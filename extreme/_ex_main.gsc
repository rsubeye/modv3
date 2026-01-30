#include extreme\_ex_weapons;
#include extreme\_ex_hudcontroller;

//******************************************************************************
// Launch main threads
//******************************************************************************
main()
{
	// trigger areas for flag return and map edge detection
	// keep after ex_entities::init and _gameobjects::main, because these can
	// remove minefield and trigger_hurt entities!
	level.ex_returners = getentarray("minefield", "targetname");
	trigger_hurts = getentarray("trigger_hurt", "classname");
	for(i = 0; i < trigger_hurts.size; i++)
		level.ex_returners[level.ex_returners.size] = trigger_hurts[i];
	trigger_hurts = undefined;

	// report removed entities
	if(level.ex_entities)
	{
		if((level.ex_entities & 1) == 1) thread extreme\_ex_entities::reportRemovedEntities();
		// dump entities after the level script has completed
		extreme\_ex_entities::dumpMapEntities("AFTER");
	}

	// report precached items
	if(level.ex_tune_precachestats) extreme\_ex_utils::reportPrecached( (level.ex_tune_precachestats == 2) );

	// we only need to initialize the mbots in mbot development mode
	if(level.ex_mbot && level.ex_mbot_dev)
	{
		// initialize spawnpoint markers array
		level.ex_spawnmarkers = [];

		// initialize mbots
		thread extreme\_ex_bots::main(true);

		// tell DRM to stop processing "small", "medium" and "large" extensions
		game["ex_modstate"] = "initialized";

		return;
	}

	// reposition flags to fix placement bug on linux
	if(level.ex_flagbased)
	{
		axis_flag = getent("axis_flag", "targetname");
		if(isDefined(axis_flag))
		{
			//axis_flag placeSpawnpoint();
			trace = bulletTrace(axis_flag.origin + (0,0,50), axis_flag.origin - (0,0,100), true, axis_flag);
			axis_flag.origin = trace["position"];
			axis_flag.home_origin = axis_flag.origin;
			if(isDefined(axis_flag.flagmodel)) axis_flag.flagmodel.origin = axis_flag.home_origin;
			if(isDefined(axis_flag.basemodel)) axis_flag.basemodel.origin = axis_flag.home_origin;
		}

		allied_flag = getent("allied_flag", "targetname");
		if(isDefined(allied_flag))
		{
			//allied_flag placeSpawnpoint();
			trace = bulletTrace(allied_flag.origin + (0,0,50), allied_flag.origin - (0,0,100), true, allied_flag);
			allied_flag.origin = trace["position"];
			allied_flag.home_origin = allied_flag.origin;
			if(isDefined(allied_flag.flagmodel)) allied_flag.flagmodel.origin = allied_flag.home_origin;
			if(isDefined(allied_flag.basemodel)) allied_flag.basemodel.origin = allied_flag.home_origin;
		}

		/*
		if(isDefined(level.flag))
		{
			//level.flag placeSpawnpoint();
			trace = bulletTrace(level.flag.origin + (0,0,50), level.flag.origin - (0,0,100), true, level.flag);
			level.flag.origin = trace["position"];
			level.flag.home_origin = level.flag.origin;
			if(isDefined(level.flag.flagmodel)) level.flag.flagmodel.origin = level.flag.home_origin;
			if(isDefined(level.flag.basemodel)) level.flag.basemodel.origin = level.flag.home_origin;
		}
		*/
	}

	// get the map dimensions and playing field dimensions
	if(!isDefined(game["mapArea_Centre"])) extreme\_ex_utils::GetMapDim(false);

	// create spawnpoints array
	if(!isDefined(level.ex_current_spawnpoints)) extreme\_ex_utils::spawnpointArray();

	// update spawnpoints in designer mode
	if(level.ex_designer) thread extreme\_ex_spawnpoints::markSpawnpoints();

	// initialize bots (dumb or meat)
	if(level.ex_testclients || level.ex_mbot) thread extreme\_ex_bots::main();

	// setup weather FX
	if(level.ex_weather) thread extreme\_ex_weather::main();

	// set up map rotation (executed only once)
	if(getCvar("ex_maprotdone") == "")
	{
		// set up player based rotation
		if(level.ex_pbrotate)
		{
			// includes fixing player based strings if level.ex_fixmaprotation is enabled
			extreme\_ex_maprotation::pbRotation();
		}
		else
		{
			// fix the other map rotation strings (includes stacker strings if enabled)
			if(level.ex_fixmaprotation) level extreme\_ex_maprotation::fixMapRotation();

			// randomize map rotation
			if(level.ex_randommaprotation) level thread extreme\_ex_maprotation::randomMapRotation();

			// save rotation for rotation stacker
			setCvar("ex_maprotation", getCvar("sv_maprotation"));
		}
		setCvar("ex_maprotdone","1");
	}

	// check if we are playing a next map set by RCON, and have to restore the rotation
	maprotsaved = getCvar("saved_maprotationcurrent");
	if(maprotsaved != "")
	{
		setCvar("sv_maprotationcurrent", maprotsaved);
		setCvar("saved_maprotationcurrent", "");
	}

	// rotation stacker
	if(!level.ex_pbrotate && !isDefined(game["stacker_done"]))
	{
		maprotcur = getCvar("sv_maprotationcurrent");
		if(maprotcur == "")
		{
			maprotno = getCvar("ex_maprotno");
			if(maprotno == "") maprotno = 0;
				else maprotno = getCvarInt("ex_maprotno");
			maprotno++;
			maprot = getCvar("sv_maprotation" + maprotno);
			if(maprot != "")
			{
				setCvar("sv_maprotation", maprot);
				setCvar("ex_maprotno", maprotno);
			}
			else if(maprotno != 1)
			{
				maprotno = 0;
				setCvar("sv_maprotation", getCvar("ex_maprotation"));
				setCvar("ex_maprotno", maprotno);
			}
			else setCvar("ex_maprotno", maprotno);
		}
		game["stacker_done"] = 1;
	}

	// start rotation rig for gunships and uav (needs to go below getMapDim)
	if(level.ex_gunship || level.ex_gunship_special || (level.ex_uav && level.ex_uav_model))
		level thread extreme\_ex_rotationrig::main();

	// start gunships
	if(level.ex_gunship || level.ex_gunship_special) level thread extreme\_ex_gunship::main();

	// clear any camping players
	if(level.ex_campwarntime || level.ex_campsniper_warntime) level thread extreme\_ex_camper::removeCampers();

	// Bash-mode level announcement
	if( (level.ex_bash_only && level.ex_bash_only_msg > 1) ||
	    (level.ex_frag_fest && level.ex_frag_fest_msg > 1) ) level thread modeAnnounceLevel();

	// Clan-mode level announcement
	if(level.ex_clanvsnonclan && level.ex_clanvsnonclan_msg > 1) level thread clanAnnounceLevel();

	// monitor the world for potatoes
	[[level.ex_registerLevelEvent]]("onSecond", ::potatoMonitor);

	// ammo crates
	if(level.ex_amc_perteam) level thread extreme\_ex_ammocrates::main();

	// turrets monitor
	if(level.ex_turrets) level thread extreme\_ex_turrets::main();

	// retreat monitor
	if(level.ex_flag_retreat) level thread retreatMonitor();

	// player callback events
	[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
	[[level.ex_registerCallback]]("onPlayerKilled", ::onBinocExit);
	[[level.ex_registerCallback]]("onBinocEnter", ::onBinocEnter);
	[[level.ex_registerCallback]]("onBinocExit", ::onBinocExit);

	// Tell DRM to stop processing "small", "medium" and "large" extensions
	game["ex_modstate"] = "initialized";

	// Start bot system
	level notify("gobots");
}

//******************************************************************************
// Launch player threads
//******************************************************************************
playerThreads()
{
	self endon("kill_thread");

	// make sure the level scripts are started before starting player threads
	while(!isDefined(game["ex_modstate"])) wait( [[level.ex_fpstime]](0.05) );

	// check just to be sure
	if(level.ex_gameover) return;

	// parachutes (prep has been done in exPreSpawn() )
	if(level.ex_parachutes && isDefined(self.ex_willparachute)) self thread extreme\_ex_parachute::main();

	// randomize execution of threads, so they won't run all at the same time for all players.
	// Especially helpful to spread the load after a map_restart (round based games)
	if(level.ex_spawncontrol) wait( randomFloat(1.0) );

	// check again... can't be sure enough
	if(level.ex_gameover) return;

	// start spawnpoint designer thread
	if(level.ex_designer)
	{
		designer = true;
		// but only for specific player, and only if mbots and mbots development are disabled
		if(level.ex_mbot && level.ex_mbot_dev) designer = false;
		if(designer && self.name == level.ex_designer_name) self thread extreme\_ex_designer::mainDesigner();
	}

	// turn off intro, spec and death music
	if( (level.ex_intromusic && self.pers["intro_on"]) || (level.ex_specmusic && self.pers["spec_on"]) || (level.ex_deathmusic && self.pers["dth_on"]) )
	{
		self.pers["intro_on"] = false;
		self.pers["spec_on"] = false;
		self.pers["dth_on"] = false;
		self playLocalSound("spec_music_null");
		self playLocalSound("spec_music_stop");
	}

	// init weapon usage monitor vars
	self.ex_lastoffhand = "none";
	self.ex_oldoffhand = self getCurrentOffHand();
	if(self.ex_oldoffhand != "none") self.ex_oldoffhand_ammo = self getAmmoCount(self.ex_oldoffhand);
		else self.ex_oldoffhand_ammo = 0;

	// init health bar
	if(level.ex_healthbar == 2)
	{
		hud_index = playerHudCreate("healthbar_icon", -118, -25, 1, (1,1,1), 1, 0, "right", "bottom", "left", "top", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, "gfx/hud/hud@health_cross.tga", 10, 10);

		hud_index = playerHudCreate("healthbar_back", -105, -25, 1, (1,1,1), 1, 0, "right", "bottom", "left", "top", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, "gfx/hud/hud@health_back.tga", 90, 10);

		hud_index = playerHudCreate("healthbar_bar", -104, -24, 0.8, (0,1,0), 1, 0, "right", "bottom", "left", "top", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, "gfx/hud/hud@health_bar.tga", 88, 8);

		self.ex_oldhealth = self.health;
	}

	// init scoped on
	if(level.ex_scopedon) hud_index = playerHudCreate("scopedon", 320, 200, 0, (1,0,0), 1.2, 0, "fullscreen", "fullscreen", "center", "middle", false, false);

	// ----- MBOTS: stop here if you are an mbot ---------------------------------
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return;
	// ----- MBOTS ---------------------------------------------------------------

	[[level.ex_registerPlayerEvent]]("onFrame", ::multiMonitorFrame, true);
	[[level.ex_registerPlayerEvent]]("onTenthSecond", ::multiMonitorTenthSecond, true);
	[[level.ex_registerPlayerEvent]]("onHalfSecond", ::multiMonitorHalfSecond, true);
	[[level.ex_registerPlayerEvent]]("onSecond", ::multiMonitorSecond, false);
	if(level.ex_heli && level.ex_heli_candamage) extreme\_ex_specials_helicopter::onFrameInit();

	// monitor laser dot
	if(level.ex_laserdot) self thread extreme\_ex_laserdot::main();

	// monitor sniper zoom level
	if(level.ex_zoom) self thread extreme\_ex_zoom::main();

	// monitor for flamethrower
	ftstart = true;
	if(!maps\mp\gametypes\_weapons::getWeaponAdvStatus("flamethrower_allies") && !maps\mp\gametypes\_weapons::getWeaponAdvStatus("flamethrower_axis")) ftstart = false;
	if(ftstart) self thread extreme\_ex_flamethrower::main();

	// monitor sprint
	if(level.ex_sprint) self thread extreme\_ex_sprintsystem::main();

	// check names and show welcome messages
	self thread handleWelcome();

	// ----- READYUP: stop here when in ready-up mode ----------------------------
	if(level.ex_readyup && !isDefined(game["readyup_done"])) return;
	// ----- READYUP -------------------------------------------------------------

	// spawn protection
	if(level.ex_spwn_time) self thread extreme\_ex_spawnpro::main();

	// parachute release
	if(level.ex_parachutes && isDefined(self.ex_willparachute)) self notify("parachute_release");

	// monitor for anti-run forced crouch
	if(level.ex_antirun_spawncrouched) self thread antirunSpawnCrouched();

	// setup arcade style HUD elements and monitor points
	if(level.ex_arcade_score || level.ex_arcade_shaders) self thread extreme\_ex_arcade::main();

	// monitor mobile MGs
	if(level.ex_turrets > 1) self thread extreme\_ex_turrets::mobileThink();

	// monitor camper
	if(level.ex_campwarntime || level.ex_campsniper_warntime) self thread extreme\_ex_camper::main();

	// ----- BOT: stop here if you are a bot -------------------------------------
	if(isDefined(self.pers["isbot"]) && self.pers["isbot"])
	{
		if(level.ex_testclients_freeze) self extreme\_ex_utils::punishment("enable", "freeze");
		return;
	}
	// ----- BOT -----------------------------------------------------------------

	// start the rank hud system
	if(level.ex_ranksystem && level.ex_rank_hudicons) self thread extreme\_ex_ranksystem::rankhud();

	// monitor first aid system
	if(level.ex_medicsystem) self thread extreme\_ex_firstaid::main();

	// monitor tripwires
	if(level.ex_tweapon) self thread extreme\_ex_tripwires::main();

	// start jukebox
	if(level.ex_jukebox) self thread extreme\_ex_jukebox::main();

	// good luck message
	if(level.ex_goodluck)
	{
		if(isDefined(self.ex_team_changed)) self.ex_glplay = undefined;
		if(!isDefined(self.ex_glplay)) self thread extreme\_ex_messages::goodluckMsg();
	}

	// display round number at spawn for roundbased game types
	self thread roundDisplay();

	// display bash mode message
	if( (level.ex_bash_only && level.ex_bash_only_msg > 1) ||
	    (level.ex_frag_fest && level.ex_frag_fest_msg > 1) ) self thread modeAnnouncePlayer();

	// display clan mode message
	if(level.ex_clanvsnonclan && level.ex_clanvsnonclan_msg > 1) self thread clanAnnouncePlayer();
}

//******************************************************************************
// Player events
//******************************************************************************
onPlayerKilled()
{
	// fixed drown script does not use the hud controller
	if(isDefined(self.drown_progrback)) self.drown_progrback destroy();
	if(isDefined(self.drown_progrbar)) self.drown_progrbar destroy();
	if(isDefined(self.drown_vision)) self.drown_vision destroy();

	if(isDefined(self.ex_anchor)) self.ex_anchor delete();

	// needed to free up the reserved objective
	self thread extreme\_ex_camper::removeCamper();

	if(isDefined(self.ex_headmarker))
	{
		self.ex_headmarker stoploopsound(); // sprint and crybaby
		self.ex_headmarker unlink();
		self.ex_headmarker delete();
	}

	if(isDefined(self.ex_spinemarker))
	{
		self.ex_spinemarker stoploopsound(); // stealth
		self.ex_spinemarker unlink();
		self.ex_spinemarker delete();
	}

	if(isDefined(self.ex_eyemarker))
	{
		self.ex_eyemarker unlink();
		self.ex_eyemarker delete();
	}

	if(isDefined(self.ex_thumbmarker))
	{
		self.ex_thumbmarker unlink();
		self.ex_thumbmarker delete();
	}

	if(isDefined(self.ex_lankmarker))
	{
		self.ex_lankmarker unlink();
		self.ex_lankmarker delete();
	}

	if(isDefined(self.ex_rankmarker))
	{
		self.ex_rankmarker unlink();
		self.ex_rankmarker delete();
	}

	if(isDefined(self.ex_lwristmarker))
	{
		self.ex_lwristmarker unlink();
		self.ex_lwristmarker delete();
	}

	if(isDefined(self.ex_rwristmarker))
	{
		self.ex_rwristmarker unlink();
		self.ex_rwristmarker delete();
	}
}

onBinocEnter()
{
	self.ex_binocuse = true;
	if(level.ex_aimrig)
	{
		show_aimrig = false;
		if(level.ex_ranksystem && !self.ex_callingwmd && (self.ex_mortar_strike || self.ex_artillery_strike || self.ex_air_strike)) show_aimrig = true;
		if(!show_aimrig && level.ex_specials && extreme\_ex_specials::playerPerkIsLocked("cam")) show_aimrig = true;

		if(show_aimrig)
		{
			if(!isDefined(self.aimrig))
			{
				self.aimrig = spawn("script_model", (0,0,0));
				self.aimrig setmodel("xmodel/tag_origin");
				self.aimrig hide();
				self.aimrig showToPlayer(self);
			}

			self thread binocAimer();
		}
	}
}

onBinocExit()
{
	self.ex_binocuse = false;
	if(level.ex_aimrig)
	{
		self notify("kill_aimrigfx");
		if(isDefined(self.aimrig)) self.aimrig delete();
	}
}

binocAimer()
{
	self endon("kill_thread");
	self endon("kill_aimrig");
	self endon("kill_aimrigfx");

	self thread binocCrosshair();

	for(;;)
	{
		vStart = self getEye() + (0,0,20);
		vForward = [[level.ex_vectorscale]](anglesToForward(self getplayerangles()), 100000);
		trace = bulletTrace(vStart, vStart + vForward, true, self);
		self.aimrig.origin = trace["position"];
		self.aimrig.angles = vectorToAngles(trace["normal"]);
		wait( [[level.ex_fpstime]](0.05) );
	}
}

binocCrosshair()
{
	self endon("kill_thread");
	self endon("kill_aimrig");
	self endon("kill_aimrigfx");

	// wait for binoc anim to finish
	wait( [[level.ex_fpstime]](.5) );

	for(;;)
	{
		playfxontag(game["aimrig_selector"], self.aimrig, "tag_origin");
		wait( [[level.ex_fpstime]](1.6) );
	}
}

//******************************************************************************
// Monitors
//******************************************************************************
retreatMonitor()
{
	level endon("ex_gameover");

	// the flags are not initialized while readying up, so return and wait for it to finish
	if(level.ex_readyup && !isDefined(game["readyup_done"])) return;

	axis_flag = getent("axis_flag", "targetname");
	allied_flag = getent("allied_flag", "targetname");

	// distance between axis and allies base divided by 2 to mark hypothetical middle of map
	flag_dist = int(distance(axis_flag.basemodel.origin, allied_flag.basemodel.origin) / 2);

	// loop delay initialization (regular checks each second; after announcements 5 seconds)
	loop_delay = 1;

	while(1)
	{
		wait( [[level.ex_fpstime]](loop_delay) );

		// loop delay reset
		loop_delay = 1;

		// are flags on base? if both flags are, no need to do additional checking
		axis_flag_onbase = (axis_flag.origin == axis_flag.home_origin);
		allies_flag_onbase = (allied_flag.origin == allied_flag.home_origin);
		if(!axis_flag_onbase || !allies_flag_onbase)
		{
			// are flags on the move?
			flag["axis"] = "none";
			flag["allies"] = "none";

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isPlayer(player) && player.sessionstate == "playing" && isDefined(player.flag))
				{
					if(level.ex_currentgt == "ctfb")
					{
						if(isDefined(player.ownflagAttached)) flag[player.pers["team"]] = player.pers["team"];
						if(isDefined(player.enemyflagAttached)) flag[getEnemyTeam(player.pers["team"])] = player.pers["team"];
					}
					else flag[getEnemyTeam(player.pers["team"])] = player.pers["team"];
				}
				if(flag["axis"] != "none" && flag["allies"] != "none") break;
			}

			// check if axis have both flags
			if( flag["allies"] == "axis" && (axis_flag_onbase || flag["axis"] == "axis") )
			{
				retreat_team = "axis";
				retreat_origin = axis_flag.home_origin;
			}
			// check if allies have both flags
			else if( flag["axis"] == "allies" && (allies_flag_onbase || flag["allies"] == "allies") )
			{
				retreat_team = "allies";
				retreat_origin = allied_flag.home_origin;
			}
			// no retreat_team (only reset retreatwarning flags)
			else
			{
				retreat_team = "none";
				retreat_origin = undefined;
			}
		}
		// no retreat_team (only reset retreatwarning flags)
		else
		{
			retreat_team = "none";
			retreat_origin = undefined;
		}

		// warn players on retreat_team to retreat when in warning range
		// if retreat_team is "none" only reset retreatwarning flag for all players
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isPlayer(player) && player.sessionstate == "playing")
			{
				// 3 warnings until flag status changes; decrement if on retreat_team, reset to 3 if not
				if(player.pers["team"] == retreat_team )
				{
					if(!isDefined(player.retreatwarning)) player.retreatwarning = 3;
					retreat_dist = int(distance(retreat_origin, player.origin));
					if(!isDefined(player.flag))
					{
						if( (retreat_dist < (flag_dist + (flag_dist * 0.25))) && (retreat_dist > (flag_dist * 0.1)) )
						{
							if(player.retreatwarning)
							{
								player.retreatwarning--;
								if((level.ex_flag_retreat & 1) == 1) player iprintln(&"MISC_FLAG_RETREAT");
									else if((level.ex_flag_retreat & 2) == 2) player iprintlnbold(&"MISC_FLAG_RETREAT");
										else if((level.ex_flag_retreat & 4) == 4) player thread playerHudAnnounce(&"MISC_FLAG_RETREAT");
								if((level.ex_flag_retreat & 8) == 8) player playlocalsound("US_mcc_order_move_back");
							}
						}
					}
					else if((level.ex_flag_retreat & 16) == 16)
					{
						if( retreat_dist < (flag_dist + (flag_dist * 0.5)) )
						{
							if(player.retreatwarning)
							{
								player.retreatwarning--;
								if((level.ex_flag_retreat & 1) == 1) player iprintln(&"MISC_FLAG_BRINGIN");
									else if((level.ex_flag_retreat & 2) == 2) player iprintlnbold(&"MISC_FLAG_BRINGIN");
										else if((level.ex_flag_retreat & 4) == 4) player thread playerHudAnnounce(&"MISC_FLAG_BRINGIN");
								if((level.ex_flag_retreat & 8) == 8) player playlocalsound("US_mcc_order_move_back");
							}
						}
					}
				}
				else player.retreatwarning = 3;
			}
		}

		// 5 seconds delay after announcements
		if(retreat_team != "none") loop_delay = 5;
	}
}

