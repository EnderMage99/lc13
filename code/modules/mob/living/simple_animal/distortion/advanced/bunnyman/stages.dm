// What his ground does to people. Stages 0 to 2 are oddities only, the small wrong things the base rolls near
// players. From stage 3, the people inside see him coming when he is not, and his rabbits sometimes look like him.

/// A thump from somewhere out of sight: one tread, from a claimed turf, going nowhere.
/obj/effect/temp_visual/distortion_oddity/bunnyman_thump
	icon_state = null
	alpha = 0
	duration = 1 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_thump/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/owner)
	. = ..()
	playsound(loc, pick(owner.footstep_sounds), 40, TRUE)

/// Three or four of his steps in a row, a step apart, from somewhere nobody is looking.
/obj/effect/temp_visual/distortion_oddity/bunnyman_steps
	icon_state = null
	alpha = 0
	duration = 4 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_steps/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/owner)
	. = ..()
	for(var/i in 0 to rand(2, 3))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), loc, pick(owner.footstep_sounds), 40, TRUE), i * 0.8 SECONDS)

/// One footprint that was not there, with its tread, fading as the real ones do.
/obj/effect/temp_visual/distortion_oddity/bunnyman_print
	icon_state = null
	alpha = 0
	duration = 1 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_print/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/owner)
	. = ..()
	new /obj/effect/temp_visual/bunnyman_footprint(loc, pick(GLOB.cardinals))
	playsound(loc, pick(owner.footstep_sounds), 40, TRUE)

/// Two eyes, for a second, then gone.
/obj/effect/temp_visual/distortion_oddity/bunnyman_glimpse
	icon = 'ModularLobotomy/_Lobotomyicons/bunnyman_eyes.dmi'
	icon_state = "eyes"
	pixel_x = -16
	layer = ABOVE_MOB_LAYER
	duration = 1 SECONDS

/// A rabbit crossing the far end of the corridor, and gone before anyone gets there.
/obj/effect/temp_visual/distortion_oddity/bunnyman_crossing
	icon = 'icons/mob/easter.dmi'
	icon_state = "rabbit_white"
	layer = MOB_LAYER
	duration = 2.5 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_crossing/Initialize(mapload)
	. = ..()
	icon_state = pick("rabbit_white", "rabbit_brown", "rabbit_black")
	var/move_dir = pick(GLOB.cardinals)
	dir = move_dir
	var/dx = (move_dir == EAST ? 1 : (move_dir == WEST ? -1 : 0)) * 128
	var/dy = (move_dir == NORTH ? 1 : (move_dir == SOUTH ? -1 : 0)) * 128
	animate(src, pixel_x = dx, pixel_y = dy, time = duration - 0.5 SECONDS)
	animate(alpha = 0, time = 0.5 SECONDS)

/// A smear of blood on the floor that is not there three seconds later.
/obj/effect/temp_visual/distortion_oddity/bunnyman_smear
	icon = 'icons/effects/blood.dmi'
	icon_state = "floor1"
	layer = ABOVE_OPEN_TURF_LAYER
	duration = 3 SECONDS

/obj/effect/temp_visual/distortion_oddity/bunnyman_smear/Initialize(mapload)
	. = ..()
	icon_state = "floor[rand(1, 7)]"
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/// Every so often from hallucination_stage, a person inside sees him rush them from the edge of their view. Nobody
/// else sees it. Twice as often at the cap.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HallucinationTick(list/inside)
	if(territory.stage < hallucination_stage || !judging)
		return
	var/interval = hallucination_interval
	if(territory.stage >= 4)
		interval /= 2
	for(var/mob/living/carbon/human/H in inside)
		if(!H.client || H.stat != CONSCIOUS)
			continue
		if(isnull(next_hallucination[H]))
			RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(OnHallucinatedDeleted))
			next_hallucination[H] = world.time + rand(interval * 0.5, interval)
			continue
		if(world.time < next_hallucination[H])
			continue
		next_hallucination[H] = world.time + rand(interval * 0.5, interval)
		var/turf/start = HallucinationStart(H)
		if(start)
			new /obj/effect/hallucination/simple/bunnyman(start, H, src)

/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/OnHallucinatedDeleted(datum/source)
	SIGNAL_HANDLER
	next_hallucination -= source

/// A claimed turf at the edge of H's view, or null if there is none to be had.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/HallucinationStart(mob/living/carbon/human/H)
	for(var/i in 1 to 15)
		var/turf/T = territory.RandomTurfNear(get_turf(H), 7)
		if(T.z == H.z && get_dist(T, H) >= 5 && (T in view(7, H)))
			return T
	return null

/// Him, to one person: his enraged sprite coming at them a tile at a time. Reaching them costs hallucination_sanity;
/// a step onto unclaimed ground ends it with nothing. Leaving his ground is always the answer.
/obj/effect/hallucination/simple/bunnyman
	image_icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	image_state = "bunnyman_enraged"
	px = -16
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion

/obj/effect/hallucination/simple/bunnyman/Initialize(mapload, mob/living/carbon/T, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/new_distortion)
	. = ..()
	distortion = new_distortion
	distortion.Own(src)
	target.playsound_local(get_turf(src), 'sound/distortions/bunnyman/scream.ogg', 40, FALSE)
	addtimer(CALLBACK(src, PROC_REF(Step)), distortion.hallucination_step)

/obj/effect/hallucination/simple/bunnyman/Destroy()
	distortion = null
	return ..()

/obj/effect/hallucination/simple/bunnyman/proc/Step()
	if(QDELETED(target) || !distortion || target.z != z)
		qdel(src)
		return
	var/turf/next = get_step_towards(src, target)
	if(!next || !distortion.territory.Contains(next))
		qdel(src)
		return
	forceMove(next)
	target.playsound_local(next, pick(distortion.footstep_sounds), 50, TRUE)
	if(get_dist(src, target) <= 1)
		var/mob/living/carbon/human/H = target
		to_chat(H, span_userdanger("He is on you. And then he is not."))
		H.adjustSanityLoss(distortion.hallucination_sanity)
		qdel(src)
		return
	addtimer(CALLBACK(src, PROC_REF(Step)), distortion.hallucination_step)

/// From hallucination_stage, one rabbit every mimic_interval that has a human in view takes his shape and runs at them.
/// The interval only counts from a mimic that happened; a scan that found nobody looks again after mimic_retry.
/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/proc/MimicTick()
	if(territory.stage < hallucination_stage || !judging || world.time < next_mimic)
		return
	for(var/mob/living/simple_animal/hostile/bunnyman_rabbit/R in shuffle(rabbits))
		if(R.stat == DEAD || R.mimic_target)
			continue
		for(var/mob/living/carbon/human/H in view(7, R))
			if(H.stat == CONSCIOUS && H.client && H != hunt_target)
				R.Mimic(H)
				next_mimic = world.time + mimic_interval
				return
	next_mimic = world.time + mimic_retry
