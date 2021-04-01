/obj/item/clothing/suit/armor/skeledoom
	name = "skeleton suit"
	desc = "An armor suit with a skeleton print on it. Spooky!"
	icon_state = "skeleton"
	inhand_icon_state = "skeleton"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	clothing_flags = THICKMATERIAL

	armor = list(MELEE = 40, BULLET = 45, LASER = 25, ENERGY = 25, BOMB = 15, BIO = 50, RAD = 0, FIRE = 90, ACID = 90, WOUND = 15)

/obj/item/clothing/suit/armor/skeledoom/cryo
	icon_state = "skeleton_cryo"
	cold_protection = CHEST|GROIN|ARMS|LEGS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT

/obj/item/clothing/gloves/color/white/skeleton
	name = "skeleton gloves"
	desc = "Black gloves with bone print of them."
	icon_state = "skeleton"
	siemens_coefficient = 0
	permeability_coefficient = 0.05

/obj/item/clothing/mask/gas/skeleton
	name = "skeleton gas mask"
	desc = "Spooky."
	icon_state = "death"

/obj/item/clothing/head/beret/black/skeledoom
	name = "armored black beret"
	desc = "An armored black beret, perfect for badass snipers."
	armor = list(MELEE = 40, BULLET = 45, LASER = 25, ENERGY = 25, BOMB = 15, BIO = 50, RAD = 0, FIRE = 90, ACID = 90, WOUND = 15)
	clothing_flags = THICKMATERIAL

/obj/item/clothing/head/beret/black/skeledoom/cryo
	name = "armored black hood"
	desc = "A black hood separated from a coat. Not very comfortable."
	icon_state = "hood_hos"
	icon = 'icons/obj/clothing/head/winterhood.dmi'
	worn_icon = 'icons/mob/clothing/head/winterhood.dmi'
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT

/obj/item/gun/ballistic/automatic/sniper_rifle/skeledoom
	name = "modified sniper rifle"
	desc = "A modified .50 sniper rifle with a dna-locked pin and a suppressor. It has \"This is my gun, fuck off.\" written on the grip."
	can_suppress = TRUE
	fire_delay = 2 //Speedy!
	pin = /obj/item/firing_pin/dna

/obj/item/gun/ballistic/automatic/sniper_rifle/skeledoom/Initialize()
	. = ..()
	var/obj/item/suppressor/suppressor = new(src)
	install_suppressor(suppressor)

/obj/projectile/bullet/p50/smoke
	name =".50 smoke bullet"
	armour_penetration = 15
	damage = 10
	dismemberment = 0
	paralyze = 0
	breakthings = FALSE

/obj/projectile/bullet/p50/smoke/on_hit(atom/target, blocked = FALSE)
	playsound(src, 'sound/effects/smoke.ogg', 50, TRUE, -3)
	var/datum/effect_system/smoke_spread/bad/smoke = new
	smoke.set_up(3, src)
	smoke.start()
	qdel(smoke)
	. = ..()

/obj/item/ammo_casing/p50/smoke
	name = ".50 smoke bullet casing"
	desc = "A .50 bullet casing, containing a small mix that creates smoke upon impact."
	projectile_type = /obj/projectile/bullet/p50/smoke
	harmful = FALSE

/obj/item/ammo_box/magazine/sniper_rounds/smoke
	name = "sniper rounds (Smoke)"
	desc = "Smoke sniper rounds, designed for professional bee hunters."
	icon_state = "smoker"
	base_icon_state = "smoker"
	ammo_type = /obj/item/ammo_casing/p50/smoke
	max_ammo = 5
	caliber = CALIBER_50

/obj/item/ammo_casing/p50/taser
	name = ".50 taser bullet casing"
	desc = "A modified .50 bullet casing that will turn kinetical energy into electricity, creating a small taser bolt."
	projectile_type = /obj/projectile/energy/electrode
	harmful = FALSE

/obj/item/ammo_box/magazine/sniper_rounds/taser
	name = "sniper rounds (Taser)"
	desc = "Taser sniper rounds, perfect for pacifists and security."
	icon_state = "taser"
	base_icon_state = "taser"
	ammo_type = /obj/item/ammo_casing/p50/taser
	max_ammo = 5
	caliber = CALIBER_50

