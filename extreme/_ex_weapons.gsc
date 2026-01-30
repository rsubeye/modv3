#include extreme\_ex_sprintsystem;
#include extreme\_ex_hudcontroller;
#include maps\mp\gametypes\_weapons;

loadout()
{
	// create weapon array
	self setWeaponArray();

	// weapon checks, if weapon = ignore or the weapon is undefined, set to "none"
	if(!isDefined(self.pers["weapon"]) || self.pers["weapon"] == "ignore") self.pers["weapon"] = "none";
	if(level.ex_wepo_secondary)
	{
		if(!isDefined(self.pers["weapon1"]) || self.pers["weapon1"] == "ignore") self.pers["weapon1"] = "none";
		if(!isDefined(self.pers["weapon2"]) || self.pers["weapon2"] == "ignore") self.pers["weapon2"] = "none";
	}

	if(level.ex_wepo_secondary)
	{
	 	self setWeaponSlotWeapon("primary", self.pers["weapon1"]);
		self setWeaponSlotWeapon("primaryb", self.pers["weapon2"]);
		self setSpawnWeapon(self.pers["weapon1"]);
	}
	else
	{
		self setWeaponSlotWeapon("primary", self.pers["weapon"]);
		self setWeaponSlotWeapon("primaryb", "none");
		self setSpawnWeapon(self.pers["weapon"]);
	}

	// give them a sidearm if allowed (if sec weapon enabled, the sidearm is handled in setSpawnWeapons)
	if(level.ex_wepo_sidearm && !level.ex_wepo_secondary) self giveSidearm();

	// set the ammo for the weapons
	self setAmmo("primary", false, true);
	self setAmmo("primaryb", false, true);

	// give landmines if allowed
	if(level.ex_landmines) self extreme\_ex_landmines::giveLandmines();

	// give first aid kits if allowed
	if(level.ex_medicsystem) self giveFirstAid();

	// give grenades if allowed
	self giveGrenades(false);

	// give binoculars
	self giveWeapon("binoculars_mp");

	// mbot loadout
	if(level.ex_mbot && isDefined(self.pers["isbot"])) self extreme\_ex_bots::botLoadout();

	// set up the spawning weapons
	self setSpawnWeapons();

	// for bash mode they can't have any weapons
	if(level.ex_bash_only)
	{
		self setWeaponSlotAmmo("primary", 0);
		self setWeaponSlotClipAmmo("primary", 0);
		self setWeaponSlotAmmo("primaryb", 0);
		self setWeaponSlotClipAmmo("primaryb", 0);
	}

	// bots stop here (for freezetag we need the monitors for weapon exchange)
	if(level.ex_currentgt != "ft" && isDefined(self.pers["isbot"])) return;

	// start weapon monitors
	self thread saveWeaponMonitor();
	self thread weaponChangeMonitor();
}

setAmmo(slot, gts, spawning)
{
	self endon("disconnect");

	// if not spawning, default false
	if(!isDefined(spawning)) spawning = false;

	// if not gametype start delay, default false
	if(!isDefined(gts)) gts = false;

	weapon = self getWeaponSlotWeapon(slot);

	// sprinting, none or ignore?
	if(!isValidWeapon(weapon)) return;

	clip = self getWeaponSlotClipAmmoDefault(weapon);
	if(!isDefined(clip) || !clip) clip = self getWeaponSlotClipAmmo(slot);

	reserve = self getWeaponSlotAmmoDefault(weapon);
	if(!isDefined(reserve) || reserve < 0) reserve = self getWeaponSlotAmmo(slot);

	// rank system reserve ammo override
	if(level.ex_wepo_loadout == 1)
	{
		if(!isWeaponType(weapon, "pistol")) rank_suffix = game["rank_ammo_gunclips_" + self.pers["rank"]];
			else rank_suffix = game["rank_ammo_pistolclips_" + self.pers["rank"]];

		reserve = clip * rank_suffix;
	}

	if(spawning)
	{
		// do nothing
	}
	else if(!gts)
	{
		// compare the ammo the weapon already has, if its greater, just fill the clip!
		reserve_check = self getWeaponSlotAmmo(slot);
		if(reserve_check > reserve) reserve = reserve_check;
	}

	self setWeaponSlotAmmo(slot, reserve);
	self setWeaponSlotClipAmmo(slot, clip);
}

setWeaponArray()
{
	// create the arrays
	if(!isDefined(self.weapon)) self.weapon = [];
	if(!isDefined(self.weaponin)) self.weaponin = [];

	// clear weapon primary
	if(!isDefined(self.weapon["primary"])) self.weapon["primary"] = spawnstruct();
	self.weapon["primary"].name = "none";
	self.weapon["primary"].clip = 0;
	self.weapon["primary"].reserve = 0;
	self.weapon["primary"].maxammo = 0;

	// clear weapon primaryb
	if(!isDefined(self.weapon["primaryb"])) self.weapon["primaryb"] = spawnstruct();
	self.weapon["primaryb"].name = "none";
	self.weapon["primaryb"].clip = 0;
	self.weapon["primaryb"].reserve = 0;
	self.weapon["primaryb"].maxammo = 0;

	// clear weapon virtual
	if(!isDefined(self.weapon["virtual"])) self.weapon["virtual"] = spawnstruct();
	self.weapon["virtual"].name = "none";
	self.weapon["virtual"].clip = 0;
	self.weapon["virtual"].reserve = 0;
	self.weapon["virtual"].maxammo = 0;

	// clear old weapon primary
	if(!isDefined(self.weapon["oldprimary"])) self.weapon["oldprimary"] = spawnstruct();
	self.weapon["oldprimary"].name = "none";
	self.weapon["oldprimary"].clip = 0;
	self.weapon["oldprimary"].reserve = 0;

	// clear old weapon primaryb
	if(!isDefined(self.weapon["oldprimaryb"])) self.weapon["oldprimaryb"] = spawnstruct();
	self.weapon["oldprimaryb"].name = "none";
	self.weapon["oldprimaryb"].clip = 0;
	self.weapon["oldprimaryb"].reserve = 0;

	// clear old current weapon
	if(!isDefined(self.weapon["current"])) self.weapon["current"] = spawnstruct();
	self.weapon["current"].name = "none";

	// slots to save nade count (gunship)
	self.weapon["frags"] = 0;
	self.weapon["smoke"] = 0;

	// clear weapon in slots
	if(!isDefined(self.weaponin["primary"])) self.weaponin["primary"] = spawnstruct();
	self.weaponin["primary"].slot = "primary";

	if(!isDefined(self.weaponin["primaryb"])) self.weaponin["primaryb"] = spawnstruct();
	self.weaponin["primaryb"].slot = "primaryb";
}

