// =============================================
// Prostheti Innovations — Hector (Chapter 2)
// =============================================
// Hector proposes the factory infiltration mission. Unlike Ch1 where he
// starts in nullspace, Ch2 Hector is visible in the Training Yard from start.
//
// Dialogue flow:
// 1. Proposal scene: pitch the factory job
// 2. Mission briefing: details + "We're ready" trigger
// 3. Post-mission: reflective dialogue (gates on clyde_confrontation_complete)

/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch2

/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch2/Initialize(mapload)
	. = ..()

	SetSharedVar("proposal_seen", FALSE)
	SetSharedVar("mission_started", FALSE)
	SetSharedVar("clyde_confrontation_complete", FALSE)

	scene_manager.load_scenes(list(
		"intro" = list(
			"text" = "Good — you're all here. I've been thinking about something. \
				Something that could change everything for Penny.",
			"actions" = list(
				"proposal" = list(
					"text" = "What do you have in mind?",
					"default_scene" = "proposal"
				),
				"about_training" = list(
					"text" = "How's the training going?",
					"default_scene" = "about_training"
				),
			)
		),

		"about_training" = list(
			"text" = "She's ready. More than ready, if I'm honest. But training \
				only gets you so far. Sooner or later, you have to face the real thing.",
			"actions" = list(
				"proposal" = list(
					"text" = "What are you suggesting?",
					"default_scene" = "proposal"
				),
			)
		),

		"proposal" = list(
			"text" = "There's a factory on the other side of the district. A competitor \
				of Clyde's — they're developing a new augment line. I want you to break \
				in and destroy their blueprints.",
			"on_enter" = list(
				"npc.proposal_seen" = "TRUE"
			),
			"actions" = list(
				"why" = list(
					"text" = "Why us? Why now?",
					"default_scene" = "why_now"
				),
				"penny_react" = list(
					"text" = "What does Penny think about this?",
					"default_scene" = "penny_reaction"
				),
				"details" = list(
					"text" = "Tell me more about this factory.",
					"default_scene" = "factory_details"
				),
			)
		),

		"why_now" = list(
			"text" = "Because training only proves you can fight in a safe space. \
				If Penny's serious about being a Fixer, she needs to prove she can handle \
				a real job. Not sparring in a yard. It has to be today.",
			"actions" = list(
				"details" = list(
					"text" = "What's the plan?",
					"default_scene" = "factory_details"
				),
			)
		),

		"penny_reaction" = list(
			"text" = "She's nervous. But she agreed. You've seen how she is — once she \
				decides something, she commits. That's what makes her dangerous. \
				And what makes her good.",
			"actions" = list(
				"details" = list(
					"text" = "Alright. What's the plan?",
					"default_scene" = "factory_details"
				),
			)
		),

		"factory_details" = list(
			"text" = "The factory is lightly guarded — mostly augmented workers. \
				Nothing you haven't trained for. Penny will guide you in. \
				Find the director's office, destroy the blueprints, get out. \
				Simple in theory.",
			"actions" = list(
				"concerns" = list(
					"text" = "And if things go wrong?",
					"default_scene" = "concerns"
				),
				"ready" = list(
					"text" = "We're ready. Let's go.",
					"default_scene" = "mission_start",
					"visibility_expression" = "NOT npc.mission_started",
					"proc_callbacks" = list()
				),
			)
		),

		"concerns" = list(
			"text" = "Then you fight your way out. That's the Fixer way. \
				But I don't think it'll come to that. These are factory workers, \
				not Zwei operatives.",
			"actions" = list(
				"ready" = list(
					"text" = "We're ready. Let's go.",
					"default_scene" = "mission_start",
					"visibility_expression" = "NOT npc.mission_started"
				),
				"back" = list(
					"text" = "Let me prepare first.",
					"default_scene" = "main_menu"
				),
			)
		),

		"mission_start" = list(
			"text" = "Good. Penny — you know the way. I'll stay here. \
				This is your test, not mine.",
			"on_enter" = list(
				"npc.mission_started" = "TRUE"
			),
			"actions" = list(
				"leave" = list(
					"text" = "...",
					"default_scene" = "intro"
				),
			)
		),

		"main_menu" = list(
			"text" = "Take your time. But don't take too long — opportunities like \
				this don't wait.",
			"actions" = list(
				"details" = list(
					"text" = "Run me through the plan again.",
					"default_scene" = "factory_details"
				),
				"about_you" = list(
					"text" = "Why aren't you coming with us?",
					"default_scene" = "why_stay"
				),
			)
		),

		"why_stay" = list(
			"text" = "Because this isn't about me. Penny needs to know she can \
				do this without someone holding her hand. And your team — you need \
				to know it too.",
			"actions" = list(
				"back" = list(
					"text" = "Understood.",
					"default_scene" = "main_menu"
				),
			)
		),

		// --- Post-Mission Dialogue (after Clyde confrontation) ---
		"post_mission_intro" = list(
			"text" = "...You're all alive. That's what matters.",
			"visibility_expression" = "npc.clyde_confrontation_complete",
			"actions" = list(
				"what_happened" = list(
					"text" = "The Zwei showed up. Someone called them.",
					"default_scene" = "post_zwei"
				),
				"about_penny" = list(
					"text" = "Penny's a mess. Her dad knew everything.",
					"default_scene" = "post_penny"
				),
			)
		),

		"post_zwei" = list(
			"text" = "The Zwei don't show up without a contract. Someone paid \
				for that rescue — and that kind of deployment doesn't come cheap. \
				Whoever called them cared more about getting you out than about \
				keeping it quiet.",
			"actions" = list(
				"who" = list(
					"text" = "You think it was Clyde?",
					"default_scene" = "post_clyde_theory"
				),
			)
		),

		"post_clyde_theory" = list(
			"text" = "...I think a father who reads his daughter's letters for a year \
				without saying anything is a man who pays attention. Whether that's \
				love or control — I couldn't tell you.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_mission_intro"
				),
			)
		),

		"post_penny" = list(
			"text" = "I know. I know she is. Give her time. She's tougher than \
				she looks — tougher than she knows. This won't break her. \
				It'll just... change the shape of things.",
			"actions" = list(
				"your_fault" = list(
					"text" = "You're the one who sent her in there.",
					"default_scene" = "post_responsibility"
				),
				"back" = list(
					"text" = "I hope you're right.",
					"default_scene" = "post_mission_intro"
				),
			)
		),

		"post_responsibility" = list(
			"text" = "...Yeah. I did. And I'd do it again. Not because I don't \
				care — because I do. She was never going to grow inside these walls. \
				Sometimes the only way forward is through.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_mission_intro"
				),
			)
		),
	))

