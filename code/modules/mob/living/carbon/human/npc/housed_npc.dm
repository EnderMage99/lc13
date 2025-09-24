// Housed NPC variant - NPCs that live in houses with UI interaction and trading system

/mob/living/simple_animal/hostile/ui_npc/housed
	name = "homeowner"
	desc = "A local resident who lives in this house."
	icon = 'ModularLobotomy/_Lobotomyicons/civilians.dmi'
	icon_state = "civilian1"
	icon_living = "civilian1"
	icon_dead = "civilian1"
	maxHealth = 100
	health = 100
	typing_interval = 50
	typing_volume = 25
	portrait = "the-goat.PNG" // Placeholder portrait
	start_scene_id = "greeting"
	random_emotes = "adjusts their collar;looks out the window;tidies up the room;checks their watch"
	bubble = "default2"
	loot = list()

	// Home defense variables
	var/obj/effect/landmark/house_door_landmark/door_landmark
	var/turf/home_turf
	var/list/warned_intruders = list()
	var/warning_cooldown = 0
	var/doorbell_response_active = FALSE

	// Trading system variables
	var/list/trade_items = list()
	var/list/item_prices = list(
		/obj/item/lighter = 10,
		/obj/item/storage/wallet = 20,
		/obj/item/flashlight = 15,
		/obj/item/stack/spacecash = 1  // Per credit
	)

	// Appearance variables
	var/hair_style = "Bedhead"
	var/hair_color = "4B3"
	var/npc_gender = MALE

/mob/living/simple_animal/hostile/ui_npc/housed/Initialize()
	. = ..()

	// Store home turf
	home_turf = get_turf(src)

	// Find the closest door landmark
	var/min_distance = INFINITY
	for(var/obj/effect/landmark/house_door_landmark/L in GLOB.house_door_landmarks)
		if(L.z != z)
			continue
		var/dist = get_dist(src, L)
		if(dist < min_distance)
			min_distance = dist
			door_landmark = L

	// Initialize trade items
	setup_trade_items()

	// Setup appearance with hair
	setup_appearance()

	// Load dialogue scenes
	scene_manager.load_scenes(get_housed_npc_scenes())

	// Set up NPC-specific variables
	scene_manager.npc_vars.variables["has_reported_intruder"] = FALSE
	scene_manager.npc_vars.variables["times_visited"] = 0

/mob/living/simple_animal/hostile/ui_npc/housed/proc/setup_trade_items()
	// Add cash
	var/cash_amount = rand(400, 600)
	trade_items["cash"] = list(
		"name" = "Spare Cash",
		"desc" = "[cash_amount] credits in bills",
		"price" = round(cash_amount * 0.75), // 25% discount
		"amount" = cash_amount,
		"type" = /obj/item/stack/spacecash
	)

	// Random household items
	if(prob(50))
		trade_items["lighter"] = list(
			"name" = "Zippo Lighter",
			"desc" = "A metal lighter, slightly used",
			"price" = round(item_prices[/obj/item/lighter] * 0.75),
			"type" = /obj/item/lighter
		)

	if(prob(30))
		trade_items["wallet"] = list(
			"name" = "Leather Wallet",
			"desc" = "A worn leather wallet",
			"price" = round(item_prices[/obj/item/storage/wallet] * 0.75),
			"type" = /obj/item/storage/wallet
		)

	if(prob(100)) // For testing
		trade_items["flashlight"] = list(
			"name" = "Flashlight",
			"desc" = "A battery-powered flashlight",
			"price" = round(item_prices[/obj/item/flashlight] * 0.75),
			"type" = /obj/item/flashlight
		)

