#include extreme\_ex_hudcontroller;

init()
{
	coloralive = (1,1,0);
	colordead = (1,0,0);
	alpha = 0.8;

	// axis icon
	hud_index = levelHudCreate("livestats_axisicon", undefined, 624, 20, alpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, game["hudicon_axis"], 16, 16);

	// allies icon
	hud_index = levelHudCreate("livestats_alliesicon", undefined, 608, 20, alpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, game["hudicon_allies"], 16, 16);

	// alive icon
	hud_index = levelHudCreate("livestats_aliveicon", undefined, 592, 36, alpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "hud_status_alive", 16, 16);

	// dead icon
	hud_index = levelHudCreate("livestats_deadicon", undefined, 592, 52, alpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "hud_status_dead", 16, 16);

	// axis alive
	hud_index = levelHudCreate("livestats_axisalive", undefined, 624, 36, alpha, coloralive, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	// axis dead
	hud_index = levelHudCreate("livestats_axisdead", undefined, 624, 52, alpha, colordead, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	// allies alive
	hud_index = levelHudCreate("livestats_alliesalive", undefined, 608, 36, alpha, coloralive, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	// allies dead
	hud_index = levelHudCreate("livestats_alliesdead", undefined, 608, 52, alpha, colordead, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetValue(hud_index, 0);

	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
}

onSecond(eventID)
{
	level endon("ex_gameover");

	axisalive = 0;
	axisdead = 0;

	alliesalive = 0;
	alliesdead = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]))
		{
			player = players[i];

			if(!isDefined(player.pers["team"])) continue;
			if(player.pers["team"] == "spectator" || player.sessionteam == "spectator") continue;

			if(player.sessionstate == "playing")
			{
				if(player.pers["team"] == "allies") alliesalive++;
					else axisalive++;
			}
			else
			{
				if(player.pers["team"] == "allies") alliesdead++;
					else axisdead++;
			}
		}
	}

	levelHudSetValue("livestats_axisalive", axisalive);
	levelHudSetValue("livestats_axisdead", axisdead);
	levelHudSetValue("livestats_alliesalive", alliesalive);
	levelHudSetValue("livestats_alliesdead", alliesdead);
}
