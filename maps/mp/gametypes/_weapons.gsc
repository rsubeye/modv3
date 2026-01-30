#include extreme\_ex_weapons;

init()
{
	// create weapons array
	level.weaponnames = [];
	level.weapons = [];

	if(!level.ex_modern_weapons) registerWeaponsClassic();
		else registerWeaponsModern();

	registerWeaponsOther();

	// process weapons specs, and set initial allowed status for all weapons.
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// process specs for weapons with update flag set or in sidearm class
		if((level.weapons[weaponname].status & 2) == 2 || isWeaponType(weaponname, "sidearm"))
		{
			weaponspec = extreme\_ex_utils::trim( [[level.ex_drm]](weaponname, "", "", "", "string") );
			if(weaponspec == "") weaponspec = "1,0,999,999,100";
			weaponspec_array = strtok(weaponspec, ",");

			// make sure we have a proper array
			if(!isDefined(weaponspec_array) || !weaponspec_array.size) weaponspec_array = strtok("1,0,999,999,100", ",");

			level.weapons[weaponname].allow = strToInt(weaponspec_array[0], 1, 0, 1);
			level.weapons[weaponname].limit = strToInt(weaponspec_array[1], 0, 0, 128);
			level.weapons[weaponname].clip_limit = strToInt(weaponspec_array[2], 999, 0, 999);
			level.weapons[weaponname].ammo_limit = strToInt(weaponspec_array[3], 999, 0, 999);
			level.weapons[weaponname].wdm = strToInt(weaponspec_array[4], 100, 0, 500);

			// force the allow flag for rocket launchers, knife and pistols if their weapon class is active (primary weapons now)
			if(isWeaponType(weaponname, "rl") && level.ex_wepo_class == 8) level.weapons[weaponname].allow = 1;
				else if(isWeaponType(weaponname, "knife") && level.ex_wepo_class == 10) level.weapons[weaponname].allow = 1;
					else if(isWeaponType(weaponname, "pistol") && level.ex_wepo_class == 1 && level.ex_wepo_team_only) level.weapons[weaponname].allow = 1;

			server_allowcvar = "scr_allow_" + weaponname;
			setCvar(server_allowcvar, level.weapons[weaponname].allow);
			if(level.ex_wepo_limiter)
			{
				// set weapon limit to -1 if disallowed so it isn't re-enabled by the weapon limiter
				if(!level.weapons[weaponname].allow) level.weapons[weaponname].limit = -1;

				if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
				{
					level.weapons[weaponname].allow_allies = level.weapons[weaponname].allow;
					level.weapons[weaponname].allow_axis = level.weapons[weaponname].allow;
					level.weapons[weaponname].limit_allies = level.weapons[weaponname].limit;
					level.weapons[weaponname].limit_axis = level.weapons[weaponname].limit;
				}
			}
			//logprint("WEAPONS: " + weaponname + ": " + level.weapons[weaponname].allow + "," + level.weapons[weaponname].limit + "," + level.weapons[weaponname].clip_limit + "," + level.weapons[weaponname].ammo_limit + "," + level.weapons[weaponname].wdm + "\n");
		}
	}

	// set WDM for misc weapons (unparented)
	if(level.ex_wdmodon)
	{
		for(i = 0; i < level.weaponnames.size; i++)
		{
			weaponname = level.weaponnames[i];

			// get WDM for weapons without update flag set, not in sidearm class, without parent
			if((level.weapons[weaponname].status & 2) != 2 && !isWeaponType(weaponname, "sidearm") && !isDefined(level.weapons[weaponname].parent))
			{
				level.weapons[weaponname].wdm = [[level.ex_drm]]("ex_wdm_" + weaponname, 100, 0, 500, "int");
				//logprint("WEAPONS: " + weaponname + ": " + level.weapons[weaponname].wdm + "\n");
			}
		}
	}

	// copy parent specs to parented weapons
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// process specs for weapons with parent
		if(isDefined(level.weapons[weaponname].parent))
		{
			parent = level.weapons[weaponname].parent;
			if(isDefined(level.weapons[parent]))
			{
				// set child flag on parent, so parent and child point to eachother
				level.weapons[parent].child = weaponname;

				level.weapons[weaponname].allow = level.weapons[parent].allow;
				level.weapons[weaponname].limit = level.weapons[parent].limit;
				level.weapons[weaponname].clip_limit = level.weapons[parent].clip_limit;
				level.weapons[weaponname].ammo_limit = level.weapons[parent].ammo_limit;
				level.weapons[weaponname].wdm = level.weapons[parent].wdm;
				//logprint("WEAPONS: " + weaponname + ": " + level.weapons[weaponname].allow + "," + level.weapons[weaponname].limit + "," + level.weapons[weaponname].clip_limit + "," + level.weapons[weaponname].ammo_limit + "," + level.weapons[weaponname].wdm + "\n");
			}
			else
			{
				logprint("WEAPONS ERROR: weapon " + weaponname + " in weapons array references a non existing parent!\n");
				level.weapons[weaponname].parent = undefined;
				level.weapons[weaponname].allow = 0;
				level.weapons[weaponname].limit = 0;
				level.weapons[weaponname].clip_limit = 999;
				level.weapons[weaponname].ammo_limit = 999;
				level.weapons[weaponname].wdm = 100;
			}
		}
	}

	// precache the weapons
	precacheWeapons();

	// Update the allowed status for the weapons. This includes weapon limiter settings
	updateAllowed();

	// delete all restricted weapons from the map (in case the map includes weapons)
	thread deleteRestrictedWeapons();

	// monitor allowed status
	thread cycleUpdateAllowed();
}

strToInt(str, def, min, max)
{
	if(!isDefined(str)) return(def);

	str = extreme\_ex_utils::trim(str);
	if(str == "") return(def);

	validchars = "-+0123456789";
	for(i = 0; i < str.size; i++)
		if(!isSubStr(validchars, str[i])) return(def);

	val = int(str);
	if(val < min) return(def);
	if(val > max) return(def);
	return(val);
}

deleteRestrictedWeapons()
{
	// remove all weapons from the map that are not allowed (only checking weapons array)
	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// skip weapon if update flag not set
		if((level.weapons[weaponname].status & 2) != 2) continue;

		if(level.weapons[weaponname].classname == "frag")
		{
			if(!level.weapons[weaponname].allow)
			{
				entities_removed = extreme\_ex_entities::removeEntity("weapon_frag_grenade_american_mp", "classname");
				entities_removed += extreme\_ex_entities::removeEntity("weapon_frag_grenade_british_mp", "classname");
				entities_removed += extreme\_ex_entities::removeEntity("weapon_frag_grenade_russian_mp", "classname");
				entities_removed += extreme\_ex_entities::removeEntity("weapon_frag_grenade_german_mp", "classname");
				if(entities_removed)
				{
					game["entities_removed_class"] += entities_removed;
					game["entities_removed_total"] += entities_removed;
				}
			}
		}
		else if(level.weapons[weaponname].classname == "smoke")
		{
			if(!level.weapons[weaponname].allow)
			{
				entities_removed = extreme\_ex_entities::removeEntity("weapon_smoke_grenade_american_mp", "classname");
				entities_removed += extreme\_ex_entities::removeEntity("weapon_smoke_grenade_british_mp", "classname");
				entities_removed += extreme\_ex_entities::removeEntity("weapon_smoke_grenade_russian_mp", "classname");
				entities_removed += extreme\_ex_entities::removeEntity("weapon_smoke_grenade_german_mp", "classname");
				if(entities_removed)
				{
					game["entities_removed_class"] += entities_removed;
					game["entities_removed_total"] += entities_removed;
				}
			}
		}
		else
		{
			if(level.ex_bash_only || !level.weapons[weaponname].allow || !level.weapons[weaponname].precached)
			{
				entities_removed = extreme\_ex_entities::removeEntity("weapon_" + weaponname, "classname");
				if(entities_removed)
				{
					game["entities_removed_class"] += entities_removed;
					game["entities_removed_total"] += entities_removed;
				}
			}
		}
	}	

	// if using modern weapons, remove all ww2 weapons from the map (shadow array)
	if(level.ex_modern_weapons)
	{
		for(i = 0; i < level.oldweaponnames.size; i++)
		{
			weaponname = level.oldweaponnames[i];
			entities_removed = extreme\_ex_entities::removeEntity("weapon_" + weaponname, "classname");
			if(entities_removed)
			{
				game["entities_removed_class"] += entities_removed;
				game["entities_removed_total"] += entities_removed;
			}
		}
	}
}

