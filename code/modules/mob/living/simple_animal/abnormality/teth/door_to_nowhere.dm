/mob/living/simple_animal/hostile/abnormality/door_to_nowhere
	name = "Door to Nowhere"
	desc = "A door wrapped in chains, floating ominously in the air. Behind it lies memories best left forgotten, regrets that should remain sealed."
	icon = 'ModularTegustation/Teguicons/chain_door.dmi'
	icon_state = "chained_door"
	icon_living = "chained_door"
	icon_dead = "chained_door"
	maxHealth = 400
	health = 400
	threat_level = TETH_LEVEL
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 8
	melee_damage_upper = 12
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "crashes into"
	attack_verb_simple = "crash into"
	attack_sound = 'sound/weapons/genhit1.ogg'
	can_breach = FALSE
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(70, 70, 65, 65, 65),
		ABNORMALITY_WORK_INSIGHT = list(70, 70, 65, 65, 65),
		ABNORMALITY_WORK_ATTACHMENT = list(30, 30, 25, 25, 25),
		ABNORMALITY_WORK_REPRESSION = list(10, 10, 5, 0, 0),
	)
	work_damage_amount = 6
	work_damage_type = WHITE_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/liminal,
		/datum/ego_datum/armor/liminal,
	)
	gift_type = /datum/ego_gifts/liminal
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

	observation_prompt = "The chained door hovers before you, its surface scarred and weathered. You feel drawn to examine it closer..."
	observation_choices = list(
		"The chains seem to pulse with regret" = list(TRUE, "You notice the chains tighten rhythmically, as if trying to keep something locked away. Behind the door, you hear faint echoes of forgotten memories."),
		"It's just a locked door" = list(FALSE, "You turn away from the door. Some things are meant to stay locked."),
	)

	var/list/trapped_employees = list()
	var/list/original_locations = list()
	var/list/backrooms_locations = list()
	var/list/backrooms_effects = list() // Track status effects

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/PostSpawn()
	..()
	// Find all backrooms landmarks
	for(var/obj/effect/landmark/backrooms_spawn/L in GLOB.landmarks_list)
		backrooms_locations += get_turf(L)

	// Fallback if no landmarks exist
	if(!LAZYLEN(backrooms_locations))
		var/turf/T = locate(1, 1, z)
		if(T)
			backrooms_locations += T
		else
			backrooms_locations += get_turf(src)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	. = ..()
	// Handle Repression work - rescue trapped employees
	if(work_type == ABNORMALITY_WORK_REPRESSION)
		if(LAZYLEN(trapped_employees))
			var/mob/living/carbon/human/rescued = pick(trapped_employees)
			RescueFromBackrooms(rescued)
			to_chat(user, span_notice("You manage to pull [rescued] back from that strange place!"))
		else
			to_chat(user, span_notice("There's no one to rescue."))
		return

	// Handle Insight work - increase Qliphoth counter
	if(work_type == ABNORMALITY_WORK_INSIGHT)
		datum_reference.qliphoth_change(2)
		to_chat(user, span_notice("The chains around the door tighten, keeping the regrets sealed within."))
		return

	// All other work types decrease Qliphoth counter
	datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	// 70% chance to send to backrooms on bad work (except Repression)
	if(work_type != ABNORMALITY_WORK_REPRESSION && prob(70))
		SendToBackrooms(user)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/SendToBackrooms(mob/living/carbon/human/H)
	if(!H || (H in trapped_employees))
		return

	trapped_employees += H
	original_locations[H] = get_turf(H)

	to_chat(H, span_userdanger("The door's chains rattle violently as it pulls you into a realm of sealed memories!"))
	playsound(get_turf(H), 'sound/abnormalities/dinner_chair/ragdoll_effect.ogg', 75, TRUE)

	// Apply violent spinning effect
	INVOKE_ASYNC(src, PROC_REF(ViolentSpin), H)

	// Wait for the spinning to finish before teleporting
	addtimer(CALLBACK(src, PROC_REF(FinishTeleport), H), 12 SECONDS)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/ViolentSpin(mob/living/M)
	if(!M)
		return

	var/matrix/initial_matrix = matrix(M.transform)
	// 10x more extreme than disco dance
	for(var/i in 1 to 120) // 12 seconds worth at 0.1 second intervals
		if(!M || QDELETED(M))
			return

		// Violent rotation
		initial_matrix = matrix(M.transform)
		initial_matrix.Turn(rand(45, 180)) // Random violent turns

		// Extreme position changes
		var/x_shift = rand(-10, 10)
		var/y_shift = rand(-10, 10)
		initial_matrix.Translate(x_shift, y_shift)

		animate(M, transform = initial_matrix, time = 1, loop = 0, easing = pick(LINEAR_EASING, SINE_EASING, CIRCULAR_EASING))

		// Rapid direction changes
		M.setDir(pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))

		sleep(1)

	// Reset transformation
	animate(M, transform = null, time = 5, loop = 0)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/FinishTeleport(mob/living/carbon/human/H)
	if(!H || !(H in trapped_employees))
		return

	to_chat(H, span_warning("You find yourself in a liminal space of forgotten memories. The walls echo with regrets that were never voiced, sealed away behind countless doors."))
	to_chat(H, span_warning("Each door you see is chained shut, hiding moments that someone desperately wanted to forget."))

	playsound(get_turf(H), 'sound/effects/podwoosh.ogg', 50, TRUE)

	// Pick a random backrooms location
	var/turf/destination = pick(backrooms_locations)
	H.forceMove(destination)

	H.Stun(30)
	H.adjustSanityLoss(20)

	// Apply backrooms status effect
	var/datum/status_effect/backrooms_ambience/B = H.apply_status_effect(/datum/status_effect/backrooms_ambience)
	if(B)
		backrooms_effects[H] = B

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/proc/RescueFromBackrooms(mob/living/carbon/human/H)
	if(!H || !(H in trapped_employees))
		return

	trapped_employees -= H
	var/turf/return_turf = original_locations[H]
	if(!return_turf)
		return_turf = get_turf(src)

	original_locations -= H

	// Remove status effect
	if(backrooms_effects[H])
		H.remove_status_effect(/datum/status_effect/backrooms_ambience)
		backrooms_effects -= H

	to_chat(H, span_nicegreen("You feel a pull back to reality!"))
	playsound(get_turf(H), 'sound/magic/teleport_app.ogg', 50, TRUE)

	H.forceMove(return_turf)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/ZeroQliphoth(mob/living/carbon/human/user)
	var/list/potential_victims = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(H.stat == DEAD)
			continue
		if(H in trapped_employees)
			continue
		if(!H.mind)
			continue
		potential_victims += H

	if(!LAZYLEN(potential_victims))
		return

	var/victims_count = min(rand(1, 3), LAZYLEN(potential_victims))

	for(var/i in 1 to victims_count)
		if(!LAZYLEN(potential_victims))
			break
		var/mob/living/carbon/human/victim = pick_n_take(potential_victims)
		SendToBackrooms(victim)
		to_chat(victim, span_userdanger("The door has dragged you behind its threshold, into the realm of sealed regrets!"))

	visible_message(span_danger("[src]'s chains burst open momentarily, releasing waves of forgotten regrets before sealing shut once more."))
	datum_reference.qliphoth_change(3)

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/Destroy()
	for(var/mob/living/carbon/human/H in trapped_employees)
		RescueFromBackrooms(H)
	return ..()

