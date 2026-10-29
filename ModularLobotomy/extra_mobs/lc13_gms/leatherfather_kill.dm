// The Leatherfather's kill sequence. It never leaves its tile: the victim is drawn up against its open robe, and while it
// only watches, they twist and bend against themselves, their arm wrenched up and back. Yellow thread laces them in down
// the chest while their face greys and their head droops. Then it flays them, pinned spread-armed in the robe, and
// lets the body fall back to where they stood, skinned red.

/datum/gms_kill_sequence/leatherfather
	/// The Leatherfather's own tile, and its offset from the victim. The scene happens there.
	var/turf/home_turf
	var/home_x = 0
	var/home_y = 0
	/// The thread, the shadow over the face and the raw flesh under the skin.
	var/obj/effect/gms_kill_visual/stitches
	var/obj/effect/gms_kill_visual/shadow
	var/obj/effect/gms_kill_visual/flesh
	// Timings, in the order they play.
	var/pull_time = 0.8 SECONDS
	var/reach_time = 0.3 SECONDS
	/// Each twist bends them the other way.
	var/twists = 4
	var/twist_time = 0.35 SECONDS
	var/stitch_time = 1.2 SECONDS
	var/droop_time = 0.6 SECONDS
	var/flay_time = 0.6 SECONDS
	var/hold_time = 1.2 SECONDS
	var/fall_time = 0.6 SECONDS
	var/settle_time = 0.6 SECONDS
	/// How far below the middle of its tile the victim stands against the robe, and how far up they are pinned once flayed.
	var/front_y = -2
	var/pin_rise = 3
	/// The arm they raise, then how far each twist leans the body, wrenches that arm back and tips the head the other way.
	var/reach_angle = -100
	var/twist_lean = 10
	var/twist_arm = 50
	var/twist_head = 15
	var/twist_other_arm = 30
	/// How far the head droops, and how wide the arms are pinned once flayed.
	var/droop_angle = 18
	var/splay_arms = 75
	/// How dark the face goes while they are laced in.
	var/grey_shadow = 120
	/// The colour matrix that turns the body raw red, kept on the corpse afterwards.
	var/list/flay_color = list(0.6, 0.05, 0.05, 0.25, 0.08, 0.06, 0.2, 0.06, 0.08, 0.2, 0, 0)

/datum/gms_kill_sequence/leatherfather/BuildScene()
	. = ..()
	home_turf = get_turf(killer)
	home_x = (killer.x - victim.x) * world.icon_size
	home_y = (killer.y - victim.y) * world.icon_size
	// It may still be swollen from the slam, so it is drawn standing as usual.
	actor.icon = initial(killer.icon)
	actor.icon_state = killer.icon_living
	actor.pixel_x = home_x + killer.base_pixel_x
	actor.pixel_y = home_y
	// Drawn only over the body's own pixels, keeping their colours when the body turns red.
	var/obj/effect/gms_kill_visual/chest = parts["chest"]
	var/obj/effect/gms_kill_visual/head = parts["head"]
	flesh = InsetVisual("leatherfather_kill_flesh", chest)
	stitches = InsetVisual("leatherfather_kill_stitches", chest)
	shadow = InsetVisual("mobile_go_spin_kill_shadow", head)
	// The thread starts lacing when it gets its sprite.
	stitches.icon_state = null

/datum/gms_kill_sequence/leatherfather/ClearScene()
	QDEL_NULL(stitches)
	QDEL_NULL(shadow)
	QDEL_NULL(flesh)
	return ..()

/// A hidden sprite drawn only over the pixels of `part`, keeping its own colours.
/datum/gms_kill_sequence/leatherfather/proc/InsetVisual(state, obj/effect/gms_kill_visual/part)
	var/obj/effect/gms_kill_visual/V = new
	V.icon = 'icons/mob/gms/gms_32x32.dmi'
	V.icon_state = state
	V.blend_mode = BLEND_INSET_OVERLAY
	V.appearance_flags |= RESET_COLOR
	V.alpha = 0
	part.vis_contents += V
	return V

/// The scan moved onto the Leatherfather's tile, `rise` pixels above where it stands against the robe, leaning `lean`
/// degrees about its feet.
/datum/gms_kill_sequence/leatherfather/proc/AtRobe(rise = 0, lean = 0)
	var/matrix/M = AboutFeet(lean)
	M.Translate(home_x, home_y + front_y + rise)
	return M

