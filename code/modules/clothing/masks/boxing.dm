<<<<<<< HEAD
/obj/item/clothing/mask/balaclava
	name = "balaclava"
	desc = "LOADSAMONEY"
	icon_state = "balaclava"
	item_state = "balaclava"
	flags_inv = HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	visor_flags_inv = HIDEFACE|HIDEFACIALHAIR
	w_class = 2
	actions_types = list(/datum/action/item_action/adjust)

/obj/item/clothing/mask/balaclava/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/luchador
	name = "Luchador Mask"
	desc = "Worn by robust fighters, flying high to defeat their foes!"
	icon_state = "luchag"
	item_state = "luchag"
	flags_inv = HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	w_class = 2

/obj/item/clothing/mask/luchador/speechModification(message)
	if(copytext(message, 1, 2) != "*")
		message = replacetext(message, "captain", "CAPIT�N")
		message = replacetext(message, "station", "ESTACI�N")
		message = replacetext(message, "sir", "SE�OR")
		message = replacetext(message, "the ", "el ")
		message = replacetext(message, "my ", "mi ")
		message = replacetext(message, "is ", "es ")
		message = replacetext(message, "it's", "es")
		message = replacetext(message, "friend", "amigo")
		message = replacetext(message, "buddy", "amigo")
		message = replacetext(message, "hello", "hola")
		message = replacetext(message, " hot", " caliente")
		message = replacetext(message, " very ", " muy ")
		message = replacetext(message, "sword", "espada")
		message = replacetext(message, "library", "biblioteca")
		message = replacetext(message, "traitor", "traidor")
		message = replacetext(message, "wizard", "mago")
		message = uppertext(message)	//Things end up looking better this way (no mixed cases), and it fits the macho wrestler image.
		if(prob(25))
			message += " OLE!"
	return message

/obj/item/clothing/mask/luchador/tecnicos
	name = "Tecnicos Mask"
	desc = "Worn by robust fighters who uphold justice and fight honorably."
	icon_state = "luchador"
	item_state = "luchador"

/obj/item/clothing/mask/luchador/rudos
	name = "Rudos Mask"
	desc = "Worn by robust fighters who are willing to do anything to win."
	icon_state = "luchar"
	item_state = "luchar"
=======
/obj/item/clothing/mask/luchador
	name = "Luchador Mask"
	desc = "Worn by robust fighters, flying high to defeat their foes!"
	icon_state = "luchag"
	item_state = "luchag"
	flags = FPRINT|MASKINTERNALS
	body_parts_covered = HEAD|EARS|EYES
	w_class = W_CLASS_SMALL
	siemens_coefficient = 3.0
	species_fit = list(VOX_SHAPED)

/obj/item/clothing/mask/luchador/treat_mask_speech(var/datum/speech/speech)
	var/message=speech.message
	message = replacetext(message, "captain", "CAPITÁN")
	message = replacetext(message, "station", "ESTACIÓN")
	message = replacetext(message, "sir", "SEÑOR")
	message = replacetext(message, "the ", "el ")
	message = replacetext(message, "my ", "mi ")
	message = replacetext(message, "is ", "es ")
	message = replacetext(message, "it's", "es")
	message = replacetext(message, "friend", "amigo")
	message = replacetext(message, "buddy", "amigo")
	message = replacetext(message, "hello", "hola")
	message = replacetext(message, " hot", " caliente")
	message = replacetext(message, " very ", " muy ")
	message = replacetext(message, "sword", "espada")
	message = replacetext(message, "library", "biblioteca")
	message = replacetext(message, "traitor", "traidor")
	message = replacetext(message, "wizard", "mago")
	message = uppertext(message)	//Things end up looking better this way (no mixed cases), and it fits the macho wrestler image.
	if(prob(25))
		message += " OLE!"
	speech.message = message

/obj/item/clothing/mask/luchador/tecnicos
	name = "Tecnicos Mask"
	desc = "Worn by robust fighters who uphold justice and fight honorably."
	icon_state = "luchador"
	item_state = "luchador"
	species_fit = list(VOX_SHAPED)

/obj/item/clothing/mask/luchador/rudos
	name = "Rudos Mask"
	desc = "Worn by robust fighters who are willing to do anything to win."
	icon_state = "luchar"
	item_state = "luchar"
	species_fit = list(VOX_SHAPED)
>>>>>>> ccb55b121a3fd5338fc56a602424016009566488
