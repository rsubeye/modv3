#include extreme\_ex_hudcontroller;

init()
{
	if(!level.ex_deathicons) return;

	[[level.ex_PrecacheShader]]("headicon_dead");

	level.deathicons["allies"] = spawnstruct();
	level.deathicons["allies"].array = [];
	level.deathicons["axis"] = spawnstruct();
	level.deathicons["axis"].array = [];
	level.deathicons["spectator"] = spawnstruct();
	level.deathicons["spectator"].array = [];

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onPlayerDisconnected", ::onPlayerDisconnected);
}

onPlayerSpawned()
{
	removeDeathIcon(self.clientid);
}

onPlayerDisconnected()
{
	removeDeathIcon(self.clientid);
}

addDeathIcon(entity, id, team, timeout)
{
	// if killed on parachute or entities monitor in defcon 2, remove cloned body
	// and do not display death icon
	if(isDefined(self.ex_isparachuting) || level.ex_entities_defcon == 2)
	{
		wait( [[level.ex_fpstime]](2) );
		if(isDefined(entity)) entity delete();
		return;
	}

	if(level.ex_deadbodyfx)	entity extreme\_ex_main::HandleDeadBody(team, self);

	if(!level.ex_deathicons) return;

	assert(team == "allies" || team == "axis");

	hud_index = levelHudCreate("deathicon_team_" + id, team, entity.origin[0], entity.origin[1], 0.61, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetID(hud_index, id);
	levelHudSetShader(hud_index, "headicon_dead", 7, 7);
	levelHudSetWaypoint(hud_index, entity.origin[2] + 54, true);
	level.deathicons[team].array[level.deathicons[team].array.size] = hud_index;

	hud_index = levelHudCreate("deathicon_spec_" + id, "spectator", entity.origin[0], entity.origin[1], 0.61, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	levelHudSetID(hud_index, id);
	levelHudSetShader(hud_index, "headicon_dead", 7, 7);
	levelHudSetWaypoint(hud_index, entity.origin[2] + 54, true);
	level.deathicons["spectator"].array[level.deathicons["spectator"].array.size] = hud_index;

	if(isDefined(timeout))
	{
		wait( [[level.ex_fpstime]](timeout) );
		removeDeathIcon(id);
	}
}

removeDeathIcon(id)
{
	for(i = 0; i < 3; i++)
	{
		if(i == 0)
			team = "allies";
		else if(i == 1)
			team = "axis";
		else
			team = "spectator";

		removeElement = undefined;

		for(j = 0; j < level.deathicons[team].array.size; j++)
		{
			if(levelHudGetID(level.deathicons[team].array[j]) != id) continue;

			removeElement = level.deathicons[team].array[j];
			break;
		}
		
		if(isDefined(removeElement))
		{
			lastElement = level.deathicons[team].array.size - 1;

			for(j = 0; j < level.deathicons[team].array.size; j++)
			{
				if(level.deathicons[team].array[j] != removeElement) continue;

				level.deathicons[team].array[j] = level.deathicons[team].array[lastElement];
				level.deathicons[team].array[lastElement] = undefined;
				break;
			}

			levelHudDestroy(removeElement);
		}
	}
}
