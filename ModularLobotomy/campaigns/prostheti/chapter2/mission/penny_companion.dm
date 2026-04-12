// =============================================
// Prostheti Innovations — Penny Companion (Chapter 2)
// =============================================
// Combat companion that follows and fights alongside players during
// the factory infiltration. Based on the Elliot NPC pattern: ui_npc
// with follow/wait through TGUI dialogue + hostile combat AI.
//
// Stats scale with Chapter 1 training data stored on the campaign controller.
// Has dodging and rapid melee from training.
//
// Uses a downed system instead of death — players revive her with
// help intent + do_after. Cannot die, only be incapacitated.

/mob/living/simple_animal/hostile/ui_npc/penny_companion
	name = "Penny Wells"
	desc = "Penny in her field gear, moving with the confidence of her training."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// TEMP
	icon_state = "electic"	// TEMP — same as training Penny
	icon_living = "electic"	// TEMP
	icon_dead = "electic"	// TEMP — needs downed sprite
	maxHealth = 600
	health = 600
	melee_damage_lower = 15
	melee_damage_upper = 20
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	move_to_delay = 3
	faction = list("neutral", "prostheti_staff")
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	vision_range = 8
	a_intent = INTENT_HARM
	density = TRUE
	del_on_death = FALSE
	city_faction = FALSE
	// UI NPC settings
	portrait = "penny_ch2.PNG"	// TEMP — needs portrait
	start_scene_id = "main"
	typing_interval = 30
	emote_delay = 4000
	random_emotes = "stretches her arms;checks her augments;scans the area ahead"

	/// The player Penny follows when not in combat
	var/mob/living/Leader
	/// Whether Penny is currently downed (incapacitated, not dead)
	var/is_downed = FALSE
	/// Whether players can revive Penny (FALSE during director execution)
	var/can_be_revived = TRUE
	/// Can act flag — blocks actions during scripted sequences
	var/can_act = TRUE
	/// Campaign controller reference
	var/datum/campaign_controller/prostheti/campaign
	/// Teleport catchup cooldown tracking
	var/teleport_update = 0
	var/teleport_cooldown = 10 SECONDS
	/// Whether Penny has already said her boss room line
	var/boss_room_entered = FALSE
	/// Reference to the mission datum (set by mission after spawning)
	var/datum/prostheti_mission/factory_infiltration/mission

	var/list/downed_lines = list(
		"Run... just run!",
		"I can't... move...",
		"Not like this...",
	)
	var/list/rise_lines = list(
		"I'm okay... I'm okay.",
		"Thanks. Let's keep moving.",
		"I won't go down again.",
	)

/mob/living/simple_animal/hostile/ui_npc/penny_companion/Initialize(mapload)
	. = ..()
	campaign = GLOB.prostheti_campaign
	// Build dialogue scenes
	BuildScenes()

/mob/living/simple_animal/hostile/ui_npc/penny_companion/Destroy()
	Leader = null
	campaign = null
	mission = null
	return ..()

// =============================================
// TGUI Dialogue Scenes
// =============================================

/// Builds the SpeakingNpc dialogue scenes for follow/wait commands.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/BuildScenes()
	scene_manager.load_scenes(list(
		"main" = list(
			"text" = "What's the plan?",
			"actions" = list(
				"follow" = list(
					"text" = "Follow me, Penny.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(make_leader))),
					"default_scene" = "following",
				),
				"wait" = list(
					"text" = "Wait here, Penny.",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(remove_leader))),
					"default_scene" = "waiting",
				),
				"unlock_safe" = list(
					"text" = "Can you unlock that safe?",
					"proc_callbacks" = list(CALLBACK(src, PROC_REF(TriggerSafeUnlock))),
					"default_scene" = "unlocking",
				),
			),
		),
		"following" = list(
			"text" = "Right behind you. Let's move.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "main",
				),
			),
		),
		"waiting" = list(
			"text" = "I'll hold here. Be careful.",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "main",
				),
			),
		),
		"unlocking" = list(
			"text" = "On it. Give me a second...",
			"actions" = list(
				"back" = list(
					"text" = "...",
					"default_scene" = "main",
				),
			),
		),
	))

/// Triggers the safe unlock sequence on the mission datum.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/TriggerSafeUnlock()
	var/area/A = get_area(src)
	if(!istype(A, /area/awaymission/competitor_factory/boss_room))
		return
	close_all_tgui()
	if(mission)
		INVOKE_ASYNC(mission, TYPE_PROC_REF(/datum/prostheti_mission/factory_infiltration, OnSafeUnlocked))

/// Sets the user as Penny's leader — she follows them.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/make_leader(mob/user)
	if(!user)
		user = usr
	if(isliving(user))
		Leader = user

