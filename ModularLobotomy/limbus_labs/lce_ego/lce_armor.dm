// LCE Attunement system - base armor logic + the LCE armor suits.
// A worn LCE armor carries an attunement % (0-100). Higher attunement makes its paired
// LCE weapon hit harder; pushing past your personal safe limit inflicts debuffs. The safe
// limit is derived from how much you have bonded with the source abnormality.
// Adding a new LCE set is just config: set attunement_family + paired_weapon here, define
// the weapon in lce_weapons.dm, and add an armor ego_datum in lce_datum.dm.


// ---- Global state ----
// family -> list of live LCE armor instances (worn or not). Used by the abno Communion
// action and by weapons that need to find their armor.
GLOBAL_LIST_EMPTY(lce_armors)
// "[ckey]-[family]" -> accumulated interaction points with that abno family.
GLOBAL_LIST_EMPTY(lce_attunement_affinity)

// Returns the worn LCE armor matching the given family, or null. Used by LCE weapons.
/proc/GetWornLCEArmor(mob/user, family)
	if(!ishuman(user) || !family)
		return null
	var/obj/item/clothing/suit/armor/ego_gear/lce/A = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(A) && A.attunement_family == family)
		return A
	return null

// Call after anything changes a person's bond with an abno family. The bond is earned and lost
// mid-round, so a suit already being worn has to follow it - it used to keep whatever ceiling
// it was equipped with until the wearer took it off and put it back on.
/proc/RefreshLCEAttunement(mob/user, family)
	var/obj/item/clothing/suit/armor/ego_gear/lce/A = GetWornLCEArmor(user, family)
	if(A)
		A.UpdateSafeLimit(user)

// ---- Base LCE armor: attunement state + behavior ----
/obj/item/clothing/suit/armor/ego_gear/lce
	icon = 'ModularLobotomy/_Lobotomyicons/lce_armor.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/lce_armor_worn.dmi'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)
	actions_types = list(
		/datum/action/item_action/lce_attune_raise,
		/datum/action/item_action/lce_attune_lower,
		/datum/action/item_action/lce_attune_step,
		/datum/action/item_action/lce_locate,
	)
	/// Current attunement, 0-100.
	var/attunement = 0
	/// How much a raise/lower button press changes attunement (1 / 5 / 10).
	var/attunement_step = 5
	/// Safe attunement ceiling for the current wearer, computed on equip.
	var/safe_limit = 0
	/// Floor everyone gets even with no bond to the abno.
	var/safe_limit_floor = 10
	/// Links this armor to its weapon and its source abno.
	var/attunement_family = ""
	/// The LCE weapon spawned with (and bound to) this armor.
	var/paired_weapon = null
	var/obj/item/ego_weapon/tracked_weapon
	/// Rate-limit timer for the over-limit attack burn (so attack speed doesn't matter).
	var/next_overlimit_burn = 0
	var/summon_cooldown = 0
	// --- Per-set attunement tuning. ---
	/// Affinity points needed per +1% safe limit.
	var/attunement_points_per_percent = 3
	/// Max-SP (PRUDENCE) reduction per 1% over the safe limit.
	var/overload_sp_per_over = 0.3
	/// Self-damage per attack per 1% over the safe limit.
	var/overload_dmg_per_over = 0.8
	/// Minimum gap between over-limit burns.
	var/overload_burn_cooldown = 1.5 SECONDS
	/// Cooldown on summoning a lost weapon.
	var/weapon_summon_cooldown = 30 SECONDS

/obj/item/clothing/suit/armor/ego_gear/lce/Initialize(mapload)
	. = ..()
	if(attunement_family)
		if(!GLOB.lce_armors[attunement_family])
			GLOB.lce_armors[attunement_family] = list()
		GLOB.lce_armors[attunement_family] |= src
	if(paired_weapon && get_turf(src))
		SpawnPairedWeapon(get_turf(src))

/obj/item/clothing/suit/armor/ego_gear/lce/Destroy()
	// If destroyed while worn, make sure we don't leave the wearer's SP debuff stuck on.
	if(isliving(loc))
		var/mob/living/L = loc
		L.remove_status_effect(/datum/status_effect/attunement_overload)
	if(attunement_family && GLOB.lce_armors[attunement_family])
		GLOB.lce_armors[attunement_family] -= src
	if(tracked_weapon)
		// Armor destroyed -> its weapon disappears with it.
		UnregisterSignal(tracked_weapon, COMSIG_PARENT_QDELETING)
		qdel(tracked_weapon)
		tracked_weapon = null
	return ..()

