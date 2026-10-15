// The Bunnyman on the advanced base: a butcher who judged with one look, judged wrong once, and became the judge
// who never looks twice. Whoever draws blood on his ground is a Perpetrator and is hunted; the one they drew it
// from is a Victim. Design: workspace/docs/lc13/distortions/BUNNYMAN_DESIGN.md.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman
	name = "The Bunnyman"
	desc = "Looks like a carnival mascot."
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "bunnyman"
	maxHealth = 2000
	health = 2000
	pixel_x = -8
	base_pixel_x = -8
	fear_level = WAW_LEVEL
	faction = list("neutral")
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.5)
	melee_damage_lower = 25
	melee_damage_upper = 30
	melee_damage_type = RED_DAMAGE
	attack_sound = 'sound/weapons/ego/axe2.ogg'
	attack_verb_continuous = "chops"
	attack_verb_simple = "chop"
	stat_attack = UNCONSCIOUS
	// a hit while he walks home never provokes him; the taboo answers it instead
	hard_return = TRUE
	// two and a half times the base's start, so his ground is a street from the first minute
	territory_start_size = 63
	ego_list = list(
		/obj/item/ego_weapon/animalism,
		/obj/item/clothing/suit/armor/ego_gear/waw/totalitarianism,
	)
	egoist_names = list("Douglas Grifon")
	gender = MALE
	egoist_outfit = /datum/outfit/job/butcher
	egoist_attributes = 80
	loot = list(/obj/item/documents/ncorporation, /obj/item/documents/ncorporation)
	monolith_abnormality = /mob/living/simple_animal/hostile/abnormality/norinori
	unmanifest_effect = /obj/effect/gibspawner/human
	var/list/footstep_sounds = list(
		'sound/distortions/bunnyman/step1.ogg',
		'sound/distortions/bunnyman/step2.ogg',
		'sound/distortions/bunnyman/step3.ogg',
		'sound/distortions/bunnyman/step4.ogg',
		'sound/distortions/bunnyman/step5.ogg',
		'sound/distortions/bunnyman/step6.ogg',
	)
	/// Whether his rule is running. Off for a minute after the right evidence strikes him.
	var/judging = TRUE
	/// Living mobs on claimed turf with the damage signal hooked, so blood drawn on them is seen.
	var/list/judged = list()
	/// Humans carrying the Perpetrator mark, oldest first. The hunt works through it in order.
	var/list/perpetrators = list()
	/// Mobs that may be Victims besides humans and his rabbits: anything whose faction holds one of these.
	var/list/harmless_factions = list("neutral")
	oddities = list(
		/obj/effect/temp_visual/distortion_oddity/shade,
		/obj/effect/temp_visual/distortion_oddity/bunnyman_thump,
		/obj/effect/temp_visual/distortion_oddity/bunnyman_steps,
		/obj/effect/temp_visual/distortion_oddity/bunnyman_print,
		/obj/effect/temp_visual/distortion_oddity/bunnyman_glimpse,
		/obj/effect/temp_visual/distortion_oddity/bunnyman_crossing,
		/obj/effect/temp_visual/distortion_oddity/bunnyman_smear,
	)
	/// Everything his rabbits may carry. The one he never looked at is rolled from this list at spawn.
	var/list/evidence_types = list(
		/obj/item/bunnyman_evidence/boning_knife,
		/obj/item/bunnyman_evidence/cleaver,
		/obj/item/bunnyman_evidence/butcher_knife,
		/obj/item/bunnyman_evidence/skinning_knife,
		/obj/item/bunnyman_evidence/bone_saw,
		/obj/item/bunnyman_evidence/mallet,
		/obj/item/bunnyman_evidence/chain,
		/obj/item/bunnyman_evidence/bottle,
	)
	/// The evidence he never looked at: one path from evidence_types. Only this kind makes him look.
	var/evidence_kind
	/// His rabbits, dead ones included until they are replaced.
	var/list/rabbits = list()
	var/rabbit_base = 6
	var/rabbits_per_stage = 2
	/// How long a dead rabbit waits to be replaced, and an emptied one to carry again.
	var/rabbit_respawn = 60 SECONDS
	/// "idle", "screaming", "hunting", "preparing", "dashing", "mauling", "chopping", "dragging", "stunned" while the right
	/// evidence holds him, or "errand", with errand naming which.
	var/hunt_state = "idle"
	var/mob/living/carbon/human/hunt_target
	/// No hunt starts before this. Set at the end of each hunt.
	var/next_hunt = 0
	var/scream_time = 3 SECONDS
	/// The scream is heard by everyone on his ground: this loud beside him, less by scream_falloff per turf, never under the floor.
	var/scream_volume = 100
	var/scream_falloff = 0.5
	var/scream_volume_floor = 25
	var/hunt_speed = 0.9
	/// After the rush's blow, with a clear line and the dash ready, he goes through the slowed target and this many
	/// tiles past them, to stand in their way. Each tile crossed hurts the 3x3 around it for dash_damage RED, once each.
	/// After the blow he stands this long with the marker sliding onto them, then dashes.
	var/dash_windup = 2 SECONDS
	var/dash_overshoot = 3
	var/dash_damage = 15
	var/dash_step = 1
	var/dash_cooldown = 8 SECONDS
	var/next_dash = 0
	var/list/dash_hit = list()
	/// The chop: chop_count fast blows on the tile in front of him and the ring around it, the ring one wider every
	/// chop_per_ring blows. Papa Bongy's growing ring at four times the pace, with the Woodsman's axe.
	var/chop_damage = 10
	var/chop_count = 12
	var/chop_per_ring = 4
	var/chop_interval = 1.5 SECONDS / 4
	var/chop_windup = 0.5 SECONDS
	var/chop_cooldown = 12 SECONDS
	var/next_chop = 0
	/// What he was doing when the chop began, to go back to.
	var/chop_from = "idle"
	// The den
	var/floor_type = /turf/open/floor/plating/ashplanet/rocky/bunnyman
	var/wall_type = /turf/closed/indestructible/rock/bunnyman
	/// Turfs the den has converted, with what each was, so Teardown() puts them back.
	var/list/converted = list()
	/// The den reaches den_radius tiles from the origin at spawn and den_radius_growth further per stage, filled outward
	/// from the origin through open floor only: it never crosses a wall, and it stops at doors.
	var/den_radius = 4
	var/den_radius_growth = 1
	var/list/spikes = list()
	/// Hooks for the hunted: this many at spawn and one more per stage.
	var/spikes_base = 4
	/// Where loose items on the den floor are swept to. A wall-side tile, picked once.
	var/turf/pile_turf
	/// Rolled at spawn: who did the thing he judged wrong, for the report.
	var/attacker_name
	/// The people he killed, rolled at spawn: the first is the innocent, the rest bit. Each a /datum/bunnyman_killed.
	var/list/killed = list()
	var/killed_count = 4
	/// What a missing poster can say about a look, slot by slot.
	var/list/look_options = list(
		"hat" = list("a flat cap", "a wide hat", "a wool hat", "no hat", "a hood up", "a bandage round the head"),
		"hair" = list("dark hair", "fair hair", "grey hair", "red hair", "a shaved head", "black hair tied back"),
		"eyes" = list("brown eyes", "green eyes", "blue eyes", "grey eyes", "one eye", "pale eyes"),
		"shirt" = list("a red shirt", "a white shirt", "a striped shirt", "a work shirt", "a black shirt", "a torn shirt"),
		"coat" = list("a grey coat", "a long black coat", "a leather jacket", "no coat", "a brown coat", "an apron"),
		"shoes" = list("brown boots", "black boots", "worn shoes", "no shoes", "white shoes", "heavy boots"),
	)
	/// The hunted, over his shoulder on the way to the den, and their appearance drawn on him.
	var/mob/living/carbon/human/carried
	var/mutable_appearance/carry_overlay
	// Hiding
	/// Unseen right now. He is seen from the scream to a hunt's end, through the judgement-off minute, and briefly when hit.
	var/hidden = FALSE
	var/obj/effect/bunnyman_eyes/eyes
	var/hit_reveal_time = 3 SECONDS
	/// What he says, pointing, when someone is at his things where he can see.
	var/list/warning_lines = list(
		"Those are mine.",
		"Leave it. I will not say it twice.",
		"Hands off. Once more and I will have looked.",
		"That is not yours to touch.",
	)
	// The head errand
	/// The dead on his hooks whose heads he has not yet taken.
	var/list/heads_wanted = list()
	/// The body he is walking to, the head he carries, and the edge turf he is taking it to.
	var/mob/living/carbon/human/head_body
	var/obj/item/bodypart/head/carried_head
	var/turf/head_turf
	var/head_take_time = 3 SECONDS
	/// Mid do_after on a head, so the tick does not start another.
	var/taking_head = FALSE
	// The other errands
	/// "collecting", "placing", "ripping", "petting", "giving", "den", "clearing" or "dumping".
	var/errand
	var/obj/structure/sign/poster/bunnyman/rip_target
	var/mob/living/carbon/human/rip_reader
	var/mob/living/simple_animal/hostile/bunnyman_rabbit/pet_target
	var/mob/living/carbon/human/give_target
	var/obj/structure/kitchenspike/bunnyman/clear_target
	var/turf/den_turf
	/// Percent chance per idle tick of going to sit with a rabbit, of going back to the den, and of a mutter while there.
	var/pet_chance = 4
	/// No second rabbit until this has passed, and never the same line twice running.
	var/pet_cooldown = 3 MINUTES
	var/next_pet = 0
	var/last_pet_line
	var/den_chance = 2
	var/mutter_chance = 10
	/// A mutter stops him this long.
	var/mutter_pause = 2 SECONDS
	/// And no other follows it for this long.
	var/mutter_cooldown = 30 SECONDS
	var/next_mutter = 0
	var/rooted_until = 0
	var/list/mutter_clue_lines = list(
		"...%PART%. that is what I saw. %PART%...",
		"...it was %PART%. I did not look past %PART%...",
		"...%PART%... standing there. %PART%...",
	)
	// Hearing
	/// Humans on his ground with the say hook on them.
	var/list/listening = list()
	var/list/right_name_warnings = list(
		"Shut your mouth. You do not get to say that name on my street.",
		"Say it again and I will take the tongue you said it with.",
		"That name is mine. Put it down before I put you down.",
	)
	var/list/wrong_name_warnings = list(
		"That one bit. I was right. Say it again and I will show you how right.",
		"Do not throw their names at me. I know what they did. One more and you will know what I do.",
		"I put that one on a hook for a reason. Keep talking and you will see it from the same hook.",
	)
	var/undistort_time = 30 SECONDS
	var/undistort_timer
	/// What was left of the judgement window when the rays started, given back if they are put out.
	var/judgement_left = 0
	var/judgement_resume_floor = 10 SECONDS
	var/list/pet_lines = list(
		"There, there. Nobody is looking at you.",
		"Good. Sit. Nothing is going to happen.",
		"You are a good one. You never bit anyone.",
	)
	var/list/rip_lines = list(
		"Nothing on it. Nothing worth your eyes.",
		"Paper. It was always only paper.",
		"Read the street instead. It says the same.",
	)
	var/list/give_lines = list(
		"Here. For the fright.",
		"Eat. You did nothing. I saw.",
		"Take it. You were only standing there.",
	)
	// The notices
	/// One of each: the report, the ledger, the stock list, and a missing poster for each of the killed.
	var/list/notice_kinds = list("report", "ledger", "inventory", "missing1", "missing2", "missing3", "missing4")
	/// How many of each kind are up right now.
	var/list/notices = list("report" = 0, "ledger" = 0, "inventory" = 0, "missing1" = 0, "missing2" = 0, "missing3" = 0, "missing4" = 0)
	var/notices_per_kind = 1
	/// Percent chance per claimed turf that a notice goes up on a wall beside it, while any kind is short.
	var/notice_chance = 4
	var/notice_replace_delay = 20 SECONDS
	// The stages
	/// From this stage the people inside see him coming when he is not, and rabbits sometimes look like him.
	var/hallucination_stage = 3
	var/hallucination_interval = 90 SECONDS
	/// Ticks between the hallucination's steps, and what reaching someone costs them.
	var/hallucination_step = 3
	var/hallucination_sanity = 20
	/// Humans inside to when they next see him, kept while they stay.
	var/list/next_hallucination = list()
	var/mimic_interval = 3 MINUTES
	/// How soon to look again when no rabbit had anyone in view.
	var/mimic_retry = 10 SECONDS
	var/next_mimic = 0
	/// The maul: a pinned target takes maul_damage every maul_interval for up to maul_time, each blow able to take a limb.
	var/maul_damage = 10
	var/maul_interval = 0.4 SECONDS
	var/maul_time = 10 SECONDS
	/// Percent chance per maul blow to take an arm or a leg.
	var/dismember_chance = 15
	/// Hurt this much during a maul, he lets go.
	var/maul_break_damage = 300
	var/maul_taken = 0
	var/maul_until = 0
	/// The hunt ends once the target is further than this from any claimed turf.
	var/hunt_leash = 15
	/// The wait after a hunt ends before the next may start.
	var/hunt_pause = 10 SECONDS
	var/list/hunt_resistances = list(RED_DAMAGE = 0.1, WHITE_DAMAGE = 0.1, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.1)
	var/list/quiet_resistances = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.5)
	/// His resistances while his judgement is off: a fair fight.
	var/list/fair_resistances = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.5)
	/// How long the right evidence turns his judgement off. The window for undistorting him.
	var/judgement_off_time = 60 SECONDS
	var/judgement_timer
	/// The wrong evidence stops him this long mid-rush.
	var/stagger_time = 3 SECONDS
	var/staggered_until = 0
	/// The fixers' small stagger, laid over him while he cannot move: staggered by the wrong evidence, or held by the right.
	var/mutable_appearance/stagger_overlay

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	evidence_kind = pick(evidence_types)
	attacker_name = random_unique_name(pick(MALE, FEMALE))
	RollKilled()
	GrowDen(0)
	FillRabbits()
	SeedNotices()
	Hide()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/waddling)

