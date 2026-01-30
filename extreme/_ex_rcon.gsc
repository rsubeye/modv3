
rconMain(command)
{
	self endon("disconnect");

	// Check authorization
	if(!rconIsAuthorizedFor(0))
	{
		rconSvrResponse(5);
		return;
	}

	// Catch pin entry commands for RCON Main Menu
	rcon_pin_entry = 999;
	for(i = 0; i <= 9; i++)
	{
		if(command == "rcon_cmd_pin" + i)
		{
			rcon_pin_entry = i;
			command = "rcon_cmd_pin";
			break;
		}
	}

	// Handle other commands for RCON Main Menu
	switch(command)
	{
		case "rcon_cmd_main":
		{
			// Exclude player from inactivity monitor
			self.pers["dontkick"] = true;
			if(self.ex_rcon_authorized == 2) thread rconResetLoginInfo();
			break;
		}
		case "rcon_cmd_pin":
		{
			//logprint("EXTREME RCON: player " + self.name + " sent PIN number " + rcon_pin_entry + ".\n");
			self.ex_rcon_pin_entry += rcon_pin_entry;
			self setClientCvar("ui_rconExtremeLogin", self.ex_rcon_pin_entry);
			break;
		}
		case "rcon_cmd_pinenter":
		{
			if(self.ex_rcon_authorized == 0 && self.ex_rcon_pin_entry != "")
			{
				logprint("EXTREME RCON: player " + self.name + " submitted PIN \"" + self.ex_rcon_pin_entry +"\" for validation.\n");
				if(self.ex_rcon_pin_entry == self.ex_rcon_pin)
				{
					self playlocalsound("access_granted");
					logprint("EXTREME RCON: player " + self.name + ": AUTHORIZED.\n");
					rconAuthorizeLogin();
					thread rconLoginTimeframe(5);
				}
				else
				{
					self playlocalsound("access_denied");
					logprint("EXTREME RCON: player " + self.name + ": INVALID PIN.\n");
					rconLoginFalsePIN();
				}
			}

			self.ex_rcon_pin_entry = "";
			break;
		}
		case "rcon_cmd_pinclear":
		{
			//logprint("EXTREME RCON: player " + self.name + " cleared PIN.\n");
			self.ex_rcon_pin_entry = "";
			break;
		}
		case "rcon_cmd_login":
		{
			logprint("EXTREME RCON: player " + self.name + ": LOGGED IN.\n");
			rconAuthorizeAccess();
			thread rconResetLoginInfo();
			break;
		}
	}
}

// *****************************************************************************
// Map Control
// *****************************************************************************

rconMapCtrl(command)
{
	self endon("disconnect");

	// Check authorization
	if(!rconIsAuthorizedFor(1))
	{
		rconSvrResponse(5);
		return;
	}

	// Catch map commands for Map Control
	for(i = 1; i <= 64; i++)
	{
		if(command == "rcon_cmd_map" + i)
		{
			self.ex_rcon_map = i;
			command = "rcon_cmd_map";
			break;
		}
	}

	// Catch action commands for Map Control
	for(i = 1; i <= 7; i++)
	{
		if(command == "rcon_cmd_action" + i)
		{
			self.ex_rcon_action = i;
			command = "rcon_cmd_action";
			break;
		}
	}

	// Handle commands for Map Control
	switch(command)
	{
		case "rcon_cmd_mapctrl":
		{
			self.ex_rcon_map = 999; // rcon_cmd_mapX (numb), rcon_rsp_mapX (name)
			self.ex_rcon_timeext = rconInitTimeLimit(); // rcon_cmd_timelimit, rcon_rsp_timelimit
			self.ex_rcon_scoreext = rconInitScoreLimit(); // rcon_cmd_scorelimit, rcon_rsp_scorelimit
			self.ex_rcon_roundext = rconInitRoundLimit(); // rcon_cmd_roundlimit, rcon_rsp_roundlimit
			self.ex_rcon_gametype = 0; // rcon_cmd_gametype, rcon_rsp_gametype
			self.ex_rcon_action = level.ex_rcon_mapaction; // rcon_cmd_actionX, rcon_rsp_action

			self setClientCvar("rcon_rsp_map", self.ex_rcon_map);
			self setClientCvar("rcon_rsp_timelimit", self.ex_rcon_timeext);
			self setClientCvar("rcon_rsp_scorelimit", self.ex_rcon_scoreext);
			self setClientCvar("rcon_rsp_roundlimit", self.ex_rcon_roundext);
			self setClientCvar("rcon_rsp_gametype", self.ex_rcon_gametype);
			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			self setClientCvar("rcon_rsp_apply", 0);
			self setClientCvar("ui_rconExtremeCmd", "rcon set exrcon 1");

			// disable fast restart if weapon mode is set (client mode)
			blockfast = 0;
			if(level.ex_rcon_mode == 0)
			{
				weaponmode = undefined;
				if(!isDefined(game["weaponmode"]))
				{
					weaponmode_str = getCvar("ex_weaponmode");
					if(weaponmode_str != "" && rconIsNumber(weaponmode_str)) weaponmode = getCvarInt("ex_weaponmode");
				}
				else weaponmode = int(game["weaponmode"]);
				if(isDefined(weaponmode) && weaponmode != 100) blockfast = 1;
			}
			self setClientCvar("rcon_rsp_blockfast", blockfast);

			// No need to transmit map names. They are already transmitted by _ex_cvarcontroller.gsc
			break;
		}
		case "rcon_cmd_map":
		{
			self setClientCvar("rcon_rsp_map", self.ex_rcon_map);
			rconMapAction();
			break;
		}
		case "rcon_cmd_timelimit":
		{
			if(self.ex_rcon_timeext != -1)
			{
				self.ex_rcon_timeext = rconGetIntNext(self.ex_rcon_timeext, 0, 30);
				self setClientCvar("rcon_rsp_timelimit", self.ex_rcon_timeext);

				// WARNING: set the action manually, because it is initiated by
				// the timelimit command, not the action command.
				self.ex_rcon_action = 8;
				self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
				rconMapAction();
			}
			else
			{
				rconSvrResponse(6);
				return;
			}
			break;
		}
		case "rcon_cmd_scorelimit":
		{
			if(self.ex_rcon_scoreext != -1)
			{
				increment = level.ex_points_kill * 10;
				self.ex_rcon_scoreext = rconGetIntNext(self.ex_rcon_scoreext, 0, 99999, increment);
				self setClientCvar("rcon_rsp_scorelimit", self.ex_rcon_scoreext);

				// WARNING: set the action manually, because it is initiated by
				// the scorelimit command, not the action command.
				self.ex_rcon_action = 9;
				self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
				rconMapAction();
			}
			else
			{
				rconSvrResponse(6);
				return;
			}
			break;
		}
		case "rcon_cmd_roundlimit":
		{
			if(self.ex_rcon_roundext != -1)
			{
				increment = 1;
				if(level.ex_currentgt == "esd" || level.ex_currentgt == "lts" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "sd")
				{
					if(level.ex_swapteams == 2 && game["roundnumber"] < game["halftimelimit"]) increment = 2;
				}
				self.ex_rcon_roundext = rconGetIntNext(self.ex_rcon_roundext, 0, 99, increment);
				self setClientCvar("rcon_rsp_roundlimit", self.ex_rcon_roundext);

				// WARNING: set the action manually, because it is initiated by
				// the roundlimit command, not the action command.
				self.ex_rcon_action = 10;
				self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
				rconMapAction();
			}
			else
			{
				rconSvrResponse(6);
				return;
			}
			break;
		}
		case "rcon_cmd_gametype":
		{
			self.ex_rcon_gametype = rconGetIntNext(self.ex_rcon_gametype, 0, 22);
			self setClientCvar("rcon_rsp_gametype", self.ex_rcon_gametype);

			// WARNING: set the action manually, because it is initiated by
			// the gametype command, not the action command.
			self.ex_rcon_action = 11;
			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			rconMapAction();
			break;
		}
		case "rcon_cmd_action":
		{
			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			rconMapAction();
			break;
		}
		case "rcon_cmd_apply":
		{
			self setClientCvar("rcon_rsp_apply", 0);
			// Close menu for re-authentication (required after map changes)
			self closeMenu();
			thread rconMapServerAction(self.ex_rcon_action, self.ex_rcon_map, self.ex_rcon_gametype);
			self.ex_rcon_map = 999;
			self setClientCvar("rcon_rsp_map", self.ex_rcon_map);
			break;
		}
		default:
		{
			rconSvrResponse(7);
			return;
		}
	}

	rconSvrResponse(1);
}

