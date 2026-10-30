// The Sunshone Kakis' kill sequence, always played by the pair: the hungry kaki on the left, the thirsty one on the
// right, whichever of them made the kill (the other is only drawn). Each has a loose arm, drawn only for this. The
// hungry kaki grabs the victim's face and the pair beat them, punch after punch, until a blow from both drops them to
// their knees. They hammer them lower, then hunch over them, coats covering them, to feed. Then they straighten and
// step back, and the victim slumps over. The body is left as it is.

/datum/gms_kill_sequence/kaki_sunshone
	/// The other kaki of the pair, drawn only.
	var/obj/effect/gms_kill_visual/partner
	/// The shadow that creeps over the victim's face.
	var/obj/effect/gms_kill_visual/shadow
	/// The hungry kaki on the left and the thirsty kaki on the right, whichever of them is the real killer, and their arms.
	var/obj/effect/gms_kill_visual/hungry
	var/obj/effect/gms_kill_visual/thirsty
	var/obj/effect/gms_kill_visual/hungry_arm
	var/obj/effect/gms_kill_visual/thirsty_arm
	/// Where the killer stood. It goes back there afterwards.
	var/turf/home_turf
	// Timings, in the order they play.
	var/approach_time = 0.4 SECONDS
	var/grab_time = 0.3 SECONDS
	var/close_time = 0.25 SECONDS
	/// Each punch snaps in over the first part of its time and draws back over the rest.
	var/punches = 6
	var/punch_time = 0.2 SECONDS
	var/punch_snap = 0.4
	var/wind_up_time = 0.25 SECONDS
	var/knee_blow_time = 0.15 SECONDS
	var/kneel_time = 0.3 SECONDS
	/// Blows from both at once, hammering down on them.
	var/hammers = 3
	var/hammer_time = 0.3 SECONDS
	var/hunch_time = 0.3 SECONDS
	var/feeds = 4
	var/feed_time = 0.25 SECONDS
	var/back_off_time = 0.4 SECONDS
	var/slump_time = 0.5 SECONDS
	var/hold_time = 0.5 SECONDS
	/// How far either side of the victim the kakis stand: at the start, once they close in, and right over them.
	var/start_offset = 16
	var/close_offset = 10
	var/hunch_offset = 7
	/// How far a punch carries the puncher in, and how far the victim's body snaps away from it.
	var/punch_lunge = 3
	var/jolt_angle = 12
	var/jolt_shift = 2
	/// Arm angles, forward from hanging: reaching for the face, punching, raised overhead, and brought down.
	var/grab_arm = 100
	var/punch_arm = 90
	var/raise_arm = 170
	var/slam_arm = 50
	var/tuck_arm = 40
	/// How far they lean in: holding on, over a hammer blow, and hunched over to feed. How far a feeding bob or a
	/// hammer blow dips them.
	var/hold_lean = 6
	var/hammer_lean = 14
	var/hunch_lean = 12
	var/feed_dip = 3
	var/hammer_dip = 3
	/// The victim's hands up at their face, and how far they are crushed down: kneeling, then with each hammer blow.
	var/hands_up = 150
	var/kneel_squash = 0.75
	var/hammer_squash = 0.05
	/// How dark the face gets once grabbed, before it goes fully dark under the coats.
	var/grab_shadow = 120
	/// Where the arms turn, from the tile centre with y up. Both facings share it.
	var/shoulder_x = 0
	var/shoulder_y = 4

/datum/gms_kill_sequence/kaki_sunshone/BuildScene()
	. = ..()
	home_turf = get_turf(killer)
	partner = new
	partner.icon = killer.icon
	partner.layer = MOB_LAYER + 0.01
	holder.vis_contents += partner
	ActorInFront(TRUE)
	if(istype(killer, /mob/living/simple_animal/hostile/gms_foe/kaki_sunshone/thirsty))
		thirsty = actor
		hungry = partner
		hungry.icon_state = "hungry_kaki_sunshone"
	else
		hungry = actor
		thirsty = partner
		thirsty.icon_state = "thirsty_kaki_sunshone"
	hungry.dir = EAST
	thirsty.dir = WEST
	hungry.pixel_x = -start_offset
	thirsty.pixel_x = start_offset
	hungry_arm = NewArm(hungry, "hungry_kaki_sunshone_kill_arm")
	thirsty_arm = NewArm(thirsty, "thirsty_kaki_sunshone_kill_arm")
	// Drawn only over the head's own pixels, so it darkens the face without spilling past it.
	shadow = new
	shadow.icon = 'icons/mob/gms/gms_32x32.dmi'
	shadow.icon_state = "mobile_go_spin_kill_shadow"
	shadow.blend_mode = BLEND_INSET_OVERLAY
	shadow.alpha = 0
	var/obj/effect/gms_kill_visual/head = parts["head"]
	head.vis_contents += shadow

