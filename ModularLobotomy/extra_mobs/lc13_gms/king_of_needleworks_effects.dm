// What the King of Needleworks leaves on others: the order he gives his needlekin, the Taxidermized hold, the
// Tongue-pinning Needles that hunt a foe, the needlekin he throws, and the flashes and needles of his rains.

/// The King's order on a needlekin: moves faster for a while, tinted purple. A second order
/// starts the time over rather than adding more.
/datum/status_effect/gms_kings_order
	id = "gms_kings_order"
	duration = 15 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	var/damage_bonus = 3
	var/speed_bonus = 1
	var/tint = "#d8a0ff"

/datum/status_effect/gms_kings_order/on_apply()
	var/mob/living/simple_animal/hostile/H = owner
	if(!istype(H))
		return FALSE
	H.ChangeMoveToDelayBy(-speed_bonus)
	H.add_atom_colour(tint, TEMPORARY_COLOUR_PRIORITY)
	return TRUE

/datum/status_effect/gms_kings_order/on_remove()
	var/mob/living/simple_animal/hostile/H = owner
	H.ChangeMoveToDelayBy(speed_bonus)
	H.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, tint)

/// Taxidermized: pinned through by the King's blue needles, unable to move until it wears off or he is done with them.
/datum/status_effect/gms_taxidermized
	id = "gms_taxidermized"
	duration = 8 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/gms_taxidermized
	var/mutable_appearance/pins

/atom/movable/screen/alert/status_effect/gms_taxidermized
	name = "Taxidermized"
	desc = "Needles pin you in place like a specimen. You cannot move."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "king_of_needleworks_taxidermized"

// Pinning them through takes all their Naildle, and no more can go in while it lasts (GmsAddNaildle()).
/datum/status_effect/gms_taxidermized/on_apply()
	owner.remove_status_effect(/datum/status_effect/stacking/naildle)
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, id)
	// Over clothing, under anything held, like Naildle's needles.
	pins = mutable_appearance('icons/mob/gms/gms_32x32.dmi', "king_of_needleworks_taxidermy_pins", -(HANDS_LAYER + 0.5))
	owner.add_overlay(pins)
	return TRUE

/datum/status_effect/gms_taxidermized/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, id)
	owner.cut_overlay(pins)

/// Tongue-pinning Needle: four needles hang round the bearer's head. Every step the bearer takes draws them approach
/// steps closer; each second the bearer has not moved pushes them retreat steps back, up to max_distance. If they close
/// all the way they strike, for strike_damage RED and strike_naildle Naildle. If the time runs out first they fade,
/// taking expire_naildle Naildle with them.
/datum/status_effect/gms_tongue_pinning
	id = "gms_tongue_pinning"
	duration = 8 SECONDS
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/gms_tongue_pinning
	/// The King who set them on; their damage is his.
	var/mob/living/king
	var/distance = 3
	var/approach = 0.1
	var/retreat = 3
	var/max_distance = 8
	/// When the bearer last moved.
	var/last_moved = 0
	var/strike_damage = 20
	var/strike_naildle = 3
	var/expire_naildle = 6
	/// Each needle's angle from straight up, in its state's order; how far out a step of distance puts them; how high
	/// over the bearer they centre; and how long they take to glide to a new distance.
	var/list/angles = list(-70, -30, 30, 70)
	var/pixels_per_step = 4
	var/head_pixel_y = 12
	var/glide_time = 6
	var/list/needles = list()
	var/struck = FALSE

/atom/movable/screen/alert/status_effect/gms_tongue_pinning
	name = "Tongue-pinning Needle"
	desc = "Needles hang over your head. Every step you take draws them closer; stand still and they drift away."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "king_of_needleworks_tongue_pinning"

/datum/status_effect/gms_tongue_pinning/on_creation(mob/living/new_owner, mob/living/set_by)
	king = set_by
	return ..()

/datum/status_effect/gms_tongue_pinning/on_apply()
	for(var/i in 1 to length(angles))
		var/obj/effect/gms_tongue_needle/N = new
		N.icon_state = "king_of_needleworks_tongue_pin_[i]"
		needles += N
		owner.vis_contents += N
	Place(0)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(OnMoved))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(OnDeath))
	return TRUE

// A whole second standing still pushes the needles back; having moved in it does nothing more.
/datum/status_effect/gms_tongue_pinning/tick()
	if(world.time - last_moved < initial(tick_interval))
		return
	distance = min(distance + retreat, max_distance)
	Place(glide_time)

