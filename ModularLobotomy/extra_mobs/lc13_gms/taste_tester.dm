// Taste Testers: the GMS's ranged foes, hooded shoppers with a basket of meat on their backs. They keep their distance
// and throw at whoever they spot. The Mouth tester throws a chunk of meat, the Eye tester a cleaver that arcs out and
// comes back to its hand, and the Nose tester a meat ball that slows as it nears where it was thrown and bursts.
/mob/living/simple_animal/hostile/gms_foe/taste_tester
	name = "mouth taste tester"
	desc = "A hooded figure with a mouth for a face and a basket of meat on its back. It keeps its distance, and throws."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "mouth_taste_tester"
	icon_living = "mouth_taste_tester"
	icon_dead = "mouth_taste_tester_dead"
	maxHealth = 90
	health = 90
	move_to_delay = 4
	ranged = TRUE
	ranged_cooldown_time = 3 SECONDS
	retreat_distance = 4
	minimum_distance = 4
	ranged_message = "throws something"
	projectiletype = /obj/projectile/gms_tester
	projectilesound = 'sound/weapons/thudswoosh.ogg'
	melee_damage_lower = 0
	melee_damage_upper = 0
	plays_kill_sequence = TRUE
	kill_sequence_type = /datum/gms_kill_sequence/taste_tester/mouth

// It never fights up close; throwing is all it does.
/mob/living/simple_animal/hostile/gms_foe/taste_tester/AttackingTarget(atom/attacked_target)
	return

/mob/living/simple_animal/hostile/gms_foe/taste_tester/eye
	name = "eye taste tester"
	desc = "A hooded figure with a single staring eye for a face, a cleaver in its hand and a basket of meat on its back."
	icon_state = "eye_taste_tester"
	icon_living = "eye_taste_tester"
	icon_dead = "eye_taste_tester_dead"
	projectiletype = /obj/projectile/gms_tester/cleaver
	projectilesound = 'sound/weapons/slice.ogg'
	kill_sequence_type = /datum/gms_kill_sequence/taste_tester/eye

/mob/living/simple_animal/hostile/gms_foe/taste_tester/nose
	name = "nose taste tester"
	desc = "A hooded figure with a coiled red nose for a face and a basket of meat on its back."
	icon_state = "nose_taste_tester"
	icon_living = "nose_taste_tester"
	icon_dead = "nose_taste_tester_dead"
	ranged_cooldown_time = 4 SECONDS
	projectiletype = /obj/projectile/gms_tester/meatball
	kill_sequence_type = /datum/gms_kill_sequence/taste_tester/nose

/// A chunk of meat thrown by a taste tester. It passes through the tester's own side. A throw that kills someone, or
/// leaves them in crit, starts the thrower's kill sequence.
/obj/projectile/gms_tester
	name = "chunk of meat"
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "taste_tester_meat"
	damage = 15
	damage_type = RED_DAMAGE
	speed = 1
	hitsound = 'sound/effects/meatslap.ogg'
	/// Whether the living thing it is about to hit was alive just before.
	var/struck_alive = FALSE

/obj/projectile/gms_tester/prehit_pierce(atom/A)
	if(isliving(A))
		var/mob/living/L = A
		var/mob/living/thrower = firer
		if(istype(thrower) && thrower.faction_check_mob(L))
			return PROJECTILE_PIERCE_PHASE
		struck_alive = L.stat != DEAD
	return ..()

/obj/projectile/gms_tester/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	if(isliving(target))
		TesterKill(target, struck_alive)

/// Finishes off a human the throw killed or left in crit, and plays the thrower's kill sequence over them, unless a
/// foe is already playing one out on them or the thrower cannot. `was_alive` is whether they were alive before it.
/obj/projectile/gms_tester/proc/TesterKill(mob/living/victim, was_alive)
	var/mob/living/simple_animal/hostile/gms_foe/tester = firer
	if(!ishuman(victim) || victim.stat == CONSCIOUS || (victim.stat == DEAD && !was_alive))
		return FALSE
	if(!istype(tester) || QDELETED(tester) || tester.stat == DEAD || tester.killing)
		return FALSE
	if(locate(/mob/living/simple_animal/hostile/gms_foe) in victim)
		return FALSE
	if(victim.stat != DEAD)
		victim.death()
	return tester.StartKill(victim)

