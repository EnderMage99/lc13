// =============================================
// Prostheti Innovations — Augment Design Minigame Terminal
// =============================================
// Interactable computer on the Design Floor. Players click to open the
// ProsthetiMinigame TGUI, which guides them through a multi-day augment
// design challenge with pentagon overlap scoring.
//
// MAP PLACEMENT: Place on the Design Floor of the Prostheti hub map.
// One terminal per map is recommended. Multiple players can share the
// same game instance.

/obj/machinery/computer/prostheti_minigame
	name = "Augment Design Terminal"
	desc = "A sleek terminal for the augment design challenge. Prostheti Innovations wants to see what you can do."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "rdconsole"
	anchored = TRUE
	density = TRUE
	/// The active minigame instance. Created on first interaction.
	var/datum/prostheti_minigame/game

/obj/machinery/computer/prostheti_minigame/Destroy()
	if(game)
		qdel(game)
	game = null
	return ..()

/obj/machinery/computer/prostheti_minigame/attack_hand(mob/living/carbon/user)
	if(!istype(user))
		return
	ui_interact(user)

/obj/machinery/computer/prostheti_minigame/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ProsthetiMinigame")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/prostheti_minigame/ui_data(mob/user)
	var/list/data = list()

	if(!game)
		data["no_game"] = TRUE
		return data

	data["no_game"] = FALSE
	data["phase"] = game.phase
	data["current_day"] = game.current_day
	data["total_days"] = game.total_days
	data["current_design_num"] = game.current_design_num
	data["designs_per_day"] = game.designs_per_day

	// Client info — hint text replaces wants/doesnt_want
	if(game.current_client)
		data["client_name"] = game.current_client["name"]
		data["client_desc"] = game.current_client["desc"]
		data["client_hint"] = game.current_client["hint"]
		data["client_rank_min"] = game.current_client["rank_min"]
		data["client_rank_max"] = game.current_client["rank_max"]
		data["client_required_tags"] = game.current_client["required_tags"]

	// All clients for today (for briefing display)
	var/list/day_clients_data = list()
	for(var/list/cl in game.day_clients)
		day_clients_data += list(list(
			"name" = cl["name"],
			"hint" = cl["hint"],
			"rank_min" = cl["rank_min"],
			"rank_max" = cl["rank_max"],
			"required_tags" = cl["required_tags"],
		))
	data["day_clients"] = day_clients_data

	// Market info
	data["trending_tags"] = game.trending_tags
	data["oversaturated_tags"] = game.oversaturated_tags
	data["tag_colors"] = GLOB.prostheti_tag_colors

	// Attribute metadata (always sent — needed for labels/colors)
	data["attribute_names"] = GLOB.prostheti_attribute_names
	data["attribute_colors"] = GLOB.prostheti_attribute_colors

	switch(game.phase)
		if(PROSTHETI_PHASE_BRIEFING)
			// Briefing needs client hint + market preview
			// Price changes summary
			var/list/price_changes = list()
			for(var/list/eff in game.effect_pool)
				if(eff["sale_percent"] > 0)
					price_changes += list(list("name" = eff["name"], "type" = "sale", "percent" = eff["sale_percent"]))
				else if(eff["markup_percent"] > 0)
					price_changes += list(list("name" = eff["name"], "type" = "markup", "percent" = eff["markup_percent"]))
			data["price_changes"] = price_changes

		if(PROSTHETI_PHASE_DESIGN)
			// Effects locked out from previous designs today
			data["used_effects_today"] = game.used_effects_today
			// Full effect pool for selection
			var/list/effects = list()
			for(var/list/eff in game.effect_pool)
				var/list/effect_data = list(
					"id" = eff["id"],
					"name" = eff["name"],
					"ahn_cost" = eff["ahn_cost"],
					"current_ahn_cost" = eff["current_ahn_cost"],
					"ep_cost" = eff["ep_cost"],
					"desc" = eff["desc"],
					"tags" = eff["tags"],
					"sale_percent" = eff["sale_percent"],
					"markup_percent" = eff["markup_percent"],
					"repeatable" = eff["repeatable"],
					"attributes" = eff["attributes"],
				)
				// Include special info for display
				if(eff["special"])
					effect_data["special"] = eff["special"]
				effects += list(effect_data)
			data["effects"] = effects

			// Form pool
			data["forms"] = game.form_pool

			// Current design state
			data["selected_form"] = game.selected_form
			data["selected_rank"] = game.selected_rank
			data["selected_effects"] = game.selected_effects
			data["remaining_ep"] = game.GetRemainingEP()
			data["current_cost"] = game.GetCurrentCost()
			data["max_rank"] = 5

			// Current pentagon attributes (live update)
			data["current_attributes"] = game.current_attributes

			// Build selected effects detail list
			var/list/selected_details = list()
			for(var/eid in game.selected_effects)
				var/list/eff = game.GetPoolEffect(eid)
				if(eff)
					selected_details += list(list(
						"id" = eff["id"],
						"name" = eff["name"],
						"ep_cost" = eff["ep_cost"],
						"current_ahn_cost" = eff["current_ahn_cost"],
						"tags" = eff["tags"],
						"attributes" = eff["attributes"],
					))
			data["selected_details"] = selected_details

			// DO NOT send client attributes during design — they're hidden!

		if(PROSTHETI_PHASE_RESULTS)
			// Day results — NOW reveal client attributes
			data["day_designs"] = game.day_designs
			data["day_profit"] = length(game.day_profits) ? game.day_profits[length(game.day_profits)] : 0
			data["total_profit"] = game.total_profit
			data["is_last_day"] = (game.current_day >= game.total_days)

		if(PROSTHETI_PHASE_SHOP)
			// Workshop shop between days
			data["shop_budget"] = game.shop_budget
			data["total_profit"] = game.total_profit
			data["unlocked_workshops"] = game.unlocked_workshops
			// Build workshop list for UI
			var/list/workshops = list()
			for(var/ws_id in GLOB.prostheti_workshops)
				var/list/ws = GLOB.prostheti_workshops[ws_id]
				var/list/ws_effects = list()
				for(var/eff_id in ws["effects"])
					var/list/eff_def = GLOB.prostheti_workshop_effects[eff_id]
					if(eff_def)
						ws_effects += list(list(
							"id" = eff_id,
							"name" = capitalize(replacetext(eff_id, "_", " ")),
							"tags" = eff_def["tags"],
							"attributes" = eff_def["attributes"],
							"special" = eff_def["special"],
						))
				workshops += list(list(
					"id" = ws_id,
					"name" = ws["name"],
					"desc" = ws["desc"],
					"color" = ws["color"],
					"cost" = ws["cost"],
					"unlocked" = (ws_id in game.unlocked_workshops),
					"effects" = ws_effects,
				))
			data["workshops"] = workshops

		if(PROSTHETI_PHASE_FINAL)
			// Final score
			data["total_profit"] = game.total_profit
			data["day_profits"] = game.day_profits
			data["fixer_designs"] = game.fixer_designs_count
			data["unlocked_workshops"] = game.unlocked_workshops
			var/list/ranking = game.GetFinalRanking()
			data["ranking"] = ranking

	return data

