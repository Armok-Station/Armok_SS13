/**
 * Unarmed attacks which generically apply damage to the mob it hits.
 */
/datum/attack_style/unarmed/generic_damage
	slowdown = 0.2
	can_hit_self = TRUE
	/// Type damage this attack does. If null, uses the attacker's [get_attack_type]/
	var/attack_type
	/// The verb used for an unarmed attack when using this limb, "punch".
	var/default_attack_verb = "bump"
	/// For deaf people, when this attack misses, this is the phrase used. Yeah pretty niche var.
	var/deaf_miss_phrase = "a swoosh"
	/// Flat added modifier to miss chance. Negative means more likely to hit.
	var/miss_chance_modifier = 0
	/// Wound bonus on attacks from this attack method
	var/wound_bonus_modifier = 0
	/// Bare wound bonus on attacks from this attack method
	var/bare_wound_bonus_modifier = 0
	/// Armor penetration from this attack method
	var/attack_penetration_modifier = 0
	/// If TRUE, attacks on limbs which are at max damage will be dismembered
	var/can_dismember_limbs = FALSE

/datum/attack_style/unarmed/generic_damage/collide_with_solid_atom(atom/blocking_us, obj/item/weapon, mob/living/attacker)
	attacker.resolve_unarmed_attack(blocking_us)
	return ATTACK_SWING_BLOCKED

/datum/attack_style/unarmed/generic_damage/check_pacifism(mob/living/attacker, obj/item/weapon, right_clicking)
	return TRUE

/// Gets how much damage this attack will actually end up doing.
/datum/attack_style/unarmed/generic_damage/proc/select_damage(mob/living/attacker, mob/living/smacked, obj/item/bodypart/hitting_with)
	return -1

/// Selects which verb to use for the feedback visible message component of the attack.
/datum/attack_style/unarmed/generic_damage/proc/select_attack_verb(mob/living/attacker, mob/living/smacked, obj/item/bodypart/hitting_with, damage)
	if(damage == 0 && attacker.friendly_verb_simple)
		return attacker.friendly_verb_simple

	if(smacked.response_harm_simple)
		return smacked.response_harm_simple
	if(attacker.attack_verb_simple)
		return attacker.attack_verb_simple

	return default_attack_verb

/// Calculates the probability (out of 100) that this attack will miss.
/datum/attack_style/unarmed/generic_damage/proc/calculate_miss_chance(mob/living/attacker, mob/living/smacked, obj/item/bodypart/hitting_with, damage)
	if(smacked.body_position == LYING_DOWN || HAS_TRAIT(attacker, TRAIT_PERFECT_ATTACKER))
		// Guarantee this shit hits no matter what gets added on
		return -INFINITY

	return miss_chance_modifier

/datum/attack_style/unarmed/generic_damage/finalize_attack(mob/living/attacker, mob/living/smacked, obj/item/bodypart/weapon, right_clicking)
	var/damage = max(0, select_damage(attacker, smacked, weapon))
	var/attack_verb = select_attack_verb(attacker, smacked, weapon, damage)
	var/damage_type = attack_type || attacker.get_attack_type()

	if(smacked.check_block(attacker, damage, "[attacker]'s [default_attack_verb]", UNARMED_ATTACK, attack_penetration_modifier, damage_type, MELEE))
		return ATTACK_SWING_BLOCKED

	// Todo : move this out and into its own style?
	if(!HAS_TRAIT(smacked, TRAIT_MARTIAL_ARTS_IMMUNE) && martial_arts_compatible)
		var/datum/martial_art/art = attacker.mind?.martial_art
		switch(art?.harm_act(attacker, smacked))
			if(MARTIAL_ATTACK_SUCCESS)
				return ATTACK_SWING_HIT
			if(MARTIAL_ATTACK_FAIL)
				return ATTACK_SWING_MISSED

	var/obj/item/bodypart/affecting = smacked.get_bodypart(smacked.get_random_valid_zone(attacker.zone_selected))
	var/miss_chance = calculate_miss_chance(attacker, smacked, weapon, damage)

