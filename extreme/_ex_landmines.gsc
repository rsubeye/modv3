#include extreme\_ex_hudcontroller;

init()
{
	mineDelete(-1);

	level.mine_identifier = 0;
	if(level.ex_landmine_bb) level.mine_trip_distance = 30;
		else level.mine_trip_distance = 20;
	level.mine_defuse_distance = level.mine_trip_distance + 30;
	level.mine_warn_distance = level.mine_trip_distance + 130;
}

giveLandmines()
{
	self endon("disconnect");

	if(level.ex_landmines_loadout) self.mine_ammo_max = getRankBasedMineCount(self.pers["rank"]);
		else self.mine_ammo_max = getWeaponBasedMineCount(self.pers["weapon"]);
	self.mine_ammo = self.mine_ammo_max;

	if(!isDefined(self.ex_moving)) self.ex_moving = false;
	self.mine_inrange = 0;
	self.handling_mine = 0;
	self.mine_plantprotection = 0;

	// mbots do not get landmines
	if(level.ex_mbot && isDefined(self.pers["isbot"]))
	{
		self.mine_ammo = 0;
		return;
	}

	if(self.mine_ammo) self thread minePlantMonitor();
}

updateLandmines(landmines)
{
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return;

	plantMonitorIsRunning = self.mine_ammo;
	self.mine_ammo_max = landmines;
	self.mine_ammo = self.mine_ammo_max;
	if(!plantMonitorIsRunning) self thread minePlantMonitor();
		else self thread mineShowHUD();
}

mineShowHUD()
{
	//  frag 20x20:
	//		icon(-42, -75), "right", "bottom", "left", "top"
	//		ammo(-20, -57), "right", "bottom", "left", "bottom"
	// smoke 20x20:
	//		icon(-42,-100), "right", "bottom", "left", "top"
	//		ammo(-20, -82), "right", "bottom", "left", "bottom"
	//  medi 20x20
	//		icon(-42,-125), "right", "bottom", "left", "top"
	//		ammo(-20,-107), "right", "bottom", "left", "bottom"
	//  mine 20x20
	//		icon(-42,-150), "right", "bottom", "left", "top"
	//		ammo(-20,-132), "right", "bottom", "left", "bottom"

	if(level.ex_medicsystem) iconY = -150;
		else iconY = -125;
	ammoY = iconY + 18;
	
	if(self.mine_ammo == 0) ammo_color = (1, 0, 0);
		else ammo_color = (1, 1, 1);

	// HUD landmine icon
	hud_index = playerHudIndex("landmine_icon");
	if(hud_index == -1) hud_index = playerHudCreate("landmine_icon", -42, iconY, 1, (1,1,1), 1, 0, "right", "bottom", "left", "top", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, "mtl_weapon_bbetty_hud", 20, 20);

	// HUD landmine ammo
	hud_index = playerHudIndex("landmine_ammo");
	if(hud_index == -1) hud_index = playerHudCreate("landmine_ammo", -20, ammoY, 1, ammo_color, 1, 0, "right", "bottom", "left", "bottom", false, true);
	if(hud_index != -1)
	{
		playerHudSetColor(hud_index, ammo_color);
		playerHudSetValue(hud_index, self.mine_ammo);
	}
}

