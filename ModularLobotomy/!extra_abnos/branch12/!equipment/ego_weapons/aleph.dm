
// --------ALEPH---------
//Pulsating Insanity
/obj/item/ego_weapon/branch12/mini/insanity
	name = "pulsating insanity"
	desc = "I could scarcely contain my feelings of triumph"
	special = "Upon hitting living target, the attacker would inflict a low amount of bleed. When this weapon is thrown, if it hits a mob you will teleport to the weapon and instantly pick it up. Also, the throwing attack deals an extra 10% more damager per bleed on target. (Max of 500% more damage)"
	icon_state = "insanity"
	force = 48
	swingstyle = WEAPONSWING_LARGESWEEP
	throwforce = 96
	throw_speed = 5
	throw_range = 7
	damtype = PALE_DAMAGE
	attack_verb_continuous = list("jabs")
	attack_verb_simple = list("jabs")
	hitsound = 'sound/weapons/slashmiss.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/inflicted_bleed = 2
	var/detonate_cooldown
	var/detonate_cooldown_time = 5 SECONDS
	var/extra_damage_per_bleed = 0.1

/obj/item/ego_weapon/branch12/mini/insanity/on_thrown(mob/living/carbon/user, atom/target)//No, clerks cannot hilariously kill themselves with this
	if(!CanUseEgo(user))
		return
	return ..()

/obj/item/ego_weapon/branch12/mini/insanity/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	//var/caught = hit_atom.hitby(src, FALSE, TRUE, throwingdatum=throwingdatum)
	. = ..()
	if(!ismob(hit_atom) || detonate_cooldown > world.time)
		return
	if(thrownby && !.)
		detonate_cooldown = world.time + detonate_cooldown_time
		new /obj/effect/temp_visual/dir_setting/cult/phase/out (get_turf(thrownby))
		thrownby.forceMove(get_turf(src))
		new /obj/effect/temp_visual/dir_setting/cult/phase (get_turf(thrownby))
		playsound(src, 'sound/magic/exit_blood.ogg', 100, FALSE, 4)
		src.attack_hand(thrownby)
		bleed_boost(hit_atom, thrownby)
		if(thrownby.get_active_held_item() == src) //if our attack_hand() picks up the item...
			visible_message(span_warning("[thrownby] teleports to [src]!"))

/obj/item/ego_weapon/branch12/mini/insanity/proc/bleed_boost(hit_target, thrower)
	if(!ismob(hit_target) && !iscarbon(thrower))
		return
	var/mob/living/T = hit_target
	var/mob/living/carbon/U = thrower
	var/datum/status_effect/stacking/lc_bleed/B = T.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(B)
		var/obj/effect/infinity/P = new get_turf(T)
		P.color = COLOR_RED
		var/bleed_buff = B.stacks * extra_damage_per_bleed
		var/userjust = (get_modified_attribute_level(U, JUSTICE_ATTRIBUTE))
		var/justicemod = 1 + userjust / 100
		var/extra_damage = throwforce
		extra_damage *= justicemod
		T.deal_damage(extra_damage*bleed_buff, damtype, source = U, attack_type = (ATTACK_TYPE_THROWING | ATTACK_TYPE_SPECIAL))
		visible_message(span_warning("[U] punctures [T] with [src]!"))

/obj/item/ego_weapon/branch12/mini/insanity/attack(mob/living/target, mob/living/user)
	. = ..()
	if(isliving(target))
		target.apply_lc_bleed(inflicted_bleed)

//Purity
/obj/item/ego_weapon/branch12/purity
	name = "purity"
	desc = "To be pure is to be different than Innocent, for innocence requires ignorance while the pure takes in the experiences \
	they go through grows while never losing that spark of light inside. To hold the weight of the world requires someone Pure, \
	and the same can be said for this EGO which is weighed down by a heavy past that might as well be the weight of the world."
	special = "This weapon has a ranged attack which inflicts 5 Mental Decay. Attacking a target with Mental Decay will cause it to be triggered 3 time in a row, this has a cooldown. <br>\
	When attacking a target with Mental Detonation, cause a Shatter 3 times in a row. <br><br>\
	(Mental Detonation: Does nothing until it is 'Shattered.' Once it is 'Shattered,' it will cause Mental Decay to trigger without reducing it's stack. Weapons that cause 'Shatter' gain other benefits as well.) <br>\
	(Mental Decay: Deals White damage every 5 seconds, equal to its stack, and then halves it. If it is on a mob, then it deals *4 more damage.)"
	icon_state = "purity"
	force = 80
	reach = 2		//Has 2 Square Reach.
	stuntime = 5	//Longer reach, gives you a short stun.
	attack_speed = 1.2
	damtype = WHITE_DAMAGE
	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/ego/spear1.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/detonate_cooldown
	var/detonate_cooldown_time = 8 SECONDS
	var/ranged_cooldown
	var/ranged_cooldown_time = 2 SECONDS
	var/ranged_range = 5
	var/ranged_inflict = 5

/obj/item/ego_weapon/branch12/purity/attack(mob/living/target, mob/living/user)
	..()
	var/datum/status_effect/mental_detonate/mark = target.has_status_effect(/datum/status_effect/mental_detonate)
	if(mark)
		mark.shatter()
		for(var/i = 1 to 2)
			target.apply_status_effect(/datum/status_effect/mental_detonate)
			var/datum/status_effect/mental_detonate/extra_mark = target.has_status_effect(/datum/status_effect/mental_detonate)
			extra_mark.shatter()

	var/datum/status_effect/stacking/lc_mental_decay/D = target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
	if(D)
		if(detonate_cooldown > world.time)
			return
		detonate_cooldown = world.time + detonate_cooldown_time
		var/obj/effect/infinity/P = new get_turf(target)
		P.color = COLOR_PURPLE
		playsound(loc, 'sound/magic/staff_animation.ogg', 15, TRUE, extrarange = stealthy_audio ? SILENCED_SOUND_EXTRARANGE : -1, falloff_distance = 0)
		for(var/i = 1 to 3)
			D.statues_damage(FALSE)

