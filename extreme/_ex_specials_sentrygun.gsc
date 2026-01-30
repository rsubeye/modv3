#include extreme\_ex_specials;
#include extreme\_ex_hudcontroller;

perkInit()
{
	// perk related precaching
	level.sentryguns = [];
	[[level.ex_PrecacheModel]]("xmodel/weapon_sentry_4pod");
	[[level.ex_PrecacheModel]]("xmodel/weapon_sentry_gun");

	game["actionpanel_owner"] = "spc_actionpanel_owner";
	[[level.ex_PrecacheShader]](game["actionpanel_owner"]);
	game["actionpanel_enemy"] = "spc_actionpanel_enemy";
	[[level.ex_PrecacheShader]](game["actionpanel_enemy"]);
	game["actionpanel_denied"] = "spc_actionpanel_denied";
	[[level.ex_PrecacheShader]](game["actionpanel_denied"]);

	game["waypoint_abandoned"] = "spc_waypoint_abandoned";
	[[level.ex_PrecacheShader]](game["waypoint_abandoned"]);

	if(level.ex_sentrygun_waypoints != 3)
	{
		game["waypoint_activated"] = "spc_waypoint_activated";
		[[level.ex_PrecacheShader]](game["waypoint_activated"]);
		game["waypoint_deactivated"] = "spc_waypoint_deactivated";
		[[level.ex_PrecacheShader]](game["waypoint_deactivated"]);
	}

	// varcache still holds some shader precache code in postmapload_precacheshaders()

	level.ex_effect["sentrygun_shot"] = [[level.ex_PrecacheEffect]]("fx/muzzleflashes/mg42hv.efx");
	level.ex_effect["sentrygun_eject"] = [[level.ex_PrecacheEffect]]("fx/shellejects/rifle.efx");
	level.ex_effect["sentrygun_sparks"] = [[level.ex_PrecacheEffect]]("fx/props/radio_sparks_smoke.efx");
}

perkInitPost()
{
	// perk related precaching after map load
	if(level.ex_sentrygun_waypoints == 3)
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

	if(!isDefined(self.sentrygun_moving_timer))
	{
		if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"SPECIALS_SENTRY_READY");
	}
	self playlocalsound("sentrygun_readyfor");

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
				if(getPerkPriority(index))
				{
					if(!extreme\_ex_utils::tooClose(level.ex_mindist["perks"][0], level.ex_mindist["perks"][1], level.ex_mindist["perks"][2], level.ex_mindist["perks"][3]))
					{
						if(perkClearance(self.origin, 40, 1, 30) && self playerActionPanel(-1)) break;
					}
				}
				while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
		}
	}

	self thread playerStartUsingPerk(index, true);
	self thread hudNotifySpecialRemove(index);

	self playlocalsound("sentrygun_ontheway");
	level thread perkCreate(self);

	if(level.ex_sentrygun_messages)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(player == self || !isDefined(player.pers["team"])) continue;
			else if(player.pers["team"] == self.pers["team"])
			{
				player playlocalsound("sentrygun_deployed");
				player iprintlnbold(&"SPECIALS_SENTRY_DEPLOYED_TEAM", [[level.ex_pname]](self));
			}
			else
			{
				player playlocalsound("sentrygun_enemyincoming");
				player iprintlnbold(&"SPECIALS_SENTRY_DEPLOYED_ENEMY", [[level.ex_pname]](self));
			}
		}
	}
}

/*******************************************************************************
VALIDATION
*******************************************************************************/
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
	if(isDefined(level.sentryguns))
	{
		for(i = 0; i < level.sentryguns.size; i++)
			if(level.sentryguns[i].inuse && isDefined(level.sentryguns[i].owner) && (level.sentryguns[i].sentry_base == entity || level.sentryguns[i].sentry_gun == entity) ) return(i);
	}

	return(-1);
}

perkValidateAsTarget(index, team)
{
	if(!level.sentryguns[index].inuse || !level.sentryguns[index].activated || level.sentryguns[index].sabotaged || level.sentryguns[index].destroyed) return(false);
	if(level.sentryguns[index].health <= 0 || (level.ex_teamplay && level.sentryguns[index].team == team)) return(false);
	if(!isDefined(level.sentryguns[index].owner) || !isPlayer(level.sentryguns[index].owner)) return(false);
	return(true);
}

