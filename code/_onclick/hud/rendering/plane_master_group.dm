/// Datum that represents one "group" of plane masters
/// So all the main window planes would be in one, all the spyglass planes in another
/// Etc
/datum/plane_master_group
	/// Our key in the group list on /datum/hud
	/// Should be unique for any group of plane masters in the world
	var/key
	/// Our parent hud
	var/datum/hud/our_hud
	/// List in the form "[plane]" = object, the plane masters we own
	var/list/atom/movable/screen/plane_master/plane_masters = list()

	/// What, if any, submap we render onto
	var/map = ""

/datum/plane_master_group/New(key, map = "")
	. = ..()
	src.key = key
	src.map = map
	build_plane_masters(0, SSmapping.max_plane_offset)

/datum/plane_master_group/Destroy()
	orphan_hud()
	QDEL_LIST_ASSOC_VAL(plane_masters)
	return ..()

/// Display a plane master group to some viewer, so show all our planes to it
/datum/plane_master_group/proc/attach_to(datum/hud/viewing_hud)
	if(viewing_hud.master_groups[key])
		stack_trace("Hey brother, our key [key] is already in use by a plane master group on the passed in hud, belonging to [viewing_hud.mymob]. Ya fucked up, why are there dupes")
		return

	our_hud = viewing_hud
	our_hud.master_groups[key] = src
	show_hud()

/// Hide the plane master from its current hud, fully clear it out
/datum/plane_master_group/proc/orphan_hud()
	if(our_hud)
		our_hud.master_groups -= key
		hide_hud()
		our_hud = null

/// Well, refresh our group, mostly useful for plane specific updates
/datum/plane_master_group/proc/refresh_hud()
	hide_hud()
	show_hud()

/// Fully regenerate our group, resetting our planes to their compile time values
/datum/plane_master_group/proc/rebuild_hud()
	QDEL_LIST_ASSOC_VAL(plane_masters)
	build_plane_masters(0, SSmapping.max_plane_offset)
	show_hud()

/datum/plane_master_group/proc/hide_hud()
	for(var/thing in plane_masters)
		var/atom/movable/screen/plane_master/plane = plane_masters[thing]
		plane.hide_from(our_hud.mymob)

/datum/plane_master_group/proc/show_hud()
	for(var/thing in plane_masters)
		var/atom/movable/screen/plane_master/plane = plane_masters[thing]
		show_plane(plane)

/// This is mostly a proc so it can be overriden by popups, since they have unique behavior they want to do
/datum/plane_master_group/proc/show_plane(atom/movable/screen/plane_master/plane)
	plane.show_to(our_hud.mymob)
	our_hud.mymob.client.screen += plane

/// Returns a list of all the plane master types we want to create
/datum/plane_master_group/proc/get_plane_types()
	return subtypesof(/atom/movable/screen/plane_master) - /atom/movable/screen/plane_master/rendering_plate

/// Actually generate our plane masters, in some offset range (where offset is the z layers to render to, because each "layer" in a multiz stack gets its own plane master cube)
/datum/plane_master_group/proc/build_plane_masters(starting_offset, ending_offset)
	for(var/atom/movable/screen/plane_master/mytype as anything in get_plane_types())
		for(var/plane_offset in starting_offset to ending_offset)
			if(plane_offset != 0 && !initial(mytype.allows_offsetting))
				continue
			var/atom/movable/screen/plane_master/instance = new mytype(null, src, plane_offset)
			plane_masters["[instance.plane]"] = instance
			prep_plane_instance(instance)

/// Similarly, exists so subtypes can do unique behavior to planes on creation
/datum/plane_master_group/proc/prep_plane_instance(atom/movable/screen/plane_master/instance)
	return

/// Holds plane masters for popups, like camera windows
/datum/plane_master_group/popup

/datum/plane_master_group/popup/get_plane_types()
	var/list/types = ..()
	// Don't show blackness, fucks up the screen. check if this is still needed post relays, thx
	return types - /atom/movable/screen/plane_master/blackness

/datum/plane_master_group/popup/prep_plane_instance(atom/movable/screen/plane_master/instance)
	instance.del_on_map_removal = FALSE
	// We set blendmode here because we aren't using relays, which would ordinarially handle the blending for us
	// Don worry about it brother
	if(instance.blend_mode_override)
		instance.blend_mode = instance.blend_mode_override

// Should really be using relays and show to and such, but https://www.byond.com/forum/post/2797107 and what it does to relays using CENTER break that
// I hate it here
/datum/plane_master_group/popup/show_plane(atom/movable/screen/plane_master/plane)
	our_hud.mymob.client.register_map_obj(plane)
