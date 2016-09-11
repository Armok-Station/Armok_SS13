// Living clothing for possible future antag type. Not ripping off Kill la Kill, no siree.
// ~a-t48/Flexicode

// Design todos:
// TODO: figure out progression mechanic. It would be nice to gate abilities behind number of clothes eaten, but that means thinking up of more abilities.
// TODO: figure out goals better

// Work todos:
// FUCK TODO: host is a reserved name
// Make it so that you can hear shit your host can hear
// Retract arm blade (on detach automatically, otherwise manually)
// Disable suit sensors
// Damage forwarding
// Disallow adjusting of suit?
// Blood stuff
// Interactions between two living clothes
// Natural protection from facehuggers (allowing it will just cause problems)
// Interactions with lings? No way this could go bad, ever.
// Put glow around moving clothes on the ground?
// Absorb blood that splatters on us
// Surgury to remove clothes (ew)
// Fancy transform effect
// Let your first host name you :) :)
// All antag code (for later)
// Fix F12
// Fix /mob/living/carbon/update_inv_r_hand() to update the screen of the clothes
//		...looks like a bunch of them are messed up. Disable showing inventory at all,
//		unless we move all the if(client) checks and add ourselves as an observer
// TODO: got attacked by poly, attached to host, died because poly. wtf.
// Store DNA off and use it when spitting blood
// TODO: being in a form means you don't need your legs
// TODO: only allow armblade in blade form
// Add drop item on HUD.

////////////////////////////////////////////////////////
// Summary
//
// You are an alien living piece of clothing. Find a host (or start off with one?) rip off their clothes and transform.
// Your goal is probably to eat other clothing that has been worn. Jumpsuits that people spawn in work, as do clothes worn for longer than 15 minutes.
// You could always ask your target to give up his clothes, but good luck with that. On the other hand, you only need to leave people naked and unconscious, rather than dead.

////////////////////////////////////////////////////////
// Abilities

////////////////////////////////////////////////////////
// Without host:
// 	Vent crawl
//		Nuff said.
//
// 	Able to leap onto a human, tear off their clothes. This also forces a transform the first time you do this to a host.
//
//  Someone can also willingly put you on, but where's the fun in that?
//
//	Able to open doors if you have an id in pocket
//
//  Can change look to any jumpsuits and a bunch of costumes. (or maybe you have to eat the clothes to change to them)
//
//  Doesn't need oxygen.
//
//  Resists crushing damage, vulnerable to slicing and fire damage.


////////////////////////////////////////////////////////
// Host 'benefits'
//
//	Blood regeneration
//		You regenerate blood 3 times as fast.
//
//  Natural healing
//		Wearing living clothing SLOWLY heals you from brute
//
//	Can no longer wear clothes over your living clothing.
//
//  Can't take off your clothes, have to ask the clothing to remove itself. (?)
//
//  Can strip people twice as fast.

////////////////////////////////////////////////////////
// With host (untransformed):
//
// 	Can change look as above.
//
//	Unconscious movement
// 		If host goes unconscious, you can slowly move the host to somewhere safe.
//
// 	Transformation
//		Drink some blood - you transform into a stronger form.
//
//  Untransform
//		Can do this any time you are transformed, or if you take too much damage.
//
// 	Overload\Blood heat
//		You absorb most of the blood of your host, transform into an extremely powerful form.
//		The host goes unconscious and loses control. You now control movement.
//		You lose some control too. You autoattack everything around you.
//
//  Eat clothing
//		Lets you eat clothes. Heals you. Unworn shit works kind of crappily - the more worn the clothing the better.
//
//	Give blood
//		You fucked up. Your host is now unconscious on the floor due to blood lost.
//		Give some blood back with 50 percent efficiency.

////////////////////////////////////////////////////////
// With host (transformed)
//
//	Drink Blood
// 		Pull some blood from your host to fuel your powers
//
//  All damage to host except for targeted at head is damage reduced and applied to you.
//		Spews blood everywhere because you drank it from your host.
//
// 	Chem injections instead go to you. Probably have no effect?
//
//	All forms have an initial blood cost for the transformation and slowly drain blood
//
// 	Flight form
//		Lets you jetpack around, even with gravity on
//
// 	Blades form
//		Gain armblade (steal from ling, gogogo), people get damage if they attack\grab you.
//		Transforming breaks cuffs.
//
// 	Armour form
//		Increased defense
//
// 	TODO: some way of surviving space, as you can't wear spacesuits.
//	Blood Oxygenation
//		Use up stored blood to give your host a thin transparent skin around him (protect against pressure) and oxygen
//

