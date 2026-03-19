// =============================================
// Prostheti Innovations — Clyde Wells (Chapter 1)
// =============================================
// Boss giving you work. Distant father. Stationed in/near his office on the
// Design Floor. Standard branching dialogue about the company, Penny, family.
//
// Progressive dialogue unlocks:
// - Tier 0 (always): work, company, Penny, family basics
// - Tier 1 (after Day 1): factory operations — supply chain, Tres, Backstreets
// - Tier 2 (after Day 2): the industry — Wings, L Corp, Calw
// - Tier 3 (after Day 3): personal history — QC past, stolen blueprints, wife's death, protection
//
// Gated via npc.completed_work_days, set by the minigame controller.
//
// MAP PLACEMENT: Place on the Design Floor near his office.
// Use /obj/effect/landmark/prostheti_npc_spawn/clyde for the spawn point.

/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells
	name = "Clyde Wells"
	desc = "The CEO of Prostheti Innovations. A sharp-eyed man who carries \
		himself with the weight of someone who's made too many difficult decisions."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_32x48.dmi'	// TEMP — corporate suit NPC, needs custom Clyde sprite
	icon_state = "clan_citzen"	// TEMP
	icon_living = "clan_citzen"	// TEMP
	portrait = "rat_leader.PNG"	// TEMP — needs 192x192 Clyde portrait
	typing_interval = 24
	random_emotes = "adjusts his tie;glances toward the factory floor;takes a drag from his cigarette"

/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch1

