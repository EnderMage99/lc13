// The King of Needleworks, the Grand Magasin's boss: a towering wooden mannequin in a crown and great robes, with a
// star-tipped wand. He walks slowly and strikes up close, pinning Naildle with every blow, and every so often stops to
// work his wand: raining needles, calling needlekin, ordering them on, hurling them, or setting needles hunting a foe.
// Anyone pinned deep enough with Naildle gets caught in a rain of blue needles, held up and eaten.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks
	name = "King of Needleworks"
	desc = "A towering wooden mannequin in a jagged golden crown, draped in great patterned robes. A star glints on the end of its wand."
	icon = 'icons/mob/gms/gms_128x128.dmi'
	icon_state = "king_of_needleworks"
	icon_living = "king_of_needleworks"
	icon_dead = "king_of_needleworks"
	pixel_x = -48
	base_pixel_x = -48
	maxHealth = 3000
	health = 3000
	move_to_delay = 5
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 20
	melee_damage_upper = 30
	attack_cooldown = 2 SECONDS
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'ModularLobotomy/_Lobotomysounds/gms/needlekin_stab.ogg'
	death_message = "creaks, and falls still."
	/// TRUE while he is using a skill; he neither walks nor strikes meanwhile.
	var/busy = FALSE
	/// How far around him his skills reach and look for foes, and the pause after each skill before the next.
	var/skill_range = 7
	var/skill_gap_time = 4 SECONDS
	var/skill_gap = 0
	/// The overlay on his wand while he charges it.
	var/mutable_appearance/charge_overlay
	var/charge_sound = 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_charge.ogg'
	/// How long each raise of the wand lasts, matching its animation: the full, the short (the order) and the fast
	/// (the pinning rain).
	var/charge_time = 2.4 SECONDS
	var/short_charge_time = 1.2 SECONDS
	var/fast_charge_time = 1.8 SECONDS
	/// The Needle Rain: every open tile he can see within rain_range gets rain_needles needles over rain_time, which
	/// together deal rain_damage to anyone on it the whole time. Each falls needle_drop pixels in needle_fall_time and
	/// stays stuck for needle_linger. At most rain_sounds of them make a sound each tick.
	var/rain_range = 6
	var/list/rain_needles = list(8, 13)
	var/rain_damage = 200
	var/rain_time = 1.5 SECONDS
	var/needle_fall_time = 2
	var/needle_drop = 192
	var/needle_linger = 1 SECONDS
	var/rain_sounds = 2
	/// Where on its tile a needle may land, in pixels: x from -needle_spread_x to needle_spread_x, y between the two.
	var/needle_spread_x = 10
	var/list/needle_spread_y = list(-10, 6)
	var/rain_cooldown_time = 20 SECONDS
	var/rain_cooldown = 0
	/// A Naildle stack goes into a foe for every this many needles that hit it, rolled again after each stack.
	var/list/needles_per_naildle = list(2, 3)
	/// Call the Needlekin: summon_count needlekin on open tiles within summon_range, appearing spawn_delay after their
	/// glow, while fewer than needlekin_cap of his are alive.
	var/summon_count = 6
	var/summon_range = 3
	var/needlekin_cap = 12
	var/spawn_delay = 3
	var/list/summon_types = list(/mob/living/simple_animal/hostile/gms_foe/needlekin, /mob/living/simple_animal/hostile/gms_foe/needlekin/red)
	var/list/summoned = list()
	var/summon_cooldown_time = 30 SECONDS
	var/summon_cooldown = 0
	var/last_summon = 0
	/// The Order: he spurs on every needlekin he can see, with one of these lines, sound to what he says.
	var/list/order_lines = list(
		'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_order_1.ogg' = "G... o...!",
		'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_order_2.ogg' = "Bring... it to me...!",
		'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_order_3.ogg' = "More... More...! Not... enough...!",
		)
	var/order_cooldown_time = 20 SECONDS
	var/order_cooldown = 0
	/// The Needle Throw: no sooner than throw_wait after a summon, he lifts the needlekin he can see for lift_time,
	/// rising in lift_rise_time, then hurls them one by one, throw_interval apart. Each throw lets go throw_release into
	/// its swing, and the last swing ends throw_time later.
	var/throw_wait = 10 SECONDS
	var/lift_time = 1 SECONDS
	var/lift_rise_time = 6
	var/throw_interval = 4
	var/throw_release = 1
	var/throw_time = 7
	var/throw_line = "Twick! Winkle... Tw... winkle!"
	var/throw_cooldown_time = 15 SECONDS
	var/throw_cooldown = 0
	/// The needlekin he is holding up to throw, and each one's floating copy.
	var/list/lifted = list()
	var/list/floating = list()
	/// Lifted needlekin float spread round him as if weightless: across float_arc degrees either side of straight up,
	/// float_radius pixels out from float_centre (from his tile's corner, for a 32 px sprite), each nudged up to
	/// float_jitter pixels. They bob float_bob pixels every float_bob_time and turn a full circle every float_spin_time.
	var/float_arc = 100
	var/float_radius = 56
	var/list/float_centre = list(0, 54)
	var/float_jitter = 6
	var/float_bob = 3
	var/float_bob_time = 8
	var/float_spin_time = 2 SECONDS
	/// The ring of light round whatever he holds up: aura round a needlekin, devour_aura (64x64, so shifted
	/// devour_aura_shift to stay centred) round someone he holds up to eat.
	var/mutable_appearance/aura
	var/mutable_appearance/devour_aura
	var/devour_aura_shift = -16
	/// Tongue-pinning Needle: on up to tongue_targets foes he can see, after which he watches for tongue_time.
	var/tongue_targets = 2
	var/tongue_time = 5
	var/tongue_cooldown_time = 15 SECONDS
	var/tongue_cooldown = 0
	/// Taxidermy: every taxidermy_check_time he looks for a foe with taxidermy_stacks Naildle or more, and if there is
	/// one, starts the pinning rain, with pin_needles needles a tile dealing pin_damage in all. Anyone it hits with
	/// that many stacks is Taxidermized.
	var/taxidermy_stacks = 8
	var/taxidermy_check_time = 5 SECONDS
	var/taxidermy_check = 0
	var/list/pin_needles = list(3, 4)
	var/pin_damage = 80
	/// The devour: he holds a Taxidermized foe up for devour_hold_time, pulls them to his mouth in pull_time, opens his
	/// jaw for jaw_time and bites, which takes bite_time. The mouth is at mouth_pixel_x, mouth_pixel_y from his tile's
	/// corner for a human's head. The bite deals bite_damage RED and bite_brute_share of their max health as BRUTE.
	var/devour_hold_time = 4 SECONDS
	var/pull_time = 8
	var/jaw_time = 6
	var/bite_time = 6
	var/mouth_pixel_x = 1
	var/mouth_pixel_y = 59
	var/bite_damage = 50
	var/bite_brute_share = 0.99
	var/devour_line = "Ahh...! Hnnh..."
	var/mob/living/devour_victim
	/// After the bite the body falls to his feet over drop_time. A human victim is shown upright through the devour by
	/// devour_scene, and their view, devour_watcher, follows them up, the world magnified devour_zoom times by scaling
	/// the world's planes on their screen (zoomed_planes) over devour_zoom_time.
	var/drop_time = 3
	var/datum/gms_kill_sequence/king_devour/devour_scene
	var/client/devour_watcher
	var/devour_zoom = 1.75
	var/devour_zoom_time = 6
	var/list/zoomed_planes = list()
	/// How long he takes to fade once dead.
	var/death_fade = 3 SECONDS

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/Initialize()
	. = ..()
	aura = mutable_appearance('icons/mob/gms/gms_32x32.dmi', "king_of_needleworks_lift_aura", ABOVE_MOB_LAYER)
	devour_aura = mutable_appearance('icons/mob/gms/gms_64x64.dmi', "king_of_needleworks_devour_aura", ABOVE_MOB_LAYER)
	devour_aura.pixel_x = devour_aura_shift
	devour_aura.pixel_y = devour_aura_shift

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/Move()
	if(busy)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/Goto(target, delay, minimum_distance)
	if(busy)
		return
	return ..()

