// Generator system for Resurgence Clan - properly inherits from power machinery
/obj/machinery/power/resurgence_generator
	name = "resurgence generator"
	desc = "A makeshift generator that converts materials into power. Connect with cables to power nearby machinery."
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "relay"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE // Generates its own power

	var/active = FALSE
	var/fuel_amount = 0
	var/max_fuel = 100
	var/fuel_consumption_rate = 1 // per process
	var/power_generation = 5000 // watts per process when active
	var/last_power_generation = 0

/obj/machinery/power/resurgence_generator/Initialize()
	. = ..()
	connect_to_network()
	START_PROCESSING(SSmachines, src)

/obj/machinery/power/resurgence_generator/Destroy()
	STOP_PROCESSING(SSmachines, src)
	return ..()

/obj/machinery/power/resurgence_generator/should_have_node()
	return TRUE // Shows cable node sprite

/obj/machinery/power/resurgence_generator/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Fuel: [fuel_amount]/[max_fuel]</span>"
	if(active)
		. += "<span class='good'>Generator is running. Output: [last_power_generation]W</span>"
		if(powernet)
			. += "<span class='green'>Connected to power network.</span>"
		else
			. += "<span class='warning'>Not connected to power network! Lay cables under the generator.</span>"
	else
		. += "<span class='notice'>Generator is idle.</span>"
	. += "<span class='notice'>Use materials or energy cells as fuel.</span>"

/obj/machinery/power/resurgence_generator/process()
	if(!active)
		last_power_generation = 0
		return

	if(fuel_amount <= 0)
		active = FALSE
		last_power_generation = 0
		say("Fuel depleted. Generator shutting down.")
		playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE)
		update_icon()
		return

	// Consume fuel and generate power
	fuel_amount = max(0, fuel_amount - fuel_consumption_rate)

	// Add power to the network
	if(powernet)
		add_avail(power_generation)
		last_power_generation = power_generation
		// Update connected production machines to powered mode
		check_connected_machines()
	else
		last_power_generation = 0

	// Visual feedback
	if(prob(5))
		do_sparks(1, TRUE, src)

/obj/machinery/power/resurgence_generator/proc/check_connected_machines()
	// Find all resurgence machines on the same powernet
	if(!powernet)
		return

	for(var/obj/machinery/M in GLOB.machines)
		if(!istype(M, /obj/machinery/resurgence_scrap_sorter) && \
		   !istype(M, /obj/machinery/resurgence_furnace) && \
		   !istype(M, /obj/machinery/resurgence_component_press))
			continue

		// Check if on same powernet via cable under machine
		var/obj/structure/cable/C = locate() in M.loc
		if(C && C.powernet == powernet)
			// Switch to powered mode if currently unpowered
			if(M.use_power == NO_POWER_USE)
				M.use_power = IDLE_POWER_USE
				M.visible_message("<span class='notice'>[M] hums as it connects to generator power.</span>")

/obj/machinery/power/resurgence_generator/attackby(obj/item/I, mob/user, params)
	// Accept materials as fuel
	if(istype(I, /obj/item/stack/sheet) || istype(I, /obj/item/stack/resurgence_ingot) || istype(I, /obj/item/resurgence_material/sorted))
		if(fuel_amount >= max_fuel)
			to_chat(user, "<span class='warning'>[src] fuel tank is full!</span>")
			return

		var/fuel_value = 10
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			var/fuel_to_add = min(S.amount * fuel_value, max_fuel - fuel_amount)
			var/sheets_needed = ceil(fuel_to_add / fuel_value)
			if(S.use(sheets_needed))
				fuel_amount += sheets_needed * fuel_value
				to_chat(user, "<span class='notice'>You add [sheets_needed] material\s to [src]. Fuel: [fuel_amount]/[max_fuel]</span>")
		else
			fuel_amount = min(fuel_amount + fuel_value, max_fuel)
			to_chat(user, "<span class='notice'>You add [I] to [src]. Fuel: [fuel_amount]/[max_fuel]</span>")
			qdel(I)
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		return

	// Accept energy cells for direct fuel conversion
	if(istype(I, /obj/item/stock_parts/cell))
		var/obj/item/stock_parts/cell/C = I
		if(C.charge <= 0)
			to_chat(user, "<span class='warning'>[C] is depleted!</span>")
			return

		if(fuel_amount >= max_fuel)
			to_chat(user, "<span class='warning'>[src] fuel tank is full!</span>")
			return

		var/fuel_to_add = min(round(C.charge / 100), max_fuel - fuel_amount)
		C.use(fuel_to_add * 100)
		fuel_amount += fuel_to_add
		to_chat(user, "<span class='notice'>You transfer power from [C] to [src]. Fuel: [fuel_amount]/[max_fuel]</span>")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		return

	return ..()

