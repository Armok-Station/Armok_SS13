<<<<<<< HEAD
/*!
=======
/*
>>>>>>> Updated this old code to fork
	This datum should be used for handling mineral contents of machines and whatever else is supposed to hold minerals and make use of them.

	Variables:
		amount - raw amount of the mineral this container is holding, calculated by the defined value MINERAL_MATERIAL_AMOUNT=2000.
		max_amount - max raw amount of mineral this container can hold.
		sheet_type - type of the mineral sheet the container handles, used for output.
		parent - object that this container is being used by, used for output.
		MAX_STACK_SIZE - size of a stack of mineral sheets. Constant.
*/

/datum/component/material_container
	var/total_amount = 0
	var/max_amount
	var/sheet_type
<<<<<<< HEAD
	var/list/materials //Map of key = material ref | Value = amount
=======
	var/list/materials
>>>>>>> Updated this old code to fork
	var/show_on_examine
	var/disable_attackby
	var/list/allowed_typecache
	var/last_inserted_id
	var/precise_insertion = FALSE
	var/datum/callback/precondition
	var/datum/callback/after_insert

<<<<<<< HEAD
/// Sets up the proper signals and fills the list of materials with the appropriate references.
=======
>>>>>>> Updated this old code to fork
/datum/component/material_container/Initialize(list/mat_list, max_amt = 0, _show_on_examine = FALSE, list/allowed_types, datum/callback/_precondition, datum/callback/_after_insert, _disable_attackby)
	materials = list()
	max_amount = max(0, max_amt)
	show_on_examine = _show_on_examine
	disable_attackby = _disable_attackby

	if(allowed_types)
		if(ispath(allowed_types) && allowed_types == /obj/item/stack)
			allowed_typecache = GLOB.typecache_stack
		else
			allowed_typecache = typecacheof(allowed_types)

	precondition = _precondition
	after_insert = _after_insert

	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, .proc/OnAttackBy)
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/OnExamine)

<<<<<<< HEAD
	for(var/mat in mat_list) //Make the assoc list ref | amount
		var/datum/material/M = getmaterialref(mat) || mat
		materials[M] = 0
=======
	var/list/possible_mats = list()
	for(var/mat_type in subtypesof(/datum/material))
		var/datum/material/MT = mat_type
		possible_mats[initial(MT.id)] = mat_type
	for(var/id in mat_list)
		if(possible_mats[id])
			var/mat_path = possible_mats[id]
			materials[id] = new mat_path()
>>>>>>> Updated this old code to fork

/datum/component/material_container/proc/OnExamine(datum/source, mob/user)
	if(show_on_examine)
		for(var/I in materials)
<<<<<<< HEAD
			var/datum/material/M = I
			var/amt = materials[I]
			if(amt)
				to_chat(user, "<span class='notice'>It has [amt] units of [lowertext(M.name)] stored.</span>")

/// Proc that allows players to fill the parent with mats
=======
			var/datum/material/M = materials[I]
			var/amt = amount(M.id)
			if(amt)
				to_chat(user, "<span class='notice'>It has [amt] units of [lowertext(M.name)] stored.</span>")

>>>>>>> Updated this old code to fork
/datum/component/material_container/proc/OnAttackBy(datum/source, obj/item/I, mob/living/user)
	var/list/tc = allowed_typecache
	if(disable_attackby)
		return
	if(user.a_intent != INTENT_HELP)
		return
	if(I.item_flags & ABSTRACT)
		return
	if((I.flags_1 & HOLOGRAM_1) || (I.item_flags & NO_MAT_REDEMPTION) || (tc && !is_type_in_typecache(I, tc)))
		to_chat(user, "<span class='warning'>[parent] won't accept [I]!</span>")
		return
	. = COMPONENT_NO_AFTERATTACK
	var/datum/callback/pc = precondition
	if(pc && !pc.Invoke(user))
		return
	var/material_amount = get_item_material_amount(I)
	if(!material_amount)
		to_chat(user, "<span class='warning'>[I] does not contain sufficient amounts of metal or glass to be accepted by [parent].</span>")
		return
	if(!has_space(material_amount))
		to_chat(user, "<span class='warning'>[parent] is full. Please remove metal or glass from [parent] in order to insert more.</span>")
		return
	user_insert(I, user)

