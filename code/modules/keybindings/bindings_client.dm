
// Clients aren't datums so we have to define these procs indpendently.
// These verbs are called for all key press and release events
/client/verb/key_down(key as text)
	set instant = 1
	set hidden = 1

	if(keys_active[key]) // Allow hitting the same key only once per tick. Basic spam prevention.
		return

	keys_held[key] = 1
	keys_active[key] = 1

	// Client-level keybindings are ones anyone should be able to do at any time
	// Things like taking screenshots, hitting tab, and adminhelps.

	switch(key)

		if("F1")
			if(keys_active["ctrl"] && keys_active["shift"]) // Is this command ever used?
				winset(src, null, "command=.options")
			else
				adminhelp()

		if("F2") // Screenshot. Hold shift to choose a name and location to save in
			winset(src, null, "command=.screenshot [!keys_active["shift"] ? "auto" : ""]")

		if("F12") // Toggles minimal HUD
			mob.button_pressed_F12()

	if(holder)
		holder.key_down(key, src)
	if(mob.focus)
		mob.focus.key_down(key, src)

/client/verb/key_up(key as text)
	set instant = 1
	set hidden = 1

	keys_held.Remove(key)

//	if(keys_active[key]) 	// Can't do this because it'll always be true. So don't add anything laggy in key_up() that people can spam, ok?
//		return

	if(holder)
		holder.key_up(key, src)
	if(mob.focus)
		mob.focus.key_up(key, src)

// Called every game tick
/client/proc/key_loop()
	if(!keys_active.len)
		return

	if(holder)
		holder.key_loop(src)
	if(mob.focus)
		mob.focus.key_loop(src)

	keys_active = keys_held.Copy()