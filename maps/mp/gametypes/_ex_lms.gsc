#include extreme\_ex_hudcontroller;

/*QUAKED mp_dm_spawn (1.0 0.5 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies at one of these positions.*/

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = extreme\_ex_clientcontrol::menuAutoAssignDM;
	level.allies = extreme\_ex_clientcontrol::menuAllies;
	level.axis = extreme\_ex_clientcontrol::menuAxis;
	level.spectator = extreme\_ex_clientcontrol::menuSpectator;
	level.weapon = extreme\_ex_clientcontrol::menuWeapon;
	level.secweapon = extreme\_ex_clientcontrol::menuSecWeapon;
	level.spawnplayer = ::spawnplayer;
	level.updatetimer = ::blank;
	level.endgameconfirmed = ::endMap;
	level.checkscorelimit = ::checkScoreLimit;

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();
}

blank(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
{
	wait(0);
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	if(!isDefined(game["precachedone"]))
	{
		[[level.ex_PrecacheRumble]]("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("hud_status_dead");
			[[level.ex_PrecacheStatusIcon]]("hud_status_connecting");
		}
		[[level.ex_PrecacheShader]]("hud_status_dead");
		[[level.ex_PrecacheShader]]("objpoint_A");
		[[level.ex_PrecacheShader]]("objpoint_B");
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");
		[[level.ex_PrecacheString]](&"LMS_JOINOMETER");
		[[level.ex_PrecacheString]](&"LMS_KILLOMETER");
		[[level.ex_PrecacheString]](&"LMS_DIEOMETER");
		[[level.ex_PrecacheString]](&"LMS_DUELOMETER");
		[[level.ex_PrecacheString]](&"LMS_ALIVE");
		[[level.ex_PrecacheString]](&"LMS_OPPONENT");
		[[level.ex_PrecacheString]](&"LMS_PLAYERA");
		[[level.ex_PrecacheString]](&"LMS_PLAYERB");
		[[level.ex_PrecacheString]](&"LMS_DISTANCE");
		[[level.ex_PrecacheString]](&"LMS_HEALTH");
		[[level.ex_PrecacheString]](&"LMS_WEAPON");
		[[level.ex_PrecacheString]](&"LMS_AMMO");
		[[level.ex_PrecacheString]](&"LMS_SNIPER");
		[[level.ex_PrecacheString]](&"LMS_RIFLE");
		[[level.ex_PrecacheString]](&"LMS_SHOTGUN");
		[[level.ex_PrecacheString]](&"LMS_MG");
		[[level.ex_PrecacheString]](&"LMS_PISTOL");
		[[level.ex_PrecacheString]](&"LMS_KNIFE");
		[[level.ex_PrecacheString]](&"LMS_SPRINT");
		[[level.ex_PrecacheString]](&"LMS_TURRET");
		[[level.ex_PrecacheString]](&"LMS_RL");
		[[level.ex_PrecacheString]](&"LMS_FRAG");
		[[level.ex_PrecacheString]](&"LMS_SMOKE");
		[[level.ex_PrecacheString]](&"LMS_FLAMETHROWER");
		[[level.ex_PrecacheString]](&"LMS_NONE");
	}

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_playerscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread maps\mp\gametypes\_models::init();
	extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	spawnpointname = "mp_dm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.jointimeleft = level.joinperiodtime;
	level.dueltimeleft = level.duelperiodtime;

	level.matchstarted = false;
	level.joinperiod = false;
	level.endingmatch = false;
	level.duel = false;
	level.oldbarsize = 0;
	level.QuickMessageToAll = true;
	level.mapended = false;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	thread startGame();
	thread updateGametypeCvars();

	// launch eXtreme+
	extreme\_ex_main::main();
}

dummy()
{
	waittillframeend;
	if(isDefined(self)) level notify("connecting", self);
}

Callback_PlayerConnect()
{
	thread dummy();

	playerHudSetStatusIcon("hud_status_connecting");
	self waittill("begin");
	self.statusicon = "";

	level notify("connected", self);
	self waittill("events_initialized");

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("J;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	if(game["state"] == "intermission")
	{
		extreme\_ex_spawn::spawnIntermission();
		return;
	}

	level endon("intermission");

	if(level.mapended)
	{
		extreme\_ex_spawn::spawnPreIntermission();
		return;
	}

	scriptMainMenu = game["menu_ingame"];

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self setClientCvar("ui_allow_weaponchange", "1");
		self.sessionteam = "none";

		if(isDefined(self.pers["weapon"]))
		{
			spawnPlayer();
		}
		else
		{
			extreme\_ex_spawn::spawnspectator();

			if(self.pers["team"] == "allies")
			{
				self openMenu(game["menu_weapon_allies"]);
				scriptMainMenu = game["menu_weapon_allies"];
			}
			else
			{
				self openMenu(game["menu_weapon_axis"]);
				scriptMainMenu = game["menu_weapon_axis"];
			}
		}
	}
	else
	{
		self setClientCvar("ui_allow_weaponchange", "0");

		if(!isDefined(self.pers["skipserverinfo"]))
		{
			extreme\_ex_clientcontrol::exPlayerPreServerInfo();
			self openMenu(game["menu_serverinfo"]);
			self.pers["skipserverinfo"] = true;
		}

		self.pers["team"] = "spectator";
		self.sessionteam = "spectator";

		extreme\_ex_spawn::spawnspectator();
	}

	self setClientCvar("g_scriptMainMenu", scriptMainMenu);
}

Callback_PlayerDisconnect()
{
	checkAlivePlayers();
	self removeKillOMeter();

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable) return;
	if(game["matchpaused"]) return;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		// Make sure at least one point of damage is done
		if(iDamage < 1) iDamage = 1;

		// Apply the damage to the player
		self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
		self playrumble("damage_heavy");

		if(isDefined(eAttacker) && eAttacker != self)
			eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
	}

	// Do debug print if it's enabled
	if(getCvarInt("g_debugDamage"))
	{
		println("client:" + self getEntityNumber() + " health:" + self.health +
			" damage:" + iDamage + " hitLoc:" + sHitLoc);
	}

	if(level.ex_logdamage && self.sessionstate != "dead")
	{
		lpselfguid = self getGuid();
		lpselfnum = self getEntityNumber();
		lpselfteam = self.pers["team"];
		lpselfname = self.name;

		if(isPlayer(eAttacker))
		{
			lpattackguid = eAttacker getGuid();
			lpattacknum = eAttacker getEntityNumber();
			lpattackteam = eAttacker.pers["team"];
			lpattackname = eAttacker.name;
		}
		else
		{
			lpattackguid = "";
			lpattacknum = -1;
			lpattackteam = "world";
			lpattackname = "";
		}

		logPrint("D;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator") return;
	if(game["matchpaused"]) return;

	self.ex_confirmkill = 0;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self thread removeKillOMeter();
	self thread removeDuelHud();

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	playerHudSetStatusIcon("hud_status_dead");
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isDefined(self.switching_teams))
	{
		self.pers["death"]++;
		self.deaths = self.pers["death"];
	}

	lpselfguid = self getGuid();
	lpselfnum = self getEntityNumber();
	lpselfteam = "";
	lpselfname = self.name;
	lpattackteam = "";

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			lpattackguid = lpselfguid;
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			doKillcam = false;
		}
		else
		{
			lpattackguid = attacker getGuid();
			lpattacknum = attacker getEntityNumber();
			lpattackname = attacker.name;
			doKillcam = true;

			attacker.killometer = level.killometer;
			attacker updateKillOMeter();
		}
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		lpattackguid = "";
		lpattacknum = -1;
		lpattackteam = "world";
		lpattackname = "";
		doKillcam = false;
	}

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	// Stop thread if map ended on this death
	if(level.mapended) return;

	if(isDefined(self.switching_teams))
		self.ex_team_changed = true;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	body = self cloneplayer(deathAnimDuration);
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"]);

	if(!isDefined(self.nowinner)) checkAlivePlayers();
		else self.nowinner = undefined;

	delay = 2; // Delay the player becoming a spectator till after he's done dying
	wait( [[level.ex_fpstime]](delay) ); // Also required for Callback_PlayerKilled to complete before killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(lpattacknum, delay, psOffsetTime, true);

	self thread spawnPlayer();
}