rconMapAction()
{
	self endon("disconnect");

	// 1. Change to: map <mapname> (client mode)
	// 2. End: set endmap 1 (needs command monitor) (client and server mode)
	// 3. Fast Restart: fast_restart (client mode), map_restart (server mode)
	// 4. Restart: map_restart (client mode)
	// 5. Rotate: map_rotate (client mode)
	// 6. Play Next: handled by code (server mode)
	// 7. Skip Next: handled by code (server mode)
	// 8. Extend Time Limit: handled by code (client and server mode)
	// 9. Extend Score Limit: handled by code (client and server mode)
	// 10. Extend Round Limit: handled by code (client and server mode)
	// 11. Change Gametype: g_gametype <gt> (client and server mode)

	// x. CallVote: Restart (exec "cmd callvote map_restart") (client mode)
	// x. CallVote: Rotate (exec "cmd callvote map_rotate) (client mode)
	// x. CallVote: Gametype (exec "callvote g_gametype ctf") (client mode)
	// x. CallVote: Map (client side: exec "vstr ui_ingame_vote_map_cmd_1") (client mode)
	//                  (          =  exec "callvote map " + level.ex_maps[i].mapname)

	self setClientCvar("rcon_rsp_apply", 0);

	if(self.ex_rcon_action != 0)
	{
		// make sure game type did not change before doing a fast_restart (client mode) or map_restart (server mode)
		if(self.ex_rcon_action == 3) setCvar("g_gametype", level.ex_currentgt);

		// Define which parameters are needed
		// 0 = none, 1 = map or gametype, 2 = switch
		rcon_paramode = 0;

		switch(self.ex_rcon_action)
		{
			// Actions for which commands MUST be handled by client
			case 1: rcon_action = "map"; rcon_paramode = 1; break;
			case 4: rcon_action = "map_restart"; break;
			case 5: rcon_action = "map_rotate"; break;
			default:
			{
				if(level.ex_rcon_mode == 0)
				{
					// Clientmode: commands are handled by client, unless command MUST be
					// handled by server (in that case set rcon_action to "set exrcon")
					switch(self.ex_rcon_action)
					{
						case 2: rcon_action = "set endmap"; rcon_paramode = 2; break;
						case 3: rcon_action = "fast_restart"; break;
						case 6: rcon_action = "set ex_nextmap"; rcon_paramode = 2; break;
						case 7: rcon_action = "set ex_skipmap"; rcon_paramode = 2; break;
						case 8: rcon_action = "set exrcon"; break; // Extend Time Limit
						case 9: rcon_action = "set exrcon"; break; // Extend Score Limit
						case 10: rcon_action = "set exrcon"; break; // Extend Round Limit
						case 11: rcon_action = "g_gametype"; rcon_paramode = 1; break;
						default: rcon_action = ""; break;
					}
				}
				else
				{
					// Servermode: commands are handled by server
					rcon_action = "set exrcon";
					rcon_paramode = 2;
				}
				break;
			}
		}

		if(rcon_action != "")
		{
			switch(rcon_paramode)
			{
				case 1:
				{
					switch(self.ex_rcon_action)
					{
						case 1:
							if(self.ex_rcon_map != 999 && isDefined(level.ex_maps[self.ex_rcon_map].mapname))
							{
								rcon_map = level.ex_maps[self.ex_rcon_map].mapname;
								logprint("EXTREME RCON: player " + self.name + " changing map to " + rcon_map + ".\n");
								self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action + " " + rcon_map);
								self setClientCvar("rcon_rsp_apply", 1);
							}
							break;
						case 11:
							if(self.ex_rcon_gametype != 0)
							{
								rcon_gt = rconGametype(self.ex_rcon_gametype);
								logprint("EXTREME RCON: player " + self.name + " changing game type to " + rcon_gt + ".\n");
								self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action + " " + rcon_gt);
								self setClientCvar("rcon_rsp_apply", 1);
							}
							break;
					}
					break;
				}
				case 2:
				{
					switch(self.ex_rcon_action)
					{
						case 2:
							logprint("EXTREME RCON: player " + self.name + " ending current map.\n");
							self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action + " " + self.ex_rcon_action);
							self setClientCvar("rcon_rsp_apply", 1);
							break;
						case 6:
							if(self.ex_rcon_map != 999 && isDefined(level.ex_maps[self.ex_rcon_map].mapname))
							{
								rcon_map = level.ex_maps[self.ex_rcon_map].mapname;
								logprint("EXTREME RCON: player " + self.name + " changing next map to " + rcon_map + ".\n");
								self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action + " " + rcon_map);
								self setClientCvar("rcon_rsp_apply", 1);
							}
							break;
						case 7:
							logprint("EXTREME RCON: player " + self.name + " skipping next map.\n");
							self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action + " " + self.ex_rcon_action);
							self setClientCvar("rcon_rsp_apply", 1);
							break;
						default:
							// catch server commands
							self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action + " " + self.ex_rcon_action);
							self setClientCvar("rcon_rsp_apply", 1);
							break;
					}
					break;
				}
				default:
				{
					if(rcon_action != "set exrcon") logprint("EXTREME RCON: player " + self.name + " doing a " + rcon_action + ".\n");
					self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action);
					self setClientCvar("rcon_rsp_apply", 1);
					break;
				}
			}
		}
		else rconSvrResponse(6);
	}
}

rconMapServerAction(action, map, gametype)
{
	if(!rconMapIsServerAction(action)) return;

	//logprint("EXTREME RCON: action " + action + " executed by server\n");

	switch(action)
	{
		case 2: thread extreme\_ex_cmdmonitor::endMap(); break;
		case 3: map_restart(true); break;
		case 6: setCvar("ex_nextmap", level.ex_maps[map].mapname); break;
		case 7: setCvar("ex_skipmap", action); break;
		case 8: rconExtendTimeLimit(); break;
		case 9: rconExtendScoreLimit(); break;
		case 10: rconExtendRoundLimit(); break;
		case 11: setCvar("g_gametype", rconGametype(gametype)); break;
	}
}

rconMapIsServerAction(action)
{
	// Reminder: all "set exrcon" actions are handled by server
	if(level.ex_rcon_mode == 0)
	{
		// Clientmode: return true for actions which MUST be executed by server, false for other actions
		switch(action)
		{
			case 8:
			case 9:
			case 10:
				return true;
			default:
				return false;
		}
	}
	else
	{
		// Servermode: return false for actions which MUST be executed by client, true for other actions
		switch(action)
		{
			case 1:
			case 4:
			case 5:
				return false;
			default:
				return true;
		}
	}
}

rconInitTimeLimit()
{
	if(!game["timelimit"]) return(-1);
	return(0);
}

rconInitScoreLimit()
{
	if(!game["scorelimit"]) return(-1);
	return(0);
}