setSpawnWeapons()
{
	self endon("kill_thread");

	// save primary
	primary = self getWeaponSlotWeapon("primary");

	if(isDefined(primary) && primary != "none")
	{
		self.weapon["primary"].name = primary;
		self.weapon["primary"].clip = self getWeaponSlotClipAmmo("primary");
		self.weapon["primary"].reserve = self getWeaponSlotAmmo("primary");
		self.weapon["primary"].maxammo = self.weapon["primary"].clip + self.weapon["primary"].reserve;
	}
	else
	{
		self.weapon["primary"].name = "ignore";
		self.weapon["primary"].clip = 0;
		self.weapon["primary"].reserve= 0;
		self.weapon["primary"].maxammo = 0;
	}		

	// save current
	self.weapon["current"].name = self.weapon["primary"].name;

	// save secondary
	primaryb = self getWeaponSlotWeapon("primaryb");

	if(isDefined(primaryb) && primaryb != "none")
	{
		self.weapon["primaryb"].name = primaryb;
		self.weapon["primaryb"].clip = self getWeaponSlotClipAmmo("primaryb");
		self.weapon["primaryb"].reserve = self getWeaponSlotAmmo("primaryb");
		self.weapon["primaryb"].maxammo = self.weapon["primaryb"].clip + self.weapon["primaryb"].reserve;
	}
	else
	{
		self.weapon["primaryb"].name = "ignore";
		self.weapon["primaryb"].clip = 0;
		self.weapon["primaryb"].reserve= 0;
		self.weapon["primaryb"].maxammo = 0;
	}

	// if using secondary weapons with pistols, give them a pistol
	if(level.ex_wepo_secondary && level.ex_wepo_sidearm)
	{
		self setWeaponSlotWeapon("primaryb", "none");
		self giveSidearm();

		if(isDefined(self.pers["isbot"]))
		{
			// bots don't get a secondary, so keep sidearm in primaryb
			self.weapon["primaryb"].name = self getWeaponSlotWeapon("primaryb");
			self.weapon["primaryb"].clip = self getWeaponSlotClipAmmo("primaryb");
			self.weapon["primaryb"].reserve = self getWeaponSlotAmmo("primaryb");
			self.weapon["primaryb"].maxammo = self.weapon["primaryb"].clip + self.weapon["primaryb"].reserve;

			self.weapon["virtual"].name = "ignore";
			self.weapon["virtual"].clip = 0;
			self.weapon["virtual"].reserve = 0;
			self.weapon["virtual"].maxammo = 0;
		}
		else
		{
			// save pistol
			self.weapon["virtual"].name = self getWeaponSlotWeapon("primaryb");
			self.weapon["virtual"].clip = self getWeaponSlotClipAmmo("primaryb");
			self.weapon["virtual"].reserve = self getWeaponSlotAmmo("primaryb");
			self.weapon["virtual"].maxammo = self.weapon["virtual"].clip + self.weapon["virtual"].reserve;

			// put the original secondary to the primaryb slot
			if(self.weapon["primaryb"].name != "none" && self.weapon["primaryb"].name != "ignore")
			{
				self setWeaponSlotWeapon("primaryb", self.weapon["primaryb"].name);
				self setWeaponSlotAmmo("primaryb", self.weapon["primaryb"].reserve);
				self setWeaponSlotClipAmmo("primaryb", self.weapon["primaryb"].clip);
			}
		}
	}
	else
	{
		self.weapon["virtual"].name = "ignore";
		self.weapon["virtual"].clip = 0;
		self.weapon["virtual"].reserve = 0;
		self.weapon["virtual"].maxammo = 0;
	}

	// setup old primary
	self.weapon["oldprimary"].name = self getWeaponSlotWeapon("primary");
	self.weapon["oldprimary"].clip = self getWeaponSlotClipAmmo("primary");
	self.weapon["oldprimary"].reserve = self getWeaponSlotAmmo("primary");

	// setup old secondary
	self.weapon["oldprimaryb"].name = self getWeaponSlotWeapon("primaryb");
	self.weapon["oldprimaryb"].clip = self getWeaponSlotClipAmmo("primaryb");
	self.weapon["oldprimaryb"].reserve = self getWeaponSlotAmmo("primaryb");

	self.weaponin["primary"].slot = "primary";
	self.weaponin["primaryb"].slot = "primaryb";

	if(!isDefined(self.pers["sidearm"])) self.pers["sidearm"] = "ignore";
	if(level.debugweapons) debugLog(true, "setSpawnWeapons() completed");
}

weaponChangeMonitor()
{
	self endon("kill_thread");

	while(isAlive(self))
	{
		while(isPlayer(self) && self.ex_stopwepmon) wait( [[level.ex_fpstime]](0.05) );
		if(level.debugweapons) debugLog(false, "weaponChangeMonitor() started");

		while(isPlayer(self) && !self.ex_stopwepmon)
		{
			wait( [[level.ex_fpstime]](0.05) );

			// set the ammo for these slots
			self thread checkAmmo("primary");
			self thread checkAmmo("primaryb");

			// get the current weapon
			current = self getCurrentWeapon();

			if(current == game["sprint"] || current == self.weapon["current"].name) continue;

			// get the current primary and primaryb
			primary = self whatsInSlot("primary");
			primaryb = self whatsInSlot("primaryb");

			// weapon class enabled without sidearm -- do not allow secondary weapon
			if(level.ex_wepo_class && !level.ex_wepo_sidearm && isValidWeapon(primaryb))
			{
				// the knife perk will add the knife as primaryb, so allow that to happen
				if(!level.ex_specials || !level.ex_specials_knife || !extreme\_ex_specials::playerPerkIsLocked("knife", false))
				{
					if(level.debugweapons) debugLog(true, "weaponChangeMonitor() detected illegal secondary weapon");

					// move illegal primaryb to primary. If weapon is not allowed the slotWeaponCheck() will handle it
					self dropItem(primary);
					clip = self getWeaponSlotClipAmmo("primaryb");
					reserve = self getWeaponSlotAmmo("primaryb");
					self takeWeapon(primaryb);
					self setWeaponSlotWeapon("primary", primaryb);
					self setWeaponSlotClipAmmo("primary", clip);
					self setWeaponSlotAmmo("primary", reserve);
					primary = primaryb;
					self setWeaponSlotWeapon("primaryb", "none");
					primaryb = "none";
				}
			}

			if(primary != self.weapon[self.weaponin["primary"].slot].name)
				self slotWeaponCheck("primary");

			if((level.ex_wepo_secondary || level.ex_wepo_sidearm) && primaryb != self.weapon[self.weaponin["primaryb"].slot].name)
				self slotWeaponCheck("primaryb");

			if(isPlayer(self) && isDefined(current))
			{
				if(current != "ignore" && (current == self.weapon["oldprimary"].name || current == self.weapon["oldprimaryb"].name))
				{
					// if secondary weapons with pistols, switch the weapons around
					if(level.ex_wepo_secondary && level.ex_wepo_sidearm) self switchWeapons(self.weapon["current"].name, current);
						else self notify("weaponsave");
				}
			}
		}

		if(level.debugweapons) debugLog(false, "weaponChangeMonitor() suspended");
	}

	if(level.debugweapons) debugLog(false, "weaponChangeMonitor() terminated");
}

whatsInSlot(slot)
{
	slotweapon = self getWeaponSlotWeapon(slot);

	if(slotweapon != "none" && slotweapon != game["sprint"])
	{
		if(slotweapon == self.weapon["primary"].name) self.weaponin[slot].slot = "primary";
		else if(slotweapon == self.weapon["primaryb"].name) self.weaponin[slot].slot = "primaryb";
		else if(slotweapon == self.weapon["virtual"].name) self.weaponin[slot].slot = "virtual";
	}

	return slotweapon;
}

switchWeapons(current, newcurrent)
{
	self endon("kill_thread");

	// "ignore" weapon cannot be switched so return
	if(current == "ignore" || newcurrent == "ignore") return;

	if(current == self.weapon["primary"].name && isPrimary(self.weapon["primary"].name) && newcurrent == self.weapon["primaryb"].name && isSecondary(self.weapon["primaryb"].name)) self changeWeaponInSlot("primary", "virtual");
	else if(current == self.weapon["primaryb"].name && isSecondary(self.weapon["primaryb"].name) && newcurrent == self.weapon["virtual"].name && isPrimary(self.weapon["virtual"].name)) self changeWeaponInSlot("primaryb", "primary");
	else if(current == self.weapon["virtual"].name && isPrimary(self.weapon["virtual"].name) && newcurrent == self.weapon["primary"].name && isSecondary(self.weapon["primary"].name)) self changeWeaponInSlot("primary", "primaryb");
	else if(current == self.weapon["primary"].name && isSecondary(self.weapon["primary"].name) && newcurrent == self.weapon["primaryb"].name && isPrimary(self.weapon["primaryb"].name)) self changeWeaponInSlot("primaryb", "virtual");
	else if(current == self.weapon["primaryb"].name && isPrimary(self.weapon["primaryb"].name) && newcurrent == self.weapon["virtual"].name && isSecondary(self.weapon["virtual"].name)) self changeWeaponInSlot("primary", "primary");
	else if(current == self.weapon["virtual"].name && isSecondary(self.weapon["virtual"].name) && newcurrent == self.weapon["primary"].name && isPrimary(self.weapon["primary"].name)) self changeWeaponInSlot("primaryb", "primaryb");

	if(level.debugweapons) debugLog(false, "switchWeapons(" + current + "," + newcurrent + ") completed");
}