spawnPlayer()
{
	self endon("disconnect");

	// Avoid duplicates
	self notify("lms_respawn");
	self endon("lms_respawn");

	// Wait for spawn if we are not in the first joinperiod or if we have already spawned once.
	if(!level.joinperiod || isDefined(self.spawned))
	{
		self.sessionteam = "none";
		self.sessionstate = "spectator";

		if(isDefined(self.dead_origin) && isDefined(self.dead_angles))
		{
			origin = self.dead_origin + (0, 0, 16);
			angles = self.dead_angles;
		}
		else
		{
			origin = self.origin + (0, 0, 16);
			angles = self.angles;
		}
		self spawn(origin, angles);
		playerHudSetStatusIcon("hud_status_dead");

		if(!level.matchstarted) thread countPlayers();
			else self iprintlnbold(&"LMS_NEXT_CYCLE");

		level waittill("lms_spawn_players");
	}
	
	// Flag player as one that has spawned at least once
	self.spawned = true;

	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionteam = "none";
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = level.ex_player_maxhealth;
	self.health = self.maxhealth;

	self extreme\_ex_main::exPreSpawn();
	
	self.perk_insertion = false;
	if(level.ex_insertion)
	{
		insertion_info = extreme\_ex_specials_insertion::insertionGetFrom(self);
		if(insertion_info["exists"])
		{
			self.perk_insertion = true;
			self spawn(insertion_info["origin"], insertion_info["angles"]);
		}
	}

	if(!self.perk_insertion)
	{
		spawnpointname = "mp_dm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_DM(spawnpoints);

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["scorelimit"] > 0) self setClientCvar("cg_objectiveText", &"LMS_OBJ_TEXT", game["scorelimit"]);
		else self setClientCvar("cg_objectiveText", &"LMS_OBJ_TEXT_NOSCORE");

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");

	checkAlivePlayers(true);
	self thread killOMeter();
}

