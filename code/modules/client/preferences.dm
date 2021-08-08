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
	var/gender = MALE //gender of character (well duh)
	var/underwear_color = "000" //underwear color
	var/undershirt = "Nude" //undershirt type
	var/socks = "Nude" //socks type
	var/hairstyle = "Bald" //Hair type
	var/facial_hairstyle = "Shaved" //Face hair type
	var/skin_tone = "caucasian1" //Skin color
	var/list/features = list("mcolor" = "FFF", "ethcolor" = "9c3030", "tail_lizard" = "Smooth", "tail_human" = "None", "snout" = "Round", "horns" = "None", "ears" = "None", "wings" = "None", "frills" = "None", "spines" = "None", "body_markings" = "None", "legs" = "Normal Legs", "moth_wings" = "Plain", "moth_antennae" = "Plain", "moth_markings" = "None")
	var/list/randomise = list(
		RANDOM_UNDERWEAR = TRUE,
		RANDOM_UNDERWEAR_COLOR = TRUE,
		RANDOM_UNDERSHIRT = TRUE,
		RANDOM_SOCKS = TRUE,
		RANDOM_BACKPACK = TRUE,
		RANDOM_JUMPSUIT_STYLE = TRUE,
		RANDOM_HAIRSTYLE = TRUE,
		RANDOM_HAIR_COLOR = TRUE,
		RANDOM_FACIAL_HAIRSTYLE = TRUE,
		RANDOM_FACIAL_HAIR_COLOR = TRUE,
		RANDOM_SKIN_TONE = TRUE,
		RANDOM_EYE_COLOR = TRUE,
		)
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
	///The playtime_reward_cloak variable can be set to TRUE from the prefs menu only once the user has gained over 5K playtime hours. If true, it allows the user to get a cool looking roundstart cloak.
	var/playtime_reward_cloak = FALSE

	var/list/exp = list()
	var/list/menuoptions

	var/action_buttons_screen_locs = list()

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

	/// A list of instantiated middleware
	var/list/datum/preference_middleware/middleware = list()

/datum/preferences/Destroy(force, ...)
	QDEL_NULL(character_preview_view)
	return ..()

/datum/preferences/New(client/C)
	parent = C

	for (var/middleware_type in subtypesof(/datum/preference_middleware))
		middleware += new middleware_type(src)

	for(var/custom_name_id in GLOB.preferences_custom_names)
		custom_names[custom_name_id] = get_default_name(custom_name_id)

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
	randomise_appearance_prefs() //let's create a random character then - rather than a fat, bald and naked man.
	key_bindings = deepCopyList(GLOB.hotkey_keybinding_list_by_key) // give them default keybinds and update their movement keys
	C?.set_macros()

	if(!loaded_preferences_successfully)
		save_preferences()
	save_character() //let's save this new random character so it doesn't keep generating new ones.
	menuoptions = list()

/datum/preferences/proc/ShowChoices(mob/user)
	if(!user || !user.client)
		return
	// MOTHBLOCKS TODO: ShowChoices
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
	// MOTHBLOCKS TODO: This probably means a hacker is able to edit other people's preferences.
	// `ui_status` needs to properly filter this.
	return GLOB.always_state

/datum/preferences/ui_data(mob/user)
	var/list/data = list()

	if (isnull(character_preview_view))
		character_preview_view = create_character_preview_view(user)
	else if (character_preview_view.client != parent)
		// The client re-logged, and doing this when they log back in doesn't seem to properly
		// carry emissives.
		character_preview_view.register_to_client(parent)

	// MOTHBLOCKS TODO: Try to diff these as much as possible, and only send what is needed.
	// Some of these, like job preferences, can be pretty beefy.
	data["character_profiles"] = create_character_profiles()
	data["character_preferences"] = compile_character_preferences(user)
	data["character_preview_view"] = character_preview_view.assigned_map

	// MOTHBLOCKS TODO: Job bans/yet to be unlocked jobs
	data["job_preferences"] = job_preferences

	data["active_name"] = read_preference(/datum/preference/name/real_name)

	data["name_to_use"] = "real_name" // MOTHBLOCKS TODO: Change to AI name, clown name, etc depending on circumstances

	for (var/datum/preference_middleware/preference_middleware as anything in middleware)
		data += preference_middleware.get_ui_data(user)

	return data

/datum/preferences/ui_static_data(mob/user)
	if (isnull(GLOB.preferences_species_data))
		// If we do this in GLOBAL_VAR_INIT, the species list is not created yet.
		GLOB.preferences_species_data = generate_preferences_species_data()

	var/list/data = list()
	data["generated_preference_values"] = generated_preference_values
	data["overflow_role"] = SSjob.overflow_role

	// MOTHBLOCKS TODO: Move this over to a json asset
	data["species"] = GLOB.preferences_species_data

	var/list/selected_antags = list()

	for (var/antag in be_special)
		selected_antags += serialize_antag_name(antag)

	// MOTHBLOCKS TODO: Only send when needed, just like generated_preference_values
	// MOTHBLOCKS TODO: Send banned/not old enough antags
	data["selected_antags"] = selected_antags

	for (var/datum/preference_middleware/preference_middleware as anything in middleware)
		data += preference_middleware.get_ui_static_data(user)

	return data

