#include extreme\_ex_hudcontroller;

main()
{
	// Need a delay to let the eventcontroller finish the OnPlayerKilled events
	// caused by OnPlayerSpawn when the game is over, otherwise it could destroy
	// the statsboard HUD elements while they are being initialized
	[[level.ex_bclear]]("all", 5);

	level.featureinit = newHudElem();
	level.featureinit.archived = false;
	level.featureinit.horzAlign = "center_safearea";
	level.featureinit.vertAlign = "center_safearea";
	level.featureinit.alignX = "center";
	level.featureinit.alignY = "middle";
	level.featureinit.x = 0;
	level.featureinit.y = -50;
	level.featureinit.alpha = 1;
	level.featureinit.fontscale = 1.3;
	level.featureinit.label = (&"STATSBOARD_TITLE");
	level.featureinit SetText(&"MISC_INITIALIZING");

	if(prepareStats())
	{
		// play music if there is no end music playing
		if(level.ex_statsmusic)
		{
			statsmusic = randomInt(10) + 1;
			musicplay("gom_music_" + statsmusic);
		}

		wait( [[level.ex_fpstime]](3) );
		level.featureinit destroy();

		runStats();
	}
	else level.featureinit destroy();
}

prepareStats()
{
	// Create the statsboard data structure
	level.stats = spawnstruct();
	if(level.ex_stbd_icons) level.stats.maxplayers = 5;
		else level.stats.maxplayers = 6;
	level.stats.players = 0;
	level.stats.maxcategories = 0;
	level.stats.categories = 0;
	level.stats.maxtime = level.ex_stbd_time;
	level.stats.time = level.stats.maxtime;
	level.stats.hasdata = false;
	level.stats.cat = [];

	thread [[level.ex_bclear]]("all",5);
	game["menu_team"] = "";

	// Valid players available?
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		// Only get stats from real players
		player.stats_player = false;
		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionteam != "spectator")
			player.stats_player = true;

		if(player.stats_player) level.stats.players++;
	}

	if(level.stats.players == 0) return false;
	if(level.stats.players > level.stats.maxplayers) level.stats.players = level.stats.maxplayers;

	// Make all players spectators with limited permissions
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || !player.stats_player) continue;

		player.statsicon = player thread getStatsIcon();

		if(level.ex_stbd_se)
		{
			// set player score and efficiency
			if(!isDefined(player.pers["kill"])) player.pers["kill"] = 0;

			if(player.pers["kill"] == 0 || (player.pers["kill"] - player.pers["death"]) <= 0) player.pers["efficiency"] = 0;
				else player.pers["efficiency"] = int( (100 / player.pers["kill"]) * (player.pers["kill"] - player.pers["death"]) );
			if(player.pers["efficiency"] > 100) player.pers["efficiency"] = 0;
		}
	}

	category = 0;
	for(;;)
	{
		category_str = GetCategoryStr(category);
		if(category_str == "") break;
		level.stats.maxcategories++;

		level.stats.cat[category_str] = [];
		level.stats.categories++;

		category_kill_str = GetCategoryKillStr(category);
		category_death_str = GetCategoryDeathStr(category);

		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player) || !player.stats_player) continue;

			if(category_kill_str != "-") kills = player.pers[category_kill_str];
				else kills = 0;
			if(category_death_str != "-") deaths = player.pers[category_death_str];
				else deaths = 0;

			// For whatever reason, kills or deaths is undefined sometimes. Make sure they exist
			if(!isDefined(kills)) kills = 0;
			if(!isDefined(deaths)) deaths = 0;

			if(level.stats.cat[category_str].size < level.stats.maxplayers)
			{
				// Add array element with players's stats
				level.stats.cat[category_str][level.stats.cat[category_str].size] = spawnstruct();
				level.stats.cat[category_str][level.stats.cat[category_str].size-1].player = player;
				level.stats.cat[category_str][level.stats.cat[category_str].size-1].statsicon = player.statsicon;
				level.stats.cat[category_str][level.stats.cat[category_str].size-1].kills = kills;
				level.stats.cat[category_str][level.stats.cat[category_str].size-1].deaths = deaths;

				if(kills || deaths) level.stats.hasdata = true;
			}
			else
			{
				// Array full: check if players's stats are better than stats in array
				for(j = 0; j < level.stats.cat[category_str].size; j++)
				{
					if(category_kill_str != "-")
					{
						// If category manages kills, use those
						if(kills > level.stats.cat[category_str][j].kills)
						{
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].player = player;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].statsicon = player.statsicon;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].kills = kills;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].deaths = deaths;
						}
					}
					else
					{
						// Category does not manage kills, so use deaths instead
						if(deaths > level.stats.cat[category_str][j].deaths)
						{
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].player = player;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].statsicon = player.statsicon;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].kills = kills;
							level.stats.cat[category_str][level.stats.cat[category_str].size-1].deaths = deaths;
						}
					}
				}
			}
			// Sort the scores in this category
			// Do not check on maxplayers, because it will not sort if stats.players < stats.maxplayers
			if(level.stats.cat[category_str].size >= level.stats.players)
				sortScores(category_str, 0, level.stats.cat[category_str].size - 1);
		}

		category++;
	}

	// Dump stats to log
	if(level.ex_stbd_log)
	{
		logprint("STATSBOARD [categories][" + level.stats.categories + "]\n");
		for(i = 0; i < level.stats.maxcategories; i++)
		{
			category_str = GetCategoryStr(i);
			if(isDefined(level.stats.cat[category_str]))
			{
				logprint("STATSBOARD [" + category_str + "][" + level.stats.cat[category_str].size + "]\n");
				for(j = 0; j < level.stats.cat[category_str].size; j++)
				{
					logprint("  [" + category_str + "][" + j + "][" + level.stats.cat[category_str][j].player.name + "][" +
						level.stats.cat[category_str][j].kills + ":" + level.stats.cat[category_str][j].deaths + "]\n");
				}
			}
		}
	}

	// No data - no stats
	if(!level.stats.hasdata) return false;
	return true;
}

