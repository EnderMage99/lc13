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
	/// Living mobs on claimed turf with the damage hook on them, so blood drawn on them is seen. Humans also carry the
	/// say hook, so a name said on his ground is heard.
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
	/// "idle", "screaming", "hunting", "preparing", "dashing", "chopping", "dragging", "stunned" while the right
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
	/// Each hook or head that has been hit, to who hit it last, so whoever breaks one is known.
	var/list/last_hit_by = list()
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
	/// On top of the chance, he goes back every den_interval and stays den_stay, longer by den_stay_per_stage each stage.
	var/den_interval = 5 MINUTES
	var/next_den_visit = 0
	var/den_stay = 1.5 MINUTES
	var/den_stay_per_stage = 30 SECONDS
	var/den_until = 0
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
	/// One of each: the report, the ledger, the stock list. SeedNotices() adds a missing poster for each of the killed.
	var/list/notice_kinds = list("report", "ledger", "inventory")
	/// Each missing poster kind, "missing1" and on, to the one of the killed it is about.
	var/list/missing_subjects = list()
	/// How many of each kind are up right now. A kind with none up yet has no entry.
	var/list/notices = list()
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
	/// The hunt ends once the target is further than this from any claimed turf.
	var/hunt_leash = 15
	/// The wait after a hunt ends before the next may start.
	var/hunt_pause = 10 SECONDS
	var/list/hunt_resistances = list(RED_DAMAGE = 0.1, WHITE_DAMAGE = 0.1, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.1)
	/// His resistances outside a hunt: his damage_coeff as spawned, read in Initialize().
	var/list/quiet_resistances
	/// His resistances while his judgement is off: a fair fight.
	var/list/fair_resistances = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.5)
	/// How long the right evidence turns his judgement off. The window for undistorting him.
	var/judgement_off_time = 150 SECONDS
	var/judgement_timer
	/// For the last judgement_warning of the window he flashes red, each flash quicker, from judgement_flash_slowest down.
	var/judgement_warning = 15 SECONDS
	var/judgement_flash_slowest = 1.5 SECONDS
	var/judgement_flash_colour = "#FF2020"
	var/judgement_warning_timer
	/// The wrong evidence stops him this long mid-rush.
	var/stagger_time = 3 SECONDS
	var/staggered_until = 0
	/// The fixers' small stagger, laid over him while he cannot move: staggered by the wrong evidence, or held by the right.
	var/mutable_appearance/stagger_overlay

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	quiet_resistances = unmodified_damage_coeff_datum.getList()
	evidence_kind = pick(evidence_types)
	attacker_name = random_unique_name(pick(MALE, FEMALE))
	RollKilled()
	next_den_visit = world.time + den_interval
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
	var/list/inside = TrackInside()
	HallucinationTick(inside)
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
	StopJudgementTimer()
	HideStagger()
	for(var/mob/living/L in judged)
		UnregisterSignal(L, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_MOB_SAY))
	judged.Cut()
	perpetrators.Cut()
	rabbits.Cut()
	return ..()

// The taboo. Blood drawn on his ground by a human marks them Perpetrator and the one it was drawn from Victim.

/// Returns the living mobs on his ground. Each gets the damage hook while there, humans the say hook too, and both
/// are let go when they leave.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/TrackInside()
	var/list/inside = list()
	for(var/mob/living/L as anything in GLOB.mob_living_list)
		if(L != src && L.z == z && L.stat != DEAD && territory.Contains(get_turf(L)))
			inside += L
	for(var/mob/living/L in inside)
		if(L in judged)
			continue
		RegisterSignal(L, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnBloodDrawn))
		if(ishuman(L))
			RegisterSignal(L, COMSIG_MOB_SAY, PROC_REF(OnSpeech))
		judged += L
	for(var/mob/living/L in judged)
		if(QDELETED(L) || !(L in inside))
			UnregisterSignal(L, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_MOB_SAY))
			judged -= L
	return inside

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

// Hiding. Outside a hunt and the fair fight he cannot be seen. Two tells: his eyes, a pair of red points that move
// with him, and a blood footprint where each step lands, fading in a moment. His tread is heard either way.

/// Unseen, with the eyes out, and walked through like the dark he is in. Only when nothing else is going on:
/// never mid-hunt, never while his judgement is off.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Hide()
	if(hunt_state != "idle" || !judging || stat == DEAD)
		return
	hidden = TRUE
	alpha = 0
	density = FALSE
	if(!eyes)
		eyes = new(loc)
		Own(eyes)

/// Seen. The eyes go; they are his face now.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/Reveal()
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

/// A hook or a head was hit, by hand or by a shot. Who did it is kept for OnThingBroken(); seen, it is a warning.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnThingAttacked(obj/thing, mob/living/attacker)
	if(!isliving(attacker))
		return
	last_hit_by[thing] = attacker
	if(ishuman(attacker) && territory.Contains(get_turf(thing)) && CanSee(thing))
		Warn(attacker)

/// A hook or a head was broken. Whoever hit it last is marked, if he saw.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnThingBroken(obj/thing)
	var/mob/living/attacker = last_hit_by[thing]
	last_hit_by -= thing
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
