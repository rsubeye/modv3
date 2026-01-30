#include extreme\_ex_hudcontroller;

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = extreme\_ex_clientcontrol::menuAutoAssign;
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

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	if(!level.htf_teamscore)
	{
		switch(game["allies"])
		{
			case "american":
				game["hudicon_allies"] = "hudicon_american";
				break;
			case "british":
				game["hudicon_allies"] = "hudicon_british";
				break;
			default:
				game["hudicon_allies"] = "hudicon_russian";
				break;
		}

		game["hudicon_axis"] = "hudicon_german";
	}

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
		if(!level.htf_teamscore)
		{
			[[level.ex_PrecacheShader]](game["hudicon_allies"]);
			[[level.ex_PrecacheShader]](game["hudicon_axis"]);
		}
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
	if(level.htf_teamscore) thread maps\mp\gametypes\_hud_teamscore::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread maps\mp\gametypes\_models::init();
	extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("auto_change");

	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.teamholdtime["axis"] = 0;
	level.teamholdtime["allies"] = 0;
	level.oldteamholdtime["allies"] = level.teamholdtime["allies"];
	level.oldteamholdtime["axis"] = level.teamholdtime["axis"];
	level.hasspawned["axis"] = false;
	level.hasspawned["allies"] = false;
	level.hasspawned["flag"] = false;
	level.mapended = false;

	FindTeamSides();

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

		if(self.pers["team"] == "allies")
			self.sessionteam = "allies";
		else
			self.sessionteam = "axis";

		// Fix for spectate problem
		self maps\mp\gametypes\_spectating::setSpectatePermissions();

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

	friendly = undefined;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir)) iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else if(level.friendlyfire == "1")
			{
				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");
			}
			else if(level.friendlyfire == "2")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * level.ex_friendlyfire_reflect);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 1;
			}
			else if(level.friendlyfire == "3")
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 2;
			}
		}
		else
		{
			// Make sure at least one point of damage is done
			if(iDamage < 1) iDamage = 1;

			self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
			self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
			self playrumble("damage_heavy");
		}

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

		if(!isDefined(friendly) || friendly == 2)
			logPrint("D;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

		if(isDefined(friendly) && eAttacker.sessionstate != "dead")
		{
			lpselfguid = lpattackguid;
			lpselfnum = lpattacknum;
			lpselfname = lpattackname;
			logPrint("D;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
		}
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
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isDefined(self.switching_teams) && !self.ex_confirmkill)
	{
		self.pers["death"]++;
		self.deaths = self.pers["death"];
	}

	lpselfguid = self getGuid();
	lpselfnum = self getEntityNumber();
	lpselfteam = self.pers["team"];
	lpselfname = self.name;

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			lpattackguid = lpselfguid;
			lpattacknum = lpselfnum;
			lpattackteam = lpselfteam;
			lpattackname = lpselfname;
			doKillcam = false;

			// switching teams
			if(isDefined(self.switching_teams))
			{
				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;

					if((players[self.joining_team] - players[self.leaving_team]) > 1) self thread [[level.pscoreproc]](-1);
				}
			}

			if(isDefined(attacker.friendlydamage)) attacker iprintln(&"MP_FRIENDLY_FIRE_WILL_NOT");
		}
		else
		{
			lpattackguid = attacker getGuid();
			lpattacknum = attacker getEntityNumber();
			lpattackteam = attacker.pers["team"];
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
			if(flagcarrier) reward_points += level.PointsForKillingFlagCarrier;

			points = level.ex_points_kill + reward_points;

			if(self.pers["team"] == lpattackteam) // killed by a friendly
			{
				// Was the flagcarrier killed?
				if(flagcarrier)
				{
					attacker iprintlnbold(&"MP_HTF_YOU_TEAMKILL_FLAG_CARRIER");
					attacker thread announce(&"MP_HTF_TEAMKILL_FLAG_CARRIER");
				}

				if(level.ex_reward_teamkill) attacker thread [[level.pscoreproc]](0 - points);
					else attacker thread [[level.pscoreproc]](0 - level.ex_points_kill);
			}
			else
			{
				if(flagcarrier)
				{
					attacker iprintlnbold(&"MP_HTF_YOU_KILLED_FLAG_CARRIER");
					attacker thread announce(&"MP_HTF_KILLED_FLAG_CARRIER");
				}

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

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
	self.statusicon = "";
	self.maxhealth = level.ex_player_maxhealth;
	self.health = self.maxhealth;
	self.dead_origin = undefined;
	self.dead_angles = undefined;

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
		spawnpointname = "mp_tdm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");

		// First player of each team spawn on specific teamside
		if(!level.hasspawned[self.sessionteam])
		{
			spawnpoint = NearestSpawnpoint(spawnpoints, level.teamside[self.sessionteam]);
			level.hasspawned[self.sessionteam] = true;
		}
		else
		{
			// Else use TDM spawnlogic
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
		}

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["scorelimit"] > 0) self setClientCvar("cg_objectiveText", &"MP_HTF_OBJ_TEXT", game["scorelimit"]);
		else self setClientCvar("cg_objectiveText", &"MP_HTF_OBJ_TEXT_NOSCORE");

	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");

	if(!level.ex_readyup || (isDefined(game["readyup_done"]) && game["readyup_done"])) thread CheckForFlag();
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	if(level.ex_spectatedead)
	{
		self.sessionteam = self.pers["team"];
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
	}

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
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
	}

	levelAnnounceWinner(winningteam);

	extreme\_ex_main::exEndMap();

	game["state"] = "intermission";
	level notify("intermission");

	winners = "";
	losers = "";
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(winningteam == "allies" || winningteam == "axis")
		{
			lpselfguid = player getGuid();
			if((isDefined(player.pers["team"])) && (player.pers["team"] == winningteam))
				winners = (winners + ";" + lpselfguid + ";" + player.name);
			else if((isDefined(player.pers["team"])) && (player.pers["team"] == losingteam))
				losers = (losers + ";" + lpselfguid + ";" + player.name);
		}

		player closeMenu();
		player closeInGameMenu();
		player extreme\_ex_spawn::spawnIntermission();
		player playerHudRestoreStatusIcon();
	}

	if(winningteam == "allies" || winningteam == "axis")
	{
		logPrint("W;" + winningteam + winners + "\n");
		logPrint("L;" + losingteam + losers + "\n");
	}

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

	if(level.ex_bestof)
	{
		if(getTeamScore("allies") < level.bestoflimit && getTeamScore("axis") < level.bestoflimit) return;
	}
	else if(getTeamScore("allies") < game["scorelimit"] && getTeamScore("axis") < game["scorelimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	while(!level.ex_gameover && !game["matchpaused"])
	{
		timelimit = getCvarFloat("scr_htf_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_htf_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_htf_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

pickupFlag(flag)
{
	self endon("disconnect");

	flag notify("end_autoreturn");

	myteam = self.sessionteam;
	if(myteam == "allies") otherteam = "axis";
		else otherteam = "allies";

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	flag.flagmodel setmodel("xmodel/prop_flag_" + game[myteam]);
	self.flag = flag;
	self.dont_auto_balance = true;

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

	objective_icon(flag.objective, flag.compassflag);

	//self playsound("health_pickup_medium");
	self attachFlag();
}

dropFlag(dropspot)
{
	if(isDefined(self.flag))
	{
		if(isDefined(dropspot)) start = dropspot + (0, 0, 10);
			else start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"];
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;
		self.flag.stolen = false;

		self.flag.compassflag = level.compassflag_none;
		self.flag.objpointflag = level.objpointflag_none;

		self.flag createFlagWaypoint();

		// set compass flag position on player
		objective_icon(self.flag.objective, self.flag.compassflag);
		objective_position(self.flag.objective, self.flag.origin);

		self.flag thread autoReturn();
		self detachFlag(self.flag);

		// check if it's in a flag returner
		for(i = 0; i < level.ex_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.ex_returners[i]))
			{
				self.flag thread returnFlag(false);
				break;
			}
		}

		self.flag = undefined;
		self.dont_auto_balance = undefined;
	}
}

returnFlag(delay)
{
	self notify("end_autoreturn");
	self deleteFlagWaypoint();
	objective_delete(self.objective);

	// Do not spawn flag unless there are alive players in both teams
	while( !(alivePlayers("allies") && alivePlayers("axis")) ) wait( [[level.ex_fpstime]](1) );

	// Wait delay before spawning flag
	if(delay)
	{
		self.flagmodel hide();
		self.origin = (self.home_origin[0], self.home_origin[0], self.home_origin[2] - 5000);
		wait( [[level.ex_fpstime]](level.flagspawndelay + 0.05) );
	}

	self.origin = self.home_origin;
	self.flagmodel.origin = self.home_origin;
	self.flagmodel.angles = self.home_angles;
	self.flagmodel show();
	self.atbase = true;
	self.stolen = false;
	self.lastteam = "none";

	self.compassflag = level.compassflag_none;
	self.objpointflag = level.objpointflag_none;

	self createFlagWaypoint();

	// set compass flag position on player
	objective_add(self.objective, "current", self.origin, self.compassflag);
	objective_team(self.objective, "none");
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

	hud_index = playerHudCreate("htf_flagicon", 320, 40, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);

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

	if(level.ex_flag_drop) self thread dropFlagMonitor();
}

detachFlag(flag)
{
	self endon("disconnect");

	if(!isDefined(self.flagAttached)) return;

	if(flag.team == "allies")
	{
		levelHudScale("htf_alliesicon", 1, 0, 18, 18);
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	}
	else
	{
		levelHudScale("htf_axisicon", 1, 0, 18, 18);
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	}

	self detach(flagModel, "J_Spine4");

	playerHudRestoreStatusIcon();

	playerHudDestroy("htf_flagicon");
	self.flagAttached = undefined;
}

dropFlagMonitor()
{
	level endon("ex_gameover");
	self endon("disconnect");

	while(isAlive(self) && isDefined(self.flagAttached))
	{
		if(self useButtonPressed() && self meleeButtonPressed())
		{
			dropspot = self getDropSpot(100);
			if(isDefined(dropspot))
			{
				self dropFlag(dropspot);
				break;
			}
		}
		wait( [[level.ex_fpstime]](0.05) );
	}
}

getDropSpot(radius)
{
	origin = self.origin + (0, 0, 20);
	dropspot = undefined;

	// scan 360 degrees in 20 degree increments for good spot to drop flag
	for(i = 0; i < 360; i += 20)
	{
		// locate candidate spot in circle
		spot0 = origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), radius);
		trace = bulletTrace(origin, spot0, false, undefined);
		spot1 = trace["position"];
		dist1 = int(distance(origin, spot1) + 0.5);
		if(dist1 != radius) continue;

		// check if this spot is in minefield (unfortunately needs entity to check)
		badspot = false;
		model1 = spawn("script_model", spot1);
		model1 setmodel("xmodel/tag_origin");
		for(j = 0; j < level.ex_returners.size; j++)
		{
			if(model1 istouching(level.ex_returners[j]))
			{
				badspot = true;
				break;
			}
		}
		model1 delete();
		if(badspot) continue;

		// find ground level
		trace = bulletTrace(spot1, spot1 + (0, 0, -2000), false, undefined);
		spot2 = trace["position"];
		dist2 = int(distance(spot1, spot2) + 0.5);

		// make sure path is clear 50 units up
		trace = bulletTrace(spot2, spot2 + (0, 0, 50), false, undefined);
		spot3 = trace["position"];
		dist3 = int(distance(spot2, spot3) + 0.5);
		if(dist3 != 50) continue;

		dropspot = spot2;
		break;
	}

	return dropspot;
}

