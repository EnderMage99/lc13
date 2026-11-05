// What the 3rd Floor Manager leaves on those who fight him: Guarded Caution on whoever hurts him, Gratitude for
// Listening on whoever stood in his blue light, and the Horribly Infinite Replay his bird sings at the most cautious.

/// Adds a stack of Guarded Caution to L, or gives it to them.
/proc/GmsAddCaution(mob/living/L)
	var/datum/status_effect/stacking/gms_guarded_caution/C = L.has_status_effect(/datum/status_effect/stacking/gms_guarded_caution)
	if(C)
		C.Gain()
	else
		L.apply_status_effect(/datum/status_effect/stacking/gms_guarded_caution, 1)

/// How many stacks of Guarded Caution L has, 0 if none.
/proc/GmsCautionStacks(mob/living/L)
	var/datum/status_effect/stacking/gms_guarded_caution/C = L.has_status_effect(/datum/status_effect/stacking/gms_guarded_caution)
	return C ? C.stacks : 0

/// Adds `amount` stacks of Gratitude for Listening to L, or gives it to them with that many.
/proc/GmsAddGratitude(mob/living/L, amount)
	var/datum/status_effect/stacking/gms_gratitude/G = L.has_status_effect(/datum/status_effect/stacking/gms_gratitude)
	if(G)
		G.add_stacks(amount)
	else
		L.apply_status_effect(/datum/status_effect/stacking/gms_gratitude, amount)

/// A halo of the Manager's light, centred on the head: a human's, or the top middle of anything else's sprite, where
/// `head_drop` is how far the middle of the head sits below the top of the sprite.
/proc/GmsHeadAura(mob/living/L, state, head_drop = 5)
	var/icon/I = icon(L.icon)
	var/mutable_appearance/aura = mutable_appearance('icons/mob/gms/gms_32x32.dmi', state, ABOVE_MOB_LAYER)
	aura.pixel_x = (I.Width() - world.icon_size) / 2
	aura.pixel_y = I.Height() - world.icon_size / 2 - head_drop
	return aura

/// Guarded Caution: the bearer hurt the Manager, and he is wary of them. A stack is gained each time they hurt him, at
/// most once per gain_cooldown_time, and each makes his attacks on them stronger. All of it clears once clear_time
/// passes without a new stack. The halo over their head goes from yellow to red as it builds.
/datum/status_effect/stacking/gms_guarded_caution
	id = "gms_guarded_caution"
	alert_type = /atom/movable/screen/alert/status_effect/gms_guarded_caution
	max_stacks = 10
	// It never decays a stack at a time; it clears all at once instead.
	delay_before_decay = 0
	tick_interval = 1 SECONDS
	consumed_on_threshold = FALSE
	var/clear_time = 20 SECONDS
	var/last_gained = 0
	var/gain_cooldown_time = 2 SECONDS
	var/gain_cooldown = 0
	/// The halo has this many heats, the last only at max stacks.
	var/heats = 4
	var/mutable_appearance/aura

/atom/movable/screen/alert/status_effect/gms_guarded_caution
	name = "Guarded Caution"
	desc = "The 3rd Floor Manager is wary of you. His attacks deal 5% more damage to you for each stack. At 10 stacks, his bird may sing for you."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "third_floor_manager_guarded_caution"

/datum/status_effect/stacking/gms_guarded_caution/on_apply()
	. = ..()
	if(.)
		gain_cooldown = world.time + gain_cooldown_time

/datum/status_effect/stacking/gms_guarded_caution/on_remove()
	owner.cut_overlay(aura)
	return ..()

/datum/status_effect/stacking/gms_guarded_caution/add_stacks(stacks_added)
	if(stacks_added > 0)
		last_gained = world.time
	. = ..()
	ShowAura()

/datum/status_effect/stacking/gms_guarded_caution/tick()
	if(!can_have_status() || world.time - last_gained >= clear_time)
		qdel(src)

/// Gains a stack, unless one was gained too recently.
/datum/status_effect/stacking/gms_guarded_caution/proc/Gain()
	if(gain_cooldown > world.time)
		return
	gain_cooldown = world.time + gain_cooldown_time
	add_stacks(1)

/// Shows the halo at the heat its stacks call for: one heat for every few stacks, the reddest only at max stacks.
/datum/status_effect/stacking/gms_guarded_caution/proc/ShowAura()
	if(QDELETED(src) || QDELETED(owner))
		return
	owner.cut_overlay(aura)
	var/heat = stacks >= max_stacks ? heats : 1 + round((stacks - 1) / ((max_stacks - 1) / (heats - 1)))
	aura = GmsHeadAura(owner, "third_floor_manager_aura_yellow_[heat]")
	owner.add_overlay(aura)

/// Gratitude for Listening: the bearer stood in the Manager's blue light, and his guard is down to them. Their attacks
/// on him deal far more, and do not make him wary. Each melee hit on him spends a stack, at most once per
/// spend_cooldown_time. Every check_time without one spent, it gains check_gain stacks, or ends if already full.
/datum/status_effect/stacking/gms_gratitude
	id = "gms_gratitude_for_listening"
	alert_type = /atom/movable/screen/alert/status_effect/gms_gratitude
	max_stacks = 10
	delay_before_decay = 0
	tick_interval = 1 SECONDS
	consumed_on_threshold = FALSE
	var/check_time = 10 SECONDS
	var/next_check = 0
	/// TRUE once a stack was spent since the last check.
	var/spent = FALSE
	var/check_gain = 5
	var/spend_cooldown_time = 2 SECONDS
	var/spend_cooldown = 0
	/// The halo is as see-through as its stacks are few: min_alpha at one stack, solid at max stacks.
	var/min_alpha = 60
	var/mutable_appearance/aura

