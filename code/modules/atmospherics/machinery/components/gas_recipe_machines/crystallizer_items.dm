/obj/item/hypernoblium_crystal
	name = "Hypernoblium Crystal"
	desc = "crystalized oxygen and hypernoblium stored in a bottle to pressureproof your clothes."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "potblue"
	var/uses = 1

/obj/item/hypernoblium_crystal/afterattack(obj/item/clothing/C, mob/user, proximity)
	. = ..()
	if(!uses)
		qdel(src)
		return
	if(!proximity)
		return
	if(!istype(C))
		to_chat(user, span_warning("The crystal can only be used on clothing!"))
		return
	if(istype(C, /obj/item/clothing/suit/space))
		to_chat(user, span_warning("The [C] is already pressure-resistant!"))
		return ..()
	if(C.min_cold_protection_temperature == SPACE_SUIT_MIN_TEMP_PROTECT && C.clothing_flags & STOPSPRESSUREDAMAGE)
		to_chat(user, span_warning("The [C] is already pressure-resistant!"))
		return ..()
	to_chat(user, span_notice("you see how the [C] changes color, its now pressure proof."))
	C.name = "pressure-resistant [C.name]"
	C.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	C.add_atom_colour("#00fff7", FIXED_COLOUR_PRIORITY)
	C.min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	C.cold_protection = C.body_parts_covered
	C.clothing_flags |= STOPSPRESSUREDAMAGE
	uses--
	if(!uses)
		qdel(src)