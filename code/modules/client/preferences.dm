GLOBAL_LIST_EMPTY(preferences_datums)

/// Cached object of info the client needs to represent species completely.
GLOBAL_VAR(preferences_species_data)

/datum/preferences
	var/client/parent
	//doohickeys for savefiles
	var/path
	var/default_slot = 1 //Holder so it doesn't default to slot 1, rather the last one used
	var/max_save_slots = 3

	//non-preference stuff
	var/muted = 0
	var/last_ip
	var/last_id

	//game-preferences
	var/lastchangelog = "" //Saved changlog filesize to detect if there was a change
	var/ooccolor = "#c43b23"
	var/asaycolor = "#ff4500" //This won't change the color for current admins, only incoming ones.
	/// If we spawn an ERT as an admin and choose to spawn as the briefing officer, we'll be given this outfit
	var/brief_outfit = /datum/outfit/centcom/commander
	var/enable_tips = TRUE
	var/tip_delay = 500 //tip delay in milliseconds

	//Antag preferences
	var/list/be_special = list() //Special role selection
	var/tmp/old_be_special = 0 //Bitflag version of be_special, used to update old savefiles and nothing more
										//If it's 0, that's good, if it's anything but 0, the owner of this prefs file's antag choices were,
										//autocorrected this round, not that you'd need to check that.

	var/UI_style = null
	var/buttons_locked = FALSE
	var/hotkeys = TRUE

	///Runechat preference. If true, certain messages will be displayed on the map, not ust on the chat area. Boolean.
	var/chat_on_map = TRUE
	///Limit preference on the size of the message. Requires chat_on_map to have effect.
	var/max_chat_length = CHAT_MESSAGE_MAX_LENGTH
	///Whether non-mob messages will be displayed, such as machine vendor announcements. Requires chat_on_map to have effect. Boolean.
	var/see_chat_non_mob = TRUE
	///Whether emotes will be displayed on runechat. Requires chat_on_map to have effect. Boolean.
	var/see_rc_emotes = TRUE

	// Custom Keybindings
	var/list/key_bindings = list()

	var/tgui_fancy = TRUE
	var/tgui_lock = FALSE
	var/windowflashing = TRUE
	var/toggles = TOGGLES_DEFAULT
	var/db_flags
	var/chat_toggles = TOGGLES_DEFAULT_CHAT
	var/ghost_form = "ghost"
	var/ghost_orbit = GHOST_ORBIT_CIRCLE
	var/ghost_accs = GHOST_ACCS_DEFAULT_OPTION
	var/ghost_others = GHOST_OTHERS_DEFAULT_OPTION
	var/ghost_hud = 1
	var/inquisitive_ghost = 1
	var/allow_midround_antag = 1
	var/preferred_map = null
	var/pda_style = MONO
	var/pda_color = "#808000"

	var/uses_glasses_colour = 0

	//character preferences
	var/slot_randomized //keeps track of round-to-round randomization of the character slot, prevents overwriting
	var/real_name //our character's name
	var/gender = MALE //gender of character (well duh)
	var/age = 30 //age of character
	var/underwear_color = "000" //underwear color
	var/undershirt = "Nude" //undershirt type
	var/socks = "Nude" //socks type
	var/jumpsuit_style = PREF_SUIT //suit/skirt
	var/hairstyle = "Bald" //Hair type
	var/hair_color = "000" //Hair color
	var/facial_hairstyle = "Shaved" //Face hair type
	var/facial_hair_color = "000" //Facial hair color
	var/skin_tone = "caucasian1" //Skin color
	var/eye_color = "000" //Eye color
	var/list/features = list("mcolor" = "FFF", "ethcolor" = "9c3030", "tail_lizard" = "Smooth", "tail_human" = "None", "snout" = "Round", "horns" = "None", "ears" = "None", "wings" = "None", "frills" = "None", "spines" = "None", "body_markings" = "None", "legs" = "Normal Legs", "moth_wings" = "Plain", "moth_antennae" = "Plain", "moth_markings" = "None")
	var/list/randomise = list(RANDOM_UNDERWEAR = TRUE, RANDOM_UNDERWEAR_COLOR = TRUE, RANDOM_UNDERSHIRT = TRUE, RANDOM_SOCKS = TRUE, RANDOM_BACKPACK = TRUE, RANDOM_JUMPSUIT_STYLE = TRUE, RANDOM_HAIRSTYLE = TRUE, RANDOM_HAIR_COLOR = TRUE, RANDOM_FACIAL_HAIRSTYLE = TRUE, RANDOM_FACIAL_HAIR_COLOR = TRUE, RANDOM_SKIN_TONE = TRUE, RANDOM_EYE_COLOR = TRUE)
	var/phobia = "spiders"

	var/list/custom_names = list()
	var/preferred_ai_core_display = "Blue"
	var/prefered_security_department = SEC_DEPT_NONE

	//Quirk list
	var/list/all_quirks = list()

	//Job preferences 2.0 - indexed by job title , no key or value implies never
	var/list/job_preferences = list()

		// Want randomjob if preferences already filled - Donkie
	var/joblessrole = BERANDOMJOB  //defaults to 1 for fewer assistants

	// 0 = character settings, 1 = game preferences
	var/current_tab = 0

	var/unlock_content = 0

	var/list/ignoring = list()

	var/clientfps = -1

	var/parallax

	///Do we show screentips, if so, how big?
	var/screentip_pref = TRUE
	///Color of screentips at top of screen
	var/screentip_color = "#ffd391"
	///Do we show item hover outlines?
	var/itemoutline_pref = TRUE

	var/ambientocclusion = TRUE
	///Should we automatically fit the viewport?
	var/auto_fit_viewport = FALSE
	///Should we be in the widescreen mode set by the config?
	var/widescreenpref = TRUE
	///What size should pixels be displayed as? 0 is strech to fit
	var/pixel_size = 0
	///What scaling method should we use? Distort means nearest neighbor
	var/scaling_method = SCALING_METHOD_DISTORT
	var/uplink_spawn_loc = UPLINK_PDA
	///The playtime_reward_cloak variable can be set to TRUE from the prefs menu only once the user has gained over 5K playtime hours. If true, it allows the user to get a cool looking roundstart cloak.
	var/playtime_reward_cloak = FALSE

	var/list/exp = list()
	var/list/menuoptions

	var/action_buttons_screen_locs = list()

	///This var stores the amount of points the owner will get for making it out alive.
	var/hardcore_survival_score = 0

	///Someone thought we were nice! We get a little heart in OOC until we join the server past the below time (we can keep it until the end of the round otherwise)
	var/hearted
	///If we have a hearted commendations, we honor it every time the player loads preferences until this time has been passed
	var/hearted_until
	/// Agendered spessmen can choose whether to have a male or female bodytype
	var/body_type
	/// If we have persistent scars enabled
	var/persistent_scars = TRUE
	///If we want to broadcast deadchat connect/disconnect messages
	var/broadcast_login_logout = TRUE
	///What outfit typepaths we've favorited in the SelectEquipment menu
	var/list/favorite_outfits = list()

	/// A preview of the current character
	var/atom/movable/screen/character_preview_view/character_preview_view

	/// Cached list of generated preferences (return value of [`/datum/preference/get_choices`]).
	var/list/generated_preference_values = list()

