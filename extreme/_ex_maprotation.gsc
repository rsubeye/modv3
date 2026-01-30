
init()
{
	if(!isDefined(game["ex_emptytime"])) game["ex_emptytime"] = 0;
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 60);
}

onRandom(eventID)
{
	level endon("ex_gameover");

	activeplayers = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player))
		{
			if(player.sessionstate == "playing" || player.sessionstate == "dead") activeplayers++;
				else if(level.ex_spectatedead && player.sessionstate == "spectator" && player.sessionteam != "spectator") activeplayers++;
		}
	}

	if(activeplayers >= 1) game["ex_emptytime"] = 0;
		else game["ex_emptytime"]++;

	if(game["ex_emptytime"] < level.ex_rotateifempty) return;
	if(level.mapended || level.ex_gameover) return;

	logprint("ROTATION: server empty for " + level.ex_rotateifempty + " minutes; forcing rotation...\n");
	exitLevel(false);
}

GetPlainMapRotation(include_stacker)
{
	if(!isDefined(include_stacker)) include_stacker = true;
	return GetMapRotation(false, false, include_stacker);
}

GetRandomMapRotation(include_stacker)
{
	if(!isDefined(include_stacker)) include_stacker = true;
	return GetMapRotation(true, false, include_stacker);
}

GetCurrentMapRotation()
{
	return GetMapRotation(false, true, false);
}

GetPlayerBasedMapRotation()
{
	return GetMapRotation(false, false, false);
}

GetRandomPlayerBasedMapRotation()
{
	return GetMapRotation(true, false, false);
}

GetMapRotation(random, current, include_stacker)
{
	maprot = "";

	if(current) maprot = getcvar("sv_maprotationcurrent");

	if(maprot == "")
	{
		if(level.ex_pbrotate || level.ex_mapvotemode == 2 || level.ex_mapvotemode == 3)
		{
			players = level.players;
			if(players.size >= level.ex_mapsizing_large) maprot = getcvar("scr_large_rotation");
				else if(players.size >= level.ex_mapsizing_medium) maprot = getcvar("scr_med_rotation");
					else maprot = getcvar("scr_small_rotation");
		}
		else
		{
			if(include_stacker) maprot = extreme\_ex_maps::reconstructMapRotation();
				else maprot = getcvar("sv_maprotation");
		}
	}

	maps = rotationStringToArray(maprot, random);
	return(maps);
}

rotationStringToArray(maprot, random)
{
	maprot = trim(maprot);
	if(maprot == "") return( [] );

	temparr = strtok( maprot, " ");

	xmaps = [];
	lastexec = undefined;
	lastgt = getcvar("g_gametype");

	for(i = 0; i < temparr.size;)
	{
		switch(temparr[i])
		{
			case "exec":
				if(isDefined(temparr[i+1]))
				{
					if(!isConfig(temparr[i+1]))
					{
						logprint("ROTATION: fixing keyword \"" + temparr[i] + "\" without assignment\n");
						i += 1;
					}
					else
					{
						lastexec = temparr[i+1];
						i += 2;
					}
				}
				break;

			case "gametype":
				if(isDefined(temparr[i+1]))
				{
					if(!isGametype(temparr[i+1]))
					{
						logprint("ROTATION: fixing keyword \"" + temparr[i] + "\" without assignment\n");
						i += 1;
					}
					else
					{
						lastgt = temparr[i+1];
						i += 2;
					}
				}
				break;

			case "map":
				if(isDefined(temparr[i+1]))
				{
					if(isCommand(temparr[i+1]) || isGametype(temparr[i+1]) || isConfig(temparr[i+1]))
					{
						logprint("ROTATION: fixing keyword \"" + temparr[i] + "\" without assignment\n");
						i += 1;
					}
					else
					{
						xmaps[xmaps.size]["exec"] = lastexec;
						xmaps[xmaps.size-1]["gametype"] = lastgt;
						xmaps[xmaps.size-1]["map"] = temparr[i+1];

						if(!random)
						{
							lastexec = undefined;
							lastgt = undefined;
						}

						i += 2;
					}
				}
				break;

			default:
				logprint("ROTATION: trying to fix unexpected keyword \"" + temparr[i] + "\"\n");

				if(isGametype(temparr[i])) lastgt = temparr[i];
				else if(isConfig(temparr[i])) lastexec = temparr[i];
				else
				{
					xmaps[xmaps.size]["exec"] = lastexec;
					xmaps[xmaps.size-1]["gametype"]	= lastgt;
					xmaps[xmaps.size-1]["map"]	= temparr[i];
	
					if(!random)
					{
						lastexec = undefined;
						lastgt = undefined;
					}
				}

				i += 1;
				break;
		}
	}

	if(random)
	{
		for(k = 0; k < 20; k++)
		{
			for(i = 0; i < xmaps.size; i++)
			{
				j = randomInt(xmaps.size);
				element = xmaps[i];
				xmaps[i] = xmaps[j];
				xmaps[j] = element;
			}
		}
	}

	return xmaps;
}