runStats()
{
	if(!createLevelHUD())
	{
		logprint("STATSBOARD: error creating HUD elements for Statsboard. Aborting\n");
		deleteLevelHUD();
		return;
	}

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		if(isPlayer(player) && isDefined(player.stats_player)) player thread playerStatsLogic();
	}

	thread levelStatsLogic();
	level waittill("stats_finished");

	if(level.ex_stbd_fade) fadeAllHUD(1);
	deleteAllHUD();
	wait( [[level.ex_fpstime]](2) );
}

newplayerStatsLogic()
{
	self endon("disconnect");
	level endon("stats_done");

	if(!isPlayer(self)) return;
	if(isDefined(self.stats_player)) return;
	self.stats_player = false;

	//logprint("STATSBOARD: launching newplayerStatsLogic for player " + self.name + "\n");

	self setClientCvar("g_scriptMainMenu", "");
	self closeMenu();
	self extreme\_ex_spawn::spawnSpectator();
	self allowSpectateTeam("allies", false);
	self allowSpectateTeam("axis", false);
	self allowSpectateTeam("freelook", false);
	self allowSpectateTeam("none", true);

	self thread playerStatsLogic();
}

playerStatsLogic()
{
	self endon("disconnect");
	level endon("stats_done");

	//logprint("STATSBOARD: launching playerStatsLogic for player " + self.name + "\n");

	if(!createPlayerHUD())
	{
		logprint("STATSBOARD: error creating HUD elements for player " + self.name + ". Aborting playerStatsLogic\n");
		deletePlayerHUD();
		return;
	}

	// Initialize player vars
	self.stats_category = 99;
	self nextCategory();

	// Now loop until the thread is signaled to end
	for (;;)
	{
		wait( [[level.ex_fpstime]](0.05) );

		// Attack (FIRE) button for next category
		if(isplayer(self) && self attackButtonPressed() == true)
		{
			self nextCategory();
			while(isPlayer(self) && self attackButtonPressed() == true)
				wait( [[level.ex_fpstime]](0.05) );
		}

		// Melee button for previous category
		if(isplayer(self) && self meleeButtonPressed() == true)
		{
			self previousCategory();
			while(isPlayer(self) && self meleeButtonPressed() == true)
				wait( [[level.ex_fpstime]](0.05) );
		}

		if(isPlayer(self))
		{
			self.sessionstate = "spectator";
			self.spectatorclient = -1;
		}
	}
}

