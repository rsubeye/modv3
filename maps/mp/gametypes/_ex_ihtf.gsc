#include extreme\_ex_hudcontroller;

/*------------------------------------------------------------------------------
Individual Hold the Flag - eXtreme+ mod compatible version 1.2
Author : La Truffe
Based on HTF (Hold the Flag)
Credits : Bell (HTF), Ravir (cvardef function), Astoroth (eXtreme+ mod)
------------------------------------------------------------------------------*/

main()
{
	// Trick SET: pretend we're on HQ gametype to benefit from the level.radio definitions in the map script
	setcvar("g_gametype", "hq");

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
	level.respawnplayer = ::respawn;
	level.updatetimer = ::updatetimer;
	level.endgameconfirmed = ::endMap;
	level.checkscorelimit = ::checkScoreLimit;

	// Over-override Callback_StartGameType
	level.ihtf_callbackStartGameType = level.callbackStartGameType;
	level.callbackStartGameType = ::IHTF_Callback_StartGameType;

	// set eXtreme+ variables and precache (phase 1 only)
	extreme\_ex_varcache::main(1);
}

IHTF_Callback_StartGameType()
{
	// Trick UNSET: restore IHTF gametype
	setcvar("g_gametype", "ihtf");

	// set eXtreme+ variables and precache (phase 2 only)
	extreme\_ex_varcache::main(2);

	// disable tripwires (Pat: in here since day one. I wonder why)
	level.ex_tweapons = 0;
	
	[[level.ihtf_callbackStartGameType]]();
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.compassflag_none	= "objective";
	level.objpointflag_allies = "objpoint_flag_" + game["allies"];
	level.objpointflag_axis = "objpoint_flag_" + game["axis"];
	level.objpointflag_none = "objpoint_star";
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];
	
	if(!isDefined(game["precachedone"]))
	{
		[[level.ex_PrecacheRumble]]("damage_heavy");
		if(!level.ex_rank_statusicons && !level.ex_classes_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("hud_status_dead");
			[[level.ex_PrecacheStatusIcon]]("hud_status_connecting");
		}
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]](level.hudflag_allies);
			[[level.ex_PrecacheStatusIcon]](level.hudflag_axis);
		}
		[[level.ex_PrecacheShader]](level.compassflag_allies);
		[[level.ex_PrecacheShader]](level.compassflag_axis);
		[[level.ex_PrecacheShader]](level.compassflag_none);
		[[level.ex_PrecacheShader]](level.objpointflag_allies);
		[[level.ex_PrecacheShader]](level.objpointflag_axis);
		[[level.ex_PrecacheShader]](level.objpointflag_none);
		[[level.ex_PrecacheShader]](level.hudflag_allies);
		[[level.ex_PrecacheShader]](level.hudflag_axis);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["allies"]);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["axis"]);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["allies"] + "_carry");
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["axis"] + "_carry");
		[[level.ex_PrecacheString]](&"MP_TIME_TILL_SPAWN");
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");
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
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread maps\mp\gametypes\_models::init();
	extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	SaveSDBombzonesPos();
	SaveCTFFlagsPos();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.playerspawnpoints = SpawnPointsArray(level.playerspawnpointsmode, "ihtf_player_spawn");
	level.flagspawnpoints = SpawnPointsArray(level.flagspawnpointsmode, "ihtf_flag_spawn");

	if(!level.playerspawnpoints.size)
	{
		maps\mp\_utility::error("NO PLAYER SPAWNPOINTS IN MAP");
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	if(!level.flagspawnpoints.size)
	{
		maps\mp\_utility::error("NO FLAG SPAWNPOINTS IN MAP");
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	//logprint(level.playerspawnpoints.size + " player spawn points\n");
	//logprint(level.flagspawnpoints.size + " flag positions\n");

	RemoveHQRadioPoints();

	level.holdtime = 0;
	level.totalholdtime = 0;
	level.holdtime_old = level.holdtime;
	level.totalholdtime_old = level.totalholdtime;
	level.startflagtime = 0;

	level.QuickMessageToAll = true;
	level.mapended = false; 
	level.hasspawned["flag"] = false;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread InitFlag();
		thread startGame();
		thread updateGametypeCvars();
	}

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
	self dropFlag();

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable) return;
	if(game["matchpaused"]) return;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir)) iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		// Make sure at least one point of damage is done
		if(iDamage < 1) iDamage = 1;

		self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
		self playrumble("damage_heavy");

		if(isDefined(eAttacker) && eAttacker != self) eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback();
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

	self.ex_confirmkill = extreme\_ex_killconfirmed::kcCheck(attacker, sMeansOfDeath, sWeapon);

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	flagcarrier = false;
	if(isDefined(self.flag))
	{
		flagcarrier = true;
		self dropFlag();
	}

	self.sessionstate = "dead";
	playerHudSetStatusIcon("hud_status_dead");

	if(!isDefined(self.switching_teams) && !self.ex_confirmkill)
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
			if(!isDefined(self.switching_teams)) self thread [[level.pscoreproc]](-1);
		}
		else
		{
			lpattackguid = attacker getGuid();
			lpattacknum = attacker getEntityNumber();
			lpattackname = attacker.name;
			doKillcam = true;

			// Check if reward points should be given for bash or headshot
			reward_points = 0;
			if(isDefined(sMeansOfDeath))
			{
				if(sMeansOfDeath == "MOD_MELEE") reward_points = level.ex_reward_melee;
					else if(sMeansOfDeath == "MOD_HEAD_SHOT") reward_points = level.ex_reward_headshot;
			}

			// Check if extra points should be given for GT specific achievement
			if(flagcarrier)
			{
				attacker AnnounceSelf(&"MP_IHTF_YOU_KILLED_FLAG_CARRIER", undefined);
				attacker AnnounceOthers(&"MP_IHTF_KILLED_FLAG_CARRIER", attacker);
				reward_points += level.PointsForKillingFlagCarrier;
			}

			points = level.ex_points_kill + reward_points;

			if(self.ex_confirmkill)
			{
				if(level.ex_kc_pdistr == 1)
				{
					kc_points = level.ex_points_kill;
					kc_reward = 0;
					points = reward_points;
				}
				else if(level.ex_kc_pdistr == 2)
				{
					kc_points = 0;
					kc_reward = reward_points;
					points = level.ex_points_kill;
					reward_points = 0;
				}
				else if(level.ex_kc_pdistr == 3)
				{
					kc_points = 0;
					kc_reward = level.ex_kc_confirmed_bonus;
				}
				else
				{
					kc_points = level.ex_points_kill;
					kc_reward = reward_points;
					points = 0;
					reward_points = 0;
				}

				self thread extreme\_ex_killconfirmed::kcMain(kc_points, kc_reward, false, attacker);
			}

			attacker thread [[level.pscoreproc]](points, "bonus", reward_points);
		}
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		lpattackguid = "";
		lpattacknum = -1;
		lpattackteam = "world";
		lpattackname = "";
		doKillcam = false;

		self thread [[level.pscoreproc]](-1);
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
	thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 2; // Delay the player becoming a spectator till after he's done dying
	if(level.respawndelay) self thread respawn_timer(delay);
	wait( [[level.ex_fpstime]](delay) ); // Also required for Callback_PlayerKilled to complete before killcam can execute

	if(doKillcam && level.killcam)
		self maps\mp\gametypes\_killcam::killcam(lpattacknum, delay, psOffsetTime, level.respawndelay);

	self thread respawn();
}

