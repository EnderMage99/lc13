// Wire visibility toggle tool for cleaner aesthetics
/obj/item/wire_hider
	name = "cable concealer"
	desc = "A tool that can hide or reveal power cables in the area. Alt-click to toggle between hide and reveal modes."
	icon = 'icons/obj/device.dmi'
	icon_state = "locator"
	w_class = WEIGHT_CLASS_SMALL
	var/hiding_mode = TRUE // TRUE = hide cables, FALSE = reveal cables
	var/range = 7

/obj/item/wire_hider/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Currently set to <b>[hiding_mode ? "HIDE" : "REVEAL"]</b> cables.</span>"
	. += "<span class='notice'>Alt-click to switch modes.</span>"
	. += "<span class='notice'>Use in hand to [hiding_mode ? "hide" : "reveal"] cables within [range] tiles.</span>"

/obj/item/wire_hider/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	hiding_mode = !hiding_mode
	to_chat(user, "<span class='notice'>Switched to <b>[hiding_mode ? "HIDE" : "REVEAL"]</b> mode.</span>")
	playsound(src, 'sound/weapons/empty.ogg', 30, TRUE)
	icon_state = hiding_mode ? "locator" : "locator_on"

/obj/item/wire_hider/attack_self(mob/user)
	if(!user)
		return

	var/affected_count = 0
	var/turf/center = get_turf(user)

	if(!center)
		return

	// Get all turfs in range
	for(var/turf/T in range(range, center))
		for(var/obj/structure/cable/C in T)
			if(hiding_mode)
				// Hide cables
				if(C.alpha != 0)
					C.alpha = 0
					C.mouse_opacity = FALSE
					affected_count++
			else
				// Reveal cables
				if(C.alpha == 0)
					C.alpha = 255
					C.mouse_opacity = TRUE
					affected_count++

	if(affected_count)
		to_chat(user, "<span class='notice'>You [hiding_mode ? "concealed" : "revealed"] [affected_count] cable segment\s.</span>")
		playsound(src, 'sound/effects/pop.ogg', 50, TRUE)
	else
		to_chat(user, "<span class='notice'>No cables to [hiding_mode ? "hide" : "reveal"] in range.</span>")

/obj/item/wire_hider/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag)
		return

	// Allow targeting specific tiles
	if(isturf(target))
		var/affected_count = 0
		for(var/obj/structure/cable/C in target)
			if(hiding_mode)
				if(C.alpha != 0)
					C.alpha = 0
					C.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
					affected_count++
			else
				if(C.alpha == 0)
					C.alpha = 255
					C.mouse_opacity = MOUSE_OPACITY_ICON
					affected_count++

		if(affected_count)
			to_chat(user, "<span class='notice'>You [hiding_mode ? "concealed" : "revealed"] [affected_count] cable\s on this tile.</span>")
			playsound(src, 'sound/effects/pop.ogg', 30, TRUE)
		else
			to_chat(user, "<span class='notice'>No cables to [hiding_mode ? "hide" : "reveal"] here.</span>")

// Debug version with extended range
/obj/item/wire_hider/debug
	name = "advanced cable concealer"
	desc = "An enhanced version with extended range. For testing purposes."
	range = 14
	icon_state = "locator_on"