levelStatsLogic()
{
	if(level.ex_stbd_tps)
	{
		level.stats.maxtime = level.stats.categories * level.ex_stbd_tps;
		level.stats.time = level.stats.maxtime;
	}

	for(i = 0; i < level.stats.maxtime; i++)
	{
		wait( [[level.ex_fpstime]](1) );
		players = level.players;
		for(j = 0; j < players.size; j++)
		{
			player = players[j];
			if(!isDefined(player.stats_player))
				player thread newplayerStatsLogic();
		}
		level.stats.time--;
		levelHudSetValue("statsboard_time", level.stats.time);
	}
	level notify("stats_done");

	// If things are needed between the "done" and "finished" signals, first clean HUD
	//if(level.ex_stbd_fade) fadeAllHUD(1);
	//deleteAllHUD();
	wait( [[level.ex_fpstime]](1) );

	level notify("stats_finished");
}

nextCategory()
{
	self endon("disconnect");
	level endon("stats_done");

	oldcategory = self.stats_category;
	self.stats_category++;
	while(true)
	{
		if(self.stats_category >= level.stats.maxcategories) self.stats_category = 0;
		category_str = getCategoryStr(self.stats_category);
		if(isActivatedCategory(self.stats_category) && isDefined(level.stats.cat[category_str]) && hasData(category_str)) break;
		self.stats_category++;
		if(self.stats_category == oldcategory) break; // Complete cycle, so end
	}

	if(self.stats_category != oldcategory)
	{
		self playLocalSound("flagchange");
		if(level.ex_stbd_fade)
		{
			self fadePlayerHUD(0.5);
			wait( [[level.ex_fpstime]](0.5) );
		}
		self showCategory(self.stats_category);
	}
}

previousCategory()
{
	self endon("disconnect");
	level endon("stats_done");

	oldcategory = self.stats_category;
	self.stats_category--;
	while(true)
	{
		if(self.stats_category < 0) self.stats_category = level.stats.maxcategories-1;
		category_str = getCategoryStr(self.stats_category);
		if(isActivatedCategory(self.stats_category) && isDefined(level.stats.cat[category_str]) && hasData(category_str)) break;
		self.stats_category--;
		if(self.stats_category == oldcategory) break; // Complete cycle, so end
	}

	if(self.stats_category != oldcategory)
	{
		self playLocalSound("flagchange");
		if(level.ex_stbd_fade)
		{
			self fadePlayerHUD(0.5);
			wait( [[level.ex_fpstime]](0.5) );
		}
		self showCategory(self.stats_category);
	}
}

