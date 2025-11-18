// Distortion Hunting System - Investigation Instance Datum
// Tracks a single active distortion investigation

/datum/distortion_investigation
	/// Reference to the config defining this distortion type
	var/datum/distortion_config/config

	/// Randomized profile data - stores the actual values chosen for this investigation
	/// Format: list("trait_name" = "chosen_value")
	/// Example: list("first_name" = "Marcus", "age" = "32", "company_name" = "Wing Corp Financial")
	var/list/profile_data = list()

	/// Which fields the player has unlocked by scanning evidence
	/// Format: list("trait_name", "trait_name2", ...)
	var/list/unlocked_fields = list()

	/// Track all spawned clue objects for this investigation
	/// Format: list(obj/item/clue, obj/item/clue, ...)
	var/list/spawned_clues = list()

	/// Investigation progress percentage (0-100)
	var/investigation_progress = 0

	/// Whether this investigation is currently active
	var/active = FALSE

	/// Current highest unlocked tier
	var/current_tier = 0

	/// Total number of fields to unlock for completion
	var/total_fields = 0

/// Constructor - initializes a new investigation instance
/// Arguments:
/// * config_datum - The distortion config to use for this investigation
/datum/distortion_investigation/New(datum/distortion_config/config_datum)
	. = ..()
	if(!config_datum)
		CRASH("Distortion investigation created without config!")

	config = config_datum
	RandomizeTraits()
	CalculateTotalFields()
	active = TRUE

	// Send signal that investigation started
	SEND_SIGNAL(src, COMSIG_INVESTIGATION_STARTED)

/// Randomizes all traits from the config's trait pools
/// Stores results in profile_data
/datum/distortion_investigation/proc/RandomizeTraits()
	profile_data = list()

	for(var/trait_name in config.randomized_trait_pools)
		var/list/options = config.randomized_trait_pools[trait_name]
		if(!LAZYLEN(options))
			continue

		// Pick random value from pool
		var/chosen_value = pick(options)
		profile_data[trait_name] = chosen_value

/// Calculate total number of unique fields across all evidence
/datum/distortion_investigation/proc/CalculateTotalFields()
	total_fields = LAZYLEN(config.randomized_trait_pools)

/// Unlocks investigation fields and updates progress
/// Arguments:
/// * fields - List of field names to unlock
/// * scanner - Optional reference to the scanner machine that triggered unlock
/// Returns: List of newly unlocked fields (excludes already unlocked)
/datum/distortion_investigation/proc/UnlockFields(list/fields, obj/machinery/investigation_scanner/scanner)
	if(!LAZYLEN(fields))
		return list()

	var/list/newly_unlocked = list()

	for(var/field_name in fields)
		// Skip if already unlocked
		if(field_name in unlocked_fields)
			continue

		// Verify this is a valid field
		if(!(field_name in profile_data))
			continue

		// Unlock the field
		unlocked_fields += field_name
		newly_unlocked += field_name

		// Send signal for each field unlocked
		SEND_SIGNAL(src, COMSIG_INVESTIGATION_FIELD_UNLOCKED, field_name)

	// Update progress
	if(LAZYLEN(newly_unlocked))
		UpdateProgress()
		CheckTierUnlock()

	return newly_unlocked

/// Check if a specific field is unlocked
/// Arguments:
/// * field_name - Name of the field to check
/// Returns: TRUE if unlocked, FALSE otherwise
/datum/distortion_investigation/proc/IsFieldUnlocked(field_name)
	return (field_name in unlocked_fields)

/// Updates the investigation progress percentage based on unlocked fields
/datum/distortion_investigation/proc/UpdateProgress()
	if(total_fields <= 0)
		investigation_progress = 0
		return

	var/unlocked_count = LAZYLEN(unlocked_fields)
	investigation_progress = round((unlocked_count / total_fields) * 100)

	// Send signal for progress update
	SEND_SIGNAL(src, COMSIG_INVESTIGATION_PROGRESS_UPDATED, investigation_progress)

	// Check for completion
	if(investigation_progress >= 100)
		CompleteInvestigation()