getEnemyTeam(ownteam)
{
	if(ownteam == "axis") return("allies");
		else if(ownteam == "allies") return("axis");
			else return("none");
}

multiMonitorFrame(eventID)
{
	self endon("kill_thread");

	// stance-shoot monitor
	if(level.ex_stanceshoot)
	{
		stanceshoot_check = true;
		if(self.ex_plantwire || self.ex_defusewire || self.handling_mine || isDefined(self.ex_isparachuting)) stanceshoot_check = false;
			else if(isDefined(self.ex_planting) || isDefined(self.ex_defusing)) stanceshoot_check = false;

		if(stanceshoot_check)
		{
			jump = [[level.ex_getStance]](true);
			doit = false;

			switch(level.ex_stanceshoot)
			{
				case 1:
					if(self.ex_stance == 2 && self.ex_laststance != 2) doit = true;
					break;
				case 2:
					if(jump == 3 && self.ex_lastjump != 3) self.ex_jumpcheck = true;
					break;
				default:
					if(self.ex_stance == 2 && self.ex_laststance != 2) doit = true;
						else if(jump == 3 && self.ex_lastjump != 3) self.ex_jumpcheck = true;
					break;
			}

			if(self.ex_jumpcheck)
			{
				self.ex_jumpsensor++;
				if(self.ex_jumpsensor > level.ex_jump_sensitivity)
				{
					self.ex_jumpsensor = 0;
					doit = true;
				}
				self.ex_jumpcheck = false;
			}
			else self.ex_jumpsensor = 0;

			self.ex_laststance = self.ex_stance;
			if(self.ex_jumpsensor == 0) self.ex_lastjump = jump;

			if(doit)
			{
				if(!level.ex_stanceshoot_action) self thread extreme\_ex_utils::weaponPause(0.6);
					else self thread extreme\_ex_utils::weaponWeaken(1);
			}
		}
	}

	// burst monitor
	if(level.ex_burst_mode && !isDefined(self.onturret))
	{
		bursttime = 1.5;
		burstweapon = false;
		sWeapon = self getCurrentWeapon();
		if((level.ex_burst_mode == 1 || level.ex_burst_mode == 3) && isWeaponType(sWeapon, "mg"))
		{
			burstweapon = true;
			bursttime = level.ex_burst_mg;
		}
		else if((level.ex_burst_mode == 2 || level.ex_burst_mode == 3) && isWeaponType(sWeapon, "smg"))
		{
			burstweapon = true;
			bursttime = level.ex_burst_smg;
		}

		if(self playerADS() && !level.ex_burst_ads) burstweapon = false;

		if(burstweapon && self attackButtonPressed())
		{
			self.ex_bursttrigger++;
			if(self.ex_bursttrigger > 10)
			{
				self.ex_bursttrigger = 0;
				self thread extreme\_ex_utils::execClientCommand("+attack; -attack; +attack; -attack; +attack; -attack");
			}
		}
		else self.ex_bursttrigger = 0;
	}

	[[level.ex_enablePlayerEvent]]("onFrame", eventID);
}

