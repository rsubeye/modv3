#include extreme\_ex_airtrafficcontroller;
#include extreme\_ex_hudcontroller;
#include extreme\_ex_weapons;

main()
{
	level endon("ex_gameover");

	if(!level.ex_amc_perteam) return;

	spawnpoints = getentarray("mp_tdm_spawn", "classname");
	if(!spawnpoints.size) spawnpoints = getentarray("mp_dm_spawn", "classname");
	if(spawnpoints.size < 2) return;
	ammocratesInit(spawnpoints);

	// Routine for debugging objective slot management and crate status
	level.ammocrate_debug = false; // Do NOT comment out; set to false if no debugging messages are needed

	if(level.ex_amc_chutein)
	{
		// Chuting crate logic
		drop_wait = level.ex_amc_chutein;
		drop_switcher = 0;
		
		while(level.ex_amc_perteam)
		{
			wait( [[level.ex_fpstime]](drop_wait) );
			drop_wait = level.ex_amc_chutein_pause_all;

			// if entities monitor in defcon 3 or lower, suspend
			if(level.ex_entities_defcon < 4) continue;

			drop_count = 0;
			if(level.ex_amc_chutein_neutral)
			{
				ammocrate_team = "neutral";
				drop_count = (level.ex_amc_perteam * 2) - getAmmocratesAllocated();
				if(drop_count < 0) drop_count = 0; // Merely to let debug messages look nice
				if(drop_count > 0 && level.ex_amc_chutein_slice)
				{
					if(level.ex_amc_chutein_slice < drop_count)
						drop_count = level.ex_amc_chutein_slice;
					drop_wait = level.ex_amc_chutein_pause_slice;
				}
			}
			else
			{
				if(drop_switcher%2 == 0) ammocrate_team = "allies";
					else ammocrate_team = "axis";

				drop_count = level.ex_amc_perteam - getAmmocratesForTeam(ammocrate_team);
				if(drop_count < 0) drop_count = 0; // Merely to let debug messages look nice
				if(drop_count > 0)
				{
					if(level.ex_amc_chutein_slice && level.ex_amc_chutein_slice < drop_count)
						drop_count = level.ex_amc_chutein_slice;
					drop_switcher++;
					if(drop_switcher%2 == 0) drop_wait = level.ex_amc_chutein_pause_slice;
						else drop_wait = 0.5;
				}
			}

			if(level.ammocrate_debug && drop_count) logprint("AMMOCRATES: dropping " + drop_count + " crates for " + ammocrate_team + "\n");

			plane_angle = randomInt(360);
			for(i = 0; i < drop_count; i++)
			{
				ammocrate_index = getAmmocrateIndex();
				if(ammocrate_index != 999)
				{
					ammocrate_compass = level.ex_amc_compass;
					// If not a neutral drop, don't let a team allocate all or too many compass slots at once
					if(!level.ex_amc_chutein_neutral && !level.ex_amc_chutein_slice && (i > level.ex_amc_maxobjteam - 1)) ammocrate_compass = false;
					if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " has compass request flag: " + ammocrate_compass + "\n");
					ammoCrateAlloc(ammocrate_index, ammocrate_team, ammocrate_compass);
					if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " acquired objective index: " + level.ammocrates[ammocrate_index].objective + "\n");
					level thread ammoCratePlane(ammocrate_index, plane_angle);
				}
				else level.ex_amc_perteam--;
				// do not wait, because in 2.8 the air traffic controller will handle the mutual distance between airplanes
			}

			if(drop_count == 0)
			{
				if(!level.ex_amc_chutein_lifespan) break;
				level thread ammocratesOnGroundMonitor();
				level waittill("ammocrate_countdown");
				drop_wait += level.ex_amc_chutein_lifespan;
				if(level.ammocrate_debug) logprint("AMMOCRATES: all crates touched ground. Waiting " + drop_wait + " seconds for next drop.\n");
			}
		}
	}
	else
	{
		// Fixed crate logic
		drop_count = level.ex_amc_perteam;
		ammocrate_team = "allies";
		for(i = 0; i < 2; i++)
		{
			if(level.ammocrate_debug && drop_count) logprint("AMMOCRATES: dropping " + drop_count + " crates for " + ammocrate_team + "\n");

			for(j = 0; j < drop_count; j++)
			{
				ammocrate_index = getAmmocrateIndex();
				if(ammocrate_index != 999)
				{
					ammocrate_compass = level.ex_amc_compass;
					// Don't let a team allocate all or too many compass slots at once
					if(j > level.ex_amc_maxobjteam - 1) ammocrate_compass = false;
					if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " has compass request flag: " + ammocrate_compass + "\n");
					ammoCrateAlloc(ammocrate_index, ammocrate_team, ammocrate_compass);
					if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " acquired objective index: " + level.ammocrates[ammocrate_index].objective + "\n");
					level thread ammoCrateFixed(ammocrate_index);
				}
			}

			ammocrate_team = "axis";
		}
	}
}

