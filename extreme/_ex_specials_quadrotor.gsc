#include extreme\_ex_specials;
#include extreme\_ex_hudcontroller;

perkInit()
{
	level.quads = [];

	// perk related precaching
	[[level.ex_PrecacheModel]]("xmodel/vehicle_quadrotor");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_quadrotor_gun");

	level.ex_effect["quad_rotor"] = [[level.ex_PrecacheEffect]]("fx/rotor/rotor013_spin.efx");
	level.ex_effect["quad_shot"] = [[level.ex_PrecacheEffect]]("fx/muzzleflashes/mg42hv.efx");
}

perkInitPost()
{
	// perk related precaching after map load
}

perkCheck()
{
	// checks before being able to buy this perk
	if(perkCheckFrom(self)) return(false);
	return(true);
}

perkAssignDelayed(index, delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );

	if(!playerPerkIsLocked(index, true)) self thread perkAssign(index, 0);
}

perkAssign(index, delay)
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](delay) );

	if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_QUADROTOR_READY");

	self thread hudNotifySpecial(index);

	while(true)
	{
		wait( [[level.ex_fpstime]](.05) );
		if(!self isOnGround()) continue;
		if(self meleebuttonpressed())
		{
			count = 0;
			while(self meleeButtonPressed() && count < 10)
			{
				wait( [[level.ex_fpstime]](.05) );
				count++;
			}
			if(count >= 10)
			{
				if(getPerkPriority(index)) break;
				while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
		}
	}

	self thread playerStartUsingPerk(index, true);
	self thread hudNotifySpecialRemove(index);

	angles = (0, self.angles[1], 0);
	origin = self.origin;

	level thread perkCreate(self, origin, angles);
}

perkCreate(owner, origin, angles)
{
	index = perkAllocate();

	level.quads[index].origin = origin;
	level.quads[index].angles = angles;

	level.quads[index].quad = spawn("script_model", origin + (0,0,150));
	level.quads[index].quad hide();
	level.quads[index].quad setmodel("xmodel/vehicle_quadrotor");
	level.quads[index].quad.angles = (0, angles[1], 0);

	level.quads[index].gun = spawn("script_model", origin + (0,0,150));
	level.quads[index].gun hide();
	level.quads[index].gun setmodel("xmodel/vehicle_quadrotor_gun");
	level.quads[index].gun.angles = (0, angles[1], 0);
	level.quads[index].gun linkTo(level.quads[index].quad, "tag_gun", (0,0,0), (0,0,0));

	level.quads[index].sensor_camera = spawn("script_origin", origin + (0,0,150));
	level.quads[index].sensor_camera linkTo(level.quads[index].quad, "tag_camera", (0,0,0), (0,0,0));
	level.quads[index].sensor_top = spawn("script_origin", origin + (0,0,150));
	level.quads[index].sensor_top linkTo(level.quads[index].quad, "tag_sensor_top", (0,0,0), (0,0,0));
	level.quads[index].sensor_bottom = spawn("script_origin", origin + (0,0,150));
	level.quads[index].sensor_bottom linkTo(level.quads[index].quad, "tag_sensor_bottom", (0,0,0), (0,0,0));
	level.quads[index].sensor_front = spawn("script_origin", origin + (0,0,150));
	level.quads[index].sensor_front linkTo(level.quads[index].quad, "tag_sensor_front", (0,0,0), (0,0,0));
	level.quads[index].sensor_rear = spawn("script_origin", origin + (0,0,150));
	level.quads[index].sensor_rear linkTo(level.quads[index].quad, "tag_sensor_rear", (0,0,0), (0,0,0));
	level.quads[index].sensor_left = spawn("script_origin", origin + (0,0,150));
	level.quads[index].sensor_left linkTo(level.quads[index].quad, "tag_sensor_left", (0,0,0), (0,0,0));
	level.quads[index].sensor_right = spawn("script_origin", origin + (0,0,150));
	level.quads[index].sensor_right linkTo(level.quads[index].quad, "tag_sensor_right", (0,0,0), (0,0,0));

	// set owner last so other code knowns it's fully initialized
	level.quads[index].ownernum = owner getEntityNumber();
	level.quads[index].team = owner.pers["team"];
	level.quads[index].timer = level.ex_quad_timer * 20;
	level.quads[index].firing = false;
	level.quads[index].exiting = false;
	level.quads[index].targeting = false;
	level.quads[index].following = true;
	level.quads[index].calibrating = false;
	level.quads[index].calibrate = false;
	level.quads[index].owner = owner;

	perkStartPosition(index);
	level thread perkRotorFX(index);

	wait( [[level.ex_fpstime]](.1) );

	level.quads[index].quad show();
	level.quads[index].gun show();
	level.quads[index].quad playloopsound("quadrotor_loop");

	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.quads.size; i++)
	{
		if(level.quads[i].inuse == 0)
		{
			level.quads[i].inuse = 1;
			return(i);
		}
	}

	level.quads[i] = spawnstruct();
	level.quads[i].notification = "quad" + i;
	level.quads[i].inuse = 1;
	return(i);
}

