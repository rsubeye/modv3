#include extreme\_ex_hudcontroller;

init()
{
	// material name of stock shader "logo"
	game["mylogo1"] = "logo";

	// uncomment to enable 2nd shader. Change material name "logo2" if required
	// WARNING: the mod does not provide an image associated with this material!
	//game["mylogo2"] = "logo2";

	// uncomment to enable 3rd shader. Change material name "logo3" if required
	// WARNING: the mod does not provide an image associated with this material!
	//game["mylogo3"] = "logo3";

	// uncomment to enable 4th shader. Change material name "logo4" if required
	// WARNING: the mod does not provide an image associated with this material!
	//game["mylogo4"] = "logo4";

	// uncomment to enable 5th shader. Change material name "logo5" if required
	// WARNING: the mod does not provide an image associated with this material!
	//game["mylogo5"] = "logo5";

	// ---------- NO NEED TO EDIT ANYTHING BELOW THIS LINE  ----------

	if(isDefined(game["mylogo1"])) [[level.ex_PrecacheShader]](game["mylogo1"]);
	if(isDefined(game["mylogo2"])) [[level.ex_PrecacheShader]](game["mylogo2"]);
	if(isDefined(game["mylogo3"])) [[level.ex_PrecacheShader]](game["mylogo3"]);
	if(isDefined(game["mylogo4"])) [[level.ex_PrecacheShader]](game["mylogo4"]);
	if(isDefined(game["mylogo5"])) [[level.ex_PrecacheShader]](game["mylogo5"]);

	if(!isDefined(game["mylogo1"]) && !isDefined(game["mylogo2"]) && !isDefined(game["mylogo3"]) && !isDefined(game["mylogo4"]) && !isDefined(game["mylogo5"])) return;

	if(level.ex_mylogo_looptime)
	{
		looptime = level.ex_mylogo_looptime;
		[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, true, looptime, looptime, randomInt(30)+30);
	}
	else
	{
		hud_index = levelHudCreate("mylogo", undefined, 0-level.ex_mylogo_posx, level.ex_mylogo_posy, 1 - (level.ex_mylogo_transp / 10), undefined, 1, 999, "right", "top", "right", "top", false, false);
		if(hud_index == -1) return;

		if(isDefined(game["mylogo1"])) levelHudSetShader(hud_index, game["mylogo1"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		else if(isDefined(game["mylogo2"])) levelHudSetShader(hud_index, game["mylogo2"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		else if(isDefined(game["mylogo3"])) levelHudSetShader(hud_index, game["mylogo3"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		else if(isDefined(game["mylogo4"])) levelHudSetShader(hud_index, game["mylogo4"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		else if(isDefined(game["mylogo5"])) levelHudSetShader(hud_index, game["mylogo5"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
	}
}

onRandom(eventID)
{
	level endon("ex_gameover");

	hud_index = levelHudCreate("mylogo", undefined, 0-level.ex_mylogo_posx, level.ex_mylogo_posy, 0, undefined, 1, 999, "right", "top", "right", "top", false, false);
	if(hud_index == -1) return;

	// ---------- FIRST LOGO ----------
	if(isDefined(game["mylogo1"]))
	{
		// set shader
		levelHudSetShader("mylogo", game["mylogo1"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		// fade in
		levelHudFade("mylogo", 2, level.ex_mylogo_fadewait, 1 - (level.ex_mylogo_transp / 10));
		// fade out
		levelHudFade("mylogo", 2, 2, 0);
	}

	// ---------- SECOND LOGO ----------
	if(isDefined(game["mylogo2"]))
	{
		wait( [[level.ex_fpstime]](5) );
		// set shader
		levelHudSetShader("mylogo", game["mylogo2"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		// fade in
		levelHudFade("mylogo", 2, level.ex_mylogo_fadewait, 1 - (level.ex_mylogo_transp / 10));
		// fade out
		levelHudFade("mylogo", 2, 2, 0);
	}

	// ---------- THIRD LOGO ----------
	if(isDefined(game["mylogo3"]))
	{
		wait( [[level.ex_fpstime]](5) );
		// set shader
		levelHudSetShader("mylogo", game["mylogo3"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		// fade in
		levelHudFade("mylogo", 2, level.ex_mylogo_fadewait, 1 - (level.ex_mylogo_transp / 10));
		// fade out
		levelHudFade("mylogo", 2, 2, 0);
	}

	// ---------- FOURTH LOGO ----------
	if(isDefined(game["mylogo4"]))
	{
		wait( [[level.ex_fpstime]](5) );
		// set shader
		levelHudSetShader("mylogo", game["mylogo4"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		// fade in
		levelHudFade("mylogo", 2, level.ex_mylogo_fadewait, 1 - (level.ex_mylogo_transp / 10));
		// fade out
		levelHudFade("mylogo", 2, 2, 0);
	}

	// ---------- FIFTH LOGO ----------
	if(isDefined(game["mylogo5"]))
	{
		wait( [[level.ex_fpstime]](5) );
		// set shader
		levelHudSetShader("mylogo", game["mylogo5"], level.ex_mylogo_sizex, level.ex_mylogo_sizey);
		// fade in
		levelHudFade("mylogo", 2, level.ex_mylogo_fadewait, 1 - (level.ex_mylogo_transp / 10));
		// fade out
		levelHudFade("mylogo", 2, 2, 0);
	}

	levelHudDestroy("mylogo");

	[[level.ex_enableLevelEvent]]("onRandom", eventID);
}
