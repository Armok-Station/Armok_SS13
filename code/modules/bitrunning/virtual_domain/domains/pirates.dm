/datum/lazy_template/virtual_domain/pirates
	name = "Corsair Cove"
	cost = BITRUNNER_COST_MEDIUM
	desc = "Battle your way to the hidden treasure, seize the booty, and make a swift escape before the pirates turn the tide."
	difficulty = BITRUNNER_DIFFICULTY_MEDIUM
	help_text = "Put on the provided outfits to blend in, then battle your way through the hostile pirates. \
	Grab the treasure and get out before you're overwhelmed!"
	key = "pirates"
	map_height = 42
	map_name = "pirates"
	map_width = 37
	reward_points = BITRUNNER_REWARD_MEDIUM

/obj/effect/mob_spawn/corpse/human/pirate/virtual_domain
	keep_ref = TRUE

/obj/effect/mob_spawn/corpse/human/pirate/melee/virtual_domain
	keep_ref = TRUE
