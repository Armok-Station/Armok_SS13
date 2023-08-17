/obj/structure/artifact/vomit
	assoc_comp = /datum/component/artifact/vomit
/datum/component/artifact/vomit
	associated_object = /obj/structure/artifact/vomit
	weight = ARTIFACT_UNCOMMON
	type_name = "Vomiting Inducer"
	activation_message = "starts emitting disgusting imagery!"
	deactivation_message = "falls silent, its aura dissipating!"
	valid_origins = list(ORIGIN_NARSIE,ORIGIN_WIZARD) //silicons dont like organic stuff or something
	var/range = 0
	var/spew_range = 1
	var/spew_organs = FALSE
	var/bloody_vomit = FALSE
	COOLDOWN_DECLARE(cooldown)

/datum/component/artifact/vomit/setup()
	switch(rand(1,100))
		if(1 to 84)
			range = rand(2,3)
		if(85 to 100) //15%
			range = rand(2,7)
	if(prob(12))
		spew_organs = TRUE //trolling
		potency += 20
	if(prob(40))
		spew_range = rand(1,5)
		potency += spew_range
	bloody_vomit = prob(50)
	potency += (range) * 4

/datum/component/artifact/vomit/on_examine(atom/source, mob/user, list/examine_list)
	. = ..()
	var/mob/living/carbon/carbon = user
	if(active && istype(carbon) && carbon.stat < UNCONSCIOUS)
		examine_list += span_warning("It has an [spew_organs ? "extremely" : ""] disgusting aura! [prob(20) ? "..is that a felinid?" : ""]")
		carbon.vomit(blood = bloody_vomit, stun = (spew_organs ? TRUE : prob(25)), distance = spew_range)
		if(spew_organs && prob(40))
			carbon.spew_organ()
