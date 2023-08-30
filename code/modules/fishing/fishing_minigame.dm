// Lure bobbing
#define WAIT_PHASE 1
// Click now to start tgui part
#define BITING_PHASE 2
// UI minigame phase
#define MINIGAME_PHASE 3

/// The height of the minigame slider. Not in pixels, but minigame units.
#define FISHING_MINIGAME_HEIGHT 1000
/// Any lower than this, and the target position of the fish is considered null
#define FISH_TARGET_MIN_DISTANCE 6
/// The friction applied to fish jumps, so that it decelerates over time
#define FISH_FRICTION_COEFF 0.9
/// Used to decide whether the fish can jump in a certain direction
#define FISH_SHORT_JUMP_MIN_DISTANCE 100
/// The maximum distance for a short jump
#define FISH_SHORT_JUMP_MAX_DISTANCE 200
// Acceleration mod when bait is over fish
#define FISH_ON_BAIT_ACCELERATION_COEFF 0.6
/// The minimum velocity required for the bait to bounce
#define BAIT_MIN_VELOCITY_BOUNCE 200

///Defines to know how the bait is moving on the minigame slider.
#define REELING_STATE_IDLE 0
#define REELING_STATE_UP 1
#define REELING_STATE_DOWN 2

///The height of the minigame bar, which is its icon height, minus 2 on each side
#define MINIGAME_SLIDER_HEIGHT 76
///The standard height of the bait
#define MINIGAME_BAIT_HEIGHT 25

/datum/fishing_challenge
	/// When the ui minigame phase started
	var/start_time
	/// Is it finished (either by win/lose or window closing)
	var/completed = FALSE
	/// Fish AI type to use
	var/fish_ai = FISH_AI_DUMB
	/// Rule modifiers (eg weighted bait)
	var/special_effects = NONE
	/// Did the game get past the baiting phase, used to track if bait should be consumed afterwards
	var/bait_taken = FALSE
	/// Result path
	var/reward_path = FISHING_DUD
	/// Minigame difficulty
	var/difficulty = FISHING_DEFAULT_DIFFICULTY
	// Current phase
	var/phase = WAIT_PHASE
	// Timer for the next phase
	var/next_phase_timer
	/// Fishing mob
	var/mob/user
	/// Rod that is used for the challenge
	var/obj/item/fishing_rod/used_rod
	/// Lure visual
	var/obj/effect/fishing_lure/lure
	/// Background image from /datum/asset/simple/fishing_minigame
	var/background = "default"

	/// Fishing line visual
	var/datum/beam/fishing_line

	var/experience_multiplier = 1

	/// How much space the fish takes on the minigame slider
	var/fish_height = 50
	/// How much space the bait takes on the minigame slider
	var/bait_height = 320
	/// The position of the fish on the minigame slider
	var/fish_position = 0
	/// The position of the bait on the minigame slider
	var/bait_position = 0
	/// The current speed the fish is moving at
	var/fish_velocity = 0
	/// The current speed the bait is moving at
	var/bait_velocity = 0

	/// The completion score. If it reaches 100, it's a win. If it reaches 0, it's a loss.
	var/completion = 30
	/// How much completion is lost per second when the bait area is not intersecting with the fish's
	var/completion_loss = 6
	/// How much completion is gained per second when the bait area is intersecting with the fish's
	var/completion_gain = 5

	/// How likely the fish is to perform a standard jump, then multiplied by difficulty
	var/short_jump_chance = 2.5
	/// How likely the fish is to perform a long jump, then multiplied by difficulty
	var/long_jump_chance = 0.075
	/// The speed limit for the short jump
	var/short_jump_velocity_limit = 400
	/// The speed limit for the long jump
	var/long_jump_velocity_limit = 200
	/// The current speed limit used
	var/current_velocity_limit = 200
	/// The base velocity of the fish, which may affect jump distances and falling speed.
	var/fish_idle_velocity = 0
	/// A position on the slider the fish wants to get to
	var/target_position
	/// If true, the fish can jump while a target position is set, thus overriding it
	var/can_interrupt_move = TRUE

	/// Whether the bait is idle or reeling up or down (left and right click)
	var/reeling_state = REELING_STATE_IDLE
	/// The acceleration of the bait while not reeling
	var/gravity_velocity = -1000
	/// The acceleration of the bait while reeling
	var/reeling_velocity = 1500
	/// By how much the bait recoils back when hitting the bounds of the slider while idle
	var/bait_bounce_coeff = 0.6

	///The background as shown in the minigame, and the holder of the other visual overlays
	var/atom/movable/fishing_hud/fishing_hud

