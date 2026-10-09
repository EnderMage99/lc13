// Another Day at Work on the advanced base. He stays where he spawned and never attacks anyone; the room does
// it for him. Hitting him is the taboo (Workload), the names on the clue papers are the way through it, and
// his own name, said with all three colours drained, undistorts him. Design and numbers:
// workspace/docs/lc13/distortions/ANOTHER_DAY_DESIGN.md
/mob/living/simple_animal/hostile/distortion/advanced/another_day
	name = "Another Day at Work"
	desc = "A man covered in... ties?"
	icon = 'ModularLobotomy/_Lobotomyicons/48x96.dmi'
	icon_state = "work"
	maxHealth = 900
	health = 900
	pixel_x = -8
	base_pixel_x = -8
	fear_level = TETH_LEVEL
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.15, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.3)
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "brushes against"
	attack_verb_simple = "brush against"
	ranged = FALSE
	ego_list = list(
		/obj/item/ego_weapon/waging,
		/obj/item/clothing/suit/armor/ego_gear/teth/waging,
	)
	egoist_names = list("Paige Turner", "Larry Sal", "Nota Dollar", "Donnar Profit", "Collin Beck")
	gender = MALE
	loot = list(/obj/item/documents/ncorporation)
	monolith_abnormality = /mob/living/simple_animal/hostile/abnormality/black_swan
	wanders = FALSE
	territory_cap = 1000
	territory_stages = list(50, 200, 500)
	// 467 / sqrt(size) a minute: 93 turfs the first tick, 15 at the cap, which arrives after 45 minutes
	territory_growth_rate = 467
	gimmick_stage = 3
	// picked evenly, so a type listed more than once comes up more often: clues are the rare one
	oddities = list(
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/item/paperplane/distortion,
		/obj/item/paperplane/distortion,
		/obj/effect/temp_visual/distortion_oddity/paper_drift/clue,
	)
	var/floor_type = /turf/open/floor/distortion/another_day
	var/wall_type = /turf/closed/indestructible/city/another_day
	/// Turfs the centre has converted, with the type each one was, so Teardown() can put them back.
	var/list/converted = list()
	/// Share of the territory the quilt covers when it first appears, innermost first. It shrinks as the territory grows: see QuiltSize().
	var/quilt_fraction = 0.35
	/// How the quilt keeps up with the territory. 1 would hold the share; 0.5 lets the territory outrun it.
	var/quilt_growth_power = 0.5
	/// The people who made him, role to name: "boss", "coworker", "friend" and "self". Rolled in Initialize().
	var/list/people = list()
	/// Which role each tie colour belongs to. Saying the name drains the colour and turns its effect off.
	var/list/colour_roles = list("red" = "boss", "blue" = "coworker", "yellow" = "friend")
	/// Colours drained right now, colour to the timer that brings it back.
	var/list/drained = list()
	/// The grey overlay on each drained colour.
	var/list/drain_overlays = list()
	var/drain_duration = 60 SECONDS
	var/tie_overlay_icon = 'ModularLobotomy/_Lobotomyicons/another_day_ties.dmi'
	/// Resistances while the friend's name is drained: this many times the base.
	var/drained_resistance_mult = 4
	/// The base resistances, so yellow can be put back exactly.
	var/list/base_resistances = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.15, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.3)
	/// Attacker to the time their next hit counts for the taboo. One gate for Workload and sulking.
	var/list/next_taboo = list()
	var/taboo_cooldown = 2 SECONDS
	var/sulk_damage = 15
	var/sulk_sanity = 2
	var/list/sulk_lines = list(
		"I just want to go home.",
		"Nobody asked me.",
		"It will be done by Monday.",
		"I said I was fine.",
		"Please. Not today.",
	)
	/// Humans with the say signal hooked, so names said in the territory are heard.
	var/list/listening = list()
	/// Speakers whose say is being turned into a whisper right now, so the whisper itself is not turned again.
	var/list/whispering = list()
	/// Clue papers alive, role to list. Capped per role by clues_per_person.
	var/list/clues = list()
	var/clues_per_person = 3
	var/obj/item/clothing/neck/tie/horrible/another_day/name_tie
	/// Airlocks on claimed turfs, kept so the stage 3 door locking never searches the territory.
	var/list/doors = list()
	/// Doors he locked, to the time they may be picked again.
	var/list/locked_doors = list()
	var/door_lock_time = 10 SECONDS
	var/door_lock_cooldown = 60 SECONDS
	var/next_drain = 0
	var/next_door_lock = 0
	var/next_message = 0
	var/list/idle_messages = list(
		"You check the time. It is later than you thought.",
		"Somewhere a keyboard is still going.",
		"You cannot remember what day it is.",
		"The lights hum. They have been humming for a while.",
	)
	var/undistort_timer
	var/undistort_time = 30 SECONDS

