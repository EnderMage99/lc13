// Door to Nowhere on the LCL base. Speaks only in whispers, seals corpses into the Realm of
// Sealed Regrets, and projects into the Realm as an invisible spirit that can furnish it.
// Its diet is the Realm's own artefacts only, and both bars feed the counter pump below.

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere
	true_name = "Door to Nowhere"
	original_abno = /mob/living/simple_animal/hostile/abnormality/door_to_nowhere
	maxHealth = 1500
	health = 1500
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 8
	melee_damage_upper = 12
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "crashes into"
	attack_verb_simple = "crash into"
	attack_sound = 'sound/weapons/genhit1.ogg'
	ranged = TRUE
	ranged_cooldown_time = 5 SECONDS
	projectiletype = /obj/projectile/dtn_hand
	projectilesound = 'sound/effects/curse3.ogg'
	//Per-food values live in dtn_diet; diet_list only feeds the base's Login readout.
	diet_list = list(
		/obj/item/regret_key,
		/obj/item/tape/mirror_shattered,
		/obj/item/taperecorder,
		/obj/item/photo,
	)
	diet_value = 0
	desire_on_eat = 0
	delete_food = FALSE //Belt and braces; the override decides per item whether to seal or swallow.
	insight_cooldown_time = 1 MINUTES
	liked_objects_list = list(/obj/item/taperecorder, /obj/item/tape, /obj/item/paper, /obj/item/photo)
	liked_objects_value = 4 //Insight - favoured.
	hated_objects_list = list(/obj/structure/mirror, /obj/machinery/camera) //Things that show you yourself.
	hated_objects_value = 4
	desire_on_pet = 5 //Attachment - weak.
	rep_desire_gain = 0.5 //Repression - actively disliked.
	rep_desire_loss_at_threshold = 40
	rep_threshold = 300
	rep_min_damage = 5
	desire_on_talk = 2 //It feeds a little on things said near it.
	hunger_cooldown_time = 3 MINUTES
	max_counter = 3
	attunement_family = "liminal"
	ego_list = list(/datum/ego_datum/armor/lce/liminal)
	//Body only. The spirit grants its own set on spawn.
	attack_action_types = list(
		/datum/action/cooldown/dtn_action/whisper,
		/datum/action/cooldown/dtn_action/project,
		/datum/action/cooldown/dtn_action/disgorge,
	)
	abno_additional_instructions = "You are a door, and doors are for keeping things. You cannot speak aloud - only whisper into people's heads. \
		Ordinary food is nothing to you: you hunger only for what your own Realm makes - its photographs, its recordings, and above all the key that is \
		only forged when someone has faced every regret behind you. You are fed by people walking around inside you. Strike a corpse and you will take it \
		there, and it will walk again - so long as it never leaves. Everything you feel turns into how tightly you are shut: fill yourself and another \
		lock catches, run empty and one gives way. When the last one goes you may open, if you choose to. Nothing stays locked forever - but you can try."

	// --- Sealed Burial ---
	///mob -> world.time it was sealed at.
	var/list/sealed = list()
	///ckey -> world.time its recapture immunity lapses.
	var/list/recapture_immune = list()
	var/seal_time = 5 SECONDS
	///Breached only: taking a living human, long enough to be interrupted.
	var/breach_seal_time = 9 SECONDS
	var/recapture_immunity = 10 MINUTES
	///Set while breached. Sealed Burial stops needing a corpse.
	var/seal_living = FALSE

	// --- Swallowed (non-diet) items ---
	var/list/swallowed = list()
	var/max_swallowed = 20

	// --- The spirit ---
	var/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/spirit = null
	///Guard: mind.transfer_to() fires the spirit's Logout(), which recalls.
	var/recalling_spirit = FALSE

	// --- Hunger pause ---
	var/satiated = FALSE
	///hunger_active before the pause, so EndSate cannot start the drain early.
	var/hunger_was_active = FALSE

	// --- Willing entry ---
	///ckey -> world.time before which walking in again earns nothing.
	var/list/willing_reward_cooldown = list()
	var/willing_reward_cooldown_time = 5 MINUTES
	var/willing_entry_time = 5 SECONDS

	// --- The Realm feeding loop ---
	var/realm_cooldown = 0
	var/realm_cooldown_time = 30 SECONDS
	var/occupancy_desire = 3
	var/occupancy_cap = 3
	var/realm_affinity = 2

	// --- The counter pump ---
	///Guard shared by both bars.
	var/pumping = FALSE

	// --- Breach ---
	///TRUE while the breach is offered. It never breaches on its own.
	var/breach_ready = FALSE
	var/breached = FALSE
	var/breach_break_health = 100
	///Twice as tough while breached, i.e. HALVED incoming multipliers.
	var/list/breached_resistances = list(RED_DAMAGE = 0.75, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1)
	var/list/unbreached_resistances = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)

	///Dedupes the Realm speech relay across captives in shared earshot.
	var/last_relay_time = 0
	var/last_relay_text = ""

	///Per-food values, which the base's single diet_value cannot express. Most specific type
	///first: DietEntryFor() matches with istype.
	var/static/list/dtn_diet = list(
		/obj/item/regret_key = list("hunger" = 100, "desire" = 100, "sate" = 7 MINUTES),
		/obj/item/tape/mirror_shattered = list("hunger" = 50, "desire" = 50),
		/obj/item/taperecorder = list("hunger" = 8, "desire" = 8),
		/obj/item/photo = list("hunger" = 8, "desire" = 8),
	)

	///Never swallowed, so the round cannot lose these to it.
	var/static/list/dtn_swallow_blacklist = typecacheof(list(
		/obj/item/disk/nuclear,
		/obj/item/documents,
		/obj/item/nuke_core,
		/obj/item/regret_key,
	))

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/Initialize(mapload)
	. = ..()
	InitializeRepentanceLocations() //Harmless if the WAW abno already did it.

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/Destroy()
	RecallSpirit(TRUE)
	ReleaseAllSealed()
	DumpSwallowed(get_turf(src))
	return ..()

//istype instead of the base's exact-type is_path_in_list; every liked/hated type has subtypes.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/InsightRoomCheck()
	var/room_score = 0
	var/list/room_obj_list = list()
	for(var/obj/O in view(5, src))
		room_obj_list += O
		if(is_type_in_list(O, liked_objects_list))
			room_score += liked_objects_value
		if(is_type_in_list(O, hated_objects_list))
			room_score -= hated_objects_value
	InsightRoomResults(room_score, room_obj_list)

// ============================ SPEECH ============================

//Whispers to view 7 instead of speaking. No parent call, so nothing reaches radio or say.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!message)
		return
	for(var/mob/M in get_hearers_in_view(7, src))
		if(!M.client)
			continue
		to_chat(M, DTNWhisperText("You hear a cold whisper echoing from [src]... \"[message]\""))
	RelayWhisperToGhosts(src, message)
	log_say("[key_name(src)] (LCL Door to Nowhere) whispers: [message]")
	manual_emote("'s chains rattle softly...")
	return

