# Portfolio Investigation System - Technical Overview

## System Architecture

This document explains the technical implementation of the Portfolio Investigation System for distortion hunting.

---

## Core System Flow

### 1. Distortion Spawn & Portfolio Generation

**When a distortion spawns:**

1. **System selects distortion type** from available pool
   - Example: "Another Day at Work"

2. **Load distortion configuration**
   - Retrieve distortion config datum: `/datum/distortion_config/another_day_at_work`
   - Contains fixed story traits and randomization pools

3. **Generate investigation datum**
   - Create new `/datum/distortion_investigation`
   - Links to the distortion config

4. **Generate semi-randomized portfolio (Answer Key)**
   - **Randomized traits** - Pick from config's `randomized_trait_pools`:
     - `full_name = pick("Marcus", "David", "Sarah") + " " + pick("Chen", "Park", "Smith")`
     - `job_title = pick("Junior Accountant", "Data Entry Clerk", ...)`
     - `company = pick("Wing Corp Financial", "K Corp Subsidiary", ...)`
     - `home_district = pick("District 8", "District 23", ...)`
     - `spouse_name, child_name_1, child_name_2, etc.`

   - **Fixed story traits** - Copy directly from config's `fixed_story_traits`:
     - `primary_stressor = "Abusive supervisor with impossible demands..."`
     - `triggering_event = "During mandatory meeting, publicly blamed..."`
     - `personality_trait_1 = "Dedicated and loyal to a fault"`
     - All stressors, mental states, breaking point details

5. **Store complete profile data**
   - Investigation datum now contains full "answer key"
   - Example: `investigation.profile_data["full_name"] = "Marcus Chen"`
   - Example: `investigation.profile_data["primary_stressor"] = "Abusive supervisor..."`

6. **Initialize tier system**
   - Set `current_tier = 0`
   - Set `location_progress = 0`
   - Initialize `unlocked_fields = list()`
   - Initialize `spawned_clues = list()`

7. **Spawn Tier 0 clues**
   - Select 5-7 random clues from config's Tier 0 evidence types
   - Spawn them in city locations (based on `common_locations`)
   - Each clue dynamically generates description using profile data

---

### 2. Evidence Item Spawning

**Clue item creation process:**

```dm
/obj/item/clue
	var/clue_type = "employee_id_basic"
	var/tier_requirement = 0
	var/list/reveals_fields = list("full_name", "job_title", "company")
	var/datum/distortion_investigation/linked_investigation
	var/description_template = "[company] - [full_name] - [job_title] - Employee #[random_id]"
	var/scanned = FALSE

/obj/item/clue/proc/GenerateDescription()
	if(!linked_investigation)
		return initial(desc)

	var/final_desc = description_template

	// Replace all [trait_name] placeholders with actual values
	for(var/trait_name in linked_investigation.profile_data)
		var/value = linked_investigation.profile_data[trait_name]
		final_desc = replacetext(final_desc, "\[[trait_name]\]", value)

	// Generate random elements (IDs, dates, etc.)
	final_desc = replacetext(final_desc, "\[random_id\]", "[rand(1000, 9999)]")

	return final_desc

/obj/item/clue/examine(mob/user)
	. = ..()
	. += GenerateDescription()
	if(scanned)
		. += span_notice("This evidence has been ANALYZED.")
	else
		. += span_warning("This evidence needs to be scanned at an Investigation Scanner.")
```

**Example generation:**

Template: `"[company] - [full_name] - [job_title] - Employee #[random_id]"`

With profile data:
- `company = "Wing Corp Financial Division"`
- `full_name = "Marcus Chen"`
- `job_title = "Junior Accountant"`
- `random_id = "4821"`

Generated description:
`"Wing Corp Financial Division - Marcus Chen - Junior Accountant - Employee #4821"`

---

### 3. Evidence Scanning System

**Scanner Machine Interaction:**