// ---- Weapon pairing ----
/obj/item/clothing/suit/armor/ego_gear/lce/proc/SpawnPairedWeapon(atom/where)
	if(!paired_weapon || tracked_weapon)
		return
	var/obj/item/ego_weapon/W = new paired_weapon(where)
	// The weapon comes as part of the set, so anyone who can wear the armor can use it.
	// (Attunement, not attributes, is what makes it strong.)
	W.attribute_requirements = list()
	tracked_weapon = W
	RegisterSignal(W, COMSIG_PARENT_QDELETING, PROC_REF(OnWeaponDestroyed))

/obj/item/clothing/suit/armor/ego_gear/lce/proc/OnWeaponDestroyed(datum/source)
	SIGNAL_HANDLER
	tracked_weapon = null // Now the locate button switches to "summon" mode.

// ---- Equip / unequip ----
/obj/item/clothing/suit/armor/ego_gear/lce/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_OCLOTHING)
		return
	safe_limit = SafeLimitFor(user)
	RefreshAttunement(user)

// Recomputes the wearer's safe ceiling from their current bond and reconciles the overload
// with it, so a limit earned while the suit is on takes effect where the player stands.
/obj/item/clothing/suit/armor/ego_gear/lce/proc/UpdateSafeLimit(mob/living/carbon/human/user)
	if(!istype(user))
		return
	var/new_limit = SafeLimitFor(user)
	if(new_limit == safe_limit)
		return
	var/rising = new_limit > safe_limit
	safe_limit = new_limit
	RefreshAttunement(user)
	to_chat(user, span_notice("Your bond with [src] [rising ? "deepens" : "thins"]. Your safe attunement limit is now [safe_limit]%."))

/obj/item/clothing/suit/armor/ego_gear/lce/dropped(mob/user)
	. = ..()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.remove_status_effect(/datum/status_effect/attunement_overload)

// What this suit's safe ceiling would be for a given person. Used both on equip and by
// examine, so anyone can check where they stand before putting it on.
/obj/item/clothing/suit/armor/ego_gear/lce/proc/SafeLimitFor(mob/user)
	return clamp(safe_limit_floor + round(GetAffinity(user) / attunement_points_per_percent), safe_limit_floor, 100)

/obj/item/clothing/suit/armor/ego_gear/lce/proc/GetAffinity(mob/user)
	if(!user?.ckey || !attunement_family)
		return 0
	return GLOB.lce_attunement_affinity["[user.ckey]-[attunement_family]"] || 0

// ---- The one place that reconciles buffs/debuffs ----
/obj/item/clothing/suit/armor/ego_gear/lce/proc/RefreshAttunement(mob/living/carbon/human/user)
	if(!istype(user))
		return
	var/over = attunement - safe_limit
	user.remove_status_effect(/datum/status_effect/attunement_overload)
	if(over > 0)
		user.apply_status_effect(/datum/status_effect/attunement_overload, round(over * overload_sp_per_over))

// Over-limit self-damage on attack, rate-limited so fast weapons don't burn you more.
// Called by the paired weapon when it hits while over the safe limit.
/obj/item/clothing/suit/armor/ego_gear/lce/proc/HandleOverLimit(mob/living/user)
	var/over = attunement - safe_limit
	if(over <= 0)
		return
	// Sparks fly off the suit on every over-limit swing, so onlookers can see the strain.
	OverloadSparks(user)
	if(world.time < next_overlimit_burn)
		return
	next_overlimit_burn = world.time + overload_burn_cooldown
	// Direct BRUTE + pure SP damage, so it bypasses EGO armour resistances (a black-armoured
	// LCE suit shouldn't get to soak its own overload backlash).
	var/burn = round(over * overload_dmg_per_over)
	user.adjustBruteLoss(burn)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustSanityLoss(burn)

/obj/item/clothing/suit/armor/ego_gear/lce/proc/OverloadSparks(mob/living/user)
	var/turf/T = get_turf(user)
	if(!T)
		return
	for(var/i in 1 to 3)
		new /obj/effect/temp_visual/lce_overload_spark(T)

// ---- Attunement multiplier the weapons read ----
/obj/item/clothing/suit/armor/ego_gear/lce/proc/AttunementFrac()
	return attunement / 100

// ---- Action buttons ----
/obj/item/clothing/suit/armor/ego_gear/lce/ui_action_click(mob/user, datum/action/source)
	if(istype(source, /datum/action/item_action/lce_attune_raise))
		AdjustAttunement(user, attunement_step)
	else if(istype(source, /datum/action/item_action/lce_attune_lower))
		AdjustAttunement(user, -attunement_step)
	else if(istype(source, /datum/action/item_action/lce_attune_step))
		CycleStep(user)
	else if(istype(source, /datum/action/item_action/lce_locate))
		LocateOrSummon(user)

