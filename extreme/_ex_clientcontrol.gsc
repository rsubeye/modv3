#include extreme\_ex_hudcontroller;

init()
{
	[[level.ex_registerCallback]]("onPlayerConnecting", ::onPlayerConnecting);
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
	[[level.ex_registerCallback]]("onPlayerDisconnected", ::onPlayerDisconnected);
}

onPlayerConnecting()
{
	// if roundbased, no need to display the connecting information if they've already been playing
	if(level.ex_roundbased && game["roundnumber"] > 1) return;

	// if using the ready-up system, no need to display the connecting information if they've already been playing
	if(level.ex_readyup && isDefined(game["readyup_done"]) && isDefined(self.pers["team"])) return;

	if( (isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name) )
	{
		if(level.ex_plcdmsg) iprintln(&"CLIENTCONTROL_CONNECTING", [[level.ex_pname]](self));

		if(level.ex_plcdsound)
		{
			players = level.players;
			for(i = 0; i < players.size; i++) players[i] playLocalSound("gomplayersjoined");
		}
	}
}

onPlayerConnected()
{	
	// add player to players array
	level.players[level.players.size] = self;

	// set one-off vars
	self.usedweapons = false;
	self.ex_sinbin = false;
	self.ex_glplay = undefined;
	self.pers["spec_on"] = false;
	self.pers["dth_on"] = false;
	self.pers["intro_on"] = false;

	// initialize score
	extreme\_ex_gtcommon::playerScoreInit();

	// initialize main stats
	if(!isDefined(self.pers["kill"])) self.pers["kill"] = 0;
	if(!isDefined(self.pers["bonus"])) self.pers["bonus"] = 0;
	if(!isDefined(self.pers["special"])) self.pers["special"] = 0;
	if(!isDefined(self.pers["teamkill"])) self.pers["teamkill"] = 0;
	if(!isDefined(self.pers["suicide"])) self.pers["suicide"] = 0;
	if(!isDefined(self.pers["specials_cash"])) self.pers["specials_cash"] = 0;

	// check security status
	self extreme\_ex_security::checkInit();

	// restore points, kills, deaths and bonus if rejoining during grace period
	if(level.ex_scorememory && level extreme\_ex_memory::getScoreMemory(self.name))
	{
		memory = self extreme\_ex_memory::getMemory("score", "points");
		if(!memory.error)
		{
			self.pers["score"] = memory.value;
			self.score = self.pers["score"];
		}
		memory = self extreme\_ex_memory::getMemory("score", "kills");
		if(!memory.error) self.pers["kill"] = memory.value;
		memory = self extreme\_ex_memory::getMemory("score", "deaths");
		if(!memory.error)
		{
			self.pers["death"] = memory.value;
			self.deaths = self.pers["death"];
		}
		memory = self extreme\_ex_memory::getMemory("score", "bonus");
		if(!memory.error) self.pers["bonus"] = memory.value;
		memory = self extreme\_ex_memory::getMemory("score", "special");
		if(!memory.error) self.pers["special"] = memory.value;

		// added to avoid perk abuse
		if(self.pers["score"]) self.specials_locked = (gettime() / 1000);
	}

	// populate total stats variables
	if(level.ex_statstotal) self extreme\_ex_statstotal::readStats();

	// check if this player is excluded from the inactivity monitor
	self extreme\_ex_security::checkIgnoreInactivity();

	// initialize eXtreme+ rcon
	self extreme\_ex_rcon::rconInitPlayer();

	// remove existing ready-up spawn ticket
	if(!level.ex_readyup || (level.ex_readyup && !isDefined(game["readyup_done"])) )
		self.pers["readyup_spawnticket"] = undefined;

	// detect forced auto-assign (0 = off, 1 = all, 2 = non-clan only)
	self.ex_autoassign = 0;
	if(level.ex_autoassign == 1) self.ex_autoassign = 1;
		else if(level.ex_autoassign == 2 && (!isDefined(self.ex_name) || self.ex_clid != 1)) self.ex_autoassign = 1;

	//if(self.ex_autoassign) logprint("TEAM DEBUG (C): " + self.name + " self.ex_autoassign switched on\n");
	//	else logprint("TEAM DEBUG (C): " + self.name + " self.ex_autoassign switched off\n");

	if(self.ex_autoassign) self setClientCvar("ui_allow_select_team", "0");
		else self setClientCvar("ui_allow_select_team", "1");

	// bots need to reselect weapon on round based games with swapteams enabled
	if(isDefined(self.pers["isbot"]))
	{
		if(level.ex_roundbased && level.ex_swapteams && game["roundsplayed"] > 0 && !isDefined(self.pers["weapon"]))
		{
			if(level.ex_testclients_diag) logprint(self.name + " reselecting new weapons...\n");
			self thread extreme\_ex_bots::dbotLoadout();
		}
	}

	// if roundbased, no need to hear any intro sounds again if they've already been playing
	if(level.ex_roundbased && game["roundnumber"] > 1) return;

	// if using the ready-up system, no need to hear any intro sounds again if they've already been playing
	if(level.ex_readyup && isDefined(game["readyup_done"]) && isDefined(self.pers["team"])) return;

	// start menu music
	if(level.ex_gameover && (level.ex_endmusic || level.ex_mvmusic || level.ex_statsmusic)) skip_intromusic = true;
		else skip_intromusic = false;

	extreme\_ex_maps::getmapstring(getCvar("mapname"));

	if(!skip_intromusic && level.ex_intromusic > 0)
	{
		if(level.ex_intromusic == 1 && level.msc)
		{
			self.pers["intro_on"] = true;
			self playlocalsound(getCvar("mapname"));
		}
		else
		{
			if(level.ex_intromusic == 2 && level.msc)
			{
				self.pers["intro_on"] = true;
				self playlocalsound("mus_" + getCvar("mapname"));
			}
			else
			{
				if(level.ex_intromusic == 3 || !level.msc)
				{
					intro = randomInt(10) + 1;
					self.pers["intro_on"] = true;
					self playlocalsound("intromusic_" + intro);
				}
			}
		}
	}

	if(level.ex_plcdmsg)
	{
		if( (isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name) )
			iprintln(&"CLIENTCONTROL_HASJOINED", [[level.ex_pname]](self));
	}
}

