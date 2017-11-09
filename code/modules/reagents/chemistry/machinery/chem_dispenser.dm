/obj/machinery/chem_dispenser
	name = "chem dispenser"
	desc = "Creates and dispenses chemicals."
	density = TRUE
	anchored = TRUE
	icon = 'icons/obj/chemical.dmi'
	icon_state = "dispenser"
	use_power = IDLE_POWER_USE
	idle_power_usage = 40
	interact_offline = 1
	resistance_flags = FIRE_PROOF | ACID_PROOF
	req_access = (ACCESS_CHEMISTRY)
	var/amount = 30
	var/recharge_delay = 5
	var/mutable_appearance/beaker_overlay
	var/obj/item/reagent_containers/beaker = null
	var/list/dispensable_reagents = list(
		"hydrogen",
		"lithium",
		"carbon",
		"nitrogen",
		"oxygen",
		"fluorine",
		"sodium",
		"aluminium",
		"silicon",
		"phosphorus",
		"sulfur",
		"chlorine",
		"potassium",
		"iron",
		"copper",
		"mercury",
		"radium",
		"water",
		"ethanol",
		"sugar",
		"sacid",
		"welding_fuel",
		"silver",
		"iodine",
		"bromine",
		"stable_plasma"
	)
	var/list/emagged_reagents = list(
		"space_drugs",
		"morphine",
		"carpotoxin",
		"mine_salve",
		"toxin"
	)
	var/list/saved_recipes = list(
		list("recipe_name" = "15 Mutagen", "contents" = "chlorine=5;phosphorus=5;radium=5"),
	)

/obj/machinery/chem_dispenser/Initialize()
	. = ..()
	dispensable_reagents = sortList(dispensable_reagents)


/obj/machinery/chem_dispenser/proc/recharge()
	if(stat & (BROKEN|NOPOWER))
		return

/obj/machinery/chem_dispenser/emag_act(mob/user)
	if(emagged)
		to_chat(user, "<span class='warning'>[src] has no functional safeties to emag.</span>")
		return
	to_chat(user, "<span class='notice'>You short out [src]'s safeties.</span>")
	dispensable_reagents |= emagged_reagents//add the emagged reagents to the dispensable ones
	emagged = TRUE

/obj/machinery/chem_dispenser/ex_act(severity, target)
	if(severity < 3)
		..()

/obj/machinery/chem_dispenser/contents_explosion(severity, target)
	..()
	if(beaker)
		beaker.ex_act(severity, target)

/obj/machinery/chem_dispenser/handle_atom_del(atom/A)
	..()
	if(A == beaker)
		beaker = null
		cut_overlays()

/obj/machinery/chem_dispenser/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
											datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "chem_dispenser", name, 550, 550, master_ui, state)
		if(user.hallucinating())
			ui.set_autoupdate(FALSE) //to not ruin the immersion by constantly changing the fake chemicals
		ui.open()

/obj/machinery/chem_dispenser/ui_data(mob/user)
	var/data = list()
	data["amount"] = amount
	data["isBeakerLoaded"] = beaker ? 1 : 0

	var/beakerContents[0]
	var/beakerCurrentVolume = 0
	if(beaker && beaker.reagents && beaker.reagents.reagent_list.len)
		for(var/datum/reagent/R in beaker.reagents.reagent_list)
			beakerContents.Add(list(list("name" = R.name, "volume" = R.volume))) // list in a list because Byond merges the first list...
			beakerCurrentVolume += R.volume
	data["beakerContents"] = beakerContents

	if (beaker)
		data["beakerCurrentVolume"] = beakerCurrentVolume
		data["beakerMaxVolume"] = beaker.volume
		data["beakerTransferAmounts"] = beaker.possible_transfer_amounts
	else
		data["beakerCurrentVolume"] = null
		data["beakerMaxVolume"] = null
		data["beakerTransferAmounts"] = null

	var/chemicals[0]
	var/recipes[0]
	var/is_hallucinating = FALSE
	if(user.hallucinating())
		is_hallucinating = TRUE
	for(var/re in dispensable_reagents)
		var/datum/reagent/temp = GLOB.chemical_reagents_list[re]
		if(temp)
			var/chemname = temp.name
			if(is_hallucinating && prob(5))
				chemname = "[pick_list_replacements("hallucination.json", "chemicals")]"
			chemicals.Add(list(list("title" = chemname, "id" = temp.id)))
	for(var/recipe in saved_recipes)
		recipes.Add(list(recipe))
	data["chemicals"] = chemicals
	data["recipes"] = recipes
	return data

