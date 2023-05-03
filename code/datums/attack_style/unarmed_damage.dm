/**
 * Unarmed attacks which generically apply damage to the mob it hits.
 */
/datum/attack_style/unarmed/generic_damage
	pacifism_completely_banned = TRUE // It's called generic damage for a reason

	/// Type damage this attack does.
	var/attack_type = BRUTE
	/// The verb used for an unarmed attack when using this limb, "punch".
	var/unarmed_attack_verb = "bump"

	var/deaf_miss_phrase = "a swoosh"
	/// Lowest possible punch damage this bodypart can give. If this is set to 0, unarmed attacks will always miss.
	var/unarmed_damage_low = 1
	/// Highest possible punch damage this bodypart can give.
	var/unarmed_damage_high = 1
	/// Damage at which attacks from this bodypart will stun.
	/// If negative, we will never stun. Likewise if 0, we will always stun.
	var/unarmed_stun_threshold = 2
	/// Wound bonus on attacks
	var/wound_bonus = 0
	/// Armor penetration from the attack
	var/attack_penetration = 0
	/// Amount of bonus stamina damage to apply in addition to the main attack type
	var/bonus_stamina_damage_modifier = 1.5

	var/miss_chance_modifier = 0

/datum/attack_style/unarmed/generic_damage/proc/select_damage(mob/living/attacker, mob/living/smacked)
	return rand(unarmed_damage_low, unarmed_damage_high)

/datum/attack_style/unarmed/generic_damage/finalize_attack(mob/living/attacker, mob/living/smacked, obj/item/weapon, right_clicking)
	var/damage = select_damage(attacker, smacked)
	if(smacked.check_block(attacker, damage, "[attacker]'s [unarmed_attack_verb]", UNARMED_ATTACK, attack_penetration))
		smacked.visible_message(
			span_warning("[smacked] blocks [attacker]'s [unarmed_attack_verb]!"),
			span_userdanger("You block [attacker]'s [unarmed_attack_verb]!"),
			span_hear("You hear [deaf_miss_phrase]!"),
			vision_distance = COMBAT_MESSAGE_RANGE,
			ignored_mobs = attacker,
		)
		to_chat(attacker, span_warning("[smacked] blocks your [unarmed_attack_verb]!"))
		return ATTACK_STYLE_BLOCKED

	// Todo : move this out and into its own style?
	if(!HAS_TRAIT(smacked, TRAIT_MARTIAL_ARTS_IMMUNE))
		var/datum/martial_art/art = attacker.mind?.martial_art
		switch(art?.harm_act(attacker, smacked))
			if(MARTIAL_ATTACK_SUCCESS)
				return ATTACK_STYLE_HIT
			if(MARTIAL_ATTACK_FAIL)
				return ATTACK_STYLE_MISSED

	var/obj/item/bodypart/affecting = smacked.get_bodypart(smacked.get_random_valid_zone(attacker.zone_selected))

	// calculate the odds that a punch misses entirely.
	// considers stamina and brute damage of the puncher.
	// punches miss by default to prevent weird cases
	var/miss_chance = 100
	if(unarmed_damage_low)
		if((smacked.body_position == LYING_DOWN) || HAS_TRAIT(attacker, TRAIT_PERFECT_ATTACKER))
			miss_chance = 0
		else
			miss_chance = (unarmed_damage_high / unarmed_damage_low) + attacker.getStaminaLoss() + (attacker.getBruteLoss() * 0.5) + miss_chance_modifier

	if(damage <= 0 || !istype(affecting) || prob(miss_chance))
		smacked.visible_message(
			span_danger("[attacker]'s [unarmed_attack_verb] misses [smacked]!"),
			span_danger("You avoid [attacker]'s [unarmed_attack_verb]!"),
			span_hear("You hear [deaf_miss_phrase]!"),
			vision_distance = COMBAT_MESSAGE_RANGE,
			ignored_mobs = attacker,
		)
		to_chat(attacker, span_warning("Your [unarmed_attack_verb] misses [smacked]!"))
		log_combat(attacker, smacked, "missed unarmed attack ([unarmed_attack_verb])")
		return ATTACK_STYLE_MISSED

	var/armor_block = min(ARMOR_MAX_BLOCK, smacked.run_armor_check(affecting, MELEE, armour_penetration = attack_penetration))

	smacked.visible_message(
		span_danger("[attacker] [unarmed_attack_verb]ed [smacked]!"),
		span_userdanger("You're [unarmed_attack_verb]ed by [attacker]!"),
		span_hear("You hear a sickening sound of flesh hitting flesh!"),
		vision_distance = COMBAT_MESSAGE_RANGE,
		ignored_mobs = attacker,
	)
	to_chat(attacker, span_danger("You [unarmed_attack_verb] [smacked]!"))

	smacked.lastattacker = attacker.real_name
	smacked.lastattackerckey = attacker.ckey

	actually_apply_damage(attacker, smacked, damage, affecting, armor_block)

	var/additional_logging = "([unarmed_attack_verb])"
	if(damage >= 9 && ishuman(smacked))
		var/mob/living/carbon/human/human_smacked = smacked
		human_smacked.force_say()
		additional_logging += "(causing forced say)"
		if(human_smacked.wear_suit)
			human_smacked.wear_suit.add_fingerprint(attacker)
		else if(human_smacked.w_uniform)
			human_smacked.w_uniform.add_fingerprint(attacker)

	if(smacked.stat != DEAD && unarmed_stun_threshold >= 0 && damage >= unarmed_stun_threshold)
		smacked.visible_message(
			span_danger("[attacker] knocks [smacked] down!"),
			span_userdanger("You're knocked down by [attacker]!"),
			span_hear("You hear aggressive shuffling followed by a loud thud!"),
			vision_distance = COMBAT_MESSAGE_RANGE,
			ignored_mobs = attacker,
		)
		to_chat(attacker, span_danger("You knock [smacked] down!"))
		var/knockdown_duration = (4 SECONDS) + (smacked.getStaminaLoss() + (smacked.getBruteLoss() * 0.5)) * 0.8
		smacked.apply_effect(knockdown_duration, EFFECT_KNOCKDOWN, armor_block)
		additional_logging += "(stun attack)"

	log_combat(attacker, smacked, "unarmed attack", addition = additional_logging)
	return ATTACK_STYLE_HIT

