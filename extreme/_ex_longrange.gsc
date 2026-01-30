#include extreme\_ex_weapons;

init()
{
	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
}

onPlayerSpawned()
{
	if(isDefined(self.pers["isbot"])) return;

	self endon("kill_thread");

	if(!isDefined(self.pers["scopeswitch"]))
	{
		self.pers["scopeswitch"] = "m";
		memory = self extreme\_ex_memory::getMemory("lrbind", "key");
		if(!memory.error) self.pers["scopeswitch"] = memory.value;
		self thread extreme\_ex_utils::execClientCommand("bind " + self.pers["scopeswitch"] + " openScriptMenu keysMenu " + self.pers["scopeswitch"]);
	}

	if(level.ex_longrange_autoswitch) self thread switchAuto();
}

switchAuto()
{
	self endon("kill_thread");

	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );

		weaponname = self getCurrentWeapon();
		if(isWeaponType(weaponname, "sniper"))
		{
			self thread switchZoom();
			break;
		}
	}
}

switchZoom()
{
	self endon("kill_thread");

	weaponname = self getCurrentWeapon();
	alterego = getWeaponCounterpart(weaponname, true);
	if(alterego == "none") return;

	if(weaponname == self getWeaponSlotWeapon("primary")) weaponslot = "primary";
		else if(weaponname == self getWeaponSlotWeapon("primaryb")) weaponslot = "primaryb";
			else return;

	ammo = self getWeaponSlotAmmo(weaponslot);
	clipammo = self getWeaponSlotClipAmmo(weaponslot);
	self takeWeapon(weaponname);
	self setWeaponSlotWeapon(weaponslot, alterego);
	self setWeaponSlotAmmo(weaponslot, ammo);
	self setWeaponSlotClipAmmo(weaponslot, clipammo);
	self switchToWeapon(alterego);
}

switchBind(response)
{
	self endon("kill_thread");

	keys = "1234567890abcdefghijklmnopqrstuvwxyz";
	newbind = "";
	for(i = 0; i < keys.size; i++)
	{
		if(response == "key_" + keys[i])
		{
			newbind = keys[i];
			break;
		}
	}

	if(newbind != "")
	{
		self closeMenu();
		if(!isDefined(self.pers["scopeswitch"]))
		{
			self.pers["scopeswitch"] = "m";
			memory = self extreme\_ex_memory::getMemory("lrbind", "key");
			if(!memory.error) self.pers["scopeswitch"] = memory.value;
		}
		self thread extreme\_ex_utils::execClientCommand("unbind " + self.pers["scopeswitch"]);
		wait( [[level.ex_fpstime]](0.25) );
		self.pers["scopeswitch"] = newbind;
		self thread extreme\_ex_utils::execClientCommand("bind " + self.pers["scopeswitch"] + " openScriptMenu keysMenu " + self.pers["scopeswitch"]);
		self thread extreme\_ex_memory::setMemory("lrbind", "key", self.pers["scopeswitch"], level.ex_tune_delaywrite);
	}
}

getWeaponCounterpart(weaponname, checkprecache)
{
	if(!isDefined(checkprecache)) checkprecache = true;

	if(isWeaponType(weaponname, "snipersr"))
	{
		if(isDefined(level.weapons[weaponname].child))
		{
			child = level.weapons[weaponname].child;
			if(isDefined(level.weapons[child]))
			{
				if(!checkprecache || level.weapons[child].precached) return(child);
			}
			else logprint("LONGRANGE ERROR: no child of parent weapon " + weaponname + " in weapons array!\n");
		}
	}
	else if(isWeaponType(weaponname, "sniperlr"))
	{
		if(isDefined(level.weapons[weaponname].parent))
		{
			parent = level.weapons[weaponname].parent;
			if(isDefined(level.weapons[parent]))
			{
				if(!checkprecache || level.weapons[parent].precached) return(parent);
			}
			else logprint("LONGRANGE ERROR: no parent of child weapon " + weaponname + " in weapons array!\n");
		}
	}

	return("none");
}