/obj/machinery/chem_dispenser/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("amount")
			var/target = text2num(params["target"])
			if(target in beaker.possible_transfer_amounts)
				amount = target
				. = TRUE
		if("dispense")
			var/reagent = params["reagent"]
			if(beaker && dispensable_reagents.Find(reagent))
				var/datum/reagents/R = beaker.reagents
				R.add_reagent(reagent, amount)
				. = TRUE
		if("remove")
			var/amount = text2num(params["amount"])
			if(beaker && amount in beaker.possible_transfer_amounts)
				beaker.reagents.remove_all(amount)
				. = TRUE
		if("dispense_recipe")
			var/recipe_to_use = params["recipe"]
			var/list/chemicals_to_dispense = process_recipe_list(recipe_to_use)
			for(var/r_id in chemicals_to_dispense) // i suppose you could edit the list locally before passing it
				if(beaker && dispensable_reagents.Find(r_id)) // but since we verify we have the reagent, it'll be fine
					var/amt = chemicals_to_dispense[r_id]
					beaker.reagents.add_reagent(r_id, amt)
		if("add_recipe")
			var/name = stripped_input(usr,"Name","What do you want to name this recipe?", "15 Space Lube", MAX_NAME_LEN)
			var/recipe = stripped_input(usr,"Recipe","Insert recipe with chem IDs", "oxygen=5;silicon=5;water=5")
			if(name && recipe)
				var/list/first_process = splittext(recipe, ";")
				for(var/reagents in first_process)
					var/list/fuck = splittext(reagents, "=")
					if(dispensable_reagents.Find(fuck[1]))
						continue
					else
						var/temp = fuck[1]
						to_chat(usr, "[src] can't process [temp]!")
						return
				saved_recipes += list(list("recipe_name" = name, "contents" = recipe))
		if("eject")
			if(beaker)
				beaker.forceMove(loc)
				beaker = null
				cut_overlays()
				. = TRUE

/obj/machinery/chem_dispenser/proc/process_recipe_list(var/fucking_hell)
	var/list/final_list = list()
	var/list/first_process = splittext(fucking_hell, ";")
	for(var/reagents in first_process)
		var/list/fuck = splittext(reagents, "=")
		final_list += list(fuck[1] = text2num(fuck[2]))
	return final_list


/obj/machinery/chem_dispenser/attackby(obj/item/I, mob/user, params)
	if(default_unfasten_wrench(user, I))
		return

	if(istype(I, /obj/item/reagent_containers) && (I.container_type & OPENCONTAINER_1))
		var/obj/item/reagent_containers/B = I
		. = 1 //no afterattack
		if(beaker)
			to_chat(user, "<span class='warning'>A container is already loaded into [src]!</span>")
			return

		if(!user.transferItemToLoc(B, src))
			return

		beaker = B
		to_chat(user, "<span class='notice'>You add [B] to [src].</span>")

		beaker_overlay = beaker_overlay ||  mutable_appearance(icon, "disp_beaker")
		beaker_overlay.pixel_x = rand(-10, 5)//randomize beaker overlay position.
		add_overlay(beaker_overlay)
	else if(user.a_intent != INTENT_HARM && !istype(I, /obj/item/card/emag))
		to_chat(user, "<span class='warning'>You can't load [I] into [src]!</span>")
		return ..()
	else
		return ..()

/obj/machinery/chem_dispenser/emp_act(severity)
	var/list/datum/reagents/R = list()
	var/total = rand(7,15)
	var/datum/reagents/Q = new(total*10)
	if(beaker && beaker.reagents)
		R += beaker.reagents
	for(var/i in 1 to total)
		Q.add_reagent(pick(dispensable_reagents), 10)
	R += Q
	chem_splash(get_turf(src), 3, R)
	if(beaker && beaker.reagents)
		beaker.reagents.remove_all()
	visible_message("<span class='danger'>[src] malfunctions, spraying chemicals everywhere!</span>")
	..()

