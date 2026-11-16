// Escalators between the floors of the Grand Magasin. Stepping onto the steps carries you to the paired escalator on
// the floor above or below, and you step off onto its landing. Map them by hand; each pairs up on its own.
GLOBAL_LIST_EMPTY(gms_escalators)

/// Front view going up, 3x5 tiles. Placed on the bottom left tile of its footprint; offsets are tiles from there.
/obj/structure/gms_escalator
	name = "escalator"
	desc = "Its steps climb toward the floor above, and never stop."
	icon = 'icons/obj/gms/gms_escalator_up.dmi'
	icon_state = "up"
	anchored = TRUE
	density = FALSE
	layer = LOW_OBJ_LAYER
	resistance_flags = INDESTRUCTIBLE
	/// UP or DOWN: the floor it carries you to.
	var/travel = UP
	/// Pairs with an escalator going the other way on that floor with the same id. The nearest wins if several match.
	var/escalator_id
	/// The walkable tile you step off onto when you arrive here.
	var/list/landing = list(1, 0)
	/// Stepping onto any of these tiles sends you on.
	var/list/triggers = list(list(1, 1), list(1, 2), list(1, 3), list(1, 4))
	/// Tiles under the balustrades, blocked off.
	var/list/rails = list(list(0, 0), list(0, 1), list(0, 2), list(0, 3), list(0, 4), list(2, 0), list(2, 1), list(2, 2), list(2, 3), list(2, 4))
	/// Rails and steps spawned on its tiles. Objects, not turf signals, so they outlive a ChangeTurf under them.
	var/list/parts = list()

/obj/structure/gms_escalator/Initialize()
	. = ..()
	GLOB.gms_escalators += src
	for(var/list/offset as anything in rails)
		var/turf/T = OffsetTurf(offset)
		if(T)
			parts += new /obj/effect/gms_escalator_rail(T)
	for(var/list/offset as anything in triggers)
		var/turf/T = OffsetTurf(offset)
		if(!T)
			continue
		var/obj/effect/gms_escalator_step/step = new(T)
		step.escalator = src
		parts += step

/obj/structure/gms_escalator/Destroy()
	GLOB.gms_escalators -= src
	for(var/obj/effect/part as anything in parts)
		qdel(part)
	parts = null
	return ..()

/obj/structure/gms_escalator/proc/OffsetTurf(list/offset)
	return locate(x + offset[1], y + offset[2], z)

// Someone being pulled rides along with whoever pulls them, so only the puller sets it off.
/obj/structure/gms_escalator/proc/OnStep(atom/movable/arrived)
	if(!ishuman(arrived) || arrived.pulledby)
		return
	INVOKE_ASYNC(src, PROC_REF(Ride), arrived)

/// Carries a rider to the paired escalator's landing, along with whatever they are pulling.
/obj/structure/gms_escalator/proc/Ride(mob/living/carbon/human/rider)
	var/obj/structure/gms_escalator/partner = FindPartner()
	var/turf/arrival = partner?.OffsetTurf(partner.landing)
	if(!arrival)
		to_chat(rider, span_warning("The escalator leads nowhere."))
		return
	var/atom/movable/pulled = rider.pulling
	if(pulled)
		rider.stop_pulling()
	rider.forceMove(arrival)
	if(pulled && !pulled.anchored)
		pulled.forceMove(arrival)
		rider.start_pulling(pulled, supress_message = TRUE)
	to_chat(rider, span_notice("You ride the escalator [travel == UP ? "up" : "down"] a floor."))

/// The nearest escalator going the other way, with the same id, on the floor this one leads to.
/obj/structure/gms_escalator/proc/FindPartner()
	var/turf/here = get_turf(src)
	var/turf/next = travel == UP ? SSmapping.get_turf_above(here) : SSmapping.get_turf_below(here)
	if(!next)
		return
	var/obj/structure/gms_escalator/best
	var/best_distance = INFINITY
	for(var/obj/structure/gms_escalator/other as anything in GLOB.gms_escalators)
		if(other.z != next.z || other.travel == travel || other.escalator_id != escalator_id)
			continue
		var/distance = get_dist(next, other)
		if(distance < best_distance)
			best = other
			best_distance = distance
	return best

/// Front view going down, 3x5 tiles, darkening as it sinks.
/obj/structure/gms_escalator/down
	desc = "Its steps sink into the dark of the floor below."
	icon = 'icons/obj/gms/gms_escalator_down.dmi'
	icon_state = "down"
	travel = DOWN

/// Side view with its high end to the west, 6x3 tiles. Placed on the bottom left tile of its body; the shadow hangs below.
/// You get on from the east, at the low end.
/obj/structure/gms_escalator/side
	icon = 'icons/obj/gms/gms_escalator_side.dmi'
	icon_state = "west"
	pixel_y = -32
	landing = list(5, 0)
	triggers = list(list(4, 0))
	rails = list(list(0, 0), list(0, 1), list(0, 2), list(1, 0), list(1, 1), list(1, 2), list(2, 0), list(2, 1), list(3, 0), list(3, 1))

/obj/structure/gms_escalator/side/down
	desc = "Its steps sink into the dark of the floor below."
	travel = DOWN

/// Side view with its high end to the east. You get on from the west, at the low end.
/obj/structure/gms_escalator/side/east
	icon_state = "east"
	landing = list(0, 0)
	triggers = list(list(1, 0))
	rails = list(list(5, 0), list(5, 1), list(5, 2), list(4, 0), list(4, 1), list(4, 2), list(3, 0), list(3, 1), list(2, 0), list(2, 1))

/obj/structure/gms_escalator/side/east/down
	desc = "Its steps sink into the dark of the floor below."
	travel = DOWN

/// A step of an escalator. Spawned and removed by the escalator; walking onto it sets the escalator off.
/obj/effect/gms_escalator_step
	name = "escalator step"
	icon = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE
	var/obj/structure/gms_escalator/escalator

/obj/effect/gms_escalator_step/Destroy()
	escalator = null
	return ..()

/obj/effect/gms_escalator_step/Crossed(atom/movable/AM, oldloc)
	. = ..()
	escalator?.OnStep(AM)

/// Blocks a tile under an escalator's balustrade. Spawned and removed by the escalator.
/obj/effect/gms_escalator_rail
	name = "escalator balustrade"
	icon = null
	anchored = TRUE
	density = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE
