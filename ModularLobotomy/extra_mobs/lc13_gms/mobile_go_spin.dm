// A spinning top dressed as a jester. It never walks; once it sees a target it spins up, then dashes in two straight
// legs: first onto the target's row or column, then straight at them. It aims where the target stands when the
// spin-up ends, and leaves sparkles and haze on every tile it crosses.
/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin
	name = "Mobile-Go-Spin"
	desc = "A spinning top dressed as a jester, all cones and ruffles. Whichever face is at the front is watching you."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "mobile_go_spin"
	icon_living = "mobile_go_spin"
	icon_dead = "mobile_go_spin_dead"
	maxHealth = 120
	health = 120
	var/windup_time = 1.5 SECONDS
	var/dash_damage = 40
	/// Time between each tile of a dash.
	var/dash_step_delay = 0.5
	/// Wait after a dash before it can spin up again.
	var/dash_cooldown_time = 3 SECONDS
	var/dash_cooldown = 0
	/// Sparkles left on each tile it dashes across, alongside one puff of haze.
	var/sparkles_per_tile = 2
	/// Each sparkle appears after a random delay up to this, so they do not all pop at once.
	var/sparkle_spread = 3
	/// Tiles a target it rams is thrown straight away from it. The throw is gentle, so it never knocks them down.
	var/knockback_tiles = 3
	/// TRUE from the start of the spin-up until the dash ends.
	var/busy = FALSE
	var/dashing = FALSE
	/// The swirling cloud around it while it winds up.
	var/obj/effect/gms_spin_cloud/windup_cloud
	// A human it kills gets its kill sequence (mobile_go_spin_kill.dm). Turned off, they just die and are thrown.
	plays_kill_sequence = TRUE
	kill_sequence_type = /datum/gms_kill_sequence/mobile_go_spin

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/Initialize()
	. = ..()
	AddComponent(/datum/component/knockback, knockback_tiles, FALSE, TRUE)

// It only ever moves by dashing.
/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/Move()
	if(!dashing)
		return FALSE
	return ..()

// The AI calls this every time it wants to close in on a target it can see; spin up instead of walking.
/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/Goto(target, delay, minimum_distance)
	StartSpin()

// No plain melee hit, even next to the target: the dash is its only attack.
/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/AttackingTarget(atom/attacked_target)
	StartSpin()

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/StartSpin()
	if(busy || dash_cooldown > world.time || stat == DEAD || !target)
		return
	busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(SpinAttack))

/// Spins up, then aims at where the target is now: the shorter leg first to line up on its row or column, then the
/// longer leg straight at it. Stops early at walls, blockers or the first body it runs into.
/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/SpinAttack()
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/mobile_go_spin_windup.ogg', 30, TRUE)
	// The tell: it spins twice as fast inside a swirl of dust, which breaks up once it dashes.
	icon_state = "mobile_go_spin_windup"
	windup_cloud = new(get_turf(src))
	SLEEP_CHECK_DEATH(windup_time)
	icon_state = icon_living
	EndWindupCloud()
	var/turf/goal = target ? get_turf(target) : null
	if(goal && goal.z == z)
		dashing = TRUE
		rushing = TRUE
		for(var/list/leg as anything in PlanLegs(goal))
			if(!Dash(leg[1], leg[2]))
				break
		dashing = FALSE
		rushing = FALSE
	dash_cooldown = world.time + dash_cooldown_time
	// A kill keeps it busy until the sequence lets it go.
	if(!killing)
		busy = FALSE

/// Dashes up to `tiles` tiles in one direction. A wall or blocker only cuts this leg short; returns FALSE once it
/// has rammed someone, which ends the whole attack.
/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/Dash(dir, tiles)
	for(var/i in 1 to tiles)
		var/turf/next = get_step(src, dir)
		if(!next || next.density)
			return TRUE
		var/mob/living/victim = DashVictim(next)
		if(victim)
			Ram(victim)
			return FALSE
		var/turf/left_behind = get_turf(src)
		if(!Move(next, dir))
			return TRUE
		Sparkle(left_behind)
		SLEEP_CHECK_DEATH(dash_step_delay)
	return TRUE

