/mob/living/simple_animal/hostile/abnormality/gojo_fish
	name = "Gojo Fish"
	desc = "A strange fish-like creature that seems to radiate an overwhelming aura of confidence."
	icon = 'ModularTegustation/fishing/icons/fish_sprites.dmi'
	icon_state = "nah_swim"
	portrait = "gojo_fish"

	health = 8000
	maxHealth = 8000

	threat_level = ALEPH_LEVEL
	start_qliphoth = 3
	max_boxes = 30

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 30,
		ABNORMALITY_WORK_INSIGHT = 40,
		ABNORMALITY_WORK_ATTACHMENT = 20,
		ABNORMALITY_WORK_REPRESSION = 35,
	)
	work_damage_amount = 18
	work_damage_type = WHITE_DAMAGE

	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.3, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 0.8)

	can_breach = TRUE
	del_on_death = FALSE

	ego_list = list(
		/datum/ego_datum/weapon/gojo_fish,
		/datum/ego_datum/armor/gojo_fish,
	)

	abnormality_origin = ABNORMALITY_ORIGIN_JOKE

	// Combat stats for when breached
	move_to_delay = 3
	melee_damage_lower = 40
	melee_damage_upper = 60
	melee_damage_type = WHITE_DAMAGE
	attack_sound = 'sound/weapons/ego/justitia2.ogg'
	attack_verb_continuous = "slaps"
	attack_verb_simple = "slap"

	var/infinity_active = FALSE
	var/hollow_purple_cooldown = 0
	var/hollow_purple_cooldown_time = 30 SECONDS

/mob/living/simple_animal/hostile/abnormality/gojo_fish/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(40))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/gojo_fish/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	if(prob(30))
		to_chat(user, span_userdanger("The fish looks at you with disappointment. 'You're weak.'"))
		user.apply_damage(30, WHITE_DAMAGE, null, user.run_armor_check(null, WHITE_DAMAGE))
	return

/mob/living/simple_animal/hostile/abnormality/gojo_fish/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	infinity_active = TRUE
	addtimer(CALLBACK(src, PROC_REF(DisableInfinity)), 10 SECONDS)
	to_chat(user, span_userdanger("The fish emerges, floating through the air with an unsettling grace!"))
	return

/mob/living/simple_animal/hostile/abnormality/gojo_fish/proc/DisableInfinity()
	infinity_active = FALSE

/mob/living/simple_animal/hostile/abnormality/gojo_fish/AttackingTarget(atom/attacked_target)
	if(hollow_purple_cooldown < world.time && prob(25))
		HollowPurple(attacked_target)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/gojo_fish/proc/HollowPurple(atom/target)
	if(hollow_purple_cooldown > world.time)
		return
	hollow_purple_cooldown = world.time + hollow_purple_cooldown_time

	// Visual warning and announcement
	say("Hollow... Purple!")
	visible_message(span_userdanger("[src] begins gathering an immense amount of energy!"))
	playsound(src, 'sound/magic/lightning_chargeup.ogg', 100, TRUE, 8)

	// Create charging effect at source
	var/obj/effect/temp_visual/hollow_purple_charge/charge_effect = new(get_turf(src))

	// Calculate trajectory
	var/turf/target_turf = get_turf(target)
	face_atom(target)

	// Extend the range past the target
	for(var/i = 1 to 5)
		target_turf = get_step(target_turf, get_dir(get_turf(src), target_turf))

	// Charge time with visual buildup
	SLEEP_CHECK_DEATH(1.5 SECONDS)

	// Fire the beam
	playsound(src, 'sound/magic/lightningbolt.ogg', 125, TRUE, 10)
	playsound(src, 'sound/weapons/beam_sniper.ogg', 100, TRUE, 8)
	qdel(charge_effect)

	// Create the devastating beam path
	var/list/been_hit = list()
	var/turf/last_turf = get_turf(src)

	for(var/turf/T in getline(get_turf(src), target_turf))
		// Main beam visual
		var/obj/effect/temp_visual/hollow_purple_beam/beam = new(T)
		beam.dir = get_dir(last_turf, T)

		// Side effects - gravitational distortion
		for(var/turf/side_turf in range(1, T))
			if(side_turf == T)
				continue
			if(prob(50))
				new /obj/effect/temp_visual/gravpush(side_turf, get_dir(T, side_turf))

		// Pull in nearby objects and mobs
		for(var/atom/movable/AM in range(2, T))
			if(AM == src)
				continue
			if(!AM.anchored)
				step_towards(AM, T)
				if(get_dist(AM, T) <= 1 && isliving(AM))
					var/mob/living/L = AM
					if(!(L in been_hit))
						been_hit += L
						// Visual effect on hit
						new /obj/effect/temp_visual/kinetic_blast(get_turf(L))
						// Massive damage
						L.apply_damage(120, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE), spread_damage = TRUE)
						// Knockback
						var/throw_dir = get_dir(T, L)
						L.throw_at(get_edge_target_turf(L, throw_dir), 3, 2)

						// Gib if they're dead
						if(L.stat == DEAD && ishuman(L))
							var/mob/living/carbon/human/H = L
							new /obj/effect/temp_visual/human_horizontal_bisect(get_turf(H))
							H.gib()

		// Environmental destruction
		if(T.density)
			T.ScrapeAway()
		for(var/obj/O in T)
			if(O.density && !istype(O, /obj/structure/sign))
				if(prob(80))
					O.take_damage(500)

		// Floor scarring
		if(prob(70))
			new /obj/effect/decal/cleanable/blood/gibs/old(T)

		last_turf = T
		sleep(0.1)

	// Final explosion at the end point
	new /obj/effect/temp_visual/voidout(target_turf)
	playsound(target_turf, 'sound/effects/explosion1.ogg', 50, TRUE, 8)
	for(var/mob/living/L in range(2, target_turf))
		if(L == src)
			continue
		L.apply_damage(60, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE))

