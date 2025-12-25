// Crafting bench for resurgence machines
/obj/machinery/resurgence_crafting_bench
	name = "resurgence crafting bench"
	desc = "A workbench where machines can craft tools and equipment from processed materials."
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "tinkerers_daemon"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE // Doesn't require power - uses Core charge for crafting

	var/busy = FALSE
	var/list/available_recipes = list()

/obj/machinery/resurgence_crafting_bench/Initialize()
	. = ..()
	load_recipes()

/obj/machinery/resurgence_crafting_bench/proc/load_recipes()
	available_recipes = list(
		"Basic Tool Set" = list(
			"result" = /obj/item/storage/toolbox/resurgence,
			"requirements" = list(
				/obj/item/resurgence_material/component = 2,
				/obj/item/stack/resurgence_ingot = 3
			),
			"charge_cost" = 10,
			"time" = 50,
			"description" = "A set of makeshift tools for basic repairs and construction."
		),
		"Repair Kit" = list(
			"result" = /obj/item/resurgence_repair_kit,
			"requirements" = list(
				/obj/item/resurgence_material/component = 1,
				/obj/item/stack/resurgence_ingot = 2
			),
			"charge_cost" = 15,
			"time" = 30,
			"description" = "A kit for repairing mechanical damage."
		),
		"Energy Cell" = list(
			"result" = /obj/item/stock_parts/cell/resurgence,
			"requirements" = list(
				/obj/item/resurgence_material/component/advanced = 1,
				/obj/item/resurgence_material/sorted/electronic = 2
			),
			"charge_cost" = 20,
			"time" = 40,
			"description" = "A power cell infused with mechanical core energy."
		),
		"Charge Booster" = list(
			"result" = /obj/item/resurgence_charge_booster,
			"requirements" = list(
				/obj/item/resurgence_material/component/advanced = 2,
				/obj/item/stock_parts/cell/resurgence = 1
			),
			"charge_cost" = 25,
			"time" = 60,
			"description" = "Temporarily increases charge regeneration rate."
		),
		"Faith Amplifier" = list(
			"result" = /obj/item/resurgence_faith_amplifier,
			"requirements" = list(
				/obj/item/resurgence_material/component/superior = 1,
				/obj/item/resurgence_material/blessed = 1
			),
			"charge_cost" = 30,
			"faith_cost" = 20,
			"time" = 80,
			"description" = "A device that amplifies faith gain from activities."
		),
		"Mechanical Limb Upgrade" = list(
			"result" = /obj/item/resurgence_limb_upgrade,
			"requirements" = list(
				/obj/item/resurgence_material/component/superior = 2,
				/obj/item/stack/resurgence_ingot = 5
			),
			"charge_cost" = 40,
			"time" = 100,
			"description" = "Permanently upgrades a mechanical limb for better performance."
		)
	)

/obj/machinery/resurgence_crafting_bench/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Use to view available recipes and craft items.</span>"

