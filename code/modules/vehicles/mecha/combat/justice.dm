#define DISMEMBER_CUALITY_HIGTH 50
#define DISMEMBER_CUALITY_LOW 25

#define MOVEDELAY_ANGRY 4.5
#define MOVEDELAY_SAFTY 2.5

/obj/vehicle/sealed/mecha/justice
	desc = "Black and red syndicate mech designed for execution an orders. \
	For safety reasons, the syndicate advises against standing too close."
	name = "\improper Justice"
	icon_state = "justice"
	base_icon_state = "justice"
	movedelay = MOVEDELAY_SAFTY // fast
	max_integrity = 175 // but weak
	accesses = list()
	armor_type = /datum/armor/mecha_justice
	max_temperature = 40000
	force = 60 // dangerous in melee
	damtype = BRUTE
	destruction_sleep_duration = 10
	exit_delay = 10
	wreckage = /obj/structure/mecha_wreckage/justice
	mech_type = EXOSUIT_MODULE_JUSTICE
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	mecha_flags = ID_LOCK_ON | QUIET_STEPS | QUIET_TURNS | CAN_STRAFE | HAS_LIGHTS | MMI_COMPATIBLE | IS_ENCLOSED
	destroy_wall_sound = 'sound/mecha/mech_blade_break_wall.ogg'
	brute_attack_sound = 'sound/mecha/mech_blade_attack.ogg'
	attack_verbs = list("cut", "cuts", "cuting")
	weapons_safety = TRUE
	max_equip_by_category = list(
		MECHA_L_ARM = null,
		MECHA_R_ARM = null,
		MECHA_UTILITY = 3,
		MECHA_POWER = 1,
		MECHA_ARMOR = 2,
	)
	step_energy_drain = 2
	var/datum/action/vehicle/sealed/mecha/invisibility/stealth_action
	var/datum/action/vehicle/sealed/mecha/invisibility/charge_action

/datum/armor/mecha_justice
	melee = 30
	bullet = 20
	laser = 20
	energy = 30
	fire = 100
	acid = 100

/obj/vehicle/sealed/mecha/justice/Initialize(mapload, built_manually)
	. = ..()
	RegisterSignal(src, COMSIG_MECHA_MELEE_CLICK, PROC_REF(justice_fatality)) //We do not hit those who are in crit or stun. We are finishing them
	transform = transform.Scale(1.04, 1.04)

/obj/vehicle/sealed/mecha/justice/generate_actions()
	. = ..()
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/invisibility)
	initialize_passenger_action_type(/datum/action/vehicle/sealed/mecha/charge_attack)

/obj/vehicle/sealed/mecha/justice/update_icon_state()
	. = ..()
	if(LAZYLEN(occupants))
		icon_state = weapons_safety ? "[base_icon_state]" : "[base_icon_state]-angry"
	if(!has_gravity())
		icon_state = "[icon_state]-fly"

/obj/vehicle/sealed/mecha/justice/process(seconds_per_tick)
	. = ..()
	for(var/who_inside in occupants)
		var/mob/living/occupant = who_inside
		stealth_action = LAZYACCESSASSOC(occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/invisibility)
		charge_action = LAZYACCESSASSOC(occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/charge_attack)
		if(alpha == 255)
			stealth_action.on = FALSE
		else if(alpha == 0)
			stealth_action.on = TRUE
	update_appearance(UPDATE_ICON_STATE)

/obj/vehicle/sealed/mecha/justice/set_safety(mob/user)
	weapons_safety = !weapons_safety

	if(weapons_safety)
		movedelay = MOVEDELAY_SAFTY
	else
		movedelay = MOVEDELAY_ANGRY
	playsound(src, 'sound/mecha/mech_blade_safty.ogg', 75, FALSE) //everyone need to hear this sound
	balloon_alert(user, "Justice [weapons_safety ? "calm and focused" : "is ready for battle"]")
	SEND_SIGNAL(src, COMSIG_MECH_SAFETIES_TOGGLE, user, weapons_safety)
	set_mouse_pointer()

	update_appearance(UPDATE_ICON_STATE)

/obj/vehicle/sealed/mecha/justice/Move(newloc, dir)
	if(stealth_action.start_attack)
		return
	. = ..()
	update_appearance(UPDATE_ICON_STATE)

