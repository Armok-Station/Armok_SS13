/obj/item/pod_equipment/sensors
	slot = POD_SLOT_SENSORS
	name = "NT Sensor Suite"
	desc = "A sensor suite for space pods, containing some tech doodads and a built-in GPS. Manufacted by Nanotrasen, and has weird labels like \"Not for infowar\" or manufacted on \"Tau Ceti IV\"."
	/// reference to our GPS component
	var/datum/component/gps/item/gps
	/// traits given to all passengers
	var/traits_given

/obj/item/pod_equipment/sensors/on_attach(mob/user)
	. = ..()
	gps = pod.AddComponent(/datum/component/gps/item, "POD[rand(0,999)]", state = GLOB.contained_state, overlay_state = FALSE)
	gps.tracking = FALSE
	START_PROCESSING(SSobj, src)
	if(islist(traits_given))
		RegisterSignal(pod, COMSIG_VEHICLE_OCCUPANT_ADDED, PROC_REF(occupant_added))
		RegisterSignal(pod, COMSIG_VEHICLE_OCCUPANT_REMOVED, PROC_REF(occupant_removed))
		for(var/occupant in pod.occupants)
			occupant_added(occupant)

/obj/item/pod_equipment/sensors/on_detach(mob/user)
	. = ..()
	QDEL_NULL(gps)
	UnregisterSignal(pod, list(COMSIG_VEHICLE_OCCUPANT_ADDED, COMSIG_VEHICLE_OCCUPANT_REMOVED))
	if(islist(traits_given))
		for(var/occupant in pod.occupants)
			occupant_removed(occupant)

/obj/item/pod_equipment/sensors/proc/occupant_added(datum/source, mob/living/carbon/occupant, flags)
	SIGNAL_HANDLER
	if(istype(occupant))
		occupant.add_traits(traits_given, REF(src))
		occupant.update_sight()

/obj/item/pod_equipment/sensors/proc/occupant_removed(datum/source, mob/living/carbon/occupant, flags)
	SIGNAL_HANDLER
	if(istype(occupant))
		occupant.remove_traits(traits_given, REF(src))
		occupant.update_sight()

/obj/item/pod_equipment/sensors/create_occupant_actions(mob/occupant, flag = NONE)
	if(!(flag & VEHICLE_CONTROL_DRIVE))
		return FALSE

	var/datum/action/vehicle/sealed/spacepod_equipment/equipment_action = new(src)
	equipment_action.callback_on_click = CALLBACK(src, PROC_REF(on_use))
	equipment_action.name = name
	equipment_action.button_icon = /obj/item/gps::icon
	equipment_action.button_icon_state = /obj/item/gps/engineering::icon_state
	return equipment_action

/obj/item/pod_equipment/sensors/process()
	if(!gps?.tracking)
		return
	if(!length(pod.occupants))
		return
	if(pod.use_power(STANDARD_BATTERY_CHARGE / 100000))
		return
	close_all_ui()

/obj/item/pod_equipment/sensors/proc/close_all_ui()
	if(!LAZYLEN(gps?.open_uis))
		return null
	for(var/datum/tgui/ui as anything in gps.open_uis)
		ui.close()

/obj/item/pod_equipment/sensors/proc/on_use(mob/user)
	if(pod.use_power(10)) // a noble 10 probably just used to check if the UI is opened
		gps.interact(user = user)
		return
	close_all_ui()

/obj/item/pod_equipment/sensors/mesons
	name = "Construction Sensor Suite"
	desc = "A pod sensor suite with built-in GPS and meson vision."
	traits_given = list(TRAIT_MESON_VISION)