```dm
/obj/machinery/investigation_scanner
	name = "Investigation Evidence Scanner"
	desc = "A machine for analyzing evidence and extracting information."
	var/scanner_type = "basic" // "basic", "advanced", "portable"
	var/processing = FALSE

/obj/machinery/investigation_scanner/attack_hand_with_item(obj/item/I, mob/user)
	if(!istype(I, /obj/item/clue))
		to_chat(user, span_warning("This machine only accepts evidence items."))
		return

	var/obj/item/clue/evidence = I

	if(evidence.scanned)
		to_chat(user, span_warning("This evidence has already been analyzed."))
		return

	if(!evidence.linked_investigation)
		to_chat(user, span_warning("ERROR: Evidence is not linked to an active investigation."))
		return

	ScanEvidence(evidence, user)

/obj/machinery/investigation_scanner/proc/ScanEvidence(obj/item/clue/evidence, mob/user)
	processing = TRUE
	visible_message(span_notice("[src] begins analyzing the evidence..."))

	// Animation delay
	sleep(3 SECONDS)

	// Mark evidence as scanned
	evidence.scanned = TRUE

	// Get the investigation datum
	var/datum/distortion_investigation/investigation = evidence.linked_investigation

	// Unlock fields in the portfolio
	for(var/field in evidence.reveals_fields)
		if(!(field in investigation.unlocked_fields))
			investigation.unlocked_fields += field

	// Show results
	visible_message(span_notice("[src] completes the analysis."))
	to_chat(user, span_boldnotice("ANALYSIS COMPLETE"))
	to_chat(user, span_notice("Evidence Type: [evidence.clue_type]"))
	to_chat(user, span_notice("Tier: [evidence.tier_requirement]"))
	to_chat(user, span_notice("Unlocked Portfolio Fields:"))
	for(var/field in evidence.reveals_fields)
		to_chat(user, span_notice("  ✓ [field]"))

	// Open portfolio UI for user
	investigation.OpenPortfolioUI(user)

	processing = FALSE
```

---

### 4. Portfolio UI & Field Unlocking

**Portfolio Interface (TGUI):**

```typescript
// tgui/packages/tgui/interfaces/DistortionPortfolio.tsx

interface PortfolioData {
  profile_data: Record<string, string>;      // The answer key (hidden from player)
  unlocked_fields: string[];                 // Fields player can fill
  player_answers: Record<string, string>;    // What player has entered
  location_progress: number;                 // 0-100%
  current_tier: number;                      // Current unlock tier
  total_payment: number;                     // Ahn earned so far
}

export const DistortionPortfolio = (props, context) => {
  const { act, data } = useBackend<PortfolioData>(context);

  return (
    <Window width={800} height={600}>
      <Window.Content scrollable>
        <Section title="Investigation Portfolio">

          {/* Progress Bar */}
          <ProgressBar value={data.location_progress / 100}>
            Location Progress: {data.location_progress}%
          </ProgressBar>

          {/* Personal Identity Section */}
          <Section title="Personal Identity">
            <FieldInput
              label="Full Name"
              field="full_name"
              unlocked={data.unlocked_fields.includes('full_name')}
              value={data.player_answers['full_name'] || ''}
              onSubmit={(value) => act('submit_field', { field: 'full_name', value })}
            />

            <FieldInput
              label="Age"
              field="age"
              unlocked={data.unlocked_fields.includes('age')}
              value={data.player_answers['age'] || ''}
              onSubmit={(value) => act('submit_field', { field: 'age', value })}
            />

            {/* ... more fields ... */}
          </Section>

          {/* Other sections ... */}

        </Section>
      </Window.Content>
    </Window>
  );
};

// Field Input Component
const FieldInput = ({ label, field, unlocked, value, onSubmit }) => {
  const [inputValue, setInputValue] = useState(value);

  if (!unlocked) {
    return (
      <LabeledList.Item label={label}>
        <Box color="grey">
          🔒 LOCKED - Scan evidence to unlock
        </Box>
      </LabeledList.Item>
    );
  }

  return (
    <LabeledList.Item label={label}>
      <Input
        value={inputValue}
        onChange={(e, val) => setInputValue(val)}
        onEnter={() => onSubmit(inputValue)}
      />
      <Button
        icon="check"
        tooltip="Submit answer"
        onClick={() => onSubmit(inputValue)}
      />
      🔓
    </LabeledList.Item>
  );
};
```

