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
		// just to get sound working at start round?
		if(!isDefined(game["attackers"])) game["attackers"] = "allies";
		if(!isDefined(game["defenders"])) game["defenders"] = "axis";

		[[level.ex_PrecacheRumble]]("damage_heavy");
		if(!level.ex_rank_statusicons && !level.ex_classes_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("hud_status_dead");
			[[level.ex_PrecacheStatusIcon]]("hud_status_connecting");
		}
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("lib_statusicon");
		}
		[[level.ex_precacheShader]]("hud_status_alive");
		[[level.ex_precacheShader]]("hud_status_jail");
		[[level.ex_PrecacheShader]]("objective");
		[[level.ex_PrecacheString]](&"MP_TIME_TILL_SPAWN");
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");
		[[level.ex_PrecacheString]](&"MP_SLASH");
	}

	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_scoreboard::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_hud_teamscore::init();
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

	spawnpointname = "mp_lib_spawn_alliesnonjail";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_lib_spawn_axisnonjail";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	spawnpointname = "mp_lib_spawn_alliesinjail";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_lib_spawn_axisinjail";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	allowed[0] = "lib";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;
	level.roundended = false;
	level.spawn_in_jail = false;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["timepassed"])) game["timepassed"] = 0;
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread lib_jails();
		thread Jail_Init();
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
	self.killed_once = false;

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
	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable || self.in_jail) return;
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

	self.in_jail = true;
	self.status = "injail";
	self.killed_once = true;

	self.ex_confirmkill = extreme\_ex_killconfirmed::kcCheck(attacker, sMeansOfDeath, sWeapon);

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

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

			points = level.ex_points_kill + reward_points;

			if(self.pers["team"] == lpattackteam) // killed by a friendly
			{
				if(level.ex_reward_teamkill) attacker thread [[level.pscoreproc]](0 - points);
					else attacker thread [[level.pscoreproc]](0 - level.ex_points_kill);
			}
			else
			{
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

	team_dead = self getTeamStatus();

	if(team_dead) // If the last player on a team was just killed, don't do killcam
	{
		self.skip_setspectatepermissions = true;
		wait( [[level.ex_fpstime]](2) );
		self thread spawnPlayer();
		return;
	}

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

	// Set jail status before setting sessionstate
	self.in_jail = false;
	self.status = "free";

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
	if(level.ex_insertion && !self.killed_once)
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
		if(level.spawn_in_jail || self.killed_once)
		{
			if(self.pers["team"] == "allies") spawnpointname = "mp_lib_spawn_alliesinjail";
				else spawnpointname = "mp_lib_spawn_axisinjail";
		}
		else
		{
			if(self.pers["team"] == "allies") spawnpointname = "mp_lib_spawn_alliesnonjail";
				else spawnpointname = "mp_lib_spawn_axisnonjail";
		}

		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["roundlimit"]) self setClientCvar("cg_objectiveText", &"MP_LIB_OBJ_TEXT_ROUNDS");
		else self setClientCvar("cg_objectiveText", &"MP_LIB_OBJ_TEXT_TIME");

	self thread updateTimer();

	self maps\mp\gametypes\_spectating::setSpectatePermissions();

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");
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
	thread startRound();
}

startRound()
{
	level endon("round_ended");

	game["roundnumber"]++;

	extreme\_ex_gtcommon::createClock(game["roundlength"] * 60);

	thread Monitor_Teams();
	wait( [[level.ex_fpstime]](0.2) );
	thread Players_Free_Hud();

	thread sayObjective();

	wait( [[level.ex_fpstime]](game["roundlength"] * 60) );

	if(level.roundended) return;

	iprintln(&"MP_TIMEHASEXPIRED");

	if(level.free_hud["axis"] > level.free_hud["allies"]) thread endRound("axis");
		else if(level.free_hud["axis"] < level.free_hud["allies"]) thread endRound("allies");
			else thread endRound("draw");
}

