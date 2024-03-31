#define GOKU_FILTER "goku_filter"

/// The Saiyan brain contains knowledge of powerful martial arts
/obj/item/organ/internal/brain/saiyan
	name = "saiyan brain"
	desc = "The brain of a mighty saiyan warrior. Guess they don't work out at the library..."
	brain_size = 0.5
	/// What buttons did we give out
	var/list/granted_abilities = list()
	/// Saiyans gain one of these cool karate moves at random
	var/static/list/saiyan_skills = list(
		/datum/action/cooldown/mob_cooldown/brimbeam/kamehameha,
		/datum/action/cooldown/mob_cooldown/kaioken,
		/datum/action/cooldown/mob_cooldown/super_saiyan,
		/datum/action/cooldown/mob_cooldown/watcher_gaze/solar_flare,
		/datum/action/cooldown/mob_cooldown/ultra_instinct,
	)

/obj/item/organ/internal/brain/saiyan/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	var/datum/action/cooldown/mob_cooldown/ki_blast/blast = new(organ_owner)
	blast.Grant(organ_owner)
	granted_abilities += blast

	var/datum/action/cooldown/mob_cooldown/saiyan_flight/flight = new(organ_owner)
	flight.Grant(organ_owner)
	granted_abilities += flight

	var/random_skill_path = pick(saiyan_skills)
	var/datum/action/random_skill = new random_skill_path(organ_owner)
	random_skill.Grant(organ_owner)
	granted_abilities += random_skill

/obj/item/organ/internal/brain/saiyan/on_mob_remove(mob/living/carbon/organ_owner, special)
	. = ..()
	QDEL_LIST(granted_abilities)

/// Shoot power from your hands, wow
/datum/action/cooldown/mob_cooldown/ki_blast
	name = "Ki Blast"
	desc = "Channel your ki into your hands and out into the world as rapid projectiles. Drains your fighting spirit."
	button_icon = 'icons/obj/weapons/guns/projectiles.dmi'
	button_icon_state = "pulse1"
	background_icon_state = "bg_demon"
	click_to_activate = FALSE
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED|AB_CHECK_HANDS_BLOCKED
	shared_cooldown = NONE
	melee_cooldown_time = 0 SECONDS
	/// Extra damage to do
	var/damage_modifier = 1

/datum/action/cooldown/mob_cooldown/ki_blast/Activate(atom/target)
	var/mob/living/mob_caster = target
	if (!istype(mob_caster))
		return FALSE
	var/obj/item/gun/ki_blast/ki_gun = new(mob_caster.loc)
	ki_gun.projectile_damage_multiplier = damage_modifier
	if (!mob_caster.put_in_hands(ki_gun, del_on_fail = TRUE))
		mob_caster.balloon_alert(mob_caster, "no free hands!")
	return TRUE

/obj/item/gun/ki_blast
	name = "concentrated ki"
	desc = "The power of your lifeforce converted into a deadly weapon. Fire it at someone."
	fire_sound = 'sound/magic/wand_teleport.ogg'
	icon = 'icons/obj/weapons/guns/projectiles.dmi'
	icon_state = "pulse1"
	inhand_icon_state = "arcane_barrage"
	base_icon_state = "arcane_barrage"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	slot_flags = null
	item_flags = NEEDS_PERMIT | DROPDEL | ABSTRACT | NOBLUDGEON
	flags_1 = NONE
	trigger_guard = TRIGGER_GUARD_ALLOW_ALL

/obj/item/gun/ki_blast/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.15 SECONDS)
	chambered = new /obj/item/ammo_casing/ki(src)

/obj/item/gun/ki_blast/process_fire(atom/target, mob/living/user, message, params, zone_override, bonus_spread)
	. = ..()
	if (!.)
		return FALSE
	user.apply_damage(3, STAMINA)
	return TRUE

/obj/item/gun/ki_blast/handle_chamber(empty_chamber, from_firing, chamber_next_round)
	chambered.newshot()

/obj/item/ammo_casing/ki
	slot_flags = null
	projectile_type = /obj/projectile/ki
	firing_effect_type = /obj/effect/temp_visual/dir_setting/firing_effect/blue

