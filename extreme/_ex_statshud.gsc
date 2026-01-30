#include extreme\_ex_hudcontroller;

init()
{
	// Process DRM vars
	level.ex_statshud_safemode = [[level.ex_drm]]("ex_statshud_safemode", 1, 0, 1, "int");
	level.ex_statshud_autohide = [[level.ex_drm]]("ex_statshud_autohide", 1, 0, 1, "int");
	level.ex_statshud_autohide_sec = [[level.ex_drm]]("ex_statshud_autohide_sec", 3, 1, 10, "int");
	level.ex_statshud_autohide_toggle = [[level.ex_drm]]("ex_statshud_autohide_toggle", 1, 0, 1, "int");
	level.ex_statshud_transp = [[level.ex_drm]]("ex_statshud_transp", 4, 0, 9, "int");

	level.ex_statshud_cflag = [[level.ex_drm]]("ex_statshud_cflag", 1, 0, 1, "int");   // flag captures
	level.ex_statshud_kills = [[level.ex_drm]]("ex_statshud_kills", 1, 0, 1, "int");   // kills
	level.ex_statshud_skills = [[level.ex_drm]]("ex_statshud_skills", 0, 0, 1, "int"); // sniper kills
	level.ex_statshud_hkills = [[level.ex_drm]]("ex_statshud_hkills", 0, 0, 1, "int"); // headshot kills
	level.ex_statshud_bkills = [[level.ex_drm]]("ex_statshud_bkills", 0, 0, 1, "int"); // bash kills
	level.ex_statshud_tkills = [[level.ex_drm]]("ex_statshud_tkills", 0, 0, 1, "int"); // team kills
	level.ex_statshud_deaths = [[level.ex_drm]]("ex_statshud_deaths", 1, 0, 1, "int"); // deaths
	level.ex_statshud_eff = [[level.ex_drm]]("ex_statshud_eff", 1, 0, 1, "int");       // efficiency
	level.ex_statshud_lspree = [[level.ex_drm]]("ex_statshud_lspree", 1, 0, 1, "int"); // longest spree
	level.ex_statshud_ldist = [[level.ex_drm]]("ex_statshud_ldist", 1, 0, 1, "int");   // longest distance shot
	level.ex_statshud_lhead = [[level.ex_drm]]("ex_statshud_lhead", 0, 0, 1, "int");   // longest headshot

	// Create shader name array
	statsmax = 5;
	level.statshud = [];
	if(level.ex_flagbased && level.ex_statshud_cflag && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_cf";
	if(level.ex_statshud_kills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_kt";
	if(level.ex_statshud_skills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_sk";
	if(level.ex_statshud_hkills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_hk";
	if(level.ex_statshud_bkills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_bk";
	if(level.ex_statshud_tkills && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_tk";
	if(level.ex_statshud_deaths && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_dt";
	if(level.ex_statshud_eff && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_ef";
	if(level.ex_statshud_lspree && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_ls";
	if(level.ex_statshud_ldist && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_ld";
	if(level.ex_statshud_lhead && level.statshud.size < statsmax)
		level.statshud[level.statshud.size] = "statshud_lh";

	// If at least one stat is activated, proceed
	if(level.statshud.size > 0)
	{
		// Precache left and right side shaders
		[[level.ex_PrecacheShader]]("statshud_sl"); // left side
		[[level.ex_PrecacheShader]]("statshud_sr"); // right side

		// Precache stats shaders
		for(i = 0; i < level.statshud.size; i++)
			[[level.ex_PrecacheShader]](level.statshud[i]);

		// Start level monitor for player connections
		[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	}
	// No stat activated, so turn off player stats
	else level.ex_statshud = 0;
}

onPlayerSpawned()
{
	// If allowed, monitor auto-hide toggle
	if(level.ex_statshud_autohide_toggle)
	{
		if(!level.ex_specials) self thread autohideMonitor();
			else level.ex_statshud_autohide_toggle = 0;
	}

	// Create stats dashboard
	self thread createStatsHUD();
}

autohideMonitor()
{
	self endon("kill_thread");

	if(!isDefined(self.pers["statshudautohide"])) self.pers["statshudautohide"] = level.ex_statshud_autohide;

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.5) );
		if(self meleeButtonPressed() && !self playerADS() && !(isDefined(self.ex_thirdperson) && self.ex_thirdperson))
		{
			meleepressed = 0;
			// To toggle, player must be standing and not moving
			while(self meleeButtonPressed() && self.ex_stance == 0 && !self.ex_moving && !self playerADS())
			{
				meleepressed++;
				if(meleepressed > 30) // 3 seconds
				{
					self.pers["statshudautohide"] = !self.pers["statshudautohide"];
					if(self.pers["statshudautohide"]) self thread moveStatsHUD(-1); // down
						else self thread moveStatsHUD(1); // up
					break;
				}
				wait( [[level.ex_fpstime]](0.1) );
			}
		}
	}
}

createStatsHUD()
{
	self endon("kill_thread");

	self.statshud_moving = 0;
	self.statshud_extrasec = 0;
	self.statshud_lock = undefined;

	posx = 320 - ((level.statshud.size / 2) * 64) - 32;
	posy = 480;

	// Shader for left side of dashboard (no value)
	hud_index = playerHudCreate("statshud_left", posx, posy, 1 - (level.ex_statshud_transp / 10), (1,1,1), 1, 1, "subleft", "subtop", "center", "bottom", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "statshud_sl", 64, 64);

	posx += 64;

	// Shaders and initial values for selected stats
	for(i = 0; i < level.statshud.size; i++)
	{
		hud_index = playerHudCreate("statshud_img" + i, posx, posy, 1 - (level.ex_statshud_transp / 10), (1,1,1), 1, 1, "subleft", "subtop", "center", "bottom", false, false);
		if(hud_index == -1) return;
		playerHudSetShader(hud_index, level.statshud[i], 64, 64);

		hud_index = playerHudCreate("statshud_val" + i, posx + 25, posy - 15, 1 - (level.ex_statshud_transp / 10), (1,1,1), 1.8, 2, "subleft", "subtop", "right", "bottom", false, false);
		if(hud_index == -1) return;
		playerHudSetValue(hud_index, 0);

		posx += 64;
	}

	// Shader for right side of dashboard (no value)
	hud_index = playerHudCreate("statshud_right", posx, posy, 1 - (level.ex_statshud_transp / 10), (1,1,1), 1, 1, "subleft", "subtop", "center", "bottom", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "statshud_sr", 64, 64);

	// Show stats
	self thread showStatsHud();
}

showStatsHUD()
{
	self endon("kill_thread");

	self thread updateStatsHUD();
	
	// If toggling auto-hide is enabled, did player disable auto-hide?
	if(level.ex_statshud_autohide_toggle && !self.pers["statshudautohide"]) return;

	// Is auto-hiding disabled globally?
	if(!level.ex_statshud_autohide) return;

	// Move stats HUD up and down
	self thread moveStatsHUD(1); // up
	if(!isDefined(self.statshud_lock))
	{
		self.statshud_lock = true;
		self waittill("statshudup");
		wait( [[level.ex_fpstime]](level.ex_statshud_autohide_sec) );
		while(self.statshud_extrasec > 0)
		{
			self.statshud_extrasec--;
			wait( [[level.ex_fpstime]](1) );
		}
		self.statshud_lock = undefined;
		self thread moveStatsHUD(-1); // down
	}
}

moveStatsHUD(direction)
{
	self endon("kill_thread");

	if(!isDefined(direction)) direction = 1;
	if(direction == 0) return;

	hud_left = playerHudIndex("statshud_left");
	if(hud_left == -1) return;
	hud_leftxyz = playerHudGetXYZ(hud_left);

	// direction: 1 = move up, -1 = move down
	if(direction == 1)
	{
		posy = 480;
		movetime = 0.5;
	}
	else
	{
		posy = 544;
		movetime = 1;
	}

	// statshud_moving: 1 = moving up, 0 = not moving , -1 = moving down
	if(self.statshud_moving == 0)
	{
		if(hud_leftxyz[1] == posy)
		{
			if(direction == 1)
			{
				self.statshud_extrasec++;
				wait( [[level.ex_fpstime]](0.1) ); // So we don't fire the notify before it reaches the waittill
				self notify("statshudup");
			}
			return;
		}
	}
	else
	{
		if(self.statshud_moving != direction)
		{
			travel = abs(hud_leftxyz[1] - posy);
			movetime = (movetime / 64) * travel;
			if(movetime <= 0) movetime = 0.1;
		}
		else return;
	}

	self.statshud_moving = direction;

	playerHudMove(hud_left, movetime, 0, undefined, posy, false);
	for(i = 0; i < level.statshud.size; i++) playerHudMove("statshud_img" + i, movetime, 0, undefined, posy, false);
	for(i = 0; i < level.statshud.size; i++) playerHudMove("statshud_val" + i, movetime, 0, undefined, posy - 15, false);
	playerHudMove("statshud_right", movetime, 0, undefined, posy, false);

	wait( [[level.ex_fpstime]](movetime) );
	self.statshud_moving = 0;
	if(direction == 1) self notify("statshudup");
}

updateStatsHUD()
{
	self endon("kill_thread");

	if(self.statshud_moving)
 		self waittill("statshudup");

	if(level.ex_gameover) return;

	for(i = 0; i < level.statshud.size; i++)
	{
		switch(level.statshud[i])
		{
			case "statshud_kt":
				playerHudSetValue("statshud_val" + i, self.pers["kill"]);
				break;
			case "statshud_sk":
				playerHudSetValue("statshud_val" + i, self.pers["sniperkill"]);
				break;
			case "statshud_hk":
				playerHudSetValue("statshud_val" + i, self.pers["headshotkill"]);
				break;
			case "statshud_bk":
				playerHudSetValue("statshud_val" + i, self.pers["bashkill"]);
				break;
			case "statshud_tk":
				playerHudSetValue("statshud_val" + i, self.pers["teamkill"]);
				break;
			case "statshud_dt":
				playerHudSetValue("statshud_val" + i, self.pers["death"]);
				break;
			case "statshud_ef":
			{
				if(self.pers["kill"] == 0 || (self.pers["kill"] - self.pers["death"]) <= 0) efficiency = 0;
					else efficiency = int( (100 / self.pers["kill"]) * (self.pers["kill"] - self.pers["death"]) );
				if(efficiency > 100) efficiency = 0;
				playerHudSetValue("statshud_val" + i, efficiency);
				break;
			}
			case "statshud_ld":
				playerHudSetValue("statshud_val" + i, self.pers["longdist"]);
				break;
			case "statshud_lh":
				playerHudSetValue("statshud_val" + i, self.pers["longhead"]);
				break;
			case "statshud_ls":
				playerHudSetValue("statshud_val" + i, self.pers["longspree"]);
				break;
			case "statshud_cf":
				playerHudSetValue("statshud_val" + i, self.pers["flagcap"]);
				break;
		}
	}
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return(var);
}