/// One slow tread per step, the way big bird's steps play, hidden or not. Hidden, a print where the step landed, and
/// the eyes keep up.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Moved(atom/old_loc, dir)
	. = ..()
	if(stat == DEAD)
		return
	playsound(get_turf(src), pick(footstep_sounds), 50, TRUE)
	if(eyes)
		eyes.forceMove(loc)
	if(hidden && isturf(loc))
		new /obj/effect/temp_visual/bunnyman_footprint(loc, dir)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Life()
	. = ..()
	if(stat == DEAD)
		return
	TerritoryTick()
	HuntTick()
	SpotParanoid()
	MimicTick()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Teardown()
	if(torn_down)
		return
	Reveal()
	if(carried_head)
		carried_head.forceMove(get_turf(src))
		carried_head = null
	heads_wanted.Cut()
	for(var/mob/living/carbon/human/H in listening)
		UnregisterSignal(H, COMSIG_MOB_SAY)
	listening.Cut()
	if(undistort_timer)
		deltimer(undistort_timer)
		undistort_timer = null
	for(var/mob/living/carbon/human/H in next_hallucination)
		UnregisterSignal(H, COMSIG_PARENT_QDELETING)
	next_hallucination.Cut()
	SetDown()
	for(var/turf/T in converted)
		if(istype(T, floor_type) || istype(T, wall_type))
			T.ChangeTurf(converted[T])
	converted.Cut()
	EndHunt()
	if(judgement_timer)
		deltimer(judgement_timer)
		judgement_timer = null
	HideStagger()
	for(var/mob/living/L in judged)
		UnregisterSignal(L, COMSIG_MOB_APPLY_DAMGE)
	judged.Cut()
	perpetrators.Cut()
	rabbits.Cut()
	return ..()

// The taboo. Blood drawn on his ground by a human marks them Perpetrator and the one it was drawn from Victim.

/// Hooks the damage signal on every living mob standing in the territory and lets it go when they leave.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/TerritoryTick()
	var/list/inside = list()
	for(var/mob/living/L as anything in GLOB.mob_living_list)
		if(L != src && L.z == z && L.stat != DEAD && territory.Contains(get_turf(L)))
			inside += L
	for(var/mob/living/L in inside)
		if(L in judged)
			continue
		RegisterSignal(L, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnBloodDrawn))
		judged += L
	for(var/mob/living/L in judged)
		if(QDELETED(L) || !(L in inside))
			UnregisterSignal(L, COMSIG_MOB_APPLY_DAMGE)
			judged -= L
	HallucinationTick(inside)
	ListenTick(inside)

/// Something on his ground was hurt. The signal fires before armor, so a hit that armor would swallow still counts.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnBloodDrawn(mob/living/target, damage_amount, damage_type, def_zone, mob/living/source, flags, attack_type)
	SIGNAL_HANDLER
	if(damage_amount <= 0 || (flags & DAMAGE_UNTRACKABLE))
		return
	Judge(source, target)

/// One look: a human who hurts something harmless on his ground is guilty, and the harmless thing is theirs.
/// Hurting someone already guilty is free. He is never a Victim himself; hitting him only makes a Perpetrator.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Judge(mob/living/attacker, mob/living/target)
	if(!judging || stat == DEAD || !ishuman(attacker) || attacker == target || !Harmless(target))
		return
	if(target.has_status_effect(/datum/status_effect/bunnyman_mark/perpetrator))
		return
	MarkPerpetrator(attacker)
	if(target == src)
		return
	var/datum/status_effect/bunnyman_mark/victim/V = target.has_status_effect(/datum/status_effect/bunnyman_mark/victim)
	if(V)
		V.SetPerpetrator(attacker)
	else
		target.apply_status_effect(/datum/status_effect/bunnyman_mark/victim, src, attacker)

/// What he sees as a rabbit: humans, his own rabbits, himself, and any mob in a harmless faction.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Harmless(mob/living/L)
	if(ishuman(L) || L == src || istype(L, /mob/living/simple_animal/hostile/bunnyman_rabbit))
		return TRUE
	for(var/f in harmless_factions)
		if(f in L.faction)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/MarkPerpetrator(mob/living/carbon/human/H)
	if(H.has_status_effect(/datum/status_effect/bunnyman_mark/perpetrator))
		return
	H.apply_status_effect(/datum/status_effect/bunnyman_mark/perpetrator, src)
	perpetrators |= H
	to_chat(H, span_userdanger("Something on this street has seen what you did, and has not looked twice."))

/// The mark is gone, by decay or by the evidence. He forgets the verdict with it.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnPerpetratorCleared(mob/living/H)
	perpetrators -= H

// The hunt. Every Perpetrator on his ground is hunted, one at a time, oldest first: the scream, the rush, one blow,
// the dash past them or the maul, then home. hunt_state names the step. Returning home is the base's own leash return.

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
		if("screaming", "preparing", "dashing", "mauling", "chopping")
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
/// sight. Neither crit nor death ends it: both are where the drag starts. He hooks the dead too. While he can see them it goes on, however far they are.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HuntOver()
	if(QDELETED(hunt_target))
		return TRUE
	return !NearGround(hunt_target) && !(hunt_target in view(src))

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
	if(territory && !territory.Contains(loc))
		StartReturn()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnHuntTargetDeleted(datum/source)
	SIGNAL_HANDLER
	hunt_target = null
	EndHunt()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Reveal()
	return

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Hide()
	return

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

/// Nothing but the dash itself moves him while he screams, prepares, dashes, mauls, chops, stands looking, or staggers.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Move(atom/newloc, direct)
	if(hunt_state == "screaming" || hunt_state == "preparing" || hunt_state == "dashing" || hunt_state == "mauling" || hunt_state == "chopping" || hunt_state == "stunned" || world.time < staggered_until || world.time < rooted_until)
		return FALSE
	return ..()

/// The rush lands one full blow and slows them. Then, with a clear line and the dash ready, he stops to prepare the
/// dash through and past them; else the chop if it is ready; else he is on them, and the maul begins.
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
		return
	Maul()

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

