/datum/loadout_category/masks
	category_name = "����"
	category_ui_icon = FA_ICON_MASK
	type_to_generate = /datum/loadout_item/masks
	tab_order = /datum/loadout_category/head::tab_order + 1

/datum/loadout_item/masks
	abstract_type = /datum/loadout_item/masks

/datum/loadout_item/glasses/insert_path_into_outfit(datum/outfit/outfit, mob/living/carbon/human/equipper, visuals_only = FALSE)
	if(outfit.mask)
		LAZYADD(outfit.backpack_contents, outfit.mask)
	outfit.mask = item_path

/datum/loadout_item/masks/pig
	name = "����� ������"
	item_path = /obj/item/clothing/mask/animal/pig

/datum/loadout_item/masks/horsehead
	name = "����� ������"
	item_path = /obj/item/clothing/mask/animal/horsehead

/datum/loadout_item/masks/raven
	name = "����� ������"
	item_path = /obj/item/clothing/mask/animal/small/raven

/datum/loadout_item/masks/breathscarf
	name = "���� � �������� �������"
	item_path = /obj/item/clothing/mask/breath/breathscarf

/datum/loadout_item/masks/red_gas
	name = "���-1"
	item_path = /obj/item/clothing/mask/breath/red_gas