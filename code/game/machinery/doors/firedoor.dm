#define CONSTRUCTION_PANEL_OPEN 1 //Maintenance panel is open, still functioning
#define CONSTRUCTION_NO_CIRCUIT 2 //Circuit board removed, can safely weld apart
#define DEFAULT_STEP_TIME 20 /// default time for each step
#define DETECT_COOLDOWN_STEP_TIME 5 SECONDS ///Wait time before we can detect an issue again, after a recent clear.

/obj/machinery/door/firedoor
	name = "firelock"
	desc = "Apply crowbar."
	icon = 'icons/obj/doors/Doorfireglass.dmi'
	icon_state = "door_open"
	opacity = FALSE
	density = FALSE
	max_integrity = 300
	resistance_flags = FIRE_PROOF
	heat_proof = TRUE
	glass = TRUE
	sub_door = TRUE
	explosion_block = 1
	safe = FALSE
	layer = BELOW_OPEN_DOOR_LAYER
	closingLayer = CLOSED_FIREDOOR_LAYER
	assemblytype = /obj/structure/firelock_frame
	armor = list(MELEE = 10, BULLET = 30, LASER = 20, ENERGY = 20, BOMB = 30, BIO = 100, RAD = 100, FIRE = 95, ACID = 70)
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_REQUIRES_SILICON | INTERACT_MACHINE_OPEN
	var/boltslocked = TRUE
	///List of areas we handle. See CalculateAffectingAreas()
	var/list/affecting_areas
	///For the few times we affect only the area we're actually in. Set during Init. If we get moved, we don't update, but this is consistant with fire alarms and also kinda funny so call it intentional.
	var/area/my_area
	///Tracks if the firelock is being held open by a crowbar. If so, we don't close until they walk away
	var/being_held_open = FALSE
	///Type of alarm when active. See code/defines/firealarm.dm for the list. This var being null means there is no alarm.
	var/alarm_type = null
	///Cooldown for Detections. If current world time is not greater than (dectect_cooldown + DETECT_COOLDOWN_STEP_TIME), we don't activate. Prevents instant re-activations when air mixing would solve an issue
	var/detect_cooldown = 0
	///The merger_id and merger_typecache variables are used to make rows of firelocks activate at the same time.
	var/merger_id = "firelocks"
	var/merger_typecache
	///Overlay object for the warning lights. This and some plane settings allows the lights to glow in the dark.
	var/mutable_appearance/warn_lights

/obj/machinery/door/firedoor/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/atmos_sensitive, mapload)
	CalculateAffectingAreas()
	my_area = get_area(src)

	RegisterSignal(src, COMSIG_MERGER_ADDING, .proc/MergerAdding)
	RegisterSignal(src, COMSIG_MERGER_REMOVING, .proc/MergerRemoving)
	if(!merger_typecache)
		merger_typecache = typecacheof(/obj/machinery/door/firedoor)

	return INITIALIZE_HINT_LATELOAD

/obj/machinery/door/firedoor/LateInitialize()
	. = ..()
	GetMergeGroup(merger_id, allowed_types = typecacheof(/obj/machinery/door/firedoor))

/obj/machinery/door/firedoor/Destroy()
	remove_from_areas()
	UnregisterSignal(src, COMSIG_MERGER_ADDING)
	UnregisterSignal(src, COMSIG_MERGER_REMOVING)
	return ..()

///////////////////////////////////////////////////////////////////
// Merger handling

/obj/machinery/door/firedoor/proc/MergerAdding(obj/machinery/door/firedoor/us, datum/merger/new_merger)
	SIGNAL_HANDLER
	if(new_merger.id != merger_id)
		return
	RegisterSignal(new_merger, COMSIG_MERGER_REFRESH_COMPLETE, .proc/MergerRefreshComplete)

/obj/machinery/door/firedoor/proc/MergerRemoving(obj/machinery/door/firedoor/us, datum/merger/old_merger)
	SIGNAL_HANDLER
	if(old_merger.id != merger_id)
		return
	UnregisterSignal(old_merger, COMSIG_MERGER_REFRESH_COMPLETE)

/// Handles the firelocks to register only one signal per group
/obj/machinery/door/firedoor/proc/MergerRefreshComplete(datum/merger/merger, list/leaving_members, list/joining_members)