//Relays Realm speech to the body, whispers excluded. Registered on each sealed captive.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/RelayRealmSpeech(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	if(spirit) //The player is down there in person; no need to echo it to an empty body.
		return
	var/list/mods = hearing_args[7]
	if(islist(mods) && mods[WHISPER_MODE])
		return //A whisper inside the Realm is not for the door.
	var/raw = hearing_args[HEARING_RAW_MESSAGE]
	if(!raw)
		return
	var/atom/movable/speaker = hearing_args[HEARING_SPEAKER]
	if(last_relay_time == world.time && last_relay_text == "[speaker]:[raw]")
		return
	last_relay_time = world.time
	last_relay_text = "[speaker]:[raw]"
	to_chat(src, "[DTNWhisperText("\[SEALED\]", TRUE)] [DTNWhisperText("[speaker]: \"[raw]\"")]")

// ============================ RANGED: THE BURST ============================

//Fires three hands on a stagger. Only the lead one stacks regret - see /obj/projectile/dtn_hand.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/OpenFire(atom/A)
	if(QDELETED(src) || stat >= DEAD || !A)
		return
	if(ranged_cooldown > world.time)
		return
	visible_message(span_danger("[src]'s chains rattle as spectral hands emerge!"))
	for(var/i in 1 to 3)
		addtimer(CALLBACK(src, PROC_REF(FireRegretHand), A, i == 1), (i - 1) * 2)
	ranged_cooldown = world.time + ranged_cooldown_time

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/FireRegretHand(atom/A, stacking = FALSE)
	if(QDELETED(src) || QDELETED(A) || stat >= DEAD)
		return
	var/turf/startloc = get_turf(src)
	if(!startloc)
		return
	var/hand_type = breached ? /obj/projectile/dtn_hand/unsealing : /obj/projectile/dtn_hand
	var/obj/projectile/dtn_hand/P = new hand_type(startloc)
	P.applies_stack = stacking
	P.starting = startloc
	P.firer = src
	P.fired_from = src
	P.original = A
	P.yo = A.y - startloc.y
	P.xo = A.x - startloc.x
	playsound(src, projectilesound, 100, TRUE)
	P.preparePixelProjectile(A, src, null, rand(-8, 8)) //A little spread so the burst fans.
	P.fire()

//A twin of /obj/projectile/regret_hand, not a subtype: its on_hit() stacks unconditionally
//and ..() cannot skip a level to suppress that.
/obj/projectile/dtn_hand
	name = "hand of regret"
	icon_state = "cursehand0"
	hitsound = 'sound/effects/curse4.ogg'
	layer = LARGE_MOB_LAYER
	damage_type = WHITE_DAMAGE
	damage = 15
	speed = 2
	range = 10
	var/datum/beam/arm
	var/handedness = 0
	///Only the lead hand of a volley stacks; three would be 3 of the 5 the threshold needs.
	var/applies_stack = TRUE

/obj/projectile/dtn_hand/Initialize(mapload)
	. = ..()
	handedness = prob(50)
	icon_state = "cursehand[handedness]"

/obj/projectile/dtn_hand/fire(setAngle)
	if(starting)
		arm = starting.Beam(src, icon_state = "curse[handedness]", beam_type = /obj/effect/ebeam/curse_arm)
	..()

/obj/projectile/dtn_hand/Destroy()
	if(arm)
		QDEL_NULL(arm)
	return ..()

/obj/projectile/dtn_hand/on_hit(atom/target, blocked)
	. = ..()
	if(!applies_stack || target == firer)
		return
	//People and other LCL specimens both. The Realm does not care which it is holding.
	if(!ishuman(target) && !istype(target, /mob/living/simple_animal/hostile/limbus_abno))
		return
	var/mob/living/L = target
	var/datum/status_effect/regret_stacks/R = L.has_status_effect(/datum/status_effect/regret_stacks)
	if(R)
		R.add_stack()
	else
		L.apply_status_effect(/datum/status_effect/regret_stacks, firer)

//Breached ammunition. Forces a struck door open and cascades to its neighbours. Bolted,
//welded and sealed doors still refuse.
/obj/projectile/dtn_hand/unsealing
	name = "unsealing hand"
	var/cascade_depth = 3

/obj/projectile/dtn_hand/unsealing/on_hit(atom/target, blocked)
	. = ..()
	var/obj/machinery/door/D = target
	if(!istype(D))
		return
	INVOKE_ASYNC(src, PROC_REF(Unseal), D, cascade_depth, list())

/obj/projectile/dtn_hand/unsealing/proc/Unseal(obj/machinery/door/D, depth, list/seen)
	if(!D || QDELETED(D) || seen[D] || depth <= 0)
		return
	if(istype(D, /obj/machinery/door/airlock/regret_archive)) //Reward for the shrine circuit.
		return
	seen[D] = TRUE
	if(istype(D, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/A = D
		A.open(2) //Airlocks need forced = 2 to bypass the power check. Bolts still refuse.
	else
		D.open()
	//open() sleeps twice, and adjacency is mutual, so: async, and `seen` or it never ends.
	for(var/obj/machinery/door/N in range(1, D))
		INVOKE_ASYNC(src, PROC_REF(Unseal), N, depth - 1, seen)

// ============================ SEALED BURIAL ============================

//Sealed Burial runs before the base's eat path, or meleeing a body routes into swallowing.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/UnarmedAttack(atom/A, proximity)
	if(SealedBurialAttempt(A))
		return
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/SealedBurialAttempt(atom/A)
	if(!ishuman(A))
		return FALSE
	var/mob/living/carbon/human/H = A
	if(H.stat != DEAD && !seal_living)
		return FALSE
	if(IsSealedByDoor(H))
		to_chat(src, span_warning("You are already keeping [H]."))
		return TRUE
	if(H.ckey && recapture_immune[H.ckey] && world.time < recapture_immune[H.ckey])
		to_chat(src, span_warning("[H] still smells of the outside. You cannot take them back yet."))
		return TRUE
	var/channel = (H.stat == DEAD) ? seal_time : breach_seal_time
	visible_message(span_warning("[src]'s chains unwind and reach for [H]..."))
	if(!do_after(src, channel, target = H))
		to_chat(src, span_warning("The chains slip loose."))
		return TRUE
	if(QDELETED(H) || IsSealedByDoor(H))
		return TRUE
	SealCaptive(H)
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/SealCaptive(mob/living/carbon/human/H)
	//No spin: the 12 second ragdoll is for people dragged in alive.
	if(!SendToRepentanceDimension(H, "The door takes what you left unsaid.", FALSE))
		return FALSE
	sealed[H] = world.time
	GLOB.dtn_sealed_captives[H] = src
	if(H.stat == DEAD)
		H.revive(full_heal = TRUE, admin_revive = TRUE)
		H.grab_ghost()
	RegisterSignal(H, COMSIG_MOVABLE_HEAR, PROC_REF(RelayRealmSpeech))
	RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(OnSealedDeleted))
	to_chat(H, span_userdanger("You wake somewhere behind a door. You can walk, and speak, and be mended here. \
		Do not step outside - whatever the door is holding in you goes with it."))
	visible_message(span_boldwarning("[src]'s chains close over [H], and the floor is empty."))
	playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)
	manual_emote("swallows [H] whole.")
	UpdateSealedAlert()
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/OnSealedDeleted(datum/source)
	SIGNAL_HANDLER
	sealed -= source
	GLOB.dtn_sealed_captives -= source
	UpdateSealedAlert()

