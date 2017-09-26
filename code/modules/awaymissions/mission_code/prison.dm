/**********************Areas******************************/

/area/prisonv2
	name = "Prison USSR"
	icon_state = "brig"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	requires_power = TRUE
	has_gravity = TRUE
	noteleport = TRUE
	blob_allowed = FALSE
	flags_1 = NONE

/area/prisonv2out
	name = "Caves USSR"
	icon_state = "yellow"
	requires_power = TRUE
	has_gravity = TRUE
	noteleport = TRUE
	blob_allowed = FALSE
	flags_1 = NONE

/**********************Turf Walls**************************/

/turf/closed/wall/brick
	name = "brick wall"
	desc = "���������� ��� ����� ���� ������ �����, �� �� �������� ���� ����� �� �������. �����."
	icon = 'icons/turf/walls/brick_wall.dmi'
	icon_state = "brick"
	hardness = 4500
	explosion_block = 5
	slicing_duration = 20000
	canSmoothWith = list(/turf/closed/wall/brick, /obj/structure/falsewall/brick)

/**********************Turf Minerals************************/

/turf/closed/mineral/bscrystal/dirty
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	defer_change = 1

/turf/closed/mineral/uranium/dirty
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	defer_change = 1

/turf/closed/mineral/plasma/dirty
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	defer_change = 1

/turf/closed/mineral/titanium/dirty
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	defer_change = 1

/turf/closed/mineral/silver/dirty
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	defer_change = 1

/turf/closed/mineral/gold/dirty
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	defer_change = 1

/turf/closed/mineral/diamond/dirty
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	defer_change = 1

/turf/closed/mineral/coal
	mineralType = /obj/item/stack/sheet/mineral/coal
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	spreadChance = 20
	spread = 1
	scan_state = "rock_Iron"

/turf/closed/mineral/random/prison
	turf_type = /turf/open/floor/plating/asteroid/dirty
	baseturf = /turf/open/floor/plating/asteroid/dirty
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	defer_change = 1
	mineralChance = 10
	mineralSpawnChanceList = list(
		/turf/closed/mineral/uranium/dirty = 3, /turf/closed/mineral/diamond/dirty = 3, /turf/closed/mineral/gold/dirty = 3, /turf/closed/mineral/titanium/dirty = 3,
		/turf/closed/mineral/silver/dirty = 3, /turf/closed/mineral/plasma/dirty = 3, /turf/closed/mineral/bscrystal/dirty = 3, /turf/closed/mineral/coal = 25)

/**********************Turf Floors**************************/

/turf/open/floor/plating/asteroid/dirty
	name = "dirt"
	desc = "���������."
	icon = 'icons/misc/prison.dmi'
	postdig_icon_change = TRUE
	icon_state = "dirt"
	icon_plating = "dirt"
	environment_type = "dirt"
	turf_type = /turf/open/floor/plating/asteroid/dirty
	floor_variance = 0
	initial_gas_mix = "o2=22;n2=82;TEMP=255.15"
	archdrops = list(/obj/item/ore/glass = 5)
	slowdown = 3

/turf/open/floor/trot
	name = "trotuar"
	desc = "� ����� ��� ��� ��������."
	icon_state = "trot"
	initial_gas_mix = "o2=22;n2=82;TEMP=248.15"
	icon = 'icons/misc/beton.dmi'
	floor_tile = /obj/item/stack/tile/trot
	slowdown = -1
	broken_states = list("damaged")

/turf/open/floor/beton
	name = "beton"
	desc = "������ �� ���� �� ����� ������ �������."
	icon_state = "beton"
	initial_gas_mix = "o2=22;n2=82;TEMP=293.15"
	icon = 'icons/misc/beton.dmi'
	floor_tile = /obj/item/stack/tile/beton
	broken_states = list("damaged")
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/turf/open/floor/beton)
	flags_1 = NONE