/mob/living/simple_animal/hostile/ui_npc/housed/proc/setup_appearance()
	// Randomize gender
	npc_gender = pick(MALE, FEMALE)

	// Pick a random hairstyle based on gender
	if(npc_gender == FEMALE)
		hair_style = pick(GLOB.hairstyles_female_list)
	else
		hair_style = pick(GLOB.hairstyles_male_list)

	// Random hair color
	hair_color = pick("4B3", "7D6", "8B7", "B55", "A3B", "000", "FFF", "F70", "0F0")

	// Apply hair overlay
	update_hair_overlay()

/mob/living/simple_animal/hostile/ui_npc/housed/proc/update_hair_overlay()
	// Clear existing hair overlays
	cut_overlays()

	// Get the hair sprite
	var/datum/sprite_accessory/hair/S = GLOB.hairstyles_list[hair_style]
	if(!S)
		return

	// Create the hair overlay
	var/mutable_appearance/hair_overlay = mutable_appearance('icons/mob/human_face.dmi', S.icon_state, -HAIR_LAYER)
	hair_overlay.color = "#[hair_color]"

	// Add the overlay
	add_overlay(hair_overlay)

/mob/living/simple_animal/hostile/ui_npc/housed/update_player_variables(mob/user)
	. = ..()
	if(!user?.client)
		return

	// Check player's money - both cash and bank account
	var/player_money = 0
	if(ishuman(user))
		var/mob/living/carbon/human/H = user

		// Check for physical cash in hands and backpack
		var/obj/item/stack/spacecash/cash = locate() in H.contents
		if(cash)
			player_money += cash.amount

		// Check bank account balance
		var/obj/item/card/id/C = H.get_idcard(TRUE)
		if(C?.registered_account)
			player_money += C.registered_account.account_balance

	scene_manager.set_var(user, "player.money", player_money)
	scene_manager.set_var(user, "player.name", user.real_name)

	// Check if this player was warned before
	var/was_warned = (user in warned_intruders)
	scene_manager.set_var(user, "player.was_warned", was_warned)

// Trading functionality
/mob/living/simple_animal/hostile/ui_npc/housed/proc/perform_trade(item_key)
	var/mob/user = usr  // Get the user from usr like nuke_leader does

	if(!item_key || !(item_key in trade_items))
		return FALSE

	var/list/item_data = trade_items[item_key]
	var/price = item_data["price"]

	// Check player money
	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/H = user

	// Calculate total available money
	var/obj/item/stack/spacecash/cash = locate() in H.contents
	var/cash_amount = cash ? cash.amount : 0
	var/obj/item/card/id/C = H.get_idcard(TRUE)
	var/bank_amount = (C?.registered_account) ? C.registered_account.account_balance : 0
	var/total_money = cash_amount + bank_amount

	if(total_money < price)
		say("You don't have enough money for that.")
		return FALSE

	// Deduct money - prioritize cash first, then bank account
	var/remaining_cost = price

	// First try to use cash
	if(cash && cash_amount > 0)
		var/cash_to_use = min(cash_amount, remaining_cost)
		cash.amount -= cash_to_use
		remaining_cost -= cash_to_use

		if(cash.amount <= 0)
			qdel(cash)
		else
			cash.update_icon()

	// Then use bank account for any remaining cost
	if(remaining_cost > 0 && C?.registered_account)
		if(!C.registered_account.adjust_money(-remaining_cost))
			// This shouldn't happen since we checked total money, but handle it
			say("There was a problem with your bank account.")
			return FALSE

	// Give item
	var/item_type = item_data["type"]
	if(item_key == "cash")
		var/obj/item/stack/spacecash/new_cash = new(get_turf(user))
		new_cash.amount = item_data["amount"]
		new_cash.update_icon()
	else
		new item_type(get_turf(user))

	// Remove from trade list
	trade_items -= item_key

	say("Thank you for your purchase!")
	playsound(get_turf(src), 'sound/effects/cashregister.ogg', 35, 3, 3)

	// Update player money for UI (recalculate total)
	var/new_total = 0
	cash = locate() in H.contents  // Re-find cash in case it changed
	if(cash)
		new_total += cash.amount
	if(C?.registered_account)
		new_total += C.registered_account.account_balance
	scene_manager.set_var(user, "player.money", new_total)

	return TRUE

