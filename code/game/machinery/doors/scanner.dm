/obj/machinery/scannerright
	name = "mysterious scanner"
	desc = "Why would this level of security be justified?"
	icon = 'icons/obj/machines/greytopia.dmi'
	icon_state = "right"
	anchored = TRUE
	dir = 1

/obj/machinery/scannerleft
	name = "mysterious scanner"
	desc = "None of this makes any sense..."
	icon = 'icons/obj/machines/greytopia.dmi'
	icon_state = "left"
	anchored = TRUE
	dir = 1

/obj/machinery/doorscanner
	name = "mysterious scanner"
	desc = "What are assistants doing with this kind of technology?"
	icon = 'icons/obj/machines/greytopia.dmi'
	icon_state = "center"
	anchored = TRUE
	var/obj/machinery/door/airlock/vault/scanner/gate
	var/working = FALSE
	dir = 1

/obj/machinery/doorscanner/Initialize()
	. = ..()
	for(var/obj/machinery/door/airlock/vault/scanner/check in range(3, loc))
		gate = check
		break
	if(!gate)
		qdel(src)

/obj/machinery/doorscanner/Crossed(atom/movable/AM)
	if(!gate)
		return
	if(ishuman(AM) && !working)
		var/mob/living/carbon/human/H = AM
		if(gate.approved.Find(H))
			playsound(src, 'sound/machines/synth_yes.ogg', 50, 0)
			return
		working = TRUE
		var/obj/effect/overlay/holoray/scanray/S = new(get_turf(src))
		if(do_after(H, 100, target = H))
			if(H.wear_id && (H.wear_id.GetJobName() == "Assistant") && H.w_uniform && istype(H.w_uniform, /obj/item/clothing/under/color/grey) && H.shoes && istype(H.shoes, /obj/item/clothing/shoes/sneakers/black))
				playsound(src, 'sound/machines/microwave/microwave-end.ogg', 75, 0)
				gate.approved += H
				qdel(S)
				working = FALSE
				return
		S.color = "red"
		playsound(src, 'sound/machines/buzz-two.ogg', 100, 0)
		sleep(20)
		qdel(S)
		working = FALSE

/obj/machinery/door/airlock/vault/scanner
	name = "inner gate of greytopia"
	armor = list(melee = 50, bullet = 50, laser = 50, energy = 50, bomb = 50, bio = 100, rad = 100, fire = 100, acid = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	heat_proof = TRUE
	air_tight = TRUE
	aiControlDisabled = TRUE
	hackProof = TRUE
	normalspeed = FALSE
	safe = FALSE
	var/list/approved = list()

/obj/machinery/door/airlock/vault/scanner/CollidedWith(atom/movable/AM)
	if(isliving(AM) && approved.Find(AM))
		open()
	return !density && ..()

/obj/machinery/door/airlock/vault/scanner/try_to_activate_door(mob/living/user)
	if(approved.Find(user))
		open()
	else
		do_animate("deny")
		var/atom/throwtarget
		throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(user, src)))
		user.Knockdown(40)
		user.throw_at(throwtarget, 5, 1, src)

/obj/machinery/door/airlock/vault/scanner/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	return FALSE

/obj/machinery/door/airlock/vault/scanner/emag_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	return FALSE

/obj/machinery/door/airlock/vault/scanner/emp_act(severity)
	return

/obj/machinery/door/password/voice/greytopia
	name = "outer gate of greytopia"
	autoclose = TRUE
	safe = FALSE

/obj/machinery/door/password/voice/greytopia/try_to_activate_door(mob/user)
	add_fingerprint(user)
	if(operating)
		return
	if(density)
		do_animate("deny")

/obj/machinery/door/password/voice/greytopia/Initialize()
	. = ..()
	password = pick("greytide","condom","rules","toolbox")
	desc = "An imposing door with a message etched into its surface: 'Utter the word to complete the saying:'<br>"
	switch(password)
		if("greytide")
			desc += "<b>________ worldwide!!</b>"
		if("condom")
			desc += "<b>Captain is a ______!!</b>"
		if("rules")
			desc += "<b>No captain, No _____!!</b>"
		if("toolbox")
			desc += "<b>There isn't a problem you can't solve with a _______ to the head.</b>"


/obj/effect/overlay/holoray/scanray
	name = "scanning beam"
	icon_state = "scanray"
	pixel_x = -32
	pixel_y = -8