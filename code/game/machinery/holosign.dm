////////////////////HOLOSIGN///////////////////////////////////////
/obj/machinery/holosign
	name = "holosign"
	desc = "Small wall-mounted holographic projector"
	icon = 'icons/obj/holosign.dmi'
	icon_state = "sign_off"
	layer = 4
	anchored = TRUE
	var/lit = FALSE
	var/id = null
	var/on_icon = "sign_on"

/obj/machinery/holosign/proc/toggle()
	if(stat & (BROKEN|NOPOWER))
		return
	lit = !lit
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/holosign/update_icon_state()
	icon_state = lit ? on_icon : "sign_off"

/obj/machinery/holosign/power_change(forced = FALSE)
	if(!..())
		return
	if(stat & NOPOWER)
		lit = FALSE
	update_icon(UPDATE_ICON_STATE)

/obj/machinery/holosign/surgery
	name = "surgery holosign"
	desc = "Small wall-mounted holographic projector. This one reads SURGERY."
	on_icon = "surgery"
////////////////////SWITCH///////////////////////////////////////

/obj/machinery/holosign_switch
	name = "holosign switch"
	icon = 'icons/obj/engines_and_power/power.dmi'
	icon_state = "light0"
	desc = "A remote control switch for holosign."
	var/id = null
	var/active = 0
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 4

/obj/machinery/holosign_switch/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/holosign_switch/attackby(obj/item/W, mob/user as mob, params)
	if(istype(W, /obj/item/detective_scanner))
		return
	return ..()

/obj/machinery/holosign_switch/attack_hand(mob/user as mob)
	src.add_fingerprint(usr)
	if(stat & (NOPOWER|BROKEN))
		return
	add_fingerprint(user)

	use_power(5)

	active = !active
	update_icon(UPDATE_ICON_STATE)

	for(var/obj/machinery/holosign/M in GLOB.machines)
		if(M.id == src.id)
			spawn( 0 )
				M.toggle()
				return


/obj/machinery/holosign_switch/update_icon_state()
	icon_state = "light[active]"

