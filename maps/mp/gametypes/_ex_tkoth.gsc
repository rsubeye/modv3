#include extreme\_ex_hudcontroller;

/*------------------------------------------------------------------------------
	Team King Of The Hill
	Objective: 	Score points for your team by defending and attacking the zone
	Map ends:	When one team reaches the zone time limit, or time limit is reached
	Respawning:	At base or PSP A and PSP B
	PSP's can be taken by you and teammates. You will respawn at these points.
	
	Original GameType by http://www.nlgames.org/ 
	Assistance from Gadjex contremestre@gmail.com
	Converted for eXtreme+ by {PST}*Joker
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

	level.compassflag_allies = "objective";
	level.objpointflag_allies = "objpoint_star";

	if(!isDefined(game["precachedone"]))
	{
		[[level.ex_PrecacheRumble]]("damage_heavy");
		if(!level.ex_rank_statusicons)
		{
			[[level.ex_PrecacheStatusIcon]]("hud_status_dead");
			[[level.ex_PrecacheStatusIcon]]("hud_status_connecting");
		}
		[[level.ex_PrecacheShader]]("objpoint_star");
		[[level.ex_PrecacheShader]]("objpoint_A");
		[[level.ex_PrecacheShader]]("objectiveA");
		[[level.ex_PrecacheShader]]("objpoint_B");
		[[level.ex_PrecacheShader]]("objectiveB");
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["allies"]);
		[[level.ex_PrecacheModel]]("xmodel/prop_flag_" + game["axis"]);
		[[level.ex_PrecacheString]](&"MP_TIME_TILL_SPAWN");
		[[level.ex_PrecacheString]](&"TKOTH_PRESS_TO_SPAWN_AT_YOUR_BASE");
		[[level.ex_PrecacheString]](&"TKOTH_PRESS_TO_SPAWN_AT_PSP_A");
		[[level.ex_PrecacheString]](&"TKOTH_PRESS_TO_SPAWN_AT_PSP_B");
		[[level.ex_PrecacheString]](&"TKOTH_IN_THE_ZONE");
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
	setClientNameMode("auto_change");
	
	// If map is not supported by _mapsetup_tkoth.gsc, it assumes a custom "tkoth" map.
	if(!isDefined(level.spawn))
	{
		level.spawn = "tkoth";
		spawnpointname = "mp_tkoth_spawn_allied";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint();

		spawnpointname = "mp_tkoth_spawn_axis";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] PlaceSpawnpoint();
	}
		
	if(level.spawn == "sd")
	{
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
	}
	else if(level.spawn == "ctf")
	{
		spawnpointname = "mp_ctf_spawn_allied";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] placeSpawnpoint();

		spawnpointname = "mp_ctf_spawn_axis";
		spawnpoints = getentarray(spawnpointname, "classname");

		if(!spawnpoints.size)
		{
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			return;
		}

		for(i = 0; i < spawnpoints.size; i++)
			spawnpoints[i] PlaceSpawnpoint();
	}
	
	allowed[0] = "tkoth";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.mapended = false;
	level.alliestimepassed = 0;
	level.axistimepassed = 0;
	level.oldalliestimepassed = 0;
	level.oldaxistimepassed = 0;
	level.pspaTeam = "";
	level.pspbTeam = "";
	level.pspplyaTeam = 0;
	level.pspplybTeam = 0;

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

	tkotk_zone = getent("tkotk_zone", "targetname");

	level.zz = self.origin[2];
	level.selfzone = ((level.x),(level.y),(level.zz));

	level.zza = attacker.origin[2];
	level.attackerzone = ((level.x),(level.y),(level.zza));

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

	if(isDefined(tkotk_zone) && isDefined(tkotk_zone.radius))
	{
		if((distance(self.origin,level.selfzone)) <= tkotk_zone.radius && (distance(attacker.origin,level.attackerzone)) >= tkotk_zone.radius && attacker != self)
		{
			logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + "tkoth_zone_attack" + "\n");
		}
		else if((distance(self.origin,level.selfzone)) <= tkotk_zone.radius && (distance(attacker.origin,level.attackerzone)) <= tkotk_zone.radius && attacker != self && lpattackteam == level.zoneteam)
		{
			logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + "tkoth_zone_defend" + "\n");
		}
		else if((distance(self.origin,level.selfzone)) <= tkotk_zone.radius && (distance(attacker.origin,level.attackerzone)) <= tkotk_zone.radius && attacker != self && lpattackteam != level.zoneteam)
		{
			logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + "tkoth_zone_attack" + "\n");
		}
		else if((distance(self.origin,level.selfzone)) >= tkotk_zone.radius && (distance(attacker.origin,level.attackerzone)) <= tkotk_zone.radius && attacker != self)
		{
			logPrint("A;" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + "tkoth_zone_defend" + "\n");
		}
	}

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
		if(level.spawn == "sd")
		{
			if(self.pers["team"] == "allies") spawnpointname = "mp_sd_spawn_attacker";
				else spawnpointname = "mp_sd_spawn_defender";
		}
		else if(level.spawn == "ctf")
		{
			if(self.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_allied";
				else spawnpointname = "mp_ctf_spawn_axis";
		}
		else
		{
			if(self.pers["team"] == "allies") spawnpointname = "mp_tkoth_spawn_allied";
				else spawnpointname = "mp_tkoth_spawn_axis";
		}

		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"TKOTH_OBJ_TEXT", level.zonetimelimit);
		
	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");
}

spawnPlayerA()
{
	self endon("disconnect");

	if((!isDefined(self.pers["weapon"])) || (!isDefined(self.pers["team"]))) return;

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

	psp_A = getent("psp_a", "targetname");

	self extreme\_ex_main::exPreSpawn();

	if(isDefined(psp_A) && level.pspaTeam == self.pers["team"])
	{
		self spawn(((psp_A.origin[0]-32),(psp_A.origin[1]-32),(psp_A.origin[2]+16)), psp_A.angles);
	}
	else
	{
		if(level.spawn == "sd")
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_sd_spawn_attacker";
			else
				spawnpointname = "mp_sd_spawn_defender";
		}
		else if(level.spawn == "ctf")
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_ctf_spawn_allied";
			else
				spawnpointname = "mp_ctf_spawn_axis";
		}
		else
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_tkoth_spawn_allied";
			else
				spawnpointname = "mp_tkoth_spawn_axis";
		}

		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"TKOTH_OBJ_TEXT", level.zonetimelimit);

	self thread updateTimer();

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");
}

spawnPlayerB()
{ 
	self endon("disconnect");

	if((!isDefined(self.pers["weapon"])) || (!isDefined(self.pers["team"]))) return;

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

	psp_B = getent("psp_b", "targetname");

	self extreme\_ex_main::exPreSpawn();

	if(isDefined(psp_B) && level.pspbTeam == self.pers["team"])
	{
		self spawn(((psp_B.origin[0]-32),(psp_B.origin[1]-32),(psp_B.origin[2]+16)), psp_B.angles);
	}
	else
	{
		if(level.spawn == "sd")
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_sd_spawn_attacker";
			else
				spawnpointname = "mp_sd_spawn_defender";
		}
		else if(level.spawn == "ctf")
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_ctf_spawn_allied";
			else
				spawnpointname = "mp_ctf_spawn_axis";
		}
		else
		{
			if(self.pers["team"] == "allies")
				spawnpointname = "mp_tkoth_spawn_allied";
			else
				spawnpointname = "mp_tkoth_spawn_axis";
		}

		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

		if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
		else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"TKOTH_OBJ_TEXT", level.zonetimelimit);

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

	self thread waitRespawnButton();
	self waittill("respawn");

	if(self.pers["psppoint"] == "base")
		self thread spawnPlayer();

	if(self.pers["psppoint"] == "pspapoint")
		self thread spawnPlayerA();

	if(self.pers["psppoint"] == "pspbpoint")
		self thread spawnPlayerB();
}

startGame()
{
	level.zonepointtime = getTime();

	if(game["timelimit"] > 0) extreme\_ex_gtcommon::createClock(game["timelimit"] * 60);

	SetupHUD();

	while(!level.ex_gameover)
	{
		checkTimeLimit();
		wait( [[level.ex_fpstime]](1) );
	}
}

endMap()
{
	removeHUD();

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
		timelimit = getCvarFloat("scr_tkoth_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_tkoth_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_tkoth_scorelimit");
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
	level.tkothZone = getent("tkothZone", "targetname");
	if(!isDefined(level.tkothZone))
	{
		// Spawn a script origin
		level.flag = spawn("script_model",((level.x),(level.y),(level.z)));
		level.flag.targetname = "tkotk_zone";
		level.flag.origin = ((level.x),(level.y),(level.z));
		level.flag.angles = (0,0,0);
		level.flag.home_origin = ((level.x),(level.y),(level.z));
		level.flag.home_angles = (0,0,0);
		level.flag.radius = level.radius;

		// Spawn the flag base model
		level.flag.basemodel = spawn("script_model", ((level.x),(level.y),(level.z)));
		level.flag.basemodel.angles = (0,0,0);
		level.flag.basemodel setmodel("xmodel/prop_flag_base");

		// Spawn the flag
		level.flag.flagmodel = spawn("script_model", ((level.x),(level.y),(level.z)));
		level.flag.flagmodel.angles = (0,0,0);
		level.flag.flagmodel setmodel("xmodel/prop_flag_german");
		level.flag.flagmodel hide();

		// Set flag properties
		level.flag.team = "allies";
		level.flag.atbase = true;
		level.flag.stolen = false;
		level.flag.objective = 0;
		level.flag.compassflag = level.compassflag_allies;
		level.flag.objpointflag = level.objpointflag_allies;

		level.zone = false;
		level.zoneteam = "";
		level.zonetimerax = false;
		level.zonetimeral = false;

		level.pspateam = "";
		level.pspaattempt = "";

		level.pspbteam = "";
		level.pspbattempt = "";

		level.flag thread flag();
	}
	else
	{
		// Spawn a script origin
		level.flag = spawn("script_model",level.tkothZone.origin);
		level.flag.targetname = "tkotk_zone";
		level.flag.origin = (level.tkothZone.origin);
		level.flag.angles = (0,0,0);
		level.flag.home_origin = level.tkothZone.origin;
		level.flag.home_angles = (0,0,0);
		level.flag.radius = level.tkothZone.radius;

		psp_A = getent("psp_a", "targetname");
		if(isDefined(psp_A))
		{
			level.pspaflag = spawn("script_model",psp_A.origin);
			level.pspaflag.targetname = "pspa_flag";
			level.pspaflag.flagmodel = spawn("script_model", (psp_A.origin[0],psp_A.origin[1],(psp_A.origin[2]+64)));
			level.pspaflag.flagmodel.angles = (psp_A.angles);
			level.pspaflag.flagmodel setmodel("xmodel/prop_flag_german");
			level.pspaflag.objective = 1;
			level.pspaflag.flagmodel hide();

			objective_add(1, "current", psp_A.origin, "objectiveA");
			thread maps\mp\gametypes\_objpoints::addObjpoint(psp_A.origin, "1","objpoint_A");
		}

		psp_B = getent("psp_b", "targetname");
		if(isDefined(psp_B))
		{
			level.pspbflag = spawn("script_model",psp_B.origin);
			level.pspbflag.targetname = "pspb_flag";
			level.pspbflag.flagmodel = spawn("script_model", (psp_B.origin[0],psp_B.origin[1],(psp_B.origin[2]+64)));
			level.pspbflag.flagmodel.angles = (psp_B.angles);
			level.pspbflag.flagmodel setmodel("xmodel/prop_flag_german");
			level.pspbflag.objective = 2;
			level.pspbflag.flagmodel hide();
	
			objective_add(2, "current", psp_B.origin, "objectiveB");
			thread maps\mp\gametypes\_objpoints::addObjpoint(psp_B.origin, "2","objpoint_B");
		}

		// Spawn the flag base model
		level.flag.basemodel = spawn("script_model", level.tkothZone.origin);
		level.flag.basemodel.angles = (0,0,0);
		level.flag.basemodel setmodel("xmodel/prop_flag_base");

		// Spawn the flag
		level.flag.flagmodel = spawn("script_model", level.tkothZone.origin);
		level.flag.flagmodel.angles = (0,0,0);
		level.flag.flagmodel setmodel("xmodel/prop_flag_german");
		level.flag.flagmodel hide();

		// Set flag properties
		level.flag.team = "allies";
		//level.flag.atbase = true;
		//level.flag.stolen = false;
		level.flag.objective = 0;
		level.flag.compassflag = level.compassflag_allies;
		level.flag.objpointflag = level.objpointflag_allies;

		level.x = level.tkothZone.origin[0];
		level.y = level.tkothZone.origin[1];
		level.z = level.tkothZone.origin[2];

		level.zone = false;
		level.zoneteam = "";
		level.zonetimerax = false;
		level.zonetimeral = false;

		level.pspateam = "";
		level.pspaattempt = "";

		level.pspbteam = "";
		level.pspbattempt = "";

		level.flag thread flag();
	}
}

flag()
{
	objective_add(self.objective, "current", self.origin, self.compassflag);
	tkotk_zone = getent("tkotk_zone", "targetname");
	level.tkothZone = getent("tkothZone", "targetname");
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			//coordinates print;
			if(level.debug == 1)
				iprintln(players[i].origin);

			if(!isDefined(level.tkothZone))
			{
				level.zzz = players[i].origin[2];
				tkotk_zone.origin = ((level.x),(level.y),(level.zzz));
			}
			else
			{
				level.x = level.tkothZone.origin[0];
				level.y = level.tkothZone.origin[1];
				level.zzz = players[i].origin[2];
				tkotk_zone.origin = ((level.x),(level.y),(level.zzz));
			}

			if(level.zone == false && level.mapended == false)
			{
				if((distance(players[i].origin,tkotk_zone.origin)) <= tkotk_zone.radius)
				{
					if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing")
					{
						println("CAPTURED THE ZONE");

						//level thread [[level.ex_psop]]("ctf_enemy_touchenemy");

						if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "allies")
						{
							iprintln(&"TKOTH_ALLIES_CAPTURED_ZONE");
							level.zone = true;
							level.zoneteam = "allies";
							tkotk_zone.flagmodel show();
							tkotk_zone.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);

							thread [[level.tscoreproc]]("allies", level.zonepoints_capture);

							thread Zone();
						}
						else
						{
							iprintln(&"TKOTH_AXIS_CAPTURED_ZONE");
							level.zone = true;
							level.zoneteam = "axis";
							tkotk_zone.flagmodel show();
							tkotk_zone.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);

							thread [[level.tscoreproc]]("axis", level.zonepoints_capture);

							thread Zone();
						}
					}
				}
			}
		}
	}

	wait( [[level.ex_fpstime]](0.2) );
	
	psp_A = getent("psp_a", "targetname");

	if(isDefined(psp_A))
		thread pspA();

	psp_B = getent("psp_b", "targetname");

	if(isDefined(psp_B))
		thread pspB();

	thread Flag();
}

Zone()
{
	tkotk_zone = getent("tkotk_zone", "targetname");
	level.tkothZone = getent("tkothZone", "targetname");

	level.zonepointtimepassed = (getTime() - level.zonepointtime) / 1000;

	allies_alive = 0;
	axis_alive = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isDefined(level.tkothZone))
		{
			level.zz = players[i].origin[2];
			tkotk_zone.origin = ((level.x),(level.y),(level.zz));
		}
		else
		{
			level.x = level.tkothZone.origin[0];
			level.y = level.tkothZone.origin[1];
			level.zz = players[i].origin[2];
			tkotk_zone.origin = ((level.x),(level.y),(level.zz));
		}

		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing" && (distance(players[i].origin,tkotk_zone.origin)) <= tkotk_zone.radius)
		{
			if(level.zonepointtimepassed >= 10)
			{
				lpselfnum = players[i] getEntityNumber();
				lpselfguid = players[i] getGuid();
				if(players.size >= 2) logPrint("A;" + lpselfguid + ";" + lpselfnum + ";" + players[i].pers["team"] + ";" + players[i].name + ";" + "tkoth_zone" + "\n");

				players[i] thread [[level.pscoreproc]](1);
			}

			if(distance(players[i].origin,tkotk_zone.origin) <= tkotk_zone.radius)
			{
				hud_index = players[i] playerHudIndex("tkoth_zoneline");
				if(hud_index == -1)
				{
					hud_index = players[i] playerHudCreate("tkoth_zoneline", 320, 25, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
					if(hud_index == -1) return;
					players[i] playerHudSetText(hud_index, &"TKOTH_IN_THE_ZONE");
				}
			}

			if(players[i].pers["team"] == "allies") allies_alive++;
				else if(players[i].pers["team"] == "axis") axis_alive++;

			levelHudSetValue("tkoth_axisinzone", axis_alive);
			if(axis_alive > 0) thread zonetimerAxis();

			levelHudSetValue("tkoth_alliesinzone", allies_alive);
			if(allies_alive > 0) thread zonetimerAllies();
		}
		else players[i] playerHudDestroy("tkoth_zoneline");
	}

	if(level.zoneteam == "axis" && axis_alive > 0 && allies_alive <= 0)
	{
		level.alliestimepassed = 0;
		level.zonetimeral = false;
		updateHUD();
	}

	if(level.zoneteam == "allies" && axis_alive <= 0 && allies_alive > 0)
	{
		level.axistimepassed = 0;
		level.zonetimerax = false;
		updateHUD();
	}

	if(level.zoneteam == "axis" && axis_alive <= 0 && allies_alive <= 0 && level.mapended == false)
	{
		iprintln(&"TKOTH_AXIS_LOST_ZONE");
		tkotk_zone.flagmodel hide();

		levelHudSetValue("tkoth_axisinzone", axis_alive);

		level.zone = false;
		level.zoneteam = "";

		level.axistimepassed = 0;
		level.zonetimerax = false;
		updateHUD();
	}

	if(level.zoneteam == "axis" && axis_alive <= 0 && allies_alive >= 0 && level.mapended == false)
	{
		iprintln(&"TKOTH_ALLIES_TAKENOVER_ZONE");
		tkotk_zone.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
		level.zone = true;
		level.zoneteam = "allies";

		level.axistimepassed = 0;
		level.zonetimerax = false;
		updateHUD();

		thread zonetimerAllies();

		thread [[level.tscoreproc]]("allies", level.zonepoints_takeover);
	}

	if(level.zoneteam == "allies" && axis_alive <= 0 && allies_alive <= 0 && level.mapended == false)
	{
		iprintln(&"TKOTH_ALLIES_LOST_ZONE");
		tkotk_zone.flagmodel hide();

		levelHudSetValue("tkoth_alliesinzone", allies_alive);

		level.zone = false;
		level.zoneteam = "";

		level.alliestimepassed = 0;
		level.zonetimeral = false;
		updateHUD();
	}

	if(level.zoneteam == "allies" && axis_alive >= 0 && allies_alive <= 0 && level.mapended == false)
	{
		iprintln(&"TKOTH_AXIS_TAKENOVER_ZONE");
		tkotk_zone.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
		level.zone = true;
		level.zoneteam = "axis";

		level.alliestimepassed = 0;
		level.zonetimeral = false;
		updateHUD();

		thread zonetimerAxis();

		thread [[level.tscoreproc]]("axis", level.zonepoints_takeover);
	}

	if(level.zonepointtimepassed >= 10) level.zonepointtime = getTime();

	wait( [[level.ex_fpstime]](0.2) );

	psp_A = getent("psp_a", "targetname");
	psp_B = getent("psp_b", "targetname");

	if(isDefined(psp_A)) thread pspA();
	if(isDefined(psp_B)) thread pspB();
	thread Zone();
}

zonetimerAxis()
{
	if(level.zonetimerax == true)
	{
		thread zoneLimitAxis();
		return;
	}
	else
	{
		level.zonetimerax = true;
		level.startaxis = getTime();
	}
}

zonetimerAllies()
{
	if(level.zonetimeral == true)
	{
		thread zoneLimitAllies();
		return;
	}
	else
	{
		level.zonetimeral = true;
		level.startallies = getTime();
	}
}

zoneLimitAxis()
{
	axistimepassed = (getTime() - level.startaxis) / 1000;
	level.axistimepassed = int(axistimepassed);
	thread updateHUD();

	if(level.axistimepassed < (level.zonetimelimit * 60)) return;

	level.alliestimepassed = 0;
	level.zonetimeral = false;
	level.axistimepassed = 0;
	level.zonetimerax = false;
	updateHUD();

	thread [[level.tscoreproc]]("axis", level.zonepoints_holdmax);
}

zoneLimitAllies()
{
	alliestimepassed = (getTime() - level.startallies) / 1000;
	level.alliestimepassed = int(alliestimepassed);
	thread updateHUD();

	if(level.alliestimepassed < (level.zonetimelimit * 60)) return;

	level.alliestimepassed = 0;
	level.zonetimeral = false;
	level.axistimepassed = 0;
	level.zonetimerax = false;
	updateHUD();

	thread [[level.tscoreproc]]("allies", level.zonepoints_holdmax);
}

pspA()
{
	psp_A = getent("psp_a", "targetname");
	level.playerpspa = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing" && (distance(players[i].origin,psp_A.origin)) <= psp_A.radius)
		{
			level.playerpspa++;

			if((players[i].pers["team"]) != level.pspaAttempt && (players[i].pers["team"]) != level.pspaTeam && level.pspplyaTeam <= 0)
			{
				level.pspplyaTeam = 1;
				levelHudDestroy("tkoth_pspa_timerback");
				levelHudDestroy("tkoth_pspa_timer");

				level.pspaAttempt = (players[i].pers["team"]);

				level.lpselfnuma = players[i] getEntityNumber();
				level.lpselfguida = players[i] getGuid();
				level.lpselfnamea = players[i].name;
				level.lpselfteama = players[i].pers["team"];
				//if(players.size >= 2)
				logPrint("A;" + level.lpselfguida + ";" + level.lpselfnuma + ";" + level.lpselfteama + ";" + level.lpselfnamea + ";" + "psp_attempt" + "\n");

				level thread pspaAttempt();
			}
		}
	}

	if(level.playerpspa <= 0) level.pspplyaTeam = 0;
	if(level.pspaAttempt!= "") level thread pspaTimecheck();
}

pspB()
{
	psp_B = getent("psp_b", "targetname");
	level.playerpspb = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isDefined(players[i].pers["team"]) && players[i].pers["team"] != "spectator" && players[i].sessionstate == "playing" && (distance(players[i].origin,psp_B.origin)) <= psp_B.radius)
		{
			level.playerpspb++;

			if((players[i].pers["team"]) != level.pspbAttempt && (players[i].pers["team"]) != level.pspbTeam && level.pspplybTeam <= 0)
			{
				level.pspplybTeam = 1;
				levelHudDestroy("tkoth_pspb_timerback");
				levelHudDestroy("tkoth_pspb_timer");

				level.pspbAttempt = (players[i].pers["team"]);

				level.lpselfnumb = players[i] getEntityNumber();
				level.lpselfguidb = players[i] getGuid();
				level.lpselfnameb = players[i].name;
				level.lpselfteamb = players[i].pers["team"];
				logPrint("A;" + level.lpselfguidb + ";" + level.lpselfnumb + ";" + level.lpselfteamb + ";" + level.lpselfnameb + ";" + "psp_attempt" + "\n");

				level thread pspbAttempt();
			}
		}
	}

	if(level.playerpspb <= 0) level.pspplybTeam = 0;
	if(level.pspbAttempt != "") level thread pspbTimecheck();
}

pspaAttempt()
{
	if(level.pspaAttempt == "allies") iprintln(&"TKOTH_ALLIES_TRY_TO_TAKE_PSP_A");
		else iprintln(&"TKOTH_AXIS_TRY_TO_TAKE_PSP_A");

	level thread [[level.ex_psop]]("tkoth_psp");

	pspa_flag = getent("pspa_flag", "targetname");
	level.pspaTeam = "";
	pspa_flag.flagmodel hide();

	hud_index = levelHudCreate("tkoth_pspa_timerback", undefined, 0, 104, .5, (0.2,0.2,0.2), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 102, 11);

	hud_index = levelHudCreate("tkoth_pspa_timer", undefined, (102 / -2) + 2, 104, .8, undefined, 1, 1, "center_safearea", "center_safearea", "left", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 0, 9);
	levelHudScale(hud_index, 10, 0, 100, 9);

	level.pspastarttime = getTime();
}

pspbAttempt()
{
	if(level.pspbAttempt == "allies") iprintln(&"TKOTH_ALLIES_TRY_TO_TAKE_PSP_B");
		else iprintln(&"TKOTH_AXIS_TRY_TO_TAKE_PSP_B");

	level thread [[level.ex_psop]]("tkoth_psp");

	pspb_flag = getent("pspb_flag", "targetname");
	level.pspbTeam = "";
	pspb_flag.flagmodel hide();

	hud_index = levelHudCreate("tkoth_pspb_timerback", undefined, 0, 120, .5, (0.2,0.2,0.2), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 102, 11);

	hud_index = levelHudCreate("tkoth_pspb_timer", undefined, (102 / -2) + 2, 120, .8, undefined, 1, 1, "center_safearea", "center_safearea", "left", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 0, 9);
	levelHudScale(hud_index, 10, 0, 100, 9);

	level.pspbstarttime = getTime();
}

pspaTimecheck()
{
	pspa_flag = getent("pspa_flag", "targetname");
	pspatimepassed = (getTime() - level.pspastarttime ) / 1000;

	if(pspatimepassed >= 10)
	{
		levelHudDestroy("tkoth_pspa_timerback");
		levelHudDestroy("tkoth_pspa_timer");
		level.pspaTeam = level.pspaAttempt;
		level.pspaAttempt = "";
		if(level.pspaTeam == "allies")
		{
			iprintln(&"TKOTH_ALLIES_TAKEOVER_PSP_A");
			updateStatusA(level.pspaTeam);
			logPrint("A;" + level.lpselfguida + ";" + level.lpselfnuma + ";" + level.lpselfteama + ";" + level.lpselfnamea + ";" + "psp_take" + "\n");
			level thread [[level.ex_psop]]("tkoth_psp");
			pspa_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
			pspa_flag.flagmodel show();
			pspatimepassed = 0;
		}
		else
		{
			iprintln(&"TKOTH_AXIS_TAKEOVER_PSP_A");
			updateStatusA(level.pspaTeam);
			logPrint("A;" + level.lpselfguida + ";" + level.lpselfnuma + ";" + level.lpselfteama + ";" + level.lpselfnamea + ";" + "psp_take" + "\n");
			level thread [[level.ex_psop]]("tkoth_psp");
			pspa_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
			pspa_flag.flagmodel show();
			pspatimepassed = 0;
		}
	}
}

pspbTimecheck()
{
	pspb_flag = getent("pspb_flag", "targetname");
	pspbtimepassed = (getTime() - level.pspbstarttime ) / 1000;

	if(pspbtimepassed >= 10)
	{
		levelHudDestroy("tkoth_pspb_timerback");
		levelHudDestroy("tkoth_pspb_timer");
		level.pspbTeam = level.pspbAttempt;
		level.pspbAttempt = "";
		if(level.pspbTeam == "allies")
		{
			iprintln(&"TKOTH_ALLIES_TAKEOVER_PSP_B");
			updateStatusB(level.pspbTeam);
			logPrint("A;" + level.lpselfguidb + ";" + level.lpselfnumb + ";" + level.lpselfteamb + ";" + level.lpselfnameb + ";" + "psp_take" + "\n");
			level thread [[level.ex_psop]]("tkoth_psp");
			pspb_flag.flagmodel setmodel("xmodel/prop_flag_" + game["allies"]);
			pspb_flag.flagmodel show();
			pspbtimepassed = 0;
		}
		else
		{
			iprintln(&"TKOTH_AXIS_TAKEOVER_PSP_B");
			updateStatusB(level.pspbTeam);
			logPrint("A;" + level.lpselfguidb + ";" + level.lpselfnumb + ";" + level.lpselfteamb + ";" + level.lpselfnameb + ";" + "psp_take" + "\n");
			level thread [[level.ex_psop]]("tkoth_psp");
			pspb_flag.flagmodel setmodel("xmodel/prop_flag_" + game["axis"]);
			pspb_flag.flagmodel show();
			pspbtimepassed = 0;
		}
	}
}

SetupHUD()
{
	y = 10;
	barsize = 200;

	hud_index = levelHudCreate("tkoth_timerback", undefined, 320, y, 0.3, (0.2,0.2,0.2), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", barsize * 2 + 4, 13);

	hud_index = levelHudCreate("tkoth_axisicon", undefined, 320 + barsize + 3, y, 1, (1,1,1), 1, 1, "fullscreen", "fullscreen", "left", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, game["hudicon_axis"], 18, 18);

	hud_index = levelHudCreate("tkoth_axistime", undefined, 320, y, 0.5, (0,0,1), 1, 1, "fullscreen", "fullscreen", "left", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 1, 11);

	hud_index = levelHudCreate("tkoth_axisinzone", undefined, 320 + barsize + 25, y, 1, (1,1,1), 1.6, 1, "fullscreen", "fullscreen", "left", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	hud_index = levelHudCreate("tkoth_alliesicon", undefined, 320 - barsize - 3, y, 1, (1,1,1), 1, 1, "fullscreen", "fullscreen", "right", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, game["hudicon_allies"], 18, 18);

	hud_index = levelHudCreate("tkoth_alliestime", undefined, 320, y, 0.5, (1,0,0), 1, 1, "fullscreen", "fullscreen", "right", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "white", 1, 11);

	hud_index = levelHudCreate("tkoth_alliesinzone", undefined, 320 - barsize - 25, y, 1, (1,1,1), 1.6, 1, "fullscreen", "fullscreen", "right", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	psp_A = getent("psp_a", "targetname");
	if(isDefined(psp_A))
	{
		hud_index = levelHudCreate("tkoth_pspa_status", undefined, 320, 25, 0, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index == -1) return;
		levelHudSetShader(hud_index, "objectiveA", 12, 12);
	}

	psp_B = getent("psp_b", "targetname");
	if(isDefined(psp_B))
	{
		hud_index = levelHudCreate("tkoth_pspb_status", undefined, 320, 25, 0, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index == -1) return;
		levelHudSetShader(hud_index, "objectiveB", 12, 12);
	}
}

updateHUD()
{
	barsize = 200;
	axis = int(level.axistimepassed * barsize / (level.zonetimelimit * 60 - 1) + 1);
	allies = int(level.alliestimepassed * barsize / (level.zonetimelimit * 60 - 1) + 1);

	if(level.alliestimepassed != level.oldalliestimepassed) levelHudScale("tkoth_alliestime", 1, 0, allies, 11);
	if(level.axistimepassed != level.oldaxistimepassed) levelHudScale("tkoth_axistime", 1, 0, axis, 11);

	level.oldalliestimepassed = level.alliestimepassed;
	level.oldaxistimepassed = level.axistimepassed;
}

updateStatusA(team)
{
	barsize = 200;

	if(team == "allies")
	{
		levelHudSetAlign("tkoth_pspa_status", "right", undefined);
		levelHudSetXYZ("tkoth_pspa_status", 320 - barsize - 3, undefined, undefined);
	}
	else
	{
		levelHudSetAlign("tkoth_pspa_status", "left", undefined);
		levelHudSetXYZ("tkoth_pspa_status", 320 + barsize + 3, undefined, undefined);
	}
	levelHudSetAlpha("tkoth_pspa_status", 0.8);
}

updateStatusB(team)
{
	barsize = 200;

	if(team == "allies")
	{
		levelHudSetAlign("tkoth_pspb_status", "right", undefined);
		levelHudSetXYZ("tkoth_pspb_status", 320 - barsize - 20, undefined, undefined);
	}
	else
	{
		levelHudSetAlign("tkoth_pspb_status", "left", undefined);
		levelHudSetXYZ("tkoth_pspb_status", 320 + barsize + 20, undefined, undefined);
	}
	levelHudSetAlpha("tkoth_pspb_status", 0.8);
}

removeHUD()
{
	levelHudDestroy("tkoth_timerback");
	levelHudDestroy("tkoth_alliesicon");
	levelHudDestroy("tkoth_alliestime");
	levelHudDestroy("tkoth_alliesinzone");
	levelHudDestroy("tkoth_axisicon");
	levelHudDestroy("tkoth_axistime");
	levelHudDestroy("tkoth_axisinzone");

	levelHudDestroy("tkoth_pspa_timerback");
	levelHudDestroy("tkoth_pspa_timer");
	levelHudDestroy("tkoth_pspa_status");

	levelHudDestroy("tkoth_pspb_timerback");
	levelHudDestroy("tkoth_pspb_timer");
	levelHudDestroy("tkoth_pspb_status");
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

	level.psp_A = getent("psp_a", "targetname");
	level.psp_B = getent("psp_b", "targetname");

	wait 0; // Required or the "respawn" notify could happen before it's waittill has begun

	hud_index = playerHudCreate("respawn_text", 0, -50, 1, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetLabel(hud_index, &"TKOTH_PRESS_TO_SPAWN_AT_YOUR_BASE");

	if(isDefined(level.psp_A) && self.pers["team"] == level.pspaTeam)
	{
		hud_index = playerHudCreate("respawn_texta", 0, -25, 1, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetLabel(hud_index, &"TKOTH_PRESS_TO_SPAWN_AT_PSP_A");
	}

	if(isDefined(level.psp_B) && self.pers["team"] == level.pspbTeam)
	{
		y = -25;
		hud_index = playerHudIndex("respawn_texta");
		if(hud_index != -1) y = 0;

		hud_index = playerHudCreate("respawn_textb", 0, y, 1, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetLabel(hud_index, &"TKOTH_PRESS_TO_SPAWN_AT_PSP_B");
	}

	thread removeRespawnText();
	thread waitRemoveRespawnText("end_respawn");
	thread waitRemoveRespawnText("respawn");

	while(true)
	{
		if(self useButtonPressed())
		{
			self.pers["psppoint"] = "base";
			break;
		}
		else if(self attackbuttonPressed() && self.pers["team"] == level.pspaTeam)
		{
			self.pers["psppoint"] = "pspapoint";
			break;
		}
		else if(self meleebuttonPressed() && self.pers["team"] == level.pspbTeam)
		{
			self.pers["psppoint"] = "pspbpoint";
			break;
		}
		else wait( [[level.ex_fpstime]](0.05) );
	}

	self notify("remove_respawntext");
	self notify("respawn");
}

removeRespawnText()
{
	self waittill("remove_respawntext");

	playerHudDestroy("respawn_text");
	playerHudDestroy("respawn_texta");
	playerHudDestroy("respawn_textb");
}

waitRemoveRespawnText(message)
{
	self endon("remove_respawntext");

	self waittill(message);
	self notify("remove_respawntext");
}