/// On them. Quick light blows, each able to take an arm or a leg, until they are in crit, maul_time is up, or he
/// has been hurt maul_break_damage worth. Then they are let go and the rush begins again.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Maul()
	hunt_state = "mauling"
	maul_taken = 0
	maul_until = world.time + maul_time
	forceMove(get_turf(hunt_target))
	hunt_target.Knockdown(2 SECONDS)
	hunt_target.Immobilize(maul_time + 1 SECONDS)
	hunt_target.visible_message(span_danger("[src] comes down on [hunt_target]!"), span_userdanger("He comes down on you. You cannot get out from under him."))
	MaulHit()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/MaulHit()
	if(hunt_state != "mauling")
		return
	if(HuntOver())
		EndHunt()
		return
	if(hunt_target.stat >= HARD_CRIT)
		StartDrag()
		return
	if(world.time >= maul_until || maul_taken >= maul_break_damage || !hunt_target.Adjacent(src))
		ReleaseMaul()
		return
	do_attack_animation(hunt_target)
	playsound(src, attack_sound, 100, TRUE)
	hunt_target.deal_damage(maul_damage, melee_damage_type, src, attack_type = ATTACK_TYPE_MELEE)
	if(prob(dismember_chance))
		var/obj/item/bodypart/limb = hunt_target.get_bodypart(pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		if(limb)
			limb.dismember()
	addtimer(CALLBACK(src, PROC_REF(MaulHit)), maul_interval)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ReleaseMaul()
	hunt_state = "hunting"
	hunt_target.remove_status_effect(/datum/status_effect/incapacitating/immobilized)
	visible_message(span_danger("[src] lets [hunt_target] go, and comes again."))
	Provoke(hunt_target)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(hunt_state == "mauling")
		maul_taken += damage_amount
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
	EndHunt()
	EndReturn()
	visible_message(span_userdanger("[src] stops. He looks at [user], and at what was in [user.p_their()] hands, and he keeps looking."))
	judging = FALSE
	hunt_state = "stunned"
	ClearMarks()
	Reveal()
	ShowStagger()
	LoseTarget()
	walk(src, 0)
	patrol_reset()
	ChangeResistances(fair_resistances)
	judgement_timer = addtimer(CALLBACK(src, PROC_REF(JudgementBack)), judgement_off_time, TIMER_STOPPABLE)

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
	judgement_timer = null
	// the rays hold the window open; if the timer somehow runs out under them, he stays as he is until they end
	if(undistort_timer)
		return
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

// The den. The nearest turfs to the origin become rock, his spikes stand on them, and three heads on spears watch:
// one of them the person he judged wrong, the only place that name is written. The drag brings the hunted here.

/// The base's centre hook, after every stage change. The den reaches den_radius at spawn and further per stage.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/UpdateCenter(new_stage)
	GrowDen(new_stage)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/GrowDen(stage)
	if(torn_down)
		return
	ApplyCenterEffects(DenFill(den_radius + den_radius_growth * stage))
	BreakStructures()
	SweepFloor()
	FillSpikes(spikes_base + stage)

/// The den's floor: a flood fill from the origin, cardinal steps through open claimed turfs within radius, never through
/// a closed turf and never through a door, so the rock fills the room he spawned in and no further.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DenFill(radius)
	var/turf/origin = territory.Center()
	var/list/result = list(origin)
	var/list/seen = list()
	seen[origin] = TRUE
	var/i = 1
	while(i <= result.len)
		var/turf/T = result[i++]
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(!next || seen[next] || !isopenturf(next) || get_dist(origin, next) > radius || !territory.Contains(next))
				continue
			seen[next] = TRUE
			if(locate(/obj/machinery/door) in next)
				continue
			result += next
	return result

/// Floors become rock and any wall touching one, corners included, becomes rock, each remembered with what it was.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/ApplyCenterEffects(list/turfs)
	for(var/turf/open/T in turfs)
		if(!converted[T] && !istype(T, floor_type))
			converted[T] = T.type
			T.ChangeTurf(floor_type)
		for(var/dir in GLOB.alldirs)
			var/turf/next = get_step(T, dir)
			if(!next || converted[next] || !isclosedturf(next) || istype(next, wall_type))
				continue
			converted[next] = next.type
			next.ChangeTurf(wall_type)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DenTurfs()
	var/list/den = list()
	for(var/turf/T in converted)
		if(istype(T, floor_type))
			den += T
	return den

/// Whatever stood on the den floor that is not his is broken as the rock comes in. Doors of any kind are left.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/BreakStructures()
	for(var/turf/T in DenTurfs())
		for(var/obj/structure/S in T)
			if((S in owned) || istype(S, /obj/structure/mineral_door))
				continue
			S.deconstruct(FALSE)

/// Den floor tiles against a wall and clear of every door, nearest the middle first: where the hooks, the heads
/// and the pile go, so nothing of his stands in a doorway or the middle of the room.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/WallSideTurfs()
	var/list/result = list()
	for(var/turf/T in DenTurfs())
		if(T == territory.Center() || (locate(/obj/machinery/door) in T))
			continue
		var/by_wall = FALSE
		var/by_door = FALSE
		for(var/turf/next in RANGE_TURFS(1, T))
			if(next == T)
				continue
			if(locate(/obj/machinery/door) in next)
				by_door = TRUE
				break
			if(isclosedturf(next) && get_dist(T, next) == 1 && (get_dir(T, next) in GLOB.cardinals))
				by_wall = TRUE
		if(by_wall && !by_door)
			result += T
	return result

/// Everything loose on the den floor is swept to one wall-side tile. Runs with every growth of the den.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SweepFloor()
	if(!pile_turf)
		var/list/sides = WallSideTurfs()
		pile_turf = sides.len ? sides[sides.len] : null
	if(!pile_turf)
		return
	for(var/turf/T in DenTurfs())
		if(T == pile_turf)
			continue
		for(var/obj/item/I in T)
			if(I.anchored)
				continue
			I.forceMove(pile_turf)

/// Keeps the den at its hook count, one per free wall-side tile, never on the pile.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/FillSpikes(wanted)
	for(var/turf/T in WallSideTurfs())
		if(spikes.len >= wanted)
			return
		if(T == pile_turf || T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/obj/structure/kitchenspike/bunnyman/S = new(T, src)
		spikes += S
		Own(S)

// The drag. At hard crit the hitting stops; he picks them up, the way Baroputian carries what it finds, and walks
// home with them over his shoulder. Nothing gets them off him until he sets them on a spike.

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/StartDrag()
	hunt_state = "dragging"
	LoseTarget()
	walk(src, 0)
	patrol_reset()
	hunt_target.remove_status_effect(/datum/status_effect/incapacitating/immobilized)
	PickUp(hunt_target)

/// Into his contents, their appearance drawn over his shoulder. Only if they are within reach.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/PickUp(mob/living/carbon/human/M)
	if(carried)
		return TRUE
	if(!M.Adjacent(src))
		return FALSE
	carried = M
	visible_message(span_danger("[src] hauls [carried] up over one shoulder and turns for home."), ignored_mobs = list(carried))
	to_chat(carried, span_userdanger("You are hauled up over his shoulder. The street goes by upside down."))
	carried.forceMove(src)
	carry_overlay = new /mutable_appearance(carried)
	carry_overlay.pixel_y = 20
	carry_overlay.pixel_x = 16
	carry_overlay.layer = layer + 0.1
	var/matrix/m180 = matrix()
	m180.Turn(180)
	carry_overlay.transform = m180
	add_overlay(carry_overlay)
	return TRUE

/// Sets them down on T, or where he stands. The one way out of his hold, used by the spike, the hunt's end and Teardown().
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SetDown(turf/T)
	if(!carried)
		return
	cut_overlay(carry_overlay)
	carry_overlay = null
	var/mob/living/carbon/human/H = carried
	carried = null
	H.forceMove(T || get_turf(src))

/// Each tick of the drag. Not yet picked up, he goes to them, dead or alive. On den rock, they go on a spike.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DragTick()
	if(QDELETED(hunt_target))
		EndHunt()
		return
	if(!PickUp(hunt_target))
		if(!length(patrol_path))
			WalkTo(get_turf(hunt_target))
		return
	if(istype(loc, floor_type))
		SpikeTarget()
		return
	if(!length(patrol_path))
		WalkTo(territory.Center())

/// In the den: onto a free spike, the mark lifted now that they are where he wanted them. With every spike taken he
/// drives a new one into a wall-side tile first; only with no wall left are they set down on the rock. Then the hunt
/// is over, and the next waits hunt_pause.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SpikeTarget()
	var/mob/living/carbon/human/H = carried
	var/obj/structure/kitchenspike/bunnyman/free = FreeSpike()
	if(!free)
		FillSpikes(spikes.len + 1)
		free = FreeSpike()
	if(free)
		SetDown(get_turf(free))
		free.Spike(H)
		H.remove_status_effect(/datum/status_effect/bunnyman_mark/perpetrator)
	EndHunt()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/FreeSpike()
	for(var/obj/structure/kitchenspike/bunnyman/S in spikes)
		if(!S.has_buckled_mobs())
			return S
	return null

/// His meat spike. Nobody is hurt by it, nobody gets off it alone, nobody takes it apart. Another person can pull
/// someone free with the stock 30 s hold. Someone who dies on it loses their head to a pike on the same tile.
/obj/structure/kitchenspike/bunnyman
	name = "meat hook"
	desc = "A butcher's hook, driven into the rock. Something has hung here before."
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion
	/// Who last hit it, for the mark if it breaks.
	var/mob/living/last_attacker

/obj/structure/kitchenspike/bunnyman/Initialize(mapload, new_distortion)
	. = ..()
	distortion = new_distortion

/obj/structure/kitchenspike/bunnyman/Destroy()
	distortion = null
	return ..()

/obj/structure/kitchenspike/bunnyman/crowbar_act(mob/living/user, obj/item/I)
	to_chat(user, span_warning("It is driven too deep into the rock."))
	return TRUE

/obj/structure/kitchenspike/bunnyman/deconstruct(disassembled)
	return

/obj/structure/kitchenspike/bunnyman/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	last_attacker = user
	if(distortion)
		distortion.OnThingAttacked(src, user)

/obj/structure/kitchenspike/bunnyman/bullet_act(obj/projectile/P)
	. = ..()
	if(isliving(P.firer))
		last_attacker = P.firer
		if(distortion)
			distortion.OnThingAttacked(src, P.firer)

/// Broken by damage: whoever did it is marked if he saw, and it is gone, anyone on it let down.
/obj/structure/kitchenspike/bunnyman/obj_destruction(damage_flag)
	if(distortion)
		distortion.OnThingBroken(src, last_attacker)
	qdel(src)

/// Only he puts people on it. Anyone else can only pull someone off.
/obj/structure/kitchenspike/bunnyman/attack_hand(mob/user)
	if(has_buckled_mobs())
		for(var/mob/living/L in buckled_mobs)
			user_unbuckle_mob(L, user)
		return
	to_chat(user, span_notice("It is not yours to use."))

/obj/structure/kitchenspike/bunnyman/user_unbuckle_mob(mob/living/buckled_mob, mob/living/carbon/human/user)
	if(buckled_mob == user)
		to_chat(user, span_warning("You cannot get yourself off it. Someone else will have to."))
		return
	if(distortion)
		distortion.OnUnhookTried(src, user)
	. = ..()
	if(!buckled_mob.buckled && distortion)
		distortion.OnUnhooked(src, user, buckled_mob)

/// Up and on, no blood. Whatever the hunt did to them is mended: the den is a prison, not an execution.
/obj/structure/kitchenspike/bunnyman/proc/Spike(mob/living/M)
	M.forceMove(drop_location())
	M.adjustBruteLoss(-M.getBruteLoss())
	M.setDir(SOUTH)
	buckle_mob(M, force = TRUE)
	var/matrix/m180 = matrix(M.transform)
	m180.Turn(180)
	animate(M, transform = m180, time = 3)
	M.pixel_y = M.base_pixel_y + PIXEL_Y_OFFSET_LYING
	M.visible_message(span_danger("[src] takes [M]."), span_userdanger("You are hung up. You are not going anywhere on your own."))
	if(M.stat == DEAD)
		distortion.HeadWanted(M)
	else
		RegisterSignal(M, COMSIG_LIVING_DEATH, PROC_REF(OnSpikedDeath))

/// Down and off, no blood, and standing exactly as they were before: the spike's turn and drop undone outright.
/obj/structure/kitchenspike/bunnyman/release_mob(mob/living/M)
	UnregisterSignal(M, COMSIG_LIVING_DEATH)
	M.transform = matrix()
	M.pixel_y = M.base_pixel_y
	visible_message(span_danger("[M] comes down off [src]."))
	unbuckle_mob(M, force = TRUE)

/// Died hanging. The body stays where it hangs, and he comes for the head himself.
/obj/structure/kitchenspike/bunnyman/proc/OnSpikedDeath(mob/living/carbon/human/M)
	SIGNAL_HANDLER
	UnregisterSignal(M, COMSIG_LIVING_DEATH)
	if(distortion)
		distortion.HeadWanted(M)

/// A head on his ground: someone who died on his hooks, planted at the edge where it is seen. It cannot be taken down.
/obj/structure/headpike/bunnyman
	name = "head on a spear"
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion
	var/mob/living/last_attacker

/obj/structure/headpike/bunnyman/Initialize(mapload, head_name, obj/item/bodypart/head/head)
	. = ..()
	if(head)
		head.forceMove(src)
		victim = head
	else
		victim = new(src)
	if(head_name)
		victim.real_name = head_name
	else if(!victim.real_name)
		victim.real_name = random_unique_name(prob(50))
	spear = new(src)
	name = "[victim.real_name] on a spear"
	update_icon()

/obj/structure/headpike/bunnyman/attack_hand(mob/user)
	to_chat(user, span_warning("It is set into the rock. It is not coming down."))
	return TRUE

/obj/structure/headpike/bunnyman/Destroy()
	distortion = null
	return ..()

/obj/structure/headpike/bunnyman/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	last_attacker = user
	if(distortion)
		distortion.OnThingAttacked(src, user)

/obj/structure/headpike/bunnyman/bullet_act(obj/projectile/P)
	. = ..()
	if(isliving(P.firer))
		last_attacker = P.firer
		if(distortion)
			distortion.OnThingAttacked(src, P.firer)

/obj/structure/headpike/bunnyman/obj_destruction(damage_flag)
	if(distortion)
		distortion.OnThingBroken(src, last_attacker)
	return ..()

/obj/structure/headpike/bunnyman/examine(mob/user)
	. = ..()
	. += span_notice("It did not look twice either.")

/turf/open/floor/plating/ashplanet/rocky/bunnyman
	name = "rock floor"
	desc = "Bare rock, worn smooth down the middle. Something is dragged along it often."

/turf/closed/indestructible/rock/bunnyman
	name = "rock"
	desc = "Rock where a wall was. It is cold, and it is not going anywhere."

// Hiding. Outside a hunt and the fair fight he cannot be seen. Two tells: his eyes, a pair of red points that move
// with him, and a blood footprint where each step lands, fading in a moment. His tread is heard either way.

/// Unseen, with the eyes out, and walked through like the dark he is in. Only when nothing else is going on:
/// never mid-hunt, never while his judgement is off.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Hide()
	if(hunt_state != "idle" || !judging || stat == DEAD)
		return
	hidden = TRUE
	alpha = 0
	density = FALSE
	if(!eyes)
		eyes = new(loc)
		Own(eyes)

/// Seen. The eyes go; they are his face now.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Reveal()
	hidden = FALSE
	alpha = 255
	density = initial(density)
	if(eyes)
		qdel(eyes)
		eyes = null

/// Hit while hidden: seen for hit_reveal_time, long enough to know what you struck, not long enough to follow.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/RevealBriefly()
	Reveal()
	addtimer(CALLBACK(src, PROC_REF(Hide)), hit_reveal_time, TIMER_UNIQUE | TIMER_OVERRIDE)

/// A pair of eyes where his head is. Mouse-transparent, so the only thing to click on is the dark around them.
/obj/effect/bunnyman_eyes
	name = "something"
	desc = "Two points of red, at about the height of a face."
	icon = 'ModularLobotomy/_Lobotomyicons/bunnyman_eyes.dmi'
	icon_state = "eyes"
	pixel_x = -16
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

/// One of his footprints, blood red, pointing the way he went and gone in print_time.
/obj/effect/temp_visual/bunnyman_footprint
	name = "footprint"
	icon = 'icons/effects/footprints.dmi'
	icon_state = "blood2"
	color = "#B01818"
	duration = 3 SECONDS
	randomdir = FALSE
	layer = ABOVE_OPEN_TURF_LAYER

/obj/effect/temp_visual/bunnyman_footprint/Initialize(mapload, step_dir)
	. = ..()
	if(step_dir)
		dir = step_dir
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

// The notices. His clue documents, on walls around his ground, each a window of text when examined. Ripped or cut
// down, one goes up again elsewhere, so reading never costs anyone anything and ripping never hides anything.

/// Picks a wall for a notice of kind, next to a claimed turf, and puts it up.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/PlaceNotice(kind, turf/wall)
	var/obj/structure/sign/poster/bunnyman/notice = new(wall, src, kind)
	Own(notice)
	notices[kind] += 1

/// A wall next to T that has nothing on it yet, or null.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/NoticeWallNear(turf/T)
	for(var/dir in shuffle(GLOB.cardinals))
		var/turf/next = get_step(T, dir)
		if(!next || !isclosedturf(next) || istype(next, wall_type))
			continue
		if(locate(/obj/structure/sign) in next)
			continue
		return next
	return null

/// A kind that has fewer than notices_per_kind up, or null when every kind is at its count.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/NoticeKindWanted()
	var/list/short = list()
	for(var/kind in notice_kinds)
		if(notices[kind] < notices_per_kind)
			short += kind
	return short.len ? pick(short) : null

/// Every claimed turf is a chance for a notice on a wall beside it, while any kind is short.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/OnTurfClaimed(turf/T)
	if(!prob(notice_chance))
		return
	var/kind = NoticeKindWanted()
	if(!kind)
		return
	var/turf/wall = NoticeWallNear(T)
	if(wall)
		PlaceNotice(kind, wall)

/// At spawn: one of each kind, somewhere on the walls of his first ground, so the clues exist from the first minute.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SeedNotices()
	for(var/kind in notice_kinds)
		ReplaceNotice(kind)

/// A notice of kind goes up on a wall beside a random claimed turf, trying a few before giving up until the next claim.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ReplaceNotice(kind)
	if(torn_down)
		return
	for(var/i in 1 to 20)
		var/turf/wall = NoticeWallNear(territory.RandomTurf())
		if(wall)
			PlaceNotice(kind, wall)
			return

/// A clue on a wall. Examining it opens the text. It rips like any poster and comes off to wirecutters, and either
/// way one of the same kind goes up again somewhere else a little later.
/obj/structure/sign/poster/bunnyman
	name = "notice"
	icon = 'ModularLobotomy/_Lobotomyicons/bunnyman_notices.dmi'
	icon_state = "report"
	never_random = TRUE
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion
	/// "report", "missing", "ledger" or "inventory".
	var/kind
	/// Who has its window open, so it closes with the notice and when they step away.
	var/list/readers = list()

/obj/structure/sign/poster/bunnyman/Initialize(mapload, new_distortion, new_kind)
	. = ..()
	distortion = new_distortion
	kind = new_kind
	icon_state = kind
	switch(kind)
		if("report")
			name = "notice - incident report"
			desc = "A fixer office's report, pinned up and left. Someone has read it many times."
		if("missing1", "missing2", "missing3", "missing4")
			icon_state = "missing"
			name = "notice - missing"
			desc = "A missing poster. The face has been drawn over in pencil, carefully, more than once."
		if("ledger")
			name = "notice - a page"
			desc = "A page torn from a ledger and stuck to the wall with something dark."
		if("inventory")
			name = "notice - inventory"
			desc = "A butcher's stock list, the kind kept on a nail by the door."
	original_name = name

/obj/structure/sign/poster/bunnyman/Destroy()
	for(var/mob/M in readers)
		CloseFor(M)
	distortion = null
	return ..()

/// A step away from the wall and the window shuts. Reading it means standing at it.
/obj/structure/sign/poster/bunnyman/proc/OnReaderMoved(mob/M)
	SIGNAL_HANDLER
	CloseFor(M)

/obj/structure/sign/poster/bunnyman/proc/CloseFor(mob/M)
	M << browse(null, "window=bunnyman_notice")
	UnregisterSignal(M, COMSIG_MOVABLE_MOVED)
	readers -= M

/obj/structure/sign/poster/bunnyman/examine(mob/user)
	. = ..()
	if(!Adjacent(user))
		. += span_warning("It is too far away to read. You would have to stand right by it.")
		return
	. += span_notice("You read it.")
	if(distortion)
		user << browse(distortion.NoticeHtml(kind), "window=bunnyman_notice;size=440x560")
		if(!(user in readers))
			readers += user
			RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(OnReaderMoved))
	if(distortion && ishuman(user))
		distortion.OnNoticeRead(src, user)

/// Ripped: the remnant is his too, so it goes with him, and a fresh one goes up elsewhere.
/obj/structure/sign/poster/bunnyman/attack_hand(mob/user)
	visible_message(span_notice("[user] rips [src] in a single, decisive motion!"))
	playsound(loc, 'sound/items/poster_ripped.ogg', 100, TRUE)
	var/obj/structure/sign/poster/ripped/R = new(loc)
	R.pixel_y = pixel_y
	R.pixel_x = pixel_x
	if(distortion)
		distortion.Own(R)
	qdel(src)
	return TRUE

/// Wirecutters take it off in pieces rather than rolling it up: it is not something to carry away.
/obj/structure/sign/poster/bunnyman/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour != TOOL_WIRECUTTER)
		return ..()
	I.play_tool_sound(src, 100)
	to_chat(user, span_notice("It comes off the wall in pieces."))
	qdel(src)