/obj/projectile/ki
	name = "ki blast"
	icon_state = "pulse1_bl"
	damage = 3
	damage_type = BRUTE
	hitsound = 'sound/weapons/sear_disabler.ogg'
	hitsound_wall = 'sound/weapons/sear_disabler.ogg'
	light_system = OVERLAY_LIGHT
	light_range = 1
	light_power = 1.4
	light_color = LIGHT_COLOR_CYAN

/// Saiyans can fly
/datum/action/cooldown/mob_cooldown/saiyan_flight
	name = "Flight"
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "flight"
	background_icon_state = "bg_demon"
	desc = "Focus your energy and lift into the air, or alternately stop doing that if you are doing it already."
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_IMMOBILE|AB_CHECK_INCAPACITATED|AB_CHECK_LYING
	click_to_activate = FALSE
	cooldown_time = 3 SECONDS
	shared_cooldown = NONE
	melee_cooldown_time = 0 SECONDS

/datum/action/cooldown/mob_cooldown/saiyan_flight/Activate(atom/target)
	var/mob/living/mob_caster = target
	if (!istype(mob_caster))
		return FALSE

	StartCooldown()
	if(!HAS_TRAIT_FROM(mob_caster, TRAIT_MOVE_FLYING, REF(src)))
		mob_caster.balloon_alert(mob_caster, "flying")
		ADD_TRAIT(mob_caster, TRAIT_MOVE_FLYING, REF(src))
		passtable_on(mob_caster, REF(src))
		return TRUE

	mob_caster.balloon_alert(mob_caster, "landed")
	REMOVE_TRAIT(mob_caster, TRAIT_MOVE_FLYING, REF(src))
	passtable_off(mob_caster, REF(src))
	return TRUE


/// Charge up a big beam
/datum/action/cooldown/mob_cooldown/brimbeam/kamehameha
	name = "Kamehameha"
	desc = "The signature technique of the turtle school, a devastating charged beam attack!"
	button_icon = 'icons/effects/saiyan_effects.dmi'
	button_icon_state = "kamehameha_start"
	created_type = /obj/effect/brimbeam/kamehameha
	charge_duration = 5 SECONDS
	beam_duration = 12 SECONDS
	cooldown_time = 90 SECONDS
	shared_cooldown = NONE
	melee_cooldown_time = 0 SECONDS
	/// Things we still need to say, before it's too late
	var/speech_timers = list()

/datum/action/cooldown/mob_cooldown/brimbeam/kamehameha/Activate(mob/living/target)
	owner.add_filter(GOKU_FILTER, 2, list("type" = "outline", "color" = COLOR_CYAN, "alpha" = 0, "size" = 1))
	var/filter = owner.get_filter(GOKU_FILTER)
	animate(filter, alpha = 200, time = 0.5 SECONDS, loop = -1)
	animate(alpha = 0, time = 0.5 SECONDS)
	owner.say("Ka...")
	var/queued_speech = list("...me...", "...ha...", "...me...")
	var/speech_interval = charge_duration/4
	var/current_interval = speech_interval
	while(length(queued_speech))
		var/timer = addtimer(CALLBACK(owner, TYPE_PROC_REF(/atom/movable, say), pop(queued_speech)), current_interval, TIMER_STOPPABLE | TIMER_DELETE_ME)
		current_interval += speech_interval
		speech_timers += timer
	playsound(owner, 'sound/items/modsuit/loader_charge.ogg', 75, TRUE)

	var/mob/living/living_owner = owner
	var/lightbulb = istype(living_owner) ? living_owner.mob_light(2, 1, LIGHT_COLOR_CYAN) : null

	. = ..()

	QDEL_NULL(lightbulb)
	for (var/timer as anything in speech_timers)
		deltimer(timer)
	speech_timers = list()
	animate(filter)
	owner.remove_filter(GOKU_FILTER)

/datum/action/cooldown/mob_cooldown/brimbeam/kamehameha/fire_laser()
	. = ..()
	if (.)
		owner.say("...HA!!!!!")

/datum/action/cooldown/mob_cooldown/brimbeam/kamehameha/on_fail()
	owner.visible_message(span_notice("...and launches it straight into a wall, wasting their energy."))

/// It's blue now!
/obj/effect/brimbeam/kamehameha
	name = "kamehameha"
	light_color = LIGHT_COLOR_CYAN
	icon = 'icons/effects/saiyan_effects.dmi'
	icon_state = "kamehameha"
	base_icon_state = "kamehameha"

