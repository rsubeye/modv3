#include extreme\_ex_specials;

perkInit()
{
	// perk related precaching
	level.insertions = [];

	if(level.ex_insertion_fx) level.ex_effect["insertion_marker"] = [[level.ex_PrecacheEffect]]("fx/misc/insertion_marker.efx");
}

perkInitPost()
{
	// perk related precaching after map load
}

perkCheck()
{
	// checks before being able to buy this perk
	insertion_info = insertionGetFrom(self);
	if(insertion_info["exists"]) return(false);
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
		else self iprintlnbold(&"SPECIALS_INSERTION_READY");

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
					if(!extreme\_ex_utils::tooClose(level.ex_mindist["perks"][0], level.ex_mindist["perks"][1], level.ex_mindist["perks"][2], level.ex_mindist["perks"][3])) break;
				}
				while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
		}
	}

	self thread playerStartUsingPerk(index, false);
	self thread hudNotifySpecialRemove(index);

	angles = (0, self.angles[1], 0);
	origin = self.origin;

	level thread perkCreate(self, origin, angles);
}

perkCreate(owner, origin, angles)
{
	index = perkAllocate();

	level.insertions[index].origin = origin;
	level.insertions[index].angles = angles;

	// set owner last so other code knowns it's fully initialized
	level.insertions[index].ownernum = owner getEntityNumber();
	level.insertions[index].team = owner.pers["team"];
	level.insertions[index].timer = level.ex_insertion_timer * 20;
	level.insertions[index].owner = owner;

	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.insertions.size; i++)
	{
		if(level.insertions[i].inuse == 0)
		{
			level.insertions[i].inuse = 1;
			return(i);
		}
	}

	level.insertions[i] = spawnstruct();
	level.insertions[i].notification = "insertion" + i;
	level.insertions[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_insertion && isDefined(level.insertions))
	{
		for(i = 0; i < level.insertions.size; i++)
			if(level.insertions[i].inuse) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.insertions.size; i++)
		if(level.insertions[i].inuse && isDefined(level.insertions[i].owner) && level.insertions[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	level notify(level.insertions[index].notification);
	wait( [[level.ex_fpstime]](.1) );
	thread levelStopUsingPerk(level.insertions[index].ownernum, "insertion", true);
	perkFree(index);
}

perkFree(index)
{
	level.insertions[index].inuse = 0;
}

perkThink(index)
{
	level endon(level.insertions[index].notification);

	for(;;)
	{
		// remove insertion if it reached end of life
		if(level.insertions[index].timer <= 0) break;

		// remove insertion if owner left
		if(!isPlayer(level.insertions[index].owner)) break;

		// remove insertion if owner changed team
		if(level.ex_teamplay && level.insertions[index].owner.pers["team"] != level.insertions[index].team) break;

		if(level.ex_insertion_fx && level.insertions[index].timer % 20 == 0) playfx(level.ex_effect["insertion_marker"], level.insertions[index].origin);

		level.insertions[index].timer--;
		wait( [[level.ex_fpstime]](.05) );
	}

	thread perkRemove(index);
}

insertionGetFrom(player)
{
	insertion_info["exists"] = false;

	if(isDefined(level.insertions))
	{
		for(i = 0; i < level.insertions.size; i++)
		{
			if(level.insertions[i].inuse && isDefined(level.insertions[i].owner) && level.insertions[i].owner == player)
			{
				insertion_info["exists"] = true;
				insertion_info["origin"] = level.insertions[i].origin;
				insertion_info["angles"] = level.insertions[i].angles;
				break;
			}
		}
	}

	return(insertion_info);
}
