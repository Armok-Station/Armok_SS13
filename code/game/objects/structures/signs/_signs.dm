/obj/structure/sign
	icon = 'icons/obj/decals.dmi'
	anchored = TRUE
	opacity = 0
	density = FALSE
	layer = SIGN_LAYER
	custom_materials = list(/datum/material/plastic = 2000)
	max_integrity = 100
	armor = list("melee" = 50, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)
	///Determines if a sign is unwrenchable.
	var/buildable_sign = TRUE
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	resistance_flags = FLAMMABLE
	///This determines if you can select this sign type when using a pen on a sign backing. False by default, set to true per sign type to override.
	var/is_editable = FALSE
	///sign_change_name is used to make nice looking, alphebetized and categorized names when you use a pen on a sign backing.
	var/sign_change_name = "Sign - Blank" 

/obj/structure/sign/basic
	name = "sign backing"
	desc = "A plastic sign with adhesive backing, use a pen to change the decal. It can be detached from the wall with a wrench."
	icon_state = "backing"

obj/structure/sign/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = NONE)
	if(damage_type == BRUTE)
		if(damage_amount)
			playsound(loc, 'sound/weapons/slash.ogg', 80, TRUE)

/obj/structure/sign/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	user.examinate(src)

///This is a global list of all signs you can change an existing sign or new sign backing to, when using a pen on them.
GLOBAL_VAR(editable_sign_types)
/**
   * This proc populates GLOBAL_VAR(editable_sign_types)
   *
   * The first time a pen is used on any sign, this populates GLOBAL_VAR(editable_sign_types), a global list of all the signs that you can set a sign backing to with a pen.
   */
/proc/populate_editable_sign_types() //The first time a pen is used on any sign, this populates the above, a global list of all the signs that you can set a sign backing to with a pen.
	GLOB.editable_sign_types = list()
	for(var/s in subtypesof(/obj/structure/sign))
		var/obj/structure/sign/potential_sign = s
		if(!initial(potential_sign.is_editable))
			continue
		GLOB.editable_sign_types[initial(potential_sign.sign_change_name)] = potential_sign
	GLOB.editable_sign_types = sortList(GLOB.editable_sign_types) //Alphabetizes the results.

/obj/structure/sign/wrench_act(mob/living/user, obj/item/wrench/I)
	. = ..()
	user.visible_message("<span class='notice'>[user] starts removing [src]...</span>", \
						 "<span class='notice'>You start unfastening [src].</span>")
	I.play_tool_sound(src)
	if(!I.use_tool(src, user, 4 SECONDS))
		return TRUE
	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	user.visible_message("<span class='notice'>[user] unfastens [src].</span>", \
						 "<span class='notice'>You unfasten [src].</span>")
	var/obj/item/sign_backing/SB = new (get_turf(user))
	if(type != /obj/structure/sign/basic) //If it's still just a basic sign backing, we can (and should) skip some of the below variable transfers.
		SB.name = name //Copy over the sign structure variables to the sign item we're creating when we unwrench a sign.
		SB.desc = "[desc] It can be placed on a wall."
		SB.icon_state = icon_state
		SB.sign_path = type
	SB.obj_integrity = obj_integrity //Transfer how damaged it is.
	SB.setDir(dir)
	qdel(src) //The sign structure on the wall goes poof and only the sign item from unwrenching remains.
	return TRUE

/obj/structure/sign/attackby(obj/item/I, mob/user, params)
	if(is_editable && istype(I, /obj/item/pen))
		if(!length(GLOB.editable_sign_types))
			populate_editable_sign_types()
			if(!length(GLOB.editable_sign_types))
				CRASH("GLOB.editable_sign_types failed to populate")
		var/choice = input(user, "Select a sign type.", "Sign Customization") as null|anything in GLOB.editable_sign_types
		if(!choice)
			return
		if(!Adjacent(user)) //Make sure user is adjacent still.
			to_chat(user, "<span class='warning'>You need to stand next to the sign to change it!</span>")
			return
		user.visible_message("<span class='notice'>[user] begins changing [src].</span>", \
							 "<span class='notice'>You begin changing [src].</span>")
		if(!do_after(user, 4 SECONDS, target = src)) //Small delay for changing signs instead of it being instant, so somebody could be shoved or stunned to prevent them from doing so.
			return
		var/sign_type = GLOB.editable_sign_types[choice]
		//It's import to clone the pixel layout information.
		//Otherwise signs revert to being on the turf and
		//move jarringly.
		var/obj/structure/sign/newsign = new sign_type(get_turf(src))
		newsign.pixel_x = pixel_x
		newsign.pixel_y = pixel_y
		newsign.obj_integrity = obj_integrity
		qdel(src)
		user.visible_message("<span class='notice'>[user] finishes changing the sign.</span>", \
					 "<span class='notice'>You finish changing the sign.</span>")
		return
	return ..()

