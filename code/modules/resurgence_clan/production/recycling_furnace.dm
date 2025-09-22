// Recycling furnace with temperature management minigame
/obj/machinery/resurgence_furnace
	name = "recycling furnace"
	desc = "A high-temperature furnace for melting sorted materials into ingots. Requires careful temperature control."
	icon = 'icons/obj/atmospherics/components/unary_devices.dmi'
	icon_state = "heater_on"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE // Operates on Core charge by default
	idle_power_usage = 100
	active_power_usage = 500

	var/active = FALSE
	var/charge_cost_to_start = 10 // Core charge to start when unpowered
	var/charge_cost_per_cycle = 1 // Ongoing charge cost when unpowered
	var/current_temp = 293 // Room temperature in Kelvin
	var/target_temp = 1500 // Optimal melting temperature
	var/temp_tolerance = 100 // How close to target is acceptable
	var/heating_rate = 50 // Temperature change per process
	var/cooling_rate = 20 // Natural cooling when off

	var/mob/living/carbon/human/operator
	var/operation_time = 0
	var/required_time = 100 // 10 seconds of proper temperature

	// Input/output
	var/list/loaded_materials = list()
	var/max_materials = 5
	var/ingot_output = 0
	var/max_output = 10

	// Temperature control UI
	var/heating_power = 0 // 0-3 heating levels

/obj/machinery/resurgence_furnace/Initialize()
	. = ..()
	START_PROCESSING(SSmachines, src)

/obj/machinery/resurgence_furnace/Destroy()
	STOP_PROCESSING(SSmachines, src)
	return ..()

/obj/machinery/resurgence_furnace/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Current temperature: [round(current_temp)]K (Target: [target_temp]K ±[temp_tolerance])</span>"

	if(active)
		var/temp_status = ""
		if(abs(current_temp - target_temp) <= temp_tolerance)
			temp_status = "<span class='green'>OPTIMAL</span>"
		else if(current_temp < target_temp - temp_tolerance)
			temp_status = "<span class='yellow'>TOO COLD</span>"
		else
			temp_status = "<span class='red'>TOO HOT</span>"
		. += "Temperature status: [temp_status]"
		. += "<span class='notice'>Heating level: [heating_power]/3</span>"

	if(length(loaded_materials))
		. += "<span class='notice'>Loaded materials: [length(loaded_materials)]/[max_materials]</span>"
	if(ingot_output)
		. += "<span class='notice'>Ingots ready: [ingot_output]/[max_output]</span>"
		. += "<span class='notice'>Alt-click to retrieve ingots.</span>"

	if(use_power == NO_POWER_USE)
		. += "<span class='yellow'>Running on Core charge ([charge_cost_to_start] to start, [charge_cost_per_cycle]/cycle). Connect power for faster heating & bonuses!</span>"
	else
		. += "<span class='green'>Powered by generator - 50% faster heating, 25% bonus yield, no charge cost!</span>"

/obj/machinery/resurgence_furnace/process()
	// Consume charge if unpowered
	if(active && use_power == NO_POWER_USE && operator)
		var/obj/item/organ/resurgence_core/core = operator.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			if(!core.can_use_charge(charge_cost_per_cycle))
				to_chat(operator, "<span class='warning'>Out of charge! Furnace shutting down.</span>")
				stop_furnace(operator)
				return
			if(prob(10)) // Only consume charge periodically
				core.use_charge(charge_cost_per_cycle)

	// Temperature physics
	var/temp_rate_modifier = use_power != NO_POWER_USE ? 1.5 : 1 // Faster heating with power
	if(active && heating_power > 0)
		current_temp = min(current_temp + (heating_rate * heating_power * temp_rate_modifier), 2000)
		if(prob(heating_power * 10))
			do_sparks(1, TRUE, src)
	else
		current_temp = max(current_temp - cooling_rate, 293)

	// Process materials if temperature is right
	if(active && operator && length(loaded_materials))
		if(abs(current_temp - target_temp) <= temp_tolerance)
			operation_time++
			if(operation_time % 10 == 0)
				to_chat(operator, "<span class='notice'>Melting progress: [operation_time]%</span>")

			if(operation_time >= required_time)
				complete_melting()
		else
			if(operation_time > 0 && operation_time % 20 == 0)
				to_chat(operator, "<span class='warning'>Temperature out of range! Maintain [target_temp]K ±[temp_tolerance]!</span>")

	// Update icon based on temperature
	if(current_temp > 500)
		icon_state = "heater_on"
	else
		icon_state = "heater"

