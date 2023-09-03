/*********************Mining Hammer****************/
/obj/item/kinetic_crusher
	name = "proto-kinetic crusher"
	desc = "An early design of the proto-kinetic accelerator, it is little more than a combination of various mining tools cobbled together, forming a high-tech club. \
	While it is an effective mining tool, it did little to aid any but the most skilled and/or suicidal miners against local fauna."
	force = 0 //You can't hit stuff unless wielded
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	throwforce = 5
	throw_speed = 4
	armour_penetration = 10
	custom_materials = list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT * 1.15, /datum/material/glass = HALF_SHEET_MATERIAL_AMOUNT * 2.075)
	icon = 'icons/obj/mining.dmi'
	icon_state = "crusher"
	inhand_icon_state = "crusher0"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("smashes", "crushes", "cleaves", "chops", "pulps")
	attack_verb_simple = list("smash", "crush", "cleave", "chop", "pulp")
	sharpness = SHARP_EDGED
	actions_types = list(/datum/action/item_action/toggle_light)
	obj_flags = UNIQUE_RENAME
	light_system = MOVABLE_LIGHT
	light_range = 5
	light_on = FALSE
	///Extra damage bonus for popping the field from the creature's back
	var/backstab_bonus = 30
	///Whether the crusher is ready to fire a destabilizing blast
	var/charged = TRUE
	///Recharge time between blast shots
	var/charge_time = 1.5 SECONDS
	///How much damage does popping the destabilizer field do
	var/detonation_damage = 50
	///List of trophies attached to the crusher
	var/list/trophies = list()
	var/force_unwielded = 0
	var/force_wielded = 20

/obj/item/kinetic_crusher/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, \
		speed = 6 SECONDS, \
		effectiveness = 110, \
	)
	//technically it's huge and bulky, but this provides an incentive to use it
	AddComponent(/datum/component/two_handed, \
		force_unwielded = src.force_unwielded, \
		force_wielded = src.force_wielded, \
	)
	AddElement(/datum/element/crusher_damage_ticker, APPLY_WITH_MELEE, force_wielded)

/obj/item/kinetic_crusher/Destroy()
	QDEL_LIST(trophies)
	return ..()

/obj/item/kinetic_crusher/Exited(atom/movable/gone, direction)
	. = ..()
	trophies -= gone

/obj/item/kinetic_crusher/examine(mob/living/user)
	. = ..()
	. += span_notice("Mark a large creature with a destabilizing force with right-click, then hit them in melee to do <b>[detonation_damage]</b> bonus damage.")
	. += span_notice("Does <b>[detonation_damage + backstab_bonus]</b> bonus damage if the target is backstabbed, instead of <b>[detonation_damage]</b>.")
	for(var/obj/item/crusher_trophy/attached_trophy as anything in trophies)
		. += span_notice("[icon2html(attached_trophy, user)] It has \a <b>[attached_trophy]</b> attached, which causes [attached_trophy.effect_desc()].")

/obj/item/kinetic_crusher/attackby(obj/item/attack_item, mob/living/user)
	if(attack_item.tool_behaviour == TOOL_CROWBAR)
		if(LAZYLEN(trophies))
			to_chat(user, span_notice("You remove [src]'s trophies."))
			attack_item.play_tool_sound(src)
			for(var/obj/item/crusher_trophy/found_trophy as anything in trophies)
				found_trophy.remove_from(src, user)
		else
			to_chat(user, span_warning("There are no trophies on [src]."))
	else if(istype(attack_item, /obj/item/crusher_trophy))
		var/obj/item/crusher_trophy/trophy_to_attach = attack_item
		trophy_to_attach.add_to(src, user)
	else
		return ..()

/obj/item/kinetic_crusher/attack(mob/living/target, mob/living/carbon/user)
	if(!HAS_TRAIT(src, TRAIT_WIELDED))
		to_chat(user, span_warning("[src] is too heavy to use with one hand! You fumble and drop everything."))
		user.drop_all_held_items()
		return
	return ..()