changeWeaponInSlot(slot, weaponslot)
{
	// "ignore" weapon cannot be switched so return
	if(self.weapon[weaponslot].name == "ignore" || self.weapon[weaponslot].name == "none") return;

	self setWeaponSlotWeapon(slot, self.weapon[weaponslot].name);
	self setWeaponSlotClipAmmo(slot, self.weapon[weaponslot].clip);
	self setWeaponSlotAmmo(slot, self.weapon[weaponslot].reserve);

	// save the new weapons for sprint system
	if(level.debugweapons) debugLog(false, "switchWeapons > changeWeaponInSlot(" + slot + ", self.weapon[" + weaponslot + "].name) completed");
	self notify("weaponsave");
}

slotWeaponCheck(slot)
{
	self endon("kill_thread");

	if(self.ex_stopwepmon) return;
	if(level.debugweapons) debugLog(false, "slotWeaponCheck(" + slot + ") called");

	weapon = self getWeaponSlotWeapon(slot);
	if(!isDefined(weapon) || weapon == "ignore") return;
	if(self.ex_sprinting || weapon == game["sprint"]) return;
	if(weapon == self.weapon["oldprimary"].name || weapon == self.weapon["oldprimaryb"].name) return;

	// did player just drop a detached turret?
	if(level.ex_turrets > 1 && isDefined(self.turretid))
	{
		stillhasturret = true;
		if(isWeaponType(self.weapon["old" + slot].name, "mobilemg")) stillhasturret = false;
		if(!stillhasturret)
		{
			if(level.debugweapons) debugLog(true, "weaponChangeMonitor() detected drop of unfixed turret");
			self thread extreme\_ex_turrets::turretRestore();
		}
	}

	if(weapon == "none")
	{
		if(level.debugweapons) debugLog(false, "slotWeaponCheck(" + slot + ") detected weapon drop");
		self saveNewSlot(slot, self.weaponin[slot].slot);
		return;
	}

	if(level.debugweapons) debugLog(false, "slotWeaponCheck(" + slot + ") detected weapon pick-up (" + weapon + ")");

	// check if this weapon is a pistol, and is allowed to be exchanged
	enemyweapon_skip = false;
	if(level.ex_wepo_sidearm == 1 && weapon != self.pers["sidearm"])
	{
		if(!level.ex_wepo_secondary && self.weaponin[slot].slot == "primaryb" || level.ex_wepo_secondary && self.weaponin[slot].slot == "virtual")
		{
			// the knife perk will change pistol to knife, so allow that to happen
			if(!level.ex_specials || !level.ex_specials_knife || !extreme\_ex_specials::playerPerkIsLocked("knife", false))
			{
				if(level.debugweapons) debugLog(false, "slotWeaponCheck(" + slot + ") detected illegal sidearm swap");

				// remove the original dropped weapon from the map first, so they can't get ammo from it
				entities = getentarray("weapon_" + self.pers["sidearm"], "classname");
				for(i = 0; i < entities.size; i++)
				{
					entity = entities[i];
					if(distance(entity.origin, self.origin) < 200) entities[i] delete();
				}

				self iprintlnbold(&"WEAPON_PISTOL_SWAP_NO_MSG1");
				self dropItem(self getWeaponSlotWeapon(slot));
				self setWeaponSlotWeapon(slot, self.pers["sidearm"]);
				self setWeaponSlotClipAmmo(slot, self.weapon[self.weaponin[slot].slot].clip);
				self setWeaponSlotAmmo(slot, self.weapon[self.weaponin[slot].slot].reserve);
			}
			enemyweapon_skip = true;
		}
	}

	if(!enemyweapon_skip && (level.ex_wepo_enemy == 0 || level.ex_wepo_enemy == 2))
	{
		// is this an enemy weapon?
		enemyweapon = false;
		if(!isWeaponType(weapon, self.pers["team"])) enemyweapon = true;

		// it is an enemy weapon, are we allowed to have it?
		if(enemyweapon)
		{
			enemyweapon_allowed = true;

			// enemy weapons are allowed only if you are low on ammo
			if(level.ex_wepo_enemy == 2)
			{
				// this is an enemy weapon and is only allowed if last weapon was low on ammo
				oldammo = self.weapon[self.weaponin[slot].slot].clip + self.weapon[self.weaponin[slot].slot].reserve;
				lowammo = int( (self.weapon[self.weaponin[slot].slot].maxammo / 100) * level.ex_wepo_enemy_pct);
				if(oldammo > lowammo)
				{
					enemyweapon_allowed = false;
					if(level.debugweapons) debugLog(false, "slotWeaponCheck(" + slot + "): enemy weapon rejected (" + weapon + " ; " + oldammo + " [" + self.weapon[self.weaponin[slot].slot].clip + "+" + self.weapon[self.weaponin[slot].slot].reserve + "] > " + lowammo + ")");
				}
				else if(level.debugweapons) debugLog(false, "slotWeaponCheck(" + slot + "): enemy weapon accepted (" + weapon + " ; " + oldammo + " [" + self.weapon[self.weaponin[slot].slot].clip + "+" + self.weapon[self.weaponin[slot].slot].reserve + "] <= " + lowammo + ")");
			}
			else if(!level.ex_wepo_enemy)
			{
				enemyweapon_allowed = false; // enemy weapons are not allowed
				if(level.debugweapons) debugLog(false, "slotWeaponCheck(" + slot + ") enemy weapon rejected (" + weapon + ")");
			}

			if(!enemyweapon_allowed)
			{
				// remove the original dropped weapon from the map first, so they can't get ammo from it
				entities = getentarray("weapon_" + self.weapon[self.weaponin[slot].slot].name, "classname");
				for(i = 0; i < entities.size; i++)
				{
					entity = entities[i];
					if(distance(entity.origin, self.origin) < 200) entities[i] delete();
				}

				if(level.ex_wepo_enemy == 2) self iprintlnbold(&"EWEAPON_AMMO_MSG0");
					else self iprintlnbold(&"EWEAPON_DISABLED");
				self dropItem(self getWeaponSlotWeapon(slot));
				self setWeaponSlotWeapon(slot, self.weapon[self.weaponin[slot].slot].name);
				self setWeaponSlotClipAmmo(slot, self.weapon[self.weaponin[slot].slot].clip);
				self setWeaponSlotAmmo(slot, self.weapon[self.weaponin[slot].slot].reserve);
			}
		}
	}

	self saveNewSlot(slot, self.weaponin[slot].slot);
}

dropCurrentWeapon(mode)
{
	self endon("kill_thread");

	// do not drop weapons if bots enabled
	if(level.ex_weapondrop_override) return;

	if(isPlayer(self))
	{
		current = self getCurrentWeapon();
		if(isWeaponType(current, "invalid")) return;

		// mode 0: drop if allowed
		// mode 1: unconditional drop
		// mode 2: take weapon instead
		if(!isDefined(mode)) mode = 0;

		switch(mode)
		{
			case 0: self thread dropItemIfAllowed(current); break;
			case 1: self dropItem(current); break;
			default: self takeWeapon(current); break;
		}
	}
}