/obj/vehicle/sealed/mecha/justice/proc/justice_fatality(datum/source, mob/living/pilot, atom/target, on_cooldown, is_adjacent)
	SIGNAL_HANDLER

	if(isliving(target))
		var/mob/living/live_or_dead = target
		if((live_or_dead.stat >= UNCONSCIOUS && live_or_dead.stat < DEAD) || live_or_dead.getStaminaLoss() >= 100)
			if(charge_action) // We don't do fatality if try to use charge or stealth attack
				if(charge_action.on)
					return FALSE
			if(stealth_action)
				if(stealth_action.on)
					return FALSE
			say(pick("Take my Justice-Slash!", "A falling leaf...", "Justice is quite a lonely path"), forced = "Justice Mech")
			playsound(src, 'sound/mecha/mech_stealth_pre_attack.ogg', 75, FALSE)
			addtimer(CALLBACK(src, PROC_REF(finish_him), pilot, live_or_dead), 1 SECONDS)
			return TRUE
		return FALSE

/obj/vehicle/sealed/mecha/justice/proc/finish_him(mob/finisher, mob/living/him)
	var/turf/finish_turf = get_step(him, get_dir(finisher, him))
	var/turf/for_line_turf = get_turf(finisher)
	var/obj/item/bodypart/in_your_head = him.get_bodypart(BODY_ZONE_HEAD)
	if(in_your_head)
		in_your_head.dismember(BRUTE)
	else
		him.apply_damage(100, BRUTE)
	playsound(src, brute_attack_sound, 75, FALSE)
	for_line_turf.Beam(src, icon_state = "mech_charge", time = 8)
	forceMove(finish_turf)

/obj/vehicle/sealed/mecha/justice/melee_attack_effect(mob/living/victim, heavy)
	if(heavy)
		var/obj/item/bodypart/cut_bodypart = victim.get_bodypart(pick(BODY_ZONE_R_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_ARM, BODY_ZONE_L_LEG))
		if(prob(DISMEMBER_CUALITY_HIGTH))
			cut_bodypart.dismember(BRUTE)
	else
		victim.Knockdown(40)

/obj/vehicle/sealed/mecha/justice/mob_exit(mob/M, silent, randomstep, forced)
	. = ..()
	if(stealth_action)
		if(stealth_action.on)
			animate(src, alpha = 255, time = 0.5 SECONDS)
			playsound(src, 'sound/mecha/mech_stealth_effect.ogg' , 75, FALSE)

/obj/vehicle/sealed/mecha/justice/Bump(atom/obstacle)
	. = ..()
	if(!isliving(obstacle))
		return
	if(stealth_action)
		if(stealth_action.on)
			animate(src, alpha = 255, time = 0.5 SECONDS)
			playsound(src, 'sound/mecha/mech_stealth_effect.ogg' , 75, FALSE)

/obj/vehicle/sealed/mecha/justice/Bumped(atom/movable/bumped_atom)
	. = ..()
	if(!isliving(bumped_atom))
		return
	if(stealth_action)
		if(stealth_action.on)
			animate(src, alpha = 255, time = 0.5 SECONDS)
			playsound(src, 'sound/mecha/mech_stealth_effect.ogg' , 75, FALSE)

/obj/vehicle/sealed/mecha/justice/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)
	if(stealth_action)
		if(stealth_action.on)
			animate(src, alpha = 255, time = 0.5 SECONDS)
			playsound(src, 'sound/mecha/mech_stealth_effect.ogg' , 75, FALSE)
	if(LAZYLEN(occupants))
		if(prob(60))
			new /obj/effect/temp_visual/mech_sparks(get_turf(src))
			playsound(src, 'sound/mecha/mech_stealth_effect.ogg' , 75, FALSE)
			return
	. = ..()

/datum/action/vehicle/sealed/mecha/invisibility
	name = "Invisibility"
	button_icon_state = "mech_stealth_off"
	var/on = FALSE
	var/charge = TRUE
	var/start_attack = FALSE
	var/stealth_pre_attack_sound = 'sound/mecha/mech_stealth_pre_attack.ogg'
	var/stealth_attack_sound = 'sound/mecha/mech_stealth_attack.ogg'

/datum/action/vehicle/sealed/mecha/invisibility/Trigger(trigger_flags)
	. = ..()
	if(chassis.weapons_safety)
		owner.balloon_alert(owner, "safty is on!")
		return
	if(!charge)
		owner.balloon_alert(owner, "on recharge!")
		return
	new /obj/effect/temp_visual/mech_sparks(get_turf(chassis))
	on = !on
	playsound(chassis, 'sound/mecha/mech_stealth_effect.ogg' , 75, FALSE)
	if(on)
		for(var/who_inside in chassis.occupants)
			var/mob/living/occupant = who_inside
			var/datum/action/vehicle/sealed/mecha/charge_attack/charge_action = LAZYACCESSASSOC(chassis.occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/charge_attack)
			if(charge_action)
				if(charge_action.on)
					charge_action.on = FALSE
		animate(chassis, alpha = 0, time = 0.5 SECONDS)
		button_icon_state = "mech_stealth_on"
		addtimer(CALLBACK(src, PROC_REF(end_stealth)), 20 SECONDS)
		RegisterSignal(chassis, COMSIG_MECHA_MELEE_CLICK, PROC_REF(stealth_attack_aoe))
	else
		addtimer(CALLBACK(src, PROC_REF(charge)), 5 SECONDS)
		animate(chassis, alpha = 255, time = 0.5 SECONDS)
		button_icon_state = "mech_stealth_off"
		UnregisterSignal(chassis, COMSIG_MECHA_MELEE_CLICK)
	build_all_button_icons()

