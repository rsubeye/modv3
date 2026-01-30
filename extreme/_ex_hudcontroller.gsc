/*******************************************************************************
INITIALIZATION
slightly different procedure names to avoid conflicts with other scripts when
_ex_hudcontroller.gsc is included
*******************************************************************************/
hud_init()
{
	level.hudelements_monitor = false;
	level.hudelements_block = false;
	level.hudBarY = 150;
	level.hudBarHeight = 12;
	level.hudBarWidth = 192;
	level.hudBarTextSize = 1.2;

	level.hudelements = [];
	level.hudelements_allocating = false;

 	level.hudobjectives = [];
	// Reserve first 4 objectives for game types
	for(i = 0; i <= 15; i++)
	{
		if(i < 4) level.hudobjectives[i] = 1;
			else level.hudobjectives[i] = 0;
	}

	if(level.hudelements_monitor)
	{
		[[level.ex_PrecacheShader]]("mod_blank_hudicon");
		[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerHasSpawned);
	}

	[[level.ex_registerCallback]]("onGameOver", ::onGameIsOver);
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerIsConnected);
	[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerIsKilled);
}

onGameIsOver()
{
	levelHudDestroyAll();

	players = level.players;
	for(i = 0; i < players.size; i++) players[i] thread playerHudDestroyAll();
}

onPlayerIsConnected()
{
	self.hudelements = [];
	self.hudelements_allocating = false;
}

onPlayerHasSpawned()
{
	if(isDefined(self.pers["isbot"])) return;
	thread playerHudMonitor();
}

onPlayerIsKilled()
{
	thread playerHudDestroyAll();
}

/*******************************************************************************
LEVEL HUD ELEMENTS
*******************************************************************************/
levelHudAlloc(name, team)
{
	if(!isDefined(name) || name == "") return(-1);
	if(isDefined(team) && (team != "allies" && team != "axis" && team != "spectator")) return(-1);
	levelHudDestroy(name);

	while(level.hudelements_allocating) wait( [[level.ex_fpstime]](0.05) );

	index = _levelHudAllocate();
	if(index == -1) return(-1);
	level.hudelements[index].name = name;
	level.hudelements[index].group = "none";
	level.hudelements[index].id = index;
	level.hudelements[index].tag = name;
	if(isDefined(team))
	{
		level.hudelements[index].team = team;
		level.hudelements[index].hud = newTeamHudElem(team);
	}
	else level.hudelements[index].hud = newHudElem();

	if(!isDefined(level.hudelements[index].hud))
	{
		level.hudelements[index].inuse = 0;
		return(-1);
	}
	else return(index);
}

levelHudCreate(name, team, x, y, alpha, color, fontscale, sort, hAlign, vAlign, xAlign, yAlign, foreground, arch)
{
	if(!isDefined(name) || name == "") return(-1);
	if(isDefined(team) && (team != "allies" && team != "axis" && team != "spectator")) return(-1);
	levelHudDestroy(name);

	while(level.hudelements_allocating) wait( [[level.ex_fpstime]](0.05) );

	index = _levelHudAllocate();
	if(index == -1) return(-1);
	level.hudelements[index].name = name;
	level.hudelements[index].group = "none";
	level.hudelements[index].id = index;
	level.hudelements[index].tag = name;
	if(isDefined(team))
	{
		level.hudelements[index].team = team;
		level.hudelements[index].hud = newTeamHudElem(team);
	}
	else level.hudelements[index].hud = newHudElem();

	if(isDefined(level.hudelements[index].hud))
	{
		levelHudSet(index, x, y, alpha, color, fontscale, sort, hAlign, vAlign, xAlign, yAlign, foreground, arch);
		return(index);
	}
	else
	{
		level.hudelements[index].inuse = 0;
		return(-1);
	}
}

_levelHudAllocate()
{
	if(level.hudelements_block) return(-1);

	level.hudelements_allocating = true;
	for(i = 0; i < level.hudelements.size; i++)
	{
		if(level.hudelements[i].inuse == 0)
		{
			level.hudelements[i].keepongameover = 0;
			level.hudelements[i].inuse = 1;
			level.hudelements_allocating = false;
			return(i);
		}
	}

	if(i == 32)
	{
		level.hudelements_allocating = false;
		return(-1);
	}
	level.hudelements[i] = spawnstruct();
	level.hudelements[i].keepongameover = 0;
	level.hudelements[i].inuse = 1;
	level.hudelements_allocating = false;
	return(i);
}

_levelHudNameToIndex(name)
{
	if(name == "") return(-1);
	for(i = 0; i < level.hudelements.size; i++)
		if(level.hudelements[i].inuse && level.hudelements[i].name == name) return(i);
	return(-1);
}

_levelHudVerifyIndex(index)
{
	if(index < 0) return(-1);
	if(!isDefined(level.hudelements[index]) || !level.hudelements[index].inuse) return(-1);
	return(index);
}

levelHudIndex(hud_variant)
{
	if(!isDefined(hud_variant)) return(-1);
	if(isString(hud_variant)) index = _levelHudNameToIndex(hud_variant);
		else index = _levelHudVerifyIndex(hud_variant);
	return(index);
}

levelHudCount()
{
	count = 0;
	for(i = 0; i < level.hudelements.size; i++)
		if(level.hudelements[i].inuse) count++;
	return(count);
}