/// Check if tier requirements are met and unlock next tier
/// Returns: The newly unlocked tier, or -1 if no new tier unlocked
/datum/distortion_investigation/proc/CheckTierUnlock()
	var/previous_tier = current_tier

	// Tier 0 is always unlocked
	// Tier 1 requires certain Tier 0 fields unlocked
	// Tier 2 requires certain Tier 1 fields unlocked

	// These requirements should be configurable per distortion
	// For "Another Day at Work":
	// Tier 1 requires: home_district, gender, work_district, job_title (all Tier 0 reveals)
	// Tier 2 requires: first_name, last_name, company_name, age (all Tier 1 reveals)

	if(current_tier == 0)
		// Check Tier 1 requirements
		if(CheckTierRequirements(1))
			current_tier = 1

	if(current_tier == 1)
		// Check Tier 2 requirements
		if(CheckTierRequirements(2))
			current_tier = 2

	// If tier increased, send signal
	if(current_tier > previous_tier)
		SEND_SIGNAL(src, COMSIG_INVESTIGATION_TIER_UNLOCKED, current_tier)
		AnnounceTierUnlock(current_tier)
		return current_tier

	return -1

/// Check if requirements for a specific tier are met
/// Arguments:
/// * tier - The tier to check requirements for
/// Returns: TRUE if requirements met, FALSE otherwise
/datum/distortion_investigation/proc/CheckTierRequirements(tier)
	if(!config || !config.tier_requirements)
		return FALSE

	// Get required fields for this tier from config
	var/tier_key = "[tier]"
	if(!(tier_key in config.tier_requirements))
		return FALSE

	var/list/required_fields = config.tier_requirements[tier_key]
	if(!LAZYLEN(required_fields))
		return TRUE // No requirements = auto-unlock

	// Check if all required fields are unlocked
	for(var/field in required_fields)
		if(!IsFieldUnlocked(field))
			return FALSE

	return TRUE

/// Announce that a new tier has been unlocked
/// Arguments:
/// * tier - The tier that was unlocked
/datum/distortion_investigation/proc/AnnounceTierUnlock(tier)
	priority_announce(
		"Investigation Update: Additional evidence located. Tier [tier] clues now available for analysis.",
		"Hunter's Guild - Investigation Division",
		ANNOUNCER_AIMLESS
	)

/// Calculate payment for unlocking fields
/// Arguments:
/// * newly_unlocked_fields - List of field names that were just unlocked
/// Returns: Payment amount in credits
/datum/distortion_investigation/proc/CalculatePayment(list/newly_unlocked_fields)
	if(!LAZYLEN(newly_unlocked_fields))
		return 0

	var/base_payment_per_field = 500 // Base payment for each field unlocked
	var/total_payment = LAZYLEN(newly_unlocked_fields) * base_payment_per_field

	// TODO: Implement tier completion bonus tracking
	// Would need to track which tiers have been completed to avoid double-payment

	return total_payment

/// Mark investigation as complete
/datum/distortion_investigation/proc/CompleteInvestigation()
	if(!active)
		return

	SEND_SIGNAL(src, COMSIG_INVESTIGATION_COMPLETED)

	priority_announce(
		"Investigation Complete: Full profile constructed. Distortion location triangulated. Contact Hunter's Guild for deployment authorization.",
		"Hunter's Guild - Investigation Division",
		ANNOUNCER_AIMLESS
	)

/// Add a spawned clue to tracking
/// Arguments:
/// * clue - The clue object that was spawned
/datum/distortion_investigation/proc/RegisterSpawnedClue(obj/item/clue/clue)
	if(!clue)
		return

	spawned_clues += clue
	clue.linked_investigation = src

/// Remove a clue from tracking (when destroyed)
/// Arguments:
/// * clue - The clue object being removed
/datum/distortion_investigation/proc/UnregisterSpawnedClue(obj/item/clue/clue)
	if(!clue)
		return

	spawned_clues -= clue

/// Get the value of a trait if unlocked, or "LOCKED" if not
/// Arguments:
/// * trait_name - Name of the trait to get
/// Returns: The trait value or "[LOCKED]"
/datum/distortion_investigation/proc/GetTraitDisplay(trait_name)
	if(!IsFieldUnlocked(trait_name))
		return "\[LOCKED\]"

	if(trait_name in profile_data)
		return profile_data[trait_name]

	return "\[ERROR\]"

/// Cleanup when investigation ends
/datum/distortion_investigation/Destroy()
	// Clean up all spawned clues
	for(var/obj/item/clue/clue in spawned_clues)
		clue.linked_investigation = null

	spawned_clues = null
	unlocked_fields = null
	profile_data = null
	config = null
	active = FALSE

	return ..()
