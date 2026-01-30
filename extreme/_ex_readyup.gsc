#include extreme\_ex_hudcontroller;

init()
{
	if(!isDefined(game["readyup_done"]))
	{
		[[level.ex_PrecacheString]](&"READYUP_WAIT_FOR_NEXT_ROUND");

		if(level.ex_readyup_graceperiod)
		{
			[[level.ex_PrecacheShader]]("white");
			[[level.ex_PrecacheString]](&"READYUP_GRACE_PERIOD");
		}

		if(level.ex_readyup == 1) // simple mode
		{
			[[level.ex_PrecacheString]](&"READYUP_WAITING_FOR_PLAYERS");
			[[level.ex_PrecacheString]](&"READYUP_MATCH_BEGINS");

			level thread levelGTSDelay();
		}
		else // enhanced mode
		{
			[[level.ex_PrecacheString]](&"READYUP_READYUP");
			[[level.ex_PrecacheString]](&"READYUP_WAITING_FOR");
			[[level.ex_PrecacheString]](&"READYUP_MORE_PLAYERS");
			[[level.ex_PrecacheString]](&"READYUP_HOWTO");
			[[level.ex_PrecacheString]](&"READYUP_READY");
			[[level.ex_PrecacheString]](&"READYUP_NOTREADY");
			[[level.ex_PrecacheString]](&"READYUP_MATCH_BEGINS");

			if(!level.ex_rank_statusicons && !level.ex_classes_statusicons)
			{
				[[level.ex_PrecacheStatusIcon]]("hud_status_ready");
				[[level.ex_PrecacheStatusIcon]]("hud_status_notready");
			}

			// [ 0: ready-up init, 1: waiting for players, 2: ready-up done ], 3: in grace period, 4: grace period done
			level.ex_readyup_status = 0;
			level.ex_readyup_players = [];

			[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
			[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
			[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
			//[[level.ex_registerCallback]]("onPlayerDisconnected", ::onPlayerDisconnected);

			level thread levelReadyup();
		}
	}
	else
	{
		if(level.ex_readyup == 2 && level.ex_readyup_graceperiod)
		{
			// 0: ready-up init, 1: waiting for players, 2: ready-up done, [ 3: in grace period, 4: grace period done ]
			level.ex_readyup_status = 3;

			level thread levelGracePeriod();
		}
		else level.ex_readyup_status = 2;
	}
}

onPlayerConnected()
{
	readyup_id = self getEntityNumber();
	if(!isDefined(level.ex_readyup_players[readyup_id])) level.ex_readyup_players[readyup_id] = spawnstruct();
	level.ex_readyup_players[readyup_id].name = self.name;
	level.ex_readyup_players[readyup_id].status = "spectating";
}

onPlayerSpawned()
{
	level endon("readyup_done");
	self endon("disconnect");

	playerHudSetStatusIcon("hud_status_notready");
	readyup_id = self getEntityNumber();
	level.ex_readyup_players[readyup_id].status = "notready";
	self thread playerReadyup(readyup_id);
}

onJoinedSpectators()
{
	level endon("readyup_done");
	self endon("disconnect");

	self notify("readyup_end");
	self.statusicon = "";
	readyup_id = self getEntityNumber();
	level.ex_readyup_players[readyup_id].status = "spectating";
}

onPlayerDisconnected(readyup_id)
{
	// called from _ex_clientcontrol::onPlayerDisconnected() to get entity parameter
	if(!isDefined(level.ex_readyup_players[readyup_id])) return;
	level.ex_readyup_players[readyup_id].status = "disconnected";
}

levelGTSDelay()
{
	level endon("ex_gameover");

	level.ex_readyup_status = 1;

	hud_index = levelHudCreate("readyup_status", undefined, 320, 100, 1, (0,1,0), 2, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetLabel(hud_index, &"READYUP_WAITING_FOR_PLAYERS");

	for(;;)
	{
		wait( [[level.ex_fpstime]](1) );

		players = level.players;
		if(players.size == 0) continue;

		playercount = 0;
		for(i = 0; i < players.size; i++)
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator") playercount++;
		if(playercount >= 2) break;
	}

	while(isDefined(level.adding_dbots) || (level.ex_mbot && level.ex_mbot_init)) wait( [[level.ex_fpstime]](1) );

	game["readyup_done"] = true;
	level notify("readyup_done");

	levelHudSetColor(hud_index, (1,1,1));
	levelHudSetLabel(hud_index, &"READYUP_MATCH_BEGINS");
	levelHudSetTimer(hud_index, level.ex_readyup_gtsd);
	wait( [[level.ex_fpstime]](level.ex_readyup_gtsd - 1) );
	levelHudDestroy(hud_index);

	restartMap();
}

levelReadyup()
{
	level endon("ex_gameover");

	hud_index = levelHudCreate("readyup_text", undefined, 320, 100, 1, (0,1,0), 2, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetLabel(hud_index, &"READYUP_READYUP");

	hud_index = levelHudCreate("readyup_waitingfor", undefined, 300, 120, 1, (1,1,1), 1.3, 0, "fullscreen", "fullscreen", "right", "middle", false, false);
	if(hud_index != -1) levelHudSetText(hud_index, &"READYUP_WAITING_FOR");

	hud_index = levelHudCreate("readyup_playernumb", undefined, 320, 120, 1, (1,0,0), 2, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetValue(hud_index, 2);

	hud_index = levelHudCreate("readyup_moreplayers", undefined, 340, 120, 1, (1,1,1), 1.3, 0, "fullscreen", "fullscreen", "left", "middle", false, false);
	if(hud_index != -1) levelHudSetText(hud_index, &"READYUP_MORE_PLAYERS");

	hud_index = levelHudCreate("readyup_timer", undefined, 320, 140, 0, (1,1,1), 2, 0, "fullscreen", "fullscreen", "center", "middle", false, false);

	timer = 0;
	timer_started = false;
	level.ex_readyup_status = 1;

	while(level.ex_readyup_status != 2)
	{
		wait( [[level.ex_fpstime]](1) );

		if(level.ex_readyup_timer && timer_started)
		{
			timer++;
			if(timer >= level.ex_readyup_timer) level.ex_readyup_status = 2;
		}

		players = level.players;
		if(players.size == 0) continue;

		ready = 0;
		ready_allies = 0;
		ready_axis = 0;
		notready = 0;
		notready_allies = 0;
		notready_axis = 0;

		if(level.ex_teamplay) waitingfor = level.ex_readyup_minteam * 2;
			else waitingfor = level.ex_readyup_min;

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			readyup_id = player getEntityNumber();
			if(isDefined(level.ex_readyup_players[readyup_id]))
			{
				if(level.ex_readyup_players[readyup_id].status == "ready")
				{
					ready++;
					if(level.ex_teamplay && isDefined(player.pers["team"]))
					{
						if(player.pers["team"] == "allies") ready_allies++;
							else if(player.pers["team"] == "axis") ready_axis++;
					}
				}
				else if(level.ex_readyup_players[readyup_id].status == "notready")
				{
					notready++;
					if(level.ex_teamplay && isDefined(player.pers["team"]))
					{
						if(player.pers["team"] == "allies") notready_allies++;
							else if(player.pers["team"] == "axis") notready_axis++;
					}
				}
			}
		}

		if((ready + notready) > 0)
		{
			// At least one player spawned
			timer_start = false;

			if(level.ex_teamplay)
			{
				// If team based match, a minimum number of players per team must be ready
				if(ready_allies < level.ex_readyup_minteam) waitingfor_allies = level.ex_readyup_minteam - ready_allies;
					else waitingfor_allies = 0;
				if(ready_axis < level.ex_readyup_minteam) waitingfor_axis = level.ex_readyup_minteam - ready_axis;
					else waitingfor_axis = 0;
				waitingfor = waitingfor_allies + waitingfor_axis;
				if(waitingfor == 0) level.ex_readyup_status = 2;

				// Check if timer is needed
				if(level.ex_readyup_timer)
				{
					// Mode 2: start timer if the minimum number of players per team spawned (ready or not)
					if(level.ex_readyup_timermode == 2)
					{
						if( ((ready_allies + notready_allies) >= level.ex_readyup_minteam) && ((ready_axis + notready_axis) >= level.ex_readyup_minteam) )
							timer_start = true;
					}
					// Mode 1: start timer if at least one player per team spawned (ready or not)
					else if(level.ex_readyup_timermode == 1)
					{
						if( ((ready_allies + notready_allies) >= 1) && ((ready_axis + notready_axis) >= 1) )
							timer_start = true;
					}
					// Mode 0: start timer if at least one player spawned (any team; ready or not)
					else
					{
						if( (ready + notready) >= 1 )
							timer_start = true;
					}
				}
			}
			else
			{
				// If not team based match, a minimum number of players must be ready
				if(ready < level.ex_readyup_min) waitingfor = level.ex_readyup_min - ready;
					else waitingfor = 0;
				if(waitingfor == 0) level.ex_readyup_status = 2;

				// If timer enabled, start it
				if(level.ex_readyup_timer) timer_start = true;
			}

			// Start timer if enabled, needed and not started yet
			if(level.ex_readyup_timer && timer_start && !timer_started)
			{
				levelHudSetTimer("readyup_timer", level.ex_readyup_timer);
				levelHudSetAlpha("readyup_timer", 1);
				timer = 0;
				timer_started = true;
			}
		}
		else
		{
			// Players left. Stop timer if enabled and started
			if(level.ex_readyup_timer && timer_started)
			{
				levelHudSetAlpha("readyup_timer", 0);
				timer = 0;
				timer_started = false;
			}
		}

		levelHudSetValue("readyup_playernumb", waitingfor);
	}

	while(isDefined(level.adding_dbots) || (level.ex_mbot && level.ex_mbot_init)) wait( [[level.ex_fpstime]](1) );

	game["readyup_done"] = true;
	level notify("readyup_done");

	levelHudDestroy("readyup_waitingfor");
	levelHudDestroy("readyup_playernumb");
	levelHudDestroy("readyup_moreplayers");

	// Set spawn flag for all players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		readyup_id = player getEntityNumber();
		if(isDefined(level.ex_readyup_players[readyup_id]))
		{
			if(level.ex_readyup_players[readyup_id].status == "ready")
			{
				player.pers["readyup_spawnticket"] = 1;
			}
			else if(level.ex_readyup_players[readyup_id].status == "notready")
			{
				switch(level.ex_readyup_ticketing)
				{
					case 0:
						player.pers["readyup_spawnticket"] = 1;
						break;
					case 1:
						player.pers["readyup_spawnticket"] = undefined;
						player thread moveToSpectators();
						break;
					case 2:
						player.pers["readyup_spawnticket"] = undefined;
						player thread moveToSpectators();
						break;
				}
			}
		}
	}

	// Announce match start and restart map
	levelHudSetLabel("readyup_timer", &"READYUP_MATCH_BEGINS");
	levelHudSetTimer("readyup_timer", 5);
	wait( [[level.ex_fpstime]](4) );
	levelHudDestroy("readyup_timer");
	levelHudDestroy("readyup_text");

	restartMap();
}

playerReadyup(readyup_id)
{
	level endon("ex_gameover");
	self endon("disconnect");

	self notify("readyup_end");
	waittillframeend;
	self endon("readyup_end");

	/*
	if(getsubstr(self.name, 0, 3) == "bot")
	{
		if(self.name != "bot1")
		{
			level.ex_readyup_players[readyup_id].status = "ready";
			playerHudSetStatusIcon("hud_status_ready");
			return;
		}
	}
	*/

	hud_index = playerHudCreate("readyup_mystatus", 320, 430, 1, (1,1,1), 1.3, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetText(hud_index, &"READYUP_NOTREADY");

	hud_index = playerHudCreate("readyup_howto", 320, 445, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetText(hud_index, &"READYUP_HOWTO");

	while(level.ex_readyup_status != 2)
	{
		if(isPlayer(self) && self useButtonPressed())
		{
			if(level.ex_readyup_players[readyup_id].status == "notready")
			{
				level.ex_readyup_players[readyup_id].status = "ready";
				playerHudSetStatusIcon("hud_status_ready");
				playerHudSetText("readyup_mystatus", &"READYUP_READY");
			}
			else if(level.ex_readyup_players[readyup_id].status == "ready")
			{
				level.ex_readyup_players[readyup_id].status = "notready";
				playerHudSetStatusIcon("hud_status_notready");
				playerHudSetText("readyup_mystatus", &"READYUP_NOTREADY");
			}
			while(isPlayer(self) && self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		}
		else wait( [[level.ex_fpstime]](0.05) );
	}

	playerHudDestroy("readyup_mystatus");
	playerHudDestroy("readyup_howto");
}

levelGracePeriod()
{
	barwidth = 300;

	hud_index = levelHudCreate("readyup_graceback", undefined, 320, 10, 0.3, (0.2,0.2,0.2), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetShader(hud_index, "white", barwidth + 4, 13);

	hud_index = levelHudCreate("readyup_gracefront", undefined, 320, 10, 0.5, (0,1,0), 1, 2, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetShader(hud_index, "white", barwidth, 11);

	hud_index = levelHudCreate("readyup_gracetext", undefined, 320, 10, 0.8, (1,1,1), 1, 3, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetText(hud_index, &"READYUP_GRACE_PERIOD");

	level.ex_readyup_graceinit = true;
	timer = level.ex_readyup_graceperiod;
	oldbarwidth = barwidth;

	while(level.ex_readyup_status != 4)
	{
		timer--;
		perc = timer / level.ex_readyup_graceperiod;
		width = int((barwidth * perc) + 0.5);
		if(width < 1) width = 1;
		if(oldbarwidth != width)
		{
			levelHudScale("readyup_gracefront", 1, 0, width, 11);
			oldbarwidth = width;
		}

		wait( [[level.ex_fpstime]](1) );
		if(timer == 0) level.ex_readyup_status = 4;
	}

	levelHudDestroy("readyup_gracetext");
	levelHudDestroy("readyup_gracefront");
	levelHudDestroy("readyup_graceback");
}

moveToSpectators()
{
	self notify("kill_thread");
	self notify("killed_player");
	wait( [[level.ex_fpstime]](0.1) );
	self.pers["team"] = "spectator";
	self.sessionteam = "spectator";
	self thread extreme\_ex_clientcontrol::clearWeapons();
	self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();
	self thread extreme\_ex_spawn::spawnspectator();
}

waitForNextRound()
{
	hud_index = playerHudCreate("readyup_nextround", 320, 100, 1, (1,1,1), 1.3, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetText(hud_index, &"READYUP_WAIT_FOR_NEXT_ROUND");
}

restartMap()
{
	//level.starttime = getTime();
	level notify("restarting");
	wait( [[level.ex_fpstime]](1) );
	map_restart(true);
}