levelHudSet(hud_variant, x, y, alpha, color, fontscale, sort, hAlign, vAlign, xAlign, yAlign, foreground, arch)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);

	if(!isDefined(x)) x = 320;
	if(!isDefined(y)) y = 240;
	if(!isDefined(alpha)) alpha = 1;
	if(!isDefined(color)) color = (1,1,1);
	if(!isDefined(fontscale)) fontscale = 1;
	if(!isDefined(sort)) sort = 0;
	if(!isDefined(hAlign)) hAlign = "fullscreen";
	if(!isDefined(vAlign)) vAlign = "fullscreen";
	if(!isDefined(xAlign)) xAlign = "center";
	if(!isDefined(yAlign)) yAlign = "middle";
	if(!isDefined(foreground)) foreground = false;
	if(!isDefined(arch)) arch = true;

	level.hudelements[index].org_alpha = alpha;

	level.hudelements[index].hud.archived = arch;
	level.hudelements[index].hud.horzAlign = hAlign;
	level.hudelements[index].hud.vertAlign = vAlign;
	level.hudelements[index].hud.alignX = xAlign;
	level.hudelements[index].hud.alignY = yAlign;
	level.hudelements[index].hud.x = x;
	level.hudelements[index].hud.y = y;
	level.hudelements[index].hud.fontscale = fontscale;
	level.hudelements[index].hud.foreground = foreground;
	level.hudelements[index].hud.sort = sort;
	level.hudelements[index].hud.alpha = alpha;
	level.hudelements[index].hud.color = color;
}

levelHudSetKeepOnGameOver(hud_variant, keepongameover)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(keepongameover)) return(-1);
	level.hudelements[index].keepongameover = keepongameover;
}

levelHudSetGroup(hud_variant, group)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(group) || !isString(group)) return(-1);
	level.hudelements[index].group = tolower(group);
}

levelHudSetID(hud_variant, id)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(id) || isString(id)) return(-1);
	level.hudelements[index].id = id;
}

levelHudGetID(hud_variant)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	return(level.hudelements[index].id);
}

levelHudSetTag(hud_variant, tag)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(tag) || !isString(tag)) return(-1);
	level.hudelements[index].tag = tag;
}

levelHudGetTag(hud_variant)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	return(level.hudelements[index].tag);
}

levelHudSetXYZ(hud_variant, x, y, z)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(isDefined(x)) level.hudelements[index].hud.x = x;
	if(isDefined(y)) level.hudelements[index].hud.y = y;
	if(isDefined(z)) level.hudelements[index].hud.z = z;
}

levelHudGetXYZ(hud_variant)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	return( (level.hudelements[index].hud.x, level.hudelements[index].hud.y, level.hudelements[index].hud.z) );
}

levelHudSetAlpha(hud_variant, alpha)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(alpha)) return(-1);
	level.hudelements[index].hud.alpha = alpha;
}

levelHudSetColor(hud_variant, color)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(color)) return(-1);
	level.hudelements[index].hud.color = color;
}

levelHudSetAlign(hud_variant, xAlign, yAlign)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(isDefined(xAlign)) level.hudelements[index].hud.alignX = xAlign;
	if(isDefined(yAlign)) level.hudelements[index].hud.alignY = yAlign;
}

levelHudSetFontScale(hud_variant, fontscale)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(fontscale)) return(-1);
	level.hudelements[index].hud.fontscale = fontscale;
}

levelHudSetClock(hud_variant, seconds, fulltime, material, width, height)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	if(!isDefined(fulltime)) fulltime = 60;
	if(!isDefined(material)) material = "hudStopWatch";
	if(!isDefined(width)) width = 48;
	if(!isDefined(height)) height = 48;
	level.hudelements[index].hud setClock(seconds, fulltime, material, width, height);
}

levelHudSetClockUp(hud_variant, seconds, fulltime, material, width, height)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	if(!isDefined(fulltime)) fulltime = 60;
	if(!isDefined(material)) material = "hudStopWatch";
	if(!isDefined(width)) width = 48;
	if(!isDefined(height)) height = 48;
	level.hudelements[index].hud setClockUp(seconds, fulltime, material, width, height);
}

levelHudSetTimer(hud_variant, seconds)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	level.hudelements[index].hud setTimer(seconds);
}

levelHudSetTimerUp(hud_variant, seconds)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	level.hudelements[index].hud setTimerUp(seconds);
}

levelHudSetTenthsTimer(hud_variant, seconds)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	level.hudelements[index].hud setTenthsTimer(seconds);
}

levelHudSetTenthsTimerUp(hud_variant, seconds)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	level.hudelements[index].hud setTenthsTimerUp(seconds);
}

levelHudSetShader(hud_variant, shader, width, height)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(shader)) return(-1);
	if(isDefined(width) && isDefined(height)) level.hudelements[index].hud setShader(shader, width, height);
		else level.hudelements[index].hud setShader(shader);
}

levelHudSetLabel(hud_variant, locstring)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(locstring)) return(-1);
	level.hudelements[index].hud.label = locstring;
}

levelHudSetText(hud_variant, locstring)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(locstring)) return(-1);
	level.hudelements[index].hud setText(locstring);
}

levelHudSetValue(hud_variant, value)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(value)) return(-1);
	level.hudelements[index].hud setValue(value);
}

levelHudSetPlayer(hud_variant, player)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(player) || !isPlayer(player)) return(-1);
	level.hudelements[index].hud setPlayerNameString(player);
}

levelHudSetWaypoint(hud_variant, z, constant, offscreenMaterial)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(z)) return(-1);
	if(!isDefined(constant)) constant = true;
	level.hudelements[index].hud.z = z;
	if(isDefined(offscreenMaterial)) level.hudelements[index].hud setWaypoint(constant, offscreenMaterial);
		else level.hudelements[index].hud setWaypoint(constant);
}

