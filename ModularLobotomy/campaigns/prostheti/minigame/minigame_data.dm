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
// Workshop Partnership Definitions
// =============================================
// Each workshop has a cost (ahn from profits), a description, a color,
// and a list of exclusive effect IDs that get unlocked when purchased.
// Workshop effects are added to GLOB.prostheti_effect_definitions so
// they work with the existing attribute/special system.

GLOBAL_LIST_INIT(prostheti_workshops, init_prostheti_workshops())

/// Builds the workshop partnership definitions.
/proc/init_prostheti_workshops()
	return list(
		"rosespanner" = list(
			"name" = "Rosespanner Workshop",
			"desc" = "Tremor specialists. Their augments sync vibration frequencies to destabilize opponents — the deeper the tremor, the harder the impact.",
			"color" = "#8B2252",
			"cost" = 300,
			"effects" = list("rs_tremor_sync", "rs_resonant_core", "rs_seismic_link", "rs_sloth_drive"),
		),
		"molar" = list(
			"name" = "Molar Boatworks",
			"desc" = "Scrap alchemists. Olga's crew converts salvaged metals into components worth ten times their weight — efficiency through ingenuity.",
			"color" = "#4A6B8A",
			"cost" = 250,
			"effects" = list("mb_salvage_weave", "mb_scrap_compression", "mb_jury_rig", "mb_lakesteel_frame"),
		),
		"leaflet" = list(
			"name" = "Leaflet Workshop",
			"desc" = "Smoke-integrated augments. Volatile, versatile, and surprisingly affordable. Business comes from all walks of life.",
			"color" = "#556B2F",
			"cost" = 200,
			"effects" = list("lf_puffy_brume", "lf_smoke_overflow", "lf_excess_supply", "lf_madness_engine"),
		),
		"atelier_logic" = list(
			"name" = "Atelier Logic",
			"desc" = "Precision ballistics. Their augments channel kinetic force with surgical accuracy — every shot counts, nothing wasted.",
			"color" = "#B8860B",
			"cost" = 400,
			"effects" = list("al_focused_payload", "al_trigger_discipline", "al_armor_piercing", "al_bullet_economy"),
		),
		"crystal_atelier" = list(
			"name" = "Crystal Atelier",
			"desc" = "Dual-channel augments built for speed and evasion. Hit twice, move fast, never get pinned down.",
			"color" = "#6A5ACD",
			"cost" = 350,
			"effects" = list("ca_twin_edge", "ca_evasion_protocol", "ca_burst_combo", "ca_glass_cannon"),
		),
		"zelkova" = list(
			"name" = "Zelkova Workshop",
			"desc" = "Weapon-alternating augments. Their designs reward switching between modes — momentum builds with every exchange.",
			"color" = "#8B4513",
			"cost" = 350,
			"effects" = list("zk_momentum_shift", "zk_exchange_mastery", "zk_axe_mace_cycle", "zk_escalating_force"),
		),
	)

/// Workshop-exclusive effect definitions. Added to the main definitions
/// when a workshop is unlocked. These are stronger than base effects.
GLOBAL_LIST_INIT(prostheti_workshop_effects, init_prostheti_workshop_effects())