pbRotation()
{
	doget = true;
	doset = true;
	if(getCvar("ex_maprotdone") == "")
	{
		if(level.ex_fixmaprotation)
		{
			logprint("ROTATION: checking player based rotation string SMALL for errors\n");

			checkrot = "scr_small_rotation";
			maps = rotationstringToArray(getcvar(checkrot), false);
			if(maps.size)
			{
				newmaprotation = "";
				for(i = 0; i < maps.size; i++)
				{
					if(isDefined(maps[i]["exec"])) newmaprotation += " exec " + maps[i]["exec"];
					if(isDefined(maps[i]["gametype"])) newmaprotation += " gametype " + maps[i]["gametype"];
					newmaprotation += " map " + maps[i]["map"];
				}

				setCvar(checkrot, trim(newmaprotation));
			}

			logprint("ROTATION: checking player based rotation string MEDIUM for errors\n");

			checkrot = "scr_med_rotation";
			maps = rotationstringToArray(getcvar(checkrot), false);
			if(maps.size)
			{
				newmaprotation = "";
				for(i = 0; i < maps.size; i++)
				{
					if(isDefined(maps[i]["exec"])) newmaprotation += " exec " + maps[i]["exec"];
					if(isDefined(maps[i]["gametype"])) newmaprotation += " gametype " + maps[i]["gametype"];
					newmaprotation += " map " + maps[i]["map"];
				}

				setCvar(checkrot, trim(newmaprotation));
			}

			logprint("ROTATION: checking player based rotation string LARGE for errors\n");

			checkrot = "scr_large_rotation";
			maps = rotationstringToArray(getcvar(checkrot), false);
			if(maps.size)
			{
				newmaprotation = "";
				for(i = 0; i < maps.size; i++)
				{
					if(isDefined(maps[i]["exec"])) newmaprotation += " exec " + maps[i]["exec"];
					if(isDefined(maps[i]["gametype"])) newmaprotation += " gametype " + maps[i]["gametype"];
					newmaprotation += " map " + maps[i]["map"];
				}

				setCvar(checkrot, trim(newmaprotation));
			}
		}

		doset = false;
		maprot = getcvar("sv_maprotation");
		smallrot = getcvar("scr_small_rotation");
		if(maprot != smallrot)
		{
			// if rotate-if-empty is enabled, make main rotation same as small rotation, so it will
			// start to rotate the correct maps after playing the very first map
			if(level.ex_rotateifempty)
			{
				setcvar("sv_maprotation", smallrot);
				setcvar("sv_maprotationcurrent", "");
			}
			doget = false;
		}
	}

	if(doget)
	{
		nextmap = pbNextMap();
		if(doset && nextmap != "") setcvar("sv_maprotationcurrent", nextmap);
	}
}

