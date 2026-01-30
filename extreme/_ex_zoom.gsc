#include extreme\_ex_weapons;
#include extreme\_ex_hudcontroller;

statusZoom()
{
	// ui_zoom:
	// 0: zoom off, memory off, menu off
	// 1: zoom off, memory on, menu disabled
	// 2: zoom on, memory off, menu disabled
	// 3: zoom on, memory on, menu enabled
	zoom_server = level.ex_zoom;
	if(zoom_server == 0 || zoom_server == 1)
	{
		if(level.ex_zoom_memory) zoom_server = 1;
	}
	else
	{
		if(level.ex_zoom_memory) zoom_server = 3;
			else zoom_server = 2;
	}
	return(zoom_server);
}

initZoom(zoom_server)
{
	zoom_sr = level.ex_zoom_default_sr;
	zoom_lr = level.ex_zoom_default_lr;

	if(zoom_server == 1 || zoom_server == 3)
	{
		memory = self extreme\_ex_memory::getMemory("zoom", "sr");
		if(!memory.error) zoom_sr = memory.value;
		memory = self extreme\_ex_memory::getMemory("zoom", "lr");
		if(!memory.error) zoom_lr = memory.value;
	}

	thread prepForMemory(zoom_sr, zoom_lr);
}

main()
{
	self endon("kill_thread");

	// make sure it initializes the zoom
	zoom_reset = true;

	zoom_active = 0;
	zoom_level = 0;
	zoom_min = 1;
	zoom_max = 10;
	zoom_first_sr = true;
	zoom_first_lr = true;

	zoom_oldclass = 0;
	zoom_oldweapon = "unknown";

	// prepare zoom levels memory
	zoom_oldlevel_sr = level.ex_zoom_default_sr;
	zoom_oldlevel_lr = level.ex_zoom_default_lr;

	if(level.ex_zoom == 2 && level.ex_zoom_memory)
	{
		memory = self extreme\_ex_memory::getMemory("zoom", "sr");
		if(!memory.error) zoom_oldlevel_sr = memory.value;

		memory = self extreme\_ex_memory::getMemory("zoom", "lr");
		if(!memory.error) zoom_oldlevel_lr = memory.value;
	}

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](0.05) );

		if(self playerADS())
		{
			// Exclude binoculars from zooming (playersADS() is true for binocs too)
			if(isDefined(self.ex_binocuse) && self.ex_binocuse) continue;

			// check weapon class
			zoom_weapon = self getCurrentWeapon();
			if((level.ex_zoom_class & 1) == 1 && isWeaponType(zoom_weapon, "snipersr")) zoom_class = 1;
				else if((level.ex_zoom_class & 2) == 2 && level.ex_longrange && isWeaponType(zoom_weapon, "sniperlr")) zoom_class = 2;
					else zoom_class = 0;

			// allow zoom if class allowed
			if(zoom_class)
			{
				// load new settings if class changed
				if(zoom_class != zoom_oldclass)
				{
					zoom_oldclass = zoom_class;
					zoom_reset = true;

					switch(zoom_class)
					{
						case 1:
							zoom_min = level.ex_zoom_min_sr;
							zoom_max = level.ex_zoom_max_sr;
							if(zoom_first_sr)
							{
								zoom_first_sr = false;
								zoom_level = level.ex_zoom_default_sr;
								if(level.ex_zoom == 2 && level.ex_zoom_memory)
								{
									memory = self extreme\_ex_memory::getMemory("zoom", "sr");
									if(!memory.error) zoom_level = memory.value;
								}
								zoom_oldlevel_sr = zoom_level;
							}
							else
							{
								zoom_oldlevel_lr = zoom_level;
								zoom_level = zoom_oldlevel_sr;
							}
							break;
						case 2:
							zoom_min = level.ex_zoom_min_lr;
							zoom_max = level.ex_zoom_max_lr;
							if(zoom_first_lr)
							{
								zoom_first_lr = false;
								zoom_level = level.ex_zoom_default_lr;
								if(level.ex_zoom == 2 && level.ex_zoom_memory)
								{
									memory = self extreme\_ex_memory::getMemory("zoom", "lr");
									if(!memory.error) zoom_level = memory.value;
								}
								zoom_oldlevel_lr = zoom_level;
							}
							else
							{
								zoom_oldlevel_sr = zoom_level;
								zoom_level = zoom_oldlevel_lr;
							}
							break;
					}

					if(zoom_level > zoom_max || zoom_level < zoom_min) zoom_reset = true;
				}

				if(zoom_weapon != zoom_oldweapon)
				{
					if(level.ex_zoom_switchreset) zoom_reset = true;
					zoom_oldweapon = zoom_weapon;
				}

				if(zoom_reset)
				{
					zoom_reset = false;
					setZoomLevel(zoom_level, false);
					if(zoom_class == 1) thread prepForMemory(zoom_level, undefined);
						else thread prepForMemory(undefined, zoom_level);
					if(level.ex_zoom == 1 && (level.ex_zoom_switchreset || level.ex_zoom_adsreset)) continue;
				}

				zoom_active = 1;

				if(level.ex_zoom_hud)
				{
					hud_index = playerHudIndex("zoom_hud");
					if(hud_index == -1) hud_index = playerHudCreate("zoom_hud", 320, 380, 0.9, (1,1,1), 2, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
					if(hud_index != -1) playerHudSetValue(hud_index, zoom_level);
				}

				if(self useButtonPressed() && zoom_level > zoom_min)
				{
					zoom_level--;
					if(level.ex_zoom_gradual) self playlocalsound("zoomauto");
						else self playlocalsound("zoommanual");
					thread setZoomLevel(zoom_level, level.ex_zoom_gradual);
					if(zoom_class == 1) thread prepForMemory(zoom_level, undefined);
						else thread prepForMemory(undefined, zoom_level);
					wait( [[level.ex_fpstime]](0.2) );
				}
				else
				if(self meleeButtonPressed() && zoom_level < zoom_max)
				{
					zoom_level++;
					if(level.ex_zoom_gradual) self playlocalsound("zoomauto");
						else self playlocalsound("zoommanual");
					thread setZoomLevel(zoom_level, level.ex_zoom_gradual);
					if(zoom_class == 1) thread prepForMemory(zoom_level, undefined);
						else thread prepForMemory(undefined, zoom_level);
					wait( [[level.ex_fpstime]](0.2) );
				}
			}
			else if(zoom_active)
			{
				zoom_active = 0;
				playerHudDestroy("zoom_hud");
			}
		}
		else if(zoom_active)
		{
			zoom_active = 0;
			playerHudDestroy("zoom_hud");

			// save zoom level if switching weapons from zoom class to non zoom class during ADS
			if(zoom_oldclass == 1) zoom_oldlevel_sr = zoom_level;
				else if(zoom_oldclass == 2) zoom_oldlevel_lr = zoom_level;

			// reset zoom level if not ADS
			if(level.ex_zoom_adsreset) zoom_reset = true;
		}
	}
}

