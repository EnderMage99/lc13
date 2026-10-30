// The Taste Testers' kill sequences. Each tester kills from afar, so in every scene it walks in from where it stood
// (no further than a few tiles, so it stays in view) and does its work over the body.
//  Mouth: the victim is knocked flat; the tester kneels at their head and saws it off. The head is left beside them.
//  Eye: the victim slumps down to sit; the tester rises behind them and tears their face away.
//  Nose: the victim bursts apart; the tester kneels among the pieces and rummages, and the limbs are left scattered.

/datum/gms_kill_sequence/taste_tester
	/// The shadow that creeps over the victim's face.
	var/obj/effect/gms_kill_visual/shadow
	/// Where the tester starts the scene, in pixels from the victim: where it really stood, but no further than this.
	var/max_start = 64
	var/start_x = 0
	var/start_y = 0
	var/walk_time = 0.8 SECONDS

/datum/gms_kill_sequence/taste_tester/BuildScene()
	. = ..()
	start_x = clamp((killer.x - victim.x) * world.icon_size, -max_start, max_start)
	start_y = clamp((killer.y - victim.y) * world.icon_size, -max_start, max_start)
	actor.pixel_x = start_x
	actor.pixel_y = start_y
	// Drawn only over the head's own pixels, so it darkens the face without spilling past it.
	shadow = new
	shadow.icon = 'icons/mob/gms/gms_32x32.dmi'
	shadow.icon_state = "mobile_go_spin_kill_shadow"
	shadow.blend_mode = BLEND_INSET_OVERLAY
	shadow.alpha = 0
	var/obj/effect/gms_kill_visual/head = parts["head"]
	head.vis_contents += shadow

/datum/gms_kill_sequence/taste_tester/ClearScene()
	QDEL_NULL(shadow)
	return ..()

/// Walks the tester over to (x, y), facing the way it goes, and then the way it should face once there.
/datum/gms_kill_sequence/taste_tester/proc/WalkTo(x, y, face_dir)
	actor.dir = x > actor.pixel_x ? EAST : WEST
	animate(actor, pixel_x = x, pixel_y = y, time = walk_time)
	. = Wait(walk_time)
	if(actor)
		actor.dir = face_dir

/// The tester kneeling: squashed about its feet by `squash`, leaning `lean` degrees clockwise.
/datum/gms_kill_sequence/taste_tester/proc/Kneel(squash, lean = 0)
	return AboutFeet(lean, 1, squash)

/// Blood sprays off the victim.
/datum/gms_kill_sequence/taste_tester/proc/Spray()
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(victim), pick(GLOB.alldirs))

/datum/gms_kill_sequence/taste_tester/mouth
	var/knock_time = 0.4 SECONDS
	var/kneel_time = 0.3 SECONDS
	var/saws = 5
	var/saw_time = 0.25 SECONDS
	var/sit_time = 0.5 SECONDS
	var/hold_time = 1 SECONDS
	/// Where it kneels: by the head of the body lying flat, a little behind it.
	var/kneel_x = 18
	var/kneel_y = 8
	var/kneel_squash = 0.8
	var/saw_lean = 8
	/// How far the head comes away from the neck, by the last stroke.
	var/head_gap = 4
	/// How far the body twitches with each stroke: the arms swinging, the legs jerking.
	var/twitch_arm = 30
	var/twitch_leg = 15

/datum/gms_kill_sequence/taste_tester/mouth/Play()
	// Knocked flat on their back.
	ActorInFront(FALSE)
	playsound(victim, 'sound/effects/meatslap.ogg', 60, TRUE)
	animate(scan, transform = Fallen(), time = knock_time, easing = BOUNCE_EASING)
	if(!Wait(knock_time))
		return
	// The tester walks over and kneels at their head.
	if(!WalkTo(kneel_x, kneel_y, WEST))
		return
	animate(actor, transform = Kneel(kneel_squash), time = kneel_time)
	if(!Wait(kneel_time))
		return
	// It saws at the neck, stroke after stroke, the body twitching, and the head comes away.
	var/obj/effect/gms_kill_visual/head = parts["head"]
	for(var/i in 1 to saws)
		animate(actor, transform = Kneel(kneel_squash, -saw_lean), time = saw_time / 2)
		animate(transform = Kneel(kneel_squash), time = saw_time / 2)
		playsound(victim, 'sound/weapons/bladeslice.ogg', 50, TRUE)
		Spray()
		var/matrix/apart = matrix()
		apart.Translate(0, head_gap * i / saws)
		animate(head, transform = apart, time = saw_time)
		var/side = (i % 2) ? 1 : -1
		PoseLimb("r_arm", twitch_arm * side, saw_time / 2)
		PoseLimb("l_arm", twitch_arm * side, saw_time / 2)
		PoseLimb("r_leg", twitch_leg * side, saw_time / 2)
		PoseLimb("l_leg", -twitch_leg * side, saw_time / 2)
		if(!Wait(saw_time))
			return
	// It sits back on its heels, and the body goes still.
	for(var/zone in joints)
		PoseLimb(zone, 0, sit_time)
	animate(actor, transform = matrix(), time = sit_time)
	if(!Wait(sit_time + hold_time))
		return
	Finish()

