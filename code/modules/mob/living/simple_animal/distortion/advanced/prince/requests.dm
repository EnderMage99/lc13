// Requests. A player with quest_favour or more and no request is sought out by a Quest harvester, which hands them a
// paper from the Prince. On the paper they accept or reject it; rejecting costs favour, more each time. Once
// accepted it can be cancelled on the paper or by telling a Tribute harvester it was lost, which also costs favour.
// A finished paper handed to a Tribute harvester earns favour. For now every request is a delivery: bring him so
// many of one thing, one at a time or in a bag, stacks counting by their size.

/mob/living/simple_animal/hostile/distortion/advanced/prince
	/// Favour at which Quest harvesters start coming.
	var/quest_favour = 6
	/// Favour for a finished request, and lost for giving one up after accepting it.
	var/request_reward = 6
	var/give_up_cost = 3
	/// Wait before the next Quest harvester: after one is finished, and after one is rejected or given up.
	var/quest_wait_done = 30 SECONDS
	var/quest_wait_given_up = 3 MINUTES
	/// How many of the item a delivery asks for.
	var/delivery_amount = 5
	/// The Quest harvester out for each ledger.
	var/list/quests_out = list()

/// Sends a Quest harvester to every player who has earned one and can be reached.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/SendQuests()
	for(var/datum/mind/M as anything in ledgers)
		var/datum/prince_ledger/L = ledgers[M]
		if(L.favour < quest_favour || L.request || world.time < L.next_quest || quests_out[L] || !L.Reachable(src))
			continue
		var/mob/living/simple_animal/hostile/prince_follower/messenger/quest/Q = SpawnFollower(/mob/living/simple_animal/hostile/prince_follower/messenger/quest, NearTurf())
		Q.for_ledger = L
		quests_out[L] = Q

/// A new request for L, offered on a paper at T. Null if there is nothing he could ask for.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/MakeRequest(datum/prince_ledger/L, turf/T)
	var/item_path = DeliveryItem()
	if(!item_path)
		return null
	var/datum/prince_request/R = new
	R.prince = src
	R.ledger = L
	R.kind = "delivery"
	R.item_type = item_path
	var/obj/item/sample = item_path
	R.item_name = initial(sample.name)
	R.needed = delivery_amount
	L.request = R
	var/obj/item/prince_request/paper = new(T)
	paper.request = R
	R.paper = paper
	return paper

/// Something a vending machine on his z-level still has in stock and that he does not hold, so it can be found.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/DeliveryItem()
	var/list/choices = list()
	for(var/obj/machinery/vending/V in GLOB.machines)
		if(V.z != z || held_machines[V])
			continue
		for(var/datum/data/vending_product/R in V.product_records)
			if(R.amount > 0 && ispath(R.product_path, /obj/item))
				choices |= R.product_path
	return length(choices) ? pick(choices) : null

/// Ends L's request, changes their favour by favour_change, and holds the next Quest harvester back for wait.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/EndRequest(datum/prince_ledger/L, favour_change, wait)
	var/datum/prince_request/R = L.request
	L.request = null
	L.AdjustFavour(favour_change)
	L.next_quest = world.time + wait
	if(R)
		R.ledger = null
		QDEL_NULL(R.paper)

/// Rejected before accepting: it costs one more favour each time since the last finished request.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/RejectRequest(datum/prince_ledger/L)
	L.rejections++
	EndRequest(L, -L.rejections, quest_wait_given_up)

/// Given up after accepting, on the paper or to a Tribute harvester.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/CancelRequest(datum/prince_ledger/L)
	EndRequest(L, -give_up_cost, quest_wait_given_up)

/// A finished paper turned in.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/CompleteRequest(datum/prince_ledger/L)
	L.rejections = 0
	EndRequest(L, request_reward, quest_wait_done)

// The request.

/datum/prince_request
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/prince
	var/datum/prince_ledger/ledger
	var/obj/item/prince_request/paper
	/// "delivery" for now.
	var/kind
	/// "offered", "accepted" or "complete".
	var/state = "offered"
	/// What a delivery asks for, exactly that type, and how many.
	var/item_type
	var/item_name
	var/needed = 0
	var/have = 0

/datum/prince_request/proc/Progress(amount)
	have = min(needed, have + amount)
	if(have >= needed)
		state = "complete"

// The paper.

/obj/item/prince_request
	name = "request from the Prince"
	desc = "A sheet of bark-paper with a gold leaf pressed into the corner, its edges sticky with green goop. Use it in hand to read it."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper_words"
	color = "#f0e0b0"
	w_class = WEIGHT_CLASS_TINY
	var/datum/prince_request/request

/obj/item/prince_request/Destroy()
	if(request?.paper == src)
		request.paper = null
	request = null
	return ..()

