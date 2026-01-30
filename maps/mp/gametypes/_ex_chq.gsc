#include extreme\_ex_hudcontroller;

main()
{
	// Trick SET: pretend we're on HQ gametype to get the level.radio definitions in the map script
	setcvar("g_gametype", "hq");

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

	// Over-override Callback_StartGameType
	level.chq_callbackStartGameType = level.callbackStartGameType;
	level.callbackStartGameType = ::CHQ_Callback_StartGameType;

	// set eXtreme+ variables and precache (phase 1 only)
	extreme\_ex_varcache::main(1);
}

CHQ_Callback_StartGameType()
{
	// Trick UNSET: restore CHQ gametype
	setcvar("g_gametype", "chq");

	// set eXtreme+ variables and precache (phase 2 only)
	extreme\_ex_varcache::main(2);

	[[level.chq_callbackStartGameType]]();
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	game["radio_prespawn"][0] = "objectiveA";
	game["radio_prespawn"][1] = "objectiveB";
	game["radio_prespawn"][2] = "objective";
	game["radio_prespawn_objpoint"][0] = "objpoint_A";
	game["radio_prespawn_objpoint"][1] = "objpoint_B";
	game["radio_prespawn_objpoint"][2] = "objpoint_star";
	game["radio_none"] = "objective";
	game["radio_axis"] = "objective_" + game["axis"];
	game["radio_allies"] = "objective_" + game["allies"];

	switch(game["allies"])
	{
		case "american":
			game["radio_model"] = "xmodel/military_german_fieldradio_green_nonsolid";
			break;
		case "british":
			game["radio_model"] = "xmodel/military_german_fieldradio_tan_nonsolid";
			break;
		default:
			game["radio_model"] = "xmodel/military_german_fieldradio_grey_nonsolid";
			break;
	}

	if(!isDefined(game["precachedone"]))
	{
		[[level.ex_PrecacheRumble]]("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("hud_status_dead");
			[[level.ex_PrecacheStatusIcon]]("hud_status_connecting");
		}
		[[level.ex_PrecacheShader]]("objective");
		[[level.ex_PrecacheShader]]("objectiveA");
		[[level.ex_PrecacheShader]]("objectiveB");
		[[level.ex_PrecacheShader]]("objpoint_A");
		[[level.ex_PrecacheShader]]("objpoint_B");
		[[level.ex_PrecacheShader]]("objpoint_radio");
		[[level.ex_PrecacheShader]]("field_radio");
		[[level.ex_PrecacheShader]](game["radio_allies"]);
		[[level.ex_PrecacheShader]](game["radio_axis"]);
		[[level.ex_PrecacheModel]](game["radio_model"]);
		[[level.ex_PrecacheString]](&"MP_TIME_TILL_SPAWN");
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");
		[[level.ex_PrecacheString]](&"MP_ESTABLISHING_HQ");
		[[level.ex_PrecacheString]](&"MP_DESTROYING_HQ");
		[[level.ex_PrecacheString]](&"MP_LOSING_HQ");
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

	level._effect["radioexplosion"] = [[level.ex_PrecacheEffect]]("fx/explosions/grenadeExp_blacktop.efx");

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

	level.progressBarY = 104;
	level.progressBarHeight = 12;
	level.progressBarWidth = 192;

	level.mapended = false;
	level.roundStarted = false;
	level.timesCaptured = 0;
	level.nextradio = 0;
	level.DefendingRadioTeam = "none";
	level.MultipleCaptureBias = 1;
	level.NeutralizingPoints = level.ex_hqpoints_teamneut;
	level.RadioSpawnDelay = level.ex_hq_radio_spawntime;
	level.RadioMaxHoldSeconds = level.ex_hq_radio_holdtime;
	level.captured_radios["allies"] = 0;
	level.captured_radios["axis"] = 0;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		hq_setup();
		thread hq_points();
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

	// check if it was the last person to die on the defending team
	level updateTeamStatus();
	if((isDefined(self.pers["team"])) && (level.DefendingRadioTeam == self.pers["team"]) && (level.exist[self.pers["team"]] <= 0))
	{
		for(i = 0; i < level.radio.size; i++)
		{
			if(level.radio[i].hidden == true) continue;
			level hq_radio_capture(level.radio[i], "none");
			break;
		}
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
	self.isscorer = undefined;
	self.esthq = undefined;
	self.desthq = undefined;

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
		spawnpoint = undefined;

		if(level.ex_readyup)
		{
			if(isDefined(game["readyup_done"]) && game["readyup_done"]) spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam_AwayfromRadios(spawnpoints);
				else spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
		}
		else spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam_AwayfromRadios(spawnpoints);

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["scorelimit"] > 0) self setClientCvar("cg_objectiveText", &"MP_OBJ_TEXT", game["scorelimit"]);
		else self setClientCvar("cg_objectiveText", &"MP_OBJ_TEXT_NOSCORE");

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
		if(!isPlayer(player)) continue;
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

	if(getTeamScore("allies") < game["scorelimit"] && getTeamScore("axis") < game["scorelimit"]) return;

	if(level.mapended) return;
	level.mapended = true;

	iprintln(&"MP_SCORE_LIMIT_REACHED");

	level thread endMap();
}

updateGametypeCvars()
{
	while(!level.ex_gameover && !game["matchpaused"])
	{
		timelimit = getCvarFloat("scr_chq_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_chq_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_chq_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

updateTeamStatus()
{
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(players[i])) continue;
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
			level.exist[players[i].pers["team"]]++;
	}
}

hq_setup()
{
	wait( [[level.ex_fpstime]](0.05) );

	maperrors = [];

	if(!isDefined(level.radio))
		level.radio = getentarray("hqradio", "targetname");

	if(level.ex_custom_radios) maps\mp\gametypes\_mapsetup_chq_hq::init();

	if(level.radio.size < 3) maperrors[maperrors.size] = "^1Less than 3 entities found with \"targetname\" \"hqradio\"";

	if(maperrors.size)
	{
		println("^1------------ Map Errors ------------");
		for(i = 0; i < maperrors.size; i++)
			println(maperrors[i]);
		println("^1------------------------------------");

		return;
	}

	setTeamScore("allies", 0);
	setTeamScore("axis", 0);

	for(i = 0; i < level.radio.size; i++)
	{
		level.radio[i] setmodel(game["radio_model"]);
		level.radio[i].team = "none";
		level.radio[i].holdtime_allies = 0;
		level.radio[i].holdtime_axis = 0;
		level.radio[i].hidden = true;
		level.radio[i] hide();

		if((!isDefined(level.radio[i].script_radius)) || (level.radio[i].script_radius <= 0)) level.radio[i].radius = level.radioradius;
			else level.radio[i].radius = level.radio[i].script_radius;

		level thread hq_radio_think(level.radio[i]);
	}

	hq_randomize_radioarray();

	level thread hq_obj_think();
}

hq_randomize_radioarray()
{
	for(i = 0; i < level.radio.size; i++)
	{
		rand = randomint(level.radio.size);
		temp = level.radio[i];
		level.radio[i] = level.radio[rand];
		level.radio[rand] = temp;
	}
}

hq_obj_think(radio)
{
	NeutralRadios = 0;
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == true) continue;
		NeutralRadios++;
	}

	if(NeutralRadios <= 0)
	{
		if(level.nextradio > level.radio.size - 1)
		{
			hq_randomize_radioarray();
			level.nextradio = 0;

			if(isDefined(radio))
			{
				// same radio twice in a row so go to the next radio
				if(radio == level.radio[level.nextradio]) level.nextradio++;
			}
		}

		// find a fake radio position that isn't the last position or the next position
		randAorB = undefined;
		if(level.radio.size >= 4)
		{
			fakeposition = level.radio[randomint(level.radio.size)];
			if(isDefined(level.radio[(level.nextradio - 1)]))
			{
				while((fakeposition == level.radio[level.nextradio]) || (fakeposition == level.radio[level.nextradio - 1]))
					fakeposition = level.radio[randomint(level.radio.size)];
			}
			else
			{
				while(fakeposition == level.radio[level.nextradio])
					fakeposition = level.radio[randomint(level.radio.size)];
			}
			randAorB = randomint(2);

			if(level.ex_hq_radio_compass)
			{
				objective_add(1, "current", fakeposition.origin, game["radio_prespawn"][randAorB]);
				thread maps\mp\gametypes\_objpoints::addObjpoint(fakeposition.origin + (0,0,20), "1", game["radio_prespawn_objpoint"][randAorB]);
			}
		}

		if(!isDefined(randAorB))
			otherAorB = 2; // use original icon since there is only one objective that will show
		else if(randAorB == 1)
			otherAorB = 0;
		else
			otherAorB = 1;

		if(level.ex_hq_radio_compass)
		{
			objective_add(0, "current", level.radio[level.nextradio].origin, game["radio_prespawn"][otherAorB]);
			thread maps\mp\gametypes\_objpoints::addObjpoint(level.radio[level.nextradio].origin + (0,0,20), "0", game["radio_prespawn_objpoint"][otherAorB]);
		}

		wait( [[level.ex_fpstime]](10) );

		level hq_check_teams_exist();
		restartRound = false;

		while((!level.alliesexist) || (!level.axisexist))
		{
			restartRound = true;
			wait( [[level.ex_fpstime]](2) );
			level hq_check_teams_exist();
		}

		if(level.mapended) return;

		if(restartRound) restartRound();
		level.roundStarted = true;

		iprintln(&"MP_RADIOS_SPAWN_IN_SECONDS", level.RadioSpawnDelay);
		wait( [[level.ex_fpstime]](level.RadioSpawnDelay) );

		level.radio[level.nextradio] show();
		level.radio[level.nextradio].hidden = false;

		level thread [[level.ex_psop]]("explo_plant_no_tick");
		objective_add(0, "current", level.radio[level.nextradio].origin, game["radio_prespawn"][2]);

		if(level.ex_hq_radio_compass)
		{
			objective_icon(0, game["radio_none"]);
			objective_delete(1);
		}

		thread maps\mp\gametypes\_objpoints::removeObjpoints();
		thread maps\mp\gametypes\_objpoints::addObjpoint(level.radio[level.nextradio].origin + (0,0,20), "0", "objpoint_radio");

		if((level.captured_radios["allies"] <= 0) && (level.captured_radios["axis"] > 0)) objective_team(0, "allies");		// AXIS HAVE A RADIO AND ALLIES DONT
		else if((level.captured_radios["allies"] > 0) && (level.captured_radios["axis"] <= 0)) objective_team(0, "axis"); // ALLIES HAVE A RADIO AND AXIS DONT
		else objective_team(0, "none"); // NO TEAMS HAVE A RADIO

		level.nextradio++;
	}
}