///Beside the door, dead on arrival, immunity stamped. Every exit from a seal comes here.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/ReleaseSealed(mob/living/carbon/human/H)
	if(!H || !(H in sealed))
		return FALSE
	sealed -= H
	GLOB.dtn_sealed_captives -= H
	UnregisterSignal(H, list(COMSIG_MOVABLE_HEAR, COMSIG_PARENT_QDELETING))
	UpdateSealedAlert()
	if(QDELETED(H))
		return FALSE
	var/turf/exit_turf = ExitTurf()
	//The normal rescue, so the ambience effect and trapped-list bookkeeping are cleaned up.
	RescueFromRepentanceDimension(H, exit_turf, "You step out of the door, and everything it was keeping in you steps out too.")
	if(exit_turf)
		H.forceMove(exit_turf)
	if(H.ckey)
		recapture_immune[H.ckey] = world.time + recapture_immunity
	if(H.stat != DEAD)
		H.adjustBruteLoss(max(H.health, 0) + 50) //A plain, defibbable corpse - not a gib.
		if(H.stat != DEAD)
			H.death()
	H.visible_message(span_boldwarning("[H] falls out of nowhere at all, and does not get up."))
	playsound(exit_turf || get_turf(src), 'sound/effects/curse4.ogg', 50, TRUE)
	return TRUE

//Sealed captives are only alive because the door is holding them, so letting go kills them.
//Anything else it merely has inside - an agent who walked in, a specimen the hands pulled
//through - is put out beside the door and walks away.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/OpenForThem(mob/living/L)
	if(!L || QDELETED(L))
		return FALSE
	if(L in sealed)
		return ReleaseSealed(L)
	var/turf/exit_turf = ExitTurf()
	if(IsTrappedInRepentance(L))
		RescueFromRepentanceDimension(L, exit_turf, "The door opens, and lets you go.")
	if(exit_turf)
		L.forceMove(exit_turf)
	L.visible_message(span_warning("[L] steps out of nowhere at all."))
	playsound(exit_turf || get_turf(src), 'sound/effects/ghost2.ogg', 50, TRUE)
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/ReleaseAllSealed()
	for(var/mob/living/carbon/human/H in sealed.Copy())
		ReleaseSealed(H)
	sealed.Cut()
	recapture_immune.Cut()
	UpdateSealedAlert()

///A free tile beside the door, or its own if boxed in.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/ExitTurf()
	var/turf/here = get_turf(src)
	if(!here)
		return null
	for(var/dir in shuffle(GLOB.cardinals.Copy()))
		var/turf/T = get_step(here, dir)
		if(T && !T.density)
			return T
	return here

// ============================ EATING: SEAL vs SWALLOW ============================

//Diet items are sealed (qdel'd) and feed it; everything else is swallowed, held, and can be
//dropped back out in spirit form.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/AbnoEat(atom/food)
	var/list/entry = DietEntryFor(food)
	if(entry)
		var/hunger_gain = entry["hunger"]
		var/desire_gain = entry["desire"]
		var/sate_for = entry["sate"]
		//No full-bar bail: the pump parks a well-fed door at max, where the key matters most.
		if(hunger_gain)
			AdjustHunger(hunger_gain)
		if(desire_gain)
			AdjustDesire(desire_gain)
		if(sate_for)
			Sate(sate_for)
		playsound(src, 'sound/items/eatfood.ogg', 100, TRUE)
		manual_emote("seals [food] away.")
		qdel(food)
		return TRUE

	return SwallowItem(food)

//Held, not consumed, and worth no hunger or desire - junk would otherwise bypass the Realm
//diet entirely. The spirit uses this too, to pick things up inside the Realm and move them.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/SwallowItem(atom/thing, mob/reporting_to)
	if(!reporting_to)
		reporting_to = src
	if(!isitem(thing))
		return FALSE
	var/obj/item/I = thing
	if(I.anchored || is_type_in_typecache(I, dtn_swallow_blacklist))
		to_chat(reporting_to, span_warning("That is not yours to keep."))
		return FALSE
	if(length(swallowed) >= max_swallowed)
		to_chat(reporting_to, span_warning("You are full of other people's things. Put some of it down first."))
		return FALSE
	if(ismob(I.loc))
		var/mob/holder = I.loc
		holder.dropItemToGround(I, TRUE)
	playsound(get_turf(I), 'sound/effects/ghost2.ogg', 40, TRUE)
	I.forceMove(src)
	swallowed += I
	RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(OnSwallowedDeleted))
	to_chat(reporting_to, span_notice("You take [I] into yourself."))
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/DietEntryFor(atom/food)
	for(var/food_type in dtn_diet)
		if(istype(food, food_type))
			return dtn_diet[food_type]
	return null

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/OnSwallowedDeleted(datum/source)
	SIGNAL_HANDLER
	swallowed -= source

///Drops everything swallowed, so the egg cannot take items out of the round.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/DumpSwallowed(turf/where)
	if(!where)
		where = get_turf(src)
	for(var/obj/item/I in swallowed.Copy())
		swallowed -= I
		if(QDELETED(I))
			continue
		UnregisterSignal(I, COMSIG_PARENT_QDELETING)
		if(where)
			I.forceMove(where)
	swallowed.Cut()

// ---- Hunger pause ----
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/Sate(duration)
	if(satiated)
		return
	satiated = TRUE
	hunger_was_active = hunger_active
	hunger_active = FALSE
	to_chat(src, span_nicegreen("Something in you settles. You will not need to be fed for a while."))
	addtimer(CALLBACK(src, PROC_REF(EndSate)), duration, TIMER_UNIQUE|TIMER_OVERRIDE)

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/EndSate()
	if(!satiated)
		return
	satiated = FALSE
	hunger_active = hunger_was_active //Never starts the drain early if the kickstart hasn't run.
	hunger_cooldown = world.time + hunger_cooldown_time
	to_chat(src, span_warning("The taste fades. You are hungry again."))

// ============================ THE COUNTER PUMP ============================

