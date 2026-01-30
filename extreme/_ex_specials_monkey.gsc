#include extreme\_ex_specials;

perkInit()
{
	// perk related precaching

	// create perk array
	level.monkeys = [];

	// precache models
	[[level.ex_PrecacheModel]]("xmodel/monkey_bomb_main");
	[[level.ex_PrecacheModel]]("xmodel/monkey_bomb_leftarm");
	[[level.ex_PrecacheModel]]("xmodel/monkey_bomb_rightarm");

	// precache effects
	// Monkey perk is using "plane_bomb" effect, which is precached by default
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

	if(!playerPerkIsLocked("monkey", true)) self thread perkAssign(index, 0);
}

perkAssign(index, delay)
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](delay) );

	if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_MONKEY_READY");

	self thread hudNotifySpecial(index);
	self playLocalSound("monkey_evil");

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

	level.monkeys[index].origin = origin;
	level.monkeys[index].angles = angles;

	level.monkeys[index].terminated = false;
	level.monkeys[index].destroyed = false;

	// create models
	level.monkeys[index].body = spawn("script_model", origin);
	level.monkeys[index].body setmodel("xmodel/monkey_bomb_main");
	level.monkeys[index].body.angles = angles;

	level.monkeys[index].leftarm = spawn("script_model", origin);
	level.monkeys[index].leftarm setmodel("xmodel/monkey_bomb_leftarm");
	level.monkeys[index].leftarm.angles = angles;
	level.monkeys[index].leftarm linkTo(level.monkeys[index].body, "tag_armleft", (0,0,0), (0,0,0));

	level.monkeys[index].rightarm = spawn("script_model", origin);
	level.monkeys[index].rightarm setmodel("xmodel/monkey_bomb_rightarm");
	level.monkeys[index].rightarm.angles = angles;
	level.monkeys[index].rightarm linkTo(level.monkeys[index].body, "tag_armright", (0,0,0), (0,0,0));

	// must have a small wait here to update origin and angles
	wait( [[level.ex_fpstime]](.05) );
	level.monkeys[index].leftarm unlink();
	level.monkeys[index].rightarm unlink();

	// set owner last so other code knowns it's fully initialized
	level.monkeys[index].timer = level.ex_monkey_timer * 4;
	level.monkeys[index].clap = 1;
	level.monkeys[index].team = owner.pers["team"];
	level.monkeys[index].ownernum = owner getEntityNumber();
	level.monkeys[index].owner = owner;

	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.monkeys.size; i++)
	{
		if(level.monkeys[i].inuse == 0)
		{
			level.monkeys[i].inuse = 1;
			return(i);
		}
	}

	level.monkeys[i] = spawnstruct();
	level.monkeys[i].notification = "monkey" + i;
	level.monkeys[i].inuse = 1;
	return(i);
}