/datum/preferences/Destroy(force, ...)
	QDEL_NULL(character_preview_view)
	return ..()

/datum/preferences/New(client/C)
	parent = C

	for(var/custom_name_id in GLOB.preferences_custom_names)
		custom_names[custom_name_id] = get_default_name(custom_name_id)

	UI_style = GLOB.available_ui_styles[1]
	if(istype(C))
		if(!IsGuestKey(C.key))
			load_path(C.ckey)
			unlock_content = C.IsByondMember()
			if(unlock_content)
				max_save_slots = 8
	var/loaded_preferences_successfully = load_preferences()
	if(loaded_preferences_successfully)
		if(load_character())
			return
	//we couldn't load character data so just randomize the character appearance + name
	random_character() //let's create a random character then - rather than a fat, bald and naked man.
	key_bindings = deepCopyList(GLOB.hotkey_keybinding_list_by_key) // give them default keybinds and update their movement keys
	C?.set_macros()

	var/species_type = read_preference(/datum/preference/choiced/species)
	var/datum/species/species = new species_type
	real_name = species.random_name(gender,1)

	if(!loaded_preferences_successfully)
		save_preferences()
	save_character() //let's save this new random character so it doesn't keep generating new ones.
	menuoptions = list()
	return

/datum/preferences/proc/ShowChoices(mob/user)
	if(!user || !user.client)
		return
	CRASH("NYI: ShowChoices")

