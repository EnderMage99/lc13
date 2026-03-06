// =============================================
// Prostheti Innovations — Bus Ticket
// =============================================
// Insert into the ticker reader (/obj/structure/maploader) to load the
// Prostheti Innovations factory map as a z-level accessible via bus.
// See: ModularLobotomy/associations/machines.dm for the maploader pattern.

/obj/item/quest_ticket/prostheti_innovations
	name = "'Prostheti Innovations' ticket"
	desc = "A small sheet of paper with a barcode. The header reads 'Prostheti Innovations — Design Floor Access.' Could be given to a ticket reader to access a new area."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "ticket"
	inhand_icon_state = "ticket"
	worn_icon_state = "ticket"
	map = "_maps/Quests/prostheti_innovations.dmm"
	map_name = "prostheti_innovations_floor"
	ticket_name = "Prostheti Innovations"
