#include extreme\_ex_utils;

init()
{
	if(level.ex_killtriggers && isDefined(level.killtriggers))
	{
		for(i = 0; i < level.killtriggers.size; i++)
		{
			killtrigger = level.killtriggers[i];
			killtrigger.origin = (killtrigger.origin[0], killtrigger.origin[1], (killtrigger.origin[2] - 16));
		}

		[[level.ex_registerLevelEvent]]("onFrame", ::onFrame, true);
	}
}

onFrame(eventID)
{
	counter = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isDefined(player) && player.sessionstate == "playing" && !isDefined(player.ex_isparachuting))
		{
			player checkKillTriggers();
			counter++;
			if(!(counter % 4)) wait( [[level.ex_fpstime]](0.05) );
		}
	}

	[[level.ex_enableLevelEvent]]("onFrame", eventID);
}

checkKillTriggers()
{
	for(i = 0; i < level.killtriggers.size; i++)
	{
		killtrigger = level.killtriggers[i];
		if((self.origin[2] >= killtrigger.origin[2]) && (self.origin[2] <= killtrigger.origin[2] + killtrigger.height))
		{
			diff1 = killtrigger.origin - self.origin;
			diff2 = (diff1[0], diff1[1], 0);
			if(length(diff2) < killtrigger.radius + 16)
			{
				self iprintlnbold(&"EXPLOITS_PLAYER_WARNING", [[level.ex_pname]](self));
				self.ex_forcedsuicide = true;
				self suicide();
				return;
			}
		}
	}
}