/datum/preferences/ui_assets(mob/user)
	var/list/assets = list(
		get_asset_datum(/datum/asset/spritesheet/antagonists),
		get_asset_datum(/datum/asset/spritesheet/preferences),
	)

	for (var/datum/preference_middleware/preference_middleware as anything in middleware)
		assets += preference_middleware.get_ui_assets()

	return assets

/datum/preferences/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if (.)
		return

	var/mob/user = usr

	switch (action)
		if ("change_slot")
			// SAFETY: `load_character` performs sanitization the slot number
			if (!load_character(params["slot"]))
				apply_character_randomization_prefs()
				save_character()

			character_preview_view.update_body()

			return TRUE
		if ("request_values")
			var/requested_preference_key = params["preference"]

			var/datum/preference/choiced/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if (!istype(requested_preference))
				return FALSE

			if (isnull(generated_preference_values[requested_preference_key]))
				generated_preference_values[requested_preference_key] = generate_preference_values(requested_preference)
				update_static_data(user, ui)

			return TRUE
		if ("rotate")
			character_preview_view.dir = turn(character_preview_view.dir, -90)

			return TRUE
		if ("set_preference")
			var/requested_preference_key = params["preference"]
			var/value = params["value"]

			var/datum/preference/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if (isnull(requested_preference))
				return FALSE

			// SAFETY: `write_preference` performs validation checks
			write_preference(requested_preference, value)

			// Preferences could theoretically perform granular updates rather than
			// recreating the whole thing, but this would complicate the preference
			// API while adding the potential for drift.
			character_preview_view.update_body()

			if (requested_preference.savefile_identifier == PREFERENCE_PLAYER)
				requested_preference.apply_to_client(parent, value)

			return TRUE
		if ("set_color_preference")
			var/requested_preference_key = params["preference"]

			var/datum/preference/color/requested_preference = GLOB.preference_entries_by_key[requested_preference_key]
			if (!istype(requested_preference))
				return FALSE

			// Yielding
			var/new_color = input(
				usr,
				"Select new color",
				null,
				read_preference(requested_preference.type) || COLOR_WHITE,
			) as color | null

			if (new_color)
				write_preference(requested_preference, new_color)
				character_preview_view.update_body()

				return TRUE
			else
				return FALSE
		if ("set_job_preference")
			var/job_title = params["job"]
			var/level = params["level"]

			if (level != null && level != JP_LOW && level != JP_MEDIUM && level != JP_HIGH)
				return FALSE

			var/datum/job/job = SSjob.GetJob(job_title)

			if (job.faction != FACTION_STATION)
				return FALSE

			return set_job_preference_level(job, level)
		if ("set_antags")
			var/sent_antags = params["antags"]
			var/toggled = params["toggled"]

			var/antags = list()

			var/serialized_antags = get_serialized_antags()

			for (var/sent_antag in sent_antags)
				var/special_role = serialized_antags[sent_antag]
				if (!special_role)
					continue

				antags += special_role

			// MOTHBLOCKS TODO: Check antag ban(?) and age requirement
			// (?) because antag bans are handled in all ruleset code
			if (toggled)
				be_special |= antags
			else
				be_special -= antags

			return TRUE

	for (var/datum/preference_middleware/preference_middleware as anything in middleware)
		var/delegation = preference_middleware.action_delegations[action]
		if (!isnull(delegation))
			return call(preference_middleware, delegation)(params, usr)

	return FALSE

/datum/preferences/ui_close(mob/user)
	save_preferences()
	QDEL_NULL(character_preview_view)

/datum/preferences/proc/create_character_preview_view(mob/user)
	character_preview_view = new(null, src, user.client)
	character_preview_view.update_body()
	character_preview_view.register_to_client(user.client)

	return character_preview_view

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

/datum/preferences/proc/get_serialized_antags()
	var/list/serialized_antags

	if (isnull(serialized_antags))
		serialized_antags = list()

		for (var/special_role in GLOB.special_roles)
			serialized_antags[serialize_antag_name(special_role)] = special_role

	return serialized_antags

/datum/preferences/proc/compile_character_preferences(mob/user)
	var/list/preferences = list()

	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]

		LAZYINITLIST(preferences[preference.category])

		var/value = read_preference(preference_type)
		var/data = preference.compile_ui_data(user, value)

		preferences[preference.category][preference.savefile_key] = data

	return preferences

// This is necessary because you can open the set preferences menu before
// the atoms SS is done loading.
INITIALIZE_IMMEDIATE(/atom/movable/screen/character_preview_view)

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

	var/list/plane_masters = list()

	/// The client that is watching this view
	var/client/client

/atom/movable/screen/character_preview_view/Initialize(mapload, datum/preferences/preferences, client/client)
	. = ..()

	assigned_map = "character_preview_[REF(src)]"
	set_position(1, 1)

	src.preferences = preferences

/atom/movable/screen/character_preview_view/Destroy()
	. = ..()

	QDEL_NULL(body)

	for (var/plane_master in plane_masters)
		client?.screen -= plane_master
		qdel(plane_master)

	client = null
	plane_masters = null
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