exPlayerPreServerInfo()
{
	if(level.ex_cinematic)
	{
		cinematic_play = true;
		if(level.ex_cinematic == 1 || level.ex_cinematic == 2)
		{
			memory = self extreme\_ex_memory::getMemory("cinematic", "status");
			if(!memory.error) cinematic_play = memory.value;
			if(cinematic_play) self thread extreme\_ex_memory::setMemory("cinematic", "status", 0, level.ex_tune_delaywrite);
		}

		waittillframeend;
		if(cinematic_play) self extreme\_ex_utils::execClientCommand("unskippablecinematic poweredby");
		wait( [[level.ex_fpstime]](0.05) );
	}
}

onJoinedTeam()
{
	team = self.pers["team"];
	if( isDefined(self.ex_autoassign_team) && ((isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name)) )
	{
		if(team == "allies")
		{
			switch(game["allies"])
			{
				case "american":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_AMERICAN", [[level.ex_pname]](self));
					break;
				case "british":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_BRITISH", [[level.ex_pname]](self));
					break;
				default:
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_RUSSIAN", [[level.ex_pname]](self));
					break;
			}
		}
		else if(team == "axis")
		{
			switch(game["axis"])
			{
				case "german":
					iprintln(&"CLIENTCONTROL_FORCED_JOIN_GERMAN", [[level.ex_pname]](self));
					break;
			}
		}
	}
	else if( (isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name) )
	{
		if(team == "allies")
		{
			switch(game["allies"])
			{
				case "american":
					iprintln(&"CLIENTCONTROL_RECRUIT_AMERICAN", [[level.ex_pname]](self));
					break;
				case "british":
					iprintln(&"CLIENTCONTROL_RECRUIT_BRITISH", [[level.ex_pname]](self));
					break;
				default:
					iprintln(&"CLIENTCONTROL_RECRUIT_RUSSIAN", [[level.ex_pname]](self));
					break;
			}
		}
		else if(team == "axis")
		{
			switch(game["axis"])
			{
				case "german":
					iprintln(&"CLIENTCONTROL_RECRUIT_GERMAN", [[level.ex_pname]](self));
					break;
			}
		}
	}
}

