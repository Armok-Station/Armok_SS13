/**
 * This is the proc that handles the order of an item_attack.
 *
 * The order of procs called is:
 * * [/atom/proc/tool_act] on the target. If it returns TOOL_ACT_TOOLTYPE_SUCCESS or TOOL_ACT_SIGNAL_BLOCKING, the chain will be stopped.
 * * [/obj/item/proc/pre_attack] on src. If this returns TRUE, the chain will be stopped.
 * * [/atom/proc/attackby] on the target. If it returns TRUE, the chain will be stopped.
 * * [/obj/item/proc/afterattack]. The return value does not matter.
 *
 * Going into this proc, Click CD is NOT YET SET
 */
/obj/item/proc/melee_attack_chain(mob/user, atom/target, params)
	var/is_right_clicking = LAZYACCESS(params2list(params), RIGHT_CLICK)
	if(tool_behaviour && (target.tool_act(user, src, tool_behaviour, is_right_clicking) & TOOL_ACT_MELEE_CHAIN_BLOCKING))
		return TRUE

	if(isliving(target) && !can_attack_with(user, params))
		return TRUE

	var/pre_attack_result
	if (is_right_clicking)
		switch (pre_attack_secondary(target, user, params))
			if (SECONDARY_ATTACK_CALL_NORMAL)
				pre_attack_result = pre_attack(target, user, params)
			if (SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
				return TRUE
			if (SECONDARY_ATTACK_CONTINUE_CHAIN)
				// Normal behavior
			else
				CRASH("pre_attack_secondary must return an SECONDARY_ATTACK_* define, please consult code/__DEFINES/combat.dm")
	else
		pre_attack_result = pre_attack(target, user, params)

	if(pre_attack_result)
		return TRUE

	var/attackby_result

	if (is_right_clicking)
		switch (target.attackby_secondary(src, user, params))
			if (SECONDARY_ATTACK_CALL_NORMAL)
				attackby_result = target.attackby(src, user, params)
			if (SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
				return TRUE
			if (SECONDARY_ATTACK_CONTINUE_CHAIN)
				// Normal behavior
			else
				CRASH("attackby_secondary must return an SECONDARY_ATTACK_* define, please consult code/__DEFINES/combat.dm")
	else
		attackby_result = target.attackby(src, user, params)

	if (attackby_result)
		return TRUE

	if(QDELETED(src) || QDELETED(target))
		attack_qdeleted(target, user, TRUE, params)
		return TRUE

	if (is_right_clicking)
		var/after_attack_secondary_result = afterattack_secondary(target, user, TRUE, params)

		// There's no chain left to continue at this point, so CANCEL_ATTACK_CHAIN and CONTINUE_CHAIN are functionally the same.
		if (after_attack_secondary_result == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN || after_attack_secondary_result == SECONDARY_ATTACK_CONTINUE_CHAIN)
			return TRUE

	var/afterattack_result = afterattack(target, user, TRUE, params)

	if (!(afterattack_result & AFTERATTACK_PROCESSED_ITEM) && isitem(target))
		if (isnull(user.get_inactive_held_item()))
			SStutorials.suggest_tutorial(user, /datum/tutorial/switch_hands, params2list(params))
		else
			SStutorials.suggest_tutorial(user, /datum/tutorial/drop, params2list(params))

	return afterattack_result & TRUE //this is really stupid but its needed because afterattack can return TRUE | FLAGS.

/// Called when the item is in the active hand, and clicked; alternately, there is an 'activate held object' verb or you can hit pagedown.
/obj/item/proc/attack_self(mob/user, modifiers)
	if(SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_SELF, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return TRUE
	interact(user)

/// Called when the item is in the active hand, and right-clicked. Intended for alternate or opposite functions, such as lowering reagent transfer amount. At the moment, there is no verb or hotkey.
/obj/item/proc/attack_self_secondary(mob/user, modifiers)
	if(SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_SELF_SECONDARY, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return TRUE

/**
 * Called on the item before it hits something
 *
 * Arguments:
 * * atom/A - The atom about to be hit
 * * mob/living/user - The mob doing the htting
 * * params - click params such as alt/shift etc
 *
 * See: [/obj/item/proc/melee_attack_chain]
 */
/obj/item/proc/pre_attack(atom/A, mob/living/user, params) //do stuff before attackby!
	if(SEND_SIGNAL(src, COMSIG_ITEM_PRE_ATTACK, A, user, params) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return TRUE
	return FALSE //return TRUE to avoid calling attackby after this proc does stuff

/**
 * Called on the item before it hits something, when right clicking.
 *
 * Arguments:
 * * atom/target - The atom about to be hit
 * * mob/living/user - The mob doing the htting
 * * params - click params such as alt/shift etc
 *
 * See: [/obj/item/proc/melee_attack_chain]
 */
/obj/item/proc/pre_attack_secondary(atom/target, mob/living/user, params)
	var/signal_result = SEND_SIGNAL(src, COMSIG_ITEM_PRE_ATTACK_SECONDARY, target, user, params)

	if(signal_result & COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(signal_result & COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CONTINUE_CHAIN

	return SECONDARY_ATTACK_CALL_NORMAL

/**
 * Called on an object being hit by an item
 *
 * Arguments:
 * * obj/item/attacking_item - The item hitting this atom
 * * mob/user - The wielder of this item
 * * params - click params such as alt/shift etc
 *
 * See: [/obj/item/proc/melee_attack_chain]
 */
/atom/proc/attackby(obj/item/attacking_item, mob/user, params)
	if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACKBY, attacking_item, user, params) & COMPONENT_NO_AFTERATTACK)
		return TRUE
	return FALSE

/**
 * Called on an object being right-clicked on by an item
 *
 * Arguments:
 * * obj/item/weapon - The item hitting this atom
 * * mob/user - The wielder of this item
 * * params - click params such as alt/shift etc
 *
 * See: [/obj/item/proc/melee_attack_chain]
 */
/atom/proc/attackby_secondary(obj/item/weapon, mob/user, params)
	var/signal_result = SEND_SIGNAL(src, COMSIG_ATOM_ATTACKBY_SECONDARY, weapon, user, params)

	if(signal_result & COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(signal_result & COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CONTINUE_CHAIN

	return SECONDARY_ATTACK_CALL_NORMAL

/obj/attackby(obj/item/attacking_item, mob/user, params)
	. = ..()
	if(.)
		return TRUE
	if(obj_flags & CAN_BE_HIT)
		return attacking_item.attack_atom(src, user, params)

/mob/living/attackby(obj/item/attacking_item, mob/living/user, params)
	if(can_perform_surgery(user, params))
		return TRUE

	if(..())
		return TRUE

	user.changeNext_move(CLICK_CD_MELEE)
	if(attacking_item.attack_wrapper(src, user, params) & (ATTACK_NO_AFTERATTACK|ATTACK_SWING_CANCEL|ATTACK_SWING_SKIPPED))
		return TRUE // end chain

	return FALSE // continue chain

/mob/living/attackby_secondary(obj/item/weapon, mob/living/user, params)
	return weapon.attack_secondary(src, user, params)


/**
 * This proc serves as a wrapper for calling [obj/item/proc/attack].
 *
 * It handles sending the proper signals before calling attack.
 *
 * If you do not understand the purpose of this proc, you probably just want to call [obj/item/proc/melee_attack_chian] instead.
 *
 * Arguments:
 * * mob/living/target_mob - The mob being hit by this item
 * * mob/living/user - The mob hitting with this item
 * * params - Click params of this attack
 *
 * Returns:
 * * Returning ATTACK_NO_AFTERATTACK cancel the attack chain
 * * Returning ATTACK_SKIP_ATTACK immediately continues attack chain, skipping the rest of the attack proc and going to afterattack.
 * This means it'll skip the part in which the target takes damage from being clicked on.
 * * Returning ATTACK_DEFAULT runs normal "target takes damage" part of the attack.
 */
/obj/item/proc/attack_wrapper(mob/living/target_mob, mob/living/user, params)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(user.is_holding(src))
		// likely not necessary but just for thoroughness, I guess.
		add_fingerprint(user)

	var/signal_return = SEND_SIGNAL(src, COMSIG_ITEM_ATTACK, target_mob, user, params) | SEND_SIGNAL(user, COMSIG_MOB_ITEM_ATTACK, src, user, params)
	if(signal_return & COMPONENT_CANCEL_ATTACK_CHAIN)
		return ATTACK_SWING_CANCEL // end chain
	if(signal_return & COMPONENT_SKIP_ATTACK)
		return ATTACK_SWING_SKIPPED // continue chain
	if(HAS_TRAIT(user, TRAIT_PACIFISM) && force && damtype != STAMINA)
		return ATTACK_SWING_CANCEL // shouldn't happen, but it if does end chain

	. = attack(target_mob, user, params)
	if(. & ATTACK_SWING_CANCEL)
		return ATTACK_SWING_CANCEL // end chain
	if(item_flags & NOBLUDGEON)
		return ATTACK_SWING_SKIPPED // continue chain

	return .

/**
 * The item is executing an attack on a living mob target
 *
 * Arguments:
 * * mob/living/target_mob - The mob being hit by this item
 * * mob/living/user - The mob hitting with this item
 * * params - Click params of this attack
 *
 * Return TRUE to stop any following attacks.
 * Return FALSE to continue with the afterattack.
 */
/obj/item/proc/attack(mob/living/target_mob, mob/living/user, params)
	PROTECTED_PROC(TRUE)
	return FALSE

/// The equivalent of [/obj/item/proc/attack] but for alternate attacks, AKA right clicking
/obj/item/proc/attack_secondary(mob/living/victim, mob/living/user, params)
	var/signal_result = SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_SECONDARY, victim, user, params)

	if(signal_result & COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(signal_result & COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CONTINUE_CHAIN

	return SECONDARY_ATTACK_CALL_NORMAL

/// The equivalent of the standard version of [/obj/item/proc/attack] but for non mob targets.
/obj/item/proc/attack_atom(atom/attacked_atom, mob/living/user, params)
	if(SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_ATOM, attacked_atom, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return
	if(item_flags & NOBLUDGEON)
		return
	var/item_cd = attack_style?.cd || CLICK_CD_MELEE
	user.changeNext_move(min(item_cd, CLICK_CD_MELEE * 1.25))
	user.do_attack_animation(attacked_atom)
	attacked_atom.attacked_by(src, user)

/**
 * Called from [/obj/item/proc/attack_atom] and [/obj/item/proc/attack] if the attack succeeds
 *
 * Note this is !!NOT THE SAME AS ATTACK_BY!!
 *
 * This proc handles the damage and effects of an attack, so it only happens after the attack has occurred.
 */
/atom/proc/attacked_by(obj/item/attacking_item, mob/living/user)
	if(!uses_integrity)
		CRASH("attacked_by() was called on an object that doesnt use integrity!")

	if(!attacking_item.force)
		return

	var/damage = take_damage(attacking_item.force, attacking_item.damtype, MELEE, 1)
	//only witnesses close by and the victim see a hit message.
	user.visible_message(span_danger("[user] hits [src] with [attacking_item][damage ? "." : ", without leaving a mark!"]"), \
		span_danger("You hit [src] with [attacking_item][damage ? "." : ", without leaving a mark!"]"), null, COMBAT_MESSAGE_RANGE)
	log_combat(user, src, "attacked", attacking_item)

/area/attacked_by(obj/item/attacking_item, mob/living/user)
	CRASH("areas are NOT supposed to have attacked_by() called on them!")

/**
 * Living attacked_by is where all "this mob is hit and takes damage" code is handled
 *
 * It handles calculating final attack damage, checking blocking, and armor calculations
 */
/mob/living/attacked_by(obj/item/attacking_item, mob/living/user)

	var/obj/item/bodypart/affecting
	var/damage = get_final_damage_for_weapon(attacking_item)
	var/damage_type = attacking_item.damtype

	if(user == src)
		// 100% hitrate for self harm
		affecting = get_attacked_bodypart(user)

	else
		var/zone_hit_chance = 80
		if(body_position == LYING_DOWN)
			// bonus to accuracy for lying down
			zone_hit_chance += 10
		affecting = get_attacked_bodypart(user, zone_hit_chance)

	var/hit_zone = parse_zone(affecting?.body_zone) || "body"
	send_item_attack_message(attacking_item, user, hit_zone, affecting)
	if(damage <= 0)
		return FALSE

	var/armor_block = min(ARMOR_MAX_BLOCK, run_armor_check(
		def_zone = affecting,
		attack_flag = MELEE, // All melee damage flies under the melee flag, even if it does burn or whatever damage
		absorb_text = span_notice("Your armor has protected your [hit_zone]!"),
		soften_text = span_warning("Your armor has softened a hit to your [hit_zone]!"),
		armour_penetration = attacking_item.armour_penetration,
		weak_against_armour = attacking_item.weak_against_armour,
	))
	var/final_wound_bonus = attacking_item.wound_bonus

	// this way, you can't wound with a surgical tool on help intent
	// if they have a surgery active and are lying down,
	// so a misclick with a circular saw on the wrong limb doesn't bleed them dry (they still get hit tho)
	if((attacking_item.item_flags & SURGICAL_TOOL) \
		&& !user.combat_mode \
		&& body_position == LYING_DOWN \
		&& (length(surgeries) > 0) \
	)
		final_wound_bonus = CANT_WOUND

	SEND_SIGNAL(attacking_item, COMSIG_ITEM_ATTACK_ZONE, src, user, affecting)

	apply_damage(
		damage = damage,
		damagetype = damage_type,
		def_zone = affecting,
		wound_bonus = final_wound_bonus,
		bare_wound_bonus = attacking_item.bare_wound_bonus,
		sharpness = attacking_item.get_sharpness(),
		attack_direction = get_dir(user, src),
		attacking_item = attacking_item,
	)

	if(ishuman(src) || client) // Icky istype src but it keeps the logs cleaner.
		SSblackbox.record_feedback("nested tally", "item_used_for_combat", 1, list("[attacking_item.force]", "[attacking_item.type]"))
		SSblackbox.record_feedback("tally", "zone_targeted", 1, parse_zone(user.zone_selected))

	was_attacked_effects(attacking_item, user, affecting, damage, damage_type, armor_block)
	return TRUE

/mob/living/proc/was_attacked_effects(obj/item/attacking_item, mob/living/user, obj/item/bodypart/hit_limb, damage, damage_type, armor_block)
	SHOULD_CALL_PARENT(TRUE)
	SEND_SIGNAL(src, COMSIG_LIVING_ATTACKED_BY, user, attacking_item, hit_limb, damage, damage_type, armor_block)
	if(damage_type == BRUTE && prob(33))
		add_blood_from_being_attacked(attacking_item, user, hit_limb)

/**
 * This takes an item (that's probably attacking us) and gets the final damage
 * of it based on its force and other modifiers that may affect it
 *
 * These are items affecting the WEAPON'S DAMAGE, but not affecting THE DAMAGE WE RECIEVE.
 * This may sound confusing at first but it's the difference is simply
 * "is the weapon becoming stronger" vs "is our guy weaker"
 *
 * Where "demolition modifier" would be in the former camp and covered by this proc,
 * and physiology is in the latter camp and is covered later in damage code
 *
 * Returns a number, the final damage of the weapon
 */
/mob/living/proc/get_final_damage_for_weapon(obj/item/attacking_item)
	. = attacking_item.force
	if(mob_biotypes & MOB_ROBOTIC)
		. *= attacking_item.demolition_mod

	return .

/**
 * Determines which bodypart is being hit by an incoming attack by a user
 *
 * Hit chance is the probability that it will divert to another random nearby limb (via [get_random_valid_zone])
 *
 * Returns a bodypart, or null if there are no valid bodyparts
 */
/mob/living/proc/get_attacked_bodypart(mob/living/user, hit_chance = 100)
	RETURN_TYPE(/obj/item/bodypart)
	return null

/**
 * Called when this mob is attacked by a BRUTE WEAPON and handles applying blood to the mob, the attacker, and the ground
 *
 * Returns a bodypart, or null if there are no valid bodyparts
 */
/mob/living/proc/add_blood_from_being_attacked(obj/item/attacking_item, mob/living/user, obj/item/bodypart/hit_limb)
	attacking_item.add_mob_blood(src)
	if(isturf(loc))
		add_splatter_floor(loc)
	if(get_dist(user, src) <= 1) //people with TK won't get smeared with blood
		user.add_mob_blood(src)
	return TRUE

/**
 * Last proc in the [/obj/item/proc/melee_attack_chain].
 * Returns a bitfield containing AFTERATTACK_PROCESSED_ITEM if the user is likely intending to use this item on another item.
 * Some consumers currently return TRUE to mean "processed". These are not consistent and should be taken with a grain of salt.
 *
 * Arguments:
 * * atom/target - The thing that was hit
 * * mob/user - The mob doing the hitting
 * * proximity_flag - is 1 if this afterattack was called on something adjacent, in your square, or on your person.
 * * click_parameters - is the params string from byond [/atom/proc/Click] code, see that documentation.
 */
/obj/item/proc/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = NONE
	. |= SEND_SIGNAL(src, COMSIG_ITEM_AFTERATTACK, target, user, proximity_flag, click_parameters)
	SEND_SIGNAL(user, COMSIG_MOB_ITEM_AFTERATTACK, target, src, proximity_flag, click_parameters)
	SEND_SIGNAL(target, COMSIG_ATOM_AFTER_ATTACKEDBY, src, user, proximity_flag, click_parameters)
	return .

/**
 * Called at the end of the attack chain if the user right-clicked.
 *
 * Arguments:
 * * atom/target - The thing that was hit
 * * mob/user - The mob doing the hitting
 * * proximity_flag - is 1 if this afterattack was called on something adjacent, in your square, or on your person.
 * * click_parameters - is the params string from byond [/atom/proc/Click] code, see that documentation.
 */
/obj/item/proc/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	var/signal_result = SEND_SIGNAL(src, COMSIG_ITEM_AFTERATTACK_SECONDARY, target, user, proximity_flag, click_parameters)
	SEND_SIGNAL(user, COMSIG_MOB_ITEM_AFTERATTACK_SECONDARY, target, src, proximity_flag, click_parameters)

	if(signal_result & COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(signal_result & COMPONENT_SECONDARY_CONTINUE_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CONTINUE_CHAIN

	return SECONDARY_ATTACK_CALL_NORMAL

/// Called if the target gets deleted by our attack
/obj/item/proc/attack_qdeleted(atom/target, mob/user, proximity_flag, click_parameters)
	SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_QDELETED, target, user, proximity_flag, click_parameters)
	SEND_SIGNAL(user, COMSIG_MOB_ITEM_ATTACK_QDELETED, target, user, proximity_flag, click_parameters)

/obj/item/proc/get_clamped_volume()
	if(w_class)
		if(force)
			return clamp((force + w_class) * 4, 30, 100)// Add the item's force to its weight class and multiply by 4, then clamp the value between 30 and 100
		else
			return clamp(w_class * 6, 10, 100) // Multiply the item's weight class by 6, then clamp the value between 10 and 100

/mob/living/proc/send_item_attack_message(obj/item/I, mob/living/user, hit_area, obj/item/bodypart/hit_bodypart)
	if(!I.force && !length(I.attack_verb_simple) && !length(I.attack_verb_continuous))
		return
	var/message_verb_continuous = length(I.attack_verb_continuous) ? "[pick(I.attack_verb_continuous)]" : "attacks"
	var/message_verb_simple = length(I.attack_verb_simple) ? "[pick(I.attack_verb_simple)]" : "attack"
	var/message_hit_area = ""
	if(hit_area)
		message_hit_area = " in the [hit_area]"
	var/attack_message_spectator = "[src] [message_verb_continuous][message_hit_area] with [I]!"
	var/attack_message_victim = "Something [message_verb_continuous] you[message_hit_area] with [I]!"
	var/attack_message_attacker = "You [message_verb_simple] [src][message_hit_area] with [I]!"
	if(user in viewers(src, null))
		attack_message_spectator = "[user] [message_verb_continuous] [src][message_hit_area] with [I]!"
		attack_message_victim = "[user] [message_verb_continuous] you[message_hit_area] with [I]!"
	if(user == src)
		attack_message_victim = "You [message_verb_simple] yourself[message_hit_area] with [I]."
	visible_message(span_danger("[attack_message_spectator]"),\
		span_userdanger("[attack_message_victim]"), null, COMBAT_MESSAGE_RANGE, user)
	if(is_blind())
		to_chat(src, span_danger("Someone hits you[message_hit_area]!"))
	to_chat(user, span_danger("[attack_message_attacker]"))
	return 1