/// The head comes off and is left lying beside the body.
/datum/gms_kill_sequence/taste_tester/mouth/Aftermath()
	var/obj/item/bodypart/head/head = victim.get_bodypart(BODY_ZONE_HEAD)
	head?.drop_limb()
	victim.add_splatter_floor(get_turf(victim))

/datum/gms_kill_sequence/taste_tester/eye
	var/slump_time = 0.4 SECONDS
	var/rise_time = 0.6 SECONDS
	var/grab_time = 0.3 SECONDS
	var/tears = 6
	var/tear_time = 0.3 SECONDS
	var/hold_time = 1 SECONDS
	/// How low they sit, and how their arms hang.
	var/sit_squash = 0.7
	var/sit_arms = 20
	/// Where it looms: right behind them, rising this high, then leaning down onto them.
	var/loom_y = 8
	var/grab_y = 4
	var/tear_jerk = 2
	/// The victim clawing up at the tester's hands in turn, and kicking, as it tears.
	var/claw_arm = 120
	var/claw_wave = 25
	var/kick_leg = 20

/datum/gms_kill_sequence/taste_tester/eye/Play()
	// The victim slumps down to sit.
	ActorInFront(FALSE)
	playsound(victim, 'sound/effects/meatslap.ogg', 60, TRUE)
	animate(scan, transform = AboutFeet(0, 1, sit_squash), time = slump_time, easing = BOUNCE_EASING)
	PoseLimb("r_arm", sit_arms, slump_time)
	PoseLimb("l_arm", -sit_arms, slump_time)
	if(!Wait(slump_time))
		return
	// The tester walks up behind them and rises over them.
	if(!WalkTo(0, 0, SOUTH))
		return
	animate(actor, pixel_y = loom_y, time = rise_time, easing = SINE_EASING)
	if(!Wait(rise_time))
		return
	// It leans down and takes hold of their face, which goes dark.
	animate(actor, pixel_y = grab_y, time = grab_time, easing = QUAD_EASING | EASE_IN)
	animate(shadow, alpha = 255, time = grab_time * tears)
	if(!Wait(grab_time))
		return
	// It tears at their face, jerk after jerk, blood flying, as they claw at it and kick.
	for(var/i in 1 to tears)
		animate(actor, pixel_y = grab_y + tear_jerk, time = tear_time / 2, easing = QUAD_EASING | EASE_OUT)
		animate(pixel_y = grab_y, time = tear_time / 2)
		var/matrix/jolt = AboutFeet((i % 2) ? tear_jerk : -tear_jerk, 1, sit_squash)
		animate(scan, transform = jolt, time = tear_time / 2)
		animate(transform = AboutFeet(0, 1, sit_squash), time = tear_time / 2)
		var/side = (i % 2) ? 1 : -1
		PoseLimb("r_arm", -(claw_arm + claw_wave * side), tear_time / 2)
		PoseLimb("l_arm", claw_arm - claw_wave * side, tear_time / 2)
		PoseLimb("r_leg", kick_leg * side, tear_time / 2)
		PoseLimb("l_leg", kick_leg * side, tear_time / 2)
		playsound(victim, (i % 2) ? 'sound/effects/butcher.ogg' : 'sound/weapons/slice.ogg', 50, TRUE)
		Spray()
		if(!Wait(tear_time))
			return
	// Their arms drop.
	PoseLimb("r_arm", sit_arms, hold_time / 2)
	PoseLimb("l_arm", -sit_arms, hold_time / 2)
	PoseLimb("r_leg", 0, hold_time / 2)
	PoseLimb("l_leg", 0, hold_time / 2)
	if(!Wait(hold_time))
		return
	Finish()

/// Their face is gone, a mess of blood where it was.
/datum/gms_kill_sequence/taste_tester/eye/Aftermath()
	victim.AddComponent(/datum/component/gms_face_torn)

