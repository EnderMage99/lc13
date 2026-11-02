// The 3rd Floor Manager, a boss of the Grand Magasin: a tall figure in a striped tent of a coat, carrying a birdcage.
// He blocks the tiles his sprite covers, which change as he turns. Every so often he stops to strike the half circle in
// front of him, slam the floor all round him, or charge across the room, hitting everything near him on the way.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager
	name = "3rd Floor Manager"
	desc = "A towering figure in a striped tent of a coat, a birdcage swinging from one hand. Something inside it is humming."
	icon = 'icons/mob/gms/gms_192x192.dmi'
	icon_state = "third_floor_manager"
	icon_living = "third_floor_manager"
	icon_dead = "third_floor_manager_dead"
	// The 192x192 sprite stands on the row below his own tile, centred on it.
	pixel_x = -80
	base_pixel_x = -80
	pixel_y = -32
	base_pixel_y = -32
	offsets_pixel_x = list("south" = -80, "north" = -80, "west" = -80, "east" = -80)
	offsets_pixel_y = list("south" = -32, "north" = -32, "west" = -32, "east" = -32)
	maxHealth = 3000
	health = 3000
	move_to_delay = 4
	death_message = "sways, and topples over."
	/// TRUE while he is using a skill; he does not walk meanwhile.
	var/busy = FALSE
	/// The tiles he blocks besides his own in each direction, as offsets from his middle, matching where his sprite
	/// really is (from `gms.exe manager_mask`). His blockers are moved to fit whenever he turns.
	var/list/footprints = list(
		"south" = list(list(-1, 0), list(1, 0), list(-1, -1), list(0, -1), list(1, -1)),
		"north" = list(list(-1, 0), list(1, 0), list(-1, -1), list(0, -1), list(1, -1)),
		"east" = list(list(1, 0), list(-1, -1), list(0, -1), list(1, -1), list(2, -1)),
		"west" = list(list(-1, 0), list(-2, -1), list(-1, -1), list(0, -1), list(1, -1)),
		)
	/// How far around him he looks for foes, and the pause after each skill before the next.
	var/skill_range = 9
	var/skill_gap_time = 3 SECONDS
	var/skill_gap = 0
	/// How long the walk animation keeps playing after each step, so it runs on between steps.
	var/walk_hold = 5
	/// His raise and drop poses are on a 256x256 sheet, standing on its bottom row like his own sprite.
	var/attack_icon = 'icons/mob/gms/gms_256x256.dmi'
	var/attack_shift_x = -112
	var/windup_sound = 'ModularLobotomy/_Lobotomysounds/gms/leatherfather_windup.ogg'
	var/hit_sound = 'ModularLobotomy/_Lobotomysounds/gms/leatherfather_slam.ogg'
	/// Anyone right by him, within shove_range of his middle, is thrown shove_distance tiles away as any skill starts.
	var/shove_range = 1
	var/shove_distance = 4
	/// The Strike: the half circle in front of him, out to strike_range, hit for strike_damage after strike_windup. Only
	/// tiles he can see are hit. He holds the drop for strike_hold afterwards.
	var/strike_range = 6
	var/strike_damage = 50
	var/strike_windup = 1.2 SECONDS
	var/strike_hold = 0.6 SECONDS
	var/strike_cooldown_time = 8 SECONDS
	var/strike_cooldown = 0
	/// The Slam: every tile he can see within slam_range of him, hit for slam_damage after slam_windup. The effect is
	/// drawn reaching slam_art_reach pixels, so it is scaled up to match the range.
	var/slam_range = 6
	var/slam_damage = 40
	var/slam_windup = 1.5 SECONDS
	var/slam_hold = 0.8 SECONDS
	var/slam_art_reach = 120
	var/slam_cooldown_time = 15 SECONDS
	var/slam_cooldown = 0
	/// Everyone the slam hits is thrown this many tiles straight away from him.
	var/slam_knock_distance = 5
	/// How fast anyone he knocks back flies.
	var/knock_speed = 2
	/// Solid structures and machines in an attack's area take this many times the damage a person would.
	var/structure_mult = 2
	/// The Charge: after dash_windup he runs up to dash_max_distance tiles, one every dash_step_delay, until a wall is in
	/// his way. Each step hits dash_damage once to anyone in the box round him: dash_ahead tiles in front of his middle
	/// to dash_behind behind, dash_left to his left to dash_right to his right (6x4 in all). He only needs room for his
	/// own tile, so he fits down a corridor, and runs through structures, which take dash_crush_mult times the damage.
	var/dash_crush_mult = 3
	var/dash_damage = 75
	var/dash_windup = 1 SECONDS
	var/dash_step_delay = 1
	var/dash_max_distance = 20
	var/dash_min_distance = 4
	var/dash_ahead = 3
	var/dash_behind = 2
	var/dash_left = 2
	var/dash_right = 1
	var/dash_recover_time = 1 SECONDS
	var/dash_cooldown_time = 12 SECONDS
	var/dash_cooldown = 0
	/// Anyone the charge hits, or who is in his footprint as he runs, is thrown this many tiles aside, out of his way.
	var/dash_knock_distance = 5
	/// TRUE while he takes a step, which has already checked the footprint he turns to.
	var/stepping = FALSE
	/// The Birdcage: he lifts his cage over cage_raise_time and his bird sings for song_time. As it starts, every foe he
	/// can see within cage_range is shut in a birdcage. If the song ends, everyone he can see within song_range takes
	/// song_damage, and solid structures there take structure_mult times that. A hit while the bird sings, from anyone
	/// not in a cage, Staggers him for stagger_time instead: the song stops, every birdcage breaks and he stands still.
	var/cage_range = 14
	var/song_range = 12
	var/song_damage = 100
	var/cage_raise_time = 4
	var/song_time = 10 SECONDS
	var/stagger_time = 5 SECONDS
	var/birdcage_cooldown_time = 45 SECONDS
	var/birdcage_cooldown = 0
	var/cage_sound = 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_charge.ogg'
	var/stagger_sound = 'ModularLobotomy/_Lobotomysounds/gms/gms_foe_ram_hit.ogg'
	/// TRUE while the bird sings, when a hit Staggers him.
	var/singing = FALSE
	/// The birdcages shut this song, and the symbols that fly from the bird's beak while it sings.
	var/list/birdcages = list()
	var/mutable_appearance/song_overlay
	/// How far he sways each way while Staggered.
	var/stagger_sway = 2
	/// The dash overlay he wears while charging, 256x256 round his 192x192 sprite.
	var/mutable_appearance/dash_overlay
	var/dash_shift = -32
	/// How long he takes to fade once dead.
	var/death_fade = 3 SECONDS

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/Initialize()
	. = ..()
	// The box round every footprint, which makes enough blockers for the biggest one.
	SetOccupiedTiles(1, 0, 2, 2)
	PlaceBlockers(dir)
	dash_overlay = mutable_appearance(attack_icon, "third_floor_manager_dash", ABOVE_MOB_LAYER)
	dash_overlay.pixel_x = dash_shift
	dash_overlay.pixel_y = dash_shift
	song_overlay = mutable_appearance(icon, "third_floor_manager_song")

