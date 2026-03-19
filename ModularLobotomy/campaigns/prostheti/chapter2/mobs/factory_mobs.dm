// =============================================
// Prostheti Innovations — Chapter 2 Factory Mobs
// =============================================
// All enemy and ally mobs for the factory infiltration mission.
//
// DESIGN: Factory workers build tremor stacks on melee hits but use
// impossibly high burst threshold (999) so they NEVER trigger TremorBurst alone.
// Only Heavy's Ground Slam and Director's abilities use real burst thresholds
// (25+) that CAN detonate accumulated stacks.
//
// Tremor reference: apply_lc_tremor(stacks, tremorburst_threshold)
//   Each stack = 10% movespeed slowdown
//   TremorBurst at threshold = Knockdown (humans) or 5*stacks brute (mobs)
//   Source: code/datums/status_effects/debuffs.dm

// =============================================
// Factory Worker — Base Melee Mob
// =============================================
// Augmented factory workers, "walking product demonstrations."
// Dangerous in groups — 3 workers hitting same player build tremor fast.

/mob/living/simple_animal/hostile/prostheti/factory_worker
	name = "Factory Worker"
	desc = "An augmented factory worker with mechanical arms that hum with latent energy."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// TEMP
	icon_state = "clan_citzen"	// TEMP
	icon_living = "clan_citzen"	// TEMP
	maxHealth = 150
	health = 150
	melee_damage_lower = 8
	melee_damage_upper = 12
	melee_damage_type = RED_DAMAGE
	move_to_delay = 4
	faction = list("prostheti_competitor")
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	vision_range = 8
	a_intent = INTENT_HARM
	density = TRUE
	del_on_death = FALSE
	damage_coeff = list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2.0)

/// Applies tremor on each melee hit — stacks accumulate, threshold too high to self-burst.
/mob/living/simple_animal/hostile/prostheti/factory_worker/AttackingTarget(atom/attacked_target)
	. = ..()
	if(. && isliving(attacked_target))
		var/mob/living/victim = attacked_target
		victim.apply_lc_tremor(2, 999)

// =============================================
// Factory Worker — Heavy Variant
// =============================================
// Foremen with industrial-grade augments. Slower but hit harder.
// Ground Slam detonates accumulated player tremor.

/mob/living/simple_animal/hostile/prostheti/factory_worker/heavy
	name = "Factory Foreman"
	desc = "A hulking foreman with heavy industrial augments. The ground seems to tremble with each step."
	icon_state = "clan_citzen"	// TEMP — needs bulkier sprite
	icon_living = "clan_citzen"	// TEMP
	maxHealth = 250
	health = 250
	melee_damage_lower = 12
	melee_damage_upper = 18
	move_to_delay = 6
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2.0)

	/// Can act flag — blocks attacks during Ground Slam animation
	var/can_act = TRUE
	COOLDOWN_DECLARE(ground_slam_cooldown)

/mob/living/simple_animal/hostile/prostheti/factory_worker/heavy/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	// Ground Slam: 40% chance when off cooldown and target within 3 tiles
	if(COOLDOWN_FINISHED(src, ground_slam_cooldown) && prob(40) && isliving(attacked_target))
		var/mob/living/target = attacked_target
		if(get_dist(src, target) <= 3)
			INVOKE_ASYNC(src, PROC_REF(GroundSlam))
			return
	. = ..()
	if(. && isliving(attacked_target))
		var/mob/living/victim = attacked_target
		victim.apply_lc_tremor(3, 999)

/mob/living/simple_animal/hostile/prostheti/factory_worker/heavy/Move()
	if(!can_act)
		return FALSE
	return ..()

