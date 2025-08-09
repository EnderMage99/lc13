/mob/living/simple_animal/hostile/abnormality/eternal_prospector
	name = "Eternal Prospector"
	desc = "A weathered figure in tattered prospecting gear, forever clutching ancient mining tools. Their eyes gleam with an insatiable greed that transcends death itself."
	icon = 'ModularTegustation/Teguicons/32x32.dmi'
	icon_state = "680_ham_actor"
	icon_living = "680_ham_actor"
	portrait = "eternal_prospector"
	maxHealth = 1000
	health = 1000
	threat_level = TETH_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 10,
		ABNORMALITY_WORK_INSIGHT = 45,
		ABNORMALITY_WORK_ATTACHMENT = 30,
		ABNORMALITY_WORK_REPRESSION = 20,
	)
	work_damage_amount = 6
	work_damage_type = RED_DAMAGE

	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	can_breach = TRUE
	start_qliphoth = 2
	chem_type = /datum/reagent/abnormality/sin/envy

	melee_damage_lower = 8
	melee_damage_upper = 12
	melee_damage_type = RED_DAMAGE
	stat_attack = HARD_CRIT
	move_to_delay = 4
	attack_same = TRUE

	ego_list = list(
		/datum/ego_datum/weapon/greed,
		/datum/ego_datum/armor/greed,
	)
	gift_type = /datum/ego_gifts/greed
	abnormality_origin = ABNORMALITY_ORIGIN_LOBOTOMY
	attack_sound = 'sound/weapons/ego/gasharpoon_hit.ogg'
	attack_verb_continuous = "slices"
	attack_verb_simple = "slice"
	friendly_verb_continuous = "bonks"
	friendly_verb_simple = "bonk"

	var/bribe_bonus = 0
	var/bribe_damage_increase = 0
	var/base_work_damage = 6
	var/can_parry = TRUE
	var/parrying = FALSE
	var/parry_chance = 20
	var/parry_duration = 1.5 SECONDS
	var/parry_cooldown = 10 SECONDS
	var/aoe_damage = 20
	var/devastation_stacks = 5
	var/teleported_on_breach = FALSE
	var/list/speak_lines = list(
		"Break, Seek, Loss... These three words are all I hear while I seek...",
		"I worked years and years for that dastardly queen... There must be an end to this all.",
		"Wait, what was that? Treasure? At long last? No... another delusion...",
		"I just need to break it all...",
		"Where is it... I sold my body and fought like a rabid beast in that war... TO EARN THIS!?",
		"After all, I need to seek it more...",
		"Is this another ploy by the queen to stop me from reaching the long-promised treasure?",
		"I just need to reach this one treasure, then I can finally rest from my tireless journey...",
		"Now, I shall not lose it all..."
	)
	var/list/queen_taunt_lines = list(
		"YOU! You're one of her agents! WHERE IS MY TREASURE!?",
		"Another queen's puppet! You won't stop me from finding what's mine!",
		"The queen sends her minions to mock me even here!?",
		"I'll tear through you just like I did her armies! WHERE IS IT!?",
		"No more lies! No more false promises! GIVE ME WHAT I'M OWED!"
	)
	var/queen_target_cooldown = 0

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/Life()
	. = ..()
	if(!.)
		return
	if(!IsContained())
		if(prob(1))
			say(pick(speak_lines))
		// Check for queen-related abnormalities
		if(world.time > queen_target_cooldown)
			CheckForQueens()

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/ListTargets()
	. = ..()
	// If there are any queen-related abnormalities in the list, prioritize them
	for(var/mob/living/L in .)
		if(IsQueenRelated(L))
			// Move queen to front of list for priority targeting
			. -= L
			. = list(L) + .

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/attackby(obj/item/I, mob/living/carbon/human/user, params)
	if(istype(I, /obj/item/holochip))
		if(IsContained())
			var/obj/item/holochip/H = I
			var/credits_taken = H.credits
			bribe_bonus += credits_taken / 10
			bribe_damage_increase += 2
			work_damage_amount = base_work_damage + bribe_damage_increase
			to_chat(user, "<span class='notice'>[src] greedily snatches the holochip, temporarily improving work chances!</span>")
			qdel(H)
			return
	return ..()

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/AttemptWork(mob/living/carbon/human/user, work_type)
	if(bribe_bonus > 0)
		var/old_chance = work_chances[work_type]
		if(islist(old_chance))
			var/list/chance_list = old_chance
			for(var/i in 1 to length(chance_list))
				chance_list[i] = min(chance_list[i] + bribe_bonus, 100)
			work_chances[work_type] = chance_list
		else
			work_chances[work_type] = min(old_chance + bribe_bonus, 100)

	return ..()

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/PostWorkEffect(mob/living/carbon/human/user, work_type, pe)
	if(bribe_bonus > 0)
		bribe_bonus = 0
		work_chances = initial(work_chances)
		to_chat(user, "<span class='notice'>The bribe's effect on work chances has worn off.</span>")
	return

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(25))
		datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	if(bribe_damage_increase > 0)
		work_damage_amount = base_work_damage
		bribe_damage_increase = 0
		to_chat(user, "<span class='notice'>The increased work damage has returned to normal.</span>")
	return

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(!teleported_on_breach)
		teleported_on_breach = TRUE
		var/list/teleport_turfs = list()
		for(var/turf/T in GLOB.xeno_spawn)
			if(istype(get_area(T), /area/department_main/command) || istype(get_area(T), /area/department_main/control))
				continue
			teleport_turfs += T

		if(LAZYLEN(teleport_turfs))
			var/turf/target = pick(teleport_turfs)
			forceMove(target)
			new /obj/effect/temp_visual/guardian/phase(target)

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/AttackingTarget(atom/attacked_target)
	if(isliving(attacked_target))
		var/mob/living/L = attacked_target
		L.apply_status_effect(/datum/status_effect/ruin)

	return ..()

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(can_parry && !parrying && prob(parry_chance))
		ParryMode()

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/bullet_act(obj/projectile/P)
	. = ..()
	if(can_parry && !parrying && prob(parry_chance))
		ParryMode()

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/proc/ParryMode()
	if(!can_parry || parrying)
		return

	parrying = TRUE
	can_parry = FALSE
	// icon_state = "[initial(icon_state)]_parry"
	playsound(src, 'sound/weapons/ego/gasharpoon_queeblock.ogg', 75, TRUE)
	visible_message("<span class='danger'>[src] enters a defensive stance!</span>")

	addtimer(CALLBACK(src, PROC_REF(EndParry)), parry_duration)

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/proc/EndParry()
	parrying = FALSE
	icon_state = initial(icon_state)
	addtimer(CALLBACK(src, PROC_REF(ResetParry)), parry_cooldown)

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/proc/ResetParry()
	can_parry = TRUE

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(parrying && amount > 0)
		CounterAttack()
		return 0
	return ..()

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/proc/CounterAttack()
	visible_message("<span class='userdanger'>[src] unleashes a devastating counter-attack!</span>")
	playsound(src, 'sound/weapons/fixer/hana_slash.ogg', 100, TRUE)

	for(var/turf/T in range(2, src))
		new /obj/effect/temp_visual/explosion(T)
		for(var/mob/living/L in T)
			if(L == src)
				continue
			L.apply_damage(aoe_damage, BLACK_DAMAGE, null, L.run_armor_check(null, BLACK_DAMAGE))
			L.apply_status_effect(/datum/status_effect/devastation, devastation_stacks)

	EndParry()

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/proc/CheckForQueens()
	// Check if we already have a queen target
	if(target && IsQueenRelated(target))
		return

	// Look for queen-related abnormalities in view
	for(var/mob/living/simple_animal/hostile/abnormality/A in view(vision_range, src))
		if(A == src)
			continue
		if(IsQueenRelated(A))
			// Found a queen! Target them immediately with specific dialogue
			var/taunt_line = GetQueenTaunt(A)
			say(taunt_line)
			visible_message("<span class='danger'>[src] flies into a rage upon seeing [A]!</span>")
			GiveTarget(A)
			queen_target_cooldown = world.time + 100 // 10 second cooldown before checking again
			return

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/proc/IsQueenRelated(mob/living/target)
	if(!istype(target, /mob/living/simple_animal/hostile/abnormality))
		return FALSE

	// Check if it's one of the queen abnormalities
	if(istype(target, /mob/living/simple_animal/hostile/abnormality/ebony_queen))
		return TRUE
	if(istype(target, /mob/living/simple_animal/hostile/abnormality/snow_whites_apple))
		return TRUE
	if(istype(target, /mob/living/simple_animal/hostile/abnormality/general_b))
		return TRUE
	if(istype(target, /mob/living/simple_animal/hostile/abnormality/titania))
		return TRUE
	if(istype(target, /mob/living/simple_animal/hostile/abnormality/snow_queen))
		return TRUE
	if(istype(target, /mob/living/simple_animal/hostile/abnormality/greed_king))
		return TRUE

	return FALSE