ammocratesOnGroundMonitor()
{
	level endon("ex_gameover");

	wait( [[level.ex_fpstime]](0.1) ); // Wait in case all crates already touched ground (the monitor would fire its notify before the waittill started).
	if(level.ammocrate_debug) logprint("AMMOCRATES: waiting for " + getAmmocratesAllocated() + " crates to touch ground.\n");
	while(getAmmocratesAllocated() != getAmmocratesWithStatus("onground")) wait( [[level.ex_fpstime]](1) );
	level notify("ammocrate_countdown");
}

ammocratesInit(spawnpoints)
{
	level.ammocrates = [];
	level.ex_amc_maxobjteam = 4;

	for(i = 0; i < spawnpoints.size; i++)
	{
		level.ammocrates[i] = spawnstruct();
		level.ammocrates[i].spawnpoint = spawnpoints[i].origin;
		level.ammocrates[i].allocated = false;
		level.ammocrates[i].objective = 0;
		level.ammocrates[i].team = "none";
		level.ammocrates[i].status = "none";
	}

	if(level.ex_teamplay)
	{
		if((level.ex_amc_perteam * 2) > level.ammocrates.size)
			level.ex_amc_perteam = int(level.ammocrates.size / 2);
	}
	else
	{
		level.ex_amc_perteam = int(level.ex_amc_perteam / 2);
		if(level.ex_amc_perteam > level.ammocrates.size)
			level.ex_amc_perteam = level.ammocrates.size;
	}
}

ammoCrateAlloc(ammocrate_index, ammocrate_team, oncompass)
{
	if(!isDefined(level.ammocrates)) return false;

	crate_objnum = 0;
	if(oncompass)
	{
		if(ammocrate_team == "neutral")
		{
			if(getAmmocratesOnCompass() < (level.ex_amc_maxobjteam * 2)) crate_objnum = levelHudGetObjective();
		}
		else if(getAmmocratesOnCompassForTeam(ammocrate_team) < level.ex_amc_maxobjteam) crate_objnum = levelHudGetObjective();
	}

	level.ammocrates[ammocrate_index].allocated = true;
	level.ammocrates[ammocrate_index].objective = crate_objnum;
	level.ammocrates[ammocrate_index].team = ammocrate_team;
	level.ammocrates[ammocrate_index].status = "alloc";
	return true;
}

ammoCrateFree(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return;

	if(level.ammocrates[ammocrate_index].objective)
		levelHudFreeObjective(level.ammocrates[ammocrate_index].objective);

	level.ammocrates[ammocrate_index].allocated = false;
	level.ammocrates[ammocrate_index].objective = 0;
	level.ammocrates[ammocrate_index].team = "none";
	level.ammocrates[ammocrate_index].status = "none";
}

IsAmmocrateAllocated(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return true;
	if(ammocrate_index > level.ammocrates.size-1) return true;

	return level.ammocrates[ammocrate_index].allocated;
}