/// It does not move at all; it is the place as much as the person.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/Move()
	return FALSE

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Initialize(mapload)
	. = ..()
	for(var/role in list("boss", "coworker", "friend"))
		people[role] = random_unique_name(pick(MALE, FEMALE))
	people["self"] = pick(egoist_names)
	egoist_names = list(people["self"])
	SpawnNameTie()

/// The named tie at the centre. It fades after its lifetime, and the next territory tick puts a new one down.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/SpawnNameTie()
	if(!territory || torn_down)
		return
	name_tie = new(territory.RandomTurf(), people["self"])
	owned += name_tie

/mob/living/simple_animal/hostile/distortion/advanced/another_day/examine(mob/user)
	. = ..()
	. += span_notice("He does not look up.")

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Life()
	. = ..()
	if(stat == DEAD)
		return
	TerritoryTick()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Teardown()
	if(torn_down)
		return
	for(var/turf/T in converted)
		if(istype(T, floor_type) || istype(T, wall_type))
			T.ChangeTurf(converted[T])
	converted.Cut()
	for(var/mob/living/carbon/human/H in listening)
		UnregisterSignal(H, COMSIG_MOB_SAY)
	listening.Cut()
	if(undistort_timer)
		deltimer(undistort_timer)
		undistort_timer = null
	for(var/colour in drained)
		deltimer(drained[colour])
	drained.Cut()
	return ..()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/PostUnmanifest(mob/living/carbon/human/egoist)
	new /obj/item/clothing/neck/tie/horrible(get_turf(src))

// The quilt. The innermost QuiltSize() turfs by walking cost become tie floor, and the walls touching them tie wall.

/// The base hands the centre over by count at stage changes; this one sizes the quilt itself.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/UpdateCenter(new_stage)
	UpdateQuilt()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnTerritoryGrown()
	UpdateQuilt()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnStageChange(old_stage, new_stage)
	if(new_stage >= 3)
		oddities |= /obj/effect/temp_visual/distortion_oddity/shade

/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnTurfClaimed(turf/T)
	for(var/obj/machinery/door/airlock/D in T)
		doors += D

/// Runs after every growth tick from gimmick_stage on, so the quilt fills a room before the door
/// and never crosses a wall the territory did not.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/UpdateQuilt()
	if(!territory || territory.stage < gimmick_stage)
		return
	ApplyCenterEffects(territory.NearestTurfs(QuiltSize()))

/// Turfs the quilt covers: quilt_fraction of the start size, scaled by the territory's growth to the power
/// quilt_growth_power, so it is a third of the territory when it appears and a smaller share the bigger it gets.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/QuiltSize()
	var/growth = territory.Size() / max(1, territory_start_size)
	return max(1, round(quilt_fraction * territory_start_size * (growth ** quilt_growth_power)))

/// Floors in the centre become quilt, and any wall touching a quilt floor becomes quilt wall.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/ApplyCenterEffects(list/turfs)
	for(var/turf/open/floor/T in turfs)
		if(!(T in converted) && !istype(T, floor_type))
			converted[T] = T.type
			T.ChangeTurf(floor_type)
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(!next || (next in converted) || !isclosedturf(next) || istype(next, wall_type))
				continue
			converted[next] = next.type
			next.ChangeTurf(wall_type)

// The taboo. Every way of hitting him lands, then costs the attacker a Workload stack and a sulk.

/mob/living/simple_animal/hostile/distortion/advanced/another_day/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	Taboo(user)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/bullet_act(obj/projectile/P)
	. = ..()
	if(isliving(P.firer))
		Taboo(P.firer)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	. = ..()
	if(throwingdatum && isliving(throwingdatum.thrower))
		Taboo(throwingdatum.thrower)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(M.a_intent == INTENT_HARM)
		Taboo(M)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/attack_animal(mob/living/simple_animal/M, damage)
	. = ..()
	Taboo(M)

/// One gate for everything a hit costs: once per attacker per taboo_cooldown, however fast they swing.
/// Any hit also stops an undistortion in progress.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/Taboo(mob/living/attacker)
	if(!istype(attacker) || attacker == src || stat == DEAD)
		return
	CancelUndistort()
	if(next_taboo[attacker] > world.time)
		return
	next_taboo[attacker] = world.time + taboo_cooldown
	if(!("red" in drained))
		AddWorkload(attacker)
	Sulk(attacker)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/AddWorkload(mob/living/L)
	var/datum/status_effect/stacking/distortion_workload/W = L.has_status_effect(/datum/status_effect/stacking/distortion_workload)
	if(W)
		W.add_stacks(1)
		return
	W = L.apply_status_effect(/datum/status_effect/stacking/distortion_workload, 1)
	if(W)
		W.distortion = src