defNextMap(skip)
{
	maprot = getCvar("sv_maprotationcurrent");
	if(maprot == "")
	{
		// check rotation stacker
		if(!level.ex_pbrotate)
		{
			maprotno = getCvar("ex_maprotno");
			if(maprotno == "") maprotno = 0;
				else maprotno = getCvarInt("ex_maprotno");
			maprotno++;
			maprot = getCvar("sv_maprotation" + maprotno);
			if(maprot != "")
			{
				setCvar("sv_maprotation", maprot);
				setCvar("ex_maprotno", maprotno);
			}
			else if(maprotno != 1)
			{
				maprot = getCvar("ex_maprotation");
				setCvar("sv_maprotation", maprot);
				setCvar("ex_maprotno", 0);
			}
			else setCvar("ex_maprotno", maprotno);
		}
		else maprot = getCvar("sv_maprotation");
	}

	mapstring = "";
	maps = rotationstringToArray(maprot, false);
	if(!isDefined(maps) || !maps.size) return mapstring;

	if(isDefined(maps[0]["exec"])) mapstring += " exec " + maps[0]["exec"];
	if(isDefined(maps[0]["gametype"])) mapstring += " gametype " + maps[0]["gametype"];
	mapstring += " map " + maps[0]["map"];

	if(skip)
	{
		newmaprotation = "";
		for(i = 1; i < maps.size; i++)
		{
			if(!isDefined(maps[i]["exec"])) exec = "";
				else exec = " exec " + maps[i]["exec"];

			if(!isDefined(maps[i]["gametype"])) gametype = "";
				else gametype = " gametype " + maps[i]["gametype"];

			newmaprotation += exec + gametype + " map " + maps[i]["map"];
		}

		setCvar("sv_maprotationcurrent", trim(newmaprotation));
	}

	return( trim(mapstring) );
}

pbNextMap()
{
	psize = level.players.size;

	// for testing only
	//if(getCvar("ex_maprotdone") == "") psize = level.players.size;
	//	else psize = randomInt(32);

	if(psize >= 1) setCvar("ex_pbplayers", psize);
		else psize = getCvarInt("ex_pbplayers");

	if(psize >= level.ex_mapsizing_large)
	{
		map_rot_cur = "scr_large_rotation_current";
		map_rot = "scr_large_rotation";
	}
	else if(psize >= level.ex_mapsizing_medium)
	{
		map_rot_cur = "scr_med_rotation_current";
		map_rot = "scr_med_rotation";
	}
	else
	{
		map_rot_cur = "scr_small_rotation_current";
		map_rot = "scr_small_rotation";
	}
	
	cur_map_rot = getcvar(map_rot_cur);
	if(cur_map_rot == "" || cur_map_rot == " ")
	{
		setcvar(map_rot_cur, getcvar(map_rot) );
		cur_map_rot = getcvar(map_rot);
	}

	mapstring = "";
	maps = rotationstringToArray(cur_map_rot, false);
	if(maps.size)
	{
		if(isDefined(maps[0]["exec"])) mapstring += " exec " + maps[0]["exec"];
		if(isDefined(maps[0]["gametype"])) mapstring += " gametype " + maps[0]["gametype"];
		mapstring += " map " + maps[0]["map"];

		newcurrentstring = "";
		for(i = 1; i < maps.size; i++)
		{
			if(isDefined(maps[i]["exec"])) newcurrentstring += " exec " + maps[i]["exec"];
			if(isDefined(maps[i]["gametype"])) newcurrentstring += " gametype " + maps[i]["gametype"];
			newcurrentstring += " map " + maps[i]["map"];
		}

		if(newcurrentstring == "") setcvar(map_rot_cur, getcvar(map_rot) );
			else setcvar(map_rot_cur, trim(newcurrentstring));
	}

	return( trim(mapstring) );
}

