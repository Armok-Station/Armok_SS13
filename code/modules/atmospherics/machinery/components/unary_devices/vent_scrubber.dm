#define SIPHONING	0
#define SCRUBBING	1

/obj/machinery/atmospherics/components/unary/vent_scrubber
	icon_state = "scrub_map-3"

	name = "air scrubber"
	desc = "Has a valve and pump attached to it."
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 60
	can_unwrench = TRUE
	welded = FALSE
	layer = GAS_SCRUBBER_LAYER
	hide = TRUE
	shift_underlay_only = FALSE

	var/scrubbing = SCRUBBING //0 = siphoning, 1 = scrubbing

	var/filter_types = list(/datum/gas/carbon_dioxide)
	var/volume_rate = 400
	var/widenet = 0 //is this scrubber acting on the 3x3 area around it.
	var/list/turf/adjacent_turfs = list()

	pipe_state = "scrubber"

	network_id = NETWORK_ATMOS_SCUBBERS
	var/list/datalink = null

/obj/machinery/atmospherics/components/unary/vent_scrubber/New()
	..()
	for(var/f in filter_types)
		if(istext(f))
			filter_types -= f
			filter_types += gas_id2path(f)


/obj/machinery/atmospherics/components/unary/vent_scrubber/Initialize()
	. = ..()
	var/area/scrub_area = get_area(src)
	name = sanitize("\proper [scrub_area.name] air scrubber [assign_random_name()]")
	datalink =  list(
		"filter_types" = filter_types,
		"hardware_id" = null,
		"long_name" = name,
		"id_tag" = id_tag,
		"device" = "VS",
		"timestamp" = world.time,
		"power" = on,
		"scrubbing" = scrubbing,
		"widenet" = widenet,
	)
	var/datum/component/ntnet_interface/net = GetComponent(/datum/component/ntnet_interface)
	net.register_port("status", datalink)
	if(id_tag)
		datalink["id_tag"] = id_tag
	datalink["hardware_id"] = net.hardware_id

	scrub_area.atmos_scrubbers[net.hardware_id] = datalink // magic!


/obj/machinery/atmospherics/components/unary/vent_scrubber/Destroy()
	var/area/scrub_area = get_area(src)
	if(scrub_area)
		var/datum/component/ntnet_interface/net = GetComponent(/datum/component/ntnet_interface)
		scrub_area.atmos_scrubbers.Remove(net.hardware_id)
	datalink = null
	return ..()

/obj/machinery/atmospherics/components/unary/vent_scrubber/auto_use_power()
	if(!on || welded || !is_operational || !powered(power_channel))
		return FALSE

	var/amount = idle_power_usage

	if(scrubbing & SCRUBBING)
		amount += idle_power_usage * length(filter_types)
	else //scrubbing == SIPHONING
		amount = active_power_usage

	if(widenet)
		amount += amount * (adjacent_turfs.len * (adjacent_turfs.len / 2))
	use_power(amount, power_channel)
	return TRUE

/obj/machinery/atmospherics/components/unary/vent_scrubber/update_icon_nopipes()
	cut_overlays()
	if(showpipe)
		var/image/cap = getpipeimage(icon, "scrub_cap", initialize_directions)
		add_overlay(cap)
	else
		PIPING_LAYER_SHIFT(src, PIPING_LAYER_DEFAULT)

	if(welded)
		icon_state = "scrub_welded"
		return

	if(!nodes[1] || !on || !is_operational)
		icon_state = "scrub_off"
		return

	if(scrubbing & SCRUBBING)
		if(widenet)
			icon_state = "scrub_wide"
		else
			icon_state = "scrub_on"
	else //scrubbing == SIPHONING
		icon_state = "scrub_purge"


/obj/machinery/atmospherics/components/unary/vent_scrubber/atmosinit()
	check_turfs()
	..()

/obj/machinery/atmospherics/components/unary/vent_scrubber/process_atmos(delta_time)
	..()
	if(welded || !is_operational)
		return FALSE

	if(NETWORK_PORT_UPDATED(datalink)) // handle port updates
		on = datalink["power"]
		scrubbing = datalink["scrubbing"]
		widenet = datalink["widenet"]
		filter_types = datalink["filter_types"]
		NETWORK_PORT_CLEAR_UPDATE(datalink)
		CallAsync(src,.proc/update_icon_nopipes)

	if(!nodes[1] || !on)
		on = FALSE
		return FALSE
	scrub(loc, delta_time)
	if(widenet)
		for(var/turf/tile in adjacent_turfs)
			scrub(tile, delta_time)
	return TRUE

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/scrub(turf/tile, delta_time = 0.5)
	if(!istype(tile))
		return FALSE
	var/datum/gas_mixture/environment = tile.return_air()
	var/datum/gas_mixture/air_contents = airs[1]
	var/list/env_gases = environment.gases

	if(air_contents.return_pressure() >= 50 * ONE_ATMOSPHERE)
		return FALSE

	if(scrubbing & SCRUBBING)
		if(length(env_gases & filter_types))
			var/transfer_moles = min(1, volume_rate * delta_time / environment.volume)*environment.total_moles()

			//Take a gas sample
			var/datum/gas_mixture/removed = tile.remove_air(transfer_moles)

			//Nothing left to remove from the tile
			if(isnull(removed))
				return FALSE

			var/list/removed_gases = removed.gases

			//Filter it
			var/datum/gas_mixture/filtered_out = new
			var/list/filtered_gases = filtered_out.gases
			filtered_out.temperature = removed.temperature

			for(var/gas in filter_types & removed_gases)
				filtered_out.add_gas(gas)
				filtered_gases[gas][MOLES] = removed_gases[gas][MOLES]
				removed_gases[gas][MOLES] = 0

			removed.garbage_collect()

			//Remix the resulting gases
			air_contents.merge(filtered_out)
			tile.assume_air(removed)
			tile.air_update_turf()

	else //Just siphoning all air

		var/transfer_moles = environment.total_moles() * (volume_rate * delta_time / environment.volume)

		var/datum/gas_mixture/removed = tile.remove_air(transfer_moles)

		air_contents.merge(removed)
		tile.air_update_turf()

	update_parents()

	return TRUE