perkCheckFrom(player)
{
	if(level.ex_quad && isDefined(level.quads))
	{
		for(i = 0; i < level.quads.size; i++)
			if(level.quads[i].inuse && isDefined(level.quads[i].owner) && level.quads[i].owner == player) return(true);
	}
	return(false);
}

perkRemoveAll()
{
	if(level.ex_quad && isDefined(level.quads))
	{
		for(i = 0; i < level.quads.size; i++)
			if(level.quads[i].inuse) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.quads.size; i++)
		if(level.quads[i].inuse && isDefined(level.quads[i].owner) && level.quads[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	level notify(level.quads[index].notification);
	thread levelStopUsingPerk(level.quads[index].ownernum, "quad");
	perkFree(index);
}

perkFree(index)
{
	level.quads[index].exiting = true;
	level.quads[index].quad waittill("quad_rotorstop");

	level.quads[index].sensor_top delete();
	level.quads[index].sensor_bottom delete();
	level.quads[index].sensor_front delete();
	level.quads[index].sensor_rear delete();
	level.quads[index].sensor_left delete();
	level.quads[index].sensor_right delete();
	level.quads[index].sensor_camera delete();
	level.quads[index].gun delete();
	level.quads[index].quad delete();
	level.quads[index].inuse = 0;
}

perkStartPosition(index)
{
	while(true)
	{
		wait( [[level.ex_fpstime]](.1) );
		collision = false;

		// sweep around the top sensor to check for clearance
		for(i = 0; i < 360; i += 10)
		{
			vFrwd = anglesToForward( (0, i, 0) );
			pFrwd = level.quads[index].sensor_top.origin + [[level.ex_vectorscale]](vFrwd, 60);
			trace = bulletTrace(level.quads[index].sensor_top.origin, pFrwd, true, level.quads[index].quad);
			if(trace["fraction"] != 1)
			{
				collision = true;
				break;
			}
		}

		// sweep around the bottom sensor to check for clearance
		if(!collision)
		{
			for(i = 0; i < 360; i += 10)
			{
				vFrwd = anglesToForward( (0, i, 0) );
				pFrwd = level.quads[index].sensor_bottom.origin + [[level.ex_vectorscale]](vFrwd, 60);
				trace = bulletTrace(level.quads[index].sensor_bottom.origin, pFrwd, true, level.quads[index].quad);
				if(trace["fraction"] != 1)
				{
					collision = true;
					break;
				}
			}
		}

		// on collision, go a bit up, and check again
		if(collision) level.quads[index].quad.origin = level.quads[index].quad.origin + (0,0,50);
			else break;
	}
}

perkRotorFX(index)
{
	while(!level.quads[index].exiting)
	{
		playfxontag(level.ex_effect["quad_rotor"], level.quads[index].quad, "tag_rotor_0");
		playfxontag(level.ex_effect["quad_rotor"], level.quads[index].quad, "tag_rotor_1");
		playfxontag(level.ex_effect["quad_rotor"], level.quads[index].quad, "tag_rotor_2");
		playfxontag(level.ex_effect["quad_rotor"], level.quads[index].quad, "tag_rotor_3");
		wait( [[level.ex_fpstime]](1) );
	}

	wait( [[level.ex_fpstime]](.1) );
	level.quads[index].quad notify("quad_rotorstop");
}

perkThink(index)
{
	level endon(level.quads[index].notification);

	level thread perkFollowOwner(index);
	level thread perkTargets(index);

	for(;;)
	{
		// remove perk if it reached end of life
		if(level.quads[index].timer <= 0) break;

		// remove perk if owner left
		if(!isPlayer(level.quads[index].owner)) break;

		// remove perk if owner died
		if(!isAlive(level.quads[index].owner) && !level.ex_quad_stayondeath) break;

		// remove perk if owner changed team
		if(level.ex_teamplay && level.quads[index].owner.pers["team"] != level.quads[index].team) break;

		level.quads[index].timer--;
		wait( [[level.ex_fpstime]](.05) );
	}

	thread perkRemove(index);
}

perkFollowOwner(index)
{
	level endon(level.quads[index].notification);

	thread perkFollowOwnerRotation(index);
	lock_forward = false;
	lock_down = 0;

	while(true)
	{
		wait( [[level.ex_fpstime]](.1) );

		// owner left: quit
		if(!isPlayer(level.quads[index].owner)) break;

		if(lock_down) lock_down--;

		// owner died: pause or quit following
		if(!isAlive(level.quads[index].owner))
		{
			if(level.ex_quad_stayondeath) continue;
				else break;
		}

		// if engaging target, pause following owner
		if(!level.quads[index].following) continue;

		// calibrate if not level (after targeting)
		if(level.quads[index].calibrate)
		{
			level.quads[index].calibrating = true;
			wait( .25 );
			level.quads[index].quad rotateto( (0,level.quads[index].quad.angles[1],0), 1);
			wait( 1 );
			level.quads[index].calibrate = false;
			level.quads[index].calibrating = false;
			continue;
		}

		// this is where we want to hover
		pDest = level.quads[index].owner.origin + (0,0,150);

		// use sensors to check for collisions
		collision = false;
		for(i = 0; i < 360; i += 10)
		{
			vFrwd = anglesToForward( (0, i, 0) );
			pFrwd = level.quads[index].sensor_bottom.origin + [[level.ex_vectorscale]](vFrwd, 60);
			trace = bulletTrace(level.quads[index].sensor_bottom.origin, pFrwd, true, level.quads[index].quad);
			if(trace["fraction"] != 1)
			{
				collision = true;
				break;
			}
		}

		// move up to avoid collision
		if(collision)
		{
			lock_forward = true;
			lock_down = 30; // don't descent towards player for x frames
			pDest = level.quads[index].sensor_top.origin + (0,0,30);
		}
		else if(lock_forward)
		{
			// check if allowed to descent
			if(!lock_down)
			{
				// check if safe to descent
				trace = bulletTrace(level.quads[index].sensor_front.origin, pDest, true, level.quads[index].quad);
				if(trace["fraction"] == 1)
				{
					trace = bulletTrace(level.quads[index].sensor_rear.origin, pDest, true, level.quads[index].quad);
					if(trace["fraction"] == 1)
					{
						trace = bulletTrace(level.quads[index].sensor_left.origin, pDest, true, level.quads[index].quad);
						if(trace["fraction"] == 1)
						{
							trace = bulletTrace(level.quads[index].sensor_right.origin, pDest, true, level.quads[index].quad);
							if(trace["fraction"] == 1) lock_forward = false;
						}
					}
				}
			}
			// not safe to descent. move towards player at same height
			if(lock_forward) pDest = (level.quads[index].owner.origin[0], level.quads[index].owner.origin[1], level.quads[index].quad.origin[2]);
		}

		// move to destination
		vDest = pDest - level.quads[index].quad.origin;
		fTime = (length(vDest) / 10) * 0.05;
		if(fTime) level.quads[index].quad moveto(pDest, fTime, 0, 0);
	}
}

perkFollowOwnerRotation(index)
{
	level endon(level.quads[index].notification);

	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );

		// owner left: quit
		if(!isPlayer(level.quads[index].owner)) break;

		// owner died: pause or quit following
		if(!isAlive(level.quads[index].owner))
		{
			if(level.ex_quad_stayondeath) continue;
				else break;
		}

		// if engaging target or calibrating, pause following owner
		if(!level.quads[index].following || level.quads[index].calibrating) continue;

		level.quads[index].quad rotateto( (0,level.quads[index].owner.angles[1],0), 0.5);
	}
}