/// Registers the relevant map objects to a client
/atom/movable/screen/character_preview_view/proc/register_to_client(client/client)
	QDEL_LIST(plane_masters)

	src.client = client

	if (!client)
		return

	for (var/plane_master_type in subtypesof(/atom/movable/screen/plane_master))
		var/atom/movable/screen/plane_master/plane_master = new plane_master_type
		plane_master.screen_loc = "[assigned_map]:CENTER"
		client?.screen |= plane_master

		plane_masters += plane_master

	client?.register_map_obj(src)

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

/datum/preferences/proc/set_job_preference_level(datum/job/job, level)
	if (!job)
		return FALSE

	if (level == JP_HIGH) // to high
		//Set all other high to medium
		for(var/j in job_preferences)
			if(job_preferences[j] == JP_HIGH)
				job_preferences[j] = JP_MEDIUM
				//technically break here

	if (isnull(job_preferences[job.title]))
		job_preferences[job.title] = level
	else
		job_preferences -= job.title

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

/// Sanitization checks to be performed before using these preferences.
/datum/preferences/proc/sanitize_chosen_prefs()
	// MOTHBLOCKS TODO: sanitize_chosen_prefs
	// Most likely remove this in favor of prefs themselves sanitizing

	// if(!(pref_species.id in GLOB.roundstart_races) && !(pref_species.id in (CONFIG_GET(keyed_list/roundstart_no_hard_check))))
	// 	pref_species = new /datum/species/human
	// 	save_character()

	// if(CONFIG_GET(flag/humans_need_surnames) && (pref_species.id == SPECIES_HUMAN))
	// 	var/firstspace = findtext(real_name, " ")
	// 	var/name_length = length(real_name)
	// 	if(!firstspace) //we need a surname
	// 		real_name += " [pick(GLOB.last_names)]"
	// 	else if(firstspace == name_length)
	// 		real_name += "[pick(GLOB.last_names)]"

/// Sanitizes the preferences, applies the randomization prefs, and then applies the preference to the human mob.
/datum/preferences/proc/safe_transfer_prefs_to(mob/living/carbon/human/character, icon_updates = TRUE, is_antag = FALSE)
	apply_character_randomization_prefs(is_antag)
	sanitize_chosen_prefs()
	apply_prefs_to(character, icon_updates)

/// Applies the given preferences to a human mob.
/datum/preferences/proc/apply_prefs_to(mob/living/carbon/human/character, icon_updates = TRUE)
	if(gender == MALE || gender == FEMALE)
		character.body_type = gender
	else
		character.body_type = body_type

	character.skin_tone = skin_tone
	character.hairstyle = hairstyle
	character.facial_hairstyle = facial_hairstyle
	character.underwear_color = underwear_color
	character.socks = socks

	// MOTHBLOCKS TODO: Put this on name/real_name/apply
	// if(roundstart_checks)
	// 	if(CONFIG_GET(flag/humans_need_surnames) && (read_preference(/datum/preference/choiced/species) == /datum/species/human))
	// 		var/firstspace = findtext(real_name, " ")
	// 		var/name_length = length(real_name)
	// 		if(!firstspace) //we need a surname
	// 			real_name += " [pick(GLOB.last_names)]"
	// 		else if(firstspace == name_length)
	// 			real_name += "[pick(GLOB.last_names)]"

	for (var/preference_type in GLOB.preference_entries)
		var/datum/preference/preference = GLOB.preference_entries[preference_type]
		if (preference.savefile_identifier != PREFERENCE_CHARACTER)
			continue

		preference.apply_to_human(character, read_preference(preference_type))

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


/// Returns whether the parent mob should have the random hardcore settings enabled. Assumes it has a mind.
/datum/preferences/proc/should_be_random_hardcore(datum/job/job, datum/mind/mind)
	if(!randomise[RANDOM_HARDCORE])
		return FALSE
	if(job.departments & DEPARTMENT_COMMAND) //No command staff
		return FALSE
	for(var/datum/antagonist/antag as anything in mind.antag_datums)
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

	for (var/species_id in get_selectable_species())
		var/species_type = GLOB.species_list[species_id]
		var/datum/species/species = new species_type

		var/list/diet = list()

		if (!(TRAIT_NOHUNGER in species.inherent_traits))
			diet = list(
				"liked_food" = bitfield2list(species.liked_food, food_flags),
				"disliked_food" = bitfield2list(species.disliked_food, food_flags),
				"toxic_food" = bitfield2list(species.toxic_food, food_flags),
			)

		// MOTHBLOCKS TODO: Move this to ts/json files and unit test consistency.
		species_data[species_id] = list(
			"name" = species.name,

			"use_skintones" = species.use_skintones,
			"sexes" = species.sexes,

			"features" = species.get_features(),
		) + diet

	return species_data

/// Serializes an antag name to be used for preferences UI
/proc/serialize_antag_name(antag_name)
	// These are sent through CSS, so they need to be safe to use as class names.
	return lowertext(sanitize_css_class_name(antag_name))
