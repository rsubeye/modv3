#include extreme\_ex_specials;
#include extreme\_ex_weapons;
/*------------------------------------------------------------------------------
Original wall penetration mod ("wallfire") by IzNoGoD
Converted and optimized for eXtreme+ by PatmanSan
------------------------------------------------------------------------------*/

perkInit()
{
	// allow to load this max of unique effects
	level.ex_unique_effects_max = 6;

	// unique effects counter
	level.ex_unique_effects = 0;

	// perk related precaching
	initSurfaceArray();
}

perkInitPost()
{
	// perk related precaching after map load
	initWeaponArray();
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

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );

	if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_WALLFIRE_READY");

	self thread hudNotifySpecial(index);
	if(!level.ex_specials_keeptimer) self thread playerStartUsingPerk(index, false);

	self thread perkThink(index);
}

perkThink(index)
{
	self endon("kill_thread");

	self thread perkWallFire();

	timer = 0;
	while(timer < level.ex_wallfire_timer)
	{
		wait( [[level.ex_fpstime]](1) );
		timer++;
		if(timer == level.ex_specials_keeptimer) self thread playerStartUsingPerk(index, false);
	}

	self thread hudNotifySpecialRemove(index);
	self notify("kill_wallfire");
	self thread playerStopUsingPerk(index, true);
}

perkWallFire()
{
	self endon("kill_thread");
	self endon("kill_wallfire");

	weapon = self getcurrentweapon();
	ammo = self getweaponslotclipammo(self getWeaponSlot(weapon));

	oldweap = weapon;
	oldammo = ammo;
	oldangles = self getplayerangles();

	for(;;)
	{
		weapon = self getcurrentweapon();
		if(isWeaponSupported(weapon))
		{
			ammo = self getweaponslotclipammo(self getWeaponSlot(weapon));
			if(self attackbuttonpressed() && weapon == oldweap && ammo < oldammo)
			{
				angles = self getplayerangles();
				newangles = ( (oldangles[0] * 1 + angles[0] * 2) / 3, angles[1], angles[2] );
				forward = [[level.ex_vectorscale]](anglestoforward(newangles), 100000);
				smallforward = vectornormalize(forward);
				eye = self getEyePos();
				point = bullettrace(eye, eye - smallforward, false, undefined)["position"];
				firsttrace = bullettrace(point, point + forward, true, self);

				if(firsttrace["fraction"] < 1 && !isPlayer(firsttrace["entity"]))
				{
					if(isValidSurface(firsttrace["surfacetype"]))
					{
						firstdistance = int(distance(firsttrace["position"], point));
						secondtrace = bullettrace(firsttrace["position"] + smallforward, firsttrace["position"] + forward, true, self);
						backtrace = bullettrace(secondtrace["position"], firsttrace["position"], false, undefined);
						wall = int(distance(firsttrace["position"], backtrace["position"]));

						strength = getWeaponPenetration(weapon, firstdistance, wall, firsttrace["surfacetype"]);
						if(backtrace["fraction"] < 1 && strength > 0)
						{
							playSurfaceEffect(backtrace);

							seconddistance = int(distance(secondtrace["position"], point));
							if(isPlayer(secondtrace["entity"]) && secondtrace["entity"] != self)
							{
								maxdamage = getWeaponDamage(weapon);
								damage = int(maxdamage * (strength / 100));
								//logprint("DAMG: int(maxdamage[" + maxdamage + "] * (strength[" + strength + "] / 100)) = " + damage + "\n");
								if(damage > 0)
								{
									vDir = vectornormalize(secondtrace["position"] - self.origin);
									if(distancesquared(secondtrace["entity"] geteyepos(), secondtrace["position"]) < 64)
									{
										damage = int(damage * 2);
										sHitloc = "head";
									}
									else sHitloc = "none";
									secondtrace["entity"] thread [[level.callbackPlayerDamage]](self, self, damage, 0, getWeaponMOD(weapon), weapon, self.origin, vDir, sHitLoc, 0);
								}
							}
							else
							{
								if(secondtrace["fraction"] < 1 && seconddistance < getWeaponRange(weapon))
									playSurfaceEffect(secondtrace);
							}
						}
					}
				}
			}
			oldammo = ammo;
		}

		oldweap = weapon;
		oldangles = self getplayerangles();

		wait( [[level.ex_fpstime]](.05) );
	}
}

getWeaponSlot(weapon)
{
	if(weapon == self getweaponslotweapon("primary")) return "primary";
		else return "primaryb";
}

getEyePos()
{
	if(isDefined(self.ex_eyemarker))
	{
		if(distancesquared(self.ex_eyemarker.origin, self.origin) > 0) return self.ex_eyemarker.origin;
			else return self geteye();
	}
	else return self geteye();
}

isWeaponSupported(weapon)
{
	if(!isDefined(level.wfweapons[weapon])) return(false);
	return(true);
}

