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
// Seismic Eruption Warning — telegraphed ground marker
// =============================================

/obj/effect/temp_visual/seismic_warning
	icon = 'icons/effects/effects.dmi'
	icon_state = "beetillery"
	duration = 1.5 SECONDS

/obj/effect/temp_visual/seismic_impact
	name = "seismic burst"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "beamout"
	pixel_x = -32
	base_pixel_x = -32
	color = "#FFD700"
	randomdir = FALSE
	duration = 4.2
	layer = POINT_LAYER

// =============================================
// Factory Worker — Base Melee Mob
// =============================================
// Augmented factory workers, "walking product demonstrations."
// Dangerous in groups — 3 workers hitting same player build tremor fast.

/mob/living/simple_animal/hostile/prostheti/factory_worker
	name = "Factory Worker"
	desc = "An augmented factory worker with mechanical arms that hum with latent energy."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'	// TEMP
	icon_state = "rat_pipe"	// TEMP
	icon_living = "rat_pipe"	// TEMP
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
	del_on_death = TRUE
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
	icon_state = "rat_hammer"	// TEMP — needs bulkier sprite
	icon_living = "rat_hammer"	// TEMP
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
	walk(src, 0)	// Cancel any queued walk_to movement
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

	// Impact effects on every affected turf
	for(var/turf/FX in affected_turfs)
		new /obj/effect/temp_visual/smash_effect(FX)

	// Apply damage and tremor to all non-faction mobs in range
	var/list/been_hit = list()
	for(var/turf/T in affected_turfs)
		for(var/mob/living/victim in HurtInTurf(T, been_hit, 15, RED_DAMAGE, check_faction = TRUE, attack_type = ATTACK_TYPE_MELEE))
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
	icon_state = "stone_guard"	// TEMP — needs imposing boss sprite
	icon_living = "stone_guard"	// TEMP
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
	ranged = TRUE
	projectiletype = null
	minimum_distance = 1
	simple_mob_flags = SILENCE_RANGED_MESSAGE

	/// Can act flag — blocks attacks during ability animations
	var/can_act = TRUE
	/// TRUE once health drops to 400 — stops all combat, begins execution sequence
	var/execution_triggered = FALSE
	/// Reference to Penny companion for execution sequence
	var/mob/living/simple_animal/hostile/ui_npc/penny_companion/penny_target

	COOLDOWN_DECLARE(borrowed_time_cooldown)
	COOLDOWN_DECLARE(seismic_eruption_cooldown)
	/// Turf positions for Borrowed Time teleport (from boss_teleport landmarks)
	var/list/turf/teleport_spots = list()

/mob/living/simple_animal/hostile/prostheti/factory_director/Move()
	if(!can_act || execution_triggered)
		return FALSE
	return ..()

/// OpenFire — triggers abilities at range (Seismic Eruption + Borrowed Time).
/mob/living/simple_animal/hostile/prostheti/factory_director/OpenFire(atom/A)
	if(!can_act || execution_triggered || !isliving(A))
		return

	// Seismic Eruption: highest priority
	if(COOLDOWN_FINISHED(src, seismic_eruption_cooldown) && prob(35))
		INVOKE_ASYNC(src, PROC_REF(SeismicEruption))
		return

	// Borrowed Time: teleport-dash at any range
	if(COOLDOWN_FINISHED(src, borrowed_time_cooldown) && length(teleport_spots) && prob(35))
		INVOKE_ASYNC(src, PROC_REF(BorrowedTime))
		return

/// Melee — applies tremor stacks, can trigger Borrowed Time mid-combat.
/mob/living/simple_animal/hostile/prostheti/factory_director/AttackingTarget(atom/attacked_target)
	if(!can_act || execution_triggered)
		return
	// Borrowed Time can trigger from melee
	if(COOLDOWN_FINISHED(src, borrowed_time_cooldown) && length(teleport_spots) && isliving(attacked_target) && prob(20))
		INVOKE_ASYNC(src, PROC_REF(BorrowedTime))
		return
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
// Director Ability — Borrowed Time
// =============================================
// Teleports to a landmark, picks a target, dashes at them with 3x3 AoE
// per step + eruption tile seeds. Repeats 3 times then goes on cooldown.
// Themed around T Corp's time-as-currency: the director spends stored
// time for bursts of inhuman speed.

