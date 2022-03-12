#define DECK_SHUFFLE_TIME (5 SECONDS)
#define DECK_SYNDIE_SHUFFLE_TIME (3 SECONDS)

/obj/item/toy/cards/deck
	name = "deck of cards"
	desc = "A deck of space-grade playing cards."
	icon = 'icons/obj/playing_cards.dmi'
	icon_state = "deck_nanotrasen_full"
	w_class = WEIGHT_CLASS_SMALL
	worn_icon_state = "card"
	/// The amount of time it takes to shuffle
	var/shuffle_time = DECK_SHUFFLE_TIME
	/// Deck shuffling cooldown.
	COOLDOWN_DECLARE(shuffle_cooldown)
	/// Tracks holodeck cards, since they shouldn't be infinite
	var/obj/machinery/computer/holodeck/holo = null
	/// If the deck is the standard 52 playing card deck (used for poker and blackjack)
	var/is_standard_deck = TRUE
	/// The amount of cards to spawn in the deck (optional)
	var/decksize = INFINITY
	///Wielding status for holding with two hands
	var/wielded = FALSE

	// the below vars will be inherited by the singlecards spawned in the deck
	hitsound = null
	force = 0
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	attack_verb_continuous = list("attacks")
	attack_verb_simple = list("attack")
	/// If the cards in the deck have different card faces icons (blank and CAS decks do not)
	var/has_unique_card_icons = TRUE
	/// The art style of deck used (determines both deck and card icons used)
	var/deckstyle = "nanotrasen"

/obj/item/toy/cards/deck/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/drag_pickup)
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, .proc/on_wield)
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, .proc/on_unwield)
	AddComponent(/datum/component/two_handed, attacksound='sound/items/cardflip.ogg')

	// not sure if we can have both this and the add_context proc together (so TEST and if it works delete this comment)
	AddElement( \
		/datum/element/contextual_screentip_bare_hands, \
		lmb_text = "Draw card", \
		rmb_text = "Draw card faceup", \
	)

	if(!is_standard_deck)
		return

	// generate a normal playing card deck
	for(var/suit in list("Hearts", "Spades", "Clubs", "Diamonds"))
		cards += new /obj/item/toy/singlecard(mapload, "Ace of [suit]", src)
		for(var/i in 2 to 10)
			cards += new /obj/item/toy/singlecard(mapload, "[i] of [suit]", src)
		for(var/person in list("Jack", "Queen", "King"))
			cards += new /obj/item/toy/singlecard(mapload, "[person] of [suit]", src)

/// triggered on wield of two handed item
/obj/item/toy/cards/deck/proc/on_wield(obj/item/source, mob/user)
	SIGNAL_HANDLER

	wielded = TRUE

/// triggered on unwield of two handed item
/obj/item/toy/cards/deck/proc/on_unwield(obj/item/source, mob/user)
	SIGNAL_HANDLER

	wielded = FALSE

/obj/item/toy/cards/deck/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] is slitting [user.p_their()] wrists with \the [src]! It looks like their luck ran out!"))
	playsound(src, 'sound/items/cardshuffle.ogg', 50, TRUE)
	return BRUTELOSS

/obj/item/toy/cards/deck/examine(mob/user)
	. = ..()
	
	if(cards.len > 0)
		var/obj/item/toy/singlecard/card = cards[1]
		if(HAS_TRAIT(user, TRAIT_XRAY_VISION))
			. += span_notice("You scan the deck with your x-ray vision and the top card reads: [card.cardname].")
		var/marked_color = card.getMarkedColor(user)
		if(marked_color)
			. += span_notice("The top card of the deck has a [marked_color] mark on the corner!")

	. += span_notice("Left-click to draw a card face down.")
	. += span_notice("Right-click to draw a card face up.")
	. += span_notice("Alt-Click to shuffle the deck.")
	. += span_notice("Click and drag the deck to yourself to pickup.")