/// Blinds people
/datum/action/cooldown/mob_cooldown/watcher_gaze/solar_flare
	name = "Solar Flare"
	desc = "A surprising move of the Crane school, creating a blinding flash that can overpower even shaded glasses. Useful on opponents regardless of power level."
	wait_delay = 1 SECONDS
	report_started = "holds their hands to their forehead!"
	blinded_source = "flash of light!"
	stop_self = FALSE

/datum/action/cooldown/mob_cooldown/watcher_gaze/solar_flare/trigger_effect()
	. = ..()
	owner.say("Solar flare!!")

/// Makes you stronger and stacks too. But watch out!
/datum/action/cooldown/mob_cooldown/kaioken
	name = "Kaio-ken Technique"
	desc = "A technique taught by the powerful Kais of Otherworld, allows the user to multiply their ki at great personal risk. The effects can be stacked multiplicatively to greatly increase fighting strength, however overuse may cause immediate disintegration."
	button_icon = 'icons/mob/actions/actions_cult.dmi'
	button_icon_state = "tele"
	background_icon_state = "bg_demon"
	cooldown_time = 3 SECONDS
	shared_cooldown = NONE
	melee_cooldown_time = NONE
	click_to_activate = FALSE

// This is basically handled entirely by the status effect
/datum/action/cooldown/mob_cooldown/kaioken/Activate(mob/living/target)
	target.apply_status_effect(/datum/status_effect/stacking/kaioken, 1)
	StartCooldown()
	return TRUE

/datum/status_effect/stacking/kaioken
	id = "kaioken"
	stacks = 0
	max_stacks = INFINITY // but good luck
	consumed_on_threshold = FALSE
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH // Allows us to add one stack at a time by just applying the effect
	duration = 10 SECONDS
	stack_decay = 0
	/// How much strength to add every time?
	var/power_multiplier = 3
	/// Percentage chance to die instantly, will be multiplied by current stacks
	var/death_chance = 5
	/// Light holder
	var/lightbulb
	/// What colour was our hair?
	var/previous_hair_colour

