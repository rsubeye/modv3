#include extreme\_ex_airtrafficcontroller;

start()
{
	plane_count = randomInt(level.ex_planes_max - level.ex_planes_min) + level.ex_planes_min;
	plane_angle = randomInt(360);

	if(level.ex_planes_alert) thread extreme\_ex_utils::playSoundLoc("air_raid",(0,0,0));
	if(level.ex_planes_flak) level thread extreme\_ex_skyeffects::fireFlaks(10, 0.25);

	for(i = 0; i < plane_count; i++)
	{
		plane_droppos = (game["playArea_CentreX"], game["playArea_CentreY"], game["mapArea_Max"][2] - 200);

		iterations = 0;
		while(iterations <= 50)
		{
			iterations++;
			wait( [[level.ex_fpstime]](0.05) );

			switch(randomInt(4))
			{
				// North-East quadrant of map area
				case 0:
					x = game["playArea_Max"][0] - randomInt( int(game["playArea_Width"] / 2) );
					y = game["playArea_Min"][1] + randomInt( int(game["playArea_Length"] / 2) );
					break;
				// South-East quadrant of map area
				case 1:
					x = game["playArea_Min"][0] + randomInt( int(game["playArea_Width"] / 2) );
					y = game["playArea_Min"][1] + randomInt( int(game["playArea_Length"] / 2) );
					break;
				// South-West quadrant of map area
				case 2:
					x = game["playArea_Min"][0] + randomInt( int(game["playArea_Width"] / 2) );
					y = game["playArea_Max"][1] - randomInt( int(game["playArea_Length"] / 2) );
					break;
				// North-West quadrant of map area
				default:
					x = game["playArea_Max"][0] - randomInt( int(game["playArea_Width"] / 2) );
					y = game["playArea_Max"][1] - randomInt( int(game["playArea_Length"] / 2) );
					break;
			}

			z = game["mapArea_Max"][2] - 200;
			if(level.ex_planes_altitude && (level.ex_planes_altitude <= z)) z = level.ex_planes_altitude;
			plane_droppos = (x,y,z);

			trace = bulletTrace(plane_droppos, plane_droppos + (0,0,-10000), false, undefined);
			if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") continue;
			targetpos = trace["position"];
			targetdist = distance(plane_droppos, targetpos);
			if(targetdist <= game["mapArea_Max"][2] + 1000) break;
			//else logprint("DEBUG: targetdist " + targetdist + " > " + game["mapArea_Max"][2] + " maparea_max\n");
		}

		// create the plane
		thread planeStart(plane_droppos, plane_angle, level.ex_planes_team);
		// do not wait, because in 2.8 the air traffic controller will handle the mutual distance between airplanes
	}

	// switch teams for next event
	level.ex_planes_team = !level.ex_planes_team;

	// wait for all planes to finish
	for(i = 0; i < plane_count; i++)
		level waittill("ambplane_finished");
}

planeStart(plane_droppos, plane_angle, plane_team_index)
{
	trace = bulletTrace(plane_droppos, plane_droppos + (0,0,-10000), false, undefined);
	targetpos = trace["position"];

	// plane team, model and type
	plane_type = 0; // fighter
	if(plane_team_index == 0)
	{
		plane_team = "axis";
		plane_models[0] = "xmodel/vehicle_stuka_flying";
		plane_models[1] = "xmodel/vehicle_condor";
		plane_model_index = randomInt(plane_models.size);
		plane_model = plane_models[plane_model_index];
		if(plane_model_index == 1) plane_type = 1; // axis bomber
	}
	else
	{
		plane_team = "allies";
		plane_models[0] = "xmodel/vehicle_spitfire_flying";
		plane_models[1] = "xmodel/vehicle_p51_mustang";
		plane_models[2] = "xmodel/vehicle_mebelle";
		plane_model_index = randomInt(plane_models.size);
		plane_model = plane_models[plane_model_index];
		if(plane_model_index == 2) plane_type = 1; // allies bomber
	}

	// switch team to neutral if without (lethal) bombs, so GML does not target it
	if(level.ex_planes != 3) plane_team = "neutral";

	// plane sound
	plane_sounds[0] = "stuka_flyby_1";
	plane_sounds[1] = "stuka_flyby_2";
	plane_sounds[0] = "spitfire_flyby_1";
	plane_sound = plane_sounds[randomInt(plane_sounds.size)];

	// calculate plane waypoints
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
	self waittill(planeSlot(0));

	// create and move airplane
	plane_index = planeCreate(0, level, plane_team, plane_model, plane_startpos, plane_angle, plane_sound, "ambplane_finished");
	if(plane_type == 0) plane_speed = 35; // fighters
		else plane_speed = 30; // bombers
	flighttime = calcTime(plane_startpos, plane_endpos, plane_speed);
	level.planes[plane_index].model moveto(plane_endpos, flighttime);

	bombs_dropped = false;
	for(i = 0; i < flighttime; i += 0.1)
	{
		if(!bombs_dropped && level.ex_planes >= 2 && plane_type == 1 && (distance(plane_droppos, level.planes[plane_index].model.origin) < dropdist) )
		{
			// DEBUG: black line from drop to target
			//level thread extreme\_ex_utils::dropLine(plane_droppos, targetpos, (0,0,0));
			level thread bombSetup(plane_index, targetpos, droprate);
			level.planes[plane_index].isdroppingpayload = true;
			bombs_dropped = true;
		}

		if(level.planes[plane_index].health <= 0 || (level.planes[plane_index].crash && !level.planes[plane_index].isdroppingpayload && (distance(game["playArea_Centre"], level.planes[plane_index].model.origin) < dropdist * 2)) )
		{
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
	impactpos = calcShellPos(plane_index, targetpos, 10000, true);

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

	// do the damage
	if(level.ex_planes == 2)
		bomb thread extreme\_ex_utils::scriptedfxradiusdamage(bomb, undefined, "MOD_EXPLOSIVE", "planebomb_mp", level.ex_airstrike_radius, 0, 0, "plane_bomb", undefined, true, true, true);

	if(level.ex_planes == 3)
	{
		bomb thread extreme\_ex_utils::scriptedfxradiusdamage(bomb, undefined, "MOD_EXPLOSIVE", "planebomb_mp", level.ex_airstrike_radius, 500, 400, "plane_bomb", undefined, true, true, true);

		thread extreme\_ex_specials_gml::perkRadiusDamage(bomb.origin, level.planes[plane_index].team, level.ex_airstrike_radius, 500);
		thread extreme\_ex_specials_flak::perkRadiusDamage(bomb.origin, level.planes[plane_index].team, level.ex_airstrike_radius, 500);
	}

	// play the explosion sound
	ms = randomInt(18) + 1;
	bomb playsound("mortar_explosion" + ms);

	wait( [[level.ex_fpstime]](1) );
	bomb delete();
}

calcShellPos(plane_index, targetpos, dist, oneshot)
{
	origin = level.planes[plane_index].model.origin;
	angle = randomFloat(360);
	radius = randomFloat(500);
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
