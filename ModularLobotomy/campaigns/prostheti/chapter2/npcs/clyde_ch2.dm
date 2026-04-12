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

		// --- Post-Chapter Dialogue (back in office after the confrontation) ---
		"post_intro" = list(
			"text" = "...Come in. Close the door.",
			"actions" = list(
				"about_penny" = list(
					"text" = "How's Penny?",
					"default_scene" = "post_penny"
				),
				"about_letters" = list(
					"text" = "About the letters...",
					"default_scene" = "post_letters"
				),
				"about_hector" = list(
					"text" = "Hector's gone.",
					"default_scene" = "post_hector"
				),
				"about_company" = list(
					"text" = "What happens to the company now?",
					"default_scene" = "post_company"
				),
			)
		),

		"post_penny" = list(
			"text" = "She's walking the factory floor. Hasn't come to my office \
				since the medical wing. I can see her through the window sometimes. \
				She walks right past. Doesn't look up.",
			"actions" = list(
				"talk_to_her" = list(
					"text" = "Maybe you should go talk to her.",
					"default_scene" = "post_talk_to_her"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_talk_to_her" = list(
			"text" = "And say what? Everything I said in that medical wing was \
				true. I was watching her. I was reading her letters. I did deploy \
				the Zwei. Those are facts. She's angry about facts. You can't \
				apologize for the truth.",
			"actions" = list(
				"truth_hurt" = list(
					"text" = "The truth can still hurt people.",
					"default_scene" = "post_truth_hurts"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_truth_hurts" = list(
			"text" = "...I know that. You think I don't know that? I've watched \
				her walk past this office thirty times today. Each time I think \
				about calling out. Each time I don't. Because the moment I open \
				my mouth, I'll either defend what I did or admit it was wrong. \
				And I'm not sure which answer I'm afraid of.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_letters" = list(
			"text" = "I won't apologize for reading them. I intercepted the first \
				letter because a boy from a competitor company was contacting my \
				daughter. Any CEO would have done the same. But then I kept reading. \
				Not as a CEO. As a father who was too afraid to have a conversation.",
			"actions" = list(
				"afraid" = list(
					"text" = "Afraid of what?",
					"default_scene" = "post_afraid"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_afraid" = list(
			"text" = "...Of hearing her say she was going to become a Fixer \
				no matter what I thought. Because then I'd have to tell her \
				about her mother. About what happened to the last person in this \
				family who believed showing up in person was worth the risk. \
				I haven't had that conversation in eleven years. I wasn't ready \
				to have it with Penny.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_hector" = list(
			"text" = "I noticed. His address is empty. The competitor company \
				has no record of him. Every return address on every letter — dead \
				ends, all of them. Whoever that boy was, he cleaned up after himself \
				very thoroughly.",
			"actions" = list(
				"suspicious" = list(
					"text" = "Doesn't that worry you?",
					"default_scene" = "post_suspicious"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_suspicious" = list(
			"text" = "It terrifies me. A childhood friend who vanishes overnight \
				the moment things go wrong? That's not a boy who moved away. That's \
				someone who was never what he appeared to be. And he had access to \
				my daughter for a year. I should have acted sooner. I should have \
				done more than just watch.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_company" = list(
			"text" = "The company is fine. The Zwei deployment was expensive, but \
				not crippling. Production continues. Patents are on track. The Expo \
				submission deadline is in three weeks. Everything is exactly where \
				it should be. On paper.",
			"actions" = list(
				"on_paper" = list(
					"text" = "On paper?",
					"default_scene" = "post_on_paper"
				),
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_on_paper" = list(
			"text" = "My daughter won't speak to me. A boy I've been monitoring \
				for a year has disappeared without a trace. And I just learned that \
				all the security measures I built — every system, every protocol, \
				every precaution — couldn't stop a single teenager from walking into \
				a death trap. The company is fine. I'm not sure about anything else.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_menu"
				),
			)
		),

		"post_menu" = list(
			"text" = "...Is there something else?",
			"actions" = list(
				"about_penny" = list(
					"text" = "About Penny...",
					"default_scene" = "post_penny"
				),
				"about_hector" = list(
					"text" = "About Hector...",
					"default_scene" = "post_hector"
				),
				"about_company" = list(
					"text" = "About the company...",
					"default_scene" = "post_company"
				),
				"leave" = list(
					"text" = "I'll leave you to it.",
					"default_scene" = "post_goodbye"
				),
			)
		),

		"post_goodbye" = list(
			"text" = "...Thank you. For going with her. For bringing her back. \
				I know I'm not easy to work for right now. But you should know \
				that what you did mattered. Even if no one in this building is \
				in any shape to say it properly.",
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