/obj/item/ego_weapon/branch12/purity/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(ranged_cooldown > world.time)
		return
	if(!CanUseEgo(user))
		return
	var/turf/target_turf = get_turf(A)
	if(!istype(target_turf))
		return
	if((get_dist(user, target_turf) < 3) || !(target_turf in view(ranged_range, user)))
		return
	..()
	var/turf/projectile_start = get_turf(user)
	ranged_cooldown = world.time + ranged_cooldown_time
	playsound(target_turf, 'sound/effects/smoke.ogg', 20, TRUE)

	//Stuff for creating the projctile.
	var/obj/projectile/ego_bullet/branch12/old_pale/B = new(projectile_start)
	B.starting = projectile_start
	B.firer = user
	B.fired_from = projectile_start
	B.yo = target_turf.y - projectile_start.y
	B.xo = target_turf.x - projectile_start.x
	B.original = target_turf
	B.preparePixelProjectile(target_turf, projectile_start)
	B.fire()

/obj/projectile/ego_bullet/branch12/old_pale
	name = "pale smoke"
	icon_state = "smoke"
	damage = 10
	speed = 4
	range = 6
	damage_type = WHITE_DAMAGE
	projectile_piercing = PASSMOB
	var/inflicted_decay = 8

/obj/projectile/ego_bullet/branch12/old_pale/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/poorfool = target
	poorfool.apply_lc_mental_decay(inflicted_decay)

//Lunar Night
/obj/item/ego_weapon/branch12/lunar_night
	name = "lunar night"
	desc = "A reflection of the moon."
	special = "When you attack with this weapon, if the target has Mental Detonation, shatter it and increase the weapon's damage by 5. You will also lose denisty for 4 seconds. <br><br>\
	After attacking, if the target has 20+ Mental Decay, inflict Mental Detonation to the target. Otherwise, if there are no targets with Mental Detonation, inflict Mental Detonation on 1 random nearby target. <br><br>\
	(Mental Detonation: Does nothing until it is 'Shattered.' Once it is 'Shattered,' it will cause Mental Decay to trigger without reducing it's stack. Weapons that cause 'Shatter' gain other benefits as well.) <br>\
	(Mental Decay: Deals White damage every 5 seconds, equal to its stack, and then halves it. If it is on a mob, then it deals *4 more damage.)"
	icon_state = "lunar_night"
	force = 60
	damtype = BLACK_DAMAGE
	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")
	hitsound = 'sound/weapons/fixer/reverb_normal.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
							)
	var/damage_buff_per_shatter = 5
	var/old_force = 60
	var/max_force = 120
	var/shatter_limit = 20

/obj/item/ego_weapon/branch12/lunar_night/attack(mob/living/target, mob/living/user)
	var/datum/status_effect/mental_detonate/MD = target.has_status_effect(/datum/status_effect/mental_detonate)
	if(MD)
		MD.shatter()
		if(force < max_force)
			force += damage_buff_per_shatter
		var/datum/status_effect/stacking/lc_mental_decay/decay = target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
		if(decay)
			if(decay.stacks >= shatter_limit)
				target.apply_status_effect(/datum/status_effect/mental_detonate)
	else
		force = old_force
	var/is_detonate = FALSE
	var/list/detonate_targets = list()
	for(var/mob/living/simple_animal/hostile/H in view(5, get_turf(user)))
		var/datum/status_effect/mental_detonate/D = H.has_status_effect(/datum/status_effect/mental_detonate)
		if(D)
			is_detonate = TRUE
			break
		else
			if(H != target)
				detonate_targets += H
	if(!is_detonate && detonate_targets.len)
		shuffle_inplace(detonate_targets)
		var/mob/living/simple_animal/hostile/random_marked = detonate_targets[1]
		random_marked.apply_status_effect(/datum/status_effect/mental_detonate)
		user.density = FALSE
		user.color = "#57f7ff"
	else
		RemoveBuff(user)
	addtimer(CALLBACK(src, PROC_REF(RemoveBuff), user), 4 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	. = ..()

/obj/item/ego_weapon/branch12/lunar_night/proc/RemoveBuff(mob/user)
	user.density = TRUE
	user.color = null

//Sands of Time
/obj/item/ego_weapon/branch12/time_sands
	name = "sands of time"
	desc = "And so it was lost."
	icon_state = "pharaoh"
	special = "This weapon inflicts burn on target and self. This weapon also deals 1% more damage per burn on target, and 4% more damage per burn on user."
	force = 80
	damtype = RED_DAMAGE
	attack_verb_continuous = list("pokes", "jabs", "tears", "lacerates", "gores")
	attack_verb_simple = list("poke", "jab", "tear", "lacerate", "gore")
	hitsound = 'sound/weapons/ego/spear1.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)
	var/extra_damage_target_burn = 0.01
	var/extra_damage_self_burn = 0.04
	var/inflicted_burn = 4
	var/gained_burn = 2

/obj/item/ego_weapon/branch12/time_sands/attack(mob/living/target, mob/living/user)
	var/datum/status_effect/stacking/lc_burn/TB = target.has_status_effect(/datum/status_effect/stacking/lc_burn)
	var/datum/status_effect/stacking/lc_burn/UB = user.has_status_effect(/datum/status_effect/stacking/lc_burn)
	var/target_burn_buff
	var/user_burn_buff
	if(TB)
		target_burn_buff = TB.stacks * extra_damage_target_burn
	if(TB)
		user_burn_buff = UB.stacks * extra_damage_self_burn
	var/old_force = force
	force = force * (1 + target_burn_buff + user_burn_buff)
	. = ..()
	force = old_force
	if(isliving(target))
		target.apply_lc_burn(inflicted_burn)
	if(isliving(user))
		user.apply_lc_burn(gained_burn)

//Darkness
/obj/item/ego_weapon/branch12/darkness
	name = "darkness"
	desc = "It's all consuming... Gaze into it enough, you might never leave it."
	icon_state = "darkness"
	special = "When you attack with this weapon, if the target has Mental Decay, gain darkness equal to the amount Mental Decay the target has. Then trigger the Mental Decay on target. If the target has Mental Detonation, shatter it and gain 20 Darkness. <br><br>\
	At enough darkness, you are able to spend all of your darkness to send out a singularity which deal MASSIVE damage. Then more darkness you had at the time of creation, then greater it's size and damage is. However the speed and range will decease at higher amounts. <br><br>\
	(Mental Detonation: Does nothing until it is 'Shattered.' Once it is 'Shattered,' it will cause Mental Decay to trigger without reducing it's stack. Weapons that cause 'Shatter' gain other benefits as well.) <br>\
	(Mental Decay: Deals White damage every 5 seconds, equal to its stack, and then halves it. If it is on a mob, then it deals *4 more damage.)"
	force = 100
	damtype = BLACK_DAMAGE
	attack_speed = 1.6
	hitsound = 'sound/weapons/ego/hammer.ogg'
	attack_verb_continuous = list("slams", "strikes", "smashes")
	attack_verb_simple = list("slam", "strike", "smash")
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 80
							)
	var/max_gathered_darkness = 1000
	var/gathered_darkness = 700
	var/ranged_cooldown
	var/ranged_cooldown_time = 1 SECONDS
	var/ranged_range = 8
	var/summoning_time
	var/darkness_per_shatter = 20
	var/inflicted_decay = 2

