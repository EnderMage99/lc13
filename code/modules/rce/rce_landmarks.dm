/obj/effect/landmark/rce_fob
	name = "RCE FOB"

/obj/effect/landmark/rce_fob/Initialize()
	. = ..()
	SSgamedirector.RegisterFOB(src)

/obj/effect/landmark/rce_arena_teleport
	name = "Combatant Lobby Warp"

/obj/effect/landmark/rce_arena_teleport/Initialize()
	. = ..()
	SSgamedirector.RegisterLobby(src)

/obj/effect/landmark/rce_postfight_teleport
	name = "Heart Victory Warp"

/obj/effect/landmark/rce_postfight_teleport/Initialize()
	. = ..()
	SSgamedirector.RegisterVictoryTeleport(src)

/obj/effect/landmark/heartfight_pylon
	name = "Heart Fight Pylon marker"

/obj/effect/landmark/heartfight_pylon/Initialize()
	. = ..()
	SSgamedirector.RegisterHeartfightPylon(src)

/obj/effect/landmark/rce_target
	name = "X-Corp Attack Target"
	var/id
	var/landmark_type = RCE_TARGET_TYPE_GENERIC

/obj/effect/landmark/rce_target/Initialize(mapload)
	..()
	GLOB.rce_targets += get_turf(src)
	if(id)
		SSgamedirector.RegisterTarget(src, landmark_type, id)
	else
		SSgamedirector.RegisterTarget(src, landmark_type)

/obj/effect/landmark/rce_target/fob_entrance
	landmark_type = RCE_TARGET_TYPE_FOB_ENTRANCE

/obj/effect/landmark/rce_target/low_level
	landmark_type = RCE_TARGET_TYPE_LOW_LEVEL

/obj/effect/landmark/rce_target/mid_level
	landmark_type = RCE_TARGET_TYPE_MID_LEVEL

/obj/effect/landmark/rce_target/high_level
	landmark_type = RCE_TARGET_TYPE_HIGH_LEVEL

/obj/effect/landmark/rce_target/xcorp_base
	landmark_type = RCE_TARGET_TYPE_XCORP_BASE

/obj/effect/landmark/rce_spawn/xcorp_heart
	name = "xcorp heart spawn"

/obj/effect/landmark/rce_spawn/xcorp_heart/Initialize(mapload)
	..()
	new /mob/living/simple_animal/hostile/megafauna/xcorp_heart(get_turf(src))
