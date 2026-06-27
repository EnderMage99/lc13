#define DR_PHASE_INTRO        "intro"
#define DR_PHASE_MENU         "menu"
#define DR_PHASE_FIGHT_TIMING "fight_timing"
#define DR_PHASE_ACT_LIST     "act_list"
#define DR_PHASE_ITEM_LIST    "item_list"
#define DR_PHASE_ENEMY_INTRO  "enemy_intro"
#define DR_PHASE_BULLET_HELL  "bullet_hell"
#define DR_PHASE_END_WIN      "end_win"
#define DR_PHASE_END_LOSE     "end_lose"
#define DR_PHASE_END_SPARE    "end_spare"

/// One Deltarune-style encounter between a human and a deltarune mob.
/datum/deltarune_battle
	var/mob/living/carbon/human/player
	var/mob/living/simple_animal/hostile/deltarune/enemy
	var/turf/player_return_turf
	var/turf/enemy_return_turf
	var/phase = DR_PHASE_INTRO
	var/dialog = ""
	var/enemy_speech = ""
	var/mercy_pct = 0
	var/defending = FALSE
	var/list/last_attack_pattern
	var/player_icon_b64 = ""
	var/datum/tgui/ui_ref

/datum/deltarune_battle/New(mob/living/carbon/human/H, mob/living/simple_animal/hostile/deltarune/E)
	if(!H || !E)
		qdel(src)
		return
	player = H
	enemy = E
	player_return_turf = get_turf(H)
	enemy_return_turf = get_turf(E)
	RegisterSignal(player, COMSIG_PARENT_QDELETING, PROC_REF(OnPlayerGone))
	RegisterSignal(enemy,  COMSIG_PARENT_QDELETING, PROC_REF(OnEnemyGone))
	player.forceMove(null)
	enemy.forceMove(null)
	enemy.LoseTarget()
	enemy.can_act = FALSE
	ADD_TRAIT(player, TRAIT_IMMOBILIZED, "deltarune_battle")
	var/icon/flat = getFlatIcon(player, no_anim = TRUE)
	if(flat)
		player_icon_b64 = icon2base64(flat)
	dialog = "* [capitalize(enemy.name)] drew near!"
	enemy_speech = pick(GetRudinnNeutralLines())
	SStgui.try_update_ui(player, src)
	ui_interact(player)
	addtimer(CALLBACK(src, PROC_REF(EnterMenu)), 1.5 SECONDS)

/datum/deltarune_battle/Destroy()
	UnregisterSignal(player, COMSIG_PARENT_QDELETING)
	UnregisterSignal(enemy,  COMSIG_PARENT_QDELETING)
	if(player && !QDELETED(player))
		REMOVE_TRAIT(player, TRAIT_IMMOBILIZED, "deltarune_battle")
		if(!player.loc && player_return_turf)
			player.forceMove(player_return_turf)
		SStgui.close_uis(src)
	if(enemy && !QDELETED(enemy) && !enemy.loc && enemy_return_turf)
		enemy.forceMove(enemy_return_turf)
		enemy.can_act = TRUE
	return ..()

/datum/deltarune_battle/proc/OnPlayerGone()
	SIGNAL_HANDLER
	player = null
	qdel(src)

/datum/deltarune_battle/proc/OnEnemyGone()
	SIGNAL_HANDLER
	enemy = null
	qdel(src)

/datum/deltarune_battle/ui_state(mob/user)
	return GLOB.always_state

/datum/deltarune_battle/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/deltarune))

/datum/deltarune_battle/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DeltaruneBattle", "Encounter")
		ui.open()
		ui_ref = ui

/datum/deltarune_battle/ui_data(mob/user)
	. = list()
	.["phase"]          = phase
	.["dialog"]         = dialog
	.["enemy_speech"]   = enemy_speech
	.["mercy"]          = mercy_pct
	.["player_hp"]      = player ? max(0, player.health) : 0
	.["player_hp_max"]  = player ? player.maxHealth : 100
	.["enemy_hp"]       = enemy ? max(0, enemy.health) : 0
	.["enemy_hp_max"]   = enemy ? enemy.maxHealth : 100
	.["player_name"]    = player ? capitalize(player.real_name) : "Player"
	.["enemy_name"]     = enemy ? capitalize(enemy.name) : "Enemy"
	.["player_icon"]    = player_icon_b64
	.["pattern"]        = last_attack_pattern
	.["act_options"]    = list("Check", "Compliment", "Threaten", "Lecture")
	.["item_options"]   = list(
		list("name" = "Bandage", "desc" = "Heals 20 HP"),
		list("name" = "Pipis",   "desc" = "Deals 30 damage"),
	)

/datum/deltarune_battle/proc/EnterMenu()
	if(QDELETED(src) || !player)
		return
	phase = DR_PHASE_MENU
	dialog = "* What will [capitalize(player.real_name)] do?"
	defending = FALSE
	SStgui.update_uis(src)

/datum/deltarune_battle/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("menu_pick")
			HandleMenuPick(params["choice"])
			return TRUE
		if("fight_resolve")
			HandleFightResult(params["quality"])
			return TRUE
		if("act_pick")
			HandleActPick(params["choice"])
			return TRUE
		if("item_pick")
			HandleItemPick(params["choice"])
			return TRUE
		if("bullet_hell_done")
			HandleBulletHellDone(params["hits"])
			return TRUE
		if("close")
			qdel(src)
			return TRUE

