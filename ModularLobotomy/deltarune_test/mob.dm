/// Test enemy that pulls a player into a Deltarune-style battle on contact.
/// On spotting a target it shows a "!" balloon for 1 second, then charges.
/mob/living/simple_animal/hostile/deltarune
	name = "rudinn"
	desc = "An ambivalent diamond. Doesn't look like any girl's best friend."
	icon = 'icons/UI_Icons/deltarune/rudinn_idle.png'
	icon_state = ""
	pixel_x = -8
	base_pixel_x = -8
	mob_biotypes = MOB_ORGANIC
	speed = 4
	maxHealth = 100
	health = 100
	melee_damage_lower = 1
	melee_damage_upper = 1
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	vision_range = 7
	aggro_vision_range = 9
	faction = list("hostile")
	loot = list()
	del_on_death = TRUE
	/// Already telegraphed at this target — avoids re-firing the bubble each tick.
	var/list/telegraphed = list()
	/// Telegraph is currently playing; suppress AI movement.
	var/telegraphing = FALSE

/mob/living/simple_animal/hostile/deltarune/GiveTarget(atom/new_target)
	. = ..()
	if(. && new_target && !(WEAKREF(new_target) in telegraphed))
		telegraphed += WEAKREF(new_target)
		PlayTelegraph()

/mob/living/simple_animal/hostile/deltarune/proc/PlayTelegraph()
	telegraphing = TRUE
	can_act = FALSE
	for(var/mob/M in viewers(7, src))
		balloon_alert(M, "!")
	visible_message(span_danger("[src] spots you!"))
	playsound(src, 'sound/effects/alert.ogg', 60, FALSE)
	addtimer(CALLBACK(src, PROC_REF(FinishTelegraph)), 1 SECONDS)

/mob/living/simple_animal/hostile/deltarune/proc/FinishTelegraph()
	telegraphing = FALSE
	can_act = TRUE

/mob/living/simple_animal/hostile/deltarune/AttackingTarget(atom/attacked_target)
	if(!attacked_target)
		attacked_target = target
	if(!ishuman(attacked_target))
		return ..()
	var/mob/living/carbon/human/H = attacked_target
	if(H.stat >= DEAD)
		return ..()
	new /datum/deltarune_battle(H, src)
	return
