// The hunt. Every Perpetrator on his ground is hunted, one at a time, oldest first: the scream, the rush, one blow,
// the dash past them or the chop, then home. hunt_state names the step. Returning home is the base's own leash return.

/// Picks up the oldest Perpetrator on his ground while idle or on an errand, runs the errand otherwise, and watches
/// the hunt once one is on.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HuntTick()
	if(!judging)
		return
	if(hunt_state == "idle" || hunt_state == "errand")
		if(world.time >= next_hunt)
			var/mob/living/carbon/human/H = NextPerpetrator()
			if(H)
				EndErrand()
				StartHunt(H)
				return
		if(hunt_state == "idle")
			StartErrand()
		else
			ErrandTick()
		return
	if(hunt_state == "dragging")
		DragTick()
		return
	if(HuntOver())
		EndHunt()
		return
	if(hunt_target.stat >= HARD_CRIT)
		StartDrag()
		return
	switch(hunt_state)
		if("screaming", "preparing", "dashing", "chopping")
			walk(src, 0)
			patrol_reset()
		if("hunting")
			if(target != hunt_target)
				Provoke(hunt_target)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/NextPerpetrator()
	for(var/mob/living/carbon/human/H in perpetrators)
		if(H.stat == DEAD || !territory.Contains(get_turf(H)))
			continue
		return H

/// The hunt is over once the target is gone, or has got further than hunt_leash from his ground and out of his
/// sight. Neither crit nor death ends it: both are where the drag starts. While he can see them it goes on.
/// Cheapest test first: standing on his ground, then in his view, then the walk over every claimed turf.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HuntOver()
	if(QDELETED(hunt_target))
		return TRUE
	if(territory.Contains(get_turf(hunt_target)) || (hunt_target in view(src)))
		return FALSE
	return !NearGround(hunt_target)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/NearGround(mob/living/H)
	if(H.z != z)
		return FALSE
	for(var/turf/T in territory.claimed)
		if(get_dist(H, T) <= hunt_leash)
			return TRUE
	return FALSE

/// The scream: he shows himself, stands where he is for scream_time, and the target's heart starts going.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/StartHunt(mob/living/carbon/human/H)
	hunt_state = "screaming"
	hunt_target = H
	RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(OnHuntTargetDeleted))
	LoseTarget()
	patrol_reset()
	EndReturn()
	leashed = FALSE
	icon_state = "bunnyman_enraged"
	icon_living = "bunnyman_enraged"
	Reveal()
	Scream()
	to_chat(H, span_userdanger("A scream goes up somewhere on this street, and your heart answers it. He is coming."))
	BunnymanHeartbeat(H)
	addtimer(CALLBACK(src, PROC_REF(Rush)), scream_time)

/// Heard by everyone standing on his ground, wherever on it they are: loud near him, never quite gone at the far end.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Scream()
	visible_message(span_userdanger("[src] throws back its head and screams!"))
	for(var/mob/M in GLOB.player_list)
		if(M.z != z || !territory.Contains(get_turf(M)))
			continue
		var/volume = clamp(scream_volume - get_dist(M, src) * scream_falloff, scream_volume_floor, scream_volume)
		M.playsound_local(null, 'sound/distortions/bunnyman/scream.ogg', volume, FALSE)

/// The rush: off the leash, fast, near immune, and after nothing but the target.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Rush()
	if(hunt_state != "screaming")
		return
	hunt_state = "hunting"
	move_to_delay = hunt_speed
	UpdateSpeed()
	ChangeResistances(hunt_resistances)
	Provoke(hunt_target)

