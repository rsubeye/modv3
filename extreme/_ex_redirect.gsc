#include extreme\_ex_hudcontroller;

init()
{
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
}

onPlayerConnected()
{
	// Exclude bots from redirect logic
	if(isDefined(self.pers["isbot"])) return;

	// Allow clan 1 members to play
	//if(isDefined(self.ex_name) && isDefined(self.ex_clid) && self.ex_clid == 1) continue;

	// Force downloads on
	self setClientCvar("cl_allowDownload", 1);

	switch(level.ex_redirect_reason)
	{
		case 0: {
			// FULL SERVER: redirect connecting players if server is full
			// If redirect priority mode is on, non-clan players or players without
			// priority status have to give up their slot for clan players
			if(isFullServer() && !isPriorityPlayer(self)) self thread redirectPlayer(0);
			break;
		}
		case 1: {
			// PRIVATE SERVER: redirect non-clan players
			// No priority status check here. All known clans are accepted
			if(!isPriorityClan(self, 4)) self thread redirectPlayer(1);
				else if(isFullServer()) self thread redirectPlayer(0);
			break;
		}
		case 2: {
			// OLD SERVER: redirect all connecting players
			self thread redirectPlayer(2);
			break;
		}
		case 3: {
			// IS BEING SERVICED: redirect all connecting players
			self thread redirectPlayer(3);
			break;
		}
	}
}

// Check if server is full (depending on logic)
isFullServer()
{
	players = level.players;
	numplayers = players.size - 1; // exclude the connecting player

	fullserver = 1;
	switch(level.ex_redirect_logic)
	{
		case 0: { if(numplayers < level.ex_maxclients - 1) fullserver = 0; break; }
		case 1: { if(numplayers < level.ex_maxclients - level.ex_privateclients) fullserver = 0; break; }
		case 2: { if(numplayers < level.ex_maxclients - level.ex_privateclients - 1) fullserver = 0; break; }
	}

	if(fullserver) return true;
	return false;
}

// Check if player has clan-priority
isPriorityPlayer(player)
{
	if(level.ex_redirect_priority && isPriorityClan(player, level.ex_redirect_priority))
	{
		players = level.players;
		numplayers = players.size;

		lastclan2player = -1; // Last clan2 player without priority status
		lastclan3player = -1; // Last clan3 player without priority status
		lastclan4player = -1; // Last clan4 player without priority status
		lastnonclanplayer = -1; // Last non-clan player

		for(i = 0; i < numplayers; i++)
		{
			if(isPlayer(players[i]) && players[i] != player && !isDefined(players[i].ex_redirected))
			{
				switch(isRedirectCandidate(players[i], level.ex_redirect_priority))
				{
					case 1: { lastnonclanplayer = i; break; }
					case 2: { lastclan2player = i; break; }
					case 3: { lastclan3player = i; break; }
					case 4: { lastclan4player = i; break; }
				}
			}
		}

		if(lastnonclanplayer != -1)
		{
			player thread redirectMonitor(players[lastnonclanplayer]);
			players[lastnonclanplayer] thread RedirectExistingPlayer(player);
			return true;
		}
		else if(lastclan4player != -1)
		{
			player thread redirectMonitor(players[lastclan4player]);
			players[lastclan4player] thread redirectExistingPlayer(player);
			return true;
		}
		else if(lastclan3player != -1)
		{
			player thread redirectMonitor(players[lastclan3player]);
			players[lastclan3player] thread redirectExistingPlayer(player);
			return true;
		}
		else if(lastclan2player != -1)
		{
			player thread redirectMonitor(players[lastclan2player]);
			players[lastclan2player] thread redirectExistingPlayer(player);
			return true;
		}
	}

	return false;
}

// Is connecting player member of priority clan
isPriorityClan(player, mode)
{
	if(isPlayer(player) && isDefined(player.ex_name) && isDefined(player.ex_clid))
		if(player.ex_clid <= mode) return true;
	return false;
}

// Is connecting player member of a priority clan
isRedirectCandidate(player, mode)
{
	if(isPlayer(player))
	{
		if(isDefined(player.pers["isbot"]) && player.pers["isbot"]) return 0; // Bot (not handled)
		if(!isDefined(player.ex_name) && !isDefined(player.ex_clid)) return 1; // Non-clan
		if(player.ex_clid > mode) return player.ex_clid; // Clan 2, 3, or 4
	}
	return 0; // Clan 1
}