getWeaponRange(weapon)
{
	if(!isDefined(level.wfweapons[weapon])) return(0);
	return(level.wfweapons[weapon].range);
}

getWeaponDamage(weapon)
{
	if(!isDefined(level.wfweapons[weapon])) return(0);
	return(level.wfweapons[weapon].damage);
}

getWeaponStrength(weapon)
{
	if(!isDefined(level.wfweapons[weapon])) return(0);
	return(level.wfweapons[weapon].strength);
}

getWeaponMOD(weapon)
{
	if(!isDefined(level.wfweapons[weapon])) return("MOD_UNKNOWN");
	return(level.wfweapons[weapon].mod);
}

getWeaponPenetration(weapon, dist, wall, surface)
{
	if(!isDefined(level.wfweapons[weapon])) return(0);
	strength = level.wfweapons[weapon].strength;
	range = level.wfweapons[weapon].range;
	strength = strength * ((range - dist) / range);
	if(level.ex_wallfire_friction) strength = int(strength - (wall * getSurfaceFriction(surface)));
		else strength = int(strength - wall);
	return(strength);
}

logWeaponPenetration(weapon, dist, wall, surface)
{
	if(!isDefined(level.wfweapons[weapon])) return(0);
	strength = level.wfweapons[weapon].strength;
	range = level.wfweapons[weapon].range;
	strength1 = int(strength * ((range - dist) / range));
	logprint("DIST: weapon " + weapon + ": strength[" + strength + "] * ((range[" + range + "] - dist[" + dist + "]) / range[" + range + "]) = " + strength1 + "\n");
	if(level.ex_wallfire_friction)
	{
		friction = getSurfaceFriction(surface);
		strength = int(strength1 - (wall * friction));
		logprint("SURF: strength[" + strength1 + "] - (wall[" + wall + "] * friction[" + friction + "]) = " + strength + "\n");
	}
	else
	{
		strength = int(strength1 - wall);
		logprint("SURF: strength[" + strength1 + "] - wall[" + wall + "] = " + strength + "\n");
	}
	return(strength);
}

isValidSurface(surface)
{
	if(!isDefined(level.wfsurfaces[surface])) return(false);
	return(level.wfsurfaces[surface].valid);
}

getSurfaceFriction(surface)
{
	if(!isDefined(level.wfsurfaces[surface])) return(100);
	return(level.wfsurfaces[surface].friction);
}

getSurfaceEffect(surface)
{
	if(!isDefined(level.wfsurfaces[surface])) return(level.wfsurfaces["default"].effect);
	return(level.wfsurfaces[surface].effect);
}

playSurfaceEffect(trace)
{
	playfx(getSurfaceEffect(trace["surfacetype"]), trace["position"], vectornormalize(trace["normal"]));
}

initWeaponArray()
{
	level.wfweapons = [];

	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// skip weapon if not a main weapon or pistol
		if((level.weapons[weaponname].status & 1) != 1 && !isWeaponType(weaponname, "pistol") && !isWeaponType(weaponname, "vip")) continue;

		// skip weapons if not precached
		if(!level.weapons[weaponname].precached) continue;

		// SR to LR flag
		weapon_checklr = false;

		// create weapon entry with default values
		level.wfweapons[weaponname] = spawnstruct();
		level.wfweapons[weaponname].range = 1000;
		level.wfweapons[weaponname].damage = 50;
		level.wfweapons[weaponname].strength = 80;
		level.wfweapons[weaponname].mod = "MOD_RIFLE_BULLET";

		// adjust weapon characteristics based on weapon class
		if(isWeaponType(weaponname, "shotgun"))
		{
			level.wfweapons[weaponname].range = 1000;
			level.wfweapons[weaponname].damage = 70;
			level.wfweapons[weaponname].strength = 60;
			level.wfweapons[weaponname].mod = "MOD_RIFLE_BULLET";
		}
		else if(isWeaponType(weaponname, "pistol"))
		{
			level.wfweapons[weaponname].range = 1500;
			level.wfweapons[weaponname].damage = 40;
			level.wfweapons[weaponname].strength = 80;
			level.wfweapons[weaponname].mod = "MOD_PISTOL_BULLET";
		}
		else if(isWeaponType(weaponname, "vip"))
		{
			level.wfweapons[weaponname].range = 2500;
			level.wfweapons[weaponname].damage = 60;
			level.wfweapons[weaponname].strength = 80;
			level.wfweapons[weaponname].mod = "MOD_PISTOL_BULLET";
		}
		else if(isWeaponType(weaponname, "smg"))
		{
			level.wfweapons[weaponname].range = 3500;
			level.wfweapons[weaponname].damage = 70;
			level.wfweapons[weaponname].strength = 80;
			level.wfweapons[weaponname].mod = "MOD_RIFLE_BULLET";
		}
		else if(isWeaponType(weaponname, "mg"))
		{
			level.wfweapons[weaponname].range = 4500;
			level.wfweapons[weaponname].damage = 70;
			level.wfweapons[weaponname].strength = 80;
			level.wfweapons[weaponname].mod = "MOD_RIFLE_BULLET";
		}
		else if(level.ex_wallfire_rpg && isWeaponType(weaponname, "rl"))
		{
			level.wfweapons[weaponname].range = 5000;
			level.wfweapons[weaponname].damage = 100;
			level.wfweapons[weaponname].strength = 200;
			level.wfweapons[weaponname].mod = "MOD_PROJECTILE";
		}
		else if(isWeaponType(weaponname, "rifle"))
		{
			level.wfweapons[weaponname].range = 5500;
			level.wfweapons[weaponname].damage = 80;
			level.wfweapons[weaponname].strength = 80;
			level.wfweapons[weaponname].mod = "MOD_RIFLE_BULLET";
		}
		else if(isWeaponType(weaponname, "snipersr"))
		{
			level.wfweapons[weaponname].range = 10000;
			level.wfweapons[weaponname].damage = 90;
			level.wfweapons[weaponname].strength = 80;
			level.wfweapons[weaponname].mod = "MOD_RIFLE_BULLET";
			if(level.ex_longrange) weapon_checklr = true;
		}

		//logprint("WALLFIRE: registered weapon " + weaponname + "\n");

		if(weapon_checklr)
		{
			counterpart = extreme\_ex_longrange::getWeaponCounterpart(weaponname, false);
			if(counterpart != "none")
			{
				level.wfweapons[counterpart] = spawnstruct();
				level.wfweapons[counterpart].range = 50000;
				level.wfweapons[counterpart].damage = 100;
				level.wfweapons[counterpart].strength = 90;
				level.wfweapons[counterpart].mod = "MOD_RIFLE_BULLET";
				//logprint("WALLFIRE: registered LR weapon " + counterpart + "\n");
			}
		}
	}
}