/turf/open/floor/beton/Initialize()
	..()
	update_icon()

/turf/open/floor/beton/update_icon()
	if(!..())
		return 0
	if(!broken && !burnt)
		if(smooth)
			queue_smooth(src)
	else
		make_plating()
		if(smooth)
			queue_smooth_neighbors(src)

/******************Structures***************************/

/obj/structure/falsewall/brick
	name = "brick wall"
	desc = "���������� ��� ����� ���� ������ �����, �� �� �������� ���� ����� �� �������. �����."
	icon = 'icons/turf/walls/brick_wall.dmi'
	icon_state = "brick"
	walltype = /turf/closed/wall/brick
	canSmoothWith = list(/obj/structure/falsewall/brick, /turf/closed/wall/brick)

/obj/structure/curtain/prison/update_icon()
	if(!open)
		icon_state = "closed"
		layer = WALL_OBJ_LAYER
		density = FALSE
		open = FALSE
		opacity = 1

	else
		icon_state = "open"
		layer = WALL_OBJ_LAYER
		density = FALSE
		open = TRUE
		opacity = 0

/******************Structures Signs********************/

/obj/structure/sign/prison
	icon = 'icons/misc/prison.dmi'

/obj/structure/sign/prison/uprava
	name = "\improper Uprava"
	icon = 'icons/misc/prisonw.dmi'
	desc = "����� �������� ������."
	icon_state = "uprava"

/obj/structure/sign/prison/blok1
	name = "\improper Blok 1"
	desc = "������ ����."
	icon_state = "blok1"

/obj/structure/sign/prison/tok
	name = "\improper Ne prikasaisya!"
	desc = "�� ����������!"
	icon_state = "tok"

/obj/structure/sign/prison/hitler
	name = "\improper Hitler"
	desc = "����� �������� �������."
	icon_state = "hitler"

/obj/structure/sign/prison/net
	name = "\improper Net!"
	desc = "���!"
	icon_state = "net"

/obj/structure/sign/prison/kolesa
	name = "\improper Pomni o kolesah"
	desc = "����� � �������."
	icon_state = "kolesa"

/obj/structure/sign/prison/pobeda
	name = "\improper K novym pobedam!"
	desc = "� ����� ������� � ����� � ������!"
	icon_state = "pobeda"

/obj/structure/sign/prison/bolt
	name = "\improper Ne boltay!"
	desc = "�� ������!"
	icon_state = "bolt"

/obj/structure/sign/prison/pyan
	name = "\improper Byl pyan"
	desc = "� �� ������������ ��� ����."
	icon_state = "pyan"

/obj/structure/sign/prison/yannp
	name = "\improper Ne ponyal!"
	desc = "� ���� ������ ����������� ���������!"
	icon_state = "yannp"

/obj/structure/sign/prison/bolt
	name = "\improper Ne boltay!"
	desc = "�� ������!."
	icon_state = "bolt"

/********************Machinery***************************/

/obj/machinery/vending/sovietvend
	name = "\improper Soviet Vend"
	icon = 'icons/misc/prison.dmi'
	desc = "������� ����������� �� �����������!"
	icon_state = "sovietvend"
	product_ads = "�� ���� � ������.;� �� �������� ����� �������?;����� ���������� �����!"
	products = list(/obj/item/clothing/under/soviet = 20, /obj/item/clothing/head/ushanka = 20, /obj/item/reagent_containers/food/snacks/candy = 40,
					/obj/item/reagent_containers/food/drinks/bottle/vodka = 40, /obj/item/gun/ballistic/automatic/ak = 5, /obj/item/ammo_box/magazine/ak762 = 5)
	contraband = list(/obj/item/clothing/under/syndicate/tacticool = 20)
	armor = list(melee = 100, bullet = 100, laser = 100, energy = 100, bomb = 0, bio = 0, rad = 0, fire = 100, acid = 50)
	resistance_flags = FIRE_PROOF