endRound(roundwinner)
{
	if(level.roundended) return;
	level.roundended = true;

	level notify("round_ended");

	extreme\_ex_gtcommon::destroyClock();

	if(roundwinner == "allies") thread [[level.tscoreproc]]("allies", 1, false);
		else if(roundwinner == "axis") thread [[level.tscoreproc]]("axis", 1, false);

	levelAnnounceWinner(roundwinner);

	checkScoreLimit();

	game["roundsplayed"]++;
	checkRoundLimit();

	game["timepassed"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
	checkTimeLimit();

	if(level.mapended) return;
	level.mapended = true;

	extreme\_ex_main::exEndRound();

	iprintlnbold(&"MP_STARTING_NEW_ROUND");
	wait( [[level.ex_fpstime]](1) );

	level notify("restarting");
	wait( [[level.ex_fpstime]](1) );
	map_restart(true);
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

	if(game["timepassed"] < game["timelimit"]) return;

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
		if(game["alliedscore"] < level.bestoflimit && game["axisscore"] < level.bestoflimit) return;
	}
	else if(game["alliedscore"] < game["scorelimit"] && game["axisscore"] < game["scorelimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

checkRoundLimit()
{
	if(game["roundlimit"] <= 0) return;
	if(game["matchpaused"]) return;

	if(game["roundsplayed"] < game["roundlimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_ROUND_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	while(!level.ex_gameover && !game["matchpaused"])
	{
		timelimit = getCvarFloat("scr_lib_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_lib_timelimit", "1440");
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
				//timelimit = game["timelimit"] - timepassed;
				//extreme\_ex_gtcommon::createClock(timelimit * 60);

				checkTimeLimit();
			}
			//else extreme\_ex_gtcommon::destroyClock();
		}

		scorelimit = getCvarInt("scr_lib_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			checkScoreLimit();
		}

		roundlimit = getCvarInt("scr_lib_roundlimit");
		if(game["roundlimit"] != roundlimit)
		{
			game["roundlimit"] = roundlimit;
			setCvar("ui_roundlimit", game["roundlimit"]);

			checkRoundLimit();
		}

		wait( [[level.ex_fpstime]](1) );
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

Jail_Init()
{
	// Set up Objective Icons
	door_switches = getentarray("door_switch","targetname");
	for(i = 0; i < door_switches.size; i++)
	{
		door_switch = door_switches[i];

		if(door_switch.script_noteworthy == "alliesdoor")
		{
			door_switch.objective = i;
			door_switch.team = "allies";
			objective_add(i, "current", door_switch.origin, "objective");
			objective_team(i, "allies");
		}

		if(door_switch.script_noteworthy == "axisdoor")
		{
			door_switch.objective = i;
			door_switch.team = "axis";
			objective_add(i, "current", door_switch.origin, "objective");
			objective_team(i, "axis");
		}
	}

	// Setup Jailcell Zones
	axisjailfields = getentarray("axisinjail", "targetname");
	for(i = 0; i < axisjailfields.size; i++)
		axisjailfields[i] thread jail_think("axis");

	alliesjailfields = getentarray("alliesinjail", "targetname");
	for(i = 0; i < alliesjailfields.size; i++)
		alliesjailfields[i] thread jail_think("allies");

	// SETUP DOOR DAMAGE TRIGGERS

	axisjaildoordamage = getentarray("doordamageaxis", "targetname");
	for(i = 0; i < axisjaildoordamage.size; i++)
		axisjaildoordamage[i] thread jail_damagethink("axis");

	alliesjaildoordamage = getentarray("doordamageallies", "targetname");
	for(i = 0; i < alliesjaildoordamage.size; i++)
		alliesjaildoordamage[i] thread jail_damagethink("allies");
}

jail_think(team)
{
	//objective_add(self.objective, "current", self.origin, "objective");
	//objective_team(self.objective, team);

	while(1)
	{
		self waittill("trigger",other);
		
		if( level.door_closed[team] && isPlayer(other) && other.pers["team"] == team && isDefined(other.in_jail) && !other.in_jail && isAlive(other) )
			other thread goto_jail(self,team);
	}
}

goto_jail(jail,team)
{
	self endon("disconnect");

	self.in_jail = true;
	playerHudSetStatusIcon("lib_statusicon");
	self.status = "injail";

	self [[level.ex_dWeapon]]();
	while(self istouching(jail) && level.door_closed[team]) wait( [[level.ex_fpstime]](0.1) );
	self [[level.ex_eWeapon]]();

	self.in_jail = false;
	playerHudRestoreStatusIcon();
	self.status = "free";
}

jail_damagethink(team)
{
	while(1)
	{
		self waittill("trigger",other);
		
		if( isPlayer(other) && isAlive(other) )
			other thread goto_jaildamage(self,team);
	}
}

goto_jaildamage(hurt,team)
{
	self endon("disconnect");
		
	if(self istouching(hurt) && level.door_damage[team])
	{
		self.ex_forcedsuicide = true;
		self suicide();
		wait( [[level.ex_fpstime]](0.5) );
	}
}

Monitor_Teams()
{
	spawn_in_jail_delay = 120;

	level.old_allies = 0;
	level.old_axis = 0;
	old_allies_free = 0;
	old_axis_free = 0;

	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );

		level.exist["allies"] = 0;
		level.exist["axis"] = 0;
		level.free["allies"] = 0;
		level.free["axis"] = 0;

		if(spawn_in_jail_delay)
		{
			spawn_in_jail_delay--;
			if(!spawn_in_jail_delay) level.spawn_in_jail = true;
		}

		// checking players on both sides
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator")
			{
				level.exist[player.pers["team"]]++;
				if(!isDefined(player.in_jail) || !player.in_jail) level.free[player.pers["team"]]++;
			}
		}

		// We have seen allies and axis before, but one team completely left
		if( (!level.exist["allies"] && level.old_allies) || (!level.exist["axis"] && level.old_axis) )
		{
			thread endRound("draw");
			return;
		}

		if(old_axis_free != level.free["axis"] || old_allies_free != level.free["allies"] || level.old_allies != level.exist["allies"] || level.old_axis != level.exist["axis"])
		{
			level.old_axis = level.exist["axis"];
			level.old_allies = level.exist["allies"];
			old_axis_free = level.free["axis"];
			old_allies_free = level.free["allies"];
			
			level notify("Update_Free_HUD");
		}

		// No allies or axis ever spawned, so we have to wait for more players to join
		if(!level.old_allies || !level.old_axis) continue;

		// If all players on a team died (in jail), end checking
		if( (!level.free["allies"] && level.door_closed["allies"]) || (!level.free["axis"] && level.door_closed["axis"]) ) break;
	}

	// At least one team is not free, end the round
	allies_down = false;
	if(!level.free["allies"] && level.door_closed["allies"]) allies_down = true;

	axis_down = false;
	if(!level.free["axis"] && level.door_closed["axis"]) axis_down = true;

	if(allies_down && axis_down)
		thread endRound("draw");
	else if(allies_down && !axis_down)
		thread endRound("axis");
	else if(!allies_down && axis_down)
		thread endRound("allies");
}

getTeamStatus()
{
	// Checks to see if this was the last person on the team to die
	// with ALL other teammates either dead or in jail
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player.pers["team"] != self.pers["team"]) continue;
		if(player.sessionstate == "dead" || (isDefined(player.in_jail) && player.in_jail)) continue;
		if(player.sessionstate == "playing") return false;
	}

	return true;
}

