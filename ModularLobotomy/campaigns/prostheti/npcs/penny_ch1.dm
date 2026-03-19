// =============================================
// Prostheti Innovations — Penny Wells (Chapter 1)
// =============================================
// Energetic daughter, wanders the factory floor via waypoint patrol system.
// Triggers the Hector introduction cutscene when fixer_designs gate is met.
// After introduction, she stays in the Training Yard permanently.
// Players can challenge her to training duels (Echo Office pattern).
//
// MAP PLACEMENT: Place on the Design Floor.
// Use /obj/effect/landmark/prostheti_npc_spawn/penny for the spawn point.
// Place /obj/effect/landmark/penny_waypoint landmarks across Design & Factory Floor.
// Place /obj/effect/landmark/prostheti_duel/player_spawn/penny and
//       /obj/effect/landmark/prostheti_duel/fixer_spawn/penny in the Training Yard.

/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells
	name = "Penny Wells"
	desc = "A young woman with an infectious energy. She seems to know every corner of this factory."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// TEMP — young female NPC, needs custom Penny sprite
	icon_state = "electic"	// TEMP — Amber Knight stand-in
	icon_living = "electic"	// TEMP
	portrait = "tinkerer.PNG"	// TEMP — needs 192x192 Penny portrait
	typing_interval = 16
	random_emotes = "looks around excitedly;hums a tune;waves at someone on the factory floor"

/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1
	// Duel system — Echo Office pattern
	can_duel = TRUE
	duel_fixer_type = /mob/living/simple_animal/hostile/prostheti/penny_combat
	duel_area_id = "penny"
	beaten_var_name = "beaten_penny"

	// Waypoint patrol system vars
	/// Populated from GLOB.penny_waypoints in Initialize
	var/list/turf/waypoints = list()
	/// Stoppable timer for the dwell-at-waypoint pause
	var/dwell_timer_id
	/// Permanent wandering kill switch — TRUE after introduction scene
	var/settled_in_yard = FALSE
	/// Where she is currently heading
	var/turf/current_waypoint

	// Introduction scene references
	/// Reference to Hector's NPC mob
	var/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch1/hector_npc
	/// The locked door between Factory Floor and Training Yard
	var/obj/machinery/door/training_door
	/// Training Yard destination turf for introduction scene
	var/turf/yard_turf
	/// Turf where Hector spawns during introduction
	var/turf/hector_spawn_turf

	/// Number of fixer designs needed to unlock the introduction trigger
	var/fixer_designs_threshold = 3

	// Adaptive learning system — persists between duels
	/// How many duels Penny has completed (wins + losses)
	var/total_duels = 0
	/// Damage received by type in the last duel
	var/list/last_duel_damage = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	/// Learned resistance coefficients (lower = more resistant, min 0.5)
	var/list/learned_resistances = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	/// What damage type Penny currently deals
	var/learned_damage_type = RED_DAMAGE
	/// Bonus max health from learning (capped at +500)
	var/learned_health_bonus = 0

