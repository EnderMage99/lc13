// LCE weapons. They read their paired worn armor's attunement to scale damage, and take
// a flat penalty (and no scaling) if the matching armor isn't worn. There are two bases:
// a melee base (/obj/item/ego_weapon/lce) and a ranged base (/obj/item/ego_weapon/ranged/lce)
// that scales bullet damage - future LCE guns should subtype the ranged base.

// ============================ MELEE BASE ============================
/obj/item/ego_weapon/lce
	icon = 'icons/obj/lce_egoweapons.dmi'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)
	/// Must match the paired armor's family for the buffs to apply.
	var/attunement_family = ""
	/// Bonus damage at 100% attunement (1 = +100% force).
	var/max_damage_bonus = 1
	/// Damage cut when the matching armor isn't worn (0.5 = -50%).
	var/no_armor_penalty = 0.5

// The attunement-scaled force this weapon should hit for right now. Gimmick weapons that
// deal extra hits reuse this so their bonus damage scales too.
/obj/item/ego_weapon/lce/proc/AttunedForce(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		return round(force * (1 - no_armor_penalty)) // No matching armor: weak and unscaled.
	return round(force * (1 + max_damage_bonus * armor.attunement / 100))

/obj/item/ego_weapon/lce/attack(mob/living/target, mob/living/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	var/saved_force = force
	force = AttunedForce(user)
	. = ..()
	force = saved_force
	if(armor)
		armor.HandleOverLimit(user) // Over-limit recoil, rate-limited on the armor.

// ============================ MELEE WEAPONS ============================
/obj/item/ego_weapon/lce/smile
	name = "LCE EGO: Smile"
	desc = "Putting your hands into it is rather unpleasant."
	special = "This weapon hits a second time after a windup that heals the user."
	icon_state = "smile"
	force = 40
	attack_speed = 1.6
	damtype = BLACK_DAMAGE
	hitsound = 'sound/weapons/ego/hammer.ogg'
	attunement_family = "smile"

/obj/item/ego_weapon/lce/smile/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	. = ..() // First hit, scaled + over-limit recoil handled by the LCE base.
	if(do_after(user, 12, src))
		if(QDELETED(target))
			return
		var/hit_force = AttunedForce(user) // Second hit scales with attunement too.
		target.deal_damage(hit_force, BLACK_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE))
		playsound(src, 'sound/weapons/fixer/generic/gen2.ogg', 100, TRUE)
		user.adjustBruteLoss(-hit_force/3)
	else
		to_chat(user, "<span class= 'spider'><b>Your attack was interrupted!</b></span>")
		balloon_alert(user, "Your attack was interrupted!")

/obj/item/ego_weapon/lce/hornet
	name = "LCE EGO: Hornet"
	desc = "A stinger honed to a wicked point."
	icon_state = "hornet"
	force = 34
	attack_speed = 1
	damtype = RED_DAMAGE
	attunement_family = "hornet"

//Grinder is supposed to be like the chainswords in Darktide.
/obj/item/ego_weapon/lce/grinder
	name = "LCE EGO: Grinder MK 4"
	desc = "A chainsword that reminds you of something..."
	special = "Use this weapon in hand to rev it up, making it attack 4 times in succession."
	icon_state = "grinder"
	force = 17
	attack_speed = 1 //has a very low DPS so that they can rev it up for multihits
	damtype = RED_DAMAGE
	attack_verb_continuous = list("slices", "saws", "rips")
	attack_verb_simple = list("slice", "saw", "rip")
	hitsound = 'sound/abnormalities/helper/attack.ogg'
	attunement_family = "grinder"
	var/chainsaw_amount = 4
	var/revved = FALSE
	var/saw_speed = 3

/obj/item/ego_weapon/lce/grinder/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE
	if(revved)
		stuntime = 10
	. = ..() // LCE base scales the hit and handles the over-limit recoil.
	if(revved)
		chainsaw_amount--
		if(chainsaw_amount)
			addtimer(CALLBACK(src, PROC_REF(attack), target, user), saw_speed)
		else
			stuntime = 0
			revved = FALSE
			chainsaw_amount = initial(chainsaw_amount)

/obj/item/ego_weapon/lce/grinder/attack_self(mob/living/user)
	if(!revved)
		revved = TRUE
		to_chat(user, span_warning("You rev up Grinder MK4."))
		balloon_alert(user, "You rev up Grinder MK4.")
	else
		revved = FALSE
		to_chat(user, span_warning("You shut off Grinder MK4."))
		balloon_alert(user, "You shut off Grinder MK4.")
	..()

/obj/item/ego_weapon/lce/unrequited
	name = "LCE EGO: Unrequited Love"
	desc = "A knife that looks like it's made from sharpened bone."
	special = "Use this weapon in hand to dodgeroll."
	icon_state = "unrequited"
	force = 26
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = WHITE_DAMAGE
	hitsound = 'sound/weapons/fixer/generic/knife2.ogg'
	attunement_family = "unrequited"
	var/dodgelanding

/obj/item/ego_weapon/lce/unrequited/attack_self(mob/living/carbon/user)
	if(user.dir == 1)
		dodgelanding = locate(user.x, user.y + 5, user.z)
	if(user.dir == 2)
		dodgelanding = locate(user.x, user.y - 5, user.z)
	if(user.dir == 4)
		dodgelanding = locate(user.x + 5, user.y, user.z)
	if(user.dir == 8)
		dodgelanding = locate(user.x - 5, user.y, user.z)
	user.adjustStaminaLoss(20, TRUE, TRUE)
	user.throw_at(dodgelanding, 3, 2, spin = TRUE)

/obj/item/ego_weapon/lce/prank
	name = "LCE EGO: Prank"
	desc = "A prop that turned out to be entirely real."
	icon_state = "prank"
	force = 24
	attack_speed = 1
	damtype = BLACK_DAMAGE
	attunement_family = "prank"

/obj/item/ego_weapon/lce/match
	name = "LCE EGO: Fourth Match Flame"
	desc = "It smolders with a light that never quite goes out."
	icon_state = "match"
	force = 28
	attack_speed = 1
	damtype = RED_DAMAGE
	attunement_family = "match"

/obj/item/ego_weapon/lce/trick
	name = "LCE EGO: Hat Trick"
	desc = "A card's edge, sharpened until it bites."
	icon_state = "trick"
	force = 24
	attack_speed = 0.9
	damtype = WHITE_DAMAGE
	attunement_family = "trick"

/obj/item/ego_weapon/lce/acupuncture
	name = "LCE EGO: Acupuncture"
	desc = "One man's medicine is another man's poison."
	special = "Inject yourself (use in hand): take toxic damage but gain a JUSTICE damage buff and inflict 2 Mental Decay on hit for 5 seconds."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/branch12_weapon.dmi'
	icon_state = "acupuncture"
	force = 20
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_THRUST
	attack_verb_continuous = list("jabs", "stabs")
	attack_verb_simple = list("jab", "stab")
	hitsound = 'sound/weapons/fixer/generic/nail1.ogg'
	attunement_family = "acupuncture"
	var/inject_cooldown = 0
	var/inject_cooldown_time = 5.1 SECONDS
	var/justice_buff = 30
	var/normal_mental_decay_inflict = 2
	var/mental_decay_inflict = 0

/obj/item/ego_weapon/lce/acupuncture/attack(mob/living/target, mob/living/user)
	. = ..() // LCE base scales the hit and handles the over-limit recoil.
	if(isliving(target))
		if(mental_decay_inflict > 0)
			target.apply_lc_mental_decay(mental_decay_inflict)

/obj/item/ego_weapon/lce/acupuncture/attack_self(mob/user)
	if(!CanUseEgo(user))
		return
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/drugie = user
	if(inject_cooldown < world.time)
		inject_cooldown = world.time + inject_cooldown_time
		drugie.set_drugginess(15)
		drugie.adjustToxLoss(3)
		to_chat(drugie, span_nicegreen("Wow... I can taste the colors..."))
		mental_decay_inflict = normal_mental_decay_inflict
		if(prob(20))
			drugie.emote(pick("twitch", "drool", "moan", "giggle"))
		drugie.adjust_attribute_buff(JUSTICE_ATTRIBUTE, justice_buff)
		addtimer(CALLBACK(src, PROC_REF(RemoveBuff), drugie), 5 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	else
		to_chat(drugie, span_boldwarning("[src] has not refueled yet."))

/obj/item/ego_weapon/lce/acupuncture/proc/RemoveBuff(mob/user)
	var/mob/living/carbon/human/human = user
	mental_decay_inflict = 0
	human.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -justice_buff)

// ============================ RANGED BASE ============================
// Scales its bullets' damage with the worn matching armor's attunement. Future LCE guns
// subtype this and just set their projectile/ammo stats.
/obj/item/ego_weapon/ranged/lce
	icon = 'icons/obj/lce_egoweapons.dmi'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)
	/// Must match the paired armor's family for the buffs to apply.
	var/attunement_family = ""
	/// Bonus bullet damage at 100% attunement (0.5 = +50%).
	var/max_damage_bonus = 0.5
	/// Bullet damage cut when the matching armor isn't worn (0.5 = -50%).
	var/no_armor_penalty = 0.5