/datum/preferences/ui_interact(mob/user, datum/tgui/ui)
	// If you leave and come back, re-register the character preview
	if (!isnull(character_preview_view) && !(character_preview_view in user.client?.screen))
		user.client.register_map_obj(character_preview_view)

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PreferencesMenu")
		ui.open()

/datum/preferences/ui_state(mob/user)
	// TODO: This probably means a hacker is able to edit other people's preferences.
	// `ui_status` needs to properly filter this.
	return GLOB.always_state

/datum/preferences/ui_data(mob/user)
	var/list/data = list()

	if (isnull(character_preview_view))
		character_preview_view = create_character_preview_view(user)

	data["character_profiles"] = create_character_profiles()
	data["character_preferences"] = compile_character_preferences(user)
	data["character_preview_view"] = character_preview_view.assigned_map
	data["real_name"] = real_name

	return data

/datum/preferences/ui_static_data(mob/user)
	if (isnull(GLOB.preferences_species_data))
		// If we do this in GLOBAL_VAR_INIT, the species list is not created yet.
		GLOB.preferences_species_data = generate_preferences_species_data()

	return list(
		"generated_preference_values" = generated_preference_values,
		"species" = GLOB.preferences_species_data,
	)

/datum/preferences/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/preferences),
	)

/datum/preferences/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
		return

	var/mob/user = usr

	switch (action)
		if ("change_slot")
			// SAFETY: `load_character` performs sanitization the slot number
			if (!load_character(params["slot"]))
				random_character()
				real_name = random_unique_name(gender)
				// save_character()

			character_preview_view.update_body()
		if ("request_values")
			var/requested_preference_key = params["preference"]

			var/datum/preference/choiced/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if (!istype(requested_preference))
				return TRUE

			if (isnull(generated_preference_values[requested_preference_key]))
				generated_preference_values[requested_preference_key] = generate_preference_values(requested_preference)
				update_static_data(user, ui)
		if ("rotate")
			character_preview_view.dir = turn(character_preview_view.dir, -90)
		if ("set_preference")
			var/requested_preference_key = params["preference"]
			var/value = params["value"]

			var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if (isnull(requested_preference))
				return TRUE

			// SAFETY: `write_preference` performs validation checks
			write_preference(requested_preference, value)

			// Preferences could theoretically perform granular updates rather than
			// recreating the whole thing, but this would complicate the preference
			// API while adding the potential for drift.
			character_preview_view.update_body()

			return TRUE

	return TRUE

/datum/preferences/proc/create_character_preview_view(mob/user)
	character_preview_view = new(null, src)
	character_preview_view.update_body()
	user.client?.register_map_obj(character_preview_view)

	// Re-register if they reconnect
	RegisterSignal(user, COMSIG_MOB_CLIENT_LOGIN, .proc/register_character_preview)

	return character_preview_view

/datum/preferences/proc/register_character_preview(datum/source, client/client)
	SIGNAL_HANDLER

	client?.register_map_obj(character_preview_view)

/datum/preferences/proc/generate_preference_values(datum/preference/choiced/preference)
	var/list/values
	var/list/choices = preference.get_choices_serialized()

	if (preference.should_generate_icons)
		values = list()
		for (var/value in choices)
			values[value] = preference.get_spritesheet_key(value)
	else
		values = choices

	return values

/datum/preferences/proc/compile_character_preferences(mob/user)
	var/list/preferences = list()

	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]

		LAZYINITLIST(preferences[preference.category])

		var/value = read_preference(preference_type)
		var/data = preference.compile_ui_data(user, value)

		preferences[preference.category][preference.savefile_key] = data

	return preferences