/datum/gms_kill_sequence/taste_tester/nose
	var/burst_time = 0.5 SECONDS
	var/land_time = 0.4 SECONDS
	var/kneel_time = 0.3 SECONDS
	var/rummages = 4
	var/rummage_time = 0.3 SECONDS
	var/stand_time = 0.3 SECONDS
	var/hold_time = 0.8 SECONDS
	/// Each part's flight: how far it flies up and out, how far it spins, and where it comes down, from where it was.
	var/list/flights = list(
		"head" = list(-6, 14, -200, -10, -2),
		"chest" = list(0, 6, 90, 0, -10),
		"r_arm" = list(-12, 8, -160, -14, -12),
		"l_arm" = list(12, 8, 160, 14, -12),
		"r_leg" = list(-8, 2, -120, -10, 0),
		"l_leg" = list(8, 2, 120, 10, 0),
		)
	/// Where it kneels among the pieces.
	var/kneel_x = 10
	var/kneel_y = 6
	var/kneel_squash = 0.8
	var/rummage_lean = 12
	/// The pieces it moves as it rummages, in order, and how far each is shifted and turned.
	var/list/rummage_order = list("r_leg", "l_arm", "head", "r_arm")
	var/nudge_x = 3
	var/nudge_y = 2
	var/nudge_turn = 40

/// A part's own transform: moved by (x, y) and turned `angle` about its own middle.
/datum/gms_kill_sequence/taste_tester/nose/proc/Flung(x, y, angle)
	var/matrix/M = matrix()
	M.Turn(angle)
	M.Translate(x, y)
	return M

/datum/gms_kill_sequence/taste_tester/nose/Play()
	// The victim bursts apart, every piece flying and spinning before it comes down.
	ActorInFront(TRUE)
	playsound(victim, 'sound/effects/gib_step.ogg', 70, TRUE)
	for(var/zone in flights)
		var/list/flight = flights[zone]
		animate(parts[zone], transform = Flung(flight[1], flight[2], flight[3] / 2), time = burst_time / 2, easing = QUAD_EASING | EASE_OUT)
		animate(transform = Flung(flight[4], flight[5], flight[3]), time = burst_time / 2 + land_time, easing = BOUNCE_EASING)
	Spray()
	Spray()
	if(!Wait(burst_time + land_time))
		return
	// The tester walks in and kneels among the pieces.
	if(!WalkTo(kneel_x, kneel_y, WEST))
		return
	animate(actor, transform = Kneel(kneel_squash), time = kneel_time)
	if(!Wait(kneel_time))
		return
	// It rummages through them, picking pieces up and setting them down again.
	for(var/i in 1 to rummages)
		animate(actor, transform = Kneel(kneel_squash, -rummage_lean), time = rummage_time / 2)
		animate(transform = Kneel(kneel_squash), time = rummage_time / 2)
		playsound(victim, 'sound/effects/gib_step.ogg', 40, TRUE)
		var/zone = rummage_order[(i - 1) % length(rummage_order) + 1]
		var/list/flight = flights[zone]
		var/side = (i % 2) ? 1 : -1
		animate(parts[zone], transform = Flung(flight[4] + nudge_x * side, flight[5] + nudge_y, flight[3] + nudge_turn * side), time = rummage_time, easing = SINE_EASING)
		if(!Wait(rummage_time))
			return
	animate(actor, transform = matrix(), time = stand_time)
	if(!Wait(stand_time + hold_time))
		return
	Finish()

/// Head, arms and legs come off and are flung across the floor around the torso.
/datum/gms_kill_sequence/taste_tester/nose/Aftermath()
	for(var/zone in list(BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		var/obj/item/bodypart/limb = victim.get_bodypart(zone)
		limb?.dismember()

/// A torn-away face on a body an eye taste tester has fed on. It goes once they are revived.
/datum/component/gms_face_torn
	var/mutable_appearance/gore

/datum/component/gms_face_torn/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/carbon/human/H = parent
	// Over hair and masks, under anything held, and only over the body's own pixels.
	gore = mutable_appearance('icons/mob/gms/gms_32x32.dmi', "taste_tester_face_torn", -(HANDS_LAYER + 0.5))
	gore.blend_mode = BLEND_INSET_OVERLAY
	H.add_overlay(gore)
	RegisterSignal(H, COMSIG_LIVING_REVIVE, PROC_REF(OnRevive))

/datum/component/gms_face_torn/Destroy()
	var/atom/A = parent
	A?.cut_overlay(gore)
	return ..()

/datum/component/gms_face_torn/proc/OnRevive(datum/source)
	SIGNAL_HANDLER
	qdel(src)