// A step must not walk his footprint deeper into walls or onto people. Diagonal steps are split into two straight
// ones, which come back through here.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/Move(atom/newloc, direct)
	if(busy)
		return FALSE
	var/move_dir = direct || get_dir(src, newloc)
	if(!(move_dir & (move_dir - 1)) && !CanStep(get_turf(src), move_dir))
		return FALSE
	stepping = TRUE
	. = ..()
	stepping = FALSE

// Walking about, he will not turn his footprint onto someone. His skills turn him anyway, and shove them out instead.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/setDir(newdir)
	if(!busy && !stepping && newdir != dir && footprints[dir2text(newdir)] && length(Overlapped(get_turf(src), newdir)))
		return
	return ..()

// Diagonal turns only happen for a moment at the start of a diagonal step, and have no footprint, so they are skipped.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/OnDirChange(atom/thing, dir, newdir)
	if(!footprints[dir2text(newdir)])
		return
	. = ..()
	PlaceBlockers(newdir)

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/Goto(target, delay, minimum_distance)
	if(busy)
		return
	return ..()

// He has no plain blow; all his damage comes from his skills.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/AttackingTarget(atom/attacked_target)
	return

// Someone in a birdcage cannot get a short weapon through the bars at him.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/attackby(obj/item/O, mob/user, params)
	if(BarredFrom(user, O.reach))
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/attack_hand(mob/living/carbon/human/M)
	if(BarredFrom(M, 1))
		return
	return ..()

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/attack_paw(mob/living/carbon/human/M)
	if(BarredFrom(M, 1))
		return
	return ..()

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/attack_animal(mob/living/simple_animal/M, damage)
	if(BarredFrom(M, 1))
		return
	return ..()