/obj/machinery/chem_dispenser/constructable
	name = "portable chem dispenser"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "minidispenser"
	amount = 5
	dispensable_reagents = list()
	circuit = /obj/item/circuitboard/machine/chem_dispenser
	var/static/list/dispensable_reagent_tiers = list(
		list(
			"hydrogen",
			"oxygen",
			"silicon",
			"phosphorus",
			"sulfur",
			"carbon",
			"nitrogen",
			"water"
		),
		list(
			"lithium",
			"sugar",
			"sacid",
			"copper",
			"mercury",
			"sodium",
			"iodine",
			"bromine"
		),
		list(
			"ethanol",
			"chlorine",
			"potassium",
			"aluminium",
			"radium",
			"fluorine",
			"iron",
			"welding_fuel",
			"silver",
			"stable_plasma"
		),
		list(
			"oil",
			"ash",
			"acetone",
			"saltpetre",
			"ammonia",
			"diethylamine"
		)
	)

/obj/machinery/chem_dispenser/constructable/RefreshParts()
	var/time = 0
	var/i
	for(var/obj/item/stock_parts/matter_bin/M in component_parts)
		time += M.rating
	for(var/obj/item/stock_parts/capacitor/C in component_parts)
		time += C.rating
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		for(i=1, i<=M.rating, i++)
			dispensable_reagents |= dispensable_reagent_tiers[i]
	dispensable_reagents = sortList(dispensable_reagents)

/obj/machinery/chem_dispenser/constructable/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, "minidispenser-o", "minidispenser", I))
		return

	if(exchange_parts(user, I))
		return

	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/chem_dispenser/constructable/on_deconstruction()
	if(beaker)
		beaker.loc = loc
		beaker = null

/obj/machinery/chem_dispenser/drinks
	name = "soda dispenser"
	desc = "Contains a large reservoir of soft drinks."
	anchored = TRUE
	icon = 'icons/obj/chemical.dmi'
	icon_state = "soda_dispenser"
	amount = 10
	dispensable_reagents = list(
		"water",
		"ice",
		"coffee",
		"cream",
		"tea",
		"icetea",
		"cola",
		"spacemountainwind",
		"dr_gibb",
		"space_up",
		"tonic",
		"sodawater",
		"lemon_lime",
		"pwr_game",
		"shamblers",
		"sugar",
		"orangejuice",
		"limejuice",
		"tomatojuice",
		"lemonjuice"
	)
	emagged_reagents = list(
		"thirteenloko",
		"whiskeycola",
		"mindbreaker",
		"tirizene"
	)



/obj/machinery/chem_dispenser/drinks/beer
	name = "booze dispenser"
	desc = "Contains a large reservoir of the good stuff."
	anchored = TRUE
	icon = 'icons/obj/chemical.dmi'
	icon_state = "booze_dispenser"
	dispensable_reagents = list(
		"beer",
		"kahlua",
		"whiskey",
		"wine",
		"vodka",
		"gin",
		"rum",
		"tequila",
		"vermouth",
		"cognac",
		"ale",
		"absinthe",
		"hcider"
	)
	emagged_reagents = list(
		"ethanol",
		"iron",
		"minttoxin",
		"atomicbomb"
	)


/obj/machinery/chem_dispenser/mutagen
	name = "mutagen dispenser"
	desc = "Creates and dispenses mutagen."
	dispensable_reagents = list("mutagen")
	emagged_reagents = list("plasma")


/obj/machinery/chem_dispenser/mutagensaltpeter
	name = "botanical chemical dispenser"
	desc = "Creates and dispenses chemicals useful for botany."
	dispensable_reagents = list(
		"mutagen",
		"saltpetre",
		"eznutriment",
		"left4zednutriment",
		"robustharvestnutriment",
		"water",
		"plantbgone",
		"weedkiller",
		"pestkiller",
		"cryoxadone",
		"ammonia",
		"ash",
		"diethylamine")
