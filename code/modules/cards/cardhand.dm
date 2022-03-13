/obj/item/toy/cards/cardhand
	name = "hand of cards"
	desc = "A number of cards not in a deck, customarily held in ones hand."
	icon = 'icons/obj/playing_cards.dmi'
	icon_state = "none"
	w_class = WEIGHT_CLASS_TINY
	worn_icon_state = "card"

/obj/item/toy/cards/cardhand/Initialize(mapload, list/cards_to_combine)
	. = ..()

	if(!LAZYLEN(cards_to_combine) && (mapload && !LAZYLEN(cards)))
		CRASH("[src] is being made into a cardhand without a list of cards to combine")

	if(mapload && LAZYLEN(cards)) // these cards have not been initialized
		for(var/card_name in cards)
			var/obj/item/toy/singlecard/new_card = new (loc, card_name)
			new_card.update_appearance()
			cards_to_combine += new_card
		cards = list() // reset our cards to an empty list

	if(LAZYLEN(cards_to_combine)) // these cards are already initialized
		for(var/obj/item/toy/singlecard/new_card in cards_to_combine)
			new_card.forceMove(src)
			cards += new_card
	update_appearance()

/obj/item/toy/cards/cardhand/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] is slitting [user.p_their()] wrists with \the [src]! It looks like [user.p_they()] [user.p_have()] a crummy hand!"))
	playsound(src, 'sound/items/cardshuffle.ogg', 50, TRUE)
	return BRUTELOSS

/obj/item/toy/cards/cardhand/examine(mob/user)
	. = ..()
	if(cards.len == 0)
		CRASH("The [src] should have been deleted since it has no cards inside it!")

	for(var/obj/item/toy/singlecard/card in cards)
		if(HAS_TRAIT(user, TRAIT_XRAY_VISION))
			. += span_notice("You scan the cardhand with your x-ray vision and there is a: [card.cardname]")
		var/marked_color = card.getMarkedColor(user)
		if(marked_color)
			. += span_notice("There is a [marked_color] mark on the corner of a card in the cardhand!")

/obj/item/toy/cards/cardhand/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()

	if(istype(held_item, /obj/item/toy/cards/deck))
		var/obj/item/toy/cards/deck/dealer_deck = held_item
		if(dealer_deck.wielded)
			context[SCREENTIP_CONTEXT_LMB] = "Deal card"
			context[SCREENTIP_CONTEXT_RMB] = "Deal card faceup"
			return CONTEXTUAL_SCREENTIP_SET
		context[SCREENTIP_CONTEXT_LMB] = "Recycle cards"
		return CONTEXTUAL_SCREENTIP_SET

	if(istype(held_item, /obj/item/toy/singlecard))
		context[SCREENTIP_CONTEXT_LMB] = "Combine cards"
		context[SCREENTIP_CONTEXT_RMB] = "Combine cards faceup"
		return CONTEXTUAL_SCREENTIP_SET

	return .

/obj/item/toy/cards/cardhand/attack_self(mob/living/user)
	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, NO_TK))
		return

	var/list/handradial = list()
	for(var/obj/item/toy/singlecard/card in cards)
		handradial[card] = image(icon = src.icon, icon_state = card.icon_state)

	var/obj/item/toy/singlecard/choice = show_radial_menu(usr, src, handradial, custom_check = CALLBACK(src, .proc/check_menu, user), radius = 36, require_near = TRUE)
	if(!choice)
		return FALSE

	var/obj/item/toy/singlecard/selected_card = draw(user, choice)
	selected_card.pickup(user)
	user.put_in_hands(selected_card)
	update_appearance()

	if(length(cards) == 1)
		user.temporarilyRemoveItemFromInventory(src, TRUE)
		var/obj/item/toy/singlecard/last_card = draw(user)
		last_card.pickup(user)
		user.put_in_hands(last_card)
		qdel(src) // cardhand is empty now so delete it

/obj/item/toy/cards/cardhand/proc/check_menu(mob/living/user)
	return isliving(user) && !user.incapacitated()

/obj/item/toy/cards/cardhand/attackby(obj/item/weapon, mob/living/user, params, flip_card = FALSE)
	var/cards_to_add = list()
	var/obj/item/toy/singlecard/card

	if(istype(weapon, /obj/item/toy/singlecard))
		card = weapon

	if(istype(weapon, /obj/item/toy/cards/deck))
		var/obj/item/toy/cards/deck/dealer_deck = weapon
		if(!dealer_deck.wielded) // recycle cardhand into deck (if unwielded)
			dealer_deck.insert(cards)
			qdel(src)
			user.balloon_alert_to_viewers("puts card in deck", vision_distance = COMBAT_MESSAGE_RANGE)
			return
		card = dealer_deck.draw(user)

	if(card)
		if(flip_card)
			card.Flip()
			card.update_appearance()
		insert(list(card))
		return

	return ..()

/obj/item/toy/cards/cardhand/attackby_secondary(obj/item/weapon, mob/user, params)
	attackby(weapon, user, params, flip_card = TRUE)
	return SECONDARY_ATTACK_CONTINUE_CHAIN

/obj/item/toy/cards/cardhand/update_overlays()
	. = ..()
	cut_overlays()
	for(var/i in 1 to cards.len)
		var/obj/item/toy/singlecard/card = cards[i]
		var/card_overlay = image(icon, icon_state = card.icon_state, pixel_x = (i - 1) * 3, pixel_y = (i - 1) * 3)
		add_overlay(card_overlay)
