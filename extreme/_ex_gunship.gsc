#include extreme\_ex_hudcontroller;

main()
{
	level.ex_gunship_attachz = 200;
	level.crashing_gunships = [];

	if(level.ex_gunship)
	{
		level.gunship = spawn("script_model", (0,0,0));
		if(level.ex_gunship_visible <= 1) level.gunship hide();
		level.gunship setmodel("xmodel/vehicle_condor");
		level.gunship linkTo(level.rotation_rig, "tag_0", (level.rotation_rig.maxradius,0,0), (0,90,-20));
		if(level.ex_gunship_ambientsound == 2) level.gunship playloopsound("gunship_ambient");

		level.gunship.health = level.ex_gunship_maxhealth;
		level.gunship.team = "none";
		level.gunship.owner = level.gunship;
	}

	if(level.ex_gunship_special)
	{
		level.gunship_special = spawn("script_model", (0,0,0));
		if(level.ex_gunship_visible <= 1) level.gunship_special hide();
		level.gunship_special setmodel("xmodel/vehicle_condor");
		level.gunship_special linkTo(level.rotation_rig, "tag_180", (level.rotation_rig.maxradius,0,0), (0,90,-20));
		if(level.ex_gunship_ambientsound == 2) level.gunship_special playloopsound("gunship_ambient");

		level.gunship_special.health = level.ex_gunship_maxhealth;
		level.gunship_special.team = "none";
		level.gunship_special.owner = level.gunship_special;
	}

	rotations = 0;
	while(!level.ex_gameover)
	{
		wait( [[level.ex_fpstime]](level.rotation_rig.rotationspeed) );

		if(level.ex_gunship && isPlayer(level.gunship.owner))
		{
			player_z = int(level.gunship.owner.origin[2] + level.ex_gunship_attachz + 0.5);
			gunship_z = int(level.gunship.origin[2] + 0.5);

			if(player_z != gunship_z)
			{
				if(level.ex_gunship_visible == 1) level.gunship hide();
				if(level.ex_gunship_ambientsound == 1) level.gunship stoploopsound();
				level.gunship.owner show();
				level.gunship.owner = level.gunship;
			}
		}

		if(level.ex_gunship_special && isPlayer(level.gunship_special.owner))
		{
			player_z = int(level.gunship_special.owner.origin[2] + level.ex_gunship_attachz + 0.5);
			gunship_z = int(level.gunship_special.origin[2] + 0.5);

			if(player_z != gunship_z)
			{
				if(level.ex_gunship_visible == 1) level.gunship_special hide();
				if(level.ex_gunship_ambientsound == 1) level.gunship_special stoploopsound();
				level.gunship_special.owner show();
				level.gunship_special.owner = level.gunship_special;
			}
		}

		rotations++;
		if(rotations == level.ex_gunship_advertise)
		{
			rotations = 0;
			level thread gunshipAdvertise();
		}
	}

	if(level.ex_gunship)
	{
		level.gunship hide();
		if(level.ex_gunship_ambientsound) level.gunship stoploopsound();
	}

	if(level.ex_gunship_special)
	{
		level.gunship_special hide();
		if(level.ex_gunship_ambientsound) level.gunship_special stoploopsound();
	}
}

/*******************************************************************************
VALIDATION
*******************************************************************************/
gunshipValidateAsTarget(team)
{
	if(!level.ex_gunship || level.ex_gunship_protect == 1) return(false);
	if(!isPlayer(level.gunship.owner) || (level.ex_teamplay && level.gunship.team == team)) return(false);
	if(level.gunship.health <= 0) return(false);
	return(true);
}

/*******************************************************************************
PERK ASSIGNMENT
*******************************************************************************/
gunshipPerk(delay)
{
	self endon("kill_thread");

	if(!isDefined(self.ex_gunship)) self.ex_gunship = false;
	if(self.ex_gunship) return;

	if(isPlayer(level.gunship.owner) && level.gunship.owner == self) return;

	self notify("end_gunship");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_gunship");

	self.ex_gunship = true;

	if(level.ex_ranksystem)
	{
		if(level.ex_gunship == 2)
		{
			if(!isDefined(delay)) delay = level.ex_rank_gunship_first;
			wait( [[level.ex_fpstime]](delay) );
		}
		else
		{
			while(isDefined(self.ex_checkingwmd)) wait( [[level.ex_fpstime]](0.05) );
			wait( [[level.ex_fpstime]](1) );
			self extreme\_ex_ranksystem::wmdStop();
		}
	}

	while(self.ex_gunship)
	{
		while(level.ex_specials && extreme\_ex_specials::playerPerkIsLocked("stealth", false)) wait( [[level.ex_fpstime]](1) );

		arcade = (level.ex_gunship == 1 && (level.ex_arcade_shaders & 1) == 1) || (level.ex_gunship == 2 && (level.ex_arcade_shaders & 4) == 4) || (level.ex_gunship == 3 && (level.ex_arcade_shaders & 2) == 2);
		if(arcade) self thread extreme\_ex_arcade::showArcadeShader("x2_gunshipunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"GUNSHIP_READY");

		playerHudCreateIcon("wmd_icon", 120, 390, game["wmd_gunship_hudicon"]);
		self thread playerHudAnnounce(&"WMD_ACTIVATE_HINT");
		self thread waitForBinocEnter();

		self waittill("gunship_over");

		if(level.ex_gunship == 2)
		{
			if(level.ex_rank_gunship_next) wait( [[level.ex_fpstime]](level.ex_rank_gunship_next) );
			else
			{
				wait( [[level.ex_fpstime]](level.ex_rank_airstrike_next) );
				break;
			}
		}
		else break;
	}

	self.ex_gunship = false;
}

gunshipBoard()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](randomFloat(0.5)) );

	if(isPlayer(level.gunship.owner))
	{
		self iprintlnbold(&"GUNSHIP_OCCUPIED");
		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		self.ex_callingwmd = false;
		return;
	}

	if(level.ex_flagbased && isDefined(self.flag))
	{
		self iprintlnbold(&"GUNSHIP_FLAGCARRIER");
		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		self.ex_callingwmd = false;
		return;
	}

	self notify("end_binoc");
	playerHudDestroy("wmd_icon");
	self.usedweapons = true;
	self thread gunshipAttachPlayer();
	self.ex_callingwmd = false;
}

