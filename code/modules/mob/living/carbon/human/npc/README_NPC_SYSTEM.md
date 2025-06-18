# Wandering NPC System for City Gamemodes

This system implements wandering NPCs and housed NPCs for city-based gamemodes in LC13.

## Features

### Wandering NPCs
- Carbon human mobs that spawn in a restricted building and exit through one-way doors
- Wander between landmark points at a slow pace
- Carry 600-1000 cash and have a 25% chance to spawn with a camera
- Take actual photos using camera's captureimage() proc when witnessing crimes
- Store evidence photos in backpack for 45 seconds before delivery (must survive to report)
- Flee in panic for 5 seconds when witnessing attacks (increased movement speed)
- 1 minute cooldown between taking photos to prevent spam
- Automatic anti-stuck system recovers from pathfinding issues every 2 minutes

### Housed NPCs  
- Spawn in residential houses with 400-600 cash
- Protect their homes by warning intruders
- Report home invasions via say() message after 5 second warning
- Respond to doorbell rings by walking to the door and opening it
- Automatically connect to closest door landmark on spawn
- Return to home position after answering door

## Usage

### Map Setup

1. **Wandering NPC Spawn Building**
   - Place `/obj/effect/landmark/wandering_npc_spawn` where NPCs should spawn
   - Use `/obj/machinery/door/airlock/public/glass/npc_exit` for one-way exit doors

2. **Wandering Points**
   - Place `/obj/effect/landmark/wandering_npc_point` around the map
   - NPCs will randomly patrol between these points

3. **Association Dropoff**
   - Place `/obj/effect/landmark/association_dropoff` where evidence photos are delivered
   - Should be in an association or police building

4. **Housed NPCs**
   - Place `/obj/effect/landmark/housed_npc_spawn` inside houses
   - Place `/obj/effect/landmark/house_door_landmark` at the house entrance
   - Doorbell will spawn automatically next to door landmark
   - Ensure houses use `/area/city/house` area type

### Admin Commands

- `Spawn Wandering NPC` - Spawn an NPC at your location
- `Create NPC Landmark` - Create landmarks for testing

### Code Integration

To detect attacks for the witness system, the following hooks are implemented:
- `attack_hand()` for punches
- `attackby()` for weapon attacks  
- `bullet_act()` for projectiles

The system automatically tracks attacks and alerts nearby NPCs with cameras.

## Configuration

### Wandering NPC Settings
- `landmark_wait_time` - How long NPCs wait at each landmark (default: 5 seconds)
- Movement speed: 4 (normal), 2 (fleeing)
- Camera spawn chance: 25%
- Photo cooldown: 1 minute between photos
- Photo delivery delay: 45 seconds (must survive)
- Flee duration: 5 seconds when witnessing violence
- Anti-stuck check interval: 2 minutes

### Housed NPC Settings  
- Warning time before reporting: 5 seconds
- Doorbell cooldown: 5 seconds
- Warning cooldown: 10 seconds per intruder
- Door landmark connection: Distance-based (closest)

## Technical Details

### Photography System
- NPCs use the camera's `captureimage()` proc to take actual in-game photos
- Photos are stored in the NPC's backpack using `forceMove()`
- After 45 seconds, photos are delivered to association dropoff if NPC survives
- Photos include descriptions of what was witnessed

### Movement and Pathfinding
- Normal wandering uses `walk_to()` with pathfinding
- Fleeing uses `walk_away()` for panic movement
- Anti-stuck system monitors `is_wandering` flag and restarts movement if needed
- All movement stops on death via `death()` override

### State Management
- `flee_end_time` and `flee_target` track fleeing state
- `photo_cooldown` prevents photo spam
- `pending_photo_deliveries` tracks scheduled deliveries
- `last_movement_check` helps detect stuck NPCs

## Expansion Ideas

- Different NPC types (workers, security, etc.)
- Day/night behavior changes
- Panic responses to ordeals
- Trading or quest systems
- More complex home defense behaviors
- Group fleeing behavior
- Witness protection mechanics
- Make it so there is a glob list of all active NPCs, and when one of them dies a new NPC is spawned in a building.