/// Everyone in the territory hears a line of his. The attacker takes WHITE for it; the rest lose a little sanity, quietly.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/Sulk(mob/living/attacker)
	var/line = pick(sulk_lines)
	for(var/mob/living/carbon/human/H in HumansInside())
		to_chat(H, span_notice("<i>\"[line]\"</i>"))
		if(H != attacker)
			H.adjustSanityLoss(sulk_sanity)
	attacker.deal_damage(sulk_damage, WHITE_DAMAGE, src, null, ATTACK_TYPE_SPECIAL)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/HumansInside()
	var/list/inside = list()
	if(!territory)
		return inside
	for(var/mob/living/carbon/human/H as anything in GLOB.human_list)
		if(H.z == z && H.stat != DEAD && territory.Contains(get_turf(H)))
			inside += H
	return inside

// The names. Said inside the territory they drain a colour from his ties; his own, with all three gone, undistorts him.

/// Hooks the say signal on humans standing in the territory and lets it go when they leave, then runs the stage effects.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/TerritoryTick()
	if(!territory)
		return
	var/list/inside = HumansInside()
	for(var/mob/living/carbon/human/H in inside)
		if(H in listening)
			continue
		RegisterSignal(H, COMSIG_MOB_SAY, PROC_REF(OnSpeech))
		listening += H
	for(var/mob/living/carbon/human/H in listening)
		if(QDELETED(H) || !(H in inside))
			UnregisterSignal(H, COMSIG_MOB_SAY)
			listening -= H
	PassiveEffects(inside)
	if(QDELETED(name_tie))
		SpawnNameTie()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/OnSpeech(mob/living/carbon/human/speaker, list/speech_args)
	SIGNAL_HANDLER
	var/message = speech_args[SPEECH_MESSAGE]
	if(!message || (speaker in whispering))
		return
	for(var/colour in colour_roles)
		if(findtext(message, people[colour_roles[colour]]))
			DrainColour(colour, speaker)
	if(findtext(message, people["self"]))
		HearOwnName(speaker)
	if(territory.stage < 4 || !PresenceActive())
		return
	// stage 4: the say is dropped and sent again as a whisper; the guard lets the whisper's own say signal through
	speech_args[SPEECH_MESSAGE] = ""
	whispering += speaker
	INVOKE_ASYNC(speaker, TYPE_PROC_REF(/mob/living, whisper), message, null, speech_args[SPEECH_SPANS], TRUE, speech_args[SPEECH_LANGUAGE])
	whispering -= speaker

