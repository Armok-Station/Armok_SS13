/*
** The base card class that is used by decks and cardhands
*/
/obj/item/toy/cards
	resistance_flags = FLAMMABLE
	max_integrity = 50
	/// Do all the cards drop to the floor when thrown at a person
	var/can_play_52_card_pickup = TRUE
	/// List of cards for a hand or deck
	var/list/cards = list()

/obj/item/toy/cards/Destroy()
	if(LAZYLEN(cards))
		QDEL_LIST(cards)
	return ..()

/// This is how we play 52 card pickup
/obj/item/toy/cards/throw_impact(mob/living/target, datum/thrownthing/throwingdatum)
	if(..() || !istype(target)) // was it caught or is the target not a living mob
		return

	if(!throwingdatum?.thrower) // if a mob didn't throw it (need two people to play 52 pickup)
		return

	var/mob/living/thrower = throwingdatum.thrower

	var/has_no_cards = !LAZYLEN(cards)
	if(has_no_cards)
		return

	for(var/obj/item/toy/singlecard/card in cards)
		cards -= card
		card.forceMove(drop_location())
		if(prob(50))
			card.Flip()
		card.pixel_x = rand(-16, 16)
		card.pixel_y = rand(-16, 16)
		var/matrix/M = matrix()
		var/angle = pick(0, 90, 180, 270)
		M.Turn(angle)
		card.transform = M
		card.update_appearance()
	update_appearance()
	playsound(src, 'sound/items/cardshuffle.ogg', 50, TRUE)

	if(istype(src, /obj/item/toy/cards/deck))
		target.visible_message(span_warning("[target] is forced to play 52 card pickup!"), span_warning("You are forced to play 52 card pickup."))
		SEND_SIGNAL(target, COMSIG_ADD_MOOD_EVENT, "lost_52_card_pickup", /datum/mood_event/lost_52_card_pickup)
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "won_52_card_pickup", /datum/mood_event/won_52_card_pickup)
		add_memory_in_range(
			target,
			7,
			MEMORY_PLAYING_52_PICKUP,
			list(DETAIL_PROTAGONIST = thrower, DETAIL_DEUTERAGONIST = target, DETAIL_WHAT_BY = src),
			story_value = STORY_VALUE_OKAY,
			memory_flags = MEMORY_CHECK_BLINDNESS
		)

	if(istype(src, /obj/item/toy/cards/cardhand))
		qdel(src)

/**
 * This is used to insert a list of cards into a deck or cardhand
 *
 * All cards that are inserted have their angle and pixel offsets reset to zero however their
 * flip state does not change unless it's being inserted into a deck which is always facedown
 * (see the deck/insert proc)
 *
 * Arguments:
 * * list/cards_to_add - List of card objects to be inserted
 */
/obj/item/toy/cards/proc/insert(list/cards_to_add)
	for(var/obj/item/toy/singlecard/card in cards_to_add)
		card.forceMove(src)
		// reset the position and angle
		card.pixel_x = 0
		card.pixel_y = 0
		var/matrix/M = matrix()
		M.Turn(0) // I think this resets the angle to 0 but needs to be tested
		card.transform = M
		card.update_appearance()
		cards += card
	update_appearance()

/**
 * Draws a card from the deck or hand of cards.
 *
 * Draws the top card unless a card arg is supplied then it picks that specific card
 * and returns it (the card arg is used by the radial menu for cardhands to select
 * specific cards out of the cardhand)
 * Arguments:
 * * mob/living/user - The user drawing the card.
 * * obj/item/toy/singlecard/card (optional) - The card drawn from the hand
**/
/obj/item/toy/cards/proc/draw(mob/living/user, obj/item/toy/singlecard/card)
	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, NO_TK))
		return

	var/has_no_cards = !LAZYLEN(cards)
	if(has_no_cards)
		to_chat(user, span_warning("There are no more cards to draw!"))
		return

	card = card || cards[1] //draw the card on top
	cards -= card
	update_appearance()
	playsound(src, 'sound/items/cardflip.ogg', 50, TRUE)
	return card
