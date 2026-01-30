#include extreme\_ex_specials;
#include extreme\_ex_gunship;
#include extreme\_ex_hudcontroller;

perkInit()
{
	// perk related precaching
	if(!level.ex_rank_statusicons && !level.ex_classes_statusicons) [[level.ex_PrecacheStatusIcon]]("gunship_statusicon");

	[[level.ex_PrecacheModel]]("xmodel/tag_origin");
	[[level.ex_PrecacheModel]]("xmodel/vehicle_condor");

	if(level.ex_gunship_40mm) [[level.ex_PrecacheShader]]("x2_40mmunlock");
	if(level.ex_gunship_105mm) [[level.ex_PrecacheShader]]("x2_105mmunlock");
	if(level.ex_gunship_nuke) [[level.ex_PrecacheShader]]("x2_nukeunlock");

	if(level.ex_gunship_25mm) [[level.ex_PrecacheShader]]("gunship_overlay_25mm");
	if(level.ex_gunship_40mm) [[level.ex_PrecacheShader]]("gunship_overlay_40mm");
	if(level.ex_gunship_105mm) [[level.ex_PrecacheShader]]("gunship_overlay_105mm");
	if(level.ex_gunship_nuke) [[level.ex_PrecacheShader]]("gunship_overlay_nuke");
	if(level.ex_gunship_grain) [[level.ex_PrecacheShader]]("gunship_overlay_grain");
	if(level.ex_gunship_clock)
	{
		[[level.ex_PrecacheShader]]("hudStopwatch");
		[[level.ex_PrecacheShader]]("hudstopwatchneedle");
	}

	level.ex_effect["gunship_flares"] = [[level.ex_PrecacheEffect]]("fx/flares/ac130_flare_emitter.efx");
	if(level.ex_gunship_nuke && level.ex_gunship_nuke_fx) level.ex_effect["gunship_nuke"] = [[level.ex_PrecacheEffect]]("fx/impacts/gunship_nuke_expand.efx");
}

perkInitPost()
{
	// perk related precaching after map load
}

perkCheck()
{
	// checks before being able to buy this perk
	if(isPlayer(level.gunship_special.owner)) return(false);
	if(level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) return(false);
	if(playerPerkIsLocked("stealth", false)) return(false);
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
		else self iprintlnbold(&"GUNSHIP_READY");

	self thread hudNotifySpecial(index);

	// specialty store method of activating gunship (hold melee)
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

			if(count >= 10 && getPerkPriority(index) && gunshipSpecialBoard()) break;
			while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
		}
	}

	self thread hudNotifySpecialRemove(index);
}

/*******************************************************************************
VALIDATION
*******************************************************************************/
perkValidateAsTarget(team)
{
	if(!level.ex_gunship_special || level.ex_gunship_protect == 1) return(false);
	if(!isPlayer(level.gunship_special.owner) || (level.ex_teamplay && level.gunship_special.team == team)) return(false);
	if(level.gunship_special.health <= 0) return(false);
	return(true);
}

/*******************************************************************************
GUNSHIP ASSIGNMENT
*******************************************************************************/
gunshipSpecialBoard()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](randomFloat(0.5)) );

	if(isPlayer(level.gunship_special.owner))
	{
		self iprintlnbold(&"GUNSHIP_OCCUPIED");
		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		return(false);
	}

	if(level.ex_flagbased && isDefined(self.flag))
	{
		self iprintlnbold(&"GUNSHIP_FLAGCARRIER");
		while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
		return(false);
	}

	self.usedweapons = true;
	self thread gunshipSpecialAttachPlayer();
	return(true);
}

gunshipSpecialAttachPlayer()
{
	self endon("kill_thread");

	if(isPlayer(level.gunship_special.owner)) return;
	level.gunship_special.owner = self;
	level.gunship_special.team = self.pers["team"];
	level.gunship_special.health = level.ex_gunship_maxhealth;

	self thread playerStartUsingPerk("gunship", true);

	self extreme\_ex_utils::forceto("stand");
	self.gunship_org_origin = self.origin;
	self.gunship_org_angles = self.angles;

	self.ex_stopwepmon = true;
	wait( [[level.ex_fpstime]](0.1) );
	self notify("weaponsave");
	self waittill("weaponsaved");

	if(level.ex_gunship_airraid) level.rotation_rig playsound("air_raid");
	if(level.ex_gunship_visible == 1) level.gunship_special show();
	if(level.ex_gunship_ambientsound == 1) level.gunship_special playloopsound("gunship_ambient");

	self.ex_gunship_ejected = false;
	playerHudSetStatusIcon("gunship_statusicon");
	if(level.ex_gunship == 1) self.pers["conseckill"] = 0;
	if(level.ex_gunship == 3) self.pers["conskillnumb"] = 0;
	if(level.ex_gunship_health) self.health = self.maxhealth;
	self.ex_gunship_kills = 0;
	self hide();
	self linkTo(level.rotation_rig, "tag_180", (level.rotation_rig.maxradius, 0, 0-level.ex_gunship_attachz), (0,0,0));
	self.dont_auto_balance = true;

	level thread gunshipSpecialTimer(self);
	if(level.ex_gunship_inform) self thread gunshipInform(true);
	if(level.ex_gunship_clock) self thread gunshipClock();
	self thread gunshipSpecialWeapon();
	if(level.ex_gunship_cm) self thread gunshipSpecialCounterMeasures();
}