d	if(damage <= 0 || (iscarbon(smacked) && !istype(affecting)) || prob(miss_chance))
		smacked.visible_message(
			span_danger("[attacker]'s [attack_verb] misses [smacked]!"),
			span_danger("You avoid [attacker]'s [attack_verb]!"),
			span_hear("You hear [deaf_miss_phrase]!"),
			vision_distance = COMBAT_MESSAGE_RANGE,
			ignored_mobs = attacker,
		)
		to_chat(attacker, span_warning("Your [attack_verb] misses [smacked]!"))
		log_combat(attacker, smacked, "missed unarmed attack ([attack_verb])")
		return ATTACK_SWING_MISSED

	// All unarmed attacks go under melee armor, even ones that use non-standard damage types like burn
	var/armor_block = min(ARMOR_MAX_BLOCK, smacked.run_armor_check(affecting, MELEE, armour_penetration = attack_penetration_modifier))

	// melbert todo : probably sounds silly
	smacked.visible_message(
		span_danger("[attacker] [attack_verb]ed [smacked]!"),
		span_userdanger("You're [attack_verb]ed by [attacker]!"),
		span_hear("You hear a sickening sound of flesh hitting flesh!"),
		vision_distance = COMBAT_MESSAGE_RANGE,
		ignored_mobs = attacker,
	)
	to_chat(attacker, span_danger("You [default_attack_verb] [smacked]!"))

	UPDATE_LAST_ATTACKER(smacked, attacker)

	// A damage packet is created to pass onto [actually_apply_damage].
	// This allows for subtypes to overide certain facets of the outgoing damage if they prefer.
	var/datum/apply_damage_packet/packet = new(
		/* damage = */damage,
		/* damagetype = */damage_type,
		/* def_zone = */affecting,
		/* blocked = */armor_block,
		/* forced = */FALSE,
		/* spread_damage = */FALSE,
		/* wound_bonus = */wound_bonus_modifier,
		/* bare_wound_bonus = */bare_wound_bonus_modifier,
		/* sharpness = */NONE,
		/* attack_direction = */get_dir(attacker, smacked),
		/* attacking_item = */null,
	)

	var/additional_logging = "([default_attack_verb])"
	var/logging_returned = actually_apply_damage(attacker, smacked, weapon, affecting, packet)
	if(logging_returned)
		additional_logging += logging_returned

	if(QDELETED(affecting) || affecting.owner != smacked)
		// Our attack ended up dismembering / removing the limb, so let's just null this out
		affecting = null

	smacked.was_attacked_effects(null, attacker, affecting, damage, armor_block)
	log_combat(attacker, smacked, "unarmed attack", addition = additional_logging)
	return ATTACK_SWING_HIT

/**
 * Called when the damage actually is being applied to the smacked mob
 *
 * Arguments
 * * attacker - The mob that is attacking
 * * smacked - The mob that is being attacked
 * * hitting_with - The bodypart that is being used to attack. CAN BE NULL, if this unarmed attack is created without bodypart (such as simplemob attacks)
 * * affecting - The bodypart being hit by the attack
 * * packet - A [/datum/apply_damage_packet] that contains all the information about the damage being applied.
 * Passed this way so one can either modify or use the arguments being passed before they're sent.
 *
 * Returns a string.
 * This string will be added to the final combat log for this attack.
 */
/datum/attack_style/unarmed/generic_damage/proc/actually_apply_damage(
	mob/living/attacker,
	mob/living/smacked,
	obj/item/bodypart/hitting_with,
	obj/item/bodypart/affecting,
	datum/apply_damage_packet/packet,
)
	SHOULD_CALL_PARENT(TRUE)

	var/returned_logging = ""
	packet.execute(smacked)
	if(can_dismember_limbs && istype(affecting) && (affecting.get_damage() >= affecting.max_damage))
		if(affecting.dismember(packet.damagetype, silent = FALSE))
			returned_logging += "(dismembering [parse_zone(affecting.body_zone)])"

	return returned_logging

/*
 * Limb attack unarmed style
 *
 * This style deals damage / uses verbs and effects based on the limb being used to attack
 */
/datum/attack_style/unarmed/generic_damage/limb_based

