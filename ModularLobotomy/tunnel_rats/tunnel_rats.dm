#define TUNNEL_SOURCE "Tunnel Source"
#define TUNNEL_READY "Tunnel Ready"

/obj/item/shovel/tunnel
	name = "tunneling shovel"
	desc = "A sturdy shovel made for digging straight down. Use it in hand to dig a tunnel, or to dig back out."
	color = "#C08A4F"
	var/first_dig_time = 10 SECONDS
	var/dig_time = 4 SECONDS
	var/digging = FALSE

/obj/item/shovel/tunnel/attack_self(mob/living/user)
	if(digging || !isturf(user.loc))
		return
	var/turf/T = user.loc
	var/source_z = SSmapping.level_trait(T.z, TUNNEL_SOURCE)
	if(source_z)
		DigUp(user, T, source_z)
		return
	DigDown(user, T)

/obj/item/shovel/tunnel/proc/DigDown(mob/living/user, turf/T)
	if(isspaceturf(T) || istype(T, /turf/open/water) || istype(T.loc, /area/space) || is_reserved_level(T.z) || is_centcom_level(T.z))
		to_chat(user, span_warning("You can't dig here."))
		return
	if(locate(/obj/structure/tunnel_hole) in T)
		to_chat(user, span_warning("There is already a tunnel here."))
		return
	var/datum/space_level/tunnels = GetTunnelLevel(T.z)
	var/delay = first_dig_time
	var/turf/open_below
	if(tunnels && isopenturf(locate(T.x, T.y, tunnels.z_value)))
		open_below = locate(T.x, T.y, tunnels.z_value)
		delay = dig_time
	if(!tunnels)
		tunnels = SSmapping.add_new_zlevel("Tunnels [T.z]", list(TUNNEL_SOURCE = T.z, ZTRAIT_GRAVITY = TRUE, ZTRAIT_BASETURF = /turf/open/floor/plating/dirt))
		INVOKE_ASYNC(src, PROC_REF(BuildTunnels), tunnels, T.z)
	to_chat(user, span_notice("You start digging down..."))
	if(!Dig(user, T, delay, open_below))
		return
	UNTIL(tunnels.traits[TUNNEL_READY])
	if(locate(/obj/structure/tunnel_hole) in T)
		return
	var/turf/below = locate(T.x, T.y, tunnels.z_value)
	if(istype(below, /turf/open/water))
		to_chat(user, span_warning("Water floods up through the hole. You can't dig here."))
		return
	if(isclosedturf(below))
		if(!ismineralturf(below))
			to_chat(user, span_warning("You hit rock too dense to dig through."))
			return
		below = below.ScrapeAway()
	var/obj/structure/tunnel_hole/top = MakeTunnel(T, below)
	top.Travel(user)
	playsound(below, 'sound/effects/ordeals/amber/dawn_dig_out.ogg', 50, TRUE, 4)

/obj/item/shovel/tunnel/proc/DigUp(mob/living/user, turf/T, source_z)
	var/turf/above = locate(T.x, T.y, source_z)
	if(istype(T, /turf/open/water) || istype(above, /turf/open/water))
		to_chat(user, span_warning("There is water above you. Digging up would flood the tunnel."))
		return
	if(!CanDigUp(above))
		to_chat(user, span_warning("There is solid ground above you."))
		return
	if(locate(/obj/structure/tunnel_hole) in T)
		to_chat(user, span_warning("There is already a way out here."))
		return
	to_chat(user, span_notice("You start digging up..."))
	if(!Dig(user, T, dig_time, above))
		return
	if(!CanDigUp(above) || (locate(/obj/structure/tunnel_hole) in T))
		return
	var/obj/structure/tunnel_hole/top = MakeTunnel(above, T)
	top.linked.Travel(user)
	playsound(above, 'sound/effects/ordeals/amber/dawn_dig_out.ogg', 50, TRUE, 4)

/obj/item/shovel/tunnel/proc/Dig(mob/living/user, turf/T, delay, turf/other_end)
	digging = TRUE
	INVOKE_ASYNC(src, PROC_REF(DirtStorm), user, delay)
	if(other_end)
		INVOKE_ASYNC(src, PROC_REF(DirtStorm), other_end, delay)
	playsound(T, 'sound/effects/ordeals/amber/dawn_dig_in.ogg', 35, TRUE, 3)
	. = use_tool(T, user, delay)
	digging = FALSE

/obj/item/shovel/tunnel/proc/DirtStorm(atom/center, delay)
	for(var/i in 1 to delay)
		if(!digging || QDELETED(center))
			return
		for(var/j in 1 to 3)
			var/turf/T = prob(55) ? get_turf(center) : get_step(center, pick(GLOB.alldirs))
			if(T)
				new /obj/effect/temp_visual/warren_dirt(T)
		sleep(2)

