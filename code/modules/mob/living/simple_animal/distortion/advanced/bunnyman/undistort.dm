// The killed, and the way out. He killed four people on this street. Three bit; one was only standing there, and that
// is the one he cannot stop talking about in his room: a piece of how they looked at a time, never the name. The
// names and the looks are on the missing posters. Say the right name to his face in his room while his judgement is
// off, and he looks up for good.

/// One of the people he killed: a name and a look in six parts, as a missing poster would give them.
/datum/bunnyman_killed
	var/name
	/// slot to what was worn or seen: "hat", "hair", "eyes", "shirt", "coat", "shoes".
	var/list/look = list()

/// Rolls the four. The innocent first; each murderer is made to differ from them in at least two parts of the look.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/RollKilled()
	for(var/i in 1 to killed_count)
		var/datum/bunnyman_killed/K = new
		K.name = random_unique_name(pick(MALE, FEMALE))
		for(var/slot in look_options)
			K.look[slot] = pick(look_options[slot])
		if(i > 1)
			var/datum/bunnyman_killed/innocent = killed[1]
			while(LookDifference(K, innocent) < 2)
				var/slot = pick(look_options)
				K.look[slot] = pick(look_options[slot] - innocent.look[slot])
		killed += K

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/LookDifference(datum/bunnyman_killed/A, datum/bunnyman_killed/B)
	. = 0
	for(var/slot in look_options)
		if(A.look[slot] != B.look[slot])
			.++

/// The look as a missing poster writes it.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/LookText(datum/bunnyman_killed/K)
	return "Last seen wearing [K.look["coat"]] over [K.look["shirt"]], [K.look["shoes"]], [K.look["hat"]]. [capitalize(K.look["hair"])], [K.look["eyes"]]."

/// Which of the killed a message names, or null.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/KilledNamed(message)
	for(var/datum/bunnyman_killed/K in killed)
		if(findtext(message, K.name))
			return K
	return null

/// In the den, idle: he stops for a moment and says one part of how the innocent looked. Never the name.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Mutter()
	if(world.time < next_mutter)
		return
	next_mutter = world.time + mutter_cooldown
	rooted_until = world.time + mutter_pause
	walk(src, 0)
	patrol_reset()
	var/datum/bunnyman_killed/innocent = killed[1]
	var/part = innocent.look[pick(look_options)]
	say(replacetext(pick(mutter_clue_lines), "%PART%", part))

// Hearing. The say hook on humans standing on his ground, held and let go by TrackInside().

/// A name of the killed, said where he can hear. With his judgement on it is a warning, worded for which name it
/// was. With it off and the speaker in his sight, the innocent's name is the way out and a murderer's is a fight.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnSpeech(mob/living/carbon/human/speaker, list/speech_args)
	SIGNAL_HANDLER
	var/message = speech_args[SPEECH_MESSAGE]
	if(!message || stat == DEAD || undistort_timer)
		return
	var/datum/bunnyman_killed/K = KilledNamed(message)
	if(!K || !(speaker in view(src)))
		return
	if(judging)
		INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, say), K == killed[1] ? pick(right_name_warnings) : pick(wrong_name_warnings))
		INVOKE_ASYNC(src, PROC_REF(Warn), speaker, FALSE)
		return
	if(K == killed[1])
		INVOKE_ASYNC(src, PROC_REF(StartUndistorting), speaker)
		return
	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, say), "That one bit.")
	INVOKE_ASYNC(src, PROC_REF(WakeOn), speaker)

/// Out of the stun and onto whoever did it, the fair fight's way. Used by a hit and by a wrong name.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/WakeOn(mob/living/source)
	if(hunt_state == "stunned")
		hunt_state = "idle"
		visible_message(span_danger("[src] turns on [source]."))
		HideStagger()
	Provoke(source)

/// He looks up. The rays grow for undistort_time while the window is held open; a hit before the end puts them out.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/StartUndistorting(mob/living/carbon/human/speaker)
	if(judgement_timer)
		judgement_left = max(timeleft(judgement_timer), judgement_resume_floor)
	StopJudgementTimer()
	undistort_timer = addtimer(CALLBACK(src, PROC_REF(Undistort)), undistort_time, TIMER_STOPPABLE)
	visible_message(span_notice("[src] goes still in a different way. Something behind the mask starts to shine."))
	to_chat(speaker, span_nicegreen("He looks at you. He looks for a long time."))
	var/datum/bunnyman_killed/innocent = killed[1]
	say("...[innocent.name]. That was the name.")
	add_filter("undistort", 1, rays_filter(size = 4, color = "#FFD8C8", offset = 0, density = 10, threshold = 0.15))
	transition_filter("undistort", undistort_time, list(size = 120, offset = 90), SINE_EASING | EASE_IN)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/CancelUndistort()
	if(!undistort_timer)
		return
	deltimer(undistort_timer)
	undistort_timer = null
	remove_filter("undistort")
	StartJudgementTimer(judgement_left)
	visible_message(span_warning("The light goes out of him."))

/// The base Unmanifest() releases the stored human alive with the EGO, so the usual death cleanup never sees them.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Undistort()
	undistort_timer = null
	Unmanifest()
