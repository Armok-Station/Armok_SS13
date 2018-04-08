/*
//////////////////////////////////////

Brain degradation

	Gives brain damage over time and replaces the stat loss from the removal of the Aggressive Viral Metabolism

//////////////////////////////////////
*/

/datum/symptom/migraine

	name = "Brain degradation"
	desc = "The virus slowly synthesizes Impedrezene, which effectively removes the need of thought in one's actions."
	stealth = -2
	resistance = 1
	stage_speed = 3
	transmittable = 1
	severity = 4
	level = 7
	base_message_chance = 10
	symptom_delay_min = 5
	symptom_delay_max = 20

/datum/symptom/migraine/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	switch(A.stage)
		if(4, 5)
			M.adjustBrainLoss(2.5)
			M.updatehealth()
		else
			if(prob(base_message_chance))
				to_chat(M, "<span class='warning'>[pick("Your head aches.", "You hear a rattling sound in your head.", "You forgot what you were just thinking about.")]</span>")

