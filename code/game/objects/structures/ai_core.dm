/obj/structure/ai_core
	density = TRUE
	anchored = FALSE
	name = "\improper AI core"
	icon = 'icons/mob/ai.dmi'
	icon_state = "0"
	desc = "The framework for an artificial intelligence core."
	max_integrity = 500
	var/state = EMPTY_CORE
	var/datum/ai_laws/laws
	var/obj/item/circuitboard/aicore/circuit
	var/obj/item/mmi/brain
	var/can_deconstruct = TRUE

/obj/structure/ai_core/Initialize(mapload)
	. = ..()
	laws = new
	laws.set_laws_config()

/obj/structure/ai_core/examine(mob/user)
	. = ..()
	if(!anchored)
		if(state != EMPTY_CORE)
			. += span_notice("It has some <b>bolts</b> that could be tightened.")
		else
			. += span_notice("The frame can be <b>melted</b> down.")
	else
		switch(state)
			if(EMPTY_CORE)
				. += span_notice("There is a <b>slot</b> for a circuit board, its <b>bolts</b> can be loosened.")
			if(CIRCUIT_CORE)
				. += span_notice("The circuit board can be <b>screwed</b> into place or <b>pried</b> out.")
			if(SCREWED_CORE)
				. += span_notice("The frame can be <b>wired</b>, the circuit board can be <b>unfastened</b>.")
			if(CABLED_CORE)
				if(!brain)
					. += span_notice("There are wires which could be hooked up to an <b>MMI or positronic brain</b>, or <b>cut</b>.")
				else
					var/accept_laws = TRUE
					if(!brain?.brainmob?.mind || !brain.brainmob || brain && brain.laws.id != DEFAULT_AI_LAWID)
						accept_laws = FALSE
					. += span_notice("There is a <b>slot</b> for a reinforced glass panel, the[brain.braintype == "Android" ? " positronic brain" : " MMI"] could be <b>pried</b> out.[accept_laws ? " A law module can be <b>swiped</b> across" : ""]")
			if(GLASS_CORE)
				. += span_notice("The monitor[brain?.brainmob?.mind ? " and neural interfaces" : " "]can be <b>screwed</b> in, the panel can be <b>pried</b> out.")
			if(AI_READY_CORE)
				. += span_notice("The monitor's connection can be <b>cut</b>[brain?.brainmob?.mind ? " the neural interface can be <b>screwed</b> in." : "."]")

/obj/structure/ai_core/handle_atom_del(atom/A)
	if(A == circuit)
		circuit = null
		if((state != GLASS_CORE) && (state != AI_READY_CORE))
			state = EMPTY_CORE
			update_appearance()
	if(A == brain)
		brain = null
	return ..()


/obj/structure/ai_core/Destroy()
	QDEL_NULL(circuit)
	QDEL_NULL(brain)
	QDEL_NULL(laws)
	return ..()

/obj/structure/ai_core/deactivated
	name = "inactive AI"
	icon_state = "ai-empty"
	anchored = TRUE
	state = AI_READY_CORE

/obj/structure/ai_core/deactivated/Initialize(mapload)
	. = ..()
	circuit = new(src)

/obj/structure/ai_core/latejoin_inactive
	name = "networked AI core"
	desc = "This AI core is connected by bluespace transmitters to NTNet, allowing for an AI personality to be downloaded to it on the fly mid-shift."
	can_deconstruct = FALSE
	icon_state = "ai-empty"
	anchored = TRUE
	state = AI_READY_CORE
	var/available = TRUE
	var/safety_checks = TRUE
	var/active = TRUE

/obj/structure/ai_core/latejoin_inactive/Initialize(mapload)
	. = ..()
	circuit = new(src)
	GLOB.latejoin_ai_cores += src

/obj/structure/ai_core/latejoin_inactive/Destroy()
	GLOB.latejoin_ai_cores -= src
	return ..()

/obj/structure/ai_core/latejoin_inactive/examine(mob/user)
	. = ..()
	. += "Its transmitter seems to be <b>[active? "on" : "off"]</b>."
	. += span_notice("You could [active? "deactivate" : "activate"] it with a multitool.")