onJoinedSpectators()
{
	if(level.ex_specmusic && !self.pers["spec_on"])
	{
		self playLocalSound("spec_music_null");
		self.pers["spec_on"] = true;
		self playLocalSound("spec_music");
		self thread spectatorMusicMonitor();
	}
}

onPlayerDisconnected()
{
	// remove player from players array
	self removePlayerOnDisconnect();

	entity = self getEntityNumber();
	if(level.ex_specials) level thread extreme\_ex_specials::onPlayerDisconnected(entity);
	if(level.ex_readyup && !isDefined(game["readyup_done"])) level thread extreme\_ex_readyup::onPlayerDisconnected(entity);

	// update persistent memory and save
	if(level.ex_cinematic == 2) self extreme\_ex_memory::setMemory("cinematic", "status", 1, true);
	if(level.ex_rcon && (level.ex_rcon_mode == 1 || (level.ex_rcon_mode == 0 && !level.ex_rcon_autopass)) && level.ex_rcon_cachepin)
		self extreme\_ex_memory::setMemory("rcon", "pin", "xxxx", true);
	if(level.ex_clanlogin && isDefined(self.ex_name))
		self extreme\_ex_memory::setMemory("clan", "pin", "xxxx", true);
	if(level.ex_scorememory)
	{
		level thread extreme\_ex_memory::setScoreMemory(self.name);
		if(isDefined(self.pers["score"])) self extreme\_ex_memory::setMemory("score", "points", self.pers["score"], true);
			else self extreme\_ex_memory::setMemory("score", "points", 0, true);
		if(isDefined(self.pers["kill"])) self extreme\_ex_memory::setMemory("score", "kills", self.pers["kill"], true);
			else self extreme\_ex_memory::setMemory("score", "kills", 0, true);
		if(isDefined(self.pers["death"])) self extreme\_ex_memory::setMemory("score", "deaths", self.pers["death"], true);
			else self extreme\_ex_memory::setMemory("score", "deaths", 0, true);
		if(isDefined(self.pers["bonus"])) self extreme\_ex_memory::setMemory("score", "bonus", self.pers["bonus"], true);
			else self extreme\_ex_memory::setMemory("score", "bonus", 0, true);
		if(isDefined(self.pers["special"])) self extreme\_ex_memory::setMemory("score", "special", self.pers["special"], true);
			else self extreme\_ex_memory::setMemory("score", "special", 0, true);
	}
	if(level.ex_statstotal) self extreme\_ex_statstotal::writeStats(false);

	self extreme\_ex_memory::saveMemory();

	// disconnect message and sound
	if( (isDefined(self.ex_name) && level.ex_clano[self.ex_clid]) || !isDefined(self.ex_name) )
	{
		if(level.ex_plcdmsg) iprintln(&"CLIENTCONTROL_DISCONNECTED", [[level.ex_pname]](self));

		if(level.ex_plcdsound)
		{
			players = level.players;
			for(i = 0; i < players.size; i++) players[i] playLocalSound("gomplayersleft");
		}
	}
}

removePlayerOnDisconnect()
{
	for(i = 0; i < level.players.size; i++ )
	{
		if(level.players[i] == self)
		{
			while(i < level.players.size-1)
			{
				level.players[i] = level.players[i+1];
				i++;
			}
			level.players[i] = undefined;
			break;
		}
	}
}

