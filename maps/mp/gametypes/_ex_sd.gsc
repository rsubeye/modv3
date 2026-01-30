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
		[[level.ex_PrecacheShader]]("plantbomb");
		[[level.ex_PrecacheShader]]("defusebomb");
		[[level.ex_PrecacheShader]]("objective");
		[[level.ex_PrecacheShader]]("objectiveA");
		[[level.ex_PrecacheShader]]("objectiveB");
		[[level.ex_PrecacheShader]]("bombplanted");
		[[level.ex_PrecacheShader]]("objpoint_bomb");
		[[level.ex_PrecacheShader]]("objpoint_A");
		[[level.ex_PrecacheShader]]("objpoint_B");
		[[level.ex_PrecacheShader]]("objpoint_star");
		[[level.ex_PrecacheShader]]("hudStopwatch");
		[[level.ex_PrecacheShader]]("hudstopwatchneedle");
		[[level.ex_PrecacheModel]]("xmodel/mp_tntbomb");
		[[level.ex_PrecacheModel]]("xmodel/mp_tntbomb_obj");
		[[level.ex_PrecacheString]](&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
		[[level.ex_PrecacheString]](&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");
		[[level.ex_PrecacheString]](&"MP_PLANTING_EXPLOSIVES");
		[[level.ex_PrecacheString]](&"MP_DEFUSING_EXPLOSIVES");
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
	thread maps\mp\gametypes\_objpoints::init();
	thread maps\mp\gametypes\_friendicons::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_grenadeindicators::init();
	thread maps\mp\gametypes\_quickmessages::init();
	thread maps\mp\gametypes\_models::init();
	extreme\_ex_varcache::postmapload();

	game["precachedone"] = true;
	setClientNameMode("manual_change");

	spawnpointname = "mp_sd_spawn_attacker";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	spawnpointname = "mp_sd_spawn_defender";
	spawnpoints = getentarray(spawnpointname, "classname");

	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] PlaceSpawnpoint();

	level._effect["bombexplosion"] = [[level.ex_PrecacheEffect]]("fx/props/barrelexp.efx");

	allowed[0] = "sd";
	allowed[1] = "bombzone";
	allowed[2] = "blocker";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.progressBarY = 104;
	level.progressBarHeight = 12;
	level.progressBarWidth = 192;

	level.bombplanted = false;
	level.bombexploded = false;
	level.roundstarted = false;
	level.roundended = false;
	level.mapended = false;
	level.bombmode = 0;
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["matchstarted"])) game["matchstarted"] = false;
	if(!isDefined(game["timepassed"])) game["timepassed"] = 0;
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread bombzones();
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
	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	level updateTeamStatus();
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

	self.sessionstate = "dead";
	playerHudSetStatusIcon("hud_status_dead");

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

	level updateTeamStatus();

	if(!level.exist[self.pers["team"]]) // If the last player on a team was just killed, don't do killcam
	{
		doKillcam = false;
		self.skip_setspectatepermissions = true;

		if(level.bombplanted && level.planting_team == self.pers["team"])
		{
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				if(player.pers["team"] == self.pers["team"])
				{
					player allowSpectateTeam("allies", true);
					player allowSpectateTeam("axis", true);
					player allowSpectateTeam("freelook", true);
					player allowSpectateTeam("none", false);
				}
			}
		}
	}

	delay = 2; // Delay the player becoming a spectator till after he's done dying
	wait( [[level.ex_fpstime]](delay) ); // Also required for Callback_PlayerKilled to complete before killcam can execute

	if(doKillcam && level.killcam && !level.roundended)
		self maps\mp\gametypes\_killcam::killcam(lpattacknum, delay, psOffsetTime);

	self thread extreme\_ex_spawn::spawnSpectator(self.origin + (0, 0, 60), self.angles);
}