multiMonitorTenthSecond(eventID)
{
	self endon("kill_thread");

	// move monitor
	self.ex_stance = [[level.ex_getStance]](false);

	dist = distance(self.ex_lastorigin, self.origin);
	if(dist > 1) self.ex_moving = true;
		else self.ex_moving = false;
	if(dist > 10) self.ex_pace = true;
		else self.ex_pace = false;

	self.ex_lastorigin = self.origin;

	// sniper anti-run monitor
	if(level.ex_antirun && !self.ex_invulnerable && !isDefined(self.ex_isparachuting))
	{
		if( (!self playerads() || !level.ex_antirun_ads) && !self.antirun_puninprog && self.ex_stance == 0 && self.ex_moving)
		{
			chkorigin = (self.origin[0], self.origin[1], 0);
			if(isDefined(self.antirun_mark))
			{
				switch(level.ex_antirun)
				{
					case 1:
						if(distance(self.antirun_mark, chkorigin) > level.ex_antirun_distance)
						{
							self thread antirunPunish();
							self.antirun_mark = undefined;
						}
						break;
					case 2:
						if(distance(self.antirun_mark, chkorigin) > 50)
						{
							self thread antirunBlackout();
							self.antirun_mark = undefined;
						}
						break;
				}
			}
			else self.antirun_mark = chkorigin;
		}
		else
		{
			self.antirun_mark = undefined;
			if(level.ex_antirun == 2 && !self.antirun_puninprog && self.pers["antirun"]) self thread antirunBlackoutFade();
		}
	}

	// weapon usage monitor
	if(!self.usedweapons || level.ex_kamikaze)
	{
		newoffhand = self getCurrentOffHand();
		if(newoffhand != "none")
		{
			newoffhand_ammo = self getAmmoCount(newoffhand);
			if(newoffhand != self.ex_lastoffhand) self.ex_lastoffhand = newoffhand;
		}
		else newoffhand_ammo = 0;

		if(!self.usedweapons)
		{
			if(self.ex_oldoffhand_ammo > newoffhand_ammo || (!self.ex_disabledWeapon && self attackButtonPressed()) )
				self.usedweapons = true;
		}
	}

	// healthbar
	if(level.ex_healthbar == 2)
	{
		if(self.health != self.ex_oldhealth)
		{
			health = self.health / self.maxhealth;
			width = int(health * 88);
			if(width < 1) width = 1;

			self playerHudSetShader("healthbar_bar", "gfx/hud/hud@health_bar.tga", width, 8);
			self playerHudSetColor("healthbar_bar", (1.0 - health, health, 0));

			self.ex_oldhealth = self.health;
		}
	}

	// scoped-on monitor
	if(level.ex_scopedon)
	{
		if(self playerads())
		{
			if(isDefined(self.ex_eyemarker.origin)) startOrigin = self.ex_eyemarker.origin;
				else startOrigin = undefined;

			if(isDefined(startOrigin))
			{
				forward = anglesToForward(self getplayerangles());
				forward = [[level.ex_vectorscale]](forward, 100000);
				endOrigin = startOrigin + forward;

				scopedon = undefined;
				trace = bulletTrace(startOrigin, endOrigin, true, self);
				if(trace["fraction"] != 1 && isDefined(trace["entity"]))
					if(isPlayer(trace["entity"])) scopedon = trace["entity"];

				if(isDefined(scopedon) && (!level.ex_teamplay || scopedon.pers["team"] != self.pers["team"]))
				{
					playerHudSetPlayer("scopedon", scopedon);
					playerHudSetAlpha("scopedon", 1);
				}
				else playerHudSetAlpha("scopedon", 0);
			}
			else playerHudSetAlpha("scopedon", 0);
		}
		else playerHudSetAlpha("scopedon", 0);
	}

	[[level.ex_enablePlayerEvent]]("onTenthSecond", eventID);
}

