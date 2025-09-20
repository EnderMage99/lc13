# R-Corp Expedition Specialist Update - Complete Documentation

## Table of Contents
1. [Research System Overview](#research-system-overview)
2. [Mob Harvesting & Body Parts](#mob-harvesting--body-parts)
3. [Research Tree & Projects](#research-tree--projects)
4. [Specialist Classes](#specialist-classes)
5. [Weapons & Equipment](#weapons--equipment)
6. [Fuel Management System](#fuel-management-system)
7. [Role-Specific Updates](#role-specific-updates)

---

## Research System Overview

### How to Gain Research Points

The research system works through **marking and harvesting body parts** from X-Corp and Resurgence Clan enemies. Marked enemies drop body parts with specific research traits when killed.

**Basic Process:**
1. Use the **R-Corp Biological Harvester** to mark living enemies (60 second duration)
2. Kill marked enemies before the mark expires
3. Body parts automatically drop from marked enemies
4. Collect dropped body parts
5. Insert body parts into the **R-Corp Research Console**
6. Each body part provides trait points based on enemy type
7. Spend accumulated points to unlock research projects

### R-Corp Biological Harvester
- **Type:** Energy gun with infinite ammo
- **Function:** Marks enemies for biological sample extraction
- **Mark Duration:** 60 seconds
- **Valid Targets:** X-Corp and Resurgence Clan mobs only
- **Visual Indicator:** Green shield overlay on marked enemies

### Research Console Interface

The Research Console uses a TGUI interface with:
- **Visual node tree** showing all available research paths with progress bars
- **Research selection** - Choose which project to feed body parts to
- **Body part storage** - Hold up to 10 parts awaiting processing
- **Requirements display** for each project showing favored/negative traits
- **Per-project progress tracking** - Each research tracks its own completion

---

## Mob Harvesting & Body Parts

### Harvesting System Overview
The harvesting system uses a **trait-based** approach rather than direct attribute points. Enemies must be marked with the R-Corp Biological Harvester before death to drop body parts. Each mob type drops parts containing specific traits that are valued differently by different research projects.

### Valid Harvest Targets
- **X-Corp Forces** - Human military units with organic traits
- **Resurgence Clan** - Mechanical units (or hybrid when greed-touched)

### X-Corp Mob Drop Table

| Mob Type | Traits | Drop Count | Drop Chance | Base Value |
|----------|--------|------------|-------------|------------|
| **X-Corp Grunt** (Laute) | Organic, Fodder, Heavy | 1 | 100% | 10 |
| **X-Corp DPS** (Studiose) | Organic, Weaponized, Agile | 1-2 (50%) | 80% | 20 |
| **X-Corp Tank** (Nimis) | Organic, Armored, Heavy | 1-2 (50%) | 85% | 22 |
| **X-Corp Scout** (Praepropere) | Organic, Agile, Volatile | 1 | 75% | 22 |
| **X-Corp Sapper** (Ardenter) | Organic, Psionic, Aberrant, Toxic | 1 | 90% | 22 |
| **Heart DPS** (Sumptus Excessivi) | Organic, Elite, Weaponized, Berserker | 1-2 (50%) | 80% | 35 |
| **Heart Ranged** (Sicarius) | Organic, Elite, Precision, Agile | 1-2 (50%) | 80% | 35 |
| **Heart Base** (Accumulatio) | Organic, Elite, Heavy, Regenerative | 1-2 (50%) | 80% | 35 |

### Resurgence Clan Drop Table

| Mob Type | Traits | Drop Count | Drop Chance | Base Value |
|----------|-----------------|-------------------------|------------|-------------|------------|
| **Scout** | Hybrid, Lightweight, Fodder | 1 | 100% | 10 |
| **Defender** | Hybrid, Armored, Ossified | 1 | 90% | 20 |
| **Drone** | Hybrid, Neural, Toxic | 1 | 95% | 15 |
| **Demolisher** | Hybrid, Weaponized, Heavy, Brutal | 1-2 (50%) | 85% | 30 |
| **Assassin** | Hybrid, Agile, Elite, Aberrant | 1-2 (50%) | 75% | 35 |
| **Sniper** | Hybrid, Precision, Aberrant | 1 | 80% | 22 |
| **Gunner** | Hybrid, Weaponized, Fodder | 1 | 85% | 25 |
| **Rapid** | Hybrid, Volatile, Erratic | 1 | 90% | 20 |
| **Warper** | Hybrid, Neural, Psionic, Corrupted | 1-2 (50%) | 75% | 35 |
| **Harpooner** | Hybrid, Weaponized, Brutal | 1 | 80% | 30 |
| **Corrupter** (Boss) | Hybrid, Corrupted, Elite, Hivemind | 2-3 (50%) | 60% | 60 |

### Trait Descriptions

#### Movement Traits
- **Lightweight**: Enhanced speed or low mass
- **Heavy**: Significant mass or slow movement
- **Agile**: Special movement abilities
- **Sluggish**: Slower than standard
- **Erratic**: Unpredictable movement patterns

#### Combat Traits
- **Armored**: Heavy defensive capabilities
- **Weaponized**: High damage output
- **Fodder**: Weak or expendable
- **Berserker**: More dangerous at low health
- **Precision**: Accurate, targeted attacks
- **Brutal**: Crude but effective attacks

#### Type Traits
- **Mechanical**: Robotic or mechanical construction
- **Organic**: Flesh and blood construction
- **Hybrid**: Fusion of mechanical and organic
- **Corrupted**: Tainted by supernatural forces

#### Special Traits
- **Elite**: Superior variant
- **Psionic**: Mental/psychic abilities
- **Neural**: Advanced cognitive systems
- **Aberrant**: Unusual or mutated
- **Toxic**: Poisonous or corrosive
- **Volatile**: Unstable or explosive
- **Energized**: Electrical or energy-based
- **Regenerative**: Self-healing capabilities
- **Adaptive**: Can adjust to threats
- **Ossified**: Bone-like hardening
- **Hivemind**: Collective consciousness

### How Traits Affect Research Progress

When feeding body parts to a selected research project:
1. Base value starts at the part's base value (8-60 points)
2. Each favored trait adds a percentage bonus to that value
3. Each negative trait reduces the value by a percentage
4. If the part lacks ALL required traits (when applicable), it's rejected entirely
5. Final calculated value is added to that specific research's progress

**Example:** The Heavy Flamethrower project favors "Weaponized" and "Mechanical" traits:
- An X-Corp DPS part (base 20, has Weaponized) would contribute ~26 points
- An X-Corp Grunt part (base 10, has Fodder which is negative) would contribute ~7 points
- You'd need approximately 6-8 well-matched parts to complete the 150-point project

---

## Research Tree & Projects

### How Research Works
Each project must be individually fed body parts to progress. The system works as follows:
1. **Select a target research** from the tree (must have prerequisites met)
2. **Insert body parts** into the research console
3. **Process parts** to feed them to the selected research
4. Body parts contribute value based on trait matching:
   - Parts with **favored traits** provide bonus points (Major +50%, Moderate +30%, Minor +10%)
   - Parts with **negative traits** reduce effectiveness (Major -50%, Moderate -30%, Minor -10%)
   - Projects with **required traits** will reject parts that don't have at least one required trait
5. Once enough parts are fed to reach the cost threshold, the research completes

**Important:** There is no generic research point pool - each project tracks its own progress independently

### FIRE WEAPONS TREE (Hellfire Roosters)

#### Tier 1 - Basic Fire Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Pyro Grenade Manufacturing** | 50 | None | Volatile (Mod), Organic (Min), Weaponized (Min) | Mechanical (Min), Armored (Min) | None | Pyro grenade factory |
| **Heavy Fuel Tank Production** | 40 | None | Mechanical (Mod), Efficient (Min), Lightweight (Min) | Corrupted (Min), Volatile (Mod) | None | Fuel tank factory |
| **Hellfire Protection Suit** | 60 | None | Armored (Maj), Reinforced (Mod), Organic (Min) | Lightweight (Mod), Fragmented (Maj) | None | Hellfire armor factory |

#### Tier 2 - Advanced Fire Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Heavy Flamethrower System** | 150 | fuel_tank | Weaponized (Maj), Mechanical (Mod), Energized (Min) | Fodder (Mod), Primitive (Min) | Mechanical OR Weaponized | Heavy flamethrower |
| **Thermite Sprayer** | 120 | pyro_grenade | Volatile (Maj), Toxic (Mod), Experimental (Min) | Armored (Mod), Heavy (Min) | Volatile OR Toxic OR Organic | Thermite sprayer weapon |
| **Inferno Wall Projector** | 140 | fuel_tank | Neural (Mod), Adaptive (Mod), Energized (Min) | Primitive (Maj), Fodder (Mod) | Neural OR Adaptive OR Mechanical | Inferno wall weapon |
| **Automatic Defense Flamethrower** | 180 | heavy_flamethrower | Mechanical (Maj), Neural (Mod), Adaptive (Mod), Precision (Min) | Erratic (Maj), Primitive (Mod), Fodder (Min) | Mechanical AND Neural | Auto-flamethrower factory |

#### Tier 3 - Elite Fire Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Inferno Rush Blade** | 250 | heavy_flamethrower, hellfire_armor | Agile (Maj), Weaponized (Maj), Lightweight (Mod), Berserker (Min) | Heavy (Maj), Sluggish (Maj), Armored (Min) | Agile AND Weaponized | Inferno rush blade |
| **Pyroclastic Burst Gauntlets** | 220 | thermite_sprayer, hellfire_armor | Brutal (Maj), Volatile (Mod), Heavy (Mod), Weaponized (Min) | Lightweight (Mod), Precision (Min) | Brutal AND Volatile AND Organic | Pyroclastic gauntlets |
| **Napalm Launcher** | 280 | heavy_flamethrower, inferno_wall | Elite (Maj), Weaponized (Maj), Precision (Mod), Mechanical (Min) | Fodder (Maj), Primitive (Mod), Erratic (Min) | Elite AND Weaponized AND Precision | Napalm launcher |

### TOXIC WEAPONS TREE (Venom Rattlesnakes)

#### Tier 1 - Basic Toxic Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Acid Tank Production** | 40 | None | Toxic (Maj), Organic (Mod), Efficient (Min) | Mechanical (Min), Armored (Mod) | None | Acid tank factory |
| **Acid Sprayer** | 50 | None | Toxic (Mod), Volatile (Min), Organic (Min) | Reinforced (Min), Heavy (Min) | None | Acid sprayer weapon |
| **Toxic Mine Manufacturing** | 45 | None | Mechanical (Mod), Toxic (Mod), Precision (Min) | Erratic (Maj), Fodder (Min) | None | Toxic mine factory |
| **Corrosive Grenade Production** | 55 | None | Volatile (Mod), Toxic (Mod), Weaponized (Min) | Armored (Min), Mechanical (Min) | None | Acid grenade factory |

#### Tier 2 - Advanced Toxic Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Venom Launcher** | 140 | acid_tank, acid_grenade | Toxic (Maj), Weaponized (Mod), Precision (Min) | Lightweight (Mod), Fodder (Min) | Toxic AND Weaponized | Venom launcher |
| **Decay Cloud Generator** | 130 | acid_sprayer, toxic_mines | Toxic (Maj), Corrupted (Mod), Volatile (Min) | Precision (Mod), Lightweight (Min) | Toxic AND Corrupted AND Organic | Decay cloud device |
| **Venom Injector Rifle** | 120 | acid_tank | Precision (Maj), Toxic (Mod), Neural (Min) | Brutal (Mod), Heavy (Min) | Precision AND Toxic | Venom injector rifle |

#### Tier 3 - Elite Toxic Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Toxic Bombardment System** | 280 | venom_launcher, decay_cloud | Elite (Maj), Toxic (Maj), Weaponized (Mod), Heavy (Min) | Fodder (Maj), Lightweight (Mod), Agile (Min) | Elite AND Toxic AND Weaponized | Toxic bombarder |
| **Plague Scythe** | 240 | acid_tank, venom_injector | Brutal (Maj), Toxic (Maj), Corrupted (Mod), Organic (Min) | Precision (Mod), Mechanical (Min) | Brutal AND Toxic AND Organic | Plague scythe |
| **Miasma Field Generator** | 260 | decay_cloud, venom_injector | Toxic (Maj), Corrupted (Maj), Neural (Mod), Adaptive (Min) | Fodder (Mod), Primitive (Mod), Lightweight (Min) | Toxic AND Corrupted AND Neural | Miasma field device |

### ELECTRIC WEAPONS TREE (Storm Rams)

#### Tier 1 - Basic Electric Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Capacitor Pack Production** | 40 | None | Energized (Maj), Mechanical (Mod), Efficient (Min) | Organic (Min), Corrupted (Mod) | None | Capacitor pack factory |
| **Thunder Gauntlets** | 45 | None | Energized (Mod), Agile (Min), Mechanical (Min) | Heavy (Min), Sluggish (Mod) | None | Thunder gauntlets weapon |
| **Storm Dash Module** | 55 | None | Energized (Mod), Agile (Mod), Neural (Min) | Sluggish (Maj), Fodder (Min) | None | Storm dash device |
| **Static Burst Generator** | 50 | None | Energized (Mod), Adaptive (Mod), Mechanical (Min) | Primitive (Mod), Organic (Min) | None | Static burst field device |
| **EMP Grenade Production** | 30 | None | Energized (Mod), Volatile (Min), Mechanical (Min) | Armored (Min), Organic (Min) | None | EMP grenade factory |

#### Tier 2 - Advanced Electric Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Lightning Ram** | 150 | capacitor_pack, thunder_gauntlets | Energized (Maj), Brutal (Mod), Reinforced (Min) | Lightweight (Mod), Fodder (Min) | Energized AND Brutal | Lightning ram weapon |
| **Thunderclap Gauntlets** | 130 | thunder_gauntlets, storm_dash | Agile (Maj), Energized (Mod), Berserker (Min) | Sluggish (Maj), Heavy (Mod) | Agile AND Energized | Thunderclap gauntlets |
| **Storm Surge Barrier** | 140 | static_burst, capacitor_pack | Reinforced (Maj), Energized (Mod), Adaptive (Min) | Fragmented (Maj), Fodder (Min) | Reinforced AND Energized | Storm surge barrier |

#### Tier 3 - Elite Electric Projects

| Project | Cost | Prerequisites | Favored Traits | Negative Traits | Required Traits | Unlocks |
|---------|------|--------------|----------------|-----------------|-----------------|---------|
| **Railgun Charge** | 250 | lightning_ram, thunderclap | Elite (Maj), Energized (Maj), Brutal (Mod), Precision (Min) | Fodder (Maj), Lightweight (Mod), Erratic (Min) | Elite AND Energized AND Brutal | Railgun charge module |
| **Thunderstorm Slam** | 280 | thunderclap, storm_surge | Elite (Maj), Energized (Maj), Weaponized (Mod), Neural (Min) | Fodder (Maj), Primitive (Mod), Lightweight (Min) | Elite AND Energized AND Weaponized | Thunderstorm slam device |

### Factory Production Costs

Once unlocked, factories consume R-Corp materials (red/green) to produce items:

| Item | Red Cost | Green Cost |
|------|----------|------------|
| Pyro Grenade | 1 | 1 |
| Fuel Tank | 0 | 2 |
| Hellfire Armor Set | 2 | 2 |
| Auto-Flamethrower | 3 | 2 |
| Acid Tank | 0 | 2 |
| Toxic Mine | 1 | 1 |
| Acid Grenade | 1 | 1 |
| Capacitor Pack | 0 | 2 |
| EMP Grenade | 1 | 1 |

### Research Tips
- **Elite parts** (from Heart units, Assassins, Corrupters) are extremely valuable for Tier 3 projects
- **Corrupted parts** (greed-touched) are essential for high-tier toxic weapons
- **Mechanical vs Organic** - Fire favors organic, Electric favors mechanical, Toxic uses both
- **Required traits** - Save rare parts with specific combinations for critical unlocks
- Projects with multiple required traits need parts that have ALL listed traits

---

## Specialist Classes (Simplified)

### Overview
Specialist classes are **elite transformations** for Rook personnel, accessed via neural implants. Each class grants access to exclusive weapon types, provides combat bonuses, and locks out normal weapons. The simplified system focuses on passive benefits and weapon accessibility rather than active abilities.

### Class Comparison Table

| Aspect | Hellfire Rooster | Venom Rattlesnake | Storm Ram |
|--------|------------------|-------------------|-----------|
| **Role** | Fire Weapons Specialist | Toxic Weapons Specialist | Electric Melee Specialist |
| **Special Traits** | TRAIT_RESISTHEAT, TRAIT_NOFIRE | None | TRAIT_PUSHIMMUNE, TRAIT_SHOCKIMMUNE |
| **Attribute Bonuses** | +20 Fort, -20 Prud, +40 Just | +60 Prud, -20 Just | +100 Fort, -20 Prud, +40 Just |
| **Visual Effect** | Fire glow overlay | Venom aura overlay | Electricity overlay |
| **Weapon Restriction** | TRAIT_NOGUNS (all classes) | TRAIT_NOGUNS (all classes) | TRAIT_NOGUNS (all classes) |

### Hellfire Rooster (Fire Specialist)

**Theme:** *"Master of flames and destruction"*

**Transformation Requirements:**
- Must be a Rook
- Hellfire Rooster Combat Implant installed

**Passive Benefits:**
- **TRAIT_NOFIRE** - Complete immunity to being set on fire
- **TRAIT_RESISTHEAT** - Resistance to heat damage  
- **+20 Fortitude, -20 Prudence, +40 Justice**
- **TRAIT_NOGUNS** - Cannot use normal weapons (all specialists have this)

**Core Mechanic - Fire Mastery:**
- Immune to own fire damage and being set on fire
- Fire weapons create persistent area denial (30 second duration)
- Bonus damage to structures (2x normal, 3x vs Seed of Greed)

**Exclusive Fire Weapons:**

**Tier 1 - Basic:**
- **Pyro Grenades** - Throwable incendiary devices
- **Heavy Fuel Tank** - Required backpack (1000 capacity)
- **Hellfire Protection Suit** - Fire-resistant armor

**Tier 2 - Advanced:**
- **Heavy Flamethrower** - 5 fuel/shot, piercing projectiles, creates fire trails
- **Thermite Sprayer** - 20 fuel/spray, delayed explosion area denial
- **Inferno Wall Projector** - 100 fuel/wall, creates fire barriers
- **Automatic Defense Flamethrower** - 3 fuel/shot, suit storage auto-turret

**Tier 3 - Elite:**
- **Inferno Rush Blade** - 50 fuel/dash, melee weapon with fire dash ability
- **Pyroclastic Gauntlets** - 30 fuel/burst in ignition mode
- **Napalm Launcher** - 75 fuel/shot, long range artillery (min 5 tiles)

**Combat Role:**
- Area denial through persistent fire effects
- Structure destruction specialist
- Frontline combat with immunity to own flames
- Requires fuel tank backpack for weapons

### Venom Rattlesnake (Toxic Specialist)

**Theme:** *"Mark enemies with venom, then exploit their weakness"*

**Transformation Requirements:**
- Must be a Rook
- Venom Rattlesnake Combat Implant installed

**Passive Benefits:**
- **+60 Prudence, -20 Justice**
- **TRAIT_NOGUNS** - Cannot use normal weapons (all specialists have this)
- No special immunities or resistances

**Core Mechanic - Venom Stacks:**
- **Duration:** 20 seconds per stack
- **Max Stacks:** 10
- **DoT Damage:** 2 damage/tick per stack (ticks every second)
- **Bonus Effects:** Dizzy at 5+ stacks (20% chance), Paralyze at 8+ stacks (10% chance)
- All toxic weapons deal bonus damage based on venom stacks

**Exclusive Toxic Weapons:**

**Tier 1 - Basic:**
- **Acid Tank** - Required backpack (500 capacity)
- **Acid Sprayer** - 5 acid/spray, cone attack, +20% damage per stack
- **Toxic Mine** - 3s setup, proximity trigger, applies 5 stacks + 20 damage
- **Acid Grenades** - Throwable corrosive devices

**Tier 2 - Advanced:**
- **Venom Launcher** - 10 acid/shot, +15 flat damage per stack
- **Decay Cloud Generator** - 20 acid/use, moving cloud, +15% damage per stack
- **Venom Trap Dispenser** - 5s setup, deploys 3 hidden traps (3 stacks each)
- **Venom Spike Strip Deployer** - 4s setup per strip (3 total), 4 stacks + 15 damage

**Tier 3 - Elite:**
- **Toxic Bombarder** - 30 acid/volley (6 shells), +10 flat damage per stack
- **Plague Scythe** - 10 acid/spin, melee reach 2, +5 flat damage per stack
- **Miasma Field Generator** - 50 acid/activation, +25% damage per stack

**Combat Role:**
- Pre-combat trap deployment essential
- Massive damage multipliers on marked targets
- Territory control through trap placement
- Requires acid tank backpack for weapons

### Storm Ram (Electric Specialist)

**Theme:** *"Rush in, devastate, escape - the living thunderbolt"*

**Transformation Requirements:**
- Must be a Rook
- Storm Ram Combat Implant installed

**Passive Benefits:**
- **TRAIT_SHOCKIMMUNE** - Complete immunity to electrical damage
- **TRAIT_PUSHIMMUNE** - Cannot be displaced or knocked back  
- **TRAIT_NOGUNS** - Melee combat specialist only (applied twice in code)
- **+100 Fortitude, -20 Prudence, +40 Justice**

**Core Mechanic - Rush & Retreat:**
- All weapons are melee/rush focused
- Capacitor pack grants speed boost (-2 movespeed modifier) after attacks
- Speed boosts last 20-60 seconds depending on ability
- Auto-retreat built into some abilities
- Temporary invulnerability during ultimate abilities

**Exclusive Electric Weapons:**

**Tier 1 - Basic:**
- **Capacitor Pack** - Required backpack (1000 capacity)
- **Thunder Gauntlets** - 10 charge/attack, 20 charge/dash, AoE stun on hit
- **Storm Dash Module** - 25 charge, rush through enemies with chain damage
- **Static Burst Generator** - 20 charge, field detonates when owner passes through
- **EMP Grenade** - Stuns organics (3s) and disables machinery

**Tier 2 - Advanced:**
- **Lightning Ram** - 40 charge/charge attack, massive charge with knockback
- **Thunderclap Gauntlets** - 50 charge/burst, auto-retreat dash after AoE
- **Storm Surge Barrier** - 30 charge, mobile shield that pushes enemies

**Tier 3 - Elite:**
- **Railgun Charge** - 75 charge, invulnerable during charge, 120 base damage
- **Thunderstorm Slam** - 80 charge, leap slam with lingering electric field

**Combat Role:**
- Rush specialist with burst melee damage
- Automatic speed boosts for escape after attacks
- Can rush through structures (not walls)
- Requires capacitor pack for weapons

---

## Weapons & Equipment

### Fire Weapons (Hellfire Specialty)

| Weapon | Damage | Fuel Cost | Special |
|--------|--------|-----------|---------|
| Heavy Flamethrower | 8 FIRE/projectile | 5/shot | Range 7, piercing, creates fire trails |
| Inferno Rush Blade | 35 RED + 60 FIRE (dash) | 50/dash | Melee with dash attack, creates persistent fire |
| Thermite Sprayer | 80 FIRE (explosion) | 20/spray | 2s delayed explosion, creates thermite fire |
| Inferno Wall Projector | N/A | 100/wall | Creates 5-tile fire barrier (10s duration) |
| Pyroclastic Gauntlets | 25 RED + 15-30 FIRE | 30/ignition burst | Melee with optional ignition mode |
| Napalm Launcher | 80 FIRE | 75/shot | Min range 5, max 15, creates napalm zones |
| Auto-Defense Flamethrower | 5 FIRE/burst | 3/shot | Suit storage, auto-targets hostiles |

### Toxic Weapons (Venom Specialty)

| Weapon | Damage | Acid Cost | Special |
|--------|--------|-----------|---------|
| Acid Sprayer | 20 TOX base | 5/spray | Cone attack, +20% damage per venom stack |
| Toxic Mine | 20 TOX | N/A (item) | 3s setup, applies 5 venom stacks |
| Venom Trap Dispenser | 10 TOX per trap | N/A (item) | 5s setup, deploys 3 traps (3 stacks each) |
| Venom Spike Strip | 15 BRUTE | 10/strip | 4s setup, 4 stacks + immobilize, 3 uses |
| Venom Launcher | 30 TOX base | 10/shot | +15 damage per venom stack |
| Decay Cloud Generator | 15 TOX/tick | 20/use | Moving cloud, +15% damage per stack |
| Plague Scythe | 45 base | 10/spin attack | Reach 2, +5 damage per stack |
| Toxic Bombarder | 40 TOX base | 30/volley | 6 shells, +10 damage per stack |
| Miasma Field Generator | 8 TOX/tick | 50/activation | Field effect, +25% damage per stack |

### Electric Weapons (Storm Ram Specialty)

| Weapon | Damage | Charge Cost | Special |
|--------|--------|-------------|---------|
| Thunder Gauntlets | 35 BRUTE + 20 FIRE (AoE) | 10/attack, 20/dash | Melee with dash attack, stuns targets |
| Storm Dash Module | 40 BRUTE + 20 FIRE (chain) | 25/dash | Rush through enemies, chain lightning |
| Static Burst Generator | 40 FIRE | 20/deploy | Field explodes when owner passes through |
| Lightning Ram | 50 melee, 80 charge | 15/attack, 40/charge | Massive charge attack, knockback |
| Thunderclap Gauntlets | 45 melee, 60 burst | 30/attack, 50/burst | AoE with auto-retreat dash |
| Storm Surge Barrier | 30 FIRE | 30/activate | Mobile shield, 8s duration, pushes enemies |
| Railgun Charge | 70 melee, 120 charge | 20/attack, 75/ultimate | Invulnerable during charge, passes through enemies |
| Thunderstorm Slam | 100 impact | 80/slam | Leap slam, invulnerable in air, creates storm field |
| EMP Grenade | 20 FIRE | N/A (item) | 3s paralyze, EMP pulse |

### Support Equipment

#### Resource Management Equipment
| Item | Capacity | Weight | Special |
|------|----------|--------|---------|
| Fuel Tank Backpack | 1000 fuel | WEIGHT_CLASS_BULKY | Powers fire weapons, refill at fuel dispensers |
| Acid Tank Backpack | 500 acid | WEIGHT_CLASS_BULKY | Powers toxic weapons, refill at acid dispensers |
| Storm Capacitor Pack | 1000 charge | WEIGHT_CLASS_BULKY | Powers electric weapons, grants speed boosts |
| Portable Fuel Canister | 100 fuel | WEIGHT_CLASS_NORMAL | Field refueling for Hellfire |
| Portable Acid Canister | 100 acid | WEIGHT_CLASS_NORMAL | Field refueling for Venom |
| Portable Power Cell | 200 charge | WEIGHT_CLASS_NORMAL | Field recharging for Storm |

#### Automatic Flamethrower Turret
- **Slot:** Suit Storage (ITEM_SLOT_SUITSTORE)
- **Damage:** 10 FIRE per burst
- **Fire Rate:** Every 2 seconds when active
- **Fuel Consumption:** 3 per shot
- **Range:** 6 tiles
- **Special:** Auto-targets hostile mobs, IFF system prevents friendly fire

---

## Resource Management System

### Overview
All specialist weapons require consumable resources that must be actively managed. They must be refilled at base stations or via portable canisters carried by Ravens.

### Base Resource Stations

#### Fuel Dispensers (Hellfire)
- **Location:** R-Corp base
- **Capacity:** 10,000 fuel units
- **Refill Method:** Use fuel tank on dispenser
- **Alternative:** Fuel tanks at chemistry

#### Acid Dispensers (Venom)  
- **Location:** R-Corp base
- **Capacity:** 5,000 acid units
- **Refill Method:** Use acid tank on dispenser
- **Alternative:** Chemical tanks with acid reagent

#### Power Stations (Storm)
- **Location:** R-Corp base  
- **Capacity:** 10,000 power units
- **Refill Method:** Use capacitor pack on station

### Field Support (Ravens Only)

#### Portable Refueling Items
- **Fuel Canister:** 100 fuel for Hellfire Roosters
- **Acid Canister:** 100 acid for Venom Rattlesnakes  
- **Power Cell:** 200 charge for Storm Rams
- **Usage:** Use canister/cell on specialist's tank/pack
- **Special:** Ravens have no movement penalty from tanks

### Resource Consumption Rates

#### Hellfire Weapons
- **Heavy Flamethrower:** 5-8 fuel per shot
- **Thermite Sprayer:** 10-15 fuel per spray
- **Inferno Wall:** 20 fuel per wall
- **Average Mission:** 300-500 fuel

#### Venom Weapons
- **Acid Sprayer:** 5-10 acid per spray
- **Venom Launcher:** 10 acid per shell
- **Toxic Mine:** 15 acid per mine
- **Average Mission:** 200-400 acid

#### Storm Weapons
- **Thunder Gauntlets:** 10-20 charge per attack
- **Lightning Ram:** 40 charge per charge attack
- **Railgun Charge:** 75 charge for ultimate
- **Average Mission:** 400-600 charge

### Resource Management Tips

1. **Pre-Mission Planning**
   - Check resource levels before deployment
   - Top off at base stations before leaving
   - Ravens should carry 2-3 portable refuel items

2. **During Combat**
   - Monitor resource consumption carefully
   - Call for Raven support before running dry
   - Use high-cost abilities sparingly

3. **Emergency Refueling**
   - Transfer between same-type tanks/packs
   - Chemical tanks can provide emergency acid
   - Power cells from Ravens for emergency charge

### Movement Penalties
- **All tanks/packs:** -2 movement speed when worn
- **Exception:** Ravens (no penalty due to specialized training)
- **Note:** Speed penalties stack with other equipment

---

## Role-Specific Updates

### Rooks (Combat Personnel)
**New Capabilities:**
- Can transform into Specialist Classes via implants
- Access to all three weapon types (fire/toxic/electric)
- Harvesting tool for collecting research materials
- Can use automatic flamethrower turret

**Restrictions:**
- Cannot refuel others in field
- Locked to one specialist class per implant

### Ravens (Support Personnel)
**New Capabilities:**
- Field refueling ability with portable canisters
- No movement penalty from fuel tanks
- Can carry 2x fuel canisters with Supply Lines research
- Access to research console for point tracking

**Unique Equipment:**
- R-Corp Fuel Canister (100 fuel, portable)
- Emergency Repair Kit (fixes specialist equipment)
- IFF Beacon (prevents friendly fire from turrets)

**Support Role:**
- Primary: Keep specialists fueled in field
- Secondary: Harvest high-value targets
- Tertiary: Deploy support equipment

---

## Mission Flow Example

### Phase 1: Preparation
1. Commander assigns specialist roles based on mission type
2. Rooks receive implants at medical bay
3. Specialists equip appropriate fuel tanks
4. Ravens load portable fuel canisters

### Phase 2: Deployment
1. Establish forward fuel station
2. Specialists take defensive positions
3. Ravens position for quick refueling
4. Automatic turrets deployed at choke points

### Phase 3: Combat
1. **Wave 1-3:** Standard X-Corp forces
   - Harvest body parts for research
   - Maintain fuel levels
   - Minimal specialist ability usage

2. **Wave 4-6:** Elite X-Corp units
   - Deploy specialist abilities
   - Ravens provide field refueling
   - Focus on high-value harvests

3. **Boss Wave:** Seed of Greed
   - Hellfire focuses structure (3x damage)
   - Venom marks with trap toxin
   - Storm provides tank/distraction
   - Ravens maintain fuel supply

### Phase 4: Extraction
1. Collect all harvested materials
2. Process at research console
3. Unlock new research projects
4. Prepare for next deployment

---

## Tips and Tricks

### General
- Always harvest elite mobs - they give the most trait points
- Coordinate specialist classes - they synergize well
- Keep Ravens protected - they're essential for long missions
- Factory materials near base can emergency refuel

### Hellfire Rooster
- Fire immunity lets you fight in your own flames
- Heavy Flamethrower creates persistent fire zones
- Prioritize researching fuel tank production early
- Inferno weapons excel at area denial

### Venom Rattlesnake
- **Preparation is everything** - All traps need 3-5 seconds setup
- **No instant marking** - Cannot apply venom on demand, must use traps
- **Territory control** - Set up kill zones with layered traps
- **Massive payoff** - 10 stacks = 200%+ damage with some weapons

### Storm Ram
- **Rush combat** - Get in, burst damage, get out
- **No ranged weapons** - Must close distance to fight
- **Speed management** - Use boosts to escape after attacks
- **Ultimate timing** - Invulnerability frames are key
- **Charge through structures** - Pass through tables and windows during charges

### Ravens
- Always carry maximum fuel canisters
- Stay behind front line but within refuel range
- Prioritize refueling during wave breaks

---

## Balance Considerations

### Fuel Economy
- Average mission consumption: 2000-3000 fuel
- Factory material conversion: 1:10 ratio
- Emergency refuel cost: 10 materials = 100 fuel
- Sustainable with 2-3 active resource points

### Research Progression
- Early game: Focus one weapon type
- Mid game: Unlock specialist training
- Late game: Complete all three paths
- Seed of Greed farming: 10 trait points each

### Power Scaling
- Significant attribute bonuses (up to +100 Fortitude for Storm Ram)
- Require constant resource supply (fuel/acid/charge)
- Cannot use normal weapons (TRAIT_NOGUNS)
- Specialized weapon access only

## Technical Implementation Notes

### File Structure
```
code/modules/rce/
├── specialist_classes.dm (class system)
├── fuel_system.dm (fuel infrastructure)
├── heavy_flamethrower.dm (fire weapons)
├── toxic_weapons.dm (toxic weapons)
├── electric_weapons.dm (electric weapons)
└── research/
    ├── research_console.dm (main console)
    ├── harvest_component.dm (harvesting system)
    └── body_parts.dm (trait items)

tgui/packages/tgui/interfaces/
└── RceResearch.js (research UI)
```

### Key Systems
- **Implant System:** Organ-based transformation
- **Status Effects:** Track specialist states
- **Harvest Component:** Automated body part collection
- **Fuel Component:** Movement penalty management
- **TGUI Integration:** Visual research tree

---

## Changelog Summary

### Major Additions
- **Simplified specialist class system** with 3 paths (Fire/Toxic/Electric)
- 30+ new weapons across 3 damage types and 3 tiers
- Comprehensive research tree with 41 projects
- Trait-based harvesting system for all X-Corp and Clan mobs
- Fuel/Acid/Capacitor management infrastructure
- TGUI research interface with visual node tree
- Automatic flamethrower turret for suit storage slot

### Specialist Classes (Simplified)
- **Hellfire Rooster**: Fire immunity, access to all fire weapons
- **Venom Rattlesnake**: Pierce/poison immunity, venom stacks mechanic for massive damage scaling
- **Storm Ram**: +50% health, stun immunity, access to all electric weapons
- Classes now focus on passive benefits and weapon access (no active abilities)

### Venom Stacks Mechanic
- Toxic mines and traps require 3-second setup time
- Venom stacks last 20 seconds, stack up to 10 times
- All toxic weapons deal bonus damage to venom-marked enemies (+10-25% per stack)
- Creates strategic "mark then execute" gameplay for Venom Rattlesnakes

### Research System
- Body parts drop with traits instead of direct points
- Projects favor/penalize specific traits (Major ±50%, Moderate ±30%, Minor ±10%)
- Some projects require specific trait combinations
- Factory production costs use red/green materials

### Balance Changes
- Ravens immune to fuel tank movement penalties
- Specialists locked from normal weapons
- 50% health bonus for Storm Ram only
- Movement penalties for all fuel/acid/capacitor tanks (except Ravens)
- Fire/toxic/electric damage types properly implemented

### Technical Improvements
- Fixed FIRE damage type (was incorrectly BURN)
- Proper trait-based harvest system implementation
- Resource points now consume factory materials
- TGUI properly displays research nodes and connections
- Simplified class system for easier maintenance

---

*This documentation represents the complete R-Corp Specialist Update as of implementation. For questions or bug reports, contact Endermage.*