// Each blow pins a stack of Naildle into a foe it leaves alive.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/AttackingTarget(atom/attacked_target)
	if(busy)
		return
	var/mob/living/victim = attacked_target || target
	var/was_alive = isliving(victim) && victim.stat != DEAD
	. = ..()
	if(was_alive && victim.stat != DEAD)
		GmsAddNaildle(victim, 1)

// Between blows, while fighting, he throws his needlekin if he can, then checks for someone to eat, and otherwise
// picks a skill.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/Life()
	. = ..()
	if(!. || busy || !target)
		return
	if(ThrowReady())
		StartSkill(PROC_REF(NeedleThrow))
		return
	if(taxidermy_check <= world.time)
		taxidermy_check = world.time + taxidermy_check_time
		if(length(TaxidermyTargets()))
			StartSkill(PROC_REF(PinningRain))
			return
	if(skill_gap > world.time)
		return
	var/list/ready = ReadySkills()
	if(length(ready))
		StartSkill(pick(ready))

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/death(gibbed)
	StopEverything()
	. = ..()
	animate(src, alpha = 0, time = death_fade)
	QDEL_IN(src, death_fade)

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/Destroy()
	StopEverything()
	summoned.Cut()
	return ..()

/// Lets go of whatever a skill was in the middle of: the charge, the needlekin he holds, and anyone he was eating.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/StopEverything()
	ClearWarnings()
	cut_overlay(charge_overlay)
	charge_overlay = null
	for(var/mob/living/simple_animal/hostile/gms_foe/needlekin/N as anything in lifted)
		Unlift(N)
	lifted.Cut()
	ReleaseVictim()

