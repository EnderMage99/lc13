// Distortion Hunting System - Configuration Datum
// Defines a distortion type's investigation parameters

/datum/distortion_config
	/// Display name of the distortion
	var/distortion_name = "Unknown Distortion"

	/// List of evidence type strings this distortion can spawn
	/// Example: list("newspaper_article", "abandoned_briefcase", "public_alert")
	var/list/allowed_evidence_types = list()

	/// Randomized trait pools - surface details that change each investigation
	/// Format: list("trait_name" = list("option1", "option2", "option3"))
	/// Example: list("first_name" = list("Marcus", "David", "Sarah"))
	var/list/randomized_trait_pools = list()

	/// Spawn weights for each clue type (higher = more likely)
	/// Format: list("clue_type" = weight_value)
	/// Example: list("newspaper_article" = 100, "employee_id_basic" = 80)
	var/list/clue_spawn_weights = list()

	/// Tier unlock requirements - which fields must be unlocked to access each tier
	/// Format: list("1" = list("field1", "field2"), "2" = list("field3", "field4"))
	/// Example: list("1" = list("home_district", "gender"), "2" = list("first_name", "last_name"))
	var/list/tier_requirements = list()

/// Base proc to get all clue types for a specific tier
/// Arguments:
/// * tier - The tier number (0, 1, 2, etc.)
/// Returns: List of clue type strings available for that tier
/datum/distortion_config/proc/GetClueTypesForTier(tier)
	var/list/clue_types = list()

	// Get all clue subtypes and check their tier_requirement
	for(var/clue_type in allowed_evidence_types)
		var/obj/item/clue/clue_path = GetCluePathFromType(clue_type)
		if(clue_path)
			var/obj/item/clue/temp = new clue_path()
			if(temp.tier_requirement == tier)
				clue_types += clue_type
			qdel(temp)

	return clue_types

/// Helper proc to convert clue type string to actual path
/// Arguments:
/// * clue_type_string - String identifier like "newspaper_article"
/// Returns: Path to clue type or null
/datum/distortion_config/proc/GetCluePathFromType(clue_type_string)
	// This will be overridden by specific distortion configs
	// Or use a global lookup table
	return null