/datum/fishing_challenge/New(datum/component/fishing_spot/comp, reward_path, obj/item/fishing_rod/rod, mob/user)
	src.user = user
	src.reward_path = reward_path
	src.used_rod = rod
	var/atom/spot = comp.parent
	lure = new(get_turf(spot), spot)
	RegisterSignal(spot, COMSIG_QDELETING, PROC_REF(on_spot_gone))
	RegisterSignal(comp.fish_source, COMSIG_FISHING_SOURCE_INTERRUPT_CHALLENGE, PROC_REF(interrupt_challenge))
	comp.fish_source.RegisterSignal(src, COMSIG_FISHING_CHALLENGE_COMPLETED, TYPE_PROC_REF(/datum/fish_source, on_challenge_completed))
	background = comp.fish_source.background
	/// Fish minigame properties
	if(ispath(reward_path,/obj/item/fish))
		var/obj/item/fish/fish = reward_path
		fish_ai = initial(fish.fish_ai_type)
		switch(fish_ai)
			if(FISH_AI_ZIPPY) // Keeps on jumping
				short_jump_chance *= 3
			if(FISH_AI_SLOW) // Only does long jump, and doesn't change direction until it gets there
				short_jump_chance = 0
				long_jump_chance = 1.5
				long_jump_velocity_limit = 150
				long_jump_velocity_limit = FALSE
		// Apply fish trait modifiers
		var/list/fish_list_properties = collect_fish_properties()
		var/list/fish_traits = fish_list_properties[fish][NAMEOF(fish, fish_traits)]
		for(var/fish_trait in fish_traits)
			var/datum/fish_trait/trait = GLOB.fish_traits[fish_trait]
			trait.minigame_mod(rod, user, src)
	/// Enable special parameters
	if(rod.line)
		if(rod.line.fishing_line_traits & FISHING_LINE_BOUNCY)
			completion_loss -= 2
	if(rod.hook)
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_WEIGHTED)
			bait_bounce_coeff = 0.1
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_BIDIRECTIONAL)
			special_effects |= FISHING_MINIGAME_RULE_BIDIRECTIONAL
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_NO_ESCAPE)
			special_effects |= FISHING_MINIGAME_RULE_NO_ESCAPE
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_ENSNARE)
			completion_loss -= 2
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_KILL)
			special_effects |= FISHING_MINIGAME_RULE_KILL

	if(special_effects & FISHING_MINIGAME_RULE_KILL && ispath(reward_path,/obj/item/fish))
		RegisterSignal(user, COMSIG_MOB_FISHING_REWARD_DISPENSED, PROC_REF(hurt_fish))

	difficulty += comp.fish_source.calculate_difficulty(reward_path, rod, user, src)
	difficulty = round(difficulty)

	/**
	 * If the chances are higher than 1% (100% at maximum difficulty), they'll grow exponentially
	 * and not linearly. This way we ensure fish with high jump chances won't get TOO jumpy until
	 * they near the maximum difficulty, at which they hit 100%
	 */
	var/square_angle_rad = TORADIANS(90)
	var/zero_one_difficulty = difficulty/100
	if(short_jump_chance > 1)
		short_jump_chance = (zero_one_difficulty**(square_angle_rad-TORADIANS(arctan(short_jump_chance * 1/square_angle_rad))))*100
	else
		short_jump_chance *= difficulty
	if(long_jump_chance > 1)
		long_jump_chance = (zero_one_difficulty**(square_angle_rad-TORADIANS(arctan(long_jump_chance * 1/square_angle_rad))))*100
	else
		long_jump_chance *= difficulty
	bait_height -= difficulty

