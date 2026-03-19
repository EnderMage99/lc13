// =============================================
// Prostheti Innovations — Clyde Wells (Chapter 2)
// =============================================
// Clyde in Chapter 2: business as usual before the mission.
// After the confrontation, cold and matter-of-fact. Believes he did
// the right thing. Will never apologize for surveillance.

/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch2

/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch2/Initialize(mapload)
	. = ..()

	scene_manager.load_scenes(list(
		// --- Pre-Mission Dialogue ---
		"intro" = list(
			"text" = "Good to see you. Production numbers are looking solid — your \
				design work is paying off. Is there something you needed?",
			"actions" = list(
				"business" = list(
					"text" = "How's the company doing?",
					"default_scene" = "business"
				),
				"about_penny" = list(
					"text" = "How's Penny?",
					"default_scene" = "about_penny"
				),
				"leave" = list(
					"text" = "Just checking in. I'll get back to work.",
					"default_scene" = "goodbye"
				),
			)
		),

		"business" = list(
			"text" = "Better than expected, honestly. The augment line you've been \
				prototyping has real commercial potential. Once we finalize the designs, \
				I want to move to mass production. There's a gap in the market right now.",
			"actions" = list(
				"competition" = list(
					"text" = "Any competition?",
					"default_scene" = "competition"
				),
				"back" = list(
					"text" = "Good to hear.",
					"default_scene" = "main_menu"
				),
			)
		),

		"competition" = list(
			"text" = "Always. There's a factory across the district — they've been \
				making noise about a new product line. Nothing I can't handle. \
				Competition is just motivation with a different name.",
			"actions" = list(
				"back" = list(
					"text" = "Confident as always.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_penny" = list(
			"text" = "She's fine. Busy with her own projects — you know how she is. \
				Always moving, always planning. She gets that from her mother.",
			"actions" = list(
				"back" = list(
					"text" = "She seems happy.",
					"default_scene" = "main_menu"
				),
			)
		),

		"main_menu" = list(
			"text" = "Anything else?",
			"actions" = list(
				"business" = list(
					"text" = "About the business...",
					"default_scene" = "business"
				),
				"about_penny" = list(
					"text" = "About Penny...",
					"default_scene" = "about_penny"
				),
				"leave" = list(
					"text" = "That's all. Back to work.",
					"default_scene" = "goodbye"
				),
			)
		),

		"goodbye" = list(
			"text" = "Good. Keep up the work. This company needs people who take \
				their jobs seriously.",
			"actions" = list(
				"back" = list(
					"text" = "Will do.",
					"default_scene" = "main_menu"
				),
			)
		),

		// --- Post-Confrontation Dialogue ---
		"post_intro" = list(
			"text" = "...You're awake. Good.",
			"actions" = list(
				"what_happened" = list(
					"text" = "What happened after we passed out?",
					"default_scene" = "post_what_happened"
				),
				"about_penny_post" = list(
					"text" = "You read her letters.",
					"default_scene" = "post_letters"
				),
				"about_zwei" = list(
					"text" = "You called the Zwei.",
					"default_scene" = "post_zwei"
				),
			)
		),

		"post_what_happened" = list(
			"text" = "The Zwei extracted you. All of you. The competitor factory \
				is dealt with — that's not your concern anymore. You were brought \
				here, treated, and now you're awake. That's all that matters.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_letters" = list(
			"text" = "Yes. For over a year. Every letter she sent to Hector, \
				every one he sent back. I intercepted, copied, and replaced them. \
				I'm not going to pretend I'm sorry for that.",
			"actions" = list(
				"why_not_sorry" = list(
					"text" = "Why not?",
					"default_scene" = "post_why_not_sorry"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_why_not_sorry" = list(
			"text" = "Because my daughter is alive. Because all of you are alive. \
				The moment I learned you entered that factory, I deployed a Zwei \
				extraction team. That cost more Ahn than most Backstreets families \
				see in a decade. I spent it without hesitation. Because I was watching. \
				Because I knew.",
			"actions" = list(
				"cost" = list(
					"text" = "You could have just talked to her.",
					"default_scene" = "post_could_have_talked"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_could_have_talked" = list(
			"text" = "...And said what? 'Stop training'? 'Give up your dream'? \
				She wouldn't have listened. She's too much like her mother for that. \
				So I let her think she had a secret. And I made sure that secret \
				couldn't kill her.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_zwei" = list(
			"text" = "I have a standing contract with the Zwei Association. \
				Emergency extraction, priority response. It's expensive to maintain. \
				It's more expensive not to.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_menu" = list(
			"text" = "If there's nothing else, I have work to do. The company \
				doesn't stop because of one bad day.",
			"actions" = list(
				"about_penny_post" = list(
					"text" = "About the letters...",
					"default_scene" = "post_letters"
				),
				"about_zwei" = list(
					"text" = "About the Zwei...",
					"default_scene" = "post_zwei"
				),
				"leave" = list(
					"text" = "...",
					"default_scene" = "post_goodbye"
				),
			)
		),

		"post_goodbye" = list(
			"text" = "Get some rest. You've earned it.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),
	))

/// Show post-confrontation dialogue after the cutscene.
/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch2/ui_interact(mob/user, datum/tgui/ui)
	if(GetSharedVar("clyde_confrontation_complete"))
		scene_manager.navigate_to_scene(user, "post_intro")
	return ..()