/// The colour leaves his ties for drain_duration and whatever it stood for stops with it.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/DrainColour(colour, mob/living/carbon/human/speaker)
	speaker.Shake(3, 3, 1.5 SECONDS)
	to_chat(speaker, span_nicegreen("Something in this place flinches at that name."))
	if(colour in drained)
		deltimer(drained[colour])
	else
		var/mutable_appearance/MA = mutable_appearance(tie_overlay_icon, colour)
		drain_overlays[colour] = MA
		add_overlay(MA)
		ApplyColour(colour, FALSE)
	drained[colour] = addtimer(CALLBACK(src, PROC_REF(RestoreColour), colour), drain_duration, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/RestoreColour(colour)
	if(!(colour in drained))
		return
	drained -= colour
	cut_overlay(drain_overlays[colour])
	drain_overlays -= colour
	ApplyColour(colour, TRUE)

/// What a colour does while it is there. Red is the taboo and needs nothing here: Taboo() reads drained itself.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/ApplyColour(colour, present)
	switch(colour)
		if("blue")
			if(territory)
				territory.paused = !present || undistort_timer
		if("yellow")
			var/list/resist = list()
			for(var/type in base_resistances)
				resist[type] = base_resistances[type] * (present ? 1 : drained_resistance_mult)
			ChangeResistances(resist)

/// Whether the territory's own effects are running: off while the co-worker's name holds or he is undistorting.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/PresenceActive()
	return !("blue" in drained) && !undistort_timer

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/HearOwnName(mob/living/carbon/human/speaker)
	if(undistort_timer)
		return
	if(drained.len < colour_roles.len)
		to_chat(speaker, span_nicegreen("You were close. Other voices are drowning yours out."))
		return
	if(!(src in view(speaker)))
		to_chat(speaker, span_nicegreen("You need to be heard more clearly."))
		return
	StartUndistorting(speaker)

/// The colours stay gone for the whole undistort_time; a hit before it ends cancels it and brings them all back.
/// The colours all come back at once, and light breaks out of him: rays that grow and turn for undistort_time.
/// A hit before it ends cancels it and the rays go out.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/StartUndistorting(mob/living/carbon/human/speaker)
	for(var/colour in drained.Copy())
		RestoreColour(colour)
	if(territory)
		territory.paused = TRUE
	visible_message(span_notice("The ties go slack, one after another, and something behind them starts to shine."))
	to_chat(speaker, span_nicegreen("He looks up."))
	add_filter("undistort", 1, rays_filter(size = 4, color = "#FFF1B8", offset = 0, density = 10, threshold = 0.15))
	transition_filter("undistort", undistort_time, list(size = 120, offset = 90), SINE_EASING | EASE_IN)
	undistort_timer = addtimer(CALLBACK(src, PROC_REF(Undistort)), undistort_time, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/CancelUndistort()
	if(!undistort_timer)
		return
	deltimer(undistort_timer)
	undistort_timer = null
	remove_filter("undistort")
	if(territory)
		territory.paused = FALSE
	visible_message(span_warning("The light goes out. The ties pull tight again."))

/// The base Unmanifest() releases the stored human alive with the EGO, so the usual death cleanup never sees them.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/Undistort()
	undistort_timer = null
	if(QDELETED(src) || stat == DEAD)
		return
	Unmanifest()

// The passive territory. From stage 3 the rooms drain sanity, lock their doors and say things; stage 4 does it faster.

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/PassiveEffects(list/inside)
	if(territory.stage < 3 || !PresenceActive())
		return
	var/fast = territory.stage >= 4
	if(world.time >= next_drain)
		next_drain = world.time + (fast ? 3 SECONDS : 10 SECONDS)
		for(var/mob/living/carbon/human/H in inside)
			H.adjustSanityLoss(1)
	if(world.time >= next_door_lock)
		next_door_lock = world.time + (fast ? 10 SECONDS : 30 SECONDS)
		LockRandomDoor()
	if(inside.len && world.time >= next_message)
		next_message = world.time + (fast ? 20 SECONDS : 60 SECONDS)
		var/mob/living/carbon/human/H = pick(inside)
		to_chat(H, span_notice(pick(idle_messages)))

/// Bolts one airlock in the territory for door_lock_time. A door he bolted waits door_lock_cooldown before it can be
/// picked again, and a door someone else bolted is left alone.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/LockRandomDoor()
	var/list/candidates = list()
	for(var/obj/machinery/door/airlock/D in doors.Copy())
		if(QDELETED(D))
			doors -= D
			continue
		if(D.locked || locked_doors[D] > world.time)
			continue
		candidates += D
	if(!candidates.len)
		return
	var/obj/machinery/door/airlock/D = pick(candidates)
	D.bolt()
	locked_doors[D] = world.time + door_lock_cooldown
	addtimer(CALLBACK(D, TYPE_PROC_REF(/obj/machinery/door/airlock, unbolt)), door_lock_time)

// Clues. The oddities carry them: a plane sometimes folds around one, and one kind of drifting page settles as one.

/// A role that still has room for another clue lying in the territory, or null.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/ClueRole()
	var/list/open = list()
	for(var/role in list("boss", "coworker", "friend"))
		var/count = 0
		for(var/obj/item/paper/distortion/clue/C in clues[role])
			if(QDELETED(C))
				LAZYREMOVE(clues[role], C)
				continue
			if(isturf(C.loc) && territory?.Contains(C.loc))
				count++
		if(count < clues_per_person)
			open += role
	if(!open.len)
		return null
	return pick(open)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/RegisterClue(obj/item/paper/distortion/clue/C, role)
	LAZYADD(clues[role], C)
	owned += C

// Workload. The stacking status effect the taboo hands out. Stacks only decay outside the territory.

/datum/status_effect/stacking/distortion_workload
	id = "distortion_workload"
	alert_type = /atom/movable/screen/alert/status_effect/distortion_workload
	max_stacks = 6
	stack_threshold = 6
	consumed_on_threshold = FALSE
	tick_interval = 1 SECONDS
	overlay_file = 'ModularLobotomy/_Lobotomyicons/another_day_workload.dmi'
	overlay_state = "workload_"
	/// Whose territory holds the stacks. Decay only happens outside it.
	var/mob/living/simple_animal/hostile/distortion/advanced/another_day/distortion
	var/decay_interval = 20 SECONDS
	var/next_decay = 0
	var/sleep_time = 3 SECONDS
	var/asleep_until = 0
	/// Blur creeps up one point a tick toward this many points per stack past the first.
	var/blur_per_stack = 2
	/// The wearer's silhouette per direction, made on first use and thrown away every mask_refresh so a dropped
	/// item or a change of clothes shows up without flattening the sprite on every turn.
	var/list/masks = list()
	var/mask_refresh = 5 SECONDS
	var/next_mask_refresh = 0

/atom/movable/screen/alert/status_effect/distortion_workload
	name = "Workload"
	desc = "It is piling up. You could put it down if you stepped away."
	icon = 'ModularLobotomy/_Lobotomyicons/another_day_workload.dmi'
	icon_state = "alert"

/datum/status_effect/stacking/distortion_workload/on_apply()
	. = ..()
	if(!.)
		return
	next_decay = world.time + decay_interval
	RegisterSignal(owner, COMSIG_ATOM_DIR_CHANGE, PROC_REF(OnDirChange))
	RebuildOverlay()

/datum/status_effect/stacking/distortion_workload/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/distortion_workload)
	return ..()

/datum/status_effect/stacking/distortion_workload/can_gain_stacks()
	return ..() && world.time >= asleep_until

/datum/status_effect/stacking/distortion_workload/add_stacks(stacks_added)
	var/before = stacks
	. = ..()
	if(QDELETED(src))
		return
	if(stacks > before)
		switch(stacks)
			if(1)
				to_chat(owner, span_warning("A tie coils around your wrist and lets go. Your arms feel heavy."))
			if(2)
				to_chat(owner, span_warning("You can't remember the last time you slept."))
			if(3)
				to_chat(owner, span_warning("The weight of it settles on your shoulders."))
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/distortion_workload, multiplicative_slowdown = max(0, stacks - 2) * 0.5)
	RebuildOverlay()

