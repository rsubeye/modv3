
init()
{
	level.ex_cvararray = [];

	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
}

initPost()
{
	registerInfo();

	if(level.ex_forceclientcvars) [[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_forceclientcvars_loop);
}

onPlayerConnected()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(!isDefined(self.pers["cvar_onforcedloop"])) self.pers["cvar_onforcedloop"] = false;
	self.pers["cvar_inprogress"] = true;

	// 1st: onReconnect (unconditional cvar distribution)
	distributeCvars("onReconnect");

	// 2nd: onConnect
	if(!isDefined(self.pers["cvar_onconnect"])) self.pers["cvar_onconnect"] = false;
	if(!self.pers["cvar_onconnect"])
	{
		distributeCvars("onConnect");
		self.pers["cvar_onconnect"] = true;
	}

	// 3rd: onForced
	if(!isDefined(self.pers["cvar_onforced"])) self.pers["cvar_onforced"] = false;
	if(!self.pers["cvar_onforced"])
	{
		distributeCvars("onForced");
		self.pers["cvar_onforced"] = true;
	}

	// 4th: onJoined
	if(!isDefined(self.pers["cvar_onjoined"])) self.pers["cvar_onjoined"] = false;
	if(!self.pers["cvar_onjoined"])
	{
		distributeCvars("onJoined");
		self.pers["cvar_onjoined"] = true;
	}

	self.pers["cvar_inprogress"] = false;
}

onRandom(eventID)
{
	level endon("ex_gameover");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player))
		{
			if(!isDefined(player.pers) || !isDefined(player.pers["team"])) continue;

			// next player if cvar distribution is in progress
			if(!isDefined(player.pers["cvar_inprogress"]) || player.pers["cvar_inprogress"]) continue;

			// next player if this player already executed the forced cvars
			if(!isDefined(player.pers["cvar_onforcedloop"]) || player.pers["cvar_onforcedloop"]) continue;

			// send forced cvars
			if(player.sessionstate == "playing") player thread forceClientCvars();
		}

		wait( [[level.ex_fpstime]](.05) );
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}

forceClientCvars()
{
	level endon("ex_gameover");
	self endon("disconnect");

	// do not thread
	distributeCvars("onForced");

	// we set self.pers["cvar_onforcedloop"] after we're done
	if(level.ex_forceclientcvars > 1) self.pers["cvar_onforcedloop"] = true;
}

distributeCvars(callback)
{
	self endon("kill_thread");

	// check the callback
	if(!isDefined(callback)) return;
	callback = tolower(callback);
	if(!isDefined(level.ex_cvararray[callback])) return;

	self notify("cvars_" + callback);
	self endon("cvars_" + callback);

	// array to store checkfunc responses, so checkfunc is not called for every
	// cvar in that group. To increase speed, successive cvars in the same group
	// get the stored response
	groupauth = [];

	// write priority 1 cvars first, then 2, then 3
	for(priority = 1; priority <= 3; priority++)
	{
		count = 0;
		for(i = 0; i < level.ex_cvararray[callback].size; i++)
		{
			item = level.ex_cvararray[callback][i];
			if(item.enabled && item.callback == callback && item.priority == priority)
			{
				send_cvar = true;
				func_value = undefined;
				if(isDefined(item.group))
				{
					if(!isDefined(groupauth[item.group]))
						groupauth[item.group] = [[item.checkfunc]]();
					send_cvar = groupauth[item.group];
				}
				else if(isDefined(item.checkfunc))
				{
					if(item.usefuncresult) func_value = [[item.checkfunc]]();
						else send_cvar = [[item.checkfunc]]();
				}
				if(send_cvar)
				{
					if(isPlayer(self))
					{
						if(isDefined(func_value)) self setClientCvar(item.cvar, func_value);
							else self setClientCvar(item.cvar, item.value);
					}
					count++;
					switch(priority)
					{
						// send priority 1 cvars with small delay every 9 cvars
						case 1: if(count % 9 == 0) wait( [[level.ex_fpstime]](.25) ); break;
						// send priority 2 cvars with medium delay every 6 cvars
						case 2: if(count % 6 == 0) wait( [[level.ex_fpstime]](.5) ); break;
						// send priority 3 cvars with full delay every 3 cvars
						default: if(count % 3 == 0) wait( [[level.ex_fpstime]](1) );
					}
				}
			}
		}

		//if(level.ex_cvararray[callback].size)
		//	logprint("CVARS: distributing " + callback + ", priority " + priority + " cvars (" + count + "/" + level.ex_cvararray[callback].size + ") to player " + self.name + "\n");

		wait( [[level.ex_fpstime]](1) );
	}
}

