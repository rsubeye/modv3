
init()
{
	[[level.ex_PrecacheModel]]("xmodel/weapon_flak_missile");
	level.ex_effect["slamraam"] = [[level.ex_PrecacheEffect]]("fx/misc/slamraam.efx");

	[[level.ex_registerLevelEvent]]("onFrame", ::onFrame, true);
}

onFrame(eventID)
{
	rockets = getentarray("rocket", "classname");
	for(i = 0; i < rockets.size; i ++)
	{
		rocket = rockets[i];
		if(!isDefined(rocket.monitored))
		{
			rocket.monitored = true;
			rocket thread tagProjectile();
		}
	}

	[[level.ex_enableLevelEvent]]("onFrame", eventID);
}

tagProjectile()
{
	closest_player = undefined;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionstate == "playing")
		{
			if(!isPlayer(closest_player)) closest_player = player;
			if(closer(self.origin, player.origin, closest_player.origin)) closest_player = player;
		}
	}

	if(isPlayer(closest_player))
	{
		if(level.ex_gunship && isPlayer(level.gunship.owner) && closest_player == level.gunship.owner)
		{
			level thread extreme\_ex_gunship::gunshipMonitorProjectile(self, level.gunship);
			//logprint("DEBUG: projectile was fired from normal gunship by " + closest_player.name + "\n");
		}
		else if(level.ex_gunship_special && isPlayer(level.gunship_special.owner) && closest_player == level.gunship_special.owner)
		{
			level thread extreme\_ex_gunship::gunshipMonitorProjectile(self, level.gunship_special);
			//logprint("DEBUG: projectile was fired from specialty gunship by " + closest_player.name + "\n");
		}
		else
		{
			weapon = closest_player getcurrentweapon();
			if(extreme\_ex_weapons::isWeaponType(weapon, "rl"))
			{
				if(closest_player usebuttonpressed())
				{
					if(isDefined(level.helicopter) && level.ex_heli_candamage && (!level.ex_teamplay || closest_player.pers["team"] != level.helicopter.team))
					{
						level thread replaceProjectile(self, level.helicopter);
						if(level.ex_heli_damagehud && isPlayer(closest_player)) closest_player thread extreme\_ex_specials_helicopter::hudDamageHeli(10);
						//logprint("DEBUG: projectile was fired from rocket launcher to chopper by " + closest_player.name + " (heat seaker)\n");
					}
					else if(level.ex_gunship && isPlayer(level.gunship.owner) && (!level.ex_teamplay || closest_player.pers["team"] != level.gunship.team))
					{
						level thread replaceProjectile(self, level.gunship);
						//logprint("DEBUG: projectile was fired from rocket launcher to gunship by " + closest_player.name + " (heat seaker)\n");
					}
					else if(level.ex_gunship_special && isPlayer(level.gunship_special.owner) && (!level.ex_teamplay || closest_player.pers["team"] != level.gunship_special.team))
					{
						level thread replaceProjectile(self, level.gunship_special);
						//logprint("DEBUG: projectile was fired from rocket launcher to specialty gunship by " + closest_player.name + " (heat seaker)\n");
					}
					else if(level.ex_gunship || level.ex_specials || level.ex_longrange)
					{
						level thread assistedProjectile(self);
						//logprint("DEBUG: projectile was fired from rocket launcher by " + closest_player.name + " (assisted)\n");
					}
				}
				else if(level.ex_gunship || level.ex_specials || level.ex_longrange)
				{
					level thread assistedProjectile(self);
					//logprint("DEBUG: projectile was fired from rocket launcher by " + closest_player.name + " (assisted)\n");
				}
				//else logprint("DEBUG: projectile was fired from rocket launcher by " + closest_player.name + " (normal)\n");
			}
			else if(extreme\_ex_weapons::isWeaponType(weapon, "knife"))
			{
				if(isDefined(self))
				{
					modern = false;
					if(level.ex_specials_knife)
					{
						if(level.ex_specials_knife_modern) modern = true;
					}
					else if(level.ex_modern_weapons) modern = true;
					closest_player thread extreme\_ex_projectiles_knife::main(weapon, self.origin, modern);
					self delete();
				}
				//logprint("DEBUG: projectile was fired from knife by " + closest_player.name + "\n");
			}
			else if(extreme\_ex_weapons::isWeaponType(weapon, "ft"))
			{
				if(isDefined(self)) self delete();
				//logprint("DEBUG: projectile was fired from flamethrower by " + closest_player.name + "\n");
			}
			//else logprint("DEBUG: projectile was fired from LR rifle by " + closest_player.name + "\n");
		}
	}
}

