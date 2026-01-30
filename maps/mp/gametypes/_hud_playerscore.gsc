#include extreme\_ex_hudcontroller;

init()
{
	game["hudicon_axis"] = "hudicon_german";
	switch(game["allies"])
	{
		case "american": game["hudicon_allies"] = "hudicon_american"; break;
		case "british": game["hudicon_allies"] = "hudicon_british"; break;
		case "russian": game["hudicon_allies"] = "hudicon_russian"; break;
	}

	[[level.ex_PrecacheShader]](game["hudicon_allies"]);
	[[level.ex_PrecacheShader]](game["hudicon_axis"]);
	
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
}

onPlayerConnected()
{
	self thread onUpdatePlayerScoreHUD();
}

onPlayerSpawned()
{
	self endon("disconnect");

	hud_index = playerHudIndex("score_playericon");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("score_playericon", 6, 28, 1, undefined, 1, 0, "left", "top", "left", "top", false, false);
		if(hud_index == -1) return;
		playerHudSetKeepOnKill(hud_index, true);
	}

	hud_index = playerHudIndex("score_playerscore");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("score_playerscore", 36, 26, 1, (1,1,1), 2, 0, "left", "top", "left", "top", false, false);
		if(hud_index == -1) return;
		playerHudSetKeepOnKill(hud_index, true);
	}

	if(self.pers["team"] == "allies") playerHudSetShader("score_playericon", game["hudicon_allies"], 24, 24);
		else if(self.pers["team"] == "axis") playerHudSetShader("score_playericon", game["hudicon_axis"], 24, 24);

	self thread updatePlayerScoreHUD();
}

onJoinedTeam()
{
	self thread removePlayerHUD();
}

onJoinedSpectators()
{
	self thread removePlayerHUD();
}

onUpdatePlayerScoreHUD()
{
	self endon("disconnect");

	while(!level.ex_gameover)
	{
		self waittill("update_playerscore_hud");
		self thread updatePlayerScoreHUD();
	}
}

updatePlayerScoreHUD()
{
	playerHudSetValue("score_playerscore", self.pers["score"]);
}

removePlayerHUD()
{
	playerHudDestroy("score_playericon");
	playerHudDestroy("score_playerscore");
}