/*******************************************************************************
cvar
	Name of cvar to register for distribution to client
	Required; registration will abort if not set
value
	Value to assign to cvar
	Required; registration will abort if not set
priority
	Distribution priority (1, 2 or 3; 1 = highest priority)
	Default is 1
callback
	Order of cvar distribution cvars to client:
	"onReconnect", "onConnect", "onForced" or "onJoined" (team or spec)
	Default is "onConnect"
group
	Keyword to group cvars together for conditional distribution
	If set, checkfunc is required.
checkfunc
	Pointer to a function which decides about conditional distribution
	Optional, unless group is set
usefuncresult
	Option to store checkfunc result as cvar value (value parameter will be ignored)
	Ignored if group set, because for groups groupfunc will be executed once
	True or false; default false
*******************************************************************************/
registerCvar(cvar, value, priority, callback, group, checkfunc, usefuncresult)
{
	if(!isDefined(cvar) || !isDefined(value)) return;
	if(!isDefined(priority)) priority = 1;
	if(!isDefined(callback)) callback = "onConnect";

	callback = tolower(callback);
	cvar = tolower(cvar);

	if(!isDefined(level.ex_cvararray[callback])) level.ex_cvararray[callback] = [];

	index = -1;
	for(i = 0; i < level.ex_cvararray[callback].size; i++)
	{
		if(level.ex_cvararray[callback][i].cvar == cvar)
		{
			index = i;
			break;
		}
	}

	if(index == -1)
	{
		index = level.ex_cvararray[callback].size;
		level.ex_cvararray[callback][index] = spawnstruct();
		level.ex_cvararray[callback][index].cvar = cvar;
	}

	level.ex_cvararray[callback][index].value = value;
	level.ex_cvararray[callback][index].enabled = true;
	level.ex_cvararray[callback][index].priority = priority;
	level.ex_cvararray[callback][index].callback = callback;
	if(isDefined(group))
	{
		if(!isDefined(checkfunc)) level.ex_cvararray[callback][index].enabled = false;
			else level.ex_cvararray[callback][index].group = tolower(group);
	}
	if(isDefined(checkfunc))
	{
		level.ex_cvararray[callback][index].checkfunc = checkfunc;
		if(isDefined(usefuncresult)) level.ex_cvararray[callback][index].usefuncresult = usefuncresult;
			else level.ex_cvararray[callback][index].usefuncresult = false;
	}
}

registerCvarServer(cvar, value)
{
	setCvar(cvar, value);
	makeCvarServerInfo(cvar, value);
}

