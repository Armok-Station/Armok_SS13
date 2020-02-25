///Tool capable of taking biological samples from mobs
/obj/item/swab
	name = "swab"
	desc = "Some men use these for different reasons."
	icon = 'icons/obj/xenobiology/vatgrowing.dmi'
	icon_state = "swab"

///Adds the swabbing component to the biopsy tool
/obj/item/swab/Initialize()
	. = ..()
	AddComponent(/datum/component/swabbing, TRUE, TRUE, TRUE, null, CALLBACK(src, .proc/update_swab_icon), max_items = 1)

/obj/item/swab/proc/update_swab_icon(overlays, var/list/swabbed_items)
	if(swabbed_items.len)
		var/datum/biological_sample/sample = swabbed_items[1] //Use the first one as our target
		var/mutable_appearance/swab_overlay = mutable_appearance(icon, "swab_[sample.sample_color]")
		swab_overlay.appearance_flags = RESET_COLOR
		. += swab_overlay


