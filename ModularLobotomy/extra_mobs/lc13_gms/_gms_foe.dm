// Base for the foes that live in the Grand Magasin Sisyphe. They share a side and leave their husk behind.
/mob/living/simple_animal/hostile/gms_foe
	name = "shop foe"
	desc = "Something from the shelves of the Grand Magasin that should not be moving."
	faction = list("gms_foe")
	gender = NEUTER
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	/// One of these plays when it dies.
	var/list/death_sounds = list(
		'ModularLobotomy/_Lobotomysounds/gms/gms_foe_death_1.ogg',
		'ModularLobotomy/_Lobotomysounds/gms/gms_foe_death_2.ogg',
		'ModularLobotomy/_Lobotomysounds/gms/gms_foe_death_3.ogg',
		)

/mob/living/simple_animal/hostile/gms_foe/death(gibbed)
	if(length(death_sounds))
		playsound(src, pick(death_sounds), 50, TRUE)
	return ..()

// Kill sequences: a foe with one plays it out over a human it kills, riding inside the body until it is over.
/mob/living/simple_animal/hostile/gms_foe
	/// Whether a human it kills gets its kill sequence. Only foes with a kill_sequence_type have one.
	var/plays_kill_sequence = FALSE
	var/kill_sequence_type
	/// TRUE while it plays out a kill from inside the body.
	var/killing = FALSE

// Inside a body, it holds still and leaves everyone alone until the kill is over.
/mob/living/simple_animal/hostile/gms_foe/Move()
	if(killing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/gms_foe/Goto(target, delay, minimum_distance)
	if(killing)
		return
	return ..()

/mob/living/simple_animal/hostile/gms_foe/AttackingTarget(atom/attacked_target)
	if(killing)
		return
	return ..()

/// Starts its kill sequence over the victim, if it has one and it is turned on. Returns TRUE if it did.
/mob/living/simple_animal/hostile/gms_foe/proc/StartKill(mob/living/victim)
	if(!plays_kill_sequence || !kill_sequence_type || !ishuman(victim) || victim.stat != DEAD)
		return FALSE
	killing = TRUE
	new kill_sequence_type(src, victim)
	return TRUE

/// Called once a kill sequence is over, with the foe back on the floor. It lets go of the body and looks for someone new.
/mob/living/simple_animal/hostile/gms_foe/proc/EndKill()
	killing = FALSE
	LoseTarget()

// Warning tiles: a foe winding up an attack lights up the tiles it is about to hit, brightening to full red.
/mob/living/simple_animal/hostile/gms_foe
	/// The warning tiles it has lit up.
	var/list/warnings = list()

/mob/living/simple_animal/hostile/gms_foe/Destroy()
	ClearWarnings()
	return ..()

/// Lights up each of the turfs, going from faint to full red over glow_time.
/mob/living/simple_animal/hostile/gms_foe/proc/ShowWarnings(list/turfs, glow_time)
	for(var/turf/T as anything in turfs)
		warnings += new /obj/effect/gms_warning(T, glow_time)

/mob/living/simple_animal/hostile/gms_foe/proc/ClearWarnings()
	QDEL_LIST(warnings)

/// A tile a foe is about to hit, glowing brighter until the attack lands.
/obj/effect/gms_warning
	name = "red glow"
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "gms_warning"
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/// How faint it is when it first appears.
	alpha = 25

/obj/effect/gms_warning/Initialize(mapload, glow_time)
	. = ..()
	animate(src, alpha = 255, time = glow_time)