levelHudSetWaypointUpdateProc(hud_variant, functionpointer, entity, interval)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(functionpointer)) return(-1);
	if(!isDefined(interval) || interval <= 0) interval = 0.1;
	level thread levelHudWaypointUpdater(index, functionpointer, entity, interval);
}

levelHudWaypointUpdater(hud_variant, functionpointer, entity, interval)
{
	level endon("ex_gameover");

	index = levelHudIndex(hud_variant);
	while(index != -1)
	{
		[[functionpointer]](index, entity);
		wait( [[level.ex_fpstime]](interval) );
		index = levelHudIndex(index);
	}
}

levelHudShow(hud_variant)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(level.hudelements[index].org_alpha != 0) level.hudelements[index].hud.alpha = level.hudelements[index].org_alpha;
		else level.hudelements[index].hud.alpha = 1;
}

levelHudHide(hud_variant)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	level.hudelements[index].hud.alpha = 0;
}

levelHudFade(hud_variant, seconds, waitseconds, alpha)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds) || seconds <= 0) seconds = 1;
	if(!isDefined(waitseconds || waitseconds < 0)) waitseconds = seconds;
	if(!isDefined(alpha)) alpha = level.hudelements[index].alpha;
	level.hudelements[index].hud fadeOverTime(seconds);
	level.hudelements[index].hud.alpha = alpha;
	if(waitseconds) wait( [[level.ex_fpstime]](waitseconds) );
}

levelHudMove(hud_variant, seconds, waitseconds, x, y, relative)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(x) && !isDefined(y)) return(-1);
	if(!isDefined(seconds) || seconds <= 0) seconds = 1;
	if(!isDefined(waitseconds || waitseconds < 0)) waitseconds = seconds;
	if(!isDefined(relative)) relative = false;
	level.hudelements[index].hud moveOverTime(seconds);
	if(relative)
	{
		if(isDefined(x)) level.hudelements[index].hud.x += x;
		if(isDefined(y)) level.hudelements[index].hud.y += y;
	}
	else
	{
		if(isDefined(x)) level.hudelements[index].hud.x = x;
		if(isDefined(y)) level.hudelements[index].hud.y = y;
	}
	if(waitseconds) wait( [[level.ex_fpstime]](waitseconds) );
}

levelHudScale(hud_variant, seconds, waitseconds, width, height)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(width) || !isDefined(height)) return(-1);
	if(!isDefined(seconds) || seconds <= 0) seconds = 1;
	if(!isDefined(waitseconds || waitseconds < 0)) waitseconds = seconds;
	level.hudelements[index].hud scaleOverTime(seconds, width, height);
	if(waitseconds) wait( [[level.ex_fpstime]](waitseconds) );
}

levelHudDestroyAll()
{
	if(!isDefined(level.hudelements)) return(-1);
	for(i = 0; i < level.hudelements.size; i++)
		if(level.hudelements[i].inuse && !level.hudelements[i].keepongameover) levelHudDestroy(i);
}

levelHudDestroyGroup(group)
{
	if(!isDefined(level.hudelements)) return(-1);

	group = tolower(group);
	for(i = 0; i < level.hudelements.size; i++)
		if(level.hudelements[i].inuse && level.hudelements[i].group == group) levelHudDestroy(i);
}

levelHudDestroy(hud_variant)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(isDefined(level.hudelements[index].hud)) level.hudelements[index].hud destroy();
	level.hudelements[index].inuse = 0;
}

levelHudDestroyTimed(hud_variant, seconds)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);
	level notify("level_hudtimer" + index);
	if(seconds) thread _levelHudDestroyTimer(index, seconds);
}

_levelHudDestroyTimer(hud_variant, seconds)
{
	index = levelHudIndex(hud_variant);
	if(index == -1) return(-1);

	level endon("level_hudtimer" + index);

	wait( [[level.ex_fpstime]](seconds) );

	index = levelHudIndex(hud_variant);
	if(index != -1)
	{
		if(level.hudelements[index].group != "none") levelHudDestroyGroup(level.hudelements[index].group);
			else levelHudDestroy(index);
	}
}

/*******************************************************************************
LEVEL OBJECTIVES
*******************************************************************************/
levelHudGetObjective()
{
	// Check slots 15 - 4 (0 - 3 are reserved for game types)
	objnum = 0;
	for(i = 15; i >= 4; i--)
	{
		if(level.hudobjectives[i] == 0)
		{
			level.hudobjectives[i] = 1;
			objnum = i;
			break;
		}
	}
	return(objnum);
}

levelHudFreeObjective(objnum)
{
	if(level.hudobjectives[objnum] == 1)
	{
		objective_delete(objnum);
		level.hudobjectives[objnum] = 0;
	}
}