/datum/gms_kill_sequence/kaki_sunshone/ClearScene()
	QDEL_NULL(shadow)
	QDEL_NULL(hungry_arm)
	QDEL_NULL(thirsty_arm)
	QDEL_NULL(partner)
	hungry = null
	thirsty = null
	return ..()

/// A loose arm hung off a kaki, so it leans and moves with them.
/datum/gms_kill_sequence/kaki_sunshone/proc/NewArm(obj/effect/gms_kill_visual/kaki, state)
	var/obj/effect/gms_kill_visual/arm = new
	arm.icon = 'icons/mob/gms/gms_32x32.dmi'
	arm.icon_state = state
	arm.dir = kaki.dir
	arm.vis_flags = VIS_INHERIT_PLANE
	arm.layer = MOB_LAYER + 0.02
	kaki.vis_contents += arm
	return arm

/// A kaki leaning in toward the victim about its feet. `sign` is 1 for the hungry kaki on the left, -1 for the thirsty one.
/datum/gms_kill_sequence/kaki_sunshone/proc/Lean(sign, angle)
	return AboutFeet(angle * sign)

/// An arm swung `forward` degrees from hanging, toward the victim, about its shoulder.
/datum/gms_kill_sequence/kaki_sunshone/proc/Swing(sign, forward)
	var/matrix/M = matrix()
	M.Translate(-shoulder_x, -shoulder_y)
	M.Turn(-forward * sign)
	M.Translate(shoulder_x, shoulder_y)
	return M

/datum/gms_kill_sequence/kaki_sunshone/proc/PoseArms(angle, time)
	PoseLimb("r_arm", -angle, time)
	PoseLimb("l_arm", angle, time)

/// The victim's crushed, kneeling shape, `extra` squashed past kneeling.
/datum/gms_kill_sequence/kaki_sunshone/proc/Kneeling(extra = 0)
	return AboutFeet(0, 1, kneel_squash - extra)

/// Blood sprays off the victim, away from the blow.
/datum/gms_kill_sequence/kaki_sunshone/proc/Spray(sign)
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(victim), sign > 0 ? EAST : WEST)

/// One punch from a kaki: it lunges in and snaps its arm out, the victim's body jerks away, and it draws back.
/datum/gms_kill_sequence/kaki_sunshone/proc/Punch(sign)
	var/obj/effect/gms_kill_visual/kaki = sign > 0 ? hungry : thirsty
	var/obj/effect/gms_kill_visual/arm = sign > 0 ? hungry_arm : thirsty_arm
	var/snap = punch_time * punch_snap
	animate(kaki, pixel_x = -sign * (hunch_offset - punch_lunge), transform = Lean(sign, hold_lean * 2), time = snap, easing = QUAD_EASING | EASE_OUT)
	animate(pixel_x = -sign * hunch_offset, transform = Lean(sign, hold_lean), time = punch_time - snap)
	animate(arm, transform = Swing(sign, punch_arm), time = snap, easing = QUAD_EASING | EASE_OUT)
	animate(transform = Swing(sign, 0), time = punch_time - snap)
	var/matrix/jolt = AboutFeet(jolt_angle * sign)
	jolt.Translate(jolt_shift * sign, 0)
	animate(scan, transform = jolt, time = snap, easing = QUAD_EASING | EASE_OUT)
	animate(transform = matrix(), time = punch_time - snap)
	playsound(victim, "punch", 60, TRUE)
	Spray(sign)