saveNewSlot(slot, wepinslot)
{
	self endon("kill_thread");

	// double check!
	new_weapon = self getWeaponSlotWeapon(slot);
	is_dummy = isDummy(new_weapon);

	if(is_dummy || new_weapon == "none")
	{
		// if the slot already contains a dummy weapon, then reuse it!
		if(!is_dummy) new_weapon = getDummy();

		// save the dummy to the weapon array
		self.weapon[wepinslot].name = new_weapon;
		self.weapon[wepinslot].clip = 0;
		self.weapon[wepinslot].reserve = 0;
		self.weapon[wepinslot].maxammo = 0;

		// set the empty slot to a dummy weapon if secondary weapons enabled with pistol
		self setWeaponSlotWeapon(slot, new_weapon);
		self setWeaponSlotClipAmmo(slot, 0);
		self setWeaponSlotAmmo(slot, 0);

		// switch to new dummy weapon and save as current
		self switchToWeapon(new_weapon);
		self.weapon["current"].name = new_weapon;
	}
	else
	{
		// add new weapon to the weapon array
		self.weapon[wepinslot].name = self getWeaponSlotWeapon(slot);
		self.weapon[wepinslot].clip = self getWeaponSlotClipAmmo(slot);
		self.weapon[wepinslot].reserve = self getWeaponSlotAmmo(slot);

		clip = self getWeaponSlotClipAmmoDefault(self.weapon[wepinslot].name);
		reserve = self getWeaponSlotAmmoDefault(self.weapon[wepinslot].name);
		if(isDefined(clip) && isDefined(reserve)) self.weapon[wepinslot].maxammo = clip + reserve;
			else self.weapon[wepinslot].maxammo = self.weapon[wepinslot].clip + self.weapon[wepinslot].reserve;

		// switch to the new weapon and save as current
		self switchToWeapon(self.weapon[wepinslot].name);
		self.weapon["current"].name = self.weapon[wepinslot].name;
	}

	// save the new weapons for sprint system
	if(level.debugweapons) debugLog(true, "saveNewSlot(" + slot + "," + wepinslot + ") completed");
	self notify("weaponsave");
}

saveWeaponMonitor()
{
	self endon("kill_thread");

	while(isPlayer(self) && self.sessionstate == "playing")
	{
		self waittill("weaponsave");

		cw = self getCurrentWeapon();
		if(cw != game["sprint"] && cw != "none") self.weapon["current"].name = cw;

		// save the current primary for safekeeping
		primary = self getWeaponSlotWeapon("primary");
		if(primary != game["sprint"] && primary != "none")
		{
			self.weapon["oldprimary"].name = primary;
			self.weapon["oldprimary"].clip = self getWeaponSlotClipAmmo("primary");
			self.weapon["oldprimary"].reserve = self getWeaponSlotAmmo("primary");
		}

		// save the current primaryb for safekeeping
		primaryb = self getWeaponSlotWeapon("primaryb");
		if(primaryb != game["sprint"] && primaryb != "none")
		{	
			self.weapon["oldprimaryb"].name = primaryb;
			self.weapon["oldprimaryb"].clip = self getWeaponSlotClipAmmo("primaryb");
			self.weapon["oldprimaryb"].reserve = self getWeaponSlotAmmo("primaryb");
		}

		// teams share the same weapon file for special nades, so if one them is enabled, only count own type
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentfrags = self getammocount(self.pers["fragtype"]);
			else currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);

		self.weapon["frags"] = currentfrags;
		self.weapon["smoke"] = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);

		if(level.debugweapons) debugLog(true, "saveWeaponMonitor() completed");
		self notify("weaponsaved");
	}
}

restoreWeapons(refill)
{
	self takeAllWeapons();

	wait 0;

	// restore the saved primary weapon
	if(isValidWeapon(self.weapon["oldprimary"].name))
	{
		self setWeaponSlotWeapon("primary", self.weapon["oldprimary"].name);
		if(refill) self setAmmo("primary", false);
		else
		{
			self setWeaponSlotClipAmmo("primary", self.weapon["oldprimary"].clip);
			self setWeaponSlotAmmo("primary", self.weapon["oldprimary"].reserve);
		}
	}
	else self setWeaponSlotWeapon("primary", "none");

	// restore the saved secondary weapon
	if(isValidWeapon(self.weapon["oldprimaryb"].name))
	{
		self setWeaponSlotWeapon("primaryb", self.weapon["oldprimaryb"].name);
		if(refill) self setAmmo("primaryb", false);
		else
		{
			self setWeaponSlotClipAmmo("primaryb", self.weapon["oldprimaryb"].clip);
			self setWeaponSlotAmmo("primaryb", self.weapon["oldprimaryb"].reserve);
		}
	}
	else self setWeaponSlotWeapon("primaryb", "none");

	if(refill) self refillWeapon("virtual", false);

	// restore nades
	if(self.weapon["frags"])
	{
		self giveWeapon(self.pers["fragtype"]);
		self setWeaponClipAmmo(self.pers["fragtype"], self.weapon["frags"]);
	}
	if(self.weapon["smoke"])
	{
		self giveWeapon(self.pers["smoketype"]);
		self setWeaponClipAmmo(self.pers["smoketype"], self.weapon["smoke"]);
	}

	// restore old current weapon that we have saved
	if(isValidWeapon(self.weapon["current"].name)) self switchToWeapon(self.weapon["current"].name);

	if(level.debugweapons) debugLog(true, "restoreWeapons() completed");
}

checkAmmo(slot)
{
	weapon = self getWeaponSlotWeapon(slot);

	if(weapon == game["sprint"] || isSprinting(self)) return;

	if(weapon == self.weapon["primary"].name)
	{
		self.weapon["primary"].clip = self getWeaponSlotClipAmmo(slot);
		self.weapon["primary"].reserve = self getWeaponSlotAmmo(slot);
	}

	if(weapon == self.weapon["primaryb"].name)
	{
		self.weapon["primaryb"].clip = self getWeaponSlotClipAmmo(slot);
		self.weapon["primaryb"].reserve = self getWeaponSlotAmmo(slot);
	}

	if(weapon == self.weapon["virtual"].name)
	{
		self.weapon["virtual"].clip = self getWeaponSlotClipAmmo(slot);
		self.weapon["virtual"].reserve = self getWeaponSlotAmmo(slot);
	}
}

giveFirstAid()
{
	// set the default first aid kit value
	firstaidcount = level.ex_firstaid_kits;

	// check if random is on
	if(level.ex_firstaid_kits_random) firstaidcount = randomInt(level.ex_firstaid_kits);

	// check if ranksystem is on
	if(level.ex_ranksystem) firstaidcount = game["rank_firstaid_kits_" + self.pers["rank"]];

	// if all fails, give them at least one first aid kit
	if(!isDefined(firstaidcount)) firstaidcount = 1;

	// check if the player has more than whats on offer, if not set number of first aid kits for player
	if(!isDefined(self.ex_firstaidkits) || firstaidcount > self.ex_firstaidkits) self.ex_firstaidkits = firstaidcount;
	if(self.ex_firstaidkits) self.ex_canheal = true;
}

giveSidearm()
{
	weapon2 = self getWeaponSlotWeapon("primaryb");

	if(weapon2 != "none") return;

	sidearmtype = getSidearmType();
	self.pers["sidearm"] = sidearmtype;

	if(sidearmtype == "ignore") return;

	self setWeaponSlotWeapon("primaryb", sidearmtype);

	if(level.ex_wepo_loadout == 1)
	{
		// set primaryb
		clip = self getWeaponSlotClipAmmo("primaryb");
		ammo = clip * game["rank_ammo_pistolclips_" + self.pers["rank"]];
		self setWeaponSlotAmmo("primaryb", ammo);
	}
	else self setWeaponSlotAmmo("primaryb", self getWeaponSlotAmmoDefault(sidearmtype));
}

