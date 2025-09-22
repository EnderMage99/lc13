// Component press with timing-based crafting minigame
/obj/machinery/resurgence_component_press
	name = "component press"
	desc = "A precision press for shaping ingots into mechanical components. Requires perfect timing."
	icon = '	'
	icon_state = "autolathe"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE // Operates on Core charge by default
	idle_power_usage = 50
	active_power_usage = 300

	var/pressing = FALSE
	var/charge_cost_to_start = 5 // Core charge to start when unpowered
	var/mob/living/carbon/human/current_operator
	var/press_stage = 0
	var/max_stages = 3

	// Timing minigame
	var/target_window_start = 0
	var/target_window_end = 0
	var/timing_success = 0
	var/timing_required = 3

	// Materials
	var/loaded_ingots = 0
	var/max_ingots = 3
	var/list/output_components = list()
	var/max_output = 10

	// Component tier based on performance
	var/perfect_timings = 0

/obj/machinery/resurgence_component_press/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Loaded ingots: [loaded_ingots]/[max_ingots]</span>"

	if(length(output_components))
		. += "<span class='notice'>Components ready for collection: [length(output_components)]</span>"
		. += "<span class='notice'>Alt-click to retrieve components.</span>"

	if(pressing)
		. += "<span class='warning'>Press operation in progress!</span>"

	if(use_power == NO_POWER_USE)
		. += "<span class='yellow'>Running on Core charge ([charge_cost_to_start] to start). Connect power for faster timing & bonuses!</span>"
	else
		. += "<span class='green'>Powered by generator - 25% faster timing, 30% chance for bonus components!</span>"

/obj/machinery/resurgence_component_press/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/resurgence_ingot))
		if(pressing)
			to_chat(user, "<span class='warning'>Cannot load ingots during operation!</span>")
			return

		if(loaded_ingots >= max_ingots)
			to_chat(user, "<span class='warning'>[src] is full!</span>")
			return

		var/obj/item/stack/resurgence_ingot/R = I
		var/to_load = min(R.amount, max_ingots - loaded_ingots)
		if(R.use(to_load))
			loaded_ingots += to_load
			to_chat(user, "<span class='notice'>You load [to_load] ingot\s into [src].</span>")
			playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		return

	return ..()

