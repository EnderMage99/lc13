// =============================================
// Prostheti Innovations — Minigame Data Definitions
// =============================================
// Effect definitions (tags + attribute modifiers), client pentagon profiles,
// and attribute metadata for the augment design minigame.
//
// Pentagon System: 5 core attributes (Lethality, Endurance, Agility, Control,
// Efficiency) define an augment's profile. Players shape their pentagon by
// adding effects. Clients have hidden pentagons — overlap determines profit.

// =============================================
// Pentagon Attribute Definitions
// =============================================

/// The 5 core attributes that form the pentagon chart.
GLOBAL_LIST_INIT(prostheti_attributes, list("lethality", "endurance", "agility", "control", "efficiency"))

/// Display names for each attribute.
GLOBAL_LIST_INIT(prostheti_attribute_names, list(\
	"lethality"  = "Lethality",\
	"endurance"  = "Endurance",\
	"agility"    = "Agility",\
	"control"    = "Control",\
	"efficiency" = "Efficiency"\
))

/// Hex colors for pentagon chart rendering.
GLOBAL_LIST_INIT(prostheti_attribute_colors, list(\
	"lethality"  = "#CC4444",\
	"endurance"  = "#4488CC",\
	"agility"    = "#44AA44",\
	"control"    = "#AA44AA",\
	"efficiency" = "#DDAA00"\
))

/// Base attributes granted by each form type. All start at 1, form adds +1 to two.
GLOBAL_LIST_INIT(prostheti_form_attributes, list(\
	"prosthetic" = list("lethality" = 1, "endurance" = 1, "agility" = 0, "control" = 0, "efficiency" = 0),\
	"tattoo"     = list("lethality" = 0, "endurance" = 0, "agility" = 1, "control" = 1, "efficiency" = 0)\
))

// =============================================
// Tag Definitions
// =============================================

/// All available effect tags.
GLOBAL_LIST_INIT(prostheti_all_tags, list("defensive", "offensive", "healing", "bleed", "overheat", "tremor", "on-kill", "support", "risky"))

/// Tag display colors for TGUI badges.
GLOBAL_LIST_INIT(prostheti_tag_colors, list(\
	"defensive" = "#4488CC",\
	"offensive" = "#CC4444",\
	"healing"   = "#44AA44",\
	"bleed"     = "#AA2222",\
	"overheat"  = "#DD8800",\
	"tremor"    = "#886644",\
	"on-kill"   = "#9944AA",\
	"support"   = "#44AAAA",\
	"risky"     = "#888888"\
))

// =============================================
// Effect Definitions
// =============================================
// Each effect maps to: tags (list), attributes (assoc list of modifiers),
// and optionally a "special" (conditional bonus when an attribute exceeds
// a threshold).
//
// Attribute values typically range -3 to +4. Most effects touch 2-3 attributes.
// The "special" field has: condition (attribute name), threshold (number),
// bonus (assoc list of attribute modifiers applied while condition is met).

GLOBAL_LIST_INIT(prostheti_effect_definitions, init_prostheti_effect_definitions())

