# The Bunnyman

A butcher who judged a street with one look, judged wrong once, and became the
judge who never looks twice. He hides on his ground, unseen but for two red
eyes and a trail of bloody prints. Draw blood on his ground and he has already
decided what you are: he screams, hunts you down, and hangs you on a hook in
his den. The way through is the one piece of evidence he never looked at, and
past that, the name of the one person he killed who did nothing.

| | |
|---|---|
| Fear level | WAW |
| Health | 2000 |
| Resistances | Hidden: RED 0.2, WHITE 1, BLACK 1, PALE 1.5. Hunting: 0.1 to all. Judgement off: RED 0.7, WHITE 1, BLACK 1, PALE 1.5 |
| Moves / attacks | Wanders his ground; attacks only the one he is hunting |
| Territory | 63 turfs at spawn, cap 2000, stages at 100 / 400 / 1000 |
| Taboo | Drawing blood on his ground from anything harmless, him included: the Perpetrator mark, and a hunt |
| Weakened by | Striking him mid-rush with the evidence he never looked at |
| Undistorted by | Saying the innocent's name to him while his judgement is off |
| Rewards | Killed: two N Corp documents. Undistorted: Douglas Grifon, alive, with his EGO |
| Files | `bunnyman/` (9 files, see Code map) |

## Passive presence

He spawns, claims a street's worth of ground, turns the room he spawned in into
his den, and lives there. He is hidden whenever nothing is going on: invisible,
not dense, and walked through like the dark. Two tells give him away:

- A pair of red eyes at face height that move with him. He can still be
  attacked while hidden, and a hit shows him for 3 seconds.
- A blood footprint wherever a step lands, fading in 3 seconds.

His tread is heard either way, hidden or not.

With nobody to hunt, he has a life of his own on his ground. In order of
priority:

1. **Heads.** Someone who died on one of his hooks loses their head to him. He
   works it off (3 seconds), carries it, and plants it on a spear at the edge
   of his territory, named for whose it was. The headless body is later taken
   down and dumped on a pile in the den.
2. **Notices.** A notice read where he can see the reader is torn down the next
   chance he gets. He shows himself to do it, says why, and warns the reader.
3. **Victims.** Someone who had blood drawn on his ground is found and given a
   carrot, once each. Eaten, it heals 20 brute and a quarter of max sanity.
4. **Rabbits.** Now and then he sits with one of his rabbits, heals it fully
   and says something kind.
5. **The den.** Every 5 minutes he goes home for a minute and a half, 30
   seconds longer per stage. He drifts from tile to tile and mutters one part
   of how someone looked (see Step 3, Catharsis).

What a player passing through notices:

- His rabbits, sitting very still, each holding something far too big for it.
- Notices on the walls: a report, a ledger page, a stock list, missing posters.
- Oddities near players: a thump, three or four of his steps in a row, a lone
  bloody footprint, two eyes for a second, a rabbit crossing the far end of the
  corridor, a blood smear that is gone three seconds later.

## How it builds

The territory uses the base growth: 15% of its size a minute, never less than
10 turfs. Doors cost 6 turfs of budget, so real times run a little later than
these.

| Stage | Size | About | Adds |
|---|---|---|---|
| 0 | 63 | spawn | Den (4 tiles from spawn), 4 hooks, 6 rabbits, oddities |
| 1 | 100 | 4 min | Den one tile wider, one more hook, two more rabbits, longer den visits |
| 2 | 400 | 14 min | The same again |
| 3 | 1000 | 20 min | The same, plus hallucinations and mimics |
| 4 | 2000 (cap) | 25 min | The same; hallucinations twice as often |

Every stage, oddities play more often (the base divides their interval by
stage + 1).

**The den** is a flood fill from his spawn through open floor: it never crosses
a wall and stops at doors, so it fills his room and no further. Floors become
rock, and walls touching them become rock wall. Anything standing on it that
is not his is broken; loose items are swept onto one pile by a wall. Hooks go
on free wall-side tiles, never in a doorway.

**From stage 3**, while his judgement is on:

