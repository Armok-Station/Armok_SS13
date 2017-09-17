/////////////
// DRIVERS //
/////////////

//Belligerent: Channeled for up to fifteen times over thirty seconds. Forces non-servants that can hear the chant to walk, doing minor damage. Nar-Sian cultists are burned.
/datum/clockwork_scripture/channeled/belligerent
	descname = "Channeled, Area Slowdown"
	name = "Belligerent"
	desc = "Forces all nearby non-servants to walk rather than run, doing minor damage. Chanted every two seconds for up to thirty seconds."
	chant_invocations = list("Punish their blindness!", "Take time, make slow!")
	chant_amount = 15
	chant_interval = 20
	channel_time = 20
	usage_tip = "Useful for crowd control in a populated area and disrupting mass movement."
	tier = SCRIPTURE_DRIVER
	primary_component = BELLIGERENT_EYE
	sort_priority = 1
	quickbind = TRUE
	quickbind_desc = "Forces nearby non-Servants to walk, doing minor damage with each chant.<br><b>Maximum 15 chants.</b>"

/datum/clockwork_scripture/channeled/belligerent/chant_effects(chant_number)
	for(var/mob/living/carbon/C in hearers(7, invoker))
		C.apply_status_effect(STATUS_EFFECT_BELLIGERENT)
	new /obj/effect/temp_visual/ratvar/belligerent(get_turf(invoker))
	return TRUE


//Sigil of Transgression: Creates a sigil of transgression, which briefly stuns and applies Belligerent to the first non-servant to cross it.
/datum/clockwork_scripture/create_object/sigil_of_transgression
	descname = "Trap, Stunning"
	name = "Sigil of Transgression"
	desc = "Wards a tile with a sigil, which will briefly stun the next non-Servant to cross it and apply Belligerent to them."
	invocations = list("Divinity, smite...", "...those who tresspass here!")
	channel_time = 50
	consumed_components = list(BELLIGERENT_EYE = 1)
	whispered = TRUE
	object_path = /obj/effect/clockwork/sigil/transgression
	creator_message = "<span class='brass'>A sigil silently appears below you. The next non-Servant to cross it will be smitten.</span>"
	usage_tip = "The sigil does not silence its victim, and is generally used to soften potential converts or would-be invaders."
	tier = SCRIPTURE_DRIVER
	one_per_tile = TRUE
	primary_component = BELLIGERENT_EYE
	sort_priority = 2
	quickbind = TRUE
	quickbind_desc = "Creates a Sigil of Transgression, which will briefly stun and slow the next non-Servant to cross it."


//Vanguard: Provides twenty seconds of stun immunity. At the end of the twenty seconds, 25% of all stuns absorbed are applied to the invoker.
/datum/clockwork_scripture/vanguard
	descname = "Self Stun Immunity"
	name = "Vanguard"
	desc = "Provides twenty seconds of stun immunity. At the end of the twenty seconds, the invoker is knocked down for the equivalent of 25% of all stuns they absorbed. \
	Excessive absorption will cause unconsciousness."
	invocations = list("Shield me...", "...from darkness!")
	channel_time = 30
	usage_tip = "You cannot reactivate Vanguard while still shielded by it."
	tier = SCRIPTURE_DRIVER
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 3
	quickbind = TRUE
	quickbind_desc = "Allows you to temporarily absorb stuns. All stuns absorbed will affect you when disabled."

/datum/clockwork_scripture/vanguard/check_special_requirements()
	if(!GLOB.ratvar_awakens && islist(invoker.stun_absorption) && invoker.stun_absorption["vanguard"] && invoker.stun_absorption["vanguard"]["end_time"] > world.time)
		to_chat(invoker, "<span class='warning'>You are already shielded by a Vanguard!</span>")
		return FALSE
	return TRUE

/datum/clockwork_scripture/vanguard/scripture_effects()
	if(GLOB.ratvar_awakens)
		for(var/mob/living/L in view(7, get_turf(invoker)))
			if(L.stat != DEAD && is_servant_of_ratvar(L))
				L.apply_status_effect(STATUS_EFFECT_VANGUARD)
			CHECK_TICK
	else
		invoker.apply_status_effect(STATUS_EFFECT_VANGUARD)
	return TRUE