/obj/machinery/resurgence_component_press/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	if(pressing)
		if(current_operator == user)
			// Check if we're in the timing window
			check_timing()
		else
			to_chat(user, "<span class='warning'>[current_operator] is operating the press!</span>")
		return

	if(loaded_ingots <= 0)
		to_chat(user, "<span class='warning'>Load ingots first!</span>")
		return

	if(!istype(user, /mob/living/carbon/human))
		return

	var/mob/living/carbon/human/H = user
	if(!istype(H.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>Only resurgence machines can operate this press!</span>")
		return

	start_pressing(H)

/obj/machinery/resurgence_component_press/proc/start_pressing(mob/living/carbon/human/user)
	if(!user || !user.client || pressing)
		return

	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(use_power == NO_POWER_USE)
		if(!istype(core) || !core.can_use_charge(charge_cost_to_start))
			to_chat(user, "<span class='warning'>You need at least [charge_cost_to_start] charge to operate the unpowered press!</span>")
			return
		core.use_charge(charge_cost_to_start)
		to_chat(user, "<span class='notice'>You use [charge_cost_to_start] charge to power the press.</span>")
	pressing = TRUE
	current_operator = user
	press_stage = 0
	timing_success = 0
	perfect_timings = 0
	if(use_power != NO_POWER_USE)
		use_power = ACTIVE_POWER_USE
	icon_state = "autolathe_n"

	to_chat(user, "<span class='notice'>You start the component press. Watch for the timing indicators!</span>")
	to_chat(user, "<span class='warning'>Click when the indicator shows GREEN for perfect timing!</span>")
	playsound(src, 'sound/machines/clockcult/integration_cog_install.ogg', 50, TRUE)

	start_timing_round()

/obj/machinery/resurgence_component_press/proc/start_timing_round()
	if(!current_operator || !pressing || get_dist(current_operator, src) > 1)
		cancel_pressing()
		return

	press_stage++

	// Set random timing window (3-5 seconds from now)
	var/delay = rand(30, 50)
	// Shorter delays with generator power
	if(use_power != NO_POWER_USE)
		delay = round(delay * 0.75)
	target_window_start = world.time + delay
	target_window_end = world.time + delay + 10 // 1 second window

	to_chat(current_operator, "<span class='notice'>Stage [press_stage]/[max_stages]: Preparing press...</span>")

	// Show countdown hints
	addtimer(CALLBACK(src, PROC_REF(show_warning)), delay - 10)
	addtimer(CALLBACK(src, PROC_REF(show_ready)), delay)
	addtimer(CALLBACK(src, PROC_REF(timing_failed)), delay + 15)

/obj/machinery/resurgence_component_press/proc/show_warning()
	if(!current_operator || !pressing)
		return
	to_chat(current_operator, "<span class='yellow'>Get ready...</span>")
	playsound(src, 'sound/machines/clockcult/ark_damage.ogg', 30, TRUE)

/obj/machinery/resurgence_component_press/proc/show_ready()
	if(!current_operator || !pressing)
		return
	to_chat(current_operator, "<span class='green'><b>PRESS NOW!</b></span>")
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

/obj/machinery/resurgence_component_press/proc/check_timing()
	if(!pressing || !current_operator)
		return

	var/current_time = world.time

	if(current_time >= target_window_start && current_time <= target_window_end)
		// Perfect timing!
		timing_success++
		perfect_timings++
		to_chat(current_operator, "<span class='green'>Perfect timing! ([timing_success]/[timing_required])</span>")
		playsound(src, 'sound/machines/chime.ogg', 50, TRUE)
	else if(current_time < target_window_start)
		// Too early
		to_chat(current_operator, "<span class='warning'>Too early! Timing reset.</span>")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
		timing_success = max(0, timing_success - 1)
	else
		// Too late
		to_chat(current_operator, "<span class='warning'>Too late! Timing reset.</span>")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
		timing_success = max(0, timing_success - 1)

	// Reset window to prevent spam
	target_window_start = 0
	target_window_end = 0

	if(timing_success >= timing_required)
		complete_stage()
	else if(press_stage < max_stages)
		addtimer(CALLBACK(src, PROC_REF(start_timing_round)), 20)

/obj/machinery/resurgence_component_press/proc/timing_failed()
	if(!pressing || target_window_start == 0)
		return

	if(world.time > target_window_end && current_operator)
		to_chat(current_operator, "<span class='warning'>Missed timing window! Timing reset.</span>")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
		timing_success = max(0, timing_success - 1)

		target_window_start = 0
		target_window_end = 0

		if(press_stage < max_stages)
			addtimer(CALLBACK(src, PROC_REF(start_timing_round)), 20)

/obj/machinery/resurgence_component_press/proc/complete_stage()
	if(!current_operator)
		return

	to_chat(current_operator, "<span class='notice'>Stage [press_stage] complete!</span>")

	if(press_stage >= max_stages)
		finish_pressing()
	else
		timing_success = 0
		addtimer(CALLBACK(src, PROC_REF(start_timing_round)), 20)

/obj/machinery/resurgence_component_press/proc/finish_pressing()
	if(!current_operator || loaded_ingots <= 0)
		return

	// Determine component quality based on performance
	var/component_type
	if(perfect_timings >= max_stages * timing_required)
		component_type = /obj/item/resurgence_material/component/superior
		to_chat(current_operator, "<span class='green'>Flawless execution! Superior component created!</span>")
	else if(perfect_timings >= (max_stages * timing_required) / 2)
		component_type = /obj/item/resurgence_material/component/advanced
		to_chat(current_operator, "<span class='notice'>Good performance! Advanced component created.</span>")
	else
		component_type = /obj/item/resurgence_material/component
		to_chat(current_operator, "<span class='notice'>Basic component created.</span>")

	var/components_made = min(loaded_ingots, 3)
	// Bonus component with generator power
	if(use_power != NO_POWER_USE && prob(30))
		components_made++
		to_chat(current_operator, "<span class='green'>Generator power provides bonus component!</span>")

	for(var/i in 1 to components_made)
		if(length(output_components) < max_output)
			output_components += component_type

	loaded_ingots -= min(loaded_ingots, 3) // Still only consume original amount

	to_chat(current_operator, "<span class='greentext'>Pressing complete! Created [components_made] component\s.</span>")
	playsound(src, 'sound/machines/chime.ogg', 50, TRUE)

	// Faith bonus for skilled operation
	var/obj/item/organ/resurgence_core/core = current_operator.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		var/faith_gain = perfect_timings >= max_stages * timing_required ? 5 : 2
		core.adjust_faith(faith_gain)
		to_chat(current_operator, "<span class='notice'>Your faith increases from precise work. (+[faith_gain])</span>")

	reset_pressing()

/obj/machinery/resurgence_component_press/proc/cancel_pressing()
	if(current_operator)
		to_chat(current_operator, "<span class='warning'>Pressing cancelled.</span>")
	reset_pressing()

/obj/machinery/resurgence_component_press/proc/reset_pressing()
	pressing = FALSE
	current_operator = null
	press_stage = 0
	timing_success = 0
	perfect_timings = 0
	target_window_start = 0
	target_window_end = 0
	if(use_power != NO_POWER_USE)
		use_power = IDLE_POWER_USE
	icon_state = "autolathe"

/obj/machinery/resurgence_component_press/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	if(pressing)
		to_chat(user, "<span class='warning'>Cannot retrieve components during operation!</span>")
		return

	if(!length(output_components))
		to_chat(user, "<span class='warning'>No components to retrieve!</span>")
		return

	var/component_type = output_components[1]
	output_components.Cut(1, 2)

	var/obj/item/resurgence_material/component/C = new component_type(get_turf(user))

	to_chat(user, "<span class='notice'>You retrieve [C] from [src]. ([length(output_components)] remaining)</span>")
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)