/// Borrowed Time — 3x teleport-dash combo.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/BorrowedTime()
	can_act = FALSE
	COOLDOWN_START(src, borrowed_time_cooldown, 15 SECONDS)

	say(pick(
		"Time is money — and I can afford to spend.",
		"You think you can keep up with borrowed seconds?",
		"The clock runs faster for those who can pay.",
	))

	for(var/dash_num in 1 to 3)
		if(stat >= DEAD || execution_triggered)
			break

		// --- Pick target BEFORE teleporting (view from current position) ---
		var/mob/living/dash_target
		var/best_dist = INFINITY
		for(var/mob/living/enemy in view(12, src))
			if(enemy == src || faction_check_mob(enemy))
				continue
			if(enemy.stat >= DEAD)
				continue
			var/d = get_dist(src, enemy)
			if(d < best_dist)
				best_dist = d
				dash_target = enemy
		if(!dash_target)
			break

		// --- Teleport to a random landmark ---
		var/turf/old_turf = get_turf(src)
		var/turf/dest_turf = pick(teleport_spots)
		if(!dest_turf)
			break

		// Afterimage at old position
		playsound(old_turf, 'sound/effects/hokma_meltdown_short.ogg', 25, TRUE)
		new /obj/effect/temp_visual/decoy(old_turf, src)

		// Line of afterimages between old and new position
		var/list/line_turfs = getline(old_turf, dest_turf)
		for(var/i in 1 to length(line_turfs))
			var/turf/LT = line_turfs[i]
			var/obj/effect/temp_visual/decoy/ghost = new(LT, src)
			ghost.alpha = min(150 + i * 15, 255)
			animate(ghost, alpha = 0, time = 2 + i * 2)

		// Teleport
		forceMove(dest_turf)
		playsound(dest_turf, 'sound/effects/hokma_meltdown_short.ogg', 25, TRUE)

		// --- 1.5 second wind-up ---
		face_atom(dash_target)
		do_shaky_animation(1.5)
		sleep(15)

		if(stat >= DEAD || execution_triggered || QDELETED(dash_target))
			break

		// --- Dash toward target via getline, always exactly 5 tiles (unless wall) ---
		var/turf/start_turf = get_turf(src)
		var/turf/target_turf = get_turf(dash_target)
		// Build a line through the target and extend past it
		var/list/full_line = getline(start_turf, target_turf)
		// Extend the line past the target by continuing in the same direction
		if(length(full_line) >= 2)
			var/turf/second_last = full_line[length(full_line) - 1]
			var/turf/last = full_line[length(full_line)]
			var/extend_dir = get_dir(second_last, last)
			if(extend_dir)
				var/turf/extend_turf = last
				for(var/ext in 1 to 10)	// Add extra turfs past target
					extend_turf = get_step(extend_turf, extend_dir)
					if(!extend_turf)
						break
					full_line += extend_turf
		// Remove self turf, then cap at 5 steps
		full_line -= start_turf
		var/list/dash_turfs = list()
		for(var/step_i in 1 to min(5, length(full_line)))
			dash_turfs += full_line[step_i]

		var/list/hit_mobs = list()
		for(var/turf/T in dash_turfs)
			if(isclosedturf(T))
				break
			if(stat >= DEAD || execution_triggered)
				break
			sleep(1)
			forceMove(T)
			playsound(T, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, FALSE, 4)
			// 3x3 AoE damage around current position
			for(var/turf/open/AT in range(1, src))
				new /obj/effect/temp_visual/smash_effect(AT)
				hit_mobs = HurtInTurf(AT, hit_mobs, 20, RED_DAMAGE, check_faction = TRUE, attack_type = ATTACK_TYPE_MELEE)
			// Seed one random eruption tile per step
			var/list/open_nearby = list()
			for(var/turf/open/OT in range(1, src))
				open_nearby += OT
			if(length(open_nearby))
				var/turf/eruption_turf = pick(open_nearby)
				new /obj/effect/temp_visual/seismic_warning(eruption_turf)
				addtimer(CALLBACK(src, PROC_REF(BorrowedTimeErupt), eruption_turf), 15)

		// Apply tremor to everything we hit
		for(var/mob/living/victim in hit_mobs)
			if(victim == src)
				continue
			victim.apply_lc_tremor(6, 25)
			if(victim.client)
				shake_camera(victim, 5, 2)

		// 1 second pause between dashes
		if(dash_num < 3)
			sleep(10)

	can_act = TRUE

/// Delayed eruption effect from Borrowed Time dash trail.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/BorrowedTimeErupt(turf/T)
	if(!T || QDELETED(src))
		return
	new /obj/effect/temp_visual/seismic_impact(T)
	playsound(T, 'sound/effects/meteorimpact.ogg', 40, TRUE)
	for(var/mob/living/victim in HurtInTurf(T, list(), 10, RED_DAMAGE, check_faction = TRUE, attack_type = ATTACK_TYPE_MELEE))
		var/datum/status_effect/stacking/lc_tremor/tremor = victim.has_status_effect(/datum/status_effect/stacking/lc_tremor)
		if(tremor)
			tremor.TremorBurst()
		if(victim.client)
			shake_camera(victim, 5, 2)

