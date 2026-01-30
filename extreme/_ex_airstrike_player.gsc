#include extreme\_ex_hudcontroller;
#include extreme\_ex_airtrafficcontroller;

start(delay)
{
	self endon("kill_thread");

	if(self.ex_air_strike) return;

	self notify("end_airstrike");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_airstrike");
	
	self.ex_air_strike = true;

	// wait the first
	if(!isDefined(delay)) delay = level.ex_rank_airstrike_first;
	wait( [[level.ex_fpstime]](delay) );

	// check for napalm
	self.ex_napalm = false;

	switch(level.ex_rank_wmdtype)
	{
		case 2: // random rank
			if(self.pers["rank"] >= level.ex_rank_special && randomInt(100) < level.ex_rank_napalm_chance) self.ex_napalm = true;
			break;

		case 3: // allowed random
			if(level.ex_rank_allow_special)
			{
				if(!level.ex_rank_allow_airstrike) self.ex_napalm = true;
				else if(randomInt(100) < level.ex_rank_napalm_chance) self.ex_napalm = true;
			}
			break;

		default: // fixed rank
			if(self.pers["rank"] == 7 && randomInt(100) < level.ex_rank_napalm_chance) self.ex_napalm = true;
			break;
	}

	while(self.ex_air_strike)
	{
		// let them know the airstrike is available
		if(!self.ex_napalm)
		{
			if((level.ex_arcade_shaders & 4) == 4) self thread extreme\_ex_arcade::showArcadeShader("x2_airstrikeunlock", level.ex_arcade_shaders_perk);
				else self iprintlnbold(&"AIRSTRIKE_READY");
		}
		else
		{
			if((level.ex_arcade_shaders & 4) == 4) self thread extreme\_ex_arcade::showArcadeShader("x2_napalmunlock", level.ex_arcade_shaders_perk);
				else self iprintlnbold(&"AIRSTRIKE_READY_NAPALM");
		}

		self teamSound("airstk_ready", 1);
			
		// set up the screen icon
		if(self.ex_napalm) playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_napalm_hudicon"]);
			else playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_airstrike_hudicon"]);

		// monitor for binocular fire
		self thread waitForUse();
		
		// show hint
		self thread playerHudAnnounce(&"WMD_ACTIVATE_HINT");

		// wait until they use airstrike
		self waittill("airstrike_over");

		if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"AIRSTRIKE_WAIT");
		self teamSound("airstk_reload",3);

		// now wait for one interval
		wait( [[level.ex_fpstime]](level.ex_rank_airstrike_next) );

		// randomize napalm again
		if(self.ex_napalm && randomInt(100) > level.ex_rank_napalm_chance) self.ex_napalm = false;
	}
}	

waitForUse()
{
	self endon("kill_thread");
	self endon("end_airstrike");
	self endon("end_waitforuse");

	self.ex_callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.ex_callingwmd && (!level.ex_specials || !extreme\_ex_specials::playerPerkIsLocked("cam")))
		{
			self thread waitForBinocUse();
			if(!self.ex_napalm) self thread playerHudAnnounce(&"WMD_AIRSTRIKE_HINT");
				else self thread playerHudAnnounce(&"WMD_NAPALM_HINT");
		}

		wait( [[level.ex_fpstime]](0.2) );
	}
}

waitForBinocUse()
{
	self endon("kill_thread");
	self endon("binocular_exit");
	self endon("end_waitforuse");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed() && !self.ex_callingwmd)
		{
			self.ex_callingwmd = true;
			self thread callRadio();
			while(self usebuttonpressed()) wait( [[level.ex_fpstime]](0.05) );
		}
		wait( [[level.ex_fpstime]](0.05) );
	}
}

callRadio()
{
	self endon("kill_thread");

	// end binoculars animated crosshair
	self notify("kill_aimrig");

	if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"AIRSTRIKE_RADIO_IN");

	targetPos = getTargetPosition();
	friendly = friendlyInstrikezone(targetpos);

	if(!level.ex_rank_wmdspeedup)
	{
		self teamSound("airstk_firemission", 3.6);
		for(i = 1; i < 4; i++) self teamsound("airstk_" + randomInt(8), 0.6);
		self teamSound("airstk_pointfuse", 3);
	}

	if(isDefined(targetPos) && isDefined(friendly) && friendly == false)
	{
		// notify threads
		self notify("end_waitforuse");

		// clear hud icon
		playerHudDestroy("wmd_icon");

		if((level.ex_arcade_shaders & 4) != 4) self iprintlnbold(&"AIRSTRIKE_ONWAY");
		self teamSound("airstk_ontheway",4);

		// player has used weapon
		self.usedweapons = true;

		airstrike = spawn("script_origin", targetpos);
		airstrike thread fireBarrage(self);

		if(level.ex_rank_airstrike_alert) airstrike thread extreme\_ex_utils::playSoundLoc("air_raid",targetpos);
	}
	else if(!isDefined(targetPos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_NOT_VALID");
		self teamSound("airstk_novalid",3);
	}
	else if(isDefined(friendly) && friendly == true)
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_FRIENDLY_WARNING");
		self teamSound("airstk_frndly",3);
	}
	else if(isDefined(targetPos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"AIRSTRIKE_TO_CLOSE_WARNING");
		self teamSound("airstk_tooclose",3);
	}

	self.ex_callingwmd = false;
}