spawnPlayer()
{
	self endon("disconnect");
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
		spawnpoints = level.playerspawnpoints;

		// Find a spawn point away from the flag
		spawnpoint = undefined;
		for(i = 0; i < 5; i ++)
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
			if(spawnpoint isAwayFromFlag()) break;
		}

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO VALID SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["scorelimit"] > 0) self setClientCvar("cg_objectiveText", &"MP_IHTF_OBJ_TEXT", game["scorelimit"]);
		else self setClientCvar("cg_objectiveText", &"MP_IHTF_OBJ_TEXT_NOSCORE");

	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");

	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
		thread CheckForFlag();
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	if(!isDefined(updtimer)) updtimer = false;
	if(updtimer) self thread updateTimer();

	while(isDefined(self.WaitingToSpawn)) wait( [[level.ex_fpstime]](0.05) );

	if(!level.forcerespawn)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}

	self thread spawnPlayer();
}

startGame()
{
	if(game["timelimit"] > 0) extreme\_ex_gtcommon::createClock(game["timelimit"] * 60);

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
	flagtimepassed = (getTime () - level.startflagtime) / 1000;
	if((level.flag.atbase || (!level.flag.stolen)) && (flagtimepassed >= level.flagtimeout))
	{
		iprintln(&"MP_IHTF_FLAG_TIMEOUT", level.flagtimeout);

		// Hide the flag
		level.flag.basemodel hide();
		level.flag.flagmodel hide();
		level.flag.compassflag = level.compassflag_none;
		level.flag.objpointflag = level.objpointflag_none;

		// Prevent players from stealing it until it respawns
		level.flag.stolen = true;

		// Respawn the flag		
		level.flag returnFlag(false);
	}

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
		timelimit = getCvarFloat("scr_ihtf_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ihtf_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_ihtf_scorelimit");
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

pickupFlag(flag)
{
	self endon("disconnect");

	flag notify("end_autoreturn");

	myteam = self.pers["team"];
	if(myteam == "allies") otherteam = "axis";
		else otherteam = "allies";

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	flag.flagmodel setmodel("xmodel/prop_flag_" + game[myteam]);
	self.flag = flag;

	flag.team = myteam;
	flag.atbase = false;

	if(myteam == "allies")
	{
		flag.compassflag = level.compassflag_allies;
		flag.objpointflag = level.objpointflag_allies;
	}
	else
	{
		flag.compassflag = level.compassflag_axis;
		flag.objpointflag = level.objpointflag_axis;
	}

	flag deleteFlagWaypoint();

	objective_icon(self.flag.objective, flag.compassflag);
	objective_team(self.flag.objective, "none");

	self playsound("ctf_touchenemy");
	self attachFlag();
}

dropFlag(dropspot)
{
	if(isDefined(self.flag))
	{
		level.holdtime = 0;
		level.totalholdtime = 0;

		UpdateHud();

		if(isDefined(dropspot)) start = dropspot + (0, 0, 10);
			else start = self.origin + (0, 0, 10);

		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"];
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;
		self.flag.stolen = false;

		// set compass flag position on player
		objective_position(self.flag.objective, self.flag.origin);
		objective_state(self.flag.objective, "current");

		self.flag createFlagWaypoint();

		self.flag thread autoReturn();
		self detachFlag(self.flag);

		// check if it's in a flag returner
		for(i = 0; i < level.ex_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.ex_returners[i]))
			{
				self.flag.compassflag = level.compassflag_none;
				self.flag.objpointflag = level.objpointflag_none;
				self.flag thread returnFlag(false);
				break;
			}
		}

		self.flag = undefined;
		
		level.startflagtime = getTime();
	}
}

