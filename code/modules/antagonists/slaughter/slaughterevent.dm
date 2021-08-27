/datum/round_event_control/slaughter
	name = "Spawn Slaughter Demon"
	typepath = /datum/round_event/ghost_role/slaughter
	weight = 1 //Very rare
	max_occurrences = 1
	earliest_start = 1 HOURS
	min_players = 20
	dynamic_should_hijack = TRUE



/datum/round_event/ghost_role/slaughter
	minimum_required = 1
	role_name = "slaughter demon"

/datum/round_event/ghost_role/slaughter/spawn_role()
	var/list/candidates = get_candidates(ROLE_ALIEN, ROLE_ALIEN)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)
	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/carpspawn/L in GLOB.landmarks_list)
		if(isturf(L.loc))
			spawn_locs += L.loc

	if(!spawn_locs)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/obj/effect/dummy/phased_mob/holder = new /obj/effect/dummy/phased_mob((pick(spawn_locs)))
	var/mob/living/simple_animal/hostile/imp/slaughter/demon = new (holder)
	demon.key = selected.key
	demon.mind.set_assigned_role(SSjob.GetJobType(/datum/job/slaughter_demon))
	demon.mind.special_role = ROLE_SLAUGHTER_DEMON
	demon.mind.add_antag_datum(/datum/antagonist/slaughter)
	to_chat(demon, demon.playstyle_string)
	to_chat(demon, "<B>You are currently not currently in the same plane of existence as the station. Blood Crawl near a blood pool to manifest.</B>")
	SEND_SOUND(demon, 'sound/magic/demon_dies.ogg')
	message_admins("[ADMIN_LOOKUPFLW(demon)] has been made into a slaughter demon by an event.")
	log_game("[key_name(demon)] was spawned as a slaughter demon by an event.")
	spawned_mobs += demon
	return SUCCESSFUL_SPAWN
