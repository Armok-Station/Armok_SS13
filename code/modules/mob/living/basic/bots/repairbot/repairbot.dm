
/mob/living/basic/bot/repairbot
	name = "\improper Repairbot"
	desc = "I can fix it!"
	icon = 'icons/mob/silicon/aibots.dmi'
	icon_state = "repairbot_base"
	base_icon_state = "repairbot_base"
	pass_flags = parent_type::pass_flags | PASSTABLE
	density = FALSE
	layer = BELOW_MOB_LAYER
	anchored = FALSE
	health = 100
	can_be_held = TRUE
	maxHealth = 100
	path_image_color = "#80dae7"
	req_one_access = list(ACCESS_ROBOTICS, ACCESS_ENGINEERING)
	radio_key = /obj/item/encryptionkey/headset_service
	radio_channel = RADIO_CHANNEL_ENGINEERING
	bot_type = REPAIR_BOT
//	additional_access = /datum/id_trim/job/engineer
	ai_controller = /datum/ai_controller/basic_controller/bot/repairbot
	///our iron stack
	var/obj/item/stack/sheet/iron/our_iron
	///our glass stack
	var/obj/item/stack/sheet/glass/our_glass
	///our floor stack
	var/obj/item/stack/tile/iron/our_tiles //testing -iron-
	///our welder
	var/obj/item/weldingtool/repairbot/our_welder
	///our crowbar
	var/obj/item/crowbar/our_crowbar
	///our iron rods
	var/obj/item/stack/rods/our_rods
	///possible interactions
	var/static/list/possible_stack_interactions = list(
		/obj/item/stack/sheet/iron = typecacheof(list(/obj/structure/girder)),
		/obj/item/stack/tile = typecacheof(list(/turf/open/space, /turf/open/floor/plating)),
		/obj/item/stack/sheet/glass = typecacheof(list(/obj/structure/grille)),
	)
	var/static/list/possible_tool_interactions = list(
		/obj/item/weldingtool/repairbot = typecacheof(list(/obj/machinery, /obj/structure/window)),
		/obj/item/crowbar = typecacheof(list(/turf/open/floor)),
	)
	///our flags
	var/repairbot_flags = REPAIRBOT_FIX_BREACHES | REPAIRBOT_FIX_GIRDERS | REPAIRBOT_FIX_GRILLES | REPAIRBOT_REPLACE_TILES | REPAIRBOT_BUILD_GIRDERS
	///our color
	var/toolbox_color = "#445eb3"
	///toolbox type we drop on death
	var/toolbox

/mob/living/basic/bot/repairbot/Initialize(mapload)
	. = ..()
	var/static/list/abilities = list(
		/datum/action/cooldown/mob_cooldown/bot/build_girder = BB_GIRDER_BUILD_ABILITY,
	)
	grant_actions_by_list(abilities)
	add_traits(list(TRAIT_SPACEWALK, TRAIT_NEGATES_GRAVITY, TRAIT_MOB_MERGE_STACKS, TRAIT_FIREDOOR_OPENNER), INNATE_TRAIT)
	our_welder = new(src)
	our_welder.switched_on(src)
	our_crowbar = new(src)
	our_rods = new(src, our_rods::max_amount)
	//testing purposes
	our_iron = new(src, our_iron::max_amount)
	our_glass = new(src, 50)
	our_tiles = new(src, 50)
	set_color(toolbox_color)
	START_PROCESSING(SSobj, src)

/mob/living/basic/bot/repairbot/proc/set_color(new_color)
	add_atom_colour(new_color, FIXED_COLOUR_PRIORITY)
	toolbox_color = new_color

/mob/living/basic/bot/repairbot/attackby(obj/item/stack/potential_stack, mob/living/carbon/human/user, list/modifiers)
	var/static/list/our_contents = list(/obj/item/stack/sheet/iron, /obj/item/stack/sheet/glass, /obj/item/stack/tile, /obj/item/stack/rods)
	for(var/obj/item/stack/content as anything in our_contents)
		if(!istype(potential_stack, content))
			continue
		var/obj/item/stack/our_sheet = locate(content) in src
		if(isnull(our_sheet))
			potential_stack.forceMove(src)
			return
		if(our_sheet.amount >= our_sheet.max_amount)
			user.balloon_alert(user, "full!")
			return
		if(!our_sheet.can_merge(potential_stack))
			return
		var/atom/movable/to_move = potential_stack.split_stack(user, min(our_sheet.max_amount - our_sheet.amount, potential_stack.amount))
		to_move.forceMove(src)
		return
	return ..()