/obj/item/clothing/suit/armor/ego_gear/lce/proc/AdjustAttunement(mob/user, delta)
	attunement = clamp(attunement + delta, 0, 100)
	RefreshAttunement(user)
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	balloon_alert(user, "attunement [attunement]% (safe [safe_limit]%)")

/obj/item/clothing/suit/armor/ego_gear/lce/proc/CycleStep(mob/user)
	switch(attunement_step)
		if(1)
			attunement_step = 5
		if(5)
			attunement_step = 10
		else
			attunement_step = 1
	UpdateStepIcon()
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	balloon_alert(user, "step [attunement_step]%")

/obj/item/clothing/suit/armor/ego_gear/lce/proc/UpdateStepIcon()
	for(var/datum/action/item_action/lce_attune_step/S in actions)
		S.button_icon_state = "step_[attunement_step]"
		S.UpdateButtonIcon()

// ---- Locate / summon the paired weapon ----
/obj/item/clothing/suit/armor/ego_gear/lce/proc/LocateOrSummon(mob/living/user)
	if(tracked_weapon && get_turf(tracked_weapon))
		PointToWeapon(user)
	else
		SummonWeapon(user)

// A short trail of sparks toward the dropped weapon, in the rose_sign style.
/obj/item/clothing/suit/armor/ego_gear/lce/proc/PointToWeapon(mob/living/user)
	var/turf/uturf = get_turf(user)
	var/turf/wturf = get_turf(tracked_weapon)
	if(!uturf || !wturf)
		return
	if(uturf.z != wturf.z)
		to_chat(user, span_warning("[tracked_weapon] is beyond your senses."))
		return
	var/turf/step_turf = uturf
	for(var/i in 1 to 8)
		if(step_turf == wturf)
			break
		step_turf = get_step_towards(step_turf, wturf)
		if(!step_turf)
			break
		new /obj/effect/temp_visual/cult/sparks(step_turf)
	to_chat(user, span_notice("You sense [tracked_weapon] to the [dir2text(get_dir(uturf, wturf))]."))

/obj/item/clothing/suit/armor/ego_gear/lce/proc/SummonWeapon(mob/living/user)
	if(!paired_weapon)
		return
	if(world.time < summon_cooldown)
		to_chat(user, span_warning("You cannot recall your EGO weapon again so soon."))
		return
	summon_cooldown = world.time + weapon_summon_cooldown
	SpawnPairedWeapon(get_turf(user))
	if(tracked_weapon)
		user.put_in_hands(tracked_weapon)
		to_chat(user, span_notice("You manifest [tracked_weapon] into your grip."))

// ---- Examine ----
/obj/item/clothing/suit/armor/ego_gear/lce/examine(mob/user)
	. = ..()
	. += span_notice("Attunement: [attunement]% (adjust step: [attunement_step]%).")
	if(ishuman(user))
		var/yours = SafeLimitFor(user)
		if(user.get_item_by_slot(ITEM_SLOT_OCLOTHING) == src)
			. += span_notice("Your safe attunement limit for this EGO is [yours]%. Past it, your mind and body pay the price.")
		else
			. += span_notice("Were you to wear this, your safe attunement limit would be [yours]%. It rises with your bond to the source abnormality.")
	else
		. += span_notice("How high it can be safely attuned depends on the wearer's bond with the source abnormality.")

// ---- The four worn action buttons ----
/datum/action/item_action/lce_attune_raise
	name = "Raise Attunement"
	desc = "Raise your EGO attunement by the current step."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "attune_up"

/datum/action/item_action/lce_attune_lower
	name = "Lower Attunement"
	desc = "Lower your EGO attunement by the current step."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "attune_down"

/datum/action/item_action/lce_attune_step
	name = "Attunement Step"
	desc = "Cycle how much each adjustment changes your attunement (1% / 5% / 10%)."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "step_5"

/datum/action/item_action/lce_locate
	name = "Locate EGO Weapon"
	desc = "Sense your paired weapon if it is dropped, or manifest it into your hands if it was destroyed."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "locate_weapon"

// ==================================================================================
// The LCE armor suits. Each just sets its stat block + attunement_family + paired_weapon.
// ==================================================================================