- **Hallucinations.** Everyone inside, every 45-90 seconds (22-45 at the cap),
  sees him burst from the edge of their view and rush at them a tile at a time,
  with his steps. Nobody else sees it. Reaching them costs 20 sanity. It ends
  harmlessly the moment it would step off his ground, so leaving is always the
  answer.
- **Mimics.** Every 3 minutes, one rabbit with a human in view takes his shape
  for that person alone: his scream, their heartbeat, and a run straight at
  them. It is a rabbit again when it reaches them, loses them, or after 30
  seconds. Hurting it is drawing blood from a rabbit, which is the taboo.

## The taboo

- **The rule:** do not draw blood on his ground from anything harmless.
  Harmless is humans, his rabbits, himself, and any mob in the `neutral`
  faction. Hurting someone already marked Perpetrator is free.
- **How he knows:** every living mob on his ground carries a damage hook
  (`COMSIG_MOB_APPLY_DAMGE`). It fires before armour, so a hit that armour
  would swallow still counts. He does not need to see it. Only humans are
  judged; untrackable damage is ignored.
- **What breaking it does:**
  - The attacker is marked **Perpetrator**. They are hunted, oldest first,
    whenever they stand on his ground. The mark only fades after 3 minutes
    spent outside it; stepping back in resets the clock.
  - The one they hurt is marked **Victim** for a minute. Victims are spared by
    his dash and chop, and he brings them a carrot.
- **His things.** There are softer rules around what is his, all needing him
  to see it:
  - Hitting a hook or a head, taking evidence from a rabbit, trying to free
    someone from a hook, reading a notice, or saying one of the dead's names
    each earn a **Warning**. He points and tells them off. Two warnings are
    kept for 10 minutes; the third is the Perpetrator mark.
  - Breaking a hook or a head, or a rabbit letting go of its evidence to
    someone, is the mark at once.
  - Freeing someone from a hook marks both. Done behind his back, the freed one
    is **Paranoid** for 10 minutes, and the Perpetrator the moment he sees
    them.
- **Why brute force is hard:** the first hit on him makes you a Perpetrator.
  From then on he is hunting you at 0.1 resistances to everything, against
  2000 health, and every hunt ends with someone on a hook. Hit while hidden, he
  shows for 3 seconds, long enough to see what you struck.

## The hunt

When a Perpetrator is on his ground and he is free (10 seconds after the last
hunt), he drops whatever errand he was on:

1. **The scream.** He shows himself, enraged, and stands for 3 seconds.
   Everyone on his ground hears it, loud near him and never quite gone at the
   far end. The target's heart starts pounding, with red veins at the edge of
   their view.
2. **The rush.** Fast, off the leash, at 0.1 resistances, after nobody but the
   target. One full blow (25-30 RED) slows them heavily for 3 seconds. Then:
   - **The dash**, if ready (every 8 seconds) and the line is clear: rooted for
     2 seconds while a marker slides from him onto them, then through them and
     3 tiles past, hitting the 3x3 around every tile for 15 RED, once each.
   - **The chop**, if ready (every 12 seconds): half a second's wind-up, then 12
     blows in 4.5 seconds on the tile they stood on, the ring around it one
     wider every 4 blows, 10 RED a blow. It does not follow them.
   - Otherwise he keeps on the rush, hitting as he reaches them.
3. **The drag.** At hard crit the hitting stops. He hauls them over his
   shoulder, walks home and hangs them on a free hook, brute damage mended. The
   Perpetrator mark comes off once they are hung. With every hook taken he
   drives in a new one.

Victims and his rabbits are never hit by the dash or the chop.

The hunt ends if the target gets more than 15 tiles from his ground and out of
his sight. Their mark stays: back on his ground, they are hunted again.

**The hooks.** Nobody gets off alone. Another person can pull them free with
the stock 30-second hold, under the rules in The taboo. Someone who dies
hanging loses their head to him.

## Investigation

### What is rolled at spawn

- **The evidence he never looked at:** one of eight butcher's tools (boning
  knife, cracked cleaver, butcher's knife with a bitten handle, skinning knife,
  bone saw, meat mallet, length of chain, labelled bottle).