///////////////////////////////////////////////////////////////////
// End of Merger

/**
 * Calculates what areas we should worry about.
 *
 * This proc builds a list of areas we are in and areas we border
 * and writes it to affecting_areas.
 */
/obj/machinery/door/firedoor/proc/CalculateAffectingAreas()
	remove_from_areas()
	affecting_areas = get_adjacent_open_areas(src) | get_area(src)
	for(var/area/place in affecting_areas)
		LAZYADD(place.firedoors, src)

/**
 * Removes us from any lists of areas in the affecting_areas list, then clears affecting_areas
 *
 * Undoes everything done in the CalculateAffectingAreas() proc, to clean up prior to deletion.
 * Calls reset() first, in case any alarms need to be cleared first.
 */
/obj/machinery/door/firedoor/proc/remove_from_areas()
	reset() //This handles some alert/alarm clearing
	if(affecting_areas)
		for(var/area/place in affecting_areas)
			LAZYREMOVE(place.firedoors, src)
			LAZYREMOVE(place.active_firelocks, src)
			if(!LAZYLEN(place.active_firelocks)) //if we were the last firelock still active in this particular area
				for(var/obj/machinery/firealarm/fire_panel in place.firealarms)
					fire_panel.set_status()

/obj/machinery/door/firedoor/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return world.time > detect_cooldown && (exposed_temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST || exposed_temperature < BODYTEMP_COLD_DAMAGE_LIMIT) && !(obj_flags & EMAGGED) && !machine_stat