hq_radio_think(radio)
{
	level endon("intermission");
	while(!level.mapended)
	{
		wait( [[level.ex_fpstime]](0.05) );
		if(!radio.hidden)
		{
			players = level.players;
			radio.allies = 0;
			radio.axis = 0;
			for(i = 0; i < players.size; i++)
			{
				if(!isPlayer(players[i])) continue;
				if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
				{
					if(((distance(players[i].origin, radio.origin)) <= radio.radius) && (distance((0,0,players[i].origin[2]), (0,0,radio.origin[2])) <= level.zradioradius))
					{
						if(players[i].pers["team"] == radio.team) continue;

						if((level.captured_radios[players[i].pers["team"]] > 0) && (radio.team == "none")) continue;

						// player radio icon
						hud_index = players[i] playerHudIndex("hq_radioicon");
						if(hud_index == -1) hud_index = players[i] playerHudCreate("hq_radioicon", 30, 95, 1, (1,1,1), 1, 0, "left", "top", "center", "middle", false, true);
						if(hud_index != -1) players[i] playerHudSetShader(hud_index, "field_radio", 40, 32);

						if((level.captured_radios[players[i].pers["team"]] <= 0) && (radio.team == "none"))
						{
							// player capture 1
							hud_index = players[i] playerHudIndex("hq_capture1");
							if(hud_index == -1) hud_index = players[i] playerHudCreate("hq_capture1", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
							if(hud_index != -1) players[i] playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

							// player capture 2
							hud_index = players[i] playerHudIndex("hq_capture2");
							if(hud_index == -1) hud_index = players[i] playerHudCreate("hq_capture2", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
							if(hud_index != -1)
							{
								if(players[i].pers["team"] == "allies") players[i] playerHudSetShader(hud_index, "white", radio.holdtime_allies, level.progressBarHeight);
									else players[i] playerHudSetShader(hud_index, "white", radio.holdtime_axis, level.progressBarHeight);
							}

							// player capture 3
							hud_index = players[i] playerHudIndex("hq_capture3");
							if(hud_index == -1) hud_index = players[i] playerHudCreate("hq_capture3", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
							if(hud_index != -1) players[i] playerHudSetText(hud_index, &"MP_ESTABLISHING_HQ");

							players[i].esthq = true;
						}
						else if(radio.team != "none")
						{
							// player capture 1
							hud_index = players[i] playerHudIndex("hq_capture1");
							if(hud_index == -1) hud_index = players[i] playerHudCreate("hq_capture1", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
							if(hud_index != -1) players[i] playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

							// player capture 2
							hud_index = players[i] playerHudIndex("hq_capture2");
							if(hud_index == -1) hud_index = players[i] playerHudCreate("hq_capture2", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
							if(hud_index != -1)
							{
								if(players[i].pers["team"] == "allies") players[i] playerHudSetShader(hud_index, "white", level.progressBarWidth - radio.holdtime_allies, level.progressBarHeight);
									else players[i] playerHudSetShader(hud_index, "white", level.progressBarWidth - radio.holdtime_axis, level.progressBarHeight);
							}

							// player capture 3
							hud_index = players[i] playerHudIndex("hq_capture3");
							if(hud_index == -1) hud_index = players[i] playerHudCreate("hq_capture3", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
							if(hud_index != -1) players[i] playerHudSetText(hud_index, &"MP_DESTROYING_HQ");

							players[i].desthq = true;

							if(radio.team == "allies")
							{
								// team neutralize 1
								hud_index = levelHudIndex("hq_axis_neutral1");
								if(hud_index == -1) hud_index = levelHudCreate("hq_axis_neutral1", "allies", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
								if(hud_index != -1) levelHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

								// team neutralize 2
								hud_index = levelHudIndex("hq_axis_neutral2");
								if(hud_index == -1) hud_index = levelHudCreate("hq_axis_neutral2", "allies", level.progressBarWidth / -2, level.progressBarY, 1, (.8,0,0), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
								if(hud_index != -1)
								{
									if(players[i].pers["team"] == "allies") levelHudSetShader(hud_index, "white", level.progressBarWidth - radio.holdtime_allies, level.progressBarHeight);
										else levelHudSetShader(hud_index, "white", level.progressBarWidth - radio.holdtime_axis, level.progressBarHeight);
								}

								// team neutralize 3
								hud_index = levelHudIndex("hq_axis_neutral3");
								if(hud_index == -1) hud_index = levelHudCreate("hq_axis_neutral3", "allies", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
								if(hud_index != -1) levelHudSetText(hud_index, &"MP_LOSING_HQ");
							}
							else if(radio.team == "axis")
							{
								// team neutralize 1
								hud_index = levelHudIndex("hq_allies_neutral1");
								if(hud_index == -1) hud_index = levelHudCreate("hq_allies_neutral1", "axis", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
								if(hud_index != -1) levelHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

								// team neutralize 2
								hud_index = levelHudIndex("hq_allies_neutral2");
								if(hud_index == -1) hud_index = levelHudCreate("hq_allies_neutral2", "axis", level.progressBarWidth / -2, level.progressBarY, 1, (.8,0,0), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
								if(hud_index != -1)
								{
									if(players[i].pers["team"] == "allies") levelHudSetShader(hud_index, "white", level.progressBarWidth - radio.holdtime_allies, level.progressBarHeight);
										else levelHudSetShader(hud_index, "white", level.progressBarWidth - radio.holdtime_axis, level.progressBarHeight);
								}

								// team neutralize 3
								hud_index = levelHudIndex("hq_allies_neutral3");
								if(hud_index == -1) hud_index = levelHudCreate("hq_allies_neutral3", "axis", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
								if(hud_index != -1) levelHudSetText(hud_index, &"MP_LOSING_HQ");
							}
						}

						if(players[i].pers["team"] == "allies") radio.allies++;
							else radio.axis++;

						players[i].inrange = true;
						players[i].isscorer = true;
					}
					else
					{
						players[i] playerHudDestroy("hq_radioicon");
						players[i] playerHudDestroy("hq_capture1");
						players[i] playerHudDestroy("hq_capture2");
						players[i] playerHudDestroy("hq_capture3");

						players[i].inrange = undefined;
					}
				}
			}

			if(radio.team == "none") // Radio is captured if no enemies around
			{
				if((radio.allies > 0) && (radio.axis <= 0) && (radio.team != "allies"))
				{
					radio.holdtime_allies = int(.667 + (radio.holdtime_allies + (radio.allies * level.MultipleCaptureBias)));

					if(radio.holdtime_allies >= level.progressBarWidth)
					{
						if((level.captured_radios["allies"] > 0) && (radio.team != "none")) level hq_radio_capture(radio, "none");
							else if(level.captured_radios["allies"] <= 0) level hq_radio_capture(radio, "allies");
					}
				}
				else if((radio.axis > 0) && (radio.allies <= 0) && (radio.team != "axis"))
				{
					radio.holdtime_axis = int(.667 + (radio.holdtime_axis + (radio.axis * level.MultipleCaptureBias)));

					if(radio.holdtime_axis >= level.progressBarWidth)
					{
						if((level.captured_radios["axis"] > 0) && (radio.team != "none")) level hq_radio_capture(radio, "none");
							else if(level.captured_radios["axis"] <= 0) level hq_radio_capture(radio, "axis");
					}
				}
				else
				{
					radio.holdtime_allies = 0;
					radio.holdtime_axis = 0;

					players = level.players;
					for(i = 0; i < players.size; i++)
					{
						if(!isPlayer(players[i])) continue;
						if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
						{
							if(((distance(players[i].origin,radio.origin)) <= radio.radius) && (distance((0,0,players[i].origin[2]),(0,0,radio.origin[2])) <= level.zradioradius))
							{
								players[i] playerHudDestroy("hq_capture1");
								players[i] playerHudDestroy("hq_capture2");
								players[i] playerHudDestroy("hq_capture3");
							}
						}
					}
				}
			}
			else // Radio should go to neutral first
			{
				if((radio.team == "allies") && (radio.axis <= 0))
				{
					levelHudDestroy("hq_axis_neutral1");
					levelHudDestroy("hq_axis_neutral2");
					levelHudDestroy("hq_axis_neutral3");
				}
				else if((radio.team == "axis") && (radio.allies <= 0))
				{
					levelHudDestroy("hq_allies_neutral1");
					levelHudDestroy("hq_allies_neutral2");
					levelHudDestroy("hq_allies_neutral3");
				}

				if((radio.allies > 0) && (radio.team == "axis"))
				{
					radio.holdtime_allies = int(.667 + (radio.holdtime_allies + (radio.allies * level.MultipleCaptureBias)));
					if(radio.holdtime_allies >= level.progressBarWidth) level hq_radio_capture(radio, "none");
				}
				else if((radio.axis > 0) && (radio.team == "allies"))
				{
					radio.holdtime_axis = int(.667 + (radio.holdtime_axis + (radio.axis * level.MultipleCaptureBias)));
					if(radio.holdtime_axis >= level.progressBarWidth) level hq_radio_capture(radio, "none");
				}
				else
				{
					radio.holdtime_allies = 0;
					radio.holdtime_axis = 0;
				}
			}
		}
	}
}

hq_radio_capture(radio, team)
{
	radio.holdtime_allies = 0;
	radio.holdtime_axis = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(players[i])) continue;
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
		{
			players[i] playerHudDestroy("hq_radioicon");
			players[i] playerHudDestroy("hq_capture1");
			players[i] playerHudDestroy("hq_capture2");
			players[i] playerHudDestroy("hq_capture3");

			// dish out some player scores
			if(isDefined(players[i].isscorer))
			{
				if(!level.ex_hqpoints_radius || (distance(players[i].origin, radio.origin) <= level.ex_hqpoints_radius))
				{
					if(isDefined(players[i].esthq))
					{
						lpselfnum = players[i] getEntityNumber();
						lpselfguid = players[i] getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + players[i].pers["team"] + ";" + players[i].name + ";" + "hq_establish" + "\n");

						players[i] thread [[level.pscoreproc]](level.ex_hqpoints_playercap, "special");
					}
					else if(isDefined(players[i].desthq))
					{
						lpselfnum = players[i] getEntityNumber();
						lpselfguid = players[i] getGuid();
						logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + players[i].pers["team"] + ";" + players[i].name + ";" + "hq_destroy" + "\n");

						players[i] thread [[level.pscoreproc]](level.ex_hqpoints_playerneut, "special");
					}
				}

				players[i].esthq = undefined;
				players[i].desthq = undefined;
				players[i].isscorer = undefined;
			}
		}
	}

	if(radio.team != "none")
	{
		level.captured_radios[radio.team] = 0;
		playfx(level._effect["radioexplosion"], radio.origin);
		level.timesCaptured = 0;

		if(radio.team == "allies")
		{
			if(getTeamCount("axis")) iprintln(&"MP_SHUTDOWN_ALLIED_HQ");

			levelHudDestroy("hq_axis_neutral1");
			levelHudDestroy("hq_axis_neutral2");
			levelHudDestroy("hq_axis_neutral3");
		}
		else if(radio.team == "axis")
		{
			if(getTeamCount("allies")) iprintln(&"MP_SHUTDOWN_AXIS_HQ");

			levelHudDestroy("hq_allies_neutral1");
			levelHudDestroy("hq_allies_neutral2");
			levelHudDestroy("hq_allies_neutral3");
		}
	}

	if(radio.team == "none") radio playsound("explo_plant_no_tick");

	NeutralizingTeam = undefined;
	if(radio.team == "allies") NeutralizingTeam = "axis";
		else if(radio.team == "axis") NeutralizingTeam = "allies";

	radio.team = team;

	level notify("Radio State Changed");

	if(team == "none")
	{
		// RADIO GOES NEUTRAL
		radio setmodel(game["radio_model"]);
		radio hide();
		radio.hidden = true;

		radio playsound("explo_radio");
		if(isDefined(NeutralizingTeam))
		{
			if(NeutralizingTeam == "allies") level thread [[level.ex_psop]]("mp_announcer_axishqdest");
				else if(NeutralizingTeam == "axis") level thread [[level.ex_psop]]("mp_announcer_alliedhqdest");
		}

		objective_delete(0);
		thread maps\mp\gametypes\_objpoints::removeObjpoints();
		level.DefendingRadioTeam = "none";
		level notify("Radio Neutralized");

		// give some points to the neutralizing team
		if(isDefined(NeutralizingTeam))
		{
			if((NeutralizingTeam == "allies") || (NeutralizingTeam == "axis"))
			{
				if(getTeamCount(NeutralizingTeam))
				{
					if(NeutralizingTeam == "allies") iprintln(&"MP_SCORED_ALLIES", level.NeutralizingPoints);
						else iprintln(&"MP_SCORED_AXIS", level.NeutralizingPoints);

					thread [[level.tscoreproc]](NeutralizingTeam, level.NeutralizingPoints);
				}
			}
		}

		// give all the players that are alive full health
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(!isPlayer(players[i])) continue;
			if(isDefined(players[i].pers["team"]) && players[i].sessionstate == "playing")
			{
				if(!isDefined(players[i].maxhealth)) players[i].maxhealth = level.ex_player_maxhealth;
				players[i].health = players[i].maxhealth;
			}
		}

		level thread removeHudElements();
	}
	else
	{
		// RADIO CAPTURED BY A TEAM
		level.captured_radios[team] = 1;
		level.DefendingRadioTeam = team;

		if(team == "allies")
		{
			iprintln(&"MP_SETUP_HQ_ALLIED");

			if(game["allies"] == "british") alliedsound = "UK_mp_hqsetup";
				else if(game["allies"] == "russian") alliedsound = "RU_mp_hqsetup";
					else alliedsound = "US_mp_hqsetup";

			level thread [[level.ex_psop]](alliedsound, "allies");
			level thread [[level.ex_psop]]("GE_mp_enemyhqsetup", "axis");
		}
		else
		{
			iprintln(&"MP_SETUP_HQ_AXIS");

			if(game["allies"] == "british") alliedsound = "UK_mp_enemyhqsetup";
				else if(game["allies"] == "russian") alliedsound = "RU_mp_enemyhqsetup";
					else alliedsound = "US_mp_enemyhqsetup";

			level thread [[level.ex_psop]]("GE_mp_hqsetup", "axis");
			level thread [[level.ex_psop]](alliedsound, "allies");
		}

		// give some points to the capturing team
		if(isDefined(level.DefendingRadioTeam))
		{
			if((level.DefendingRadioTeam == "allies") || (level.DefendingRadioTeam == "axis"))
			{
				if(getTeamCount(level.DefendingRadioTeam))
					thread [[level.tscoreproc]](level.DefendingRadioTeam, level.ex_hqpoints_teamcap);
			}
		}

		// give all the alive players that are now defending the radio full health
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(!isPlayer(players[i])) continue;
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == level.DefendingRadioTeam && players[i].sessionstate == "playing")
			{
				if(!isDefined(players[i].maxhealth)) players[i].maxhealth = level.ex_player_maxhealth;
				players[i].health = players[i].maxhealth;
			}
		}

		level thread hq_maxholdtime_think();
	}

	objective_icon(0, (game["radio_" + team ]));
	objective_team(0, "none");

	objteam = "none";
	if((level.captured_radios["allies"] <= 0) && (level.captured_radios["axis"] > 0)) objteam = "allies";
		else if((level.captured_radios["allies"] > 0) && (level.captured_radios["axis"] <= 0)) objteam = "axis";

	// Make all neutral radio objectives go to the right team
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == true) continue;
		if(level.radio[i].team == "none") objective_team(0, objteam);
	}

	level thread hq_obj_think(radio);
}

hq_maxholdtime_think()
{
	level endon("Radio State Changed");
	assert(level.RadioMaxHoldSeconds > 2);
	if(level.RadioMaxHoldSeconds > 0) wait( [[level.ex_fpstime]](level.RadioMaxHoldSeconds - 0.05) );
	level thread hq_radio_resetall();
}

hq_points()
{
	while(!level.mapended)
	{
		if(level.DefendingRadioTeam != "none")
		{
			if(getTeamCount(level.DefendingRadioTeam))
				thread [[level.tscoreproc]](level.DefendingRadioTeam, level.ex_hqpoints_defpps);
		}
		wait( [[level.ex_fpstime]](1) );
	}
}

hq_radio_resetall()
{
	// Find the radio that is in play
	radio = undefined;
	for(i = 0; i < level.radio.size; i++)
	{
		if(level.radio[i].hidden == false)
			radio = level.radio[i];
	}

	if(!isDefined(radio)) return;

	radio.holdtime_allies = 0;
	radio.holdtime_axis = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(players[i])) continue;
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
		{
			players[i] playerHudDestroy("hq_radioicon");
			players[i] playerHudDestroy("hq_capture1");
			players[i] playerHudDestroy("hq_capture2");
			players[i] playerHudDestroy("hq_capture3");
		}
	}

	if(radio.team != "none")
	{
		level.captured_radios[radio.team] = 0;

		playfx(level._effect["radioexplosion"], radio.origin);
		level.timesCaptured = 0;

		localizedTeam = undefined;
		if(radio.team == "allies")
		{
			localizedTeam = (&"MP_UPTEAM");
			levelHudDestroy("hq_axis_neutral1");
			levelHudDestroy("hq_axis_neutral2");
			levelHudDestroy("hq_axis_neutral3");
		}
		else if(radio.team == "axis")
		{
			localizedTeam = (&"MP_DOWNTEAM");
			levelHudDestroy("hq_allies_neutral1");
			levelHudDestroy("hq_allies_neutral2");
			levelHudDestroy("hq_allies_neutral3");
		}

		minutes = 0;
		maxTime = level.RadioMaxHoldSeconds;
		while(maxTime >= 60)
		{
			minutes++;
			maxTime -= 60;
		}
		seconds = maxTime;
		if((minutes > 0) && (seconds > 0)) iprintlnbold(&"MP_MAXHOLDTIME_MINUTESANDSECONDS", localizedTeam, minutes, seconds);
			else if((minutes > 0) && (seconds <= 0)) iprintlnbold(&"MP_MAXHOLDTIME_MINUTES", localizedTeam);
				else if((minutes <= 0) && (seconds > 0)) iprintlnbold(&"MP_MAXHOLDTIME_SECONDS", localizedTeam, seconds);
	}

	radio.team = "none";
	level.DefendingRadioTeam = "none";
	objective_team(0, "none");

	radio setmodel(game["radio_model"]);
	radio hide();

	if(!level.mapended)
	{
		radio playsound("explo_radio");
		level thread [[level.ex_psop]]("mp_announcer_hqdefended");
	}

	radio.hidden = true;
	objective_delete(0);
	thread maps\mp\gametypes\_objpoints::removeObjpoints();

	level thread hq_obj_think(radio);
	level thread removeHudElements();
}

removeHudElements()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(players[i])) continue;
		players[i] playerHudDestroy("hq_radioicon");
		players[i] playerHudDestroy("hq_capture1");
		players[i] playerHudDestroy("hq_capture2");
		players[i] playerHudDestroy("hq_capture3");
	}
}

