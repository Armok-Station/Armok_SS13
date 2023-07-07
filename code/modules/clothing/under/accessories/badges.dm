// Badges, pins, and other very small items that slot onto a shirt.
/obj/item/clothing/accessory/lawyers_badge
	name = "attorney's badge"
	desc = "Fills you with the conviction of JUSTICE. Lawyers tend to want to show it to everyone they meet."
	icon_state = "lawyerbadge"

/obj/item/clothing/accessory/lawyers_badge/attack_self(mob/user)
	if(prob(1))
		user.say("The testimony contradicts the evidence!", forced = "attorney's badge")
	user.visible_message(span_notice("[user] shows [user.p_their()] attorney's badge."), span_notice("You show your attorney's badge."))

/obj/item/clothing/accessory/lawyers_badge/accessory_equipped(obj/item/clothing/under/clothes, mob/living/user)
	RegisterSignal(user, COMSIG_LIVING_SLAM_TABLE, PROC_REF(table_slam))
	user.bubble_icon = "lawyer"

/obj/item/clothing/accessory/lawyers_badge/accessory_dropped(obj/item/clothing/under/clothes, mob/living/user)
	UnregisterSignal(user, COMSIG_LIVING_SLAM_TABLE)
	user.bubble_icon = initial(user.bubble_icon)

/obj/item/clothing/accessory/lawyers_badge/proc/table_slam(mob/living/source, obj/structure/table/the_table)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(handle_table_slam), source)

/obj/item/clothing/accessory/lawyers_badge/proc/handle_table_slam(mob/living/user)
	user.say("Objection!!", spans = list(SPAN_YELL), forced=TRUE)

/obj/item/clothing/accessory/clown_enjoyer_pin
	name = "\improper Clown Pin"
	desc = "A pin to show off your appreciation for clowns and clowning!"
	icon_state = "clown_enjoyer_pin"

/obj/item/clothing/accessory/clown_enjoyer_pin/accessory_equipped(obj/item/clothing/under/clothes, mob/living/user)
	if(HAS_TRAIT(user, TRAIT_CLOWN_ENJOYER))
		user.add_mood_event("clown_enjoyer_pin", /datum/mood_event/clown_enjoyer_pin)
	if(ishuman(user))
		var/mob/living/carbon/human/human_equipper = user
		human_equipper.fan_hud_set_fandom()

/obj/item/clothing/accessory/clown_enjoyer_pin/accessory_dropped(obj/item/clothing/under/clothes, mob/living/user)
	if(HAS_TRAIT(user, TRAIT_CLOWN_ENJOYER))
		user.clear_mood_event("clown_enjoyer_pin")
	if(ishuman(user))
		var/mob/living/carbon/human/human_equipper = user
		human_equipper.fan_hud_set_fandom()

/obj/item/clothing/accessory/mime_fan_pin
	name = "\improper Mime Pin"
	desc = "A pin to show off your appreciation for mimes and miming!"
	icon_state = "mime_fan_pin"

/obj/item/clothing/accessory/mime_fan_pin/accessory_equipped(obj/item/clothing/under/clothes, mob/living/user)
	if(HAS_TRAIT(user, TRAIT_MIME_FAN))
		user.add_mood_event("mime_fan_pin", /datum/mood_event/mime_fan_pin)
	if(ishuman(user))
		var/mob/living/carbon/human/human_equipper = user
		human_equipper.fan_hud_set_fandom()

/obj/item/clothing/accessory/mime_fan_pin/accessory_dropped(obj/item/clothing/under/clothes, mob/living/user)
	if(HAS_TRAIT(user, TRAIT_MIME_FAN))
		user.clear_mood_event("mime_fan_pin")
	if(ishuman(user))
		var/mob/living/carbon/human/human_equipper = user
		human_equipper.fan_hud_set_fandom()

/obj/item/clothing/accessory/pocketprotector
	name = "pocket protector"
	desc = "Can protect your clothing from ink stains, but you'll look like a nerd if you're using one."
	icon_state = "pocketprotector"

/obj/item/clothing/accessory/pocketprotector/Initialize(mapload)
	. = ..()
	create_storage(storage_type = /datum/storage/pockets/pocketprotector)

