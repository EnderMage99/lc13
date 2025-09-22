// Scrap sorting station with manual minigame
/obj/machinery/resurgence_scrap_sorter
	name = "scrap sorting station"
	desc = "A workstation for manually sorting scrap into different material types. Requires skill and patience."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "circuit_imprinter"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE // Operates on Core charge by default
	idle_power_usage = 50
	active_power_usage = 200

	var/sorting_in_progress = FALSE
	var/charge_cost_per_sort = 5 // Core charge cost when not powered
	var/mob/living/carbon/human/current_user
	var/list/unsorted_scrap = list()
	var/sorting_difficulty = 3 // Number of correct sorts needed
	var/sorting_progress = 0
	var/sorting_mistakes = 0
	var/max_mistakes = 2

	// Output storage
	var/metal_output = 0
	var/electronic_output = 0
	var/plastic_output = 0
	var/max_output = 10

/obj/machinery/resurgence_scrap_sorter/examine(mob/user)
	. = ..()
	if(length(unsorted_scrap))
		. += "<span class='notice'>Contains [length(unsorted_scrap)] piece\s of unsorted scrap.</span>"
	if(metal_output || electronic_output || plastic_output)
		. += "<span class='notice'>Sorted materials ready:</span>"
		if(metal_output)
			. += "<span class='notice'>- Metal: [metal_output]</span>"
		if(electronic_output)
			. += "<span class='notice'>- Electronics: [electronic_output]</span>"
		if(plastic_output)
			. += "<span class='notice'>- Plastics: [plastic_output]</span>"
		. += "<span class='notice'>Alt-click to retrieve sorted materials.</span>"
	if(use_power == NO_POWER_USE)
		. += "<span class='yellow'>Running on Core charge ([charge_cost_per_sort] per sort). Connect power for bonuses!</span>"
	else
		. += "<span class='green'>Powered by generator - 20% bonus yield, no charge cost!</span>"

/obj/machinery/resurgence_scrap_sorter/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_material/scrap))
		if(length(unsorted_scrap) >= 20)
			to_chat(user, "<span class='warning'>[src] is full! Process the current scrap first.</span>")
			return

		var/obj/item/resurgence_material/scrap/S = I
		unsorted_scrap += S.scrap_quality
		to_chat(user, "<span class='notice'>You load [S] into [src].</span>")
		qdel(S)
		return

	return ..()