//All high Security armor adds to 90.
//LOL THE FIRST EGO IS AN ALEPH
/obj/item/clothing/suit/armor/ego_gear/lce/smile
	name = "LCE EGO: Smile"
	desc = "This armor pulsates with hatred or.... something else."
	icon_state = "smile"
	armor = list(RED_DAMAGE = 20, WHITE_DAMAGE = 20, BLACK_DAMAGE = 40, PALE_DAMAGE = 10)
	attunement_family = "smile"
	paired_weapon = /obj/item/ego_weapon/lce/smile

/obj/item/clothing/suit/armor/ego_gear/lce/hornet
	name = "LCE EGO: Hornet"
	desc = "It's covered in a thin layer of pollen."
	icon_state = "hornet"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	attunement_family = "hornet"
	paired_weapon = /obj/item/ego_weapon/lce/hornet

//Low-Sec armor adds to 60.
/obj/item/clothing/suit/armor/ego_gear/lce/grinder
	name = "LCE EGO: Grinder MK 4"
	desc = "The broach glows with a soft light."
	icon_state = "grinder"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = -10, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	attunement_family = "grinder"
	paired_weapon = /obj/item/ego_weapon/lce/grinder

/obj/item/clothing/suit/armor/ego_gear/lce/unrequited
	name = "LCE EGO: Unrequited Love"
	desc = "The armor is covered in scales, as if scaled like a fish."
	icon_state = "unrequited"
	armor = list(RED_DAMAGE = -10, WHITE_DAMAGE = 30, BLACK_DAMAGE = 20, PALE_DAMAGE = 20)
	attunement_family = "unrequited"
	paired_weapon = /obj/item/ego_weapon/lce/unrequited

/obj/item/clothing/suit/armor/ego_gear/lce/beak
	name = "LCE EGO: Beak"
	desc = "The fabric looks to be an unremarkable quality, as if it's regular clothes."
	icon_state = "beak"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 30, BLACK_DAMAGE = -10, PALE_DAMAGE = 10)
	attunement_family = "beak"
	paired_weapon = /obj/item/ego_weapon/ranged/lce/beak

/obj/item/clothing/suit/armor/ego_gear/lce/prank
	name = "LCE EGO: Prank"
	desc = "A dress that smells of long-gone candy."
	icon_state = "prank"
	armor = list(RED_DAMAGE = 10, WHITE_DAMAGE = 10, BLACK_DAMAGE = 30, PALE_DAMAGE = 10)
	attunement_family = "prank"
	paired_weapon = /obj/item/ego_weapon/lce/prank

/obj/item/clothing/suit/armor/ego_gear/lce/match
	name = "LCE EGO: Fourth Match Flame"
	desc = "The suit glows with an otherworldly light."
	icon_state = "match"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 10, BLACK_DAMAGE = 10, PALE_DAMAGE = 10)
	attunement_family = "match"
	paired_weapon = /obj/item/ego_weapon/lce/match

