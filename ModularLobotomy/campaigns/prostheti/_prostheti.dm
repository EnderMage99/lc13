// =============================================
// Prostheti Innovations Campaign — Core Defines & Controller
// =============================================

// Mission state defines
#define PROSTHETI_MISSION_SIGNUP 1
#define PROSTHETI_MISSION_LOADING 2
#define PROSTHETI_MISSION_ACTIVE 3
#define PROSTHETI_MISSION_COMPLETE 4
#define PROSTHETI_MISSION_READY 5 // Reset after Broken Fate, awaiting re-entry

// Custom signal for the Factory Director's execution trigger (Ch2)
#define COMSIG_DIRECTOR_EXECUTION "prostheti_director_execution"

// Minigame phase defines
#define PROSTHETI_PHASE_BRIEFING 1
#define PROSTHETI_PHASE_DESIGN 2
#define PROSTHETI_PHASE_RESULTS 3
#define PROSTHETI_PHASE_FINAL 4

// Persistence file path
#define FILE_PROSTHETI_PROGRESS "data/ProsthetiProgress.json"

// GLOB lists for campaign landmarks
GLOBAL_LIST_EMPTY(prostheti_npc_landmarks)	// Assoc list: landmark_id -> turf
GLOBAL_LIST_EMPTY(penny_waypoints)			// List of turfs for Penny's patrol
GLOBAL_DATUM(prostheti_campaign, /datum/campaign_controller/prostheti)

// =============================================
// Campaign Controller
// =============================================

/// Manages chapter state for the Prostheti Innovations campaign during a round.
/// Handles NPC spawning/despawning, chapter transitions, and mission references.
/datum/campaign_controller/prostheti
	/// The active chapter number (1-7)
	var/current_chapter = 1
	/// List of NPC mob refs currently on the hub for this chapter
	var/list/mob/current_npcs = list()
	/// TRUE once a chapter has been chosen this round — prevents re-selection
	var/chapter_selected = FALSE
	/// Reference to the active away mission datum, if any
	var/datum/prostheti_mission/active_mission
	/// The z-level of the factory hub map
	var/datum/space_level/hub_level

	/// Chapter data: title, subtitle, text color per chapter
	var/list/chapter_data = list(
		"1" = list("title" = "Polished Surfaces", "subtitle" = "The Job", "color" = "#FFD700"),
		"2" = list("title" = "Paper Walls", "subtitle" = "The Test", "color" = "#C0C0C0"),
		"3" = list("title" = "Dead Letters", "subtitle" = "Roadside Rush", "color" = "#8B0000"),
		"4" = list("title" = "Old Debts", "subtitle" = "The Shop", "color" = "#8B4513"),
		"5" = list("title" = "Boiling Point", "subtitle" = "TBD", "color" = "#FF4500"),
		"6" = list("title" = "Still Water", "subtitle" = "TBD", "color" = "#4682B4"),
		"7" = list("title" = "Ash and Iron", "subtitle" = "TBD", "color" = "#708090"),
	)

	/// Chapter descriptions for the chapter select UI
	var/list/chapter_descriptions = list(
		"1" = "Begin your employment at Prostheti Innovations.",
		"2" = "Hector proposes a dangerous test.",
		"3" = "Intercept a shipment on the road.",
		"4" = "Investigate an address from the evidence.",
		"5" = "TBD",
		"6" = "TBD",
		"7" = "TBD",
	)

/datum/campaign_controller/prostheti/New()
	GLOB.prostheti_campaign = src

/datum/campaign_controller/prostheti/Destroy()
	if(GLOB.prostheti_campaign == src)
		GLOB.prostheti_campaign = null
	active_mission = null
	for(var/mob/M in current_npcs)
		qdel(M)
	current_npcs.Cut()
	return ..()

/// Qdels all current chapter NPCs and spawns the correct NPC set for the given chapter.
/// Each chapter is independent — no cumulative state needed.
/datum/campaign_controller/prostheti/proc/InitializeAtChapter(chapter_number)
	// Clean up existing NPCs
	for(var/mob/M in current_npcs)
		qdel(M)
	current_npcs.Cut()

	current_chapter = chapter_number
	SpawnChapterNPCs(chapter_number)

/// Spawns the correct NPC variant subtypes for the given chapter at their landmark positions.
/datum/campaign_controller/prostheti/proc/SpawnChapterNPCs(chapter_number)
	switch(chapter_number)
		if(1)
			// Chapter 1: Clyde on Design Floor, Penny on Design Floor (wanders), Hector in nullspace
			var/turf/clyde_turf = GLOB.prostheti_npc_landmarks["clyde_spawn"]
			var/turf/penny_turf = GLOB.prostheti_npc_landmarks["penny_spawn"]
			if(clyde_turf)
				var/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch1/clyde = new(clyde_turf)
				clyde.campaign = src
				current_npcs += clyde
			if(penny_turf)
				var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/penny = new(penny_turf)
				penny.campaign = src
				current_npcs += penny
			// Hector spawns in nullspace — moved to Training Yard during intro scene
			var/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch1/hector = new(null)
			hector.campaign = src
			current_npcs += hector
		// Chapters 2-7: will be added in future implementations
		// if(2)
		//     ...

/// Called when a chapter's objectives are met.
/// Saves progress, plays transition blurb, cleans up, advances to next chapter.
/datum/campaign_controller/prostheti/proc/CompleteChapter(chapter_number)
	// Save progress for all players on the hub z-level
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.client || !H.ckey)
			continue
		if(hub_level && H.z == hub_level.z_value)
			SSpersistence.UpdateProsthetiProgress(H.ckey, chapter_number)

	// Play chapter transition blurb to all players on the hub
	var/list/clients = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.client && hub_level && H.z == hub_level.z_value)
			clients += H.client
	var/next_chapter = chapter_number + 1
	if(next_chapter <= 7)
		ShowChapterBlurb(clients, next_chapter)

	// Clean up away mission z-level if one exists
	if(active_mission)
		qdel(active_mission)
		active_mission = null

	// Advance to next chapter
	if(next_chapter <= 7)
		// Short delay for the blurb to finish displaying
		addtimer(CALLBACK(src, PROC_REF(InitializeAtChapter), next_chapter), 60)