getAmmocrateIndex()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrate_index = 999;
	rejected = true;
	mindist = 750;
	iterations = 0;

	while(rejected && iterations < level.ammocrates.size * 2)
	{
		wait( [[level.ex_fpstime]](0.05) );
		iterations++;

		ammocrate_index = randomInt(level.ammocrates.size);
		if(IsAmmocrateAllocated(ammocrate_index)) continue;

		rejected = false;
		for(i = ammocrate_index; i < level.ammocrates.size; i++)
			if(level.ammocrates[i].allocated && distance(level.ammocrates[i].spawnpoint, level.ammocrates[ammocrate_index].spawnpoint) < mindist)
				rejected = true;

		if(!rejected)
		{
			for(i = 0; i < ammocrate_index; i++)
				if(level.ammocrates[i].allocated && distance(level.ammocrates[i].spawnpoint, level.ammocrates[ammocrate_index].spawnpoint) < mindist)
					rejected = true;
		}

		if(level.ammocrate_debug && rejected) logprint("AMMOCRATES: crate index " + ammocrate_index + " rejected.\n");
	}

	if(IsAmmocrateAllocated(ammocrate_index))
	{
		// Still no valid spawnpos? Get the first free one in the list
		for(i = 0; i < level.ammocrates.size; i++)
		{
			ammocrate_index = i;
			if(!level.ammocrates[i].allocated) break;
		}
	}

	if(IsAmmocrateAllocated(ammocrate_index)) return 999;
		else return ammocrate_index;
}

getAmmocratesAllocated()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].allocated) ammocrates++;

	return ammocrates;
}

getAmmocrateSpawnpoint(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return 0;

	return level.ammocrates[ammocrate_index].spawnpoint;
}

getAmmocrateObjective(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return 0;

	return level.ammocrates[ammocrate_index].objective;
}

getAmmocrateTeam(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return "none";

	return level.ammocrates[ammocrate_index].team;
}

setAmmocrateTeam(ammocrate_index, ammocrate_team)
{
	if(!isDefined(level.ammocrates)) return;

	// Valid are: "neutral", "allies", "axis"
	level.ammocrates[ammocrate_index].team = ammocrate_team;
	if(level.ex_teamplay && level.ex_amc_compass && level.ammocrates[ammocrate_index].objective)
		objective_team(level.ammocrates[ammocrate_index].objective, ammocrate_team);
}

getAmmocrateStatus(ammocrate_index)
{
	if(!isDefined(level.ammocrates)) return "none";

	return level.ammocrates[ammocrate_index].status;
}

getAmmocratesWithStatus(ammocrate_status)
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].status == ammocrate_status) ammocrates++;

	return ammocrates;
}

setAmmocrateStatus(ammocrate_index, ammocrate_status)
{
	if(!isDefined(level.ammocrates)) return;

	// Valid are: "none", "alloc", "inplane", "inair", "onground"
	if(level.ammocrate_debug) logprint("AMMOCRATES: crate " + ammocrate_index + " acquired status " + ammocrate_status + "\n");
	level.ammocrates[ammocrate_index].status = ammocrate_status;
}

getAmmocratesForTeam(ammocrate_team)
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].team == ammocrate_team) ammocrates++;

	return ammocrates;
}

getAmmocratesOnCompassForTeam(ammocrate_team)
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].team == ammocrate_team && level.ammocrates[i].objective != 0) ammocrates++;

	return ammocrates;
}

getAmmocratesOnCompass()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = 0;
	for(i = 0; i < level.ammocrates.size; i++)
		if(level.ammocrates[i].objective != 0) ammocrates++;

	return ammocrates;
}

getAmmocratesDropped()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = getentarray("ammocrate_chute", "targetname");

	return ammocrates.size;
}

getAmmocratesFixed()
{
	if(!isDefined(level.ammocrates)) return 999;

	ammocrates = getentarray("ammocrate_fixed", "targetname");

	return ammocrates.size;
}