fixMapRotation()
{
	logprint("ROTATION: checking rotation string for errors\n");

	maps = GetPlainMapRotation(false);
	if(!isDefined(maps) || !maps.size) return;

	newmaprotation = "";
	newmaprotationcurrent = "";
	for(i = 0; i < maps.size; i++)
	{
		if(!isDefined(maps[i]["exec"])) exec = "";
			else exec = " exec " + maps[i]["exec"];

		if(!isDefined(maps[i]["gametype"])) gametype = "";
			else gametype = " gametype " + maps[i]["gametype"];

		newmaprotation += exec + gametype + " map " + maps[i]["map"];
		if(i > 0) newmaprotationcurrent += exec + gametype + " map " + maps[i]["map"];
	}

	setCvar("sv_maprotation", trim(newmaprotation));
	setCvar("sv_maprotationcurrent", trim(newmaprotationcurrent));

	maprotno = 0;
	while(1)
	{
		maprotno++;
		checkrot = "sv_maprotation" + maprotno;
		if(getcvar(checkrot) == "") break;
		logprint("ROTATION: checking stacker " + maprotno + " rotation string for errors\n");
		maps = rotationstringToArray(getcvar(checkrot), false);
		if(maps.size)
		{
			newmaprotation = "";
			for(i = 0; i < maps.size; i++)
			{
				if(isDefined(maps[i]["exec"])) newmaprotation += " exec " + maps[i]["exec"];
				if(isDefined(maps[i]["gametype"])) newmaprotation += " gametype " + maps[i]["gametype"];
				newmaprotation += " map " + maps[i]["map"];
			}

			setCvar(checkrot, trim(newmaprotation));
		}
	}
}

randomMapRotation()
{
	logprint("ROTATION: randomizing rotation string\n");

	maps = GetRandomMapRotation(false);
	if(!isDefined(maps) || !maps.size) return;

	lastexec = "";
	lastgt = "";

	newmaprotation = "";
	for(i = 0; i < maps.size; i++)
	{
		if(!isDefined(maps[i]["exec"]) || lastexec == maps[i]["exec"]) exec = "";
		else
		{
			lastexec = maps[i]["exec"];
			exec = " exec " + maps[i]["exec"];
		}

		if(!isDefined(maps[i]["gametype"]) || lastgt == maps[i]["gametype"]) gametype = "";
		else
		{
			lastgt = maps[i]["gametype"];
			gametype = " gametype " + maps[i]["gametype"];
		}

		newmaprotation += exec + gametype + " map " + maps[i]["map"];
	}

	setCvar("sv_maprotationcurrent", trim(newmaprotation));
}

trim(s)
{
	if(s == "") return "";

	s2 = "";
	s3 = "";

	i = 0;
	while(i < s.size && s[i] == " ") i++;

	// String is just blanks?
	if(i == s.size) return "";
	
	for(; i < s.size; i++) s2 += s[i];

	i = s2.size - 1;
	while(s2[i] == " " && i > 0) i--;

	for(j = 0; j <= i; j++) s3 += s2[j];
		
	return s3;
}

isCommand(command)
{
	switch(command)
	{
		case "map":
		case "exec":
		case "gametype": return true;
		default: return false;
	}
}

isGametype(gt)
{
	switch(gt)
	{
		case "chq":
		case "cnq":
		case "ctf":
		case "ctfb":
		case "dm":
		case "dom":
		case "esd":
		case "ft":
		case "hm":
		case "hq":
		case "htf":
		case "ihtf":
		case "lib":
		case "lms":
		case "lts":
		case "ons":
		case "rbcnq":
		case "rbctf":
		case "sd":
		case "tdm":
		case "tkoth":
		case "vip": return true;
		default: return false;
	}
}

isConfig(cfg)
{
	temparr = explode(cfg, ".");
	if(temparr.size == 2 && temparr[1] == "cfg") return true;
		else return false;
}

explode(s, delimiter)
{
	j = 0;
	temparr[j] = "";	

	for(i = 0; i < s.size; i++)
	{
		if(s[i] == delimiter)
		{
			j++;
			temparr[j] = "";
		}
		else temparr[j] += s[i];
	}

	return temparr;
}