/datum/fishing_challenge/Destroy(force, ...)
	if(!completed)
		complete(win = FALSE)
	if(fishing_line)
		QDEL_NULL(fishing_line)
	if(lure)
		QDEL_NULL(lure)
	user = null
	used_rod = null
	return ..()

/datum/fishing_challenge/proc/send_alert(message)
	var/turf/lure_turf = get_turf(lure)
	lure_turf?.balloon_alert(user, message)

/datum/fishing_challenge/proc/on_spot_gone(datum/source)
	send_alert("fishing spot gone!")
	interrupt(balloon_alert = FALSE)

/datum/fishing_challenge/proc/interrupt_challenge(datum/source, reason)
	if(reason)
		send_alert(reason)
	interrupt(balloon_alert = FALSE)

/datum/fishing_challenge/proc/start(mob/living/user)
	/// Create fishing line visuals
	fishing_line = used_rod.create_fishing_line(lure, target_py = 5)
	// If fishing line breaks los / rod gets dropped / deleted
	RegisterSignal(fishing_line, COMSIG_FISHING_LINE_SNAPPED, PROC_REF(interrupt))
	RegisterSignal(used_rod, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))
	ADD_TRAIT(user, TRAIT_GONE_FISHING, REF(src))
	user.add_mood_event("fishing", /datum/mood_event/fishing)
	RegisterSignal(user, COMSIG_MOB_CLICKON, PROC_REF(handle_click))
	start_baiting_phase()
	to_chat(user, span_notice("You start fishing..."))
	playsound(lure, 'sound/effects/splash.ogg', 100)

/datum/fishing_challenge/proc/handle_click(mob/source, atom/target, modifiers)
	SIGNAL_HANDLER
	//You need to be holding the rod to use it.
	if(!source.get_active_held_item(used_rod) || LAZYACCESS(modifiers, SHIFT_CLICK))
		return
	if(phase == WAIT_PHASE) //Reset wait
		send_alert("miss!")
		start_baiting_phase()
	else if(phase == BITING_PHASE)
		INVOKE_ASYNC(src, PROC_REF(start_minigame_phase))
	return COMSIG_MOB_CANCEL_CLICKON

/// Challenge interrupted by something external
/datum/fishing_challenge/proc/interrupt(datum/source, balloon_alert = TRUE)
	SIGNAL_HANDLER
	if(!completed)
		experience_multiplier *= 0.5
		if(balloon_alert)
			send_alert(user.is_holding(used_rod) ? "line snapped" : "tool dropped")
		complete(FALSE)

/datum/fishing_challenge/proc/on_attack_self(obj/item/source, mob/user)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(stop_fishing), source, user)

/datum/fishing_challenge/proc/stop_fishing(obj/item/rod, mob/user)
	if((phase != MINIGAME_PHASE || do_after(user, 3 SECONDS, rod)) && !QDELETED(src) && !completed)
		experience_multiplier *= 0.5
		send_alert("stopped fishing")
		complete(FALSE)

/datum/fishing_challenge/proc/complete(win = FALSE)
	deltimer(next_phase_timer)
	completed = TRUE
	if(phase == MINIGAME_PHASE)
		remove_minigame_hud()
	if(user)
		REMOVE_TRAIT(user, TRAIT_GONE_FISHING, REF(src))
		if(start_time)
			var/seconds_spent = (world.time - start_time)/10
			if(!(special_effects & FISHING_MINIGAME_RULE_NO_EXP))
				user.mind?.adjust_experience(/datum/skill/fishing, min(round(seconds_spent * FISHING_SKILL_EXP_PER_SECOND * experience_multiplier), FISHING_SKILL_EXP_CAP_PER_GAME))
				if(win && user.mind?.get_skill_level(/datum/skill/fishing) >= SKILL_LEVEL_LEGENDARY)
					user.client?.give_award(/datum/award/achievement/skill/legendary_fisher, user)
	if(win)
		if(reward_path != FISHING_DUD)
			playsound(lure, 'sound/effects/bigsplash.ogg', 100)
	SEND_SIGNAL(src, COMSIG_FISHING_CHALLENGE_COMPLETED, user, win)
	qdel(src)