// before_firing runs right before each projectile is created, so we set the damage
// multiplier here from the current attunement.
/obj/item/ego_weapon/ranged/lce/before_firing(atom/target, mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		projectile_damage_multiplier = initial(projectile_damage_multiplier) * (1 - no_armor_penalty)
	else
		projectile_damage_multiplier = initial(projectile_damage_multiplier) * (1 + max_damage_bonus * armor.attunement / 100)
		armor.HandleOverLimit(user)
	return ..()

// ============================ RANGED WEAPONS ============================
// Beak - a two-handed shotgun paired with the Beak armor.
/obj/item/ego_weapon/ranged/lce/beak
	name = "LCE EGO: Beak"
	desc = "A stout scattergun that spits a cone of shot."
	icon_state = "beak"
	force = 12
	damtype = RED_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_beak
	weapon_weight = WEAPON_HEAVY
	fire_delay = 10
	shotsleft = 6
	reloadtime = 1.6 SECONDS
	pellets = 6
	variance = 20
	randomspread = 0
	fire_sound = 'sound/weapons/gun/shotgun/shot.ogg'
	attunement_family = "beak"

// Love and Hate - the Queen of Hatred's set. A pair of gauntlets that read the wearer's mind
// and change with it: steady and WHITE while they are holding together, BLACK and harder
// when they are not.
//
// DPS is held at the high-sec LCE line rather than raised: 21 force / 0.6 attack_speed = 35,
// which sits between hornet (34/1.0 = 34) and despair (30/0.8 = 37.5). The gloves are fast
// and light, not strong - the 20% is what you get for being in a bad way, and it rides on
// AttunedForce so it scales with attunement instead of being a flat bonus on top.
/obj/item/ego_weapon/lce/love
	name = "LCE EGO: Love and Hate"
	desc = "A pair of slim gauntlets. They sit warm against the knuckles, and go cold when you do."
	special = "While your Sanity is below half: Damage becomes BLACK and hits 20% harder."
	icon_state = "lovehate_love"
	force = 21
	attack_speed = 0.6
	damtype = WHITE_DAMAGE
	hitsound = 'sound/weapons/fixer/generic/dodge3.ogg'
	attack_verb_continuous = list("strikes", "punches", "jabs")
	attack_verb_simple = list("strike", "punch", "jab")
	attunement_family = "love"
	/// Below this fraction of max Sanity the gloves flip to Hate.
	var/hate_threshold = 0.5
	/// Damage multiplier while in Hate. Applied inside AttunedForce so attunement still scales it.
	var/hate_damage_mult = 1.2
	/// Current state, so the swap only fires on an actual change.
	var/hating = FALSE

/obj/item/ego_weapon/lce/love/proc/UpdateMood(mob/living/carbon/human/H)
	var/should_hate = FALSE
	if(ishuman(H) && H.maxSanity)
		should_hate = (H.sanityhealth / H.maxSanity) < hate_threshold
	if(should_hate == hating)
		return FALSE
	hating = should_hate
	damtype = hating ? BLACK_DAMAGE : WHITE_DAMAGE
	icon_state = hating ? "lovehate_hate" : "lovehate_love"
	update_icon()
	if(ishuman(H))
		H.update_inv_hands() // The inhand sprite follows icon_state, so it has to be refreshed too.
		if(hating)
			to_chat(H, span_warning("The gauntlets go cold in your hands. Whatever was holding you together isn't."))
		else
			to_chat(H, span_nicegreen("The gauntlets warm again. You have got yourself back."))
	return TRUE

// Read the wearer on pickup, so the gloves show the right face the moment they are held
// rather than waiting for the first punch to correct themselves.
/obj/item/ego_weapon/lce/love/equipped(mob/user, slot)
	. = ..()
	UpdateMood(user)

// The other place - and the only one that matters for damage. No signal, no processing: the
// gloves look at whoever is swinging them, immediately before the swing lands. Because this
// runs ahead of ..(), the damage type and the 20% are always correct on every hit.
/obj/item/ego_weapon/lce/love/attack(mob/living/target, mob/living/user)
	UpdateMood(user)
	return ..()

/obj/item/ego_weapon/lce/love/AttunedForce(mob/user)
	. = ..()
	if(hating)
		. = round(. * hate_damage_mult)
	return .

// ============================ SHIELD-BASED LCE ============================
// Vigil - the Knight of Despair's set. A tower shield instead of her rapier: she does not
// fight for herself, she stands in front of someone.
//
// It sits on the SHIELD base, not the LCE melee base. DM is single-inheritance and the two
// bases are siblings, so the LCE attunement glue (family, scaled force, over-limit recoil)
// is repeated below rather than inherited. It is kept deliberately identical to
// /obj/item/ego_weapon/lce so the two never drift apart in behaviour.
//
// Gimmick: blocking stores charges, and a charge calls one of the Knight's rapiers out of
// the air. Blocking is the only way to arm it, so the weapon only pays out for players who
// actually stand and take the hit.
/obj/item/ego_weapon/shield/vigil
	name = "LCE EGO: Vigil"
	desc = "A tower shield of black plate, its face split by a single steel tear."
	special = "Blocking a source of damage stores a charge. Click a living target while holding a charge \
		to call a rapier out of the air: it takes half a second to form, then flies at wherever its \
		quarry is standing by then. No cooldown beyond the charges themselves. Attunement raises both \
		the rapiers' damage and how many charges you can hold (3 to 7)."
	icon = 'icons/obj/lce_egoweapons.dmi'
	// One state, deliberately: the cracked face is the best of the three and a shield that
	// never changes needs no others. vigil / vigil_raised were dropped from the sheet.
	icon_state = "vigil_cracked"
	force = 45
	attack_speed = 3
	damtype = WHITE_DAMAGE
	hitsound = 'sound/weapons/ego/shield1.ogg'
	reductions = list(30, 25, 25, 20) // 100 total, PALE held to 20 per the shield table's shape.
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)
	// --- LCE glue, mirroring /obj/item/ego_weapon/lce ---
	/// Must match the paired armor's family for any of the scaling to apply.
	var/attunement_family = "despair"
	/// Bonus damage at 100% attunement (1 = +100%). Applies to the shield AND the rapiers.
	var/max_damage_bonus = 1
	/// Damage cut when the matching armor isn't worn.
	var/no_armor_penalty = 0.5
	// --- Charges ---
	/// Stored blocks, spent one per summoned rapier.
	var/charges = 0
	/// Charge cap at 0% and at 100% attunement; interpolated in between.
	var/min_max_charges = 3
	var/max_max_charges = 7
	/// Base PALE damage of a summoned rapier before attunement scaling.
	var/rapier_damage = 25
	/// How long a rapier takes to form before it flies.
	var/rapier_delay = 0.5 SECONDS

