// Nurseries: one behind each toll gate. His summons travel between him and his nurseries as a green light racing along
// the way, ride_speed tiles a tick, leaving a fading trail. A wave for a Foe nearer a nursery than him goes out that
// way, and a summon rides whenever that saves it ride_margin tiles of walking. If the nursery it is bound for breaks
// on the way, the riders drop out wherever the light has got to.

/mob/living/simple_animal/hostile/distortion/advanced/prince
	/// His standing nurseries.
	var/list/nurseries = list()
	/// Ways between his nodes, by "[REF(from)]>[REF(dest)]": the fort_version it was found at, then the route.
	var/list/node_routes = list()
	/// Tiles the light covers each tick.
	var/ride_speed = 2
	/// A summon only rides when that is this many tiles shorter than walking.
	var/ride_margin = 10

/// The node nearest A: him, or one of his nurseries.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/NodeNear(atom/A)
	. = src
	var/best = get_dist(src, A)
	for(var/obj/structure/prince_nursery/N as anything in nurseries)
		var/dist = get_dist(N, A)
		if(dist < best)
			. = N
			best = dist

/// The way from one node to another, found now if none is kept for the fort as it stands. It may search. From him to
/// a nursery it follows the nursery's trail, so the light runs along it.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/NodeRoute(atom/from, atom/dest)
	if(from == src)
		for(var/datum/prince_ring/toll/R as anything in toll_routes)
			if(R.nest == get_turf(dest))
				return toll_routes[R]
	var/key = "[REF(from)]>[REF(dest)]"
	var/list/kept = node_routes[key]
	if(kept && kept[1] == fort_version)
		return kept[2]
	var/list/route = RouteTo(get_turf(dest), get_turf(from))
	if(!QDELETED(src) && !torn_down)
		node_routes[key] = list(fort_version, route)
	return route

/// Sends riders from a node to a nursery as a light along the way between. They wait inside it, out of reach, and come
/// out beside the nursery, or wherever the light got to if it broke. With no way there they come out where they began.
/mob/living/simple_animal/hostile/distortion/advanced/prince/proc/Ride(list/riders, atom/from, obj/structure/prince_nursery/dest)
	set waitfor = FALSE
	var/obj/effect/prince_light/light = new(get_turf(from))
	Own(light)
	for(var/mob/living/simple_animal/hostile/prince_follower/F as anything in riders)
		F.toggle_ai(AI_OFF)
		F.forceMove(light)
	var/list/route = NodeRoute(from, dest)
	// the last turf is the nursery itself, which is solid
	for(var/i in 2 to length(route) - 1)
		if(QDELETED(light) || QDELETED(dest))
			break
		light.forceMove(route[i])
		new /obj/effect/temp_visual/prince_light_trail(route[i])
		if(!(i % ride_speed))
			sleep(1)
	if(QDELETED(light))
		return
	var/turf/out = get_turf(light)
	for(var/mob/living/simple_animal/hostile/prince_follower/F in light)
		F.forceMove(out)
		F.toggle_ai(AI_ON)
	qdel(light)

/obj/effect/prince_light
	name = "green light"
	desc = "A mote of green light, racing along the ground."
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparkles"
	color = "#6cff4a"
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	light_range = 2
	light_power = 1
	light_color = "#6cff4a"

/obj/effect/temp_visual/prince_light_trail
	icon_state = "sparkles"
	color = "#6cff4a"
	duration = 8
	light_range = 1
	light_power = 0.5
	light_color = "#6cff4a"

/obj/effect/temp_visual/prince_light_trail/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = duration)

// The nursery itself: a pod behind each toll gate. Hitting it makes you a Foe, like the rest of the fort.

/obj/structure/prince_nursery
	name = "nursery"
	desc = "A swollen pod of root and goop. A green light swims inside it, waiting to be sent somewhere."
	icon = 'ModularLobotomy/_Lobotomyicons/prince_structures.dmi'
	icon_state = "nursery"
	anchored = TRUE
	density = TRUE
	max_integrity = 600
	/// The distortion it belongs to. Null if an admin spawned it alone.
	var/mob/living/simple_animal/hostile/distortion/advanced/prince/prince

/obj/structure/prince_nursery/Initialize(mapload, new_prince, instant = FALSE)
	. = ..()
	prince = new_prince
	prince?.nurseries += src
	if(!instant)
		PrinceRise(src, 32)

/obj/structure/prince_nursery/Destroy()
	if(prince)
		prince.nurseries -= src
		// routes to and from it are no use now
		prince.node_routes.Cut()
	prince = null
	return ..()

/obj/structure/prince_nursery/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	Struck(user)

/obj/structure/prince_nursery/bullet_act(obj/projectile/P)
	. = ..()
	Struck(P.firer)

/obj/structure/prince_nursery/attack_animal(mob/living/simple_animal/M)
	. = ..()
	Struck(M)

/obj/structure/prince_nursery/proc/Struck(mob/living/by)
	if(!prince || !isliving(by) || istype(by, /mob/living/simple_animal/hostile/prince_follower))
		return
	prince.MakeFoe(by)
