// The Leather Glove's kill sequence: the glove crouches, leaps onto the victim's head and clamps on while they stagger
// with their hands up at it, then springs off taking the head with it. The headless body topples backwards, and the
// head is left on the floor beside it where the glove lands.

/datum/gms_kill_sequence/leather_glove
	/// Where the glove started, in pixels from the victim, and the tile it springs back to with the head.
	var/start_x = 0
	var/start_y = 0
	var/turf/landing_turf
	var/land_x = 0
	var/land_y = 0
	// Timings, in the order they play.
	var/sit_time = 1.5
	var/crouch_time = 5
	var/deep_crouch_time = 1.5
	var/leap_time = 1
	/// How long it stays clamped on, and how long each lurch of the struggle takes.
	var/struggle_time = 12.5
	var/lurch_time = 1.25
	var/rip_time = 1.5
	var/sway_time = 1.5
	var/fall_time = 3.5
	var/hold_time = 5
	/// Squash while crouching, as a fraction of its height.
	var/crouch_squash = 0.85
	var/deep_crouch_squash = 0.7
	/// Where the glove sits on the head, from the tile centre, and how far it tilts there.
	var/clamp_x = 0
	var/clamp_y = 19
	var/clamp_tilt = -20
	/// How high its leaps arc above a straight line.
	var/leap_arc = 10
	/// Where the torn-off head lands, from the middle of the glove's landing tile, so the glove does not cover it.
	var/head_land_x = 10
	var/head_land_y = -14
	// Limb angles, clockwise, for our left arm and leg (the victim's right); the other side mirrors them.
	/// Arms up at the glove on the head, and how much they wrench at it on each lurch.
	var/grab_arms = 155
	var/wrench_arms = 12
	/// How far the body sways and the legs shuffle while struggling.
	var/sway_body = 5
	var/shuffle_legs = 6
	/// The headless body hunching forward, its arms falling, and the limp pose it lands in.
	var/slump_body = -8
	var/drop_arms = 20
	var/limp_arms = 30
	var/limp_legs = 6

/datum/gms_kill_sequence/leather_glove/BuildScene()
	. = ..()
	// It leaps from where it really stood, and springs back that way with the head, or to any open tile beside the body.
	start_x = (killer.x - victim.x) * world.icon_size
	start_y = (killer.y - victim.y) * world.icon_size
	var/back_dir = get_dir(victim, killer)
	for(var/dir in list(back_dir) + GLOB.cardinals)
		var/turf/T = get_step(victim, dir)
		if(T && !T.is_blocked_turf(TRUE))
			landing_turf = T
			break
	if(!landing_turf)
		landing_turf = get_turf(victim)
	land_x = (landing_turf.x - victim.x) * world.icon_size
	land_y = (landing_turf.y - victim.y) * world.icon_size

/// Squashes the glove about its base, so it crouches into the floor rather than shrinking towards its middle.
/datum/gms_kill_sequence/leather_glove/proc/Squash(scale_y, angle = 0)
	var/half_tile = world.icon_size / 2
	var/matrix/M = matrix()
	M.Translate(0, half_tile)
	M.Scale(2 - scale_y, scale_y)
	M.Translate(0, -half_tile)
	M.Turn(angle)
	return M

/// Moves something in an arc from where it is to (x, y), peaking `arc` pixels above the straight line.
/datum/gms_kill_sequence/leather_glove/proc/Arc(atom/movable/thing, x, y, time, arc, list/end_transform)
	var/mid_x = (thing.pixel_x + x) / 2
	var/mid_y = (thing.pixel_y + y) / 2 + arc
	animate(thing, pixel_x = mid_x, pixel_y = mid_y, time = time / 2, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = x, pixel_y = y, transform = end_transform, time = time / 2, easing = SINE_EASING | EASE_IN)

/datum/gms_kill_sequence/leather_glove/proc/PoseArms(angle, time)
	PoseLimb("r_arm", angle, time)
	PoseLimb("l_arm", -angle, time)

/datum/gms_kill_sequence/leather_glove/Play()
	// Sitting where it stood, then crouching lower and lower.
	ActorInFront(start_y <= 0)
	actor.pixel_x = start_x
	actor.pixel_y = start_y
	if(!Wait(sit_time))
		return
	animate(actor, transform = Squash(crouch_squash), time = crouch_time)
	if(!Wait(crouch_time))
		return
	animate(actor, transform = Squash(deep_crouch_squash), time = deep_crouch_time)
	if(!Wait(deep_crouch_time))
		return
	// The leap onto the head. Clamped on, it rides along with the body as it sways.
	ActorInFront(TRUE)
	Arc(actor, clamp_x, clamp_y, leap_time, leap_arc, matrix().Turn(clamp_tilt))
	if(!Wait(leap_time))
		return
	playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/leather_glove_attack.ogg', 60, TRUE)
	holder.vis_contents -= actor
	scan.vis_contents += actor
	// The struggle: hands up at the glove, wrenching at it, the body lurching and the feet shuffling.
	PoseArms(grab_arms, leap_time)
	var/lurches = round(struggle_time / lurch_time)
	for(var/i in 1 to lurches)
		var/side = (i % 2) ? 1 : -1
		animate(scan, transform = AboutFeet(sway_body * side), time = lurch_time)
		PoseArms(grab_arms + wrench_arms * side, lurch_time)
		PoseLimb("r_leg", shuffle_legs * side, lurch_time)
		PoseLimb("l_leg", shuffle_legs * side, lurch_time)
		animate(actor, transform = matrix().Turn(clamp_tilt - 10 * side), time = lurch_time)
		if(!Wait(lurch_time))
			return
	// The rip: the glove springs off with the head and both land on the tile beside the body.
	playsound(victim, 'sound/effects/dismember.ogg', 70, TRUE)
	var/obj/effect/gms_kill_visual/head = parts["head"]
	scan.vis_contents -= actor
	scan.vis_contents -= head
	holder.vis_contents += actor
	holder.vis_contents += head
	Arc(actor, land_x, land_y, rip_time, leap_arc * 2, matrix())
	// The head trails below the glove and ends up on its side on the floor of that tile, just clear of the glove.
	Arc(head, land_x + head_land_x, land_y + head_land_y, rip_time, leap_arc, AboutJoint("head", 90))
	// The headless body slumps forward with its arms falling, sways, then topples backwards.
	animate(scan, transform = AboutFeet(slump_body), time = rip_time)
	PoseArms(drop_arms, rip_time)
	PoseLimb("r_leg", 0, rip_time)
	PoseLimb("l_leg", 0, rip_time)
	if(!Wait(rip_time + sway_time))
		return
	animate(scan, transform = Fallen(), time = fall_time, easing = QUAD_EASING | EASE_IN)
	PoseArms(limp_arms, fall_time)
	PoseLimb("r_leg", limp_legs, fall_time)
	PoseLimb("l_leg", -limp_legs, fall_time)
	if(!Wait(fall_time + hold_time))
		return
	Finish()

/// The real head comes off and is left where the glove dropped it, with whatever the victim wore on it at their feet.
/datum/gms_kill_sequence/leather_glove/Aftermath()
	var/obj/item/bodypart/head/head = victim.get_bodypart(BODY_ZONE_HEAD)
	if(!head)
		return
	victim.add_splatter_floor(get_turf(victim))
	head.drop_limb()
	head.forceMove(landing_turf)

/datum/gms_kill_sequence/leather_glove/ReleaseTurf()
	return landing_turf
