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

/// At spawn: a missing poster kind for each of the killed, then one of each kind somewhere on the walls of his first
/// ground, so the clues exist from the first minute.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/SeedNotices()
	for(var/i in 1 to killed.len)
		var/kind = "missing[i]"
		missing_subjects[kind] = killed[i]
		notice_kinds += kind
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
	/// One of his notice_kinds: "report", "ledger", "inventory", or a missing poster's "missing1" and on.
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
		if("ledger")
			name = "notice - a page"
			desc = "A page torn from a ledger and stuck to the wall with something dark."
		if("inventory")
			name = "notice - inventory"
			desc = "A butcher's stock list, the kind kept on a nail by the door."
		else
			icon_state = "missing"
			name = "notice - missing"
			desc = "A missing poster. The face has been drawn over in pencil, carefully, more than once."
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
	if(!distortion)
		return
	user << browse(distortion.NoticeHtml(kind), "window=bunnyman_notice;size=440x560")
	if(!(user in readers))
		readers += user
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(OnReaderMoved))
	if(ishuman(user))
		distortion.OnNoticeRead(src, user)

/obj/structure/sign/poster/bunnyman/attack_hand(mob/user)
	visible_message(span_notice("[user] rips [src] in a single, decisive motion!"))
	Rip()
	return TRUE

/// Torn down, by a player or by him. The remnant is his too, so it goes with him, and a fresh one goes up elsewhere.
/obj/structure/sign/poster/bunnyman/proc/Rip()
	playsound(loc, 'sound/items/poster_ripped.ogg', 100, TRUE)
	var/obj/structure/sign/poster/ripped/R = new(loc)
	R.pixel_x = pixel_x
	R.pixel_y = pixel_y
	if(distortion)
		distortion.Own(R)
	qdel(src)

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
		else
			var/datum/bunnyman_killed/K = missing_subjects[kind]
			body = {"<h2>MISSING</h2>
<p><b>[K.name]</b></p>
<p>[LookText(K)]</p>
<p>Last seen on the butcher's street, late. Did not come home.</p>
<p>If you saw anything that night, you saw it wrong. Please come forward anyway.</p>"}
	body = replacetext(body, "%ATTACKER%", attacker_name)
	body = replacetext(body, "%WEAPON%", weapon)
	return {"<html><head><title>Notice</title><style>
body { background: #d9cfb6; color: #2a2118; font-family: Georgia, serif; font-size: 15px; padding: 18px 24px; }
h2 { font-size: 20px; letter-spacing: 2px; border-bottom: 1px solid #6b5a42; margin: 0 0 12px 0; }
p { margin: 0 0 10px 0; line-height: 1.4; }
.circled { border: 2px solid #7a1c1c; border-radius: 50%; padding: 2px 8px; }
</style></head><body>[body]</body></html>"}