/obj/item/ego_weapon/branch12/darkness/examine(mob/user)
	. = ..()
	. += span_notice("This weapon currently has gathered [gathered_darkness] darkness out of [max_gathered_darkness] maximum darkness.")

/obj/item/ego_weapon/branch12/darkness/attack(mob/living/target, mob/living/user)
	..()
	var/datum/status_effect/mental_detonate/mark = target.has_status_effect(/datum/status_effect/mental_detonate)
	if(mark)
		mark.shatter()
		if(gathered_darkness <= (max_gathered_darkness-darkness_per_shatter))
			gathered_darkness += darkness_per_shatter
	var/datum/status_effect/stacking/lc_mental_decay/D = target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
	if(D)
		if(gathered_darkness <= (max_gathered_darkness - D.stacks))
			gathered_darkness += D.stacks
			to_chat(user, span_nicegreen("You siphon some of the target's mental decay!"))
			playsound(loc, 'sound/magic/teleport_diss.ogg', 25, TRUE, extrarange = stealthy_audio ? SILENCED_SOUND_EXTRARANGE : -1, falloff_distance = 0)
			var/obj/effect/infinity/P = new get_turf(target)
			P.color = COLOR_PURPLE
			D.statues_damage(FALSE)
	if(isliving(target))
		var/mob/living/target_hit = target
		target_hit.apply_lc_mental_decay(inflicted_decay)

/obj/item/ego_weapon/branch12/darkness/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(ranged_cooldown > world.time)
		return
	if(!CanUseEgo(user))
		return
	var/turf/target_turf = get_turf(A)
	if(!istype(target_turf))
		return
	if((get_dist(user, target_turf) < 2) || !(target_turf in view(ranged_range, user)))
		return
	..()

	//Stuff for creating the projctile.
	var/obj/projectile/magic/aoe/black_hole/B
	if(gathered_darkness >= 900)
		B = new /obj/projectile/magic/aoe/black_hole/stage_5
	else if(gathered_darkness >= 600)
		B = new /obj/projectile/magic/aoe/black_hole/stage_4
	else if(gathered_darkness >= 400)
		B = new /obj/projectile/magic/aoe/black_hole/stage_3
	else if(gathered_darkness >= 200)
		B = new /obj/projectile/magic/aoe/black_hole/stage_2
	else if(gathered_darkness >= 100)
		B = new /obj/projectile/magic/aoe/black_hole
	else
		return
	ranged_cooldown = world.time + ranged_cooldown_time
	playsound(target_turf, 'sound/magic/arbiter/repulse.ogg', 45, TRUE)
	update_black_hole(B, user, target_turf)

/obj/item/ego_weapon/branch12/darkness/proc/update_black_hole(obj/projectile/magic/aoe/black_hole/B, mob/user, turf/target_turf)
	var/turf/projectile_start = get_turf(user)
	B.starting = projectile_start
	B.firer = user
	B.fired_from = projectile_start
	B.yo = target_turf.y - projectile_start.y
	B.xo = target_turf.x - projectile_start.x
	B.original = target_turf
	B.set_angle(Get_Angle(user, target_turf))
	B.forceMove(projectile_start)
	//B.preparePixelProjectile(target_turf, user, TRUE)
	if(do_after(user, B.appearing_time, src))
		B.fire()
		gathered_darkness = 0
	else
		qdel(B)

/obj/projectile/magic/aoe/black_hole
	name = "devouring singularity"
	icon = 'icons/obj/singularity.dmi'
	icon_state = "singularity_s1"
	alpha = 0
	range = 50
	damage = 100
	damage_type = BLACK_DAMAGE
	armour_penetration = 0
	speed = 1
	white_healing = FALSE
	nodamage = FALSE
	projectile_piercing = PASSMOB
	projectile_phasing = (ALL & (~PASSMOB))
	hitsound = 'sound/magic/arbiter/pillar_hit.ogg'
	var/consuming_range = 0
	var/appearing_time = 10

