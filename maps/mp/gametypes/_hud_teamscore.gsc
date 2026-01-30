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

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
	level thread onUpdateTeamScoreHUD();
}

onPlayerSpawned()
{
	self endon("disconnect");

	hud_index = playerHudIndex("score_teamicon");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("score_teamicon", 6, 28, 1, undefined, 1, 0, "left", "top", "left", "top", false, false);
		if(hud_index == -1) return;
		playerHudSetKeepOnKill(hud_index, true);
	}

	hud_index = playerHudIndex("score_teamscore");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("score_teamscore", 36, 26, 1, (1,1,1), 2, 0, "left", "top", "left", "top", false, false);
		if(hud_index == -1) return;
		playerHudSetKeepOnKill(hud_index, true);
	}

	hud_index = playerHudIndex("score_enemyicon");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("score_enemyicon", 6, 50, 1, undefined, 1, 0, "left", "top", "left", "top", false, false);
		if(hud_index == -1) return;
		playerHudSetKeepOnKill(hud_index, true);
	}

	hud_index = playerHudIndex("score_enemyscore");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("score_enemyscore", 36, 48, 1, (1,1,1), 2, 0, "left", "top", "left", "top", false, false);
		if(hud_index == -1) return;
		playerHudSetKeepOnKill(hud_index, true);
	}

	if(self.pers["team"] == "allies")
	{
		playerHudSetShader("score_teamicon", game["hudicon_allies"], 24, 24);
		playerHudSetShader("score_enemyicon", game["hudicon_axis"], 24, 24);
	}
	else if(self.pers["team"] == "axis")
	{
		playerHudSetShader("score_teamicon", game["hudicon_axis"], 24, 24);
		playerHudSetShader("score_enemyicon", game["hudicon_allies"], 24, 24);
	}

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

onUpdateTeamScoreHUD()
{
	while(!level.ex_gameover)
	{
		self waittill("update_teamscore_hud");
		level thread updateTeamScoreHUD();
	}
}

updatePlayerScoreHUD()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");
	
	if(self.pers["team"] == "allies")
	{
		playerHudSetValue("score_teamscore", alliedscore);
		playerHudSetValue("score_enemyscore", axisscore);
	}
	else if(self.pers["team"] == "axis")
	{
		playerHudSetValue("score_teamscore", axisscore);
		playerHudSetValue("score_enemyscore", alliedscore);
	}
}

updateTeamScoreHUD()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || !isDefined(player.pers["team"])) continue;

		if(player.pers["team"] == "allies")
		{
			player playerHudSetValue("score_teamscore", alliedscore);
			player playerHudSetValue("score_enemyscore", axisscore);
		}
		else if(player.pers["team"] == "axis")
		{
			player playerHudSetValue("score_teamscore", axisscore);
			player playerHudSetValue("score_enemyscore", alliedscore);
		}
	}
}

removePlayerHUD()
{
	playerHudDestroy("score_teamicon");
	playerHudDestroy("score_teamscore");
	playerHudDestroy("score_enemyicon");
	playerHudDestroy("score_enemyscore");
}