main(eAttacker, sWeapon, vPoint, aInfo)
{
	self endon("disconnect");

	//logprint("LRHITLOC: passed sMeansOfDeath \"" + aInfo.sMeansOfDeath + "\", sHitLoc \"" + aInfo.sHitLoc + "\", iDamage \"" + aInfo.iDamage + "\"\n");

	aInfo.sMeansOfDeath = "MOD_RIFLE_BULLET";
	aInfo.sHitLoc = "none";
	aInfo.iDamage = 50;

	// causing runtime errors in earlier versions. Seems that sometimes the markers are cleared
	// before this procedure is done. Now returning if a marker is missing
	if(isDefined(self.ex_headmarker)) rangehm = int(distance(vPoint, self.ex_headmarker.origin));
		else return;
	if(isDefined(self.ex_eyemarker)) rangeem = int(distance(vPoint, self.ex_eyemarker.origin));
		else return;
	if(isDefined(self.ex_spinemarker)) rangesm = int(distance(vPoint, self.ex_spinemarker.origin));
		else return;
	if(isDefined(self.ex_lankmarker)) rangela = int(distance(vPoint, self.ex_lankmarker.origin));
		else return;
	if(isDefined(self.ex_rankmarker)) rangera = int(distance(vPoint, self.ex_rankmarker.origin));
		else return;
	if(isDefined(self.ex_lwristmarker)) rangelw = int(distance(vPoint, self.ex_lwristmarker.origin));
		else return;
	if(isDefined(self.ex_rwristmarker)) rangerw = int(distance(vPoint, self.ex_rwristmarker.origin));
		else return;

	/*
	if(!isDefined(level.lrhitlocno)) level.lrhitlocno = 0;
	level.lrhitlocno++;
	logprint("LRHITLOC: hit " + level.lrhitlocno + " distance to hm:" + rangehm + " em:" + rangeem + " sm:" + rangesm + " la:" + rangela + " ra:" + rangera + " lw:" + rangelw + " rw:" + rangerw + "\n");
	*/

	// Head
	if(rangeem <= 8)
	{
		aInfo.sMeansOfDeath = "MOD_HEAD_SHOT";
		aInfo.sHitLoc = "head";
		aInfo.iDamage = level.ex_lrhitloc_head;
	}
	// Neck
	else if(rangeem > 8 && rangehm <= 5 && rangesm <= 8)
	{
		aInfo.sHitLoc = "neck";
		aInfo.iDamage = level.ex_lrhitloc_neck;
	}
	// Feet
	else if(rangera <= 10 && rangeem > 30)
	{
		aInfo.sHitLoc = "right_foot";
		aInfo.iDamage = level.ex_lrhitloc_right_foot;
	}
	else if(rangela <= 10 && rangeem > 30)
	{
		aInfo.sHitLoc = "left_foot";
		aInfo.iDamage = level.ex_lrhitloc_left_foot;
	}
	// Hands
	else if(rangerw <= 6)
	{
		aInfo.sHitLoc = "right_hand";
		aInfo.iDamage = level.ex_lrhitloc_right_hand;
	}
	else if(rangelw <= 6)
	{
		aInfo.sHitLoc = "left_hand";
		aInfo.iDamage = level.ex_lrhitloc_left_hand;
	}
	// Torso
	else if(rangeem > 6 && rangesm <= 6)
	{
		aInfo.sHitLoc = "torso_upper";
		aInfo.iDamage = level.ex_lrhitloc_torso_upper;
	}
	else if(rangeem > 8 && rangeem < 25 && rangesm > 6 && rangesm <= 18)
	{
		aInfo.sHitLoc = "torso_lower";
		aInfo.iDamage = level.ex_lrhitloc_torso_lower;
	}
	// Legs
	else if(rangeem > 25 && rangera > 10 && rangera < 30)
	{
		aInfo.sHitLoc = "right_leg_upper";
		aInfo.iDamage = level.ex_lrhitloc_right_leg_upper;
	}
	else if(rangeem > 25 && rangera > 1 && rangera < 15)
	{
		aInfo.sHitLoc = "right_leg_lower";
		aInfo.iDamage = level.ex_lrhitloc_right_leg_lower;
	}
	else if(rangeem > 25 && rangela > 10 && rangela < 30)
	{
		aInfo.sHitLoc = "left_leg_upper";
		aInfo.iDamage = level.ex_lrhitloc_left_leg_upper;
	}
	else if(rangeem > 25 && rangela > 1 && rangela < 15)
	{
		aInfo.sHitLoc = "left_leg_lower";
		aInfo.iDamage = level.ex_lrhitloc_left_leg_lower;
	}
	// Arms
	else if(rangesm > 18 && rangerw > 10 && rangerw < 30)
	{
		aInfo.sHitLoc = "right_arm_upper";
		aInfo.iDamage = level.ex_lrhitloc_right_arm_upper;
	}
	else if(rangesm > 18 && rangerw > 1 && rangerw < 15)
	{
		aInfo.sHitLoc = "right_arm_lower";
		aInfo.iDamage = level.ex_lrhitloc_right_arm_lower;
	}
	else if(rangesm > 18 && rangelw > 10 && rangelw < 30)
	{
		aInfo.sHitLoc = "left_arm_upper";
		aInfo.iDamage = level.ex_lrhitloc_left_arm_upper;
	}
	else if(rangesm > 18 && rangelw > 1 && rangelw < 15)
	{
		aInfo.sHitLoc = "left_arm_lower";
		aInfo.iDamage = level.ex_lrhitloc_left_arm_lower;
	}
}

