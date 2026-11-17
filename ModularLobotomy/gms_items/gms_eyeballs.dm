// Eyeballs, the currency of the Grand Magasin: gold coins stamped with an open eye. They stack up to 30 to a pile,
// and a bottle keeps up to 200 in one item.

/// A pile of eyeball coins. Its sprite grows from one coin to a heap as the pile does. Coins a foe spills lie
/// scattered on the floor, and are sorted back into neat stacks as soon as anyone picks them up or the pile changes.
/obj/item/stack/gms_eyeball
	name = "eyeballs"
	singular_name = "eyeball"
	desc = "Gold coins stamped with an open eye. The Magasin takes them, and so does everyone in it."
	icon = 'icons/obj/gms/gms_eyeballs.dmi'
	icon_state = "eyeball"
	max_amount = 30
	novariants = FALSE
	w_class = WEIGHT_CLASS_TINY
	full_w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FIRE_PROOF | ACID_PROOF
	drop_sound = 'ModularLobotomy/_Lobotomysounds/gms/eyeball_coin_drop.ogg'
	/// Played once when coins burst out in many piles, in place of each pile's own landing sound.
	var/burst_sound = 'ModularLobotomy/_Lobotomysounds/gms/eyeball_multi_coin_drop.ogg'
	/// The fewest coins each bigger sprite needs, from eyeball_2 up to eyeball_5.
	var/list/sprite_thresholds = list(2, 5, 10, 20)
	/// Lying loose as a foe spilled them, drawn with the eyeball_scattered states, until sorted.
	var/scattered = FALSE
	/// A thrown pile bigger than this bursts into smaller piles of up to this many when it lands.
	var/spill_pile_size = 5

/obj/item/stack/gms_eyeball/update_icon_state()
	var/tier = 1
	for(var/threshold in sprite_thresholds)
		if(amount >= threshold)
			tier++
	var/base = scattered ? "[initial(icon_state)]_scattered" : initial(icon_state)
	// Not calling the parent, which would set its own three-sprite icon_state over this one.
	icon_state = tier == 1 ? base : "[base]_[tier]"

/// Lays the coins out loose, as if just spilled.
/obj/item/stack/gms_eyeball/proc/Scatter()
	scattered = TRUE
	update_icon()

/// Gathers loose coins back into neat stacks.
/obj/item/stack/gms_eyeball/proc/Sort()
	if(!scattered)
		return
	scattered = FALSE
	update_icon()

// Thrown coins land loose, and a big pile bursts apart. Only a throw by someone bursts a pile: the piles a dying
// foe flings have no thrower, so they land as they are.
/obj/item/stack/gms_eyeball/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	// A flung pile lands silently (see Fling()); it gets its landing sound back now.
	drop_sound = initial(drop_sound)
	if(. || QDELETED(src))
		return
	if(throwingdatum?.thrower && amount > spill_pile_size)
		BurstApart()
	Scatter()

/// Throws the pile to a tile without its own landing sound, for the many piles of a burst, which share one sound.
/obj/item/stack/gms_eyeball/proc/Fling(turf/spot)
	if(spot == loc)
		return
	drop_sound = null
	throw_at(spot, get_dist(src, spot), 2)

/// Splits off piles of 1 to spill_pile_size coins, flinging each onto this tile or one beside it, until this pile
/// is no bigger than that either.
/obj/item/stack/gms_eyeball/proc/BurstApart()
	var/turf/landing = get_turf(src)
	if(!landing)
		return
	playsound(landing, burst_sound, 50, TRUE)
	var/list/spots = RANGE_TURFS(1, landing)
	while(amount > spill_pile_size)
		var/part_size = rand(1, spill_pile_size)
		use(part_size)
		var/obj/item/stack/gms_eyeball/part = new(landing, part_size, FALSE)
		part.Scatter()
		part.Fling(pick(spots))

/obj/item/stack/gms_eyeball/pickup(mob/user)
	. = ..()
	Sort()

// Merging, splitting and taking coins out all go through these two, so any change to the pile sorts it.
/obj/item/stack/gms_eyeball/add(_amount)
	scattered = FALSE
	return ..()

/obj/item/stack/gms_eyeball/use(used, transfer = FALSE, check = TRUE)
	scattered = FALSE
	return ..()

// Coins clink whenever piles are joined or split. The split-off pile plays it, since this one may be used up.
/obj/item/stack/gms_eyeball/merge(obj/item/stack/S, limit)
	. = ..()
	if(.)
		playsound(S, initial(drop_sound), 40, TRUE)

/obj/item/stack/gms_eyeball/split_stack(mob/user, amount)
	. = ..()
	if(.)
		playsound(., initial(drop_sound), 40, TRUE)