/obj/item/prince_request/examine(mob/user)
	. = ..()
	if(!request)
		. += span_notice("The ink has faded. It asks for nothing now.")
		return
	. += span_notice("He wants [request.needed] [request.item_name]. [request.have] of [request.needed] given.")
	if(request.state == "complete")
		. += span_notice("It is done. Hand it to one of his Tribute harvesters.")

/obj/item/prince_request/attack_self(mob/user)
	ShowTo(user)

/// Opens the paper for user: a parchment page in a frame of green goop, with buttons for whatever they may do now.
/obj/item/prince_request/proc/ShowTo(mob/user)
	user << browse(PageHtml(user), "window=prince_request;size=420x520")

/obj/item/prince_request/proc/PageHtml(mob/user)
	var/body
	if(!request)
		body = "<p class='faded'>The ink has faded. It asks for nothing now.</p>"
	else
		var/percent = request.needed ? round(100 * request.have / request.needed) : 0
		body = {"<p>Bring me <b>[request.needed] [request.item_name]</b>.</p>
<p>Hand them to my Tribute harvesters at the gates, one at a time or in a bag.</p>
<div class='bar'><div class='fill' style='width:[percent]%'></div><span>[request.have] / [request.needed]</span></div>"}
		var/owner = request.ledger?.mind && request.ledger.mind == user.mind
		if(!owner)
			body += "<p class='note'>This request was not given to you.</p>"
		else
			switch(request.state)
				if("offered")
					body += {"<div class='buttons'><a class='btn good' href='?src=[REF(src)];action=accept'>Accept</a>
<a class='btn bad' href='?src=[REF(src)];action=reject'>Reject, at a cost</a></div>"}
				if("accepted")
					body += "<div class='buttons'><a class='btn bad' href='?src=[REF(src)];action=cancel'>Give up, at a cost</a></div>"
				if("complete")
					body += "<p class='note done'>It is done. Hand this paper to one of my Tribute harvesters.</p>"
	return {"<html><head><meta charset='utf-8'><title>A Request from the Prince</title><style>
body { margin: 0; padding: 22px; background: #1c140c; font-family: Georgia, serif; }
.frame { position: relative; padding: 34px 30px 26px 30px; color: #2a1d10; font-size: 15px; line-height: 1.45;
	background: radial-gradient(ellipse at 30% 20%, #f3ead2 0%, #e4d6b0 60%, #cdb98a 100%);
	border: 9px solid #4fae34; border-radius: 26px 14px 30px 12px / 14px 28px 12px 30px;
	box-shadow: 0 0 0 3px #2f7a20, inset 0 0 0 3px #2f7a20, inset 0 0 26px rgba(79, 174, 52, 0.45), 0 0 18px #4fae34; }
.drip { position: absolute; top: -9px; width: 12px; background: #4fae34; border-radius: 0 0 8px 8px;
	box-shadow: 2px 0 0 #2f7a20, -2px 0 0 #2f7a20, 0 2px 0 #2f7a20; }
.drip:after { content: ''; position: absolute; left: 3px; top: 4px; width: 3px; height: 40%; background: #9be07a;
	border-radius: 2px; }
.seal { position: absolute; right: 18px; top: 16px; width: 44px; height: 44px; border-radius: 50%;
	background: radial-gradient(circle at 35% 35%, #ffe88c, #d9a520 55%, #8f6410); box-shadow: 0 0 0 2px #6b4a10;
	color: #5a3a08; font-size: 22px; font-weight: bold; text-align: center; line-height: 44px; }
h1 { margin: 0 56px 16px 0; font-size: 21px; letter-spacing: 1px; color: #6b4a10;
	text-shadow: 0 1px 0 #f6d670; border-bottom: 2px solid #4fae34; padding-bottom: 6px; }
p { margin: 0 0 11px 0; }
.bar { position: relative; height: 22px; margin: 14px 0 18px 0; background: #2c1d10; border: 2px solid #22150a;
	border-radius: 11px; overflow: hidden; box-shadow: inset 0 2px 4px #000; }
.fill { height: 100%; background: linear-gradient(90deg, #3a8a26, #6cc848 45%, #f0c440); border-radius: 9px; }
.bar span { position: absolute; left: 0; right: 0; top: 2px; text-align: center; color: #fff4c8; font-weight: bold;
	text-shadow: 0 1px 2px #000; }
.buttons { text-align: center; margin-top: 18px; }
.btn { display: inline-block; margin: 0 6px; padding: 7px 16px; border-radius: 14px; text-decoration: none;
	font-weight: bold; color: #fff4c8; border: 2px solid #22150a; box-shadow: inset 0 -3px 0 rgba(0, 0, 0, 0.3); }
.good { background: #4fae34; }
.bad { background: #8a3a24; }
.note { font-style: italic; color: #5e4024; }
.done { color: #2f7a20; font-weight: bold; }
.faded { font-style: italic; color: #8a7a5a; }
</style></head><body><div class='frame'>
<div class='drip' style='left:38px;height:26px'></div><div class='drip' style='left:96px;height:16px'></div>
<div class='drip' style='left:170px;height:34px'></div><div class='drip' style='left:236px;height:20px'></div>
<div class='drip' style='left:300px;height:12px'></div>
<div class='seal'>P</div><h1>By the Prince's Word</h1>[body]</div></body></html>"}

/// The buttons. Only the one it was given to may press them, holding it or standing by it.
/obj/item/prince_request/Topic(href, href_list)
	. = ..()
	if(!usr || (loc != usr && !Adjacent(usr)))
		return
	if(!request?.ledger || request.ledger.mind != usr.mind || !request.prince)
		return
	var/datum/prince_ledger/L = request.ledger
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/P = request.prince
	switch(href_list["action"])
		if("accept")
			if(request.state == "offered")
				request.state = "accepted"
				ShowTo(usr)
		if("reject")
			if(request.state == "offered")
				usr << browse(null, "window=prince_request")
				P.RejectRequest(L)
		if("cancel")
			if(request.state == "accepted")
				usr << browse(null, "window=prince_request")
				P.CancelRequest(L)

// Turning in, and deliveries, at a Tribute harvester.

/// A finished paper of theirs earns the reward. Anything else is handed back with a word.
/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/proc/TurnIn(obj/item/prince_request/paper, datum/prince_ledger/L, mob/living/user)
	if(paper.request != L.request || !L.request)
		say("That is not your request to give me.")
		return
	if(L.request.state != "complete")
		say("It is not done yet. [L.request.have] of [L.request.needed].")
		return
	prince.CompleteRequest(L)
	say("Done, and done well. He will remember this.")

/// Takes what an accepted delivery asks for from I: I itself, or what is inside it if it is a bag or box. A stack
/// counts by its size, and only what is still needed comes off it. TRUE if anything was taken.
/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/proc/TakeDelivery(obj/item/I, datum/prince_request/R, mob/living/user)
	var/taken = 0
	if(I.type == R.item_type)
		taken = TakeOne(I, R, user)
	else
		var/datum/component/storage/S = I.GetComponent(/datum/component/storage)
		if(!S)
			return FALSE
		for(var/obj/item/X in S.real_location())
			if(R.have >= R.needed)
				break
			if(X.type == R.item_type)
				taken += TakeOne(X, R, user, I)
	if(!taken)
		return FALSE
	if(mode == "post")
		mode = "to_prince"
	if(R.state == "complete")
		say("That is all of it. Bring me the paper.")
	else
		say("For the Prince. [R.have] of [R.needed].")
	return TRUE

/// Takes one item, or as much of a stack as is still needed, toward R. From a bag if bag is given. Returns the count.
/mob/living/simple_animal/hostile/prince_follower/messenger/tribute/proc/TakeOne(obj/item/X, datum/prince_request/R, mob/living/user, obj/item/bag)
	var/still = R.needed - R.have
	if(still <= 0)
		return 0
	var/count = 1
	if(istype(X, /obj/item/stack))
		var/obj/item/stack/stack = X
		count = stack.get_amount()
		if(count > still)
			// only what is needed comes off; the rest stays where it was
			var/obj/item/stack/part = stack.split_stack(null, still)
			if(!part)
				return 0
			part.forceMove(src)
			load += part
			R.Progress(still)
			return still
	if(bag)
		if(!SEND_SIGNAL(bag, COMSIG_TRY_STORAGE_TAKE, X, src))
			return 0
	else if(!user.transferItemToLoc(X, src))
		return 0
	load += X
	R.Progress(count)
	return count

// Quest harvesters.

/mob/living/simple_animal/hostile/prince_follower/messenger/quest
	name = "messenger twiglet"
	desc = "A twiglet with a roll of bark-paper under one arm, looking for someone."
	color = "#b8e890"
	/// Whose request it carries, and whether it has handed it over.
	var/datum/prince_ledger/for_ledger
	var/handed = FALSE

/mob/living/simple_animal/hostile/prince_follower/messenger/quest/Destroy()
	if(prince && for_ledger)
		prince.quests_out -= for_ledger
	for_ledger = null
	return ..()

/// To the player, hand over the paper, then home to him and gone. If they cannot be reached it goes home and he
/// sends another later.
/mob/living/simple_animal/hostile/prince_follower/messenger/quest/Life()
	. = ..()
	if(!. || client || !prince)
		return
	var/mob/living/M = for_ledger?.Reachable(src)
	if(handed || !M || for_ledger.request)
		if(FlowTo(get_turf(prince)) || flow_failed)
			qdel(src)
		return
	if(!ReachPerson(M))
		return
	handed = TRUE
	face_atom(M)
	var/obj/item/prince_request/paper = prince.MakeRequest(for_ledger, get_turf(src))
	if(!paper)
		say("He could not think of anything he wanted. Imagine that.")
		for_ledger.next_quest = world.time + prince.quest_wait_given_up
		return
	M.put_in_hands(paper)
	say("From the Prince. Read it, and answer him.")
