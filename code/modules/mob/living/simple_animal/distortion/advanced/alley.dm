// A test subtype and the template for new ones: the same distortion, limited to the city's alleys and the
// rooms off them. Spawn it in an alley. The territory follows the alleys and goes into alleyway rooms,
// including barricaded ones, never spills onto the streets, and from stage 2 the centre fills with grime.
/mob/living/simple_animal/hostile/distortion/advanced/alley
	name = "alley distortion"
	desc = "Something that has made the back alleys its own."
	territory_areas = list(/area/city/alleyways, /area/city/alleyway_room)
	/// Turfs the centre effect has already dirtied, so a later stage only adds the new ring.
	var/list/dirtied = list()

/mob/living/simple_animal/hostile/distortion/advanced/alley/ApplyCenterEffects(list/turfs)
	for(var/turf/T in turfs)
		if((T in dirtied) || !isopenturf(T))
			continue
		dirtied += T
		var/obj/effect/decal/cleanable/dirt/grime = new(T)
		grime.color = "#4a4238"
		owned += grime
