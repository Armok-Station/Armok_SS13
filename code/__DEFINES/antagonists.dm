#define NUKE_RESULT_FLUKE 0
#define NUKE_RESULT_NUKE_WIN 1
#define NUKE_RESULT_CREW_WIN 2
#define NUKE_RESULT_CREW_WIN_SYNDIES_DEAD 3
#define NUKE_RESULT_DISK_LOST 4
#define NUKE_RESULT_DISK_STOLEN 5
#define NUKE_RESULT_NOSURVIVORS 6
#define NUKE_RESULT_WRONG_STATION 7
#define NUKE_RESULT_WRONG_STATION_DEAD 8

//fugitive end results
#define FUGITIVE_RESULT_BADASS_HUNTER 0
#define FUGITIVE_RESULT_POSTMORTEM_HUNTER 1
#define FUGITIVE_RESULT_MAJOR_HUNTER 2
#define FUGITIVE_RESULT_HUNTER_VICTORY 3
#define FUGITIVE_RESULT_MINOR_HUNTER 4
#define FUGITIVE_RESULT_STALEMATE 5
#define FUGITIVE_RESULT_MINOR_FUGITIVE 6
#define FUGITIVE_RESULT_FUGITIVE_VICTORY 7
#define FUGITIVE_RESULT_MAJOR_FUGITIVE 8

#define APPRENTICE_DESTRUCTION "destruction"
#define APPRENTICE_BLUESPACE "bluespace"
#define APPRENTICE_ROBELESS "robeless"
#define APPRENTICE_HEALING "healing"

//ERT Types
#define ERT_BLUE "Blue"
#define ERT_RED  "Red"
#define ERT_AMBER "Amber"
#define ERT_DEATHSQUAD "Deathsquad"

//ERT subroles
#define ERT_SEC "sec"
#define ERT_MED "med"
#define ERT_ENG "eng"
#define ERT_LEADER "leader"
#define DEATHSQUAD "ds"
#define DEATHSQUAD_LEADER "ds_leader"

//Shuttle elimination hijacking
/// Does not stop elimination hijacking but itself won't elimination hijack
#define ELIMINATION_NEUTRAL 0
/// Needs to be present for shuttle to be elimination hijacked
#define ELIMINATION_ENABLED 1
/// Prevents elimination hijack same way as non-antags
#define ELIMINATION_PREVENT 2

//Syndicate Contracts
#define CONTRACT_STATUS_INACTIVE 1
#define CONTRACT_STATUS_ACTIVE 2
#define CONTRACT_STATUS_BOUNTY_CONSOLE_ACTIVE 3
#define CONTRACT_STATUS_EXTRACTING 4
#define CONTRACT_STATUS_COMPLETE 5
#define CONTRACT_STATUS_ABORTED 6

#define CONTRACT_PAYOUT_LARGE 1
#define CONTRACT_PAYOUT_MEDIUM 2
#define CONTRACT_PAYOUT_SMALL 3

#define CONTRACT_UPLINK_PAGE_CONTRACTS "CONTRACTS"
#define CONTRACT_UPLINK_PAGE_HUB "HUB"

GLOBAL_LIST_INIT(heretic_start_knowledge,list(/datum/eldritch_knowledge/spell/basic,/datum/eldritch_knowledge/living_heart,/datum/eldritch_knowledge/codex_cicatrix))


#define PATH_SIDE "Side"

#define PATH_ASH "Ash"
#define PATH_RUST "Rust"
#define PATH_FLESH "Flesh"
#define PATH_VOID "Void"

/// tgui parameter on purchasing with red currency
#define RED_TELECRYSTALS "red"
/// tgui parameter on purchasing with black currency
#define BLACK_TELECRYSTALS "black"

/// How many red telecrystals a normal traitor starts with
#define RED_TELECRYSTALS_DEFAULT 20
/// How many black telecrystals a normal traitor starts with
#define BLACK_TELECRYSTALS_DEFAULT 0

/// How many telecrystals mapper/admin only "precharged" uplink implant
#define RED_TELECRYSTALS_PRELOADED_IMPLANT 10
/// The normal cost of an uplink implant; used for calcuating how many
/// TC to charge someone if they get a free implant through choice or
/// because they have nothing else that supports an implant.
#define UPLINK_IMPLANT_RED_TELECRYSTAL_COST 4