rconInitRoundLimit()
{
	if(!level.ex_roundbased) return(-1);
	return(0);
}

rconExtendTimeLimit()
{
	timelimit = game["timelimit"] + self.ex_rcon_timeext;
	setCvar("scr_" + level.ex_currentgt + "_timelimit", timelimit);
}

rconExtendScoreLimit()
{
	scorelimit = game["scorelimit"] + self.ex_rcon_scoreext;
	setCvar("scr_" + level.ex_currentgt + "_scorelimit", scorelimit);
}

rconExtendRoundLimit()
{
	if(!level.ex_roundbased) return;
	roundlimit = game["roundlimit"] + self.ex_rcon_roundext;
	setCvar("scr_" + level.ex_currentgt + "_roundlimit", roundlimit);
}

// *****************************************************************************
// Player Control
// *****************************************************************************

rconPlayerCtrl(command)
{
	self endon("disconnect");

	// Check authorization
	if(!rconIsAuthorizedFor(2))
	{
		rconSvrResponse(5);
		return;
	}

	// Catch player commands for Player Control (0 - 63)
	for(i = 0; i < 64; i++)
	{
		if(command == "rcon_cmd_player" + i)
		{
			self.ex_rcon_player = i;
			command = "rcon_cmd_player";
			break;
		}
	}

	// Catch action commands for Player Control
	for(i = 1; i <= 20; i++)
	{
		if(command == "rcon_cmd_action" + i)
		{
			self.ex_rcon_action = i;
			command = "rcon_cmd_action";
			break;
		}
	}

	// Handle other commands for Player Control
	switch(command)
	{
		case "rcon_cmd_playerctrl":
		{
			self.ex_rcon_player = 999; // rcon_cmd_player, rcon_rsp_player
			self.ex_rcon_team = 0; // rcon_cmd_team, rcon_rsp_team
			self.ex_rcon_action = level.ex_rcon_playeraction; // rcon_cmd_actionX, rcon_rsp_action
			self.ex_rcon_model = level.ex_rcon_playermodel; // rcon_cmd_model, rcon_rsp_model
			self.ex_rcon_truncate = level.ex_rcon_truncate; // rcon_cmd_truncate
			self.ex_rcon_color = level.ex_rcon_color; // rcon_cmd_color

			self setClientCvar("rcon_rsp_player", self.ex_rcon_player);
			self setClientCvar("rcon_rsp_team", self.ex_rcon_team);
			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			self setClientCvar("rcon_rsp_model", self.ex_rcon_model);
			self setClientCvar("rcon_rsp_truncate", self.ex_rcon_truncate);
			self setClientCvar("rcon_rsp_color", self.ex_rcon_color);
			self setClientCvar("rcon_rsp_apply", 0);
			self setClientCvar("ui_rconExtremeCmd", "rcon set exrcon 1");

			rconPlayerSlots();
			break;
		}
		case "rcon_cmd_playerctrl_cleanup":
		{
			if(!isDefined(level.ex_rcon_maxplayers)) return;
			for(i = 0; i < level.ex_rcon_maxplayers; i++) self setClientCvar("rcon_rsp_player" + i, "");
			return;
		}
		case "rcon_cmd_player":
		{
			self setClientCvar("rcon_rsp_player", self.ex_rcon_player);
			if(self.ex_rcon_player != -1)
			{
				player = getEntityByNumber(self.ex_rcon_player);
				if(isDefined(player)) self.ex_rcon_playername = player.name;
			}
			rconPlayerAction();
			break;
		}
		case "rcon_cmd_playerall":
		{
			self.ex_rcon_player = -1;
			self setClientCvar("rcon_rsp_player", self.ex_rcon_player);
			self.ex_rcon_playername = undefined;
			// If "All Players" selected, remove team selection
			if(self.ex_rcon_team != 0)
			{
				self.ex_rcon_team = 0;
				self setClientCvar("rcon_rsp_team", self.ex_rcon_team);
				rconPlayerTeam();
			}
			rconPlayerAction();
			break;
		}
		case "rcon_cmd_action":
		{
			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			rconPlayerAction();
			break;
		}
		case "rcon_cmd_team":
		{
			self.ex_rcon_team = rconGetIntNext(self.ex_rcon_team, 0, 2);
			self setClientCvar("rcon_rsp_team", self.ex_rcon_team);
			rconPlayerTeam();
			break;
		}
		case "rcon_cmd_model":
		{
			self.ex_rcon_model = rconGetIntNext(self.ex_rcon_model, 0, 7);
			//self setClientCvar("rcon_rsp_model", self.ex_rcon_model);

			// WARNING: set the action manually, because it is initiated by
			// the model command, not the action command.
			self.ex_rcon_action = 19;
			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			rconPlayerAction();
			break;
		}
		case "rcon_cmd_color":
		{
			self.ex_rcon_color = rconGetIntNext(self.ex_rcon_color, 0, 1);
			rconPlayerSlots();
			break;
		}
		case "rcon_cmd_truncate":
		{
			self.ex_rcon_truncate = rconGetIntNext(self.ex_rcon_truncate, 0, 1);
			rconPlayerSlots();
			break;
		}
		case "rcon_cmd_apply":
		{
			self setClientCvar("rcon_rsp_apply", 0);
			thread rconPlayerServerAction(self.ex_rcon_action, self.ex_rcon_player, self.ex_rcon_team);

			if(isDefined(self.ex_rcon_playername) && self.ex_rcon_player != -1)
			{
				switch(self.ex_rcon_action)
				{
					case  2: //banClient
						thread rconDelayedSay("player " + self.ex_rcon_playername + "^7 (" + self.ex_rcon_player + ") perma-banned by " + self.name);
						break;
					case  5: //clientkick
						thread rconDelayedSay("player " + self.ex_rcon_playername + "^7 (" + self.ex_rcon_player + ") kicked by " + self.name);
						break;
					case 13: //tempBanClient
						thread rconDelayedSay("player " + self.ex_rcon_playername + "^7 (" + self.ex_rcon_player + ") temp-banned by " + self.name);
						break;
				}
			}

			self.ex_rcon_player = 999;
			self setClientCvar("rcon_rsp_player", self.ex_rcon_player);
			self.ex_rcon_team = 0;
			self setClientCvar("rcon_rsp_team", self.ex_rcon_team);
			break;
		}
		default:
		{
			rconSvrResponse(7);
			return;
		}
	}

	rconSvrResponse(1);
}

rconPlayerSlots()
{
	self endon("disconnect");

	players = level.players;
	level.ex_rcon_maxplayers = players.size;
	for(i = 0; i < level.ex_rcon_maxplayers; i++)
	{
		player = players[i];

		if(!self.ex_rcon_color) entName = extreme\_ex_utils::monotone(player.name);
			else entName = player.name;

		if(self.ex_rcon_truncate) entName = rconTruncate(entName, 19);

		entID = player getEntityNumber();
		self setClientCvar("rcon_rsp_player" + entID, entName);
	}
}

rconPlayerName(requestID)
{
	players = level.players;

	for(i = 0; i < level.ex_rcon_maxplayers; i++)
	{
		player = players[i];
		entID = player getEntityNumber();
		if(entID == requestID) return player.name;
	}
}

