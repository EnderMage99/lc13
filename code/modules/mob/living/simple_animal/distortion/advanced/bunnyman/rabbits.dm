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
	last_hit_by -= source
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
	/// His shape, shown to the target alone, over the rabbit everyone else still sees.
	var/image/mimic_image
	/// The mimic gives up after this long if it has not reached them.
	var/mimic_time = 30 SECONDS
	var/mimic_until = 0
	/// What it holds, shown over its head at this scale and this many pixels up.
	var/evidence_scale = 0.4
	var/evidence_offset = 14

/mob/living/simple_animal/hostile/bunnyman_rabbit/Initialize(mapload, new_distortion)
	. = ..()
	distortion = new_distortion
	var/coat = pick("b_rabbit_white", "b_rabbit_brown", "b_rabbit_black")
	icon_state = coat
	icon_living = coat
	icon_dead = "[coat]_dead"
	RegisterSignal(src, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnHurt))

/mob/living/simple_animal/hostile/bunnyman_rabbit/Destroy()
	if(mimic_target)
		Unmimic()
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

/mob/living/simple_animal/hostile/bunnyman_rabbit/update_overlays()
	. = ..()
	if(!evidence)
		return
	var/mutable_appearance/held = mutable_appearance(evidence.icon, evidence.icon_state)
	held.transform *= evidence_scale
	held.pixel_y = evidence_offset
	. += held

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
		// hurt, a mimic is a rabbit at once, so its heartbeat never runs under the real hunt that follows the hit
		if(mimic_target)
			Unmimic()

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

/// His shape to H alone, a scream only they hear, their heart going as if hunted, and a run straight at them. The
/// moment it reaches them, loses them, or mimic_time runs out, it is a rabbit again and their heart is let be.
/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/Mimic(mob/living/carbon/human/H)
	mimic_target = H
	LoseTarget()
	mimic_until = world.time + mimic_time
	mimic_image = image('ModularLobotomy/_Lobotomyicons/48x48.dmi', src, "bunnyman_enraged")
	mimic_image.override = TRUE
	mimic_image.pixel_x = -16
	if(H.client)
		H.client.images += mimic_image
	H.playsound_local(get_turf(src), 'sound/distortions/bunnyman/scream.ogg', 60, FALSE)
	to_chat(H, span_userdanger("He is here. He is coming straight at you."))
	BunnymanHeartbeat(H)
	walk_to(src, H, 0, mimic_speed)

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/MimicStep()
	if(QDELETED(mimic_target) || mimic_target.z != z || get_dist(src, mimic_target) > 10 || stat == DEAD || world.time >= mimic_until)
		Unmimic()
		return
	if(Adjacent(mimic_target))
		to_chat(mimic_target, span_notice("[src] stops at your feet. It is a rabbit. It was always a rabbit."))
		Unmimic()
		return
	walk_to(src, mimic_target, 0, mimic_speed)

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/Unmimic()
	walk(src, 0)
	if(mimic_target)
		if(mimic_target.client)
			mimic_target.client.images -= mimic_image
		// a real hunt on them keeps its own heartbeat
		if(!distortion || distortion.hunt_target != mimic_target)
			BunnymanHeartbeatStop(mimic_target)
	mimic_image = null
	mimic_target = null

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
	distortion.OnEvidenceTaking(src, M)
	if(!do_after(M, hand_out_time, src, extra_checks = CALLBACK(src, PROC_REF(StillCalm), M)))
		if(M.m_intent == MOVE_INTENT_RUN)
			Startle(M)
		return TRUE
	var/obj/item/bunnyman_evidence/given = evidence
	DropEvidence(get_turf(M))
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
	update_icon()

/mob/living/simple_animal/hostile/bunnyman_rabbit/proc/DropEvidence(turf/T)
	evidence.forceMove(T)
	evidence = null
	update_icon()

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
