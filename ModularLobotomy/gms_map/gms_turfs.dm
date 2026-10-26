// Walls and floors of the Grand Magasin Sisyphe, rebuilt from the 1F map.
/area/gms
	name = "Grand Magasin Sisyphe"
	icon_state = "away"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

// Empty grid space the floor generator may build rooms in. Anything in another area counts as the base.
/area/gms/unbuilt
	name = "Unbuilt Floor"

// Marks a door slot on a room shell. The generator cuts doors at fixed spots, so this only shows mappers what to keep clear.
/obj/effect/mapping_helpers/gms_door_slot
	name = "door slot"
	icon_state = "blocker"

// The black between the halls.
/turf/closed/indestructible/gms_void
	name = "darkness"
	desc = "There is nothing past the walls of the store."
	icon = 'icons/turf/floors.dmi'
	icon_state = "black"

/turf/closed/indestructible/reinforced/gms
	name = "wall"
	desc = "A wall of the Grand Magasin. It does not feel like it was built to keep anyone out."
	icon = 'icons/turf/walls/gms_panel.dmi'
	icon_state = "panel-0"
	base_icon_state = "panel"

/turf/closed/indestructible/reinforced/gms/plaster
	icon = 'icons/turf/walls/gms_plaster.dmi'
	icon_state = "plaster-0"
	base_icon_state = "plaster"

/turf/closed/indestructible/reinforced/gms/wainscot
	icon = 'icons/turf/walls/gms_wainscot.dmi'
	icon_state = "wainscot-0"
	base_icon_state = "wainscot"

/turf/closed/indestructible/reinforced/gms/crimson
	icon = 'icons/turf/walls/gms_crimson.dmi'
	icon_state = "crimson-0"
	base_icon_state = "crimson"

/turf/closed/indestructible/reinforced/gms/gilded
	icon = 'icons/turf/walls/gms_gilded.dmi'
	icon_state = "gilded-0"
	base_icon_state = "gilded"

/turf/open/indestructible/gms
	name = "tile floor"
	icon = 'icons/turf/floors/gms_turfs.dmi'
	icon_state = "cream"

/turf/open/indestructible/gms/checker
	icon_state = "checker"

/turf/open/indestructible/gms/diamond
	name = "carpet"
	icon_state = "diamond"
	footstep = FOOTSTEP_CARPET
	barefootstep = FOOTSTEP_CARPET_BAREFOOT
	clawfootstep = FOOTSTEP_CARPET_BAREFOOT

// Patterns that span two tiles each way. The cell is picked from the map position so the pattern runs on.
/turf/open/indestructible/gms/tiled
	icon_state = "carpet_red_00"
	base_icon_state = "carpet_red"

/turf/open/indestructible/gms/tiled/Initialize()
	. = ..()
	icon_state = "[base_icon_state]_[x % 2][y % 2]"

/turf/open/indestructible/gms/tiled/carpet_red
	name = "carpet"
	footstep = FOOTSTEP_CARPET
	barefootstep = FOOTSTEP_CARPET_BAREFOOT
	clawfootstep = FOOTSTEP_CARPET_BAREFOOT

/turf/open/indestructible/gms/tiled/obsidian
	name = "floor"
	icon_state = "obsidian_00"
	base_icon_state = "obsidian"