/datum/status_effect/gms_tongue_pinning/proc/OnMoved(datum/source)
	SIGNAL_HANDLER
	last_moved = world.time
	distance -= approach
	if(distance <= 0)
		INVOKE_ASYNC(src, PROC_REF(Strike))
		return
	Place(glide_time)

/datum/status_effect/gms_tongue_pinning/proc/OnDeath(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Moves each needle out along its angle to the current distance, over `time`.
/datum/status_effect/gms_tongue_pinning/proc/Place(time)
	for(var/i in 1 to length(needles))
		var/obj/effect/gms_tongue_needle/N = needles[i]
		animate(N, pixel_x = round(sin(angles[i]) * distance * pixels_per_step), pixel_y = head_pixel_y + round(cos(angles[i]) * distance * pixels_per_step), time = time)

/datum/status_effect/gms_tongue_pinning/proc/Strike()
	if(struck)
		return
	struck = TRUE
	if(QDELETED(king))
		king = null
	owner.deal_damage(strike_damage, RED_DAMAGE, king, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
	GmsAddNaildle(owner, strike_naildle)
	qdel(src)

// The needles are left behind where they hung to play out their strike or their fade.
/datum/status_effect/gms_tongue_pinning/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_DEATH))
	for(var/obj/effect/gms_tongue_needle/N as anything in needles)
		new /obj/effect/temp_visual/gms_tongue_needle(get_turf(owner), "[N.icon_state]_[struck ? "strike" : "fade"]", owner.pixel_x + N.pixel_x, owner.pixel_y + N.pixel_y)
		owner.vis_contents -= N
		qdel(N)
	needles.Cut()
	king = null
	if(!struck && owner.stat != DEAD)
		GmsAddNaildle(owner, -expire_naildle)

/// The King's devour, shown the way a kill sequence shows a kill: the human is hidden and an upright copy of them,
/// cut into body parts, stands in, hung off the body. Unlike a kill the King stays where he is and plays himself,
/// moving the copy's holder up to his mouth and back down; Behead() takes the copy's head, End() shows the body again.
/datum/gms_kill_sequence/king_devour

/datum/gms_kill_sequence/king_devour/New(mob/living/simple_animal/hostile/gms_foe/new_killer, mob/living/carbon/human/new_victim)
	killer = new_killer
	victim = new_victim
	last_turf = get_turf(victim)
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(OnVictimDeleted))
	BuildScene()
	holder.vis_contents -= actor
	// Held up to his mouth, the copy is drawn over him wherever its body stands.
	scan.layer = ABOVE_MOB_LAYER
	for(var/zone in parts)
		var/obj/effect/gms_kill_visual/part = parts[zone]
		part.layer = ABOVE_MOB_LAYER

/datum/gms_kill_sequence/king_devour/proc/Behead()
	animate(parts["head"], alpha = 0, time = 1)

/datum/gms_kill_sequence/king_devour/proc/End()
	if(victim)
		UnregisterSignal(victim, COMSIG_PARENT_QDELETING)
		ClearScene()
		victim.alpha = old_alpha
	qdel(src)

/datum/gms_kill_sequence/king_devour/OnVictimDeleted(datum/source)
	victim = null
	qdel(src)

/// One Tongue-pinning needle, hung over its bearer.
/obj/effect/gms_tongue_needle
	icon = 'icons/mob/gms/gms_32x32.dmi'
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// A Tongue-pinning needle's strike or fade, left where it hung.
/obj/effect/temp_visual/gms_tongue_needle
	icon = 'icons/mob/gms/gms_32x32.dmi'
	duration = 0.5 SECONDS
	randomdir = FALSE

/obj/effect/temp_visual/gms_tongue_needle/Initialize(mapload, state, offset_x, offset_y)
	icon_state = state
	pixel_x = offset_x
	pixel_y = offset_y
	return ..()

/// A needlekin the King has thrown. It spins through the air, passing over his own side, and hits whoever it reaches
/// first, walls included; whatever it hits, the needlekin dies there.
/obj/projectile/gms_thrown_needlekin
	name = "thrown needlekin"
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "green_needlekin"
	nondirectional_sprite = TRUE
	damage = 60
	damage_type = RED_DAMAGE
	speed = 0.8
	range = 20
	hitsound = 'ModularLobotomy/_Lobotomysounds/gms/king_of_needleworks_throw_hit.ogg'
	/// Degrees it turns each tile.
	var/spin = 45
	var/mob/living/simple_animal/hostile/gms_foe/needlekin/needlekin
	var/landed = FALSE

