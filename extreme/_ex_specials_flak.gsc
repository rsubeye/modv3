#include extreme\_ex_specials;
#include extreme\_ex_hudcontroller;

perkInit()
{
	// perk related precaching

	// create perk array
	level.flaks = [];

	// precache models
	[[level.ex_PrecacheModel]]("xmodel/weapon_flak_missile");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_flakvierling_base");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_flakvierling_body");

	if(level.ex_flak_complex)
	{
		[[level.ex_PrecacheModel]]("xmodel/vehicle_flakvierling_guns_assy");
		[[level.ex_PrecacheModel]]("xmodel/vehicle_flakvierling_gun_barrel");
	}
	else [[level.ex_PrecacheModel]]("xmodel/vehicle_flakvierling_guns");

	// precache other shaders
	game["actionpanel_owner"] = "spc_actionpanel_owner";
	[[level.ex_PrecacheShader]](game["actionpanel_owner"]);
	game["actionpanel_enemy"] = "spc_actionpanel_enemy";
	[[level.ex_PrecacheShader]](game["actionpanel_enemy"]);
	game["actionpanel_denied"] = "spc_actionpanel_denied";
	[[level.ex_PrecacheShader]](game["actionpanel_denied"]);

	// precache general purpose waypoints
	if(level.ex_flak_waypoints)
	{
		game["waypoint_abandoned"] = "spc_waypoint_abandoned";
		[[level.ex_PrecacheShader]](game["waypoint_abandoned"]);

		if(level.ex_flak_waypoints != 3)
		{
			game["waypoint_activated"] = "spc_waypoint_activated";
			[[level.ex_PrecacheShader]](game["waypoint_activated"]);
			game["waypoint_deactivated"] = "spc_waypoint_deactivated";
			[[level.ex_PrecacheShader]](game["waypoint_deactivated"]);
		}
	}

	// precache strings
	if(level.ex_flak == 2 || level.ex_flak == 3)
	{
		game["flak_reticle"] = &":    :";
		[[level.ex_PrecacheString]](game["flak_reticle"]);
	}

	// precache effects
	level.ex_effect["flak_shot"] = [[level.ex_PrecacheEffect]]("fx/flakvierling/20mm_flash.efx");
	level.ex_effect["flak_sparks"] = [[level.ex_PrecacheEffect]]("fx/props/radio_sparks_smoke.efx");
}

perkInitPost()
{
	// perk related precaching after map load

	// precache team related waypoints
	if(level.ex_flak_waypoints == 3)
	{
		switch(game["allies"])
		{
			case "american":
				game["waypoint_activated_allies"] = "spc_waypoint_activated_a";
				game["waypoint_deactivated_allies"] = "spc_waypoint_deactivated_a";
				break;
			case "british":
				game["waypoint_activated_allies"] = "spc_waypoint_activated_b";
				game["waypoint_deactivated_allies"] = "spc_waypoint_deactivated_b";
				break;
			default:
				game["waypoint_activated_allies"] = "spc_waypoint_activated_r";
				game["waypoint_deactivated_allies"] = "spc_waypoint_deactivated_r";
				break;
		}

		game["waypoint_activated_axis"] = "spc_waypoint_activated_g";
		game["waypoint_deactivated_axis"] = "spc_waypoint_deactivated_g";

		[[level.ex_PrecacheShader]](game["waypoint_activated_allies"]);
		[[level.ex_PrecacheShader]](game["waypoint_deactivated_allies"]);
		[[level.ex_PrecacheShader]](game["waypoint_activated_axis"]);
		[[level.ex_PrecacheShader]](game["waypoint_deactivated_axis"]);
	}
}

perkCheck()
{
	// checks before being able to buy this perk
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

	if(!isDefined(self.flak_moving_timer))
	{
		if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"SPECIALS_FLAK_READY");
	}

	self thread hudNotifySpecial(index);
	approved_angles = [];

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
				if(getPerkPriority(index))
				{
					if(!extreme\_ex_utils::tooClose(level.ex_mindist["perks"][0], level.ex_mindist["perks"][1], level.ex_mindist["perks"][2], level.ex_mindist["perks"][3]))
					{
						if(perkEvenGround(self.origin, self.angles) && perkClearance(self.origin, 10, 4, 80))
						{
							approved_angles = perkGetApprovedAngles(self.origin + (0,0,50), 500, 20, 5);
							if(!isDefined(approved_angles) || !approved_angles.size) self iprintlnbold(&"SPECIALS_BAD_LOCATION");
								else if(self playerActionPanel(-1)) break;
						}
					}
				}
				while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
		}
	}

	self thread playerStartUsingPerk(index, true);
	self thread hudNotifySpecialRemove(index);

	level thread perkCreate(self, approved_angles);

	if(level.ex_flak_messages)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(player == self || !isDefined(player.pers["team"])) continue;
			else if(player.pers["team"] == self.pers["team"])
				player iprintlnbold(&"SPECIALS_FLAK_DEPLOYED_TEAM", [[level.ex_pname]](self));
			else
				player iprintlnbold(&"SPECIALS_FLAK_DEPLOYED_ENEMY", [[level.ex_pname]](self));
		}
	}
}

