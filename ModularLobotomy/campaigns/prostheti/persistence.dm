// =============================================
// Prostheti Innovations — SSpersistence Integration
// =============================================
// Follows the ClearedCores pattern from code/controllers/subsystem/persistence.dm
// Stores per-ckey chapter progress in data/ProsthetiProgress.json
//
// JSON format:
// {
//   "player_ckey_1": { "highest_chapter": 3 },
//   "player_ckey_2": { "highest_chapter": 1 }
// }

/// Loads Prostheti Innovations campaign progress from JSON.
/datum/controller/subsystem/persistence/proc/LoadProsthetiProgress()
	var/json = file2text(FILE_PROSTHETI_PROGRESS)
	if(!json)
		if(!fexists(file(FILE_PROSTHETI_PROGRESS)))
			return // File doesn't exist yet — first run
		return
	var/list/data = json_decode(json)
	if(islist(data))
		prostheti_progress = data

/// Updates a player's highest completed chapter. Only writes if the new chapter
/// is higher than the existing record. Writes immediately to disk.
/datum/controller/subsystem/persistence/proc/UpdateProsthetiProgress(player_ckey, chapter_number)
	if(!player_ckey || !chapter_number)
		return

	var/list/player_data = prostheti_progress[player_ckey]
	if(!islist(player_data))
		prostheti_progress[player_ckey] = list("highest_chapter" = chapter_number)
	else
		var/existing = player_data["highest_chapter"]
		if(!existing || chapter_number > existing)
			player_data["highest_chapter"] = chapter_number

	// Immediate write (same pattern as UpdateClearedCores)
	fdel(FILE_PROSTHETI_PROGRESS)
	text2file(json_encode(prostheti_progress), FILE_PROSTHETI_PROGRESS)

/// Saves Prostheti Innovations progress to disk during round-end collection.
/datum/controller/subsystem/persistence/proc/CollectProsthetiProgress()
	if(!length(prostheti_progress))
		return
	fdel(FILE_PROSTHETI_PROGRESS)
	text2file(json_encode(prostheti_progress), FILE_PROSTHETI_PROGRESS)

/// Returns the highest chapter a player has completed, or 0 if no progress.
/datum/controller/subsystem/persistence/proc/GetProsthetiProgress(player_ckey)
	if(!player_ckey)
		return 0
	var/list/player_data = prostheti_progress[player_ckey]
	if(!islist(player_data))
		return 0
	return player_data["highest_chapter"] || 0
