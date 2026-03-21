#define MENU_OPERATION 1
#define MENU_SURGERIES 2

/obj/machinery/computer/operating
	name = "operating computer"
	desc = "Monitors patient vitals and displays surgery steps. Can be loaded with surgery disks to perform experimental procedures. Automatically syncs to stasis beds within its line of sight for surgical tech advancement."
	icon_screen = "crew"
	icon_keyboard = "med_key"
	circuit = /obj/item/circuitboard/computer/operating

	var/mob/living/carbon/human/patient
	var/obj/structure/table/optable/table
	var/obj/machinery/stasis/sbed
	var/list/advanced_surgeries = list()
	var/datum/techweb/linked_techweb
	light_color = LIGHT_COLOR_BLUE
	/// Cached base64 icons for surgery tools, keyed by icon_state
	var/static/list/tool_icon_cache
	/// Basic surgery kit: TOOL_ constant -> list("name", "icon_state")
	var/static/list/basic_tool_map
	/// Advanced surgery kit: TOOL_ constant -> list("name", "icon_state", "note")
	var/static/list/advanced_tool_map

/obj/machinery/computer/operating/Initialize()
	. = ..()
	linked_techweb = SSresearch.science_tech
	find_table()

/obj/machinery/computer/operating/Destroy()
	for(var/direction in GLOB.alldirs)
		table = locate(/obj/structure/table/optable) in get_step(src, direction)
		if(table && table.computer == src)
			table.computer = null
		else
			sbed = locate(/obj/machinery/stasis) in get_step(src, direction)
			if(sbed && sbed.op_computer == src)
				sbed.op_computer = null
	. = ..()

/obj/machinery/computer/operating/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/disk/surgery))
		user.visible_message(span_notice("[user] begins to load \the [O] in \the [src]..."), \
			span_notice("You begin to load a surgery protocol from \the [O]..."), \
			span_hear("You hear the chatter of a floppy drive."))
		var/obj/item/disk/surgery/D = O
		if(do_after(user, 10, target = src))
			advanced_surgeries |= D.surgeries
		return TRUE
	return ..()

/obj/machinery/computer/operating/proc/sync_surgeries()
	for(var/i in linked_techweb.researched_designs)
		var/datum/design/surgery/D = SSresearch.techweb_design_by_id(i)
		if(!istype(D))
			continue
		advanced_surgeries |= D.surgery

/obj/machinery/computer/operating/proc/find_table()
	for(var/direction in GLOB.alldirs)
		table = locate(/obj/structure/table/optable) in get_step(src, direction)
		if(table)
			table.computer = src
			break
		else
			sbed = locate(/obj/machinery/stasis) in get_step(src, direction)
			if(sbed)
				sbed.op_computer = src
				break

/// Initialize the static tool mapping and icon cache
/obj/machinery/computer/operating/proc/ensure_tool_cache()
	if(tool_icon_cache)
		return
	// Basic kit tool mapping: TOOL_ constant -> list(name, icon_state)
	basic_tool_map = list()
	basic_tool_map[TOOL_SCALPEL] = list("name" = "scalpel", "icon_state" = "scalpel")
	basic_tool_map[TOOL_HEMOSTAT] = list("name" = "hemostat", "icon_state" = "hemostat")
	basic_tool_map[TOOL_RETRACTOR] = list("name" = "retractor", "icon_state" = "retractor")
	basic_tool_map[TOOL_SAW] = list("name" = "circular saw", "icon_state" = "saw")
	basic_tool_map[TOOL_DRILL] = list("name" = "surgical drill", "icon_state" = "drill")
	basic_tool_map[TOOL_CAUTERY] = list("name" = "cautery", "icon_state" = "cautery")
	basic_tool_map[TOOL_BONESET] = list("name" = "bonesetter", "icon_state" = "bone setter")
	// Advanced kit tool mapping: TOOL_ constant -> list(name, icon_state, note)
	advanced_tool_map = list()
	advanced_tool_map[TOOL_SCALPEL] = list("name" = "laser scalpel", "icon_state" = "scalpel_a", "note" = "")
	advanced_tool_map[TOOL_SAW] = list("name" = "laser scalpel", "icon_state" = "scalpel_a", "note" = "Click to swap to saw mode")
	advanced_tool_map[TOOL_RETRACTOR] = list("name" = "mechanical pinches", "icon_state" = "retractor_a", "note" = "")
	advanced_tool_map[TOOL_HEMOSTAT] = list("name" = "mechanical pinches", "icon_state" = "hemostat_a", "note" = "Click to swap to hemostat mode")
	advanced_tool_map[TOOL_CAUTERY] = list("name" = "searing tool", "icon_state" = "cautery_a", "note" = "")
	advanced_tool_map[TOOL_DRILL] = list("name" = "searing tool", "icon_state" = "surgicaldrill_a", "note" = "Click to swap to drill mode")
	advanced_tool_map[TOOL_BONESET] = list("name" = "bonesetter", "icon_state" = "bone setter", "note" = "")
	// Build icon cache for all unique icon_states
	tool_icon_cache = list()
	var/list/all_icon_states = list("scalpel", "hemostat", "retractor", "saw", "drill", "cautery", "bone setter", "scalpel_a", "retractor_a", "hemostat_a", "cautery_a", "surgicaldrill_a")
	for(var/state in all_icon_states)
		var/icon/I = new('icons/obj/surgery.dmi', state)
		tool_icon_cache[state] = icon2base64(I)