showCategory(newcategory)
{
	self endon("disconnect");
	level endon("stats_done");

	category_str = GetCategoryStr(newcategory);
	if(!isDefined(level.stats.cat[category_str]) || category_str == "") return;

	category_locstr = getCategoryLocStr(newcategory);
	playerHudSetLabel(self.pstatshud_head[0], category_locstr);
	playerHudSetAlpha(self.pstatshud_head[0], 1);

	category_header = getCategoryHeader(newcategory);
	playerHudSetLabel(self.pstatshud_head[1], category_header);
	playerHudSetAlpha(self.pstatshud_head[1], 1);

	if(level.ex_stbd_icons)
	{
		for(i = 0; i < level.stats.players; i++)
		{
			playerHudSetShader(self.pstatshud_col1[i], level.stats.cat[category_str][i].statsicon, 14,14);
			playerHudSetAlpha(self.pstatshud_col1[i], 1);
		}
	}

	for(i = 0; i < level.stats.players; i++)
	{
		if(isPlayer(level.stats.cat[category_str][i].player) &&
			isDefined(level.stats.cat[category_str][i].player.stats_player) &&
			level.stats.cat[category_str][i].player.stats_player &&
			!isDefined(level.stats.cat[category_str][i].playerleft))
		{
			playerHudSetPlayer(self.pstatshud_col2[i], level.stats.cat[category_str][i].player);
			playerHudSetAlpha(self.pstatshud_col2[i], 1);
		}
		else
		{
			level.stats.cat[category_str][i].playerleft = true;
			playerHudSetText(self.pstatshud_col2[i], &"STATSBOARD_PLAYERLEFT");
			playerHudSetAlpha(self.pstatshud_col2[i], 1);
		}
	}

	category_kill_str = GetCategoryKillStr(newcategory);
	for(i = 0; i < level.stats.players; i++)
	{
		if(category_kill_str != "-")
		{
			playerHudSetValue(self.pstatshud_col3[i], level.stats.cat[category_str][i].kills);
			playerHudSetAlpha(self.pstatshud_col3[i], 1);
		}
		else playerHudSetAlpha(self.pstatshud_col3[i], 0);;
	}

	category_death_str = GetCategoryDeathStr(newcategory);
	for(i = 0; i < level.stats.players; i++)
	{
		if(category_death_str != "-")
		{
			playerHudSetValue(self.pstatshud_col4[i], level.stats.cat[category_str][i].deaths);
			playerHudSetAlpha(self.pstatshud_col4[i], 1);
		}
		else playerHudSetAlpha(self.pstatshud_col4[i], 0);
	}
}

hasData(category_str)
{
	self endon("disconnect");
	level endon("stats_done");

	for(i = 0; i < level.stats.cat[category_str].size; i++)
	{
		if(level.stats.cat[category_str][i].kills != 0 || level.stats.cat[category_str][i].deaths != 0) return true;
		if(i % 10 == 0) wait( [[level.ex_fpstime]](.05) );
	}

	return false;
}

sortScores(category_str, start, max)
{
	temp = spawnstruct();

	i = start;
	while(i < max)
	{
		j = start;
		while(j < (max - i))
		{
			r = compareScores(category_str, j, j + 1);
			if(r == 2)
			{
				temp = level.stats.cat[category_str][j];
				level.stats.cat[category_str][j] = level.stats.cat[category_str][j + 1];
				level.stats.cat[category_str][j + 1] = temp;
			}
			j++;
		}
		i++;
	}

	temp = undefined;
}

compareScores(category_str, s1, s2)
{
	if(category_str == "score" || category_str == "bonus") special = true;
		else special = false;

	k = level.stats.cat[category_str][s1].kills - level.stats.cat[category_str][s2].kills;
	d = level.stats.cat[category_str][s1].deaths - level.stats.cat[category_str][s2].deaths;

	if(k == 0)
	{
		if(d == 0) return 0;
		if(!special)
		{
			if(d > 0) return 2;
				else return 1;
		}
		else
		{
			if(d > 0) return 1;
				else return 2;
		}
	}
	else
	{
		if(k > 0) return 1;
			else return 2;
	}
}