/obj/projectile/magic/aoe/black_hole/Initialize()
	. = ..()
	animate(src, alpha = 255, time = appearing_time)

/obj/projectile/magic/aoe/black_hole/Range()
	if(proxdet)
		if(isliving(firer))
			var/mob/living/user = firer
			var/target_aoe_turf = locate(src.x + consuming_range, src.y + consuming_range, user.z)
			for(var/mob/living/L in range(consuming_range, target_aoe_turf))
				if(L != user && !(faction_check(L.faction, list("neutral"), FALSE)))
					L.deal_damage(damage, "black", source = user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))

	range--
	damage += damage_falloff_tile
	if(range <= 0 && loc)
		on_range()

/obj/projectile/magic/aoe/black_hole/stage_2
	icon = 'icons/effects/96x96.dmi'
	icon_state = "singularity_s3"
	range = 40
	damage = 200
	speed = 1.5
	pixel_x = -32
	pixel_y = -32
	consuming_range = 1
	appearing_time = 20

/obj/projectile/magic/aoe/black_hole/stage_3
	icon = 'icons/effects/160x160.dmi'
	icon_state = "singularity_s5"
	range = 30
	damage = 400
	speed = 2.5
	pixel_x = -64
	pixel_y = -64
	consuming_range = 2
	appearing_time = 30

/obj/projectile/magic/aoe/black_hole/stage_4
	icon = 'icons/effects/224x224.dmi'
	icon_state = "singularity_s7"
	range = 20
	damage = 600
	speed = 3.5
	pixel_x = -96
	pixel_y = -96
	consuming_range = 3
	appearing_time = 40

/obj/projectile/magic/aoe/black_hole/stage_5
	icon = 'icons/effects/288x288.dmi'
	icon_state = "singularity_s9"
	range = 10
	damage = 800
	speed = 4.5
	pixel_x = -128
	pixel_y = -128
	consuming_range = 4
	appearing_time = 50


//Lucifer, Morning Star and Executioner
/obj/item/ego_weapon/ranged/branch12/lucifer
	name = "Lucifer, Morning Star"
	desc = "The first star seen in the sky on any given night."
	icon_state = "lucifer"
	inhand_icon_state = "lucifer"
	special = "Use in hand to load bullets."
	force = 56
	projectile_path = /obj/projectile/ego_bullet/lucifer
	weapon_weight = WEAPON_HEAVY
	spread = 5
	recoil = 1.5
	fire_sound = 'sound/weapons/gun/rifle/shot_atelier.ogg'
	vary_fire_sound = TRUE
	fire_sound_volume = 30
	fire_delay = 7

	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
							)


	shotsleft = 16
	reloadtime = 0.5 SECONDS


/obj/item/ego_weapon/ranged/branch12/lucifer/reload_ego(mob/user)
	if(shotsleft == initial(shotsleft))
		return
	is_reloading = TRUE
	to_chat(user,"<span class='notice'>You start loading a bullet.</span>")
	if(do_after(user, reloadtime, src)) //gotta reload
		playsound(src, 'sound/weapons/gun/general/slide_lock_1.ogg', 50, TRUE)
		shotsleft +=1
	is_reloading = FALSE


/obj/item/ego_weapon/ranged/branch12/lucifer/executioner
	name = "Executioner"
	desc = "There is but one last ."
	icon_state = "executioner"
	inhand_icon_state = "executioner"
	force = 56
	weapon_weight = WEAPON_MEDIUM	//Can be dual wielded
	recoil = 2
	fire_sound_volume = 30
	fire_delay = 12

	shotsleft = 6	//Based off a colt Single Action Navy
	reloadtime = 0.8 SECONDS

/obj/projectile/ego_bullet/lucifer
	name = "lucifer"
	damage = 140 // VERY high damage
	damage_type = BLACK_DAMAGE

//Station Command - Complex 4-Mode Weapon with Overlapping Resource System
/obj/item/ego_weapon/ranged/branch12/station_command
	name = "station command"
	desc = "Command and control from orbit. A sophisticated weapon system that manages station resources across four integrated departments."
	special = "A complex weapon with 4 overlapping modes sharing Research and Supplies resources. \
	SECURITY (Red): High damage. Consumes Research for +50% damage. Generates Supplies on marked kills. Buffed by Supplies held. \
	ENGINEERING (Yellow): Support/healing. Consumes Supplies for heals. Generates Research on critical heals. Buffed by Research held. \
	RESEARCH (Blue): Debuffs/scanning. Consumes Supplies for enhanced scans. Generates Research per hit. Marks targets for Security. \
	CARGO (Orange): Resource multiplication. Consumes Research for premium drops. Generates Supplies per hit/kill. \
	Switching modes in sequence grants powerful COMBO bonuses!"
	icon_state = "station_command"
	inhand_icon_state = "station_command"
	force = 25
	projectile_path = /obj/projectile/ego_bullet/branch12/station_command
	fire_delay = 8
	spread = 0
	shotsleft = 30
	reloadtime = 3 SECONDS
	fire_sound = 'sound/weapons/laser.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

	// Mode tracking
	var/mode = "security"
	var/last_mode = "security"

	// Dual resource system
	var/research = 50
	var/supplies = 50
	var/max_research = 100
	var/max_supplies = 100
	var/total_research_accumulated = 0  // For PE box tracking

	// Buff tracking
	var/security_kill_streak = 0
	var/combo_shots_remaining = 0
	var/combo_type = ""

	// Target marking for Research mode
	var/mob/living/marked_target

