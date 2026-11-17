// Lighting in the Grand Magasin. The base stays fullbright; every room the generator loads is moved into the dark
// room area, where only the ceiling lights mapped into it light anything.

/// The rooms around the base. Dark unless lit; the generator moves each loaded room's turfs into it.
/area/gms/room
	name = "Grand Magasin Sisyphe Room"
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED

/// A shaft of light falling from the ceiling onto its tile. It cannot be touched or broken; it goes with its room.
/// Its icon is the pool on the floor and the shaft above is an overlay: a taller icon would move the light up a tile.
/obj/effect/gms_ceiling_light
	name = "ceiling light"
	desc = "Light falls here from somewhere high above."
	icon = 'icons/effects/gms_ceiling_light.dmi'
	icon_state = "light"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	// Above the lighting so the shaft glows over whatever stands in it, added on rather than painted over.
	plane = ABOVE_LIGHTING_PLANE
	blend_mode = BLEND_ADD
	light_range = 4
	light_power = 1
	light_color = "#FFF4E0"

/obj/effect/gms_ceiling_light/Initialize()
	. = ..()
	var/mutable_appearance/shaft = mutable_appearance(icon, "[icon_state]_shaft")
	shaft.pixel_y = world.icon_size
	shaft.blend_mode = BLEND_ADD
	add_overlay(shaft)

/obj/effect/gms_ceiling_light/singularity_act()
	return

/obj/effect/gms_ceiling_light/singularity_pull()
	return

/// A fainter shaft that lights less of the room around it.
/obj/effect/gms_ceiling_light/dim
	icon_state = "dim"
	light_range = 3
	light_power = 0.6

/// Twice as bright as a plain ceiling light, reaching twice as far.
/obj/effect/gms_ceiling_light/double
	name = "bright ceiling light"
	light_range = 8
	light_power = 2

/// Three times as bright as a plain ceiling light, reaching three times as far.
/obj/effect/gms_ceiling_light/triple
	name = "blazing ceiling light"
	light_range = 12
	light_power = 3