minePlantMonitor()
{
	self endon("kill_thread");

	self thread mineShowHUD();

	while(self.mine_ammo)
	{
		timer = 0;
		while(self stanceOK(2) && !self.ex_moving && self useButtonPressed())
		{
			// prevent mine plant hysteria
			if(timer < .5)
			{
				timer = timer + .05;
				wait( level.ex_fps_frame );
				continue;
			}

			// prevent planting while defusing
			if(self.mine_inrange || self.handling_mine) break;

			// prevent planting while healing (crouched shellshock position is detected as prone).
			// wait till healing is over and player releases USE button
			if(isDefined(self.ex_ishealing))
			{
				while(isDefined(self.ex_ishealing)) wait( level.ex_fps_frame );
				while(self useButtonPressed()) wait( level.ex_fps_frame );
				break;
			}

			// prevent planting landmine while planting or defusing bomb in SD or ESD
			if(isDefined(self.ex_planting) || isDefined(self.ex_defusing)) break;

			// prevent planting too close to special entities
			if(self extreme\_ex_utils::tooClose(level.ex_mindist["landmines"][0], level.ex_mindist["landmines"][1], level.ex_mindist["landmines"][2], level.ex_mindist["landmines"][3])) break;

			// prevent planting while being frozen in freezetag
			if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") break;

			// double check stance
			if(!self stanceOK(2)) break;

			// check for correct surface type
			plant = self getPlant();
			if(level.ex_landmine_surfacecheck && !allowedSurface(plant.origin))
			{
				self iprintln(&"LANDMINES_WRONG_SURFACE");
				break;
			}

			// check if free slot available
			if(!(self mineCount(false) < level.ex_landmines_max) && !level.ex_landmines_fifo)
			{
				self iprintln(&"LANDMINES_MAXIMUM");
				break;
			}

			self.handling_mine = 1;
			playerHudSetAlpha("tripwire_msg", 0);

			self playsound("moody_plant");
			self.mine_plant_sitstill = spawn("script_origin", self.origin);
			self linkTo(self.mine_plant_sitstill);
			self [[level.ex_dWeapon]]();

			playerHudCreateBar(level.ex_landmine_plant_time, &"LANDMINES_PLANTING", false);

			count = 0;
			while(isAlive(self) && self useButtonPressed() && self stanceOK(2))
			{
				wait( level.ex_fps_frame );
				count += level.ex_fps_frame;
				if(count >= level.ex_landmine_plant_time) break;
			}

			playerHudDestroyBar();

			if(count >= level.ex_landmine_plant_time)
			{
				self thread mineDrop(plant);
				self iprintln(&"LANDMINES_PLANTED");

				self.mine_ammo--;
				self thread mineShowHUD();
			}

			self unlink();
			self [[level.ex_eWeapon]]();
			if(isDefined(self.mine_plant_sitstill)) self.mine_plant_sitstill delete();

			while(isAlive(self) && self useButtonPressed()) wait( level.ex_fps_frame );

			self.handling_mine = 0;
			playerHudSetAlpha("tripwire_msg", 1);

			if(!self.mine_ammo) break;

			timer = 0;
			wait( level.ex_fps_frame );
		}

		wait( [[level.ex_fpstime]](0.1) );
	}

	self thread mineShowHUD();
}

mineDrop(plant)
{
	if(!isDefined(self)) return;

	level.mine_identifier++;
	self.mine_plantprotection = level.mine_identifier;

	item_mine = spawn("script_model", plant.origin - (0, 0, level.ex_landmine_depth));
	item_mine hide();
	item_mine.angles = plant.angles;
	item_mine.identifier = level.mine_identifier; // set custom vars before assigning targetname
	item_mine.blow = false;
	item_mine.being_defused = 0;
	item_mine.owner = self;
	item_mine.team = self.pers["team"];
	item_mine setModel("xmodel/weapon_bbetty");
	item_mine.targetname = "item_mine";
	item_mine show();

	// check if planted mines exceed maximum now
	self thread MineCheckMax();

	self playsound("weap_fraggrenade_pin");
	wait( [[level.ex_fpstime]](0.15) );
	self playsound("weap_fraggrenade_pin");

	item_mine thread mineThink();
}

