// Foe of the Prince. Striking at his walls, gates, towers, taps or tap sites makes you one. While any Foe stands on
// his ground he sends a wave of summons every foe_wave_interval, split evenly between the Foes there, and larger by
// foe_wave_scale for each Foe past the first. The summons chase any Foe they see, and go home once no living Foe is
// left on his ground (see followers.dm). The status ends after foe_decay spent off his ground.

/mob/living/simple_animal/hostile/distortion/advanced/prince
	/// Everyone carrying the Foe status for him.
	var/list/foes = list()
	/// Each summon out in a wave, with the Foe it was first sent after. Counted against foe_summon_cap.
	var/list/foe_summons = list()
	var/foe_wave_interval = 30 SECONDS
	var/next_foe_wave = 0
	/// A wave for one Foe, and how much larger it gets for each Foe past the first.
	var/foe_wave_base = 4
	var/foe_wave_scale = 0.75
	/// Wave summons out at once, at most. The fort's own call for help does not count.
	var/foe_summon_cap = 30

/// Makes L a Foe of the Prince, or starts their time off his ground over if they already are.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/MakeFoe(mob/living/L)
	if(!isliving(L) || istype(L, /mob/living/simple_animal/hostile/prince_follower) || L == src)
		return
	var/datum/status_effect/prince_foe/F = L.has_status_effect(/datum/status_effect/prince_foe)
	if(F)
		F.Restrike()
		return
	L.apply_status_effect(/datum/status_effect/prince_foe, src)
	// a Foe loses all the favour they had
	var/datum/prince_ledger/ledger = Ledger(L, FALSE)
	ledger?.AdjustFavour(-ledger.favour)

/// Foes standing on his ground and still alive.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/FoesInside()
	. = list()
	for(var/mob/living/L as anything in foes)
		if(L.stat != DEAD && territory.Contains(get_turf(L)))
			. += L

/// Sends a wave if it is time and any Foe is on his ground: dealt out one summon at a time to each Foe in turn,
/// from a random one, so the split is even and the leftovers land on different Foes. Summons for a Foe nearer one of
/// his nurseries than him ride there together.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/FoeWaves()
	if(world.time < next_foe_wave)
		return
	var/list/inside = FoesInside()
	var/count = length(inside)
	if(!count)
		return
	next_foe_wave = world.time + foe_wave_interval
	var/troops = round(foe_wave_base * (1 + foe_wave_scale * (count - 1)))
	troops = min(troops, foe_summon_cap - length(foe_summons))
	var/start = rand(1, count)
	var/list/riding = list()
	for(var/i in 0 to troops - 1)
		var/mob/living/foe = inside[(start + i - 1) % count + 1]
		var/summon_type = ISODD(i) ? /mob/living/simple_animal/hostile/prince_follower/summon/ranged : /mob/living/simple_animal/hostile/prince_follower/summon
		var/mob/living/simple_animal/hostile/prince_follower/summon/S = SpawnFollower(summon_type, NearTurf())
		S.SetQuarry(foe)
		foe_summons[S] = foe
		var/atom/node = NodeNear(foe)
		if(node == src)
			continue
		if(!riding[node])
			riding[node] = list()
		riding[node] += S
	for(var/obj/structure/prince_nursery/N as anything in riding)
		Ride(riding[N], src, N)

/// A Foe's status ended. Summons stop going after them on their own next tick.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/ReleaseFoe(mob/living/L)
	foes -= L

/// Whether L carries the Foe status for P.
/proc/PrinceFoe(mob/living/L, mob/living/simple_animal/hostile/distortion/advanced/prince/P)
	if(!isliving(L) || !P)
		return FALSE
	// has_status_effect() returns FALSE, not null, when there is none
	var/datum/status_effect/prince_foe/F = L.has_status_effect(/datum/status_effect/prince_foe)
	return F && F.prince == P

// The status itself. Its alert turns red while its owner stands on his ground.

/datum/status_effect/prince_foe
	id = "prince_foe"
	duration = -1
	tick_interval = 1 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/prince_foe
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/prince
	/// Time off his ground that ends it, and the time spent off it so far. Stepping back on starts it over.
	var/foe_decay = 2 MINUTES
	var/outside_time = 0
	/// Set each tick so the alert only changes when the edge is crossed.
	var/inside = FALSE

/atom/movable/screen/alert/status_effect/prince_foe
	name = "Foe of the Prince"
	desc = "You struck at what is his. His household comes for you on his ground, and chases you wherever it can see you. Stay off his ground for two minutes and he forgets you."
	icon = 'ModularLobotomy/_Lobotomyicons/prince_alerts.dmi'
	icon_state = "foe"

/datum/status_effect/prince_foe/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/distortion/advanced/prince/new_prince)
	. = ..()
	if(!.)
		return
	if(!new_prince)
		qdel(src)
		return
	prince = new_prince
	prince.foes |= owner
	RegisterSignal(prince, COMSIG_PARENT_QDELETING, PROC_REF(OnPrinceDeleted))
	to_chat(owner, span_userdanger("You have made yourself a Foe of the Prince."))
	UpdateAlert(TRUE)

/datum/status_effect/prince_foe/on_remove()
	if(prince)
		UnregisterSignal(prince, COMSIG_PARENT_QDELETING)
		prince.ReleaseFoe(owner)
		to_chat(owner, span_notice("The Prince has forgotten you, for now."))
	prince = null
	return ..()

/datum/status_effect/prince_foe/proc/OnPrinceDeleted(datum/source)
	SIGNAL_HANDLER
	prince = null
	qdel(src)

/// Starts its time off his ground over.
/datum/status_effect/prince_foe/proc/Restrike()
	outside_time = 0

/// A dead Foe counts as off his ground, so the status runs out.
/datum/status_effect/prince_foe/proc/Inside()
	return prince && owner.stat != DEAD && prince.territory?.Contains(get_turf(owner))

/datum/status_effect/prince_foe/proc/UpdateAlert(force = FALSE)
	var/now_inside = Inside()
	if(!force && now_inside == inside)
		return
	inside = now_inside
	if(linked_alert)
		linked_alert.icon_state = inside ? "foe_inside" : "foe"

/datum/status_effect/prince_foe/tick()
	UpdateAlert()
	if(inside)
		outside_time = 0
		return
	// tick_interval holds the next tick's time once running; initial() is the interval itself
	outside_time += initial(tick_interval)
	if(outside_time >= foe_decay)
		qdel(src)
