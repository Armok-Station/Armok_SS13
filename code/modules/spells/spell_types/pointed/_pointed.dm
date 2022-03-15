/**
 * ## Pointed spells
 *
 * These spells override the caster's click,
 * allowing them to cast the spell on whatever is clicked on.
 */
/datum/action/cooldown/spell/pointed
	click_to_activate = TRUE
	// ranged_mousepointer = 'icons/effects/mouse_pointers/throw_target.dmi'
	// action_icon_state = "projectile"

	/// Message showing to the spell owner upon activating pointed spell.
	var/active_msg = "You prepare to use the spell on a target..."
	/// Message showing to the spell owner upon deactivating pointed spell.
	var/deactive_msg = "You dispel the magic..."
	/// Variable dictating if the spell will use turf based aim assist
	var/aim_assist = TRUE

/datum/action/cooldown/spell/pointed/New()
	. = ..()
	active_msg = "You prepare to use [src] on a target..."
	deactive_msg = "You dispel [src]."

/datum/action/cooldown/spell/pointed/set_click_ability()
	if(!can_cast_spell())
		return FALSE

	on_activation()
	return ..()

/datum/action/cooldown/spell/pointed/unset_click_ability()
	on_deactivation()
	return ..()

/datum/action/cooldown/spell/pointed/proc/on_activation()
	to_chat(owner, span_notice("[active_msg] <B>Left-click to activate the spell on a target!</B>"))

/datum/action/cooldown/spell/pointed/proc/on_deactivation()
	to_chat(owner, span_notice("[deactive_msg]"))

/datum/action/cooldown/spell/pointed/InterceptClickOn(mob/living/caller, params, atom/target)

	var/atom/aim_assist_target
	if(aim_assist && isturf(target))
		// Find any human in the list. We aren't picky, it's aim assist after all
		aim_assist_target = locate(/mob/living/carbon/human) in target
		if(!aim_assist_target)
			// If we didn't find a human, we settle for any living at all
			aim_assist_target = locate(/mob/living) in target

	return ..(caller, params, aim_assist_target || target)

/datum/action/cooldown/spell/pointed/is_valid_target(atom/cast_on)
	if(cast_on == owner)
		to_chat(owner, span_warning("You cannot cast [src] on yourself!"))
		return FALSE

	if(get_dist(owner, cast_on) > range)
		to_chat(owner, span_warning("[target.p_theyre(TRUE)] too far away!"))
		return FALSE

	return TRUE

/**
 * ### Pointed projectile spells
 *
 * Pointed spells that, instead of casting a spell directly on the target that's clicked,
 * will instead fire a projectile pointed at the target's direction.
 */
/datum/action/cooldown/spell/pointed/projectile
	unset_after_click = FALSE
	/// What projectile we create when we shoot our spell.
	var/projectile_type = /obj/projectile/magic/teleport
	/// How many projectiles we can fire per cast. Not all at once, per click
	var/projectile_amount = 1
	/// How many projectiles we have yet to fire
	var/current_amount = 0
	/// How many projectiles we fire every fire_projectile() call.
	/// Unwise to change without overriding or extending ready_projectile.
	var/projectiles_per_fire = 1

/datum/action/cooldown/spell/pointed/projectile/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/projectile/on_activation()
	. = ..()
	current_amount = projectile_amount

/datum/action/cooldown/spell/pointed/projectile/on_deactivation()
	. = ..()
	if(charge_type == "recharge")
		StartCooldown(cooldown_time * (current_amount / projectile_amount))

// cast_on is a turf, or atom target, that we clicked on to fire at.
/datum/action/cooldown/spell/pointed/projectile/cast(atom/cast_on)
	if(!isturf(owner.loc))
		return FALSE

	var/turf/caster_turf = get_turf(owner)
	// Get the tile infront of the caster, based on their direction
	var/turf/caster_front_turf = get_step(owner, owner.dir)

	fire_projectile(cast_on)
	owner.newtonian_move(get_dir(caster_front_turf, caster_turf))
	if(current_amount <= 0)
		on_deactivation()

	return TRUE

/datum/action/cooldown/spell/pointed/projectile/proc/fire_projectile(atom/target)
	current_amount--
	for(var/i in 1 to projectiles_per_fire)
		var/obj/projectile/to_fire = new projectile_type(get_turf(owner))
		ready_projectile(to_fire, target, owner, i)
		to_fire.fire()
	return TRUE

/datum/action/cooldown/spell/pointed/projectile/proc/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	to_fire.firer = owner
	to_fire.fired_from = get_turf(owner)
	to_fire.preparePixelProjectile(target, owner)