/// Builds the assoc list mapping effect IDs to their definitions.
/proc/init_prostheti_effect_definitions()
	return list(
		// =====================
		// --- Defensive ---
		// =====================
		"ES_red" = list(
			"tags" = list("defensive"),
			"attributes" = list("endurance" = 2, "lethality" = -1),
		),
		"ES_black" = list(
			"tags" = list("defensive"),
			"attributes" = list("endurance" = 2, "agility" = -1),
		),
		"ES_white" = list(
			"tags" = list("defensive"),
			"attributes" = list("endurance" = 2, "control" = 1, "lethality" = -1),
		),
		"defensive_preparations" = list(
			"tags" = list("defensive", "support"),
			"attributes" = list("endurance" = 2, "control" = 2, "efficiency" = 1, "lethality" = -1),
		),
		"cooling_systems" = list(
			"tags" = list("defensive"),
			"attributes" = list("endurance" = 2, "efficiency" = 1),
		),
		"stalwart_form" = list(
			"tags" = list("defensive"),
			"attributes" = list("endurance" = 4, "agility" = -3),
			"special" = list("condition" = "endurance", "threshold" = 8, "bonus" = list("lethality" = 1)),
		),
		"fireproof" = list(
			"tags" = list("defensive"),
			"attributes" = list("endurance" = 2, "efficiency" = -1),
		),

		// =====================
		// --- Offensive ---
		// =====================
		"struggling_strength" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 3, "endurance" = -2),
		),
		"ar_red" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 2),
		),
		"ar_black" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 2, "control" = 1, "efficiency" = -1),
		),
		"dual_wield" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 3, "agility" = 1, "control" = -2),
		),
		"unstable" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 3, "control" = -1, "efficiency" = -2),
		),
		"shattering_mind_red" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 2, "agility" = 1, "endurance" = -1),
		),
		"shattering_mind_white" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 2, "control" = 1, "endurance" = -1),
		),
		"shattering_mind_black" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 2, "efficiency" = 1, "endurance" = -1),
		),
		"inner_ardor" = list(
			"tags" = list("offensive", "overheat"),
			"attributes" = list("lethality" = 2, "efficiency" = -1),
			"special" = list("condition" = "lethality", "threshold" = 8, "bonus" = list("control" = 2)),
		),
		"ink_over" = list(
			"tags" = list("offensive", "bleed"),
			"attributes" = list("lethality" = 2, "agility" = 1, "endurance" = -1),
		),

		// =====================
		// --- Healing ---
		// =====================
		"regeneration" = list(
			"tags" = list("healing"),
			"attributes" = list("endurance" = 2, "efficiency" = 1),
		),
		"tranquility" = list(
			"tags" = list("healing"),
			"attributes" = list("endurance" = 1, "efficiency" = 2, "lethality" = -1),
		),
		"regenerative_warmth" = list(
			"tags" = list("healing", "overheat"),
			"attributes" = list("endurance" = 2, "efficiency" = 1, "control" = -1),
		),
		"blood_cycler" = list(
			"tags" = list("healing", "bleed"),
			"attributes" = list("endurance" = 1, "efficiency" = 1, "agility" = 1),
		),

		// =====================
		// --- Bleed ---
		// =====================
		"gashing_wounds" = list(
			"tags" = list("bleed"),
			"attributes" = list("lethality" = 1, "agility" = 2, "endurance" = -1),
		),
		"backstabber" = list(
			"tags" = list("bleed", "offensive"),
			"attributes" = list("lethality" = 2, "agility" = 2, "endurance" = -2),
		),
		"blood_jaunt" = list(
			"tags" = list("bleed", "offensive"),
			"attributes" = list("lethality" = 2, "agility" = 1, "efficiency" = -1),
		),
		"sanguine_desire" = list(
			"tags" = list("bleed", "healing"),
			"attributes" = list("lethality" = 1, "endurance" = 1, "agility" = 1, "efficiency" = -1),
		),
		"hemomaniac" = list(
			"tags" = list("bleed"),
			"attributes" = list("lethality" = 2, "agility" = 1, "control" = -1),
		),
		"bleed_vigor" = list(
			"tags" = list("bleed", "offensive"),
			"attributes" = list("lethality" = 3, "agility" = 1, "endurance" = -2),
		),
		"crimson_cascade" = list(
			"tags" = list("bleed", "offensive"),
			"attributes" = list("lethality" = 3, "agility" = 2, "endurance" = -2, "control" = -1),
			"special" = list("condition" = "lethality", "threshold" = 7, "bonus" = list("agility" = 1)),
		),
		"faint_drain" = list(
			"tags" = list("bleed", "support"),
			"attributes" = list("lethality" = 1, "control" = 1, "efficiency" = 1, "endurance" = -1),
		),
		"acidic_blood" = list(
			"tags" = list("bleed"),
			"attributes" = list("lethality" = 2, "agility" = 1, "efficiency" = -1),
		),

		// =====================
		// --- Overheat ---
		// =====================
		"scorching_mind" = list(
			"tags" = list("overheat"),
			"attributes" = list("lethality" = 2, "control" = 1, "efficiency" = -1),
		),
		"stigmatize" = list(
			"tags" = list("overheat"),
			"attributes" = list("control" = 2, "lethality" = 1, "efficiency" = -1),
		),
		"brandish_the_flame" = list(
			"tags" = list("overheat", "offensive"),
			"attributes" = list("lethality" = 3, "control" = 1, "efficiency" = -2),
		),
		"combustion" = list(
			"tags" = list("overheat", "offensive"),
			"attributes" = list("lethality" = 3, "agility" = 1, "efficiency" = -2),
		),
		"pyromaniac" = list(
			"tags" = list("overheat"),
			"attributes" = list("lethality" = 2, "control" = 2, "efficiency" = -2),
			"special" = list("condition" = "lethality", "threshold" = 6, "bonus" = list("efficiency" = 1)),
		),
		"spreading_embers" = list(
			"tags" = list("overheat"),
			"attributes" = list("lethality" = 2, "control" = 1, "efficiency" = -1),
		),
		"burn_vigor" = list(
			"tags" = list("overheat", "offensive"),
			"attributes" = list("lethality" = 3, "endurance" = -1, "efficiency" = -1),
		),
		"rekindled_flame" = list(
			"tags" = list("overheat"),
			"attributes" = list("lethality" = 1, "endurance" = 1, "efficiency" = -1),
		),
		"force_of_a_wildfire" = list(
			"tags" = list("overheat", "on-kill"),
			"attributes" = list("lethality" = 3, "agility" = 1, "efficiency" = -2),
		),

		// =====================
		// --- Tremor ---
		// =====================
		"slothful_decay" = list(
			"tags" = list("tremor"),
			"attributes" = list("control" = 2, "endurance" = 1, "agility" = -2),
		),
		"earthquake" = list(
			"tags" = list("tremor", "offensive"),
			"attributes" = list("control" = 2, "lethality" = 2, "agility" = -2),
		),
		"tremor_break" = list(
			"tags" = list("tremor"),
			"attributes" = list("control" = 2, "endurance" = 1, "agility" = -1),
		),
		"tremor_burst" = list(
			"tags" = list("tremor"),
			"attributes" = list("control" = 3, "agility" = -2),
		),
		"reflective_tremor" = list(
			"tags" = list("tremor", "defensive"),
			"attributes" = list("control" = 2, "endurance" = 2, "agility" = -2),
		),
		"time_moratorium" = list(
			"tags" = list("tremor"),
			"attributes" = list("control" = 3, "efficiency" = 1, "agility" = -3),
			"special" = list("condition" = "control", "threshold" = 8, "bonus" = list("efficiency" = 2)),
		),
		"tremor_everlasting" = list(
			"tags" = list("tremor"),
			"attributes" = list("control" = 2, "endurance" = 2, "agility" = -2),
		),
		"tremor_deterioration" = list(
			"tags" = list("tremor"),
			"attributes" = list("control" = 2, "lethality" = 1, "agility" = -1),
		),
		"vibroweld_morph_combat_effect" = list(
			"tags" = list("tremor"),
			"attributes" = list("control" = 2, "endurance" = 1, "agility" = -1),
		),
		"tremor_ruin" = list(
			"tags" = list("tremor", "offensive"),
			"attributes" = list("control" = 2, "lethality" = 2, "agility" = -2, "efficiency" = -1),
		),
		"stoneward_form" = list(
			"tags" = list("tremor", "support"),
			"attributes" = list("control" = 3, "endurance" = 2, "agility" = -3),
			"special" = list("condition" = "endurance", "threshold" = 7, "bonus" = list("control" = 1)),
		),
		"unstable_inertia" = list(
			"tags" = list("tremor", "risky"),
			"attributes" = list("control" = 2, "lethality" = 1, "agility" = -1, "efficiency" = -1),
		),

		// =====================
		// --- On-Kill ---
		// =====================
		"absorption" = list(
			"tags" = list("on-kill", "healing"),
			"attributes" = list("lethality" = 1, "efficiency" = 2, "control" = -1),
		),
		"brutalize" = list(
			"tags" = list("on-kill", "offensive"),
			"attributes" = list("lethality" = 3, "efficiency" = 1, "control" = -2),
		),
		"flesh_morphing" = list(
			"tags" = list("on-kill", "support"),
			"attributes" = list("endurance" = 2, "efficiency" = 1, "control" = 1, "lethality" = -1),
		),
		"reclaimed_flame" = list(
			"tags" = list("on-kill", "healing"),
			"attributes" = list("lethality" = 1, "endurance" = 1, "efficiency" = 2, "control" = -1),
		),
		"blood_rush" = list(
			"tags" = list("on-kill", "bleed"),
			"attributes" = list("lethality" = 2, "agility" = 1, "control" = -1),
		),

		// =====================
		// --- Risky / Negative ---
		// =====================
		"paranoid" = list(
			"tags" = list("risky"),
			"attributes" = list("agility" = 1, "control" = -2, "endurance" = -1),
		),
		"bus" = list(
			"tags" = list("risky"),
			"attributes" = list("lethality" = -2, "agility" = -2),
		),
		"overheated" = list(
			"tags" = list("risky", "overheat"),
			"attributes" = list("lethality" = 1, "efficiency" = -3),
		),
		"thanatophobia" = list(
			"tags" = list("risky"),
			"attributes" = list("endurance" = -2, "control" = -1),
		),
		"pacifist" = list(
			"tags" = list("risky"),
			"attributes" = list("lethality" = -3, "control" = 1),
		),
		"struggling_weakness" = list(
			"tags" = list("risky"),
			"attributes" = list("lethality" = -2, "endurance" = -1),
		),
		"struggling_fragility" = list(
			"tags" = list("risky"),
			"attributes" = list("endurance" = -3, "lethality" = -1),
		),
		"algophobia" = list(
			"tags" = list("risky"),
			"attributes" = list("agility" = -2, "control" = -1),
		),
		"weak_arms" = list(
			"tags" = list("risky"),
			"attributes" = list("lethality" = -2, "agility" = -1),
		),
		"annoyance" = list(
			"tags" = list("risky"),
			"attributes" = list("control" = -2, "lethality" = -1),
		),
		"allodynia" = list(
			"tags" = list("risky", "bleed"),
			"attributes" = list("lethality" = 1, "endurance" = -2, "agility" = -1),
		),
		"internal_vibrations" = list(
			"tags" = list("risky", "tremor"),
			"attributes" = list("control" = 1, "agility" = -2, "endurance" = -1),
		),
		"scalding_skin" = list(
			"tags" = list("risky", "overheat"),
			"attributes" = list("lethality" = 1, "endurance" = -1, "efficiency" = -2),
		),
		"open_wound" = list(
			"tags" = list("risky", "bleed"),
			"attributes" = list("agility" = 1, "endurance" = -2, "efficiency" = -1),
		),
	)

