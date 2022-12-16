/// Simple element to be applied to reagents
/// When those reagents are exposed to mobs with the bug biotype, causes toxins damgae
/datum/element/bugkiller_reagent

/datum/element/bugkiller_reagent/Attach(datum/target)
	. = ..()
	if(!istype(target, /datum/reagent))
		return

	RegisterSignal(target, COMSIG_REAGENT_EXPOSE_MOB, PROC_REF(on_expose))

/datum/element/bugkiller_reagent/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_REAGENT_EXPOSE_MOB)

/datum/element/bugkiller_reagent/proc/on_expose(
	datum/reagent/source,
	mob/living/exposed_mob,
	methods = TOUCH,
	reac_volume,
	show_message = TRUE,
	touch_protection = 0,
)
	SIGNAL_HANDLER

	if(exposed_mob.stat == DEAD)
		return
	if(!(exposed_mob.mob_biotypes & MOB_BUG))
		return

	var/damage = min(round(0.4 * reac_volume * (1 - touch_protection), 0.1), 10)
	if(exposed_mob.health <= damage)
		exposed_mob.apply_status_effect(/datum/status_effect/bugkiller_death)
		return

	exposed_mob.apply_damage(damage, TOX)

/// If bugkiller delivers a lethal dosage, applies this effect which does a funny animation THEN kills 'em
/// Also makes it so simplemobs / basicmobs no longer delete when they die (if they do)
/datum/status_effect/bugkiller_death
	id = "bugkiller_death"
	alert_type = /atom/movable/screen/alert/status_effect/bugkiller_death
	/// How many times the spasm loops
	var/spasm_loops = 0

/datum/status_effect/bugkiller_death/on_creation(mob/living/new_other, duration = 4 SECONDS)
	src.duration = duration
	src.spasm_loops = ROUND_UP(duration / 0.8) // one spasm ~= 0.8 deciseconds (yes deciseconds)
	return ..()

/datum/status_effect/bugkiller_death/on_apply()
	if(owner.stat == DEAD)
		return FALSE
	owner.spasm_animation(spasm_loops)
	playsound(owner, 'sound/voice/human/malescream_1.ogg', 25, TRUE, extrarange = SILENCED_SOUND_EXTRARANGE, frequency = 5)
	return TRUE

/datum/status_effect/bugkiller_death/on_remove()
	if(owner.stat == DEAD || QDELETED(owner))
		return

	if(isbasicmob(owner))
		var/mob/living/basic/basic_owner = owner
		basic_owner.basic_mob_flags &= ~DEL_ON_DEATH
		basic_owner.flip_on_death = TRUE

	if(isanimal(owner))
		var/mob/living/simple_animal/simple_owner = owner
		simple_owner.del_on_death = FALSE
		simple_owner.flip_on_death = TRUE

	owner.investigate_log("died to being sprayed with bugkiller.", INVESTIGATE_DEATHS)
	owner.death()

/atom/movable/screen/alert/status_effect/bugkiller_death
	name = "Overwhelming Bugkiller"
	desc = "You don't feel so good."
	icon_state = "paralysis"
