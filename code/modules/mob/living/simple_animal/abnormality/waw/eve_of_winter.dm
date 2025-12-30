// Eve of Winter - O-02-1225
// WAW-class abnormality - Ice/cold themed
// Part of the Holiday abnormality set
// During breach becomes "Adam" and stays in containment room

/mob/living/simple_animal/hostile/abnormality/eve_of_winter
	name = "Eve of Winter"
	desc = "A beautiful figure carved from ice and frost. The air around them is bitterly cold."
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "eve_of_winter"
	icon_living = "eve_of_winter"
	icon_dead = "eve_of_winter_dead"
	portrait = "eve_of_winter"
	pixel_x = -16
	base_pixel_x = -16

	maxHealth = 2500
	health = 2500
	threat_level = WAW_LEVEL
	start_qliphoth = 3
	max_boxes = 25
	// RED Endured, WHITE Absorbed, BLACK Endured, PALE Resistant
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = -1, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.4)

	melee_damage_type = WHITE_DAMAGE
	melee_damage_lower = 35
	melee_damage_upper = 50
	attack_verb_continuous = "freezes"
	attack_verb_simple = "freeze"
	attack_sound = 'sound/effects/glassbr1.ogg'

	work_damage_type = WHITE_DAMAGE
	work_damage_amount = 15
	can_breach = TRUE
	faction = list()
	move_to_delay = 4

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(30, 35, 40, 40, 45),
		ABNORMALITY_WORK_INSIGHT = list(45, 50, 55, 55, 60),
		ABNORMALITY_WORK_ATTACHMENT = list(60, 65, 70, 75, 80),
		ABNORMALITY_WORK_REPRESSION = list(60, 65, 70, 75, 80),
	)

	ego_list = list(
		// Add EGO datums when created
	)
	gift_type = null // Add gift when created
	abnormality_origin = ABNORMALITY_ORIGIN_ARTBOOK
	chem_type = /datum/reagent/abnormality/sin/gloom

	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/wild_ashe = 1.5,
		/mob/living/simple_animal/hostile/abnormality/treat_or_trick = 1.5,
		/mob/living/simple_animal/hostile/abnormality/coupid = 1.5,
	)

	observation_prompt = "The cold bites at your skin as you stand before the frozen figure. \
		Snow falls gently around you, each flake impossibly beautiful. \
		The figure extends a hand, offering you a gift wrapped in frost. \
		You..."
	observation_choices = list(
		"Accept the gift" = list(FALSE, "The cold seeps into your bones as you touch the gift. You feel yourself becoming ice..."),
		"Warm them with your presence" = list(TRUE, "You step closer, sharing what little warmth you have. For a moment, you see a tear freeze on their cheek."),
	)

	/// List of ice statues we've created
	var/list/ice_statues = list()
	/// Cooldown for freezing humans
	var/freeze_cooldown = 0
	var/freeze_cooldown_time = 5 SECONDS
	/// Cooldown for spawning presents
	var/present_cooldown = 0
	var/present_cooldown_time = 30 SECONDS
	/// Are we in Adam form (breached)?
	var/is_adam = FALSE

/mob/living/simple_animal/hostile/abnormality/eve_of_winter/Destroy()
	for(var/obj/structure/intice_statue/S in ice_statues)
		if(!QDELETED(S))
			qdel(S)
	ice_statues.Cut()
	return ..()

/// Worktick deals random damage regardless of PE generation
/mob/living/simple_animal/hostile/abnormality/eve_of_winter/Worktick(mob/living/carbon/human/user, bubble_type, work_type)
	. = ..()
	if(!ishuman(user))
		return
	// Random chance to deal work damage regardless of success
	if(prob(30))
		user.deal_damage(work_damage_amount, work_damage_type, src)
		to_chat(user, span_danger("The cold bites into you unexpectedly!"))

/mob/living/simple_animal/hostile/abnormality/eve_of_winter/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(!.)
		return
	// Transform to Adam
	is_adam = TRUE
	name = "Adam"
	icon_state = "adam"
	icon_living = "adam"
	visible_message(span_danger("[src] transforms into a terrifying visage of winter's wrath!"))