/// A notice is gone, however it went. One of the same kind goes up again after notice_replace_delay.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnNoticeGone(kind)
	notices[kind] -= 1
	addtimer(CALLBACK(src, PROC_REF(ReplaceNotice), kind), notice_replace_delay)

/// The text of each kind, the names and the weapon filled in. The one he judged wrong is never on paper.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/NoticeHtml(kind)
	var/obj/item/bunnyman_evidence/E = evidence_kind
	var/weapon = initial(E.name)
	var/body
	switch(kind)
		if("missing1", "missing2", "missing3", "missing4")
			var/datum/bunnyman_killed/K = killed[text2num(copytext(kind, 8))]
			body = {"<h2>MISSING</h2>
<p><b>[K.name]</b></p>
<p>[LookText(K)]</p>
<p>Last seen on the butcher's street, late. Did not come home.</p>
<p>If you saw anything that night, you saw it wrong. Please come forward anyway.</p>"}
		if("report")
			body = {"<h2>Incident report</h2>
<p><b>Office:</b> backstreets, night desk.<br><b>Subject:</b> assault, the butcher's street.</p>
<p>The attacker, identified by two witnesses as <b>%ATTACKER%</b>, fled on foot toward the canal. The weapon was left at the scene: <b>a %WEAPON%</b>, bagged and taken into evidence. Evidence since lost.</p>
<p>The injured party was not identified and did not come forward.</p>
<p>The butcher on the corner, D. Grifon, gave a statement at the scene: "I saw who did it. One look was enough." He named a bystander who had tried to stop it. Statement withdrawn by this office; not withdrawn by the butcher.</p>
<p><i>Closed. No further action.</i></p>"}
		if("ledger")
			body = {"<h2>&nbsp;</h2>
<p>one look. blood. done.</p><p>one look. blood. done.</p><p>one look. blood. done.</p>
<p>one look. <s>blood</s>. done.</p>
<p>one look. blood. done.</p><p>one look. blood. done.</p>
<p style="margin-top:2em">they keep saying I was wrong about one. they keep saying it. I keep saying what I saw of them, in my room, over and over, and it never comes to a name.</p>
<p>if someone knows the name, let them come and say it to me. there. when I am not the judge. I will not hear it otherwise.</p>
<p style="margin-top:2em"><i>The fourth line has been gone over so many times the pen went through the page.</i></p>"}
		if("inventory")
			body = "<h2>Stock, back room</h2><p>"
			for(var/path in evidence_types)
				var/obj/item/bunnyman_evidence/item = path
				var/line = initial(item.name)
				body += (path == evidence_kind) ? "<span class='circled'>[line]</span><br>" : "[line]<br>"
			body += "</p><p style=\"margin-top:2em\"><i>One line is ringed in pencil, hard enough to score the paper. Beside it, smaller: <b>never looked.</b></i></p>"
	body = replacetext(body, "%ATTACKER%", attacker_name)
	body = replacetext(body, "%WEAPON%", weapon)
	return {"<html><head><title>Notice</title><style>
body { background: #d9cfb6; color: #2a2118; font-family: Georgia, serif; font-size: 15px; padding: 18px 24px; }
h2 { font-size: 20px; letter-spacing: 2px; border-bottom: 1px solid #6b5a42; margin: 0 0 12px 0; }
p { margin: 0 0 10px 0; line-height: 1.4; }
.circled { border: 2px solid #7a1c1c; border-radius: 50%; padding: 2px 8px; }
</style></head><body>[body]</body></html>"}

// The head errand. Someone dead on a hook is a head he wants where it will be seen: he walks to the body, works the
// head off, carries it, and plants it on the edge of his ground. Hunts come first; the errand waits and resumes.

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HeadWanted(mob/living/carbon/human/M)
	heads_wanted |= M

/// Still a head to take: dead, on one of his hooks, head still on.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnHook(mob/living/carbon/human/M)
	return !QDELETED(M) && M.stat == DEAD && M.buckled && (M.buckled in spikes) && M.get_bodypart(BODY_ZONE_HEAD)

/// What to do with nothing to hunt, in order: plant a head in hand, fetch a head, tear down a notice someone read,
/// feed a Victim; then by chance, sit with a rabbit or go back to the den. In the den, by chance, a mutter.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/StartErrand()
	if(carried_head)
		BeginErrand("placing")
		head_turf = EdgeTurf()
		return
	for(var/mob/living/carbon/human/M in heads_wanted)
		if(OnHook(M))
			head_body = M
			BeginErrand("collecting")
			return
		heads_wanted -= M
	if(rip_target && !QDELETED(rip_target))
		BeginErrand("ripping")
		return
	give_target = VictimToFeed()
	if(give_target)
		BeginErrand("giving")
		return
	if(istype(loc, floor_type) && world.time >= next_mutter && prob(mutter_chance))
		Mutter()
	if(world.time >= next_pet && prob(pet_chance))
		pet_target = RabbitNear()
		if(pet_target)
			BeginErrand("petting")
			return
	if(prob(den_chance))
		clear_target = HookToClear()
		if(clear_target)
			BeginErrand("clearing")
			return
		var/list/den = DenTurfs()
		if(den.len)
			den_turf = pick(den)
			BeginErrand("den")

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/BeginErrand(what)
	hunt_state = "errand"
	errand = what
	patrol_reset()

/// Walks to whatever the errand is about and does it on arrival. Anything gone or spoiled ends the errand.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ErrandTick()
	switch(errand)
		if("collecting")
			if(!OnHook(head_body))
				heads_wanted -= head_body
				EndErrand()
				return
			if(!head_body.Adjacent(src))
				GoTo(get_turf(head_body))
				return
			patrol_reset()
			walk(src, 0)
			if(!taking_head)
				INVOKE_ASYNC(src, PROC_REF(TakeHead))
		if("placing")
			if(loc == head_turf)
				PlaceHead()
				return
			if(!length(patrol_path) && !WalkTo(head_turf))
				head_turf = EdgeTurf()
		if("ripping")
			if(QDELETED(rip_target))
				rip_target = null
				EndErrand()
				return
			if(get_dist(src, rip_target) <= 1)
				RipNotice()
				return
			if(!GoTo(NearestOpenTurf(get_turf(rip_target))))
				EndErrand()
		if("petting")
			if(QDELETED(pet_target) || pet_target.stat == DEAD)
				EndErrand()
				return
			if(pet_target.Adjacent(src))
				PetRabbit()
				return
			GoTo(get_turf(pet_target))
		if("giving")
			if(QDELETED(give_target) || give_target.stat == DEAD || !give_target.has_status_effect(/datum/status_effect/bunnyman_mark/victim) || !territory.Contains(get_turf(give_target)))
				EndErrand()
				return
			if(give_target.Adjacent(src))
				GiveCarrot()
				return
			GoTo(get_turf(give_target))
		if("clearing")
			if(QDELETED(clear_target) || clear_target != HookToClear())
				EndErrand()
				return
			if(clear_target.Adjacent(src))
				ClearHook()
				return
			GoTo(get_turf(clear_target))
		if("dumping")
			if(!carried)
				EndErrand()
				return
			if(loc == den_turf)
				SetDown()
				visible_message(span_notice("[carried ? carried : "The body"] is set down on the pile."))
				EndErrand()
				return
			if(!GoTo(den_turf))
				EndErrand()
		if("den")
			if(loc == den_turf)
				Mutter()
				EndErrand()
				return
			if(!GoTo(den_turf))
				EndErrand()

/// A step of walking on an errand: a new path when the old one has run out. FALSE when there is no way there.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/GoTo(turf/T)
	if(length(patrol_path))
		return TRUE
	return T && WalkTo(T)

/// head_take_time with the body, then the head is his. A hunt starting in the middle leaves the head where it is.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/TakeHead()
	taking_head = TRUE
	head_body.visible_message(span_danger("Something takes hold of [head_body]'s head and pulls."))
	if(do_after(src, head_take_time, head_body) && hunt_state == "errand" && errand == "collecting" && OnHook(head_body))
		var/obj/item/bodypart/head/head = head_body.get_bodypart(BODY_ZONE_HEAD)
		head.dismember()
		head.forceMove(src)
		carried_head = head
		heads_wanted -= head_body
		head_body = null
		errand = "placing"
		head_turf = EdgeTurf()
	taking_head = FALSE

/// A claimed turf with unclaimed open ground beside it: the edge of his territory, where a head is seen from outside.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/EdgeTurf()
	var/list/edge = list()
	for(var/turf/T in territory.claimed)
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(next && !next.density && !territory.Contains(next))
				edge += T
				break
	return edge.len ? pick(edge) : territory.RandomTurf()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/PlaceHead()
	var/obj/structure/headpike/bunnyman/P = new(loc, carried_head.real_name, carried_head)
	P.distortion = src
	Own(P)
	carried_head = null
	EndErrand()

/// Back to nothing in particular, and hidden. A head in hand is kept for the next errand; a body on his shoulder from
/// clearing a hook is set down where he stands, so the drag never mistakes it for the hunted.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/EndErrand()
	hunt_state = "idle"
	errand = null
	head_body = null
	head_turf = null
	pet_target = null
	give_target = null
	clear_target = null
	den_turf = null
	SetDown()
	patrol_reset()
	Hide()

// What his ground does to people. Stages 0 to 2 are oddities only, the small wrong things the base rolls near
// players. From stage 3, the people inside see him coming when he is not, and his rabbits sometimes look like him.

/// A thump from somewhere out of sight: one tread, from a claimed turf, going nowhere.
/obj/effect/temp_visual/distortion_oddity/bunnyman_thump
	icon_state = null
	alpha = 0
	duration = 1 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_thump/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/owner)
	. = ..()
	playsound(loc, pick(owner.footstep_sounds), 40, TRUE)

/// Three or four of his steps in a row, a step apart, from somewhere nobody is looking.
/obj/effect/temp_visual/distortion_oddity/bunnyman_steps
	icon_state = null
	alpha = 0
	duration = 4 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_steps/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/owner)
	. = ..()
	for(var/i in 0 to rand(2, 3))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), loc, pick(owner.footstep_sounds), 40, TRUE), i * 0.8 SECONDS)

/// One footprint that was not there, with its tread, fading as the real ones do.
/obj/effect/temp_visual/distortion_oddity/bunnyman_print
	icon_state = null
	alpha = 0
	duration = 1 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_print/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/owner)
	. = ..()
	new /obj/effect/temp_visual/bunnyman_footprint(loc, pick(GLOB.cardinals))
	playsound(loc, pick(owner.footstep_sounds), 40, TRUE)

/// Two eyes, for a second, then gone.
/obj/effect/temp_visual/distortion_oddity/bunnyman_glimpse
	icon = 'ModularLobotomy/_Lobotomyicons/bunnyman_eyes.dmi'
	icon_state = "eyes"
	pixel_x = -16
	layer = ABOVE_MOB_LAYER
	duration = 1 SECONDS

/// A rabbit crossing the far end of the corridor, and gone before anyone gets there.
/obj/effect/temp_visual/distortion_oddity/bunnyman_crossing
	icon = 'icons/mob/easter.dmi'
	icon_state = "rabbit_white"
	layer = MOB_LAYER
	duration = 2.5 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_crossing/Initialize(mapload)
	. = ..()
	icon_state = pick("rabbit_white", "rabbit_brown", "rabbit_black")
	var/move_dir = pick(GLOB.cardinals)
	dir = move_dir
	var/dx = (move_dir == EAST ? 1 : (move_dir == WEST ? -1 : 0)) * 128
	var/dy = (move_dir == NORTH ? 1 : (move_dir == SOUTH ? -1 : 0)) * 128
	animate(src, pixel_x = dx, pixel_y = dy, time = duration - 0.5 SECONDS)
	animate(alpha = 0, time = 0.5 SECONDS)

/// A smear of blood on the floor that is not there three seconds later.
/obj/effect/temp_visual/distortion_oddity/bunnyman_smear
	icon = 'icons/effects/blood.dmi'
	icon_state = "floor1"
	layer = ABOVE_OPEN_TURF_LAYER
	duration = 3 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_smear/Initialize(mapload)
	. = ..()
	icon_state = "floor[rand(1, 7)]"
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/// Every so often from hallucination_stage, a person inside sees him rush them from the edge of their view. Nobody
/// else sees it. Twice as often at the cap.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HallucinationTick(list/inside)
	if(territory.stage < hallucination_stage || !judging)
		return
	var/interval = hallucination_interval
	if(territory.stage >= 4)
		interval /= 2
	for(var/mob/living/carbon/human/H in inside)
		if(!H.client || H.stat != CONSCIOUS)
			continue
		if(isnull(next_hallucination[H]))
			RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(OnHallucinatedDeleted))
			next_hallucination[H] = world.time + rand(interval * 0.5, interval)
			continue
		if(world.time < next_hallucination[H])
			continue
		next_hallucination[H] = world.time + rand(interval * 0.5, interval)
		var/turf/start = HallucinationStart(H)
		if(start)
			new /obj/effect/hallucination/simple/bunnyman(start, H, src)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnHallucinatedDeleted(datum/source)
	SIGNAL_HANDLER
	next_hallucination -= source