**Backend (DM):**

```dm
/datum/distortion_investigation
	var/datum/distortion_config/config
	var/list/profile_data = list()           // The answer key
	var/list/unlocked_fields = list()        // Fields that can be filled
	var/list/player_answers = list()         // What player has submitted
	var/location_progress = 0                // 0-100%
	var/current_tier = 0
	var/total_payment = 0

/datum/distortion_investigation/ui_data(mob/user)
	var/list/data = list()

	data["unlocked_fields"] = unlocked_fields
	data["player_answers"] = player_answers
	data["location_progress"] = location_progress
	data["current_tier"] = current_tier
	data["total_payment"] = total_payment

	// DO NOT send profile_data (answer key) to client!

	return data

/datum/distortion_investigation/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("submit_field")
			var/field = params["field"]
			var/value = params["value"]

			if(!(field in unlocked_fields))
				to_chat(usr, span_warning("This field is locked!"))
				return TRUE

			SubmitAnswer(field, value, usr)
			return TRUE

/datum/distortion_investigation/proc/SubmitAnswer(field, submitted_value, mob/user)
	// Store the answer
	player_answers[field] = submitted_value

	// Check if correct
	var/correct_value = profile_data[field]
	var/is_correct = (submitted_value == correct_value)

	if(is_correct)
		// Calculate progress added
		var/progress_added = CalculateProgressValue(field)
		location_progress += progress_added
		location_progress = min(location_progress, 100)

		// Calculate payment
		var/payment = CalculatePayment(field, progress_added)
		total_payment += payment

		// Pay the player
		var/mob/living/carbon/human/H = user
		if(istype(H))
			H.AdjustAhn(payment)

		to_chat(user, span_boldnotice("CORRECT! +[progress_added]% progress. +[payment] Ahn."))

		// Check if tier unlocked
		CheckTierUnlock()
	else
		to_chat(user, span_warning("Information recorded. Progress will update when tier requirements are met."))

	return is_correct
```

---

### 5. Tier Progression System

**Checking tier unlock requirements:**

```dm
/datum/distortion_investigation/proc/CheckTierUnlock()
	var/next_tier = current_tier + 1

	switch(next_tier)
		if(1)
			// Tier 1: Need name + district + age
			if(IsCorrect("full_name") && IsCorrect("home_district") && IsCorrect("age"))
				UnlockTier(1)

		if(2)
			// Tier 2: Need 3 job-related fields
			var/job_fields_correct = 0
			if(IsCorrect("job_title")) job_fields_correct++
			if(IsCorrect("company")) job_fields_correct++
			if(IsCorrect("work_location")) job_fields_correct++
			if(IsCorrect("employment_status")) job_fields_correct++

			if(job_fields_correct >= 3)
				UnlockTier(2)

		if(3)
			// Tier 3: Need 3 relationship fields
			var/relationship_fields_correct = 0
			if(IsCorrect("marital_status")) relationship_fields_correct++
			if(IsCorrect("spouse_name")) relationship_fields_correct++
			if(IsCorrect("children_count")) relationship_fields_correct++
			if(IsCorrect("child_name_1")) relationship_fields_correct++

			if(relationship_fields_correct >= 3)
				UnlockTier(3)

		// ... additional tiers ...

		if(7)
			// Tier 7: Portfolio 70%+ complete + Breaking Point filled
			if(location_progress >= 70 && IsBreakingPointComplete())
				UnlockTier(7)

/datum/distortion_investigation/proc/IsCorrect(field)
	if(!(field in player_answers))
		return FALSE
	return (player_answers[field] == profile_data[field])

/datum/distortion_investigation/proc/UnlockTier(tier_number)
	current_tier = tier_number

	// Spawn new clues in the world
	SpawnTierClues(tier_number)

	// Notify player
	var/district = profile_data["home_district"] || "the city"
	AnnounceToInvestigators("New leads discovered! Check [district] for more evidence.")

/datum/distortion_investigation/proc/SpawnTierClues(tier)
	// Get clues for this tier from config
	var/list/tier_clues = list()
	for(var/clue_type in config.allowed_evidence_types)
		var/obj/item/clue/C = GetCluePrototype(clue_type)
		if(C.tier_requirement == tier)
			tier_clues += clue_type

	// Spawn 3-6 random clues
	var/clues_to_spawn = rand(3, 6)
	for(var/i = 1 to clues_to_spawn)
		var/clue_type = PickWeighted(tier_clues, config.clue_spawn_weights)
		var/spawn_location = PickSpawnLocation(config.common_locations, tier)

		SpawnClueInWorld(clue_type, spawn_location)

/datum/distortion_investigation/proc/SpawnClueInWorld(clue_type, location)
	// Create the clue item
	var/obj/item/clue/C = new /obj/item/clue(location)
	C.clue_type = clue_type
	C.linked_investigation = src

	// Load template and configuration
	var/clue_config = GetClueConfig(clue_type)
	C.reveals_fields = clue_config["reveals_fields"]
	C.tier_requirement = clue_config["tier"]
	C.description_template = clue_config["template"]

	// Generate description
	C.desc = C.GenerateDescription()
	C.name = clue_config["name"]

	// Track spawned clues
	spawned_clues += C
```

