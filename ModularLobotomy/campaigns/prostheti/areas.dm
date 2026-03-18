// Prostheti Innovations Factory Hub — Area Definitions

/// Base area for the Prostheti Innovations factory hub
/area/awaymission/prostheti
	name = "Prostheti Innovations"
	icon_state = "away"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	sound_environment = SOUND_ENVIRONMENT_ROOM

/// Entrance area near the bus stop — chapter select landmark goes here
/area/awaymission/prostheti/entrance
	name = "Prostheti Innovations - Entrance"
	icon_state = "awaycontent1"

/// Main workspace with augment design terminals and Clyde's office
/area/awaymission/prostheti/design_floor
	name = "Prostheti Innovations - Design Floor"
	icon_state = "awaycontent2"

/// Clyde's office, adjacent to the design floor
/area/awaymission/prostheti/design_floor/office
	name = "Prostheti Innovations - Clyde's Office"
	icon_state = "awaycontent3"

/// Connecting corridor with factory machinery — Penny patrols through here
/area/awaymission/prostheti/factory_floor
	name = "Prostheti Innovations - Factory Floor"
	icon_state = "awaycontent4"

/// Outdoor back area for training duels — gated behind locked door
/area/awaymission/prostheti/training_yard
	name = "Prostheti Innovations - Training Yard"
	icon_state = "awaycontent5"

/// Medical wing with beds — used for Ch2 extraction and Clyde confrontation
/area/awaymission/prostheti/medical_wing
	name = "Prostheti Innovations - Medical Wing"
	icon_state = "awaycontent6"