/// The skills he could start now.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/ReadySkills()
	. = list()
	var/list/foes = Foes()
	if(!length(foes))
		return
	var/kin = length(Needlekin())
	if(rain_cooldown <= world.time)
		. += PROC_REF(NeedleRain)
	if(summon_cooldown <= world.time && LivingSummoned() + summon_count <= needlekin_cap)
		. += PROC_REF(Summon)
	if(order_cooldown <= world.time && kin)
		. += PROC_REF(Order)
	if(tongue_cooldown <= world.time)
		. += PROC_REF(TonguePinning)

/// Whether the Needle Throw is ready: off cooldown, long enough after a summon, with needlekin and foes in sight.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/ThrowReady()
	if(throw_cooldown > world.time || !last_summon || last_summon + throw_wait > world.time)
		return FALSE
	return length(Needlekin()) && length(Foes())

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/StartSkill(skill)
	busy = TRUE
	INVOKE_ASYNC(src, skill)

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/EndSkill()
	busy = FALSE
	skill_gap = world.time + skill_gap_time
	if(stat != DEAD)
		icon_state = icon_living

/// Every living foe he can see within skill_range.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Foes()
	. = list()
	for(var/mob/living/L in view(skill_range, src))
		if(L == src || L.stat == DEAD || (L.status_flags & GODMODE) || faction_check_mob(L))
			continue
		. += L

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/TaxidermyTargets()
	. = list()
	for(var/mob/living/L as anything in Foes())
		if(GmsNaildleStacks(L) >= taxidermy_stacks)
			. += L

/// Every living needlekin he can see that is free to be lifted.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Needlekin()
	. = list()
	for(var/mob/living/simple_animal/hostile/gms_foe/needlekin/N in view(skill_range, src))
		if(N.stat != DEAD && !N.lifted && !N.killing)
			. += N

/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/LivingSummoned()
	. = 0
	for(var/mob/living/N as anything in summoned)
		if(QDELETED(N) || N.stat == DEAD)
			summoned -= N
			continue
		.++

/// Raises the wand in `state`, with `overlay_state` playing over it.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/BeginCharge(state, overlay_state)
	icon_state = state
	charge_overlay = mutable_appearance(icon, overlay_state)
	add_overlay(charge_overlay)

/// The charge is done: the wand bursts with `flash_state` and he stands as usual again.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/EndCharge(flash_state)
	cut_overlay(charge_overlay)
	charge_overlay = null
	icon_state = icon_living
	new /obj/effect/temp_visual/gms_king_flash(get_turf(src), flash_state)

/// Every open tile he can see within rain_range.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/RainTurfs()
	. = list()
	for(var/turf/T in view(rain_range, src))
		if(!T.density)
			. += T

/// Needle Rain: a long charge, then needles pour down on everything he can see.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/NeedleRain()
	rain_cooldown = world.time + rain_cooldown_time
	var/list/turfs = RainTurfs()
	ShowWarnings(turfs, charge_time)
	BeginCharge("king_of_needleworks_raise", "king_of_needleworks_charge")
	playsound(src, charge_sound, 75, FALSE)
	SLEEP_CHECK_DEATH(charge_time)
	ClearWarnings()
	EndCharge("king_of_needleworks_flash")
	Rain(turfs, rain_needles, rain_damage, "king_of_needleworks_needle")
	EndSkill()

