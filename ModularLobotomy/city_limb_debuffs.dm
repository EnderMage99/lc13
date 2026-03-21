/// Component that applies debuffs based on limb damage percentage on city maps.
/// Arms: reduced outgoing damage + self-damage on attack when mangled
/// Legs: self-damage every N tiles moved
/// Head: increased white/sanity damage taken
/// Chest: reduced healing effectiveness
/datum/component/city_limb_debuffs
	/// Current penalty applied to owner's extra_damage from arm injuries
	var/arm_damage_penalty = 0
	/// Current penalty applied to owner's physiology.white_mod from head injuries
	var/head_white_penalty = 0
	/// Whether either arm is mangled (100% damage) - triggers pain on attack
	var/arms_mangled = FALSE
	/// Tile move counter for leg pain
	var/move_counter = 0
	/// Current leg pain amount per trigger (0, 3, or 8)
	var/leg_pain_amount = 0
	/// Tiles between leg pain triggers (0 = no pain, 5 = injured, 3 = mangled)
	var/leg_pain_threshold = 0
	/// Previous tier per body_zone, used to detect threshold changes
	var/list/previous_tiers
	/// Limb max_damage as percentage of owner's maxHealth, keyed by body_zone type
	var/static/list/limb_health_percent = list(
		BODY_ZONE_CHEST = 0.30,
		BODY_ZONE_HEAD = 0.15,
		BODY_ZONE_L_ARM = 0.15,
		BODY_ZONE_R_ARM = 0.15,
		BODY_ZONE_L_LEG = 0.15,
		BODY_ZONE_R_LEG = 0.15
	)

/datum/component/city_limb_debuffs/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	previous_tiers = list()

/datum/component/city_limb_debuffs/RegisterWithParent()
	var/mob/living/carbon/human/H = parent
	// Prevent limb disabling and wounds
	ADD_TRAIT(H, TRAIT_NEVER_WOUNDED, CITY_VULNERABILITY_TRAIT)
	for(var/obj/item/bodypart/BP as anything in H.bodyparts)
		BP.can_be_disabled = FALSE
		previous_tiers[BP.body_zone] = 0

	update_limb_max_damage(H)
	RegisterSignal(parent, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_damage_taken))
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/component/city_limb_debuffs/UnregisterFromParent()
	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return
	// Remove all active debuffs
	if(arm_damage_penalty)
		H.extra_damage -= arm_damage_penalty
		arm_damage_penalty = 0
	if(head_white_penalty && H.physiology)
		H.physiology.white_mod -= head_white_penalty
		head_white_penalty = 0
	H.city_heal_mod = 1

	REMOVE_TRAIT(H, TRAIT_NEVER_WOUNDED, CITY_VULNERABILITY_TRAIT)
	for(var/obj/item/bodypart/BP as anything in H.bodyparts)
		BP.can_be_disabled = initial(BP.can_be_disabled)
		BP.max_damage = initial(BP.max_damage)

	UnregisterSignal(parent, list(COMSIG_MOB_AFTER_APPLY_DAMGE, COMSIG_MOB_ITEM_ATTACK, COMSIG_MOVABLE_MOVED))

/// Set each limb's max_damage to a percentage of the owner's maxHealth
/datum/component/city_limb_debuffs/proc/update_limb_max_damage(mob/living/carbon/human/H)
	for(var/obj/item/bodypart/BP as anything in H.bodyparts)
		var/percent = limb_health_percent[BP.body_zone]
		if(percent)
			BP.max_damage = max(1, round(H.maxHealth * percent))

/// Returns 0 (healthy), 1 (injured >=50%), or 2 (mangled >=100%)
/datum/component/city_limb_debuffs/proc/get_limb_tier(obj/item/bodypart/BP)
	var/damage_percent = (BP.brute_dam + BP.burn_dam) / BP.max_damage
	if(damage_percent >= 1)
		return 2
	if(damage_percent >= 0.5)
		return 1
	return 0

/// Recalculate all limb debuffs after taking damage
/datum/component/city_limb_debuffs/proc/on_damage_taken(datum/source, final_damage, damage_type, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker, flags, attack_type)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(update_limb_debuffs))