createLevelHUD()
{
	// Create all level HUD elements
	maxLines = level.stats.players + 2;
	//maxLines = level.stats.maxplayers + 2;

	// Background
	hud_index = levelHudCreate("statsboard_back", undefined, 190 + level.ex_stbd_movex, 45, .7, (0,0,0), 1, 100, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return(false);
	levelHudSetShader(hud_index, "white", 260, 75 + (maxLines * 16));

	// Title bar
	hud_index = levelHudCreate("statsboard_titlebar", undefined, 193 + level.ex_stbd_movex, 47, .3, (1,1,1), 1, 101, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return(false);
	levelHudSetShader(hud_index, "white", 255, 21);

	// Separator (top)
	hud_index = levelHudCreate("statsboard_septop", undefined, 193 + level.ex_stbd_movex, 100, .3, (1,1,1), 1, 101, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return(false);
	levelHudSetShader(hud_index, "white", 255, 1);

	// Separator (bottom)
	hud_index = levelHudCreate("statsboard_sepbottom", undefined, 193 + level.ex_stbd_movex, 100 + (maxLines * 16), .3, (1,1,1), 1, 101, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return(false);
	levelHudSetShader(hud_index, "white", 255, 1);

	// Title
	hud_index = levelHudCreate("statsboard_title", undefined, 195 + level.ex_stbd_movex, 50, 1, (1,1,1), 1.4, 102, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return(false);
	levelHudSetLabel(hud_index, &"STATSBOARD_TITLE");

	// How-to instructions
	hud_index = levelHudCreate("statsboard_howto", undefined, 320 + level.ex_stbd_movex, 83 + (maxLines * 16), 1, (1,1,1), 1, 102, "subleft", "subtop", "center", "top", false, false);
	if(hud_index == -1) return(false);
	levelHudSetLabel(hud_index, &"STATSBOARD_HOWTO");

	// Time left
	hud_index = levelHudCreate("statsboard_time", undefined, 195 + level.ex_stbd_movex, 105 + (maxLines * 16), 1, (1,1,1), 1, 102, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return(false);
	levelHudSetLabel(hud_index, &"STATSBOARD_TIMELEFT");
	levelHudSetValue(hud_index, level.ex_stbd_time);

	return(true);
}

createPlayerHUD()
{
	self endon("disconnect");
	level endon("stats_done");

	// Column headers
	if(!isDefined(self.pstatshud_head))
	{
		self.pstatshud_head = [];

		hud_index = playerHudCreate("statsboard_header0", 195 + level.ex_stbd_movex, 80, 1, (1,1,1), 1.2, 103, "subleft", "subtop", "left", "top", false, false);
		if(hud_index == -1) return(false);
		self.pstatshud_head[0] = hud_index;

		hud_index = playerHudCreate("statsboard_header1", 445 + level.ex_stbd_movex, 80, 1, (1,1,1), 1.1, 103, "subleft", "subtop", "right", "middle", false, false);
		if(hud_index == -1) return(false);
		self.pstatshud_head[1] = hud_index;
	}

	// Icon column
	if(level.ex_stbd_icons && !isDefined(self.pstatshud_col1))
	{
		self.pstatshud_col1 = [];

		for(i = 0; i < level.stats.players; i++)
		{
			hud_index = playerHudCreate("statsboard_column1_" + i, 195 + level.ex_stbd_movex, 105 + i * 16, 1, (1,1,1), 1, 103, "subleft", "subtop", "left", "top", false, false);
			if(hud_index == -1) return(false);
			self.pstatshud_col1[i] = hud_index;
		}
		namex = 215;
	}
	else namex = 195;

	// Name column
	if(!isDefined(self.pstatshud_col2))
	{
		self.pstatshud_col2 = [];

		for(i = 0; i < level.stats.players; i++)
		{
			hud_index = playerHudCreate("statsboard_column2_" + i, namex + level.ex_stbd_movex, 105 + i * 16, 1, (1,1,1), 1.2, 103, "subleft", "subtop", "left", "top", false, false);
			if(hud_index == -1) return(false);
			self.pstatshud_col2[i] = hud_index;
		}
	}

	// Stats column 1
	if(!isDefined(self.pstatshud_col3))
	{
		self.pstatshud_col3 = [];

		for(i = 0; i < level.stats.players; i++)
		{
			hud_index = playerHudCreate("statsboard_column3_" + i, 375 + level.ex_stbd_movex, 105 + i * 16, 1, (1,1,1), 1.3, 103, "subleft", "subtop", "left", "top", false, false);
			if(hud_index == -1) return(false);
			self.pstatshud_col3[i] = hud_index;
		}
	}

	// Stats column 2
	if(!isDefined(self.pstatshud_col4))
	{
		self.pstatshud_col4 = [];

		for(i = 0; i < level.stats.players; i++)
		{
			hud_index = playerHudCreate("statsboard_column4" + i, 415 + level.ex_stbd_movex, 105 + i * 16, 1, (1,1,1), 1.3, 103, "subleft", "subtop", "left", "top", false, false);
			if(hud_index == -1) return(false);
			self.pstatshud_col4[i] = hud_index;
		}
	}

	return(true);
}

fadeAllHUD(fadetime)
{
	// Fade all HUD elements
	thread fadeAllPlayerHUD(fadetime);
	thread fadeLevelHUD(fadetime);
	wait( [[level.ex_fpstime]](fadetime) );
}

fadeLevelHUD(fadetime)
{
	levelHudFade("statsboard_time", fadetime, 0, 0);
	levelHudFade("statsboard_howto", fadetime, 0, 0);
	levelHudFade("statsboard_title", fadetime, 0, 0);
	levelHudFade("statsboard_sepbottom", fadetime, 0, 0);
	levelHudFade("statsboard_septop", fadetime, 0, 0);
	levelHudFade("statsboard_titlebar", fadetime, 0, 0);
	levelHudFade("statsboard_back", fadetime, 0, 0);
}

fadeAllPlayerHUD(fadetime)
{
	// Fade all player based HUD elements for all players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		player thread fadePlayerHUD(fadetime);
	}
}

fadePlayerHUD(fadetime)
{
	self endon("disconnect");
	level endon("stats_done");

	// Fade all player based HUD elements for single player (self)
	// We take the paranoid approach to check player existence every single time
	if(isPlayer(self) && isDefined(self.pstatshud_head)) elements = self.pstatshud_head.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_head[i])) playerHudFade(self.pstatshud_head[i], fadetime, 0, 0);

	if(isPlayer(self) && isDefined(self.pstatshud_col1)) elements = self.pstatshud_col1.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_col1[i])) playerHudFade(self.pstatshud_col1[i], fadetime, 0, 0);

	if(isPlayer(self) && isDefined(self.pstatshud_col2)) elements = self.pstatshud_col2.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_col2[i])) playerHudFade(self.pstatshud_col2[i], fadetime, 0, 0);

	if(isPlayer(self) && isDefined(self.pstatshud_col3)) elements = self.pstatshud_col3.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_col3[i])) playerHudFade(self.pstatshud_col3[i], fadetime, 0, 0);

	if(isPlayer(self) && isDefined(self.pstatshud_col4)) elements = self.pstatshud_col4.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_col4[i])) playerHudFade(self.pstatshud_col4[i], fadetime, 0, 0);
}

