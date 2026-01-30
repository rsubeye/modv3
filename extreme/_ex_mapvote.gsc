#include extreme\_ex_hudcontroller;

init()
{
	// Either set it to true or false. DO NOT DISABLE!
	level.ex_maps_log = false;

	// ***** END-GAME VOTING *****
	level.ex_maps = [];

	// Catch-all map. KEEP THIS INDEX 0!
	level.ex_maps[0] = spawnstruct();
	level.ex_maps[0].mapname = "";
	level.ex_maps[0].longname = "Non-localized map name";
	level.ex_maps[0].loclname = &"Non-localized map name";
	level.ex_maps[0].gametype = "dm tdm";

	// Add stock and custom maps
	scriptdata\_ex_votemaps::init();

	// Sort the array using QuickSort
	//dumpArray();
	quickSort(1, level.ex_maps.size - 1);
	//dumpArray();

	// ***** END-GAME VOTING THUMBNAILS *****
	if(level.ex_mapvote && level.ex_mapvote_thumbnails)
	{
		thumbnail = "s000";
		level.ex_maps[0].thumbnail = thumbnail;
		[[level.ex_PrecacheShader]](thumbnail);
		for(i = 1; i < level.ex_maps.size; i++)
		{
			lcmapname = tolower(level.ex_maps[i].mapname);
			thumbnail = scriptdata\_ex_votethumb::getThumbnail(lcmapname);
			level.ex_maps[i].thumbnail = thumbnail;
			if(thumbnail != "s000") [[level.ex_PrecacheShader]](thumbnail);
		}
	}
}

quickSort(lo0, hi0)
{
	temp = spawnstruct();
	pivot = spawnstruct();

	lo = lo0;
	hi = hi0;
	if( lo >= hi ) return;
	if( lo == hi - 1 )
	{
		if( strCompare( level.ex_maps[lo], level.ex_maps[hi] ) == 2 )
		{
			temp = level.ex_maps[lo];
			level.ex_maps[lo] = level.ex_maps[hi];
			level.ex_maps[hi] = temp;
		}
		return;
	}

	ipivot = int( (lo + hi) / 2 );
	pivot = level.ex_maps[ipivot];
	level.ex_maps[ipivot] = level.ex_maps[hi];
	level.ex_maps[hi] = pivot;

	while( lo < hi )
	{
		while( (strCompare(level.ex_maps[lo], pivot) <= 1) && (lo < hi) ) lo++;
		while( (strCompare(pivot, level.ex_maps[hi]) <= 1) && (lo < hi) ) hi--;

		if( lo < hi )
		{
			temp = level.ex_maps[lo];
			level.ex_maps[lo] = level.ex_maps[hi];
			level.ex_maps[hi] = temp;
		}
	}

	level.ex_maps[hi0] = level.ex_maps[hi];
	level.ex_maps[hi] = pivot;

	quickSort( lo0, lo - 1 );
	quickSort( hi + 1, hi0 );

	pivot = undefined;
	temp = undefined;
}

strCompare(str1, str2)
{
	// return values
	// 0 : string1 and string 2 are the same
	// 1 : string1 < string2
	// 2 : string1 > string2

	ascii = " !#$%&'()*+,-.0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[]^_`{}~";

	monostr1 = tolower( extreme\_ex_utils::monotone(str1.longname) );
	monostr2 = tolower( extreme\_ex_utils::monotone(str2.longname) );

	if(monostr1.size <= monostr2.size)
	{
		mode = 1;
		str1 = monostr1;
		str2 = monostr2;
	}
	else
	{
		mode = 2;
		str1 = monostr2;
		str2 = monostr1;
	}

	size1 = str1.size;
	size2 = str2.size;

	for(i = 0; i < size1; i++)
	{
		chr1 = str1[i];
		pos1 = -1;
		for(j = 0; j < ascii.size; j++)
		{
			if(chr1 == ascii[j])
			{
				pos1 = j;
				break;
			}
		}

		chr2 = str2[i];
		pos2 = -1;
		for(j = 0; j < ascii.size; j++)
		{
			if(chr2 == ascii[j])
			{
				pos2 = j;
				break;
			}
		}

		if(mode == 1)
		{
			if(pos1 < pos2) return 1;
			if(pos1 > pos2) return 2;
		}
		else
		{
			if(pos1 < pos2) return 2;
			if(pos1 > pos2) return 1;
		}
	}

	if(size1 == size2) return 0;
	if(mode == 1) return 1;
		else return 2;
}

dumpArray()
{
	for(i = 1; i < level.ex_maps.size; i++)
		logprint("map " + i + ": " + extreme\_ex_utils::monotone(level.ex_maps[i].longname) + " (" + level.ex_maps[i].mapname + ")\n");
}

main()
{
	// Need a delay to let the eventcontroller finish the OnPlayerKilled events
	// caused by OnPlayerSpawn when the game is over, otherwise it could destroy
	// the statsboard HUD elements while they are being initialized
	if(!level.ex_stbd) [[level.ex_bclear]]("all", 5);

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
	level.featureinit.label = (&"MAPVOTE_TITLE");
	level.featureinit SetText(&"MISC_INITIALIZING");

	if(PrepareMapVote())
	{
		if(level.ex_mvmusic)
		{
			mv_music = randomInt(10) + 1;
			musicplay("gom_music_" + mv_music);
		}

		wait( [[level.ex_fpstime]](3) );
		level.featureinit destroy();

		RunMapVote();
	}
	else level.featureinit destroy();
}

