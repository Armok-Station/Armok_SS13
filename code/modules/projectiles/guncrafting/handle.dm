/obj/item/weapon/gun_attachment/handle
	name = "base"
	desc = "sfdahgfhgasfhgiahjfhajsdjkJA"
	var/burst_size = 1
	var/fire_delay = 0
	var/recoil = 1
	var/automatic = 0

/obj/item/weapon/gun_attachment/handle/on_attach(var/obj/item/weapon/gun/owner)
	..()
	owner.burst_size = burst_size
	owner.fire_delay = fire_delay
	owner.automatic = automatic
	owner.handle = src
	return

/obj/item/weapon/gun_attachment/handle/on_remove(var/obj/item/weapon/gun/owner)
	..()
	owner.burst_size = initial(owner.burst_size)
	owner.fire_delay = initial(owner.fire_delay)
	owner.automatic = initial(owner.automatic)
	owner.handle = null
	return