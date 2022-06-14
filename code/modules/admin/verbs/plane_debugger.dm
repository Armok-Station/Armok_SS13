/// Used for testing/debugger plane masters and their associated rendering plates
/datum/plane_master_debug
	var/datum/admins/owner
	/// Assoc list of plane master group key -> its depth stack
	var/list/depth_stack = list()
	/// The current plane master group we're viewing
	var/current_group = PLANE_GROUP_MAIN

/datum/plane_master_debug/New(datum/admins/owner)
	src.owner = owner

/datum/plane_master_debug/Destroy()
	owner = null
	return ..()

/datum/plane_master_debug/ui_state(mob/user)
	return GLOB.admin_state

/datum/plane_master_debug/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlaneMasterDebug")
		ui.open()

/datum/plane_master_debug/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/plane_background))

/datum/plane_master_debug/ui_data()
	var/list/data = list()

	var/datum/hud/our_hud = owner.owner.mob.hud_used
	var/list/our_groups = our_hud.master_groups
	if(!our_groups[current_group])
		// We assume we'll always have at least one group
		current_group = our_groups[length(our_hud.master_groups)]

	var/list/groups = list()
	for(var/key in our_groups)
		groups += key

	// Ok so like
	// Right now, there are no groups except MAIN that actually uh, use relays
	// You know, the thing this viewer is for
	// It's becuase relays on submaps are hyper yorked https://www.byond.com/forum/post/2797107
	// So um, we disable this feature for now. If lummy ever fixes it and we start using relay'd groups, enable this
	// Thanks, I love you, xoxo ~~Lemon
	data["enable_group_view"] = FALSE
	data["our_group"] = current_group
	data["present_groups"] = groups

	var/list/plane_info = list()
	data["plane_info"] = plane_info
	var/list/relay_deets = list()
	data["relay_info"] = relay_deets
	var/list/filter_connections = list()
	data["filter_connect"] = filter_connections

	var/list/filter_queue = list()

	// Assoc of render targets -> planes
	// Gotta be able to look these up so filter stuff can work
	var/list/render_target_to_plane = list()
	// Assoc list of pending planes -> relays
	// Used to ensure the incoming_relays list is filled, even if the relay's generated before the plane's processed
	var/list/pending_relays = list()

	var/list/our_planes = our_hud?.get_planes_from(current_group)
	for(var/plane_string as anything in our_planes)
		var/list/this_plane = list()
		var/atom/movable/screen/plane_master/plane = our_planes[plane_string]
		var/string_plane = "[plane.plane]"
		this_plane["name"] = plane.name
		this_plane["documentation"] = plane.documentation
		this_plane["plane"] = plane.plane
		this_plane["our_ref"] = string_plane
		this_plane["offset"] = plane.offset
		this_plane["real_plane"] = plane.real_plane
		this_plane["renders_onto"] = plane.render_relay_planes
		this_plane["blend_mode"] = GLOB.blend_names["[plane.blend_mode_override || initial(plane.blend_mode)]"]
		this_plane["color"] = plane.color
		this_plane["alpha"] = plane.alpha
		this_plane["render_target"] = plane.render_target


		var/list/incoming_relays = list()
		this_plane["incoming_relays"] = incoming_relays

		for(var/pending_relay in pending_relays[string_plane])
			incoming_relays += pending_relay
			var/list/this_relay = relay_deets[pending_relay]
			this_relay["target_index"] = length(incoming_relays)


		this_plane["outgoing_relays"] = list()

		// You can think of relays as connections between plane master "nodes
		// They do have some info of their own tho, best to pass that along
		for(var/atom/movable/render_plane_relay/relay in plane.relays)
			var/string_target = "[relay.plane]"
			var/list/this_relay = list()
			this_relay["name"] = relay.name
			this_relay["source"] = plane.plane
			this_relay["source_ref"] = string_plane
			this_relay["target"] = relay.plane
			this_relay["target_ref"] = string_target
			this_relay["layer"] = relay.layer

			// Now taht we've encoded our relay, we need to hand out references to it to our source plane, alongside the target plane
			var/relay_ref = "[string_plane]-[string_target]"
			this_relay["our_ref"] = relay_ref
			relay_deets[relay_ref] = this_relay
			this_plane["outgoing_relays"] += relay_ref

			// If we've already encoded our target plane, update its incoming relays list
			// Otherwise, we'll handle this later
			var/list/existing_target = plane_info[string_target]
			if(existing_target)
				existing_target["incoming_relays"] += relay_ref
			else
				var/list/pending_plane = pending_relays[string_target]
				if(!pending_plane)
					pending_plane = list()
					pending_relays[string_target] = pending_plane
				pending_plane += relay_ref

		this_plane["incoming_filters"] = list()
		this_plane["outgoing_filters"] = list()
		// We're gonna collect a list of filters, partly because they're useful info
		// But also because they can be used as connections, and we need to support that
		for(var/filter_id in plane.filter_data)
			var/list/filter = plane.filter_data[filter_id]
			if(!filter["render_source"])
				continue
			var/list/filter_info = filter.Copy()
			filter_info["target_ref"] = string_plane
			filter_info["name"] = filter_id
			filter_queue += list(filter_info)

		plane_info[plane_string] = this_plane
		render_target_to_plane[plane.render_target] = this_plane

	for(var/list/filter in filter_queue)
		var/source = filter["render_source"]
		var/list/source_plane = render_target_to_plane[source]
		var/list/target_plane = plane_info[filter["target_ref"]]
		var/source_ref = source_plane["our_ref"]
		filter["source_ref"] = source_ref
		var/our_ref = "[source_ref]-[filter["target_ref"]]-filter"
		filter["our_ref"] = our_ref
		filter_connections[our_ref] = filter
		source_plane["outgoing_filters"] += our_ref
		target_plane["incoming_filters"] += our_ref

	// Only load this once. Prevents leaving off orphaned components
	if(!depth_stack[current_group])
		depth_stack[current_group] = treeify(plane_info, relay_deets, filter_connections)

	// We will use this js side to arrange our plane masters and such
	// It's essentially a stack of where they should be displayed
	data["depth_stack"] = depth_stack[current_group]
	return data