//Sentinel's Compromise: Allows the invoker to select a nearby servant and convert their brute, burn, and oxygen damage into half as much toxin damage.
/datum/clockwork_scripture/ranged_ability/sentinels_compromise
	descname = "Convert Brute/Burn/Oxygen to Half Toxin"
	name = "Sentinel's Compromise"
	desc = "Charges your slab with healing power, allowing you to convert all of a target Servant's brute, burn, and oxygen damage to half as much toxin damage."
	invocations = list("Mend the wounds of...", "...my inferior flesh.")
	channel_time = 30
	consumed_components = list(VANGUARD_COGWHEEL = 1)
	usage_tip = "The Compromise is very fast to invoke, and will remove holy water from the target Servant."
	tier = SCRIPTURE_DRIVER
	primary_component = VANGUARD_COGWHEEL
	sort_priority = 4
	quickbind = TRUE
	quickbind_desc = "Allows you to convert a Servant's brute, burn, and oxygen damage to half toxin damage.<br><b>Click your slab to disable.</b>"
	slab_overlay = "compromise"
	ranged_type = /obj/effect/proc_holder/slab/compromise
	ranged_message = "<span class='inathneq_small'><i>You charge the clockwork slab with healing power.</i>\n\
	<b>Left-click a fellow Servant or yourself to heal!\n\
	Click your slab to cancel.</b></span>"


//Abscond: Used to return to Reebe.
/datum/clockwork_scripture/abscond
	descname = "Return to Reebe"
	name = "Abscond"
	desc = "Yanks you through space, returning you to home base."
	invocations = list("As we bid farewell, and return to the stars...", "...we shall find our way home.")
	whispered = TRUE
	channel_time = 50
	usage_tip = "This can't be used while on Reebe, for obvious reasons."
	tier = SCRIPTURE_DRIVER
	primary_component = GEIS_CAPACITOR
	sort_priority = 5
	quickbind = TRUE
	quickbind_desc = "Returns you to Reebe."

/datum/clockwork_scripture/abscond/check_special_requirements()
	if(invoker.z == ZLEVEL_CITYOFCOGS)
		to_chat(invoker, "<span class='danger'>You're already at Reebe.</span>")
		return
	return TRUE

/datum/clockwork_scripture/abscond/recital()
	animate(invoker.client, color = "#AF0AAF", time = 50)
	. = ..()

/datum/clockwork_scripture/abscond/scripture_effects()
	var/turf/T = get_turf(pick(GLOB.servant_spawns))
	invoker.visible_message("<span class='warning'>[invoker] flickers and phases out of existence!</span>", \
	"<span class='bold sevtug_small'>You feel a dizzying sense of vertigo as you're yanked back to Reebe!</span>")
	T.visible_message("<span class='warning'>[invoker] flickers and phases into existence!</span>")
	playsound(invoker, 'sound/magic/magic_missile.ogg', 50, TRUE)
	playsound(T, 'sound/magic/magic_missile.ogg', 50, TRUE)
	do_sparks(5, TRUE, invoker)
	do_sparks(5, TRUE, T)
	invoker.forceMove(T)
	if(invoker.client)
		animate(invoker.client, color = initial(invoker.client.color), time = 25)

/datum/clockwork_scripture/abscond/scripture_fail()
	if(invoker && invoker.client)
		animate(invoker.client, color = initial(invoker.client.color), time = 10)


//Kindle: Charges the slab with blazing energy. It can be released to stun and silence a target.
/datum/clockwork_scripture/ranged_ability/kindle
	descname = "Short-Range Single-Target Stun"
	name = "Kindle"
	desc = "Charges your slab with divine energy, allowing you to overwhelm a target with Ratvar's light."
	invocations = list("Divinity, show them your light!")
	whispered = TRUE
	channel_time = 30
	usage_tip = "The light can be used from up to two tiles away. Damage taken will GREATLY REDUCE the stun's duration."
	tier = SCRIPTURE_DRIVER
	primary_component = GEIS_CAPACITOR
	sort_priority = 6
	slab_overlay = "volt"
	ranged_type = /obj/effect/proc_holder/slab/kindle
	ranged_message = "<span class='brass'><i>You charge the clockwork slab with divine energy.</i>\n\
	<b>Left-click a target within melee range to stun!\n\
	Click your slab to cancel.</b></span>"
	timeout_time = 150
	quickbind = TRUE
	quickbind_desc = "Stuns and mutes a target from a short range."


