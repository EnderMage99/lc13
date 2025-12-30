// Coupid - O-02-1402
// HE-class abnormality - Pollen/allergy themed
// Part of the Holiday abnormality set

/// Amount of histamine to apply
#define COUPID_HISTAMINE_AMOUNT 10

/mob/living/simple_animal/hostile/abnormality/coupid
	name = "Coupid"
	desc = "A cherubic figure wreathed in flowers and pollen. Its presence makes your eyes water."
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "coupid"
	icon_living = "coupid"
	icon_dead = "coupid_dead"
	portrait = "coupid"
	pixel_x = -16
	base_pixel_x = -16

	maxHealth = 1800
	health = 1800
	threat_level = HE_LEVEL
	start_qliphoth = 2
	max_boxes = 20
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = -1, PALE_DAMAGE = 0.4)
	// RED Normal, WHITE Endured, BLACK Absorbed, PALE Resisted

	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 15
	melee_damage_upper = 25
	attack_verb_continuous = "lashes"
	attack_verb_simple = "lash"
	attack_sound = 'sound/weapons/whip.ogg'

	work_damage_type = BLACK_DAMAGE
	work_damage_amount = 10
	can_breach = TRUE
	faction = list()
	move_to_delay = 4

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(20, 20, 25, 25, 30),
		ABNORMALITY_WORK_INSIGHT = list(60, 65, 70, 75, 80),
		ABNORMALITY_WORK_ATTACHMENT = list(45, 50, 55, 55, 60),
		ABNORMALITY_WORK_REPRESSION = list(45, 50, 55, 55, 60),
	)

	ego_list = list(
		// Add EGO datums when created
	)
	gift_type = null // Add gift when created
	abnormality_origin = ABNORMALITY_ORIGIN_ARTBOOK
	chem_type = /datum/reagent/abnormality/sin/gluttony

	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/wild_ashe = 1.5,
		/mob/living/simple_animal/hostile/abnormality/treat_or_trick = 1.5,
		/mob/living/simple_animal/hostile/abnormality/eve_of_winter = 1.5,
	)

	observation_prompt = "The flowers bloom so beautifully, yet your nose runs and your eyes water. \
		In the center of the garden stands a figure, offering you a bouquet. \
		You..."
	observation_choices = list(
		"Accept the flowers" = list(FALSE, "The allergic reaction intensifies. Your throat swells. The flowers are beautiful, but deadly to you."),
		"Politely decline" = list(TRUE, "The figure seems disappointed, but understanding. It plucks a single petal and offers it instead - this one doesn't make you sneeze."),
	)

	/// Cooldown for pollen spread during breach
	var/pollen_cooldown = 0
	var/pollen_cooldown_time = 10 SECONDS
	/// List of blossoms we've created
	var/list/spawned_blossoms = list()
	// Coupid heals the worker
	var/heal_amount = 20
	/// Can't move/attack when performing finishing move
	var/finishing = FALSE

/mob/living/simple_animal/hostile/abnormality/coupid/Destroy()
	for(var/obj/structure/forbidden_blossom/B in spawned_blossoms)
		if(!QDELETED(B))
			qdel(B)
	spawned_blossoms.Cut()
	return ..()