/obj/machinery/door/airlock/woodsov
	name = "wooden soviet door"
	icon = 'icons/obj/doors/airlocks/station/wood.dmi'
	var/mineral = "wood"
	req_access_txt = "150"
	assemblytype = /obj/structure/door_assembly/door_assembly_wood

/obj/machinery/power/port_gen/pacman/coal
	name = "\improper HellMachine"
	desc = "��� ����� ���������� �������� �������� ������ �������� �� ���� �������� ����. ����������� ������."
	icon = 'icons/misc/prisond.dmi'
	icon_state = "portgen0_0"
	base_icon = "portgen0"
	sheet_path = /obj/item/stack/sheet/mineral/coal
	power_gen = 15000
	time_per_sheet = 85
	density = TRUE
	anchored = TRUE

/********************Top Z-Levels***************************/

/obj/effect/bump_teleporter/prison/CollidedWith(atom/movable/AM)
	if(!ismob(AM))
		return
	if(!id_target)
		return

	for(var/obj/effect/bump_teleporter/BT in AllTeleporters)
		if(BT.id == src.id_target)
			AM.visible_message("<span class='boldwarning'>[AM] ��������!</span>", "<span class='userdanger'>������� � ����...</span>")
			AM.forceMove(BT.loc) //Teleport to location with correct id.
			if(isliving(AM))
				var/mob/living/L = AM
				L.Knockdown(100)
				L.adjustBruteLoss(70)

/obj/effect/decal/tuman
	name = "tuman"
	desc = "����� �����, ����� �� �����..."
	icon = 'icons/misc/prison.dmi'
	icon_state = "tuman"
	layer = 6

/********************Tiles***************************/

/obj/item/stack/tile/beton
	name = "beton floor tile"
	singular_name = "beton floor tile"
	desc = "����� ������. ���..."
	icon = 'icons/misc/prison.dmi'
	icon_state = "tile_beton"
	turf_type = /turf/open/floor/beton

/obj/item/stack/tile/trot
	name = "trot floor tile"
	singular_name = "trot floor tile"
	desc = "����� ���������� ������. �����?"
	icon = 'icons/misc/prison.dmi'
	icon_state = "tile_trot"
	turf_type = /turf/open/floor/trot

/********************Plants***************************/

/obj/machinery/prisonplant
	name = "potted plant"
	icon = 'icons/obj/flora/plants.dmi'
	icon_state = "plant-01"
	layer = 5

/obj/machinery/prisonplant/Initialize()
	icon_state = "plant-[rand(0,2)][rand(0,5)]"

/********************Lights***************************/

/obj/machinery/light/streetlight
	name = "street light"
	icon = 'icons/misc/prisonh.dmi'
	base_state = "light"
	icon_state = "light1"
	brightness = 10
	layer = 5
	density = 1
	light_type = /obj/item/light/bulb
	fitting = "bulb"

/********************Guns***************************/

/obj/item/gun/ballistic/automatic/ak
	name = "\improper AK-47"
	desc = "����������� ������� �����������. ���������� ������� ������� 7.62"
	icon = 'icons/misc/prison.dmi'
	icon_state = "kalash"
	origin_tech = "combat=4;materials=2;syndicate=4"
	mag_type = /obj/item/ammo_box/magazine/ak762
	burst_size = 3

/obj/item/ammo_box/magazine/ak762
	name = "AK-47 magazine (7.62)"
	icon = 'icons/misc/prison.dmi'
	icon_state = "akmag"
	ammo_type = /obj/item/ammo_casing/a762
	caliber = "a762"
	max_ammo = 30

/*****************Mineral Sheets**********************/

/obj/item/stack/sheet/mineral/coal
	name = "coal"
	icon = 'icons/misc/prison.dmi'
	desc = "������ ��� ��� ���."
	singular_name = "coal"
	icon_state = "coal"
	throw_speed = 3
	throw_range = 5
	origin_tech = "materials=1"
	materials = list(MAT_DIAMOND=MINERAL_MATERIAL_AMOUNT)

