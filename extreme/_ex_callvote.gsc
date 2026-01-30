
init()
{
	// We need level.ex_allowvote to remember the original setting so we know if we
	// have to send the voting vars to the client when they join.
	// level.allowvote in _serversettings.gsc will be synced to what we set here
	level.ex_allowvote = voteGetStatus();
	if(!level.ex_callvote_mode || !level.ex_allowvote)
	{
		voteSetStatus(level.ex_allowvote);
		return;
	}

	switch(level.ex_callvote_mode)
	{
		case 1:
			level.ex_callvote_timer = level.ex_callvote_disable_time;
			level.ex_callvote_state = false;
			break;
		case 2:
			level.ex_callvote_timer = level.ex_callvote_enable_time;
			level.ex_callvote_state = true;
			break;
		case 3:
			if(level.ex_callvote_delay) level.ex_callvote_timer = level.ex_callvote_delay;
				else level.ex_callvote_timer = level.ex_callvote_disable_time;
			level.ex_callvote_state = false;
			break;
		case 4:
			if(level.ex_callvote_delay) level.ex_callvote_timer = level.ex_callvote_delay;
				else level.ex_callvote_timer = level.ex_callvote_enable_time;
			level.ex_callvote_state = true;
			break;
	}
	voteSetStatus(level.ex_callvote_state);

	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
}

onSecond(eventID)
{
	level endon("ex_gameover");

	if(level.ex_callvote_delay_players)
	{
		players = level.players;
		playercount = players.size;
		for(i = 0; i < players.size; i++)
		{
			if(isDefined(players[i].pers["team"]) && players[i].pers["team"] == "spectator" || players[i].sessionteam == "spectator")
				playercount--;
		}
		if(playercount < level.ex_callvote_delay_players) return;
		level.ex_callvote_delay_players = 0;
	}

	level.ex_callvote_timer--;
	if(!level.ex_callvote_timer)
	{
		level.ex_callvote_state = !level.ex_callvote_state;
		voteSetStatus(level.ex_callvote_state);

		switch(level.ex_callvote_mode)
		{
			case 1:
				if(level.ex_callvote_msg == 1 || level.ex_callvote_msg == 3) iprintln(&"MISC_CALLVOTE_ENABLED");
				[[level.ex_disableLevelEvent]]("onSecond", eventID);
				break;
			case 2:
				if(level.ex_callvote_msg == 2 || level.ex_callvote_msg == 3) iprintln(&"MISC_CALLVOTE_DISABLED");
				[[level.ex_disableLevelEvent]]("onSecond", eventID);
				break;
			case 3:
			case 4:
				if(level.ex_callvote_state)
				{
					if(level.ex_callvote_msg == 1 || level.ex_callvote_msg == 3) iprintln(&"MISC_CALLVOTE_TMPENABLED");
					level.ex_callvote_timer = level.ex_callvote_enable_time;
				}
				else
				{
					if(level.ex_callvote_msg == 2 || level.ex_callvote_msg == 3) iprintln(&"MISC_CALLVOTE_TMPDISABLED");
					level.ex_callvote_timer = level.ex_callvote_disable_time;
				}
				break;
		}
	}
}

voteGetStatus()
{
	allowvote = getCvar("g_allowvote");
	if(allowvote != "")	return( (getCvarInt("g_allowvote") == 1) );
	return(true);
}

voteSetStatus(state)
{
	if(state) setCvar("g_allowvote", "1");
		else setCvar("g_allowvote", "0");
}