/obj/item/clothing/suit/armor/ego_gear/lce/trick
	name = "LCE EGO: Hat Trick"
	desc = "The Ace on the back of the suit is embroidered beautifully."
	icon_state = "trick"
	armor = list(RED_DAMAGE = 10, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	attunement_family = "trick"
	paired_weapon = /obj/item/ego_weapon/lce/trick

/obj/item/clothing/suit/armor/ego_gear/lce/love
	name = "LCE EGO: In the Name of Love"
	desc = "A magical one-piece dress. Wearing it stirs something insistent and bright."
	icon_state = "love"
	armor = list(RED_DAMAGE = 20, WHITE_DAMAGE = 10, BLACK_DAMAGE = 40, PALE_DAMAGE = 20)
	attunement_family = "love"
	paired_weapon = /obj/item/ego_weapon/lce/love

/obj/item/clothing/suit/armor/ego_gear/lce/despair
	name = "LCE EGO: Despair"
	desc = "A blue dress stitched from a knight's unspent devotion."
	icon_state = "despair"
	armor = list(RED_DAMAGE = 20, WHITE_DAMAGE = 30, BLACK_DAMAGE = 10, PALE_DAMAGE = 30)
	attunement_family = "despair"
	paired_weapon = /obj/item/ego_weapon/shield/vigil

/obj/item/clothing/suit/armor/ego_gear/lce/acupuncture
	name = "LCE EGO: Acupuncture"
	desc = "Realize that this is good for you."
	icon_state = "acupuncture"
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 10, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	slowdown = -0.15
	attunement_family = "acupuncture"
	paired_weapon = /obj/item/ego_weapon/lce/acupuncture

//The Door to Nowhere's set. Attunement is the chain tension: the tighter it is bound the more
//it turns aside - but past the safe limit it binds, and the wearer slows badly. Carries the
//base EGO's escape.
/obj/item/clothing/suit/armor/ego_gear/lce/liminal
	name = "LCE EGO: Liminal"
	desc = "A mantle crossed with chain, fastened at the chest by a padlock with no keyhole on this side. It smells of old carpet and older regret. \
		At 25% attunement or higher, going insane while wearing it pulls you into the realm of sealed regrets and arriving there cures the panic. \
		The tighter the chain is wound, the sooner it can do it again."
	icon_state = "liminal"
	armor = list(RED_DAMAGE = -10, WHITE_DAMAGE = 40, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	attunement_family = "liminal"
	paired_weapon = /obj/item/ego_weapon/lce/unsent
	/// Movement penalty at 100 points over the safe limit. Nothing at or under it.
	var/overload_slowdown = 1.2
	/// Attunement needed before the suit will catch you at all.
	var/escape_attunement_req = 25
	/// Cooldown at the requirement, and at a full dial. Interpolated between.
	var/escape_cooldown_time = 15 MINUTES
	var/escape_cooldown_min = 5 MINUTES
	var/escape_cooldown = 0
	actions_types = list(
		/datum/action/item_action/lce_attune_raise,
		/datum/action/item_action/lce_attune_lower,
		/datum/action/item_action/lce_attune_step,
		/datum/action/item_action/lce_locate,
		/datum/action/item_action/lce_liminal_hologram,
	)
	/// Attunement needed before the projection unlocks.
	var/hologram_attunement_req = 75
	var/hologram_cooldown_time = 2 MINUTES
	var/hologram_cooldown = 0
	/// Below this fraction of max SP or max health the projection cannot be cast, and an
	/// active one collapses.
	var/hologram_sp_floor = 0.05
	var/hologram_hp_floor = 0.05
	/// Fraction of max health burned per 1% over the safe limit, across hologram_duration.
	var/hologram_overload_hp_per_over = 0.04
	/// How long a projection lasts cast at full SP. The drain is scaled to hit the floor here.
	var/hologram_duration = 10 MINUTES
	var/mob/living/simple_animal/hostile/liminal_hologram/active_hologram
	/// Guard: mind.transfer_to() fires the hologram's Logout(), which recalls.
	var/recalling_hologram = FALSE

// The chain only binds past the safe limit: within your bond the mantle is worn, beyond it you
// are wearing chain. RefreshAttunement is where both the attunement and the safe limit land, so
// the penalty follows either of them changing.
/obj/item/clothing/suit/armor/ego_gear/lce/liminal/RefreshAttunement(mob/living/carbon/human/user)
	. = ..()
	var/over = max(0, attunement - safe_limit)
	slowdown = round(overload_slowdown * (over / 100), 0.01)
	if(istype(user) && user.get_item_by_slot(ITEM_SLOT_OCLOTHING) == src)
		user.update_equipment_speed_mods()

//The base EGO's escape, on a cooldown rather than once per suit: going insane while worn
//drops you into the Realm and the arrival cures the panic.
/obj/item/clothing/suit/armor/ego_gear/lce/liminal/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_OCLOTHING)
		return
	RegisterSignal(user, COMSIG_HUMAN_INSANE, PROC_REF(OnInsanity))

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_HUMAN_INSANE)

//The tighter the chain is wound the faster it can reach for you again: full cooldown at the
//attunement requirement, a third of it at a full dial.
/obj/item/clothing/suit/armor/ego_gear/lce/liminal/proc/CurrentEscapeCooldown()
	var/span = 100 - escape_attunement_req
	var/frac = span > 0 ? clamp((attunement - escape_attunement_req) / span, 0, 1) : 1
	return escape_cooldown_time - (escape_cooldown_time - escape_cooldown_min) * frac

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/proc/OnInsanity(mob/living/carbon/human/panicked_user)
	SIGNAL_HANDLER
	if(attunement < escape_attunement_req)
		to_chat(panicked_user, span_warning("The chains hang slack. There is nothing in them to catch you."))
		return
	if(world.time < escape_cooldown || !AnyDoorToNowhereExists())
		return
	escape_cooldown = world.time + CurrentEscapeCooldown()
	to_chat(panicked_user, span_warning("The chains resonate with your panic, pulling you into a familiar yet alien space..."))
	INVOKE_ASYNC(src, PROC_REF(EmergencyTeleport), panicked_user)
	addtimer(CALLBACK(src, PROC_REF(CurePanic), panicked_user), 1 SECONDS)

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/proc/EmergencyTeleport(mob/living/carbon/human/panicked_user)
	SendToRepentanceDimension(panicked_user, "The chains pull you into the realm of sealed regrets...", FALSE)
	to_chat(panicked_user, span_warning("You are now trapped in the realm of sealed regrets. You will have to find your own way out."))

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/proc/CurePanic(mob/living/carbon/human/H)
	if(!H || QDELETED(H))
		return
	H.adjustWhiteLoss(999, updating_health = TRUE, forced = TRUE, white_healable = TRUE)
	to_chat(H, span_notice("The panic fades as you find yourself in the liminal space. The suit feels oddly comfortable here, like it belongs."))



