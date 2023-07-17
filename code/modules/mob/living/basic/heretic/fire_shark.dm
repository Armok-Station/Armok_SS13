/mob/living/basic/fire_shark
	name = "fire shark"
	desc = "It is a eldritch dwarf space shark, also known as a fire shark."
	icon = 'icons/mob/nonhuman-player/eldritch_mobs.dmi'
	icon_state = "fire_shark"
	icon_living = "fire_shark"
	pass_flags = PASSTABLE | PASSMOB
	mob_biotypes = MOB_ORGANIC | MOB_BEAST
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	speed = -0.5
	health = 16
	maxHealth = 16
	melee_damage_lower = 8
	melee_damage_upper = 8
	attack_sound = 'sound/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	obj_damage = 0
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	damage_coeff = list(BRUTE = 1, BURN = 0.25, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	mob_size = MOB_SIZE_TINY
	speak_emote = list("screams")

/mob/living/basic/fire_shark/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/death_drops, list(/obj/effect/gibspawner/human))
	AddElement(/datum/element/death_gases, /datum/gas/plasma, 40)
	AddElement(/datum/element/simple_flying)
	AddElement(/datum/element/venomous, /datum/reagent/phlogiston, 2)
	AddComponent(/datum/component/swarming)
	AddComponent(/datum/component/regenerator, outline_colour = COLOR_DARK_RED)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