startGame()
{
	if(game["timelimit"] > 0) extreme\_ex_gtcommon::createClock(game["timelimit"] * 60);

	updateAlivePlayersHud(0);

	while(!level.ex_gameover)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

endMap()
{
	players = level.players;
	highscore = undefined;
	tied = false;
	winner = undefined;
	guid = undefined;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] == "spectator") continue;

		if(!isDefined(highscore))
		{
			winner = player;
			highscore = player.pers["score"];
			guid = player getGuid();
			continue;
		}

		if(player.pers["score"] > highscore)
		{
			tied = false;
			winner = player;
			highscore = player.pers["score"];
			guid = player getGuid();
		}
		else if(player.pers["score"] == highscore) tied = true;
	}

	extreme\_ex_main::exEndMap();

	game["state"] = "intermission";
	level notify("intermission");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(tied) player setClientCvar("cg_objectiveText", &"MP_THE_GAME_IS_A_TIE");
			else if(isDefined(winner)) player setClientCvar("cg_objectiveText", &"MP_WINS", winner);

		player closeMenu();
		player closeInGameMenu();
		player extreme\_ex_spawn::spawnIntermission();
		player playerHudRestoreStatusIcon();
	}

	if(!tied && isDefined(winner)) logPrint("W;;" + guid + ";" + winner.name + "\n");

	wait( [[level.ex_fpstime]](level.ex_intermission) );

	exitLevel(false);
}

checkTimeLimit()
{
	if(game["timelimit"] <= 0) return;
	if(game["matchpaused"]) return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(timepassed < game["timelimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_TIME_LIMIT_REACHED");

	level thread endMap();
}

checkScoreLimit()
{
	if(game["scorelimit"] <= 0) return;
	if(game["matchpaused"]) return;

	if(self.pers["score"] < game["scorelimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	while(!level.ex_gameover && !game["matchpaused"])
	{
		timelimit = getCvarFloat("scr_lms_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_lms_timelimit", "1440");
			}

			if(timelimit < game["timelimit"])
			{
				timepassed = 0;
				level.starttime = getTime();
			}
			else timepassed = ((getTime() - level.starttime) / 1000) / 60.0;

			game["timelimit"] = timelimit;
			setCvar("ui_timelimit", game["timelimit"]);

			if(game["timelimit"] > 0)
			{
				timelimit = game["timelimit"] - timepassed;
				extreme\_ex_gtcommon::createClock(timelimit * 60);

				checkTimeLimit();
			}
			else extreme\_ex_gtcommon::destroyClock();
		}

		scorelimit = getCvarInt("scr_lms_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			players = level.players;
			for(i = 0; i < players.size; i++) players[i] checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

updateAlivePlayersHud(n)
{
	hud_index = levelHudIndex("lms_alive");
	if(hud_index == -1)
	{
		hud_index = levelHudCreate("lms_alive", undefined, 320, 20, 0.8, (1,1,1), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index == -1) return;
		levelHudSetLabel(hud_index, &"LMS_ALIVE");
	}
	levelHudSetValue(hud_index, n);
}

checkAlivePlayers(spawn)
{
	// Count the players who are still alive
	n = 0;
	lastOnesAlive1 = undefined;
	lastOnesAlive2 = undefined;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player) && isAlive(player))
		{
			n++;

			// Save the two last players
			if(isDefined(lastOnesAlive1)) lastOnesAlive2 = lastOnesAlive1;
			lastOnesAlive1 = player;
		}
	}

	updateAlivePlayersHud(n);

	// Do not check for winners when players spawn
	if(isDefined(spawn)) return;

	// Do we have a winner?
	if(n < 2) level thread endMatch(lastOnesAlive1);
		else if(n == 2) level thread duel(lastOnesAlive1, lastOnesAlive2);
}

countPlayers()
{
	// Count the players who have chosen their team
	n = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator") n++;
	}

	// Do we have enough players to start?
	if(n >= level.minplayers) level thread watchJoinPeriod();
		else iprintlnbold(&"LMS_WAITING", (level.minplayers - n), &"LMS_PLAYERS");
}

