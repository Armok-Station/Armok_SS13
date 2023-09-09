
/obj/item/melee/sickly_blade
	name = "\improper sickly blade"
	desc = "A sickly green crescent blade, decorated with an ornamental eye. You feel like you're being watched..."
	icon = 'icons/obj/weapons/khopesh.dmi'
	icon_state = "eldritch_blade"
	inhand_icon_state = "eldritch_blade"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	flags_1 = CONDUCT_1
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_NORMAL
	force = 20
	throwforce = 10
	toolspeed = 0.375
	demolition_mod = 0.8
	hitsound = 'sound/weapons/bladeslice.ogg'
	armour_penetration = 35
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "rends")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "rend")
	var/after_use_message = ""

/obj/item/melee/sickly_blade/proc/check_usability(mob/living/user)
	return IS_HERETIC_OR_MONSTER(user)

/obj/item/melee/sickly_blade/attack(mob/living/M, mob/living/user)
	if(!check_usability(user))
		to_chat(user, span_danger("You feel a pulse of alien intellect lash out at your mind!"))
		var/mob/living/carbon/human/human_user = user
		human_user.AdjustParalyzed(5 SECONDS)
		return TRUE

	return ..()

/obj/item/melee/sickly_blade/attack_self(mob/user)
	var/turf/safe_turf = find_safe_turf(zlevels = z, extended_safety_checks = TRUE)
	if(check_usability(user))
		if(do_teleport(user, safe_turf, channel = TELEPORT_CHANNEL_MAGIC))
			to_chat(user, span_warning("As you shatter [src], you feel a gust of energy flow through your body. [after_use_message]"))
		else
			to_chat(user, span_warning("You shatter [src], but your plea goes unanswered."))
	else
		to_chat(user,span_warning("You shatter [src]."))
	playsound(src, SFX_SHATTER, 70, TRUE) //copied from the code for smashing a glass sheet onto the ground to turn it into a shard
	qdel(src)

/obj/item/melee/sickly_blade/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!isliving(target))
		return

	if(proximity_flag)
		SEND_SIGNAL(user, COMSIG_HERETIC_BLADE_ATTACK, target, src)
	else
		SEND_SIGNAL(user, COMSIG_HERETIC_RANGED_BLADE_ATTACK, target, src)

/obj/item/melee/sickly_blade/examine(mob/user)
	. = ..()
	if(!check_usability(user))
		return

	. += span_notice("You can shatter the blade to teleport to a random, (mostly) safe location by <b>activating it in-hand</b>.")

// Path of Rust's blade
/obj/item/melee/sickly_blade/rust
	name = "\improper rusted blade"
	desc = "This crescent blade is decrepit, wasting to rust. \
		Yet still it bites, ripping flesh and bone with jagged, rotten teeth."
	icon_state = "rust_blade"
	inhand_icon_state = "rust_blade"
	after_use_message = "The Rusted Hills hear your call..."

// Path of Ash's blade
/obj/item/melee/sickly_blade/ash
	name = "\improper ashen blade"
	desc = "Molten and unwrought, a hunk of metal warped to cinders and slag. \
		Unmade, it aspires to be more than it is, and shears soot-filled wounds with a blunt edge."
	icon_state = "ash_blade"
	inhand_icon_state = "ash_blade"
	after_use_message = "The Nightwatcher hears your call..."
	resistance_flags = FIRE_PROOF

// Path of Flesh's blade
/obj/item/melee/sickly_blade/flesh
	name = "\improper bloody blade"
	desc = "A crescent blade born from a fleshwarped creature. \
		Keenly aware, it seeks to spread to others the suffering it has endured from its dreadful origins."
	icon_state = "flesh_blade"
	inhand_icon_state = "flesh_blade"
	after_use_message = "The Marshal hears your call..."

// Path of Void's blade
/obj/item/melee/sickly_blade/void
	name = "\improper void blade"
	desc = "Devoid of any substance, this blade reflects nothingness. \
		It is a real depiction of purity, and chaos that ensues after its implementation."
	icon_state = "void_blade"
	inhand_icon_state = "void_blade"
	after_use_message = "The Aristocrat hears your call..."

// Path of the Blade's... blade.
// Opting for /dark instead of /blade to avoid "sickly_blade/blade".
/obj/item/melee/sickly_blade/dark
	name = "\improper sundered blade"
	desc = "A galliant blade, sundered and torn. \
		Furiously, the blade cuts. Silver scars bind it forever to its dark purpose."
	icon_state = "dark_blade"
	inhand_icon_state = "dark_blade"
	after_use_message = "The Torn Champion hears your call..."

// Path of Cosmos's blade
/obj/item/melee/sickly_blade/cosmic
	name = "\improper cosmic blade"
	desc = "A mote of celestial resonance, shaped into a star-woven blade. \
		An iridescent exile, carving radiant trails, desperately seeking unification."
	icon_state = "cosmic_blade"
	inhand_icon_state = "cosmic_blade"
	after_use_message = "The Stargazer hears your call..."

// Path of Nar'Sie's blade
// What!? This blade is given to cultists as a forge item when they sacrifice a heretic.
// It is also given to the heretic themself if they sacrifice a cultist.
/obj/item/melee/sickly_blade/cursed
	name = "\improper cursed blade"
	desc = "A dark blade, cursed to bleed forever. In constant struggle between the eldritch and the dark, it is forced to accept any wielder as its master. \
		Its eye's cornea flickers between bloody red and sickly green, yet its piercing gaze remains on you."
	force = 25
	throwforce = 15
	block_chance = 35
	wound_bonus = 25
	bare_wound_bonus = 15
	armour_penetration = 35
	icon_state = "cursed_blade"
	inhand_icon_state = "cursed_blade"

/obj/item/melee/sickly_blade/cursed/Initialize(mapload)
	. = ..()

	var/examine_text = {"Allows the scribing of blood runes of the cult of Nar'Sie.
	The combination of eldritch power and Nar'Sie's might allows for vastly increased rune drawing speed,
	alongside the vicious strength of the blade being more powerful than usual. It can also be shattered in-hand by cultists, teleporting them to relative safety."}

	AddComponent(/datum/component/cult_ritual_item, span_cult(examine_text), turfs_that_boost_us = /turf) // Always fast to draw!

/obj/item/melee/sickly_blade/cursed/check_usability(mob/living/user)
	if(IS_HERETIC_OR_MONSTER(user) || IS_CULTIST(user))
		return TRUE
	var/mob/living/carbon/human/human_user = user
	if(prob(50))
		to_chat(user, span_cultlarge(pick("\"An untouched mind? Amusing.\"", "\" I suppose it isn't worth the effort to stop you.\"", "\"Go ahead. I don't care.\", \"You'll be mine soon enough.\"")))
	else
		to_chat(user, span_big(span_hypnophrase("LW'NAFH'NAHOR UH'ENAH'YMG EPGOKA AH NAFL MGEMPGAH'EHYE")))
		to_chat(user, span_danger("Horrible, unintelligible utterances flood your mind!"))
		human_user.adjustOrganLoss(ORGAN_SLOT_BRAIN, 25)
	return TRUE

/obj/item/melee/sickly_blade/cursed/equipped(mob/user, slot)
	. = ..()
	if(ISHERETIC(user))
		after_use_message = "The Mansus hears your call..."
	else if(ISCULTIST(user))
		after_use_message = "Nar'Sie hears your call..."
