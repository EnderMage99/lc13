// The Denim Wallet's kill sequence. The wallet never leaves its tile: it swells up and opens its maw, the victim is
// yanked off their feet onto it head first, and it chews them down bite by bite while they kick, until nothing is left.
// Then it spits out bones and a skull. The body is left as a skeleton lying where they stood, with everything they
// carried spat out on the floor around it.

/datum/gms_kill_sequence/denim_wallet
	/// The shadow that creeps over the victim's head.
	var/obj/effect/gms_kill_visual/shadow
	/// The bones it spits out.
	var/list/spat = list()
	/// The wallet's own tile, and its offset from the victim. The scene happens there.
	var/turf/home_turf
	var/home_x = 0
	var/home_y = 0
	// Timings, in the order they play.
	var/swell_time = 2
	var/yank_time = 2
	/// Each bite shuts the mouth on them and opens it again, and takes a step off their size.
	var/bites = 7
	var/bite_time = 1.6
	/// Empty chews once they are gone.
	var/chews = 2
	var/chew_time = 1.6
	/// Each bone takes this long to fly back to where the victim stood, and the next follows after the gap.
	var/spit_time = 3
	var/spit_gap = 1
	var/hold_time = 5
	var/shrink_time = 2
	/// How big it swells to fit someone, and how far down each bite or chew squashes it.
	var/swell_scale = 1.35
	var/bite_squash = 0.85
	/// How far above the middle of its tile its open mouth is once swollen.
	var/mouth_rise = 4
	/// The victim tipped head first across the mouth: the angle, and how far to shift them so the middle of their body
	/// sits over the mouth (tipping them about their feet leaves it up and to the left).
	var/yank_angle = -65
	var/yank_x = 14
	var/yank_y = 9
	/// How small the victim is after the last bite.
	var/eaten_scale = 0.1
	/// How dark the victim's head is while the wallet looms, before it goes fully dark.
	var/loom_shadow = 120
	/// The skeleton's parts it spits out, in order, each with the sprites drawn for it, skull last. They are the same
	/// limb sprites the skeleton itself is drawn with, so they land laid out as the skeleton left behind.
	var/list/spit_order = list(
		list("skeleton_r_leg"),
		list("skeleton_l_leg"),
		list("skeleton_r_arm", "skeleton_r_hand"),
		list("skeleton_l_arm", "skeleton_l_hand"),
		list("skeleton_chest"),
		list("skeleton_head"),
		)
	/// How high the bones fly on their way back.
	var/spit_arc = 16
	// Limb angles, clockwise, for our left arm and leg (the victim's right); the other side mirrors them.
	var/flail_arms = 60
	var/wave_arms = 20
	var/kick_legs = 25

/datum/gms_kill_sequence/denim_wallet/BuildScene()
	. = ..()
	home_turf = get_turf(killer)
	home_x = (killer.x - victim.x) * world.icon_size
	home_y = (killer.y - victim.y) * world.icon_size
	// Drawn only over the head's own pixels, so it darkens the head without spilling past it.
	shadow = new
	shadow.icon = 'icons/mob/gms/gms_32x32.dmi'
	shadow.icon_state = "mobile_go_spin_kill_shadow"
	shadow.blend_mode = BLEND_INSET_OVERLAY
	shadow.alpha = 0
	var/obj/effect/gms_kill_visual/head = parts["head"]
	head.vis_contents += shadow

/datum/gms_kill_sequence/denim_wallet/ClearScene()
	QDEL_NULL(shadow)
	QDEL_LIST(spat)
	return ..()

/// The wallet scaled about its base, so it grows up from the floor, squashed down by `squash` for a bite.
/datum/gms_kill_sequence/denim_wallet/proc/WalletSize(scale, squash = 1)
	var/half_tile = world.icon_size / 2
	var/matrix/M = matrix()
	M.Translate(0, half_tile)
	M.Scale(scale * (2 - squash), scale * squash)
	M.Translate(0, -half_tile)
	return M

/// The victim tipped head first across the wallet's open mouth, shrunk towards it by `scale`.
/datum/gms_kill_sequence/denim_wallet/proc/InMouth(scale)
	var/matrix/M = AboutFeet(yank_angle)
	M.Translate(yank_x, yank_y)
	M.Scale(scale)
	M.Translate(home_x, home_y + mouth_rise)
	return M

/datum/gms_kill_sequence/denim_wallet/proc/PoseArms(angle, time)
	PoseLimb("r_arm", angle, time)
	PoseLimb("l_arm", -angle, time)

/// One bite or chew: the mouth snaps shut into the grin and the wallet squashes down, then it opens back up if `reopen`.
/datum/gms_kill_sequence/denim_wallet/proc/Bite(time, reopen)
	actor.icon_state = "denim_wallet_grin"
	animate(actor, transform = WalletSize(swell_scale, bite_squash), time = time / 2)
	animate(transform = WalletSize(swell_scale), time = time / 2)
	playsound(victim, 'sound/effects/butcher.ogg', 50, TRUE)
	sleep(time / 2)
	if(reopen && actor)
		actor.icon_state = "denim_wallet_maw"

