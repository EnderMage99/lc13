// The marks. Each mark's alert shows a red background while its owner stands in the territory, the plain one outside.

/// Shared by every mark: the territory they belong to, and the alert swap at its edge.
/datum/status_effect/bunnyman_mark
	id = "bunnyman_mark"
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark
	/// Whose ground this is. Null once he is gone, and the mark then runs out anywhere.
	var/mob/living/simple_animal/hostile/distortion/advanced/bunnyman/distortion
	/// The alert's plain icon state; "_inside" is added while the owner stands on claimed turf.
	var/alert_state = "perpetrator"
	/// Set each tick so the alert only changes when the edge is crossed.
	var/inside = FALSE

/atom/movable/screen/alert/status_effect/bunnyman_mark
	icon = 'ModularLobotomy/_Lobotomyicons/bunnyman_alerts.dmi'
	icon_state = "perpetrator"

/datum/status_effect/bunnyman_mark/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/new_distortion)
	. = ..()
	if(!.)
		return
	if(new_distortion)
		distortion = new_distortion
		RegisterSignal(distortion, COMSIG_PARENT_QDELETING, PROC_REF(OnDistortionDeleted))
	UpdateAlert(TRUE)

/datum/status_effect/bunnyman_mark/on_remove()
	distortion = null
	return ..()

/datum/status_effect/bunnyman_mark/proc/OnDistortionDeleted(datum/source)
	SIGNAL_HANDLER
	distortion = null
	UpdateAlert()

/datum/status_effect/bunnyman_mark/proc/Inside()
	return distortion && distortion.territory && distortion.territory.Contains(get_turf(owner))

/// Swaps the alert between the plain icon and the red one as the owner crosses the territory's edge.
/datum/status_effect/bunnyman_mark/proc/UpdateAlert(force = FALSE)
	var/now_inside = Inside()
	if(!force && now_inside == inside)
		return
	inside = now_inside
	if(linked_alert)
		linked_alert.icon_state = inside ? "[alert_state]_inside" : alert_state

/datum/status_effect/bunnyman_mark/tick()
	UpdateAlert()

/// Drew blood on his ground. He hunts whoever carries this, one at a time. Anyone may hit a Perpetrator freely.
/// It fades after perpetrator_decay spent outside the territory; inside it holds.
/datum/status_effect/bunnyman_mark/perpetrator
	id = "bunnyman_perpetrator"
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark/perpetrator
	alert_state = "perpetrator"
	var/perpetrator_decay = 3 MINUTES
	/// Time spent outside so far, in deciseconds.
	var/outside_time = 0

/atom/movable/screen/alert/status_effect/bunnyman_mark/perpetrator
	name = "Perpetrator"
	desc = "You drew blood on his ground. He has already decided what you are."
	icon_state = "perpetrator"

/datum/status_effect/bunnyman_mark/perpetrator/tick()
	. = ..()
	if(inside)
		outside_time = 0
		return
	outside_time += initial(tick_interval)
	if(outside_time >= perpetrator_decay)
		qdel(src)

/datum/status_effect/bunnyman_mark/perpetrator/on_remove()
	if(distortion)
		distortion.OnPerpetratorCleared(owner)
	return ..()

/// Had blood drawn from them on his ground. A Victim may hit their own Perpetrator without being judged for it.
/datum/status_effect/bunnyman_mark/victim
	id = "bunnyman_victim"
	duration = 1 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark/victim
	alert_state = "victim"
	/// Who struck them. The one target they may strike back at freely.
	var/mob/living/perpetrator
	/// Whether he has already brought them a carrot.
	var/fed = FALSE

/atom/movable/screen/alert/status_effect/bunnyman_mark/victim
	name = "Victim"
	desc = "Something was done to you on his ground. He has taken your side, whether you wanted it or not."
	icon_state = "victim"

/datum/status_effect/bunnyman_mark/victim/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/distortion/advanced/bunnyman/new_distortion, mob/living/new_perpetrator)
	. = ..()
	if(!.)
		return
	SetPerpetrator(new_perpetrator)

/datum/status_effect/bunnyman_mark/victim/on_remove()
	if(perpetrator)
		UnregisterSignal(perpetrator, COMSIG_PARENT_QDELETING)
		perpetrator = null
	return ..()

/// A Victim keeps the newest person to strike them; the duration restarts with each one.
/datum/status_effect/bunnyman_mark/victim/proc/SetPerpetrator(mob/living/new_perpetrator)
	if(perpetrator)
		UnregisterSignal(perpetrator, COMSIG_PARENT_QDELETING)
	perpetrator = new_perpetrator
	if(perpetrator)
		RegisterSignal(perpetrator, COMSIG_PARENT_QDELETING, PROC_REF(OnPerpetratorDeleted))
	refresh()

/datum/status_effect/bunnyman_mark/victim/proc/OnPerpetratorDeleted(datum/source)
	SIGNAL_HANDLER
	perpetrator = null

/// He saw them at his things and said so. Two warnings are kept on it; the third is the Perpetrator mark.
/datum/status_effect/bunnyman_mark/warned
	id = "bunnyman_warned"
	duration = 10 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark/warned
	alert_state = "warned1"
	var/warnings = 1

/atom/movable/screen/alert/status_effect/bunnyman_mark/warned
	name = "Warned"
	desc = "He has seen you at his things, and said so. He will not say it a third time."
	icon_state = "warned1"

/datum/status_effect/bunnyman_mark/warned/proc/AddWarning()
	warnings++
	alert_state = "warned2"
	UpdateAlert(TRUE)
	refresh()

/// Taken off his hook while he was not looking. The first time he sees them, it is the Perpetrator mark.
/datum/status_effect/bunnyman_mark/paranoid
	id = "bunnyman_paranoid"
	duration = 10 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/bunnyman_mark/paranoid
	alert_state = "paranoid"

/atom/movable/screen/alert/status_effect/bunnyman_mark/paranoid
	name = "Paranoid"
	desc = "You came down off his hook while he was not looking. If he sees you, he will know."
	icon_state = "paranoid"
