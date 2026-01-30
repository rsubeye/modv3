#include extreme\_ex_hudcontroller;

/*------------------------------------------------------------------------------
	V.I.P. - eXtreme+ mod compatible version, Version 1.2
	Author : La Truffe
	Credits : Astoroth (eXtreme+ mod), Ravir (cvardef function)

	Objective : Kill the VIP of the other team while protecting yours.
	A team scores when the enemy VIP has been killed.
	Map ends : When one team reaches the score limit, or time limit is reached.
	Respawning : After a configurable delay / Near teammates.
------------------------------------------------------------------------------*/

main()
{
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerDamage = ::Callback_PlayerDamage;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();

	level.autoassign = ::menuAutoAssign;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
	level.spectator = ::menuSpectator;
	level.weapon = extreme\_ex_clientcontrol::menuWeapon;
	level.secweapon = extreme\_ex_clientcontrol::menuSecWeapon;
	level.spawnplayer = ::spawnplayer;
	level.respawnplayer = ::respawn;
	level.updatetimer = ::updatetimer;
	level.endgameconfirmed = ::endMap;
	level.checkscorelimit = ::checkScoreLimit;

	// set eXtreme+ variables and precache
	extreme\_ex_varcache::main();

	// Over-override Callback_PlayerDamage
	level.vip_callbackPlayerDamage = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::VIP_Callback_PlayerDamage;
}

Callback_StartGameType()
{
	// defaults if not defined in level script
	if(!isDefined(game["allies"])) game["allies"] = "american";
	if(!isDefined(game["axis"])) game["axis"] = "german";

	// server cvar overrides
	if(level.game_allies != "") game["allies"] = level.game_allies;
	if(level.game_axis != "") game["axis"] = level.game_axis;

	// vip pistols
	if(level.ex_modern_weapons)
	{
		level.vip_pistol["american"] = "deagle_vip_mp";
		level.vip_pistol["british"] = "beretta_vip_mp";
		level.vip_pistol["russian"] = "glock_vip_mp";
		level.vip_pistol["german"] = "hk45_vip_mp";
	}
	else
	{
		level.vip_pistol["american"] = "colt_vip_mp";
		level.vip_pistol["british"] = "webley_vip_mp";
		level.vip_pistol["russian"] = "tt30_vip_mp";
		level.vip_pistol["german"] = "luger_vip_mp";
	}

	level.vip_smokenade["american"] = "smoke_grenade_american_vip_mp";
	level.vip_smokenade["british"] = "smoke_grenade_british_vip_mp";
	level.vip_smokenade["russian"] = "smoke_grenade_russian_vip_mp";
	level.vip_smokenade["german"] = "smoke_grenade_german_vip_mp";

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
			[[level.ex_PrecacheStatusIcon]]("hudicon_" + game["allies"]);
			[[level.ex_PrecacheStatusIcon]]("hudicon_" + game["axis"]);
		}
		[[level.ex_PrecacheHeadIcon]]("objective_" + game["allies"] + "_down");
		[[level.ex_PrecacheHeadIcon]]("objective_" + game["axis"] + "_down");
		[[level.ex_PrecacheShader]]("objective_" + game["allies"]);
		[[level.ex_PrecacheShader]]("objective_" + game["axis"]);
		[[level.ex_PrecacheString]](&"MP_TIME_TILL_SPAWN");
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");
		[[level.ex_PrecacheString]](&"MP_VIP_SPOTTED");

		/* now done in _weapons::precacheWeapons
		if(level.vippistol)
		{
			[[level.ex_PrecacheItem]](level.vip_pistol[game["allies"]]);
			[[level.ex_PrecacheItem]](level.vip_pistol[game["axis"]]);
		}
		*/

		if(level.vipsmokenades)
		{
			[[level.ex_PrecacheItem]](level.vip_smokenade[game["allies"]]);
			[[level.ex_PrecacheItem]](level.vip_smokenade[game["axis"]]);
		}

		level._effect["vip_fx"] = [[level.ex_PrecacheEffect]]("fx/misc/flare_smoke_9sec.efx");
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

	level.mapended = false;
	level.alive_time_record = 0;
	level.objnumber = [];
	level.objnumber["allies"] = 0;
	level.objnumber["axis"] = 1;
	level.vip_player = [];
	level.vip_player["allies"] = undefined;
	level.vip_player["axis"] = undefined;

	game["matchpaused"] = 0;
	if(!isDefined(game["matchovertime"])) game["matchovertime"] = 0;
	if(!isDefined(game["state"])) game["state"] = "playing";

	level.starttime = getTime();
	if(!level.ex_readyup || (level.ex_readyup && isDefined(game["readyup_done"])) )
	{
		thread startGame();
		thread updateGametypeCvars();
		level thread SelectVIP("allies");
		level thread SelectVIP("axis");
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
	if(self IsVIP())
	{
		iprintln(&"MP_VIP_DISCONNECTED", [[level.ex_pname]](self));
		RemoveVIPFromTeam(self.pers["team"]);
	}

	lpselfnum = self getEntityNumber();
	lpselfguid = self getGuid();
	logPrint("Q;" + lpselfguid + ";" + lpselfnum + ";" + self.name + "\n");
}

