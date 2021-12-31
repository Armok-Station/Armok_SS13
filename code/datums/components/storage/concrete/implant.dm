/datum/component/storage/concrete/implant
	max_atom_size = ITEM_SIZE_NORMAL
	max_total_atom_size = ITEM_SIZE_NORMAL * 2
	max_items = 2
	drop_all_on_destroy = TRUE
	drop_all_on_deconstruct = TRUE
	silent = TRUE
	allow_big_nesting = TRUE

/datum/component/storage/concrete/implant/Initialize()
	. = ..()
	set_holdable(null, list(/obj/item/disk/nuclear))

/datum/component/storage/concrete/implant/InheritComponent(datum/component/storage/concrete/implant/I, original)
	if(!istype(I))
		return ..()
	max_total_atom_size += I.max_total_atom_size
	max_items += I.max_items