watchJoinPeriod()
{
	level notify("end_watchJoinPeriod");
	level endon("end_watchJoinPeriod");

	// Make sure we have only one thread
	if(level.joinperiod) return;
	level.joinperiod = true;
	level.jointimeleft = level.joinperiodtime;

	// Officially start the game
	level.matchstarted = true;
	
	// Spawn all waiting players
	iprintlnbold(&"LMS_SPAWNING");
	level notify("lms_spawn_players");

	iprintlnbold(&"LMS_OPEN_FOR_JOIN", level.joinperiodtime, &"LMS_SECONDS");
	// Allow new players to join for the specified amount of time
	for(i = 0; i < level.joinperiodtime; i++)
	{
		level.jointimeleft = level.joinperiodtime - i;
		wait( [[level.ex_fpstime]](1) );
	}
	iprintlnbold(&"LMS_NO_JOIN");

	// Join period is officially over
	level.joinperiod = false;
}

endMatch(winner)
{
	// Avoid dups
	if(level.endingmatch) return;
	level.endingmatch = true;

	// Reset flags
	level.joinperiod = false;
	level.duel = false;

	// Kill threads
	level notify("end_killometers");
	level notify("end_duel");

	removeDuelOMeter();
	removeSpectatorHuds();

	// Announce winner
	if(isDefined(winner))
	{
		iprintlnbold(&"LMS_WINNER", [[level.ex_pname]](winner));

		winner thread [[level.pscoreproc]](1, undefined, undefined, false);
		winner thread removeDuelHud();
		wait( [[level.ex_fpstime]](1) );

		if(level.killwinner && isAlive(winner))
		{
			winner.ex_forcedsuicide = true;
			winner suicide();
		}
	}
	else iprintlnbold(&"LMS_NO_SURVIVE");

	wait( [[level.ex_fpstime]](4) );
	if(isDefined(winner)) winner checkScoreLimit();

	// Did the map end?
	if(level.mapended) return;

	// Reset player flags for dead players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isAlive(player)) player.spawned = undefined;

		player.killometer = level.killometer;
		player updateKillOMeter();
	}

	// Restart the kill-o-meter for the winner if still alive
	if(isDefined(winner) && isAlive(winner)) winner thread killometer();

	// Start a new join period
	level notify("end_watchJoinPeriod");
	wait( [[level.ex_fpstime]](0.05) );
	level.joinperiod = false;
	level thread watchJoinPeriod();

	level.endingmatch = false;
}

killOMeter()
{
	level endon("end_killometers");
	self endon("disconnect");
	self endon("spawned");
	self endon("killed_player");

	// Avoid duplicate threads, happens sometimes, reason unknown
	self notify("end_killometer");
	wait( [[level.ex_fpstime]](0.05) );
	self endon("end_killometer");

	self.killometer = level.killometer;
	self setupKillOMeter();

	while(isAlive(self) && self.sessionstate == "playing")
	{
		updateKillOMeter();
		wait( [[level.ex_fpstime]](1) );
		if(self.killometer && !level.joinperiod)
			self.killometer--;
		else if(!self.killometer)
		{
			self.ex_forcedsuicide = true;
			self suicide();
		}
	}
	self removeKillOMeter();
}