VIP_Callback_PlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(level.vipsmokenades && isDefined(sWeapon) && ((sWeapon == level.vip_smokenade[game["allies"]]) || (sWeapon == level.vip_smokenade[game["axis"]])))
	{
		// Damage caused by a VIP smoke nade : not a real damage

		if(isDefined(self) && isPlayer(self) && (self IsVIP()) && (isDefined(self.pers["team"])) && (sWeapon == level.vip_smokenade[game[self.pers["team"]]]))
			self thread VIPSmoke(vPoint);

		return;
	}

	[[level.vip_callbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
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

			// Damage caused to the enemy VIP: record the time
			if((self IsVIP()) && isDefined(eAttacker) && isPlayer(eAttacker))
				eAttacker.last_VIP_damage_time = getTime();
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

	if(isDefined(self.switching_vip))
	{
		self notify("kill_thread");
		self.ex_confirmkill = 0;
	}
	else self.ex_confirmkill = extreme\_ex_killconfirmed::kcCheck(attacker, sMeansOfDeath, sWeapon);

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	if(!isDefined(self.switching_vip))
	{
		// If the player was killed by a head shot, let players know it was a head shot kill
		if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") sMeansOfDeath = "MOD_HEAD_SHOT";

		// send out an obituary message to all clients about the kill
		self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

		self maps\mp\gametypes\_weapons::dropWeapon();
		self maps\mp\gametypes\_weapons::dropOffhand();
	}

	self.sessionstate = "dead";
	playerHudSetStatusIcon("hud_status_dead");

	if(!isDefined(self.switching_vip))
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

			// Check if reward points should be given for bash or headshot
			reward_points = 0;
			if(isDefined(sMeansOfDeath))
			{
				if(sMeansOfDeath == "MOD_MELEE") reward_points = level.ex_reward_melee;
					else if(sMeansOfDeath == "MOD_HEAD_SHOT") reward_points = level.ex_reward_headshot;
			}

			// Check if extra points should be given for GT specific achievement
			reward_points += attacker checkProtectedVIP(self);

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

	if(self isVIP()) self thread VIPkilledBy(attacker);

	if(!isDefined(self.switching_vip))
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

	if(isDefined(self.switching_vip))
	{
		self.switching_vip = undefined;
		self.isvip = true;
	}

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

	team = self.pers["team"];
	if(self IsVIP()) playerHudSetStatusIcon("hudicon_" + game[team]);
		else playerHudRestoreStatusIcon();

	if(self IsVIP()) self.maxhealth = level.viphealth;
		else self.maxhealth = level.ex_player_maxhealth;
	self.health = self.maxhealth;

	self.last_VIP_damage_time = undefined;

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
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

		if(isDefined(spawnpoint)) self spawn(spawnpoint.origin, spawnpoint.angles);
			else maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	self setClientCvar("cg_objectiveText", &"MP_VIP_OBJ_TEXT_NOSCORE");

	if(self IsVIP())
	{
		self setHeadIcon();

		// Change the VIP weapons a posteriori
		if(level.vippistol)
		{
			self takeWeapon(self getWeaponSlotWeapon("primary"));
			self takeWeapon(self getWeaponSlotWeapon("primaryb"));

			pistol = level.vip_pistol[game[team]];
			self giveWeapon(pistol);
			self giveMaxAmmo(pistol);
			self switchToWeapon(pistol);

			self.pers["sidearm"] = pistol;

			self.weapon["virtual"].name = "ignore";
			self.weapon["virtual"].clip = 0;
			self.weapon["virtual"].reserve = 0;
			self.weapon["virtual"].maxammo = 0;
		}

		if(level.vipsmokenades)
		{
			self RemoveRegularSmokeNades();

			smokenade = level.vip_smokenade[game[team]];
			self giveWeapon(smokenade);
			self setWeaponClipAmmo(smokenade, level.vipsmokenades);
		}

		if(level.vipfragnades)
		{
			fragnade = "frag_grenade_" + game[team] + "_mp";
			self giveWeapon(fragnade);
			self setWeaponClipAmmo(fragnade, level.vipfragnades);
		}

		// VIP attributes
		self.vip_credit = 0;
		self.vip_alive_time = getTime();
		self.vip_alive_time_cycle = self.vip_alive_time;

		// Add the objective on compass
		if(level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		{
			if(level.vipvisiblebyteammates && level.vipvisiblebyenemies) objteam = "none";
				else if(level.vipvisiblebyteammates) objteam = team;
					else objteam = EnemyTeam(team);

			objective_add(level.objnumber[team], "current", self.origin, "objective_" + game[team]);
			objective_team(level.objnumber[team], objteam);
		}

		// Follow VIP until he's no longer a VIP
		self thread FollowVIP();
	}

	self thread updateTimer();

	if(level.vipbinoculars) self thread CheckBinoculars();

	waittillframeend;
	self extreme\_ex_main::exPostSpawn();
	self notify("spawned_player");
}

respawn(updtimer)
{
	self endon("disconnect");
	self endon("end_respawn");

	if(!isDefined(self.pers["weapon"])) return;

	if(!isDefined(updtimer)) updtimer = false;
	if(updtimer) self thread updateTimer();

	while(isDefined(self.WaitingToSpawn)) wait( [[level.ex_fpstime]](0.05) );

	// VIP is forced to respawn
	if(!level.forcerespawn && !self IsVIP())
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
		timelimit = getCvarFloat("scr_vip_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_vip_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_vip_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			checkScoreLimit();
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

menuAutoAssign()
{
	if(self IsVIP())
	{
		self iprintlnbold(&"MP_VIP_CHANGE_TEAM");
		return;
	}

	self extreme\_ex_clientcontrol::menuAutoAssign();
}

menuAllies()
{
	if(self IsVIP())
	{
		self iprintlnbold(&"MP_VIP_CHANGE_TEAM");
		return;
	}

	self extreme\_ex_clientcontrol::menuAllies();
}

menuAxis()
{
	if(self IsVIP())
	{
		self iprintlnbold(&"MP_VIP_CHANGE_TEAM");
		return;
	}

	self extreme\_ex_clientcontrol::menuAxis();
}

menuSpectator()
{
	if(self IsVIP())
	{
		self iprintlnbold(&"MP_VIP_SPECTATOR");
		return;
	}

	self extreme\_ex_clientcontrol::menuSpectator();
}

IsVIP()
{
	if(!isDefined(self.isvip))
		self.isvip = false;

	return self.isvip;
}

SetVIP()
{
	// We shouldn't be here...
	if(self IsVIP()) return;

	// VIP attributes
	self.in_smoke = spawnstruct();
	self.in_smoke.status = false;
	self.in_smoke.nextnade = 0;
	self.in_smoke.statusbynade = [];
	for(i = 0; i < level.vipmaxsmokenades; i ++)
		self.in_smoke.statusbynade[i] = false;

	vipteam = self.pers["team"];

	// Already a VIP in the team ?! (should not happen)
	if(isDefined(level.vip_player[vipteam])) return;

	level.vip_player[vipteam] = self;
	self.dont_auto_balance = true;

	// Notify the change to the player himself
	self iprintlnbold(&"MP_VIP_BECOME_VIP1");
	self iprintlnbold(&"MP_VIP_BECOME_VIP2");
	self playLocalSound("ctf_touchenemy");

	// Notify the change to other players
	players = level.players;
	for(i = 0; i < players.size; i ++)
	{
		player = players[i];
		if((!isDefined(player.pers["team"])) || (player == self))
			continue;

		if(vipteam == "allies")
			player iprintlnbold(&"MP_VIP_NEW_VIP_ALLIES", [[level.ex_pname]](self));
		else
			player iprintlnbold(&"MP_VIP_NEW_VIP_AXIS", [[level.ex_pname]](self));
	}

	// Suicide the player with a little effect
	self.switching_vip = true;
	self suicide();
	playfx(level._effect["vip_fx"], self.origin);
}

ForceVIPpistol()
{
	if(level.ex_spwn_time && self.ex_invulnerable && level.ex_spwn_wepdisable) return;

	current = self getCurrentWeapon();
	if(current == game["sprint"]) return;

	pistol = level.vip_pistol[game[self.pers["team"]]];

	if(extreme\_ex_weapons::isDummy(current) || (current == "none"))
		self switchToWeapon(pistol);
	else if((extreme\_ex_weapons::isValidWeapon(current)) && (current != pistol))
	{
		self dropItem(current);
		pistolname = maps\mp\gametypes\_weapons::getWeaponName(pistol);
		self iprintlnbold(&"CUSTOM_ADMIN_NAME", &"WEAPON_PISTOL_SWAP_NO_MSG1");
		self iprintlnbold(&"WEAPON_PISTOL_SWAP_NO_MSG2", pistolname);
	}
}

RemoveRegularSmokeNades()
{
	team = self.pers["team"];

	self takeWeapon("smoke_grenade_" + game["allies"] + extreme\_ex_weapons::getSmokeColour(level.ex_smoke[game["allies"]]) + "mp");
	self takeWeapon("smoke_grenade_" + game["axis"] + extreme\_ex_weapons::getSmokeColour(level.ex_smoke[game["axis"]]) + "mp");
}

FollowVIP()
{
	vipteam = self.pers["team"];

	self LoopOnVIP();

	level thread SelectVIP(vipteam);
}

LoopOnVIP()
{
	self endon("kill_thread");
	self endon("killed_vip");

	while((isDefined(self)) && (isPlayer(self)) && (isDefined(self.pers["team"])) && (self IsVIP()))
	{
		wait( [[level.ex_fpstime]](0.05) );

		vipteam = self.pers["team"];

		// Update icon position and visibility on compass
		if(level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		{
			objective_position(level.objnumber[vipteam], self.origin);

			self.in_smoke.status = false;
			for(i = 0; i < level.vipmaxsmokenades; i ++)
				self.in_smoke.status = self.in_smoke.status || self.in_smoke.statusbynade[i];

			if(self.in_smoke.status)
				objective_state(level.objnumber[vipteam], "invisible");
			else
				objective_state(level.objnumber[vipteam], "current");
		}

		// Make sure VIP pistol is used
		if(level.vippistol) self ForceVIPpistol();

		// Make sure VIP has no regular smoke nade
		if(level.vipsmokenades)
			self RemoveRegularSmokeNades();

		// Reward VIP for staying alive if enemy team is populated
		timepassed = (getTime() - self.vip_alive_time_cycle) / 1000;
		if(timepassed > level.vippointscycle * 60)
		{
			self.vip_alive_time_cycle = getTime();
			playerscount = maps\mp\gametypes\_teams::CountPlayers();
			if(playerscount[EnemyTeam(vipteam)] > 0) self thread [[level.pscoreproc]](level.vippoints);
		}
	}
}

VIPSmoke(location)
{
	if((!level.vipvisiblebyteammates) && (!level.vipvisiblebyenemies)) return;

	self endon("disconnect");
	self endon("killed_vip");

	nade = self.in_smoke.nextnade;
	self.in_smoke.nextnade ++;

	vipteam = self.pers["team"];
	endtime = getTime() + level.vipsmokeduration * 1000;

	while(getTime() < endtime)
	{
		self.in_smoke.statusbynade[nade] = (distance(self.origin, location) <= level.vipsmokeradius);
		wait( [[level.ex_fpstime]](0.1) );
	}

	self.in_smoke.statusbynade[nade] = false;
}

RemoveVIPFromTeam(team)
{
	// Team has no more VIP
	level.vip_player[team] = undefined;

	// Remove the objective on compass
	if(level.vipvisiblebyteammates || level.vipvisiblebyenemies)
		objective_delete(level.objnumber[team]);
}

UnsetVIP(team)
{
	// We shouldn't be here...
	if(!self IsVIP()) return;

	RemoveVIPFromTeam(team);

	self.isvip = false;
	self.dont_auto_balance = undefined;
	self.in_smoke = undefined;
	self setHeadIcon();

	// Notify the change to the player himself only
	self iprintlnbold(&"MP_VIP_NO_LONGER_VIP");
}

setHeadIcon()
{
	if(self.isvip)
	{
		headicon_vip = "objective_" + game[self.pers["team"]] + "_down";
		playerHudSetHeadIcon(headicon_vip);
	}
	else playerHudRestoreHeadIcon();
}

SelectVIP(team)
{
	wait( [[level.ex_fpstime]](level.vipdelay) );
	
	candidate = undefined;
	candidate_credit = 0;

	for(;;)
	{
		players = level.players;

		// Increase randomly the credit of all living players of the team
		for(i = 0; i < players.size; i ++)
		{
			player = players[i];

			if((!isDefined(player.pers["team"])) || (player.pers["team"] != team)) continue;

			if(!isDefined(player.vip_credit))
				player.vip_credit = 0;

			if(player.sessionstate == "playing")
				player.vip_credit += randomInt(100);
		}

		// Choose the new VIP = the alive player with the highest credit
		for(i = 0; i < players.size; i ++)
		{
			player = players[i];
		
			if((!isDefined(player.pers["team"])) || (player.pers["team"] != team)) continue;
		
			if(player.vip_credit > candidate_credit)
			{
				candidate = player;
				candidate_credit = player.vip_credit;
			}
		}

		playerscount = maps\mp\gametypes\_teams::CountPlayers();

		if(isDefined(candidate) && (candidate.sessionstate == "playing") && (playerscount[EnemyTeam(team)] > 0)) break;

		wait( [[level.ex_fpstime]](1) );
	}

	candidate SetVIP();
}

VIPkilledBy(killer)
{
	vipteam = self.pers["team"];
	enemyteam = EnemyTeam(vipteam);

	if(isPlayer(killer))
		killerteam = killer.pers["team"];
	else
		killerteam = undefined;

	if(!isDefined(killerteam))
	{
		iprintlnbold(&"MP_VIP_KILLED", [[level.ex_pname]](self));
		teamscoring	= enemyteam;
	}
	else if(killer == self)
	{
		if(isDefined(self.switching_teams))
		{
			self notify("killed_vip");
			self UnsetVIP(vipteam);
			return;
		}

		iprintlnbold(&"MP_VIP_KILLED_HIMSELF", [[level.ex_pname]](killer));
		teamscoring = enemyteam;
	}
	else if(killerteam == vipteam)
	{
		iprintlnbold(&"MP_VIP_TEAMKILLED_BY", [[level.ex_pname]](killer));
		teamscoring = enemyteam;
	}
	else
	{
		iprintlnbold(&"MP_VIP_KILLED_BY", [[level.ex_pname]](killer));
		teamscoring = killerteam;
		killer thread [[level.pscoreproc]](level.pointsforkillingvip);
	}

	alive_time = getTime() - self.vip_alive_time;
	alive_sec_total = int(alive_time / 1000);
	alive_min = int(alive_sec_total / 60);
	alive_sec = alive_sec_total - alive_min * 60;
	if(alive_sec >= 10)
		alive_str = alive_min + "'" + alive_sec + "''";
	else
		alive_str = alive_min + "'0" + alive_sec + "''";

	if(alive_time > level.alive_time_record)
	{
		iprintln(&"MP_VIP_ALIVE_RECORD", alive_str);
		level.alive_time_record = alive_time;
	}
	else iprintln(&"MP_VIP_ALIVE", alive_str);

	level thread [[level.ex_psop]]("ctf_touchcapture", teamscoring);
	level thread [[level.ex_psop]]("ctf_enemy_touchcapture", vipteam);

	thread [[level.tscoreproc]](teamscoring, 1);

	self notify("killed_vip");
	self UnsetVIP(vipteam);
}

EnemyTeam(team)
{
	if(team == "axis") enemyteam = "allies";
		else enemyteam = "axis";
	return (enemyteam);
}

CheckBinoculars()
{
	self endon("kill_thread");

	for(;;)
	{
		self waittill("binocular_enter");
		self thread CheckVIPspotted();

		self waittill("binocular_exit");
		playerHudDestroy("vip_spotted");
	}	
}

CheckVIPspotted()
{
	self endon("kill_thread");
	self endon("binocular_exit");

	wait( [[level.ex_fpstime]](0.5) );

	team = self.pers["team"];
	vipteam = EnemyTeam(team);

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.1) );

		// No VIP on team yet
		if(!isDefined(level.vip_player[vipteam])) continue;

		vip = level.vip_player[vipteam];

		// Condition on alive state
		cond_state = (vip.sessionstate == "playing");

		// Condition on invisibility in smoke
		cond_smoke = (isDefined(vip.in_smoke)) && (isDefined(vip.in_smoke.status)) && (!vip.in_smoke.status);

		self_eyepos = self getEye();
		vip_eyepos = vip getEye();
		self_angles = self getplayerangles();

		trace = bulletTrace(self_eyepos, vip_eyepos, false, undefined);
		virtualpoint = trace["position"];
		virtual_dist = distance(vip_eyepos, virtualpoint);

		// Condition on direct visibility
		cond_visible = (virtual_dist < 5);

		virtual_angles = vectortoangles(vectornormalize(trace["normal"]));

		delta_angles_v = virtual_angles[0] - self_angles[0];
		if(delta_angles_v < 0) delta_angles_v += 360;
		else if(delta_angles_v > 360) delta_angles_v -= 360;

		delta_angles_h = virtual_angles[1] - self_angles[1];
		if(delta_angles_h < 0) delta_angles_h += 360;
		else if(delta_angles_h > 360) delta_angles_h -= 360;

		// Condition on view angles : less than 4 degrees vertically and horizontally
		cond_angle = ((delta_angles_v < 4) || (delta_angles_v > 356)) && ((delta_angles_h < 4) || (delta_angles_h > 356));

		// Resulting condition for spotting enemy VIP
		cond = cond_state && cond_smoke && cond_visible && cond_angle;

		if(cond)
		{
			hud_index = playerHudCreate("vip_spotted", 320, 20, 1, (1,1,1), 1.6, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
			if(hud_index != -1) playerHudSetText(hud_index, &"MP_VIP_SPOTTED");
		}
		else playerHudDestroy("vip_spotted");
	}
}

checkProtectedVIP(victim)
{
	// No "self protection" for VIPs
	if(self IsVIP()) return 0;

	team = self.pers["team"];
	vip = level.vip_player[team];

	// Condition on distance to VIP
	if(isDefined(vip) && isPlayer(vip) && (vip.sessionstate == "playing"))
		cond_dist = (distance(victim.origin, vip.origin) <= level.vipprotectiondistance);
	else
		cond_dist = false;

	// Condition on time since last damage to VIP
	if(isDefined(vip) && isPlayer(vip) && (vip.sessionstate == "playing") && isDefined(victim.last_VIP_damage_time))
		cond_time = ((getTime() - victim.last_VIP_damage_time) < level.vipprotectiontime * 1000);
	else cond_time = false;

	if(cond_dist || cond_time)
	{
		iprintln(&"MP_VIP_PROTECTED_VIP", [[level.ex_pname]](self));
		return(level.pointsforprotectingvip);
	}
	else return(0);
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