/obj/item/toy/cards/deck/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
		
	if(istype(held_item, /obj/item/toy/singlecard))
		context[SCREENTIP_CONTEXT_LMB] = "Recycle card"
		return CONTEXTUAL_SCREENTIP_SET
		
	if(istype(held_item, /obj/item/toy/cards/cardhand))
		context[SCREENTIP_CONTEXT_LMB] = "Recycle cards"
		return CONTEXTUAL_SCREENTIP_SET
	return .

/**
 * Shuffles the cards in the deck
 * 
 * Arguments:
 * * user - The person shuffling the cards.
 */
/obj/item/toy/cards/deck/proc/shuffle_cards(mob/living/user)
	if(!COOLDOWN_FINISHED(src, shuffle_cooldown))
		return
	COOLDOWN_START(src, shuffle_cooldown, shuffle_time)
	cards = shuffle(cards)
	playsound(src, 'sound/items/cardshuffle.ogg', 50, TRUE)
	user.balloon_alert_to_viewers("shuffles the deck", vision_distance = COMBAT_MESSAGE_RANGE)

/obj/item/toy/cards/deck/attack_hand(mob/living/user, list/modifiers, flip_card = FALSE)
	if(!ishuman(user) || !user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, NO_TK, !iscyborg(user)))
		return
		
	var/obj/item/toy/singlecard/card = draw(user)
	if(!card)
		return
	if(flip_card)
		card.Flip()
	card.pickup(user)
	user.put_in_hands(card)
	user.balloon_alert_to_viewers("draws a card", vision_distance = COMBAT_MESSAGE_RANGE)

/obj/item/toy/cards/deck/attack_hand_secondary(mob/living/user, list/modifiers)
	attack_hand(user, modifiers, flip_card = TRUE)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/toy/cards/deck/AltClick(mob/living/user)
	if(user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, NO_TK, !iscyborg(user)))
		if(wielded)
			shuffle_cards(user)
		else
			to_chat(user, span_notice("You must hold the [src] with both hands to shuffle."))
	return ..()

/obj/item/toy/cards/deck/update_icon_state()
	switch(cards.len)
		if(27 to INFINITY)
			icon_state = "deck_[deckstyle]_full"
		if(11 to 27)
			icon_state = "deck_[deckstyle]_half"
		if(1 to 11)
			icon_state = "deck_[deckstyle]_low"
		else
			icon_state = "deck_[deckstyle]_empty"
	return ..()

/obj/item/toy/cards/deck/insert(list/cards_to_add)
	for(var/obj/item/toy/singlecard/card in cards_to_add)
		card.Flip(CARD_FACEDOWN) // any card inserted into the deck is always facedown
	. = ..()

/obj/item/toy/cards/deck/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/toy/singlecard))
		insert(list(item))
		user.balloon_alert_to_viewers("puts card in deck", vision_distance = COMBAT_MESSAGE_RANGE)
		return
	if(istype(item, /obj/item/toy/cards/cardhand))
		var/obj/item/toy/cards/cardhand/recycled_cardhand = item		
		insert(recycled_cardhand.cards)
		qdel(recycled_cardhand)
		user.balloon_alert_to_viewers("puts cards in deck", vision_distance = COMBAT_MESSAGE_RANGE)
		return
	return ..()

/*
|| Syndicate playing cards, for pretending you're Gambit and playing poker for the nuke disk. ||
*/
/obj/item/toy/cards/deck/syndicate
	name = "suspicious looking deck of cards"
	desc = "A deck of space-grade playing cards. They seem unusually rigid."
	icon_state = "deck_syndicate_full"
	deckstyle = "syndicate"
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 5
	throwforce = 10
	throw_speed = 3
	throw_range = 7
	attack_verb_continuous = list("attacks", "slices", "dices", "slashes", "cuts")
	attack_verb_simple = list("attack", "slice", "dice", "slash", "cut")
	resistance_flags = NONE
	shuffle_time = DECK_SYNDIE_SHUFFLE_TIME

#undef DECK_SHUFFLE_TIME
#undef DECK_SYNDIE_SHUFFLE_TIME
