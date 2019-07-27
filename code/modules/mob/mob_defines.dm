<<<<<<< HEAD
/**
  * The mob, usually meant to be a creature of some type
  *
  * Has a client attached that is a living person (most of the time), although I have to admit
  * sometimes it's hard to tell they're sentient
  *
  * Has a lot of the creature game world logic, such as health etc
  */
=======
>>>>>>> Updated this old code to fork
/mob
	datum_flags = DF_USE_TAG
	density = TRUE
	layer = MOB_LAYER
	animate_movement = 2
	flags_1 = HEAR_1
	hud_possible = list(ANTAG_HUD)
	pressure_resistance = 8
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	throwforce = 10

	var/lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
	var/datum/mind/mind
	var/static/next_mob_id = 0

<<<<<<< HEAD
	/// List of movement speed modifiers applying to this mob
	var/list/movespeed_modification				//Lazy list, see mob_movespeed.dm
	/// The calculated mob speed slowdown based on the modifiers list
	var/cached_multiplicative_slowdown
	/// List of action hud items the user has
	var/list/datum/action/actions = list()
	/// A special action? No idea why this lives here
	var/list/datum/action/chameleon_item_actions

	/// Whether a mob is alive or dead. TODO: Move this to living - Nodrak (2019, still here)
	var/stat = CONSCIOUS

	/* A bunch of this stuff really needs to go under their own defines instead of being globally attached to mob.
=======
	//MOVEMENT SPEED
	var/list/movespeed_modification				//Lazy list, see mob_movespeed.dm
	var/cached_multiplicative_slowdown
	//ACTIONS
	var/list/datum/action/actions = list()
	var/list/datum/action/chameleon_item_actions

	var/stat = CONSCIOUS //Whether a mob is alive or dead. TODO: Move this to living - Nodrak

	/*A bunch of this stuff really needs to go under their own defines instead of being globally attached to mob.
>>>>>>> Updated this old code to fork
	A variable should only be globally attached to turfs/objects/whatever, when it is in fact needed as such.
	The current method unnecessarily clusters up the variable list, especially for humans (although rearranging won't really clean it up a lot but the difference will be noticable for other mobs).
	I'll make some notes on where certain variable defines should probably go.
	Changing this around would probably require a good look-over the pre-existing code.
	*/
<<<<<<< HEAD

	/// The zone this mob is currently targeting
=======
>>>>>>> Updated this old code to fork
	var/zone_selected = null

	var/computer_id = null
	var/list/logging = list()
<<<<<<< HEAD

	/// The machine the mob is interacting with (this is very bad old code btw)
	var/obj/machinery/machine = null

	/// Tick time the mob can next move
	var/next_move = null

	/**
	  * Magic var that stops you moving and interacting with anything
	  * 
	  * Set when you're being turned into something else and also used in a bunch of places
	  * it probably shouldn't really be
	  */
	var/notransform = null	//Carbon

	/// Is the mob blind
	var/eye_blind = 0		//Carbon
	/// Does the mob have blurry sight
	var/eye_blurry = 0		//Carbon
	/// What is the mobs real name (name is overridden for disguises etc)
	var/real_name = null

	/// can this mob move freely in space (should be a trait)
	var/spacewalk = FALSE

	/**
	  * back up of the real name during admin possession
	  * 
	  * If an admin possesses an object it's real name is set to the admin name and this
	  * stores whatever the real name was previously. When possession ends, the real name
	  * is reset to this value
	  */
	var/name_archive //For admin things like possession

	/// Default body temperature
	var/bodytemperature = BODYTEMP_NORMAL	//310.15K / 98.6F
	/// Drowsyness level of the mob
	var/drowsyness = 0//Carbon
	/// Dizziness level of the mob
	var/dizziness = 0//Carbon
	/// Jitteryness level of the mob
	var/jitteriness = 0//Carbon
	/// Hunger level of the mob
	var/nutrition = NUTRITION_LEVEL_START_MIN // randomised in Initialize
	/// Satiation level of the mob
	var/satiety = 0//Carbon

	/// How many ticks this mob has been over reating
	var/overeatduration = 0		// How long this guy is overeating //Carbon

	/// The current intent of the mob
	var/a_intent = INTENT_HELP//Living
	/// List of possible intents a mob can have
	var/list/possible_a_intents = null//Living
	/// The movement intent of the mob (run/wal)
	var/m_intent = MOVE_INTENT_RUN//Living

	/// The last known IP of the client who was in this mob
	var/lastKnownIP = null

	/// movable atoms buckled to this mob
	var/atom/movable/buckled = null//Living
	/// movable atom we are buckled to
	var/atom/movable/buckling

	//Hands
	///What hand is the active hand
	var/active_hand_index = 1
	/**
	  * list of items held in hands
	  * 
	  * len = number of hands, eg: 2 nulls is 2 empty hands, 1 item and 1 null is 1 full hand
	  * and 1 empty hand.
	  * 
	  * NB: contains nulls!
	  * 
	  * held_items[active_hand_index] is the actively held item, but please use
	  * get_active_held_item() instead, because OOP
	  */
	var/list/held_items = list()

	//HUD things

	/// Storage component (for mob inventory)
	var/datum/component/storage/active_storage
	/// Active hud
	var/datum/hud/hud_used = null
	/// I have no idea tbh
	var/research_scanner = FALSE

	/// Is the mob throw intent on
	var/in_throw_mode = 0

	/// What job does this mob have
	var/job = null//Living

	/// A list of factions that this mob is currently in, for hostile mob targetting, amongst other things
	var/list/faction = list("neutral")

	/// Can this mob enter shuttles
	var/move_on_shuttle = 1

	///The last mob/living/carbon to push/drag/grab this mob (exclusively used by slimes friend recognition)
	var/mob/living/carbon/LAssailant = null

	/**
	  * construct spells and mime spells.
	  *
	  * Spells that do not transfer from one mob to another and can not be lost in mindswap.
	  * obviously do not live in the mind
	  */
	var/list/mob_spell_list = list()

	
	/// bitflags defining which status effects can be inflicted (replaces canknockdown, canstun, etc)
	var/status_flags = CANSTUN|CANKNOCKDOWN|CANUNCONSCIOUS|CANPUSH

	/// Can they be tracked by the AI?
	var/digitalcamo = 0
	///Are they ivisible to the AI?
	var/digitalinvis = 0
	///what does the AI see instead of them?
	var/image/digitaldisguise = null

	/// Can they interact with station electronics
	var/has_unlimited_silicon_privilege = 0

	///Used by admins to possess objects. All mobs should have this var
	var/obj/control_object

	///Calls relay_move() to whatever this is set to when the mob tries to move
	var/atom/movable/remote_control

	/**
	  * The sound made on death
	  *
	  * leave null for no sound. used for *deathgasp
	  */
	var/deathsound

	///the current turf being examined in the stat panel
	var/turf/listed_turf = null

	///The list of people observing this mob.
	var/list/observers = null

	///List of progress bars this mob is currently seeing for actions
	var/list/progressbars = null	//for stacking do_after bars

	///Allows a datum to intercept all click calls this mob is the source of
	var/datum/click_intercept

	///THe z level this mob is currently registered in
	var/registered_z = null