/mob/living/basic/bot/repairbot/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(istype(arrived, /obj/item/stack/sheet/iron) && isnull(our_iron))
		our_iron = arrived
	if(istype(arrived, /obj/item/stack/sheet/glass) && isnull(our_glass))
		our_glass = arrived
	if(istype(arrived, /obj/item/stack/tile) && isnull(our_tiles))
		our_tiles = arrived
	if(istype(arrived, /obj/item/stack/rods) && isnull(our_rods))
		our_rods = arrived
	update_appearance()

/mob/living/basic/bot/repairbot/UnarmedAttack(atom/target, proximity_flag, list/modifiers)
	. = ..()

	if(!. || !proximity_flag)
		return

	//priority interactions
	if(istype(target, /turf/open/space))
		var/turf/open/space/space_target = target
		if(!space_target.has_valid_support() && !(locate(/obj/structure/lattice) in space_target))
			our_rods?.melee_attack_chain(src, space_target)

	if(istype(target, /obj/structure/grille))
		var/obj/structure/grille/grille_target = target
		if(grille_target.broken)
			our_rods?.melee_attack_chain(src, grille_target)

	if(istype(target, /turf/open))
		var/turf/open/open_target = target
		if(open_target.broken || open_target.burnt)
			our_welder?.melee_attack_chain(src, open_target)

	//stack interactions
	for(var/type in possible_stack_interactions)
		var/obj/item/target_stack = locate(type) in src
		if(isnull(target_stack))
			continue
		if(!is_type_in_typecache(target, possible_stack_interactions[type]))
			continue
		target_stack.melee_attack_chain(src, target)
		return

	//tool interactions
	var/list/our_tools = list(our_welder, our_crowbar)
	for(var/obj/item/tool in our_tools)
		if(is_type_in_typecache(target, possible_tool_interactions[tool.type]) && !combat_mode)
			tool.melee_attack_chain(src, target)
			return

/mob/living/basic/bot/repairbot/Exited(atom/movable/gone, direction)
	if(gone == our_tiles)
		our_tiles = null
	if(gone == our_iron)
		our_iron = null
	if(gone == our_glass)
		our_glass = null
	if(gone == our_rods)
		our_rods = null
	update_appearance()
	return ..()

/mob/living/basic/bot/repairbot/process(seconds_per_tick) //generate 1 iron rod every 2 seconds
	if(isnull(our_rods) || our_rods.amount < our_rods.max_amount)
		new /obj/item/stack/rods(src)
	//testing purposes
	if(isnull(our_iron) || our_iron.amount < our_iron.max_amount)
		new /obj/item/stack/sheet/iron(src)
	if(isnull(our_glass) || our_glass.amount < our_glass.max_amount)
		new /obj/item/stack/sheet/glass(src)
	if(isnull(our_tiles) || our_tiles.amount < our_tiles.max_amount)
		new /obj/item/stack/tile/iron(src)


/mob/living/basic/bot/repairbot/turn_on()
	. = ..()
	if(!.)
		return
	START_PROCESSING(SSobj, src)

/mob/living/basic/bot/repairbot/turn_off()
	. = ..()
	STOP_PROCESSING(SSobj, src)

/mob/living/basic/bot/repairbot/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "repairbot[bot_mode_flags & BOT_MODE_ON]", appearance_flags = RESET_COLOR)
	if(our_glass)
		. +=  mutable_appearance(icon, "repairbot_glass_overlay", BELOW_MOB_LAYER + 0.02, appearance_flags = RESET_COLOR)
	if(our_iron)
		. +=  mutable_appearance(icon, "repairbot_iron_overlay", BELOW_MOB_LAYER + 0.01, appearance_flags = RESET_COLOR)
	if(our_tiles)
		. +=  mutable_appearance(icon, "repairbot_tile_overlay", BELOW_MOB_LAYER + 0.03, appearance_flags = RESET_COLOR)

