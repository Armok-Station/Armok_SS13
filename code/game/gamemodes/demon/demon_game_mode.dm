/datum/game_mode
	var/list/datum/mind/sintouched = list()
	var/list/datum/mind/demons = list()

/datum/game_mode/proc/auto_declare_completion_sintouched()
	var/text = ""
	if(sintouched.len)
		text += "<br><span class='big'><b>The sintouched were:</b></span>"
		var/list/sintouchedUnique = uniqueList(sintouched)
		for(var/datum/mind/sintouched_mind in sintouchedUnique)
			text += printplayer(sintouched_mind)
			text += printobjectives(sintouched_mind)
		text += "<br>"
	text += "<br>"
	world << text

/datum/game_mode/proc/auto_declare_completion_demons()
	/var/text = ""
	if(demons.len)
		text += "<br><span class='big'><b>The demons were:</b></span>"
		for(var/datum/mind/demon in demons)
			text += printplayer(demon)
			text += printdemoninfo(demon)
			text += printobjectives(demon)
		text += "<br>"
	world << text

/datum/game_mode/demon


/datum/game_mode/proc/finalize_demon(datum/mind/demon_mind)
	var/mob/living/carbon/human/S = demon_mind.current
	demon_mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/demon(null))
	demon_mind.AddSpell(new /obj/effect/proc_holder/spell/dumbfire/fireball/demonic(null))
	demon_mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/summon_contract(null))
	demon_mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/summon_pitchfork(null))
	var/trueName= randomDemonName()
	var/datum/objective/demon/soulquantity/soulquant = new
	soulquant.owner = demon_mind
	var/datum/objective/demon/soulquality/soulqual = new
	soulqual.owner = demon_mind
	demon_mind.objectives += soulqual
	demon_mind.objectives += soulquant
	demon_mind.demoninfo = demonInfo(trueName, 1)
	demon_mind.store_memory("Your demonic true name is [demon_mind.demoninfo.truename]<br>[demon_mind.demoninfo.banlaw()]<br>[demon_mind.demoninfo.banelaw()]<br>[demon_mind.demoninfo.obligationlaw()]<br>")
	demon_mind.demoninfo.owner = demon_mind
	spawn(10)
		if(demon_mind.assigned_role == "Clown")
			S << "<span class='notice'>Your infernal nature has allowed you to overcome your clownishness.</span>"
			S.dna.remove_mutation(CLOWNMUT)
