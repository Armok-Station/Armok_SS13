/// This provides different types of magic resistance on an object
/datum/component/anti_magic
	var/antimagic_flags
	var/charges
	var/inventory_flags
	var/datum/callback/drain_antimagic
	var/datum/callback/expiration

/**
 * Adds magic resistances to an object
 *
 * Magic resistance will prevent magic from affecting the user if it has the correct resistance
 * against the type of magic being used
 * 
 * args:
 * * antimagic_flags (optional) A bitflag with the types of magic resistance on the object
 * * charges (optional) The amount of times the object can protect the user from magic 
 * * inventory_flags (optional) The inventory slot the object must be located at in order to activate
 * * drain_antimagic (optional) The proc that is triggered when an object has been drained a antimagic charge
 * * expiration (optional) The proc that is triggered when the object is depleted of charges
 * *
 * antimagic bitflags: (see code/__DEFINES/magic.dm)
 * * MAGIC_RESISTANCE - Default magic resistance that blocks normal magic (wizard, spells, staffs)
 * * MAGIC_RESISTANCE_MIND - Tinfoil hat magic resistance that blocks mental magic (telepathy, abductors, jelly people)
 * * MAGIC_RESISTANCE_HOLY - Holy magic resistance that blocks unholy magic (revenant, cult, vampire, voice of god)
 * * MAGIC_RESISTANCE_ALL - All magic resistances combined
**/
/datum/component/anti_magic/Initialize(
		antimagic_flags = MAGIC_RESISTANCE,
		charges = INFINITY, 
		inventory_flags = ~ITEM_SLOT_BACKPACK, // items in a backpack won't activate, anywhere else is fine
		drain_antimagic, 
		expiration
	)

	if(isitem(parent))
		RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, .proc/on_equip)
		RegisterSignal(parent, COMSIG_ITEM_DROPPED, .proc/on_drop)
	else if(ismob(parent))
		RegisterSignal(parent, COMSIG_MOB_RECEIVE_MAGIC, .proc/block_receiving_magic)
		RegisterSignal(parent, COMSIG_MOB_RESTRICT_MAGIC, .proc/restrict_casting_magic)
		to_chat(parent, span_warning("Magic seems to flee from you, you can't gather enough power to cast spells."))	
	else
		return COMPONENT_INCOMPATIBLE

	src.antimagic_flags = antimagic_flags
	src.charges = charges
	src.inventory_flags = inventory_flags 
	src.drain_antimagic = drain_antimagic
	src.expiration = expiration

/datum/component/anti_magic/proc/on_equip(datum/source, mob/equipper, slot)
	SIGNAL_HANDLER

	if(!(inventory_flags & slot)) //Check that the slot is valid for antimagic
		UnregisterSignal(equipper, COMSIG_MOB_RECEIVE_MAGIC)
		UnregisterSignal(equipper, COMSIG_MOB_RESTRICT_MAGIC)
		equipper.update_action_buttons()
		return
	RegisterSignal(equipper, COMSIG_MOB_RECEIVE_MAGIC, .proc/block_receiving_magic)
	RegisterSignal(equipper, COMSIG_MOB_RESTRICT_MAGIC, .proc/restrict_casting_magic)
	equipper.update_action_buttons()

	//if(is_type_in_list(/datum/action/spell_action/spell, equipper.actions))
	for(var/datum/action/spell_action/spell/magic_action in equipper.actions)
		var/obj/effect/proc_holder/spell/magic_spell = magic_action.target
		if(antimagic_flags & magic_spell.antimagic_flags)
			to_chat(equipper, span_warning("Your [parent] is interfering with your ability to cast magic!"))
			break


/datum/component/anti_magic/proc/on_drop(datum/source, mob/user)
	SIGNAL_HANDLER

	UnregisterSignal(user, COMSIG_MOB_RECEIVE_MAGIC)
	UnregisterSignal(user, COMSIG_MOB_RESTRICT_MAGIC)
	user.update_action_buttons()

/datum/component/anti_magic/proc/block_receiving_magic(datum/source, mob/user, casted_magic_flags, charge_cost)
	SIGNAL_HANDLER

	// disclaimer - All anti_magic sources will be drained a charge_cost
	if(casted_magic_flags & antimagic_flags)
		// im a programmer not shakesphere to the future grammar nazis that come after me for this
		var/visible_subject = ismob(parent) ? "[user.p_they()]" : "[user.p_their()] [parent]"
		var/self_subject = ismob(parent) ? "you" : "your [parent]"
		if(casted_magic_flags & antimagic_flags & MAGIC_RESISTANCE)
			user.visible_message(span_warning("[user] pulses red as [visible_subject] absorbs magic energy!"), \
			span_userdanger("An intense magical aura pulses around [self_subject] as it dissipates into the air!"))
		else if(casted_magic_flags & antimagic_flags & MAGIC_RESISTANCE_HOLY)
			user.visible_message(span_warning("[user] starts to glow as [visible_subject] emits a halo of light!"), \
			span_userdanger("A feeling of warmth washes over [self_subject] as rays of light surround your body and protect you!"))
		else if(casted_magic_flags & antimagic_flags & MAGIC_RESISTANCE_MIND)
			user.visible_message(span_warning("[user] forehead shines as [visible_subject] repulses magic from their mind!"), \
			span_userdanger("A feeling of cold splashes on [self_subject] as your forehead reflects magic targeting your mind!"))

		if(ismob(parent))
			return TRUE

		var/has_limited_charges = !(charges == INFINITY)
		var/charge_was_drained = charge_cost > 0
		if(has_limited_charges && charge_was_drained)
			drain_antimagic?.Invoke(user, parent)
			charges -= charge_cost
			if(charges <= 0)
				expiration?.Invoke(user, parent)
				qdel(src)
		return TRUE
	return FALSE

/// cannot cast magic with the same type of antimagic present
/datum/component/anti_magic/proc/restrict_casting_magic(datum/source, mob/user, magic_flags)
	SIGNAL_HANDLER

	if(magic_flags & antimagic_flags)
		if(HAS_TRAIT(user, TRAIT_ANTIMAGIC_NO_SELFBLOCK)) // this trait bypasses magic casting restrictions
			return FALSE	
		return TRUE	

	return FALSE