/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch1/Initialize(mapload)
	. = ..()

	// Set shared NPC vars
	SetSharedVar("asked_about_penny", FALSE)
	SetSharedVar("asked_about_company", FALSE)
	SetSharedVar("asked_about_family", FALSE)
	SetSharedVar("completed_work_days", 0)

	scene_manager.load_scenes(list(

		// =============================================
		// TIER 0 — Always Available
		// =============================================

		"intro" = list(
			"text" = "You must be the new designers. I'm Clyde Wells — I run \
				this operation. Prostheti Innovations builds augments for anyone \
				who can pay. Your job is to design them. Do it well and we'll \
				get along fine.",
			"actions" = list(
				"about_work" = list(
					"text" = "What exactly will we be doing?",
					"default_scene" = "about_work"
				),
				"about_company" = list(
					"text" = "Tell me about Prostheti Innovations.",
					"default_scene" = "about_company"
				),
				"about_penny" = list(
					"text" = "Is that your daughter on the factory floor?",
					"default_scene" = "about_penny"
				),
			)
		),

		"about_work" = list(
			"text" = "You'll use the design terminals on the floor. Each day \
				you'll get a client brief — who's buying, what they want. Build \
				augments that match demand and you'll turn a profit. Build the \
				wrong thing and you're wasting company resources. Simple as that.",
			"actions" = list(
				"understood" = list(
					"text" = "Understood.",
					"default_scene" = "main_menu"
				),
				"more_about_clients" = list(
					"text" = "What kind of clients do we get?",
					"default_scene" = "about_clients"
				),
			)
		),

		"about_clients" = list(
			"text" = "Everyone. Zwei patrol squads need defensive gear. \
				Backstreets brawlers want cheap and nasty. Seven investigators \
				want precision. Cinq duelists want to hit harder than anything \
				else alive. You learn to read what they want, or you don't \
				last here.",
			"actions" = list(
				"back" = list(
					"text" = "Good to know.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_company" = list(
			"text" = "I built this company from nothing. We're not the biggest \
				augment shop in the City, but we're reliable. We've survived \
				things that shut down larger operations.",
			"on_enter" = list(
				"npc.asked_about_company" = TRUE
			),
			"actions" = list(
				"continue" = list(
					"text" = "From nothing?",
					"default_scene" = "about_company_2"
				),
				"back" = list(
					"text" = "Sounds like a solid operation.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_company_2" = list(
			"text" = "...A rented garage and a stubborn refusal to build \
				something I knew would break. That's all it took to start. \
				Everything else came after. Prostheti is mine — every bolt, \
				every blueprint, every ahn in the accounts. That's what matters.",
			"actions" = list(
				"guts" = list(
					"text" = "That takes guts.",
					"default_scene" = "about_company_guts"
				),
				"yours" = list(
					"text" = "Must be nice, owning something that's yours.",
					"default_scene" = "about_company_yours"
				),
				"back" = list(
					"text" = "Fair enough.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_company_guts" = list(
			"text" = "Guts had nothing to do with it. I had no other choice — \
				build something real or keep watching people get hurt by \
				cheap product. Desperation looks a lot like courage \
				from the outside.",
			"actions" = list(
				"back" = list(
					"text" = "Still. Not everyone would've done it.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_company_yours" = list(
			"text" = "...It is. Every late night, every ahn reinvested — \
				that's mine. Don't forget whose name is on the door.",
			"actions" = list(
				"back" = list(
					"text" = "Noted.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_penny" = list(
			"text" = "...Yes. That's Penny. She helps around the factory. \
				Talks to everyone, knows every corner of this building. \
				She's... enthusiastic.",
			"on_enter" = list(
				"npc.asked_about_penny" = TRUE
			),
			"actions" = list(
				"more_about_penny" = list(
					"text" = "She seems to know a lot about augments.",
					"default_scene" = "about_penny_2"
				),
				"back" = list(
					"text" = "She seems nice.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_penny_2" = list(
			"text" = "She's been around augment work her whole life. She'll \
				run this place someday — that's the plan, at least. For now \
				she's learning. Let her ask her questions. It's good for her.",
			"actions" = list(
				"about_family" = list(
					"text" = "Just the two of you?",
					"default_scene" = "about_family"
				),
				"back" = list(
					"text" = "Got it.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_family" = list(
			"text" = "...Yes. Just us.",
			"on_enter" = list(
				"npc.asked_about_family" = TRUE
			),
			"actions" = list(
				"empathy" = list(
					"text" = "That must be tough, raising her alone.",
					"default_scene" = "about_family_empathy"
				),
				"mother" = list(
					"text" = "She ever talk about her mother?",
					"default_scene" = "about_family_mother"
				),
				"back" = list(
					"text" = "I didn't mean to pry.",
					"default_scene" = "about_family_close"
				),
			)
		),

		"about_family_empathy" = list(
			"text" = "...We manage. She's tougher than she looks. Gets that \
				from her mother. ...Was there something else?",
			"actions" = list(
				"back" = list(
					"text" = "No. Sorry.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_family_mother" = list(
			"text" = "...(his jaw tightens) ...Not to me, she doesn't. \
				Was there something else?",
			"actions" = list(
				"back" = list(
					"text" = "Forget I asked.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_family_close" = list(
			"text" = "You didn't. Get back to work.",
			"actions" = list(
				"pushback" = list(
					"text" = "Just making conversation.",
					"default_scene" = "about_family_pushback"
				),
				"back" = list(
					"text" = "Yes, sir.",
					"default_scene" = "main_menu"
				),
			)
		),

		"about_family_pushback" = list(
			"text" = "This isn't a social club. You're here to design augments, \
				not make friends. ...(beat) But I'll remember you asked.",
			"actions" = list(
				"back" = list(
					"text" = "Fair enough.",
					"default_scene" = "main_menu"
				),
			)
		),

		// =============================================
		// MAIN MENU — Hub with progressive unlocks
		// =============================================

		"main_menu" = list(
			"text" = "Anything else?",
			"actions" = list(
				"about_work" = list(
					"text" = "Remind me about the work.",
					"default_scene" = "about_work"
				),
				"about_company" = list(
					"text" = "Tell me more about Prostheti.",
					"visibility_expression" = "NOT npc.asked_about_company",
					"default_scene" = "about_company"
				),
				"about_penny" = list(
					"text" = "About your daughter...",
					"visibility_expression" = "NOT npc.asked_about_penny",
					"default_scene" = "about_penny"
				),
				"factory" = list(
					"text" = "How does this factory actually run?",
					"visibility_expression" = "npc.completed_work_days >= 1",
					"default_scene" = "factory_operations"
				),
				"industry" = list(
					"text" = "What's the augment market like out there?",
					"visibility_expression" = "npc.completed_work_days >= 2",
					"default_scene" = "industry_menu"
				),
				"personal" = list(
					"text" = "You've been at this a long time. How'd you end up here?",
					"visibility_expression" = "npc.completed_work_days >= 3",
					"default_scene" = "personal_menu"
				),
				"leave" = list(
					"text" = "Nothing for now.",
					"default_scene" = "goodbye"
				),
			)
		),

		"goodbye" = list(
			"text" = "Then get to the terminals. We're burning daylight.",
			"actions" = list(
				"back" = list(
					"text" = "On it.",
					"default_scene" = "main_menu"
				),
			)
		),

		// =============================================
		// TIER 1 — After Day 1: Factory Operations
		// =============================================

		"factory_operations" = list(
			"text" = "You want to know how the sausage gets made? Fine. Pick a topic.",
			"actions" = list(
				"supply" = list(
					"text" = "Where do the materials come from?",
					"default_scene" = "factory_supply"
				),
				"tres" = list(
					"text" = "Who regulates all this?",
					"default_scene" = "factory_tres"
				),
				"location" = list(
					"text" = "Why set up shop in the Backstreets?",
					"default_scene" = "factory_location"
				),
				"back" = list(
					"text" = "Just curious.",
					"default_scene" = "main_menu"
				),
			)
		),

		"factory_supply" = list(
			"text" = "Everything comes through middlemen. Base alloys from \
				X Corp distributors — they mine the toughest metals in the \
				City, but getting it here means paying three people between \
				us and the source. Prosthetic components from K Corp's \
				district, when we can get them. Enkephalin used to be \
				cheap — L Corp sold PE-boxes everywhere. Now we buy \
				salvaged stock from scrappers picking through old L Corp \
				branches at triple the old price.",
			"actions" = list(
				"supply_more" = list(
					"text" = "That sounds expensive.",
					"default_scene" = "factory_supply_2"
				),
				"supply_direct" = list(
					"text" = "Ever tried going direct to the source?",
					"default_scene" = "factory_supply_direct"
				),
				"back" = list(
					"text" = "I see.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_supply_direct" = list(
			"text" = "Direct? X Corp doesn't take calls from Backstreets \
				workshops. Their distributors do — for a price. Skip the \
				chain and you get nothing. Trust me, I've tried.",
			"actions" = list(
				"back" = list(
					"text" = "Worth asking.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_supply_2" = list(
			"text" = "It is. Every middleman takes their cut — thirty percent, \
				sometimes more. A Nest workshop buys direct from Wing \
				distributors. We get whatever's left after the Nests have had \
				their fill. That's the Backstreets tax. You pay it or you \
				don't build anything.",
			"actions" = list(
				"unfair" = list(
					"text" = "That's not fair.",
					"default_scene" = "factory_supply_unfair"
				),
				"back" = list(
					"text" = "Makes sense why margins are tight.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_supply_unfair" = list(
			"text" = "'Fair.' ...When you've been down here long enough, \
				you stop using that word. Fair is for the Nests. Down \
				here we deal in what works.",
			"actions" = list(
				"back" = list(
					"text" = "Point taken.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_tres" = list(
			"text" = "Tres Association. They oversee every Workshop in the \
				City — us included. Every augment design we sell has to be \
				registered through them. They review it, they tax it, they \
				send inspectors every quarter to make sure we're not \
				cutting corners.",
			"actions" = list(
				"tres_more" = list(
					"text" = "Sounds like a hassle.",
					"default_scene" = "factory_tres_2"
				),
				"back" = list(
					"text" = "At least there's oversight.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_tres_2" = list(
			"text" = "It is a hassle. But without them, every garage mechanic \
				with a soldering iron would be selling augments that fry your \
				nervous system in a week. I've seen what unregistered gear \
				does to people. Tres keeps the worst of it off the market. \
				Doesn't mean I enjoy their paperwork.",
			"actions" = list(
				"tres_illegal" = list(
					"text" = "What happens if you sell unapproved gear?",
					"default_scene" = "factory_tres_illegal"
				),
				"back" = list(
					"text" = "Fair point.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_tres_illegal" = list(
			"text" = "Best case — Tres shuts you down, confiscates your stock, \
				and you start over with nothing. Worst case — the Head's \
				patent enforcers get involved. And the Head doesn't send \
				cease-and-desist letters. They send Claws.",
			"actions" = list(
				"reckless" = list(
					"text" = "What if the money was worth the risk?",
					"default_scene" = "factory_tres_reckless"
				),
				"back" = list(
					"text" = "I'll stick to the approved list.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_tres_reckless" = list(
			"text" = "(sharp look) Don't get clever. I've watched garage \
				mechanics try selling under Tres's nose. Maybe they pull \
				it off for a month. Then someone's arm fails mid-contract \
				and the trail leads back. ...I didn't hire you to take \
				shortcuts.",
			"actions" = list(
				"back" = list(
					"text" = "Just a hypothetical.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_location" = list(
			"text" = "Money. Setting up in a Nest means Wing sponsorship or \
				a migration permit — which costs more than I made in my first \
				year. Nest rent alone would've sunk me before I sold a single \
				augment. The Backstreets are cheaper. Rougher, but cheaper. \
				And by the time I could've moved, I'd learned the Backstreets \
				are where the people who actually need augments live.",
			"actions" = list(
				"location_risks" = list(
					"text" = "What are the risks?",
					"default_scene" = "factory_location_risks"
				),
				"back" = list(
					"text" = "Makes sense.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_location_risks" = list(
			"text" = "The usual. Break-ins. Syndicate crews who think every \
				business owes them a cut. Clients who'd rather steal a \
				finished augment than pay for one. Couriers who vanish with \
				your shipments. But there's an upside — no Wing breathing \
				down your neck, no feather politics, no executive board \
				telling you what you can and can't build.",
			"actions" = list(
				"worry" = list(
					"text" = "Doesn't that keep you up at night?",
					"default_scene" = "factory_location_worry"
				),
				"confident" = list(
					"text" = "Sounds like you can handle it.",
					"default_scene" = "factory_location_confident"
				),
				"back" = list(
					"text" = "Freedom has its price.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_location_worry" = list(
			"text" = "Worry is a luxury. I plan. Every risk gets a contingency — \
				security contracts, insurance, backup suppliers. The people \
				who lose sleep are the ones who didn't prepare.",
			"actions" = list(
				"back" = list(
					"text" = "Sounds like you've got it covered.",
					"default_scene" = "factory_operations"
				),
			)
		),

		"factory_location_confident" = list(
			"text" = "...(looks you over) We'll see if you still think that \
				after your first Night raid. Confidence is cheap. Preparation \
				isn't.",
			"actions" = list(
				"back" = list(
					"text" = "Looking forward to it.",
					"default_scene" = "factory_operations"
				),
			)
		),

		// =============================================
		// TIER 2 — After Day 2: The Industry
		// =============================================

		"industry_menu" = list(
			"text" = "The augment market. That's a big topic. What specifically?",
			"actions" = list(
				"wings" = list(
					"text" = "How do small shops compete with Wings?",
					"default_scene" = "industry_wings"
				),
				"lcorp" = list(
					"text" = "You mentioned energy costs. What happened?",
					"default_scene" = "industry_lcorp"
				),
				"calw" = list(
					"text" = "Are there other prosthetics workshops like this one?",
					"default_scene" = "industry_calw"
				),
				"back" = list(
					"text" = "Nevermind.",
					"default_scene" = "main_menu"
				),
			)
		),

		"industry_wings" = list(
			"text" = "We don't. Not on volume, not on quality. Wings have \
				Singularity tech — patents protected by the Head itself. If \
				I used Singularity-derived components without authorization, \
				I'd be dead before the week was out. That's not a metaphor. \
				The Head sends Claws for patent violations.",
			"actions" = list(
				"wings_survive" = list(
					"text" = "Then how does Prostheti survive?",
					"default_scene" = "industry_wings_2"
				),
				"back" = list(
					"text" = "That's brutal.",
					"default_scene" = "industry_menu"
				),
			)
		),

		"industry_wings_2" = list(
			"text" = "Flexibility. Custom work. Rush orders. Clients who don't \
				want their name on a Wing purchase order. Fixers who need \
				something modified between jobs and can't wait six weeks for \
				a Nest workshop to process the request. We're faster, we're \
				quieter, and we don't ask questions. That's our edge.",
			"actions" = list(
				"proud" = list(
					"text" = "You sound almost proud.",
					"default_scene" = "industry_wings_proud"
				),
				"back" = list(
					"text" = "Speed over scale.",
					"default_scene" = "industry_menu"
				),
			)
		),

		"industry_wings_proud" = list(
			"text" = "...(pauses) Maybe. We built something real in a city \
				that eats small operations alive. That counts for something. \
				...Don't tell anyone I said that.",
			"actions" = list(
				"back" = list(
					"text" = "Secret's safe.",
					"default_scene" = "industry_menu"
				),
			)
		),

		"industry_lcorp" = list(
			"text" = "L Corp. Lobotomy Corporation — the energy Wing. They \
				produced Enkephalin — stored it in PE-boxes, sold it cheap. \
				Half the City ran on the stuff. Then they collapsed. The \
				White Nights, the Dark Days — whatever it was that happened \
				in District 12. Nobody talks about it. One day L Corp was \
				there. The next, they weren't.",
			"actions" = list(
				"lcorp_impact" = list(
					"text" = "How did that affect Prostheti?",
					"default_scene" = "industry_lcorp_2"
				),
				"back" = list(
					"text" = "I've heard rumors about that.",
					"default_scene" = "industry_menu"
				),
			)
		),

		"industry_lcorp_2" = list(
			"text" = "Enkephalin prices went through the roof overnight. \
				Workshops that depended on cheap PE-boxes had to scramble — \
				buy from Fixers and scrappers picking through collapsed \
				L Corp branches, or find alternative power sources that \
				cost twice as much. People talk about 'Enkephalin Rush' and \
				'Lobotomy Dream' like it's some gold rush. Some shops \
				couldn't adapt. They closed. We survived, but barely. \
				Every ahn I saved on rent went straight into keeping \
				the lights on.",
			"actions" = list(
				"empathy" = list(
					"text" = "A lot of people must have suffered.",
					"default_scene" = "industry_lcorp_empathy"
				),
				"back" = list(
					"text" = "That explains the tight margins.",
					"default_scene" = "industry_menu"
				),
			)
		),

		"industry_lcorp_empathy" = list(
			"text" = "They did. Backstreets got hit hardest — always do. \
				Nest residents barely noticed. Down here, people froze. \
				Businesses folded. ...I try not to dwell on it.",
			"actions" = list(
				"back" = list(
					"text" = "Sorry I brought it up.",
					"default_scene" = "industry_menu"
				),
			)
		),

		"industry_calw" = list(
			"text" = "Calw. District 11 — K Corp's territory. The holy site \
				of the prosthetics industry. Biggest concentration of augment \
				workshops, body shops, and prosthetic artisans in the entire \
				City. If you work in prosthetics, you know someone in Calw.",
			"actions" = list(
				"calw_compete" = list(
					"text" = "Can you compete with them?",
					"default_scene" = "industry_calw_2"
				),
				"back" = list(
					"text" = "Sounds impressive.",
					"default_scene" = "industry_menu"
				),
			)
		),

		"industry_calw_2" = list(
			"text" = "Not directly — they've got the volume, the artisan \
				talent, and K Corp's infrastructure behind them. But Calw \
				workshops focus on high-end custom work. Nest clients, \
				celebrity Fixers, people who'll pay a fortune for a perfectly \
				fitted combat arm. We serve a different market — Backstreets \
				workers who need a reliable replacement that won't break \
				in three months.",
			"actions" = list(
				"calw_relationship" = list(
					"text" = "Any connection between Prostheti and Calw?",
					"default_scene" = "industry_calw_3"
				),
				"back" = list(
					"text" = "Different markets, different problems.",
					"default_scene" = "industry_menu"
				),
			)
		),

		"industry_calw_3" = list(
			"text" = "We buy components from Calw suppliers — some of the best \
				base prosthetic hardware in the City comes out of those \
				workshops. I've got contacts there. Good people. The kind who \
				understand that prosthetics aren't luxury goods — they're how \
				people survive. Without Calw's supply chain, half the \
				independent shops in the City would fold overnight.",
			"actions" = list(
				"back" = list(
					"text" = "Good to know where the parts come from.",
					"default_scene" = "industry_menu"
				),
			)
		),

		// =============================================
		// TIER 3 — After Day 3: Personal History
		// =============================================

		"personal_menu" = list(
			"text" = "...You've put in the work. I suppose you've earned a \
				straight answer. What do you want to know?",
			"actions" = list(
				"past" = list(
					"text" = "What were you doing before Prostheti?",
					"default_scene" = "personal_past"
				),
				"mother" = list(
					"text" = "What happened to Penny's mother?",
					"visibility_expression" = "npc.asked_about_family",
					"default_scene" = "personal_mother"
				),
				"protection" = list(
					"text" = "How do you keep this place safe?",
					"default_scene" = "personal_protection"
				),
				"back" = list(
					"text" = "Maybe another time.",
					"default_scene" = "main_menu"
				),
			)
		),

		"personal_past" = list(
			"text" = "Quality control. At a Wing-adjacent augment \
				manufacturer — big name, Nest headquarters, corporate \
				everything. Good pay. Stable. The kind of job people in \
				the Backstreets would kill for.",
			"actions" = list(
				"past_continue" = list(
					"text" = "Sounds comfortable. Why leave?",
					"default_scene" = "personal_past_2"
				),
				"back" = list(
					"text" = "Quite the change.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_past_2" = list(
			"text" = "Because I watched them cut corners on Backstreets-grade \
				product. Same brand name, different internals. Components \
				that would fail in months — joint servos that lock up, nerve \
				interfaces that degrade. Sold to people who'd spent their \
				savings on a new arm and couldn't afford a replacement \
				when it broke.",
			"actions" = list(
				"past_report" = list(
					"text" = "Did you report it?",
					"default_scene" = "personal_past_3"
				),
				"back" = list(
					"text" = "That's awful.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_past_3" = list(
			"text" = "Every time. Filed reports, flagged components, documented \
				the lot. Know what happened? Nothing. The margins on cheap \
				product were too good. Management smiled, thanked me for my \
				diligence, and shipped the same defective units the next week.",
			"actions" = list(
				"past_left" = list(
					"text" = "So you left.",
					"default_scene" = "personal_why_left"
				),
				"righteous" = list(
					"text" = "That's disgusting.",
					"default_scene" = "personal_past_righteous"
				),
				"cynical" = list(
					"text" = "Corporations never change.",
					"default_scene" = "personal_past_cynical"
				),
			)
		),

		"personal_past_righteous" = list(
			"text" = "(quiet) ...Yeah. Someone should have stopped them. \
				Turns out that someone had to be me.",
			"actions" = list(
				"continue" = list(
					"text" = "What did you do?",
					"default_scene" = "personal_why_left"
				),
			)
		),

		"personal_past_cynical" = list(
			"text" = "No. They don't. That's why I stopped waiting for \
				them to.",
			"actions" = list(
				"continue" = list(
					"text" = "What did you do?",
					"default_scene" = "personal_why_left"
				),
			)
		),

		"personal_why_left" = list(
			"text" = "I took the blueprints for their best-selling prosthetic \
				line and walked out. Their engineering was sound — the problem \
				was always the manufacturing shortcuts. I knew I could build \
				the same designs properly if I did it myself.",
			"actions" = list(
				"left_consequences" = list(
					"text" = "Didn't they come after you?",
					"default_scene" = "personal_why_left_2"
				),
				"judgment" = list(
					"text" = "You stole from them?",
					"default_scene" = "personal_stole_judgment"
				),
				"support" = list(
					"text" = "Good. They deserved worse.",
					"default_scene" = "personal_stole_support"
				),
			)
		),

		"personal_stole_judgment" = list(
			"text" = "I took blueprints that were being used to sell people \
				broken arms. Call it what you want. (beat) They could have \
				come after me. Probably should have. But the schematics \
				weren't Singularity tech — just good engineering they never \
				bothered to protect. Chasing a QC nobody wasn't worth \
				their time.",
			"actions" = list(
				"continue" = list(
					"text" = "So you got away with it.",
					"default_scene" = "personal_lucky"
				),
			)
		),

		"personal_stole_support" = list(
			"text" = "...Don't romanticize it. What I did was theft — justified \
				or not. (beat) I got lucky. The blueprints weren't patented \
				Singularity tech. Chasing down a QC grunt over non-patented \
				schematics? Not worth their time. So they let me walk.",
			"actions" = list(
				"continue" = list(
					"text" = "And you built Prostheti.",
					"default_scene" = "personal_lucky"
				),
			)
		),

		"personal_why_left_2" = list(
			"text" = "Could have. Should have, probably. But the blueprints \
				weren't patented Singularity tech — just good engineering \
				they'd never bothered to protect. Sending Fixers after a \
				quality control nobody over non-patented schematics? Not \
				worth the ahn. I was lucky.",
			"actions" = list(
				"lucky" = list(
					"text" = "Lucky?",
					"default_scene" = "personal_lucky"
				),
			)
		),

		"personal_lucky" = list(
			"text" = "'Lucky' is what I call it. Others would say 'stupid.' \
				Just a rented garage in the Backstreets, a workbench, and a \
				stubborn refusal to build something I knew would break. Built \
				the first batch of augments by hand. Sold them to a Fixer who \
				liked the craftsmanship. He told two friends. They told \
				two more.",
			"actions" = list(
				"lucky_continue" = list(
					"text" = "And that became Prostheti.",
					"default_scene" = "personal_lucky_2"
				),
			)
		),

		"personal_lucky_2" = list(
			"text" = "That became Prostheti. Took years to get the Tres \
				registration, hire real staff, move out of the garage. But \
				the company you see now... it wasn't always like this. It \
				used to be different. Open.",
			"actions" = list(
				"lucky_open" = list(
					"text" = "What do you mean, open?",
					"default_scene" = "personal_open"
				),
				"back" = list(
					"text" = "That's quite a story.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_open" = list(
			"text" = "We used to be out there. In the streets, fitting augments \
				for people who couldn't afford workshop prices. Free \
				maintenance for Backstreets residents with cheap prosthetics \
				that were falling apart. Community outreach. I wasn't doing \
				it alone — I had someone who believed that was the right way \
				to run things.",
			"actions" = list(
				"open_who" = list(
					"text" = "Someone?",
					"default_scene" = "personal_open_2"
				),
				"back" = list(
					"text" = "Sounds like a different company.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_open_2" = list(
			"text" = "...My wife. She brought connections, credibility — a \
				reputation that opened doors I couldn't open alone. She \
				believed if you had the resources to help people directly, \
				you had the obligation to do it. I believed her.",
			"actions" = list(
				"open_what_changed" = list(
					"text" = "What changed?",
					"default_scene" = "personal_what_changed"
				),
			)
		),

		"personal_what_changed" = list(
			"text" = "She died. And the lesson I took from it was specific: \
				being visible is what gets you killed. Skill doesn't protect \
				you. Reputation doesn't protect you. Showing up for people \
				doesn't protect you. So I stopped showing up. Built walls \
				instead. Patents, contracts, Inventor certifications — \
				influence from behind closed doors.",
			"actions" = list(
				"changed_continue" = list(
					"text" = "That's why you run things the way you do now.",
					"default_scene" = "personal_changed_2"
				),
				"challenge" = list(
					"text" = "Shutting everyone out isn't the answer.",
					"default_scene" = "personal_changed_challenge"
				),
			)
		),

		"personal_changed_challenge" = list(
			"text" = "(long pause) ...Maybe not. But my daughter is alive. \
				This company is standing. And the people who killed my wife \
				never came back. You tell me which matters more — being \
				open, or being here.",
			"actions" = list(
				"back" = list(
					"text" = "...I don't have an answer for that.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_changed_2" = list(
			"text" = "Every decision I've made since has been about making \
				this company strong enough that no one can touch us again. \
				Strong enough that Penny will inherit something worth \
				having — something safe. Maybe I'm wrong. But I've seen \
				what happens when you bet on being right instead of \
				being protected.",
			"actions" = list(
				"penny_challenge" = list(
					"text" = "Penny might not want what you're building for her.",
					"default_scene" = "personal_changed_penny"
				),
				"comfort" = list(
					"text" = "You're doing the best you can.",
					"default_scene" = "personal_changed_comfort"
				),
				"back" = list(
					"text" = "...I understand.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_changed_penny" = list(
			"text" = "(stiffens) ...That's not your concern. What Penny wants \
				and what she needs are two different things. I've seen what \
				happens when people in this City chase what they want without \
				protection. ...We're done here.",
			"actions" = list(
				"back" = list(
					"text" = "...Sorry.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_changed_comfort" = list(
			"text" = "...(quiet pause) ...Get back to work.",
			"actions" = list(
				"back" = list(
					"text" = "Yes, sir.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_mother" = list(
			"text" = "...She's dead. Penny was eight.",
			"actions" = list(
				"mother_more" = list(
					"text" = "I'm sorry. What happened?",
					"default_scene" = "personal_mother_2"
				),
				"back" = list(
					"text" = "I shouldn't have asked.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_mother_2" = list(
			"text" = "...Someone decided we were too visible. That we'd grown \
				too much. That's what happens when you succeed in the \
				Backstreets — you become a target. I lost her. That's all \
				I'm going to say about it.",
			"actions" = list(
				"mother_penny" = list(
					"text" = "Does Penny know?",
					"default_scene" = "personal_mother_3"
				),
				"back" = list(
					"text" = "I understand.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_mother_3" = list(
			"text" = "She knows her mother died. She doesn't know... the \
				details. And I'd like to keep it that way. ...We're done \
				talking about this.",
			"actions" = list(
				"back" = list(
					"text" = "Of course.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_protection" = list(
			"text" = "Every Backstreets business pays someone. That's not \
				optional — it's how things work down here. You either pay \
				for protection or you deal with whatever walks through your \
				door uninvited.",
			"actions" = list(
				"protection_who" = list(
					"text" = "Who do you pay?",
					"default_scene" = "personal_protection_2"
				),
				"back" = list(
					"text" = "The cost of doing business.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_protection_2" = list(
			"text" = "Zwei Association. Hired shields — professional, \
				contracted, reliable. They're not cheap, but they follow \
				the terms of the agreement. Every ahn. I used to rely on a \
				local Syndicate crew, but Syndicates follow whatever they \
				feel like on a given Tuesday. After what happened to my \
				wife, I don't gamble on protection anymore.",
			"actions" = list(
				"protection_zwei" = list(
					"text" = "Zwei instead of Cinq?",
					"default_scene" = "personal_protection_3"
				),
				"back" = list(
					"text" = "Smart move.",
					"default_scene" = "personal_menu"
				),
			)
		),

		"personal_protection_3" = list(
			"text" = "Cinq duelists are the best fighters in the City. But \
				the people who come for you in the Backstreets don't throw \
				a glove and declare intent. They hit you in the dark, during \
				the Night, when no one's watching. Against that, you don't \
				need a sword — you need a shield. Zwei understands that.",
			"actions" = list(
				"back" = list(
					"text" = "You've thought about this a lot.",
					"default_scene" = "personal_protection_4"
				),
			)
		),

		"personal_protection_4" = list(
			"text" = "I've had to. ...Get back to work.",
			"actions" = list(
				"back" = list(
					"text" = "Yes, sir.",
					"default_scene" = "personal_menu"
				),
			)
		),
	))
