/** Icon State Sanity
 * - Also known as "Why the fuck doesn't the esword that traitor is holding have a sprite."
 *  Iterates over all atom types, minus areas, and verifies that their default icon_state exists in their default icon. Note that this cannot check for atoms with custom icon_states.
 */
/datum/unit_test/icon_state_sanity

/datum/unit_test/icon_state_sanity/Run()
	var/list/atoms_to_check = build_check_list()
	for(var/atom/atom_path as anything in atoms_to_check)
		var/ref_icon = initial(atom_path.icon)
		var/ref_state = initial(atom_path.icon_state)
		if(!ref_icon || !ref_state)
			continue // This catches edge cases where we get the path to an abstract atom; i.e. mob holders
		if(!(ref_state in icon_states(ref_icon)))
			if(initial(atom_path.greyscale_config))
				continue // If there is a GAGS config value, its covered by greyscale_config.dm. Checking for a valid GAGS config again here would be pointless.
			Fail("cannot find icon_state '[ref_state]' for icon '[ref_icon]' for '[atom_path]'")

/datum/unit_test/icon_state_sanity/proc/build_check_list()
	var/list/atoms_to_check = typesof(/atom) - typesof(/area)
	var/list/atoms_to_exclude = new
	atoms_to_exclude += typesof(/atom/movable/screen)

	return atoms_to_check - atoms_to_exclude