/obj/machinery/door/firedoor/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	if(obj_flags & EMAGGED)
		return
	for(var/area/place in affecting_areas)
		if(!place.fire_detect) //if any area is set to disable detection
			return
	if(alarm_type)
		return

	if(exposed_temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		start_activation_process(FIRELOCK_ALARM_TYPE_HOT)
		return
	if(exposed_temperature < BODYTEMP_COLD_DAMAGE_LIMIT)
		start_activation_process(FIRELOCK_ALARM_TYPE_COLD)
		return
	activate()//Fallback. If firelocks regularly trigger themselves as generic, we need to do some bugfixing

/**
 * Begins activation process of us and our neighbors.
 *
 * This proc will call activate() on every fire lock (including us) listed
 * in the merge group datum. Returns without doing anything if our alarm_type
 * was already set, as that means that we're already active.
 *
 * Arguments:
 * code should be one of three defined alarm types, or can be not supplied. Will dictate the color of the fire alarm lights, and defults to "firelock_alarm_type_generic"
 */
/obj/machinery/door/firedoor/proc/start_activation_process(code = FIRELOCK_ALARM_TYPE_GENERIC)
	if(alarm_type)
		return //We're already active
	var/datum/merger/merge_group = GetMergeGroup(merger_id, merger_typecache)
	for(var/obj/machinery/door/firedoor/buddylock as anything in merge_group.members)
		INVOKE_ASYNC(buddylock, .proc/activate, code)


/**
 * Proc that handles activation of the firelock and all this details
 *
 * Sets the alarm_type variable based on the single arg, which is in turn
 * used by several procs to understand the intended state of the fire lock.
 * Also calls set_status() on all fire alarms in all affected areas, tells
 * the area the firelock sits in to report the event (AI, alarm consoles, etc)
 * and finally calls correct_state(), which will handle opening or closing
 * this fire lock.
 */
/obj/machinery/door/firedoor/proc/activate(code = FIRELOCK_ALARM_TYPE_GENERIC)
	SIGNAL_HANDLER
	if(alarm_type)
		return //Already active
	alarm_type = code
	for(var/area/place in affecting_areas)
		LAZYADD(place.active_firelocks, src)
		if(LAZYLEN(place.active_firelocks) == 1) //if we're the first to activate in this particular area
			for(var/obj/machinery/firealarm/fire_panel in place.firealarms)
				fire_panel.set_status()
			if(place == my_area)
				place.alarm_manager.send_alarm(ALARM_FIRE, place) //We'll limit our reporting to just the area we're on. If the issue affects bordering areas, they can report it themselves
	update_icon() //Sets the lights even if the door doesn't move.
	if(!being_held_open)
		INVOKE_ASYNC(src, .proc/correct_state)

/**
 * Proc that handles reset steps
 *
 * Sets the alarm_type to null, removes us from active firelock lists
 * in the affected areas, and may tell fire alarms to update their icon
 * Also sets the detect cooldown so that we can't immediately re-activate
 * and finally calls correct_state() to handle opening the fire lock.
 */
/obj/machinery/door/firedoor/proc/reset()
	SIGNAL_HANDLER
	alarm_type = null
	for(var/area/place in affecting_areas)
		LAZYREMOVE(place.active_firelocks, src)
		if(!LAZYLEN(place.active_firelocks)) //if we were the last firelock still active in this particular area
			for(var/obj/machinery/firealarm/fire_panel in place.firealarms)
				fire_panel.set_status()
	detect_cooldown = world.time + DETECT_COOLDOWN_STEP_TIME
	update_icon() //Sets the lights even if the door doesn't move.
	INVOKE_ASYNC(src, .proc/correct_state)

/obj/machinery/door/firedoor/emag_act(mob/user)
	obj_flags |= EMAGGED
	open()

/obj/machinery/door/firedoor/Bumped(atom/movable/AM)
	if(panel_open || operating)
		return
	if(!density)
		return ..()
	return FALSE

/obj/machinery/door/firedoor/bumpopen(mob/living/user)
	return FALSE //No bumping to open, not even in mechs

/obj/machinery/door/firedoor/power_change()
	. = ..()
	update_icon()
	INVOKE_ASYNC(src, .proc/correct_state)

/obj/machinery/door/firedoor/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(operating || !density)
		return
	user.changeNext_move(CLICK_CD_MELEE)

	user.visible_message(span_notice("[user] bangs on \the [src]."), \
		span_notice("You bang on \the [src]."))
	playsound(loc, 'sound/effects/glassknock.ogg', 10, FALSE, frequency = 32000)

/obj/machinery/door/firedoor/attackby(obj/item/C, mob/user, params)
	add_fingerprint(user)
	if(operating)
		return
	if(welded)
		if(C.tool_behaviour == TOOL_WRENCH)
			if(boltslocked)
				to_chat(user, span_notice("There are screws locking the bolts in place!"))
				return
			C.play_tool_sound(src)
			user.visible_message(span_notice("[user] starts undoing [src]'s bolts..."), \
				span_notice("You start unfastening [src]'s floor bolts..."))
			if(!C.use_tool(src, user, DEFAULT_STEP_TIME))
				return
			playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
			user.visible_message(span_notice("[user] unfastens [src]'s bolts."), \
				span_notice("You undo [src]'s floor bolts."))
			deconstruct(TRUE)
			return
		if(C.tool_behaviour == TOOL_SCREWDRIVER)
			user.visible_message(span_notice("[user] [boltslocked ? "unlocks" : "locks"] [src]'s bolts."), \
				span_notice("You [boltslocked ? "unlock" : "lock"] [src]'s floor bolts."))
			C.play_tool_sound(src)
			boltslocked = !boltslocked
			return
	return ..()

/obj/machinery/door/firedoor/try_to_activate_door(mob/user)
	return

/obj/machinery/door/firedoor/try_to_weld(obj/item/weldingtool/W, mob/user)
	if(!W.tool_start_check(user, amount=0))
		return
	user.visible_message(span_notice("[user] starts [welded ? "unwelding" : "welding"] [src]."), span_notice("You start welding [src]."))
	if(W.use_tool(src, user, DEFAULT_STEP_TIME, volume=50))
		welded = !welded
		user.visible_message(span_danger("[user] [welded?"welds":"unwelds"] [src]."), span_notice("You [welded ? "weld" : "unweld"] [src]."))
		log_game("[key_name(user)] [welded ? "welded":"unwelded"] firedoor [src] with [W] at [AREACOORD(src)]")
		update_appearance()
		correct_state()

/// We check for adjacency when using the primary attack.
/obj/machinery/door/firedoor/try_to_crowbar(obj/item/acting_object, mob/user)
	if(welded || operating)
		return

	if(density)
		being_held_open = TRUE
		user.balloon_alert_to_viewers("holding [src] open", "holding [src] open")
		open()
		if(QDELETED(user))
			being_held_open = FALSE
			return
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, .proc/handle_held_open_adjacency)
		RegisterSignal(user, COMSIG_LIVING_SET_BODY_POSITION, .proc/handle_held_open_adjacency)
		RegisterSignal(user, COMSIG_PARENT_QDELETING, .proc/handle_held_open_adjacency)
		handle_held_open_adjacency(user)
	else
		close()

