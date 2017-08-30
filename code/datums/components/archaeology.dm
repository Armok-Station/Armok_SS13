/* How this works:
		In turf.Initialize() , AddComponent(/datum/component/archaeology, prob2drop). prob2drop is a base number that affects each drop in list/drop the same. Good for if you want to have turfs be a bit more dynamic.
		In the turf's vars, you can set the drop list with the archdrops var. Format is type = num where num is the max it could possibly drop. postdig
		In the turf's AttackBy() [open turfs are vastly different and don't typically call inheritance hence component], call ArchaeologySignal(user, W). This will send the signal to the component as well.
		If your turf has a unique post-dig sprite like basalt/asteroid, put that in postdig_icon as a text string AND set postdig_icon_change = TRUE.
*/
/datum/component/archaeology
	dupe_type = COMPONENT_DUPE_UNIQUE
	var/list/archdrops = list()
	var/prob2drop = 0
	var/mob/user
	var/obj/item/W
	var/dug = FALSE

/datum/component/archaeology/Initialize(_prob2drop, _archdrops)
	prob2drop = Clamp(_prob2drop, 0, 100)
	if(isopenturf(parent))
		RegisterSignal(COMSIG_PARENT_ATTACKBY,.proc/Dig)
		RegisterSignal(COMSIG_ATOM_EX_ACT, .proc/BombDig)
		RegisterSignal(COMSIG_ATOM_SING_PULL, .proc/SingDig)

/datum/component/archaeology/Destroy()
	user = null
	W = null
	return ..()

/datum/component/archaeology/InheritComponent(datum/component/archaeology/A, i_am_original)
	var/list/other_drops = A.drops
	var/list/_drops = drops
	for(var/I in other_drops)
		_drops[I] += other_drops[I]

/datum/component/archaeology/proc/Dig(mob/user, obj/item/W)
	if(dug)
		to_chat(user, "<span class='notice'>Looks like someone has dug here already.</span>")
		return FALSE
	else
		var/digging_speed
		if (istype(W, /obj/item/shovel))
			var/obj/item/shovel/S = W
			digging_speed = S.digspeed
		else if (istype(W, /obj/item/pickaxe))
			var/obj/item/pickaxe/P = W
			digging_speed = P.digspeed

		if (digging_speed && isturf(user.loc))
			to_chat(user, "<span class='notice'>You start digging...</span>")
			playsound(parent, 'sound/effects/shovel_dig.ogg', 50, 1)

			if(do_after(user, digging_speed, target = parent))
				to_chat(user, "<span class='notice'>You dig a hole.</span>")
				gets_dug()
				dug = TRUE
				return TRUE
		return FALSE

/datum/component/archaeology/proc/gets_dug()
	if(dug)
		return
	else
		if(isopenturf(parent))
			var/turf/open/OT = parent
			for(var/thing in drops)
				var/maxtodrop = drops[thing]
				for(var/i in 1 to maxtodrop)
					if(prob(prob2drop)) // can't win them all!
						new thing(OT)

			if(OT.postdig_icon_change)
				if(istype(OT, /turf/open/floor/plating/asteroid/) && !OT.postdig_icon)
					var/turf/open/floor/plating/asteroid/AOT = parent
					AOT.icon_plating = "[AOT.environment_type]_dug"
					AOT.icon_state = "[AOT.environment_type]_dug"
				else
					if(isplatingturf(OT))
						var/turf/open/floor/plating/POT = parent
						POT.icon_plating = "[POT.postdig_icon]"
					OT.icon_state = "[OT.postdig_icon]"

			if(OT.slowdown) //Things like snow slow you down until you dig them.
				OT.slowdown = 0
			SSblackbox.add_details("pick_used_mining",W.type)
	dug = TRUE
	user = null
	W = null

/datum/component/archaeology/proc/SingDig(S, current_size)
	switch(current_size)
		if(STAGE_THREE)
			if(!prob(30))
				gets_dug()
		if(STAGE_FOUR)
			if(prob(50))
				gets_dug()
		else
			if(current_size >= STAGE_FIVE && prob(70))
				gets_dug()

/datum/component/archaeology/proc/BombDig(severity, target)
	var/turf/open/OT = parent
	OT.contents_explosion(severity, target)
	switch(severity)
		if(3)
			return
		if(2)
			if(prob(20))
				gets_dug()
		if(1)
			gets_dug()