/datum/gms_kill_sequence/kaki_sunshone/Play()
	// They close in from either side.
	animate(hungry, pixel_x = -close_offset, time = approach_time)
	animate(thirsty, pixel_x = close_offset, time = approach_time)
	if(!Wait(approach_time))
		return
	// The hungry kaki grabs the victim's face, and their hands fly up to it as it starts to darken.
	playsound(victim, 'sound/weapons/thudswoosh.ogg', 50, TRUE)
	animate(hungry, pixel_x = -hunch_offset, transform = Lean(1, hold_lean), time = grab_time, easing = QUAD_EASING | EASE_OUT)
	animate(hungry_arm, transform = Swing(1, grab_arm), time = grab_time, easing = QUAD_EASING | EASE_OUT)
	animate(shadow, alpha = grab_shadow, time = grab_time)
	PoseArms(hands_up, grab_time)
	if(!Wait(grab_time))
		return
	// The thirsty kaki closes in, and they beat them, punch after punch from either side.
	animate(thirsty, pixel_x = hunch_offset, transform = Lean(-1, hold_lean), time = close_time, easing = QUAD_EASING | EASE_OUT)
	if(!Wait(close_time))
		return
	for(var/i in 1 to punches)
		Punch((i % 2) ? -1 : 1)
		if(!Wait(punch_time))
			return
	// Both raise their arms high, and bring them down together: the victim drops to their knees.
	animate(hungry_arm, transform = Swing(1, raise_arm), time = wind_up_time, easing = QUAD_EASING | EASE_OUT)
	animate(thirsty_arm, transform = Swing(-1, raise_arm), time = wind_up_time, easing = QUAD_EASING | EASE_OUT)
	if(!Wait(wind_up_time))
		return
	animate(hungry_arm, transform = Swing(1, slam_arm), time = knee_blow_time, easing = QUAD_EASING | EASE_IN)
	animate(thirsty_arm, transform = Swing(-1, slam_arm), time = knee_blow_time, easing = QUAD_EASING | EASE_IN)
	if(!Wait(knee_blow_time))
		return
	playsound(victim, 'sound/effects/wounds/crack1.ogg', 60, TRUE)
	Spray(1)
	Spray(-1)
	animate(scan, transform = Kneeling(), time = kneel_time, easing = BOUNCE_EASING)
	if(!Wait(kneel_time))
		return
	// They hammer down on them together, driving them lower with every blow.
	for(var/i in 1 to hammers)
		for(var/sign in list(1, -1))
			var/obj/effect/gms_kill_visual/kaki = sign > 0 ? hungry : thirsty
			animate(sign > 0 ? hungry_arm : thirsty_arm, transform = Swing(sign, raise_arm), time = hammer_time / 2, easing = QUAD_EASING | EASE_OUT)
			animate(transform = Swing(sign, slam_arm), time = hammer_time / 2, easing = QUAD_EASING | EASE_IN)
			animate(kaki, transform = Lean(sign, hold_lean), time = hammer_time / 2)
			animate(transform = Lean(sign, hammer_lean), pixel_y = -hammer_dip, time = hammer_time / 2, easing = QUAD_EASING | EASE_IN)
		if(!Wait(hammer_time / 2))
			return
		animate(scan, transform = Kneeling(hammer_squash * i), time = hammer_time / 2, easing = BOUNCE_EASING)
		playsound(victim, "punch", 70, TRUE)
		if(i == hammers)
			playsound(victim, 'sound/effects/wounds/crackandbleed.ogg', 60, TRUE)
		Spray(1)
		Spray(-1)
		if(!Wait(hammer_time / 2))
			return
	// Both hunch right over them, coats covering them, arms tucked in, and the face goes fully dark.
	animate(hungry, pixel_y = 0, transform = Lean(1, hunch_lean), time = hunch_time)
	animate(thirsty, pixel_y = 0, transform = Lean(-1, hunch_lean), time = hunch_time)
	animate(hungry_arm, transform = Swing(1, tuck_arm), time = hunch_time)
	animate(thirsty_arm, transform = Swing(-1, tuck_arm), time = hunch_time)
	animate(shadow, alpha = 255, time = hunch_time)
	if(!Wait(hunch_time))
		return
	// They feed, tearing at them in turn.
	for(var/i in 1 to feeds)
		var/sign = (i % 2) ? 1 : -1
		animate(sign > 0 ? hungry : thirsty, pixel_y = -feed_dip, time = feed_time / 2, easing = SINE_EASING)
		animate(pixel_y = 0, time = feed_time / 2, easing = SINE_EASING)
		playsound(victim, 'sound/effects/butcher.ogg', 60, TRUE)
		Spray(sign)
		if(!Wait(feed_time))
			return
	// They straighten and step back, arms hanging.
	animate(hungry, pixel_x = -start_offset, transform = matrix(), time = back_off_time)
	animate(thirsty, pixel_x = start_offset, transform = matrix(), time = back_off_time)
	animate(hungry_arm, transform = matrix(), time = back_off_time)
	animate(thirsty_arm, transform = matrix(), time = back_off_time)
	if(!Wait(back_off_time))
		return
	// The victim slumps over where they knelt.
	playsound(victim, 'sound/effects/splat.ogg', 50, TRUE)
	animate(scan, transform = Fallen(), time = slump_time, easing = BOUNCE_EASING)
	PoseArms(0, slump_time)
	if(!Wait(slump_time + hold_time))
		return
	Finish()

/datum/gms_kill_sequence/kaki_sunshone/ReleaseTurf()
	return home_turf