getSidearmType()
{
	self endon("disconnect");

	if(level.ex_currentgt == "ft" && level.ft_raygun) return "raygun_mp";

	if(level.ex_wepo_sidearm_type == 0)
	{
		sidearmtype = undefined;

		if(level.ex_modern_weapons)
		{
			if(self.pers["team"] == "allies")
			{
				switch(game["allies"])
				{
					case "american": sidearmtype = "deagle_mp"; break;
					case "british": sidearmtype = "beretta_mp"; break;
					default: sidearmtype = "glock_mp"; break;
				}
			}
			else sidearmtype = "hk45_mp";
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				switch(game["allies"])
				{
					case "american": sidearmtype = "colt_mp"; break;
					case "british": sidearmtype = "webley_mp"; break;
					default: sidearmtype = "tt30_mp"; break;
				}
			}
			else sidearmtype = "luger_mp";
		}
	}
	else
	{
		if(level.ex_modern_weapons) sidearmtype = "modern_knife_mp";
			else sidearmtype = "knife_mp";
	}

	// weapon limiter check
	if(level.ex_wepo_limiter)
	{
		if(isDefined(level.weapons[sidearmtype]))
		{
			if(level.ex_teamplay && level.ex_wepo_limiter_perteam)
			{
				if(self.pers["team"] == "allies")
				{
					if(isDefined(level.weapons[sidearmtype].allow_allies))
					{
						if(level.weapons[sidearmtype].allow_allies == 0) return "ignore";
							else return sidearmtype;
					}
					else return "ignore";
				}
				else
				{
					if(isDefined(level.weapons[sidearmtype].allow_axis))
					{
						if(level.weapons[sidearmtype].allow_axis == 0) return "ignore";
							else return sidearmtype;
					}
					else return "ignore";
				}
			}
			else
			{
				if(isDefined(level.weapons[sidearmtype].allow))
				{
					if(level.weapons[sidearmtype].allow == 0) return "ignore";
						else return sidearmtype;
				}
				else return "ignore";
			}
		}
		else return "ignore";
	}
	else return sidearmtype;
}

giveGrenades(rank_update, frags, smokes)
{
	self endon("disconnect");

	grenadetype_allies = getFragTypeAllies();
	grenadetype_axis = getFragTypeAxis();
	smokegrenadetype_allies = getSmokeTypeAllies();
	smokegrenadetype_axis = getSmokeTypeAxis();

	self takeWeapon(grenadetype_allies);
	self takeWeapon(grenadetype_axis);
	self takeWeapon(smokegrenadetype_allies);
	self takeWeapon(smokegrenadetype_axis);

	// set the grenade types
	if(self.pers["team"] == "allies")
	{
		self.pers["fragtype"] = grenadetype_allies;
		self.pers["smoketype"] = smokegrenadetype_allies;
		self.pers["enemy_fragtype"] = grenadetype_axis;
		self.pers["enemy_smoketype"] = smokegrenadetype_axis;
		if(level.ex_mbot && isDefined(self.pers["isbot"]))
		{
			self.botgrenade = "frag_grenade_" + game["allies"] + "_bot";
			self.botgrenadecount = 0;
			self.botsmoke = "smoke_grenade_" + game["allies"] + "_bot";
			self.botsmokecount = 0;
		}
	}
	else
	{
		self.pers["fragtype"] = grenadetype_axis;
		self.pers["smoketype"] = smokegrenadetype_axis;
		self.pers["enemy_fragtype"] = grenadetype_allies;
		self.pers["enemy_smoketype"] = smokegrenadetype_allies;
		if(level.ex_mbot && isDefined(self.pers["isbot"]))
		{
			self.botgrenade = "frag_grenade_german_bot";
			self.botgrenadecount = 0;
			self.botsmoke = "smoke_grenade_german_bot";
			self.botsmokecount = 0;
		}
	}

	// if entities monitor in defcon 2, do not give grenades
	if(level.ex_entities_defcon == 2) return;

	if(maps\mp\gametypes\_weapons::getWeaponStatus("fraggrenade"))
	{
		fraggrenadecount = 0;

		if(!rank_update)
		{
			switch(level.ex_frag_loadout)
			{
				case 1:	// eXtreme rank system settings
				fraggrenadecount = game["rank_ammo_grenades_" + self.pers["rank"]];
				break;

				case 2:	// eXtreme fixed settings
				fraggrenadecount = level.ex_wepo_frag;
				break;

				case 3: // eXtreme random settings
				fraggrenadecount = randomInt(level.ex_wepo_frag_random + 1);
				break;

				default: // eXtreme weapon class settings
				fraggrenadecount = getWeaponBasedGrenadeCount(self.pers["weapon"]);
				if(!fraggrenadecount && isDefined(self.pers["weapon2"]))
					fraggrenadecount = getWeaponBasedGrenadeCount(self.pers["weapon2"]);
				break;
			}
		}
		else fraggrenadecount = game["rank_ammo_grenades_" + self.pers["rank"]];

		// if all fails, give them 1 grenade
		if(!isDefined(fraggrenadecount)) fraggrenadecount = 1;

		// check how many nades they have already, if the new count is less, don't bother
		if(isDefined(frags) && frags > fraggrenadecount) fraggrenadecount = frags;

		if(fraggrenadecount)
		{
			if(level.ex_mbot && isDefined(self.pers["isbot"])) self.botgrenadecount = fraggrenadecount;
			self giveWeapon(self.pers["fragtype"]);
			self setWeaponClipAmmo(self.pers["fragtype"], fraggrenadecount);
		}
	}

	if(maps\mp\gametypes\_weapons::getWeaponStatus("smokegrenade"))
	{
		smokegrenadecount = 0;

		if(!rank_update)
		{
			switch(level.ex_smoke_loadout)
			{
				case 1:	// eXtreme rank system settings
				smokegrenadecount = game["rank_ammo_smoke_grenades_" + self.pers["rank"]];
				break;

				case 2: // eXtreme fixed settings
				smokegrenadecount = level.ex_wepo_smoke;
				break;

				case 3:	// eXtreme random settings
				smokegrenadecount = randomInt(level.ex_wepo_smoke_random + 1);
				break;

				default: // eXtreme weapon class settings
				smokegrenadecount = getWeaponBasedSmokeGrenadeCount(self.pers["weapon"]);
				if(!smokegrenadecount && isDefined(self.pers["weapon2"]))
					smokegrenadecount = getWeaponBasedSmokeGrenadeCount(self.pers["weapon2"]);
				break;
			}
		}
		else smokegrenadecount = game["rank_ammo_smoke_grenades_" + self.pers["rank"]];

		// if all fails, give them 1 grenade
		if(!isDefined(smokegrenadecount)) smokegrenadecount = 1;

		// check how many nades they have already, if the new count is less, don't bother
		if(isDefined(smokes) && smokes > smokegrenadecount) smokegrenadecount = smokes;

		if(smokegrenadecount)
		{
			if(level.ex_mbot && isDefined(self.pers["isbot"])) self.botsmokecount = smokegrenadecount;
			self giveWeapon(self.pers["smoketype"]);
			self setWeaponClipAmmo(self.pers["smoketype"], smokegrenadecount);
		}
	}
}

getFragTypeAllies()
{
	if(level.ex_firenades) fragtype = "fire_mp";
		else if(level.ex_gasnades) fragtype = "gas_mp";
			else if(level.ex_satchelcharges) fragtype = "satchel_mp";
				else fragtype = "frag_grenade_" + game["allies"] + "_mp";

	return fragtype;
}

getFragTypeAxis()
{
	if(level.ex_firenades) fragtype = "fire_mp";
		else if(level.ex_gasnades) fragtype = "gas_mp";
			else if(level.ex_satchelcharges) fragtype = "satchel_mp";
				else fragtype = "frag_grenade_" + game["axis"] + "_mp";

	return fragtype;
}

getSmokeTypeAllies()
{
	smoketype = "smoke_grenade_" + game["allies"] + getSmokeColour(level.ex_smoke[game["allies"]]) + "mp";
	return smoketype;
}

getSmokeTypeAxis()
{
	smoketype = "smoke_grenade_" + game["axis"] + getSmokeColour(level.ex_smoke[game["axis"]]) + "mp";
	return smoketype;
}

isValidWeapon(weapon)
{
	if(!isDefined(weapon)) return false;
	if(weapon == "none") return false;
	if(weapon == "ignore") return false;
	if(weapon == game["sprint"]) return false;
	return true;
}

getWeaponSlotAmmoDefault(weapon)
{
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return 999;

	if(isDefined(weapon))
	{
		if(weapon == "none" || weapon == "ignore" || weapon == game["sprint"])
		{
			logPrint("getWeaponSlotAmmoDefault() for player " + self.name + ": invalid weapon >>> " + weapon + " <<<\n");
		}
		else
		{
			if(isDefined(level.weapons[weapon]))
			{
				if(isDefined(level.weapons[weapon].ammo_limit)) return level.weapons[weapon].ammo_limit;
					else logPrint("getWeaponSlotAmmoDefault() for player " + self.name + ": ammo_limit not found >>> " + weapon + " <<<\n");
			}
			else logPrint("getWeaponSlotAmmoDefault() for player " + self.name + ": weapon not found >>> " + weapon + " <<<\n");
		}
	}

	//return( self getWeaponSlotAmmo(weaponslot) );
	return 0;
}

