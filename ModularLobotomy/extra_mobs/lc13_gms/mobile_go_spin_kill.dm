// The Mobile-Go-Spin's kill sequence: the top circles the victim, then dives into their chest and disappears inside.
// Their head goes dark, they stagger and topple, and the top bursts back out of the chest and settles on the body,
// which is left behind with a hole through the chest.

/datum/gms_kill_sequence/mobile_go_spin
	/// The shadow that creeps over the scan's head.
	var/obj/effect/gms_kill_visual/shadow
	/// The hole it leaves in the chest, shown once it bursts back out.
	var/obj/effect/gms_kill_visual/hole
	// Timings, in the order they play.
	var/orbit_time = 5
	/// The dive: a short arc from the victim's left into their chest.
	var/dive_time = 2.5
	var/jolt_time = 0.5
	var/bulge_time = 1
	var/hunch_time = 5
	var/stagger_step = 1.5
	/// Angles it rocks through while staggering, clockwise positive.
	var/list/stagger_angles = list(-6, 5, -4, 7, -3, 6)
	var/fall_time = 4
	var/bounce_time = 0.5
	/// Bursting back out of the chest, and dropping onto it.
	var/burst_time = 1.5
	var/settle_time = 1.5
	/// How long the top sits on the body before the scene ends.
	var/hold_time = 5
	/// How high its arcs rise above a straight line, and how small it shrinks going in and coming out.
	var/dive_arc = 10
	var/inside_scale = 0.4
	/// How much the chest swells when the top goes in.
	var/bulge_scale = 1.15
	/// The top's offset when centred on the standing chest, and on the fallen one.
	var/chest_x = 0
	var/chest_y = 2
	var/fallen_chest_x = 0
	var/fallen_chest_y = -4
	/// How high it bursts out, and where it perches on the fallen body.
	var/burst_height = 18
	var/perch_x = 4
	var/perch_y = 12
	// Limb angles, clockwise, for our left arm and leg (the victim's right); the other side mirrors them.
	/// How far the arms fling out and the head snaps back when the top goes in.
	var/fling_arms = 35
	var/fling_head = 10
	/// The arms pulled in to the chest and the head bowed while hunching.
	var/clutch_arms = -15
	var/bow_head = 4
	/// How much the head lolls and the legs brace against each stagger.
	var/loll_head = 1.5
	var/brace_legs = 0.8
	/// Flailing limbs while toppling, and the limp pose they settle into.
	var/flail_arms = 70
	var/flail_legs = 15
	var/flail_head = 20
	var/limp_arms = 25
	var/limp_legs = 5
	var/limp_head = 10

/datum/gms_kill_sequence/mobile_go_spin/BuildScene()
	. = ..()
	// Drawn only over the scan's own pixels, so it darkens the head without spilling past it.
	shadow = new
	shadow.icon = 'icons/mob/gms/gms_32x32.dmi'
	shadow.icon_state = "mobile_go_spin_kill_shadow"
	shadow.blend_mode = BLEND_INSET_OVERLAY
	shadow.alpha = 0
	var/obj/effect/gms_kill_visual/head = parts["head"]
	head.vis_contents += shadow
	// Rides on the chest part, so it turns and falls with it; hidden until the top bursts out.
	hole = new
	hole.icon = 'icons/mob/gms/gms_32x32.dmi'
	hole.icon_state = "mobile_go_spin_chest_hole"
	hole.alpha = 0
	var/obj/effect/gms_kill_visual/chest = parts["chest"]
	chest.vis_contents += hole

/datum/gms_kill_sequence/mobile_go_spin/ClearScene()
	QDEL_NULL(shadow)
	QDEL_NULL(hole)
	return ..()

/// Shrinks or grows the top about its middle.
/datum/gms_kill_sequence/mobile_go_spin/proc/TopScale(scale)
	var/matrix/M = matrix()
	M.Scale(scale)
	return M

/// Moves the top in an arc from where it is to (x, y), peaking `arc` pixels above the straight line.
/datum/gms_kill_sequence/mobile_go_spin/proc/Arc(x, y, time, arc, scale = 1, end_alpha = 255, easing = SINE_EASING)
	var/mid_x = (actor.pixel_x + x) / 2
	var/mid_y = (actor.pixel_y + y) / 2 + arc
	animate(actor, pixel_x = mid_x, pixel_y = mid_y, transform = TopScale((1 + scale) / 2), time = time / 2, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = x, pixel_y = y, transform = TopScale(scale), alpha = end_alpha, time = time / 2, easing = easing | EASE_IN)

