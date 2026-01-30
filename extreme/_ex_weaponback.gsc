#include extreme\_ex_weapons;
/*------------------------------------------------------------------------------
Based on Weapons on Back code from R&R Projects
------------------------------------------------------------------------------*/

init()
{
	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
}

onPlayerSpawned()
{
	if(level.ex_wepo_secondary && !isDefined(self.pers["isbot"])) self thread wob_twoslotmonitor();
		else self thread wob_oneslotmonitor();
}

wob_twoslotmonitor()
{
	self endon("kill_thread");

	// when carrying a flamethrower (any slot), the tank is on the back
	if(isWeaponType(self.pers["weapon1"], "ft") || isWeaponType(self.pers["weapon2"], "ft")) return;

	self.weapononback = undefined;
	wob = "none";

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.5) );

		attach_enabled = true;
		if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail) attach_enabled = false;

		currentweapon = self getcurrentweapon();

		if(isValidWeaponOnBack(currentweapon))
		{
			if(currentweapon == self.pers["weapon1"]) newwob = self.pers["weapon2"];
				else if(currentweapon == self.pers["weapon2"]) newwob = self.pers["weapon1"];
					else newwob = wob;

			if(newwob != wob)
			{
				wob = newwob;

				if(isDefined(self.weapononback))
				{
					if(checkAttached(self.weapononback)) self detach("xmodel/" + self.weapononback, "");
					self.weapononback = undefined;
				}

				wait( [[level.ex_fpstime]](0.05) );

				if(attach_enabled)
				{
					self.weapononback = wob;
					if(!checkAttached(self.weapononback)) self attach("xmodel/" + self.weapononback, "", true);
				}
			}
		}
	}
}

wob_oneslotmonitor()
{
	self endon("kill_thread");

	// when carrying a flamethrower (any slot), the tank is on the back
	if(isWeaponType(self.pers["weapon"], "ft")) return;

	self.weapononback = undefined;
	oldweapon = "none";
	wob = "none";

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.5) );

		attach_enabled = true;
		if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail) attach_enabled = false;

		currentweapon = self getcurrentweapon();

		if(isValidWeaponOnBack(currentweapon))
		{
			if(wob == "none") newwob = currentweapon;
				else if(currentweapon != oldweapon) newwob = oldweapon;
					else newwob = wob;

			if(newwob != wob)
			{
				oldweapon = currentweapon;
				wob = newwob;

				if(isDefined(self.weapononback))
				{
					if(checkAttached(self.weapononback)) self detach("xmodel/" + self.weapononback, "");
					self.weapononback = undefined;
				}

				wait( [[level.ex_fpstime]](0.05) );

				if(attach_enabled)
				{
					self.weapononback = wob;
					if(!checkAttached(self.weapononback)) self attach("xmodel/" + self.weapononback, "", true);
				}
			}
			else oldweapon = currentweapon;
		}
	}
}

checkAttached(model)
{
	self endon("kill_thread");

	model_attached = false;
	model_full = "xmodel/" + model;

	attachedSize = self getAttachSize();
	for(i = 0; i < attachedSize; i++)
	{
		attachedModel = self getAttachModelName(i);
		if(attachedModel == model_full)
		{
			model_attached = true;
			break;
		}
	}

	return(model_attached);
}

isValidWeaponOnBack(weapon)
{
	if(!isDefined(weapon)) return false;
	if(weapon == game["sprint"]) return false;
	if(!isDefined(level.weapons[weapon]) || (level.weapons[weapon].status & 4) != 4) return false;
	return true;
}