/// The hunt is done, however it went. Everything the rush changed goes back, the target's heart is let be,
/// and the mark stays: back on his ground, they are hunted again.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/EndHunt()
	if(hunt_state == "idle")
		return
	var/mob/living/H = hunt_target
	hunt_state = "idle"
	hunt_target = null
	SetDown()
	if(H)
		UnregisterSignal(H, COMSIG_PARENT_QDELETING)
		BunnymanHeartbeatStop(H)
		provoked_by -= H
		H.remove_status_effect(/datum/status_effect/incapacitating/immobilized)
	leashed = TRUE
	move_to_delay = initial(move_to_delay)
	UpdateSpeed()
	icon_state = "bunnyman"
	icon_living = "bunnyman"
	HideStagger()
	can_act = TRUE
	move_resist = initial(move_resist)
	ChangeResistances(quiet_resistances)
	LoseTarget()
	next_hunt = world.time + hunt_pause
	Hide()
	if(!territory.Contains(loc))
		StartReturn()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnHuntTargetDeleted(datum/source)
	SIGNAL_HANDLER
	hunt_target = null
	EndHunt()

/// He fights only through a hunt, and then only the one he is hunting. With his judgement off he fights whoever
/// hurts him, the base's provoked way, once the evidence's hold on him is broken.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/CanAttack(atom/the_target)
	if(!judging)
		return (hunt_state == "stunned" || hunt_state == "chopping") ? FALSE : ..()
	if(hunt_state != "hunting" || the_target != hunt_target)
		return FALSE
	return ..()

/// His own things are no obstacle: he steps through a hook or a head rather than breaking it, as the base would.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Bump(atom/A)
	if(A in owned)
		forceMove(get_turf(A))
		return
	return ..()

/// Nothing but the dash itself moves him while he screams, prepares, dashes, chops, stands looking, or staggers.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Move(atom/newloc, direct)
	if(hunt_state == "screaming" || hunt_state == "preparing" || hunt_state == "dashing" || hunt_state == "chopping" || hunt_state == "stunned" || world.time < staggered_until || world.time < rooted_until)
		return FALSE
	return ..()

/// The rush lands one full blow and slows them. Then, with a clear line and the dash ready, he stops to prepare the
/// dash through and past them; else the chop if it is ready; else he keeps on the rush.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/AttackingTarget(atom/attacked_target)
	if(!judging)
		if(world.time >= next_chop && isliving(attacked_target))
			Chop(get_turf(attacked_target))
			return FALSE
		return ..()
	if(hunt_state != "hunting" || attacked_target != hunt_target)
		return FALSE
	. = ..()
	if(!.)
		return
	hunt_target.apply_status_effect(/datum/status_effect/bunnyman_slow)
	if(world.time >= next_dash && DashLine())
		PrepareDash()
		return
	if(world.time >= next_chop)
		Chop(get_turf(hunt_target))

/// The telegraph: rooted for dash_windup with the Indigo Dusk commander's marker sliding from him onto the target.
/// The dash goes along whatever line there is when the marker arrives; none, and he is back on the rush.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/PrepareDash()
	hunt_state = "preparing"
	next_dash = world.time + dash_cooldown
	LoseTarget()
	walk(src, 0)
	var/obj/effect/temp_visual/bunnyman_dash_mark/mark = new(get_turf(src))
	walk_towards(mark, hunt_target, 0.1 SECONDS)
	visible_message(span_userdanger("[src] drops low, eyes fixed on [hunt_target]!"))
	playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, FALSE, 5)
	addtimer(CALLBACK(src, PROC_REF(DashNow)), dash_windup)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DashNow()
	if(hunt_state != "preparing")
		return
	var/list/path = DashLine()
	if(!path)
		hunt_state = "hunting"
		Provoke(hunt_target)
		return
	Dash(path)

/// The marker that slides from him onto the target while he prepares.
/obj/effect/temp_visual/bunnyman_dash_mark
	name = "his look"
	icon = 'icons/mob/telegraphing/telegraph_holographic.dmi'
	icon_state = "target_circle"
	duration = 2.1 SECONDS
	randomdir = FALSE
	movement_type = PHASING | FLYING
	layer = POINT_LAYER

