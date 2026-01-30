#include extreme\_ex_specials;
#include extreme\_ex_hudcontroller;

perkInit()
{
	// perk related precaching

	// create perk array
	level.uavs = [];

	// precache shaders
	[[level.ex_PrecacheShader]]("compass_dot");

	// precache models
	if(level.ex_uav_model && !level.ex_uav_private)
	{
		level.ex_effect["uav_rotor"] = [[level.ex_PrecacheEffect]]("fx/rotor/rotor045_spin.efx");
		[[level.ex_PrecacheModel]]("xmodel/vehicle_uav");
	}

	level.ex_uavX = 55;
	level.ex_uavY = -59;
	level.ex_uavUnit = 0.0226875;
	level.ex_uavHudScale = level.ex_uav_range * level.ex_uavUnit;
}

perkInitPost()
{
	// perk related precaching after map load
}

perkCheck()
{
	// checks before being able to buy this perk
	if(!level.ex_uav_private)
	{
		// special override to avoid script var overflow
		if(level.players.size > 32) return(false);
		if(perkCheckTeam(self)) return(false);
	}
	else
	{
		// special override to avoid script var overflow
		if(getTotalActive("uav") > 8) return(false);
		if(perkCheckFrom(self)) return(false);
	}
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
		else self iprintlnbold(&"SPECIALS_UAV_READY");

	self thread hudNotifySpecial(index, 5);
	self thread playerStartUsingPerk(index, true);

	level thread perkCreate(self);
}

/*******************************************************************************
PERK CREATION AND REMOVAL
*******************************************************************************/
perkCreate(owner)
{
	index = perkAllocate();
	level.uavs[index].timer = level.ex_uav_timer;
	level.uavs[index].owner = owner;
	level.uavs[index].ownernum = owner getEntityNumber();
	level.uavs[index].team = owner.pers["team"];

	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.uavs.size; i++)
	{
		if(level.uavs[i].inuse == 0)
		{
			level.uavs[i].inuse = 1;
			return(i);
		}
	}

	level.uavs[i] = spawnstruct();
	level.uavs[i].notification = "uav" + i;
	level.uavs[i].inuse = 1;
	level.uavs[i].owner = undefined;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_uav && isDefined(level.uavs))
	{
		for(i = 0; i < level.uavs.size; i++)
			if(level.uavs[i].inuse) thread perkRemove(i);
	}
}

perkRemove(index)
{
	if(!level.uavs[index].inuse) return;
	level notify(level.uavs[index].notification);

	if(!level.ex_uav_private)
	{
		for(i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			if(!isPlayer(player) || !isDefined(player.pers["team"])) continue;
			if(player.pers["team"] == level.uavs[index].team && player.sessionstate == "playing") player thread perkHudRemove(index);
		}

		if(level.ex_uav_model)
		{
			level.uavs[index].model.exiting = true;
			level.uavs[index].model waittill("uav_rotorstop");
			level.uavs[index].model delete();
		}
	}
	else if(isPlayer(level.uavs[index].owner)) level.uavs[index].owner thread perkHudRemove(index);

	thread levelStopUsingPerk(level.uavs[index].ownernum, "uav");
	perkFree(index);
}

perkFree(index)
{
	level.uavs[index].inuse = 0;
	level.uavs[index].owner = undefined;
	level.uavs[index].friendlies = undefined;
}

perkCheckFrom(player)
{
	if(level.ex_uav && isDefined(level.uavs))
	{
		for(i = 0; i < level.uavs.size; i++)
			if(level.uavs[i].inuse && isDefined(level.uavs[i].owner) && level.uavs[i].owner == player) return(true);
	}
	return(false);
}

perkCheckTeam(player)
{
	if(level.ex_uav && isDefined(level.uavs))
	{
		for(i = 0; i < level.uavs.size; i++)
			if(level.uavs[i].inuse && isDefined(level.uavs[i].team) && level.uavs[i].team == player.pers["team"]) return(true);
	}
	return(false);
}

perkCheckEntity(entity)
{
	if(level.ex_uav && level.ex_uav_model && isDefined(level.uavs))
	{
		if(level.uavs["allies"].model == entity || level.uavs["axis"].model == entity) return(true);
	}

	return(-1);
}

