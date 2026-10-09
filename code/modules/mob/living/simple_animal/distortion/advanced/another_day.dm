// Another Day at Work on the advanced base. It stays where it spawned, its oddities are all paper,
// and from the gimmick stage the floor around it turns into the another_day quilt, restored when it goes.
/mob/living/simple_animal/hostile/distortion/advanced/another_day
	name = "Another Day at Work"
	desc = "A man covered in... ties?"
	icon = 'ModularLobotomy/_Lobotomyicons/48x96.dmi'
	icon_state = "work"
	maxHealth = 900
	health = 900
	pixel_x = -8
	base_pixel_x = -8
	fear_level = TETH_LEVEL
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 2)
	melee_damage_lower = 10
	melee_damage_upper = 14
	melee_damage_type = BLACK_DAMAGE
	attack_sound = 'sound/abnormalities/censored/attack.ogg'
	attack_verb_continuous = "whips"
	attack_verb_simple = "whip"
	ranged = TRUE
	ranged_cooldown_time = 4 SECONDS
	projectiletype = /obj/projectile/tie
	projectilesound = 'sound/weapons/whip.ogg'
	ego_list = list(
		/obj/item/ego_weapon/waging,
		/obj/item/clothing/suit/armor/ego_gear/teth/waging,
	)
	egoist_names = list("Paige Turner", "Larry Sal", "Nota Dollar", "Donnar Profit", "Collin Beck")
	gender = MALE
	loot = list(/obj/item/documents/ncorporation)
	monolith_abnormality = /mob/living/simple_animal/hostile/abnormality/black_swan
	wanders = FALSE
	territory_cap = 1000
	territory_stages = list(50, 200, 500)
	gimmick_stage = 3
	oddities = list(
		/obj/effect/temp_visual/distortion_oddity/paper_drift,
		/obj/item/paperplane/distortion,
	)
	var/floor_type = /turf/open/floor/distortion/another_day
	var/wall_type = /turf/closed/indestructible/city/another_day
	/// Turfs the centre has converted, with the type each one was, so Teardown() can put them back.
	var/list/converted = list()
	/// Share of the territory the quilt covers when it first appears, innermost first. It shrinks as the territory grows: see QuiltSize().
	var/quilt_fraction = 0.35
	/// How the quilt keeps up with the territory. 1 would hold the share; 0.5 lets the territory outrun it.
	var/quilt_growth_power = 0.5

/// It does not move at all; it is the place as much as the person.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/Move()
	return FALSE

/// The base hands the centre over by count at stage changes; this one sizes the quilt itself.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/UpdateCenter(new_stage)
	UpdateQuilt()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnTerritoryGrown()
	UpdateQuilt()

/// The quilt is the innermost QuiltSize() turfs of the territory by walking cost, so it fills a room before the door
/// and never crosses a wall the territory did not. Runs after every growth tick from gimmick_stage on.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/UpdateQuilt()
	if(!territory || territory.stage < gimmick_stage)
		return
	ApplyCenterEffects(territory.CenterTurfs(QuiltSize()))

/// Turfs the quilt covers: quilt_fraction of the start size, scaled by the territory's growth to the power
/// quilt_growth_power, so it is a third of the territory when it appears and a smaller share the bigger it gets.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/QuiltSize()
	var/growth = territory.Size() / max(1, territory_start_size)
	return max(1, round(quilt_fraction * territory_start_size * (growth ** quilt_growth_power)))

/// Floors in the centre become quilt, and any wall touching a quilt floor becomes quilt wall.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/ApplyCenterEffects(list/turfs)
	for(var/turf/open/floor/T in turfs)
		if(!(T in converted) && !istype(T, floor_type))
			converted[T] = T.type
			T.ChangeTurf(floor_type)
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(!next || (next in converted) || !isclosedturf(next) || istype(next, wall_type))
				continue
			converted[next] = next.type
			next.ChangeTurf(wall_type)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Teardown()
	if(torn_down)
		return
	for(var/turf/T in converted)
		if(istype(T, floor_type) || istype(T, wall_type))
			T.ChangeTurf(converted[T])
	converted.Cut()
	return ..()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/PostUnmanifest()
	new /obj/item/clothing/neck/tie/horrible(get_turf(src))

/// A single written page flies in from one side, loses its speed, and settles slowly to the floor, swaying as it falls.
/obj/effect/temp_visual/distortion_oddity/paper_drift
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper_words"
	alpha = 220
	duration = 4.5 SECONDS

/obj/effect/temp_visual/distortion_oddity/paper_drift/Initialize(mapload)
	. = ..()
	var/from = pick(-1, 1)
	pixel_x = from * 56
	pixel_y = 28
	var/sway = -from * 8
	animate(src, pixel_x = from * 12, pixel_y = 34, time = duration * 0.3, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = from * 12 + sway, pixel_y = 22, time = duration * 0.25, easing = SINE_EASING)
	animate(pixel_x = from * 12 - sway, pixel_y = 10, time = duration * 0.25, easing = SINE_EASING)
	animate(pixel_x = from * 12, pixel_y = 0, alpha = 0, time = duration * 0.2)