/*******************************************************************************
LEVEL WINNER ANNOUNCEMENT
*******************************************************************************/
levelAnnounceWinner(winner)
{
	hud_index = -1;
	if(level.mapended)
	{
		level.ex_gameover = true;
		level notify("ex_gameover");

		wait( [[level.ex_fpstime]](.25) );
		if(level.ex_announcewinner) hud_index = levelHudCreate("winner", undefined, 0, 20, 1, (1,1,1), 1, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	}

	switch(winner)
	{
		case "allies":
			if(level.mapended)
			{
				if(hud_index != -1) levelHudSetShader(hud_index, game["winner_allies"], 512, 256);
				text = &"MP_ALLIES_WIN";
			}
			else text = &"MP_ALLIES_WIN_ROUND";
			iprintlnbold(text);
			level thread [[level.ex_psop]]("MP_announcer_allies_win");
			break;
		case "axis":
			if(level.mapended)
			{
				if(hud_index != -1) levelHudSetShader(hud_index, game["winner_axis"], 512, 256);
				text = &"MP_AXIS_WIN";
			}
			else text = &"MP_AXIS_WIN_ROUND";
			iprintlnbold(text);
			level thread [[level.ex_psop]]("MP_announcer_axis_win");
			break;
		default:
			if(level.mapended)
			{
				if(hud_index != -1) levelHudSetShader(hud_index, game["winner_draw"], 512, 256);
				text = &"MP_THE_GAME_IS_A_TIE";
			}
			else text = &"MP_THE_ROUND_IS_A_TIE";
			iprintlnbold(text);
			level thread [[level.ex_psop]]("MP_announcer_round_draw");
			break;
	}

	if(level.mapended)
	{
		// prepare players for intermission
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player)) continue;

			// stop pain sounds by restoring health
			player.health = player.maxhealth;

			// drop flag
			player extreme\_ex_utils::dropTheFlag(true);

			// close and set menu
			player setClientCvar("cg_objectiveText", text);
			player setClientCvar("g_scriptMainMenu", "");
			player closeMenu();
			player closeInGameMenu();

			// move to spectators
			player thread extreme\_ex_spawn::spawnSpectator();

			// set spectate permissions
			player allowSpectateTeam("allies", false);
			player allowSpectateTeam("axis", false);
			player allowSpectateTeam("freelook", false);
			player allowSpectateTeam("none", true);

			// restore status icon
			player playerHudRestoreStatusIcon();
		}
	}

	wait( [[level.ex_fpstime]](level.ex_announcewinner_delay) );

	if(hud_index != -1) levelHudDestroy(hud_index);
}

/*******************************************************************************
PLAYER HUD ELEMENTS
*******************************************************************************/
playerHudAlloc(name)
{
	if(!isDefined(name) || name == "") return(-1);
	if(!isPlayer(self)) return(-1);
	playerHudDestroy(name);

	while(isPlayer(self) && self.hudelements_allocating) wait( [[level.ex_fpstime]](0.05) );
	if(!isPlayer(self)) return(-1);

	index = _playerHudAllocate();
	if(index == -1) return(-1);
	self.hudelements[index].name = name;
	self.hudelements[index].group = "none";
	self.hudelements[index].id = index;
	self.hudelements[index].tag = name;
	self.hudelements[index].hud = newClientHudElem(self);

	if(!isDefined(self.hudelements[index].hud))
	{
		self.hudelements[index].inuse = 0;
		return(-1);
	}
	else return(index);
}

playerHudCreate(name, x, y, alpha, color, fontscale, sort, hAlign, vAlign, xAlign, yAlign, foreground, arch)
{
	if(!isDefined(name) || name == "") return(-1);
	if(!isPlayer(self)) return(-1);
	playerHudDestroy(name);

	while(isPlayer(self) && self.hudelements_allocating) wait( [[level.ex_fpstime]](0.05) );
	if(!isPlayer(self)) return(-1);

	index = _playerHudAllocate();
	if(index == -1) return(-1);
	self.hudelements[index].name = name;
	self.hudelements[index].group = "none";
	self.hudelements[index].id = index;
	self.hudelements[index].tag = name;
	self.hudelements[index].hud = newClientHudElem(self);

	if(isDefined(self.hudelements[index].hud))
	{
		playerHudSet(index, x, y, alpha, color, fontscale, sort, hAlign, vAlign, xAlign, yAlign, foreground, arch);
		return(index);
	}
	else
	{
		self.hudelements[index].inuse = 0;
		return(-1);
	}
}

_playerHudAllocate()
{
	if(level.hudelements_block) return(-1);

	self.hudelements_allocating = true;
	for(i = 0; i < self.hudelements.size; i++)
	{
		if(self.hudelements[i].inuse == 0)
		{
			self.hudelements[i].keeponkill = 0;
			self.hudelements[i].keepongameover = 0;
			self.hudelements[i].inuse = 1;
			self.hudelements_allocating = false;
			return(i);
		}
	}

	if(i == 32 || (i + levelHudCount() >= 32))
	{
		self.hudelements_allocating = false;
		return(-1);
	}
	self.hudelements[i] = spawnstruct();
	self.hudelements[i].keeponkill = 0;
	self.hudelements[i].keepongameover = 0;
	self.hudelements[i].inuse = 1;
	self.hudelements_allocating = false;
	return(i);
}

_playerHudNameToIndex(name)
{
	if(name == "" || !isPlayer(self)) return(-1);
	for(i = 0; i < self.hudelements.size; i++)
		if(self.hudelements[i].inuse && self.hudelements[i].name == name) return(i);
	return(-1);
}

_playerHudVerifyIndex(index)
{
	if(index < 0 || !isPlayer(self)) return(-1);
	if(!isDefined(self.hudelements[index]) || !self.hudelements[index].inuse) return(-1);
	return(index);
}

playerHudIndex(hud_variant)
{
	if(!isDefined(hud_variant)) return(-1);
	if(isString(hud_variant)) index = _playerHudNameToIndex(hud_variant);
		else index = _playerHudVerifyIndex(hud_variant);
	return(index);
}

playerHudCount()
{
	count = 0;
	for(i = 0; i < self.hudelements.size; i++)
		if(self.hudelements[i].inuse) count++;
	return(count);
}

