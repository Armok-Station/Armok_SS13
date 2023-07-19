/datum/attack_style/unarmed/help
	attack_effect = null
	successful_hit_sound = 'sound/weapons/thudswoosh.ogg'
	miss_sound = null

/datum/attack_style/unarmed/help/finalize_attack(mob/living/attacker, mob/living/smacked, obj/item/weapon, right_clicking)
	if(smacked.check_block(attacker, 0, "[attacker]'s touch", UNARMED_ATTACK, 0, STAMINA))
		return ATTACK_SWING_BLOCKED

	// Todo : move this out and into its own style?
	if(!HAS_TRAIT(smacked, TRAIT_MARTIAL_ARTS_IMMUNE) && martial_arts_compatible)
		var/datum/martial_art/art = attacker.mind?.martial_art
		switch(art?.help_act(attacker, smacked))
			if(MARTIAL_ATTACK_SUCCESS)
				return ATTACK_SWING_HIT
			if(MARTIAL_ATTACK_FAIL)
				return ATTACK_SWING_MISSED

	var/list/new_modifiers = list(LEFT_CLICK = !right_clicking, RIGHT_CLICK = right_clicking)
	smacked.attack_hand(attacker, new_modifiers)
	return ATTACK_SWING_HIT
