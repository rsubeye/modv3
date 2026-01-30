#include extreme\_ex_hudcontroller;

/*------------------------------------------------------------------------------
Domination
AdmiralMOD by Matthias Lorenz, http://www.cod2mod.com
Additions and Standalone Version: La Tuffe (nedgerblansky), Tally, & Oddball
credits: some script in here was originally coded by Pointy
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

	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.compassflag_empty = "gfx/custom/objective_empty.tga";
	
	level.objpointflag_allies = "objpoint_flagpatch1_" + game["allies"];
	level.objpointflag_axis = "objpoint_flagpatch1_" + game["axis"];
	level.objpointflag_empty = "gfx/custom/objpoint_empty.tga";

	level.hudicon_empty = "gfx/custom/headicon_empty.tga";

	//Setup the hud icons and team specific stuff
	switch(game["allies"])
	{
		case "american":
			game["allies_area_secured"] = "US_area_secured";
			game["allies_ground_taken"] = "US_ground_taken";
			game["allies_losing_ground"] = "US_losing_ground";
			break;
		case "british":
			game["allies_area_secured"] = "UK_area_secured";
			game["allies_ground_taken"] = "UK_ground_taken";
			game["allies_losing_ground"] = "UK_losing_ground";
			break;
		default:
			game["allies_area_secured"] = "RU_area_secured";
			game["allies_ground_taken"] = "RU_ground_taken";
			game["allies_losing_ground"] = "RU_losing_ground";
			break;
	}

	game["german_area_secured"] = "GE_area_secured";
	game["german_ground_taken"] = "GE_ground_taken";
	game["german_losing_ground"] = "GE_losing_ground";

	if(!isDefined(game["precachedone"]))
	{
		[[level.ex_PrecacheRumble]]("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("hud_status_dead");
			[[level.ex_PrecacheStatusIcon]]("hud_status_connecting");
		}
		[[level.ex_PrecacheShader]](level.compassflag_empty);
		[[level.ex_PrecacheShader]](level.compassflag_allies);
		[[level.ex_PrecacheShader]](level.compassflag_axis);
		[[level.ex_PrecacheShader]](level.objpointflag_allies);
		[[level.ex_PrecacheShader]](level.objpointflag_axis);
		[[level.ex_PrecacheShader]](level.objpointflag_empty);
		[[level.ex_PrecacheShader]](level.hudicon_empty);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["allies"]);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["axis"]);
		[[level.ex_PrecacheModel]]("xmodel/fahne");
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_base");
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

	// if Spawn Type defined
	if(!isDefined(level.spawntype) || !(isSpawnTypeCorrect(level.spawntype)))
		level.spawntype = "dm";

	level.spawn_allies = getSpawnTypeAllies(level.spawntype);
	level.spawn_axis = getSpawnTypeAxis(level.spawntype);

	setSpawnPoints(level.spawn_allies);
	if(level.spawn_allies != level.spawn_axis) //For "sd" or "ctf"
		setSpawnPoints(level.spawn_axis);

	allowed[0] = "ctf"; // KEEP IT THIS WAY
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;
	level.roundstarted = false;
	level.roundended = false;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["timepassed"])) game["timepassed"] = 0;
	if(!isDefined(game["roundnumber"])) game["roundnumber"] = 0;
	if(!isDefined(game["roundsplayed"])) game["roundsplayed"] = 0;
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

	if(!level.roundended && level.roundstarted)
	{
		if(!isDefined(self.switching_teams) && !self.ex_confirmkill)
		{
			self.pers["death"]++;
			self.deaths = self.pers["death"];
		}
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
			
			// Only handle points if game has started and has not ended
			if(!level.roundended && level.roundstarted)
			{
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
		if(self.pers["team"] == "allies") spawnpointname = level.spawn_allies;
			else spawnpointname = level.spawn_axis;

		spawnpoints = getentarray(spawnpointname, "classname");

		// Find a spawn point away from the flags
		spawnpoint = undefined;
		for(i = 0; i < 5; i ++)
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
			if(spawnpoint IsAwayFromFlags(level.spawndistance)) break;
		}

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"MP_DOM_OBJ_TEXT_NOSCORE");

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
	thread startRound();
}

startRound()
{
	level endon("round_ended");

	game["roundnumber"]++;
	level.roundstarted = true;

	extreme\_ex_gtcommon::createClock(game["roundlength"] * 60);

	wait( [[level.ex_fpstime]](game["roundlength"] * 60) );

	if(level.roundended) return;

	iprintln(&"MP_TIMEHASEXPIRED");

	level thread endRound("draw");
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

	extreme\_ex_main::exEndRound();

	// do endround delay
	wait( [[level.ex_fpstime]](level.cooldowntime) );

	// reset player vars
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(level.ex_ranksystem && level.ex_rank_score == 1) player.pers["rank"] = 0;
		if(level.ex_readyup == 2) player.pers["readyup_spawnticket"] = 1;
	}

	iprintlnbold(&"MP_DOM_START_NEXT_ROUND");
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
		timelimit = getCvarFloat("scr_dom_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_dom_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_dom_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			checkScoreLimit();
		}

		roundlimit = getCvarInt("scr_dom_roundlimit");
		if(game["roundlimit"] != roundlimit)
		{
			game["roundlimit"] = roundlimit;
			setCvar("ui_roundlimit", game["roundlimit"]);

			checkRoundLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

initFlags()
{
	level.hud_dom_pos_y = 15;
	level.flag_radius 	= 80;
	
	if(isDefined(level.flags))
	{
		flags = level.flags;
	}
	else
	{
		flags = [];

		spawnpoints = getentarray("mp_dm_spawn", "classname");

		j = randomInt(spawnpoints.size);

		flags[0] = spawnpoints[j];	
		//logprint("Flag "+flags.size+ " : " + spawnpoints[j].origin + "\n");

		if(level.flagsnumber > 0)
			// Fixed number of flags
			flagsnumber = level.flagsnumber;
		else
		{
			// Variable number of flags, depending on the number of players
			players = level.players;
			flagsnumber = players.size / 2 + 1;
			if(flagsnumber < 2)
				flagsnumber = 2;
			if(flagsnumber > 7)
				flagsnumber = 7;
		}

		trys = 0;

		while(flags.size < flagsnumber) 
		{
			trys++;
			if(trys > 100) break;

			j = randomInt(spawnpoints.size);

			near = false;

			for(i = 0; i < flags.size; i++)
			{
				if(distance(spawnpoints[j].origin,flags[i].origin) < 1000) 
				{
					near = true;
					break;
				}
			}

			if(near == true) continue;

			flags[flags.size] = spawnpoints[j];
		}

		level.flags = flags;
	}

	for(i = 0; i < flags.size; i++)
	{
		flags[i] placeSpawnpoint();

		flags[i].flagmodel = spawn("script_model", flags[i].origin);
		flags[i].flagmodel.angles = flags[i].angles;
		flags[i].flagmodel setmodel("xmodel/fahne");

		flags[i].basemodel = spawn("script_model", flags[i].origin);
		flags[i].basemodel.angles = flags[i].angles;
		flags[i].basemodel setmodel("xmodel/prop_flag_base");

		flags[i].team = "none";
		flags[i].objective = i;
		flags[i].compassflag = level.compassflag_empty;
		flags[i].objpointflag = level.objpointflag_empty;

		flags[i] thread flag();

		hud_index = levelHudCreate("flag_" + flags[i].objective, undefined, 325 + 36 * i - 18 * (flags.size - 1), level.hud_dom_pos_y, 0.8, (1,1,1), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index != -1) levelHudSetShader(hud_index, level.hudicon_empty, 32, 32);
	}	
	
	level.flagscaptured["allies"] = 0;
	level.flagscaptured["axis"] = 0;

	level thread checkWin(level.flags);
}

flagbaseAnimation(team, origin)
{
	if(isDefined(self.fxlooper)) self.fxlooper delete();
	self.fxlooper = playLoopedFx(game["flagbase_anim_" + team], 1.6, origin + (0,0,level.ex_flagbase_anim_height), 0, vectorNormalize((origin + (0,0,100)) - origin));
}

FlagTimeOut()
{
	if(!level.flagtimeout) return;

	if(!level.roundstarted) return;

	// No multiple occurrences allowed otherwise new flag point selection will yield unpredictable results
	while(isDefined(level.FlagTimeOut_running) && level.FlagTimeOut_running)
		wait( [[level.ex_fpstime]](randomint(10) / 10) );

	iprintln(&"MP_DOM_CAPTURE_TIMEOUT", level.flagtimeout);
	iprintln(&"MP_DOM_NEW_FLAG", 5);

	level.FlagTimeOut_running = true;
	self.flagmodel hide();
	self.basemodel hide();
	self deleteFlagWaypoint();
	objective_state(self.objective, "invisible");
	levelHudSetAlpha("flag_" + self.objective, 0);

	spawnpoints = getentarray("mp_dm_spawn", "classname");

	new_point = undefined;
	for(i = 0; i < 100 ; i ++)
	{
		new_point = spawnpoints[randomint(spawnpoints.size)];
		if(new_point IsAwayFromFlags(1000)) break;
	}

	wait( [[level.ex_fpstime]](5) );

	self.origin = new_point.origin;
	self.flagmodel.origin = self.origin;
	self.flagmodel.angles = self.angles;
	self.basemodel.origin = self.origin;
	self.basemodel.angles = self.angles;
	levelHudSetAlpha("flag_" + self.objective, 0.8);
	objective_position(self.objective, self.origin);
	objective_state(self.objective, "current");
	if(level.showflagwaypoints) self createFlagWaypoint();
	self.flagmodel show();
	self.basemodel show();

	switch(self.team)
	{
		case "none":
			if(level.ex_flagbase_anim_neutral) self thread flagbaseAnimation("neutral", self.origin);
			break;
		case "allies":
			if(level.ex_flagbase_anim_allies) self thread flagbaseAnimation("allies", self.origin);
			break;
		case "axis":
			if(level.ex_flagbase_anim_axis) self thread flagbaseAnimation("axis", self.origin);
			break;
	}

	level.FlagTimeOut_running = false;
}

flag()
{
	level endon("ex_gameover");

	objective_add(self.objective, "current", self.origin, self.compassflag);
	if(level.showflagwaypoints) self createFlagWaypoint();
	if(level.ex_flagbase_anim_neutral) self thread flagbaseAnimation("neutral", self.origin);

	for(;;)
	{
		player = WaitForRadius(self.origin, level.flag_radius, 50);

		// no return value for WaitForRadius : time out for the flag
		if(!isDefined(player)) self FlagTimeOut();
		else if(isPlayer(player) && isAlive(player) && (player.pers["team"] != "spectator") && level.roundstarted && !level.roundended)
		{
			// Touched by enemy
			if(player.pers["team"] != self.team)
				self startCaptureProgress(player, player.pers["team"]);

			// Flag is reachable
			self.reachable = true;
		}

		wait( [[level.ex_fpstime]](0.5) );
	}
}

startCaptureProgress(player, team)
{
	helper = spawn("script_model", self.origin);
	helper playloopsound("alt_start_flag_capture");

	origin = self.origin;
	time = 0;
	swatch = 0;

	if(team == "allies") enemyteam = "axis";
		else enemyteam = "allies";

	// Neutralize flag
	if(self.team != "none") 
	{
		time_neutral = int(level.flagcapturetime/2);

		while(isDefined(self) && time < time_neutral)
		{
			player = self checkPlayersInRange(player, team);
			if(level.roundended || !isDefined(player))
			{
				levelHudSetAlpha("flag_" + self.objective, 0.8);

				if(isDefined(helper)) 
				{
					helper stoploopsound();
					helper delete();
				}

				return;
			}

			alpha = 0.8 - ((0.8/time_neutral) * time);
			if(!swatch) levelHudSetAlpha("flag_" + self.objective, 0);
				else levelHudSetAlpha("flag_" + self.objective, alpha);

			swatch = !swatch;

			time++;
			wait( [[level.ex_fpstime]](0.5) );
		}

		level.flagscaptured[enemyteam] --;

		// Show neutral
		self.flagmodel setmodel("xmodel/fahne");
		self.team = "none";
		self.compassflag = level.compassflag_empty;
		self.objpointflag = level.objpointflag_empty;
		objective_icon(self.objective, self.compassflag);
		if(level.ex_flagbase_anim_neutral) self thread flagbaseAnimation("neutral", self.origin);

		levelHudDestroy("flag_" + self.objective);
		hud_index = levelHudCreate("flag_" + self.objective, undefined, 325 + 36 * self.objective - 18 * (level.flags.size - 1), level.hud_dom_pos_y, 0.8, (1,1,1), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index != -1) levelHudSetShader(hud_index, level.hudicon_empty, 32, 32);

		if(level.showflagwaypoints) self createFlagWaypoint();
	}

	// Capture flag
	while(isDefined(self) && time < level.flagcapturetime) 
	{
		player = self checkPlayersInRange(player, team);
		if(level.roundended || !isDefined(player))
		{
			levelHudSetAlpha("flag_" + self.objective, 0.8);
			
			if(isDefined(helper)) 
			{
				helper stoploopsound();
				helper delete();
			}
			
			return;
		}
		
		alpha = 0.8 - ((0.8/level.flagcapturetime) * time);
		if(!swatch) levelHudSetAlpha("flag_" + self.objective, 0);
			else levelHudSetAlpha("flag_" + self.objective, alpha);
		
		swatch = !swatch;
		
		time++;
		wait( [[level.ex_fpstime]](0.5) );
	}
	
	if(isDefined(helper))
	{
		helper stoploopsound();
		helper delete();
	}

	// Finalize capture
	if(isDefined(player)) player GetFlag(self);
}

checkPlayersInRange(player, team)
{
	owner = undefined;
	teammate = undefined;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && players[i].sessionstate == "playing" && isDefined(players[i].pers["team"]))
		{
			if(distance(players[i].origin, self.origin) < level.flag_radius)
			{
				if(players[i].pers["team"] == team)
				{
					if(players[i] == player) owner = players[i];
						else teammate = players[i];
				}
				else return(undefined);
			}
		}
	}

	if(isDefined(owner)) return(owner);
	if(isDefined(teammate)) return(teammate);
	return(undefined);
}

GetFlag(flag)
{
	self endon("disconnect");

	// Give points
	if(level.pointscaptureflag > 0) self thread [[level.pscoreproc]](level.pointscaptureflag, "special");

	level.flagscaptured[self.pers["team"]] ++;
	
	if(self.pers["team"] == "allies") 
	{
		flag.team = "allies";
		
		// Only if not last flag
		if(!checkAllFlagsCaptured()) 
		{
			if(randomInt(2)) level thread [[level.ex_psop]](game["allies_area_secured"], "allies");
				else level thread [[level.ex_psop]](game["allies_ground_taken"], "allies");

			level thread [[level.ex_psop]](game["german_losing_ground"], "axis");
		}
	
		flagModel = "xmodel/prop_flag_" + game["allies"];
		flag.flagmodel setmodel(flagModel);
		
		flag.compassflag = level.compassflag_allies;
		objective_icon(flag.objective, flag.compassflag);
		if(level.ex_flagbase_anim_allies) flag thread flagbaseAnimation("allies", flag.origin);

		if(level.showflagwaypoints) flag.objpointflag = level.objpointflag_allies;

		levelHudDestroy("flag_" + flag.objective);
		hud_index = levelHudCreate("flag_" + flag.objective, undefined, 325 + 36 * flag.objective - 18 * (level.flags.size - 1), level.hud_dom_pos_y, 0.8, (1,1,1), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index != -1) levelHudSetShader(hud_index, game["hudicon_allies"], 32, 32);
	}
	else 
	{
		flag.team = "axis";

		// Only if not last flag
		if(!checkAllFlagsCaptured()) 
		{
			if(randomInt(2)) level thread [[level.ex_psop]](game["german_area_secured"], "axis");
				else level thread [[level.ex_psop]](game["german_ground_taken"], "axis");

			level thread [[level.ex_psop]](game["allies_losing_ground"], "allies");
		}

		flagModel = "xmodel/prop_flag_" + game["axis"];
		flag.flagmodel setmodel(flagModel);
		
		flag.compassflag = level.compassflag_axis;
		objective_icon(flag.objective, flag.compassflag);
		if(level.ex_flagbase_anim_axis) flag thread flagbaseAnimation("axis", flag.origin);

		if(level.showflagwaypoints) flag.objpointflag = level.objpointflag_axis;

		levelHudDestroy("flag_" + flag.objective);
		hud_index = levelHudCreate("flag_" + flag.objective, undefined, 325 + 36 * flag.objective - 18 * (level.flags.size - 1), level.hud_dom_pos_y, 0.8, (1,1,1), 1, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index != -1) levelHudSetShader(hud_index, game["hudicon_axis"], 32, 32);
	}

	self.dont_auto_balance = true;
	if(level.showflagwaypoints) flag createFlagWaypoint();
}

createFlagWaypoint()
{
	self deleteFlagWaypoint();

	hud_index = levelHudCreate("waypoint_flag_" + self.objective, undefined, self.origin[0], self.origin[1], .61, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
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

checkWin(flags) 
{
	level notify("checkWin");
	level endon("checkWin");

	while(isDefined(flags)) 
	{
		if(checkAllFlagsCaptured()) 
		{
			if(flags[0].team == "allies") level thread endRound("allies");
				else level thread endRound("axis");

			break;
		}
		
		wait( [[level.ex_fpstime]](0.5) );
	}
}

checkAllFlagsCaptured() 
{
	flags = level.flags;

	team = flags[0].team;

	if(!isDefined(team)) return false;
	if(team != "axis" && team != "allies") return false;

	if(level.flagscaptured[team] == flags.size) return true;
	return false;
}

printOnTeam(text, team, playername)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text,playername);
	}
}

WaitFlagTimeOut(timeout)
{
	// No more time out for this flag
	if(isDefined(self.reachable)) return;

	wait( [[level.ex_fpstime]](timeout) );

	// If still not reachable, time out !
	if(!isDefined(self.reachable))
		self notify("flag_timeout");
}

WaitForRadius(origin, radius, height) 
{
	self endon("flag_timeout");

	self thread WaitFlagTimeOut(level.flagtimeout);

	if(!isDefined(origin) || !isDefined(radius) || !isDefined(height)) return;

	trigger = spawn("trigger_radius", origin, 0, radius, height);

	while(1) 
	{
		trigger waittill("trigger", player);

		if(isPlayer(player) && player.sessionstate == "playing")
		{
			if(isDefined(trigger)) trigger delete();
			return player;
		}

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(isDefined(trigger)) trigger delete();
}

IsAwayFromFlags(mindist)
{
	if(!isDefined(level.flags)) return true;

	for(i = 0; i < level.flags.size; i ++)
		if(distance(self.origin, level.flags[i].origin) < mindist) return false;
	
	return true;
}

//Added by 0ddball.

getSpawnTypeAllies(spawntype)
{
	switch(spawntype)
	{
		case "dm" :
			spawntype_allies = "mp_dm_spawn";
			break;
		case "tdm" : 
			spawntype_allies = "mp_tdm_spawn";
			break;
		case "sd" :
			spawntype_allies = "mp_sd_spawn_attacker";
			break;
		case "ctf":
			spawntype_allies = "mp_ctf_spawn_allied";
			break;
		default:
			spawntype_allies = "mp_dm_spawn";
		break;
	}
	return spawntype_allies;
}

getSpawnTypeAxis(spawntype)
{
	switch(spawntype)
	{
		case "dm" :
			spawntype_axis = "mp_dm_spawn";
			break;
		case "tdm" :
			spawntype_axis = "mp_tdm_spawn";
			break;
		case "sd" :
			spawntype_axis = "mp_sd_spawn_defender";
			break;
		case "ctf":
			spawntype_axis = "mp_ctf_spawn_axis";
			break;
		default:
			spawntype_axis = "mp_dm_spawn";
		break;
	}
	return spawntype_axis;
}

isSpawnTypeCorrect(spawntype)
{
	switch(spawntype)
	{
		case "dm" :
		case "tdm" : 
		case "sd" :
		case "ctf":
			res = true;
			break;
		default:
			res=false;;
		break;
	}
	return res;
}

setSpawnPoints(spawntype)
{
	spawnpoints = getentarray(spawntype, "classname");
	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}

	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	return spawnpoints;
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
