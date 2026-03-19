// =============================================
// Prostheti Innovations — Chapter 2 Map Landmarks
// =============================================
// Self-deleting landmarks that store turfs in GLOB lists.
//
// HUB MAP LANDMARKS (prostheti_innovations.dmm):
// - medical_bed_1 through medical_bed_4: Patient beds in Medical Wing (player buckle targets)
// - penny_medical_bed: Penny's bed in Medical Wing
// - clyde_medical_stand: Where Clyde stands during confrontation cutscene
//
// FACTORY MAP LANDMARKS (competitor_factory.dmm):
// - Uses mission_player_spawn from mission_landmarks.dm for player spawns
// - Uses mission_mob_spawn from mission_landmarks.dm for enemy placement
// - penny_companion_spawn: Where Penny's combat companion spawns

// =============================================
// Medical Wing — Patient Bed Landmarks (Hub Map)
// =============================================
// Players are buckled to these beds after extraction from the factory.
// Place 4 beds in the Medical Wing area, near each other.

/obj/effect/landmark/prostheti_npc_spawn/medical_bed_1
	name = "Medical bed 1"
	landmark_id = "medical_bed_1"

/obj/effect/landmark/prostheti_npc_spawn/medical_bed_2
	name = "Medical bed 2"
	landmark_id = "medical_bed_2"

/obj/effect/landmark/prostheti_npc_spawn/medical_bed_3
	name = "Medical bed 3"
	landmark_id = "medical_bed_3"

/obj/effect/landmark/prostheti_npc_spawn/medical_bed_4
	name = "Medical bed 4"
	landmark_id = "medical_bed_4"

/obj/effect/landmark/prostheti_npc_spawn/penny_medical_bed
	name = "Penny medical bed"
	landmark_id = "penny_medical_bed"

/obj/effect/landmark/prostheti_npc_spawn/clyde_medical_stand
	name = "Clyde medical stand"
	landmark_id = "clyde_medical_stand"

// =============================================
// Factory Mission — Penny Companion Spawn (Factory Map)
// =============================================

/obj/effect/landmark/prostheti_npc_spawn/penny_companion
	name = "Penny companion spawn"
	landmark_id = "penny_companion_spawn"

// =============================================
// Factory Mission — Rally Point Spawn (Hub Map)
// =============================================
// Where the mission rally point object spawns in the Training Yard.

/obj/effect/landmark/prostheti_npc_spawn/rally_point
	name = "Rally point spawn"
	landmark_id = "rally_point_spawn"

// =============================================
// Factory Mission — Mob Spawn Subtypes
// =============================================
// These are placed on the factory away map (competitor_factory.dmm).
// They use the persistent mission_mob_spawn pattern from mission_landmarks.dm.

/obj/effect/landmark/mission_mob_spawn/factory_worker
	name = "factory worker spawn"
	mob_type = /mob/living/simple_animal/hostile/prostheti/factory_worker

/obj/effect/landmark/mission_mob_spawn/factory_heavy
	name = "factory heavy spawn"
	mob_type = /mob/living/simple_animal/hostile/prostheti/factory_worker/heavy

/obj/effect/landmark/mission_mob_spawn/factory_director
	name = "factory director spawn"
	mob_type = /mob/living/simple_animal/hostile/prostheti/factory_director
	segment_id = "office"