/// Whether the bars of a birdcage stop someone's melee blow at him: they are caged and the blow only reaches one tile.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/BarredFrom(mob/user, reach)
	if(reach > 1 || !IsCaged(user))
		return FALSE
	to_chat(user, span_warning("The bars of the birdcage are in the way!"))
	return TRUE

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(busy || stat == DEAD)
		return
	icon_state = "third_floor_manager_walk"
	addtimer(CALLBACK(src, PROC_REF(StopWalking)), walk_hold, TIMER_UNIQUE | TIMER_OVERRIDE)

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/Life()
	. = ..()
	if(!. || busy || !target || skill_gap > world.time)
		return
	var/list/ready = ReadySkills()
	if(length(ready))
		StartSkill(pick(ready))

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/death(gibbed)
	StopEverything()
	. = ..()
	animate(src, alpha = 0, time = death_fade)
	QDEL_IN(src, death_fade)

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/Destroy()
	StopEverything()
	return ..()

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/StopWalking()
	if(icon_state == "third_floor_manager_walk")
		icon_state = icon_living

/// Lets go of whatever a skill was in the middle of: the warnings, the dash, the song, the cages and the attack pose.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/StopEverything()
	ClearWarnings()
	cut_overlay(dash_overlay)
	rushing = FALSE
	StopSong()
	UsePose(null)

// A hit from someone free while the bird sings Staggers him.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(singing && ismob(source) && !IsCaged(source) && !faction_check_mob(source))
		Stagger()

/// The skills he could start on his target now.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/ReadySkills()
	. = list()
	if(!(target in view(skill_range, src)))
		return
	var/dist = get_dist(src, target)
	if(strike_cooldown <= world.time && get_dist_euclidian(src, target) <= strike_range)
		. += PROC_REF(Strike)
	if(slam_cooldown <= world.time && dist <= slam_range)
		. += PROC_REF(Slam)
	if(dash_cooldown <= world.time && dist >= dash_min_distance && Across(target) <= min(dash_left, dash_right))
		. += PROC_REF(Charge)
	if(birdcage_cooldown <= world.time && length(CageTargets()))
		. += PROC_REF(Birdcage)

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/StartSkill(skill)
	busy = TRUE
	walk(src, 0)
	Shove()
	INVOKE_ASYNC(src, skill)

/// Throws every foe within shove_range of his middle away from him, so nobody can hide right against him.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Shove()
	for(var/mob/living/L in range(shove_range, src))
		if(L == src || L.stat == DEAD || istype(L, /mob/living/simple_animal/projectile_blocker_dummy) || faction_check_mob(L))
			continue
		Knock(L, get_dir(src, L), shove_distance)

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/EndSkill()
	busy = FALSE
	skill_gap = world.time + skill_gap_time
	UsePose(null)

