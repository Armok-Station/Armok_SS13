// Any preferences that will show to the sides of the character in the setup menu.
#define PREFERENCE_CATEGORY_CLOTHING "clothing"

/// Backpack preference
/datum/preference/choiced/backpack
	savefile_key = "backpack"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_CLOTHING
	should_generate_icons = TRUE

/datum/preference/choiced/backpack/init_possible_values()
	var/list/values = list()

	values[GBACKPACK] = /obj/item/storage/backpack
	values[GSATCHEL] = /obj/item/storage/backpack/satchel
	values[LSATCHEL] = /obj/item/storage/backpack/satchel/leather
	values[GDUFFELBAG] = /obj/item/storage/backpack/duffelbag

	// In a perfect world, these would be your department's backpack.
	// However, this doesn't factor in assistants, or no high slot, and would
	// also increase the spritesheet size a lot.
	// I play medical doctor, and so medical doctor you get.
	values[DBACKPACK] = /obj/item/storage/backpack/medic
	values[DSATCHEL] = /obj/item/storage/backpack/satchel/med
	values[DDUFFELBAG] = /obj/item/storage/backpack/duffelbag/med

	return values

/datum/preference/choiced/backpack/apply_to_human(mob/living/carbon/human/target, value)
	target.backpack = value

/// Jumpsuit preference
/datum/preference/choiced/jumpsuit
	savefile_key = "jumpsuit_style"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_CLOTHING
	should_generate_icons = TRUE

/datum/preference/choiced/jumpsuit/init_possible_values()
	var/list/values = list()

	values[PREF_SUIT] = /obj/item/clothing/under/color/grey
	values[PREF_SKIRT] = /obj/item/clothing/under/color/jumpskirt/grey

	return values

/datum/preference/choiced/jumpsuit/apply_to_human(mob/living/carbon/human/target, value)
	target.jumpsuit_style = value

/// Socks preference
/datum/preference/choiced/socks
	savefile_key = "socks"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_CLOTHING
	should_generate_icons = TRUE

/datum/preference/choiced/socks/init_possible_values()
	return possible_values_for_sprite_accessory_list(GLOB.socks_list)

/datum/preference/choiced/socks/apply_to_human(mob/living/carbon/human/target, value)
	target.socks = value

/// Undershirt preference
/datum/preference/choiced/undershirt
	savefile_key = "undershirt"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_CLOTHING
	should_generate_icons = TRUE

/datum/preference/choiced/undershirt/init_possible_values()
	return possible_values_for_sprite_accessory_list(GLOB.undershirt_list)

/datum/preference/choiced/undershirt/apply_to_human(mob/living/carbon/human/target, value)
	target.undershirt = value

/// Underwear preference
/datum/preference/choiced/underwear
	savefile_key = "underwear"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_CLOTHING
	should_generate_icons = TRUE

/datum/preference/choiced/underwear/init_possible_values()
	return possible_values_for_sprite_accessory_list(GLOB.underwear_list)

/datum/preference/choiced/underwear/apply_to_human(mob/living/carbon/human/target, value)
	target.underwear = value

#undef PREFERENCE_CATEGORY_CLOTHING