waitForBinocEnter()
{
	self endon("kill_thread");
	self endon("end_gunship");
	self endon("end_binoc");

	self.ex_callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.ex_callingwmd)
		{
			self thread waitForBinocUse();
			self thread playerHudAnnounce(&"WMD_GUNSHIP_HINT");
		}
	}
}

waitForBinocUse()
{
	self endon("kill_thread");
	self endon("binocular_exit");
	self endon("end_binoc");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed() && !self.ex_callingwmd)
		{
			self.ex_callingwmd = true;
			self thread gunshipBoard();
		}
		wait( [[level.ex_fpstime]](0.05) );
	}
}

/*******************************************************************************
GUNSHIP ASSIGNMENT PROCEDURES
*******************************************************************************/
gunshipAttachPlayer()
{
	self endon("kill_thread");

	if(isPlayer(level.gunship.owner)) return;
	level.gunship.owner = self;
	level.gunship.team = self.pers["team"];
	level.gunship.health = level.ex_gunship_maxhealth;
	self.pers["gunship"] = true;

	self extreme\_ex_utils::forceto("stand");
	self.gunship_org_origin = self.origin;
	self.gunship_org_angles = self.angles;

	self.ex_stopwepmon = true;
	wait( [[level.ex_fpstime]](0.1) );
	self notify("weaponsave");
	self waittill("weaponsaved");

	if(level.ex_gunship_airraid) level.rotation_rig playsound("air_raid");
	if(level.ex_gunship_visible == 1) level.gunship show();
	if(level.ex_gunship_ambientsound == 1) level.gunship playloopsound("gunship_ambient");

	self.ex_gunship_ejected = false;
	playerHudSetStatusIcon("gunship_statusicon");
	if(level.ex_gunship == 1) self.pers["conseckill"] = 0;
	if(level.ex_gunship == 3) self.pers["conskillnumb"] = 0;
	if(level.ex_gunship_health) self.health = self.maxhealth;
	self.ex_gunship_kills = 0;
	self hide();
	self linkTo(level.rotation_rig, "tag_0", (level.rotation_rig.maxradius,0,0-level.ex_gunship_attachz), (0,0,0));
	self.dont_auto_balance = true;

	level thread gunshipTimer(self);
	if(level.ex_gunship_inform) self thread gunshipInform(true);
	if(level.ex_gunship_clock) self thread gunshipClock();
	self thread gunshipWeapon();
	if(level.ex_gunship_cm) self thread gunshipCounterMeasures();
}

gunshipTimer(player)
{
	player endon("gunship_over");

	gunship_time = level.ex_gunship_time;
	while(gunship_time > 0 && !level.ex_gameover)
	{
		wait( [[level.ex_fpstime]](1) );
		gunship_time--;

		// keep an eye on the player
		if(!isPlayer(player))
		{
			level thread gunshipDetachPlayerLevel(player, true);
			return;
		}

		// crash if health dropped to 0
		if(level.gunship.health <= 0)
		{
			level thread gunshipCrash();
			return;
		}
	}

	if(isPlayer(player))
	{
		// player is still there, and has a valid ticket
		if(isPlayer(level.gunship.owner))
		{
			if(level.gunship.owner == player)
			{
				if(!level.ex_gameover && (level.ex_gunship_eject & 1) == 1) player thread gunshipDetachPlayer(true);
					else player thread gunshipDetachPlayer();
			}
		}
		// player is still there, but seems to be in gunship without a valid ticket
		else if(player.origin[2] + level.ex_gunship_attachz == level.gunship.origin[2])
		{
			if(!level.ex_gameover) player thread gunshipDetachPlayer(false, true);
				else level thread gunshipDetachPlayerLevel(player, true);
		}
	}
}

gunshipDetachPlayer(eject, skipcheck)
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isPlayer(level.gunship.owner) || !isPlayer(self) || level.gunship.owner != self)) return;

	if(!isDefined(eject)) eject = false;
	if(self.ex_gunship_ejected) return;
	if(eject) self.ex_gunship_ejected = true;

	self notify("gunship_over");
	if(isDefined(self.ex_gunship_weapons)) self.ex_gunship_weapons = [];
	if(level.ex_gunship_inform) self thread gunshipInform(false);
	playerHudDestroy("gunship_overlay");
	playerHudDestroy("gunship_grain");
	playerHudDestroy("gunship_clock");

	self show();
	self unlink();
	self.ex_invulnerable = false;
	playerHudRestoreStatusIcon();
	if(level.ex_gunship == 1) self.pers["conseckill"] = 0;
	if(level.ex_gunship == 3) self.pers["conskillnumb"] = 0;
	self.dont_auto_balance = undefined;

	if(eject) thread gunshipPlayerEject();
	else
	{
		self setPlayerAngles(self.gunship_org_angles);
		self setOrigin(self.gunship_org_origin);
	}

	self extreme\_ex_weapons::restoreWeapons(level.ex_gunship_refill);
	self.ex_stopwepmon = false;

	if(level.ex_gunship_visible == 1) level.gunship hide();
	if(level.ex_gunship_ambientsound == 1) level.gunship stoploopsound();
	level.gunship.owner = level.gunship;
	level.gunship.team = "none";
}