spawnPlayer()
{
	self endon("disconnect");
	self notify("spawned");

	// Handle ready-up spawn tickets
	if(level.ex_readyup == 2 && isDefined(game["readyup_done"]))
	{
		if(!isDefined(self.pers["readyup_spawnticket"]))
		{
			if(level.ex_readyup_status == 2 && level.ex_readyup_ticketing == 1)
				self.pers["readyup_spawnticket"] = 1;
			else if(level.ex_readyup_status == 3)
				self.pers["readyup_spawnticket"] = 1;
			else
			{
				self extreme\_ex_readyup::moveToSpectators();
				playerHudSetStatusIcon("hud_status_dead");
				self extreme\_ex_readyup::waitForNextRound();
				return;
			}
		}
	}

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	if(isDefined(self.spawned)) return;
	self.spawned = true;

	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;
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
		if(game["attackers"] == "axis")
		{
			if(self.pers["team"] == "axis") spawnpointname = "mp_sd_spawn_attacker";
				else spawnpointname = "mp_sd_spawn_defender";
		}
		else
		{
			if(self.pers["team"] == "allies") spawnpointname = "mp_sd_spawn_attacker";
				else spawnpointname = "mp_sd_spawn_defender";
		}

		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	level updateTeamStatus();

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["roundlimit"])
	{
		if(self.pers["team"] == game["attackers"]) self setClientCvar("cg_objectiveText", &"MP_OBJ_ATTACKERS", game["roundlimit"]);
			else if(self.pers["team"] == game["defenders"]) self setClientCvar("cg_objectiveText", &"MP_OBJ_DEFENDERS", game["roundlimit"]);
	}
	else
	{
		if(self.pers["team"] == game["attackers"]) self setClientCvar("cg_objectiveText", &"MP_OBJ_ATTACKERS_NOSCORE");
			else if(self.pers["team"] == game["defenders"]) self setClientCvar("cg_objectiveText", &"MP_OBJ_DEFENDERS_NOSCORE");
	}

	if(level.bombplanted) thread showPlayerBombTimer();

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");
}

startGame()
{
	thread startRound();
}

startRound()
{
	level endon("bomb_planted");
	level endon("round_ended");

	game["matchstarted"] = true; // mainly to control UpdateTeamStatus
	game["roundnumber"]++;

	extreme\_ex_gtcommon::createClock(game["roundlength"] * 60);
	
	wait( [[level.ex_fpstime]](game["roundlength"] * 60) );

	if(level.roundended) return;

	iprintln(&"MP_TIMEHASEXPIRED");

	if(!level.exist[game["attackers"]] || !level.exist[game["defenders"]]) level thread endRound("draw");
		else level thread endRound(game["defenders"]);
}

endRound(roundwinner)
{
	if(level.roundended) return;
	level.roundended = true;

	level notify("round_ended");

	extreme\_ex_gtcommon::destroyClock();

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player playerHudDestroy("sd_progress1");
		player playerHudDestroy("sd_progress2");
		player playerHudDestroy("sd_progress3");

		player unlink();
		player [[level.ex_eWeapon]]();

		if(level.ex_readyup == 2) player.pers["readyup_spawnticket"] = 1;
	}

	objective_delete(0);
	objective_delete(1);

	if(roundwinner == "allies") thread [[level.tscoreproc]]("allies", 1, false);
		else if(roundwinner == "axis") thread [[level.tscoreproc]]("axis", 1, false);

	levelAnnounceWinner(roundwinner);

	checkScoreLimit();

	game["roundsplayed"]++;
	checkRoundLimit();

	game["timepassed"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
	checkTimeLimit();

	if(level.mapended) return;

	extreme\_ex_main::exEndRound();

	iprintlnbold(&"MP_STARTING_NEW_ROUND");
	wait( [[level.ex_fpstime]](1) );

	if(level.ex_swapteams == 1) extreme\_ex_gtcommon::swapTeams();
	else if(level.ex_swapteams == 2 && game["roundnumber"] == game["halftimelimit"]) extreme\_ex_gtcommon::swapTeams();
	else
	{
		level notify("restarting");
		wait( [[level.ex_fpstime]](1) );
		map_restart(true);
	}
}

