//////////////
// RCE BUILDINGS
//////////////
// Structures and buildings used by the Resurgence Clan units

//////////////
// XCORP BARRICADE
//////////////
// A barricade that allows simple mobs to vault over but blocks other mobs
/obj/structure/xcorp_barricade
	name = "X-Corp Barricade"
	desc = "A bloody barricade with meat growing from the sides... It looks low enough to vault over."
	icon = 'icons/obj/smooth_structures/sandbags.dmi'
	icon_state = "meatbags-0"
	base_icon_state = "meatbags"
	density = FALSE
	anchored = TRUE
	layer = TABLE_LAYER
	max_integrity = 400
	integrity_failure = 0.33
	pass_flags_self = LETPASSTHROW
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_SANDBAGS)
	canSmoothWith = list(SMOOTH_GROUP_SANDBAGS, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_SECURITY_BARRICADE)
	var/last_message_time = 0
	var/message_cooldown = 3 SECONDS

/obj/structure/xcorp_barricade/Initialize()
	. = ..()
	AddElement(/datum/element/climbable)

/obj/structure/xcorp_barricade/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(ishuman(mover))
		return FALSE
	if(ismecha(mover))
		return FALSE
	return ..()

/obj/structure/xcorp_barricade/Crossed(atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return

	var/mob/living/L = AM

	// Simple mobs can vault over with a message
	if(istype(L, /mob/living/simple_animal))
		visible_message(span_notice("[L] vaults over [src]."))

//////////////
// XCORP TURRET
//////////////
// Immobile ranged turret that fires projectiles at enemies
/mob/living/simple_animal/hostile/clan/ranged/turret
	name = "X-Corp Turret"
	desc = "An automated defense turret bearing X-Corp markings. It appears to be fused into the ground."
	icon = 'ModularTegustation/Teguicons/resurgence_48x48.dmi'
	icon_state = "turret"
	icon_living = "turret"
	icon_dead = "turret_dead"
	pixel_x = -8
	base_pixel_x = -8
	maxHealth = 1500
	health = 1500
	ranged = TRUE
	retreat_distance = 0
	minimum_distance = 0
	move_to_delay = 100
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/projectile/clan_bullet/turret
	projectilesound = 'sound/weapons/gun/pistol/shot_suppressed.ogg'
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.5)
	melee_damage_lower = 15
	melee_damage_upper = 20
	silk_results = list(/obj/item/stack/sheet/silk/azure_simple = 2,
						/obj/item/stack/sheet/silk/azure_advanced = 1)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 4)
	teleport_away = FALSE // Turrets don't teleport
	charge = 15
	max_charge = 30
	special_attack_cost = 10
	special_attack_cooldown_time = 15 SECONDS
	var/barrage_shots = 5
	var/barrage_delay = 2
	var/targeting_laser = FALSE
	var/datum/beam/current_beam = null

// Cannot move
/mob/living/simple_animal/hostile/clan/ranged/turret/Move()
	return FALSE

/mob/living/simple_animal/hostile/clan/ranged/turret/Initialize()
	. = ..()
	anchored = TRUE
	
// Special attack - rapid barrage
/mob/living/simple_animal/hostile/clan/ranged/turret/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown)
		return FALSE
	
	special_attack_cooldown = world.time + special_attack_cooldown_time
	charge -= special_attack_cost
	
	// Visual and audio warning
	visible_message(span_danger("[src] begins charging up for a barrage!"))
	playsound(src, 'sound/weapons/beam_sniper.ogg', 75, TRUE)
	
	// Create targeting laser
	if(isliving(target))
		targeting_laser = TRUE
		current_beam = Beam(target, icon_state="blood", time = 2 SECONDS)
		var/mob/living/L = target
		L.apply_status_effect(/datum/status_effect/spirit_gun_target) // Reuse visual indicator
	
	// Charge up time
	SLEEP_CHECK_DEATH(2 SECONDS)
	
	// Clean up beam
	if(current_beam)
		QDEL_NULL(current_beam)
	
	if(isliving(target))
		var/mob/living/L = target
		L.remove_status_effect(/datum/status_effect/spirit_gun_target)
	
	targeting_laser = FALSE
	
	// Fire barrage
	visible_message(span_danger("[src] unleashes a barrage of projectiles!"))
	playsound(src, 'sound/weapons/gun/general/mag_release.ogg', 75, TRUE)
	
	for(var/i = 1 to barrage_shots)
		if(stat == DEAD || !target)
			break
		
		// Create projectile with slight spread
		var/turf/startloc = get_turf(src)
		var/obj/projectile/P = new projectiletype(startloc)
		P.starting = startloc
		P.firer = src
		P.fired_from = src
		P.yo = target.y - y
		P.xo = target.x - x
		P.original = target
		
		// Add slight random spread
		if(i > 1)
			P.yo += rand(-1, 1)
			P.xo += rand(-1, 1)
		
		P.fire()
		playsound(src, projectilesound, 50, TRUE)
		
		SLEEP_CHECK_DEATH(barrage_delay)
	
	say("Re-echar-ging we-eapons...")
	return TRUE

/mob/living/simple_animal/hostile/clan/ranged/turret/death()
	// Explosion effect on death
	if(current_beam)
		QDEL_NULL(current_beam)
	visible_message(span_danger("[src] overloads and explodes!"))
	playsound(src, 'sound/effects/explosion1.ogg', 75, FALSE, 5)
	new /obj/effect/temp_visual/explosion(get_turf(src))
	return ..()

// Turret projectile - slightly stronger than normal clan bullets
/obj/projectile/clan_bullet/turret
	name = "turret bolt"
	damage = 35
	damage_type = RED_DAMAGE
	flag = RED_DAMAGE