getTargetPosition()
{
	startOrigin = self getEye() + (0,0,20);
	forward = anglesToForward(self getplayerangles());
	forward = [[level.ex_vectorscale]](forward, 100000);
	endOrigin = startOrigin + forward;

	trace = bulletTrace( startOrigin, endOrigin, false, self );
	if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") return (undefined);
		else return (trace["position"]);
}

fireBarrage(owner)
{
	// drop flare
	if(level.ex_rank_wmd_flare) playfx(level.ex_effect["flare_indicator"], self.origin);

	if(level.ex_planes_flak) level thread extreme\_ex_skyeffects::fireFlaks(10, 0.25);

	// planes angle
	plane_angle = randomInt(360);

	// make sure the first plane is on target
	x_adjust = 0;
	y_adjust = 0;

	// create planes
	plane_count = 1;
	if(!owner.ex_napalm)
	{
		if(!level.ex_rank_airstrike_planes) plane_count = randomInt(3) + 1;
			else plane_count = level.ex_rank_airstrike_planes;
	}
	for(i = 0; i < plane_count; i++)
	{
		x = self.origin[0] + x_adjust;
		y = self.origin[1] + y_adjust;
		self thread createPlanes( (x,y,self.origin[2]), plane_angle, owner);
		x_adjust = randomInt(250);
		y_adjust = randomInt(250);
		// do not wait, because in 2.8 the air traffic controller will handle the mutual distance between airplanes
	}

	owner teamSound("pilot_cmg_target", 4);
	wait( [[level.ex_fpstime]](3) );
	if(isPlayer(owner)) owner teamSound("flack_hang_on", 3);

	// wait for all planes to finish
	for(i = 0; i < plane_count; i++)
		self waittill("wmdplane_finished");

	if(isPlayer(owner)) owner notify ("airstrike_over");
	self delete();
}

createPlanes(targetpos, plane_angle, owner)
{
	// plane models
	if(!isPlayer(owner)) return;
	if(owner.pers["team"] == "axis") plane_model = "xmodel/vehicle_condor";
		else plane_model = "xmodel/vehicle_mebelle";

	// plane sounds
	plane_sounds[0] = "stuka_flyby_1";
	plane_sounds[1] = "stuka_flyby_2";
	plane_sound = plane_sounds[randomInt(plane_sounds.size)];

	// calculate plane waypoints
	targetpos_x = targetpos[0];
	targetpos_y = targetpos[1];
	targetpos_z = game["mapArea_Max"][2] - 200;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= targetpos_z)) targetpos_z = level.ex_planes_altitude;
	plane_droppos = (targetpos_x, targetpos_y, targetpos_z);

	plane_firsthalf = planeStartEnd(plane_droppos, plane_angle);
	plane_sechalf = planeStartEnd((plane_firsthalf[1]), plane_angle);
	if(plane_sechalf[2] == 1) plane_firsthalf[1] = plane_sechalf[1];
	plane_startpos = plane_firsthalf[0];
	plane_endpos = plane_firsthalf[1];

	// calculate drop distance
	mapsquare = (game["mapArea_Width"] + game["mapArea_Length"]) / 2;
	mapheight = game["mapArea_Max"][2];
	if(mapsquare >= 8000 && mapheight >= 2000) dropdist = 2500;
		else if(mapsquare >= 7000 && mapheight >= 1500) dropdist = 2000;
			else dropdist = 1500;
	maxdist = distance(plane_startpos, plane_droppos);
	if(maxdist < dropdist) dropdist = maxdist;
	if(dropdist < 1000) droprate = 0.1;
		else droprate = 0.2;

	// request a slot and wait for clearance
	self waittill(planeSlot(2));

	// create and move airplane
	plane_index = planeCreate(2, owner, owner.pers["team"], plane_model, plane_startpos, plane_angle, plane_sound, "wmdplane_finished");
	plane_speed = 30; // bombers
	flighttime = calcTime(plane_startpos, plane_endpos, plane_speed);
	level.planes[plane_index].model moveto(plane_endpos, flighttime);

	bombs_dropped = false;
	for(i = 0; i < flighttime; i += 0.1)
	{
		if(!bombs_dropped && (distance(plane_droppos, level.planes[plane_index].model.origin) < dropdist) )
		{
			// DEBUG: black line from drop to target
			//level thread extreme\_ex_utils::dropLine(plane_droppos, targetpos, (0,0,0));
			owner teamSound("fire_away",1);
			level thread bombSetup(plane_index, targetpos, droprate);
			level.planes[plane_index].isdroppingpayload = true;
			bombs_dropped = true;
		}

		if(level.planes[plane_index].health <= 0 || (level.planes[plane_index].crash && !level.planes[plane_index].isdroppingpayload && (distance(game["playArea_Centre"], level.planes[plane_index].model.origin) < dropdist * 2)) )
		{
			owner teamsound("airstk_vbc",1);
			level thread planeCrash(plane_index, plane_speed);
			return;
		}

		wait( [[level.ex_fpstime]](0.1) );
	}

	planeFree(plane_index);
}