/*******************************************************************************
VALIDATION
*******************************************************************************/
perkEvenGround(origin, angles)
{
	f0 = posForward(origin + (0,0,10), angles, 50);
	fl = posLeft(f0, angles, 35);
	pos = posDown(fl, angles, 0);
	if(distance(fl, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}
	fr = posRight(f0, angles, 35);
	pos = posDown(fr, angles, 0);
	if(distance(fr, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}

	b0 = posBack(origin + (0,0,10), angles, 50);
	bl = posLeft(b0, angles, 35);
	pos = posDown(bl, angles, 0);
	if(distance(bl, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}
	br = posRight(b0, angles, 35);
	pos = posDown(br, angles, 0);
	if(distance(br, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}

	return(true);
}

perkGetApprovedAngles(center, radius, yaw_step, pitch_step)
{
	//extreme\_ex_debug::debugVec();
	approved_angles = [];

	for(y = 0; y < 360; y += yaw_step)
	{
		approved_angle = undefined;

		// try angle -45 first, because it looks nice
		//test_angle = perkTestTriplet(center, (rev(randomIntRange(10, 85)), y, 0), radius);
		test_angle = perkTestTriplet(center, (-45, y, 0), radius);
		if(isDefined(test_angle)) approved_angle = test_angle;
		else
		{
			// then scan angles -40 down to 0, otherwise the skylimit will always win
			for(p = 40; p >= 0; p -= pitch_step)
			{
				test_angle = perkTestTriplet(center, (rev(p), y, 0), radius);
				if(isDefined(test_angle))
				{
					approved_angle = test_angle;
					break;
				}
			}

			// lastly scan angles -50 up to -80
			if(!isDefined(approved_angle))
			{
				for(p = 50; p <= 80; p += pitch_step)
				{
					test_angle = perkTestTriplet(center, (rev(p), y, 0), radius);
					if(isDefined(test_angle))
					{
						approved_angle = test_angle;
						break;
					}
				}
			}
		}

		if(isDefined(approved_angle)) approved_angles[approved_angles.size] = approved_angle;
	}

	return(approved_angles);
}

perkTestTriplet(center, angles, radius)
{
	// this will validate an angle by testing a base angle and 2 adjacent angles
	approved_angle = undefined;
	test_angle = perkTestAngle(center, angles, radius, 0);
	if(isDefined(test_angle))
	{
		yaw = angles[1] - 5;
		if(yaw < 0) yaw = 360 - abs(yaw);
		test_angle = perkTestAngle(center, (angles[0], yaw, angles[2]), radius, 0);
		if(isDefined(test_angle))
		{
			yaw = angles[1] + 5;
			if(yaw > 360) yaw = yaw - 360;
			test_angle = perkTestAngle(center, (angles[0], yaw, angles[2]), radius, 0);
			if(isDefined(test_angle)) approved_angle = test_angle;
		}
	}

	return(approved_angle);
}

perkTestAngle(center, angles, radius, debug)
{
	// this will test a single angle
	test_angle = undefined;
	pos = perkForwardLimit(center, angles, radius, true);
	temp_radius = int(distance(center, pos) + 1); // get rid of fractional differences
	if(temp_radius >= radius) test_angle = angles;

	return(test_angle);
}

perkClearance(origin, z_up, z_rings, radius)
{
	//extreme\_ex_debug::debugVec();
	for(x = 0; x < z_rings; x++)
	{
		check_origin = origin + (0,0,z_up);

		for(i = 0; i < 360; i += 10)
		{
			pos = perkForwardLimit(check_origin, (0,i,0), radius + 10, true);
			if(distance(check_origin, pos) < radius)
			{
				//extreme\_ex_debug::debugVec(pos, 1);
				self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
				return(false);
			}
			//extreme\_ex_debug::debugVec(pos, 0);
		}

		z_up += 40;
	}

	return(true);
}

perkForwardLimit(pos, angles, dist, oneshot)
{
	forwardvector = anglestoforward(angles);
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

perkCheckEntity(entity)
{
	if(isDefined(level.flaks))
	{
		for(i = 0; i < level.flaks.size; i++)
			if(level.flaks[i].inuse && isDefined(level.flaks[i].owner) && (level.flaks[i].body == entity || level.flaks[i].guns == entity) ) return(i);
	}

	return(-1);
}

perkValidateAsTarget(index, team)
{
	if(!level.flaks[index].inuse || !level.flaks[index].activated || level.flaks[index].sabotaged || level.flaks[index].destroyed) return(false);
	if(level.flaks[index].health <= 0 || (level.ex_teamplay && level.flaks[index].team == team)) return(false);
	if(!isDefined(level.flaks[index].owner) || !isPlayer(level.flaks[index].owner)) return(false);
	return(true);
}

perkRadiusDamage(origin, team, radius, damage)
{
	if(isDefined(level.flaks))
	{
		for(i = 0; i < level.flaks.size; i++)
		{
			if(perkValidateAsTarget(i, team) && distance(origin, level.flaks[i].org_origin) <= radius) level.flaks[i].health -= damage;
		}
	}
}

/*******************************************************************************
PERK CREATION AND REMOVAL
*******************************************************************************/
perkCreate(owner, approved_angles)
{
	index = perkAllocate();
	angles = (0, owner.angles[1], 0);
	origin = owner.origin;

	level.flaks[index].health = level.ex_flak_maxhealth;
	level.flaks[index].timer = level.ex_flak_timer * 5;
	level.flaks[index].nades = 0;

	level.flaks[index].approved_angles = approved_angles;
	level.flaks[index].allowattach = (level.ex_flak == 2 || level.ex_flak == 3);
	level.flaks[index].mode = 1;

	level.flaks[index].ismoving = false;
	level.flaks[index].isfiring = false;
	level.flaks[index].istargeting = false;

	level.flaks[index].activated = false;
	level.flaks[index].destroyed = false;
	level.flaks[index].sabotaged = false;
	level.flaks[index].abandoned = false;

	level.flaks[index].org_origin = origin;
	level.flaks[index].org_angles = angles;
	level.flaks[index].org_owner = owner;
	level.flaks[index].org_ownernum = owner getEntityNumber();

	// create models
	level.flaks[index].base = spawn("script_model", origin);
	level.flaks[index].base hide();
	level.flaks[index].base setmodel("xmodel/vehicle_flakvierling_base");
	level.flaks[index].base.angles = angles;

	level.flaks[index].body = spawn("script_model", origin + (0,0,40) );
	level.flaks[index].body hide();
	level.flaks[index].body setmodel("xmodel/vehicle_flakvierling_body");
	level.flaks[index].body.angles = angles;

	if(level.ex_flak_complex)
	{
		level.flaks[index].guns = spawn("script_model", origin);
		level.flaks[index].guns hide();
		level.flaks[index].guns setmodel("xmodel/vehicle_flakvierling_guns_assy");
		level.flaks[index].guns.angles = angles;
		level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (0,0,0));

		level.flaks[index].guns.barrels = [];

		level.flaks[index].guns.barrels[0] = spawn("script_model", origin);
		level.flaks[index].guns.barrels[0] hide();
		level.flaks[index].guns.barrels[0] setmodel("xmodel/vehicle_flakvierling_gun_barrel");
		level.flaks[index].guns.barrels[0].angles = angles;
		level.flaks[index].guns.barrels[0] linkTo(level.flaks[index].guns, "tag_gun0", (0,0,0), (0,0,0));

		level.flaks[index].guns.barrels[1] = spawn("script_model", origin);
		level.flaks[index].guns.barrels[1] hide();
		level.flaks[index].guns.barrels[1] setmodel("xmodel/vehicle_flakvierling_gun_barrel");
		level.flaks[index].guns.barrels[1].angles = angles;
		level.flaks[index].guns.barrels[1] linkTo(level.flaks[index].guns, "tag_gun1", (0,0,0), (0,0,0));

		level.flaks[index].guns.barrels[2] = spawn("script_model", origin);
		level.flaks[index].guns.barrels[2] hide();
		level.flaks[index].guns.barrels[2] setmodel("xmodel/vehicle_flakvierling_gun_barrel");
		level.flaks[index].guns.barrels[2].angles = angles;
		level.flaks[index].guns.barrels[2] linkTo(level.flaks[index].guns, "tag_gun2", (0,0,0), (0,0,0));

		level.flaks[index].guns.barrels[3] = spawn("script_model", origin);
		level.flaks[index].guns.barrels[3] hide();
		level.flaks[index].guns.barrels[3] setmodel("xmodel/vehicle_flakvierling_gun_barrel");
		level.flaks[index].guns.barrels[3].angles = angles;
		level.flaks[index].guns.barrels[3] linkTo(level.flaks[index].guns, "tag_gun3", (0,0,0), (0,0,0));
	}
	else
	{
		level.flaks[index].guns = spawn("script_model", origin);
		level.flaks[index].guns hide();
		level.flaks[index].guns setmodel("xmodel/vehicle_flakvierling_guns");
		level.flaks[index].guns.angles = angles;
		level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (0,0,0));
	}

	level.flaks[index].block_trig = spawn("trigger_radius", origin + (0, 0, 20), 0, 30, 30);
	if(level.flaks[index].allowattach) level.flaks[index].mount_trig = spawn("trigger_radius", origin, 0, level.ex_flak_mount_radius, 50);

	// set owner after creating entities so proximity code can handle it
	level.flaks[index].gunner = level.flaks[index].guns;
	level.flaks[index].owner = owner;
	level.flaks[index].team = owner.pers["team"];

	// wait for player to clear perk location
	while(positionWouldTelefrag(origin)) wait( [[level.ex_fpstime]](.05) );
	wait( [[level.ex_fpstime]](1) ); // to let player get out of trigger zone

	// show models
	level.flaks[index].base show();
	level.flaks[index].body show();
	level.flaks[index].guns show();
	if(level.ex_flak_complex)
	{
		level.flaks[index].guns.barrels[0] show();
		level.flaks[index].guns.barrels[1] show();
		level.flaks[index].guns.barrels[2] show();
		level.flaks[index].guns.barrels[3] show();
	}

	level.flaks[index].block_trig setcontents(1);
	if(level.flaks[index].allowattach) level.flaks[index].mount_trig thread perkTrigger(index);

	// restore timer and owner after moving perk
	if(isDefined(owner.flak_moving_timer))
	{
		level.flaks[index].timer = owner.flak_moving_timer;
		owner.flak_moving_timer = undefined;

		if(isDefined(owner.flak_moving_owner) && isPlayer(owner.flak_moving_owner) && owner.pers["team"] == owner.flak_moving_owner.pers["team"])
			level.flaks[index].owner = owner.flak_moving_owner;
		owner.flak_moving_owner = undefined;
	}

	perkActivate(index, false);
	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.flaks.size; i++)
	{
		if(level.flaks[i].inuse == 0)
		{
			level.flaks[i].inuse = 1;
			return(i);
		}
	}

	level.flaks[i] = spawnstruct();
	level.flaks[i].notification = "flak" + i;
	level.flaks[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_flak && isDefined(level.flaks))
	{
		for(i = 0; i < level.flaks.size; i++)
			if(level.flaks[i].inuse && !level.flaks[i].destroyed) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.flaks.size; i++)
		if(level.flaks[i].inuse && isDefined(level.flaks[i].owner) && level.flaks[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	if(!level.flaks[index].inuse) return;
	level notify(level.flaks[index].notification);
	level.flaks[index].destroyed = true; // kills perkThink(index)
	perkDeactivate(index, false);
	wait( [[level.ex_fpstime]](2) );
	perkDeleteWaypoint(index);
	perkFree(index);
}

perkFree(index)
{
	thread levelStopUsingPerk(level.flaks[index].org_ownernum, "flak");
	level.flaks[index].owner = undefined;

	level.flaks[index].block_trig delete();
	if(level.flaks[index].allowattach) level.flaks[index].mount_trig delete();
	if(level.ex_flak_complex)
	{
		level.flaks[index].guns.barrels[0] delete();
		level.flaks[index].guns.barrels[1] delete();
		level.flaks[index].guns.barrels[2] delete();
		level.flaks[index].guns.barrels[3] delete();
	}
	level.flaks[index].guns delete();
	level.flaks[index].body delete();
	level.flaks[index].base delete();

	level.flaks[index].inuse = 0;
}

/*******************************************************************************
PERK MAIN LOGIC
*******************************************************************************/
perkThink(index)
{
	target = level.flaks[index].guns;
	auto_interval = level.ex_flak_interval * 5;

	for(;;)
	{
		target_old = target;
		target = level.flaks[index].guns;

		// signaled to destroy by proximity checks, or when being moved
		if(level.flaks[index].destroyed) return;

		// remove perk if it reached end of life
		if(level.flaks[index].timer <= 0)
		{
			if(isPlayer(level.flaks[index].owner)) level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_REMOVED");
			level thread perkRemove(index);
			return;
		}

		// remove perk if health dropped to 0
		if(level.flaks[index].health <= 0)
		{
			if(level.ex_flak_messages && isPlayer(level.flaks[index].owner)) level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_DESTROYED");
			level thread perkRemove(index);
			return;
		}

		// check if owner left the game or switched teams
		if(!level.flaks[index].abandoned)
		{
			// owner left
			if(!isPlayer(level.flaks[index].owner))
			{
				if((level.ex_flak_remove & 1) == 1)
				{
					level thread perkRemove(index);
					return;
				}
				level.flaks[index].abandoned = true;
				level.flaks[index].owner = level.flaks[index].guns;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
			// owner switched teams
			else if((level.ex_flak_remove & 2) != 2 && level.flaks[index].owner.pers["team"] != level.flaks[index].team)
			{
				level.flaks[index].abandoned = true;
				perkDeleteWaypoint(index);
				level.flaks[index].owner = level.flaks[index].guns;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
		}

		// check for players activating the action panel
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player))
			{
				if(level.flaks[index].inuse && player meleebuttonpressed() && perkInRadius(index, player)) player thread playerActionPanel(index);
			}
		}

		// no gunner, so check auto-mode
		if(!level.flaks[index].istargeting && (level.ex_flak == 1 || level.ex_flak == 3) && !isPlayer(level.flaks[index].gunner))
		{
			auto_interval--;
			if(!auto_interval)
			{
				level thread perkAutoTargeting(index);
				auto_interval = level.ex_flak_interval * 5;
			}
		}

		level.flaks[index].timer--;
		wait( [[level.ex_fpstime]](.2) );
	}
}

perkInRadius(index, player)
{
	if(distance(player.origin, level.flaks[index].guns.origin) < level.ex_flak_actionradius) return(true);
	return(false);
}

perkCanSee(index, player)
{
	cansee = (bullettrace(level.flaks[index].guns.origin + (0, 0, 10), player.origin + (0, 0, 10), false, level.flaks[index].block_trig)["fraction"] == 1);
	if(!cansee) cansee = (bullettrace(level.flaks[index].guns.origin + (0, 0, 10), player.origin + (0, 0, 40), false, level.flaks[index].block_trig)["fraction"] == 1);
	if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.flaks[index].guns.origin + (0, 0, 10), player.ex_eyemarker.origin, false, level.flaks[index].block_trig)["fraction"] == 1);
	return(cansee);
}

perkOwnership(index, player)
{
	if(!isPlayer(level.flaks[index].owner))
	{
		perkDeleteWaypoint(index);
		level.flaks[index].owner = player;
		level.flaks[index].abandoned = false;
		perkCreateWaypoint(index);

		if(!level.ex_teamplay || player.pers["team"] != level.flaks[index].team) level.flaks[index].team = player.pers["team"];
		level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_OWNERSHIP_ABANDONED");
	}
}

/*******************************************************************************
AUTO MODE
*******************************************************************************/
perkAutoTargeting(index, vector, duration)
{
	if(level.flaks[index].istargeting) return;
	level.flaks[index].istargeting = true;

	// this is where the actual targeting will have to go
	if(level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed)
		perkPosition(index, level.flaks[index].approved_angles[randomInt(level.flaks[index].approved_angles.size)]);
	if(level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed)
		perkAutoFiring(index);

	level.flaks[index].istargeting = false;
}

perkAutoFiring(index)
{
	level.flaks[index].isfiring = true;

	for(gun = 0; gun < 4; gun++)
	{
		level.flaks[index].guns playsound("Flak88_fire");
		if(level.ex_flak_complex)
		{
			thread perkAutoFiringComplex(index, gun);
			wait( [[level.ex_fpstime]](.25) );
		}
		else
		{
			thread perkFireShell(index, gun);
			wait( [[level.ex_fpstime]](.25) );
		}

	}

	// wait to allow recoil of last shot to finish
	if(level.ex_flak_complex) wait( [[level.ex_fpstime]](.5) );

	level.flaks[index].isfiring = false;
}

perkAutoFiringComplex(index, gun)
{
	level.flaks[index].guns.barrels[gun] unlink();
	before_recoil = level.flaks[index].guns.barrels[gun].origin;
	angles_forward = anglesToForward(level.flaks[index].guns.barrels[gun].angles);
	after_recoil = before_recoil + [[level.ex_vectorscale]](angles_forward, -15);
	level.flaks[index].guns.barrels[gun] moveTo(after_recoil, .20, .20, 0);

	thread perkFireShell(index, gun);

	wait( [[level.ex_fpstime]](.25) );
	level.flaks[index].guns.barrels[gun] moveTo(before_recoil, .25, .25, 0);
	wait( [[level.ex_fpstime]](.30) );
	level.flaks[index].guns.barrels[gun] linkTo(level.flaks[index].guns, "tag_gun" + gun, (0,0,0), (0,0,0));
}

/*******************************************************************************
POSITIONING
*******************************************************************************/
perkPosition(index, approved_angle)
{
	level.flaks[index].ismoving = true;

	// rotate body (yaw) to approved angle
	//logprint("DEBUG: comparing angles " + level.flaks[index].body.angles + " against approved angles " + approved_angle + "\n");
	if(approved_angle[1] != level.flaks[index].body.angles[1])
	{
		rotate_angle = (level.flaks[index].body.angles[0], approved_angle[1], level.flaks[index].body.angles[2]);

		fdot = vectorDot(anglesToForward(level.flaks[index].body.angles), anglesToForward(rotate_angle));
		if(fdot < -1) fdot = -1;
			else if(fdot > 1) fdot = 1;
		fdiff = abs(acos(fdot)); // difference in degrees

		level.flaks[index].body playloopsound("tank_turret_spin");
		rotate_speed = 0.01 + fdiff * 0.025;
		level.flaks[index].body rotateto(rotate_angle, rotate_speed);
		wait( [[level.ex_fpstime]](rotate_speed) );
		level.flaks[index].body stoploopsound();
		level.flaks[index].body playsound("tank_turret_stop");

		wait( [[level.ex_fpstime]](.5) );
	}

	// rotate guns (pitch) to approved angle
	if(approved_angle[0] != level.flaks[index].guns.angles[0])
	{
		level.flaks[index].guns unlink();
		// guns pitch needs to be normalized after being linked to body
		level.flaks[index].guns.angles = pitchNormalize(anglesNormalize(level.flaks[index].guns.angles));
		rotate_angle = (approved_angle[0], level.flaks[index].guns.angles[1], level.flaks[index].guns.angles[2]);

		fdiff = dif(level.flaks[index].guns.angles[0], rotate_angle[0]);

		level.flaks[index].guns playloopsound("tank_turret_spin");
		rotate_speed = 0.01 + fdiff * 0.025;
		level.flaks[index].guns rotateto(rotate_angle, rotate_speed);
		wait( [[level.ex_fpstime]](rotate_speed) );
		level.flaks[index].guns stoploopsound();
		level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (approved_angle[0],0,0));

		wait( [[level.ex_fpstime]](.1) );
	}

	level.flaks[index].ismoving = false;
}

