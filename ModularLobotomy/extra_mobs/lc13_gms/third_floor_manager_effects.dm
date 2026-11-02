/// A tall birdcage the 3rd Floor Manager shuts someone in while his bird sings. Whoever is inside cannot move while
/// they stay on its tile, and any shot they fire hits the cage instead. Others cannot step in, and their shots hit the
/// cage first, so breaking it is how a friend gets out. It breaks for good when the song ends or is cut off.
/obj/structure/gms_birdcage
	name = "birdcage"
	desc = "A tall iron birdcage, big enough for a person. The door has no handle on the inside."
	icon = 'icons/mob/gms/gms_96x96.dmi'
	icon_state = "third_floor_manager_cage"
	// The 96x96 cage is centred on its tile, with its floor ring at the feet of whoever stands inside.
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -9
	base_pixel_y = -9
	layer = ABOVE_MOB_LAYER
	density = TRUE
	anchored = TRUE
	max_integrity = 150
	/// Everyone shut inside, held still until they leave its tile.
	var/list/occupants = list()
	var/break_sound = 'ModularLobotomy/_Lobotomysounds/gms/gms_foe_ram_hit.ogg'

/obj/structure/gms_birdcage/Initialize(mapload, mob/living/caught)
	. = ..()
	if(caught)
		Trap(caught)

/obj/structure/gms_birdcage/Destroy()
	for(var/mob/living/L as anything in occupants.Copy())
		Release(L)
	return ..()

/obj/structure/gms_birdcage/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(mover in occupants)
		return TRUE

// A shot fired from inside hits the bars on its way out.
/obj/structure/gms_birdcage/Uncross(atom/movable/AM, atom/newloc)
	if(istype(AM, /obj/projectile))
		var/obj/projectile/P = AM
		if(P.firer in occupants)
			bullet_act(P)
			qdel(P)
			return FALSE
	return ..()

/// Shuts someone in, holding them still for as long as they stay on its tile.
/obj/structure/gms_birdcage/proc/Trap(mob/living/L)
	occupants += L
	ADD_TRAIT(L, TRAIT_IMMOBILIZED, REF(src))
	RegisterSignal(L, COMSIG_MOVABLE_MOVED, PROC_REF(OnOccupantMoved))
	RegisterSignal(L, COMSIG_PARENT_QDELETING, PROC_REF(Release))

/// Lets someone go, free to move again.
/obj/structure/gms_birdcage/proc/Release(mob/living/L)
	SIGNAL_HANDLER
	occupants -= L
	REMOVE_TRAIT(L, TRAIT_IMMOBILIZED, REF(src))
	UnregisterSignal(L, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))

// Anyone thrown, pulled or carried off its tile is out of the cage.
/obj/structure/gms_birdcage/proc/OnOccupantMoved(mob/living/L)
	SIGNAL_HANDLER
	if(L.loc != loc)
		Release(L)

/// The cage bursts apart, letting everyone out.
/obj/structure/gms_birdcage/proc/Shatter()
	playsound(src, break_sound, 60, TRUE)
	new /obj/effect/temp_visual/small_smoke/halfsecond(loc)
	qdel(src)

/// The great ring of blue light that bursts out of the 3rd Floor Manager when his bird's song ends. The sprite is
/// 192x192, centred on his tile.
/obj/effect/temp_visual/gms_manager_burst
	icon = 'icons/mob/gms/gms_192x192.dmi'
	icon_state = "third_floor_manager_burst_blue"
	duration = 1.3 SECONDS
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER
	pixel_x = -80
	base_pixel_x = -80
	pixel_y = -80
	base_pixel_y = -80
