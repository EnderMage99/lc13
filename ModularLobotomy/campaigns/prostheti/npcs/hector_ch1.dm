// =============================================
// Prostheti Innovations — Hector (Chapter 1)
// =============================================
// Former Fixer, now combat trainer. Starts in nullspace, moved to
// Training Yard during Penny's introduction cutscene.
// After introduction, offers dialogue about Fixer life and suggests
// sparring with Penny for training.
//
// MAP PLACEMENT: Does NOT get a map-placed spawn point.
// Spawned in nullspace by the campaign controller. Penny's IntroductionCutscene
// forceMove()s him to the hector_spawn landmark in the Training Yard.

/mob/living/simple_animal/hostile/ui_npc/prostheti/hector
	name = "Hector"
	desc = "A weathered man with kind eyes and a blade at his hip. He moves like someone who's spent a lifetime fighting."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// PLACEHOLDER
	icon_state = "elliot"	// PLACEHOLDER
	icon_living = "elliot"	// PLACEHOLDER
	portrait = "the-goat.PNG"	// PLACEHOLDER — needs 192x192 Hector portrait
	typing_interval = 55
	random_emotes = "rests a hand on his blade;rolls his shoulder;watches the yard quietly"

/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch1

/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch1/Initialize(mapload)
	. = ..()

	// Set shared NPC vars
	SetSharedVar("hector_conversations", 0)

	scene_manager.load_scenes(list(
		"intro" = list(
			"text" = "So you're the designers Penny's been talking about. \
				She thinks highly of your work — that counts for something.",
			"on_enter" = list(
				"npc.hector_conversations" = "npc.hector_conversations + 1"
			),
			"actions" = list(
				"about_you" = list(
					"text" = "Who are you, exactly?",
					"default_scene" = "about_you"
				),
				"about_training" = list(
					"text" = "What's this training yard for?",
					"default_scene" = "about_training"
				),
				"about_fixers" = list(
					"text" = "Penny said you used to be a Fixer.",
					"default_scene" = "about_fixers"
				),
			)
		),

		"about_you" = list(
			"text" = "Just Hector. No family name worth using anymore. I help Penny \
				with things her father won't — or can't. Combat readiness. \
				Practical knowledge. The kind of lessons you don't learn at a terminal.",
			"actions" = list(
				"back" = list(
					"text" = "Fair enough.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_training" = list(
			"text" = "This yard is where theory meets reality. You can design the \
				finest augment in the City, but if you don't understand what it \
				feels like to fight with it — or against it — you're just guessing.",
			"actions" = list(
				"continue" = list(
					"text" = "How does the training work?",
					"default_scene" = "training_explained"
				),
				"back" = list(
					"text" = "Makes sense.",
					"default_scene" = "main_menu"
				),
			)
		),

		"training_explained" = list(
			"text" = "I've been teaching Penny what I know. She's a quick learner — \
				faster than she has any right to be. If you want to test your designs, \
				challenge her to a sparring match. She'll show you what combat \
				augments really feel like.",
			"actions" = list(
				"back" = list(
					"text" = "I'll give it a try.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_fixers" = list(
			"text" = "I was. Grade 7 — ran contracts for a small office. Retrieval, \
				escort, the occasional breach job. It's honest work if you can \
				stomach the dishonest parts.",
			"actions" = list(
				"why_stop" = list(
					"text" = "Why'd you stop?",
					"default_scene" = "why_stopped"
				),
				"back" = list(
					"text" = "Sounds rough.",
					"default_scene" = "main_menu"
				),
			)
		),

		"why_stopped" = list(
			"text" = "...Everyone stops eventually. Some retire. Some don't get \
				the choice. I got out while I still could. That's all there is to it.",
			"actions" = list(
				"back" = list(
					"text" = "I understand.",
					"default_scene" = "main_menu"
				),
			)
		),

		"main_menu" = list(
			"text" = "What else?",
			"actions" = list(
				"about_you" = list(
					"text" = "Tell me more about yourself.",
					"default_scene" = "about_you"
				),
				"about_penny" = list(
					"text" = "How do you know Penny?",
					"default_scene" = "about_penny"
				),
				"suggest_spar" = list(
					"text" = "Any advice for the sparring?",
					"default_scene" = "spar_advice"
				),
				"leave" = list(
					"text" = "I'll head out.",
					"default_scene" = "goodbye"
				),
			)
		),

		"about_penny" = list(
			"text" = "We grew up together, actually — same stretch of the Backstreets, \
				back when her parents were still doing outreach. I wrote to her about \
				a year ago. Figured I'd see how she turned out. Turns out she wanted \
				to learn about Fixers. Reminded me of someone I used to know.",
			"actions" = list(
				"who" = list(
					"text" = "Who?",
					"default_scene" = "who_remind"
				),
				"back" = list(
					"text" = "She's persistent.",
					"default_scene" = "main_menu"
				),
			)
		),

		"who_remind" = list(
			"text" = "...Doesn't matter. Old story. Point is — she's got potential. \
				More than she knows. Her father doesn't see it, but I do.",
			"actions" = list(
				"back" = list(
					"text" = "Maybe he will, eventually.",
					"default_scene" = "main_menu"
				),
			)
		),

		"spar_advice" = list(
			"text" = "Penny's fast. Faster than you'd expect. Don't try to out-speed \
				her — read her patterns, find the openings. She's still learning, \
				so she'll telegraph her bigger swings. Punish those and you'll do fine.",
			"actions" = list(
				"back" = list(
					"text" = "Thanks for the tip.",
					"default_scene" = "main_menu"
				),
			)
		),

		"goodbye" = list(
			"text" = "Take care. And keep designing — your work matters more than you think.",
			"actions" = list(
				"back" = list(
					"text" = "Thanks, Hector.",
					"default_scene" = "main_menu"
				),
			)
		),
	))

/// Block interaction until the introduction cutscene has played.
/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch1/ui_interact(mob/user, datum/tgui/ui)
	if(!GetSharedVar("introduced_hector"))
		return
	return ..()

/// Block click interaction until introduced.
/mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch1/attack_hand(mob/living/carbon/user)
	if(!GetSharedVar("introduced_hector"))
		to_chat(user, span_warning("[src] doesn't seem to be here right now."))
		return
	return ..()