returnFlag(delay)
{
	self notify("end_autoreturn");
	self deleteFlagWaypoint();
	objective_delete(self.objective);

	// Wait delay before spawning flag
	if(delay)
	{
		self.flagmodel hide();
		self.origin = (self.home_origin[0], self.home_origin[0], self.home_origin[2] - 5000);
		wait( [[level.ex_fpstime]](level.flagspawndelay + 0.05) );
	}

	if(!level.hasspawned["flag"])
	{
		self.origin = self.home_origin;
 		self.flagmodel.origin = self.home_origin;
	 	self.flagmodel.angles = self.home_angles;
		if(level.randomflagspawns) level.hasspawned["flag"] = true;
	}
	else
	{
		spawnpoints = level.flagspawnpoints;

		// Find a new spawn point for the flag
		spawnpoint = undefined;
		for(i = 0; i < 50; i ++)
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
			if(spawnpoint.origin != self.origin) break;
		}

		self.origin = spawnpoint.origin;
 		self.flagmodel.origin = spawnpoint.origin;
	 	self.flagmodel.angles = spawnpoint.angles;
		self.basemodel.origin = spawnpoint.origin;
	 	self.basemodel.angles = spawnpoint.angles;
	}

	self.flagmodel show();
	self.basemodel show();
	self.atbase = true;
	self.stolen = false;

	// set compass flag position on player
	objective_add(self.objective, "current", self.origin, self.compassflag);
	objective_position(self.objective, self.origin);
	objective_state(self.objective, "current");

	self createFlagWaypoint();
	
	level.holdtime = 0;
	level.totalholdtime = 0;

	UpdateHud();

	level.startflagtime = getTime();
}