////////////////////////////////////////////////////////
// the mob code

/mob/living/simple_animal/clothing
	languages_spoken = HUMAN // TODO: replace with CLOTHING. People you possess gain the ability to speak CLOTHING
	languages_understood = HUMAN

	status_flags = 0
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_SMALL

	ventcrawler = 2

	stop_automated_movement = 1

	// Damage vars
	melee_damage_lower = 1
	melee_damage_upper = 1
	obj_damage = 0 //how much damage this simple animal does to objects, if any
	armour_penetration = 0 //How much armour they ignore, as a flat reduction from the targets armour value
	melee_damage_type = BRUTE //Damage type of a simple mob's melee attack, should it do damage.
	list/damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0) // 1 for full damage , 0 for none , -1 for 1:1 heal from that source
	attacktext = "attacks"
	sound/attack_sound = 'sound/weapons/punch1.ogg'
	//sound/miss_sound = 'sound/weapons/punchmiss.ogg'
	//friendly = "nuzzles" //If the mob does no damage with it's attack
	environment_smash = 0 //Set to 1 to allow breaking of crates,lockers,racks,tables; 2 for walls; 3 for Rwalls

	// Appearance vars
	var/appearance_name = "blue schoolgirl uniform"

	var/list/stored_appearances = list(
		//initial(/obj/item/clothing/under/color/grey.name) = /obj/item/clothing/under/color/grey,
		"blue schoolgirl uniform" = /obj/item/clothing/under/schoolgirl,
		)

	var/list/stored_apparence_names = list(
		//initial(/obj/item/clothing/under/color/grey.name),
		"blue schoolgirl uniform"
		)

	var/list/powers_with_host = list(
		/datum/action/generic/clothes_drink_blood,
		/datum/action/generic/living_clothing/detach,
		/datum/action/generic/clothes_grow_armour,
		/datum/action/generic/clothes_grow_blade,
		)

	var/list/current_dynamic_powers = list()

	// Attachment vars
	var/obj/item/clothing/under/living/linked_clothes = null

/mob/living/simple_animal/clothing/get_blood_id()
	return "blood"

/mob/living/simple_animal/clothing/New()
	// I guess we want this?
	// create_reagents(1000)

	var/datum/action/generic/set_living_clothing_appearance/CC = new(src)
	CC.Grant(src)

	set_appearance(appearance_name)

	// Can hold 500 units of blood
	create_reagents(500)
	..()

// Handle dir change due to clicking around on screen
/mob/living/simple_animal/clothing/setDir(newDir)
	handleDir(newDir)
	return ..()

// Handle dir change due to movement
/mob/living/simple_animal/clothing/Moved(atom/OldLoc, newDir)
	handleDir(newDir)
	return ..()

/mob/living/simple_animal/clothing/proc/handleDir(newDir)
	// TODO: we should maybe use icon rotations instead...
	// TODO: is this mob scalable??
	//if(newDir != dir)
	var/angle = dir2angle(newDir)
	var/matrix/ntransform = matrix()
	ntransform.Turn(angle)
	transform = ntransform

/mob/living/simple_animal/clothing/proc/set_appearance(appearance_name = "")
	if(appearance_name == "")
		appearance_name = input("Select your appearance!", "Living Clothing Appearance", null, null) in stored_apparence_names

	src.appearance_name = appearance_name

	var/appearance_type = stored_appearances[appearance_name]

	var/obj/item/clothing/C = new appearance_type()

	icon = C.icon
	icon_living = C.icon_state
	icon_state = C.icon_state

	if(linked_clothes)
		linked_clothes.icon = C.icon
		linked_clothes.icon_state = C.icon_state
		linked_clothes.item_state = C.item_state
		linked_clothes.item_color = C.item_color

		if(linked_clothes.loc && istype(linked_clothes.loc,/mob/living/carbon/human))
			var/mob/living/carbon/human/H = linked_clothes.loc
			H.update_inv_w_uniform()

	sparkle()

	qdel(C)

/mob/living/simple_animal/clothing/UnarmedAttack(atom/A, proximity)
	var/mob/living/M = A
	if(M)
		if(TryAttach(M))
			return
	..()

