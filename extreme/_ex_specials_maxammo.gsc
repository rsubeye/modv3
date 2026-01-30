#include extreme\_ex_specials;

perkInit()
{
	// perk related precaching
}

perkInitPost()
{
	// perk related precaching after map load
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

	self thread hudNotifySpecial(index, 5);
	self thread playerStartUsingPerk(index, true);

	if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
	    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) )
	{
		if(isDefined(self.ex_gunship_weapons))
		{
			for(i = 0; i < level.ex_gunship_weapons.size; i++)
			{
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
			}
		}
	}
	else self thread extreme\_ex_weapons::updateLoadout(2);

	self thread playerStopUsingPerk(index);
}