menuAutoAssign()
{
	if(isDefined(self.spawned)) return;

	assignment = "";

	if(level.ex_statstotal && level.ex_statstotal_balance)
	{
		my_skill = extreme\_ex_statstotal::getMySkillLevel(true);
		if(my_skill)
		{
			AlliedSkill = extreme\_ex_statstotal::getTeamSkillLevel("allies", true, false, false);
			AxisSkill = extreme\_ex_statstotal::getTeamSkillLevel("axis", true, false, false);

			if(level.ex_statstotal_balance_log)
			{
				logprint("SBAA: " + self.name + " (skill " + my_skill + ") requested auto-assign based on skill levels\n");
				logprint("SBAA: current skill levels are Allies " + AlliedSkill + ", Axis " + AxisSkill + "\n");
			}

			if(AlliedSkill < AxisSkill) assignment = "allies";
				else if(AxisSkill < AlliedSkill) assignment = "axis";

			if(level.ex_statstotal_balance_log)
			{
				if(assignment != "") logprint("SBAA: " + self.name + " (skill " + my_skill + ") assigned to team " + assignment + "\n");
					else logprint("SBAA: " + self.name + " (skill " + my_skill + ") will be balanced based on number of players\n");
			}
			if(level.ex_statstotal_balance == 1) assignment = "";
		}
	}

	if(assignment == "")
	{
		numonteam["allies"] = 0;
		numonteam["axis"] = 0;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(player == self || !isDefined(player.pers["team"]) || player.pers["team"] == "spectator" || !isDefined(player.pers["teamTime"])) continue;
			numonteam[player.pers["team"]]++;
		}

		// if teams are equal return the team with the lowest score
		if(numonteam["allies"] == numonteam["axis"])
		{
			if(getTeamScore("allies") == getTeamScore("axis"))
			{
				teams[0] = "allies";
				teams[1] = "axis";
				assignment = teams[randomInt(2)];
			}
			else if(getTeamScore("allies") < getTeamScore("axis")) assignment = "allies";
				else assignment = "axis";
		}
		else if(numonteam["allies"] < numonteam["axis"]) assignment = "allies";
			else assignment = "axis";
	}

	if(self.sessionstate == "playing" || self.sessionstate == "dead")
	{
		if(assignment == self.pers["team"])
		{
			if(!isDefined(self.pers["weapon"]))
			{
				if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
					else self openMenu(game["menu_weapon_axis"]);
			}

			return;
		}
		else
		{
			self.switching_teams = true;
			self.joining_team = assignment;
			self.leaving_team = self.pers["team"];
			if(self.sessionstate == "playing") self suicide();
		}
	}

	self.pers["team"] = assignment;
	self.pers["savedmodel"] = undefined;

	// create the eXtreme+ weapon array
	self extreme\_ex_weapons::setWeaponArray();

	// clear game weapon array
	self clearWeapons();
	
	self setClientCvar("ui_allow_weaponchange", "1");
	if(level.ex_classes == 1) self setClientCvar("ui_allow_classchange", "1");

	self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else if(self.pers["team"] == "allies")
		{
			self openMenu(game["menu_weapon_allies"]);
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		}
		else
		{
			self openMenu(game["menu_weapon_axis"]);
			self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
		}
	}

	self notify("joined_team");
	if(!level.ex_roundbased) self notify("end_respawn");
}

menuAutoAssignDM()
{
	if(self.pers["team"] != "allies" && self.pers["team"] != "axis")
	{
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self suicide();
		}

		teams[0] = "allies";
		teams[1] = "axis";
		self.pers["team"] = teams[randomInt(2)];
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");
		if(level.ex_classes == 1) self setClientCvar("ui_allow_classchange", "0");

		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		if(self.pers["team"] == "allies") self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
		else self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		self notify("joined_team");
		self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else if(!isDefined(self.pers["weapon"]))
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
				else self openMenu(game["menu_weapon_axis"]);
		}
	}
}

