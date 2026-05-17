-- ============================================================
-- Arui QOL - ResAnnounce Quotes Data

-- ============================================================

noTargetQuotes = {      -- Used when target name is UNKNOWN. No %t placeholder.

    "Looks like someone's taking an unplanned dirt nap.",
    "I'd rez you by name, but the Light only gives me a vague sense of disappointment.",
    "Ressing an anonymous casualty — because every corpse deserves a second chance.",
    "The Light works in mysterious ways... like not telling me who I'm reviving.",
    "Somewhere out there, a corpse just got very lucky.",
    "Unknown target detected. Applying holy resuscitation anyway.",
    "I don't know who you are, but I'm sure you didn't deserve that.",
    "Congratulations, mystery player — you've won a free resurrection!",
    "Even the Spirit Healer doesn't know who you are. Let me fix that.",
    "Plot twist: the corpse gets up.",

}

hunterQuotes = {        -- Used when casting Revive Pet. Contains %t.

    "Get up, %t — the fight's not over and I'm out of treats.",
    "%t, I swear if you die one more time I'm taming a squirrel.",
    "Rise and shine, %t! There's more face-melting to do.",
    "Mend Pet was right there, %t. Right there.",
    "%t, you're supposed to bite THEM, not the ground.",
    "I didn't tame you just to watch you nap, %t!",
    "Back on your paws, %t — we've got places to be.",
    "%t, if you wanted a timeout you could've just asked.",
    "One revived %t, slightly charred but ready to go.",
    "Stop dying, %t, or I'll replace you with a boar.",

}

combatQuotes = {        -- Used when casting Rebirth (Druid). Contains %t.

    "Nature calls, %t — and by that I mean back from the grave.",
    "The earth gives you another chance, %t. Don't waste it.",
    "%t, even the trees are embarrassed for you right now.",
    "Sprouting %t from the soil like a very disappointing turnip.",
    "Rebirth: because %t can't be trusted to stay alive on their own.",
    "I grew this rez specially for you, %t. Organic and free-range.",
    "%t, I'm a druid, not a babysitter — but here we are.",
    "May the roots cradle you gently, %t, because the ground certainly didn't.",
    "The cycle of life continues! %t dies, I rez, %t dies again.",
    "%t, nature abhors a vacuum — and apparently also your survival instincts.",

}

warlockQuotes = {       -- Used when casting Soulstone. Contains %t.

    "%t, I've bound your soul to a rock. You're welcome.",
    "Soulstoning %t — because death is merely a suggestion when you know a warlock.",
    "I saved your soul, %t. I'm keeping the receipt, though.",
    "Here's a soulstone, %t. Try not to need it within the first five minutes.",
    "%t, this soulstone comes with terms and conditions. Mainly: don't die.",
    "One get-out-of-death-free card for %t. Non-transferable.",
    "%t, I've invested a shard in you. Don't make me regret it.",
    "Soulstoning %t so they can die twice and disappoint me twice as fast.",
    "My soulstone on %t is basically a warranty that expires the moment they stand in fire.",
    "Enjoy the second life, %t — I'm billing your ghost later.",

}

selfQuotes = {          -- Used when self-rezzing from a Soulstone. No %t.

    "Back from the dead! Again. It's becoming a hobby.",
    "I had a lovely nap. What did I miss?",
    "Death is temporary. My repair bills are permanent.",
    "And I'm back — like a bad penny, but holier.",
    "That was the worst nap ever. No pillows, just dirt.",
    "Rise and shine, me!",
    "Respawning in 3... 2... 1... oh wait, I'm already up.",
    "I've seen the other side. The queue was too long so I came back.",
    "Death couldn't hold me. Nothing can. Especially not my repair bill.",
    "Plot twist: I'm not actually dead. I was just resting my eyes.",

}

engineerQuotes = {      -- Used with Goblin Jumper Cables / Defibrillate. Contains %t.

    "Clear! ...and by clear I mean nobody sue me if this goes wrong, %t.",
    "Zapping %t back to life with 100% goblin engineering and 0% safety standards.",
    "%t, you're about to experience what we in the business call a 'jolt of hope'.",
    "Cross your fingers, %t — these cables have a 50/50 track record.",
    "If this works, %t owes me a beer. If it doesn't... well, they won't know.",
    "Reanimating %t with science! And a little bit of lightning.",
    "One order of fried %t, coming right up! Wait, no — that's the wrong setting.",
    "%t, please don't sue — jumper cables are not FDA approved.",
    "Applying voltage to %t's central philosophy: stay alive next time.",
    "Goblin-certified resurrection for %t! Side effects may include: being alive.",

}

ghoulQuotes = {         -- Used when casting Raise Ally (Death Knight). Contains %t.

    "Rise, %t! You're not done suffering yet.",
    "%t, welcome to undeath — the benefits are terrible but the hours are eternal.",
    "I raise %t from the grave. The Lich King sends his regards.",
    "%t, you're only mostly dead now. Congratulations on the downgrade.",
    "Arise, %t! Your brief vacation in the afterlife is over.",
    "Raising %t as a ghoul. Please don't eat the other party members.",
    "%t, death was too good for you — back to work!",
    "Reanimating %t. Side effects may include an insatiable hunger for brains.",
    "%t, I'm giving you a second chance. Don't make me regret creating you.",
    "Rise, %t! The Scourge demands your attendance.",

}

noghoulQuotes = {       -- Used when casting Raise Dead (Death Knight ghoul pet). No %t.

    "Rise, my faithful ghoul. Today we feast!",
    "Creating an abomination against nature. Please stand by.",
    "One fresh ghoul, coming right up.",
    "Rise and shamble, my friend. There are living things to annoy.",
    "I call upon the dark powers to raise... a very loyal pet.",
    "Behold! My newest minion, freshly dug and ready to serve.",
    "Raising the dead for fun and profit. Mostly fun.",
    "Another ghoul joins the ranks. The neighbors are concerned.",
    "Digging up a companion. He doesn't talk much, but he's a great listener.",
    "Rise, ghoul! Your first task: stop smelling like that.",

}

otherQuotes = {         -- Used when casting Resurrection, Redemption, Ancestral Spirit, Revive. Contains %t.

    "Ressing %t. Please adjust your expectations accordingly.",
    "%t has been disconnected from life. Reconnecting now...",
    "Get up, %t — we're not done wiping yet.",
    "%t, your subscription to Life has been renewed. Payment: one repair bill.",
    "Holy resurrection for %t! Side effects include a strong desire to not do that again.",
    "Patching %t back together with hope and holy light.",
    "%t, I've got good news and bad news. Good: you're alive. Bad: you owe me.",
    "Reviving %t. Please hold, your call is very important to us.",
    "The Light compels %t to get off the floor!",
    "%t, I believe in you. That's a lie, but here's a rez anyway.",
    "Ressing %t — because someone has to carry the extra loot.",
    "%t died as they lived: face-down in the dirt. Let's fix at least one of those.",
    "Attention %t: the floor is not a bed. Please vacate immediately.",
    "One resurrection for %t, hold the dignity.",
    "%t, even the Spirit Healer was getting tired of you.",
    "Casting resurrection on %t. If this were a boss fight, you'd be benched.",
    "%t, welcome back! We kept your spot warm. On the floor. Where you left it.",
    "Ressing %t because apparently standing in fire is a lifestyle choice.",
    "%t, I'm not saying you're bad, but I've ressed you more than our tank.",
    "Holy light, activate! %t is once again vertical and marginally useful.",

}
