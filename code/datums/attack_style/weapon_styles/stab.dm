// Direct stabs out to turfs in front
/datum/attack_style/melee_weapon/stab_out
	time_per_turf = 0.2 SECONDS
	/// How far the stab goes
	var/stab_range = 1
	/// How long the animation lingers after finishing
	var/animation_linger_time = 0.2 SECONDS

/datum/attack_style/melee_weapon/stab_out/get_swing_description(has_alt_style)
	return "Stabs out [stab_range] tiles in the direction you are attacking."

/datum/attack_style/melee_weapon/stab_out/select_targeted_turfs(mob/living/attacker, obj/item/weapon, attack_direction, right_clicking)
	var/max_range = stab_range
	var/turf/last_turf = get_turf(attacker)
	var/list/select_turfs = list()
	while(max_range > 0)
		var/turf/next_turf = get_step(last_turf, attack_direction)
		if(istype(next_turf))
			select_turfs += next_turf
		// This block stabbing over tables... needs a bit of work to allow that.
		if(isnull(next_turf) || next_turf.is_blocked_turf(exclude_mobs = TRUE, source_atom = weapon)) // melbert todo
			return select_turfs
		last_turf = next_turf
		max_range--

	return select_turfs

/datum/attack_style/melee_weapon/stab_out/attack_effect_animation(mob/living/attacker, obj/item/weapon, list/turf/affected_turfs)
	var/image/attack_image = create_attack_image(attacker, weapon, affected_turfs[1])
	var/stab_length = time_per_turf * length(affected_turfs)
	attacker.do_attack_animation(affected_turfs[1], no_effect = TRUE) // melbert todo
	flick_overlay_global(attack_image, GLOB.clients, stab_length + animation_linger_time)
	var/start_x = attack_image.pixel_x
	var/start_y = attack_image.pixel_y
	var/x_move = 0
	var/y_move = 0
	var/stab_dir = get_dir(attacker, affected_turfs[1])
	if(stab_dir & NORTH)
		y_move += 8
	else if(stab_dir & SOUTH)
		y_move -= 8
	if(stab_dir & EAST)
		x_move += 8
	else if(stab_dir & WEST)
		x_move -= 8

	// Does a short pull in, then stab out
	animate(
		attack_image,
		time = stab_length * 0.25,
		pixel_x = start_x + (x_move * -1),
		pixel_y = start_y + (y_move * -1),
		easing = CUBIC_EASING|EASE_IN,
	)
	animate(
		time = stab_length * 0.75,
		pixel_x = start_x + (x_move * 1.5),
		pixel_y = start_y + (y_move * 1.5),
		alpha = 175,
		easing = CUBIC_EASING|EASE_OUT,
	)
	animate(
		time = animation_linger_time,
		alpha = 0,
		easing = CIRCULAR_EASING|EASE_OUT,
	)

/datum/attack_style/melee_weapon/stab_out/spear
	cd = CLICK_CD_MELEE * 2
	stab_range = 2
	sprite_size_multiplier = 1.5
