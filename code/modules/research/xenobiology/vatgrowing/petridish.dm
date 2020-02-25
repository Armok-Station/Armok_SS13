///Holds a biological sample which can then be put into the growing vat
/obj/item/petri_dish
	name = "petri dish"
	desc = "This makes you feel well-cultured."
	icon = 'icons/obj/xenobiology/vatgrowing.dmi'
	icon_state = "petri_dish"
	///The sample stored on the dish
	var/datum/biological_sample/sample

/obj/item/petri_dish/examine(mob/user)
	. = ..()
	if(!user.research_scanner) //For some reason a mob var
		return
	if(!sample)
		return
	. += "<span class='notice'>You can see the following micro-organisms:</span>"
	. += sample.GetAllDetails() //Get just the names nicely parsed.

/obj/item/petri_dish/update_overlays()
	. = ..()
	if(!sample)
		return
	var/reagentcolor = sample.sample_color
	var/mutable_appearance/base_overlay = mutable_appearance(icon, "petri_dish_overlay")
	base_overlay.appearance_flags = RESET_COLOR
	base_overlay.color = reagentcolor
	. += base_overlay
	var/mutable_appearance/overlay2 = mutable_appearance(icon, "petri_dish_overlay2")
	. += overlay2

/obj/item/petri_dish/proc/deposit_sample(user, var/datum/biological_sample/deposited_sample)
	sample = deposited_sample
	to_chat(user, "<span class='notice'>You deposit a sample into [src].</span>")
	update_icon()
