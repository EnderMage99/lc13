// =============================================
// Prostheti Innovations — Minigame Round Controller
// =============================================
// Manages the multi-day augment design minigame. Each day has a client type,
// trending/oversaturated tags, and market price changes. Players submit designs
// and are scored on pentagon overlap at the end of each day.
//
// Pentagon System: Players build a 5-attribute profile (Lethality, Endurance,
// Agility, Control, Efficiency) by adding effects. Profit is determined by
// how well the player's pentagon overlaps the client's hidden pentagon.
//
// Flow: BRIEFING → DESIGN (x designs_per_day) → RESULTS → repeat or FINAL

/// Manages one full minigame session (3 days of augment design).
/datum/prostheti_minigame
	/// Current day number (1-indexed)
	var/current_day = 1
	/// Total number of days in the minigame
	var/total_days = 3
	/// Number of designs required per day
	var/designs_per_day = 4
	/// Current design number within the day (1-indexed)
	var/current_design_num = 0
	/// Current minigame phase (PROSTHETI_PHASE_*)
	var/phase = PROSTHETI_PHASE_BRIEFING

	// --- Market State ---
	/// The client type for the current day (assoc list from GLOB.prostheti_client_types)
	var/list/current_client
	/// List of trending tag strings (2-3 tags, +bonus to sell price)
	var/list/trending_tags = list()
	/// List of oversaturated tag strings (1-2 tags, -penalty to sell price)
	var/list/oversaturated_tags = list()

	// --- Effect Pool ---
	/// Deep copy of available_effects with market changes applied per day
	var/list/effect_pool = list()
	/// Deep copy of available_forms
	var/list/form_pool = list()

	// --- Current Design State ---
	/// Currently selected form ID
	var/selected_form = ""
	/// Currently selected rank (1-5)
	var/selected_rank = 1
	/// List of selected effect IDs for the current design
	var/list/selected_effects = list()
	/// Computed attribute totals for the current design (updated on every change)
	var/list/current_attributes = list()

	// --- Results Tracking ---
	/// List of completed design results for the current day
	var/list/day_designs = list()
	/// Profit results per day (list of numbers)
	var/list/day_profits = list()
	/// Running total profit across all days
	var/total_profit = 0
	/// Number of fixer-type client designs completed (gates Penny's intro)
	var/fixer_designs_count = 0

	/// Reference to the campaign controller
	var/datum/campaign_controller/prostheti/campaign

/datum/prostheti_minigame/New()
	if(GLOB.prostheti_campaign)
		campaign = GLOB.prostheti_campaign
	StartNewDay()

/datum/prostheti_minigame/Destroy()
	campaign = null
	return ..()

// =============================================
// Day Management
// =============================================

/// Sets up a new day: picks a client, sets trending/oversaturated tags, applies market changes.
/datum/prostheti_minigame/proc/StartNewDay()
	// Pick a random client type
	current_client = pick(GLOB.prostheti_client_types)

	// Pick trending tags (2-3 from all tags)
	trending_tags = list()
	var/list/available_tags = GLOB.prostheti_all_tags.Copy()
	var/num_trending = rand(2, 3)
	for(var/i in 1 to num_trending)
		if(!length(available_tags))
			break
		var/tag = pick(available_tags)
		trending_tags += tag
		available_tags -= tag

	// Pick oversaturated tags (1-2 from remaining)
	oversaturated_tags = list()
	var/num_oversaturated = rand(1, 2)
	for(var/i in 1 to num_oversaturated)
		if(!length(available_tags))
			break
		var/tag = pick(available_tags)
		oversaturated_tags += tag
		available_tags -= tag

	// Build fresh effect pool with market changes
	BuildEffectPool()

	// Reset design state
	current_design_num = 0
	day_designs = list()
	selected_form = ""
	selected_rank = 1
	selected_effects = list()
	current_attributes = list()
	phase = PROSTHETI_PHASE_BRIEFING