// Close menus and activate spectator mode
prepareNewPlayer()
{
	while(!isDefined(self.pers["team"])) wait( [[level.ex_fpstime]](.05) );
	wait( [[level.ex_fpstime]](.5) );

	self setClientCvar("g_scriptMainMenu", "");
	self closeMenu();
	self closeInGameMenu();

	self extreme\_ex_spawn::spawnSpectator();
	self allowSpectateTeam("allies", false);
	self allowSpectateTeam("axis", false);
	self allowSpectateTeam("freelook", false);
	self allowSpectateTeam("none", true);
}

// Manage redirect. Put clan player on hold until other player is redirected
redirectMonitor(playertomonitor)
{
	self endon("disconnect");

	self prepareNewPlayer();
	self createHUD(5, false);

	for(i = level.ex_redirect_pause + 2; i >= 0; i--) wait( [[level.ex_fpstime]](1) );

	if(isPlayer(playertomonitor))
	{
		playertomonitor setClientCvar("com_errorTitle", "eXtreme+ Message");
		playertomonitor setClientCvar("com_errorMessage", "You have been disconnected from the server\nto make room for a clan member!\nYou can try to reconnect to our server later.\nSorry for the inconvenience!");
		wait( [[level.ex_fpstime]](1) );
		playertomonitor thread extreme\_ex_utils::execClientCommand("disconnect");
	}

	self fadeHUD();
	self deleteHUD();

	scriptMainMenu = game["menu_ingame"];
	self openMenu(game["menu_serverinfo"]);
	self setClientCvar("g_scriptMainMenu", scriptMainMenu);
}

// Handle player redirection
redirectPlayer(reason)
{
	self endon("disconnect");

	self.ex_redirected = true;
	self prepareNewPlayer();
	self createHUD(reason, true);
	for (i = level.ex_redirect_pause; i >= 0; i--)
	{
		playerHudSetValue("redirect_timer", i);
		wait( [[level.ex_fpstime]](1) );
	}

	self fadeHUD();
	self deleteHUD();

	self thread extreme\_ex_utils::execClientCommand("connect " + level.ex_redirect_ip);
}

// Handle other player redirection
redirectExistingPlayer(playertonotify)
{
	self endon("disconnect");

	self.ex_redirected = true;

	self createHUD(4, true);
	for (i = level.ex_redirect_pause; i >= 0; i--)
	{
		playerHudSetValue("redirect_timer", i);
		if(!isPlayer(playertonotify))
		{
			playerHudSetLabel("redirect_reason", &"REDIRECT_CLAN_ABORTED");
			playerHudSetLabel("redirect_to", &"REDIRECT_CLAN_CONTINUE");
			if(level.ex_redirect_hint) playerHudSetLabel("redirect_hint", &"REDIRECT_HINT_PRIORITY");
			self.ex_redirected = undefined;
			wait( [[level.ex_fpstime]](5) );
			break;
		}
		else wait( [[level.ex_fpstime]](1) );
	}

	self fadeHUD();
	self deleteHUD();

	if(isDefined(self.ex_redirected))
		self thread extreme\_ex_utils::execClientCommand("connect " + level.ex_redirect_ip);
}

