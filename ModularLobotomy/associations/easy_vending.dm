/**
 * Simple vending machine system for easy subtyping
 *
 * ADMIN USAGE:
 * To customize a vending machine in-game:
 * 1. Right-click the machine and select "View Variables"
 * 2. Edit the "products" variable to add/remove items or change prices/stock
 *    Format: /obj/item/path = list("stock" = amount, "current" = current_amount, "price" = cost, "desc" = "description")
 * 3. Call the "UpdateProducts()" proc to apply your changes:
 *    - UpdateProducts() = Full refresh, resets all stock to initial values
 *    - UpdateProducts(TRUE) = Keeps current stock levels (useful for price/desc changes only)
 * 4. The machine will refresh and update for all viewers
 *
 * CODER USAGE:
 * Create subtypes by defining the products list:
 * /obj/machinery/simple_vending/my_vendor
 *     name = "My Vendor"
 *     products = list(
 *         /obj/item/flashlight = list("stock" = 10, "price" = 50, "desc" = "A flashlight"),
 *         /obj/item/pen = list("stock" = -1, "price" = 10, "desc" = "Unlimited pens!")
 *     )
 */
/obj/machinery/simple_vending
	name = "\improper simple vending machine"
	desc = "A simplified vending machine for easy configuration."
	icon = 'icons/obj/vending.dmi'
	icon_state = "generic"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	anchored = TRUE

	/// List of products in format: /obj/item/path = list("stock" = amount, "current" = current_stock, "price" = cost, "desc" = description)
	/// Stock of -1 means unlimited
	/// "current" tracks current stock level (set automatically on init)
	/// ADMIN NOTE: After editing this var via VV, call UpdateProducts() or UpdateProducts(TRUE) to apply changes
	var/list/products = list()

	/// Whether to show the search bar in the UI
	var/enable_search = TRUE

	/// Sound to play when vending
	var/vend_sound = 'sound/machines/machine_vend.ogg'

	/// Icon state for vending animation
	var/icon_vend = null

	/// Icon state for vending denial
	var/icon_deny = null

	/// Whether this machine is on station (affects payment)
	var/onstation = TRUE

	/// Stored ahn from cash/holochip insertions (can be used for purchases)
	var/stored_ahn = 0

/obj/machinery/simple_vending/Initialize()
	payment_department = NO_FREEBIES
	. = ..()
	InitializeStock()

/// Initializes the current stock levels for all products
/obj/machinery/simple_vending/proc/InitializeStock()
	for(var/product_path in products)
		var/list/product_data = products[product_path]
		if(!islist(product_data))
			continue
		// Set current stock to initial stock if not already set
		if(!("current" in product_data))
			product_data["current"] = product_data["stock"]

/// Updates the vending machine's inventory based on the current products list
/// Call this proc after modifying the products var (useful for admin customization via VV)
/// This will refresh the UI for all viewers
/// keep_stock: If TRUE, preserves current stock levels for existing products (useful for price/description changes)
/obj/machinery/simple_vending/proc/UpdateProducts(keep_stock = FALSE)
	// If not keeping stock, reset current to initial stock values
	if(!keep_stock)
		for(var/product_path in products)
			var/list/product_data = products[product_path]
			if(islist(product_data))
				product_data["current"] = product_data["stock"]
	else
		// If keeping stock, ensure all new products have current values
		InitializeStock()

	// Refresh UI for all viewers
	update_static_data_for_all_viewers()

	visible_message("<span class='notice'>[src] beeps as it updates its inventory.</span>")
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)

/// Handle cash and holochip insertions
/obj/machinery/simple_vending/attackby(obj/item/I, mob/user, params)
	// Check if it's cash or holochip
	if(istype(I, /obj/item/stack/spacecash) || istype(I, /obj/item/holochip))
		var/value = I.get_item_credit_value()
		if(value <= 0)
			to_chat(user, "<span class='warning'>[I] has no value!</span>")
			return

		stored_ahn += value
		to_chat(user, "<span class='notice'>You insert [value] ahn into [src]. The machine now has [stored_ahn] ahn stored.</span>")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)

		// Delete the money item
		qdel(I)

		// Update UI for all viewers
		SStgui.update_uis(src)
		return

	return ..()

/obj/machinery/simple_vending/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SimpleVending")
		ui.open()

/obj/machinery/simple_vending/ui_static_data(mob/user)
	var/list/data = list()

	data["enable_search"] = enable_search
	data["vendor_name"] = name
	data["onstation"] = onstation

	// Build product list directly from products
	var/list/product_list = list()
	for(var/product_path in products)
		var/list/product_data = products[product_path]
		if(!islist(product_data))
			continue

		var/obj/item/temp_item = product_path
		var/stock = product_data["stock"]

		var/list/product_info = list(
			"name" = initial(temp_item.name),
			"desc" = product_data["desc"] || initial(temp_item.desc),
			"price" = product_data["price"] || 0,
			"max_amount" = stock,
			"unlimited" = (stock == -1),
			"path" = "[product_path]",
			"icon_path" = GetIconPath(product_path)
		)
		product_list[++product_list.len] = product_info

	data["products"] = product_list

	return data

