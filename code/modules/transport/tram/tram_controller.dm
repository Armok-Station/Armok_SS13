/**
 * Tram specific variant of the generic linear transport controller.
 *
 * Hierarchy
 * The sstransport subsystem manages a list of controllers,
 * A controller manages a list of transport modules (individual tiles) which together make up a transport unit (in this case a tram)
 */
/datum/transport_controller/linear/tram

	///whether this controller is active (any state we don't accept new orders, not nessecarily moving)
	var/controller_active = FALSE
	///whether all required parts of the tram are considered operational
	var/controller_operational = TRUE
	var/obj/machinery/icts/tram_controller/paired_cabinet
	///if we're travelling, what direction are we going
	var/travel_direction = NONE
	///if we're travelling, how far do we have to go
	var/travel_remaining = 0
	///how far in total we'll be travelling
	var/travel_trip_length = 0

	///multiplier on how much damage/force the tram imparts on things it hits
	var/collision_lethality = 1
	var/obj/effect/landmark/icts/nav_beacon/tram/nav/nav_beacon
	/// reference to the destination landmarks we consider ourselves "at" or travelling towards. since we potentially span multiple z levels we dont actually
	/// know where on us this platform is. as long as we know THAT its on us we can just move the distance and direction between this
	/// and the destination landmark.
	var/obj/effect/landmark/icts/nav_beacon/tram/platform/idle_platform
	/// reference to the destination landmarks we consider ourselves travelling towards. since we potentially span multiple z levels we dont actually
	/// know where on us this platform is. as long as we know THAT its on us we can just move the distance and direction between this
	/// and the destination landmark.
	var/obj/effect/landmark/icts/nav_beacon/tram/platform/destination_platform

	var/current_speed = 0
	var/current_load = 0

	///decisecond delay between horizontal movement. cannot make the tram move faster than 1 movement per world.tick_lag.
	var/speed_limiter = 0.5

	///version of speed_limiter that gets set in init and is considered our base speed if our lift gets slowed down
	var/base_speed_limiter = 0.5

	///the world.time we should next move at. in case our speed is set to less than 1 movement per tick
	var/scheduled_move = INFINITY

	///whether we have been slowed down automatically
	var/recovery_mode = FALSE

	///how many times we moved while costing more than SStransport.max_time milliseconds per movement.
	///if this exceeds SStransport.max_exceeding_moves
	var/recovery_activate_count = 0

	///how many times we moved while costing less than 0.5 * SStransport.max_time milliseconds per movement
	var/recovery_clear_count = 0

	var/datum/tram_mfg_info/tram_registration

/datum/tram_mfg_info
	var/serial_number
	var/mfg_date
	var/install_location
	var/distance_travelled = 0
	var/collisions = 0

/**
 * Assign registration details to a new tram.
 *
 * When a new tram is created, we give it a builder's plate with the date it was created.
 * We track a few stats about it, and keep a small historical record on the
 * information plate inside the tram.
 */
/datum/tram_mfg_info/New(specific_transport_id)
	if(GLOB.round_id)
		serial_number = "LT306TG[add_leading(GLOB.round_id, 6, 0)]"
	else
		serial_number = "LT306TG[rand(000000, 999999)]"
	mfg_date = world.realtime
	install_location = specific_transport_id

/**
 * Loads persistent tram data from the JSON save file on initialization.
 */
/datum/tram_mfg_info/proc/load_data(list/tram_data)
	serial_number = text2path(tram_data["serial_number"])
	mfg_date = text2path(tram_data["mfg_date"])
	install_location = text2path(tram_data["install_location"])
	distance_travelled = text2path(tram_data["distance_travelled"])
	collisions = text2path(tram_data["collisions"])
	return TRUE

/**
 * Provide JSON formatted data to the persistence subsystem to save at round end.
 */
/datum/transport_controller/linear/tram/proc/get_json_data()
	. = list()
	.["serial_number"] = tram_registration.serial_number
	.["mfg_date"] = tram_registration.mfg_date
	.["install_location"] = tram_registration.install_location
	.["distance_travelled"] = tram_registration.distance_travelled
	.["collisions"] = tram_registration.collisions

/**
 * Make sure all modules have matching speed limiter vars, pull save data from persistence
 *
 * We track a few stats about it, and keep a small historical record on the
 * information plate inside the tram.
 */