/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/death(gibbed)
	for(var/mob/living/carbon/human/H in trapped_employees)
		RescueFromBackrooms(H)
		to_chat(H, span_notice("With the door shattered, the sealed memories dissipate and you are freed from that forsaken realm."))
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

// Backrooms landmark for mapping
/obj/effect/landmark/backrooms_spawn
	name = "backrooms spawn"
	icon_state = "x2"

/area/fishboat/backrooms
	name = "???"

// Status effect for ambient backrooms audio
/datum/status_effect/backrooms_ambience
	id = "backrooms_ambience"
	duration = -1 // Permanent until removed
	alert_type = null
	var/next_sound_time = 0

/datum/status_effect/backrooms_ambience/tick()
	if(world.time >= next_sound_time)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.playsound_local(get_turf(H), 'sound/ambience/VoidsEmbrace.ogg', 50, FALSE, pressure_affected = FALSE)
			to_chat(H, span_warning("You hear whispers of regrets... memories trying to claw their way back into existence."))
		// Next sound in 5-10 minutes (converted to deciseconds)
		next_sound_time = world.time + rand(3000, 6000) // 300-600 seconds = 5-10 minutes

/datum/status_effect/backrooms_ambience/on_apply()
	. = ..()
	// Play the sound immediately when first applied
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.playsound_local(get_turf(H), 'sound/ambience/VoidsEmbrace.ogg', 50, FALSE, pressure_affected = FALSE)
	next_sound_time = world.time + rand(3000, 6000)

// Regret Door Structure
/obj/structure/regret_door
	name = "chained door"
	desc = "A door bound in rusted chains, keeping memories sealed away."
	icon = 'ModularTegustation/Teguicons/chain_door.dmi'
	icon_state = "regret_door"
	anchored = TRUE
	opacity = FALSE
	resistance_flags = INDESTRUCTIBLE
	density = FALSE
	var/door_name = ""
	var/door_desc = ""
	var/spirit_name = ""
	var/spirit_desc = ""
	var/mob/living/simple_animal/hostile/regret_spirit/associated_spirit

