
/obj/machinery/airalarm/crowbar_act(mob/living/user, obj/item/tool)
	if(build_stage != AIRALARM_BUILD_NO_WIRES)
		return
	user.visible_message(span_notice("[user.name] removes the electronics from [name]."), \
						span_notice("You start prying out the circuit..."))
	tool.play_tool_sound(src)
	if (tool.use_tool(src, user, 20))
		if (build_stage == AIRALARM_BUILD_NO_WIRES)
			to_chat(user, span_notice("You remove the air alarm electronics."))
			new /obj/item/electronics/airalarm(drop_location())
			playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)
			build_stage = AIRALARM_BUILD_NO_CIRCUIT
			update_appearance()
	return TRUE

/obj/machinery/airalarm/screwdriver_act(mob/living/user, obj/item/tool)
	if(build_stage != AIRALARM_BUILD_COMPLETE)
		return
	tool.play_tool_sound(src)
	panel_open = !panel_open
	to_chat(user, span_notice("The wires have been [panel_open ? "exposed" : "unexposed"]."))
	update_appearance()
	return TRUE

/obj/machinery/airalarm/wirecutter_act(mob/living/user, obj/item/tool)
	if(!(build_stage == AIRALARM_BUILD_COMPLETE && panel_open && wires.is_all_cut()))
		return
	tool.play_tool_sound(src)
	to_chat(user, span_notice("You cut the final wires."))
	var/obj/item/stack/cable_coil/cables = new(drop_location(), 5)
	user.put_in_hands(cables)
	build_stage = AIRALARM_BUILD_NO_WIRES
	update_appearance()
	return TRUE

/obj/machinery/airalarm/wrench_act(mob/living/user, obj/item/tool)
	if(build_stage != AIRALARM_BUILD_NO_CIRCUIT)
		return
	to_chat(user, span_notice("You detach \the [src] from the wall."))
	tool.play_tool_sound(src)
	var/obj/item/wallframe/airalarm/alarm_frame = new(drop_location())
	user.put_in_hands(alarm_frame)
	qdel(src)
	return TRUE

/obj/machinery/airalarm/attackby(obj/item/W, mob/user, params)
	update_last_used(user)
	switch(build_stage)
		if(AIRALARM_BUILD_COMPLETE)
			if(W.GetID())// trying to unlock the interface with an ID card
				togglelock(user)
				return
			else if(panel_open && is_wire_tool(W))
				wires.interact(user)
				return
		if(AIRALARM_BUILD_NO_WIRES)
			if(istype(W, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/cable = W
				if(cable.get_amount() < 5)
					to_chat(user, span_warning("You need five lengths of cable to wire the air alarm!"))
					return
				user.visible_message(span_notice("[user.name] wires the air alarm."), \
									span_notice("You start wiring the air alarm..."))
				if (do_after(user, 20, target = src))
					if (cable.get_amount() >= 5 && build_stage == AIRALARM_BUILD_NO_WIRES)
						cable.use(5)
						to_chat(user, span_notice("You wire the air alarm."))
						wires.repair()
						ai_disabled = 0
						locked = FALSE
						mode = 1
						shorted = 0
						post_alert(0)
						build_stage = AIRALARM_BUILD_COMPLETE
						update_appearance()
				return
		if(AIRALARM_BUILD_NO_CIRCUIT)
			if(istype(W, /obj/item/electronics/airalarm))
				if(user.temporarilyRemoveItemFromInventory(W))
					to_chat(user, span_notice("You insert the circuit."))
					build_stage = AIRALARM_BUILD_NO_WIRES
					update_appearance()
					qdel(W)
				return

			if(istype(W, /obj/item/electroadaptive_pseudocircuit))
				var/obj/item/electroadaptive_pseudocircuit/P = W
				if(!P.adapt_circuit(user, 25))
					return
				user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
				span_notice("You adapt an air alarm circuit and slot it into the assembly."))
				build_stage = AIRALARM_BUILD_NO_WIRES
				update_appearance()
				return

	return ..()

/obj/machinery/airalarm/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((build_stage == AIRALARM_BUILD_NO_CIRCUIT) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/machinery/airalarm/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
			span_notice("You adapt an air alarm circuit and slot it into the assembly."))
			build_stage = AIRALARM_BUILD_NO_WIRES
			update_appearance()
			return TRUE
	return FALSE

/obj/machinery/airalarm/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(!can_interact(user))
		return
	if(!user.canUseTopic(src, !issilicon(user)) || !isturf(loc))
		return
	togglelock(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/airalarm/proc/togglelock(mob/living/user)
	if(machine_stat & (NOPOWER|BROKEN))
		to_chat(user, span_warning("It does nothing!"))
	else
		if(src.allowed(usr) && !wires.is_cut(WIRE_IDSCAN))
			locked = !locked
			to_chat(user, span_notice("You [ locked ? "lock" : "unlock"] the air alarm interface."))
			updateUsrDialog()
		else
			to_chat(user, span_danger("Access denied."))
	return

/obj/machinery/airalarm/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	visible_message(span_warning("Sparks fly out of [src]!"), span_notice("You emag [src], disabling its safeties."))
	playsound(src, SFX_SPARKS, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/machinery/airalarm/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/iron(loc, 2)
		var/obj/item/I = new /obj/item/electronics/airalarm(loc)
		if(!disassembled)
			I.take_damage(I.max_integrity * 0.5, sound_effect=FALSE)
		new /obj/item/stack/cable_coil(loc, 3)
	qdel(src)
