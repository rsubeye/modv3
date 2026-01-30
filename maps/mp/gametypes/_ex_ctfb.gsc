#include extreme\_ex_hudcontroller;

/*------------------------------------------------------------------------------
Capture the Flag Back - eXtreme+ mod compatible version
Version : 1.1
Author : La Truffe
Credits : Matthias (original CTFB in Admiral mod), Astoroth (eXtreme+ mod),
Ravir (cvardef function)
------------------------------------------------------------------------------*/

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

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.objpointflag_allies = "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis = "objpoint_flagpatch1_" + game["axis"];
	level.objpointflagmissing_allies = "objpoint_flagmissing_" + game["allies"];
	level.objpointflagmissing_axis = "objpoint_flagmissing_" + game["axis"];
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];

	switch(game["allies"])
	{
		case "american":
			game["flag_taken"] = "US_mp_flagtaken";
			break;
		case "british":
			game["flag_taken"] = "UK_mp_flagtaken";
			break;
		default:
			game["flag_taken"] = "RU_mp_flagtaken";
			break;
	}

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
		[[level.ex_PrecacheShader]](level.objpointflag_allies);
		[[level.ex_PrecacheShader]](level.objpointflag_axis);
		[[level.ex_PrecacheShader]](level.hudflag_allies);
		[[level.ex_PrecacheShader]](level.hudflag_axis);
		[[level.ex_PrecacheShader]](level.objpointflag_allies);
		[[level.ex_PrecacheShader]](level.objpointflag_axis);
		[[level.ex_PrecacheShader]](level.objpointflagmissing_allies);
		[[level.ex_PrecacheShader]](level.objpointflagmissing_axis);
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

	spawnpointname = "mp_ctf_spawn_allied";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		spawnpoints = getentarray(spawnpointname, "targetname");
		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_ctf_spawn_axis";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		spawnpoints = getentarray(spawnpointname, "targetname");
		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	if(level.random_flag_position)
	{
		spawnpointname = "mp_dm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint();
	}

	allowed[0] = "ctf";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread initFlags();
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
	self dropOwnFlag();

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

	flagrunner_enemy = false;
	if(isDefined(self.flag))
	{
		flagrunner_enemy = true;
		self dropFlag();
	}

	flagrunner_own = false;
	if(isDefined(self.ownflag))
	{
		flagrunner_own = true;
		self dropOwnFlag();
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
			if(flagrunner_enemy) reward_points += level.ex_ctfbpoints_playerkfe;
			if(flagrunner_own) reward_points += level.ex_ctfbpoints_playerkfo;
			if(level.flagprotectiondistance) reward_points += attacker checkProtectedOwnFlag(self.origin);

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

	if(game["matchovertime"] && level.ex_overtime_lastman)
	{
		level checkTeamStatus();
		if(!level.exist[self.pers["team"]]) return;
	}

	delay = 2; // Delay the player becoming a spectator till after he's done dying
	if(isDefined(self.spawned))
	{
		self thread respawn_staydead(delay);
	}
	else if(level.respawndelay) self thread respawn_timer(delay);
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

	if(game["matchovertime"] && level.ex_overtime_lastman) self.spawned = true;

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
		if(self.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_allied";
			else spawnpointname = "mp_ctf_spawn_axis";

		if(level.random_flag_position) spawnpointname = "mp_dm_spawn";

		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["scorelimit"] > 0) self setClientCvar("cg_objectiveText", &"MP_CTFB_OBJ_TEXT", game["scorelimit"]);
		else self setClientCvar("cg_objectiveText", &"MP_CTFB_OBJ_TEXT_NOSCORE");

	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	if(level.ex_spectatedead || isDefined(self.spawned))
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
	if(game["timelimit"] > 0)
	{
		if(level.ex_swapteams)
		{
			extreme\_ex_gtcommon::createClock(game["halftimelimit"] * 60);
			if(game["halftime"] == 0) levelHudSetLabel("mainclock", &"MISC_CLOCK_1H");
				else levelHudSetLabel("mainclock", &"MISC_CLOCK_2H");
		}
		else extreme\_ex_gtcommon::createClock(game["timelimit"] * 60);
	}

	while(!level.ex_gameover)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

endMap()
{
	level notify("finish_staydead");

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

	level notify("restarting");
	wait( [[level.ex_fpstime]](1) );
	exitLevel(false);
}

checkTeamStatus()
{
	if(level.mapended) return;

	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	if(game["matchpaused"]) return;

	if(!level.exist["allies"] && !level.exist["axis"])
	{
		iprintlnbold(&"MP_ALLPLAYERSHAVEBEENELIMINATED");
		level.mapended = true;
		level thread endMap();
		return;
	}

	if(!level.exist["allies"])
	{
		iprintlnbold(&"MP_ALLIESHAVEBEENELIMINATED");
		level thread [[level.ex_psop]]("mp_announcer_allieselim");
		thread [[level.tscoreproc]]("axis", 1);
		return;
	}

	if(!level.exist["axis"])
	{
		iprintlnbold(&"MP_AXISHAVEBEENELIMINATED");
		level thread [[level.ex_psop]]("mp_announcer_axiselim");
		thread [[level.tscoreproc]]("allies", 1);
		return;
	}
}

checkTimeLimit()
{
	if(game["timelimit"] <= 0) return;
	if(game["matchpaused"]) return;

	timepassed = (getTime() - level.starttime) / 1000;
	timepassed = timepassed / 60.0;

	if(level.ex_swapteams && !game["matchovertime"])
	{
		if(timepassed < game["halftimelimit"]) return;

		if(game["halftime"] == 0)
		{
			thread extreme\_ex_gtcommon::swapTeams(::returnFlag);
			return;
		}
	}
	else if(timepassed < game["timelimit"]) return;

	if(level.ex_overtime && !game["matchovertime"])
	{
		if(getTeamScore("allies") == getTeamScore("axis"))
		{
			thread extreme\_ex_gtcommon::startOvertime(::returnFlag);
			return;
		}
	}

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
	while(!level.ex_gameover && !game["matchpaused"] && !game["matchovertime"])
	{
		timelimit = getCvarFloat("scr_ctfb_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ctfb_timelimit", "1440");
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
				if(level.ex_swapteams)
				{
					game["halftimelimit"] = game["timelimit"] / 2;
					halftimelimit = game["halftimelimit"] - timepassed;
					extreme\_ex_gtcommon::createClock(halftimelimit * 60);
					if(game["halftime"] == 0) levelHudSetLabel("mainclock", &"MISC_CLOCK_1H");
						else levelHudSetLabel("mainclock", &"MISC_CLOCK_2H");
				}
				else
				{
					timelimit = game["timelimit"] - timepassed;
					extreme\_ex_gtcommon::createClock(timelimit * 60);
				}

				checkTimeLimit();
			}
			else extreme\_ex_gtcommon::destroyClock();
		}

		scorelimit = getCvarInt("scr_ctfb_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

initFlags()
{
	maperrors = [];

	allied_flags = getentarray("allied_flag", "targetname");
	if(allied_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"allied_flag\"";
	else if(allied_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"allied_flag\"";

	axis_flags = getentarray("axis_flag", "targetname");
	if(axis_flags.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"axis_flag\"";
	else if(axis_flags.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"axis_flag\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	allied_flag = getent("allied_flag", "targetname");
	axis_flag = getent("axis_flag", "targetname");

	if(level.random_flag_position)
	{
		spawnpoints = getentarray("mp_dm_spawn", "classname");
		
		allied_flag.origin = (0,0,0);
		axis_flag.origin = (0,0,0);
		
		trys = 0;
		while((distance(allied_flag.origin, axis_flag.origin) < 2200) || (allied_flag.origin == axis_flag.origin))
		{
			j = randomInt(spawnpoints.size);
			allied_flag = spawnpoints[j];
		
			j = randomInt(spawnpoints.size);
			axis_flag = spawnpoints[j];
	
			trys ++;

			if(trys > 50) break;
		}
	}
	
	if((distance(axis_flag.origin, allied_flag.origin) < 2000) || (allied_flag.origin == axis_flag.origin))
	{
		allied_flag = getent("allied_flag", "targetname");
		axis_flag = getent("axis_flag", "targetname");
	}

	allied_flag.home_origin = allied_flag.origin;
	allied_flag.home_angles = allied_flag.angles;
	allied_flag.flagmodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.flagmodel.angles = allied_flag.home_angles;
	allied_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
	allied_flag.basemodel = spawn("script_model", allied_flag.home_origin);
	allied_flag.basemodel.angles = allied_flag.home_angles;
	allied_flag.basemodel setmodel("xmodel/prop_flag_base");
	allied_flag.team = "allies";
	allied_flag.atbase = true;
	allied_flag.objective = 0;
	allied_flag.compassflag = level.compassflag_allies;
	allied_flag.objpointflag = level.objpointflag_allies;
	allied_flag.objpointflagmissing = level.objpointflagmissing_allies;
	allied_flag thread flag();
	if(level.ex_flagbase_anim_allies) allied_flag thread flagbaseAnimation(allied_flag.team, allied_flag.home_origin);

	axis_flag.home_origin = axis_flag.origin;
	axis_flag.home_angles = axis_flag.angles;
	axis_flag.flagmodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.flagmodel.angles = axis_flag.home_angles;
	axis_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
	axis_flag.basemodel = spawn("script_model", axis_flag.home_origin);
	axis_flag.basemodel.angles = axis_flag.home_angles;
	axis_flag.basemodel setmodel("xmodel/prop_flag_base");
	axis_flag.team = "axis";
	axis_flag.atbase = true;
	axis_flag.objective = 1;
	axis_flag.compassflag = level.compassflag_axis;
	axis_flag.objpointflag = level.objpointflag_axis;
	axis_flag.objpointflagmissing = level.objpointflagmissing_axis;
	axis_flag thread flag();
	if(level.ex_flagbase_anim_axis) axis_flag thread flagbaseAnimation(axis_flag.team, axis_flag.home_origin);

	level.flags	= [];
	level.flags["allies"] = allied_flag;
	level.flags["axis"] = axis_flag;
}

flagbaseAnimation(team, origin)
{
	if(isDefined(self.fxlooper)) self.fxlooper delete();
	self.fxlooper = playLoopedFx(game["flagbase_anim_" + team], 1.6, origin + (0,0,level.ex_flagbase_anim_height), 0, vectorNormalize((origin + (0,0,100)) - origin));
}

flag()
{
	objective_add(self.objective, "current", self.origin, self.compassflag);
	self createFlagWaypoint();

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.05) );

		if(level.random_flag_position)
		{
			other = undefined;
			other = self checkFlag();
		}
		else
		{
			self waittill("trigger", other);
		}

		// do not handle flag if match is paused
		if(game["matchpaused"]) continue;

		if(isPlayer(other) && isAlive(other) && (other.pers["team"] != "spectator"))
		{
			// do not allow player in stealth mode to pick up flag
			if(level.ex_stealth && isDefined(other.ex_stealth)) continue;

			if(other.pers["team"] == self.team) // Touched by team
			{
				if(self.atbase)
				{
					if(isDefined(other.flag) && (other.pers["team"] != other.flag.team)) // Captured flag
					{
						if(self.team == "axis")
						{
							enemy = "allies";
							if((level.ex_flag_voiceover & 2) == 2) level thread [[level.ex_psop]]("GE_mp_flagcap");
						}
						else
						{
							enemy = "axis";
							if((level.ex_flag_voiceover & 2) == 2) level thread [[level.ex_psop]]("mp_announcer_axisflagcap");
						}

						level thread [[level.ex_psop]]("ctf_touchcapture", self.team);
						level thread [[level.ex_psop]]("ctf_enemy_touchcapture", enemy);

						thread printOnTeam(&"MP_CTFB_ENEMY_FLAG_CAPTURED", self.team, other);
						thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_CAPTURED", enemy, other);

						other.flag returnFlag();
						other detachFlag(other.flag);
						other.flag = undefined;
						other playerHudRestoreStatusIcon();

						lpselfnum = other getEntityNumber();
						lpselfguid = other getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctfb_captured" + "\n");

						other.pers["flagcap"]++;
						other thread [[level.pscoreproc]](level.ex_ctfbpoints_playercf, "special");
						thread [[level.tscoreproc]](other.pers["team"], 1);

						if(level.ex_statshud) other thread extreme\_ex_statshud::showStatsHUD();
					}
				}
				else // Picked up own flag
				{
					level thread [[level.ex_psop]]("ctf_touchown", self.team);
					thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_PICKED_UP", self.team, other);

					if(self.team == "axis") enemy = "allies";
						else enemy = "axis";

					other pickupOwnFlag(self);
					other thread checkBaseHomeOwnFlag(self);
					if(level.ex_flag_drop) level thread dropflagUntagEnemy(enemy);

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctfb_pickup_own" + "\n");

					if(!isDefined(other.ownflagDropped)) other thread [[level.pscoreproc]](level.ex_ctfbpoints_playerpf, "special");
				}
			}
			else if(other.pers["team"] != self.team) // Touched by enemy
			{
				if(self.team == "axis") enemy = "allies";
					else enemy = "axis";

				level thread [[level.ex_psop]]("ctf_touchenemy", self.team);
				level thread [[level.ex_psop]]("ctf_enemy_touchenemy", enemy);
				if(level.ex_flag_drop) level thread dropflagUntagOwn(self.team);

				thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_TAKEN", self.team, other);
				thread printOnTeam(&"MP_CTFB_ENEMY_FLAG_TAKEN", enemy, other);

				if(self.atbase) // Stolen flag
				{
					if((level.ex_flag_voiceover & 1) == 1)
					{
						if(self.team == "axis")
							level thread [[level.ex_psop]](game["flag_taken"]);
						else
							level thread [[level.ex_psop]]("GE_mp_flagtaken");
					}

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctfb_take" + "\n");

					other thread [[level.pscoreproc]](level.ex_ctfbpoints_playersf, "special");
				}
				else // Picked up flag
				{
					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "ctfb_pickup" + "\n");

					if(!isDefined(other.enemyflagDropped)) other thread [[level.pscoreproc]](level.ex_ctfbpoints_playertf, "special");
				}

				other pickupFlag(self);
			}
		}
	}
}

checkFlag()
{
	self notify("checkFlag");
	self endon("checkFlag");

	other = undefined;

	while(isDefined(self) && !isDefined(other))
	{
		wait( [[level.ex_fpstime]](0.2) );

		players = level.players;

		for(i = 0; i < players.size; i++)
		{
			if(isDefined(self) && players[i].sessionstate == "playing" && distance(self.origin,players[i].origin) < 65)
				return players[i];				
		}		
	}	
}

checkBaseHomeOwnFlag(flag)
{
	self endon("disconnect");
	self endon("killed_player");

	self notify("checkBase");
	self endon("checkBase");

	while(isDefined(flag))
	{
		wait( [[level.ex_fpstime]](0.3) );

		if(isDefined(flag) && (self.sessionstate == "playing") && (distance(flag.basemodel.origin, self.origin) < 50))
		{
			// Returned flag (no return sounds if this is also a capture)
			if(!isDefined(self.flag))
			{
				level thread [[level.ex_psop]]("ctf_touchown", flag.team);
				if((level.ex_flag_voiceover & 4) == 4)
				{
					if(flag.team == "axis")
						level thread [[level.ex_psop]]("mp_announcer_axisflagret");
					else
						level thread [[level.ex_psop]]("mp_announcer_alliedflagret");
				}
			}

			thread printOnTeam(&"MP_CTFB_YOUR_FLAG_WAS_RETURNED", flag.team, self);

			flag returnFlag();
			self detachOwnFlag(flag);
			self.ownflag = undefined; 
			self playerHudRestoreStatusicon();

			lpselfnum = self getEntityNumber();
			lpselfguid = self getGuid();
			logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.pers["team"] + ";" + self.name + ";" + "ctfb_returned" + "\n");

			self.pers["flagret"]++;
			self thread [[level.pscoreproc]](level.ex_ctfbpoints_playerrf, "special");
			break;
		}
	}	
}

pickupFlag(flag)
{
	self endon("disconnect");

	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.flag = flag;

	flag.carrier = self;

	if(!isDefined(self.ownflag))
	{
		if(self.pers["team"] == "allies") playerHudSetStatusIcon(level.hudflag_axis);
			else if(self.pers["team"] == "axis") playerHudSetStatusIcon(level.hudflag_allies);
	}
	else self thread blinkFlags();

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();
	flag createFlagMissingWaypoint();

	objective_onEntity(flag.objective, self);
	objective_team(flag.objective, self.pers["team"]);

	self attachFlag();

	self thread showFlag_afterTime(flag);
}

pickupOwnFlag(flag)
{
	self endon("disconnect");

	flag notify("end_autoreturn");

	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	self.ownflag = flag;

	flag.carrier = self;

	if(!isDefined(self.flag))
	{
		if(self.pers["team"] == "allies") playerHudSetStatusIcon(level.hudflag_allies);
			else if(self.pers["team"] == "axis") playerHudSetStatusIcon(level.hudflag_axis);
	}
	else self thread blinkFlags();

	self.dont_auto_balance = true;

	flag deleteFlagWaypoint();

	objective_onEntity(flag.objective, self);
	objective_team(flag.objective, self.pers["team"]);

	self attachOwnFlag();

	self thread showFlag_afterTime(flag);
}

dropFlag(dropspot)
{
	if(isDefined(self.flag))
	{
		if(isDefined(dropspot)) start = dropspot + (0, 0, 10);
			else start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.flag.origin = trace["position"] + (randomint(20), randomint(20), 0);
		self.flag.flagmodel.origin = self.flag.origin;
		self.flag.flagmodel show();
		self.flag.atbase = false;
		if(isDefined(self.ownflag))
		{
			self notify("stop_blinkflags");
			if(self.pers["team"] == "allies") playerHudSetStatusIcon(level.hudflag_allies);
				else if(self.pers["team"] == "axis") playerHudSetStatusIcon(level.hudflag_axis);
		}
		else playerHudRestoreStatusIcon();

		self.flag.carrier = undefined;

		objective_position(self.flag.objective, self.flag.origin);
		objective_team(self.flag.objective, "none");

		self.flag createFlagWaypoint();

		self.flag thread autoReturn();
		self detachFlag(self.flag);

		// check if it's in a flag returner
		for(i = 0; i < level.ex_returners.size; i++)
		{
			if(self.flag.flagmodel istouching(level.ex_returners[i]))
			{
				self.flag returnFlag();
				break;
			}
		}

		if((level.ex_flag_voiceover & 8) == 8)
		{
			if(self.flag.team == "axis")
				level thread [[level.ex_psop]]("mp_announcer_axisflagdrop");
			else
				level thread [[level.ex_psop]]("mp_announcer_alliedflagdrop");
		}

		self.flag = undefined;
		self.dont_auto_balance = undefined;
	}
}

dropOwnFlag(dropspot)
{
	if(isDefined(self.ownflag))
	{
		if(isDefined(dropspot)) start = dropspot + (0, 0, 10);
			else start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		self.ownflag.origin = trace["position"] + (randomint(20),randomint(20),0);
		self.ownflag.flagmodel.origin = self.ownflag.origin;
		self.ownflag.flagmodel show();
		self.ownflag.atbase = false;
		if(isDefined(self.flag))
		{
			self notify("stop_blinkflags");
			if(self.pers["team"] == "allies") playerHudSetStatusIcon(level.hudflag_axis);
				else if(self.pers["team"] == "axis") playerHudSetStatusIcon(level.hudflag_allies);
		}
		else playerHudRestoreStatusIcon();

		self.ownflag.carrier = undefined;

		objective_position(self.ownflag.objective, self.ownflag.origin);
		objective_team(self.ownflag.objective, "none");

		self.ownflag createFlagWaypoint();

		self.ownflag thread autoReturn();
		self detachOwnFlag(self.ownflag);

		// check if it's in a flag returner
		for(i = 0; i < level.ex_returners.size; i++)
		{
			if(self.ownflag.flagmodel istouching(level.ex_returners[i]))
			{
				self.ownflag returnFlag();
				break;
			}
		}

		self.ownflag = undefined;
		self.dont_auto_balance = undefined;
	}
}

showFlag_afterTime(flag)
{
	if(!level.show_enemy_own_flag) return;

	self endon("disconnect");
	self endon("killed_player");

	flag endon("end_autoreturn");

	flag_after_sec = level.show_enemy_own_flag_after_sec;
	flag_time = level.show_enemy_own_flag_time;

	for(;;)
	{
		wait( [[level.ex_fpstime]](flag_after_sec) );

		objective_onEntity(flag.objective, self);
		objective_team(flag.objective, "none");

		wait( [[level.ex_fpstime]](flag_time) );

		objective_onEntity(flag.objective, self);
		objective_team(flag.objective, self.pers["team"]);
	}
}

returnFlag()
{
	self notify("end_autoreturn");

	if(level.ex_flag_drop)
	{
		if(self.team == "axis") enemy = "allies";
			else enemy = "axis";
		level thread dropflagUntag(enemy);
	}

	self.origin = self.home_origin;
	self.flagmodel.origin = self.home_origin;
	self.flagmodel.angles = self.home_angles;
	self.flagmodel show();
	self.atbase = true;

	self.carrier = undefined;

	objective_position(self.objective, self.origin);
	objective_team(self.objective, "none");

	self createFlagWaypoint();
	self deleteFlagMissingWaypoint();
}

autoReturn()
{
	level endon("ex_gameover");
	self endon("end_autoreturn");

	wait( [[level.ex_fpstime]](level.flagautoreturndelay) );

	if(level.ex_gameover) announce_return = false;
		else announce_return = true;

	if(announce_return)
	{
		if(self.team == "axis")
		{
			level thread [[level.ex_psop]]("mp_announcer_axisflagret");
			iprintln(&"MP_CTFB_AUTO_RETURN", &"MP_DOWNTEAM");
		}
		else
		{
			level thread [[level.ex_psop]]("mp_announcer_alliedflagret");
			iprintln(&"MP_CTFB_AUTO_RETURN", &"MP_UPTEAM");
		}
	}

	self thread returnFlag();
}

attachFlag()
{
	self endon("disconnect");

	if(isDefined(self.enemyflagAttached)) return;

	if(self.pers["team"] == "allies")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	
	self attach(flagModel, "J_Spine4", true);
	self.enemyflagAttached = true;
	self.flagAttached = true;
	
	self thread createHudIcon();
	if(level.ex_flag_drop) self thread dropFlagMonitor();
}

attachOwnFlag()
{
	self endon("disconnect");

	if(isDefined(self.ownflagAttached)) return;

	if(self.pers["team"] == "axis")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";

	self attach( flagModel, "J_Spine2", true);
	self.ownflagAttached = true;
	self.flagAttached = true;

	self thread createOwnHudIcon();
	if(level.ex_flag_drop) self thread dropFlagMonitor();
}

detachFlag(flag)
{
	self endon("disconnect");

	if(!isDefined(self.enemyflagAttached)) return;

	if(flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		
	self detach(flagModel, "J_Spine4");
	self.enemyflagAttached = undefined;

	if(!isDefined(self.ownflagAttached))
		self.flagAttached = undefined;

	self thread deleteHudIcon();
}

detachOwnFlag(flag)
{
	self endon("disconnect");

	if(!isDefined(self.ownflagAttached)) return;

	if(self.pers["team"] == "axis")
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";

	self detach(flagModel, "J_Spine2");
	self.ownflagAttached = undefined;

	if(!isDefined(self.enemyflagAttached))
		self.flagAttached = undefined;

	self thread deleteOwnHudIcon();
}

dropFlagMonitor()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.dropmonRunning)) return;
	self.dropmonRunning = true;

	while(isAlive(self) && (isDefined(self.ownflagAttached) || isDefined(self.enemyflagAttached)) )
	{
		if(self useButtonPressed() && self meleeButtonPressed())
		{
			dropspot = self getDropSpot(100);
			if(isDefined(dropspot))
			{
				if(isDefined(self.enemyflagAttached))
				{
					self.enemyflagDropped = true;
					self dropFlag(dropspot);
					if(!isDefined(self.ownflagAttached)) break;
						else while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
				}
				else if(isDefined(self.ownflagAttached))
				{
					self.ownflagDropped = true;
					self dropOwnFlag(dropspot);
					break;
				}
			}
		}
		wait( [[level.ex_fpstime]](0.05) );
	}

	self.dropmonRunning = undefined;
}