endMap()
{
	if(isDefined(level.bombmodel))
		level.bombmodel stopLoopSound();

	game["alliedscore"] = getTeamScore("allies");
	game["axisscore"] = getTeamScore("axis");

	if(game["alliedscore"] == game["axisscore"])
	{
		winningteam = "tie";
		losingteam = "tie";
	}
	else if(game["alliedscore"] > game["axisscore"])
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
		timelimit = getCvarFloat("scr_sd_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_sd_timelimit", "1440");
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

				if(game["matchstarted"]) checkTimeLimit();
			}
			//else extreme\_ex_gtcommon::destroyClock();
		}

		scorelimit = getCvarInt("scr_sd_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			if(game["matchstarted"]) checkScoreLimit();
		}

		roundlimit = getCvarInt("scr_sd_roundlimit");
		if(game["roundlimit"] != roundlimit)
		{
			game["roundlimit"] = roundlimit;
			setCvar("ui_roundlimit", game["roundlimit"]);

			if(level.ex_swapteams == 2 && game["roundnumber"] < game["halftimelimit"])
				game["halftimelimit"] = int((roundlimit / 2) + 0.5);

			if(game["matchstarted"]) checkRoundLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

updateTeamStatus()
{
	wait 0; // Required for Callback_PlayerDisconnect to complete before updateTeamStatus can execute

	if(!game["matchstarted"]) return;

	resettimeout();

	oldvalue["allies"] = level.exist["allies"];
	oldvalue["axis"] = level.exist["axis"];
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			level.exist[player.pers["team"]]++;
	}

	if(level.roundended || game["matchpaused"]) return;

	// if both allies and axis were alive and now they are both dead in the same instance
	if(oldvalue["allies"] && !level.exist["allies"] && oldvalue["axis"] && !level.exist["axis"])
	{
		if(level.bombplanted)
		{
			// if allies planted the bomb, allies win
			if(level.planting_team == "allies")
			{
				iprintlnbold(&"MP_ALLIEDMISSIONACCOMPLISHED");
				level thread endRound("allies");
				return;
			}
			else // axis planted the bomb, axis win
			{
				assert(game["attackers"] == "axis");
				iprintlnbold(&"MP_AXISMISSIONACCOMPLISHED");
				level thread endRound("axis");
				return;
			}
		}

		// if there is no bomb planted the round is a draw
		iprintlnbold(&"MP_ROUNDDRAW");
		level thread endRound("draw");
		return;
	}

	// if allies were alive and now they are not
	if(oldvalue["allies"] && !level.exist["allies"])
	{
		// if allies planted the bomb, continue the round
		if(level.bombplanted && level.planting_team == "allies") return;
		iprintlnbold(&"MP_ALLIESHAVEBEENELIMINATED");
		level thread [[level.ex_psop]]("mp_announcer_allieselim");
		level thread endRound("axis");
		return;
	}

	// if axis were alive and now they are not
	if(oldvalue["axis"] && !level.exist["axis"])
	{
		// if axis planted the bomb, continue the round
		if(level.bombplanted && level.planting_team == "axis") return;
		iprintlnbold(&"MP_AXISHAVEBEENELIMINATED");
		level thread [[level.ex_psop]]("mp_announcer_axiselim");
		level thread endRound("allies");
		return;
	}
}