//The pump: a bar hitting 0 costs a counter, a bar hitting max banks one, and both reset to
//half. The bars are written directly - calling the Adjust procs here would recurse.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/AdjustDesire(desire_amount)
	. = ..()
	if(!. || pumping)
		return .
	pumping = TRUE
	if(desire_bar <= 0)
		desire_bar = round(max_desire * 0.5)
		AdjustCounter(-1)
	else if(desire_bar >= max_desire && counter < max_counter)
		desire_bar = round(max_desire * 0.5)
		AdjustCounter(1)
	pumping = FALSE
	UpdateBars()
	return .

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/AdjustHunger(feeding_amount)
	. = ..()
	if(!. || pumping)
		return .
	pumping = TRUE
	if(hunger_bar <= 0)
		hunger_bar = round(max_hunger * 0.5)
		starving = FALSE //The base only clears this on a later call, which writing directly skips.
		AdjustCounter(-1)
	else if(hunger_bar >= max_hunger && counter < max_counter)
		hunger_bar = round(max_hunger * 0.5)
		AdjustCounter(1)
	pumping = FALSE
	UpdateBars()
	return .

//Base bookkeeping with its own messages; the pump moves the counter far too often for the
//base's "[N] COUNTER" line.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/AdjustCounter(counter_amount)
	if(breached || counter_amount == 0)
		return FALSE
	var/original = counter
	counter = clamp(counter + counter_amount, 0, max_counter)
	UpdateBars()
	update_action_buttons()
	if(original != counter)
		if(counter > original)
			to_chat(src, span_nicegreen("<b>Another lock catches.</b> [counter] of [max_counter]."))
			playsound(src, 'sound/machines/synth_yes.ogg', 20, FALSE)
		else
			to_chat(src, span_userdanger("A latch gives. [counter] of [max_counter]."))
			playsound(src, 'sound/machines/synth_no.ogg', 20, FALSE)
	UpdateBreachOffer()
	return TRUE

// ============================ THE REALM FEEDING LOOP ============================

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/Life()
	. = ..()
	if(stat >= DEAD)
		return
	SweepSealed()
	if(realm_cooldown > world.time)
		return
	realm_cooldown = world.time + realm_cooldown_time
	RealmOccupancyTick()

//Ejects any captive no longer inside the Realm. A sweep rather than COMSIG_MOVABLE_MOVED,
//which would area-check every step.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/SweepSealed()
	for(var/mob/living/carbon/human/H in sealed.Copy())
		if(QDELETED(H))
			sealed -= H
			GLOB.dtn_sealed_captives -= H
			continue
		if(istype(get_area(H), /area/fishboat/repentance))
			continue
		ReleaseSealed(H)

//Desire per live guest in the Realm, plus a liminal affinity drip. Both skip sealed captives,
//who are revived and walking around in there.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/RealmOccupancyTick()
	var/guests = 0
	for(var/mob/living/carbon/human/H in GetRealmOccupants())
		if(!ishuman(H) || H.stat == DEAD || !H.client)
			continue
		if(H in sealed)
			continue
		guests++
		GainAffinity(H, realm_affinity) //Raises their safe limit; never writes their armor's dial.
	if(!guests)
		return
	AdjustDesire(occupancy_desire * min(guests, occupancy_cap))
	to_chat(src, span_notice("Someone is walking about inside you."))

// ============================ WILLING ENTRY ============================

//Help intent on the door offers the way in, the same as the contained abnormality. The parent
//call still runs first, so anyone who says no has simply petted it.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/attack_hand(mob/living/carbon/human/M)
	. = ..()
	if(!ishuman(M) || M.a_intent != INTENT_HELP || stat >= DEAD)
		return
	if(IsTrappedInRepentance(M))
		to_chat(M, span_warning("You are already within the realm of sealed regrets."))
		return
	INVOKE_ASYNC(src, PROC_REF(OfferWillingEntry), M)

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/OfferWillingEntry(mob/living/carbon/human/M)
	if(tgui_alert(M, "Do you wish to step through the Door to Nowhere and enter the realm of sealed regrets?", "Enter the Door", list("Yes", "No")) != "Yes")
		return
	to_chat(M, span_notice("You place your hand on the door. The chains begin to loosen as it recognises your willing surrender..."))
	if(!do_after(M, willing_entry_time, target = src))
		to_chat(M, span_notice("You pull your hand back from the door."))
		return
	if(QDELETED(src) || stat >= DEAD || IsTrappedInRepentance(M))
		return
	to_chat(M, span_userdanger("You step through the door willingly, accepting whatever fate awaits within..."))
	visible_message(span_warning("[M] steps through [src], vanishing into the realm beyond!"))
	playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)
	SendToRepentanceDimension(M, "You willingly entered the realm of sealed regrets. The door closes gently behind you.", FALSE)
	RewardWillingOffering(M)

//A counter for the offering, the way the contained abnormality pays a qliphoth for one. Rate
//limited per person: the reality void puts a visitor back where they started, so without this
//one agent could walk the same loop for counters all shift.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/RewardWillingOffering(mob/living/carbon/human/M)
	manual_emote("'s chains tighten, satisfied.")
	if(!M.ckey || world.time < (willing_reward_cooldown[M.ckey] || 0))
		return
	willing_reward_cooldown[M.ckey] = world.time + willing_reward_cooldown_time
	AdjustCounter(1)

// ============================ BREACH ============================

///Counter 0 offers the breach as a clickable alert; the counter climbing back withdraws it.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/UpdateBreachOffer()
	if(breached || counter > 0 || stat >= DEAD)
		if(breach_ready)
			breach_ready = FALSE
			clear_alert("dtn_breach")
			to_chat(src, span_nicegreen("The chains draw tight again. Not yet."))
		return
	if(breach_ready)
		return
	breach_ready = TRUE
	throw_alert("dtn_breach", /atom/movable/screen/alert/dtn_breach)
	to_chat(src, span_userdanger("You are done being a door that only opens when asked. \
		Click the warning on your screen when you want to open yourself."))

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/AcceptBreach()
	if(breached || !breach_ready || stat >= DEAD)
		return FALSE
	breach_ready = FALSE
	clear_alert("dtn_breach")
	breached = TRUE
	unstable = TRUE
	seal_living = TRUE
	ChangeResistances(breached_resistances)
	adjustHealth(-maxHealth) //Full restoration, the same idiom the Punishing Bird uses.
	AddBreachEffect()
	manual_emote("throws itself open.")
	to_chat(src, span_userdanger("You are open. You do not need them dead first any more - hold a living \
		person still long enough and you can take them. And no door in this place is shut to you: \
		shoot one and it opens, and the ones beside it with it. Only bolts will hold."))
	playsound(get_turf(src), 'sound/effects/curse3.ogg', 60, TRUE)
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/Unbreach()
	if(!breached)
		return
	breached = FALSE
	unstable = FALSE
	seal_living = FALSE
	ChangeResistances(unbreached_resistances)
	RemoveBreachEffect()
	manual_emote("swings shut, and the chains find their places again.")
	to_chat(src, span_userdanger("That is enough. You close."))
	AdjustCounter(max_counter) //Or the offer is thrown again the instant the breach ends.

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/updatehealth()
	..()
	if(breached && health <= breach_break_health)
		Unbreach()