/datum/action/vehicle/sealed/mecha/invisibility/proc/end_stealth()
	if(on)
		owner.balloon_alert(owner, "invisability is over")
		Trigger()

/datum/action/vehicle/sealed/mecha/invisibility/proc/stealth_attack_aoe(datum/source, mob/living/pilot, atom/target, on_cooldown, is_adjacent)
	SIGNAL_HANDLER

	if(!charge)
		return FALSE
	if(chassis.alpha != 0)
		UnregisterSignal(chassis, COMSIG_MECHA_MELEE_CLICK)
		return FALSE
	UnregisterSignal(chassis, COMSIG_MECHA_MELEE_CLICK)
	new /obj/effect/temp_visual/mech_attack_aoe_charge(get_turf(chassis))
	start_attack = TRUE
	playsound(chassis, stealth_pre_attack_sound, 75, FALSE)
	addtimer(CALLBACK(src, PROC_REF(attack_in_aoe), pilot), 1 SECONDS)
	return TRUE

/datum/action/vehicle/sealed/mecha/invisibility/proc/attack_in_aoe(mob/living/pilot)
	Trigger()
	new /obj/effect/temp_visual/mech_attack_aoe_attack(get_turf(chassis))
	for(var/mob/living/somthing_living as anything in range(1, get_turf(chassis)))
		if(!isliving(somthing_living))
			continue
		if(somthing_living.stat >= UNCONSCIOUS)
			continue
		if(somthing_living.getStaminaLoss() >= 100)
			continue
		if(somthing_living == pilot)
			continue
		if(prob(DISMEMBER_CUALITY_LOW))
			var/obj/item/bodypart/cut_bodypart = somthing_living.get_bodypart(pick(BODY_ZONE_R_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_ARM, BODY_ZONE_L_LEG))
			cut_bodypart.dismember(BRUTE)
		somthing_living.apply_damage(35, BRUTE)
	playsound(chassis, stealth_attack_sound, 75, FALSE)
	start_attack = FALSE
	charge = FALSE
	button_icon_state = "mech_stealth_cooldown"
	build_all_button_icons()
	addtimer(CALLBACK(src, PROC_REF(charge)), 5 SECONDS)

/datum/action/vehicle/sealed/mecha/invisibility/proc/charge()
	button_icon_state = "mech_stealth_off"
	charge = TRUE
	build_all_button_icons()

/datum/action/vehicle/sealed/mecha/charge_attack
	name = "Charge Attack"
	button_icon_state = "mech_charge_off"
	var/on = FALSE
	var/charge = TRUE
	var/max_charge_range = 7
	var/charge_attack_sound = 'sound/mecha/mech_charge_attack.ogg'

/datum/action/vehicle/sealed/mecha/charge_attack/Trigger(trigger_flags)
	if(chassis.weapons_safety)
		owner.balloon_alert(owner, "safty is on!")
		return
	if(!charge)
		owner.balloon_alert(owner, "on recharge!")
		return
	on = !on
	if(on)
		for(var/who_inside in chassis.occupants)
			var/mob/living/occupant = who_inside
			var/datum/action/vehicle/sealed/mecha/charge_attack/stealth_action = LAZYACCESSASSOC(chassis.occupant_actions, occupant, /datum/action/vehicle/sealed/mecha/invisibility)
			if(stealth_action)
				if(stealth_action.on)
					stealth_action.Trigger()
		button_icon_state = "mech_charge_on"
		RegisterSignal(chassis, COMSIG_MECHA_MELEE_CLICK, PROC_REF(click_try_charge))
	if(!on)
		button_icon_state = "mech_charge_off"
		UnregisterSignal(chassis, COMSIG_MECHA_MELEE_CLICK)
	build_all_button_icons()

/datum/action/vehicle/sealed/mecha/charge_attack/proc/click_try_charge(datum/source, mob/living/pilot, atom/target, on_cooldown, is_adjacent)
	SIGNAL_HANDLER

	var/turf = get_turf(target)
	if(!on)
		UnregisterSignal(chassis, COMSIG_MECHA_MELEE_CLICK)
		return FALSE
	if(!turf)
		pilot.balloon_alert(pilot, "invalid direction!")
		return FALSE
	if(!charge)
		pilot.balloon_alert(pilot, "on recharge!")
		return FALSE
	else
		if(charge_attack(pilot, turf))
			return TRUE
	return FALSE