/obj/machinery/power/resurgence_generator/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	if(active)
		active = FALSE
		to_chat(user, "<span class='notice'>You shut down [src].</span>")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
	else
		if(fuel_amount <= 0)
			to_chat(user, "<span class='warning'>[src] has no fuel!</span>")
			return

		if(!powernet)
			to_chat(user, "<span class='warning'>[src] is not connected to a power network! Place cables under it first.</span>")
			return

		active = TRUE
		to_chat(user, "<span class='notice'>You start up [src].</span>")
		playsound(src, 'sound/machines/clockcult/steam_whoosh.ogg', 50, TRUE)

	update_icon()

/obj/machinery/power/resurgence_generator/update_overlays()
	. = ..()
	if(active && last_power_generation > 0)
		var/level = clamp(round(last_power_generation/1000), 1, 11)
		. += mutable_appearance('icons/obj/power.dmi', "teg-op[level]")

// Power mode detector - automatically switches production machines between charge/power mode
/obj/machinery/resurgence_power_detector
	name = "power mode controller"
	desc = "Automatically configures production machines to use generator power when available."
	icon = 'icons/obj/power.dmi'
	icon_state = "smes"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 50

	var/checking_interval = 50 // Check every 5 seconds
	var/next_check = 0

/obj/machinery/resurgence_power_detector/Initialize()
	. = ..()
	START_PROCESSING(SSmachines, src)

/obj/machinery/resurgence_power_detector/Destroy()
	STOP_PROCESSING(SSmachines, src)
	return ..()

/obj/machinery/resurgence_power_detector/process()
	if(world.time < next_check)
		return

	next_check = world.time + checking_interval

	// Check if we have power
	var/has_power = FALSE
	if(use_power == NO_POWER_USE)
		has_power = FALSE
	else
		var/area/A = get_area(src)
		if(A && A.power_equip)
			has_power = TRUE

	// Update all production machines in area
	var/area/our_area = get_area(src)
	for(var/obj/machinery/M in our_area)
		if(!istype(M, /obj/machinery/resurgence_scrap_sorter) && \
		   !istype(M, /obj/machinery/resurgence_furnace) && \
		   !istype(M, /obj/machinery/resurgence_component_press))
			continue

		if(has_power && M.use_power == NO_POWER_USE)
			// Switch to powered mode
			M.use_power = IDLE_POWER_USE
			M.visible_message("<span class='notice'>[M] switches to generator power mode.</span>")
		else if(!has_power && M.use_power != NO_POWER_USE)
			// Switch to charge mode
			M.use_power = NO_POWER_USE
			M.visible_message("<span class='notice'>[M] switches to Core charge mode.</span>")

/obj/machinery/resurgence_power_detector/examine(mob/user)
	. = ..()
	var/area/A = get_area(src)
	if(A && A.power_equip)
		. += "<span class='green'>Area has power - machines using generator mode.</span>"
	else
		. += "<span class='yellow'>No area power - machines using Core charge mode.</span>"