/// Anyone on T carrying the Victim mark goes into the hit list before the turf is hurt, so a sweep never touches them.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SpareVictims(turf/T, list/hit)
	for(var/mob/living/carbon/human/H in T)
		if(H.has_status_effect(/datum/status_effect/bunnyman_mark/victim))
			hit |= H
	return hit

/// The turfs of the dash: the straight line through the target to dash_overshoot tiles past them, cut short at the
/// first blocked turf. Null if the line is blocked before it reaches them, since then there is nothing to cut off.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DashLine()
	var/turf/far = get_ranged_target_turf_direct(src, hunt_target, get_dist(src, hunt_target) + dash_overshoot)
	var/list/path = list()
	var/reached = FALSE
	for(var/turf/T in getline(src, far) - get_turf(src))
		if(T.is_blocked_turf(exclude_mobs = TRUE))
			break
		path += T
		if(T == get_turf(hunt_target))
			reached = TRUE
	return reached ? path : null

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Dash(list/path)
	hunt_state = "dashing"
	// the rabbits go in the hit list first, so his ground's own creatures are never in the way of him
	dash_hit = rabbits.Copy()
	LoseTarget()
	walk(src, 0)
	visible_message(span_danger("[src] goes through [hunt_target]!"))
	DashStep(path, 1)