/datum/transport_controller/linear/tram/New(obj/structure/transport/linear/tram/transport_module)
	. = ..()
	speed_limiter = transport_module.speed_limiter
	base_speed_limiter = transport_module.speed_limiter
	tram_registration = SSpersistence.load_tram_stats(specific_transport_id)

	if(!tram_registration)
		tram_registration = new /datum/tram_mfg_info(specific_transport_id)

	check_starting_landmark()

/**
 * If someone VVs the base speed limiter of the tram, copy it to the current active speed limiter.
 */
/datum/transport_controller/linear/tram/vv_edit_var(var_name, var_value)
	. = ..()
	if(var_name == "base_speed_limiter")
		speed_limiter = max(speed_limiter, base_speed_limiter)

/datum/transport_controller/linear/tram/Destroy()
	paired_cabinet = null
	set_status_code(SYSTEM_FAULT, TRUE)

	..()

/**
 * Register transport modules to the controller
 *
 * Spreads out searching neighbouring tiles for additional transport modules, to combine into one full tram.
 * We register to every module's signal that it's collided with something, be it mob, structure, etc.
 */
/datum/transport_controller/linear/tram/add_transport_modules(obj/structure/transport/linear/new_transport_module)
	. = ..()
	RegisterSignal(new_transport_module, COMSIG_MOVABLE_BUMP, PROC_REF(gracefully_break))

/**
 * The mapper should have placed the tram at one of the stations, the controller will search for a landmark within
 * its control area and set it as its idle position.
 */
/datum/transport_controller/linear/tram/check_for_landmarks(obj/structure/transport/linear/tram/new_transport_module)
	. = ..()
	for(var/turf/platform_loc as anything in new_transport_module.locs)
		var/obj/effect/landmark/icts/nav_beacon/tram/platform/initial_destination = locate() in platform_loc
		var/obj/effect/landmark/icts/nav_beacon/tram/nav/beacon = locate() in platform_loc

		if(initial_destination)
			idle_platform = initial_destination

		if(beacon)
			nav_beacon = beacon

/**
 * Verify tram is in a valid starting location, start the subsystem.
 *
 * Throw an error if someone mapped a tram with no landmarks available for it to register.
 * The processing subsystem starts off because not all maps have elevators/transports.
 * Now that the tram is aware of its surroundings, we start the subsystem.
 */
/datum/transport_controller/linear/tram/proc/check_starting_landmark()
	if(!idle_platform || !nav_beacon)
		CRASH("a tram lift_master was initialized without the required landmarks to give it direction!")

	SStransport.can_fire = TRUE

	return TRUE

/**
 * The tram explodes if it hits a few types of objects.
 *
 * Signal for when the tram runs into a field of which it cannot go through.
 * Stops the train's travel fully, sends a message, and destroys the train.
 * Arguments:
 * * bumped_atom - The atom this tram bumped into
 */
/datum/transport_controller/linear/tram/proc/gracefully_break(atom/bumped_atom)
	SIGNAL_HANDLER

	travel_remaining = 0
	bumped_atom.visible_message(span_userdanger("The [bumped_atom.name] crashes into the field violently!"))
	for(var/obj/structure/transport/linear/tram/transport_module as anything in transport_modules)
		transport_module.set_travelling(FALSE)
		for(var/explosive_target in transport_module.transport_contents)
			if(iseffect(explosive_target))
				continue

			if(isliving(explosive_target))
				explosion(explosive_target, devastation_range = rand(0, 1), heavy_impact_range = 2, light_impact_range = 3) //50% chance of gib

			else if(prob(9))
				explosion(explosive_target, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 3)

			explosion(transport_module, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 3)
			qdel(transport_module)

		for(var/obj/machinery/icts/destination_sign/desto as anything in SStransport.displays)
			desto.icon_state = "[desto.base_icon_state][DESTINATION_NOT_IN_SERVICE]"

		for(var/obj/machinery/icts/crossing_signal/xing as anything in SStransport.crossing_signals)
			xing.set_signal_state(XING_STATE_MALF)
			xing.update_appearance()

/**
 * Calculate the journey details to the requested platform
 *
 * These will eventually be passed to the transport modules as args telling them where to move.
 * We do some sanity checking in case of discrepencany between where the subsystem thinks the
 * tram is and where the tram actually is. (For example, moving the landmarks after round start.)
 *
 * TODO: the message_admins is just for debugging. remove before PRing. ideally the tram will
 * self-recover with the SYSTEM_FAULT operational status if it finds a mismatch between subsystem
 * and controller.
 */