/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/Initialize(mapload)
	. = ..()

	// Populate waypoints from GLOB
	waypoints = GLOB.penny_waypoints.Copy()

	// Find references — these may be set by landmarks or found by type
	yard_turf = GLOB.prostheti_npc_landmarks["penny_yard_destination"]
	hector_spawn_turf = GLOB.prostheti_npc_landmarks["hector_spawn"]

	// Find Hector NPC (may not exist yet if spawned in nullspace — find later)
	addtimer(CALLBACK(src, PROC_REF(FindReferences)), 2 SECONDS)

	// Set shared NPC vars
	SetSharedVar("introduced_hector", FALSE)
	SetSharedVar("fixer_designs", 0)
	SetSharedVar("training_wins", 0)

	// Start wandering after a short delay
	addtimer(CALLBACK(src, PROC_REF(PickNewWaypoint)), rand(5 SECONDS, 15 SECONDS))

	// Load dialogue scenes
	scene_manager.load_scenes(list(
		"intro" = list(
			"text" = "Hey! You're the new designers, right? I'm Penny — Penny Wells. \
				My dad runs this place. I basically grew up on this factory floor, \
				so if you need anything, just ask!",
			"actions" = list(
				"about_work" = list(
					"text" = "What can you tell us about the work here?",
					"default_scene" = "about_work"
				),
				"about_you" = list(
					"text" = "What do you do around here?",
					"default_scene" = "about_you"
				),
				"about_dad" = list(
					"text" = "Your dad seems... intense.",
					"default_scene" = "about_dad"
				),
			)
		),

		"about_work" = list(
			"text" = "The terminals handle everything! You pick a form, add effects, \
				try to match what the clients want. Dad says the trick is reading the \
				market board carefully — the trending tags tell you what sells. \
				Don't just slap random effects together!",
			"actions" = list(
				"back" = list(
					"text" = "Thanks for the tip.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_you" = list(
			"text" = "A bit of everything? I check the equipment, talk to the couriers, \
				make sure the factory floor is running smooth. Dad says I'm the \
				'operations liaison.' I think he just doesn't want me sitting still.",
			"actions" = list(
				"fixers" = list(
					"text" = "You seem to know a lot about Fixers too.",
					"default_scene" = "about_fixers"
				),
				"back" = list(
					"text" = "Sounds like a lot of work.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_fixers" = list(
			"text" = "I've read about them! The Associations, the grades, the contracts — \
				it's fascinating. Real combat augments, not just factory tools. \
				Someday I want to... well. Nevermind. Dad wouldn't approve.",
			"actions" = list(
				"back" = list(
					"text" = "Maybe someday.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_dad" = list(
			"text" = "He's... yeah. He's like that. Don't take it personally — he's the \
				same with everyone. With me too, honestly. He cares, he just doesn't \
				know how to show it. Or maybe he does know and just... chooses not to.",
			"actions" = list(
				"back" = list(
					"text" = "That's rough.",
					"default_scene" = "main_menu"
				),
			)
		),

		"main_menu" = list(
			"text" = "What else do you want to know?",
			"actions" = list(
				"about_work" = list(
					"text" = "Tell me about the work.",
					"default_scene" = "about_work"
				),
				"about_you" = list(
					"text" = "What do you do around here?",
					"default_scene" = "about_you"
				),
				"about_dad" = list(
					"text" = "Tell me about your dad.",
					"default_scene" = "about_dad"
				),
				"fixer_knowledge" = list(
					"text" = "I've been building augments for Fixers — Zwei squads, Cinq duelists...",
					"visibility_expression" = "npc.fixer_designs >= [fixer_designs_threshold] && !npc.introduced_hector",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(TriggerIntroduction))),
					"default_scene" = "fixer_trigger"
				),
				"duel" = list(
					"text" = "I challenge you to a sparring match!",
					"visibility_expression" = "npc.introduced_hector",
					"default_scene" = "duel_offer"
				),
				"leave" = list(
					"text" = "See you around!",
					"default_scene" = "goodbye"
				),
			)
		),

		"fixer_trigger" = list(
			"text" = "Wait — you've actually been designing for real Fixer contracts? \
				Zwei patrol loadouts, Cinq dueling rigs? That's... that's incredible. \
				Come with me — there's something I want to show you.",
			"actions" = list(
				"follow" = list(
					"text" = "Lead the way.",
					"default_scene" = "main_menu"
				),
			)
		),

		"duel_offer" = list(
			"text" = "A sparring match? You're on! Hector's been teaching me — \
				I want to see how I measure up. Ready?",
			"actions" = list(
				"accept" = list(
					"text" = "Let's do it.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(StartDuel))),
					"default_scene" = "duel_start"
				),
				"decline" = list(
					"text" = "Not right now.",
					"default_scene" = "duel_decline"
				),
			)
		),

		"duel_start" = list(
			"text" = "Don't hold back — I won't!",
			"actions" = list(
				"go" = list(
					"text" = "Here we go!",
					"default_scene" = "main_menu"
				),
			)
		),

		"duel_decline" = list(
			"text" = "No rush! Come find me when you're ready.",
			"actions" = list(
				"back" = list(
					"text" = "Will do.",
					"default_scene" = "main_menu"
				),
			)
		),

		"goodbye" = list(
			"text" = "Don't be a stranger! And use those terminals — \
				Dad notices when people slack off.",
			"actions" = list(
				"back" = list(
					"text" = "Will do.",
					"default_scene" = "main_menu"
				),
			)
		),
	))

/// Finds NPC and object references that may not be available at Initialize time.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/proc/FindReferences()
	// Find Hector
	if(!hector_npc)
		for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch1/H in GLOB.mob_list)
			hector_npc = H
			break

	// Find training yard door
	if(!training_door)
		for(var/obj/machinery/door/D in GLOB.prostheti_npc_landmarks)
			training_door = D
			break
		// Fallback: search by landmark
		if(!training_door)
			var/turf/door_turf = GLOB.prostheti_npc_landmarks["training_door"]
			if(door_turf)
				for(var/obj/machinery/door/D in door_turf)
					training_door = D
					break

// =============================================
// Waypoint Patrol System
// =============================================

/// Picks a random waypoint and walks toward it.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/proc/PickNewWaypoint()
	if(settled_in_yard)
		return
	if(!length(waypoints))
		return

	// Pick a random waypoint, excluding current location
	var/list/available = waypoints.Copy()
	if(current_waypoint)
		available -= current_waypoint
	if(!length(available))
		available = waypoints.Copy()

	current_waypoint = pick(available)
	if(current_waypoint)
		walk_to(src, current_waypoint, 1, move_to_delay)
		// Check for arrival periodically
		addtimer(CALLBACK(src, PROC_REF(CheckArrival)), 2 SECONDS)

/// Checks if Penny has arrived at her target waypoint.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/proc/CheckArrival()
	if(settled_in_yard)
		return
	if(!current_waypoint)
		return

	var/turf/my_turf = get_turf(src)
	if(get_dist(my_turf, current_waypoint) <= 1)
		// Arrived — stop and dwell
		walk(src, 0) // Stop walking
		stop_automated_movement = TRUE
		dwell_timer_id = addtimer(CALLBACK(src, PROC_REF(PickNewWaypoint)), rand(45 SECONDS, 75 SECONDS), TIMER_STOPPABLE)
	else
		// Not there yet — check again
		addtimer(CALLBACK(src, PROC_REF(CheckArrival)), 2 SECONDS)

/// Pause wandering when dialogue opens.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/ui_interact(mob/user, datum/tgui/ui)
	// Kill current movement and dwell timer
	walk(src, 0)
	stop_automated_movement = TRUE
	if(dwell_timer_id)
		deltimer(dwell_timer_id)
		dwell_timer_id = null
	return ..()

/// Resume wandering when dialogue closes.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/ui_close(mob/user)
	..()
	if(!settled_in_yard)
		addtimer(CALLBACK(src, PROC_REF(PickNewWaypoint)), rand(5 SECONDS, 10 SECONDS))

// =============================================
// Introduction Cutscene
// =============================================

/// Called by the fixer_knowledge dialogue action's proc_callback.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/proc/TriggerIntroduction()
	INVOKE_ASYNC(src, PROC_REF(IntroductionCutscene))

/// Full introduction cutscene — Penny leads players to Training Yard, introduces Hector.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/proc/IntroductionCutscene()
	// Lock both NPCs
	in_cutscene = TRUE
	if(hector_npc)
		hector_npc.in_cutscene = TRUE

	// Close all open TGUI sessions
	close_all_tgui()

	// Kill wandering permanently
	if(dwell_timer_id)
		deltimer(dwell_timer_id)
		dwell_timer_id = null
	settled_in_yard = TRUE
	walk(src, 0)

	// Unlock and open the training yard door
	if(training_door)
		training_door.locked = FALSE
		training_door.update_icon()
		training_door.open()

	// Penny speaks aloud
	say("Follow me — there's someone you should meet.")
	SLEEP_CHECK_DEATH(30)

	// Walk toward the training yard
	if(yard_turf)
		walk_to(src, yard_turf, 0, move_to_delay)

	// Wait for Penny to arrive (check periodically)
	var/arrival_attempts = 0
	while(arrival_attempts < 30) // Max ~60 seconds of waiting
		if(yard_turf && get_dist(get_turf(src), yard_turf) <= 2)
			break
		SLEEP_CHECK_DEATH(20)
		arrival_attempts++
	walk(src, 0) // Stop walking

	// Update npc_original_turf so Penny reappears in the yard after duels
	npc_original_turf = get_turf(src)

	// Move Hector from nullspace into the Training Yard
	if(hector_npc && hector_spawn_turf)
		hector_npc.forceMove(hector_spawn_turf)
		hector_npc.speaking_on()

	SLEEP_CHECK_DEATH(25)

	// Face each other for the conversation
	if(hector_npc)
		face_atom(hector_npc)
		hector_npc.face_atom(src)

	// Back-and-forth say() cutscene
	say("Hector! It's been a while.")
	SLEEP_CHECK_DEATH(30)

	if(hector_npc)
		hector_npc.say("Penny. Still dragging strangers to meet me, I see.")
	SLEEP_CHECK_DEATH(30)

	say("They're not strangers — they've been building gear for real Fixers.")
	SLEEP_CHECK_DEATH(30)

	if(hector_npc)
		hector_npc.say("Is that so.")
	SLEEP_CHECK_DEATH(25)

	say("Zwei loadouts, Cinq dueling rigs — the real stuff.")
	SLEEP_CHECK_DEATH(30)

	if(hector_npc)
		hector_npc.say("Designing for Fixers is one thing. Knowing what they need is another.")
	SLEEP_CHECK_DEATH(30)

	say("That's why I brought them here — Hector knows what augments need to survive.")
	SLEEP_CHECK_DEATH(35)

	if(hector_npc)
		hector_npc.say("I don't run jobs anymore, but I can still swing a blade. I'm here if they want to learn.")
	SLEEP_CHECK_DEATH(30)

	say("And I'll spar too — just ask!")
	SLEEP_CHECK_DEATH(25)

	// Set shared state
	SetSharedVar("introduced_hector", TRUE)
	if(hector_npc)
		hector_npc.SetSharedVar("introduced_hector", TRUE)

	// Face south after the conversation
	dir = SOUTH
	if(hector_npc)
		hector_npc.dir = SOUTH

	// Unlock both NPCs
	in_cutscene = FALSE
	if(hector_npc)
		hector_npc.in_cutscene = FALSE

// =============================================
// Duel Victory — Chapter Completion Check
// =============================================

/// Override: check if enough training wins to complete Chapter 1.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/OnDuelVictory(mob/living/winner, total_wins)
	if(total_wins >= 5 && campaign)
		addtimer(CALLBACK(campaign, TYPE_PROC_REF(/datum/campaign_controller/prostheti, CompleteChapter), 1), 30)

// =============================================
// Adaptive Learning System
// =============================================

/// Apply learning data to the freshly-spawned combat mob.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/OnFighterSpawned(mob/living/fighter)
	var/mob/living/simple_animal/hostile/prostheti/penny_combat/P = fighter
	if(!istype(P))
		return
	P.ApplyLearning(src)

/// Record what happened in the duel before the combat mob is deleted.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/OnFighterDefeated(mob/living/fighter, player_won)
	var/mob/living/simple_animal/hostile/prostheti/penny_combat/P = fighter
	if(!istype(P))
		return
	RecordLearning(P)

/// Processes the duel results and updates Penny's learning state for next time.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/proc/RecordLearning(mob/living/simple_animal/hostile/prostheti/penny_combat/fighter)
	total_duels++

	// Copy damage tracking
	last_duel_damage = fighter.damage_received.Copy()

	// Health bonus: +50 per duel, cap +500 (ZAYIN 500 → HE 1000)
	learned_health_bonus = min(total_duels * 50, 500)

	// Resistance adaptation: find most-taken damage type, reduce coeff by 0.05 (min 0.5)
	var/worst_type = RED_DAMAGE
	var/worst_amount = 0
	for(var/dtype in last_duel_damage)
		if(last_duel_damage[dtype] > worst_amount)
			worst_amount = last_duel_damage[dtype]
			worst_type = dtype
	if(worst_amount > 0)
		learned_resistances[worst_type] = max(learned_resistances[worst_type] - 0.05, 0.5)

	// Damage type adaptation: switch to whatever type dealt the most to the player
	var/best_type = RED_DAMAGE
	var/best_outgoing = 0
	for(var/dtype in fighter.damage_dealt)
		if(fighter.damage_dealt[dtype] > best_outgoing)
			best_outgoing = fighter.damage_dealt[dtype]
			best_type = dtype
	if(best_outgoing > 0)
		learned_damage_type = best_type
