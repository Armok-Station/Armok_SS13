/mob
	density = 1
	layer = 4
	animate_movement = 2
	flags = HEAR
	hud_possible = list(ANTAG_HUD)
	var/datum/mind/mind

	var/stat = 0 //Whether a mob is alive or dead. TODO: Move this to living - Nodrak

	var/tmp/obj/screen/flash = null
	var/tmp/obj/screen/blind = null
	var/tmp/obj/screen/hands = null
	var/tmp/obj/screen/pullin = null
	var/tmp/obj/screen/internals = null
	var/tmp/obj/screen/i_select = null
	var/tmp/obj/screen/m_select = null
	var/tmp/obj/screen/healths = null
	var/tmp/obj/screen/throw_icon = null
	var/tmp/obj/screen/damageoverlay = null
	/*A bunch of this stuff really needs to go under their own defines instead of being globally attached to mob.
	A variable should only be globally attached to turfs/objects/whatever, when it is in fact needed as such.
	The current method unnecessarily clusters up the variable list, especially for humans (although rearranging won't really clean it up a lot but the difference will be noticable for other mobs).
	I'll make some notes on where certain variable defines should probably go.
	Changing this around would probably require a good look-over the pre-existing code.
	*/
	var/tmp/obj/screen/zone_sel/zone_sel = null
	var/tmp/obj/screen/leap_icon = null
	var/tmp/obj/screen/healthdoll = null

	var/damageoverlaytemp = 0
	var/tmp/computer_id = null
	var/lastattacker = null
	var/lastattacked = null
	var/attack_log = list( )
	var/tmp/obj/machinery/machine = null
	var/other_mobs = null
	var/memory = ""
	var/disabilities = 0	//Carbon
	var/tmp/atom/movable/pulling = null
	var/tmp/next_move = null
	var/notransform = null	//Carbon
	var/hand = null
	var/eye_blind = 0		//Carbon
	var/eye_blurry = 0		//Carbon
	var/ear_deaf = 0		//Carbon
	var/ear_damage = 0		//Carbon
	var/stuttering = null	//Carbon
	var/slurring = 0		//Carbon
	var/real_name = null
	var/bhunger = 0			//Carbon
	var/ajourn = 0
	var/druggy = 0			//Carbon
	var/confused = 0		//Carbon
	var/sleeping = 0		//Carbon
	var/resting = 0			//Carbon
	var/lying = 0
	var/lying_prev = 0
	var/canmove = 1
	var/eye_stat = null//Living, potentially Carbon
	var/lastpuke = 0

	var/name_archive //For admin things like possession

	var/timeofdeath = 0//Living
	var/cpr_time = 1//Carbon


	var/bodytemperature = 310.055	//98.7 F
	var/drowsyness = 0//Carbon
	var/dizziness = 0//Carbon
	var/jitteriness = 0//Carbon
	var/tmp/nutrition = NUTRITION_LEVEL_FED + 50//Carbon
	var/satiety = 0//Carbon

	var/overeatduration = 0		// How long this guy is overeating //Carbon
	var/paralysis = 0
	var/stunned = 0
	var/weakened = 0
	var/losebreath = 0//Carbon
	var/shakecamera = 0
	var/a_intent = "help"//Living
	var/m_intent = "run"//Living
	var/tmp/lastKnownIP = null
	var/obj/structure/stool/bed/buckled = null//Living
	var/obj/item/l_hand = null//Living
	var/obj/item/r_hand = null//Living
	var/tmp/obj/item/weapon/storage/s_active = null//Carbon

	var/seer = 0 //for cult//Carbon, probably Human
	var/see_override = 0 //0 for no override, sets see_invisible = see_override in mob life process

	var/tmp/datum/hud/hud_used = null

	var/tmp/list/grabbed_by = list(  )
	var/tmp/list/requests = list(  )

	var/tmp/list/mapobjs = list()

	var/in_throw_mode = 0

	var/coughedtime = null

	var/music_lastplayed = "null"

	var/job = null//Living

	var/radiation = 0//Carbon

	var/list/mutations = list() //Carbon -- Doohl
	//see: setup.dm for list of mutations

	var/voice_name = "unidentifiable voice"

	var/list/faction = list("neutral") //A list of factions that this mob is currently in, for hostile mob targetting, amongst other things
	var/move_on_shuttle = 1 // Can move on the shuttle.

//The last mob/living/carbon to push/drag/grab this mob (mostly used by slimes friend recognition)
	var/tmp/mob/living/carbon/LAssailant = null


	var/list/mob_spell_list = list() //construct spells and mime spells. Spells that do not transfer from one mob to another and can not be lost in mindswap.

//Changlings, but can be used in other modes
//	var/obj/effect/proc_holder/changpower/list/power_list = list()

//List of active diseases

	var/list/viruses = list() // replaces var/datum/disease/virus

//Monkey/infected mode
	var/list/resistances = list()
	var/datum/disease/virus = null

	mouse_drag_pointer = MOUSE_ACTIVE_POINTER


	var/status_flags = CANSTUN|CANWEAKEN|CANPARALYSE|CANPUSH	//bitflags defining which status effects can be inflicted (replaces canweaken, canstun, etc)

	var/tmp/area/lastarea = null

	var/digitalcamo = 0 // Can they be tracked by the AI?
	var/weakeyes = 0 //Are they vulnerable to flashes?

	var/has_unlimited_silicon_privilege = 0 // Can they interact with station electronics

	var/force_compose = 0 //If this is nonzero, the mob will always compose it's own hear message instead of using the one given in the arguments.

	var/tmp/obj/control_object //Used by admins to possess objects. All mobs should have this var
	var/atom/movable/remote_control //Calls relaymove() to whatever it is

	var/tmp/turf/listed_turf = null	//the current turf being examined in the stat panel

	var/list/permanent_huds = list()
	var/permanent_sight_flags = 0