init()
{
	// WHAT IS THIS FILE:
	// Actually this is a game script, so DO NOT mess it up or it will prevent
	// your server from running! This file is used for the end-game voting system
	// and the map rotation server messages.
	//
	// HOW TO USE THIS FILE:
	// 1. Copy the template for each CUSTOM map you want to add.
	// 2. Uncomment the lines by removing the double slashes.
	// 3. In the "mapname" field, replace the text between quotes with the map's
	//    rotation name (the name you would put in the rotation string).
	//    Do NOT add color codes in this field!
	// 4. In the "longname" and "loclname" fields, replace the text between quotes
	//    with the map's descriptive name. You can add color codes if you like.
	// 5. The "gametype" field is used in map vote mode 4, 5, 6 and 7
	//    For this field, remove all game types the map doesn't support or you
	//    don't want to vote for (if you want "lib", you must add it yourself).
	// 6. The "playsize" field is used in map vote mode 4, 5 and 6
	//    when player based filtering is enabled. It defines the size of the map,
	//    which is linked to the number of players in the server during end-game
	//    voting. The "playsize" field must be "all", "large", "medium" or "small".
	// 7. If you enabled weapon mode voting in the end-of-game voting system, you
	//    can add the optional "weaponmode" field, in which you set the weapon modes
	//    that players can select for this specific map. You MUST set the default
	//    allow list ex_endgame_vote_weaponmode_allow in mapcontrol.cfg for this
	//    to work. If you don't specify the "weaponmode" field, the default allow
	//    list is used.

	// IMPORTANT:
	// - DO NOT ADD STOCK MAPS. They are already in here.
	//   If you don't want stock maps, see mapcontrol.cfg -- ex_stock_maps.
	// - ONLY REPLACE TEXT BETWEEN QUOTES. Otherwise you corrupt the structure.
	// - DO NOT REMOVE THE &-SIGN. It needs to be there.
	// - DO NOT ADD COLOR CODES TO THE GAME TYPES. It will mess up the system.
	// - DO NOT ADD TOO MANY CUSTOM MAPS AT ONCE!
	//   Although 160 maps (including stock maps) is the maximum for the in-game
	//   and end-game voting systems, your server will run out of precached
	//   strings much sooner. The actual limit depends on the feature set you have
	//   enabled, so add a couple of maps at once, and test before adding more.

	// Add stock maps
	if(level.ex_stock_maps)
	{
		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_farmhouse";
		level.ex_maps[level.ex_maps.size-1].longname = "Beltot, France";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Beltot, France";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_brecourt";
		level.ex_maps[level.ex_maps.size-1].longname = "Brecourt, France";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Brecourt, France";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_burgundy";
		level.ex_maps[level.ex_maps.size-1].longname = "Burgundy, France";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Burgundy, France";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_trainstation";
		level.ex_maps[level.ex_maps.size-1].longname = "Caen, France";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Caen, France";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_carentan";
		level.ex_maps[level.ex_maps.size-1].longname = "Carentan, France";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Carentan, France";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_decoy";
		level.ex_maps[level.ex_maps.size-1].longname = "El Alamein, Egypt";
		level.ex_maps[level.ex_maps.size-1].loclname = &"El Alamein, Egypt";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_leningrad";
		level.ex_maps[level.ex_maps.size-1].longname = "Leningrad, Russia";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Leningrad, Russia";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_matmata";
		level.ex_maps[level.ex_maps.size-1].longname = "Matmata, Tunisia";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Matmata, Tunisia";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_downtown";
		level.ex_maps[level.ex_maps.size-1].longname = "Moscow, Russia";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Moscow, Russia";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_harbor";
		level.ex_maps[level.ex_maps.size-1].longname = "Rostov, Russia";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Rostov, Russia";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_dawnville";
		level.ex_maps[level.ex_maps.size-1].longname = "St. Mere Eglise, France";
		level.ex_maps[level.ex_maps.size-1].loclname = &"St. Mere Eglise, France";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_railyard";
		level.ex_maps[level.ex_maps.size-1].longname = "Stalingrad, Russia";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Stalingrad, Russia";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_toujane";
		level.ex_maps[level.ex_maps.size-1].longname = "Toujane, Tunisia";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Toujane, Tunisia";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_breakout";
		level.ex_maps[level.ex_maps.size-1].longname = "Villers-Bocage, France";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Villers-Bocage, France";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";

		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_rhine";
		level.ex_maps[level.ex_maps.size-1].longname = "Wallendar, Germany";
		level.ex_maps[level.ex_maps.size-1].loclname = &"Wallendar, Germany";
		level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";
	}
	// DON'T CHANGE ANYTHING ABOVE THIS LINE
	// (unless you want to restrict game types for stock maps in map vote mode 4/5)


	// Add custom maps
	// TEMPLATE:
	//level.ex_maps[level.ex_maps.size] = spawnstruct();
	//level.ex_maps[level.ex_maps.size-1].mapname  = "mapname";
	//level.ex_maps[level.ex_maps.size-1].longname = "longname";
	//level.ex_maps[level.ex_maps.size-1].loclname = &"longname";
	//level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
	//level.ex_maps[level.ex_maps.size-1].playsize = "all";

	// DON'T CHANGE ANYTHING BELOW THIS LINE
}