/atom/movable/screen/alert/dtn_breach
	name = "You May Open"
	desc = "You have met the condition to breach. Click this to open yourself - you will be whole again and far harder to hurt, \
		you will be able to take the living and not only the dead, and every door you shoot will open, along with the doors beside it. \
		Bolted doors will still hold. A hard enough beating will close you."
	icon = 'ModularLobotomy/_Lobotomyicons/abno_hud.dmi'
	icon_state = "dtn_breach"

/atom/movable/screen/alert/dtn_breach/Click(location, control, params)
	. = ..() //The parent handles the shift-click "examine" path, which prints name + desc.
	if(!usr || usr != owner)
		return
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, SHIFT_CLICK))
		return
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = owner
	if(!istype(D))
		return
	D.AcceptBreach()

// ============================ HUD / READOUT ============================

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/UpdateSealedAlert()
	if(!length(sealed))
		clear_alert("dtn_sealed")
		return
	throw_alert("dtn_sealed", /atom/movable/screen/alert/dtn_sealed)
	var/atom/movable/screen/alert/dtn_sealed/A = alerts["dtn_sealed"]
	if(A)
		A.UpdateSealed(length(sealed))

/atom/movable/screen/alert/dtn_sealed
	name = "Sealed"
	desc = "How many people you are keeping."
	icon = 'ModularLobotomy/_Lobotomyicons/abno_hud.dmi'
	icon_state = "dtn_sealed"
	maptext_x = 6
	maptext_y = 10

/atom/movable/screen/alert/dtn_sealed/proc/UpdateSealed(count)
	desc = "You are keeping [count] \
		[count == 1 ? "person" : "people"] behind you. They die the moment they leave, by any route."
	maptext = MAPTEXT("<span style='color: #caac4e'><b>[count]</b></span>")

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/SelfStatusReadout()
	. = ..()
	. += "Sealed: [length(sealed)]"
	. += "Swallowed: [length(swallowed)]/[max_swallowed]"
	if(satiated)
		. += "<span class='nicegreen'>Sated - hunger is paused.</span>"
	if(breached)
		. += "<span class='userdanger'>OPEN. Closes at [breach_break_health] health.</span>"

// ============================ DEATH / REBIRTH ============================

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/death(gibbed)
	breach_ready = FALSE
	clear_alert("dtn_breach")
	Unbreach()
	RecallSpirit(TRUE)
	//Before the base swaps the body for the egg.
	ReleaseAllSealed()
	DumpSwallowed(get_turf(src))
	EndSate()
	return ..()

//hunger_active is left alone: death() ran EndSate(), and setting it would start the drain on
//a shell that never got its kickstart.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/Rebirth()
	..()
	satiated = FALSE
	seal_living = FALSE
	breached = FALSE
	breach_ready = FALSE

// ============================ THE SPIRIT ============================

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/ProjectSpirit()
	if(spirit || !client || stat >= DEAD)
		return FALSE
	var/turf/destination = RealmEntryTurf()
	if(!destination)
		to_chat(src, span_warning("You cannot find the way in. There is nothing behind you right now."))
		return FALSE
	var/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/P = new(destination)
	P.name = "the presence behind [true_name]"
	P.dtn_door = src
	P.source_door = src
	P.faction = faction.Copy()
	spirit = P
	possession_locked = TRUE //The body sits empty while we are down there; it is still ours.
	QuietMindTransfer(mind, P)
	visible_message(span_warning("[src] shudders, and then goes completely still..."))
	playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)
	to_chat(P, span_notice("<b>You are inside yourself.</b> Nobody can see you here, and you cannot leave."))
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/RecallSpirit(abort = FALSE)
	if(!spirit || recalling_spirit)
		return FALSE
	recalling_spirit = TRUE
	spirit.SetClickMode(null)
	if(spirit.mind)
		if(QDELETED(src) || stat >= DEAD)
			spirit.ghostize(FALSE) //Pushing a player into a deleting body would strand them.
		else
			QuietMindTransfer(spirit.mind, src)
	QDEL_NULL(spirit)
	possession_locked = FALSE
	recalling_spirit = FALSE
	if(abort || QDELETED(src))
		return FALSE
	playsound(src, 'sound/effects/ghost.ogg', 50, TRUE)
	to_chat(src, span_notice("You draw yourself back in."))
	visible_message(span_notice("[src] settles, as if something had come back to it."))
	return TRUE

///A repentance_spawn landmark to arrive at, or null if the Realm has none.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/RealmEntryTurf()
	if(!LAZYLEN(GLOB.repentance_spawn_points))
		InitializeRepentanceLocations()
	for(var/turf/T in shuffle(GLOB.repentance_spawn_points.Copy()))
		if(T && istype(get_area(T), /area/fishboat/repentance))
			return T
	return null

//The projected form. Invisible, confined to the Realm, and whispers rather than speaks.
/mob/living/simple_animal/hostile/regret_spirit/projection/dtn
	name = "sealed presence"
	desc = "Nothing at all."
	maxHealth = 1000
	health = 1000
	invisibility = INVISIBILITY_MAXIMUM
	see_invisible = SEE_INVISIBLE_OBSERVER
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	del_on_death = FALSE
	light_range = 0
	light_power = 0
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/dtn_door
	///Client-side marker; it is invisible even to itself.
	var/image/self_marker
	///Whichever click mode holds the click. Build or mend, never both.
	var/datum/dtn_click_mode/click_mode

/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/Initialize(mapload)
	. = ..()
	alpha = 255
	density = FALSE
	//No-ops the projection base's 1.5 brute a tick, which exists to expire the WAW spirit.
	status_flags |= GODMODE
	incorporeal_move = INCORPOREAL_MOVE_BASIC
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB | PASSMACHINE | PASSSTRUCTURE | PASSCLOSEDTURF
	for(var/action_type in list(
		/datum/action/cooldown/dtn_action/whisper,
		/datum/action/cooldown/dtn_action/disgorge,
		/datum/action/cooldown/dtn_action/spirit_return,
		/datum/action/cooldown/dtn_action/teleport,
		/datum/action/cooldown/dtn_action/build,
		/datum/action/cooldown/dtn_action/drop_object,
		/datum/action/cooldown/dtn_action/mend,
	))
		var/datum/action/cooldown/dtn_action/A = new action_type()
		A.Grant(src)
		A.UpdateButtonIcon() //Base Grant refreshes before our vars are set, so the button greys out.

/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/Destroy()
	SetClickMode(null)
	if(client)
		client.images.Remove(self_marker)
	self_marker = null
	dtn_door = null
	return ..()

/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	ShowSelfMarker()