menuAllies()
{
	if(isDefined(self.spawned)) return;
	
	if(self.pers["team"] != "allies")
	{
		if(self.pers["team"] != "spectator")
		{
			self.switching_teams = true;
			self.joining_team = "allies";
			self.leaving_team = self.pers["team"];
			if(self.sessionstate == "playing") self suicide();
		}

		self.pers["team"] = "allies";
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");
		if(level.ex_classes == 1) self setClientCvar("ui_allow_classchange", "1");

		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);

		// allow team change option on weapons menu if not deathmatch
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "lms" || level.ex_autoassign) self setClientCvar("ui_allow_teamchange", 0);
		else self setClientCvar("ui_allow_teamchange", 1);

		self notify("joined_team");
		if(!level.ex_roundbased) self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else if(!isDefined(self.pers["weapon"])) self openMenu(game["menu_weapon_allies"]);
	}
}

menuAxis()
{
	if(isDefined(self.spawned)) return;

	if(self.pers["team"] != "axis")
	{
		if(self.pers["team"] != "spectator")
		{
			self.switching_teams = true;
			self.joining_team = "axis";
			self.leaving_team = self.pers["team"];
			if(self.sessionstate == "playing") self suicide();
		}

		self.pers["team"] = "axis";
		self.pers["savedmodel"] = undefined;

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self clearWeapons();

		self setClientCvar("ui_allow_weaponchange", "1");
		if(level.ex_classes == 1) self setClientCvar("ui_allow_classchange", "1");

		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);

		// allow team change option on weapons menu if not deathmatch
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "lms" || level.ex_autoassign) self setClientCvar("ui_allow_teamchange", 0);
		else self setClientCvar("ui_allow_teamchange", 1);

		self notify("joined_team");
		if(!level.ex_roundbased) self notify("end_respawn");
	}

	if(level.ex_gameover)
	{
		menuSpectator();
		return;
	}
	else
	{
		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else if(!isDefined(self.pers["weapon"])) self openMenu(game["menu_weapon_axis"]);
	}
}

menuSpectator()
{
	// do not allow anyone to go to spectators
	//if(isDefined(self.spawned)) return;

	// only allow clan 1 members (as set up in clancontrol.cfg) to go to spectators
	//if(isDefined(self.spawned) && (!isDefined(self.ex_name) || self.ex_clid != 1)) return;

	// only allow clan members (clan 1 - 4 as set up in clancontrol.cfg) to go to spectators
	//if(isDefined(self.spawned) && !isDefined(self.ex_name)) return;

	if(self.pers["team"] != "spectator")
	{
		self.switching_teams = true;
		self.joining_team = "spectator";
		self.leaving_team = self.pers["team"];
		if(self.sessionstate == "playing") self suicide();

		self.pers["team"] = "spectator";
		self.pers["savedmodel"] = undefined;
		self.sessionteam = "spectator";

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self clearWeapons();

		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		self setClientCvar("ui_allow_weaponchange", "0");
		if(level.ex_classes == 1) self setClientCvar("ui_allow_classchange", "0");

		extreme\_ex_spawn::spawnspectator();
		
		self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
	}

	self notify("joined_spectators");
}

menuWeapon(response)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || (self.pers["team"] != "allies" && self.pers["team"] != "axis")) return;

	weapon = self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(response);

	if(weapon == "restricted")
	{
		if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
		else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis"]);

		return;
	}

	self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);

	if(level.ex_wepo_secondary)
	{
		if(isDefined(self.pers["weapon2"]) && self.pers["weapon2"] == response)
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
			else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis"]);
	
			return;
		}
	}
	else if(isDefined(self.pers["weapon"]) && self.pers["weapon"] == weapon) return;

	self maps\mp\gametypes\_weapons::updateDisabledSingleClient(weapon);

	if(!isDefined(self.pers["weapon"]))
	{
		self.pers["weapon"] = weapon;
		if(level.ex_wepo_secondary) self.pers["weapon1"] = weapon;

		if(!level.ex_wepo_secondary)
		{
			if(!isDefined(self.ex_team_changed) && isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize)) )
			{
				self [[level.respawnplayer]](true);
			}
			else
			{
				playerHudDestroy("respawn_timer");
				[[level.spawnplayer]]();
			}
		}
		else
		{
			if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies_sec"]);
			else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis_sec"]);

			return;
		}
	}
	else
	{
		self maps\mp\gametypes\_weapons::updateEnabledSingleClient(self.pers["weapon"]);

		self.pers["weapon"] = weapon;
		if(level.ex_wepo_secondary) self.pers["weapon1"] = weapon;

		weaponname = maps\mp\gametypes\_weapons::getWeaponName(weapon);
		if(level.ex_roundbased && (level.ex_currentgt == "sd" || level.ex_currentgt == "lts"))
		{
			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_SPAWN_WITH_AN_NEXT_ROUND", weaponname);
				else self iprintln(&"MP_YOU_WILL_SPAWN_WITH_A_NEXT_ROUND", weaponname);
		}
		else
		{
			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"])) self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN", weaponname);
				else self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A", weaponname);
		}
	}

	level thread maps\mp\gametypes\_weapons::updateAllowed();

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

