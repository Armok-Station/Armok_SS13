/obj/item/weapon/gun_attachment/base/c9mm
	gun_type = CUSTOMIZABLE_PROJECTILE
	name = "9mm Pistol Ballistic Base"
	icon_state = "base_projectile_9mm"
	mag_type = /obj/item/ammo_box/magazine/pistolm9mm

/obj/item/weapon/gun_attachment/base/stun
	gun_type = CUSTOMIZABLE_ENERGY
	name = "Stun Energy Base"
	icon_state = "base_energy_stun"
	energy_type = list(/obj/item/ammo_casing/energy/electrode)
	the_item_state = "taser"

/obj/item/weapon/gun_attachment/base/htaser
	gun_type = CUSTOMIZABLE_ENERGY
	name = "Hybrid Taser Energy Base"
	icon_state = "base_energy_stun"
	energy_type = list(/obj/item/ammo_casing/energy/electrode, /obj/item/ammo_casing/energy/disabler)
	the_item_state = "advtaser"

/obj/item/weapon/gun_attachment/base/egun
	gun_type = CUSTOMIZABLE_ENERGY
	name = "Energy Gun Energy Base"
	icon_state = "base_energy_ion"
	energy_type = list(/obj/item/ammo_casing/energy/disabler, /obj/item/ammo_casing/energy/lasergun)
	the_item_state = "energy"

/obj/item/weapon/gun_attachment/base/laser
	gun_type = CUSTOMIZABLE_ENERGY
	name = "Laser Energy Base"
	icon_state = "base_energy_laser"
	energy_type = list(/obj/item/ammo_casing/energy/lasergun)
	the_item_state = "laser"

/obj/item/weapon/gun_attachment/base/ion
	gun_type = CUSTOMIZABLE_ENERGY
	name = "Ioniser Energy Base"
	icon_state = "base_energy_ion"
	energy_type = list(/obj/item/ammo_casing/energy/ion)
	the_item_state = "ioncarbine"

/obj/item/weapon/gun_attachment/base/disable
	gun_type = CUSTOMIZABLE_ENERGY
	name = "Disabler Energy Base"
	icon_state = "base_energy_ion"
	energy_type = list(/obj/item/ammo_casing/energy/disabler)
	the_item_state = "disabler"

/obj/item/weapon/gun_attachment/base/bee
	gun_type = CUSTOMIZABLE_ENERGY
	name = "It's Hip To Shoot Bees Energy Base"
	icon_state = "base_energy_stun"
	energy_type = list(/obj/item/ammo_casing/energy/bee)

/obj/item/weapon/gun_attachment/base/xray
	gun_type = CUSTOMIZABLE_ENERGY
	name = "X-Ray Energy Base"
	icon_state = "base_energy_stun"
	energy_type = list(/obj/item/ammo_casing/energy/xray)
	the_item_state = "xray"

/obj/item/weapon/gun_attachment/base/tesla
	gun_type = CUSTOMIZABLE_ENERGY
	name = "Tesla Energy Base"
	icon_state = "base_energy_stun"
	energy_type = list(/obj/item/ammo_casing/energy/tesla_revolver)
	the_item_state = "tesla"