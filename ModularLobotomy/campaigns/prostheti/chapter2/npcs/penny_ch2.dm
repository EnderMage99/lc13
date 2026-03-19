// =============================================
// Prostheti Innovations — Penny Wells (Chapter 2)
// =============================================
// Penny in Chapter 2: settled in Training Yard (no wandering), no duels.
// Nervous before the mission, devastated after the confrontation.
//
// Unlike Ch1, she doesn't patrol or offer sparring. She's focused on
// the upcoming factory infiltration.

/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2

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

		// --- Post-Confrontation Dialogue (after Clyde revelation) ---
		"post_intro" = list(
			"text" = "...He knew. The whole time, he knew.",
			"actions" = list(
				"ask_how" = list(
					"text" = "Are you okay?",
					"default_scene" = "post_okay"
				),
				"about_letters" = list(
					"text" = "He read your letters?",
					"default_scene" = "post_letters"
				),
			)
		),

		"post_okay" = list(
			"text" = "I don't know. I thought I had something that was mine. \
				The training, the letters, Hector — all of it. Turns out Dad \
				was watching the whole time. Copying every word. For a year.",
			"actions" = list(
				"comfort" = list(
					"text" = "He was trying to protect you.",
					"default_scene" = "post_protect"
				),
				"angry" = list(
					"text" = "That's a violation of your privacy.",
					"default_scene" = "post_violation"
				),
			)
		),

		"post_protect" = list(
			"text" = "Is that what it is? Because it doesn't feel like protection. \
				It feels like he let me think I was free, just so he could watch \
				where I went. That's not protection. That's a cage with invisible bars.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_intro"
				),
			)
		),

		"post_violation" = list(
			"text" = "Yeah. Yeah, it is. But try telling him that. He spent a fortune \
				deploying the Zwei to save us. In his mind, that proves he was right \
				to spy. Because he was there when it mattered. Never mind that he \
				could have just... talked to me.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_intro"
				),
			)
		),

		"post_letters" = list(
			"text" = "Every single one. He intercepted them, copied them, put them \
				back before I noticed. He knew about Hector, the training, the combat \
				drills — everything. And he said nothing. For a year. A whole year.",
			"actions" = list(
				"why_silent" = list(
					"text" = "Why didn't he say anything?",
					"default_scene" = "post_why_silent"
				),
				"back" = list(
					"text" = "I'm sorry, Penny.",
					"default_scene" = "post_intro"
				),
			)
		),

		"post_why_silent" = list(
			"text" = "He said combat skills are 'useful for a CEO.' That he \
				hoped I'd come to my senses on my own. He wasn't watching me \
				because he was worried. He was watching me to see if I'd give up. \
				And when I didn't — he just... waited.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "post_intro"
				),
			)
		),
	))

/// Show post-confrontation dialogue after the cutscene.
/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/ui_interact(mob/user, datum/tgui/ui)
	if(GetSharedVar("clyde_confrontation_complete"))
		scene_manager.navigate_to_scene(user, "post_intro")
	return ..()