/obj/item/kinetic_crusher/afterattack(atom/target, mob/living/user, proximity_flag, clickparams)
	if(!HAS_TRAIT(src, TRAIT_WIELDED))
		return //it's already dropped by this point, so no feedback/dropping is required

	//handle trophy attack effects
	for(var/obj/item/crusher_trophy/found_trophy as anything in trophies)
		if(!QDELETED(target))
			found_trophy.on_melee_hit(target, user)

	if(proximity_flag && isliving(target))
		var/mob/living/victim = target
		var/datum/status_effect/crusher_mark/mark_field = victim.has_status_effect(/datum/status_effect/crusher_mark)
		if(!mark_field || mark_field.hammer_synced != src || !victim.remove_status_effect(/datum/status_effect/crusher_mark))
			return ..()
		var/datum/status_effect/crusher_damage/crusher_damage_tracker = victim.has_status_effect(/datum/status_effect/crusher_damage)
		var/target_health = victim.health
		for(var/obj/item/crusher_trophy/found_trophy as anything in trophies)
			found_trophy.on_mark_detonation(target, user)
		if(!QDELETED(victim))
			if(!QDELETED(crusher_damage_tracker))
				crusher_damage_tracker.total_damage += target_health - victim.health //we did some damage, but let's not assume how much we did
			new /obj/effect/temp_visual/kinetic_blast(get_turf(victim))
			var/backstabbed = FALSE
			var/combined_damage = detonation_damage
			var/backstab_dir = get_dir(user, victim)
			var/def_check = victim.getarmor(type = BOMB)
			if((user.dir & backstab_dir) && (victim.dir & backstab_dir))
				backstabbed = TRUE
				combined_damage += backstab_bonus
				playsound(user, 'sound/weapons/kinetic_accel.ogg', 80, TRUE)

			if(!QDELETED(crusher_damage_tracker))
				crusher_damage_tracker.total_damage += combined_damage


			SEND_SIGNAL(user, COMSIG_LIVING_CRUSHER_DETONATE, victim, src, backstabbed)
			victim.apply_damage(combined_damage, BRUTE, blocked = def_check)
	return ..()

/obj/item/kinetic_crusher/attack_secondary(mob/living/victim, mob/living/user, params)
	return SECONDARY_ATTACK_CONTINUE_CHAIN

/obj/item/kinetic_crusher/afterattack_secondary(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(!HAS_TRAIT(src, TRAIT_WIELDED))
		balloon_alert(user, "wield it first!")
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(target == user)
		balloon_alert(user, "can't aim at yourself!")
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	fire_kinetic_blast(target, user, click_parameters)
	user.changeNext_move(CLICK_CD_MELEE)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/kinetic_crusher/ui_action_click(mob/user, actiontype)
	set_light_on(!light_on)
	playsound(user, 'sound/weapons/empty.ogg', 80, TRUE)
	update_appearance()

/obj/item/kinetic_crusher/update_icon_state()
	inhand_icon_state = "crusher[HAS_TRAIT(src, TRAIT_WIELDED)]" // this is not icon_state and not supported by 2hcomponent
	return ..()

/obj/item/kinetic_crusher/update_overlays()
	. = ..()
	if(!charged)
		. += "[icon_state]_uncharged"
	if(light_on)
		. += "[icon_state]_lit"

///Fires a destabilizer projectile that can mark enemies with a destabilizer field or mine mineral turfs.
/obj/item/kinetic_crusher/proc/fire_kinetic_blast(atom/target, mob/living/user, click_parameters)
	if(!charged)
		return
	var/modifiers = params2list(click_parameters)
	var/turf/proj_turf = get_turf(user)
	if(!isturf(proj_turf))
		return
	var/obj/projectile/destabilizer/destabilizer = new(proj_turf)
	for(var/obj/item/crusher_trophy/attached_trophy as anything in trophies)
		attached_trophy.on_projectile_fire(destabilizer, user)
	destabilizer.preparePixelProjectile(target, user, modifiers)
	destabilizer.firer = user
	destabilizer.hammer_synced = src
	playsound(user, 'sound/weapons/plasma_cutter.ogg', 80, TRUE)
	destabilizer.fire()
	destabilizer.AddElement(/datum/element/crusher_damage_ticker, APPLY_WITH_PROJECTILE, destabilizer.damage) //apply element after on_projectile_fire() in case a trophy modifies it
	charged = FALSE
	update_appearance()
	if(charge_time <= 0) //you never know
		charge_time = 0.1 SECONDS
	addtimer(CALLBACK(src, PROC_REF(Recharge)), charge_time)

///Ready up the crusher to fire another projectile
/obj/item/kinetic_crusher/proc/Recharge()
	if(!charged)
		charged = TRUE
		update_appearance()
		playsound(get_turf(src), 'sound/weapons/kinetic_reload.ogg', 80, TRUE)

///Normal-sized crusher for admemery (used in a combat-ready miner outfit)
/obj/item/kinetic_crusher/compact
	name = "compact kinetic crusher"
	w_class = WEIGHT_CLASS_NORMAL

