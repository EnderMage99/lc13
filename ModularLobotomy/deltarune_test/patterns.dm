/// Bullet pattern descriptor used by DeltaruneBattle TGUI.
/// All coordinates are in arena pixels (200x150 viewport).
/// Bullets are { t, x, y, vx, vy } - t is spawn time in deciseconds from round start.
/datum/deltarune_battle/proc/MakeDiamondToss()
	var/list/bullets = list()
	var/arena_w = 200
	var/arena_h = 150
	// Six diamonds sweep in from alternating sides, each 12px slower than the last.
	for(var/i in 0 to 5)
		var/from_left = (i % 2 == 0)
		var/spawn_y = 30 + (i * 18)
		var/speed = 60 + (i * 6)
		bullets += list(list(
			"t"  = i * 6,
			"x"  = from_left ? -20 : (arena_w + 20),
			"y"  = spawn_y,
			"vx" = from_left ? speed : -speed,
			"vy" = 0,
		))
	// Two diving diamonds from the top to mix things up.
	for(var/i in 0 to 1)
		bullets += list(list(
			"t"  = 30 + (i * 8),
			"x"  = 60 + (i * 60),
			"y"  = -20,
			"vx" = 0,
			"vy" = 50,
		))
	return list(
		"arena_w"  = arena_w,
		"arena_h"  = arena_h,
		"duration" = 60,  // deciseconds, ~6 real seconds
		"bullets"  = bullets,
	)
