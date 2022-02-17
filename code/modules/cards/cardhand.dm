/obj/item/toy/cards/cardhand
	name = "hand of cards"
	desc = "A number of cards not in a deck, customarily held in ones hand."
	icon = 'icons/obj/toy.dmi'
	icon_state = "none"
	w_class = WEIGHT_CLASS_TINY
	worn_icon_state = "card"
	///Cards in this hand of cards.
	var/list/cards = list()
	///List of cards to add into the hand on initialization (used for mapping mostly)
	var/list/init_cards = list()

/obj/item/toy/cards/cardhand/Initialize(mapload, list/cards_to_combine)
	. = ..()
	if(!LAZYLEN(init_cards) || !LAZYLEN(cards_to_combine)) // if both lists are empty 
		CRASH("[src] is being made into a cardhand without a list of cards to combine")

	if(LAZYLEN(init_cards))
		for(var/card in init_cards)
			var/obj/item/toy/cards/singlecard/new_card = new /obj/item/toy/cards/singlecard(src)
			new_card.cardname = card
			new_card.Flip()
			cards += new_card
		update_appearance()
	if(LAZYLEN(cards_to_combine))
		for(var/obj/item/toy/cards/singlecard/new_card in cards_to_combine)
			cards += new_card
		update_appearance()

/obj/item/toy/cards/cardhand/add_card(mob/user, list/cards, obj/item/toy/cards/card_to_add)
	. = ..()
	interact(user)
	update_appearance()

/obj/item/toy/cards/cardhand/attack_self(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		if(!(human_user.mobility_flags & MOBILITY_USE))
			return
	if(user.stat || !ishuman(user))
		return
	interact(user)

	var/list/handradial = list()
	for(var/obj/item/toy/cards/singlecard/card in cards)
		handradial[card] = image(icon = src.icon, icon_state = card.icon_state)

	var/obj/item/toy/cards/singlecard/choice = show_radial_menu(usr, src, handradial, custom_check = CALLBACK(src, .proc/check_menu, user), radius = 36, require_near = TRUE)
	if(!choice)
		return FALSE
	draw_card(user, cards, choice)

	interact(user)
	if(length(cards) == 1)
		var/obj/item/toy/cards/singlecard/last_card = draw_card(user, cards)
		qdel(src)
		last_card.pickup(user)
		user.put_in_hands(last_card)
		to_chat(user, span_notice("You also take [last_card.cardname] and hold it."))
	else
		update_appearance()

/obj/item/toy/cards/cardhand/attackby(obj/item/toy/cards/singlecard/card, mob/living/user, params)
	if(istype(card))
		add_card(user, cards, card)
	else
		return ..()

/obj/item/toy/cards/cardhand/apply_card_vars(obj/item/toy/cards/newobj, obj/item/toy/cards/sourceobj)
	..()
	newobj.deckstyle = sourceobj.deckstyle
	update_appearance()
	newobj.card_hitsound = sourceobj.card_hitsound
	newobj.card_force = sourceobj.card_force
	newobj.card_throwforce = sourceobj.card_throwforce
	newobj.card_throw_speed = sourceobj.card_throw_speed
	newobj.card_throw_range = sourceobj.card_throw_range
	newobj.card_attack_verb_continuous = sourceobj.card_attack_verb_continuous //null or unique list made by string_list()
	newobj.card_attack_verb_simple = sourceobj.card_attack_verb_simple //null or unique list made by string_list()
	newobj.resistance_flags = sourceobj.resistance_flags

/**
 * ## check_menu
 *
 * Checks if we are allowed to interact with a radial menu
 *
 * Arguments:
 * * user - The mob interacting with a menu
 */
/obj/item/toy/cards/cardhand/proc/check_menu(mob/living/user)
	if(!istype(user) || user.incapacitated())
		return FALSE
	return TRUE
	
/obj/item/toy/cards/cardhand/update_overlays()
	. = ..()
	cut_overlays()
	var/overlay_cards = cards.len

	var/k = overlay_cards == 2 ? 1 : overlay_cards - 2
	for(var/i = k; i <= overlay_cards; i++)
		var/obj/item/toy/cards/singlecard/card = cards[i]
		var/card_overlay = image(icon, icon_state = card.icon_state, pixel_x = (1 - i + k) * 3, pixel_y = (1 - i + k) * 3)
		add_overlay(card_overlay)