/obj/item/clothing/accessory/pocketprotector/detach(obj/item/clothing/under/detach_from)
	. = ..()
	var/drop_loc = drop_location()
	for(var/atom/movable/held as anything in src)
		held.forceMove(drop_loc)

/obj/item/clothing/accessory/pocketprotector/full

/obj/item/clothing/accessory/pocketprotector/full/Initialize(mapload)
	. = ..()
	new /obj/item/pen/red(src)
	new /obj/item/pen(src)
	new /obj/item/pen/blue(src)

/obj/item/clothing/accessory/pocketprotector/cosmetology

/obj/item/clothing/accessory/pocketprotector/cosmetology/Initialize(mapload)
	. = ..()
	for(var/i in 1 to 3)
		new /obj/item/lipstick/random(src)

/obj/item/clothing/accessory/dogtag
	/// What message is displayed when our dogtags / its clothes / its wearer is examined
	var/display = "Nothing!"

/obj/item/clothing/accessory/dogtag/examine(mob/user)
	. = ..()
	. += display

// Examining the clothes will display the examine message of the dogtag
/obj/item/clothing/accessory/dogtag/attach(obj/item/clothing/under/attach_to, mob/living/attacher)
	. = ..()
	RegisterSignal(attach_to, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/obj/item/clothing/accessory/dogtag/detach(obj/item/clothing/under/detach_from)
	. = ..()
	UnregisterSignal(detach_from, COMSIG_ATOM_EXAMINE)

// Double examining the person wearing the clothes will display the examine message of the dogtag
/obj/item/clothing/accessory/dogtag/accessory_equipped(obj/item/clothing/under/clothes, mob/living/user)
	. = ..()
	RegisterSignal(user, COMSIG_ATOM_EXAMINE_MORE, PROC_REF(on_examine))

/obj/item/clothing/accessory/dogtag/accessory_dropped(obj/item/clothing/under/clothes, mob/living/user)
	. = ..()
	UnregisterSignal(user, COMSIG_ATOM_EXAMINE_MORE)

/// Adds the examine message to the clothes and mob.
/obj/item/clothing/accessory/dogtag/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	// Only show the examine message if we're close (2 tiles)
	if(!IN_GIVEN_RANGE(get_turf(user), get_turf(src), 2))
		return

	examine_list += display

/obj/item/clothing/accessory/allergy_dogtag
	name = "Allergy dogtag"
	desc = "A dogtag with a listing of allergies."
	icon_state = "allergy"
	minimize_when_attached = TRUE
	attachment_slot = CHEST

/obj/item/clothing/accessory/allergy_dogtag/Initialize(mapload, allergy_string)
	. = ..()
	if(allergy_string)
		display = span_notice("The dogtag has a listing of allergies: [allergy_string]")
	else
		display = span_notice("The dogtags are all scratched up.")

/// Reskins for the pride pin accessory, mapped by display name to icon state
GLOBAL_LIST_INIT(pride_pin_reskins, list(
	"Rainbow Pride" = "pride",
	"Bisexual Pride" = "pride_bi",
	"Pansexual Pride" = "pride_pan",
	"Asexual Pride" = "pride_ace",
	"Non-binary Pride" = "pride_enby",
	"Transgender Pride" = "pride_trans",
	"Intersex Pride" = "pride_intersex",
	"Lesbian Pride" = "pride_lesbian",
))

/obj/item/clothing/accessory/pride
	name = "pride pin"
	desc = "A Nanotrasen Diversity & Inclusion Center-sponsored holographic pin to show off your pride, reminding the crew of their unwavering commitment to equity, diversity, and inclusion!"
	icon_state = "pride"
	obj_flags = UNIQUE_RENAME
	infinite_reskin = TRUE

/obj/item/clothing/accessory/pride/Initialize(mapload)
	. = ..()
	unique_reskin = GLOB.pride_pin_reskins

/obj/item/clothing/accessory/deaf_pin
	name = "deaf personnel pin"
	desc = "Indicates that the wearer is deaf."
	icon_state = "deaf_pin"