/proc/init_prostheti_workshop_effects()
	return list(
		// --- Rosespanner Workshop (Tremor Specialists) ---
		"rs_tremor_sync" = list(
			"tags" = list("tremor", "support"),
			"attributes" = list("control" = 3, "efficiency" = 2, "agility" = -1),
			"special" = list("condition" = "control", "threshold" = 7, "bonus" = list("endurance" = 2)),
		),
		"rs_resonant_core" = list(
			"tags" = list("tremor", "offensive"),
			"attributes" = list("lethality" = 3, "control" = 2, "endurance" = -2),
		),
		"rs_seismic_link" = list(
			"tags" = list("tremor", "defensive"),
			"attributes" = list("endurance" = 3, "control" = 2, "lethality" = -1),
		),
		"rs_sloth_drive" = list(
			"tags" = list("tremor"),
			"attributes" = list("control" = 4, "agility" = -2, "efficiency" = 1),
			"special" = list("condition" = "control", "threshold" = 9, "bonus" = list("lethality" = 2)),
		),

		// --- Molar Boatworks (Scrap Efficiency) ---
		"mb_salvage_weave" = list(
			"tags" = list("support", "defensive"),
			"attributes" = list("efficiency" = 3, "endurance" = 2, "lethality" = -1),
		),
		"mb_scrap_compression" = list(
			"tags" = list("support"),
			"attributes" = list("efficiency" = 4, "control" = 1, "agility" = -2),
			"special" = list("condition" = "efficiency", "threshold" = 8, "bonus" = list("endurance" = 2)),
		),
		"mb_jury_rig" = list(
			"tags" = list("support", "risky"),
			"attributes" = list("efficiency" = 2, "agility" = 2, "endurance" = -1),
		),
		"mb_lakesteel_frame" = list(
			"tags" = list("defensive", "support"),
			"attributes" = list("endurance" = 3, "efficiency" = 2, "agility" = -2),
		),

		// --- Leaflet Workshop (Smoke/Versatile) ---
		"lf_puffy_brume" = list(
			"tags" = list("offensive", "support"),
			"attributes" = list("lethality" = 2, "control" = 2, "endurance" = -1),
		),
		"lf_smoke_overflow" = list(
			"tags" = list("support"),
			"attributes" = list("efficiency" = 2, "lethality" = 2, "agility" = -1),
			"special" = list("condition" = "efficiency", "threshold" = 7, "bonus" = list("lethality" = 2)),
		),
		"lf_excess_supply" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 3, "efficiency" = 1, "endurance" = -2),
		),
		"lf_madness_engine" = list(
			"tags" = list("risky", "offensive"),
			"attributes" = list("lethality" = 2, "agility" = 2, "endurance" = 2, "control" = -3),
		),

		// --- Atelier Logic (Precision Ranged) ---
		"al_focused_payload" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 4, "control" = 2, "agility" = -2),
			"special" = list("condition" = "lethality", "threshold" = 9, "bonus" = list("efficiency" = 2)),
		),
		"al_trigger_discipline" = list(
			"tags" = list("offensive", "support"),
			"attributes" = list("control" = 3, "lethality" = 2, "endurance" = -2),
		),
		"al_armor_piercing" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 3, "efficiency" = -1, "endurance" = -1),
		),
		"al_bullet_economy" = list(
			"tags" = list("support"),
			"attributes" = list("efficiency" = 3, "control" = 2, "lethality" = -1),
		),

		// --- Crystal Atelier (Speed/Evasion) ---
		"ca_twin_edge" = list(
			"tags" = list("offensive"),
			"attributes" = list("agility" = 3, "lethality" = 2, "endurance" = -2),
		),
		"ca_evasion_protocol" = list(
			"tags" = list("defensive"),
			"attributes" = list("agility" = 4, "endurance" = 1, "control" = -2),
			"special" = list("condition" = "agility", "threshold" = 8, "bonus" = list("lethality" = 2)),
		),
		"ca_burst_combo" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 3, "agility" = 2, "efficiency" = -2),
		),
		"ca_glass_cannon" = list(
			"tags" = list("offensive", "risky"),
			"attributes" = list("lethality" = 4, "agility" = 2, "endurance" = -3),
		),

		// --- Zelkova Workshop (Momentum/Exchange) ---
		"zk_momentum_shift" = list(
			"tags" = list("offensive", "support"),
			"attributes" = list("lethality" = 2, "agility" = 2, "efficiency" = 1, "endurance" = -2),
		),
		"zk_exchange_mastery" = list(
			"tags" = list("support"),
			"attributes" = list("agility" = 3, "control" = 2, "lethality" = -1),
			"special" = list("condition" = "agility", "threshold" = 7, "bonus" = list("efficiency" = 2)),
		),
		"zk_axe_mace_cycle" = list(
			"tags" = list("offensive", "tremor"),
			"attributes" = list("lethality" = 3, "control" = 1, "agility" = -1),
		),
		"zk_escalating_force" = list(
			"tags" = list("offensive"),
			"attributes" = list("lethality" = 2, "endurance" = 2, "efficiency" = -1),
			"special" = list("condition" = "lethality", "threshold" = 8, "bonus" = list("agility" = 2)),
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
		// --- Difficulty 1 (Easy): Rank 1-2 (2-4 EP = 1-2 effects). ---
		// Max reachable per stat: ~5-7. Pentagons capped at 5-6 peak, rest 2-3.
		// Budget Freelancer: flat pentagon, no required tags. Just don't mess up.
		list(
			"name" = "Budget Freelancer",
			"desc" = "Anything goes as long as it's cheap. Downsides are features, not bugs.",
			"hint" = "Look, I can't afford anything fancy. Just give me something that works and won't fall apart.",
			"rank_min" = 1,
			"rank_max" = 2,
			"required_tags" = list(),
			"attributes" = list("lethality" = 3, "endurance" = 3, "agility" = 3, "control" = 3, "efficiency" = 5),
			"is_fixer" = FALSE,
			"difficulty" = 1,
		),
		// Hana Intern: one clear spike (endurance 6), rest low. Healing effects cover it easily.
		list(
			"name" = "Hana Association Intern",
			"desc" = "Entry-level augments for medical support. Keep them alive, nothing too aggressive.",
			"hint" = "Our field medics need augments that keep them alive while they work. Survivability first.",
			"rank_min" = 1,
			"rank_max" = 2,
			"required_tags" = list("healing"),
			"attributes" = list("lethality" = 2, "endurance" = 6, "agility" = 2, "control" = 3, "efficiency" = 4),
			"is_fixer" = TRUE,
			"difficulty" = 1,
		),
		// Backstreets Brawler: two moderate stats (lethality 5, agility 5). Common offensive effects cover both.
		list(
			"name" = "Backstreets Brawler",
			"desc" = "Cheap gear for street fights. Hit hard, bleed harder, worry about the consequences later.",
			"hint" = "Speed is everything in the Backstreets. If you can't dodge, you're dead. And when you do hit, make it count.",
			"rank_min" = 1,
			"rank_max" = 2,
			"required_tags" = list("offensive"),
			"attributes" = list("lethality" = 5, "endurance" = 2, "agility" = 5, "control" = 2, "efficiency" = 2),
			"is_fixer" = FALSE,
			"difficulty" = 1,
		),
		// Rat Courier: agility 6 spike. Bleed tag steers toward agility-boosting bleed effects.
		list(
			"name" = "Rat Courier",
			"desc" = "A Backstreets runner who needs to outpace rival gangs. Speed and grit over finesse.",
			"hint" = "I run packages between Backstreets blocks for whoever's paying. Half the time someone tries to jump me for the cargo. I need to be faster than them and tough enough to keep moving if they clip me. Something with bite — if I'm bleeding, so should they.",
			"rank_min" = 1,
			"rank_max" = 2,
			"required_tags" = list("bleed"),
			"attributes" = list("lethality" = 2, "endurance" = 3, "agility" = 6, "control" = 2, "efficiency" = 3),
			"is_fixer" = FALSE,
			"difficulty" = 1,
		),
		// Oufi Mediator Trainee: control 5 spike. Support tag for precision/enforcement augments.
		list(
			"name" = "Oufi Mediator Trainee",
			"desc" = "Junior Oufi representative. Needs precision augments for contract enforcement detail.",
			"hint" = "I observe deals for the Oufi Association. My augments need to be precise — reading situations, controlling confrontations before they escalate. I'm not there to fight, I'm there to enforce. Reliable tools, nothing extravagant.",
			"rank_min" = 1,
			"rank_max" = 2,
			"required_tags" = list("support"),
			"attributes" = list("lethality" = 2, "endurance" = 3, "agility" = 2, "control" = 5, "efficiency" = 4),
			"is_fixer" = TRUE,
			"difficulty" = 1,
		),

		// --- Difficulty 2 (Medium): Rank 3-4 (6-8 EP = 3-4 effects). ---
		// Max reachable per stat: ~8-11. Pentagons have one 8-9 spike + one 5-6 secondary.
		// Zwei Patrol: 8 endurance spike + 5 control secondary. Defensive effects serve both.
		list(
			"name" = "Zwei Patrol Squad",
			"desc" = "Association-standard patrol augments. Defensive, reliable, nothing flashy.",
			"hint" = "We need augments that keep our officers standing through long patrols. Endurance is everything — and they need to maintain formation.",
			"rank_min" = 3,
			"rank_max" = 4,
			"required_tags" = list("defensive"),
			"attributes" = list("lethality" = 3, "endurance" = 8, "agility" = 3, "control" = 5, "efficiency" = 4),
			"is_fixer" = TRUE,
			"difficulty" = 2,
		),
		// Dieci: 8 lethality + 6 agility. On-kill effects plus some agility picks.
		list(
			"name" = "Dieci Association Bounty Hunter",
			"desc" = "Kill-focused augments for contract work. Finish the job, loot the spoils.",
			"hint" = "My targets don't stand still. I need something that lets me hit hard and chase them down. Don't care about the rest.",
			"rank_min" = 3,
			"rank_max" = 4,
			"required_tags" = list("on-kill"),
			"attributes" = list("lethality" = 8, "endurance" = 3, "agility" = 6, "control" = 3, "efficiency" = 3),
			"is_fixer" = TRUE,
			"difficulty" = 2,
		),
		// Workshop Artisan: 7 control + 6 efficiency. Two uncommon stats — requires thoughtful picks.
		list(
			"name" = "Workshop Artisan",
			"desc" = "Utility augments for non-combat work. Support and sustainability over raw power.",
			"hint" = "I'm not a fighter. I need precision tools — fine motor control, energy efficiency. Forget about damage.",
			"rank_min" = 2,
			"rank_max" = 3,
			"required_tags" = list("support"),
			"attributes" = list("lethality" = 1, "endurance" = 3, "agility" = 3, "control" = 7, "efficiency" = 6),
			"is_fixer" = FALSE,
			"difficulty" = 2,
		),
		// Kurokumo Enforcer: dual 7 spike in lethality + agility. Bleed effects naturally serve both.
		list(
			"name" = "Kurokumo Clan Enforcer",
			"desc" = "Syndicate muscle needs blades that cut deep. Bleed them dry, disappear before backup arrives.",
			"hint" = "In the Kurokumo Clan, you either cut first or you don't come home. I need something that makes every wound count — deep, persistent, the kind that slows a target down. And I need to be quick enough to get out before their friends show up.",
			"rank_min" = 3,
			"rank_max" = 4,
			"required_tags" = list("bleed"),
			"attributes" = list("lethality" = 7, "endurance" = 2, "agility" = 7, "control" = 3, "efficiency" = 3),
			"is_fixer" = FALSE,
			"difficulty" = 2,
		),
		// Devyat' Trunk Operator: dual 7 in control + efficiency. Support effects needed for both.
		list(
			"name" = "Devyat' Trunk Operator",
			"desc" = "AI trunk synchronization augments for the delivery Association. Precision and reliability above all.",
			"hint" = "My trunk and I need to be in perfect sync. Precision motor control for package handling, and enough energy efficiency to run double shifts through the District. Strength is irrelevant — I'm not fighting anyone, I'm delivering.",
			"rank_min" = 3,
			"rank_max" = 4,
			"required_tags" = list("support"),
			"attributes" = list("lethality" = 2, "endurance" = 5, "agility" = 3, "control" = 7, "efficiency" = 7),
			"is_fixer" = TRUE,
			"difficulty" = 2,
		),

		// --- Difficulty 3 (Hard): Rank 3-5 (6-10 EP = 3-5 effects). ---
		// Pentagons have extreme demands: 9+ spike or two stats at 7+.
		// Seven Investigator: 9 control + 6 efficiency. Control is the hardest stat to stack.
		list(
			"name" = "Seven Association Investigator",
			"desc" = "Precision tools for field investigators. Control the fight, don't let it control you.",
			"hint" = "Precision. Control. Our operatives don't need brute force — they need to incapacitate targets without causing collateral.",
			"rank_min" = 3,
			"rank_max" = 5,
			"required_tags" = list("tremor"),
			"attributes" = list("lethality" = 2, "endurance" = 4, "agility" = 3, "control" = 9, "efficiency" = 6),
			"is_fixer" = TRUE,
			"difficulty" = 3,
		),
		// Cinq Duelist: 10 lethality + 8 agility. The only client with a 10. Maximum investment in two stats.
		list(
			"name" = "Cinq Association Duelist",
			"desc" = "Premium combat augments for elite duelists. Maximum offensive power, no drawbacks.",
			"hint" = "One strike. That's all a real duelist needs. Maximum lethality, maximum speed — leave defense to the amateurs.",
			"rank_min" = 4,
			"rank_max" = 5,
			"required_tags" = list("offensive"),
			"attributes" = list("lethality" = 10, "endurance" = 2, "agility" = 8, "control" = 4, "efficiency" = 2),
			"is_fixer" = TRUE,
			"difficulty" = 3,
		),
		// Liu Flame Corps: 9 lethality spike + 6 control secondary. Two required tags (overheat + offensive).
		list(
			"name" = "Liu Association Flame Corps",
			"desc" = "Senior Liu combat augments. Maximum thermal output with sustained battlefield presence.",
			"hint" = "Liu doesn't send the Flame Corps for small jobs. I need an augment that burns hotter than anything on the market — overwhelming firepower with enough resilience to wade through the carnage. Precision matters too. An uncontrolled flame is just an accident.",
			"rank_min" = 4,
			"rank_max" = 5,
			"required_tags" = list("overheat", "offensive"),
			"attributes" = list("lethality" = 9, "endurance" = 5, "agility" = 2, "control" = 6, "efficiency" = 2),
			"is_fixer" = TRUE,
			"difficulty" = 3,
		),
		// N Corp Inquisitor: 8 endurance + 7 control. Tremor tag required. Ironic prosthetics request.
		list(
			"name" = "N Corp Inquisitor",
			"desc" = "Wing-grade suppression augments. Crush resistance with overwhelming force.",
			"hint" = "N Corp doesn't tolerate deviation. I need tools that incapacitate through sheer concussive force — shake them apart from the inside. And I need to endure whatever they throw back. Subtlety is a luxury we don't afford our targets.",
			"rank_min" = 4,
			"rank_max" = 5,
			"required_tags" = list("tremor"),
			"attributes" = list("lethality" = 3, "endurance" = 8, "agility" = 1, "control" = 7, "efficiency" = 5),
			"is_fixer" = FALSE,
			"difficulty" = 3,
		),
		// Grade 2 Veteran: 8 efficiency + 6 agility. Two required tags (offensive + defensive). Breadth challenge.
		list(
			"name" = "Grade 2 Fixer Veteran",
			"desc" = "Veteran Grade 2 Fixer commission. Demands reliable, efficient augments with no wasted potential.",
			"hint" = "Flashy gear gets you killed. I've been doing this for years and the one thing that saves you is consistency. I need an augment that's efficient above all else — stretches every ounce of energy, moves well enough to reposition, and won't fall apart when things go south. Keep it practical.",
			"rank_min" = 4,
			"rank_max" = 5,
			"required_tags" = list("offensive", "defensive"),
			"attributes" = list("lethality" = 4, "endurance" = 4, "agility" = 6, "control" = 3, "efficiency" = 8),
			"is_fixer" = TRUE,
			"difficulty" = 3,
		),
	)