dropflagUntag(team)
{
	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			{
				players[i].ownflagDropped = undefined;
				players[i].enemyflagDropped = undefined;
			}
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
		{
			players[i].ownflagDropped = undefined;
			players[i].enemyflagDropped = undefined;
		}
	}
}

dropflagUntagEnemy(team)
{
	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i].enemyflagDropped = undefined;
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i].enemyflagDropped = undefined;
	}
}

dropflagUntagOwn(team)
{
	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i].ownflagDropped = undefined;
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i].ownflagDropped = undefined;
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

createHudIcon()
{
	self endon("disconnect");

	hud_index = playerHudCreate("ctfb_flagicon", 295, 30, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index != -1)
	{
		iconSize = 40;
		if(self.pers["team"] == "allies")
			playerHudSetShader(hud_index, level.hudflag_axis, iconSize, iconSize);
		else
			playerHudSetShader(hud_index, level.hudflag_allies, iconSize, iconSize);

		self thread pulsateHudIcon(self.pers["team"]);
	}
}

pulsateHudIcon(team)
{
	self endon("kill_thread");
	self endon("delete_hud_flag");

	if(team == "allies")
		base = level.flags["axis"].home_origin;
	else
		base = level.flags["allies"].home_origin;

	basedist = distance(self.origin, base);
	lastdist = basedist;

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](0.2) );

		basedist = distance(self.origin, base);
		if(basedist < lastdist)
		{
			playerHudSetAlpha("ctfb_flagicon", 0);
			wait( [[level.ex_fpstime]](0.2) );
			playerHudSetAlpha("ctfb_flagicon", 1);
		}

		lastdist = basedist;
	}
}