perkPositionQuick(index, approved_angle)
{
	// rotate body (yaw) to approved angle
	if(approved_angle[1] != level.flaks[index].body.angles[1])
	{
		rotate_angle = (level.flaks[index].body.angles[0], approved_angle[1], level.flaks[index].body.angles[2]);
		level.flaks[index].body rotateto(rotate_angle, .1, 0, 0);
		wait( [[level.ex_fpstime]](.1) );
	}

	// rotate guns (pitch) to approved angle
	if(approved_angle[0] != level.flaks[index].guns.angles[0])
	{
		level.flaks[index].guns unlink();
		level.flaks[index].guns.angles = pitchNormalize(anglesNormalize(level.flaks[index].guns.angles));
		rotate_angle = (approved_angle[0], level.flaks[index].guns.angles[1], level.flaks[index].guns.angles[2]);
		level.flaks[index].guns rotateto(rotate_angle, .1, 0, 0);
		wait( [[level.ex_fpstime]](.1) );
		level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (approved_angle[0],0,0));

		wait( [[level.ex_fpstime]](.1) );
	}
}

perkPositionFlat(index)
{
	// rotate body (pitch) to base position
	if(level.flaks[index].body.angles[0] != 0)
	{
		level.flaks[index].body rotateto((0,level.flaks[index].body.angles[1], level.flaks[index].body.angles[2]), .1, 0, 0);
		wait( [[level.ex_fpstime]](.1) );
	}

	// rotate guns (pitch) to base position
	level.flaks[index].guns unlink();
	level.flaks[index].guns.angles = pitchNormalize(anglesNormalize(level.flaks[index].guns.angles));
	level.flaks[index].guns rotateto((0, level.flaks[index].guns.angles[1], level.flaks[index].guns.angles[2]), .1, 0, 0);
	wait( [[level.ex_fpstime]](.1) );
	level.flaks[index].guns linkTo(level.flaks[index].body, "tag_guns", (0,0,0), (0,0,0));

	// in case auto-fire loop sound is still playing
	level.flaks[index].guns stoploopsound();
}

