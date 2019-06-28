/*
Warping extracts:
	Have unique effects that apply to the tile they are placed on.
*/
/obj/item/slimecross/warping
	name = "warping extract"
	desc = "It seems to be pulsing with untold spatial energies."
	effect = "warping"
	icon_state = "warping"
	var/rune_path = /obj/effect/slimerune
	var/placetime = 20 //2 seconds

/obj/item/slimecross/warping/afterattack(turf/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(!istype(target))
		return
	if(do_after(user, placetime, target))
		var/obj/effect/slimerune/rune = new rune_path(target)
		to_chat(user, "<span class='notice'>You place [src] onto the ground, and it shapes into [rune]!</span>")
		rune.extract = src
		forceMove(rune)

/obj/effect/slimerune
	name = "blank rune"
	desc = "This doesn't seem to do anything..."
	anchored = TRUE
	icon = 'icons/effects/crayondecal.dmi'
	icon_state = "rune3"
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = SIGIL_LAYER

	var/obj/item/slimecross/warping/extract
	var/pickuptime = 20 //2 seconds

/obj/effect/slimerune/attack_hand(mob/living/user)
	. = ..()
	var/mob/living/L = user
	if(!istype(user))
		return
	if(.)
		return
	to_chat(user, "<span class='warning'>You begin to gather [src] up off the ground.</span>")
	if(do_after(user, pickuptime, src))
		if(QDELETED(src))
			return
		to_chat(user, "<span class='notice'>You collect [src] into a pile, and it reforms into [extract]!</span>")
		extract.forceMove(loc)
		on_remove()
		qdel(src)
		L.put_in_hands(extract)

/obj/effect/slimerune/Initialize(mapload)
	. = ..()
	on_place()

/obj/effect/slimerune/Destroy()
	STOP_PROCESSING(SSobj,src)
	return ..()

/obj/effect/slimerune/proc/on_place()
	START_PROCESSING(SSobj,src)
	return

/obj/effect/slimerune/proc/on_remove()
	return

/obj/item/slimecross/warping/grey/
	colour = "grey"
	rune_path = /obj/effect/slimerune/grey
	effect_desc = "Forms a recoverable rune that absorbs slime extracts to produce baby slimes."
	var/num_absorbed = 0

/obj/item/slimecross/warping/orange
	colour = "orange"
	rune_path = /obj/effect/slimerune/orange
	effect_desc = "Forms a recoverable rune that functions as a fancy, magical bonfire."

/obj/item/slimecross/warping/purple
	colour = "purple"
	rune_path = /obj/effect/slimerune/purple
	effect_desc = "Forms a recoverable rune that converts cloth and plastic to medical supplies."

/obj/item/slimecross/warping/blue
	colour = "blue"
	rune_path = /obj/effect/slimerune/blue
	effect_desc = "Forms a recoverable rune that douses the area it is on with water."

/obj/item/slimecross/warping/metal
	colour = "metal"
	rune_path = /obj/effect/slimerune/metal
	effect_desc = "Forms a recoverable rune that functions as a transparent wall."

/obj/item/slimecross/warping/yellow
	colour = "yellow"
	rune_path = /obj/effect/slimerune/yellow
	effect_desc = "Forms a recoverable rune that drains batteries on the tile to fuel the area's APC."

/obj/item/slimecross/warping/darkpurple
	colour = "dark purple"
	rune_path = /obj/effect/slimerune/darkpurple
	effect_desc = "Forms a recoverable rune that grows crystallized plasma over time. It's too fragile to make sheets out of..."

/obj/item/slimecross/warping/darkblue
	colour = "dark blue"
	rune_path = /obj/effect/slimerune/darkblue
	effect_desc = "Forms a recoverable rune that lowers the body temperature of creatures that enter its circle."

/obj/item/slimecross/warping/silver
	colour = "silver"
	rune_path = /obj/effect/slimerune/silver
	effect_desc = "Forms a recoverable rune that absorbs food to feed those who cross its path."
	var/nutrition = 0

/obj/item/slimecross/warping/bluespace //TODO: Fix issues.
	colour = "bluespace"
	rune_path = /obj/effect/slimerune//bluespace
	effect_desc = "Forms a recoverable rune that links a <b>wormhole satchel</b> with the space above it."

/obj/item/slimecross/warping/sepia
	colour = "sepia"
	rune_path = /obj/effect/slimerune/sepia
	effect_desc = "Forms a recoverable rune that holds any living creature in its influence under stasis."

/obj/item/slimecross/warping/cerulean
	colour = "cerulean"
	rune_path = /obj/effect/slimerune/cerulean
	effect_desc = "Forms a recoverable rune that displays a hologram of the last creature to cross it."

/obj/item/slimecross/warping/pyrite
	colour = "pyrite"
	rune_path = /obj/effect/slimerune/pyrite
	effect_desc = "Forms a recoverable rune that paints things that cross its area a rainbow of colors."

/obj/item/slimecross/warping/red
	colour = "red"
	rune_path = /obj/effect/slimerune/red
	effect_desc = "Forms a recoverable rune that increases the effectiveness of unarmed attacks made from within it."

/obj/item/slimecross/warping/green
	colour = "green"
	rune_path = /obj/effect/slimerune/green
	effect_desc = "Forms a recoverable rune that converts sheets of plasma to resin, allowing you to form xenomorphic structures."

/obj/item/slimecross/warping/pink
	colour = "pink"
	rune_path = /obj/effect/slimerune
	effect_desc = "Forms a recoverable rune that makes hugging anyone standing in it a pleasant experience."

/obj/item/slimecross/warping/gold
	colour = "gold"
	rune_path = /obj/effect/slimerune
	effect_desc = "Forms a recoverable rune that accepts coinage for items drawn from an unknown dimension."

/obj/item/slimecross/warping/oil
	colour = "oil"
	rune_path = /obj/effect/slimerune
	effect_desc = "Forms a recoverable rune that absorbs explosions, converting them into a gooey energy."

/obj/item/slimecross/warping/black
	colour = "black"
	rune_path = /obj/effect/slimerune
	effect_desc = "Forms a recoverable rune that summons the spirits of the imminently deceased."

/obj/item/slimecross/warping/lightpink
	colour = "light pink"
	rune_path = /obj/effect/slimerune
	effect_desc = "Forms a recoverable rune that stops simple creatures from crossing its boundary."

/obj/item/slimecross/warping/adamantine
	colour = "adamantine"
	rune_path = /obj/effect/slimerune
	effect_desc = "Forms a recoverable rune that crystallizes materials based on nearby ore nodes."

/obj/item/slimecross/warping/rainbow
	colour = "rainbow"
	rune_path = /obj/effect/slimerune
	effect_desc = "Forms a recoverable rune that opens a gate to a pocket dimension."

///////////////////////////////////////////////
//////////////////SLIME RUNES//////////////////
///////////////////////////////////////////////

/obj/effect/slimerune/grey
	name = "grey rune"
	desc = "The center has an outline of a slime extract in it."

/obj/effect/slimerune/grey/examine(mob/user)
	..()
	var/obj/item/slimecross/warping/grey/ex = extract
	to_chat(user, "<span class='notice'>It has absorbed [ex.num_absorbed] extract[(ex.num_absorbed != 1) ? "s":""].</span>")
	to_chat(user, "<span class='notice'>At 8 extracts, it can be manually fed an extract to produce a slime of that color.</span>")

/obj/effect/slimerune/grey/process()
	var/obj/item/slimecross/warping/grey/ex = extract
	if(ex.num_absorbed >= 8)
		return
	if(locate(/obj/item/slime_extract) in get_turf(loc))
		var/eaten = 0
		for(var/obj/item/slime_extract/x in get_turf(src))
			if(ex.num_absorbed >= 8)
				break
			qdel(x)
			ex.num_absorbed++
			eaten += 1
		visible_message("<span class='notice'>[src] glows, and the extract[eaten != 1 ? "s":""] on it fade[eaten != 1 ? "":"s"] away.</span>")
		if(ex.num_absorbed >= 8)
			visible_message("<span class='notice'>[src] has finished its bluespace calibration, and can now produce a slime.</span>")

/obj/effect/slimerune/grey/attackby(obj/item/slime_extract/O, mob/user)
	var/obj/item/slimecross/warping/grey/ex = extract
	if(!istype(O))
		return
	if(ex.num_absorbed < 8)
		to_chat(user, "<span class='warning'>[src] isn't calibrated with enough slime extracts to produce a slime.</span>")
		return
	ex.num_absorbed = 0
	user.visible_message("<span class='warning'>[user] places a slime extract onto [src], and a slime grows from it!</span>", "<span class='notice'>You place [O] onto [src], and a slime grows from it!</span>")
	var/mob/living/simple_animal/slime/S = new(loc)
	S.set_colour(O.slimecolor)
	qdel(O)
	return

/obj/effect/slimerune/orange
	name = "orange rune"
	desc = "It's hot to the touch..."
	var/obj/structure/bonfire/prelit/slime/fire

/obj/effect/slimerune/orange/on_place()
	fire = new(loc)

/obj/effect/slimerune/orange/on_remove()
	qdel(fire)

/obj/structure/bonfire/prelit/slime
	name = "magical flame"
	desc = "It floats above the rune with constrained purpose."

/obj/structure/bonfire/prelit/slime/CheckOxygen()
	return TRUE

/obj/structure/bonfire/prelit/slime/extinguish()
	return

/obj/effect/slimerune/purple
	name = "purple rune"
	desc = "It longs for cloth to weave and plastics to catalyze."

/obj/effect/slimerune/purple/process()
	for(var/obj/item/stack/sheet/cloth/C in get_turf(loc))
		if(C.use(20))
			var/obj/item/stack/medical/bruise_pack/B = new(loc)
			visible_message("<span class='notice'>[src] weaves [C] into [B].")
			break

	for(var/obj/item/stack/sheet/plastic/P in get_turf(loc))
		if(P.use(20))
			var/obj/item/stack/medical/ointment/O = new(loc)
			visible_message("<span class='notice'>[src] melts down [P], creating [O].")
			break

/obj/effect/slimerune/blue
	name = "blue rune"
	desc = "It constantly mists water from its intricate design."

/obj/effect/slimerune/blue/ComponentInitialize()
	AddComponent(/datum/component/slippery, 80)

/obj/effect/slimerune/blue/process()
	var/obj/effect/particle_effect/water/W = new /obj/effect/particle_effect/water(get_turf(src))
	var/datum/reagents/R = new/datum/reagents(10)
	W.reagents = R
	R.my_atom = W
	R.add_reagent(/datum/reagent/water, 10)
	for(var/atom/A in get_turf(loc))
		W.Bump(A)

/obj/effect/slimerune/metal
	name = "metal rune"
	desc = "The air above it feels solid to the touch."
	density = TRUE
	pickuptime = 100 //10 seconds.

/obj/effect/slimerune/yellow
	name = "yellow rune"
	desc = "The air around it feels negatively charged."

/obj/effect/slimerune/yellow/process()
	var/total = 0
	for(var/atom/movable/A in get_turf(loc))
		var/obj/item/stock_parts/cell/C = A.get_cell()
		if(C && C.charge > 0)
			var/amount = min(C.charge, 1000)
			total += amount
			C.use(amount)
	for(var/obj/machinery/power/apc/A in get_area(loc))
		var/obj/item/stock_parts/cell/C = A.get_cell()
		C.give(total)

/obj/effect/slimerune/darkpurple
	name = "dark purple rune"
	desc = "Plasma mist seeps from the edges of the rune, pooling in the center."
	var/time_to_produce = 2
	var/production = 0

/obj/effect/slimerune/darkpurple/process() //Will likely slow this down.
	if(production < time_to_produce)
		production++
		return
	production = 0
	var/obj/item/plasmacrystal/crystal = locate(/obj/item/plasmacrystal) in get_turf(loc)
	if(!istype(crystal))
		crystal = new(loc)
	crystal.reagents.add_reagent(/datum/reagent/toxin/plasma,5)
	crystal.update_icon()

/obj/item/plasmacrystal
	name = "plasma crystal"
	desc = "A fragile shard of crystallized plasma. Useless to fabricators, but it would probably fit in a grinder rather easily."
	icon = 'icons/obj/shards.dmi' //Temp icons
	icon_state = "plasmasmall"
	grind_results = list(/datum/reagent/toxin/plasma=0)

/obj/item/plasmacrystal/Initialize(mapload)
	. = ..()
	create_reagents(100)

/obj/item/plasmacrystal/update_icon() //Temp icons
	if(reagents.total_volume >= 100)
		icon_state = "plasmalarge"
	else if(reagents.total_volume >= 50)
		icon_state = "plasmamedium"
	else
		icon_state = "plasmasmall"

/obj/effect/slimerune/darkblue
	name = "dark blue rune"
	desc = "The air doesn't feel colder around it, but it sends a chill through you nonetheless."

/obj/effect/slimerune/darkblue/process()
	for(var/mob/living/L in get_turf(loc))
		L.adjust_bodytemperature(-20)

/obj/effect/slimerune/darkblue/Crossed(atom/movable/AM)
	. = ..()
	var/mob/living/L = AM
	if(!istype(L))
		return
	L.adjust_bodytemperature(-70) //Crossing it is much stronger of an effect.

/obj/effect/slimerune/silver
	name = "silver rune"
	desc = "Sate its hunger, so that you might sate yours."

/obj/effect/slimerune/silver/process()
	var/obj/item/reagent_containers/food/snacks/snack = locate(/obj/item/reagent_containers/food/snacks) in get_turf(loc)
	if(snack)
		var/datum/reagent/N = snack.reagents.has_reagent(/datum/reagent/consumable/nutriment)
		var/obj/item/slimecross/warping/silver/ex = extract
		qdel(snack)
		ex.nutrition += N.volume * 2

/obj/effect/slimerune/silver/Crossed(atom/movable/AM)
	. = ..()
	var/mob/living/carbon/human/H = AM
	if(!istype(H))
		return
	if(!HAS_TRAIT(H, TRAIT_NOHUNGER))
		var/difference = NUTRITION_LEVEL_FULL - H.nutrition
		if(difference > 0)
			var/obj/item/slimecross/warping/silver/ex = extract
			var/nutrition = min(ex.nutrition, difference)
			H.adjust_nutrition(nutrition)
			ex.nutrition -= nutrition

/obj/effect/slimerune/bluespace
	name = "bluespace rune"
	desc = "A rectangular hole is at the center, covered with blue cloth."
	var/obj/item/storage/backpack/satchel/warping/satchel

/obj/effect/slimerune/bluespace/on_place()
	. = ..()
	satchel = new(loc, get_turf(loc))

/obj/effect/slimerune/bluespace/process()
	if(!istype(satchel))
		extract.forceMove(loc)
		on_remove()
		qdel(src)

/obj/effect/slimerune/bluespace/on_remove()
	if(satchel)
		qdel(satchel)

/obj/item/storage/backpack/satchel/warping
	name = "wormhole satchel"
	desc = "You can make out a strange runic pattern on the interior."
	component_type = /datum/component/storage/concrete/tilebound

/obj/item/storage/backpack/satchel/warping/Initialize(mapload, turf/tileloc)
	. = ..()
	var/datum/component/storage/concrete/tilebound/STR = GetComponent(/datum/component/storage/concrete/tilebound)
	STR.base_tile = tileloc

/obj/effect/slimerune/sepia
	name = "sepia rune"
	desc = "You can feel it slow your breathing and your pulse."

/obj/effect/slimerune/sepia/on_place()
	return //Stops it from processing.

/obj/effect/slimerune/sepia/Crossed(atom/movable/AM)
	if(isliving(AM))
		var/mob/living/L = AM
		L.apply_status_effect(STATUS_EFFECT_STASIS, null, TRUE)
		RegisterSignal(L, COMSIG_LIVING_RESIST, .proc/resist_stasis)

/obj/effect/slimerune/sepia/Uncrossed(atom/movable/AM)
	if(isliving(AM))
		var/mob/living/L = AM
		L.remove_status_effect(STATUS_EFFECT_STASIS)
		UnregisterSignal(L, COMSIG_LIVING_RESIST)

/obj/effect/slimerune/sepia/Destroy() //On Destroy rather than on_remove to ensure you absolutely cannot circumvent it and maintain infinite stasis.
	for(var/mob/living/L in get_turf(src))
		L.remove_status_effect(STATUS_EFFECT_STASIS)
		UnregisterSignal(L, COMSIG_LIVING_RESIST)
	return ..()

/obj/effect/slimerune/sepia/proc/resist_stasis(mob/living/M)
	attack_hand(M)

/obj/effect/slimerune/cerulean
	name = "cerulean rune"
	desc = "It shimmers from certain angles, like an empty mirror..."
	var/atom/movable/lastcrossed

/obj/effect/slimerune/cerulean/on_place()
	return //Stops it from processing.

/obj/effect/slimerune/cerulean/Crossed(atom/movable/AM)
	if(isliving(AM))
		vis_contents -= lastcrossed
		lastcrossed = AM
		vis_contents += lastcrossed

/obj/effect/slimerune/pyrite
	name = "pyrite rune"
	desc = "It glitters, reflecting a rainbow of colors."

/obj/effect/slimerune/pyrite/on_place()
	return //Stops it from processing.

/obj/effect/slimerune/pyrite/Crossed(atom/movable/AM)
	AM.add_atom_colour(rgb(rand(0,255),rand(0,255),rand(0,255)), WASHABLE_COLOUR_PRIORITY)

/obj/effect/slimerune/red
	name = "red rune"
	desc = "Just looking at it makes you want to ball your fists."

/obj/effect/slimerune/red/on_place()
	return //Stops it from processing.

/obj/effect/slimerune/red/Crossed(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/C = AM
		RegisterSignal(C, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, .proc/bonus_damage)

/obj/effect/slimerune/red/Uncrossed(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/C = AM
		UnregisterSignal(C, COMSIG_HUMAN_MELEE_UNARMED_ATTACK)

/obj/effect/slimerune/red/proc/bonus_damage(mob/living/user, atom/A)
	if(!isliving(A))
		return
	var/mob/living/L = A
	L.visible_message("<span class='danger'>[src] glows brightly below [user]...</span>", "<span class='userdanger'>[src] glows, empowering [user]'s attack!</span>")
	L.adjustBruteLoss(10) //Turns the average punch into the equivalent of a toolbox, but only as long as you're on the tile.

/obj/effect/slimerune/green
	name = "green rune"
	desc = "Strange, alien markings line the interior. It searches for plasma."

/obj/effect/slimerune/green/process()
	for(var/obj/item/stack/sheet/mineral/plasma/P in get_turf(loc))
		if(P.use(2))
			new /obj/item/stack/sheet/resin(loc)