// Create HUD elements
createHUD(reason, showtimer)
{
	// Background
	hud_index = playerHudCreate("redirect_back", 120, 120, 0.7, (0,0,0), 1, 100, "subleft", "subtop", "left", "top", false, false);
	if(hud_index != -1) playerHudSetShader(hud_index, "white", 400, 115);

	// Title bar
	hud_index = playerHudCreate("redirect_titlebar", 123, 122, 0.3, (1,1,1), 1, 101, "subleft", "subtop", "left", "top", false, false);
	if(hud_index != -1) playerHudSetShader(hud_index, "white", 395, 21);

	// Title
	hud_index = playerHudCreate("redirect_title", 125, 125, 1, (1,1,1), 1.3, 102, "subleft", "subtop", "left", "top", false, false);
	if(hud_index != -1) playerHudSetLabel(hud_index, &"REDIRECT_TITLE");

	// Separator
	hud_index = playerHudCreate("redirect_sep", 123, 215, 0.3, (1,1,1), 1, 102, "subleft", "subtop", "left", "top", false, false);
	if(hud_index != -1) playerHudSetShader(hud_index, "white", 395, 1);

	// Reason
	hud_index = playerHudCreate("redirect_reason", 320, 165, 1, (1,1,1), 1.2, 102, "subleft", "subtop", "center", "middle", false, false);
	if(hud_index != -1)
	{
		switch(reason)
		{
			case 0: { playerHudSetLabel(hud_index, &"REDIRECT_REASON_ISFULL"); break; }
			case 1: { playerHudSetLabel(hud_index, &"REDIRECT_REASON_ISPRIVATE"); break; }
			case 2: { playerHudSetLabel(hud_index, &"REDIRECT_REASON_ISOLD"); break; }
			case 3: { playerHudSetLabel(hud_index, &"REDIRECT_REASON_ISSERVICED"); break; }
			case 4: { playerHudSetLabel(hud_index, &"REDIRECT_REASON_CLANPRIORITY"); break; }
			case 5: { playerHudSetLabel(hud_index, &"REDIRECT_CLAN_FREEUPSLOT"); break; }
		}
	}

	// Redirect to
	hud_index = playerHudCreate("redirect_to", 320, 185, 1, (1,1,1), 1.2, 102, "subleft", "subtop", "center", "middle", false, false);
	if(hud_index != -1)
	{
		switch(reason)
		{
			case 0: { playerHudSetLabel(hud_index, &"REDIRECT_TO_OTHERSERVER"); break; }
			case 1: { playerHudSetLabel(hud_index, &"REDIRECT_TO_PUBLICSERVER"); break; }
			case 2: { playerHudSetLabel(hud_index, &"REDIRECT_TO_NEWSERVER"); break; }
			case 3: { playerHudSetLabel(hud_index, &"REDIRECT_TO_OTHERSERVER"); break; }
			case 4: { playerHudSetLabel(hud_index, &"REDIRECT_TO_OTHERSERVER"); break; }
			case 5: { playerHudSetLabel(hud_index, &"REDIRECT_CLAN_PLEASEWAIT"); break; }
		}
	}

	// Hint
	if(level.ex_redirect_hint)
	{
		hud_index = playerHudCreate("redirect_hint", 320, 200, 1, (1,1,1), 1, 102, "subleft", "subtop", "center", "middle", false, false);
		if(hud_index != -1)
		{
			switch(reason)
			{
				case 0: { playerHudSetLabel(hud_index, &"REDIRECT_HINT_VISITWEBSITE"); break; }
				case 1: { playerHudSetLabel(hud_index, &"REDIRECT_HINT_VISITWEBSITE"); break; }
				case 2: { playerHudSetLabel(hud_index, &"REDIRECT_HINT_ADDTOFAV"); break; }
				case 3: { playerHudSetLabel(hud_index, &"REDIRECT_HINT_VISITWEBSITE"); break; }
				case 4: { playerHudSetLabel(hud_index, &"REDIRECT_HINT_SORRY"); break; }
				case 5: { playerHudSetLabel(hud_index, &"REDIRECT_HINT_EXTREME"); break; }
			}
		}
	}

	// Timer
	if(showtimer)
	{
		hud_index = playerHudCreate("redirect_timer", 123, 220, 1, (1,1,1), 1, 102, "subleft", "subtop", "left", "top", false, false);
		if(hud_index != -1) playerHudSetLabel(hud_index, &"REDIRECT_TIMELEFT");
	}
}

// Fade all HUD elements
fadeHUD()
{
	playerHudFade("redirect_timer", 1, 0, 0);
	playerHudFade("redirect_hint", 1, 0, 0);
	playerHudFade("redirect_to", 1, 0, 0);
	playerHudFade("redirect_reason", 1, 0, 0);
	playerHudFade("redirect_sep", 1, 0, 0);
	playerHudFade("redirect_title", 1, 0, 0);
	playerHudFade("redirect_titlebar", 1, 0, 0);
	playerHudFade("redirect_back", 1, 0, 0);
	wait( [[level.ex_fpstime]](1) );
}

// Destroy all HUD elements
deleteHUD()
{
	playerHudDestroy("redirect_timer");
	playerHudDestroy("redirect_hint");
	playerHudDestroy("redirect_to");
	playerHudDestroy("redirect_reason");
	playerHudDestroy("redirect_sep");
	playerHudDestroy("redirect_title");
	playerHudDestroy("redirect_titlebar");
	playerHudDestroy("redirect_back");
}