/obj/machinery/resurgence_crafting_bench/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	if(busy)
		to_chat(user, "<span class='warning'>[src] is currently in use!</span>")
		return

	if(!istype(user, /mob/living/carbon/human))
		return

	var/mob/living/carbon/human/H = user
	if(!istype(H.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>Only resurgence machines can use this workbench!</span>")
		return

	show_recipe_menu(H)

/obj/machinery/resurgence_crafting_bench/proc/show_recipe_menu(mob/living/carbon/human/user)
	if(!user || !user.client)
		return

	var/list/recipe_choices = list()
	for(var/recipe_name in available_recipes)
		var/list/recipe = available_recipes[recipe_name]
		var/desc = recipe["description"]
		recipe_choices["[recipe_name] - [desc]"] = recipe_name

	recipe_choices["Cancel"] = null

	var/choice = input(user, "Select a recipe to craft:", "Crafting Bench") as null|anything in recipe_choices

	if(!choice || recipe_choices[choice] == null || get_dist(user, src) > 1 || busy)
		return

	var/recipe_name = recipe_choices[choice]
	var/list/recipe = available_recipes[recipe_name]

	// Show requirements
	var/requirements_text = "Requirements:\n"
	for(var/req_type in recipe["requirements"])
		var/req_amount = recipe["requirements"][req_type]
		var/obj/item/I = req_type
		requirements_text += "- [initial(I.name)] x[req_amount]\n"

	if(recipe["charge_cost"])
		requirements_text += "- Charge: [recipe["charge_cost"]]\n"
	if(recipe["faith_cost"])
		requirements_text += "- Faith: [recipe["faith_cost"]]\n"

	requirements_text += "\nCrafting time: [recipe["time"] / 10] seconds"

	var/confirm = alert(user, requirements_text, "Craft [recipe_name]?", "Craft", "Cancel")
	if(confirm != "Craft" || get_dist(user, src) > 1 || busy)
		return

	attempt_craft(user, recipe_name)

/obj/machinery/resurgence_crafting_bench/proc/attempt_craft(mob/living/carbon/human/user, recipe_name)
	if(!user || busy)
		return

	var/list/recipe = available_recipes[recipe_name]
	if(!recipe)
		return

	// Check resources
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	if(recipe["charge_cost"] && !core.can_use_charge(recipe["charge_cost"]))
		to_chat(user, "<span class='warning'>Insufficient charge! Need [recipe["charge_cost"]].</span>")
		return

	if(recipe["faith_cost"] && core.faith < recipe["faith_cost"])
		to_chat(user, "<span class='warning'>Insufficient faith! Need [recipe["faith_cost"]].</span>")
		return

	// Check materials
	var/list/found_materials = list()
	for(var/req_type in recipe["requirements"])
		var/req_amount = recipe["requirements"][req_type]
		var/found_amount = 0

		for(var/obj/item/I in user.loc)
			if(istype(I, req_type))
				if(istype(I, /obj/item/stack))
					var/obj/item/stack/S = I
					found_amount += S.amount
					found_materials[I] = min(S.amount, req_amount - (found_amount - S.amount))
				else
					found_amount++
					found_materials[I] = 1

				if(found_amount >= req_amount)
					break

		if(found_amount < req_amount)
			var/obj/item/I = req_type
			to_chat(user, "<span class='warning'>Missing materials! Need [req_amount] [initial(I.name)], found [found_amount].</span>")
			return

	// Start crafting
	busy = TRUE

	// Consume resources
	if(recipe["charge_cost"])
		core.use_charge(recipe["charge_cost"])
	if(recipe["faith_cost"])
		core.adjust_faith(-recipe["faith_cost"])

	// Consume materials
	for(var/obj/item/I in found_materials)
		var/amount = found_materials[I]
		if(istype(I, /obj/item/stack))
			var/obj/item/stack/S = I
			S.use(amount)
		else
			qdel(I)

	user.visible_message("<span class='notice'>[user] begins crafting at [src].</span>",
		"<span class='notice'>You begin crafting [recipe_name]...</span>")

	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)

	if(do_after(user, recipe["time"], target = src))
		complete_craft(user, recipe_name)
	else
		to_chat(user, "<span class='warning'>Crafting interrupted!</span>")
		busy = FALSE

/obj/machinery/resurgence_crafting_bench/proc/complete_craft(mob/living/carbon/human/user, recipe_name)
	if(!user)
		busy = FALSE
		return

	var/list/recipe = available_recipes[recipe_name]
	if(!recipe)
		busy = FALSE
		return

	var/result_type = recipe["result"]
	var/obj/item/result = new result_type(get_turf(src))

	user.visible_message("<span class='notice'>[user] finishes crafting [result].</span>",
		"<span class='green'>You successfully craft [result]!</span>")

	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)

	// Faith bonus for crafting
	var/obj/item/organ/resurgence_core/core = user.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.adjust_faith(2)
		to_chat(user, "<span class='notice'>Your faith increases from productive work. (+2)</span>")

	busy = FALSE

// Crafted items
/obj/item/storage/toolbox/resurgence
	name = "makeshift toolbox"
	desc = "A roughly assembled toolbox containing basic tools."

/obj/item/storage/toolbox/resurgence/PopulateContents()
	new /obj/item/wrench/makeshift(src)
	new /obj/item/screwdriver/makeshift(src)
	new /obj/item/weldingtool/makeshift(src)
	new /obj/item/crowbar(src)
	new /obj/item/wirecutters(src)

/obj/item/wrench/makeshift
	name = "makeshift wrench"
	desc = "A basic wrench formed from scrap."
	force = 3

/obj/item/screwdriver/makeshift
	name = "makeshift screwdriver"
	desc = "A simple screwdriver made from spare parts."
	force = 2

/obj/item/weldingtool/makeshift
	name = "makeshift welder"
	desc = "A crude welding tool assembled from scrap."
	max_fuel = 10

/obj/item/resurgence_repair_kit
	name = "mechanical repair kit"
	desc = "A kit containing materials for self-repair."
	icon = 'icons/obj/storage.dmi'
	icon_state = "toolbox_blue"
	w_class = WEIGHT_CLASS_SMALL
	var/charges = 3