/mob/living/simple_animal/clothing/proc/TryAttach(mob/living/M)
	if(!isliving(M))
		return 0
	if(!ishuman(M))
		return 0 // As fun as trying to implement this for aliens and corgi would be...

	if(stat != CONSCIOUS)
		return 0

	if(linked_clothes)
		return 0

	M.visible_message("<span class='danger'>[src] leaps at [M]'s body!</span>", \
						"<span class='userdanger'>[src] leaps at [M]'s body!</span>")

	var/mob/living/carbon/human/target = M

	if(target.wear_suit)
		var/obj/item/clothing/Suit = target.wear_suit
		if(Suit.flags & NODROP)
			return 0
		target.unEquip(Suit)
		target.visible_message("<span class='danger'>[src] tears [Suit] off of [target]'s body!</span>", \
								"<span class='userdanger'>[src] tears [Suit] off of [target]'s body!</span>")

	if(target.w_uniform)
		var/obj/item/clothing/Uniform = target.w_uniform
		if(Uniform.flags & NODROP)
			return 0
		target.unEquip(Uniform)
		target.visible_message("<span class='danger'>[src] tears [Uniform] off of [target]'s body!</span>", \
								"<span class='userdanger'>[src] tears [Uniform] off of [target]'s body!</span>")

		// Save this type of uniform for later
		var/name = Uniform.name
		if(!stored_appearances[name])
			stored_appearances[name] = Uniform.type
			stored_apparence_names.Insert(0, name)

		qdel(Uniform)

	// Create new clothing
	var/obj/item/clothing/under/living/U = new()

	if(!target.equip_to_slot_if_possible(U, slot_w_uniform))
		//TODO
		//target.visible_message("<span class='danger'>[src] tears [Uniform] off of [target]'s body!</span>", \
		//		"<span class='userdanger'>[src] tears [Uniform] off of [target]'s body!</span>")
		qdel(U)
		return

	U.linked_mob = src
	linked_clothes = U
	set_appearance(appearance_name)


	forceMove(linked_clothes)

	// Setup abilities
	for(var/T in powers_with_host)
		var/datum/action/generic/A = new T(src)
		A.Grant(src)
		current_dynamic_powers += A

	// Setup HUD

	hud_used.blooddisplay.invisibility = 0
	hud_used.action_intent.invisibility = INVISIBILITY_ABSTRACT
	target.hud_used.show_hud(1,src)
	hud_used.show_hud(1,src,1)

	transform_effect(target, 1)

	//hud_used.healthdoll = target.hud_used.healthdoll
	//hud_used.infodisplay += hud_used.healthdoll

	return 1

/mob/living/simple_animal/clothing/proc/TryDetach()
	var/mob/living/carbon/human/host = getHost()

	if(!host)
		return

	// Force us off of the clothes obj
	forceMove(get_turf(src))

	// Force our clothes to drop
	host.unEquip(linked_clothes, 1)
	linked_clothes = null

	// Fixup HUD
	hud_used.blooddisplay.invisibility = INVISIBILITY_ABSTRACT
	hud_used.action_intent.invisibility = 0
	hud_used.show_hud(1,src)

	for(var/datum/action/generic/A in current_dynamic_powers)
		A.Remove(src)

	current_dynamic_powers = list()

	src << "You detach from your host!"
	host << "The clothing detaches from you!"

	// Lose all your stored blood
	bleed(blood_volume)
	sparkle() // we vampire now

/mob/living/simple_animal/clothing/proc/getHost()
	if(linked_clothes && linked_clothes.loc && istype(linked_clothes.loc,/mob/living/carbon/human))
		. = linked_clothes.loc

////////////////////////////////////////////////////////
// The clothes item code

/obj/item/clothing/under/living
	desc = "Some clothes - they feel weird to the touch."
	name = "strange clothing"
	var/mob/living/simple_animal/clothing/linked_mob = null
	flags = ABSTRACT | NODROP | DROPDEL

// TODO: handle emergency delete code (host got gibbed?)

////////////////////////////////////////////////////////
// Abilities code

//TODO: properly namespace this shit

////////////////////////////////////////////////////////
// Detach

/datum/action/generic/living_clothing/detach
	name = "Detach"
	desc = "Detach from your host."
	button_icon_state = "meson"
	procname = /mob/living/simple_animal/clothing/proc/detach_action