/// How many tiles the atom is off the nearest straight line out from his middle.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Across(atom/A)
	return min(abs(A.x - x), abs(A.y - y))

/// The straight direction nearest to the way the atom lies from him.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/StraightDir(atom/A)
	return abs(A.x - x) >= abs(A.y - y) ? (A.x > x ? EAST : WEST) : (A.y > y ? NORTH : SOUTH)

/// Turns him to face the atom along the nearest straight line, shoving out anyone his new footprint lands on.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/FaceStraight(atom/A)
	var/facing = StraightDir(A)
	var/list/in_way = Overlapped(get_turf(src), facing)
	setDir(facing)
	for(var/mob/living/L as anything in in_way)
		Knock(L, get_dir(src, L) || pick(GLOB.cardinals))

/// Whether a living mob other than him and his blockers stands on the turf. The dead are stepped over.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/LivingOn(turf/T)
	for(var/mob/living/L in T)
		if(L != src && L.stat != DEAD && !istype(L, /mob/living/simple_animal/projectile_blocker_dummy))
			return TRUE
	return FALSE

/// The living mobs on tiles his footprint round `centre` would cover facing `facing`, that it does not cover now.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Overlapped(turf/centre, facing)
	. = list()
	var/list/now = Footprint(centre, dir)
	for(var/turf/T in Footprint(centre, facing))
		if(T in now)
			continue
		for(var/mob/living/L in T)
			if(L != src && L.stat != DEAD && !istype(L, /mob/living/simple_animal/projectile_blocker_dummy))
				. += L

/// Throws someone `distance` tiles towards `knock_dir`.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Knock(mob/living/L, knock_dir, distance = dash_knock_distance)
	L.throw_at(get_ranged_target_turf(L, knock_dir, distance), distance, knock_speed, src)

/// Damages every solid structure and machine on the turf up to `damage` in all for one attack. `dealt` holds what each
/// has taken so far, so one caught again takes only the difference.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/SmashTurf(turf/T, damage, list/dealt)
	for(var/obj/O in T)
		if(!O.density || !(isstructure(O) || ismachinery(O)) || (O.resistance_flags & INDESTRUCTIBLE))
			continue
		var/more = damage - dealt[O]
		if(more <= 0)
			continue
		dealt[O] = damage
		O.take_damage(more, RED_DAMAGE)

/// Moves his blockers onto his footprint for `facing`. Any spare ones wait on his own tile, where they change nothing.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/PlaceBlockers(facing)
	var/list/mask = footprints[dir2text(facing)]
	for(var/i in 1 to length(projectile_blockers))
		var/mob/living/simple_animal/projectile_blocker_dummy/D = projectile_blockers[i]
		var/list/offset = i <= length(mask) ? mask[i] : list(0, 0)
		D.offset_x = offset[1]
		D.offset_y = offset[2]
		D.OnParentMoved()

/// Every turf his footprint for `facing` covers round `centre`, his own tile first. Null where it runs off the map.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Footprint(turf/centre, facing)
	. = list()
	for(var/list/offset as anything in list(list(0, 0)) + footprints[dir2text(facing)])
		. += locate(centre.x + offset[1], centre.y + offset[2], centre.z)

/// Shows a pose from his 256x256 attack sheet, or his own sprite again for null.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/UsePose(state)
	icon = state ? attack_icon : initial(icon)
	icon_state = state || (stat == DEAD ? icon_dead : icon_living)
	pixel_x = state ? attack_shift_x : initial(pixel_x)
	base_pixel_x = pixel_x

/// The turf `along` tiles in front of `centre` and `across` tiles to the right, facing `facing`, or null off the map.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Offset(turf/centre, facing, along, across)
	var/fx = (facing & EAST) ? 1 : ((facing & WEST) ? -1 : 0)
	var/fy = (facing & NORTH) ? 1 : ((facing & SOUTH) ? -1 : 0)
	return locate(centre.x + fx * along + fy * across, centre.y + fy * along - fx * across, centre.z)

