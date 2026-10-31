// The Needlekin's kill sequence. The victim's face darkens and they clutch their head, staggering, as needles drive
// into their head and body one after another. They collapse flat, bristling with pins, and a green and a red needlekin
// peek out from behind the body (whichever made the kill, the other is only drawn). The body keeps its needles.

/datum/gms_kill_sequence/needlekin
	/// The other needlekin of the pair, drawn only.
	var/obj/effect/gms_kill_visual/partner
	/// The shadow that creeps over the victim's face.
	var/obj/effect/gms_kill_visual/shadow
	/// The needles in the body, more with every stab.
	var/obj/effect/gms_kill_visual/needles
	// Timings, in the order they play.
	var/darken_time = 0.3 SECONDS
	var/stabs = 6
	var/stab_time = 0.2 SECONDS
	var/fall_time = 0.4 SECONDS
	var/peek_time = 0.4 SECONDS
	var/hold_time = 1 SECONDS
	/// How dark the face goes before the needles finish it.
	var/darken_shadow = 160
	/// The victim's hands at their head, how far each stab rocks them, and the hand that falls away at the last one.
	var/clutch_arm = 150
	var/stagger_lean = 8
	var/dropped_arm = 30
	/// Where the needlekin peek out from, behind the fallen body.
	var/green_x = -8
	var/red_x = 10
	var/peek_y = 12

/datum/gms_kill_sequence/needlekin/BuildScene()
	. = ..()
	shadow = new
	shadow.icon = 'icons/mob/gms/gms_32x32.dmi'
	shadow.icon_state = "mobile_go_spin_kill_shadow"
	shadow.blend_mode = BLEND_INSET_OVERLAY
	shadow.alpha = 0
	var/obj/effect/gms_kill_visual/head = parts["head"]
	head.vis_contents += shadow
	// Hung off the scan so the needles fall with the body.
	needles = new
	needles.icon = 'icons/mob/gms/gms_32x32.dmi'
	needles.vis_flags = VIS_INHERIT_PLANE
	needles.layer = MOB_LAYER + 0.02
	scan.vis_contents += needles
	var/killer_is_red = istype(killer, /mob/living/simple_animal/hostile/gms_foe/needlekin/red)
	partner = new
	partner.icon = killer.icon
	partner.icon_state = killer_is_red ? "green_needlekin" : "red_needlekin"
	holder.vis_contents += partner
	// Both stay out of sight behind the body until they peek out.
	for(var/obj/effect/gms_kill_visual/kin in list(actor, partner))
		kin.alpha = 0
		kin.layer = MOB_LAYER - 0.01
		kin.pixel_y = peek_y
	actor.pixel_x = killer_is_red ? red_x : green_x
	partner.pixel_x = killer_is_red ? green_x : red_x

/datum/gms_kill_sequence/needlekin/ClearScene()
	QDEL_NULL(shadow)
	QDEL_NULL(needles)
	QDEL_NULL(partner)
	return ..()

/datum/gms_kill_sequence/needlekin/Play()
	// Their face darkens and their hands go to their head.
	animate(shadow, alpha = darken_shadow, time = darken_time)
	PoseLimb("r_arm", -clutch_arm, darken_time)
	PoseLimb("l_arm", clutch_arm, darken_time)
	if(!Wait(darken_time))
		return
	// Needles drive in one after another, each rocking them, the face going fully dark.
	animate(shadow, alpha = 255, time = stab_time * stabs)
	for(var/i in 1 to stabs)
		var/side = (i % 2) ? 1 : -1
		needles.icon_state = "needlekin_needles_[i]"
		playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/needlekin_stab.ogg', 40, TRUE)
		animate(scan, transform = AboutFeet(stagger_lean * side), time = stab_time / 2, easing = QUAD_EASING | EASE_OUT)
		animate(transform = matrix(), time = stab_time / 2)
		if(i == stabs)
			PoseLimb("r_arm", dropped_arm, stab_time)
		if(!Wait(stab_time))
			return
	// They collapse flat on their back.
	playsound(victim, 'sound/effects/splat.ogg', 50, TRUE)
	animate(scan, transform = Fallen(), time = fall_time, easing = BOUNCE_EASING)
	PoseLimb("r_arm", 0, fall_time)
	PoseLimb("l_arm", 0, fall_time)
	if(!Wait(fall_time))
		return
	// The needlekin peek out from behind the body.
	animate(actor, alpha = 255, time = peek_time)
	animate(partner, alpha = 255, time = peek_time)
	if(!Wait(peek_time + hold_time))
		return
	Finish()

/// The body keeps every needle.
/datum/gms_kill_sequence/needlekin/Aftermath()
	victim.AddComponent(/datum/component/gms_pinned)

/// Needles left in a body the needlekin killed. They go once the body is revived.
/datum/component/gms_pinned
	var/mutable_appearance/pins

/datum/component/gms_pinned/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/carbon/human/H = parent
	// Over clothing, under anything held. Pins stick out past the body, so they are not clipped to it.
	pins = mutable_appearance('icons/mob/gms/gms_32x32.dmi', "needlekin_needles_6", -(HANDS_LAYER + 0.5))
	H.add_overlay(pins)
	RegisterSignal(H, COMSIG_LIVING_REVIVE, PROC_REF(OnRevive))

/datum/component/gms_pinned/Destroy()
	var/atom/A = parent
	A?.cut_overlay(pins)
	return ..()

/datum/component/gms_pinned/proc/OnRevive(datum/source)
	SIGNAL_HANDLER
	qdel(src)