/// Blur holds while the stacks do; a stack falls off every decay_interval, but only outside the territory.
/datum/status_effect/stacking/distortion_workload/tick()
	if(!can_have_status())
		qdel(src)
		return
	if(stacks >= 2 && world.time >= asleep_until && owner.eye_blurry < (stacks - 1) * blur_per_stack)
		owner.adjust_blurriness(1)
	if(world.time >= next_mask_refresh)
		next_mask_refresh = world.time + mask_refresh
		masks.Cut()
		RebuildOverlay()
	if(world.time < next_decay)
		return
	next_decay = world.time + decay_interval
	if(distortion?.territory?.Contains(get_turf(owner)))
		return
	add_stacks(-1)

/// Six stacks: asleep for sleep_time, no stacks gained meanwhile, then back down to three.
/datum/status_effect/stacking/distortion_workload/threshold_cross_effect()
	to_chat(owner, span_userdanger("You sit down for a moment. Just a moment."))
	asleep_until = world.time + sleep_time
	owner.Sleeping(sleep_time)
	addtimer(CALLBACK(src, PROC_REF(WakeUp)), sleep_time)

/datum/status_effect/stacking/distortion_workload/proc/WakeUp()
	if(QDELETED(src))
		return
	add_stacks(3 - stacks)

/datum/status_effect/stacking/distortion_workload/proc/OnDirChange(atom/movable/source, olddir, newdir)
	SIGNAL_HANDLER
	RebuildOverlay(newdir)

/// The ties only on the body: the wearer's flattened sprite for the direction is the alpha mask over the stack's
/// state. Flattening is the slow part, so each direction's mask is kept once it has been made.
/datum/status_effect/stacking/distortion_workload/proc/RebuildOverlay(dir = owner.dir)
	owner.cut_overlay(status_overlay)
	if(!masks["[dir]"])
		masks["[dir]"] = getFlatIcon(owner, dir, no_anim = TRUE)
	var/icon/ties = icon(overlay_file, "[overlay_state][stacks]")
	ties.AddAlphaMask(masks["[dir]"])
	status_overlay = mutable_appearance(ties)
	status_overlay.pixel_x = -owner.pixel_x
	owner.add_overlay(status_overlay)

/datum/movespeed_modifier/distortion_workload
	multiplicative_slowdown = 0
	variable = TRUE

// Oddities. Paper, all of it; two of them carry the clues.

/// A single written page flies in from one side, loses its speed, and settles slowly to the floor, swaying as it falls.
/obj/effect/temp_visual/distortion_oddity/paper_drift
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	alpha = 220
	duration = 4.5 SECONDS

/obj/effect/temp_visual/distortion_oddity/paper_drift/Initialize(mapload)
	. = ..()
	var/from = pick(-1, 1)
	pixel_x = from * 56
	pixel_y = 28
	var/sway = -from * 8
	animate(src, pixel_x = from * 12, pixel_y = 34, time = duration * 0.3, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = from * 12 + sway, pixel_y = 22, time = duration * 0.25, easing = SINE_EASING)
	animate(pixel_x = from * 12 - sway, pixel_y = 10, time = duration * 0.25, easing = SINE_EASING)
	animate(pixel_x = from * 12, pixel_y = 0, alpha = 0, time = duration * 0.2)

/// The same drift, but the page is real: it does not fade at the floor, it becomes the clue where it lands.
/obj/effect/temp_visual/distortion_oddity/paper_drift/clue
	icon_state = "paper_words"
	var/mob/living/simple_animal/hostile/distortion/advanced/another_day/owner
	var/role
	/// Which side it came in from, so the page is put down exactly where the effect ends.
	var/from

/obj/effect/temp_visual/distortion_oddity/paper_drift/clue/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/another_day/new_owner)
	. = ..()
	role = istype(new_owner) ? new_owner.ClueRole() : null
	if(!role)
		new /obj/effect/temp_visual/distortion_oddity/paper_drift(loc)
		return INITIALIZE_HINT_QDEL
	owner = new_owner
	from = pixel_x > 0 ? 1 : -1
	var/sway = -from * 8
	animate(src, pixel_x = from * 12, pixel_y = 34, time = duration * 0.3, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = from * 12 + sway, pixel_y = 22, time = duration * 0.25, easing = SINE_EASING)
	animate(pixel_x = from * 12 - sway, pixel_y = 10, time = duration * 0.25, easing = SINE_EASING)
	animate(pixel_x = from * 12, pixel_y = 0, time = duration * 0.2, easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(Settle)), duration - 1)