/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/proc/ShowSelfMarker()
	if(client)
		client.images.Remove(self_marker)
	self_marker = image('ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi', src, "dtn_spirit", ABOVE_MOB_LAYER)
	self_marker.override = TRUE
	if(client)
		client.images |= self_marker

//Confinement on arrival, not in Move(): Process_Incorpmove() forceMove()s an
//INCORPOREAL_MOVE_BASIC mob, so Move() is never called.
/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(istype(get_area(src), /area/fishboat/repentance))
		return
	var/turf/back = get_turf(OldLoc)
	if(!back || !istype(get_area(back), /area/fishboat/repentance))
		back = dtn_door ? dtn_door.RealmEntryTurf() : null
	if(back)
		forceMove(back)
	to_chat(src, span_warning("You cannot leave. You *are* the room."))

//A specimen the hands dragged in here has no key and no way back, so it gets the archive by
//force. Nothing else in the Realm opens this door without the key of acceptance.
/obj/machinery/door/airlock/regret_archive/attack_animal(mob/user)
	if(!istype(user, /mob/living/simple_animal/hostile/limbus_abno))
		return ..()
	if(operating || welded || locked || seal || !density)
		return
	to_chat(user, span_notice("The seals mean nothing to you. You put a hand through them."))
	visible_message(span_warning("[src]'s seals gutter out, and it grinds open."))
	playsound(src, 'sound/effects/ghost2.ogg', 50, TRUE)
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/machinery/door/airlock, open), 2)

//Picks items up off the Realm's floor into the door, so the spirit can carry them elsewhere
//and put them down with Give It Back. Diet items are not sealed this way - only the body eats.
/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/UnarmedAttack(atom/A, proximity)
	if(dtn_door && !QDELETED(dtn_door) && isitem(A))
		return dtn_door.SwallowItem(A, src)
	return ..()

//The same whisper the body uses, inside the Realm.
/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!message)
		return
	for(var/mob/M in get_hearers_in_view(7, src))
		if(!M.client)
			continue
		to_chat(M, DTNWhisperText("You hear a cold whisper from everywhere at once... \"[message]\""))
	RelayWhisperToGhosts(src, message)
	log_say("[key_name(src)] (LCL Door spirit) whispers: [message]")
	return

/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/death(gibbed)
	. = ..() //Recall deletes this mob, so let the death chain finish on a live one first.
	if(dtn_door && !QDELETED(dtn_door))
		dtn_door.RecallSpirit(TRUE)

//A logout down here would strand the body empty and possession-locked.
/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/Logout()
	. = ..()
	if(dtn_door && !QDELETED(dtn_door))
		dtn_door.RecallSpirit(TRUE)

///One slot for both click modes, so build and mend are mutually exclusive by construction.
/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/proc/SetClickMode(datum/dtn_click_mode/mode)
	if(click_mode == mode)
		return
	if(click_mode)
		var/datum/dtn_click_mode/old = click_mode
		click_mode = null
		old.Deactivate()
	click_mode = mode
	click_intercept = mode
	update_action_buttons()

// ============================ CLICK MODES ============================

/datum/dtn_click_mode
	var/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/spirit

/datum/dtn_click_mode/New(_spirit)
	. = ..()
	spirit = _spirit

/datum/dtn_click_mode/Destroy()
	spirit = null
	return ..()

///interface/skin.dmf leaves right-click off on the game map, so BYOND answers a right-click
///with its own verb popup and Click() is never reached. Turned on for as long as a click mode
///wants it, and back off after, so nothing else in the round changes.
/datum/dtn_click_mode/proc/SetMapRightClick(enabled)
	if(spirit?.client)
		winset(spirit.client, "mapwindow.map", "right-click=[enabled ? "true" : "false"]")

///Called when something else takes the click, or the owning action is toggled off.
/datum/dtn_click_mode/proc/Deactivate()
	if(spirit && spirit.click_mode == src)
		spirit.SetClickMode(null)
	qdel(src)

/datum/dtn_click_mode/proc/InterceptClickOn(mob/user, params, atom/A)
	return FALSE

// ---- Mini build mode ----
/datum/dtn_click_mode/builder
	var/selected = null
	var/selected_name = ""
	var/next_place = 0
	var/place_cooldown = 1 SECONDS
	var/desire_cost = 0.25
	///Fractional cost carried between placements: AdjustDesire() rounds the bar to 1, so a
	///quarter point spent per placement would otherwise round away to nothing.
	var/desire_owed = 0
	///Facing given to placed objects. NORTHWEST means "whichever way I am facing".
	var/build_dir = SOUTH

/datum/dtn_click_mode/builder/New(_spirit)
	. = ..()
	SetMapRightClick(TRUE)

/datum/dtn_click_mode/builder/Destroy()
	SetMapRightClick(FALSE)
	return ..()

///What the door has put down, so it can take it back up again. Tiles are keyed by coordinate
///because ChangeTurf replaces the turf datum.
/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere
	///"x-y-z" -> "closed" or "open".
	var/list/built_tiles = list()
	var/list/built_objects = list()
	///What a removed tile reverts to.
	var/removed_wall = /turf/closed/indestructible/wood
	var/removed_floor = /turf/open/indestructible/hotelwood

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/TileKey(turf/T)
	return "[T.x]-[T.y]-[T.z]"

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/TrackBuiltObject(obj/O)
	built_objects += O
	RegisterSignal(O, COMSIG_PARENT_QDELETING, PROC_REF(OnBuiltObjectDeleted))

/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/proc/OnBuiltObjectDeleted(datum/source)
	SIGNAL_HANDLER
	built_objects -= source

///Access-free, since nothing in the Realm carries a bar ID.
/obj/machinery/jukebox/unlocked
	req_access = null

//Category, then item, then facing; the flat list is over a hundred entries.
/datum/dtn_click_mode/builder/proc/PickMaterial(mob/user)
	if(!length(GLOB.dtn_build_palette))
		BuildDTNPalette()
	var/category = tgui_input_list(user, "What kind of thing?", "Furnish", GLOB.dtn_build_palette)
	if(!category)
		return FALSE
	var/list/entries = GLOB.dtn_build_palette[category]
	if(!length(entries))
		return FALSE
	var/choice = tgui_input_list(user, "What do you want to put down?", category, entries)
	if(!choice)
		return FALSE
	selected = entries[choice]
	selected_name = choice
	if(!ispath(selected, /turf))
		var/facing = tgui_input_list(user, "Facing which way?", "Furnish", GLOB.dtn_build_dirs)
		if(facing)
			build_dir = GLOB.dtn_build_dirs[facing]
	to_chat(user, span_notice("You will place: <b>[choice]</b>. Left-click a tile inside your Realm \
		to put one down, right-click to take back anything you put there."))
	return TRUE