/// The Classic Wizard wizard loadout.
#define WIZARD_LOADOUT_CLASSIC "loadout_classic"
/// Mjolnir's Power wizard loadout.
#define WIZARD_LOADOUT_MJOLNIR "loadout_hammer"
/// Fantastical Army wizard loadout.
#define WIZARD_LOADOUT_WIZARMY "loadout_army"
/// Soul Tapper wizard loadout.
#define WIZARD_LOADOUT_SOULTAP "loadout_tap"
/// Convenient list of all wizard loadouts for unit testing.
#define ALL_WIZARD_LOADOUTS list( \
	WIZARD_LOADOUT_CLASSIC, \
	WIZARD_LOADOUT_MJOLNIR, \
	WIZARD_LOADOUT_WIZARMY, \
	WIZARD_LOADOUT_SOULTAP, \
)

/// Chance that the traitor could roll hijack if the pop limit is met.
#define HIJACK_PROB 10
/// Hijack is unavailable as a random objective below this player count.
#define HIJACK_MIN_PLAYERS 30

/// Chance the traitor gets a martyr objective instead of having to escape alive, as long as all the objectives are martyr compatible.
#define MARTYR_PROB 20

/// Chance the traitor gets a kill objective. If this prob fails, they will get a steal objective instead.
#define KILL_PROB 50
/// If a kill objective is rolled, chance that it is to destroy the AI.
#define DESTROY_AI_PROB(denominator) (100 / denominator)
/// If the destroy AI objective doesn't roll, chance that we'll get a maroon instead. If this prob fails, they will get a generic assassinate objective instead.
#define MAROON_PROB 30
/// If it's a steal objective, this is the chance that it'll be a download research notes objective. Science staff can't get this objective. It can only roll once. If any of these fail, they will get a generic steal objective instead.
#define DOWNLOAD_PROB 15

///File to the traitor flavor
#define TRAITOR_FLAVOR_FILE "traitor_flavor.json"

///employers that are from the syndicate
GLOBAL_LIST_INIT(syndicate_employers, list(
	"Tiger Cooperative Fanatic",
	"Waffle Corporation Terrorist",
	"Animal Rights Consortium",
	"Bee Liberation Front",
	"Cybersun Industries",
	"MI13",
	"Gorlex Marauders",
	"Donk Corporation",
	"Waffle Corporation",
))
///employers that are from nanotrasen
GLOBAL_LIST_INIT(nanotrasen_employers, list(
	"Gone Postal",
	"Internal Affairs Agent",
	"Corporate Climber",
	"Legal Trouble"
))

///employers who hire agents to do the hijack
GLOBAL_LIST_INIT(hijack_employers, list(
	"Tiger Cooperative Fanatic",
	"Waffle Corporation Terrorist",
	"Animal Rights Consortium",
	"Bee Liberation Front",
	"Gone Postal"
))

///employers who hire agents to do a task and escape... or martyrdom. whatever
GLOBAL_LIST_INIT(normal_employers, list(
	"Cybersun Industries",
	"MI13",
	"Gorlex Marauders",
	"Donk Corporation",
	"Waffle Corporation",
	"Internal Affairs Agent",
	"Corporate Climber",
	"Legal Trouble"
))

///codebase limit of the total cost of the red market (items purchasable with red tc)
#define RED_TELECRYSTAL_LIMIT 80

///all the employers that are syndicate
#define FACTION_SYNDICATE "syndicate"
///all the employers that are nanotrasen
#define FACTION_NANOTRASEN "nanotrasen"

#define UPLINK_THEME_SYNDICATE "syndicate"

#define UPLINK_THEME_UNDERWORLD_MARKET "neutral"

/// Checks if the given mob is a blood cultist
#define IS_CULTIST(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/cult))

/// Checks if the given mind is a leader of the monkey antagonists
#define IS_MONKEY_LEADER(mind) mind?.has_antag_datum(/datum/antagonist/monkey/leader)

/// Checks if the given mind is a monkey antagonist
#define IS_INFECTED_MONKEY(mind) mind?.has_antag_datum(/datum/antagonist/monkey)

/// Checks if the given mob is a nuclear operative
#define IS_NUKE_OP(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/nukeop))

#define IS_HERETIC(mob) (mob.mind?.has_antag_datum(/datum/antagonist/heretic))

#define IS_HERETIC_MONSTER(mob) (mob.mind?.has_antag_datum(/datum/antagonist/heretic_monster))

/// Checks if the given mob is a wizard
#define IS_WIZARD(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/wizard))

/// Checks if the given mob is a revolutionary. Will return TRUE for rev heads as well.
#define IS_REVOLUTIONARY(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/rev))

/// Checks if the given mob is a head revolutionary.
#define IS_HEAD_REVOLUTIONARY(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/rev/head))