<<<<<<< HEAD
/// Proc used for when player inserts materials
=======
>>>>>>> Updated this old code to fork
/datum/component/material_container/proc/user_insert(obj/item/I, mob/living/user)
	set waitfor = FALSE
	var/requested_amount
	var/active_held = user.get_active_held_item()  // differs from I when using TK
	if(istype(I, /obj/item/stack) && precise_insertion)
		var/atom/current_parent = parent
		var/obj/item/stack/S = I
		requested_amount = input(user, "How much do you want to insert?", "Inserting [S.singular_name]s") as num|null
		if(isnull(requested_amount) || (requested_amount <= 0))
			return
		if(QDELETED(I) || QDELETED(user) || QDELETED(src) || parent != current_parent || user.physical_can_use_topic(current_parent) < UI_INTERACTIVE || user.get_active_held_item() != active_held)
			return
	if(!user.temporarilyRemoveItemFromInventory(I))
		to_chat(user, "<span class='warning'>[I] is stuck to you and cannot be placed into [parent].</span>")
		return
	var/inserted = insert_item(I, stack_amt = requested_amount)
	if(inserted)
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			to_chat(user, "<span class='notice'>You insert [inserted] [S.singular_name][inserted>1 ? "s" : ""] into [parent].</span>")
			if(!QDELETED(I) && I == active_held && !user.put_in_hands(I))
				stack_trace("Warning: User could not put object back in hand during material container insertion, line [__LINE__]! This can lead to issues.")
				I.forceMove(user.drop_location())
		else
			to_chat(user, "<span class='notice'>You insert a material total of [inserted] into [parent].</span>")
			qdel(I)
		if(after_insert)
			after_insert.Invoke(I.type, last_inserted_id, inserted)
	else if(I == active_held)
		user.put_in_active_hand(I)

<<<<<<< HEAD
/// Proc specifically for inserting items, returns the amount of materials entered.
/datum/component/material_container/proc/insert_item(obj/item/I, var/multiplier = 1, stack_amt)
=======
//For inserting an amount of material
/datum/component/material_container/proc/insert_amount(amt, id = null)
	if(amt > 0 && has_space(amt))
		var/total_amount_saved = total_amount
		if(id)
			var/datum/material/M = materials[id]
			if(M)
				M.amount += amt
				total_amount += amt
		else
			for(var/i in materials)
				var/datum/material/M = materials[i]
				M.amount += amt
				total_amount += amt
		return (total_amount - total_amount_saved)
	return FALSE

/datum/component/material_container/proc/insert_stack(obj/item/stack/S, amt, multiplier = 1)
	if(isnull(amt))
		amt = S.amount

	if(amt <= 0)
		return FALSE

	if(amt > S.amount)
		amt = S.amount

	var/material_amt = get_item_material_amount(S)
	if(!material_amt)
		return FALSE

	amt = min(amt, round(((max_amount - total_amount) / material_amt)))
	if(!amt)
		return FALSE

	last_inserted_id = insert_materials(S,amt * multiplier)
	S.use(amt)
	return amt

/datum/component/material_container/proc/insert_item(obj/item/I, multiplier = 1, stack_amt)
>>>>>>> Updated this old code to fork
	if(!I)
		return FALSE
	if(istype(I, /obj/item/stack))
		return insert_stack(I, stack_amt, multiplier)

<<<<<<< HEAD
	multiplier = CEILING(multiplier, 0.01)

=======
>>>>>>> Updated this old code to fork
	var/material_amount = get_item_material_amount(I)
	if(!material_amount || !has_space(material_amount))
		return FALSE

