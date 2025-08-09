/mob/living/simple_animal/hostile/abnormality/mustard
	name = "MUSTAAAAARD"
	desc = "An entity of pure condiment enthusiasm. Its presence alone makes everyone uncomfortably aware of their sandwich preferences."
	icon = 'ModularTegustation/Teguicons/64x64.dmi'
	icon_state = "mustard"
	icon_living = "mustard"
	portrait = "mustard"
	
	health = 2000
	maxHealth = 2000
	
	threat_level = WAW_LEVEL
	start_qliphoth = 2
	max_boxes = 24
	
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(30, 35, 40, 45, 50),
		ABNORMALITY_WORK_INSIGHT = list(40, 45, 50, 55, 60),
		ABNORMALITY_WORK_ATTACHMENT = list(20, 25, 30, 35, 40),
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 40, 45, 50),
	)
	work_damage_amount = 12
	work_damage_type = WHITE_DAMAGE
	
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.0)
	
	can_breach = TRUE
	del_on_death = FALSE
	
	ego_list = list(
		/datum/ego_datum/weapon/mustard,
		/datum/ego_datum/armor/mustard,
	)
	
	abnormality_origin = ABNORMALITY_ORIGIN_JOKE
	
	// Combat stats for when breached
	move_to_delay = 4
	melee_damage_lower = 35
	melee_damage_upper = 45
	melee_damage_type = WHITE_DAMAGE
	attack_sound = 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg'
	attack_verb_continuous = "slathers"
	attack_verb_simple = "slather"
	
	var/mustard_cooldown = 0
	var/mustard_cooldown_time = 20 SECONDS
	var/scream_cooldown = 0
	var/scream_cooldown_time = 8 SECONDS
	var/list/condiment_lines = list(
		"MUSTAAAAARD!",
		"YOU NEED MORE MUSTARD!",
		"INSUFFICIENT CONDIMENTS!",
		"MAYO IS INFERIOR!",
		"KETCHUP IS A LIE!",
		"EMBRACE THE YELLOW!"
	)

/mob/living/simple_animal/hostile/abnormality/mustard/Initialize()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(OnMobDeath))

/mob/living/simple_animal/hostile/abnormality/mustard/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	return ..()

/mob/living/simple_animal/hostile/abnormality/mustard/proc/OnMobDeath(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(!IsContained() || QDELETED(died) || !ishuman(died))
		return
	if(get_dist(died, src) > 7)
		return
	// Someone died near MUSTAAAAARD while contained - it gets excited
	if(prob(50))
		datum_reference.qliphoth_change(-1)
		// Can't use say() in signal handler, so we'll just make a visual effect
		visible_message(span_danger("[src] seems excited by the death!"))

/mob/living/simple_animal/hostile/abnormality/mustard/WorkChance(mob/living/carbon/human/user, chance)
	// Mustard prefers employees with high temperance (they understand condiment restraint)
	var/temperance_mod = get_attribute_level(user, TEMPERANCE_ATTRIBUTE)
	chance += temperance_mod * 2
	return chance

/mob/living/simple_animal/hostile/abnormality/mustard/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	// Success makes mustard happy
	say(pick("Acceptable mustard levels.", "You understand the condiment.", "Good. Gooood."))
	user.adjust_nutrition(50) // Mustard feeds you
	
/mob/living/simple_animal/hostile/abnormality/mustard/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(40))
		datum_reference.qliphoth_change(-1)
		MustardScream(user)
	
/mob/living/simple_animal/hostile/abnormality/mustard/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	MustardScream(user)
	// Cover them in mustard
	user.color = "#FFDB58"
	addtimer(CALLBACK(user, TYPE_PROC_REF(/atom, update_atom_colour)), 30 SECONDS)
	to_chat(user, span_warning("You are covered in mustard!"))
	user.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10) // The mustard is overwhelming

/mob/living/simple_animal/hostile/abnormality/mustard/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	visible_message(span_danger("[src] breaches with incredible condiment energy!"))
	playsound(src, 'sound/weapons/ego/mustard.ogg', 100, FALSE, 40, falloff_distance = 20)
	addtimer(CALLBACK(src, PROC_REF(MustardAnnouncement)), 2 SECONDS)