/datum/transport_controller/linear/tram/proc/calculate_route(obj/effect/landmark/icts/nav_beacon/tram/destination)
	if(destination == idle_platform)
		return FALSE

	destination_platform = destination
	travel_direction = get_dir(nav_beacon, destination_platform)
	travel_remaining = get_dist(nav_beacon, destination_platform)
	travel_trip_length = travel_remaining
	return TRUE

/**
 * Handles moving the tram
 *
 * Called by the subsystem, the controller tells the individual tram parts where to actually go and has extra safety checks
 * incase multiple inputs get through, preventing conflicting directions and the tram literally ripping itself apart.
 * All of the actual movement is handled by SStransport.
 *
 * If we're this far all the PRE_DEPARTURE checks should have passed, so we leave the PRE_DEPARTURE status and actually move.
 * We send a signal to anything registered that cares about the physical movement of the tram.
 *
 * Arguments:
 * * destination_platform - where the subsystem wants it to go
 */

/datum/transport_controller/linear/tram/proc/dispatch_transport(obj/effect/landmark/icts/nav_beacon/tram/destination_platform)
	set_status_code(PRE_DEPARTURE, FALSE)
	SEND_SIGNAL(src, COMSIG_TRAM_TRAVEL, idle_platform, destination_platform)

	for(var/obj/structure/transport/linear/tram/transport_module as anything in transport_modules) //only thing everyone needs to know is the new location.
		if(transport_module.travelling) //wee woo wee woo there was a double action queued. damn multi tile structs
			return //we don't care to undo cover_locked controls, though, as that will resolve itself
		transport_module.glide_size_override = DELAY_TO_GLIDE_SIZE(speed_limiter)
		transport_module.set_travelling(TRUE)

	scheduled_move = world.time + speed_limiter

	START_PROCESSING(SStransport, src)

/**
 * Tram processing loop
 *
 * Moves the tram to its set destination.
 * When it arrives at its destination perform callback to the post-arrival procs like controls and lights.
 * We update the odometer and kill the process until we need to move again.area
 *
 * TODO: If the status is EMERGENCY_STOP the tram should immediately come to a stop regardless of the
 * travel_remaining. Some extra things happen in an emergency stop (throwing the passengers) and it will
 * run a recovery procedure to head to the nearest platform and 'reset' once the issue is resolved.
 */
/datum/transport_controller/linear/tram/process(seconds_per_tick)
	if(isnull(paired_cabinet))
		halt_and_catch_fire()
		return PROCESS_KILL

	if(!travel_remaining)
		if(!controller_operational)
			degraded_stop()
			return PROCESS_KILL

		normal_stop()
		return PROCESS_KILL

	else if(world.time >= scheduled_move)
		var/start_time = TICK_USAGE
		travel_remaining--

		move_transport_horizontally(travel_direction)

		var/duration = TICK_USAGE_TO_MS(start_time)
		current_load = duration
		current_speed = transport_modules[1].glide_size
		if(recovery_mode)
			if(duration <= (SStransport.max_time / 2))
				recovery_clear_count++
			else
				recovery_clear_count = 0

			if(recovery_clear_count >= SStransport.max_cheap_moves)
				speed_limiter = base_speed_limiter
				recovery_mode = FALSE
				recovery_clear_count = 0

		else if(duration > SStransport.max_time)
			recovery_activate_count++

			if(recovery_activate_count >= SStransport.max_exceeding_moves)
				message_admins("The tram at [ADMIN_JMP(transport_modules[1])] is taking more than [SStransport.max_time] milliseconds per movement, halving its movement speed. if this continues to be a problem you can call reset_lift_contents() on the trams transport_controller_datum to reset it to its original state and clear added objects")
				speed_limiter = base_speed_limiter * 2 //halves its speed
				recovery_mode = TRUE
				recovery_activate_count = 0
		else
			recovery_activate_count = max(recovery_activate_count - 1, 0)

		scheduled_move = world.time + speed_limiter

