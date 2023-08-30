/datum/action/cooldown/spell/pointed/burglar_finesse
	name = "Burglar's Finesse"
	desc = "Steal a random item from the victims backpack, or any other storage item if not found."
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	button_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "burglarsfinesse"

	school = SCHOOL_FORBIDDEN
	cooldown_time = 40 SECONDS

	invocation = "Y'O'K!"
	invocation_type = INVOCATION_WHISPER
	spell_requirements = NONE

	cast_range = 4

/datum/action/cooldown/spell/pointed/burglar_finesse/is_valid_target(atom/cast_on)
	return ..() && ishuman(cast_on) && (locate(/obj/item/storage) in cast_on.contents)

/datum/action/cooldown/spell/pointed/burglar_finesse/cast(mob/living/carbon/human/cast_on)
	. = ..()
	var/obj/storage_item = cast_on.get_item_by_slot(ITEM_SLOT_BACK)
	if(!storage_item)
		storage_item = locate(/obj/item/storage) in cast_on.contents
	
	if(!storage_item) //if we still didnt find one
		return FALSE

	var/item = pick(storage_item.contents)
	to_chat(cast_on, span_warning("Your [storage_item] feels lighter..."))
	to_chat(owner, span_notice("With a blink, you pull [item] out of [cast_on][p_s()] [storage_item]."))
	owner.put_in_active_hand(item)