perkTargets(index)
{
	level endon(level.quads[index].notification);

	target = level.quads[index].quad;

	while(true)
	{
		wait( [[level.ex_fpstime]](0.2) );

		// owner left: quit
		if(!isPlayer(level.quads[index].owner)) break;

		// pause until it's done calibrating
		if(level.quads[index].calibrating) continue;

		target_old = target;
		target = level.quads[index].quad;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player) && isPlayer(level.quads[index].owner))
			{
				// check for targets
				if( (!level.ex_teamplay && player != level.quads[index].owner) || (level.ex_teamplay && player.pers["team"] != level.quads[index].team) )
				{
					distsq = distancesquared( (level.quads[index].quad.origin[0], level.quads[index].quad.origin[1], 0), (player.origin[0], player.origin[1], 0) );
					if(distsq > level.ex_quad_fireradius * level.ex_quad_fireradius) continue;

					// check if old target is still alive and in range
					if(isPlayer(target_old) && isAlive(target_old) && perkInSight(index, target_old) && perkCanSee(index, target_old))
					{
						target = target_old;
						break;
					}
					// check other player
					else if(perkInSight(index, player) && perkCanSee(index, player))
					{
						if(!isPlayer(target)) target = player;
						if(closer(level.quads[index].quad.origin, player.origin, target.origin)) target = player;
					}
				}
			}
		}

		// if valid target, show some action
		if(isPlayer(target))
		{
			// stop following owner when engaging target
			level.quads[index].following = false;
			level.quads[index].calibrate = true;

			va = vectorToAngles(target.origin + (0, 0, 40) - level.quads[index].quad.origin);

			if(target == target_old && !level.quads[index].targeting) level.quads[index].quad rotateto(va, .2);
				else thread perkTargeting(index, va, .5);

			wait( [[level.ex_fpstime]](.05) );

			if(!level.quads[index].targeting)
			{
				thread perkFiring(index);

				// using weapon dummy2_mp so we don't have to precache another weapon. We will convert dummy2_mp to quad_mp for MOD_PROJECTILE later on
				if(isPlayer(level.quads[index].owner) && (!level.ex_teamplay || level.quads[index].owner.pers["team"] == level.quads[index].team))
					target thread [[level.callbackPlayerDamage]](level.quads[index].quad, level.quads[index].owner, level.ex_quad_damage, 1, "MOD_CRUSH", "dummy2_mp", target.origin + (0,0,40), anglesToForward(va), "none", 0);
				else
					target thread [[level.callbackPlayerDamage]](level.quads[index].quad, level.quads[index].quad, level.ex_quad_damage, 1, "MOD_CRUSH", "dummy2_mp", target.origin + (0,0,40), anglesToForward(va), "none", 0);
			}
		}
		else level.quads[index].following = true;
	}
}

