// Sunshone Kakis: hooded shoppers in long bloodied coats. Unlike the plain kakis they do not shy away; they close in
// on whoever they notice and strike, like a leather glove, only a little harder.
/mob/living/simple_animal/hostile/gms_foe/kaki_sunshone
	name = "sunshone hungry kaki"
	desc = "A hooded figure in a long dark coat, its shirt stained with old blood. It walks straight for you."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "hungry_kaki_sunshone"
	icon_living = "hungry_kaki_sunshone"
	icon_dead = "hungry_kaki_sunshone_dead"
	maxHealth = 110
	health = 110
	move_to_delay = 5
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 10
	melee_damage_upper = 15
	attack_cooldown = 1.5 SECONDS
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/punch1.ogg'
	// A human it kills gets its kill sequence (kaki_sunshone_kill.dm). Turned off, they just die.
	plays_kill_sequence = TRUE
	kill_sequence_type = /datum/gms_kill_sequence/kaki_sunshone

// Only the blow that kills starts the sequence; hitting a body that was already dead does not.
/mob/living/simple_animal/hostile/gms_foe/kaki_sunshone/AttackingTarget(atom/attacked_target)
	var/mob/living/victim = attacked_target || target
	var/was_alive = isliving(victim) && victim.stat != DEAD
	. = ..()
	if(was_alive)
		StartKill(victim)

/mob/living/simple_animal/hostile/gms_foe/kaki_sunshone/thirsty
	name = "sunshone thirsty kaki"
	desc = "A hooded figure in a long brown coat, its shirt stained with old blood. It walks straight for you."
	icon_state = "thirsty_kaki_sunshone"
	icon_living = "thirsty_kaki_sunshone"
	icon_dead = "thirsty_kaki_sunshone_dead"