/obj/item/shovel/tunnel/proc/CanDigUp(turf/above)
	if(isclosedturf(above) || isspaceturf(above) || istype(above, /turf/open/water) || istype(above.loc, /area/space))
		return FALSE
	if(locate(/obj/structure/tunnel_hole) in above)
		return FALSE
	return TRUE

/obj/item/shovel/tunnel/proc/MakeTunnel(turf/surface_turf, turf/tunnel_turf)
	var/obj/structure/tunnel_hole/top = new(surface_turf)
	var/obj/structure/tunnel_hole/ladder/bottom = new(tunnel_turf)
	top.linked = bottom
	bottom.linked = top
	return top

/obj/item/shovel/tunnel/proc/GetTunnelLevel(source_z)
	for(var/datum/space_level/level as anything in SSmapping.z_list)
		if(level.traits[TUNNEL_SOURCE] == source_z)
			return level

/obj/item/shovel/tunnel/proc/BuildTunnels(datum/space_level/tunnels, source_z)
	var/area/underground = GLOB.areas_by_type[/area/lavaland/underground]
	if(!underground)
		underground = new /area/lavaland/underground(null)
	for(var/turf/T as anything in block(locate(1, 1, tunnels.z_value), locate(world.maxx, world.maxy, tunnels.z_value)))
		var/turf/above = locate(T.x, T.y, source_z)
		underground.contents += T
		if(istype(above.loc, /area/space))
			T.ChangeTurf(/turf/closed/indestructible/rock)
		else if(istype(above, /turf/open/water/deep))
			T.ChangeTurf(above.type)
		else if(isclosedturf(above))
			T.ChangeTurf(/turf/closed/mineral/ash_rock)
		else
			T.ChangeTurf(/turf/closed/mineral/ash_rock/dirt)
		CHECK_TICK
	tunnels.traits[TUNNEL_READY] = TRUE
	log_game("Tunnel level [tunnels.z_value] built under z-level [source_z].")

/turf/closed/mineral/ash_rock/dirt
	name = "packed dirt"
	desc = "Loose, damp earth. It would not take much to dig through."
	color = "#9B7653"
	baseturfs = /turf/open/floor/plating/dirt
	turf_type = /turf/open/floor/plating/dirt
	var/mine_time = 1.5 SECONDS

/turf/closed/mineral/ash_rock/dirt/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour != TOOL_MINING || !ISADVANCEDTOOLUSER(user) || !isturf(user.loc))
		return ..()
	to_chat(user, span_notice("You start digging through the dirt..."))
	if(I.use_tool(src, user, mine_time, volume = 50) && ismineralturf(src))
		gets_drilled(user, TRUE)

/obj/structure/tunnel_hole
	name = "tunnel"
	desc = "A freshly dug hole. It looks like it could cave in at the slightest knock."
	icon = 'icons/mob/nest.dmi'
	icon_state = "hole"
	anchored = TRUE
	density = FALSE
	var/obj/structure/tunnel_hole/linked
	var/climb_time = 1 SECONDS
	var/fill_time = 3 SECONDS

/obj/structure/tunnel_hole/Destroy()
	if(linked)
		linked.linked = null
		QDEL_NULL(linked)
	return ..()

/obj/structure/tunnel_hole/attack_hand(mob/living/user)
	. = ..()
	if(. || !linked)
		return
	to_chat(user, span_notice("You start climbing through [src]..."))
	if(!do_after(user, climb_time, src))
		return
	Travel(user)

/obj/structure/tunnel_hole/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_SHOVEL)
		to_chat(user, span_notice("You start filling in [src]..."))
		if(I.use_tool(src, user, fill_time, volume = 50))
			visible_message(span_notice("[user] fills in [src]."))
			qdel(src)
		return
	if(!I.force)
		return ..()
	visible_message(span_warning("[src] caves in as [user] hits it with [I]!"))
	playsound(src, 'sound/effects/break_stone.ogg', 50, TRUE)
	playsound(linked, 'sound/effects/break_stone.ogg', 50, TRUE)
	qdel(src)

/obj/structure/tunnel_hole/proc/Travel(mob/living/user)
	if(!linked)
		return
	var/turf/destination = get_turf(linked)
	var/atom/movable/pulled = user.pulling
	user.forceMove(destination)
	if(!pulled)
		return
	pulled.forceMove(destination)
	if(user.pulling != pulled)
		user.start_pulling(pulled)

/obj/structure/tunnel_hole/ladder
	name = "ladder"
	desc = "A rough ladder leading up to a hole in the ceiling. Daylight spills down through it."
	icon = 'icons/obj/structures.dmi'
	icon_state = "ladder10"
	light_range = 3
	light_power = 1.5
	light_color = "#FFF4D6"

#undef TUNNEL_SOURCE
#undef TUNNEL_READY
