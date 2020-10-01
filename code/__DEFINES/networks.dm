#define HID_RESTRICTED_END 101		//the first nonrestricted ID, automatically assigned on connection creation.

#define NETWORK_ERROR_DISCONNECTED "exception_disconnected"
#define NETWORK_BROADCAST_ID "ALL"

/// Any device under limbo can only be found in LIMBO with knowing its hardware id
/// Limbo cannot be broadcasted or searched in.  Used for things like assembly or
/// point to point buttons.

#define NETWORK_LIMBO			"LIMBO"

#define STATION_NETWORK_ROOT 	"SS13_NTNET"
#define SYNDICATE_NETWORK_ROOT 	"SYNDI_NTNET"

#define NETWORK_TOOLS			"TOOLS"
#define NETWORK_TOOLS_REMOTES	"TOOLS.REMOTES"

#define NETWORK_AIRLOCKS 		"AIRLOCKS"

#define NETWORK_STATION_ATMOS 			"SS13.ATMOS"
#define NETWORK_STATION_ATMOS_AIRALARMS "SS13.ATMOS.AIRALARMS"	// all air alarms
#define NETWORK_STATION_ATMOS_SCUBBERS	"SS13.ATMOS.SCURBBERS"	// includes vents
#define NETWORK_STATION_ATMOS_ALARMS	"SS13.ATMOS.ALARMS"		// Console and station wide
#define NETWORK_STATION_ATMOS_CONTROL 	"SS13.ATMOS.CONTROL"
#define NETWORK_STATION_ATMOS_STORAGE 	"SS13.ATMOS.STORAGE"
#define NETWORK_CHARLIE_ATMOS 	"CHARLIE.ATMOS"
#define DEEP_STORAGE_ATMOS		"DEEP.ATMOS"

#define NETWORK_PORT_DISCONNECTED(LIST) (!LIST || LIST["_disconnected"])
#define NETWORK_PORT_UPDATED(LIST) (LIST && !LIST["_disconnected"] && LIST["_updated"])
#define NETWORK_PORT_UPDATE(LIST) if(LIST) { LIST["_updated"] = TRUE }
#define NETWORK_PORT_CLEAR_UPDATE(LIST) if(LIST) { LIST["_updated"] = FALSE }
#define NETWORK_PORT_SET_UPDATE(LIST) if(LIST) { LIST["_updated"] = TRUE }
#define NETWORK_PORT_DISCONNECT(LIST)  if(LIST) { LIST["_disconnected"] = TRUE }