/obj/structure/regret_door/Initialize()
	. = ..()
	generate_regret_identity()
	spawn_associated_spirit()

/obj/structure/regret_door/proc/generate_regret_identity()
	// Lists of regret themes
	var/list/regret_types = list(
		"The Apology Never Given",
		"Mother's Last Words",
		"The Love Never Confessed",
		"Father's Disappointment",
		"The Friend You Betrayed",
		"The Opportunity Refused",
		"The Child Never Born",
		"The Truth Never Told",
		"The Promise Broken",
		"The Goodbye Never Said",
		"The Help Never Offered",
		"The Stand Never Taken",
		"The Dream Abandoned",
		"The Parent Never Visited",
		"The Forgiveness Withheld",
		"The Letter Never Sent",
		"The Call Never Made",
		"The Risk Never Taken",
		"The Words Too Late",
		"The Silence That Hurt"
	)

	var/list/spirit_first_names = list(
		"Marcus", "Elena", "James", "Sarah", "David", "Maria", "Thomas", "Anna",
		"Robert", "Lisa", "Michael", "Emma", "William", "Sophie", "Charles", "Grace",
		"Joseph", "Claire", "Daniel", "Helen", "Samuel", "Rose", "Henry", "Alice"
	)

	var/list/spirit_emotions = list(
		"weeping", "lamenting", "mourning", "grieving", "regretting",
		"yearning", "aching", "suffering", "remorseful", "tormented"
	)

	// Pick random elements
	door_name = pick(regret_types)
	name = door_name

	var/chosen_first_name = pick(spirit_first_names)
	var/chosen_emotion = pick(spirit_emotions)

	// Generate descriptions based on the door type
	switch(door_name)
		if("The Apology Never Given")
			door_desc = "Behind this door echoes an endless loop of 'I'm sorry' that was never spoken."
			spirit_name = "[chosen_first_name] the Unforgiving"
			spirit_desc = "A spectral figure eternally waiting for an apology that will never come."
		if("Mother's Last Words")
			door_desc = "You can hear a mother's voice calling for her child who never came."
			spirit_name = "[chosen_first_name] the Absent"
			spirit_desc = "This spirit clutches at empty air where a child's hand should have been."
		if("The Love Never Confessed")
			door_desc = "The chains tremble with the weight of unspoken affection."
			spirit_name = "[chosen_first_name] the Silent Heart"
			spirit_desc = "A ghost whose lips move constantly, practicing words they never had the courage to say."
		if("Father's Disappointment")
			door_desc = "A heavy silence emanates from within, thick with unmet expectations."
			spirit_name = "[chosen_first_name] the Insufficient"
			spirit_desc = "This shade carries the weight of never being good enough."
		if("The Friend You Betrayed")
			door_desc = "Muffled sobs and the sound of trust breaking echo from beyond."
			spirit_name = "[chosen_first_name] the Betrayed"
			spirit_desc = "A spirit with a knife-shaped wound that never stops bleeding ectoplasm."
		if("The Opportunity Refused")
			door_desc = "Behind this door lies every 'what if' that haunts the fearful."
			spirit_name = "[chosen_first_name] the Coward"
			spirit_desc = "This ghost eternally reaches for something just beyond their grasp."
		if("The Child Never Born")
			door_desc = "Empty lullabies drift through the chains."
			spirit_name = "[chosen_first_name] the Childless"
			spirit_desc = "A parental figure cradling nothing but air and sorrow."
		if("The Truth Never Told")
			door_desc = "Lies upon lies have crystallized into chains that bind this door."
			spirit_name = "[chosen_first_name] the Deceiver"
			spirit_desc = "A spirit whose form shifts constantly, never showing their true face."
		if("The Promise Broken")
			door_desc = "The chains here are made from shattered vows."
			spirit_name = "[chosen_first_name] the Oathbreaker"
			spirit_desc = "This shade's hands are bound by ethereal contracts they failed to honor."
		if("The Goodbye Never Said")
			door_desc = "The door rattles with the urgency of final words unspoken."
			spirit_name = "[chosen_first_name] the Departed"
			spirit_desc = "A ghost forever frozen in the moment they should have said farewell."
		else
			door_desc = "The chains pulse with the rhythm of a [chosen_emotion] heart."
			spirit_name = "[chosen_first_name] the [capitalize(chosen_emotion)]"
			spirit_desc = "A tormented soul forever bound to their deepest regret."

	desc = door_desc

/obj/structure/regret_door/proc/spawn_associated_spirit()
	// Find all valid turfs in the backrooms area
	var/list/valid_turfs = list()
	for(var/turf/T in range(10, src))
		if(istype(T.loc, /area/fishboat/backrooms) && !T.density)
			var/blocked = FALSE
			for(var/atom/A in T)
				if(A.density)
					blocked = TRUE
					break
			if(!blocked)
				valid_turfs += T

	if(!LAZYLEN(valid_turfs))
		return

	// Spawn the spirit
	var/turf/spawn_loc = pick(valid_turfs)
	associated_spirit = new /mob/living/simple_animal/hostile/regret_spirit(spawn_loc)
	associated_spirit.name = spirit_name
	associated_spirit.desc = spirit_desc
	associated_spirit.associated_door = src