/obj/item/resurgence_repair_kit/attack(mob/living/carbon/human/M, mob/living/user)
	if(!istype(M.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>This only works on resurgence machines!</span>")
		return

	if(M.health >= M.maxHealth)
		to_chat(user, "<span class='notice'>[M] is already in perfect condition!</span>")
		return

	if(charges <= 0)
		to_chat(user, "<span class='warning'>[src] is depleted!</span>")
		return

	user.visible_message("<span class='notice'>[user] begins repairing [M] with [src].</span>",
		"<span class='notice'>You begin repairing [M]...</span>")

	if(do_after(user, 30, target = M))
		M.adjustBruteLoss(-30)
		M.adjustFireLoss(-30)
		charges--
		playsound(src, 'sound/items/welder.ogg', 50, TRUE)
		user.visible_message("<span class='notice'>[user] repairs some of [M]'s damage.</span>",
			"<span class='notice'>You repair some of [M]'s damage. [charges] charge\s remaining.</span>")

/obj/item/resurgence_repair_kit/examine(mob/user)
	. = ..()
	. += "<span class='notice'>It has [charges] charge\s remaining.</span>"

/obj/item/stock_parts/cell/resurgence
	name = "resurgence power cell"
	desc = "A power cell charged with mechanical core energy."
	maxcharge = 2000
	chargerate = 200

/obj/item/resurgence_charge_booster
	name = "charge booster"
	desc = "Temporarily increases your core's charge regeneration rate."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "bottle_gold"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/resurgence_charge_booster/attack(mob/living/carbon/human/M, mob/living/user)
	if(M != user)
		to_chat(user, "<span class='warning'>This can only be used on yourself!</span>")
		return

	if(!istype(M.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>This only works on resurgence machines!</span>")
		return

	var/obj/item/organ/resurgence_core/core = M.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	to_chat(user, "<span class='notice'>You activate [src], boosting your charge regeneration!</span>")
	core.charge_regen_rate *= 3
	playsound(src, 'sound/machines/synth_yes.ogg', 50, TRUE)

	addtimer(CALLBACK(src, PROC_REF(end_boost), core), 600) // 60 seconds
	qdel(src)

/obj/item/resurgence_charge_booster/proc/end_boost(obj/item/organ/resurgence_core/core)
	if(!core)
		return
	core.charge_regen_rate = initial(core.charge_regen_rate)
	if(core.owner)
		to_chat(core.owner, "<span class='notice'>The charge boost wears off.</span>")

/obj/item/resurgence_faith_amplifier
	name = "faith amplifier"
	desc = "A device that amplifies faith gained from communal activities."
	icon = 'icons/obj/device.dmi'
	icon_state = "signaler"
	w_class = WEIGHT_CLASS_SMALL
	var/active = FALSE
	var/mob/living/carbon/human/linked_user

/obj/item/resurgence_faith_amplifier/attack_self(mob/user)
	if(!istype(user, /mob/living/carbon/human))
		return

	var/mob/living/carbon/human/H = user
	if(!istype(H.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>This device only works with resurgence machines!</span>")
		return

	if(active)
		deactivate()
	else
		activate(H)

/obj/item/resurgence_faith_amplifier/proc/activate(mob/living/carbon/human/H)
	active = TRUE
	linked_user = H
	to_chat(H, "<span class='notice'>Faith amplifier activated. Faith gains increased by 50%!</span>")
	playsound(src, 'sound/machines/synth_yes.ogg', 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(deactivate)), 1200) // 2 minutes

/obj/item/resurgence_faith_amplifier/proc/deactivate()
	active = FALSE
	if(linked_user)
		to_chat(linked_user, "<span class='notice'>Faith amplifier deactivated.</span>")
	linked_user = null
	playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE)

/obj/item/resurgence_limb_upgrade
	name = "limb upgrade kit"
	desc = "Permanently upgrades a mechanical limb for improved performance."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "arm_cyber"
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/resurgence_limb_upgrade/attack(mob/living/carbon/human/M, mob/living/user)
	if(!istype(M.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>This only works on resurgence machines!</span>")
		return

	var/list/valid_limbs = list()
	for(var/obj/item/bodypart/BP in M.bodyparts)
		if(!(BP.status & BODYPART_ROBOTIC))
			continue
		if(BP.brute_reduction >= 10) // Already upgraded
			continue
		valid_limbs["[BP.name]"] = BP

	if(!length(valid_limbs))
		to_chat(user, "<span class='warning'>[M] has no limbs that can be upgraded!</span>")
		return

	var/choice = input(user, "Select a limb to upgrade:", "Limb Upgrade") as null|anything in valid_limbs

	if(!choice || get_dist(user, M) > 1)
		return

	var/obj/item/bodypart/BP = valid_limbs[choice]

	user.visible_message("<span class='notice'>[user] begins upgrading [M]'s [BP.name].</span>",
		"<span class='notice'>You begin upgrading [M]'s [BP.name]...</span>")

	if(do_after(user, 50, target = M))
		BP.brute_reduction += 5
		BP.burn_reduction += 5
		to_chat(M, "<span class='green'>Your [BP.name] has been upgraded! It now provides better damage resistance.</span>")
		playsound(src, 'sound/items/welder.ogg', 50, TRUE)
		qdel(src)