//////////////
// XCORP ARTILLERY TURRET
//////////////
// Slower firing turret with AoE explosive shots
/mob/living/simple_animal/hostile/clan/ranged/turret/artillery
	name = "X-Corp Artillery Turret"
	desc = "A heavy artillery turret with X-Corp markings. Its barrel glows with barely contained energy."
	icon_state = "turret_artillery"
	maxHealth = 2000
	health = 2000
	ranged_cooldown_time = 6 SECONDS // Much slower fire rate
	projectiletype = null // We handle firing manually
	projectilesound = 'sound/weapons/lasercannonfire.ogg'
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.5)
	special_attack_cooldown_time = 20 SECONDS
	var/aoe_damage = 50
	var/aoe_range = 1 // 3x3 area
	var/is_firing = FALSE

/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/OpenFire(atom/A)
	if(is_firing)
		return FALSE
	
	// Check for special attack
	if(charge >= special_attack_cost && world.time > special_attack_cooldown)
		if(prob(30))
			SpecialAttack(A)
			return TRUE
	
	// Normal artillery shot
	ArtilleryShot(A)
	return TRUE

/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/proc/ArtilleryShot(atom/target)
	if(is_firing || !target)
		return FALSE
	
	is_firing = TRUE
	var/turf/target_turf = get_turf(target)
	
	if(!target_turf)
		is_firing = FALSE
		return FALSE
	
	// Visual warning
	visible_message(span_danger("[src] begins targeting [target]!"))
	playsound(src, 'sound/weapons/beam_sniper.ogg', 50, TRUE)
	
	// Create warning indicator at target location
	new /obj/effect/temp_visual/artillery_warning(target_turf)
	
	// Create targeting beam
	var/datum/beam/targeting = Beam(target_turf, icon_state="blood", time = 2 SECONDS)
	
	// Wait for charge time
	SLEEP_CHECK_DEATH(2 SECONDS)
	
	// Clean up beam
	if(targeting)
		QDEL_NULL(targeting)
	
	// Check if we're still alive
	if(stat == DEAD)
		is_firing = FALSE
		return FALSE
	
	// Fire the shot
	visible_message(span_danger("[src] fires an explosive shell!"))
	playsound(src, projectilesound, 75, TRUE)
	
	// Create explosion effect and deal damage
	new /obj/effect/temp_visual/explosion(target_turf)
	playsound(target_turf, 'sound/effects/explosion2.ogg', 50, TRUE)
	
	// Deal damage in AoE
	for(var/turf/T in range(aoe_range, target_turf))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			L.deal_damage(aoe_damage, RED_DAMAGE)
			to_chat(L, span_userdanger("You are caught in the explosion!"))
			
			// Knockback effect
			var/throw_dir = get_dir(target_turf, L)
			if(throw_dir)
				var/throwtarget = get_edge_target_turf(L, throw_dir)
				L.throw_at(throwtarget, 2, 1)
	
	is_firing = FALSE
	ranged_cooldown = world.time + ranged_cooldown_time
	return TRUE

// Special attack - sustained bombardment
/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown || is_firing)
		return FALSE
	
	special_attack_cooldown = world.time + special_attack_cooldown_time
	charge -= special_attack_cost
	is_firing = TRUE
	
	// Visual and audio warning
	visible_message(span_danger("[src] begins a sustained bombardment!"))
	playsound(src, 'sound/effects/alert.ogg', 75, TRUE)
	say("Co-mmen-cing ar-til-lery bar-rage!")
	
	// Fire multiple shots at random locations near target
	var/shots = 3
	for(var/i = 1 to shots)
		if(stat == DEAD)
			break
		
		// Pick a random turf near the target
		var/turf/T = get_turf(target)
		if(!T)
			break
		
		var/list/possible_turfs = list()
		for(var/turf/check in range(2, T))
			if(!check.density)
				possible_turfs += check
		
		if(!possible_turfs.len)
			break
		
		var/turf/bomb_turf = pick(possible_turfs)
		
		// Create warning
		new /obj/effect/temp_visual/artillery_warning(bomb_turf)
		
		// Wait shorter time for barrage
		SLEEP_CHECK_DEATH(1.5 SECONDS)
		
		// Explosion
		new /obj/effect/temp_visual/explosion(bomb_turf)
		playsound(bomb_turf, 'sound/effects/explosion2.ogg', 50, TRUE)
		
		// Deal damage
		for(var/turf/damage_turf in range(aoe_range, bomb_turf))
			new /obj/effect/temp_visual/small_smoke/halfsecond(damage_turf)
			for(var/mob/living/L in damage_turf)
				if(faction_check_mob(L))
					continue
				L.deal_damage(aoe_damage, RED_DAMAGE)
				to_chat(L, span_userdanger("Artillery shell lands nearby!"))
		
		SLEEP_CHECK_DEATH(5) // Brief pause between shots
	
	is_firing = FALSE
	say("Bar-rage com-plete. Re-load-ing...")
	return TRUE

// Artillery warning indicator
/obj/effect/temp_visual/artillery_warning
	name = "targeted area"
	desc = "This area is being targeted by artillery!"
	icon = 'icons/effects/effects.dmi'
	icon_state = "target"
	duration = 2 SECONDS
	layer = POINT_LAYER
	color = "#FF0000"

/obj/effect/temp_visual/artillery_warning/Initialize()
	. = ..()
	// Flashing animation
	animate(src, alpha = 100, time = 2)
	animate(alpha = 255, time = 2)
	animate(alpha = 100, time = 2)
	animate(alpha = 255, time = 2)
	animate(alpha = 100, time = 2)
	animate(alpha = 255, time = 2)
	animate(alpha = 100, time = 2)
	animate(alpha = 255, time = 2)