/datum/fishing_challenge/proc/start_baiting_phase()
	deltimer(next_phase_timer)
	phase = WAIT_PHASE
	//Bobbing animation
	animate(lure, pixel_y = 1, time = 1 SECONDS, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_y = -1, time = 1 SECONDS, flags = ANIMATION_RELATIVE)
	//Setup next phase
	var/wait_time = rand(1 SECONDS, 30 SECONDS)
	next_phase_timer = addtimer(CALLBACK(src, PROC_REF(start_biting_phase)), wait_time, TIMER_STOPPABLE)

/datum/fishing_challenge/proc/start_biting_phase()
	phase = BITING_PHASE
	// Trashing animation
	playsound(lure, 'sound/effects/fish_splash.ogg', 100)
	send_alert("!!!")
	animate(lure, pixel_y = 3, time = 5, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_y = -3, time = 5, flags = ANIMATION_RELATIVE)
	// Setup next phase
	var/wait_time = rand(3 SECONDS, 6 SECONDS)
	next_phase_timer = addtimer(CALLBACK(src, PROC_REF(start_baiting_phase)), wait_time, TIMER_STOPPABLE)

///The damage dealt per second to the fish when FISHING_MINIGAME_RULE_KILL is active.
#define FISH_DAMAGE_PER_SECOND 2

///The player is no longer around to play the minigame, so we interrupt it.
/datum/fishing_challenge/proc/on_user_logout(datum/source)
	SIGNAL_HANDLER
	interrupt(balloon_alert = FALSE)

/datum/fishing_challenge/proc/win_anyway()
	if(!completed)
		//winning by timeout or idling around shouldn't give as much experience.
		experience_multiplier *= 0.5
		complete(TRUE)

/datum/fishing_challenge/proc/hurt_fish(datum/source, obj/item/fish/reward)
	SIGNAL_HANDLER
	if(istype(reward))
		var/damage = CEILING((world.time - start_time)/10 * FISH_DAMAGE_PER_SECOND, 1)
		reward.adjust_health(reward.health - damage)

/datum/fishing_challenge/proc/start_minigame_phase()
	if(!prepare_minigame_hud())
		return
	phase = MINIGAME_PHASE
	deltimer(next_phase_timer)
	if((FISHING_MINIGAME_RULE_KILL in special_effects) && ispath(reward_path,/obj/item/fish))
		var/obj/item/fish/fish = reward_path
		var/wait_time = (initial(fish.health) / FISH_DAMAGE_PER_SECOND) SECONDS
		addtimer(CALLBACK(src, PROC_REF(win_anyway)), wait_time)
	start_time = world.time
	experience_multiplier += difficulty * FISHING_SKILL_DIFFIULTY_EXP_MULT

#undef FISH_DAMAGE_PER_SECOND

/datum/fishing_challenge/proc/prepare_minigame_hud()
	if(!user.client || user.incapacitated())
		return FALSE
	. = TRUE
	RegisterSignal(user, COMSIG_MOB_LOGOUT, PROC_REF(on_user_logout))
	SSfishing.begin_minigame_process(src)

/datum/fishing_challenge/proc/remove_minigame_hud()
	SSfishing.end_minigame_process(src)
	QDEL_NULL(fishing_hud)

/datum/fishing_challenge/process(seconds_per_tick)
	move_fish(seconds_per_tick)
	move_bait(seconds_per_tick)
	update_visuals()