menuSecWeapon(response)
{
	self endon("disconnect");

	weapon = self maps\mp\gametypes\_weapons::restrictWeaponByServerCvars(response);

	if(weapon == "restricted" || (isDefined(self.pers["weapon1"]) && self.pers["weapon1"] == response))
	{
		if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies_sec"]);
		else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis_sec"]);

		return;
	}

	self maps\mp\gametypes\_weapons::updateDisabledSingleClient(weapon);

	if(!isDefined(self.pers["weapon2"]))
	{
		self.pers["weapon2"] = weapon;

		if(!isDefined(self.ex_team_changed) && (isDefined(self.WaitingToSpawn) || (level.ex_currentgt == "hq" && (self.pers["team"] == level.DefendingRadioTeam) && isDefined(self.WaitingOnNeutralize))) )
		{
			self [[level.respawnplayer]](true);
		}
		else
		{
			playerHudDestroy("respawn_timer");
			[[level.spawnplayer]]();
		}
	}
	else
	{
		self maps\mp\gametypes\_weapons::updateEnabledSingleClient(self.pers["weapon2"]);

		self.pers["weapon2"] = weapon;

		weaponname = maps\mp\gametypes\_weapons::getWeaponName(weapon);
		if(level.ex_roundbased && (level.ex_currentgt == "sd" || level.ex_currentgt == "lts"))
		{
			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_SPAWN_WITH_AN_NEXT_ROUND_SECONDARY", weaponname);
				else self iprintln(&"MP_YOU_WILL_SPAWN_WITH_A_NEXT_ROUND_SECONDARY", weaponname);
		}
		else
		{
			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon2"])) self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN_SECONDARY", weaponname);
				else self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A_SECONDARY", weaponname);
		}
	}		

	level thread maps\mp\gametypes\_weapons::updateAllowed();

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

clearWeapons()
{
	self endon("disconnect");

	// clear weapon selection
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
}

spectatorMusicMonitor()
{
	self endon("disconnect");

	mt = undefined;

	hud_index = playerHudCreate("spec_music", 322, 462, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"MISC_MELEE_CHANGE_MUSIC");

	for(;;)
	{
		if(self meleeButtonPressed())
		{
			self playLocalSound("spec_music_null");
			self playLocalSound("spec_music_stop");

			playerHudFade(hud_index, 0.2, 0.2, 0);
			playerHudSetText(hud_index, &"MISC_MUSIC_CHNG");
			playerHudFade(hud_index, 0.2, 0, 1);
			self playLocalSound("spec_music");
			mt = 30;
		}

		if(isDefined(mt))
		{
			if(mt <= 0)
			{
				mt = undefined;
				playerHudFade(hud_index, 0.2, 0.2, 0);
				playerHudSetText(hud_index, &"MISC_MELEE_CHANGE_MUSIC");
				playerHudFade(hud_index, 0.2, 0, 1);
			}
			else mt--;
		}

		if(!self.pers["spec_on"] || level.ex_gameover == true)
		{
			playerHudDestroy(hud_index);
			break;
		}

		wait( [[level.ex_fpstime]](0.1) );
	}
}