playerHudSet(hud_variant, x, y, alpha, color, fontscale, sort, hAlign, vAlign, xAlign, yAlign, foreground, arch)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);

	if(!isDefined(x)) x = 320;
	if(!isDefined(y)) y = 240;
	if(!isDefined(alpha)) alpha = 1;
	if(!isDefined(color)) color = (1,1,1);
	if(!isDefined(fontscale)) fontscale = 1;
	if(!isDefined(sort)) sort = 0;
	if(!isDefined(hAlign)) hAlign = "fullscreen";
	if(!isDefined(vAlign)) vAlign = "fullscreen";
	if(!isDefined(xAlign)) xAlign = "center";
	if(!isDefined(yAlign)) yAlign = "middle";
	if(!isDefined(foreground)) foreground = false;
	if(!isDefined(arch)) arch = true;

	self.hudelements[index].org_alpha = alpha;

	self.hudelements[index].hud.archived = arch;
	self.hudelements[index].hud.horzAlign = hAlign;
	self.hudelements[index].hud.vertAlign = vAlign;
	self.hudelements[index].hud.alignX = xAlign;
	self.hudelements[index].hud.alignY = yAlign;
	self.hudelements[index].hud.x = x;
	self.hudelements[index].hud.y = y;
	self.hudelements[index].hud.fontscale = fontscale;
	self.hudelements[index].hud.foreground = foreground;
	self.hudelements[index].hud.sort = sort;
	self.hudelements[index].hud.alpha = alpha;
	self.hudelements[index].hud.color = color;
}

playerHudSetKeepOnKill(hud_variant, keeponkill)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(keeponkill)) return(-1);
	self.hudelements[index].keeponkill = keeponkill;
}

playerHudSetKeepOnGameOver(hud_variant, keepongameover)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(keepongameover)) return(-1);
	self.hudelements[index].keepongameover = keepongameover;
}

playerHudSetGroup(hud_variant, group)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(group) || !isString(group)) return(-1);
	self.hudelements[index].group = tolower(group);
}

playerHudSetID(hud_variant, id)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(id) || isString(id)) return(-1);
	self.hudelements[index].id = id;
}

playerHudGetID(hud_variant)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	return(self.hudelements[index].id);
}

playerHudSetTag(hud_variant, tag)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(tag) || !isString(tag)) return(-1);
	self.hudelements[index].tag = tag;
}

playerHudGetTag(hud_variant)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return("");
	return(self.hudelements[index].tag);
}

playerHudSetXYZ(hud_variant, x, y, z)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(isDefined(x)) self.hudelements[index].hud.x = x;
	if(isDefined(y)) self.hudelements[index].hud.y = y;
	if(isDefined(z)) self.hudelements[index].hud.z = z;
}

playerHudGetXYZ(hud_variant)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	return( (self.hudelements[index].hud.x, self.hudelements[index].hud.y, self.hudelements[index].hud.z) );
}

playerHudSetAlpha(hud_variant, alpha)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(alpha)) return(-1);
	self.hudelements[index].hud.alpha = alpha;
}

playerHudSetColor(hud_variant, color)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(color)) return(-1);
	self.hudelements[index].hud.color = color;
}

playerHudSetAlign(hud_variant, xAlign, yAlign)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(isDefined(xAlign)) self.hudelements[index].hud.alignX = xAlign;
	if(isDefined(yAlign)) self.hudelements[index].hud.alignY = yAlign;
}

playerHudSetFontScale(hud_variant, fontscale)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(fontscale)) return(-1);
	self.hudelements[index].hud.fontscale = fontscale;
}

playerHudSetClock(hud_variant, seconds, fulltime, material, width, height)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	if(!isDefined(fulltime)) fulltime = 60;
	if(!isDefined(material)) material = "hudStopWatch";
	if(!isDefined(width)) width = 48;
	if(!isDefined(height)) height = 48;
	self.hudelements[index].hud setClock(seconds, fulltime, material, width, height);
}

playerHudSetClockUp(hud_variant, seconds, fulltime, material, width, height)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	if(!isDefined(fulltime)) fulltime = 60;
	if(!isDefined(material)) material = "hudStopWatch";
	if(!isDefined(width)) width = 48;
	if(!isDefined(height)) height = 48;
	self.hudelements[index].hud setClockUp(seconds, fulltime, material, width, height);
}

playerHudSetTimer(hud_variant, seconds)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	self.hudelements[index].hud setTimer(seconds);
}

playerHudSetTimerUp(hud_variant, seconds)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	self.hudelements[index].hud setTimerUp(seconds);
}

playerHudSetTenthsTimer(hud_variant, seconds)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	self.hudelements[index].hud setTenthsTimer(seconds);
}

playerHudSetTenthsTimerUp(hud_variant, seconds)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds)) return(-1);
	self.hudelements[index].hud setTenthsTimerUp(seconds);
}

playerHudSetShader(hud_variant, shader, width, height)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(shader)) return(-1);
	if(isDefined(width) && isDefined(height)) self.hudelements[index].hud setShader(shader, width, height);
		else self.hudelements[index].hud setShader(shader);
}

playerHudSetLabel(hud_variant, locstring)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(locstring)) return(-1);
	self.hudelements[index].hud.label = locstring;
}

playerHudSetText(hud_variant, locstring)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(locstring)) return(-1);
	self.hudelements[index].hud setText(locstring);
}

playerHudSetValue(hud_variant, value)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(value)) return(-1);
	self.hudelements[index].hud setValue(value);
}

playerHudSetPlayer(hud_variant, player)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(player) || !isPlayer(player)) return(-1);
	self.hudelements[index].hud setPlayerNameString(player);
}

playerHudSetWaypoint(hud_variant, z, constant, offscreenMaterial)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(z)) return(-1);
	if(!isDefined(constant)) constant = true;
	self.hudelements[index].hud.z = z;
	if(isDefined(offscreenMaterial)) self.hudelements[index].hud setWaypoint(constant, offscreenMaterial);
		else self.hudelements[index].hud setWaypoint(constant);
}

