// A leather cousin of the denim wallet. It watches no lanes: it walks after its target along rows and columns, never
// diagonally, trying to get onto the same row or column. Its "shot" is the charge: each time it would open fire, it
// checks whether the target is in line with nothing between them, and if so rumbles and charges like the denim wallet.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet
	name = "leather wallet"
	desc = "A boxy leather wallet, sewn shut over something raw. It shuffles along the aisles, squaring up to whoever it sees."
	icon_state = "leather_wallet"
	icon_living = "leather_wallet"
	icon_dead = "leather_wallet_dead"
	AIStatus = AI_ON
	can_have_ai = TRUE
	move_to_delay = 4
	ranged = TRUE
	ranged_cooldown_time = 0.5 SECONDS
	/// Each step it walks squashes it down by this much, then it bounces up this many pixels and settles.
	var/step_squash = 0.12
	var/step_bounce = 2
	/// Each of the squash, the bounce and the settle takes this long, all three within one step.
	var/step_squash_time = 1
	flash_type = /obj/effect/temp_visual/gms_wallet_flash/leather
	kill_sequence_type = /datum/gms_kill_sequence/denim_wallet/leather_wallet

// Only while it is free to act, and only along rows and columns.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/CanWalk(direct)
	return scanning && !ISDIAGONALDIR(direct)

// It watches no lanes; OpenFire() looks for its target instead.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/BuildLanes()
	return

// Fires nothing: if the target is in line, it charges at them.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/OpenFire(atom/A)
	ranged_cooldown = world.time + ranged_cooldown_time
	if(!scanning || killing || stat == DEAD || !isliving(target))
		return
	var/turf/goal = get_turf(target)
	if(goal?.z != z || !InLine(goal))
		return
	walk(src, 0)
	Spotted(target, get_dir(src, goal))

/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/Goto(target, delay, minimum_distance)
	LineUp()

// No plain melee hit, even next to the target: the charge is its only attack.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/AttackingTarget(atom/attacked_target)
	return

// Every step it walks gets a little squash and bounce, and it steers again so it stops on the line instead of passing it.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(scanning && !Forced && stat != DEAD)
		Waddle()
	LineUp()

/// Walks a step closer to being in line with its target, or stops once it is and opens fire if its cooldown is up.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/proc/LineUp()
	if(!scanning || killing || stat == DEAD || !isliving(target))
		return
	var/turf/goal = get_turf(target)
	if(!goal || goal.z != z)
		return
	if(InLine(goal))
		walk(src, 0)
		// The AI only aims every couple of seconds, so a step that lines it up fires at once if the cooldown is up.
		if(ranged_cooldown <= world.time)
			OpenFire(target)
		return
	walk(src, LineUpDir(goal), move_to_delay)

/// Whether the turf shares its row or column and is within scan_range. The charge itself stops at walls.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/proc/InLine(turf/goal)
	return (goal.x == x || goal.y == y) && goal != loc && get_dist(src, goal) <= scan_range

/// Which way to step: the shorter gap first, the nearest way into line, or the other way if that step is blocked.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/proc/LineUpDir(turf/goal)
	var/dx = goal.x - x
	var/dy = goal.y - y
	var/across = dx > 0 ? EAST : WEST
	var/upright = dy > 0 ? NORTH : SOUTH
	var/list/dirs = abs(dx) <= abs(dy) ? list(across, upright) : list(upright, across)
	for(var/dir in dirs)
		if(dir == across ? !dx : !dy)
			continue
		var/turf/next = get_step(src, dir)
		if(next && !next.is_blocked_turf(TRUE, src))
			return dir
	return 0

/// The leather wallet's flash, the same burst in yellow.
/obj/effect/temp_visual/gms_wallet_flash/leather
	icon_state = "leather_wallet_flash"

/// Squashes down about its base as it lands a step, then bounces up and settles.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet/proc/Waddle()
	var/matrix/squashed = matrix()
	squashed.Scale(1 + step_squash, 1 - step_squash)
	squashed.Translate(0, -world.icon_size / 2 * step_squash)
	animate(src, transform = squashed, time = step_squash_time, easing = SINE_EASING | EASE_OUT)
	animate(transform = matrix(), pixel_y = base_pixel_y + step_bounce, time = step_squash_time, easing = SINE_EASING | EASE_OUT)
	animate(pixel_y = base_pixel_y, time = step_squash_time, easing = SINE_EASING | EASE_IN)