/// Called when the damage actually is being applied to the smacked mob
/datum/attack_style/unarmed/generic_damage/proc/actually_apply_damage(mob/living/attacker, mob/living/smacked, damage, affecting, armor_block)
	var/direction = get_dir(attacker, smacked)
	smacked.apply_damage(damage, attack_type, affecting, armor_block, wound_bonus = wound_bonus, attack_direction = direction)
	if(bonus_stamina_damage_modifier > 0)
		smacked.apply_damage(damage * bonus_stamina_damage_modifier, attack_type, affecting, armor_block, attack_direction = direction)

/datum/attack_style/unarmed/generic_damage/punch
	unarmed_attack_verb = "punch" // The classic punch, wonderfully classic and completely random
	unarmed_damage_low = 1
	unarmed_damage_high = 10
	unarmed_stun_threshold = 10

/datum/attack_style/unarmed/generic_damage/punch/monkey
	unarmed_damage_low = 1 // Monkey punches are weak, they opt to bite instead
	unarmed_damage_high = 2
	unarmed_stun_threshold = 3

/datum/attack_style/unarmed/generic_damage/punch/ethereal
	successful_hit_sound = 'sound/weapons/etherealhit.ogg'
	miss_sound = 'sound/weapons/etherealmiss.ogg'
	attack_type = BURN // bish buzz
	unarmed_attack_verb = "burn"

/datum/attack_style/unarmed/generic_damage/punch/claw
	successful_hit_sound = 'sound/weapons/slash.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	attack_effect = ATTACK_EFFECT_CLAW
	unarmed_attack_verb = "slash"

/datum/attack_style/unarmed/generic_damage/punch/mushroom
	unarmed_damage_low = 6
	unarmed_damage_high = 14
	unarmed_stun_threshold = 14

/datum/attack_style/unarmed/generic_damage/snail
	attack_effect = ATTACK_EFFECT_DISARM
	unarmed_attack_verb = "slap"
	unarmed_damage_low = 0.2
	unarmed_damage_high = 0.5 //snails are soft and squishy
	unarmed_stun_threshold = 8

/datum/attack_style/unarmed/generic_damage/bite
	successful_hit_sound = 'sound/weapons/bite.ogg'
	miss_sound = 'sound/weapons/bite.ogg'
	attack_effect = ATTACK_EFFECT_BITE
	unarmed_attack_verb = "bite"
	deaf_miss_phrase = "jaws snapping shut"
	unarmed_damage_low = 1 // Yeah, biting is pretty weak, blame the monkey super-nerf
	unarmed_damage_high = 3
	unarmed_stun_threshold = 4
	miss_chance_modifier = 25

	/// Having less armor than this on the hit bodypart will result in diseases being spread by the attacker.
	var/disease_armor_thresold = 2