hitlocMessage(eAttacker, sHitLoc)
{
	hitloc = getHitlocStringname(sHitLoc);
	range = int(distance(eAttacker.origin, self.origin));
	if(level.ex_lrhitloc_unit) rangedist = int(range * 0.02778); // Range in Yards
		else rangedist = int(range * 0.0254); // Range in Metres

	switch(level.ex_lrhitloc_msg)
	{
		case 1:
		{
			eAttacker iprintln(&"LONGRANGE_HIT", [[level.ex_pname]](self), hitloc);
			if(level.ex_lrhitloc_unit) eAttacker iprintln(&"OBITUARY_YARDS", rangedist);
				else eAttacker iprintln(&"OBITUARY_METRES", rangedist);
			break;
		}
		case 2:
		{
			eAttacker iprintlnbold(&"LONGRANGE_HIT", [[level.ex_pname]](self), hitloc);
			if(level.ex_lrhitloc_unit) eAttacker iprintlnbold(&"OBITUARY_YARDS", rangedist);
				else eAttacker iprintlnbold(&"OBITUARY_METRES", rangedist);
			break;
		}
	}
}

getHitlocStringname(location)
{
	switch(location)
	{
		case "right_hand":      return &"HITLOC_RIGHT_HAND";
		case "left_hand":       return &"HITLOC_LEFT_HAND";
		case "right_arm_upper": return &"HITLOC_RIGHT_UPPER_ARM";
		case "right_arm_lower": return &"HITLOC_RIGHT_FOREARM";
		case "left_arm_upper":  return &"HITLOC_LEFT_UPPER_ARM";
		case "left_arm_lower":  return &"HITLOC_LEFT_FOREARM";
		case "head":            return &"HITLOC_HEAD";
		case "neck":            return &"HITLOC_NECK";
		case "right_foot":      return &"HITLOC_RIGHT_FOOT";
		case "left_foot":       return &"HITLOC_LEFT_FOOT";
		case "right_leg_lower": return &"HITLOC_RIGHT_LOWER_LEG";
		case "left_leg_lower":  return &"HITLOC_LEFT_LOWER_LEG";
		case "right_leg_upper": return &"HITLOC_RIGHT_UPPER_LEG";
		case "left_leg_upper":  return &"HITLOC_LEFT_UPPER_LEG";
		case "torso_upper":     return &"HITLOC_UPPER_TORSO";
		case "torso_lower":     return &"HITLOC_LOWER_TORSO";
		default:                return &"HITLOC_UNKNOWN";
	}
}

statusLongrange()
{
	// ui_longrange:
	// 0: longrange off, memory off, menu off
	// 1: longrange off, memory on, menu disabled
	// 2: longrange on, memory off, menu disabled
	// 3: longrange on, memory on, menu enabled
	longrange_server = level.ex_longrange;
	if(!longrange_server)
	{
		if(level.ex_longrange_memory) longrange_server = 1;
	}
	else
	{
		if(level.ex_longrange_memory) longrange_server = 3;
			else longrange_server = 2;
	}
	return(longrange_server);
}