/// Clears Penny's leader — she stays in place.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/remove_leader()
	Leader = null

// =============================================
// Training Data Application
// =============================================

/// Applies Chapter 1 training data from the campaign controller.
/// Called by the mission datum after spawning.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/ApplyTrainingData()
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
		ChangeResistances(campaign.penny_learned_resistances)

	// Dodging (unlocked at 2+ duels)
	if(duels >= 2)
		dodging = TRUE
		dodge_prob = 25
		sidestep_per_cycle = 1

	// Faster combos (unlocked at 7+ duels)
	if(duels >= 7)
		rapid_melee = 2

// =============================================
// AI Behavior — Elliot Pattern
// =============================================
// Life() switches between follow mode (no target) and combat mode (has target).
// toggle_ai() prevents going AI_IDLE so the combat AI stays active.

/mob/living/simple_animal/hostile/ui_npc/penny_companion/Life()
	if(..())
		if(is_downed)
			return
		if(!target)
			// No enemy — follow leader, show speech bubble
			speaking_on()
			density = TRUE
			if(Leader)
				if(Leader.z != z || QDELETED(Leader))
					Leader = null
					return
				if(!can_see(src, Leader, vision_range))
					if(teleport_update < world.time - teleport_cooldown)
						TeleportToLeader()
						teleport_update = world.time
						return
				if(!HAS_TRAIT(src, TRAIT_IMMOBILIZED) && isturf(loc))
					follow_leader()
					addtimer(CALLBACK(src, PROC_REF(follow_leader)), 5)
					addtimer(CALLBACK(src, PROC_REF(follow_leader)), 10)
		else
			// In combat — hide speech bubble, reduce density so players can move through
			speaking_off()
			density = FALSE

/// Prevents Penny from going AI_IDLE — keeps combat AI responsive.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/toggle_ai(togglestatus)
	if(togglestatus != AI_IDLE)
		..()

/// Steps toward Leader.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/follow_leader()
	if(!Leader || QDELETED(Leader))
		return
	if(Leader.stat == DEAD)
		Leader = null
		return
	step_to(src, Leader)

/// Teleports near Leader when too far away or out of sight.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/TeleportToLeader()
	if(!Leader || QDELETED(Leader))
		return
	var/turf/origin = get_turf(Leader)
	if(!origin)
		return
	var/list/all_turfs = RANGE_TURFS(2, origin)
	for(var/turf/T in all_turfs)
		if(T == origin)
			continue
		if(T.density)
			continue
		var/blocked = FALSE
		for(var/obj/O in T)
			if(O.density)
				blocked = TRUE
				break
		if(blocked)
			continue
		forceMove(T)
		LoseTarget()
		return
	// Fallback — just teleport to leader's turf
	forceMove(origin)
	LoseTarget()

// =============================================
// Combat Overrides
// =============================================

/mob/living/simple_animal/hostile/ui_npc/penny_companion/AttackingTarget(atom/attacked_target)
	if(!can_act || is_downed)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ui_npc/penny_companion/Move()
	if(!can_act || is_downed)
		return FALSE
	. = ..()
	if(.)
		CheckBossRoomEntry()

/// Checks if Penny just entered the boss room area for the first time.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/CheckBossRoomEntry()
	if(boss_room_entered)
		return
	var/area/A = get_area(src)
	if(!istype(A, /area/awaymission/competitor_factory/boss_room))
		return
	boss_room_entered = TRUE
	say("That safe... these must be the blueprints Hector mentioned. I can try to open it.")

// =============================================
// Downed System
// =============================================

/// Override death — go downed instead of dying.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/death(gibbed)
	if(is_downed)
		return
	GoDown()
	return FALSE

/// Puts Penny in downed state — incapacitated but not dead.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/GoDown()
	is_downed = TRUE
	can_act = FALSE
	status_flags |= GODMODE
	density = FALSE
	icon_state = "electic"	// TEMP — needs downed sprite
	speaking_off()
	say(pick(downed_lines))
	visible_message(span_warning("[src] falls down!"))

/// Revives Penny from downed state.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/proc/GetUp()
	is_downed = FALSE
	can_act = TRUE
	status_flags &= ~GODMODE
	density = TRUE
	icon_state = initial(icon_state)
	health = maxHealth * 0.5	// Revives at half health
	adjustBruteLoss(-maxHealth, forced = TRUE)
	say(pick(rise_lines))
	visible_message(span_warning("[src] gets back up!"))

/// Players revive Penny with help intent click.
/mob/living/simple_animal/hostile/ui_npc/penny_companion/attack_hand(mob/living/carbon/human/user)
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
