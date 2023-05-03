/datum/attack_style/unarmed/help

/datum/attack_style/unarmed/help/finalize_attack(mob/living/attacker, mob/living/smacked, obj/item/weapon, right_clicking)
	if(smacked.check_block(attacker, 0, "[attacker]'s touch", UNARMED_ATTACK))
		smacked.visible_message(
			span_warning("[smacked] blocks [attacker]'s touch!"),
			span_userdanger("You block [attacker]'s touch!"),
			span_hear("You hear a swoosh!"),
			vision_distance = COMBAT_MESSAGE_RANGE,
			ignored_mobs = attacker,
		)
		to_chat(attacker, span_warning("[smacked] blocks your grab!"))
		return ATTACK_STYLE_BLOCKED

	// Todo : move this out and into its own style?
	if(!HAS_TRAIT(smacked, TRAIT_MARTIAL_ARTS_IMMUNE))
		var/datum/martial_art/art = attacker.mind?.martial_art
		switch(art?.help_act(attacker, smacked))
			if(MARTIAL_ATTACK_SUCCESS)
				return ATTACK_STYLE_HIT
			if(MARTIAL_ATTACK_FAIL)
				return ATTACK_STYLE_MISSED

	var/list/new_modifiers = list(LEFT_CLICK = !right_clicking, RIGHT_CLICK = right_clicking)
	return smacked.attack_hand(attacker, new_modifiers)
