// Needlekin: tiny hooded things with needle staffs, a green kind and a red kind. They walk up and stab like a kaki
// that fights, and each stab can pin a stack of Naildle into the target, no more often than once every couple of
// seconds per needlekin. Now and then, pinning one, they shout.
/mob/living/simple_animal/hostile/gms_foe/needlekin
	name = "green needlekin"
	desc = "A tiny hooded figure leaning on a needle taller than it is. Its eyes are two pinpricks of light."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "green_needlekin"
	icon_living = "green_needlekin"
	icon_dead = "green_needlekin_dead"
	maxHealth = 60
	health = 60
	move_to_delay = 4
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 3
	melee_damage_upper = 4
	attack_cooldown = 1.2 SECONDS
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	attack_sound = 'ModularLobotomy/_Lobotomysounds/gms/needlekin_stab.ogg'
	// Small enough to walk through, and to crowd onto one tile.
	density = FALSE
	plays_kill_sequence = TRUE
	kill_sequence_type = /datum/gms_kill_sequence/needlekin
	/// It pins at most one stack of Naildle per this long.
	var/naildle_cooldown_time = 2 SECONDS
	var/naildle_cooldown = 0
	/// The chance, pinning a stack, that it shouts one of its lines.
	var/shout_chance = 25
	var/list/shout_sounds = list(
		'ModularLobotomy/_Lobotomysounds/gms/needlekin_shaddap_1.ogg',
		'ModularLobotomy/_Lobotomysounds/gms/needlekin_shaddap_2.ogg',
		'ModularLobotomy/_Lobotomysounds/gms/needlekin_shaddap_3.ogg',
		)
	/// Where needlekin sharing a tile stand on it, in pixels, so a crowd of them does not pile onto one spot.
	var/list/crowd_offsets = list(list(0, 0), list(-8, 4), list(8, 4), list(-8, -4), list(8, -4), list(0, 8))
	/// TRUE while the King of Needleworks holds it up to throw, when it is left out of the crowd's spreading.
	var/lifted = FALSE

// Every move re-spreads the needlekin on the tile it left and the one it came to.
/mob/living/simple_animal/hostile/gms_foe/needlekin/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	SpreadOut(OldLoc)
	SpreadOut(loc)

/mob/living/simple_animal/hostile/gms_foe/needlekin/death(gibbed)
	. = ..()
	SpreadOut(loc)

/// Spreads the living needlekin on a turf across it, each to its own spot; one alone stands in the middle.
/mob/living/simple_animal/hostile/gms_foe/needlekin/proc/SpreadOut(turf/T)
	if(!isturf(T))
		return
	var/i = 0
	for(var/mob/living/simple_animal/hostile/gms_foe/needlekin/N in T)
		if(N.stat == DEAD || N.lifted)
			continue
		var/list/offset = crowd_offsets[i % length(crowd_offsets) + 1]
		i++
		N.base_pixel_x = offset[1]
		N.base_pixel_y = offset[2]
		animate(N, pixel_x = offset[1], pixel_y = offset[2], time = 0.2 SECONDS)

// They leave anyone the King has Taxidermized to him.
/mob/living/simple_animal/hostile/gms_foe/needlekin/CanAttack(atom/the_target)
	var/mob/living/L = the_target
	if(istype(L) && L.has_status_effect(/datum/status_effect/gms_taxidermized))
		return FALSE
	return ..()

// A stab may pin Naildle into someone still alive. Only the blow that kills starts the kill sequence.
/mob/living/simple_animal/hostile/gms_foe/needlekin/AttackingTarget(atom/attacked_target)
	var/mob/living/victim = attacked_target || target
	var/was_alive = isliving(victim) && victim.stat != DEAD
	. = ..()
	if(!was_alive)
		return
	if(victim.stat != DEAD)
		PinNaildle(victim)
		return
	StartKill(victim)

/// Pins one stack of Naildle into the target, if its cooldown is up, and maybe shouts.
/mob/living/simple_animal/hostile/gms_foe/needlekin/proc/PinNaildle(mob/living/L)
	if(naildle_cooldown > world.time)
		return
	naildle_cooldown = world.time + naildle_cooldown_time
	GmsAddNaildle(L, 1)
	playsound(L, 'ModularLobotomy/_Lobotomysounds/gms/needlekin_naildle.ogg', 50, TRUE)
	if(prob(shout_chance))
		playsound(src, pick(shout_sounds), 60, FALSE)
		say("Shaddap! Shaddap!")

