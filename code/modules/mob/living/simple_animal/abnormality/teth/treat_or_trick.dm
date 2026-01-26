// Treat or Trick - O-02-1031
// TETH-class abnormality - Two-form ghost
// Part of the Holiday abnormality set

/mob/living/simple_animal/hostile/abnormality/treat_or_trick
	name = "Treat or Trick"
	desc = "A spectral figure draped in tattered robes. Its hollow eyes seem to peer into your soul."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "treat_contained"
	icon_living = "treat_contained"
	icon_dead = "treat_dead"
	portrait = "treat_or_trick"

	maxHealth = 800
	health = 800
	threat_level = TETH_LEVEL
	start_qliphoth = 5
	max_boxes = 12
	// Treat form resistances: RED Normal, WHITE Weak, BLACK Endured, PALE Absorbed
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = -1)

	melee_damage_type = PALE_DAMAGE
	melee_damage_lower = 0
	melee_damage_upper = 0
	attack_verb_continuous = "reaches through"
	attack_verb_simple = "reach through"
	attack_sound = 'sound/hallucinations/veryfar_noise.ogg'

	work_damage_type = PALE_DAMAGE
	work_damage_amount = 4
	can_breach = TRUE
	faction = list("neutral", "hostile")
	move_to_delay = 5

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(60, 65, 70, 75, 80),
		ABNORMALITY_WORK_INSIGHT = list(45, 50, 55, 55, 60),
		ABNORMALITY_WORK_ATTACHMENT = list(45, 50, 55, 55, 60),
		ABNORMALITY_WORK_REPRESSION = list(20, 20, 25, 25, 30),
	)

	ego_list = list(
		/datum/ego_datum/weapon/hallowed,
		/datum/ego_datum/armor/hallowed,
	)
	gift_type = null
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
	/// List of humans who have attacked us recently
	var/list/recent_attackers = list()
	/// Cooldown for AoE slam
	var/aoe_cooldown = 0
	/// How many attackers triggers AoE
	var/swarm_threshold = 3
	/// List of soul mobs we've created
	var/list/spawned_souls = list()
	/// Timer for qliphoth decay
	var/qliphoth_decay_timer

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/PostSpawn()
	. = ..()
	StartQliphothDecay()

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/Destroy()
	if(qliphoth_decay_timer)
		deltimer(qliphoth_decay_timer)
	recent_attackers.Cut()
	for(var/mob/living/simple_animal/hostile/soul_mob/S in spawned_souls)
		if(!QDELETED(S))
			S.RestoreHuman()
	spawned_souls.Cut()
	return ..()

/// Start the 2-minute qliphoth decay timer
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/StartQliphothDecay()
	if(qliphoth_decay_timer)
		deltimer(qliphoth_decay_timer)
	qliphoth_decay_timer = addtimer(CALLBACK(src, PROC_REF(QliphothDecayTick)), 2 MINUTES, TIMER_STOPPABLE | TIMER_LOOP)

/// Every 2 minutes, reduce qliphoth by 1
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/QliphothDecayTick()
	if(!(status_flags & GODMODE))
		return // Don't decay while breached
	datum_reference?.qliphoth_change(-1)

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
	update_icon_state()
	// Turn up to 5 employees into Soul Mobs
	var/list/potential_victims = list()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.stat != DEAD && H.z == z)
			potential_victims += H
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
	update_icon_state()
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
		addtimer(CALLBACK(src, PROC_REF(RemoveAttacker), attacker), 10 SECONDS)
	if(length(recent_attackers) >= swarm_threshold && aoe_cooldown < world.time)
		AoESlam()

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/RemoveAttacker(mob/attacker)
	recent_attackers -= attacker

/// AoE slam attack when swarmed
/mob/living/simple_animal/hostile/abnormality/treat_or_trick/proc/AoESlam()
	if(!is_trick)
		return
	aoe_cooldown = world.time + 5 SECONDS
	visible_message(span_danger("[src] raises its talons and slams them down in a fury!"))
	playsound(get_turf(src), 'sound/effects/meteorimpact.ogg', 75, TRUE)
	for(var/mob/living/carbon/human/H in view(3, src))
		H.deal_damage(40, PALE_DAMAGE, src)
		visible_message(span_danger("[src]'s talons rake across [H]!"))

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/Life()
	. = ..()
	if(!. || (status_flags & GODMODE))
		return
	// Random AoE slam when swarmed
	if(is_trick && length(recent_attackers) >= swarm_threshold && prob(10) && aoe_cooldown < world.time)
		AoESlam()

/mob/living/simple_animal/hostile/abnormality/treat_or_trick/update_icon_state()
	if(status_flags & GODMODE)
		is_trick = FALSE
		name = initial(name)
		icon = initial(icon)
		icon_state = initial(icon_state)
		icon_living = initial(icon_living)
		pixel_x = initial(pixel_x)
		base_pixel_x = initial(base_pixel_x)
		damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = -1)
		melee_damage_lower = 0
		melee_damage_upper = 0
		faction = list("neutral", "hostile")
		StartQliphothDecay()
	else if(is_trick)
		icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
		icon_state = "trick"
		icon_living = "trick"
		pixel_x = -16
		base_pixel_x = -16
	else
		icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
		icon_state = "treat"
		icon_living = "treat"

// ==================== SOUL MOB ====================

/mob/living/simple_animal/hostile/soul_mob
	name = "Soul"
	desc = "A spectral form, a soul separated from its body."
	icon = 'icons/mob/guardian.dmi'
	icon_state = "magicbase"
	icon_living = "magicbase"
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
	/// Timer ID for restoration
	var/restore_timer_id

/mob/living/simple_animal/hostile/soul_mob/Initialize(mapload)
	. = ..()
	var/mutable_appearance/overlay = mutable_appearance(icon, "magic")
	add_overlay(overlay)

/mob/living/simple_animal/hostile/soul_mob/Destroy()
	if(restore_timer_id)
		deltimer(restore_timer_id)
	if(original_human && !QDELETED(original_human))
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
	name = "[H.real_name]'s Soul"
	var/soul_color = "#[H.eye_color]"
	add_atom_colour(soul_color, FIXED_COLOUR_PRIORITY)
	light_color = soul_color
	if(H.mind)
		H.mind.transfer_to(src)
	H.forceMove(src)
	ADD_TRAIT(H, TRAIT_RESTRAINED, src)
	to_chat(src, span_userdanger("You have become a Soul! Your body is trapped while your spirit roams free!"))
	to_chat(src, span_warning("All damage you deal is now Pale damage. You will return to your body in 2 minutes."))
	visible_message(span_danger("[H]'s soul is ripped from their body!"))
	restore_timer_id = addtimer(CALLBACK(src, PROC_REF(RestoreHuman)), 2 MINUTES, TIMER_STOPPABLE)

/// Restore the human to their body - fully healed for surviving
/mob/living/simple_animal/hostile/soul_mob/proc/RestoreHuman()
	if(!original_human || QDELETED(original_human))
		qdel(src)
		return
	visible_message(span_notice("[src] fades away as the soul returns to its body..."))
	original_human.forceMove(get_turf(src))
	REMOVE_TRAIT(original_human, TRAIT_RESTRAINED, src)
	if(mind)
		mind.transfer_to(original_human)
	original_human.fully_heal()
	to_chat(original_human, span_nicegreen("Your soul returns to your body, and you feel completely restored!"))
	original_human = null
	qdel(src)

/mob/living/simple_animal/hostile/soul_mob/death(gibbed)
	. = ..()
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
