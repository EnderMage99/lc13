// Material items for Resurgence Clan production chain

// Base scrap item
/obj/item/resurgence_material/scrap
	name = "raw scrap"
	desc = "Unsorted scrap materials collected from various sources."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal_2"
	w_class = WEIGHT_CLASS_SMALL
	var/scrap_quality = 1 // 1-5, affects sorting results

/obj/item/resurgence_material/scrap/Initialize()
	. = ..()
	scrap_quality = rand(1, 5)
	switch(scrap_quality)
		if(1)
			name = "poor quality scrap"
			desc = "Heavily damaged and rusted scrap. Won't yield much."
		if(2)
			name = "low quality scrap"
			desc = "Worn scrap materials with some usable parts."
		if(3)
			name = "standard scrap"
			desc = "Average quality scrap that can be processed."
		if(4)
			name = "good quality scrap"
			desc = "Well-preserved scrap with many usable components."
		if(5)
			name = "pristine scrap"
			desc = "Nearly undamaged materials ready for processing."

// Sorted scrap types
/obj/item/resurgence_material/sorted
	w_class = WEIGHT_CLASS_SMALL

/obj/item/resurgence_material/sorted/metal
	name = "sorted metal scrap"
	desc = "Metal pieces sorted and ready for melting."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal_2"

/obj/item/resurgence_material/sorted/electronic
	name = "sorted electronics"
	desc = "Electronic components sorted for recycling."
	icon = 'icons/obj/module.dmi'
	icon_state = "id_mod"

/obj/item/resurgence_material/sorted/plastic
	name = "sorted plastics"
	desc = "Plastic materials ready for reprocessing."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-plastic"

// Processed materials
/obj/item/stack/resurgence_ingot
	name = "processed ingot"
	desc = "A refined metal ingot ready for manufacturing."
	singular_name = "ingot"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-plasteel"
	max_amount = 10
	merge_type = /obj/item/stack/resurgence_ingot
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/stack/resurgence_ingot/examine(mob/user)
	. = ..()
	. += "<span class='notice'>High-quality material for advanced crafting.</span>"

// Components
/obj/item/resurgence_material/component
	name = "basic component"
	desc = "A manufactured component for machine construction."
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "micro_mani"
	w_class = WEIGHT_CLASS_TINY
	var/component_tier = 1

/obj/item/resurgence_material/component/advanced
	name = "advanced component"
	desc = "A precision-manufactured component for complex machinery."
	icon_state = "nano_mani"
	component_tier = 2

/obj/item/resurgence_material/component/superior
	name = "superior component"
	desc = "An expertly crafted component using the finest materials."
	icon_state = "pico_mani"
	component_tier = 3

// Special materials for faith-based crafting
/obj/item/resurgence_material/blessed
	name = "blessed materials"
	desc = "Materials infused with the collective faith of the clan."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-mythril"
	w_class = WEIGHT_CLASS_SMALL
	var/faith_charge = 50

/obj/item/resurgence_material/blessed/examine(mob/user)
	. = ..()
	. += "<span class='notice'>It hums with spiritual energy. Faith charge: [faith_charge]</span>"