/datum/gms_kill_sequence/mobile_go_spin/Play()
	// Circling: from the victim's right, across in front of them, then round behind them on their left.
	ActorInFront(TRUE)
	actor.pixel_x = 18
	actor.pixel_y = -4
	playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/mobile_go_spin_windup.ogg', 30, TRUE)
	animate(actor, pixel_x = 0, pixel_y = -7, time = orbit_time / 2)
	animate(pixel_x = -18, pixel_y = -3, time = orbit_time / 2)
	if(!Wait(orbit_time / 2))
		return
	ActorInFront(FALSE)
	if(!Wait(orbit_time / 2))
		return
	// The dive: it springs from their left in a short arc and goes into their chest, shrinking away as it enters.
	ActorInFront(TRUE)
	Arc(chest_x, chest_y, dive_time, dive_arc, inside_scale, 0)
	if(!Wait(dive_time))
		return
	playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/gms_foe_ram_hit.ogg', 70, TRUE)
	animate(scan, pixel_x = 3, time = jolt_time)
	animate(pixel_x = 0, time = jolt_time)
	var/obj/effect/gms_kill_visual/chest = parts["chest"]
	var/matrix/bulge = matrix()
	bulge.Scale(bulge_scale)
	animate(chest, transform = bulge, time = bulge_time / 2)
	animate(transform = matrix(), time = bulge_time / 2)
	PoseArms(fling_arms, jolt_time)
	PoseLimb("head", -fling_head, jolt_time)
	if(!Wait(bulge_time))
		return
	// Hunching over while the shadow takes the head.
	animate(scan, transform = AboutFeet(0, 1.04, 0.92), time = hunch_time)
	animate(shadow, alpha = 255, time = hunch_time)
	PoseArms(clutch_arms, hunch_time)
	PoseLimb("head", bow_head, hunch_time)
	if(!Wait(hunch_time))
		return
	// Staggering on the spot: the head lolls with each lurch, the arms hang, and the legs brace against it.
	for(var/angle in stagger_angles)
		animate(scan, transform = AboutFeet(angle), time = stagger_step)
		PoseLimb("head", angle * loll_head, stagger_step)
		PoseLimb("r_arm", -angle, stagger_step)
		PoseLimb("l_arm", -angle, stagger_step)
		PoseLimb("r_leg", -angle * brace_legs, stagger_step)
		PoseLimb("l_leg", -angle * brace_legs, stagger_step)
		if(!Wait(stagger_step))
			return
	// Toppling backwards, then settling with a small bounce.
	animate(scan, transform = Fallen(), time = fall_time, easing = QUAD_EASING | EASE_IN)
	PoseArms(flail_arms, fall_time)
	PoseLegs(flail_legs, fall_time)
	PoseLimb("head", flail_head, fall_time)
	if(!Wait(fall_time))
		return
	animate(scan, pixel_y = 2, time = bounce_time)
	animate(pixel_y = 0, time = bounce_time)
	PoseArms(limp_arms, bounce_time * 2)
	PoseLegs(limp_legs, bounce_time * 2)
	PoseLimb("head", limp_head, bounce_time * 2)
	if(!Wait(bounce_time * 2))
		return
	// It bursts back out of the chest, leaving the hole, then drops onto the body.
	playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/gms_foe_ram_hit.ogg', 70, TRUE)
	actor.pixel_x = fallen_chest_x
	actor.pixel_y = fallen_chest_y
	actor.transform = TopScale(inside_scale)
	actor.alpha = 255
	hole.alpha = 255
	animate(scan, pixel_y = 2, time = bounce_time)
	animate(pixel_y = 0, time = bounce_time)
	animate(actor, pixel_x = perch_x, pixel_y = fallen_chest_y + burst_height, transform = TopScale(1), time = burst_time, easing = SINE_EASING | EASE_OUT)
	animate(pixel_y = perch_y, time = settle_time, easing = BOUNCE_EASING)
	if(!Wait(burst_time + settle_time + hold_time))
		return
	Finish()

/// Both arms at once, mirrored: a positive angle swings them both outward.
/datum/gms_kill_sequence/mobile_go_spin/proc/PoseArms(angle, time)
	PoseLimb("r_arm", angle, time)
	PoseLimb("l_arm", -angle, time)

/datum/gms_kill_sequence/mobile_go_spin/proc/PoseLegs(angle, time)
	PoseLimb("r_leg", angle, time)
	PoseLimb("l_leg", -angle, time)

/datum/gms_kill_sequence/mobile_go_spin/Aftermath()
	victim.AddComponent(/datum/component/gms_chest_hole)

/// A hole through the chest where a Mobile-Go-Spin went through. It closes up if they are brought back to life.
/datum/component/gms_chest_hole
	var/mutable_appearance/hole

/datum/component/gms_chest_hole/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	// Over clothing and belts, under anything held.
	hole = mutable_appearance('icons/mob/gms/gms_32x32.dmi', "mobile_go_spin_chest_hole", -(HANDS_LAYER + 0.5))
	var/mob/living/carbon/human/H = parent
	H.add_overlay(hole)
	RegisterSignal(H, COMSIG_LIVING_REVIVE, PROC_REF(OnRevive))

/datum/component/gms_chest_hole/Destroy()
	var/atom/A = parent
	A?.cut_overlay(hole)
	return ..()

/datum/component/gms_chest_hole/proc/OnRevive(datum/source)
	SIGNAL_HANDLER
	qdel(src)
