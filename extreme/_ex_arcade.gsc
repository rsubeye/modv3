#include extreme\_ex_hudcontroller;

main()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.ex_arcade_test)) return;
	self.ex_arcade_test = 1;

	if(level.ex_arcade_score)
	{
		self.ex_arcade_oldscore = self.pers["score"];

		hud_index = playerHudCreate("arcade_score", 340, 220, 0, (1,1,1), 2, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index != -1)
		{
			playerHudSetKeepOnKill(hud_index, true);
			playerHudFontPulseInit(hud_index);
		}
	}

	if(level.ex_arcade_shaders)
	{
		hud_index = playerHudCreate("arcade_shader", 320, 105, 0, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index != -1) playerHudSetKeepOnKill(hud_index, true);
	}
}

checkScoreUpdate()
{
	level endon("ex_gameover");
	self endon("disconnect");

	wait(0); // wait for next frame

	if(!isDefined(self)) return;
	scorediff = self.pers["score"] - self.ex_arcade_oldscore;
	if(scorediff != 0) self thread showScoreUpdate(scorediff);
}

showScoreUpdate(scorediff)
{
	level endon("ex_gameover");
	self endon("disconnect");

	self notify("kill_scoreupdate");
	waittillframeend;
	self endon("kill_scoreupdate");

	// wait a brief moment to let quick consecutive kills come through
	wait( [[level.ex_fpstime]](0.1) );

	hud_index = playerHudIndex("arcade_score");
	if(hud_index == -1) return;

	playerHudSetAlpha(hud_index, 0);

	if(scorediff < 0)
	{
		playerHudSetLabel(hud_index, &"MP_MINUS");
		playerHudSetColor(hud_index, (1, 0, 0));
	}
	else if(scorediff > 0)
	{
		playerHudSetLabel(hud_index, &"MP_PLUS");
		playerHudSetColor(hud_index, (level.ex_arcade_score_red, level.ex_arcade_score_green, level.ex_arcade_score_blue));
	}

	if(scorediff < 0) scorediff = scorediff * (-1);
	thread playerHudFontPulse(hud_index, scorediff, true, "kill_scorepulse");

	self.ex_arcade_oldscore = self.pers["score"];
}

showArcadeShader(shader, time)
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(shader == "none") return;

	self notify("kill_shaderupdate");
	waittillframeend;
	self endon("kill_shaderupdate");

	// wait a brief moment to let quick consecutive kills come through
	wait( [[level.ex_fpstime]](0.5) );

	hud_index = playerHudIndex("arcade_shader");
	if(hud_index == -1) return;

	playerHudSetAlpha(hud_index, 0);
	playerHudSetShader(hud_index, shader, 160, 160);
	playerHudSetAlpha(hud_index, 1);

	if(!isDefined(time)) time = 1;
	wait( [[level.ex_fpstime]](time) );

	playerHudFade(hud_index, 1, 0, 0);
}
