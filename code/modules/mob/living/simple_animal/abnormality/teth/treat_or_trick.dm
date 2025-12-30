// Treat or Trick - O-02-1031
// TETH-class abnormality - Two-form ghost
// Part of the Holiday abnormality set

/mob/living/simple_animal/hostile/abnormality/treat_or_trick
	name = "Treat or Trick"
	desc = "A spectral figure draped in tattered robes. Its hollow eyes seem to peer into your soul."
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "treat"
	icon_living = "treat"
	icon_dead = "treat_dead"
	portrait = "treat_or_trick"
	pixel_x = -16
	base_pixel_x = -16

	maxHealth = 800
	health = 800
	threat_level = TETH_LEVEL
	start_qliphoth = 5
	max_boxes = 12
	// Treat form resistances: RED Normal, WHITE Weak, BLACK Endured, PALE Absorbed
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = -1)

	melee_damage_type = PALE_DAMAGE
	melee_damage_lower = 0
	melee_damage_upper = 0  // No damage as Treat
	attack_verb_continuous = "reaches through"
	attack_verb_simple = "reach through"
	attack_sound = 'sound/hallucinations/veryfar_noise.ogg'

	work_damage_type = PALE_DAMAGE
	work_damage_amount = 4
	can_breach = TRUE
	faction = list("neutral")  // Passive as Treat
	move_to_delay = 5

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(60, 65, 70, 75, 80),
		ABNORMALITY_WORK_INSIGHT = list(45, 50, 55, 55, 60),
		ABNORMALITY_WORK_ATTACHMENT = list(45, 50, 55, 55, 60),
		ABNORMALITY_WORK_REPRESSION = list(20, 20, 25, 25, 30),
	)

	ego_list = list(
		// Add EGO datums when created
	)
	gift_type = null // Add gift when created
	abnormality_origin = ABNORMALITY_ORIGIN_ARTBOOK
	chem_type = /datum/reagent/abnormality/sin/sloth

	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/wild_ashe = 1.5,
		/mob/living/simple_animal/hostile/abnormality/eve_of_winter = 1.5,
		/mob/living/simple_animal/hostile/abnormality/coupid = 1.5,
	)

	observation_prompt = "The ghost drifts before you, holding out a bag. \
		'Treat or Trick?' it asks in a hollow whisper. \
		You..."
	observation_choices = list(
		"Reach into the bag" = list(TRUE, "Your hand passes through something cold. When you pull it back, you hold a small candy. The ghost seems pleased."),
		"Run away" = list(FALSE, "The ghost's form shifts, becoming twisted and angry. 'Then it shall be a trick...'"),
	)

	/// Are we in Trick form?
	var/is_trick = FALSE
	/// List of humans who have attacked us recently (for swarm detection)
	var/list/recent_attackers = list()
	/// Cooldown for AoE slam
	var/aoe_cooldown = 0
	var/aoe_cooldown_time = 5 SECONDS
	/// How many attackers triggers AoE
	var/swarm_threshold = 3
	/// List of soul mobs we've created
	var/list/spawned_souls = list()

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/Initialize(mapload)
	. = ..()
	// Register for work on other abnormalities
	RegisterSignal(SSdcs, COMSIG_GLOB_WORK_STARTED, PROC_REF(OnAbnoWork))

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_WORK_STARTED)
	recent_attackers.Cut()
	for(var/mob/living/simple_animal/hostile/soul_mob/S in spawned_souls)
		if(!QDELETED(S))
			S.RestoreHuman()
	spawned_souls.Cut()
	return ..()

/// When work is done on other abnormalities, chance to reduce qliphoth
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/OnAbnoWork(datum/source, datum/abnormality/abno_datum, mob/user, work_type)
	SIGNAL_HANDLER
	if(!(status_flags & GODMODE)) // If breaching, ignore
		return FALSE
	if(abno_datum == datum_reference) // They worked on us
		return FALSE
	// 20% for ZAYIN, 15% for TETH, 10% for HE, 5% for WAW, 0% for ALEPH
	if(prob(20 - (abno_datum.threat_level * 5)))
		datum_reference.qliphoth_change(-1)
	return TRUE