PrepareMapVote()
{
	game["menu_team"] = "";

	// Prepare players for vote
	votingplayers = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		player.mv_allowvote = true;

		// No voting for spectators (unless there is only one player)
		if(level.players.size > 1)
		{
			if(isDefined(player.pers["team"]) && player.pers["team"] == "spectator" || player.sessionteam == "spectator")
				if(!isDefined(player.ex_name) || !isDefined(player.ex_clid))
					player.mv_allowvote = false;
		}

		// No voting for testclients (bots)
		if(isDefined(player.pers["isbot"]) && player.pers["isbot"])
			player.mv_allowvote = false;

		// No voting for non-clan players if clan voting enabled, unless it should be ignored
		if(level.ex_clanvoting && !level.ex_mapvoteignclan)
			if(!isDefined(player.ex_name) || !isDefined(player.ex_clid) || !level.ex_clvote[player.ex_clid])
				player.mv_allowvote = false;

		// No voting for this player
		//if(player.name == "PatmanSan") player.mv_allowvote = false;

		if(player.mv_allowvote) votingplayers++;
	}

	// Any players?
	if(votingplayers == 0) return false;

	// Use map rotation (mode 0 - 3) or map list (mode 4 - 7)?
	if(level.ex_mapvotemode < 4)
	{
		// Rotation: get the map rotation queue
		switch(level.ex_mapvotemode)
		{
			case 1: { mv_maprot = extreme\_ex_maprotation::GetRandomMapRotation(); break; }
			case 2: { mv_maprot = extreme\_ex_maprotation::GetPlayerBasedMapRotation(); break; }
			case 3: { mv_maprot = extreme\_ex_maprotation::GetRandomPlayerBasedMapRotation(); break; }
			default: { mv_maprot = extreme\_ex_maprotation::GetPlainMapRotation(); break; }
		}

		// Any maps to begin with?
		if(!isDefined(mv_maprot) || !mv_maprot.size) return false;

		// Prepare final array
		if(level.ex_mapvotemax > mv_maprot.size)
		{
			mv_mapvotemax = mv_maprot.size;
			if(level.ex_mapvotereplay) mv_mapvotemax++;
		}
		else mv_mapvotemax = level.ex_mapvotemax;

		// If map vote memory enabled, load the memory and add the map we just played
		if(level.ex_mapvote_memory) mapvoteMemory(level.ex_currentmap, mv_mapvotemax);

		level.mv_items = [];
		lastgametype = level.ex_currentgt;

		// Do we need the first slot for current map (replay)?
		if(level.ex_mapvotereplay == 2)
		{
			level.mv_items[0]["map"] = level.ex_currentmap;
			level.mv_items[0]["mapname"] = &"MAPVOTE_REPLAY";
			level.mv_items[0]["gametype"] = level.ex_currentgt;
			level.mv_items[0]["gametypename"] = extreme\_ex_maps::getgtstringshort(level.ex_currentgt);
			level.mv_items[0]["votes"] = 0;
		}

		i = level.mv_items.size;

		// Get candidates
		for(j = 0; j < mv_maprot.size; j++)
		{
			// Make sure we know the game type
			if(!isDefined(mv_maprot[j]["gametype"])) mv_maprot[j]["gametype"] = lastgametype;
				else lastgametype = mv_maprot[j]["gametype"];

			// Skip current map and game type combination
			if(mv_maprot[j]["map"] == level.ex_currentmap && mv_maprot[j]["gametype"] == level.ex_currentgt)
			{
				if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maprot[j]["map"] + ". Map has just been played.\n");
				continue;
			}

			// If map vote memory enabled, skip map if it is in memory
			if(level.ex_mapvote_memory && mapvoteInMemory(mv_maprot[j]["map"]))
			{
				if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maprot[j]["map"] + ". Map has been played recently (memory).\n");
				continue;
			}

			// Fill the candidate entry
			level.mv_items[i]["map"] = mv_maprot[j]["map"];
			level.mv_items[i]["mapname"] = extreme\_ex_maps::getmapstring(mv_maprot[j]["map"]);
			level.mv_items[i]["gametype"] = mv_maprot[j]["gametype"];
			level.mv_items[i]["gametypename"] = extreme\_ex_maps::getgtstringshort(mv_maprot[j]["gametype"]);
			level.mv_items[i]["exec"] = mv_maprot[j]["exec"];
			level.mv_items[i]["votes"] = 0;

			i++;
			if(i == mv_mapvotemax) break;
		}

		// Do we need the last slot for current map (replay)?
		if(level.ex_mapvotereplay == 1)
		{
			if(level.mv_items.size)
			{
				if(level.mv_items.size == level.ex_mapvotemax) replayentry = level.mv_items.size - 1;
					else replayentry = level.mv_items.size;
			}
			else replayentry = 0;

			level.mv_items[replayentry]["map"] = level.ex_currentmap;
			level.mv_items[replayentry]["mapname"] = &"MAPVOTE_REPLAY";
			level.mv_items[replayentry]["gametype"] = level.ex_currentgt;
			level.mv_items[replayentry]["gametypename"] = extreme\_ex_maps::getgtstringshort(level.ex_currentgt);
			level.mv_items[replayentry]["votes"] = 0;
		}

		level.mv_itemsmax = level.mv_items.size;
	}
	else
	{
		// Map List: copy maps from list
		mv_maplist = [];
		mv_reverse = 0;

		if(level.ex_mapvotemode == 6)
		{
			mv_reverse = getCvar("ex_mapvotereverse");
			if(mv_reverse != "")
			{
				mv_reverse = getCvarInt("ex_mapvotereverse");
				mv_reverse = !mv_reverse;
			}
			else mv_reverse = 0;
			setCvar("ex_mapvotereverse", mv_reverse);
		}

		if(!mv_reverse) // top-down
		{
			i = 0;
			for(j = 1; j < level.ex_maps.size; j++)
			{
				if(!isDefined(level.ex_maps[j].playsize)) level.ex_maps[j].playsize = "all";

				mv_maplist[i]["map"] = level.ex_maps[j].mapname;
				mv_maplist[i]["mapname"] = level.ex_maps[j].loclname;
				mv_maplist[i]["gametype"] = tolower(level.ex_maps[j].gametype);
				mv_maplist[i]["thumbnail"] = level.ex_maps[j].thumbnail;
				if(isDefined(level.ex_maps[j].wmodes)) mv_maplist[i]["weaponmode"] = level.ex_maps[j].wmodes;
					else mv_maplist[i]["weaponmode"] = "";
				mv_maplist[i]["playsize"] = 0; // all
				if(level.ex_maps[j].playsize == "large") mv_maplist[i]["playsize"] = level.ex_mapsizing_large; // large
					else if(level.ex_maps[j].playsize == "medium") mv_maplist[i]["playsize"] = level.ex_mapsizing_medium; // medium
						else if(level.ex_maps[j].playsize == "small") mv_maplist[i]["playsize"] = 1; // small
				i++;
			}
		}
		else // bottom-up (reverse list)
		{
			i = 0;
			for(j = level.ex_maps.size - 1; j > 0; j--) 
			{
				if(!isDefined(level.ex_maps[j].playsize)) level.ex_maps[j].playsize = "all";

				mv_maplist[i]["map"] = level.ex_maps[j].mapname;
				mv_maplist[i]["mapname"] = level.ex_maps[j].loclname;
				mv_maplist[i]["gametype"] = tolower(level.ex_maps[j].gametype);
				mv_maplist[i]["thumbnail"] = level.ex_maps[j].thumbnail;
				if(isDefined(level.ex_maps[j].wmodes)) mv_maplist[i]["weaponmode"] = level.ex_maps[j].wmodes;
					else mv_maplist[i]["weaponmode"] = "";
				mv_maplist[i]["playsize"] = 0; // all
				if(level.ex_maps[j].playsize == "large") mv_maplist[i]["playsize"] = level.ex_mapsizing_large; // large
					else if(level.ex_maps[j].playsize == "medium") mv_maplist[i]["playsize"] = level.ex_mapsizing_medium; // medium
						else if(level.ex_maps[j].playsize == "small") mv_maplist[i]["playsize"] = 1; // small
				i++;
			}
		}

		// Any maps to begin with?
		if(!isDefined(mv_maplist)) return false;

		// Randomize list if requested (mode 5 and 7)
		if(level.ex_mapvotemode == 5 || level.ex_mapvotemode == 7)
		{
			for(i = 0; i < 20; i++)
			{
				for(j = 0; j < mv_maplist.size; j++)
				{
					r = randomInt(mv_maplist.size);
					element = mv_maplist[j];
					mv_maplist[j] = mv_maplist[r];
					mv_maplist[r] = element;
				}
			}
		}

		// Prepare final array
		if(level.ex_mapvotemax > mv_maplist.size)
		{
			mv_mapvotemax = mv_maplist.size;
			if(level.ex_mapvotereplay) mv_mapvotemax++;
		}
		else mv_mapvotemax = level.ex_mapvotemax;

		// If map vote memory enabled, load the memory and add the map we just played
		if(level.ex_mapvote_memory) mapvoteMemory(level.ex_currentmap, mv_mapvotemax);

		// Get the number of players for player based map filter
		if(level.ex_mapvote_filter_who)
		{
			mv_numplayers = 0;
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(!isPlayer(player)) continue;
				if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator") mv_numplayers++;
			}
		}
		else mv_numplayers = level.players.size;

		if(level.ex_maps_log) logprint("MAPVOTE DEBUG: number of players for mapvote = " + mv_numplayers + " (out of " + level.players.size + " players)\n");
		mv_skipmemcheck = false;
		mv_currentmapix = 0;

		for(run = 1; run <= 3; run++)
		{
			if(level.ex_maps_log) logprint("MAPVOTE DEBUG: map selection run " + run + "\n");
			level.mv_items = [];

			// Do we need the first slot for current map (replay)?
			if(level.ex_mapvotereplay == 2)
			{
				level.mv_items[0]["map"] = level.ex_currentmap;
				level.mv_items[0]["mapname"] = &"MAPVOTE_REPLAY";
				level.mv_items[0]["gametype"] = level.ex_currentgt;
				level.mv_items[0]["gametypename"] = "";
				level.mv_items[0]["thumbnail"] = level.ex_maps[0].thumbnail;
				level.mv_items[0]["votes"] = 0;
			}

			i = level.mv_items.size;

			// Get candidates
			for(j = 0; j < mv_maplist.size; j++)
			{
				// Skip current map
				if(mv_maplist[j]["map"] == level.ex_currentmap)
				{
					if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maplist[j]["map"] + ". Map has just been played.\n");
					mv_currentmapix = j;
					if(level.ex_mapvotereplay == 2)
					{
						level.mv_items[0]["thumbnail"] = mv_maplist[j]["thumbnail"];
						level.mv_items[0]["weaponmode"] = mv_maplist[j]["weaponmode"];
					}
					continue;
				}

				// If map vote memory enabled, skip map if it is in memory
				if(!mv_skipmemcheck && level.ex_mapvote_memory && mapvoteInMemory(mv_maplist[j]["map"]))
				{
					if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maplist[j]["map"] + ". Map has been played recently (memory).\n");
					continue;
				}

				// If map filter enabled, only allow map if minimum number of players available
				if(level.ex_mapvote_filter)
				{
					if(level.ex_mapvote_filter == 2)
					{
						if(mv_maplist[j]["playsize"] == level.ex_mapsizing_large) // Large map
						{
							if(mv_numplayers < mv_maplist[j]["playsize"])
							{
								if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting large map " + mv_maplist[j]["map"] + ". There are " + mv_numplayers + " players. Map requires at least " + mv_maplist[j]["playsize"] + " players.\n");
								continue;
							}
						}
						else if(mv_maplist[j]["playsize"] == level.ex_mapsizing_medium) // Medium map
						{
							if((mv_numplayers < mv_maplist[j]["playsize"]) || (mv_numplayers >= level.ex_mapsizing_large))
							{
								if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting medium map " + mv_maplist[j]["map"] + ". There are " + mv_numplayers + " players. Map requires between " + mv_maplist[j]["playsize"] + " and " + (level.ex_mapsizing_large - 1) + " players.\n");
								continue;
							}
						}
						else if((mv_maplist[j]["playsize"] == 1) && (mv_numplayers >= level.ex_mapsizing_medium)) // Small map
						{
							if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting small map " + mv_maplist[j]["map"] + ". There are " + mv_numplayers + " players. Map requires less than " + level.ex_mapsizing_medium + " players.\n");
							continue;
						}
					}
					else if(mv_numplayers < mv_maplist[j]["playsize"])
					{
						if(level.ex_maps_log) logprint("MAPVOTE DEBUG: omitting map " + mv_maplist[j]["map"] + ". There are " + mv_numplayers + " players. Map requires " + mv_maplist[j]["playsize"] + " players.\n");
						continue;
					}
				}

				// Make sure we have a game type to vote for
				if(mv_maplist[j]["gametype"] == "") mv_maplist[j]["gametype"] = "dm tdm";

				level.mv_items[i]["map"] = mv_maplist[j]["map"];
				level.mv_items[i]["mapname"] = mv_maplist[j]["mapname"];
				level.mv_items[i]["gametype"] = mv_maplist[j]["gametype"];
				level.mv_items[i]["gametypename"] = "";
				level.mv_items[i]["thumbnail"] = mv_maplist[j]["thumbnail"];
				level.mv_items[i]["weaponmode"] = mv_maplist[j]["weaponmode"];
				level.mv_items[i]["votes"] = 0;

				i++;
				if(i == mv_mapvotemax) break;
			}

			// If we have at least two maps we don't need another run
			if(level.mv_items.size > 1) break;

			// No maps after run: (1) size from small to medium, (2) size from medium to large, (3) skip memory check
			if(mv_numplayers < level.ex_mapsizing_medium) mv_numplayers = level.ex_mapsizing_medium;
				else if(mv_numplayers < level.ex_mapsizing_large) mv_numplayers = level.ex_mapsizing_large;
					else mv_skipmemcheck = true;
		}

		// Do we need the last slot for current map (replay)?
		if(level.ex_mapvotereplay == 1)
		{
			if(level.mv_items.size)
			{
				if(level.mv_items.size == level.ex_mapvotemax) replayentry = level.mv_items.size - 1;
					else replayentry = level.mv_items.size;
			}
			else replayentry = 0;

			level.mv_items[replayentry]["map"] = level.ex_currentmap;
			level.mv_items[replayentry]["mapname"] = &"MAPVOTE_REPLAY";
			level.mv_items[replayentry]["gametype"] = level.ex_currentgt;
			level.mv_items[replayentry]["gametypename"] = "";
			level.mv_items[replayentry]["thumbnail"] = mv_maplist[mv_currentmapix]["thumbnail"];
			level.mv_items[replayentry]["weaponmode"] = mv_maplist[mv_currentmapix]["weaponmode"];
			level.mv_items[replayentry]["votes"] = 0;
		}

		level.mv_itemsmax = level.mv_items.size;
	}

	// Any maps left?
	if(level.mv_itemsmax == 0) return false;
	return true;
}

