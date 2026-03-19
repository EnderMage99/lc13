// =============================================
// Prostheti Innovations — Campaign NPC Base Type
// =============================================
// Base type for all Prostheti campaign NPCs. Extends ui_npc with:
// - Cutscene lock (blocks ui_interact during say() cutscenes)
// - Campaign controller reference
// - Shared dialogue state (npc_vars used for all players, no per-player dialog)
// - Echo-style duel system (StartDuel/EndDuel on the NPC itself)

/mob/living/simple_animal/hostile/ui_npc/prostheti
	faction = list("neutral")
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	density = TRUE
	a_intent = INTENT_HARM

	/// When TRUE, all ui_interact calls are blocked (during say() cutscenes)
	var/in_cutscene = FALSE
	/// Reference to the campaign controller
	var/datum/campaign_controller/prostheti/campaign

	// ---- Duel System Vars ----
	/// Can this NPC be challenged to a duel?
	var/can_duel = FALSE
	/// The mob type to spawn as the combat opponent for duels
	var/duel_fixer_type
	/// Is this NPC currently in a duel?
	var/in_duel = FALSE
	/// The player currently dueling this NPC
	var/mob/living/current_duelist
	/// Where to return the duelist after the duel ends
	var/turf/duelist_return_turf
	/// The spawned combat mob
	var/mob/living/spawned_fixer
	/// Original turf of this NPC (to reappear after duel)
	var/turf/npc_original_turf
	/// The duel area ID — must match fixer_id on landmarks
	var/duel_area_id
	/// Cooldown time after winning a duel (3 minutes)
	var/duel_win_cooldown = 3 MINUTES
	/// Assoc list of ckey → cooldown expiry world.time
	var/list/duel_cooldowns = list()
	/// Scene manager variable name to track wins (e.g., "beaten_penny")
	var/beaten_var_name

/mob/living/simple_animal/hostile/ui_npc/prostheti/Initialize(mapload)
	. = ..()
	if(!campaign)
		campaign = GLOB.prostheti_campaign
	npc_original_turf = get_turf(src)

/mob/living/simple_animal/hostile/ui_npc/prostheti/ui_interact(mob/user, datum/tgui/ui)
	if(in_cutscene)
		return
	return ..()

/mob/living/simple_animal/hostile/ui_npc/prostheti/attack_hand(mob/living/carbon/user)
	if(in_cutscene)
		to_chat(user, span_warning("[src] is busy right now."))
		return
	return ..()

/// Helper to set a shared npc_var that all players can see.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/SetSharedVar(var_name, value)
	if(scene_manager)
		scene_manager.npc_vars.variables[var_name] = value

/// Helper to get a shared npc_var.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/GetSharedVar(var_name)
	if(scene_manager)
		return scene_manager.npc_vars.variables[var_name]
	return null

// =============================================
// Duel System — Echo Office Pattern
// =============================================

/// Find this NPC's player spawn landmark by matching duel_area_id.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/get_player_spawn_landmark()
	for(var/obj/effect/landmark/prostheti_duel/player_spawn/L in GLOB.landmarks_list)
		if(L.fixer_id == duel_area_id)
			return L
	return null

/// Find this NPC's fixer/mob spawn landmark by matching duel_area_id.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/get_fixer_spawn_landmark()
	for(var/obj/effect/landmark/prostheti_duel/fixer_spawn/L in GLOB.landmarks_list)
		if(L.fixer_id == duel_area_id)
			return L
	return null

/// Check if a player is on cooldown from winning a duel.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/check_duel_cooldown(mob/living/challenger)
	if(!challenger?.ckey)
		return FALSE
	var/cooldown_end = duel_cooldowns[challenger.ckey]
	if(cooldown_end && world.time < cooldown_end)
		var/remaining = (cooldown_end - world.time) / 10
		var/minutes = round(remaining / 60)
		var/seconds = round(remaining % 60)
		to_chat(challenger, span_warning("You must wait [minutes]m [seconds]s before challenging [src] again."))
		return TRUE
	return FALSE

/// Set cooldown for a player after winning a duel.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/set_duel_cooldown(mob/living/winner)
	if(!winner?.ckey)
		return
	duel_cooldowns[winner.ckey] = world.time + duel_win_cooldown

