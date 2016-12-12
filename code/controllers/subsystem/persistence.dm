var/datum/subsystem/persistence/SSpersistence

/datum/subsystem/persistence
	name = "Persistence"
	init_order = -100
	flags = SS_NO_FIRE
	var/savefile/secret_satchels
	var/savefile/chisel_messages
	var/savefile/trophy_items
	var/list/satchel_blacklist 		= list() //this is a typecache
	var/list/new_secret_satchels 	= list() //these are objects
	var/list/new_chisel_messages 	= list() //these are also objects
	var/old_secret_satchels 		= ""
	var/old_chisel_messages 		= ""
	var/old_trophy_list				= ""
/datum/subsystem/persistence/New()
	NEW_SS_GLOBAL(SSpersistence)

/datum/subsystem/persistence/Initialize()
	secret_satchels = new /savefile("data/npc_saves/SecretSatchels.sav")
	chisel_messages = new /savefile("data/npc_saves/ChiselMessages.sav")
	trophy_items = new /savefile("data/npc_saves/TrophyItems.sav")
	satchel_blacklist = typecacheof(list(/obj/item/stack/tile/plasteel, /obj/item/weapon/crowbar))
	secret_satchels[MAP_NAME] >> old_secret_satchels
	chisel_messages[MAP_NAME] >> old_chisel_messages
	trophy_items >> old_trophy_list

	var/list/expanded_old_satchels = list()
	var/placed_satchels = 0

	var/list/expanded_old_chisels = list()

	var/list/expanded_trophy_items = list()

	if(!isnull(old_secret_satchels))
		expanded_old_satchels = splittext(old_secret_satchels,"#")
		if(PlaceSecretSatchel(expanded_old_satchels))
			placed_satchels++
	else
		expanded_old_satchels.len = 0

	if(!isnull(old_chisel_messages))
		expanded_old_chisels = splittext(old_chisel_messages,"#")
		PlaceChiselMessage(expanded_old_chisels)
	else
		expanded_old_chisels.len = 0

	if(!isnull(old_trophy_list))
		expanded_trophy_items = splittext(old_trophy_list,"#")
		SetUpTrophies(expanded_trophy_items)
	else
		expanded_trophy_items.len = 0

	var/list/free_satchels = list()
	for(var/turf/T in shuffle(block(locate(TRANSITIONEDGE,TRANSITIONEDGE,ZLEVEL_STATION), locate(world.maxx-TRANSITIONEDGE,world.maxy-TRANSITIONEDGE,ZLEVEL_STATION)))) //Nontrivially expensive but it's roundstart only
		if(isfloorturf(T) && !istype(T,/turf/open/floor/plating/))
			free_satchels += new /obj/item/weapon/storage/backpack/satchel/flat/secret(T)
			if(!isemptylist(free_satchels) && ((free_satchels.len + placed_satchels) >= (50 - expanded_old_satchels.len) * 0.1)) //up to six tiles, more than enough to kill anything that moves
				break

	..()

/datum/subsystem/persistence/proc/CollectData()
	CollectSecretSatchels()
	CollectChiselMessages()
	CollectTrophies()

/datum/subsystem/persistence/proc/PlaceSecretSatchel(list/expanded_old_satchels)
	var/satchel_string

	if(expanded_old_satchels.len >= 20) //guards against low drop pools assuring that one player cannot reliably find his own gear.
		satchel_string = pick_n_take(expanded_old_satchels)

	old_secret_satchels = jointext(expanded_old_satchels,"#")
	secret_satchels[MAP_NAME] << old_secret_satchels

	var/list/chosen_satchel = splittext(satchel_string,"|")
	if(!chosen_satchel || isemptylist(chosen_satchel) || chosen_satchel.len != 3) //Malformed
		return 0

	var/path = text2path(chosen_satchel[3]) //If the item no longer exist, this returns null
	if(!path)
		return 0

	var/obj/item/weapon/storage/backpack/satchel/flat/F = new()
	F.x = text2num(chosen_satchel[1])
	F.y = text2num(chosen_satchel[2])
	F.z = ZLEVEL_STATION
	if(isfloorturf(F.loc) && !istype(F.loc,/turf/open/floor/plating/))
		F.hide(1)
	new path(F)
	return 1

/datum/subsystem/persistence/proc/PlaceChiselMessage(list/expanded_old_chisels)
	for(var/chisel_string in expanded_old_chisels)

		old_chisel_messages = jointext(expanded_old_chisels,"#")
		chisel_messages[MAP_NAME] << old_chisel_messages

		var/list/chosen_chisel = splittext(chisel_string,"|")
		if(!chosen_chisel || isemptylist(chosen_chisel) || chosen_chisel.len != 3) //Malformed
			continue

		var/obj/structure/chisel_message/M = new()
		M.x = text2num(chosen_chisel[1])
		M.y = text2num(chosen_chisel[2])
		M.z = ZLEVEL_STATION
		M.hidden_message = chosen_chisel[3]
	return 1

/datum/subsystem/persistence/proc/CollectSecretSatchels()
	for(var/A in new_secret_satchels)
		var/obj/item/weapon/storage/backpack/satchel/flat/F = A
		if(qdeleted(F) || F.z != ZLEVEL_STATION || F.invisibility != INVISIBILITY_MAXIMUM)
			continue
		var/list/savable_obj = list()
		for(var/obj/O in F)
			if(is_type_in_typecache(O, satchel_blacklist) || O.admin_spawned)
				continue
			if(O.persistence_replacement)
				savable_obj += O.persistence_replacement
			else
				savable_obj += O.type
		if(isemptylist(savable_obj))
			continue
		old_secret_satchels += "[F.x]|[F.y]|[pick(savable_obj)]#"
	secret_satchels[MAP_NAME] << old_secret_satchels

/datum/subsystem/persistence/proc/CollectChiselMessages()
	for(var/A in new_chisel_messages)
		var/obj/structure/chisel_message/M = A
		if(qdeleted(M) || M.z != ZLEVEL_STATION)
			continue
		old_chisel_messages += "[M.x]|[M.y]|[M.hidden_message]#"
	chisel_messages[MAP_NAME] << old_chisel_messages

/datum/subsystem/persistence/proc/CollectTrophies()
	for(var/A in trophy_cases)
		var/obj/structure/displaycase/T = A
		if(T.showpiece)
			old_trophy_list += "[T.showpiece.type]|[T.trophy_message]#"
	trophy_items << old_trophy_list

/datum/subsystem/persistence/proc/SetUpTrophies(list/expanded_trophy_items)
	for(var/A in trophy_cases)
		var/obj/structure/displaycase/T = A
		T.added_roundstart = 1

		var/trophy_string = pick_n_take(expanded_trophy_items)

		old_trophy_list = jointext(expanded_trophy_items,"#")
		trophy_items << old_trophy_list

		var/list/chosen_trophy = splittext(trophy_string,"|")
		if(!chosen_trophy || isemptylist(chosen_trophy) || chosen_trophy.len != 2) //Malformed
			continue

		var/path = text2path(chosen_trophy[1]) //If the item no longer exist, this returns null
		if(!path)
			continue

		T.showpiece = new path
		T.trophy_message = chosen_trophy[2]
		T.update_icon()