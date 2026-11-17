// Foe spawn points for the Grand Magasin. Each one spawns its foe when it loads, with a room or with the map, and can
// spawn it again later. Map them into rooms facing the way the foe should face; GmsRespawnFoes() restocks a floor.
GLOBAL_LIST_EMPTY(gms_foe_spawns)

/// Spawns its foe_type on itself. Keeps track of the foe it spawned, so a respawn replaces it instead of adding another.
/obj/effect/landmark/gms_foe_spawn
	name = "foe spawn"
	icon = 'icons/effects/gms_landmarks.dmi'
	icon_state = "x"
	var/foe_type
	/// The foe it last spawned, until that foe is deleted.
	var/mob/living/simple_animal/hostile/gms_foe/foe

/obj/effect/landmark/gms_foe_spawn/Initialize()
	. = ..()
	GLOB.gms_foe_spawns += src
	Spawn()

// A spawn point is only removed with its room, so its foe goes with it.
/obj/effect/landmark/gms_foe_spawn/Destroy()
	GLOB.gms_foe_spawns -= src
	if(foe)
		UnregisterSignal(foe, COMSIG_PARENT_QDELETING)
		QDEL_NULL(foe)
	return ..()

/// Spawns a new foe here, deleting the one it spawned before, alive or dead.
/obj/effect/landmark/gms_foe_spawn/proc/Spawn()
	if(foe)
		UnregisterSignal(foe, COMSIG_PARENT_QDELETING)
		QDEL_NULL(foe)
	if(!foe_type)
		return
	foe = new foe_type(get_turf(src))
	foe.setDir(dir)
	RegisterSignal(foe, COMSIG_PARENT_QDELETING, PROC_REF(OnFoeDeleted))

/obj/effect/landmark/gms_foe_spawn/proc/OnFoeDeleted(datum/source)
	SIGNAL_HANDLER
	foe = null

/// Respawns the foe of every spawn point on a z-level, or on every floor if no z-level is given. Returns how many.
/proc/GmsRespawnFoes(z)
	. = 0
	for(var/obj/effect/landmark/gms_foe_spawn/spawn_point as anything in GLOB.gms_foe_spawns)
		if(z && spawn_point.z != z)
			continue
		spawn_point.Spawn()
		.++
		CHECK_TICK

/obj/effect/landmark/gms_foe_spawn/denim_wallet
	name = "denim wallet spawn"
	icon_state = "denim_wallet"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/denim_wallet

/obj/effect/landmark/gms_foe_spawn/leather_wallet
	name = "leather wallet spawn"
	icon_state = "leather_wallet"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/denim_wallet/leather_wallet

/obj/effect/landmark/gms_foe_spawn/hungry_kaki
	name = "hungry kaki spawn"
	icon_state = "hungry_kaki"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/kaki

/obj/effect/landmark/gms_foe_spawn/thirsty_kaki
	name = "thirsty kaki spawn"
	icon_state = "thirsty_kaki"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/kaki/thirsty

/obj/effect/landmark/gms_foe_spawn/hungry_kaki_sunshone
	name = "sunshone hungry kaki spawn"
	icon_state = "hungry_kaki_sunshone"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/kaki_sunshone

/obj/effect/landmark/gms_foe_spawn/thirsty_kaki_sunshone
	name = "sunshone thirsty kaki spawn"
	icon_state = "thirsty_kaki_sunshone"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/kaki_sunshone/thirsty

/obj/effect/landmark/gms_foe_spawn/leather_glove
	name = "leather glove spawn"
	icon_state = "leather_glove"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/leather_glove

/obj/effect/landmark/gms_foe_spawn/mobile_go_spin
	name = "Mobile-Go-Spin spawn"
	icon_state = "mobile_go_spin"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/mobile_go_spin

/obj/effect/landmark/gms_foe_spawn/green_needlekin
	name = "green needlekin spawn"
	icon_state = "green_needlekin"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/needlekin

/obj/effect/landmark/gms_foe_spawn/red_needlekin
	name = "red needlekin spawn"
	icon_state = "red_needlekin"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/needlekin/red

/obj/effect/landmark/gms_foe_spawn/mouth_taste_tester
	name = "mouth taste tester spawn"
	icon_state = "mouth_taste_tester"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/taste_tester

/obj/effect/landmark/gms_foe_spawn/eye_taste_tester
	name = "eye taste tester spawn"
	icon_state = "eye_taste_tester"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/taste_tester/eye

/obj/effect/landmark/gms_foe_spawn/nose_taste_tester
	name = "nose taste tester spawn"
	icon_state = "nose_taste_tester"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/taste_tester/nose

/obj/effect/landmark/gms_foe_spawn/leatherfather
	name = "Leatherfather spawn"
	icon_state = "leatherfather"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/leatherfather

/obj/effect/landmark/gms_foe_spawn/king_of_needleworks
	name = "King of Needleworks spawn"
	icon_state = "king_of_needleworks"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/king_of_needleworks

/obj/effect/landmark/gms_foe_spawn/third_floor_manager
	name = "3rd Floor Manager spawn"
	icon_state = "third_floor_manager"
	foe_type = /mob/living/simple_animal/hostile/gms_foe/third_floor_manager