setupKillOMeter()
{
	y = 10;
	barsize = 300;

	self.oldbarsize = barsize;

	self removeKillOMeter();

	hud_index = playerHudCreate("lms_killmeter_back", 320, y, 0.3, (0.2,0.2,0.2), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "white", barsize+4, 13);

	hud_index = playerHudCreate("lms_killmeter_progress", 320, y, 0.5, (0,1,0), 1, 2, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "white", barsize, 11);

	hud_index = playerHudCreate("lms_killmeter_text", 320, y, 0.8, (1,1,1), 1, 3, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_KILLOMETER");
}

removeKillOMeter()
{
	playerHudDestroy("lms_killmeter_back");
	playerHudDestroy("lms_killmeter_progress");
	playerHudDestroy("lms_killmeter_text");
}

updateKillOMeter()
{
	y = 10;
	barsize = 300;

	hud_index = playerHudIndex("lms_killmeter_progress");
	if(hud_index != -1)
	{
		if(level.joinperiod)
		{
			pc = level.jointimeleft/level.joinperiodtime;
			playerHudSetText("lms_killmeter_text", &"LMS_JOINOMETER");
			playerHudSetColor(hud_index, (0,0,1));
		}
		else
		{
			pc = self.killometer/level.killometer;
			if(pc >= 0.55)
			{
				c = 1 - (pc - 0.55)/0.45;
				playerHudSetText("lms_killmeter_text", &"LMS_KILLOMETER");
				playerHudSetColor(hud_index, (1*c,1,0));
			}
			else if(pc >= 0.1)
			{
				c = (pc-0.1)/0.45;
				playerHudSetText("lms_killmeter_text", &"LMS_KILLOMETER");
				playerHudSetColor(hud_index, (1,1*c,0));
			}
			else
			{
				playerHudSetText("lms_killmeter_text", &"LMS_DIEOMETER");
				playerHudSetColor(hud_index, (1,0,0));
			}
		}

		size = int(barsize * pc + 0.5);
		if(size < 1) size = 1;
		if(self.oldbarsize != size)
		{
			playerHudScale(hud_index, 1, 0, size, 11);
			self.oldbarsize = size;
		}
	}
}

duel(p1, p2)
{
	level notify("end_duel");
	level endon("end_duel");
	if(level.duel) return;
	level.duel = true;
	level.dueltimeleft = level.duelperiodtime;

	// End join period
	level notify("end_watchJoinPeriod");
	level.joinperiod = false;

	iprintlnbold(&"LMS_DUEL", level.duelperiodtime, &"LMS_SECONDS");

	// Small delay to let last player dying join the spectators
	wait( [[level.ex_fpstime]](2) );

	if(isDefined(p1) && isAlive(p1) && isDefined(p2) && isAlive(p2))
	{
		p1 notify("end_killometer");
		p2 notify("end_killometer");
		p1 removeKillOMeter();
		p2 removeKillOMeter();
		p1 thread duelHud(p2);
		p2 thread duelHud(p1);
	}

	setupDuelOMeter();

	setupSpectatorHuds(p1,p2);

	for(i = 0; i < level.duelperiodtime; i++)
	{
		level.dueltimeleft = level.duelperiodtime - i;
		updateDuelOMeter();
		wait( [[level.ex_fpstime]](1) );
	}

	// If we get here then there is no winners, kill the loosers...
	iprintlnbold(&"LMS_SUCKS");
	p1.nowinner = true;
	p1.ex_forcedsuicide = true;
	p1 suicide();
	p2.ex_forcedsuicide = true;
	p2 suicide();

	// End match without winner
	endMatch(undefined);
}

duelHud(other)
{
	self endon("end_duelhud");

	size = 70;
	x = 6;
	y = 60;

	other.dh_weapon = &"LMS_NONE";
	other.dh_ammo = 0;

	titlecolor = (1,1,1);
	subtitlecolor = (0.8,0.8,0.8);
	valuecolor = (1,1,0);

	hud_index = playerHudCreate("lms_duelhud_back", x, y, 0.3, (0,0,0.2), 1, 0, "left", "top", "left", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "white", 1, 135);
	playerHudScale(hud_index, 1, 1, size, 135);

	if(!isDefined(self) || !isDefined(other) || !isAlive(self) || !isAlive(other)) return;

	dist = int(distance(self.origin, other.origin) * 0.0254 + 0.5);
	cw = other getCurrentWeapon();
	weapon = weaponType(cw);
	ammo = other getammocount(cw);

	other.dh_weapon = weapon;
	other.dh_ammo = ammo;

	hud_index = playerHudCreate("lms_duelhud_title", x+(size/2), y+2, 0, titlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_OPPONENT");
	playerHudFade(hud_index, 1, 0, 1);

	hud_index = playerHudCreate("lms_duelhud_disttxt", x+(size/2), y+17, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_DISTANCE");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_duelhud_dist", x+(size/2), y+30, 0, valuecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, dist);
	playerHudFade(hud_index, 1, 0, 0.8);
	
	hud_index = playerHudCreate("lms_duelhud_healthtxt", x+(size/2), y+47, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_HEALTH");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_duelhud_health", x+(size/2), y+60, 0, valuecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, other.health);
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_duelhud_weapontxt", x+(size/2), y+77, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_WEAPON");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_duelhud_weapon", x+(size/2), y+90, 0, valuecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, weapon);
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_duelhud_ammotxt", x+(size/2), y+107, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_AMMO");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_duelhud_ammo", x+(size/2), y+120, 0, valuecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, ammo);
	playerHudFade(hud_index, 1, 0, 0.8);

	while(isDefined(self) && isAlive(self) && self.sessionstate == "playing" && isDefined(other) && isAlive(other) && other.sessionstate == "playing")
	{
		dist = int(distance(self.origin, other.origin) * 0.0254 + 0.5);
		playerHudSetValue("lms_duelhud_dist", dist);
		playerHudSetValue("lms_duelhud_health", other.health);

		cw = other getCurrentWeapon();
		weapon = weaponType(cw);
		ammo = other getammocount(cw);
		playerHudSetText("lms_duelhud_weapon", weapon);
		playerHudSetValue("lms_duelhud_ammo", ammo);

		other.dh_weapon = weapon;
		other.dh_ammo = ammo;

		wait( [[level.ex_fpstime]](0.5) );
	}
}