/*			LIMINAL HOLOGRAM			*/

// At 50% attunement the suit can throw a soft-light copy of its wearer into the Realm, beside
// the door. Built to read like a holosynth: a purple colour cast, a scanline sweeping the
// silhouette, an emissive glow, and a periodic glitch that leaves an afterimage behind.

/datum/action/item_action/lce_liminal_hologram
	name = "Project Through The Door"
	desc = "At 75% attunement or higher, and from inside the realm of sealed regrets, stand a soft-light copy of yourself beside the Door to Nowhere. \
		It burns your SP for as long as it stands - ten minutes from a full bar - and, if the suit is set past your safe limit, your health along with it, faster the further over you are. \
		It collapses at 5% of either, or the moment your body leaves the realm. Press again to come back."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_liminal"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "dtn_project"

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/ui_action_click(mob/user, datum/action/source)
	if(!istype(source, /datum/action/item_action/lce_liminal_hologram))
		return ..()
	if(active_hologram)
		RecallHologram()
		return
	ProjectHologram(user)

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/dropped(mob/user)
	. = ..()
	RecallHologram(TRUE)

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/Destroy()
	RecallHologram(TRUE)
	return ..()

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/proc/ProjectHologram(mob/living/carbon/human/user)
	if(!istype(user) || user.get_item_by_slot(ITEM_SLOT_OCLOTHING) != src)
		return FALSE
	if(attunement < hologram_attunement_req)
		to_chat(user, span_warning("The chains are too slack. You would not carry through at less than [hologram_attunement_req]% attunement."))
		return FALSE
	if(world.time < hologram_cooldown)
		to_chat(user, span_warning("You have nothing left to send through yet."))
		return FALSE
	if(!user.mind || !user.client)
		return FALSE
	if(!istype(get_area(user), /area/fishboat/repentance))
		to_chat(user, span_warning("There is nothing here for the chains to reach through. You have to be inside the door."))
		return FALSE
	if(user.sanityhealth <= user.maxSanity * hologram_sp_floor || user.health <= user.maxHealth * hologram_hp_floor)
		to_chat(user, span_warning("There is not enough of you left to send."))
		return FALSE
	var/mob/living/door = FindDoorToNowhere()
	if(!door || QDELETED(door))
		to_chat(user, span_warning("There is no door to stand beside."))
		return FALSE
	var/turf/destination = get_turf(door)
	if(!destination)
		return FALSE
	for(var/dir in shuffle(GLOB.cardinals.Copy()))
		var/turf/T = get_step(destination, dir)
		if(T && !T.density)
			destination = T
			break
	var/mob/living/simple_animal/hostile/liminal_hologram/H = new(destination)
	H.Build(user, src)
	active_hologram = H
	QuietMindTransfer(user.mind, H)
	user.visible_message(span_warning("[user] goes still, and the light in [src]'s chains goes out."))
	to_chat(H, span_notice("<b>You are standing at the door.</b> You are made of light here - you can hold things, but you cannot hurt anything."))
	return TRUE

/obj/item/clothing/suit/armor/ego_gear/lce/liminal/proc/RecallHologram(abort = FALSE)
	if(!active_hologram || recalling_hologram)
		return FALSE
	recalling_hologram = TRUE
	var/mob/living/simple_animal/hostile/liminal_hologram/H = active_hologram
	var/mob/living/body = H.projector
	if(H.mind)
		if(!body || QDELETED(body) || body.stat == DEAD)
			H.ghostize(FALSE)
		else
			QuietMindTransfer(H.mind, body)
	active_hologram = null
	QDEL_NULL(H)
	hologram_cooldown = world.time + hologram_cooldown_time
	recalling_hologram = FALSE
	if(body && !QDELETED(body))
		to_chat(body, span_notice("The light gathers back into the chains, and you are yourself again."))
	return !abort