/mob/living/simple_animal/clothing/proc/detach_action()
	TryDetach()

/datum/action/generic/set_living_clothing_appearance
	name = "Change Appearance"
	desc = "Switch what you want to look like."
	button_icon_state = "meson"
	procname = /mob/living/simple_animal/clothing/proc/set_appearance_action

/mob/living/simple_animal/clothing/proc/set_appearance_action()
	set_appearance()

////////////////////////////////////////////////////////
// Grow Armour

/datum/action/generic/clothes_grow_armour
	name = "Grow armour"
	desc = "Grow clothing armour"
	button_icon_state = "meson"
	procname = /mob/living/simple_animal/clothing/proc/grow_armour_action

/mob/living/simple_animal/clothing/proc/grow_armour_action()
	var/mob/living/carbon/human/host = getHost()

	if(!host)
		return
/*
	if(!host.drop_item())
		host << "<span class='warning'>The [host.get_active_hand()] is stuck to your host's hand, you cannot grow a blade over it!</span>"
		return
*/

	var/obj/item/clothing/suit/living_clothing/armour_form/W = new(host)

	if(!host.equip_to_slot_if_possible(W, slot_wear_suit))
		src << "<span class='warning'>Something is preventing you from transforming!</span>"
		host << "<span class='warning'>Something is preventing your clothes from transforming!</span>"
		return

	transform_effect(host, 0)

/obj/item/clothing/suit/living_clothing/armour_form
	name = "Armour form"
	desc = "You gain increased defense in this form"
	icon_state = "knight_grey"
	item_state = "knight_grey"
	w_class = 4
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	slowdown = 0.1
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	flags = STOPSPRESSUREDMAGE | THICKMATERIAL | NODROP | DROPDEL
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	// TODO: work this out better - should be full protection, but damage the clothing - will have to override procs
	armor = list(melee = 40, bullet = 50, laser = 50, energy = 25, bomb = 50, bio = 100, rad = 50)

////////////////////////////////////////////////////////
// Grow Blade

/datum/action/generic/clothes_grow_blade
	name = "Grow blade"
	desc = "Grow a clothing blade"
	button_icon_state = "meson"
	procname = /mob/living/simple_animal/clothing/proc/grow_blade_action

/mob/living/simple_animal/clothing/proc/grow_blade_action()
	var/mob/living/carbon/human/host = getHost()

	if(!host)
		return

	if(!host.drop_item())
		host << "<span class='warning'>The [host.get_active_hand()] is stuck to your host's hand, you cannot grow a blade over it!</span>"
		return

/*
	var/limb_regen = 0
	if(host.hand) //we regen the arm before changing it into the weapon
		limb_regen = host.regenerate_limb("l_arm", 1)
	else
		limb_regen = host.regenerate_limb("r_arm", 1)
	if(limb_regen)
		host.visible_message("<span class='warning'>[host]'s missing arm reforms, making a loud, grotesque sound!</span>", "<span class='hostdanger'>Your arm regrows, making a loud, crunchy sound and giving you great pain!</span>", "<span class='italics'>You hear organic matter ripping and tearing!</span>")
		host.emote("scream")
*/
	var/obj/item/weapon/melee/arm_blade/clothing_arm_blade/W = new(host)
	host.put_in_hands(W)

	sparkle()

/obj/item/weapon/melee/arm_blade/clothing_arm_blade
	name = "arm blade"
	desc = "A shape blade made from living fiber."

////////////////////////////////////////////////////////
// Drink Blood

/mob/living/simple_animal/clothing/proc/drink_blood()
	var/mob/living/carbon/human/host = getHost()

	if(!host)
		return

	var/wanted_amount = 25

	if(host.transfer_blood_to(src, wanted_amount, 1) == 0)
		// I'd like to husk if you take all your host's blood, but that seems cruel.
		src << "You can't take any more blood!"
	else
		src << "You drink some blood!"
		host << "Your clothes drink some blood!"

	if(host.blood_volume < BLOOD_VOLUME_OKAY)
		if(host.stat == CONSCIOUS)
			src << "You can feel your host's knees buckle."
		else
			// Less flavourful, but eh.
			src << "Your host seems low on blood."

/mob/living/simple_animal/clothing/proc/drink_blood_action()
	drink_blood()

