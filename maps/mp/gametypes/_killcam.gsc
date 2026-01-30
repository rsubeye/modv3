#include extreme\_ex_hudcontroller;

init()
{
	[[level.ex_PrecacheString]](&"MP_KILLCAM");
	[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_SKIP");
	[[level.ex_PrecacheString]](&"PLATFORM_PRESS_TO_RESPAWN");
	[[level.ex_PrecacheShader]]("black");
	
	killcam = getCvar("scr_killcam");
	if(killcam == "")
	{
		level.killcam = 1;
		setCvar("scr_killcam", level.killcam);
	}
	else level.killcam = getCvarInt("scr_killcam");
	setCvar("ui_killcam", level.killcam);
	makeCvarServerInfo("ui_killcam", level.killcam);

	if(level.killcam > 0) setarchive(true);

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 5);
}

onRandom(eventID)
{
	killcam = getCvarInt("scr_killcam");
	if(level.killcam != killcam)
	{
		level.killcam = getCvarInt("scr_killcam");
		setCvar("ui_killcam", level.killcam);

		if((level.killcam > 0) || (getCvarInt("g_antilag") > 0)) setarchive(true);
			else setarchive(false);
	}
}

killcam(attackerNum, delay, offsetTime, respawn)
{
	self endon("spawned");

	// killcam
	if(attackerNum < 0) return;

	// hide objectives during killcam
	if(level.ex_killcam_hideobj) self setClientCvar("ui_hide_pointers", 1);

	self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.archivetime = delay + 7;
	self.psoffsettime = offsetTime;

	// ignore spectate permissions
	self allowSpectateTeam("allies", true);
	self allowSpectateTeam("axis", true);
	self allowSpectateTeam("freelook", true);
	self allowSpectateTeam("none", true);
	
	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait( [[level.ex_fpstime]](0.05) );

	if(self.archivetime <= delay)
	{
		self.sessionstate = "dead";
		self.spectatorclient = -1;
		self.archivetime = 0;
		self.psoffsettime = 0;
		return;
	}
	
	self.killcam = true;

	hud_index = playerHudCreate("killcam_top", 0, 0, 0.5, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, false);
	if(hud_index != -1) playerHudSetShader(hud_index, "black", 640, 112);

	hud_index = playerHudCreate("killcam_bottom", 0, 368, 0.5, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, false);
	if(hud_index != -1) playerHudSetShader(hud_index, "black", 640, 112);

	hud_index = playerHudCreate("killcam_title", 0, 30, 1, (1,1,1), 3.5, 1, "center_safearea", "top", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetText(hud_index, &"MP_KILLCAM");

	hud_index = playerHudCreate("killcam_skip", 0, 70, 1, (1,1,1), 2, 1, "center_safearea", "top", "center", "middle", false, false);
	if(hud_index != -1)
	{
		if(isDefined(respawn)) playerHudSetText(hud_index, &"PLATFORM_PRESS_TO_RESPAWN");
			else playerHudSetText(hud_index, &"PLATFORM_PRESS_TO_SKIP");
	}

	hud_index = playerHudCreate("killcam_timer", 0, -32, 1, (1,1,1), 3.5, 1, "center_safearea", "bottom", "center", "middle", false, false);
	if(hud_index != -1) playerHudSetTenthsTimer(hud_index, self.archivetime - delay);

	self thread spawnedKillcamCleanup();
	self thread waitSkipKillcamButton();
	self thread waitKillcamTime();

	self waittill("end_killcam");

	self removeKillcamElements();

	self.sessionstate = "dead";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	
	self.killcam = undefined;
	
	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}

waitKillcamTime()
{
	self endon("disconnect");
	self endon("end_killcam");

	wait( [[level.ex_fpstime]](self.archivetime - 0.05) );

	self notify("end_killcam");
}

waitSkipKillcamButton()
{
	self endon("disconnect");
	self endon("end_killcam");

	while(self useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
	while(!(self useButtonPressed())) wait( [[level.ex_fpstime]](0.05) );

	self notify("end_killcam");
}

removeKillcamElements()
{
	// show objectives after killcam
	if(level.ex_killcam_hideobj) self setClientCvar("ui_hide_pointers", 0);

	playerHudDestroy("killcam_top");
	playerHudDestroy("killcam_bottom");
	playerHudDestroy("killcam_title");
	playerHudDestroy("killcam_skip");
	playerHudDestroy("killcam_timer");
}

spawnedKillcamCleanup()
{
	self endon("end_killcam");

	self waittill("spawned");
	self removeKillcamElements();
}
