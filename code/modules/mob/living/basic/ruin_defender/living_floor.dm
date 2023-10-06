/datum/ai_planning_subtree/basic_melee_attack_subtree/on_top/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/datum/weakref/weak_target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	var/atom/target = weak_target?.resolve()
	if(!target || QDELETED(target))
		return
	if(target.loc != controller.pawn.loc)
		return
	return ..()

/datum/ai_controller/basic_controller/living_floor
	max_target_distance = 2
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/syndicate(), //kill people
	)

	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/on_top
	)

/mob/living/basic/living_floor
	name = "floor"
	desc = ""
	icon = 'icons/turf/floors.dmi'
	icon_state = "floor"
	icon_living = "floor"
	mob_size = MOB_SIZE_HUGE
	status_flags = GODMODE //everything but crowbars may kill us
	death_message = ""
	unsuitable_atmos_damage = 0
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = INFINITY
	basic_mob_flags = DEL_ON_DEATH
	move_resist = INFINITY
	density = FALSE
	combat_mode = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	faction = list(FACTION_HOSTILE)
	melee_damage_lower = 20
	melee_damage_upper = 40 //pranked.....
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	ai_controller = /datum/ai_controller/basic_controller/living_floor
	
	var/icon_aggro = "floor-hostile"
	var/desc_aggro = "This flooring is alive and filled with teeth, better not step on that. Being covered in plating, it is immune to damage. Seems vulnerable to prying though."

/mob/living/basic/living_floor/Initialize(mapload)
	. = ..()
	RegisterSignal(loc, COMSIG_ATOM_ENTERED, PROC_REF(on_entered)) //we cant move anyway

/mob/living/basic/living_floor/Destroy()
	. = ..()
	UnregisterSignal(loc, COMSIG_ATOM_ENTERED)

/mob/living/basic/living_floor/Life(delta_time = SSMOBS_DT, times_fired)
	. = ..()
	var/datum/targetting_datum/basic/targetting = ai_controller.blackboard[BB_TARGETTING_DATUM]
	var/datum/weakref/weak_target = ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	var/mob/living/target = weak_target?.resolve()
	if(targetting.can_attack(src, target) && get_dist(src, target) <= 1) //do this at pointblank and when we can attack
		icon_state = icon_aggro
		desc = desc_aggro
	else
		icon_state = icon_living
		desc = ""

/mob/living/basic/living_floor/med_hud_set_health()
	return

/mob/living/basic/living_floor/med_hud_set_status()
	return

/mob/living/basic/living_floor/proc/on_entered(datum/source, atom/movable/victim) // guaranteed bite on pass
	SIGNAL_HANDLER
	var/datum/targetting_datum/basic/targetting = ai_controller.blackboard[BB_TARGETTING_DATUM]
	if(targetting.can_attack(src, victim)) 
		melee_attack(victim)

/mob/living/basic/living_floor/attackby(obj/item/weapon, mob/user, params)
	if(weapon.tool_behaviour == TOOL_CROWBAR)
		balloon_alert(user, "you start prying it off with all your strength...")
		if(do_after(user, 5 SECONDS, src))
			new /obj/effect/gibspawner/generic(loc)
			qdel(src)
	else
		return ..()

/mob/living/basic/living_floor/white
	icon_state = "white"
	icon_living = "white"
	icon_aggro = "whitefloor-hostile"