getWeaponSlotClipAmmoDefault(weapon)
{
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return 999;

	if(isDefined(weapon))
	{
		if(weapon == "none" || weapon == "ignore" || weapon == game["sprint"])
		{
			logPrint("getWeaponSlotClipAmmoDefault() for player " + self.name + ": invalid weapon >>> " + weapon + " <<<\n");
		}
		else
		{
			if(isDefined(level.weapons[weapon]))
			{
				if(isDefined(level.weapons[weapon].clip_limit)) return level.weapons[weapon].clip_limit;
					else logPrint("getWeaponSlotClipAmmoDefault() for player " + self.name + ": clip_limit not found >>> " + weapon + " <<<\n");
			}
			else logPrint("getWeaponSlotClipAmmoDefault() for player " + self.name + ": weapon not found >>> " + weapon + " <<<\n");
		}
	}

	//return( self getWeaponSlotClipAmmo(weaponslot) );
	return 0;
}

getWeaponBasedGrenadeCount(weapon)
{
	if(!isDefined(weapon) || !isValidWeapon(weapon)) return 0;

	if(isWeaponType(weapon, "sniper")) return level.ex_wepo_frag_stock_sniper;
	if(isWeaponType(weapon, "rifle")) return level.ex_wepo_frag_stock_rifle;
	if(isWeaponType(weapon, "mg")) return level.ex_wepo_frag_stock_mg;
	if(isWeaponType(weapon, "smg")) return level.ex_wepo_frag_stock_smg;
	if(isWeaponType(weapon, "shotgun")) return level.ex_wepo_frag_stock_shot;
	if(isWeaponType(weapon, "rl")) return level.ex_wepo_frag_stock_rl;
	if(isWeaponType(weapon, "ft")) return level.ex_wepo_frag_stock_ft;
	return 0;
}

getWeaponBasedSmokeGrenadeCount(weapon)
{
	if(!isDefined(weapon) || !isValidWeapon(weapon)) return 0;

	if(isWeaponType(weapon, "sniper")) return level.ex_wepo_smoke_stock_sniper;
	if(isWeaponType(weapon, "rifle")) return level.ex_wepo_smoke_stock_rifle;
	if(isWeaponType(weapon, "mg")) return level.ex_wepo_smoke_stock_mg;
	if(isWeaponType(weapon, "smg")) return level.ex_wepo_smoke_stock_smg;
	if(isWeaponType(weapon, "shotgun")) return level.ex_wepo_smoke_stock_shot;
	if(isWeaponType(weapon, "rl")) return level.ex_wepo_smoke_stock_rl;
	if(isWeaponType(weapon, "ft")) return level.ex_wepo_smoke_stock_ft;
	return 0;
}

isWeaponType(weapon, type)
{
	if(!isDefined(weapon)) return false;

	// look-ups that don't require weapons array records
	switch(type)
	{
		case "invalid":
			switch(weapon)
			{
				case "none":
				case "ignore":
				case "dummy1_mp":
				case "dummy2_mp":
				case "dummy3_mp": return true;
				default: return false;
			}

		case "30cal":
			switch(weapon)
			{
				case "30cal_duck_mp":
				case "30cal_prone_mp":
				case "30cal_stand_mp": return true;
				default: return false;
			}

		case "mg42":
			switch(weapon)
			{
				case "mg42_bipod_duck_mp":
				case "mg42_bipod_prone_mp":
				case "mg42_bipod_stand_mp": return true;
				default: return false;
			}

		case "mobilemg":
			switch(weapon)
			{
				case "mobile_30cal":
				case "mobile_mg42": return true;
				default: return false;
			}

		// Check if weapon is a turret
		case "turret":
			if(isWeaponType(weapon, "30cal") || isWeaponType(weapon, "mg42") || isWeaponType(weapon, "mobilemg")) return true;
			return false;

		// Check if weapon is a frag grenade (or replacement)
		case "fragspecial":
			if(weapon == "fire_mp" || weapon == "gas_mp" || weapon == "satchel_mp") return true;
			return false;

		// Check if weapon is smoke grenade
		case "smoke":
			if(level.ex_smoke[game["allies"]] < 7 && weapon == getSmokeTypeAllies() ||
			   level.ex_smoke[game["axis"]] < 7 && weapon == getSmokeTypeAxis()) return true;
			return false;

		// Check if weapon is smoke replacement
		case "smokespecial":
			if(level.ex_smoke[game["allies"]] >= 7 && weapon == getSmokeTypeAllies() ||
			   level.ex_smoke[game["axis"]] >= 7 && weapon == getSmokeTypeAxis()) return true;
			return false;

		// Check if weapon is VIP smoke grenade
		case "smokevip":
			vip_allies = "smoke_grenade_" + game["allies"] + "_vip_mp";
			if(weapon == vip_allies) return true;
			vip_axis = "smoke_grenade_" + game["axis"] + "_vip_mp";
			if(weapon == vip_axis) return true;
			return false;
	}

	// look-ups that do require weapons array records
	if(!isDefined(level.weapons[weapon])) return false;
	switch(type)
	{
		case "wmd":
			if(level.weapons[weapon].classname == "wmd") return true;
			return false;

		// Check if weapon is a frag grenade
		case "frag":
			if(level.weapons[weapon].classname == "frag") return true;
			return false;

		// Check if weapon is a super grenade
		case "super":
			if(level.weapons[weapon].classname == "super") return true;
			return false;

		// Check if weapon is fire grenade
		case "fire":
			if(level.weapons[weapon].classname == "fire") return true;
			return false;

		// Check if weapon is gas grenade
		case "gas":
			if(level.weapons[weapon].classname == "gas") return true;
			return false;

		// Check if weapon is satchel charge
		case "satchel":
			if(level.weapons[weapon].classname == "satchel") return true;
			return false;

		// Check if weapon is a proper suicide bomb
		case "kamikaze":
			if(level.weapons[weapon].classname == "frag" ||
			   level.weapons[weapon].classname == "satchel") return true;
			return false;

		// Check if weapon is a rifle
		case "rifle":
			if(level.weapons[weapon].classname == "rifle") return true;
			return false;

		// Check if weapon is a bolt action rifle
		case "boltrifle":
			if(level.weapons[weapon].classname == "rifle" &&
			   isDefined(level.weapons[weapon].subclass) &&
			   level.weapons[weapon].subclass == "bolt") return true;
			return false;

		// Check if weapon is a semi automatic rifle
		case "semirifle":
			if(level.weapons[weapon].classname == "rifle" &&
			   isDefined(level.weapons[weapon].subclass) &&
			   level.weapons[weapon].subclass == "semi") return true;
			return false;

		// Check if weapon is smg
		case "smg":
			if(level.weapons[weapon].classname == "smg") return true;
			return false;

		// Check if weapon is mg
		case "mg":
			if(level.weapons[weapon].classname == "mg") return true;
			return false;

		// Check if weapon is sniper rifle
		case "sniper":
			if(level.weapons[weapon].classname == "sniper" ||
			   level.weapons[weapon].classname == "sniperlr") return true;
			return false;

		// Check if weapon is SR sniper rifle
		case "snipersr":
			if(level.weapons[weapon].classname == "sniper") return true;
			return false;

		// Check if weapon is a LR sniper rifle
		case "sniperlr":
			if(level.weapons[weapon].classname == "sniperlr") return true;
			return false;

		// Check if weapons is bolt rifle or sniper rifle
		case "boltsniper":
			if(isWeaponType(weapon, "boltrifle") ||
			   level.weapons[weapon].classname == "sniper" ||
			   level.weapons[weapon].classname == "sniperlr") return true;
			return false;

		// Check if weapon is rocket launcher
		case "rl":
			if(level.weapons[weapon].classname == "rl") return true;
			return false;

		// Check if weapon is shotgun
		case "shotgun":
			if(level.weapons[weapon].classname == "shotgun") return true;
			return false;

		// Check if weapon is sidearm
		case "sidearm":
			if(level.weapons[weapon].classname == "pistol" ||
			   level.weapons[weapon].classname == "knife" ||
			   level.weapons[weapon].classname == "vip" ||
			   level.weapons[weapon].classname == "raygun") return true;
			return false;

		// Check if weapon is pistol
		case "pistol":
			if(level.weapons[weapon].classname == "pistol") return true;
			return false;

		// Check if weapon is knife
		case "knife":
			if(level.weapons[weapon].classname == "knife") return true;
			return false;

		// Check if weapon is VIP pistol
		case "vip":
			if(level.weapons[weapon].classname == "vip") return true;
			return false;

		// Check if weapon is flamethrower
		case "ft":
			if(level.weapons[weapon].classname == "ft") return true;
			return false;

		// Check if weapon is perk
		case "perk":
			if(level.weapons[weapon].classname == "perk") return true;
			return false;

		// Check if weapon is perk weapon
		case "perkweapon":
			if(isDefined(level.weapons[weapon].perkindex)) return true;
			return false;

		// Check if weapon is perk weapon
		case "perkonhand":
			if(isDefined(level.weapons[weapon].perkindex) &&
			   game["perkcatalog"][level.weapons[weapon].perkindex]["weapontype"] == 0) return true;
			return false;

		// Check if weapon is perk weapon
		case "perkfrag":
			if(isDefined(level.weapons[weapon].perkindex) &&
			   game["perkcatalog"][level.weapons[weapon].perkindex]["weapontype"] == 1) return true;
			return false;

		// Check if weapon is perk weapon
		case "perksmoke":
			if(isDefined(level.weapons[weapon].perkindex) &&
			   game["perkcatalog"][level.weapons[weapon].perkindex]["weapontype"] == 2) return true;
			return false;

		// Check if weapon is american
		case "american":
			if((level.weapons[weapon].nat & 1) == 1) return true;
			return false;

		// Check if weapon is british
		case "british":
			if((level.weapons[weapon].nat & 2) == 2) return true;
			return false;

		// Check if weapon is allies
		case "allies":
			if((level.weapons[weapon].nat & 4) != 4) return true;
			return false;

		// Check if weapon is german
		case "axis":
		case "german":
			if((level.weapons[weapon].nat & 4) == 4) return true;
			return false;

		// Check if weapon is russian
		case "russian":
			if((level.weapons[weapon].nat & 8) == 8) return true;
			return false;
	}
	
	return false;
}

