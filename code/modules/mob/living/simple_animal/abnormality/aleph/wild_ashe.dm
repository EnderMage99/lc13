// Wild Ashe - O-06-1006
// ALEPH-class abnormality - Fire/heat themed
// Part of the Holiday abnormality set

/mob/living/simple_animal/hostile/abnormality/wild_ashe
	name = "Wild Ashe"
	desc = "A towering figure wreathed in flames and ash. The heat emanating from it is unbearable."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wild_ashe"
	icon_living = "wild_ashe"
	icon_dead = "wild_ashe_dead"
	portrait = "wild_ashe"

	maxHealth = 5000
	health = 5000
	threat_level = ALEPH_LEVEL
	start_qliphoth = 1
	max_boxes = 35
	// RED Immune, WHITE Endured, BLACK Resistant, PALE Endured
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 0.5)

	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 40
	melee_damage_upper = 60
	attack_verb_continuous = "incinerates"
	attack_verb_simple = "incinerate"
	attack_sound = 'sound/items/welder.ogg'

	work_damage_type = RED_DAMAGE
	work_damage_amount = 20
	can_breach = TRUE
	faction = list()
	move_to_delay = 3
	del_on_death = FALSE

	light_color = COLOR_ORANGE
	light_range = 5
	light_power = 3

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(60, 65, 70, 75, 80),
		ABNORMALITY_WORK_INSIGHT = list(30, 35, 40, 40, 45),
		ABNORMALITY_WORK_ATTACHMENT = list(30, 35, 40, 40, 45),
		ABNORMALITY_WORK_REPRESSION = list(20, 20, 25, 25, 30),
	)

	ego_list = list(
		/datum/ego_datum/weapon/fireball,
		/datum/ego_datum/armor/fireball,
	)
	gift_type = null
	abnormality_origin = ABNORMALITY_ORIGIN_ARTBOOK
	chem_type = /datum/reagent/abnormality/sin/wrath

	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/treat_or_trick = 1.5,
		/mob/living/simple_animal/hostile/abnormality/eve_of_winter = 1.5,
		/mob/living/simple_animal/hostile/abnormality/coupid = 1.5,
	)

	observation_prompt = "The flames dance before you, forming shapes of memories long forgotten. \
		In the heart of the inferno, you see a figure watching you. \
		The heat is unbearable, yet something compels you forward. \
		You..."
	observation_choices = list(
		"Walk into the flames" = list(FALSE, "The flames consume you, but you feel no pain - only an endless burning that lasts forever."),
		"Offer something precious" = list(TRUE, "You throw something dear to you into the fire. The flames dim for a moment, and you feel... acknowledged."),
	)

	/// Cooldown for hall burning
	var/hall_burn_cooldown = 0

/mob/living/simple_animal/hostile/abnormality/wild_ashe/Initialize(mapload)
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(OnMobDeath))

/mob/living/simple_animal/hostile/abnormality/wild_ashe/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	return ..()

/// Work is noticeably slow
/mob/living/simple_animal/hostile/abnormality/wild_ashe/SpeedWorktickOverride(mob/living/carbon/human/user, work_speed, init_work_speed, work_type)
	return work_speed * 1.5

/// Work deals light burn damage and spawns fire when employee takes burn damage
/mob/living/simple_animal/hostile/abnormality/wild_ashe/WorktickFailure(mob/living/carbon/human/user)
	user.deal_damage(work_damage_amount * 0.5, FIRE, src)
	WorkDamageEffect()
	// When employee takes burn damage during work, spawn fire
	if(prob(30))
		SpawnRandomFire()

/// On human death from burn damage, reduce qliphoth
/mob/living/simple_animal/hostile/abnormality/wild_ashe/proc/OnMobDeath(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(!(status_flags & GODMODE))
		return
	if(!ishuman(died) || died.z != z)
		return
	var/mob/living/carbon/human/H = died
	if(H.getFireLoss() > (H.maxHealth * 0.3))
		datum_reference.qliphoth_change(-1)
		SpawnRandomFire()

/// Spawn fire at a random location outside containment
/mob/living/simple_animal/hostile/abnormality/wild_ashe/proc/SpawnRandomFire()
	var/list/valid_turfs = list()
	for(var/turf/open/T in GLOB.department_centers)
		if(!locate(/obj/effect/turf_fire) in T)
			valid_turfs += T
	if(length(valid_turfs))
		var/turf/fire_turf = pick(valid_turfs)
		new /obj/effect/turf_fire(fire_turf)

/mob/living/simple_animal/hostile/abnormality/wild_ashe/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(!.)
		return
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "wildashe"
	icon_living = "wildashe"
	pixel_x = -16
	base_pixel_x = -16
	light_range = 15
	light_power = 10
	update_light()
	for(var/i in 1 to 5)
		SpawnRandomFire()

/mob/living/simple_animal/hostile/abnormality/wild_ashe/Life()
	. = ..()
	if(!. || (status_flags & GODMODE))
		return
	// Burn humans in hallways
	if(hall_burn_cooldown < world.time)
		BurnHallwayHumans()
		hall_burn_cooldown = world.time + 3 SECONDS

/// Burn humans who are outside containment zones
/mob/living/simple_animal/hostile/abnormality/wild_ashe/proc/BurnHallwayHumans()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.stat == DEAD || H.z != z)
			continue
		var/area/A = get_area(H)
		if(!A || istype(A, /area/containment_zone))
			continue
		H.deal_damage(10, FIRE, src)
		if(prob(20))
			to_chat(H, span_danger("The oppressive heat burns you!"))
			H.adjust_fire_stacks(1)
			H.IgniteMob()

/// Attacking burning targets deals 500 RED
/mob/living/simple_animal/hostile/abnormality/wild_ashe/AttackingTarget(atom/attacked_target)
	if(!ishuman(attacked_target))
		return ..()
	var/mob/living/carbon/human/H = attacked_target
	if(H.on_fire)
		visible_message(span_danger("[src] unleashes a devastating inferno upon the burning [H]!"))
		playsound(get_turf(H), 'sound/effects/explosion1.ogg', 75, TRUE)
		H.deal_damage(500, RED_DAMAGE, src)
		new /obj/effect/temp_visual/fire/fast(get_turf(H))
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/abnormality/wild_ashe/death(gibbed)
	density = FALSE
	light_range = 0
	light_power = 0
	update_light()
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	return ..()

/mob/living/simple_animal/hostile/abnormality/wild_ashe/update_icon_state()
	if(status_flags & GODMODE)
		light_range = 5
		light_power = 3
	else
		light_range = 15
		light_power = 10
	update_light()
