#define PATH_PEST_KILLER "path_pest_killer"
#define PATH_PLANT_HEALER "path_plant_healer"
#define PATH_PLANT_MUTATOR "path_plant_mutator"
#define REQUIRED_TREE_GROWTH 400
#define UPPER_BOUND_VOLUME 50
#define LOWER_BOUND_VOLUME 10
#define BB_TURTLE_TREE_ABILITY "turtle_tree_ability"

/mob/living/basic/turtle
	name = "turtle"
	desc = "Dog."
	icon_state = "turtle"
	icon_living = "turtle"
	icon_dead = "turtle_dead"
	base_icon_state = "turtle"
	icon = 'icons/mob/simple/pets.dmi'
	butcher_results = list(/obj/item/food/meat/slab = 3, /obj/item/food/pickle = 1, /obj/item/stack/sheet/mineral/wood = 10)
	mob_biotypes = MOB_ORGANIC
	mobility_flags = MOBILITY_FLAGS_REST_CAPABLE_DEFAULT
	health = 100
	maxHealth = 100
	speed = 5
	verb_say = "snaps"
	verb_ask = "snaps curiously"
	verb_exclaim = "snaps loudly"
	verb_yell = "snaps loudly"
	faction = list(FACTION_NEUTRAL)
//	ai_controller = /datum/ai_controller/basic_controller/turtle
	///our displayed tree
	var/mutable_appearance/grown_tree
	///growth progress of our tree
	var/list/path_growth_progress = list(
		PATH_PLANT_HEALER = 0,
		PATH_PLANT_MUTATOR = 0,
		PATH_PEST_KILLER = 0,
	)
	///what nutrients leads to each evolution path
	var/static/list/path_requirements = list(
		//plant healers
		/datum/reagent/plantnutriment/eznutriment = PATH_PLANT_HEALER,
		/datum/reagent/plantnutriment/robustharvestnutriment = PATH_PLANT_HEALER,
		/datum/reagent/plantnutriment/endurogrow = PATH_PLANT_HEALER,
		//plant mutators
		/datum/reagent/plantnutriment/left4zednutriment = PATH_PLANT_MUTATOR,
		/datum/reagent/uranium = PATH_PLANT_MUTATOR,
		//pest killers
		/datum/reagent/toxin = PATH_PEST_KILLER,
	)
	///if we are fully grown, what is our path
	var/developed_path

/mob/living/basic/turtle/Initialize(mapload)
	. = ..()

	desc = pick(
		"Likey Dog...",
		"Praise the Dog!",
		"Dog ahead.",
		"Could this be a Dog?",
	)

	create_reagents(150, REAGENT_HOLDER_ALIVE)
	START_PROCESSING(SSprocessing, src)

/mob/living/basic/turtle/process(seconds_per_tick)
	if(isnull(reagents) || !length(reagents.reagent_list)) //if we have no reagents, default to being a plant healer
		set_plant_growth(PATH_PLANT_HEALER, 0.5)
		return

	for(var/datum/reagent/existing_reagent as anything in reagents.reagent_list)
		var/evolution_path = path_requirements[existing_reagent.type]
		switch(existing_reagent.volume)
			if(UPPER_BOUND_VOLUME to INFINITY)
				set_plant_growth(evolution_path, 3)
			if(LOWER_BOUND_VOLUME to UPPER_BOUND_VOLUME)
				set_plant_growth(evolution_path, 2)
			if(1 to LOWER_BOUND_VOLUME)
				set_plant_growth(evolution_path, 1)

		reagents.remove_reagent(existing_reagent.type, 0.5)

/mob/living/basic/turtle/proc/set_plant_growth(evolution_path, amount)
	path_growth_progress[evolution_path] += amount
	if(path_growth_progress[evolution_path] >= REQUIRED_TREE_GROWTH)
		evolve_turtle()

/mob/living/basic/turtle/examine(mob/user)
	. = ..()

	if(stat == DEAD)
		. += span_notice("its tree seems to be all withered...")
		return

	var/destined_path
	var/current_max_growth = 0

	for(var/evolution_path in path_growth_progress)
		if(path_growth_progress[evolution_path] > current_max_growth)
			destined_path = evolution_path
			current_max_growth = path_growth_progress[evolution_path]

	var/text_to_display = "its tree seems to be exuding "
	switch(destined_path)
		if(PATH_PEST_KILLER)
			text_to_display += "pest killing"
		if(PATH_PLANT_HEALER)
			text_to_display += "plant healing"
		if(PATH_PLANT_MUTATOR)
			text_to_display += "plant mutating"

	text_to_display += " properties... which [current_max_growth >= REQUIRED_TREE_GROWTH ? "seems to be fully grown" : "is yet to develop"]."
	. += span_notice(text_to_display)


/mob/living/basic/turtle/proc/evolve_turtle(evolution_path)
	var/static/list/evolution_gains = list(
		PATH_PLANT_HEALER = list(
			"tree_appearance" = "healer_tree",
			"tree_ability" = /datum/action/cooldown/mob_cooldown/turtle_tree/healer,
		),
		PATH_PEST_KILLER = list(
			"tree_appearance" = "killer_tree",
			"tree_ability" = /datum/action/cooldown/mob_cooldown/turtle_tree/killer,
		),
		PATH_PLANT_MUTATOR = list(
			"tree_appearance" = "mutator_tree",
			"tree_ability" = /datum/action/cooldown/mob_cooldown/turtle_tree/mutator,
		),
	)

	var/tree_icon_state = evolution_gains[evolution_path]["tree_appearance"]
	grown_tree = mutable_appearance(icon = 'icons/mob/simple/turtle_trees.dmi', icon_state = tree_icon_state)

	var/new_ability_path = evolution_gains[evolution_path]["tree_ability"]
	developed_path = evolution_path
	var/datum/action/cooldown/tree_ability = new new_ability_path(src)
	tree_ability?.Grant(src)
	ai_controller?.set_blackboard_key(BB_TURTLE_TREE_ABILITY, tree_ability)
	STOP_PROCESSING(SSprocessing, src)
	update_appearance()

/mob/living/basic/turtle/update_overlays()
	. = ..()
	if(stat == DEAD)
		var/mutable_appearance/dead_overlay = mutable_appearance(icon = 'icons/mob/simple/pets.dmi', icon_state = developed_path ? "dead_tree" : "growing_tree")
		dead_overlay.pixel_y = -2
		. += dead_overlay
		return
	var/pixel_offset = resting ?  -2 : 2
	var/mutable_appearance/living_tree = grown_tree ? grown_tree : mutable_appearance(icon = icon, icon_state = "growing_tree")
	living_tree.pixel_y = pixel_offset
	. += living_tree

/mob/living/basic/turtle/toggle_resting()
	. = ..()
	if(stat == DEAD)
		return
	if(resting)
		icon_state = "[base_icon_state]_rest"
	else
		icon_state = "[base_icon_state]"
	regenerate_icons()

/mob/living/basic/turtle/attackby(obj/item/reagent_containers/container, mob/living/user, params)
	. = ..()

	if(stat == DEAD)
		balloon_alert(user, "its dead!")
		return

	if(isnull(container.reagents))
		balloon_alert(user, "empty!")
		return

	var/should_transfer = FALSE
	for(var/reagent as anything in path_requirements)
		if(container.reagents.has_reagent(reagent))
			should_transfer = TRUE
			break

	if(!should_transfer)
		balloon_alert(user, "refuses to drink!")
		return

	container.reagents.trans_to(reagents, 5)
	balloon_alert(user, "drinks happily")


