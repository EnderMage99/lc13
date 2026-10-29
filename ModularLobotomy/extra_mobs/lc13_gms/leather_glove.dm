// An empty glove that creeps toward whoever it notices and jabs them once it reaches them.
/mob/living/simple_animal/hostile/gms_foe/leather_glove
	name = "leather glove"
	desc = "An empty leather glove that walks on its fingertips. It is in no hurry."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "leather_glove"
	icon_living = "leather_glove"
	icon_dead = "leather_glove_dead"
	maxHealth = 80
	health = 80
	move_to_delay = 6
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 8
	melee_damage_upper = 12
	attack_cooldown = 1.5 SECONDS
	attack_verb_continuous = "jabs"
	attack_verb_simple = "jab"
	attack_sound = 'ModularLobotomy/_Lobotomysounds/gms/leather_glove_attack.ogg'
	// A human it kills gets its kill sequence (leather_glove_kill.dm). Turned off, they just die.
	plays_kill_sequence = TRUE
	kill_sequence_type = /datum/gms_kill_sequence/leather_glove

// Only the blow that kills starts the sequence; hitting a body that was already dead does not.
/mob/living/simple_animal/hostile/gms_foe/leather_glove/AttackingTarget(atom/attacked_target)
	var/mob/living/victim = attacked_target || target
	var/was_alive = isliving(victim) && victim.stat != DEAD
	. = ..()
	if(was_alive)
		StartKill(victim)
