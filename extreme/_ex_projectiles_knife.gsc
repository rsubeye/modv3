
main(weapon, origin, modern)
{
	direction = anglesToForward(self getPlayerAngles());
	origin = origin + [[level.ex_vectorscale]](direction, 80);
	vVelocity = [[level.ex_vectorscale]](direction, 60);

	knife = spawn("script_model", origin);
	if(modern) knife setModel("xmodel/viewmodel_modern_knife");
		else knife setModel("xmodel/viewmodel_knife");
	knife.angles = self.angles;
	knife_bouncing = false;

	iLoop = 0;
	if(level.ex_wepo_knife_gravity) iLoopMax = 200; // max 10 seconds
		else iLoopMax = 40; // max 2 seconds

	for(;;)
	{
		wait(0.05);

		iLoop++;
		if(!isPlayer(self) || iLoop == iLoopMax) break;

		if(level.ex_wepo_knife_gravity) vVelocity += (0,0,-2);

		neworigin = knife.origin + vVelocity;
		if(knife_bouncing) newangles = knife.angles + (randomInt(20), randomInt(20), randomInt(20));
			else newangles = vectorToAngles(neworigin - knife.origin) + (90,0,0);

		trace = bulletTrace(knife.origin, neworigin, true, knife);
		if(trace["fraction"] != 1)
		{
			ignore_entity = false;

			// hit player
			if(isDefined(trace["entity"]) && isPlayer(trace["entity"]))
			{
				// you can't hit yourself unless the knife has traveled far enough to avoid collision
				if(trace["entity"] != self || iLoop > 5)
				{
					trace["entity"] thread [[level.callbackPlayerDamage]](self, self, 100, 1, "MOD_PISTOL_BULLET", weapon, undefined, (0,0,1), "none", 0);
					break;
				}
				else ignore_entity = true;
			}

			if(!ignore_entity)
			{
				knife_action = knifeAction(trace["surfacetype"]);

				// stick
				if(knife_action == 1)
				{
					knife.origin = trace["position"] + [[level.ex_vectorscale]](vectorNormalize(neworigin - knife.origin), -5);
					knife.angles = vectorToAngles(neworigin - knife.origin) + (90,0,0);
					//extreme\_ex_utils::debugAngles(trace["position"], vectorNormalize(neworigin - knife.origin), undefined);
					wait( [[level.ex_fpstime]](1) );
					break;
				}
				// bounce
				else if(knife_action == 2)
				{
					knife.origin = trace["position"];
					vOldDirection = vectorNormalize(neworigin - knife.origin);
					vNewDirection = vOldDirection - [[level.ex_vectorscale]](trace["normal"], vectorDot(vOldDirection, trace["normal"]) * 2);
					vVelocity = [[level.ex_vectorscale]](vNewDirection, length(vVelocity) * level.ex_wepo_knife_bouncefactor);
					if(length(vVelocity) < 5)
					{
						knife.angles = (90, knife.angles[1], knife.angles[2]);
						wait( [[level.ex_fpstime]](1) );
						break;
					}
					//extreme\_ex_utils::debugAngles(trace["position"], vOldDirection, vNewDirection);
					knife_bouncing = true;
					continue;
				}
				// delete
				else break;
			}
		}

		knife rotateto(newangles, .05, 0, 0);
		knife moveto(neworigin, .05, 0, 0);
	}

	knife delete();
}

knifeAction(surface)
{
	switch(surface)
	{
		// stick
		case "bark":
		case "dirt":
		case "grass":
		case "mud":
		case "sand":
		case "snow":
		case "wood":
			return(1);

		// bounce
		case "asphalt":
		case "brick":
		case "concrete":
		case "glass":
		case "gravel":
		case "ice":
		case "metal":
		case "plaster":
		case "rock":
			if(level.ex_wepo_knife_gravity) return(2);
				else return(0);

		// delete
		//case "carpet":
		//case "cloth":
		//case "default":
		//case "flesh":
		//case "foliage":
		//case "paper":
		//case "water":
		default:
			return(0);
	}
}