/*******************************************************************************
PERK ACTIONS
*******************************************************************************/
perkActivate(index, force)
{
	if(!level.flaks[index].inuse || (level.flaks[index].activated && !force)) return;
	perkPosition(index, (-45,level.flaks[index].body.angles[1],level.flaks[index].body.angles[2]));

	level.flaks[index].nades = 0;
	level.flaks[index].activated = true;
	perkCreateWaypoint(index);
}

perkDeactivate(index, forcebarrelup)
{
	if(!level.flaks[index].inuse || (!level.flaks[index].activated && !forcebarrelup)) return;
	level.flaks[index].activated = false;
	perkCreateWaypoint(index);

	if(level.flaks[index].allowattach && isPlayer(level.flaks[index].gunner)) perkDetachPlayer(index, level.flaks[index].gunner);
	while(level.flaks[index].istargeting) wait( [[level.ex_fpstime]](.05) );

	if(forcebarrelup) perkPosition(index, (-85,level.flaks[index].body.angles[1],level.flaks[index].body.angles[2]));
		else perkPosition(index, (20,level.flaks[index].body.angles[1],level.flaks[index].body.angles[2]));
}

perkDeactivateTimer(index, timer)
{
	if(!level.flaks[index].inuse || (!level.flaks[index].activated || level.flaks[index].destroyed)) return;

	if(timer && level.flaks[index].timer > timer)
	{
		perkDeactivate(index, false);
		wait( [[level.ex_fpstime]](timer) );
		if(!level.flaks[index].sabotaged && !level.flaks[index].destroyed && level.flaks[index].timer > 5)
			perkActivate(index, false);
	}
	else level thread perkDeactivate(index, false);
}

perkAdjust(index, player)
{
	// NOP
}

perkSabotage(index)
{
	if(!level.flaks[index].inuse || level.flaks[index].sabotaged) return;
	level.flaks[index].sabotaged = true; // stops targeting and firing
	perkMalfunction(index);
	if(level.flaks[index].sabotaged) perkDeactivate(index, true);
}

perkRepair(index)
{
	if(!level.flaks[index].inuse || !level.flaks[index].sabotaged) return;
	level.flaks[index].sabotaged = false;
	perkActivate(index, level.flaks[index].activated);
	level.flaks[index].health = level.ex_flak_maxhealth;
}

perkDestroy(index)
{
	if(!level.flaks[index].inuse || level.flaks[index].destroyed) return;
	level.flaks[index].destroyed = true; // kills perkThink(index)
	perkMalfunction(index);
	perkRemove(index);
}

perkMove(index, player)
{
	if(!level.flaks[index].inuse || isDefined(player.flak_moving_timer)) return;
	level.flaks[index].destroyed = true; // kills perkThink(index)
	player.flak_moving_timer = level.flaks[index].timer;
	player.flak_moving_owner = level.flaks[index].owner;
	wait( [[level.ex_fpstime]](.5) );
	perkRemove(index);
	player thread playerGiveBackPerk("flak");
}

perkSteal(index, player)
{
	perkDeleteWaypoint(index);
	level.flaks[index].owner = player;
	if(isAlive(player) && (!level.ex_teamplay || player.pers["team"] != level.flaks[index].team))
		level.flaks[index].team = player.pers["team"];
	level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_OWNERSHIP");

	if(level.flaks[index].sabotaged) perkRepair(index);
		else if(!level.flaks[index].activated) perkActivate(index, false);
			else perkCreateWaypoint(index);
}

perkMalfunction(index)
{
	for(i = 0; i < 20; i++)
	{
		// quit malfunctioning if perk has been removed or repaired
		if(!level.flaks[index].inuse || (!level.flaks[index].sabotaged && !level.flaks[index].destroyed)) break;

		random_time = randomFloatRange(.1, 1);
		playfx(level.ex_effect["flak_sparks"], level.flaks[index].guns.origin);
		wait( [[level.ex_fpstime]](random_time) );
	}
}