/obj/structure/regret_door/examine(mob/user)
	. = ..()
	. += span_warning("Looking at it fills you with an inexplicable sense of loss.")
	if(prob(30))
		to_chat(user, span_notice("You hear faint whispers: '[pick("I should have...", "Why didn't I...", "If only...", "I'm sorry...", "Please forgive me...")]'"))
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.adjustSanityLoss(5)

/obj/structure/regret_door/Destroy()
	if(associated_spirit)
		qdel(associated_spirit)
	return ..()

// Regret Spirit Mob
/mob/living/simple_animal/hostile/regret_spirit
	name = "spirit of regret"
	desc = "A tormented soul bound to their eternal shame."
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	icon_living = "ghost"
	mob_biotypes = MOB_SPIRIT
	speak_chance = 0.1
	turns_per_move = 10
	response_help_continuous = "passes through"
	response_help_simple = "pass through"
	a_intent = INTENT_HELP
	friendly_verb_continuous = "mourns at"
	friendly_verb_simple = "mourn at"
	speed = 2
	maxHealth = 100
	health = 100
	faction = list("neutral")
	harm_intent_damage = 0
	melee_damage_lower = 0
	melee_damage_upper = 0
	attack_verb_continuous = "phases through"
	attack_verb_simple = "phase through"
	speak_emote = list("whispers", "laments", "weeps")
	emote_see = list(
		"stares at something that isn't there",
		"reaches out to empty air",
		"mouths silent words",
		"trembles with grief",
		"clutches at their ethereal chest"
	)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	is_flying_animal = TRUE
	pressure_resistance = 300
	light_system = MOVABLE_LIGHT
	light_range = 1
	light_power = 1
	light_color = "#7092BE"
	del_on_death = TRUE
	death_message = "lets out a final, mournful wail before fading into nothingness..."
	var/obj/structure/regret_door/associated_door
	var/list/regret_phrases = list()

/mob/living/simple_animal/hostile/regret_spirit/Initialize()
	. = ..()
	alpha = 180 // Semi-transparent
	generate_regret_phrases()

/mob/living/simple_animal/hostile/regret_spirit/proc/generate_regret_phrases()
	// Generate phrases based on the spirit's name/type
	if(findtext(name, "Unforgiving"))
		regret_phrases = list(
			"I waited so long for you to say it...",
			"Just one word would have been enough...",
			"Why couldn't you apologize?",
			"I would have forgiven you..."
		)
	else if(findtext(name, "Absent"))
		regret_phrases = list(
			"She called for you...",
			"You should have been there...",
			"She died alone because of you...",
			"Her last word was your name..."
		)
	else if(findtext(name, "Silent Heart"))
		regret_phrases = list(
			"I loved you... I loved you... I loved you...",
			"Three words I never said...",
			"Now you'll never know...",
			"My cowardice killed us both..."
		)
	else if(findtext(name, "Betrayed"))
		regret_phrases = list(
			"We were supposed to be friends...",
			"How could you do this to me?",
			"I trusted you with everything...",
			"Was any of it real?"
		)
	else
		regret_phrases = list(
			"If only...",
			"I should have...",
			"Why didn't I...",
			"It's too late now...",
			"I'm so sorry..."
		)

/mob/living/simple_animal/hostile/regret_spirit/Life()
	. = ..()
	if(prob(speak_chance))
		say(pick(regret_phrases))

/mob/living/simple_animal/hostile/regret_spirit/examine(mob/user)
	. = ..()
	. += span_warning("Looking at [src] fills you with secondhand sorrow.")
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustSanityLoss(3)

/mob/living/simple_animal/hostile/regret_spirit/attack_hand(mob/living/carbon/human/M)
	if(M.a_intent == INTENT_HELP)
		to_chat(M, span_notice("Your hand passes through [src]. They don't even notice you're there."))
		playsound(loc, 'sound/effects/ghost2.ogg', 30, TRUE)
	else
		to_chat(M, span_warning("[src] is already suffering enough."))

/mob/living/simple_animal/hostile/regret_spirit/attackby(obj/item/W, mob/user, params)
	to_chat(user, span_notice("[W] passes harmlessly through [src]."))
	playsound(loc, 'sound/effects/ghost2.ogg', 30, TRUE)

/mob/living/simple_animal/hostile/regret_spirit/Destroy()
	if(associated_door)
		associated_door.associated_spirit = null
	return ..()