createFlagWaypoint()
{
	if(!level.ex_objindicator) return;

	self deleteFlagWaypoint();

	hud_index = levelHudCreate("waypoint_flag", undefined, self.origin[0], self.origin[1], .61, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
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

printOnTeam(text, team)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text);
	}
}

alivePlayers(team)
{
	allplayers = level.players;
	alive = [];
	for(i = 0; i < allplayers.size; i++)
	{
		if(allplayers[i].sessionstate == "playing" && allplayers[i].sessionteam == team)
			alive[alive.size] = allplayers[i];
	}
	return alive.size;
}

announce(msg)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(players[i] != self) players[i] iprintln(msg, [[level.ex_pname]](self));
	}
}

FindTeamSides()
{
	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	maxdist = 0;
	p1 = spawnpoints[0];
	p2 = spawnpoints[0];
	for(i = 0; i < spawnpoints.size; i++)
	{
		for(j = 0; j < spawnpoints.size; j++)
		{
			if(i == j) continue;
			dist = distance(spawnpoints[i].origin,spawnpoints[j].origin);
			if(dist > maxdist)
			{
				maxdist = dist;
				p1 = spawnpoints[i];
				p2 = spawnpoints[j];
			}
		}
	}

	// Save teamsides for initial spawning
	if(randomInt(2))
	{
		level.teamside["axis"] = p1.origin;
		level.teamside["allies"] = p2.origin;
	}
	else
	{
		level.teamside["axis"] = p2.origin;
		level.teamside["allies"] = p1.origin;
	}
}

