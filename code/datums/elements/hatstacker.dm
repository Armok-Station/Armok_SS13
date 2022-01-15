/**
 * ### hat stacker element!
 *
 * Bespoke element (1-per-unique-argument in existence) that lets helmets stack hats on top of themselves!
 */
/datum/element/hatstacker
	element_flags = ELEMENT_BESPOKE|ELEMENT_DETACH
	id_arg_index = 2
	///Whitelist of attachable hats, supplied as argument 2
	var/list/attachable_hats_list

/datum/element/hatstacker/Attach(datum/target, list/attachable_hats_list)
	. = ..()
	src.attachable_hats_list = attachable_hats_list
	if(!istype(target, /obj/item/clothing/head))
		return ELEMENT_INCOMPATIBLE
	var/obj/item/clothing/head/valid_target = target

	RegisterSignal(valid_target, COMSIG_PARENT_EXAMINE, .proc/add_examine)
	RegisterSignal(valid_target, COMSIG_PARENT_ATTACKBY, .proc/place_hat)
	RegisterSignal(valid_target, COMSIG_ATOM_ATTACK_HAND_SECONDARY, .proc/remove_hat)

/datum/element/hatstacker/Detach(datum/target)
	. = ..()
	var/obj/item/clothing/head/attached_hat = find_stacked_hat(target)
	if(attached_hat)	//knock off the helmet if its on their head. Or, technically, auto-rightclick it for them; that way it saves us code, AND gives them the bubble
		remove_hat()
	UnregisterSignal(target, COMSIG_PARENT_EXAMINE)
	UnregisterSignal(target, COMSIG_PARENT_ATTACKBY)
	UnregisterSignal(target, COMSIG_ATOM_ATTACK_HAND_SECONDARY)

/datum/element/hatstacker/proc/find_stacked_hat(obj/item/clothing/head/target)
	for(var/obj/item/clothing/head/possibly_stacked in target)
		if(HAS_TRAIT(possibly_stacked, TRAIT_HATSTACKED))
			return possibly_stacked

/**
* Adds a span_notice(blue) examine to the target, saying if anything is/can be stacked on it
*
* target = what's examined
* user = who examined it
* base_examine = target's original examine, which we add our addition to the bottom of
**/
/datum/element/hatstacker/proc/add_examine(obj/item/clothing/head/target, mob/user, list/base_examine)
	SIGNAL_HANDLER
	var/obj/item/clothing/head/attached_hat = find_stacked_hat(target)
	if(attached_hat)
		base_examine += span_notice("There's \a [attached_hat] placed on the helmet. Right-click to remove it.")
	else
		base_examine += span_notice("There's nothing placed on the helmet. Yet.")

/**
* Attempts to place the attacking item, if a hat, atop the targetted hat
*
* target = the bottom-most, attacked hat
* hitting_item = the attacking item, hopefully a hat
* user = the one trying to stack the hats
**/
/datum/element/hatstacker/proc/place_hat(obj/item/clothing/head/target, obj/item/hitting_item, mob/user)
	SIGNAL_HANDLER
	var/obj/item/clothing/head/attached_hat = find_stacked_hat(target)
	if(!istype(hitting_item, /obj/item/clothing/head))
		return
	if(attached_hat)
		target.balloon_alert(user, "hat already attached!")
		return
	if(!is_type_in_list(hitting_item, attachable_hats_list))
		target.balloon_alert(user, "this hat won't fit!")
		return
	if(user.transferItemToLoc(hitting_item, target, force = FALSE, silent = TRUE))
		ADD_TRAIT(hitting_item, TRAIT_HATSTACKED, ELEMENT_TRAIT(src))
		attached_hat = hitting_item
		target.balloon_alert(user, "hat attached, right click to remove")
		//MODs all route thru the back. So this check needs to make sure the update is done on the back.
		if(istype(target, /obj/item/clothing/head/mod))
			var/icon_to_use = attached_hat.build_worn_icon(default_layer = ABOVE_BODY_FRONT_HEAD_LAYER-0.1, default_icon_file = 'icons/mob/clothing/head.dmi')
			user.update_inv_back(icon_to_use)	//The user should really be the only one placing the item in this case; helmet can only be deployed by a worn suit, after all.
		else
			var/icon_to_use = attached_hat.build_worn_icon(default_layer = HEAD_LAYER, default_icon_file = 'icons/mob/clothing/head.dmi')
			target.update_appearance(icon_to_use)

/**
* Attemps to remove a stacked hat on right-click
*
*
**/
/datum/element/hatstacker/proc/remove_hat(obj/item/clothing/head/target, mob/user)
	SIGNAL_HANDLER
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/obj/item/clothing/head/attached_hat = find_stacked_hat(target)
	if(!attached_hat)
		return
	attached_hat.forceMove(user.drop_location())
	if(user.put_in_active_hand(attached_hat))
		target.balloon_alert(user, "hat removed")
	else
		target.balloon_alert_to_viewers("the hat falls to the floor!")
	attached_hat = null
	//MODs all route thru the back. So this check needs to make sure the update is done on the back.
	if(istype(target, /obj/item/clothing/head/mod))
		user.update_inv_back()	//The user should really be the only one placing the item. I hope.
	else
		user.update_inv_head()