/*******************************************************************************
PERK MAIN LOGIC
*******************************************************************************/
perkThink(index)
{
	if(level.ex_uav_model && !level.ex_uav_private)
	{
		if(level.uavs[index].team == "axis") uav_tag = "tag_90";
			else uav_tag = "tag_270";

		level.uavs[index].model = spawn("script_model", (0,0,0));
		level.uavs[index].model hide();
		level.uavs[index].model.exiting = false; // to end blades fx when exiting
		level.uavs[index].model setmodel("xmodel/vehicle_uav");
		level.uavs[index].model linkTo(level.rotation_rig, uav_tag, (level.rotation_rig.maxradius,0,0), (0,90,-20));
		level.uavs[index].model thread rotateTailRotor(1);
		level.uavs[index].model show();
	}

	level thread perkLevelController(index);

	for(;;)
	{
		// remove perk if it reached end of life
		if(level.uavs[index].timer <= 0) break;

		// remove private UAV if player left
		if(level.ex_uav_private && !isPlayer(level.uavs[index].owner)) break;

		// remove private UAV in team based GT if owner switches teams
		if(level.ex_teamplay && level.ex_uav_private && level.uavs[index].owner.pers["team"] != level.uavs[index].team) break;

		// start UAV HUD (and restart for respawning players)
		if(!level.ex_uav_private)
		{
			for(i = 0; i < level.players.size; i++)
			{
				player = level.players[i];
				if(!isPlayer(player) || !isDefined(player.pers["team"])) continue;
				if(player.pers["team"] != level.uavs[index].team || player.sessionstate != "playing") continue;
				if(!isDefined(player.ex_radarindex)) player thread perkPlayerController(index);
			}
		}
		else if(isPlayer(level.uavs[index].owner) && level.uavs[index].owner.sessionstate == "playing")
		{
			if(!isDefined(level.uavs[index].owner.ex_radarindex)) level.uavs[index].owner thread perkPlayerController(index);
		}

		wait( [[level.ex_fpstime]](1) );
		level.uavs[index].timer--;
	}

	level thread perkRemove(index);
}

rotateTailRotor(time)
{
	while(!self.exiting)
	{
		playfxontag(level.ex_effect["uav_rotor"], self, "tag_blades");
		wait( [[level.ex_fpstime]](time) );
	}

	wait( [[level.ex_fpstime]](.1) );
	self notify("uav_rotorstop");
}

perkLevelController(index)
{
	level endon("ex_gameover");
	level endon(level.uavs[index].notification);

	level.uavs[index].friendlies = [];

	while(true)
	{
		wait( [[level.ex_fpstime]](1) );

		friendlies = [];
		if(level.ex_uav_private) friendlies[0] = level.uavs[index].owner;
			else friendlies = getTeamPlayers(index, false);

		enemies = [];
		enemies = getTeamPlayers(index, true);

		for(f = 0; f < friendlies.size; f++)
		{
			wait(.05);

			friendly = friendlies[f];
			if(!isPlayer(friendly) || !isDefined(friendly.ex_radarindex) || friendly.sessionstate != "playing") continue;

			if(friendly.ex_radarindex == -1)
			{
				friendlyindex = level.uavs[index].friendlies.size;
				level.uavs[index].friendlies[friendlyindex] = [];
				friendly notify("uav_init_" + level.uavs[index].team, friendlyindex);
			}
			else friendlyindex = friendly.ex_radarindex;

			for(e = 0; e < enemies.size; e++)
			{
				enemy = enemies[e];
				if(!isPlayer(enemy)) continue;

				enemyindex = -1;
				for(i = 0; i < level.uavs[index].friendlies[friendlyindex].size; i++)
				{
					enemyrec = level.uavs[index].friendlies[friendlyindex][i];
					if(isDefined(enemyrec.entity) && enemyrec.entity == enemy)
					{
						enemyindex = i;
						break;
					}
				}

				dist = int(distance( (friendly.origin[0], friendly.origin[1], 0), (enemy.origin[0], enemy.origin[1], 0) ));
				if(dist <= level.ex_uav_range)
				{
					if(enemyindex == -1)
					{
						enemyindex = level.uavs[index].friendlies[friendlyindex].size;
						level.uavs[index].friendlies[friendlyindex][enemyindex] = spawnstruct();
						level.uavs[index].friendlies[friendlyindex][enemyindex].entity = enemy;
						level.uavs[index].friendlies[friendlyindex][enemyindex].entityno = enemy getEntityNumber(); // for hud naming
						level.uavs[index].friendlies[friendlyindex][enemyindex].hud_index = -1;
					}

					level.uavs[index].friendlies[friendlyindex][enemyindex].dist = dist;
				}
				else if(enemyindex != -1) level.uavs[index].friendlies[friendlyindex][enemyindex].dist = dist;
			}

			// sort the enemy players array on distance if necessary
			if(level.uavs[index].friendlies[friendlyindex].size > level.ex_uav_maxenemy)
			{
				level.uavs[index].friendlies[friendlyindex] = quickSort(level.uavs[index].friendlies[friendlyindex], 0, level.uavs[index].friendlies[friendlyindex].size - 1);
			}

			friendly notify("uav_update_" + level.uavs[index].team);
		}
	}
}