registerInfo()
{
	level endon("ex_gameover");

	/*****************************************************************************
	PRIORITY 1 DVARS onReconnect (unconditional refresh on map_restart)
	*****************************************************************************/

	// health bar
	if(level.ex_healthbar == 1)
	{
		// stock healthbar on; no pulse or fade (hud.menu)
		registerCvar("cg_drawhealth", 1, 1, "onReconnect"); // stock 0 (0 or 1)
		registerCvar("hud_fade_healthbar", 0, 1, "onReconnect"); // stock 2 (0 - 30)
		registerCvar("hud_health_startpulse_injured", 0, 1, "onReconnect"); // stock 1 (0 - 1.1)
		registerCvar("hud_health_startpulse_critical", 0, 1, "onReconnect"); // stock 1 (0 - 1.1)
		//registerCvar("hud_health_pulserate_injured", 0.1, 1, "onReconnect"); // stock 0.33 (0.1 - 3)
		//registerCvar("hud_health_pulserate_critical", 0.1, 1, "onReconnect"); // stock 0.5 (0.1 - 3)
	}
	else
	{
		// stock healthbar off
		registerCvar("cg_drawhealth", 0, 1, "onReconnect"); // stock 0 (0 or 1)
		//registerCvar("hud_fade_healthbar", 2, 1, "onReconnect"); // stock 2 (0 - 30)
		//registerCvar("hud_health_startpulse_injured", 1, 1, "onReconnect"); // stock 1 (0 - 1.1)
		//registerCvar("hud_health_startpulse_critical", 1, 1, "onReconnect"); // stock 1 (0 - 1.1)
		//registerCvar("hud_health_pulserate_injured", 0.33, 1, "onReconnect"); // stock 0.33 (0.1 - 3)
		//registerCvar("hud_health_pulserate_critical", 0.5, 1, "onReconnect"); // stock 0.5 (0.1 - 3)
	}

	/*****************************************************************************
	PRIORITY 1 DVARS onConnect (for server information menu)
	*****************************************************************************/

	// time limit
	registerCvarServer("ui_timelimit", game["timelimit"]);

	// score limit
	registerCvarServer("ui_scorelimit", game["scorelimit"]);

	// player spawn delay?
	registerCvar("ui_spawndelay", level.respawndelay, 1);

	// dom, esd, lts, ons, rbcnq, rbctf, sd
	if(level.ex_roundbased)
	{
		// round limit
		registerCvarServer("ui_roundlimit", game["roundlimit"]);

		// round length
		registerCvar("ui_roundlength", game["roundlength"], 1);

		// bomb timer?
		if(level.ex_currentgt == "sd" || level.ex_currentgt == "esd")
			registerCvar("ui_bombtimer", level.bombtimer, 1);
	}

	if(level.ex_currentgt == "htf" || level.ex_currentgt == "ihtf")
	{
		// flag hold time
		registerCvar("ui_gtinfo_a", level.flagholdtime, 1);

		// flag recover time
		registerCvar("ui_gtinfo_b", level.flagrecovertime, 1);

		// flag spawn delay
		registerCvar("ui_gtinfo_c", level.flagspawndelay, 1);
	}

	// rank system
	if(!level.ex_ranksystem) rank = 0;
		else rank = level.ex_rank_wmdtype + 1;
	registerCvar("ui_rank", rank, 1);

	// weapon class
	if(level.ex_bash_only)
	{
		wepclass = 100;
	}
	else if(level.ex_frag_fest)
	{
		wepclass = 200;
	}
	else if(level.ex_all_weapons)
	{
		wepclass = 300;
	}
	else if(level.ex_modern_weapons)
	{
		if(level.ex_wepo_class) wepclass = level.ex_wepo_class;
			else wepclass = 400;
	}
	else wepclass = level.ex_wepo_class;
	registerCvar("ui_weapon_only", wepclass, 1);
	
	// secondary weapons
	secwep = 0;
	if(level.ex_wepo_secondary) secwep = 1;
	if(level.ex_wepo_secondary && level.ex_wepo_sec_enemy) secwep = 2;
	registerCvar("ui_secondarywep", secwep, 1);

	// enemy weapons
	registerCvar("ui_enemywep", level.ex_wepo_enemy, 1);

	// grenades
	//  0 = none
	//  1 = frag nades
	//  2 = smoke nades
	//  4 = fire nades
	//  8 = gas nades
	// 16 = satchel charges
	frags = 0;
	if(maps\mp\gametypes\_weapons::getWeaponStatus("fraggrenade"))
	{
		if(level.ex_firenades) frags = 4;
			else if(level.ex_gasnades) frags = 8;
				else if(level.ex_satchelcharges) frags = 16;
					else frags = 1;
	}
	smokes = 0;
	if(maps\mp\gametypes\_weapons::getWeaponStatus("smokegrenade"))
	{
		if(level.ex_smoke["german"] == 7) smokes = 4;
			else if(level.ex_smoke["german"] == 8) smokes = 8;
				else if(level.ex_smoke["german"] == 9) smokes = 16;
					else smokes = 2;
	}
	nades = (frags | smokes);
	registerCvar("ui_nades", nades, 1);

	// tripwires
	registerCvar("ui_tripwire", level.ex_tweapon, 1);

	// landmines
	landmines = 0;
	if(level.ex_landmines)
	{
		if(!level.ex_landmines_loadout) landmines = 1;
			else landmines = 2;
	}
	registerCvar("ui_landmines", landmines, 1);

	// spawn protection
	spro = 0;
	if(level.ex_spwn_time >= 1)
	{
		if(level.ex_spwn_invisible) spro = 2;
			else spro = 1;
	}
	registerCvar("ui_spawnpro", spro, 1);

	// health system
	registerCvar("ui_healthregen", level.ex_healthregen, 1);

	// firstaid system
	registerCvar("ui_firstaid", level.ex_medicsystem, 1);

	// sprinting
	if(level.ex_sprint >= 1) sprint = 1;
		else sprint = 0;
	registerCvar("ui_sprinting", sprint, 1);

	// forced autoassign
	registerCvar("ui_forced_auto", level.ex_autoassign, 1);

	// initial ingame and class menu variables
	registerCvar("ui_allow_teamchange", 1, 1, "onConnect", "ingame", ::checkCvarDistrMenu);
	registerCvar("ui_allow_weaponchange", 0, 1, "onConnect", "ingame", ::checkCvarDistrMenu);
	registerCvar("ui_allow_classchange", 0, 1, "onConnect", "ingame", ::checkCvarDistrMenu);

	/*****************************************************************************
	PRIORITY 2 DVARS onConnect (mostly in-game and quickmessage controls)
	*****************************************************************************/

	// sync snaps cvar
	registerCvar("snaps", level.ex_snaps, 2);

	// in-game menu eXtreme call vote
	registerCvar("ui_ingame_vote_allow_old", level.ex_ingame_vote_allow_old, 2);
	registerCvar("ui_ingame_vote_allow_gametype", level.ex_ingame_vote_allow_gametype, 2);
	registerCvar("ui_ingame_vote_allow_map", level.ex_ingame_vote_allow_map, 2);

	// add favorite menu activation
	if(level.ex_addtofavorites)
	{
		registerCvar("ui_favoriteExtreme", level.ex_addtofavorites, 2);
		registerCvar("ui_favoriteName", getCvar("sv_hostname"), 2);
		favport = getCvar("net_port");
		if(favport == "") favport = "28960";
		favip = [[level.ex_drm]]("ex_addtofavorites_ip", "", "", "", "string");
		if(isDefined(favip) && favip != "") favaddress = favip + ":" + favport;
			else favaddress = getCvar("net_ip") + ":" + favport;
		registerCvar("ui_favoriteAddress", favaddress, 2);
	}

	// female model Diana menu activation
	registerCvar("ui_diana", 0, 2, "onConnect", undefined, ::checkCvarDistrDiana, true);
	registerCvar("ui_diana_player", 0, 2, "onConnect", undefined, ::checkCvarDistrDianaPlayer, true);

	// longrange rifle bind menu activation
	longrange_server = extreme\_ex_longrange::statusLongrange();
	registerCvar("ui_longrange", longrange_server, 2);

	// zoom menu activation
	registerCvar("ui_zoom", 0, 2, "onConnect", undefined, ::checkCvarDistrZoom, true);

	// server connection hub activation
	if(level.ex_hub_server1_name != "") registerCvar("ui_hub_server1", level.ex_hub_server1_name, 2);
	if(level.ex_hub_server2_name != "") registerCvar("ui_hub_server2", level.ex_hub_server2_name, 2);
	if(level.ex_hub_server3_name != "") registerCvar("ui_hub_server3", level.ex_hub_server3_name, 2);
	if(level.ex_hub_server4_name != "")
	{
		if(level.ex_hub_password) registerCvar("ui_hub_password", level.ex_hub_server4_name, 2);
			else registerCvar("ui_hub_server4", level.ex_hub_server4_name, 2);
	}

	// quick message menu activations
	display = 0;
	if(level.ex_teamplay && level.ex_medicsystem == 2) display = 1;
	registerCvar("ui_allow_quickrequests", display, 2); // menu item 4

	display = 0;
	if(level.ex_taunts == 1 || level.ex_taunts == 3) display = 1;
	registerCvar("ui_allow_quicktaunts", display, 2); // menu item 5 and 6

	display = 0;
	if(level.ex_currentgt == "lib") display = 1;
	registerCvar("ui_allow_quickresponseslib", display, 2); // menu item 7

	display = 0;
	if(level.ex_currentgt == "ft") display = 1;
	registerCvar("ui_allow_quickresponsesft", display, 2); // menu item 7

	display = 0;
	if(level.ex_jukebox) display = 1;
	registerCvar("ui_allow_quickjukebox", display, 2); // menu item 8

	display = 0;
	if(level.ex_specials) display = 1;
	registerCvar("ui_allow_quickspecials", display, 2); // menu item 9

	/*****************************************************************************
	PRIORITY 3 DVARS onConnect
	*****************************************************************************/

	// ...

	/*****************************************************************************
	PRIORITY 1 DVARS onForced
	*****************************************************************************/

	if(level.ex_forceclientcvars)
	{
		// crosshairs
		registerCvar("cg_drawcrosshair", level.ex_crosshair, 1, "onForced");

		// crosshair turret
		registerCvar("cg_drawturretcrosshair", level.ex_crosshair, 1, "onForced");

		// crosshair names
		registerCvar("cg_drawcrosshairnames", level.ex_crosshairnames, 1, "onForced");

		// crosshair color change
		registerCvar("cg_crosshairEnemyColor", level.ex_enemycross, 1, "onForced");

		// stance indicator
		if(level.ex_hudstance) registerCvar("hud_fade_stance", 1.7, 1, "onForced");
			else registerCvar("hud_fade_stance", .05, 1, "onForced");

		// ambient light tweak
		registerCvar("r_lighttweakambient", level.ex_brightmodels, 1, "onForced");

		// LOD scale (forced to 1)
		registerCvar("r_lodscale", 1, 1, "onForced");

		// sound (forced to 1, sound will not function correctly without it)
		registerCvar("mss_Q3fs", 1, 1, "onForced");

		// rate setting
		if(level.ex_forcerate) registerCvar("rate", level.ex_forcerate, 1, "onForced");

		// max packets
		if(level.ex_maxpackets) registerCvar("cl_maxpackets", level.ex_maxpackets, 1, "onForced");

		// max fps
		if(level.ex_maxfps) registerCvar("com_maxfps", level.ex_maxfps, 1, "onForced");

		// mantle hints
		registerCvar("cg_drawmantlehint", level.ex_mantlehint, 1, "onForced");
	}

	/*****************************************************************************
	PRIORITY 2 DVARS onForced
	*****************************************************************************/

	// ...

	/*****************************************************************************
	PRIORITY 3 DVARS onForced
	*****************************************************************************/

	// ...

	/*****************************************************************************
	PRIORITY 1 DVARS onJoined
	*****************************************************************************/

	if(!level.ex_mbot && level.ex_allowvote && level.ex_ingame_vote_allow_gametype)
	{
		gt_str = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lib lms lts ons rbcnq rbctf sd tdm tkoth vip";
		gt_array = strtok(gt_str, " ");

		for(i = 0; i < gt_array.size; i++)
		{
			gt = gt_array[i];
			status = [[level.ex_drm]]("ex_ingame_vote_allow_" + gt, 1, 0, 1, "int");
			registerCvar("ui_vote_gametype_" + gt, status, 1, "onJoined", "gtvote", ::checkCvarDistrGametype);
		}
	}

	if(!level.ex_mbot && (level.ex_rcon || (level.ex_allowvote && level.ex_ingame_vote_allow_map)) )
	{
		number = level.ex_maps.size - 1;
		if(number > 160) number = 160; // 2*80

		for(i = 1; i <= number; i++)
			registerCvar("ui_vote_map_" + i, level.ex_maps[i].longname, 1, "onJoined", "mapvote", ::checkCvarDistrMap);

		registerCvar("ui_vote_map_2pages", (number > 80), 1, "onJoined", "mapvote", ::checkCvarDistrMap);
	}

	/*****************************************************************************
	PRIORITY 2 DVARS onJoined
	*****************************************************************************/

	if(game["profiles"].size > 1)
	{
		for(i = 0; i < game["profiles"].size; i++)
			registerCvar("ui_modprofile" + i, game["profiles"][i].name, 2, "onJoined", "profile", ::checkCvarDistrProfile);
	}

	/*****************************************************************************
	PRIORITY 3 DVARS onJoined
	*****************************************************************************/

	// ...
}