InitFlag()
{
	flagpoint = GetFlagPoint();
	origin = flagpoint.origin;
	angles = flagpoint.angles;

	// Remove spawn on flag points?
	if(level.removeflagspawns) flagpoint delete();

	// Spawn a script origin
	level.flag = spawn("script_origin", origin);
	level.flag.targetname = "htf_flaghome";
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
	level.flag.flagmodel hide();
	level.flag.flagmodel.angles = level.flag.home_angles;
	level.flag.flagmodel setmodel("xmodel/prop_flag_german");

	// Set flag properties
	level.flag.team = "none";
	level.flag.lastteam = "none";
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
	// level.flags is set and populated in _mapsetup_htf.gsc, which is called from _ex_gtcommon.gsc
	if(isDefined(level.flags) && level.flags.size)
	{
		level.removeflagspawns = false;
		flagpoint = level.flags[randomInt(level.flags.size)];
	}
	else
	{
		p1 = level.teamside["axis"];
		p2 = level.teamside["allies"];

		// Find center
		x = p1[0] + (p2[0] - p1[0]) / 2;
		y = p1[1] + (p2[1] - p1[1]) / 2;
		z = p1[2] + (p2[2] - p1[2]) / 2;

		// Get nearest spawn
		spawnpointname = "mp_tdm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		flagpoint = NearestSpawnpoint(spawnpoints, (x,y,z));
	}

	return flagpoint;
}