// =============================================
// Director Ability — Seismic Eruption
// =============================================
// Telegraphed AoE — warning markers appear on turfs, then
// anyone standing on them gets launched and has their tremor force-burst.

/// Returns the eruption cooldown in deciseconds, scaling with HP loss.
/// 15s at full HP, down to 3s at 400 HP (execution threshold).
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/GetEruptionCooldown()
	var/hp_ratio = clamp(health / maxHealth, 0, 1)
	return (3 + 12 * hp_ratio) SECONDS

/// Seismic Eruption — telegraphed AoE that force-bursts accumulated tremor.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/SeismicEruption()
	can_act = FALSE
	COOLDOWN_START(src, seismic_eruption_cooldown, GetEruptionCooldown())

	say("The ground remembers every step.")

	// Pick target turfs: 6-8 random in view + 3-4 near each visible enemy (open turfs only)
	var/list/warning_turfs = list()
	var/list/view_turfs = list()
	for(var/turf/open/T in view(5, src))
		view_turfs += T
	for(var/i in 1 to rand(6, 8))
		if(length(view_turfs))
			warning_turfs |= pick(view_turfs)

	for(var/mob/living/enemy in view(5, src))
		if(enemy == src || faction_check_mob(enemy))
			continue
		var/list/nearby_turfs = list()
		for(var/turf/open/NT in range(2, enemy))
			nearby_turfs += NT
		for(var/j in 1 to rand(3, 4))
			if(length(nearby_turfs))
				warning_turfs |= pick(nearby_turfs)

	// Place warning markers
	var/list/warning_visuals = list()
	for(var/turf/T in warning_turfs)
		var/obj/effect/temp_visual/seismic_warning/warning = new(T)
		warning_visuals += warning

	// Telegraph delay — 1.5 seconds for players to react
	sleep(15)

	// Detonation — impact effects and sound on every warning turf
	playsound(src, 'sound/effects/meteorimpact.ogg', 80, TRUE)
	for(var/turf/FX in warning_turfs)
		new /obj/effect/temp_visual/seismic_impact(FX)
		playsound(FX, 'sound/effects/meteorimpact.ogg', 40, TRUE)

	// Apply initial damage + launch victims caught on warning turfs
	var/list/been_hit = list()
	for(var/turf/T in warning_turfs)
		for(var/mob/living/victim in HurtInTurf(T, been_hit, 10, RED_DAMAGE, check_faction = TRUE, attack_type = ATTACK_TYPE_MELEE))
			// Launch victim into air
			animate(victim, pixel_y = victim.base_pixel_y + 32, time = 3)
			// Land at 3 ticks, then detonate at 6 ticks (after landing completes)
			addtimer(CALLBACK(src, PROC_REF(LandVictim), victim), 3)
			addtimer(CALLBACK(src, PROC_REF(EruptionDetonate), victim), 6)

	can_act = TRUE

/// Helper to animate a victim back to ground level after Seismic Eruption launch.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/LandVictim(mob/living/victim)
	if(!QDELETED(victim))
		animate(victim, pixel_y = victim.base_pixel_y, time = 3)

/// Applies tremor burst and landing damage after Seismic Eruption landing.
/mob/living/simple_animal/hostile/prostheti/factory_director/proc/EruptionDetonate(mob/living/victim)
	if(QDELETED(victim))
		return
	// Force-burst tremor if they have stacks
	var/datum/status_effect/stacking/lc_tremor/tremor = victim.has_status_effect(/datum/status_effect/stacking/lc_tremor)
	if(tremor)
		tremor.TremorBurst()
	// Landing damage
	victim.deal_damage(10, RED_DAMAGE, src, attack_type = ATTACK_TYPE_MELEE)
	if(victim.client)
		shake_camera(victim, 7, 3)

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
		for(var/mob/living/simple_animal/hostile/ui_npc/penny_companion/P in GLOB.mob_list)
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
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'	// TEMP — needs Zwei Director sprite
	icon_state = "fixer_r"	// TEMP
	icon_living = "fixer_r"	// TEMP
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
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'	// TEMP — needs Zwei Fixer sprite
	icon_state = "fixer_p"	// TEMP
	icon_living = "fixer_p"	// TEMP
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