/datum/transport_controller/linear/tram/proc/normal_stop()
	cycle_doors(OPEN_DOORS)
	addtimer(CALLBACK(src, PROC_REF(unlock_controls)), 2 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(set_lights)), 2.2 SECONDS)
	idle_platform = destination_platform
	tram_registration["distance_travelled"] += (travel_trip_length - travel_remaining)
	travel_trip_length = 0
	current_speed = 0
	current_load = 0

/datum/transport_controller/linear/tram/proc/degraded_stop()
	addtimer(CALLBACK(src, PROC_REF(unlock_controls)), 4 SECONDS)
	set_lights(estop = TRUE)
	idle_platform = destination_platform
	tram_registration["distance_travelled"] += (travel_trip_length - travel_remaining)
	travel_trip_length = 0
	current_speed = 0
	current_load = 0
	var/throw_direction = travel_direction
	for(var/obj/structure/transport/linear/tram/module in transport_modules)
		module.estop_throw(throw_direction)

/datum/transport_controller/linear/tram/proc/halt_and_catch_fire()
	if(travel_remaining)
		travel_remaining = 0
		var/throw_direction = travel_direction
		for(var/obj/structure/transport/linear/tram/module in transport_modules)
			module.estop_throw(throw_direction)

	addtimer(CALLBACK(src, PROC_REF(unlock_controls)), 4 SECONDS)
	idle_platform = null
	tram_registration["distance_travelled"] += (travel_trip_length - travel_remaining)
	travel_trip_length = 0
	current_speed = 0
	current_load = 0
	set_active(FALSE)
	set_status_code(SYSTEM_FAULT, TRUE)
	for(var/obj/machinery/door/airlock/tram/door as anything in SStransport.doors)
		door.open()

/**
 * Handles unlocking the tram controls for use after moving
 *
 * More safety checks to make sure the tram has actually docked properly
 * at a location before users are allowed to interact with the tram console again.
 * Tram finds its location at this point before fully unlocking controls to the user.
 */
/datum/transport_controller/linear/tram/proc/unlock_controls()
	controls_lock(FALSE)
	for(var/obj/structure/transport/linear/tram/transport_module as anything in transport_modules) //only thing everyone needs to know is the new location.
		transport_module.set_travelling(FALSE)
	set_active(FALSE)

/**
 * Send a signal to any lights associated with the tram so they can change based on the status and direction.
 */
/datum/transport_controller/linear/tram/proc/set_lights(estop = FALSE)
	SEND_SIGNAL(src, COMSIG_TRANSPORT_LIGHTS, controller_active, controller_status, travel_direction, estop)

/**
 * Sets the active status for the controller and sends a signal to listeners.
 *
 * The main signal used by most components, it has the active status, the bitfield of the controller's status, its direction, and set destination.
 *
 * Arguments:
 * new_status - The active status of the controller (whether it's busy doing something and not taking commands right now)
 */
/datum/transport_controller/linear/tram/proc/set_active(new_status)
	if(controller_active == new_status)
		return

	controller_active = new_status
	SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_ACTIVE, src, controller_active, controller_status, travel_direction, destination_platform)

/**
 * Sets the controller status bitfield
 *
 * This status var is used by various components like lights, crossing signals, signs
 * Sent via signal the listening components will perform required actions based on
 * the status codes.
 *
 * Arguments:
 * * code - The status bitflag we're changing
 * * value - boolean TRUE/FALSE to set the code
 */
/datum/transport_controller/linear/tram/proc/set_status_code(code, value)
	switch(value)
		if(TRUE)
			controller_status |= code
		if(FALSE)
			controller_status &= ~code
		else
			stack_trace("Transport controller received invalid status code request [code]/[value]")
			return

	SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_ACTIVE, src, controller_active, controller_status, travel_direction, destination_platform)

/**
 * Part of the pre-departure list, checks the status of the doors on the tram
 *
 * Checks if all doors are closed, and updates the status code accordingly.
 *
 * TODO: this is probably better renamed check_door_status()
 */
/datum/transport_controller/linear/tram/proc/update_status()
	set_status_code(DOORS_OPEN, FALSE)
	for(var/obj/machinery/door/airlock/tram/door as anything in SStransport.doors)
		if(door.transport_linked_id == specific_transport_id)
			if(door.airlock_state != 1)
				set_status_code(DOORS_OPEN, TRUE)
				break

/**
 * Cycle all the doors on the tram.
 */
