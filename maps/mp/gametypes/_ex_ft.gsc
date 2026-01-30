#include extreme\_ex_weapons;
#include extreme\_ex_hudcontroller;

/*QUAKED mp_tdm_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.*/

/*------------------------------------------------------------------------------
Freeze-Tag Mod version 1.3
	Written by MedicMan
	For information or Questions: james@mayrinckevans.com

Credits:
	Models: UKUFTaFFyTuck
	Sounds: BritishBulldog1, MedicMan
	Additional scripting help: MSJeta1
Special Thanks to:
	The makers of AWE, eXtreme+ and PowerServer
	All the fellow gamers who put up with my testing requests
	My wife for putting up with me when I lock myself in the office
	to play and mod Call of Duty.
Converted for eXtreme+ 2.7 by PatmanSan

Objective:
	Score points for your team by freezing players on the opposing team
Map ends:
	When one team reaches the score limit, or entire team is frozen, or time limit is reached
Respawning:
	No wait / Near teammates

Level requirements
------------------
Spawnpoints:
	classname		mp_tdm_spawn
	All players spawn from these. The spawnpoint chosen is dependent on the current
	locations of teammates and enemies at the time of spawn. Players generally spawn
	behind their teammates relative to the direction of enemies.

Spectator Spawnpoints:
	classname		mp_global_intermission
	Spectators spawn from these and intermission is viewed from these positions.
	Atleast one is required, any more and they are randomly chosen between.

Level script requirements
-------------------------
Team Definitions:
	game["allies"] = "american";
	game["axis"] = "german";
	This sets the nationalities of the teams. Allies can be american, british, or
	russian. Axis can be german.

If using minefields or exploders:
	maps\mp\_load::main();

Optional level script settings
------------------------------
Soldier Type and Variation:
	game["american_soldiertype"] = "normandy";
	game["german_soldiertype"] = "normandy";
	This sets what character models are used for each nationality on a particular map.

Valid settings:
	american_soldiertype	normandy
	british_soldiertype		normandy, africa
	russian_soldiertype		coats, padded
	german_soldiertype		normandy, africa, winterlight, winterdark
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
			[[level.ex_PrecacheStatusIcon]]("hud_stat_frozen");
		}
		[[level.ex_PrecacheString]](&"MP_TIME_TILL_SPAWN");
		[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SPAWN");

		[[level.ex_PrecacheString]](&"FT_UNFREEZE_HINT");
		[[level.ex_PrecacheString]](&"FT_UNFREEZE_YOU");
		[[level.ex_PrecacheString]](&"FT_UNFREEZE_ME");
		[[level.ex_PrecacheString]](&"FT_YOUAREFROZEN");
		[[level.ex_PrecacheString]](&"FT_ROUND_DEAD");
		[[level.ex_PrecacheString]](&"FT_NEXT_ROUND");
		[[level.ex_PrecacheString]](&"FT_WEAPON_STEAL");
		[[level.ex_PrecacheString]](&"FT_WEAPON_CHANGE");
		[[level.ex_PrecacheString]](&"FT_WEAPON_KEEP");
		[[level.ex_PrecacheString]](&"FT_WEAPON_KEEP_CURRENT");
		[[level.ex_PrecacheString]](&"FT_WEAPON_KEEP_SPAWN");

		[[level.ex_PrecacheShader]]("hudStopwatch");
		[[level.ex_PrecacheShader]]("hudstopwatchneedle");

		[[level.ex_PrecacheModel]]("xmodel/icecubeblue1");
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

	// load freezetag fx
	level.ft_laserfx = [[level.ex_PrecacheEffect]]("fx/ft/laservision.efx");
	level.ft_smokefx = [[level.ex_PrecacheEffect]]("fx/misc/snow_impact_small.efx");

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);

	level.progressBarY = 104;
	level.progressBarHeight = 12;
	level.progressBarWidth = 192;

	// set score update flag. Used to remove the double score bug
	level.ft_scoreupdate = 0;
	level.roundended = false;
	level.mapended = false;
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
		//level thread debugMonitor();
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

	self.frozenstate = "unfrozen";
	self.frozenstatus = 0;
	self.frozencount = 0;
	self.spawnfrozen = 0;

	// check history for reconnecting players
	if(level.ft_history && !isDefined(self.pers["skiphistory"])) self checkHistory();
	self.pers["skiphistory"] = undefined;

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
	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator" && (self.frozenstate == "frozen" || isDefined(self.spawned)) )
	{
		if(self.frozenstate == "frozen")
		{
			if(isDefined(self.icecube)) self.icecube delete();
			status_cvar = self.name + ",FROZEN";
		}
		else status_cvar = self.name + ",DEAD";

		if(level.ft_history)
		{
			if(!isDefined(game["checknumber"])) game["checknumber"] = 0;
			game["checknumber"]++;
			if(game["checknumber"] > level.ft_history) game["checknumber"] = 1;
			setcvar("ft_history" + game["checknumber"], status_cvar);
			iprintln(&"FT_HISTORY_ADD", [[level.ex_pname]](self));
			//logprint("FREEZETAG disconnect: player added to FT history (" + status_cvar + ")\n");
		}
	}

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

				// check if damage is greater than current health. If it is, freeze the player
				if(iDamage >= self.health)
				{
					self.frozencount++;
					if(self.frozencount < level.ft_maxfreeze) self thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
						else self finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

					self.pers["death"]++;
					self.deaths = self.pers["death"];
				}
				else
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

				// check if damage is greater than current health. If it is, freeze the player
				if(iDamage >= eAttacker.health)
				{
					eAttacker.frozencount++;
					if(eAttacker.frozencount < level.ft_maxfreeze) eAttacker thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
						else eAttacker finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

					eAttacker.pers["death"]++;
					eAttacker.deaths = eAttacker.pers["death"];
					eAttacker thread [[level.pscoreproc]](-1);
				}
				else eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

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

				// check if damage is greater than current health. If it is, freeze the player
				if(iDamage >= self.health)
				{
					self.frozencount++;
					if(self.frozencount < level.ft_maxfreeze) self thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
						else self finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

					self.pers["death"]++;
					self.deaths = self.pers["death"];
					eAttacker thread [[level.pscoreproc]](-1);
				}
				else self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				// check if damage is greater than current health. If it is, freeze the player
				if(iDamage >= eAttacker.health)
				{
					eAttacker.frozencount++;
					if(eAttacker.frozencount < level.ft_maxfreeze) eAttacker thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
						else eAttacker finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

					eAttacker.pers["death"]++;
					eAttacker.deaths = eAttacker.pers["death"];
				}
				else eAttacker finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				self thread maps\mp\gametypes\_shellshock::shellshockOnDamage(sMeansOfDeath, iDamage);
				self playrumble("damage_heavy");

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

			// check if damage is greater than current health. If it is, freeze the player
			if(iDamage >= self.health)
			{
				self.frozencount++;
				if(self.frozencount < level.ft_maxfreeze) self thread freezePlayer(eAttacker, sWeapon, sMeansOfDeath);
					else self finishPlayerDamage(eInflictor, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

				self.pers["death"]++;
				self.deaths = self.pers["death"];
				if(isPlayer(eAttacker) && eAttacker != self) eAttacker thread [[level.pscoreproc]](level.ft_points_freeze);
			}
			else self finishPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

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

	if(self.frozenstate == "frozen" || (level.ex_logdamage && self.sessionstate != "dead"))
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

		if(self.frozenstate == "frozen")
		{
			if(!isDefined(friendly) || friendly == 2)
				logPrint("F;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

			if(isDefined(friendly) && eAttacker.sessionstate != "dead")
			{
				lpselfguid = lpattackguid;
				lpselfnum = lpattacknum;
				lpselfname = lpattackname;
				logPrint("F;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
			}
		}
		else
		{
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
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator") return;
	if(game["matchpaused"]) return;

	// save some player info for weapon restore and exchange feature
	if(!isDefined(self.switching_teams) && !self.terminate_reason) self weaponSave();

	level thread updateTeamStatus();

	self.ex_confirmkill = 0;

	self thread extreme\_ex_main::explayerkilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	// If the player was killed by a head shot, let players know it was a head shot kill
	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE") sMeansOfDeath = "MOD_HEAD_SHOT";

	// send out an obituary message to all clients about the kill
	self thread extreme\_ex_obituary::main(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc);

	self maps\mp\gametypes\_weapons::dropWeapon();
	self maps\mp\gametypes\_weapons::dropOffhand();

	self.sessionstate = "dead";

	// make sure this comes after setting sessionstate
	if(self.frozenstate == "frozen")
	{
		self.killedfrozen = 1;
		self thread unfreezePlayer();
	}

	playerHudSetStatusIcon("hud_status_dead");
	self.dead_origin = self.origin;
	self.dead_angles = self.angles;

	if(!isDefined(self.switching_teams))
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
				if(self.killedfrozen) self.spawnfrozen = 1;

				if((self.leaving_team == "allies" && self.joining_team == "axis") || (self.leaving_team == "axis" && self.joining_team == "allies"))
				{
					players = maps\mp\gametypes\_teams::CountPlayers();
					players[self.leaving_team]--;
					players[self.joining_team]++;

					if((players[self.joining_team] - players[self.leaving_team]) > 1) self thread [[level.pscoreproc]](-1);
				}
			}
			// catch those who blew themselves up
			else if(sWeapon == "none" && sMeansOfDeath == "MOD_SUICIDE")
			{
				if(self.killedfrozen)
				{
					self.frozencount = 999;

					// cheat with /kill when frozen
					if(!self.terminate_reason)
					{
						iprintln(&"FT_ALL_OUT_CHEAT", [[level.ex_pname]](self));
						self iprintlnbold(&"FT_YOU_OUT_CHEAT");
						self.terminate_reason = 1;
					}
					// time-out suicide
					else
					{
						iprintln(&"FT_ALL_OUT_TIME", [[level.ex_pname]](self));
						self iprintlnbold(&"FT_YOU_OUT_TIME");
					}
				}
				// held a nade too long
				else self.spawnfrozen = 2;
			}
			// catch those who were killed in a minefield
			else if(sWeapon == "minefield" && sMeansOfDeath == "MOD_EXPLOSIVE") self.spawnfrozen = 3;

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

			points = level.ft_points_freeze + reward_points;

			if(self.pers["team"] == lpattackteam) // killed by a friendly
			{
				if(level.ex_reward_teamkill) attacker thread [[level.pscoreproc]](0 - points);
					else attacker thread [[level.pscoreproc]](0 - level.ex_points_kill);
			}
			else attacker thread [[level.pscoreproc]](points, "bonus", reward_points);
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

	/*
	logprint("FREEZETAG killed: player " + self.name +
		", killedfrozen = " + self.killedfrozen +
		", spawnfrozen = " + self.spawnfrozen +
		", frozencount " + self.frozencount +
		", terminate_reason " + self.terminate_reason +
		", sWeapon = " + sWeapon +
		", sMeansOfDeath = " + sMeansOfDeath + "\n");
	*/

	if(self.frozencount >= level.ft_maxfreeze && !self.terminate_reason)
	{
		iprintln(&"FT_ALL_OUT_LIMIT", [[level.ex_pname]](self));
		self iprintlnbold(&"FT_YOU_OUT_LIMIT");
	}

	if(!isDefined(self.switching_teams))
	{
		if(self.spawnfrozen)
			logPrint("F;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
		else
			logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
	else self.ex_team_changed = true;

	// Stop thread if map ended on this death
	if(level.mapended) return;

	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	//body = self cloneplayer(deathAnimDuration);
	//thread maps\mp\gametypes\_deathicons::addDeathicon(body, self.clientid, self.pers["team"], 5);
	
	delay = 2; // Delay the player becoming a spectator till after he's done dying
	if(self.frozencount >= level.ft_maxfreeze)
	{
		self.spawned = 1;
		self thread respawn_staydead(delay);
	}
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

	self extreme\_ex_main::exPreSpawn();
	
	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);

	if(self.spawnfrozen == 2 && isDefined(self.dead_origin) && isDefined(self.dead_angles))
	{
		self spawn(self.dead_origin, self.dead_angles);
	}
	else if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	self.dead_origin = undefined;
	self.dead_angles = undefined;

	level updateTeamStatus();

	if(!isDefined(self.pers["savedmodel"])) maps\mp\gametypes\_models::getModel();
		else maps\mp\gametypes\_models::loadModel(self.pers["savedmodel"]);

	extreme\_ex_weapons::loadout();

	if(game["scorelimit"] > 0) self setClientCvar("cg_objectiveText", &"FT_OBJECTIVE_SCORE", game["scorelimit"]);
		else self setClientCvar("cg_objectiveText", &"FT_OBJECTIVE");

	self thread updateTimer();

	waittillframeend;

	self.killedfrozen = 0;
	self.terminate_reason = 0;
	self.unfreezing = 0;
	self.beingunfroze = 0;
	self.foundinbinocs = 0;
	self.foundeligible = 0;
	self.foundenemy = 0;

	self extreme\_ex_main::exPostSpawn();

	if(self.spawnfrozen == 1) self thread freezePlayer(undefined, "empty", "empty");
		else if(self.spawnfrozen > 1) self thread freezePlayer(self, "empty", "empty");

	self thread hudScan();
	self thread frozenTracker();

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

	/*
	if(!level.forcerespawn)
	{
		self thread waitRespawnButton();
		self waittill("respawn");
	}
	*/

	// wait for callback to end
	wait 0;

	self thread spawnPlayer();
}