playerHudSetWaypointUpdateProc(hud_variant, functionpointer, entity, interval)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(functionpointer)) return(-1);
	if(!isDefined(interval) || interval <= 0) interval = 0.1;
	self thread playerHudWaypointUpdater(index, functionpointer, entity, interval);
}

playerHudWaypointUpdater(hud_variant, functionpointer, entity, interval)
{
	self endon("kill_thread");

	index = playerHudIndex(hud_variant);
	while(index != -1)
	{
		[[functionpointer]](index, entity);
		wait( [[level.ex_fpstime]](interval) );
		index = playerHudIndex(index);
	}
}

playerHudShow(hud_variant)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(self.hudelements[index].org_alpha != 0) self.hudelements[index].hud.alpha = self.hudelements[index].org_alpha;
		else self.hudelements[index].hud.alpha = 1;
}

playerHudHide(hud_variant)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	self.hudelements[index].hud.alpha = 0;
}

playerHudFade(hud_variant, seconds, waitseconds, alpha)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(seconds) || seconds <= 0) seconds = 1;
	if(!isDefined(waitseconds || waitseconds < 0)) waitseconds = seconds;
	if(!isDefined(alpha)) alpha = self.hudelements[index].alpha;
	self.hudelements[index].hud fadeOverTime(seconds);
	self.hudelements[index].hud.alpha = alpha;
	if(waitseconds) wait( [[level.ex_fpstime]](waitseconds) );
}

playerHudMove(hud_variant, seconds, waitseconds, x, y, relative)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(x) && !isDefined(y)) return(-1);
	if(!isDefined(seconds) || seconds <= 0) seconds = 1;
	if(!isDefined(waitseconds || waitseconds < 0)) waitseconds = seconds;
	if(!isDefined(relative)) relative = false;
	self.hudelements[index].hud moveOverTime(seconds);
	if(relative)
	{
		if(isDefined(x)) self.hudelements[index].hud.x += x;
		if(isDefined(y)) self.hudelements[index].hud.y += y;
	}
	else
	{
		if(isDefined(x)) self.hudelements[index].hud.x = x;
		if(isDefined(y)) self.hudelements[index].hud.y = y;
	}
	if(waitseconds) wait( [[level.ex_fpstime]](waitseconds) );
}

playerHudScale(hud_variant, seconds, waitseconds, width, height)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(width) || !isDefined(height)) return(-1);
	if(!isDefined(seconds) || seconds <= 0) seconds = 1;
	if(!isDefined(waitseconds || waitseconds < 0)) waitseconds = seconds;
	self.hudelements[index].hud scaleOverTime(seconds, width, height);
	if(waitseconds) wait( [[level.ex_fpstime]](waitseconds) );
}

playerHudSetUpdateProc(hud_variant, functionpointer, interval)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(!isDefined(functionpointer)) return(-1);
	if(!isDefined(interval) || interval <= 0) interval = 0.1;
	self notify("player_killupdater" + index);
	self thread _playerHudUpdater(index, functionpointer, interval);
}

_playerHudUpdater(hud_variant, functionpointer, interval)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);

	self endon("kill_thread");
	self endon("player_killupdater" + index);

	while(index != -1)
	{
		[[functionpointer]](index);
		wait( [[level.ex_fpstime]](interval) );
		index = playerHudIndex(hud_variant);
	}
}

playerHudDestroyAll()
{
	if(!isDefined(self.hudelements)) return(-1);
	for(i = 0; i < self.hudelements.size; i++)
	{
		if(!level.ex_gameover)
		{
			if(self.hudelements[i].inuse && !self.hudelements[i].keeponkill) playerHudDestroy(i);
		}
		else if(self.hudelements[i].inuse && !self.hudelements[i].keepongameover) playerHudDestroy(i);
	}
}

playerHudDestroyGroup(group)
{
	if(!isDefined(self.hudelements)) return(-1);

	group = tolower(group);
	for(i = 0; i < self.hudelements.size; i++)
		if(self.hudelements[i].inuse && self.hudelements[i].group == group) playerHudDestroy(i);
}

playerHudDestroy(hud_variant)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	if(isDefined(self.hudelements[index].hud)) self.hudelements[index].hud destroy();
	self.hudelements[index].inuse = 0;
}

playerHudDestroyTimed(hud_variant, seconds)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	self notify("player_hudtimer" + index);
	if(seconds) thread _playerHudDestroyTimer(index, seconds);
}

_playerHudDestroyTimer(hud_variant, seconds)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);

	self endon("kill_thread");
	self endon("player_hudtimer" + index);

	wait( [[level.ex_fpstime]](seconds) );

	index = playerHudIndex(hud_variant);
	if(index != -1)
	{
		if(self.hudelements[index].group != "none") playerHudDestroyGroup(self.hudelements[index].group);
			else playerHudDestroy(index);
	}
}