<<<<<<< HEAD
	last_inserted_id = insert_item_materials(I, multiplier)
	return material_amount

/datum/component/material_container/proc/insert_item_materials(obj/item/I, multiplier = 1)
	var/primary_mat
	var/max_mat_value = 0
	for(var/MAT in materials)
		materials[MAT] += I.materials[MAT] * multiplier
=======
	last_inserted_id = insert_materials(I, multiplier)
	return material_amount

/datum/component/material_container/proc/insert_materials(obj/item/I, multiplier = 1) //for internal usage only
	var/datum/material/M
	var/primary_mat
	var/max_mat_value = 0
	for(var/MAT in materials)
		M = materials[MAT]
		M.amount += I.materials[MAT] * multiplier
>>>>>>> Updated this old code to fork
		total_amount += I.materials[MAT] * multiplier
		if(I.materials[MAT] > max_mat_value)
			primary_mat = MAT
	return primary_mat

<<<<<<< HEAD
/// Proc for putting a stack inside of the container
/datum/component/material_container/proc/insert_stack(obj/item/stack/S, amt, multiplier = 1) 
	if(isnull(amt))
		amt = S.amount

	if(amt <= 0)
		return FALSE

	if(amt > S.amount)
		amt = S.amount

	var/material_amt = get_item_material_amount(S)
	if(!material_amt)
		return FALSE

	amt = min(amt, round(((max_amount - total_amount) / material_amt)))
	if(!amt)
		return FALSE

	last_inserted_id = insert_item_materials(S,amt * multiplier)
	S.use(amt)
	return amt

/// For inserting an amount of material
/datum/component/material_container/proc/insert_amount_mat(amt, var/datum/material/mat) 
	if(!istype(mat))
		mat = getmaterialref(mat)
	if(amt > 0 && has_space(amt))
		var/total_amount_saved = total_amount
		if(mat)
			materials[mat] += amt
		else
			for(var/i in materials)
				materials[i] += amt
				total_amount += amt
		return (total_amount - total_amount_saved)
	return FALSE

/// Uses an amount of a specific material, effectively removing it.
/datum/component/material_container/proc/use_amount_mat(amt, var/datum/material/mat) 
	if(!istype(mat))
		mat = getmaterialref(mat)
	var/amount = materials[mat]
	if(mat)
		if(amount >= amt)
			materials[mat] -= amt
=======
//For consuming material
//mats is a list of types of material to use and the corresponding amounts, example: list(MAT_METAL=100, MAT_GLASS=200)
/datum/component/material_container/proc/use_amount(list/mats, multiplier=1)
	if(!mats || !mats.len)
		return FALSE

	var/datum/material/M
	for(var/MAT in materials)
		M = materials[MAT]
		if(M.amount < (mats[MAT] * multiplier))
			return FALSE

	var/total_amount_save = total_amount
	for(var/MAT in materials)
		M = materials[MAT]
		M.amount -= mats[MAT] * multiplier
		total_amount -= mats[MAT] * multiplier

	return total_amount_save - total_amount


/datum/component/material_container/proc/use_amount_type(amt, id)
	var/datum/material/M = materials[id]
	if(M)
		if(M.amount >= amt)
			M.amount -= amt
>>>>>>> Updated this old code to fork
			total_amount -= amt
			return amt
	return FALSE

<<<<<<< HEAD
/// Proc for transfering materials to another container.
/datum/component/material_container/proc/transer_amt_to(var/datum/component/material_container/T, amt, var/datum/material/mat) 
	if(!istype(mat))
		mat = getmaterialref(mat)
	if((amt==0)||(!T)||(!mat))
		return FALSE
	if(amt<0)
		return T.transer_amt_to(src, -amt, mat)
	var/tr = min(amt, materials[mat],T.can_insert_amount_mat(amt, mat))
	if(tr)
		use_amount_mat(tr, mat)
		T.insert_amount_mat(tr, mat)
		return tr
	return FALSE