deleteAllHUD()
{
	// Destroy all player based HUD elements for all players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		player thread deletePlayerHUD();
	}

	// Destroy all level HUD elements
	deleteLevelHUD();
}

deleteLevelHUD()
{
	levelHudDestroy("statsboard_time");
	levelHudDestroy("statsboard_howto");
	levelHudDestroy("statsboard_title");
	levelHudDestroy("statsboard_sepbottom");
	levelHudDestroy("statsboard_septop");
	levelHudDestroy("statsboard_titlebar");
	levelHudDestroy("statsboard_back");
}

deletePlayerHUD()
{
	self endon("disconnect");
	level endon("stats_done");

	// Destroy all player based HUD elements for a single player
	// We take the paranoid approach to check player existence every single time
	if(isPlayer(self) && isDefined(self.pstatshud_head)) elements = self.pstatshud_head.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_head[i])) playerHudDestroy(self.pstatshud_head[i]);

	self.pstatshud_head = undefined;

	if(isPlayer(self) && isDefined(self.pstatshud_col1)) elements = self.pstatshud_col1.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_col1[i])) playerHudDestroy(self.pstatshud_col1[i]);

	self.pstatshud_col1 = undefined;

	if(isPlayer(self) && isDefined(self.pstatshud_col2)) elements = self.pstatshud_col2.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_col2[i])) playerHudDestroy(self.pstatshud_col2[i]);

	self.pstatshud_col2 = undefined;

	if(isPlayer(self) && isDefined(self.pstatshud_col3)) elements = self.pstatshud_col3.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_col3[i])) playerHudDestroy(self.pstatshud_col3[i]);

	self.pstatshud_col3 = undefined;

	if(isPlayer(self) && isDefined(self.pstatshud_col4)) elements = self.pstatshud_col4.size;
		else elements = 0;
	for(i = 0; i < elements; i++)
		if(isPlayer(self) && isDefined(self.pstatshud_col4[i])) playerHudDestroy(self.pstatshud_col4[i]);

	self.pstatshud_col4 = undefined;
}