/// Swaps the effect for the page in the same spot, so nothing jumps.
/obj/effect/temp_visual/distortion_oddity/paper_drift/clue/proc/Settle()
	if(QDELETED(src) || QDELETED(owner) || !isturf(loc))
		return
	var/obj/item/paper/distortion/clue/page = new(loc, owner, role)
	page.pixel_x = from * 12
	page.pixel_y = 0
	page.alpha = alpha
	qdel(src)

/obj/effect/temp_visual/distortion_oddity/paper_drift/clue/Destroy()
	owner = null
	return ..()

/// A paper plane that fades in out of the sky, already turned toward a far turf it can see, swaying as it comes
/// down, then glides there slowly, or drops where it is if nothing is in view. It fades out a while after landing.
/// Some carry a clue page instead of the blank.
/obj/item/paperplane/distortion
	alpha = 0
	hit_probability = 0
	/// Time spent fading in above the ground before it is thrown.
	var/fade_in = 4.5 SECONDS
	/// How long it lies where it landed before fading away.
	var/linger = 10 SECONDS
	/// Tiles per tick while thrown: 0.2 is one tile every half second.
	var/glide_speed = 0.2
	var/min_throw = 4
	var/max_throw = 7
	var/clue_chance = 10
	/// Where it will be thrown, chosen on spawn so it can face that way while fading in. Null means it just drops.
	var/turf/target_turf

/obj/item/paperplane/distortion/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/another_day/owner)
	var/obj/item/paper/distortion/page
	var/role = (istype(owner) && prob(clue_chance)) ? owner.ClueRole() : null
	if(role)
		page = new /obj/item/paper/distortion/clue(loc, owner, role)
	else
		page = new /obj/item/paper/distortion(loc)
	. = ..(mapload, page)
	target_turf = PickTarget()
	if(target_turf)
		setDir(get_cardinal_dir(src, target_turf))
	var/sway = pick(-8, 8)
	pixel_y = 36
	animate(src, alpha = 255, pixel_x = sway, pixel_y = 28, time = fade_in * 0.3, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = -sway, pixel_y = 20, time = fade_in * 0.25, easing = SINE_EASING)
	animate(pixel_x = sway, pixel_y = 14, time = fade_in * 0.25, easing = SINE_EASING)
	animate(pixel_x = 0, pixel_y = 10, time = fade_in * 0.2, easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(Launch)), fade_in)

/// A random visible open turf between min_throw and max_throw away, or null.
/obj/item/paperplane/distortion/proc/PickTarget()
	var/list/far = list()
	for(var/turf/open/T in view(max_throw, src))
		if(get_dist(src, T) >= min_throw)
			far += T
	if(!far.len)
		return null
	return pick(far)

/// Throws at the chosen turf, or drops straight down if there was none.
/obj/item/paperplane/distortion/proc/Launch()
	if(QDELETED(src) || !isturf(loc))
		return
	if(!target_turf)
		animate(src, pixel_y = 0, time = 1 SECONDS, easing = SINE_EASING | EASE_IN)
		addtimer(CALLBACK(src, PROC_REF(Landed)), 1 SECONDS)
		return
	throw_at(target_turf, get_dist(src, target_turf), glide_speed, callback = CALLBACK(src, PROC_REF(Landed)))

/// Settles to the floor and fades out over linger, then is gone. Picking it up before that still lets it fade.
/obj/item/paperplane/distortion/proc/Landed()
	if(QDELETED(src))
		return
	animate(src, pixel_y = 0, alpha = 0, time = linger)
	QDEL_IN(src, linger)

/// Unfolding sets the page fading on its own; the parent then deletes the empty plane.
/obj/item/paperplane/distortion/Exited(atom/movable/AM, atom/newLoc)
	if(AM == internalPaper)
		var/obj/item/paper/distortion/page = AM
		page.StartFading()
	return ..()

/// The page inside a plain plane. Once unfolded it fades away over linger and cannot be folded into anything again.
/obj/item/paper/distortion
	name = "limp page"
	desc = "A sheet of paper, damp and soft as cloth. Whatever was written on it has run."
	var/linger = 10 SECONDS

/obj/item/paper/distortion/proc/StartFading()
	animate(src, alpha = 0, time = linger)
	QDEL_IN(src, linger)

/obj/item/paper/distortion/examine(mob/user)
	. = ..()
	. -= "<span class='notice'>Alt-click [src] to fold it into a paper plane.</span>"
	. += span_notice("It is far too limp to hold a fold.")

/obj/item/paper/distortion/AltClick(mob/living/user, obj/item/I)
	if(!user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, FALSE, TRUE))
		return
	to_chat(user, span_warning("[src] sags in your hands. It will not hold a fold."))

// The quilt's turfs.