rconPlayerAction()
{
	self endon("disconnect");

	self setClientCvar("rcon_rsp_apply", 0);

	if(isDefined(self.ex_rcon_player) && self.ex_rcon_player != 999 && self.ex_rcon_action != 0)
	{
		rcon_allowall = true;

		switch(self.ex_rcon_action)
		{
			// Actions for which commands MUST be handled by client
			case  2: rcon_action = "banClient"; rcon_allowall = false; break; //banClient, banUser, dumpuser
			case  5: rcon_action = "clientkick"; rcon_allowall = false; break; //clientkick, onlykick, kick
			case 13: rcon_action = "tempBanClient"; rcon_allowall = false; break; //tempBanClient, tempBanUser

			// Actions for model changing are handled separately
			case 19: rconPlayerModels(); return; // Action = change model
			default:
			{
				if(level.ex_rcon_mode == 0)
				{
					// Clientmode: commands are handled by client, unless command MUST be
					// handled by server (in that case set rcon_action to "set exrcon")
					switch(self.ex_rcon_action)
					{
						case  1: rcon_action = "set arty"; break;
						case  3: rcon_action = "set silence"; break;
						case  4: rcon_action = "set fire"; break;
						case  6: rcon_action = "set lock"; break;
						case  7: rcon_action = "set smite"; break;
						case  8: rcon_action = "set spank"; break;
						case  9: rcon_action = "set suicide"; break;
						case 10: rcon_action = "set switchplayerallies"; break;
						case 11: rcon_action = "set switchplayeraxis"; break;
						case 12: rcon_action = "set switchplayerspec"; break;
						case 14: rcon_action = "set exrcon"; break; // Crybaby
						case 15: rcon_action = "set unlock"; break;
						case 16: rcon_action = "set warp"; break;
						case 17: rcon_action = "set disableweapon"; break;
						case 18: rcon_action = "set enableweapon"; break;
						case 20: rcon_action = "set exrcon"; break; // Change name
						//case xx: rcon_action = "set switchsidesallplayers"; break;
						default: rcon_action = ""; break;
					}
				}
				else
				{
					// Servermode: commands are handled by server
					rcon_action = "set exrcon";
				}
				break;
			}
		}

		if(self.ex_rcon_player == -1 && !rcon_allowall)
		{
			rconSvrResponse(2);
			return;
		}

		if(rcon_action != "")
		{
			if(rcon_action != "set exrcon") logprint("EXTREME RCON: player " + self.name + " doing a " + rcon_action + ".\n");
			self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action + " " + self.ex_rcon_player);
			self setClientCvar("rcon_rsp_apply", 1);
		}
		else rconSvrResponse(6);
	}
}

rconPlayerModels()
{
	self endon("disconnect");

	if(level.ex_cmdmonitor_models)
	{
		if(level.ex_rcon_mode == 0)
		{
			// Clientmode: commands are handled by client (needs command monitor enabled)
			switch(self.ex_rcon_model)
			{
				case 0: rcon_action = "set original"; break;
				case 1: rcon_action = "set barrel"; break;
				case 2: rcon_action = "set bathtub"; break;
				case 3: rcon_action = "set funmode"; break;
				case 4: rcon_action = "set mattress"; break;
				case 5: rcon_action = "set toilet"; break;
				case 6: rcon_action = "set tombstone"; break;
				case 7: rcon_action = "set tree"; break;
				default: rcon_action = ""; break;
			}
		}
		else
		{
			// Servermode: commands are handled by server
			rcon_action = "set exrcon";
		}
	}
	else
	{
		rconSvrResponse(6);
		return;
	}

	if(rcon_action != "")
	{
		if(rcon_action != "set exrcon") logprint("EXTREME RCON: player " + self.name + " doing a " + rcon_action + ".\n");
		self setClientCvar("ui_rconExtremeCmd", "rcon " + rcon_action + " " + self.ex_rcon_player);
		self setClientCvar("rcon_rsp_apply", 1);
	}
	else
	{
		rconSvrResponse(6);
		self setClientCvar("rcon_rsp_apply", 0);
	}
}

rconPlayerTeam()
{
	self endon("disconnect");

	switch(self.ex_rcon_team)
	{
		case 1: rcon_team = "allies"; break;
		case 2: rcon_team = "axis"; break;
		default: rcon_team = ""; break;
	}

	// If team selected, remove player selection (99 means team selected)
	if(rcon_team != "")
	{
		self.ex_rcon_player = 99;
		self setClientCvar("rcon_rsp_player", self.ex_rcon_player);
	}

	setCvar("team", rcon_team);
}

rconPlayerServerAction(action, playerent, team)
{
	if(!rconPlayerIsServerAction(action)) return;

	//logprint("EXTREME RCON: action " + action + " executed by server\n");

	switch(action)
	{
		case  1: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "arty"); break;
		case  3: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "silence"); break;
		case  4: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "fire"); break;
		case  6: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "lock"); break;
		case  7: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "smite"); break;
		case  8: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "spank"); break;
		case  9: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "suicide"); break;
		case 10: thread extreme\_ex_cmdmonitor::switchSide(playerent, "allies", true, true); break;
		case 11: thread extreme\_ex_cmdmonitor::switchSide(playerent, "axis", true, true); break;
		case 12: thread extreme\_ex_cmdmonitor::switchSide(playerent, "spectator", true, true); break;
		case 14: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "crybaby"); break;
		case 15: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "unlock"); break;
		case 16: thread extreme\_ex_cmdmonitor::messWithPlayer(playerent, "warp"); break;
		case 17: thread extreme\_ex_cmdmonitor::setStatusweaponPlayer(playerent, true); break;
		case 18: thread extreme\_ex_cmdmonitor::setStatusweaponPlayer(playerent, false); break;
		case 19:
		{
			switch(self.ex_rcon_model)
			{
				case 0: thread extreme\_ex_cmdmonitor::changePlayerModel(playerent, "original"); break;
				case 1: thread extreme\_ex_cmdmonitor::changePlayerModel(playerent, "barrel"); break;
				case 2: thread extreme\_ex_cmdmonitor::changePlayerModel(playerent, "bathtub"); break;
				case 3: thread extreme\_ex_cmdmonitor::changePlayerModel(playerent, "funmode"); break;
				case 4: thread extreme\_ex_cmdmonitor::changePlayerModel(playerent, "mattress"); break;
				case 5: thread extreme\_ex_cmdmonitor::changePlayerModel(playerent, "toilet"); break;
				case 6: thread extreme\_ex_cmdmonitor::changePlayerModel(playerent, "tombstone"); break;
				case 7: thread extreme\_ex_cmdmonitor::changePlayerModel(playerent, "tree"); break;
			}
			break;
		}
		case 20:
		{
			if(playerent == -1 || playerent == 99) return;

			players = level.players;
			for (i = 0; i < players.size; i++)
			{
				player = players[i];
				entID = player getEntityNumber();
				if(entID == playerent)
				{
					player setClientCvar("name", "Unknown Soldier");
					if(player.sessionstate == "playing") player thread extreme\_ex_namecheck::handleUnknown(true);
						else player.ex_isunknown = true;
					break;
				}
			}
		}
	}
}

rconPlayerIsServerAction(action)
{
	// Reminder: all "set exrcon" actions are handled by server
	if(level.ex_rcon_mode == 0)
	{
		// Clientmode: return true for actions which MUST be executed by server, false for other actions
		switch(action)
		{
			case 14:
			case 20:
				return true;
			default:
				return false;
		}
	}
	else
	{
		// Servermode: return false for actions which MUST be executed by client, true for other actions
		switch(action)
		{
			case  2:
			case  5:
			case 13:
				return false;
			default:
				return true;
		}
	}
}

// *****************************************************************************
// MeatBot Control
// *****************************************************************************