multiMonitorHalfSecond(eventID)
{
	self endon("kill_thread");

	// range finder
	if(level.ex_rangefinder)
	{
		if(self.ex_binocuse || (self playerads() && extreme\_ex_weapons::isWeaponType(self getcurrentweapon(), "sniper")))
		{
			if(isDefined(self.ex_eyemarker.origin)) startOrigin = self.ex_eyemarker.origin;
				else startOrigin = undefined;

			if(isDefined(startOrigin))
			{
				forward = anglesToForward(self getplayerangles());
				forward = [[level.ex_vectorscale]](forward, 100000);
				endOrigin = startOrigin + forward;

				rangedist = undefined;
				trace = bulletTrace(startOrigin, endOrigin, true, self);
				range = int(distance(startOrigin, trace["position"]));

				hud_index = playerHudIndex("rangefinder");
				if(hud_index == -1) hud_index = playerHudCreate("rangefinder", 0, 90, 1, (1,1,1), 1, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
				if(hud_index != -1)
				{
					if(level.ex_rangefinder_units == 1)
					{
						rangedist = int(range * 0.02778); // Range in Yards
						playerHudSetLabel(hud_index, &"MISC_RANGE");
					}
					else
					{
						rangedist = int(range * 0.0254); // Range in Metres
						playerHudSetLabel(hud_index, &"MISC_RANGE2");
					}

					playerHudSetValue(hud_index, rangedist);
				}
			}
			else playerHudDestroy("rangefinder");
		}
		else playerHudDestroy("rangefinder");
	}

	// call for medic monitor
	if(level.ex_teamplay && level.ex_medicsystem == 1)
	{
		if(!self.ex_calledformedic && (!level.ex_medic_self || !self.ex_firstaidkits))
		{
			if(self.health < level.ex_medic_callout)
			{
				self thread extreme\_ex_firstaid::callformedic();
				self.ex_calledformedic = 60;
			}
		}
		else self.ex_calledformedic--;
	}

	// cold breath monitor
	if(level.ex_wintermap && level.ex_coldbreathfx)
	{
		if(!self.ex_coldbreathdelay)
		{
			playfxontag (level.ex_effect["coldbreathfx"], self, "TAG_EYE");
			if(self.ex_playsprint || self.ex_sprintreco) self.ex_coldbreathdelay = (randomInt(1) + 1) * 2;
				else self.ex_coldbreathdelay = (randomInt(2) + 3) * 2;
		}
		else self.ex_coldbreathdelay--;
	}

	// weather fx modifier
	if(level.ex_weather && !level.ex_wintermap && level.ex_weather_level)
	{
		z = 650;
		z_max = game["mapArea_Max"][2] - 100;
		if((self.origin[2] + z) > z_max) z = z_max - self.origin[2];
		playfx(level.ex_effect["weather"], self.origin + (0, 0, z), self.origin + (0, 0, z+30) );
	}

	[[level.ex_enablePlayerEvent]]("onHalfSecond", eventID);
}

multiMonitorSecond(eventID)
{
	self endon("kill_thread");

	if(self.spamdelay) self.spamdelay--;
}

potatoMonitor(eventID)
{
	if(level.ex_sprint) thread maps\mp\_utility::deletePlacedEntity("weapon_" + game["sprint"]);
	thread maps\mp\_utility::deletePlacedEntity("weapon_dummy1_mp");
	thread maps\mp\_utility::deletePlacedEntity("weapon_dummy2_mp");
	thread maps\mp\_utility::deletePlacedEntity("weapon_dummy3_mp");
}

//******************************************************************************
// Bash mode or nade fest announcement
//******************************************************************************
modeAnnounceLevel()
{
	if(level.ex_bash_only && level.ex_bash_only_msg != 1 && level.ex_bash_only_msg != 4 && level.ex_bash_only_msg != 5) return;
	if(level.ex_frag_fest && level.ex_frag_fest_msg != 1 && level.ex_frag_fest_msg != 4 && level.ex_frag_fest_msg != 5) return;

	hud_index = levelHudCreate("announcer_mode_level", undefined, 0-20, 20, 1, (1,1,1), 1.3, 0, "right", "top", "right", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetText(hud_index, level.ex_specialmodemsg);
}

modeAnnouncePlayer()
{
	self endon("kill_thread");

	if(level.ex_bash_only && (level.ex_bash_only_msg == 2 || level.ex_bash_only_msg == 4) && isDefined(self.ex_modeann)) return;
	if(level.ex_frag_fest && (level.ex_frag_fest_msg == 2 || level.ex_frag_fest_msg == 4) && isDefined(self.ex_modeann)) return;
	self.ex_modeann = true;

	hud_index = playerHudCreate("announcer_mode_player", 320, 120, 1, (1,1,1), 3, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, level.ex_specialmodemsg);

	wait( [[level.ex_fpstime]](1.5) );

	playerHudFade(hud_index, 0.5, 0.5, 0);
	playerHudDestroy(hud_index);
}

//******************************************************************************
// Clan mode annoucement
//******************************************************************************
clanAnnounceLevel()
{
	if(level.ex_clanvsnonclan_msg != 1 && level.ex_clanvsnonclan_msg != 4 && level.ex_clanvsnonclan_msg != 5) return;

	hud_index = levelHudCreate("announcer_clan_level", undefined, 0-20, 35, 1, (1,1,1), 1.3, 0, "right", "top", "right", "top", false, false);
	if(hud_index == -1) return;
	levelHudSetText(hud_index, level.ex_clanmodemsg);
}

clanAnnouncePlayer()
{
	self endon("kill_thread");

 	if( (level.ex_clanvsnonclan_msg == 2 || level.ex_clanvsnonclan_msg == 4) && isDefined(self.ex_clanann) ) return;
	self.ex_clanann = true;

	hud_index = playerHudCreate("announcer_clan_player", 320, 150, 1, (1,1,1), 3, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetText(hud_index, level.ex_clanmodemsg);

	wait( [[level.ex_fpstime]](1.5) );

	playerHudFade(hud_index, 0.5, 0.5, 0);
	playerHudDestroy(hud_index);
}

//******************************************************************************
// Anti-run
//******************************************************************************
antirunSpawnCrouched()
{
	self endon("kill_thread");

	while(isDefined(self.ex_isparachuting)) wait( [[level.ex_fpstime]](.5) );
	extreme\_ex_utils::forceto("crouch");
}

antirunPunish()
{
	self endon("kill_thread");

	if(self.antirun_puninprog) return;
	self.antirun_puninprog = true;

	self iprintlnbold(&"SPRINT_RUNWARNINGA");
	self iprintlnbold(&"SPRINT_RUNWARNINGB");

	switch(self.pers["antirun"])
	{
		case 0:
			self.pers["antirun"]++;
			self iprintlnbold(&"SPRINT_FIRST_PLAYER");
			iprintln(&"SPRINT_FIRST_ALL", [[level.ex_pname]](self));
			extreme\_ex_utils::forceto("crouch");
			self [[level.ex_dWeapon]]();
			self shellshock("default", 5);
			wait( [[level.ex_fpstime]](5) );
			if(isDefined(self)) self [[level.ex_eWeapon]]();
			break;

		case 1:
			self.pers["antirun"]++;
			self iprintlnbold(&"SPRINT_SECOND_PLAYER");
			iprintln(&"SPRINT_SECOND_ALL", [[level.ex_pname]](self));
			extreme\_ex_utils::forceto("crouch");
			self.health = int(self.health / 2);
			self [[level.ex_dWeapon]]();
			self shellshock("default", 10);
			wait( [[level.ex_fpstime]](10) );
			if(isDefined(self)) self [[level.ex_eWeapon]]();
			break;

		case 2:
			self.pers["antirun"]++;
			self iprintlnbold(&"SPRINT_THIRD_PLAYER");
			iprintln(&"SPRINT_THIRD_ALL", [[level.ex_pname]](self));
			extreme\_ex_utils::forceto("crouch");
			self thread extreme\_ex_punishments::doWarp(true);
			wait( [[level.ex_fpstime]](30) );
			break;

		case 3:
			self thread antirunPunishKick();
 			// this keeps self.antirun_puninprog set to true, so we don't end up here again
			return;
	}

	self.antirun_puninprog = false;
}

antirunPunishKick()
{
	self endon("disconnect");

	self iprintlnbold(&"SPRINT_FOURTH_PLAYERA");
	extreme\_ex_utils::forceto("crouch");
	self [[level.ex_dWeapon]]();
	self shellshock("default", 5);
	wait( [[level.ex_fpstime]](5) );
	if(isDefined(self)) self iprintlnbold(&"SPRINT_FOURTH_PLAYERB");
	wait( [[level.ex_fpstime]](3) );
	if(isDefined(self))
	{
		iprintln(&"SPRINT_FOURTH_ALL", [[level.ex_pname]](self));
		kick(self getEntityNumber());
	}
}

antirunBlackout()
{
	self endon("kill_thread");

	if(self.antirun_puninprog) return;
	self.antirun_puninprog = true;

	self notify("stop_blackoutfade");

	hud_index = playerHudIndex("blackscreen");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("blackscreen", 0, 0, 0, (1,1,1), 1, -1, "fullscreen", "fullscreen", "left", "top", false, false);
		if(hud_index != -1)
		{
			if(level.ex_bsod) playerHudSetKeepOnKill(hud_index, true);
			playerHudSetShader(hud_index, "black", 640, 480);
		}
	}

	self.pers["antirun"]++;

	/*
	if(self.pers["antirun"] == 1)
	{
		self iprintlnbold(&"SPRINT_RUNWARNINGA");
		self iprintlnbold(&"SPRINT_RUNWARNINGB");
	}
	*/

	self.antirun_fading = undefined;
	if(self.pers["antirun"] > 10) self.pers["antirun"] = 10;
	alpha = self.pers["antirun"] / 10;
	delay = .2;
	//logprint("ANTIRUN DEBUG: setting alpha " + alpha + " for level " + self.pers["antirun"] + " in " + delay + " seconds\n");
	playerHudFade("blackscreen", delay, delay + 0.1, alpha);

	self.antirun_puninprog = false;
}

antirunBlackoutFade()
{
	self endon("kill_thread");
	self endon("stop_blackoutfade");

	hud_index = playerHudIndex("blackscreen");
	if(hud_index != -1)
	{
		if(isDefined(self.antirun_fading)) return;
		self.antirun_fading = true;

		wait( [[level.ex_fpstime]](1 + (self.pers["antirun"] * .2)) );

		if(isPlayer(self) && isAlive(self))
		{
			while(self.pers["antirun"] > 0)
			{
				self.pers["antirun"]--;
				alpha = self.pers["antirun"] / 10;
				delay = .1 + (alpha * 2);
				//logprint("ANTIRUN DEBUG: setting alpha " + alpha + " for level " + self.pers["antirun"] + " in " + delay + " seconds\n");
				playerHudFade(hud_index, delay, delay + 0.1, alpha);
			}

			self thread antirunBlackoutKill();
		}
	}
}

antirunBlackoutKill()
{
	if(!isPlayer(self) || (!isAlive(self) && level.ex_bsod)) return;
	playerHudDestroy("blackscreen");
	self.antirun_fading = undefined;
}

//******************************************************************************
// Pop helmet
//******************************************************************************
popHelmet(damageDir, damage)
{
	self.ex_helmetpopped = true;

	// if entities monitor in defcon 2, no helmet popping
	if(level.ex_entities_defcon == 2)
	{
		level extreme\_ex_objectqueue::queueFlush("helmet");
		return;
	}

	if(!isDefined(self.hatModel) || isDefined(self.ex_newmodel)) return;
	helmet_model = self.hatModel;

	// make sure the helmet is still there
	helmet_attached = false;
	if(isPlayer(self))
	{
		attachedSize = self getAttachSize();
		for(i = 0; i < attachedSize; i++)
		{
			attachedModel = self getAttachModelName(i);
			if(attachedModel == helmet_model) helmet_attached = true;
		}
	}
	if(!helmet_attached) return;

	if(isPlayer(self))
	{
		self detach(helmet_model, "");
		self.ex_stance = [[level.ex_getStance]](false);
		switch(self.ex_stance)
		{
			case 2: helmet_origin = self.origin + (0,0,15); break;
			case 1: helmet_origin = self.origin + (0,0,44); break;
			default: helmet_origin = self.origin + (0,0,64); break;
		}
		helmet_angles = self.angles;
	}
	else return;

	switch(helmet_model)
	{
		case "xmodel/beret_british_red":
		case "xmodel/beret_british_green":
		case "xmodel/beret_british_blue":
		case "xmodel/bonnet_british_winter":
		case "xmodel/bonnet_russian_winter":
		case "xmodel/cap_american_baseball":
		case "xmodel/cap_american_baseball_dark":
		case "xmodel/hat_american_boonie":
		case "xmodel/hat_american_cowboy":
		case "xmodel/sidecap_camo":
		case "xmodel/sidecap_green":
		case "xmodel/sidecap_khaki":
		case "xmodel/sidecap_lightgrey":
		case "xmodel/sidecap_darkgrey":
			bounceability = 0.2;
			impactsound = undefined;
			break;
		case "xmodel/helmet_russian_padded_a":
		case "xmodel/helmet_russian_trench_a_hat":
		case "xmodel/helmet_russian_trench_b_hat":
		case "xmodel/helmet_russian_trench_c_hat":
		case "xmodel/helmet_russian_trench_d_hat":
		case "xmodel/helmet_russian_trench_popov_hat":
			bounceability = 0.4;
			impactsound = undefined;
			break;
		default:
			bounceability = 0.6;
			impactsound = "helmet_bounce_";
			break;
	}

	damageAngles = vectorToAngles(damageDir);
	if(damageAngles[0] > -45) damageAngles = (-45, damageAngles[1], damageAngles[2]);
	direction = anglesToForward(damageAngles);
	rotation = (randomFloat(360), randomFloat(360), randomFloat(360));

	item_helmet = spawn("script_model", helmet_origin);
	item_helmet.angles = helmet_angles;
	item_helmet setmodel(helmet_model);
	item_helmet.targetname = "poppedhelmet";
	item_helmet extreme\_ex_utils::bounceObject(direction, 20, rotation, bounceability, impactsound, 6);
	level extreme\_ex_objectqueue::queuePutObject(item_helmet, "helmet", false);
}

//******************************************************************************
// First aid
//******************************************************************************
firstaidDrop(origin)
{
	// if entities monitor in defcon 2, suspend all firstaid drops
	if(level.ex_entities_defcon == 2)
	{
		level extreme\_ex_objectqueue::queueFlush("health");
		return;
	}

	health_nr = RandomInt(3) + 1;
	switch(health_nr)
	{
		case 1: modeltype = "xmodel/health_small"; break;
		case 2: modeltype = "xmodel/health_medium"; break;
		default: modeltype = "xmodel/health_large"; break;
	}

	item_health = spawn("script_model", origin);
	item_health hide();
	item_health.angles = (0,0,0);
	item_health setModel(modeltype);
	item_health.targetname = "droppedhealth";
	item_health.health_nr = health_nr;

	switch(level.ex_firstaid_drop)
	{
		case 1: {
			wait( [[level.ex_fpstime]](1) );
			item_health show();
			item_health extreme\_ex_utils::popObject();
			break;
		}
		case 2: {
			wait( [[level.ex_fpstime]](2) );
			item_health extreme\_ex_utils::placeObject();
			item_health show();
			break;
		}
	}

	level extreme\_ex_objectqueue::queuePutObject(item_health, "health", true, 20, 20, ::firstaidCallback);
}

firstaidCallBack(player, entity)
{
	if(isPlayer(player) && player.sessionstate == "playing")
	{
		if(player.health < player.maxhealth)
		{
			player.health += entity.health_nr * 30;
			if(player.health > player.maxhealth) player.health = player.maxhealth;

			if(entity.health_nr == 1) player playLocalSound("health_pickup_small");
				else if(entity.health_nr == 2) player playLocalSound("health_pickup_medium");
					else player playLocalSound("health_pickup_large");

			return(true);
		}
		else if(level.ex_firstaid_collect && player.ex_firstaidkits < level.ex_firstaid_collect)
		{
			player.ex_firstaidkits++;
			player playLocalSound("health_pickup_medium");
			player iprintln(&"FIRSTAID_PICKEDUP");
			player.ex_canheal = true;

			hud_index = player playerHudIndex("firstaid_kits");
			if(hud_index != -1)
			{
				player playerHudSetValue(hud_index, player.ex_firstaidkits);
				player playerHudSetColor(hud_index, (1, 1, 1));
			}

			return(true);
		}
	}
	return(false);
}

//******************************************************************************
// Player pre-spawn routine
//******************************************************************************
exPreSpawn()
{
	self endon("kill_thread");

	// set spawn variables
	setPlayerVariables();

	// spawn protection pre-spawn settings
	if(level.ex_spwn_time)
	{
		self.ex_invulnerable = true;
		self.ex_spawnprotected = true;
		if(level.ex_spwn_invisible) self hide();
	}

	// parachute preperation (keep below spawn protection pre-spawn)
	if(level.ex_parachutes) self thread extreme\_ex_parachute::prep();

	// disallow team change option on weapons menu
	self setClientCvar("ui_allow_teamchange", 0);

	// start rank monitor
	if(level.ex_ranksystem) self thread extreme\_ex_ranksystem::playerRankMonitor();

	// hide mbots until they are completely ready
	if(level.ex_mbot && isDefined(self.pers["isbot"])) self hide();
}

//******************************************************************************
// Player post-spawn routine
//******************************************************************************
exPostSpawn()
{
	self endon("kill_thread");

	// wait for threads to die
	wait( [[level.ex_fpstime]](.05) );

	if(isDefined(self.ex_redirected)) return;

	if(isPlayer(self) && !level.ex_gameover)
	{
		// Attach head marker, used by Sprint System and LR Hitloc
		if(!isDefined(self.ex_headmarker))
		{
			self.ex_headmarker = spawn("script_origin",(0,0,0));
			//self.ex_headmarker linkto (self, "J_Head",(0,50,0),(0,0,0));
			self.ex_headmarker linkto(self, "J_Head",(0,0,0),(0,0,0));
		}
		// Attach spine marker, used by GetStance() and LR Hitloc
		if(!isDefined(self.ex_spinemarker))
		{
			self.ex_spinemarker = spawn("script_origin",(0,0,0));
			self.ex_spinemarker linkto(self, "J_Spine4",(0,0,0),(0,0,0));
		}
		// Attach eye marker, used by Range Finder and LR Hitloc
		if(!isDefined(self.ex_eyemarker))
		{
			self.ex_eyemarker = spawn("script_origin",(0,0,0));
			self.ex_eyemarker linkto(self, "tag_eye",(0,0,0),(0,0,0));
		}
		// Attach thumb marker, used by Knife and Unfixed Turrets
		if(!isDefined(self.ex_thumbmarker))
		{
			self.ex_thumbmarker = spawn("script_origin",(0,0,0));
			self.ex_thumbmarker linkto(self, "J_Thumb_ri_1",(0,0,0),(0,0,0));
		}

		if(level.ex_lrhitloc)
		{
			// Attach left ankle marker, used by LR Hitloc
			if(!isDefined(self.ex_lankmarker))
			{
				self.ex_lankmarker = spawn("script_origin",(0,0,0));
				self.ex_lankmarker linkto(self, "j_ankle_le",(0,0,0),(0,0,0));
			}
			// Attach right ankle marker, used by LR Hitloc
			if(!isDefined(self.ex_rankmarker))
			{
				self.ex_rankmarker = spawn("script_origin",(0,0,0));
				self.ex_rankmarker linkto(self, "j_ankle_ri",(0,0,0),(0,0,0));
			}
			// Attach left wrist marker, used by LR Hitloc
			if(!isDefined(self.ex_lwristmarker))
			{
				self.ex_lwristmarker = spawn("script_origin",(0,0,0));
				self.ex_lwristmarker linkto(self, "j_wrist_le",(0,0,0),(0,0,0));
			}
			// Attach right wrist marker, used by LR Hitloc
			if(!isDefined(self.ex_rwristmarker))
			{
				self.ex_rwristmarker = spawn("script_origin",(0,0,0));
				self.ex_rwristmarker linkto(self, "j_wrist_ri",(0,0,0),(0,0,0));
			}
		}

		if(level.ex_mbot)
		{
			self.mark = [];

			// keep tag_eye first, because it's being addressed as index [0] later on
			self.mark[0] = self.ex_eyemarker;

			if(level.ex_diana && isDefined(self.pers["diana"]))
			{
				self.mark[1] = spawn("script_origin", (0,0,0));
				self.mark[1] linkto(self, "j_spine2", (0,0,0),(0,0,0));
			}
			else
			{
				self.mark[1] = spawn("script_origin", (0,0,0));
				self.mark[1] linkto(self, "j_spine1", (0,0,0),(0,0,0));
			}

			self.mark[2] = spawn("script_origin", (0,0,0));
			self.mark[2] linkto(self, "j_shoulder_le", (0,0,0),(0,0,0));

			self.mark[3] = spawn("script_origin", (0,0,0));
			self.mark[3] linkto(self, "j_shoulder_ri", (0,0,0),(0,0,0));

			self.mark[4] = spawn("script_origin", (0,0,0));
			self.mark[4] linkto(self, "j_elbow_bulge_le", (0,0,0),(0,0,0));

			self.mark[5] = spawn("script_origin", (0,0,0));
			self.mark[5] linkto(self, "j_elbow_bulge_ri", (0,0,0),(0,0,0));

			if(level.ex_mbot_dev && (self.name == level.ex_mbot_devname))
				self thread extreme\_ex_mbot_dev::mainDeveloper();
		}

		self thread playerThreads();

		// remove black screen of death
		if(level.ex_bsod) self thread fadeBlackScreen();
	}
}

//******************************************************************************
// Player on-damage routine
//******************************************************************************
exPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	self endon("disconnect");

	if(level.ex_readyup && !isDefined(game["readyup_done"])) return;

	// bubble protected
	if(isDefined(self.ex_bubble_protected)) return;

	// Anti-hip shooting
	if(level.ex_antihip && isPlayer(eAttacker) && !eAttacker playerADS() && !isDefined(eAttacker.onturret))
	{
		if(sMeansOfDeath != "MOD_MELEE" && (maps\mp\gametypes\_weapons::isMainWeapon(sWeapon) || isWeaponType(sWeapon, "pistol"))) return;
	}

	// Activate line below if you do not want panzerschreck and rpg to kill owner
	//if(isPlayer(eAttacker) && eAttacker == self && extreme\_ex_weapons::isWeaponType(sWeapon, "rl")) return;

	// LR rifle checks and conversion
	if(isPlayer(eAttacker) && isWeaponType(sWeapon, "sniperlr"))
	{
		// bubble protected attacker with LR rifle should not do damage
		if(isDefined(eAttacker.ex_bubble_protected)) return;

		// long range hitloc modifications and messages
		if(level.ex_lrhitloc && isDefined(sMeansOfDeath) && sMeansOfDeath == "MOD_PROJECTILE")
		{
			self.ex_lrhitloc_msg = true;
			aInfo = spawnstruct();
			aInfo.sMeansOfDeath = sMeansOfDeath;
			aInfo.iDamage = iDamage;
			aInfo.sHitLoc = sHitLoc;
			self extreme\_ex_longrange::main(eAttacker, sWeapon, vPoint, aInfo);
			sMeansOfDeath = aInfo.sMeansOfDeath;
			iDamage = aInfo.iDamage;
			sHitLoc = aInfo.sHitLoc;
		}
	}

	if(isPlayer(eAttacker) && isDefined(eAttacker.ex_weakenweapon) && maps\mp\gametypes\_weapons::isMainWeapon(sWeapon))
		iDamage = int(iDamage * (level.ex_stanceshoot_action / 100));

	if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
	    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) )
	{
		if(level.ex_gunship_protect == 1) return;
		if(level.ex_gunship_protect == 2) iDamage = int(iDamage * .1);
	}

	if(level.ex_vest && isDefined(self.ex_vest_protected) && sHitLoc != "none")
	{
		while(1)
		{
			if(sMeansOfDeath != "MOD_MELEE")
			{
				if(isWeaponType(sWeapon, "mg") && !level.ex_vest_protect_mg) break;
				if(isWeaponType(sWeapon, "snipersr") && !level.ex_vest_protect_sniper) break;
				if(isWeaponType(sWeapon, "sniperlr") && !level.ex_vest_protect_sniperlr) break;
			}

			switch(sHitLoc)
			{
				case "torso_upper":
				case "torso_lower": return;
				case "head": break;
				case "helmet": iDamage = int(iDamage * .5); break;
				default: iDamage = int(iDamage * .2); break;
			}
			break;
		}
	}

	// long range hitloc damage message
	if(isDefined(self.ex_lrhitloc_msg))
	{
		if(level.ex_lrhitloc && level.ex_lrhitloc_msg && iDamage < self.health)
			self thread extreme\_ex_longrange::hitlocMessage(eAttacker, sHitLoc);
		self.ex_lrhitloc_msg = undefined;
	}

	// freezetag checks
	if(level.ex_currentgt == "ft")
	{
		// check for freezing or unfreezing with raygun
		if(sWeapon == "raygun_mp" && isPlayer(eAttacker) && (self != eAttacker))
		{
			if(self.pers["team"] == eAttacker.pers["team"])
			{
				if(self.frozenstate == "frozen" && (level.ft_raygun == 1 || level.ft_raygun == 3))
				{
					// Make sure at least one point of unfreezing is done
					if(iDamage < 1) iDamage = 1;

					self.frozenstatus = self.frozenstatus - iDamage;
					if(self.frozenstatus < 0) self.frozenstatus = 0;

					// update status bar for frozen player
					freezebar = int(self.frozenstatus * (level.progressBarWidth / 100));
					playerHudSetShader("ft_progressbar", "white", freezebar, level.progressBarHeight);

					if(self.frozenstatus == 0 && !isDefined(self.unfreeze_pending))
					{
						self.unfreeze_pending = 1; // avoid multiple score registrations
						eAttacker thread maps\mp\gametypes\_ex_ft::finishUnfreeze(self, true);
					}
					return;
				}
			}
			else if(level.ft_raygun != 2 && level.ft_raygun != 3) return;
		}

		// in any other case, do no damage if already frozen
		if(self.frozenstate == "frozen") return;
	}

	if(!isDefined(vPoint)) vPoint = self.origin + (0,0,11);

	// napalm?
	napalm = false;
	if(sMeansOfDeath == "MOD_PROJECTILE" && sWeapon == "planebomb_mp") napalm = true;

	// disable or drop weapon after a fall
	if(level.ex_droponfall && sMeansOfDeath == "MOD_FALLING" && randomInt(100) < level.ex_droponfall)
		self thread weaponfall(1.5);

	// figure out if extreme damage fx should be applied
	dodamagefx = false;
	if(!level.ex_teamplay) dodamagefx = true;

	if(isPlayer(eAttacker))
	{
		if(eAttacker == self) dodamagefx = true;
			else if(level.ex_teamplay && ((self.pers["team"] != eAttacker.pers["team"]) || level.friendlyfire == "1" || level.friendlyfire == "3")) dodamagefx = true;

		if(dodamagefx && eAttacker != self)
		{
			// make mbot alert on hit
			if(level.ex_mbot) self thread extreme\_ex_bots::playerDamage(eAttacker, iDamage);

			// gunship eject
			if(level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self)
			{
				if(iDamage > self.health && ((level.ex_gunship_eject & 2) == 2))
				{
					extreme\_ex_gunship::gunshipDetachPlayer(true);
					return;
				}
			}
			if(level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self)
			{
				if(iDamage > self.health && ((level.ex_gunship_eject & 2) == 2))
				{
					extreme\_ex_specials_gunship::gunshipSpecialDetachPlayer(true);
					return;
				}
			}

			// no damage if invulnerable
			if(self.ex_invulnerable)
			{
				// punish attacking player for attacking spawn protected players
				if(level.ex_spwn_time && level.ex_spwn_punish_attacker && !isDefined(self.ex_crybaby))
				{
					// exclude wmd, nades and satchel charges
					if(isDefined(sWeapon) && !(isWeaponType(sWeapon, "wmd") || isWeaponType(sWeapon, "frag") || isWeaponType(sWeapon, "fragspecial")) )
					{
						punish = true;

						// spawn protection punishment threshold check
						if(level.ex_spwn_punish_threshold)
						{
							eAttacker.ex_spwn_punish_counter += iDamage;
							if(eAttacker.ex_spwn_punish_counter < level.ex_spwn_punish_threshold) punish = false;
						}

						if(punish)
						{
							if(isDefined(eAttacker.onturret))
								eAttacker thread extreme\_ex_spawnpro::punish("turretattack");
							else
								eAttacker thread extreme\_ex_spawnpro::punish("attacking");
						}
					}
				}

				return;
			}

			// punish protected player for abusing spawn protection
			if(level.ex_spwn_time && level.ex_spwn_punish_self && eAttacker.ex_invulnerable && eAttacker.usedweapons)
			{
				eAttacker thread extreme\_ex_spawnpro::punish("abusing");
				return;
			}

			// close kill detection
			if(level.ex_closekill)
			{
				range = int(distance(eAttacker.origin, self.origin));
				if(level.ex_closekill_units) calcdist = int(range * 0.0254); // Range in Metres
					else calcdist = int(range * 0.02778); // Range in Yards

				if(calcdist < level.ex_closekill_distance)
				{
					if(level.ex_closekill_msg)
					{
						if(level.ex_closekill_units)
						{
							eAttacker iprintlnBold(&"CLOSEKILL_RANGE_METRES", calcdist);
							eAttacker iprintlnBold(&"CLOSEKILL_MINRANGE_METRES", level.ex_closekill_range);
							if(level.ex_closekill_msg == 2) self iprintln(&"CLOSEKILL_PROTECTION");
						}
						else
						{
							eAttacker iprintlnBold(&"CLOSEKILL_RANGE_YARDS", calcdist);
							eAttacker iprintlnBold(&"CLOSEKILL_MINRANGE_YARDS", level.ex_closekill_range);
							if(level.ex_closekill_msg == 2) self iprintln(&"CLOSEKILL_PROTECTION");
						}
					}

					if(!isDefined(eAttacker.ckcount)) eAttacker.ckcount = 0;
					eAttacker.ckcount++;

					if(eAttacker.ckcount == 1)
						eAttacker shellshock("default", 5);
					else if(eAttacker.ckcount == 2)
						eAttacker shellshock("default", 10);
					else if(eAttacker.ckcount == 3)
					{
						eAttacker.ckcount = 0;
						eAttacker.ex_forcedsuicide = true;
						eAttacker suicide();
					}

					return;
				}
			}

			// Splatter on attacker?
			if(level.ex_bloodonscreen && (sMeansOfDeath == "MOD_MELEE" || distance(eAttacker.origin , self.origin ) < 50))
				eAttacker thread bloodonscreen();

			if(iDamage < self.health)
			{
				// bulletholes?
				if(level.ex_bulletholes && (sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET"))
					self thread extreme\_ex_bulletholes::bullethole();

				// Pain sound
				if(level.ex_painsound)
				{
					if(napalm && randomInt(100) < 25) self thread extreme\_ex_utils::playSoundOnPlayer("generic_pain", "pain");
						else if(!napalm && randomInt(100) < 50) self thread extreme\_ex_utils::playSoundOnPlayer("generic_pain", "pain");
				}
			}
		}

		// Helmet pop (just for the fun of it, we always allow helmets to pop)
		if(level.ex_pophelmet && !self.ex_helmetpopped)
		{
			switch(sHitLoc)
			{
				case "helmet":
				case "head":
					if(randomInt(100)+1 <= level.ex_pophelmet)
					{
						self thread popHelmet(vDir, iDamage);
						if(dodamagefx) self thread bloodonscreen();
					}
					break;
			}
		}
	}
	else dodamagefx = true;

	// Damage modifiers, weapons
	if(level.ex_wdmodon && isDefined(sWeapon) && sMeansOfDeath != "MOD_MELEE")
	{
		wdmWeapon = sWeapon;
		if(isWeaponType(wdmWeapon, "frag") || isWeaponType(wdmWeapon, "fragspecial")) wdmWeapon = "fraggrenade";
			else if(isWeaponType(wdmWeapon, "smoke") || isWeaponType(wdmWeapon, "smokespecial")) wdmWeapon = "smokegrenade";

		if(isDefined(level.weapons[wdmWeapon])) iDamage = int((iDamage / 100) * level.weapons[wdmWeapon].wdm);
	}

	iDamage = int(iDamage);

	if(isAlive(self))
	{	
		switch(sHitLoc)
		{
			case "right_hand":
			case "left_hand":
			case "gun":
				if(level.ex_droponhandhit && randomInt(100) < level.ex_droponhandhit) self thread extreme\_ex_weapons::dropcurrentweapon();
				break;
			
			case "right_arm_lower":
			case "left_arm_lower":
				if(level.ex_droponarmhit && randomInt(100) < level.ex_droponarmhit) self thread extreme\_ex_weapons::dropcurrentweapon();
				break;
	
			case "torso_lower":
				if(isDefined(self.tankonback) && (randomInt(100) < level.ex_ft_tank_explode))
				{
					if(dodamagefx)
					{
						level thread extreme\_ex_flamethrower::tankExplosion(self, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
						return;
					}
				}
				break;
		}
	}

	if(dodamagefx && !napalm && level.ex_bleeding)
		if(self.health - iDamage < level.ex_startbleed) self thread extreme\_ex_bleeding::doPlayerBleed(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

	[[level.ex_callbackPlayerDamage]](eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}

//******************************************************************************
// Player on-killed routine
//******************************************************************************
exPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc)
{
	self endon("disconnect");
	self notify("kill_thread");

	// black screen on death
	if(level.ex_bsod && isDefined(eAttacker) && eAttacker != self) self thread showBlackScreen();

	// drop health packs
	if(level.ex_medicsystem && level.ex_firstaid_drop && self.ex_firstaidkits) level thread firstaidDrop(self.origin);

	// skip the other stuff if playing freezetag
	if(level.ex_currentgt == "ft") return;

	// kamikaze (suicide bombing)
	if(sMeansOfDeath == "MOD_SUICIDE" && level.ex_kamikaze && isDefined(eAttacker) && isPlayer(eAttacker))
	{
		// suicide bomber
		if(eAttacker == self && !isDefined(self.switching_teams) && !isDefined(self.ex_forcedsuicide) && sWeapon != "dummy1_mp" && isWeaponType(self.ex_lastoffhand, "kamikaze"))
			self thread suicideBomb(eAttacker);
	}

 	// spawn protection punishment threshold reset
	if(level.ex_spwn_time && level.ex_spwn_punish_attacker && level.ex_spwn_punish_threshold && level.ex_spwn_punish_threshold_reset)
		self.ex_spwn_punish_counter = 0;

	// turret abuse check
	if(level.ex_turrets && level.ex_turretabuse && (extreme\_ex_weapons::isWeaponType(sWeapon, "turret") || (sWeapon == "none" && sMeansOfDeath == "MOD_RIFLE_BULLET")) && isDefined(eAttacker))
		eAttacker thread turretAbuse(sWeapon);

	// Helmet pop
	if(level.ex_pophelmet && !self.ex_helmetpopped)
	{
		switch(sHitLoc)
		{
			case "helmet":
			case "head":
				if(randomInt(100)+1 <= level.ex_pophelmet)
				{
					self thread popHelmet(vDir, iDamage);
					//if(dodamagefx) self thread bloodonscreen();
				}
				break;
		}
	}

	if(isPlayer(eAttacker))
	{
		// attacker taunt
		if(level.ex_taunts >= 2)
		{
			if(level.ex_teamplay && eAttacker.pers["team"] != self.pers["team"]) eAttacker thread taunts(randomInt(9)+1);
				else eAttacker thread taunts(4); // DM taunts set to Got one! and Got him!
		}

		// team kill check
		if(level.ex_teamplay && eAttacker != self && eAttacker.pers["team"] == self.pers["team"])
		{
			if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == eAttacker) ||
			    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == eAttacker) ) return;

			// firstaid disable
			if(level.ex_medicsystem && level.ex_medic_penalty)
			{
				if(!isDefined(eAttacker.ex_blockhealing)) eAttacker thread extreme\_ex_firstaid::disablePlayerHealing();
			}

			// sinbin punishment
			if(level.ex_sinbin)
			{
				eAttacker.pers["teamkill"]++;
				eAttacker.pers["conseckill"] = 0;
				if(eAttacker.pers["teamkill"] > level.ex_sinbinmaxtk) eAttacker thread extreme\_ex_punishments::doSinbin();
			}
		}
	}
}

