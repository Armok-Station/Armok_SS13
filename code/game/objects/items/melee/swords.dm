/obj/item/melee/sword
	name = "broadsword"
	desc = "A sharp steel forged sword. It's fine edge shines in the light."
	icon = 'icons/obj/weapons/sword.dmi'
	icon_state = "broadsword"
	inhand_icon_state = "broadsword"
	worn_icon_state = "broadsword"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	force = 20
	throwforce = 10
	wound_bonus = 5
	throw_range = 4
	w_class = WEIGHT_CLASS_BULKY
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	block_chance = 30
	block_sound = 'sound/weapons/parry.ogg'
	sharpness = SHARP_EDGED
	max_integrity = 200
	armor_type = /datum/armor/item_claymore
	resistance_flags = FIRE_PROOF
	embedding = list("embed_chance" = 20, "impact_pain_mult" = 10) //It's a sword, thrown swords can stick into people.

/obj/item/melee/sword/Initialize(mapload)
	. = ..()
	AddComponent( \
		/datum/component/butchering, \
		speed = 8 SECONDS, \
		effectiveness = 105, \
	)
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/melee/sword/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is falling on [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return BRUTELOSS

/obj/item/melee/sword/on_exit_storage(datum/storage/container)
	var/obj/item/storage/belt/sheath/sword = container.real_location?.resolve()
	if(istype(sword))
		playsound(sword, 'sound/items/unsheath.ogg', 25, TRUE)

/obj/item/melee/sword/gold
	name = "gilded broadsword"
	desc = "A sharp steel forged sword. It's got a rich guard and pommel. It's fine edge shines in the light."
	icon_state = "broadsword_gold"
	inhand_icon_state = "broadsword_gold"
	worn_icon_state = "broadsword_gold"

/obj/item/melee/sword/rust
	name = "rusty broadsword"
	desc = "A sharp steel forged sword. It's edge is rusty and corroded."
	icon_state = "broadsword_rust"
	worn_icon_state = "broadsword"
	force = 15
	wound_bonus = 0
	var/broken_icon = "broadsword_broken"

	/// How many hits a sword can deal and block before it breaks, with one additional final attack.
	var/rustiness = 15 // It may say 15, but it's 16 hits/blocks before it breaks.
	/// If the sword is broken or not.
	var/broken = FALSE

/obj/item/melee/sword/rust/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(broken)
		return
	if(ismovable(target))
		decrease_uses(user)

/obj/item/melee/sword/rust/hit_reaction(mob/user)
	. = ..()
	if(!.)
		return
	if(broken)
		return 
	decrease_uses(user)

/obj/item/melee/sword/rust/proc/decrease_uses(mob/user)
	if(rustiness == 0)
		no_uses(user)
		return
	rustiness--

/obj/item/melee/sword/rust/proc/no_uses(mob/user)
	if(broken == TRUE)
		return
	user.visible_message(span_notice("[user]'s sword snaps in half."), span_notice("[src]'s blade breaks leaving you with half a sword!"))
	broken = TRUE
	name = "broken [initial(name)]"
	icon_state = broken_icon
	inhand_icon_state = broken_icon
	worn_icon_state = broken_icon
	update_appearance()
	playsound(user, 'sound/effects/structure_stress/pop3.ogg', 100, TRUE)
	force -= 5
	wound_bonus = 1
	throw_range = 2
	embedding = list("embed_chance" = 10, "impact_pain_mult" = 15)//jagged metal in wound would be more painful.
	block_chance = 20
	w_class = WEIGHT_CLASS_SMALL

/obj/item/melee/sword/rust/gold
	name = "rusty gilded broadsword"
	desc = "A sharp steel forged sword. It's got a rich guard and pommel. It's edge is rusty and corroded."
	icon_state = "broadsword_gold_rust"
	inhand_icon_state = "broadsword_gold"
	worn_icon_state = "broadsword_gold"
	broken_icon = "broadsword_gold_broken"

/obj/item/melee/sword/rust/claymore
	name = "rusty claymore"
	desc = "A rusted claymore, it smells damp and it has seen better days."
	icon_state = "claymore_rust"
	inhand_icon_state = "claymore"
	worn_icon_state = "claymore"
	broken_icon = "claymore_broken"

/obj/item/melee/sword/rust/claymoregold
	name = "rusty holy claymore"
	desc = "A weapon fit for a crusade... or it used to be..."
	icon_state = "claymore_gold_rust"
	inhand_icon_state = "claymore_gold"
	worn_icon_state = "claymore_gold"
	broken_icon = "claymore_gold_broken"

/obj/item/melee/sword/rust/cultblade
	name = "rusty dark blade"
	desc = "Once used by worshipers of forbidden gods, now its covered in old rust."
	icon_state = "cultblade_rust"
	inhand_icon_state = "cultblade_rust"
	broken_icon = "cultblade_broken"

/obj/item/melee/sword/claymore
	name = "holy claymore"
	desc = "A weapon fit for a crusade! It lacks a holy shine however."
	force = 18
	icon_state = "claymore_gold"
	inhand_icon_state = "claymore_gold"
	worn_icon_state = "claymore_gold"

/obj/item/melee/sword/claymore/darkblade
	name = "dark blade"
	desc = "Spread the glory of the dark gods! Even if they don't bless this blade."
	icon_state = "cultblade"
	inhand_icon_state = "cultblade"
	worn_icon_state = "cultblade"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64

/obj/item/melee/sword/reforged
	name = "Reforged longsword"
	desc = "A hard steel blade, it's edge has been forged to be incredibly strong. It feels light."
	icon_state = "reforged"
	inhand_icon_state = "reforged"
	worn_icon_state = "reforged"
	force = 25
	throwforce = 15
	throw_range = 6
	block_chance = 40
	wound_bonus = 5
	armour_penetration = 15
	embedding = list("embed_chance" = 30, "impact_pain_mult" = 10)

/obj/item/melee/sword/reforged/shitty
	var/broken = FALSE
	var/rustiness = 0 //This isn't a mistake, this causes it to break instantly upon use.
	var/broken_icon = "reforged_broken"

/obj/item/melee/sword/reforged/shitty/afterattack(target, mob/user, proximity_flag)
	. = ..()
	if(broken)
		return ..()
	if(ismovable(target))
		decrease_uses(user)

/obj/item/melee/sword/reforged/shitty/hit_reaction(mob/user)
	. = ..()
	if(broken)
		return ..()
	if(!.)
		return
	decrease_uses(user)

/obj/item/melee/sword/reforged/shitty/proc/decrease_uses(mob/user)
	if(rustiness == 0)
		no_uses(user)
		return
	rustiness--

/obj/item/melee/sword/reforged/shitty/proc/no_uses(mob/user)
	if(broken == TRUE)
		return
	user.visible_message(span_notice("[user]'s sword breaks. WHAT AN IDIOT!"), span_notice("The [src]'s blade shatters! It was a cheap felinid imitation! WHAT A PIECE OF SHIT!"))
	broken = TRUE
	name = "broken fake longsword"
	desc = "A cheap piece of felinid forged trash."
	icon_state = broken_icon
	inhand_icon_state = broken_icon
	worn_icon_state = broken_icon
	update_appearance()
	playsound(user, 'sound/effects/glassbr1.ogg', 100, TRUE)
	force -= 20
	throwforce = 5
	throw_range = 1
	block_chance = 5
	wound_bonus = -10
	armour_penetration = 0
	embedding = list("embed_chance" = 5, "impact_pain_mult" = 5)
	w_class = WEIGHT_CLASS_SMALL

/obj/item/storage/belt/sheath
	name = "sword sheath"
	desc = "A leather sheath meant to hold a variety of swords."
	icon_state = "sheath_plain"
	inhand_icon_state = "sheath_plain"
	worn_icon_state = "sheath_plain"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/sheath/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

	atom_storage.max_slots = 1
	atom_storage.rustle_sound = FALSE
	atom_storage.max_specific_storage = WEIGHT_CLASS_BULKY
	atom_storage.set_holdable(
		list(
			/obj/item/melee/sword,
			/obj/item/melee/sword/gold,
			/obj/item/melee/sword/rust,
			/obj/item/melee/sword/rust/gold,
			/obj/item/melee/sword/rust/claymore,
			/obj/item/melee/sword/rust/claymoregold,
			/obj/item/melee/sword/rust/cultblade,
			/obj/item/claymore,
			/obj/item/claymore/weak,
			/obj/item/claymore/weak/ceremonial,
			/obj/item/nullrod/claymore,
			/obj/item/nullrod/claymore/glowing,
			/obj/item/nullrod/claymore/darkblade,
			/obj/item/melee/sword/claymore,
			/obj/item/melee/sword/claymore/darkblade,
			/obj/item/melee/cultblade,
			/obj/item/melee/sword/reforged,
			/obj/item/melee/sword/reforged/shitty,
			/obj/item/melee/moonlight_greatsword,
		), generate_can_hold_subtypes = FALSE
	)

/obj/item/storage/belt/sheath/examine(mob/user)
	. = ..()
	if(length(contents))
		. += span_notice("Alt-click it to quickly draw the blade.")

/obj/item/storage/belt/sheath/AltClick(mob/user)
	if(!user.can_perform_action(src, NEED_DEXTERITY|NEED_HANDS))
		return
	if(length(contents))
		var/obj/item/I = contents[1]
		user.visible_message(span_notice("[user] takes [I] out of [src]."), span_notice("You take [I] out of [src]."))
		user.put_in_hands(I)
		update_appearance()
	else
		balloon_alert(user, "it's empty!")

/obj/item/storage/belt/sheath/update_icon_state()
	icon_state = initial(inhand_icon_state)
	inhand_icon_state = initial(inhand_icon_state)
	worn_icon_state = initial(worn_icon_state)
	if(contents.len)
		icon_state += "-sword"
		inhand_icon_state += "-sword"
		worn_icon_state += "-sword"
	return ..()

/obj/item/storage/belt/sheath/full
	var/swordtype = list(/obj/item/melee/sword = 20,
		/obj/item/melee/sword/gold = 20,
		/obj/item/melee/sword/rust = 160,
		/obj/item/melee/sword/rust/gold = 160,
		/obj/item/melee/sword/rust/claymore = 160,
		/obj/item/melee/sword/rust/claymoregold = 160,
		/obj/item/melee/sword/rust/cultblade = 160,
		/obj/item/claymore/weak/ceremonial = 60,
		/obj/item/melee/sword/claymore = 40,
		/obj/item/melee/sword/claymore/darkblade = 40,
		/obj/item/melee/sword/reforged = 9,
		/obj/item/melee/sword/reforged/shitty = 1,)

/obj/item/storage/belt/sheath/full/PopulateContents()
	var/typepath = pick_weight(swordtype)
	new typepath(src)
	update_appearance()