// ---- The hologram ----
/mob/living/simple_animal/hostile/liminal_hologram
	name = "hologram"
	desc = "A figure of soft light, standing a little out of step with itself."
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	maxHealth = 100
	health = 100
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	harm_intent_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	attack_verb_continuous = "passes through"
	attack_verb_simple = "pass through"
	response_help_continuous = "passes through"
	response_help_simple = "pass through"
	a_intent = INTENT_HELP
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM)
	dextrous = TRUE
	held_items = list(null, null)
	faction = list("neutral")
	mob_biotypes = MOB_SPIRIT
	density = FALSE
	//Soft-light: windows, grilles and every door are no obstacle. PASSMACHINE is what carries
	//it through solid airlocks - PASSGLASS alone only opens the ones you can see through.
	pass_flags = PASSGLASS | PASSGRILLE | PASSMACHINE | PASSTABLE
	//NOT del_on_death: the parent would delete this mob mid-death() and ghost the player out
	//of it. RecallHologram() does the deleting, after the mind is home.
	del_on_death = FALSE
	light_system = MOVABLE_LIGHT
	light_range = 2
	light_power = 1
	light_color = "#a05ce8"
	/// The wearer this was cast from.
	var/mob/living/carbon/human/projector
	var/obj/item/clothing/suit/armor/ego_gear/lce/liminal/source_armor
	/// The soft-light tint. Multiplied over the copied appearance.
	var/holo_colour = "#7a3fc4"
	var/holo_alpha = 150
	/// world.time the SP drain was last charged, so the rate does not ride on the tick rate.
	var/last_sp_drain = 0
	var/obj/effect/liminal_scanline/scanline
	/// Only ever one at a time: each flicker clears the last and leaves its own behind.
	var/obj/effect/liminal_afterimage/afterimage
	var/glitch_timer

/mob/living/simple_animal/hostile/liminal_hologram/Initialize(mapload)
	. = ..()
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/liminal_hologram/is_literate()
	return TRUE

/// Takes the wearer's whole rendered appearance, then makes it out of light.
/mob/living/simple_animal/hostile/liminal_hologram/proc/Build(mob/living/carbon/human/user, obj/item/clothing/suit/armor/ego_gear/lce/liminal/armor)
	projector = user
	source_armor = armor
	appearance = user.appearance
	name = "[user.real_name] (hologram)"
	real_name = name
	desc = "A figure of soft light in the shape of [user.real_name], standing a little out of step with itself."
	alpha = holo_alpha
	add_atom_colour(holo_colour, FIXED_COLOUR_PRIORITY)
	mouse_opacity = MOUSE_OPACITY_ICON
	//Soft-light edge, so it reads as projected rather than as a tinted person.
	add_filter("holo_edge", 1, outline_filter(1, "#c9a0ff88"))
	last_sp_drain = world.time
	//The armor's own button is on the body, which the player is no longer in.
	var/datum/action/innate/liminal_hologram_return/R = new
	R.Grant(src)
	StartScanline()
	ScheduleGlitch()

/mob/living/simple_animal/hostile/liminal_hologram/Destroy()
	//Backstop for anything that deletes the hologram without going through the armor.
	if(source_armor && source_armor.active_hologram == src)
		source_armor.RecallHologram(TRUE)
	deltimer(glitch_timer)
	if(scanline)
		vis_contents -= scanline
		QDEL_NULL(scanline)
	QDEL_NULL(afterimage)
	projector = null
	source_armor = null
	return ..()

/mob/living/simple_animal/hostile/liminal_hologram/death(gibbed)
	//Home before the death chain runs, not after - it ends with this mob gone.
	if(source_armor && !QDELETED(source_armor))
		source_armor.RecallHologram(TRUE)
		return
	return ..()

/mob/living/simple_animal/hostile/liminal_hologram/Logout()
	. = ..()
	if(source_armor && !QDELETED(source_armor))
		source_armor.RecallHologram(TRUE)

/mob/living/simple_animal/hostile/liminal_hologram/Life()
	. = ..()
	if(!source_armor)
		return
	//The projection is cast off a living wearer standing inside the Realm. It outlasts neither.
	if(!projector || QDELETED(projector) || projector.stat == DEAD)
		source_armor.RecallHologram(TRUE)
		return
	if(!istype(get_area(projector), /area/fishboat/repentance))
		to_chat(src, span_userdanger("Your body has stepped outside. The light lets go of you."))
		source_armor.RecallHologram(TRUE)
		return
	DrainProjector()