//Sigil of Submission: Creates a sigil of submission, which converts one heretic above it after a delay.
/datum/clockwork_scripture/create_object/sigil_of_submission
	descname = "Trap, Conversion"
	name = "Sigil of Submission"
	desc = "Places a luminous sigil that will convert any non-Servants that remain on it for 8 seconds."
	invocations = list("Divinity, enlighten...", "...those who trespass here!")
	channel_time = 60
	consumed_components = list(GEIS_CAPACITOR = 1)
	whispered = TRUE
	object_path = /obj/effect/clockwork/sigil/submission
	creator_message = "<span class='brass'>A luminous sigil appears below you. Any non-Servants to cross it will be converted after 8 seconds if they do not move.</span>"
	usage_tip = "This is the primary conversion method, though it will not penetrate mindshield implants."
	tier = SCRIPTURE_DRIVER
	one_per_tile = TRUE
	primary_component = GEIS_CAPACITOR
	sort_priority = 6
	quickbind = TRUE
	quickbind_desc = "Creates a Sigil of Submission, which will convert non-Servants that remain on it."


//Replicant: Creates a new clockwork slab.
/datum/clockwork_scripture/create_object/replicant
	descname = "New Clockwork Slab"
	name = "Replicant"
	desc = "Creates a new clockwork slab."
	invocations = list("Metal, become greater!")
	channel_time = 10
	whispered = TRUE
	object_path = /obj/item/clockwork/slab
	creator_message = "<span class='brass'>You copy a piece of replicant alloy and command it into a new slab.</span>"
	usage_tip = "This is inefficient as a way to produce components, as the slab produced must be held by someone with no other slabs to produce components."
	tier = SCRIPTURE_DRIVER
	space_allowed = TRUE
	primary_component = REPLICANT_ALLOY
	sort_priority = 7
	quickbind = TRUE
	quickbind_desc = "Creates a new Clockwork Slab."


//Stargazer: Creates a stargazer, a cheap power generator that utilizes starlight.
/datum/clockwork_scripture/create_object/stargazer
	descname = "Necessary Structure, Generates Power From Starlight"
	name = "Stargazer"
	desc = "Forms a weak structure that generates power every second while within three tiles of starlight."
	invocations = list("Capture their inferior light for us!")
	channel_time = 50
	consumed_components = list(REPLICANT_ALLOY = 1)
	object_path = /obj/structure/destructible/clockwork/stargazer
	creator_message = "<span class='brass'>You form a stargazer, which will generate power near starlight.</span>"
	observer_message = "<span class='warning'>A large lantern-shaped machine forms!</span>"
	usage_tip = "For obvious reasons, make sure to place this near a window or somewhere else that can see space!"
	tier = SCRIPTURE_DRIVER
	one_per_tile = TRUE
	primary_component = REPLICANT_ALLOY
	sort_priority = 8
	quickbind = TRUE
	quickbind_desc = "Creates a Tinkerer's Cache, which stores components globally for slab access."


//Integration Cog: Creates an integration cog that can be inserted into APCs to passively siphon power.
/datum/clockwork_scripture/create_object/integration_cog
	descname = "APC Power Siphoner"
	name = "Integration Cog"
	desc = "Fabricates an integration cog, which can be used on an open APC to replace its innards and passively siphon its power."
	invocations = list("Take that which sustains them!")
	channel_time = 10
	whispered = TRUE
	object_path = /obj/item/clockwork/integration_cog
	creator_message = "<span class='brass'>You form an integration cog, which can be inserted into an open APC to passively siphon power.</span>"
	usage_tip = "Tampering isn't visible unless the APC is opened."
	tier = SCRIPTURE_DRIVER
	space_allowed = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 9
	quickbind = TRUE
	quickbind_desc = "Creates an integration cog, which can be used to siphon power from an open APC."


//Wraith Spectacles: Creates a pair of wraith spectacles, which grant xray vision but damage vision slowly.
/datum/clockwork_scripture/create_object/wraith_spectacles
	descname = "Limited Xray Vision Glasses"
	name = "Wraith Spectacles"
	desc = "Fabricates a pair of glasses which grant true sight but cause gradual vision loss."
	invocations = list("Show the truth of this world to me!")
	channel_time = 10
	consumed_components = list(HIEROPHANT_ANSIBLE = 1)
	whispered = TRUE
	object_path = /obj/item/clothing/glasses/wraith_spectacles
	creator_message = "<span class='brass'>You form a pair of wraith spectacles, which grant true sight but cause gradual vision loss.</span>"
	usage_tip = "\"True sight\" means that you are able to see through walls and in darkness."
	tier = SCRIPTURE_DRIVER
	space_allowed = TRUE
	primary_component = HIEROPHANT_ANSIBLE
	sort_priority = 10
	quickbind = TRUE
	quickbind_desc = "Creates a pair of Wraith Spectacles, which grant true sight but cause gradual vision loss."
