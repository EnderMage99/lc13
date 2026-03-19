// =============================================
// Prostheti Innovations — Proposal Cutscene (Chapter 2)
// =============================================
// Hector proposes the factory infiltration to Penny and the players.
// Triggered automatically when Penny and Hector are near each other
// after chapter 2 starts (or triggered via dialogue).
//
// Uses say() + sleep() pattern. Global proc — no src, so manual QDELETED checks.

/// Runs the proposal cutscene where Hector pitches the factory infiltration.
/// Called from Hector's ch2 dialogue via proc_callback.
/proc/RunProposalCutscene(mob/living/simple_animal/hostile/ui_npc/prostheti/hector/ch2/hector)
	if(!hector || QDELETED(hector))
		return

	var/datum/campaign_controller/prostheti/campaign = GLOB.prostheti_campaign
	if(!campaign)
		return

	// Find Penny ch2 NPC
	var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/penny
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/P in campaign.current_npcs)
		penny = P
		break
	if(!penny)
		return

	// Lock both NPCs
	hector.in_cutscene = TRUE
	penny.in_cutscene = TRUE

	// Close any open TGUI sessions
	SStgui.close_uis(hector)
	SStgui.close_uis(penny)

	hector.face_atom(penny)
	penny.face_atom(hector)

	hector.say("Penny. You too — all of you. I need to talk to you about something.")
	sleep(20)
	if(QDELETED(hector))
		return

	hector.say("You've been training hard. All of you have. But training only gets you so far.")
	sleep(20)
	if(QDELETED(hector))
		return

	hector.say("There's a factory on the other side of the district. A competitor of your father's — they're developing a new augment line.")
	sleep(20)
	if(QDELETED(hector))
		return

	hector.say("I want you to break in and destroy the blueprints.")
	sleep(25)
	if(QDELETED(hector))
		return

	if(!QDELETED(penny))
		penny.say("You... you want us to break into a building?")
		sleep(15)

	hector.say("If you're serious about being a Fixer, you need to prove you can handle a real job. Not sparring in a yard.")
	sleep(20)
	if(QDELETED(hector))
		return

	if(!QDELETED(penny))
		penny.say("That's not — Fixers take contracts. They don't just break into places.")
		sleep(20)

	if(QDELETED(hector))
		return
	hector.say("And how do you think those contracts start? Someone needs something done. I'm telling you what needs doing. It has to be today.")
	sleep(20)

	if(!QDELETED(penny))
		penny.say("...Alright. I'll do it.")
		sleep(15)

	// Unlock NPCs
	if(!QDELETED(hector))
		hector.in_cutscene = FALSE
	if(!QDELETED(penny))
		penny.in_cutscene = FALSE

	// Set shared var so players know the proposal happened
	if(!QDELETED(hector))
		hector.SetSharedVar("proposal_seen", TRUE)
