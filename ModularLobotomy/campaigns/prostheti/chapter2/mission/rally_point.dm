// =============================================
// Prostheti Innovations — Mission Rally Point (Chapter 2)
// =============================================
// Signup object spawned in the Training Yard after the "We're ready"
// cutscene. Players click to join the factory infiltration mission.
// 30-second countdown starts on first signup; first player can close early.

/obj/structure/mission_rally/factory_infiltration
	name = "Mission Rally Point"
	desc = "Penny is waiting at the exit. Click to join the factory infiltration."
	icon = 'icons/obj/stationobjs.dmi'	// TEMP — needs rally point visual
	icon_state = "signpost"	// TEMP
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE

	/// Players who have signed up
	var/list/mob/living/signed_up = list()
	/// Maximum players allowed
	var/max_players = 4
	/// Timer ID for the signup countdown
	var/signup_timer
	/// Whether signup is still open
	var/signup_open = TRUE
	/// Whether a mission is currently active (blocks interaction)
	var/mission_active = FALSE
	/// Reference to the campaign controller
	var/datum/campaign_controller/prostheti/campaign

/obj/structure/mission_rally/factory_infiltration/Initialize(mapload)
	. = ..()
	campaign = GLOB.prostheti_campaign

/obj/structure/mission_rally/factory_infiltration/Destroy()
	signed_up.Cut()
	campaign = null
	if(signup_timer)
		deltimer(signup_timer)
	return ..()

/obj/structure/mission_rally/factory_infiltration/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!user || !user.client || !isliving(user))
		return
	if(mission_active)
		to_chat(user, span_warning("A mission is already in progress."))
		return
	if(!signup_open)
		to_chat(user, span_warning("Signup has already closed."))
		return

	// Already signed up — first player can close early
	if(user in signed_up)
		if(signed_up[1] == user && length(signed_up) >= 1)
			to_chat(user, span_notice("You signal that everyone is here."))
			CloseSignup()
		else
			to_chat(user, span_notice("You've already signed up. Waiting for others..."))
		return

	// Sign up
	if(length(signed_up) >= max_players)
		to_chat(user, span_warning("The team is full."))
		return

	signed_up += user
	// Announce to all players on the z-level
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.client && H.z == src.z)
			to_chat(H, span_notice("[user.name] is joining the mission. ([length(signed_up)]/[max_players])"))

	// Start countdown on first signup
	if(length(signed_up) == 1)
		to_chat(user, span_notice("Signup opens for 30 seconds. Click again to close early when everyone is ready."))
		signup_timer = addtimer(CALLBACK(src, PROC_REF(CloseSignup)), 30 SECONDS, TIMER_STOPPABLE)

	// Auto-close if full
	if(length(signed_up) >= max_players)
		CloseSignup()

/// Closes signup and starts the mission.
/obj/structure/mission_rally/factory_infiltration/proc/CloseSignup()
	if(!signup_open)
		return
	signup_open = FALSE
	if(signup_timer)
		deltimer(signup_timer)
		signup_timer = null

	if(!length(signed_up))
		return

	// Announce mission start
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.client && H.z == src.z)
			to_chat(H, span_boldnotice("The mission is starting with [length(signed_up)] participant\s."))

	// Create and start the mission
	mission_active = TRUE
	if(campaign)
		var/datum/prostheti_mission/factory_infiltration/mission = new()
		mission.rally_point = src
		campaign.active_mission = mission
		mission.BeginMission(signed_up)

/// Resets the rally point for re-entry after Broken Fate.
/obj/structure/mission_rally/factory_infiltration/proc/ResetForReentry()
	signed_up.Cut()
	signup_open = TRUE
	mission_active = FALSE