/// A preview of a character for use in the preferences menu
/atom/movable/screen/character_preview_view
	name = "character_preview"
	del_on_map_removal = FALSE
	layer = GAME_PLANE
	plane = GAME_PLANE

	/// The body that is displayed
	var/mob/living/carbon/human/dummy/body

	/// The preferences this refers to
	var/datum/preferences/preferences

/atom/movable/screen/character_preview_view/Initialize(mapload, datum/preferences/preferences)
	. = ..()

	assigned_map = "character_preview_[REF(src)]"
	set_position(1, 1)

	src.preferences = preferences

/atom/movable/screen/character_preview_view/Destroy()
	. = ..()

	QDEL_NULL(body)
	preferences = null

/// Updates the currently displayed body
/atom/movable/screen/character_preview_view/proc/update_body()
	create_body()
	preferences.update_preview_icon(body)
	appearance = body.appearance

/atom/movable/screen/character_preview_view/proc/create_body()
	QDEL_NULL(body)

	body = new

	// Without this, it doesn't show up in the menu
	body.appearance_flags &= ~KEEP_TOGETHER

/datum/preferences/proc/create_character_profiles()
	var/list/profiles = list()

	var/savefile/savefile = new(path)
	for (var/index in 1 to max_save_slots)
		// MOTHBLOCKS TODO: This cd's to root, is this even better?
		savefile.cd = "/character[index]"

		var/name
		READ_FILE(savefile["real_name"], name)

		if (isnull(name))
			profiles += null
			continue

		// MOTHBLOCKS TODO: Cached profile headshots
		profiles += list(list(
			"name" = name,
		))

	return profiles

/datum/preferences/proc/SetJobPreferenceLevel(datum/job/job, level)
	if (!job)
		return FALSE

	if (level == JP_HIGH) // to high
		//Set all other high to medium
		for(var/j in job_preferences)
			if(job_preferences[j] == JP_HIGH)
				job_preferences[j] = JP_MEDIUM
				//technically break here

	job_preferences[job.title] = level
	return TRUE

/datum/preferences/proc/GetQuirkBalance()
	var/bal = 0
	for(var/V in all_quirks)
		var/datum/quirk/T = SSquirks.quirks[V]
		bal -= initial(T.value)
	return bal

/datum/preferences/proc/GetPositiveQuirkCount()
	. = 0
	for(var/q in all_quirks)
		if(SSquirks.quirk_points[q] > 0)
			.++

/datum/preferences/proc/validate_quirks()
	if(GetQuirkBalance() < 0)
		all_quirks = list()

/datum/preferences/proc/copy_to(mob/living/carbon/human/character, icon_updates = 1, roundstart_checks = TRUE, character_setup = FALSE, antagonist = FALSE, is_latejoiner = TRUE)

	hardcore_survival_score = 0 //Set to 0 to prevent you getting points from last another time.

	if((randomise[RANDOM_SPECIES] || randomise[RANDOM_HARDCORE]) && !character_setup)
		random_species()

	if((randomise[RANDOM_BODY] || (randomise[RANDOM_BODY_ANTAG] && antagonist) || randomise[RANDOM_HARDCORE]) && !character_setup)
		slot_randomized = TRUE
		random_character(gender, antagonist)

	if((randomise[RANDOM_NAME] || (randomise[RANDOM_NAME_ANTAG] && antagonist) || randomise[RANDOM_HARDCORE]) && !character_setup)
		slot_randomized = TRUE
		// MOTHBLOCKS TODO: Random name for antags
		// real_name = species.random_name(gender)

	if(randomise[RANDOM_HARDCORE] && parent.mob.mind && !character_setup)
		if(can_be_random_hardcore())
			hardcore_random_setup(character, antagonist, is_latejoiner)

	if(roundstart_checks)
		if(CONFIG_GET(flag/humans_need_surnames) && (read_preference(/datum/preference/choiced/species) == /datum/species/human))
			var/firstspace = findtext(real_name, " ")
			var/name_length = length(real_name)
			if(!firstspace) //we need a surname
				real_name += " [pick(GLOB.last_names)]"
			else if(firstspace == name_length)
				real_name += "[pick(GLOB.last_names)]"

	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]
		preference.apply(character, read_preference(preference_type))

	character.real_name = real_name
	character.name = character.real_name

	character.age = age
	if(gender == MALE || gender == FEMALE)
		character.body_type = gender
	else
		character.body_type = body_type

	character.eye_color = eye_color
	var/obj/item/organ/eyes/organ_eyes = character.getorgan(/obj/item/organ/eyes)
	if(organ_eyes)
		if(!initial(organ_eyes.eye_color))
			organ_eyes.eye_color = eye_color
		organ_eyes.old_eye_color = eye_color
	character.hair_color = hair_color
	character.facial_hair_color = facial_hair_color
	character.skin_tone = skin_tone
	character.hairstyle = hairstyle
	character.facial_hairstyle = facial_hairstyle
	character.underwear_color = underwear_color
	character.undershirt = undershirt
	character.socks = socks

	character.jumpsuit_style = jumpsuit_style

	character.dna.features = features.Copy()
	character.dna.real_name = character.real_name

	// MOTHBLOCKS TODO: What is all this for? If it doesn't include moth wings, then what is it?
	// Is it the same problem with cloning moths not giving wings? Oversight?

	// if(species.mutant_bodyparts["tail_lizard"])
	// 	character.dna.species.mutant_bodyparts["tail_lizard"] = species.mutant_bodyparts["tail_lizard"]
	// if(species.mutant_bodyparts["spines"])
	// 	character.dna.species.mutant_bodyparts["spines"] = species.mutant_bodyparts["spines"]

	if(icon_updates)
		character.update_body()
		character.update_hair()
		character.update_body_parts()

