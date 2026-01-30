#include extreme\_ex_hudcontroller;

/*------------------------------------------------------------------------------
Original: Ravir's "Assassin" gametype for COD and UO
Revised: Artful_Dodger's "Espionage Agent" gametype for COD and UO
         revised from Assassin.
COD2 1.3 version: Tally. Ported over Artful_Dodger's ESP gametype and added
         extra features, and changed scoring and respawning patterns.
------------------------------------------------------------------------------*/

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

	game["headicon_commander"] = "headicon_commander";
	game["headicon_guard"] = "headicon_guard";
	game["headicon_hitman"] = "headicon_hitman";

	game["statusicon_commander"] = "statusicon_commander";
	game["statusicon_guard"] = "statusicon_guard";
	game["statusicon_hitman"] = "statusicon_hitman";

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
			[[level.ex_PrecacheStatusIcon]](game["statusicon_commander"]);
			[[level.ex_PrecacheStatusIcon]](game["statusicon_guard"]);
			[[level.ex_PrecacheStatusIcon]](game["statusicon_hitman"]);
		}
		[[level.ex_PrecacheHeadIcon]](game["headicon_commander"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_guard"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_hitman"]);
		[[level.ex_PrecacheShader]]("objpoint_star");
		[[level.ex_PrecacheShader]](game["statusicon_commander"]);
		[[level.ex_PrecacheShader]](game["statusicon_guard"]);
		[[level.ex_PrecacheShader]](game["statusicon_hitman"]);
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");
		[[level.ex_PrecacheString]](&"HM_HITMAN");
		[[level.ex_PrecacheString]](&"HM_KILL_COMMANDER");
		[[level.ex_PrecacheString]](&"HM_NEW_HITMAN");
		[[level.ex_PrecacheString]](&"HM_NEW_GUARD");
		[[level.ex_PrecacheString]](&"HM_NEW_COMMANDER");
		[[level.ex_PrecacheString]](&"HM_HITMAN_VS_HITMAN");
		[[level.ex_PrecacheString]](&"HM_OTHER_HITMANS");
		[[level.ex_PrecacheString]](&"HM_AVOID_GUARDS");
		[[level.ex_PrecacheString]](&"HM_HITMAN_KILL_COMMANDER");
		[[level.ex_PrecacheString]](&"HM_COMMANDER_EVADE_HITMAN");
		[[level.ex_PrecacheString]](&"HM_GUARD_STOP_HITMAN");
		[[level.ex_PrecacheString]](&"HM_GUARD_PROTECT_COMMANDER");
		[[level.ex_PrecacheString]](&"HM_DONT_KILL_GUARDS");
		[[level.ex_PrecacheString]](&"HM_AVOID_GUARDS");
		[[level.ex_PrecacheString]](&"HM_RESPAWN_HITMAN");
		[[level.ex_PrecacheString]](&"HM_GUARD_KILLED_HITMAN");
		[[level.ex_PrecacheString]](&"HM_GUARD_CHOSEN_COMMANDER");
		[[level.ex_PrecacheString]](&"HM_GUARD_CHOSEN_HITMAN");
		[[level.ex_PrecacheString]](&"HM_RESPAWN_GUARD");
		[[level.ex_PrecacheString]](&"HM_HITMAN_KILLEDBY_GUARD");
		[[level.ex_PrecacheString]](&"HM_COMMANDER_KILLEDBY_HITMAN");
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

	for(i = 0; i < spawnpoints.size; i++) spawnpoints[i] placeSpawnpoint();

	allowed[0] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.QuickMessageToAll = true;
	level.mapended = false;

	level.hitmans = 0;
	level.guards = 0;
	level.commander = undefined;
	
	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
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

	self.hm_status = "";
	self.hm_lockstatus = false;
	self.hm_nodamage = false;
	self.hm_wasCommander = false;

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
	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");

	players = level.players;

	guards = [];
	untappedguards = [];
	newcommander = undefined;

	for(i = 0; i < players.size; i++)
	{
		if(isDefined(players[i]) && isDefined(players[i].hm_status) && players[i].hm_status == "guard")
		{
			guards[guards.size] = players[i];
			if(!players[i].hm_wasCommander) // hasn't been commander
				untappedguards[untappedguards.size] = players[i];
		}
	}

	if(!isDefined(self.hm_status)) 
		return;

	if(self.hm_status == "commander")
	{
		objective_delete(0);

		if(untappedguards.size > 0)
		{
			i = randomInt(untappedguards.size);
			newCommander = untappedguards[i];
		}
		else if(guards.size > 0)
		{
			i = randomInt(guards.size);
			newCommander = guards[i];
		}

		if(isDefined(newCommander))
		{
			newCommander thread playerHudAnnounce(&"HM_GUARD_CHOSEN_COMMANDER");
			newCommander thread newStatus("commander");
		}
	}

	if(self.hm_status == "hitman")
	{
		level.hitmans--;
		if(level.hitmans == 0) // there are no more hitmen
		{
			if(guards.size > 0 && level.guards > 0) // pick a guard to become an hitman
			{
				i = randomInt(guards.size);
				newHitman = guards[i];
				newHitman thread playerHudAnnounce(&"HM_GUARD_CHOSEN_HITMAN");
				newHitman thread newStatus("hitman");
			}
		}
	}
}

Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(self.sessionteam == "spectator" || self.ex_invulnerable || self.hm_nodamage) return;
	if(game["matchpaused"]) return;

	friendly = undefined;

	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir)) iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		// Make sure at least one point of damage is done
		if(iDamage < 1) iDamage = 1;

		// guards and commanders share friendly fire damage
		if((self.hm_status == "guard" || self.hm_status == "commander") && isDefined(eAttacker) && isDefined(eAttacker.hm_status) && (eAttacker.hm_status == "guard" || eAttacker.hm_status == "commander"))
		{
			if(level.friendlyfire == "0")
			{
				return;
			}
			else
			{
				eAttacker.friendlydamage = true;

				iDamage = int(iDamage * .5);

				// Make sure at least one point of damage is done
				if(iDamage < 1) iDamage = 1;

				eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
				eAttacker.friendlydamage = undefined;
				eAttacker thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				eAttacker playrumble("damage_heavy");

				friendly = 2;
			}
		}

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

	self.ex_confirmkill = 0;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);
		
	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
		sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";
	playerHudSetStatusIcon("hud_status_dead");

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

	oldStatus = self.hm_status;
	nextStatus = "";

	if(self.hm_status == "commander") 
		self thread delete_commander_marker();

	penalty = 0;

	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			lpattackguid = lpselfguid;
			lpattacknum = lpselfnum;
			lpattackname = lpselfname;
			doKillcam = false;
			self.hm_lockstatus = true; // killing yourself keeps your status
			if(!isDefined(self.switching_teams)) self thread [[level.pscoreproc]](-1);
		}
		else
		{
			lpattackguid = attacker getGuid();
			lpattacknum = attacker getEntityNumber();
			lpattackname = attacker.name;
			doKillcam = true;

			// give points to commander killing hitman
			if(attacker.hm_status == "commander" && self.hm_status == "hitman")
				attacker thread [[level.pscoreproc]](level.ex_hmpoints_cmd_hitman);

			// give points to guard killing hitman
			if(attacker.hm_status == "guard" && self.hm_status == "hitman")
				attacker thread [[level.pscoreproc]](level.ex_hmpoints_guard_hitman);

			// give points to hitman
			if(attacker.hm_status == "hitman")
			{
				// give points to hitman killing commander
				if(self.hm_status == "commander")
					attacker thread [[level.pscoreproc]](level.ex_hmpoints_hitman_cmd);

				// give points to hitman killing guard
				if(self.hm_status == "guard")
					attacker thread [[level.pscoreproc]](level.ex_hmpoints_hitman_guard);

				// give points to hitman killing another hitman
				if(self.hm_status == "hitman")
				{
					// additional respawn delay for killed hitman (optional)
					penalty = level.penalty_time;
					self.hm_lockstatus = true;
					attacker thread [[level.pscoreproc]](level.ex_hmpoints_hitman_hitman);
				}
			}

			if(self.hm_status == "hitman" && attacker.hm_status == "guard") // a guard killed a hitman
			{
				self thread playerHudAnnounce(&"HM_HITMAN_KILLEDBY_GUARD");
				self thread playerHudAnnounce(&"HM_RESPAWN_GUARD");
				// see if the guard should become a hitman
				if(level.hitmans > 1) // more than one hitman, may need to lose one
				{
					if(level.guards + 1 > (level.hitmans-1) * 2) // losing a hitman would produce more than 2 guards per hitman
						attackerNewStatus = "hitman";
					else 
						attackerNewStatus = "guard";
				}
				else attackerNewStatus = "hitman";
				
				self thread newStatus("guard");

				attacker thread playerHudAnnounce(&"HM_GUARD_KILLED_HITMAN");
				if(attackerNewStatus == "hitman")
				{
					attacker thread playerHudAnnounce(&"HM_RESPAWN_HITMAN");
					attacker thread newStatus("hitman");
				}
			}

			if(self.hm_status == "hitman" && attacker.hm_status == "commander") // the commander killed an hitman
			{
				self.hm_lockstatus = true;
			}
			
			if(self.hm_status == "commander") // the commander was killed by the hitman
			{
				level.commander = undefined;
				players = level.players;
				guards = [];
				untappedguards = [];
				for(i = 0; i < players.size; i++)
				{
					if(isDefined(players[i]) && isDefined(players[i].hm_status) && players[i].hm_status == "guard")
					{
						guards[guards.size] = players[i]; // all guards
						if(!players[i].hm_wasCommander)
							untappedguards[untappedguards.size] = players[i]; // guards that haven't been the commander yet
					}
				}

				if(level.guards == 0) // the hitman and commander are alone on the server, exchange them
				{
					attacker thread playerHudAnnounce(&"HM_GUARD_CHOSEN_COMMANDER");
					attacker thread newStatus("commander");
					self thread playerHudAnnounce(&"HM_GUARD_CHOSEN_HITMAN");
					self thread newStatus("hitman");
				}
				else // there are guards on the server
				{
					if(untappedguards.size > 0)
					{
						j = randomint(untappedguards.size);
						newCommander = untappedguards[j];
					}
					else
					{
						j = randomint(guards.size);
						for(i = 0; i < guards.size; i++)
							guards[i].hm_wasCommander = false;
						newCommander = guards[j];
					}
					if(!isDefined(level.commander)) // in case someone else already got the spot
					{
						newCommander thread playerHudAnnounce(&"HM_GUARD_CHOSEN_COMMANDER");
						newCommander thread newStatus("commander");
					}
					self thread playerHudAnnounce(&"HM_COMMANDER_KILLEDBY_HITMAN");
					self thread playerHudAnnounce(&"HM_RESPAWN_GUARD");
					self thread newStatus("guard"); // the commander is now a guard
				}
			}
		}
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		lpattackguid = "";
		lpattacknum = -1;
		lpattackname = "";
		lpattackteam = "world";
		doKillcam = false;

		self.hm_lockstatus = true;
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
	//thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);

	delay = 2 + penalty; // Delay the player becoming a spectator till after he's done dying
	if(penalty > 0) self thread playerHudAnnounce(&"HM_HITMAN_VS_HITMAN");
	wait( [[level.ex_fpstime]](delay) ); // Also required for Callback_PlayerKilled to complete before killcam can execute

	// no killcam for the commander if he needs to respawn
	if(self.hm_status == "commander") doKillcam = false;

	if(doKillcam && level.killcam) 
	{
		self maps\mp\gametypes\_killcam::killcam(lpattacknum, delay, psOffsetTime, true);
		self thread respawn();
	}
	else // if you're still the commander, you can't wait to respawn
	{
		if(self.hm_status == "commander") self thread spawnPlayer();
			else self thread respawn();
	}
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
		spawnpointname = "mp_dm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_DM(spawnpoints);

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(!self.hm_lockstatus) // enable auto-selection of role
	{
		nextStatus = "";

		if(level.hitmans == 0) // the first player to spawn is an hitman
		{
			nextStatus = "hitman";
		}
		if(level.hitmans >= 1 && !isDefined(level.commander) && (self.hm_status == "" || self.hm_status == "guard")) // there is an hitman, but no commander, this player is the commander
		{
			nextStatus = "commander";
			level.commander = self;
		}

		if(level.hitmans > 0 && isDefined(level.commander) && self.hm_status != "commander" && nextStatus != "commander" && nextStatus != "hitman") // this player should be either an hitman or guard
		{
			if(level.guards <= level.hitmans * 2) // there aren't enough guards, should be at least 2 to 1 odds
			{
				if(self.hm_status == "hitman") // is currently an hitman, may have to change
				{
					if((level.guards+1 <= (level.hitmans-1) * 2) && level.hitmans > 1) // one more guard and one less hitman is still good odds
						nextStatus = "guard";
					else
						nextStatus = "hitman";
				}
				else // they're not an hitman, make them a guard
				{
					nextStatus = "guard";
				}
			}
			else // might need another hitman, too many guards
			{
				if(self.hm_status == "") // not set yet, make an hitman
					nextStatus = "hitman";

				if(self.hm_status == "guard") // player is currently a guard
				{
					if((level.guards - 1) <= (level.hitmans+1) * 2) // cannot afford to convert guard to hitman
						nextStatus = "guard";
					else
						nextStatus = "hitman";
				}
			}
		}
	}
	else
	{
		nextStatus = self.hm_status; // players status was locked by another function
	}

	self.hm_nodamage = false;
	self newStatus(nextStatus);

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");
}