// =============================================
// Client Type Definitions — Hidden Pentagons
// =============================================
// Each client has a hidden attribute pentagon that the player tries to match.
// The "hint" field gives flavor text that implies what stats they value.
// The "required_tags" field lists tags that MUST be present (shown to player).
// The "attributes" field is the client's pentagon — hidden until results.

GLOBAL_LIST_INIT(prostheti_client_types, init_prostheti_client_types())

/// Builds the list of client type definitions for the minigame.
/proc/init_prostheti_client_types()
	return list(
		list(
			"name" = "Zwei Patrol Squad",
			"desc" = "Association-standard patrol augments. Defensive, reliable, nothing flashy.",
			"hint" = "We need augments that keep our officers standing through long patrols. Endurance is everything — and they need to maintain formation.",
			"rank_min" = 3,
			"rank_max" = 4,
			"required_tags" = list("defensive"),
			"attributes" = list("lethality" = 3, "endurance" = 9, "agility" = 3, "control" = 6, "efficiency" = 4),
			"is_fixer" = TRUE,
		),
		list(
			"name" = "Backstreets Brawler",
			"desc" = "Cheap gear for street fights. Hit hard, bleed harder, worry about the consequences later.",
			"hint" = "Speed is everything in the Backstreets. If you can't dodge, you're dead. And when you do hit, make it count.",
			"rank_min" = 1,
			"rank_max" = 2,
			"required_tags" = list("offensive"),
			"attributes" = list("lethality" = 7, "endurance" = 3, "agility" = 8, "control" = 2, "efficiency" = 3),
			"is_fixer" = FALSE,
		),
		list(
			"name" = "Seven Association Investigator",
			"desc" = "Precision tools for field investigators. Control the fight, don't let it control you.",
			"hint" = "Precision. Control. Our operatives don't need brute force — they need to incapacitate targets without causing collateral.",
			"rank_min" = 3,
			"rank_max" = 5,
			"required_tags" = list("tremor"),
			"attributes" = list("lethality" = 2, "endurance" = 4, "agility" = 3, "control" = 9, "efficiency" = 6),
			"is_fixer" = TRUE,
		),
		list(
			"name" = "Budget Freelancer",
			"desc" = "Anything goes as long as it's cheap. Downsides are features, not bugs.",
			"hint" = "Look, I can't afford anything fancy. Just give me something reliable that won't drain my account every time I use it.",
			"rank_min" = 1,
			"rank_max" = 2,
			"required_tags" = list(),
			"attributes" = list("lethality" = 3, "endurance" = 3, "agility" = 3, "control" = 3, "efficiency" = 9),
			"is_fixer" = FALSE,
		),
		list(
			"name" = "Cinq Association Duelist",
			"desc" = "Premium combat augments for elite duelists. Maximum offensive power, no drawbacks.",
			"hint" = "One strike. That's all a real duelist needs. Maximum lethality, maximum speed — leave defense to the amateurs.",
			"rank_min" = 4,
			"rank_max" = 5,
			"required_tags" = list("offensive"),
			"attributes" = list("lethality" = 10, "endurance" = 2, "agility" = 8, "control" = 4, "efficiency" = 2),
			"is_fixer" = TRUE,
		),
		list(
			"name" = "Hana Association Intern",
			"desc" = "Entry-level augments for medical support. Keep them alive, nothing too aggressive.",
			"hint" = "Our field medics need augments that keep them alive while they work. Survivability first, efficiency second.",
			"rank_min" = 1,
			"rank_max" = 2,
			"required_tags" = list("healing"),
			"attributes" = list("lethality" = 2, "endurance" = 8, "agility" = 3, "control" = 4, "efficiency" = 7),
			"is_fixer" = TRUE,
		),
		list(
			"name" = "Dieci Association Bounty Hunter",
			"desc" = "Kill-focused augments for contract work. Finish the job, loot the spoils.",
			"hint" = "My targets don't stand still. I need something that lets me hit hard and chase them down. Don't care about the rest.",
			"rank_min" = 3,
			"rank_max" = 4,
			"required_tags" = list("on-kill"),
			"attributes" = list("lethality" = 9, "endurance" = 3, "agility" = 7, "control" = 3, "efficiency" = 3),
			"is_fixer" = TRUE,
		),
		list(
			"name" = "Workshop Artisan",
			"desc" = "Utility augments for non-combat work. Support and sustainability over raw power.",
			"hint" = "I'm not a fighter. I need precision tools — fine motor control, energy efficiency. Forget about damage.",
			"rank_min" = 2,
			"rank_max" = 3,
			"required_tags" = list("support"),
			"attributes" = list("lethality" = 1, "endurance" = 3, "agility" = 3, "control" = 8, "efficiency" = 9),
			"is_fixer" = FALSE,
		),
	)