/datum/deltarune_battle/proc/HandleMenuPick(choice)
	switch(choice)
		if("fight")
			phase = DR_PHASE_FIGHT_TIMING
			dialog = "* Press at the center for max damage."
		if("act")
			phase = DR_PHASE_ACT_LIST
			dialog = "* Pick an action."
		if("item")
			phase = DR_PHASE_ITEM_LIST
			dialog = "* Pick an item."
		if("spare")
			TrySpare()
		if("defend")
			defending = TRUE
			dialog = "* [capitalize(player.real_name)] braced for impact."
			BeginEnemyTurn()
	SStgui.update_uis(src)

/datum/deltarune_battle/proc/HandleFightResult(quality)
	var/dmg = 5
	switch(quality)
		if("great") dmg = 35
		if("good")  dmg = 22
		if("miss")  dmg = 5
	enemy.adjustBruteLoss(dmg)
	dialog = "* [capitalize(enemy.name)] took [dmg] damage!"
	if(enemy.health <= 0)
		WinBattle()
		return
	BeginEnemyTurn()

/datum/deltarune_battle/proc/HandleActPick(choice)
	switch(choice)
		if("Check")
			dialog = "* [capitalize(enemy.name)] - This ambivalent diamond isn't any girl's best friend."
		if("Compliment")
			enemy_speech = "Yeah I guess that makes sense."
			mercy_pct = min(100, mercy_pct + 25)
			dialog = "* You complimented the rudinn. It's blushing slightly."
		if("Threaten")
			enemy_speech = "You kidding? I can't quit. Stopping you is my job!"
			dialog = "* The rudinn doesn't take you seriously."
		if("Lecture")
			enemy_speech = "(Yawn)... What? OK..."
			mercy_pct = min(100, mercy_pct + 40)
			dialog = "* You lectured the enemies on the importance of kindness. The enemies became TIRED..."
	BeginEnemyTurn()

/datum/deltarune_battle/proc/HandleItemPick(choice)
	switch(choice)
		if("Bandage")
			if(player)
				player.adjustBruteLoss(-20)
			dialog = "* You used the Bandage. Recovered 20 HP."
		if("Pipis")
			enemy.adjustBruteLoss(30)
			dialog = "* You used the Pipis. Dealt 30 damage."
			if(enemy.health <= 0)
				WinBattle()
				return
	BeginEnemyTurn()

/datum/deltarune_battle/proc/TrySpare()
	if(mercy_pct >= 100)
		phase = DR_PHASE_END_SPARE
		dialog = "* You spared [capitalize(enemy.name)]."
		SStgui.update_uis(src)
		addtimer(CALLBACK(src, PROC_REF(EndBattle), TRUE), 2 SECONDS)
		return
	enemy_speech = "I'm just a normal person."
	dialog = "* [capitalize(enemy.name)] isn't ready to be spared. (Mercy: [mercy_pct]%)"
	BeginEnemyTurn()

/datum/deltarune_battle/proc/BeginEnemyTurn()
	phase = DR_PHASE_ENEMY_INTRO
	enemy_speech = pick(GetRudinnAttackLines())
	dialog = "* [capitalize(enemy.name)] attacks!"
	SStgui.update_uis(src)
	addtimer(CALLBACK(src, PROC_REF(BeginBulletHell)), 1.5 SECONDS)

/datum/deltarune_battle/proc/BeginBulletHell()
	if(QDELETED(src))
		return
	phase = DR_PHASE_BULLET_HELL
	last_attack_pattern = PickBulletPattern()
	SStgui.update_uis(src)

/datum/deltarune_battle/proc/HandleBulletHellDone(hits)
	hits = isnum(hits) ? hits : 0
	var/dmg_per_hit = 6
	if(defending)
		dmg_per_hit = round(dmg_per_hit / 2)
	var/total = hits * dmg_per_hit
	if(total > 0 && player)
		player.adjustBruteLoss(total)
		dialog = "* You took [total] damage."
	else
		dialog = "* You dodged everything!"
	defending = FALSE
	if(player.health <= 0)
		LoseBattle()
		return
	EnterMenu()

/datum/deltarune_battle/proc/WinBattle()
	phase = DR_PHASE_END_WIN
	dialog = "* You won! [capitalize(enemy.name)] was defeated."
	SStgui.update_uis(src)
	addtimer(CALLBACK(src, PROC_REF(EndBattle), TRUE), 2 SECONDS)

/datum/deltarune_battle/proc/LoseBattle()
	phase = DR_PHASE_END_LOSE
	dialog = "* You fell."
	SStgui.update_uis(src)
	addtimer(CALLBACK(src, PROC_REF(EndBattle), FALSE), 2 SECONDS)

/datum/deltarune_battle/proc/EndBattle(won)
	if(won && enemy && !QDELETED(enemy))
		if(phase == DR_PHASE_END_SPARE)
			if(enemy_return_turf)
				enemy.forceMove(enemy_return_turf)
			enemy.LoseTarget()
		else
			qdel(enemy)
			enemy = null
	qdel(src)

/// Quote pools per the user's reference dialog.
/datum/deltarune_battle/proc/GetRudinnNeutralLines()
	return list(
		"Long live the guy who pays us!",
		"I'm just a normal person.",
		"Shine, shine",
		"I spend all my money on RENT and MYSTIC GEMs.",
	)

/datum/deltarune_battle/proc/GetRudinnAttackLines()
	return list(
		"Face my Diamond Cutter!",
		"Shine, shine",
		"Long live the guy who pays us!",
	)

/datum/deltarune_battle/proc/PickBulletPattern()
	return MakeDiamondToss()