autoReturn()
{
	level endon("ex_gameover");
	self endon("end_autoreturn");

	if(!level.flagrecovertime) return;

	wait( [[level.ex_fpstime]](level.flagrecovertime) );

	self thread returnFlag(false);
}

attachFlag()
{
	self endon("disconnect");

	if(isDefined(self.flagAttached)) return;

	hud_index = playerHudCreate("ihtf_flagicon", 30, 95, 1, (1,1,1), 1, 0, "left", "top", "center", "middle", false, true);

	iconSize = 40;
	if(self.pers["team"] == "allies")
	{
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
		if(hud_index != -1) playerHudSetShader(hud_index, level.hudflag_allies, iconSize, iconSize);
		playerHudSetStatusIcon(level.hudflag_allies);
	}
	else
	{
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		if(hud_index != -1) playerHudSetShader(hud_index, level.hudflag_axis, iconSize, iconSize);
		playerHudSetStatusIcon(level.hudflag_axis);
	}

	self attach(flagModel, "J_Spine4", true);
	self.flagAttached = true;
}

detachFlag(flag)
{
	self endon("disconnect");

	if(!isDefined(self.flagAttached)) return;

	if(flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";

	self detach(flagModel, "J_Spine4");

	playerHudRestoreStatusIcon();

	playerHudDestroy("ihtf_flagicon");
	self.flagAttached = undefined;
}

createFlagWaypoint()
{
	if(!level.ex_objindicator) return;

	self deleteFlagWaypoint();

	hud_index = levelHudCreate("waypoint_flag_" + self.team, undefined, self.origin[0], self.origin[1], .61, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, self.objpointflag, 7, 7);
	levelHudSetWaypoint(hud_index, self.origin[2] + 100, true);

	self.waypoint_flag = hud_index;
}

deleteFlagWaypoint()
{
	if(isDefined(self.waypoint_flag))
	{
		levelHudDestroy(self.waypoint_flag);
		self.waypoint_flag = undefined;
	}
}

AnnounceSelf(locstring, var)
{
	if(isDefined(var))
		self iprintlnbold(locstring, var);
	else
		self iprintlnbold(locstring);
}

AnnounceOthers(locstring, var)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(players[i] == self)
			continue;

		if(isDefined(var))
			players[i] iprintln(locstring, var);
		else
			players[i] iprintln(locstring);
	}
}

AnnounceAll(locstring, var)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isDefined(var))
			players[i] iprintln(locstring, var);
		else
			players[i] iprintln(locstring);
	}
}