/obj/machinery/simple_vending/ui_data(mob/user)
	var/list/data = list()

	// User info
	var/list/user_info = list(
		"name" = user.name,
		"cash" = 0,
		"job" = "Unknown"
	)

	// Get user's cash if on station
	if(onstation && isliving(user))
		var/mob/living/L = user
		var/obj/item/card/id/user_id = L.get_idcard(TRUE)
		if(user_id && user_id.registered_account)
			user_info["cash"] = user_id.registered_account.account_balance
		if(user_id)
			user_info["job"] = user_id.assignment || "Unknown"

	data["user"] = user_info

	// Stock info - send current stock for each product
	var/list/stock_info = list()
	for(var/product_path in products)
		var/list/product_data = products[product_path]
		if(!islist(product_data))
			continue
		var/obj/item/temp_item = product_path
		var/product_name = initial(temp_item.name)
		var/current = product_data["current"]
		var/stock = product_data["stock"]
		stock_info[product_name] = (stock == -1) ? -1 : current

	data["stock"] = stock_info
	data["stored_ahn"] = stored_ahn

	return data

/obj/machinery/simple_vending/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("vend")
			// Find product by path string
			var/product_path = text2path(params["path"])
			if(!(product_path in products))
				return FALSE

			var/list/product_data = products[product_path]
			var/stock = product_data["stock"]
			var/current = product_data["current"]
			var/unlimited = (stock == -1)
			var/price = product_data["price"] || 0
			var/obj/item/temp_item = product_path
			var/product_name = initial(temp_item.name)

			// Check stock
			if(!unlimited && current <= 0)
				to_chat(usr, "<span class='warning'>[src] is out of [product_name]!</span>")
				return FALSE

			// Handle payment if on station and price > 0
			if(onstation && price > 0)
				var/remaining_cost = price

				// First, try to use stored ahn
				if(stored_ahn > 0)
					var/used_from_machine = min(stored_ahn, remaining_cost)
					stored_ahn -= used_from_machine
					remaining_cost -= used_from_machine

					if(used_from_machine > 0)
						to_chat(usr, "<span class='notice'>[src] uses [used_from_machine] ahn from its stored balance.</span>")

				// If stored ahn covered the full price, no need to check ID
				if(remaining_cost > 0)
					// Need to charge from user's account
					var/obj/item/card/id/user_id
					if(isliving(usr))
						var/mob/living/L = usr
						user_id = L.get_idcard(TRUE)
					if(!user_id)
						to_chat(usr, "<span class='warning'>No ID card detected! You need [remaining_cost] more ahn.</span>")
						if(icon_deny)
							flick(icon_deny, src)
						return FALSE

					var/datum/bank_account/user_account = user_id.registered_account
					if(!user_account)
						to_chat(usr, "<span class='warning'>No bank account detected! You need [remaining_cost] more ahn.</span>")
						if(icon_deny)
							flick(icon_deny, src)
						return FALSE

					// Check if user can afford the remaining cost
					if(user_account.account_balance < remaining_cost)
						to_chat(usr, "<span class='warning'>You don't have enough ahn! You need [remaining_cost] more ahn.</span>")
						if(icon_deny)
							flick(icon_deny, src)
						return FALSE

					// Charge the user for remaining cost
					user_account.adjust_money(-remaining_cost)

					// Add to department account if applicable
					if(payment_department != NO_FREEBIES)
						var/datum/bank_account/department_account = SSeconomy.get_dep_account(payment_department)
						if(department_account)
							department_account.adjust_money(remaining_cost)

					// Log the transaction
					log_econ("[remaining_cost] ahn were deducted from [usr]'s account to buy [product_name] from [src].")
					SSblackbox.record_feedback("amount", "vending_spent", remaining_cost)

			// Vend the item
			if(icon_vend)
				flick(icon_vend, src)
			if(vend_sound)
				playsound(src, vend_sound, 50, TRUE, extrarange = -3)

			// Create the item
			var/obj/item/vended_item = new product_path(get_turf(src))

			// Try to put it in user's hands
			if(usr.Adjacent(src))
				usr.put_in_hands(vended_item)

			// Decrease stock if not unlimited
			if(!unlimited)
				product_data["current"]--

			// Update UI
			update_static_data_for_all_viewers()

			return TRUE

/// Generates a CSS-friendly icon path from a typepath
/obj/machinery/simple_vending/proc/GetIconPath(typepath)
	var/icon_path = ""
	var/list/path_parts = splittext("[typepath]", "/")

	// Remove empty first element
	if(path_parts.len && path_parts[1] == "")
		path_parts.Cut(1, 2)

	// Join with dashes
	for(var/i in 1 to path_parts.len)
		if(i > 1)
			icon_path += "-"
		icon_path += path_parts[i]

	return icon_path

/// Example vendor subtype
/obj/machinery/simple_vending/example
	name = "\improper example vendor"
	desc = "An example simple vending machine. Buy some test items!"
	icon_state = "generic"
	enable_search = TRUE
	onstation = TRUE

	products = list(
		/obj/item/flashlight = list("stock" = 10, "price" = 50, "desc" = "A standard flashlight. Illuminates the darkness."),
		/obj/item/storage/box = list("stock" = 5, "price" = 100, "desc" = "A basic storage box for organizing items."),
		/obj/item/pen = list("stock" = -1, "price" = 10, "desc" = "A writing pen. Unlimited stock!"),
		/obj/item/paper = list("stock" = -1, "price" = 5, "desc" = "A blank piece of paper. Perfect for notes.")
	)
