
/datum/reagent/abnormality/healing_gel
	name = "L-Corp Healing Gel"
	description = "Restores 3 HP per cycle. Stops working if overdosed. Overdose threshold: 30 units."
	color = "#6baf65"
	health_restore = 3
	overdose_threshold = 30

/datum/reagent/abnormality/healing_gel/on_mob_life(mob/living/M)
	if(overdosed)
		return
	..()
	return TRUE

/datum/reagent/abnormality/sanity_gel
	name = "L-Corp SP Plus"
	description = "Restores 3 sanity per cycle. Stops working if overdosed. Overdose threshold: 30 units."
	color = "#6baf65"
	sanity_restore = 3
	overdose_threshold = 30

/datum/reagent/abnormality/sanity_gel/on_mob_life(mob/living/M)
	if(overdosed)
		return
	..()
	return TRUE


/datum/reagent/abnormality/burn_salve
	name = "L-Corp BurnSalve"
	description = "Heals 2 burn damage per cycle, but slightly damages eyes as a side effect. No overdose protection."
	color = "#6baf65"

/datum/reagent/abnormality/burn_salve/on_mob_life(mob/living/M)
	M.adjustFireLoss(-2*REM)
	M.adjustOrganLoss(ORGAN_SLOT_EYES,0.25*REM)
	..()
	return TRUE


/datum/reagent/abnormality/mixed_gel
	name = "L-Corp mixed drink"
	description = "Restores 1 HP and 1 sanity per cycle. Stops working if overdosed. Overdose threshold: 30 units."
	color = "#6baf65"
	health_restore = 1
	sanity_restore = 1
	overdose_threshold = 30

/datum/reagent/abnormality/mixed_gel/on_mob_life(mob/living/M)
	if(overdosed)
		return
	..()
	return TRUE

//mostly hard to get medicines
/datum/reagent/abnormality/healing_fast
	name = "K-Corp regeneration solution"
	description = "Restores 8 HP per cycle. Overdose causes severe cellular damage. Overdose threshold: 10 units."
	metabolization_rate = REAGENTS_METABOLISM
	color = "#6baf65"
	health_restore = 8
	overdose_threshold = 10

/datum/reagent/abnormality/healing_fast/on_mob_life(mob/living/M)
	if(overdosed)
		M.adjustCloneLoss(5, 0)
	..()
	return TRUE

/datum/reagent/abnormality/sanity_fast
	name = "M-Corp powdered moonstone"
	description = "Restores 8 sanity per cycle. Stops working if overdosed. Overdose threshold: 30 units."
	metabolization_rate = REAGENTS_METABOLISM
	color = "#6baf65"
	sanity_restore = 8
	overdose_threshold = 30

/datum/reagent/abnormality/sanity_fast/on_mob_life(mob/living/M)
	if(overdosed)
		return
	..()
	return TRUE

//Weird stuff here
/datum/reagent/antitoxin
	name = "Universal antitoxin"
	description = "Removes 2 toxin damage per cycle. Stops working if overdosed. Overdose threshold: 30 units."
	metabolization_rate = REAGENTS_METABOLISM
	color = "#6baf65"
	overdose_threshold = 30

/datum/reagent/antitoxin/on_mob_life(mob/living/M)
	if(overdosed)
		return
	M.adjustToxLoss(-2*REM, 0)
	..()
	return TRUE

/datum/reagent/abnormality/gene_repair
	name = "Genetic repair solution"
	description = "A rare genetic reparation solution that heals damage to DNA slowly."
	metabolization_rate = 0.1*REAGENTS_METABOLISM
	color = "#6baf65"
	overdose_threshold = 30

/datum/reagent/abnormality/healing_fast/on_mob_life(mob/living/M)
	if(overdosed)
		return
	M.adjustCloneLoss(-0.5, 0)
	..()
	return TRUE

/datum/reagent/purgall
	name = "K-Corp Purge-All"
	description = "Purges all other chemicals from the body at 2 units per cycle. Use to remove harmful or unwanted reagents."
	metabolization_rate = REAGENTS_METABOLISM

/datum/reagent/purgall/on_mob_life(mob/living/M)
	for(var/datum/reagent/R in M.reagents.reagent_list)
		if(R != src)
			M.reagents.remove_reagent(R.type,2)
	..()
	. = 1