---

### 6. Progress & Payment Calculation

**How progress percentage is calculated:**

```dm
/datum/distortion_investigation/proc/CalculateProgressValue(field)
	// Different fields worth different amounts
	switch(field)
		// Basic identity fields - 2% each
		if("full_name", "age", "gender", "home_district")
			return 2

		// Job fields - 3% each
		if("job_title", "company", "work_location")
			return 3

		// Relationship fields - 3% each
		if("marital_status", "spouse_name", "children_count")
			return 3

		// Stressor fields - 5% each (important)
		if("primary_stressor", "secondary_stressor_1", "secondary_stressor_2")
			return 5

		// Personality/mental state - 4% each
		if("personality_trait_1", "mental_state_initial", "mental_state_final")
			return 4

		// Breaking point fields - 10% each (critical)
		if("triggering_event", "breaking_point_location")
			return 10

		// Default
		else
			return 1

/datum/distortion_investigation/proc/CalculatePayment(field, progress_added)
	// Base payment per progress point
	var/base_payment_per_percent = 100 // 100 Ahn per 1%

	var/payment = progress_added * base_payment_per_percent

	// Bonus for critical fields
	if(progress_added >= 10)
		payment *= 1.5 // 50% bonus for breaking point info

	// Round to nearest 10
	payment = round(payment, 10)

	return payment

// Example calculations:
// Basic field (2%): 2 * 100 = 200 Ahn
// Job field (3%): 3 * 100 = 300 Ahn
// Stressor (5%): 5 * 100 = 500 Ahn
// Breaking point (10%): 10 * 100 * 1.5 = 1,500 Ahn
// Total possible: ~10,000-15,000 Ahn for complete investigation
```

---

### 7. Bus Ticket Generation

**When portfolio reaches 100%:**

```dm
/datum/distortion_investigation/proc/CheckCompletion()
	if(location_progress >= 100)
		EnableBusTicketCreation()

/datum/distortion_investigation/proc/EnableBusTicketCreation()
	// Mark investigation as complete
	investigation_complete = TRUE

	// Announce to all investigators
	AnnounceToInvestigators(span_boldnotice("INVESTIGATION COMPLETE! Distortion location identified. Bus ticket now available."))

	// Enable bus ticket creation at terminals
	for(var/obj/machinery/investigation_terminal/T in GLOB.investigation_terminals)
		T.available_tickets += src

/obj/machinery/investigation_terminal/ui_act(action, params)
	switch(action)
		if("create_bus_ticket")
			var/datum/distortion_investigation/inv = params["investigation"]
			if(!inv.investigation_complete)
				to_chat(usr, span_warning("Investigation not complete!"))
				return

			// Create bus ticket
			var/obj/item/bus_ticket/distortion/ticket = new(get_turf(src))
			ticket.destination = inv.GetDistortionLocation()
			ticket.distortion_name = inv.config.distortion_name

			to_chat(usr, span_boldnotice("Bus ticket created for [ticket.distortion_name]!"))
			usr.put_in_hands(ticket)
```

---

## Complete Data Flow Example