/// The Eye tester's cleaver. It spins out in an arc for `range` tiles, hangs slowly in the air for a moment, then
/// speeds back to the tester's hand, cutting everyone in its path both ways.
/obj/projectile/gms_tester/cleaver
	name = "cleaver"
	icon_state = "taste_tester_cleaver"
	nondirectional_sprite = TRUE
	// It cuts through everyone in its path, out and back, rather than stopping at the first.
	projectile_piercing = PASSMOB
	damage = 18
	speed = 1
	range = 6
	hitsound = 'sound/weapons/bladeslice.ogg'
	/// Degrees it turns each tile on the way out; it sets off half the arc to one side so it sweeps through the aim.
	var/arc_turn = 12
	var/returning = FALSE
	/// How long it hangs in the air at the far end, how slowly it moves meanwhile, and how fast it comes back.
	var/hover_time = 0.5 SECONDS
	var/hover_speed = 3
	var/return_speed = 0.6
	var/hover_until = 0
	/// Tiles it may travel on the way back before giving up, and how sharply it turns to follow the tester.
	var/return_range = 20
	var/return_turn = 40

/obj/projectile/gms_tester/cleaver/fire(angle, atom/direct_target)
	. = ..()
	set_angle(Angle - arc_turn * range / 2)

/obj/projectile/gms_tester/cleaver/Range()
	if(!returning)
		set_angle(Angle + arc_turn)
		return ..()
	speed = world.time < hover_until ? hover_speed : return_speed
	if(QDELETED(firer) || get_turf(firer) == get_turf(src))
		qdel(src)
		return
	return ..()

// At the far end it turns for home instead of dropping.
/obj/projectile/gms_tester/cleaver/on_range()
	if(returning || QDELETED(firer))
		return ..()
	returning = TRUE
	range = return_range
	hover_until = world.time + hover_time
	speed = hover_speed
	homing_turn_speed = return_turn
	impacted = list()
	set_homing_target(firer)

/// The Nose tester's meat ball. It is aimed at the turf its target stood on, slows as it closes in, and bursts there
/// (or on whatever it hits first), hurting everyone in a 3x3.
/obj/projectile/gms_tester/meatball
	name = "meat ball"
	icon_state = "taste_tester_meatball"
	nondirectional_sprite = TRUE
	damage = 10
	speed = 1.2
	hitsound = 'sound/effects/splat.ogg'
	/// Where it was thrown at.
	var/turf/goal_turf
	/// Within this many tiles of the goal it slows down, by this much more per tile closer.
	var/slow_distance = 3
	var/slow_step = 1
	var/burst_damage = 25
	var/burst_range = 1
	var/burst = FALSE

/obj/projectile/gms_tester/meatball/fire(angle, atom/direct_target)
	goal_turf = get_turf(original)
	return ..()

/obj/projectile/gms_tester/meatball/Range()
	. = ..()
	if(QDELETED(src) || !goal_turf)
		return
	if(get_turf(src) == goal_turf)
		Burst()
		return
	var/distance = get_dist(src, goal_turf)
	if(distance <= slow_distance)
		speed = initial(speed) + (slow_distance - distance + 1) * slow_step

/obj/projectile/gms_tester/meatball/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	Burst()

/obj/projectile/gms_tester/meatball/on_range()
	Burst()

/// Bursts in a 3x3, hurting everyone in it. A burst that kills someone alive, or leaves them in crit, starts the
/// thrower's kill sequence.
/obj/projectile/gms_tester/meatball/proc/Burst()
	if(burst)
		return
	burst = TRUE
	var/turf/center = get_turf(src)
	var/mob/living/thrower = firer
	if(center && istype(thrower))
		playsound(center, 'sound/effects/blobattack.ogg', 60, TRUE)
		var/list/alive = list()
		for(var/mob/living/carbon/human/H in range(burst_range, center))
			if(H.stat != DEAD)
				alive += H
		var/list/hit_list = list()
		for(var/turf/T in range(burst_range, center))
			new /obj/effect/temp_visual/gms_tester_burst(T)
			thrower.HurtInTurf(T, hit_list, burst_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/carbon/human/H as anything in alive)
			if(TesterKill(H, TRUE))
				break
	qdel(src)

/// A splash of blood on one tile of a meat ball's burst.
/obj/effect/temp_visual/gms_tester_burst
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "taste_tester_burst"
	duration = 0.5 SECONDS
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER
