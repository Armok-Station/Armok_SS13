/** Icon State Sanity
 * - Also known as "Why the fuck doesn't the esword that traitor is holding have a sprite."
 *  Iterates over all atom types, minus areas, and verifies that their default icon_state exists in their default icon. Note that this cannot check for atoms with custom icon_states.
 */
/datum/unit_test/icon_state_sanity

/datum/unit_test/icon_state_sanity/Run()
	var/list/atoms_to_check = typesof(/atom) - typesof(/area)
	for(var/atom_path in atoms_to_check)
		var/atom/path_ref = atom_path
		var/ref_icon = initial(path_ref.icon)
		var/ref_state = initial(path_ref.icon_state)
		if(!ref_icon || !ref_state)
			continue // This catches edge cases where we get the path to an abstract atom; i.e. mob holders
		if(!(ref_state in icon_states(ref_icon)))
			Fail("cannot find icon_state '[ref_state]' for icon '[ref_icon]' for '[path_ref]'")
