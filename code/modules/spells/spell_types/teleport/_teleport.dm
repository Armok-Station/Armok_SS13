
/**
 * ## Teleport Spell
 *
 * Teleports the caster to a turf selected by get_destination().
 */
/datum/action/cooldown/spell/teleport
	sound = 'sound/weapons/zapbang.ogg'

	school = SCHOOL_TRANSLOCATION
	spell_requirements = (SPELL_REQUIRES_WIZARD_GARB|SPELL_REQUIRES_NON_ABSTRACT)

	/// A list of flags related to determining if our destination target is valid or not.
	var/destination_flags = NONE
	/// The sound played on arrival, after the teleport.
	var/post_teleport_sound = 'sound/weapons/zapbang.ogg'

/datum/action/cooldown/spell/teleport/cast(atom/cast_on)
	var/turf/destination = get_destination(cast_on)
	if(!destination)
		return

	if(do_teleport(cast_on, destination, channel = TELEPORT_CHANNEL_MAGIC))
		playsound(get_turf(user), post_teleport_sound, 50, TRUE)

/datum/action/cooldown/spell/teleport/proc/get_destination(atom/center)
	CRASH("[type] did not implement get_destination and either has no effects or implemented the spell incorrectly.")


/**
 * ###  Radius Teleport Spell
 *
 * A subtype of teleport that will teleport the caster
 * to a random turf within a radius of themselves.
 */
/datum/action/cooldown/spell/teleport/radius_turf
	/// The inner radius around the caster that we can teleport to
	var/inner_tele_radius = 1
	/// The outer radius around the caster that we can teleport to
	var/outer_tele_radius = 2

/datum/action/cooldown/spell/teleport/radius_turf/get_destination(atom/center)
	var/list/valid_turfs = list()
	var/list/possibles = RANGE_TURFS(outer_tele_radius, center)
	if(inner_tele_radius > 0)
		 possibles -= RANGE_TURFS(inner_tele_radius, center)

	for(var/turf/nearby_turf as anything in possibles)
		if(isspaceturf(nearby_turf) && (destination_flags & TELEPORT_SPELL_SKIP_SPACE))
			continue
		if(nearby_turf.density && (destination_flags & TELEPORT_SPELL_SKIP_DENSE))
			continue
		if(nearby_turf.is_blocked_turf(exlude_mobs = TRUE) && (destination_flags & TELEPORT_SPELL_SKIP_BLOCKED))
			continue

		if(nearby_turf.x > world.maxx - outer_tele_radius || nearby_turf.x < outer_tele_radius)
			continue //putting them at the edge is dumb
		if(nearby_turf.y > world.maxy - outer_tele_radius || nearby_turf.y < outer_tele_radius)
			continue
		valid_turfs += nearby_turf

	var/turf/picked_turf = length(valid_turfs) ? pick(valid_turfs) : pick(possibles)
	if(!istype(picked_turf))
		return

	return picked_turf

/datum/action/cooldown/spell/teleport/area_teleport
	destination_flags = TELEPORT_SPELL_SKIP_BLOCKED
	/// The last area we chose to teleport / where we're currently teleporting to, if mid-cast
	var/area/last_chosen_area_type
	/// If TRUE, the caster can select the destination area. Otherwise, random selection.
	var/randomise_selection = FALSE
	/// If the invocation appends the selected area when said. Requires invocation mode shout or whisper.
	var/invocation_says_area = TRUE

/datum/action/cooldown/spell/teleport/area_teleport/get_destination(atom/center)
	if(!ispath(last_chosen_area))
		CRSAH("[type] made it to get_destination without an area selected.")

	var/list/valid_turfs = list()
	for(var/turf/possible_destination as anything in get_area_turfs(last_chosen_area))
		if(isspaceturf(possible_destination) && (destination_flags & TELEPORT_SPELL_SKIP_SPACE))
			continue
		if(possible_destination.density && (destination_flags & TELEPORT_SPELL_SKIP_DENSE))
			continue
		if(possible_destination.is_blocked_turf(exlude_mobs = TRUE) && (destination_flags & TELEPORT_SPELL_SKIP_BLOCKED))
			continue

		valid_turfs += possible_destination

	if(!length(valid_turfs))
		to_chat(cast_on, span_warning("The spell matrix was unable to locate a suitable teleport destination."))
		return

	return pick(valid_turfs)

/datum/action/cooldown/spell/teleport/area_teleport/before_cast(list/targets)
	var/area/target_area
	if(randomise_selection)
		target_area = pick(GLOB.teleportlocs)
	else
		target_area = tgui_input_list(usr, "Chose an area to teleport to.", "Teleport", GLOB.teleportlocs)

	if(isnull(target_area) || isnull(GLOB.teleportlocs[target_area]))
		return FALSE

	last_chosen_area = target_area
	return TRUE

/datum/action/cooldown/spell/teleport/area_teleport/cast(atom/cast_on)
	cast_on.buckled?.unbuckle_mob(cast_on, force = TRUE)
	return ..()

/datum/action/cooldown/spell/teleport/area_teleport/invocation()
	var/area/last_chosen_area = GLOB.teleportlocs[last_chosen_area_type]

	if(!invocation_says_area || isnull(last_chosen_area)
		return ..()

	switch(invocation_type)
		if(INVOCATION_SHOUT)
			user.say("[invocation] [uppertext(last_chosen_area.name)]", forced = "spell ([src])")
		if(INVOCATION_WHISPER)
			user.whisper("[invocation] [uppertext(last_chosen_area.name)]", forced = "spell ([src])")