//There is no easy way for an object to be notified of changes to atmos can pass flags
//	So we check every machinery process (2 seconds)
/obj/machinery/atmospherics/components/unary/vent_scrubber/process()
	if(widenet)
		check_turfs()

//we populate a list of turfs with nonatmos-blocked cardinal turfs AND
//	diagonal turfs that can share atmos with *both* of the cardinal turfs

/obj/machinery/atmospherics/components/unary/vent_scrubber/proc/check_turfs()
	adjacent_turfs.Cut()
	var/turf/T = get_turf(src)
	if(istype(T))
		adjacent_turfs = T.GetAtmosAdjacentTurfs(alldir = 1)


/obj/machinery/atmospherics/components/unary/vent_scrubber/ntnet_receive(datum/netdata/signal)
	if(!is_operational || signal.data["sigtype"]!="command")
		return

	var/atom/signal_sender = signal.data["user"]

	if("power" in signal.data)
		on = text2num(signal.data["power"])
		datalink["on"] = on

	if("power_toggle" in signal.data)
		on = !on
		datalink["on"] = on

	if("widenet" in signal.data)
		widenet = text2num(signal.data["widenet"])
		datalink["widenet"] = widenet

	if("toggle_widenet" in signal.data)
		widenet = !widenet
		datalink["widenet"] = widenet

	var/old_scrubbing = scrubbing
	if("scrubbing" in signal.data)
		scrubbing = text2num(signal.data["scrubbing"])
		datalink["scrubbing"] = scrubbing

	if("toggle_scrubbing" in signal.data)
		scrubbing = !scrubbing
		datalink["scrubbing"] = scrubbing

	if(scrubbing != old_scrubbing)
		datalink["scrubbing"] = scrubbing
		investigate_log(" was toggled to [scrubbing ? "scrubbing" : "siphon"] mode by [key_name(signal_sender)]",INVESTIGATE_ATMOS)


	if("init" in signal.data)
		name = signal.data["init"]
		return

	if(!("status" in signal.data))
		update_icon()  //do not update_icon

	return

/obj/machinery/atmospherics/components/unary/vent_scrubber/power_change()
	. = ..()
	update_icon_nopipes()

/obj/machinery/atmospherics/components/unary/vent_scrubber/welder_act(mob/living/user, obj/item/I)
	..()
	if(!I.tool_start_check(user, amount=0))
		return TRUE
	to_chat(user, "<span class='notice'>Now welding the scrubber.</span>")
	if(I.use_tool(src, user, 20, volume=50))
		if(!welded)
			user.visible_message("<span class='notice'>[user] welds the scrubber shut.</span>","<span class='notice'>You weld the scrubber shut.</span>", "<span class='hear'>You hear welding.</span>")
			welded = TRUE
		else
			user.visible_message("<span class='notice'>[user] unwelds the scrubber.</span>", "<span class='notice'>You unweld the scrubber.</span>", "<span class='hear'>You hear welding.</span>")
			welded = FALSE
		update_icon()
		pipe_vision_img = image(src, loc, layer = ABOVE_HUD_LAYER, dir = dir)
		pipe_vision_img.plane = ABOVE_HUD_PLANE
		investigate_log("was [welded ? "welded shut" : "unwelded"] by [key_name(user)]", INVESTIGATE_ATMOS)
		add_fingerprint(user)
	return TRUE

/obj/machinery/atmospherics/components/unary/vent_scrubber/can_unwrench(mob/user)
	. = ..()
	if(. && on && is_operational)
		to_chat(user, "<span class='warning'>You cannot unwrench [src], turn it off first!</span>")
		return FALSE

/obj/machinery/atmospherics/components/unary/vent_scrubber/examine(mob/user)
	. = ..()
	if(welded)
		. += "It seems welded shut."

/obj/machinery/atmospherics/components/unary/vent_scrubber/can_crawl_through()
	return !welded

/obj/machinery/atmospherics/components/unary/vent_scrubber/attack_alien(mob/user)
	if(!welded || !(do_after(user, 20, target = src)))
		return
	user.visible_message("<span class='warning'>[user] furiously claws at [src]!</span>", "<span class='notice'>You manage to clear away the stuff blocking the scrubber.</span>", "<span class='hear'>You hear loud scraping noises.</span>")
	welded = FALSE
	update_icon()
	pipe_vision_img = image(src, loc, layer = ABOVE_HUD_LAYER, dir = dir)
	pipe_vision_img.plane = ABOVE_HUD_PLANE
	playsound(loc, 'sound/weapons/bladeslice.ogg', 100, TRUE)


/obj/machinery/atmospherics/components/unary/vent_scrubber/layer2
	piping_layer = 2
	icon_state = "scrub_map-2"

/obj/machinery/atmospherics/components/unary/vent_scrubber/layer4
	piping_layer = 4
	icon_state = "scrub_map-4"

/obj/machinery/atmospherics/components/unary/vent_scrubber/on
	on = TRUE
	icon_state = "scrub_map_on-3"

/obj/machinery/atmospherics/components/unary/vent_scrubber/on/layer2
	piping_layer = 2
	icon_state = "scrub_map_on-2"

/obj/machinery/atmospherics/components/unary/vent_scrubber/on/layer4
	piping_layer = 4
	icon_state = "scrub_map_on-4"

#undef SIPHONING
#undef SCRUBBING