ammoCratePlane(ammocrate_index, plane_angle)
{
	level endon("ex_gameover");

	setAmmocrateStatus(ammocrate_index, "inplane");

	plane_team = getAmmocrateTeam(ammocrate_index);

	plane_models[0] = "xmodel/vehicle_condor";
	plane_models[1] = "xmodel/vehicle_mebelle";
	if(plane_team == "axis") plane_model_index = 0;
		else if(plane_team == "allies") plane_model_index = 1;
			else plane_model_index = randomInt(plane_models.size);
	plane_model = plane_models[plane_model_index];

	plane_sounds[0] = "stuka_flyby_1";
	plane_sounds[1] = "stuka_flyby_2";
	plane_sound = plane_sounds[randomInt(plane_sounds.size)];

	// Get height of plane and drop position
	targetpos = getAmmocrateSpawnpoint(ammocrate_index);
	targetpos_x = targetpos[0] - 150 + randomInt(300);
	targetpos_y = targetpos[1] - 150 + randomInt(300);
	targetpos_z = game["mapArea_Max"][2] - 200;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= targetpos_z)) targetpos_z = level.ex_planes_altitude;
	plane_droppos = (targetpos_x, targetpos_y, targetpos_z);

	// Calculate plane waypoints
	plane_firsthalf = planeStartEnd(plane_droppos, plane_angle);
	plane_sechalf = planeStartEnd((plane_firsthalf[1]), plane_angle);
	if(plane_sechalf[2] == 1) plane_firsthalf[1] = plane_sechalf[1];
	plane_startpos = plane_firsthalf[0];
	plane_endpos = plane_firsthalf[1];

	// request a slot and wait for clearance
	self waittill(planeSlot(1));

	// Create and move airplane
	plane_index = planeCreate(1, level, plane_team, plane_model, plane_startpos, plane_angle, plane_sound);
	plane_speed = 30;
	flighttime = calcTime(plane_startpos, plane_endpos, plane_speed);
	level.planes[plane_index].model moveto(plane_endpos, flighttime);

	// Drop crate when passing drop position
	crate_dropped = false;
	for(i = 0; i < flighttime; i += 0.1)
	{
		if(!crate_dropped && (distance(plane_droppos, level.planes[plane_index].model.origin) < 200))
		{
			level thread ammoCrateDrop(plane_index, ammocrate_index, level.planes[plane_index].model.origin);
			level.planes[plane_index].isdroppingpayload = true;
			crate_dropped = true;
		}

		if(level.planes[plane_index].health <= 0 || (level.planes[plane_index].crash && !level.planes[plane_index].isdroppingpayload && (distance(game["playArea_Centre"], level.planes[plane_index].model.origin) < 400)) )
		{
			level thread planeCrash(plane_index, plane_speed);
			if(!crate_dropped) ammoCrateFree(ammocrate_index);
			return;
		}

		wait( [[level.ex_fpstime]](0.1) );
	}

	planeFree(plane_index);
	if(!crate_dropped) ammoCrateFree(ammocrate_index);
}

ammoCrateDrop(plane_index, ammocrate_index, ammocrate_droppos)
{
	level endon("ex_gameover");

	setAmmocrateStatus(ammocrate_index, "inair");

	crate = spawn("script_model", ammocrate_droppos);
	crate setmodel("xmodel/ammocrate_rearming");
	crate.targetname = "ammocrate_chute";
	crate.index = ammocrate_index;
	crate.timeout = false;

	// Let it freefall for a brief moment
	crate_speed = 10;
	crate_endpos = crate.origin + (0, 0, -400);
	falltime = calcTime(crate.origin, crate_endpos, crate_speed);
	crate moveto(crate_endpos, falltime);
	wait( [[level.ex_fpstime]](falltime) );

	level.planes[plane_index].isdroppingpayload = false;

	// Define final position
	targetpos = getAmmocrateSpawnpoint(ammocrate_index);
	crate_endpos = targetpos - ( 15, 15, 0) + ( randomInt(31), randomInt(31), 0);
	trace = bulletTrace(crate_endpos + (0, 0, 100), crate_endpos + (0, 0, -1200), false, undefined);
	if(trace["fraction"] < 1.0)
	{
		ground = trace["position"];
		if(ground[2] > targetpos[2] && (ground[2] - targetpos[2] > 50)) ground = targetpos;
	}
	else ground = targetpos;

	// Create parachute
	crate.parachute = spawn("script_model", crate.origin);
	switch(level.ammocrates[ammocrate_index].team)
	{
		case "axis": crate.parachute setModel(game["chute_cargo_axis"]); break;
		case "allies": crate.parachute setModel(game["chute_cargo_allies"]); break;
		default: crate.parachute setModel(game["chute_cargo_neutral"]);
	}

	// Create anchor and link parachute to it
	crate.anchor = spawn("script_model", crate.parachute.origin);
	crate.anchor.angles = crate.angles;
	crate.parachute linkto(crate.anchor);
	crate linkto(crate.anchor);
	crate.anchor.origin = crate.origin;

	// Descent to final position
	crate_speed = 3;
	falltime = calcTime(crate.origin, crate_endpos, crate_speed);
	crate.anchor moveto(crate_endpos, falltime);
	wait( [[level.ex_fpstime]](falltime) );

	// Clean up parachute
	crate unlink();
	crate.parachute delete();
	crate.anchor delete();
	crate.origin = ground;

	// If crate has limited lifespan, wait for signal to start countdown
	crate thread ammoCrateTimer(level.ex_amc_chutein_lifespan);

	// Now let the crate do the thinking
	crate thread ammoCrateThink();
}