gunshipSpecialTimer(player)
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
			level thread gunshipSpecialDetachPlayerLevel(player, true);
			return;
		}

		// crash if health dropped to 0
		if(level.gunship_special.health <= 0)
		{
			level thread gunshipSpecialCrash();
			return;
		}
	}

	if(isPlayer(player))
	{
		// player is still there, and has a valid ticket
		if(isPlayer(level.gunship_special.owner))
		{
			if(level.gunship_special.owner == player)
			{
				if(!level.ex_gameover && (level.ex_gunship_eject & 1) == 1) player thread gunshipSpecialDetachPlayer(true);
					else player thread gunshipSpecialDetachPlayer();
			}
		}
		// player is still there, but seems to be in gunship without a valid ticket
		else if(player.origin[2] + level.ex_gunship_attachz == level.gunship_special.origin[2])
		{
			if(!level.ex_gameover) player thread gunshipSpecialDetachPlayer(false, true);
				else level thread gunshipSpecialDetachPlayerLevel(player, true);
		}
	}
}

gunshipSpecialDetachPlayer(eject, skipcheck)
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isPlayer(level.gunship_special.owner) || !isPlayer(self) || level.gunship_special.owner != self)) return;

	self thread playerStopUsingPerk("gunship");

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

	if(level.ex_gunship_visible == 1) level.gunship_special hide();
	if(level.ex_gunship_ambientsound == 1) level.gunship_special stoploopsound();
	level.gunship_special.owner = level.gunship_special;
	level.gunship_special.team = "none";
}

gunshipSpecialDetachPlayerLevel(playerent, skipcheck)
{
	level endon("ex_gameover");

	if(!isDefined(skipcheck)) skipcheck = false;
	if(!skipcheck && (!isPlayer(level.gunship_special.owner) || !isPlayer(playerent) || level.gunship_special.owner != playerent)) return;

	if(isPlayer(playerent)) playerent thread playerStopUsingPerk("gunship");

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

	if(level.ex_gunship_visible == 1) level.gunship_special hide();
	if(level.ex_gunship_ambientsound == 1) level.gunship_special stoploopsound();
	level.gunship_special.owner = level.gunship_special;
	level.gunship_special.team = "none";
}

gunshipSpecialWeapon()
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
			thread gunshipSpecialDetachPlayer(true);
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

gunshipSpecialCounterMeasures()
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
			playfxontag(level.ex_effect["gunship_flares"], level.gunship_special, "tag_flares");
			level thread gunshipSpecialDecoy(level.gunship_special.origin);
			cm--;

			while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
			wait( [[level.ex_fpstime]](1) );
		}
	}
}

gunshipSpecialDecoy(origin)
{
	level notify("decoy_special_over");
	level endon("decoy_special_over");

	if(!isDefined(level.gunship_special_decoy))
	{
		level.gunship_special_decoy = spawn("script_model", origin);
		level.gunship_special_decoy setmodel("xmodel/tag_origin");
	}
	else level.gunship_special_decoy.origin = origin;

	level.gunship_special_decoy moveto( (origin[0], origin[1], int(origin[2] / 2)), level.ex_gunship_cm_ttl);

	wait( [[level.ex_fpstime]](level.ex_gunship_cm_ttl) );
	level.gunship_special_decoy delete();
}

/*******************************************************************************
CRASHING
*******************************************************************************/
gunshipSpecialCrash()
{
	index = gunshipCrashAllocate();

	origin = level.gunship_special.origin;
	angles = anglesNormalize((0, level.gunship_special.angles[1], -20));

	level.crashing_gunships[index].model = spawn("script_model", origin);
	level.crashing_gunships[index].model.angles = angles;
	level.crashing_gunships[index].model setmodel("xmodel/vehicle_condor");
	level.crashing_gunships[index].model thread gunshipCrashFX();

	// force parachute ejection if player is still there
	if(isPlayer(level.gunship_special.owner)) level.gunship_special.owner thread gunshipSpecialDetachPlayer(true);

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