/// Pours needles (`prefix` states) onto the turfs over rain_time, `counts` (lowest, highest) needles a tile, `damage`
/// in all to anyone on a tile the whole time. Foes hit gain Naildle. If `marked` is given, anyone in it hit by a single
/// needle, or anyone hit who already had taxidermy_stacks of it, is Taxidermized. Returns them.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Rain(list/turfs, list/counts, damage, prefix, list/marked)
	. = list()
	// When each needle drops: a list per tick of (turf, pixel x, pixel y), and how much each on a tile deals.
	var/list/schedule = new /list(rain_time)
	var/list/per_needle = list()
	var/list/beds = list()
	for(var/turf/T as anything in turfs)
		var/count = rand(counts[1], counts[2])
		per_needle[T] = damage / count
		beds[T] = new /obj/effect/temp_visual/gms_needle_bed(T, rain_time + needle_fall_time + needle_linger)
		for(var/i in 1 to count)
			var/tick = rand(1, rain_time)
			if(!schedule[tick])
				schedule[tick] = list()
			schedule[tick] += list(list(T, rand(-needle_spread_x, needle_spread_x), rand(needle_spread_y[1], needle_spread_y[2])))
	var/list/hits = list()
	var/list/next_pin = list()
	for(var/tick in 1 to rain_time + needle_fall_time)
		if(tick <= rain_time)
			for(var/list/needle as anything in schedule[tick])
				new /obj/effect/temp_visual/gms_falling_needle(needle[1], prefix, needle[2], needle[3], needle_fall_time, needle_drop)
		var/sounds = 0
		for(var/list/needle as anything in (tick > needle_fall_time ? schedule[tick - needle_fall_time] : null))
			var/turf/T = needle[1]
			var/obj/effect/temp_visual/gms_needle_bed/bed = beds[T]
			if(!QDELETED(bed))
				bed.AddNeedle(prefix, needle[2], needle[3])
			if(sounds < rain_sounds)
				sounds++
				playsound(T, 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_needle.ogg', 40, TRUE)
			// Who is pinned deep enough counts from before the needle lands, since its damage can drive a stack out.
			var/list/deep = list()
			if(marked)
				for(var/mob/living/L in T)
					if(GmsNaildleStacks(L) >= taxidermy_stacks)
						deep += L
			for(var/mob/living/L in HurtInTurf(T, list(), per_needle[T], RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL)))
				if(L.stat == DEAD)
					continue
				hits[L] = hits[L] + 1
				if(!next_pin[L])
					next_pin[L] = rand(needles_per_naildle[1], needles_per_naildle[2])
				if(hits[L] >= next_pin[L])
					hits[L] = 0
					next_pin[L] = rand(needles_per_naildle[1], needles_per_naildle[2])
					GmsAddNaildle(L, 1)
				if(((L in deep) || (L in marked)) && !(L in .) && !L.has_status_effect(/datum/status_effect/gms_taxidermized))
					L.apply_status_effect(/datum/status_effect/gms_taxidermized)
					. += L
		SLEEP_CHECK_DEATH(1)

/// Call the Needlekin: a long charge, then needlekin spring up round him.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Summon()
	summon_cooldown = world.time + summon_cooldown_time
	BeginCharge("king_of_needleworks_raise", "king_of_needleworks_summon")
	playsound(src, charge_sound, 75, FALSE)
	SLEEP_CHECK_DEATH(charge_time)
	EndCharge("king_of_needleworks_summon_flash")
	var/list/spots = list()
	for(var/turf/T in RANGE_TURFS(summon_range, src))
		if(T != get_turf(src) && !T.is_blocked_turf(TRUE))
			spots += T
	var/list/chosen = list()
	for(var/i in 1 to (length(spots) ? summon_count : 0))
		chosen += pick(spots)
	for(var/turf/T as anything in chosen)
		new /obj/effect/temp_visual/gms_king_spawn(T)
	SLEEP_CHECK_DEATH(spawn_delay)
	for(var/i in 1 to length(chosen))
		var/kind = summon_types[(i - 1) % length(summon_types) + 1]
		var/mob/living/simple_animal/hostile/gms_foe/needlekin/N = new kind(chosen[i])
		// They fight for whoever he fights for, even if his side has been changed.
		N.faction = faction.Copy()
		summoned += N
	last_summon = world.time
	EndSkill()