/datum/component/city_limb_debuffs/proc/update_limb_debuffs()
	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return

	update_limb_max_damage(H)

	var/new_arm_penalty = 0
	var/new_arms_mangled = FALSE
	var/new_head_white_penalty = 0
	var/new_chest_heal_mod = 1
	var/new_leg_pain_amount = 0
	var/new_leg_pain_threshold = 0

	for(var/obj/item/bodypart/BP as anything in H.bodyparts)
		var/tier = get_limb_tier(BP)
		var/old_tier = previous_tiers[BP.body_zone]

		// Notify on threshold changes
		if(tier != old_tier)
			notify_tier_change(H, BP, old_tier, tier)
			previous_tiers[BP.body_zone] = tier

		switch(BP.body_zone)
			// Arms: outgoing damage reduction
			if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
				switch(tier)
					if(1)
						new_arm_penalty -= 15
					if(2)
						new_arm_penalty -= 30
						new_arms_mangled = TRUE
			// Legs: pain on movement
			if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
				// Use worst leg tier
				if(tier == 2)
					new_leg_pain_amount = 8
					new_leg_pain_threshold = 3
				else if(tier == 1 && new_leg_pain_amount < 3)
					new_leg_pain_amount = 3
					new_leg_pain_threshold = 5
			// Head: increased white/sanity damage
			if(BODY_ZONE_HEAD)
				switch(tier)
					if(1)
						new_head_white_penalty = 0.25
					if(2)
						new_head_white_penalty = 0.5
			// Chest: reduced healing
			if(BODY_ZONE_CHEST)
				switch(tier)
					if(1)
						new_chest_heal_mod = 0.75
					if(2)
						new_chest_heal_mod = 0.5

	// Apply arm penalty changes
	if(new_arm_penalty != arm_damage_penalty)
		H.extra_damage -= arm_damage_penalty
		H.extra_damage += new_arm_penalty
		arm_damage_penalty = new_arm_penalty

	arms_mangled = new_arms_mangled

	// Apply head white_mod changes
	if(new_head_white_penalty != head_white_penalty && H.physiology)
		H.physiology.white_mod -= head_white_penalty
		H.physiology.white_mod += new_head_white_penalty
		head_white_penalty = new_head_white_penalty

	// Apply chest heal_mod
	H.city_heal_mod = new_chest_heal_mod

	// Apply leg pain settings
	leg_pain_amount = new_leg_pain_amount
	leg_pain_threshold = new_leg_pain_threshold
	if(!leg_pain_threshold)
		move_counter = 0

/// Send to_chat messages when a limb crosses a damage threshold
/datum/component/city_limb_debuffs/proc/notify_tier_change(mob/living/carbon/human/H, obj/item/bodypart/BP, old_tier, new_tier)
	var/limb_name = BP.name
	// Upgrading to injured
	if(new_tier >= 1 && old_tier < 1)
		switch(BP.body_zone)
			if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
				to_chat(H, span_warning("Your [limb_name] is injured! Your attacks deal less damage."))
			if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
				to_chat(H, span_warning("Your [limb_name] is injured! Moving causes you pain."))
			if(BODY_ZONE_HEAD)
				to_chat(H, span_warning("Your head is injured! You are more vulnerable to sanity damage."))
			if(BODY_ZONE_CHEST)
				to_chat(H, span_warning("Your chest is injured! Healing is less effective."))
	// Upgrading to mangled
	if(new_tier >= 2 && old_tier < 2)
		switch(BP.body_zone)
			if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
				to_chat(H, span_userdanger("Your [limb_name] is mangled! Your attacks deal much less damage and cause you pain!"))
			if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
				to_chat(H, span_userdanger("Your [limb_name] is mangled! Every step is agony!"))
			if(BODY_ZONE_HEAD)
				to_chat(H, span_userdanger("Your head is mangled! You are extremely vulnerable to sanity damage!"))
			if(BODY_ZONE_CHEST)
				to_chat(H, span_userdanger("Your chest is mangled! Healing is severely reduced!"))
	// Recovering from mangled
	if(new_tier < 2 && old_tier >= 2)
		switch(BP.body_zone)
			if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
				to_chat(H, span_notice("Your [limb_name] is no longer mangled."))
			if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
				to_chat(H, span_notice("Your [limb_name] is no longer mangled."))
			if(BODY_ZONE_HEAD)
				to_chat(H, span_notice("Your head is no longer mangled."))
			if(BODY_ZONE_CHEST)
				to_chat(H, span_notice("Your chest is no longer mangled."))
	// Recovering from injured
	if(new_tier < 1 && old_tier >= 1)
		switch(BP.body_zone)
			if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
				to_chat(H, span_notice("Your [limb_name] has recovered."))
			if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
				to_chat(H, span_notice("Your [limb_name] has recovered."))
			if(BODY_ZONE_HEAD)
				to_chat(H, span_notice("Your head has recovered."))
			if(BODY_ZONE_CHEST)
				to_chat(H, span_notice("Your chest has recovered."))

/// When attacking with a weapon and arms are mangled, deal self-damage
/datum/component/city_limb_debuffs/proc/on_item_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(!arms_mangled)
		return
	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return
	INVOKE_ASYNC(src, PROC_REF(apply_arm_pain), H)

/datum/component/city_limb_debuffs/proc/apply_arm_pain(mob/living/carbon/human/H)
	H.adjustBruteLoss(5)
	to_chat(H, span_warning("Pain shoots through your mangled arms!"))

/// Track tile movement and deal leg pain
/datum/component/city_limb_debuffs/proc/on_moved(datum/source, atom/old_loc, dir)
	SIGNAL_HANDLER
	if(!leg_pain_threshold)
		return
	move_counter++
	if(move_counter >= leg_pain_threshold)
		move_counter = 0
		var/mob/living/carbon/human/H = parent
		if(!istype(H))
			return
		INVOKE_ASYNC(src, PROC_REF(apply_leg_pain), H)

/datum/component/city_limb_debuffs/proc/apply_leg_pain(mob/living/carbon/human/H)
	H.adjustBruteLoss(leg_pain_amount)
	to_chat(H, span_warning("Your injured legs ache with every step!"))