/*******************************************************************************
ACTION PANEL
*******************************************************************************/
playerActionPanel(index)
{
	self endon("kill_thread");

	if(isDefined(self.flak_action) || !isAlive(self) || !self isOnGround()) return(false);

	// if this is a deployment call (index -1), first check basic requirements before setting flak_action flag
	candeploy = false;
	if(index == -1)
	{
		if(self.ex_moving || self [[level.ex_getstance]](false) == 2) return(false);
		candeploy = true;
	}

	self.flak_action = true;

	// set mayadjust to false if this perk has no adjust capabilities
	mayadjust = false;

	canactivate = false;
	canadjust = false;
	canrepair = false;
	canmove = false;
	candeactivate = false;
	cansabotage = false;
	candestroy = false;
	cansteal = false;

	panel = game["actionpanel_owner"];
	if(!candeploy)
	{
		// check ownership if not deploying
		perkOwnership(index, self);

		// check owner actions
		if(self == level.flaks[index].owner && (!level.ex_teamplay || self.pers["team"] == level.flaks[index].team))
		{
			canactivate = ((level.ex_flak_owneraction & 1) == 1 && !level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canadjust = (mayadjust && (level.ex_flak_owneraction & 2) == 2 && level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canrepair = ((level.ex_flak_owneraction & 4) == 4 && level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canmove = ((level.ex_flak_owneraction & 8) == 8 && !level.flaks[index].sabotaged && !level.flaks[index].destroyed && !playerPerkIsLocked("flak", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.flak_action = undefined;
				return(false);
			}
		}
		// check teammates actions
		else if(level.ex_teamplay && self.pers["team"] == level.flaks[index].team)
		{
			canactivate = ((level.ex_flak_teamaction & 1) == 1 && !level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canadjust = (mayadjust && (level.ex_flak_teamaction & 2) == 2 && level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canrepair = ((level.ex_flak_teamaction & 4) == 4 && level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			canmove = ((level.ex_flak_teamaction & 8) == 8 && !level.flaks[index].sabotaged && !level.flaks[index].destroyed && !playerPerkIsLocked("flak", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.flak_action = undefined;
				return(false);
			}
		}
		// check enemy actions
		else if(!level.ex_teamplay || self.pers["team"] != level.flaks[index].team)
		{
			panel = game["actionpanel_enemy"];
			candeactivate = ((level.ex_flak_enemyaction & 1) == 1 && level.flaks[index].activated && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			cansabotage = ((level.ex_flak_enemyaction & 2) == 2 && !level.flaks[index].sabotaged && !level.flaks[index].destroyed);
			candestroy = ((level.ex_flak_enemyaction & 4) == 4 && !level.flaks[index].destroyed);
			cansteal = ((level.ex_flak_enemyaction & 8) == 8 && !level.flaks[index].destroyed);
			if(!candeactivate && !cansabotage && !candestroy && !cansteal)
			{
				self.flak_action = undefined;
				return(false);
			}
		}
	}

	// show the action panel
	hud_index = playerHudCreate("perk_action_bg", 0, 160, 1, undefined, 1, 0, "center_safearea", "center_safearea", "center", "middle", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, panel, 256, 256);

	// show progress bar
	hud_index = playerHudCreate("perk_action_pb", (200 / -2) + 2, 161, 1, (0,1,0), 1, 1, "center_safearea", "center_safearea", "left", "middle", false, true);
	if(hud_index != -1)
	{
		playerHudSetShader(hud_index, "white", 1, 11);
		playerHudScale(hud_index, level.ex_flak_actiontime * 4, 0, 200, 11);
	}

	// show disabled indicator for action 1
	actiontimer_autostop = 0;
	if(!(candeploy || canactivate || candeactivate))
	{
		hud_index = playerHudCreate("perk_action_a1", -45, 112, 1, undefined, 1, 1, "center_safearea", "center_safearea", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["actionpanel_denied"], 45, 45);
	}
	else actiontimer_autostop = 1;
	// show disabled indicator for action 2
	if(!(canadjust || cansabotage))
	{
		hud_index = playerHudCreate("perk_action_a2", 3, 112, 1, undefined, 1, 1, "center_safearea", "center_safearea", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["actionpanel_denied"], 45, 45);
	}
	else actiontimer_autostop = 2;
	// show disabled indicator for action 3
	if(!(canrepair || candestroy))
	{
		hud_index = playerHudCreate("perk_action_a3", 51, 112, 1, undefined, 1, 1, "center_safearea", "center_safearea", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["actionpanel_denied"], 45, 45);
	}
	else actiontimer_autostop = 3;
	// show disabled indicator for action 4
	if(!(canmove || cansteal))
	{
		hud_index = playerHudCreate("perk_action_a4", 99, 112, 1, undefined, 1, 1, "center_safearea", "center_safearea", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetShader(hud_index, game["actionpanel_denied"], 45, 45);
	}
	else actiontimer_autostop = 4;

	// now see for how long the melee key is pressed
	granted = false;
	progresstime = 0;
	while(self meleebuttonpressed())
	{
		if(!self isOnGround() || self.ex_moving || self [[level.ex_getstance]](false) == 2) break;
		if(!candeploy && !level.flaks[index].inuse) break;
		if(!candeploy && !perkInRadius(index, self) && !perkCanSee(index, self)) break;

		wait( level.ex_fps_frame );
		progresstime += level.ex_fps_frame;
		if(progresstime >= level.ex_flak_actiontime * actiontimer_autostop) break;
	}

	playerHudDestroy("perk_action_a1");
	playerHudDestroy("perk_action_a2");
	playerHudDestroy("perk_action_a3");
	playerHudDestroy("perk_action_a4");
	playerHudDestroy("perk_action_pb");
	playerHudDestroy("perk_action_bg");

	if(candeploy && progresstime >= level.ex_flak_actiontime) granted = true;
	if(!candeploy && level.flaks[index].inuse)
	{
		// 4th action (8 second boundary by default)
		if(!granted && progresstime >= level.ex_flak_actiontime * 4)
		{
			if(canmove)
			{
				granted = true;
				if(level.ex_flak_messages == 2 && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_MOVED_BY", [[level.ex_pname]](self));
				level thread perkMove(index, self);
			}
			else if(cansteal)
			{
				granted = true;
				if(level.ex_flak_messages && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_STOLEN_BY", [[level.ex_pname]](self));
				level thread perkSteal(index, self);
			}
		}

		// 3rd action (6 second boundary by default)
		if(!granted && progresstime >= level.ex_flak_actiontime * 3)
		{
			if(canrepair)
			{
				granted = true;
				if(level.ex_flak_messages == 2 && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_REPAIRED_BY", [[level.ex_pname]](self));
				level thread perkRepair(index);
			}
			else if(candestroy)
			{
				granted = true;
				if(level.ex_flak_messages && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_DESTROYED_BY", [[level.ex_pname]](self));
				level thread perkDestroy(index);
			}
		}

		// 2nd action (4 second boundary by default)
		if(!granted && progresstime >= level.ex_flak_actiontime * 2)
		{
			if(canadjust)
			{
				granted = true;
				if(level.ex_flak_messages == 2 && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_ADJUSTED_BY", [[level.ex_pname]](self));
				level thread perkAdjust(index, self);
			}
			else if(cansabotage)
			{
				granted = true;
				if(level.ex_flak_messages && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_SABOTAGED_BY", [[level.ex_pname]](self));
				level thread perkSabotage(index);
			}
		}

		// 1st action (2 second boundary by default)
		if(!granted && progresstime >= level.ex_flak_actiontime)
		{
			if(canactivate)
			{
				granted = true;
				if(level.ex_flak_messages == 2 && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_ACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkActivate(index, false);
			}
			else if(candeactivate)
			{
				granted = true;
				if(level.ex_flak_messages && isPlayer(level.flaks[index].owner) && self != level.flaks[index].owner)
					level.flaks[index].owner iprintlnbold(&"SPECIALS_FLAK_DEACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkDeactivate(index, false);
			}
		}
	}

	wait( [[level.ex_fpstime]](.2) );
	self.flak_action = undefined;
	if(!granted) return(false);
		else if(!candeploy) while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
	return(true);
}

/*******************************************************************************
MANUAL MODE
*******************************************************************************/
perkTrigger(index)
{
	level endon("ex_gameover");
	level endon(level.flaks[index].notification);

	while(1)
	{
		self waittill("trigger", player);

		if(isDefined(player.onflak) || isPlayer(level.flaks[index].gunner))
		{
			while(isDefined(player.onflak) || isPlayer(level.flaks[index].gunner)) wait( [[level.ex_fpstime]](1) );
			continue;
		}
		prevent_entry = false;
		switch(level.ex_flak_mount)
		{
			case 0: if(player != level.flaks[index].owner) prevent_entry = true; break;
			case 1: if(player.pers["team"] != level.flaks[index].team) prevent_entry = true; break;
		}
		if(!prevent_entry && player useButtonPressed()) level thread perkAttachPlayer(index, player);
	}
}

perkAttachPlayer(index, player)
{
	level endon(level.flaks[index].notification);
	player endon("kill_thread");
	player endon("flak_detach");

	while(player useButtonPressed()) wait( [[level.ex_fpstime]](.05) );

	if(!isPlayer(level.flaks[index].gunner) && isDefined(player))
	{
		level.flaks[index].gunner = player;
		player.onflak = index;
		player [[level.ex_dWeapon]]();

		perkDeleteWaypoint(index);
		level thread perkMonitorPlayerKill(index, player);
		level thread perkMonitorPlayerKeys(index, player);

		flak = level.flaks[index].body;

		if(level.flaks[index].ismoving || level.flaks[index].isfiring)
		{
			player linkTo(flak, "tag_player", (0,0,0), (0,0,0));
			player setPlayerAngles(flak.angles);
			while(level.flaks[index].ismoving || level.flaks[index].isfiring) wait( [[level.ex_fpstime]](.05) );
			perkPositionFlat(index);
		}
		else
		{
			perkPositionFlat(index);
			player linkTo(flak, "tag_player", (0,0,0), (0,0,0));
		}

		iNewPitch = flak.angles[0];
		iNewYaw = flak.angles[1];
		iOldPitch = iNewPitch;
		iOldYaw = iNewYaw;

		while(isPlayer(player) && isAlive(player))
		{
			angles = flak.angles;

			temp = flak.origin + [[level.ex_vectorscale]](anglesToForward(player getPlayerAngles()), 10000);
			lookDirection = anglesNormalize(vectorToAngles(temp - flak.origin));

			temp = flak.origin + [[level.ex_vectorscale]](anglesToForward(angles), -10000);
			backDirection = anglesNormalize(vectorToAngles(temp - flak.origin));

			hdirection = angleDir(lookDirection[1], backDirection[1]);
			if(hdirection != 0)
			{
				hdiff = angleDiff(lookDirection[1], angles[1]);
				iTempYaw = hdirection;
				iYaw = hdiff;
				if(iYaw > 80) iYaw = 80;
				iTempYaw *= hdiff * (15 / (15 + iYaw));
				iNewYaw = angles[1] + iTempYaw;
			}

			vdirection = angleDir(angles[0], lookDirection[0]);
			temp = lookDirection[0];
			if( temp > 90 || temp < -90) temp -= 360;
			vdirection = angleDir(angles[0], angleNormalize(temp));
			if(vdirection != 0)
			{
				vdiff = angleDiff(lookDirection[0], angles[0]);
				iTempPitch = vdirection * (vdiff * (10 / 30));
				iNewPitch = angles[0] + iTempPitch;
			}

			if(iNewPitch > 0)
			{
				iNewPitch = 0;
				perkPlayerHUD(player, (1,0,0), false);
			}
			else if(iNewPitch < -70)
			{
				iNewPitch = -70;
				perkPlayerHUD(player, (1,0,0), false);
			}
			else perkPlayerHUD(player, (0,1,0), false);

			if(iNewPitch != iOldPitch || iNewYaw != iOldYaw)
			{
				flak rotateTo((iNewPitch, iNewYaw, 0), .1, 0, 0);
				iOldPitch = iNewPitch;
				iOldYaw = iNewYaw;
			}

			wait( [[level.ex_fpstime]](.1) );
		}
	}
}

perkMonitorPlayerKeys(index, player)
{
	level endon(level.flaks[index].notification);
	player endon("kill_thread");

	mode1_gun = -1;
	mode2_gun = 0;

	while(isDefined(player) && isAlive(player))
	{
		wait( [[level.ex_fpstime]](.1) );
		if(player useButtonPressed())
		{
			while(isDefined(player) && player useButtonPressed()) wait( [[level.ex_fpstime]](.1) );
			break;
		}
		else if(player meleeButtonPressed())
		{
			oldmode = level.flaks[index].mode;
			if(level.flaks[index].mode == 1 && level.ex_flak_firemode) level.flaks[index].mode = 2;
				else if(level.flaks[index].mode == 2 && level.ex_flak_firemode > 1) level.flaks[index].mode = 4;
					else level.flaks[index].mode = 1;

			if(level.ex_flak_complex && oldmode != level.flaks[index].mode)
			{
				player freezecontrols(true);
				wait( [[level.ex_fpstime]](1) );
				if(level.flaks[index].mode == 1)
				{
					perkShowRecoil(index, 0);
				}
				else if(level.flaks[index].mode == 2)
				{
					thread perkShowRecoil(index, 0);
					perkShowRecoil(index, 3);
				}
				else
				{
					thread perkShowRecoil(index, 0);
					thread perkShowRecoil(index, 1);
					thread perkShowRecoil(index, 2);
					perkShowRecoil(index, 3);
				}
				player freezecontrols(false);
			}

			while(isDefined(player) && player meleeButtonPressed()) wait( [[level.ex_fpstime]](.1) );
		}
		else if(player attackButtonPressed())
		{
			// do not allow manual fire if still finishing auto movement or fire
			if(level.flaks[index].ismoving || level.flaks[index].isfiring) continue;

			// only play sound once, even when firing multiple guns simultaneously
			level.flaks[index].guns playsound("Flak88_fire");

			if(level.flaks[index].mode == 1)
			{
				mode1_gun++;
				if(mode1_gun > 3) mode1_gun = 0;
				thread perkFireShell(index, mode1_gun);
			}
			else if(level.flaks[index].mode == 2)
			{
				mode2_gun = !mode2_gun;
				if(mode2_gun == 0)
				{
					thread perkFireShell(index, 0);
					thread perkFireShell(index, 3);
				}
				else
				{
					thread perkFireShell(index, 1);
					thread perkFireShell(index, 2);
				}
			}
			else
			{
				thread perkFireShell(index, 0);
				thread perkFireShell(index, 1);
				thread perkFireShell(index, 2);
				thread perkFireShell(index, 3);
			}

			wait( [[level.ex_fpstime]](.25) );
		}
	}

	thread perkDetachPlayer(index, player);
}

perkMonitorPlayerKill(index, player)
{
	level endon(level.flaks[index].notification);

	player waittill("kill_thread");

	// only reposition flak if not moving or firing (in case player mounts and unmounts flak
	// while still moving or firing in auto mode)
	if(!level.flaks[index].ismoving && !level.flaks[index].isfiring) perkPositionFlat(index);

	thread perkDetachPlayer(index, player);
}

perkShowRecoil(index, gun)
{
	level.flaks[index].guns.barrels[gun] unlink();
	before_recoil = level.flaks[index].guns.barrels[gun].origin;
	angles_forward = anglesToForward(level.flaks[index].guns.barrels[gun].angles);
	after_recoil = before_recoil + [[level.ex_vectorscale]](angles_forward, -15);

	for(i = 0; i < 3; i++)
	{
		level.flaks[index].guns.barrels[gun] moveTo(after_recoil, .15, .15, 0);
		wait( [[level.ex_fpstime]](.20) );
		level.flaks[index].guns.barrels[gun] moveTo(before_recoil, .15, .15, 0);
		wait( [[level.ex_fpstime]](.20) );
	}

	level.flaks[index].guns.barrels[gun] linkTo(level.flaks[index].guns, "tag_gun" + gun, (0,0,0), (0,0,0));
}

perkDetachPlayer(index, player)
{
	perkCreateWaypoint(index);
	level.flaks[index].gunner = level.flaks[index].guns;
	if(isDefined(player))
	{
		player notify("flak_detach");
		player.onflak = undefined;
		perkPlayerHUD(player, (1,0,0), true);
		if(isAlive(player))
		{
			player unlink();
			player [[level.ex_eWeapon]]();
			player freezecontrols(false);
		}
	}

	// only reposition flak if not moving or firing (in case player mounts and unmounts flak
	// while still moving or firing in auto mode)
	if(!level.flaks[index].ismoving && !level.flaks[index].isfiring) perkPositionFlat(index);
}

perkPlayerHUD(player, color, remove)
{
	if(!isDefined(remove)) remove = true;
	if(!remove)
	{
		hud_index = player playerHudCreate("special_flakreticle", 0, 2, 0.7, color, 1, 0, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index == -1) return;
		player playerHudSetText(hud_index, game["flak_reticle"]);
	}
	else player playerHudDestroy("special_flakreticle");
}

angleDir(angleNew, angleOld)
{
	if(angleNew <= 180)
	{
		temp = angleNew + 180;
		if(angleOld >= angleNew && angleOld <= temp) iResult = 1;
			else iResult = -1;
	}
	else
	{
		temp = angleNew - 180;
		if(angleOld >= temp && angleOld <= angleNew) iResult = -1;
			else iResult = 1;
	}

	return(iResult);
}

angleDiff(angleNew, angleOld)
{
	val1 = angleMod(angleNew, true);
	val2 = angleMod(angleOld, true);

	if(val1 > val2)
	{
		temp = val1;
		val1 = val2;
		val2 = temp;
	}

	if((val2 - val1) < 180) return(val2 - val1);
		else return((360 - val2) + val1);
}

angleMod(angle, positive)
{
	if(angle < 0)
	{
		if(angle < -1000)
		{
			temp = int(angle / -360) - 1;
			angle -= (-360 * temp);
		}
		while(angle <= -360) angle += 360;
		if(positive) angle = (360 + angle);
	}
	else if(angle > 0)
	{
		if(angle > 1000)
		{
			temp = int(angle / 360) - 1;
			angle -= (360 * temp);
		}
		while(angle >= 360) angle -= 360;
	}

	return(angle);
}

/*******************************************************************************
SHELL
*******************************************************************************/
perkFireShell(index, gun)
{
	shell = spawn("script_model", (0,0,0));
	shell setmodel("xmodel/weapon_flak_missile");
	shell hide();
	// align shell with gun barrel
	if(level.ex_flak_complex)
	{
		playfxontag(level.ex_effect["flak_shot"], level.flaks[index].guns.barrels[gun], "tag_flash");
		shell linkto(level.flaks[index].guns.barrels[gun], "tag_flash", (0,0,0), (0,0,0));
	}
	else
	{
		playfxontag(level.ex_effect["flak_shot"], level.flaks[index].guns, "tag_flash" + gun);
		shell linkto(level.flaks[index].guns, "tag_flash" + gun, (0,0,0), (0,0,0));
	}

	// must have a small wait here to update shell origin and angles
	wait( [[level.ex_fpstime]](.05) );
	shell unlink();
	// make sure the shell is not touching the barrel, or the bullettrace will fail
	shell.origin = shell.origin + [[level.ex_vectorscale]](anglesToForward(shell.angles), 20);
	shell show();
	shell thread perkTrackShell(index);
}

perkTrackShell(index)
{
	endpos = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
	trace = bulletTrace(self.origin, endpos, true, self);

	// if bullettrace hit a moving target, extend the end position to allow the shell to hit it
	if(isDefined(trace["entity"])) trace["position"] = trace["position"] + [[level.ex_vectorscale]](anglesToForward(self.angles), 2000);

	shell_ttl = calcTime(self.origin, trace["position"], 100);
	if(shell_ttl > 0) self moveto(trace["position"], shell_ttl, 0, 0);

	lookahead = [[level.ex_vectorscale]](anglesToForward(self.angles), 200);
	while(shell_ttl > 0)
	{
		wait( [[level.ex_fpstime]](.05) );
		shell_ttl -= .05;

		endpos = self.origin + lookahead;
		trace = bulletTrace(self.origin, endpos, true, self);
		//if(trace["fraction"] != 1) shell_ttl = calcTime(self.origin, trace["position"], 100);
		if(trace["fraction"] != 1) break;
	}

	// handle explosion and damage
	if(isDefined(trace["entity"]))
	{
		self hide();

		if(isPlayer(level.flaks[index].owner) && level.flaks[index].owner.sessionstate != "spectator" && (!level.ex_teamplay || level.flaks[index].owner.pers["team"] == level.flaks[index].team))
		{
			dodamage = true;

			while(1)
			{
				// player
				if(isPlayer(trace["entity"]) && (!level.ex_teamplay || trace["entity"].pers["team"] != level.flaks[index].team)) break;

				// planes (ask air traffic controller)
				target_index = extreme\_ex_airtrafficcontroller::planeCheckEntity(trace["entity"]);
				if(target_index != -1)
				{
					// CONSIDER: var for # of hits instead of single hit
					if(!level.ex_teamplay || level.planes[target_index].team != level.flaks[index].team) level.planes[target_index].health -= 1000;
					break;
				}

				// helicopter
				if(level.ex_heli && isDefined(level.helicopter) && trace["entity"] == level.helicopter)
				{
					if(!level.ex_teamplay || level.helicopter.team != level.flaks[index].team) level.helicopter.health -= 100;
					break;
				}

				// gunship
				if(level.ex_gunship && trace["entity"] == level.gunship)
				{
					if(level.ex_gunship_protect != 1 && isPlayer(level.gunship.owner) && (!level.ex_teamplay || level.gunship.owner.pers["team"] != level.flaks[index].team)) level.gunship.health -= 100;
					break;
				}

				// gunship perk
				if(level.ex_gunship_special && trace["entity"] == level.gunship_special)
				{
					if(level.ex_gunship_protect != 1 && isPlayer(level.gunship_special.owner) && (!level.ex_teamplay || level.gunship_special.owner.pers["team"] != level.flaks[index].team)) level.gunship_special.health -= 100;
					break;
				}

				// Flaks
				target_index = extreme\_ex_specials_flak::perkCheckEntity(trace["entity"]);
				if(target_index != -1)
				{
					if(!level.ex_teamplay || level.flaks[target_index].team != level.flaks[index].team) level.flaks[target_index].health -= 100;
					break;
				}

				// GMLs
				target_index = extreme\_ex_specials_gml::perkCheckEntity(trace["entity"]);
				if(target_index != -1)
				{
					if(!level.ex_teamplay || level.gmls[target_index].team != level.flaks[index].team) level.gmls[target_index].health -= 100;
					break;
				}

				// nothing of interest
				dodamage = false;
				break;
			}

			if(dodamage)
			{
				playfx(level.ex_effect["artillery"], self.origin);
				ms = randomInt(18) + 1;
				self playsound("mortar_explosion" + ms);

				// using weapon dummy3_mp so we don't have to precache another weapon. We will convert dummy3_mp to flakmissile_mp for MOD_EXPLOSIVE later on
				if(!game["perkcatalog"][ getPerkIndex("flak") ]["price"] && isPlayer(level.flaks[index].gunner))
					self thread extreme\_ex_utils::scriptedfxradiusdamage(level.flaks[index].gunner, undefined, "MOD_EXPLOSIVE", "dummy3_mp", 200, 150, 30, "none", undefined, false, true, true);
				else if(isPlayer(level.flaks[index].owner) && level.flaks[index].owner.sessionstate != "spectator")
					self thread extreme\_ex_utils::scriptedfxradiusdamage(level.flaks[index].owner, undefined, "MOD_EXPLOSIVE", "dummy3_mp", 200, 150, 30, "none", undefined, false, true, true);
				else
					self thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_EXPLOSIVE", "dummy3_mp", 200, 0, 0, "none", undefined, false, true, true);

				wait( [[level.ex_fpstime]](1) );
			}
		}
	}

	self delete();
}

perkTrackShellNoDamage(index)
{
	endpos = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
	trace = bulletTrace(self.origin, endpos, false, self);
	shell_ttl = calcTime(self.origin, trace["position"], 60);
	if(shell_ttl <= 0)
	{
		self delete();
		return;
	}
	self moveto(trace["position"], shell_ttl, 0, 0);
	wait( [[level.ex_fpstime]](shell_ttl) );

	// handle explosion
	self hide();
	playfx(level.ex_effect["artillery"], self.origin);
	ms = randomInt(18) + 1;
	self playsound("mortar_explosion" + ms);
	self delete();
}

/*******************************************************************************
WAYPOINT MANAGEMENT
*******************************************************************************/
perkCreateWaypoint(index)
{
	if(level.ex_flak_waypoints)
	{
		if(level.ex_flak_waypoints != 1 || !isPlayer(level.flaks[index].owner)) levelCreateWaypoint(index);
			else level.flaks[index].owner playerCreateWaypoint(index);
	}
}

perkDeleteWaypoint(index)
{
	if(level.ex_flak_waypoints)
	{
		if(level.ex_flak_waypoints != 1 || !isPlayer(level.flaks[index].owner)) levelDeleteWaypoint(index);
			else level.flaks[index].owner playerDeleteWaypoint(index);
	}
}

levelCreateWaypoint(index)
{
	if(!isDefined(level.flaks) || !isDefined(level.flaks[index])) return;

	level levelDeleteWaypoint(index);

	if(level.ex_flak_waypoints == 3 || !isPlayer(level.flaks[index].owner))
	{
		if(level.flaks[index].abandoned) shader = game["waypoint_abandoned"];
		else if(level.flaks[index].activated)
		{
			if(level.flaks[index].team == "axis") shader = game["waypoint_activated_axis"];
				else shader = game["waypoint_activated_allies"];
		}
		else
		{
			if(level.flaks[index].team == "axis") shader = game["waypoint_deactivated_axis"];
				else shader = game["waypoint_deactivated_allies"];
		}

		hud_index = levelHudCreate("waypoint_flak" + index, undefined, level.flaks[index].org_origin[0], level.flaks[index].org_origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}
	else
	{
		if(level.flaks[index].abandoned) shader = game["waypoint_abandoned"];
			else if(level.flaks[index].activated) shader = game["waypoint_activated"];
				else shader = game["waypoint_deactivated"];

		hud_index = levelHudCreate("waypoint_flak" + index, level.flaks[index].team, level.flaks[index].org_origin[0], level.flaks[index].org_origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}

	levelHudSetShader(hud_index, shader, 7, 7);
	levelHudSetWaypoint(hud_index, level.flaks[index].org_origin[2] + 100, true);
	level.flaks[index].waypoint = hud_index;
}

levelDeleteWaypoint(index)
{
	if(!isDefined(level.flaks) || !isDefined(level.flaks[index])) return;
	if(!isDefined(level.flaks[index].waypoint)) return;

	levelHudDestroy(level.flaks[index].waypoint);
	level.flaks[index].waypoint = undefined;
}

playerCreateWaypoint(index)
{
	if(!isDefined(self.flak_waypoints)) self.flak_waypoints = [];

	self playerDeleteWaypoint(index);

	if(level.flaks[index].abandoned) shader = game["waypoint_abandoned"];
		if(level.flaks[index].activated) shader = game["waypoint_activated"];
			else shader = game["waypoint_deactivated"];

	hud_index = playerHudCreate("waypoint_flak" + index, level.flaks[index].org_origin[0], level.flaks[index].org_origin[1], 0.6, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, shader, 7, 7);
	playerHudSetWaypoint(hud_index, level.flaks[index].org_origin[2] + 100, true);

	wp_index = playerAllocateWaypoint();
	self.flak_waypoints[wp_index].id = hud_index;
}

playerAllocateWaypoint()
{
	for(i = 0; i < self.flak_waypoints.size; i++)
	{
		if(self.flak_waypoints[i].inuse == 0)
		{
			self.flak_waypoints[i].inuse = 1;
			return(i);
		}
	}

	self.flak_waypoints[i] = spawnstruct();
	self.flak_waypoints[i].inuse = 1;
	return(i);
}

playerDeleteWaypoint(index)
{
	if(!isDefined(self.flak_waypoints)) return;

	hud_index = playerHudIndex("waypoint_flak" + index);
	if(hud_index == -1) return;

	remove_element = undefined;
	for(i = 0; i < self.flak_waypoints.size; i++)
	{
		if(!self.flak_waypoints[i].inuse) continue;
		if(self.flak_waypoints[i].id != hud_index) continue;
		remove_element = i;
		break;
	}

	if(isDefined(remove_element))
	{
		playerHudDestroy(self.flak_waypoints[remove_element].id);
		self.flak_waypoints[remove_element].inuse = 0;
	}
}

/*******************************************************************************
PROXIMITY CHECK
*******************************************************************************/
checkProximityFlaks(origin, launcher, cpx)
{
	if(level.ex_flak && level.ex_flak_cpx)
	{
		for(index = 0; index < level.flaks.size; index++)
		{
			if(level.flaks[index].inuse && !level.flaks[index].destroyed)
			{
				dist = int( distance(origin, level.flaks[index].guns.origin) );
				if(isDefined(level.flaks[index].owner) && (dist <= cpx))
				{
					level.flaks[index].nades++;
					if(level.flaks[index].nades >= level.ex_flak_cpx_nades)
					{
						if(level.ex_teamplay && isDefined(launcher) && isPlayer(launcher) && launcher.pers["team"] == level.flaks[index].team)
						{
							if((level.ex_flak_cpx & 4) == 4) level thread perkDestroy(index);
							else if((level.ex_flak_cpx & 2) == 2) level thread perkSabotage(index);
							else if((level.ex_flak_cpx & 1) == 1) level thread perkDeactivateTimer(index, level.ex_flak_cpx_timer);
						}
						else
						{
							if((level.ex_flak_cpx & 32) == 32) level thread perkDestroy(index);
							else if((level.ex_flak_cpx & 16) == 16) level thread perkSabotage(index);
							else if((level.ex_flak_cpx & 8) == 8) level thread perkDeactivateTimer(index, level.ex_flak_cpx_timer);
						}
					}
				}
			}
		}
	}
}

/*******************************************************************************
MISC
*******************************************************************************/
getTeamPlayers(team)
{
	team_players = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
		if(isPlayer(players[i]) && isDefined(players[i].pers["team"]) && players[i].pers["team"] == team) team_players[team_players.size] = players[i];

	return(team_players);
}

calcTime(p1, p2, speed)
{
	time = ((distance(p1, p2) * 0.0254) / speed);
	if(time < 0) time = 0;
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

pitchNormalize(angles)
{
	pitch = 0.0 + angles[0];
	if(pitch > 180) pitch = pitch - 360;
	return( (pitch, angles[1], angles[2]) );
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return(var);
}

rev(var)
{
	if(var < 0) var = var * (-1);
		else var = 0 - var;
	return(var);
}

dif(var1, var2)
{
	if(var1 >= var2) diff = var1 - var2;
		else diff = var2 - var1;
	return(abs(diff));
}

/*******************************************************************************
LOCATORS
*******************************************************************************/
posForward(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posBack(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, 0 - length);
	return(origin);
}

posUp(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp( (0, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posAngledUp(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posDown(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp( (180, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posAngledDown(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, -20000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posLeft(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward( (0, angles[1] + 90, 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posAngledLeft(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToRight(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, -20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posRight(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward( (0, angles[1] - 90, 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posAngledRight(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToRight(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}