/// A claimed turf at the edge of H's view, or null if there is none to be had.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HallucinationStart(mob/living/carbon/human/H)
	for(var/i in 1 to 15)
		var/turf/T = territory.RandomTurfNear(get_turf(H), 7)
		if(T.z == H.z && get_dist(T, H) >= 5 && (T in view(7, H)))
			return T
	return null

/// Him, to one person: his enraged sprite coming at them a tile at a time. Reaching them costs hallucination_sanity;
/// a step onto unclaimed ground ends it with nothing. Leaving his ground is always the answer.
/obj/effect/hallucination/simple/bunnyman
	image_icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	image_state = "bunnyman_enraged"
	px = -16
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion

/obj/effect/hallucination/simple/bunnyman/Initialize(mapload, mob/living/carbon/T, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/new_distortion)
	. = ..()
	distortion = new_distortion
	distortion.Own(src)
	target.playsound_local(get_turf(src), 'sound/distortions/bunnyman/scream.ogg', 40, FALSE)
	addtimer(CALLBACK(src, PROC_REF(Step)), distortion.hallucination_step)

/obj/effect/hallucination/simple/bunnyman/Destroy()
	distortion = null
	return ..()

/obj/effect/hallucination/simple/bunnyman/proc/Step()
	if(QDELETED(target) || !distortion || target.z != z)
		qdel(src)
		return
	var/turf/next = get_step_towards(src, target)
	if(!next || !distortion.territory.Contains(next))
		qdel(src)
		return
	forceMove(next)
	target.playsound_local(next, pick(distortion.footstep_sounds), 50, TRUE)
	if(get_dist(src, target) <= 1)
		var/mob/living/carbon/human/H = target
		to_chat(H, span_userdanger("He is on you. And then he is not."))
		H.adjustSanityLoss(distortion.hallucination_sanity)
		qdel(src)
		return
	addtimer(CALLBACK(src, PROC_REF(Step)), distortion.hallucination_step)