bombzones()
{
	maperrors = [];

	wait( [[level.ex_fpstime]](0.2) );

	bombzones = getentarray("bombzone", "targetname");
	array = [];

	if(level.bombmode == 0)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isDefined(bombzone.script_bombmode_original) && isDefined(bombzone.script_label))
				array[array.size] = bombzone;
		}

		if(array.size == 2)
		{
			bombzone0 = array[0];
			bombzone1 = array[1];
			bombzoneA = undefined;
			bombzoneB = undefined;

			if(bombzone0.script_label == "A" || bombzone0.script_label == "a")
			{
				bombzoneA = bombzone0;
				bombzoneB = bombzone1;
			}
			else if(bombzone0.script_label == "B" || bombzone0.script_label == "b")
			{
				bombzoneA = bombzone1;
				bombzoneB = bombzone0;
			}
			else
				maperrors[maperrors.size] = "^1Bombmode original: Bombzone found with an invalid \"script_label\", must be \"A\" or \"B\"";

			objective_add(0, "current", bombzoneA.origin, "objectiveA");
			objective_add(1, "current", bombzoneB.origin, "objectiveB");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneA.origin + (0,0,20), "0", "allies", "objpoint_A");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneB.origin + (0,0,20), "1", "allies", "objpoint_B");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneA.origin + (0,0,20), "0", "axis", "objpoint_A");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzoneB.origin + (0,0,20), "1", "axis", "objpoint_B");

			bombzoneA thread bombzone_think(bombzoneB);
			bombzoneB thread bombzone_think(bombzoneA);
		}
		else if(array.size < 2)
			maperrors[maperrors.size] = "^1Bombmode original: Less than 2 bombzones found with \"script_bombmode_original\" \"1\"";
		else if(array.size > 2)
			maperrors[maperrors.size] = "^1Bombmode original: More than 2 bombzones found with \"script_bombmode_original\" \"1\"";
	}
	else if(level.bombmode == 1)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isDefined(bombzone.script_bombmode_single))
				array[array.size] = bombzone;
		}

		if(array.size == 1)
		{
			objective_add(0, "current", array[0].origin, "objective");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(array[0].origin + (0,0,20), "single", "allies", "objpoint_star");
			thread maps\mp\gametypes\_objpoints::addTeamObjpoint(array[0].origin + (0,0,20), "single", "axis", "objpoint_star");

			array[0] thread bombzone_think();
		}
		else if(array.size < 1)
			maperrors[maperrors.size] = "^1Bombmode single: Less than 1 bombzone found with \"script_bombmode_single\" \"1\"";
		else if(array.size > 1)
			maperrors[maperrors.size] = "^1Bombmode single: More than 1 bombzone found with \"script_bombmode_single\" \"1\"";
	}
	else if(level.bombmode == 2)
	{
		for(i = 0; i < bombzones.size; i++)
		{
			bombzone = bombzones[i];

			if(isDefined(bombzone.script_bombmode_dual))
				array[array.size] = bombzone;
		}

		if(array.size == 2)
		{
			bombzone0 = array[0];
			bombzone1 = array[1];

			objective_add(0, "current", bombzone0.origin, "objective");
			objective_add(1, "current", bombzone1.origin, "objective");

			if(isDefined(bombzone0.script_team) && isDefined(bombzone1.script_team))
			{
				if((bombzone0.script_team == "allies" && bombzone1.script_team == "axis") || (bombzone0.script_team == "axis" || bombzone1.script_team == "allies"))
				{
					objective_team(0, bombzone0.script_team);
					objective_team(1, bombzone1.script_team);

					if(bombzone0.script_team == "allies")
					{
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone0.origin + (0,0,20), "0", "allies", "objpoint_star");
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone1.origin + (0,0,20), "1", "axis", "objpoint_star");
					}
					else
					{
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone0.origin + (0,0,20), "0", "axis", "objpoint_star");
						thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombzone1.origin + (0,0,20), "1", "allies", "objpoint_star");
					}
				}
				else
					maperrors[maperrors.size] = "^1Bombmode dual: One or more bombzones missing \"script_team\" \"allies\" or \"axis\"";
			}

			bombzone0 thread bombzone_think(bombzone1);
			bombzone1 thread bombzone_think(bombzone0);
		}
		else if(array.size < 2)
			maperrors[maperrors.size] = "^1Bombmode dual: Less than 2 bombzones found with \"script_bombmode_dual\" \"1\"";
		else if(array.size > 2)
			maperrors[maperrors.size] = "^1Bombmode dual: More than 2 bombzones found with \"script_bombmode_dual\" \"1\"";
	}
	else
		println("^6Unknown bomb mode");

	bombtriggers = getentarray("bombtrigger", "targetname");
	if(bombtriggers.size < 1)
		maperrors[maperrors.size] = "^1No entities found with \"targetname\" \"bombtrigger\"";
	else if(bombtriggers.size > 1)
		maperrors[maperrors.size] = "^1More than 1 entity found with \"targetname\" \"bombtrigger\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	bombtrigger = getent("bombtrigger", "targetname");
	bombtrigger maps\mp\_utility::triggerOff();

	// Kill unused bombzones and associated script_exploders

	accepted = [];
	for(i = 0; i < array.size; i++)
	{
		if(isDefined(array[i].script_noteworthy))
			accepted[accepted.size] = array[i].script_noteworthy;
	}

	remove = [];
	bombzones = getentarray("bombzone", "targetname");
	for(i = 0; i < bombzones.size; i++)
	{
		bombzone = bombzones[i];

		if(isDefined(bombzone.script_noteworthy))
		{
			addtolist = true;
			for(j = 0; j < accepted.size; j++)
			{
				if(bombzone.script_noteworthy == accepted[j])
				{
					addtolist = false;
					break;
				}
			}

			if(addtolist)
				remove[remove.size] = bombzone.script_noteworthy;
		}
	}

	ents = getentarray();
	for(i = 0; i < ents.size; i++)
	{
		ent = ents[i];

		if(isDefined(ent.script_exploder))
		{
			kill = false;
			for(j = 0; j < remove.size; j++)
			{
				if(ent.script_exploder == int(remove[j]))
				{
					kill = true;
					break;
				}
			}

			if(kill)
				ent delete();
		}
	}
}