dropWeapon()
{
	self endon("disconnect");

	// do not drop weapons if bots enabled
	if(level.ex_weapondrop_override) return;

	// if entities monitor in defcon 2, no weapon drop
	if(level.ex_entities_defcon == 2) return;

	if(!level.ex_wepo_drop_weps) return;

	// do not drop near spawnpoints to avoid weapon pickup when commencing sprint
	if(level.ex_sprint && level.ex_wepo_drop_sp && extreme\_ex_utils::tooClose(100, false, false, false, false)) return;

	clipsize1 = 0;
	clipsize2 = 0;
	reservesize1 = 0;
	reservesize2 = 0;
	currentslot = undefined;
	current = undefined;

	// get primary information
	weapon1 = self getweaponslotweapon("primary");
	if(weapon1 != "none" && weapon1 != game["sprint"] && weapon1 != "dummy1_mp" && weapon1 != "dummy2_mp" && weapon1 != "dummy3_mp")
	{
		clipsize1 = self getweaponslotclipammo("primary");
		reservesize1 = self getweaponslotammo("primary");
	}
	else weapon1 = "none";

	// get primaryb information
	weapon2 = self getweaponslotweapon("primaryb");
	if(weapon2 != "none" && weapon2 != game["sprint"] && weapon2 != "dummy1_mp" && weapon2 != "dummy2_mp" && weapon2 != "dummy3_mp")
	{
		clipsize2 = self getweaponslotclipammo("primaryb");
		reservesize2 = self getweaponslotammo("primaryb");
	}
	else weapon2 = "none";

	if(level.ex_wepo_drop_weps == 1)
	{
		current = self getcurrentweapon();

		if(current == weapon1) currentslot = "primary";
			else currentslot = "primaryb";

		if(isDefined(currentslot))
		{
			if(currentslot == "primary") if(clipsize1 || reservesize1) self dropItemIfAllowed(weapon1);
				else if(clipsize2 || reservesize2) self dropItemIfAllowed(weapon2);
		}
	}
	else if(level.ex_wepo_drop_weps == 2)
	{
		if(clipsize1 || reservesize1) self dropItemIfAllowed(weapon1);
	}
	else if(level.ex_wepo_drop_weps == 3)
	{
		if(clipsize2 || reservesize2) self dropItemIfAllowed(weapon2);
	}
	else if(level.ex_wepo_drop_weps == 4)
	{
		if(clipsize1 || reservesize1) self dropItemIfAllowed(weapon1);
		if(clipsize2 || reservesize2) self thread dropItemDelayed(weapon2, 0.2);
	}
}

dropItemDelayed(weapon, delay)
{
	wait( [[level.ex_fpstime]](delay) );
	if(isPlayer(self)) self dropItemIfAllowed(weapon);
}

dropOffhand()
{
	self endon("disconnect");

	// do not drop weapons if bots enabled
	//if(level.ex_weapondrop_override) return;

	// if entities monitor in defcon 2, no weapon drop
	if(level.ex_entities_defcon == 2) return;

	if(!level.ex_wepo_drop_frag && !level.ex_wepo_drop_smoke) return;

	// teams share the same weapon file for special nades, so if one them is enabled, only count own type
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges)
	{
		fragsize = self getammocount(self.pers["fragtype"]);
		enemy_fragsize = 0;
	}
	else
	{
		fragsize = self getammocount(self.pers["fragtype"]);
		enemy_fragsize = self getammocount(self.pers["enemy_fragtype"]);
	}

	smokesize = self getammocount(self.pers["smoketype"]);
	enemy_smokesize = self getammocount(self.pers["enemy_smoketype"]);

	if(level.ex_wepo_drop_frag)
	{
		if(fragsize) self dropItemIfAllowed(self.pers["fragtype"]);
		if(enemy_fragsize) self dropItemIfAllowed(self.pers["enemy_fragtype"]);
	}

	if(level.ex_wepo_drop_smoke)
	{
		if(smokesize) self dropItemIfAllowed(self.pers["smoketype"]);
		if(enemy_smokesize) self dropItemIfAllowed(self.pers["enemy_smoketype"]);
	}

	if(level.ex_specials && level.ex_supernade && level.ex_supernade_drop)
	{
		supernades = self getammocount(level.ex_supernade_allies);
		if(supernades) self dropItem(level.ex_supernade_allies);

		supernades = self getammocount(level.ex_supernade_axis);
		if(supernades) self dropItem(level.ex_supernade_axis);
	}
}

dropItemIfAllowed(weapon)
{
	// do not drop stealth knife
	if(weapon == "stealth_mp") return;
	// do not drop FreezeTag raygun (not considered main weapon)
	if(weapon == "raygun_mp") return;
	// do not drop VIP pistols (not part of weapons array)
	if(isWeaponType(weapon, "vip")) return;
	// check knife (not considered main weapon)
	if(isWeaponType(weapon, "knife"))
	{
		if(!level.allow_knife_drop) return;
		if(level.ex_wepo_class != 10 && (!level.ex_wepo_sidearm || !level.ex_wepo_sidearm_type)) return;
	}
	// check normal pistols (not considered main weapon)
	if(isWeaponType(weapon, "pistol") && !level.allow_pistol_drop) return;
	// check LR rifles (not considered main weapon)
	if(isWeaponType(weapon, "sniperlr") && !level.allow_sniperlr_drop) return;

	if(isMainWeapon(weapon))
	{
		if(level.weapons[weapon].classname == "sniper" && !level.allow_sniper_drop) return;
		if(level.weapons[weapon].classname == "mg" && !level.allow_mg_drop) return;
		if(level.weapons[weapon].classname == "smg" && !level.allow_smg_drop) return;
		if(level.weapons[weapon].classname == "rifle" && !level.allow_rifle_drop) return; 
		if(level.weapons[weapon].classname == "shotgun" && !level.allow_shotgun_drop) return; 
		if(level.weapons[weapon].classname == "rl" && !level.allow_rl_drop) return;
		if(level.weapons[weapon].classname == "ft" && !level.allow_ft_drop) return;

		if(isWeaponType(weapon, "boltrifle") && !level.allow_boltrifle_drop) return;
		if(isWeaponType(weapon, "boltsniper") && !level.allow_boltsniper_drop) return;
	}

	// convert frag, smoke and special grenades to a proper array index string
	weaponindex = weapon;
	if(isWeaponType(weapon, "frag") || isWeaponType(weapon, "fragspecial")) weaponindex = "fraggrenade";
		else if(isWeaponType(weapon, "smoke") || isWeaponType(weapon, "smokespecial")) weaponindex = "smokegrenade";

	if(isDefined(level.weapons[weaponindex]) && level.weapons[weaponindex].allow) self dropItem(weapon);
}

getFragGrenadeCount()
{
	if(self.pers["team"] == "allies") grenadetype = getFragTypeAllies();
		else grenadetype = getFragTypeAxis();

	count = self getammocount(grenadetype);
	return count;
}

getSmokeGrenadeCount()
{
	if(self.pers["team"] == "allies") grenadetype = "smoke_grenade_" + game["allies"] + GetSmokeColour(level.ex_smoke[game["allies"]]) + "mp";
		else grenadetype = "smoke_grenade_" + game["axis"] + GetSmokeColour(level.ex_smoke[game["axis"]]) + "mp";

	count = self getammocount(grenadetype);
	return count;
}

isMainWeapon(weapon)
{
	if(isDefined(level.weapons[weapon]) && (level.weapons[weapon].status & 1) == 1) return true;
	return false;
}

restrictWeaponByServerCvars(response)
{
	// allow "none" type for bots only (secondary weapon)
	if(response == "none")
	{
		if(isDefined(self.pers["isbot"])) return response;
			else return "restricted";
	}

	// must be a main weapon and precached
	if(!isMainWeapon(response) || !level.weapons[response].precached) return "restricted";

	// check if selected weapon belongs to the right team
	if(level.ex_all_weapons || level.ex_modern_weapons)
	{
		// do nothing!
	}
	else if( (!level.ex_wepo_class & level.ex_wepo_secondary == 1) || (level.ex_wepo_class && level.ex_wepo_team_only) )
	{
		if(self.pers["team"] == "axis")
		{
			if(!isWeaponType(response, game["axis"])) return "restricted";
		}
		else if(self.pers["team"] == "allies")
		{
			if(!isWeaponType(response, game["allies"])) return "restricted";
		}
		else return "restricted";
	}

	// weapon limiter check
	if(level.ex_wepo_limiter)
	{
		if(isDefined(level.weapons[response]))
		{
			if(level.weapons[response].limit > 0)
			{
				if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
				{
					if(self.pers["team"] == "allies")
					{
						if(isDefined(level.weapons[response].allow_allies))
						{
							if(level.weapons[response].allow_allies == 0) return "restricted";
								else return response;
						}
						else logprint("WEAPONS ERROR: level.weapons[" + response + "].allow_allies does not exist\n");
					}
					else
					{
						if(isDefined(level.weapons[response].allow_axis))
						{
							if(level.weapons[response].allow_axis == 0) return "restricted";
								else return response;
						}
						else logprint("WEAPONS ERROR: level.weapons[" + response + "].allow_axis does not exist\n");
					}
				}
				else
				{
					if(isDefined(level.weapons[response].allow))
					{
						if(level.weapons[response].allow == 0) return "restricted";
							else return response;
					}
					else logprint("WEAPONS ERROR: level.weapons[" + response + "].allow does not exist\n");
				}
			}
		}
		else logprint("WEAPONS ERROR: level.weapons[" + response + "] does not exist\n");
	}

	if(!getWeaponStatus(response)) return "restricted";
		else return response;
}