/// Starts a duel with the calling player. Called from dialogue proc_callbacks.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/StartDuel()
	var/mob/living/challenger = usr
	if(!isliving(challenger))
		return FALSE
	if(!can_duel)
		to_chat(challenger, span_warning("[src] cannot be challenged right now."))
		return FALSE
	if(in_duel)
		to_chat(challenger, span_warning("[src] is already sparring with someone else."))
		return FALSE
	if(check_duel_cooldown(challenger))
		return FALSE
	if(!duel_fixer_type)
		to_chat(challenger, span_warning("[src] has no combat form."))
		return FALSE

	// Find this NPC's duel landmarks
	var/obj/effect/landmark/prostheti_duel/player_spawn/player_landmark = get_player_spawn_landmark()
	var/obj/effect/landmark/prostheti_duel/fixer_spawn/fixer_landmark = get_fixer_spawn_landmark()
	if(!player_landmark || !fixer_landmark)
		to_chat(challenger, span_warning("The training area isn't set up yet."))
		return FALSE

	// Set up duel state
	in_duel = TRUE
	current_duelist = challenger
	duelist_return_turf = get_turf(challenger)

	// Close dialogue
	close_all_tgui()

	// Teleport player to the duel arena
	challenger.forceMove(get_turf(player_landmark))

	// Spawn the combat mob at the fixer spawn point
	spawned_fixer = new duel_fixer_type(get_turf(fixer_landmark))
	spawned_fixer.faction = list("training_enemy")

	// Let subtypes customize the fighter
	OnFighterSpawned(spawned_fixer)

	// Hide the NPC during the duel
	moveToNullspace()

	// Register signals for duel end conditions
	RegisterSignal(challenger, COMSIG_MOB_STATCHANGE, PROC_REF(OnDuelistStatChange))
	RegisterSignal(challenger, COMSIG_HUMAN_INSANE, PROC_REF(OnDuelistInsane))
	RegisterSignal(spawned_fixer, COMSIG_LIVING_DEATH, PROC_REF(OnFixerDeath))

	to_chat(challenger, span_boldwarning("The sparring match begins! Defeat [spawned_fixer]!"))
	return TRUE

/// SIGNAL_HANDLER — Player's stat changed; if downed, they lose.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/OnDuelistStatChange(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(new_stat >= SOFT_CRIT)
		INVOKE_ASYNC(src, PROC_REF(EndDuel), FALSE)

/// SIGNAL_HANDLER — Combat mob died; player wins.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/OnFixerDeath(datum/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(EndDuel), TRUE)

/// SIGNAL_HANDLER — Player went insane during duel.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/OnDuelistInsane(datum/source, attribute)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(EndDuel), FALSE, TRUE) // skip_heal for insanity
	var/mob/living/L = source
	addtimer(CALLBACK(src, PROC_REF(CureInsanity), L), 1 SECONDS)

/// Cures insanity on a player after duel ends.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/CureInsanity(mob/living/target)
	var/mob/living/carbon/human/H = target
	if(!istype(H) || !H.sanity_lost)
		return
	H.adjustWhiteLoss(9999, updating_health = TRUE, forced = TRUE, white_healable = TRUE)

/// Ends the duel, heals the player, returns them to their original position.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/EndDuel(player_won = FALSE, skip_heal = FALSE)
	if(!in_duel)
		return

	// Capture references and reset state FIRST to prevent stuck states
	// If any cleanup below throws a runtime, the NPC won't be stuck in_duel
	var/mob/living/duelist = current_duelist
	var/mob/living/fighter = spawned_fixer
	var/turf/return_turf = duelist_return_turf
	in_duel = FALSE
	current_duelist = null
	duelist_return_turf = null
	spawned_fixer = null

	// Unregister signals
	if(duelist)
		UnregisterSignal(duelist, list(COMSIG_MOB_STATCHANGE, COMSIG_HUMAN_INSANE))
	if(fighter && !QDELETED(fighter))
		UnregisterSignal(fighter, COMSIG_LIVING_DEATH)
		// Let subtypes record duel data before cleanup
		OnFighterDefeated(fighter, player_won)
		qdel(fighter)

	// Teleport player back
	if(duelist && !QDELETED(duelist))
		if(return_turf)
			duelist.forceMove(return_turf)

		// Fully heal the player (unless skipped for insanity handling)
		if(!skip_heal)
			duelist.fully_heal(admin_revive = TRUE)

		// Remove status effect stacks
		duelist.remove_status_effect(/datum/status_effect/stacking/lc_overheat)

		if(player_won)
			to_chat(duelist, span_boldnotice("You won the sparring match!"))
			// Track wins via shared NPC var
			var/current_wins = GetSharedVar("training_wins")
			if(isnull(current_wins))
				current_wins = 0
			SetSharedVar("training_wins", current_wins + 1)
			// Attribute reward for civilians (capped at 40)
			if(ishuman(duelist))
				var/mob/living/carbon/human/duelist_human = duelist
				if(duelist_human.mind?.assigned_role == "Civilian")
					if(get_attribute_level(duelist_human, TEMPERANCE_ATTRIBUTE) < 40)
						duelist_human.adjust_all_attribute_levels(4)
						to_chat(duelist_human, span_nicegreen("The combat experience sharpens your abilities. (+4 to all stats)"))
			// Check for chapter completion
			OnDuelVictory(duelist, current_wins + 1)
		else
			to_chat(duelist, span_boldwarning("You were defeated. Dust yourself off and try again."))

		// Reset conversation state so player returns to main_menu next interaction
		if(scene_manager)
			var/user_ref = "\ref[duelist]"
			if(user_ref in scene_manager.user_states)
				var/datum/ui_npc/conversation_state/state = scene_manager.user_states[user_ref]
				state.current_scene_id = "main_menu"

	// Show the NPC again
	if(npc_original_turf)
		forceMove(npc_original_turf)

/// Called after a player wins a duel. Override in subtypes for chapter-specific logic.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/OnDuelVictory(mob/living/winner, total_wins)
	return

/// Called after the combat mob is spawned. Override to customize the fighter.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/OnFighterSpawned(mob/living/fighter)
	return

/// Called before the combat mob is qdel'd. Override to record duel data.
/mob/living/simple_animal/hostile/ui_npc/prostheti/proc/OnFighterDefeated(mob/living/fighter, player_won)
	return