removeDuelHud()
{
	// End thread
	self notify("end_duelhud");

	// Fade away text
	hud_index = playerHudIndex("lms_duelhud_title");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_duelhud_disttxt");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_duelhud_dist");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_duelhud_healthtxt");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_duelhud_health");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_duelhud_weapontxt");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_duelhud_weapon");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_duelhud_ammotxt");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_duelhud_ammo");
	if(hud_index != -1) playerHudFade(hud_index, 1, 1, 0);

	hud_index = playerHudIndex("lms_duelhud_back");
	if(hud_index != -1) playerHudScale(hud_index, 1, 1, 1, 135);

	// Remove HUD elements
	playerHudDestroy("lms_duelhud_title");
	playerHudDestroy("lms_duelhud_disttxt");
	playerHudDestroy("lms_duelhud_dist");
	playerHudDestroy("lms_duelhud_healthtxt");
	playerHudDestroy("lms_duelhud_health");
	playerHudDestroy("lms_duelhud_weapontxt");
	playerHudDestroy("lms_duelhud_weapon");
	playerHudDestroy("lms_duelhud_ammotxt");
	playerHudDestroy("lms_duelhud_ammo");
	playerHudDestroy("lms_duelhud_back");
}

weaponType(cw)
{
	if(extreme\_ex_weapons::isWeaponType(cw, "rifle")) weapon = &"LMS_RIFLE";
	else if(extreme\_ex_weapons::isWeaponType(cw, "mg") || extreme\_ex_weapons::isWeaponType(cw, "smg")) weapon = &"LMS_MG";
	else if(extreme\_ex_weapons::isWeaponType(cw, "sniper")) weapon = &"LMS_SNIPER";
	else if(extreme\_ex_weapons::isWeaponType(cw, "shotgun")) weapon = &"LMS_SHOTGUN";
	else if(extreme\_ex_weapons::isWeaponType(cw, "pistol")) weapon = &"LMS_PISTOL";
	else if(extreme\_ex_weapons::isWeaponType(cw, "knife")) weapon = &"LMS_KNIFE";
	else if(extreme\_ex_weapons::isWeaponType(cw, "turret")) weapon = &"LMS_TURRET";
	else if(extreme\_ex_weapons::isWeaponType(cw, "ft")) weapon = &"LMS_FLAMETHROWER";
	else if(extreme\_ex_weapons::isWeaponType(cw, "frag") || extreme\_ex_weapons::isWeaponType(cw, "fire") ||
		extreme\_ex_weapons::isWeaponType(cw, "gas") || extreme\_ex_weapons::isWeaponType(cw, "satchel")) weapon = &"LMS_FRAG";
	else if(extreme\_ex_weapons::isWeaponType(cw, "smoke")) weapon = &"LMS_SMOKE";
	else if(extreme\_ex_weapons::isWeaponType(cw, "rl")) weapon = &"LMS_RL";
	else if(cw == game["sprint"]) weapon = &"LMS_SPRINT";
	else weapon = &"LMS_NONE";

	return weapon;
}