- **The attacker's name**, for the incident report.
- **The four he killed.** Each has a name and a look in six parts: hat, hair,
  eyes, shirt, coat, shoes. The first is the innocent. The other three bit, and
  each differs from the innocent in at least two parts of the look.

All of it only exists in this round's clues, so knowing the distortion does
not skip step 1, Investigation.

### Where the clues are

| Clue | Where | What it tells you |
|---|---|---|
| Incident report | Notice on a wall | The attacker's name, and the weapon left at the scene: **the evidence he never looked at** |
| Stock list | Notice on a wall | All eight tools, with one ringed and "never looked." beside it |
| Ledger page | Notice on a wall | That he was wrong about one; that the name must be said to him "when I am not the judge" |
| Missing posters | Notices on walls, one per killed | Each of the four's name and full look |
| His rabbits | Sitting on his ground | Each holds one tool. If no rabbit holds the right one, the next to be restocked gets it |
| His mutters | In the den, idle | One part of the innocent's look at a time, never the name |

- A notice is read by examining it while standing next to it. The window shuts
  when you step away. Read in his sight, he comes to tear it down.
- A notice that is torn down, cut down or ripped goes up somewhere else 20
  seconds later, so ripping never hides anything.
- A rabbit gives what it holds to anyone who walks up on help intent and holds
  a hand out for 3 seconds. Coming at a run, or breaking into one, sends it
  bolting. It never leaves his ground. An emptied rabbit carries again after a
  minute.
- Evidence left lying on the floor for 5 minutes fades back into an empty
  rabbit's hands.

### Step 2, Exposure: weakening him (the easy route)

Strike him with a piece of evidence while he is rushing, preparing the dash or
dashing. It never counts as a hit, so it draws no blood. Either way the piece
breaks in your hands. Outside those moments it does nothing, and is kept.

- **The right piece:** he looks. The hunt ends. Every Perpetrator and Victim
  mark, anywhere, is cleared. His judgement is off for 2.5 minutes: he stands
  where he is, seen, at RED 0.7, until something hurts him. Hurt, he fights
  whoever did it, fairly: no hunt and no dash. He still swings
  and chops.
- **The wrong piece:** he staggers for 3 seconds mid-rush and keeps coming.

In the last 15 seconds he flashes red, each flash quicker than the last: the
warning to get off his ground. When the 2.5 minutes end, everyone who fought
him in the window is a Perpetrator, and the hunts begin again, oldest first.
The window is the fair fight; a team that wants him dead has 2.5 minutes to
do it.

### Step 3, Catharsis: undistorting him (the hard route)

Work out which of the four on the missing posters is the innocent: match the
parts of the look he mutters in his den against the posters. Then, with his
judgement off, say that name inside his territory where he can see you:

- The 2.5-minute window pauses, and light breaks out of him over 30 seconds.
- Any hit on him in that time puts the light out, and the window resumes with
  what was left of it (never less than 10 seconds).
- One of the other three names in the window gets "That one bit." and he turns
  on the speaker.
- Any of the four names said while his judgement is on gets a warning aimed at
  the speaker, worded differently for the innocent's name.

At the end Douglas Grifon steps out alive, in a butcher's outfit, with his EGO
(Animalism and Totalitarianism). The territory and everything he made go with
him.

## Fighting him

- **Before a hunt:** do not. The first hit is the mark.
- **During a hunt:** stay away from the target's line, so you are not in the
  dash. The chop is a fixed ring on the ground: step out of it. A pinned
  target is freed when he has taken 300 damage, but anyone who hurts him in a
  hunt is a Perpetrator too.
- **The right counter** is the evidence. Carry the ringed tool, wait for the
  scream, and strike him as he comes.
- **After the look**, he is a 2000-health mob at RED 0.7 that hits back. Make
  the minute count, or use it for step 3, Catharsis.

## Death and cleanup