/// From hallucination_stage, one rabbit every mimic_interval that has a human in view takes his shape and runs at them.
/// The interval only counts from a mimic that happened; a scan that found nobody looks again after mimic_retry.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/MimicTick()
	if(territory.stage < hallucination_stage || !judging || world.time < next_mimic)
		return
	for(var/mob/living/simple_animal/hostile/bunnyman_rabbit/R in shuffle(rabbits))
		if(R.stat == DEAD || R.mimic_target)
			continue
		for(var/mob/living/carbon/human/H in view(7, R))
			if(H.stat == CONSCIOUS)
				R.Mimic(H)
				next_mimic = world.time + mimic_interval
				return
	next_mimic = world.time + mimic_retry

// The other errands. With nothing to hunt he has a life of his own on his ground: a notice read in his sight is torn
// down and the reader warned; a rabbit is sat with and comforted; a Victim is found and given a carrot; the den is
// visited for a mutter, and a hook with a headless body on it is cleared. Hunts come first over all of it.

/// A notice read where he can see the reader is torn down the next chance he gets, and the reader warned for it.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnNoticeRead(obj/structure/sign/poster/bunnyman/notice, mob/living/carbon/human/reader)
	if(rip_target || !CanSee(reader))
		return
	rip_target = notice
	rip_reader = reader

/// Taking from a rabbit in his sight: a warning as the hand goes out, the mark once the rabbit lets go.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnEvidenceTaking(mob/living/simple_animal/hostile/bunnyman_rabbit/R, mob/living/carbon/human/taker)
	if(CanSee(R))
		Warn(taker)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnEvidenceTaken(mob/living/simple_animal/hostile/bunnyman_rabbit/R, mob/living/carbon/human/taker)
	if(CanSee(R))
		MarkPerpetrator(taker)

/// A Victim on his ground who has not been given anything yet, or null.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/VictimToFeed()
	for(var/mob/living/carbon/human/H as anything in GLOB.human_list)
		if(H.z != z || H.stat == DEAD || !territory.Contains(get_turf(H)))
			continue
		var/datum/status_effect/bunnyman_mark/victim/V = H.has_status_effect(/datum/status_effect/bunnyman_mark/victim)
		if(V && !V.fed && !H.has_status_effect(/datum/status_effect/bunnyman_mark/perpetrator))
			return H
	return null

/// A living rabbit within sight of him, or null.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/RabbitNear()
	for(var/mob/living/simple_animal/hostile/bunnyman_rabbit/R in view(7, src))
		if(R.stat != DEAD && !R.mimic_target)
			return R
	return null

/// A hook with a dead, headless body on it, or null.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HookToClear()
	for(var/obj/structure/kitchenspike/bunnyman/S in spikes)
		for(var/mob/living/carbon/human/M in S.buckled_mobs)
			if(M.stat == DEAD && !M.get_bodypart(BODY_ZONE_HEAD))
				return S
	return null

/// Facing the wall with the notice: it comes down, he says why, and the reader is warned.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/RipNotice()
	Reveal()
	visible_message(span_danger("[src] tears [rip_target] from the wall!"))
	playsound(loc, 'sound/items/poster_ripped.ogg', 100, TRUE)
	var/obj/structure/sign/poster/ripped/R = new(get_turf(rip_target))
	R.pixel_x = rip_target.pixel_x
	R.pixel_y = rip_target.pixel_y
	Own(R)
	qdel(rip_target)
	rip_target = null
	say(pick(rip_lines))
	if(!QDELETED(rip_reader))
		Warn(rip_reader, FALSE)
	rip_reader = null
	EndErrand()

/// A hand on the rabbit. It is whole again, and it leans in.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/PetRabbit()
	if(hidden)
		pet_target.visible_message(span_notice("Something strokes [pet_target]'s ears."))
	else
		visible_message(span_notice("[src] crouches and strokes [pet_target]'s ears."))
	var/line = pick(pet_lines - last_pet_line)
	last_pet_line = line
	say(line)
	next_pet = world.time + pet_cooldown
	pet_target.adjustHealth(-pet_target.maxHealth)
	pet_target.manual_emote(pick("leans into the hand.", "twitches its nose and goes still.", "closes its eyes."))
	pet_target = null
	EndErrand()

/// A carrot into the Victim's hand, or at their feet if their hands are full. Once each.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/GiveCarrot()
	var/obj/item/food/grown/carrot/bunnyman/C = new(get_turf(give_target))
	if(give_target.put_in_hands(C))
		to_chat(give_target, span_notice("A carrot is pressed into your hand."))
	else
		to_chat(give_target, span_notice("A carrot is set down at your feet."))
	whisper(pick(give_lines))
	var/datum/status_effect/bunnyman_mark/victim/V = give_target.has_status_effect(/datum/status_effect/bunnyman_mark/victim)
	if(V)
		V.fed = TRUE
	give_target = null
	EndErrand()

/// The body comes down off the hook and over his shoulder, to be set down on the pile.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ClearHook()
	var/mob/living/carbon/human/body
	for(var/mob/living/carbon/human/M in clear_target.buckled_mobs)
		body = M
		break
	clear_target = null
	if(!body)
		EndErrand()
		return
	var/obj/structure/kitchenspike/bunnyman/S = body.buckled
	S.release_mob(body)
	if(!PickUp(body))
		EndErrand()
		return
	errand = "dumping"
	den_turf = pile_turf || pick(DenTurfs())

/// A carrot from him, for the fright. Eating it mends 20 brute and a quarter of max sanity.
/obj/item/food/grown/carrot/bunnyman
	desc = "A carrot, a little old, pressed into your hand by someone who was not sorry about anything else."
	var/carrot_brute = 20
	var/carrot_sanity_fraction = 0.25

/obj/item/food/grown/carrot/bunnyman/OnConsume(mob/living/eater, mob/living/feeder)
	. = ..()
	if(!ishuman(eater))
		return
	var/mob/living/carbon/human/H = eater
	H.adjustBruteLoss(-carrot_brute)
	H.adjustSanityLoss(-H.maxSanity * carrot_sanity_fraction)
	to_chat(H, span_nicegreen("It is only a carrot. It helps anyway."))

// The killed, and the way out. He killed four people on this street. Three bit; one was only standing there, and that
// is the one he cannot stop talking about in his room: a piece of how they looked at a time, never the name. The
// names and the looks are on the missing posters. Say the right name to his face in his room while his judgement is
// off, and he looks up for good.

/// One of the people he killed: a name and a look in six parts, as a missing poster would give them.
/datum/bunnyman_killed
	var/name
	/// slot to what was worn or seen: "hat", "hair", "eyes", "shirt", "coat", "shoes".
	var/list/look = list()

/// Rolls the four. The innocent first; each murderer is made to differ from them in at least two parts of the look.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/RollKilled()
	for(var/i in 1 to killed_count)
		var/datum/bunnyman_killed/K = new
		K.name = random_unique_name(pick(MALE, FEMALE))
		for(var/slot in look_options)
			K.look[slot] = pick(look_options[slot])
		if(i > 1)
			var/datum/bunnyman_killed/innocent = killed[1]
			while(LookDifference(K, innocent) < 2)
				var/slot = pick(look_options)
				K.look[slot] = pick(look_options[slot] - innocent.look[slot])
		killed += K

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/LookDifference(datum/bunnyman_killed/A, datum/bunnyman_killed/B)
	. = 0
	for(var/slot in look_options)
		if(A.look[slot] != B.look[slot])
			.++

/// The look as a missing poster writes it.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/LookText(datum/bunnyman_killed/K)
	return "Last seen wearing [K.look["coat"]] over [K.look["shirt"]], [K.look["shoes"]], [K.look["hat"]]. [capitalize(K.look["hair"])], [K.look["eyes"]]."

/// Which of the killed a message names, or null.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/KilledNamed(message)
	for(var/datum/bunnyman_killed/K in killed)
		if(findtext(message, K.name))
			return K
	return null

/// In the den, idle: he stops for a moment and says one part of how the innocent looked. Never the name.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Mutter()
	if(world.time < next_mutter)
		return
	next_mutter = world.time + mutter_cooldown
	rooted_until = world.time + mutter_pause
	walk(src, 0)
	patrol_reset()
	var/datum/bunnyman_killed/innocent = killed[1]
	var/part = innocent.look[pick(look_options)]
	say(replacetext(pick(mutter_clue_lines), "%PART%", part))

// Hearing. The say hook on humans standing on his ground, held and let go by the territory tick.

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ListenTick(list/inside)
	for(var/mob/living/carbon/human/H in inside)
		if(H in listening)
			continue
		RegisterSignal(H, COMSIG_MOB_SAY, PROC_REF(OnSpeech))
		listening += H
	for(var/mob/living/carbon/human/H in listening)
		if(QDELETED(H) || !(H in inside))
			UnregisterSignal(H, COMSIG_MOB_SAY)
			listening -= H

/// A name of the killed, said where he can hear. With his judgement on it is a warning, worded for which name it
/// was. With it off and the speaker in his sight, the innocent's name is the way out and a murderer's is a fight.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnSpeech(mob/living/carbon/human/speaker, list/speech_args)
	SIGNAL_HANDLER
	var/message = speech_args[SPEECH_MESSAGE]
	if(!message || stat == DEAD || undistort_timer)
		return
	var/datum/bunnyman_killed/K = KilledNamed(message)
	if(!K || !(speaker in view(src)))
		return
	if(judging)
		say(K == killed[1] ? pick(right_name_warnings) : pick(wrong_name_warnings))
		Warn(speaker, FALSE)
		return
	if(K == killed[1])
		INVOKE_ASYNC(src, PROC_REF(StartUndistorting), speaker)
		return
	say("That one bit.")
	INVOKE_ASYNC(src, PROC_REF(WakeOn), speaker)

/// Out of the stun and onto whoever did it, the fair fight's way. Used by a hit and by a wrong name.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/WakeOn(mob/living/source)
	if(hunt_state == "stunned")
		hunt_state = "idle"
		visible_message(span_danger("[src] turns on [source]."))
		HideStagger()
	Provoke(source)

/// He looks up. The rays grow for undistort_time while the window is held open; a hit before the end puts them out.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/StartUndistorting(mob/living/carbon/human/speaker)
	if(judgement_timer)
		judgement_left = max(timeleft(judgement_timer), judgement_resume_floor)
		deltimer(judgement_timer)
		judgement_timer = null
	undistort_timer = addtimer(CALLBACK(src, PROC_REF(Undistort)), undistort_time, TIMER_STOPPABLE)
	visible_message(span_notice("[src] goes still in a different way. Something behind the mask starts to shine."))
	to_chat(speaker, span_nicegreen("He looks at you. He looks for a long time."))
	var/datum/bunnyman_killed/innocent = killed[1]
	say("...[innocent.name]. That was the name.")
	add_filter("undistort", 1, rays_filter(size = 4, color = "#FFD8C8", offset = 0, density = 10, threshold = 0.15))
	transition_filter("undistort", undistort_time, list(size = 120, offset = 90), SINE_EASING | EASE_IN)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/CancelUndistort()
	if(!undistort_timer)
		return
	deltimer(undistort_timer)
	undistort_timer = null
	remove_filter("undistort")
	judgement_timer = addtimer(CALLBACK(src, PROC_REF(JudgementBack)), judgement_left, TIMER_STOPPABLE)
	visible_message(span_warning("The light goes out of him."))

/// The base Unmanifest() releases the stored human alive with the EGO, so the usual death cleanup never sees them.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Undistort()
	undistort_timer = null
	if(QDELETED(src) || stat == DEAD)
		return
	Unmanifest()