InitFlag()
{
	flagpoint = GetFlagPoint();
	origin = flagpoint.origin;
	angles = flagpoint.angles;

	// Spawn a script origin
	level.flag = spawn("script_origin",origin);
	level.flag.targetname = "ihtf_flaghome";
	level.flag.origin = origin;
	level.flag.angles = angles;
	level.flag.home_origin = origin;
	level.flag.home_angles = angles;

	// Spawn the flag base model
	level.flag.basemodel = spawn("script_model", level.flag.home_origin);
	level.flag.basemodel.angles = level.flag.home_angles;
	level.flag.basemodel setmodel("xmodel/prop_flag_base");
	
	// Spawn the flag
	level.flag.flagmodel = spawn("script_model", level.flag.home_origin);
	level.flag.flagmodel.angles = level.flag.home_angles;
	level.flag.flagmodel setmodel("xmodel/prop_flag_german");
	level.flag.flagmodel hide();

	// Set flag properties
	level.flag.team = "none";
	level.flag.atbase = false;
	level.flag.stolen = true;
	level.flag.objective = 0;
	level.flag.compassflag = level.compassflag_none;
	level.flag.objpointflag = level.objpointflag_none;

	if(level.ex_flagbase_anim_neutral) level.flag thread flagbaseAnimation("neutral", level.flag.home_origin);

	SetupHud();

	level.flag returnFlag(true);
}

flagbaseAnimation(team, origin)
{
	if(isDefined(self.fxlooper)) self.fxlooper delete();
	self.fxlooper = playLoopedFx(game["flagbase_anim_" + team], 1.6, origin + (0,0,level.ex_flagbase_anim_height), 0, vectorNormalize((origin + (0,0,100)) - origin));
}

GetFlagPoint()
{
	// Get nearest spawn

	spawnpoints = level.flagspawnpoints;
	flagpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	return flagpoint;
}

CheckForFlag()
{
	level endon("intermission");

	// check if flag exists. It could be missing due the ready-up
	if(!isDefined(level.flag)) return;

	self.flag = undefined;
	count = 0;

	// What is my team?
	myteam = self.pers["team"];
	if(myteam == "allies") otherteam = "axis";
		else otherteam = "allies";
	
	while(isAlive(self) && self.sessionstate=="playing" && myteam == self.pers["team"])
	{
		// Does the flag exist and is not currently being stolen?
		if(isDefined(level.flag) && !level.flag.stolen)
		{
			// Am I touching it and it is not currently being stolen?
			if(self isTouchingFlag() && !level.flag.stolen)
			{
				count = 0;
				level.flag.stolen = true;
		
				// Steal flag
				self pickupFlag(level.flag);
				
				self AnnounceSelf(&"MP_IHTF_YOU_STOLE_FLAG", undefined);
				self AnnounceOthers(&"MP_IHTF_STOLE_FLAG", self);

				lpselfnum = self getEntityNumber();
				lpselfguid = self getGuid();
				logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_stole" + "\n");

				// Get personal score
				self thread [[level.pscoreproc]](level.PointsForStealingFlag);
			}
		}

		// Update objective on compass
		if(isDefined(self.flag))
		{
			// Update the objective
			objective_position(self.flag.objective, self.origin);

			wait( [[level.ex_fpstime]](0.05) );

			// Make sure flag still exist
			if(isDefined(self.flag))
			{
				// Check hold time every second
				count++;
				if(count >= 20)
				{
					count = 0;
				
					level.holdtime ++;
					level.totalholdtime ++;
					
					if(level.totalholdtime >= level.flagmaxholdtime)
					{
						AnnounceAll(&"MP_IHTF_FLAG_MAXTIME", level.flagmaxholdtime);

						level.holdtime = 0;
						level.totalholdtime = 0;

						lpselfnum = self getEntityNumber();
						lpselfguid = self getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_maxheld" + "\n");
						
						self detachFlag(self.flag);
						self.flag.compassflag = level.compassflag_none;
						self.flag.objpointflag = level.objpointflag_none;

						self.flag thread ReturnFlag(true);
						self.flag = undefined;	
					}

					if(level.holdtime >= level.flagholdtime)
					{
						iprintln(&"MP_IHTF_FLAG_CARRIER_SCORES", level.PointsForHoldingFlag);

						self.pers["flagcap"]++;
						if(level.ex_statshud) self thread extreme\_ex_statshud::showStatsHUD();

						level.holdtime = 0;

						lpselfnum = self getEntityNumber();
						lpselfguid = self getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.name + ";" + "ihtf_scored" + "\n");

						self thread [[level.pscoreproc]](level.PointsForHoldingFlag);
					}

					UpdateHud();
				}
			}
		}
		else wait( [[level.ex_fpstime]](0.2) );
	}

	//player died or went spectator
	self dropFlag();
}