// Home defense behavior
/mob/living/simple_animal/hostile/ui_npc/housed/Life()
	. = ..()
	if(!. || stat != CONSCIOUS)
		return

	// Check for intruders in our home
	if(world.time > warning_cooldown)
		var/area/A = get_area(src)
		if(istype(A, /area/city/house))
			for(var/mob/living/carbon/human/H in A)
				if(H == src || !H.ckey) // Ignore self and other NPCs
					continue

				if(!(H in warned_intruders))
					warn_intruder(H)

/mob/living/simple_animal/hostile/ui_npc/housed/proc/warn_intruder(mob/living/carbon/human/intruder)
	warned_intruders += intruder
	warning_cooldown = world.time + 10 SECONDS

	say("Hey! What are you doing in my house? Get out!")

	// Start 5 second timer
	addtimer(CALLBACK(src, PROC_REF(report_intruder), intruder), 5 SECONDS)

/mob/living/simple_animal/hostile/ui_npc/housed/proc/report_intruder(mob/living/carbon/human/intruder)
	// Check if they're still in our house
	if(!intruder || intruder.z != z)
		warned_intruders -= intruder
		return

	var/area/A = get_area(src)
	var/area/intruder_area = get_area(intruder)

	if(A != intruder_area || !istype(A, /area/city/house))
		warned_intruders -= intruder
		return

	// Report the intrusion
	var/message = "[intruder.real_name] is invading my home at [A.name]! Send help!"
	say(message)
	to_chat(intruder, span_warning("The homeowner has reported you to the authorities!"))

	scene_manager.npc_vars.variables["has_reported_intruder"] = TRUE

	// Clear them from warned list after some time
	addtimer(CALLBACK(src, PROC_REF(clear_warned), intruder), 30 SECONDS)

/mob/living/simple_animal/hostile/ui_npc/housed/proc/clear_warned(mob/living/carbon/human/intruder)
	warned_intruders -= intruder

// Doorbell response
/mob/living/simple_animal/hostile/ui_npc/housed/proc/respond_to_doorbell()
	if(doorbell_response_active || !door_landmark || stat != CONSCIOUS)
		return

	doorbell_response_active = TRUE

	say("Coming!")

	// Walk to door
	walk_to(src, door_landmark, 0, 2)

	// Check when we arrive
	addtimer(CALLBACK(src, PROC_REF(check_door_arrival)), 1 SECONDS)

/mob/living/simple_animal/hostile/ui_npc/housed/proc/check_door_arrival()
	if(get_dist(src, door_landmark) <= 1)
		// We're at the door
		walk(src, 0)
		dir = door_landmark.dir

		// Open the door
		var/turf/door_turf = get_turf(door_landmark)
		for(var/obj/machinery/door/locked_door in door_turf.contents)
			locked_door.open()

		say(pick("Yes? Who is it?", "Can I help you?", "What do you want?"))

		// Wait a bit then return home
		addtimer(CALLBACK(src, PROC_REF(return_home)), rand(3 SECONDS, 5 SECONDS))
	else
		// Keep checking
		addtimer(CALLBACK(src, PROC_REF(check_door_arrival)), 1 SECONDS)

/mob/living/simple_animal/hostile/ui_npc/housed/proc/return_home()
	doorbell_response_active = FALSE

	if(!home_turf)
		return

	say(pick("Nobody there...", "Must have left.", "Hmm..."))

	// Walk back to original position
	walk_to(src, home_turf, 0, 2)

	// Stop walking when we get home
	addtimer(CALLBACK(src, PROC_REF(stop_walking)), 3 SECONDS)

/mob/living/simple_animal/hostile/ui_npc/housed/proc/stop_walking()
	walk(src, 0)