/// After "We're ready" — spawn the rally point and trigger the mission start cutscene.
/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch2/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	// Check if we just entered the mission_start scene — only fire once
	if(GetSharedVar("mission_started") && !GLOB.prostheti_campaign?.active_mission && !in_cutscene)
		INVOKE_ASYNC(src, PROC_REF(MissionStartCutscene), ui)

/// Brief cutscene when mission starts, then spawns the rally point.
/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch2/proc/MissionStartCutscene(datum/tgui/ui)
	in_cutscene = TRUE
	// Close the player's dialogue UI so they can't click during the cutscene
	close_all_tgui()

	// Find Penny ch2 NPC
	var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/penny
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/P in campaign.current_npcs)
		penny = P
		break
	if(penny)
		penny.in_cutscene = TRUE

	say("Good. Penny — you know the way. I'll stay here. This is your test, not mine.")
	SLEEP_CHECK_DEATH(20)

	if(penny)
		penny.say("You're not coming?")
		SLEEP_CHECK_DEATH(15)

	say("You don't need me for this. Go.")
	SLEEP_CHECK_DEATH(20)

	if(penny)
		penny.in_cutscene = FALSE

	in_cutscene = FALSE

	// Spawn rally point (only if one doesn't already exist)
	var/turf/rally_turf = GLOB.prostheti_npc_landmarks["rally_point_spawn"]
	if(rally_turf && !locate(/obj/structure/mission_rally/factory_infiltration) in rally_turf)
		new /obj/structure/mission_rally/factory_infiltration(rally_turf)

/// Show post-mission dialogue when confrontation is complete.
/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch2/ui_interact(mob/user, datum/tgui/ui)
	if(GetSharedVar("clyde_confrontation_complete"))
		scene_manager.navigate_to_scene(user, "post_mission_intro")
	return ..()