/mob/living/simple_animal/hostile/abnormality/eternal_prospector/proc/GetQueenTaunt(mob/living/simple_animal/hostile/abnormality/target)
	// Return specific taunts for each queen abnormality
	if(istype(target, /mob/living/simple_animal/hostile/abnormality/ebony_queen))
		return pick(\
			"EBONY QUEEN! Just like HER - all beauty and lies! WHERE IS MY PAYMENT!?",\
			"Another queen of darkness! You all promised riches but gave only death!",\
			"Your ebony crown wont protect you! Ive slain queens before!"\
			)

	if(istype(target, /mob/living/simple_animal/hostile/abnormality/snow_whites_apple))
		return pick(\
			"Poisoned apples, poisoned promises! You queens are all the same!",\
			"Snow Whites legacy of lies! The treasure was supposed to be MINE!",\
			"False gifts from false royalty! Ill take what Im owed!"\
			)

	if(istype(target, /mob/living/simple_animal/hostile/abnormality/general_b))
		return pick(\
			"The Queen Bee! Another monarch hoarding what belongs to ME!",\
			"Your hive has MY treasure! I fought your wars, now PAY ME!",\
			"Generals and queens, all the same liars! WHERE IS IT!?"\
			)

	if(istype(target, /mob/living/simple_animal/hostile/abnormality/titania))
		return pick(\
			"TITANIA! Queen of the Faeries, queen of THIEVES!",\
			"Your fairy gold was an illusion! I want REAL treasure!",\
			"The Fairy Queens tricks wont work on me anymore!"\
			)

	if(istype(target, /mob/living/simple_animal/hostile/abnormality/snow_queen))
		return pick(\
			"The Snow Queen! Your frozen heart matches HER cruelty!",\
			"Ice and gold, both cold and worthless! I was promised MORE!",\
			"Another queen, another betrayal! This ends NOW!"\
			)

	if(istype(target, /mob/living/simple_animal/hostile/abnormality/greed_king))
		return pick(\
			"GREED KING! You sit on a throne of MY gold!",\
			"Kings, queens, all hoarding what they promised their soldiers!",\
			"Your greed is NOTHING compared to what Im OWED!"\
			)

	// Fallback generic taunt
	return pick(queen_taunt_lines)