/// A simple toggle for firedoors between on and off
/obj/machinery/door/firedoor/try_to_crowbar_secondary(obj/item/acting_object, mob/user)
	if(welded || operating)
		return

	if(density)
		open()
		if(alarm_type)
			addtimer(CALLBACK(src, .proc/correct_state), 2 SECONDS, TIMER_UNIQUE)
	else
		close()

/obj/machinery/door/firedoor/proc/handle_held_open_adjacency(mob/user)
	SIGNAL_HANDLER

	var/mob/living/living_user = user
	if(!QDELETED(user) && Adjacent(user) && isliving(user) && (living_user.body_position == STANDING_UP))
		return
	being_held_open = FALSE
	INVOKE_ASYNC(src, .proc/correct_state)
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(user, COMSIG_LIVING_SET_BODY_POSITION)
	UnregisterSignal(user, COMSIG_PARENT_QDELETING)
	if(user)
		user.balloon_alert_to_viewers("released [src]", "released [src]")

/obj/machinery/door/firedoor/attack_ai(mob/user)
	add_fingerprint(user)
	if(welded || operating || machine_stat & NOPOWER)
		return TRUE
	if(density)
		open()
		if(alarm_type)
			addtimer(CALLBACK(src, .proc/correct_state), 2 SECONDS, TIMER_UNIQUE)
	else
		close()
	return TRUE

/obj/machinery/door/firedoor/attack_robot(mob/user)
	return attack_ai(user)

/obj/machinery/door/firedoor/attack_alien(mob/user, list/modifiers)
	add_fingerprint(user)
	if(welded)
		to_chat(user, span_warning("[src] refuses to budge!"))
		return
	open()
	if(alarm_type)
		addtimer(CALLBACK(src, .proc/correct_state), 2 SECONDS, TIMER_UNIQUE)

/obj/machinery/door/firedoor/do_animate(animation)
	switch(animation)
		if("opening")
			flick("door_opening", src)
		if("closing")
			flick("door_closing", src)

/obj/machinery/door/firedoor/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]_[density ? "closed" : "open"]"

/obj/machinery/door/firedoor/update_overlays()
	cut_overlays()
	. = ..()
	if(welded)
		. += density ? "welded" : "welded_open"
	if(alarm_type && powered())
		if(!warn_lights)
			warn_lights = new()
		warn_lights.icon = icon
		warn_lights.icon_state = "[(obj_flags & EMAGGED) ? "firelock_alarm_type_emag" : alarm_type]"
		warn_lights.plane = ABOVE_LIGHTING_PLANE
		add_overlay(warn_lights)

/**
 * Corrects the current state of the door, based on if alarm_type is set.
 *
 * This proc is called after weld and power restore events. Gives the
 * illusion that the door is constantly attempting to move without actually
 * having to process it. Timers also call this, so that if alarm_type
 * changes during the timer, the door doesn't close or open incorrectly.
 */
/obj/machinery/door/firedoor/proc/correct_state()
	if(obj_flags & EMAGGED)
		return //Unmotivated, indifferent, we have no real care what state we're in anymore.
	if(alarm_type && !density) //We should be closed but we're not
		return close()
	if(!alarm_type && density) //We should be open but we're not
		return open()

/obj/machinery/door/firedoor/open()
	if(welded)
		return
	. = ..()

/obj/machinery/door/firedoor/close()
	if(HAS_TRAIT(loc, TRAIT_FIREDOOR_STOP))
		return
	. = ..()

/obj/machinery/door/firedoor/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/turf/targetloc = get_turf(src)
		if(disassembled || prob(40))
			var/obj/structure/firelock_frame/fatal = new assemblytype(targetloc)
			if(disassembled)
				fatal.constructionStep = CONSTRUCTION_PANEL_OPEN
			else
				fatal.constructionStep = CONSTRUCTION_NO_CIRCUIT
				fatal.update_integrity(fatal.max_integrity * 0.5)
			fatal.update_appearance()
		else
			new /obj/item/electronics/firelock (targetloc)
	qdel(src)