/// Builds the effect pool with randomized sales/markups for this day.
/datum/prostheti_minigame/proc/BuildEffectPool()
	effect_pool = list()
	form_pool = list()

	// Deep copy forms — we only need the core data, not icon references
	var/list/form_data = list(
		list("id" = "prosthetic", "name" = "Internal Prosthetic", "base_cost" = 200, "base_ep" = 2, "desc" = "A standard internal augmentation base.", "negative_immune" = 0),
		list("id" = "tattoo", "name" = "Tattoo", "base_cost" = 50, "base_ep" = 4, "desc" = "An augment woven into the skin. Unable to have negative effects.", "negative_immune" = 1),
	)
	for(var/list/fd in form_data)
		form_pool += list(fd.Copy())

	// Build effects from the definition map (source of valid effect IDs)
	for(var/effect_id in GLOB.prostheti_effect_definitions)
		var/list/effect_entry = FindEffectById(effect_id)
		if(!effect_entry)
			continue
		var/list/copy = effect_entry.Copy()
		// Initialize market state
		copy["current_ahn_cost"] = copy["ahn_cost"]
		copy["sale_percent"] = 0
		copy["markup_percent"] = 0
		// Add definition data (tags, attributes, special)
		var/list/def = GLOB.prostheti_effect_definitions[effect_id]
		copy["tags"] = def["tags"]
		copy["attributes"] = def["attributes"]
		if(def["special"])
			copy["special"] = def["special"]
		effect_pool += list(copy)

	// Apply random sales and markups
	ApplyMinigameMarketChanges()

/// Finds an effect definition by ID from an augment fabricator in the world, or uses hardcoded fallback.
/datum/prostheti_minigame/proc/FindEffectById(effect_id)
	// Try to find an augment fabricator to pull data from
	for(var/obj/machinery/augment_fabricator/fab in GLOB.machines)
		for(var/list/effect in fab.available_effects)
			if(effect["id"] == effect_id)
				return effect
		break // Only need one fabricator
	return null

/// Applies random sales and markups to the effect pool for this day.
/datum/prostheti_minigame/proc/ApplyMinigameMarketChanges()
	var/list/sale_percentages = list(25, 33, 40, 66)
	var/list/markup_percentages = list(25, 33, 40)
	var/num_effects = length(effect_pool)
	if(!num_effects)
		return

	var/num_on_sale = max(1, round(num_effects * 0.2))
	var/num_marked_up = max(1, round(num_effects * 0.1))
	var/max_66_sales = 2
	var/count_66 = 0

	// Shuffle indices for random selection
	var/list/indices = list()
	for(var/i in 1 to num_effects)
		indices += i
	indices = shuffle(indices)

	var/assigned = 0

	// Apply sales
	for(var/idx in indices)
		if(assigned >= num_on_sale)
			break
		var/list/effect = effect_pool[idx]
		var/sale = pick(sale_percentages)
		if(sale == 66)
			if(count_66 >= max_66_sales)
				sale = pick(list(25, 33, 40))
			else
				count_66++
		effect["sale_percent"] = sale
		effect["current_ahn_cost"] = round(effect["ahn_cost"] * (1 - sale / 100))
		assigned++

	// Remove sale indices from pool
	var/list/remaining = indices.Copy(assigned + 1)
	assigned = 0

	// Apply markups
	for(var/idx in remaining)
		if(assigned >= num_marked_up)
			break
		var/list/effect = effect_pool[idx]
		var/markup = pick(markup_percentages)
		effect["markup_percent"] = markup
		effect["current_ahn_cost"] = round(effect["ahn_cost"] * (1 + markup / 100))
		assigned++

// =============================================
// Pentagon Attribute Calculation
// =============================================

/// Recalculates current_attributes based on form + effects + specials.
/datum/prostheti_minigame/proc/CalculateAttributes()
	current_attributes = list()

	// Base: all attributes start at 1
	for(var/attr in GLOB.prostheti_attributes)
		current_attributes[attr] = 1

	// Form bonus (+1 to two attributes)
	var/list/form_bonus = GLOB.prostheti_form_attributes[selected_form]
	if(form_bonus)
		for(var/attr in form_bonus)
			current_attributes[attr] += form_bonus[attr]

	// Effect modifiers
	for(var/eid in selected_effects)
		var/list/def = GLOB.prostheti_effect_definitions[eid]
		if(!def || !def["attributes"])
			continue
		var/list/attrs = def["attributes"]
		for(var/attr in attrs)
			current_attributes[attr] += attrs[attr]

	// Special/conditional bonuses (single pass — specials don't chain)
	for(var/eid in selected_effects)
		var/list/def = GLOB.prostheti_effect_definitions[eid]
		if(!def || !def["special"])
			continue
		var/list/special = def["special"]
		var/condition_attr = special["condition"]
		var/threshold = special["threshold"]
		if(current_attributes[condition_attr] >= threshold)
			var/list/bonus = special["bonus"]
			for(var/attr in bonus)
				current_attributes[attr] += bonus[attr]

	// Floor at 0 (no negative attributes)
	for(var/attr in GLOB.prostheti_attributes)
		if(current_attributes[attr] < 0)
			current_attributes[attr] = 0