ammoCrateFixed(ammocrate_index)
{
	// Define fixed position
	targetpos = getAmmocrateSpawnpoint(ammocrate_index);
	crate_endpos = targetpos - ( 15, 15, 0) + ( randomInt(31), randomInt(31), 0);
	trace = bulletTrace(crate_endpos + (0, 0, 100), crate_endpos + (0, 0, -1200), false, undefined);
	ground = trace["position"];
	if(ground[2] > targetpos[2] && (ground[2] - targetpos[2] > 50)) ground = targetpos;

	crate = spawn("script_model", ground);
	crate setmodel("xmodel/ammocrate_rearming");
	crate.targetname = "ammocrate_fixed";
	crate.index = ammocrate_index;
	crate.timeout = false;

	// Now let the crate do the thinking
	crate thread ammoCrateThink();
}

ammoCrateThink()
{
	level endon("ex_gameover");
	level endon("round_ended");

	setAmmocrateStatus(self.index, "onground");

	self thread ammoCrateShowObjective();
	
	while(!self.timeout)
	{
		wait( [[level.ex_fpstime]](0.1) );

		ammocrate_team = getAmmocrateTeam(self.index);
		
		// Look for any players near enough to the crate to rearm
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(!isPlayer(players[i]) || players[i].sessionstate != "playing") continue;

			// If crate reached end-of-life, stop all services
			if(self.timeout) continue;

			// If moving or not the right stance, don't try to rearm the player
			if(players[i].ex_moving || players[i] [[level.ex_getstance]](false) == 2) continue;

			// If player is ADS, do not rearm
			if(players[i] playerADS()) continue;

			// Do not rearm bots
			if(isDefined(players[i].pers["isbot"])) continue;

			// Prevent rearming while being frozen in freezetag
			if(level.ex_currentgt == "ft" && isDefined(players[i].frozenstate) && players[i].frozenstate == "frozen") continue;

			if(players[i] isOnGround() && !isDefined(players[i].ex_amc_rearm))
			{
				dist = distance(players[i].origin, self.origin);
				if((dist < 36) && (!level.ex_teamplay || (level.ex_teamplay && (ammocrate_team == players[i].pers["team"] || ammocrate_team == "neutral" )))) players[i] thread ammoCratePlayerRearm(self);
			}
		}
	}

	self notify("ammocrate_deleted"); // Signal ammoCrateShowObjective() to end
	wait( [[level.ex_fpstime]](0.1) ); // Wait for all threads to die
	ammoCrateFree(self.index);
	self delete();
}

ammoCrateTimer(timeout)
{
	level endon("ex_gameover");
	level endon("round_ended");

	if(!timeout) return;
	
	level waittill("ammocrate_countdown");

	for(i = 0; i < timeout; i++) wait( [[level.ex_fpstime]](1) );

	self.timeout = true;
}

