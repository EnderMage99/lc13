// Tribute. Favour is kept per player, on their mind, so it survives death and ghosting. Tribute harvesters stand
// beside the gates of his outermost ring with a speech bubble. Hit one with an item on help intent and it carries the
// gift to him; he judges it, and the harvester comes back to tell you what he thought, by walking, or out of a puff
// of green mist if it cannot find a way. A gift the same player has given twice before is worthless and an insult.

/mob/living/simple_animal/hostile/distortion/advanced/prince
	/// Each player's ledger, by mind.
	var/list/ledgers = list()
	/// Favour a gift is worth the first time; each repeat of the exact same type halves it. Below 1 it is worthless.
	var/tribute_worth = 2
	/// Favour lost for a worthless gift.
	var/insult_cost = 2
	/// His Tribute harvesters, and when the next may come out after one was killed.
	var/list/tributes = list()
	var/tribute_respawn = 60 SECONDS
	var/next_tribute = 0
	/// What a Tribute harvester says he made of a gift: worth the full amount, worth less, and worthless.
	var/list/delighted_lines = list(
		"He was delighted. He has never had one of those. He says you may come again.",
		"The Prince laughed. A real laugh. Keep that up.",
	)
	var/list/pleased_lines = list(
		"He took it. He did not say thank you. That is a good sign.",
		"He has seen one before, but he kept it. Well done.",
	)
	var/list/insulted_lines = list(
		"He has three of these already. He says to take it back, and to think about it.",
		"The Prince is insulted. Here. He does not want it.",
	)

/// The ledger for whoever controls user, made now if create is set. Null for a mob with no mind.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/Ledger(mob/user, create = TRUE)
	var/datum/mind/M = user?.mind
	if(!M)
		return null
	var/datum/prince_ledger/L = ledgers[M]
	if(!L && create)
		L = new
		L.mind = M
		ledgers[M] = L
	return L

/// Judges a gift from L. Returns the worth it had: 0 for worthless, which costs favour and leaves the gift with the
/// caller to hand back. A gift with worth is eaten.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/JudgeTribute(datum/prince_ledger/L, obj/item/gift)
	var/worth = tribute_worth / (2 ** L.given[gift.type])
	if(worth < 1)
		L.AdjustFavour(-insult_cost)
		return 0
	L.given[gift.type]++
	L.AdjustFavour(worth)
	Eat(list(gift))
	return worth

/// Keeps one Tribute harvester at each post of his outermost ring. When a new ring goes up, they move out to it.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/UpdateTributes()
	if(!length(rings))
		return
	var/datum/prince_ring/outer = rings[length(rings)]
	var/list/posts = outer.TributePosts()
	var/list/taken = list()
	var/list/unposted = list()
	for(var/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/T as anything in tributes)
		if((T.post in posts) && !taken[T.post])
			taken[T.post] = T
		else
			unposted += T
	for(var/turf/P as anything in posts)
		if(taken[P])
			continue
		var/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/T
		if(length(unposted))
			T = unposted[1]
			unposted -= T
		else if(world.time >= next_tribute)
			T = SpawnFollower(/mob/living/simple_animal/hostile/prince_follower/messenger/tribute, NearTurf())
			tributes += T
		if(T)
			T.post = P
			taken[P] = T
	// more harvesters than posts: the spare ones go once they are free
	for(var/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/T as anything in unposted)
		T.post = null

// The ledger.

/datum/prince_ledger
	var/datum/mind/mind
	var/favour = 0
	/// Item type to how many times this player has given it.
	var/list/given = list()
	/// Offered requests rejected since the last one completed.
	var/rejections = 0
	/// Their request, offered or accepted. One at a time.
	var/datum/prince_request/request
	/// No Quest harvester comes before this.
	var/next_quest = 0
	/// Reports, and gifts to hand back, that could not reach them. Each is list(text, item or null).
	var/list/pending = list()