/obj/item/ego_weapon/ranged/branch12/station_command/examine(mob/user)
	. = ..()
	var/mode_display
	switch(mode)
		if("security")
			mode_display = "<font color='red'><b>SECURITY</b></font>"
		if("engineering")
			mode_display = "<font color='yellow'><b>ENGINEERING</b></font>"
		if("research")
			mode_display = "<font color='blue'><b>RESEARCH</b></font>"
		if("cargo")
			mode_display = "<font color='orange'><b>CARGO</b></font>"

	. += span_notice("[mode_display] Mode Active")
	. += span_notice("Research: [research]/[max_research] | Supplies: [supplies]/[max_supplies]")

	if(combo_type && combo_shots_remaining > 0)
		. += span_warning("Active Combo: [combo_type] ([combo_shots_remaining] shots remaining)")

	if(mode == "security" && security_kill_streak > 0)
		. += span_warning("Kill Streak Bonus: +[min(security_kill_streak * 5, 25)]% damage")

	if(marked_target && !QDELETED(marked_target) && marked_target.stat != DEAD)
		. += span_warning("Research Target: [marked_target] (Security deals +50% damage)")

/obj/item/ego_weapon/ranged/branch12/station_command/attack_self(mob/user)
	if(!CanUseEgo(user))
		return

	last_mode = mode

	switch(mode)
		if("security")
			mode = "engineering"
			fire_sound = 'sound/weapons/pulse.ogg'
			security_kill_streak = 0  // Reset streak on mode change
		if("engineering")
			mode = "research"
			fire_sound = 'sound/weapons/taser.ogg'
		if("research")
			mode = "cargo"
			fire_sound = 'sound/weapons/black_silence/shotgun.ogg'
		if("cargo")
			mode = "security"
			fire_sound = 'sound/weapons/laser.ogg'

	// Apply combo bonuses based on mode transition
	ApplyComboBonus(user)

	// Display mode info
	var/resource_info = "Research: [research]/[max_research] | Supplies: [supplies]/[max_supplies]"
	to_chat(user, span_notice("Switched to [uppertext(mode)] mode. [resource_info]"))

/obj/item/ego_weapon/ranged/branch12/station_command/proc/ApplyComboBonus(mob/user)
	combo_type = ""
	combo_shots_remaining = 0

	// Define combo transitions
	switch("[last_mode]_to_[mode]")
		if("security_to_engineering")
			combo_type = "Tactical Repair"
			combo_shots_remaining = 3
			to_chat(user, span_boldwarning("COMBO: Tactical Repair! Next 3 Engineering shots cost no Supplies!"))
			playsound(user, 'sound/machines/ping.ogg', 50, TRUE)

		if("engineering_to_research")
			combo_type = "Data Recovery"
			research = min(research + 30, max_research)
			to_chat(user, span_boldwarning("COMBO: Data Recovery! +30 Research gained!"))
			playsound(user, 'sound/machines/ping.ogg', 50, TRUE)

		if("research_to_cargo")
			combo_type = "Supply Chain"
			combo_shots_remaining = 1  // Next kill
			to_chat(user, span_boldwarning("COMBO: Supply Chain! Next kill spawns double items!"))
			playsound(user, 'sound/machines/ping.ogg', 50, TRUE)

		if("cargo_to_security")
			combo_type = "Armed Escort"
			combo_shots_remaining = 5
			to_chat(user, span_boldwarning("COMBO: Armed Escort! +30% damage for 5 shots!"))
			playsound(user, 'sound/machines/ping.ogg', 50, TRUE)

		if("security_to_research")
			combo_type = "Threat Analysis"
			combo_shots_remaining = 3
			to_chat(user, span_boldwarning("COMBO: Threat Analysis! Next 3 targets marked for 2x Mental Decay!"))
			playsound(user, 'sound/machines/ping.ogg', 50, TRUE)

		if("research_to_security")
			combo_type = "Calculated Strike"
			combo_shots_remaining = 1
			to_chat(user, span_boldwarning("COMBO: Calculated Strike! Next shot applies guaranteed Mental Detonation!"))
			playsound(user, 'sound/machines/ping.ogg', 50, TRUE)

		if("engineering_to_cargo")
			combo_type = "Salvage Op"
			supplies = min(supplies + 25, max_supplies)
			to_chat(user, span_boldwarning("COMBO: Salvage Op! +25 Supplies gained!"))
			playsound(user, 'sound/machines/ping.ogg', 50, TRUE)

		if("cargo_to_engineering")
			combo_type = "Field Supplies"
			combo_shots_remaining = 5
			to_chat(user, span_boldwarning("COMBO: Field Supplies! Next 5 heals are 50% stronger!"))
			playsound(user, 'sound/machines/ping.ogg', 50, TRUE)

/obj/item/ego_weapon/ranged/branch12/station_command/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		START_PROCESSING(SSobj, src)

/obj/item/ego_weapon/ranged/branch12/station_command/dropped(mob/user)
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/ego_weapon/ranged/branch12/station_command/process()
	// Research decays slowly when not in research mode
	if(mode != "research" && research > 0 && prob(5))
		research = max(research - 1, 0)

/obj/projectile/ego_bullet/branch12/station_command
	name = "station command"
	damage = 70
	damage_type = BLACK_DAMAGE
	var/base_damage = 70

/obj/projectile/ego_bullet/branch12/station_command/on_hit(atom/target, blocked = FALSE)
	if(!isliving(target) || !isliving(firer))
		return ..()

	var/obj/item/ego_weapon/ranged/branch12/station_command/gun = fired_from
	if(!istype(gun))
		return ..()

	var/mob/living/L = target
	var/mob/living/shooter = firer

	// Skip if target is already dead
	if(L.stat == DEAD)
		return ..()

	// Reset damage to base before mode modifications
	damage = base_damage

	switch(gun.mode)
		if("security")
			SecurityModeHit(L, shooter, gun)
		if("engineering")
			EngineeringModeHit(L, shooter, gun)
		if("research")
			ResearchModeHit(L, shooter, gun)
		if("cargo")
			CargoModeHit(L, shooter, gun)

	// Consume combo shot if applicable
	if(gun.combo_shots_remaining > 0)
		gun.combo_shots_remaining--
		if(gun.combo_shots_remaining <= 0)
			gun.combo_type = ""

	return ..()