/// One tile of the dash: a tread, and the 3x3 around it hurt, nobody twice in one dash.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DashStep(list/path, i)
	if(hunt_state != "dashing")
		return
	if(i > path.len)
		EndDash()
		return
	var/turf/T = path[i]
	forceMove(T)
	playsound(T, pick(footstep_sounds), 80, TRUE)
	for(var/turf/hit_turf in RANGE_TURFS(1, T))
		new /obj/effect/temp_visual/smash_effect(hit_turf)
		dash_hit = SpareVictims(hit_turf, dash_hit)
		dash_hit = HurtInTurf(hit_turf, dash_hit, dash_damage, RED_DAMAGE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	addtimer(CALLBACK(src, PROC_REF(DashStep), path, i + 1), dash_step)

/// Past them. He turns and comes back on the rush; they are slowed and he is in their way.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/EndDash()
	hunt_state = "hunting"
	Provoke(hunt_target)

/// The chop. Rooted, facing the tile the target stood on, he brings the cleaver down chop_count times, fast, the ring
/// around that tile one wider every chop_per_ring blows. It does not follow them: it is the ground they were on.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Chop(turf/centre)
	chop_from = hunt_state
	hunt_state = "chopping"
	next_chop = world.time + chop_cooldown
	LoseTarget()
	walk(src, 0)
	face_atom(centre)
	visible_message(span_danger("[src] raises the cleaver!"))
	playsound(get_turf(src), 'sound/abnormalities/woodsman/woodsman_prepare.ogg', 75, FALSE, 5)
	addtimer(CALLBACK(src, PROC_REF(ChopHit), centre, 1), chop_windup)

/// One blow: the Woodsman's axe, the heavy one on the last blow of each ring. Everyone in the ring is hit once per blow.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ChopHit(turf/centre, i)
	if(hunt_state != "chopping")
		return
	if(chop_from == "hunting" && judging && hunt_target && hunt_target.stat >= HARD_CRIT)
		StartDrag()
		return
	if(i > chop_count)
		EndChop()
		return
	var/ring = 1 + round((i - 1) / chop_per_ring)
	var/heavy = (i % chop_per_ring == 0)
	playsound(get_turf(src), heavy ? 'sound/abnormalities/woodsman/woodsman_strong.ogg' : 'sound/abnormalities/woodsman/woodsman_attack.ogg', heavy ? 100 : 75, FALSE, heavy ? 8 : 5)
	do_attack_animation(centre)
	var/list/been_hit = rabbits.Copy()
	for(var/turf/T in RANGE_TURFS(ring, centre))
		new /obj/effect/temp_visual/smash_effect(T)
		been_hit = SpareVictims(T, been_hit)
		been_hit = HurtInTurf(T, been_hit, chop_damage, RED_DAMAGE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	addtimer(CALLBACK(src, PROC_REF(ChopHit), centre, i + 1), chop_interval)

/// Back to what he was doing: the rush if this was a hunt and it is still on, otherwise nothing in particular.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/EndChop()
	if(chop_from == "hunting" && judging && hunt_target)
		hunt_state = "hunting"
		Provoke(hunt_target)
		return
	hunt_state = "idle"

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(damage_amount <= 0 || !isliving(source) || source == src)
		return
	if(judging)
		Judge(source, src)
		if(hidden)
			RevealBriefly()
		return
	CancelUndistort()
	WakeOn(source)

/// The fixers' small stagger from the 32x32 sheet, centred on his 48x48 sprite.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ShowStagger()
	if(stagger_overlay)
		return
	stagger_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegumobs.dmi', "small_stagger", layer + 0.1)
	stagger_overlay.pixel_x = 8
	stagger_overlay.pixel_y = 8
	add_overlay(stagger_overlay)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HideStagger()
	if(!stagger_overlay)
		return
	cut_overlay(stagger_overlay)
	stagger_overlay = null

// The evidence hit. Struck with a piece while he rushes, prepares the dash or dashes, he either looks, or it breaks
// and he does not.

/// A piece of evidence never lands as a hit, so it draws no blood and marks nobody. Outside the rush it does nothing.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/attacked_by(obj/item/I, mob/living/user)
	if(!istype(I, /obj/item/bunnyman_evidence))
		return ..()
	if(hunt_state != "hunting" && hunt_state != "preparing" && hunt_state != "dashing")
		to_chat(user, span_warning("He is not looking. It would have to be while he comes."))
		return TRUE
	user.visible_message(span_danger("[user] strikes [src] with [I], and it breaks in [user.p_their()] hands!"), span_danger("You strike him with [I]. It breaks in your hands."))
	playsound(src, 'sound/effects/snap.ogg', 50, TRUE)
	if(I.type == evidence_kind)
		Look(user)
	else
		to_chat(user, span_userdanger("He does not look. He does not stop."))
		Stagger()
	qdel(I)
	return TRUE

/// The wrong piece: a moment lost mid-rush, nothing more. While he prepares or dashes it only breaks.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Stagger()
	visible_message(span_warning("[src] staggers!"))
	if(hunt_state != "hunting")
		return
	staggered_until = world.time + stagger_time
	can_act = FALSE
	walk(src, 0)
	LoseTarget()
	ShowStagger()
	addtimer(CALLBACK(src, PROC_REF(EndStagger)), stagger_time)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/EndStagger()
	HideStagger()
	if(hunt_state != "hunting")
		return
	can_act = TRUE
	Provoke(hunt_target)

/// He looks. The one time. The hunt ends, every mark goes, his judgement is off for judgement_off_time, and he stands
/// where he is until something hurts him. Hurt, he fights whoever did it, fairly: no rush, no leap, no limbs.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Look(mob/living/user)
	// judgement off first, so EndHunt() leaves him seen instead of hiding him
	judging = FALSE
	EndHunt()
	EndReturn()
	visible_message(span_userdanger("[src] stops. He looks at [user], and at what was in [user.p_their()] hands, and he keeps looking."))
	hunt_state = "stunned"
	ClearMarks()
	ShowStagger()
	walk(src, 0)
	ChangeResistances(fair_resistances)
	StartJudgementTimer(judgement_off_time)

/// Runs the window for time, and the red warning over its last judgement_warning. Also resumes a paused window.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/StartJudgementTimer(time)
	judgement_timer = addtimer(CALLBACK(src, PROC_REF(JudgementBack)), time, TIMER_STOPPABLE)
	judgement_warning_timer = addtimer(CALLBACK(src, PROC_REF(JudgementFlash)), max(time - judgement_warning, 0), TIMER_STOPPABLE)

/// Stops the window and its warning where they are, his colour back to normal.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/StopJudgementTimer()
	if(judgement_timer)
		deltimer(judgement_timer)
		judgement_timer = null
	if(judgement_warning_timer)
		deltimer(judgement_warning_timer)
		judgement_warning_timer = null
	animate(src, color = null, time = 0)

/// One red flash, as long as the share of judgement_warning still left, so they come quicker to the end.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/JudgementFlash()
	var/interval = clamp(timeleft(judgement_timer) / judgement_warning, 0.1, 1) * judgement_flash_slowest
	animate(src, color = judgement_flash_colour, time = interval * 0.3, easing = SINE_EASING | EASE_OUT)
	animate(color = null, time = interval * 0.7, easing = SINE_EASING | EASE_IN)
	judgement_warning_timer = addtimer(CALLBACK(src, PROC_REF(JudgementFlash)), interval, TIMER_STOPPABLE)

/// Every Perpetrator and Victim anywhere is unmarked, and the queue with them.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ClearMarks()
	for(var/mob/living/L in perpetrators.Copy())
		L.remove_status_effect(/datum/status_effect/bunnyman_mark/perpetrator)
	perpetrators.Cut()
	for(var/mob/living/L as anything in GLOB.mob_living_list)
		L.remove_status_effect(/datum/status_effect/bunnyman_mark/victim)

/// The window closes. He is the judge again, and everyone who fought him in the window is a Perpetrator now:
/// the fair fight is over and the hunts begin, oldest first.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/JudgementBack()
	StopJudgementTimer()
	judging = TRUE
	if(hunt_state == "stunned")
		hunt_state = "idle"
	HideStagger()
	for(var/mob/living/carbon/human/H in provoked_by)
		if(H.stat != DEAD)
			MarkPerpetrator(H)
	provoked_by.Cut()
	LoseTarget()
	ChangeResistances(quiet_resistances)
	Hide()

/// The rush's one blow leaves them at half speed for its duration: long enough for him to get past and come back.
/datum/status_effect/bunnyman_slow
	id = "bunnyman_slow"
	duration = 3 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/bunnyman_slow/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/bunnyman_slow)

/datum/status_effect/bunnyman_slow/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/bunnyman_slow)
	return ..()

