// Kakis: hooded shoppers with an eye clutched to their chest. For now they only keep away from whoever they spot,
// the way the Resurgence Clan citizens do: a ranged mob with nothing to fire, held at a distance it never closes.
/mob/living/simple_animal/hostile/gms_foe/kaki
	name = "hungry kaki"
	desc = "A hooded shopper hugging something to its chest. It shies away the moment it notices you."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "hungry_kaki"
	icon_living = "hungry_kaki"
	icon_dead = "hungry_kaki_dead"
	maxHealth = 80
	health = 80
	move_to_delay = 3
	ranged = TRUE
	retreat_distance = 10
	minimum_distance = 10
	ranged_message = null
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	melee_damage_lower = 0
	melee_damage_upper = 0

// It never fights back, even when cornered.
/mob/living/simple_animal/hostile/gms_foe/kaki/AttackingTarget(atom/attacked_target)
	return

/mob/living/simple_animal/hostile/gms_foe/kaki/thirsty
	name = "thirsty kaki"
	desc = "A shopper in a green jumper, clutching something to its chest. It backs off the moment it notices you."
	icon_state = "thirsty_kaki"
	icon_living = "thirsty_kaki"
	icon_dead = "thirsty_kaki_dead"
