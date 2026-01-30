
init()
{
	// array for tracking slots and plane entities
	level.planes = [];
	level.slots = [];

	// no ATC needed if all related features are turned off
	if(!level.ex_planes &&
	  (!level.ex_ranksystem || !level.ex_rank_wmdtype) &&
	  (!level.ex_amc_perteam || !level.ex_amc_chutein)) return;

	// var for tracking crashes
	if(!isDefined(game["ex_planescrashed"])) game["ex_planescrashed"] = 0;

	// ambient planes
	if(level.ex_planes)
	{
		if(randomInt(100) < 50) level.ex_planes_team = 1;
			else level.ex_planes_team = 0;

		[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_planes_delay_min, level.ex_planes_delay_max, randomInt(30)+30);
	}

	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond, true);
}

onRandom(eventID)
{
	// suspend if entities monitor in defcon 3 or lower, or other planes are present
	if(level.ex_entities_defcon < 4 || planesInSky())
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	extreme\_ex_airplanes::start();

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}

onSecond(eventID)
{
	if(planesInSky() < level.ex_atc_maxplanes)
	{
		longest_time = -1;
		notify_slot = -1;
		notify_type = 0;

		for(i = 0; i < level.slots.size; i++)
		{
			if(level.slots[i].inuse == 1)
			{
				time_past = getTime() - level.slots[i].time;
				// prioritize based on type number
				if(level.slots[i].type < notify_type) continue;
				if(time_past > longest_time)
				{
					notify_slot = i;
					notify_type = level.slots[i].type;
					longest_time = time_past;
				}
			}
		}

		if(notify_slot != -1)
		{
			wait( [[level.ex_fpstime]](randomInt(2) + 1) );

/*
			if(level.players.size)
			{
				if(isPlayer(level.slots[notify_slot].pilot)) level.players[0] sayall("clearance for slot " + notify_slot + ", airplane type " + notify_type);
					else level.players[0] sayall("clearance for slot " + notify_slot + ", airplane type " + notify_type);
			}
*/

			if(isDefined(level.slots[notify_slot].pilot)) level.slots[notify_slot].pilot notify("clearance" + notify_slot);

			level.slots[notify_slot].inuse = 0;
			level.slots[notify_slot].pilot = undefined;
		}
	}

	[[level.ex_enableLevelEvent]]("onSecond", eventID);
}

planeSlot(type)
{
	index = -1;
	for(i = 0; i < level.slots.size; i++)
	{
		if(level.slots[i].inuse == 0)
		{
			index = i;
			break;
		}
	}

	if(index == -1)
	{
		index = level.slots.size;
		level.slots[index] = spawnstruct();
	}

	level.slots[index].inuse = 1;
	// type for clearance priority: 0 = ambient airstrike, 1 = ammocrate drop, 2 = WMD airstrike
	level.slots[index].type = type;
	level.slots[index].time = getTime();
	level.slots[index].pilot = self;

/*
	if(level.players.size)
	{
		if(isPlayer(level.slots[index].pilot)) level.players[0] sayall("slot " + index + " reserved for airplane type " + type);
			else level.players[0] sayall("slot " + index + " reserved for airplane type " + type);
	}
*/

	return("clearance" + index);
}

planeCreate(type, owner, team, model, origin, angle, sound, notification)
{
	index = planeAllocate();

	// type identifier for targeting: 0 = ambient airstrike, 1 = ammocrate drop, 2 = WMD airstrike
	level.planes[index].notification = notification;
	level.planes[index].type = type;
	level.planes[index].pilot = self; // not the owner, but the entity allocating
	level.planes[index].owner = owner;
	level.planes[index].team = team;
	level.planes[index].model = spawn("script_model", origin);
	level.planes[index].model setModel(model);
	level.planes[index].model.angles = (0, angle, 0);
	level.planes[index].model playloopsound(sound);
	level.planes[index].isdroppingpayload = false;

	if(type == 2) level.planes[index].health = level.ex_wmdplanes_maxhealth;
		else level.planes[index].health = level.ex_planes_maxhealth;

	level.planes[index].crash = false;
	if(randomInt(100) < level.ex_atc_crashchance && game["ex_planescrashed"] < level.ex_atc_maxcrashes)
		level.planes[index].crash = true;

	return(index);
}