/// Each quilt tile picks one of the four variants so the patch does not repeat. The mapped "another_day"
/// state is left for the District 4 ruin.
/turf/open/floor/distortion/another_day/Initialize(mapload)
	. = ..()
	icon_state = pick("another_day1", "another_day2", "another_day3", "another_day4")

/// The quilt wall: the floor hung up. Smooths with the other city walls.
/turf/closed/indestructible/city/another_day
	name = "quilted wall"
	desc = "Ties, hundreds of them, stitched edge to edge and hung over whatever was here before."
	icon = 'icons/turf/walls/city_another_day.dmi'
	icon_state = "another_day-0"
	base_icon_state = "another_day"

// The clue documents. The tie with his name on it, the page that carries a clue, and the texts the names are written into.

/// The tie left on the chair at the centre: the one thing the quilt never covers, and the only place his name is written.
/obj/item/clothing/neck/tie/horrible/another_day
	desc = "A neosilk clip-on tie. This one is disgusting. There is a name on the label."
	/// How long it lasts before fading. While someone has it, it checks again every recheck until it is put down.
	var/lifetime = 3 MINUTES
	var/recheck = 30 SECONDS
	var/fade_time = 10 SECONDS

/// Arrives the way the pages do: in from one side, swaying down to the floor.
/obj/item/clothing/neck/tie/horrible/another_day/Initialize(mapload, who)
	. = ..()
	desc = "A neosilk clip-on tie. This one is disgusting. The label reads: [who]."
	addtimer(CALLBACK(src, PROC_REF(Expire)), lifetime)
	var/from = pick(-1, 1)
	var/sway = -from * 8
	alpha = 0
	pixel_x = from * 56
	pixel_y = 28
	animate(src, alpha = 255, pixel_x = from * 12, pixel_y = 34, time = 1.35 SECONDS, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = from * 12 + sway, pixel_y = 22, time = 1.1 SECONDS, easing = SINE_EASING)
	animate(pixel_x = from * 12 - sway, pixel_y = 10, time = 1.1 SECONDS, easing = SINE_EASING)
	animate(pixel_x = 0, pixel_y = 0, time = 0.9 SECONDS, easing = SINE_EASING | EASE_IN)

/// Fades once it is lying on a turf; while someone has it, it checks again every recheck.
/obj/item/clothing/neck/tie/horrible/another_day/proc/Expire()
	if(QDELETED(src))
		return
	if(!isturf(loc))
		addtimer(CALLBACK(src, PROC_REF(Expire)), recheck)
		return
	animate(src, alpha = 0, time = fade_time)
	QDEL_IN(src, fade_time)

/// A page that names one of his people. Unfolding does not fade it and it will not fold, but like everything
/// else he puts out it goes on its own: it pales over its lifetime, then vanishes once it is lying on the floor.
/obj/item/paper/distortion/clue
	name = "page"
	desc = "A sheet of office paper, soft at the edges. Something is written on it."
	var/lifetime = 3 MINUTES
	var/recheck = 30 SECONDS

/obj/item/paper/distortion/clue/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/another_day/owner, role)
	. = ..()
	if(!istype(owner) || !role)
		return
	var/list/options = owner.ClueTemplates()[role]
	var/list/doc = pick(options)
	name = doc[1]
	var/text = doc[2]
	text = replacetext(text, "%BOSS%", owner.people["boss"])
	text = replacetext(text, "%COWORKER%", owner.people["coworker"])
	text = replacetext(text, "%FRIEND%", owner.people["friend"])
	setText(text)
	owner.RegisterClue(src, role)
	animate(src, alpha = 40, time = lifetime)
	addtimer(CALLBACK(src, PROC_REF(Expire)), lifetime)

/obj/item/paper/distortion/clue/StartFading()
	return

/// Fades once it is lying on a turf; while someone has it, it checks again every recheck.
/obj/item/paper/distortion/clue/proc/Expire()
	if(QDELETED(src))
		return
	if(!isturf(loc))
		addtimer(CALLBACK(src, PROC_REF(Expire)), recheck)
		return
	animate(src, alpha = 0, time = linger)
	QDEL_IN(src, linger)