//******************************************************************************
// Black screen on death
//******************************************************************************
showBlackScreen()
{
	self endon("disconnect");

	if(isDefined(self.skip_blackscreen)) return;

	if(level.ex_bsod_blockmenu)
	{
		self closeMenu();
		self closeInGameMenu();
		self setClientCvar("g_scriptMainMenu", game["menu_blackscreen"]);
	}

	hud_index = playerHudIndex("blackscreen");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("blackscreen", 0, 0, 1, (1,1,1), 1, -1, "fullscreen", "fullscreen", "left", "top", false, false);
		if(hud_index == -1) return;
		playerHudSetKeepOnKill(hud_index, true);
		playerHudSetShader(hud_index, "black", 640, 480);
	}
	else playerHudSetAlpha(hud_index, 1); // in case black screen is already active for anti-run

	if(level.ex_bsod == 2) self thread fadeBlackScreen(5);
	else if(level.ex_bsod == 3) self thread fadeBlackScreen(10);
	else if(level.ex_bsod == 4) self thread fadeBlackScreen(level.respawndelay + 2);
}

fadeBlackScreen(delay)
{
	self endon("disconnect");

	if(!isDefined(delay)) delay = 5;
	if(delay) wait( [[level.ex_fpstime]](delay) );

	if(isDefined(self))
	{
		hud_index = playerHudIndex("blackscreen");
		if(hud_index != -1)
		{
			playerHudFade(hud_index, 1.3, 2, 0);
			if(isDefined(self)) self thread killBlackScreen();
		}
	}
}