/datum/dtn_click_mode/builder/InterceptClickOn(mob/user, params, atom/A)
	if(!spirit)
		return FALSE
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		return RemoveBuilt(user, A)
	if(!selected)
		return FALSE
	if(world.time < next_place)
		return TRUE
	var/turf/T = get_turf(A)
	if(!T)
		return TRUE
	if(!istype(get_area(T), /area/fishboat/repentance))
		to_chat(user, span_warning("You can only shape what is inside you."))
		return TRUE
	//An open turf, so the floor rule below would otherwise let the Realm's only exit be paved.
	if(istype(T, /turf/open/chasm))
		to_chat(user, span_warning("You will not close that. It is the only way out, and it is not yours to take."))
		return TRUE
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = spirit.dtn_door
	if(D && D.desire_bar < 1)
		to_chat(user, span_warning("You have nothing left to spend on decorating."))
		return TRUE

	if(ispath(selected, /turf))
		//Wall on wall, floor on floor: it redecorates without changing the floorplan.
		if(ispath(selected, /turf/closed) && !isclosedturf(T))
			to_chat(user, span_warning("A wall only goes where a wall already is."))
			return TRUE
		if(ispath(selected, /turf/open) && !isopenturf(T))
			to_chat(user, span_warning("A floor only goes where a floor already is."))
			return TRUE
		if(D)
			D.built_tiles[D.TileKey(T)] = ispath(selected, /turf/closed) ? "closed" : "open"
		T.ChangeTurf(selected)
	else
		if(!isopenturf(T))
			to_chat(user, span_warning("There is no room for that there."))
			return TRUE
		var/atom/movable/placed = new selected(T)
		//NORTHWEST is the "use my own facing" entry. Intercepts run before ClickOn() turns the
		//mob, so that is whichever way it last moved.
		placed.setDir(build_dir == NORTHWEST ? user.dir : build_dir)
		if(D && isobj(placed))
			D.TrackBuiltObject(placed)

	next_place = world.time + place_cooldown
	SpendDesire(D)
	playsound(T, 'sound/effects/ghost2.ogg', 30, TRUE)
	return TRUE

///The bar rounds to 1, so a quarter point is carried until a whole one is owed.
/datum/dtn_click_mode/builder/proc/SpendDesire(mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D)
	if(!D)
		return
	desire_owed += desire_cost
	if(desire_owed < 1)
		return
	var/spend = round(desire_owed)
	desire_owed -= spend
	D.AdjustDesire(-spend)

///Right-click takes back anything the door put down, free. Nothing else in the Realm can be
///touched this way - the map's own furniture and turfs are not its to remove.
/datum/dtn_click_mode/builder/proc/RemoveBuilt(mob/user, atom/A)
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = spirit.dtn_door
	if(!D)
		return TRUE
	if(isobj(A) && (A in D.built_objects))
		to_chat(user, span_notice("You take [A] back."))
		playsound(get_turf(A), 'sound/effects/ghost2.ogg', 30, TRUE)
		qdel(A)
		return TRUE
	var/turf/T = get_turf(A)
	if(!T)
		return TRUE
	//Standing on a tile you built, clicking the mob or an item on it, still means the tile.
	for(var/obj/O in T)
		if(O in D.built_objects)
			to_chat(user, span_notice("You take [O] back."))
			playsound(T, 'sound/effects/ghost2.ogg', 30, TRUE)
			qdel(O)
			return TRUE
	var/key = D.TileKey(T)
	var/built = D.built_tiles[key]
	if(!built)
		to_chat(user, span_warning("That was not yours to begin with."))
		return TRUE
	T.ChangeTurf(built == "closed" ? D.removed_wall : D.removed_floor)
	playsound(T, 'sound/effects/ghost2.ogg', 30, TRUE)
	return TRUE

// ---- Mend ----
/datum/dtn_click_mode/mender
	var/next_mend = 0
	var/mend_cooldown = 5 SECONDS
	var/brute_healed = 25
	var/sanity_healed = 15

/datum/dtn_click_mode/mender/InterceptClickOn(mob/user, params, atom/A)
	var/mob/living/carbon/human/H = A
	//A hologram is only light; mending one mends whoever is casting it.
	if(istype(A, /mob/living/simple_animal/hostile/liminal_hologram))
		var/mob/living/simple_animal/hostile/liminal_hologram/holo = A
		H = holo.projector
	if(!ishuman(H))
		return FALSE //Let ordinary clicks on anything else through.
	if(!istype(get_area(H), /area/fishboat/repentance))
		to_chat(user, span_warning("They are not inside you. You cannot reach them."))
		return TRUE
	if(world.time < next_mend)
		return TRUE
	next_mend = world.time + mend_cooldown
	H.adjustBruteLoss(-brute_healed)
	H.adjustSanityLoss(-sanity_healed)
	new /obj/effect/temp_visual/heart(get_turf(H))
	to_chat(H, span_nicegreen("Something closes over your wounds, gently, and holds."))
	to_chat(user, span_notice("You mend [H]."))
	return TRUE

// ============================ ACTIONS ============================

//One base for both forms; owner is the body or the spirit, so actions resolve via GetDoor().
/datum/action/cooldown/dtn_action
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_liminal"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	transparent_when_unavailable = TRUE
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/dtn_action/proc/GetDoor()
	if(istype(owner, /mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere))
		return owner
	if(istype(owner, /mob/living/simple_animal/hostile/regret_spirit/projection/dtn))
		var/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/S = owner
		return S.dtn_door
	return null

/datum/action/cooldown/dtn_action/proc/GetSpirit()
	if(istype(owner, /mob/living/simple_animal/hostile/regret_spirit/projection/dtn))
		return owner
	return null

/datum/action/cooldown/dtn_action/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = GetDoor()
	if(!D || QDELETED(D) || D.stat >= DEAD)
		return FALSE
	return TRUE

// ---- Focused Whisper (both forms) ----
/datum/action/cooldown/dtn_action/whisper
	name = "Focused Whisper"
	desc = "Send a chilling whisper directly into one person's mind."
	button_icon_state = "dtn_whisper"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/dtn_action/whisper/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/list/possible_targets = list()
	for(var/mob/living/L in view(7, owner))
		if(L == owner || !L.client)
			continue
		possible_targets[L.name] = L
	if(!length(possible_targets))
		to_chat(owner, span_warning("There is no one nearby to whisper to..."))
		return FALSE
	var/target_name = tgui_input_list(owner, "Choose your target...", "Focused Whisper", possible_targets)
	if(!target_name)
		return FALSE
	var/mob/living/target = possible_targets[target_name]
	if(QDELETED(target) || get_dist(owner, target) > 7 || !target.client)
		return FALSE
	var/message = stripped_input(owner, "What chilling message do you wish to send?", "Whisper")
	if(!message)
		return FALSE
	if(QDELETED(target) || get_dist(owner, target) > 7)
		to_chat(owner, span_warning("Your target is no longer in range."))
		return FALSE
	to_chat(target, DTNWhisperText("You feel a presence focus on you... A cold whisper penetrates your mind: \"[message]\"", TRUE))
	to_chat(owner, DTNWhisperText("You whisper to [target]: \"[message]\""))
	for(var/mob/M in viewers(target, 7))
		if(M != target && M != owner)
			to_chat(M, span_warning("[target] shivers as if touched by something unseen..."))
	RelayWhisperToGhosts(owner, message, target)
	log_directed_talk(owner, target, message, LOG_SAY, "door whisper")
	StartCooldown()
	return TRUE

