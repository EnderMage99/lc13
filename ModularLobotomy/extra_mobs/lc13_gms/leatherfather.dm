// A Leatherfather never moves. When someone comes within reach it winds up for three seconds, swaying from side to side
// while every tile it is about to hit glows steadily redder, then slams everything in a rhombus two tiles out in each direction.
/mob/living/simple_animal/hostile/gms_foe/leatherfather
	name = "Leatherfather"
	desc = "A tall, hunched figure of old stitched leather, hands hanging at its sides. It does not walk anywhere."
	// About 39 px tall at the Kakis' scale, so it is drawn on a 48x48 canvas, centred on its tile.
	icon = 'icons/mob/gms/gms_48x48.dmi'
	icon_state = "leatherfather"
	icon_living = "leatherfather"
	icon_dead = "leatherfather_dead"
	pixel_x = -8
	base_pixel_x = -8
	maxHealth = 200
	health = 200
	/// The slam reaches every tile this many steps away, counting straight steps only, so it forms a rhombus.
	var/slam_range = 2
	var/slam_damage = 50
	var/windup_time = 3 SECONDS
	var/slam_cooldown_time = 3 SECONDS
	var/slam_cooldown = 0
	/// How far it sways to each side while winding up, and how long each sway takes.
	var/sway_pixels = 2
	var/sway_time = 3
	/// As it slams, its robe swells into a round barrel and narrows back (leatherfather_expand). That sprite is 64x64,
	/// so it is shifted further to stay centred, and lasts this long.
	var/expand_duration = 8
	var/expand_pixel_x = -16
	/// How long its body glows red as it slams.
	var/glow_time = 6
	/// TRUE from the start of the wind-up until the slam lands.
	var/busy = FALSE
	// A human its slam kills gets its kill sequence (leatherfather_kill.dm). Turned off, they just die.
	plays_kill_sequence = TRUE
	kill_sequence_type = /datum/gms_kill_sequence/leatherfather

// It never moves.
/mob/living/simple_animal/hostile/gms_foe/leatherfather/Move()
	return FALSE

// The AI calls these when it has a target; the Leatherfather winds up a slam instead of walking or swinging.
/mob/living/simple_animal/hostile/gms_foe/leatherfather/Goto(target, delay, minimum_distance)
	StartSlam()

/mob/living/simple_animal/hostile/gms_foe/leatherfather/AttackingTarget(atom/attacked_target)
	StartSlam()

/mob/living/simple_animal/hostile/gms_foe/leatherfather/death(gibbed)
	EndWindup()
	// If it dies mid-slam, the dead sprite is in the usual file, not the swelling one.
	icon = initial(icon)
	pixel_x = base_pixel_x
	return ..()

/mob/living/simple_animal/hostile/gms_foe/leatherfather/Destroy()
	EndWindup()
	return ..()

/// Every tile within slam_range straight steps, so a rhombus, leaving out walls.
/mob/living/simple_animal/hostile/gms_foe/leatherfather/proc/SlamTurfs()
	. = list()
	var/turf/centre = get_turf(src)
	for(var/turf/T in RANGE_TURFS(slam_range, centre))
		if(abs(T.x - centre.x) + abs(T.y - centre.y) <= slam_range && !T.density)
			. += T

/// Only winds up when the target is already inside the rhombus, so it does not keep slamming at people far away.
/mob/living/simple_animal/hostile/gms_foe/leatherfather/proc/StartSlam()
	if(busy || slam_cooldown > world.time || stat == DEAD || !target)
		return
	if(abs(target.x - x) + abs(target.y - y) > slam_range || target.z != z)
		return
	busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(Slam))

/mob/living/simple_animal/hostile/gms_foe/leatherfather/proc/Slam()
	var/list/turfs = SlamTurfs()
	// Winding up: the tiles it is about to hit glow brighter and brighter red and it sways from side to side.
	ShowWarnings(turfs, windup_time)
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/leatherfather_windup.ogg', 60, TRUE)
	animate(src, pixel_x = base_pixel_x + sway_pixels, time = sway_time / 2, easing = SINE_EASING)
	animate(pixel_x = base_pixel_x - sway_pixels, time = sway_time, easing = SINE_EASING, loop = -1)
	animate(pixel_x = base_pixel_x + sway_pixels, time = sway_time, easing = SINE_EASING)
	SLEEP_CHECK_DEATH(windup_time)
	EndWindup()
	// The slam: it puffs up glowing red with a star flaring on its chest, red dust bursts out round it, and every tile
	// flashes red. Then it settles back down.
	new /obj/effect/temp_visual/gms_leatherfather_flare(get_turf(src))
	new /obj/effect/temp_visual/gms_leatherfather_dust(get_turf(src))
	icon = 'icons/mob/gms/gms_64x64.dmi'
	icon_state = "leatherfather_expand"
	pixel_x = expand_pixel_x
	animate(src, color = "#ff5a48", time = 1)
	animate(color = null, time = glow_time)
	addtimer(CALLBACK(src, PROC_REF(EndExpand)), expand_duration)
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/leatherfather_slam.ogg', 70, TRUE)
	// Only a slam that kills someone starts the kill; bodies already lying there are left alone.
	var/list/alive = list()
	for(var/turf/T as anything in turfs)
		for(var/mob/living/carbon/human/H in T)
			if(H.stat != DEAD)
				alive += H
	var/list/hit_list = list()
	for(var/turf/T as anything in turfs)
		new /obj/effect/temp_visual/gms_leatherfather_strike(T)
		hit_list = HurtInTurf(T, hit_list, slam_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	slam_cooldown = world.time + slam_cooldown_time
	busy = FALSE
	for(var/mob/living/carbon/human/H as anything in alive)
		if(StartKill(H))
			break

/// Back to its usual sprite once the swelling has passed.
/mob/living/simple_animal/hostile/gms_foe/leatherfather/proc/EndExpand()
	if(stat == DEAD)
		return
	icon = initial(icon)
	icon_state = icon_living
	pixel_x = base_pixel_x

/// Takes down the warning tiles and stops the sway.
/mob/living/simple_animal/hostile/gms_foe/leatherfather/proc/EndWindup()
	ClearWarnings()
	animate(src, pixel_x = base_pixel_x)

/// The red flash on each tile a Leatherfather slams.
/obj/effect/temp_visual/gms_leatherfather_strike
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "leatherfather_strike"
	duration = 0.5 SECONDS
	randomdir = FALSE
	layer = BELOW_MOB_LAYER

/// The star that flares on a Leatherfather's chest as it slams.
/obj/effect/temp_visual/gms_leatherfather_flare
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "leatherfather_flare"
	duration = 0.5 SECONDS
	randomdir = FALSE
	// Raised to sit on its chest, which is higher than a human's.
	pixel_y = 4
	base_pixel_y = 4

/// The red dust that bursts out round a Leatherfather as it slams. The sprite is 64x64, centred on its tile.
/obj/effect/temp_visual/gms_leatherfather_dust
	icon = 'icons/mob/gms/gms_64x64.dmi'
	icon_state = "leatherfather_dust"
	duration = 0.8 SECONDS
	randomdir = FALSE
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16
