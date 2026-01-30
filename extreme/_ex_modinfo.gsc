#include extreme\_ex_hudcontroller;

init()
{
	if(level.ex_clantext)
	{
		if(isDefined(level.ex_clantext_str)) [[level.ex_PrecacheString]](level.ex_clantext_str);
			else level.ex_clantext = 0;
	}

	if(level.ex_modtext)
	{
		[[level.ex_PrecacheString]](&"CUSTOM_MODINFO_NAME");
		[[level.ex_PrecacheString]](&"CUSTOM_MODINFO_BY");
		[[level.ex_PrecacheString]](&"CUSTOM_MODINFO_WEBSITE");
	}

	hud_index = levelHudCreate("mod_info", undefined, 630, 474, 0, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "right", "middle", false, false);
	if(hud_index == -1) return;

	if(level.ex_stbd || level.ex_mapvote)
	{
		levelHudSetKeepOnGameOver(hud_index, true);
		[[level.ex_registerCallback]]("onGameOver", ::onGameOver);
	}

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, 60, 60, randomInt(30)+30);
}

onGameOver()
{
	level endon("intermission");

	hud_index = levelHudIndex("mod_info");
	if(hud_index == -1) return;
	levelHudFade(hud_index, 1, 1, 0);
	levelHudSetXYZ(hud_index, 320);
	levelHudSetAlign(hud_index, "center", undefined);

	while(true) onRandom(0);
}

onRandom(eventID)
{
	level endon("ex_gameover");

	hud_index = levelHudIndex("mod_info");
	if(hud_index == -1) return;

	if(level.ex_clantext)
	{
		levelHudSetText(hud_index, level.ex_clantext_str);
		levelHudFade(hud_index, 1, 5, 1);
		levelHudFade(hud_index, 1, 2, 0);
	}

	if(level.ex_modtext)
	{
		levelHudSetText(hud_index, &"CUSTOM_MODINFO_NAME");
		levelHudFade(hud_index, 1, 5, 1);
		levelHudFade(hud_index, 1, 2, 0);

		levelHudSetText(hud_index, &"CUSTOM_MODINFO_BY");
		levelHudFade(hud_index, 1, 5, 1);
		levelHudFade(hud_index, 1, 2, 0);

		levelHudSetText(hud_index, &"CUSTOM_MODINFO_WEBSITE");
		levelHudFade(hud_index, 1, 5, 1);
		levelHudFade(hud_index, 1, 2, 0);
	}

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}
