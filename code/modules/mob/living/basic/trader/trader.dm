/mob/living/basic/trader
	name = "Trader"
	desc = "Come buy some!"
	unique_name = TRUE
	icon = 'icons/mob/simple/simple_human.dmi'
	maxHealth = 200
	health = 200
	melee_damage_lower = 10
	melee_damage_upper = 10
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	attack_sound = 'sound/weapons/punch1.ogg'
	basic_mob_flags = DEL_ON_DEATH
	unsuitable_atmos_damage = 2.5
	combat_mode = TRUE
	move_resist = MOVE_FORCE_STRONG
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	sentience_type = SENTIENCE_HUMANOID
	speed = 0
	///TODO: remove this, use component to intercept clicks
	interaction_flags_atom = INTERACT_ATOM_NO_FINGERPRINT_ATTACK_HAND|INTERACT_ATOM_ATTACK_HAND|INTERACT_ATOM_NO_FINGERPRINT_INTERACT

	ai_controller = /datum/ai_controller/basic_controller/trader

	///Sound used when item sold/bought
	var/sell_sound = 'sound/effects/cashregister.ogg'
	///The spawner we use to create our look
	var/spawner_path = /obj/effect/mob_spawn/corpse/human/generic_assistant
	///Our species to create our look
	var/species_path = /datum/species/human
	///The loot we drop when we die
	var/loot = list(/obj/effect/mob_spawn/corpse/human/generic_assistant)
	///Casing used to shoot during retaliation
	var/ranged_attack_casing =/obj/item/ammo_casing/shotgun/buckshot
	///Sound to make while doing a retalitory attack
	var/ranged_attack_sound = 'sound/weapons/gun/pistol/shot.ogg'
	///Weapon path, for visuals
	var/held_weapon_visual = /obj/item/gun/ballistic/shotgun

/mob/living/basic/trader/Initialize(mapload)
	. = ..()
	apply_dynamic_human_appearance(src, species_path = species_path, mob_spawn_path = spawner_path, r_hand = held_weapon_visual)
	AddElement(/datum/element/ai_retaliate)
	AddComponent(/datum/component/ranged_attacks, casing_type = ranged_attack_casing, projectile_sound = ranged_attack_sound, cooldown_time = 3 SECONDS)
	if(LAZYLEN(loot))
		loot = string_list(loot)
		AddElement(/datum/element/death_drops, loot)

/mob/living/basic/trader/mrbones
	name = "Mr. Bones"
	desc = "A skeleton merchant, he seems very humerus."
	speak_emote = list("rattles")
	speech_span = SPAN_SANS
	mob_biotypes = MOB_UNDEAD|MOB_HUMANOID
	icon_state = "mrbones"
	gender = MALE

	sell_sound = 'sound/voice/hiss2.ogg'
	species_path = /datum/species/skeleton
	spawner_path = /obj/effect/mob_spawn/corpse/human/skeleton/mrbones
	loot = list(/obj/effect/decal/remains/human)
	ranged_attack_casing = /obj/item/ammo_casing/energy/bolt/halloween
	ranged_attack_sound = 'sound/hallucinations/growl1.ogg'
	held_weapon_visual = /obj/item/cane

/obj/effect/mob_spawn/corpse/human/skeleton/mrbones
	mob_species = /datum/species/skeleton
	outfit = /datum/outfit/mrbonescorpse

/datum/outfit/mrbonescorpse
	name = "Mr Bones' Corpse"
	head = /obj/item/clothing/head/hats/tophat