/// Map a type path from implements to a TOOL_ constant if it matches a kit tool
/obj/machinery/computer/operating/proc/typepath_to_tool(path)
	if(ispath(path, /obj/item/scalpel))
		return TOOL_SCALPEL
	if(ispath(path, /obj/item/hemostat))
		return TOOL_HEMOSTAT
	if(ispath(path, /obj/item/retractor))
		return TOOL_RETRACTOR
	if(ispath(path, /obj/item/circular_saw))
		return TOOL_SAW
	if(ispath(path, /obj/item/surgicaldrill))
		return TOOL_DRILL
	if(ispath(path, /obj/item/cautery))
		return TOOL_CAUTERY
	if(ispath(path, /obj/item/bonesetter))
		return TOOL_BONESET
	return null

/// Get recommended basic and advanced tool info for a surgery step
/obj/machinery/computer/operating/proc/get_tool_recommendation(datum/surgery_step/step)
	var/list/result = list()
	var/found_basic = FALSE
	var/found_advanced = FALSE
	for(var/key in step.implements)
		if(found_basic && found_advanced)
			break
		var/tool_key = key
		// If the key is a type path, try to map it to a TOOL_ constant
		if(ispath(key))
			tool_key = typepath_to_tool(key)
			if(!tool_key)
				continue
		// Check basic kit
		if(!found_basic && basic_tool_map[tool_key])
			var/list/basic = basic_tool_map[tool_key]
			result["basic_name"] = basic["name"]
			result["basic_icon"] = tool_icon_cache[basic["icon_state"]]
			found_basic = TRUE
		// Check advanced kit
		if(!found_advanced && advanced_tool_map[tool_key])
			var/list/adv = advanced_tool_map[tool_key]
			result["adv_name"] = adv["name"]
			result["adv_icon"] = tool_icon_cache[adv["icon_state"]]
			result["adv_note"] = adv["note"]
			found_advanced = TRUE
	return result

/obj/machinery/computer/operating/ui_state(mob/user)
	return GLOB.not_incapacitated_state

/obj/machinery/computer/operating/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OperatingComputer", name)
		ui.open()

/obj/machinery/computer/operating/ui_data(mob/user)
	ensure_tool_cache()
	var/list/data = list()
	var/list/surgeries = list()
	for(var/X in advanced_surgeries)
		var/datum/surgery/S = X
		var/list/surgery = list()
		surgery["name"] = initial(S.name)
		surgery["desc"] = initial(S.desc)
		surgeries += list(surgery)
	data["surgeries"] = surgeries
	data["patient"] = null
	if(table)
		data["table"] = table
		if(!table.check_eligible_patient())
			return data
		data["patient"] = list()
		patient = table.patient
	else
		if(sbed)
			data["table"] = sbed
			if(!ishuman(sbed.occupant))
				return data
			data["patient"] = list()
			patient = sbed.occupant
		else
			data["patient"] = null
			return data
	switch(patient.stat)
		if(CONSCIOUS)
			data["patient"]["stat"] = "Conscious"
			data["patient"]["statstate"] = "good"
		if(SOFT_CRIT)
			data["patient"]["stat"] = "Conscious"
			data["patient"]["statstate"] = "average"
		if(UNCONSCIOUS, HARD_CRIT)
			data["patient"]["stat"] = "Unconscious"
			data["patient"]["statstate"] = "average"
		if(DEAD)
			data["patient"]["stat"] = "Dead"
			data["patient"]["statstate"] = "bad"
	data["patient"]["health"] = patient.health
	data["patient"]["blood_type"] = patient.dna.blood_type
	data["patient"]["maxHealth"] = patient.maxHealth
	data["patient"]["minHealth"] = patient.death_threshold
	data["patient"]["bruteLoss"] = patient.getBruteLoss()
	data["patient"]["sanityLoss"] = patient.getSanityLoss()
	data["patient"]["fireLoss"] = patient.getFireLoss()
	data["patient"]["toxLoss"] = patient.getToxLoss()
	data["patient"]["oxyLoss"] = patient.getOxyLoss()
	data["procedures"] = list()
	if(patient.surgeries.len)
		for(var/datum/surgery/procedure in patient.surgeries)
			var/datum/surgery_step/surgery_step = procedure.get_surgery_step()
			var/chems_needed = surgery_step.get_chem_list()
			var/alternative_step
			var/alt_chems_needed = ""
			if(surgery_step.repeatable)
				var/datum/surgery_step/next_step = procedure.get_surgery_next_step()
				if(next_step)
					alternative_step = capitalize(next_step.name)
					alt_chems_needed = next_step.get_chem_list()
				else
					alternative_step = "Finish operation"
			var/list/tool_rec = get_tool_recommendation(surgery_step)
			data["procedures"] += list(list(
				"name" = capitalize("[parse_zone(procedure.location)] [procedure.name]"),
				"next_step" = capitalize(surgery_step.name),
				"chems_needed" = chems_needed,
				"alternative_step" = alternative_step,
				"alt_chems_needed" = alt_chems_needed,
				"basic_tool_name" = tool_rec["basic_name"],
				"basic_tool_icon" = tool_rec["basic_icon"],
				"adv_tool_name" = tool_rec["adv_name"],
				"adv_tool_icon" = tool_rec["adv_icon"],
				"adv_tool_note" = tool_rec["adv_note"]
			))
	return data



/obj/machinery/computer/operating/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("sync")
			sync_surgeries()
			. = TRUE
	. = TRUE

#undef MENU_OPERATION
#undef MENU_SURGERIES