// ---- Project Regret Spirit (body only) ----
/datum/action/cooldown/dtn_action/project
	name = "Project Regret Spirit"
	desc = "Step out of yourself and into your own Realm as a presence nobody can see. \
		You can come back whenever you like."
	button_icon_state = "dtn_project"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/dtn_action/project/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = GetDoor()
	if(!D.ProjectSpirit())
		return FALSE
	StartCooldown()
	return TRUE

// ---- Return to Form (spirit only) ----
/datum/action/cooldown/dtn_action/spirit_return
	name = "Return to Form"
	desc = "Draw yourself back into your body."
	button_icon_state = "dtn_return"

/datum/action/cooldown/dtn_action/spirit_return/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = GetDoor()
	return D.RecallSpirit()

// ---- Disgorge a captive (both forms) ----
/datum/action/cooldown/dtn_action/disgorge
	name = "Open For Them"
	desc = "Let anyone inside you out beside your body. The ones you are keeping alive will not survive it; \
		anyone else you were only holding walks away."
	button_icon_state = "dtn_disgorge"
	cooldown_time = 10 SECONDS

/datum/action/cooldown/dtn_action/disgorge/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = GetDoor()
	//An O(1) proxy for GetRealmOccupants(): every route in registers on the trapped list, and
	//IsAvailable() runs on every button refresh, which the counter pump drives constantly.
	return length(D.sealed) || length(GLOB.repentance_trapped_players)

/datum/action/cooldown/dtn_action/disgorge/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = GetDoor()
	var/list/choices = list()
	//Sealed captives may have been dragged out of the Realm already, so both sources are read.
	for(var/mob/living/L in (GetRealmOccupants() | D.sealed))
		if(QDELETED(L))
			continue
		choices["[L.real_name || L.name][(L in D.sealed) ? " (sealed)" : ""]"] = L
	if(!length(choices))
		to_chat(owner, span_warning("There is nobody inside you."))
		return FALSE
	var/picked = tgui_input_list(owner, "Who do you let go?", "Open For Them", choices)
	if(!picked)
		return FALSE
	var/mob/living/L = choices[picked]
	if(QDELETED(L))
		return FALSE
	D.OpenForThem(L)
	StartCooldown()
	return TRUE

// ---- Teleport to a human in the Realm (spirit only) ----
/datum/action/cooldown/dtn_action/teleport
	name = "Be Where They Are"
	desc = "Move to anyone standing inside your Realm."
	button_icon_state = "dtn_teleport"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/dtn_action/teleport/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/S = GetSpirit()
	if(!S)
		return FALSE
	var/list/choices = list()
	for(var/mob/living/L in GetRealmOccupants())
		choices["[L.real_name || L.name][L.stat == DEAD ? " (dead)" : ""]"] = L
	if(!length(choices))
		to_chat(owner, span_warning("There is nobody inside you."))
		return FALSE
	var/picked = tgui_input_list(owner, "Who do you go to?", "Be Where They Are", choices)
	if(!picked)
		return FALSE
	var/mob/living/L = choices[picked]
	if(QDELETED(L) || !istype(get_area(L), /area/fishboat/repentance))
		return FALSE
	S.forceMove(get_turf(L))
	StartCooldown()
	return TRUE

// ---- Mini build mode (spirit only, toggle) ----
/datum/action/cooldown/dtn_action/build
	name = "Furnish"
	desc = "Shape the inside of yourself. Walls only where walls already are, floors only where floors already are, \
		and never over the void. Placed walls cannot be broken. Left-click to place, right-click to take back \
		anything you put down."
	button_icon_state = "dtn_build"

/datum/action/cooldown/dtn_action/build/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/S = GetSpirit()
	if(!S)
		return FALSE
	if(istype(S.click_mode, /datum/dtn_click_mode/builder))
		S.SetClickMode(null)
		to_chat(owner, span_notice("You stop shaping."))
		UpdateButtonIcon()
		return TRUE
	var/datum/dtn_click_mode/builder/B = new(S)
	if(!B.PickMaterial(owner))
		qdel(B)
		return FALSE
	S.SetClickMode(B)
	UpdateButtonIcon()
	return TRUE

// ---- Disgorge a swallowed object (spirit only) ----
/datum/action/cooldown/dtn_action/drop_object
	name = "Give It Back"
	desc = "Put down one of the things you swallowed, here, inside your Realm."
	button_icon_state = "dtn_drop"
	cooldown_time = 2 SECONDS

/datum/action/cooldown/dtn_action/drop_object/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = GetDoor()
	return length(D.swallowed) > 0

/datum/action/cooldown/dtn_action/drop_object/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/door_to_nowhere/D = GetDoor()
	var/list/choices = list()
	for(var/obj/item/I in D.swallowed)
		choices["[I.name] ([REF(I)])"] = I
	if(!length(choices))
		return FALSE
	var/picked = tgui_input_list(owner, "What do you put down?", "Give It Back", choices)
	if(!picked)
		return FALSE
	var/obj/item/I = choices[picked]
	if(QDELETED(I))
		return FALSE
	D.swallowed -= I
	D.UnregisterSignal(I, COMSIG_PARENT_QDELETING)
	I.forceMove(get_turf(owner))
	to_chat(owner, span_notice("You put [I] down."))
	StartCooldown()
	return TRUE

// ---- Mend (spirit only, toggle) ----
/datum/action/cooldown/dtn_action/mend
	name = "Mend"
	desc = "While this is lit, clicking anyone inside your Realm heals them, from any distance. \
		It does not stop them dying the moment they leave."
	button_icon_state = "dtn_heal"

/datum/action/cooldown/dtn_action/mend/UpdateButtonIcon(status_only, force)
	var/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/S = GetSpirit()
	background_icon_state = (S && istype(S.click_mode, /datum/dtn_click_mode/mender)) ? "bg_liminal_on" : "bg_liminal"
	return ..()

/datum/action/cooldown/dtn_action/mend/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/regret_spirit/projection/dtn/S = GetSpirit()
	if(!S)
		return FALSE
	if(istype(S.click_mode, /datum/dtn_click_mode/mender))
		S.SetClickMode(null)
		to_chat(owner, span_notice("Your hands close."))
	else
		S.SetClickMode(new /datum/dtn_click_mode/mender(S))
		to_chat(owner, span_notice("Your hands open. Click anyone inside you to mend them."))
	UpdateButtonIcon()
	return TRUE