/// Ground Slam AoE — telegraphed tremor burst in 2-tile radius.
/mob/living/simple_animal/hostile/prostheti/factory_worker/heavy/proc/GroundSlam()
	can_act = FALSE
	COOLDOWN_START(src, ground_slam_cooldown, 12 SECONDS)

	// Telegraph — warning visuals on surrounding turfs
	var/list/affected_turfs = list()
	for(var/turf/T in range(2, src))
		affected_turfs += T
		new /obj/effect/temp_visual/cult/sparks(T)	// TEMP — needs ground crack warning visual

	// Windup animation
	animate(src, pixel_y = base_pixel_y + 8, time = 3)
	sleep(5)	// 0.5s telegraph

	// Slam down
	animate(src, pixel_y = base_pixel_y, time = 2)
	playsound(src, 'sound/effects/meteorimpact.ogg', 60, TRUE)

	// Apply damage and tremor to all non-faction mobs in range
	for(var/turf/T in affected_turfs)
		for(var/mob/living/victim in T)
			if(victim == src || (victim.faction & faction))
				continue
			victim.deal_damage(15, RED_DAMAGE, src, attack_type = ATTACK_TYPE_MELEE)
			victim.apply_lc_tremor(5, 25)
			if(victim.client)
				shake_camera(victim, 5, 2)

	can_act = TRUE

// =============================================
// Factory Director — Boss
// =============================================
// The competitor factory's director. Top-line augments, BLACK damage.
// Two abilities: Seismic Dash (gap closer + tremor burst) and
// Seismic Eruption (telegraphed AoE that force-bursts tremor).
// At 400 HP: execution trigger → seize Penny → Zwei rescue.

/mob/living/simple_animal/hostile/prostheti/factory_director
	name = "Factory Director"
	desc = "The competitor's director, clad in sleek corporate-grade augments that radiate an unsettling black energy."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// TEMP
	icon_state = "clan_citzen"	// TEMP — needs imposing boss sprite
	icon_living = "clan_citzen"	// TEMP
	maxHealth = 2400
	health = 2400
	melee_damage_lower = 15
	melee_damage_upper = 22
	melee_damage_type = BLACK_DAMAGE
	move_to_delay = 3
	faction = list("prostheti_competitor")
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	vision_range = 12
	a_intent = INTENT_HARM
	density = TRUE
	del_on_death = FALSE
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 0.3, PALE_DAMAGE = 1.5)

	/// Can act flag — blocks attacks during ability animations
	var/can_act = TRUE
	/// TRUE once health drops to 400 — stops all combat, begins execution sequence
	var/execution_triggered = FALSE
	/// Reference to Penny companion for execution sequence
	var/mob/living/simple_animal/hostile/prostheti/penny_companion/penny_target

	COOLDOWN_DECLARE(seismic_dash_cooldown)
	COOLDOWN_DECLARE(seismic_eruption_cooldown)

/mob/living/simple_animal/hostile/prostheti/factory_director/Move()
	if(!can_act || execution_triggered)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/prostheti/factory_director/AttackingTarget(atom/attacked_target)
	if(!can_act || execution_triggered)
		return
	if(!isliving(attacked_target))
		return ..()
	var/mob/living/target = attacked_target
	var/dist = get_dist(src, target)

	// Seismic Eruption: highest priority, 15s cooldown
	if(COOLDOWN_FINISHED(src, seismic_eruption_cooldown) && prob(35))
		INVOKE_ASYNC(src, PROC_REF(SeismicEruption))
		return

	// Seismic Dash: gap closer when 3-7 tiles away
	if(COOLDOWN_FINISHED(src, seismic_dash_cooldown) && dist >= 3 && dist <= 7)
		INVOKE_ASYNC(src, PROC_REF(SeismicDash), target)
		return

	// Normal melee
	. = ..()
	if(. && isliving(attacked_target))
		var/mob/living/victim = attacked_target
		victim.apply_lc_tremor(4, 999)

/// Checks for execution trigger after taking damage.
/mob/living/simple_animal/hostile/prostheti/factory_director/adjustBruteLoss(amount, updating_health, forced)
	. = ..()
	CheckExecutionTrigger()