planeAllocate()
{
	for(i = 0; i < level.planes.size; i++)
	{
		if(level.planes[i].inuse == 0)
		{
			level.planes[i].inuse = 1;
			return(i);
		}
	}

	level.planes[i] = spawnstruct();
	level.planes[i].inuse = 1;
	return(i);
}

planeFree(index)
{
	if(isDefined(level.planes[index].pilot) && isDefined(level.planes[index].notification))
		level.planes[index].pilot notify(level.planes[index].notification);

	level.planes[index].model stoploopsound();
	level.planes[index].model delete();
	level.planes[index].inuse = 0;
}

planesInSky()
{
	insky = 0;
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse == 1) insky++;
	return(insky);
}

planesInSkyNeutral()
{
	insky = 0;
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse == 1 && level.planes[i].team == "neutral") insky++;
	return(insky);
}

planesInSkyAllies()
{
	insky = 0;
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse == 1 && level.planes[i].team == "allies") insky++;
	return(insky);
}

planesInSkyAxis()
{
	insky = 0;
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse == 1 && level.planes[i].team == "axis") insky++;
	return(insky);
}

planeCheckEntity(entity)
{
	for(i = 0; i < level.planes.size; i++)
		if(level.planes[i].inuse && level.planes[i].model == entity) return(i);
	return(-1);
}

planeCrashAll()
{
	for(i = 0; i < level.planes.size; i++)
	{
		if(level.planes[i].inuse)
		{
			level.planes[i].health = 0;
			wait( [[level.ex_fpstime]](1 + randomFloat(0.5)) );
		}
	}
}

planeCrash(index, plane_speed)
{
	game["ex_planescrashed"]++;

	plane = level.planes[index].model;
	plane.angles = anglesNormalize(plane.angles);
	plane thread planeCrashFX();

	origin = plane.origin;
	angles = plane.angles;

	// take over plane movement to predefined crash point
	f0 = posForward(origin, angles, 1000);
	movetime = calcTime(origin, f0, plane_speed);
	plane moveto(f0, movetime);

	// calculate nodes in parallel
	if(randomInt(100) < 75)
	{
		f1 = posForward(f0, angles, 3000 + randomInt(2000));

		if(randomInt(2)) f2 = posLeft(f1, angles, 1000 + randomInt(2000));
			else f2 = posRight(f1, angles, 1000 + randomInt(2000));

		dest = posDown(f2, angles, 0);
		if(dest[2] < game["mapArea_Min"][2]) dest = (dest[0], dest[1], game["mapArea_Min"][2] - 100);
		plane thread quadraticBezierCurve(f0, f1, dest, plane_speed);
	}
	else
	{
		f1 = posForward(f0, angles, 3000 + randomInt(2000));
		b1 = posBack(f0, angles, 2000 + randomInt(3000));

		if(randomInt(2))
		{
			f2 = posLeft(f1, angles, 4000 + randomInt(3000));
			if(randomInt(100) < 95) b2 = posLeft(b1, angles, randomInt(4000));
				else b2 = posRight(b1, angles, 500 + randomInt(500));
		}
		else
		{
			f2 = posRight(f1, angles, 4000 + randomInt(3000));
			if(randomInt(100) < 95) b2 = posRight(b1, angles, randomInt(4000));
				else b2 = posLeft(b1, angles, 500 + randomInt(500));
		}

		dest = posDown(b2, angles, 0);
		if(dest[2] < game["mapArea_Min"][2]) dest = (dest[0], dest[1], game["mapArea_Min"][2] - 1000);
		plane thread cubicBezierCurve(f0, f1, f2, dest, plane_speed);
	}

	// wait to arrive at crash point
	wait( [[level.ex_fpstime]](movetime * .999) );

	// commence crashing
	plane notify("crash_go");
	plane stoploopsound();
	plane playloopsound("plane_dive");

	// wait for crash to finish
	plane waittill("crash_done");
	plane notify("crashfx_done");

	plane stoploopsound();
	playfx(level.ex_effect["planecrash_explosion"], plane.origin);
	plane playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );
	playfx(level.ex_effect["planecrash_ball"], plane.origin);
	wait( [[level.ex_fpstime]](5) );

	planeFree(index);
}

