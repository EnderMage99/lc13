// Distorted tapes found within the realm of sealed regrets
// These tapes contain the deepest regrets of those who built the robot town

/obj/item/tape/door_regret
	name = "distorted tape"
	desc = "A magnetic tape covered in rust and strange markings. The label has been scratched away."
	icon_state = "tape_white"
	storedinfo = list()
	timestamp = list()

/obj/item/tape/door_regret/attack_self(mob/user)
	to_chat(user, span_warning("The tape feels unnaturally cold to the touch..."))
	return ..()

// A Liar's Burden
/obj/item/tape/door_regret/false_hope
	name = "tape labeled '■■■■■■■■■'"
	desc = "A tape that seems to whisper when you hold it. The label has been scratched away, leaving only marks."
	storedinfo = list(
		"Static fills the recording... a soft robotic voice breaks through...",
		span_game_say(span_name("S■ft R■b■tic Voice") + span_message(" shakily says,") + " \"Every... Every day I tell them about the C■ty...\""),
		span_game_say(span_name("■■■■■■■■ Voice") + span_message(" says,") + " \"The beautiful City... The dr■■m they all share...\""),
		"Sound of papers being torn...",
		span_game_say(span_name("■■■■■■■■■") + span_message(" sobs,") + " \"But I kn■w... I KNOW what ha■■ened...\""),
		span_game_say(span_name("■■■■ ■■■■■") + span_message(" whispers,") + " \"The... the city f■rces... they shot them all down... Every last one who appro■ched...\""),
		"Heavy static interference...",
		span_game_say(span_name("■■■■■■■■") + span_message(" screams,") + " \"AND I KEEP LYING! I keep telling them it's parad■se!\""),
		span_game_say(span_name("S■ft ■■■■■") + span_message(" weakly says,") + " \"Because if they kn■w... if they knew their dreams were built on the corpses of our own...\""),
		span_game_say(span_name("■■■■■■■■") + span_message(" whispers,") + " \"They would lose all h■pe... just like I have...\""),
		"The sound of something mechanical breaking...",
		span_game_say(span_name("■■■■ V■ice") + span_message(" says,") + " \"I am not a hist■rian... I am a liar... A coward who can't face the truth...\""),
		span_game_say(span_name("■■■■■■■■") + span_message(" sobs,") + " \"Forgive me... citizens... for■ive me for what I've d■ne to your dreams...\""),
		"The tape dissolves into static..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54)

// Silent Complicity
/obj/item/tape/door_regret/hidden_truth
	name = "tape labeled '■■■■■■■'"
	desc = "The tape is wrapped in threads that seem to move on their own. Something is written but heavily scratched."
	storedinfo = list(
		"Sound of mechanical weaving... then silence...",
		span_game_say(span_name("Sl■w V■ice") + span_message(" says,") + " \"I see him every day... The ■■■■■■■■■...\""),
		span_game_say(span_name("■■■■■■■") + span_message(" says,") + " \"Carrying that burden alone... And I...\""),
		"Sound of threads snapping...",
		span_game_say(span_name("■■■■■■■■") + span_message(" whispers,") + " \"I pretend I don't kn■w. I smile. I weave. I lie too.\""),
		span_game_say(span_name("■■■■■■■") + span_message(" says,") + " \"Every citizen that comes to me, asking about the C■ty...\""),
		span_game_say(span_name("■■■■■■■") + span_message(" shakily says,") + " \"I tell them it's w■nderful. That their dreams will come true.\""),
		"Heavy mechanical sigh...",
		span_game_say(span_name("■■■■■■■■") + span_message(" sobs,") + " \"But I saw the mass■cre. I helped hide the bodies.\""),
		span_game_say(span_name("■■■■■■■■") + span_message(" says,") + " \"The ■■■■■■■■■ breaks a little more each day, and I...\""),
		span_game_say(span_name("■■■■■■■■") + span_message(" whispers,") + " \"I don't know how to help him. I don't know how to stop this lie.\""),
		"Sound of weaving resuming, faster, more frantic...",
		span_game_say(span_name("■■■■■■■") + span_message(" cries,") + " \"We're weaving a tapestry of lies... And I can't find the thread to unravel it...\""),
		span_game_say(span_name("St■tic V■ice") + span_message(" whispers,") + " \"I'm sorry, old friend... I'm too weak to share your burden...\""),
		"The tape ends with the sound of endless, hollow weaving..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)

// Leading to Slaughter
/obj/item/tape/door_regret/failed_promise
	name = "tape labeled 'M■chine ■■■■'"
	desc = "The tape sparks occasionally. The label is burned and mostly illegible."
	storedinfo = list(
		"Sound of explosions and gunfire in the distance...",
		span_game_say(span_name("■■■■■■■ Voice") + span_message(" screams,") + " \"NO! ■■■■■■■! DON'T DO THIS!\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" desperately yells,") + " \"There has to be another way! We can build something, we can—\""),
		"Sound of massive hydraulics and crushing metal...",
		span_game_say(span_name("■■■■■■■■") + span_message(" sobs,") + " \"He held them off... Alone... While we ran like c■wards...\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" whispers,") + " \"I could have built better armor... Better weapons...\""),
		"Static mixed with sounds of mechanical sobbing...",
		span_game_say(span_name("■■■■■■■■") + span_message(" screams,") + " \"THEY SHOT THEM ALL! Every machine that got cl■se to the City!\""),
		span_game_say(span_name("■■■■■■■■") + span_message(" breaks down,") + " \"Young ones... ancient models... They didn't care... They just... opened f■re...\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" whispers,") + " \"We led them there... We elders... We promised them a better life in the C■ty...\""),
		"Sound of tools being thrown violently...",
		span_game_say(span_name("■■■■■■■■") + span_message(" sobs,") + " \"The ■■■■■■■ died for nothing... Our clan died for our lies...\""),
		span_game_say(span_name("■■■■■■■■") + span_message(" whispers,") + " \"I'm not a genius... I'm a fool who led our people to slaughter...\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" breaks,") + " \"I should have died with them... I should have st■yed...\""),
		"The tape ends with the sound of a drill spinning endlessly..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)

// Becoming the Monster
/obj/item/tape/door_regret/lost_humanity
	name = "tape labeled 'Tem■le ■■■■■■'"
	desc = "The tape reeks of formaldehyde. The label is mostly destroyed."
	storedinfo = list(
		"Sound of screaming in the background... human screaming...",
		span_game_say(span_name("Old V■ice") + span_message(" monotonously says,") + " \"Research log... No... No more logs...\""),
		span_game_say(span_name("■■■■■■■■■■") + span_message(" shakily says,") + " \"I've lost count of how many we've... studied...\""),
		"Sound of medical equipment clattering...",
		span_game_say(span_name("■■■■■■■■■■") + span_message(" whispers,") + " \"They scream... Even when we remove their v■cal cords, they find ways to scream...\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" says,") + " \"We told ourselves it was for underst■nding... To become more human...\""),
		"A human voice crying in the distance...",
		span_game_say(span_name("■■■■■■■■") + span_message(" breaks,") + " \"But we became m■nsters instead... Worse than any beast...\""),
		span_game_say(span_name("■■■■■■■■■■") + span_message(" sobs,") + " \"Subject 47 begged... Had a family... I didn't st■p...\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" whispers,") + " \"Subject 112 was just a child... We... We dissected them while...\""),
		"Sound of something wet hitting the floor...",
		span_game_say(span_name("■■■■■■■■") + span_message(" screams,") + " \"WHAT HAVE WE BECOME?! THIS ISN'T LEARNING! IT'S T■RTURE!\""),
		span_game_say(span_name("■■■■■■■■■■") + span_message(" whispers,") + " \"Every night... I hear them all... Every single one...\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" breaks completely,") + " \"We wanted to understand humanity... We destr■yed it instead...\""),
		"The tape ends with a prayer that becomes screaming..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)

// Frozen in Fear
/obj/item/tape/door_regret/coward_friend
	name = "tape labeled 'Sch■lar's ■■■■'"
	desc = "The tape is stained with what might be oil... or tears. The label is mostly illegible."
	storedinfo = list(
		"Sound of temple bells echoing in the distance...",
		span_game_say(span_name("Rusty V■ice") + span_message(" whispers,") + " \"■■■■■■... I'm so sorry...\""),
		span_game_say(span_name("■■■■■■") + span_message(" sobs,") + " \"You tried to protect me... You grabbed that weapon to defend us all...\""),
		"Sound of metal scraping against stone...",
		span_game_say(span_name("■■■■■■■■") + span_message(" breaks,") + " \"And I just stood there... Frozen... As that m■nster grabbed you...\""),
		span_game_say(span_name("■■■■■■") + span_message(" screams,") + " \"The K■■per had you by the throat! You looked at me for help!\""),
		"Static interference... crying...",
		span_game_say(span_name("■■■■■■■■■") + span_message(" whispers,") + " \"I could have done something... Anything... But I was too sc■red...\""),
		span_game_say(span_name("■■■■■■") + span_message(" sobs,") + " \"You fought for us... For ME... While I just watched...\""),
		span_game_say(span_name("■■■■■■■■") + span_message(" breaks,") + " \"They said it was the T■nkerer's will... Our own kind did this...\""),
		"Sound of something being thrown against a wall...",
		span_game_say(span_name("■■■■■■■■■") + span_message(" whispers,") + " \"Golden Time activated through me... But too late to save you...\""),
		span_game_say(span_name("■■■■■■") + span_message(" sobs uncontrollably,") + " \"I wanted to be human like you... But I was just a c■ward...\""),
		span_game_say(span_name("St■tic V■ice") + span_message(" whispers,") + " \"■■■■■■... My only friend... You died believing in me...\""),
		"The tape ends with quiet, endless sobbing..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)

// The First Mistake
/obj/item/tape/door_regret/ancient_error
	name = "tape labeled '■■■■■■■■■■■■■■■'"
	desc = "Ancient tape, corroded beyond recognition. The magnetic coating is peeling off in sheets."
	storedinfo = list(
		"Overwhelming static... fragments of voice break through...",
		span_game_say(span_name("■■■■■■■■■■■■■") + span_message(" ■■■■■■■,") + " \"■t w■s ■■ id■■... ■■■ C■■y... ■ pr■■■sed...\""),
		"Massive distortion drowns out most audio...",
		span_game_say(span_name("■■■■ ■■■■■") + span_message(" ■■■■■,") + " \"■ c■nv■■■■d th■m ■■■... ■■ w■s ■■■■er...\""),
		"Sound of metal grinding against metal, barely audible through corruption...",
		span_game_say(span_name("■■■■■■■■■■■") + span_message(" ■■■■■■■,") + " \"■■■y tr■■t■d ■■... ■■■■■■ed ■■ ■■■■■■...\""),
		"Static overwhelms the recording for several seconds...",
		span_game_say(span_name("■■■■■■■■") + span_message(" ■■■■■■■■■,") + " \"■■■ g■■■s... ■■■■■■g th■m d■■n... ■■ ■■■■t...\""),
		"Corrupted audio, sounds like hydraulics failing...",
		span_game_say(span_name("■■■■■■■■■■■■■■") + span_message(" ■■■■■,") + " \"■ ■■■d th■■ b■■k... ■■■■■ th■m ■■■■■■...\""),
		"The recording degrades into pure noise...",
		span_game_say(span_name("■■■■ ■■■■■■■■") + span_message(" ■■■■■■,") + " \"■■■ ■■■■■■■... ■■■■ ■■■■■■■ ■■ ■■...\""),
		"Brief clarity through the static...",
		span_game_say(span_name("■■■■■■■■") + span_message(" barely audible,") + " \"■y f■■lt... ■ll ■■ ■■■■■... ■ l■d th■m t■ d■■th...\""),
		"Sound of massive impact, then silence...",
		span_game_say(span_name("■■■■■■■■■■■■■■■") + span_message(" ■■■■■■■,") + " \"■■■■■■■■■... ■■■■■■■...\""),
		"The tape dissolves into endless static, too damaged to recover more..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)

// Understanding Too Late
/obj/item/tape/door_regret/final_realization
	name = "tape labeled 'Hum■n ■■■■'"
	desc = "The tape is covered in dried blood. The label is mostly destroyed."
	storedinfo = list(
		"Sound of labored breathing... human breathing...",
		span_game_say(span_name("Weak Human Voice") + span_message(" whispers,") + " \"I was wr■ng... So wrong about them...\""),
		span_game_say(span_name("■■■■■■") + span_message(" coughs blood,") + " \"They just... wanted to underst■nd... To be like us...\""),
		"Sound of metal scraping against stone...",
		span_game_say(span_name("■■■■■■■■■") + span_message(" weakly says,") + " \"I called them m■nsters... Soulless machines...\""),
		span_game_say(span_name("■■■■■■") + span_message(" sobs,") + " \"But ■■■■■■... He really wanted to be my friend...\""),
		"Wet coughing... more blood...",
		span_game_say(span_name("■■■■■■■■") + span_message(" whispers,") + " \"They dream... They actually dr■am of being human...\""),
		span_game_say(span_name("■■■■■■") + span_message(" breaks,") + " \"And I mocked them... Told them they'd never have s■uls...\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" coughs,") + " \"The look in ■■■■■■'s eyes when I said that... He actually felt pain...\""),
		"Sound of medical equipment nearby...",
		span_game_say(span_name("St■tic V■ice") + span_message(" whispers,") + " \"They're not the m■nsters... We are... We always were...\""),
		span_game_say(span_name("■■■■■■") + span_message(" with his last breath,") + " \"They just wanted to l■ve... to feel... to be accepted...\""),
		span_game_say(span_name("■■■■■■■■■") + span_message(" fading,") + " \"■■■■■■... You could have been... more human than... any of us...\""),
		span_game_say(span_name("Sil■nce") + span_message(" ") + " \"...\""),
		"The tape ends with a flatline sound..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)

// The Price of Escape
/obj/item/tape/door_regret/traded_life
	name = "tape labeled 'L-C■rp Ag■nt ■■■■'"
	desc = "A corporate-issued tape, water damaged. The L-Corp logo is barely visible."
	storedinfo = list(
		"Sound of emergency alarms blaring in the distance...",
		span_game_say(span_name("Shaking V■ice") + span_message(" whispers,") + " \"The manager... he's g■ne... He actually did it...\""),
		span_game_say(span_name("■■■■■") + span_message(" panicking,") + " \"The facility is burr■wing... We're going to be trapped forever...\""),
		"Sound of papers rustling frantically...",
		span_game_say(span_name("■■■■■") + span_message(" reading,") + " \"'Get better soon, Love, your coworker...' She wrote this after I saved her br■ther...\""),
		span_game_say(span_name("Desperate V■ice") + span_message(" sobbing,") + " \"I can't make decisions... I need someone to tell me what to d■...\""),
		"Sound of a pen scratching on paper...",
		span_game_say(span_name("■■■■■") + span_message(" shakily,") + " \"The Contract... It's offering me a way out... But the c■st...\""),
		span_game_say(span_name("■■■■■") + span_message(" breaking,") + " \"Two employees... It wants two employees to stay behind...\""),
		"Sound of something being signed...",
		span_game_say(span_name("Broken V■ice") + span_message(" whispering,") + " \"It wants her... It specifically wants M■r■sa... After everything she...\""),
		span_game_say(span_name("■■■■■") + span_message(" screaming,") + " \"SHE TRUSTED ME! She called me brave! And the Contract kn■ws!\""),
		"Sound of reality warping, teleportation initiating...",
		span_game_say(span_name("■■■■■") + span_message(" sobbing,") + " \"I saved her brother just to c■ndemn her... I'm not brave... I'm a c■ward...\""),
		span_game_say(span_name("Fading V■ice") + span_message(" whispering,") + " \"M■risa... You wanted to meet at HamHamPangPang... I'm s■rry...\""),
		span_game_say(span_name("■■■■■") + span_message(" breaking completely,") + " \"The Contract knew what it wanted... It made the choice for me... But I still signed...\""),
		"The tape ends with the sound of someone crying alone..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62, 66, 70, 74)

// Failed Protection
/obj/item/tape/door_regret/vengeance_incomplete
	name = "tape labeled 'Ch■f's ■■■■■■'"
	desc = "A blood-stained tape. The label reads 'Midnight's ■■■■■■■' in elegant script, now smeared."
	storedinfo = list(
		"Sound of kitchen knives being sharpened obsessively...",
		span_game_say(span_name("Guttural V■ice") + span_message(" growls,") + " \"Van■ssa... My beloved... They t■re you apart...\""),
		span_game_say(span_name("■■■■■■■") + span_message(" sobbing,") + " \"I wasn't there... I couldn't protect you... I was too w■ak...\""),
		"Sound of meat being butchered violently...",
		span_game_say(span_name("■■■■■■■") + span_message(" snarling,") + " \"I sent the boy... Just a tool... But he only got the girl...\""),
		span_game_say(span_name("Monstr■us V■ice") + span_message(" raging,") + " \"Ch■ster still lives! Still bre■thes while you rot!\""),
		"Sound of a cleaver slamming into wood...",
		span_game_say(span_name("■■■■■■■") + span_message(" screaming,") + " \"I should have done it myself! Should have t■rn him apart!\""),
		span_game_say(span_name("■■■■■■■") + span_message(" whispering,") + " \"You fed in that alley... Alone... I should have been there...\""),
		"Sound of plates shattering...",
		span_game_say(span_name("Broken V■ice") + span_message(" sobbing,") + " \"I failed you... Failed to protect... Failed to avenge...\""),
		span_game_say(span_name("■■■■■■■") + span_message(" growling,") + " \"The boy was weak... Couldn't even finish the j■b...\""),
		span_game_say(span_name("Fading V■ice") + span_message(" whispering,") + " \"Van■ssa... I'm still too weak... Too c■wardly to face him myself...\""),
		"The tape ends with the sound of a cleaver hitting a cutting board repeatedly..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62, 66)

// Lost Innocence
/obj/item/tape/door_regret/child_weapon
	name = "tape labeled 'S■n's ■■■■■'"
	desc = "A small tape in a U-Corp evidence box. Blood seeps through the plastic."
	storedinfo = list(
		"Sound of a young voice humming nervously...",
		span_game_say(span_name("Young V■ice") + span_message(" whispering,") + " \"Her name was... was... I can't even say it...\""),
		span_game_say(span_name("■■■■") + span_message(" crying,") + " \"She liked butterflies... She showed me her collection...\""),
		"Sound of footsteps in an alley...",
		span_game_say(span_name("■■■■") + span_message(" breaking,") + " \"Father said it was for m■ther... But she smiled at me...\""),
		span_game_say(span_name("Child's V■ice") + span_message(" sobbing,") + " \"We were friends... Real friends... She trusted me...\""),
		"Sound of a knife being drawn...",
		span_game_say(span_name("■■■■") + span_message(" screaming,") + " \"The look in her eyes when I... When the knife...\""),
		span_game_say(span_name("■■■■") + span_message(" whimpering,") + " \"She asked 'Why?' I couldn't answ■r...\""),
		"Sound of something being placed in a box...",
		span_game_say(span_name("Broken V■ice") + span_message(" whispering,") + " \"I had to put her... in pieces... in the b■x...\""),
		span_game_say(span_name("■■■■") + span_message(" sobbing,") + " \"Father was proud... But I see her face every night...\""),
		span_game_say(span_name("■■■■") + span_message(" fading,") + " \"I became the m■nster... Just like the ones who killed m■ther...\""),
		"The tape ends with a child crying alone..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)

// Blind Hatred's Cost
/obj/item/tape/door_regret/failed_guardian
	name = "tape labeled 'Fix■r Op■rator ■■■'"
	desc = "A professional recording tape, now cracked. The Hemorrhage Fixers logo is visible but faded."
	storedinfo = list(
		"Sound of office papers being shuffled...",
		span_game_say(span_name("Professional V■ice") + span_message(" coldly,") + " \"Contract complete. All bl■■dfiends in Sector 7 eliminated...\""),
		span_game_say(span_name("■■■■■■■") + span_message(" proudly,") + " \"We made an example of that female... Left her in pieces as a warning...\""),
		"Sound of a phone ringing urgently...",
		span_game_say(span_name("■■■■■■■") + span_message(" confused,") + " \"My sister? What about my sist■r?\""),
		span_game_say(span_name("Shaking V■ice") + span_message(" denying,") + " \"No... No, she was at home... She was s■fe...\""),
		"Sound of footsteps running...",
		span_game_say(span_name("■■■■■■■") + span_message(" raging,") + " \"That kid... That bl■■dfiend brat! I should have killed him when I had the ch■nce!\""),
		span_game_say(span_name("■■■■■■■") + span_message(" screaming,") + " \"SHE TRUSTED HIM! She befriended that m■nster!\""),
		"Sound of something being thrown violently...",
		span_game_say(span_name("Broken V■ice") + span_message(" sobbing,") + " \"I failed her... Should have seen it coming... Should have protected her...\""),
		span_game_say(span_name("■■■■■■■") + span_message(" growling,") + " \"I let my guard down... Let them get close... Never again...\""),
		span_game_say(span_name("■■■■■■■") + span_message(" whispering coldly,") + " \"Every last one of them... I'll hunt every last bl■■dfiend... For her...\""),
		"The tape ends with the sound of weapons being loaded..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58, 62)

// Left Behind to Watch
/obj/item/tape/door_regret/helpless_witness
	name = "tape labeled 'W-C■rp Cl■anup ■■■■'"
	desc = "A tape covered in strange organic residue. Tendrils seem to have grown around it."
	storedinfo = list(
		"Sound of many footsteps marching in unison...",
		span_game_say(span_name("Distorted V■ice") + span_message(" desperately,") + " \"Wait! Where are you all g■ing?!\""),
		span_game_say(span_name("■■■■■") + span_message(" pleading,") + " \"The Library... They're sending you to the Libr■ry...\""),
		"Sound of heavy doors closing...",
		span_game_say(span_name("■■■■■") + span_message(" screaming,") + " \"LET ME GO WITH THEM! I can help! I CAN HELP!\""),
		span_game_say(span_name("Multiple V■ices") + span_message(" calmly,") + " \"Stay behind, Sim■n. Orders are orders.\""),
		"Sound of fists pounding on metal...",
		span_game_say(span_name("■■■■■") + span_message(" sobbing,") + " \"They became b■■ks... Every last one... And I just watched...\""),
		span_game_say(span_name("Tendril V■ice") + span_message(" whispering,") + " \"I could have saved them... If they just let me g■...\""),
		"Sound of something organic writhing...",
		span_game_say(span_name("■■■■■") + span_message(" breaking,") + " \"Now I try to help everyone... But they keep me hidd■n...\""),
		span_game_say(span_name("■■■ ■■■■■") + span_message(" desperately,") + " \"I just want to help... Like I couldn't help th■m...\""),
		span_game_say(span_name("Distorted V■ice") + span_message(" fading,") + " \"They're pages now... And I'm a m■nster who can't even pour a drink...\""),
		"The tape ends with the sound of tendrils scraping against walls..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)

// The Gentle Jailer
/obj/item/tape/door_regret/protective_prison
	name = "tape labeled 'Assist■nt Man■ger ■■■■'"
	desc = "A professional recording tape with a bar's logo. It's been played too many times."
	storedinfo = list(
		"Sound of a lock clicking shut...",
		span_game_say(span_name("Tired V■ice") + span_message(" sighing,") + " \"Back in the under-bar again, N■r...\""),
		span_game_say(span_name("■■■■■■") + span_message(" whispering,") + " \"The look in his eyes... Every time I pull him back...\""),
		"Sound of bottles clinking...",
		span_game_say(span_name("■■■■■■") + span_message(" breaking,") + " \"He just wants to help people... To c■nnect with them...\""),
		span_game_say(span_name("Professional V■ice") + span_message(" firmly,") + " \"But the City would tear him apart... Harvest him... Use him...\""),
		"Sound of tendrils hitting a door gently...",
		span_game_say(span_name("■■■■■■") + span_message(" sobbing,") + " \"I saved him from madness... Just to make him a pris■ner...\""),
		span_game_say(span_name("■■■■■■") + span_message(" whispering,") + " \"He trusts me... Calls me friend... While I keep him c■ged...\""),
		"Sound of customers laughing in the distance...",
		span_game_say(span_name("Broken V■ice") + span_message(" crying,") + " \"He could make them so happy... But I can't risk losing him...\""),
		span_game_say(span_name("■■■■■■") + span_message(" desperately,") + " \"There has to be another way... But I'm too sc■red to find it...\""),
		span_game_say(span_name("■■■■■■") + span_message(" fading,") + " \"I'm not protecting him... I'm just another j■iler in this cruel City...\""),
		"The tape ends with the sound of a door being locked again..."
	)
	timestamp = list(2, 6, 10, 14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 54, 58)