/// The Strike tiles: every open tile he can see within strike_range of his middle that is level with it or in front.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/StrikeTurfs()
	. = list()
	var/fx = (dir & EAST) ? 1 : ((dir & WEST) ? -1 : 0)
	var/fy = (dir & NORTH) ? 1 : ((dir & SOUTH) ? -1 : 0)
	for(var/turf/T in view(strike_range, src))
		if(T.density || get_dist_euclidian(src, T) > strike_range)
			continue
		if((T.x - x) * fx + (T.y - y) * fy >= 0)
			. += T

/// The Strike: he raises his arms, then brings them down on the half circle in front of him.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Strike()
	strike_cooldown = world.time + strike_cooldown_time
	FaceStraight(target)
	var/list/turfs = StrikeTurfs()
	ShowWarnings(turfs, strike_windup)
	UsePose("third_floor_manager_raise")
	playsound(src, windup_sound, 60, TRUE)
	SLEEP_CHECK_DEATH(strike_windup)
	ClearWarnings()
	UsePose("third_floor_manager_drop")
	playsound(src, hit_sound, 70, TRUE)
	var/list/hit_list = list()
	var/list/smashed = list()
	for(var/turf/T as anything in turfs)
		new /obj/effect/temp_visual/smash_effect(T)
		hit_list = HurtInTurf(T, hit_list, strike_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		SmashTurf(T, strike_damage * structure_mult, smashed)
	SLEEP_CHECK_DEATH(strike_hold)
	EndSkill()

/// Every open tile he can see within slam_range of his middle.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/SlamTurfs()
	. = list()
	for(var/turf/T in view(slam_range, src))
		if(!T.density && get_dist_euclidian(src, T) <= slam_range)
			. += T

/// The Slam: he raises his arms, then slams the floor, and light bursts up all round him.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Slam()
	slam_cooldown = world.time + slam_cooldown_time
	var/list/turfs = SlamTurfs()
	ShowWarnings(turfs, slam_windup)
	UsePose("third_floor_manager_raise")
	playsound(src, windup_sound, 60, TRUE)
	SLEEP_CHECK_DEATH(slam_windup)
	ClearWarnings()
	UsePose("third_floor_manager_drop")
	playsound(src, hit_sound, 80, TRUE)
	new /obj/effect/temp_visual/gms_manager_slam(get_turf(src), (slam_range + 0.5) * world.icon_size / slam_art_reach)
	var/list/hit_list = list()
	var/list/smashed = list()
	for(var/turf/T as anything in turfs)
		hit_list = HurtInTurf(T, hit_list, slam_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		SmashTurf(T, slam_damage * structure_mult, smashed)
	for(var/mob/living/L in hit_list)
		Knock(L, get_dir(src, L) || pick(GLOB.cardinals), slam_knock_distance)
	for(var/mob/M in range(slam_range, src))
		shake_camera(M, 3, 0.5)
	SLEEP_CHECK_DEATH(slam_hold)
	EndSkill()

/// Whether he can walk a step from `centre` towards `facing`, turning that way. His own tile must be clear, his
/// footprint must stay on the map and off anyone living, and it must not end up in more solid tiles than it is now. So
/// he keeps out of walls in the open, but can walk back out of a corridor a charge left him in.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/CanStep(turf/centre, facing)
	var/turf/next = get_step(centre, facing)
	if(!next || next.is_blocked_turf(TRUE))
		return FALSE
	var/list/now = Footprint(centre, dir)
	var/list/after = Footprint(next, facing)
	if(null in after)
		return FALSE
	// Someone lying down is not dense, but he still does not walk onto them.
	for(var/turf/T as anything in after - now)
		if(LivingOn(T))
			return FALSE
	return SolidTiles(after) <= SolidTiles(now)

/// How many of the turfs are walls, or hold something solid that is not a mob.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/SolidTiles(list/turfs)
	. = 0
	for(var/turf/T in turfs)
		if(T.is_blocked_turf(TRUE))
			.++

/// A charge only needs his own tile clear of walls and his footprint on the map. It runs through people and structures,
/// and squeezes down corridors.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/CanCharge(turf/centre, facing)
	var/turf/next = get_step(centre, facing)
	if(!next || next.density)
		return FALSE
	return !(null in Footprint(next, facing))

/// The tiles of the box a charge step hits round `centre`.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/ChargeBox(turf/centre)
	. = list()
	for(var/along in -dash_behind to dash_ahead)
		for(var/across in -dash_left to dash_right)
			var/turf/T = Offset(centre, dir, along, across)
			if(T)
				. += T

/// The side of his path the mob is on, at right angles to the way he faces. Straight ahead or behind, either side.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/SideAway(mob/living/L)
	var/fx = (dir & EAST) ? 1 : ((dir & WEST) ? -1 : 0)
	var/fy = (dir & NORTH) ? 1 : ((dir & SOUTH) ? -1 : 0)
	var/across = fy * (L.x - x) - fx * (L.y - y)
	if(!across)
		return pick(turn(dir, 90), turn(dir, -90))
	return across > 0 ? turn(dir, -90) : turn(dir, 90)

/// The Charge: he turns to his target, braces, and runs across the room, hitting everything near him once.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Charge()
	dash_cooldown = world.time + dash_cooldown_time
	FaceStraight(target)
	// Every tile the box will sweep over on the way, so the whole charge can be seen coming.
	var/list/path = list()
	var/turf/centre = get_turf(src)
	var/steps = 0
	while(steps < dash_max_distance && CanCharge(centre, dir))
		centre = get_step(centre, dir)
		steps++
		for(var/turf/T as anything in ChargeBox(centre))
			if(!T.density)
				path |= T
	if(!steps)
		EndSkill()
		return
	ShowWarnings(path, dash_windup)
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/denim_wallet_spotted.ogg', 70, TRUE)
	SLEEP_CHECK_DEATH(dash_windup)
	ClearWarnings()
	add_overlay(dash_overlay)
	rushing = TRUE
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/denim_wallet_charge.ogg', 70, TRUE)
	var/list/hit_list = list()
	var/list/smashed = list()
	for(var/i in 1 to steps)
		if(!CanCharge(get_turf(src), dir))
			break
		forceMove(get_step(src, dir))
		var/list/before = hit_list.Copy()
		for(var/turf/T as anything in ChargeBox(get_turf(src)))
			hit_list = HurtInTurf(T, hit_list, dash_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			SmashTurf(T, dash_damage * structure_mult, smashed)
		// What he runs right through takes the rest of the crushing damage on top.
		for(var/turf/T in Footprint(get_turf(src), dir))
			SmashTurf(T, dash_damage * dash_crush_mult, smashed)
		// Everyone just hit, and anyone already hit who is still where he runs, is thrown aside.
		var/list/knocked = hit_list - before
		for(var/turf/T in Footprint(get_turf(src), dir))
			for(var/mob/living/L in T)
				if(L != src && L.stat != DEAD && !istype(L, /mob/living/simple_animal/projectile_blocker_dummy))
					knocked |= L
		for(var/mob/living/L in knocked)
			Knock(L, SideAway(L))
		SLEEP_CHECK_DEATH(dash_step_delay)
	rushing = FALSE
	cut_overlay(dash_overlay)
	SLEEP_CHECK_DEATH(dash_recover_time)
	EndSkill()

/// Every living foe he can see within cage_range who is not in a cage yet.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/CageTargets()
	. = list()
	for(var/mob/living/L in view(cage_range, src))
		if(L == src || L.stat == DEAD || (L.status_flags & GODMODE) || faction_check_mob(L) || IsCaged(L))
			continue
		. += L

/// Whether the mob is shut in a birdcage.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/IsCaged(mob/M)
	for(var/obj/structure/gms_birdcage/C in get_turf(M))
		if(M in C.occupants)
			return TRUE
	return FALSE

/// Every open tile he can see within song_range: the room the song fills.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/SongTurfs()
	. = list()
	for(var/turf/T in view(song_range, src))
		if(!T.density)
			. += T

/// The Birdcage: he lifts his cage, shuts his foes in cages of their own, and his bird sings. If nobody free hits him
/// before the song ends, it bursts over the whole room.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Birdcage()
	birdcage_cooldown = world.time + birdcage_cooldown_time
	FaceStraight(target)
	icon_state = "third_floor_manager_cage_raise"
	playsound(src, cage_sound, 75, FALSE)
	SLEEP_CHECK_DEATH(cage_raise_time)
	for(var/mob/living/L as anything in CageTargets())
		// Two caught on one tile share a cage.
		var/obj/structure/gms_birdcage/C = locate() in get_turf(L)
		if(C)
			C.Trap(L)
			continue
		birdcages += new /obj/structure/gms_birdcage(get_turf(L), L)
	var/list/turfs = SongTurfs()
	ShowWarnings(turfs, song_time)
	icon_state = "third_floor_manager_sing"
	add_overlay(song_overlay)
	singing = TRUE
	var/song_end = world.time + song_time
	while(world.time < song_end)
		SLEEP_CHECK_DEATH(1)
		// Staggered: Stagger() has taken over and ends the skill itself.
		if(!singing)
			return
	StopSong()
	icon_state = icon_living
	new /obj/effect/temp_visual/gms_manager_burst(get_turf(src))
	playsound(src, hit_sound, 100, TRUE)
	var/list/hit_list = list()
	var/list/smashed = list()
	for(var/turf/T as anything in turfs)
		hit_list = HurtInTurf(T, hit_list, song_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
		SmashTurf(T, song_damage * structure_mult, smashed)
	for(var/mob/M in range(song_range, src))
		shake_camera(M, 4, 1)
	EndSkill()

/// Ends the song, if it is playing: the warnings and symbols go, and every birdcage breaks.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/StopSong()
	singing = FALSE
	ClearWarnings()
	cut_overlay(song_overlay)
	for(var/obj/structure/gms_birdcage/C as anything in birdcages)
		if(!QDELETED(C))
			C.Shatter()
	birdcages.Cut()

/// The Stagger: the song breaks off and he reels, neither moving nor acting until stagger_time is up.
/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/Stagger()
	StopSong()
	icon_state = icon_living
	visible_message(span_danger("[src] reels, and the song breaks off!"))
	playsound(src, stagger_sound, 75, TRUE)
	animate(src, pixel_x = base_pixel_x + stagger_sway, time = 2, loop = -1, easing = SINE_EASING)
	animate(pixel_x = base_pixel_x - stagger_sway, time = 2, easing = SINE_EASING)
	addtimer(CALLBACK(src, PROC_REF(EndStagger)), stagger_time)

/mob/living/simple_animal/hostile/gms_foe/third_floor_manager/proc/EndStagger()
	if(stat == DEAD)
		return
	animate(src, pixel_x = base_pixel_x, time = 1)
	EndSkill()

/// The light that bursts up round the 3rd Floor Manager when he slams the floor. The sprite is 320x320, centred on
/// his tile, and scaled up so it reaches as far as the slam does.
/obj/effect/temp_visual/gms_manager_slam
	icon = 'icons/mob/gms/gms_320x320.dmi'
	icon_state = "third_floor_manager_slam"
	duration = 0.9 SECONDS
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER
	pixel_x = -144
	base_pixel_x = -144
	pixel_y = -144
	base_pixel_y = -144

/obj/effect/temp_visual/gms_manager_slam/Initialize(mapload, scale = 1)
	. = ..()
	transform = matrix(scale, MATRIX_SCALE)
