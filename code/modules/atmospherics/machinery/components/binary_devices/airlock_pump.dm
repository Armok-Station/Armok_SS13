/// A vent, scrubber and a sensor in a single device meant specifically for cycling airlocks
/obj/machinery/atmospherics/components/unary/airlock_pump
	name = "airlock pump"
	desc = "A pump for cycling airlock that vents, siphons the air and controls the connected airlocks. Can be configured with a multitool."
	icon = 'icons/obj/machines/atmospherics/unary_devices.dmi'
	icon_state = "airlock_pump"
	pipe_state = "airlock_pump"
	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION * 0.15
	can_unwrench = TRUE
	welded = FALSE
	vent_movement = VENTCRAWL_ALLOWED | VENTCRAWL_CAN_SEE | VENTCRAWL_ENTRANCE_ALLOWED
	max_integrity = 100
	paintable = FALSE
	pipe_flags = PIPING_ONE_PER_TURF
	layer = GAS_PUMP_LAYER
	hide = TRUE
	device_type = BINARY

	///Indicates that the direction of the pump, if ATMOS_DIRECTION_SIPHONING is siphoning, if ATMOS_DIRECTION_RELEASING is releasing
	var/pump_direction = ATMOS_DIRECTION_RELEASING
	///Set the maximum allowed external pressure
	var/external_pressure_bound = ONE_ATMOSPHERE
	///Set the maximum pressure at the input port
	var/input_pressure_min = 0
	///Set the maximum pressure at the output port
	var/output_pressure_max = 0
	///Set the flag for the pressure bound
	var/pressure_checks = ATMOS_EXTERNAL_BOUND

/obj/machinery/atmospherics/components/unary/airlock_pump/update_icon_nopipes()
	cut_overlays()

	if(showpipe)
		var/image/cap_distro = get_pipe_image(icon, "vent_cap", dir, COLOR_BLUE, piping_layer = 4)
		var/image/cap_waste = get_pipe_image(icon, "vent_cap", dir, COLOR_RED, piping_layer = 2)
		add_overlay(cap_distro)
		add_overlay(cap_waste)

	if(!on || !is_operational)
		icon_state = "vent_off"
	else
		icon_state = pump_direction ? "vent_out" : "vent_in"

/obj/machinery/atmospherics/components/unary/airlock_pump/update_icon_underlays(var/tmp/list/underlays)
	if(nodes[1])
		underlays += mutable_appearance('icons/obj/pipes_n_cables/pipe_underlays.dmi', "intact_[dir]_[4]")
	if(nodes[2])
		underlays += mutable_appearance('icons/obj/pipes_n_cables/pipe_underlays.dmi', "intact_[dir]_[2]")
	return underlays

/obj/machinery/atmospherics/components/unary/airlock_pump/atmos_init()
	nodes = list()
	var/obj/machinery/atmospherics/node_distro = find_connecting(dir, 4)
	var/obj/machinery/atmospherics/node_waste = find_connecting(dir, 2)
	if(node_distro && !QDELETED(node_distro))
		nodes += node_distro
	if(node_waste && !QDELETED(node_waste))
		nodes += node_waste
	update_appearance()

/obj/machinery/atmospherics/components/unary/airlock_pump/connect_pipes()
	atmos_init()
	var/obj/machinery/atmospherics/node_distro = nodes[1]
	if(node_distro)
		node_distro.atmos_init()
		node_distro.add_member(src)
	var/obj/machinery/atmospherics/node_waste = nodes[2]
	if(node_waste)
		node_waste.atmos_init()
		node_waste.add_member(src)
	SSair.add_to_rebuild_queue(src)

/obj/machinery/atmospherics/components/unary/airlock_pump/disconnect_pipes()
	var/obj/machinery/atmospherics/node_distro = nodes[1]
	if(node_distro)
		if(src in node_distro.nodes) //Only if it's actually connected. On-pipe version would is one-sided.
			node_distro.disconnect(src)
		nodes[1] = null
	if(parents[1])
		nullify_pipenet(parents[1])
	var/obj/machinery/atmospherics/node_waste = nodes[2]
	if(node_waste)
		if(src in node_waste.nodes) //Only if it's actually connected. On-pipe version would is one-sided.
			node_waste.disconnect(src)
		nodes[2] = null
	if(parents[2])
		nullify_pipenet(parents[2])