/mob/living/basic/bot/repairbot/update_icon_state()
	. = ..()
	icon_state = base_icon_state

/mob/living/basic/bot/proc/attempt_access(mob/bot, obj/door_attempt)
	SIGNAL_HANDLER

	. = ..()
	if(istype(door_attempt, /obj/machinery/door/firedoor) && door_attempt.density)
		our_crowbar?.melee_attack_chain(src, door_attempt)


/mob/living/basic/bot/repairbot/ui_data(mob/user)
	var/list/data = ..()
	if(!(bot_access_flags & BOT_COVER_LOCKED) || issilicon(user) || isAdminGhostAI(user))
		data["custom_controls"]["fix_breaches"] = repairbot_flags & REPAIRBOT_FIX_BREACHES
		data["custom_controls"]["fix_grilles"] = repairbot_flags & REPAIRBOT_FIX_GRILLES
		data["custom_controls"]["replace_tiles"] = repairbot_flags & REPAIRBOT_REPLACE_TILES
		data["custom_controls"]["fix_girders"] = repairbot_flags & REPAIRBOT_FIX_GIRDERS
		data["custom_controls"]["build_girders"] = repairbot_flags & REPAIRBOT_BUILD_GIRDERS
	return data

/mob/living/basic/bot/honkbot/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(. || !isliving(ui.user) || (bot_access_flags & BOT_COVER_LOCKED) && !(ui.user.has_unlimited_silicon_privilege))
		return
	switch(action)
		if("fix_breaches")
			repairbot_flags ^= REPAIRBOT_FIX_BREACHES
		if("fix_grilles")
			repairbot_flags ^= REPAIRBOT_FIX_GRILLES
		if("replace_tiles")
			repairbot_flags ^= REPAIRBOT_REPLACE_TILES
		if("fix_girders")
			repairbot_flags ^= REPAIRBOT_FIX_GIRDERS
		if("build_girders")
			repairbot_flags ^= REPAIRBOT_BUILD_GIRDERS


/obj/item/weldingtool/repairbot
	max_fuel = INFINITY
	starting_fuel = TRUE

/mob/living/basic/bot/repairbot/mob_pickup(mob/living/user)
	var/obj/item/carried_repairbot/carried = new(get_turf(src))
	carried.set_bot(src)
	user.visible_message(span_warning("[user] scoops up [src]!"))
	user.put_in_hands(carried)

/obj/item/carried_repairbot
	desc = "A most robust bot!"
	attack_verb_continuous = list("robusts")
	attack_verb_simple = list("robust")
	hitsound = 'sound/weapons/smash.ogg'
	drop_sound = 'sound/items/handling/toolbox_drop.ogg'
	pickup_sound = 'sound/items/handling/toolbox_pickup.ogg'
	///the bot we own
	var/atom/movable/our_bot

/obj/item/carried_repairbot/proc/set_bot(mob/living/basic/bot/repairbot/repairbot)
	var/obj/item/bot_toolbox = repairbot.toolbox
	icon = repairbot.icon
	icon_state = repairbot.icon_state
	lefthand_file = bot_toolbox::lefthand_file
	righthand_file = bot_toolbox::righthand_file
	inhand_icon_state = bot_toolbox::inhand_icon_state
	force = bot_toolbox::force
	repairbot.forceMove(src)
	add_atom_colour(repairbot.toolbox_color, FIXED_COLOUR_PRIORITY)

/obj/item/carried_repairbot/dropped()
	. = ..()
	if(isturf(loc))
		release_bot()

/obj/item/carried_repairbot/proc/release_bot(bypass_delete = FALSE)
	if(!isnull(our_bot))
		our_bot.forceMove(drop_location())
		our_bot.balloon_alert_to_viewers("plops down")
	if(!bypass_delete)
		qdel(src)

/obj/item/carried_repairbot/Destroy()
	. = ..()
	release_bot(bypass_delete = TRUE)

/obj/item/carried_repairbot/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(isliving(arrived))
		our_bot = arrived

/obj/item/carried_repairbot/Exited(atom/movable/gone, direction)
	if(gone == our_bot)
		our_bot = null
	return ..()