bombzone_think(bombzone_other)
{
	level endon("round_ended");

	self setteamfortrigger(game["attackers"]);
	self setHintString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");

	for(;;)
	{
		self waittill("trigger", other);

		if(isDefined(bombzone_other) && isDefined(bombzone_other.planting))
			continue;

		if(level.bombmode == 2 && isDefined(self.script_team))
			team = self.script_team;
		else
			team = game["attackers"];

		if(isPlayer(other) && (other.pers["team"] == team) && other isOnGround())
		{
			while(isAlive(other) && other istouching(self) && other useButtonPressed())
			{
				other notify("kill_check_bombzone");

				other clientclaimtrigger(self);
				other clientclaimtrigger(bombzone_other);
				self.planting = true;
				other.ex_planting = true;
				self setHintString(&" ");

				hud_index = other playerHudCreate("sd_progress1", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
				if(hud_index != -1) other playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

				hud_index = other playerHudCreate("sd_progress2", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
				if(hud_index != -1)
				{
					other playerHudSetShader(hud_index, "white", 1, level.progressBarHeight);
					other playerHudScale(hud_index, level.planttime, 0, level.progressBarWidth, level.progressBarHeight);
				}

				hud_index = other playerHudCreate("sd_progress3", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
				if(hud_index != -1) other playerHudSetText(hud_index, &"MP_PLANTING_EXPLOSIVES");

				other playsound("MP_bomb_plant");
				other linkTo(self);
				other [[level.ex_dWeapon]]();

				other.progresstime = 0;
				while(isAlive(other) && other useButtonPressed())
				{
					wait( level.ex_fps_frame );
					other.progresstime += level.ex_fps_frame;
					if(other.progresstime >= level.planttime) break;
				}

				// TODO: script error if player is disconnected/kicked here
				other clientreleasetrigger(self);
				other clientreleasetrigger(bombzone_other);
				other.ex_planting = undefined;

				other playerHudDestroy("sd_progress1");
				other playerHudDestroy("sd_progress2");
				other playerHudDestroy("sd_progress3");

				if(other.progresstime >= level.planttime)
				{
					other [[level.ex_eWeapon]]();
					other thread [[level.pscoreproc]](level.ex_sdpoints_plant, "special");

					if(isDefined(self.target))
					{
						exploder = getent(self.target, "targetname");

						if(isDefined(exploder) && isDefined(exploder.script_exploder))
							level.bombexploder = exploder.script_exploder;
					}

					bombzones = getentarray("bombzone", "targetname");
					for(i = 0; i < bombzones.size; i++)
						bombzones[i] delete();

					if(level.bombmode == 1)
					{
						objective_delete(0);
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					}
					else
					{
						objective_delete(0);
						objective_delete(1);
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
						thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					}

					plant = other maps\mp\_utility::getPlant();

					level.bombmodel = spawn("script_model", plant.origin);
					level.bombmodel.angles = plant.angles;
					level.bombmodel setmodel("xmodel/mp_tntbomb");
					level.bombmodel playSound("Explo_plant_no_tick");
					level.bombglow = spawn("script_model", plant.origin);
					level.bombglow.angles = plant.angles;
					level.bombglow setmodel("xmodel/mp_tntbomb_obj");

					bombtrigger = getent("bombtrigger", "targetname");
					bombtrigger.origin = level.bombmodel.origin;

					objective_add(0, "current", bombtrigger.origin, "objective");
					thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
					thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombtrigger.origin + (0,0,20), "bomb", "allies", "objpoint_star");
					thread maps\mp\gametypes\_objpoints::addTeamObjpoint(bombtrigger.origin + (0,0,20), "bomb", "axis", "objpoint_star");

					level.bombplanted = true;
					level.bombtimerstart = gettime();
					level.planting_team = other.pers["team"];

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "bomb_plant" + "\n");

					iprintln(&"MP_EXPLOSIVESPLANTED");
					level thread soundPlanted(other);

					bombtrigger thread bomb_think();
					bombtrigger thread bomb_countdown();

					level notify("bomb_planted");
					extreme\_ex_gtcommon::destroyClock();

					return;
				}
				else
				{
					other unlink();
					other [[level.ex_eWeapon]]();

					self setHintString(&"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES");
				}

				wait( [[level.ex_fpstime]](0.05) );
			}

			self.planting = undefined;
			other.ex_planting = undefined;
			other thread check_bombzone(self);
		}
	}
}

check_bombzone(trigger)
{
	self notify("kill_check_bombzone");
	self endon("kill_check_bombzone");
	self endon("disconnect");
	level endon("round_ended");

	while(isDefined(trigger) && !isDefined(trigger.planting) && self istouching(trigger) && isAlive(self))
		wait( [[level.ex_fpstime]](0.05) );
}

bomb_countdown()
{
	self endon("bomb_defused");
	level endon("intermission");

	thread showBombTimers();
	level.bombmodel playLoopSound("bomb_tick");

	wait( [[level.ex_fpstime]](level.bombtimer) );

	// bomb timer is up
	objective_delete(0);
	thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
	thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
	thread deleteBombTimers();

	level.bombexploded = true;
	self notify("bomb_exploded");

	// trigger exploder if it exists
	if(isDefined(level.bombexploder))
		maps\mp\_utility::exploder(level.bombexploder);

	// explode bomb
	origin = self getorigin();
	range = 500;
	maxdamage = 2000;
	mindamage = 1000;

	self delete(); // delete the defuse trigger
	level.bombmodel stopLoopSound();
	level.bombmodel delete();
	level.bombglow delete();

	playfx(level._effect["bombexplosion"], origin);
	radiusDamage(origin, range, maxdamage, mindamage);

	level thread [[level.ex_psop]]("mp_announcer_objdest");
	level thread endRound(level.planting_team);
}

bomb_think()
{
	self endon("bomb_exploded");

	self setteamfortrigger(game["defenders"]);
	self setHintString(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");

	for(;;)
	{
		self waittill("trigger", other);

		// check for having been triggered by a valid player
		if(isPlayer(other) && (other.pers["team"] != level.planting_team) && other isOnGround())
		{
			while(isAlive(other) && other useButtonPressed())
			{
				other notify("kill_check_bomb");

				other clientclaimtrigger(self);
				other.ex_defusing = true;
				self setHintString(&" ");

				hud_index = other playerHudCreate("sd_progress1", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
				if(hud_index != -1) other playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

				hud_index = other playerHudCreate("sd_progress2", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
				if(hud_index != -1)
				{
					other playerHudSetShader(hud_index, "white", level.progressBarWidth, level.progressBarHeight);
					other playerHudScale(hud_index, level.defusetime, 0, 1, level.progressBarHeight);
				}

				hud_index = other playerHudCreate("sd_progress3", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
				if(hud_index != -1) other playerHudSetText(hud_index, &"MP_DEFUSING_EXPLOSIVES");

				other playsound("MP_bomb_defuse");
				other linkTo(self);
				other [[level.ex_dWeapon]]();

				other.progresstime = 0;
				while(isAlive(other) && other useButtonPressed())
				{
					wait( level.ex_fps_frame );
					other.progresstime += level.ex_fps_frame;
					if(other.progresstime >= level.defusetime) break;
				}

				other clientreleasetrigger(self);
				other.ex_defusing = undefined;

				other playerHudDestroy("sd_progress1");
				other playerHudDestroy("sd_progress2");
				other playerHudDestroy("sd_progress3");

				if(other.progresstime >= level.defusetime)
				{
					other unlink();
					other [[level.ex_eWeapon]]();

					objective_delete(0);
					thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("allies");
					thread maps\mp\gametypes\_objpoints::removeTeamObjpoints("axis");
					thread deleteBombTimers();

					self notify("bomb_defused");
					level.bombmodel stopLoopSound();
					level.bombglow delete();
					self delete();

					iprintln(&"MP_EXPLOSIVESDEFUSED");
					level thread [[level.ex_psop]]("MP_announcer_bomb_defused");

					lpselfnum = other getEntityNumber();
					lpselfguid = other getGuid();
					logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + other.pers["team"] + ";" + other.name + ";" + "bomb_defuse" + "\n");

					other thread [[level.pscoreproc]](level.ex_sdpoints_defuse, "special");

					level thread endRound(other.pers["team"]);
					return;
				}
				else
				{
					other unlink();
					other [[level.ex_eWeapon]]();

					self setHintString(&"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES");
				}

				wait( [[level.ex_fpstime]](0.05) );
			}

			self.defusing = undefined;
			other.ex_defusing = undefined;
			other thread check_bomb(self);
		}
	}
}

check_bomb(trigger)
{
	self notify("kill_check_bomb");
	self endon("kill_check_bomb");
	self endon("disconnect");
	level endon("round_ended");

	while(isDefined(trigger) && !isDefined(trigger.defusing) && self istouching(trigger) && isAlive(self))
		wait( [[level.ex_fpstime]](0.05) );
}

sayMoveIn()
{
	wait( [[level.ex_fpstime]](2) );

	alliedsoundalias = game["allies"] + "_move_in";
	axissoundalias = game["axis"] + "_move_in";

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player.pers["team"] == "allies") player playLocalSound(alliedsoundalias);
		else if(player.pers["team"] == "axis") player playLocalSound(axissoundalias);
	}
}

showBombTimers()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
			player showPlayerBombTimer();
	}
}