/obj/projectile/bullet/p50/net
	name =".50 net bullet"
	armour_penetration = 0
	damage = 0
	dismemberment = 0
	paralyze = 0
	breakthings = FALSE

/obj/projectile/bullet/p50/net/on_hit(atom/target, blocked = FALSE)
	if(!isliving(target))
		return ..()
	var/mob/living/net_target = target
	if(locate(/obj/structure/energy_net) in net_target.drop_location())
		return ..()
	var/obj/structure/energy_net/net = new (net_target.drop_location())
	net.affecting = net_target
	if(net_target.buckled)
		net_target.buckled.unbuckle_mob(firer, TRUE)
	net.buckle_mob(net_target, TRUE)
	. = ..()

/obj/item/ammo_casing/p50/net
	name = ".50 net bullet casing"
	desc = "A .50 bullet casing with an energy net projector attached to them."
	projectile_type = /obj/projectile/bullet/p50/net
	harmful = FALSE

/obj/item/ammo_box/magazine/sniper_rounds/net
	name = "sniper rounds (Net)"
	desc = "Smoke sniper rounds, designed for professional bee hunters."
	icon_state = "net_sniper"
	base_icon_state = "net_sniper"
	ammo_type = /obj/item/ammo_casing/p50/net
	max_ammo = 3
	caliber = CALIBER_50

/obj/item/reagent_containers/hypospray/medipen/beepen
	name = "anti-bee medipen"
	desc = "Contains a special mix of chemicals that will quickly purge all bee toxins from the body."
	icon_state = "beepen"
	inhand_icon_state = "medipen"
	base_icon_state = "beepen"
	volume = 40
	amount_per_transfer_from_this = 40
	list_reagents = list(/datum/reagent/medicine/calomel = 2, /datum/reagent/medicine/c2/multiver = 10, /datum/reagent/medicine/polypyr = 5, /datum/reagent/medicine/leporazine = 8, /datum/reagent/medicine/silibinin = 15)

/obj/item/storage/belt/bee_hunter
	name = "bee hunter belt"
	desc = "A belt for holding everything a professional bee hunter needss."
	icon_state = "grenadebeltnew"
	inhand_icon_state = "security"
	worn_icon_state = "grenadebeltnew"

/obj/item/storage/belt/bee_hunter/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 20
	STR.max_combined_w_class = 60
	STR.display_numerical_stacking = TRUE
	STR.set_holdable(list(/obj/item/ammo_box/magazine/sniper_rounds,
						  /obj/item/reagent_containers/hypospray/medipen/beepen,
						  /obj/item/grenade/smokebomb,
						  /obj/item/restraints/handcuffs,
						  /obj/item/grenade/flashbang
					))

/obj/item/storage/belt/bee_hunter/full/PopulateContents()
	for(var/i = 1 to 3)
		new /obj/item/ammo_box/magazine/sniper_rounds/net(src)
		new /obj/item/ammo_box/magazine/sniper_rounds/taser(src)
		new /obj/item/ammo_box/magazine/sniper_rounds/smoke(src)
		new /obj/item/reagent_containers/hypospray/medipen/beepen(src)
		new /obj/item/grenade/smokebomb(src)
		new /obj/item/grenade/flashbang(src)

	new /obj/item/restraints/handcuffs(src)
	new /obj/item/restraints/handcuffs(src)

/obj/item/storage/belt/bee_hunter/full/cryo/PopulateContents()
	for(var/i = 1 to 3)
		new /obj/item/ammo_box/magazine/sniper_rounds/net(src)
		new /obj/item/ammo_box/magazine/sniper_rounds/taser(src)
		new /obj/item/ammo_box/magazine/sniper_rounds/smoke(src)
		new /obj/item/reagent_containers/hypospray/medipen/beepen(src)
		new /obj/item/grenade/gluon(src)
		new /obj/item/grenade/flashbang(src)

	new /obj/item/restraints/handcuffs(src)
	new /obj/item/restraints/handcuffs(src)

/obj/item/clothing/glasses/thermal/sunglasses
	name = "thermal sunglasses"
	desc = "Sunglasses with a thermal vision. Badass."
	icon_state = "sunhudsec"
	darkness_view = 1
	flash_protect = FLASH_PROTECTION_FLASH
	tint = 1
	glass_colour_type = /datum/client_colour/glass_colour/darkred