gunshipDetachPlayerLevel(playerent, skipcheck)
{
	level endon("ex_gameover");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isPlayer(level.gunship.owner) || !isPlayer(playerent) || level.gunship.owner != playerent)) return;

	if(isPlayer(playerent)) playerent notify("gunship_over");
	if(isPlayer(playerent) && isDefined(playerent.ex_gunship_weapons)) playerent.ex_gunship_weapons = [];
	if(isPlayer(playerent) && level.ex_gunship_inform) playerent thread gunshipInform(false);
	if(isPlayer(playerent)) playerent playerHudDestroy("gunship_overlay");
	if(isPlayer(playerent)) playerent playerHudDestroy("gunship_grain");
	if(isPlayer(playerent)) playerent playerHudDestroy("gunship_clock");

	if(isPlayer(playerent)) playerent show();
	if(isPlayer(playerent)) playerent unlink();
	if(isPlayer(playerent)) playerent.ex_invulnerable = false;
	if(isPlayer(playerent)) playerHudRestoreStatusIcon();
	if(level.ex_gunship == 1 && isPlayer(playerent)) playerent.pers["conseckill"] = 0;
	if(level.ex_gunship == 3 && isPlayer(playerent)) playerent.pers["conskillnumb"] = 0;
	if(isPlayer(playerent)) playerent.dont_auto_balance = undefined;

	if(level.ex_gunship_visible == 1) level.gunship hide();
	if(level.ex_gunship_ambientsound == 1) level.gunship stoploopsound();
	level.gunship.owner = level.gunship;
	level.gunship.team = "none";
}

gunshipPlayerEject()
{
	level endon("ex_gameover");
	self endon("disconnect");

	self.ex_isparachuting = true;
	if(level.ex_gunship_eject_protect) self.ex_invulnerable = true;

	startpoint = self.origin;
	if(!level.ex_gunship_eject_dropzone)
	{
		spawnpoint = getNearestSpawnpoint(self.origin);
		endpoint = spawnpoint.origin + (0, 0, 30);
	}
	else endpoint = self.gunship_org_origin + (0, 0, 30);

	chute = level createParachute(startpoint, self.angles, self.pers["team"], false);
	self linkto(level.chutes[chute].anchor);
	level thread dropOnParachute(chute, startpoint, endpoint);

	while(isPlayer(self) && isAlive(self) && level.chutes[chute].flag == 1)
	{
		if(level.ex_gunship_eject_protect == 2 && isAlive(self) && self.sessionstate == "playing" &&
			(self attackButtonPressed() && self getCurrentWeapon() != "none" )) self.ex_invulnerable = false;

		self setClientCvar("cl_stance", "0");
		wait( [[level.ex_fpstime]](0.2) );
	}

	if(isPlayer(self))
	{
		self unlink();
		if(isAlive(self))
		{
			self playSound("para_land");
			earthquake(0.4, 1.2, self.origin, 70);
		}
		self.ex_invulnerable = false;
		self.ex_isparachuting = undefined;
	}
}