/obj/machinery/resurgence_furnace/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_material/sorted))
		if(active)
			to_chat(user, "<span class='warning'>Cannot load materials while furnace is active!</span>")
			return

		if(length(loaded_materials) >= max_materials)
			to_chat(user, "<span class='warning'>[src] is full!</span>")
			return

		loaded_materials += I.type
		to_chat(user, "<span class='notice'>You load [I] into [src].</span>")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		qdel(I)
		return

	return ..()

/obj/machinery/resurgence_furnace/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	if(!istype(user, /mob/living/carbon/human))
		return

	var/mob/living/carbon/human/H = user
	if(!istype(H.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>Only resurgence machines can operate this furnace!</span>")
		return

	if(active)
		if(operator != H)
			to_chat(user, "<span class='warning'>[operator] is operating the furnace!</span>")
			return

		// Temperature control menu
		var/list/options = list(
			"Heating OFF" = 0,
			"Heating LOW (1/3)" = 1,
			"Heating MEDIUM (2/3)" = 2,
			"Heating HIGH (3/3)" = 3,
			"STOP FURNACE" = -1
		)

		var/choice = input(user, "Current temp: [round(current_temp)]K | Target: [target_temp]K", "Temperature Control") as null|anything in options

		if(!choice || get_dist(user, src) > 1)
			return

		if(options[choice] == -1)
			stop_furnace(H)
		else
			heating_power = options[choice]
			to_chat(user, "<span class='notice'>Heating set to level [heating_power].</span>")
			playsound(src, 'sound/machines/click.ogg', 30, TRUE)

	else
		if(!length(loaded_materials))
			to_chat(user, "<span class='warning'>Load sorted materials first!</span>")
			return

		start_furnace(H)

/obj/machinery/resurgence_furnace/proc/start_furnace(mob/living/carbon/human/user)
	if(!user || active)
		return

	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(use_power == NO_POWER_USE)
		if(!istype(core) || !core.can_use_charge(charge_cost_to_start))
			to_chat(user, "<span class='warning'>You need at least [charge_cost_to_start] charge to start the unpowered furnace!</span>")
			return
		core.use_charge(charge_cost_to_start)
		to_chat(user, "<span class='notice'>You use [charge_cost_to_start] charge to start the furnace.</span>")
	active = TRUE
	operator = user
	operation_time = 0
	heating_power = 1
	if(use_power != NO_POWER_USE)
		use_power = ACTIVE_POWER_USE

	to_chat(user, "<span class='notice'>You start the furnace. Monitor the temperature carefully!</span>")
	to_chat(user, "<span class='warning'>Maintain temperature at [target_temp]K ±[temp_tolerance]!</span>")
	playsound(src, 'sound/machines/clockcult/steam_whoosh.ogg', 50, TRUE)

/obj/machinery/resurgence_furnace/proc/stop_furnace(mob/living/carbon/human/user)
	if(!active)
		return

	active = FALSE
	operator = null
	operation_time = 0
	heating_power = 0
	if(use_power != NO_POWER_USE)
		use_power = IDLE_POWER_USE

	if(user)
		to_chat(user, "<span class='notice'>You shut down the furnace.</span>")

	playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE)

/obj/machinery/resurgence_furnace/proc/complete_melting()
	if(!operator || !length(loaded_materials))
		return

	// Calculate output
	var/ingots_produced = length(loaded_materials)

	// Bonus for perfect temperature control
	if(current_temp == target_temp)
		ingots_produced++
		to_chat(operator, "<span class='green'>Perfect temperature maintained! Bonus ingot produced!</span>")

	// Bonus for generator power
	if(use_power != NO_POWER_USE)
		ingots_produced = round(ingots_produced * 1.25)
		to_chat(operator, "<span class='green'>Generator power provides 25% bonus yield!</span>")

	ingot_output = min(ingot_output + ingots_produced, max_output)
	loaded_materials.Cut()

	to_chat(operator, "<span class='greentext'>Melting complete! Produced [ingots_produced] ingot\s.</span>")
	playsound(src, 'sound/machines/chime.ogg', 50, TRUE)

	// Faith bonus for skilled operation
	var/obj/item/organ/resurgence_core/core = operator.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.adjust_faith(3)
		to_chat(operator, "<span class='notice'>Your faith increases from skilled labor. (+3)</span>")

	stop_furnace(operator)

/obj/machinery/resurgence_furnace/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	if(active)
		to_chat(user, "<span class='warning'>Cannot retrieve ingots while furnace is active!</span>")
		return

	if(!ingot_output)
		to_chat(user, "<span class='warning'>No ingots to retrieve!</span>")
		return

	var/obj/item/stack/resurgence_ingot/I = new(get_turf(user))
	I.amount = min(ingot_output, I.max_amount)
	ingot_output -= I.amount

	to_chat(user, "<span class='notice'>You retrieve [I.amount] ingot\s from [src].</span>")
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)