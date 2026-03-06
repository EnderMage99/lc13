// =============================================
// Prostheti Innovations — Training Combat Mob (Penny)
// =============================================
// The combat version of Penny spawned during training duels.
// Uses the Echo Office duel pattern — the duel logic lives on the NPC
// (_npc_base.dm), this file only defines the combat mob.
//
// Penny fights as a quick, light combatant with moderate damage.
// She's meant to be a learning experience, not a brick wall.
//
// MAP PLACEMENT: Not map-placed. Spawned dynamically by Penny's
// StartDuel() at the prostheti_duel/fixer_spawn/penny landmark.

/mob/living/simple_animal/hostile/prostheti/penny_combat
	name = "Penny Wells"
	desc = "Penny in her training gear, moving with surprising speed and confidence."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'	// PLACEHOLDER
	icon_state = "elliot"	// PLACEHOLDER
	icon_living = "elliot"	// PLACEHOLDER
	maxHealth = 150
	health = 150
	melee_damage_lower = 6
	melee_damage_upper = 10
	melee_damage_type = RED_DAMAGE
	move_to_delay = 3
	faction = list("training_enemy")
	stat_attack = CONSCIOUS
	robust_searching = TRUE
	vision_range = 12
	a_intent = INTENT_HARM
	density = TRUE