/// Instinct work has 50/50 chance to change qliphoth by +3 or -3
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	. = ..()
	if(work_type == ABNORMALITY_WORK_INSTINCT)
		if(prob(50))
			datum_reference.qliphoth_change(3)
			to_chat(user, span_nicegreen("[src] seems pleased with your offering. The air feels lighter."))
		else
			datum_reference.qliphoth_change(-3)
			to_chat(user, span_danger("[src] seems displeased. The air grows heavy with malice."))

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(!.)
		return
	// Turn 5 employees into Soul Mobs
	var/list/potential_victims = list()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.stat == DEAD)
			continue
		if(H.z != z)
			continue
		potential_victims += H
	// Pick up to 5 random humans
	var/victims_count = min(5, length(potential_victims))
	for(var/i in 1 to victims_count)
		if(!length(potential_victims))
			break
		var/mob/living/carbon/human/victim = pick_n_take(potential_victims)
		ConvertToSoul(victim)

/// Convert a human into a Soul Mob
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/ConvertToSoul(mob/living/carbon/human/H)
	if(!H || H.stat == DEAD)
		return
	to_chat(H, span_userdanger("Your soul is being pulled from your body!"))
	var/mob/living/simple_animal/hostile/soul_mob/S = new(get_turf(H))
	S.SetupSoul(H, src)
	spawned_souls += S
	RegisterSignal(S, COMSIG_PARENT_QDELETING, PROC_REF(OnSoulDestroyed))

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/OnSoulDestroyed(mob/living/simple_animal/hostile/soul_mob/S)
	SIGNAL_HANDLER
	UnregisterSignal(S, COMSIG_PARENT_QDELETING)
	spawned_souls -= S

/// Transform from Treat to Trick when attacked
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/TransformToTrick()
	if(is_trick)
		return
	is_trick = TRUE
	visible_message(span_danger("[src]'s form twists and warps into something malevolent!"))
	playsound(get_turf(src), 'sound/hallucinations/wail.ogg', 75, TRUE)
	// Update stats to Trick form
	name = "Trick"
	icon_state = "trick"
	icon_living = "trick"
	// Trick resistances: RED Resisted, WHITE Normal, BLACK Resisted, PALE Absorbed
	damage_coeff = list(RED_DAMAGE = 0.4, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.4, PALE_DAMAGE = -1)
	melee_damage_lower = 30
	melee_damage_upper = 50
	faction = list("hostile")
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/bladeslice.ogg'

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(!(status_flags & GODMODE))
		TrackAttacker(user)
		if(!is_trick)
			TransformToTrick()
			GiveTarget(user)

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	. = ..()
	if(!(status_flags & GODMODE) && Proj.firer)
		TrackAttacker(Proj.firer)
		if(!is_trick)
			TransformToTrick()
			if(ishuman(Proj.firer))
				GiveTarget(Proj.firer)

/// Track attackers for swarm detection
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/TrackAttacker(mob/attacker)
	if(!ishuman(attacker))
		return
	if(!(attacker in recent_attackers))
		recent_attackers += attacker
		// Remove attacker from list after 10 seconds
		addtimer(CALLBACK(src, PROC_REF(RemoveAttacker), attacker), 10 SECONDS)
	// Check for swarm
	if(length(recent_attackers) >= swarm_threshold && aoe_cooldown < world.time)
		AoESlam()

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/RemoveAttacker(mob/attacker)
	recent_attackers -= attacker

/// AoE slam attack when swarmed
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/AoESlam()
	if(!is_trick)
		return
	aoe_cooldown = world.time + aoe_cooldown_time
	visible_message(span_danger("[src] raises its talons and slams them down in a fury!"))
	playsound(get_turf(src), 'sound/effects/meteorimpact.ogg', 75, TRUE)
	// Hit everyone in range
	var/slam_range = 3
	var/slam_damage = 40
	for(var/turf/T in view(slam_range, src))
		new /obj/effect/temp_visual/smash_effect(T)
	for(var/mob/living/carbon/human/H in view(slam_range, src))
		H.deal_damage(slam_damage, PALE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		visible_message(span_danger("[src]'s talons rake across [H]!"))

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/Life()
	. = ..()
	if(!.)
		return FALSE
	if(status_flags & GODMODE)
		return FALSE
	// Randomly trigger AoE slam at inconsistent pace when in Trick form with multiple attackers
	if(is_trick && length(recent_attackers) >= swarm_threshold && prob(10) && aoe_cooldown < world.time)
		AoESlam()

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/update_icon_state()
	if(status_flags & GODMODE)
		// Contained
		is_trick = FALSE
		name = initial(name)
		icon_state = initial(icon_state)
		icon_living = initial(icon_living)
		damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = -1)
		melee_damage_lower = 0
		melee_damage_upper = 0
		faction = list("neutral")
	else if(is_trick)
		icon_state = "trick"
		icon_living = "trick"
	else
		icon_state = "treat"
		icon_living = "treat"

// ==================== SOUL MOB ====================

