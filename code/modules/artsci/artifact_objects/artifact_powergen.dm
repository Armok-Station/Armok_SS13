#define KW *1000
#define MAX_POSSIBLE_GEN 600 KW
#define SIDEEFFECT_THRESHOLD 100 KW
#define SHITFUCK_THRESHOLD 400 KW

/obj/machinery/power/generator_artifact
	icon = 'icons/obj/artifacts.dmi'
	icon_state = "narnar-1"
	resistance_flags = LAVA_PROOF | ACID_PROOF | INDESTRUCTIBLE
	use_power = NO_POWER_USE
	circuit = null
	density = TRUE
	anchored = FALSE
	ARTIFACT_SETUP(/obj/machinery/power/generator_artifact, /datum/component/artifact/generator, SSmachines)

/datum/component/artifact/generator
	associated_object = /obj/machinery/power/generator_artifact
	type_name = "Power Generator"
	weight = ARTIFACT_RARE
	valid_triggers = list(/datum/artifact_trigger/heat, /datum/artifact_trigger/shock, /datum/artifact_trigger/radiation)
	valid_origins = list(ORIGIN_WIZARD,ORIGIN_SILICON) //narnar doesnt need power
	activation_message = "begins emitting a faint, droning hum."
	deactivation_message = "shortcircuits!"
	xray_result = "COMPLEX"
	COOLDOWN_DECLARE(sideeffect_cooldown)

	var/power_gen = 0
	///does the power output fluctuate
	var/unstable_generation = FALSE
	
/datum/component/artifact/generator/setup()
	. = ..()
	if(prob(65))
		power_gen = rand(1 KW, MAX_POSSIBLE_GEN / 2)
	else
		power_gen = rand(1 KW, MAX_POSSIBLE_GEN)
	unstable_generation = prob(40)
	potency += power_gen / 1.5 KW

/datum/component/artifact/generator/effect_touched(mob/living/user)
	var/obj/machinery/power/generator_artifact/powerholder = holder
	if(!powerholder.anchored && locate(/obj/structure/cable) in get_turf(powerholder))
		powerholder.visible_message(span_warning("[holder] seems to snap to the cable!"))
		playsound(get_turf(powerholder), 'sound/items/deconstruct.ogg', 50, TRUE)
		powerholder.anchored = TRUE
		powerholder.connect_to_network()
		return	
	holder.Beam(user, icon_state="lightning[rand(1,12)]", time = 0.5 SECONDS)
	playsound(get_turf(powerholder), 'sound/magic/lightningshock.ogg', 100, TRUE, extrarange = 5)
	var/damage = user.electrocute_act(power_gen / 1.5 KW, powerholder, flags = SHOCK_NOSTUN)
	to_chat(user, span_userdanger("You are hit by a burst of electricity from [holder]!"))
	if(damage > 80) //just fuckin repel them from the sheer power burst
		var/turf/owner_turf = get_turf(holder)
		var/throwtarget = get_edge_target_turf(get_turf(user), get_dir(owner_turf, get_step_away(user, owner_turf)))
		user.safe_throw_at(throwtarget, power_gen / 38 KW, 1, force = MOVE_FORCE_EXTREMELY_STRONG)
	if(damage > 350 && prob(50)) //lol, lmao
		user.dust(just_ash = TRUE, drop_items = TRUE)
		Deactivate() //shortcircuit

	if(prob(20)) //try to get yourself shocked with insuls many times to shortcircuit it
		Deactivate()

/datum/component/artifact/generator/effect_process() //todo add more
	if(!holder.anchored)
		return
	var/obj/machinery/power/generator_artifact/powerholder = holder
	powerholder.add_avail(power_gen * (unstable_generation ? rand(0.1, 1) : 1))
	if(power_gen < SIDEEFFECT_THRESHOLD || !COOLDOWN_FINISHED(src,sideeffect_cooldown)) //sorry boss no can do
		return
	COOLDOWN_START(src,sideeffect_cooldown,rand(4,8) SECONDS)
	//minor to medium side effects
	if(power_gen >= (SHITFUCK_THRESHOLD / 3))
		powerholder.visible_message(span_danger("\The [holder] lets out a shower of thunder!"), span_hear("You hear a loud electrical crack!"))
		playsound(get_turf(powerholder), 'sound/magic/lightningshock.ogg', 100, TRUE, extrarange = 5)
		tesla_zap(powerholder, rand(2,3), power_gen / 3500)
	
	//SHIT IS FUCK
	
	if(power_gen < SHITFUCK_THRESHOLD)
		return
		
	if(prob(50)) //hehe
		explosion(powerholder, flame_range = rand(1,2), adminlog = FALSE) //doesnt log to not spam
	else
		var/datum/gas_mixture/merger = new
		merger.assert_gas(/datum/gas/carbon_dioxide)
		merger.gases[/datum/gas/carbon_dioxide][MOLES] = rand(10,120)
		merger.temperature = rand(200,1000)
		var/turf/holder_turf = get_turf(holder)
		holder_turf.assume_air(merger)


/datum/component/artifact/generator/effect_deactivate()
	var/obj/machinery/power/generator_artifact/powerholder = holder
	powerholder.disconnect_from_network()
	powerholder.anchored = FALSE
	playsound(get_turf(powerholder), 'sound/items/deconstruct.ogg', 50, TRUE)

#undef SHITFUCK_THRESHOLD
#undef SIDEEFFECT_THRESHOLD
#undef MAX_POSSIBLE_GEN
#undef KW