planeCrashFX()
{
	self endon("crashfx_done");

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );

	while(1)
	{
		playfx(level.ex_effect["planecrash_smoke"], self.origin);
		if(randomInt(100) < 5)
		{
			playfx(level.ex_effect["plane_explosion"], self.origin);
			self playsound("plane_explosion_" + (1 + randomInt(3)));
		}
		wait( [[level.ex_fpstime]](.1) );
	}
}

planeStartEnd(targetpos, angle)
{
	forwardvector = anglestoforward( (0, angle, 0) );
	backpos = targetpos + ([[level.ex_vectorscale]](forwardvector, -30000));
	frontpos = targetpos + ([[level.ex_vectorscale]](forwardvector, 30000));
	fronthit = 0;

	trace = bulletTrace(targetpos, backpos, false, undefined);
	if(trace["fraction"] != 1) start = trace["position"];
		else start = backpos;

	trace = bulletTrace(targetpos, frontpos, false, undefined);
	if(trace["fraction"] != 1)
	{
		endpoint = trace["position"];
		fronthit = 1;
	}
	else endpoint = frontpos;

	startpos = start + ([[level.ex_vectorscale]](forwardvector, -3000));
	endpoint = endpoint + ([[level.ex_vectorscale]](forwardvector, 3000));
	stenpos[0] = startpos;
	stenpos[1] = endpoint;
	stenpos[2] = fronthit;
	return stenpos;
}

/*******************************************************************************
BEZIER
*******************************************************************************/
quadraticBezierCurve(pos0, pos1, pos2, speed)
{
	angles_prev = self.angles;
	angles_roll = self.angles[2];
	adjust_roll = 0;

	node_array = [];
	nodes = 25;
	node_prev = pos0;

	for(i = 1; i <= nodes; i++)
	{
		index = node_array.size;
		node_array[index] = spawnstruct();

		node = pointQuadraticBezierCurve(pos0, pos1, pos2, i / nodes);
		node_array[index].node = node;
		node_array[index].time = calcTime(node_prev, node_array[index].node, speed);
		if(speed < 45) speed = speed + 1;

		va = vectorToAngles(node - node_prev);
		fv = anglesToForward(va);
		rdot = vectorDot(anglesToRight(angles_prev), fv);
		if(rdot < 0 && adjust_roll > -30) adjust_roll--; // right
			else if(rdot > 0 && adjust_roll < 30) adjust_roll++; // left
		node_array[index].angles = (va[0], va[1], angles_roll + adjust_roll);

		node_prev = node_array[index].node;
		angles_prev = node_array[index].angles;
		if(i % 10 == 0) wait( [[level.ex_fpstime]](.05) );
	}

	self waittill("crash_go");

	for(i = 0; i < node_array.size; i++)
	{
		movetime = node_array[i].time;
		self rotateto(node_array[i].angles, movetime);
		self moveto(node_array[i].node, movetime);
		wait( [[level.ex_fpstime]](movetime * .999) );
	}

	self notify("crash_done");
}

pointQuadraticBezierCurve(pos0, pos1, pos2, t)
{
	// B(t) = (1-t)^2*P0 + 2(1-t)*t*P1 + t^2*P2
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 2)) +
	       [[level.ex_vectorscale]](pos1, t * (2 * (1 - t))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2));
	vec = (tvec[0], tvec[1], tvec[2]);
	return vec;
}