setZoomLevel(zoomlevel, gradual)
{
	self endon("kill_thread");

	self notify("stop_zooming");
	waittillframeend;
	self endon("stop_zooming");

	self.ex_zoomtarget = (81 - (zoomlevel * 8));

	if(gradual && isDefined(self.ex_zoom))
	{
		if(self.ex_zoomtarget > self.ex_zoom)
		{
			for(i = self.ex_zoom + 1; i <= self.ex_zoomtarget; i++) setZoom(i);
		}
		else
		if(self.ex_zoomtarget < self.ex_zoom)
		{
			for(i = self.ex_zoom - 1; i >= self.ex_zoomtarget; i--) setZoom(i);
		}
	}
	else setZoom(self.ex_zoomtarget);

	hud_index = playerHudIndex("zoom_hud");
	if(hud_index != -1) playerHudSetValue(hud_index, zoomlevel);
}

setZoom(zoomvalue)
{
	self endon("kill_thread");

	self.ex_zoom = zoomvalue;
	self setclientCvar("cg_fovmin", self.ex_zoom);
	wait( [[level.ex_fpstime]](0.05) );
}

prepForMemory(zoom_sr, zoom_lr)
{
	if(isDefined(zoom_sr)) self.pers["zoom_sr"] = zoom_sr;
	if(isDefined(zoom_lr)) self.pers["zoom_lr"] = zoom_lr;
}

saveZoom()
{
	zoom_server = statusZoom();
	if(zoom_server == 1 || zoom_server == 3)
	{
		self thread extreme\_ex_memory::setMemory("zoom", "sr", self.pers["zoom_sr"], true);
		self thread extreme\_ex_memory::setMemory("zoom", "lr", self.pers["zoom_lr"], level.ex_tune_delaywrite);
	}
	else
	{
		self thread extreme\_ex_memory::setMemory("zoom", "sr", level.ex_zoom_default_sr, true);
		self thread extreme\_ex_memory::setMemory("zoom", "lr", level.ex_zoom_default_lr, level.ex_tune_delaywrite);
	}
}