/*******************************************************************************
PLAYER HUD ANNOUNCEMENTS
*******************************************************************************/
playerHudAnnounce(locstring)
{
	self endon("kill_thread");

	if(!isDefined(locstring)) return;
	if(!isDefined(self.allocating_hudannounce)) self.allocating_hudannounce = false;
	if(!isDefined(self.hudannouncements)) self.hudannouncements = [];

	// if the string is already on screen, don't display again
	for(i = 0; i < self.hudannouncements.size; i++)
		if(self.hudannouncements[i].inuse && self.hudannouncements[i].locstring == locstring) return;

	// wait while another hudAnnounce thread is allocating a slot
	while(self.allocating_hudannounce) wait( [[level.ex_fpstime]](0.25) );

	// allocate a slot
	self.allocating_hudannounce = true;
	hud_slot = playerHudAnnounceAllocateSlot();
	while(hud_slot == -1)
	{
		wait( [[level.ex_fpstime]](0.25) );
		hud_slot = playerHudAnnounceAllocateSlot();
	}

	self.hudannouncements[hud_slot].locstring = locstring;

	// move existing strings up
	for(i = 0; i < self.hudannouncements.size; i++)
	{
		if(self.hudannouncements[i].inuse && self.hudannouncements[i].hud_index != -1)
		{
			hud_index = playerHudIndex(self.hudannouncements[i].hud_index);
			if(hud_index == -1) continue;
			playerHudMove(hud_index, 0.2, 0, undefined, -15, true);
		}
	}

	wait( [[level.ex_fpstime]](0.3) );

	// create the HUD element
	hud_index = playerHudCreate("hudannounce_slot" + hud_slot, 320, 80, 0, (1,1,1), 1.1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1)
	{
		self.hudannouncements[hud_slot].hud_index = hud_index;
		thread playerHudAnnounceDisplay(hud_slot);
	}
	else playerHudAnnounceFree(hud_slot);
	self.allocating_hudannounce = false;
}

playerHudAnnounceDisplay(hud_slot)
{
	self endon("kill_thread");

	playerHudSetText(self.hudannouncements[hud_slot].hud_index, self.hudannouncements[hud_slot].locstring);
	playerHudFade(self.hudannouncements[hud_slot].hud_index, 0.5, 0, 1);

	wait( [[level.ex_fpstime]](5) );

	playerHudFade(self.hudannouncements[hud_slot].hud_index, 0.5, 0.5, 0);
	playerHudDestroy(self.hudannouncements[hud_slot].hud_index);

	playerHudAnnounceFree(hud_slot);
}

playerHudAnnounceAllocateSlot(locstring)
{
	self endon("kill_thread");

	for(i = 0; i < 3; i++)
	{
		if(isDefined(self.hudannouncements[i]))
		{
			if(self.hudannouncements[i].inuse == 0)
			{
				self.hudannouncements[i].hud_index = -1;
				self.hudannouncements[i].inuse = 1;
				return(i);
			}
		}
		else
		{
			self.hudannouncements[i] = spawnstruct();
			self.hudannouncements[i].hud_index = -1;
			self.hudannouncements[i].inuse = 1;
			return(i);
		}
	}
	return(-1);
}

playerHudAnnounceFree(hud_slot)
{
	self.hudannouncements[hud_slot].hud_index = -1;
	self.hudannouncements[hud_slot].inuse = 0;
}

/*******************************************************************************
PLAYER HUD PULSE FONT
*******************************************************************************/
playerHudFontPulseInit(hud_variant)
{
	index = playerHudIndex(hud_variant);
	if(index == -1) return(-1);
	self.hudelements[index].hud.pulse_orgfontscale = self.hudelements[index].hud.fontscale;
	self.hudelements[index].hud.pulse_maxfontscale = self.hudelements[index].hud.fontscale * 2;
	self.hudelements[index].hud.pulse_inframes = 3;
	self.hudelements[index].hud.pulse_outframes = 5;
}

playerHudFontPulse(hud_variant, value, fadeout, notification)
{
	self notify(notification);
	self endon(notification);

	index = playerHudIndex(hud_variant);
	if(index == -1) return;

	level endon("ex_gameover");
	self endon("disconnect");

	hud = self.hudelements[index].hud;
	if(isDefined(hud))
	{
		if(isDefined(value)) hud setValue(value);
		hud.alpha = 1;
		scalerange = hud.pulse_maxfontscale - hud.pulse_orgfontscale;

		while(isDefined(hud) && hud.fontscale < hud.pulse_maxfontscale)
		{
			hud.fontScale = min(hud.pulse_maxfontscale, hud.fontscale + (scalerange / hud.pulse_inframes));
			wait( [[level.ex_fpstime]](level.ex_fps_frame) );
		}

		while(isDefined(hud) && hud.fontscale > hud.pulse_orgfontscale)
		{
			hud.fontScale = max(hud.pulse_orgfontscale, hud.fontscale - (scalerange / hud.pulse_outframes));
			wait( [[level.ex_fpstime]](level.ex_fps_frame) );
		}

		if(isDefined(hud) && fadeout)
		{
			hud fadeOverTime(1);
			hud.alpha = 0;
		}
	}
}

min(x, y)
{
	if(x < y) return(x);
	return(y);
}

max(x, y)
{
	if(x > y) return(x);
	return(y);
}