// Reading this in the queue tells the search to increase the depth, and then push another increase command to the end of the stack
// This way we ensure groupings always stay together, and depth is respected
#define COMMAND_DEPTH_INCREASE "increase_depth"
#define COMMAND_NEXT_PARENT "next_parent"

/// Takes a list of js formatted planes, and turns it into a tree based off the back connections of relays
/// So start at the top master plane, and work down
/// Haha jerry what if I added commands to my list parser lmao lol
/datum/plane_master_debug/proc/treeify(list/plane_info, list/relay_info, list/filter_connections)
	// List in the form [depth in num] -> list(list(plane_ref -> parent_ref, ...), ...)
	var/list/treelike_output = list()
	// List in the form plane ref -> current depth
	var/list/plane_to_depth = list()
	// List of items/commands to process. FIFO queue, to ensure the brackets are built correctly
	var/list/processing_queue = list()
	// A FIFO queue of parents. Used so planes can have refs to their direct parent, to make sorting easier
	var/list/parents = list("")
	var/parent_head = 1
	// The current depth of our search, used with treelike_output
	var/depth = 0
	// Push a depth increase onto the queue, to properly setup the sorta looping effect it has
	processing_queue += COMMAND_DEPTH_INCREASE
	processing_queue += "[RENDER_PLANE_MASTER]"
	// We need to do a c style loop here because we are expanding the queue, and so need to update our conditional
	for(var/i = 1; i <= length(processing_queue); i++)
		var/entry = processing_queue[i]
		// We've reached the end of a depth block
		// Increment the depth and stick another command on the end of the queue
		if(entry == COMMAND_DEPTH_INCREASE)
			// Don't wanna infinite loop now
			if(i == length(processing_queue))
				continue
			// Increment our depth
			depth += 1
			treelike_output += list(list())
			// If this isn't the end, stick another entry on the end to ensure batches work proper
			processing_queue += COMMAND_DEPTH_INCREASE
			continue
		if(entry == COMMAND_NEXT_PARENT)
			parent_head += 1
			continue

		var/old_queue_len = length(processing_queue)
		var/existing_depth = plane_to_depth[entry]
		// If we've seen you before, remove your last entry
		// We always want inputs before outputs in the stack
		if(existing_depth)
			treelike_output[existing_depth] -= entry

		// If it's not a command, it must be a plane string
		var/list/plane = plane_info[entry]
		// Add all the planes that pipe into us to the queue, Intentionally allows dupes
		// If we find the same entry twice, it'll get moved down the depth stack
		for(var/relay_string in plane["incoming_relays"])
			var/list/relay = relay_info[relay_string]
			processing_queue += relay["source_ref"]
		for(var/filter_ref in plane["incoming_filters"])
			var/list/filter = filter_connections[filter_ref]
			processing_queue += filter["source_ref"]

		// If the queue has grown, we're a parent, so stick us in the parent queue
		if(old_queue_len != length(processing_queue))
			parents += entry
			// Stick a parent increase right before our children show up in the queue. That way we're properly set as their parent
			processing_queue.Insert(old_queue_len + 1, COMMAND_NEXT_PARENT)
		// Stick us in the output at our designated depth
		var/list/plane_packet = list()
		plane_packet[entry] = parents[parent_head]
		treelike_output[depth] += plane_packet
		plane_to_depth[entry] = depth

	return treelike_output

