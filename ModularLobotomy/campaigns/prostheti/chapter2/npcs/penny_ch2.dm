// =============================================
// Prostheti Innovations — Penny Wells (Chapter 2)
// =============================================
// Penny in Chapter 2: settled in Training Yard (no wandering), no duels.
// Nervous before the mission, devastated after the confrontation.
//
// Unlike Ch1, she doesn't patrol or offer sparring. She's focused on
// the upcoming factory infiltration.

/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2
	/// Whether post-confrontation wandering is active
	var/wandering_active = FALSE
	/// Waypoints for wandering (filtered copy of GLOB.penny_waypoints)
	var/list/turf/wandering_waypoints = list()
	/// Current target waypoint
	var/turf/current_waypoint
	/// Dwell timer for pausing at waypoints
	var/dwell_timer_id

/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/Initialize(mapload)
	. = ..()

	scene_manager.load_scenes(list(
		// --- Pre-Mission Dialogue ---
		"intro" = list(
			"text" = "Hey. Hector told you about the factory, right? \
				I know it sounds crazy. But I can do this. I've trained for this.",
			"actions" = list(
				"nervous" = list(
					"text" = "You seem nervous.",
					"default_scene" = "nervous"
				),
				"ready" = list(
					"text" = "You've got this.",
					"default_scene" = "confidence"
				),
				"why" = list(
					"text" = "Why do you want to do this?",
					"default_scene" = "why_do_this"
				),
			)
		),

		"nervous" = list(
			"text" = "I'm not nervous. I'm... focused. There's a difference. \
				Okay, maybe I'm a little nervous. But that's normal, right? \
				Hector says fear is just your body telling you to pay attention.",
			"actions" = list(
				"back" = list(
					"text" = "He's not wrong.",
					"default_scene" = "main_menu"
				),
			)
		),

		"confidence" = list(
			"text" = "Thanks. I mean it. Having you all there makes it... \
				easier. Not easy. Just easier. I won't let you down.",
			"actions" = list(
				"back" = list(
					"text" = "We'll watch each other's backs.",
					"default_scene" = "main_menu"
				),
			)
		),

		"why_do_this" = list(
			"text" = "Because I don't want to spend my whole life behind a desk. \
				Dad built this company from nothing — I respect that. But I want \
				to build something too. Something that's mine. Being a Fixer... \
				it's the first thing that's ever felt right.",
			"actions" = list(
				"dad" = list(
					"text" = "Does your dad know?",
					"default_scene" = "about_dad"
				),
				"back" = list(
					"text" = "I understand.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_dad" = list(
			"text" = "No. And he can't. He'd shut everything down — the training, \
				the letters with Hector, all of it. He thinks the City is too \
				dangerous for me. He doesn't understand that I need to face it, \
				not hide from it.",
			"actions" = list(
				"back" = list(
					"text" = "Your secret's safe.",
					"default_scene" = "main_menu"
				),
			)
		),

		"main_menu" = list(
			"text" = "Talk to Hector when everyone's ready. He'll tell you the plan.",
			"actions" = list(
				"nervous" = list(
					"text" = "How are you feeling?",
					"default_scene" = "nervous"
				),
				"why" = list(
					"text" = "Why be a Fixer?",
					"default_scene" = "why_do_this"
				),
				"leave" = list(
					"text" = "I'll go get ready.",
					"default_scene" = "goodbye"
				),
			)
		),

		"goodbye" = list(
			"text" = "See you out there. And hey — watch out for the augmented workers. \
				Their arms pack more punch than they look.",
			"actions" = list(
				"back" = list(
					"text" = "Will do.",
					"default_scene" = "main_menu"
				),
			)
		),

		// --- Post-Chapter Dialogue (wandering the factory after the confrontation) ---
		"post_intro" = list(
			"text" = "I keep walking past his office. I don't go in. \
				I just... walk past it. Like if I stop moving, I'll have to \
				think about what happened.",
			"actions" = list(
				"how_feeling" = list(
					"text" = "How are you holding up?",
					"default_scene" = "post_holding_up"
				),
				"about_dad" = list(
					"text" = "Have you talked to your dad since?",
					"default_scene" = "post_dad_since"
				),
				"about_hector" = list(
					"text" = "Have you heard from Hector?",
					"default_scene" = "post_hector"
				),
				"what_next" = list(
					"text" = "What are you going to do now?",
					"default_scene" = "post_what_next"
				),
			)
		),

		"post_holding_up" = list(
			"text" = "I'm angry. Not the kind that burns out — the kind that \
				settles in. He had a year of chances to just talk to me like a \
				person. Instead he watched me like a... like an investment. \
				Checking the returns.",
			"actions" = list(
				"he_cares" = list(
					"text" = "He does care about you. In his own way.",
					"default_scene" = "post_his_way"
				),
				"back" = list(
					"text" = "I'm sorry.",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_his_way" = list(
			"text" = "I know he does. That's the worst part. If he didn't care, \
				I could just be angry and move on. But he cares so much he spent \
				a fortune to save my life, and he cares so little he read my \
				private letters for a year without saying a word. How do you \
				hold both of those at the same time?",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_dad_since" = list(
			"text" = "No. He's in his office. Door's open — it's always open. \
				He's not hiding. He just doesn't think he did anything wrong. \
				That's what makes it impossible. He's not sorry. He's not even \
				pretending to be sorry. He thinks he was right.",
			"actions" = list(
				"was_he" = list(
					"text" = "Was he right? About the danger?",
					"default_scene" = "post_was_he_right"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_was_he_right" = list(
			"text" = "About the factory being dangerous? Yeah. Obviously. We \
				almost died in there. But being right about the danger doesn't \
				make him right about everything else. You can save someone's life \
				and still betray their trust. He did both. On the same day.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_hector" = list(
			"text" = "No. He hasn't written. Hasn't shown up. After everything — \
				the training, the letters, the test — nothing. I thought maybe he \
				was giving me space. But it's been long enough that I'm starting \
				to wonder if the space was always the point.",
			"actions" = list(
				"worried" = list(
					"text" = "Are you worried about him?",
					"default_scene" = "post_worried_hector"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_worried_hector" = list(
			"text" = "...Yeah. A little. He set up that whole test, pushed us \
				into it, and then just vanished. That's not like him. Or maybe \
				it is, and I just don't know him as well as I thought. \
				Seems to be a pattern with the men in my life.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_what_next" = list(
			"text" = "I don't know. I still want to be a Fixer. That hasn't \
				changed. If anything, what happened in that factory proved I'm \
				not ready — and that's exactly why I need to keep going. But I \
				can't train with Hector if he's gone. And I can't stay in this \
				building pretending everything's normal.",
			"actions" = list(
				"fixer_still" = list(
					"text" = "You still want to be a Fixer after all that?",
					"default_scene" = "post_still_fixer"
				),
				"back" = list(
					"text" = "Take your time.",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_still_fixer" = list(
			"text" = "More than ever. Those Zwei who saved us — they were \
				incredible. Professional, fast, efficient. That's what real \
				Fixers look like. And I know I'm not there yet. I know. But \
				I saw the gap, and now I know exactly how far I have to go. \
				That's not discouraging. That's a map.",
			"actions" = list(
				"back" = list(
					"text" = "You'll get there.",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_menu" = list(
			"text" = "...Thanks for checking on me. Most people around here \
				just look the other way.",
			"actions" = list(
				"how_feeling" = list(
					"text" = "How are you feeling?",
					"default_scene" = "post_holding_up"
				),
				"about_dad" = list(
					"text" = "About your dad...",
					"default_scene" = "post_dad_since"
				),
				"about_hector" = list(
					"text" = "About Hector...",
					"default_scene" = "post_hector"
				),
				"what_next" = list(
					"text" = "What's next for you?",
					"default_scene" = "post_what_next"
				),
				"leave" = list(
					"text" = "Hang in there, Penny.",
					"default_scene" = "post_goodbye"
				),
			)
		),

		"post_goodbye" = list(
			"text" = "...Yeah. I will. I always do.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),
	))

/// Show post-confrontation dialogue after the cutscene.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/ui_interact(mob/user, datum/tgui/ui)
	if(GetSharedVar("clyde_confrontation_complete"))
		scene_manager.navigate_to_scene(user, "post_intro")
	// Pause wandering while in dialogue
	if(wandering_active)
		walk(src, 0)
		stop_automated_movement = TRUE
		if(dwell_timer_id)
			deltimer(dwell_timer_id)
			dwell_timer_id = null
	return ..()

/// Resume wandering when dialogue closes.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/ui_close(mob/user)
	..()
	if(wandering_active)
		addtimer(CALLBACK(src, PROC_REF(PickNewWaypoint)), rand(5 SECONDS, 10 SECONDS))

// =============================================
// Post-Confrontation Wandering
// =============================================
// After the Clyde confrontation, Penny wanders the factory
// but avoids waypoints near Clyde's office.

/// Activates post-confrontation wandering, filtering out waypoints near Clyde.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/proc/StartPostConfrontationWandering()
	wandering_active = TRUE
	// Copy waypoints and filter out any within 5 tiles of Clyde's spawn
	var/turf/clyde_turf = GLOB.prostheti_npc_landmarks["clyde_spawn"]
	wandering_waypoints = GLOB.penny_waypoints.Copy()
	if(clyde_turf)
		for(var/turf/T in wandering_waypoints)
			if(get_dist(T, clyde_turf) <= 5)
				wandering_waypoints -= T
	// Start wandering
	addtimer(CALLBACK(src, PROC_REF(PickNewWaypoint)), rand(3 SECONDS, 8 SECONDS))

/// Picks a random waypoint and walks toward it.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/proc/PickNewWaypoint()
	if(!wandering_active || !length(wandering_waypoints))
		return
	var/list/available = wandering_waypoints.Copy()
	if(current_waypoint)
		available -= current_waypoint
	if(!length(available))
		available = wandering_waypoints.Copy()
	current_waypoint = pick(available)
	if(current_waypoint)
		walk_to(src, current_waypoint, 1, move_to_delay)
		addtimer(CALLBACK(src, PROC_REF(CheckArrival)), 2 SECONDS)

/// Checks if Penny has arrived at her target waypoint.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/proc/CheckArrival()
	if(!wandering_active || !current_waypoint)
		return
	if(get_dist(get_turf(src), current_waypoint) <= 1)
		walk(src, 0)
		stop_automated_movement = TRUE
		dwell_timer_id = addtimer(CALLBACK(src, PROC_REF(PickNewWaypoint)), rand(30 SECONDS, 60 SECONDS), TIMER_STOPPABLE)
	else
		addtimer(CALLBACK(src, PROC_REF(CheckArrival)), 2 SECONDS)
