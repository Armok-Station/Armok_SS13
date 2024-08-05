//
// space pods
//

// TODO:
// todo ingame manual item so i can self insert >:)
// sprites
// fix drill bump (not possible without tinkering with drift_handler)
// research n designs
// ALSO DO NOT FORGET TO REMOVE THIS HUGE ASS COMMENT before finishing

// this is the iron variant
/obj/vehicle/sealed/space_pod
	name = "space pod"
	desc = "A small, highly modular space exploration vessel. These were developed by Nanotrasen for private personnel to evaluate local space fauna and structures, and potentially other uses, like repair."
	layer = ABOVE_MOB_LAYER
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_EXTREMELY_STRONG
	resistance_flags = FIRE_PROOF | ACID_PROOF
	icon = 'icons/mob/rideables/spacepod/pod_small.dmi'
	icon_state = "cockpit"
	light_system = OVERLAY_LIGHT_DIRECTIONAL
	light_on = FALSE
	light_range = 5
	light_power = 1.5
	max_occupants = 2
	max_integrity = 350
	inertia_force_cap = INERTIA_FORCE_CAP * 4 // lol, lmao
	/// Max count of a certain slot. If it is not defined here, it is assumed to be one (1). Use slot_max(slot) to access.
	var/list/slot_max = list(
		POD_SLOT_MISC = 3,
	)
	/// Equipment we have, slot = list(equipment)
	var/list/equipped = list()
	/// is our panel open? required for adding and removing parts
	var/panel_open = FALSE
	/// ion trail effect
	var/datum/effect_system/trail_follow/ion/trail
	// speed vars are here if someone wants to make their own turbo subtype pod or admin abuse
	/// max drift speed we can get via moving intentionally, modified by thrusters
	var/max_speed = 0
	/// Force per 1 second held down, modified by engine
	var/force_per_move = 0
	/// Force per process run to bring us to a halt, modified by thrusters
	var/stabilizer_force = 0

	/// our air tank, used to cycle cabin air
	var/obj/item/tank/internals/cabin_air_tank
	/// gas mixture inside the vehicle
	var/datum/gas_mixture/cabin_air = new(TANK_STANDARD_VOLUME * 5)
	/// our battery
	var/obj/item/stock_parts/power_store/battery/cell

	/// mob = list(action)
	var/list/list/equipment_actions = list()


/obj/vehicle/sealed/space_pod/Initialize(mapload, dont_equip)
	. = ..()
	if(!dont_equip)
		spawn_equip()
		generate_name()
	trail = new
	trail.auto_process = FALSE
	trail.set_up(src)
	trail.start()
	START_PROCESSING(SSnewtonian_movement, src)
	update_appearance()
	RegisterSignal(src, COMSIG_ATOM_POST_DIR_CHANGE, PROC_REF(onSetDir))
	ADD_TRAIT(src, TRAIT_CONSIDERED_ANCHORED_FOR_SPACEMOVEBACKUP, INNATE_TRAIT)

/obj/vehicle/sealed/space_pod/proc/generate_name()
	name = "[pick("pod", "vessel")] [istype(get_area(src), /area/station) ? "NT-" : ""][rand(0,9)][rand(0,9)][rand(0,9)]"

/// This proc is responsible for outfitting the pod when spawned (admin or otherwise)
/obj/vehicle/sealed/space_pod/proc/spawn_equip()
	equip_item(new /obj/item/pod_equipment/sensors)
	equip_item(new /obj/item/pod_equipment/comms)
	equip_item(new /obj/item/pod_equipment/thrusters/default)
	equip_item(new /obj/item/pod_equipment/engine/default)
	if(prob(45))
		equip_item(new /obj/item/pod_equipment/primary/projectile_weapon/energy/wildlife)
	equip_item(new /obj/item/pod_equipment/cargo_hold)
	if(prob(40))
		equip_item(new /obj/item/pod_equipment/lock/pin)
	cabin_air_tank = new /obj/item/tank/internals/oxygen(src)
	cell = new /obj/item/stock_parts/power_store/battery(src)

/obj/vehicle/sealed/space_pod/Destroy()
	. = ..()
	QDEL_NULL(trail)
	QDEL_NULL(cabin_air_tank)
	QDEL_LIST_ASSOC_VAL(equipment_actions)
	equipped = null // equipment gets deleted already because its in our contents

/obj/vehicle/sealed/space_pod/generate_actions()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/kick_out)
	initialize_controller_action_type(/datum/action/vehicle/sealed/pod_status, VEHICLE_CONTROL_DRIVE)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/climb_out/pod)

/obj/vehicle/sealed/space_pod/update_overlays()
	. = ..()
	. += "window"
	if(panel_open)
		. += "panel_open[!isnull(cabin_air_tank) ? "_t" : ""]"
	if(light_on)
		. += "headlights_on" //this is a fixed overlay which might be bad for unique pods but why wouldnt one have headlights
		. += emissive_appearance(icon, "headlights_on", src, alpha = src.alpha)

	for(var/obj/item/pod_equipment/equipment as anything in get_all_parts())
		var/overlay = equipment.get_overlay()
		if(isnull(overlay))
			continue
		. += overlay

