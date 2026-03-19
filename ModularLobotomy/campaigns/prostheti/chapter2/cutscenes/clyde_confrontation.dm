// =============================================
// Prostheti Innovations — Clyde Confrontation Cutscene (Chapter 2)
// =============================================
// Players wake up in the medical wing, buckled to beds.
// Clyde is standing beside Penny's bed. He reveals he's been reading
// her letters to Hector for over a year.
//
// Players are forced witnesses — buckled, immobilized, unable to intervene.
// After the confrontation, they're unbuckled and the chapter completes.

/// Runs the Clyde/Penny confrontation cutscene in the medical wing.
/// Called by the mission datum after extraction and fade-in.
/proc/RunClydeConfrontation(datum/prostheti_mission/factory_infiltration/mission)
	if(!mission)
		return

	var/datum/campaign_controller/prostheti/campaign = mission.campaign
	if(!campaign)
		return

	// Find Clyde and Penny NPCs
	var/mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch2/clyde
	var/mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2/penny
	for(var/mob/living/simple_animal/hostile/ui_npc/prostheti/npc in campaign.current_npcs)
		if(istype(npc, /mob/living/simple_animal/hostile/ui_npc/prostheti/clyde_wells/ch2))
			clyde = npc
		if(istype(npc, /mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch2))
			penny = npc

	if(!clyde || !penny)
		// Fallback — skip cutscene and complete chapter
		mission.ChapterComplete()
		return

	// Lock NPCs
	clyde.in_cutscene = TRUE
	penny.in_cutscene = TRUE

	// Pause before dialogue starts
	sleep(20)

	// --- The Confrontation ---
	clyde.say("You're awake. Good.")
	sleep(20)

	penny.say("Dad? What... where are we?")
	sleep(15)

	clyde.say("The medical wing. The Zwei brought you back. All of you.")
	sleep(20)

	penny.say("How did you know where we—")
	sleep(15)

	clyde.say("I've known about Hector since the first letter.")
	sleep(30)	// This lands hard — 3 second pause

	penny.say("...What?")
	sleep(15)

	clyde.say("Every letter you sent. Every letter he sent back. I've been reading them for over a year.")
	sleep(20)

	penny.say("You... you read my letters?")
	sleep(20)

	clyde.say("I intercepted them. Copied them. Put them back before you noticed. The training, the combat drills, the fixer talk — I knew all of it.")
	sleep(25)

	penny.say("Then why didn't you stop me?!")
	sleep(20)

	clyde.say("Because combat skills are useful for a CEO. And because I hoped you'd come to your senses on your own.")
	sleep(20)

	penny.say("You let me think I had a secret. You let me think I was doing something on my own for once in my life.")
	sleep(20)

	clyde.say("You were never in danger until today. The moment I learned you entered that factory, I deployed the Zwei. That deployment cost more Ahn than most Backstreets workers see in a year. I spent it without hesitation.")
	sleep(20)

	penny.say("I didn't ask you to do that.")
	sleep(15)

	clyde.say("You didn't have to.")
	sleep(30)	// 3 second pause

	penny.say("A year. A whole year you could have just... talked to me.")
	sleep(20)

	// Clyde has no answer — 3 second silence
	sleep(30)

	// --- Aftermath ---
	// Long pause (4 seconds of silence)
	sleep(40)

	// Clyde turns and walks out
	clyde.in_cutscene = FALSE
	var/turf/clyde_office = GLOB.prostheti_npc_landmarks["clyde_spawn"]
	if(clyde_office)
		clyde.forceMove(clyde_office)

	// Short pause after Clyde leaves
	sleep(20)

	// Penny stays in bed — unlock her for post-dialogue
	penny.in_cutscene = FALSE

	// Complete the chapter
	mission.ChapterComplete()
