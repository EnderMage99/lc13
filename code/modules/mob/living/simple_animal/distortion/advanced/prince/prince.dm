// The Prince on the advanced base: a Rat boss who lived off his brother's envelopes, killed him when they ran thin,
// and found his own way out paid for in the one he never opened. He is the slug inside his brother's golden head.
// He never moves. He raises a fort of root walls round himself, one ring more for every stage of his territory.
// Design: workspace/docs/lc13/distortions/PRINCE_DESIGN.md. Build plan: PRINCE_BUILD_PLAN.md beside it.
/mob/living/simple_animal/hostile/distortion/advanced/prince
	name = "The Prince"
	desc = "A golden bird's head, half sunk into the ground. Something green moves behind the beak."
	icon = 'ModularLobotomy/_Lobotomyicons/prince.dmi'
	icon_state = "prince_closed"
	icon_living = "prince_closed"
	maxHealth = 1500
	health = 1500
	pixel_x = -16
	base_pixel_x = -16
	fear_level = HE_LEVEL
	faction = list("neutral", "prince")
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	melee_damage_lower = 0
	melee_damage_upper = 0
	move_resist = MOVE_FORCE_OVERPOWERING
	wanders = FALSE
	leashed = FALSE
	egoist_names = list("Ezra Vale", "Milo Grieve", "Tobin Marsh", "Corvin Hale")
	gender = MALE
	/// How often Think() runs: the one place that checks caps and timers.
	var/think_interval = 2 SECONDS
	var/next_think = 0
	/// The rings of his fort, innermost first. See fort.dm.
	var/list/rings = list()
	/// Ring 1's distance from him in tiles, and how much further out each ring after it stands: 6 leaves 5 open tiles
	/// between two rings.
	var/ring_first = 3
	var/ring_step = 6
	/// Rings at most. He has one at stage 0 and a second at stage 1; past that he builds toll gates (see tolls.dm).
	var/max_rings = 2
	/// His worker harvesters. A dead one is replaced harvester_respawn later, one at a time.
	var/list/harvesters = list()
	var/harvester_respawn = 60 SECONDS
	var/harvesters_base = 4
	var/harvesters_per_stage = 3
	var/next_harvester = 0
	/// Shared flow maps his followers move on, by goal turf, and a count bumped whenever a solid piece goes up, which
	/// makes every map made before it stale.
	var/list/flows = list()
	var/fort_version = 0
	/// A map nobody has used for this long is dropped.
	var/flow_keep = 30 SECONDS

/mob/living/simple_animal/hostile/distortion/advanced/prince/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	BuildRings()
	while(length(harvesters) < HarvesterCap())
		SpawnHarvester()

/mob/living/simple_animal/hostile/distortion/advanced/prince/Teardown()
	if(torn_down)
		return
	// the parent deletes every piece first; the rings see torn_down set and regrow nothing
	..()
	QDEL_LIST(rings)
	QDEL_LIST(tolls)
	nurseries.Cut()
	node_routes.Cut()
	toll_routes.Cut()
	harvesters.Cut()
	flows.Cut()
	held_machines.Cut()
	lost_machines.Cut()
	foes.Cut()
	foe_summons.Cut()
	routes.Cut()
	path_tiles.Cut()
	// gifts held for players who could not be reached go with him
	for(var/datum/mind/M as anything in ledgers)
		var/datum/prince_ledger/L = ledgers[M]
		for(var/list/held as anything in L.pending)
			qdel(held[2])
	ledgers.Cut()
	tributes.Cut()
	quests_out.Cut()

/mob/living/simple_animal/hostile/distortion/advanced/prince/Move(atom/newloc, direct, glide_size_override)
	return FALSE

/mob/living/simple_animal/hostile/distortion/advanced/prince/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/distortion/advanced/prince/Life()
	. = ..()
	if(!. || torn_down || world.time < next_think)
		return
	next_think = world.time + think_interval
	Think()

/// Checks every cap and timer he has. Called every think_interval.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/Think()
	for(var/datum/prince_ring/R as anything in rings + tolls)
		R.Upkeep()
	if(length(harvesters) < HarvesterCap() && world.time >= next_harvester)
		SpawnHarvester()
		next_harvester = world.time + harvester_respawn
	TakeMachines()
	ReplanRoutes()
	FoeWaves()
	UpdateTributes()
	SendQuests()
	if(length(tolls) < TollCap() && world.time >= next_toll_search)
		BuildTolls()
	PruneFlows()

/mob/living/simple_animal/hostile/distortion/advanced/prince/OnStageChange(old_stage, new_stage)
	BuildRings()
	next_toll_search = 0

/// Vending machines he may hold: 2, and 2 more per stage.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/MachineCap()
	return 2 + 2 * territory.stage

/// Worker harvesters he keeps: harvesters_base, and harvesters_per_stage more for each territory stage.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/HarvesterCap()
	return harvesters_base + harvesters_per_stage * territory.stage

/// A new worker harvester beside him.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/SpawnHarvester()
	harvesters += SpawnFollower(/mob/living/simple_animal/hostile/prince_follower/harvester, NearTurf())

/// An open turf beside him, or his own if every side is blocked. Where his followers come out.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/NearTurf()
	for(var/dir in shuffle(GLOB.cardinals.Copy()))
		var/turf/side = get_step(src, dir)
		if(side && !side.is_blocked_turf(TRUE))
			return side
	return get_turf(src)

/// A harvester died. Its replacement comes harvester_respawn from now.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/HarvesterLost(mob/living/simple_animal/hostile/prince_follower/harvester/H)
	harvesters -= H
	next_harvester = max(next_harvester, world.time + harvester_respawn)

/// Spawns a follower that belongs to him: it is deleted with him. instant is passed on to a tower: no rise.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/SpawnFollower(follower_type, turf/T, instant = FALSE)
	var/mob/living/simple_animal/hostile/prince_follower/F = new follower_type(T, src, instant)
	Own(F)
	return F

/// His followers walk through him, so he never blocks the way to his own gates.
/mob/living/simple_animal/hostile/distortion/advanced/prince/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /mob/living/simple_animal/hostile/prince_follower))
		return TRUE

/// The shared flow map to goal, made now if none serves the requester. It may still be mapping when returned. wide
/// asks for the widest map, after a smaller one found no way round.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/GetFlow(turf/goal, mob/living/simple_animal/hostile/prince_follower/requester, wide = FALSE)
	var/datum/prince_flow/F = flows[goal]
	if(F && F.Covers(requester, src) && (!wide || F.range >= F.wide_range))
		return F
	F = PrinceNewFlow(goal, requester, fort_version, wide)
	flows[goal] = F
	return F

/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/PruneFlows()
	for(var/turf/T as anything in flows)
		var/datum/prince_flow/F = flows[T]
		if(F.version != fort_version || world.time > F.last_used + flow_keep)
			flows -= T