/datum/preferences/proc/can_be_random_hardcore()
	if(parent.mob.mind.assigned_role in GLOB.command_positions) //No command staff
		return FALSE
	for(var/A in parent.mob.mind.antag_datums)
		var/datum/antagonist/antag
		if(antag.get_team()) //No team antags
			return FALSE
	return TRUE

/datum/preferences/proc/get_default_name(name_id)
	switch(name_id)
		if("human")
			return random_unique_name()
		if("ai")
			return pick(GLOB.ai_names)
		if("cyborg")
			return DEFAULT_CYBORG_NAME
		if("clown")
			return pick(GLOB.clown_names)
		if("mime")
			return pick(GLOB.mime_names)
		if("religion")
			return pick(GLOB.religion_names)
		if("deity")
			return DEFAULT_DEITY
		if("bible")
			return DEFAULT_BIBLE
	return random_unique_name()

/datum/preferences/proc/ask_for_custom_name(mob/user,name_id)
	var/namedata = GLOB.preferences_custom_names[name_id]
	if(!namedata)
		return

	var/raw_name = input(user, "Choose your character's [namedata["qdesc"]]:","Character Preference") as text|null
	if(!raw_name)
		if(namedata["allow_null"])
			custom_names[name_id] = get_default_name(name_id)
		else
			return
	else
		var/sanitized_name = reject_bad_name(raw_name,namedata["allow_numbers"])
		if(!sanitized_name)
			to_chat(user, "<font color='red'>Invalid name. Your name should be at least 2 and at most [MAX_NAME_LEN] characters long. It may only contain the characters A-Z, a-z, [namedata["allow_numbers"] ? "0-9, " : ""]-, ' and . It must not contain any words restricted by IC chat and name filters.</font>")
			return
		else
			custom_names[name_id] = sanitized_name

/proc/generate_preferences_species_data()
	var/list/food_flags = FOOD_FLAGS
	var/list/species_data = list()

	for (var/species_id in GLOB.roundstart_races)
		var/datum/species/species = GLOB.species_list[species_id]

		var/list/diet = list()

		if (!(TRAIT_NOHUNGER in initial(species.inherent_traits)))
			diet = list(
				"liked_food" = bitfield2list(initial(species.liked_food), food_flags),
				"disliked_food" = bitfield2list(initial(species.disliked_food), food_flags),
				"toxic_food" = bitfield2list(initial(species.toxic_food), food_flags),
			)

		species_data[species_id] = list(
			"name" = initial(species.name),

			"use_skintones" = initial(species.use_skintones),
			"sexes" = initial(species.sexes),
		) + diet

	return species_data