cubicBezierCurve(pos0, pos1, pos2, pos3, speed)
{
	angles_prev = self.angles;
	angles_roll = self.angles[2];
	adjust_roll = 0;

	node_array = [];
	nodes = 50;
	node_prev = pos0;

	for(i = 1; i <= nodes; i++)
	{
		index = node_array.size;
		node_array[index] = spawnstruct();

		node = pointCubicBezierCurve(pos0, pos1, pos2, pos3, i / nodes);
		node_array[index].node = node;
		node_array[index].time = calcTime(node_prev, node_array[index].node, speed);
		if(speed < 45) speed = speed + 1;

		va = vectorToAngles(node - node_prev);
		fv = anglesToForward(va);
		rdot = vectorDot(anglesToRight(angles_prev), fv);
		if(rdot < 0 && adjust_roll > -30) adjust_roll--; // right
			else if(rdot > 0 && adjust_roll < 30) adjust_roll++; // left
		node_array[index].angles = (va[0], va[1], angles_roll + adjust_roll);

		node_prev = node_array[index].node;
		angles_prev = node_array[index].angles;
		if(i % 10 == 0) wait( [[level.ex_fpstime]](.05) );
	}

	self waittill("crash_go");

	for(i = 0; i < node_array.size; i++)
	{
		movetime = node_array[i].time;
		self rotateto(node_array[i].angles, movetime);
		self moveto(node_array[i].node, movetime);
		wait( [[level.ex_fpstime]](movetime * .999) );
	}

	self notify("crash_done");
}

pointCubicBezierCurve(pos0, pos1, pos2, pos3, t)
{
	// B(t) = (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)*t^2*P2 + t^3*P3
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 3)) +
	       [[level.ex_vectorscale]](pos1, t * (3 * pow(1 - t, 2))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2) * (3 * (1 - t))) +
	       [[level.ex_vectorscale]](pos3, pow(t, 3));
	vec = (tvec[0], tvec[1], tvec[2]);
	return vec;
}

/*******************************************************************************
LOCATORS
*******************************************************************************/
posForward(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posBack(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	origin = origin + [[level.ex_vectorscale]](forwardvector, 0 - length);
	return(origin);
}

posUp(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoup( (0, angles[1], 0) );
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posDown(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoup( (180, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, false, undefined);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posLeft(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoforward( (0, angles[1] + 90, 0) );
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posRight(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoforward( (0, angles[1] - 90, 0) );
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

circleHor(origin, angles, length)
{
	for(i = 0; i < 360; i += 20)
		origin = origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), length);
}

circleVert(origin, angles, length)
{
	for(i = 0; i < 360; i += 20)
		origin = origin + [[level.ex_vectorscale]](anglestoup((i, angles[1], 0)), length);
}

/*******************************************************************************
MISC
*******************************************************************************/
calcTime(p1, p2, speed)
{
	time = ((distance(p1, p2) * 0.0254) / speed);
	if(time <= 0) time = 0.1;
	return time;
}

angleNormalize(angle)
{
	if(angle) while(angle >= 360) angle -= 360;
		else while(angle <= -360) angle += 360;
	return(angle);
}

anglesNormalize(angles)
{
	pitch = angleNormalize(angles[0]);
	yaw = angleNormalize(angles[1]);
	roll = angleNormalize(angles[2]);
	return( (pitch, yaw, roll) );
}

pow(numb, power)
{
	result = 1.0;
	for(i = 0; i < power; i++)
		result = result * numb;
	return result;
}

sqrt(X)
{
	if(X < 0) return -1;
	e = 0.000000000001;
	while(e > X) e /= 10;
	b = (1.0 + X) / 2;
	c = (b - X / b) / 2;
	iterations = 0;
	while(c > e && iterations < 1000)
	{
		f = b;
		b -= c;
		if(f == b) return b;
		c = (b - X / b) / 2;
		iterations++;
	}
	return b;
}