CheckForFlag()
{
	level endon("intermission");

	// check if flag exists. It could be missing due the ready-up
	if(!isDefined(level.flag)) return;

	self.flag = undefined;
	count = 0;
	oldorigin = self.origin;

	// What is my team?
	myteam = self.sessionteam;
	if(myteam == "allies") otherteam = "axis";
		else otherteam = "allies";

	while(isAlive(self) && self.sessionstate == "playing" && myteam == self.sessionteam)
	{
		// Does the flag exist and is not currently being stolen?
		if(!level.flag.stolen)
		{
			// Am I touching it and it is not currently being stolen?
			if(self isTouchingFlag() && !level.flag.stolen)
			{
				level.flag.stolen = true;

				// Steal flag
				self pickupFlag(level.flag);

				if(level.flag.lastteam != myteam)
				{
					level.flag.lastteam = myteam;

					self iprintlnbold(&"MP_HTF_YOU_STOLE_FLAG");
					self thread announce(&"MP_HTF_STOLE_FLAG");

					friendlyAlias = "ctf_touchenemy";
					enemyAlias = "ctf_enemy_touchenemy";

					// What is my team?
					myteam = self.sessionteam;
					if(myteam == "allies") otherteam = "axis";
					else otherteam = "allies";
	
					thread [[level.ex_psop]](friendlyAlias, myteam);
					thread [[level.ex_psop]](enemyAlias, otherteam);

					if(level.mode == 2) level.teamholdtime[otherteam] = 0;

					lpselfnum = self getEntityNumber();
					lpselfguid = self getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + "htf_stole" + "\n");

					// Get personal score
					self thread [[level.pscoreproc]](level.PointsForStealingFlag);
				}
				else
				{
					self iprintlnbold(&"MP_HTF_YOU_PICKED_FLAG");
					self thread announce(&"MP_HTF_PICKED_FLAG");

					friendlyAlias = "ctf_touchenemy";
					enemyAlias = "ctf_enemy_touchenemy";

					// What is my team?
					myteam = self.sessionteam;
					if(myteam == "allies") otherteam = "axis";
					else otherteam = "allies";
	
					thread [[level.ex_psop]](friendlyAlias, myteam);
					thread [[level.ex_psop]](enemyAlias, otherteam);
				}

				if(myteam == "axis") levelHudScale("htf_axisicon", 1, 0, 22, 22);
				else levelHudScale("htf_alliesicon", 1, 0, 22, 22);

				count = 0;
			}
		}

		// Update objective on compass
		if(isDefined(self.flag))
		{
			// Update the objective for my team
			objective_position(self.flag.objective, self.origin);		

			wait( [[level.ex_fpstime]](0.05) );

			// Increase teamscore every second
			count++;
			if(count >= 20 && isDefined(self.flag))
			{
				count = 0;
			
				if(level.mode == 1 && level.teamholdtime[otherteam]) level.teamholdtime[otherteam]--;
				else level.teamholdtime[myteam]++;

				if(level.teamholdtime[myteam] >= level.flagholdtime)
				{
					myteamstring = "";
					
					if(myteam == "allies")
					{
						switch(game["allies"])
						{
							case "american":
							myteamstring = &"MP_HTF_AMERICAN_TEAM";
							break;
							
							case "british":
							myteamstring = &"MP_HTF_BRITISH_TEAM";
							break;

							case "russian":
							myteamstring = &"MP_HTF_RUSSIAN_TEAM";
							break;
						}
					}
					else myteamstring = &"MP_HTF_GERMAN_TEAM";
					
					iprintlnbold(&"MP_HTF_SCORED_A", myteamstring, &"MP_HTF_SCORED_B", level.flagholdtime, &"MP_HTF_SCORED_C");

					friendlyAlias = "ctf_touchcapture";
					enemyAlias = "ctf_enemy_touchcapture";
	
					// What is my team?
					myteam = self.sessionteam;
					if(myteam == "allies") otherteam = "axis";
					else otherteam = "allies";
	
					thread [[level.ex_psop]](friendlyAlias, myteam);
					thread [[level.ex_psop]](enemyAlias, otherteam);

					level.teamholdtime[myteam] = 0;
					if(level.mode == 3) level.teamholdtime[otherteam] = 0;

					self detachFlag(self.flag);

					// Return flag
					self.flag thread ReturnFlag(true);

					// Clear flags
					self.flag = undefined;

					lpselfnum = self getEntityNumber();
					lpselfguid = self getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + myteam + ";" + self.name + ";" + "htf_scored" + "\n");

					// Get personal score
					self.pers["flagcap"]++;
					self thread [[level.pscoreproc]](5);

					if(level.ex_statshud) self thread extreme\_ex_statshud::showStatsHUD();

					// Give all other team members 1 point
					players = level.players;
					for(i = 0; i < players.size; i++)
					{
						player = players[i];
						if(!isDefined(player.pers["team"]) || player.pers["team"] != myteam || player == self) continue;
						player thread [[level.pscoreproc]](1);
					}

					// Get team score
					if(myteam == "axis") levelHudSetValue("htf_axisscore", getTeamScore("axis")+1);
						else levelHudSetValue("htf_alliesscore", getTeamScore("allies")+1);
					thread [[level.tscoreproc]](myteam, 1);
				}

				UpdateHud();
			}
		}
		else wait( [[level.ex_fpstime]](0.2) );
	}

	// player died or went spectator
	self dropFlag();
}