/datum/fishing_challenge/proc/move_fish(seconds_per_tick)
	var/long_chance = long_jump_chance * seconds_per_tick * 10
	var/short_chance = short_jump_chance * seconds_per_tick * 10

	// If we have the target but we're close enough, mark as target reached
	if(abs(target_position - fish_position) < FISH_TARGET_MIN_DISTANCE)
		target_position = null

	// Switching to new long jump target can interrupt any other
	if((can_interrupt_move || isnull(target_position)) && prob(long_chance))
		/**
		 * Move at least 0.75 to full of the availible bar in given direction,
		 * and more likely to move in the direction where there's more space
		 */
		var/distance_from_top = FISHING_MINIGAME_HEIGHT - fish_position - fish_height
		var/distance_from_bottom = fish_position
		var/top_chance
		if(distance_from_top < FISH_TARGET_MIN_DISTANCE)
			top_chance = 0
		else
			top_chance = (distance_from_top/max(distance_from_bottom, 1)) * 100
		var/new_target = fish_position
		if(prob(top_chance))
			new_target += distance_from_top * rand(75, 100)/100
		else
			new_target -= distance_from_bottom * rand(75, 100)/100
		target_position = round(new_target)
		current_velocity_limit = long_jump_velocity_limit

	// Move towards target
	if(isnull(target_position))
		var/distance = target_position - fish_position
		// about 5 at diff 15 , 10 at diff 30, 30 at diff 100
		var/acceleration_coeff = 0.3 * difficulty + 0.5
		var/target_acceleration = distance * acceleration_coeff * seconds_per_tick

		fish_velocity = fish_velocity * FISH_FRICTION_COEFF + target_acceleration
	else if(prob(short_chance))
		var/distance_from_top = FISHING_MINIGAME_HEIGHT - fish_position - fish_height
		var/distance_from_bottom = fish_position
		var/jump_length
		if(distance_from_top > FISH_SHORT_JUMP_MIN_DISTANCE)
			jump_length = rand(FISH_SHORT_JUMP_MIN_DISTANCE, FISH_SHORT_JUMP_MAX_DISTANCE)
		if(distance_from_bottom > FISH_SHORT_JUMP_MIN_DISTANCE && (!jump_length || prob(50)))
			jump_length = -rand(FISH_SHORT_JUMP_MIN_DISTANCE, FISH_SHORT_JUMP_MAX_DISTANCE)
		target_position = clamp(fish_position + jump_length, 0, FISHING_MINIGAME_HEIGHT - fish_height)
		current_velocity_limit = short_jump_velocity_limit

	fish_velocity = clamp(fish_velocity + fish_idle_velocity, -current_velocity_limit, current_velocity_limit)
	fish_position = clamp(fish_position + fish_velocity * seconds_per_tick, 0, FISHING_MINIGAME_HEIGHT - fish_height)

/datum/fishing_challenge/proc/move_bait(seconds_per_tick)
	var/should_bounce = abs(bait_velocity) > BAIT_MIN_VELOCITY_BOUNCE
	bait_position += bait_velocity * seconds_per_tick
	// Hitting the top bound
	if(bait_position + bait_height > FISHING_MINIGAME_HEIGHT)
		bait_position = FISHING_MINIGAME_HEIGHT
		if(reeling_state == REELING_STATE_UP || !should_bounce)
			bait_velocity = 0
		else
			bait_velocity = -bait_velocity * bait_bounce_coeff
	// Hitting rock bottom
	else if(bait_position < 0)
		bait_position = 0
		if(reeling_state == REELING_STATE_DOWN || !should_bounce)
			bait_velocity = 0
		else
			bait_velocity = -bait_velocity * bait_bounce_coeff

	var/fish_on_bait = (fish_position + fish_height >= bait_position) && (bait_position + bait_height >= fish_position)

	var/velocity_change
	switch(reeling_state)
		if(REELING_STATE_UP)
			velocity_change = reeling_velocity
		if(REELING_STATE_DOWN)
			velocity_change = -reeling_velocity
		if(REELING_STATE_IDLE)
			velocity_change = gravity_velocity
	velocity_change *= (fish_on_bait ? FISH_ON_BAIT_ACCELERATION_COEFF : 1) * seconds_per_tick

	velocity_change = round(velocity_change)

	///bidirectional baits stay bouyant while idle
	if(special_effects & FISHING_MINIGAME_RULE_BIDIRECTIONAL && reeling_state == REELING_STATE_IDLE && velocity_change < 0)
		bait_velocity = max(bait_velocity + velocity_change, 0)
	else
		bait_velocity += velocity_change

	//check that the fish area is still intersecting the bait now that it has moved
	fish_on_bait = (fish_position + fish_height >= bait_position) && (bait_position + bait_height >= fish_position)

	if(fish_on_bait)
		completion += completion_gain * seconds_per_tick
	else
		completion -= completion_loss * seconds_per_tick

	completion = clamp(completion, 0, 100)