/// Spits one of the skeleton's parts out of the mouth in an arc back to where the victim stood, landing laid out
/// the way the skeleton lies there afterwards.
/datum/gms_kill_sequence/denim_wallet/proc/SpitBone(list/states)
	var/obj/effect/gms_kill_visual/bone = new
	bone.icon = 'icons/mob/human_parts.dmi'
	bone.icon_state = states[1]
	for(var/i in 2 to length(states))
		bone.add_overlay(mutable_appearance('icons/mob/human_parts.dmi', states[i]))
	bone.layer = MOB_LAYER + 0.02
	bone.transform = Fallen()
	bone.pixel_x = home_x
	bone.pixel_y = home_y + mouth_rise
	holder.vis_contents += bone
	spat += bone
	playsound(victim, 'sound/effects/wounds/crack1.ogg', 50, TRUE)
	animate(bone, pixel_x = home_x / 2, pixel_y = max(home_y + mouth_rise, 0) + spit_arc, time = spit_time / 2, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = 0, pixel_y = 0, time = spit_time / 2, easing = BOUNCE_EASING)

/datum/gms_kill_sequence/denim_wallet/Play()
	// The wallet swells up where it stands and opens its maw, and the victim's face starts to darken.
	ActorInFront(FALSE)
	actor.pixel_x = home_x
	actor.pixel_y = home_y
	playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/denim_wallet_spotted.ogg', 60, TRUE)
	animate(actor, transform = WalletSize(swell_scale), time = swell_time)
	animate(shadow, alpha = loom_shadow, time = swell_time)
	if(!Wait(swell_time))
		return
	// The victim is yanked off their feet onto the wallet, head first into the open mouth, flailing.
	actor.icon_state = "denim_wallet_maw"
	playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/denim_wallet_charge.ogg', 60, TRUE)
	animate(scan, transform = InMouth(1), time = yank_time, easing = QUAD_EASING | EASE_OUT)
	animate(shadow, alpha = 255, time = yank_time)
	PoseArms(flail_arms, yank_time)
	if(!Wait(yank_time))
		return
	// Chewed down bite by bite: each bite shrinks them a step while they kick, and the last one finishes them.
	for(var/i in 1 to bites)
		var/side = (i % 2) ? 1 : -1
		var/scale = 1 - (1 - eaten_scale) * i / bites
		animate(scan, transform = InMouth(scale), alpha = i == bites ? 0 : 255, time = bite_time / 2, easing = QUAD_EASING | EASE_IN)
		PoseLimb("r_leg", kick_legs * side, bite_time / 2)
		PoseLimb("l_leg", -kick_legs * side, bite_time / 2)
		PoseArms(flail_arms - wave_arms * side, bite_time / 2)
		Bite(bite_time, TRUE)
		if(!Wait(bite_time / 2))
			return
	// A few more chews with the mouth shut.
	for(var/i in 1 to chews)
		Bite(chew_time, FALSE)
		if(!Wait(chew_time / 2))
			return
	// It gapes again and spits the bones back to where the victim stood, one at a time, skull last.
	actor.icon_state = "denim_wallet_maw"
	for(var/list/states as anything in spit_order)
		SpitBone(states)
		if(!Wait(spit_gap))
			return
	if(!Wait(spit_time - spit_gap + hold_time))
		return
	// It shrinks back to its usual size, still where it stands.
	actor.icon_state = killer.icon_living
	animate(actor, transform = matrix(), time = shrink_time)
	if(!Wait(shrink_time))
		return
	Finish()

/// Everything the victim carried is spat out around them, and every part of them, head and all, is bone: they become
/// a skeleton, lying the way the spat bones landed. Their own brain stays in the skull; changing species would
/// otherwise swap it for a new one.
/datum/gms_kill_sequence/denim_wallet/Aftermath()
	victim.unequip_everything()
	var/obj/item/organ/brain/brain = victim.getorganslot(ORGAN_SLOT_BRAIN)
	brain?.Remove(victim, TRUE, TRUE)
	victim.set_species(/datum/species/skeleton)
	if(brain)
		var/obj/item/organ/brain/new_brain = victim.getorganslot(ORGAN_SLOT_BRAIN)
		if(new_brain)
			new_brain.Remove(victim, TRUE, TRUE)
			qdel(new_brain)
		brain.Insert(victim, TRUE, TRUE)
	// Underwear is drawn on the body rather than worn as an item, so it needs clearing too to leave a bare skeleton.
	victim.underwear = "Nude"
	victim.undershirt = "Nude"
	victim.socks = "Nude"
	victim.update_body()
	victim.set_lying_angle(90)

/datum/gms_kill_sequence/denim_wallet/ReleaseTurf()
	return home_turf