/obj/structure/ai_core/latejoin_inactive/proc/is_available() //If people still manage to use this feature to spawn-kill AI latejoins ahelp them.
	if(!available)
		return FALSE
	if(!safety_checks)
		return TRUE
	if(!active)
		return FALSE
	var/turf/T = get_turf(src)
	var/area/A = get_area(src)
	if(!(A.area_flags & BLOBS_ALLOWED))
		return FALSE
	if(!A.power_equip)
		return FALSE
	if(!SSmapping.level_trait(T.z,ZTRAIT_STATION))
		return FALSE
	if(!istype(T, /turf/open/floor))
		return FALSE
	return TRUE

/obj/structure/ai_core/latejoin_inactive/attackby(obj/item/P, mob/user, params)
	if(P.tool_behaviour == TOOL_MULTITOOL)
		active = !active
		to_chat(user, span_notice("You [active? "activate" : "deactivate"] \the [src]'s transmitters."))
		return
	return ..()

/obj/structure/ai_core/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/structure/ai_core/screwdriver_act(mob/living/user, obj/item/tool)
	. = ..()
	if(state == AI_READY_CORE && brain?.brainmob?.mind)
		balloon_alert(user, "connecting neural network...")
		if(!tool.use_tool(src, user, 10 SECONDS))
			return
		if(!ai_structure_to_mob())
			return
		balloon_alert(user, "connected neural network")
		return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/structure/ai_core/attackby(obj/item/P, mob/user, params)
	if(!anchored)
		if(P.tool_behaviour == TOOL_WELDER && can_deconstruct)
			if(state != EMPTY_CORE)
				balloon_alert(user, "core must be empty to deconstruct it!")
				return

			if(!P.tool_start_check(user, amount=0))
				return

			balloon_alert(user, "deconstructing frame...")
			if(P.use_tool(src, user, 20, volume=50) && state == EMPTY_CORE)
				balloon_alert(user, "deconstructed frame")
				deconstruct(TRUE)
			return
		else
			balloon_alert(user, "bolt it down first!")
			return
	else
		switch(state)
			if(EMPTY_CORE)
				if(istype(P, /obj/item/circuitboard/aicore))
					if(!user.transferItemToLoc(P, src))
						return
					playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)
					balloon_alert(user, "circuit board inserted")
					update_appearance()
					state = CIRCUIT_CORE
					circuit = P
					return
			if(CIRCUIT_CORE)
				if(P.tool_behaviour == TOOL_SCREWDRIVER)
					P.play_tool_sound(src)
					balloon_alert(user, "board screwed into place")
					state = SCREWED_CORE
					update_appearance()
					return
				if(P.tool_behaviour == TOOL_CROWBAR)
					P.play_tool_sound(src)
					balloon_alert(user, "circuit board removed")
					state = EMPTY_CORE
					update_appearance()
					circuit.forceMove(loc)
					circuit = null
					return
			if(SCREWED_CORE)
				if(P.tool_behaviour == TOOL_SCREWDRIVER && circuit)
					P.play_tool_sound(src)
					balloon_alert(user, "circuit board unfastened")
					state = CIRCUIT_CORE
					update_appearance()
					return
				if(istype(P, /obj/item/stack/cable_coil))
					var/obj/item/stack/cable_coil/C = P
					if(C.get_amount() >= 5)
						playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)
						balloon_alert(user, "adding cables to frame...")
						if(do_after(user, 20, target = src) && state == SCREWED_CORE && C.use(5))
							balloon_alert(user, "added cables to frame.")
							state = CABLED_CORE
							update_appearance()
					else
						balloon_alert(user, "need five lengths of cable!")
					return
			if(CABLED_CORE)
				if(P.tool_behaviour == TOOL_WIRECUTTER)
					if(brain)
						balloon_alert(user, "remove the [brain.braintype == "Android" ? "brain" : "MMI"] first!")
					else
						P.play_tool_sound(src)
						balloon_alert(user, "cables removed")
						state = SCREWED_CORE
						update_appearance()
						new /obj/item/stack/cable_coil(drop_location(), 5)
					return

				if(istype(P, /obj/item/stack/sheet/rglass))
					if(!brain)
						balloon_alert(user, "add a brain first!")
						return
					var/obj/item/stack/sheet/rglass/G = P
					if(G.get_amount() >= 2)
						playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)
						balloon_alert(user, "adding glass panel...")
						if(do_after(user, 20, target = src) && state == CABLED_CORE && G.use(2))
							balloon_alert(user, "added glass panel")
							state = GLASS_CORE
							update_appearance()
					else
						balloon_alert(user, "need two sheets of reinforced glass!")
					return

				if(istype(P, /obj/item/ai_module))
					if(!brain?.brainmob || !brain?.brainmob?.mind)
						balloon_alert(user, "[brain.braintype == "Android" ? "brain" : "MMI"] is inactive!")
						return
					if(brain && brain.laws.id != DEFAULT_AI_LAWID)
						balloon_alert(user, "[brain.braintype == "Android" ? "brain" : "MMI"] already has set laws!")
						return
					var/obj/item/ai_module/module = P
					module.install(laws, user)
					return

				if(istype(P, /obj/item/mmi) && !brain)
					var/obj/item/mmi/M = P
					if(!M.brain_check(user))
						var/install = tgui_alert(user, "This [brain.braintype == "Android" ? "brain" : "MMI"] is inactive, would you like to make an inactive AI?", "Installing AI [brain.braintype == "Android" ? "Brain" : "MMI"]", list("Yes", "No"))
						if(install == "No")
							return
						else
							if(!user.transferItemToLoc(M, src))
								return
							brain = M
							balloon_alert(user, "added [brain.braintype == "Android" ? "brain" : "MMI"] to frame")
							update_appearance()
							return

					var/mob/living/brain/B = M.brainmob
					if(!CONFIG_GET(flag/allow_ai) || (is_banned_from(B.ckey, JOB_AI) && !QDELETED(src) && !QDELETED(user) && !QDELETED(M) && !QDELETED(user) && Adjacent(user)))
						if(!QDELETED(M))
							to_chat(user, span_warning("This [M.name] does not seem to fit!"))
						return
					if(!user.transferItemToLoc(M,src))
						return

					brain = M
					balloon_alert(user, "added [brain.braintype == "Android" ? "brain" : "MMI"] to frame")
					update_appearance()
					return

				if(P.tool_behaviour == TOOL_CROWBAR && brain)
					P.play_tool_sound(src)
					balloon_alert(user, "removed [brain.braintype == "Android" ? "brain" : "MMI"]")
					brain.forceMove(loc)
					brain = null
					update_appearance()
					return

			if(GLASS_CORE)
				if(P.tool_behaviour == TOOL_CROWBAR)
					P.play_tool_sound(src)
					balloon_alert(user, "removed glass panel")
					state = CABLED_CORE
					update_appearance()
					new /obj/item/stack/sheet/rglass(loc, 2)
					return

				if(P.tool_behaviour == TOOL_SCREWDRIVER)
					P.play_tool_sound(src)
					balloon_alert(user, "connected monitor[brain?.brainmob?.mind ? " and neural network" : ""]")
					if(brain.brainmob?.mind)
						ai_structure_to_mob(from_glass_core_to_mob = TRUE)
					else
						state = AI_READY_CORE
						update_appearance()
					return

			if(AI_READY_CORE)
				if(istype(P, /obj/item/aicard))
					return //handled by /obj/structure/ai_core/transfer_ai()

				if(P.tool_behaviour == TOOL_WIRECUTTER)
					P.play_tool_sound(src)
					balloon_alert(user, "disconnected monitor")
					state = GLASS_CORE
					update_appearance()
					return
	return ..()