// =============================================
// Design Phase
// =============================================

/// Begins the design phase for the current day.
/datum/prostheti_minigame/proc/BeginDesigning()
	phase = PROSTHETI_PHASE_DESIGN
	current_design_num = 1
	selected_form = "prosthetic"
	selected_rank = current_client["rank_min"]
	selected_effects = list()
	CalculateAttributes()

/// Adds an effect ID to the current design.
/datum/prostheti_minigame/proc/AddEffect(effect_id)
	if(phase != PROSTHETI_PHASE_DESIGN)
		return FALSE

	// Find the effect in the pool
	var/list/effect = GetPoolEffect(effect_id)
	if(!effect)
		return FALSE

	// Check if already at max repeats
	var/current_count = 0
	for(var/eid in selected_effects)
		if(eid == effect_id)
			current_count++
	var/max_repeats = effect["repeatable"] ? effect["repeatable"] : 1
	if(current_count >= max_repeats)
		return FALSE

	// Check form restrictions (tattoos can't have negative effects)
	if(selected_form == "tattoo" && effect["ep_cost"] < 0)
		return FALSE

	// Check EP budget
	var/remaining_ep = GetRemainingEP()
	if(remaining_ep - effect["ep_cost"] < 0)
		return FALSE

	selected_effects += effect_id
	CalculateAttributes()
	return TRUE

/// Removes an effect ID from the current design by index.
/datum/prostheti_minigame/proc/RemoveEffect(index)
	if(phase != PROSTHETI_PHASE_DESIGN)
		return FALSE
	if(index < 1 || index > length(selected_effects))
		return FALSE
	selected_effects.Cut(index, index + 1)
	CalculateAttributes()
	return TRUE

/// Sets the form for the current design.
/datum/prostheti_minigame/proc/SetForm(form_id)
	if(phase != PROSTHETI_PHASE_DESIGN)
		return FALSE
	// Validate form exists
	for(var/list/form in form_pool)
		if(form["id"] == form_id)
			selected_form = form_id
			// Remove negative effects if switching to tattoo
			if(form_id == "tattoo")
				var/list/clean = list()
				for(var/eid in selected_effects)
					var/list/eff = GetPoolEffect(eid)
					if(eff && eff["ep_cost"] >= 0)
						clean += eid
				selected_effects = clean
			CalculateAttributes()
			return TRUE
	return FALSE

/// Sets the rank for the current design.
/datum/prostheti_minigame/proc/SetRank(rank)
	if(phase != PROSTHETI_PHASE_DESIGN)
		return FALSE
	if(rank < 1 || rank > 5)
		return FALSE
	selected_rank = rank
	return TRUE

/// Submits the current design. Calculates profit and stores the result.
/datum/prostheti_minigame/proc/SubmitDesign()
	if(phase != PROSTHETI_PHASE_DESIGN)
		return FALSE
	if(!selected_form)
		return FALSE
	if(!length(selected_effects))
		return FALSE

	var/list/design = list(
		"form" = selected_form,
		"rank" = selected_rank,
		"effects" = selected_effects.Copy(),
		"attributes" = current_attributes.Copy(),
	)

	var/list/result = CalculateProfit(design)
	day_designs += list(result)

	// Track fixer designs
	if(current_client["is_fixer"])
		fixer_designs_count++

	// Advance to next design or results
	current_design_num++
	if(current_design_num > designs_per_day)
		// Day is done
		var/day_total = 0
		for(var/list/r in day_designs)
			day_total += r["profit"]
		day_profits += day_total
		total_profit += day_total
		phase = PROSTHETI_PHASE_RESULTS
	else
		// Reset design state for next design
		selected_form = "prosthetic"
		selected_rank = current_client["rank_min"]
		selected_effects = list()
		CalculateAttributes()

	return TRUE