/// Each quilt tile picks one of the four variants so the patch does not repeat. The mapped "another_day"
/// state is left for the District 4 ruin.
/turf/open/floor/distortion/another_day/Initialize(mapload)
	. = ..()
	icon_state = pick("another_day1", "another_day2", "another_day3", "another_day4")

/// The quilt wall: the floor hung up. Smooths with the other city walls.
/turf/closed/indestructible/city/another_day
	name = "quilted wall"
	desc = "Ties, hundreds of them, stitched edge to edge and hung over whatever was here before."
	icon = 'icons/turf/walls/city_another_day.dmi'
	icon_state = "another_day-0"
	base_icon_state = "another_day"

/// A paper plane that fades in out of the sky, already turned toward a far turf it can see, swaying as it comes
/// down, then glides there slowly, or drops where it is if nothing is in view. It fades out a while after landing.
/obj/item/paperplane/distortion
	alpha = 0
	hit_probability = 0
	/// Time spent fading in above the ground before it is thrown.
	var/fade_in = 4.5 SECONDS
	/// How long it lies where it landed before fading away.
	var/linger = 10 SECONDS
	/// Tiles per tick while thrown: 0.2 is one tile every half second.
	var/glide_speed = 0.2
	var/min_throw = 4
	var/max_throw = 7
	/// Where it will be thrown, chosen on spawn so it can face that way while fading in. Null means it just drops.
	var/turf/target_turf

/obj/item/paperplane/distortion/Initialize(mapload)
	. = ..(mapload, new /obj/item/paper/distortion(loc))
	target_turf = PickTarget()
	if(target_turf)
		setDir(get_cardinal_dir(src, target_turf))
	var/sway = pick(-8, 8)
	pixel_y = 36
	animate(src, alpha = 255, pixel_x = sway, pixel_y = 28, time = fade_in * 0.3, easing = SINE_EASING | EASE_OUT)
	animate(pixel_x = -sway, pixel_y = 20, time = fade_in * 0.25, easing = SINE_EASING)
	animate(pixel_x = sway, pixel_y = 14, time = fade_in * 0.25, easing = SINE_EASING)
	animate(pixel_x = 0, pixel_y = 10, time = fade_in * 0.2, easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(Launch)), fade_in)

/// A random visible open turf between min_throw and max_throw away, or null.
/obj/item/paperplane/distortion/proc/PickTarget()
	var/list/far = list()
	for(var/turf/open/T in view(max_throw, src))
		if(get_dist(src, T) >= min_throw)
			far += T
	if(!far.len)
		return null
	return pick(far)

/// Throws at the chosen turf, or drops straight down if there was none.
/obj/item/paperplane/distortion/proc/Launch()
	if(QDELETED(src) || !isturf(loc))
		return
	if(!target_turf)
		animate(src, pixel_y = 0, time = 1 SECONDS, easing = SINE_EASING | EASE_IN)
		addtimer(CALLBACK(src, PROC_REF(Landed)), 1 SECONDS)
		return
	throw_at(target_turf, get_dist(src, target_turf), glide_speed, callback = CALLBACK(src, PROC_REF(Landed)))

/// Settles to the floor and fades out over linger, then is gone. Picking it up before that still lets it fade.
/obj/item/paperplane/distortion/proc/Landed()
	if(QDELETED(src))
		return
	animate(src, pixel_y = 0, alpha = 0, time = linger)
	QDEL_IN(src, linger)

/// Unfolding sets the page fading on its own; the parent then deletes the empty plane.
/obj/item/paperplane/distortion/Exited(atom/movable/AM, atom/newLoc)
	if(AM == internalPaper)
		var/obj/item/paper/distortion/page = AM
		page.StartFading()
	return ..()

/// The page inside the plane. Once unfolded it fades away over linger and cannot be folded into anything again.
/obj/item/paper/distortion
	name = "limp page"
	desc = "A sheet of paper, damp and soft as cloth. Whatever was written on it has run."
	var/linger = 10 SECONDS

/obj/item/paper/distortion/proc/StartFading()
	animate(src, alpha = 0, time = linger)
	QDEL_IN(src, linger)

/obj/item/paper/distortion/examine(mob/user)
	. = ..()
	. += span_notice("It is far too limp to hold a fold.")

/obj/item/paper/distortion/AltClick(mob/living/user, obj/item/I)
	if(!user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, FALSE, TRUE))
		return
	to_chat(user, span_warning("[src] sags in your hands. It will not hold a fold."))