/obj/structure/ai_core/proc/ai_structure_to_mob(from_glass_core_to_mob = FALSE)
	var/mob/living/brain/the_brainmob = brain.brainmob
	if(!the_brainmob.mind)
		return FALSE
	the_brainmob.mind?.remove_antags_for_borging()

	var/mob/living/silicon/ai/ai_mob = null

	if(brain.overrides_aicore_laws)
		ai_mob = new /mob/living/silicon/ai(loc, brain.laws, the_brainmob)
		brain.laws = null //Brain's law datum is being donated, so we need the brain to let it go or the GC will eat it
	else
		ai_mob = new /mob/living/silicon/ai(loc, laws, the_brainmob)
		laws = null //we're giving the new AI this datum, so let's not delete it when we qdel(src) 5 lines from now

	if(brain.force_replace_ai_name)
		ai_mob.fully_replace_character_name(ai_mob.name, brain.replacement_ai_name())
	if(brain.braintype == "Android")
		ai_mob.posibrain_core = TRUE
	if(from_glass_core_to_mob)
		SSblackbox.record_feedback("amount", "ais_created", 1)
	deadchat_broadcast(" has been brought online at <b>[get_area_name(ai_mob, TRUE)]</b>.", span_name("[ai_mob]"), follow_target = ai_mob, message_type = DEADCHAT_ANNOUNCEMENT)
	qdel(src)
	return TRUE