/// The Order: a short charge with a shout, then every needlekin he can see hits harder and moves faster for a while.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Order()
	order_cooldown = world.time + order_cooldown_time
	var/line = pick(order_lines)
	playsound(src, line, 75, FALSE)
	say(order_lines[line])
	BeginCharge("king_of_needleworks_raise_short", "king_of_needleworks_order")
	SLEEP_CHECK_DEATH(short_charge_time)
	EndCharge("king_of_needleworks_order_flash")
	for(var/mob/living/simple_animal/hostile/gms_foe/needlekin/N in view(skill_range, src))
		if(N.stat != DEAD)
			N.apply_status_effect(/datum/status_effect/gms_kings_order)
	EndSkill()

/// The Needle Throw: he lifts the needlekin he can see to float round him, marks the foes round him, and hurls the
/// needlekin one by one at those foes in turn, walls or no walls.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/NeedleThrow()
	throw_cooldown = world.time + throw_cooldown_time
	var/list/kin = Needlekin()
	var/list/marked = Foes()
	if(!length(kin) || !length(marked))
		EndSkill()
		return
	icon_state = "king_of_needleworks_lift"
	for(var/i in 1 to length(kin))
		Lift(kin[i], i, length(kin))
	SLEEP_CHECK_DEATH(lift_time)
	icon_state = "king_of_needleworks_hold"
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_throw.ogg', 75, FALSE)
	say(throw_line)
	var/thrown = 0
	while(length(lifted))
		var/mob/living/simple_animal/hostile/gms_foe/needlekin/N = lifted[1]
		lifted -= N
		var/list/standing = list()
		for(var/mob/living/L as anything in marked)
			if(!QDELETED(L) && L.stat != DEAD)
				standing += L
		marked = standing
		if(QDELETED(N) || N.stat == DEAD || !length(marked))
			Unlift(N)
			continue
		flick("king_of_needleworks_throw", src)
		SLEEP_CHECK_DEATH(throw_release)
		// Gone between the swing and the release: it is let down instead.
		if(QDELETED(N) || N.stat == DEAD)
			Unlift(N)
			continue
		Hurl(N, marked[thrown % length(marked) + 1])
		thrown++
		SLEEP_CHECK_DEATH(throw_interval - throw_release)
	SLEEP_CHECK_DEATH(throw_time)
	EndSkill()