isTouchingFlag()
{
	if(!isDefined(level.flag)) return true;

	// do not allow player in stealth mode to pick up flag
	if(level.ex_stealth && isDefined(self.ex_stealth)) return false;

	if(distance(self.origin, level.flag.origin) < 50)
		return true;
	else
		return false;
}

isAwayFromFlag()
{
	if(!isDefined(level.flag)) return true;

	if(distance(self.origin, level.flag.origin) >= level.spawndistance) return true;
		else return false;
}

SetupHud()
{
	y = 10;
	barsize = 200;

	hud_index = levelHudCreate("ihtf_cursorleft", undefined, 320, y, 0.5, (1,0,0), 1, 2, "fullscreen", "fullscreen", "right", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 1, 11);

	hud_index = levelHudCreate("ihtf_backdrop", undefined, 320, y, 0.3, (0.2,0.2,0.2), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", barsize*2+4, 13);

	hud_index = levelHudCreate("ihtf_cursorright", undefined, 320, y, 0.5, (0,0,1), 1, 2, "fullscreen", "fullscreen", "left", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 1, 11);
}

UpdateHud()
{
	barsize = 200;
	left = int(level.holdtime * barsize / (level.flagholdtime - 1) + 1);
	right = int(level.totalholdtime * barsize / (level.flagmaxholdtime - 1) + 1);

	if(level.holdtime != level.holdtime_old) levelHudScale("ihtf_cursorleft", 1, 0, left, 11);
	if(level.totalholdtime != level.totalholdtime_old) levelHudScale("ihtf_cursorright", 1, 0, right, 11);
		
	level.holdtime_old = level.holdtime;
	level.totalholdtime_old = level.totalholdtime;
}

AddToSpawnArray(array, spawntype, customclassname)
{
	spawnpoints = getentarray(spawntype, "classname");
	for(i = 0; i < spawnpoints.size; i ++)
	{
		s = array.size;
		origin = FixSpawnPoint(spawnpoints[i].origin);
		array[s] = spawn("script_origin", origin);
		array[s].origin = origin;
		array[s].angles = spawnpoints[i].angles;
		array[s].targetname = customclassname;
		array[s] placeSpawnpoint();
	}
	
	return (array);
}

AddToSpawnArrayCTFFlags(array, customclassname)
{
	if((!isDefined(level.ctfflagspos[0])) || (!isDefined(level.ctfflagspos[1])))
		return (array);
		
	s = array.size;
	origin = FixSpawnPoint(level.ctfflagspos[0].origin);
	array[s] = spawn("script_origin", origin);
	array[s].origin = origin;
	array[s].angles = level.ctfflagspos[0].angles;
	array[s].targetname = customclassname;
	array[s] placeSpawnpoint();
	
	origin = FixSpawnPoint(level.ctfflagspos[1].origin);
	array[s + 1] = spawn("script_origin", origin);
	array[s + 1].origin = origin;
	array[s + 1].angles = level.ctfflagspos[1].angles;
	array[s + 1].targetname = customclassname;
	array[s + 1] placeSpawnpoint();

	return (array);
}

SaveCTFFlagsPos()
{
	allied_flags = getentarray("allied_flag", "targetname");
	axis_flags = getentarray("axis_flag", "targetname");
	
	if((allied_flags.size != 1) || (axis_flags.size != 1))
		return;

	allied_flag = getent("allied_flag", "targetname");
	axis_flag = getent("axis_flag", "targetname");
	
	level.ctfflagspos[0] = spawnstruct();
	level.ctfflagspos[0].origin = allied_flag.origin;
	level.ctfflagspos[0].angles = allied_flag.angles;
	level.ctfflagspos[1] = spawnstruct();
	level.ctfflagspos[1].origin = axis_flag.origin;
	level.ctfflagspos[1].angles = axis_flag.angles;
}

AddToSpawnArraySDbombzones(array, customclassname)
{
	if((!isDefined(level.sdbombzonepos[0])) || (!isDefined(level.sdbombzonepos[1])))
		return (array);

	s = array.size;
	for(i = 0; i <= 1; i ++)
	{
		origin = FixSpawnPoint(level.sdbombzonepos[i].origin);
		array[s + i] = spawn("script_origin", origin);
		array[s + i].origin = origin;
		array[s + i].angles = level.sdbombzonepos[i].angles;
		array[s + i].targetname = customclassname;
		array[s + i] placeSpawnpoint();
	}

	return (array);
}

SaveSDBombzonesPos()
{
	bombzones = getentarray("bombzone", "targetname");
	if(isDefined(bombzones[0]))
	{
		level.sdbombzonepos[0] = spawnstruct();
		level.sdbombzonepos[0].origin = bombzones[0].origin;
		level.sdbombzonepos[0].angles = bombzones[0].angles;
	}
	if(isDefined(bombzones[1]))
	{
		level.sdbombzonepos[1] = spawnstruct();
		level.sdbombzonepos[1].origin = bombzones[1].origin;
		level.sdbombzonepos[1].angles = bombzones[1].angles;
	}
}

AddToSpawnArrayHQRadios(array, customclassname)
{
	if(!isDefined(level.radio))
		return (array);

	for(i = 0; i < level.radio.size; i ++)
	{
		s = array.size;
		origin = FixSpawnPoint(level.radio[i].origin);
		array[s] = spawn("script_origin", origin);
		array[s].origin = origin;
		array[s].angles = level.radio[i].angles;
		array[s].targetname = customclassname;
		array[s] placeSpawnpoint();
	}
	
	return (array);
}

RemoveHQRadioPoints()
{
	if(!isDefined(level.radio))
		return;

	for(i = 0; i < level.radio.size; i ++)
		level.radio[i] delete();

	level.radio = undefined;
}

SpawnPointsArray(modestring, customclassname)
{
	modearray = strtok(modestring, " ");
	activespawntype = [];
	for(i = 0; i < modearray.size; i ++)
	{
		switch(modearray[i])
		{
			case "dm" :
			case "tdm" :
			case "ctfp" :
			case "ctff" :
			case "sdp" :
			case "sdb" :
			case "hq" :
				activespawntype[modearray[i]] = true;
				break;
			default :
				break;
		}
	}

	array = [];

	if(isDefined(activespawntype["dm"]))
		array = AddToSpawnArray(array, "mp_dm_spawn", customclassname);

	if(isDefined(activespawntype["tdm"]))
		array = AddToSpawnArray(array, "mp_tdm_spawn", customclassname);
	
	if(isDefined(activespawntype["ctfp"]))
	{
		array = AddToSpawnArray(array, "mp_ctf_spawn_allied", customclassname);
		array = AddToSpawnArray(array, "mp_ctf_spawn_axis", customclassname);
	}
	
	if(isDefined(activespawntype["sdp"]))
	{
		array = AddToSpawnArray(array, "mp_sd_spawn_attacker", customclassname);
		array = AddToSpawnArray(array, "mp_sd_spawn_defender", customclassname);
	}
	
	if(isDefined(activespawntype["ctff"]))
		array = AddToSpawnArrayCTFFlags(array, customclassname);
	
	if(isDefined(activespawntype["sdb"]))
		array = AddToSpawnArraySDBombzones(array, customclassname);
	
	if(isDefined(activespawntype["hq"]))
		array = AddToSpawnArrayHQRadios(array, customclassname);

	return (array);
}

FixSpawnPoint(position)
{
	return (physicstrace(position + (0, 0, 20), position + (0, 0, -20)));
}

respawn_timer(delay)
{
	self endon("disconnect");

	self.WaitingToSpawn = true;

	respawndelay = level.respawndelay;
	if(level.ex_respawndelay_subzero && self.pers["score"] < 0) respawndelay += level.ex_respawndelay_subzero;
	if(level.ex_respawndelay_class && isDefined(self.pers["weapon"]))
	{
		weapon = self.pers["weapon"];
		weapon_hit = 0;
		if(level.ex_respawndelay_sniper && extreme\_ex_weapons::isWeaponType(weapon, "sniper")) weapon_hit = level.ex_respawndelay_sniper;
		else if(level.ex_respawndelay_rifle && extreme\_ex_weapons::isWeaponType(weapon, "rifle")) weapon_hit = level.ex_respawndelay_rifle;
		else if(level.ex_respawndelay_mg && extreme\_ex_weapons::isWeaponType(weapon, "mg")) weapon_hit = level.ex_respawndelay_mg;
		else if(level.ex_respawndelay_smg && extreme\_ex_weapons::isWeaponType(weapon, "smg")) weapon_hit = level.ex_respawndelay_smg;
		else if(level.ex_respawndelay_shot && extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) weapon_hit = level.ex_respawndelay_shot;
		else if(level.ex_respawndelay_rl && extreme\_ex_weapons::isWeaponType(weapon, "rl")) weapon_hit = level.ex_respawndelay_rl;

		if(!weapon_hit && level.ex_respawndelay_class == 2 && level.ex_wepo_secondary && isDefined(self.pers["weapon2"]))
		{
			weapon = self.pers["weapon2"];
			if(level.ex_respawndelay_sniper && extreme\_ex_weapons::isWeaponType(weapon, "sniper")) weapon_hit = level.ex_respawndelay_sniper;
			else if(level.ex_respawndelay_rifle && extreme\_ex_weapons::isWeaponType(weapon, "rifle")) weapon_hit = level.ex_respawndelay_rifle;
			else if(level.ex_respawndelay_mg && extreme\_ex_weapons::isWeaponType(weapon, "mg")) weapon_hit = level.ex_respawndelay_mg;
			else if(level.ex_respawndelay_smg && extreme\_ex_weapons::isWeaponType(weapon, "smg")) weapon_hit = level.ex_respawndelay_smg;
			else if(level.ex_respawndelay_shot && extreme\_ex_weapons::isWeaponType(weapon, "shotgun")) weapon_hit = level.ex_respawndelay_shot;
			else if(level.ex_respawndelay_rl && extreme\_ex_weapons::isWeaponType(weapon, "rl")) weapon_hit = level.ex_respawndelay_rl;
		}

		if(weapon_hit) respawndelay += weapon_hit;
	}

	hud_index = playerHudCreate("respawn_timer", 0, -50, 0, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		playerHudSetKeepOnKill(hud_index, true);
		playerHudSetLabel(hud_index, &"MP_TIME_TILL_SPAWN");
		playerHudSetTimer(hud_index, respawndelay + delay);
	}

	wait( [[level.ex_fpstime]](delay) );
	self thread updateTimer();

	wait( [[level.ex_fpstime]](respawndelay) );

	playerHudDestroy("respawn_timer");

	self.WaitingToSpawn = undefined;
}

updateTimer()
{
	if(isDefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isDefined(self.pers["weapon"]))
		playerHudSetAlpha("respawn_timer", 1);
	else
		playerHudSetAlpha("respawn_timer", 0);
}

waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("respawn");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	hud_index = playerHudCreate("respawn_text", 0, -50, 1, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetLabel(hud_index, &"PLATFORM_PRESS_TO_SPAWN");

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(self useButtonPressed() != true) wait( [[level.ex_fpstime]](0.05) );

	self notify("remove_respawntext");
	self notify("respawn");
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	playerHudDestroy("respawn_text");
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}