// The rabbits. His view of people, made solid. Each carries one thing from his shop; one of them carries the thing
// he never looked at. They never leave his ground, run from anyone coming at a run, and give what they hold to
// anyone who walks up and waits.

/// Keeps the territory at its rabbit count: rabbit_base at spawn, rabbits_per_stage more for each stage.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/FillRabbits()
	if(torn_down)
		return
	var/wanted = rabbit_base + rabbits_per_stage * territory.stage
	while(LivingRabbits() < wanted)
		SpawnRabbit()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/LivingRabbits()
	. = 0
	for(var/mob/living/simple_animal/hostile/bunnyman_rabbit/R in rabbits)
		if(R.stat != DEAD)
			.++

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SpawnRabbit()
	var/mob/living/simple_animal/hostile/bunnyman_rabbit/R = new(territory.RandomTurf(), src)
	rabbits += R
	Own(R)
	R.GiveEvidence(RollEvidenceKind())

/// A type for a rabbit to carry. The rolled kind is always out there on one of them; after that, no two alike
/// while evidence_types lasts.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/RollEvidenceKind()
	var/list/carried = list()
	for(var/mob/living/simple_animal/hostile/bunnyman_rabbit/R in rabbits)
		if(R.stat != DEAD && R.evidence)
			carried += R.evidence.type
	if(!(evidence_kind in carried))
		return evidence_kind
	var/list/free = evidence_types - carried
	if(free.len)
		return pick(free)
	return pick(evidence_types)

/// A dead rabbit lies where it fell for rabbit_respawn, then is gone and another sits somewhere else on his ground.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnRabbitDied(mob/living/simple_animal/hostile/bunnyman_rabbit/R)
	addtimer(CALLBACK(src, PROC_REF(ReplaceRabbit), R), rabbit_respawn)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/ReplaceRabbit(mob/living/simple_animal/hostile/bunnyman_rabbit/R)
	if(torn_down)
		return
	qdel(R)
	FillRabbits()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/OnOwnedDeleted(datum/source)
	. = ..()
	rabbits -= source
	spikes -= source
	if(istype(source, /obj/structure/sign/poster/bunnyman))
		var/obj/structure/sign/poster/bunnyman/notice = source
		OnNoticeGone(notice.kind)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/OnStageChange(old_stage, new_stage)
	. = ..()
	FillRabbits()

/// The Resurgence Clan citizen's flight: ranged with nothing to fire, so it only ever keeps its distance from
/// its target. Here the target is a human coming at a run and nothing else.
/mob/living/simple_animal/hostile/bunnyman_rabbit
	name = "rabbit"
	desc = "It is looking at you."
	icon = 'icons/mob/easter.dmi'
	icon_state = "b_rabbit_white"
	icon_living = "b_rabbit_white"
	icon_dead = "b_rabbit_white_dead"
	maxHealth = 20
	health = 20
	faction = list("hostile", "bunnyman")
	ranged = TRUE
	retreat_distance = 10
	minimum_distance = 10
	vision_range = 3
	ranged_message = null
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	environment_smash = FALSE
	density = FALSE
	mob_size = MOB_SIZE_SMALL
	speak_emote = list("twitches")
	emote_see = list("twitches its nose", "sits very still", "looks at you")
	response_help_continuous = "holds a hand out to"
	response_help_simple = "hold a hand out to"
	del_on_death = FALSE
	/// Whose rabbit this is. Its ground is his territory.
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion
	/// What it holds, inside its contents. Null while it sits empty-handed.
	var/obj/item/bunnyman_evidence/evidence
	/// Until when it runs from every human, walking or not. Set when something hurts it.
	var/startled_until = 0
	var/startle_time = 5 SECONDS
	/// How long a hand must be held out for it to give up what it holds.
	var/hand_out_time = 3 SECONDS
	/// Where it stood at the last AI tick, to notice when fleeing has it pinned.
	var/turf/last_loc
	/// Who it is running at while it wears his shape. Null when it is only a rabbit.
	var/mob/living/carbon/human/mimic_target
	var/mimic_speed = 3

/mob/living/simple_animal/hostile/bunnyman_rabbit/Initialize(mapload, new_distortion)
	. = ..()
	distortion = new_distortion
	var/coat = pick("b_rabbit_white", "b_rabbit_brown", "b_rabbit_black")
	icon_state = coat
	icon_living = coat
	icon_dead = "[coat]_dead"
	RegisterSignal(src, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnHurt))

/mob/living/simple_animal/hostile/bunnyman_rabbit/Destroy()
	distortion = null
	if(evidence)
		QDEL_NULL(evidence)
	return ..()

/mob/living/simple_animal/hostile/bunnyman_rabbit/examine(mob/user)
	. = ..()
	if(stat == DEAD)
		return
	if(evidence)
		. += span_notice("It is holding \a [evidence], far too big for it.")
	else
		. += span_notice("It is holding nothing, and keeps looking at your hands.")

/// Only a human coming at a run is anything to it, unless something just hurt it. Walk up and it stays put.
/mob/living/simple_animal/hostile/bunnyman_rabbit/CanAttack(atom/the_target)
	if(mimic_target)
		return FALSE
	if(!ishuman(the_target))
		return FALSE
	var/mob/living/carbon/human/H = the_target
	if(H.m_intent != MOVE_INTENT_RUN && world.time >= startled_until)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/OnHurt(datum/source, damage_amount)
	SIGNAL_HANDLER
	if(damage_amount > 0)
		startled_until = world.time + startle_time

/// It never touches anyone, so the stock nuzzle of a mob with no melee damage never prints.
/mob/living/simple_animal/hostile/bunnyman_rabbit/AttackingTarget(atom/attacked_target)
	return FALSE

/// Pinned against a wall with the runner in front, walk_away finds no step and it would freeze. Then it darts
/// through any open side instead, the runner's own tile included, since nothing stops a rabbit underfoot.
/mob/living/simple_animal/hostile/bunnyman_rabbit/handle_automated_action()
	if(mimic_target)
		MimicStep()
		return
	. = ..()
	if(target && stat != DEAD && get_dist(src, target) <= retreat_distance && loc == last_loc)
		Dodge()
	last_loc = loc

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/Dodge()
	walk(src, 0)
	for(var/dir in shuffle(GLOB.alldirs))
		if(Move(get_step(src, dir), dir))
			return

/// His shape, and a run straight at H. The moment it reaches them, or loses them, it is a rabbit again.
/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/Mimic(mob/living/carbon/human/H)
	mimic_target = H
	LoseTarget()
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "bunnyman_enraged"
	pixel_x = -16
	visible_message(span_userdanger("[src] is suddenly a great deal bigger, and coming!"))
	walk_to(src, H, 0, mimic_speed)

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/MimicStep()
	if(QDELETED(mimic_target) || mimic_target.z != z || get_dist(src, mimic_target) > 10 || stat == DEAD)
		Unmimic()
		return
	if(Adjacent(mimic_target))
		visible_message(span_notice("[src] stops at [mimic_target]'s feet, a rabbit, and sits."))
		Unmimic()
		return
	walk_to(src, mimic_target, 0, mimic_speed)

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/Unmimic()
	walk(src, 0)
	mimic_target = null
	icon = initial(icon)
	icon_state = icon_living
	pixel_x = 0

/// It never leaves his ground. A step onto unclaimed turf does not happen, so at the edge it is cornered.
/mob/living/simple_animal/hostile/bunnyman_rabbit/Move(atom/newloc, direct)
	if(distortion && !distortion.territory.Contains(newloc))
		return FALSE
	return ..()

/// Help intent, adjacent: a hand held out for hand_out_time, and it lets go of what it holds at your feet.
/// A hand held out by someone set to run, or someone who breaks into a run mid-wait, sends it bolting instead.
/mob/living/simple_animal/hostile/bunnyman_rabbit/attack_hand(mob/living/carbon/human/M)
	if(stat == DEAD || M.a_intent != INTENT_HELP)
		return ..()
	if(M.m_intent == MOVE_INTENT_RUN)
		Startle(M)
		return TRUE
	if(!evidence)
		to_chat(M, span_notice("You hold out your hand. The rabbit looks at it, then at you. It has nothing to give."))
		return TRUE
	M.visible_message(span_notice("[M] holds a hand out to [src]."), span_notice("You hold out your hand. The rabbit considers you."))
	if(distortion)
		distortion.OnEvidenceTaking(src, M)
	if(!do_after(M, hand_out_time, src, extra_checks = CALLBACK(src, PROC_REF(StillCalm), M)))
		if(M.m_intent == MOVE_INTENT_RUN)
			Startle(M)
		return TRUE
	var/obj/item/bunnyman_evidence/given = evidence
	DropEvidence(get_turf(M))
	if(distortion)
		distortion.OnEvidenceTaken(src, M)
	M.visible_message(span_notice("[src] lets go of [given] and sits back."), span_notice("The rabbit lets go of [given] and sits back, empty-handed."))
	addtimer(CALLBACK(src, PROC_REF(Rearm)), distortion.rabbit_respawn)
	return TRUE

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/StillCalm(mob/living/carbon/human/M)
	return stat != DEAD && evidence && M.m_intent != MOVE_INTENT_RUN

/// Runs from M now, and from every human for startle_time after, whether they walk or not.
/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/Startle(mob/living/carbon/human/M)
	startled_until = world.time + startle_time
	visible_message(span_warning("[src] bolts!"))
	if(AIStatus == AI_IDLE)
		toggle_ai(AI_ON)
	GiveTarget(M)

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/GiveEvidence(kind)
	evidence = new kind(src)
	evidence.distortion = distortion
	distortion.Own(evidence)

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/DropEvidence(turf/T)
	evidence.forceMove(T)
	evidence = null

/// An emptied rabbit is carrying again after a while, something rerolled.
/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/Rearm()
	if(stat == DEAD || evidence || !distortion)
		return
	GiveEvidence(distortion.RollEvidenceKind())

/// Killing one drops what it held. The blood drawn is judged by the taboo like any other.
/mob/living/simple_animal/hostile/bunnyman_rabbit/death(gibbed)
	. = ..()
	if(evidence)
		DropEvidence(get_turf(src))
	if(distortion)
		distortion.OnRabbitDied(src)

// The evidence. His own things, so nothing from outside stands in for them. One subtype per piece; the one he never
// looked at is a subtype path rolled at spawn. The sprites are borrowed item sprites recoloured onto the bone axe
// palette, by workspace/art/scripts/bunnyman/gen_evidence.pl. None of them shows in hand.

/obj/item/bunnyman_evidence
	name = "evidence"
	desc = "Something of his."
	icon = 'ModularLobotomy/_Lobotomyicons/bunnyman_evidence.dmi'
	icon_state = "knife"
	inhand_icon_state = "bunnyman_evidence"
	w_class = WEIGHT_CLASS_SMALL
	force = 5
	attack_verb_continuous = list("strikes")
	attack_verb_simple = list("strike")
	/// Whose piece this is. Set when a rabbit is handed it.
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion
	/// Left lying on the ground this long, it fades and a rabbit with nothing to hold is holding it instead.
	var/fade_time = 5 MINUTES
	/// How long it waits before looking for an empty rabbit again when none was free.
	var/fade_retry = 1 MINUTES
	var/fade_timer

/obj/item/bunnyman_evidence/examine(mob/user)
	. = ..()
	. += span_notice("It is heavier than it should be, as if it were holding a verdict. If this is the thing he never looked at, striking him with it will make him look. If it is not, it will break in your hands and he will not stop.")

