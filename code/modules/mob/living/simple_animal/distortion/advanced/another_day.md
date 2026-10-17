# Another Day at Work

An office worker who never went home, covered in the ties of everyone who
kept him there. He never moves and never attacks. The rooms around him do the
work: they grow, drain the people in them, lock their doors, and hang anyone
who breaks. Hitting him piles his workload onto you. The way through is to
find out who did this to him and say their names where he can hear.

| | |
|---|---|
| Fear level | TETH |
| Health | 900 |
| Resistances | RED 0.2, WHITE 0.15, BLACK 0.1, PALE 0.3 |
| Moves / attacks | Never / never |
| Territory | 25 turfs at spawn, cap 1000, stages at 50 / 200 / 500 |
| Taboo | Damaging him: Workload stacks and a sanity hit |
| Weakened by | Saying the boss, co-worker and friend names inside his territory |
| Undistorted by | Saying his own name, from his name tie, with all three colours drained |
| Rewards | Killed: N Corp documents. Undistorted: the worker, alive, with his EGO |
| Files | `another_day.dm` (one file, see Code map) |

## Passive presence

He spawns, claims the room around him, and sits there for the rest of the
round. He does not wander (`wanders = FALSE`, `Move()` returns FALSE) and
`CanAttack()` is always FALSE, so nothing about him is hostile until someone
makes it so.

What a player passing through notices, before stage 3:

- Single pages drifting in from one side and settling on the floor, then
  fading.
- Paper planes fading in overhead, gliding a few tiles and fading where they
  land. Unfolded, the page inside is too limp to read or fold again.
- Now and then a page that lands and stays: a clue (see Investigation).
- His tie with a name on the label, lying somewhere in the territory.

Oddities only play on claimed turfs within 7 tiles of a player, so an empty
territory does nothing.

## How it builds

Growth is `467 / sqrt(size)` turfs a minute: a fast start that keeps slowing.
Doors cost 6 turfs of budget, so rooms tend to arrive one at a time. Times
below ignore door cost and are a little early in practice.

| Stage | Size | About | Adds |
|---|---|---|---|
| 0 | 25 | spawn | Oddities: drifting pages, paper planes, clue pages |
| 1 | 50 | 1 min | Oddities twice as often |
| 2 | 200 | 4 min | Oddities three times as often |
| 3 | 500 | 16 min | The quilt, the drain, door locking, the hanging |
| 4 | 1000 (cap) | 45 min | Faster drain and locking; all speech inside is forced to a whisper |

Stage 3 (`gimmick_stage`) is where the territory turns on the people in it:

- **The quilt.** The innermost ~40 turfs, by steps from his spawn, become tie
  floor, and walls touching them become quilted wall. It reaches ~55 turfs at
  the cap. Every turf is put back when he goes.
- **The drain.** Everyone inside loses 1 sanity every 10 seconds, sometimes
  with one of his lines in their head ("Is it still Monday?").
- **Doors.** One airlock in the territory is bolted for 10 seconds every 30
  seconds. A door he bolted is left alone for a minute after; a door someone
  else bolted is never touched.
- **The hanging.** Any panicked human inside gets a long tie dropped on them,
  in one of the colours he still has. It lifts them off the floor and chokes
  them (30 oxygen damage a second). Nobody can loosen it. A weapon with reach
  2 or more, a thrown object or a shot cuts it (40 integrity), and the body
  drops. A body that dies up there stays hanging, swaying, until cut down.
- A deepening-shadow oddity joins the paper.

At stage 4 (`fast_stage`) the drain runs every 3 seconds and a door locks
every 10. Everything said inside comes out as a whisper, so a team spread
across his rooms has to stand close to talk.

The territory never shrinks. Draining the co-worker's colour pauses its growth
and every effect above (see Step 2, Exposure).

## The taboo

- **The rule:** do not hurt him.
- **How he knows:** every source of damage ends in `deal_damage()`, so one
  hook (`PostDamageReaction()`) catches melee, punches, shots, throws and area
  attacks. The cost is gated to once per attacker every 2 seconds, however fast
  they swing.
- **What breaking it does:**
  - The attacker gains a **Workload** stack. Two or more stacks blur their
    vision, more with each stack. Three or more slow them. At six they fall
    asleep for 3 seconds, can gain no stacks meanwhile, and wake at three.
    Stacks only fall off outside his territory, one every 20 seconds.
  - He **sulks**. Everyone in the territory hears the line in their head. The
    attacker loses 15 sanity, cut by their WHITE armour; everyone else inside
    loses 2.
  - Any hit cancels an undistortion in progress.
- **Why brute force is hard:** 900 health behind 0.1-0.3 resistances means a
  long fight. Every attacker in it is half blind, slowed, falling asleep and
  losing sanity, and everyone else inside is losing sanity too. Anyone who
  panics is hanged by the room. Leaving the territory to shed stacks takes 2
  minutes to clear a full six.

## Investigation

### What is rolled at spawn

- Three random names: his **boss**, his **co-worker** and his **friend**.
- His own name, picked from five.
- Which tie colour each person holds is fixed: red is the boss, blue the
  co-worker, yellow the friend. The papers never say this.

The names only exist in this round's clues, so knowing the distortion does
not skip step 1, Investigation.

### Where the clues are

| Clue | Where it comes from | What it tells you |
|---|---|---|
| Clue page | One drifting-page oddity in seven lands and stays; 10% of paper planes carry one | One of the three names, and enough of the story to tell whose |
| Name tie | Lies on a random claimed turf; a new one appears whenever the last is gone | His own name, on the label |