mineThink()
{
	self endon("kill_think");

	while(true)
	{
		if(!isDefined(self)) return;
		if(self.blow) break;
		wait( [[level.ex_fpstime]](0.2) );

		// delete mines from player who left or switched to spectators
		if(!isPlayer(self.owner) || (level.ex_teamplay && self.owner.pers["team"] != self.team))
		{
			self thread mineDeleteSelf();
			return;
		}

		mine_origin = self.origin;
		mine_owner = self.owner;
		mine_team = self.team;
		mine_identifier = self.identifier;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player) || player.sessionstate != "playing") continue;
			if(!isDefined(self)) return;
			if(self.blow) break;

			// would it trigger on player?
			mine_wouldtrip = true;
			switch(level.ex_landmines)
			{
				case 2: if(player == mine_owner) mine_wouldtrip = false; break;
				case 3: if(player == mine_owner || (level.ex_teamplay && player.pers["team"] == mine_team)) mine_wouldtrip = false; break;
			}

			// owner plant protection
			if(mine_identifier == player.mine_plantprotection) mine_wouldtrip = false;

			// is player in trip range?
			mine_trip = false;
			mine_dist = int(distance(mine_origin, player.origin));
			if(mine_dist < level.mine_trip_distance)
			{
				// player is jumping over the landmine?
				// mbots do not always pass the isOnGround test, so skip this test for them
				if(!isDefined(player.pers["isbot"]) && player isOnGround()) mine_trip = mine_wouldtrip;
			}

			if(!mine_trip)
			{
				mine_defuse = false;
				mine_danger = false;
				// is player in warn range?
				if(mine_dist < level.mine_warn_distance)
				{
					// is player in defuse range?
					if(level.ex_landmines_defuse && mine_dist < level.mine_defuse_distance)
					{
						if(!player.handling_mine && !player.ex_moving && player stanceOK(3))
						{
							if(level.ex_teamplay)
							{
								switch(level.ex_landmines_defuse)
								{
									case 1: if(player == mine_owner) mine_defuse = true; break;
									case 2:	if(player == mine_owner || player.pers["team"] == mine_team) mine_defuse = true; break;
									case 3:	if(player == mine_owner || player.pers["team"] != mine_team) mine_defuse = true; break;
									case 4: mine_defuse = true; break;
								}
							}
							else
							{
								switch(level.ex_landmines_defuse)
								{
									case 1:
									case 2: if(player == mine_owner) mine_defuse = true; break;
									case 3:
									case 4: mine_defuse = true; break;
								}
							}
						}
					}

					// Check if we should show the danger warning
					if(mine_wouldtrip && level.ex_landmine_warning)
					{
						if(level.ex_teamplay)
						{
							switch(level.ex_landmine_warning)
							{
								case 1: if(player == mine_owner || player.pers["team"] == mine_team) mine_danger = true; break;
								case 2: mine_danger = true; break;
							}
						}
						else mine_danger = true;
					}
				}
				else if(mine_identifier == player.mine_plantprotection) player.mine_plantprotection = 0;

				if(mine_defuse)
				{
					player.mine_inrange = 1;

					if(!player.handling_mine && !player.ex_moving && player stanceOK(3))
					{
						//if(level.ex_landmine_warning) player notify("landmine_danger" + mine_identifier);
						hud_index = player playerHudIndex("landmine_defuse");
						if(hud_index == -1)
						{
							hud_index = player playerHudCreate("landmine_defuse", 0, level.hudBarY, 1, (1,0,0), 1, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
							if(hud_index != -1) player playerHudSetText(hud_index, &"LANDMINES_DEFUSE");
						}

						if(player useButtonPressed()) player thread mineDefuse(self);
					}
				}
				else
				{
					player.mine_inrange = 0;

					player playerHudDestroy("landmine_defuse");
					if(mine_danger) player thread mineWarning("landmine_danger" + mine_identifier, mine_origin);
						else player notify("landmine_danger" + mine_identifier);
				}
			}
			else self.blow = true;
		}
	}

	self thread mineBlow();
}

mineBlow()
{
	self playsound ("minefield_click");

	if(level.ex_landmine_bb) self movez(60, 0.4, 0, 0.3);
	wait( [[level.ex_fpstime]](0.5) );

	if(isDefined(self))
	{
		self hide();
		level notify("landmine_danger" + self.identifier);

		self playsound("explo_mine");
		playfx(level.ex_effect["landmine_explosion"], self getorigin());

		if(isPlayer(self.owner)) eAttacker = self.owner;
			else eAttacker = self;

		if(level.ex_landmine_bb) self extreme\_ex_utils::scriptedfxradiusdamage(eAttacker, undefined, "MOD_EXPLOSIVE", "landmine_mp", 400, 600, 400, "none", undefined, true, true, true);
			else self extreme\_ex_utils::scriptedfxradiusdamage(eAttacker, undefined, "MOD_EXPLOSIVE", "landmine_mp", 300, 600, 400, "none", undefined, true, true, true);

		wait( [[level.ex_fpstime]](0.25) );
		if(isDefined(self))
		{
			origin = self.origin;
			if(isDefined(self.linkedplayer) && isPlayer(self.linkedplayer) && isAlive(self.linkedplayer)) mineReleasePlayer(self.linkedplayer);

			self delete();

			thread checkProximityLandmines(origin, level.ex_landmine_cpx);
			thread extreme\_ex_tripwires::checkProximityTrips(origin, level.ex_landmine_cpx);
			thread extreme\_ex_specials_sentrygun::checkProximitySentryGuns(origin, eAttacker, level.ex_landmine_cpx);
		}
	}
}

