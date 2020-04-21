
	//The mob should have a gender you want before running this proc. Will run fine without H
/datum/preferences/proc/random_character(gender_override, antag_override = FALSE)
	if(randomise[RANDOM_SPECIES])
		random_species()
	else if(randomise[RANDOM_NAME])
		real_name = pref_species.random_name(gender,1)
	if(gender_override && !(randomise[RANDOM_GENDER] || randomise[RANDOM_GENDER_ANTAG] && antag_override))
		gender = gender_override
	else
		gender = pick(MALE,FEMALE,PLURAL)
	if(randomise[RANDOM_AGE] || randomise[RANDOM_AGE_ANTAG] && antag_override)
		age = rand(AGE_MIN,AGE_MAX)
	if(randomise[RANDOM_UNDERWEAR])
		underwear = random_underwear(gender)
	if(randomise[RANDOM_UNDERWEAR_COLOR])
		underwear_color = random_short_color()
	if(randomise[RANDOM_UNDERSHIRT])
		undershirt = random_undershirt(gender)
	if(randomise[RANDOM_SOCKS])
		socks = random_socks()
	if(randomise[RANDOM_BACKPACK])
		backpack = random_backpack()
	if(randomise[RANDOM_JUMPSUIT_STYLE])
		jumpsuit_style = pick(GLOB.jumpsuitlist)
	if(randomise[RANDOM_HAIRSTYLE])
		hairstyle = random_hairstyle(gender)
	if(randomise[RANDOM_FACIAL_HAIRSTYLE])
		facial_hairstyle = random_facial_hairstyle(gender)
	if(randomise[RANDOM_HAIR_COLOR])
		hair_color = random_short_color()
	if(randomise[RANDOM_FACIAL_HAIR_COLOR])
		facial_hair_color = random_short_color()
	if(randomise[RANDOM_SKIN_TONE])
		skin_tone = random_skin_tone()
	if(randomise[RANDOM_EYE_COLOR])
		eye_color = random_eye_color()
	if(!pref_species)
		var/rando_race = pick(GLOB.roundstart_races)
		pref_species = new rando_race()
	features = random_features()

/datum/preferences/proc/random_species()
	var/random_species_type = GLOB.species_list[pick(GLOB.roundstart_races)]
	pref_species = new random_species_type
	if(randomise[RANDOM_NAME])
		real_name = pref_species.random_name(gender,1)

///Setup a hardcore random character and calculate their hardcore random score
/datum/preferences/proc/hardcore_random_setup(mob/living/carbon/human/character, antagonist)
	random_character(TRUE, antagonist)
	select_hardcore_quirks()
	hardcore_survival_score = hardcore_survival_score ** 1.2 //30 points would be about 60 score
	character.hardcore_survival_score = hardcore_survival_score

///Go through all quirks that can be used in hardcore mode and select some based on a random budget.
/datum/preferences/proc/select_hardcore_quirks()

	var/quirk_budget = rand(8, 35)


	all_quirks = list() //empty it out

	var/list/available_hardcore_quirks = SSquirks.hardcore_quirks.Copy()

	while(quirk_budget > 0)
		for(var/i in available_hardcore_quirks) //Remove from available quirks if its too expensive.
			var/datum/quirk/T = i
			if(available_hardcore_quirks[T] > quirk_budget)
				available_hardcore_quirks -= T

		var/datum/quirk/T = pick(available_hardcore_quirks)

		for(var/V in SSquirks.quirk_blacklist) //Check if the quirk is blacklisted. V is a list
			var/list/L = V
			for(var/Q in all_quirks)
				if((T in L) && (Q in L) && !(Q == T)) //two quirks have lined up in the list of the list of quirks that conflict with each other, so return (see quirks.dm for more details)
					available_hardcore_quirks -= T
					continue

		for(var/_V in all_quirks)//Check for dupes
			if(_V == T)
				available_hardcore_quirks -= T
				continue

		if(initial(T.mood_quirk) && CONFIG_GET(flag/disable_human_mood)) //check for moodlet quirks
			available_hardcore_quirks -= T
			continue

		all_quirks += initial(T.name)
		quirk_budget -= available_hardcore_quirks[T]
		hardcore_survival_score += available_hardcore_quirks[T]
		available_hardcore_quirks -= T

/datum/preferences/proc/update_preview_icon()
	// Determine what job is marked as 'High' priority, and dress them up as such.
	var/datum/job/previewJob
	var/highest_pref = 0
	for(var/job in job_preferences)
		if(job_preferences[job] > highest_pref)
			previewJob = SSjob.GetJob(job)
			highest_pref = job_preferences[job]

	if(previewJob)
		// Silicons only need a very basic preview since there is no customization for them.
		if(istype(previewJob,/datum/job/ai))
			parent.show_character_previews(image('icons/mob/ai.dmi', icon_state = resolve_ai_icon(preferred_ai_core_display), dir = SOUTH))
			return
		if(istype(previewJob,/datum/job/cyborg))
			parent.show_character_previews(image('icons/mob/robots.dmi', icon_state = "robot", dir = SOUTH))
			return

	// Set up the dummy for its photoshoot
	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	copy_to(mannequin, 1, TRUE, TRUE)

	if(previewJob)
		mannequin.job = previewJob.title
		previewJob.equip(mannequin, TRUE, preference_source = parent)

	COMPILE_OVERLAYS(mannequin)
	parent.show_character_previews(new /mutable_appearance(mannequin))
	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
