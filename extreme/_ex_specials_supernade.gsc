#include extreme\_ex_specials;

perkInit()
{
	// perk related precaching
}

perkInitPost()
{
	// perk related precaching after map load
	level.ex_supernade_allies = "supernade_" + game["allies"] + "_mp";
	[[level.ex_PrecacheItem]](level.ex_supernade_allies);

	level.ex_supernade_axis = "supernade_german_mp";
	[[level.ex_PrecacheItem]](level.ex_supernade_axis);
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

	wait( [[level.ex_fpstime]](delay) );

	if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_SUPERNADE_READY");

	self thread hudNotifySpecial(index, 5);
	if(level.ex_specials_keeptimer) thread perkKeepTimer(index);
		else self thread playerStartUsingPerk(index, false);

	self thread perkThink(index);
}

perkKeepTimer(index)
{
	self endon("kill_thread");
	self endon("kill_keep" + index);

	wait( [[level.ex_fpstime]](level.ex_specials_keeptimer) );
	self thread playerStartUsingPerk(index, false);
}

perkThink(index)
{
	self endon("kill_thread");

	// remove all regular frag nades
	self takeWeapon(self.pers["fragtype"]);
	self takeWeapon(self.pers["enemy_fragtype"]);

	// give one supernade
	if(self.pers["team"] == "allies") weapon = level.ex_supernade_allies;
		else weapon = level.ex_supernade_axis;

	self giveWeapon(weapon);
	self setWeaponClipAmmo(weapon, 1);
	self switchToOffhand(weapon);

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](1) );

		// keep removing regular nades until supernade is gone, unless we're in the
		// process of throwing back a nade
		if(!isDefined(self.ex_throwback))
		{
			self takeWeapon(self.pers["fragtype"]);
			self takeWeapon(self.pers["enemy_fragtype"]);
		}

		supernades = self getammocount(weapon);
		if(!supernades) break;
	}

	// if enabled, give back frag weapon, but no ammo
	if(maps\mp\gametypes\_weapons::getWeaponStatus("fraggrenade"))
	{
		self giveWeapon(self.pers["fragtype"]);
		self setWeaponClipAmmo(self.pers["fragtype"], 0);
	}

	self notify("kill_keep" + index);
	playerStopUsingPerk(index, false);
	playerUnlockPerk(index);
}
