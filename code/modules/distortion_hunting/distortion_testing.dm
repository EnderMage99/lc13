// Distortion Hunting System - Testing & Debug Tools
// Admin verbs and test procs for development

/client/proc/test_distortion_investigation()
	set name = "Test Distortion Investigation"
	set category = "Debug"

	if(!check_rights(R_ADMIN))
		return

	// Create config
	var/datum/distortion_config/another_day_at_work/config = new

	to_chat(src, span_notice("=== DISTORTION INVESTIGATION TEST ==="))
	to_chat(src, span_notice("Config created: [config.distortion_name]"))
	to_chat(src, span_notice("Allowed evidence types: [LAZYLEN(config.allowed_evidence_types)]"))

	// Create investigation
	var/datum/distortion_investigation/investigation = new(config)

	to_chat(src, span_notice("Investigation created!"))
	to_chat(src, span_notice("Active: [investigation.active]"))
	to_chat(src, span_notice("Total fields: [investigation.total_fields]"))
	to_chat(src, span_notice("Current tier: [investigation.current_tier]"))

	// Show randomized traits
	to_chat(src, span_notice("--- Randomized Profile Data ---"))
	for(var/trait_name in investigation.profile_data)
		var/value = investigation.profile_data[trait_name]
		to_chat(src, span_notice("  [trait_name]: [value]"))

	// Test unlocking fields
	to_chat(src, span_notice("--- Testing Field Unlocking ---"))

	// Unlock Tier 0 fields (home_district)
	var/list/newly_unlocked = investigation.UnlockFields(list("home_district"))
	to_chat(src, span_notice("Unlocked: [english_list(newly_unlocked)]"))
	to_chat(src, span_notice("Progress: [investigation.investigation_progress]%"))

	// Unlock more Tier 0 fields
	newly_unlocked = investigation.UnlockFields(list("job_title", "work_district", "gender"))
	to_chat(src, span_notice("Unlocked: [english_list(newly_unlocked)]"))
	to_chat(src, span_notice("Progress: [investigation.investigation_progress]%"))
	to_chat(src, span_notice("Current tier: [investigation.current_tier]"))

	// Unlock Tier 1 fields
	newly_unlocked = investigation.UnlockFields(list("first_name", "last_name", "company_name", "age"))
	to_chat(src, span_notice("Unlocked: [english_list(newly_unlocked)]"))
	to_chat(src, span_notice("Progress: [investigation.investigation_progress]%"))
	to_chat(src, span_notice("Current tier: [investigation.current_tier]"))

	// Unlock Tier 2 fields
	newly_unlocked = investigation.UnlockFields(list("supervisor_name", "department"))
	to_chat(src, span_notice("Unlocked: [english_list(newly_unlocked)]"))
	to_chat(src, span_notice("Progress: [investigation.investigation_progress]%"))
	to_chat(src, span_notice("Current tier: [investigation.current_tier]"))

	// Test GetTraitDisplay
	to_chat(src, span_notice("--- Testing Display Values ---"))
	to_chat(src, span_notice("First name (unlocked): [investigation.GetTraitDisplay("first_name")]"))

	// Test duplicate unlock
	to_chat(src, span_notice("--- Testing Duplicate Unlock ---"))
	newly_unlocked = investigation.UnlockFields(list("first_name"))
	to_chat(src, span_notice("Unlocked: [LAZYLEN(newly_unlocked)] fields (should be 0)"))

	// Show final state
	to_chat(src, span_notice("--- Final State ---"))
	to_chat(src, span_notice("Total unlocked: [LAZYLEN(investigation.unlocked_fields)]/[investigation.total_fields]"))
	to_chat(src, span_notice("Progress: [investigation.investigation_progress]%"))
	to_chat(src, span_notice("Active: [investigation.active]"))

	to_chat(src, span_notice("=== TEST COMPLETE ==="))

/client/proc/test_distortion_config()
	set name = "Test Distortion Config"
	set category = "Debug"

	if(!check_rights(R_ADMIN))
		return

	var/datum/distortion_config/another_day_at_work/config = new

	to_chat(src, span_notice("=== DISTORTION CONFIG TEST ==="))
	to_chat(src, span_notice("Name: [config.distortion_name]"))
	to_chat(src, span_notice("Category: [config.distortion_category]"))
	to_chat(src, span_notice("Theme: [config.primary_theme]"))

	to_chat(src, span_notice("--- Trait Pools ---"))
	for(var/trait_name in config.randomized_trait_pools)
		var/list/options = config.randomized_trait_pools[trait_name]
		to_chat(src, span_notice("  [trait_name]: [LAZYLEN(options)] options"))

	to_chat(src, span_notice("--- Evidence Types ---"))
	for(var/evidence_type in config.allowed_evidence_types)
		var/weight = config.clue_spawn_weights[evidence_type]
		to_chat(src, span_notice("  [evidence_type] (weight: [weight])"))

	to_chat(src, span_notice("--- Tier Requirements ---"))
	for(var/tier_key in config.tier_requirements)
		var/list/required_fields = config.tier_requirements[tier_key]
		to_chat(src, span_notice("  Tier [tier_key]: [english_list(required_fields)]"))

	to_chat(src, span_notice("=== TEST COMPLETE ==="))
