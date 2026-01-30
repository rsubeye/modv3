#include extreme\_ex_hudcontroller;

init()
{
	[[level.ex_PrecacheShader]]("objpoint_default");

	level.objpoints_allies = spawnstruct();
	level.objpoints_allies.array = [];
	level.objpoints_axis = spawnstruct();
	level.objpoints_axis.array = [];
	level.objpoints_allplayers = spawnstruct();
	level.objpoints_allplayers.array = [];
	level.objpoint_scale = 7;

	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
}

onPlayerConnected()
{
	self.objpoints = [];
}

onPlayerSpawned()
{
	self thread updatePlayerObjpoints();
}

onPlayerKilled()
{
	self thread clearPlayerObjpoints();
}

onJoinedTeam()
{
	self thread clearPlayerObjpoints();
}

onJoinedSpectators()
{
	self thread clearPlayerObjpoints();
}

addObjpoint(origin, name, material)
{
	if(!level.ex_objindicator) return;
	if(!isDefined(name)) return;
	thread addTeamObjpoint(origin, name, "all", material);
}

addTeamObjpoint(origin, name, team, material)
{
	if(!level.ex_objindicator) return;
	if(!isDefined(name)) return;
	if(!isDefined(team) || (team != "allies" && team != "axis" && team != "all")) return;

	if(team == "allies")
	{
		objpoints = level.objpoints_allies;
	}
	else if(team == "axis")
	{
		objpoints = level.objpoints_axis;
	}
	else // "all"
	{
		objpoints = level.objpoints_allplayers;
	}

	cleanpoints = [];
	for(i = 0; i < objpoints.array.size; i++)
	{
		objpoint = objpoints.array[i];
		if(objpoint.name == name)
		{
			if(isDefined(objpoint.hud_index) && objpoint.hud_index != -1)
				levelHudDestroy(objpoint.hud_index);
		}
		else cleanpoints[cleanpoints.size] = objpoint;
	}
	objpoints.array = cleanpoints;

	newpoint = spawnstruct();
	newpoint.name = name;
	newpoint.x = origin[0];
	newpoint.y = origin[1];
	newpoint.z = origin[2];
	newpoint.archived = false;
	if(isDefined(material)) newpoint.material = material;
		else newpoint.material = "objpoint_default";

	objpoints.array[objpoints.array.size] = newpoint;

	if(team == "all")
	{
		hud_index = levelHudCreate(newpoint.name, undefined, newpoint.x, newpoint.y, .61, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, newpoint.archived);
		if(hud_index == -1) return;
		levelHudSetShader(hud_index, newpoint.material, level.objpoint_scale, level.objpoint_scale);
		levelHudSetWaypoint(hud_index, newpoint.z, true);
		newpoint.hud_index = hud_index;
	}
	else
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player)) continue;
			player thread updatePlayerObjpoints();
		}
	}
}

removeObjpoints()
{
	if(!level.ex_objindicator) return;
	thread removeTeamObjpoints("all");
}

removeTeamObjpoints(team)
{
	if(!level.ex_objindicator) return;
	if(!isDefined(team) || (team != "allies" && team != "axis" && team != "all")) return;

	if(team == "allies")
	{
		level.objpoints_allies.array = [];
	}
	else if(team == "axis")
	{
		level.objpoints_axis.array = [];
	}
	else // "all"
	{
		clearGlobalObjpoints();
		return;
	}

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		if(isDefined(player.pers["team"]) && player.pers["team"] == team && player.sessionstate == "playing")
			player clearPlayerObjpoints();
	}
}

changeTeamObjpoints(name, team, material, drawwaypoint)
{
	if(!level.ex_objindicator) return;
	if(!isDefined(team) || (team != "allies" && team != "axis" && team != "all")) return;

	if(team == "allies")
	{
		objpoints = level.objpoints_allies;
	}
	else if(team == "axis")
	{
		objpoints = level.objpoints_axis;
	}
	else // "all"
	{
		objpoints = level.objpoints_allplayers;

		for(i = 0; i < objpoints.array.size; i++)
		{
			objpoint = objpoints.array[i];
			if(objpoint.name == name)
			{
				objpoint.material = material;
				levelHudSetShader(objpoint.hud_index, material, level.objpoint_scale, level.objpoint_scale);
				levelHudSetWaypoint(objpoint.hud_index, objpoint.z, drawwaypoint);
				break;
			}
		}
		return;
	}

	for(i = 0; i < objpoints.array.size; i++)
	{
		objpoint = objpoints.array[i];
		if(objpoint.name == name)
		{
			objpoint.material = material;
			break;
		}
	}

	players = level.players;
	for(i = 0; i < players.size; i ++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		if(isDefined(player.pers["team"]) && player.pers["team"] == team && player.sessionstate == "playing")
		{
			objpoints = player.objpoints;
			for(j = 0; j < objpoints.size; j++)
			{
				objpoint = objpoints[j];
				if(objpoint.name == name)
				{
					player playerHudSetShader(objpoint.hud_index, material, level.objpoint_scale, level.objpoint_scale);
					player playerHudSetWaypoint(objpoint.hud_index, objpoint.z, drawwaypoint);
					break;
				}
			}
		}
	}
}

updatePlayerObjpoints()
{
	self endon("disconnect");

	if(!level.ex_objindicator) return;

	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator" && self.sessionstate == "playing")
	{
		if(self.pers["team"] == "allies")
		{
			objpoints = level.objpoints_allies;
		}
		else if(self.pers["team"] == "axis")
		{
			objpoints = level.objpoints_axis;
		}
		else return
		
		self clearPlayerObjpoints();
		
		for(i = 0; i < objpoints.array.size; i++)
		{
			objpoint = objpoints.array[i];
			
			hud_index = playerHudCreate(objpoint.name, objpoint.x, objpoint.y, .61, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, objpoint.archived);
			if(hud_index == -1) return;
			playerHudSetShader(hud_index, objpoint.material, level.objpoint_scale, level.objpoint_scale);
			playerHudSetWaypoint(hud_index, objpoint.z, true);

			newobjpoint = spawnstruct();
			newobjpoint.name = objpoint.name;
			newobjpoint.x = objpoint.x;
			newobjpoint.y = objpoint.y;
			newobjpoint.z = objpoint.z;
			newobjpoint.archived = objpoint.archived;
			newobjpoint.hud_index = hud_index;

			self.objpoints[self.objpoints.size] = newobjpoint;
		}
	}
}

clearPlayerObjpoints()
{
	self endon("disconnect");

	for(i = 0; i < self.objpoints.size; i++)
	{
		objpoint = self.objpoints[i];
		if(isDefined(objpoint.hud_index) && objpoint.hud_index != -1)
			playerHudDestroy(objpoint.hud_index);
	}
	
	self.objpoints = [];
}

clearGlobalObjpoints()
{
	for(i = 0; i < level.objpoints_allplayers.array.size; i++)
	{
		objpoint = level.objpoints_allplayers.array[i];
		if(isDefined(objpoint.hud_index) && objpoint.hud_index != -1)
			levelHudDestroy(objpoint.hud_index);
	}

	level.objpoints_allplayers.array = [];
}
