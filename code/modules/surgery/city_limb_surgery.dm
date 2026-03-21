/// Surgery to mend damaged limbs on city maps, healing bodypart brute/burn damage.
/// Only available when the targeted limb has accumulated damage.
/datum/surgery/mend_limb
	name = "Mend Limb"
	desc = "A surgical procedure to mend an injured or mangled limb, restoring it to working condition."
	steps = list(
		/datum/surgery_step/incise/nobleed,
		/datum/surgery_step/mend_limb,
		/datum/surgery_step/close
	)
	target_mobtypes = list(/mob/living/carbon/human)
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	requires_real_bodypart = TRUE
	requires_bodypart_type = FALSE
	ignore_clothes = TRUE

/datum/surgery/mend_limb/can_start(mob/user, mob/living/carbon/human/target)
	if(!(SSmaptype.maptype in SSmaptype.citymaps))
		return FALSE
	if(!istype(target))
		return FALSE
	if(!..())
		return FALSE
	var/obj/item/bodypart/BP = target.get_bodypart(user.zone_selected)
	if(!BP)
		return FALSE
	// Only show if the limb has damage
	if(BP.brute_dam <= 0 && BP.burn_dam <= 0)
		return FALSE
	return TRUE

/// The actual mending step — heals bodypart damage over multiple repeats
/datum/surgery_step/mend_limb
	name = "mend limb"
	implements = list(TOOL_HEMOSTAT = 100, /obj/item/stack/medical/bone_gel = 100, TOOL_SCREWDRIVER = 65, /obj/item/pen = 55)
	repeatable = TRUE
	time = 30
	/// Base amount of brute healed per step
	var/heal_amount = 25

/datum/surgery_step/mend_limb/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/bodypart/BP = target.get_bodypart(target_zone)
	if(!BP || (BP.brute_dam <= 0 && BP.burn_dam <= 0))
		to_chat(user, span_notice("[target]'s [parse_zone(target_zone)] doesn't need mending."))
		return -1
	display_results(user, target, span_notice("You begin to mend [target]'s [BP.name]..."),
		span_notice("[user] begins to mend [target]'s [BP.name] with [tool]."),
		span_notice("[user] begins to mend [target]'s [BP.name]."))

/datum/surgery_step/mend_limb/initiate(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail = FALSE)
	if(!..())
		return
	var/obj/item/bodypart/BP = target.get_bodypart(target_zone)
	// Keep repeating while the limb has damage
	while(BP && (BP.brute_dam > 0 || BP.burn_dam > 0))
		if(!..())
			break

/datum/surgery_step/mend_limb/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	var/obj/item/bodypart/BP = target.get_bodypart(target_zone)
	if(!BP)
		return ..()
	var/brute_to_heal = min(BP.brute_dam, heal_amount)
	var/burn_to_heal = min(BP.burn_dam, heal_amount)
	BP.heal_damage(brute_to_heal, burn_to_heal)
	display_results(user, target, span_notice("You mend some of the damage on [target]'s [BP.name]."),
		span_notice("[user] mends some of the damage on [target]'s [BP.name] with [tool]."),
		span_notice("[user] mends some of the damage on [target]'s [BP.name]."))
	if(BP.brute_dam <= 0 && BP.burn_dam <= 0)
		to_chat(user, span_notice("[target]'s [BP.name] is fully mended."))
		to_chat(target, span_notice("Your [BP.name] feels much better!"))
	return ..()

/datum/surgery_step/mend_limb/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/bodypart/BP = target.get_bodypart(target_zone)
	if(!BP)
		return FALSE
	display_results(user, target, span_warning("You screwed up and hurt [target]'s [BP.name]!"),
		span_warning("[user] screws up, damaging [target]'s [BP.name]!"),
		span_notice("[user] mends some of the damage on [target]'s [BP.name]."))
	BP.receive_damage(heal_amount * 0.5, 0)
	return FALSE