/obj/item/sign_backing/attackby(obj/item/I, mob/user, params)
	if(is_editable && istype(I, /obj/item/pen))
		if(!length(GLOB.editable_sign_types))
			populate_editable_sign_types()
			if(!length(GLOB.editable_sign_types))
				CRASH("GLOB.editable_sign_types failed to populate")
		var/choice = input(user, "Select a sign type.", "Sign Customization") as null|anything in GLOB.editable_sign_types
		if(!choice)
			return
		if(!Adjacent(user)) //Make sure user is adjacent still.
			to_chat(user, "<span class='warning'>You need to stand next to the sign to change it!</span>")
			return
		if(!choice)
			return
		user.visible_message("<span class='notice'>You begin changing [src].</span>")
		if(!do_after(user, 4 SECONDS, target = src))
			return
		var/obj/structure/sign/sign_type = GLOB.editable_sign_types[choice]
		name = initial(sign_type.name)
		desc = "[initial(sign_type.desc)] It can be placed on a wall."
		icon_state = initial(sign_type.icon_state)
		sign_path = sign_type	
		user.visible_message("<span class='notice'>You finish changing the sign.</span>")
		return
	return ..()

/obj/item/sign_backing
	name = "sign backing"
	desc = "A plastic sign with adhesive backing, use a pen to change the decal. It can be placed on a wall."
	icon = 'icons/obj/decals.dmi'
	icon_state = "backing"
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/plastic = 2000)
	armor = list("melee" = 50, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)
	resistance_flags = FLAMMABLE
	max_integrity = 100
	var/sign_path = /obj/structure/sign/basic //The type of sign structure that will be created when placed on a turf, the default looks just like a sign backing item.
	var/is_editable = TRUE

/obj/item/sign_backing/Initialize() //Signs not attached to walls are always rotated so they look like they're laying horizontal.
	. = ..()
	var/matrix/M = matrix()
	M.Turn(90)
	transform = M

/obj/item/sign_backing/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!iswallturf(target) || !proximity)
		return
	var/turf/T = target
	var/turf/userT = get_turf(user)
	var/obj/structure/sign/S = new sign_path(userT) //We place the sign on the turf the user is standing, and pixel shift it to the target wall, as below.
	//This is to mimic how signs and other wall objects are usually placed by mappers, and so they're only visible from one side of a wall.
	var/dir = get_dir(userT, T)
	switch(dir)
		if(NORTH)
			S.pixel_y = 32
		if(SOUTH)
			S.pixel_y = -32
		if(EAST)
			S.pixel_x = 32
		if(WEST)
			S.pixel_x = -32
		if(NORTHEAST)
			S.pixel_y = 32
			S.pixel_x = 32
		if(NORTHWEST)
			S.pixel_y = 32
			S.pixel_x = -32
		if(SOUTHEAST)
			S.pixel_y = -32
			S.pixel_x = 32
		if(SOUTHWEST)
			S.pixel_y = -32
			S.pixel_x = -32
	user.visible_message("<span class='notice'>[user] fastens [src] to [T].</span>", \
						 "<span class='notice'>You attach the sign to [T].</span>")
	playsound(T, 'sound/items/deconstruct.ogg', 50, TRUE)
	S.obj_integrity = obj_integrity
	S.setDir(dir)
	qdel(src)

/obj/item/sign_backing/Move(atom/new_loc, direct = 0)
	// Pulling, throwing, or conveying a sign backing does not rotate it.
	var/old_dir = dir
	. = ..()
	setDir(old_dir)

/obj/item/sign_backing/attack_self(mob/user)
	. = ..()
	setDir(turn(dir, 90))

/obj/structure/sign/nanotrasen
	name = "\improper Nanotrasen logo sign"
	sign_change_name = "Corporate Logo - Nanotrasen"
	desc = "A sign with the Nanotrasen logo on it. Glory to Nanotrasen!"
	icon_state = "nanotrasen"
	is_editable = TRUE

/obj/structure/sign/logo
	name = "\improper Nanotrasen logo sign"
	desc = "The Nanotrasen corporate logo."
	icon_state = "nanotrasen_sign1"