/*******************************************************************************
REPLACE STANDARD PROJECTILE FOR TRACKABLE ONE
*******************************************************************************/
replaceProjectile(entity, target)
{
	origin = entity.origin;
	angles = entity.angles;
	entity delete();
	rocket = spawn("script_model", origin);
	rocket setmodel("xmodel/weapon_flak_missile");
	rocket.angles = angles;
	rocket thread trackProjectile(target, 50);
}

trackProjectile(target, speed)
{
	self.finishedrotating = true;

	self.dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
	time = int(distance(self.origin, self.dest) * 0.0254) / speed;
	if(time <= 0)
	{
		self delete();
		return;
	}
	self moveto(self.dest, time, 0, 0);
	wait( [[level.ex_fpstime]](.25) ); // no turn for .25 second to let it detach properly

	olddest = (0,0,0);
	totaltime = 0;
	lifespan = 30 * level.ex_fps;
	trace = bulletTrace(self.origin, self.dest, true, self);
	ftime = int(distance(self.origin, trace["position"]) * 0.0254) / speed;
	for(t = 0; t < ftime * level.ex_fps; t++)
	{
		wait( [[level.ex_fpstime]](.05) );

		newtrace = bulletTrace(self.origin, self.dest, true, self);
		if(distance(newtrace["position"], trace["position"]) > 1)
		{
			trace = newtrace;
			ftime = int(distance(self.origin, trace["position"]) * 0.0254) / speed;
			t = 0;
		}

		// handle fx
		totaltime++;
		if(totaltime % 4 == 0) playfxontag(level.ex_effect["slamraam"], self, "tag_origin");

		// handle flying time
		if(lifespan && totaltime > lifespan) break;

		// check if target still exists
		if(!isDefined(target))
		{
			self.dest = self.origin + [[level.ex_vectorscale]](anglestoforward(self.angles), 999999);
			time = int(distance(self.origin, self.dest) * 0.0254) / speed;
			if(time <= 0) break;
			self moveto(self.dest, time, 0, 0);
			continue;
		}

		// try to follow target
		newdest = target.origin;
		if(!isDefined(newdest) || newdest == olddest) continue;
		olddest = self.dest;
		self.dest = newdest;

		if(self.finishedrotating)
		{
			dir = vectorNormalize(self.dest - self.origin);
			forward = anglesToForward(self.angles);
			dot = vectordot(dir, forward);
			if(dot < 0.85)
			{
				rotate = vectorToAngles(self.dest - self.origin);
				dot = vectorDot(anglesToForward(self.angles), anglesToForward(rotate));
				if(dot < -1) dot = -1;
					else if(dot > 1) dot = 1;
				time = abs(acos(dot) * .0075);
				if(time <= 0) time = 0.1;

				self rotateto(rotate, time, 0, 0);
				self.finishedrotating = false;
				self thread waitForRotate(time);
			}
		}

		if(self.finishedrotating) angle = vectorToAngles(self.dest - self.origin);
		else
		{
			self.dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
			angle = undefined;
		}
		if(isDefined(angle)) self.angles = angle;

		time = int(distance(self.origin, self.dest) * 0.0254) / speed;
		if(time <= 0) break;
		self moveto(self.dest, time, 0, 0);
	}

	// handle explosion
	self hide();
	playfx(level.ex_effect["artillery"], self.origin);
	ms = randomInt(18) + 1;
	self playsound("mortar_explosion" + ms);
	self delete();

	if(trace["fraction"] != 1 && isDefined(trace["entity"]))
	{
		if(isDefined(target) && trace["entity"] == target) target.health -= 500;
	}
}

waitForRotate(time)
{
	self notify("stop_rotate_thread");
	self endon("stop_rotate_thread");

	wait( [[level.ex_fpstime]](time) );
	if(isDefined(self)) self.finishedrotating = true;
}

/*******************************************************************************
MONITOR PROJECTILE FOR ROCKET LAUNCHER EFFECTS
*******************************************************************************/
assistedProjectile(entity)
{
	lastorigin = entity.origin;
	while(isDefined(entity))
	{
		lastorigin = entity.origin;
		wait( [[level.ex_fpstime]](0.05) );
	}

	playfx(level.ex_effect["artillery"], lastorigin);
	level thread extreme\_ex_utils::playSoundLoc("grenade_explode_default", lastorigin);
}

/*******************************************************************************
MISC
*******************************************************************************/
abs(x)
{
	if(x < 0) x *= -1;
	return x;
}
