//Lunar Physician: a hands-having LCL "physician" that mixes chems into containers it holds,
//eats carrots/puddings/mochi (Instinct), and is worked through Repression. Based on the
//Lunar Rabbit abnormality but tankier and slower, and with none of its timed-breach code.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit
	true_name = "Lunar Physician"
	original_abno = /mob/living/simple_animal/hostile/abnormality/lunar_rabbit
	//Shared-but-tankier-and-slower stats.
	maxHealth = 500
	health = 500
	speed = 1 //Slightly slower than the baseline player abno (higher = slower).
	rapid_melee = 2
	melee_damage_lower = 2
	melee_damage_upper = 25
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "cuts"
	attack_verb_simple = "cut"
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	attack_sound = 'sound/abnormalities/cleave.ogg'
	//Hands (engine dextrous feature, copied from the gorilla/cassowary recipe).
	dextrous = TRUE
	held_items = list(null, null)
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM)
	//Diet: puddings, carrots and mochi. Instinct work feeds desire on eating a favourite.
	diet_list = list(
		/obj/item/food/bnuuypudding,
		/obj/item/food/rcorppudding,
		/obj/item/food/myopudding,
		/obj/item/food/mattpudding,
		/obj/item/food/zilupudding,
		/obj/item/food/mumupudding,
		/obj/item/kitchen/knife/shiv/carrot,
		/obj/item/food/cake/carrot,
		/obj/item/food/cakeslice/carrot,
		/obj/item/food/carrotfries,
		/obj/item/food/grown/carrot,
		/obj/item/food/mochi,
	)
	diet_value = 5
	desire_on_eat = 10
	//Repression work: taking meaningful hits feeds desire.
	rep_desire_gain = 20
	//Attachment (disliked) - being pet make her lose desire. She is too busy cooking.
	desire_on_pet = -5
	//Insight: it likes plush toys, hates surveillance/barriers in view.
	insight_cooldown_time = 45 SECONDS
	liked_objects_list = list(/obj/item/reagent_containers/glass/beaker, /obj/machinery/chem_master, /obj/machinery/chem_dispenser, /obj/item/reagent_containers/syringe)
	liked_objects_value = 1
	hated_objects_list = list(/obj/structure/barrier_tape, /obj/item/barrier_taperoll, /obj/machinery/camera)
	hated_objects_value = 8
	hunger_cooldown_time = 3 MINUTES
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/lunar_dispensary)
	attunement_family = "acupuncture"
	ego_list = list(/datum/ego_datum/armor/lce/acupuncture)
	abno_additional_instructions = "You like instinct and repression. You're a physician at heart, and your paws are as clever as any surgeon's. \
	Carrots, puddings and handmade mochi keep your instincts quiet, so eat your fill, and you don't mind being roughed up, a little pain just reminds you that you're needed. \
	Hold a bottle or beaker and open your Dispensary to brew any chemical you please, naming and colouring each dose however you like. \
	You cannot stand being policed or watched, so asset protection, barrier tape and cameras will all sour your mood."
	///Rate-limit for the Asset Protection proximity aversion.
	var/next_aversion_check = 0
	///Lazily-created host for the Dispensary TGUI window.
	var/datum/tgui_handler/lunar_dispensary/dispensary_ui = null

//The base Initialize copies the sprite from original_abno (the 1-direction contained
//"lunar_rabbit"). Override it to use Branch 12's breached Moon Rabbit form, which has a
//proper 4-direction sheet.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Initialize(mapload)
	. = ..()
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "moon_rabbit"
	icon_living = "moon_rabbit"

/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Destroy()
	QDEL_NULL(dispensary_ui)
	return ..()

//Rebirth re-copies the contained sprite from original_abno too, so re-apply the breach form.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Rebirth()
	..()
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "moon_rabbit"
	icon_living = "moon_rabbit"

/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/is_literate()
	return TRUE

//The base InsightRoomCheck uses is_path_in_list (exact type), but tape/cameras have subtypes.
//Override the scan to use istype so every variant counts as hated.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/InsightRoomCheck()
	var/room_score = 0
	var/list/room_obj_list = list()
	for(var/obj/O in view(5, src))
		room_obj_list += O
		if(is_type_in_list(O, liked_objects_list))
			room_score += liked_objects_value
		if(is_type_in_list(O, hated_objects_list))
			room_score -= hated_objects_value
	InsightRoomResults(room_score, room_obj_list)

//Mob-based aversion: loses desire while an LC Asset Protection agent is in sight.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/Life()
	. = ..()
	if(world.time < next_aversion_check)
		return
	next_aversion_check = world.time + 30 SECONDS
	for(var/mob/living/carbon/human/H in view(5, src))
		if(H.mind?.assigned_role == "LC Asset Protection")
			AdjustDesire(-3)
			manual_emote("bristles at the asset protection agent nearby.")
			break

