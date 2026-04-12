// =============================================
// Prostheti Innovations — Clyde Confrontation Cutscene (Chapter 2)
// =============================================
// Players wake up in the medical wing, buckled to beds.
// Clyde is standing beside Penny's bed. He reveals he's been reading
// her letters to Hector for over a year.
//
// Players are forced witnesses — buckled, immobilized, unable to intervene.
// After the confrontation, they're unbuckled and the chapter completes.

/// Returns a sleep delay in deciseconds scaled to message length.
/// ~1 tick per character, minimum 20 (2 seconds), plus optional extra pause for dramatic weight.
/proc/CutsceneDelay(message, extra_pause = 0)
	return max(20, length(message)) + extra_pause

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
	var/line

	line = "You're awake. Good."
	clyde.say(line)
	sleep(CutsceneDelay(line))

	line = "Dad? What... where are we?"
	penny.say(line)
	sleep(CutsceneDelay(line))

	line = "The medical wing. The Zwei brought you back. All of you."
	clyde.say(line)
	sleep(CutsceneDelay(line))

	line = "How did you know where we—"
	penny.say(line)
	sleep(CutsceneDelay(line))

	line = "I've known about Hector since the first letter."
	clyde.say(line)
	sleep(CutsceneDelay(line, 30))	// Extra pause — this lands hard

	line = "...What?"
	penny.say(line)
	sleep(CutsceneDelay(line))

	line = "Every letter you sent. Every letter he sent back. I've been reading them for over a year."
	clyde.say(line)
	sleep(CutsceneDelay(line))

	line = "You... you read my letters?"
	penny.say(line)
	sleep(CutsceneDelay(line))

	line = "I intercepted them. Copied them. Put them back before you noticed. The training, the combat drills, the fixer talk — I knew all of it."
	clyde.say(line)
	sleep(CutsceneDelay(line))

	line = "Then why didn't you stop me?!"
	penny.say(line)
	sleep(CutsceneDelay(line))

	line = "Because combat skills are useful for a CEO. And because I hoped you'd come to your senses on your own."
	clyde.say(line)
	sleep(CutsceneDelay(line))

	line = "You let me think I had a secret. You let me think I was doing something on my own for once in my life."
	penny.say(line)
	sleep(CutsceneDelay(line))

	line = "You were never in danger until today. The moment I learned you entered that factory, I deployed the Zwei. That deployment cost more Ahn than most Backstreets workers see in a year. I spent it without hesitation."
	clyde.say(line)
	sleep(CutsceneDelay(line))

	line = "I didn't ask you to do that."
	penny.say(line)
	sleep(CutsceneDelay(line))

	line = "You didn't have to."
	clyde.say(line)
	sleep(CutsceneDelay(line, 30))	// Extra pause — dramatic weight

	line = "A year. A whole year you could have just... talked to me."
	penny.say(line)
	sleep(CutsceneDelay(line))

	// Clyde has no answer — long silence
	sleep(60)

	// --- Aftermath ---
	// Long pause before Clyde leaves
	sleep(40)

	// Clyde turns and walks out — stays at medical wing position for now
	clyde.in_cutscene = FALSE

	// Short pause after Clyde's silence
	sleep(20)

	// Penny stays in bed — unlock her for post-dialogue
	penny.in_cutscene = FALSE

	// Complete the chapter
	mission.ChapterComplete()