/// Proc for checking if there is room in the component, returning the amount or else the amount lacking.
/datum/component/material_container/proc/can_insert_amount_mat(amt, mat)
	if(amt && mat)
		var/datum/material/M = mat
=======
/datum/component/material_container/proc/transer_amt_to(var/datum/component/material_container/T, amt, id)
	if((amt==0)||(!T)||(!id))
		return FALSE
	if(amt<0)
		return T.transer_amt_to(src, -amt, id)
	var/datum/material/M = materials[id]

	if(M)
		var/tr = min(amt, M.amount,T.can_insert_amount(amt, id))
		if(tr)
			use_amount_type(tr, id)
			T.insert_amount(tr, id)
			return tr
	return FALSE

/datum/component/material_container/proc/can_insert_amount(amt, id)
	if(amt && id)
		var/datum/material/M = materials[id]
>>>>>>> Updated this old code to fork
		if(M)
			if((total_amount + amt) <= max_amount)
				return amt
			else
				return	(max_amount-total_amount)

<<<<<<< HEAD

/// For consuming a dictionary of materials. mats is the map of materials to use and the corresponding amounts, example: list(M/datum/material/glass =100, datum/material/iron=200)
/datum/component/material_container/proc/use_materials(list/mats, multiplier=1)
	if(!mats || !length(mats))
		return FALSE
	
	var/list/mats_to_remove = list() //Assoc list MAT | AMOUNT

	for(var/x in mats) //Loop through all required materials
		var/datum/material/req_mat = x
		if(!istype(req_mat))
			req_mat = getmaterialref(req_mat) //Get the ref if necesary
		if(!materials[req_mat]) //Do we have the resource?
			return FALSE //Can't afford it
		var/amount_required = mats[x] * multiplier
		if(!(materials[req_mat] >= amount_required)) // do we have enough of the resource?
			return FALSE //Can't afford it
		mats_to_remove[req_mat] += amount_required //Add it to the assoc list of things to remove
		continue
		
	var/total_amount_save = total_amount

	for(var/i in mats_to_remove)
		total_amount_save -= use_amount_mat(mats_to_remove[i], i)

	return total_amount_save - total_amount

/// For spawning mineral sheets at a specific location. Used by machines to output sheets.
/datum/component/material_container/proc/retrieve_sheets(sheet_amt, var/datum/material/M, target = null) 
	if(!M.sheet_type)
		return 0 //Add greyscale sheet handling here later
=======
/datum/component/material_container/proc/can_use_amount(amt, id, list/mats)
	if(amt && id)
		var/datum/material/M = materials[id]
		if(M && M.amount >= amt)
			return TRUE
	else if(istype(mats))
		for(var/M in mats)
			if(materials[M] && (mats[M] <= materials[M]))
				continue
			else
				return FALSE
		return TRUE
	return FALSE

//For spawning mineral sheets; internal use only
/datum/component/material_container/proc/retrieve(sheet_amt, datum/material/M, target = null)
	if(!M.sheet_type)
		return 0
>>>>>>> Updated this old code to fork
	if(sheet_amt <= 0)
		return 0

	if(!target)
		target = get_turf(parent)
<<<<<<< HEAD
	if(materials[M] < (sheet_amt * MINERAL_MATERIAL_AMOUNT))
		sheet_amt = round(materials[M] / MINERAL_MATERIAL_AMOUNT)
=======
	if(M.amount < (sheet_amt * MINERAL_MATERIAL_AMOUNT))
		sheet_amt = round(M.amount / MINERAL_MATERIAL_AMOUNT)
>>>>>>> Updated this old code to fork
	var/count = 0
	while(sheet_amt > MAX_STACK_SIZE)
		new M.sheet_type(target, MAX_STACK_SIZE)
		count += MAX_STACK_SIZE