getWeaponStatus(weapon)
{
	cvarvalue = 0;
	if(isDefined(level.weapons[weapon])) cvarvalue = getCvarInt("scr_allow_" + weapon);
	return(cvarvalue);
}

getWeaponAdvStatus(weapon)
{
	if(!isDefined(level.weapons[weapon]) || !level.weapons[weapon].precached) return(false);

	if(level.ex_wepo_limiter)
	{
		if(level.weapons[weapon].limit == -1) return(false);
	}
	else if(!level.weapons[weapon].allow) return(false);

	return(true);
}

getWeaponName(weapon)
{
	if(!isDefined(weapon)) return &"WEAPON_UNKNOWNWEAPON";
	if(isWeaponType(weapon, "30cal")) return &"WEAPON_30CAL";
	if(isWeaponType(weapon, "mg42")) return &"WEAPON_MG42";
	if(!isDefined(level.weapons[weapon])) return &"WEAPON_UNKNOWNWEAPON";
	return(level.weapons[weapon].locstr);
}

useAn(weapon)
{
	if(!isDefined(weapon)) return false;
	if(isWeaponType(weapon, "30cal") || isWeaponType(weapon, "mg42")) return false;
	if(!isDefined(level.weapons[weapon]) || !isDefined(level.weapons[weapon].usean)) return false;
	return(level.weapons[weapon].usean);
}

cycleUpdateAllowed()
{
	level endon("ex_gameover");

	for(;;)
	{
		wait( [[level.ex_fpstime]](5) );
		if(!level.players.size) continue;
		updateAllowed();
	}
}

updateAllowed()
{
	level endon("ex_gameover");

	classname = undefined;

	switch(level.ex_wepo_class)
	{
		case 1: classname = "pistol"; break;     // pistol only
		case 2: classname = "sniper"; break;     // sniper only
		case 3: classname = "mg"; break;         // mg only
		case 4: classname = "smg"; break;        // smg only
		case 5: classname = "rifle"; break;      // rifle only
		case 6: classname = "boltrifle"; break;  // bolt action rifle only
		case 7: classname = "shotgun"; break;    // shotgun only
		case 8: classname = "rl"; break;         // panzerschreck only
		case 9: classname = "boltsniper"; break; // bolt and sniper only
		case 10: classname = "knife"; break;     // knives only
	}

	for(i = 0; i < level.weaponnames.size; i++)
	{
		weaponname = level.weaponnames[i];

		// skip weapon if update flag not set
		if((level.weapons[weaponname].status & 2) != 2) continue;

		// skip weapons if not precached
		if(!level.weapons[weaponname].precached) continue;

		server_allowcvar = "scr_allow_" + weaponname;
		if(level.ex_wepo_class)
		{
			// frag grenade class override
			if(level.weapons[weaponname].classname == "frag")
			{
				cvarvalue = getCvarInt(server_allowcvar);
				if(cvarvalue && !level.ex_wepo_allow_frag) cvarvalue = 0;
			}
			// smoke grenade class override
			else if(level.weapons[weaponname].classname == "smoke")
			{
				cvarvalue = getCvarInt(server_allowcvar);
				if(cvarvalue && !level.ex_wepo_allow_smoke) cvarvalue = 0;
			}
			// check if it matches the class based weapon
			else if(isWeaponType(weaponname, classname))
			{
				cvarvalue = getCvarInt(server_allowcvar);
			}
			else cvarvalue = 0;
		}
		else cvarvalue = getCvarInt(server_allowcvar);

		//logprint("WEAPONS: checking allow status for weapon " + weaponname + " (new " + cvarvalue + " vs old " + level.weapons[weaponname].allow + ")\n");

		// if weapon limiter enabled (disabled for classes automatically), count the weapons
		if(cvarvalue && level.ex_wepo_limiter && level.weapons[weaponname].classname != "frag" && level.weapons[weaponname].classname != "smoke")
		{
			// only process weapons which have a weapon limit set (0 = unlimited, -1 = disabled)
			if(level.weapons[weaponname].limit > 0)
			{
				// Set cvarvalue to 1 to force a recount
				cvarvalue = 1;
				cvarvalue_allies = cvarvalue;
				cvarvalue_axis = cvarvalue;

				// if valid allied or axis weapon, check if limit reached
				if(isWeaponType(weaponname, game["allies"]) || isWeaponType(weaponname, game["axis"]))
				{
					count = 0;
					count_allies = count;
					count_axis = count;

					// get the players array
					players = level.players;

					for(j = 0; j < players.size; j++)
					{
						player = players[j];

						// skip player if no team setting exist
						if(isPlayer(player) && !isDefined(player.pers["team"])) continue;

						// don't count real spectators
						if(isPlayer(player) && player.pers["team"] == "spectator") continue;

						// check players that are not spectator team and have not started playing, i.e. just joined or switched sides
						if(isPlayer(player) && player.sessionstate == "spectator")
						{
							// check for a primary being chosen, primaryb (secondary) is not checked now, cause they will have spawned directly after choosing
							if(isDefined(player.pers["weapon"]) && weaponname == player.pers["weapon"])
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
						}
						else if(isPlayer(player) && isDefined(player.weapon))
						{
							// check for registered primary spawn weapon
							if(isDefined(player.weapon["primary"]) && isDefined(player.weapon["primary"].name) && weaponname == player.weapon["primary"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
							// check for registered secondary spawn weapon
							else if(isDefined(player.weapon["primaryb"]) && isDefined(player.weapon["primaryb"].name) && weaponname == player.weapon["primaryb"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
							// check for registered virtual spawn weapon
							else if(isDefined(player.weapon["virtual"]) && isDefined(player.weapon["virtual"].name) && weaponname == player.weapon["virtual"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}

							// check if player selected new primary weapon
							if(isDefined(player.pers["weapon"]) && weaponname == player.pers["weapon"] &&
							   isDefined(player.weapon["primary"]) && isDefined(player.weapon["primary"].name) && weaponname != player.weapon["primary"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
							// check if player selected new secondary weapon
							else if(isDefined(player.pers["weapon2"]) && weaponname == player.pers["weapon2"] &&
							        isDefined(player.weapon["primaryb"]) && isDefined(player.weapon["primaryb"].name) && weaponname != player.weapon["primaryb"].name)
							{
								count++;
								if(player.pers["team"] == "allies") count_allies++;
									else count_axis++;
							}
						}
					}

					if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
					{
						if(count_allies >= level.weapons[weaponname].limit_allies) cvarvalue_allies = 0;
						if(count_axis >= level.weapons[weaponname].limit_axis) cvarvalue_axis = 0;

						if(level.weapons[weaponname].allow_allies != cvarvalue_allies)
						{
							level.weapons[weaponname].allow_allies = cvarvalue_allies;
							thread updateAllowedAllAllies(weaponname);
						}

						if(level.weapons[weaponname].allow_axis != cvarvalue_axis)
						{
							level.weapons[weaponname].allow_axis = cvarvalue_axis;
							thread updateAllowedAllAxis(weaponname);
						}
					}
					else
					{
						if(count >= level.weapons[weaponname].limit) cvarvalue = 0;

						if(level.weapons[weaponname].allow != cvarvalue)
						{
							level.weapons[weaponname].allow = cvarvalue;
							thread updateAllowedAllClients(weaponname);
						}
					}
				}
			}
		}
		else
		{
			if(level.weapons[weaponname].allow != cvarvalue)
			{
				level.weapons[weaponname].allow = cvarvalue;
				setCvar(server_allowcvar, level.weapons[weaponname].allow);
				thread updateAllowedAllClients(weaponname);
			}
		}
	}
}

updateAllowedAllClients(weaponname)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
		players[i] updateAllowedSingleClient(weaponname);
}

updateAllowedAllAllies(weaponname)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] == "allies")
			player updateAllowedSingleClientAllies(weaponname);
	}
}

updateAllowedAllAxis(weaponname)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isDefined(player.pers["team"]) && player.pers["team"] == "axis")
			player updateAllowedSingleClientAxis(weaponname);
	}
}