killBlackScreen()
{
	self endon("disconnect");

	if(isDefined(self))
	{
		if(!level.ex_gameover && level.ex_bsod_blockmenu) self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
		playerHudDestroy("blackscreen");
	}
}

turretAbuse(sWeapon)
{
	self endon("disconnect");

	wepname = maps\mp\gametypes\_weapons::getWeaponName(sWeapon);
	self.pers["turretkill"]++;

	if(self.pers["turretkill"] == level.ex_turretabuse_warn)
	{
		self iprintlnbold(&"TURRET_ABUSER_WARN_PMSG_0");
		self iprintlnbold(&"TURRET_ABUSER_WARN_PMSG_1");
	}
	else if(self.pers["turretkill"] >= level.ex_turretabuse_kill)
	{
		if(sWeapon == "none")
		{
			self iprintlnbold(&"TURRET_ABUSER_PMSG");
			iprintln(&"TURRET_ABUSER_OBITMSG_0", [[level.ex_pname]](self));
			iprintln(&"TURRET_ABUSER_OBITMSG_2");
		}
		else
		{
			self iprintlnbold(&"TURRET_ABUSERWEP_PMSG", wepname);
			iprintln(&"TURRET_ABUSER_OBITMSG_0", [[level.ex_pname]](self));
			iprintln(&"TURRET_ABUSER_OBITMSG_1", wepname);
		}

		wait( [[level.ex_fpstime]](2) );
		playfx(level.ex_effect["barrel"], self.origin);
		self playsound("mortar_explosion1");
		wait( [[level.ex_fpstime]](0.05) );
		self.pers["turretkill"] = 0;
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

//******************************************************************************
// End-round routine
//******************************************************************************
exEndRound()
{
	// update totals
	if(level.ex_statstotal) extreme\_ex_statstotal::writeStatsAll(true);
}

//******************************************************************************
// End-map routine
//******************************************************************************
exEndMap()
{
	level.ex_gameover = true;
	level notify("ex_gameover");
	wait( [[level.ex_fpstime]](0.05) );

	// Disconnect bots
	disconnectBots();

	// clean up perks in the field
	if(level.ex_specials) thread extreme\_ex_specials::removeAllPerks();

	// end-of-game music (Tnic)
	if(level.ex_endmusic || level.ex_mvmusic || level.ex_statsmusic)
		level thread [[level.ex_psop]]("spec_music_null");

	// update totals
	if(level.ex_statstotal) extreme\_ex_statstotal::writeStatsAll(true);

	// clear iprintlnbold messages
	[[level.ex_bclear]]("all", 5);

	if(!level.ex_announcewinner)
	{
		// prepare players for intermission
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player)) continue;

			// stop pain sounds by restoring health
			player.health = player.maxhealth;

			// drop flag
			player extreme\_ex_utils::dropTheFlag(true);

			// close and set menu
			player setClientCvar("g_scriptMainMenu", "");
			player closeMenu();
			player closeInGameMenu();

			// move to spectators
			player thread extreme\_ex_spawn::spawnSpectator();

			// set spectate permissions
			player allowSpectateTeam("allies", false);
			player allowSpectateTeam("axis", false);
			player allowSpectateTeam("freelook", false);
			player allowSpectateTeam("none", true);

			// clean up (disabled for now, 'cause not sure we really need it)
			//if(level.ex_ranksystem) player setPlayerVariables();
		}
	}

	// play end music
	if(level.ex_endmusic) level thread extremeMusic();

	// launch statsboard
	if(level.ex_stbd) extreme\_ex_statsboard::main();

	// if player based map rotation is enabled and map voting is disabled, change the rotation
	if(level.ex_pbrotate && !level.ex_mapvote) extreme\_ex_maprotation::pbRotation();

	// check if we have a next map set by RCON
	nextmap = getCvar("ex_nextmap");
	if(nextmap != "")
	{
		setCvar("ex_nextmap", "");
		setCvar("saved_maprotationcurrent", getCvar("sv_maprotationcurrent"));
		setCvar("sv_maprotationcurrent", "map " + nextmap);
	}
	else
	{
		// launch mapvote
		if(level.ex_mapvote) extreme\_ex_mapvote::main();
		else
		{
			// check if we have to skip the next map (RCON)
			skipmap = getCvar("ex_skipmap");
			if(skipmap != "")
			{
				setCvar("ex_skipmap", "");
				extreme\_ex_maprotation::defNextMap(true);
			}
		}
	}

	// fade the end-of-game music during intermission
	level notify("endmusic");

	// save the number of players for map sizing in DRM
	setCvar("drm_players", level.players.size);
}

