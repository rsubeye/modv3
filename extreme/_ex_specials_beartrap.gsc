#include extreme\_ex_specials;
#include extreme\_ex_hudcontroller;

perkInit()
{
	// perk related precaching
	level.beartraps = [];
	[[level.ex_PrecacheModel]]("xmodel/weapon_beartrap_frame");
	[[level.ex_PrecacheModel]]("xmodel/weapon_beartrap_claw");

	if(level.ex_beartrap_warning) [[level.ex_PrecacheShader]]("killiconsuicide");

	level.ex_effect["beartrap_blood"] = [[level.ex_PrecacheEffect]]("fx/impacts/flesh_hit.efx");
}

perkInitPost()
{
	// perk related precaching after map load
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

	if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_BEARTRAP_READY");

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
				if(allowedSurface(self.origin) && getPerkPriority(index))
				{
					if(!extreme\_ex_utils::tooClose(level.ex_mindist["perks"][0], level.ex_mindist["perks"][1], level.ex_mindist["perks"][2], level.ex_mindist["perks"][3])) break;
				}
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

	level.beartraps[index].origin = origin;
	level.beartraps[index].angles = angles;

	level.beartraps[index].trap_frame = spawn("script_model", origin);
	level.beartraps[index].trap_frame setmodel("xmodel/weapon_beartrap_frame");
	level.beartraps[index].trap_frame.angles = angles;

	level.beartraps[index].trap_claw1 = spawn("script_model", origin);
	level.beartraps[index].trap_claw1 hide();
	level.beartraps[index].trap_claw1 setmodel("xmodel/weapon_beartrap_claw");
	level.beartraps[index].trap_claw1.angles = angles;

	level.beartraps[index].trap_claw2 = spawn("script_model", origin);
	level.beartraps[index].trap_claw2 hide();
	level.beartraps[index].trap_claw2 setmodel("xmodel/weapon_beartrap_claw");
	level.beartraps[index].trap_claw2.angles = angles;
	level.beartraps[index].trap_claw2 rotateyaw(180, .05);

	// set owner last so other code knowns it's fully initialized
	level.beartraps[index].ownernum = owner getEntityNumber();
	level.beartraps[index].team = owner.pers["team"];
	level.beartraps[index].timer = level.ex_beartrap_timer * 20;
	level.beartraps[index].hot = false;
	level.beartraps[index].opening = false;
	level.beartraps[index].trapped_player = undefined;
	level.beartraps[index].owner = owner;

	wait( [[level.ex_fpstime]](.1) );

	level.beartraps[index].trap_claw1 show();
	level.beartraps[index].trap_claw2 show();

	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.beartraps.size; i++)
	{
		if(level.beartraps[i].inuse == 0)
		{
			level.beartraps[i].inuse = 1;
			return(i);
		}
	}

	level.beartraps[i] = spawnstruct();
	level.beartraps[i].notification = "trap" + i;
	level.beartraps[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_beartrap && isDefined(level.beartraps))
	{
		for(i = 0; i < level.beartraps.size; i++)
			if(level.beartraps[i].inuse) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.beartraps.size; i++)
		if(level.beartraps[i].inuse && isDefined(level.beartraps[i].owner) && level.beartraps[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	level notify(level.beartraps[index].notification);
	beartrapOpen(index); // this will end the beartrapPlayer thread
	while(level.beartraps[index].opening) wait( [[level.ex_fpstime]](.05) );
	thread levelStopUsingPerk(level.beartraps[index].ownernum, "beartrap");
	perkFree(index);
}

perkFree(index)
{
	level.beartraps[index].trap_frame delete();
	level.beartraps[index].trap_claw1 delete();
	level.beartraps[index].trap_claw2 delete();
	level.beartraps[index].trapped_player = undefined;
	level.beartraps[index].inuse = 0;
}

perkThink(index)
{
	level endon(level.beartraps[index].notification);

	//level thread beartrapDebug(index, 20, (1,0,0));
	beartrapOpen(index);

	for(;;)
	{
		// remove trap if it reached end of life
		if(level.beartraps[index].timer <= 0) break;

		// remove trap if owner left
		if(!isPlayer(level.beartraps[index].owner)) break;

		// remove trap if owner changed team
		if(level.ex_teamplay && level.beartraps[index].owner.pers["team"] != level.beartraps[index].team) break;

		// detect players stepping on the trap, or trying to release teammate
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isDefined(player.pers["team"])) continue;

			if(level.beartraps[index].hot)
			{
				if(isPlayer(player) && !isDefined(player.pers["isbot"]) && !player isOnGround()) continue;

				if(isAlive(player))
				{
					if( (!level.ex_teamplay && player != level.beartraps[index].owner) || (level.ex_teamplay && player.pers["team"] != level.beartraps[index].team) )
					{
						dist = distance(level.beartraps[index].trap_frame.origin, player.origin);
						if(dist < 20)
						{
							beartrapClose(index, player);
							break;
						}
						else if(level.ex_beartrap_warning)
						{
							if(dist < level.ex_beartrap_warning) player thread beartrapWarning(index);
								else player notify("beartrap_danger" + level.beartraps[index].notification);
						}
					}
				}
			}
			else
			{
				if(level.ex_beartrap_warning) player notify("beartrap_danger" + level.beartraps[index].notification);

				if(level.ex_beartrap_untrap)
				{
					if(level.ex_teamplay && isPlayer(player) && player.pers["team"] != level.beartraps[index].team)
					{
						if(isDefined(level.beartraps[index].trapped_player) && level.beartraps[index].trapped_player != player)
						{
							if(isAlive(player) && (distance(level.beartraps[index].trap_frame.origin, player.origin) < 40) && player usebuttonpressed())
							{
								beartrapOpen(index);
								break;
							}
						}
					}
				}
			}
		}

		level.beartraps[index].timer--;
		wait( [[level.ex_fpstime]](.05) );
	}

	thread perkRemove(index);
}

