#include extreme\_ex_hudcontroller;

init()
{
	if(!level.ex_hitblip) return;
	[[level.ex_PrecacheShader]]("damage_feedback");
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
}

onPlayerConnected()
{
	hud_index = playerHudCreate("damagefeedback", 0, 0, 0, (1,1,1), 1, 0, "center", "middle", "center", "middle", false, true);
	if(hud_index == -1) return;
	playerHudSetKeepOnKill(hud_index, true);
	playerHudSetShader(hud_index, "damage_feedback", 24, 24);
}

updateDamageFeedback()
{
	if(level.ex_gameover || !level.ex_hitblip) return;

	if(isPlayer(self))
	{
		playerHudSetAlpha("damagefeedback", 1);
		playerHudFade("damagefeedback", 1, 0, 0);
		if(level.ex_hitsound) self playlocalsound("MP_hit_alert");
	}
}