/// Favour never goes below 0.
/datum/prince_ledger/proc/AdjustFavour(amount)
	favour = max(0, favour + amount)

/// Their body, if it can be reached: alive, played, and on the same z-level as A.
/datum/prince_ledger/proc/Reachable(atom/A)
	var/mob/living/body = mind?.current
	if(!isliving(body) || body.stat == DEAD || !body.client || body.z != A.z)
		return null
	return body

// Messengers: harvesters that go to a person rather than a place. Tribute and Quest harvesters are both.

/mob/living/simple_animal/hostile/prince_follower/messenger
	// they slip past people instead of getting stuck behind them
	pass_flags = PASSTABLE | PASSMOB
	/// Who it is going to, since when, and how long it walks before it gives up and steps out of the mist instead.
	var/mob/living/errand_to
	var/errand_since = 0
	var/errand_patience = 30 SECONDS

/mob/living/simple_animal/hostile/prince_follower/messenger/Destroy()
	errand_to = null
	return ..()

/mob/living/simple_animal/hostile/prince_follower/messenger/CanAttack(atom/the_target)
	return FALSE

/// Walks to M, keeping the map's goal within 2 tiles of them. With no way to them, or after errand_patience, it
/// steps out of a puff of green mist beside them instead. TRUE once it is next to them.
/mob/living/simple_animal/hostile/prince_follower/messenger/proc/ReachPerson(mob/living/M)
	if(errand_to != M)
		errand_to = M
		errand_since = world.time
		flow = null
	if(get_dist(src, M) <= 1)
		StopFlow()
		return TRUE
	var/turf/goal = flow?.goal
	if(!goal || get_dist(goal, M) > 2)
		goal = get_turf(M)
	if(FlowTo(goal))
		flow = null
	if(flow_failed || world.time > errand_since + errand_patience)
		MistTo(get_turf(M))
		return get_dist(src, M) <= 1
	return FALSE

// Tribute harvesters.

/mob/living/simple_animal/hostile/prince_follower/messenger/tribute
	name = "tribute twiglet"
	desc = "A twiglet with a gold-leaf collar, waiting by the gate with its hands out."
	color = "#f0d890"
	/// Where it stands, beside one of the outermost gates. Null when it has no post left and goes home.
	var/turf/post
	/// "post", "to_prince" or "to_giver".
	var/mode = "post"
	/// What it is carrying in: one gift at most, and any deliveries.
	var/obj/item/gift
	var/list/load = list()
	/// Whose gift it carries, and what he made of it.
	var/datum/prince_ledger/giver
	var/report
	var/obj/item/returned
	/// Set when it misted to the giver, so it mists back to its post after reporting.
	var/misted = FALSE

/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/Initialize(mapload, new_prince)
	. = ..()
	// the talking NPCs' bubble, so people know it can be spoken to
	add_overlay(mutable_appearance('icons/mob/talk.dmi', "default2", ABOVE_MOB_LAYER))

/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/Destroy()
	if(prince)
		prince.tributes -= src
		prince.next_tribute = max(prince.next_tribute, world.time + prince.tribute_respawn)
	var/turf/T = get_turf(src)
	for(var/obj/item/I in contents - access_card)
		if(T)
			I.forceMove(T)
		else
			qdel(I)
	gift = null
	returned = null
	load.Cut()
	giver = null
	post = null
	return ..()

/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/Life()
	. = ..()
	if(!. || client || !prince)
		return
	switch(mode)
		if("post")
			if(!post)
				if(FlowTo(get_turf(prince)) || flow_failed)
					qdel(src)
				return
			if(loc != post && FlowTo(post) && !post.is_blocked_turf(TRUE))
				step_towards(src, post)
		if("to_prince")
			if(FlowTo(get_turf(prince)) || flow_failed)
				HandIn()
		if("to_giver")
			var/mob/living/M = giver?.Reachable(src)
			if(!M)
				Hold()
				return
			if(ReachPerson(M))
				Report(M)