/// Charges SP - and, past the safe attunement limit, health - against real elapsed time. A
/// full SP bar buys exactly hologram_duration; the health burn scales with how far over the
/// limit the suit is set, so an unearned 75% attunement cuts that short.
/mob/living/simple_animal/hostile/liminal_hologram/proc/DrainProjector()
	var/elapsed = world.time - last_sp_drain
	if(elapsed <= 0)
		return
	last_sp_drain = world.time
	var/fraction = elapsed / source_armor.hologram_duration
	projector.adjustSanityLoss(projector.maxSanity * (1 - source_armor.hologram_sp_floor) * fraction)
	var/over = source_armor.attunement - source_armor.safe_limit
	if(over > 0)
		//Direct BRUTE, like the rest of the overload backlash, so EGO resistances cannot soak it.
		projector.adjustBruteLoss(projector.maxHealth * over * source_armor.hologram_overload_hp_per_over * fraction)
	if(projector.sanityhealth <= projector.maxSanity * source_armor.hologram_sp_floor)
		to_chat(src, span_userdanger("There is nothing left of you to hold the shape."))
		source_armor.RecallHologram(TRUE)
		return
	if(projector.health <= projector.maxHealth * source_armor.hologram_hp_floor)
		to_chat(src, span_userdanger("Your body cannot pay for this any longer."))
		source_armor.RecallHologram(TRUE)

/// The scanlines ride in vis_contents and are clipped to our silhouette by a render_source
/// alpha mask, the same way the LCE claw's scan does - an icon() mask only covers 32x32.
/mob/living/simple_animal/hostile/liminal_hologram/proc/StartScanline()
	//The leading * matters: without it the atom renders ONLY into the buffer and stops being
	//drawn in the world.
	if(!render_target)
		render_target = "*holo_[REF(src)]"
	scanline = new(src)
	scanline.filters += filter(type = "alpha", render_source = render_target)
	vis_contents += scanline
	//Scrolls by exactly one line period, so the loop point is invisible. The sheet is twice
	//the tile height, so the scroll never uncovers the top of the sprite.
	animate(scanline, pixel_y = -4, time = 1.5 SECONDS, loop = -1)

/mob/living/simple_animal/hostile/liminal_hologram/proc/ScheduleGlitch()
	glitch_timer = addtimer(CALLBACK(src, PROC_REF(StartGlitch)), rand(10 SECONDS, 15 SECONDS), TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/liminal_hologram/proc/StartGlitch()
	INVOKE_ASYNC(src, PROC_REF(GlitchBurst)) //The burst sleeps between hops; timers must not.

/mob/living/simple_animal/hostile/liminal_hologram/proc/GlitchBurst()
	for(var/i in 1 to rand(3, 5))
		Flicker(rand(-10, 10), rand(-10, 10))
		sleep(rand(1, 3))
		if(QDELETED(src))
			return
	Flicker(0, 0) //Settles back onto its own tile, leaving the last smear where it was.
	addtimer(CALLBACK(src, PROC_REF(FadeAfterimage), afterimage), 1 SECONDS)
	ScheduleGlitch()

/// The trailing smear is the only one with no next flicker to clear it, so it fades on a timer.
/mob/living/simple_animal/hostile/liminal_hologram/proc/FadeAfterimage(obj/effect/liminal_afterimage/target)
	if(afterimage == target)
		QDEL_NULL(afterimage)

/// Drops an afterimage where we are and jumps to the given offset. The previous afterimage is
/// cleared here, so each one lasts until the next flicker within the burst.
/mob/living/simple_animal/hostile/liminal_hologram/proc/Flicker(new_x, new_y)
	QDEL_NULL(afterimage)
	afterimage = new(get_turf(src))
	afterimage.appearance = appearance
	afterimage.render_target = null //Copied with the appearance; two atoms cannot share one.
	afterimage.alpha = 55
	afterimage.transform = matrix() * 0.85
	afterimage.pixel_x = pixel_x
	afterimage.pixel_y = pixel_y
	pixel_x = new_x
	pixel_y = new_y

/datum/action/innate/liminal_hologram_return
	name = "Return To Your Body"
	desc = "Let the light go and wake up where you left yourself."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_liminal"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "dtn_return"

/datum/action/innate/liminal_hologram_return/Activate()
	var/mob/living/simple_animal/hostile/liminal_hologram/H = owner
	if(!istype(H) || !H.source_armor || QDELETED(H.source_armor))
		return FALSE
	return H.source_armor.RecallHologram()

/obj/effect/liminal_scanline
	icon = 'ModularLobotomy/_Lobotomyicons/lce_hologram.dmi'
	icon_state = "holo_scanlines"
	alpha = 130
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID
	plane = FLOAT_PLANE
	layer = FLOAT_LAYER
	appearance_flags = KEEP_TOGETHER
	anchored = TRUE

/obj/effect/liminal_afterimage
	name = "afterimage"
	desc = "A smear of soft light where something was a moment ago."
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