/*******************************************************************************
PERK CREATION AND REMOVAL
*******************************************************************************/
perkCreate(owner)
{
	index = perkAllocate();
	angles = (0, owner.angles[1], 0);
	origin = owner.origin;

	level.sentryguns[index].health = level.ex_sentrygun_maxhealth;
	level.sentryguns[index].timer = level.ex_sentrygun_timer * 5;
	level.sentryguns[index].nades = 0;

	level.sentryguns[index].ismoving = false;
	level.sentryguns[index].firing = false;
	level.sentryguns[index].rotating = 2;
	level.sentryguns[index].targeting = false;
	level.sentryguns[index].barrelno = 0;

	level.sentryguns[index].activated = false;
	level.sentryguns[index].destroyed = false;
	level.sentryguns[index].sabotaged = false;
	level.sentryguns[index].abandoned = false;

	level.sentryguns[index].org_origin = origin;
	level.sentryguns[index].org_angles = angles;
	level.sentryguns[index].org_owner = owner;
	level.sentryguns[index].org_ownernum = owner getEntityNumber();

	// create models
	level.sentryguns[index].sentry_base = spawn("script_model", origin);
	level.sentryguns[index].sentry_base hide();
	level.sentryguns[index].sentry_base setmodel("xmodel/weapon_sentry_4pod");
	level.sentryguns[index].sentry_base.angles = angles;

	level.sentryguns[index].sentry_gun = spawn("script_model", origin + (0, 0, 39));
	level.sentryguns[index].sentry_gun hide();
	level.sentryguns[index].sentry_gun setmodel("xmodel/weapon_sentry_gun");
	level.sentryguns[index].sentry_gun.angles = angles + (75, 0, 0);

	level.sentryguns[index].sentry_sensor = spawn("script_origin", (0,0,0));
	level.sentryguns[index].sentry_sensor linkTo(level.sentryguns[index].sentry_gun, "tag_sensor", (0,0,0), (0,0,0));

	level.sentryguns[index].block_trig = spawn("trigger_radius", origin + (0, 0, 20), 0, 30, 30);

	// set owner after creating entities so proximity code can handle it
	level.sentryguns[index].owner = owner;
	level.sentryguns[index].team = owner.pers["team"];

	// wait for player to clear perk location
	while(positionWouldTelefrag(level.sentryguns[index].sentry_base.origin)) wait( [[level.ex_fpstime]](.05) );
	wait( [[level.ex_fpstime]](1) ); // to let player get out of trigger zone

	// show models
	level.sentryguns[index].sentry_base show();
	level.sentryguns[index].sentry_gun show();
	level.sentryguns[index].block_trig setcontents(1);

	// restore timer and owner after moving perk
	if(isDefined(owner.sentrygun_moving_timer))
	{
		level.sentryguns[index].timer = owner.sentrygun_moving_timer;
		owner.sentrygun_moving_timer = undefined;

		if(isDefined(owner.sentrygun_moving_owner) && isPlayer(owner.sentrygun_moving_owner) && owner.pers["team"] == owner.sentrygun_moving_owner.pers["team"])
			level.sentryguns[index].owner = owner.sentrygun_moving_owner;
		owner.sentrygun_moving_owner = undefined;
	}

	perkActivate(index, false);
	if(isPlayer(owner)) owner playlocalsound("sentrygun_ready");
	level thread perkThink(index);
	//level thread sentryDeveloper(index);
}