startGame()
{
	thread startRound();
}

startRound()
{
	level endon("round_ended");

	game["matchstarted"] = true; // mainly to control UpdateTeamStatus
	game["roundnumber"]++;

	// clear history
	if(level.ft_history) thread clearHistory();

	extreme\_ex_gtcommon::createClock(game["roundlength"] * 60);

	wait( [[level.ex_fpstime]](game["roundlength"] * 60) );

	if(level.roundended) return;

	iprintln(&"MP_TIMEHASEXPIRED");

	frozen = [];
	frozen["axis"] = 0;
	frozen["allies"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isPlayer(player) && isDefined(player.pers["team"]) && player.pers["team"] != "spectator")
		{
			if(player.sessionstate == "spectator") continue;
			if(isDefined(player.spawned) || (player.frozenstatus > 0 && player.frozenstate == "frozen"))
				frozen[player.pers["team"]]++;
		}
	}

	if(frozen["axis"] > frozen["allies"]) thread endRound("allies");
		else if(frozen["axis"] < frozen["allies"]) thread endRound("axis");
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

	extreme\_ex_main::exEndRound();

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player))
		{
			player notify("end_unfreeze");

			// optionally unfreeze frozen players
			//if(player.frozenstate == "frozen") player.frozenstatus = 0;

			// clean the hud
			player hudDestroy(true);
			playerHudDestroy("respawn_staydead");

			// make sure this player bypasses history check
			player.pers["skiphistory"] = true;

			// save weapons for new rounds
			if(level.ft_weaponsteal_keep && isDefined(player) && isDefined(player.pers["team"]) && (player.pers["team"] != "spectator") && (player.sessionteam != "spectator"))
				player thread weaponEndRoundSave();

			// disable weapons during delay
			player [[level.ex_dWeapon]]();
		}
	}

	hud_index = levelHudCreate("timer_nextround", undefined, 0, -50, 1, (1,1,0), 2, 1, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		levelHudSetLabel(hud_index, &"FT_NEXT_ROUND");
		levelHudSetTimer(hud_index, level.ft_roundend_delay);
	}
	wait( [[level.ex_fpstime]](level.ft_roundend_delay) );
	if(hud_index != -1) levelHudDestroy(hud_index);

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
		timelimit = getCvarFloat("scr_ft_timelimit");
		if(game["timelimit"] != timelimit)
		{
			if(timelimit > 1440)
			{
				timelimit = 1440;
				setCvar("scr_ft_timelimit", "1440");
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

		scorelimit = getCvarInt("scr_ft_scorelimit");
		if(game["scorelimit"] != scorelimit)
		{
			game["scorelimit"] = scorelimit;
			setCvar("ui_scorelimit", game["scorelimit"]);

			if(game["matchstarted"]) checkScoreLimit();
		}

		roundlimit = getCvarInt("scr_ft_roundlimit");
		if(game["roundlimit"] != roundlimit)
		{
			game["roundlimit"] = roundlimit;
			setCvar("ui_roundlimit", game["roundlimit"]);

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

	level.existed["allies"] = level.exist["allies"];
	level.existed["axis"] = level.exist["axis"];
	level.exist["allies"] = 0;
	level.exist["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing" && player.frozenstate != "frozen")
			level.exist[player.pers["team"]]++;
	}

	if(level.roundended || game["matchpaused"]) return;

	playercount = maps\mp\gametypes\_teams::CountPlayers();
	if(playercount["allies"] > 0 && playercount["axis"] > 0)
	{
		// if both allies and axis were there and now they are both frozen in the same instance
		if(level.existed["allies"] && !level.exist["allies"] && level.existed["axis"] && !level.exist["axis"])
		{
			iprintlnbold(&"MP_ROUNDDRAW");
			level thread endRound("draw");
			return;
		}

		// if allies were there and now they are not
		if(level.existed["allies"] && !level.exist["allies"])
		{
			level.allied_eliminated = true;
			iprintlnbold(&"MP_ALLIESHAVEBEENELIMINATED");
			level thread [[level.ex_psop]]("mp_announcer_allieselim");
			level thread endRound("axis");
			return;
		}

		// if axis were there and now they are not
		if(level.existed["axis"] && !level.exist["axis"])
		{
			level.axis_eliminated = true;
			iprintlnbold(&"MP_AXISHAVEBEENELIMINATED");
			level thread [[level.ex_psop]]("mp_announcer_axiselim");
			level thread endRound("allies");
			return;
		}
	}
	else
	{
		// one team forfeited. No points to be scored, just start new round
		if(playercount["allies"] == 0 && level.existed["allies"] > 0)
		{
			iprintlnbold(&"FT_ALLIES_FORFEITED");
			level thread endRound("draw");
		}

		if(playercount["axis"] == 0 && level.existed["axis"] > 0)
		{
			iprintlnbold(&"FT_AXIS_FORFEITED");
			level thread endRound("draw");
		}
	}
}

// *****************************************************************************

freezePlayer(eAttacker, sWeapon, sMeansOfDeath)
{
	// sometimes a suicide nade triggers a freeze through ft::Callback_PlayerDamage
	// even though it is handled by ft::Callback_PlayerKilled as well.
	// 4:29 K;0;10;axis;CLAN|PatmanSan;0;10;axis;CLAN|PatmanSan;none;100000;MOD_SUICIDE;none
	// 4:29 F;0;10;axis;CLAN|PatmanSan;0;10;axis;CLAN|PatmanSan;frag_grenade_british_mp;174;MOD_GRENADE_SPLASH;none
	if(self.spawnfrozen == 2 && isDefined(eAttacker) && eAttacker == self && isWeaponType(sWeapon, "frag") && sMeansOfDeath == "MOD_GRENADE_SPLASH") return;

	if(self.spawnfrozen != 3 && self.frozenstate == "frozen") return;
	self.frozenstate = "frozen";
	self.frozenstatus = 100;

	// let ft::Callback_PlayerDamage finish first
	wait(0);

	self.unfreezing = 0;
	self.beingunfroze = 0;

	self stopShellshock();
	self stoprumble("damage_heavy");

	if(!isDefined(sWeapon)) sWeapon = "empty";
	if(!isDefined(sMeansOfDeath)) sMeansOfDeath = "empty";

	/*
	logprint("FREEZETAG freeze: player " + self.name +
		", killedfrozen = " + self.killedfrozen +
		", spawnfrozen = " + self.spawnfrozen +
		", frozencount " + self.frozencount +
		", terminate_reason " + self.terminate_reason +
		", sWeapon = " + sWeapon +
		", sMeansOfDeath = " + sMeansOfDeath + "\n");
	*/

	// release the fire button to stop firing, and press the use button to get off the turret
	if(isDefined(self.onturret)) self.forceoffturret = true;

	// save some player info for weapon restore and exchange feature
	if(sWeapon != "empty") self weaponSave();

	// self kill by minefield when handled by ft::Callback_PlayerDamage
	if(sWeapon == "minefield" && sMeansOfDeath == "MOD_EXPLOSIVE")
	{
		self iprintlnbold(&"FT_FROZEN_BY_MINE");

		// kill running player threads
		self notify("kill_thread");
		self notify("killed_player");
		wait(0);

		// respawn the player away from minefield
		self.spawnfrozen = 3;
		self spawnPlayer();
		// quit because this procedure will be called again by spawnPlayer()
		return;
	}

	// self.spawnfrozen:
	// 0 = disabled
	// 1 = switching teams manually or auto-balanced (set by ft::Callback_PlayerKilled)
	// 2 = suicide nade (set by ft::Callback_PlayerKilled)
	// 3 = minefield (set by ft::Callback_PlayerKilled or section above)
	// 4 = reconnect when frozen (set by checkHistory)
	// 5 = reconnect when waiting for next round (set by checkHistory)

	if(self.spawnfrozen > 1)
	{
		// suicide nade or minefield
		if(self.spawnfrozen == 2 || self.spawnfrozen == 3) self weaponRestore();
		// reconnect when frozen
		else if(self.spawnfrozen == 4)
		{
			iprintln(&"FT_ALL_RECON_FROZEN", [[level.ex_pname]](self));
			self iprintlnbold(&"FT_YOU_RECON_FROZEN");
		}
		// reconnect when waiting for next round
		else if(self.spawnfrozen == 5) self thread frozenTermination(5);
	}

	if(isDefined(eAttacker) && isPlayer(eAttacker))
	{
		if(eAttacker == self) iprintln(&"FT_FROZEN_HIMSELF", [[level.ex_pname]](self));
			else if(eAttacker.pers["team"] == self.pers["team"]) iprintln(self.name, &"FT_FROZEN_BY_FRIEND", [[level.ex_pname]](eAttacker));
				else iprintln(self.name, &"FT_FROZEN_BY", [[level.ex_pname]](eAttacker));
	}

	// force the player to stand on normal freeze, i.e. if not forced to spawn frozen
	if(!self.spawnfrozen) self extreme\_ex_utils::forceto("stand");
	self.spawnfrozen = 0;

	// put up the icecube, and lock the players in place
	if(!isDefined(self.icecube)) self.icecube = spawn("script_model", self.origin);
	self.icecube setmodel("xmodel/icecubeblue1");
	self.icecube.origin = self.origin;
	self.icecube.angles = self.angles;
	self.icecube rotateto((0,0,90), .05);
	self linkTo(self.icecube);

	if(!level.ft_balance_frozen) self.dont_auto_balance = 1;

	playerHudSetStatusIcon("hud_stat_frozen");

	// display frozen bar and text
	hud_index = playerHudCreate("ft_progressback", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

	hud_index = playerHudCreate("ft_progressbar", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
	if(hud_index != -1)
	{
		freezebar = int(self.frozenstatus * (level.progressBarWidth / 100));
		playerHudSetShader(hud_index, "white", freezebar, level.progressBarHeight);
	}

	hud_index = playerHudCreate("ft_frozentext", 0, level.progressBarY + 20, 1, (1,1,1), 1.6, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetText(hud_index, &"FT_YOUAREFROZEN");

	// show optional clock
	if(level.ft_unfreeze_mode) self thread frozenWindowClock(level.ft_unfreeze_mode_window);

	// play freezing sound
	self thread playFreezeFX("freeze", undefined);

	// force them to throw a nade if holding it
	self freezecontrols(true);
	wait(0);
	self freezecontrols(false);

	// disable the frozen player's weapons
	self [[level.ex_dWeapon]]();
	if(level.ex_ranksystem) self thread extreme\_ex_ranksystem::wmdStop();

	self thread playBreathFX();

	level updateTeamStatus();
}

frozenWindowClock(time)
{
	self endon("kill_thread");

	hud_index = playerHudCreate("ft_frozenclock", 6, 76, 1, (1,1,1), 1, 0, "left", "top", "left", "top", false, false);
	if(hud_index != -1) playerHudSetClock(hud_index, time, time, "hudStopwatch", 48, 48);

	timer = time;
	while(timer)
	{
		wait( [[level.ex_fpstime]](1) );
		if(self.frozenstatus == 0)
		{
			playerHudDestroy("ft_frozenclock");
			return;
		}

		timer--;
	}

	if(level.roundended || level.mapended) return;

	switch(level.ft_unfreeze_mode)
	{
		case 1:
			self.terminate_reason = 2;
			self suicide();
			break;
		case 2:
			if(self.frozenstate == "frozen") self.frozenstatus = 0;
			break;
	}
}

frozenTermination(time)
{
	self endon("kill_thread");

	iprintln(&"FT_ALL_RECON_DEAD", [[level.ex_pname]](self));
	self iprintlnbold(&"FT_YOU_RECON_DEAD");

	wait( [[level.ex_fpstime]](time) );

	if(level.roundended || level.mapended) return;

	self.frozencount = 999;
	self.terminate_reason = 3;
	self suicide();
}

unfreezePlayer()
{
	self endon("disconnect");

	self.health = self.maxhealth;
	self hudDestroy(false);
	self notify("unfrozen");

	if(isDefined(self.icecube))
	{
		self unlink();
		self.icecube delete();
	}

	self.frozenstate = "unfrozen";
	self.frozenstatus = 0;
	self.unfreeze_pending = undefined;

	// spawn at another location
	if(self.sessionstate != "dead")
	{
		if(level.ft_unfreeze_respawn)
		{
			spawnpointname = "mp_tdm_spawn";
			spawnpoints = getentarray(spawnpointname, "classname");
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam_Unfrozen(spawnpoints);
			if(isDefined(spawnpoint))
			{
				self setOrigin(spawnpoint.origin);
				self setplayerangles(spawnpoint.angles);
			}
		}
		self [[level.ex_eWeapon]]();
		playerHudRestoreStatusIcon();
	}

	self.dont_auto_balance = undefined;
}

hudScan()
{
	self endon("kill_thread");
	self endon("spawned");

	// randomize execution, so the thread won't run at the same time for all players.
	// Especially needed to spread the load after a map_restart (round based games)
	wait( [[level.ex_fpstime]](randomFloat(.5)) );

	while(1)
	{
		wait( [[level.ex_fpstime]](.5) );

		if(self.foundeligible || self.foundinbinocs)
		{
			hud_index = playerHudIndex("ft_unfreezehint");
			if(hud_index == -1) hud_index = playerHudCreate("ft_unfreezehint", 0, 160, 1, (0.980,0.996,0.388), 1.6, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
			if(hud_index != -1) playerHudSetText(hud_index, &"FT_UNFREEZE_HINT");
		}
		else playerHudDestroy("ft_unfreezehint");

		if(self.unfreezing || self.beingunfroze)
		{
			hud_index = playerHudIndex("ft_unfreezetext");
			if(hud_index == -1) hud_index = playerHudCreate("ft_unfreezetext", 580, 130, 1, (1,1,1), 1.2, 0, "left", "top", "center", "middle", false, false);
			if(hud_index != -1)
			{
				if(self.unfreezing) playerHudSetText(hud_index, &"FT_UNFREEZE_YOU");
					else playerHudSetText(hud_index, &"FT_UNFREEZE_ME");
			}
		}
		else playerHudDestroy("ft_unfreezetext");

		if(level.ft_weaponsteal && self.foundenemy)
		{
			hud_index = playerHudIndex("ft_stealtext");
			if(hud_index == -1) hud_index = playerHudCreate("ft_stealtext", 0, 200, 1, (0.980,0.996,0.388), 1.6, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
			if(hud_index != -1) playerHudSetText(hud_index, &"FT_WEAPON_STEAL");
		}
		else playerHudDestroy("ft_stealtext");
	}
}

hudDestroy(all)
{
	self endon("disconnect");

	playerHudDestroy("ft_progressback");
	playerHudDestroy("ft_progressbar");
	playerHudDestroy("ft_frozentext");
	playerHudDestroy("ft_frozenclock");
	if(all)
	{
		playerHudDestroy("ft_unfreezehint");
		playerHudDestroy("ft_unfreezetext");
		playerHudDestroy("ft_stealtext");
	}
}

frozenTracker()
{
	self endon("kill_thread");
	self endon("spawned");

	// randomize execution, so the thread won't run at the same time for all players.
	// Especially needed to spread the load after a map_restart (round based games)
	wait( [[level.ex_fpstime]](randomFloat(.5)) );

	while(isDefined(self) && isAlive(self))
	{
		wait( [[level.ex_fpstime]](.5) );

		// if frozen, only check for unfreeze
		if(self.frozenstate == "frozen")
		{
			self.foundinbinocs = 0;
			self.foundeligible = 0;
			self.foundenemy = 0;

			// unfreeze player if frozenstatus drops to zero
			if(self.frozenstatus == 0) self unfreezePlayer();
		}
		// if binocs are up, check for laservision unfreeze targets
		else if(level.ft_unfreeze_laser && self.ex_binocuse)
		{
			frozen_player = self checkFrozenPlayers("laser", false, level.ft_unfreeze_laser_dist);

			if(frozen_player != self && self.frozenstate != "frozen")
			{
				self.foundinbinocs = 1;

				if(self usebuttonpressed()) self unfreezePlayerStatus(frozen_player); // do not thread
			}
			else self.foundinbinocs = 0;
		}
		// check for close proximity unfreezes and weapon exchanges
		else
		{
			self.foundinbinocs = 0;
			frozen_player = self checkFrozenPlayers("prox", false, level.ft_unfreeze_prox_dist);

			if(frozen_player != self && self.frozenstate != "frozen")
			{
				self.foundeligible = 1;

				if(self useButtonPressed()) self unfreezePlayerStatus(frozen_player); // do not thread
			}
			else self.foundeligible = 0;

			// check for weapon exchange targets if no frozen teammate is nearby
			if(!self.foundeligible && level.ft_weaponsteal)
			{
				frozen_player = self checkFrozenPlayers("prox", true, level.ft_unfreeze_prox_dist);

				if(frozen_player != self && self.frozenstate != "frozen")
				{
					self.foundenemy = 1;

					if(!isDefined(self.pers["isbot"]))
					{
						if(self useButtonPressed()) self weaponExchange(frozen_player);
						if(self meleeButtonPressed()) self grenadeSteal(frozen_player);
					}
				}
				else self.foundenemy = 0;
			}
		}
	}
}

checkFrozenPlayers(mode, check_enemy, check_dist)
{
	self endon("kill_thread");
	self endon("spawned");

	eligible_player = self;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(!isDefined(player) || !isAlive(player) || player == self) continue;
		if(isDefined(player.pers["team"]) && (player.pers["team"] == "spectator" || player.sessionteam == "spectator")) continue;
		if(check_enemy && player.pers["team"] == self.pers["team"]) continue;
		if(!check_enemy && player.pers["team"] != self.pers["team"]) continue;
		if(check_dist)
		{
			if(mode == "prox" && distance(player.origin, self.origin) > check_dist) continue;
			if(mode == "laser" && distance(player.origin, self.origin) > check_dist) continue;
		}
		if(self islookingat(player) && player.frozenstatus > 0 && player.frozenstate == "frozen")
		{
			eligible_player = player;
			break;
		}
	}

	return eligible_player;
}

unfreezePlayerStatus(frozen_player)
{
	self endon("kill_thread");
	self endon("spawned");

	self.unfreezing = 1;
	frozen_player.beingunfroze = 1;

	// unfreeze loops every half a sec, so divide by 2 to get correct unfreeze amount
	if(self.foundinbinocs) unfreeze_amount = int( (100 / level.ft_unfreeze_laser_time) / 2);
		else unfreeze_amount = int( (100 / level.ft_unfreeze_prox_time) / 2);
	if(unfreeze_amount == 0) unfreeze_amount = 1;

	// add unfreezing status bar
	hud_index = playerHudCreate("ft_progressback", 0, level.progressBarY, 0.5, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, "black", level.progressBarWidth, level.progressBarHeight);

	hud_index = playerHudCreate("ft_progressbar", level.progressBarWidth / -2, level.progressBarY, 1, (1,1,1), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
	if(hud_index != -1)
	{
		freezebar = int(frozen_player.frozenstatus * (level.progressBarWidth / 100));
		playerHudSetShader(hud_index, "white", freezebar, level.progressBarHeight);
	}

	// play unfreeze fx
	if(!self.foundinbinocs)
		self thread playFreezeFX("unfreeze", frozen_player);

	timer = 0;

	while(isDefined(self) && isDefined(frozen_player) && self useButtonPressed() && frozen_player.frozenstatus > 0)
	{
		if(!self.foundinbinocs && level.ft_unfreeze_prox_dist && distance(self.origin, frozen_player.origin) > level.ft_unfreeze_prox_dist) break;

		if(self.foundinbinocs && (!self.ex_binocuse || !(self islookingat(frozen_player))) ) break;

		if(!self useButtonPressed()
		|| !isAlive(self)
		|| !isAlive(frozen_player)
		|| self.sessionstate != "playing"
		|| frozen_player.sessionstate != "playing"
		|| self.frozenstate == "frozen") break;

		if(!timer)
		{
			// shoot laser
			if(self.foundinbinocs)
			{
				self thread playLaserFX(frozen_player);
				wait( [[level.ex_fpstime]](.05) );
			}

			// play unfreeze smoke efx
			if(!self.foundinbinocs)
			{
				playereye = frozen_player geteye();
				playfx(level.ft_smokefx, playereye);
			}

			timer = 2;
		}

		frozen_player.frozenstatus = frozen_player.frozenstatus - unfreeze_amount;
		if(frozen_player.frozenstatus < 0) frozen_player.frozenstatus = 0;

		// update unfreezing status bar
		freezebar = int(frozen_player.frozenstatus * (level.progressBarWidth / 100));
		playerHudSetShader("ft_progressbar", "white", freezebar, level.progressBarHeight);

		// update status bar for frozen player
		frozen_player playerHudSetShader("ft_progressbar", "white", freezebar, level.progressBarHeight);

		if(frozen_player.frozenstatus == 0)
		{
			self thread finishUnfreeze(frozen_player, false);
			break;
		}

		wait( [[level.ex_fpstime]](.5) );
		timer--;
	}

	if(isDefined(self))
	{
		self.unfreezing = 0;
		if(self.foundinbinocs)
		{
			self thread playFreezeFX("binocs", frozen_player);
			self.foundinbinocs = 0;
		}
	}

	if(isDefined(frozen_player))
		frozen_player.beingunfroze = 0;

	playerHudDestroy("ft_progressback");
	playerHudDestroy("ft_progressbar");
}

finishUnfreeze(frozen_player, raygun)
{
	// no need to unfreeze here; this is done by frozenTracker!
	iprintln(frozen_player.name, &"FT_UNFROZEN_BY", [[level.ex_pname]](self));

	// record it in the logs
	ft_selfnum = self getEntityNumber();
	ft_woundnum = frozen_player getEntityNumber();
	ft_selfGuid = self getGuid();
	ft_woundGuid = frozen_player getGuid();
	if(raygun) type = "MP_RAYGUN";
		else if(self.foundinbinocs) type = "MP_LASERVISION";
			else type = "MP_STANDNEAR";
	logprint("U;" + ft_selfGuid + ";" + ft_selfnum + ";" + self.name + ";" + ft_woundGuid + ";" + ft_woundnum + ";" + frozen_player.name + ";" + type + "\n");

	// give points
	self thread [[level.pscoreproc]](level.ft_points_unfreeze);
}

playLaserFX(frozen_player)
{
	self endon("kill_thread");
	self endon("spawned");

	playereye = frozen_player geteye();
	vectortoplayer = vectornormalize(playereye - self.ex_eyemarker.origin);
	fx_origin = self.ex_eyemarker.origin;

	level thread extreme\_ex_utils::playSoundLoc("ft_laser", self.origin);
	playfx(level.ft_laserfx, fx_origin, vectortoplayer);

	if(frozen_player.frozenstate == "frozen")
	{
		playfx(level.ft_smokefx, playereye);
		frozen_player playLocalSound("ft_sandbag_snow");
		wait( [[level.ex_fpstime]](1) );
		if(isPlayer(frozen_player)) frozen_player playlocalSound("ft_melt");
	}
}

playFreezeFX(condition, frozen_player)
{
	self endon("kill_thread");
	self endon("spawned");

	if(condition == "freeze")
		self playLocalSound("ft_freeze");

	if(condition == "unfreeze" && isDefined(frozen_player) && !self.foundinbinocs)
	{
		wait( [[level.ex_fpstime]](.75) );
		if(isDefined(self)) self playLocalSound("ft_sandbag_snow");
		if(isDefined(frozen_player)) frozen_player playLocalSound("ft_sandbag_snow");

		wait( [[level.ex_fpstime]](.2) );
		if(isDefined(self)) self playLocalSound("ft_melt");
		if(isDefined(frozen_player)) frozen_player playLocalSound("ft_melt");

		while(isDefined(frozen_player) && frozen_player.beingunfroze)
		{
			chance = randomint(100);

			if(chance <= level.ft_soundchance)
			{
				if(isDefined(self)) self playLocalSound("ft_sandbag_snow");
				if(isDefined(frozen_player)) frozen_player playLocalSound("ft_sandbag_snow");

				wait( [[level.ex_fpstime]](.2) );
				if(isDefined(self)) self playLocalSound("ft_melt");
				if(isDefined(frozen_player)) frozen_player playLocalSound("ft_melt");
			}

			wait( [[level.ex_fpstime]](1) );
		}

		if(isDefined(self)) self playLocalSound("breathing_better");
		if(isDefined(frozen_player)) frozen_player playLocalSound("breathing_better");
	}

	if(condition == "binocs" && isDefined(frozen_player) && self.foundinbinocs)
	{
		wait( [[level.ex_fpstime]](.5) );
		if(isDefined(self)) self playLocalSound("breathing_better");
		if(isDefined(frozen_player)) frozen_player playLocalSound("breathing_better");
	}
}

playBreathFX()
{
	self endon("kill_thread");
	self endon("unfrozen");

	while(isDefined(self) && isAlive(self) && self.frozenstate == "frozen")
	{
		self pingplayer();

		// make sure the player's weapons are disabled until unfrozen!
		// don't do a self [[level.ex_dWeapon]]() here!
		if(!isDefined(self.pers["isbot"])) self disableWeapon();

		if(isDefined(self.ex_eyemarker))
		{
			angle = self getplayerangles();
			forwardvec = anglestoforward(angle);
			forward = vectornormalize(forwardvec);

			playfx(level.ex_effect["coldbreathfx"], self.ex_eyemarker.origin, forward);
		}

		wait( [[level.ex_fpstime]](3) );
	}
}

grenadeSteal(enemy)
{
	self endon("kill_thread");
	self endon("spawned");

	enemy endon("kill_thread");

	if(self.ex_sprinting) return;
	if(self.ex_binocuse) return;
	if(level.roundended || level.mapended) return;

	if(level.ft_weaponsteal_frag)
	{
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) self_currentfrags = self getammocount(self.pers["fragtype"]);
			else self_currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
		if(!isDefined(self_currentfrags)) self_currentfrags = 0;

		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) enemy_currentfrags = enemy getammocount(enemy.pers["fragtype"]);
			else enemy_currentfrags = enemy getammocount(enemy.pers["fragtype"]) + enemy getammocount(enemy.pers["enemy_fragtype"]);
		if(!isDefined(enemy_currentfrags)) enemy_currentfrags = 0;

		if(enemy_currentfrags && self_currentfrags < 9)
		{
			self_stealfrags = level.ft_weaponsteal_frag;
			if(enemy_currentfrags < self_stealfrags) self_stealfrags = enemy_currentfrags;
			if(self_currentfrags + self_stealfrags > 9) self_stealfrags = 9 - self_currentfrags;
			self_totalfrags = self_currentfrags + self_stealfrags;

			if(self_stealfrags)
			{
				self setWeaponClipAmmo(self.pers["fragtype"], self_totalfrags);
				enemy_totalfrags = enemy_currentfrags - self_stealfrags;
				enemy setWeaponClipAmmo(enemy.pers["fragtype"], enemy_totalfrags);

				if(self_stealfrags > 1)
				{
					enemy iprintlnbold(&"FT_YOUR_NADES_STOLEN", self_stealfrags);
					self iprintln(&"FT_NADES_STOLEN", self_stealfrags);
				}
				else
				{
					enemy iprintlnbold(&"FT_YOUR_NADE_STOLEN", self_stealfrags);
					self iprintln(&"FT_NADE_STOLEN", self_stealfrags);
				}
			}
		}
	}

	if(level.ft_weaponsteal_smoke)
	{
		self_currentsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
		if(!isDefined(self_currentsmokes)) self_currentsmokes = 0;

		enemy_currentsmokes = enemy getammocount(enemy.pers["smoketype"]) + enemy getammocount(enemy.pers["enemy_smoketype"]);
		if(!isDefined(enemy_currentsmokes)) enemy_currentsmokes = 0;

		if(enemy_currentsmokes && self_currentsmokes < 9)
		{
			self_stealsmokes = level.ft_weaponsteal_smoke;
			if(enemy_currentsmokes < self_stealsmokes) self_stealsmokes = enemy_currentsmokes;
			if(self_currentsmokes + self_stealsmokes > 9) self_stealsmokes = 9 - self_currentsmokes;
			self_totalsmokes = self_currentsmokes + self_stealsmokes;

			if(self_stealsmokes)
			{
				self setWeaponClipAmmo(self.pers["smoketype"], self_totalsmokes);
				enemy_totalsmokes = enemy_currentsmokes - self_stealsmokes;
				enemy setWeaponClipAmmo(enemy.pers["smoketype"], enemy_totalsmokes);

				if(self_stealsmokes > 1)
				{
					enemy iprintlnbold(&"FT_YOUR_SMOKES_STOLEN", self_stealsmokes);
					self iprintln(&"FT_SMOKES_STOLEN", self_stealsmokes);
				}
				else
				{
					enemy iprintlnbold(&"FT_YOUR_SMOKE_STOLEN", self_stealsmokes);
					self iprintln(&"FT_SMOKE_STOLEN", self_stealsmokes);
				}
			}
		}
	}
}

weaponExchange(enemy)
{
	self endon("kill_thread");
	self endon("spawned");

	enemy endon("kill_thread");

	if(self.ex_sprinting) return;
	if(self.ex_binocuse) return;
	if(level.roundended || level.mapended) return;

	my_current = self getcurrentweapon();
	my_primary = self getWeaponSlotWeapon("primary");
	my_primaryb = self getWeaponSlotWeapon("primaryb");
	if(isValidWeapon(my_current) && !isDummy(my_current))
	{
		if(my_current == my_primary) my_slot = "primary";
			else if(my_current == my_primaryb) my_slot = "primaryb";
				else my_slot = "virtual"; // should not get here

		my_current_clip = self.weapon[ self.weaponin[ my_slot ].slot ].clip;
		my_current_reserve = self.weapon[ self.weaponin[ my_slot ].slot ].reserve;
	}
	else
	{
		my_slot = "invalid";
		my_current_clip = 0;
		my_current_reserve = 0;
	}

	// if stealing of primary is allowed
	if(my_slot != "invalid" && !isWeaponType(my_current, "sidearm"))
	{
		if(!isDefined(enemy) || !isDefined(enemy.weapon) || !isDefined(enemy.weaponin)) return;

		enemy_current = enemy.weapon["primary"].name; // not really his current, but his saved primary
		enemy_primary = enemy getWeaponSlotWeapon("primary");
		enemy_primaryb = enemy getWeaponSlotWeapon("primaryb");
		if(isValidWeapon(enemy_current) && !isDummy(enemy_current))
		{
			if(enemy_current == enemy_primary) enemy_slot = "primary";
				else if(enemy_current == enemy_primaryb) enemy_slot = "primaryb";
					else enemy_slot = "virtual";

			enemy_primary_clip = enemy.weapon[ enemy.weaponin[ enemy_slot ].slot ].clip;
			enemy_primary_reserve = enemy.weapon[ enemy.weaponin[ enemy_slot ].slot ].reserve;
		}
		else
		{
			enemy_slot = "invalid";
			enemy_primary_clip = 0;
			enemy_primary_reserve = 0;
		}

		// if enemy has primary, try to take it
		if(enemy_slot != "invalid" && !isWeaponType(enemy_current, "sidearm") && enemy_primary_reserve)
		{
			// if you already have this weapon, skip to stealing ammo only
			if(enemy_current != self.weapon["primary"].name && enemy_current != self.weapon["primaryb"].name && enemy_current != self.weapon["virtual"].name)
			{
				// get weapon names, tells the player which weapon was stolen
				my_current_name = maps\mp\gametypes\_weapons::getWeaponName(my_current);
				enemy_current_name = maps\mp\gametypes\_weapons::getWeaponName(enemy_current);

				self takeWeapon(my_current);
				self setWeaponSlotWeapon(my_slot, enemy_current);
				self setWeaponSlotClipAmmo(my_slot, enemy_primary_clip);
				self setWeaponSlotAmmo(my_slot, enemy_primary_reserve);
				self switchtoweapon(enemy_current);

				enemy takeWeapon(enemy_current);
				if(enemy_slot != "virtual")
				{
					enemy setWeaponSlotWeapon(enemy_slot, my_current);
					enemy setWeaponSlotClipAmmo(enemy_slot, my_current_clip);
					enemy setWeaponSlotAmmo(enemy_slot, my_current_reserve);
					enemy switchtoweapon(my_current);
				}
				else
				{
					enemy.weapon["virtual"].name = my_current;
					enemy.weapon["virtual"].clip = my_current_clip;
					enemy.weapon["virtual"].reserve = my_current_reserve;
				}

				// tell the players about the weapon exchange
				self iprintlnbold(&"FT_WEAPON_EXCHANGED", enemy_current_name);
				enemy iprintlnbold(&"FT_WEAPON_PRI_STOLEN", my_current_name);
			}
			else
			{
				// reuse my_slot to save slot for ammo exchange
				if(enemy_current == my_primary) my_slot = "primary";
					else if(enemy_current == my_primaryb) my_slot = "primaryb";
						else my_slot = "virtual"; //if(enemy_current == self.weapon["virtual"].name)

				if(my_slot != "virtual")
				{
					if(self.weapon[ self.weaponin[my_slot].slot ].reserve < level.weapons[my_primary].ammo_limit)
						self setWeaponSlotAmmo(my_slot, self.weapon[ self.weaponin[my_slot].slot ].reserve + enemy_primary_reserve);
				}
				else
				{
					if(self.weapon[ self.weapon[my_slot]].reserve < level.weapons[my_primary].ammo_limit)
						self.weapon[my_slot].reserve += enemy_primary_reserve;
				}

				if(enemy_slot != "virtual") enemy setWeaponSlotAmmo(enemy_slot, 0);
					else enemy.weapon["virtual"].reserve = 0;

				// tell the players about the ammo exchange
				self iprintlnbold(&"FT_AMMO_ONLY_RESERVE");
				enemy iprintlnbold(&"FT_AMMO_RESERVE_STOLEN");
			}
		}
		else self iprintlnbold(&"FT_WEAPON_NOTHING");
	}
	else self iprintlnbold(&"FT_WEAPON_INVALID");

	wait( [[level.ex_fpstime]](.05) );
	while(self useButtonPressed()) wait( [[level.ex_fpstime]](.05) );
}

weaponEndRoundSave()
{
	self endon("disconnect");

	spawn_primary = self.pers["weapon1"];
	if(!isDefined(spawn_primary)) spawn_primary = "none";
	spawn_secondary = self.pers["weapon2"];
	if(!isDefined(spawn_secondary)) spawn_secondary = "none";

	new_primary = self.pers["weapon1"];
	new_secondary = self.pers["weapon2"];

	weapon = self.weapon["primary"].name; //self getWeaponSlotWeapon("primary");
	if(isValidWeapon(weapon) && !isDummy(weapon) && !isWeaponType(weapon, "sidearm")) new_primary = weapon;
	if(!isDefined(new_primary)) new_primary = "none";
	weapon = self.weapon["primaryb"].name; //self getWeaponSlotWeapon("primaryb");
	if(isValidWeapon(weapon) && !isDummy(weapon) && !isWeaponType(weapon, "sidearm")) new_secondary = weapon;
	if(!isDefined(new_secondary)) new_secondary = "none";

	hud_index = playerHudCreate("ft_saveweapon", 0, -30, 1, (1,1,1), 1.3, 1, "center_safearea", "center_safearea", "center", "middle", false, false);

	// if no new weapons, return
	if( (new_primary == spawn_primary || new_primary == spawn_secondary) && (new_secondary == spawn_primary || new_secondary == spawn_secondary) )
	{
		if(hud_index != -1) playerHudSetLabel(hud_index, &"FT_WEAPON_CHANGE");
		return;
	}
	else if(hud_index != -1) playerHudSetLabel(hud_index, &"FT_WEAPON_KEEP");

	weapons_current = 0;

	while(isPlayer(self))
	{
		wait( [[level.ex_fpstime]](.05) );

		if(isplayer(self) && self attackButtonPressed())
		{
			if(!weapons_current)
			{
				self.pers["weapon"] = new_primary;
				self.pers["weapon1"] = self.pers["weapon"];
				self.pers["weapon2"] = new_secondary;
				if(hud_index != -1) playerHudSetLabel(hud_index, &"FT_WEAPON_KEEP_CURRENT");
				weapons_current = 1;
			}
			else
			{
				self.pers["weapon"] = spawn_primary;
				self.pers["weapon1"] = self.pers["weapon"];
				self.pers["weapon2"] = spawn_secondary;
				if(hud_index != -1) playerHudSetLabel(hud_index, &"FT_WEAPON_KEEP_SPAWN");
				weapons_current = 0;
			}

			while(isPlayer(self) && self attackButtonPressed())
				wait( [[level.ex_fpstime]](.05) );
		}
	}
}

weaponSave()
{
	self endon("disconnect");

	debugLog(false, "ft::weaponSave() started"); // DEBUG

	// save primary weapon
	if(!isDefined(self.weapon["save_primary"])) self.weapon["save_primary"] = spawnstruct();
	self.weapon["save_primary"].name = self.weapon["primary"].name;
	self.weapon["save_primary"].clip = self.weapon["primary"].clip;
	self.weapon["save_primary"].reserve = self.weapon["primary"].reserve;

	// save secondary weapon
	if(!isDefined(self.weapon["save_primaryb"])) self.weapon["save_primaryb"] = spawnstruct();
	self.weapon["save_primaryb"].name = self.weapon["primaryb"].name;
	self.weapon["save_primaryb"].clip = self.weapon["primaryb"].clip;
	self.weapon["save_primaryb"].reserve = self.weapon["primaryb"].reserve;

	// save virtual weapon
	if(!isDefined(self.weapon["save_virtual"])) self.weapon["save_virtual"] = spawnstruct();
	self.weapon["save_virtual"].name = self.weapon["virtual"].name;
	self.weapon["save_virtual"].clip = self.weapon["virtual"].clip;
	self.weapon["save_virtual"].reserve = self.weapon["virtual"].reserve;

	// save nades
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) self.weapon["save_frags"] = self getammocount(self.pers["fragtype"]);
		else self.weapon["save_frags"] = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	if(!isDefined(self.weapon["save_frags"])) self.weapon["save_frags"] = 0;
	self.weapon["save_smoke"] = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	if(!isDefined(self.weapon["save_smoke"])) self.weapon["save_smoke"] = 0;

	debugLog(false, "ft::weaponSave() finished"); // DEBUG
}

weaponRestore()
{
	self endon("disconnect");

	debugLog(false, "ft::weaponRestore() called"); // DEBUG

	self takeAllWeapons();

	wait 0;

	// restore primary weapon
	if(isValidWeapon(self.weapon["save_primary"].name))
	{
		self setWeaponSlotWeapon("primary", self.weapon["save_primary"].name);
		self setWeaponSlotClipAmmo("primary", self.weapon["save_primary"].clip);
		self setWeaponSlotAmmo("primary", self.weapon["save_primary"].reserve);
	}
	else self setWeaponSlotWeapon("primary", "none");

	// restore secondary weapon
	if(isValidWeapon(self.weapon["save_primaryb"].name))
	{
		self setWeaponSlotWeapon("primaryb", self.weapon["save_primaryb"].name);
		self setWeaponSlotClipAmmo("primaryb", self.weapon["save_primaryb"].clip);
		self setWeaponSlotAmmo("primaryb", self.weapon["save_primaryb"].reserve);
	}
	else self setWeaponSlotWeapon("primaryb", "none");

	// restore virtual weapon
	self.weapon["virtual"].name = self.weapon["save_virtual"].name;
	self.weapon["virtual"].clip = self.weapon["save_virtual"].clip;
	self.weapon["virtual"].reserve = self.weapon["save_virtual"].reserve;

	// restore nades
	self giveWeapon(self.pers["fragtype"]);
	self setWeaponClipAmmo(self.pers["fragtype"], self.weapon["save_frags"]);
	self giveWeapon(self.pers["smoketype"]);
	self setWeaponClipAmmo(self.pers["smoketype"], self.weapon["save_smoke"]);

	debugLog(true, "ft::weaponRestore() finished"); // DEBUG
}

checkHistory()
{
	for(i = level.ft_history; i > 0 ; i--)
	{
		status_cvar = getcvar("ft_history" + i);
		if(isDefined(status_cvar))
		{
			token_array = strtok(status_cvar, ",");
			if(token_array.size != 2) continue;
			if(token_array[0] != self.name) continue;
			if(token_array[1] == "DEAD")
			{
				//logprint("FREEZETAG connect: player " + self.name + " found in FT history (reconnect DEAD)\n");
				iprintln(&"FT_HISTORY_HIT_DEAD", [[level.ex_pname]](self));
				self.spawnfrozen = 5;
				return;
			}
			else if(token_array[1] == "FROZEN")
			{
				//logprint("FREEZETAG connect: player " + self.name + " found in FT history (reconnect FROZEN)\n");
				iprintln(&"FT_HISTORY_HIT_FROZEN", [[level.ex_pname]](self));
				self.spawnfrozen = 4;
				return;
			}
		}
	}
}

clearHistory()
{
	for(i = 1; i <= level.ft_history; i++)
		setcvar("ft_history" + i, "*");
}

debugMonitor()
{
	level endon("round_ended");

	// debug script to end the round or to unfreeze all frozen players
	while(1)
	{
		if(getCvarInt("ft_endround") == 1)
		{
			setcvar("ft_endround", 0);

			level notify("finish_staydead");
			wait( [[level.ex_fpstime]](.1) );

			endRound("draw");
		}

		if(getCvarInt("ft_unfreeze") == 1)
		{
			setcvar("ft_unfreeze", 0);

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isDefined(player) && isDefined(player.pers["team"]) && player.pers["team"] != "spectator" && (player.frozenstate == "frozen" || isDefined(player.spawned)))
				{
					if(player.frozenstate == "frozen") player.frozenstatus = 0;
					player.spawned = undefined;
					player.frozencount = 0;
					player.spawnfrozen = 0;
					player.killedfrozen = 0;
					player.terminate_reason = 0;
				}
			}

			level notify("finish_staydead");
			wait( [[level.ex_fpstime]](.1) );
		}

		wait( [[level.ex_fpstime]](1) );
	}
}

respawn_staydead(delay)
{
	self endon("disconnect");

	self.WaitingToSpawn = true;

	if(isDefined(self.icecube))
	{
		self unlink();
		self.icecube delete();
	}

	hud_index = playerHudCreate("respawn_staydead", 0, -50, 0, (1,1,1), 2, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetText(hud_index, &"FT_ROUND_DEAD");

	wait( [[level.ex_fpstime]](delay) );
	self thread updateTimer();

	level waittill("finish_staydead");

	playerHudDestroy("respawn_staydead");

	self.spawned = undefined;
	self.WaitingToSpawn = undefined;
}

updateTimer()
{
	if(isDefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis") && isDefined(self.pers["weapon"]))
		playerHudSetAlpha("respawn_staydead", 1);
	else
		playerHudSetAlpha("respawn_staydead", 0);
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
