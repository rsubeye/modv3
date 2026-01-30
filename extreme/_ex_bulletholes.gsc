#include extreme\_ex_hudcontroller;

bullethole()
{
	self endon("kill_thread");

	index = bulletholeAllocate();
	if(index == -1) return;
	
	hud_index = playerHudCreate("bullethole_" + index, 48 + randomInt(544), 48 + randomInt(384), 0.8 + randomFloat(0.2), (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;

	xsize = 64 + randomInt(32);
	ysize = 64 + randomInt(32);

	if(randomInt(2)) playerHudSetShader(hud_index, "gfx/custom/bullethit_glass.tga", xsize, ysize);
		else playerHudSetShader(hud_index, "gfx/custom/bullethit_glass2.tga", xsize, ysize);

	self.bulletholes[index].hud_index = hud_index;

	self playLocalSound("glassbreak");

	self thread fadeBullethole(index);
}

fadeBullethole(index)
{
	self endon("kill_bullethole");

	wait( [[level.ex_fpstime]](5) );

	if(isPlayer(self))
	{
		playerHudFade(self.bulletholes[index].hud_index, 1, 1, 0);
		if(isPlayer(self)) removeBulletHole(index);
	}
}

removeBulletHole(index)
{
	playerHudDestroy(self.bulletholes[index].hud_index);
	self.bulletholes[index].inuse = 0;
}

removeAllHoles()
{
	if(!isDefined(self.bulletholes)) return;

	self notify("kill_bullethole");

	for(i = 0; i < self.bulletholes.size; i++)
		if(self.bulletholes[i].inuse) removeBulletHole(i);
}

bulletholeAllocate()
{
	if(!isDefined(self.bulletholes)) self.bulletholes = [];

	for(i = 0; i < self.bulletholes.size; i++)
	{
		if(self.bulletholes[i].inuse == 0)
		{
			self.bulletholes[i].inuse = 1;
			return(i);
		}
	}

	if(self.bulletholes.size >= 3) return(-1);
	self.bulletholes[i] = spawnstruct();
	self.bulletholes[i].inuse = 1;
	return(i);
}