rconMbotCtrl(command)
{
	self endon("disconnect");

	// Check authorization
	if(!rconIsAuthorizedFor(3))
	{
		rconSvrResponse(5);
		return;
	}

	// Mbots disabled
	if(!level.ex_mbot)
	{
		rconSvrResponse(6);
		return;
	}

	// Catch player commands for Player Control (0 - 63)
	for(i = 0; i < 64; i++)
	{
		if(command == "rcon_cmd_player" + i)
		{
			self.ex_rcon_player = i;
			command = "rcon_cmd_player";
			break;
		}
	}

	// Catch action commands for MeatBot Control
	for(i = 1; i <= 8; i++)
	{
		if(command == "rcon_cmd_action" + i)
		{
			self.ex_rcon_action = i;
			command = "rcon_cmd_action";
			break;
		}
	}

	// Handle commands for MeatBot Control
	switch(command)
	{
		case "rcon_cmd_mbotctrl":
		{
			self.ex_rcon_player = 999; // rcon_cmd_player, rcon_rsp_player
			self.ex_rcon_action = 0; // rcon_cmd_action, rcon_rsp_action
			self.ex_rcon_mbotskill = level.ex_mbot_skill; // rcon_cmd_skilldown, rcon_cmd_skillup
			self.ex_rcon_mbotspeed = level.ex_mbot_speed; // rcon_cmd_speeddown, rcon_cmd_speedup
			self.ex_rcon_truncate = level.ex_rcon_truncate; // rcon_cmd_truncate
			self.ex_rcon_color = level.ex_rcon_color; // rcon_cmd_color

			self setClientCvar("rcon_rsp_player", self.ex_rcon_player);
			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			self setClientCvar("rcon_rsp_mbotskill", self.ex_rcon_mbotskill);
			self setClientCvar("rcon_rsp_mbotspeed", self.ex_rcon_mbotspeed);
			self setClientCvar("rcon_rsp_truncate", self.ex_rcon_truncate);
			self setClientCvar("rcon_rsp_color", self.ex_rcon_color);
			self setClientCvar("rcon_rsp_apply", 0);
			self setClientCvar("ui_rconExtremeCmd", "rcon set exrcon 1");

			rconPlayerSlots();
			break;
		}
		case "rcon_cmd_mbotctrl_cleanup":
		{
			if(!isDefined(level.ex_rcon_maxplayers)) return;
			for(i = 0; i < level.ex_rcon_maxplayers; i++) self setClientCvar("rcon_rsp_player" + i, "");
			return;
		}
		case "rcon_cmd_player":
		{
			self setClientCvar("rcon_rsp_player", self.ex_rcon_player);
			rconMbotAction();
			break;
		}
		case "rcon_cmd_action":
		{
			rconMbotAction();
			break;
		}
		case "rcon_cmd_skilldown":
		{
			self.ex_rcon_action = 9;
			rconMbotAction();
			break;
		}
		case "rcon_cmd_skillup":
		{
			self.ex_rcon_action = 10;
			rconMbotAction();
			break;
		}
		case "rcon_cmd_speeddown":
		{
			self.ex_rcon_action = 11;
			rconMbotAction();
			break;
		}
		case "rcon_cmd_speedup":
		{
			self.ex_rcon_action = 12;
			rconMbotAction();
			break;
		}
		case "rcon_cmd_color":
		{
			self.ex_rcon_color = rconGetIntNext(self.ex_rcon_color, 0, 1);
			rconPlayerSlots();
			break;
		}
		case "rcon_cmd_truncate":
		{
			self.ex_rcon_truncate = rconGetIntNext(self.ex_rcon_truncate, 0, 1);
			rconPlayerSlots();
			break;
		}
		case "rcon_cmd_apply":
		{
			self setClientCvar("rcon_rsp_apply", 0);
			//self closeMenu();
			//self closeInGameMenu();
			thread rconMbotServerAction();
			self.ex_rcon_player = 999;
			self setClientCvar("rcon_rsp_player", self.ex_rcon_player);
			break;
		}
		default:
		{
			rconSvrResponse(7);
			return;
		}
	}

	rconSvrResponse(1);
}

rconMbotAction()
{
	self endon("disconnect");

	self setClientCvar("rcon_rsp_apply", 0);
	self setClientCvar("rcon_rsp_action", self.ex_rcon_action);

	if(self.ex_rcon_action != 8 || (self.ex_rcon_action == 8 && self.ex_rcon_player != 999))
	{
		switch(self.ex_rcon_action)
		{
			case  9:
				rconMbotSkill(false);
				break;
			case 10:
				rconMbotSkill(true);
				break;
			case 11:
				rconMbotSpeed(false);
				break;
			case 12:
				rconMbotSpeed(true);
				break;
		}

		// Servermode: commands are handled by server
		self setClientCvar("ui_rconExtremeCmd", "rcon set exrcon 1");
		self setClientCvar("rcon_rsp_apply", 1);
	}
}

rconMbotSkill(up)
{
	// valid mbot skill levels: 0 - 10
	if(up && self.ex_rcon_mbotskill < 10) self.ex_rcon_mbotskill++;
	else if(!up && self.ex_rcon_mbotskill > 0) self.ex_rcon_mbotskill--;

	self setClientCvar("rcon_rsp_mbotskill", self.ex_rcon_mbotskill);
}

rconMbotSpeed(up)
{
	// valid mbot speed levels: 50 - 220
	if(up && self.ex_rcon_mbotspeed < 220) self.ex_rcon_mbotspeed += 10;
	else if(!up && self.ex_rcon_mbotspeed > 50) self.ex_rcon_mbotspeed -= 10;

	self setClientCvar("rcon_rsp_mbotspeed", self.ex_rcon_mbotspeed);
}

rconMbotServerAction()
{
	if(level.ex_mbot)
	{
		switch(self.ex_rcon_action)
		{
			case  1: thread extreme\_ex_bots::addBot("allies"); break;
			case  2: thread extreme\_ex_bots::addBot("axis"); break;
			case  3: thread extreme\_ex_bots::addBot("spectator"); break;
			case  4: thread extreme\_ex_bots::addBot("autoassign"); break;
			case  5: thread extreme\_ex_bots::removeBot("allies"); break;
			case  6: thread extreme\_ex_bots::removeBot("axis"); break;
			case  7: thread extreme\_ex_bots::removeBot("all"); break;
			case  8: thread extreme\_ex_bots::removeBot( rconPlayerName(self.ex_rcon_player) ); break;
			case  9:
			case 10: thread extreme\_ex_bots::setBotSkill(self.ex_rcon_mbotskill); break;
			case 11:
			case 12: thread extreme\_ex_bots::setBotSpeed(self.ex_rcon_mbotspeed); break;
		}
	}
	else
	{
		rconSvrResponse(6);
		return;
	}
}

// *****************************************************************************
// Weapon Mode
// *****************************************************************************