/// Takes a needlekin out of the fight and floats it up beside him, the `index`th of `count` spread round him, bobbing
/// and slowly turning as if it weighed nothing. The needlekin itself waits inside him while a copy of it on his tile
/// does the floating, so none of the spinning can stay on it afterwards.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Lift(mob/living/simple_animal/hostile/gms_foe/needlekin/N, index, count)
	N.lifted = TRUE
	N.toggle_ai(AI_OFF)
	walk(N, 0)
	// The copy starts where the needlekin stood, so it glides over to him.
	var/obj/effect/gms_floating_kin/F = new(get_turf(src), N)
	F.pixel_x = (N.x - x) * world.icon_size + N.pixel_x
	F.pixel_y = (N.y - y) * world.icon_size + N.pixel_y
	F.add_overlay(aura)
	floating[N] = F
	lifted += N
	N.forceMove(src)
	var/angle = -float_arc + 2 * float_arc * (index - 0.5) / count
	var/float_x = float_centre[1] + round(sin(angle) * float_radius) + rand(-float_jitter, float_jitter)
	var/float_y = float_centre[2] + round(cos(angle) * float_radius) + rand(-float_jitter, float_jitter)
	animate(F, pixel_x = float_x, pixel_y = float_y, time = lift_rise_time, easing = SINE_EASING)
	animate(F, pixel_y = float_y + float_bob, time = float_bob_time, delay = lift_rise_time, loop = -1, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	animate(pixel_y = float_y - float_bob, time = float_bob_time, easing = SINE_EASING)
	// A full turn in thirds, some one way and some the other.
	var/turn = pick(-120, 120)
	animate(F, transform = turn(matrix(), turn), time = float_spin_time / 3, loop = -1, flags = ANIMATION_PARALLEL)
	animate(transform = turn(matrix(), turn * 2), time = float_spin_time / 3)
	animate(transform = matrix(), time = float_spin_time / 3)

/// Takes away a lifted needlekin's floating copy, returning where it floated.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/EndFloat(mob/living/simple_animal/hostile/gms_foe/needlekin/N)
	var/obj/effect/gms_floating_kin/F = floating[N]
	floating -= N
	. = F ? list(F.pixel_x, F.pixel_y) : list(0, 0)
	qdel(F)

/// Lets a lifted needlekin back down onto his tile, from where its copy floated, and back into the fight.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Unlift(mob/living/simple_animal/hostile/gms_foe/needlekin/N)
	var/list/at = EndFloat(N)
	if(QDELETED(N))
		return
	N.lifted = FALSE
	N.forceMove(get_turf(src))
	N.pixel_x = at[1]
	N.pixel_y = at[2]
	animate(N, pixel_x = N.base_pixel_x, pixel_y = N.base_pixel_y, time = lift_rise_time)
	if(N.stat == DEAD)
		return
	N.toggle_ai(AI_ON)
	N.SpreadOut(N.loc)

/// Throws a lifted needlekin at a foe.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Hurl(mob/living/simple_animal/hostile/gms_foe/needlekin/N, mob/living/foe)
	EndFloat(N)
	var/turf/start = get_turf(src)
	var/obj/projectile/gms_thrown_needlekin/P = new(start)
	P.Carry(N)
	P.starting = start
	P.firer = src
	P.fired_from = src
	P.original = foe
	P.preparePixelProjectile(foe, src)
	P.fire()

/// Tongue-pinning Needle: sets needles hunting up to tongue_targets of the foes he can see.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/TonguePinning()
	tongue_cooldown = world.time + tongue_cooldown_time
	var/list/foes = list()
	for(var/mob/living/L as anything in Foes())
		if(!L.has_status_effect(/datum/status_effect/gms_tongue_pinning))
			foes += L
	for(var/i in 1 to min(tongue_targets, length(foes)))
		var/mob/living/L = pick_n_take(foes)
		L.apply_status_effect(/datum/status_effect/gms_tongue_pinning, src)
		playsound(L, 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_needle.ogg', 50, TRUE)
	SLEEP_CHECK_DEATH(tongue_time)
	EndSkill()

/// The pinning rain: a quicker charge and a thinner, blue rain that Taxidermizes anyone deep in Naildle. If it catches
/// someone, he eats them.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/PinningRain()
	// Whoever is deep in Naildle as it starts needs only one blue needle, even if a stack falls out meanwhile.
	var/list/marked = TaxidermyTargets()
	var/list/turfs = RainTurfs()
	ShowWarnings(turfs, fast_charge_time)
	BeginCharge("king_of_needleworks_raise_fast", "king_of_needleworks_charge_blue")
	playsound(src, charge_sound, 75, FALSE)
	SLEEP_CHECK_DEATH(fast_charge_time)
	ClearWarnings()
	EndCharge("king_of_needleworks_flash_blue")
	var/list/pinned = Rain(turfs, pin_needles, pin_damage, "king_of_needleworks_needle_blue", marked)
	if(QDELETED(src) || stat == DEAD)
		return
	if(length(pinned))
		Devour(pinned[1])
	EndSkill()

/// Holds a Taxidermized foe up, and if they are still in sight, pulls them to his mouth, bites, and lets the body fall
/// to the floor beneath him. A human is shown upright through it, as in a kill sequence, and watches it up close.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Devour(mob/living/victim)
	devour_victim = victim
	icon_state = "king_of_needleworks_hold"
	victim.add_overlay(devour_aura)
	SLEEP_CHECK_DEATH(devour_hold_time)
	if(QDELETED(victim) || victim.stat == DEAD || !(victim in view(skill_range, src)) || !victim.has_status_effect(/datum/status_effect/gms_taxidermized))
		ReleaseVictim()
		return
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_devour.ogg', 75, FALSE)
	say(devour_line)
	var/pull_x = (x - victim.x) * world.icon_size + mouth_pixel_x
	var/pull_y = (y - victim.y) * world.icon_size + mouth_pixel_y
	if(ishuman(victim))
		// The copy is cut out along the body, which would clip the aura, so the aura goes up with the copy as a whole.
		victim.cut_overlay(devour_aura)
		devour_scene = new(src, victim)
		devour_scene.holder.add_overlay(devour_aura)
		devour_watcher = victim.client
		if(devour_watcher)
			ZoomWatcher()
			animate(devour_watcher, pixel_x = pull_x, pixel_y = pull_y, time = pull_time, easing = SINE_EASING)
	else
		victim.layer = ABOVE_MOB_LAYER
	animate(Puppet(), pixel_x = pull_x, pixel_y = pull_y, time = pull_time, easing = SINE_EASING)
	SLEEP_CHECK_DEATH(pull_time)
	icon_state = "king_of_needleworks_jaw"
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_jaw.ogg', 75, FALSE)
	SLEEP_CHECK_DEATH(jaw_time)
	icon_state = "king_of_needleworks_bite"
	playsound(src, 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_bite.ogg', 75, FALSE)
	var/killed = !QDELETED(victim) && Bite(victim)
	if(killed && !QDELETED(devour_scene))
		devour_scene.Behead()
	SLEEP_CHECK_DEATH(bite_time)
	if(QDELETED(victim))
		ReleaseVictim()
		return
	// The body drops straight down from his mouth to his feet, the watcher's view with it.
	var/floor_y = (y - victim.y) * world.icon_size
	animate(Puppet(), pixel_y = floor_y, time = drop_time, easing = QUAD_EASING | EASE_IN)
	if(devour_watcher)
		animate(devour_watcher, pixel_y = floor_y, time = drop_time, easing = QUAD_EASING | EASE_IN)
	SLEEP_CHECK_DEATH(drop_time)
	victim.forceMove(get_turf(src))
	victim.pixel_x = victim.base_pixel_x
	victim.pixel_y = victim.base_pixel_y
	if(killed && ishuman(victim))
		var/mob/living/carbon/human/H = victim
		H.add_splatter_floor(get_turf(src))
	ReleaseVictim()

/// Magnifies the world on the watcher's screen about its middle, leaving the HUD alone: every plane drawn below the
/// fullscreen effects is scaled, except those only drawn into another plane (render targets starting "*"), which
/// would otherwise be scaled twice.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/ZoomWatcher()
	var/datum/hud/H = devour_watcher.mob?.hud_used
	if(!H)
		return
	for(var/plane in H.plane_masters)
		var/atom/movable/screen/plane_master/PM = H.plane_masters[plane]
		if(PM.plane >= FULLSCREEN_PLANE || copytext(PM.render_target, 1, 2) == "*")
			continue
		zoomed_planes += PM
		animate(PM, transform = matrix(devour_zoom, 0, 0, 0, devour_zoom, 0), time = devour_zoom_time, easing = SINE_EASING)

/// What is lifted and dropped in the devour: a human's upright copy, or anything else itself.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Puppet()
	return QDELETED(devour_scene) ? devour_victim : devour_scene.holder

/// The bite. If it kills, their head is gone and he heals by all it dealt. Returns whether it killed.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/Bite(mob/living/victim)
	var/before = victim.health
	victim.deal_damage(bite_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	victim.deal_damage(victim.maxHealth * bite_brute_share, BRUTE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	if(victim.stat != DEAD)
		return FALSE
	var/dealt = before - victim.health
	if(ishuman(victim))
		var/mob/living/carbon/human/H = victim
		var/obj/item/bodypart/head/head = H.get_bodypart(BODY_ZONE_HEAD)
		if(head)
			head.drop_limb()
			qdel(head)
	visible_message(span_danger("[src] bites [victim]'s head clean off!"))
	adjustBruteLoss(-dealt*5)
	return TRUE

/// Puts down whoever he was eating: no longer pinned, shown as themselves again, their view back to normal.
/mob/living/simple_animal/hostile/gms_foe/king_of_needleworks/proc/ReleaseVictim()
	for(var/atom/movable/screen/plane_master/PM as anything in zoomed_planes)
		animate(PM, transform = matrix(), time = devour_zoom_time, easing = SINE_EASING)
	zoomed_planes.Cut()
	if(devour_watcher)
		animate(devour_watcher, pixel_x = 0, pixel_y = 0, time = 0, flags = ANIMATION_END_NOW)
		devour_watcher = null
	if(!QDELETED(devour_scene))
		devour_scene.End()
	devour_scene = null
	if(!devour_victim)
		return
	var/mob/living/victim = devour_victim
	devour_victim = null
	if(QDELETED(victim))
		return
	victim.cut_overlay(devour_aura)
	victim.remove_status_effect(/datum/status_effect/gms_taxidermized)
	victim.layer = initial(victim.layer)
	animate(victim, pixel_x = victim.base_pixel_x, pixel_y = victim.base_pixel_y, time = pull_time / 2)
