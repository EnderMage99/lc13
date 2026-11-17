// A wallet that never moves on its own. It marks the four straight lines out from it, and when a human steps onto one
// it rumbles, then charges down that line until something stops it. Whoever it runs into takes a heavy hit.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet
	name = "denim wallet"
	desc = "A fat denim wallet, stitched shut. It sits very still, and it is watching the aisle."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "denim_wallet"
	icon_living = "denim_wallet"
	icon_dead = "denim_wallet_dead"
	maxHealth = 150
	health = 150
	AIStatus = AI_OFF
	can_have_ai = FALSE
	/// Tiles it watches in each straight line, stopping at walls.
	var/scan_range = 10
	var/rumble_time = 0.75 SECONDS
	var/charge_damage = 90
	/// Object damage dealt to each solid structure it crashes into.
	var/structure_damage = 300
	/// Time between each tile of the charge.
	var/charge_step_delay = 0.5
	/// The charge ends after this many tiles even if nothing stops it.
	var/charge_max_distance = 20
	/// Wait after a charge ends before it starts watching again.
	var/recover_time = 1.5 SECONDS
	/// The blue flash comes this long after the charge ends, so it does not land on top of the crash dust.
	var/flash_delay = 0.3 SECONDS
	/// The flash it gives off, blue for denim.
	var/flash_type = /obj/effect/temp_visual/gms_wallet_flash
	/// When the flash goes off, everyone this close gets a light screen shake, or a heavier one if it rammed someone.
	var/shake_range = 2
	var/shake_duration = 2
	var/shake_strength = 0.15
	var/shake_duration_hit = 4
	var/shake_strength_hit = 0.4
	/// Off while it rumbles, charges and recovers.
	var/scanning = TRUE
	var/charging = FALSE
	/// The markers on the tiles it is watching.
	var/list/lane_markers = list()
	// A human it kills gets its kill sequence (denim_wallet_kill.dm). Turned off, they just die.
	plays_kill_sequence = TRUE
	kill_sequence_type = /datum/gms_kill_sequence/denim_wallet

/mob/living/simple_animal/hostile/gms_foe/denim_wallet/Initialize()
	. = ..()
	BuildLanes()

/mob/living/simple_animal/hostile/gms_foe/denim_wallet/Destroy()
	ClearLanes()
	return ..()

/mob/living/simple_animal/hostile/gms_foe/denim_wallet/death(gibbed)
	ClearWarnings()
	ClearLanes()
	animate(src, pixel_x = base_pixel_x)
	return ..()

/mob/living/simple_animal/hostile/gms_foe/denim_wallet/Move(atom/newloc, direct)
	if(!charging && !CanWalk(direct))
		return FALSE
	return ..()

/// Whether it may take a step outside a charge. The denim wallet only ever moves by charging.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/CanWalk(direct)
	return FALSE

/// Marks up to scan_range tiles in each straight line, stopping at walls. Charges at once if someone already stands on one.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/BuildLanes()
	ClearLanes()
	for(var/dir in GLOB.cardinals)
		var/turf/T = get_turf(src)
		for(var/i in 1 to scan_range)
			T = get_step(T, dir)
			if(!T || T.density)
				break
			lane_markers += new /obj/effect/gms_wallet_lane(T, src, dir)
	for(var/obj/effect/gms_wallet_lane/marker as anything in lane_markers)
		for(var/mob/living/carbon/human/H in marker.loc)
			Spotted(H, marker.lane_dir)
			if(!scanning)
				return

/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/ClearLanes()
	QDEL_LIST(lane_markers)

/// Called by a lane marker when a human steps onto it.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/Spotted(mob/living/carbon/human/H, dir)
	if(!scanning || stat == DEAD || H.stat == DEAD || faction_check_mob(H))
		return
	scanning = FALSE
	INVOKE_ASYNC(src, PROC_REF(Charge), dir)

/// Rumbles in place, then charges down the line until it hits a wall, a blocker or someone.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/Charge(charge_dir)
	ClearLanes()
	setDir(charge_dir)
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/denim_wallet_spotted.ogg', 60, TRUE)
	ShowWarnings(ChargeTurfs(charge_dir), rumble_time)
	animate(src, pixel_x = base_pixel_x + 1, time = 0.5, loop = -1)
	animate(pixel_x = base_pixel_x - 1, time = 0.5)
	SLEEP_CHECK_DEATH(rumble_time)
	ClearWarnings()
	animate(src, pixel_x = base_pixel_x)
	charging = TRUE
	rushing = TRUE
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/denim_wallet_charge.ogg', 60, TRUE)
	// Set when a wall, a blocker or a body stops the charge, rather than running out of distance.
	var/crashed = FALSE
	var/hit_someone = FALSE
	for(var/i in 1 to charge_max_distance)
		var/turf/next = get_step(src, charge_dir)
		if(!next || next.density)
			crashed = TRUE
			break
		var/mob/living/victim = ChargeVictim(next)
		if(victim)
			// A kill hands the wallet over to its kill sequence, which lets it go again when it is done.
			if(Ram(victim))
				charging = FALSE
				rushing = FALSE
				return
			crashed = TRUE
			hit_someone = TRUE
			break
		var/turf/left_behind = get_turf(src)
		if(!Move(next, charge_dir))
			crashed = TRUE
			SmashStructures(next)
			break
		new /obj/effect/temp_visual/gms_wallet_dust(left_behind)
		SLEEP_CHECK_DEATH(charge_step_delay)
	charging = FALSE
	rushing = FALSE
	if(crashed)
		new /obj/effect/temp_visual/gms_wallet_impact(get_turf(src), turn(charge_dir, 180))
	addtimer(CALLBACK(src, PROC_REF(Flash), get_turf(src), hit_someone), flash_delay)
	SLEEP_CHECK_DEATH(recover_time)
	scanning = TRUE
	BuildLanes()