perkRemoveAll()
{
	if(level.ex_monkey && isDefined(level.monkeys))
	{
		for(i = 0; i < level.monkeys.size; i++)
			if(level.monkeys[i].inuse) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.monkeys.size; i++)
		if(level.monkeys[i].inuse && isDefined(level.monkeys[i].owner) && level.monkeys[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	level notify(level.monkeys[index].notification);
	level.monkeys[index].rightarm delete();
	level.monkeys[index].leftarm delete();
	level.monkeys[index].body delete();
	perkFree(index);
}

perkFree(index)
{
	thread levelStopUsingPerk(level.monkeys[index].ownernum, "monkey");
	level.monkeys[index].inuse = 0;
}

perkThink(index)
{
	level endon(level.monkeys[index].notification);

	level.monkeys[index].body playsound("monkey_song");
	wait( [[level.ex_fpstime]](6) );
	level thread monkeyClap(index);

	for(;;)
	{
		// signaled to destroy by proximity checks
		if(level.monkeys[index].destroyed) break;

		// remove perk if it reached end of life
		if(level.monkeys[index].timer <= 0) break;

		// remove perk if owner left
		if(!isPlayer(level.monkeys[index].owner))
		{
			level.monkeys[index].terminated = true;
			break;
		}

		// remove perk if owner changed team
		if(level.ex_teamplay && level.monkeys[index].owner.pers["team"] != level.monkeys[index].team)
		{
			level.monkeys[index].terminated = true;
			break;
		}

		// check for enemies close by
		clap = 0;
		dist_closest = 9999;
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isDefined(player.pers["team"])) continue;

			if(isAlive(player))
			{
				if( (!level.ex_teamplay && player != level.monkeys[index].owner) || (level.ex_teamplay && player.pers["team"] != level.monkeys[index].team) )
				{
					if(perkCanSee(index, player))
					{
						dist = distance(level.monkeys[index].body.origin, player.origin);
						if(dist < 500 && dist < dist_closest) dist_closest = dist;
					}
				}
			}
		}

		if(dist_closest != 9999)
		{
			clap = int(dist_closest / 50) * .1;
			if(!clap) clap = .05;
		}
		level.monkeys[index].clap = clap;
		if(dist_closest < 100) break;

		level.monkeys[index].timer--;
		wait( [[level.ex_fpstime]](.25) );
	}

	if(!level.monkeys[index].terminated)
	{
		level.monkeys[index].body playsound("monkey_ratchet");
		wait( [[level.ex_fpstime]](1) );
		playfx(level.ex_effect["plane_bomb"], level.monkeys[index].body.origin);
		level.monkeys[index].body playSound("grenade_explode_default");
		if(isPlayer(level.monkeys[index].owner)) level.monkeys[index].owner thread delayedSound(1, "monkey_laugh");

		// using weapon dummy1_mp so we don't have to precache another weapon. We will convert dummy1_mp to monkey_mp for MOD_GRENADE later on
		// scriptfxradiusdamage not threaded to handle all damage before removing the entities!
		if(isPlayer(level.monkeys[index].owner) && level.monkeys[index].owner.sessionstate != "spectator" && (!level.ex_teamplay || level.monkeys[index].owner.pers["team"] == level.monkeys[index].team))
			level.monkeys[index].body extreme\_ex_utils::scriptedfxradiusdamage(level.monkeys[index].owner, undefined, "MOD_GRENADE", "dummy1_mp", 500, 150, 50, "none", undefined, true, true, true);
		else
			level.monkeys[index].body extreme\_ex_utils::scriptedfxradiusdamage(level.monkeys[index].body, undefined, "MOD_GRENADE", "dummy1_mp", 500, 0, 0, "none", undefined, true, true, true);
	}

	thread perkRemove(index);
}

perkCanSee(index, player)
{
	if(level.ex_monkey_stance)
	{
		if(player.ex_stance == 2) return(false); // prone (mode 1 or 2)
		if(level.ex_monkey_stance == 2 && player.ex_stance == 1) return(false); // crouch (mode 2 only)
	}

	cansee = (bullettrace(level.monkeys[index].body.origin + (0, 0, 20), player.origin + (0, 0, 10), false, undefined)["fraction"] == 1);
	if(!cansee) cansee = (bullettrace(level.monkeys[index].body.origin + (0, 0, 20), player.origin + (0, 0, 40), false, undefined)["fraction"] == 1);
	if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.monkeys[index].body.origin + (0, 0, 20), player.ex_eyemarker.origin, false, undefined)["fraction"] == 1);
	return(cansee);
}

delayedSound(delay, sound)
{
	wait( [[level.ex_fpstime]](delay) );
	if(isDefined(self)) self playLocalSound(sound);
}

allowedSurface(origin)
{
	if(level.ex_monkey_surfacecheck)
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

monkeyClap(index)
{
	level endon(level.monkeys[index].notification);

	while(1)
	{
		clap = level.monkeys[index].clap;
		if(clap)
		{
			level.monkeys[index].leftarm rotateyaw(10, clap, 0, 0);
			level.monkeys[index].rightarm rotateyaw(-10, clap, 0, 0);
			wait( [[level.ex_fpstime]](clap) );
			level.monkeys[index].leftarm rotateyaw(-10, .05, 0, 0);
			level.monkeys[index].rightarm rotateyaw(10, .05, 0, 0);
			wait( [[level.ex_fpstime]](.05) );
			level.monkeys[index].body playsound("monkey_cymbal");
		}
		else wait( [[level.ex_fpstime]](.25) );
	}
}

checkProximityMonkeys(origin, cpx)
{
	if(level.ex_monkey)
	{
		for(index = 0; index < level.monkeys.size; index++)
		{
			if(level.monkeys[index].inuse && !level.monkeys[index].destroyed)
			{
				dist = int(distance(origin, level.monkeys[index].body.origin));
				if(dist <= cpx) level.monkeys[index].destroyed = true;
			}
		}
	}
}
