#include extreme\_ex_specials;

main()
{
	x = game["playArea_CentreX"];
	y = game["playArea_CentreY"];
	z = game["mapArea_Max"][2] - 200;
	if(level.ex_planes_altitude && (level.ex_planes_altitude <= z)) z = level.ex_planes_altitude;

	level.rotation_rig = spawn("script_model", (x,y,z));
	level.rotation_rig setmodel("xmodel/tag_origin");
	level.rotation_rig.angles = (0,0,0);

	if(isDefined(level.ex_gunship_rotationspeed)) maxspeed = level.ex_gunship_rotationspeed;
		else maxspeed = 40;

	if(isDefined(level.ex_gunship_radius_tweak)) radiustweak = level.ex_gunship_radius_tweak;
		else radiustweak = 150;

	level.rotation_rig.maxradius = getRadius(level.rotation_rig.origin, radiustweak);

	rotationspeed = int((maxspeed / 2000) * level.rotation_rig.maxradius);
	if(rotationspeed < maxspeed) rotationspeed = maxspeed;
	level.rotation_rig.rotationspeed = rotationspeed;

	level thread rigRotate();
}

rigRotate()
{
	while(!level.ex_gameover)
	{
		level.rotation_rig rotateyaw(360, level.rotation_rig.rotationspeed);
		wait( [[level.ex_fpstime]](level.rotation_rig.rotationspeed) );
	}
}

getRadius(center, correction)
{
	radius = (((game["playArea_Width"] + game["playArea_Length"]) / 2) / 2) + 500;

	deviations = 0;
	deviations_allowed = 3;

	for(i = 0; i < 360; i += 10)
	{
		pos = forwardLimit(center, i, radius, true);

		/* Plot radius detection
		if(!isDefined(level.ex_xxx)) level.ex_xxx = [];
		index = level.ex_xxx.size;
		level.ex_xxx[index] = spawn("script_model", pos);
		level.ex_xxx[index] setmodel("xmodel/health_large");
		*/

		radius_temp = distance(center, pos);
		if(radius_temp < radius)
		{
			if( (radius_temp < (radius / 2)) && (deviations < deviations_allowed) ) deviations++;
				else radius = radius_temp;
		}
	}

	radius = radius - correction;

	/* Plot final orbit
	for(i = 0; i < 360; i += 10)
	{
		pos = forwardLimit(center, i, radius, true);

		if(!isDefined(level.ex_xxx)) level.ex_xxx = [];
		index = level.ex_xxx.size;
		level.ex_xxx[index] = spawn("script_model", pos);
		level.ex_xxx[index] setmodel("xmodel/health_medium");
	}
	*/

	return radius;
}

forwardLimit(pos, angle, dist, oneshot)
{
	forwardvector = anglestoforward( (0, angle, 0) );
	while(true)
	{
		forwardpos = pos + [[level.ex_vectorscale]](forwardvector, dist);
		trace = bulletTrace(pos, forwardpos, true, self);
		if(trace["fraction"] != 1)
		{
			endpos = trace["position"];
			return endpos;
		}
		else
		{
			pos = forwardpos;
			if(oneshot) return forwardpos;
		}
	}
}

