/// Watchers' ground-dwelling cousins, they shoot at you until they get into melee and absorb laser fire to power up.
/mob/living/basic/mining/basilisk
	name = "basilisk"
	desc = "A territorial beast, covered in a diamond shell which absorbs heat. Its stare causes victims to freeze from the inside."
	icon_state = "Basilisk"
	icon_living = "Basilisk"
	icon_dead = "Basilisk_dead"
	speak_emote = list("chimes")
	damage_coeff = list(BRUTE = 1, BURN = 0.1, TOX = 1, CLONE = 1, STAMINA = 0, OXY = 1)
	speed = 20
	maxHealth = 200
	health = 200
	obj_damage = 60
	melee_damage_lower = 12
	melee_damage_upper = 12
	attack_verb_continuous = "bites into"
	attack_verb_simple = "bite into"
	throw_blocked_message = "bounces off the shell of"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	ai_controller = /datum/ai_controller/basic_controller/Basilisk
	butcher_results = list(
		/obj/item/stack/sheet/bone = 1,
		/obj/item/stack/ore/diamond = 2,
		/obj/item/stack/sheet/sinew = 2,
	)
	/// How often can we shoot?
	var/ranged_cooldown = 3 SECONDS
	/// What kind of beam do we fire?
	var/default_projectile_type = /obj/projectile/temp/watcher
	/// What does it sound like when we fire a beam?
	var/default_projectile_sound = 'sound/weapons/pierce.ogg'

/mob/living/basic/mining/basilisk/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ranged_attacks, projectiletype = default_projectile_type, projectilesound = default_projectile_sound)
	AddComponent(/datum/component/basic_mob_attack_telegraph)

/mob/living/basic/mining/basilisk/welder_act(mob/living/user, obj/item/tool)
	. = ..()
	heat_up() // Who would do this?

/mob/living/basic/mining/basilisk/bullet_act(obj/projectile/bullet, def_zone, piercing_hit)
	. = .. ()
	if (istype(bullet, /obj/projectile/temp))
		var/obj/projectile/temp/heat_bullet = bullet
		if (heat_bullet.temperature < 0)
			return
		heat_up()
		return

	if (bullet.damage == 0 || bullet.damage_type != BURN)
		return
	heat_up()

/mob/living/basic/mining/basilisk/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	. = ..()
	var/turf/open/lava/entered_lava = loc
	if (!islava(entered_lava) || entered_lava.immunity_trait != TRAIT_LAVA_IMMUNE)
		return
	heat_up()

/// We got hit by something hot, go into heat mode
/mob/living/basic/mining/basilisk/proc/heat_up()
	if (stat != CONSCIOUS || has_status_effect(/datum/status_effect/basilisk_overheat))
		return
	apply_status_effect(/datum/status_effect/basilisk_overheat)

/datum/ai_controller/basic_controller/Basilisk
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/ranged_skirmish,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)
