/**
 * the tram has a few objects mapped onto it at roundstart, by default many of those objects have unwanted properties
 * for example grilles and windows have the atmos_sensitive element applied to them, which makes them register to
 * themselves moving to re register signals onto the turf via connect_loc. this is bad and dumb since it makes the tram
 * more expensive to move.
 *
 * if you map something on to the tram, make SURE if possible that it doesnt have anything reacting to its own movement
 * it will make the tram more expensive to move and we dont want that because we dont want to return to the days where
 * the tram took a third of the tick per movement when its just carrying its default mapped in objects
 */

/obj/structure/grille/tram/Initialize(mapload)
	. = ..()
	RemoveElement(/datum/element/atmos_sensitive, mapload)
	//atmos_sensitive applies connect_loc which 1. reacts to movement in order to 2. unregister and register signals to
	//the old and new locs. we dont want that, pretend these grilles and windows are plastic or something idk

/obj/structure/window/reinforced/shuttle/tram
	name = "tram window"
	icon = 'icons/obj/smooth_structures/tram_window.dmi'

/obj/structure/window/reinforced/shuttle/tram/Initialize(mapload, direct)
	. = ..()
	RemoveElement(/datum/element/atmos_sensitive, mapload)

/turf/open/floor/glass/reinforced/tram/Initialize(mapload)
	. = ..()
	RemoveElement(/datum/element/atmos_sensitive, mapload)

/obj/structure/industrial_lift/tram/white
	icon_state = "titanium_white"

/obj/structure/industrial_lift/tram/subfloor
	name = "tram"
	desc = "A tram for tramversing the station."
	icon_state = "tram_subfloor"

/obj/structure/industrial_lift/tram/accessible
	icon_state = "titanium_accessible_north"

/obj/structure/industrial_lift/tram/accessible/north
	icon_state = "titanium_accessible_north"

/obj/structure/industrial_lift/tram/accessible/south
	icon_state = "titanium_accessible_south"

/obj/structure/chair/sofa/bench/tram
	greyscale_colors = "#00CCFF"

/obj/structure/chair/sofa/bench/tram/left
	name = "tram seating"
	desc = "Not the most comfortable, but easy to keep clean!"
	icon_state = "bench_left"
	greyscale_config = /datum/greyscale_config/bench_left
	greyscale_colors = "#00CCFF"

/obj/structure/chair/sofa/bench/tram/right
	name = "tram seating"
	desc = "Not the most comfortable, but easy to keep clean!"
	icon_state = "bench_right"
	greyscale_config = /datum/greyscale_config/bench_right
	greyscale_colors = "#00CCFF"

/obj/structure/chair/sofa/bench/tram/solo
	name = "tram seating"
	desc = "Not the most comfortable, but easy to keep clean!"
	icon_state = "bench_solo"
	greyscale_config = /datum/greyscale_config/bench_solo
	greyscale_colors = "#00CCFF"

/turf/open/floor/glass/reinforced/tram
	name = "tram bridge"
	desc = "It shakes a bit when you step, but lets you cross between sides quickly!"

/obj/machinery/door/window/tram
	icon = 'icons/obj/doors/tramdoor.dmi'
	var/associated_lift = MAIN_STATION_TRAM
	var/datum/weakref/tram_ref
	/// Directions the tram door can be forced open in an emergency
	var/space_dir = null
	name = "tram door"
	desc = "Probably won't crush you if you try to rush them as they close. But we know you live on that danger, try and beat the tram!"

/obj/machinery/door/window/tram/left
	icon_state = "left"
	base_state = "left"

/obj/machinery/door/window/tram/right
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/tram/proc/cycle_doors(command, forced=FALSE)
	if(command == "open" && icon_state == "[base_state]open")
		if(!forced)
			if(!hasPower())
				return 0
		return 1
	if(command == "close" && icon_state == base_state)
		return 1
	if(operating) //doors can still function when emag-disabled
		return 0
	if(forced < 2)
		if(obj_flags & EMAGGED)
			return 0
	if(!operating) //in case of emag
		operating = TRUE
	playsound(src, 'sound/machines/windowdoor.ogg', 100, TRUE)
	switch(command)
		if("open")
			do_animate("opening")
			icon_state ="[base_state]open"
			sleep(8 DECISECONDS)
			set_density(FALSE)
			air_update_turf(TRUE, FALSE)
			if(operating == 1) //emag again
				operating = FALSE
		if("close")
			do_animate("closing")
			icon_state = base_state
			sleep(17 DECISECONDS)
			set_density(TRUE)
			air_update_turf(TRUE, TRUE)
			operating = FALSE
	update_freelook_sight()
	return 1

//When the tram is in station, the doors are locked to engineering and command only.
/obj/machinery/door/window/tram/lock()
	req_access = list("engineering")

/obj/machinery/door/window/tram/unlock()
	req_access = null

/obj/machinery/door/window/tram/proc/find_tram()
	for(var/datum/lift_master/lift as anything in GLOB.active_lifts_by_type[TRAM_LIFT_ID])
		if(lift.specific_lift_id == associated_lift)
			tram_ref = WEAKREF(lift)

/obj/machinery/door/window/tram/Initialize(mapload, set_dir, unres_sides)
	. = ..()
	RemoveElement(/datum/element/atmos_sensitive, mapload)
	associated_lift = MAIN_STATION_TRAM
	INVOKE_ASYNC(src, PROC_REF(open))
	find_tram()

/obj/machinery/door/window/tram/examine(mob/user)
	. = ..()
	. += span_notice("It has labels indicating that it has an emergency mechanism to open from the inside using <b>just your hands</b> in the event of an emergency.")

/obj/machinery/door/window/tram/try_safety_unlock(mob/user)
	if(!hasPower()  && density)
		to_chat(user, span_notice("You begin pulling the tram emergency exit handle..."))
		if(do_after(user, 15 SECONDS, target = src))
			try_to_crowbar(null, user, TRUE)
			return TRUE

/obj/machinery/door/window/tram/open_and_close()
	var/datum/lift_master/tram/tram_part = tram_ref?.resolve()
	if(!open())
		return
	if(tram_part.travelling) //making a daring exit midtravel? make sure the doors don't go in the wrong state on arrival.
		return PROCESS_KILL

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/door/window/tram/left, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/door/window/tram/right, 0)