/datum/movespeed_modifier/bunnyman_slow
	flags = IS_ACTUALLY_MULTIPLICATIVE
	multiplicative_slowdown = 3

// The hunt's screen. Red veins at the edge of the hunted person's view, flaring in on each beat of the heartbeat.

/atom/movable/screen/fullscreen/bunnyman_veins
	icon_state = "bunnyman_veins"
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE
	alpha = 0

/// One beat: the file is heartbeat_length long and holds one beat, so sound and flare share the clock.
/// Starts the veins and the heartbeat on H and keeps them going until StopHeartbeat().
/proc/BunnymanHeartbeat(mob/living/H, heartbeat_length = 13.35)
	var/atom/movable/screen/fullscreen/bunnyman_veins/veins = H.overlay_fullscreen("bunnyman_veins", /atom/movable/screen/fullscreen/bunnyman_veins)
	if(!veins)
		return
	// up over the first third of the beat, down over the rest, forever
	animate(veins, alpha = 255, time = heartbeat_length * 0.3, loop = -1, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 40, time = heartbeat_length * 0.7, easing = SINE_EASING | EASE_IN)
	SEND_SOUND(H, sound('sound/abnormalities/nothingthere/heartbeat.ogg', repeat = 1, channel = CHANNEL_HEARTBEAT, volume = 60))

/proc/BunnymanHeartbeatStop(mob/living/H)
	H.clear_fullscreen("bunnyman_veins", 5)
	H.stop_sound_channel(CHANNEL_HEARTBEAT)
