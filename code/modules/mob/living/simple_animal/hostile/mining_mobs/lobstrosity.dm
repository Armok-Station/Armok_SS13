/**
 * Lobstrosities, the poster boy of charging AI mobs. Drops crab meat and bones.
 * Outside of charging, it's intended behavior is that it is generally slow moving, but makes up for that with a knockdown attack to score additional hits.
 */
/mob/living/simple_animal/hostile/asteroid/lobstrosity
	name = "arctic lobstrosity"
	desc = "A marvel of evolution gone wrong, the frosty ice produces underground lakes where these ill tempered seafood gather. Beware its charge."
	icon = 'icons/mob/icemoon/icemoon_monsters.dmi'
	icon_state = "arctic_lobstrosity"
	icon_living = "arctic_lobstrosity"
	icon_dead = "arctic_lobstrosity_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	friendly_verb_continuous = "chitters at"
	friendly_verb_simple = "chits at"
	speak_emote = list("chitters")
	speed = 3
	move_to_delay = 20
	maxHealth = 150
	health = 150
	obj_damage = 15
	melee_damage_lower = 15
	melee_damage_upper = 19
	attack_verb_continuous = "snips"
	attack_verb_simple = "snip"
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE //the closest we have to a crustacean pinching attack effect rn.
	weather_immunities = list(TRAIT_SNOWSTORM_IMMUNE)
	vision_range = 5
	aggro_vision_range = 7
	butcher_results = list(/obj/item/food/meat/crab = 2, /obj/item/stack/sheet/bone = 2)
	robust_searching = TRUE
	footstep_type = FOOTSTEP_MOB_CLAW
	gold_core_spawnable = HOSTILE_SPAWN
	var/datum/action/cooldown/mob_cooldown/charge/charge

/mob/living/simple_animal/hostile/asteroid/lobstrosity/Initialize()
	. = ..()
	charge = new /datum/action/cooldown/mob_cooldown/charge()
	charge.charge_distance = 4
	charge.cooldown_time = 6 SECONDS
	charge.charge_indicator = FALSE
	charge.Grant(src)
	RegisterSignal(src, COMSIG_STARTED_CHARGE, .proc/before_charge)
	RegisterSignal(src, COMSIG_BUMPED_CHARGE, .proc/hit_target)

/mob/living/simple_animal/hostile/asteroid/lobstrosity/OpenFire()
	if(client)
		return
	charge.Trigger(target)

/mob/living/simple_animal/hostile/asteroid/lobstrosity/proc/before_charge()
	Shake(15, 15, 1 SECONDS)

/mob/living/simple_animal/hostile/asteroid/lobstrosity/proc/hit_target(atom/hit_atom)
	if(isliving(hit_atom))
		var/mob/living/L = hit_atom
		var/blocked = FALSE
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			if(H.check_shields(src, 0, "the [name]", attack_type = LEAP_ATTACK))
				blocked = TRUE
		if(!blocked)
			L.visible_message(span_danger("[src] charges on [L]!"), span_userdanger("[src] charges into you!"))
			L.Knockdown(knockdown_time)
		else
			Stun((knockdown_time * 2), ignore_canstun = TRUE)
	else if(hit_atom.density && !hit_atom.CanPass(src, get_dir(hit_atom, src)))
		visible_message(span_danger("[src] smashes into [hit_atom]!"))
		Stun((knockdown_time * 2), ignore_canstun = TRUE)
	update_icons()
	return COMPONENT_OVERRIDE_CHARGE_BUMP

/mob/living/simple_animal/hostile/asteroid/lobstrosity/lava
	name = "tropical lobstrosity"
	desc = "A marvel of evolution gone wrong, the sulfur lakes of lavaland have given them a vibrant, red hued shell. Beware its charge."
	icon_state = "lobstrosity"
	icon_living = "lobstrosity"
	icon_dead = "lobstrosity_dead"