getStatsIcon()
{
	self endon("disconnect");
	level endon("stats_done");

	if(self.pers["team"] == "allies") statsicon = game["hudicon_allies"];
		else statsicon = game["hudicon_axis"];

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		if(level.ex_classes && level.ex_classes_hudicons && isDefined(self.pers["class"]))
		{
			switch(self.pers["class"])
			{
				case 1: return(game["hudicon_assault"]);
				case 2: return(game["hudicon_recon"]);
				case 3: return(game["hudicon_engineer"]);
				case 4: return(game["hudicon_support"]);
				case 5: return(game["hudicon_comm"]);
			}
		}
		else if(level.ex_ranksystem && level.ex_rank_hudicons && isDefined(self.pers["rank"]))
		{
			switch(self.pers["rank"])
			{
				case 0: return(game["hudicon_rank0"]);
				case 1: return(game["hudicon_rank1"]);
				case 2: return(game["hudicon_rank2"]);
				case 3: return(game["hudicon_rank3"]);
				case 4: return(game["hudicon_rank4"]);
				case 5: return(game["hudicon_rank5"]);
				case 6: return(game["hudicon_rank6"]);
				case 7: return(game["hudicon_rank7"]);
			}
		}
	}

	return(statsicon);
}

isActivatedCategory(category)
{
	// score, efficiency and bonus points belong to ex_stbd_se; others to ex_stbd_kd
	activated = false;
	if( (level.ex_stbd_kd && category >= 3) || (level.ex_stbd_se && category < 3) ) activated = true;

	return activated;
}

getCategoryStr(category)
{
	// Categories
	switch(category)
	{
		case  0: return "score";
		case  1: return "flag";
		case  2: return "bonus";
		case  3: return "killsdeaths";
		case  4: return "grenades";
		case  5: return "tripwires";
		case  6: return "headshots";
		case  7: return "bashes";
		case  8: return "snipers";
		case  9: return "knives";
		case 10: return "mortars";
		case 11: return "artillery";
		case 12: return "airstrikes";
		case 13: return "napalm";
		case 14: return "panzers";
		case 15: return "spawn";
		case 16: return "landmines";
		case 17: return "firenades";
		case 18: return "gasnades";
		case 19: return "flamethrowers";
		case 20: return "satchelcharges";
		case 21: return "gunship";
		case 22: return "spam";
		case 23: return "team";
		case 24: return "falling";
		case 25: return "minefield";
		case 26: return "suicide";
		default: return "";
	}
}

