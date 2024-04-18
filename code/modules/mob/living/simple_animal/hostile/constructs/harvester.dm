/mob/living/simple_animal/hostile/construct/harvester
	name = "Harvester"
	real_name = "Harvester"
	desc = "A long, thin construct built to herald Nar'Sie's rise. It'll be all over soon."
	icon_state = "harvester"
	icon_living = "harvester"
	maxHealth = 40
	health = 40
	sight = SEE_MOBS
	melee_damage_lower = 15
	melee_damage_upper = 20
	attack_verb_continuous = "butchers"
	attack_verb_simple = "butcher"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	construct_spells = list(
		/datum/action/cooldown/spell/aoe/area_conversion,
		/datum/action/cooldown/spell/forcewall/cult,
	)
	playstyle_string = "<B>You are a Harvester. You are incapable of directly killing humans, \
		but your attacks will remove their limbs: Bring those who still cling to this world \
		of illusion back to the Geometer so they may know Truth. Your form and any you are \
		pulling can pass through runed walls effortlessly.</B>"
	can_repair = TRUE
	slowed_by_drag = FALSE
	var/list/passable_atoms = list(
		/obj/machinery/door/airlock/cult,
		/obj/structure/girder/cult,
		/obj/structure/table/wood,
		/turf/closed/wall/mineral/cult,
		// Add windows and windoors here when narsie_act() doesn't just change their fuckin' color
	)
	var/datum/action/innate/seek_prey/seek

/mob/living/simple_animal/hostile/construct/harvester/Initialize(mapload)
	. = ..()
	seek = new()
	seek.Grant(src)
	seek.Activate()

/mob/living/simple_animal/hostile/construct/harvester/Bump(atom/thing)
	. = ..()
	if(thing == loc)
		return
	// We force move through anything in passable_atoms or that passes a snowflake check.
	if(!is_type_in_list(thing, passable_atoms) && !snowflake_check(thing))
		return
	var/atom/movable/stored_pulling = pulling

	if(stored_pulling)
		stored_pulling.setDir(get_dir(stored_pulling.loc, loc))
		stored_pulling.forceMove(loc)
	forceMove(thing)

	if(stored_pulling)
		start_pulling(stored_pulling, supress_message = TRUE) //drag anything we're pulling through the wall with us by magic

/mob/living/simple_animal/hostile/construct/harvester/proc/snowflake_check(atom/thing)
	return

/mob/living/simple_animal/hostile/construct/harvester/proc/snowflake_attack_check(mob/target)
	return TRUE

/mob/living/simple_animal/hostile/construct/harvester/AttackingTarget()
	if(!iscarbon(target))
		return ..()

	if(target == src)
		to_chat(src, span_warning("That's probably a bad idea."))
		return FALSE

	var/mob/living/carbon/victim = target
	if(HAS_TRAIT(victim, TRAIT_NODISMEMBER))
		return ..() //ATTACK!

	if(!snowflake_attack_check(target))
		return ..()

	var/list/parts = list()
	var/strong_limbs = 0

	for(var/obj/item/bodypart/limb as anything in victim.bodyparts)
		if(limb.body_part == HEAD || limb.body_part == CHEST)
			continue
		if(!(limb.bodypart_flags & BODYPART_UNREMOVABLE))
			parts += limb
		else
			strong_limbs++

	if(!LAZYLEN(parts))
		if(strong_limbs) // they have limbs we can't remove, and no parts we can, attack!
			return ..()
		victim.Paralyze(60)
		visible_message(span_danger("[src] knocks [victim] down!"))
		to_chat(src, span_cultlarge("\"Bring [victim.p_them()] to me.\""))
		return FALSE

	do_attack_animation(victim)
	var/obj/item/bodypart/limb = pick(parts)
	limb.dismember()
	return FALSE

/datum/action/innate/seek_master
	name = "Seek your Master"
	desc = "You and your master share a soul-link that informs you of their location"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"

	buttontooltipstyle = "cult"
	button_icon = "icons/mob/actions/actions_cult.dmi"
	button_icon_state = "cult_mark"
	/// Where is nar nar? Are we even looking?
	var/tracking = FALSE
	/// The construct we're attached to
	var/mob/living/simple_animal/hostile/construct/the_construct

/datum/action/innate/seek_master/Grant(mob/living/player)
	the_construct = player
	..()