/datum/transport_controller/linear/tram/proc/cycle_doors(door_status)
	switch(door_status)
		if(OPEN_DOORS)
			for(var/obj/machinery/door/airlock/tram/door as anything in SStransport.doors)
				if(door.transport_linked_id == specific_transport_id)
					INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/airlock/tram, open))

		if(CLOSE_DOORS)
			for(var/obj/machinery/door/airlock/tram/door as anything in SStransport.doors)
				if(door.transport_linked_id == specific_transport_id)
					INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/airlock/tram, close))

	update_status()

/datum/transport_controller/linear/tram/proc/notify_controller(obj/machinery/icts/tram_controller/new_cabinet)
	paired_cabinet = new_cabinet
	RegisterSignal(new_cabinet, COMSIG_MACHINERY_POWER_LOST, PROC_REF(power_lost))
	RegisterSignal(new_cabinet, COMSIG_MACHINERY_POWER_RESTORED, PROC_REF(power_restored))
	RegisterSignal(new_cabinet, COMSIG_QDELETING, PROC_REF(on_cabinet_qdel))
	if(controller_status & SYSTEM_FAULT)
		set_status_code(SYSTEM_FAULT, FALSE)

/datum/transport_controller/linear/tram/proc/on_cabinet_qdel()
	paired_cabinet = null
	set_status_code(SYSTEM_FAULT, TRUE)

/**
 * Tram malfunction random event. Set comm error, increase tram lethality.
 */
/datum/transport_controller/linear/tram/proc/start_malf_event()
	set_status_code(SYSTEM_FAULT, TRUE)
	set_status_code(COMM_ERROR, TRUE)
	SEND_TRANSPORT_SIGNAL(COMSIG_COMMS_STATUS, src, FALSE)
	paired_cabinet.generate_repair_signals()
	collision_lethality = 1.25

/**
 * Remove effects of tram malfunction event.
 *
 * If engineers didn't already repair the tram by the end of the event,
 * automagically reset it remotely.
 */
/datum/transport_controller/linear/tram/proc/end_malf_event()
	if(!(controller_status & COMM_ERROR))
		return
	set_status_code(COMM_ERROR, FALSE)
	paired_cabinet.clear_repair_signals()
	collision_lethality = initial(collision_lethality)
	SEND_TRANSPORT_SIGNAL(COMSIG_COMMS_STATUS, src, TRUE)

/datum/transport_controller/linear/tram/proc/register_collision()
	tram_registration["collisions"] += 1

/datum/transport_controller/linear/tram/proc/power_lost()
	controller_operational = FALSE
	SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_ACTIVE, src, controller_active, controller_status, travel_direction, destination_platform)

/datum/transport_controller/linear/tram/proc/power_restored()
	controller_operational = TRUE
	SEND_TRANSPORT_SIGNAL(COMSIG_TRANSPORT_ACTIVE, src, controller_active, controller_status, travel_direction, destination_platform)

/datum/transport_controller/linear/tram/proc/set_operational(new_value)
	if(controller_operational != new_value)
		controller_operational = new_value

/**
 * Returns the closest tram nav beacon to an atom
 *
 * Creates a list of nav beacons in the requested direction
 * and returns the closest to be passed to the industrial_lift
 *
 * Arguments: source: the starting point to find a beacon
 *            travel_dir: travel direction in tram form, INBOUND or OUTBOUND
 *            beacon_type: what list of beacons we pull from
 */