- Each person has three documents: a performance review, memo or overtime
  sheet for the boss; a promotion email, proposal cover page or sticky note
  for the co-worker; a phone log, birthday card or chat log for the friend.
- At most three pages per person lie in the territory at once.
- A page pales over 3 minutes and vanishes once it is lying on the floor.
  Held or pocketed, it waits. The name tie works the same way.

### Step 2, Exposure: weakening him (the easy route)

Say a name anywhere in his territory. No need to see him. That person's colour
drains from his ties for 60 seconds, the speaker shakes, and what the colour
stood for stops:

| Colour | Person | While drained |
|---|---|---|
| Red | Boss | Hits give no Workload. The sulk still happens. |
| Yellow | Friend | His resistances are multiplied by 4 (RED 0.8, WHITE 0.6, BLACK 0.4, PALE 1.2) |
| Blue | Co-worker | The drain, door locking, hanging and forced whispers stop, and the territory stops growing |

Saying a name again restarts its 60 seconds. With red and yellow down, a team
can kill him in a fair fight that costs sanity but nothing else. Players learn
which name is which colour by watching which one greys out.

### Step 3, Catharsis: undistorting him (the hard route)

Find the name tie and read his name off the label. With all three colours
drained, say his name where he is in sight. Then:

- All three colours come back at once, and light breaks out of him over 30
  seconds. The territory's effects and growth hold for those 30 seconds.
- Any damage to him in that time cancels it. Because red is back, that hit
  also gives Workload.
- Said with a colour still showing, or out of his sight, his name does
  nothing, and the speaker is told which.

At the end the worker steps out alive, with his EGO (Waging, weapon and
armour), and drops a horrible tie. The territory and everything he made go
with him.

## Fighting him

He has no attacks. The fight is the taboo and the room: Workload on the
attackers, sanity loss on everyone inside, the hanging for anyone who breaks.
Counters, in order of value:

1. Drain red, so the attackers take no Workload.
2. Drain yellow, so the attackers do four times the damage.
3. Drain blue, if the room has reached stage 3, so nobody inside panics into
   a tie.
4. Keep someone with a reach weapon or a gun near anyone low on sanity, to cut
   them down.

## Death and cleanup

- **Killed:** he drops N Corp documents. The human stored inside him, if he
  was made from one, dies with him. The territory reverts, every quilt turf
  and wall is put back, and every clue, plane, name tie and hanging tie he
  made is deleted. Hanged people drop.
- **Undistorted:** the same cleanup, but the worker is released alive with
  the EGO.
- Workload stacks outlive him and decay anywhere once he is gone.

## Code map

All in `another_day.dm`, in this order:

| Section | Contents |
|---|---|
| Mob | Vars, `Move()`, `Initialize()` rolls the names, `Teardown()`, `PostUnmanifest()` |
| The quilt | `UpdateQuilt()`, `QuiltSize()`, `ApplyCenterEffects()`, door tracking |
| The taboo | `PostDamageReaction()`, `Taboo()`, `AddWorkload()`, `Sulk()`, `MindSpeak()` |
| The names | `TerritoryTick()`, `OnSpeech()`, `ForceWhisper()`, `DrainColour()`, `ApplyColour()`, undistortion |
| Passive territory | `PassiveEffects()`, `LockRandomDoor()` |
| The hanging | `TryHang()` |
| Clues | `ClueRole()`, `RegisterClue()` |
| Workload | `/datum/status_effect/stacking/distortion_workload` |
| Oddities | Drifting page, clue page, paper plane, limp page, `AnotherDayDrift()` |
| Turfs | Quilt floor and wall |
| Clue documents | Name tie, clue page, `ClueTemplates()` |
| Hanging tie | `/obj/structure/another_day_tie` and its shadow |

## Tuning

| Group | Vars (default) |
|---|---|
| Territory | `territory_cap` (1000), `territory_stages` (50, 200, 500), `territory_growth_rate` (467), `gimmick_stage` (3), `fast_stage` (4) |
| Quilt | `quilt_fraction` (0.35), `quilt_growth_power` (0.5) |
| Taboo | `taboo_cooldown` (2 s), `sulk_damage` (15), `sulk_sanity` (2) |
| Workload | `max_stacks` (6), `decay_interval` (20 s), `sleep_time` (3 s), `blur_per_stack` (2) |
| Names | `drain_duration` (60 s), `drained_resistance_mult` (4), `undistort_time` (30 s) |
| Passive | `drain_sanity` (1), `drain_interval` (10 s / 3 s fast), `door_lock_interval` (30 s / 10 s fast), `door_lock_time` (10 s), `door_lock_cooldown` (60 s), `idle_message_chance` (25) |
| Clues | `clues_per_person` (3), plane `clue_chance` (10), page and tie `lifetime` (3 min) |
| Hanging | `oxy_per_tick` (30), `max_integrity` (40) |

## Admin and testing

- Spawn `/mob/living/simple_animal/hostile/distortion/advanced/another_day`.
  It is not in the random distortion pool.
- The rolled names are in his `people` list (View Variables). His own is
  `people["self"]`.
- To skip ahead, call `territory.Claim(500)` on him for stage 3, or
  `territory.Claim(1000)` for the cap.
- Pieces spawned alone are safe: a clue page with no owner is a plain page,
  a plane with no owner carries a blank, and a hanging tie with no owner
  still works.