/// The fade clock runs only while it lies on a turf. Picked up, bagged, or handed to a rabbit, it stops.
/obj/item/bunnyman_evidence/Moved(atom/old_loc, dir, forced)
	. = ..()
	if(fade_timer)
		deltimer(fade_timer)
		fade_timer = null
	if(isturf(loc))
		fade_timer = addtimer(CALLBACK(src, PROC_REF(Fade)), fade_time, TIMER_STOPPABLE)

/obj/item/bunnyman_evidence/Destroy()
	if(fade_timer)
		deltimer(fade_timer)
	distortion = null
	return ..()

/// Gone, and in the hands of a rabbit that had nothing. With no such rabbit it lies a while longer and looks again.
/obj/item/bunnyman_evidence/proc/Fade()
	fade_timer = null
	var/list/empty = list()
	for(var/mob/living/simple_animal/hostile/bunnyman_rabbit/R in distortion.rabbits)
		if(R.stat != DEAD && !R.evidence)
			empty += R
	if(!empty.len)
		fade_timer = addtimer(CALLBACK(src, PROC_REF(Fade)), fade_retry, TIMER_STOPPABLE)
		return
	var/mob/living/simple_animal/hostile/bunnyman_rabbit/R = pick(empty)
	R.GiveEvidence(type)
	animate(src, alpha = 0, time = 2 SECONDS)
	QDEL_IN(src, 2 SECONDS)

/obj/item/bunnyman_evidence/boning_knife
	name = "boning knife"
	desc = "A thin, flexible knife for working meat off the bone. The edge has been kept; the handle has not."
	icon_state = "knife"

/obj/item/bunnyman_evidence/cleaver
	name = "cleaver with a cracked spine"
	desc = "A heavy cleaver. A crack runs along the back of the blade from one hard blow too many."
	icon_state = "cleaver"

/obj/item/bunnyman_evidence/butcher_knife
	name = "butcher's knife with a bitten handle"
	desc = "A broad butcher's knife. Something has chewed the end of the wooden handle to splinters."
	icon_state = "butch"

/obj/item/bunnyman_evidence/skinning_knife
	name = "skinning knife"
	desc = "A short curved knife for taking a hide off whole. It has done this many times."
	icon_state = "buckknife"

/obj/item/bunnyman_evidence/bone_saw
	name = "bone saw"
	desc = "A butcher's saw with fine teeth. There is old marrow in them."
	icon_state = "saw"

/obj/item/bunnyman_evidence/mallet
	name = "meat mallet"
	desc = "A long-handled mallet for tenderising. The head is stained the colour of the floor of a cold room."
	icon_state = "sledgehammer"

/obj/item/bunnyman_evidence/chain
	name = "length of chain"
	desc = "A length of chain with a hook at one end, for hanging a carcass. It is cold."
	icon_state = "chain"

/obj/item/bunnyman_evidence/bottle
	name = "bottle with a butcher's label"
	desc = "A bottle of something strong. The label is a butcher's shop label, written over in pencil."
	icon_state = "whiskeybottle"

// His things. Attacking a hook or a head where he can see it earns a warning; breaking one is the mark. Unhooking
// someone in his sight warns, and done, marks both; done behind his back, the freed one is Paranoid until he sees them.

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/CanSee(atom/A)
	return judging && stat != DEAD && (A in view(src))

/// A warning: he points, says one of his lines unless the caller already had him say something, and the mark of it
/// goes on. Two are kept; the third is the mark.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Warn(mob/living/carbon/human/H, speak = TRUE)
	if(H.has_status_effect(/datum/status_effect/bunnyman_mark/perpetrator))
		return
	point_at(H)
	if(speak)
		say(pick(warning_lines))
	var/datum/status_effect/bunnyman_mark/warned/W = H.has_status_effect(/datum/status_effect/bunnyman_mark/warned)
	if(!W)
		H.apply_status_effect(/datum/status_effect/bunnyman_mark/warned, src)
		return
	if(W.warnings >= 2)
		H.remove_status_effect(/datum/status_effect/bunnyman_mark/warned)
		MarkPerpetrator(H)
		return
	W.AddWarning()

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnThingAttacked(obj/thing, mob/living/attacker)
	if(ishuman(attacker) && territory.Contains(get_turf(thing)) && CanSee(thing))
		Warn(attacker)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnThingBroken(obj/thing, mob/living/attacker)
	if(ishuman(attacker) && territory.Contains(get_turf(thing)) && CanSee(thing))
		MarkPerpetrator(attacker)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnUnhookTried(obj/structure/kitchenspike/bunnyman/S, mob/living/carbon/human/rescuer)
	if(CanSee(S))
		Warn(rescuer)

/// Freed in his sight, both are guilty. Freed behind his back, the freed one carries it until he sees them.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnUnhooked(obj/structure/kitchenspike/bunnyman/S, mob/living/carbon/human/rescuer, mob/living/carbon/human/freed)
	if(CanSee(S))
		MarkPerpetrator(rescuer)
		MarkPerpetrator(freed)
		return
	freed.apply_status_effect(/datum/status_effect/bunnyman_mark/paranoid, src)
	to_chat(freed, span_warning("He did not see you come down. You are not sure that helps."))

/// The Paranoid in his sight become what they were afraid of.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SpotParanoid()
	if(!judging || stat == DEAD)
		return
	for(var/mob/living/carbon/human/H in view(src))
		if(!H.has_status_effect(/datum/status_effect/bunnyman_mark/paranoid))
			continue
		H.remove_status_effect(/datum/status_effect/bunnyman_mark/paranoid)
		MarkPerpetrator(H)
		to_chat(H, span_userdanger("He has seen you. He knows where you came down from."))

/// He saw them at his things and said so. Two warnings are kept on it; the third is the Perpetrator mark.
/datum/status_effect/bunnyman_mark/warned
	id = "bunnyman_warned"
	duration = 10 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark/warned
	alert_state = "warned1"
	var/warnings = 1

/atom/movable/screen/alert/status_effect/bunnyman_mark/warned
	name = "Warned"
	desc = "He has seen you at his things, and said so. He will not say it a third time."
	icon_state = "warned1"

/datum/status_effect/bunnyman_mark/warned/proc/AddWarning()
	warnings++
	alert_state = "warned2"
	UpdateAlert(TRUE)
	refresh()

/// Taken off his hook while he was not looking. The first time he sees them, it is the Perpetrator mark.
/datum/status_effect/bunnyman_mark/paranoid
	id = "bunnyman_paranoid"
	duration = 10 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark/paranoid
	alert_state = "paranoid"

/atom/movable/screen/alert/status_effect/bunnyman_mark/paranoid
	name = "Paranoid"
	desc = "You came down off his hook while he was not looking. If he sees you, he will know."
	icon_state = "paranoid"

// The marks. Each mark's alert shows a red background while its owner stands in the territory, the plain one outside.

/// Shared by both marks: the territory they belong to, and the alert swap at its edge.
/datum/status_effect/bunnyman_mark
	id = "bunnyman_mark"
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark
	/// Whose ground this is. Null once he is gone, and the mark then runs out anywhere.
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion
	/// The alert's plain icon state; "_inside" is added while the owner stands on claimed turf.
	var/alert_state = "perpetrator"
	/// Set each tick so the alert only changes when the edge is crossed.
	var/inside = FALSE

/atom/movable/screen/alert/status_effect/bunnyman_mark
	icon = 'ModularLobotomy/_Lobotomyicons/bunnyman_alerts.dmi'
	icon_state = "perpetrator"

/datum/status_effect/bunnyman_mark/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/new_distortion)
	. = ..()
	if(!.)
		return
	if(new_distortion)
		distortion = new_distortion
		RegisterSignal(distortion, COMSIG_PARENT_QDELETING, PROC_REF(OnDistortionDeleted))
	UpdateAlert(TRUE)

/datum/status_effect/bunnyman_mark/on_remove()
	distortion = null
	return ..()

/datum/status_effect/bunnyman_mark/proc/OnDistortionDeleted(datum/source)
	SIGNAL_HANDLER
	distortion = null
	UpdateAlert()

/datum/status_effect/bunnyman_mark/proc/Inside()
	return distortion && distortion.territory && distortion.territory.Contains(get_turf(owner))

/// Swaps the alert between the plain icon and the red one as the owner crosses the territory's edge.
/datum/status_effect/bunnyman_mark/proc/UpdateAlert(force = FALSE)
	var/now_inside = Inside()
	if(!force && now_inside == inside)
		return
	inside = now_inside
	if(linked_alert)
		linked_alert.icon_state = inside ? "[alert_state]_inside" : alert_state

/datum/status_effect/bunnyman_mark/tick()
	UpdateAlert()

/// Drew blood on his ground. He hunts whoever carries this, one at a time. Anyone may hit a Perpetrator freely.
/// It fades after perpetrator_decay spent outside the territory; inside it holds.
/datum/status_effect/bunnyman_mark/perpetrator
	id = "bunnyman_perpetrator"
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark/perpetrator
	alert_state = "perpetrator"
	var/perpetrator_decay = 3 MINUTES
	/// Time spent outside so far, in deciseconds.
	var/outside_time = 0

/atom/movable/screen/alert/status_effect/bunnyman_mark/perpetrator
	name = "Perpetrator"
	desc = "You drew blood on his ground. He has already decided what you are."
	icon_state = "perpetrator"

/datum/status_effect/bunnyman_mark/perpetrator/tick()
	. = ..()
	if(inside)
		outside_time = 0
		return
	outside_time += initial(tick_interval)
	if(outside_time >= perpetrator_decay)
		qdel(src)

/datum/status_effect/bunnyman_mark/perpetrator/on_remove()
	if(distortion)
		distortion.OnPerpetratorCleared(owner)
	return ..()

/// Had blood drawn from them on his ground. A Victim may hit their own Perpetrator without being judged for it.
/datum/status_effect/bunnyman_mark/victim
	id = "bunnyman_victim"
	duration = 1 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark/victim
	alert_state = "victim"
	/// Who struck them. The one target they may strike back at freely.
	var/mob/living/perpetrator
	/// Whether he has already brought them a carrot.
	var/fed = FALSE

/atom/movable/screen/alert/status_effect/bunnyman_mark/victim
	name = "Victim"
	desc = "Something was done to you on his ground. He has taken your side, whether you wanted it or not."
	icon_state = "victim"

/datum/status_effect/bunnyman_mark/victim/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/new_distortion, mob/living/new_perpetrator)
	. = ..()
	if(!.)
		return
	SetPerpetrator(new_perpetrator)

/datum/status_effect/bunnyman_mark/victim/on_remove()
	if(perpetrator)
		UnregisterSignal(perpetrator, COMSIG_PARENT_QDELETING)
		perpetrator = null
	return ..()

/// A Victim keeps the newest person to strike them; the duration restarts with each one.
/datum/status_effect/bunnyman_mark/victim/proc/SetPerpetrator(mob/living/new_perpetrator)
	if(perpetrator)
		UnregisterSignal(perpetrator, COMSIG_PARENT_QDELETING)
	perpetrator = new_perpetrator
	if(perpetrator)
		RegisterSignal(perpetrator, COMSIG_PARENT_QDELETING, PROC_REF(OnPerpetratorDeleted))
	refresh()

/datum/status_effect/bunnyman_mark/victim/proc/OnPerpetratorDeleted(datum/source)
	SIGNAL_HANDLER
	perpetrator = null

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