getSmokeColour(num)
{
	switch(num)
	{
		case 1: return "_blue_";
		case 2: return "_green_";
		case 3: return "_orange_";
		case 4: return "_pink_";
		case 5: return "_red_";
		case 6: return "_yellow_";
		case 7: return "_fire_";
		case 8: return "_gas_";
		case 9: return "_satchel_";
		case 0:
		default: return "_";
	}
}

setWeaponClientStatus(status)
{
	self endon("disconnect");

	if(!isDefined(status)) status = false;

	if(isValidWeapon(self.pers["weapon"]))
	{
		if(!status) self updateDisabledSingleClient(self.pers["weapon"]);
			else self updateAllowedSingleClient(self.pers["weapon"]);
	}

	if(isValidWeapon(self.pers["weapon2"]))
	{
		if(!status) self updateDisabledSingleClient(self.pers["weapon2"]);
			else self updateAllowedSingleClient(self.pers["weapon2"]);
	}
}

isSprinting(player)
{
	if(player getCurrentWeapon("primary") == game["sprint"]) return true;
	else return false;
}

isPrimary(weapon)
{
	if(isDefined(weapon) && weapon == self getWeaponSlotWeapon("primary")) return true;
	else return false;
}

isSecondary(weapon)
{
	if(isDefined(weapon) && weapon == self getWeaponSlotWeapon("primaryb")) return true;
	else return false;
}

isDummy(weapon)
{
	if(isDefined(weapon) && weapon == "dummy1_mp" || weapon == "dummy2_mp" || weapon == "dummy3_mp") return true;
	else return false;
}

getDummy()
{
	self endon("disconnect");

	if(self.weapon["primary"].name != "dummy1_mp" && self.weapon["primaryb"].name != "dummy1_mp" && self.weapon["virtual"].name != "dummy1_mp") return "dummy1_mp";
	else if(self.weapon["primary"].name != "dummy2_mp" && self.weapon["primaryb"].name != "dummy2_mp" && self.weapon["virtual"].name != "dummy2_mp") return "dummy2_mp";
	else if(self.weapon["primary"].name != "dummy3_mp" && self.weapon["primaryb"].name != "dummy3_mp" && self.weapon["virtual"].name != "dummy3_mp") return "dummy3_mp";
	return "dummy3_mp";
}

replenishWeapons(gts)
{
	self endon("kill_thread");

	if(!isDefined(gts)) gts = false;

	if(!gts)
	{
		self [[level.ex_dWeapon]]();

		// stop the weapon monitor
		self.ex_stopwepmon = true;

		// play reload sound for effect
		self playlocalsound("weap_bar_reload");

		wait( [[level.ex_fpstime]](0.25) );
	}

	if(isPlayer(self))
	{
		if(level.ex_wepo_class)
		{
			self setAmmo("primary", gts);
			self setAmmo("primaryb", gts);
		}
		else
		{
			// replenish all slots
			self refillWeapon("primary", gts);
			self refillWeapon("primaryb", gts);
			self refillWeapon("virtual", gts);
		}

		if(!gts)
		{
			// save the new weapon variables
			self notify("weaponsave");

			// start the weapon monitor
			self.ex_stopwepmon = false;
		}
	}

	if(!gts)
	{
		wait( [[level.ex_fpstime]](3) );
		if(isPlayer(self)) self [[level.ex_eWeapon]]();
	}
}

replenishGrenades(gts)
{
	self endon("kill_thread");

	if(!isDefined(gts)) gts = false;

	if(!gts)
	{
		// play reload sound for effect
		self playlocalsound("grenade_pickup");

		wait( [[level.ex_fpstime]](0.25) );

		// replenish grenades
		// teams share the same weapon file for special nades, so if one them is enabled, only count own type
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) frags = self getammocount(self.pers["fragtype"]);
			else frags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);

		smokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	}
	else
	{
		frags = 0;
		smokes = 0;
	}

	if(isPlayer(self)) self giveGrenades(false, frags, smokes);
}

replenishFirstaid(gts)
{
	self endon("kill_thread");

	if(!isDefined(gts)) gts = false;

	if(!gts)
	{
		// play reload sound for effect
		self playlocalsound("health_pickup_large");
		wait( [[level.ex_fpstime]](0.25) );
	}
	else self.ex_firstaidkits = 0;

	// replenish firstaid
	if(isPlayer(self)) self giveFirstAid();

	// refresh the number of firstaid kits on screen
	hud_index = playerHudIndex("firstaid_kits");
	if(hud_index != -1)
	{
		playerHudSetValue(hud_index, self.ex_firstaidkits);
		if(self.ex_firstaidkits == 0) kits_color = (1, 0, 0);
			else kits_color = (1, 1, 1);
		playerHudSetColor(hud_index, kits_color);
	}
}