/obj/structure/ai_core/update_icon_state()
	switch(state)
		if(EMPTY_CORE)
			icon_state = "0"
		if(CIRCUIT_CORE)
			icon_state = "1"
		if(SCREWED_CORE)
			icon_state = "2"
		if(CABLED_CORE)
			if(brain)
				icon_state = "3b"
			else
				icon_state = "3"
		if(GLASS_CORE)
			icon_state = "4"
		if(AI_READY_CORE)
			icon_state = "ai-empty"
	return ..()

/obj/structure/ai_core/deconstruct(disassembled = TRUE)
	if(state == GLASS_CORE)
		new /obj/item/stack/sheet/rglass(loc, 2)
	if(state >= CABLED_CORE)
		new /obj/item/stack/cable_coil(loc, 5)
	if(circuit)
		circuit.forceMove(loc)
		circuit = null
	new /obj/item/stack/sheet/plasteel(loc, 4)
	qdel(src)

/*
This is a good place for AI-related object verbs so I'm sticking it here.
If adding stuff to this, don't forget that an AI need to cancel_camera() whenever it physically moves to a different location.
That prevents a few funky behaviors.
*/
//The type of interaction, the player performing the operation, the AI itself, and the card object, if any.


/atom/proc/transfer_ai(interaction, mob/user, mob/living/silicon/ai/AI, obj/item/aicard/card)
	if(istype(card))
		if(card.flush)
			to_chat(user, span_alert("ERROR: AI flush is in progress, cannot execute transfer protocol."))
			return FALSE
	return TRUE

/obj/structure/ai_core/transfer_ai(interaction, mob/user, mob/living/silicon/ai/AI, obj/item/aicard/card)
	if(state != AI_READY_CORE || !..() || brain?.brainmob?.mind)
		return
	//Transferring a carded AI to a core.
	if(interaction == AI_TRANS_FROM_CARD)
		AI.control_disabled = FALSE
		AI.radio_enabled = TRUE
		AI.forceMove(loc) // to replace the terminal.
		to_chat(AI, span_notice("You have been uploaded to a stationary terminal. Remote device connection restored."))
		to_chat(user, "[span_boldnotice("Transfer successful")]: [AI.name] ([rand(1000,9999)].exe) installed and executed successfully. Local copy has been removed.")
		card.AI = null
		AI.battery = circuit.battery
		qdel(src)
	else //If for some reason you use an empty card on an empty AI terminal.
		to_chat(user, span_alert("There is no AI loaded on this terminal."))

/obj/item/circuitboard/aicore
	name = "AI core (AI Core Board)" //Well, duh, but best to be consistent
	var/battery = 200 //backup battery for when the AI loses power. Copied to/from AI mobs when carding, and placed here to avoid recharge via deconning the core
