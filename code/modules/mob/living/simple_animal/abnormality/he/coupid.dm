// Coupid - O-02-1402
// HE-class abnormality - Pollen/allergy themed
// Part of the Holiday abnormality set

#define COUPID_HISTAMINE_AMOUNT 10

/mob/living/simple_animal/hostile/abnormality/coupid
	name = "Coupid"
	desc = "A cherubic figure wreathed in flowers and pollen. Its presence makes your eyes water."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "coupid_contained"
	icon_living = "coupid_contained"
	icon_dead = "coupid_dead"
	portrait = "coupid"

	maxHealth = 1800
	health = 1800
	threat_level = HE_LEVEL
	start_qliphoth = 2
	max_boxes = 20
	// RED Normal, WHITE Endured, BLACK Absorbed, PALE Resisted
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = -1, PALE_DAMAGE = 0.4)

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
		/datum/ego_datum/weapon/allergen,
		/datum/ego_datum/armor/allergen,
	)
	gift_type = null
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
	/// List of blossoms we've created
	var/list/spawned_blossoms = list()
	/// Heal amount after work
	var/heal_amount = 20

/mob/living/simple_animal/hostile/abnormality/coupid/Destroy()
	for(var/obj/structure/forbidden_blossom/B in spawned_blossoms)
		if(!QDELETED(B))
			qdel(B)
	spawned_blossoms.Cut()
	return ..()

/// During work, agents suffer allergic response
/mob/living/simple_animal/hostile/abnormality/coupid/Worktick(mob/living/carbon/human/user, bubble_type, work_type)
	. = ..()
	if(!ishuman(user))
		return
	// Apply histamine during work regardless of success
	if(prob(30))
		user.reagents?.add_reagent(/datum/reagent/toxin/histamine, COUPID_HISTAMINE_AMOUNT * 0.5)
		to_chat(user, span_warning("The pollen makes your nose itch..."))

/// After work, heal the worker but don't remove histamine
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
	icon_state = "coupid"
	icon_living = "coupid"

/mob/living/simple_animal/hostile/abnormality/coupid/Life()
	. = ..()
	if(!. || (status_flags & GODMODE))
		return
	// Spread pollen during breach
	if(pollen_cooldown < world.time)
		SpreadPollen()
		pollen_cooldown = world.time + 10 SECONDS

/// Spread pollen in an area around Coupid
/mob/living/simple_animal/hostile/abnormality/coupid/proc/SpreadPollen()
	for(var/turf/T in view(5, src))
		if(prob(30))
			new /obj/effect/temp_visual/pollen(T)
	for(var/mob/living/carbon/human/H in view(5, src))
		if(H.stat == DEAD)
			continue
		H.reagents?.add_reagent(/datum/reagent/toxin/histamine, COUPID_HISTAMINE_AMOUNT)
		if(prob(20))
			to_chat(H, span_warning("The pollen makes you start sneezing uncontrollably!"))

/// When Coupid kills someone, spawn a Forbidden Blossom
/mob/living/simple_animal/hostile/abnormality/coupid/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!.)
		return
	if(!ishuman(attacked_target))
		return
	var/mob/living/carbon/human/H = attacked_target
	if(H.stat == DEAD)
		SpawnBlossom(get_turf(H))

/// Spawn a Forbidden Blossom on a corpse
/mob/living/simple_animal/hostile/abnormality/coupid/proc/SpawnBlossom(turf/T)
	if(!T)
		return
	visible_message(span_danger("A grotesque flower blooms from the corpse!"))
	var/obj/structure/forbidden_blossom/B = new(T)
	B.connected_abno = src
	spawned_blossoms += B
	RegisterSignal(B, COMSIG_PARENT_QDELETING, PROC_REF(OnBlossomDestroyed))

/mob/living/simple_animal/hostile/abnormality/coupid/proc/OnBlossomDestroyed(obj/structure/forbidden_blossom/B)
	SIGNAL_HANDLER
	UnregisterSignal(B, COMSIG_PARENT_QDELETING)
	spawned_blossoms -= B

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
		allergen_cooldown = world.time + 8 SECONDS

/// Release allergens in area
/obj/structure/forbidden_blossom/proc/ReleaseAllergens()
	for(var/turf/T in view(4, src))
		if(prob(20))
			new /obj/effect/temp_visual/pollen(T)
	for(var/mob/living/carbon/human/H in view(4, src))
		if(H.stat == DEAD)
			continue
		H.reagents?.add_reagent(/datum/reagent/toxin/histamine, COUPID_HISTAMINE_AMOUNT)
		if(prob(20))
			to_chat(H, span_warning("The blossom's pollen triggers an allergic reaction!"))

/// Attract nearby abnormalities
/obj/structure/forbidden_blossom/proc/AttractAbnormalities()
	for(var/mob/living/simple_animal/hostile/abnormality/A in range(15, src))
		if(A == connected_abno || A.IsContained())
			continue
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