perkAllocate()
{
	for(i = 0; i < level.sentryguns.size; i++)
	{
		if(level.sentryguns[i].inuse == 0)
		{
			level.sentryguns[i].inuse = 1;
			return(i);
		}
	}

	level.sentryguns[i] = spawnstruct();
	level.sentryguns[i].notification = "sentrygun" + i;
	level.sentryguns[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_sentrygun && isDefined(level.sentryguns))
	{
		for(i = 0; i < level.sentryguns.size; i++)
			if(level.sentryguns[i].inuse && !level.sentryguns[i].destroyed) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.sentryguns.size; i++)
		if(level.sentryguns[i].inuse && isDefined(level.sentryguns[i].owner) && level.sentryguns[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	if(!level.sentryguns[index].inuse) return;
	level notify(level.sentryguns[index].notification);
	level.sentryguns[index].destroyed = true; // kills perkThink(index)
	perkDeactivate(index, false);
	wait( [[level.ex_fpstime]](2) );
	perkDeleteWaypoint(index);
	perkFree(index);
}

perkFree(index)
{
	thread levelStopUsingPerk(level.sentryguns[index].org_ownernum, "sentrygun");
	level.sentryguns[index].owner = undefined;
	if(isDefined(level.sentryguns[index].block_trig)) level.sentryguns[index].block_trig delete();
	if(isDefined(level.sentryguns[index].sentry_sensor)) level.sentryguns[index].sentry_sensor delete();
	if(isDefined(level.sentryguns[index].sentry_gun)) level.sentryguns[index].sentry_gun delete();
	if(isDefined(level.sentryguns[index].sentry_base)) level.sentryguns[index].sentry_base delete();
	level.sentryguns[index].inuse = 0;
}

/*******************************************************************************
PERK MAIN LOGIC
*******************************************************************************/
perkThink(index)
{
	limit = sin(level.ex_sentrygun_reach) - 0.0001;
	target = level.sentryguns[index].sentry_gun;

	for(;;)
	{
		target_old = target;
		target = level.sentryguns[index].sentry_gun;

		// signaled to destroy by proximity checks, or when being moved
		if(level.sentryguns[index].destroyed) return;

		// remove perk if it reached end of life
		if(level.sentryguns[index].timer <= 0)
		{
			if(isPlayer(level.sentryguns[index].owner)) level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_REMOVED");
			level thread perkRemove(index);
			return;
		}

		// check if owner left the game or switched teams
		if(!level.sentryguns[index].abandoned)
		{
			// owner left
			if(!isPlayer(level.sentryguns[index].owner))
			{
				if((level.ex_sentrygun_remove & 1) == 1)
				{
					level thread perkRemove(index);
					return;
				}
				level.sentryguns[index].abandoned = true;
				level.sentryguns[index].owner = level.sentryguns[index].sentry_gun;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
			// owner switched teams
			else if((level.ex_sentrygun_remove & 2) != 2 && level.sentryguns[index].owner.pers["team"] != level.sentryguns[index].team)
			{
				level.sentryguns[index].abandoned = true;
				perkDeleteWaypoint(index);
				level.sentryguns[index].owner = level.sentryguns[index].sentry_gun;
				perkDeactivate(index, false);
				perkCreateWaypoint(index);
			}
		}

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(isAlive(player))
			{
				// check for actions. removed for now: perkCanSee(index, self)
				if(level.sentryguns[index].inuse && player meleebuttonpressed() && perkInRadius(index, player)) player thread playerActionPanel(index);

				// check for targets if activated and not sabotaged
				if( (!level.ex_teamplay && player != level.sentryguns[index].owner) || (level.ex_teamplay && player.pers["team"] != level.sentryguns[index].team) )
				{
					if(level.sentryguns[index].activated && !level.sentryguns[index].sabotaged)
					{
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
							if(closer(level.sentryguns[index].sentry_base.origin, player.origin, target.origin)) target = player;
						}
					}
				}
			}
		}

		// if still active and not sabotaged, show some action
		if(level.sentryguns[index].activated && !level.sentryguns[index].sabotaged)
		{
			if(isPlayer(target))
			{
				level.sentryguns[index].rotating = 0;
				va = vectorToAngles(target.origin + (0, 0, 40) - level.sentryguns[index].sentry_gun.origin);

				if(target == target_old && !level.sentryguns[index].targeting) level.sentryguns[index].sentry_gun rotateTo(va, .2);
					else thread perkTargeting(index, va, .5);

				wait( [[level.ex_fpstime]](.05) );

				if(!level.sentryguns[index].targeting)
				{
					thread perkFiring(index);

					// using weapon dummy1_mp so we don't have to precache another weapon. We will convert dummy1_mp to sentrygun_mp for MOD_PROJECTILE later on
					if(isPlayer(level.sentryguns[index].owner) && (!level.ex_teamplay || level.sentryguns[index].owner.pers["team"] == level.sentryguns[index].team))
						target thread [[level.callbackPlayerDamage]](level.sentryguns[index].sentry_gun, level.sentryguns[index].owner, level.ex_sentrygun_damage, 1, "MOD_PROJECTILE", "dummy1_mp", target.origin + (0,0,40), anglesToForward(va), "none", 0);
					else
						target thread [[level.callbackPlayerDamage]](level.sentryguns[index].sentry_gun, level.sentryguns[index].sentry_gun, level.ex_sentrygun_damage, 1, "MOD_PROJECTILE", "dummy1_mp", target.origin + (0,0,40), anglesToForward(va), "none", 0);
				}
			}
			else
			{
				if(level.sentryguns[index].rotating == 2) // start the rotation of the barrel if no target has been found yet (activation and angle reset)
				{
					level.sentryguns[index].rotating = 1;
					level.sentryguns[index].sentry_gun playsound("sentrygun_servo_medium");
					level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles + (0, level.ex_sentrygun_reach, 0), 1); // to left
				}
				else if(level.sentryguns[index].rotating == 0) // resetting (after shooting a target and no next target)
				{
					level.sentryguns[index].rotating = 1;
					while(level.sentryguns[index].firing) wait( [[level.ex_fpstime]](.05) );
					dot = vectorDot(anglesToRight(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
					level.sentryguns[index].sentry_gun playsound("sentrygun_servo_medium");
					if(dot < 0) level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles + (0, level.ex_sentrygun_reach, 0), .5); // to left
						else level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles - (0, level.ex_sentrygun_reach, 0), .5); // to right
					wait( [[level.ex_fpstime]](.3) );
				}
				else
				{
					dot = vectorDot(anglesToForward(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
					if(dot < 0) // when resetting the angle of the perk than 90 degrees
					{
						level.sentryguns[index].rotating = 0;
						level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles, .2);
					}
					else
					{
						dot = vectorDot(anglesToRight(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
						if(dot < 0 - limit) // to right (hitting left limit)
						{
							level.sentryguns[index].rotating = -1;
							level.sentryguns[index].sentry_gun playsound("sentrygun_servo_long");
							level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles - (0, level.ex_sentrygun_reach, 0), 2);
						}
						else if(dot > limit) // to left (hitting right limit)
						{
							level.sentryguns[index].rotating = 1;
							level.sentryguns[index].sentry_gun playsound("sentrygun_servo_long");
							level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles + (0, level.ex_sentrygun_reach, 0), 2);
						}
					}
				}
			}
		}

		level.sentryguns[index].timer--;
		wait( [[level.ex_fpstime]](.2) );
	}
}

perkInRadius(index, player)
{
	if(distance(player.origin, level.sentryguns[index].sentry_gun.origin) < level.ex_sentrygun_actionradius) return(true);
	return(false);
}

perkInSight(index, player)
{
	dir = vectorNormalize(player.origin + (0, 0, 40) - level.sentryguns[index].sentry_gun.origin);

	// check if player is within the limits of perk movement
	dot = vectorDot(anglesToForward(level.sentryguns[index].org_angles), dir);
	if(dot > 1) dot = 1;
	viewangle = acos(dot);
	if(viewangle > level.ex_sentrygun_reach) return(false);

	// check if player is in line of sight
	dot = vectorDot(anglesToForward(level.sentryguns[index].sentry_gun.angles), dir);
	if(dot > 1) dot = 1;
	viewangle = acos(dot);
	if(viewangle > level.ex_sentrygun_viewangle) return(false);
	return(true);
}

perkCanSee(index, player)
{
	cansee = false;
 	if(distance(player.origin, level.sentryguns[index].sentry_base.origin) <= level.ex_sentrygun_fireradius)
 	{
		cansee = (bullettrace(level.sentryguns[index].sentry_sensor.origin, player.origin + (0, 0, 10), false, level.sentryguns[index].block_trig)["fraction"] == 1);
		if(!cansee) cansee = (bullettrace(level.sentryguns[index].sentry_sensor.origin, player.origin + (0, 0, 40), false, level.sentryguns[index].block_trig)["fraction"] == 1);
		if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.sentryguns[index].sentry_sensor.origin + (0, 0, 10), player.ex_eyemarker.origin, false, level.sentryguns[index].block_trig)["fraction"] == 1);
	}
	return(cansee);
}