#undef COMMAND_DEPTH_INCREASE
#undef COMMAND_NEXT_PARENT

/datum/plane_master_debug/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/datum/hud/our_hud = owner?.owner?.mob?.hud_used
	var/datum/plane_master_group/group = our_hud?.master_groups[current_group]
	if(!group) // Nothing to act on
		return
	var/list/our_planes = group.plane_masters

	switch(action)
		if("refresh")
			group.rebuild_hud()
		if("set_group")
			current_group = params["target_group"]
		if("connect_relay")
			var/source_plane = params["source"]
			var/target_plane = params["target"]
			var/atom/movable/screen/plane_master/source = our_planes["[source_plane]"]
			if(source.get_relay_to(target_plane)) // Fuck off
				return
			source.add_relay_to(target_plane)
			return TRUE
		if("disconnect_relay")
			var/source_plane = params["source"]
			var/target_plane = params["target"]
			var/atom/movable/screen/plane_master/source = our_planes["[source_plane]"]
			source.remove_relay_from(text2num(target_plane))
			return TRUE
		if("disconnect_filter")
			var/target_plane = params["target"]
			var/atom/movable/screen/plane_master/filtered_plane = our_planes["[target_plane]"]
			filtered_plane.remove_filter(params["name"])
			return TRUE
		if("vv_plane")
			var/plane_edit = params["edit"]
			var/atom/movable/screen/plane_master/edit = our_planes["[plane_edit]"]
			var/mob/user = ui.user
			user?.client?.debug_variables(edit)
			return TRUE
		if("set_alpha")
			var/plane_edit = params["edit"]
			var/atom/movable/screen/plane_master/edit = our_planes["[plane_edit]"]
			var/newalpha = params["alpha"]
			animate(edit, 0.4 SECONDS, alpha = newalpha)
			return TRUE
		if("edit_color_matrix")
			var/plane_edit = params["edit"]
			var/atom/movable/screen/plane_master/edit = our_planes["[plane_edit]"]
			var/mob/user = ui.user
			user?.client?.open_color_matrix_editor(edit)
			return TRUE
		if("edit_filters")
			var/plane_edit = params["edit"]
			var/atom/movable/screen/plane_master/edit = our_planes["[plane_edit]"]
			var/mob/user = ui.user
			user?.client?.open_filter_editor(edit)
			return TRUE