- **Killed:** he drops two N Corp documents. The human stored inside him, if
  he was made from one, dies with him. The den's rock is put back, and every
  hook, head on a spear, notice, rabbit and piece of evidence is deleted.
  Anyone on his shoulder is set down. A head he was carrying is dropped.
- **Undistorted:** the same cleanup, but Douglas Grifon is released alive.
- Marks outlive him. With him gone, a Perpetrator mark fades after 3 minutes
  wherever its owner stands.

## Code map

| File | Contents |
|---|---|
| `bunnyman.dm` | Mob vars, `Initialize()`, `Life()`, `Teardown()`, the taboo (`TrackInside()`, `Judge()`), hiding, his things and `Warn()` |
| `hunt.dm` | The hunt, rush, dash and chop, the evidence hit, `Look()`, `JudgementBack()`, the slow, the heartbeat and veins |
| `den.dm` | Den growth, the drag, the hook, the head on a spear, the den turfs |
| `errands.dm` | Errand selection and ticking: heads, notices, carrots, rabbits, den visits, clearing hooks |
| `notices.dm` | Placing and replacing notices, the poster, `NoticeHtml()` |
| `rabbits.dm` | Rabbit count and respawn, the rabbit mob and its mimic, the evidence items |
| `marks.dm` | Perpetrator, Victim, Warned and Paranoid status effects |
| `stages.dm` | His oddities, the stage 3 hallucination, `MimicTick()` |
| `undistort.dm` | The killed (`RollKilled()`), `Mutter()`, hearing names, undistortion |

## Tuning

| Group | Vars (default) |
|---|---|
| Territory | `territory_start_size` (63), `hallucination_stage` (3) |
| Hunt | `scream_time` (3 s), `hunt_speed` (0.9), `hunt_resistances` (0.1), `hunt_leash` (15), `hunt_pause` (10 s) |
| Dash | `dash_windup` (2 s), `dash_overshoot` (3), `dash_damage` (15), `dash_cooldown` (8 s) |
| Chop | `chop_damage` (10), `chop_count` (12), `chop_per_ring` (4), `chop_windup` (0.5 s), `chop_cooldown` (12 s) |
| Judgement | `judgement_off_time` (2.5 min), `judgement_warning` (15 s), `judgement_flash_slowest` (1.5 s), `fair_resistances`, `stagger_time` (3 s), `undistort_time` (30 s), `judgement_resume_floor` (10 s) |
| Marks | Perpetrator `perpetrator_decay` (3 min), Victim duration (1 min), Warned and Paranoid duration (10 min) |
| Den | `den_radius` (4), `den_radius_growth` (1), `spikes_base` (4), `den_interval` (5 min), `den_stay` (1.5 min), `den_stay_per_stage` (30 s) |
| Rabbits | `rabbit_base` (6), `rabbits_per_stage` (2), `rabbit_respawn` (60 s), rabbit `hand_out_time` (3 s), evidence `fade_time` (5 min) |
| Clues | `killed_count` (4), `notices_per_kind` (1), `notice_chance` (4), `notice_replace_delay` (20 s), `mutter_cooldown` (30 s) |
| Stage 3 | `hallucination_interval` (90 s), `hallucination_sanity` (20), `mimic_interval` (3 min) |
| Errands | `pet_chance` (4), `pet_cooldown` (3 min), `den_chance` (2), `mutter_chance` (10), `head_take_time` (3 s) |

## Admin and testing

- Spawn `/mob/living/simple_animal/hostile/distortion/advanced/bunnyman`. It is
  not in the random distortion pool.
- The rolled answers are on him (View Variables): `evidence_kind` is the right
  piece, and `killed[1]` is the innocent (its `name` var).
- To skip ahead, call `territory.Claim(1000)` on him for stage 3, or
  `territory.Claim(2000)` for the cap.
- To test step 2 (Exposure) without a rabbit, spawn the `evidence_kind` path
  and strike him with it after the scream.
- Pieces spawned alone are safe: a rabbit with no Bunnyman goes anywhere and
  gives nothing, a hook or a head with no Bunnyman can be hit and broken
  freely, and a notice with no Bunnyman shows no text.