perkTargeting(index, vector, duration)
{
	if(level.sentryguns[index].targeting) return;
	level.sentryguns[index].targeting = true;
	if(randomInt(2)) level.sentryguns[index].sentry_gun playsound("sentrygun_servo_short");
		else level.sentryguns[index].sentry_gun playsound("sentrygun_servo_medium");
	level.sentryguns[index].sentry_gun rotateTo(vector, duration);
	wait( [[level.ex_fpstime]](duration) );
	level.sentryguns[index].targeting = false;
}

perkFiring(index)
{
	if(level.sentryguns[index].firing) return;
	level.sentryguns[index].firing = true;
	level.sentryguns[index].sentry_gun playsound("sentrygun_fire");

	firingtime = 1.3;
	for(i = 0; i < firingtime; i += .1)
	{
		playfxontag(level.ex_effect["sentrygun_shot"], level.sentryguns[index].sentry_gun, "tag_flash_" + level.sentryguns[index].barrelno);
		level.sentryguns[index].barrelno++;
		if(level.sentryguns[index].barrelno == 5) level.sentryguns[index].barrelno = 0;
		playfxontag(level.ex_effect["sentrygun_eject"], level.sentryguns[index].sentry_gun, "tag_eject");
		wait( [[level.ex_fpstime]](.1) );
	}

	level.sentryguns[index].firing = false;
}

perkOwnership(index, player)
{
	if(!isPlayer(level.sentryguns[index].owner))
	{
		perkDeleteWaypoint(index);
		level.sentryguns[index].owner = player;
		level.sentryguns[index].abandoned = false;
		perkCreateWaypoint(index);

		if(!level.ex_teamplay || player.pers["team"] != level.sentryguns[index].team) level.sentryguns[index].team = player.pers["team"];
		level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_OWNERSHIP_ABANDONED");
	}
}

/*******************************************************************************
PERK ACTIONS
*******************************************************************************/
perkActivate(index, force)
{
	if(!level.sentryguns[index].inuse || (level.sentryguns[index].activated && !force)) return;

	level.sentryguns[index].nades = 0;
	level.sentryguns[index].rotating = 2;
	level.sentryguns[index].sentry_gun playsound("sentrygun_windup");
	level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles, 2);
	wait( [[level.ex_fpstime]](2) );

	level.sentryguns[index].activated = true;
	perkCreateWaypoint(index);
}