/// Adam doesn't leave containment zones
/mob/living/simple_animal/hostile/abnormality/eve_of_winter/Move(turf/newloc, dir, step_x, step_y)
	if(is_adam && !(status_flags & GODMODE))
		var/area/new_area = get_area(newloc)
		// Only allow movement within containment zones
		if(!istype(new_area, /area/containment_zone))
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/eve_of_winter/Life()
	. = ..()
	if(!.)
		return FALSE
	if(status_flags & GODMODE)
		return FALSE
	// Check for humans to freeze
	if(freeze_cooldown < world.time)
		CheckForFreezeTargets()
		freeze_cooldown = world.time + freeze_cooldown_time
	// Spawn presents occasionally
	if(present_cooldown < world.time && prob(20))
		SpawnPresent()
		present_cooldown = world.time + present_cooldown_time

/// Check for insaned or frozen humans to convert to ice statues
/mob/living/simple_animal/hostile/abnormality/eve_of_winter/proc/CheckForFreezeTargets()
	var/freeze_range = 7
	for(var/mob/living/carbon/human/H in view(freeze_range, src))
		if(H.stat == DEAD)
			continue
		// Check if insaned or frozen
		if(H.sanity_lost || H.has_status_effect(/datum/status_effect/freon))
			ConvertToStatue(H)
			return  // Only convert one at a time

/// Convert a human to an ice statue
/mob/living/simple_animal/hostile/abnormality/eve_of_winter/proc/ConvertToStatue(mob/living/carbon/human/H)
	if(!H)
		return
	visible_message(span_danger("[H] is encased in ice, becoming a frozen statue!"))
	playsound(get_turf(H), 'sound/effects/glassbr1.ogg', 50, TRUE)
	var/obj/structure/intice_statue/S = new(get_turf(H))
	S.frozen_victim = H
	S.connected_abno = src
	H.forceMove(S)
	ADD_TRAIT(H, TRAIT_NOBREATH, src)
	ADD_TRAIT(H, TRAIT_INCAPACITATED, src)
	ADD_TRAIT(H, TRAIT_IMMOBILIZED, src)
	ice_statues += S
	RegisterSignal(S, COMSIG_PARENT_QDELETING, PROC_REF(OnStatueDestroyed))

/mob/living/simple_animal/hostile/abnormality/eve_of_winter/proc/OnStatueDestroyed(obj/structure/intice_statue/S)
	SIGNAL_HANDLER
	UnregisterSignal(S, COMSIG_PARENT_QDELETING)
	ice_statues -= S

/// Spawn a present nearby
/mob/living/simple_animal/hostile/abnormality/eve_of_winter/proc/SpawnPresent()
	var/list/valid_turfs = list()
	for(var/turf/T in view(5, src))
		if(!T.density && !istype(T, /turf/closed))
			valid_turfs += T
	if(!length(valid_turfs))
		return
	var/turf/spawn_turf = pick(valid_turfs)
	new /obj/structure/winter_present(spawn_turf)
	visible_message(span_notice("A frost-covered present materializes nearby..."))

/mob/living/simple_animal/hostile/abnormality/eve_of_winter/update_icon_state()
	if(status_flags & GODMODE)
		// Contained - back to Eve
		is_adam = FALSE
		name = initial(name)
		icon_state = initial(icon_state)
		icon_living = initial(icon_living)
	else if(is_adam)
		icon_state = "adam"
		icon_living = "adam"

// ==================== ICE STATUE ====================

/obj/structure/intice_statue
	name = "Ice Statue"
	desc = "A person frozen solid in a block of ice. They seem to still be alive inside..."
	icon = 'icons/obj/flora/icedecor.dmi'
	icon_state = "ice_grave2"
	anchored = TRUE
	density = TRUE
	max_integrity = 300
	/// The human frozen inside
	var/mob/living/carbon/human/frozen_victim
	/// Reference to Eve of Winter
	var/mob/living/simple_animal/hostile/abnormality/eve_of_winter/connected_abno
	/// Has this statue been awakened?
	var/awakened = FALSE

/obj/structure/intice_statue/Destroy()
	if(frozen_victim && !QDELETED(frozen_victim))
		// Release victim
		frozen_victim.forceMove(get_turf(src))
		REMOVE_TRAIT(frozen_victim, TRAIT_NOBREATH, connected_abno)
		REMOVE_TRAIT(frozen_victim, TRAIT_INCAPACITATED, connected_abno)
		REMOVE_TRAIT(frozen_victim, TRAIT_IMMOBILIZED, connected_abno)
		// If statue was destroyed (not awakened), deal damage to Eve
		if(!awakened && connected_abno && !QDELETED(connected_abno))
			var/damage_amount = connected_abno.maxHealth * 0.2
			connected_abno.deal_damage(damage_amount, RED_DAMAGE, null, flags = DAMAGE_FORCED)
			visible_message(span_danger("[connected_abno] recoils as one of its statues is shattered!"))
	frozen_victim = null
	connected_abno = null
	return ..()

