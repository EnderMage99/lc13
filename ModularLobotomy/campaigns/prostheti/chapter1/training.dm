// =============================================
// Prostheti Innovations — Training Combat Mob (Penny)
// =============================================
// The combat version of Penny spawned during training duels.
// Uses the Echo Office duel pattern — the duel logic lives on the NPC
// (_npc_base.dm), this file only defines the combat mob.
//
// Penny starts at ZAYIN-tier strength and learns from each duel,
// ramping up toward HE-tier over ~10 duels. She gains HP, adapts
// resistances, shifts damage types, and unlocks new moves.
//
// Combat style: Fencer — mark-based dash attack sequence where
// the player must face Penny to parry each incoming dash.
//
// MAP PLACEMENT: Not map-placed. Spawned dynamically by Penny's
// StartDuel() at the prostheti_duel/fixer_spawn/penny landmark.

/mob/living/simple_animal/hostile/prostheti/penny_combat
	name = "Penny Wells"
	desc = "Penny in her training gear, moving with surprising speed and confidence."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// TEMP — training combat mob, needs custom sprite
	icon_state = "electic"	// TEMP — reuses Penny's temp sprite for her combat form
	icon_living = "electic"	// TEMP
	maxHealth = 500
	health = 500
	melee_damage_lower = 10
	melee_damage_upper = 15
	melee_damage_type = RED_DAMAGE
	move_to_delay = 3
	faction = list("training_enemy")
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	vision_range = 12
	a_intent = INTENT_HARM
	density = TRUE

	// Adaptive learning — damage tracking
	/// Tracks damage received by type during this duel
	var/list/damage_received = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	/// Tracks damage dealt to player by type during this duel
	var/list/damage_dealt = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)

	// Fencer's Mark system
	/// Can use the Fencer's Mark ability
	var/can_fencer_mark = FALSE
	/// Currently executing the mark sequence
	var/in_mark_sequence = FALSE
	/// Delay between dashes in the mark sequence (seconds, decreases with duels)
	var/mark_dash_delay = 2.5
	/// Cooldown for the mark sequence
	COOLDOWN_DECLARE(fencer_mark_cooldown)
	/// Can act flag — blocks Move/AttackingTarget during sequences
	var/can_act = TRUE
	/// Whether the mark sequence flavor has been said
	var/mark_announced = FALSE

// =============================================
// Damage Tracking Overrides
// =============================================

/mob/living/simple_animal/hostile/prostheti/penny_combat/adjustRedLoss(amount, updating_health, forced)
	if(amount > 0)
		damage_received[RED_DAMAGE] += amount
	return ..()

/mob/living/simple_animal/hostile/prostheti/penny_combat/adjustWhiteLoss(amount, updating_health, forced, white_healable)
	if(amount > 0)
		damage_received[WHITE_DAMAGE] += amount
	return ..()

/mob/living/simple_animal/hostile/prostheti/penny_combat/adjustBlackLoss(amount, updating_health, forced, white_healable)
	if(amount > 0)
		damage_received[BLACK_DAMAGE] += amount
	return ..()

/mob/living/simple_animal/hostile/prostheti/penny_combat/adjustPaleLoss(amount, updating_health, forced)
	if(amount > 0)
		damage_received[PALE_DAMAGE] += amount
	return ..()

// =============================================
// Adaptive Learning — Applied from NPC state
// =============================================

/// Reads the NPC's learning state and configures this combat mob accordingly.
/mob/living/simple_animal/hostile/prostheti/penny_combat/proc/ApplyLearning(mob/living/simple_animal/hostile/ui_npc/prostheti/penny_wells/ch1/owner)
	var/duels = owner.total_duels

	// Health scaling (ZAYIN 500 -> HE 1000)
	maxHealth = initial(maxHealth) + owner.learned_health_bonus
	health = maxHealth

	// Damage type
	melee_damage_type = owner.learned_damage_type

	// Damage scaling (ZAYIN 10-15 -> HE 20-28)
	melee_damage_lower = initial(melee_damage_lower) + min(duels, 10)
	melee_damage_upper = initial(melee_damage_upper) + min(round(duels * 1.3), 13)

	// Resistances
	ChangeResistances(owner.learned_resistances)

	// Move unlocks — flavor lines fire mid-fight on first activation
	if(duels >= 2)
		// Augment-assisted reflexes
		dodging = TRUE
		dodge_prob = 25
		sidestep_per_cycle = 1

	if(duels >= 3)
		// Fencer's Mark — telegraphed directional dash sequence
		can_fencer_mark = TRUE
		mark_dash_delay = max(2.5 - (duels - 3) * 0.4, 0.5)

	if(duels >= 7)
		// Faster combos between mark sequences
		rapid_melee = 2