/// Takes the needlekin inside it, to fly as it.
/obj/projectile/gms_thrown_needlekin/proc/Carry(mob/living/simple_animal/hostile/gms_foe/needlekin/N)
	needlekin = N
	icon_state = N.icon_living
	add_overlay(mutable_appearance('icons/mob/gms/gms_32x32.dmi', "king_of_needleworks_lift_aura"))
	N.forceMove(src)

/obj/projectile/gms_thrown_needlekin/prehit_pierce(atom/A)
	var/mob/living/thrower = firer
	if(isliving(A) && istype(thrower) && thrower.faction_check_mob(A))
		return PROJECTILE_PIERCE_PHASE
	return ..()

/obj/projectile/gms_thrown_needlekin/Range()
	transform = turn(transform, spin)
	return ..()

/obj/projectile/gms_thrown_needlekin/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	Land()

/obj/projectile/gms_thrown_needlekin/on_range()
	Land()
	return ..()

/obj/projectile/gms_thrown_needlekin/Destroy()
	Land()
	return ..()

/// Lets the needlekin out where it came down, and it dies there.
/obj/projectile/gms_thrown_needlekin/proc/Land()
	if(landed)
		return
	landed = TRUE
	var/mob/living/simple_animal/hostile/gms_foe/needlekin/N = needlekin
	needlekin = null
	var/turf/T = get_turf(src)
	if(QDELETED(N) || !T)
		return
	playsound(T, hitsound, 60, TRUE)
	N.forceMove(T)
	N.lifted = FALSE
	N.pixel_x = N.base_pixel_x
	N.pixel_y = N.base_pixel_y
	N.death()

/// A copy of a needlekin the King holds up, floating and turning in its place while the needlekin waits inside him.
/obj/effect/gms_floating_kin
	anchored = TRUE

/obj/effect/gms_floating_kin/Initialize(mapload, mob/living/kin)
	. = ..()
	appearance = kin.appearance
	transform = matrix()
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// A burst from the King's wand as a charge ends, in `state`. The sprite is 128x128, centred on the wand's star where
/// it is at the end of his raise.
/obj/effect/temp_visual/gms_king_flash
	icon = 'icons/mob/gms/gms_128x128.dmi'
	duration = 0.8 SECONDS
	randomdir = FALSE
	pixel_x = -78
	base_pixel_x = -78
	pixel_y = 38
	base_pixel_y = 38

/obj/effect/temp_visual/gms_king_flash/Initialize(mapload, state)
	icon_state = state
	return ..()

/// The glow where a summoned needlekin is about to appear.
/obj/effect/temp_visual/gms_king_spawn
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "king_of_needleworks_summon_spawn"
	duration = 0.6 SECONDS
	randomdir = FALSE
	layer = BELOW_MOB_LAYER

/// One needle of a rain, dropping `drop` pixels onto the point it lands at over `fall_time`.
/obj/effect/temp_visual/gms_falling_needle
	icon = 'icons/mob/gms/gms_32x32.dmi'
	randomdir = FALSE

/obj/effect/temp_visual/gms_falling_needle/Initialize(mapload, prefix, offset_x, offset_y, fall_time, drop)
	icon_state = "[prefix]_fall"
	duration = fall_time
	pixel_x = offset_x
	pixel_y = offset_y + drop
	. = ..()
	animate(src, pixel_y = offset_y, time = fall_time)

/// The needles a rain leaves stuck in one tile, gathered on one object so a big rain is not thousands of them. Only
/// the first few to land stay, kept_needles (lowest, highest) of them. It lasts `life` and fades over its last
/// fade_time.
/obj/effect/temp_visual/gms_needle_bed
	icon = 'icons/mob/gms/gms_32x32.dmi'
	randomdir = FALSE
	layer = BELOW_MOB_LAYER
	var/fade_time = 0.5 SECONDS
	/// The stuck needle states, upright and leaning.
	var/list/variants = list("", "_1", "_2", "_3", "_4", "_5", "_6")
	var/list/kept_needles = list(2, 3)
	var/room = 0

/obj/effect/temp_visual/gms_needle_bed/Initialize(mapload, life)
	duration = life + fade_time
	room = rand(kept_needles[1], kept_needles[2])
	. = ..()
	animate(src, alpha = 0, time = fade_time, delay = life)

/obj/effect/temp_visual/gms_needle_bed/proc/AddNeedle(prefix, offset_x, offset_y)
	if(room <= 0)
		return
	room--
	var/mutable_appearance/M = mutable_appearance(icon, "[prefix]_stuck[pick(variants)]")
	M.pixel_x = offset_x
	M.pixel_y = offset_y
	add_overlay(M)