/mob/living/simple_animal/hostile/prostheti/factory_director/adjustFireLoss(amount, updating_health, forced)
	. = ..()
	CheckExecutionTrigger()

/// If health is at or below 400, trigger the execution sequence.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/CheckExecutionTrigger()
	if(execution_triggered)
		return
	if(health <= 400)
		execution_triggered = TRUE
		INVOKE_ASYNC(src, PROC_REF(ExecutionSequence))

// =============================================
// Director Ability — Seismic Dash
// =============================================
// Dashes along a line to the target, dealing damage and tremor to
// everything in the path. Primary tremor detonator.

/// Seismic Dash — gap closer along getline() with trail damage.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/SeismicDash(mob/living/target)
	if(QDELETED(target) || target.stat >= DEAD)
		return
	can_act = FALSE
	COOLDOWN_START(src, seismic_dash_cooldown, 8 SECONDS)

	// Jump up
	animate(src, pixel_y = base_pixel_y + 16, time = 3)
	sleep(3)

	// Dash along line
	var/turf/target_turf = get_turf(target)
	var/list/dash_turfs = getline(get_turf(src), target_turf)
	for(var/turf/T in dash_turfs)
		if(T == get_turf(src))
			continue
		forceMove(T)
		new /obj/effect/temp_visual/cult/sparks(T)	// TEMP — needs seismic trail visual
		// Damage anything on the path
		for(var/mob/living/victim in T)
			if(victim == src || (victim.faction & faction))
				continue
			victim.deal_damage(20, RED_DAMAGE, src, attack_type = ATTACK_TYPE_MELEE)
			victim.apply_lc_tremor(6, 25)
		sleep(1)

	// Slam down at destination
	animate(src, pixel_y = base_pixel_y, time = 2)
	playsound(src, 'sound/effects/meteorimpact.ogg', 70, TRUE)

	// AoE at landing point
	for(var/mob/living/victim in range(1, src))
		if(victim == src || (victim.faction & faction))
			continue
		if(victim.client)
			shake_camera(victim, 5, 2)

	can_act = TRUE

// =============================================
// Director Ability — Seismic Eruption
// =============================================
// Telegraphed AoE — warning markers appear on turfs, then
// anyone standing on them gets launched and has their tremor force-burst.

/// Seismic Eruption — telegraphed AoE that force-bursts accumulated tremor.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/SeismicEruption()
	can_act = FALSE
	COOLDOWN_START(src, seismic_eruption_cooldown, 15 SECONDS)

	say("The ground remembers every step.")

	// Pick target turfs: 3-4 random in view + 3-4 near each visible enemy
	var/list/warning_turfs = list()
	var/list/view_turfs = list()
	for(var/turf/T in view(5, src))
		view_turfs += T
	for(var/i in 1 to rand(3, 4))
		if(length(view_turfs))
			warning_turfs |= pick(view_turfs)

	for(var/mob/living/enemy in view(5, src))
		if(enemy == src || (enemy.faction & faction))
			continue
		for(var/j in 1 to rand(3, 4))
			var/turf/near_turf = get_step(enemy, pick(GLOB.alldirs))
			if(near_turf)
				warning_turfs |= near_turf

	// Place warning markers
	var/list/warning_visuals = list()
	for(var/turf/T in warning_turfs)
		var/obj/effect/temp_visual/cult/sparks/warning = new(T)	// TEMP — needs eruption warning visual
		warning_visuals += warning

	// Telegraph delay — 1.5 seconds for players to react
	sleep(15)

	// Detonation — process each warning turf
	playsound(src, 'sound/effects/meteorimpact.ogg', 80, TRUE)
	for(var/turf/T in warning_turfs)
		for(var/mob/living/victim in T)
			if(victim == src || (victim.faction & faction))
				continue
			// Launch victim into air
			animate(victim, pixel_y = victim.base_pixel_y + 32, time = 3)
			// Force-burst tremor if they have stacks
			var/datum/status_effect/stacking/lc_tremor/tremor = victim.has_status_effect(/datum/status_effect/stacking/lc_tremor)
			if(tremor)
				tremor.TremorBurst()
			// Landing damage
			victim.deal_damage(10, RED_DAMAGE, src, attack_type = ATTACK_TYPE_MELEE)
			if(victim.client)
				shake_camera(victim, 7, 3)
			// Bring back down after a brief delay
			addtimer(CALLBACK(src, PROC_REF(LandVictim), victim), 3)

	can_act = TRUE

