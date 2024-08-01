/obj/item/pod_equipment/primary/projectile_weapon/energy/plasma_cutter
	name = "plasma cutter apparatus"
	desc = "An apparatus for pods that fires plasma cutter beams."
	casing_path = /obj/item/ammo_casing/energy/plasma
	fire_sound = /obj/item/ammo_casing/energy/plasma::fire_sound
	cooldown_time = 2 SECONDS

/obj/item/pod_equipment/primary/projectile_weapon/energy/kinetic_accelerator
	name = "pod proto-kinetic accelerator"
	projectile_path = /obj/item/ammo_casing/energy/kinetic::projectile_type
	fire_sound = /obj/item/ammo_casing/energy/kinetic::fire_sound
	cooldown_time = 1.75 SECONDS

/obj/item/pod_equipment/primary/drill
	name = "pod mining drill"
	desc = "A rig for pods that drills rocks infront of it."
	cooldown_time = 1 SECONDS
	/// damage vs objects
	var/damage_obj = 10
	/// damage vs mobs
	var/damage_mob = 20
	/// power used to drill
	var/power_used = STANDARD_BATTERY_CHARGE / 100
	/// force multiplier if we hit a rock to drill it
	var/force_mult = 0

/obj/item/pod_equipment/primary/drill/on_attach(mob/user)
	. = ..()
	RegisterSignal(pod, COMSIG_MOVABLE_BUMP, PROC_REF(on_bump))

/obj/item/pod_equipment/primary/drill/on_detach(mob/user)
	. = ..()
	UnregisterSignal(pod, COMSIG_MOVABLE_BUMP)

/obj/item/pod_equipment/primary/drill/proc/on_bump(datum/source, atom/bumped)
	SIGNAL_HANDLER
	if(get_dir(pod, bumped) != pod.dir)
		return

	if(!ismineralturf(get_step(pod, pod.dir)))
		if(!COOLDOWN_FINISHED(src, use_cooldown))
			return
		COOLDOWN_START(src, use_cooldown, cooldown_time)

	if(action())
		if(pod.drift_handler?.drift_force > 0.1 NEWTONS)
			var/force_needed = abs(pod.drift_handler.drift_force - pod.drift_handler.drift_force * force_mult)
			pod.newtonian_move(dir2angle(REVERSE_DIR(pod.dir)), instant = TRUE, drift_force = force_needed)
		return COMPONENT_INTERCEPT_BUMPED

/obj/item/pod_equipment/primary/drill/action(mob/user)
	if(!pod.use_power(power_used))
		return FALSE
	var/turf/target_turf = get_step(pod, pod.dir)
	if(ismineralturf(target_turf))
		var/turf/closed/mineral/mineral_turf = target_turf
		playsound(pod.loc, 'sound/weapons/drill.ogg', 50 , TRUE)
		mineral_turf.gets_drilled()
		return TRUE
	if(isclosedturf(target_turf))
		playsound(pod.loc, 'sound/weapons/drill.ogg', 50 , TRUE)
		return FALSE
	for(var/atom/movable/potential_target as anything in target_turf.contents)
		if(!potential_target.density)
			continue
		playsound(pod.loc, 'sound/weapons/drill.ogg', 50 , TRUE)
		potential_target.visible_message(span_danger("[potential_target] is drilled by the [pod]!"))
		if(ismob(potential_target))
			var/mob/living/target = potential_target
			target.apply_damage(damage_mob, BRUTE)
			if(iscarbon(target) && prob(35)) // no
				target.Knockdown(1 SECONDS)
		else
			potential_target.take_damage(damage_obj, BRUTE, attack_dir = REVERSE_DIR(pod.dir))
		return TRUE
	return FALSE

/obj/item/pod_equipment/primary/drill/impact
	name = "pod impact drill"
	desc = "Advanced variant of the pod drill, this one mines anything it bumps into. Equipped with advanced velocity tech, if it can be drilled, you only slightly lose speed."
	power_used = STANDARD_BATTERY_CHARGE / 60
	force_mult = 0.8

/obj/item/pod_equipment/primary/drill/impact/improved
	name = "improved pod impact drill"
	desc = "Advanced variant of the pod drill, this one mines anything it bumps into. Improves on its previous version by slowing you down even less."
	force_mult = 0.9
	power_used = STANDARD_BATTERY_CHARGE / 50

/obj/item/pod_equipment/primary/metalfoam
	name = "pod metal foam dispenser"
	desc = "Puts metal foam infront of your pod."
	cooldown_time = 1 SECONDS

/obj/item/pod_equipment/primary/metalfoam/action(mob/user)
	. = ..()
	var/turf/target_turf = get_step(pod, pod.dir)
	if(target_turf.is_blocked_turf_ignore_climbable())
		var/obj/structure/foamedmetal/foam = locate() in target_turf
		if(!isnull(foam))
			foam.take_damage(foam.max_integrity, BRUTE)
		return
	var/datum/effect_system/fluid_spread/foam/foam = new /datum/effect_system/fluid_spread/foam/metal()
	foam.set_up(range = 1, holder = src, location = target_turf)
	foam.start()