/*********************ID system*************************/

/obj/item/card/id/keys
	name = "keys"
	icon = 'icons/misc/prison.dmi'
	icon_state = "keys"
	desc = "����� �� ���� ������"

/obj/item/card/id/keys/Initialize()
	access = get_all_syndicate_access()
	..()

/*********************Radio Shit*************************/

/obj/item/device/radio/headset/radioprison
	name = "soviet radio"
	icon = 'icons/misc/prison.dmi'
	desc = "�������� ���������� ��������� ������ - �����!"
	canhear_range = 3
	frequency = 1469
	slot_flags = SLOT_EARS
	icon_state = "radio"
	flags_2 = BANG_PROTECT_2

/**********************Spawners**************************/

/obj/effect/mob_spawn/human/prison
	desc = "������� ��� ���-�� �������� ��� �������..."
	icon = 'icons/misc/prison.dmi'
	icon_state = "spwn"
	roundstart = FALSE
	death = FALSE
	var/list/imena = list("��������", "��������", "�������", "��������", "����", "��������", "������", "������", "���������", "�������", "�����", "������� ����")


/obj/effect/mob_spawn/human/prison/doctor
	name = "doctor spawner"
	flavour_text = "�� ������ �������������� ������ �������. ������������ ������� �� ������, ����� ��� ��� ���, � �� ��������� �������� ���� ��� ������.<b> � ��, ������ � ���� ������ �� ��������������, �� �������� ������� � ��� � ����.</b>"
	outfit = /datum/outfit/prison/doctor
	assignedrole = "Doctor USSR"

/obj/effect/mob_spawn/human/prison/vertuhai
	name = "vertuhai spawner"
	flavour_text = "�� ������ ���������� ������ �������. ������������ �� ������� ����� ��� ������� ����� � �� ��������� ������ �������.<b> � ��, ������ � ���� ������ �� ��������������, �� �������� ������� � ��� � ����.</b>"
	outfit = /datum/outfit/prison/vertuhai
	assignedrole = "Vertuhai USSR"

/obj/effect/mob_spawn/human/prison/mehanik
	name = "mehanik spawner"
	flavour_text = "�� ������ ������� ������ �������. ������������ �� �������� ���������, ��������, ��� �� ������� � �� ��������� ���������� � �����, ����� ������� ����� ���.<b> � ��, ������ � ���� ������ �� ��������������, �� �������� ������� � ��� � ����.</b>"
	outfit = /datum/outfit/prison/mehanik
	assignedrole = "Mehanik USSR"

/obj/effect/mob_spawn/human/prison/nachalnik
	name = "nachalnik spawner"
	flavour_text = "�� ������ ����������� ������ �������. ������������ �������� � � ������� � �� ��������� ���������� ����� � ���, ��� ������� ������ ������.<b> � ��, ������ � ���� ������ �� ��������������, �� �������� ������� � ��� � ����.</b>"
	icon_state = "spwn"
	outfit = /datum/outfit/prison/nachalnik
	assignedrole = "Nachalnik USSR"

/obj/effect/mob_spawn/human/prison/prisoner
	name = "shkonka spawner"
	desc = "������� ��� ���-�� �������� ��� �������..."
	flavour_text = "�� ������ ����������� ������ �������. ����������� ���� �������� ���� ��� �������, ���������� ���������� � �� ��������� � ���, ��� ������� ������ ������. ������, ������ �� ��� �� "
	outfit = /datum/outfit/prison/prisoner
	assignedrole = "Prisoner USSR"

/**********************Outfits**************************/