/datum/attack_style/unarmed/generic_damage/limb_based/select_damage(mob/living/attacker, mob/living/smacked, obj/item/bodypart/hitting_with)
	. = rand(hitting_with.unarmed_damage_low, hitting_with.unarmed_damage_high)
	if(attacker != hitting_with.owner)
		. *= 0.5 // Damage penalty for using a limb as a melee weapon
	if(isbasicmob(smacked))
		var/mob/living/basic/smacked_basic = smacked
		if(smacked_basic.basic_mob_flags & IMMUNE_TO_FISTS)
			. *= 0

/datum/attack_style/unarmed/generic_damage/limb_based/calculate_miss_chance(mob/living/attacker, mob/living/smacked, obj/item/bodypart/hitting_with, damage)
	// 0 damage is a guaranteed miss
	if(hitting_with.unarmed_damage_low <= 0 || hitting_with.unarmed_damage_high <= 0)
		return 100

	// Get base miss chance modifier (from parent)
	. = ..()
	// Adds a chance of missing based on the damage range of the limb...
	. += (hitting_with.unarmed_damage_high / hitting_with.unarmed_damage_low)
	// Adds some chance of missing if the attacker is wounded...
	. += (attacker.getBruteLoss() * 0.5)
	// And also adds some chance of missing if the attacker is worn out
	. += (attacker.getStaminaLoss())

	return .

/datum/attack_style/unarmed/generic_damage/limb_based/actually_apply_damage(
	mob/living/attacker,
	mob/living/smacked,
	obj/item/bodypart/hitting_with,
	obj/item/bodypart/affecting,
	datum/apply_damage_packet/packet,
)
	. = ..()
	if(smacked.stat == DEAD || smacked.check_stun_immunity(CANKNOCKDOWN) || smacked.body_position == LYING_DOWN)
		return
	if(hitting_with.unarmed_stun_threshold < 0 || packet.damage < hitting_with.unarmed_stun_threshold)
		return

	smacked.visible_message(
		span_danger("[attacker] knocks [smacked] down!"),
		span_userdanger("You're knocked down by [attacker]!"),
		span_hear("You hear aggressive shuffling followed by a loud thud!"),
		vision_distance = COMBAT_MESSAGE_RANGE,
		ignored_mobs = attacker,
	)
	to_chat(attacker, span_danger("You knock [smacked] down!"))
	var/knockdown_duration = (4 SECONDS) + (smacked.getStaminaLoss() + (smacked.getBruteLoss() * 0.5)) * 0.8
	smacked.apply_effect(knockdown_duration, EFFECT_KNOCKDOWN, packet.blocked)
	. += "(knockdown attack, [DisplayTimeText(knockdown_duration)] duration)"

/**
 * Mob attack unarmed style
 *
 * This style deals damage / uses verbs based on the mob's vars,
 * generally for use in simple / basic mobs
 */
/datum/attack_style/unarmed/generic_damage/mob_attack

/datum/attack_style/unarmed/generic_damage/mob_attack/select_damage(mob/living/attacker, mob/living/smacked, obj/item/bodypart/weapon)
	return rand(attacker.melee_damage_lower, attacker.melee_damage_upper)

/datum/attack_style/unarmed/generic_damage/mob_attack/attack_effect_animation(mob/living/attacker, obj/item/bodypart/weapon, list/turf/affected_turfs, override_effect)
	if(isanimal(attacker))
		var/mob/living/simple_animal/animal = attacker
		override_effect = animal.attack_vis_effect

	if(isbasicmob(attacker))
		var/mob/living/basic/animal = attacker
		override_effect = animal.attack_vis_effect

	return ..()

/datum/attack_style/unarmed/generic_damage/mob_attack/actually_apply_damage(
	mob/living/attacker,
	mob/living/smacked,
	obj/item/bodypart/hitting_with,
	obj/item/bodypart/affecting,
	datum/apply_damage_packet/packet,
)
	. = ..()
	// Bad code ahead but this is primarily for compatibiltiy with old effects
	// Ideally these should all be moved to a swing, or react to a signal sent by a swing, or just in click, or whatever else
	if(ishostile(attacker))
		var/mob/living/simple_animal/hostile/animal = attacker
		animal.GiveTarget(smacked)
		UNLINT(animal.AttackingTarget(smacked))

	if(isbasicmob(attacker))
		var/mob/living/basic/animal = attacker
		UNLINT(animal.melee_attack(smacked))