setupDuelOMeter()
{
	y = 10;
	barsize = 300;
	level.oldbarsize = barsize;

	level removeDuelOMeter();

	hud_index = levelHudCreate("lms_duelmeter_back", undefined, 320, y, 0.3, (0.2,0.2,0.2), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", barsize+4, 13);

	hud_index = levelHudCreate("lms_duelmeter_progress", undefined, 320, y, 0.5, (1,1,0), 1, 2, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", barsize, 11);

	hud_index = levelHudCreate("lms_duelmeter_text", undefined, 320, y, 0.8, (1,1,1), 1, 3, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetText(hud_index, &"LMS_DUELOMETER");
}

removeDuelOMeter()
{
	levelHudDestroy("lms_duelmeter_back");
	levelHudDestroy("lms_duelmeter_progress");
	levelHudDestroy("lms_duelmeter_text");
}

updateDuelOMeter()
{
	y = 10;
	barsize = 300;

	hud_index = levelHudIndex("lms_duelmeter_progress");
	if(hud_index != -1)
	{
		pc = level.dueltimeleft/level.duelperiodtime;
		levelHudSetColor(hud_index, (1,1*pc,0));

		size = int(barsize * pc + 0.5);
		if(size < 1) size = 1;
		if(level.oldbarsize != size)
		{
			levelHudScale(hud_index, 1, 0, size, 11);
			level.oldbarsize = size;
		}
	}
}

setupSpectatorHuds(a, b)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player) && !isAlive(player)) player thread spectatorHud(a, b);
	}
}

spectatorHud(a, b)
{
	self endon("disconnect");
	self endon("end_spectatorhud");

	self.spectatorhud = true;

	size = 70;
	x = 6;
	y = 60;
	x2 = x + y + 20;

	titlecolor = (1,1,1);
	subtitlecolor = (0.8,0.8,0.8);
	valuecolor = (0,0.8,0);
	valuecolor2 = (0.8,0,0);

	hud_index = playerHudCreate("lms_spechud_back1", x, y, 0.3, (0,0,0.2), 1, 0, "left", "top", "left", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "white", 1, 135);
	playerHudScale(hud_index, 1, 0, size, 135);

	hud_index = playerHudCreate("lms_spechud_back2", x2, y, 0.3, (0.2,0,0), 1, 0, "left", "top", "left", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "white", 1, 135);
	playerHudScale(hud_index, 1, 1, size, 135);

	if(!isDefined(a) || !isDefined(b) || !isAlive(a) || !isAlive(b)) return;

	hud_index = playerHudCreate("lms_spechud_title1", x+(size/2), y+2, 0, titlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_PLAYERA");
	playerHudFade(hud_index, 1, 0, 1);

	hud_index = playerHudCreate("lms_spechud_disttxt1", x+(size/2), y+17, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_DISTANCE");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_dist1", x+(size/2), y+30, 0, valuecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, 0);
	playerHudFade(hud_index, 1, 0, 0.8);
	
	hud_index = playerHudCreate("lms_spechud_healthtxt1", x+(size/2), y+47, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_HEALTH");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_health1", x+(size/2), y+60, 0, valuecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, a.health);
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_weapontxt1", x+(size/2), y+77, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_WEAPON");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_weapon1", x+(size/2), y+90, 0, valuecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, a.dh_weapon);
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_ammotxt1", x+(size/2), y+107, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_AMMO");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_ammo1", x+(size/2), y+120, 0, valuecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, a.dh_ammo);
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_title2", x2+(size/2), y+2, 0, titlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_PLAYERB");
	playerHudFade(hud_index, 1, 0, 1);

	hud_index = playerHudCreate("lms_spechud_disttxt2", x2+(size/2), y+17, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_DISTANCE");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_dist2", x2+(size/2), y+30, 0, valuecolor2, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, 0);
	playerHudFade(hud_index, 1, 0, 0.8);
	
	hud_index = playerHudCreate("lms_spechud_healthtxt2", x2+(size/2), y+47, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_HEALTH");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_health2", x2+(size/2), y+60, 0, valuecolor2, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, b.health);
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_weapontxt2", x2+(size/2), y+77, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_WEAPON");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_weapon2", x2+(size/2), y+90, 0, valuecolor2, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, b.dh_weapon);
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_ammotxt2", x2+(size/2), y+107, 0, subtitlecolor, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, &"LMS_AMMO");
	playerHudFade(hud_index, 1, 0, 0.8);

	hud_index = playerHudCreate("lms_spechud_ammo2", x2+(size/2), y+120, 0, valuecolor2, 1, 1, "left", "top", "center", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetValue(hud_index, b.dh_ammo);
	playerHudFade(hud_index, 1, 0, 0.8);

	// Add objective points
	hud_index = playerHudCreate("lms_spechud_wp1", a.origin[0], a.origin[1], 0.61, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "objpoint_A", 7, 7);
	playerHudSetWaypoint(hud_index, a.origin[2] + 70, true);
	playerHudSetWaypointUpdateProc(hud_index, ::spectatorHudWaypointA, a, 0.1);

	hud_index = playerHudCreate("lms_spechud_wp2", b.origin[0], b.origin[1], 0.61, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "objpoint_B", 7, 7);
	playerHudSetWaypoint(hud_index, b.origin[2] + 70, true);
	playerHudSetWaypointUpdateProc(hud_index, ::spectatorHudWaypointB, b, 0.1);

	while(isDefined(a) && isAlive(a) && a.sessionstate == "playing" && isDefined(b) && isAlive(b) && b.sessionstate == "playing")
	{
		//playerHudSetXYZ("lms_spechud_wp1", a.origin[0], a.origin[1], a.origin[2] + 70);
		//playerHudSetXYZ("lms_spechud_wp2", b.origin[0], b.origin[1], b.origin[2] + 70);

		dist = int(distance(a.origin, b.origin) * 0.0254 + 0.5);
		playerHudSetValue("lms_spechud_dist1", dist);
		playerHudSetValue("lms_spechud_health1", a.health);
		playerHudSetText("lms_spechud_weapon1", a.dh_weapon);
		playerHudSetValue("lms_spechud_ammo1", a.dh_ammo);

		playerHudSetValue("lms_spechud_dist2", dist);
		playerHudSetValue("lms_spechud_health2", b.health);
		playerHudSetText("lms_spechud_weapon2", b.dh_weapon);
		playerHudSetValue("lms_spechud_ammo2", b.dh_ammo);

		wait( [[level.ex_fpstime]](0.5) );
	}
}