/datum/outfit/prison/doctor
	name = "Doctor USSR"
	head = /obj/item/clothing/head/ushanka
	ears = /obj/item/device/radio/headset/radioprison
	uniform = /obj/item/clothing/under/soviet
	suit = /obj/item/clothing/suit/toggle/labcoat
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	l_pocket = /obj/item/card/id/keys
	back = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(/obj/item/device/flashlight/lantern = 1, /obj/item/crowbar/red = 1)
	implants = list(/obj/item/implant/weapons_auth)

/datum/outfit/prison/vertuhai
	name = "Vertuhai USSR"
	head = /obj/item/clothing/head/ushanka
	ears = /obj/item/device/radio/headset/radioprison
	uniform = /obj/item/clothing/under/soviet
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	r_pocket = /obj/item/restraints/handcuffs
	l_pocket = /obj/item/card/id/keys
	belt = /obj/item/melee/classic_baton
	back = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(/obj/item/device/flashlight/lantern = 1, /obj/item/crowbar/red = 1)
	implants = list(/obj/item/implant/weapons_auth)

/datum/outfit/prison/mehanik
	name = "Mehanik USSR"
	head = /obj/item/clothing/head/ushanka
	ears = /obj/item/device/radio/headset/radioprison
	uniform = /obj/item/clothing/under/soviet
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	l_pocket = /obj/item/card/id/keys
	belt = /obj/item/storage/belt/utility/full/engi
	back = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(/obj/item/device/flashlight/lantern = 1, /obj/item/crowbar/red = 1)
	implants = list(/obj/item/implant/weapons_auth)

/datum/outfit/prison/nachalnik
	name = "Nachalnik USSR"
	head = /obj/item/clothing/head/ushanka
	ears = /obj/item/device/radio/headset/radioprison
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/armor/vest/capcarapace/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	r_pocket = /obj/item/gun/ballistic/automatic/pistol
	l_pocket = /obj/item/card/id/keys
	belt = /obj/item/storage/belt/military
	back = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(/obj/item/device/flashlight/lantern = 1, /obj/item/crowbar/red = 1)
	implants = list(/obj/item/implant/weapons_auth)

/datum/outfit/prison/prisoner
	name = "Prisoner USSR"
	uniform = /obj/item/clothing/under/rank/prisoner
	shoes = /obj/item/clothing/shoes/sneakers/orange

/**********************Spawn-flavoures**************************/

/obj/effect/mob_spawn/human/prison/doctor/special(mob/living/L)
	L.real_name = "������ [pick(imena)]"
	L.name = L.real_name

/obj/effect/mob_spawn/human/prison/vertuhai/special(mob/living/L)
	L.real_name = "���������� [pick(imena)]"
	L.name = L.real_name

/obj/effect/mob_spawn/human/prison/mehanik/special(mob/living/L)
	L.real_name = "������� [pick(imena)]"
	L.name = L.real_name

/obj/effect/mob_spawn/human/prison/nachalnik/special(mob/living/L)
	L.real_name = "��������� [pick(imena)]"
	L.name = L.real_name

/obj/effect/mob_spawn/human/prison/prisoner/special(mob/living/L)
	var/list/klikuhi = list("������", "������", "��������", "�����", "��������", "�������", "�����", "���������", "������", \
	"�������", "�������", "�������", "�������", "������", "����������", "�����", "�������", "���������", "����������", \
	"������", "�����", "�����", "�������", "�����", "��������", "�����", "���������", "��������", "��������", "�����", "�����", \
	"�����", "�������", "�������", "��������", "���������", "�������", "����", "������", "��������", "����")
	L.real_name = "[pick(klikuhi)]"
	L.name = L.real_name

/obj/effect/mob_spawn/human/prison/prisoner/Initialize(mapload)
	. = ..()
	var/list/zacho = list("��������", "���������", "���������", "������������ ������������", "��������� �����", "������ ����������������", \
	"�����", "���������� ������������ ��������", "���������� ���������", "�����")
	flavour_text += "[pick(zacho)].</b>."