=======
	var/obj/machinery/machine = null

	var/next_move = null
	var/notransform = null	//Carbon
	var/eye_blind = 0		//Carbon
	var/eye_blurry = 0		//Carbon
	var/real_name = null
	var/spacewalk = FALSE

	var/name_archive //For admin things like possession

	var/bodytemperature = BODYTEMP_NORMAL	//310.15K / 98.6F
	var/drowsyness = 0//Carbon
	var/dizziness = 0//Carbon
	var/jitteriness = 0//Carbon
	var/nutrition = NUTRITION_LEVEL_START_MIN // randomised in Initialize
	var/satiety = 0//Carbon

	var/overeatduration = 0		// How long this guy is overeating //Carbon
	var/a_intent = INTENT_HELP//Living
	var/list/possible_a_intents = null//Living
	var/m_intent = MOVE_INTENT_RUN//Living
	var/lastKnownIP = null
	var/atom/movable/buckled = null//Living
	var/atom/movable/buckling

	//Hands
	var/active_hand_index = 1
	var/list/held_items = list() //len = number of hands, eg: 2 nulls is 2 empty hands, 1 item and 1 null is 1 full hand and 1 empty hand.
	//held_items[active_hand_index] is the actively held item, but please use get_active_held_item() instead, because OOP

	//HUD things
	var/datum/component/storage/active_storage
	var/datum/hud/hud_used = null
	var/research_scanner = FALSE

	var/in_throw_mode = 0

	var/job = null//Living

	var/list/faction = list("neutral") //A list of factions that this mob is currently in, for hostile mob targetting, amongst other things
	var/move_on_shuttle = 1 // Can move on the shuttle.

//The last mob/living/carbon to push/drag/grab this mob (mostly used by slimes friend recognition)
	var/mob/living/carbon/LAssailant = null

	var/list/mob_spell_list = list() //construct spells and mime spells. Spells that do not transfer from one mob to another and can not be lost in mindswap.

	var/status_flags = CANSTUN|CANKNOCKDOWN|CANUNCONSCIOUS|CANPUSH	//bitflags defining which status effects can be inflicted (replaces canknockdown, canstun, etc)

	var/digitalcamo = 0 // Can they be tracked by the AI?
	var/digitalinvis = 0 //Are they ivisible to the AI?
	var/image/digitaldisguise = null  //what does the AI see instead of them?

	var/has_unlimited_silicon_privilege = 0 // Can they interact with station electronics

	var/obj/control_object //Used by admins to possess objects. All mobs should have this var
	var/atom/movable/remote_control //Calls relaymove() to whatever it is

	var/deathsound //leave null for no sound. used for *deathgasp

	var/turf/listed_turf = null	//the current turf being examined in the stat panel

	var/list/observers = null	//The list of people observing this mob.

	var/list/progressbars = null	//for stacking do_after bars

	var/list/mousemove_intercept_objects

	var/datum/click_intercept

	var/registered_z
>>>>>>> Updated this old code to fork