/datum/attack_style/unarmed/generic_damage/bite/execute_attack(mob/living/attacker, obj/item/weapon, list/turf/affecting, atom/priority_target, right_clicking)
	if(attacker.is_muzzled() || attacker.is_mouth_covered(ITEM_SLOT_MASK))
		attacker.balloon_alert(attacker, "mouth covered, can't bite!")
		return FALSE

	return ..()

/datum/attack_style/unarmed/generic_damage/bite/actually_apply_damage(mob/living/attacker, mob/living/smacked, damage, affecting, armor)
	. = ..()
	if(armor >= disease_armor_thresold)
		return
	if(!smacked.try_inject(attacker, affecting))
		return

	for(var/datum/disease/bite_infection as anything in attacker.diseases)
		if(bite_infection.spread_flags & (DISEASE_SPREAD_SPECIAL|DISEASE_SPREAD_NON_CONTAGIOUS))
			continue // ignore diseases that have special spread logic, or are not contagious
		smacked.ForceContractDisease(bite_infection)

/datum/attack_style/unarmed/generic_damage/bite/larva
	miss_chance_modifier = 10

/datum/attack_style/unarmed/generic_damage/bite/larva/actually_apply_damage(mob/living/carbon/alien/larva/attacker, mob/living/smacked, damage, affecting, armor)
	. = ..()
	attacker.amount_grown = min(attacker.amount_grown + damage, attacker.max_grown)

/datum/attack_style/unarmed/generic_damage/hulk
	unarmed_damage_low = 12
	unarmed_damage_high = 15
	unarmed_stun_threshold = 0
	wound_bonus = 10
	unarmed_attack_verb = "smash"

/datum/attack_style/unarmed/generic_damage/hulk/finalize_attack(mob/living/attacker, mob/living/smacked, obj/item/weapon, right_clicking)
	// Me hulk, me mutate global singleton, me no care
	unarmed_attack_verb = pick("smash", "pummel", "slam")
	. = ..()
	if(. & ATTACK_STYLE_HIT)
		smacked.hulk_smashed(attacker)

/datum/attack_style/unarmed/generic_damage/kick
	attack_effect = ATTACK_EFFECT_KICK
	unarmed_attack_verb = "kick" // The lovely kick, typically only accessable by attacking a grouded foe. 1.5 times better than the punch.
	unarmed_damage_low = 2
	unarmed_damage_high = 15
	unarmed_stun_threshold = 10
	bonus_stamina_damage_modifier = 0

/datum/attack_style/unarmed/generic_damage/kick/monkey
	unarmed_damage_low = 2
	unarmed_damage_high = 3
	unarmed_stun_threshold = 4

/datum/attack_style/unarmed/generic_damage/kick/leg_day
	unarmed_damage_low = 30
	unarmed_damage_low = 50

/datum/attack_style/unarmed/generic_damage/kick/mushroom
	unarmed_damage_low = 9
	unarmed_damage_high = 21
	unarmed_stun_threshold = 14

/datum/attack_style/unarmed/generic_damage/mob_attack
	unarmed_stun_threshold = -1

/datum/attack_style/unarmed/generic_damage/mob_attack/select_damage(mob/living/attacker, mob/living/smacked)
	return rand(attacker.melee_damage_lower, attacker.melee_damage_upper)

/datum/attack_style/unarmed/generic_damage/mob_attack/attack_effect_animation(mob/living/attacker, obj/item/weapon, list/turf/affecting)
	if(isanimal(attacker))
		var/mob/living/simple_animal/animal = attacker
		if(animal.attack_vis_effect)
			attacker.do_attack_animation(affecting[1], animal.attack_vis_effect)

	if(isbasicmob(attacker))
		var/mob/living/basic/animal = attacker
		if(animal.attack_vis_effect)
			attacker.do_attack_animation(affecting[1], animal.attack_vis_effect)

/datum/attack_style/unarmed/generic_damage/mob_attack/xeno
	successful_hit_sound = 'sound/weapons/slice.ogg'
	miss_sound = 'sound/weapons/slashmiss.ogg'
	unarmed_attack_verb = "slash"
	miss_chance_modifier = 10

/datum/attack_style/unarmed/generic_damage/mob_attack/xeno/select_damage(mob/living/attacker, mob/living/smacked)
	if(isalien(smacked))
		return 1
	return ..()
