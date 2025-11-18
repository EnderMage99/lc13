// Example distortion configuration for "Another Day at Work"
// Simplified MVP version - 3 tiers, 7 clues total
// File location: code/modules/distortion_hunting/configs/another_day_at_work.dm

/datum/distortion_config/another_day_at_work
	distortion_name = "Another Day at Work"

	// ===========================
	// EVIDENCE TYPES BY TIER
	// ===========================

	allowed_evidence_types = list(
		// TIER 0 - Initial clues (3 clues)
		"newspaper_article",
		"abandoned_briefcase",
		"public_alert",

		// TIER 1 - Identity & Work (2 clues)
		"employee_id_basic",
		"paycheck_stub",

		// TIER 2 - Breaking Point (2 clues)
		"meeting_recording",
		"witness_statement"
	)

	// ===========================
	// RANDOMIZED TRAITS
	// Only what player fills in portfolio (max 3 words each)
	// ===========================

	randomized_trait_pools = list(
		// Personal Identity
		"first_name" = list("Marcus", "David", "Sarah", "Jennifer", "Michael", "Lisa"),
		"last_name" = list("Chen", "Park", "Kim", "Smith", "Garcia", "Lee"),
		"age" = list("28", "32", "34", "38", "41", "45"),
		"gender" = list("Male", "Female"),

		// Employment
		"job_title" = list("Junior Accountant", "Data Entry Clerk", "Administrative Assistant"),
		"company_name" = list("Wing Corp Financial", "K Corp Subsidiary", "N Corp Data"),
		"supervisor_name" = list("Director Hayes", "Manager Winters", "Chief Reynolds"),
		"department" = list("Finance Department", "Operations Department", "Administrative Services"),

		// Location
		"home_district" = list("District 8", "District 23", "District 11"),
		"work_district" = list("District 8 Business", "District 11 Corporate", "District 23 Office")
	)

	// ===========================
	// CLUE SPAWN WEIGHTS
	// ===========================

	clue_spawn_weights = list(
		"newspaper_article" = 100,
		"abandoned_briefcase" = 100,
		"public_alert" = 100,
		"employee_id_basic" = 80,
		"paycheck_stub" = 80,
		"meeting_recording" = 50,
		"witness_statement" = 50
	)

// ===========================
// CLUE SPAWN LANDMARK
// Place these on the map where clues should spawn
// ===========================

/obj/effect/landmark/clue_spawn
	name = "clue spawn point"
	desc = "A location where investigation clues can spawn."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	var/tier_requirement = 0 // Which tier can use this spawn point
	var/spawn_weight = 100 // Higher = more likely to be chosen

/obj/effect/landmark/clue_spawn/Initialize()
	. = ..()
	GLOB.clue_spawn_landmarks += src

/obj/effect/landmark/clue_spawn/Destroy()
	GLOB.clue_spawn_landmarks -= src
	return ..()

// Tier-specific spawn points
/obj/effect/landmark/clue_spawn/tier0
	tier_requirement = 0

/obj/effect/landmark/clue_spawn/tier1
	tier_requirement = 1

/obj/effect/landmark/clue_spawn/tier2
	tier_requirement = 2

// Global list to track spawn points
GLOBAL_LIST_EMPTY(clue_spawn_landmarks)

// ===========================
// BASE CLUE ITEM WITH UI
// ===========================

/obj/item/clue
	name = "evidence"
	desc = "A piece of evidence related to a distortion investigation."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	var/clue_type = "generic"
	var/tier_requirement = 0
	var/list/reveals_fields = list()
	var/datum/distortion_investigation/linked_investigation
	var/description_template = "Generic evidence."
	var/scanned = FALSE

/obj/item/clue/attack_self(mob/user)
	ui_interact(user)

/obj/item/clue/ui_interact(mob/user)
	. = ..()
	if(isliving(user))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)

	var/dat
	dat += "<b>EVIDENCE: [name]</b><br>----------------------<br>"

	// Show the generated description
	var/full_description = GenerateDescription()
	dat += "[full_description]<br><br>"

	// Show scan status
	if(scanned)
		dat += "<b>STATUS: ANALYZED</b><br>"
		dat += "This evidence has been scanned and processed.<br>"
		if(LAZYLEN(reveals_fields))
			dat += "<br><b>Unlocked Fields:</b><br>"
			for(var/field in reveals_fields)
				dat += "  - [field]<br>"
	else
		dat += "<b>STATUS: UNANALYZED</b><br>"
		dat += "Take this evidence to an Investigation Scanner for analysis.<br>"

	var/datum/browser/popup = new(user, "evidence_[clue_type]", "Evidence: [name]", 500, 400)
	popup.set_content(dat)
	popup.open()

