// The Leather Wallet's kill sequence. It hops in place, and the victim is pulled up to sit on its raw lid, kicking.
// Gulp by gulp they sink into it, legs up, until even their blackened head is gone, and it spits the bones back out.
// The body is left a skeleton, the same as the denim wallet's.

/datum/gms_kill_sequence/denim_wallet/leather_wallet
	// Timings, in the order they play.
	var/hop_time = 0.25 SECONDS
	var/hops = 2
	var/hop_height = 5
	yank_time = 0.15 SECONDS
	var/kicks = 3
	var/kick_time = 0.15 SECONDS
	/// Each gulp squashes it down and pulls the victim a step further in; the last one swallows them.
	var/gulps = 5
	var/gulp_time = 0.2 SECONDS
	var/gulp_squash = 0.9
	chews = 1
	chew_time = 0.2 SECONDS
	spit_time = 0.3 SECONDS
	spit_gap = 0.1 SECONDS
	hold_time = 0.5 SECONDS
	/// How far above the middle of its tile its lid is. The bones fly out of there.
	mouth_rise = 10
	/// How high the victim is lifted to sit on the lid, and how far they have sunk once the last gulp takes them.
	var/sit_rise = 20
	var/swallowed_depth = 24
	// Limb angles while sitting and kicking, and while sinking with their legs and arms in the air.
	var/sit_legs = 80
	var/sink_legs = 150
	var/sink_arms = 140

/// The victim sitting on the wallet's lid, sunk `depth` pixels into it. The wallet is drawn in front, so whatever
/// sinks below the lid is hidden behind it.
/datum/gms_kill_sequence/denim_wallet/leather_wallet/proc/OnLid(depth)
	var/matrix/M = matrix()
	M.Translate(home_x, home_y + sit_rise - depth)
	return M

/datum/gms_kill_sequence/denim_wallet/leather_wallet/proc/PoseLegs(angle, time)
	PoseLimb("r_leg", angle, time)
	PoseLimb("l_leg", -angle, time)

/datum/gms_kill_sequence/denim_wallet/leather_wallet/Play()
	// It hops in place, and the victim's face starts to darken.
	ActorInFront(TRUE)
	actor.pixel_x = home_x
	actor.pixel_y = home_y
	playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/denim_wallet_spotted.ogg', 60, TRUE)
	animate(shadow, alpha = loom_shadow, time = hop_time * hops)
	for(var/i in 1 to hops)
		animate(actor, pixel_y = home_y + hop_height, time = hop_time / 2, easing = SINE_EASING | EASE_OUT)
		animate(pixel_y = home_y, time = hop_time / 2, easing = SINE_EASING | EASE_IN)
		if(!Wait(hop_time))
			return
	// The victim is yanked up onto the lid, sitting with their legs out.
	playsound(victim, 'ModularLobotomy/_Lobotomysounds/gms/denim_wallet_charge.ogg', 60, TRUE)
	animate(scan, transform = OnLid(0), time = yank_time, easing = QUAD_EASING | EASE_OUT)
	PoseLegs(sit_legs, yank_time)
	PoseArms(flail_arms, yank_time)
	if(!Wait(yank_time))
		return
	// They kick and flail.
	for(var/i in 1 to kicks)
		var/side = (i % 2) ? 1 : -1
		PoseLegs(sit_legs - kick_legs * side, kick_time)
		PoseArms(flail_arms + wave_arms * side, kick_time)
		if(!Wait(kick_time))
			return
	// Gulp by gulp they sink in, legs and arms thrown up, until the last gulp takes their head too.
	PoseLegs(sink_legs, gulp_time)
	PoseArms(sink_arms, gulp_time)
	for(var/i in 1 to gulps)
		animate(scan, transform = OnLid(swallowed_depth * i / gulps), alpha = i == gulps ? 0 : 255, time = gulp_time / 2, easing = QUAD_EASING | EASE_IN)
		if(i == round(gulps / 2))
			animate(shadow, alpha = 255, time = gulp_time)
		Gulp(gulp_time)
		if(!Wait(gulp_time / 2))
			return
	for(var/i in 1 to chews)
		Gulp(chew_time)
		if(!Wait(chew_time / 2))
			return
	// It spits the bones back to where the victim stood, skull last.
	for(var/list/states as anything in spit_order)
		SpitBone(states)
		if(!Wait(spit_gap))
			return
	if(!Wait(spit_time - spit_gap + hold_time))
		return
	Finish()

/// One gulp: it squashes down and springs back up, over `time`.
/datum/gms_kill_sequence/denim_wallet/leather_wallet/proc/Gulp(time)
	animate(actor, transform = WalletSize(1, gulp_squash), time = time / 2)
	animate(transform = matrix(), time = time / 2)
	playsound(victim, 'sound/effects/butcher.ogg', 50, TRUE)
	sleep(time / 2)
