// =============================================
// Prostheti Innovations — Chapter Transition Blurb & Broken Fate Screen
// =============================================
// Chapter transition blurb follows the ShowOrdealBlurb pattern from
// code/modules/ordeals/_ordeal.dm (lines 138-159).
// Broken Fate screen uses fullscreen overlays with show_when_dead = TRUE.

// =============================================
// Custom Fullscreen Type — Broken Fate Background
// =============================================

/atom/movable/screen/fullscreen/broken_fate_bg
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "flash"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = SPLASHSCREEN_PLANE
	layer = SPLASHSCREEN_LAYER - 1
	color = "#000000"
	show_when_dead = TRUE

// =============================================
// Custom Overlay — Chapter Blurb Background (semi-transparent band)
// =============================================

/obj/effect/overlay/prostheti_blurb_bg
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "black"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = "1,10 to 17,14"
	alpha = 0
	layer = UNDER_HUD_LAYER
	plane = HUD_PLANE - 1
	appearance_flags = APPEARANCE_UI_IGNORE_ALPHA

/obj/effect/overlay/prostheti_blurb_bg/Initialize()
	. = ..()
	animate(src, alpha = 175, time = 10)

// =============================================
// Chapter Transition Blurb
// =============================================

/// Shows a chapter transition blurb to all provided clients.
/// Follows the ShowOrdealBlurb pattern: overlay text + semi-transparent BG band.
/proc/ShowChapterBlurb(list/clients, chapter_number)
	if(!length(clients))
		return

	var/datum/campaign_controller/prostheti/campaign = GLOB.prostheti_campaign
	if(!campaign)
		return

	var/chapter_key = "[chapter_number]"
	var/list/ch_data = campaign.chapter_data[chapter_key]
	if(!ch_data)
		return

	var/ch_title = ch_data["title"]
	var/ch_subtitle = ch_data["subtitle"]
	var/ch_color = ch_data["color"]

	var/style1 = "font-family: 'Baskerville'; text-align: center; color: [ch_color]; font-size: 12pt;"
	var/style2 = "font-family: 'Baskerville'; text-align: center; color: #FFFFFF; font-size: 14pt; font-weight: bold;"
	var/style3 = "font-family: 'Baskerville'; text-align: center; color: [ch_color]; font-size: 10pt;"

	for(var/client/C in clients)
		if(!C)
			continue

		// Text overlay
		var/obj/effect/overlay/T = new()
		T.alpha = 0
		T.maptext_height = 120
		T.maptext_width = 424
		T.layer = FLOAT_LAYER
		T.plane = HUD_PLANE
		T.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
		T.screen_loc = "Center-6,Center+3"
		T.maptext = "<span style=\"[style1]\">Prostheti Innovations</span><br><span style=\"[style2]\">[ch_title]</span><br><span style=\"[style3]\">[ch_subtitle]</span>"

		// Background band
		var/obj/effect/overlay/prostheti_blurb_bg/BG = new()

		C.screen += T
		C.screen += BG
		animate(T, alpha = 255, time = 10)

		// Fade out after 4 seconds (40 deciseconds)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(fade_blurb), C, T, 10), 40)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(fade_blurb), C, BG, 10), 40)

// =============================================
// Broken Fate Screen
// =============================================

/// Shows the "BROKEN FATE" fullscreen overlay to all participants.
/// Uses fullscreen overlay system with show_when_dead = TRUE so dead players see it.
/proc/ShowBrokenFateScreen(list/mob/living/participants)
	if(!length(participants))
		return

	var/style = "font-family: 'Baskerville'; text-align: center; color: #FFFFFF; font-size: 18pt; font-weight: bold; letter-spacing: 8px;"

	for(var/mob/living/P in participants)
		if(!P)
			continue

		// Full black background via fullscreen overlay
		P.overlay_fullscreen("broken_fate_bg", /atom/movable/screen/fullscreen/broken_fate_bg)

		// Text overlay on top
		if(P.client)
			var/obj/effect/overlay/T = new()
			T.alpha = 0
			T.maptext_height = 80
			T.maptext_width = 424
			T.layer = FLOAT_LAYER
			T.plane = SPLASHSCREEN_PLANE
			T.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
			T.screen_loc = "Center-6,Center"
			T.maptext = "<span style=\"[style]\">BROKEN FATE</span>"
			P.client.screen += T
			animate(T, alpha = 255, time = 5)

			// Fade text after 3.5 seconds
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(fade_blurb), P.client, T, 5), 35)