/datum/status_effect/stacking/kaioken/on_apply()
	. = ..()
	owner.add_filter(GOKU_FILTER, 2, list("type" = "outline", "color" = COLOR_SOFT_RED, "alpha" = 0, "size" = 1))
	var/filter = owner.get_filter(GOKU_FILTER)
	animate(filter, alpha = 200, time = 0.5 SECONDS, loop = -1)
	animate(alpha = 0, time = 0.5 SECONDS)
	lightbulb = owner.mob_light(2, 1, LIGHT_COLOR_BUBBLEGUM)

	ADD_TRAIT(owner, TRAIT_POWER_HAIR, "[STATUS_EFFECT_TRAIT]_[id]")
	if (ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		previous_hair_colour = human_owner.hair_color
		human_owner.set_haircolor(COLOR_SOFT_RED, update = TRUE)

/datum/status_effect/stacking/kaioken/on_remove()
	QDEL_NULL(lightbulb)
	var/filter = owner.get_filter(GOKU_FILTER)
	animate(filter)
	owner.remove_filter(GOKU_FILTER)
	owner.saiyan_boost(-power_multiplier * stacks)

	REMOVE_TRAIT(owner, TRAIT_POWER_HAIR, "[STATUS_EFFECT_TRAIT]_[id]")
	if (ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.set_haircolor(previous_hair_colour, update = TRUE)
	return ..()

/datum/status_effect/stacking/kaioken/refresh(effect, stacks_to_add)
	. = ..()
	add_stacks(stacks_to_add)

/datum/status_effect/stacking/kaioken/add_stacks(stacks_added)
	if (stacks_added == 0)
		return
	. = ..()
	if (stacks == 0)
		return
	if (prob((stacks - 1) * death_chance))
		owner.say("Kaio-AARGH!!")
		owner.visible_message(span_boldwarning("[owner] vanishes in an intense flash of light!"))
		owner.ghostize(can_reenter_corpse = FALSE)
		owner.dust()
		return
	owner.saiyan_boost(power_multiplier)
	if (stacks == 1)
		owner.say("Kaio-ken!")
		return
	var/exclamations = ""
	for (var/i in 1 to stacks)
		exclamations += "!"
	owner.say("Kaio-ken... times [convert_integer_to_words(stacks)][exclamations]")

/// Achieve the legend
/datum/action/cooldown/mob_cooldown/super_saiyan
	name = "Power Up"
	desc = "Concentrate your energy, surpass your limits, and go even further beyond!"
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "sacredflame"
	background_icon_state = "bg_demon"
	cooldown_time = 4 MINUTES
	cooldown_rounding = 0
	shared_cooldown = NONE
	melee_cooldown_time = NONE
	click_to_activate = FALSE
	/// How long does it take to assume your next form?
	var/charge_time = 30 SECONDS
	/// Storage for our scream timer
	var/yell_timer

/datum/action/cooldown/mob_cooldown/super_saiyan/Activate(mob/living/target)
	StartCooldown(360 SECONDS)

	target.add_filter(GOKU_FILTER, 2, list("type" = "outline", "color" = COLOR_GOLD, "alpha" = 0, "size" = 1))
	var/filter = target.get_filter(GOKU_FILTER)
	animate(filter, alpha = 200, time = 0.5 SECONDS, loop = -1)
	animate(alpha = 0, time = 0.5 SECONDS)
	yell()

	var/lightbulb = target.mob_light(3, 1, LIGHT_COLOR_BRIGHT_YELLOW)

	owner.balloon_alert(owner, "charging...")
	var/succeeded = do_after(target, delay = charge_time, target = target)

	deltimer(yell_timer)
	animate(filter)
	target.remove_filter(GOKU_FILTER)
	QDEL_NULL(lightbulb)

	if (succeeded)
		charge_time = max(6 SECONDS, charge_time - 2 SECONDS)
		target.apply_status_effect(/datum/status_effect/super_saiyan)
		StartCooldown()
		return TRUE

	StartCooldown(10 SECONDS)
	return TRUE

/// Aaaaaaa Aaaaaaaa aaaaaa AAAAAAAa a AaAAAAAA aAAAAAAAAAAAAAAAAAAAAAAA!!!!
/datum/action/cooldown/mob_cooldown/super_saiyan/proc/yell()
	owner.emote("scream")
	yell_timer = addtimer(CALLBACK(src, PROC_REF(yell)), rand(1 SECONDS, 3 SECONDS), TIMER_DELETE_ME | TIMER_STOPPABLE)

/datum/status_effect/super_saiyan
	id = "super_saiyan"
	alert_type = null
	duration = 45 SECONDS
	/// How much strength do we gain?
	var/power_multiplier = 8
	/// What colour was our hair?
	var/previous_hair_colour
	/// Light holder
	var/atom/lightbulb

/datum/status_effect/super_saiyan/on_apply()
	. = ..()
	to_chat(owner, span_notice("Your power surges!"))

	new /obj/effect/temp_visual/explosion/fast(get_turf(owner))
	ADD_TRAIT(owner, TRAIT_POWER_HAIR, "[STATUS_EFFECT_TRAIT]_[id]")

	if (ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		previous_hair_colour = human_owner.hair_color
		human_owner.set_haircolor(COLOR_GOLD, update = TRUE)

	owner.add_filter(GOKU_FILTER, 2, list("type" = "outline", "color" = COLOR_GOLD, "alpha" = 0, "size" = 2.5))
	var/filter = owner.get_filter(GOKU_FILTER)
	animate(filter, alpha = 200, time = 0.25 SECONDS, loop = -1)
	animate(alpha = 0, time = 0.25 SECONDS)
	owner.saiyan_boost(multiplier = power_multiplier)

	lightbulb = owner.mob_light(5, 1, COLOR_GOLD)

	playsound(owner, 'sound/magic/charge.ogg', vol = 80)

	var/list/destroy_turfs = circle_range_turfs(center = owner, radius = 2)
	for (var/turf/check_turf as anything in destroy_turfs)
		if (!isfloorturf(check_turf) || isindestructiblefloor(check_turf))
			continue
		if (prob(75))
			continue
		check_turf.break_tile()

	var/transform_area = get_area(owner)
	for(var/mob/living/player as anything in GLOB.alive_player_list)
		if (player == owner || !HAS_TRAIT(player, TRAIT_MARTIAL_VISION))
			continue
		to_chat(player, span_warning("You sense an incredible power level coming from the direction of the [transform_area]!"))

/datum/status_effect/super_saiyan/on_remove()
	. = ..()
	QDEL_NULL(lightbulb)

	REMOVE_TRAIT(owner, TRAIT_POWER_HAIR, "[STATUS_EFFECT_TRAIT]_[id]")

	var/filter = owner.get_filter(GOKU_FILTER)
	animate(filter)
	owner.remove_filter(GOKU_FILTER)
	owner.saiyan_boost(multiplier = -power_multiplier)

	if (ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.set_haircolor(previous_hair_colour, update = TRUE)

/// Dodge without thinking
/datum/action/cooldown/mob_cooldown/ultra_instinct
	name = "Ultra Instinct"
	desc = "Clear your mind and instinctually avoid incoming blows, until you take action yourself."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "chuuni"
	background_icon_state = "bg_demon"
	cooldown_time = 90 SECONDS
	shared_cooldown = NONE
	melee_cooldown_time = NONE
	click_to_activate = FALSE

// This is basically handled entirely by the status effect
/datum/action/cooldown/mob_cooldown/ultra_instinct/Activate(mob/living/target)
	target.apply_status_effect(/datum/status_effect/ultra_instinct)
	StartCooldown()
	return TRUE

/datum/status_effect/ultra_instinct
	id = "ultra_instinct"
	alert_type = null
	duration = 90 SECONDS
	/// Light holder
	var/atom/lightbulb
	/// What colour was our hair?
	var/previous_hair_colour

/datum/status_effect/ultra_instinct/on_apply()
	. = ..()
	owner.add_filter(GOKU_FILTER, 2, list("type" = "outline", "color" = COLOR_CYAN, "alpha" = 0, "size" = 2))
	var/filter = owner.get_filter(GOKU_FILTER)
	animate(filter, alpha = 200, time = 0.5 SECONDS, loop = -1)
	animate(alpha = 0, time = 0.5 SECONDS)
	lightbulb = owner.mob_light(2, 1, LIGHT_COLOR_CYAN)

	ADD_TRAIT(owner, TRAIT_POWER_HAIR, "[STATUS_EFFECT_TRAIT]_[id]")
	if (ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		previous_hair_colour = human_owner.hair_color
		human_owner.set_haircolor(COLOR_CYAN, update = TRUE)

	RegisterSignals(owner, list(COMSIG_MOB_ATTACK_HAND, COMSIG_LIVING_GRAB, COMSIG_MOB_ITEM_ATTACK, COMSIG_MOB_THROW), PROC_REF(took_action))
	RegisterSignal(owner, COMSIG_LIVING_CHECK_BLOCK, PROC_REF(on_hit))

/datum/status_effect/ultra_instinct/on_remove()
	QDEL_NULL(lightbulb)
	var/filter = owner.get_filter(GOKU_FILTER)
	animate(filter)
	owner.remove_filter(GOKU_FILTER)

	REMOVE_TRAIT(owner, TRAIT_POWER_HAIR, "[STATUS_EFFECT_TRAIT]_[id]")
	if (ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.set_haircolor(previous_hair_colour, update = TRUE)

	UnregisterSignal(owner, list(
		COMSIG_LIVING_CHECK_BLOCK,
		COMSIG_LIVING_GRAB,
		COMSIG_MOB_ATTACK_HAND,
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_THROW
	))
	return ..()

/// Called when we do something
/datum/status_effect/ultra_instinct/proc/took_action()
	SIGNAL_HANDLER
	qdel(src)

/// Called when something hits us
/datum/status_effect/ultra_instinct/proc/on_hit(mob/living/source)
	SIGNAL_HANDLER
	source.balloon_alert_to_viewers("dodged")
	var/turf/current = get_turf(source)
	var/list/valid_turfs = list()
	for (var/turf/open/check_turf in orange(source, 1))
		if (check_turf.is_blocked_turf(exclude_mobs = FALSE, source_atom = source))
			continue
		valid_turfs += check_turf
	if (length(valid_turfs))
		var/turf/land_turf = pick(valid_turfs)
		source.Move(land_turf, get_dir(current, land_turf))
	new /obj/effect/temp_visual/jet_plume(current)
	return SUCCESSFUL_BLOCK

#undef GOKU_FILTER