<<<<<<< HEAD
		use_amount_mat(sheet_amt * MINERAL_MATERIAL_AMOUNT, M)
=======
		use_amount_type(sheet_amt * MINERAL_MATERIAL_AMOUNT, M.id)
>>>>>>> Updated this old code to fork
		sheet_amt -= MAX_STACK_SIZE
	if(sheet_amt >= 1)
		new M.sheet_type(target, sheet_amt)
		count += sheet_amt
<<<<<<< HEAD
		use_amount_mat(sheet_amt * MINERAL_MATERIAL_AMOUNT, M)
	return count


/// Proc to get all the materials and dump them as sheets
/datum/component/material_container/proc/retrieve_all(target = null) 
	var/result = 0
	for(var/MAT in materials)
		var/amount = materials[MAT]
		result += retrieve_sheets(amount2sheet(amount), MAT, target)
	return result

/// Proc that returns TRUE if the container has space
/datum/component/material_container/proc/has_space(amt = 0)
	return (total_amount + amt) <= max_amount

/// Checks if its possible to afford a certain amount of materials. Takes a dictionary of materials.
=======
		use_amount_type(sheet_amt * MINERAL_MATERIAL_AMOUNT, M.id)
	return count

/datum/component/material_container/proc/retrieve_sheets(sheet_amt, id, target = null)
	if(materials[id])
		return retrieve(sheet_amt, materials[id], target)
	return FALSE

/datum/component/material_container/proc/retrieve_amount(amt, id, target)
	return retrieve_sheets(amount2sheet(amt), id, target)

/datum/component/material_container/proc/retrieve_all(target = null)
	var/result = 0
	var/datum/material/M
	for(var/MAT in materials)
		M = materials[MAT]
		result += retrieve_sheets(amount2sheet(M.amount), MAT, target)
	return result

/datum/component/material_container/proc/has_space(amt = 0)
	return (total_amount + amt) <= max_amount

>>>>>>> Updated this old code to fork
/datum/component/material_container/proc/has_materials(list/mats, multiplier=1)
	if(!mats || !mats.len)
		return FALSE

<<<<<<< HEAD
	for(var/x in mats) //Loop through all required materials
		var/datum/material/req_mat = x
		if(!istype(req_mat))
			if(ispath(req_mat)) //Is this an actual material, or is it a category?
				req_mat = getmaterialref(req_mat) //Get the ref

			else // Its a category. (For example MAT_CATEGORY_RIGID)
				if(!has_enough_of_category(req_mat, mats[req_mat], multiplier)) //Do we have enough of this category?
					return FALSE
				else
					continue

		if(!has_enough_of_material(req_mat, mats[req_mat], multiplier))//Not a category, so just check the normal way
			return FALSE

	return TRUE

/// Returns all the categories in a recipe.
/datum/component/material_container/proc/get_categories(list/mats) 
	var/list/categories = list()
	for(var/x in mats) //Loop through all required materials
		if(!istext(x)) //This means its not a category
			continue
		categories += x
	return categories


/// Returns TRUE if you have enough of the specified material.
/datum/component/material_container/proc/has_enough_of_material(var/datum/material/req_mat, amount, multiplier=1) 
	if(!materials[req_mat]) //Do we have the resource?
		return FALSE //Can't afford it
	var/amount_required = amount * multiplier
	if(materials[req_mat] >= amount_required) // do we have enough of the resource?
		return TRUE 
	return FALSE //Can't afford it

/// Returns TRUE if you have enough of a specified material category (Which could be multiple materials)
/datum/component/material_container/proc/has_enough_of_category(category, amount, multiplier=1)
	for(var/i in SSmaterials.materials_by_category[category])
		var/datum/material/mat = i
		if(materials[mat] >= amount) //we have enough
			return TRUE
	return FALSE