getCategoryKillStr(category)
{
	// Kills
	switch(category)
	{
		case  0: return "score";
		case  1: return "flagcap";
		case  2: return "-";
		case  3: return "kill";
		case  4: return "grenadekill";
		case  5: return "tripwirekill";
		case  6: return "headshotkill";
		case  7: return "bashkill";
		case  8: return "sniperkill";
		case  9: return "knifekill";
		case 10: return "mortarkill";
		case 11: return "artillerykill";
		case 12: return "airstrikekill";
		case 13: return "napalmkill";
		case 14: return "panzerkill";
		case 15: return "spawnkill";
		case 16: return "landminekill";
		case 17: return "firenadekill";
		case 18: return "gasnadekill";
		case 19: return "flamethrowerkill";
		case 20: return "satchelchargekill";
		case 21: return "gunshipkill";
		case 22: return "spamkill";
		case 23: return "teamkill";
		case 24: return "-";
		case 25: return "-";
		case 26: return "-";
		default: return "";
	}
}

getCategoryDeathStr(category)
{
	// Deaths
	switch(category)
	{
		case  0: return "efficiency";
		case  1: return "flagret";
		case  2: return "bonus";
		case  3: return "death";
		case  4: return "grenadedeath";
		case  5: return "tripwiredeath";
		case  6: return "headshotdeath";
		case  7: return "bashdeath";
		case  8: return "sniperdeath";
		case  9: return "knifedeath";
		case 10: return "mortardeath";
		case 11: return "artillerydeath";
		case 12: return "airstrikedeath";
		case 13: return "napalmdeath";
		case 14: return "panzerdeath";
		case 15: return "spawndeath";
		case 16: return "landminedeath";
		case 17: return "firenadedeath";
		case 18: return "gasnadedeath";
		case 19: return "flamethrowerdeath";
		case 20: return "satchelchargedeath";
		case 21: return "gunshipdeath";
		case 22: return "-";
		case 23: return "-";
		case 24: return "fallingdeath";
		case 25: return "minefielddeath";
		case 26: return "suicide";
		default: return "";
	}
}

getCategoryLocStr(category)
{
	// Localized strings for categories
	switch(category)
	{
		case  0: return &"STATSBOARD_SCORE_EFFICIENCY";
		case  1: return &"STATSBOARD_FLAGS";
		case  2: return &"STATSBOARD_BONUS";
		case  3: return &"STATSBOARD_KILLS_DEATHS";
		case  4: return &"STATSBOARD_GRENADES";
		case  5: return &"STATSBOARD_TRIPWIRES";
		case  6: return &"STATSBOARD_HEADSHOTS";
		case  7: return &"STATSBOARD_BASHES";
		case  8: return &"STATSBOARD_SNIPERS";
		case  9: return &"STATSBOARD_KNIVES";
		case 10: return &"STATSBOARD_MORTARS";
		case 11: return &"STATSBOARD_ARTILLERY";
		case 12: return &"STATSBOARD_AIRSTRIKES";
		case 13: return &"STATSBOARD_NAPALM";
		case 14: return &"STATSBOARD_PANZERS";
		case 15: return &"STATSBOARD_SPAWN";
		case 16: return &"STATSBOARD_LANDMINES";
		case 17: return &"STATSBOARD_FIRENADES";
		case 18: return &"STATSBOARD_GASNADES";
		case 19: return &"STATSBOARD_FLAMETHROWERS";
		case 20: return &"STATSBOARD_SATCHELCHARGES";
		case 21: return &"STATSBOARD_GUNSHIP";
		case 22: return &"STATSBOARD_SPAM_KILLS";
		case 23: return &"STATSBOARD_TEAM_KILLS";
		case 24: return &"STATSBOARD_FALLING_DEATHS";
		case 25: return &"STATSBOARD_MINEFIELD_DEATHS";
		case 26: return &"STATSBOARD_SUICIDE_DEATHS";
		default: return "";
	}
}

getCategoryHeader(category)
{
	// localized strings for column headers
	switch(category)
	{
		case  0: return &"STATSBOARD_HEADER_SE";
		case  1: return &"STATSBOARD_HEADER_FL";
		case  2: return &"STATSBOARD_HEADER_BP";
		default: return &"STATSBOARD_HEADER_KD";
	}
}