/// At the Prince: deliveries are eaten, and a gift is judged.
/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/proc/HandIn()
	if(length(load))
		prince.Eat(load)
	if(!gift)
		mode = "post"
		return
	var/obj/item/judged = gift
	gift = null
	var/worth = prince.JudgeTribute(giver, judged)
	if(worth)
		report = pick(worth >= prince.tribute_worth ? prince.delighted_lines : prince.pleased_lines)
	else
		report = pick(prince.insulted_lines)
		returned = judged
	misted = FALSE
	mode = "to_giver"

/// Tells the giver what he thought, and hands back a worthless gift.
/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/proc/Report(mob/living/M)
	face_atom(M)
	say(report)
	if(returned)
		returned.forceMove(get_turf(src))
		M.put_in_hands(returned)
	returned = null
	report = null
	giver = null
	errand_to = null
	mode = "post"
	if(misted && post)
		addtimer(CALLBACK(src, PROC_REF(MistTo), post), 3 SECONDS)

/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/MistTo(turf/T)
	if(mode == "to_giver")
		misted = TRUE
	return ..()

/// The giver cannot be reached: the report and any gift wait with him until they next speak to a Tribute harvester.
/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/proc/Hold()
	if(returned)
		returned.forceMove(prince)
	giver?.pending += list(list(report, returned))
	returned = null
	report = null
	giver = null
	mode = "post"

/// Empty hand on help intent: any reports waiting first, then what it has to say.
/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/attack_hand(mob/living/carbon/human/M)
	if(M.a_intent != INTENT_HELP || !prince)
		return ..()
	INVOKE_ASYNC(src, PROC_REF(Converse), M)

/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/proc/Converse(mob/living/user)
	var/datum/prince_ledger/L = prince.Ledger(user)
	if(!L)
		return
	face_atom(user)
	for(var/list/held as anything in L.pending)
		say(held[1])
		var/obj/item/I = held[2]
		if(!QDELETED(I))
			I.forceMove(get_turf(src))
			user.put_in_hands(I)
	L.pending.Cut()
	var/list/options = list("How do I offer tribute?")
	if(L.request)
		options += "I lost my request."
	options += "Nothing."
	var/choice = tgui_input_list(user, "The twiglet tilts its acorn cap up at you.", name, options)
	if(QDELETED(src) || !user.Adjacent(src))
		return
	switch(choice)
		if("How do I offer tribute?")
			say("Hold out what you would give, kindly, and I will carry it to the Prince.")
			say("He likes a new thing. He does not like the same thing three times.")
		if("I lost my request.")
			if(L.request)
				prince.CancelRequest(L)
				say("Then it is forgotten. He will not forget that you forgot it.")

/// Help intent with an item: a finished request paper is turned in, a delivery is taken, anything else is tribute.
/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/attackby(obj/item/I, mob/living/user, params)
	if(user.a_intent != INTENT_HELP || !prince)
		return ..()
	face_atom(user)
	var/datum/prince_ledger/L = prince.Ledger(user)
	if(!L)
		return TRUE
	if(PrinceFoe(user, prince))
		say("The Prince does not take gifts from his Foes.")
		return TRUE
	if(istype(I, /obj/item/prince_request))
		TurnIn(I, L, user)
		return TRUE
	if(L.request?.state == "accepted" && TakeDelivery(I, L.request, user))
		return TRUE
	if(mode != "post" || gift)
		say("One thing at a time. I am still carrying the last.")
		return TRUE
	if(!user.transferItemToLoc(I, src))
		return TRUE
	gift = I
	giver = L
	mode = "to_prince"
	say("I will carry this to him.")
	return TRUE

/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/examine(mob/user)
	. = ..()
	. += span_notice("It holds out its hands. Help intent: speak with it, or offer it something for the Prince.")
	if(isobserver(user))
		. += span_notice("Errand: [mode][post ? "" : ", no post, going home"].")

