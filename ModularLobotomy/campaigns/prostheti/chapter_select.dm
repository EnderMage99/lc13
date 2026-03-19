// =============================================
// Prostheti Innovations — Chapter Select Landmark
// =============================================
// Place near the bus stop / factory entrance on the Prostheti hub map.
// First thing players see when they arrive via bus.
// Allows players with cross-round progress to skip ahead.
// One selection per round — affects all players.

/obj/structure/prostheti_chapter_select
	name = "Prostheti Innovations Directory"
	desc = "A polished terminal displaying the Prostheti Innovations logo. It seems to track ongoing projects."
	icon = 'icons/obj/stationobjs.dmi'	// TEMP — signpost stand-in, needs custom chapter select sprite
	icon_state = "signpost"	// TEMP
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// Reference to the campaign controller
	var/datum/campaign_controller/prostheti/campaign
	/// DEBUG: When TRUE, all chapters are selectable regardless of progress
	var/debug_unlock_all = FALSE

/obj/structure/prostheti_chapter_select/Initialize(mapload)
	. = ..()
	// Campaign controller will be created when the map loads — find or create it
	if(!GLOB.prostheti_campaign)
		new /datum/campaign_controller/prostheti()
	campaign = GLOB.prostheti_campaign

/obj/structure/prostheti_chapter_select/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!user || !user.client)
		return
	ui_interact(user)

/obj/structure/prostheti_chapter_select/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ProsthetiChapterSelect")
		ui.open()

/obj/structure/prostheti_chapter_select/ui_data(mob/user)
	var/list/data = list()

	if(!campaign)
		campaign = GLOB.prostheti_campaign

	// Check if a chapter was already selected this round
	data["already_selected"] = campaign?.chapter_selected
	data["selected_chapter"] = campaign?.current_chapter

	// Get player's personal progress
	var/highest_completed = 0
	if(user.client && user.ckey)
		highest_completed = SSpersistence.GetProsthetiProgress(user.ckey)
	data["highest_completed"] = highest_completed
	data["player_name"] = user.name

	// Build chapters list
	var/list/chapters = list()
	for(var/i in 1 to 7)
		var/chapter_key = "[i]"
		var/list/ch_data = campaign?.chapter_data[chapter_key]
		var/list/chapter = list()
		chapter["number"] = i
		chapter["title"] = ch_data ? ch_data["title"] : "Chapter [i]"
		chapter["subtitle"] = ch_data ? ch_data["subtitle"] : ""
		chapter["color"] = ch_data ? ch_data["color"] : "#FFFFFF"
		chapter["description"] = campaign?.chapter_descriptions[chapter_key] || ""
		chapter["unlocked"] = (debug_unlock_all || i <= highest_completed + 1)
		chapter["is_new"] = (i == highest_completed + 1 && highest_completed > 0)
		chapters += list(chapter)
	data["chapters"] = chapters

	return data

/obj/structure/prostheti_chapter_select/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	if(!campaign)
		campaign = GLOB.prostheti_campaign

	switch(action)
		if("select")
			if(campaign.chapter_selected)
				to_chat(usr, span_warning("A chapter has already been selected this round."))
				return TRUE

			var/chapter_num = text2num(params["chapter"])
			if(!chapter_num || chapter_num < 1 || chapter_num > 7)
				return TRUE

			// Validate the player has unlocked this chapter
			var/highest_completed = 0
			if(usr.client && usr.ckey)
				highest_completed = SSpersistence.GetProsthetiProgress(usr.ckey)
			if(!debug_unlock_all && chapter_num > highest_completed + 1)
				to_chat(usr, span_warning("You haven't unlocked that chapter yet."))
				return TRUE

			// Lock the selection
			campaign.chapter_selected = TRUE
			campaign.InitializeAtChapter(chapter_num)

			// Announce to all players on the z-level
			for(var/mob/living/carbon/human/H in GLOB.player_list)
				if(H.client && H.z == src.z)
					to_chat(H, span_notice("<b>Prostheti Innovations:</b> Chapter [chapter_num] — [campaign.chapter_data["[chapter_num]"]["title"]] has been selected for this session."))

			return TRUE