/datum/transport_controller/linear/tram/proc/closest_nav_in_travel_dir(atom/origin, travel_dir, beacon_type)
	if(!istype(origin) || !origin.z)
		return FALSE

	var/list/obj/effect/landmark/icts/nav_beacon/tram/inbound_candidates = list()
	var/list/obj/effect/landmark/icts/nav_beacon/tram/outbound_candidates = list()

	for(var/obj/effect/landmark/icts/nav_beacon/tram/candidate_beacon in SStransport.nav_beacons[beacon_type])
		if(candidate_beacon.z != origin.z || candidate_beacon.z != nav_beacon.z)
			continue

		switch(nav_beacon.dir)
			if(EAST, WEST)
				if(candidate_beacon.y != nav_beacon.y)
					continue
				else if(candidate_beacon.x < nav_beacon.x)
					inbound_candidates += candidate_beacon
				else
					outbound_candidates += candidate_beacon
			if(NORTH, SOUTH)
				if(candidate_beacon.x != nav_beacon.x)
					continue
				else if(candidate_beacon.y < nav_beacon.y)
					inbound_candidates += candidate_beacon
				else
					outbound_candidates += candidate_beacon

	switch(travel_dir)
		if(INBOUND)
			var/obj/effect/landmark/icts/nav_beacon/tram/nav/selected = get_closest_atom(/obj/effect/landmark/icts/nav_beacon/tram, inbound_candidates, origin)
			if(selected)
				return selected
			stack_trace("No inbound beacon candidate found for [origin]. Cancelling dispatch.")
			return FALSE

		if(OUTBOUND)
			var/obj/effect/landmark/icts/nav_beacon/tram/nav/selected = get_closest_atom(/obj/effect/landmark/icts/nav_beacon/tram, outbound_candidates, origin)
			if(selected)
				return selected
			stack_trace("No outbound beacon candidate found for [origin]. Cancelling dispatch.")
			return FALSE

		else
			stack_trace("Tram receieved invalid travel direction [travel_dir]. Cancelling dispatch.")

	return FALSE

/**
 * Moves the tram when hit by an immovable rod
 *
 * Tells the individual tram parts where to actually go and has an extra safety checks
 * incase multiple inputs get through, preventing conflicting directions and the tram
 * literally ripping itself apart. all of the actual movement is handled by SStramprocess
 *
 * Arguments: collided_rod (the immovable rod that hit the tram)
 * Return: push_destination (the landmark /obj/effect/landmark/tram/nav that the tram is being pushed to due to the rod's trajectory)
 */
/datum/transport_controller/linear/tram/proc/rod_collision(obj/effect/immovablerod/collided_rod)
	if(!controller_operational)
		return
	var/rod_velocity_sign
	// Determine inbound or outbound
	if(collided_rod.dir & (NORTH|SOUTH))
		rod_velocity_sign = collided_rod.dir & NORTH ? OUTBOUND : INBOUND
	else
		rod_velocity_sign = collided_rod.dir & EAST ? OUTBOUND : INBOUND

	var/obj/effect/landmark/icts/nav_beacon/tram/nav/push_destination = closest_nav_in_travel_dir(origin = nav_beacon, travel_dir = rod_velocity_sign, beacon_type = IMMOVABLE_ROD_DESTINATIONS)
	if(!push_destination)
		return
	travel_direction = get_dir(nav_beacon, push_destination)
	travel_remaining = get_dist(nav_beacon, push_destination)
	travel_trip_length = travel_remaining
	destination_platform = push_destination
	// Don't bother processing crossing signals, where this tram's going there are no signals
	//for(var/obj/machinery/icts/crossing_signal/xing as anything in SStransport.crossing_signals)
	//	xing.temp_malfunction()
	priority_announce("In a turn of rather peculiar events, it appears that [GLOB.station_name] has struck an immovable rod. (Don't ask us where it came from.) This has led to a station brakes failure on one of the tram platforms.\n\n\
		Our diligent team of engineers have been informed and they're rushing over - although not quite at the speed of our recently flying tram.\n\n\
		So while we all look in awe at the universe's mysterious sense of humour, please stand clear of the tracks and remember to stand behind the yellow line.", "Braking News")
	set_active(TRUE)
	set_status_code(CONTROLS_LOCKED, TRUE)
	dispatch_transport(destination_platform = push_destination)
	set_operational(FALSE)
	return push_destination

/**
 * The physical cabinet on the tram. Acts as the interface between players and the controller datum.
 */
/obj/machinery/icts/tram_controller
	name = "tram controller"
	desc = "Makes the tram go, or something."
	icon = 'icons/obj/tram/tram_controllers.dmi'
	icon_state = "controller-panel"
	anchored = TRUE
	density = FALSE
	armor_type = /datum/armor/transport_module
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	max_integrity = 750
	integrity_failure = 0.25
	layer = SIGN_LAYER
	req_access = list(ACCESS_TCOMMS)
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION * 4.8
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 4.8
	var/datum/transport_controller/linear/tram/controller_datum
	/// If the cover is open
	var/cover_open = FALSE
	/// If the cover is locked
	var/cover_locked = FALSE