initSurfaceArray()
{
	level.wfsurfaces = [];

	// the catch-all "default" is precached the regular way
	surface = "default";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_none", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = [[level.ex_PrecacheEffect]]("fx/impacts/default_hit.efx");
	level.ex_unique_effects++;

	// all other surfaces are precached via InitEffect
	surface = "wood";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_wood", 1, 0, 1, "int");
	level.wfsurfaces[surface].friction = 3;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_woodhit.efx");

	surface = "glass";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_glass", 1, 0, 1, "int");
	level.wfsurfaces[surface].friction = 2;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_glass.efx");

	surface = "cloth";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_cloth", 1, 0, 1, "int");
	level.wfsurfaces[surface].friction = 1;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/cloth_hit.efx");

	surface = "plaster";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_plaster", 1, 0, 1, "int");
	level.wfsurfaces[surface].friction = 4;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_concrete.efx");

	surface = "metal";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_metal", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 6;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_metalhit.efx");

	surface = "asphalt";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_asphalt", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 5;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_concrete.efx");

	surface = "concrete";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_concrete", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 5;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_concrete.efx");

	surface = "rock";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_rock", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 5;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_rock.efx");

	surface = "brick";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_brick", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 5;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_brick.efx");

	surface = "bark";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_bark", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 4;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_woodhit.efx");

	surface = "carpet";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_carpet", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 2;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/cloth_hit.efx");

	surface = "flesh";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_flesh", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 1;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/flesh_hit.efx");

	surface = "paper";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_paper", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 1;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/default_hit.efx");

	surface = "dirt";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_dirt", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_dirt.efx");

	surface = "foliage";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_foliage", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_foliage.efx");

	surface = "grass";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_grass", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_grass.efx");

	surface = "gravel";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_gravel", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_gravel.efx");

	surface = "ice";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_ice", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_snowhit.efx");

	surface = "mud";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_mud", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_mud.efx");

	surface = "sand";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_sand", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_dirt.efx");

	surface = "snow";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_snow", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_snowhit.efx");

	surface = "water";
	level.wfsurfaces[surface] = spawnstruct();
	level.wfsurfaces[surface].valid = [[level.ex_drm]]("ex_wallfire_water", 0, 0, 1, "int");
	level.wfsurfaces[surface].friction = 100;
	level.wfsurfaces[surface].effect = initEffect(surface, level.wfsurfaces[surface].valid, "fx/impacts/small_waterhit.efx");
}

initEffect(surface, valid, effect)
{
	effect_id = extreme\_ex_utils::isInEffectsArray(game["precached_effects"], effect);
	if(effect_id == -1)
	{
		if(valid && level.ex_unique_effects < level.ex_unique_effects_max)
		{
			level.ex_unique_effects++;
			effect_id = [[level.ex_PrecacheEffect]](effect);
		}
		else effect_id = getSurfaceEffect("default");
	}

	return(effect_id);
}