/obj/machinery/resurgence_scrap_sorter/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	if(sorting_in_progress)
		to_chat(user, "<span class='warning'>Someone is already sorting scrap!</span>")
		return

	if(!length(unsorted_scrap))
		to_chat(user, "<span class='warning'>No scrap to sort! Load some raw scrap first.</span>")
		return

	if(!istype(user, /mob/living/carbon/human))
		return

	var/mob/living/carbon/human/H = user
	if(!istype(H.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>Only resurgence machines can operate this station!</span>")
		return

	start_sorting_minigame(H)

/obj/machinery/resurgence_scrap_sorter/proc/start_sorting_minigame(mob/living/carbon/human/user)
	if(!user || !user.client)
		return

	// Check if we need to use Core charge (when not powered)
	if(use_power == NO_POWER_USE)
		var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
		if(!istype(core) || !core.can_use_charge(charge_cost_per_sort))
			to_chat(user, "<span class='warning'>You need at least [charge_cost_per_sort] charge to operate the unpowered sorter!</span>")
			return
		core.use_charge(charge_cost_per_sort)
		to_chat(user, "<span class='notice'>You use [charge_cost_per_sort] charge to power the sorter.</span>")

	sorting_in_progress = TRUE
	current_user = user
	sorting_progress = 0
	sorting_mistakes = 0
	if(use_power != NO_POWER_USE)
		use_power = ACTIVE_POWER_USE

	to_chat(user, "<span class='notice'>You begin sorting the scrap. Follow the prompts carefully!</span>")
	to_chat(user, "<span class='warning'>Make less than [max_mistakes + 1] mistakes to succeed.</span>")

	addtimer(CALLBACK(src, PROC_REF(sorting_round)), 20)

/obj/machinery/resurgence_scrap_sorter/proc/sorting_round()
	if(!current_user || !current_user.client || get_dist(current_user, src) > 1)
		cancel_sorting()
		return

	if(sorting_progress >= sorting_difficulty)
		complete_sorting()
		return

	// Generate random sorting challenge
	var/list/materials = list("metal", "electronics", "plastic", "waste")
	var/correct_answer = pick(materials)
	var/scrap_desc = ""

	switch(correct_answer)
		if("metal")
			scrap_desc = "a piece of corroded steel plating"
		if("electronics")
			scrap_desc = "a burnt circuit board"
		if("plastic")
			scrap_desc = "a cracked polymer casing"
		if("waste")
			scrap_desc = "a bundle of mixed debris"

	to_chat(current_user, "<span class='notice'>You pick up <b>[scrap_desc]</b>.</span>")
	to_chat(current_user, "<span class='notice'>Sort it into: [materials.Join(" / ")]</span>")

	// Get user input
	var/choice = input(current_user, "Where does this item belong?", "Scrap Sorting") as null|anything in materials

	if(!choice || !current_user || get_dist(current_user, src) > 1)
		cancel_sorting()
		return

	if(choice == correct_answer)
		sorting_progress++
		to_chat(current_user, "<span class='green'>Correct! ([sorting_progress]/[sorting_difficulty])</span>")
		playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	else
		sorting_mistakes++
		to_chat(current_user, "<span class='warning'>Wrong! That was [correct_answer]. ([sorting_mistakes]/[max_mistakes] mistakes)</span>")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)

		if(sorting_mistakes > max_mistakes)
			to_chat(current_user, "<span class='boldwarning'>Too many mistakes! The scrap is ruined.</span>")
			failed_sorting()
			return

	// Continue minigame
	addtimer(CALLBACK(src, PROC_REF(sorting_round)), 15)

/obj/machinery/resurgence_scrap_sorter/proc/complete_sorting()
	if(!current_user)
		return

	var/total_quality = 0
	var/scrap_count = min(5, length(unsorted_scrap))

	for(var/i in 1 to scrap_count)
		total_quality += unsorted_scrap[1]
		unsorted_scrap.Cut(1, 2)

	// Calculate output based on quality
	var/metal_gain = round(total_quality * 0.4)
	var/electronic_gain = round(total_quality * 0.3)
	var/plastic_gain = round(total_quality * 0.3)

	// Bonus output if powered by generator
	if(use_power != NO_POWER_USE)
		metal_gain = round(metal_gain * 1.2)
		electronic_gain = round(electronic_gain * 1.2)
		plastic_gain = round(plastic_gain * 1.2)
		to_chat(current_user, "<span class='green'>Generator power provides 20% bonus yield!</span>")

	metal_output = min(metal_output + metal_gain, max_output)
	electronic_output = min(electronic_output + electronic_gain, max_output)
	plastic_output = min(plastic_output + plastic_gain, max_output)

	to_chat(current_user, "<span class='greentext'>Sorting complete! Gained [metal_gain] metal, [electronic_gain] electronics, [plastic_gain] plastic.</span>")
	playsound(src, 'sound/machines/chime.ogg', 50, TRUE)

	// Grant small faith bonus for completing task
	var/obj/item/organ/resurgence_core/core = current_user.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.adjust_faith(2)
		to_chat(current_user, "<span class='notice'>Your faith increases from productive work. (+2)</span>")

	reset_sorting()

/obj/machinery/resurgence_scrap_sorter/proc/failed_sorting()
	var/scrap_lost = min(3, length(unsorted_scrap))
	for(var/i in 1 to scrap_lost)
		unsorted_scrap.Cut(1, 2)

	reset_sorting()

/obj/machinery/resurgence_scrap_sorter/proc/cancel_sorting()
	to_chat(current_user, "<span class='warning'>Sorting cancelled.</span>")
	reset_sorting()

/obj/machinery/resurgence_scrap_sorter/proc/reset_sorting()
	sorting_in_progress = FALSE
	current_user = null
	sorting_progress = 0
	sorting_mistakes = 0
	if(use_power != NO_POWER_USE)
		use_power = IDLE_POWER_USE

/obj/machinery/resurgence_scrap_sorter/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	if(!metal_output && !electronic_output && !plastic_output)
		to_chat(user, "<span class='warning'>No sorted materials to retrieve!</span>")
		return

	if(metal_output)
		new /obj/item/resurgence_material/sorted/metal(get_turf(user))
		metal_output--
	if(electronic_output)
		new /obj/item/resurgence_material/sorted/electronic(get_turf(user))
		electronic_output--
	if(plastic_output)
		new /obj/item/resurgence_material/sorted/plastic(get_turf(user))
		plastic_output--

	to_chat(user, "<span class='notice'>You retrieve the sorted materials.</span>")
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)