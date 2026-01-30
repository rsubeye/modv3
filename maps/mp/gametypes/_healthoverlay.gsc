init()
{
	[[level.ex_PrecacheShader]]("overlay_low_health");
	if(!level.ex_healthregen) return;

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
	[[level.ex_registerCallback]]("onPlayerDisconnected", ::onPlayerDisconnected);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
}

onPlayerSpawned()
{
	self thread playerHealthRegen();
}

onPlayerKilled()
{
	self notify("end_healthregen");
}

onPlayerDisconnected()
{
	self notify("end_healthregen");
}

onJoinedTeam()
{
	self notify("end_healthregen");
}

onJoinedSpectators()
{
	self notify("end_healthregen");
}

playerHealthRegen()
{
	self endon("end_healthregen");

	maxhealth = self.health;
	oldhealth = maxhealth;
	hurtTime = 0;

	regenRate = (20 - level.ex_healthregen_rate) + 1;
	regenTick = regenRate;

	if(level.ex_healthregen_heavybreathing) thread playerBreathingSound(maxhealth * (level.ex_healthregen_heavybreathing_cutoff / 100));

	for(;;)
	{
		if(level.ex_gameover) return;
		wait( [[level.ex_fpstime]](0.05) );

		if(self.health == maxhealth) continue;
		if(self.health <= 0 || maxhealth <= 0) return;

		if(self.health >= oldhealth)
		{
			if(gettime() - hurtTime < level.ex_healthregen_delay) continue;

			regenTick--;
			if(!regenTick)
			{
				oldhealth = self.health;
				self.health++;
				regenTick = regenRate;
			}

			continue;
		}

		oldhealth = self.health;
		hurtTime = gettime();
	}
}

playerBreathingSound(healthcap)
{
	self endon("end_healthregen");
	
	better = true;

	for(;;)
	{
		if(level.ex_gameover) return;
		if(self.health <= 0) return;
		if(isDefined(self.frozenstate) && self.frozenstate == "frozen") return;
		wait( [[level.ex_fpstime]](1.0 + randomfloat(1.5)) );

		if(self.health >= healthcap)
		{
			if(!better)
			{
				self playLocalSound("breathing_better");
				better = true;
			}
		}
		else
		{
			better = false;
			self playLocalSound("breathing_hurt");
		}
	}
}