isTouchingFlag()
{
	// do not allow player in stealth mode to pick up flag
	if(level.ex_stealth && isDefined(self.ex_stealth)) return false;

	if(distance(self.origin, level.flag.origin) < 50)
		return true;
	else
		return false;
}

SetupHud()
{
	y = 10;
	barsize = 200;

	hud_index = levelHudCreate("htf_backdrop", undefined, 320, y, 0.3, (0.2,0.2,0.2), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", barsize*2+4, 13);

	hud_index = levelHudCreate("htf_alliesicon", undefined, 320 - barsize - 3, y, 1, (1,1,1), 1, 1, "fullscreen", "fullscreen", "right", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, game["hudicon_allies"], 18, 18);

	hud_index = levelHudCreate("htf_alliesscore", undefined, 320 - barsize - 25, y, 1, (1,1,0), 1.6, 1, "fullscreen", "fullscreen", "right", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, getTeamScore("allies"));

	hud_index = levelHudCreate("htf_axisicon", undefined, 320 + barsize + 3, y, 1, (1,1,1), 1, 1, "fullscreen", "fullscreen", "left", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, game["hudicon_axis"], 18, 18);

	hud_index = levelHudCreate("htf_axisscore", undefined, 320 + barsize + 25, y, 1, (1,1,0), 1.6, 1, "fullscreen", "fullscreen", "left", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, getTeamScore("axis"));

	hud_index = levelHudCreate("htf_alliesprogress", undefined, 320, y, 0.5, (1,0,0), 1, 2, "fullscreen", "fullscreen", "right", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 1, 11);

	hud_index = levelHudCreate("htf_axisprogress", undefined, 320, y, 0.5, (0,0,1), 1, 2, "fullscreen", "fullscreen", "left", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 1, 11);
}

UpdateHud()
{
	barsize = 200;
	axis = int(level.teamholdtime["axis"] * barsize / (level.flagholdtime - 1) + 1);
	allies = int(level.teamholdtime["allies"] * barsize / (level.flagholdtime - 1) + 1);

	if(level.teamholdtime["allies"] != level.oldteamholdtime["allies"]) levelHudScale("htf_alliesprogress", 1, 0, allies, 11);
	if(level.teamholdtime["axis"] != level.oldteamholdtime["axis"]) levelHudScale("htf_axisprogress", 1, 0, axis, 11);

	level.oldteamholdtime["allies"] = level.teamholdtime["allies"];
	level.oldteamholdtime["axis"] = level.teamholdtime["axis"];
}

// Returns the spawn point closest to the passed in position.
NearestSpawnpoint(aeSpawnpoints, vPosition)
{
	eNearestSpot = aeSpawnpoints[0];
	fNearestDist = distance(vPosition, aeSpawnpoints[0].origin);
	for(i = 1; i < aeSpawnpoints.size; i++)
	{
		fDist = distance(vPosition, aeSpawnpoints[i].origin);
		if(fDist < fNearestDist)
		{
			eNearestSpot = aeSpawnpoints[i];
			fNearestDist = fDist;
		}
	}
	
	return eNearestSpot;
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