// Death handling - spawn backpack with items and lay down the NPC
/mob/living/simple_animal/hostile/ui_npc/housed/death(gibbed)
	// Spawn a backpack with all unsold items
	if(length(trade_items))
		var/obj/item/storage/backpack/B = new /obj/item/storage/backpack(get_turf(src))
		B.name = "[name]'s belongings"
		B.desc = "A backpack containing the belongings of [name]."

		// Add all remaining trade items to the backpack
		for(var/item_key in trade_items)
			var/list/item_data = trade_items[item_key]
			var/item_type = item_data["type"]

			if(item_key == "cash")
				var/obj/item/stack/spacecash/cash = new(B)
				cash.amount = item_data["amount"]
				cash.update_icon()
			else
				new item_type(B)

		// Make the backpack visible
		B.visible_message(span_notice("[B] falls to the ground."))

	// Rotate the sprite and adjust position to simulate lying down
	transform = turn(transform, 90)  // Rotate 90 degrees
	pixel_y = pixel_y - 20  // Lower the sprite

	return ..()

// Dialogue scenes
/mob/living/simple_animal/hostile/ui_npc/housed/proc/get_housed_npc_scenes()
	var/list/scenes = list()

	scenes["greeting"] = list(
		"text" = "\[player.was_warned?You! I told you to get out of my house!:Welcome to my home. \[dialog.is_first_visit?I don't usually have visitors.:Back again?\]\]",
		"on_enter" = list(
			"npc.times_visited" = "{npc.times_visited + 1}"
		),
		"actions" = list(
			"apologize" = list(
				"text" = "I'm sorry for barging in earlier.",
				"visibility_expression" = "player.was_warned",
				"default_scene" = "apology_accepted"
			),
			"chat" = list(
				"text" = "Can we talk for a bit?",
				"visibility_expression" = "NOT player.was_warned",
				"default_scene" = "chat_menu"
			),
			"trade" = list(
				"text" = "Do you have anything for sale?",
				"visibility_expression" = "NOT player.was_warned",
				"default_scene" = "trade_menu"
			),
			"leave" = list(
				"text" = "I should go.",
				"default_scene" = "goodbye"
			)
		)
	)

	scenes["apology_accepted"] = list(
		"text" = "Well... I suppose you did ring the doorbell this time. Just don't break in again, alright?",
		"on_enter" = list(
			"player.was_warned" = FALSE
		),
		"actions" = list(
			"continue" = list(
				"text" = "Thank you for understanding.",
				"default_scene" = "greeting"
			)
		)
	)

	scenes["chat_menu"] = list(
		"text" = "What would you like to know about?",
		"actions" = list(
			"neighborhood" = list(
				"text" = "Tell me about the neighborhood.",
				"default_scene" = "about_neighborhood"
			),
			"yourself" = list(
				"text" = "Tell me about yourself.",
				"default_scene" = "about_self"
			),
			"back" = list(
				"text" = "Actually, nevermind.",
				"default_scene" = "greeting"
			)
		)
	)

	scenes["about_neighborhood"] = list(
		"text" = "It used to be a nice, quiet place. These days though... well, let's just say I keep my doors locked. Too many strange folks wandering around.",
		"on_enter" = list(
			"dialog.discussed.neighborhood" = TRUE
		),
		"actions" = list(
			"continue" = list(
				"text" = "I see...",
				"default_scene" = "chat_menu"
			)
		)
	)

	scenes["about_self"] = list(
		"text" = "I've lived here for years. Got a decent collection of stuff, though I might part with some of it for the right price. Times are tough, you know?",
		"on_enter" = list(
			"dialog.discussed.self" = TRUE
		),
		"actions" = list(
			"continue" = list(
				"text" = "Interesting.",
				"default_scene" = "chat_menu"
			)
		)
	)

	// Trade menu - dynamically generated based on available items
	var/list/trade_actions = list()

	// Add trade actions dynamically
	for(var/item_key in trade_items)
		var/list/item_data = trade_items[item_key]
		var/action_key = "buy_[item_key]"
		trade_actions[action_key] = list(
			"text" = "Buy [item_data["name"]] ([item_data["price"]] credits) - [item_data["desc"]]",
			"enabled_expression" = "player.money >= [item_data["price"]]",
			"proc_callbacks" = list(CALLBACK(src, PROC_REF(perform_trade), item_key)),
			"default_scene" = "purchase_complete"
		)

	// Add back button
	trade_actions["back"] = list(
		"text" = "On second thought, I'll keep my money.",
		"default_scene" = "greeting"
	)

	scenes["trade_menu"] = list(
		"text" = "Here's what I'm willing to part with. You have {player.money} credits.",
		"actions" = trade_actions
	)

	scenes["purchase_complete"] = list(
		"text" = "Pleasure doing business with you. Anything else?",
		"actions" = list(
			"more" = list(
				"text" = "Let me see what else you have.",
				"default_scene" = "trade_menu"
			),
			"done" = list(
				"text" = "That's all, thanks.",
				"default_scene" = "greeting"
			)
		)
	)

	scenes["goodbye"] = list(
		"text" = "\[npc.has_reported_intruder?Don't let me catch you breaking in again!:Take care now.\]",
		"actions" = list()  // Ends conversation
	)

	return scenes

