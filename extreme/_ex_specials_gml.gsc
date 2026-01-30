#include extreme\_ex_specials;
#include extreme\_ex_hudcontroller;

perkInit()
{
	// perk related precaching

	// create perk array
	level.gmls = [];

	// precache models
	[[level.ex_PrecacheModel]]("xmodel/rim116_base");
	[[level.ex_PrecacheModel]]("xmodel/rim116_arms");
	[[level.ex_PrecacheModel]]("xmodel/rim116_tubes");
	[[level.ex_PrecacheModel]]("xmodel/slamraam_missile");

	// precache other shaders
	game["actionpanel_owner"] = "spc_actionpanel_owner";
	[[level.ex_PrecacheShader]](game["actionpanel_owner"]);
	game["actionpanel_enemy"] = "spc_actionpanel_enemy";
	[[level.ex_PrecacheShader]](game["actionpanel_enemy"]);
	game["actionpanel_denied"] = "spc_actionpanel_denied";
	[[level.ex_PrecacheShader]](game["actionpanel_denied"]);

	// precache general purpose waypoints
	if(level.ex_gml_waypoints)
	{
		game["waypoint_abandoned"] = "spc_waypoint_abandoned";
		[[level.ex_PrecacheShader]](game["waypoint_abandoned"]);

		if(level.ex_gml_waypoints != 3)
		{
			game["waypoint_activated"] = "spc_waypoint_activated";
			[[level.ex_PrecacheShader]](game["waypoint_activated"]);
			game["waypoint_deactivated"] = "spc_waypoint_deactivated";
			[[level.ex_PrecacheShader]](game["waypoint_deactivated"]);
		}
	}

	// precache effects
	level.ex_effect["gml_sparks"] = [[level.ex_PrecacheEffect]]("fx/props/radio_sparks_smoke.efx");
	level.ex_effect["missile_flash"] = [[level.ex_PrecacheEffect]]("fx/muzzleflashes/cruisader_flash.efx");
	level.ex_effect["slamraam"] = [[level.ex_PrecacheEffect]]("fx/misc/slamraam.efx");
}

perkInitPost()
{
	// perk related precaching after map load

	// precache team related waypoints
	if(level.ex_gml_waypoints == 3)
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

	if(!isDefined(self.gml_moving_timer))
	{
		if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"SPECIALS_GML_READY");
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
						if(perkEvenGround(self.origin, self.angles) && perkClearance(self.origin, 20, 4, 80))
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

	if(level.ex_gml_messages)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(player == self || !isDefined(player.pers["team"])) continue;
			else if(player.pers["team"] == self.pers["team"])
				player iprintlnbold(&"SPECIALS_GML_DEPLOYED_TEAM", [[level.ex_pname]](self));
			else
				player iprintlnbold(&"SPECIALS_GML_DEPLOYED_ENEMY", [[level.ex_pname]](self));
		}
	}
}