/datum/action/vehicle/sealed/mecha/charge_attack/proc/charge_attack(mob/living/charger, turf/target)
	var/turf/start_charge_here = get_turf(charger)
	var/turf/we_wanna_here = get_turf(target)
	var/charge_range = min(get_dist_euclidian(start_charge_here, we_wanna_here), max_charge_range)
	var/turf/but_we_gonna_here = get_ranged_target_turf(start_charge_here, get_dir(start_charge_here, we_wanna_here), floor(charge_range))

	var/turf/here_we_go = start_charge_here
	for(var/turf/line_turf in get_line(get_step(start_charge_here, get_dir(start_charge_here, we_wanna_here)), but_we_gonna_here))
		if(get_turf(charger) == get_turf(line_turf))
			continue
		if(isclosedturf(line_turf))
			if(isindestructiblewall(line_turf))
				break
			if(istype(line_turf, /turf/closed/wall/r_wall))
				line_turf.atom_destruction(MELEE)
			if(istype(line_turf, /turf/closed/wall))
				line_turf.atom_destruction(MELEE)
		for(var/obj/break_in as anything in line_turf.contents)
			if(istype(break_in, /obj/machinery/power/supermatter_crystal))
				var/obj/machinery/power/supermatter_crystal/funny_crystal = break_in
				funny_crystal.Bumped(chassis)
				break
			if(istype(break_in, /obj/machinery/gravity_generator))
				continue
			if(istype(break_in, /obj/machinery/atmospherics/pipe))
				continue
			if(istype(break_in, /obj/structure/disposalpipe))
				continue
			if(istype(break_in, /obj/structure/cable))
				continue
			if(istype(break_in, /obj/machinery) || istype(break_in, /obj/structure))
				break_in.atom_destruction(MELEE)
				continue
		for(var/mob/living/somthing_living as anything in line_turf.contents)
			if(!isliving(somthing_living))
				continue
			if(somthing_living.stat >= UNCONSCIOUS)
				continue
			if(somthing_living.getStaminaLoss() >= 100)
				continue
			if(somthing_living == charger)
				continue
			if(prob(DISMEMBER_CUALITY_LOW))
				var/obj/item/bodypart/cut_bodypart = somthing_living.get_bodypart(pick(BODY_ZONE_R_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_ARM, BODY_ZONE_L_LEG, BODY_ZONE_HEAD))
				cut_bodypart.dismember(BRUTE)
			somthing_living.apply_damage(35, BRUTE)
		here_we_go = line_turf

	if(here_we_go == start_charge_here)
		charger.balloon_alert(charger, "can't charge this direction!")
		return FALSE
	chassis.forceMove(here_we_go)
	start_charge_here.Beam(chassis, icon_state = "mech_charge", time = 8)
	playsound(chassis, charge_attack_sound, 75, FALSE)
	on = !on
	UnregisterSignal(chassis, COMSIG_MECHA_MELEE_CLICK)
	charge = FALSE
	button_icon_state = "mech_charge_cooldown"
	build_all_button_icons()
	addtimer(CALLBACK(src, PROC_REF(charge)), 5 SECONDS)
	return TRUE

/datum/action/vehicle/sealed/mecha/charge_attack/proc/charge()
	charge = TRUE
	button_icon_state = "mech_charge_off"
	build_all_button_icons()

/obj/vehicle/sealed/mecha/justice/loaded
	equip_by_category = list(
		MECHA_L_ARM = null,
		MECHA_R_ARM = null,
		MECHA_UTILITY = list(/obj/item/mecha_parts/mecha_equipment/radio, /obj/item/mecha_parts/mecha_equipment/air_tank/full, /obj/item/mecha_parts/mecha_equipment/thrusters/ion),
		MECHA_POWER = list(),
		MECHA_ARMOR = list(),
	)

/obj/vehicle/sealed/mecha/justice/loaded/populate_parts()
	cell = new /obj/item/stock_parts/cell/bluespace(src)
	scanmod = new /obj/item/stock_parts/scanning_module/triphasic(src)
	capacitor = new /obj/item/stock_parts/capacitor/quadratic(src)
	servo = new /obj/item/stock_parts/servo/femto(src)
	update_part_values()

#undef DISMEMBER_CUALITY_HIGTH
#undef DISMEMBER_CUALITY_LOW

#undef MOVEDELAY_ANGRY
#undef MOVEDELAY_SAFTY