// process_hit is called AFTER damage is applied - use for kill detection
/obj/projectile/ego_bullet/branch12/station_command/process_hit(turf/T, atom/target, atom/bumped, hit_something = FALSE)
	if(!isliving(target))
		return ..()

	var/mob/living/L = target
	var/old_stat = L.stat

	. = ..()

	// Check if this shot killed the target
	if(!. || old_stat == DEAD)
		return

	if(L.stat != DEAD)
		return

	// Target was killed by this shot - process on-kill effects
	var/obj/item/ego_weapon/ranged/branch12/station_command/gun = fired_from
	if(!istype(gun))
		return

	var/mob/living/shooter = firer
	if(!isliving(shooter))
		return

	switch(gun.mode)
		if("security")
			SecurityModeKill(L, shooter, gun)
		if("cargo")
			CargoModeKill(L, shooter, gun)

/obj/projectile/ego_bullet/branch12/station_command/proc/SecurityModeHit(mob/living/L, mob/living/shooter, obj/item/ego_weapon/ranged/branch12/station_command/gun)
	// Base damage: 70
	damage = 70

	// Buff from Supplies held (+20% per 25 Supplies, max +80%)
	var/supply_bonus = min(round(gun.supplies / 25) * 0.2, 0.8)
	damage *= (1 + supply_bonus)

	// Kill streak bonus (+5% per kill, max +25%)
	var/streak_bonus = min(gun.security_kill_streak * 0.05, 0.25)
	damage *= (1 + streak_bonus)

	// Consume Research for enhanced shot (+50% damage)
	if(gun.research >= 5)
		gun.research -= 5
		damage *= 1.5
		to_chat(shooter, span_notice("Research-enhanced targeting! (+50% damage)"))

	// Armed Escort combo (+30% damage)
	if(gun.combo_type == "Armed Escort" && gun.combo_shots_remaining > 0)
		damage *= 1.3

	// Check for marked target from Research mode (+50% damage)
	if(L == gun.marked_target)
		damage *= 1.5
		to_chat(shooter, span_warning("Marked target hit! (+50% damage)"))
		gun.marked_target = null

	// Apply Mental Detonation if target has 15+ Mental Decay OR Calculated Strike combo
	var/datum/status_effect/stacking/lc_mental_decay/decay = L.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
	if((decay && decay.stacks >= 15) || (gun.combo_type == "Calculated Strike" && gun.combo_shots_remaining > 0))
		L.apply_status_effect(/datum/status_effect/mental_detonate)
		to_chat(shooter, span_warning("Target marked for Mental Detonation!"))

	// Check for Mental Detonation to shatter for execution damage
	var/datum/status_effect/mental_detonate/MD = L.has_status_effect(/datum/status_effect/mental_detonate)
	if(MD)
		MD.shatter()
		L.deal_damage(100, BLACK_DAMAGE, source = shooter, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
		to_chat(shooter, span_boldwarning("EXECUTION! Mental Detonation shattered for +100 damage!"))
		// Generate Supplies on shatter
		gun.supplies = min(gun.supplies + 10, gun.max_supplies)
		to_chat(shooter, span_nicegreen("+10 Supplies from detonation shatter!"))

/obj/projectile/ego_bullet/branch12/station_command/proc/EngineeringModeHit(mob/living/L, mob/living/shooter, obj/item/ego_weapon/ranged/branch12/station_command/gun)
	// Base damage: 40
	damage = 40

	// Calculate heal amount (base 15 + Research/5)
	var/heal_amount = 15 + round(gun.research / 5)

	// Field Supplies combo (+50% healing)
	if(gun.combo_type == "Field Supplies" && gun.combo_shots_remaining > 0)
		heal_amount *= 1.5

	// Check if we need to consume Supplies (unless Tactical Repair combo)
	var/free_shot = (gun.combo_type == "Tactical Repair" && gun.combo_shots_remaining > 0)

	if(!free_shot && gun.supplies < 10)
		to_chat(shooter, span_warning("Not enough Supplies for healing! (Need 10, have [gun.supplies])"))
		// Still do damage and mental decay, just no healing
	else
		if(!free_shot)
			gun.supplies -= 10

		// Heal allies in range 3
		for(var/mob/living/carbon/human/H in range(3, L))
			if(H.stat == DEAD)
				continue
			if(H == shooter || H.faction_check_mob(shooter))
				H.heal_overall_damage(heal_amount, heal_amount)
				to_chat(H, span_nicegreen("Station Engineering repairs your equipment! (+[heal_amount] HP)"))

				// Generate Research when healing allies below 50% HP
				if(H.health < H.maxHealth * 0.5)
					gun.research = min(gun.research + 5, gun.max_research)
					to_chat(shooter, span_notice("+5 Research from emergency repair data!"))

		// Bonus: If Supplies > 50, also mention enhanced repair
		if(gun.supplies > 50)
			to_chat(shooter, span_notice("High supply levels: Enhanced repair efficiency!"))

	// Apply Mental Decay to enemy
	L.apply_lc_mental_decay(3)

/obj/projectile/ego_bullet/branch12/station_command/proc/ResearchModeHit(mob/living/L, mob/living/shooter, obj/item/ego_weapon/ranged/branch12/station_command/gun)
	// Base damage: 50
	damage = 50

	// Calculate Mental Decay to apply (base 3 + Research/20)
	var/decay_amount = 3 + round(gun.research / 20)

	// Buff from Supplies held (+1 per 20 Supplies)
	decay_amount += round(gun.supplies / 20)

	// Threat Analysis combo (2x Mental Decay)
	if(gun.combo_type == "Threat Analysis" && gun.combo_shots_remaining > 0)
		decay_amount *= 2

	// Consume Supplies for enhanced scan (+3 Mental Decay)
	if(gun.supplies >= 5)
		gun.supplies -= 5
		decay_amount += 3
		to_chat(shooter, span_notice("Enhanced scan! (+3 Mental Decay)"))

	// Apply Mental Decay
	L.apply_lc_mental_decay(decay_amount)

	// Generate Research (8 base, +4 if target has status effects)
	var/research_gain = 8
	if(L.status_effects && L.status_effects.len > 0)
		research_gain += 4
		to_chat(shooter, span_notice("Target has status effects! Bonus research data!"))

	gun.research = min(gun.research + research_gain, gun.max_research)
	gun.total_research_accumulated += research_gain

	// Grant PE box every 50 total research accumulated
	if(gun.total_research_accumulated >= 50)
		gun.total_research_accumulated -= 50
		SSlobotomy_corp.AdjustAvailableBoxes(1)
		to_chat(shooter, span_boldwarning("Research milestone reached! +1 PE Box!"))
		playsound(shooter, 'sound/machines/ping.ogg', 75, TRUE)

	// Mark target for Security mode
	gun.marked_target = L
	to_chat(shooter, span_warning("[L] marked for Security targeting! (+50% damage)"))

/obj/projectile/ego_bullet/branch12/station_command/proc/CargoModeHit(mob/living/L, mob/living/shooter, obj/item/ego_weapon/ranged/branch12/station_command/gun)
	// Base damage: 60
	damage = 60

	// Calculate supply gain (8 base, +50% if Research > 50)
	var/supply_gain = 8
	if(gun.research > 50)
		supply_gain = 12
		to_chat(shooter, span_notice("High research: Enhanced supply generation!"))

	gun.supplies = min(gun.supplies + supply_gain, gun.max_supplies)

	// Check for Mental Detonation to shatter for AOE supply drop
	var/datum/status_effect/mental_detonate/MD = L.has_status_effect(/datum/status_effect/mental_detonate)
	if(MD)
		MD.shatter()
		to_chat(shooter, span_boldwarning("Supply explosion! Detonation shattered!"))
		// AOE Mental Decay
		for(var/mob/living/M in range(3, L))
			if(M != L && M != shooter)
				M.apply_lc_mental_decay(4)
		// Bonus supplies
		gun.supplies = min(gun.supplies + 15, gun.max_supplies)

// On-kill proc for Security mode - called from process_hit after damage is applied
/obj/projectile/ego_bullet/branch12/station_command/proc/SecurityModeKill(mob/living/L, mob/living/shooter, obj/item/ego_weapon/ranged/branch12/station_command/gun)
	// Increment kill streak
	gun.security_kill_streak++
	to_chat(shooter, span_warning("Kill streak: [gun.security_kill_streak] (+[min(gun.security_kill_streak * 5, 25)]% damage)"))

// On-kill proc for Cargo mode - called from process_hit after damage is applied
/obj/projectile/ego_bullet/branch12/station_command/proc/CargoModeKill(mob/living/L, mob/living/shooter, obj/item/ego_weapon/ranged/branch12/station_command/gun)
	// Generate supplies on kill
	var/kill_supplies = 20
	if(gun.combo_type == "Supply Chain" && gun.combo_shots_remaining > 0)
		kill_supplies *= 2
		to_chat(shooter, span_boldwarning("Supply Chain combo! Double supplies!"))

	gun.supplies = min(gun.supplies + kill_supplies, gun.max_supplies)

	// Spread Mental Decay to nearby enemies
	for(var/mob/living/M in range(2, L))
		if(M != L && M != shooter)
			M.apply_lc_mental_decay(4)

	// Spawn supplies (premium if Research consumed)
	var/spawn_premium = FALSE
	if(gun.research >= 15)
		gun.research -= 15
		spawn_premium = TRUE

	if(spawn_premium)
		// Premium drop - healing item
		new /obj/item/reagent_containers/hypospray/medipen(get_turf(L))
		to_chat(shooter, span_nicegreen("Premium supply drop! (Medical supplies)"))
	else
		// Regular drop - cash
		new /obj/item/stack/spacecash/c500(get_turf(L))
		to_chat(shooter, span_notice("Supply drop delivered!"))

//XXI (The World)
/obj/item/ego_weapon/branch12/XXI
	name = "XXI"
	desc = "The World card represents completion, fulfillment, and the end of a journey."
	special = "This weapon's damage type changes randomly on each hit. \
	Using this weapon in hand places a random damaging tile at your feet that lasts 10 seconds. \
	After 21 hits, apply Mental Detonation to the target. When hitting a target with Mental Detonation, shatter it for a time stop effect dealing all damage types. <br><br>\
	(Mental Detonation: Does nothing until it is 'Shattered.' Once it is 'Shattered,' it will cause Mental Decay to trigger without reducing it's stack. Weapons that cause 'Shatter' gain other benefits as well.) <br>\
	(Mental Decay: Deals White damage every 5 seconds, equal to its stack, and then halves it. If it is on a mob, then it deals *4 more damage.)"
	icon_state = "XXI"
	force = 90
	damtype = RED_DAMAGE
	throwforce = 50
	throw_speed = 2
	throw_range = 10
	attack_verb_continuous = list("tricks", "jests", "mocks")
	attack_verb_simple = list("trick", "jest", "mock")
	hitsound = 'sound/items/bikehorn.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/tile_cooldown = 0
	var/tile_cooldown_time = 5 SECONDS
	var/hit_counter = 0

/obj/item/ego_weapon/branch12/XXI/attack(mob/living/target, mob/living/user)
	// Random damage type each hit
	damtype = pick(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)
	. = ..()

	if(!isliving(target))
		return

	// Check for mental detonation to complete the cycle
	var/datum/status_effect/mental_detonate/MD = target.has_status_effect(/datum/status_effect/mental_detonate)
	if(MD)
		MD.shatter()
		// The World completes - deal damage of ALL types and reset the cycle
		to_chat(user, span_boldwarning("THE WORLD! Time has stopped!"))
		playsound(target, 'sound/magic/clockwork/narsie_attack.ogg', 100, TRUE)
		new /obj/effect/temp_visual/dir_setting/cult/phase(get_turf(target))

		// Stop time effect - freeze target
		target.Stun(30)

		// Deal damage of all types representing completion
		target.deal_damage(50, RED_DAMAGE, source = user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		target.deal_damage(50, WHITE_DAMAGE, source = user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		target.deal_damage(50, BLACK_DAMAGE, source = user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		target.deal_damage(50, PALE_DAMAGE, source = user, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

		// Reset hit counter as the cycle completes
		hit_counter = 0
		to_chat(user, span_nicegreen("The cycle begins anew..."))
		return

	// Track hits for XXI theme
	hit_counter++
	if(hit_counter >= 21)
		hit_counter = 0
		target.apply_status_effect(/datum/status_effect/mental_detonate)
		to_chat(user, span_boldwarning("The World completes its cycle! Mental detonation applied!"))
		playsound(target, 'sound/magic/clockwork/invoke_general.ogg', 75, TRUE)
		new /obj/effect/temp_visual/cult/sparks(get_turf(target))

	// Small chance for special effect based on damage type
	if(prob(25))
		switch(damtype)
			if(RED_DAMAGE)
				target.apply_lc_bleed(20)
			if(WHITE_DAMAGE)
				target.apply_lc_mental_decay(5)
			if(BLACK_DAMAGE)
				target.deal_damage(10, RED_DAMAGE, source = user, attack_type = (ATTACK_TYPE_MELEE))
			if(PALE_DAMAGE)
				target.add_movespeed_modifier(/datum/movespeed_modifier/XXI_curse)
				addtimer(CALLBACK(src, PROC_REF(RemoveCurse), target), 5 SECONDS)

/obj/item/ego_weapon/branch12/XXI/attack_self(mob/user)
	if(!CanUseEgo(user))
		return
	if(!ishuman(user))
		return

	if(tile_cooldown > world.time)
		to_chat(user, span_warning("The jester's magic hasn't recharged yet."))
		return

	tile_cooldown = world.time + tile_cooldown_time
	var/turf/T = get_turf(user)

	// Create a random damage zone
	var/damage_type = pick(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)
	var/damage_amount = rand(20, 40)
	var/obj/effect/jester_zone/zone = new(T, damage_type, damage_amount)
	zone.owner = user

	to_chat(user, span_notice("You conjure a chaotic damage zone!"))
	playsound(T, 'sound/magic/summon_karp.ogg', 50, TRUE)
	QDEL_IN(zone, 10 SECONDS)

/obj/item/ego_weapon/branch12/XXI/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	// Create a bouncing projectile instead of normal throw impact
	var/turf/T = get_turf(src)
	var/obj/projectile/ego_XXI/P = new(T)
	P.damage = throwforce
	P.firer = thrownby
	P.fired_from = src
	P.original = hit_atom
	P.preparePixelProjectile(hit_atom, T)
	P.fire()
	. = ..()

/obj/item/ego_weapon/branch12/XXI/proc/RemoveCurse(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/XXI_curse)

/datum/movespeed_modifier/XXI_curse
	variable = TRUE
	multiplicative_slowdown = 2

// Special bouncing projectile
/obj/projectile/ego_XXI
	name = "jester's trick"
	icon_state = "dvoid"
	desc = "A chaotic ball of energy."
	damage_type = RED_DAMAGE
	speed = 3
	damage = 50
	projectile_piercing = NONE
	ricochets_max = 5
	ricochet_chance = 100
	ricochet_decay_chance = 0.8
	ricochet_decay_damage = 1.2
	ricochet_auto_aim_range = 4
	ricochet_incidence_leeway = 90

/obj/projectile/ego_XXI/Initialize()
	. = ..()
	damage_type = pick(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)

/obj/projectile/ego_XXI/on_ricochet(atom/A)
	// Change damage type on each bounce
	damage_type = pick(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)

/obj/projectile/ego_XXI/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	if(istype(A, /obj/structure) && A.density)
		return TRUE
	return FALSE

// Damage zone effect
/obj/effect/jester_zone
	name = "chaotic zone"
	desc = "A swirling vortex of chaotic energy."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-grey"
	layer = BELOW_MOB_LAYER
	var/damage_type = RED_DAMAGE
	var/damage_amount = 30
	var/mob/owner

/obj/effect/jester_zone/Initialize(mapload, dtype, damount)
	. = ..()
	if(dtype)
		damage_type = dtype
	if(damount)
		damage_amount = damount

	// Set color based on damage type
	switch(damage_type)
		if(RED_DAMAGE)
			color = "#ff0000"
		if(WHITE_DAMAGE)
			color = "#ffffff"
		if(BLACK_DAMAGE)
			color = "#000000"
		if(PALE_DAMAGE)
			color = "#cc99ff"

	START_PROCESSING(SSobj, src)

/obj/effect/jester_zone/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/effect/jester_zone/process()
	for(var/mob/living/L in get_turf(src))
		if(L == owner)
			continue
		L.deal_damage(damage_amount * 0.1, damage_type, source = owner, attack_type = (ATTACK_TYPE_ENVIRONMENT))