/obj/item/ego_weapon/shield/vigil/examine(mob/user)
	. = ..()
	. += span_notice("Stored blocks: <b>[charges]/[MaxCharges(user)]</b>.")

// ---- The LCE scaling, same shape as the melee base's ----
/obj/item/ego_weapon/shield/vigil/proc/AttunedForce(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		return round(force * (1 - no_armor_penalty))
	return round(force * (1 + max_damage_bonus * armor.attunement / 100))

/obj/item/ego_weapon/shield/vigil/attack(mob/living/target, mob/living/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	var/saved_force = force
	force = AttunedForce(user)
	. = ..()
	force = saved_force
	if(armor)
		armor.HandleOverLimit(user)

/obj/item/ego_weapon/shield/vigil/proc/AttunedRapierDamage(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		return round(rapier_damage * (1 - no_armor_penalty))
	return round(rapier_damage * (1 + max_damage_bonus * armor.attunement / 100))

/obj/item/ego_weapon/shield/vigil/proc/MaxCharges(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		return min_max_charges
	return min_max_charges + round((max_max_charges - min_max_charges) * armor.attunement / 100)

// ---- Earning charges: every blocked source of damage is one ----
/obj/item/ego_weapon/shield/vigil/proc/GainCharge(mob/living/user)
	var/cap = MaxCharges(user)
	if(charges >= cap)
		return FALSE
	charges++
	playsound(get_turf(src), 'sound/weapons/ego/rapier1.ogg', 25, TRUE)
	balloon_alert(user, "vigil [charges]/[cap]")
	return TRUE

// A blocked hit. The parent's own guard is repeated rather than read off block_success,
// because that flag stays TRUE for the rest of the block window - it says "this block caught
// something at some point", not "this particular hit landed on the shield".
// No SIGNAL_HANDLER here: it expands to `set SpacemanDMM_should_not_sleep`, which is only
// legal on a proc's initial definition. The parent declares it and overrides inherit it - so
// the must-not-sleep contract still applies to this body, it just cannot be restated.
/obj/item/ego_weapon/shield/vigil/AnnounceBlock(datum/source, damage, damagetype, def_zone)
	var/mob/living/carbon/human/H = source
	var/blocked_it = ishuman(source) && H.is_holding(src)
	. = ..()
	if(blocked_it)
		GainCharge(H)

// A deflected projectile counts too - it is still the shield eating a source of damage.
/obj/item/ego_weapon/shield/vigil/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	. = ..()
	if(attack_type == PROJECTILE_ATTACK && attacking)
		GainCharge(owner)

// ---- Spending them: click anything living ----
/obj/item/ego_weapon/shield/vigil/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!isliving(target) || target == user || !ishuman(user))
		return
	if(charges <= 0)
		return
	if(!CanUseEgo(user))
		return
	charges--
	SummonRapier(user, target)

/obj/item/ego_weapon/shield/vigil/proc/SummonRapier(mob/living/user, mob/living/target)
	var/turf/origin = get_step(get_turf(user), pick(GLOB.cardinals))
	if(!origin || origin.density)
		origin = get_turf(user)
	if(!origin)
		return
	var/obj/projectile/despair_rapier/vigil/P = new(origin)
	P.damage = AttunedRapierDamage(user)
	P.firer = user
	P.starting = origin
	P.fired_from = origin
	playsound(get_turf(user), 'sound/abnormalities/despairknight/attack.ogg', 35, FALSE, 3)
	// Calling a rapier is as much of a strain as swinging the shield, so it burns an
	// over-attuned wearer exactly like a melee hit does. HandleOverLimit is rate-limited on
	// the armor itself, so this shares one cooldown with her attacks rather than stacking.
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(armor)
		armor.HandleOverLimit(user)
	balloon_alert(user, "vigil [charges]/[MaxCharges(user)]")
	addtimer(CALLBACK(src, PROC_REF(LaunchRapier), P, target, origin), rapier_delay)

/obj/item/ego_weapon/shield/vigil/proc/LaunchRapier(obj/projectile/P, atom/target, turf/origin)
	if(QDELETED(P))
		return
	if(QDELETED(target) || !origin)
		qdel(P)
		return
	// Aimed where the quarry is NOW, not where they stood when it was called. Half a second
	// is long enough to walk out of the line, which is what makes it a telegraph.
	P.yo = target.y - origin.y
	P.xo = target.x - origin.x
	P.original = target
	P.preparePixelProjectile(target, origin)
	P.fire()

// The rapiers Vigil calls. PALE like the Knight's own, but their damage is set per-instance
// from the wearer's attunement rather than being fixed on the type.
/obj/projectile/despair_rapier/vigil
	damage = 25
	spread = 0

/obj/projectile/despair_rapier/vigil/Initialize()
	. = ..()
	animate(src, alpha = 255, time = 5) // Half a second to form, matching rapier_delay.
