#include extreme\_ex_specials;
#include extreme\_ex_weapons;

perkInit()
{
	// perk related precaching
}

perkInitPost()
{
	// perk related precaching after map load
	// done here because the weapon needs to be registered first by _weapons::registerWeaponsOther(),
	// which is done AFTER perkInit but BEFORE perkInitPost
	level.ex_specials_knife_modern = false;
	if( (!level.ex_specials_knife_model && level.ex_modern_weapons) || level.ex_specials_knife_model == 2) level.ex_specials_knife_modern = true;

	if(level.ex_specials_knife_modern)
	{
		[[level.ex_PrecacheItem]]("modern_knife_mp");
		[[level.ex_PrecacheModel]]("xmodel/viewmodel_modern_knife");
	}
	else
	{
		[[level.ex_PrecacheItem]]("knife_mp");
		[[level.ex_PrecacheModel]]("xmodel/viewmodel_knife");
	}
}

perkCheck()
{
	// checks before being able to buy this perk
	if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
	    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) return(false);

	return(!hasKnife());
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
		else self iprintlnbold(&"SPECIALS_KNIFE_READY");

	self thread hudNotifySpecial(index, 5);
	if(level.ex_specials_keeptimer) thread perkKeepTimer(index);
		else self thread playerStartUsingPerk(index, false);

	thread giveKnife();
}

perkKeepTimer(index)
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](level.ex_specials_keeptimer) );
	self thread playerStartUsingPerk(index, false);
}

giveKnife()
{
	if(level.ex_specials_knife_modern) weaponfile = "modern_knife_mp";
		else weaponfile = "knife_mp";

	weaponslot = "primaryb";
	if(!level.ex_wepo_class && level.ex_wepo_secondary && level.ex_wepo_sidearm)
	{
		if(isPistol("primary")) weaponslot = "primary";
			else if(isPistol("primaryb")) weaponslot = "primaryb";
				else weaponslot = "virtual";
	}

	if(weaponslot != "virtual")
	{
		weaponinslot = self getWeaponSlotWeapon(weaponslot);
		self takeWeapon(weaponinslot);
		self setWeaponSlotWeapon(weaponslot, weaponfile);

		clip = self extreme\_ex_weapons::getWeaponSlotClipAmmoDefault(weaponfile);
		if(!isDefined(clip) || !clip) clip = self getWeaponSlotClipAmmo(weaponslot);
		self setWeaponSlotClipAmmo(weaponslot, clip);

		reserve = self extreme\_ex_weapons::getWeaponSlotAmmoDefault(weaponfile);
		if(!isDefined(reserve) || reserve < 0) reserve = self getWeaponSlotAmmo(weaponslot);
		self setWeaponSlotAmmo(weaponslot, reserve);

		if(!level.ex_wepo_secondary && !level.ex_wepo_sidearm)
		{
			self.weapon[weaponslot].name = weaponfile;
			self.weapon[weaponslot].clip = clip;
			self.weapon[weaponslot].reserve = reserve;
			self.weapon[weaponslot].maxammo = clip + reserve;
		}
	}
	else
	{
		clip = self extreme\_ex_weapons::getWeaponSlotClipAmmoDefault(weaponfile);
		if(!isDefined(clip) || !clip) clip = self getWeaponSlotClipAmmo(weaponslot);

		reserve = self extreme\_ex_weapons::getWeaponSlotAmmoDefault(weaponfile);
		if(!isDefined(reserve) || reserve < 0) reserve = self getWeaponSlotAmmo(weaponslot);

		self.weapon[weaponslot].name = weaponfile;
		self.weapon[weaponslot].clip = clip;
		self.weapon[weaponslot].reserve = reserve;
		self.weapon[weaponslot].maxammo = clip + reserve;
	}
}

hasKnife()
{
	if(level.ex_wepo_class)
	{
		if(level.ex_wepo_sidearm)
		{
			if(isKnife("primary") || isKnife("primaryb")) return(true);
		}
		else if(isKnife("primary")) return(true);
	}
	else
	{
		if(level.ex_wepo_secondary)
		{
			if(level.ex_wepo_sidearm)
			{
				if(isKnife("primary") || isKnife("primaryb") || isKnife("virtual")) return(true);
			}
			else if(isKnife("primary") || isKnife("primaryb")) return(true);
		}
		else
		{
			if(level.ex_wepo_sidearm)
			{
				if(isKnife("primary") || isKnife("primaryb")) return(true);
			}
			else if(isKnife("primary")) return(true);
		}
	}

	return(false);
}

isKnife(weaponslot)
{
	if(!isDefined(self.weapon) || !isDefined(self.weapon[weaponslot])) return(false);
	weaponname = self.weapon[weaponslot].name;
	if(extreme\_ex_weapons::isWeaponType(weaponname, "knife")) return(true);
	return(false);
}

isPistol(weaponslot)
{
	weaponname = self getWeaponSlotWeapon(weaponslot);
	if(extreme\_ex_weapons::isWeaponType(weaponname, "pistol")) return(true);
	return(false);
}