RunMapVote()
{
	level.mv_perpage = 10; // default: 10. max: 10
	level.mv_width = 260; // default: 260. max: 640
	level.mv_originx1 = int((640 - level.mv_width) / 2) + level.ex_mapvote_movex;
	level.mv_originx2 = level.mv_originx1 + level.mv_width; // int( 320 + (level.mv_width / 2));
	level.mv_originxc = int(level.mv_originx1 + (level.mv_width / 2));
	level.mv_heightadj = 0;

	if(level.ex_mapvote_thumbnails)
	{
		level.mv_perpage = 9;
		level.mv_heightadj = 105;
	}

	if(level.ex_mapvotemode < 4) thread VoteLogicRotation();
		else thread VoteLogicList();

	level waittill("VotingComplete");
}

VoteLogicRotation()
{
	// Big brother is watching votes (rotation based)

	// Make sure the vote window has the enough lines for the weapon modes, if
	// weapon mode selection is enabled
	ItemsOnPage = maxItemsOnPage(1);
	if(level.ex_mapvoteweaponmode && level.weaponmodenames.size > ItemsOnPage)
	{
		if(level.weaponmodenames.size > level.mv_perpage) ItemsOnPage = level.mv_perpage;
			else ItemsOnPage = level.weaponmodenames.size;
	}
	// Make sure the vote window is at least 5 lines high for the message
	// for players not allowed to vote to display correctly
	if(ItemsOnPage < 5) ItemsOnPage = 5;
	CreateHud(ItemsOnPage);

	// Start voting threads for players
	level.mv_stage = 1;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		if(isDefined(player.mv_allowvote) && player.mv_allowvote) player thread PlayerVote();
			else player thread PlayerNoVote();
	}

	mv_musicstop = undefined;

	for(; level.ex_mapvotetime >= 0; level.ex_mapvotetime--)
	{
		for(t = 0; t < 10; t++)
		{
			// Reset votes
			for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

			// Recount votes
			// Spawn no-vote thread for new players (joined during vote)
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(!isPlayer(player)) continue;

				if(!isDefined(player.mv_allowvote))
				{
					player.mv_allowvote = false;
					player thread PlayerNoVote();
				}
				else
				{
					if(player.mv_allowvote && player.mv_choice != 0)
						level.mv_items[player.mv_choice - 1]["votes"]++;
				}
			}

			// Update votes on player's HUD, depending on page displayed (scary stuff)
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(!isPlayer(player)) continue;

				if(player.mv_allowvote)
				{
					if(player.mv_flipchoice != 0) isonpage = onPage(player.mv_flipchoice);
						else isonpage = onPage(player.mv_choice);
					for(j = 0; j < maxItemsOnPage(isonpage); j++)
						player playerHudSetValue("mapvote_vote" + j, level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
				}
			}

			if(level.ex_mvmusic && !isDefined(mv_musicstop) && !level.ex_mapvoteweaponmode && level.ex_mapvotetime <= 5)
			{
				musicstop(level.ex_mapvotetime);
				mv_musicstop = true;
			}

			wait( [[level.ex_fpstime]](0.1) );
		}
		// Update time left HUD
		levelHudSetValue("mapvote_timeleft", level.ex_mapvotetime);
	}

	// Signal voting threads to end, and wait for threads to die
	level notify("VotingStageDone");
	wait( [[level.ex_fpstime]](0.2) );

	// Count the votes
	mv_newitemnum = 0;
	mv_topvotes = 0;
	for(i = 0; i < level.mv_itemsmax; i++)
	{
		if(level.mv_items[i]["votes"] > mv_topvotes)
		{
			mv_newitemnum = i;
			mv_topvotes = level.mv_items[i]["votes"];
		}
	}

	// Select the winning map and game type
	map = level.mv_items[mv_newitemnum]["map"];
	mapname = level.mv_items[mv_newitemnum]["mapname"];
	gametype = level.mv_items[mv_newitemnum]["gametype"];
	gametypename = extreme\_ex_maps::getgtstringshort(gametype); // only short strings are precached!
	exec = level.mv_items[mv_newitemnum]["exec"];

	if(level.ex_mapvoteweaponmode)
	{
		// Fade HUD elements
		FadePlayerHUDStage();

		// Destroy the HUD elements which will be recreated for stage 2
		DeletePlayerHudStage();

		level.mv_items = [];
		for(j = 0; j < level.weaponmodenames.size; j++)
		{
			wm_index = level.mv_items.size;
			level.mv_items[wm_index]["weaponmode"] = level.weaponmodenames[j];
			level.mv_items[wm_index]["weaponmodename"] = level.weaponmodes[level.weaponmodenames[j]].loc;
			level.mv_items[wm_index]["votes"] = 0;
		}

		level.mv_itemsmax = level.mv_items.size;

		// Do we have enough weapon modes to vote for?
		if(level.mv_itemsmax > 1)
		{
			// Change title to show map voted for
			levelHudSetLabel("mapvote_title", mapname);
			levelHudSetText("mapvote_title", gametypename);

			level.mv_stage = 3;
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(!isPlayer(player)) continue;

				if(isDefined(player.mv_allowvote) && player.mv_allowvote) player thread PlayerVote();
					else if(!isDefined(player.mv_allowvote)) player thread PlayerNoVote();
			}

			// Weapon mode voting in progress
			for(; level.ex_mapvotetimewm >= 0; level.ex_mapvotetimewm--)
			{
				for(t = 0; t < 10; t++)
				{
					// Reset votes
					for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

					// Recount votes
					// Spawn no-vote thread for new players (joined during vote)
					players = level.players;
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
						if(!isPlayer(player)) continue;

						if(!isDefined(player.mv_allowvote))
						{
							player.mv_allowvote = false;
							player thread PlayerNoVote();
						}
						else
						{
							if(player.mv_allowvote && player.mv_choice != 0)
								level.mv_items[player.mv_choice - 1]["votes"]++;
						}
					}

					// Update votes on player's HUD, depending on page displayed (scary stuff)
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
						if(!isPlayer(player)) continue;

						if(player.mv_allowvote)
						{
							if(player.mv_flipchoice != 0) isonpage = onPage(player.mv_flipchoice);
								else isonpage = onPage(player.mv_choice);
							for(j = 0; j < maxItemsOnPage(isonpage); j++)
								player playerHudSetValue("mapvote_vote" + j, level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
						}
					}

					if(level.ex_mvmusic && !isDefined(mv_musicstop) && level.ex_mapvotetimewm <= 10)
					{
						musicstop(level.ex_mapvotetimewm);
						mv_musicstop = true;
					}

					wait( [[level.ex_fpstime]](0.1) );
				}
				// Update time left HUD
				levelHudSetValue("mapvote_timeleft", level.ex_mapvotetimewm);
			}

			// Signal voting threads to end, and wait for threads to die
			level notify("VotingStageDone");
			wait( [[level.ex_fpstime]](0.2) );
		}
		else if(level.ex_mvmusic) musicstop(5);

		// Count the votes
		mv_newitemnum = 0;
		mv_topvotes = 0;
		for(i = 0; i < level.mv_itemsmax; i++)
		{
			if(level.mv_items[i]["votes"] > mv_topvotes)
			{
				mv_newitemnum = i;
				mv_topvotes = level.mv_items[i]["votes"];
			}
		}

		// Select the winning weapon mode
		weaponmode = level.mv_items[mv_newitemnum]["weaponmode"];
		weaponmodename = level.mv_items[mv_newitemnum]["weaponmodename"];

		// Write to cvar
		setCvar("ex_weaponmode", level.weaponmodes[weaponmode].id);
	}
	else weaponmodename = undefined;

	// Signal voting threads to end, and wait for threads to die
	level notify("VotingDone");
	wait( [[level.ex_fpstime]](0.2) );

	// Fade HUD elements
	FadeHud();

	// Destroy all HUD elements
	DeleteHud();

	// Write to cvars
	if(!isDefined(exec)) exec = "";
		else exec = "exec " + exec;
	setCvar("sv_maprotationcurrent", exec + " gametype " + gametype + " map " + map);

	// Announce winner
	WinnerIs(mapname, gametypename, weaponmodename);

	// Signal the end of map vote
	level notify("VotingComplete");
}