/// Turns a material amount into the amount of sheets it should output
/datum/component/material_container/proc/amount2sheet(amt) 
=======
	var/datum/material/M
	for(var/MAT in mats)
		M = materials[MAT]
		if(M.amount < (mats[MAT] * multiplier))
			return FALSE
	return TRUE

/datum/component/material_container/proc/amount2sheet(amt)
>>>>>>> Updated this old code to fork
	if(amt >= MINERAL_MATERIAL_AMOUNT)
		return round(amt / MINERAL_MATERIAL_AMOUNT)
	return FALSE

<<<<<<< HEAD
/// Turns an amount of sheets into the amount of material amount it should output
=======
>>>>>>> Updated this old code to fork
/datum/component/material_container/proc/sheet2amount(sheet_amt)
	if(sheet_amt > 0)
		return sheet_amt * MINERAL_MATERIAL_AMOUNT
	return FALSE

<<<<<<< HEAD

///returns the amount of material relevant to this container; if this container does not support glass, any glass in 'I' will not be taken into account
=======
/datum/component/material_container/proc/amount(id)
	var/datum/material/M = materials[id]
	return M ? M.amount : 0

//returns the amount of material relevant to this container;
//if this container does not support glass, any glass in 'I' will not be taken into account
>>>>>>> Updated this old code to fork
/datum/component/material_container/proc/get_item_material_amount(obj/item/I)
	if(!istype(I))
		return FALSE
	var/material_amount = 0
	for(var/MAT in materials)
		material_amount += I.materials[MAT]
	return material_amount

<<<<<<< HEAD
/// Returns the amount of a specific material in this container.
/datum/component/material_container/proc/get_material_amount(var/datum/material/mat) 
	if(!istype(mat))
		mat = getmaterialref(mat)
	return(materials[mat])
=======

/datum/material
	var/name
	var/amount = 0
	var/id = null
	var/sheet_type = null
	var/coin_type = null

/datum/material/metal
	name = "Metal"
	id = MAT_METAL
	sheet_type = /obj/item/stack/sheet/metal
	coin_type = /obj/item/coin/iron

/datum/material/glass
	name = "Glass"
	id = MAT_GLASS
	sheet_type = /obj/item/stack/sheet/glass

/datum/material/silver
	name = "Silver"
	id = MAT_SILVER
	sheet_type = /obj/item/stack/sheet/mineral/silver
	coin_type = /obj/item/coin/silver

/datum/material/gold
	name = "Gold"
	id = MAT_GOLD
	sheet_type = /obj/item/stack/sheet/mineral/gold
	coin_type = /obj/item/coin/gold

/datum/material/diamond
	name = "Diamond"
	id = MAT_DIAMOND
	sheet_type = /obj/item/stack/sheet/mineral/diamond
	coin_type = /obj/item/coin/diamond

/datum/material/uranium
	name = "Uranium"
	id = MAT_URANIUM
	sheet_type = /obj/item/stack/sheet/mineral/uranium
	coin_type = /obj/item/coin/uranium

/datum/material/plasma
	name = "Solid Plasma"
	id = MAT_PLASMA
	sheet_type = /obj/item/stack/sheet/mineral/plasma
	coin_type = /obj/item/coin/plasma

/datum/material/bluespace
	name = "Bluespace Mesh"
	id = MAT_BLUESPACE
	sheet_type = /obj/item/stack/sheet/bluespace_crystal

/datum/material/bananium
	name = "Bananium"
	id = MAT_BANANIUM
	sheet_type = /obj/item/stack/sheet/mineral/bananium
	coin_type = /obj/item/coin/bananium

/datum/material/titanium
	name = "Titanium"
	id = MAT_TITANIUM
	sheet_type = /obj/item/stack/sheet/mineral/titanium

/datum/material/biomass
	name = "Biomass"
	id = MAT_BIOMASS

/datum/material/plastic
	name = "Plastic"
	id = MAT_PLASTIC
	sheet_type = /obj/item/stack/sheet/plastic
>>>>>>> Updated this old code to fork