### Marcus Chen Investigation

**Step 1: Distortion Spawns**
```dm
profile_data = list(
	// RANDOMIZED
	"full_name" = "Marcus Chen",
	"age" = "34",
	"job_title" = "Junior Accountant",
	"company" = "Wing Corp Financial Division",
	"home_district" = "District 8",
	"spouse_name" = "Jordan",
	"child_name_1" = "Emma",
	"child_name_2" = "Lucas",

	// FIXED (from config)
	"primary_stressor" = "Abusive supervisor with impossible demands and constant belittling",
	"triggering_event" = "During a mandatory department meeting, the supervisor publicly blamed...",
	"personality_trait_1" = "Dedicated and loyal to a fault",
	// ... all other fixed story traits
)
```

**Step 2: Tier 0 Clues Spawn**
- Newspaper article (vague description)
- Abandoned briefcase (generic office supplies)
- Public alert (distortion in District 8)
- Witness statement (scared office worker)

**Step 3: Player Finds & Scans Evidence**
```
Player finds: Employee ID Badge
Examines: "Wing Corp Financial Division - Marcus Chen - Junior Accountant - Employee #4821"
Takes to Scanner → Unlocks: full_name, job_title, company, work_location
Player fills in: "Marcus Chen", "Junior Accountant", "Wing Corp Financial Division"
System checks: ✓ All correct
Rewards: +8% progress, +800 Ahn
```

**Step 4: Tier 1 Unlocks**
```
Player has: full_name ✓, home_district (from public alert) ✓, age (needs to find)
Finds wallet → Scans → Unlocks age field
Fills in: "34" ✓
System: Tier 1 requirements met!
→ Spawns 5 new clues in District 8 residential areas
```

**Step 5-8: Progressive Investigation**
- Tier 2 unlocks → Workplace clues spawn
- Tier 3 unlocks → Family clues spawn
- Tier 4 unlocks → Financial evidence spawns
- Continue until Tier 7...

**Step 9: Investigation Complete**
```
location_progress = 100%
total_payment = 12,500 Ahn
Bus ticket unlocked → Travel to distortion encounter
```

---

## Performance Considerations

**Optimization strategies:**

1. **Clue Pooling:**
   - Pre-generate clue templates at server start
   - Only create instances when needed
   - Destroy clues when scanned and no longer needed

2. **Investigation Datum Cleanup:**
   - Delete investigation datum when distortion is defeated
   - Clean up spawned clues that weren't found
   - Archive completed investigations for records

3. **UI Updates:**
   - Only send changed data to TGUI
   - Batch field updates instead of per-field
   - Cache common calculations

4. **Spawn Distribution:**
   - Don't spawn all clues at once
   - Spread spawns across map to reduce congestion
   - Limit concurrent investigations (1-2 active at a time)

---

## Anti-Cheat Measures

1. **Answer Key Security:**
   - Never send `profile_data` to client
   - All validation server-side only
   - No client-side hints about correctness

2. **Evidence Verification:**
   - Track which evidence has been scanned
   - Prevent duplicate scanning
   - Validate evidence authenticity (linked to active investigation)

3. **Progress Gating:**
   - Can't skip tiers
   - Must have evidence to unlock fields
   - Cooldown on submission attempts

4. **Exploit Prevention:**
   - Rate limit field submissions
   - Validate all input data types
   - Check for impossible combinations

---

## Future Expansion Hooks

**Designed for easy expansion:**

1. **New Distortion Types:**
   - Create new `/datum/distortion_config` subtype
   - Define story traits and randomization pools
   - System automatically handles evidence generation

2. **New Evidence Types:**
   - Add to evidence type registry
   - Define template and reveals_fields
   - Configure spawn weights

3. **New Tiers:**
   - Add tier unlock conditions to `CheckTierUnlock()`
   - Define tier-specific evidence pools
   - Balance progress values

4. **Cooperative Investigations:**
   - Multiple players share investigation datum
   - Track individual contributions
   - Split payment based on contribution

5. **Investigation Skills:**
   - Skill system affects scanner quality
   - Higher skill = better hints, auto-fill
   - Unlock special evidence types