/obj/machinery/door/firedoor/closed
	icon_state = "door_closed"
	density = TRUE

/obj/machinery/door/firedoor/border_only
	icon = 'icons/obj/doors/edge_Doorfire.dmi'
	can_crush = FALSE
	flags_1 = ON_BORDER_1
	CanAtmosPass = ATMOS_PASS_PROC
	glass = FALSE

/obj/machinery/door/firedoor/border_only/closed
	icon_state = "door_closed"
	opacity = TRUE
	density = TRUE

/obj/machinery/door/firedoor/border_only/Initialize(mapload)
	. = ..()

	var/static/list/loc_connections = list(
		COMSIG_ATOM_EXIT = .proc/on_exit,
	)

	AddElement(/datum/element/connect_loc, loc_connections)

/obj/machinery/door/firedoor/update_overlays()
	if(alarm_type && powered())
		if(!warn_lights)
			warn_lights = new()
		switch(dir) //Thin firelocks hug the edge of the sprite and so there's no real room for the lights without this
			if(NORTH)
				warn_lights.pixel_y = 2
			if(SOUTH)
				warn_lights.pixel_y = -2
			if(EAST)
				warn_lights.pixel_x = 2
			if(WEST)
				warn_lights.pixel_x = -2
	return ..()

/obj/machinery/door/firedoor/border_only/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(!(border_dir == dir)) //Make sure looking at appropriate border
		return TRUE

/obj/machinery/door/firedoor/border_only/proc/on_exit(datum/source, atom/movable/leaving, direction)
	SIGNAL_HANDLER
	if(leaving.movement_type & PHASING)
		return
	if(leaving == src)
		return // Let's not block ourselves.

	if(direction == dir && density)
		leaving.Bump(src)
		return COMPONENT_ATOM_BLOCK_EXIT

/obj/machinery/door/firedoor/border_only/CanAtmosPass(turf/T)
	if(get_dir(loc, T) == dir)
		return !density
	else
		return TRUE

/obj/machinery/door/firedoor/heavy
	name = "heavy firelock"
	icon = 'icons/obj/doors/Doorfire.dmi'
	glass = FALSE
	explosion_block = 2
	assemblytype = /obj/structure/firelock_frame/heavy
	max_integrity = 550


/obj/item/electronics/firelock
	name = "firelock circuitry"
	desc = "A circuit board used in construction of firelocks."
	icon_state = "mainboard"

/obj/structure/firelock_frame
	name = "firelock frame"
	desc = "A partially completed firelock."
	icon = 'icons/obj/doors/Doorfire.dmi'
	icon_state = "frame1"
	base_icon_state = "frame"
	anchored = FALSE
	density = TRUE
	var/constructionStep = CONSTRUCTION_NO_CIRCUIT
	var/reinforced = 0

/obj/structure/firelock_frame/examine(mob/user)
	. = ..()
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			. += span_notice("It is <i>unbolted</i> from the floor. The circuit could be removed with a <b>crowbar</b>.")
			if(!reinforced)
				. += span_notice("It could be reinforced with plasteel.")
		if(CONSTRUCTION_NO_CIRCUIT)
			. += span_notice("There are no <i>firelock electronics</i> in the frame. The frame could be <b>welded</b> apart .")

/obj/structure/firelock_frame/update_icon_state()
	icon_state = "[base_icon_state][constructionStep]"
	return ..()