/// Advances to the next day, or to the final score screen.
/datum/prostheti_minigame/proc/AdvanceToNextDay()
	if(phase != PROSTHETI_PHASE_RESULTS)
		return FALSE

	current_day++
	if(current_day > total_days)
		phase = PROSTHETI_PHASE_FINAL
		// Update NPC vars on the campaign NPCs
		if(campaign)
			for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/penny in campaign.current_npcs)
				penny.SetSharedVar("fixer_designs", fixer_designs_count)
				break
			for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch1/clyde in campaign.current_npcs)
				clyde.SetSharedVar("completed_work_days", total_days)
				break
	else
		// Update Clyde's completed days tracker (current_day was already incremented, so -1)
		if(campaign)
			for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch1/clyde in campaign.current_npcs)
				clyde.SetSharedVar("completed_work_days", current_day - 1)
				break
		StartNewDay()
	return TRUE

// =============================================
// Profit Calculation — Pentagon Overlap
// =============================================

/// Calculates the profit for a submitted design using pentagon overlap scoring.
/datum/prostheti_minigame/proc/CalculateProfit(list/design)
	var/form_id = design["form"]
	var/rank = design["rank"]
	var/list/effects = design["effects"]
	var/list/player_attrs = design["attributes"]

	// Find form data
	var/list/form_data
	for(var/list/fd in form_pool)
		if(fd["id"] == form_id)
			form_data = fd
			break
	if(!form_data)
		return list("profit" = 0, "material_cost" = 0, "sell_value" = 0)

	// --- Material Cost ---
	var/material_cost = form_data["base_cost"] * rank
	for(var/eid in effects)
		var/list/eff = GetPoolEffect(eid)
		if(eff)
			material_cost += eff["current_ahn_cost"]

	// --- Base Sell Value (1.5x material cost at base prices) ---
	var/base_material = form_data["base_cost"] * rank
	for(var/eid in effects)
		var/list/eff = GetPoolEffect(eid)
		if(eff)
			base_material += eff["ahn_cost"] // Use base cost for sell value
	var/base_sell = round(base_material * 1.5)

	// --- Pentagon Overlap Scoring (Primary) ---
	var/list/client_attrs = current_client["attributes"]
	var/total_axis_score = 0
	var/list/axis_breakdown = list()

	for(var/attr in GLOB.prostheti_attributes)
		var/player_val = player_attrs[attr] || 0
		var/client_val = client_attrs[attr] || 0
		var/axis_score = 0
		var/diff = 0

		if(player_val >= client_val)
			diff = player_val - client_val
			axis_score = 1.0 + min(diff * 0.03, 0.15)
		else
			diff = player_val - client_val // Negative
			if(client_val > 0)
				axis_score = player_val / client_val
			else
				axis_score = 1.0

		total_axis_score += axis_score
		axis_breakdown += list(list(
			"attr" = attr,
			"player" = player_val,
			"client" = client_val,
			"covered" = (player_val >= client_val),
			"diff" = diff,
		))

	var/overlap = total_axis_score / 5
	var/overlap_sell = round(base_sell * overlap)

	// --- Tag Analysis ---
	var/list/design_tags = list()
	for(var/eid in effects)
		var/list/def = GLOB.prostheti_effect_definitions[eid]
		if(def && def["tags"])
			for(var/tag in def["tags"])
				design_tags[tag] = (design_tags[tag] || 0) + 1

	var/list/breakdown = list()
	var/tag_bonus_total = 0

	// Required tag check (+8% present, -15% missing)
	var/list/required_tags = current_client["required_tags"]
	if(required_tags)
		for(var/tag in required_tags)
			if(design_tags[tag])
				var/bonus = round(base_sell * 0.08)
				tag_bonus_total += bonus
				breakdown += list(list("label" = "Required: [tag]", "value" = bonus, "positive" = TRUE))
			else
				var/penalty = round(base_sell * 0.15)
				tag_bonus_total -= penalty
				breakdown += list(list("label" = "Missing required: [tag]", "value" = -penalty, "positive" = FALSE))

	// Trending bonuses (+8% per matching tag)
	for(var/tag in trending_tags)
		if(design_tags[tag])
			var/bonus = round(base_sell * 0.08)
			tag_bonus_total += bonus
			breakdown += list(list("label" = "Trending: [tag]", "value" = bonus, "positive" = TRUE))

	// Oversaturated penalties (-6% per matching tag)
	for(var/tag in oversaturated_tags)
		if(design_tags[tag])
			var/penalty = round(base_sell * 0.06)
			tag_bonus_total -= penalty
			breakdown += list(list("label" = "Oversaturated: [tag]", "value" = -penalty, "positive" = FALSE))

	// --- Rank Mismatch Penalty ---
	var/rank_penalty = 0
	if(rank < current_client["rank_min"] || rank > current_client["rank_max"])
		rank_penalty = round(base_sell * 0.25)
		breakdown += list(list("label" = "Rank mismatch", "value" = -rank_penalty, "positive" = FALSE))

	// --- Final Calculation ---
	var/final_sell = overlap_sell + tag_bonus_total - rank_penalty
	if(final_sell < 0)
		final_sell = 0
	var/profit = final_sell - material_cost

	// Build effect names list for display
	var/list/effect_names = list()
	for(var/eid in effects)
		var/list/eff = GetPoolEffect(eid)
		if(eff)
			effect_names += eff["name"]

	return list(
		"form" = form_data["name"],
		"rank" = rank,
		"effects" = effect_names,
		"effect_ids" = effects,
		"material_cost" = material_cost,
		"base_sell" = base_sell,
		"overlap" = overlap,
		"overlap_sell" = overlap_sell,
		"sell_value" = final_sell,
		"profit" = profit,
		"breakdown" = breakdown,
		"axis_breakdown" = axis_breakdown,
		"player_attributes" = player_attrs,
		"client_attributes" = client_attrs,
	)

