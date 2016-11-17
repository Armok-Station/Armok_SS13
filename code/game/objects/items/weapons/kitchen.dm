/* Kitchen tools
 * Contains:
 *		Fork
 *		Kitchen knives
 *		Ritual Knife
 *		Butcher's cleaver
 *		Combat Knife
 *		Rolling Pins
 */

/obj/item/weapon/kitchen
	icon = 'icons/obj/kitchen.dmi'
	origin_tech = "materials=1"

/obj/item/weapon/kitchen/fork
	name = "fork"
	desc = "Pointy."
	icon_state = "fork"
	force = 5
	w_class = 1
	throwforce = 0
	throw_speed = 3
	throw_range = 5
	materials = list(MAT_METAL=80)
	flags = CONDUCT
	attack_verb = list("attacked", "stabbed", "poked")
	hitsound = 'sound/weapons/bladeslice.ogg'
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 50, acid = 30)
	var/datum/reagent/forkload //used to eat omelette

	var/loaded_food_name
	var/image/loaded_food
	melt_temperature = MELTPOINT_STEEL

/obj/item/weapon/kitchen/utensil/fork/New()
	..()
	reagents = new(10)
	reagents.my_atom = src

/obj/item/weapon/kitchen/utensil/fork/attack_self(var/mob/living/carbon/user)
	if(loaded_food)
		attack(user,user)

/obj/item/weapon/kitchen/utensil/fork/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	if(!istype(M) || !istype(user))
		return ..()

	if(user.zone_sel.selecting != "eyes" && user.zone_sel.selecting != LIMB_HEAD && M != user && !loaded_food)
		return ..()

	if (src.loaded_food)
		reagents.update_total()
		if(M == user)
			user.visible_message("<span class='notice'>[user] eats a delicious forkful of [loaded_food_name]!</span>")
			feed_to(user, user)
			return
		else
			user.visible_message("<span class='notice'>[user] attempts to feed [M] a delicious forkful of [loaded_food_name].</span>")
			if(do_mob(user, M))
				if(!loaded_food)
					return

				user.visible_message("<span class='notice'>[user] feeds [M] a delicious forkful of [loaded_food_name]!</span>")
				feed_to(user, M)
				return
	else
		if((M_CLUMSY in user.mutations) && prob(50))
			return eyestab(user,user)
		else
			return eyestab(M, user)

/obj/item/weapon/kitchen/utensil/fork/examine(mob/user)
	..()
	if(loaded_food)
		user.show_message("It has a forkful of [loaded_food_name] on it.")

/obj/item/weapon/kitchen/utensil/fork/proc/load_food(obj/item/weapon/reagent_containers/food/snacks/snack, mob/user)
	if(!snack || !user || !istype(snack) || !istype(user))
		return

	if(loaded_food)
		to_chat(user, "<span class='notice'>You already have food on \the [src].</span>")
		return

	if(snack.wrapped)
		to_chat(user, "<span class='notice'>You can't eat packaging!</span>")
		return

	if(snack.reagents.total_volume)
		loaded_food_name = snack.name
		var/icon/food_to_load = getFlatIcon(snack)
		food_to_load.Scale(16,16)
		loaded_food = image(food_to_load)
		loaded_food.pixel_x = 8 * PIXEL_MULTIPLIER + src.pixel_x
		loaded_food.pixel_y = 15 * PIXEL_MULTIPLIER + src.pixel_y
		src.overlays += loaded_food
		if(snack.reagents.total_volume > snack.bitesize)
			snack.reagents.trans_to(src, snack.bitesize)
		else
			snack.reagents.trans_to(src, snack.reagents.total_volume)
			snack.bitecount++
			snack.after_consume(user)
	return 1

/obj/item/weapon/kitchen/utensil/fork/proc/feed_to(mob/living/carbon/user, mob/living/carbon/target)
	reagents.reaction(target, INGEST)
	reagents.trans_to(target.reagents, reagents.total_volume, log_transfer = TRUE, whodunnit = user)
	overlays -= loaded_food
	qdel(loaded_food)
	loaded_food = null
	loaded_food_name = null