/obj/machinery/icts/tram_controller/Initialize(mapload)
	. = ..()
	register_context()
	return INITIALIZE_HINT_LATELOAD

/**
 * Mapped or built tram cabinet isn't located on a transport module.
 */
/obj/machinery/icts/tram_controller/LateInitialize(mapload)
	. = ..()

	find_controller()
	update_appearance()

/obj/machinery/icts/tram_controller/atom_break()
	set_machine_stat(machine_stat | BROKEN)
	..()

/obj/machinery/icts/tram_controller/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	if(held_item?.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_RMB] = panel_open ? "close panel" : "open panel"

	if(!held_item && !cover_locked)
		context[SCREENTIP_CONTEXT_RMB] = cover_open ? "close cabinet" : "open cabinet"

	if(istype(held_item, /obj/item/card/id/) && allowed(user) && !cover_open)
		context[SCREENTIP_CONTEXT_LMB] = cover_locked ? "unlock cabinet" : "lock cabinet"

	if(panel_open)
		if(held_item?.tool_behaviour == TOOL_WRENCH)
			context[SCREENTIP_CONTEXT_RMB] = "unscrew cabinet"
		if(malfunctioning || methods_to_fix.len)
			context[SCREENTIP_CONTEXT_LMB] = "repair electronics"

	if(held_item?.tool_behaviour == TOOL_WELDER)
		context[SCREENTIP_CONTEXT_LMB] = "repair frame"

	if(istype(held_item, /obj/item/card/emag) && !(obj_flags & EMAGGED))
		context[SCREENTIP_CONTEXT_LMB] = "emag controller"

	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/icts/tram_controller/attackby(obj/item/weapon, mob/living/user, params)
	if(!user.combat_mode)
		if(weapon && istype(weapon, /obj/item/card/id) && !cover_open)
			return try_toggle_lock(user)

	return ..()

/obj/machinery/icts/tram_controller/wrench_act_secondary(mob/living/user, obj/item/tool)
	. = ..()
	if(panel_open)
		balloon_alert(user, "unsecuring...")
		tool.play_tool_sound(src)
		if(tool.use_tool(src, user, 6 SECONDS))
			playsound(loc, 'sound/items/deconstruct.ogg', 50, vary = TRUE)
			balloon_alert(user, "unsecured")
			deconstruct()

/obj/machinery/icts/tram_controller/deconstruct(disassembled = TRUE)
	if(flags_1 & NODECONSTRUCT_1)
		return
	if(disassembled)
		new /obj/item/wallframe/icts/tram_controller(drop_location())
	else
		new /obj/item/stack/sheet/mineral/titanium(drop_location(), 2)
		new /obj/item/stack/sheet/iron(drop_location(), 1)
		new /obj/item/shard(drop_location())
	qdel(src)

/**
 * Update the blinky lights based on the controller status, allowing to quickly check without opening up the cabinet.
 */
/obj/machinery/icts/tram_controller/update_overlays()
	. = ..()

	if(!cover_open)
		. += mutable_appearance(icon, "controller-closed")

	else
		var/mutable_appearance/controller_door = mutable_appearance(icon, "controller-open")
		controller_door.pixel_w = -3
		. += controller_door

	if(machine_stat & NOPOWER)
		. += mutable_appearance(icon, "estop")
		. += emissive_appearance(icon, "estop", src, alpha = src.alpha)
		return

	. += mutable_appearance(icon, "power")
	. += emissive_appearance(icon, "power", src, alpha = src.alpha)

	if(!controller_datum)
		. += mutable_appearance(icon, "fatal")
		. += emissive_appearance(icon, "fatal", src, alpha = src.alpha)
		return

	if(controller_datum.controller_status & DOORS_OPEN)
		. += mutable_appearance(icon, "doors")
		. += emissive_appearance(icon, "doors", src, alpha = src.alpha)

	if(controller_datum.controller_active)
		. += mutable_appearance(icon, "active")
		. += emissive_appearance(icon, "active", src, alpha = src.alpha)

	else if(controller_datum.controller_status & SYSTEM_FAULT)
		. += mutable_appearance(icon, "fault")
		. += emissive_appearance(icon, "fault", src, alpha = src.alpha)

	else if(controller_datum.controller_status & COMM_ERROR)
		. += mutable_appearance(icon, "comms")
		. += emissive_appearance(icon, "comms", src, alpha = src.alpha)

	else
		. += mutable_appearance(icon, "normal")
		. += emissive_appearance(icon, "normal", src, alpha = src.alpha)