/// Returns the final ranking string based on total profit.
/datum/prostheti_minigame/proc/GetFinalRanking()
	if(total_profit >= 3000)
		return list("rank" = "S", "title" = "Master Artificer", "desc" = "You could run this company yourself.")
	if(total_profit >= 2000)
		return list("rank" = "A", "title" = "Expert Designer", "desc" = "Clyde might actually be impressed.")
	if(total_profit >= 1200)
		return list("rank" = "B", "title" = "Competent Worker", "desc" = "Reliable work. The company profits.")
	if(total_profit >= 600)
		return list("rank" = "C", "title" = "Adequate", "desc" = "You covered costs. Barely.")
	if(total_profit >= 0)
		return list("rank" = "D", "title" = "Break Even", "desc" = "You didn't lose money. That's... something.")
	return list("rank" = "F", "title" = "Net Loss", "desc" = "Clyde is going to have words with you.")

// =============================================
// Helpers
// =============================================

/// Gets an effect from the pool by ID.
/datum/prostheti_minigame/proc/GetPoolEffect(effect_id)
	for(var/list/eff in effect_pool)
		if(eff["id"] == effect_id)
			return eff
	return null

/// Gets the remaining EP budget for the current design.
/datum/prostheti_minigame/proc/GetRemainingEP()
	var/list/form_data
	for(var/list/fd in form_pool)
		if(fd["id"] == selected_form)
			form_data = fd
			break
	if(!form_data)
		return 0

	var/max_ep = form_data["base_ep"] + ((selected_rank - 1) * 2)
	var/used_ep = 0
	for(var/eid in selected_effects)
		var/list/eff = GetPoolEffect(eid)
		if(eff)
			used_ep += eff["ep_cost"]
	return max_ep - used_ep

/// Gets the total material cost for the current design.
/datum/prostheti_minigame/proc/GetCurrentCost()
	var/list/form_data
	for(var/list/fd in form_pool)
		if(fd["id"] == selected_form)
			form_data = fd
			break
	if(!form_data)
		return 0

	var/cost = form_data["base_cost"] * selected_rank
	for(var/eid in selected_effects)
		var/list/eff = GetPoolEffect(eid)
		if(eff)
			cost += eff["current_ahn_cost"]
	return cost