refillWeapon(slot, gts)
{
	if(!isDefined(self.weapon) || !isDefined(self.weapon[slot].name)) return;

	if(!isDefined(gts)) gts = false;

	// refill all eXtreme+ slots
	weapon = self.weapon[slot].name;

	// sprinting, none or ignore?
	if(!isValidWeapon(weapon)) return;

	clip = self getWeaponSlotClipAmmoDefault(weapon);
	if(!isDefined(clip) || !clip) clip = self getWeaponSlotClipAmmo(slot);

	reserve = self getWeaponSlotAmmoDefault(weapon);
	if(!isDefined(reserve) || reserve < 0) reserve = self getWeaponSlotAmmo(slot);

	// rank system reserve ammo override
	if(level.ex_wepo_loadout == 1)
	{
		if(isWeaponType(weapon, "pistol")) rank_suffix = game["rank_ammo_pistolclips_" + self.pers["rank"]];
		else rank_suffix = game["rank_ammo_gunclips_" + self.pers["rank"]];

		reserve = clip * rank_suffix;
	}

	if(!gts)
	{
		// compare the ammo the weapon already has, if its greater, just fill the clip!
		reserve_check = self.weapon[slot].reserve;
		if(reserve_check > reserve) reserve = reserve_check;
	}

	self.weapon[slot].clip = clip;
	self.weapon[slot].reserve = reserve;
	self.weapon[slot].maxammo = clip + reserve;

	// now do the real slots if this weapon is in them!
	if(weapon == self getWeaponSlotWeapon("primary")) self setAmmo("primary", gts);
	else if(weapon == self getWeaponSlotWeapon("primaryb")) self setAmmo("primaryb", gts);
}

updateLoadout(promotion)
{
	if(!isDefined(promotion)) return;

	// update the ammo, first aid and binocs
	if(promotion)
	{
		self refillWeapon("primary", false);
		self refillWeapon("primaryb", false);
		self refillWeapon("virtual", false);

		if(level.ex_medicsystem) self giveFirstAid();
	}

	// process landmine
	if(level.ex_landmines)
	{
		// rank system update
		if(level.ex_landmines_loadout)
		{
			currentlandmines = 0;
			newlandmines = 0;

			if(isDefined(self.mine_ammo)) currentlandmines = self.mine_ammo;
				else currentlandmines = 0;
			if(!isDefined(currentlandmines)) currentlandmines = 0;
			newlandmines = game["rank_ammo_landmines_" + self.pers["rank"]];

			if(promotion)
			{
				if(level.ex_rank_promote_nades)
				{
					totallandmines = currentlandmines + newlandmines;
					if(totallandmines > level.ex_landmines_cap) totallandmines = level.ex_landmines_cap;
					self thread extreme\_ex_landmines::updateLandmines(totallandmines);
				}
			}
			else if(level.ex_rank_demote_nades && currentlandmines > newlandmines)
			{
				totallandmines = newlandmines;
				if(totallandmines > level.ex_landmines_cap) totallandmines = level.ex_landmines_cap;
				self thread extreme\_ex_landmines::updateLandmines(totallandmines);
			}
		}
		// maxammo perk
		else
		{
			self thread extreme\_ex_landmines::updateLandmines(self.mine_ammo_max);
		}
	}

	// get current nade count
	// teams share the same weapon file for special nades, so if one of them is enabled, only count own type
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentfrags = self getammocount(self.pers["fragtype"]);
		else currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	if(!isDefined(currentfrags)) currentfrags = 0;
	currentsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	if(!isDefined(currentsmokes)) currentsmokes = 0;

	// give nades based on new rank. promotion if 1 (true), demotion if 0 (false), max ammo specialty if 2
	self giveGrenades((promotion != 2));

	// get new nade count
	// teams share the same weapon file for special nades, so if one of them is enabled, only count own type
	if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) newfrags = self getammocount(self.pers["fragtype"]);
		else newfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
	if(!isDefined(newfrags)) newfrags = 0;
	newsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
	if(!isDefined(newsmokes)) newsmokes = 0;

	if(promotion)
	{
		if(!level.ex_ranksystem || level.ex_rank_promote_nades) // promotion; promote nades
		{
			totalfrags = currentfrags + newfrags;
			if(totalfrags > level.ex_frag_cap) totalfrags = level.ex_frag_cap;
			if(totalfrags)
			{
				if(!newfrags) self giveWeapon(self.pers["fragtype"]);
				self setWeaponClipAmmo(self.pers["fragtype"], totalfrags);
			}

			totalsmokes = currentsmokes + newsmokes;
			if(totalsmokes > level.ex_smoke_cap) totalsmokes = level.ex_smoke_cap;
			if(totalsmokes)
			{
				if(!newsmokes) self giveWeapon(self.pers["smoketype"]);
				self setWeaponClipAmmo(self.pers["smoketype"], totalsmokes);
			}
		}
		else // promotion; keep current
		{
			if(currentfrags && !newfrags)
			{
				self giveWeapon(self.pers["fragtype"]);
				self setWeaponClipAmmo(self.pers["fragtype"], currentfrags);
			}

			if(currentsmokes && !newsmokes)
			{
				self giveWeapon(self.pers["smoketype"]);
				self setWeaponClipAmmo(self.pers["smoketype"], currentsmokes);
			}
		}
	}
	else if(level.ex_ranksystem && level.ex_rank_demote_nades) // demotion; demote nades
	{
		if(currentfrags > newfrags)
		{
			totalfrags = newfrags;
			if(totalfrags > level.ex_frag_cap) totalfrags = level.ex_frag_cap;
			if(!newfrags) self giveWeapon(self.pers["fragtype"]);
			self setWeaponClipAmmo(self.pers["fragtype"], totalfrags);
		}

		if(currentsmokes > newsmokes)
		{
			totalsmokes = newsmokes;
			if(totalsmokes > level.ex_smoke_cap) totalsmokes = level.ex_smoke_cap;
			if(!newsmokes) self giveWeapon(self.pers["smoketype"]);
			self setWeaponClipAmmo(self.pers["smoketype"], totalsmokes);
		}
	}
	else // demotion; keep current
	{
		if(currentfrags && !newfrags)
		{
			self giveWeapon(self.pers["fragtype"]);
			self setWeaponClipAmmo(self.pers["fragtype"], currentfrags);
		}

		if(currentsmokes && !newsmokes)
		{
			self giveWeapon(self.pers["smoketype"]);
			self setWeaponClipAmmo(self.pers["smoketype"], currentsmokes);
		}
	}
}

debugLog(logweap, procname)
{
	if(!level.debugweapons) return;
	//if(!isDefined(self.ex_name)) return;
	//if(self.name != "bot1") return;
	//if(isDefined(self.pers["isbot"])) return;

	wait( [[level.ex_fpstime]](0.05) );
	logproc = true;
	if(!isDefined(procname)) logproc = false;

	logprint("\n********** " + self.name + " **********\n");
	if(logproc) logprint("WEAPON DEBUG: procedure " + procname + "\n");
	if(logweap)
	{
		primary = self getWeaponSlotWeapon("primary");
		secondary = self getWeaponSlotWeapon("primaryb");
		current = self getCurrentWeapon();

		if(level.ex_wepo_secondary)
		{
			logprint("WEAPON DEBUG:           self.pers[\"weapon1\"] " + self.pers["weapon1"] + " -- actual primary " + primary + "\n");
			logprint("WEAPON DEBUG:           self.pers[\"weapon2\"] " + self.pers["weapon2"] + " -- actual secondary " + secondary + "\n");
		}
		else
			logprint("WEAPON DEBUG:            self.pers[\"weapon\"] " + self.pers["weapon"] + " -- actual primary " + primary + " (secondary: " + secondary + ")\n");

		logprint("WEAPON DEBUG:  self.weaponin[\"primary\"].slot " + self.weaponin["primary"].slot + "\n");
		logprint("WEAPON DEBUG: self.weaponin[\"primaryb\"].slot " + self.weaponin["primaryb"].slot + "\n");

		logprint("WEAPON DEBUG:         self.weapon[\"primary\"] " + self.weapon["primary"].name + " (self.weapon[\"oldprimary\"] " + self.weapon["oldprimary"].name + ")\n");
		logprint("WEAPON DEBUG:        self.weapon[\"primaryb\"] " + self.weapon["primaryb"].name + " (self.weapon[\"oldprimaryb\"] " + self.weapon["oldprimaryb"].name + ")\n");
		logprint("WEAPON DEBUG:         self.weapon[\"virtual\"] " + self.weapon["virtual"].name + "\n");
		logprint("WEAPON DEBUG:         self.weapon[\"current\"] " + self.weapon["current"].name + " -- actual current " + current + "\n");
	}
}