hq_check_teams_exist()
{
	players = level.players;
	level.alliesexist = false;
	level.axisexist = false;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(players[i])) continue;
		if(!isDefined(players[i].sessionteam) || players[i].sessionteam == "spectator") continue;
		if(players[i].pers["team"] == "allies") level.alliesexist = true;
			else if(players[i].pers["team"] == "axis") level.axisexist = true;

		if(level.alliesexist && level.axisexist) return;
	}
}

restartRound()
{
	if(level.mapended) return;

	if(level.roundStarted)
	{
		iprintlnbold(&"MP_MATCHRESUMING");
		return;
	}
	else if(!level.ex_readyup)
	{
		iprintlnbold(&"MP_MATCHSTARTING");
		wait( [[level.ex_fpstime]](5) );
	}

	if(level.ex_readyup) return;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		if(!isDefined(player.sessionteam) || player.sessionteam == "spectator") continue;

		if(isDefined(player.pers["team"]) && (player.pers["team"] == "allies" || player.pers["team"] == "axis"))
		{
			player.pers["score"] = 0;
			player.score = player.pers["score"];
			player.pers["death"] = 0;
			player.deaths = player.pers["death"];

			// kill running player threads and respawn
			player notify("kill_thread");
			wait(0);
			player spawnPlayer();
		}
	}
}

getTeamCount(team)
{
	count = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && (player.pers["team"] == team))
			count++;
	}

	return count;
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
