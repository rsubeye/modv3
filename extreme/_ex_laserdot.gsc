#include extreme\_ex_utils;
#include extreme\_ex_hudcontroller;

main()
{
	if(isExcluded()) return;

	self endon("kill_thread");

	hud_index = playerHudCreate("laserdot", 320, 242, 0, (level.ex_laserdotred, level.ex_laserdotgreen, level.ex_laserdotblue), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "white", level.ex_laserdotsize, level.ex_laserdotsize);

	if(level.ex_laserdot == 1) playerHudSetAlpha(hud_index, 1);
		else [[level.ex_registerPlayerEvent]]("onHalfSecond", ::onHalfSecond);
}

onHalfSecond(eventID)
{
	self endon("kill_thread");

	switch(level.ex_laserdot)
	{
		case 2:
			if(self playerads()) playerHudSetAlpha("laserdot", 1);
				else playerHudSetAlpha("laserdot", 0);
			break;
		case 3:
			if(self playerads()) playerHudSetAlpha("laserdot", 0);
				else playerHudSetAlpha("laserdot", 1);
			break;
	}
}

isExcluded()
{
	self endon("disconnect");

	count = 0;
	clan_check = "";

	if(isDefined(self.ex_name))
	{
		playerclan = convertMLJ(self.ex_name);

		for(;;)
		{
			clan_check = [[level.ex_drm]]("ex_laserdot_clan_" + count, "", "", "", "string");
			if(clan_check == "") break;
			clan_check = convertMLJ(clan_check);
			if(clan_check == playerclan) break;
				else count++;
		}
	}

	if(clan_check != "") return true;

	count = 0;
	playername = convertMLJ(self.name);

	for(;;)
	{
		name_check = [[level.ex_drm]]("ex_laserdot_name_" + count, "", "", "", "string");
		if(name_check == "") break;
		name_check = convertMLJ(name_check);
		if(name_check == playername) break;
			else count++;
	}

	if(name_check != "") return true;

	return false;
}