perkInSight(index, player)
{
	dir = vectorNormalize(player.origin + (0, 0, 40) - level.quads[index].sensor_camera.origin);
	dot = vectorDot(anglesToForward(level.quads[index].quad.angles), dir);
	if(dot > 1) dot = 1;
	viewangle = acos(dot);
	if(viewangle > level.ex_quad_viewangle) return(false);
	return(true);
}

perkCanSee(index, player)
{
	cansee = (bullettrace(level.quads[index].sensor_camera.origin, player.origin + (0, 0, 10), false, undefined)["fraction"] == 1);
	if(!cansee) cansee = (bullettrace(level.quads[index].sensor_camera.origin, player.origin + (0, 0, 40), false, undefined)["fraction"] == 1);
	if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.quads[index].sensor_camera.origin, player.ex_eyemarker.origin, false, undefined)["fraction"] == 1);
	return(cansee);
}

perkTargeting(index, angles, duration)
{
	level endon(level.quads[index].notification);

	if(level.quads[index].targeting) return;
	level.quads[index].targeting = true;

	level.quads[index].quad rotateTo(angles, duration);
	wait( [[level.ex_fpstime]](duration) );

	level.quads[index].targeting = false;
}

perkFiring(index)
{
	level endon(level.quads[index].notification);

	if(level.quads[index].firing) return;
	level.quads[index].firing = true;

	level.quads[index].quad playsound("sentrygun_fire");
	firingtime = 1.3;
	for(i = 0; i < firingtime; i += .1)
	{
		playfxontag(level.ex_effect["quad_shot"], level.quads[index].gun, "tag_flash");
		wait( [[level.ex_fpstime]](.1) );
	}

	level.quads[index].firing = false;
}
