/datum/loadout_category/suits
	category_name = "������� ������"
	category_ui_icon = FA_ICON_VEST
	type_to_generate = /datum/loadout_item/suits
	tab_order = /datum/loadout_category/head::tab_order + 1

/datum/loadout_item/suits
	abstract_type = /datum/loadout_item/suits

/datum/loadout_item/glasses/insert_path_into_outfit(datum/outfit/outfit, mob/living/carbon/human/equipper, visuals_only = FALSE)
	if(outfit.suit)
		LAZYADD(outfit.backpack_contents, outfit.suit)
	outfit.suit = item_path

/datum/loadout_item/suits/wintercoat
	name = "������ ������"
	item_path = /obj/item/clothing/suit/hooded/wintercoat

/datum/loadout_item/suits/apron
	name = "������"
	item_path = /obj/item/clothing/suit/apron

/datum/loadout_item/suits/apron/red
	name = "������� ������"
	item_path = /obj/item/clothing/suit/apron/chef/red

/datum/loadout_item/suits/jacket/miljacket
	name = "��������� �������"
	item_path = /obj/item/clothing/suit/jacket/miljacket

/datum/loadout_item/suits/jacket/det_jacket/disco
	name = "������ �������"
	item_path = /obj/item/clothing/suit/jacket/det_suit/disco

/datum/loadout_item/suits/jacket/biker
	name = "������ �������"
	item_path = /obj/item/clothing/suit/jacket/leather/biker

/datum/loadout_item/suits/jacket/puffer
	name = "�����"
	item_path = /obj/item/clothing/suit/jacket/puffer

/datum/loadout_item/suits/jacket/letterman_nt
	name = "������� ��������� ��"
	item_path = /obj/item/clothing/suit/jacket/letterman_nanotrasen