mineWarning(name, origin)
{
	self endon("kill_thread");

	hud_index = playerHudIndex(name);
	if(hud_index != -1) return;

	// the name of the HUD element must be the same as the notification to destroy it
	self thread mineWarningDestroyer(name);

	hud_index = playerHudCreate(name, origin[0], origin[1], 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "killiconsuicide", 7, 7);
	playerHudSetWaypoint(hud_index, origin[2] + 30, true);
}

mineWarningDestroyer(notification)
{
	self endon("kill_thread");

	ent = spawnstruct();
	self thread mineNotification(notification, true, ent);
	self thread mineNotification(notification, false, ent);
	ent waittill("returned");

	ent notify("die");
	self playerHudDestroy(notification);
}

mineNotification(notification, islevel, ent)
{
	self endon("kill_thread");
	ent endon("die");

	if(isLevel) level waittill(notification);
		else self waittill(notification);

	ent notify("returned");
}

mineDefuse(mine)
{
	self endon("kill_thread");

	self.handling_mine = 1;
	mine.being_defused = 1;
	playerHudSetAlpha("tripwire_msg", 0);

	// remember player so we can unlink and clean up the HUD when the landmine blows without
	// killing the player
	mine.linkedplayer = self;

	//self playsound("MP_bomb_defuse");
	self playsound("moody_plant");
	self linkTo(mine);
	self [[level.ex_dWeapon]]();

	playerHudCreateBar(level.ex_landmine_defuse_time, &"LANDMINES_DEFUSING", true);

	count = 0;
	while(isDefined(mine) && isAlive(self) && self useButtonPressed() && self stanceOK(3))
	{
		wait( level.ex_fps_frame );
		count += level.ex_fps_frame;
		if(count >= level.ex_landmine_defuse_time) break;
	}

	playerHudDestroyBar();

	if(count >= level.ex_landmine_defuse_time && isDefined(mine))
	{
		playerHudDestroy("landmine_defuse");

		if(level.ex_reward_landmine)
		{
			if( (!level.ex_teamplay && mine.owner != self) || (level.ex_teamplay && mine.team != self.pers["team"]) )
				self thread [[level.pscoreproc]](level.ex_reward_landmine, "bonus");
		}

		self iprintln(&"LANDMINES_DEFUSED");

		mine notify("kill_think");
		level notify("landmine_danger" + mine.identifier);
		mine delete();

		if(self.mine_ammo < self.mine_ammo_max)
		{
			self.mine_ammo++;
			if(self.mine_ammo == 1) self thread minePlantMonitor();
			self thread mineShowHUD();
		}
	}
	else if(isDefined(mine))
	{
		mine.linkedplayer = undefined;
		mine.being_defused = 0;
	}

	self unlink();
	self [[level.ex_eWeapon]]();
	playerHudSetAlpha("tripwire_msg", 1);

	while(isAlive(self) && self useButtonPressed()) wait( level.ex_fps_frame );
	self.handling_mine = 0;
	self.mine_inrange = 0;
}

mineReleasePlayer(player)
{
	playerHudDestroyBar();

	player unlink();
	player [[level.ex_eWeapon]]();
	player.handling_mine = 0;
	playerHudSetAlpha("tripwire_msg", 1);
}

checkProximityLandmines(origin, cpx)
{
	if(level.ex_landmines && level.ex_landmine_cpx)
	{
		mines = getentarray("item_mine", "targetname");
		for(i = 0; i < mines.size; i++)
		{
			mine = mines[i];
			if(!isDefined(mine)) continue;

			origin1 = mine.origin;
			cond_dist = (distance(origin, origin1) <= cpx);
			if(cond_dist) mine.blow = true;
		}
	}
}

// check max amount of mines for player (DM style game) or team (team based game)
mineCheckMax()
{
	oldestMine = self mineCount(true);
	if(oldestMine != 0) mineDelete(oldestMine);
}