/atom/movable/screen/alert/status_effect/gms_gratitude
	name = "Gratitude for Listening"
	desc = "The 3rd Floor Manager's guard is down to you. Your attacks deal 5 times the damage to him. Each melee hit on him spends a stack; go 10 seconds without one and it builds up, then fades."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "third_floor_manager_gratitude_for_listening"

/datum/status_effect/stacking/gms_gratitude/on_apply()
	. = ..()
	if(.)
		next_check = world.time + check_time

/datum/status_effect/stacking/gms_gratitude/on_remove()
	owner.cut_overlay(aura)
	return ..()

/datum/status_effect/stacking/gms_gratitude/add_stacks(stacks_added)
	. = ..()
	ShowAura()

/// Shows the halo, fainter the fewer stacks there are.
/datum/status_effect/stacking/gms_gratitude/proc/ShowAura()
	if(QDELETED(src) || QDELETED(owner))
		return
	owner.cut_overlay(aura)
	aura = GmsHeadAura(owner, "third_floor_manager_aura_blue")
	aura.alpha = min_alpha + (255 - min_alpha) * (stacks - 1) / (max_stacks - 1)
	owner.add_overlay(aura)

/datum/status_effect/stacking/gms_gratitude/tick()
	if(!can_have_status())
		qdel(src)
		return
	if(next_check > world.time)
		return
	next_check = world.time + check_time
	if(spent)
		spent = FALSE
		return
	if(stacks >= max_stacks)
		qdel(src)
		return
	add_stacks(check_gain)

/// Spends a stack for a melee hit on the Manager, unless one was spent too recently.
/datum/status_effect/stacking/gms_gratitude/proc/Spend()
	if(spend_cooldown > world.time)
		return
	spend_cooldown = world.time + spend_cooldown_time
	spent = TRUE
	add_stacks(-1)

/// While a Gratitude holder's hit lands on the Manager, it takes this many times the damage of every type.
/datum/dc_change/gms_gratitude
	potency = 5
	damage_type = list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)

/// Ends the bird's song on a human for the Horribly Infinite Replay: whatever panic the song drove them to is made
/// murder. Someone it could not panic takes final_share of their max health as BRUTE instead, and no Replay. Returns
/// TRUE if they got the Replay.
/proc/GmsHorriblyInfiniteReplay(mob/living/carbon/human/H, mob/living/singer, final_share = 0.5)
	if(!H.sanity_lost)
		H.deal_damage(H.maxHealth * final_share, BRUTE, singer, attack_type = ATTACK_TYPE_SPECIAL)
		return FALSE
	// The same swap White Lake and the Singing Machine make, whatever panic came first.
	QDEL_NULL(H.ai_controller)
	H.ai_controller = /datum/ai_controller/insane/murder
	H.InitializeAIController()
	H.apply_status_effect(/datum/status_effect/panicked_type/murder)
	H.apply_status_effect(/datum/status_effect/gms_horribly_infinite_replay)
	return TRUE

/// Horribly Infinite Replay: the bird's song plays on in the bearer's head, and they turn on their friends with their
/// attacks dealing damage_cut percent less. When it ends, unpanic_damage WHITE snaps them out of it (sanity is set right
/// directly for those whose WHITE turns to BRUTE), and then they take final_share of their max health as BRUTE.
/datum/status_effect/gms_horribly_infinite_replay
	id = "gms_horribly_infinite_replay"
	duration = 10 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/gms_horribly_infinite_replay
	var/damage_cut = 50
	var/unpanic_damage = 999
	var/final_share = 0.5

/atom/movable/screen/alert/status_effect/gms_horribly_infinite_replay
	name = "Horribly Infinite Replay"
	desc = "The bird's song will not stop. You deal 50% less damage. When it ends, you come back to your senses, and take damage equal to half your max health."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "third_floor_manager_horribly_infinite_replay"

/datum/status_effect/gms_horribly_infinite_replay/on_apply()
	owner.extra_damage -= damage_cut
	return TRUE

/datum/status_effect/gms_horribly_infinite_replay/on_remove()
	owner.extra_damage += damage_cut
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	var/mob/living/carbon/human/H = owner
	// Their friends may already have talked them down.
	if(H.sanity_lost)
		if(HAS_TRAIT(H, TRAIT_BRUTESANITY))
			H.adjustSanityLoss(-H.maxSanity, forced = TRUE)
		else
			H.deal_damage(unpanic_damage, WHITE_DAMAGE, flags = (DAMAGE_WHITE_HEALABLE | DAMAGE_PIERCING | DAMAGE_FORCED), attack_type = ATTACK_TYPE_STATUS)
	H.deal_damage(H.maxHealth * final_share, BRUTE, attack_type = ATTACK_TYPE_STATUS)
