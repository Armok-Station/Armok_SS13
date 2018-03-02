/datum/relic_effect/attack
	hogged_signals = list(COMSIG_ITEM_ATTACK,COMSIG_ITEM_ATTACK_OBJ)

/datum/relic_effect/attack/apply_to_component(obj/item/A,datum/component/relic/comp)
	if(COMSIG_ITEM_ATTACK in hogged_signals)
		comp.RegisterSignal(COMSIG_ITEM_ATTACK, CALLBACK(src, .proc/attack_mob, A))
	if(COMSIG_ITEM_ATTACK_OBJ in hogged_signals)
		comp.RegisterSignal(COMSIG_ITEM_ATTACK_OBJ, CALLBACK(src, .proc/attack_obj, A))

/datum/relic_effect/attack/proc/attack_mob(obj/item/A, mob/living/target, mob/living/user)
	return use_power(A,user)

/datum/relic_effect/attack/proc/attack_obj(obj/item/A, obj/target, mob/user)
	return use_power(A,user)

/datum/relic_effect/attack/repair_robot
	weight = 20
	hint = list("Analysis revealed a full set of 80 different diagnostic tools. Only 7 could be identified.")
	hogged_signals = list(COMSIG_ITEM_ATTACK)
	var/healed_brute = 10
	var/healed_burn = 10
	var/list/affected_types

/datum/relic_effect/attack/repair_robot/init()
	affected_types = typecacheof(/mob/living/silicon) + typecacheof(/mob/living/simple_animal/bot) + typecacheof(/mob/living/simple_animal/drone)
	healed_brute = rand(5,20)
	healed_burn = rand(5,20)
	if(prob(30)) //Damage converter
		healed_brute *= pick(-1,1)
		healed_burn *= abs(-healed_brute)

/datum/relic_effect/attack/repair_robot/attack_mob(obj/item/A, mob/living/target, mob/living/user)
	if(user.a_intent != INTENT_HELP || !..())
		return
	if(affected_types[target.type])
		target.adjustBruteLoss(-healed_brute)
		target.adjustFireLoss(-healed_burn)

/datum/relic_effect/attack/activate
	weight = 20
	var/datum/relic_effect/activate/internal

/datum/relic_effect/attack/activate/init()
	var/internaltype = pick(subtypesof(/datum/relic_effect/activate))
	internal = new internaltype()
	internal.init()
	internal.free = TRUE

/datum/relic_effect/attack/activate/attack_mob(obj/item/A, mob/living/target, mob/living/user)
	if(..())
		internal.activate(A,target,user)

/datum/relic_effect/attack/activate/attack_obj(obj/item/A, obj/target, mob/living/user)
	if(..())
		internal.activate(A,target,user)

/datum/relic_effect/attack/ignite
	weight = 20
	hint = list("It is covered in a smooth film of unidentified high-performance fuel.")
	firstname = list("burning","nova","blazing","pyro","thermonuclear","fusic","hidrazine","gas","superheated","plasmic","tritium")
	lastname = list("igniter","flare","burninator","cyclotorch","brumane","incinerator","fulgurite")
	var/apply_stacks = 1
	var/max_stacks = 10

/datum/relic_effect/attack/ignite/apply()
	apply_stacks = rand(1,5)
	max_stacks = rand(1,12)
	if(prob(40))
		apply_stacks *= rand(1,3)
	if(prob(10)) //contains superfuel
		max_stacks *= rand(1,5)
	..()

/datum/relic_effect/attack/ignite/attack_mob(obj/item/A, mob/living/target, mob/living/user)
	if(..())
		if(target.fire_stacks < max_stacks)
			target.adjust_fire_stacks(apply_stacks)
		target.IgniteMob()

/datum/relic_effect/attack/ignite/attack_obj(obj/item/A, obj/target, mob/living/user)
	if(..())
		target.fire_act(1000,10)

/datum/relic_effect/attack/inject
	weight = 20
	hint = list("It's covered in small needles.")
	hogged_signals = list(COMSIG_ITEM_ATTACK)
	var/list/applied_chems = list()
	var/piercing = FALSE

/datum/relic_effect/attack/inject/init()
	var/times = rand(1,3)
	for(var/i in 1 to times)
		applied_chems[get_random_reagent_id()] += rand(1,10)
	if(prob(30))
		piercing = TRUE

/datum/relic_effect/attack/inject/attack_mob(obj/item/A, mob/living/target, mob/living/user)
	if(user.a_intent != INTENT_HELP || !..())
		return
	if(target.reagents && target.can_inject(user, FALSE, penetrate_thick = piercing))
		for(var/id in applied_chems)
			target.reagents.add_reagent(id,applied_chems[id])