rconWpnMode(command)
{
	self endon("disconnect");

	// Check authorization
	if(!rconIsAuthorizedFor(4))
	{
		rconSvrResponse(5);
		return;
	}

	// Catch action commands for Weapon Mode
	for(i = 0; i <= 23; i++)
	{
		if(command == "rcon_cmd_action" + i)
		{
			self.ex_rcon_action = i;
			command = "rcon_cmd_action";
			break;
		}
	}

	// Handle commands for Weapon Mode
	switch(command)
	{
		case "rcon_cmd_wpnmode":
		{
			weaponmode = getCvar("ex_weaponmode");
			if(weaponmode != "" && rconIsNumber(weaponmode))
			{
				weaponmode = getCvarInt("ex_weaponmode");
				if(weaponmode == 99) modeitem = 22;
				else if(weaponmode == 100) modeitem = 23;
				else modeitem = weaponmode;
				self.ex_rcon_action = modeitem; // rcon_cmd_actionX, rcon_rsp_action
			}
			else self.ex_rcon_action = 0; // rcon_cmd_actionX, rcon_rsp_action
			self.ex_rcon_restart = 0;

			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			self setClientCvar("rcon_rsp_restart", self.ex_rcon_restart);
			self setClientCvar("rcon_rsp_apply", 0);
			self setClientCvar("ui_rconExtremeCmd", "rcon set exrcon 1");
			break;
		}
		case "rcon_cmd_action":
		{
			self setClientCvar("rcon_rsp_apply", 1);
			self setClientCvar("rcon_rsp_action", self.ex_rcon_action);
			break;
		}
		case "rcon_cmd_restart":
		{
			self.ex_rcon_restart = !self.ex_rcon_restart;
			self setClientCvar("rcon_rsp_restart", self.ex_rcon_restart);
			break;
		}
		case "rcon_cmd_apply":
		{
			self setClientCvar("rcon_rsp_apply", 0);
			if(self.ex_rcon_action == 22) setCvar("ex_weaponmode", 99);
			else if(self.ex_rcon_action == 23) setCvar("ex_weaponmode", 100);
			else setCvar("ex_weaponmode", self.ex_rcon_action);

			if(self.ex_rcon_restart)
			{
				self closeMenu();
				self closeInGameMenu();
				wait( [[level.ex_fpstime]](1) );
				if(level.ex_statstotal) extreme\_ex_statstotal::writeStatsAll(true);
				self thread extreme\_ex_utils::execClientCommand("rcon map_restart");
			}
			break;
		}
		default:
		{
			rconSvrResponse(7);
			return;
		}
	}

	rconSvrResponse(1);
}

// *****************************************************************************
// Server Settings
// *****************************************************************************

rconSetSvr(command)
{
	self endon("disconnect");

	// Check authorization
	if(!rconIsAuthorizedFor(5))
	{
		rconSvrResponse(5);
		return;
	}

	// Catch profile commands
	for(i = 0; i <= 5; i++)
	{
		if(command == "rcon_profile" + i)
		{
			self.ex_rcon_action = i;
			command = "rcon_cmd_profile";
			break;
		}
	}

	// Handle commands for General Settings
	switch(command)
	{
		case "rcon_cmd_setsvr":
		{
			self.ex_rcon_action = -1;
			self.ex_rcon_clanvsnonclan = rconGetCvarDef("ex_clanvsnonclan", 0);
			self.ex_rcon_balancenow = 0;
			self.ex_rcon_profile = rconGetCvarDef("scr_profile_active", 0);

			// g_allowvote already has clientside var "ui_allowvote"
			self setClientCvar("rcon_rsp_g_antilag", rconGetCvarDef("g_antilag", 0));
			self setClientCvar("rcon_rsp_sv_disableClientConsole", rconGetCvarDef("sv_disableClientConsole", 0));
			self setClientCvar("rcon_rsp_g_deadChat", rconGetCvarDef("g_deadChat", 0));
			self setClientCvar("rcon_rsp_scr_drawfriend", rconGetCvarDef("scr_drawfriend", 1));
			self setClientCvar("rcon_rsp_scr_forcerespawn", rconGetCvarDef("scr_forcerespawn", 1));
			// scr_friendlyfire already has clientside var "ui_friendlyfire"
			self setClientCvar("rcon_rsp_scr_killcam", rconGetCvarDef("scr_killcam", 0));
			self setClientCvar("rcon_rsp_scr_spectateenemy", rconGetCvarDef("scr_spectateenemy", 0));
			self setClientCvar("rcon_rsp_scr_spectatefree", rconGetCvarDef("scr_spectatefree", 1));
			self setClientCvar("rcon_rsp_scr_teambalance", rconGetCvarDef("scr_teambalance", 1));
			self setClientCvar("rcon_rsp_clanvsnonclan", self.ex_rcon_clanvsnonclan);
			self setClientCvar("rcon_rsp_balancenow", self.ex_rcon_balancenow);
			self setClientCvar("rcon_rsp_apply", 0);
			self setClientCvar("ui_rconExtremeCmd", "rcon set exrcon 1");
			break;
		}
		case "rcon_cmd_g_allowvote":
		{
			setCvar("g_allowvote", rconGetCvarIntNext("g_allowvote", 0, 1));
			break;
		}
		case "rcon_cmd_g_antilag":
		{
			setCvar("g_antilag", rconGetCvarIntNext("g_antilag", 0, 1));
			break;
		}
		case "rcon_cmd_sv_disableClientConsole":
		{
			setCvar("sv_disableClientConsole", rconGetCvarIntNext("sv_disableClientConsole", 0, 1));
			break;
		}
		case "rcon_cmd_g_deadChat":
		{
			setCvar("g_deadChat", rconGetCvarIntNext("g_deadChat", 0, 1));
			break;
		}
		case "rcon_cmd_scr_drawfriend":
		{
			setCvar("scr_drawfriend", rconGetCvarIntNext("scr_drawfriend", 0, 1));
			break;
		}
		case "rcon_cmd_scr_forcerespawn":
		{
			setCvar("scr_forcerespawn", rconGetCvarIntNext("scr_forcerespawn", 0, 1));
			break;
		}
		case "rcon_cmd_scr_friendlyfire":
		{
			setCvar("scr_friendlyfire", rconGetCvarIntNext("scr_friendlyfire", 0, 3));
			break;
		}
		case "rcon_cmd_scr_killcam":
		{
			setCvar("scr_killcam", rconGetCvarIntNext("scr_killcam", 0, 1));
			break;
		}
		case "rcon_cmd_scr_spectateenemy":
		{
			setCvar("scr_spectateenemy", rconGetCvarIntNext("scr_spectateenemy", 0, 1));
			break;
		}
		case "rcon_cmd_scr_spectatefree":
		{
			setCvar("scr_spectatefree", rconGetCvarIntNext("scr_spectatefree", 0, 1));
			break;
		}
		case "rcon_cmd_scr_teambalance":
		{
			setCvar("scr_teambalance", rconGetCvarIntNext("scr_teambalance", 0, 1));
			break;
		}
		case "rcon_cmd_profile":
		{
			// self.ex_rcon_action is set above (0 - 5);
			if(self.ex_rcon_action < game["profiles"].size)
			{
				self.ex_rcon_profile = self.ex_rcon_action;
				self setClientCvar("rcon_rsp_apply", 1);
			}
			break;
		}
		case "rcon_cmd_clanvsnonclan":
		{
			self.ex_rcon_action = 6;
			// 0 = off, 1 = on (now), 2 = on (next map), 3 = off (next map)
			self.ex_rcon_clanvsnonclan = rconGetIntNext(self.ex_rcon_clanvsnonclan, 0, 3, 1);
			self setClientCvar("rcon_rsp_clanvsnonclan", self.ex_rcon_clanvsnonclan);
			self setClientCvar("rcon_rsp_apply", 1);
			break;
		}
		case "rcon_cmd_balancenow":
		{
			self.ex_rcon_action = 7;
			// 0 = off, 1 = auto, 2 = numbers, 3 = skill
			self.ex_rcon_balancenow = rconGetIntNext(self.ex_rcon_balancenow, 0, 3, 1);
			self setClientCvar("rcon_rsp_balancenow", self.ex_rcon_balancenow);
			self setClientCvar("rcon_rsp_apply", 1);
			break;
		}
		case "rcon_cmd_apply":
		{
			self setClientCvar("rcon_rsp_apply", 0);
			// Apply will be used for profile switching, clan versus non-clan and balance now only
			thread rconSetSvrAction();
			break;
		}
		default:
		{
			rconSvrResponse(7);
			return;
		}
	}

	rconSvrResponse(1);
}