perkPlayerController(index)
{
	level endon(level.uavs[index].notification);
	self endon("disconnect");

	// set to -1 to prevent perkThink from calling perkPlayerController again
	self.ex_radarindex = -1;

	// wait for perklevelController to send array index
	self waittill("uav_init_" + level.uavs[index].team, myindex);
	self.ex_radarindex = myindex;

	// wait for perkLevelController to signal update
	while(true)
	{
		self waittill("uav_update_" + level.uavs[index].team);

		for(i = 0; i < level.uavs[index].friendlies[myindex].size; i++)
		{
			if(self.sessionstate != "playing") break;

			enemyrec = level.uavs[index].friendlies[myindex][i];
			if(i < level.ex_uav_maxenemy && isPlayer(enemyrec.entity) && isAlive(enemyrec.entity) && enemyrec.dist <= level.ex_uav_range)
			{
				// create or update enemy dot
				if(enemyrec.hud_index == -1)
				{
					hud_index = playerHudCreate("uavdot" + enemyrec.entityno, 320, 240, 1, (1,0,0), 1, -1, "left", "bottom", "center", "middle", true, true);
					if(hud_index == -1) continue;
					enemyrec.hud_index = hud_index;
					playerHudSetShader(hud_index, "compass_dot", 8, 8);
				}
				else hud_index = enemyrec.hud_index;

				forward = anglesToForward(self getPlayerAngles());
				forward = vectorNormalize( (forward[0], forward[1], 0) );
				dotx = vectorDot( (forward[1], -1 * forward[0], 0), enemyrec.entity.origin - self.origin) / level.ex_uavHudScale;
				doty = vectorDot(forward, enemyrec.entity.origin - self.origin) / level.ex_uavHudScale;
				playerHudSetAlpha(hud_index, 1);
				playerHudSetXYZ(hud_index, level.ex_uavX + dotx, level.ex_uavY - doty, undefined);
				if(level.ex_currentgt == "ft")
				{
					if(enemyrec.entity.frozenstate == "frozen") playerHudSetColor(hud_index, (0,0,1));
						else playerHudSetColor(hud_index, (1,0,0));
				}
				playerHudFade(hud_index, 3, 0, 0);
			}
			else if(enemyrec.hud_index != -1)
			{
				// remove enemy dot
				playerHudDestroy(enemyrec.hud_index);
				enemyrec.hud_index = -1;
			}
		}
	}
}

perkHudRemove(index)
{
	self endon("disconnect");

	if(!isDefined(self.ex_radarindex)) return;

	if(self.ex_radarindex != -1)
	{
		for(i = 0; i < level.uavs[index].friendlies[self.ex_radarindex].size; i++)
		{
			enemyrec = level.uavs[index].friendlies[self.ex_radarindex][i];
			if(isDefined(enemyrec.hud_index) && enemyrec.hud_index != -1)
			{
				playerHudDestroy(enemyrec.hud_index);
				enemyrec.hud_index = -1;
			}
		}
	}

	self.ex_radarindex = undefined;
}

getTeamPlayers(index, enemy)
{
	teamplayers = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionstate == "spectator") continue;

		if(!enemy)
		{
			if(level.ex_uav_private && player == level.uavs[index].owner)
			{
				teamplayers[teamplayers.size] = player;
				break;
			}
			else if(player.pers["team"] == level.uavs[index].team) teamplayers[teamplayers.size] = player;
		}
		else
		{
			if(level.ex_uav_private && player != level.uavs[index].owner) teamplayers[teamplayers.size] = player;
				else if(player.pers["team"] != level.uavs[index].team) teamplayers[teamplayers.size] = player;
		}
	}

	return teamplayers;
}

quickSort(array, first, last)
{
	if(first >= last || array.size < 2) return(array);

	pivot_index = int((first + last) / 2);
	pivot = array[pivot_index];
	t = array[pivot_index];
	array[pivot_index] = array[last];
	array[last] = t;

	pivot_index = first;
	for(i = first; i < last; i++)
	{
		if(array[i].dist <= pivot.dist)
		{
			t = array[i];
			array[i] = array[pivot_index];
			array[pivot_index] = t;
			pivot_index++;
		}
	}

	t = array[pivot_index];
	array[pivot_index] = array[last];
	array[last] = t;

	array = quickSort(array, first, pivot_index - 1);
	array = quickSort(array, pivot_index + 1, last);
	return(array);
}