/obj/structure/firelock_frame/attackby(obj/item/object, mob/user)
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			if(object.tool_behaviour == TOOL_CROWBAR)
				object.play_tool_sound(src)
				user.visible_message(span_notice("[user] begins removing the circuit board from [src]..."), \
					span_notice("You begin prying out the circuit board from [src]..."))
				if(!object.use_tool(src, user, DEFAULT_STEP_TIME))
					return
				if(constructionStep != CONSTRUCTION_PANEL_OPEN)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				user.visible_message(span_notice("[user] removes [src]'s circuit board."), \
					span_notice("You remove the circuit board from [src]."))
				new /obj/item/electronics/firelock(drop_location())
				constructionStep = CONSTRUCTION_NO_CIRCUIT
				update_appearance()
				return
			if(object.tool_behaviour == TOOL_WRENCH)
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					to_chat(user, span_warning("There's already a firelock there."))
					return
				object.play_tool_sound(src)
				user.visible_message(span_notice("[user] starts bolting down [src]..."), \
					span_notice("You begin bolting [src]..."))
				if(!object.use_tool(src, user, DEFAULT_STEP_TIME))
					return
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					return
				user.visible_message(span_notice("[user] finishes the firelock."), \
					span_notice("You finish the firelock."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				if(reinforced)
					new /obj/machinery/door/firedoor/heavy(get_turf(src))
				else
					new /obj/machinery/door/firedoor(get_turf(src))
				qdel(src)
				return
			if(istype(object, /obj/item/stack/sheet/plasteel))
				var/obj/item/stack/sheet/plasteel/plasteel_sheet = object
				if(reinforced)
					to_chat(user, span_warning("[src] is already reinforced."))
					return
				if(plasteel_sheet.get_amount() < 2)
					to_chat(user, span_warning("You need more plasteel to reinforce [src]."))
					return
				user.visible_message(span_notice("[user] begins reinforcing [src]..."), \
					span_notice("You begin reinforcing [src]..."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				if(do_after(user, DEFAULT_STEP_TIME, target = src))
					if(constructionStep != CONSTRUCTION_PANEL_OPEN || reinforced || plasteel_sheet.get_amount() < 2 || !plasteel_sheet)
						return
					user.visible_message(span_notice("[user] reinforces [src]."), \
						span_notice("You reinforce [src]."))
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
					plasteel_sheet.use(2)
					reinforced = 1
				return
		if(CONSTRUCTION_NO_CIRCUIT)
			if(istype(object, /obj/item/electronics/firelock))
				user.visible_message(span_notice("[user] starts adding [object] to [src]..."), \
					span_notice("You begin adding a circuit board to [src]..."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				if(!do_after(user, DEFAULT_STEP_TIME, target = src))
					return
				if(constructionStep != CONSTRUCTION_NO_CIRCUIT)
					return
				qdel(object)
				user.visible_message(span_notice("[user] adds a circuit to [src]."), \
					span_notice("You insert and secure [object]."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, TRUE)
				constructionStep = CONSTRUCTION_PANEL_OPEN
				return
			if(object.tool_behaviour == TOOL_WELDER)
				if(!object.tool_start_check(user, amount=1))
					return
				user.visible_message(span_notice("[user] begins cutting apart [src]'s frame..."), \
					span_notice("You begin slicing [src] apart..."))

				if(object.use_tool(src, user, DEFAULT_STEP_TIME, volume=50, amount=1))
					if(constructionStep != CONSTRUCTION_NO_CIRCUIT)
						return
					user.visible_message(span_notice("[user] cuts apart [src]!"), \
						span_notice("You cut [src] into metal."))
					var/turf/tagetloc = get_turf(src)
					new /obj/item/stack/sheet/iron(tagetloc, 3)
					if(reinforced)
						new /obj/item/stack/sheet/plasteel(tagetloc, 2)
					qdel(src)
				return
			if(istype(object, /obj/item/electroadaptive_pseudocircuit))
				var/obj/item/electroadaptive_pseudocircuit/raspberrypi = object
				if(!raspberrypi.adapt_circuit(user, DEFAULT_STEP_TIME * 0.5))
					return
				user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
				span_notice("You adapt a firelock circuit and slot it into the assembly."))
				constructionStep = CONSTRUCTION_PANEL_OPEN
				update_appearance()
				return
	return ..()

/obj/structure/firelock_frame/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode == RCD_DECONSTRUCT)
		return list("mode" = RCD_DECONSTRUCT, "delay" = 50, "cost" = 16)
	else if((constructionStep == CONSTRUCTION_NO_CIRCUIT) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/structure/firelock_frame/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
			span_notice("You adapt a firelock circuit and slot it into the assembly."))
			constructionStep = CONSTRUCTION_PANEL_OPEN
			update_appearance()
			return TRUE
		if(RCD_DECONSTRUCT)
			to_chat(user, span_notice("You deconstruct [src]."))
			qdel(src)
			return TRUE
	return FALSE

/obj/structure/firelock_frame/heavy
	name = "heavy firelock frame"
	reinforced = TRUE

#undef CONSTRUCTION_PANEL_OPEN
#undef CONSTRUCTION_NO_CIRCUIT
#undef DETECT_COOLDOWN_STEP_TIME