/// Which leg to dash first. It prefers lining up on the shorter leg, but takes the other order when a wall or blocker
/// sits on the first route and not the other; if both are blocked, whichever route ends closer to the target.
/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/PlanLegs(turf/goal)
	var/dx = goal.x - x
	var/dy = goal.y - y
	var/list/across = list(dx > 0 ? EAST : WEST, abs(dx))
	var/list/upright = list(dy > 0 ? NORTH : SOUTH, abs(dy))
	var/list/preferred = abs(dy) <= abs(dx) ? list(upright, across) : list(across, upright)
	var/list/other = list(preferred[2], preferred[1])
	var/turf/preferred_end = RouteEnd(preferred)
	if(preferred_end == goal)
		return preferred
	var/turf/other_end = RouteEnd(other)
	if(other_end == goal || get_dist(other_end, goal) < get_dist(preferred_end, goal))
		return other
	return preferred

/// Where a route of legs would stop, walking each leg until a wall or blocker. Bodies are ignored, since the dash rams them.
/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/RouteEnd(list/legs)
	var/turf/T = get_turf(src)
	for(var/list/leg as anything in legs)
		for(var/i in 1 to leg[2])
			var/turf/next = get_step(T, leg[1])
			if(!next || next.is_blocked_turf(TRUE, src))
				break
			T = next
	return T

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/DashVictim(turf/T)
	for(var/mob/living/L in T)
		if(L.stat != DEAD && !faction_check_mob(L))
			return L
	return null

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/Ram(mob/living/victim)
	do_attack_animation(victim)
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/gms_foe_ram_hit.ogg', 70, TRUE)
	visible_message(span_danger("[src] spins into [victim]!"))
	victim.deal_damage(dash_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	// A human it kills gets the full kill sequence instead of being thrown, if it is turned on.
	if(StartKill(victim))
		return
	// The knockback component throws whoever this signal names, away from us.
	SEND_SIGNAL(src, COMSIG_HOSTILE_ATTACKINGTARGET, victim)

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/Sparkle(turf/T)
	new /obj/effect/temp_visual/gms_spin_haze(T)
	for(var/i in 1 to sparkles_per_tile)
		addtimer(CALLBACK(src, PROC_REF(SpawnSparkle), T), rand(0, sparkle_spread))

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/SpawnSparkle(turf/T)
	new /obj/effect/temp_visual/gms_spin_sparkle(T)

/// A teal or yellow sparkle left on a tile the Mobile-Go-Spin dashed across, set somewhere random on the tile.
/obj/effect/temp_visual/gms_spin_sparkle
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "mobile_go_spin_sparkle_teal"
	duration = 1 SECONDS
	randomdir = FALSE
	/// Pixels the sparkle may be shifted each way from the middle of the tile.
	var/scatter = 11

/obj/effect/temp_visual/gms_spin_sparkle/Initialize()
	. = ..()
	icon_state = pick("mobile_go_spin_sparkle_teal", "mobile_go_spin_sparkle_yellow")
	pixel_x = base_pixel_x + rand(-scatter, scatter)
	pixel_y = base_pixel_y + rand(-scatter, scatter)

/// The smoky haze a dashing Mobile-Go-Spin leaves behind it.
/obj/effect/temp_visual/gms_spin_haze
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "mobile_go_spin_haze"
	duration = 0.8 SECONDS
	randomdir = FALSE
	layer = BELOW_MOB_LAYER

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/death(gibbed)
	EndWindupCloud()
	return ..()

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/Destroy()
	EndWindupCloud()
	return ..()

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/EndKill()
	. = ..()
	busy = FALSE
	dash_cooldown = world.time + dash_cooldown_time

/mob/living/simple_animal/hostile/gms_foe/mobile_go_spin/proc/EndWindupCloud()
	if(windup_cloud)
		windup_cloud.Dissipate()
		windup_cloud = null

/// The dust that swirls around a Mobile-Go-Spin while it winds up a dash.
/obj/effect/gms_spin_cloud
	name = "swirling dust"
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "mobile_go_spin_cloud"
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/// How long it takes to break up once the dash starts.
	var/dissipate_time = 0.4 SECONDS

/// Plays the break-up and removes the cloud when it is done.
/obj/effect/gms_spin_cloud/proc/Dissipate()
	icon_state = "mobile_go_spin_cloud_fade"
	QDEL_IN(src, dissipate_time)