rconSetSvrAction()
{
	self endon("disconnect");

	self setClientCvar("rcon_rsp_apply", 0);

	if(self.ex_rcon_action != -1)
	{
		switch(self.ex_rcon_action)
		{
			// profile switching
			case 0:
			case 1:
			case 2:
			case 3:
			case 4:
			case 5:
				setCvar("scr_profile_active", self.ex_rcon_action);
				logprint("RCON: " + self.name + " activated profile " + self.ex_rcon_action + ", \"" + game["profiles"][self.ex_rcon_action].name + "\" for the next map\n");
				break;

			// clan versus non clan
			case 6:
				setCvar("ex_clanvsnonclan", self.ex_rcon_clanvsnonclan);
				thread maps\mp\gametypes\_teams::switchClanVersusNonclan(self.ex_rcon_clanvsnonclan);
				break;

			// balance now
			case 7:
				switch(self.ex_rcon_balancenow)
				{
					case 1: thread maps\mp\gametypes\_teams::balanceTeams(); break;
					case 2: thread maps\mp\gametypes\_teams::balanceTeamsTraditional(); break;
					case 3: if(level.ex_statstotal) thread maps\mp\gametypes\_teams::balanceTeamsSkill(false); break;
				}
				break;
		}
	}
}

// *****************************************************************************
// Client Settings
// *****************************************************************************

rconSetClnt(command)
{
	self endon("disconnect");

	// Check authorization
	if(!rconIsAuthorizedFor(6))
	{
		rconSvrResponse(5);
		return;
	}

	// Handle commands for Client Settings
	switch(command)
	{
		case "rcon_cmd_setclnt":
		{
			break;
		}
		default:
		{
			rconSvrResponse(7);
			return;
		}
	}

	rconSvrResponse(1);
}

// *****************************************************************************
// Weapon Settings
// *****************************************************************************

rconSetWpn(command)
{
	self endon("disconnect");

	// Check authorization
	if(!rconIsAuthorizedFor(7))
	{
		rconSvrResponse(5);
		return;
	}

	// Handle commands for Weapon Settings
	switch(command)
	{
		case "rcon_cmd_setwpn":
		{
			for(i = 0; i < level.weaponnames.size; i++)
			{
				weaponname = level.weaponnames[i];
				if((level.weapons[weaponname].status & 2) != 2) continue;
				rconGetWeaponStatus(weaponname);
			}
			break;
		}
		default:
		{
			rconSetWeaponStatus(command);
		}
	}

	rconSvrResponse(1);
}

rconGetWeaponStatus(weaponname)
{
	if(!isDefined(level.weapons[weaponname]) || !level.weapons[weaponname].precached || level.weapons[weaponname].limit == -1) status = -1;
		else status = rconGetCvarDef("scr_allow_" + weaponname, -1);
	self setClientCvar("rcon_" + weaponname, status);
}

rconSetWeaponStatus(command)
{
	if(isSubStr(command, "rcon_"))
	{
		weaponname = getSubStr(command, 5);
		if(!isDefined(level.weapons[weaponname]) || !level.weapons[weaponname].precached || level.weapons[weaponname].limit == -1) status = -1;
		else
		{
			server_allowcvar = "scr_allow_" + weaponname;
			status = rconGetCvarIntNext(server_allowcvar, 0, 1);
			setCvar(server_allowcvar, status);
		}
		self setClientCvar("rcon_" + weaponname, status);
	}
	else
	{
		rconSvrResponse(7);
		return;
	}
}

// *****************************************************************************
// Authentication and Authorization
// *****************************************************************************

rconInitPlayer()
{
	self endon("disconnect");

	rconClearAuthorization();
	if(!level.ex_rcon) return;

	count = 0;
	for(;;)
	{
		rcon_name = [[level.ex_drm]]("ex_rcon_name_" + count, "", "", "", "string");
		if(rcon_name == "") break;
		if(rcon_name == self.name) break;
			else count++;
	}

	if(rcon_name != "")
	{
		if(level.ex_security && !self extreme\_ex_security::checkGuid()) return;
		rconInitAuthorization(count);
		return;
	}

	rcon_clan = "";
	count = 0;
	if(isDefined(self.ex_name))
	{
		for(;;)
		{
			rcon_clan = [[level.ex_drm]]("ex_rcon_clan_" + count, "", "", "", "string");
			if(rcon_clan == "") break;
			if(rcon_clan == self.ex_name) break;
				else count++;
		}
	}

	if(rcon_clan != "")
	{
		if(level.ex_rcon_autopass && !self extreme\_ex_security::checkGuid()) return;
		rconInitAuthorization(count);
	}
}

rconClearAuthorization()
{
	self.ex_rcon = undefined;
	self setClientCvar("ui_rconExtreme", 0);
}

rconInitAuthorization(authno)
{
	self endon("disconnect");

	self.ex_rcon = authno;
	self setClientCvar("ui_rconExtreme", 1);

	// 0 = not authorized
	// 1 = authorized, but not logged in yet
	// 2 = authorized and logged in
	self.ex_rcon_authorized = 0;

	self setClientCvar("ui_rconExtremeAccess0", 0);
	self setClientCvar("ui_rconExtremeAccess1", 0);
	self setClientCvar("ui_rconExtremeAccess2", 0);
	self setClientCvar("ui_rconExtremeAccess3", 0);
	self setClientCvar("ui_rconExtremeAccess4", 0);
	self setClientCvar("ui_rconExtremeAccess5", 0);
	self setClientCvar("ui_rconExtremeAccess6", 0);
	self setClientCvar("ui_rconExtremeAccess7", 0);

	self.ex_rcon_access = [[level.ex_drm]]("ex_rcon_access_" + self.ex_rcon, level.ex_rcon_access_default, 1, 127, "int");

	if(level.ex_rcon_mode == 0 && level.ex_rcon_autopass)
	{
		// Full authorization in client mode if autopass is enabled
		rconAuthorizeLogin();
		rconAuthorizeAccess();
	}
	else
	{
		// Server mode or client mode without autopass
		// No authorization until correct pin is presented. Get player's PIN
		self.ex_rcon_pin = [[level.ex_drm]]("ex_rcon_pin_" + self.ex_rcon, "", "", "", "string");
		self.ex_rcon_pin = rconJustNumbers(self.ex_rcon_pin);
		if(self.ex_rcon_pin == "")
		{
			self.ex_rcon_pin = "" + randomInt(10) + randomInt(10) + randomInt(10) + randomInt(10);
			logprint("EXTREME RCON: no PIN defined for player " + self.name + ". Assigned random PIN " + self.ex_rcon_pin + ".\n");
		}
		self.ex_rcon_pin_entry = "";

		// Set dummy rcon login command for rcon_main.menu OnOpen event
		self setClientCvar("ui_rconExtremeLogin", "set exrcon 1");

		// Check persistent memory for cached PIN
		if(level.ex_rcon_cachepin)
		{
			memory = self extreme\_ex_memory::getMemory("rcon", "pin");
			if(!memory.error && memory.value == self.ex_rcon_pin)
			{
				rconAuthorizeLogin();
				rconAuthorizeAccess();
			}
		}
	}
}

rconAuthorizeLogin()
{
	self endon("disconnect");

	// 0 = not authorized
	// 1 = authorized, but not logged in yet
	// 2 = authorized and logged in
	self.ex_rcon_authorized = 1;
	self setClientCvar("ui_rconExtremeAccess0", 1);

	rcon_pass = getCvar("rcon_password");
	if(rcon_pass != "")
		self setClientCvar("ui_rconExtremeLogin", "rcon login " + rcon_pass);
}