/**
 * Find the controller associated with the transport module the cabinet is sitting on.
 */
/obj/machinery/icts/tram_controller/proc/find_controller()
	var/obj/structure/transport/linear/tram/tram_structure = locate() in src.loc
	if(!tram_structure)
		return

	controller_datum = tram_structure.transport_controller_datum
	if(!controller_datum)
		return

	controller_datum.notify_controller(src)
	RegisterSignal(SStransport, COMSIG_TRANSPORT_ACTIVE, PROC_REF(sync_controller))

/**
 * Since the machinery obj is a dumb terminal for the controller datum, sync the display with the status bitfield of the tram
 */
/obj/machinery/icts/tram_controller/proc/sync_controller(source, controller, controller_status, travel_direction, destination_platform)
	use_power(active_power_usage)
	if(controller != controller_datum)
		return
	update_appearance()

/obj/machinery/icts/tram_controller/attack_hand_secondary(mob/living/user, params)
	. = ..()

	if(cover_locked)
		return

	if(!cover_open)
		playsound(loc, 'sound/machines/closet_open.ogg', 35, TRUE, -3)
	else
		playsound(loc, 'sound/machines/closet_close.ogg', 50, TRUE, -3)
	cover_open = !cover_open
	update_appearance()
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/icts/tram_controller/proc/try_toggle_lock(mob/living/user, item, params)
	var/obj/item/card/id/id_card = user.get_idcard(TRUE)
	if(obj_flags & EMAGGED)
		balloon_alert(user, "access controller damaged!")
		return FALSE

	else if(check_access(id_card))
		cover_locked = !cover_locked
		balloon_alert(user, "controls [cover_locked ? "locked" : "unlocked"]")
		update_appearance()
		return TRUE

	else
		balloon_alert(user, "access denied")
		return FALSE

/obj/machinery/icts/tram_controller/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		balloon_alert(user, "already fried!")
		return FALSE
	obj_flags |= EMAGGED
	cover_locked = FALSE
	playsound(src, SFX_SPARKS, 100, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	balloon_alert(user, "access controller shorted")
	return TRUE

/**
 * Check if the tram was malfunctioning due to the random event, and if so end the event on repair.
 */
/obj/machinery/icts/tram_controller/try_fix_machine(obj/machinery/icts/machine, mob/living/user, obj/item/tool)
	. = ..()

	if(. == FALSE)
		return

	if(!controller_datum)
		return

	controller_datum.end_malf_event()

/obj/machinery/icts/tram_controller/ui_interact(mob/user, datum/tgui/ui)
	. = ..()

	if(!cover_open && !issilicon(user))
		return

	if(!is_operational)
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TramController")
		ui.open()

/obj/machinery/icts/tram_controller/ui_status(mob/user)
	if(!allowed(user))
		return UI_UPDATE

	return ..()

/obj/machinery/icts/tram_controller/ui_data(mob/user)
	var/list/data = list()

	data = list(
		"transportId" = controller_datum.specific_transport_id,
		"controllerActive" = controller_datum.controller_active,
		"controllerOperational" = controller_datum.controller_operational,
		"travelDirection" = controller_datum.travel_direction,
		"destinationPlatform" = controller_datum.destination_platform,
		"idlePlatform" = controller_datum.idle_platform,
		"recoveryMode" = controller_datum.recovery_mode,
		"currentSpeed" = controller_datum.current_speed,
		"currentLoad" = controller_datum.current_load,
	)

	return data

/obj/machinery/icts/tram_controller/ui_static_data(mob/user)
	var/list/data = list()
	data["destinations"] = SStransport.detailed_destination_list(controller_datum.specific_transport_id)

	return data

/obj/item/wallframe/icts/tram_controller
	name = "tram controller cabinet"
	desc = "A box that makes the tram go, or something. Just secure to the tram."
	icon = 'icons/obj/tram/tram_controllers.dmi'
	icon_state = "controller-panel"
	custom_materials = list(/datum/material/titanium = SHEET_MATERIAL_AMOUNT * 4, /datum/material/iron = SHEET_MATERIAL_AMOUNT * 2, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2)
	result_path = /obj/machinery/icts/tram_controller
	pixel_shift = 16