/obj/machinery/computer/prostheti_minigame/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start_game")
			if(!game)
				game = new()
			return TRUE

		if("begin_designing")
			if(!game)
				return FALSE
			game.BeginDesigning()
			return TRUE

		if("add_effect")
			if(!game)
				return FALSE
			var/effect_id = params["effect_id"]
			if(!effect_id)
				return FALSE
			return game.AddEffect(effect_id)

		if("remove_effect")
			if(!game)
				return FALSE
			var/index = text2num(params["index"])
			if(!index)
				return FALSE
			return game.RemoveEffect(index)

		if("set_form")
			if(!game)
				return FALSE
			var/form_id = params["form_id"]
			if(!form_id)
				return FALSE
			return game.SetForm(form_id)

		if("set_rank")
			if(!game)
				return FALSE
			var/rank = text2num(params["rank"])
			if(!rank)
				return FALSE
			return game.SetRank(rank)

		if("submit_design")
			if(!game)
				return FALSE
			return game.SubmitDesign()

		if("next_day")
			if(!game)
				return FALSE
			return game.AdvanceToNextDay()

		if("purchase_workshop")
			if(!game)
				return FALSE
			var/ws_id = params["workshop_id"]
			if(!ws_id)
				return FALSE
			return game.PurchaseWorkshop(ws_id)

		if("advance_from_shop")
			if(!game)
				return FALSE
			return game.AdvanceFromShop()

		if("close_game")
			if(game)
				qdel(game)
				game = null
			return TRUE