// Visual effect for charging
/obj/effect/temp_visual/hollow_purple_charge
	name = "gathering void energy"
	desc = "Reality seems to be tearing at this point."
	icon = 'icons/effects/effects.dmi'
	icon_state = "emfield_s3"
	layer = ABOVE_MOB_LAYER
	duration = 20

/obj/effect/temp_visual/hollow_purple_charge/Initialize()
	. = ..()
	animate(src, transform = matrix()*2, time = 10, loop = -1)
	animate(transform = matrix()*0.5, time = 10)

// Main beam visual
/obj/effect/temp_visual/hollow_purple_beam
	name = "void beam"
	icon = 'icons/effects/effects.dmi'
	icon_state = "lightning"
	layer = ABOVE_ALL_MOB_LAYER
	duration = 5
	color = "#8B00FF"

/obj/effect/temp_visual/hollow_purple_beam/Initialize()
	. = ..()
	transform = matrix()*2
	animate(src, alpha = 0, time = duration)

// Gravitational push visual
/obj/effect/temp_visual/gravpush
	name = "gravitational distortion"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-flash"
	layer = ABOVE_MOB_LAYER
	duration = 3
	color = "#4B0082"

/obj/effect/temp_visual/gravpush/Initialize(mapload, push_dir)
	. = ..()
	setDir(push_dir)
	animate(src, pixel_x = pixel_x + (16 * (push_dir & (EAST|WEST) ? push_dir == EAST ? 1 : -1 : 0)),
		pixel_y = pixel_y + (16 * (push_dir & (NORTH|SOUTH) ? push_dir == NORTH ? 1 : -1 : 0)),
		alpha = 0, time = duration)

// Void explosion effect
/obj/effect/temp_visual/voidout
	name = "void collapse"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "singularity_s5"
	layer = ABOVE_ALL_MOB_LAYER
	duration = 10
	pixel_x = -32
	pixel_y = -32

/obj/effect/temp_visual/voidout/Initialize()
	. = ..()
	transform = matrix()*0.5
	animate(src, transform = matrix()*1.5, alpha = 0, time = duration)

/mob/living/simple_animal/hostile/abnormality/gojo_fish/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(infinity_active && amount > 0)
		amount = amount * 0.1 // 90% damage reduction when infinity is active
		visible_message(span_warning("[src]'s infinity barrier reduces the damage!"))
	return ..()

// EGO Datum entries
/datum/ego_datum/weapon/gojo_fish
	item_path = /obj/item/ego_weapon/shield/gojo_fish
	cost = 100

/datum/ego_datum/armor/gojo_fish
	item_path = /obj/item/clothing/suit/armor/ego_gear/aleph/gojo_fish
	cost = 100