/// The tiles a charge in that direction would cross: up to charge_max_distance, stopping at the first wall.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/ChargeTurfs(charge_dir)
	. = list()
	var/turf/T = get_turf(src)
	for(var/i in 1 to charge_max_distance)
		T = get_step(T, charge_dir)
		if(!T || T.density)
			return
		. += T

/// The blue flash where the charge ended, shaking the screens of everyone nearby.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/Flash(turf/T, hit_someone)
	new flash_type(T)
	for(var/mob/M in range(shake_range, T))
		shake_camera(M, hit_someone ? shake_duration_hit : shake_duration, hit_someone ? shake_strength_hit : shake_strength)

/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/ChargeVictim(turf/T)
	for(var/mob/living/L in T)
		if(L.stat != DEAD && !faction_check_mob(L))
			return L
	return null

/// Crashing into solid structures, like tables or shelves, hits each one the way its melee attack would, only harder.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/SmashStructures(turf/T)
	for(var/obj/structure/S in T)
		if(S.density)
			S.attack_generic(src, structure_damage, RED_DAMAGE)

/// Returns TRUE if the hit killed them and started the kill sequence.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/proc/Ram(mob/living/victim)
	var/was_alive = victim.stat != DEAD
	do_attack_animation(victim)
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/gms_foe_ram_hit.ogg', 70, TRUE)
	visible_message(span_danger("[src] slams into [victim]!"))
	victim.deal_damage(charge_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	return was_alive && StartKill(victim)

// Back on its own tile after a kill, it starts watching its lanes again.
/mob/living/simple_animal/hostile/gms_foe/denim_wallet/EndKill()
	. = ..()
	scanning = TRUE
	BuildLanes()

/// An unseen marker on a tile a denim wallet is watching. Stepping onto it sets the wallet off.
/obj/effect/gms_wallet_lane
	name = "wallet lane"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	var/mob/living/simple_animal/hostile/gms_foe/denim_wallet/watcher
	/// Direction from the wallet to this tile, which is the way it charges.
	var/lane_dir

/obj/effect/gms_wallet_lane/Initialize(mapload, mob/living/simple_animal/hostile/gms_foe/denim_wallet/new_watcher, new_lane_dir)
	. = ..()
	watcher = new_watcher
	lane_dir = new_lane_dir

/obj/effect/gms_wallet_lane/Destroy()
	watcher = null
	return ..()

/obj/effect/gms_wallet_lane/Crossed(atom/movable/AM)
	. = ..()
	if(ishuman(AM))
		watcher?.Spotted(AM, lane_dir)

/// Dust kicked up on each tile a charging denim wallet leaves behind. It fades in, swells and fades away.
/obj/effect/temp_visual/gms_wallet_dust
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "denim_wallet_dust"
	duration = 0.4 SECONDS
	randomdir = FALSE
	layer = BELOW_MOB_LAYER
	/// Pixels the puff may be shifted each way, so a trail of them does not line up.
	var/scatter = 3

/obj/effect/temp_visual/gms_wallet_dust/Initialize()
	. = ..()
	pixel_x = base_pixel_x + rand(-scatter, scatter)
	pixel_y = base_pixel_y + rand(-scatter, scatter)

/// A heavier burst of dust when a charging denim wallet crashes into a wall or a body. It flies off in its dir,
/// away from what was hit. The sprite is 64x64, centred on the tile.
/obj/effect/temp_visual/gms_wallet_impact
	icon = 'icons/mob/gms/gms_64x64.dmi'
	icon_state = "denim_wallet_impact"
	duration = 0.4 SECONDS
	randomdir = FALSE
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16

/// The blue flash a denim wallet gives off when its charge ends. The sprite is 96x96, centred on the tile.
/obj/effect/temp_visual/gms_wallet_flash
	icon = 'icons/mob/gms/gms_96x96.dmi'
	icon_state = "denim_wallet_flash"
	duration = 0.4 SECONDS
	randomdir = FALSE
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32

/obj/effect/temp_visual/gms_wallet_impact/Initialize(mapload, flight_dir)
	. = ..()
	if(flight_dir)
		setDir(flight_dir)