/datum/fishing_challenge/proc/update_visuals()

/// The visual that appears over the fishing spot
/obj/effect/fishing_lure
	icon = 'icons/obj/fishing.dmi'
	icon_state = "lure_idle"

/obj/effect/fishing_lure/Initialize(mapload, atom/spot)
	. = ..()
	if(ismovable(spot)) // we want the lure and therefore the fishing line to stay connected with the fishing spot.
		RegisterSignal(spot, COMSIG_MOVABLE_MOVED, PROC_REF(follow_movable))

/obj/effect/fishing_lure/proc/follow_movable(atom/movable/source)
	set_glide_size(source.glide_size)
	forceMove(source.loc)

/atom/movable/fishing_hud
	icon = 'icons/hud/fishing_hud.dmi'
	screen_loc = "CENTER+1:10,CENTER-1:8"
	///The fish as shown in the minigame
	var/atom/movable/hud_fish
	///The bait as shown in the minigame
	var/atom/movable/hud_bait
	///The completion bar as shown in the minigame
	var/atom/movable/hud_completion

/atom/movable/fishing_hud/Initialize(mapload, datum/fishing_challenge/challenge)
	. = ..()
	if(!challenge) //create and destroy, mayhaps.
		return
	icon_state = challenge.background
	add_overlay("frame")
	hud_bait = new
	hud_bait.icon = icon
	hud_bait.icon_state = "bait"
	var/static/icon/cut_bait_mask = icon(icon, "cut_bait")
	var/new_sprite_height = round(MINIGAME_BAIT_HEIGHT * (challenge.bait_height/initial(challenge.bait_height)), 1)
	if(new_sprite_height < MINIGAME_BAIT_HEIGHT)
		var/size = MINIGAME_BAIT_HEIGHT - new_sprite_height
		hud_bait.add_filter("Cut_Bait", 1, displacement_map_filter(cut_bait_mask, x = 0, y = 0, size = size))
	vis_contents += hud_bait
	hud_fish = new
	hud_fish.icon = icon
	hud_fish.icon_state = "fish"
	vis_contents += hud_fish
	hud_completion = new
	hud_completion.icon = icon
	hud_completion.icon_state = "completion_[FLOOR(challenge.completion, 5)]"
	vis_contents += hud_completion
	challenge.user.client.screen += src

/atom/movable/fishing_hud/Destroy()
	QDEL_NULL(hud_fish)
	QDEL_NULL(hud_bait)
	QDEL_NULL(hud_completion)
	return ..()

#undef WAIT_PHASE
#undef BITING_PHASE
#undef MINIGAME_PHASE

#undef FISHING_MINIGAME_HEIGHT
#undef FISH_TARGET_MIN_DISTANCE
#undef FISH_FRICTION_COEFF
#undef FISH_SHORT_JUMP_MIN_DISTANCE
#undef FISH_SHORT_JUMP_MAX_DISTANCE
#undef FISH_ON_BAIT_ACCELERATION_COEFF
#undef BAIT_MIN_VELOCITY_BOUNCE

#undef MINIGAME_SLIDER_HEIGHT
#undef MINIGAME_BAIT_HEIGHT

#undef REELING_STATE_IDLE
#undef REELING_STATE_UP
#undef REELING_STATE_DOWN