gunshipWeapon()
{
	self endon("kill_thread");
	self endon("gunship_over");

	wait( [[level.ex_fpstime]](0.2) );
	self takeAllWeapons();

	self.ex_gunship_weapons = [];
	for(i = 0; i < level.ex_gunship_weapons.size; i++)
	{
		self.ex_gunship_weapons[i] = spawnstruct();

		if(level.ex_gunship_weapons[i].clip >= level.ex_gunship_weapons[i].ammo)
		{
			weapon_clip = level.ex_gunship_weapons[i].ammo;
			weapon_reserve = 0;
		}
		else
		{
			weapon_clip = level.ex_gunship_weapons[i].clip;
			weapon_reserve = level.ex_gunship_weapons[i].ammo - level.ex_gunship_weapons[i].clip;
		}

		self.ex_gunship_weapons[i].clip = weapon_clip;
		self.ex_gunship_weapons[i].reserve = weapon_reserve;
		self.ex_gunship_weapons[i].enabled = level.ex_gunship_weapons[i].enabled;
		self.ex_gunship_weapons[i].locked = level.ex_gunship_weapons[i].locked;
	}

	current = -1;
	stop_switch = false;
	force_eject = false;
	manual_eject = false;
	weapon_switch = getTime();

	for(;;)
	{
		if(current != -1) while(!self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );

		manual_eject = ((level.ex_gunship_eject & 8) == 8 && self useButtonPressed() && self meleeButtonPressed());

		if(force_eject || manual_eject)
		{
			if(force_eject) self iprintlnbold(&"GUNSHIP_FORCED_EJECT");
			thread gunshipDetachPlayer(true);
			break;
		}

		if(!stop_switch)
		{
			if(current != -1)
			{
				self.ex_gunship_weapons[current].clip = self getWeaponSlotClipAmmo("primary");
				self.ex_gunship_weapons[current].reserve = self getWeaponSlotAmmo("primary");
				if(self.ex_gunship_weapons[current].clip == 0)
				{
					if(self.ex_gunship_weapons[current].reserve > 0)
					{
						self.ex_gunship_weapons[current].clip = 1;
						self.ex_gunship_weapons[current].reserve--;
					}
					else self.ex_gunship_weapons[current].enabled = false;
				}
			}

			check_switch = false;
			newcurrent = current;
			while(1)
			{
				newcurrent++;
				if(newcurrent == current)
				{
					if(!self.ex_gunship_weapons[newcurrent].enabled || self.ex_gunship_weapons[newcurrent].locked) newcurrent = -1;
					break;
				}
				else if(newcurrent < self.ex_gunship_weapons.size)
				{
					if(self.ex_gunship_weapons[newcurrent].enabled && !self.ex_gunship_weapons[newcurrent].locked) break;
				}
				else
				{
					check_switch = true;
					newcurrent = -1;
				}
			}

			skip_switch = false;
			if(newcurrent == -1)
			{
				skip_switch = true;
				if((level.ex_gunship_eject & 4) == 4) force_eject = true;
			}
			else if(newcurrent == current) skip_switch = true;

			current = newcurrent;

			if(!skip_switch)
			{
				if(check_switch)
				{
					weapon_switch_prev = weapon_switch;
					weapon_switch = getTime();
					weapon_cycle = (weapon_switch - weapon_switch_prev) / 1000;
					if(weapon_cycle < level.ex_gunship_weapons.size * 1)
					{
						self takeAllWeapons();
						playerHudSetAlpha("gunship_overlay", 0);
						self iprintlnbold(&"GUNSHIP_SWITCH_TOO_FAST");
						wait( [[level.ex_fpstime]](3) );
						playerHudSetAlpha("gunship_overlay", 1);
					}
				}

				self setWeaponSlotWeapon("primary", level.ex_gunship_weapons[current].weapon);
				self setWeaponClipAmmo(level.ex_gunship_weapons[current].weapon, self.ex_gunship_weapons[current].clip);
				self setWeaponSlotAmmo("primary", self.ex_gunship_weapons[current].reserve);
				self switchToWeapon(level.ex_gunship_weapons[current].weapon);
				thread gunshipWeaponOverlay(level.ex_gunship_weapons[current].overlay);

				if(level.ex_gunship_weapons.size == 1) stop_switch = true;
			}
		}

		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
	}
}

gunshipCounterMeasures()
{
	self endon("kill_thread");
	self endon("gunship_over");

	while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.05) );

	cm = level.ex_gunship_cm;

	while(cm > 0)
	{
		wait( [[level.ex_fpstime]](0.1) );

		if(self meleeButtonPressed())
		{
			self playlocalsound("gunship_flares");
			playfxontag(level.ex_effect["gunship_flares"], level.gunship, "tag_flares");
			level thread gunshipDecoy(level.gunship.origin);
			cm--;

			while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
			wait( [[level.ex_fpstime]](1) );
		}
	}
}

gunshipDecoy(origin)
{
	level notify("decoy_over");
	level endon("decoy_over");

	if(!isDefined(level.gunship_decoy))
	{
		level.gunship_decoy = spawn("script_model", origin);
		level.gunship_decoy setmodel("xmodel/tag_origin");
	}
	else level.gunship_decoy.origin = origin;

	level.gunship_decoy moveto( (origin[0], origin[1], int(origin[2] / 2)), level.ex_gunship_cm_ttl);

	wait( [[level.ex_fpstime]](level.ex_gunship_cm_ttl) );
	level.gunship_decoy delete();
}

gunshipWeaponUnlock(attacker)
{
	attacker endon("disconnect");

	if(isPlayer(attacker) && ( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == attacker) || (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == attacker) ))
	{
		attacker.ex_gunship_kills++;

		// wait a brief moment to let other arcade shaders display first
		wait( [[level.ex_fpstime]](1) );
		if(!isPlayer(attacker)) return;

		gunship_arcade = 0;
		if(level.ex_arcade_shaders)
		{
			if( (level.ex_gunship == 1 && (level.ex_arcade_shaders & 1) == 1) || (level.ex_gunship == 2 && (level.ex_arcade_shaders & 4) == 4) || (level.ex_gunship == 3 && (level.ex_arcade_shaders & 2) == 2) ) gunship_arcade = 1;
			if(level.ex_specials && level.ex_gunship_special) gunship_arcade = 1;
		}

		for(i = 0; i < attacker.ex_gunship_weapons.size; i++)
		{
			switch(level.ex_gunship_weapons[i].weapon)
			{
				case "gunship_40mm_mp":
					if(level.ex_gunship_40mm_unlock && attacker.ex_gunship_kills >= level.ex_gunship_40mm_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(gunship_arcade) attacker thread extreme\_ex_arcade::showArcadeShader("x2_40mmunlock", level.ex_arcade_shaders_perk);
								else attacker iprintlnbold(&"GUNSHIP_40MM_UNLOCK");
						}
					}
					break;
				case "gunship_105mm_mp":
					if(level.ex_gunship_105mm_unlock && attacker.ex_gunship_kills >= level.ex_gunship_105mm_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(gunship_arcade) attacker thread extreme\_ex_arcade::showArcadeShader("x2_105mmunlock", level.ex_arcade_shaders_perk);
								else attacker iprintlnbold(&"GUNSHIP_105MM_UNLOCK");
						}
					}
					break;
				case "gunship_nuke_mp":
					if(level.ex_gunship_nuke_unlock && attacker.ex_gunship_kills >= level.ex_gunship_nuke_unlock)
					{
						if(attacker.ex_gunship_weapons[i].enabled && attacker.ex_gunship_weapons[i].locked)
						{
							attacker.ex_gunship_weapons[i].locked = false;
							if(gunship_arcade) attacker thread extreme\_ex_arcade::showArcadeShader("x2_nukeunlock", level.ex_arcade_shaders_perk);
								else attacker iprintlnbold(&"GUNSHIP_NUKE_UNLOCK");
						}
					}
					break;
			}
		}
	}
}