/// A corked bottle that keeps up to capacity eyeballs as one item. Use coins on it to put them in, use it in hand
/// to take some out. Held or worn on the belt or in a pocket, it scoops up any eyeballs its holder walks over.
/// Glass, like a drink bottle: it shatters when thrown, smashed over someone, or when its holder is knocked down,
/// spilling its eyeballs.
/obj/item/gms_eyeball_bottle
	name = "eyeball bottle"
	desc = "A corked glass bottle for keeping eyeballs in. The coins inside all seem to look back at you."
	icon = 'icons/obj/gms/gms_eyeballs.dmi'
	icon_state = "eyeball_bottle"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	throwforce = 10
	resistance_flags = FIRE_PROOF | ACID_PROOF
	var/eyeballs = 0
	var/capacity = 200
	/// How many fullness sprites there are, eyeball_bottle_1 up to this one.
	var/fill_sprites = 5
	/// Whoever holds or wears it, watched so it can scoop up the eyeballs they walk over, and break if they fall.
	var/mob/holder
	/// Set once it has told its holder it is full, so walking over more coins does not repeat it every step.
	var/warned_full = FALSE
	/// Damage dealt when smashed over someone on harm intent.
	var/smash_damage = 10
	/// Coins going into the bottle.
	var/fill_sound = 'ModularLobotomy/_Lobotomysounds/gms/eyeball_coin_bottle_drop.ogg'
	/// Coins coming out, or spilling when it breaks.
	var/pour_sound = 'ModularLobotomy/_Lobotomysounds/gms/eyeball_coin_drop.ogg'
	var/spill_sound = 'ModularLobotomy/_Lobotomysounds/gms/eyeball_multi_coin_drop.ogg'

/obj/item/gms_eyeball_bottle/Initialize()
	. = ..()
	update_icon()

/obj/item/gms_eyeball_bottle/Destroy()
	StopWatching()
	return ..()

/obj/item/gms_eyeball_bottle/examine(mob/user)
	. = ..()
	. += span_notice("It holds [eyeballs] of [capacity] eyeballs.")
	. += span_notice("Carried in hand, on the belt or in a pocket, it scoops up the eyeballs you walk over.")

/obj/item/gms_eyeball_bottle/update_icon_state()
	if(!eyeballs)
		icon_state = initial(icon_state)
		return ..()
	icon_state = "[initial(icon_state)]_[clamp(CEILING(eyeballs * fill_sprites / capacity, 1), 1, fill_sprites)]"
	return ..()

// Called when picked up, worn or moved between hands and slots; not while packed away in a bag.
/obj/item/gms_eyeball_bottle/equipped(mob/user, slot, initial)
	. = ..()
	if(holder == user)
		return
	StopWatching()
	holder = user
	RegisterSignal(holder, COMSIG_MOVABLE_MOVED, PROC_REF(Scoop))
	RegisterSignal(holder, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(OnHolderFell))

/obj/item/gms_eyeball_bottle/dropped(mob/user, silent)
	. = ..()
	StopWatching()

/obj/item/gms_eyeball_bottle/proc/StopWatching()
	if(!holder)
		return
	UnregisterSignal(holder, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_SET_BODY_POSITION))
	holder = null

/// The holder went down. Knocked down, slipped or stunned, not lying down on purpose, buckled to a bed, or passing
/// out, the bottle falls out of their hand, belt or pocket and breaks. Bottles packed in a bag are not watched.
/obj/item/gms_eyeball_bottle/proc/OnHolderFell(mob/living/user)
	SIGNAL_HANDLER
	if(user.body_position != LYING_DOWN || user.resting || user.buckled || user.stat != CONSCIOUS)
		return
	INVOKE_ASYNC(src, PROC_REF(FallAndBreak), user)

/obj/item/gms_eyeball_bottle/proc/FallAndBreak(mob/living/user)
	var/turf/landing = get_turf(user)
	if(QDELETED(src) || !landing || !user.dropItemToGround(src, TRUE))
		return
	user.visible_message(span_warning("[src] falls from [user] and shatters!"), span_warning("[src] falls and shatters!"))
	Shatter(landing, user, TRUE)

/// Puts as much of a pile into the bottle as fits. Returns how many went in.
/obj/item/gms_eyeball_bottle/proc/AddCoins(obj/item/stack/gms_eyeball/coins)
	var/moved = min(coins.get_amount(), capacity - eyeballs)
	if(moved <= 0)
		return 0
	coins.use(moved)
	eyeballs += moved
	update_icon()
	return moved

/// Scoops every eyeball on the tile its holder just stepped onto.
/obj/item/gms_eyeball_bottle/proc/Scoop(mob/living/user)
	SIGNAL_HANDLER
	var/turf/tile = user.loc
	if(!isturf(tile))
		return
	var/scooped = 0
	var/left_behind = FALSE
	for(var/obj/item/stack/gms_eyeball/coins in tile)
		scooped += AddCoins(coins)
		if(!QDELETED(coins))
			left_behind = TRUE
	if(scooped)
		warned_full = FALSE
		playsound(user, fill_sound, 50, TRUE)
		to_chat(user, span_notice("You scoop [scooped] eyeball\s into [src]. It now holds [eyeballs]."))
	if(left_behind && !warned_full)
		warned_full = TRUE
		to_chat(user, span_warning("[src] is full."))

