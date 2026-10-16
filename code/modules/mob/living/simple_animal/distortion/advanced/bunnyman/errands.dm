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
	if(world.time >= next_den_visit || prob(den_chance))
		clear_target = HookToClear()
		if(clear_target)
			BeginErrand("clearing")
			return
		var/list/den = DenTurfs()
		if(den.len)
			den_turf = pick(den)
			den_until = 0
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
				var/mob/living/carbon/human/body = carried
				SetDown()
				visible_message(span_notice("[body] is set down on the pile."))
				EndErrand()
				return
			if(!GoTo(den_turf))
				EndErrand()
		if("den")
			DenTick()

/// The den visit. Arriving starts the stay; through it he drifts from den tile to den tile, stopping to say a piece of
/// the look whenever the mutter cooldown allows. When the stay is up, the next visit is den_interval away.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/DenTick()
	if(den_until && world.time >= den_until)
		next_den_visit = world.time + den_interval
		EndErrand()
		return
	if(loc != den_turf)
		if(!GoTo(den_turf))
			next_den_visit = world.time + den_interval
			EndErrand()
		return
	if(!den_until)
		den_until = world.time + den_stay + den_stay_per_stage * territory.stage
	Mutter()
	if(world.time >= rooted_until && prob(30))
		den_turf = pick(DenTurfs())

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
	Own(new /obj/structure/headpike/bunnyman(loc, src, carried_head))
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
	rip_target.Rip()
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
