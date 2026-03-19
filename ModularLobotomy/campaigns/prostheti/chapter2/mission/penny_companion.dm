// =============================================
// Prostheti Innovations — Penny Companion (Chapter 2)
// =============================================
// Combat companion that follows and fights alongside players during
// the factory infiltration. Separate mob from Chapter 1's Penny NPC.
//
// Stats scale with Chapter 1 training data stored on the campaign controller.
// Has dodging and rapid melee from training but NOT Fencer's Mark
// (too disruptive to ally gameplay).
//
// Uses a downed system instead of death — players revive her with
// help intent + do_after. Cannot die, only be incapacitated.

/mob/living/simple_animal/hostile/prostheti/penny_companion
	name = "Penny Wells"
	desc = "Penny in her field gear, moving with the confidence of her training."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// TEMP
	icon_state = "electic"	// TEMP — same as training Penny
	icon_living = "electic"	// TEMP
	maxHealth = 600
	health = 600
	melee_damage_lower = 15
	melee_damage_upper = 20
	melee_damage_type = RED_DAMAGE
	move_to_delay = 3
	faction = list("neutral", "prostheti_staff")
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	vision_range = 8
	a_intent = INTENT_HARM
	density = TRUE
	del_on_death = FALSE

	/// The player Penny follows when not in combat
	var/mob/living/leader
	/// Whether Penny is currently downed (incapacitated, not dead)
	var/is_downed = FALSE
	/// Whether players can revive Penny (FALSE during director execution)
	var/can_be_revived = TRUE
	/// Campaign controller reference
	var/datum/campaign_controller/prostheti/campaign
	/// Periodic say line timer
	var/say_timer

/mob/living/simple_animal/hostile/prostheti/penny_companion/Initialize(mapload)
	. = ..()
	campaign = GLOB.prostheti_campaign
	// Start periodic contextual lines
	say_timer = addtimer(CALLBACK(src, PROC_REF(ContextualSay)), rand(30, 60) SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/mob/living/simple_animal/hostile/prostheti/penny_companion/Destroy()
	leader = null
	campaign = null
	if(say_timer)
		deltimer(say_timer)
	return ..()

// =============================================
// Training Data Application
// =============================================

/// Applies Chapter 1 training data from the campaign controller.
/// Called by the mission datum after spawning.
/mob/living/simple_animal/hostile/prostheti/penny_companion/proc/ApplyTrainingData()
	if(!campaign)
		return
	var/duels = campaign.penny_total_duels

	// Health scaling (base 600 + up to 500 from training)
	maxHealth = initial(maxHealth) + campaign.penny_learned_health_bonus
	health = maxHealth

	// Damage type from training adaptation
	melee_damage_type = campaign.penny_learned_damage_type

	// Damage scaling
	melee_damage_lower = initial(melee_damage_lower) + min(duels, 10)
	melee_damage_upper = initial(melee_damage_upper) + min(round(duels * 1.3), 13)

	// Resistances from training
	if(length(campaign.penny_learned_resistances))
		ApplyResistances(campaign.penny_learned_resistances)

	// Dodging (unlocked at 2+ duels)
	if(duels >= 2)
		dodging = TRUE
		dodge_prob = 25
		sidestep_per_cycle = 1

	// Faster combos (unlocked at 7+ duels)
	if(duels >= 7)
		rapid_melee = 2

/// Applies resistance coefficients from training data.
/mob/living/simple_animal/hostile/prostheti/penny_companion/proc/ApplyResistances(list/resistances)
	if(!length(resistances))
		return
	damage_coeff = resistances.Copy()

// =============================================
// Following Behavior
// =============================================

/mob/living/simple_animal/hostile/prostheti/penny_companion/handle_automated_movement()
	if(is_downed)
		return
	// If we have a target, let combat AI handle movement
	if(target)
		return ..()
	// Otherwise follow leader
	if(leader && !QDELETED(leader))
		var/dist = get_dist(src, leader)
		if(dist > 8)
			// Teleport catchup — too far behind
			forceMove(get_turf(leader))
		else if(dist > 2)
			step_to(src, leader, 2, move_to_delay)
	return ..()

// =============================================
// Downed System
// =============================================

/// Override death — go downed instead of dying.
/mob/living/simple_animal/hostile/prostheti/penny_companion/death(gibbed)
	if(is_downed)
		return
	GoDown()
	return

/// Puts Penny in downed state — incapacitated but not dead.
/mob/living/simple_animal/hostile/prostheti/penny_companion/proc/GoDown()
	is_downed = TRUE
	status_flags |= GODMODE
	density = FALSE
	icon_state = "electic"	// TEMP — needs downed sprite
	say(pick("Run... just run!", "I can't... move...", "Not like this..."))

/// Revives Penny from downed state.
/mob/living/simple_animal/hostile/prostheti/penny_companion/proc/GetUp()
	is_downed = FALSE
	status_flags &= ~GODMODE
	density = TRUE
	icon_state = initial(icon_state)
	health = maxHealth * 0.5	// Revives at half health
	say(pick("I'm okay... I'm okay.", "Thanks. Let's keep moving.", "I won't go down again."))

/// Players revive Penny with help intent click.
/mob/living/simple_animal/hostile/prostheti/penny_companion/attack_hand(mob/living/carbon/human/user)
	if(!is_downed || !can_be_revived)
		return ..()
	if(user.a_intent != INTENT_HELP)
		return ..()
	to_chat(user, span_notice("You start helping [src] to her feet..."))
	if(!do_after(user, 3 SECONDS, src))
		return
	if(!is_downed)	// Check again after do_after
		return
	GetUp()
	to_chat(user, span_notice("You help [src] back up."))

/// Block all actions while downed.
/mob/living/simple_animal/hostile/prostheti/penny_companion/AttackingTarget(atom/attacked_target)
	if(is_downed)
		return
	return ..()

/mob/living/simple_animal/hostile/prostheti/penny_companion/Move()
	if(is_downed)
		return FALSE
	return ..()

// =============================================
// Contextual Say Lines
// =============================================

/// Periodic contextual say lines during exploration/combat.
/mob/living/simple_animal/hostile/prostheti/penny_companion/proc/ContextualSay()
	if(is_downed || QDELETED(src))
		return
	if(target)
		// Combat lines
		say(pick(
			"Watch their arms — the augments hit hard!",
			"Stay together!",
			"I've trained for this!",
			"Dodge the tremor, don't let it build up!",
		))
	else
		// Exploration lines
		say(pick(
			"This place gives me the creeps...",
			"Dad doesn't know we're here. Let's keep it that way.",
			"Hector said to destroy the blueprints. Let's find them.",
			"Stay sharp. These workers won't be happy to see us.",
		))