/obj/vehicle/sealed/space_pod/mob_try_enter(mob/rider)
	if(!istype(rider))
		return FALSE
	if(!allowed(rider) || !does_lock_permit_it(rider))
		balloon_alert(rider, "no access!")
		return FALSE
	if(!rider.can_perform_action(src, NEED_HANDS)) // you need hands to use the door handle buddy
		return ..()
	if(length(occupants) < max_occupants)
		return ..()
	rider.balloon_alert_to_viewers("kicking driver out!")
	if(!do_after(rider, 5 SECONDS, src))
		return
	for(var/mob/living/driver as anything in return_drivers())
		driver.Knockdown(1 SECONDS)
		mob_exit(driver, randomstep = TRUE)

/obj/vehicle/sealed/space_pod/mob_try_exit(mob/removing, mob/user, silent = FALSE, randomstep = FALSE)
	if(user != removing)
		return ..()
	if(!HAS_TRAIT(removing, TRAIT_RESTRAINED)) // you need hands to use the door handle buddy
		return ..()

/obj/vehicle/sealed/space_pod/container_resist_act(mob/living/user)
	. = ..()
	mob_try_exit(user, user)

/obj/vehicle/sealed/space_pod/mouse_drop_receive(mob/living/dropped, mob/living/dropper, params)
	. = ..()
	if(dropped == dropper || !istype(dropped) || !istype(dropper) || !dropper.can_interact_with(src))
		return
	if(length(occupants) >= max_occupants - max_drivers)
		balloon_alert(dropper, "not enough passenger spots!")
		return
	if(!does_lock_permit_it(dropper))
		return
	dropped.visible_message(span_warning("[dropper] begins forcing [dropped] into [src]!"), span_userdanger("[dropper] begins forcing you into [src]!"))
	if(!do_after(dropper, 4 SECONDS, dropped, extra_checks = CALLBACK(src, PROC_REF(enter_checks))))
		return
	if(!dropped.Adjacent(src))
		return
	mob_enter(dropped, flags = NONE) // force occupancy
	dropped.visible_message(span_warning("[dropped] is forced into [src] by [dropper]!"))

/obj/vehicle/sealed/space_pod/welder_act(mob/living/user, obj/item/welder)
	if(user.combat_mode || DOING_INTERACTION(user, src))
		return
	. = NONE
	if(atom_integrity >= max_integrity)
		balloon_alert(user, "no damage!")
		return
	if(!welder.tool_start_check(user, amount=1))
		return
	user.balloon_alert_to_viewers("repairing pod!")
	audible_message(span_hear("You hear welding."))
	while(atom_integrity < max_integrity) //19-20 seconds to repair an iron pod from almost 0 to full
		if(welder.use_tool(src, user, 1 SECONDS, volume=50))
			atom_integrity += min(/obj/vehicle/sealed/space_pod::max_integrity / 20, (max_integrity - atom_integrity))
			audible_message(span_hear("You hear welding."))
		else
			break

/obj/vehicle/sealed/space_pod/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_PODPANEL, "Pod Debug Panel")

/obj/vehicle/sealed/space_pod/vv_do_topic(list/href_list)
	. = ..()
	if(!.)
		return

	if(href_list[VV_HK_PODPANEL])
		if(!check_rights(R_ADMIN))
			return
		SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/pod_debug_panel, src)

/obj/vehicle/sealed/space_pod/proc/process_huds()
	for(var/mob/living/occupant as anything in occupants)
		if(cell?.maxcharge)
			var/cellcharge = cell.charge/cell.maxcharge
			switch(cellcharge)
				if(0.75 to INFINITY)
					occupant.clear_alert(ALERT_CHARGE)
				if(0.5 to 0.75)
					occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/lowcell, 1)
				if(0.25 to 0.5)
					occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/lowcell, 2)
				if(0.01 to 0.25)
					occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/lowcell, 3)
				else
					occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/emptycell)
		else
			occupant.throw_alert(ALERT_CHARGE, /atom/movable/screen/alert/nocell)
		var/integrity = get_integrity_percentage() * 100
		switch(integrity)
			if(40 to 60)
				occupant.throw_alert(ALERT_MECH_DAMAGE, /atom/movable/screen/alert/pod_damage, 1)
			if(20 to 40)
				occupant.throw_alert(ALERT_MECH_DAMAGE, /atom/movable/screen/alert/pod_damage, 2)
			if(-INFINITY to 20)
				occupant.throw_alert(ALERT_MECH_DAMAGE, /atom/movable/screen/alert/pod_damage, 3)
			else
				occupant.clear_alert(ALERT_MECH_DAMAGE)

// atmos
/obj/vehicle/sealed/space_pod/proc/cycle_tank_air(to_tank = FALSE)
	if(isnull(cabin_air_tank))
		return
	var/datum/gas_mixture/from = to_tank ? cabin_air : cabin_air_tank.return_air()
	var/datum/gas_mixture/target = to_tank ? cabin_air_tank.return_air() : cabin_air
	var/datum/gas_mixture/removed = from.remove(from.total_moles())
	if(!removed)
		return
	target.merge(removed)

/obj/vehicle/sealed/space_pod/remove_air(amount)
	return !isnull(cabin_air_tank) ? cabin_air.remove(amount) : ..()
/obj/vehicle/sealed/space_pod/return_air()
	return !isnull(cabin_air_tank) ? cabin_air : ..()
/obj/vehicle/sealed/space_pod/return_analyzable_air()
	return !isnull(cabin_air_tank) ? cabin_air : null // no internal air
/obj/vehicle/sealed/space_pod/return_temperature()
	var/datum/gas_mixture/air = return_air()
	return air?.return_temperature()