/datum/action/innate/seek_master/Activate()
	var/datum/antagonist/cult/cult_status = owner.mind.has_antag_datum(/datum/antagonist/cult)
	if(!cult_status)
		return
	var/datum/objective/eldergod/summon_objective = locate() in cult_status.cult_team.objectives

	if(summon_objective.check_completion())
		the_construct.master = cult_status.cult_team.blood_target

	if(!the_construct.master)
		to_chat(the_construct, span_cultitalic("You have no master to seek!"))
		the_construct.seeking = FALSE
		return
	if(tracking)
		tracking = FALSE
		the_construct.seeking = FALSE
		to_chat(the_construct, span_cultitalic("You are no longer tracking your master."))
		return
	else
		tracking = TRUE
		the_construct.seeking = TRUE
		to_chat(the_construct, span_cultitalic("You are now tracking your master."))


/datum/action/innate/seek_prey
	name = "Seek the Harvest"
	desc = "None can hide from Nar'Sie, activate to track a survivor attempting to flee the red harvest!"
	button_icon = 'icons/mob/actions/actions_cult.dmi'
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"

	buttontooltipstyle = "cult"
	button_icon_state = "cult_mark"

/datum/action/innate/seek_prey/Activate()
	if(GLOB.cult_narsie == null)
		return
	var/mob/living/simple_animal/hostile/construct/harvester/the_construct = owner

	if(the_construct.seeking)
		desc = "None can hide from Nar'Sie, activate to track a survivor attempting to flee the red harvest!"
		button_icon_state = "cult_mark"
		the_construct.seeking = FALSE
		to_chat(the_construct, span_cultitalic("You are now tracking Nar'Sie, return to reap the harvest!"))
		return

	if(!LAZYLEN(GLOB.cult_narsie.souls_needed))
		to_chat(the_construct, span_cultitalic("Nar'Sie has completed her harvest!"))
		return

	the_construct.master = pick(GLOB.cult_narsie.souls_needed)
	var/mob/living/real_target = the_construct.master //We can typecast this way because Narsie only allows /mob/living into the souls list
	to_chat(the_construct, span_cultitalic("You are now tracking your prey, [real_target.real_name] - harvest [real_target.p_them()]!"))
	desc = "Activate to track Nar'Sie!"
	button_icon_state = "sintouch"
	the_construct.seeking = TRUE

/mob/living/simple_animal/hostile/construct/harvester/heretic
	name = "Rusted Harvester"
	real_name = "Rusted Harvester"
	desc = "A long, thin, decrepit construct originally built to herald Nar'Sie's rise, corrupted and rusted by the forces of the Mansus to spread their will instead."
	icon_state = "harvester"
	icon_living = "harvester"
	maxHealth = 40
	health = 40
	sight = SEE_MOBS
	melee_damage_lower = 15
	melee_damage_upper = 20
	attack_verb_continuous = "butchers"
	attack_verb_simple = "butcher"
	// Dim green
	lighting_cutoff_red = 10
	lighting_cutoff_green = 5
	lighting_cutoff_blue = 20
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	construct_spells = list(
		/datum/action/cooldown/spell/aoe/rust_conversion,
		/datum/action/cooldown/spell/pointed/rust_construction,
	)
	playstyle_string = "<B>You are a Rusted Harvester, built to serve the Sanguine Apostate, twisted to work the will of the Mansus. You are fragile and weak, but you rend cultists (only) apart on each attack. Follow your Master's orders!<B>"
	theme = THEME_HERETIC
	passable_atoms = list()

/mob/living/simple_animal/hostile/construct/harvester/Initialize(mapload)
	. = ..()
	qdel(seek)
	ADD_TRAIT(src, TRAIT_MANSUS_TOUCHED, REF(src))
	add_filter("rusted_harvester", 3, list("type" = "outline", "color" = COLOR_GREEN, "size" = 2, "alpha" = 40))

/mob/living/simple_animal/hostile/construct/harvester/heretic/snowflake_check(atom/thing)
	if(HAS_TRAIT(thing, TRAIT_RUSTY) && isturf(thing))
		return TRUE

	//thing.AddElement(/datum/element/rust)

// If cultist delimb! If not attack normally.
/mob/living/simple_animal/hostile/construct/harvester/snowflake_attack_check(mob/target)
	return IS_CULTIST(target)