rconAuthorizeAccess()
{
	self endon("disconnect");

	// Clear falls pin memory
	if(isDefined(self.ex_rcon_fallspins)) self.ex_rcon_fallspins = 0;

	// 0 = not authorized
	// 1 = authorized, but not logged in yet
	// 2 = authorized and logged in
	self.ex_rcon_authorized = 2;
	self setClientCvar("ui_rconExtremeAccess0", 2);

	if(isDefined(self.ex_rcon_access))
	{
		if( (self.ex_rcon_access &  1) ==  1) self setClientCvar("ui_rconExtremeAccess1", 1);
		if( (self.ex_rcon_access &  2) ==  2) self setClientCvar("ui_rconExtremeAccess2", 1);
		if( (self.ex_rcon_access &  4) ==  4) self setClientCvar("ui_rconExtremeAccess3", 1);
		if( (self.ex_rcon_access &  8) ==  8) self setClientCvar("ui_rconExtremeAccess4", 1);
		if( (self.ex_rcon_access & 16) == 16) self setClientCvar("ui_rconExtremeAccess5", 1);
		if( (self.ex_rcon_access & 32) == 32) self setClientCvar("ui_rconExtremeAccess6", 1);
		if( (self.ex_rcon_access & 64) == 64) self setClientCvar("ui_rconExtremeAccess7", 1);
	}
}

rconIsAuthorizedFor(menu)
{
	self endon("disconnect");

	rcon_authok = false;
	
	// Check if this is a legitimate rcon user
	if(isDefined(self.ex_rcon) && isDefined(self.ex_rcon_authorized) && isDefined(self.ex_rcon_access))
	{
		// Main menu is not included in access var, so having the vars above is enough
		if(menu == 0) rcon_authok = true;

		// Other menus can be checked with a logical AND operation
		if(self.ex_rcon_authorized == 2)
		{
			if(menu == 1 && (self.ex_rcon_access &  1) ==  1) rcon_authok = true;
			else if(menu == 2 && (self.ex_rcon_access &  2) ==  2) rcon_authok = true;
			else if(menu == 3 && (self.ex_rcon_access &  4) ==  4) rcon_authok = true;
			else if(menu == 4 && (self.ex_rcon_access &  8) ==  8) rcon_authok = true;
			else if(menu == 5 && (self.ex_rcon_access & 16) == 16) rcon_authok = true;
			else if(menu == 6 && (self.ex_rcon_access & 32) == 32) rcon_authok = true;
			else if(menu == 7 && (self.ex_rcon_access & 64) == 64) rcon_authok = true;
		}
	}

	if(!rcon_authok)
	{
		// Player tried to gain access without proper authorization (probably setting cvars
		// manually on the client) -- kick the bastard
		logprint("EXTREME RCON: player " + self.name + " kicked for unauthorized access attempt.\n");
		rconResetLoginInfo();
		kick(self getEntityNumber());
		return false;
	}

	return true;
}

rconLoginTimeframe(seconds)
{
	self endon("disconnect");

	rcon_loggedin = false;
	for(i = 0; i < seconds; i++)
	{
		if(self.ex_rcon_authorized == 2)
		{
			rcon_loggedin = true;
			break;
		}
		wait( [[level.ex_fpstime]](1) );
	}

	if(!rcon_loggedin)
	{
		logprint("EXTREME RCON: player " + self.name + " missed the window of opportunity (" + seconds + " seconds).\n");
		self.ex_rcon_authorized = 0;
		self setClientCvar("ui_rconExtremeAccess0", 0);
		self setClientCvar("ui_rconExtremeLogin", "set exrcon 1");
	}
	else if(level.ex_rcon_cachepin)
		self thread extreme\_ex_memory::setMemory("rcon", "pin", self.ex_rcon_pin, level.ex_tune_delaywrite);
}

rconLoginFalsePIN()
{
	if(!isDefined(self.ex_rcon_fallspins)) self.ex_rcon_fallspins = 1;
		else self.ex_rcon_fallspins += 1;

	if(self.ex_rcon_fallspins >= 5)
	{
		logprint("EXTREME RCON: player " + self.name + " kicked for exceeding allowed number of login attempts.\n");
		kick(self getEntityNumber());
	}
}

rconResetLoginInfo()
{
	// Reset logon info with dummy command
	wait( [[level.ex_fpstime]](1) );
	self setClientCvar("ui_rconExtremeLogin", "set exrcon 1");
}

// *****************************************************************************
// Supporting code
// *****************************************************************************

rconSvrResponse(response)
{
	// 0 = awaiting server response (client only)
	// 1 = success
	// 2 = unable to comply
	// 3 = not available yet
	// 4 = command incomplete
	// 5 = not authorized
	// 6 = feature disabled on server
	// 7 = unknown command
	wait( [[level.ex_fpstime]](1) );
	self setClientCvar("rcon_rsp_result", response);
}

rconGetCvarDef(var, def)
{
	if(getCvar(var) == "") rcon_var = def;
		else rcon_var = getCvarInt(var);
	return rcon_var;
}

rconGetCvarIntNext(var, min, max)
{
	rcon_var = getCvarInt(var);
	rcon_var = rconGetIntNext(rcon_var, min, max);
	return rcon_var;
}

rconGetIntNext(var, min, max, inc)
{
	if(!isDefined(inc)) inc = 1;
	var += inc;
	if(var > max) var = min;
	return var;
}

rconJustNumbers(str)
{
	if(!isDefined(str) || str == "") return "";

	numbers = "0123456789";
	string = "";

	for(i = 0; i < str.size; i++)
	{
		chr = str[i];
		for(j = 0; j < numbers.size; j++)
			if(chr == numbers[j]) string += numbers[j];
	}

	return string;
}

rconIsNumber(str)
{
	if(!isDefined(str) || str == "") return false;

	validchars = "0123456789";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return false;

	return true;
}

rconTruncate(str, maxchar)
{
	if(!isDefined(str) || (str == "")) return ("");

	newstr = "";
	strlen = 0;
	colorcheck = false;
	for (i = 0; i < str.size; i++)
	{
		ch = str[i];
		if(colorcheck)
		{
			colorcheck = false;
			switch(ch)
			{
				case "0":	// black
				case "1":	// red
				case "2":	// green
				case "3":	// yellow
				case "4":	// blue
				case "5":	// cyan
				case "6":	// pink
				case "7":	// white
				case "8":	// Olive
				case "9":	// Grey
					newstr += ("^" + ch);
					break;
				default:
					newstr += "^";
					strlen++;
					if(strlen < maxchar)
					{
						newstr += ch;
						strlen++;
					}
					break;
			}
		}
		else
		{
			if(ch != "^")
			{
				newstr += ch;
				strlen++;
			}
			else colorcheck = true;
		}
		
		if(strlen >= maxchar) break;
	}

	return (newstr);
}

rconGametype(gtnumber)
{
	switch(gtnumber)
	{
		case  1: return "chq";
		case  2: return "cnq";
		case  3: return "ctf";
		case  4: return "ctfb";
		case  5: return "dm";
		case  6: return "dom";
		case  7: return "esd";
		case  8: return "ft";
		case  9: return "hm";
		case 10: return "hq";
		case 11: return "htf";
		case 12: return "ihtf";
		case 13: return "lib";
		case 14: return "lms";
		case 15: return "lts";
		case 16: return "ons";
		case 17: return "rbcnq";
		case 18: return "rbctf";
		case 19: return "sd";
		case 20: return "tdm";
		case 21: return "tkoth";
		case 22: return "vip";
		default: return "";
	}
}

rconDelayedSay(text)
{
	wait( [[level.ex_fpstime]](1) );
	extreme\_ex_utils::execClientCommand("rcon say " + text);
}

getEntityByNumber(entityID)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		entID = players[i] getEntityNumber();
		if(entID == entityID) return(players[i]);
	}
	return(undefined);
}