sayObjective()
{
	wait( [[level.ex_fpstime]](2) );

	attacksounds["american"] = "US_mp_cmd_movein";
	attacksounds["british"] = "UK_mp_cmd_movein";
	attacksounds["russian"] = "RU_mp_cmd_movein";
	attacksounds["german"] = "GE_mp_cmd_movein";
	defendsounds["american"] = "US_mp_cmd_movein";
	defendsounds["british"] = "UK_mp_cmd_movein";
	defendsounds["russian"] = "RU_mp_cmd_movein";
	defendsounds["german"] = "GE_mp_cmd_movein";

	level thread [[level.ex_psop]](attacksounds[game[game["attackers"]]], game["attackers"]);
	level thread [[level.ex_psop]](defendsounds[game[game["defenders"]]], game["defenders"]);
}

Players_Free_Hud()
{
	coloralive = (1,1,0);
	colordead = (1,0,0);
	alpha = 0.8;

	// axis icon
	hud_index = levelHudCreate("lib_axisicon", undefined, 624, 20, alpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, game["hudicon_axis"], 16, 16);

	// allies icon
	hud_index = levelHudCreate("lib_alliesicon", undefined, 608, 20, alpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, game["hudicon_allies"], 16, 16);

	// alive icon
	hud_index = levelHudCreate("lib_aliveicon", undefined, 592, 36, alpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "hud_status_alive", 16, 16);

	// jail icon
	hud_index = levelHudCreate("lib_jailicon", undefined, 592, 52, alpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "hud_status_jail", 16, 16);

	// axis free
	hud_index = levelHudCreate("lib_axisfree", undefined, 624, 36, alpha, coloralive, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	// axis jail
	hud_index = levelHudCreate("lib_axisjail", undefined, 624, 52, alpha, colordead, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	// allies free
	hud_index = levelHudCreate("lib_alliesfree", undefined, 608, 36, alpha, coloralive, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	// allies jail
	hud_index = levelHudCreate("lib_alliesjail", undefined, 608, 52, alpha, colordead, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	level thread Maintain_Free_HUD();
}

Maintain_Free_HUD()
{
	level endon("ex_gameover");

	while(1)
	{
		level waittill("Update_Free_HUD");
		thread Update_Free_HUD();
	}
}

Update_Free_HUD()
{
	levelHudSetValue("lib_axisfree", level.free["axis"]);
	levelHudSetValue("lib_axisjail", level.old_axis - level.free["axis"]);

	levelHudSetValue("lib_alliesfree", level.free["allies"]);
	levelHudSetValue("lib_alliesjail", level.old_allies - level.free["allies"]);
}

lib_jails()
{
	//thread test();
	level.door_closed["axis"] = true;
	level.door_closed["allies"] = true;
	level.door_damage["axis"] = false;
	level.door_damage["allies"] = false;

	door_trigs = getentarray("door_trig","targetname");

	for(i = 0; i < door_trigs.size; i++)
	{
		if(!isDefined(door_trigs[i].script_noteworthy))
			door_trigs[i].script_noteworthy = "rot";

		switch(door_trigs[i].script_noteworthy)
		{
			case "alliesdoor":
				 door_trigs[i] thread allies_door_think();break;
				
			case "axisdoor":
				 door_trigs[i] thread axis_door_think();break;
		}
	}
}

addalliedplayerscore(trigger)
{
	if(level.door_closed["allies"]) iprintln(&"LIB_ALLIESFREED", [[level.ex_pname]](self));
}

addaxisplayerscore(trigger)
{
	if(level.door_closed["axis"]) iprintln(&"LIB_AXISFREED", [[level.ex_pname]](self));
}

allies_door_think()
{
	self.team = "allies";
	self setteamfortrigger("allies");

	while(1)
	{
		self waittill("trigger",other);

		if(level.door_closed["allies"])
		{					
			if(isPlayer(other))
				other thread addalliedplayerscore(self);
		}		

		door = getentarray(self.target,"targetname");

		for(i = 0; i < door.size; i++)
		{
			if(!isDefined(door[i].script_start) || door[i].script_start == false)
			{
				if(self.script_noteworthy == "slide_nouse")
					self thread open_slide_door(door[i], "allies");
				else
				{
					if(other useButtonPressed())
						self thread open_slide_door(door[i], "allies");
				}
			}
		}
	}
}

axis_door_think()
{
	self.team = "axis";
	self setteamfortrigger("axis");

	while(1)
	{
		self waittill("trigger",other);

		if(level.door_closed["axis"])
		{					
			if(isPlayer(other))
				other thread addaxisplayerscore(self);
		}		

		door = getentarray(self.target,"targetname");

		for(i = 0; i < door.size; i++)
		{
			if(!isDefined(door[i].script_start) || door[i].script_start == false)
			{
				if(self.script_noteworthy == "slide_nouse")
					self thread open_slide_door(door[i], "axis");
				else
				{
					if(other useButtonPressed())
						self thread open_slide_door(door[i], "axis");
				}
			}
		}
	}
}

test()
{
	while(1)
	{
		wait( [[level.ex_fpstime]](0.5) );
		if(getCvar("test_open") != "")
		{
			door_switches = getentarray("door_switch","targetname");
			n = 0;
			for(i = 0; i < door_switches.size; i++)
			{
				door_switch = door_switches[i];
				n++;

				if(door_switch.script_noteworthy == "alliesdoor")
					iprintln("Allies Switch Found");
				else if(door_switch.script_noteworthy == "axisdoor")
					iprintln("Axis Switch Found");
			}

			if(n == 0) iprintln("No Door Switches");

			door_trigs = getentarray("door_trig","targetname");
			for(i = 0; i < door_trigs.size; i++)
			{
				if(door_trigs[i].script_noteworthy == "alliesdoor")
					door_trigs[i] thread test_door("allies");
				else if(door_trigs[i].script_noteworthy == "axisdoor")
					door_trigs[i] thread test_door("axis");
			}
			iprintln("^3Test script: Doors Opening");
			setcvar("test_open", "");
		}
	}
}

test_door(team)
{
	door = getentarray(self.target,"targetname");

	for(i = 0; i < door.size; i++)
	{
		if(!isDefined(door[i].script_start) || door[i].script_start == false)
			self thread open_slide_door(door[i], team);

		//self thread detect_slide_touch(door[i],other);
	}
}

open_slide_door(door, team)
{
	door.script_start = true;
	open_sound1 = undefined;
	stop_sound = undefined;
	close_sound = undefined;
	alarm_sound = undefined;

	if(isDefined(door.script_noteworthy2) && (door.script_noteworthy2 == "locked"))
	{
		if(!isDefined(door.script_noteworthy))
			door.script_noteworthy = "wood";

		if(door.script_noteworthy == "wood")
			door playsound("wood_door_locked");
		else
			door playsound("metal_door_locked");

		door.script_start = false;
	}
	else
	{
		if(!isDefined(door.script_noteworthy))
			door.script_noteworthy = "wood";

		switch(door.script_noteworthy)
		{
			case "wood":
				open_sound1 = "wood_sliding_door";
				stop_sound = "wood_door_open_stop";
				close_sound = "wood_door_close_stop";
				break;
			case "metal":
				open_sound1 = "metal_door_sliding_openlib";
				stop_sound = "metal_door_sliding_close";
				close_sound = "metal_door_sliding_closelib";
				alarm_sound = "jail_alarmlib";
				break;
		}

		if(!isDefined(door.script_delay)) door.script_delay = 10;
		open_move_timer = door.script_delay;

		script_org1 = getent(door.target,"targetname");
		script_org2 = getent(script_org1.target,"targetname");
		vec = (script_org1.origin - script_org2.origin);
		pos1 = door.origin;
		pos2 = (door.origin + vec);

		move_timer = 1.4;

		while(1)
		{
			start_time = gettime();

			if(move_timer < .05) move_timer = .05;

			level.door_closed[team] = false;

			if(door.script_noteworthy == "metal")
			{
				door playsound(open_sound1);
				door playsound(alarm_sound);
			}

			door moveto(pos2, move_timer, 0, 0);
			door waittill("movedone");
			door moveto(door.origin, .05, 0, 0);

			end_time = gettime();
			time = ((end_time - start_time)/ 1000);
			move_timer -= time;

			if(door.origin == pos2) break;
				else door waittill("notouch"); // rotatedone sent by touch thread so wait
		}

		//door playsound(stop_sound);

		wait( [[level.ex_fpstime]](open_move_timer) );

		move_timer = 1.4;

		while(1)
		{
			start_time = gettime();

			if(move_timer < .05) move_timer = .05;
			if(move_timer < .2) level.door_damage[team] = true;

			if(door.script_noteworthy == "metal") door playsound(close_sound);

			door moveto(pos1, move_timer, 0, 0);
			door waittill("movedone");
			door moveto(door.origin, .05, 0, 0);

			end_time = gettime();
			time = ((end_time - start_time)/ 1000);
			move_timer -= time;

			if(door.origin == pos1) break;
				else door waittill("notouch"); // rotatedone sent by touch thread so wait
		}

		//door playsound(stop_sound);
		door notify("closed");

		level.door_closed[team] = true;
		level.door_damage[team] = false;

		door.script_start = false;
	}
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