gunshipWeaponOverlay(overlay)
{
	self endon("kill_thread");
	self endon("gunship_over");

	hud_index = playerHudCreate("gunship_overlay", 0, 0, 1, (1,1,1), 1, 0, "center", "middle", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, overlay, 640, 480);

	if(level.ex_gunship_grain)
	{
		hud_index = playerHudCreate("gunship_grain", 0, 0, 0.5, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, true);
		if(hud_index == -1) return;
		playerHudSetShader(hud_index, "gunship_overlay_grain", 640, 480);
	}
}

gunshipClock()
{
	hud_index = playerHudCreate("gunship_clock", 6, 76, 1, (1,1,1), 1, 0, "left", "top", "left", "top", false, true);
	if(hud_index == -1) return;
	playerHudSetClock(hud_index, level.ex_gunship_time, level.ex_gunship_time, "hudStopwatch", 48, 48);
}

/*******************************************************************************
ADVERTISE
*******************************************************************************/
gunshipAdvertise()
{
	switch(level.ex_gunship)
	{
		case 1:
			iprintln(&"GUNSHIP_ADVERTISE_MODE1");
			iprintln(&"GUNSHIP_ADVERTISE_MODE1_HOW", level.ex_gunship_killspree);
			break;
		case 2:
			iprintln(&"GUNSHIP_ADVERTISE_MODE2");
			switch(level.ex_rank_wmdtype)
			{
				case 1:
					iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", 7);
					break;
				case 2:
					iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", level.ex_rank_special);
					break;
				case 3:
					iprintln(&"GUNSHIP_ADVERTISE_MODE2_HOW", level.ex_rank_allow_rank);
					break;
			}
			break;
		case 3:
			iprintln(&"GUNSHIP_ADVERTISE_MODE3");
			iprintln(&"GUNSHIP_ADVERTISE_MODE3_HOW", level.ex_gunship_obitladder, gunshipGetLadderStr());
			break;
		case 4:
			if(level.ex_gunship_special && extreme\_ex_specials::getPerkStock("gunship") > 0)
			{
				iprintln(&"GUNSHIP_ADVERTISE_MODE4");
				iprintln(&"GUNSHIP_ADVERTISE_MODE4_HOW");
			}
	}

	wait( [[level.ex_fpstime]](3) );

	random_hint = randomInt(3);
	switch(random_hint)
	{
		case 0:
			iprintln(&"GUNSHIP_ADVERTISE_HINT1");
			break;
		case 1:
			iprintln(&"GUNSHIP_ADVERTISE_HINT2");
			break;
		case 2:
			if(level.ex_gunship_eject)
			{
				if((level.ex_gunship_eject & 7) == 7) iprintln(&"GUNSHIP_ADVERTISE_HINT9");
				else if((level.ex_gunship_eject & 6) == 6) iprintln(&"GUNSHIP_ADVERTISE_HINT8");
				else if((level.ex_gunship_eject & 5) == 5) iprintln(&"GUNSHIP_ADVERTISE_HINT7");
				else if((level.ex_gunship_eject & 4) == 4) iprintln(&"GUNSHIP_ADVERTISE_HINT6");
				else if((level.ex_gunship_eject & 3) == 3) iprintln(&"GUNSHIP_ADVERTISE_HINT5");
				else if((level.ex_gunship_eject & 2) == 2) iprintln(&"GUNSHIP_ADVERTISE_HINT4");
				else if((level.ex_gunship_eject & 1) == 1) iprintln(&"GUNSHIP_ADVERTISE_HINT3");
			}
			break;
	}

	wait( [[level.ex_fpstime]](3) );

	if(level.ex_gunship_nuke && level.ex_gunship_nuke_unlock) iprintln(&"GUNSHIP_ADVERTISE_NUKE_UNLOCK", level.ex_gunship_nuke_unlock);
}

gunshipGetLadderStr()
{
	switch(level.ex_gunship_obitladder)
	{
		case 2: return &"GUNSHIP_ADVERTISE_MODE3_DOUBLE";
		case 3: return &"GUNSHIP_ADVERTISE_MODE3_TRIPLE";
		case 4: return &"GUNSHIP_ADVERTISE_MODE3_MULTI";
		case 5: return &"GUNSHIP_ADVERTISE_MODE3_MEGA";
		case 6: return &"GUNSHIP_ADVERTISE_MODE3_ULTRA";
		case 7: return &"GUNSHIP_ADVERTISE_MODE3_MONSTER";
		case 8: return &"GUNSHIP_ADVERTISE_MODE3_LUDICROUS";
		case 9: return &"GUNSHIP_ADVERTISE_MODE3_TOPGUN";
	}
}