perkDeactivate(index, forcebarrelup)
{
	if(!level.sentryguns[index].inuse || (!level.sentryguns[index].activated && !forcebarrelup)) return;

	level.sentryguns[index].activated = false;
	perkCreateWaypoint(index);

	level.sentryguns[index].sentry_gun playsound("sentrygun_winddown");
	if(forcebarrelup) level.sentryguns[index].sentry_gun rotateTo((-75, level.sentryguns[index].sentry_gun.angles[1], 0), 2);
		else level.sentryguns[index].sentry_gun rotateTo((75, level.sentryguns[index].sentry_gun.angles[1], 0), 2);
	level.sentryguns[index].sentry_gun playsound("sentrygun_servo_long");
	wait( [[level.ex_fpstime]](2) );
}

perkDeactivateTimer(index, timer)
{
	if(!level.sentryguns[index].inuse || (!level.sentryguns[index].activated || level.sentryguns[index].destroyed)) return;

	if(timer && level.sentryguns[index].timer > timer)
	{
		perkDeactivate(index, false);
		wait( [[level.ex_fpstime]](timer) );
		if(!level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed && level.sentryguns[index].timer > 5)
			perkActivate(index, false);
	}
	else level thread perkDeactivate(index, false);
}

perkAdjust(index, player)
{
	level.sentryguns[index].org_angles = (0, player.angles[1], 0);
	level.sentryguns[index].rotating = 2;
	wait( [[level.ex_fpstime]](2) );
}

perkSabotage(index)
{
	if(!level.sentryguns[index].inuse || level.sentryguns[index].sabotaged) return;
	level.sentryguns[index].sabotaged = true; // stops targeting and firing
	perkMalfunction(index);
	if(level.sentryguns[index].sabotaged) perkDeactivate(index, true);
}

perkRepair(index)
{
	if(!level.sentryguns[index].inuse || !level.sentryguns[index].sabotaged) return;
	level.sentryguns[index].sabotaged = false;
	perkActivate(index, level.sentryguns[index].activated);
	level.sentryguns[index].health = level.ex_sentryguns_maxhealth;
}

perkDestroy(index)
{
	if(!level.sentryguns[index].inuse || level.sentryguns[index].destroyed) return;
	level.sentryguns[index].destroyed = true; // kills perkThink(index)
	if(isPlayer(level.sentryguns[index].owner)) level.sentryguns[index].owner playlocalsound("sentrygun_destroyed");
	perkMalfunction(index);
	perkRemove(index);
}

perkMove(index, player)
{
	if(!level.sentryguns[index].inuse || isDefined(player.sentrygun_moving_timer)) return;
	level.sentryguns[index].destroyed = true; // kills perkThink(index)
	player.sentrygun_moving_timer = level.sentryguns[index].timer;
	player.sentrygun_moving_owner = level.sentryguns[index].owner;
	wait( [[level.ex_fpstime]](.5) );
	perkRemove(index);
	player thread playerGiveBackPerk("sentrygun");
}

perkSteal(index, player)
{
	perkDeleteWaypoint(index);
	level.sentryguns[index].owner = player;
	if(isAlive(player) && (!level.ex_teamplay || player.pers["team"] != level.sentryguns[index].team))
		level.sentryguns[index].team = player.pers["team"];
	level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_OWNERSHIP");

	if(level.sentryguns[index].sabotaged) perkRepair(index);
		else if(!level.sentryguns[index].activated) perkActivate(index, false);
			else perkCreateWaypoint(index);
}

perkMalfunction(index)
{
	for(i = 0; i < 20; i++)
	{
		// quit malfunctioning if perk has been removed or repaired
		if(!level.sentryguns[index].inuse || (!level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed)) break;

		random_time = randomFloatRange(.5, 1);
		// do not want two malfunctions to run at once when perkSabotage(index) is called from checkProximitySentryGuns()
		if(level.sentryguns[index].activated)
		{
			random_pitch = randomIntRange(-20, 20);
			random_yaw = randomIntRange(0 - level.ex_sentrygun_reach, level.ex_sentrygun_reach);
			random_time = randomFloatRange(.1, 1);
			level.sentryguns[index].sentry_gun playsound("sentrygun_servo_short");
			level.sentryguns[index].sentry_gun rotateTo(level.sentryguns[index].org_angles + (random_pitch, random_yaw, 0), random_time);
		}
		playfx(level.ex_effect["sentrygun_sparks"], level.sentryguns[index].sentry_gun.origin);
		wait( [[level.ex_fpstime]](random_time) );
	}
}