/datum/action/generic/clothes_drink_blood
	name = "Drink Blood"
	desc = "Drink the blood of your host"
	button_icon_state = "meson"
	procname = /mob/living/simple_animal/clothing/proc/drink_blood_action


////////////////////////////////////////////////////////
//Effects code

/mob/living/simple_animal/clothing/proc/transform_effect(var/mob/living/carbon/human/host, var/make_naked = 1)
	var/obj/effect/clothing_transformation/Z = new(get_turf(src.loc))
	Z.name = "transformation!"
	Z.desc = "Someone is transforming!"
	Z.setDir(host.dir)
	host.notransform = 1
	host.status_flags |= GODMODE

	// Make naked for maximum anime
	var/list/body_layers = list(MUTATIONS_LAYER,BODY_LAYER,DAMAGE_LAYER,UNIFORM_LAYER,ID_LAYER,SHOES_LAYER,GLOVES_LAYER,EARS_LAYER,SUIT_LAYER,GLASSES_LAYER,BELT_LAYER,SUIT_STORE_LAYER,BACK_LAYER,FACEMASK_LAYER,HANDCUFF_LAYER,LEGCUFF_LAYER,L_HAND_LAYER,R_HAND_LAYER)


	playsound(host, 'sound/effects/phasein.ogg', 30, 1)

	var/cached_overlays
	var/cached_overlays_standing

	if(make_naked)
		cached_overlays = host.overlays.Copy()
		cached_overlays_standing = host.overlays_standing.Copy()
		Z.alpha = 0
		for(var/layer in body_layers)
			host.remove_overlay(layer)
		animate(Z, alpha = 255, time=5)
		spawn(5)
			host.forceMove(Z)
			animate(Z, color="#0000ff", time=5)
	else
		host.forceMove(Z)
		animate(Z, color="#0000ff", time=10)

	spawn(10)
		host.status_flags &= ~GODMODE
		host.notransform = 0
		host.forceMove(get_turf(Z))
		host.visible_message("<span class='danger'>[host] transforms!</span>")
		Z.can_destroy = TRUE
		sparkle()
		if(make_naked)
			host.overlays = cached_overlays
			host.overlays_standing = cached_overlays_standing

		animate(Z, alpha = 0, time = 5, transform = matrix(0,0,0,0,1,0))
	//	spawn(5)
	//		qdel(Z)

/obj/effect/clothing_transformation
	icon_state = "blank"
	icon = 'icons/effects/effects.dmi'
	burn_state = LAVA_PROOF
	var/can_destroy = FALSE
	layer = ABOVE_MOB_LAYER
	color = "#ff0000"

/obj/effect/clothing_transformation/attackby()
	return

/obj/effect/clothing_transformation/ex_act()
	return

/obj/effect/clothing_transformation/singularity_pull()
	return 0

/obj/effect/clothing_transformation/Destroy(force)
	if(!can_destroy && !force)
		return QDEL_HINT_LETMELIVE
	else
		. = ..()


/mob/living/simple_animal/clothing/proc/sparkle()
	playsound(src, 'sound/magic/Blind.ogg', 30, 1)
	PoolOrNew(/obj/effect/overlay/temp/clothing_sparkles, get_turf(src))

/obj/effect/overlay/temp/clothing_sparkles
	name = "sparkles"
	icon_state = "ion_fade"
	duration = 16



////////////////////////////////////////////////////////
//HUD code

/mob/living/simple_animal/clothing/handle_stat_huds()
	if(hud_used.blooddisplay)
		// I guess hide this if we don't have a host.
		var/mob/living/carbon/human/host = getHost()
		if(host)
			var/host_blood = host.blood_volume
			hud_used.blooddisplay.maptext = "<div align='center' valign='center' style='position:relative; top:-6px; left:6px'> \
			<font color='#dd66dd'>[round(blood_volume)]</font><br /> \
			<font color='#dd6666'>[round(host_blood)]</font></div>"

/*
/mob/living/simple_animal/clothing/update_health_hud()
	var/mob/living/carbon/human/host = getHost()
	if(host)
		host.update_health_hud()
*/

/*
/mob/living/simple_animal/clothing/proc/transform_action()
	transform()

/datum/action/generic/clothes_transform
	name = "Transform"
	desc = "Do some transforming"
	button_icon_state = "meson"
	procname = /mob/living/simple_animal/clothing/proc/transform_action*/