gunshipInform(boarding)
{
	if(!level.ex_teamplay)
	{
		if(boarding) iprintln(&"GUNSHIP_ACTIVATED_ALL", [[level.ex_pname]](self));
			else iprintln(&"GUNSHIP_DEACTIVATED_ALL", [[level.ex_pname]](self));
	}
	else
	{
		if(level.ex_gunship_inform == 1)
		{
			if(boarding) gunshipInformTeam(&"GUNSHIP_ACTIVATED_TEAM", self.pers["team"]);
				else gunshipInformTeam(&"GUNSHIP_DEACTIVATED_TEAM", self.pers["team"]);
		}
		else
		{
			if(self.pers["team"] == "allies") enemyteam = "axis";
				else enemyteam = "allies";

			if(boarding)
			{
				gunshipInformTeam(&"GUNSHIP_ACTIVATED_TEAM", self.pers["team"]);
				gunshipInformTeam(&"GUNSHIP_ACTIVATED_ENEMY", enemyteam);
			}
			else
			{
				gunshipInformTeam(&"GUNSHIP_DEACTIVATED_TEAM", self.pers["team"]);
				gunshipInformTeam(&"GUNSHIP_DEACTIVATED_ENEMY", enemyteam);
			}
		}
	}

	if(!level.ex_gunship_clock) self iprintln(&"GUNSHIP_TIME", level.ex_gunship_time);
}

gunshipInformTeam(locstring, team)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers) && isDefined(player.pers["team"]))
			if(player.pers["team"] == team) player iprintln(locstring, [[level.ex_pname]](self));
	}
}

/*******************************************************************************
PROJECTILE MONITORING PROCEDURES
*******************************************************************************/
gunshipReplaceProjectile()
{
	self setmodel("xmodel/weapon_flak_missile");
	dest = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), 999999);
	time = distance(self.origin, dest) * 0.0254 / 100;
	if(time > 0)
	{
		self moveto(dest, time, 0, 0);
		wait( [[level.ex_fpstime]](time) );
	}
	self delete();
}

gunshipMonitorProjectile(entity, gunship)
{
	entity_by = gunship.owner;
	entity_wp = entity_by getcurrentweapon();
	if(!isDefined(entity_wp)) return;

/*
	origin = entity.origin;
	angles = entity.angles;
	entity delete();
	entity = spawn("script_model", origin);
	entity.angles = angles;
	entity thread gunshipReplaceProjectile();
*/

	// Screen shaking when firing (on player in gunship)
	switch(entity_wp)
	{
		case "gunship_25mm_mp":
			duration = 0.1;
			scale = 0.2;
			break;
		case "gunship_40mm_mp":
			duration = 0.3;
			scale = 0.4;
			break;
		case "gunship_105mm_mp":
			duration = 0.5;
			scale = 0.6;
			break;
		case "gunship_nuke_mp":
			duration = 0.5;
			scale = 0.6;
			entity_by.ex_invulnerable = true; // begin nuke survival hack
			break;
		default:
			duration = 0;
			scale = 0;
			break;
	}

	if(duration) earthquake(scale, duration, entity_by.origin, 100);

	// wait for projectile to explode
	lastorigin = entity.origin;
	while(isDefined(entity))
	{
		lastorigin = entity.origin;
		wait( [[level.ex_fpstime]](0.05) );
	}

	// Screen shaking on impact
	switch(entity_wp)
	{
		case "gunship_40mm_mp":
			duration = 1;
			scale = 0.2;
			thread extreme\_ex_specials_gml::perkRadiusDamage(lastorigin, gunship.team, 500, 250);
			thread extreme\_ex_specials_flak::perkRadiusDamage(lastorigin, gunship.team, 500, 250);
			break;
		case "gunship_105mm_mp":
			duration = 2;
			scale = 0.2;
			thread extreme\_ex_specials_gml::perkRadiusDamage(lastorigin, gunship.team, 500, 500);
			thread extreme\_ex_specials_flak::perkRadiusDamage(lastorigin, gunship.team, 500, 500);
			break;
		case "gunship_nuke_mp":
			duration = 4;
			scale = 1;
			entity_by.ex_invulnerable = false; // end nuke survival hack
			if(level.ex_gunship_nuke_fx) playfx(level.ex_effect["gunship_nuke"], lastorigin);
			if(level.ex_gunship_nuke_wipeout)
			{
				if(level.ex_gunship && level.ex_gunship_special)
				{
					if(gunship == level.gunship && extreme\_ex_specials_gunship::perkValidateAsTarget(gunship.team)) level.gunship_special.health = 0;
						else if(gunship == level.gunship_special && extreme\_ex_gunship::gunshipValidateAsTarget(gunship.team)) level.gunship.health = 0;
				}
				if(level.ex_heli && isDefined(level.helicopter)) level.helicopter.health = 0;
				thread extreme\_ex_airtrafficcontroller::planeCrashAll();

				if(level.ex_gunship_nuke_wipeout == 2)
				{
					thread extreme\_ex_specials_gml::perkRadiusDamage(lastorigin, gunship.team, 2000, 1000);
					thread extreme\_ex_specials_flak::perkRadiusDamage(lastorigin, gunship.team, 2000, 1000);
				}

				if(level.ex_gunship_nuke_wipeout == 3)
				{
					nuke_radius = spawn("script_origin", lastorigin);
					nuke_radius thread extreme\_ex_utils::scriptedfxradiusdamage(entity_by, undefined, "MOD_PROJECTILE_SPLASH", entity_wp, 5000, 300, 300, "none", undefined, false, true, true, "nuke");
					nuke_radius delete();
				}
			}
			break;
		default:
			duration = 0;
			scale = 0;
			break;
	}

	if(duration && isDefined(lastorigin)) earthquake(scale, duration, lastorigin, 1000);
}