checkCvarDistrMenu()
{
	// allow to send menu vars if this player just connected to the server (not on successive rounds)
	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator") return(false);
	return(true);
}

checkCvarDistrProfile()
{
	// allow to send profile vars if this is a player with access rights to rcon server settings
	if(level.ex_rcon && isDefined(self.ex_rcon) && isDefined(self.ex_rcon_access) && (self.ex_rcon_access & 16) == 16) return(true);
	return(false);
}

checkCvarDistrGametype()
{
	// allow to send game type vars if extreme callvote for game types is enabled,
	// but only if g_allowvote was enabled when map started
	if(level.ex_allowvote && level.ex_ingame_vote_allow_gametype) return(true);
	return(false);
}

checkCvarDistrMap()
{
	// allow to send map vars if this is a player with access rights to rcon map control,
	// or if extreme callvote for maps is enabled, but only if g_allowvote was enabled when map started
	rcon_allowed = false;
	if(level.ex_rcon && isDefined(self.ex_rcon) && isDefined(self.ex_rcon_access) && (self.ex_rcon_access & 1) == 1) rcon_allowed = true;
	if(rcon_allowed || (level.ex_allowvote && level.ex_ingame_vote_allow_map)) return(true);
	return(false);
}

checkCvarDistrDiana()
{
	return(extreme\_ex_diana::statusDiana());
}

checkCvarDistrDianaPlayer()
{
	if(checkCvarDistrDiana())
	{
		memory = self extreme\_ex_memory::getMemory("diana", "status");
		if(!memory.error && memory.value == 1) self.pers["diana"] = memory.value;
		if(isDefined(self.pers["diana"])) return(true);
	}
	return(false);
}

checkCvarDistrZoom()
{
	zoom_server = extreme\_ex_zoom::statusZoom();
	if(zoom_server) thread extreme\_ex_zoom::initZoom(zoom_server);
	return(zoom_server);
}