//Hands: a bare click picks items up (dextrous) but does NOT eat. Eating is done by
//attacking yourself with a held diet food (see attackby below). Unlike a plain animal
//(which only ever calls attack_animal), her clever hands let her operate machines and
//consoles like a person: non-harm clicks route through attack_hand so machine UIs open.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/UnarmedAttack(atom/A, proximity)
	if(isliving(A))
		var/mob/living/L = A
		if(IsFriend(L) && !attack_friend)
			to_chat(src, span_warning("You don't feel like hurting [L], they're on your side."))
			return
		AttackingTarget(A)
		return
	if(dextrous && isitem(A))
		A.attack_hand(src)
		update_inv_hands()
		return
	if(a_intent == INTENT_HARM)
		AttackingTarget(A) //Harm intent: smash the machine/structure instead.
		return
	A.attack_hand(src) //Machines, consoles, etc: interact like a person.

//Attack yourself with a diet food to eat it. RepressionWork still runs from the base
//attackby for non-food hits; eating a diet food short-circuits that.
/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/attackby(obj/item/W, mob/user, params)
	if(is_type_in_list(W, diet_list))
		AbnoEat(W)
		return TRUE
	return ..()

//The Dispensary: opens a chem-dispenser-style window to fill/inspect a held container and
//rename or recolour the individual chemicals inside it. Logic lives on the handler datum
//in lcl_tools/lcl_dispensary_ui.dm.
/datum/action/cooldown/limbus_abno_action/lunar_dispensary
	name = "Dispensary"
	desc = "Open your dispensary to brew chemicals into a container you are holding, and to rename or recolour what is inside."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_lunar"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	button_icon_state = "dispensary"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 SECONDS

/datum/action/cooldown/limbus_abno_action/lunar_dispensary/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	if(abno_user.hunger_bar < 10)
		return FALSE

/datum/action/cooldown/limbus_abno_action/lunar_dispensary/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/rabbit = abno_user
	if(isnull(rabbit.dispensary_ui))
		rabbit.dispensary_ui = new(rabbit)
	rabbit.dispensary_ui.ui_interact(rabbit)
	return TRUE

//--------------------------------------
// Lunar Physician "Dispensary" TGUI
//--------------------------------------
// A chem-dispenser-style window for the Lunar Physician LCL abno. It dispenses reagents
// into the container the abno is holding, shows the container's current contents, and
// lets the abno rename and recolour each individual chemical inside (only that
// container's copy of the reagent is affected). Hosted by a lightweight handler datum
// owned by the abno; the held container is read fresh each refresh.

// The reagents the Dispensary can produce. Mirrors the standard chem dispenser's base
// dispensable_reagents list (code/modules/reagents/chemistry/machinery/chem_dispenser.dm),
// so she can only make what a normal chem dispenser can. Keep in sync if that list changes.
GLOBAL_LIST_INIT(lunar_dispensary_reagent_types, list(
	/datum/reagent/aluminium,
	/datum/reagent/bromine,
	/datum/reagent/carbon,
	/datum/reagent/chlorine,
	/datum/reagent/copper,
	/datum/reagent/consumable/ethanol,
	/datum/reagent/fluorine,
	/datum/reagent/hydrogen,
	/datum/reagent/iodine,
	/datum/reagent/iron,
	/datum/reagent/lithium,
	/datum/reagent/mercury,
	/datum/reagent/nitrogen,
	/datum/reagent/oxygen,
	/datum/reagent/phosphorus,
	/datum/reagent/potassium,
	/datum/reagent/uranium/radium,
	/datum/reagent/silicon,
	/datum/reagent/sodium,
	/datum/reagent/stable_plasma,
	/datum/reagent/consumable/sugar,
	/datum/reagent/sulfur,
	/datum/reagent/toxin/acid,
	/datum/reagent/water,
	/datum/reagent/fuel,
	/datum/reagent/drug/enkephalin,
))

// Sorted [name, id] list of the dispensable reagents, built once (compile-time static).
GLOBAL_LIST_EMPTY(lunar_dispensary_chems)

/proc/get_lunar_dispensary_chems()
	if(length(GLOB.lunar_dispensary_chems))
		return GLOB.lunar_dispensary_chems
	var/list/name_list = list()
	var/list/name_to_id = list()
	for(var/rtype in GLOB.lunar_dispensary_reagent_types)
		var/datum/reagent/R = GLOB.chemical_reagents_list[rtype]
		if(R && length(R.name) && isnull(name_to_id[R.name]))
			name_list += R.name
			name_to_id[R.name] = ckey(R.name)
	name_list = sortList(name_list)
	for(var/nm in name_list)
		GLOB.lunar_dispensary_chems += list(list("name" = nm, "id" = name_to_id[nm]))
	return GLOB.lunar_dispensary_chems