// return number of mines (parameter set to FALSE) or oldest mine (parameter set to TRUE)
// for player (DM style game) or team (team based game)
mineCount(returnOldestMine)
{
	ownMines = 0;
	oldestMine = 9999;
	mines = getentarray("item_mine", "targetname");
	for(i = 0; i < mines.size; i++)
	{
		if(isDefined(mines[i]) && isDefined(self))
		{
			if( (!level.ex_teamplay && mines[i].owner == self) || (level.ex_teamplay && mines[i].team == self.pers["team"]) )
			{
				ownMines++;
				if(mines[i].identifier < oldestMine) oldestMine = mines[i].identifier;
			}
		}
	}

	if(returnOldestMine)
	{
		if(ownMines > level.ex_landmines_max) return(oldestMine);
			else return(0);
	}
	else return(ownMines);
}

// delete mine with specific identifier, or all mines if identifier is -1
mineDelete(identifier)
{
	mines = getentarray("item_mine", "targetname");
	for(i = 0; i < mines.size; i++)
	{
		if(isDefined(mines[i]) && (mines[i].identifier == identifier || identifier == -1))
		{
			if(mines[i].blow) continue;
			mines[i] notify("kill_think");
			level notify("landmine_danger" + mines[i].identifier);
			mines[i] delete();
		}
	}
}

// delete mine
mineDeleteSelf()
{
	self notify("kill_think");
	level notify("landmine_danger" + self.identifier);
	self delete();
}

// check if stance is allowed: 0 = stand, 1 = crouch, 2 = prone, 3 = crouch or prone
StanceOK(allowedstance)
{
	stance = self [[level.ex_getstance]](false);

	if(allowedstance == 1 && stance == 1) return(true);
		else if(allowedstance == 2 && stance == 2) return(true);
			else if(allowedstance == 3 && (stance == 1 || stance == 2)) return(true);

	return(false);
}

getWeaponBasedMineCount(weapon)
{
	if(extreme\_ex_weapons::isWeaponType(weapon, "boltrifle")) return(level.ex_allow_mine_boltrifle);
	if(!isDefined(level.weapons[weapon])) return(0);

	switch(level.weapons[weapon].classname)
	{
		case "sniper": return(level.ex_allow_mine_sniper);
		case "rifle": return(level.ex_allow_mine_rifle);
		case "smg": return(level.ex_allow_mine_smg);
		case "mg": return(level.ex_allow_mine_mg);
		case "shotgun": return(level.ex_allow_mine_shotgun);
		default: return(0);
	}
}

getRankBasedMineCount(rank)
{
	return(game["rank_ammo_landmines_" + rank]);
}

getPlant()
{
	start = self.origin + (0, 0, 10);

	range = 32;
	forward = anglesToForward(self.angles);
	forward = maps\mp\_utility::vectorScale(forward, range);

	traceorigins[0] = start + forward;
	traceorigins[1] = start;

	trace = bulletTrace(traceorigins[0], (traceorigins[0] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return(temp);
	}

	trace = bulletTrace(traceorigins[1], (traceorigins[1] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return(temp);
	}

	traceorigins[2] = start + (16, 16, 0);
	traceorigins[3] = start + (16, -16, 0);
	traceorigins[4] = start + (-16, -16, 0);
	traceorigins[5] = start + (-16, 16, 0);

	besttracefraction = undefined;
	besttraceposition = undefined;
	for(i = 0; i < traceorigins.size; i++)
	{
		trace = bulletTrace(traceorigins[i], (traceorigins[i] + (0, 0, -1000)), false, undefined);

		if(!isDefined(besttracefraction) || (trace["fraction"] < besttracefraction))
		{
			besttracefraction = trace["fraction"];
			besttraceposition = trace["position"];
		}
	}
	
	if(besttracefraction == 1)
		besttraceposition = self.origin;
	
	temp = spawnstruct();
	temp.origin = besttraceposition;
	temp.angles = orientToNormal(trace["normal"]);
	return(temp);
}

orientToNormal(normal)
{
	hor_normal = (normal[0], normal[1], 0);
	hor_length = length(hor_normal);

	if(!hor_length) return(0, 0, 0);
	
	hor_dir = vectornormalize(hor_normal);
	neg_height = normal[2] * -1;
	tangent = (hor_dir[0] * neg_height, hor_dir[1] * neg_height, hor_length);
	plant_angle = vectortoangles(tangent);

	return(plant_angle);
}

allowedSurface(plantPos)
{
	startOrigin = plantPos + (0, 0, 100);
	endOrigin = plantPos + (0, 0, -2048);

	trace = bulletTrace(startOrigin, endOrigin, true, undefined);
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
		case "snow": return(true);
	}

	return(false);
}