/*******************************************************************************
PLAYER HUD ICONS
*******************************************************************************/
playerHudCreateIcon(name, x, y, shader)
{
	self endon("kill_thread");

	index = playerHudCreate(name, x, y, level.ex_iconalpha, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(index == -1) return;

	playerHudSetShader(index, shader, 32, 32);
	playerHudScale(index, 0.5, 0, 24, 24);
}

playerHudBlip(color)
{
	self endon("kill_thread");

	hud_index = playerHudCreate("debugblip", 320, 140, 1, color, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "white", 24, 24);
	wait( [[level.ex_fpstime]](1) );
	playerHudDestroy(hud_index);
}

/*******************************************************************************
PLAYER STATUS ICON
*******************************************************************************/
playerHudSetStatusIcon(icon)
{
	if(!isDefined(icon)) return;
	if(!extreme\_ex_utils::isInArray(game["precached_statusicons"], icon)) return;
	self.statusicon = icon;
}

playerHudRestoreStatusIcon()
{
	self endon("kill_thread");

	if(level.ex_classes == 1 && level.ex_classes_statusicons)
	{
		self.statusicon = extreme\_ex_classes::getStatusIcon();
	}
	else if(level.ex_ranksystem && level.ex_rank_statusicons)
	{
		self.statusicon = extreme\_ex_ranksystem::getStatusIcon();
	}
	else self.statusicon = "";
}

/*******************************************************************************
PLAYER HEAD ICON
*******************************************************************************/
playerHudSetHeadIcon(icon, team)
{
	if(!isDefined(icon)) return;
	if(!extreme\_ex_utils::isInArray(game["precached_headicons"], icon)) return;
	if(level.ex_currentgt != "hm" && (!level.ex_teamplay || !level.drawfriend)) return;
	self.headicon = icon;
	if(isDefined(team)) self.headiconteam = team;
}

playerHudRestoreHeadIcon()
{
	self endon("kill_thread");

	if(level.ex_currentgt == "hm" && isDefined(self.hm_status))
	{
		self thread maps\mp\gametypes\_ex_hm::setHeadIcon();
	}
	else if(level.ex_currentgt == "vip" && isDefined(self.isvip) && self.isvip)
	{
		self thread maps\mp\gametypes\_ex_vip::setHeadIcon();
	}
	else
	{
		if(level.ex_teamplay && level.drawfriend && self.pers["team"] != "spectator" && self.sessionstate == "playing")
		{
			if(level.ex_classes == 1 && level.ex_classes_headicons)
			{
				self.headicon = extreme\_ex_classes::getHeadIcon();
			}
			else if(level.ex_ranksystem && level.ex_rank_headicons)
			{
				self.headicon = extreme\_ex_ranksystem::getHeadIcon();
			}
			else self.headicon = game["headicon_" + self.pers["team"]];

			if(isDefined(self.sessionteam) && self.sessionteam != "spectator") self.headiconteam = self.sessionteam;
				else self.headiconteam = self.pers["team"];
		}
		else
		{
			self.headicon = "";
			self.headiconteam = "";
		}
	}
}

/*******************************************************************************
PLAYER HUD GENERAL PURPOSE PROGRESS BAR
*******************************************************************************/
playerHudCreateBar(bartime, locstring, reverse)
{
	self endon("kill_thread");

	hud_index = playerHudCreate("progress_back", 0, level.hudBarY, 0.5, (0,0,0), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "black", level.hudBarWidth, level.hudBarHeight);

	hud_index = playerHudCreate("progress_bar", level.hudBarWidth / -2, level.hudBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, false);
	if(hud_index == -1) return;

	if(reverse)
	{
		playerHudSetShader(hud_index, "white", level.hudBarWidth, level.hudBarHeight);
		playerHudScale(hud_index, bartime, 0, 1, level.hudBarHeight);
	}
	else
	{
		playerHudSetShader(hud_index, "white", 1, level.hudBarHeight);
		playerHudScale(hud_index, bartime, 0, level.hudBarWidth, level.hudBarHeight);
	}

	if(isDefined(locstring))
	{
		hud_index = playerHudCreate("progress_text", 0, level.hudBarY + (level.hudBarTextSize * 10), 1, (1,1,1), level.hudBarTextSize, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index == -1) return;
		playerHudSetText(hud_index, locstring);
	}
}

playerHudBarSetText(locstring)
{
	if(!isDefined(locstring)) return;
	hud_index = playerHudIndex("progress_text");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("progress_text", 0, level.hudBarY + (level.hudBarTextSize * 10), 1, (1,1,1), level.hudBarTextSize, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index == -1) return;
	}
	playerHudSetText(hud_index, locstring);
}

playerHudDestroyBar()
{
	playerHudDestroy("progress_back");
	playerHudDestroy("progress_bar");
	playerHudDestroy("progress_text");
}

/*******************************************************************************
HUD ELEMENTS MONITOR
*******************************************************************************/
playerHudMonitor()
{
	self endon("disconnect");

	hud_index = playerHudIndex("hudmonitor_back");
	if(hud_index != -1) return;

	hud_index = playerHudCreate("hudmonitor_back", 320, 50, level.ex_iconalpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;

	playerHudSetShader(hud_index, "mod_blank_hudicon", 24, 24);
	playerHudSetKeepOnKill(hud_index, true);
	playerHudSetKeepOnGameOver(hud_index, true);

	hud_index = playerHudCreate("hudmonitor_stat", 320, 50, 1, (0.2,0.2,0), 0.7, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;

	playerHudSetValue(hud_index, 0);
	playerHudSetKeepOnKill(hud_index, true);
	playerHudSetKeepOnGameOver(hud_index, true);

	showing = 0;

	while(true)
	{
		wait( [[level.ex_fpstime]](2) );
		if(!isDefined(self)) break;

		stat = 0;
		if(showing)
		{
			stat_list = "level HUD: ";
			for(i = 0; i < level.hudelements.size; i++)
			{
				if(level.hudelements[i].inuse)
				{
					stat++;
					stat_list = stat_list + level.hudelements[i].name + ";";
					//stat_list = stat_list + level.hudelements[i].name + "(" + level.hudelements[i].hud.x + "," + level.hudelements[i].hud.y + ");";
				}
			}
			logprint(stat_list + "\n");
		}
		else
		{
			stat_list = "player HUD: ";
			for(i = 0; i < self.hudelements.size; i++)
			{
				if(self.hudelements[i].inuse)
				{
					stat++;
					stat_list = stat_list + self.hudelements[i].name + ";";
					//stat_list = stat_list + self.hudelements[i].name + "(" + self.hudelements[i].hud.x + "," + self.hudelements[i].hud.y + ");";
				}
			}
			logprint(stat_list + "\n");
		}

		playerHudSetValue(hud_index, stat);
		showing = !showing;
	}
}