/*******************************************************************************
PARACHUTE
*******************************************************************************/
getNearestSpawnpoint(origin)
{
	level endon("ex_gameover");
	self endon("disconnect");

	spawnpoints = [];

	spawn_entities = getentarray("mp_dm_spawn", "classname");
	if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];

	if(!spawnpoints.size || level.ex_teamplay)
	{
		spawn_entities = getentarray("mp_tdm_spawn", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}
	if(!spawnpoints.size || level.ex_flagbased)
	{
		spawn_entities = getentarray("mp_ctf_spawn_allied", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
		spawn_entities = getentarray("mp_ctf_spawn_axis", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}
	if(!spawnpoints.size)
	{
		spawn_entities = getentarray("mp_sd_spawn_attacker", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
		spawn_entities = getentarray("mp_sd_spawn_defender", "classname");
		if(isDefined(spawn_entities)) for(i = 0; i < spawn_entities.size; i++) spawnpoints[spawnpoints.size] = spawn_entities[i];
	}

	if(isDefined(level.ex_spawnpoints)) for(i = 0; i < level.ex_spawnpoints.size; i++) spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];

	nearest_spot = spawnpoints[0];
	nearest_dist = distance(origin, spawnpoints[0].origin);

	for(i = 1; i < spawnpoints.size; i++)
	{
		trace = bullettrace(spawnpoints[i].origin, spawnpoints[i].origin + (0,0,300), true, undefined);
		trace_dist = int(distance(spawnpoints[i].origin, trace["position"]));

		if(!isDefined(trace_dist) || trace_dist == 300)
		{
			dist = distance(origin, spawnpoints[i].origin);
			if(dist < nearest_dist)
			{
				nearest_spot = spawnpoints[i];
				nearest_dist = dist;
			}
		}
	}

	return nearest_spot;
}

createParachute(chute_origin, chute_angles, chute_team, chute_hide)
{
	chute = allocateParachute();

	level.chutes[chute].anchor = spawn("script_model", chute_origin);
	level.chutes[chute].anchor.angles = chute_angles;

	level.chutes[chute].model = spawn("script_model", chute_origin);
	if(chute_hide) hideParachute(chute);
	switch(chute_team)
	{
		case "axis": level.chutes[chute].model setModel(game["chute_player_axis"]); break;
		case "allies": level.chutes[chute].model setModel(game["chute_player_allies"]); break;
		default: level.chutes[chute].model setModel(game["chute_player_allies"]);
	}
	level.chutes[chute].model linkto(level.chutes[chute].anchor);
	level.chutes[chute].autokill = 180;
	thread monitorParachute(chute);
	return chute;
}

dropOnParachute(chute, chute_start, chute_end)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
	{
		level.chutes[chute].endpoint = chute_end;
		level.chutes[chute].anchor.origin = chute_start;
		level.chutes[chute].anchor playLoopSound ("para_wind");
		falltime = distance(chute_start, chute_end) / 100 + randomint(4);
		level.chutes[chute].autokill = (falltime * 2) + 10;
		level.chutes[chute].anchor moveto(chute_end, falltime);
		wait( [[level.ex_fpstime]](falltime) );
		level.chutes[chute].anchor stopLoopSound();
		level.chutes[chute].flag = 2; // 2 = delete
	}
}

hideParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
		level.chutes[chute].model hide();
}

showParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
		level.chutes[chute].model show();
}

monitorParachute(chute)
{
	chute_time = 0;
	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );
		chute_time++;
		if(level.chutes[chute].flag == 2 || chute_time >= level.chutes[chute].autokill)
		{
			if(level.chutes[chute].flag == 2) level.chutes[chute].model unlink(); // 2 = delete
			freeParachute(chute);
			break;
		}
	}
}

allocateParachute()
{
	if(!isDefined(level.chutes)) level.chutes = [];

	for(i = 0; i < level.chutes.size; i++)
	{
		if(level.chutes[i].flag == 0) // 0 = free
		{
			level.chutes[i].flag = 1; // 1 = in use
			return i;
		}
	}

	level.chutes[i] = spawnstruct();
	level.chutes[i].flag = 1; // 1 = in use
	return i;
}

freeParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
	{
		if(isDefined(level.chutes[chute].model))
			level.chutes[chute].model delete();

		if(isDefined(level.chutes[chute].anchor))
			level.chutes[chute].anchor delete();

		level.chutes[chute].flag = 0; // 0 = free
	}
}

/*******************************************************************************
CRASHING
*******************************************************************************/
gunshipCrash()
{
	index = gunshipCrashAllocate();

	origin = level.gunship.origin;
	angles = anglesNormalize((0, level.gunship.angles[1], -20));

	level.crashing_gunships[index].model = spawn("script_model", origin);
	level.crashing_gunships[index].model.angles = angles;
	level.crashing_gunships[index].model setmodel("xmodel/vehicle_condor");
	level.crashing_gunships[index].model thread gunshipCrashFX();

	// force parachute ejection if player is still there
	if(isPlayer(level.gunship.owner)) level.gunship.owner thread gunshipDetachPlayer(true);

	// calculate speed
	gunship_speed = ((2 * 3.14159265358979 * level.rotation_rig.maxradius) / level.rotation_rig.rotationspeed) * 0.0254;

	// take over plane movement to predefined crash point
	f0 = posForward(origin, angles, 1000);
	movetime = calcTime(origin, f0, gunship_speed);
	level.crashing_gunships[index].model moveto(f0, movetime);

	// calculate nodes in parallel
	f1 = posForward(f0, angles, 2000 + randomInt(2000));
	f2 = posLeft(f1, angles, 2000 + randomInt(int(level.rotation_rig.maxradius)));
	dest = posDown(f2, angles, 0);
	if(dest[2] < game["mapArea_Min"][2]) dest = (dest[0], dest[1], game["mapArea_Min"][2] - 100);
	level.crashing_gunships[index].model thread quadraticBezierCurve(f0, f1, dest, gunship_speed);

	// wait to arrive at crash point
	wait( [[level.ex_fpstime]](movetime * .999) );

	// commence crashing
	level.crashing_gunships[index].model notify("crash_go");
	level.crashing_gunships[index].model playloopsound("plane_dive");

	// wait for crash to finish
	level.crashing_gunships[index].model waittill("crash_done");
	level.crashing_gunships[index].model notify("crashfx_done");

	level.crashing_gunships[index].model stoploopsound();
	playfx(level.ex_effect["planecrash_explosion"], level.crashing_gunships[index].model.origin);
	level.crashing_gunships[index].model playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );
	playfx(level.ex_effect["planecrash_ball"], level.crashing_gunships[index].model.origin);
	wait( [[level.ex_fpstime]](5) );

	gunshipCrashFree(index);
}