/*******************************************************************************
VALIDATION
*******************************************************************************/
perkEvenGround(origin, angles)
{
	f0 = posForward(origin + (0,0,10), angles, 35);
	fl = posLeft(f0, angles, 15);
	pos = posDown(fl, angles, 0);
	if(distance(fl, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}
	fr = posRight(f0, angles, 15);
	pos = posDown(fr, angles, 0);
	if(distance(fr, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}

	b0 = posBack(origin + (0,0,10), angles, 35);
	bl = posLeft(b0, angles, 15);
	pos = posDown(bl, angles, 0);
	if(distance(bl, pos) > 30)
	{
		self iprintlnbold(&"SPECIALS_BAD_LOCATION_CLEARANCE");
		return(false);
	}
	br = posRight(b0, angles, 15);
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
	if(isDefined(level.gmls))
	{
		for(i = 0; i < level.gmls.size; i++)
			if(level.gmls[i].inuse && isDefined(level.gmls[i].owner) && (level.gmls[i].arms == entity || level.gmls[i].tube == entity) ) return(i);
	}

	return(-1);
}

perkValidateAsTarget(index, team)
{
	if(!level.gmls[index].inuse || !level.gmls[index].activated || level.gmls[index].sabotaged || level.gmls[index].destroyed) return(false);
	if(level.gmls[index].health <= 0 || (level.ex_teamplay && level.gmls[index].team == team)) return(false);
	if(!isDefined(level.gmls[index].owner) || !isPlayer(level.gmls[index].owner)) return(false);
	return(true);
}

perkRadiusDamage(origin, team, radius, damage)
{
	if(isDefined(level.gmls))
	{
		for(i = 0; i < level.gmls.size; i++)
		{
			if(perkValidateAsTarget(i, team) && distance(origin, level.gmls[i].org_origin) <= radius) level.gmls[i].health -= damage;
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

	level.gmls[index].health = level.ex_gml_maxhealth;
	level.gmls[index].timer = level.ex_gml_timer * 5;
	level.gmls[index].target_type = 0; // to adjust missile speed
	level.gmls[index].missile = 0;
	level.gmls[index].nades = 0;

	level.gmls[index].approved_angles = approved_angles;

	level.gmls[index].ismoving = false;
	level.gmls[index].isfiring = false;
	level.gmls[index].istargeting = false;

	level.gmls[index].activated = false;
	level.gmls[index].destroyed = false;
	level.gmls[index].sabotaged = false;
	level.gmls[index].abandoned = false;

	level.gmls[index].org_origin = origin;
	level.gmls[index].org_angles = angles;
	level.gmls[index].org_owner = owner;
	level.gmls[index].org_ownernum = owner getEntityNumber();

	// create models
	level.gmls[index].base = spawn("script_model", origin);
	level.gmls[index].base hide();
	level.gmls[index].base setmodel("xmodel/rim116_base");
	level.gmls[index].base.angles = angles;

	level.gmls[index].arms = spawn("script_model", origin + (0,0,60) );
	level.gmls[index].arms hide();
	level.gmls[index].arms setmodel("xmodel/rim116_arms");
	level.gmls[index].arms.angles = angles;

	level.gmls[index].tube = spawn("script_model", origin + (0,0,60) );
	level.gmls[index].tube hide();
	level.gmls[index].tube setmodel("xmodel/rim116_tubes");
	level.gmls[index].tube.angles = angles + (89,0,0); // don't set 90 to avoid gimbal lock issue
	level.gmls[index].tube linkTo(level.gmls[index].arms, "tag_origin");

	level.gmls[index].block_trig = spawn("trigger_radius", origin + (0, 0, 20), 0, 60, 60);

	// set owner last so other code knowns it's fully initialized
	level.gmls[index].owner = owner;
	level.gmls[index].team = owner.pers["team"];

	// wait for player to clear perk location
	while(positionWouldTelefrag(origin)) wait( [[level.ex_fpstime]](.05) );
	wait( [[level.ex_fpstime]](1) ); // to let player get out of trigger zone

	// show models
	level.gmls[index].base show();
	level.gmls[index].arms show();
	level.gmls[index].tube show();
	level.gmls[index].block_trig setcontents(1);

	// restore timer and owner after moving perk
	if(isDefined(owner.gml_moving_timer))
	{
		level.gmls[index].timer = owner.gml_moving_timer;
		owner.gml_moving_timer = undefined;

		if(isDefined(owner.gml_moving_owner) && isPlayer(owner.gml_moving_owner) && owner.pers["team"] == owner.gml_moving_owner.pers["team"])
			level.gmls[index].owner = owner.gml_moving_owner;
		owner.gml_moving_owner = undefined;
	}

	perkActivate(index, false);
	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.gmls.size; i++)
	{
		if(level.gmls[i].inuse == 0)
		{
			level.gmls[i].inuse = 1;
			return(i);
		}
	}

	level.gmls[i] = spawnstruct();
	level.gmls[i].notification = "gml" + i;
	level.gmls[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_gml && isDefined(level.gmls))
	{
		for(i = 0; i < level.gmls.size; i++)
			if(level.gmls[i].inuse && !level.gmls[i].destroyed) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.gmls.size; i++)
		if(level.gmls[i].inuse && isDefined(level.gmls[i].owner) && level.gmls[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	if(!level.gmls[index].inuse) return;
	level notify(level.gmls[index].notification);
	level.gmls[index].destroyed = true; // kills perkThink(index)
	perkDeactivate(index, false);
	wait( [[level.ex_fpstime]](2) );
	perkDeleteWaypoint(index);
	perkFree(index);
}

perkFree(index)
{
	thread levelStopUsingPerk(level.gmls[index].org_ownernum, "gml");
	level.gmls[index].owner = undefined;

	level.gmls[index].block_trig delete();
	level.gmls[index].tube delete();
	level.gmls[index].arms delete();
	level.gmls[index].base delete();

	level.gmls[index].inuse = 0;
}

/*******************************************************************************
PERK MAIN LOGIC
*******************************************************************************/
perkThink(index)
{
	wait( [[level.ex_fpstime]](1) );
	thread perkTargeting(index);

	for(;;)
	{
		// signaled to destroy by proximity checks, or when being moved
		if(level.gmls[index].destroyed) return;

		// remove perk if it reached end of life or no more missiles
		if(level.gmls[index].timer <= 0 || level.gmls[index].missile == level.ex_gml_missiles)
		{
			if(isPlayer(level.gmls[index].owner)) level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_REMOVED");
			level thread perkRemove(index);
			return;
		}

		// remove perk if health dropped to 0
		if(level.gmls[index].health <= 0)
		{
			if(level.ex_gml_messages && isPlayer(level.gmls[index].owner)) level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_DESTROYED");
			level thread perkRemove(index);
			return;
		}

		// check if owner left the game or switched teams
		if(!level.gmls[index].abandoned)
		{
			// owner left
			if(!isPlayer(level.gmls[index].owner))
			{
				if((level.ex_gml_remove & 1) == 1)
				{
					level thread perkRemove(index);
					return;
				}
				level.gmls[index].abandoned = true;
				level.gmls[index].owner = level.gmls[index].arms;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
			// owner switched teams
			else if((level.ex_gml_remove & 2) != 2 && level.gmls[index].owner.pers["team"] != level.gmls[index].team)
			{
				level.gmls[index].abandoned = true;
				perkDeleteWaypoint(index);
				level.gmls[index].owner = level.gmls[index].arms;
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
				if(level.gmls[index].inuse && player meleebuttonpressed() && perkInRadius(index, player)) player thread playerActionPanel(index);
			}
		}

		level.gmls[index].timer--;
		wait( [[level.ex_fpstime]](.2) );
	}
}

perkInRadius(index, player)
{
	if(distance(player.origin, level.gmls[index].arms.origin) < level.ex_gml_actionradius) return(true);
	return(false);
}

perkCanSee(index, player)
{
	cansee = (bullettrace(level.gmls[index].arms.origin + (0, 0, 10), player.origin + (0, 0, 10), false, level.gmls[index].block_trig)["fraction"] == 1);
	if(!cansee) cansee = (bullettrace(level.gmls[index].arms.origin + (0, 0, 10), player.origin + (0, 0, 40), false, level.gmls[index].block_trig)["fraction"] == 1);
	if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.gmls[index].arms.origin + (0, 0, 10), player.ex_eyemarker.origin, false, level.gmls[index].block_trig)["fraction"] == 1);
	return(cansee);
}

perkOwnership(index, player)
{
	if(!isPlayer(level.gmls[index].owner))
	{
		perkDeleteWaypoint(index);
		level.gmls[index].owner = player;
		level.gmls[index].abandoned = false;
		perkCreateWaypoint(index);

		if(!level.ex_teamplay || player.pers["team"] != level.gmls[index].team) level.gmls[index].team = player.pers["team"];
		level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_OWNERSHIP_ABANDONED");
	}
}

/*******************************************************************************
TARGETING
*******************************************************************************/
perkTargeting(index)
{
	while(!level.gmls[index].destroyed)
	{
		level.gmls[index].istargeting = true;

		if(level.gmls[index].activated && !level.gmls[index].sabotaged && !level.gmls[index].destroyed)
			perkPosition(index, level.gmls[index].approved_angles[randomInt(level.gmls[index].approved_angles.size)]);
		if(level.gmls[index].activated && !level.gmls[index].sabotaged && !level.gmls[index].destroyed)
			perkFiring(index);

		level.gmls[index].istargeting = false;

		wait( [[level.ex_fpstime]](level.ex_gml_interval) );
	}
}

perkFiring(index)
{
	level.gmls[index].isfiring = true;

	target = perkGetTarget(index);
	if(!isDefined(target)) return;

	missiles_fired = 0;
	missile_no = level.gmls[index].missile;

	for(i = missile_no; i < level.ex_gml_missiles; i++)
	{
		tag = i + 1;
		missile = spawn("script_model", (0,0,0));
		missile setmodel("xmodel/slamraam_missile");
		missile linkto(level.gmls[index].tube, "tag_sam" + tag, (0,0,0), (0,0,0));

		// must have a small wait here to update missile angles
		wait( [[level.ex_fpstime]](.1) );

		raw_angle = pitchNormalize(anglesNormalize(missile.angles));
		tuned_angle = missile perkGetTunedAngle(missile.origin, raw_angle, 500, 5, 5);
		if(isDefined(tuned_angle))
		{
			if(tuned_angle != raw_angle) perkPosition(index, tuned_angle);
			missile unlink();
			playfxontag(level.ex_effect["missile_flash"], level.gmls[index].tube, "tag_sam" + tag);
			playfxontag(level.ex_effect["missile_flash"], level.gmls[index].tube, "tag_flash" + tag);
			missile thread perkFireMissile(index, target, level.gmls[index].target_type);
		}
		else
		{
			missile delete();
			break;
		}

		missiles_fired++;
		level.gmls[index].missile++;
		if(!level.ex_gml_burst || missiles_fired == level.ex_gml_burst) break;
		wait( [[level.ex_fpstime]](level.ex_gml_burst_interval) );
	}

	level.gmls[index].isfiring = false;
}

perkGetTarget(index)
{
	target = undefined;
	target_time = gettime() / 1000;

	// GMls
	if((level.ex_gml_target & 64) == 64)
	{
		if(isDefined(level.gmls))
		{
			for(i = 0; i < level.gmls.size; i++)
			{
				if(extreme\_ex_specials_gml::perkValidateAsTarget(i, level.gmls[index].team))
				{
					if(!isDefined(level.gmls[i].tube.ex_targeted) || (target_time - level.gmls[i].tube.ex_targeted > level.ex_gml_interval))
					{
						target = level.gmls[i].tube;
						target.ex_targeted = gettime() / 1000;
						level.gmls[index].target_type = 64;
						break;
					}
				}
			}
		}
	}

	// flaks
	if(!isDefined(target) && (level.ex_gml_target & 32) == 32)
	{
		if(isDefined(level.flaks))
		{
			for(i = 0; i < level.flaks.size; i++)
			{
				if(extreme\_ex_specials_flak::perkValidateAsTarget(i, level.gmls[index].team))
				{
					if(!isDefined(level.flaks[i].guns.ex_targeted) || (target_time - level.flaks[i].guns.ex_targeted > level.ex_gml_interval))
					{
						target = level.flaks[i].guns;
						target.ex_targeted = gettime() / 1000;
						level.gmls[index].target_type = 32;
						break;
					}
				}
			}
		}
	}

	// gunships
	if(!isDefined(target) && (level.ex_gml_target & 16) == 16)
	{
		if(extreme\_ex_gunship::gunshipValidateAsTarget(level.gmls[index].team))
		{
			if(!isDefined(level.gunship.ex_targeted) || (target_time - level.gunship.ex_targeted > level.ex_gml_interval))
			{
				target = level.gunship;
				target.ex_targeted = gettime() / 1000;
				level.gmls[index].target_type = 16;
			}
		}
		if(!isDefined(target) && extreme\_ex_specials_gunship::perkValidateAsTarget(level.gmls[index].team))
		{
			if(!isDefined(level.gunship_special.ex_targeted) || (target_time - level.gunship_special.ex_targeted > level.ex_gml_interval))
			{
				target = level.gunship_special;
				target.ex_targeted = gettime() / 1000;
				level.gmls[index].target_type = 16;
			}
		}
	}

	// helicopter
	if(!isDefined(target) && (level.ex_gml_target & 8) == 8)
	{
		if(extreme\_ex_specials_helicopter::perkValidateAsTarget(level.gmls[index].team))
		{
			if(!isDefined(level.helicopter.ex_targeted) || (target_time - level.helicopter.ex_targeted > level.ex_gml_interval) )
			{
				target = level.helicopter;
				target.ex_targeted = gettime() / 1000;
				level.gmls[index].target_type = 8; // to handle crash
			}
		}
	}

	// WMD airstrike
	if(!isDefined(target) && (level.ex_gml_target & 4) == 4)
	{
		for(i = 0; i < level.planes.size; i++)
		{
			if(level.planes[i].inuse && level.planes[i].type == 2 && level.planes[i].health > 0 && !level.planes[i].isdroppingpayload && (!level.ex_teamplay || level.planes[i].team != level.gmls[index].team))
			{
				target = level.planes[i].model;
				target.ex_targeted = gettime() / 1000;
				level.gmls[index].target_type = 4; // for increased missile speed and to handle crash
				break;
			}
		}
	}

	// ambient airstrike
	if(!isDefined(target) && (level.ex_gml_target & 2) == 2)
	{
		for(i = 0; i < level.planes.size; i++)
		{
			if(level.planes[i].inuse && level.planes[i].type == 0 && level.planes[i].health > 0 && level.planes[i].team != "neutral" && (!level.ex_teamplay || level.planes[i].team != level.gmls[index].team))
			{
				target = level.planes[i].model;
				target.ex_targeted = gettime() / 1000;
				level.gmls[index].target_type = 2; // for increased missile speed and to handle crash
				break;
			}
		}
	}

	// players
	if(!isDefined(target) && (level.ex_gml_target & 1) == 1)
	{
		if(level.ex_teamplay)
		{
			if(level.gmls[index].team == "allies") players = getTeamPlayers("axis");
				else players = getTeamPlayers("allies");
		}
		else players = getOtherPlayers(level.gmls[index].owner);

		for(j = 0; j < players.size; j++)
		{
			player = players[randomInt(players.size)];
			if(isPlayer(player) && player.sessionstate == "playing")
			{
				if(!isDefined(player.ex_targeted) || (target_time - player.ex_targeted > level.ex_gml_interval) )
				{
					target = player;
					target.ex_targeted = gettime() / 1000;
					level.gmls[index].target_type = 1;
					break;
				}
			}
		}
	}

	return(target);
}

perkGetTunedAngle(center, angles, radius, yaw_step, pitch_step)
{
	//extreme\_ex_debug::debugVec();
	center = center + [[level.ex_vectorscale]](anglesToForward(angles), 30);
	tuned_angle = undefined;

	test_angle = perkTestAngle(center, angles, radius);
	if(isDefined(test_angle))
		tuned_angle = test_angle;
	else
	{
		for(p = abs(angles[0]); p <= 80; p += pitch_step)
		{
			test_angle = perkTestAngle(center, (rev(p), angles[1], angles[2]), radius);
			if(isDefined(test_angle))
			{
				tuned_angle = test_angle;
				break;
			}
			wait( [[level.ex_fpstime]](.05) );
		}

		if(!isDefined(tuned_angle))
		{
			for(p = abs(angles[0]); p >= 0; p -= pitch_step)
			{
				test_angle = perkTestAngle(center, (rev(p), angles[1], angles[2]), radius);
				if(isDefined(test_angle))
				{
					tuned_angle = test_angle;
					break;
				}
				wait( [[level.ex_fpstime]](.05) );
			}
		}
	}

	return(tuned_angle);
}

/*******************************************************************************
POSITIONING
*******************************************************************************/
perkPosition(index, approved_angle)
{
	level.gmls[index].ismoving = true;

	// rotate arms (yaw) to approved angle
	//logprint("DEBUG: comparing angles " + level.gmls[index].arms.angles + " against approved angles " + approved_angle + "\n");
	if(approved_angle[1] != level.gmls[index].arms.angles[1])
	{
		rotate_angle = (level.gmls[index].arms.angles[0], approved_angle[1], level.gmls[index].arms.angles[2]);

		fdot = vectorDot(anglesToForward(level.gmls[index].arms.angles), anglesToForward(rotate_angle));
		if(fdot < -1) fdot = -1;
			else if(fdot > 1) fdot = 1;
		fdiff = abs(acos(fdot)); // difference in degrees

		if(fdiff < 90) level.gmls[index].arms playsound("gml_low_pitch_short");
			else if(fdiff < 180) level.gmls[index].arms playsound("gml_low_pitch_med");
				else level.gmls[index].arms playsound("gml_low_pitch_long");

		rotate_speed = 0.01 + fdiff * 0.025;
		level.gmls[index].arms rotateto(rotate_angle, rotate_speed);
		wait( [[level.ex_fpstime]](rotate_speed + 1) );
	}

	// rotate tubes (pitch) to approved angle
	if(approved_angle[0] != level.gmls[index].tube.angles[0])
	{
		level.gmls[index].tube unlink();
		// tube pitch needs to be normalized after being linked to arms
		level.gmls[index].tube.angles = pitchNormalize(anglesNormalize(level.gmls[index].tube.angles));
		rotate_angle = (approved_angle[0], level.gmls[index].tube.angles[1], level.gmls[index].tube.angles[2]);

		fdiff = dif(level.gmls[index].tube.angles[0], rotate_angle[0]);

		if(fdiff < 45) level.gmls[index].tube playsound("gml_high_pitch_short");
			else level.gmls[index].tube playsound("gml_medium_pitch_long");

		rotate_speed = 0.01 + fdiff * 0.025;
		level.gmls[index].tube rotateto(rotate_angle, rotate_speed);
		wait( [[level.ex_fpstime]](rotate_speed + 1) );
		level.gmls[index].tube linkTo(level.gmls[index].arms, "tag_origin");
	}

	level.gmls[index].ismoving = false;
}

/*******************************************************************************
PERK ACTIONS
*******************************************************************************/
perkActivate(index, force)
{
	if(!level.gmls[index].inuse || (level.gmls[index].activated && !force)) return;

	perkPosition(index, (-45,level.gmls[index].arms.angles[1],level.gmls[index].arms.angles[2]));
	level.gmls[index].nades = 0;

	level.gmls[index].activated = true;
	perkCreateWaypoint(index);
}

perkDeactivate(index, forcebarrelup)
{
	if(!level.gmls[index].inuse || (!level.gmls[index].activated && !forcebarrelup)) return;

	level.gmls[index].activated = false;
	perkCreateWaypoint(index);

	while(level.gmls[index].istargeting) wait( [[level.ex_fpstime]](.05) );

	if(forcebarrelup) perkPosition(index, (-85,level.gmls[index].arms.angles[1],level.gmls[index].arms.angles[2]));
		else perkPosition(index, (85,level.gmls[index].arms.angles[1],level.gmls[index].arms.angles[2]));
}

perkDeactivateTimer(index, timer)
{
	if(!level.gmls[index].inuse || (!level.gmls[index].activated || level.gmls[index].destroyed)) return;

	if(timer && level.gmls[index].timer > timer)
	{
		perkDeactivate(index, false);
		wait( [[level.ex_fpstime]](timer) );
		if(!level.gmls[index].sabotaged && !level.gmls[index].destroyed && level.gmls[index].timer > 5)
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
	if(!level.gmls[index].inuse || level.gmls[index].sabotaged) return;
	level.gmls[index].sabotaged = true; // stops targeting and firing
	perkMalfunction(index);
	if(level.gmls[index].sabotaged) perkDeactivate(index, true);
}

perkRepair(index)
{
	if(!level.gmls[index].inuse || !level.gmls[index].sabotaged) return;
	level.gmls[index].sabotaged = false;
	perkActivate(index, level.gmls[index].activated);
	level.gmls[index].health = level.ex_gml_maxhealth;
}

perkDestroy(index)
{
	if(!level.gmls[index].inuse || level.gmls[index].destroyed) return;
	level.gmls[index].destroyed = true; // kills perkThink(index)
	perkMalfunction(index);
	perkRemove(index);
}

perkMove(index, player)
{
	if(!level.gmls[index].inuse || isDefined(player.gml_moving_timer)) return;
	level.gmls[index].destroyed = true; // kills perkThink(index)
	player.gml_moving_timer = level.gmls[index].timer;
	player.gml_moving_owner = level.gmls[index].owner;
	wait( [[level.ex_fpstime]](.5) );
	perkRemove(index);
	player thread playerGiveBackPerk("gml");
}

perkSteal(index, player)
{
	perkDeleteWaypoint(index);
	level.gmls[index].owner = player;
	if(isAlive(player) && (!level.ex_teamplay || player.pers["team"] != level.gmls[index].team))
		level.gmls[index].team = player.pers["team"];
	level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_OWNERSHIP");

	if(level.gmls[index].sabotaged) perkRepair(index);
		else if(!level.gmls[index].activated) perkActivate(index, false);
			else perkCreateWaypoint(index);
}

perkMalfunction(index)
{
	for(i = 0; i < 20; i++)
	{
		// quit malfunctioning if perk has been removed or repaired
		if(!level.gmls[index].inuse || (!level.gmls[index].sabotaged && !level.gmls[index].destroyed)) break;

		random_time = randomFloatRange(.1, 1);
		playfx(level.ex_effect["gml_sparks"], level.gmls[index].arms.origin);
		wait( [[level.ex_fpstime]](random_time) );
	}
}

/*******************************************************************************
ACTION PANEL
*******************************************************************************/
playerActionPanel(index)
{
	self endon("kill_thread");

	if(isDefined(self.gml_action) || !isAlive(self) || !self isOnGround()) return(false);

	// if this is a deployment call (index -1), first check basic requirements before setting gml_action flag
	candeploy = false;
	if(index == -1)
	{
		if(self.ex_moving || self [[level.ex_getstance]](false) == 2) return(false);
		candeploy = true;
	}

	self.gml_action = true;

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
		if(self == level.gmls[index].owner && (!level.ex_teamplay || self.pers["team"] == level.gmls[index].team))
		{
			canactivate = ((level.ex_gml_owneraction & 1) == 1 && !level.gmls[index].activated && !level.gmls[index].sabotaged && !level.gmls[index].destroyed);
			canadjust = (mayadjust && (level.ex_gml_owneraction & 2) == 2 && level.gmls[index].activated && !level.gmls[index].sabotaged && !level.gmls[index].destroyed);
			canrepair = ((level.ex_gml_owneraction & 4) == 4 && level.gmls[index].sabotaged && !level.gmls[index].destroyed);
			canmove = ((level.ex_gml_owneraction & 8) == 8 && !level.gmls[index].sabotaged && !level.gmls[index].destroyed && !playerPerkIsLocked("gml", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.gml_action = undefined;
				return(false);
			}
		}
		// check teammates actions
		else if(level.ex_teamplay && self.pers["team"] == level.gmls[index].team)
		{
			canactivate = ((level.ex_gml_teamaction & 1) == 1 && !level.gmls[index].activated && !level.gmls[index].sabotaged && !level.gmls[index].destroyed);
			canadjust = (mayadjust && (level.ex_gml_teamaction & 2) == 2 && level.gmls[index].activated && !level.gmls[index].sabotaged && !level.gmls[index].destroyed);
			canrepair = ((level.ex_gml_teamaction & 4) == 4 && level.gmls[index].sabotaged && !level.gmls[index].destroyed);
			canmove = ((level.ex_gml_teamaction & 8) == 8 && !level.gmls[index].sabotaged && !level.gmls[index].destroyed && !playerPerkIsLocked("gml", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.gml_action = undefined;
				return(false);
			}
		}
		// check enemy actions
		else if(!level.ex_teamplay || self.pers["team"] != level.gmls[index].team)
		{
			panel = game["actionpanel_enemy"];
			candeactivate = ((level.ex_gml_enemyaction & 1) == 1 && level.gmls[index].activated && !level.gmls[index].sabotaged && !level.gmls[index].destroyed);
			cansabotage = ((level.ex_gml_enemyaction & 2) == 2 && !level.gmls[index].sabotaged && !level.gmls[index].destroyed);
			candestroy = ((level.ex_gml_enemyaction & 4) == 4 && !level.gmls[index].destroyed);
			cansteal = ((level.ex_gml_enemyaction & 8) == 8 && !level.gmls[index].destroyed);
			if(!candeactivate && !cansabotage && !candestroy && !cansteal)
			{
				self.gml_action = undefined;
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
		playerHudScale(hud_index, level.ex_gml_actiontime * 4, 0, 200, 11);
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
		if(!candeploy && !level.gmls[index].inuse) break;
		if(!candeploy && !perkInRadius(index, self) && !perkCanSee(index, self)) break;

		wait( level.ex_fps_frame );
		progresstime += level.ex_fps_frame;
		if(progresstime >= level.ex_gml_actiontime * actiontimer_autostop) break;
	}

	playerHudDestroy("perk_action_a1");
	playerHudDestroy("perk_action_a2");
	playerHudDestroy("perk_action_a3");
	playerHudDestroy("perk_action_a4");
	playerHudDestroy("perk_action_pb");
	playerHudDestroy("perk_action_bg");

	if(candeploy && progresstime >= level.ex_gml_actiontime) granted = true;
	if(!candeploy && level.gmls[index].inuse)
	{
		// 4th action (8 second boundary by default)
		if(!granted && progresstime >= level.ex_gml_actiontime * 4)
		{
			if(canmove)
			{
				granted = true;
				if(level.ex_gml_messages == 2 && isPlayer(level.gmls[index].owner) && self != level.gmls[index].owner)
					level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_MOVED_BY", [[level.ex_pname]](self));
				level thread perkMove(index, self);
			}
			else if(cansteal)
			{
				granted = true;
				if(level.ex_gml_messages && isPlayer(level.gmls[index].owner) && self != level.gmls[index].owner)
					level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_STOLEN_BY", [[level.ex_pname]](self));
				level thread perkSteal(index, self);
			}
		}

		// 3rd action (6 second boundary by default)
		if(!granted && progresstime >= level.ex_gml_actiontime * 3)
		{
			if(canrepair)
			{
				granted = true;
				if(level.ex_gml_messages == 2 && isPlayer(level.gmls[index].owner) && self != level.gmls[index].owner)
					level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_REPAIRED_BY", [[level.ex_pname]](self));
				level thread perkRepair(index);
			}
			else if(candestroy)
			{
				granted = true;
				if(level.ex_gml_messages && isPlayer(level.gmls[index].owner) && self != level.gmls[index].owner)
					level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_DESTROYED_BY", [[level.ex_pname]](self));
				level thread perkDestroy(index);
			}
		}

		// 2nd action (4 second boundary by default)
		if(!granted && progresstime >= level.ex_gml_actiontime * 2)
		{
			if(canadjust)
			{
				granted = true;
				if(level.ex_gml_messages == 2 && isPlayer(level.gmls[index].owner) && self != level.gmls[index].owner)
					level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_ADJUSTED_BY", [[level.ex_pname]](self));
				level thread perkAdjust(index, self);
			}
			else if(cansabotage)
			{
				granted = true;
				if(level.ex_gml_messages && isPlayer(level.gmls[index].owner) && self != level.gmls[index].owner)
					level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_SABOTAGED_BY", [[level.ex_pname]](self));
				level thread perkSabotage(index);
			}
		}

		// 1st action (2 second boundary by default)
		if(!granted && progresstime >= level.ex_gml_actiontime)
		{
			if(canactivate)
			{
				granted = true;
				if(level.ex_gml_messages == 2 && isPlayer(level.gmls[index].owner) && self != level.gmls[index].owner)
					level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_ACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkActivate(index, false);
			}
			else if(candeactivate)
			{
				granted = true;
				if(level.ex_gml_messages && isPlayer(level.gmls[index].owner) && self != level.gmls[index].owner)
					level.gmls[index].owner iprintlnbold(&"SPECIALS_GML_DEACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkDeactivate(index, false);
			}
		}
	}

	wait( [[level.ex_fpstime]](.2) );
	self.gml_action = undefined;
	if(!granted) return(false);
		else if(!candeploy) while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
	return(true);
}

/*******************************************************************************
MISSILE
*******************************************************************************/
perkFireMissile(index, target, target_type)
{
	self playsound("weap_panzerfaust_fire");

	if(target_type == 2 || target_type == 4) self.speed = 50;
		else self.speed = 30;
	self.finishedrotating = true;

	self.dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
	time = calcTime(self.origin, self.dest, self.speed);
	if(time <= 0)
	{
		self delete();
		return;
	}
	self moveto(self.dest, time, 0.5, 0);
	wait( [[level.ex_fpstime]](.5) ); // no turn for .5 second to let it detach properly

	olddest = (0,0,0);
	totaltime = 0;
	lifespan = 30 * level.ex_fps;
	trace = bulletTrace(self.origin, self.dest, true, self);
	ftime = calcTime(self.origin, trace["position"], self.speed);
	for(t = 0; t < ftime * level.ex_fps; t++)
	{
		wait( [[level.ex_fpstime]](.05) );

		newtrace = bulletTrace(self.origin, self.dest, true, self);
		if(distance(newtrace["position"], trace["position"]) > 1)
		{
			trace = newtrace;
			ftime = calcTime(self.origin, trace["position"], self.speed);
			t = 0;
		}

		// handle fx
		totaltime++;
		if(totaltime % 4 == 0) playfxontag(level.ex_effect["slamraam"], self, "tag_flash");

		// handle flying time
		if(lifespan && totaltime > lifespan) break;

		// check if owner still exist
		if(!isPlayer(level.gmls[index].owner))
		{
			self.dest = self.origin + [[level.ex_vectorscale]](anglestoforward(self.angles), 999999);
			time = calcTime(self.origin, self.dest, self.speed);
			if(time <= 0) break;
			self moveto(self.dest, time, 0, 0);
			continue;
		}

		// check if target still exist
		if(!isDefined(target) || (isPlayer(target) && target.sessionstate != "playing"))
		{
			target = perkGetTarget(index);
			if(!isDefined(target) || (isPlayer(target) && target.sessionstate != "playing"))
			{
				self.dest = self.origin + [[level.ex_vectorscale]](anglestoforward(self.angles), 999999);
				time = calcTime(self.origin, self.dest, self.speed);
				if(time <= 0) break;
				self moveto(self.dest, time, 0, 0);
				continue;
			}
		}

		// change target from gunship to decoy if one is deployed
		if(target_type == 0 || target_type == 16)
		{
			if(isDefined(level.gunship) && target == level.gunship && isDefined(level.ex_gunship_decoy))
			{
				target = level.gunship_decoy;
				target_type = 0;
			}
			else if(isDefined(level.gunship_special) && target == level.gunship_special && isDefined(level.gunship_special_decoy))
			{
				target = level.gunship_special_decoy;
				target_type = 0;
			}
			else target_type = 16;
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

		time = calcTime(self.origin, self.dest, self.speed);
		if(time <= 0) break;
		self moveto(self.dest, time, 0, 0);
	}

	// handle explosion and damage
	self hide();
	playfx(level.ex_effect["artillery"], self.origin);
	ms = randomInt(18) + 1;
	self playsound("mortar_explosion" + ms);

	// using weapon dummy1_mp so we don't have to precache another weapon. We will convert dummy1_mp to gmlmissile_mp for MOD_EXPLOSIVE later on
	if(isPlayer(level.gmls[index].owner) && level.gmls[index].owner.sessionstate != "spectator" && (!level.ex_teamplay || level.gmls[index].owner.pers["team"] == level.gmls[index].team))
		self thread extreme\_ex_utils::scriptedfxradiusdamage(level.gmls[index].owner, undefined, "MOD_EXPLOSIVE", "dummy1_mp", 300, 150, 50, "none", undefined, true, true, true);
	else
		self thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_EXPLOSIVE", "dummy1_mp", 300, 0, 0, "none", undefined, true, true, true);

	if(trace["fraction"] != 1 && isDefined(trace["entity"]))
	{
		if(isDefined(target) && trace["entity"] == target)
		{
			switch(target_type)
			{
				// ambient and WMD planes
				case 2:
				case 4:
					target_index = extreme\_ex_airtrafficcontroller::planeCheckEntity(target);
					if(target_index != -1) level.planes[target_index].health -= 1000;
					break;
				// helicopter and gunships
				case 8:
				case 16:
					target.health -= 500;
					break;
				// flaks
				case 32:
					target_index = extreme\_ex_specials_flak::perkCheckEntity(target);
					if(target_index != -1) level.flaks[target_index].health -= 500;
					break;
				// GMLs
				case 64:
					target_index = extreme\_ex_specials_gml::perkCheckEntity(target);
					if(target_index != -1) level.gmls[target_index].health -= 500;
					break;
			}
		}
	}

	wait( [[level.ex_fpstime]](1) );
	self delete();
}

waitForRotate(time)
{
	self notify("stop_rotate_thread");
	self endon("stop_rotate_thread");

	wait( [[level.ex_fpstime]](time) );
	if(isDefined(self)) self.finishedrotating = true;
}

/*******************************************************************************
WAYPOINT MANAGEMENT
*******************************************************************************/
perkCreateWaypoint(index)
{
	if(level.ex_gml_waypoints)
	{
		if(level.ex_gml_waypoints != 1 || !isPlayer(level.gmls[index].owner)) levelCreateWaypoint(index);
			else level.gmls[index].owner playerCreateWaypoint(index);
	}
}

perkDeleteWaypoint(index)
{
	if(level.ex_gml_waypoints)
	{
		if(level.ex_gml_waypoints != 1 || !isPlayer(level.gmls[index].owner)) levelDeleteWaypoint(index);
			else level.gmls[index].owner playerDeleteWaypoint(index);
	}
}

levelCreateWaypoint(index)
{
	if(!isDefined(level.gmls) || !isDefined(level.gmls[index])) return;

	level levelDeleteWaypoint(index);

	if(level.ex_gml_waypoints == 3 || !isPlayer(level.gmls[index].owner))
	{
		if(level.gmls[index].abandoned) shader = game["waypoint_abandoned"];
		else if(level.gmls[index].activated)
		{
			if(level.gmls[index].team == "axis") shader = game["waypoint_activated_axis"];
				else shader = game["waypoint_activated_allies"];
		}
		else
		{
			if(level.gmls[index].team == "axis") shader = game["waypoint_deactivated_axis"];
				else shader = game["waypoint_deactivated_allies"];
		}

		hud_index = levelHudCreate("waypoint_gml" + index, undefined, level.gmls[index].org_origin[0], level.gmls[index].org_origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}
	else
	{
		if(level.gmls[index].abandoned) shader = game["waypoint_abandoned"];
			else if(level.gmls[index].activated) shader = game["waypoint_activated"];
				else shader = game["waypoint_deactivated"];

		hud_index = levelHudCreate("waypoint_gml" + index, level.gmls[index].team, level.gmls[index].org_origin[0], level.gmls[index].org_origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}

	levelHudSetShader(hud_index, shader, 7, 7);
	levelHudSetWaypoint(hud_index, level.gmls[index].org_origin[2] + 100, true);
	level.gmls[index].waypoint = hud_index;
}

levelDeleteWaypoint(index)
{
	if(!isDefined(level.gmls) || !isDefined(level.gmls[index])) return;
	if(!isDefined(level.gmls[index].waypoint)) return;

	levelHudDestroy(level.gmls[index].waypoint);
	level.gmls[index].waypoint = undefined;
}

playerCreateWaypoint(index)
{
	if(!isDefined(self.gml_waypoints)) self.gml_waypoints = [];

	self playerDeleteWaypoint(index);

	if(level.gmls[index].abandoned) shader = game["waypoint_abandoned"];
		if(level.gmls[index].activated) shader = game["waypoint_activated"];
			else shader = game["waypoint_deactivated"];

	hud_index = playerHudCreate("waypoint_gml" + index, level.gmls[index].org_origin[0], level.gmls[index].org_origin[1], 0.6, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, shader, 7, 7);
	playerHudSetWaypoint(hud_index, level.gmls[index].org_origin[2] + 100, true);

	wp_index = playerAllocateWaypoint();
	self.gml_waypoints[wp_index].id = hud_index;
}

playerAllocateWaypoint()
{
	for(i = 0; i < self.gml_waypoints.size; i++)
	{
		if(self.gml_waypoints[i].inuse == 0)
		{
			self.gml_waypoints[i].inuse = 1;
			return(i);
		}
	}

	self.gml_waypoints[i] = spawnstruct();
	self.gml_waypoints[i].inuse = 1;
	return(i);
}

playerDeleteWaypoint(index)
{
	if(!isDefined(self.gml_waypoints)) return;

	hud_index = playerHudIndex("waypoint_gml" + index);
	if(hud_index == -1) return;

	remove_element = undefined;
	for(i = 0; i < self.gml_waypoints.size; i++)
	{
		if(!self.gml_waypoints[i].inuse) continue;
		if(self.gml_waypoints[i].id != hud_index) continue;
		remove_element = i;
		break;
	}

	if(isDefined(remove_element))
	{
		playerHudDestroy(self.gml_waypoints[remove_element].id);
		self.gml_waypoints[remove_element].inuse = 0;
	}
}

/*******************************************************************************
PROXIMITY CHECK
*******************************************************************************/
checkProximityGMLs(origin, launcher, cpx)
{
	if(level.ex_gml && level.ex_gml_cpx)
	{
		for(index = 0; index < level.gmls.size; index++)
		{
			if(level.gmls[index].inuse && !level.gmls[index].destroyed)
			{
				dist = int( distance(origin, level.gmls[index].arms.origin) );
				if(isDefined(level.gmls[index].owner) && (dist <= cpx))
				{
					level.gmls[index].nades++;
					if(level.gmls[index].nades >= level.ex_gml_cpx_nades)
					{
						if(level.ex_teamplay && isDefined(launcher) && isPlayer(launcher) && launcher.pers["team"] == level.gmls[index].team)
						{
							if((level.ex_gml_cpx & 4) == 4) level thread perkDestroy(index);
							else if((level.ex_gml_cpx & 2) == 2) level thread perkSabotage(index);
							else if((level.ex_gml_cpx & 1) == 1) level thread perkDeactivateTimer(index, level.ex_gml_cpx_timer);
						}
						else
						{
							if((level.ex_gml_cpx & 32) == 32) level thread perkDestroy(index);
							else if((level.ex_gml_cpx & 16) == 16) level thread perkSabotage(index);
							else if((level.ex_gml_cpx & 8) == 8) level thread perkDeactivateTimer(index, level.ex_gml_cpx_timer);
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

getOtherPlayers(owner)
{
	other_players = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
		if(isPlayer(players[i]) && players[i] != owner) other_players[other_players.size] = players[i];

	return(other_players);
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