// =============================================
// Combat Overrides — Fencer Moves
// =============================================

/mob/living/simple_animal/hostile/prostheti/penny_combat/Move()
	if(!can_act)
		return FALSE
	return ..()

/// Main attack proc — triggers Fencer's Mark or normal melee + damage tracking.
/mob/living/simple_animal/hostile/prostheti/penny_combat/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	// Fencer's Mark: 25% chance when off cooldown
	if(can_fencer_mark && COOLDOWN_FINISHED(src, fencer_mark_cooldown) && prob(25) && isliving(attacked_target))
		INVOKE_ASYNC(src, PROC_REF(FencerMarkSequence), attacked_target)
		return
	. = ..()
	// Track outgoing damage
	if(.)
		damage_dealt[melee_damage_type] += rand(melee_damage_lower, melee_damage_upper)

// =============================================
// Fencer's Mark — Directional Dash Sequence
// =============================================
// 1. Mark the target (overlay + sparkle indicators)
// 2. Immobilize target briefly
// 3. Teleport to cardinal position, telegraph, then dash in
// 4. Player faces Penny = parry (she staggers); doesn't face = hit
// 5. Repeat from 4 cardinal directions
// 6. All 4 parried = big stagger (vulnerability window)

/// Executes the full Fencer's Mark dash sequence against the target.
/mob/living/simple_animal/hostile/prostheti/penny_combat/proc/FencerMarkSequence(mob/living/mark_target)
	if(in_mark_sequence || QDELETED(mark_target) || mark_target.stat >= SOFT_CRIT)
		return
	in_mark_sequence = TRUE
	can_act = FALSE

	// First-time flavor
	if(!mark_announced)
		say("En garde! Watch my blade!")
		mark_announced = TRUE

	// Place mark overlay on target
	var/image/mark_overlay = image(icon = 'icons/effects/cult_effects.dmi', icon_state = "bloodsparkles", layer = mark_target.layer + 0.1)
	mark_target.add_overlay(mark_overlay)

	// Dash away from target (3 tiles opposite direction)
	var/away_dir = get_dir(mark_target, src)
	if(!away_dir)
		away_dir = pick(GLOB.cardinals)
	for(var/i in 1 to 3)
		var/turf/retreat_turf = get_step(src, away_dir)
		if(!retreat_turf || !ClearSky(retreat_turf))
			break
		forceMove(retreat_turf)

	SLEEP_CHECK_DEATH(10) // 1 second

	// Place cardinal sparkle indicators around target
	for(var/card_dir in GLOB.cardinals)
		var/turf/indicator_turf = get_step(mark_target, card_dir)
		if(indicator_turf)
			new /obj/effect/temp_visual/cult/sparks(indicator_turf)

	// Immobilize target
	if(!QDELETED(mark_target) && mark_target.stat < SOFT_CRIT)
		ADD_TRAIT(mark_target, TRAIT_IMMOBILIZED, "penny_mark")

	SLEEP_CHECK_DEATH(5) // 0.5 seconds

	// Shuffle cardinal directions for dash order
	var/list/directions = GLOB.cardinals.Copy()
	for(var/j in length(directions) to 2 step -1)
		directions.Swap(j, rand(1, j))

	var/parry_count = 0

	// 4 directional dashes
	for(var/dash_dir in directions)
		if(QDELETED(mark_target) || mark_target.stat >= SOFT_CRIT)
			break

		// Teleport to position 3 tiles away in this direction
		var/turf/dash_start = get_turf(mark_target)
		for(var/d in 1 to 3)
			var/turf/check = get_step(dash_start, dash_dir)
			if(!check || !ClearSky(check))
				break
			dash_start = check
		// Must be at least 1 tile away
		if(dash_start == get_turf(mark_target))
			dash_start = get_step(mark_target, dash_dir)
			if(!dash_start || !ClearSky(dash_start))
				continue

		forceMove(dash_start)
		face_atom(mark_target)

		// Telegraph at Penny's position
		new /obj/effect/temp_visual/cult/sparks(get_turf(src))

		// Delay before dash (gets faster with duels)
		SLEEP_CHECK_DEATH(mark_dash_delay * 10) // Convert seconds to ticks

		// Dash toward target tile by tile
		var/turf/target_turf = get_turf(mark_target)
		if(QDELETED(mark_target) || !target_turf)
			break
		var/dash_distance = get_dist(src, mark_target)
		for(var/step_i in 1 to dash_distance)
			var/dash_step_dir = get_dir(src, target_turf)
			var/turf/next_turf = get_step(src, dash_step_dir)
			if(!next_turf || !ClearSky(next_turf))
				break
			// Trail visual on each tile
			new /obj/effect/temp_visual/cult/sparks(get_turf(src))
			forceMove(next_turf)
			SLEEP_CHECK_DEATH(1)

		// Arrived — check for parry
		if(QDELETED(mark_target) || mark_target.stat >= SOFT_CRIT)
			break

		if(get_dist(src, mark_target) <= 1)
			// Parry check: player must face the direction Penny dashed from
			// Use dash_dir (the known cardinal) instead of get_dir which can return 0 if on same tile
			if(mark_target.dir == dash_dir)
				// Parried! Target was facing Penny
				parry_count++
				playsound(src, 'sound/weapons/parry.ogg', 50, TRUE)
				visible_message(span_notice("[mark_target] reads the strike and parries [src]!"))
				// Stagger back 1 tile with pixel animation
				var/stagger_dir = dash_dir
				var/turf/stagger_turf = get_step(src, stagger_dir)
				if(stagger_turf && ClearSky(stagger_turf))
					// Smooth pixel slide: lurch toward stagger dir, then snap back
					var/px_offset = 0
					var/py_offset = 0
					if(stagger_dir & NORTH)
						py_offset = 16
					if(stagger_dir & SOUTH)
						py_offset = -16
					if(stagger_dir & EAST)
						px_offset = 16
					if(stagger_dir & WEST)
						px_offset = -16
					animate(src, pixel_x = base_pixel_x + px_offset, pixel_y = base_pixel_y + py_offset, time = 2)
					forceMove(stagger_turf)
					animate(src, pixel_x = base_pixel_x, pixel_y = base_pixel_y, time = 2)
				else
					// No room to stagger — just do a pixel shake in place
					animate(src, pixel_x = base_pixel_x + 4, time = 1)
					animate(src, pixel_x = base_pixel_x - 4, time = 1)
					animate(src, pixel_x = base_pixel_x, time = 1)
				SLEEP_CHECK_DEATH(5) // 0.5s stagger before next dash
			else
				// Hit! Target wasn't facing Penny
				var/damage = rand(melee_damage_lower, melee_damage_upper) * 1.5
				visible_message(span_danger("[src] strikes [mark_target] from behind!"))
				mark_target.deal_damage(damage, melee_damage_type, src, attack_type = (ATTACK_TYPE_MELEE))
				damage_dealt[melee_damage_type] += damage

	// Clean up — remove mark overlay and immobilize
	if(!QDELETED(mark_target))
		mark_target.cut_overlay(mark_overlay)
		REMOVE_TRAIT(mark_target, TRAIT_IMMOBILIZED, "penny_mark")

	// All 4 parried — big stagger (vulnerability window)
	if(parry_count >= 4)
		visible_message(span_boldwarning("[src] staggers, completely thrown off balance!"))
		var/mutable_appearance/stagger_overlay = mutable_appearance(icon, "small_stagger", layer + 0.1)
		add_overlay(stagger_overlay)
		SLEEP_CHECK_DEATH(30) // 3 seconds
		cut_overlay(stagger_overlay)

	can_act = TRUE
	in_mark_sequence = FALSE
	COOLDOWN_START(src, fencer_mark_cooldown, 15 SECONDS)