updateAllAllowedSingleClient()
{
	for(i = 0; i < level.weaponnames.size; i++)
	{
		if(i % 10 == 0) wait( [[level.ex_fpstime]](.05) );

		weaponname = level.weaponnames[i];

		// skip weapon if update flag not set
		if((level.weapons[weaponname].status & 2) != 2) continue;

		if(level.ex_teamplay && level.ex_wepo_limiter && level.ex_wepo_limiter_perteam && isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
		{
			if(self.pers["team"] == "allies") self updateAllowedSingleClientAllies(weaponname);
				else self updateAllowedSingleClientAxis(weaponname);
		}
		else self updateAllowedSingleClient(weaponname);
	}
}

updateAllowedSingleClient(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
	{
		if(!level.weapons[weaponname].precached) cvarvalue = -1;
			else cvarvalue = level.weapons[weaponname].allow;
		self setClientCvar("ui_allow_" + weaponname, cvarvalue);
	}
}

updateAllowedSingleClientAllies(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
	{
		if(!level.weapons[weaponname].precached) cvarvalue = -1;
			else cvarvalue = level.weapons[weaponname].allow_allies;
		self setClientCvar("ui_allow_" + weaponname, cvarvalue);
	}
}

updateAllowedSingleClientAxis(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
	{
		if(!level.weapons[weaponname].precached) cvarvalue = -1;
			else cvarvalue = level.weapons[weaponname].allow_axis;
		self setClientCvar("ui_allow_" + weaponname, cvarvalue);
	}
}

updateDisabledSingleClient(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
		self setClientCvar("ui_allow_" + weaponname, 0);
}

updateEnabledSingleClient(weaponname)
{
	if(isDefined(level.weapons[weaponname]))
		self setClientCvar("ui_allow_" + weaponname, 1);
}

registerWeapon(weaponname, classname, subclass, status, team, nationality, locstr, usean, parent)
{
	// registerWeapon(weaponname, classname, subclass, status, team, nationality, locstr, usean, parent)
	//   weaponname : string; name of weapon file
	//    classname : string; class of weapon
	//      subname : string; subclass of weapon (set undefined if not needed)
	//       status : integer; 1(main) + 2(update) + 4(wob) + 8(mbot)
	//         team : string; "axis", "allies" or "all"
	//  nationality : integer; 1(american) + 2(british) + 4(german) + 8(russian)
	//       locstr : localized string in weapon.str
	//        usean : boolean; true(1) for "using an", false(0) for "using a"
	//       parent : string; name of parent weapon file (set undefined if not needed)

	if(!isDefined(level.weapons[weaponname]))
	{
		level.weaponnames[level.weaponnames.size] = weaponname;
		level.weapons[weaponname] = spawnstruct();
	}

	level.weapons[weaponname].classname = classname;
	if(isDefined(subclass)) level.weapons[weaponname].subclass = subclass;
	level.weapons[weaponname].status = status;
	level.weapons[weaponname].team = team;
	level.weapons[weaponname].nat = nationality;
	level.weapons[weaponname].locstr = locstr;
	level.weapons[weaponname].allow = 1;
	if(isDefined(parent)) level.weapons[weaponname].parent = parent;
	level.weapons[weaponname].precached = 0;
}

registerWeaponsClassic()
{
	registerWeapon("bar_mp", "mg", undefined, 15, "allies", 1, &"WEAPON_BAR", 0);
	registerWeapon("bren_mp", "mg", undefined, 15, "allies", 2, &"WEAPON_BREN", 0);
	registerWeapon("dp28_mp", "mg", undefined, 15, "allies", 8, &"WEAPON_DP28", 0);
	registerWeapon("enfield_mp", "rifle", "bolt", 15, "allies", 3, &"WEAPON_LEEENFIELD", 0);
	registerWeapon("enfield_scope_mp", "sniper", undefined, 15, "allies", 3, &"WEAPON_SCOPEDLEEENFIELD", 0);
	registerWeapon("flamethrower_allies", "ft", undefined, 11, "allies", 11, &"WEAPON_FLAMETHROWER", 0);
	registerWeapon("flamethrower_axis", "ft", undefined, 11, "axis", 4, &"WEAPON_FLAMMENWERFER", 0);
	registerWeapon("g43_mp", "rifle", "semi", 15, "axis", 4, &"WEAPON_G43", 0);
	registerWeapon("g43_sniper", "sniper", undefined, 15, "axis", 4, &"WEAPON_SCOPEDG43", 0);
	registerWeapon("greasegun_mp", "smg", undefined, 15, "allies", 1, &"WEAPON_GREASEGUN", 0);
	registerWeapon("kar98k_mp", "rifle", "bolt", 15, "axis", 4, &"WEAPON_KAR98K", 0);
	registerWeapon("kar98k_sniper_mp", "sniper", undefined, 15, "axis", 4, &"WEAPON_SCOPEDKAR98K", 0);
	registerWeapon("m1carbine_mp", "rifle", undefined, 15, "allies", 1, &"WEAPON_M1A1CARBINE", 1);
	registerWeapon("m1garand_mp", "rifle", "semi", 15, "allies", 3, &"WEAPON_M1GARAND", 1);
	registerWeapon("mobile_30cal", "mg", undefined, 15, "allies", 11, &"WEAPON_30CAL", 0);
	registerWeapon("mobile_mg42", "mg", undefined, 15, "axis", 4, &"WEAPON_MG42", 0);
	registerWeapon("mosin_nagant_mp", "rifle", "bolt", 15, "allies", 8, &"WEAPON_MOSINNAGANT", 0);
	registerWeapon("mosin_nagant_sniper_mp", "sniper", undefined, 15, "allies", 8, &"WEAPON_SCOPEDMOSINNAGANT", 0);
	registerWeapon("mp40_mp", "smg", undefined, 15, "axis", 4, &"WEAPON_MP40", 1);
	registerWeapon("mp44_mp", "mg", undefined, 15, "axis", 4, &"WEAPON_MP44", 1);
	registerWeapon("pps42_mp", "smg", undefined, 15, "allies", 8, &"WEAPON_PPS42", 0);
	registerWeapon("ppsh_mp", "smg", undefined, 15, "allies", 8, &"WEAPON_PPSH", 0);
	registerWeapon("shotgun_mp", "shotgun", undefined, 15, "all", 15, &"WEAPON_SHOTGUN", 1);
	registerWeapon("springfield_mp", "sniper", undefined, 15, "allies", 1, &"WEAPON_SPRINGFIELD", 0);
	registerWeapon("springfield_noscope_mp", "rifle", "bolt", 15, "allies", 1, &"WEAPON_SPRINGFIELD_NOSCOPE", 0);
	registerWeapon("sten_mp", "smg", undefined, 15, "allies", 2, &"WEAPON_STEN", 0);
	registerWeapon("svt40_mp", "rifle", "semi", 15, "allies", 8, &"WEAPON_SVT40", 0);
	registerWeapon("thompson_mp", "smg", undefined, 15, "allies", 3, &"WEAPON_THOMPSON", 0);

	// longrange rifles
	if(level.ex_longrange)
	{
		registerWeapon("enfield_scope_lr_mp", "sniperlr", undefined, 0, "allies", 3, &"WEAPON_SCOPEDLEEENFIELD_LR", 0, "enfield_scope_mp");
		registerWeapon("g43_sniper_lr", "sniperlr", undefined, 0, "axis", 4, &"WEAPON_SCOPEDG43_LR", 0, "g43_sniper");
		registerWeapon("kar98k_sniper_lr_mp", "sniperlr", undefined, 0, "axis", 4, &"WEAPON_SCOPEDKAR98K_LR", 0, "kar98k_sniper_mp");
		registerWeapon("mosin_nagant_sniper_lr_mp", "sniperlr", undefined, 0, "allies", 8, &"WEAPON_SCOPEDMOSINNAGANT_LR", 0, "mosin_nagant_sniper_mp");
		registerWeapon("springfield_lr_mp", "sniperlr", undefined, 0, "allies", 1, &"WEAPON_SPRINGFIELD_LR", 0, "springfield_mp");
	}

	// rocket launchers
	if(level.ex_wepo_class == 8)
	{
		registerWeapon("panzerfaust_mp", "rl", undefined, 15, "all", 15, &"WEAPON_PANZERFAUST", 0);
		registerWeapon("panzerschreck_mp", "rl", undefined, 15, "all", 15, &"WEAPON_PANZERSCHRECK", 0);
	}
	else
	{
		// panzerfaust is not menu selectable, but some maps (like Willow) have the panzerfaust built-in
		registerWeapon("panzerfaust_mp", "rl", undefined, 15, "all", 15, &"WEAPON_PANZERFAUST", 0);
		registerWeapon("panzerschreck_allies", "rl", undefined, 15, "allies", 11, &"WEAPON_BAZOOKA", 0);
		registerWeapon("panzerschreck_mp", "rl", undefined, 15, "axis", 4, &"WEAPON_PANZERSCHRECK", 0);
	}

	// pistols
	if(level.ex_wepo_class == 1)
	{
		registerWeapon("colt_mp", "pistol", undefined, 3, "all", 15, &"WEAPON_COLT45", 0);
		registerWeapon("luger_mp", "pistol", undefined, 3, "all", 15, &"WEAPON_LUGER", 0);
		registerWeapon("tt30_mp", "pistol", undefined, 3, "all", 15, &"WEAPON_TT30", 0);
		registerWeapon("webley_mp", "pistol", undefined, 3, "all", 15, &"WEAPON_WEBLEY", 0);
	}
	else if(level.ex_wepo_sidearm && !level.ex_wepo_sidearm_type)
	{
		registerWeapon("luger_mp", "pistol", undefined, 0, "axis", 4, &"WEAPON_LUGER", 0);
		switch(game["allies"])
		{
			case "american": registerWeapon("colt_mp", "pistol", undefined, 0, "allies", 1, &"WEAPON_COLT45", 0); break;
			case "british": registerWeapon("webley_mp", "pistol", undefined, 0, "allies", 2, &"WEAPON_WEBLEY", 0); break;
			case "russian": registerWeapon("tt30_mp", "pistol", undefined, 0, "allies", 8, &"WEAPON_TT30", 0); break;
		}
	}

	// knife
	if(level.ex_wepo_class == 10) registerWeapon("knife_mp", "knife", undefined, 3, "all", 15, &"WEAPON_KNIFE", 0);
		else if(level.ex_wepo_sidearm && level.ex_wepo_sidearm_type) registerWeapon("knife_mp", "knife", undefined, 0, "all", 15, &"WEAPON_KNIFE", 0);
}

registerWeaponsModern()
{
	registerWeapon("ak47_mp", "mg", undefined, 11, "all", 15, &"WEAPON_AK47", 1);
	registerWeapon("ak74_mp", "smg", undefined, 11, "all", 15, &"WEAPON_AK74", 1);
	registerWeapon("ar10_mp", "sniper", undefined, 11, "all", 15, &"WEAPON_AR10", 1);
	registerWeapon("auga3_mp", "mg", undefined, 11, "all", 15, &"WEAPON_AUGA3", 1);
	registerWeapon("barrett_mp", "sniper", undefined, 11, "all", 15, &"WEAPON_BARRETT", 0);
	registerWeapon("dragunov_mp", "sniper", undefined, 11, "all", 15, &"WEAPON_DRAGUNOV", 0);
	registerWeapon("famas_mp", "mg", undefined, 11, "all", 15, &"WEAPON_FAMAS", 0);
	registerWeapon("galil_mp", "mg", undefined, 11, "all", 15, &"WEAPON_GALIL", 1);
	registerWeapon("hk21_mp", "smg", undefined, 11, "all", 15, &"WEAPON_HK21", 1);
	registerWeapon("m40a3_mp", "sniper", undefined, 11, "all", 15, &"WEAPON_M40A3", 1);
	registerWeapon("m4a1_mp", "mg", undefined, 11, "all", 15, &"WEAPON_M4A1", 1);
	registerWeapon("m8a1_mp", "mg", undefined, 11, "all", 15, &"WEAPON_M8A1", 0);
	registerWeapon("mp5_mp", "smg", undefined, 11, "all", 15, &"WEAPON_MP5", 1);
	registerWeapon("mp7a2_mp", "smg", undefined, 11, "all", 15, &"WEAPON_MP7A2", 1);
	registerWeapon("mtar_mp", "mg", undefined, 11, "all", 15, &"WEAPON_MTAR", 1);
	registerWeapon("p90_mp", "smg", undefined, 11, "all", 15, &"WEAPON_P90", 0);
	registerWeapon("sg552_mp", "mg", undefined, 11, "all", 15, &"WEAPON_SG552", 0);
	registerWeapon("spas12_mp", "shotgun", undefined, 11, "all", 15, &"WEAPON_SPAS12", 0);
	registerWeapon("ump45_mp", "smg", undefined, 11, "all", 15, &"WEAPON_UMP45", 0);
	registerWeapon("xm1014_mp", "shotgun", undefined, 11, "all", 15, &"WEAPON_XM1014", 1);
	registerWeapon("xm8_mp", "mg", undefined, 11, "all", 15, &"WEAPON_XM8", 0);

	// longrange rifles
	if(level.ex_longrange)
	{
		registerWeapon("ar10_lr_mp", "sniperlr", undefined, 0, "all", 15, &"WEAPON_AR10_LR", 1, "ar10_mp");
		registerWeapon("barrett_lr_mp", "sniperlr", undefined, 0, "all", 15, &"WEAPON_BARRETT_LR", 0, "barrett_mp");
		registerWeapon("dragunov_lr_mp", "sniperlr", undefined, 0, "all", 15, &"WEAPON_DRAGUNOV_LR", 0, "dragunov_mp");
		registerWeapon("m40a3_lr_mp", "sniperlr", undefined, 0, "all", 15, &"WEAPON_M40A3_LR", 1, "m40a3_mp");
	}

	// mobile MG
	if(level.ex_turrets > 1)
	{
		registerWeapon("mobile_30cal", "mg", undefined, 11, "allies", 15, &"WEAPON_30CAL", 0);
		registerWeapon("mobile_mg42", "mg", undefined, 11, "axis", 15, &"WEAPON_MG42", 0);
	}

	// rocket launchers
	if(level.ex_wepo_class == 8)
	{
		registerWeapon("panzerfaust_mp", "rl", undefined, 11, "all", 15, &"WEAPON_PANZERFAUST", 0);
		registerWeapon("panzerschreck_mp", "rl", undefined, 11, "all", 15, &"WEAPON_PANZERSCHRECK", 0);
	}

	// pistols
	if(level.ex_wepo_class == 1)
	{
		registerWeapon("beretta_mp", "pistol", undefined, 3, "all", 15, &"WEAPON_BERETTA", 0);
		registerWeapon("deagle_mp", "pistol", undefined, 3, "all", 15, &"WEAPON_DEAGLE", 0);
		registerWeapon("glock_mp", "pistol", undefined, 3, "all", 15, &"WEAPON_GLOCK", 0);
		registerWeapon("hk45_mp", "pistol", undefined, 3, "all", 15, &"WEAPON_HK45", 0);
	}
	else if(level.ex_wepo_sidearm && !level.ex_wepo_sidearm_type)
	{
		registerWeapon("hk45_mp", "pistol", undefined, 0, "axis", 4, &"WEAPON_HK45", 0);
		switch(game["allies"])
		{
			case "american": registerWeapon("deagle_mp", "pistol", undefined, 0, "allies", 1, &"WEAPON_DEAGLE", 0); break;
			case "british": registerWeapon("beretta_mp", "pistol", undefined, 0, "allies", 2, &"WEAPON_BERETTA", 0); break;
			case "russian": registerWeapon("glock_mp", "pistol", undefined, 0, "allies", 8, &"WEAPON_GLOCK", 0); break;
		}
	}

	// knife
	if(level.ex_wepo_class == 10) registerWeapon("modern_knife_mp", "knife", undefined, 3, "all", 15, &"WEAPON_KNIFE", 0);
		else if(level.ex_wepo_sidearm && level.ex_wepo_sidearm_type) registerWeapon("modern_knife_mp", "knife", undefined, 0, "all", 15, &"WEAPON_KNIFE", 0);

	// Keep a list of stock ww2 weapons, so we can remove them from maps that contain weapons
	level.oldweaponnames = [];
	level.oldweaponnames[level.oldweaponnames.size] = "bar_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "bren_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "colt_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "dp28_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "enfield_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "enfield_scope_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "flamethrower_allies";
	level.oldweaponnames[level.oldweaponnames.size] = "flamethrower_axis";
	level.oldweaponnames[level.oldweaponnames.size] = "g43_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "g43_sniper";
	level.oldweaponnames[level.oldweaponnames.size] = "greasegun_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "kar98k_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "kar98k_sniper_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "knife_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "luger_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "m1carbine_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "m1garand_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "mosin_nagant_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "mosin_nagant_sniper_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "mp40_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "mp44_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "panzerfaust_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "panzerschreck_allies";
	level.oldweaponnames[level.oldweaponnames.size] = "panzerschreck_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "pps42_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "ppsh_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "shotgun_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "springfield_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "sten_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "svt40_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "thompson_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "tt30_mp";
	level.oldweaponnames[level.oldweaponnames.size] = "webley_mp";
}

registerWeaponsOther()
{
	// catch-all parent for frags and frag replacements
	registerWeapon("fraggrenade", "frag", undefined, 2, "all", 15, &"WEAPON_FRAGGRENADE", 0);

	// frag replacements
	if(level.ex_firenades) registerWeapon("fire_mp", "fire", undefined, 0, "all", 15, &"WEAPON_FIRE", 0, "fraggrenade");
	else if(level.ex_gasnades) registerWeapon("gas_mp", "gas", undefined, 0, "all", 15, &"WEAPON_GAS", 0, "fraggrenade");
	else if(level.ex_satchelcharges) registerWeapon("satchel_mp", "satchel", undefined, 0, "all", 15, &"WEAPON_SATCHEL", 0, "fraggrenade");
	// regular frags
	else
	{
		registerWeapon("frag_grenade_german_mp", "frag", undefined, 0, "all", 15, &"WEAPON_FRAGGRENADE", 0, "fraggrenade");
		switch(game["allies"])
		{
			case "american": registerWeapon("frag_grenade_american_mp", "frag", undefined, 0, "all", 15, &"WEAPON_FRAGGRENADE", 0, "fraggrenade"); break;
			case "british": registerWeapon("frag_grenade_british_mp", "frag", undefined, 0, "all", 15, &"WEAPON_FRAGGRENADE", 0, "fraggrenade"); break;
			case "russian": registerWeapon("frag_grenade_russian_mp", "frag", undefined, 0, "all", 15, &"WEAPON_FRAGGRENADE", 0, "fraggrenade"); break;
		}
	}

	// catch-all parent for smoke replacements
	registerWeapon("smokegrenade", "smoke", undefined, 2, "all", 15, &"WEAPON_SMOKEGRENADE", 0);

	// smoke replacements (regular smoke does not kill and is not required in the weapons array)
	if(level.ex_smoke[game["axis"]] == 7) registerWeapon("smoke_grenade_german_fire_mp", "fire", undefined, 0, "all", 15, &"WEAPON_FIRE", 0, "smokegrenade");
	else if(level.ex_smoke[game["axis"]] == 8) registerWeapon("smoke_grenade_german_gas_mp", "gas", undefined, 0, "all", 15, &"WEAPON_GAS", 0, "smokegrenade");
	else if(level.ex_smoke[game["axis"]] == 9) registerWeapon("smoke_grenade_german_satchel_mp", "satchel", undefined, 0, "all", 15, &"WEAPON_SATCHEL", 0, "smokegrenade");
	switch(game["allies"])
	{
		case "american":
			if(level.ex_smoke[game["allies"]] == 7) registerWeapon("smoke_grenade_american_fire_mp", "fire", undefined, 0, "all", 15, &"WEAPON_FIRE", 0, "smokegrenade");
			else if(level.ex_smoke[game["allies"]] == 8) registerWeapon("smoke_grenade_american_gas_mp", "gas", undefined, 0, "all", 15, &"WEAPON_GAS", 0, "smokegrenade");
			else if(level.ex_smoke[game["allies"]] == 9) registerWeapon("smoke_grenade_american_satchel_mp", "satchel", undefined, 0, "all", 15, &"WEAPON_SATCHEL", 0, "smokegrenade");
			break;
		case "british":
			if(level.ex_smoke[game["allies"]] == 7) registerWeapon("smoke_grenade_british_fire_mp", "fire", undefined, 0, "all", 15, &"WEAPON_FIRE", 0, "smokegrenade");
			else if(level.ex_smoke[game["allies"]] == 8) registerWeapon("smoke_grenade_british_gas_mp", "gas", undefined, 0, "all", 15, &"WEAPON_GAS", 0, "smokegrenade");
			else if(level.ex_smoke[game["allies"]] == 9) registerWeapon("smoke_grenade_british_satchel_mp", "satchel", undefined, 0, "all", 15, &"WEAPON_SATCHEL", 0, "smokegrenade");
			break;
		case "russian":
			if(level.ex_smoke[game["allies"]] == 7) registerWeapon("smoke_grenade_russian_fire_mp", "fire", undefined, 0, "all", 15, &"WEAPON_FIRE", 0, "smokegrenade");
			else if(level.ex_smoke[game["allies"]] == 8) registerWeapon("smoke_grenade_russian_gas_mp", "gas", undefined, 0, "all", 15, &"WEAPON_GAS", 0, "smokegrenade");
			else if(level.ex_smoke[game["allies"]] == 9) registerWeapon("smoke_grenade_russian_satchel_mp", "satchel", undefined, 0, "all", 15, &"WEAPON_SATCHEL", 0, "smokegrenade");
			break;
	}

	// landmines
	if(level.ex_landmines) registerWeapon("landmine_mp", "landmine", undefined, 0, "all", 15, &"WEAPON_LANDMINE", 0);

	// tripwires
	if(level.ex_tweapon) registerWeapon("tripwire_mp", "tripwire", undefined, 0, "all", 15, &"WEAPON_TRIPWIRE", 0);

	// perks (mostly fake weapon files handled by dummy weapon files, except stealth and super nades)
	if(level.ex_specials)
	{
		if(level.ex_beartrap) registerWeapon("beartrap_mp", "perk", undefined, 0, "all", 15, &"WEAPON_BEARTRAP", 0);
		if(level.ex_flak) registerWeapon("flakprojectile_mp", "perk", undefined, 0, "all", 15, &"WEAPON_FLAKPROJECTILE", 0);
		if(level.ex_gml) registerWeapon("gmlmissile_mp", "perk", undefined, 0, "all", 15, &"WEAPON_GMLMISSILE", 0);
		if(level.ex_heli)
		{
			registerWeapon("heligun_mp", "perk", undefined, 0, "all", 15, &"WEAPON_HELIGUN", 0);
			registerWeapon("helimissile_mp", "perk", undefined, 0, "all", 15, &"WEAPON_HELIMISSILE", 0);
			registerWeapon("helitube_mp", "perk", undefined, 0, "all", 15, &"WEAPON_HELITUBE", 0);
		}
		if(level.ex_monkey) registerWeapon("monkey_mp", "perk", undefined, 0, "all", 15, &"WEAPON_MONKEYBOMB", 0);
		if(level.ex_quad) registerWeapon("quadrotor_mp", "perk", undefined, 0, "all", 15, &"WEAPON_QUADROTOR", 0);
		if(level.ex_sentrygun) registerWeapon("sentrygun_mp", "perk", undefined, 0, "all", 15, &"WEAPON_SENTRYGUN", 0);
		if(level.ex_stealth) registerWeapon("stealth_mp", "knife", undefined, 0, "all", 15, &"WEAPON_STEALTH", 0);
		if(level.ex_supernade)
		{
			registerWeapon("supernade_german_mp", "super", undefined, 0, "all", 15, &"WEAPON_SUPERNADE", 0);
			switch(game["allies"])
			{
				case "american": registerWeapon("supernade_american_mp", "super", undefined, 0, "all", 15, &"WEAPON_SUPERNADE", 0); break;
				case "british": registerWeapon("supernade_british_mp", "super", undefined, 0, "all", 15, &"WEAPON_SUPERNADE", 0); break;
				case "russian": registerWeapon("supernade_russian_mp", "super", undefined, 0, "all", 15, &"WEAPON_SUPERNADE", 0); break;
			}
		}
		if(level.ex_ugv)
		{
			registerWeapon("ugvgun_mp", "perk", undefined, 0, "all", 15, &"WEAPON_UGVGUN", 0);
			registerWeapon("ugvrocket_mp", "perk", undefined, 0, "all", 15, &"WEAPON_UGVROCKET", 0);
		}
		if(level.ex_specials_knife)
		{
			modern = false;
			if( (!level.ex_specials_knife_model && level.ex_modern_weapons) || level.ex_specials_knife_model == 2) modern = true;
			if(modern) registerWeapon("modern_knife_mp", "knife", undefined, 0, "all", 15, &"WEAPON_KNIFE", 0);
				else registerWeapon("knife_mp", "knife", undefined, 0, "all", 15, &"WEAPON_KNIFE", 0);
		}
	}

	// gunship (ranksystem or perk)
	if(level.ex_gunship || (level.ex_specials && level.ex_gunship_special))
	{
		if(level.ex_gunship_25mm) registerWeapon("gunship_25mm_mp", "gunship", undefined, 0, "all", 15, &"WEAPON_GUNSHIP_25MM", 0);
		if(level.ex_gunship_40mm) registerWeapon("gunship_40mm_mp", "gunship", undefined, 0, "all", 15, &"WEAPON_GUNSHIP_40MM", 0);
		if(level.ex_gunship_105mm) registerWeapon("gunship_105mm_mp", "gunship", undefined, 0, "all", 15, &"WEAPON_GUNSHIP_105MM", 0);
		if(level.ex_gunship_nuke) registerWeapon("gunship_nuke_mp", "gunship", undefined, 0, "all", 15, &"WEAPON_GUNSHIP_NUKE", 0);
	}

	// ranksystem WMD
	if((level.ex_ranksystem && level.ex_rank_wmdtype) || level.ex_mortars == 2) registerWeapon("mortar_mp", "wmd", undefined, 0, "all", 15, &"WEAPON_MORTAR", 0);
	if((level.ex_ranksystem && level.ex_rank_wmdtype) || level.ex_artillery == 2 || level.ex_cmdmonitor) registerWeapon("artillery_mp", "wmd", undefined, 0, "all", 15, &"WEAPON_ARTILLERY", 1);
	if((level.ex_ranksystem && level.ex_rank_wmdtype) || level.ex_planes == 3) registerWeapon("planebomb_mp", "wmd", undefined, 0, "all", 15, &"WEAPON_AIRSTRIKE", 0);

	// FT raygun
	if(level.ex_currentgt == "ft" && level.ft_raygun) registerWeapon("raygun_mp", "raygun", undefined, 0, "all", 15, &"WEAPON_RAYGUN", 0);

	// VIP pistols
	if(level.ex_currentgt == "vip" && level.vippistol)
	{
		if(level.ex_modern_weapons)
		{
			registerWeapon("hk45_vip_mp", "vip", undefined, 0, "axis", 4, &"WEAPON_HK45", 0);
			switch(game["allies"])
			{
				case "american": registerWeapon("deagle_vip_mp", "vip", undefined, 0, "allies", 1, &"WEAPON_DEAGLE", 0); break;
				case "british": registerWeapon("beretta_vip_mp", "vip", undefined, 0, "allies", 2, &"WEAPON_BERETTA", 0); break;
				case "russian": registerWeapon("glock_vip_mp", "vip", undefined, 0, "allies", 8, &"WEAPON_GLOCK", 0); break;
			}
		}
		else
		{
			registerWeapon("luger_vip_mp", "vip", undefined, 0, "axis", 4, &"WEAPON_LUGER", 0);
			switch(game["allies"])
			{
				case "american": registerWeapon("colt_vip_mp", "vip", undefined, 0, "allies", 1, &"WEAPON_COLT45", 0); break;
				case "british": registerWeapon("webley_vip_mp", "vip", undefined, 0, "allies", 2, &"WEAPON_WEBLEY", 0); break;
				case "russian": registerWeapon("tt30_vip_mp", "vip", undefined, 0, "allies", 8, &"WEAPON_TT30", 0); break;
			}
		}
	}
}

precacheWeapons()
{
	classname = undefined;
	allteamweapons = false;
	allmodernweapons = false;

	if(level.ex_modern_weapons)
	{
		switch(level.ex_wepo_class)
		{
			case 1: classname = "pistol"; break; // pistol only
			case 2: classname = "sniper"; break; // sniper only
			case 3: classname = "mg"; break; // mg only
			case 4: classname = "smg"; break; // smg only
			case 7: classname = "shotgun"; break; // shotgun only
			case 8: classname = "rl"; break; // rocket launcher only
			case 10: classname = "knife"; break; // knife only
			default: allmodernweapons = true; break; // all team weapons
		}
	}
	else if(!level.ex_all_weapons)
	{
		switch(level.ex_wepo_class)
		{
			case 1: classname = "pistol"; break; // pistol only
			case 2: classname = "sniper"; break; // sniper only
			case 3: classname = "mg"; break; // mg only
			case 4: classname = "smg"; break; // smg only
			case 5: classname = "rifle"; break; // rifle only
			case 6: classname = "boltrifle"; break; // bolt action rifle only
			case 7: classname = "shotgun"; break; // shotgun only
			case 8: classname = "rl"; break; // rocket launcher only
			case 9: classname = "boltsniper"; break; // bolt and sniper only
			case 10: classname = "knife"; break; // knife only
			default: allteamweapons = true; break; // all team weapons
		}
	}

	// precache the on hand weapons
	for(i = 0; i < level.weapons.size; i++)
	{
		weaponname = level.weaponnames[i];

		// skip if not a main weapon
		if((level.weapons[weaponname].status & 1) != 1) continue;

		// all ww2 weapons for allies and axis
		if(level.ex_all_weapons)
		{
			bridgePrecacheItem(weaponname);
		}
		// all modern weapons for allies and axis
		else if(level.ex_modern_weapons)
		{
			if(allmodernweapons || (level.ex_wepo_class && isWeaponType(weaponname, classname)))
				bridgePrecacheItem(weaponname);
		}
		// all team weapons for allies and axis
		else if(allteamweapons)
		{
			if(isWeaponType(weaponname, game["allies"]) || isWeaponType(weaponname, game["axis"]))
				bridgePrecacheItem(weaponname);
		}
		// weapon class (secondary system disabled)
		else
		{
			// team based, only precache weapons of this type that match the game allies and the game axis
			if(level.ex_wepo_team_only)
			{
				if(isWeaponType(weaponname, classname) && (isWeaponType(weaponname, game["allies"]) || isWeaponType(weaponname, game["axis"])))
					bridgePrecacheItem(weaponname);
			}
			// not team based so precache all weapons of this type
			else
			{
				if(isWeaponType(weaponname, classname)) bridgePrecacheItem(weaponname);
			}
		}
	}

	// if sidearm is allowed precache it
	if(level.ex_wepo_sidearm)
	{
		if(level.ex_currentgt == "ft" && level.ft_raygun)
		{
			// FreezeTag raygun
			[[level.ex_PrecacheItem]]("raygun_mp");
		}
		else
		{
			// pistols
			if(level.ex_wepo_sidearm_type == 0)
			{
				if(level.ex_modern_weapons)
				{
					switch(game["allies"])
					{
						case "american": sidearmtype = "deagle_mp"; break;
						case "british": sidearmtype = "beretta_mp"; break;
						default: sidearmtype = "glock_mp"; break;
					}

					[[level.ex_PrecacheItem]](sidearmtype);
					[[level.ex_PrecacheItem]]("hk45_mp");
				}
				else
				{
					switch(game["allies"])
					{
						case "american": sidearmtype = "colt_mp"; break;
						case "british": sidearmtype = "webley_mp"; break;
						default: sidearmtype = "tt30_mp"; break;
					}

					[[level.ex_PrecacheItem]](sidearmtype);
					[[level.ex_PrecacheItem]]("luger_mp");
				}
			}
			// knife
			else
			{
				if(level.ex_modern_weapons) [[level.ex_PrecacheItem]]("modern_knife_mp");
					else [[level.ex_PrecacheItem]]("knife_mp");
			}
		}
	}

	// precache the VIP pistols
	if(level.ex_currentgt == "vip" && level.vippistol)
	{
		if(level.ex_modern_weapons)
		{
			switch(game["allies"])
			{
				case "american": vippistol = "deagle_vip_mp"; break;
				case "british": vippistol = "beretta_vip_mp"; break;
				default: vippistol = "glock_vip_mp"; break;
			}

			[[level.ex_PrecacheItem]](vippistol);
			[[level.ex_PrecacheItem]]("hk45_vip_mp");
		}
		else
		{
			switch(game["allies"])
			{
				case "american": vippistol = "colt_vip_mp"; break;
				case "british": vippistol = "webley_vip_mp"; break;
				default: vippistol = "tt30_vip_mp"; break;
			}

			[[level.ex_PrecacheItem]](vippistol);
			[[level.ex_PrecacheItem]]("luger_vip_mp");
		}
	}

	// precache the frag grenades (off hand)
	if(!level.ex_wepo_precache_mode || getCvarInt("scr_allow_fraggrenades"))
	{
		if(level.ex_firenades)
			[[level.ex_PrecacheItem]]("fire_mp");
		else if(level.ex_gasnades)
			[[level.ex_PrecacheItem]]("gas_mp");
		else if(level.ex_satchelcharges)
			[[level.ex_PrecacheItem]]("satchel_mp");
		else
		{
			[[level.ex_PrecacheItem]]("frag_grenade_" + game["allies"] + "_mp");
			[[level.ex_PrecacheItem]]("frag_grenade_german_mp");
		}

		if(level.ex_mbot)
		{
			[[level.ex_PrecacheItem]]("frag_grenade_" + game["allies"] + "_bot");
			[[level.ex_PrecacheItem]]("frag_grenade_german_bot");
		}

		level.weapons["fraggrenade"].precached = 1;
	}

	// precache the smoke grenades (off hand)
	if(!level.ex_wepo_precache_mode || getCvarInt("scr_allow_smokegrenades"))
	{
		[[level.ex_PrecacheItem]]("smoke_grenade_" + game["allies"] + getSmokeColour(level.ex_smoke[game["allies"]]) + "mp");
		[[level.ex_PrecacheItem]]("smoke_grenade_german" + GetSmokeColour(level.ex_smoke["german"]) + "mp");

		if(level.ex_mbot)
		{
			[[level.ex_PrecacheItem]]("smoke_grenade_" + game["allies"] + "_bot");
			[[level.ex_PrecacheItem]]("smoke_grenade_german_bot");
		}

		level.weapons["smokegrenade"].precached = 1;
	}

	// placebo weapons for empty slots
	[[level.ex_PrecacheItem]]("dummy1_mp");
	[[level.ex_PrecacheItem]]("dummy2_mp");
	[[level.ex_PrecacheItem]]("dummy3_mp");

	// sprint system placebo weapon
	game["sprint"] = "sprint_mp";
	if(level.ex_sprint)
	{
		if(level.ex_sprint_level == 1) game["sprint"] = "sprint20_mp";
		else if(level.ex_sprint_level == 2) game["sprint"] = "sprint25_mp";
		else if(level.ex_sprint_level == 3) game["sprint"] = "sprint30_mp";
		else if(level.ex_sprint_level == 4) game["sprint"] = "sprint35_mp";
		[[level.ex_PrecacheItem]](game["sprint"]);
	}

	// mortar placebo weapon
	if(level.ex_ranksystem || level.ex_mortars) [[level.ex_PrecacheItem]]("mortar_mp");

	// artillery placebo weapon
	if(level.ex_ranksystem || level.ex_artillery || level.ex_cmdmonitor) [[level.ex_PrecacheItem]]("artillery_mp");

	// airstrike placebo weapons
	if(level.ex_ranksystem || level.ex_planes) [[level.ex_PrecacheItem]]("planebomb_mp");

	// landmine placebo weapon
	if(level.ex_landmines) [[level.ex_PrecacheItem]]("landmine_mp");

	// tripwire placebo weapon
	if(level.ex_tweapon) [[level.ex_PrecacheItem]]("tripwire_mp");

	// you look through these :)
	[[level.ex_PrecacheItem]]("binoculars_mp");

	// mbot placebo weapons
	if(level.ex_mbot)
	{
		[[level.ex_PrecacheItem]]("mantle_up_bot");
		[[level.ex_PrecacheItem]]("mantle_over_bot");
		[[level.ex_PrecacheItem]]("climb_up_bot");
		[[level.ex_PrecacheItem]]("jump_bot");
	}

	// gunship
	if(level.ex_gunship || level.ex_gunship_special)
	{
		if(level.ex_gunship_25mm) [[level.ex_PrecacheItem]]("gunship_25mm_mp");
		if(level.ex_gunship_40mm) [[level.ex_PrecacheItem]]("gunship_40mm_mp");
		if(level.ex_gunship_105mm) [[level.ex_PrecacheItem]]("gunship_105mm_mp");
		if(level.ex_gunship_nuke) [[level.ex_PrecacheItem]]("gunship_nuke_mp");
	}

	// unfix turrets
	if(level.ex_turrets > 1)
	{
		[[level.ex_PrecacheItem]]("30cal_duck_mp");
		[[level.ex_PrecacheItem]]("30cal_prone_mp");
		[[level.ex_PrecacheItem]]("30cal_stand_mp");
		[[level.ex_PrecacheItem]]("mg42_bipod_duck_mp");
		[[level.ex_PrecacheItem]]("mg42_bipod_prone_mp");
		[[level.ex_PrecacheItem]]("mg42_bipod_stand_mp");
	}

	// flamethrower tank (not a weapon!)
	if(!level.ex_wepo_precache_mode || (getWeaponStatus("flamethrower_axis") || getWeaponStatus("flamethrower_allies")))
		[[level.ex_PrecacheModel]]("xmodel/ft_tank");
}

bridgePrecacheItem(weaponname)
{
	precache = 1;
	if(level.ex_wepo_precache_mode) precache = getWeaponStatus(weaponname);
	if(precache)
	{
		[[level.ex_PrecacheItem]](weaponname);

		// load longrange equivalent if enabled
		if(level.ex_longrange && level.weapons[weaponname].classname == "sniper")
		{
			counterpart = extreme\_ex_longrange::getWeaponCounterpart(weaponname, false);
			if(counterpart != "none") [[level.ex_PrecacheItem]](counterpart);
		}

		// load weapon on back model if wob flag is set
		if(level.ex_weaponsonback && (level.weapons[weaponname].status & 4) == 4)
			[[level.ex_PrecacheModel]]("xmodel/" + weaponname);

		// optionally load mbot weapon
		if(level.ex_mbot && (level.weapons[weaponname].status & 8) == 8)
		{
			counterpart = getMBotWeapon(weaponname);
			if(counterpart != "dummy1_mp") [[level.ex_PrecacheItem]](counterpart);
		}
	}
}

getMBotWeapon(weapon)
{
	// mbot weapons which are always available
	if(level.ex_modern_weapons)
	{
		switch(weapon)
		{
			case "auga3_mp": return "auga3_bot";
			case "mp5_mp": return "mp5_bot";
			case "p90_mp": return "p90_bot";
		}
	}
	else
	{
		switch(weapon)
		{
			case "mp40_mp": return "mp40_bot";
			case "ppsh_mp": return "ppsh_bot";
			case "thompson_mp": return "thompson_bot";
		}
	}

	// Stop here if "all weapons" mode OR not a weapon class AND gunship enabled
	// due to game engine limit for precached weapons (PrecacheItem)
	if(level.ex_all_weapons || (!level.ex_wepo_class && (level.ex_gunship || level.ex_gunship_special)) ) return "dummy1_mp";

	// mbot weapons which are only available for weapon classes
	if(level.ex_modern_weapons)
	{
		switch(weapon)
		{
			case "ak47_mp": return "ak47_bot";
			case "ak74_mp": return "ak74_bot";
			case "ar10_mp": return "ar10_bot"; // sniper
			case "barrett_mp": return "barrett_bot"; // sniper
			case "dragunov_mp": return "dragunov_bot"; // sniper
			case "famas_mp": return "famas_bot";
			case "galil_mp": return "galil_bot";
			case "hk21_mp": return "hk21_bot";
			case "m40a3_mp": return "m40a3_bot"; // sniper
			case "m4a1_mp": return "m4a1_bot";
			case "m8a1_mp": return "m8a1_bot";
			case "mp7a2_mp": return "mp7a2_bot";
			case "mtar_mp": return "mtar_bot";
			case "sg552_mp": return "sg552_bot";
			case "spas12_mp": return "spas12_bot";
			case "ump45_mp": return "ump45_bot";
			case "xm1014_mp": return "xm1014_bot";
			case "xm8_mp": return "xm8_bot";
		}
	}
	else
	{
		switch(weapon)
		{
			case "bar_mp": return "bar_bot";
			case "bren_mp": return "bren_bot";
			case "dp28_mp": return "dp28_bot";
			case "enfield_mp": return "enfield_bot";
			case "enfield_scope_mp": return "enfield_scope_bot";
			case "flamethrower_allies": return "flamethrower_allies_bot";
			case "flamethrower_axis": return "flamethrower_axis_bot";
			case "g43_mp": return "g43_bot";
			case "g43_sniper": return "g43_sniper_bot";
			case "greasegun_mp": return "greasegun_bot";
			case "kar98k_mp": return "kar98k_bot";
			case "kar98k_sniper_mp": return "kar98k_sniper_bot";
			case "m1carbine_mp": return "m1carbine_bot";
			case "m1garand_mp": return "m1garand_bot";
			case "mobile_30cal": return "mobile_30cal_bot";
			case "mobile_mg42": return "mobile_mg42_bot";
			case "mosin_nagant_mp": return "mosin_nagant_bot";
			case "mosin_nagant_sniper_mp": return "mosin_nagant_sniper_bot";
			case "mp44_mp": return "mp44_bot";
			case "panzerfaust_mp": return "panzerfaust_bot";
			case "panzerschreck_allies": return "panzerschreck_allies_bot";
			case "panzerschreck_mp": return "panzerschreck_bot";
			case "pps42_mp": return "pps42_bot";
			case "shotgun_mp": return "shotgun_bot";
			case "springfield_mp": return "springfield_bot";
			case "sten_mp": return "sten_bot";
			case "svt40_mp": return "svt40_bot";
		}
	}

	// If unknown weapon, return dummy weapon.
	// Dummies are always precached anyway, and the botJoin code will automatically skip it
	return "dummy1_mp";
}
