/datum/proc/ntnet_receive(datum/netdata/data)
	return


/datum/proc/ntnet_send(datum/netdata/data)
	var/datum/component/ntnet_interface/NIC = GetComponent(/datum/component/ntnet_interface)
	if(!NIC)
		return FALSE
	data.sender_id = NIC.hardware_id
	return NIC.network.process_data_transmit(data)

/datum/proc/ntnet_join_network(network_name, network_tag=null)
	if(!SSnetworks.verify_network_name(network_name))
		return FALSE
	return AddComponent(/datum/component/ntnet_interface, network_name, network_tag)


/datum/component/ntnet_interface
	var/hardware_id						//text. this is the true ID. do not change this. stuff like ID forgery can be done manually.
	var/id_tag = null  			// named tag for looking up on mapping objects
	var/datum/ntnet/network = null		// network we are on, we MUST be on a network or there is no point in this component
	var/list/registered_sockets 		// list of connections

/datum/component/ntnet_interface/Initialize(network_name, network_tag=null)
	if(!network_name)
		log_runtime("Bad network name [network_name], going to limbo it")
		network_name = NETWORK_LIMBO

	src.hardware_id = "[SSnetworks.get_next_HID()]"
	src.id_tag = network_tag
	SSnetworks.interfaces_by_hardware_id[src.hardware_id] = src
	src.registered_sockets = list()

	if(isatom(parent))
		var/atom/A = parent
		A.hardware_id = src.hardware_id
	join_network(network_name)
// Port connection system
// The basic idea is that two or more objects share a list and transfer data between the list
// The list keeps a flag called "_updated", if that flag is set to "true" then something was
// changed.  Now I COULD send a signal, but that would require the parent object to be shoved
// in datum/netlink.  I am trying my best to not have hard references in any of these data
// objects

/datum/component/ntnet_interface/proc/connect_port(hid_or_tag, port, mob/user=null)
	ASSERT(hid_or_tag && port)
	var/datum/component/ntnet_interface/target = network.root_devices[hid_or_tag]
	if(target && target.registered_sockets[port])
		var/list/datalink = target.registered_sockets[port]
		return datalink
	if(user)
		to_chat(user,"Port [port] does not exist on [hid_or_tag]!")


/datum/component/ntnet_interface/proc/deregister_port(port)
	if(registered_sockets[port]) // should I runtime if this isn't in here?
		var/list/datalink = registered_sockets[port]
		NETWORK_PORT_DISCONNECT(datalink)
		// this should remove all outstanding ports
		registered_sockets.Remove(port)


/datum/component/ntnet_interface/proc/register_port(port, list/data)
	if(!port || !length(data))
		log_runtime("port is null or data is empty")
		return
	if(registered_sockets[port])
		log_runtime("port already regestered")
		return
	data["_updated"] = FALSE
	registered_sockets[port] = data

/datum/component/ntnet_interface/Destroy()
	if(network)
		leave_network()
	if(isatom(parent))
		var/atom/A = parent
		A.hardware_id = null
	SSnetworks.interfaces_by_hardware_id.Remove(hardware_id)
	for(var/port in registered_sockets)
		deregister_port(port)
	registered_sockets = null
	return ..()

/datum/component/ntnet_interface/proc/join_network(network_name)
	if(network)
		leave_network()
	var/datum/ntnet/net = SSnetworks.create_network_simple(network_name)
	ASSERT(net)
	net.interface_connect(src)
	ASSERT(network)
	if(network)
		var/atom/A = parent
		if(A)
			A.network_id = 	network.network_id
		// So why here?  Before this there were hacks (radio, ref sharing, etc) on how other objects "connected" with another
		// (embedded_controller, assembly's, etc).  They all had their own interfaces and snowflake connections.  By giving
		// everything a hardware_id and a network_id, now you can find and connect devices.  However, the problem is when maps
		// are loading, as of 9/25/2020, atmosinit() and a few other procs run BEFORE even Initialize()  (see. the state hack
		// hell that is the atoms init process)
		// Because maps are loaded though an async process AND Initialize/LateInitialize is only run per template and not when ALL maps are loaded there is no
		// no way for an atom to know if a device exists at map time.  Could try to change LateInitialize to run at the end of the map process but since it
		// doesn't pass mapload and itself is async, thats problematic.
		// You might say this shouldn't matter as of right now, each map should be isolated.  But if we ever start making
		// stations that contain multiple map templates or, for example, headset relays are converted to this system, something
		// needs to run after all the machines are down, all the maps are loaded, but no players exist yet.
		// So yea.  This is why we have to delay load
		if(!SSmapping.initialized)
			SEND_SIGNAL(parent, COMSIG_COMPONENT_NTNET_JOIN_NETWORK, network)
		else
			SSnetworks.network_initialize_queue += src

/datum/component/ntnet_interface/proc/leave_network()
	if(network)
		network.interface_disconnect(src)
	if(isatom(parent))
		var/atom/A = parent
		A.network_id = 	null