/datum/gms_kill_sequence/leatherfather/Play()
	// Drawn up against the robe, in front of it.
	ActorInFront(FALSE)
	playsound(victim, 'sound/effects/creak1.ogg', 60, TRUE)
	animate(scan, transform = AtRobe(), time = pull_time, easing = QUAD_EASING | EASE_OUT)
	if(!Wait(pull_time))
		return
	// They raise an arm, then twist and bend one way and the other, the arm wrenched back and the head tipping.
	PoseLimb("l_arm", reach_angle, reach_time)
	if(!Wait(reach_time))
		return
	for(var/i in 1 to twists)
		var/side = (i % 2) ? 1 : -1
		playsound(victim, 'sound/effects/wounds/crack1.ogg', 40, TRUE)
		animate(scan, transform = AtRobe(0, twist_lean * side), time = twist_time, easing = BACK_EASING | EASE_OUT)
		PoseLimb("l_arm", reach_angle - twist_arm * side, twist_time, BACK_EASING | EASE_OUT)
		PoseLimb("r_arm", twist_other_arm * side, twist_time, BACK_EASING | EASE_OUT)
		PoseLimb("head", -twist_head * side, twist_time, BACK_EASING | EASE_OUT)
		if(!Wait(twist_time))
			return
	animate(scan, transform = AtRobe(), time = twist_time)
	// Laced in down the chest while their face greys.
	stitches.icon_state = "leatherfather_kill_stitches"
	stitches.alpha = 255
	playsound(victim, 'sound/weapons/bladeslice.ogg', 30, TRUE)
	animate(shadow, alpha = grey_shadow, time = stitch_time)
	if(!Wait(stitch_time))
		return
	// The head droops and the face goes dark.
	PoseLimb("head", droop_angle, droop_time, SINE_EASING)
	animate(shadow, alpha = 255, time = droop_time)
	if(!Wait(droop_time))
		return
	// Flayed: the skin comes away red and raw, and they are pinned up in the robe with their arms spread.
	playsound(victim, 'sound/effects/butcher.ogg', 70, TRUE)
	animate(scan, transform = AtRobe(pin_rise), time = flay_time, easing = QUAD_EASING | EASE_OUT)
	animate(flesh, alpha = 255, time = flay_time)
	for(var/zone in parts)
		animate(parts[zone], color = flay_color, time = flay_time)
	PoseLimb("r_arm", splay_arms, flay_time, QUAD_EASING | EASE_OUT)
	PoseLimb("l_arm", -splay_arms, flay_time, QUAD_EASING | EASE_OUT)
	if(!Wait(flay_time + hold_time))
		return
	// Let go, the body falls back to where they stood.
	playsound(victim, 'sound/effects/splat.ogg', 50, TRUE)
	animate(scan, transform = Fallen(), time = fall_time, easing = BOUNCE_EASING)
	for(var/zone in joints)
		PoseLimb(zone, 0, fall_time)
	if(!Wait(fall_time + settle_time))
		return
	Finish()

/// The body is left skinned red where they stood, clothes and all.
/datum/gms_kill_sequence/leatherfather/Aftermath()
	victim.AddComponent(/datum/component/gms_flayed, flay_color)

/datum/gms_kill_sequence/leatherfather/ReleaseTurf()
	return home_turf

/// A body flayed by a Leatherfather: drawn red, with the raw ribs showing down the chest. It goes away if they are
/// brought back to life.
/datum/component/gms_flayed
	var/mutable_appearance/flesh

/datum/component/gms_flayed/Initialize(list/flay_color)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/carbon/human/H = parent
	H.add_filter("gms_flayed", 1, color_matrix_filter(flay_color))
	// Over clothing and belts, under anything held, and only over the body's own pixels.
	flesh = mutable_appearance('icons/mob/gms/gms_32x32.dmi', "leatherfather_kill_flesh", -(HANDS_LAYER + 0.5))
	flesh.blend_mode = BLEND_INSET_OVERLAY
	H.add_overlay(flesh)
	RegisterSignal(H, COMSIG_LIVING_REVIVE, PROC_REF(OnRevive))

/datum/component/gms_flayed/Destroy()
	var/atom/A = parent
	A?.remove_filter("gms_flayed")
	A?.cut_overlay(flesh)
	return ..()

/datum/component/gms_flayed/proc/OnRevive(datum/source)
	SIGNAL_HANDLER
	qdel(src)