/datum/status_effect/ruin
	id = "ruin"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/ruin
	var/stacks = 1
	var/max_stacks = 20

/datum/status_effect/ruin/on_creation(mob/living/new_owner, new_stacks = 1)
	. = ..()
	if(.)
		stacks = clamp(new_stacks, 1, max_stacks)

/datum/status_effect/ruin/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage))
	owner.apply_status_effect(/datum/status_effect/devastation, 1)
	return TRUE

/datum/status_effect/ruin/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)

/datum/status_effect/ruin/proc/on_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER

	if(prob(stacks * 5))
		var/datum/status_effect/devastation/D = owner.has_status_effect(/datum/status_effect/devastation)
		if(D)
			var/bonus_damage = D.stacks * 10
			if(owner.stat != DEAD)
				if(istype(owner, /mob/living/simple_animal))
					bonus_damage *= 4
				owner.apply_damage(bonus_damage, BLACK_DAMAGE, null, owner.run_armor_check(null, BLACK_DAMAGE))
				new /obj/effect/temp_visual/revenant(get_turf(owner))
				to_chat(owner, "<span class='userdanger'>A devastating hit tears through you!</span>")
				playsound(owner, 'sound/effects/wounds/pierce3.ogg', 100, TRUE)

/datum/status_effect/ruin/proc/add_stacks(amount)
	stacks = clamp(stacks + amount, 1, max_stacks)
	owner.apply_status_effect(/datum/status_effect/devastation, amount)

/atom/movable/screen/alert/status_effect/ruin
	name = "Ruin"
	desc = "You're marked with ruin. Attacks have a chance to trigger devastating hits."
	icon_state = "ruin"

/datum/status_effect/devastation
	id = "devastation"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/devastation
	var/stacks = 1
	var/max_stacks = 40

/datum/status_effect/devastation/on_creation(mob/living/new_owner, new_stacks = 1)
	. = ..()
	if(.)
		stacks = clamp(new_stacks, 1, max_stacks)

/datum/status_effect/devastation/on_apply()
	owner.apply_status_effect(/datum/status_effect/ruin, 1)
	return TRUE

/datum/status_effect/devastation/proc/add_stacks(amount)
	stacks = clamp(stacks + amount, 1, max_stacks)
	var/datum/status_effect/ruin/R = owner.has_status_effect(/datum/status_effect/ruin)
	if(R)
		R.add_stacks(amount)

/atom/movable/screen/alert/status_effect/devastation
	name = "Devastation"
	desc = "You're building up devastating damage. The higher the stacks, the more damage you'll take from devastating hits."
	icon_state = "devastation"

/datum/ego_gifts/greed
	name = "Prospector's Charm"
	desc = "A small golden pickaxe charm that never loses its luster."
	icon_state = "greed"
