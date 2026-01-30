#include extreme\_ex_specials;

perkInit()
{
	// perk related precaching
	[[level.ex_PrecacheModel]]("xmodel/bulletproofvest");

	game["mod_protect_hudicon"] = "mod_protect_hudicon";
	[[level.ex_PrecacheShader]](game["mod_protect_hudicon"]);
}

perkInitPost()
{
	// perk related precaching after map load
}

perkCheck()
{
	// checks before being able to buy this perk
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

	self thread hudNotifySpecial(index, 5);
	if(!level.ex_specials_keeptimer) self thread playerStartUsingPerk(index, false);

	self thread perkThink(index);
}

perkThink(index)
{
	self endon("kill_thread");

	self.health = self.maxhealth;
	self.ex_vest_protected = true;
	if(!checkVest()) self attach("xmodel/bulletproofvest", "J_Spine4", false);

	timer = 0;
	while(timer < level.ex_vest_timer)
	{
		self thread hudNotifyProtected();
		wait( [[level.ex_fpstime]](1) );
		timer++;
		if(timer == level.ex_specials_keeptimer) self thread playerStartUsingPerk(index, false);
	}

	if(checkVest()) self detach("xmodel/bulletproofvest", "J_Spine4");
	self thread playerStopUsingPerk(index, true);

	self thread hudNotifyProtectedRemove();
	self.ex_vest_protected = undefined;
}

checkVest()
{
	vest_attached = false;
	attachedSize = self getAttachSize();
	for(i = 0; i < attachedSize; i++)
	{
		attachedModel = self getAttachModelName(i);
		if(attachedModel == "xmodel/bulletproofvest") vest_attached = true;
	}

	return(vest_attached);
}