/mob/living/simple_animal/hostile/abnormality/coupid/CanAttack(atom/the_target)
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/coupid/Move()
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/coupid/Goto(target, delay, minimum_distance)
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/coupid/DestroySurroundings()
	if(finishing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/coupid/AttackingTarget(atom/attacked_target)
	if(finishing)
		return
	. = ..()
	if(.)
		if(!ishuman(attacked_target))
			return
		var/mob/living/carbon/human/TH = attacked_target
		if(TH.health < 0)
			finishing = TRUE
			TH.Stun(4 SECONDS)
			forceMove(get_turf(TH))
			for(var/i = 1 to 5)
				if(!targets_from.Adjacent(TH) || QDELETED(TH) || TH.health > 0)
					finishing = FALSE
					return
				SLEEP_CHECK_DEATH(3)
				TH.attack_animal(src)
			if(!targets_from.Adjacent(TH) || QDELETED(TH) || TH.health > 0)
				finishing = FALSE
				return
			playsound(get_turf(src), 'sound/weapons/whip.ogg', 50, TRUE)
			TH.gib()
			finishing = FALSE

/// After work completes, heal the worker but don't remove histamine
/mob/living/simple_animal/hostile/abnormality/coupid/WorkComplete(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	. = ..()
	if(!ishuman(user))
		return
	user.adjustBruteLoss(-heal_amount)
	user.adjustFireLoss(-heal_amount)
	user.reagents?.add_reagent(/datum/reagent/toxin/histamine, COUPID_HISTAMINE_AMOUNT)
	to_chat(user, span_warning("You feel an allergic reaction starting..."))
	to_chat(user, span_nicegreen("[src] tends to your wounds with gentle care, though the sneezing continues..."))

/// Bad work result reduces qliphoth
/mob/living/simple_animal/hostile/abnormality/coupid/FailureEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	. = ..()
	datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/coupid/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(!.)
		return

/mob/living/simple_animal/hostile/abnormality/coupid/Life()
	. = ..()
	if(!.)
		return FALSE
	if(status_flags & GODMODE)
		return FALSE
	// Spread pollen during breach
	if(pollen_cooldown < world.time)
		SpreadPollen()
		pollen_cooldown = world.time + pollen_cooldown_time

/// Spread pollen in an area around Coupid
/mob/living/simple_animal/hostile/abnormality/coupid/proc/SpreadPollen()
	var/pollen_range = 5
	for(var/turf/T in view(pollen_range, src))
		if(prob(30))
			new /obj/effect/temp_visual/pollen(T)
	// Apply histamine to nearby humans
	for(var/mob/living/carbon/human/H in view(pollen_range, src))
		if(H.stat == DEAD)
			continue
		H.reagents?.add_reagent(/datum/reagent/toxin/histamine, COUPID_HISTAMINE_AMOUNT)
		if(prob(20))
			to_chat(H, span_warning("The pollen makes you start sneezing uncontrollably!"))

// ==================== FORBIDDEN BLOSSOM ====================

/obj/structure/forbidden_blossom
	name = "Forbidden Blossom"
	desc = "A grotesque flower that has bloomed from a corpse. It releases allergens and seems to attract abnormalities."
	icon = 'icons/obj/flora/ausflora.dmi'
	icon_state = "fernybush_1"
	anchored = TRUE
	density = FALSE
	max_integrity = 750
	resistance_flags = FIRE_PROOF
	/// Reference to the Coupid that spawned us
	var/mob/living/simple_animal/hostile/abnormality/coupid/connected_abno
	/// Cooldown for allergen release
	var/allergen_cooldown = 0
	var/allergen_cooldown_time = 8 SECONDS
	/// Range for attracting abnormalities
	var/attract_range = 15

/obj/structure/forbidden_blossom/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)
	icon_state = pick("fernybush_1", "fernybush_2", "fernybush_3")

/obj/structure/forbidden_blossom/Destroy()
	STOP_PROCESSING(SSobj, src)
	connected_abno = null
	return ..()

/obj/structure/forbidden_blossom/process(delta_time)
	if(allergen_cooldown < world.time)
		ReleaseAllergens()
		AttractAbnormalities()
		allergen_cooldown = world.time + allergen_cooldown_time

/// Release allergens in area
/obj/structure/forbidden_blossom/proc/ReleaseAllergens()
	var/allergen_range = 4
	for(var/turf/T in view(allergen_range, src))
		if(prob(20))
			new /obj/effect/temp_visual/pollen(T)
	for(var/mob/living/carbon/human/H in view(allergen_range, src))
		if(H.stat == DEAD)
			continue
		H.reagents?.add_reagent(/datum/reagent/toxin/histamine, COUPID_HISTAMINE_AMOUNT)
		if(prob(20))
			to_chat(H, span_warning("The blossom's pollen triggers an allergic reaction!"))

/// Attract nearby abnormalities
/obj/structure/forbidden_blossom/proc/AttractAbnormalities()
	for(var/mob/living/simple_animal/hostile/abnormality/A in range(attract_range, src))
		if(A == connected_abno)
			continue
		if(A.IsContained())
			continue
		// Give abnormalities a target near the blossom
		if(!A.target && prob(20))
			A.GiveTarget(src)

/obj/structure/forbidden_blossom/examine(mob/user)
	. = ..()
	. += span_warning("It pulses with an unnatural life, releasing clouds of pollen.")
	. += span_notice("It seems extremely resilient, but can be destroyed with enough effort.")

// ==================== POLLEN VISUAL ====================

/obj/effect/temp_visual/pollen
	name = "pollen"
	desc = "A cloud of allergen-laden pollen."
	icon = 'icons/effects/effects.dmi'
	icon_state = "mustard"
	duration = 3 SECONDS
	layer = ABOVE_MOB_LAYER
	alpha = 150
	color = "#FFFF88"

/obj/effect/temp_visual/pollen/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = duration)

#undef COUPID_HISTAMINE_AMOUNT