disconnectBots()
{
	if(level.ex_mbot)
	{
		spectateBots();
		return;
	}

	bot_entities = [];
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].pers["isbot"]))
		{
			bot_entity = players[i] getEntityNumber();
			bot_entities[bot_entities.size] = bot_entity;
			kick(bot_entity);
			wait( [[level.ex_fpstime]](0.1) );
		}
	}

	if(bot_entities.size)
	{
		entities = getEntArray();
		for(i = 0; i < level.ex_maxclients; i++)
		{
			for(j = 0; j < bot_entities.size; j++)
			{
				if(i == bot_entities[j])
					entities[i] = undefined;
			}
		}
	}
}

spectateBots()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers["isbot"]))
			player thread extreme\_ex_bots::botJoin("spectator");
	}
}

extremeMusic()
{
	// play random track
	musicplay("gom_music_" + (randomInt(10) + 1));

	// wait here till stats and mapvote are done
	level waittill("endmusic");
	
	// wait for intermission time minus music fade time
	wait( [[level.ex_fpstime]](level.ex_intermission - 5) );

	// fade music in last 5 seconds
	musicstop(5);
	wait( [[level.ex_fpstime]](5) );
}

//******************************************************************************
// Player additional routines
//******************************************************************************
suicideBomb(eAttacker)
{
	self endon("disconnect");

	// sEffect "none" is OK, because the exploding nade/satchel charge will have effects
	if(isWeaponType(self.ex_lastoffhand, "satchel"))
	{
		iRadius = level.ex_kamikaze_satchel_radius;
		iMaxDamage = level.ex_kamikaze_satchel_damage;
		sEffect = "none"; // sEffect = "satchel";
	}
	else
	{
		iRadius = level.ex_kamikaze_frag_radius;
		iMaxDamage = level.ex_kamikaze_frag_damage;
		sEffect = "none"; // sEffect = "generic";
	}

	if(isPlayer(eAttacker)) eAttacker.kamikaze_victims = undefined;
	explosion = spawn("script_origin", self.origin);
	explosion thread extreme\_ex_utils::scriptedfxradiusdamage(eAttacker, undefined, "MOD_GRENADE_SPLASH", self.ex_lastoffhand, iRadius, iMaxDamage, iMaxDamage, sEffect, undefined, false, true, true, "kamikaze");
	explosion delete();

	if(level.ex_reward_kamikaze && isDefined(eAttacker.kamikaze_victims))
	{
		wait( [[level.ex_fpstime]](0.05) );
		kamikaze_bonus = level.ex_reward_kamikaze * eAttacker.kamikaze_victims;
		//logprint("KAMIKAZE DEBUG: " + eAttacker.name + " received " + kamikaze_bonus + " bonus for killing " + eAttacker.kamikaze_victims + " players\n");
		eAttacker thread [[level.pscoreproc]](kamikaze_bonus, "bonus");
	}
}