VoteLogicList()
{
	// Big brother is watching votes (list based)

	// Make sure the vote window has the max number of lines, because in list mode
	// we do not know how many lines we need for game type selection
	CreateHud(level.mv_perpage);

	mv_musicstop = undefined;

	if(level.ex_mapvotemode != 7)
	{
		// Start voting threads for players
		level.mv_stage = 1;
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player)) continue;

			if(isDefined(player.mv_allowvote) && player.mv_allowvote) player thread PlayerVote();
				else player thread PlayerNoVote();
		}

		for(; level.ex_mapvotetime >= 0; level.ex_mapvotetime--)
		{
			for(t = 0; t < 10; t++)
			{
				// Reset votes
				for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

				// Recount votes
				// Spawn no-vote thread for new players (joined during vote)
				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(!isPlayer(player)) continue;

					if(!isDefined(player.mv_allowvote))
					{
						player.mv_allowvote = false;
						player thread PlayerNoVote();
					}
					else
					{
						if(player.mv_allowvote && player.mv_choice != 0)
							level.mv_items[player.mv_choice - 1]["votes"]++;
					}
				}

				// Update votes on player's HUD, depending on page displayed (scary stuff)
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(!isPlayer(player)) continue;

					if(player.mv_allowvote)
					{
						if(player.mv_flipchoice != 0) isonpage = onPage(player.mv_flipchoice);
							else isonpage = onPage(player.mv_choice);
						for(j = 0; j < maxItemsOnPage(isonpage); j++)
							player playerHudSetValue("mapvote_vote" + j, level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
					}
				}

				wait( [[level.ex_fpstime]](0.1) );
			}
			// Update time left HUD
			levelHudSetValue("mapvote_timeleft", level.ex_mapvotetime);
		}

		// Signal voting threads to end, and wait for threads to die
		level notify("VotingStageDone");
		wait( [[level.ex_fpstime]](0.2) );

		// Fade HUD elements
		FadePlayerHUDStage();

		// Destroy the HUD elements which will be recreated for stage 2
		DeletePlayerHudStage();
	}

	// Count the votes
	mv_newitemnum = 0;
	mv_topvotes = 0;
	for(i = 0; i < level.mv_itemsmax; i++)
	{
		if(level.mv_items[i]["votes"] > mv_topvotes)
		{
			mv_newitemnum = i;
			mv_topvotes = level.mv_items[i]["votes"];
		}
	}

	// Select the winning map
	map = level.mv_items[mv_newitemnum]["map"];
	mapname = level.mv_items[mv_newitemnum]["mapname"];
	weaponmode = level.mv_items[mv_newitemnum]["weaponmode"];
	if(level.ex_mapvoteweaponmode && weaponmode == "") weaponmode = level.wmodes;
	if(level.ex_mapvote_thumbnails) showWinningMapThumbnail(mv_newitemnum);

	// Prepare for game type voting
	gt_array = strtok(level.mv_items[mv_newitemnum]["gametype"], " ");
	if(!isDefined(gt_array) || !gt_array.size) gt_array[0] = "tdm";

	level.mv_items = undefined;
	gt_index = 0;
	for(j = 0; j < gt_array.size; j++)
	{
		if(level.ex_mapvote_skiplastgt && gt_array[j] == level.ex_currentgt) continue;
		gt_allowed = [[level.ex_drm]]("ex_endgame_vote_allow_" + gt_array[j], 1, 0, 1, "int");

		if(gt_allowed)
		{
			level.mv_items[gt_index]["gametype"] = gt_array[j];
			level.mv_items[gt_index]["gametypename"] = extreme\_ex_maps::getgtstring(gt_array[j]);
			level.mv_items[gt_index]["votes"] = 0;
			gt_index++;
		}
		else if(level.ex_maps_log) logprint("MAPVOTE: Ignoring game type " + gt_array[j] + ". Disabled in mapcontrol.cfg (see ex_endgame_vote_allow_" + gt_array[j] + ").\n");
	}

	// Safety net in case none of the game types were allowed
	if(!isDefined(level.mv_items))
	{
		level.mv_items[gt_index]["gametype"] = "tdm";
		level.mv_items[gt_index]["gametypename"] = extreme\_ex_maps::getgtstring("tdm");
		level.mv_items[gt_index]["votes"] = 0;
	}

	level.mv_itemsmax = level.mv_items.size;

	// Do we have enough game types to vote for?
	if(level.mv_itemsmax > 1)
	{
		// Change title to show map voted for
		levelHudSetLabel("mapvote_title", mapname);

		level.mv_stage = 2;
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player)) continue;

			if(isDefined(player.mv_allowvote) && player.mv_allowvote) player thread PlayerVote();
				else if(!isDefined(player.mv_allowvote)) player thread PlayerNoVote();
		}

		// Game type voting in progress
		for(; level.ex_mapvotetimegt >= 0; level.ex_mapvotetimegt--)
		{
			for(t = 0; t < 10; t++)
			{
				// Reset votes
				for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

				// Recount votes
				// Spawn no-vote thread for new players (joined during vote)
				players = level.players;
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(!isPlayer(player)) continue;

					if(!isDefined(player.mv_allowvote))
					{
						player.mv_allowvote = false;
						player thread PlayerNoVote();
					}
					else
					{
						if(player.mv_allowvote && player.mv_choice != 0)
							level.mv_items[player.mv_choice - 1]["votes"]++;
					}
				}

				// Update votes on player's HUD, depending on page displayed (scary stuff)
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(!isPlayer(player)) continue;

					if(player.mv_allowvote)
					{
						if(player.mv_flipchoice != 0) isonpage = onPage(player.mv_flipchoice);
							else isonpage = onPage(player.mv_choice);
						for(j = 0; j < maxItemsOnPage(isonpage); j++)
							player playerHudSetValue("mapvote_vote" + j, level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
					}
				}

				if(level.ex_mvmusic && !isDefined(mv_musicstop) && !level.ex_mapvoteweaponmode && level.ex_mapvotetimegt <= 10)
				{
					musicstop(level.ex_mapvotetimegt);
					mv_musicstop = true;
				}

				wait( [[level.ex_fpstime]](0.1) );
			}
			// Update time left HUD
			levelHudSetValue("mapvote_timeleft", level.ex_mapvotetimegt);
		}

		// Signal voting threads to end, and wait for threads to die
		level notify("VotingStageDone");
		wait( [[level.ex_fpstime]](0.2) );
	}
	else if(level.ex_mvmusic && !level.ex_mapvoteweaponmode) musicstop(5);

	// Count the votes
	mv_newitemnum = 0;
	mv_topvotes = 0;
	for(i = 0; i < level.mv_itemsmax; i++)
	{
		if(level.mv_items[i]["votes"] > mv_topvotes)
		{
			mv_newitemnum = i;
			mv_topvotes = level.mv_items[i]["votes"];
		}
	}

	// Select the winning game type
	gametype = level.mv_items[mv_newitemnum]["gametype"];
	gametypename = level.mv_items[mv_newitemnum]["gametypename"];

	// Prepare for weapon mode voting
	if(level.ex_mapvoteweaponmode)
	{
		// Fade HUD elements
		FadePlayerHUDStage(true);

		// Destroy the HUD elements which will be recreated for stage 3
		DeletePlayerHudStage(true);

		level.mv_items = [];
		wm_array = strtok(weaponmode, " ");
		if(isDefined(wm_array) && wm_array.size)
		{
			for(i = 0; i < wm_array.size; i++)
			{
				wm_index = level.mv_items.size;
				level.mv_items[wm_index]["weaponmode"] = level.weaponmodenames[int(wm_array[i])]; // now based on integers in wmodes list!
				level.mv_items[wm_index]["weaponmodename"] = level.weaponmodes[level.mv_items[wm_index]["weaponmode"]].loc;
				level.mv_items[wm_index]["votes"] = 0;
			}
		}

		level.mv_itemsmax = level.mv_items.size;

		// Do we have enough weapon modes to vote for?
		if(level.mv_itemsmax > 1)
		{
			// title already shows map voted for
			// can't show short GT string, because they are not precached for modes > 4
			//levelHudSetText("mapvote_title", extreme\_ex_maps::getgtstringshort(gametype));

			level.mv_stage = 3;
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(!isPlayer(player)) continue;

				if(isDefined(player.mv_allowvote) && player.mv_allowvote) player thread PlayerVote();
					else if(!isDefined(player.mv_allowvote)) player thread PlayerNoVote();
			}

			// Weapon mode voting in progress
			for(; level.ex_mapvotetimewm >= 0; level.ex_mapvotetimewm--)
			{
				for(t = 0; t < 10; t++)
				{
					// Reset votes
					for(i = 0; i < level.mv_itemsmax; i++) level.mv_items[i]["votes"] = 0;

					// Recount votes
					// Spawn no-vote thread for new players (joined during vote)
					players = level.players;
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
						if(!isPlayer(player)) continue;

						if(!isDefined(player.mv_allowvote))
						{
							player.mv_allowvote = false;
							player thread PlayerNoVote();
						}
						else
						{
							if(player.mv_allowvote && player.mv_choice != 0)
								level.mv_items[player.mv_choice - 1]["votes"]++;
						}
					}

					// Update votes on player's HUD, depending on page displayed (scary stuff)
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
						if(!isPlayer(player)) continue;

						if(player.mv_allowvote)
						{
							if(player.mv_flipchoice != 0) isonpage = onPage(player.mv_flipchoice);
								else isonpage = onPage(player.mv_choice);
							for(j = 0; j < maxItemsOnPage(isonpage); j++)
								player playerHudSetValue("mapvote_vote" + j, level.mv_items[(isonpage * level.mv_perpage)-level.mv_perpage+j]["votes"]);
						}
					}

					if(level.ex_mvmusic && !isDefined(mv_musicstop) && level.ex_mapvotetimewm <= 10)
					{
						musicstop(level.ex_mapvotetimewm);
						mv_musicstop = true;
					}

					wait( [[level.ex_fpstime]](0.1) );
				}
				// Update time left HUD
				levelHudSetValue("mapvote_timeleft", level.ex_mapvotetimewm);
			}

			// Signal voting threads to end, and wait for threads to die
			level notify("VotingStageDone");
			wait( [[level.ex_fpstime]](0.2) );
		}
		else if(level.ex_mvmusic) musicstop(5);

		// Count the votes
		mv_newitemnum = 0;
		mv_topvotes = 0;
		for(i = 0; i < level.mv_itemsmax; i++)
		{
			if(level.mv_items[i]["votes"] > mv_topvotes)
			{
				mv_newitemnum = i;
				mv_topvotes = level.mv_items[i]["votes"];
			}
		}

		// Select the winning weapon mode
		weaponmode = level.mv_items[mv_newitemnum]["weaponmode"];
		weaponmodename = level.mv_items[mv_newitemnum]["weaponmodename"];

		// Write to cvar
		setCvar("ex_weaponmode", level.weaponmodes[weaponmode].id);
	}
	else weaponmodename = undefined;

	// Signal voting threads to end, and wait for threads to die
	level notify("VotingDone");
	wait( [[level.ex_fpstime]](0.2) );

	// Fade HUD elements
	FadeHud();

	// Destroy all HUD elements
	DeleteHud();

	// Write to cvars
	setCvar("sv_maprotationcurrent", "gametype " + gametype + " map " + map);

	// Announce winner
	WinnerIs(mapname, gametypename, weaponmodename);

	// Signal the end of map vote
	level notify("VotingComplete");
}