/*******************************************************************************
ACTION PANEL
*******************************************************************************/
playerActionPanel(index)
{
	self endon("kill_thread");

	if(isDefined(self.sentrygun_action) || !isAlive(self) || !self isOnGround()) return(false);

	// if this is a deployment call (index -1), first check basic requirements before setting sentrygun_action flag
	candeploy = false;
	if(index == -1)
	{
		if(self.ex_moving || self [[level.ex_getstance]](false) == 2) return(false);
		candeploy = true;
	}

	self.sentrygun_action = true;

	// set mayadjust to false if this perk has no adjust capabilities
	mayadjust = true;

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
		if(self == level.sentryguns[index].owner && (!level.ex_teamplay || self.pers["team"] == level.sentryguns[index].team))
		{
			canactivate = ((level.ex_sentrygun_owneraction & 1) == 1 && !level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canadjust = (mayadjust && (level.ex_sentrygun_owneraction & 2) == 2 && level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canrepair = ((level.ex_sentrygun_owneraction & 4) == 4 && level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canmove = ((level.ex_sentrygun_owneraction & 8) == 8 && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed && !playerPerkIsLocked("sentrygun", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.sentrygun_action = undefined;
				return(false);
			}
		}
		// check teammates actions
		else if(level.ex_teamplay && self.pers["team"] == level.sentryguns[index].team)
		{
			canactivate = ((level.ex_sentrygun_teamaction & 1) == 1 && !level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canadjust = (mayadjust && (level.ex_sentrygun_teamaction & 2) == 2 && level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canrepair = ((level.ex_sentrygun_teamaction & 4) == 4 && level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			canmove = ((level.ex_sentrygun_teamaction & 8) == 8 && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed && !playerPerkIsLocked("sentrygun", false));
			if(!canactivate && !canadjust && !canrepair && !canmove)
			{
				self.sentrygun_action = undefined;
				return(false);
			}
		}
		// check enemy actions
		else if(!level.ex_teamplay || self.pers["team"] != level.sentryguns[index].team)
		{
			panel = game["actionpanel_enemy"];
			candeactivate = ((level.ex_sentrygun_enemyaction & 1) == 1 && level.sentryguns[index].activated && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			cansabotage = ((level.ex_sentrygun_enemyaction & 2) == 2 && !level.sentryguns[index].sabotaged && !level.sentryguns[index].destroyed);
			candestroy = ((level.ex_sentrygun_enemyaction & 4) == 4 && !level.sentryguns[index].destroyed);
			cansteal = ((level.ex_sentrygun_enemyaction & 8) == 8 && !level.sentryguns[index].destroyed);
			if(!candeactivate && !cansabotage && !candestroy && !cansteal)
			{
				self.sentrygun_action = undefined;
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
		playerHudScale(hud_index, level.ex_sentrygun_actiontime * 4, 0, 200, 11);
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
		if(!candeploy && !level.sentryguns[index].inuse) break;
		if(!candeploy && !perkCanSee(index, self) && !perkInRadius(index, self)) break;

		wait( level.ex_fps_frame );
		progresstime += level.ex_fps_frame;
		if(progresstime >= level.ex_sentrygun_actiontime * actiontimer_autostop) break;
	}

	playerHudDestroy("perk_action_a1");
	playerHudDestroy("perk_action_a2");
	playerHudDestroy("perk_action_a3");
	playerHudDestroy("perk_action_a4");
	playerHudDestroy("perk_action_pb");
	playerHudDestroy("perk_action_bg");

	if(candeploy && progresstime >= level.ex_sentrygun_actiontime) granted = true;
	if(!candeploy && level.sentryguns[index].inuse)
	{
		// 4th action (8 second boundary by default)
		if(!granted && progresstime >= level.ex_sentrygun_actiontime * 4)
		{
			if(canmove)
			{
				granted = true;
				if(level.ex_sentrygun_messages == 2 && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_MOVED_BY", [[level.ex_pname]](self));
				level thread perkMove(index, self);
			}
			else if(cansteal)
			{
				granted = true;
				if(level.ex_sentrygun_messages && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_STOLEN_BY", [[level.ex_pname]](self));
				level thread perkSteal(index, self);
			}
		}

		// 3rd action (6 second boundary by default)
		if(!granted && progresstime >= level.ex_sentrygun_actiontime * 3)
		{
			if(canrepair)
			{
				granted = true;
				if(level.ex_sentrygun_messages == 2 && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_REPAIRED_BY", [[level.ex_pname]](self));
				level thread perkRepair(index);
			}
			else if(candestroy)
			{
				granted = true;
				if(level.ex_sentrygun_messages && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_DESTROYED_BY", [[level.ex_pname]](self));
				level thread perkDestroy(index);
			}
		}

		// 2nd action (4 second boundary by default)
		if(!granted && progresstime >= level.ex_sentrygun_actiontime * 2)
		{
			if(canadjust)
			{
				granted = true;
				if(level.ex_sentrygun_messages == 2 && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_ADJUSTED_BY", [[level.ex_pname]](self));
				level thread perkAdjust(index, self);
			}
			else if(cansabotage)
			{
				granted = true;
				if(level.ex_sentrygun_messages && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_SABOTAGED_BY", [[level.ex_pname]](self));
				level thread perkSabotage(index);
			}
		}

		// 1st action (2 second boundary by default)
		if(!granted && progresstime >= level.ex_sentrygun_actiontime)
		{
			if(canactivate)
			{
				granted = true;
				if(level.ex_sentrygun_messages == 2 && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_ACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkActivate(index, false);
			}
			else if(candeactivate)
			{
				granted = true;
				if(level.ex_sentrygun_messages && isPlayer(level.sentryguns[index].owner) && self != level.sentryguns[index].owner)
					level.sentryguns[index].owner iprintlnbold(&"SPECIALS_SENTRY_DEACTIVATED_BY", [[level.ex_pname]](self));
				level thread perkDeactivate(index, false);
			}
		}
	}

	wait( [[level.ex_fpstime]](.2) );
	self.sentrygun_action = undefined;
	if(!granted) return(false);
		else if(!candeploy) while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
	return(true);
}

/*******************************************************************************
WAYPOINT MANAGEMENT
*******************************************************************************/
perkCreateWaypoint(index)
{
	if(level.ex_sentrygun_waypoints)
	{
		if(level.ex_sentrygun_waypoints != 1 || !isPlayer(level.sentryguns[index].owner)) levelCreateWaypoint(index);
			else level.sentryguns[index].owner playerCreateWaypoint(index);
	}
}

perkDeleteWaypoint(index)
{
	if(level.ex_sentrygun_waypoints)
	{
		if(level.ex_sentrygun_waypoints != 1 || !isPlayer(level.sentryguns[index].owner)) levelDeleteWaypoint(index);
			else level.sentryguns[index].owner playerDeleteWaypoint(index);
	}
}

levelCreateWaypoint(index)
{
	if(!isDefined(level.sentryguns) || !isDefined(level.sentryguns[index])) return;

	level levelDeleteWaypoint(index);

	if(level.ex_sentrygun_waypoints == 3 || !isPlayer(level.sentryguns[index].owner))
	{
		if(level.sentryguns[index].abandoned) shader = game["waypoint_abandoned"];
		else if(level.sentryguns[index].activated)
		{
			if(level.sentryguns[index].team == "axis") shader = game["waypoint_activated_axis"];
				else shader = game["waypoint_activated_allies"];
		}
		else
		{
			if(level.sentryguns[index].team == "axis") shader = game["waypoint_deactivated_axis"];
				else shader = game["waypoint_deactivated_allies"];
		}

		hud_index = levelHudCreate("waypoint_sentry" + index, undefined, level.sentryguns[index].org_origin[0], level.sentryguns[index].org_origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}
	else
	{
		if(level.sentryguns[index].abandoned) shader = game["waypoint_abandoned"];
			else if(level.sentryguns[index].activated) shader = game["waypoint_activated"];
				else shader = game["waypoint_deactivated"];

		hud_index = levelHudCreate("waypoint_sentry" + index, level.sentryguns[index].team, level.sentryguns[index].org_origin[0], level.sentryguns[index].org_origin[1], .6, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index == -1) return;
	}

	levelHudSetShader(hud_index, shader, 7, 7);
	levelHudSetWaypoint(hud_index, level.sentryguns[index].org_origin[2] + 100, true);
	level.sentryguns[index].waypoint = hud_index;
}

levelDeleteWaypoint(index)
{
	if(!isDefined(level.sentryguns) || !isDefined(level.sentryguns[index])) return;
	if(!isDefined(level.sentryguns[index].waypoint)) return;

	levelHudDestroy(level.sentryguns[index].waypoint);
	level.sentryguns[index].waypoint = undefined;
}

playerCreateWaypoint(index)
{
	if(!isDefined(self.sentry_waypoints)) self.sentry_waypoints = [];

	self playerDeleteWaypoint(index);

	if(level.sentryguns[index].abandoned) shader = game["waypoint_abandoned"];
		if(level.sentryguns[index].activated) shader = game["waypoint_activated"];
			else shader = game["waypoint_deactivated"];

	hud_index = playerHudCreate("waypoint_sentry" + index, level.sentryguns[index].org_origin[0], level.sentryguns[index].org_origin[1], 0.6, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, shader, 7, 7);
	playerHudSetWaypoint(hud_index, level.sentryguns[index].org_origin[2] + 100, true);

	wp_index = playerAllocateWaypoint();
	self.sentry_waypoints[wp_index].id = hud_index;
}

playerAllocateWaypoint()
{
	for(i = 0; i < self.sentry_waypoints.size; i++)
	{
		if(self.sentry_waypoints[i].inuse == 0)
		{
			self.sentry_waypoints[i].inuse = 1;
			return(i);
		}
	}

	self.sentry_waypoints[i] = spawnstruct();
	self.sentry_waypoints[i].inuse = 1;
	return(i);
}

playerDeleteWaypoint(index)
{
	if(!isDefined(self.sentry_waypoints)) return;

	hud_index = playerHudIndex("waypoint_sentry" + index);
	if(hud_index == -1) return;

	remove_element = undefined;
	for(i = 0; i < self.sentry_waypoints.size; i++)
	{
		if(!self.sentry_waypoints[i].inuse) continue;
		if(self.sentry_waypoints[i].id != hud_index) continue;
		remove_element = i;
		break;
	}

	if(isDefined(remove_element))
	{
		playerHudDestroy(self.sentry_waypoints[remove_element].id);
		self.sentry_waypoints[remove_element].inuse = 0;
	}
}

/*******************************************************************************
PROXIMITY CHECK
*******************************************************************************/
checkProximitySentryGuns(origin, launcher, cpx)
{
	if(level.ex_sentrygun && level.ex_sentrygun_cpx)
	{
		for(index = 0; index < level.sentryguns.size; index++)
		{
			if(level.sentryguns[index].inuse && !level.sentryguns[index].destroyed)
			{
				dist = int( distance(origin, level.sentryguns[index].sentry_gun.origin) );
				if(isDefined(level.sentryguns[index].owner) && (dist <= cpx))
				{
					level.sentryguns[index].nades++;
					if(level.sentryguns[index].nades >= level.ex_sentrygun_cpx_nades)
					{
						if(level.ex_teamplay && isDefined(launcher) && isPlayer(launcher) && launcher.pers["team"] == level.sentryguns[index].team)
						{
							if((level.ex_sentrygun_cpx & 4) == 4) level thread perkDestroy(index);
							else if((level.ex_sentrygun_cpx & 2) == 2) level thread perkSabotage(index);
							else if((level.ex_sentrygun_cpx & 1) == 1) level thread perkDeactivateTimer(index, level.ex_sentrygun_cpx_timer);
						}
						else
						{
							if((level.ex_sentrygun_cpx & 32) == 32) level thread perkDestroy(index);
							else if((level.ex_sentrygun_cpx & 16) == 16) level thread perkSabotage(index);
							else if((level.ex_sentrygun_cpx & 8) == 8) level thread perkDeactivateTimer(index, level.ex_sentrygun_cpx_timer);
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
sentryDebug(index)
{
	dot1 = vectorDot(anglesToForward(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
	dot2 = vectorDot(anglesToRight(level.sentryguns[index].org_angles), anglesToForward(level.sentryguns[index].sentry_gun.angles));
	slimit = sin(level.ex_sentrygun_reach);
	climit = cos(level.ex_sentrygun_reach);

	logprint("dot1 = " + dot1 + ", angles = " + level.sentryguns[index].sentry_gun.angles + "\n");
	logprint("dot2 = " + dot2 + ", slimit = " + slimit + ", climit = " + climit + "\n");
}

sentryDeveloper(index)
{
	while(level.sentryguns[index].activated)
	{
		angle = (level.sentryguns[index].org_angles[0], level.sentryguns[index].org_angles[1] + level.ex_sentrygun_reach, 0);
		endpoint = level.sentryguns[index].sentry_gun.origin + [[level.ex_vectorscale]](anglesToForward(angle), 64);
		line(level.sentryguns[index].sentry_gun.origin, endpoint, (0, .8, .8), false);

		angle = (level.sentryguns[index].org_angles[0], level.sentryguns[index].org_angles[1] - level.ex_sentrygun_reach, 0);
		endpoint = level.sentryguns[index].sentry_gun.origin + [[level.ex_vectorscale]](anglesToForward(angle), 64);
		line(level.sentryguns[index].sentry_gun.origin, endpoint, (0, .8, .8), false);

		angle = (level.sentryguns[index].sentry_gun.angles[0], level.sentryguns[index].sentry_gun.angles[1] + level.ex_sentrygun_viewangle, 0);
		endpoint = level.sentryguns[index].sentry_gun.origin + [[level.ex_vectorscale]](anglesToForward(angle), 64);
		line(level.sentryguns[index].sentry_gun.origin, endpoint, (1, 0, 0), false);

		angle = (level.sentryguns[index].sentry_gun.angles[0], level.sentryguns[index].sentry_gun.angles[1] - level.ex_sentrygun_viewangle, 0);
		endpoint = level.sentryguns[index].sentry_gun.origin + [[level.ex_vectorscale]](anglesToForward(angle), 64);
		line(level.sentryguns[index].sentry_gun.origin, endpoint, (1, 0, 0), false);

		wait( [[level.ex_fpstime]](.05) );
	}
}