beartrapWarning(index)
{
	self endon("kill_thread");

	name = "beartrap_danger" + level.beartraps[index].notification;
	hud_index = playerHudIndex(name);
	if(hud_index != -1) return;

	// the name of the HUD element must be the same as the notification to destroy it
	self thread beartrapWarningDestroyer(name);

	hud_index = playerHudCreate(name, level.beartraps[index].trap_frame.origin[0], level.beartraps[index].trap_frame.origin[1], 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "killiconsuicide", 7, 7);
	playerHudSetWaypoint(hud_index, level.beartraps[index].trap_frame.origin[2] + 30, true);
}

beartrapWarningDestroyer(notification)
{
	self endon("kill_thread");

	ent = spawnstruct();
	self thread beartrapNotification(notification, true, ent);
	self thread beartrapNotification(notification, false, ent);
	ent waittill("returned");

	ent notify("die");
	self playerHudDestroy(notification);
}

beartrapNotification(notification, islevel, ent)
{
	self endon("kill_thread");
	ent endon("die");

	if(isLevel) level waittill(notification);
		else self waittill(notification);

	ent notify("returned");
}

beartrapOpen(index)
{
	if(level.beartraps[index].hot) return;
	if(level.beartraps[index].opening) return;
	level.beartraps[index].opening = true;

	level.beartraps[index].trap_claw1 rotatepitch(-80, 2);
	level.beartraps[index].trap_claw2 rotatepitch(-80, 2);
	wait( [[level.ex_fpstime]](2) );

	level.beartraps[index].hot = true;
	level.beartraps[index].opening = false;
}

beartrapClose(index, player)
{
	if(!level.beartraps[index].hot) return;
	level.beartraps[index].hot = false;

	level.beartraps[index].trap_frame playsound("beartrap_snap");
	level.beartraps[index].trap_claw1 rotatepitch(80, .05);
	level.beartraps[index].trap_claw2 rotatepitch(80, .05);
	wait( [[level.ex_fpstime]](.1) );

	if(isDefined(player)) thread beartrapPlayer(index, player);
		else thread beartrapIdle(index, 5);
}