/obj/item/weapon/kitchen/knife
	name = "kitchen knife"
	icon_state = "knife"
	desc = "A general purpose Chef's Knife made by SpaceCook Incorporated. Guaranteed to stay sharp for years to come."
	flags = CONDUCT
	force = 10
	w_class = 2
	throwforce = 10
	hitsound = 'sound/weapons/bladeslice.ogg'
	throw_speed = 3
	throw_range = 6
	materials = list(MAT_METAL=12000)
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	sharpness = IS_SHARP_ACCURATE
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 50, acid = 50)

/obj/item/weapon/kitchen/knife/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(user.zone_selected == "eyes")
		if(user.disabilities & CLUMSY && prob(50))
			M = user
		return eyestab(M,user)
	else
		return ..()

/obj/item/weapon/kitchen/knife/suicide_act(mob/user)
	user.visible_message(pick("<span class='suicide'>[user] is slitting [user.p_their()] wrists with the [src.name]! It looks like [user.p_theyre()] trying to commit suicide.</span>", \
						"<span class='suicide'>[user] is slitting [user.p_their()] throat with the [src.name]! It looks like [user.p_theyre()] trying to commit suicide.</span>", \
						"<span class='suicide'>[user] is slitting [user.p_their()] stomach open with the [src.name]! It looks like [user.p_theyre()] trying to commit seppuku.</span>"))
	return (BRUTELOSS)

/obj/item/weapon/kitchen/knife/ritual
	name = "ritual knife"
	desc = "The unearthly energies that once powered this blade are now dormant."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "render"
	w_class = 3

/obj/item/weapon/kitchen/knife/butcher
	name = "butcher's cleaver"
	icon_state = "butch"
	desc = "A huge thing used for chopping and chopping up meat. This includes clowns and clown by-products."
	flags = CONDUCT
	force = 15
	throwforce = 10
	materials = list(MAT_METAL=18000)
	attack_verb = list("cleaved", "slashed", "stabbed", "sliced", "torn", "ripped", "diced", "cut")
	w_class = 3

/obj/item/weapon/kitchen/knife/combat
	name = "combat knife"
	icon_state = "buckknife"
	item_state = "knife"
	desc = "A military combat utility survival knife."
	force = 20
	throwforce = 20
	origin_tech = "materials=3;combat=4"
	attack_verb = list("slashed", "stabbed", "sliced", "torn", "ripped", "cut")


/obj/item/weapon/kitchen/knife/combat/survival
	name = "survival knife"
	icon_state = "survivalknife"
	desc = "A hunting grade survival knife."
	force = 15
	throwforce = 15

/obj/item/weapon/kitchen/knife/combat/bone
	name = "bone dagger"
	item_state = "bone_dagger"
	icon_state = "bone_dagger"
	desc = "A sharpened bone. The bare mimimum in survival."
	force = 15
	throwforce = 15
	materials = list()

/obj/item/weapon/kitchen/knife/combat/cyborg
	name = "cyborg knife"
	icon = 'icons/obj/items_cyborg.dmi'
	icon_state = "knife"
	desc = "A cyborg-mounted plasteel knife. Extremely sharp and durable."
	origin_tech = null

/obj/item/weapon/kitchen/knife/carrotshiv
	name = "carrot shiv"
	icon_state = "carrotshiv"
	item_state = "carrotshiv"
	desc = "Unlike other carrots, you should probably keep this far away from your eyes."
	force = 8
	throwforce = 12//fuck git
	materials = list()
	origin_tech = "biotech=3;combat=2"
	attack_verb = list("shanked", "shivved")
	armor = list(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0)

/obj/item/weapon/kitchen/rollingpin
	name = "rolling pin"
	desc = "Used to knock out the Bartender."
	icon_state = "rolling_pin"
	force = 8
	throwforce = 5
	throw_speed = 3
	throw_range = 7
	w_class = 3
	attack_verb = list("bashed", "battered", "bludgeoned", "thrashed", "whacked")

/* Trays  moved to /obj/item/weapon/storage/bag */