/// Helper to animate a victim back to ground level after Seismic Eruption launch.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/LandVictim(mob/living/victim)
	if(!QDELETED(victim))
		animate(victim, pixel_y = victim.base_pixel_y, time = 3)

// =============================================
// Director — Execution Sequence
// =============================================
// Triggers at 400 HP. Director dashes to Penny, forces her down,
// then signals for the Zwei rescue cutscene.

/// Execution sequence — seize Penny and trigger Zwei rescue.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/ExecutionSequence()
	can_act = FALSE

	// Find Penny companion on our z-level
	if(!penny_target)
		for(var/mob/living/simple_animal/hostile/prostheti/penny_companion/P in GLOB.mob_list)
			if(P.z == src.z)
				penny_target = P
				break
	if(!penny_target)
		SEND_SIGNAL(src, COMSIG_DIRECTOR_EXECUTION)
		return

	// Dash to Penny
	var/list/dash_turfs = getline(get_turf(src), get_turf(penny_target))
	for(var/turf/T in dash_turfs)
		if(T == get_turf(src))
			continue
		forceMove(T)
		sleep(1)

	// Seize Penny — force her downed
	face_atom(penny_target)
	penny_target.GoDown()
	say("You brought children into my factory. Let me show you what happens to trespassers.")

	// GODMODE during windup — fight is meant to be unwinnable
	status_flags |= GODMODE

	// 3-second execution windup
	animate(src, pixel_y = base_pixel_y + 12, time = 5)	// Arm raised
	sleep(30)

	// Signal the mission datum to trigger Zwei rescue
	SEND_SIGNAL(src, COMSIG_DIRECTOR_EXECUTION)

// =============================================
// Zwei Lead Fixer — Rescue Squad Leader
// =============================================
// 800 HP, high damage. Kills the director during the rescue cutscene.
// Overwhelmingly strong — "the adults have arrived."

/mob/living/simple_animal/hostile/prostheti/zwei_lead
	name = "Zwei Lead Fixer"
	desc = "A professional Zwei Association fixer. Efficient. Dangerous."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// TEMP — needs Zwei Director sprite
	icon_state = "clan_citzen"	// TEMP
	icon_living = "clan_citzen"	// TEMP
	maxHealth = 800
	health = 800
	melee_damage_lower = 35
	melee_damage_upper = 50
	melee_damage_type = RED_DAMAGE
	move_to_delay = 2
	faction = list("zwei", "neutral")
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	vision_range = 12
	a_intent = INTENT_HARM
	density = TRUE
	del_on_death = FALSE

// =============================================
// Zwei Standard Fixer — Rescue Squad Member
// =============================================
// 500 HP each, × 3 spawned. Clean up remaining factory workers.
// Intentionally overpowered — workers die in 2-3 hits.

/mob/living/simple_animal/hostile/prostheti/zwei_fixer
	name = "Zwei Fixer"
	desc = "A standard Zwei Association fixer, moving with practiced precision."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// TEMP — needs Zwei Fixer sprite
	icon_state = "clan_citzen"	// TEMP
	icon_living = "clan_citzen"	// TEMP
	maxHealth = 500
	health = 500
	melee_damage_lower = 25
	melee_damage_upper = 35
	melee_damage_type = RED_DAMAGE
	move_to_delay = 3
	faction = list("zwei", "neutral")
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	vision_range = 10
	a_intent = INTENT_HARM
	density = TRUE
	del_on_death = FALSE