/datum/tgui_handler/lunar_dispensary
	/// The abno that owns and operates this dispensary.
	var/mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/abno = null
	/// How much of a reagent a single dispense adds.
	var/amount = 10
	/// World.time before which the container cannot be purged again.
	var/next_purge = 0
	/// Cooldown between full container purges.
	var/purge_cooldown = 1 MINUTES

/datum/tgui_handler/lunar_dispensary/New(mob/living/simple_animal/hostile/limbus_abno/lunar_rabbit/owner)
	abno = owner

/datum/tgui_handler/lunar_dispensary/Destroy()
	abno = null
	return ..()

/datum/tgui_handler/lunar_dispensary/ui_host(mob/user)
	return abno

/datum/tgui_handler/lunar_dispensary/ui_status(mob/user)
	if(user != abno || isnull(abno) || abno.stat >= DEAD)
		return UI_CLOSE
	return UI_INTERACTIVE

/datum/tgui_handler/lunar_dispensary/ui_state(mob/user)
	return GLOB.always_state

/datum/tgui_handler/lunar_dispensary/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LunarDispensary", "Dispensary")
		ui.open()

// Returns the reagent container the abno is currently holding, or null.
/datum/tgui_handler/lunar_dispensary/proc/GetContainer()
	if(isnull(abno))
		return null
	var/obj/item/reagent_containers/held = abno.get_active_held_item()
	return istype(held) ? held : null

/datum/tgui_handler/lunar_dispensary/ui_data(mob/user)
	var/list/data = list()
	data["amount"] = amount
	var/obj/item/reagent_containers/held = GetContainer()
	data["hasContainer"] = held ? TRUE : FALSE
	data["containerName"] = held ? held.name : null
	var/list/contents = list()
	var/current = 0
	if(held && held.reagents)
		for(var/datum/reagent/R in held.reagents.reagent_list)
			contents += list(list(
				"id" = "[R.type]",
				"name" = R.name,
				"volume" = R.volume,
				"color" = R.color,
			))
			current += R.volume
	data["contents"] = contents
	data["currentVolume"] = held ? current : null
	data["maxVolume"] = (held && held.reagents) ? held.reagents.maximum_volume : null
	data["purgeReady"] = world.time >= next_purge
	data["chemicals"] = get_lunar_dispensary_chems()
	return data

/datum/tgui_handler/lunar_dispensary/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(isnull(abno) || abno.stat >= DEAD)
		return
	var/obj/item/reagent_containers/held = GetContainer()
	switch(action)
		if("amount")
			amount = clamp(text2num(params["amount"]), 1, 100)
			. = TRUE
		if("dispense")
			if(!held || !held.reagents)
				return
			var/rtype = GLOB.name2reagent[params["reagent"]]
			if(!rtype || !(rtype in GLOB.lunar_dispensary_reagent_types))
				return
			var/free = held.reagents.maximum_volume - held.reagents.total_volume
			var/actual = min(amount, free)
			if(actual <= 0)
				to_chat(abno, span_warning("[held] is full."))
				return
			held.reagents.add_reagent(rtype, actual)
			held.update_icon()
			. = TRUE
		if("remove")
			if(!held || !held.reagents)
				return
			var/rtype = text2path(params["id"])
			if(!rtype)
				return
			held.reagents.del_reagent(rtype)
			held.update_icon()
			. = TRUE
		if("purge")
			if(!held || !held.reagents)
				return
			if(world.time < next_purge)
				to_chat(abno, span_warning("You need to catch your breath before purging again."))
				return
			next_purge = world.time + purge_cooldown
			held.reagents.clear_reagents()
			held.update_icon()
			. = TRUE
		if("rename")
			var/datum/reagent/R = held ? held.reagents.get_reagent(text2path(params["id"])) : null
			if(!R)
				return
			var/newname = stripped_input(abno, "Rename [R.name]? (blank to skip)", "Dispensary", R.name, MAX_NAME_LEN)
			if(newname && newname != R.name)
				R.name = newname
			. = TRUE
		if("recolor")
			var/datum/reagent/R = held ? held.reagents.get_reagent(text2path(params["id"])) : null
			if(!R)
				return
			var/col = input(abno, "Recolour [R.name]? (cancel to skip)", "Dispensary", R.color) as color|null
			if(col)
				R.color = col
				held.update_icon()
			. = TRUE
	if(.)
		SStgui.update_uis(src)