showPlayerBombTimer()
{
	timeleft = (level.bombtimer - (getTime() - level.bombtimerstart) / 1000);

	if(timeleft > 0)
	{
		hud_index = playerHudCreate("sd_bombtimer", 6, 76, 1, (1,1,1), 1, 0, "left", "top", "left", "top", false, true);
		if(hud_index == -1) return;
		playerHudSetClock(hud_index, timeleft, level.bombtimer, "hudStopwatch", 48, 48);
		self.bombtimer = hud_index;
	}
}

deleteBombTimers()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
		players[i] deletePlayerBombTimer();
}

deletePlayerBombTimer()
{
	if(isDefined(self.bombtimer))
		playerHudDestroy(self.bombtimer);
}

soundPlanted(player)
{
	if(game["allies"] == "british") alliedsound = "UK_mp_explosivesplanted";
	else if(game["allies"] == "russian") alliedsound = "RU_mp_explosivesplanted";
	else alliedsound = "US_mp_explosivesplanted";

	axissound = "GE_mp_explosivesplanted";

	level thread [[level.ex_psop]](alliedsound, "allies");
	level thread [[level.ex_psop]](axissound, "axis");

	wait( [[level.ex_fpstime]](1.5) );

	if(level.planting_team == "allies")
	{
		if(game["allies"] == "british") alliedsound = "UK_mp_defendbomb";
		else if(game["allies"] == "russian") alliedsound = "RU_mp_defendbomb";
		else alliedsound = "US_mp_defendbomb";

		level thread [[level.ex_psop]](alliedsound, "allies");
		level thread [[level.ex_psop]]("GE_mp_defusebomb", "axis");
	}
	else if(level.planting_team == "axis")
	{
		if(game["allies"] == "british") alliedsound = "UK_mp_defusebomb";
		else if(game["allies"] == "russian") alliedsound = "RU_mp_defusebomb";
		else alliedsound = "US_mp_defusebomb";

		level thread [[level.ex_psop]](alliedsound, "allies");
		level thread [[level.ex_psop]]("GE_mp_defendbomb", "axis");
	}
}