PlayerNoVote()
{
	// Thread for players not allowed to vote (all modes)
	// For players joining the vote during VoteLogic(), create HUD elements in this thread
	// not in CreateHUD()
	level endon("VotingDone");

	// Tag player as a non-voting player
	self.mv_allowvote = false;

	// To vertically center HUD elements, find out how many map lines are displayed
	// If less than 5 maps, make sure we have enough space for HUD elements
	minMapLinesOnPage = maxItemsOnPage(1);
	if(minMapLinesOnPage < 5) minMapLinesOnPage = 5;

	// Map vote in progress
	hud_index = self playerHudCreate("mapvote_inprogress", level.mv_originxc, 70 + int(minMapLinesOnPage / 2) * 16, 1, (0,1,0), 1.5, 103, "subleft", "subtop", "center", "middle", false, false);
	if(hud_index == -1) return;
	self playerHudSetLabel(hud_index, &"MAPVOTE_INPROGRESS");

	// You are not allowed to vote
	hud_index = self playerHudCreate("mapvote_notallowed", level.mv_originxc, 95 + int(minMapLinesOnPage / 2) * 16, 1, (1,0,0), 1.3, 103, "subleft", "subtop", "center", "middle", false, false);
	if(hud_index == -1) return;
	self playerHudSetLabel(hud_index, &"MAPVOTE_NOTALLOWED");

	// Please wait...
	hud_index = self playerHudCreate("mapvote_wait", level.mv_originxc, 111 + int(minMapLinesOnPage / 2) * 16, 1, (1,0,0), 1.3, 103, "subleft", "subtop", "center", "middle", false, false);
	if(hud_index == -1) return;
	self playerHudSetLabel(hud_index, &"MAPVOTE_PLEASEWAIT");

	// Now loop until the thread is signaled to end
	for(;;)
	{
		wait( [[level.ex_fpstime]](0.1) );
		if(isPlayer(self))
		{
			self.sessionstate = "spectator";
			self.spectatorclient = -1;
		}
	}
}

