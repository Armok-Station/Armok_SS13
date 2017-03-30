/obj/machinery/power/exporter
	name = "power exporter"
	desc = "This device instantaneously beams power to the IEV market in return for vouchers"
	icon = 'icons/obj/machines/dominator.dmi'
	icon_state = "dominator"
	density = 1
	anchored = FALSE
	verb_say = "states"
	var/drain_rate = 0	// amount of power to drain per tick
	var/power_drained = 0 		// has drained this much power
	var/rating = ""
	var/active = FALSE
	var/rewarded = FALSE

/obj/machinery/power/exporter/examine(mob/user)
	..()
	if(!active)
		user << "<span class='notice'>The exporter seems to be offline.</span>"
	else
		user << "<span class='notice'>The [src] is exporting [drain_rate] kilowatts of power, it has consumed [power_drained] kilowatts so far.</span>"

obj/machinery/power/exporter/Initialize()
	..()
	power_exporter_list += src

obj/machinery/power/exporter/Destroy()
	power_exporter_list -= src
	return ..()

/obj/machinery/power/exporter/attackby(obj/item/O, mob/user, params)
	if(!active)
		if(istype(O, /obj/item/weapon/wrench))
			if(!anchored && !isinspace())
				connect_to_network()
				user << "<span class='notice'>You secure the [src] to the floor.</span>"
				anchored = TRUE
			else if(anchored)
				disconnect_from_network()
				user << "<span class='notice'>You unsecure and disconnect the [src].</span>"
				anchored = FALSE
			playsound(loc, 'sound/items/Deconstruct.ogg', 50, 1)
			return
	return ..()

/obj/machinery/power/exporter/attack_hand(mob/user)
	..()
	if (!anchored)
		user << "<span class='warning'>This device must be anchored by a wrench!</span>"
		return
	interact(user)

/obj/machinery/power/exporter/attack_ai(mob/user)
	interact(user)

/obj/machinery/power/exporter/attack_paw(mob/user)
	interact(user)

/obj/machinery/power/exporter/interact(mob/user)
	if (!anchored)
		user << "<span class='warning'>This device must be anchored by a wrench!</span>"
		return
	if(!Adjacent(user) && (!isAI(user)))
		return
	user.set_machine(src)
	var/list/dat = list()
	dat += ("<b>[name]</b><br>")
	if (active)
		dat += ("Exporter: <A href='?src=\ref[src];action=disable'>On</A><br>")
	else
		dat += ("Exporter: <A href='?src=\ref[src];action=enable'>Off</A><br>")
	dat += ("Power export rate: <A href='?src=\ref[src];action=set_power'>[drain_rate] kilowatts</A><br><br>")
	dat += ("Surplus power: [(powernet == null ? "Unconnected" : "[powernet.netexcess/1000] kilowatts")]<br>")
	dat += ("Total Power exported: [power_drained] kilowatts<br><br>")
	dat += ("The current power export rate will earn approximately:<br>[round(sqrt(power_drained)*8)] vouchers per minute<br><br>")
	switch(drain_rate)
		if(0 to 200)
			rating = "TERRIBLE"
		if(201 to 400)
			rating = "BAD"
		if(401 to 800)
			rating = "SUBPAR"
		if(801 to 4500)
			rating = "DECENT"
		if(4501 to 8000)
			rating = "ROBUST"
		if(8001 to 15000)
			rating = "THE 1%"
		if(15001 to 9999999)
			rating = "INCONCEIVABLE!"
	dat += ("Current export rating is: [rating]<br>")
	dat += "<br><A href='?src=\ref[src];action=close'>Close</A>"
	var/datum/browser/popup = new(user, "vending", "Power Exporter", 400, 350)
	popup.set_content(dat.Join())
	popup.open()

/obj/machinery/power/exporter/Topic(href, href_list)
	if(..())
		return
	add_fingerprint(usr)
	switch(href_list["action"])
		if("enable")
			if(!active && !crit_fail)
				active = TRUE
				src.updateUsrDialog()
				if(active && !crit_fail && anchored && powernet && drain_rate)
					icon_state = "dominator-yellow"
		if("disable")
			if (active)
				active = FALSE
				drain_rate = 0
				src.updateUsrDialog()
		if("set_power")
			drain_rate = input("Power export rate (in kW):", name, drain_rate)
			src.updateUsrDialog()
			if(active && !crit_fail && anchored && powernet && drain_rate)
				icon_state = "dominator-yellow"
		if ("close")
			usr.unset_machine()


/obj/machinery/power/exporter/process()
	if(active && !crit_fail && anchored && powernet)
		if(powernet.netexcess >= 1)
			powernet.load += drain_rate*1000
			power_drained += drain_rate
		else
			visible_message("Power export levels have exceeded energy surplus, shutting down")
			active = FALSE
			drain_rate = 0
			icon_state = "dominator"
	else
		active = FALSE
		drain_rate = 0
		icon_state = "dominator"