respawn()
{
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	if(!level.forcerespawn)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}

	self thread spawnPlayer();
}

setHeadIcon()
{
	switch(self.hm_status)
	{
		case "commander": self.headicon = game["headicon_commander"]; break;
		case "guard": self.headicon = game["headicon_guard"]; break;
		case "hitman": self.headicon = game["headicon_hitman"]; break;
	}
}

// a player's status has changed, inform them
newStatus(status)
{
	self endon("disconnect");

	if(!isDefined(status))
		status = self.hm_status;
	if(self.hm_status == "guard")
		level.guards--;	
	if(self.hm_status == "hitman") 
		level.hitmans--;

	myHeadIcon = undefined;
	myStatusIcon = undefined;
	myHud1Text = undefined;
	myHud1Icon = undefined;
	myHud2Text = undefined;
	myHud2Icon = undefined;
	myHud3Text = undefined;
	myHud3Icon = undefined;
	myStatus = undefined;

	switch(status)
	{
		case "guard":
			myHeadIcon = "headicon_guard";
			myStatusIcon = "statusicon_guard";
			myHud1Text = &"HM_GUARD_STOP_HITMAN";
			myHud1Icon = "statusicon_hitman";
			myHud2Text = &"HM_DONT_KILL_GUARDS";
			myHud2Icon = "statusicon_guard";
			myHud3Text = &"HM_GUARD_PROTECT_COMMANDER";
			myHud3Icon = "statusicon_commander";
			myStatus = &"HM_NEW_GUARD";
			level.guards++;
			break;

		case "commander":
			myHeadIcon = "headicon_commander";
			myStatusIcon = "statusicon_commander";
			myHud1Text = &"HM_NEW_COMMANDER";
			myHud1Icon = "statusicon_commander";
			myHud2Text = &"HM_DONT_KILL_GUARDS";
			myHud2Icon = "statusicon_guard";
			myHud3Text = &"HM_COMMANDER_EVADE_HITMAN";
			myHud3Icon = "statusicon_hitman";
			myStatus = &"HM_NEW_COMMANDER";
			level.commander = self;
			self.hm_wasCommander = true;
			break;

		case "hitman":
			myHeadIcon = "headicon_hitman";
			myStatusIcon = "statusicon_hitman";
			myHud1Text = &"HM_OTHER_HITMANS";
			myHud1Icon = "statusicon_hitman";
			myHud2Text = &"HM_AVOID_GUARDS";
			myHud2Icon = "statusicon_guard";
			myHud3Text = &"HM_HITMAN_KILL_COMMANDER";
			myHud3Icon = "statusicon_commander";
			myStatus = &"HM_NEW_HITMAN";
			level.hitmans++;
			break;
	}

	respawnNow = undefined;

	if((self.hm_status == "guard" || self.hm_status == "hitman") && status == "commander" && self.sessionstate == "playing") // a player has been chosen to respawn as the commander
	{
		self.hm_status = "commander";
		respawnNow = 1;
	}

	if((self.hm_status == "guard" || self.hm_status == "commander") && status == "hitman" && self.sessionstate == "playing") // a player has been chosen to be an hitman
	{
		self.hm_status = "hitman";
		respawnNow = 1;
	}

	if(isDefined(respawnNow)) // do the forced respawn
	{
		self.hm_lockstatus = true;
		// take away their weapons and mark them as undamageable
		self.hm_nodamage = true;

		wait( [[level.ex_fpstime]](2) );
		self.sessionstate = "dead"; // hide the player from the world

		self thread clearHud();

		wait( [[level.ex_fpstime]](3) );
		self thread spawnplayer(); // respawn this player
		return;
	}

	self.hm_status = status;

	if(self.sessionstate == "playing")
	{
		self.hm_lockstatus = false;

		playerHudSetStatusIcon(game[myStatusIcon]);
		playerHudSetHeadIcon(game[myHeadIcon], undefined);

		hud_index = playerHudCreate("hm_statusicon", 180, 420, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
		if(hud_index != -1)
		{
			if(isDefined(self.oldhmst) && self.oldhmst != myStatusIcon)
			{
				playerHudSetShader(hud_index, game[myStatusIcon], 96, 96);
				playerHudScale(hud_index, 2, 0, 24, 24);
			}
			else playerHudSetShader(hud_index, game[myStatusIcon], 24, 24);
		}

		hud_index = playerHudCreate("hm_text1", 575, 140, 0.7, (1,1,1), 1, 0, "left", "top", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetText(hud_index, myHud1Text);

		hud_index = playerHudCreate("hm_icon1", 575, 165, 1, (1,1,1), 1, 0, "left", "top", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetShader(hud_index, game[myHud1Icon], 24, 24);

		hud_index = playerHudCreate("hm_text2", 575, 190, 0.7, (1,1,1), 1, 0, "left", "top", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetText(hud_index, myHud2Text);

		hud_index = playerHudCreate("hm_icon2", 575, 215, 1, (1,1,1), 1, 0, "left", "top", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetShader(hud_index, game[myHud2Icon], 24, 24);

		hud_index = playerHudCreate("hm_text3", 575, 235, 0.7, (1,1,1), 1, 0, "left", "top", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetText(hud_index, myHud3Text);

		hud_index = playerHudCreate("hm_icon3", 575, 260, 1, (1,1,1), 1, 0, "left", "top", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetShader(hud_index, game[myHud3Icon], 24, 24);

		self thread playerHudAnnounce(myStatus);
		self thread playerHudAnnounce(myHud3Text);

		self setClientCvar("cg_objectiveText", myHud3Text);

		if(self.hm_status == "commander") 
			self thread make_commander_marker();
	}
	else self.hm_lockstatus = true; // lock this status in place for the next spawn

	self thread fadehudinfo();
	self.oldhmst = myStatusIcon;
}

fadehudinfo()
{
	self endon("death");
	self endon("respawn");
	
	wait( [[level.ex_fpstime]](10) );

	playerHudFade("hm_text1", 2, 0, 0);
	playerHudFade("hm_icon1", 2, 0, 0);
	playerHudFade("hm_text2", 2, 0, 0);
	playerHudFade("hm_icon2", 2, 0, 0);
	playerHudFade("hm_text3", 2, 0, 0);
	playerHudFade("hm_icon3", 2, 0, 0);

	wait( [[level.ex_fpstime]](2) );

	playerHudDestroy("hm_text1");
	playerHudDestroy("hm_icon1");
	playerHudDestroy("hm_text2");
	playerHudDestroy("hm_icon2");
	playerHudDestroy("hm_text3");
	playerHudDestroy("hm_icon3");
}

clearHUD()
{
	playerHudDestroy("hm_text1");
	playerHudDestroy("hm_icon1");
	playerHudDestroy("hm_text2");
	playerHudDestroy("hm_icon2");
	playerHudDestroy("hm_text3");
	playerHudDestroy("hm_icon3");
	playerHudDestroy("hm_statusicon");
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
		timelimit = getCvarFloat("scr_hm_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_hm_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_hm_scorelimit");
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

make_commander_marker()
{
	self endon("disconnect");
	self endon("commanderblip");
	wait( [[level.ex_fpstime]](level.tposuptime) );

	while((isPlayer(self)) && (isAlive(self)))
	{
		if(level.showcommander)
		{
			objective_add(0, "current", self.origin, "objpoint_star");
			objective_icon(0, "objpoint_star");
			objective_team(0, "none");
			objective_position(1, self.origin);
			lastobjpos = self.origin;
			newobjpos = self.origin;
			lastobjpos = newobjpos;
			newobjpos = (((lastobjpos[0] + self.origin[0]) * 0.5), ((lastobjpos[1] + self.origin[1]) * 0.5), 0);
			objective_position(0, newobjpos);
		}
		wait( [[level.ex_fpstime]](level.tposuptime) );
		objective_delete(0);
	}
}

delete_commander_marker()
{
	self notify("commanderblip");
	objective_delete(0);
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