// House door landmark remains the same
/obj/effect/landmark/house_door_landmark
	name = "house door landmark"
	icon_state = "x4"
	var/obj/structure/doorbell/connected_doorbell

GLOBAL_LIST_EMPTY(house_door_landmarks)

/obj/effect/landmark/house_door_landmark/Initialize()
	. = ..()
	GLOB.house_door_landmarks += src

	// Create doorbell next to this landmark
	var/turf/bell_turf = get_step(src, turn(dir, 90))
	if(bell_turf)
		connected_doorbell = new /obj/structure/doorbell(bell_turf)
		connected_doorbell.connected_landmark = src

/obj/effect/landmark/house_door_landmark/Destroy()
	GLOB.house_door_landmarks -= src
	if(connected_doorbell)
		qdel(connected_doorbell)
	return ..()

// Doorbell structure
/obj/structure/doorbell
	name = "doorbell"
	desc = "A simple doorbell. Ring it to get the homeowner's attention."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "doorctrl"
	anchored = TRUE
	density = FALSE
	var/obj/effect/landmark/house_door_landmark/connected_landmark
	var/ring_cooldown = 0

/obj/structure/doorbell/attack_hand(mob/user)
	. = ..()
	if(world.time < ring_cooldown)
		to_chat(user, span_warning("You just rang it! Give them a moment."))
		return

	ring_cooldown = world.time + 5 SECONDS

	// Visual feedback
	flick("doorctrl1", src)
	playsound(src, 'sound/machines/ding.ogg', 50, TRUE)

	user.visible_message(span_notice("[user] rings the doorbell."), \
		span_notice("You ring the doorbell."))

	// Find the NPC in this house
	if(connected_landmark)
		var/area/A = get_area(connected_landmark)
		for(var/mob/living/simple_animal/hostile/ui_npc/housed/NPC in A)
			if(NPC.stat == CONSCIOUS)
				NPC.respond_to_doorbell()
				break

// House NPC spawn landmark
/obj/effect/landmark/housed_npc_spawn
	name = "housed npc spawn"
	icon_state = "x5"

/obj/effect/landmark/housed_npc_spawn/Initialize()
	. = ..()
	// Spawn a housed NPC here
	INVOKE_ASYNC(src, PROC_REF(spawn_npc))

/obj/effect/landmark/housed_npc_spawn/proc/spawn_npc()
	new /mob/living/simple_animal/hostile/ui_npc/housed(loc)

// House area definition
/area/city/house
	name = "Residential House"
	icon_state = "house"