roundDisplay()
{
	self endon("kill_thread");

	if(!isDefined(game["roundnumber"]) || !game["roundnumber"] || game["roundnumber"] == self.pers["roundshown"]) return;
	self.pers["roundshown"] = game["roundnumber"];

	hud_index = playerHudCreate("roundnumber", 320, 100, 0, (1,1,1), 2.4, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;

	if(isDefined(game["roundlimit"])) rlimit = game["roundlimit"];
		else rlimit = 0;

	if(rlimit == game["roundnumber"]) playerHudSetText(hud_index, &"MISC_LASTROUND");
	else
	{
		playerHudSetLabel(hud_index, &"MISC_ROUNDNUMBER");
		playerHudSetValue(hud_index, game["roundnumber"]);
	}

	playerHudFade(hud_index, 2, 0, 1);
	wait( [[level.ex_fpstime]](5) );

	if(isPlayer(self))
	{
		playerHudFade(hud_index, 2, 2, 0);
		playerHudDestroy(hud_index);
	}
}

setPlayerVariables()
{
	self thread resetFlagVars();

	// apply these stats if not defined already
	extreme\_ex_gtcommon::playerStatsInit();

	// spawn protection punishment threshold
	if(level.ex_spwn_time && level.ex_spwn_punish_attacker && level.ex_spwn_punish_threshold && !isDefined(self.ex_spwn_punish_counter))
		self.ex_spwn_punish_counter = 0;

	// reset streak variables
	self.pers["conseckill"] = 0;
	self.pers["conskillnumb"] = 0;
	self.pers["conskilltime"] = 0;
	self.pers["conskillprev"] = 0;
	self.pers["noobstreak"] = 0;
	self.pers["weaponstreak"] = 0;
	self.pers["weaponname"] = "";

	// reset turret abuse counter
	self.pers["turretkill"] = 0;

	// clear the grenades
	if(isDefined(self.pers["fragtype"])) self setWeaponClipAmmo(self.pers["fragtype"], 0);
	if(isDefined(self.pers["smoketype"])) self setWeaponClipAmmo(self.pers["smoketype"], 0);
	if(isDefined(self.pers["enemy_fragtype"])) self setWeaponClipAmmo(self.pers["enemy_fragtype"], 0);
	if(isDefined(self.pers["enemy_smoketype"])) self setWeaponClipAmmo(self.pers["enemy_smoketype"], 0);	
}

resetPlayerVariables()
{
	self thread resetFlagVars();

	// reset score and deaths
	extreme\_ex_gtcommon::playerScoreReset()

	// reset the stats
	extreme\_ex_gtcommon::playerStatsReset();

	// reset streak variables to 0
	self.pers["conseckill"] = 0;
	self.pers["noobstreak"] = 0;
	self.pers["weaponstreak"] = 0;
	self.pers["weaponname"] = "";

	// reset the player rank
	if(level.ex_ranksystem)
	{
		self.pers["special"] = 0;
		self.pers["rank"] = self.pers["preset_rank"];
		self.pers["newrank"] = self.pers["rank"];
	}

	// reset all weapons and firstaid
	self thread extreme\_ex_weapons::replenishWeapons(true);
	self thread extreme\_ex_weapons::replenishGrenades(true);
	if(level.ex_medicsystem) self thread extreme\_ex_weapons::replenishFirstaid(true);
}

resetFlagVars()
{
	// remove team switching flag (re-allow spawn delay if enabled)
	self.ex_team_changed = undefined;

	// init move monitor vars
	self.ex_lastorigin = self.origin;
	self.ex_stance = 0;
	self.ex_pace = false;
	self.ex_moving = false;

	// init stance-shoot monitor vars
	if(level.ex_stanceshoot)
	{
		self.ex_laststance = 2;
		self.ex_lastjump = 3;
		self.ex_jumpcheck = false;
		self.ex_jumpsensor = 0;
	}

	// init sniper anti-run monitor vars
	if(level.ex_antirun)
	{
		self.antirun_puninprog = false;
		self.antirun_fading = undefined;
		self.antirun_mark = undefined;
		if(!isDefined(self.pers["antirun"])) self.pers["antirun"] = 0;
	}

	// init call for medic monitor vars
	self.ex_calledformedic = 0;

	// init cold breath monitor vars
	self.ex_coldbreathdelay = 0;

	// init burst monitor vars
	self.ex_bursttrigger = 0;

	// stop binocular weapons
	self.ex_callingwmd = false;
	self notify("binocular_exit");

	// stop mortars
	self.ex_mortar_strike = false;
	self notify("mortar_over");
	self notify("end_mortar");

	// stop artillery
	self.ex_artillery_strike = false;
	self notify("artillery_over");
	self notify("end_artillery");

	// stop airstrikes
	self.ex_air_strike = false;
	self notify("airstrike_over");
	self notify("end_airstrike");

	// stop gunship
	self.ex_gunship = false;
	self.ex_gunship_ejected = false;
	self.ex_gunship_kills = 0;
	self notify("gunship_over");
	self notify("end_gunship");

	// specials
	self.ex_vest_protected = undefined;
	self.ex_bubble_protected = undefined;
	self.ex_stealth = undefined;
	self.sentrygun_action = undefined;
	self.sentrygun_moving_owner = undefined;
	self.sentrygun_moving_timer = undefined;
	self.flak_action = undefined;
	self.flak_moving_owner = undefined;
	self.flak_moving_timer = undefined;
	self.gml_action = undefined;
	self.gml_moving_owner = undefined;
	self.gml_moving_timer = undefined;
	self.ugv_action = undefined;
	self.ugv_moving_owner = undefined;
	self.ugv_moving_timer = undefined;

	// reset inactivity timers
	self.inactive_plyr_time = undefined;
	self.inactive_dead_time = undefined;
	self.inactive_spec_time = undefined;

	// misc
	self.ex_forcedsuicide = undefined;
	self.ex_disabledWeapon = 0;
	self.ex_iscamper = false;
	self.ex_isonfire = undefined;
	self.ex_puked = undefined;
	if(!isDefined(self.ex_isunknown)) self.ex_isunknown = false;
	if(!isDefined(self.ex_isdupname)) self.ex_isdupname = false;
	self.ex_weakenweapon = undefined;
	self.ex_ispunished = false;
	self.ex_sinbin = false;
	self.ex_oldweapon = undefined;
	self.ex_invulnerable = false;
	self.ex_helmetpopped = false;
	self.ex_sprinttime = 0;
	self.ex_playsprint = false;
	self.ex_sprintreco = false;
	self.ex_sprinting = false;
	self.ex_binocuse = false;
	self.ex_plantwire = false;
	self.ex_defusewire = false;
	self.ex_stopwepmon = false;
	self.ex_bleeding = false;
	self.ex_bsoundinit = false;
	self.ex_bshockinit = false;
	self.ex_pace = false;
	self.ex_checkingwmd = undefined;
	self.ex_spwn_punish = undefined;
	self.ex_firstaidkits = 0;
	self.ex_ishealing = undefined;
	self.ex_canheal = false;
	self.ex_inmenu = false;
	self.ex_isparachuting = undefined;
	self.ex_targeted = undefined;
	self.ex_confirmkill = false;
	self.ex_throwback = undefined;
	self.handling_mine = false;
	self.onflak = undefined;

	// some maps have drowning. Make sure we reset it on death
	self.drowning = undefined;

	// stock
	self.usedweapons = false;
	self.spamdelay = 0;
}

taunts(tauntno)
{
	self endon("kill_thread");

	chance = randomInt(20);

	if(chance == 10)
	{
		// convert number to str
		taunt_str = "" + tauntno;

		// delay for death sound to finish
		wait( [[level.ex_fpstime]](1.5) );

		// if the attacker is still here, play the sound now
		switch(randomInt(2))
		{
			case 1: { if(isPlayer(self)) self thread maps\mp\gametypes\_quickmessages::quicktauntsa(taunt_str, true); break; }
			default: { if(isPlayer(self)) self thread maps\mp\gametypes\_quickmessages::quicktauntsb(taunt_str, true); break; }
		}
	}
}

handleDeadBody(team, owner)
{
	switch(level.ex_deadbodyfx)
	{
		case 1: self thread bodySink(); break;
		case 2: self thread bodyRise(); break;
	}
}

bodySink()
{
	wait( [[level.ex_fpstime]](15) );
	
	for(i = 0; i < 100; i++)
	{
		if(!isDefined(self)) return;
		self.origin = self.origin - (0,0,0.2);
		wait( [[level.ex_fpstime]](0.05) );
	}
	if(isDefined(self)) self delete();
}

bodyRise()
{
	wait( [[level.ex_fpstime]](15) );

	for(i = 0; i < 150; i++)
	{
		if(!isDefined(self)) return;
		self.origin = self.origin + (0,0,0.2);
		wait( [[level.ex_fpstime]](0.05) );
	}
	if(isDefined(self)) self delete();
}

bloodonscreen()
{
	self endon("kill_thread");

	hud_index = playerHudIndex("bloodscreen1");
	if(hud_index != -1) return;

	size = randomint(48);
	hud_index = playerHudCreate("bloodscreen1", randomint(496), randomint(336), 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, true);
	if(hud_index == -1) playerHudSetShader(hud_index, "gfx/impact/flesh_hit2", 96 + size , 96 + size);

	size = randomint(48);
	hud_index = playerHudCreate("bloodscreen2", randomint(496), randomint(336), 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, true);
	if(hud_index == -1) playerHudSetShader(hud_index, "gfx/impact/flesh_hitgib", 96 + size , 96 + size);

	size = randomint(48);
	hud_index = playerHudCreate("bloodscreen3", randomint(496), randomint(336), 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, true);
	if(hud_index == -1) playerHudSetShader(hud_index, "gfx/impact/flesh_hit2", 96 + size , 96 + size);

	size = randomint(48);
	hud_index = playerHudCreate("bloodscreen4", randomint(496), randomint(336), 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, true);
	if(hud_index == -1) playerHudSetShader(hud_index, "gfx/impact/flesh_hitgib", 96 + size , 96 + size);

	wait( [[level.ex_fpstime]](4) );

	playerHudFade("bloodscreen1", 2, 0, 0);
	playerHudFade("bloodscreen2", 2, 0, 0);
	playerHudFade("bloodscreen3", 2, 0, 0);
	playerHudFade("bloodscreen4", 2, 0, 0);

	wait( [[level.ex_fpstime]](2) );

	playerHudDestroy("bloodscreen1");
	playerHudDestroy("bloodscreen2");
	playerHudDestroy("bloodscreen3");
	playerHudDestroy("bloodscreen4");
}

weaponfall(delay)
{
	self endon("kill_thread");

	// good strong healthy boy can hold weapon!
	if(self.health > 80) return;

	if(self.health > 50 && randomInt(100) < 50)
	{
		if(isPlayer(self)) self [[level.ex_dWeapon]]();
		wait( [[level.ex_fpstime]](delay) );
		if(isPlayer(self) && self.sessionstate == "playing") self [[level.ex_eWeapon]]();
	}
	else self thread extreme\_ex_weapons::dropcurrentweapon();
}

handleWelcome()
{
	self endon("kill_thread");
	self endon("ex_freefall");

	if(isPlayer(self))
	{
		// Resetting the tag ex_ispunished is done in resetFlagVars()

		// Did the Name Checker already tag the player for using an unacceptable name?
		if(isDefined(self.ex_isunknown) && self.ex_isunknown)
		{
			self thread extreme\_ex_namecheck::handleUnknown(false);
		}
		else
		{
			// Did the Name Checker already tag the player for using a duplicate name?
			if(isDefined(self.ex_isdupname) && self.ex_isdupname)
			{
				self thread extreme\_ex_namecheck::handleDupName();
			}
			else
			{
				// If Name Checker is disabled and Unknown Soldier handling is enabled,
				// check for unacceptable names ourselves
				if(level.ex_uscheck && extreme\_ex_namecheck::isUnknown(self))
				{
					self thread extreme\_ex_namecheck::handleUnknown(false);
				}
				else if(!level.ex_roundbased || game["roundnumber"] == 1)
				{
					self thread extreme\_ex_messages::welcomemsg();
				}
			}
		}
	}
}