/mob/living/simple_animal/hostile/soul_mob
	name = "Soul"
	real_name = "Soul"
	desc = "A spectral form, a soul separated from its body. It seems confused and hostile."
	icon = 'icons/mob/guardian.dmi'
	icon_state = "magicbase"
	icon_living = "magicbase"
	icon_dead = "magicbase"
	gender = NEUTER
	mob_biotypes = NONE
	maxHealth = 300
	health = 300
	melee_damage_lower = 15
	melee_damage_upper = 25
	melee_damage_type = PALE_DAMAGE
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	attack_sound = 'sound/hallucinations/veryfar_noise.ogg'
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2)
	faction = list("neutral")
	move_to_delay = 4
	is_flying_animal = TRUE
	del_on_death = FALSE
	light_system = MOVABLE_LIGHT
	light_range = 2
	light_color = COLOR_WHITE
	/// The human whose soul this is
	var/mob/living/carbon/human/original_human
	/// Reference to Treat or Trick
	var/mob/living/simple_animal/hostile/abnormality/treat_or_trick/connected_abno
	/// Duration before restoring
	var/soul_duration = 120 SECONDS
	/// Timer ID for restoration
	var/restore_timer_id

/mob/living/simple_animal/hostile/soul_mob/Initialize(mapload)
	. = ..()
	// Add the guardian overlay
	var/mutable_appearance/overlay = mutable_appearance(icon, "magic")
	add_overlay(overlay)

/mob/living/simple_animal/hostile/soul_mob/Destroy()
	if(restore_timer_id)
		deltimer(restore_timer_id)
	if(original_human && !QDELETED(original_human))
		// Release human from storage
		original_human.forceMove(get_turf(src))
		REMOVE_TRAIT(original_human, TRAIT_RESTRAINED, src)
	original_human = null
	connected_abno = null
	return ..()

/// Set up the soul mob with a human victim
/mob/living/simple_animal/hostile/soul_mob/proc/SetupSoul(mob/living/carbon/human/H, mob/living/simple_animal/hostile/abnormality/treat_or_trick/abno)
	if(!H)
		return
	original_human = H
	connected_abno = abno
	// Set name based on original human
	name = "[H.real_name]'s Soul"
	real_name = name
	// Color based on eye color
	var/soul_color = "#[H.eye_color]"
	add_atom_colour(soul_color, FIXED_COLOUR_PRIORITY)
	light_color = soul_color
	// Transfer mind to soul mob
	if(H.mind)
		H.mind.transfer_to(src)
	// Store original human inside
	H.forceMove(src)
	ADD_TRAIT(H, TRAIT_RESTRAINED, src)
	to_chat(src, span_userdanger("You have become a Soul! Your body is trapped while your spirit roams free!"))
	to_chat(src, span_warning("All damage you deal is now Pale damage. You will return to your body in 2 minutes."))
	visible_message(span_danger("[H]'s soul is ripped from their body!"))
	// Start timer to restore
	restore_timer_id = addtimer(CALLBACK(src, PROC_REF(RestoreHuman)), soul_duration, TIMER_STOPPABLE)

/// Restore the human to their body - fully healed for surviving
/mob/living/simple_animal/hostile/soul_mob/proc/RestoreHuman()
	if(!original_human || QDELETED(original_human))
		qdel(src)
		return
	visible_message(span_notice("[src] fades away as the soul returns to its body..."))
	// Move human out
	original_human.forceMove(get_turf(src))
	REMOVE_TRAIT(original_human, TRAIT_RESTRAINED, src)
	// Transfer mind back
	if(mind)
		mind.transfer_to(original_human)
	// Fully heal the human for surviving
	original_human.fully_heal()
	to_chat(original_human, span_nicegreen("Your soul returns to your body, and you feel completely restored!"))
	original_human = null
	qdel(src)

/mob/living/simple_animal/hostile/soul_mob/death(gibbed)
	. = ..()
	// On death, release human and kill them too
	if(original_human && !QDELETED(original_human))
		original_human.forceMove(get_turf(src))
		REMOVE_TRAIT(original_human, TRAIT_RESTRAINED, src)
		if(mind)
			mind.transfer_to(original_human)
		to_chat(original_human, span_userdanger("Your soul is destroyed! Your body cannot survive without it!"))
		original_human.death()
		original_human = null
	qdel(src)

/mob/living/simple_animal/hostile/soul_mob/examine(mob/user)
	. = ..()
	if(original_human)
		. += span_notice("This is the soul of [original_human.real_name].")
	. += span_warning("It seems to be in torment, separated from its body.")