/obj/structure/intice_statue/attackby(obj/item/W, mob/user, params)
	. = ..()
	// If damaged but not destroyed, awaken the statue
	if(!awakened && obj_integrity < max_integrity && obj_integrity > 0)
		Awaken()

/obj/structure/intice_statue/bullet_act(obj/projectile/P)
	. = ..()
	if(!awakened && obj_integrity < max_integrity && obj_integrity > 0)
		Awaken()

/// Awaken the statue as a hostile mob
/obj/structure/intice_statue/proc/Awaken()
	if(awakened)
		return
	awakened = TRUE
	visible_message(span_danger("[src] cracks and the frozen figure begins to move!"))
	playsound(get_turf(src), 'sound/effects/glassbr2.ogg', 60, TRUE)
	// Spawn hostile animated statue
	var/mob/living/simple_animal/hostile/intice_statue_animated/animated = new(get_turf(src))
	animated.connected_abno = connected_abno
	// The frozen victim dies
	if(frozen_victim)
		frozen_victim.death()
	// Destroy self
	qdel(src)

/obj/structure/intice_statue/examine(mob/user)
	. = ..()
	if(frozen_victim)
		. += span_notice("[frozen_victim] is frozen inside.")
	. += span_warning("Destroying the statue might weaken whatever created it...")
	. += span_danger("But damaging it might wake something up...")

// ==================== ANIMATED ICE STATUE ====================

/mob/living/simple_animal/hostile/intice_statue_animated
	name = "Awakened Ice Statue"
	desc = "A frozen figure animated by malevolent cold. Its movements are jerky but deadly."
	icon = 'icons/obj/flora/icedecor.dmi'
	icon_state = "ice_grave1"
	icon_living = "ice_grave1"
	maxHealth = 400
	health = 400
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	melee_damage_lower = 20
	melee_damage_upper = 30
	melee_damage_type = WHITE_DAMAGE
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/effects/glassbr1.ogg'
	faction = list("hostile")
	move_to_delay = 6
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	/// Reference to Eve of Winter
	var/mob/living/simple_animal/hostile/abnormality/eve_of_winter/connected_abno

/mob/living/simple_animal/hostile/intice_statue_animated/death(gibbed)
	visible_message(span_notice("[src] shatters into a pile of ice shards!"))
	playsound(get_turf(src), 'sound/effects/glassbr3.ogg', 50, TRUE)
	// Spawn ice shards
	for(var/i in 1 to 3)
		new /obj/item/shard/ice(get_turf(src))
	return ..()

// ==================== WINTER PRESENT ====================

/obj/structure/winter_present
	name = "Frost-Covered Present"
	desc = "A gift wrapped in frost and tied with icicles. What could be inside?"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "yourfloor_rainbow"  // Placeholder
	anchored = FALSE
	density = FALSE

/obj/structure/winter_present/attack_hand(mob/user)
	. = ..()
	OpenPresent(user)

/obj/structure/winter_present/attackby(obj/item/W, mob/user, params)
	OpenPresent(user)
	return TRUE

/obj/structure/winter_present/proc/OpenPresent(mob/user)
	visible_message(span_notice("[user] opens [src]..."))
	playsound(get_turf(src), 'sound/items/poster_ripped.ogg', 50, TRUE)
	if(prob(50))
		// Bad outcome - frozen head (sanity damage)
		visible_message(span_danger("Inside is a frozen severed head!"))
		to_chat(user, span_userdanger("The sight horrifies you!"))
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.adjustSanityLoss(30)
		new /obj/effect/gibspawner/generic(get_turf(src))
	else
		// Good outcome - random loot
		var/loot = pick(list(
			/obj/item/storage/firstaid/regular,  // Healing item
			/obj/item/stack/medical/bruise_pack,  // Bandages
			/obj/item/reagent_containers/syringe,  // Syringe
		))
		new loot(get_turf(src))
		visible_message(span_nicegreen("Inside is a useful item!"))
	qdel(src)

/obj/structure/winter_present/examine(mob/user)
	. = ..()
	. += span_notice("It could contain something useful... or something terrible.")

// Ice shard item for dropped items
/obj/item/shard/ice
	name = "ice shard"
	desc = "A sharp piece of magical ice."
	icon_state = "large"
	color = "#88DDFF"