spectatorHudWaypointA(hud_index, entity)
{
	if(isDefined(entity)) playerHudSetXYZ(hud_index, entity.origin[0], entity.origin[1], entity.origin[2] + 70);
}

spectatorHudWaypointB(hud_index, entity)
{
	if(isDefined(entity)) playerHudSetXYZ(hud_index, entity.origin[0], entity.origin[1], entity.origin[2] + 70);
}

removeSpectatorHuds()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player) && isDefined(player.spectatorhud)) player thread removeSpectatorHud();
	}
}

removeSpectatorHud()
{
	// End thread
	self notify("end_spectatorhud");

	self.spectatorhud = undefined;

	// Remove objective points
	playerHudDestroy("lms_spechud_wp1");
	playerHudDestroy("lms_spechud_wp2");

	// Fade away text
	hud_index = playerHudIndex("lms_spechud_title1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_disttxt1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_dist1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_healthtxt1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_health1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_weapontxt1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_weapon1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_ammotxt1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_ammo1");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_title2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_disttxt2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_dist2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_healthtxt2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_health2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_weapontxt2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_weapon2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_ammotxt2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

	hud_index = playerHudIndex("lms_spechud_ammo2");
	if(hud_index != -1) playerHudFade(hud_index, 1, 1, 0);

	hud_index = playerHudIndex("lms_spechud_back1");
	if(hud_index != -1) playerHudScale(hud_index, 1, 0, 1, 135);

	hud_index = playerHudIndex("lms_spechud_back2");
	if(hud_index != -1) playerHudScale(hud_index, 1, 1, 1, 135);

	// Remove HUD elements
	playerHudDestroy("lms_spechud_title1");
	playerHudDestroy("lms_spechud_disttxt1");
	playerHudDestroy("lms_spechud_dist1");
	playerHudDestroy("lms_spechud_healthtxt1");
	playerHudDestroy("lms_spechud_health1");
	playerHudDestroy("lms_spechud_weapontxt1");
	playerHudDestroy("lms_spechud_weapon1");
	playerHudDestroy("lms_spechud_ammotxt1");
	playerHudDestroy("lms_spechud_ammo1");
	playerHudDestroy("lms_spechud_back1");

	playerHudDestroy("lms_spechud_title2");
	playerHudDestroy("lms_spechud_disttxt2");
	playerHudDestroy("lms_spechud_dist2");
	playerHudDestroy("lms_spechud_healthtxt2");
	playerHudDestroy("lms_spechud_health2");
	playerHudDestroy("lms_spechud_weapontxt2");
	playerHudDestroy("lms_spechud_weapon2");
	playerHudDestroy("lms_spechud_ammotxt2");
	playerHudDestroy("lms_spechud_ammo2");
	playerHudDestroy("lms_spechud_back2");
}
