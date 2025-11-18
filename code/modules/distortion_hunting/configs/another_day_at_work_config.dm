// Another Day at Work - Distortion Configuration
// Corporate exploitation and workplace burnout themed investigation

/datum/distortion_config/another_day_at_work
	distortion_name = "Another Day at Work"
	distortion_category = "workplace_stress"
	primary_theme = "Corporate exploitation and workplace burnout"

	// Evidence types this distortion can spawn (7 total across 3 tiers)
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

	// Randomized traits - surface details that change each investigation
	// These are the personal details that make each playthrough unique
	randomized_trait_pools = list(
		// Personal Identity (4 traits)
		"first_name" = list("Marcus", "David", "Sarah", "Jennifer", "Michael", "Lisa"),
		"last_name" = list("Chen", "Park", "Kim", "Smith", "Garcia", "Lee"),
		"age" = list("28", "32", "34", "38", "41", "45"),
		"gender" = list("Male", "Female"),

		// Employment (4 traits)
		"job_title" = list("Junior Accountant", "Data Entry Clerk", "Administrative Assistant"),
		"company_name" = list("Wing Corp Financial", "K Corp Subsidiary", "N Corp Data"),
		"supervisor_name" = list("Director Hayes", "Manager Winters", "Chief Reynolds"),
		"department" = list("Finance Department", "Operations Department", "Administrative Services"),

		// Location (2 traits)
		"home_district" = list("District 8", "District 23", "District 11"),
		"work_district" = list("District 8 Business", "District 11 Corporate", "District 23 Office")
	)

	// Spawn weights for each clue type (higher = more likely to spawn at that landmark)
	clue_spawn_weights = list(
		"newspaper_article" = 100,
		"abandoned_briefcase" = 100,
		"public_alert" = 100,
		"employee_id_basic" = 80,
		"paycheck_stub" = 80,
		"meeting_recording" = 50,
		"witness_statement" = 50
	)

	// Tier unlock requirements
	// Tier 1 unlocks when all Tier 0 clue reveals are found
	// Tier 2 unlocks when all Tier 1 clue reveals are found
	tier_requirements = list(
		"1" = list("home_district", "job_title", "work_district", "gender"),
		"2" = list("first_name", "last_name", "company_name", "age")
	)

// Override to provide clue path lookup for this distortion
/datum/distortion_config/another_day_at_work/GetCluePathFromType(clue_type_string)
	switch(clue_type_string)
		if("newspaper_article")
			return /obj/item/clue/another_day/newspaper
		if("abandoned_briefcase")
			return /obj/item/clue/another_day/briefcase
		if("public_alert")
			return /obj/item/clue/another_day/public_alert
		if("employee_id_basic")
			return /obj/item/clue/another_day/employee_id
		if("paycheck_stub")
			return /obj/item/clue/another_day/paycheck
		if("meeting_recording")
			return /obj/item/clue/another_day/meeting_recording
		if("witness_statement")
			return /obj/item/clue/another_day/witness_statement

	return null