bombSetup(plane_index, targetpos, droprate)
{
	bombcount = 0;
	bombno = randomInt(3) + 4;

	linecolor = (randomFloat(1),randomFloat(1),randomFloat(1));

	while(bombcount < bombno)
	{
		thread dropBomb(plane_index, targetpos, linecolor);
		bombcount++;
		wait( [[level.ex_fpstime]](droprate) );
	}

	level.planes[plane_index].isdroppingpayload = false;
}

dropBomb(plane_index, targetpos, linecolor)
{
	if(!isDefined(level.planes[plane_index].model)) return;

	// get the impact point
	startpos = level.planes[plane_index].model.origin;
	impactpos = calcShellPos(plane_index, targetpos, 100000, true);

	// DEBUG: colored line from plane origin to impact
	//level thread extreme\_ex_utils::dropLine(startpos, impactpos, linecolor, 300);

	// bomb falltime
	falltime = calcTime(startpos, impactpos, 25);

	// spawn the bomb and drop it
	bomb = spawn("script_model", startpos);
	bomb.angles = level.planes[plane_index].model.angles + (-180 + randomint(50),0,0);
	bomb setModel("xmodel/prop_stuka_bomb");
	bomb moveto(impactpos + (0,0,-100), falltime);

	// play the incoming sound falling sound
	ms = randomInt(14) + 1;
	bomb playsound("mortar_incoming" + ms);

	// wait for it to hit
	wait( [[level.ex_fpstime]](falltime) );
	bomb hide();

	// play the explosion sound
	ms = randomInt(18) + 1;
	bomb playsound("mortar_explosion" + ms);

	// do the damage
	if(isPlayer(level.planes[plane_index].owner) && level.planes[plane_index].owner.sessionstate != "spectator")
	{
		if(isDefined(level.planes[plane_index].owner.ex_napalm) && level.planes[plane_index].owner.ex_napalm == true)
			bomb thread extreme\_ex_utils::scriptedfxradiusdamage(level.planes[plane_index].owner, undefined, "MOD_GRENADE", "planebomb_mp", level.ex_airstrike_radius, 500, 400, "plane_bomb", undefined, true, true, true, "napalm");
		else
			bomb thread extreme\_ex_utils::scriptedfxradiusdamage(level.planes[plane_index].owner, undefined, "MOD_GRENADE", "planebomb_mp", level.ex_airstrike_radius, 500, 400, "plane_bomb", undefined, true, true, true);

		thread extreme\_ex_specials_gml::perkRadiusDamage(bomb.origin, level.planes[plane_index].team, level.ex_airstrike_radius, 500);
		thread extreme\_ex_specials_flak::perkRadiusDamage(bomb.origin, level.planes[plane_index].team, level.ex_airstrike_radius, 500);
	}
	else
		bomb thread extreme\_ex_utils::scriptedfxradiusdamage(bomb, undefined, "MOD_GRENADE", "planebomb_mp", level.ex_airstrike_radius, 0, 0, "plane_bomb", undefined, true, true, true);

	wait( [[level.ex_fpstime]](1) );
	bomb delete();
}

calcShellPos(plane_index, targetpos, dist, oneshot)
{
	origin = level.planes[plane_index].model.origin;
	angle = randomFloat(360);
	radius = randomFloat(level.ex_rank_airstrike_radius);
	impactpos = targetpos + (cos(angle) * radius, sin(angle) * radius, 0);

	vangles = vectortoangles(vectornormalize(impactpos - origin));
	vangles = (vangles[0], level.planes[plane_index].model.angles[1], vangles[2]);
	forwardvector = anglestoforward(vangles);

	forwardpos = origin + [[level.ex_vectorscale]](forwardvector, dist);
	trace = bulletTrace(origin, forwardpos, false, level.planes[plane_index].model);
	if(trace["fraction"] != 1) origin = trace["position"];
		else origin = forwardpos;

	return(origin);
}

friendlyInStrikeZone(targetPos)
{
	// return if friendly fire check has been disabled
	if(level.ex_rank_wmd_checkfriendly == 0) return false;

	// dont need to check friendly if gametype is not teamplay
	if(!level.ex_teamplay) return false;

	if(!isDefined(targetPos)) return (undefined);

	if(distance(targetPos, self.origin) <= 1000) return (undefined);

	// check if players in the same team are in targetzone
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(self) && isPlayer(players[i]))
		{
			if(players[i].sessionstate == "playing" && players[i].pers["team"] == self.pers["team"])
			{
				if(distance(targetpos, players[i].origin) <= 1000)
					return true;
			}
		}
	}
	return false;
}

teamSound(aliasPart, waitTime)
{
	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
			case "american":
				self playLocalSound("us_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
			case "british":
				self playLocalSound("uk_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
			default:
				self playLocalSound("ru_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
		}
	}
	else
	{
		self playLocalSound("ge_" + aliasPart);
		wait( [[level.ex_fpstime]](waitTime) );
	}
}