gunshipCrashAllocate()
{
	for(i = 0; i < level.crashing_gunships.size; i++)
	{
		if(level.crashing_gunships[i].inuse == 0)
		{
			level.crashing_gunships[i].inuse = 1;
			return(i);
		}
	}

	level.crashing_gunships[i] = spawnstruct();
	level.crashing_gunships[i].inuse = 1;
	return(i);
}

gunshipCrashFree(index)
{
	level.crashing_gunships[index].model delete();
	level.crashing_gunships[index].inuse = 0;
}

gunshipCrashFX()
{
	self endon("crashfx_done");

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );

	playfx(level.ex_effect["plane_explosion"], self.origin);
	self playsound("plane_explosion_" + (1 + randomInt(3)));
	wait( [[level.ex_fpstime]](0.5) );

	engine = randomInt(4);

	while(1)
	{
		playfxontag(level.ex_effect["planecrash_smoke"], self, "tag_engine" + engine);
		if(randomInt(100) < 5)
		{
			playfx(level.ex_effect["plane_explosion"], self.origin);
			self playsound("plane_explosion_" + (1 + randomInt(3)));
		}
		wait( [[level.ex_fpstime]](.1) );
	}
}

/*******************************************************************************
BEZIER
*******************************************************************************/
quadraticBezierCurve(pos0, pos1, pos2, speed)
{
	angles_prev = self.angles;
	angles_roll = self.angles[2];
	adjust_roll = 0;

	node_array = [];
	nodes = 25;
	node_prev = pos0;

	for(i = 1; i <= nodes; i++)
	{
		index = node_array.size;
		node_array[index] = spawnstruct();

		node = pointQuadraticBezierCurve(pos0, pos1, pos2, i / nodes);
		node_array[index].node = node;
		node_array[index].time = calcTime(node_prev, node_array[index].node, speed);
		if(speed < 45) speed = speed + 1;

		va = vectorToAngles(node - node_prev);
		fv = anglesToForward(va);
		rdot = vectorDot(anglesToRight(angles_prev), fv);
		if(rdot < 0 && adjust_roll > -10) adjust_roll--; // right
			else if(rdot > 0 && adjust_roll < 10) adjust_roll++; // left
		node_array[index].angles = (va[0], va[1], angles_roll + adjust_roll);

		node_prev = node_array[index].node;
		angles_prev = node_array[index].angles;
		if(i % 10 == 0) wait( [[level.ex_fpstime]](.05) );
	}

	self waittill("crash_go");

	for(i = 0; i < node_array.size; i++)
	{
		movetime = node_array[i].time;
		self rotateto(node_array[i].angles, movetime);
		self moveto(node_array[i].node, movetime);
		wait( [[level.ex_fpstime]](movetime * .999) );
	}

	self notify("crash_done");
}

pointQuadraticBezierCurve(pos0, pos1, pos2, t)
{
	// B(t) = (1-t)^2*P0 + 2(1-t)*t*P1 + t^2*P2
	tvec = [[level.ex_vectorscale]](pos0, pow(1 - t, 2)) +
	       [[level.ex_vectorscale]](pos1, t * (2 * (1 - t))) +
	       [[level.ex_vectorscale]](pos2, pow(t, 2));
	vec = (tvec[0], tvec[1], tvec[2]);
	return vec;
}

/*******************************************************************************
LOCATORS
*******************************************************************************/
posForward(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posDown(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoup( (180, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, false, undefined);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posLeft(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoforward( (0, angles[1] + 90, 0) );
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

/*******************************************************************************
MISC
*******************************************************************************/
calcTime(p1, p2, speed)
{
	time = ((distance(p1, p2) * 0.0254) / speed);
	if(time <= 0) time = 0.1;
	return time;
}

angleNormalize(angle)
{
	if(angle) while(angle >= 360) angle -= 360;
		else while(angle <= -360) angle += 360;
	return(angle);
}

anglesNormalize(angles)
{
	pitch = angleNormalize(angles[0]);
	yaw = angleNormalize(angles[1]);
	roll = angleNormalize(angles[2]);
	return( (pitch, yaw, roll) );
}

pow(numb, power)
{
	result = 1.0;
	for(i = 0; i < power; i++)
		result = result * numb;
	return result;
}

sqrt(X)
{
	if(X < 0) return -1;
	e = 0.000000000001;
	while(e > X) e /= 10;
	b = (1.0 + X) / 2;
	c = (b - X / b) / 2;
	iterations = 0;
	while(c > e && iterations < 1000)
	{
		f = b;
		b -= c;
		if(f == b) return b;
		c = (b - X / b) / 2;
		iterations++;
	}
	return b;
}
