// Kill sequences for GMS foes. When a foe kills a human, the body is hidden and a frozen copy of it (the scan), upright
// and facing south, plays out the death instead, with the foe acting it out beside it. The foe itself waits inside the
// body. It is all drawn through the body's vis_contents, so it follows the body if it is dragged, thrown or moved.
// Each foe's subtype writes its own Play() and what is left of the body afterwards in Aftermath().

/// A piece of a kill scene. None of them can be clicked; the body underneath still can.
/obj/effect/gms_kill_visual
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/gms_kill_sequence
	var/mob/living/simple_animal/hostile/gms_foe/killer
	var/mob/living/carbon/human/victim
	/// Hangs off the body but ignores its transform and alpha, so the scene stays upright and visible whatever the body does.
	var/obj/effect/gms_kill_visual/holder
	/// The frozen copy of the victim as a whole. It draws nothing itself: its parts hang off it, so turning it turns them all.
	var/obj/effect/gms_kill_visual/scan
	/// Body part -> its piece of the frozen copy, cut out with a mask so it can move on its own.
	var/list/parts = list()
	/// Parts in drawing order, back to front: arms over the chest, everything over the legs.
	var/list/part_order = list("r_leg", "l_leg", "chest", "head", "r_arm", "l_arm")
	/// Where each part turns about, in pixels from the tile centre with y up. r_ is the victim's right, on our left.
	var/list/joints = list("head" = list(-0.5, 6.5), "r_arm" = list(-5, 4), "l_arm" = list(4, 4), "r_leg" = list(-2.5, -7.5), "l_leg" = list(2, -7.5))
	/// The foe's place in the scene, using its own sprite.
	var/obj/effect/gms_kill_visual/actor
	/// Where the foe is let out if the body vanishes partway through.
	var/turf/last_turf
	/// The body's alpha before it was hidden, put back when the scene ends.
	var/old_alpha

/datum/gms_kill_sequence/New(mob/living/simple_animal/hostile/gms_foe/new_killer, mob/living/carbon/human/new_victim)
	killer = new_killer
	victim = new_victim
	last_turf = get_turf(victim)
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(OnVictimDeleted))
	RegisterSignal(killer, COMSIG_PARENT_QDELETING, PROC_REF(OnKillerDeleted))
	BuildScene()
	killer.forceMove(victim)
	INVOKE_ASYNC(src, PROC_REF(Play))

/datum/gms_kill_sequence/Destroy()
	ClearScene()
	killer = null
	victim = null
	return ..()

/// Copies the victim upright and facing south, hides the real body, and hangs the scene off it.
/datum/gms_kill_sequence/proc/BuildScene()
	holder = new
	// Humans draw KEEP_TOGETHER, which flattens their vis_contents into them and would hide the scene along with the
	// body; KEEP_APART keeps the scene out of that, and the resets keep it upright and visible.
	holder.appearance_flags = RESET_TRANSFORM | RESET_ALPHA | RESET_COLOR | KEEP_APART
	var/mutable_appearance/copy = new(victim)
	copy.dir = SOUTH
	copy.transform = matrix()
	copy.alpha = 255
	copy.pixel_x = 0
	copy.pixel_y = 0
	scan = new
	scan.vis_flags = VIS_INHERIT_PLANE
	scan.layer = MOB_LAYER
	// Each part is the whole copy masked down to one body part, so clothes, hair and hats move with the part they cover.
	for(var/zone in part_order)
		var/obj/effect/gms_kill_visual/part = new
		part.appearance = copy
		part.appearance_flags |= KEEP_TOGETHER
		part.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		part.vis_flags = VIS_INHERIT_PLANE
		part.layer = MOB_LAYER
		part.add_filter("gms_kill_mask", 1, alpha_mask_filter(icon = icon('icons/mob/gms/gms_32x32.dmi', "gms_kill_mask_[zone]")))
		scan.vis_contents += part
		parts[zone] = part
	actor = new
	actor.icon = killer.icon
	actor.icon_state = killer.icon_living
	holder.vis_contents += scan
	holder.vis_contents += actor
	old_alpha = victim.alpha
	victim.alpha = 0
	victim.vis_contents += holder

/datum/gms_kill_sequence/proc/ClearScene()
	if(victim)
		victim.vis_contents -= holder
	QDEL_LIST_ASSOC_VAL(parts)
	QDEL_NULL(scan)
	QDEL_NULL(actor)
	QDEL_NULL(holder)

/// The foe drawn in front of the victim or behind them.
/datum/gms_kill_sequence/proc/ActorInFront(in_front)
	actor.layer = in_front ? MOB_LAYER + 0.01 : MOB_LAYER - 0.01

/// A transform that scales and turns the scan about its feet, at the bottom of the tile, rather than its middle.
/datum/gms_kill_sequence/proc/AboutFeet(angle = 0, scale_x = 1, scale_y = 1)
	var/half_tile = world.icon_size / 2
	var/matrix/M = matrix()
	M.Translate(0, half_tile)
	M.Scale(scale_x, scale_y)
	M.Turn(angle)
	M.Translate(0, -half_tile)
	return M

/// A transform that turns a part about its joint.
/datum/gms_kill_sequence/proc/AboutJoint(zone, angle)
	var/list/joint = joints[zone]
	var/matrix/M = matrix()
	M.Translate(-joint[1], -joint[2])
	M.Turn(angle)
	M.Translate(joint[1], joint[2])
	return M

/// Turns a part about its joint over time. Angles are clockwise, so a positive angle swings our left arm (their right) outward.
/datum/gms_kill_sequence/proc/PoseLimb(zone, angle, time, easing = LINEAR_EASING)
	animate(parts[zone], transform = AboutJoint(zone, angle), time = time, easing = easing)

/// Lying flat on its back with the head to the right, centred across the lower half of the tile.
/datum/gms_kill_sequence/proc/Fallen()
	var/matrix/M = AboutFeet(90)
	M.Translate(-world.icon_size / 2, world.icon_size / 4)
	return M

/// Sleeps, then reports whether the sequence should carry on. Only losing the body or the foe stops it.
/datum/gms_kill_sequence/proc/Wait(time)
	sleep(time)
	if(QDELETED(src) || QDELETED(victim) || QDELETED(killer))
		return FALSE
	last_turf = get_turf(victim)
	return TRUE

/// The foe's part of the scene, ending with Finish().
/datum/gms_kill_sequence/proc/Play()
	Finish()

/// What the kill leaves on the body once the scene is over.
/datum/gms_kill_sequence/proc/Aftermath()
	return

/// Where the foe is let out when the scene is over.
/datum/gms_kill_sequence/proc/ReleaseTurf()
	return last_turf

/// Shows the real body again with what the kill left on it, and lets the foe out.
/datum/gms_kill_sequence/proc/Finish()
	UnregisterSignal(victim, COMSIG_PARENT_QDELETING)
	UnregisterSignal(killer, COMSIG_PARENT_QDELETING)
	ClearScene()
	victim.alpha = old_alpha
	Aftermath()
	killer.forceMove(ReleaseTurf())
	killer.EndKill()
	qdel(src)

/datum/gms_kill_sequence/proc/OnVictimDeleted(datum/source)
	SIGNAL_HANDLER
	if(killer && !isturf(killer.loc))
		killer.forceMove(last_turf)
	killer?.EndKill()
	victim = null
	qdel(src)

/datum/gms_kill_sequence/proc/OnKillerDeleted(datum/source)
	SIGNAL_HANDLER
	victim.alpha = old_alpha
	killer = null
	qdel(src)