createOwnHudIcon()
{
	self endon("disconnect");

	hud_index = playerHudCreate("ctfb_ownflagicon", 345, 30, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index != -1)
	{
		iconSize = 40;
		if(self.pers["team"] == "allies")
			playerHudSetShader(hud_index, level.hudflag_allies, iconSize, iconSize);
		else
			playerHudSetShader(hud_index, level.hudflag_axis, iconSize, iconSize);

		self thread pulsateOwnHudIcon(self.pers["team"]);
	}
}

pulsateOwnHudIcon(team)
{
	self endon("kill_thread");
	self endon("delete_hud_flagown");

	if(team == "allies")
		base = level.flags["allies"].home_origin;
	else
		base = level.flags["axis"].home_origin;

	basedist = distance(self.origin, base);
	lastdist = basedist;

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](0.2) );

		basedist = distance(self.origin, base);
		if(basedist > lastdist)
		{
			playerHudSetAlpha("ctfb_ownflagicon", 0);
			wait( [[level.ex_fpstime]](0.2) );
			playerHudSetAlpha("ctfb_ownflagicon", 1);
		}

		lastdist = basedist;
	}
}

deleteHudIcon()
{
	self notify("delete_hud_flag");

	playerHudDestroy("ctfb_flagicon");
}

deleteOwnHudIcon()
{
	self notify("delete_hud_flagown");

	playerHudDestroy("ctfb_ownflagicon");
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

createFlagMissingWaypoint()
{
	if(!level.ex_objindicator) return;

	self deleteFlagMissingWaypoint();

	hud_index = levelHudCreate("waypoint_flagmissing_" + self.team, undefined, self.home_origin[0], self.home_origin[1], .61, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, self.objpointflagmissing, 7, 7);
	levelHudSetWaypoint(hud_index, self.home_origin[2] + 100, true);

	self.waypoint_base = hud_index;
}

deleteFlagMissingWaypoint()
{
	if(isDefined(self.waypoint_base))
	{
		levelHudDestroy(self.waypoint_base);
		self.waypoint_base = undefined;
	}
}

blinkFlags()
{
	self endon("disconnect");
	self endon("stop_blinkflags");

	while(isDefined(self.flag) && isDefined(self.ownflag))
	{
		if(self.statusicon == level.hudflag_allies) playerHudSetStatusIcon(level.hudflag_axis);
			else playerHudSetStatusIcon(level.hudflag_allies);

		wait( [[level.ex_fpstime]](2) );
	}
}

checkProtectedOwnFlag(victim_origin)
{
	// called from Callback_PlayerKilled(). "self" is attacker!

	// check if attacker is still playing
	if(self.pers["team"] == "spectator") return(0);

	flag = level.flags[self.pers["team"]];
	if(!isDefined(flag)) return(0);

	// is flag being carried?
	if(isDefined(flag.carrier))
	{
		// no "self-assistance"
		if(flag.carrier == self) return(0);
			
		// no assistance for enemy carrier
		if(flag.carrier.pers["team"] != self.pers["team"]) return(0);

		dist = distance(victim_origin, flag.carrier.origin);
		if(dist <= level.flagprotectiondistance)
		{
			lpselfnum = self getEntityNumber();
			lpselfguid = self getGuid();
			logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.pers["team"] + ";" + self.name + ";" + "ctfb_assist" + "\n");
			iprintln(&"MP_CTFB_ASSIST", [[level.ex_pname]](self));
			return(level.ex_ctfbpoints_assist);
		}
	}
	// flag is at base, or was dropped
	else
	{
		if(flag.atbase) dist = distance(victim_origin, flag.home_origin);
			else dist = distance(victim_origin, flag.origin);

		if(dist <= level.flagprotectiondistance)
		{
			lpselfnum = self getEntityNumber();
			lpselfguid = self getGuid();
			logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + self.pers["team"] + ";" + self.name + ";" + "ctfb_defend" + "\n");
			iprintln(&"MP_CTFB_DEFEND", [[level.ex_pname]](self));
			return(level.ex_ctfbpoints_defend);
		}
	}

	return(0);
}

printOnTeam(text, team, player)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text, [[level.ex_pname]](player));
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

respawn_staydead(delay)
{
	self endon("disconnect");

	if(isDefined(self.WaitingToSpawn)) return;
	self.WaitingToSpawn = true;

	wait( [[level.ex_fpstime]](delay) );

	hud_index = playerHudCreate("respawn_staydead", 0, -50, 1, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		playerHudSetKeepOnKill(hud_index, true);
		playerHudSetText(hud_index, &"MISC_OVERTIME_WAIT");
	}

	level waittill("finish_staydead");

	playerHudDestroy("respawn_staydead");

	//self.WaitingToSpawn = undefined;
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