/// Adds `amount` stacks of Naildle to L, giving it Naildle if it has none; a negative amount takes stacks away, and
/// taking the last one removes it. Nothing goes into someone Taxidermized. Shared by everything that pins Naildle.
/proc/GmsAddNaildle(mob/living/L, amount)
	if(amount > 0 && L.has_status_effect(/datum/status_effect/gms_taxidermized))
		return
	var/datum/status_effect/stacking/naildle/N = L.has_status_effect(/datum/status_effect/stacking/naildle)
	if(N)
		N.add_stacks(amount)
	else if(amount > 0)
		L.apply_status_effect(/datum/status_effect/stacking/naildle, amount)

/// How many stacks of Naildle L has, 0 if none.
/proc/GmsNaildleStacks(mob/living/L)
	var/datum/status_effect/stacking/naildle/N = L.has_status_effect(/datum/status_effect/stacking/naildle)
	return N ? N.stacks : 0

/mob/living/simple_animal/hostile/gms_foe/needlekin/red
	name = "red needlekin"
	icon_state = "red_needlekin"
	icon_living = "red_needlekin"
	icon_dead = "red_needlekin_dead"

/// Naildle: needles pinned in. Each time the bearer takes damage, the needles drive in for stacks * bonus_per_stack
/// more RED damage, no more often than once per trigger_cooldown_time, and a stack is spent. The needles show in the
/// bearer, more of them as stacks build. A stack falls out for every decay_time that passes without gaining one.
/datum/status_effect/stacking/naildle
	id = "naildle"
	alert_type = /atom/movable/screen/alert/status_effect/naildle
	max_stacks = 10
	// Its own decay replaces the base's, which would push decay further back with every stack gained.
	delay_before_decay = 0
	tick_interval = 1 SECONDS
	consumed_on_threshold = FALSE
	var/decay_time = 10 SECONDS
	/// When it last gained a stack or lost one to decay.
	var/quiet_since = 0
	var/bonus_per_stack = 3
	var/trigger_cooldown_time = 2 SECONDS
	var/trigger_cooldown = 0
	/// The needles shown in the bearer: one of the kill sequence's needle stages, more of them as stacks build.
	var/mutable_appearance/pins
	var/needle_stages = 6

/atom/movable/screen/alert/status_effect/naildle
	name = "Naildle"
	desc = "Needles are pinned into you. When you are hurt they drive deeper, dealing extra RED damage for each one."
	icon = 'icons/mob/gms/gms_32x32.dmi'
	icon_state = "needlekin_naildle"

/datum/status_effect/stacking/naildle/on_apply()
	. = ..()
	if(.)
		RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnDamaged))
		RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(OnDeath))
		// Fresh needles wait out the cooldown before they can drive in, or the very next hit would spend the first stack
		// and remove the effect, and every new one would trigger at once.
		trigger_cooldown = world.time + trigger_cooldown_time

/datum/status_effect/stacking/naildle/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_LIVING_DEATH))
	owner.cut_overlay(pins)
	return ..()

/datum/status_effect/stacking/naildle/add_stacks(stacks_added)
	if(stacks_added > 0)
		quiet_since = world.time
	. = ..()
	ShowPins()

/datum/status_effect/stacking/naildle/tick()
	if(!can_have_status())
		qdel(src)
		return
	if(world.time - quiet_since < decay_time)
		return
	quiet_since = world.time
	add_stacks(-stack_decay)

/// Shows as many needles in the bearer as its stacks call for, out of the kill sequence's stages.
/datum/status_effect/stacking/naildle/proc/ShowPins()
	if(QDELETED(src) || QDELETED(owner))
		return
	owner.cut_overlay(pins)
	var/stage = clamp(CEILING(stacks * needle_stages / max_stacks, 1), 1, needle_stages)
	// Over clothing, under anything held, like the needles left in a needlekin's kill.
	pins = mutable_appearance('icons/mob/gms/gms_32x32.dmi', "needlekin_needles_[stage]", -(HANDS_LAYER + 0.5))
	owner.add_overlay(pins)

/datum/status_effect/stacking/naildle/proc/OnDamaged(datum/source, damage_amount, damage_type, def_zone, damage_source, flags, attack_type)
	SIGNAL_HANDLER
	if(damage_amount <= 0 || trigger_cooldown > world.time)
		return
	// The cooldown starts now, so the needles' own damage cannot set them off again.
	trigger_cooldown = world.time + trigger_cooldown_time
	INVOKE_ASYNC(src, PROC_REF(DriveIn))

// The needles go with the life they were in; a needlekin's kill leaves its own on the body.
/datum/status_effect/stacking/naildle/proc/OnDeath(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/stacking/naildle/proc/DriveIn()
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	owner.deal_damage(stacks * bonus_per_stack, RED_DAMAGE, attack_type = ATTACK_TYPE_STATUS)
	to_chat(owner, span_warning("The needles in you drive deeper!"))
	// Driving in spends a needle.
	add_stacks(-1)