/obj/item/clue/proc/GenerateDescription()
	if(!linked_investigation)
		return description_template

	var/final_desc = description_template

	// Replace all [trait_name] placeholders with actual values
	for(var/trait_name in linked_investigation.profile_data)
		var/value = linked_investigation.profile_data[trait_name]
		final_desc = replacetext(final_desc, "\[[trait_name]\]", value)

	return final_desc

/obj/item/clue/examine(mob/user)
	. = ..()
	if(scanned)
		. += span_notice("This evidence has been ANALYZED. Click to view details.")
	else
		. += span_warning("This evidence is UNANALYZED. Take it to an Investigation Scanner.")
	. += span_notice("Click in hand to examine evidence.")

// ===========================
// CLUE DEFINITIONS
// 7 total clues for MVP
// ===========================

// ===========================
// TIER 0 CLUES (3 clues)
// Initial investigation - spawn at start
// Each reveals unique traits - 4 total traits
// ===========================

/obj/item/clue/another_day/newspaper
	name = "newspaper clipping"
	clue_type = "newspaper_article"
	tier_requirement = 0
	reveals_fields = list("home_district")

	description_template = {"District [home_district] Gazette: 'Distortion incident reported in corporate district.
	A worker transformed during a workplace incident. Authorities investigating. Area cordoned off.'"}

/obj/item/clue/another_day/briefcase
	name = "abandoned briefcase"
	clue_type = "abandoned_briefcase"
	tier_requirement = 0
	reveals_fields = list("job_title")

	description_template = {"A battered briefcase containing office supplies and stress-crumpled papers.
	Business cards inside indicate owner worked as [job_title]. No name visible."}

/obj/item/clue/another_day/public_alert
	name = "public safety alert"
	clue_type = "public_alert"
	tier_requirement = 0
	reveals_fields = list("work_district", "gender")

	description_template = {"CITY ALERT: Distortion event in [work_district].
	Witnesses report [gender] individual underwent transformation during business hours.
	Citizens advised to avoid area until Hunter's Guild provides all-clear."}

// ===========================
// TIER 1 CLUES (2 clues)
// Identity & Employment - spawn after Tier 0 complete
// Prerequisites: home_district + gender + age filled in
// ===========================

/obj/item/clue/another_day/employee_id
	name = "employee ID badge"
	clue_type = "employee_id_basic"
	tier_requirement = 1
	reveals_fields = list("first_name", "last_name", "company_name")

	description_template = {"[company_name] - [first_name] [last_name] - [job_title]
	The photo has been scratched out. The plastic is cracked like someone gripped it too hard."}

/obj/item/clue/another_day/paycheck
	name = "paycheck stub"
	clue_type = "paycheck_stub"
	tier_requirement = 1
	reveals_fields = list("age")

	// Story hardcoded: Overwork, unpaid overtime
	description_template = {"Paycheck stub for [job_title] position.
	Employee age: [age] years old. Years of service: [age] minus 22.
	87 hours this period (47 hours unpaid overtime).
	Handwritten note on back: 'Why do I keep doing this?'"}

// ===========================
// TIER 2 CLUES (2 clues)
// The Breaking Point - spawn after Tier 1 complete
// Prerequisites: first_name + last_name + company_name filled in
// ===========================

/obj/item/clue/another_day/meeting_recording
	name = "audio recording"
	clue_type = "meeting_recording"
	tier_requirement = 2
	reveals_fields = list("supervisor_name")

	// Story hardcoded: THE BREAKING POINT - Public humiliation, evidence destroyed, silence from peers
	description_template = {"Meeting audio transcript - Quarterly Review at [company_name]

	[supervisor_name]: '[first_name], your failure on this project is unacceptable. You're dead weight.'
	[first_name]: 'But I have documentation showing-'
	[supervisor_name]: (sound of papers tearing) 'Speak again and you're fired. Understood?'
	(long silence from other attendees)
	(strange distortion sounds)
	(screaming)
	Recording ends."}

/obj/item/clue/another_day/witness_statement
	name = "witness statement"
	clue_type = "witness_statement"
	tier_requirement = 2
	reveals_fields = list("department")

	// Story hardcoded: Coworker testimony - fear, guilt, distortion transformation
	description_template = {"Witness statement - Coworker in [department] at [company_name], [work_district]

	'I was in the quarterly review meeting when it happened. [supervisor_name] was tearing into [first_name]
	in front of everyone. Called them dead weight. Ripped up their documentation when they tried to defend
	themselves. We all just sat there in silence. Too scared to speak up.

	Then... then [first_name] started changing. Their body twisted, merged with the office furniture.
	Cubicle walls grew from their bones. Flesh fused with filing cabinets. They became the office itself.

	[supervisor_name] was the first one caught. The rest of us ran. I can still hear the screaming.

	I wanted to say something during that meeting. I really did. But I was scared for my job.
	Maybe if just one of us had spoken up...'

	Statement recorded by Hunter's Guild investigator."}