PlayerVote()
{
	// Thread for players allowed to vote (map: modes 0 - 6, game type: modes 4 - 7, weapon mode: ex_mapvote_mode_weapons "1")
	level endon("VotingDone");
	level endon("VotingStageDone");

	// Players start without a vote
	self.mv_choice = 0;
	self.mv_flipchoice = 0;

	// Create HUD elements for maps (max 10)
	for(i = 0; i <= maxItemsOnPage(onPage(self.mv_choice))-1; i++)
	{
		hud_index = self playerHudCreate("mapvote_item" + i, level.mv_originx1 + 5, 105 + i * 16, 1, (1,1,1), 1.3, 104, "subleft", "subtop", "left", "middle", false, false);
		if(hud_index == -1) return;

		switch(level.mv_stage)
		{
			case 1:
				self playerHudSetLabel(hud_index, level.mv_items[i]["mapname"]);
				if(level.ex_mapvotemode < 4) self playerHudSetText(hud_index, level.mv_items[i]["gametypename"]);
				break;
			case 2:
				self playerHudSetLabel(hud_index, level.mv_items[i]["gametypename"]);
				break;
			case 3:
				self playerHudSetLabel(hud_index, level.mv_items[i]["weaponmodename"]);
				break;
		}
	}

	// Create HUD elements for voting slots (max 10)
	for(i = 0; i <= maxItemsOnPage(onPage(self.mv_choice))-1; i++)
	{
		hud_index = self playerHudCreate("mapvote_vote" + i, level.mv_originx2 - 20, 105 + i * 16, 1, (1,1,1), 1, 104, "subleft", "subtop", "center", "middle", false, false);
		if(hud_index == -1) return;
		self playerHudSetValue(hud_index, level.mv_items[i]["votes"]);
	}

	// Update page info
	self playerHudSetValue("mapvote_page", 1);

	// Create HUD element for selection bar. It starts invisible.
	// Keep sort number less than maps and votes, so it appears behind them
	hud_index = self playerHudCreate("mapvote_indicator", level.mv_originx1 + 3, 104, 0, (0,0,1), 1, 103, "subleft", "subtop", "left", "middle", false, false);
	if(hud_index == -1) return;
	self playerHudSetShader(hud_index, "white", level.mv_width - 6, 17);

	// Now loop until the thread is signaled to end
	for(;;)
	{
		wait( [[level.ex_fpstime]](0.05) );

		// Attack (FIRE) button to vote
		if(isplayer(self) && self attackButtonPressed() == true)
		{
			nextMap(self);
			while(isPlayer(self) && self attackButtonPressed() == true)
				wait( [[level.ex_fpstime]](0.05) );
		}

		// Melee button to flip pages
		if(isplayer(self) && self meleeButtonPressed() == true)
		{
			if(maxPages() > 1) flipPage(self);
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

nextMap(player)
{
	// Show indicator if first vote
	if(player.mv_choice == 0)
		player playerHudSetAlpha("mapvote_indicator", 0.8);

	// Is this first click after page flipping?
	if(player.mv_flipchoice != 0)
	{
		if(onPage(player.mv_choice) == onPage(player.mv_flipchoice)) player.mv_choice++;
			else player.mv_choice = player.mv_flipchoice;
		player playerHudSetAlpha("mapvote_indicator", 0.8);
		player.mv_flipchoice = 0;

	}
	else player.mv_choice++;

	if(player.mv_choice > level.mv_itemsmax)
		player.mv_choice = 1;

	showChoice(player, player.mv_choice);
}

flipPage(player)
{
	// IMPORTANT: do not change player's choice during page flipping!
	// Hide the indicator
	player playerHudHide("mapvote_indicator");

	// Init temporary choice on first flip
	if(player.mv_flipchoice == 0) player.mv_flipchoice = player.mv_choice;

	// Set next page. Rotate if on last page already
	page = onPage(player.mv_flipchoice);
	page++;
	if(page > maxPages()) page = 1;

	// Calculate temporary choice based on new page.
	player.mv_flipchoice = (page * level.mv_perpage)-(level.mv_perpage-1);

	showChoice(player, player.mv_flipchoice);

	// Show indicator if this is the page with the player's choice on it
	if(player.mv_choice != 0 && (onPage(player.mv_choice) == onPage(player.mv_flipchoice)))
		player playerHudSetAlpha("mapvote_indicator", 0.8);
}

showChoice(player, choice)
{
	// Show players's choice, and auto-flip page if needed
	if(choice == 1) oldpage = maxPages();
		else oldpage = onPage(choice-1);
	newpage = onPage(choice);

	// Is a page flip needed?
	if(newpage != oldpage)
	{
		// Remove old maps and votes
		for(i = 0; i <= maxItemsOnPage(oldpage)-1; i++)
		{
			player playerHudSetAlpha("mapvote_item" + i, 0);
			player playerHudSetAlpha("mapvote_vote" + i, 0);
		}
		// Show new maps and votes
		for(i = 0; i <= maxItemsOnPage(newpage)-1; i++)
		{
			switch(level.mv_stage)
			{
				case 1:
					player playerHudSetLabel("mapvote_item" + i, level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["mapname"]);
					if(level.ex_mapvotemode < 4) player playerHudSetText("mapvote_item" + i, level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["gametypename"]);
					break;
				case 2:
					player playerHudSetLabel("mapvote_item" + i, level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["gametypename"]);
					break;
				case 3:
					player playerHudSetLabel("mapvote_item" + i, level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["weaponmodename"]);
					break;
			}

			player playerHudSetValue("mapvote_vote" + i, level.mv_items[(newpage * level.mv_perpage)-level.mv_perpage+i]["votes"]);
			player playerHudSetAlpha("mapvote_item" + i, 1);
			player playerHudSetAlpha("mapvote_vote" + i, 1);
		}
		// Update page info
		player playerHudSetValue("mapvote_page", newpage);
	}
	// Update indicator, and show selected map if not in page flipping mode
	if(player.mv_flipchoice == 0)
	{
		indpos = (level.mv_perpage - 1) - ((newpage * level.mv_perpage) - choice);
		player playerHudSetXYZ("mapvote_indicator", undefined, 104 + (indpos * 16), undefined);
		player playLocalSound("flagchange");
		if(level.ex_mapvote_thumbnails && level.mv_stage == 1) player showPlayerMapThumbnail(choice);
	}
}

showPlayerMapThumbnail(choice)
{
	thumbnail_width = 256;
	thumbnail_height = 96;

	hud_index = playerHudCreate("mapvote_thumb", level.mv_originxc, 255, 1, (1,1,1), 1, 200, "subleft", "subtop", "center", "top", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, level.mv_items[choice - 1]["thumbnail"], thumbnail_width, thumbnail_height);
}

showWinningMapThumbnail(choice)
{
	thumbnail_width = 256;
	thumbnail_height = 96;

	hud_index = levelHudCreate("mapvote_winnerthumb", undefined, level.mv_originxc, 255, 1, (1,1,1), 1, 200, "subleft", "subtop", "center", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, level.mv_items[choice]["thumbnail"], thumbnail_width, thumbnail_height);
}

moveWinningMapThumbnail(movetime, ypos)
{
	hud_index = levelHudIndex("mapvote_winnerthumb");
	if(hud_index == -1) return;
	levelHudMove(hud_index, movetime, movetime, 320, ypos);
}

WinnerIs(mapname, gametypename, weaponmodename)
{
	// Announce the winning map
	if(level.ex_mapvote_thumbnails)
	{
		if(isDefined(weaponmodename)) moveWinningMapThumbnail(1, 190);
			else moveWinningMapThumbnail(1, 170);
	}

	// And the winner is...
	hud_index = levelHudCreate("mapvote_winneris", undefined, 320, 90, 1, (1,1,1), 1.3, 0, "subleft", "subtop", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetText(hud_index, &"MAPVOTE_WINNER");

	// Winning map name
	hud_index = levelHudCreate("mapvote_winnermap", undefined, 320, 120, 1, (0,1,0), 2, 0, "subleft", "subtop", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetLabel(hud_index, mapname);

	// Winning game type
	hud_index = levelHudCreate("mapvote_winnergt", undefined, 320, 140, 1, (1,1,1), 1.5, 0, "subleft", "subtop", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetLabel(hud_index, gametypename);

	// Winning weapon mode
	if(isDefined(weaponmodename))
	{
		hud_index = levelHudCreate("mapvote_winnerwm", undefined, 320, 160, 1, (1,1,1), 1.5, 0, "subleft", "subtop", "center", "middle", false, false);
		if(hud_index == -1) return;
		levelHudSetLabel(hud_index, weaponmodename);
	}

	wait( [[level.ex_fpstime]](5) );

	hud_index = levelHudIndex("mapvote_winneris");
	if(hud_index != -1) levelHudFade(hud_index, 1, 0, 0);

	hud_index = levelHudIndex("mapvote_winnermap");
	if(hud_index != -1) levelHudFade(hud_index, 1, 0, 0);

	hud_index = levelHudIndex("mapvote_winnergt");
	if(hud_index != -1) levelHudFade(hud_index, 1, 0, 0);
	if(isDefined(level.mv_winner_wm))
	{
		hud_index = levelHudIndex("mapvote_winnerwm");
		if(hud_index != -1) levelHudFade(hud_index, 1, 0, 0);
	}
	if(isDefined(level.mv_thumbnail))
	{
		hud_index = levelHudIndex("mapvote_winnerthumb");
		if(hud_index != -1) levelHudFade(hud_index, 1, 0, 0);
	}

	wait( [[level.ex_fpstime]](1) );

	levelHudDestroy("mapvote_winnerthumb");
	levelHudDestroy("mapvote_winneris");
	levelHudDestroy("mapvote_winnermap");
	levelHudDestroy("mapvote_winnergt");
	levelHudDestroy("mapvote_winnerwm");
}

CreateHud(ItemsOnPage)
{
	// Create basic HUD elements

	// Background
	hud_index = levelHudCreate("mapvote_back", undefined, level.mv_originx1, 45, 0.7, (0,0,0), 1, 100, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", level.mv_width, 85 + level.mv_heightadj + ItemsOnPage * 16);

	// Title bar
	hud_index = levelHudCreate("mapvote_titlebar", undefined, level.mv_originx1 + 3, 47, 0.3, (1,1,1), 1, 101, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", level.mv_width - 5, 21);

	// Separator (bottom line)
	hud_index = levelHudCreate("mapvote_bottomline", undefined, level.mv_originx1 + 3, 110 + level.mv_heightadj + ItemsOnPage * 16, 0.3, (1,1,1), 1, 101, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", level.mv_width - 5, 1);
	
	// Time left
	hud_index = levelHudCreate("mapvote_timeleft", undefined, level.mv_originx1 + 5, 115 + level.mv_heightadj + ItemsOnPage * 16, 1, (1,1,1), 1, 102, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetLabel(hud_index, &"MAPVOTE_TIMELEFT");
	levelHudSetValue(hud_index, level.ex_mapvotetime);

	// Title
	hud_index = levelHudCreate("mapvote_title", undefined, level.mv_originx1 + 5, 50, 1, (1,1,1), 1.3, 102, "subleft", "subtop", "left", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetLabel(hud_index, &"MAPVOTE_TITLE");

	// Create additional info ONLY for players allowed to vote
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		// Catch players joining the map vote just now (do not allow them to vote)
		if(!isDefined(player.mv_allowvote)) player.mv_allowvote = false;

		if(player.mv_allowvote)
		{
			// Votes column header
			hud_index = player playerHudCreate("mapvote_headers", level.mv_originx2 - 5, 90, 1, (1,1,1), 1, 102, "subleft", "subtop", "right", "middle", false, false);
			if(hud_index == -1) return;
			player playerHudSetLabel(hud_index, &"MAPVOTE_HEADERS");

			// How-to instructions
			hud_index = player playerHudCreate("mapvote_howto", level.mv_originxc, 80, 1, (1,1,1), 1, 102, "subleft", "subtop", "center", "middle", false, false);
			if(hud_index == -1) return;
			player playerHudSetLabel(hud_index, &"MAPVOTE_HOWTO");

			// Page info
			hud_index = player playerHudCreate("mapvote_page", level.mv_originx2 - 5, 115 + level.mv_heightadj + ItemsOnPage * 16, 1, (1,1,1), 1, 102, "subleft", "subtop", "right", "top", false, false);
			if(hud_index == -1) return;
			player playerHudSetLabel(hud_index, &"MAPVOTE_PAGE");
			player playerHudSetValue(hud_index, 1);
		}
	}
}

FadePlayerHudStage(keepthumb)
{
	if(!isDefined(keepthumb)) keepthumb = false;

	// Fade all player-based HUD elements
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		if(isDefined(player.mv_allowvote))
		{
			if(player.mv_allowvote)
			{
				// For players allowed to vote
				if(!keepthumb) player playerHudFade("mapvote_thumb", 1, 0, 0);

				for(j = 0; j < maxItemsOnPage(1); j++)
					player playerHudFade("mapvote_vote" + j, 1, 0, 0);

				for(j = 0; j < maxItemsOnPage(1); j++)
					player playerHudFade("mapvote_item" + j, 1, 0, 0);

				player playerHudFade("mapvote_indicator", 1, 0, 0);
			}
		}
	}
	
	wait( [[level.ex_fpstime]](1) );
}

FadeHud()
{
	// Fade all player-based HUD elements
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		if(isDefined(player.mv_allowvote))
		{
			if(player.mv_allowvote)
			{
				// For players allowed to vote
				for(j = 0; j < maxItemsOnPage(1); j++)
					player playerHudFade("mapvote_vote" + j, 1, 0, 0);

				for(j = 0; j < maxItemsOnPage(1); j++)
					player playerHudFade("mapvote_item" + j, 1, 0, 0);

				player playerHudFade("mapvote_indicator", 1, 0, 0);
				player playerHudFade("mapvote_page", 1, 0, 0);
				player playerHudFade("mapvote_howto", 1, 0, 0);
				player playerHudFade("mapvote_header", 1, 0, 0);
			}
			else
			{
				// For players not allowed to vote
				player playerHudFade("mapvote_inprogress", 1, 0, 0);
				player playerHudFade("mapvote_notallowed", 1, 0, 0);
				player playerHudFade("mapvote_wait", 1, 0, 0);
			}
		}
	}

	// Fade all level-based HUD elements
	levelHudFade("mapvote_timeleft", 1, 0, 0);
	levelHudFade("mapvote_bottomline", 1, 0, 0);
	levelHudFade("mapvote_title", 1, 0, 0);
	levelHudFade("mapvote_titlebar", 1, 0, 0);
	levelHudFade("mapvote_back", 1, 0, 0);
	
	wait( [[level.ex_fpstime]](1) );
}

DeletePlayerHudStage(keepthumb)
{
	if(!isDefined(keepthumb)) keepthumb = false;

	// Destroy all player-based HUD elements for maps
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		if(isDefined(player.mv_allowvote))
		{
			if(player.mv_allowvote)
			{
				// For players allowed to vote
				if(!keepthumb) player playerHudDestroy("mapvote_thumb");

				for(j = 0; j < maxItemsOnPage(1); j++)
					player playerHudDestroy("mapvote_vote" + j);

				for(j = 0; j < maxItemsOnPage(1); j++)
					player playerHudDestroy("mapvote_item" + j);

				player playerHudDestroy("mapvote_indicator");
			}
		}
	}
}

DeleteHud()
{
	// Destroy all player-based HUD elements
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;

		if(isDefined(player.mv_allowvote))
		{
			if(player.mv_allowvote)
			{
				// For players allowed to vote
				if(isDefined(player.mv_thumbnail)) player.mv_thumbnail destroy();

				for(j = 0; j < maxItemsOnPage(1); j++)
					player playerHudDestroy("mapvote_vote" + j);

				for(j = 0; j < maxItemsOnPage(1); j++)
					player playerHudDestroy("mapvote_item" + j);

				player playerHudDestroy("mapvote_indicator");
				player playerHudDestroy("mapvote_page");
				player playerHudDestroy("mapvote_howto");
				player playerHudDestroy("mapvote_headers");
			}
			else
			{
				// For players not allowed to vote
				player playerHudDestroy("mapvote_inprogress");
				player playerHudDestroy("mapvote_notallowed");
				player playerHudDestroy("mapvote_wait");
			}
		}
	}

	// Destroy all level-based HUD elements
	levelHudDestroy("mapvote_timeleft");
	levelHudDestroy("mapvote_bottomline");
	levelHudDestroy("mapvote_title");
	levelHudDestroy("mapvote_titlebar");
	levelHudDestroy("mapvote_back");
}

maxPages()
{
	// Calculate the number of pages available
	pages = int((level.mv_itemsmax + (level.mv_perpage - 1)) / level.mv_perpage);
	return pages;
}

onPage(choice)
{
	// Calculate which page the player is on
	if(choice != 0)
	{
		page = int((choice + (level.mv_perpage - 1)) / level.mv_perpage);
		if(page > maxPages()) page = 1;
	}
	else page = 1;
	return page;
}

maxItemsOnPage(page)
{
	// Calculate number of items on page
	items = level.mv_itemsmax;
	itemsonpage = 0;
	for(i = 1; i <= page; i++)
	{
		if(items >= level.mv_perpage)
		{
			itemsonpage = level.mv_perpage;
			items = items - level.mv_perpage;
		}
		else
		{
			if(items != 0)
			{
				itemsonpage = items;
				items = 0;
			}
			else itemsonpage = 0;
		}
	}
	return itemsonpage;
}

mapvoteMemory(mapname, maxmaps)
{
	level.ex_mapmemory = [];

	// limit the map vote memory to two-third of the maps available for voting (before filtering)
	maxtwothird = int( (maxmaps / 3) * 2);
	if(maxtwothird < 2) maxtwothird = 2;
	if(level.ex_mapvote_memory_max > maxtwothird) level.ex_mapvote_memory_max = maxtwothird;

	mapvoteLoadMemory();
	mapvoteAddMemory(mapname);
	mapvoteSaveMemory();

	if(level.ex_maps_log)
	{
		maps_in_memory = "";
		for(i = 0; i < level.ex_mapmemory.size; i++)
		{
			maps_in_memory += level.ex_mapmemory[i] + " ";
			if(i == level.ex_mapvote_memory_max - 1) maps_in_memory += "| ";
		}
		logprint("MAPVOTE DEBUG: maps in memory, including last map played. The | character marks the max for the current rotation:\n");
		logprint("MAPVOTE DEBUG: memory [ " + maps_in_memory + "]\n");
	}
}

mapvoteLoadMemory()
{
	filename = "memory/_ex_mapvote";
	filehandle = openfile(filename, "read");
	if(filehandle != -1)
	{
		farg = freadln(filehandle);
		if(farg > 0)
		{
			memory = fgetarg(filehandle, 0);
			array = strtok(memory, " ");
			if(array.size > 1)
			{
				fileid = array[0];
				if(fileid == "mapvote")
				{
					arrayend = array.size - 1;
					if(arrayend > 50) arrayend = 50;

					for(i = 0; i < arrayend; i++)
						level.ex_mapmemory[i] = array[i+1];
				}
			}
		}
		closefile(filehandle);
	}
}

mapvoteAddMemory(mapname)
{
	startentry = level.ex_mapmemory.size;
	if(startentry >= level.ex_mapvote_memory_max) startentry = level.ex_mapvote_memory_max - 1;

	for(i = startentry; i > 0; i--)
		level.ex_mapmemory[i] = level.ex_mapmemory[i-1];

	level.ex_mapmemory[0] = tolower(mapname);
}

mapvoteSaveMemory()
{
	filename = "memory/_ex_mapvote";
	filehandle = openfile(filename, "write");
	if(filehandle != -1)
	{
		memory = "mapvote ";
		for(i = 0; i < level.ex_mapmemory.size; i++)
			memory += level.ex_mapmemory[i] + " ";

		fprintln(filehandle, memory);
		closefile(filehandle);
	}
}

mapvoteInMemory(mapname)
{
	lcmapname = tolower(mapname);

	// if number of maps in memory exceeds the memory limit, only check lastest additions
	searchend = level.ex_mapmemory.size;
	if(searchend > level.ex_mapvote_memory_max) searchend = level.ex_mapvote_memory_max;

	for(i = 0; i < searchend; i++)
		if(level.ex_mapmemory[i] == lcmapname) return true;

	return false;
}