/// The documents, role to a list of list(title, text). The names are filled in by the clue paper. Styled the way
/// the printed forms in the game are, so they read as paperwork and not as a note.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/ClueTemplates()
	var/head = "<table bgcolor='#2b2b33' width=100%><tr><td width=100%><font size=4 face='Times New Roman' color='#c9b36a'><div align=center><b>"
	var/head_end = "</b></div></font></td></tr></table><hr size=2>"
	var/body = "<font size=2 face='Times New Roman'>"
	var/small = "<font size=1 face='Times New Roman'>"
	var/mono = "<font size=2 face='Courier New'>"
	var/pen = "<font size=2 face='Comic Sans MS' color='#1b2f6b'><i>"
	var/pen_end = "</i></font>"
	return list(
		"boss" = list(
			list("quarterly performance review",
				"[head]HUMAN RESOURCES<br><font size=2>Quarterly Performance Review</font>[head_end]\
				[body]<b>Employee:</b> you<br><b>Reviewer:</b> %BOSS%<br><b>Period:</b> Q3<hr size=1>\
				<b>Summary</b><br>[small]Meets expectations. Takes on additional work without complaint. Stayed on for the Q3 close when the rest of the team rolled off. Recommend expanded responsibilities at no change in grade.</font><br><br>\
				<b>Notes</b><br>[small]No leave taken this year. Please address.</font><hr size=1>\
				<div align=right>[small]Signed, %BOSS%</font></div></font>"),
			list("memo",
				"[head]INTERNAL MEMORANDUM[head_end]\
				[body]<b>To:</b> you<br><b>From:</b> %BOSS%<br><b>Re:</b> Tonight<hr size=1>\
				See me before you go home.<br><br><br>\
				<font color='#7a1f1f'>[pen]did not go home[pen_end]</font><br>[small]<i>(pressed hard enough to tear the page)</i></font></font>"),
			list("overtime sheet",
				"[head]OVERTIME AUTHORISATION[head_end]\
				[body]<b>Employee:</b> you<br><b>Week ending:</b> last week<hr size=1>\
				<table width=100% border=1 cellpadding=2>[mono]<tr><td>Mon</td><td>Tue</td><td>Wed</td><td>Thu</td><td>Fri</td><td>Sat</td><td>Sun</td></tr>\
				<tr><td>4.0</td><td>3.5</td><td>5.0</td><td>4.5</td><td>6.0</td><td>8.0</td><td>3.0</td></tr></font></table><br>\
				<b>Approved:</b> %BOSS%<br><b>Reason:</b> as discussed</font>"),
		),
		"coworker" = list(
			list("printed email",
				"<table bgcolor='#e4e4e4' width=100%><tr><td>[mono]<b>From:</b> %BOSS%<br><b>To:</b> All staff<br><b>Subject:</b> Congratulations</font></td></tr></table><hr size=1>\
				[body]Please join me in congratulating %COWORKER% on the promotion to team lead.<br><br>The restructuring proposal was exactly the initiative this department needed, and it is good to see it recognised.<br><br>Regards,<br>%BOSS%</font>"),
			list("proposal cover page",
				"<br><br><font size=5 face='Times New Roman'><div align=center><b>RESTRUCTURING PROPOSAL</b></div></font>\
				<font size=2 face='Times New Roman'><div align=center>Draft 4</div></font><br><br><hr size=2>\
				[body]<div align=center>Prepared by: <font color='#555555'>&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;&#9608;</font> [small]<i>(scratched out, pressed through the page)</i></font><br>\
				Prepared by: %COWORKER%</div><br><br>[small]<div align=center>Attached: 31 pages. You can tell where the staples used to be.</div></font></font>"),
			list("sticky note",
				"<table bgcolor='#f2e27a' width=100%><tr><td>[pen]Can you cover my shift again Thursday? Something came up.<br>I'll make it up to you, promise.<br><br>- %COWORKER%[pen_end]</td></tr></table><br>\
				[small]<i>(the back has eleven tally marks)</i></font>"),
		),
		"friend" = list(
			list("phone log",
				"<table bgcolor='#1d1d22' width=100%><tr><td>[mono]<font color='#d8d8d8'><b>MISSED CALLS</b><hr size=1>\
				%FRIEND%&nbsp;&nbsp;Tue 19:12<br>%FRIEND%&nbsp;&nbsp;Tue 21:40<br>%FRIEND%&nbsp;&nbsp;Wed 08:03<br>%FRIEND%&nbsp;&nbsp;Fri 18:55<br>%FRIEND%&nbsp;&nbsp;Fri 18:57<br>%FRIEND%&nbsp;&nbsp;Sat 12:30<br>%FRIEND%&nbsp;&nbsp;Sun 22:14<hr size=1>\
				Call back: <i>(nothing)</i></font></font></td></tr></table>"),
			list("birthday card",
				"<table bgcolor='#f6e6ee' width=100%><tr><td><font size=4 face='Times New Roman' color='#8a3b5c'><div align=center><i>Happy Birthday</i></div></font><hr size=1>\
				[pen]To %FRIEND%,<br><br>Happy birthday. I know I missed it. I know I missed the last one. Work has been[pen_end]<br><br>\
				[small]<i>(it stops there. The envelope is addressed and has no stamp.)</i></font></td></tr></table>"),
			list("chat log",
				"[mono]<table width=100% cellpadding=2>\
				<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> are you coming tonight</td></tr>\
				<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> everyone's asking</td></tr>\
				<tr><td bgcolor='#e9e9e9' align=right><b>you:</b> sorry. work.</td></tr>\
				<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> it's always work</td></tr>\
				<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> hello?</td></tr>\
				<tr><td bgcolor='#dfe8f5'><b>%FRIEND%:</b> ok</td></tr></table></font>"),
		),
	)