ammoCratePlayerRearm(crate)
{
	self endon("disconnect");

	if(isDefined(self.ex_amc_rearm)) return;
	self.ex_amc_rearm = true;

	monitor = true;
	linked = false;

	// Set how long it takes to replenish
	prog_limit = 5;
	if(level.ex_medicsystem) prog_limit = 8;

	while(monitor && isDefined(crate) && !crate.timeout && isPlayer(self) && self.sessionstate == "playing" && distance(self.origin, crate.origin) < 36 && self [[level.ex_getstance]](true) != 2)
	{
		// Display the message
		if(!isDefined(self.ex_amc_msg_displayed))
		{
			self.ex_amc_msg_displayed = true;
			self ammoCrateMessage(&"AMMOCRATE_ACTIVATE");
		}

		wait( [[level.ex_fpstime]](0.05) );

		// Wait until they press the USE key
		if(!self useButtonPressed()) continue;

		// Optionally give points if player conquered a neutral crate
		if(getAmmocrateTeam(crate.index) == "neutral")
		{
			setAmmocrateTeam(crate.index, self.pers["team"]);

			if(level.ex_amc_chutein_score == 1 || level.ex_amc_chutein_score == 3)
				self thread [[level.pscoreproc]](1, "bonus");
		}

		// Make sure they want to rearm, and have not just stopped sprinting over one
		count = 0;
		while(self useButtonPressed() && count < 20)
		{
			wait( level.ex_fps_frame );
			count++;
		}
		if(count < 20) continue;

		// if you got into the gunship by hitting USE, stop rearming attempt
		if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
		    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) continue;

		// OK, they're still holding so lets rearm them
		if(self useButtonPressed())
		{
			if(isDefined(crate))
			{
				self linkTo(crate);
				linked = true;
			}
			
			weaponsdone = undefined;
			grenadesdone = undefined;
			firstaiddone = undefined;

			playerHudCreateBar(prog_limit, &"AMMOCRATE_REARMING_WEAPONS", false);

			progresstime = 0;
			while(isPlayer(self) && isDefined(crate) && self useButtonPressed() && progresstime <= prog_limit && !crate.timeout)
			{
				wait( level.ex_fps_frame );
				progresstime += level.ex_fps_frame;

				if(progresstime >= 2 && !isDefined(weaponsdone))
				{
					self thread replenishWeapons();
					playerHudBarSetText(&"AMMOCRATE_REARMING_GRENADES");
					weaponsdone = true;
				}
				else if(progresstime >= 5 && !isDefined(grenadesdone))
				{
					self thread replenishGrenades();
					if(level.ex_medicsystem) playerHudBarSetText(&"AMMOCRATE_REARMING_FIRSTAID");
					grenadesdone = true;
				}
				else if(progresstime >= 8 && !isDefined(firstaiddone))
				{
					if(level.ex_medicsystem) self thread replenishFirstaid();
					firstaiddone = true;
				}
			}

			monitor = false;
		}
	}

	// Clear the bar graphic and reset the variables
	if(linked) self unlink();
	self [[level.ex_eWeapon]]();
	playerHudDestroyBar();
	self.ex_amc_msg_displayed = undefined;
	self.ex_amc_rearm = undefined;
}

ammoCrateMessage(msg)
{
	self endon("kill_thread");

	if(!isDefined(msg)) return;

	switch(level.ex_amc_msg)
	{
		case 0: self iprintln(msg); break;
		case 1: self iprintlnbold(msg); break;
		case 2: self thread playerHudAnnounce(msg); break;
	}
}

ammoCrateShowObjective()
{
	level endon("ex_gameover");
	self endon("ammocrate_deleted");

	crate_objnum = getAmmocrateObjective(self.index);
	if(!crate_objnum) return;
	
	// Show to all
	crate_objteam = "none";

	// If team based game, make sure teams only can see own crates
	if(level.ex_teamplay)
	{
		switch(getAmmocrateTeam(self.index))
		{
			case "allies":
				crate_objteam = "allies"; // Show to allies only
				break;
			case "axis":
				crate_objteam = "axis"; // Show to axis only
				break;
		}
	}

	objective_add(crate_objnum, "current", self.origin, "compassping_ammocrate");
	objective_team(crate_objnum, crate_objteam);

	if(level.ex_amc_compass < 2) return;
	if(!level.ex_teamplay && !level.ex_amc_chutein_score) return;

	while(getAmmocrateTeam(self.index) == "neutral")
	{
		wait( [[level.ex_fpstime]](0.5) );
		objective_state(crate_objnum, "invisible");
		wait( [[level.ex_fpstime]](0.5) );
		objective_state(crate_objnum, "current");
	}
}