beartrapIdle(index, seconds)
{
	wait( [[level.ex_fpstime]](seconds) );
	beartrapOpen(index);
}

beartrapPlayer(index, player)
{
	player setOrigin(level.beartraps[index].trap_frame.origin);
	player freezecontrols(true);
	player extreme\_ex_utils::forceto("crouch");
	playfx(level.ex_effect["beartrap_blood"], player.origin + (0,0,10));

	kill_player = false;
	if(level.ex_beartrap == 3) kill_player = true;
	else
	{
		if(level.ex_beartrap == 2) kill_player = true;

		level.beartraps[index].trapped_player = player;
		player shellshock("medical", level.ex_beartrap_bleedtime);
		player thread extreme\_ex_utils::playSoundLoc("beartrap_yell", player.origin);

		timer = 0;
		while(isAlive(player) && timer < level.ex_beartrap_bleedtime)
		{
			timer++;
			wait( [[level.ex_fpstime]](1) );

			// release player if trap is opened by teammate
			if(level.beartraps[index].opening || level.beartraps[index].hot)
			{
				kill_player = false;
				break;
			}

			//if(timer > 1) player playLocalSound("breathing_hurt");
			if(isPlayer(level.beartraps[index].owner) && isAlive(player) && player.health > 10 && (!level.ex_bleeding || !player.ex_bleeding))
				player thread [[level.callbackPlayerDamage]](level.beartraps[index].owner, level.beartraps[index].owner, 10, 1, "MOD_CRUSH", "dummy1_mp", undefined, (randomFloat(.5),randomFloat(.5),randomFloat(.5)), "right_leg_lower", 0);
		}
	}

	// release controls
	if(isPlayer(player)) player freezecontrols(false);
	level.beartraps[index].trapped_player = undefined;

	// kill the player if we have to
	if(kill_player && isAlive(player) && isPlayer(level.beartraps[index].owner) && level.beartraps[index].owner.sessionstate != "spectator")
		player thread [[level.callbackPlayerDamage]](level.beartraps[index].owner, level.beartraps[index].owner, 1000, 1, "MOD_CRUSH", "dummy1_mp", undefined, (0,0,0), "right_leg_lower", 0);

	beartrapOpen(index);
}

isTrapped(player)
{
	if(level.ex_beartrap)
	{
		for(index = 0; index < level.beartraps.size; index++)
		{
			if(level.beartraps[index].inuse && isDefined(level.beartraps[index].trapped_player))
			{
				if(level.beartraps[index].trapped_player == player) return(true);
			}
		}
	}
	return(false);
}

checkProximityBearTraps(origin, cpx)
{
	if(level.ex_beartrap)
	{
		for(index = 0; index < level.beartraps.size; index++)
		{
			if(level.beartraps[index].inuse && level.beartraps[index].hot)
			{
				dist = int(distance(origin, level.beartraps[index].trap_frame.origin));
				if(dist <= cpx) beartrapClose(index, undefined);
			}
		}
	}
}

allowedSurface(origin)
{
	if(level.ex_beartrap_surfacecheck)
	{
		startOrigin = origin + (0, 0, 100);
		endOrigin = origin + (0, 0, -100);

		trace = bulletTrace(startOrigin, endOrigin, false, self);
		if(trace["fraction"] < 1.0) surface = trace["surfacetype"];
			else surface = "dirt";

		switch(surface)
		{
			case "beach":
			case "dirt":
			case "grass":
			case "ice":
			case "mud":
			case "sand":
			case "snow": return true;
		}

		self iprintln(&"MISC_WRONG_SURFACE");
		return false;
	}

	return true;
}

beartrapDebug(index, range, color)
{
	while(level.beartraps[index].timer > 0)
	{
		start = level.beartraps[index].origin + [[level.ex_vectorscale]](anglestoforward((0,0,0)), range);
		for(i = 10; i < 360; i += 10)
		{
			point = level.beartraps[index].origin + [[level.ex_vectorscale]](anglestoforward((0,i,0)), range);
			line(start, point, color);
			start = point;
		}
		wait(.05);
	}
}