/obj/item/gms_eyeball_bottle/attackby(obj/item/I, mob/user, params)
	if(!istype(I, /obj/item/stack/gms_eyeball))
		return ..()
	var/moved = AddCoins(I)
	if(!moved)
		to_chat(user, span_warning("[src] is full."))
		return TRUE
	playsound(src, fill_sound, 50, TRUE)
	to_chat(user, span_notice("You drop [moved] eyeball\s into [src]. It now holds [eyeballs]."))
	return TRUE

/obj/item/gms_eyeball_bottle/attack_self(mob/user)
	if(!eyeballs)
		to_chat(user, span_warning("[src] is empty."))
		return
	var/wanted = input(user, "How many eyeballs do you take out? (up to [eyeballs])", "[src]") as null|num
	if(!wanted || QDELETED(src) || !user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, FALSE, TRUE))
		return
	wanted = clamp(round(wanted), 0, eyeballs)
	if(!wanted)
		return
	eyeballs -= wanted
	update_icon()
	TakeOut(user, wanted)
	playsound(src, pour_sound, 50, TRUE)
	to_chat(user, span_notice("You shake [wanted] eyeball\s out of [src]."))

/// Pours out that many eyeballs. A pile caps at 30, so anything past that lands on the floor as more piles,
/// and the rest goes into the user's hands if there is room.
/obj/item/gms_eyeball_bottle/proc/TakeOut(mob/user, count)
	var/obj/item/stack/gms_eyeball/coins = new(user.drop_location(), count, FALSE)
	user.put_in_hands(coins)

/// Empties the bottle across the floor around a tile as loose coins: small piles flung up to a tile away, or two
/// tiles for more than 50 coins. Piles grow with the amount so a full bottle makes about 25, not 70.
/obj/item/gms_eyeball_bottle/proc/SpillCoins(turf/spill)
	var/spread = eyeballs > 50 ? 2 : 1
	var/biggest_pile = clamp(CEILING(eyeballs / 15, 1), 5, 30)
	var/list/spots = RANGE_TURFS(spread, spill)
	while(eyeballs > 0)
		var/pile_size = min(rand(1, biggest_pile), eyeballs)
		eyeballs -= pile_size
		var/obj/item/stack/gms_eyeball/coins = new(spill, pile_size, FALSE)
		coins.Scatter()
		coins.Fling(pick(spots))

/// A full bottle, for mapping and testing.
/obj/item/gms_eyeball_bottle/full
	eyeballs = 200

/obj/item/gms_eyeball_bottle/attack(mob/living/target, mob/living/user)
	if(user.a_intent != INTENT_HARM)
		return ..()
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("You don't want to harm [target]!"))
		return
	user.do_attack_animation(target)
	target.deal_damage(smash_damage, RED_DAMAGE, user, attack_type = ATTACK_TYPE_MELEE)
	if(target == user)
		user.visible_message(span_danger("[user] smashes [src] over [user.p_their()] own head!"), \
			span_userdanger("You smash [src] over your own head!"))
	else
		target.visible_message(span_danger("[user] smashes [src] over [target]!"), \
			span_userdanger("[user] smashes [src] over you!"))
	log_combat(user, target, "smashed", src)
	Shatter(target, user)

// Like a drink bottle, it breaks wherever a throw ends, unless someone catches it.
/obj/item/gms_eyeball_bottle/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!. && !QDELETED(src))
		Shatter(hit_atom, throwingdatum?.thrower, TRUE)

/// Breaks the bottle: its eyeballs spill where it broke, glass may scatter, and a broken bottle is left behind,
/// cut from this bottle's own sprite the way drink bottles are. Smashed over someone, it stays in the smasher's hand.
/obj/item/gms_eyeball_bottle/proc/Shatter(atom/target, mob/user, thrown = FALSE)
	var/turf/spill = get_turf(target) || get_turf(src)
	if(eyeballs && spill)
		SpillCoins(spill)
		playsound(spill, spill_sound, 50, TRUE)
	var/obj/item/broken_bottle/broken = new(drop_location())
	var/icon/broken_icon = new(icon, initial(icon_state))
	broken_icon.Blend(broken.broken_outline, ICON_OVERLAY, rand(5), 1)
	broken_icon.SwapColor(rgb(255, 0, 220, 255), rgb(0, 0, 0, 0))
	broken.icon = broken_icon
	broken.name = "broken [name]"
	if(prob(33))
		new /obj/item/shard(spill)
	playsound(spill, "shatter", 70, TRUE)
	transfer_fingerprints_to(broken)
	qdel(src)
	if(!thrown && user)
		user.put_in_hands(broken)