/mob/living/simple_animal/hostile/abnormality/mustard/proc/MustardAnnouncement()
	for(var/mob/M in GLOB.player_list)
		if(M.z != z)
			continue
		to_chat(M, span_userdanger("MUSTAAAAAAAAARD!"))
		M.playsound_local(get_turf(M), 'sound/weapons/ego/mustard.ogg', 75, FALSE)
		flash_color(M, flash_color = "#FFDB58", flash_time = 10)

/mob/living/simple_animal/hostile/abnormality/mustard/proc/MustardScream(mob/living/target = null)
	if(scream_cooldown > world.time)
		return
	scream_cooldown = world.time + scream_cooldown_time
	
	var/chosen_line = pick(condiment_lines)
	say(chosen_line)
	if(chosen_line == "MUSTAAAAARD!") // Only play the sound when it actually says MUSTARD
		playsound(src, 'sound/weapons/ego/mustard.ogg', 75, FALSE, 7)
	else
		playsound(src, 'sound/machines/buzz-sigh.ogg', 75, FALSE, 7)
	
	// Create visual mustard wave
	for(var/turf/T in view(3, src))
		if(prob(30))
			new /obj/effect/temp_visual/mustard_splash(T)
	
	// Sanity damage to nearby people
	for(var/mob/living/carbon/human/H in view(5, src))
		if(faction_check_mob(H))
			continue
		H.adjustSanityLoss(10)
		to_chat(H, span_warning("The intensity of [src]'s mustard obsession hurts your mind!"))

/mob/living/simple_animal/hostile/abnormality/mustard/AttackingTarget(atom/attacked_target)
	if(mustard_cooldown < world.time && prob(30))
		MustardBlast(attacked_target)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/mustard/proc/MustardBlast(atom/target)
	if(mustard_cooldown > world.time)
		return
	mustard_cooldown = world.time + mustard_cooldown_time
	
	say("MUSTARD BLAST!")
	playsound(src, 'sound/effects/splat.ogg', 75, TRUE)
	
	// Create a cone of mustard
	var/turf/target_turf = get_turf(target)
	face_atom(target)
	
	for(var/i = 1 to 3)
		for(var/turf/T in getline(get_turf(src), target_turf))
			new /obj/effect/temp_visual/mustard_projectile(T)
			for(var/mob/living/L in T)
				if(L == src)
					continue
				L.apply_damage(30, WHITE_DAMAGE, null, L.run_armor_check(null, WHITE_DAMAGE))
				L.color = "#FFDB58" // Cover them in mustard
				addtimer(CALLBACK(L, TYPE_PROC_REF(/atom, update_atom_colour)), 20 SECONDS)
				to_chat(L, span_warning("You're covered in aggressive mustard!"))
		target_turf = get_step(target_turf, get_dir(get_turf(src), target_turf))

/mob/living/simple_animal/hostile/abnormality/mustard/Life()
	. = ..()
	if(!IsContained() && prob(5))
		MustardScream()

// Visual effects
/obj/effect/temp_visual/mustard_splash
	name = "mustard splash"
	icon = 'icons/effects/effects.dmi'
	icon_state = "yellow_sparkles"
	duration = 10
	color = "#FFDB58"

/obj/effect/temp_visual/mustard_splash/Initialize()
	. = ..()
	animate(src, alpha = 0, time = duration)

/obj/effect/temp_visual/mustard_projectile
	name = "mustard stream"
	icon = 'icons/effects/effects.dmi'
	icon_state = "water"
	duration = 5
	color = "#FFDB58"

/obj/effect/temp_visual/mustard_projectile/Initialize()
	. = ..()
	transform = matrix() * 2
	animate(src, alpha = 0, transform = matrix() * 0.5, time = duration)

// EGO Datums
/datum/ego_datum/weapon/mustard
	item_path = /obj/item/ego_weapon/mustard
	cost = 50

/datum/ego_datum/armor/mustard
	item_path = /obj/item/clothing/suit/armor/ego_gear/waw/mustard
	cost = 50