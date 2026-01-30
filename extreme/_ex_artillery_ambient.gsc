
init()
{
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, level.ex_artillery_delay_min, level.ex_artillery_delay_max, randomInt(30)+30);
}

onRandom(eventID)
{
	// if entities monitor in defcon 3 or lower, suspend
	if(level.ex_entities_defcon < 4)
	{
		[[level.ex_enableLevelEvent]]("onRandom", eventID);
		return;
	}

	// get artillery target position (surface level)
	artilleryTargetPos = getTargetPosition();

	// artillery firing sound, and optionally alert players
	shellNumber = randomInt(level.ex_artillery_shells_max - level.ex_artillery_shells_min) + level.ex_artillery_shells_min;
	for(i = 0; i < shellNumber; i++ )
	{
		[[level.ex_psop]]("artillery_fire");
		if(level.ex_artillery_alert && i == 0) thread extreme\_ex_utils::playBattleChat("order_cover_generic", "both");
		wait( [[level.ex_fpstime]](0.5) );
	}

	// get shell target positions and fire
	for(i = 0; i < shellNumber; i++)
	{
		thread fireShell(calcShellPos(artilleryTargetPos));
		wait( [[level.ex_fpstime]](randomFloatRange(1.5, 2.5)) );
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}

fireShell(shellTargetPos)
{
	shellStartPos = (shellTargetPos[0]-100, shellTargetPos[1]-100, game["mapArea_Max"][2]-200);

	// show visible artillery shell
	shell = spawn("script_model", shellStartPos);
	shell setModel("xmodel/prop_stuka_bomb");
	shell.angles = vectorToAngles(vectorNormalize(shellTargetPos - shellStartPos));

	// Play incoming sound
	ms = randomInt(14) + 1;
	shell playsound("mortar_incoming" + ms);

	// calculate time in air (s) based on distance (m) and preferred shell speed (m/s)!
	shellInAir = calcTime(shellStartPos, shellTargetPos, 50);

	// move visible artillery shell (correct target to slam shells into the ground, and for more realistic FX)
	shell moveTo(shellTargetPos + (0,0,-100), shellInAir);

	// wait for shell to hit
	wait( [[level.ex_fpstime]](shellInAir) );
	shell hide();

	playfx(level.ex_effect["artillery"], shell.origin);
	ms = randomInt(18) + 1;
	shell playsound("mortar_explosion" + ms);

	if(level.ex_artillery == 1)
		shell thread extreme\_ex_utils::scriptedFxRadiusDamage(shell, undefined, "MOD_EXPLOSIVE", "artillery_mp", level.ex_artillery_radius, 0, 0, "none", undefined, true, true, true);
	else if(level.ex_artillery == 2)
		shell thread extreme\_ex_utils::scriptedFxRadiusDamage(shell, undefined, "MOD_EXPLOSIVE", "artillery_mp", level.ex_artillery_radius, 500, 350, "none", undefined, true, true, true);

	wait( [[level.ex_fpstime]](1) );
	shell delete();
}

calcTime(p1, p2, speed)
{
	time = ((distance(p1, p2) * 0.0254) / speed);
	if(time <= 0) time = 0.1;
	return time;
}

getPlayAreaStartPosition(side)
{
	x = game["playArea_Min"][0];
	y = game["playArea_Min"][1];
	z = game["playArea_Max"][2];

	if(!isDefined(side)) side = randomInt(4);

	switch(side)
	{
		// North side of map area
		case 1: {
			x = game["playArea_Max"][0];
			y = randomInt(game["playArea_Length"]);
			z = game["playArea_Max"][2];
			break;
		}
		// East side of map area
		case 2: {
			x = randomInt(game["playArea_Width"]);
			y = game["playArea_Min"][1];
			z = game["playArea_Max"][2];
			break;
		}
		// South side of map area
		case 3: {
			x = randomInt(game["playArea_Width"]);
			y = game["playArea_Max"][1];
			z = game["playArea_Max"][2];
			break;
		}
		// West side of map area
		default: {
			x = game["playArea_Min"][0];
			y = randomInt(game["playArea_Length"]);
			z = game["playArea_Max"][2];
			break;
		}
	}

	return (x, y, z);
}

getMapAreaStartPosition(side)
{
	x = game["mapArea_Min"][0];
	y = game["mapArea_Min"][1];
	z = game["mapArea_Max"][2];

	if(!isDefined(side)) side = randomInt(4);

	switch(side)
	{
		// North side of map area
		case 1: {
			x = game["mapArea_Max"][0];
			y = randomInt(game["mapArea_Length"]);
			z = game["mapArea_Max"][2];
			break;
		}
		// East side of map area
		case 2: {
			x = randomInt(game["mapArea_Width"]);
			y = game["mapArea_Min"][1];
			z = game["mapArea_Max"][2];
			break;
		}
		// South side of map area
		case 3: {
			x = randomInt(game["mapArea_Width"]);
			y = game["mapArea_Max"][1];
			z = game["mapArea_Max"][2];
			break;
		}
		// West side of map area
		default: {
			x = game["mapArea_Min"][0];
			y = randomInt(game["mapArea_Length"]);
			z = game["mapArea_Max"][2];
			break;
		}
	}

	return (x, y, z);
}

getTargetPosition()
{
	x = game["playArea_Min"][0] + randomInt(game["playArea_Width"]);
	y = game["playArea_Min"][1] + randomInt(game["playArea_Length"]);
	z = game["playArea_Min"][2];

	return (x, y, z);
}

getMeAsTargetPosition()
{
	targetPos = getTargetPosition();
	players = level.players;
	for(i = 0; i < players.size; i++)
		if(players[i].name == "yourplayername") targetPos = players[i].origin;

	return targetPos;
}

calcShellPos(targetPos)
{
	shellPos = undefined;
	iterations = 0;

	while(!isDefined(shellPos) && iterations < 5)
	{
		shellPos = targetPos;
		angle = randomFloat(360);
		radius = randomFloat(750);
		randomOffset = (cos(angle) * radius, sin(angle) * radius, 0);
		shellPos += randomOffset;
		startOrigin = shellPos + (0, 0, 800);
		endOrigin = shellPos + (0, 0, -2048);

		trace = bulletTrace( startOrigin, endOrigin, true, undefined );
		if(trace["fraction"] < 1.0) shellPos = trace["position"];
			else shellPos = undefined;

		iterations++;
	}

	if(!isDefined(shellPos)) shellPos = targetPos;
	return shellPos;
}
