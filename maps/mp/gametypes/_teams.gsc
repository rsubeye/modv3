#include extreme\_ex_weapons;

init()
{
	level endon("ex_gameover");

	if(getCvar("scr_teambalance") == "") setCvar("scr_teambalance", "0");
	level.teambalance = getCvarInt("scr_teambalance");

	level.ex_autobalancing = false;
	if(level.ex_teamplay)
	{
		[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
		[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
		[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 5);

		wait( [[level.ex_fpstime]](0.15) );

		if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts")
		{
			if(level.teambalance)
			{
				if(level.ex_teambalance_delay)
				{
					wait( [[level.ex_fpstime]](level.ex_teambalance_delay) );
					level.ex_teambalance_delay = 0;
				}

				if(level.teambalance && !getTeamBalance())
				{
					iprintlnbold(&"MP_AUTOBALANCE_NEXT_ROUND");
					level waittill("restarting");

					if(level.teambalance && !getTeamBalance()) level balanceTeams();
				}
			}
		}
		else
		{
			for(;;)
			{
				if(level.teambalance)
				{
					if(level.ex_teambalance_delay)
					{
						wait( [[level.ex_fpstime]](level.ex_teambalance_delay) );
						level.ex_teambalance_delay = 0;
					}

					secondsleft = 999;
					if(game["timelimit"])
					{
						passedtime = (getTime() - level.starttime) / 1000;
						if(level.ex_overtime && game["matchovertime"]) secondsleft = int( (game["timelimit"] * 60) - passedtime + 0.5 );
							else if(level.ex_swapteams == 2 && !level.ex_roundbased) secondsleft = int( (game["halftimelimit"] * 60) - passedtime + 0.5 );
								else secondsleft = int( (game["timelimit"] * 60) - passedtime + 0.5 );
					}

					if(level.teambalance && secondsleft > 60 && !getTeamBalance())
					{
						if(level.ex_statstotal && level.ex_statstotal_balance >= 2) iprintlnbold(&"MP_AUTOBALANCE_SKILL_SECONDS", 15);
							else iprintlnbold(&"MP_AUTOBALANCE_SECONDS", 15);
						wait( [[level.ex_fpstime]](15) );

						secondsleft = 999;
						if(game["timelimit"])
						{
							passedtime = (getTime() - level.starttime) / 1000;
							if(level.ex_overtime && game["matchovertime"]) secondsleft = int( (game["timelimit"] * 60) - passedtime + 0.5 );
								else if(level.ex_swapteams == 2 && !level.ex_roundbased) secondsleft = int( (game["halftimelimit"] * 60) - passedtime + 0.5 );
									else secondsleft = int( (game["timelimit"] * 60) - passedtime + 0.5 );
						}

						if(level.teambalance && secondsleft > 60 && !getTeamBalance()) level balanceTeams();
					}

					wait( [[level.ex_fpstime]](level.ex_teambalance_interval) );
				}

				wait( [[level.ex_fpstime]](1) );
			}
		}
	}
}

onRandom(eventID)
{
	teambalance = getCvarInt("scr_teambalance");
	if(level.teambalance != teambalance) level.teambalance = teambalance;
}

onJoinedTeam()
{
	self updateTeamTime();
}

onJoinedSpectators()
{
	self.pers["teamTime"] = undefined;
}

updateTeamTime()
{
	if(level.ex_currentgt == "sd" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd") self.pers["teamTime"] = game["timepassed"] + ((getTime() - level.starttime) / 1000) / 60.0;
		else self.pers["teamTime"] = (gettime() / 1000);
}

getTeamBalance()
{
	level endon("ex_gameover");

	if(level.ex_autobalancing) return true;

	if(level.ex_statstotal && level.ex_statstotal_balance)
	{
		switch(level.ex_statstotal_balance)
		{
			case 1:
				getTeamBalanceSkills();
				return(getTeamBalanceTraditional());
			default: return(getTeamBalanceSkills());
		}
	}
	else return(getTeamBalanceTraditional());
}

getTeamBalanceSkills()
{
	level endon("ex_gameover");

	balance_diff = extreme\_ex_statstotal::getTeamBalanceDiff();

	AlliedPlayers = 0;
	AxisPlayers = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers["team"]))
		{
			if(player.pers["team"] != "spectator" && player.sessionteam != "spectator")
			{
				if(player.pers["team"] == "allies") AlliedPlayers++;
					else if(player.pers["team"] == "axis") AxisPlayers++;
			}
		}
	}

	if( (!AlliedPlayers && AxisPlayers <= 1) || (!AxisPlayers && AlliedPlayers <= 1) ) return true;

	AlliedSkill = extreme\_ex_statstotal::getTeamSkillLevel("allies", true, false, true);
	AxisSkill = extreme\_ex_statstotal::getTeamSkillLevel("axis", true, false, true);

	if(level.ex_statstotal_balance_log) logprint("SBAB: checking balance based on skill (Allies " + AlliedSkill + " vs Axis " + AxisSkill + ")\n");

	if( (AlliedSkill > AxisSkill) && (AlliedSkill > (AxisSkill + balance_diff)) ) return false;
		else if( (AxisSkill > AlliedSkill) && (AxisSkill > (AlliedSkill + balance_diff)) ) return false;

	return true;
}

getTeamBalanceTraditional()
{
	level endon("ex_gameover");

	AlliedPlayers = 0;
	AxisPlayers = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers["team"]))
		{
			if(player.pers["team"] != "spectator" && player.sessionteam != "spectator")
			{
				if(player.pers["team"] == "allies") AlliedPlayers++;
					else if(player.pers["team"] == "axis") AxisPlayers++;
			}
		}
	}

	if(AlliedPlayers > (AxisPlayers + 1)) return false;
		else if(AxisPlayers > (AlliedPlayers + 1)) return false;

	return true;
}

balanceTeams()
{
	level endon("ex_gameover");

	if(level.ex_autobalancing) return;
	level.ex_autobalancing = true;

	if(level.ex_statstotal && level.ex_statstotal_balance)
	{
		switch(level.ex_statstotal_balance)
		{
			case 1:
				balanceTeamsSkill(true);
				balanceTeamsTraditional();
				break;
			default:
				balanceTeamsSkill(false);
		}
	}
	else balanceTeamsTraditional();

	level.ex_autobalancing = false;
}

balanceTeamsSkill(fake)
{
	level endon("ex_gameover");

	balance_diff = extreme\_ex_statstotal::getTeamBalanceDiff();

	// populate the team arrays
	AlliedPlayers = [];
	AlliedSkill = 0.0;
	AxisPlayers = [];
	AxisSkill = 0.0;
	ClosestSkill = undefined;
	ClosestPlayer = undefined;
	MostRecent = undefined;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers) && isDefined(player.pers["team"]) && isDefined(player.pers["teamTime"]))
		{
			skill = player extreme\_ex_statstotal::getMySkillLevel(true);
			if(player.pers["team"] == "allies")
			{
				AlliedSkill += skill;
				index = AlliedPlayers.size;
				AlliedPlayers[index] = spawnstruct();
				AlliedPlayers[index].player = player;
				AlliedPlayers[index].skill = skill;
				AlliedPlayers[index].teamtime = player.pers["teamTime"];
			}
			else if(player.pers["team"] == "axis")
			{
				AxisSkill += skill;
				index = AxisPlayers.size;
				AxisPlayers[index] = spawnstruct();
				AxisPlayers[index].player = player;
				AxisPlayers[index].skill = skill;
				AxisPlayers[index].teamtime = player.pers["teamTime"];
			}
			wait( [[level.ex_fpstime]](0.05) );
		}
	}

	if(level.ex_statstotal_balance_log) logprint("SBAB: initiating balancing based on skill (Allies " + AlliedSkill + " vs Axis " + AxisSkill + ")\n");
	if(!fake) iprintlnbold(&"MP_AUTOBALANCE_SKILL_NOW");

	// sort team arrays based on skill and teamtime (lowest to highest)
	AlliedPlayers = sortTeamSkill(AlliedPlayers, 0, AlliedPlayers.size - 1);
	//logprint("ALLIED sorted:\n");
	//for(i = 0; i < AlliedPlayers.size; i++) logprint("Player " + AlliedPlayers[i].player.name + ": skill " + AlliedPlayers[i].skill + ", teamtime " + AlliedPlayers[i].teamtime + "\n");
	AxisPlayers = sortTeamSkill(AxisPlayers, 0, AxisPlayers.size - 1);
	//logprint("AXIS sorted:\n");
	//for(i = 0; i < AxisPlayers.size; i++) logprint("Player " + AxisPlayers[i].player.name + ": skill " + AxisPlayers[i].skill + ", teamtime " + AxisPlayers[i].teamtime + "\n");

	// check if allied player needs to be balanced based on skill level
	if( (AlliedSkill > AxisSkill) && (AlliedSkill > (AxisSkill + balance_diff)) )
	{
		if(level.ex_statstotal_balance_log) logprint("SBAB: balancing based on skill (Allies " + AlliedSkill + " vs Axis " + AxisSkill + ")\n");
		skill_diff = int( (AlliedSkill - AxisSkill) / 2 );

		// move allied player based on skill level and teamtime
		for(j = 0; j < AlliedPlayers.size; j++)
		{
			wait( [[level.ex_fpstime]](0.05) );
			if(isPlayer(AlliedPlayers[j].player))
			{
				if(isDefined(AlliedPlayers[j].player.dont_auto_balance) || !isDefined(AlliedPlayers[j].player.pers["teamTime"])) continue;

				skill_close = abs(AlliedPlayers[j].skill - skill_diff);
				if(!isDefined(ClosestSkill) || skill_close < ClosestSkill)
				{
					ClosestSkill = skill_close;
					ClosestPlayer = AlliedPlayers[j];
				}
			}
		}

		if(isDefined(ClosestSkill) && ClosestSkill < (skill_diff + balance_diff))
		{
			if(!fake) MostRecent = ClosestPlayer;
				else if(level.ex_statstotal_balance_log) logprint("SBAB: Allied player " + ClosestPlayer.player.name + " (skill " + ClosestPlayer.skill + ") would have been balanced\n");
		}

		if(isDefined(MostRecent))
		{
			if(level.ex_statstotal_balance_log) logprint("SBAB: moving Allied player " + MostRecent.player.name + " to Axis (skill " + MostRecent.skill + ")\n");
			if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || (isDefined(MostRecent.spawned) && (level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd"))) MostRecent.player changeTeam_RoundBased("axis");
				else MostRecent.player changeTeam("axis");
		}
	}
	// check if axis player needs to be balanced based on skill level
	else if( (AxisSkill > AlliedSkill) && (AxisSkill > (AlliedSkill + balance_diff)) )
	{
		if(level.ex_statstotal_balance_log) logprint("SBAB: balancing based on skill (Allies " + AlliedSkill + " vs Axis " + AxisSkill + ")\n");
		skill_diff = int( (AxisSkill - AlliedSkill) / 2 );

		// move axis player based on skill level and teamtime
		for(j = 0; j < AxisPlayers.size; j++)
		{
			wait( [[level.ex_fpstime]](0.05) );
			if(isPlayer(AxisPlayers[j].player))
			{
				if(isDefined(AxisPlayers[j].player.dont_auto_balance) || !isDefined(AxisPlayers[j].player.pers["teamTime"])) continue;

				skill_close = abs(AxisPlayers[j].skill - skill_diff);
				if(!isDefined(ClosestSkill) || skill_close < ClosestSkill)
				{
					ClosestSkill = skill_close;
					ClosestPlayer = AxisPlayers[j];
				}
			}
		}

		if(isDefined(ClosestSkill) && ClosestSkill < (skill_diff + balance_diff))
		{
			if(!fake) MostRecent = ClosestPlayer;
				else if(level.ex_statstotal_balance_log && isDefined(MostRecent)) logprint("SBAB: Axis player " + MostRecent.player.name + " (skill " + MostRecent.skill + ") would have been balanced\n");
		}

		if(isDefined(MostRecent))
		{
			if(level.ex_statstotal_balance_log) logprint("SBAB: moving Axis player " + MostRecent.player.name + " to Allies (skill " + MostRecent.skill + ")\n");
			if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || (isDefined(MostRecent.spawned) && (level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd"))) MostRecent.player changeTeam_RoundBased("allies");
				else MostRecent.player changeTeam("allies");
		}
	}

	// if run for logging purposes only, return now to kick off traditional balancing
	if(fake) return;

	// if skill based balancing failed, try player count balancing instead (one player only)
	if(!isDefined(MostRecent))
	{
		if(level.ex_statstotal_balance_log) logprint("SBAB: checking balance based on player count instead (Allies " + AlliedPlayers.size + " vs Axis " + AxisPlayers.size + ")\n");

		// check if allied player needs to be balanced based on player count
		if(AlliedPlayers.size > (AxisPlayers.size + 1))
		{
			if(level.ex_statstotal_balance_log) logprint("SBAB: balancing based on player count (Allies " + AlliedPlayers.size + " vs Axis " + AxisPlayers.size + ")\n");

			// move allied player with 0 skill who has been on the team the shortest amount of time (highest teamTime value)
			for(j = 0; j < AlliedPlayers.size; j++)
			{
				wait( [[level.ex_fpstime]](0.05) );
				if(isPlayer(AlliedPlayers[j].player))
				{
					if(isDefined(AlliedPlayers[j].player.dont_auto_balance) || !isDefined(AlliedPlayers[j].player.pers["teamTime"])) continue;
					if(AlliedPlayers[j].skill > 0) continue;

					MostRecent = AlliedPlayers[j];
					break;
				}
			}

			if(isDefined(MostRecent))
			{
				if(level.ex_statstotal_balance_log) logprint("SBAB: moving Allied player " + MostRecent.player.name + " to Allies (skill " + MostRecent.skill + ")\n");
				if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || (isDefined(MostRecent.spawned) && (level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd"))) MostRecent.player changeTeam_RoundBased("axis");
					else MostRecent.player changeTeam("axis");
			}
			else if(level.ex_statstotal_balance_log) logprint("SBAB: no Allied player with zero skill available. Auto-balance failed!\n");
		}
		// check if axis player needs to be balanced based on player count
		else if(AxisPlayers.size > (AlliedPlayers.size + 1))
		{
			if(level.ex_statstotal_balance_log) logprint("SBAB: balancing based on player count (Allies " + AlliedPlayers.size + " vs Axis " + AxisPlayers.size + ")\n");

			// move axis player with 0 skill who has been on the team the shortest amount of time (highest teamTime value)
			for(j = 0; j < AxisPlayers.size; j++)
			{
				wait( [[level.ex_fpstime]](0.05) );
				if(isPlayer(AxisPlayers[j].player))
				{
					if(isDefined(AxisPlayers[j].player.dont_auto_balance) || !isDefined(AxisPlayers[j].player.pers["teamTime"])) continue;
					if(AxisPlayers[j].skill > 0) continue;

					MostRecent = AxisPlayers[j];
					break;
				}
			}

			if(isDefined(MostRecent))
			{
				if(level.ex_statstotal_balance_log) logprint("SBAB: moving Axis player " + MostRecent.player.name + " to Allies (skill " + MostRecent.skill + ")\n");
				if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || (isDefined(MostRecent.spawned) && (level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd"))) MostRecent.player changeTeam_RoundBased("allies");
					else MostRecent.player changeTeam("allies");
			}
			else if(level.ex_statstotal_balance_log) logprint("SBAB: no Axis player with zero skill available. Auto-balance failed!\n");
		}
	}
	// double the auto-balance interval after successful skill based balancing
	else if(level.ex_statstotal_balance_interval) level.ex_teambalance_interval = level.ex_teambalance_interval * 2;
}

sortTeamsSkillTest()
{
/*
		AlliedPlayers = [];
		for(i = 0; i < 64; i++)
		{
			index = AlliedPlayers.size;
			AlliedPlayers[index] = spawnstruct();
			AlliedPlayers[index].no = i;
			AlliedPlayers[index].skill = roundDecimal(randomInt(10), 2);
			AlliedPlayers[index].teamtime = randomInt(100);
		}

		logprint("ALLIED unsorted:\n");
		for(i = 0; i < AlliedPlayers.size; i++) logprint("Player " + AlliedPlayers[i].no + ": skill " + AlliedPlayers[i].skill + ", teamtime " + AlliedPlayers[i].teamtime + "\n");
		AlliedPlayers = sortTeamSkill(AlliedPlayers, 0, AlliedPlayers.size - 1);
		logprint("ALLIED sorted:\n");
		for(i = 0; i < AlliedPlayers.size; i++) logprint("Player " + AlliedPlayers[i].no + ": skill " + AlliedPlayers[i].skill + ", teamtime " + AlliedPlayers[i].teamtime + "\n");

		AxisPlayers = [];
		for(i = 0; i < 64; i++)
		{
			index = AxisPlayers.size;
			AxisPlayers[index] = spawnstruct();
			AxisPlayers[index].no = i;
			AxisPlayers[index].skill = roundDecimal(randomInt(10), 2);
			AxisPlayers[index].teamtime = randomInt(100);
		}

		logprint("AXIS unsorted:\n");
		for(i = 0; i < AxisPlayers.size; i++) logprint("Player " + AxisPlayers[i].no + ": skill " + AxisPlayers[i].skill + ", teamtime " + AxisPlayers[i].teamtime + "\n");
		AxisPlayers = sortTeamSkill(AxisPlayers, 0, AxisPlayers.size - 1);
		logprint("AXIS sorted:\n");
		for(i = 0; i < AxisPlayers.size; i++) logprint("Player " + AxisPlayers[i].no + ": skill " + AxisPlayers[i].skill + ", teamtime " + AxisPlayers[i].teamtime + "\n");
*/

	wait(30);
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers))
		{
			player.pers["total_time"] = randomInt(level.MAX_UNSIGNED_SHORT);
			player.pers["total_kill"] = int( (player.pers["total_time"] / 60) * (1 + randomInt(10)) );
			player.pers["total_death"] = int(player.pers["total_kill"] / 2);
			player.pers["total_points"] = player.pers["total_kill"] * level.ex_points_kill;
			player.pers["total_bonus"] = int(player.pers["total_points"] * 0.1);
			player.pers["total_special"] = 0;
		}
	}
}

sortTeamSkill(array, first, last)
{
	sortarray = array;
	if(first >= last || sortarray.size < 2) return(sortarray);

	// in-place quicksort partitioning
	pivot_index = int((first + last) / 2);
	pivot = sortarray[pivot_index];

	// move pivot value to last element
	t = sortarray[pivot_index];
	sortarray[pivot_index] = sortarray[last];
	sortarray[last] = t;

	pivot_index = first;
	for(i = first; i < last; i++)
	{
		if(sortarray[i].skill == pivot.skill)
		{
			if(sortarray[i].teamtime > pivot.teamtime)
			{
				t = sortarray[i];
				sortarray[i] = sortarray[pivot_index];
				sortarray[pivot_index] = t;
				pivot_index++;
			}
		}
		else if(sortarray[i].skill < pivot.skill)
		{
			t = sortarray[i];
			sortarray[i] = sortarray[pivot_index];
			sortarray[pivot_index] = t;
			pivot_index++;
		}
	}

	// restore pivot value
	t = sortarray[pivot_index];
	sortarray[pivot_index] = sortarray[last];
	sortarray[last] = t;

	// recursively sort elements smaller than the pivot
	sortarray = sortTeamSkill(sortarray, first, pivot_index - 1);

	// recursively sort elements at least as big as the pivot
	sortarray = sortTeamSkill(sortarray, pivot_index + 1, last);

	return(sortarray);
}

balanceTeamsTraditional()
{
	level endon("ex_gameover");

	// populate the team arrays
	AlliedPlayers = [];
	AlliedClanPlayers = 0;
	AxisPlayers = [];
	AxisClanPlayers = 0;
	MostRecent = undefined;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		wait( [[level.ex_fpstime]](0.05) );
		player = players[i];
		if(isPlayer(player) && isDefined(player.pers["teamTime"]))
		{
			if(isDefined(player.pers["team"]))
			{
				if(player.pers["team"] == "allies")
				{
					AlliedPlayers[AlliedPlayers.size] = player;
					if(isDefined(player.ex_name) && player.ex_clid == 1) AlliedClanPlayers++;
				}
				else if(player.pers["team"] == "axis")
				{
					AxisPlayers[AxisPlayers.size] = player;
					if(isDefined(player.ex_name) && player.ex_clid == 1) AxisClanPlayers++;
				}
			}
		}
	}

	// if level.ex_clantag1_nobalance is enabled, clan1 members will not be auto-balanced, unless all players on that team are clan members
	clan_nobalance = level.ex_clantag1_nobalance;
	if(clan_nobalance && (AlliedPlayers.size == AlliedClanPlayers || AxisPlayers.size == AxisClanPlayers)) clan_nobalance = false;

	iprintlnbold(&"MP_AUTOBALANCE_NOW");

	while( (AlliedPlayers.size > (AxisPlayers.size + 1)) || (AxisPlayers.size > (AlliedPlayers.size + 1)) )
	{
		if(AlliedPlayers.size > (AxisPlayers.size + 1))
		{
			// move allied player who has been on the team the shortest amount of time (highest teamTime value)
			for(j = 0; j < AlliedPlayers.size; j++)
			{
				wait( [[level.ex_fpstime]](0.05) );
				player = AlliedPlayers[j];
				if(isPlayer(player) && (isDefined(player.dont_auto_balance) || !isDefined(player.pers) || !isDefined(player.pers["teamTime"]))) continue;

				// skip clan1 player if clan1 is excluded from auto-balance
				if(clan_nobalance && isDefined(player.ex_name) && player.ex_clid == 1) continue;

				if(isPlayer(player))
				{
					if(!isDefined(MostRecent)) MostRecent = player;
						else if(isPlayer(player) && isDefined(player.pers["teamTime"]) && player.pers["teamTime"] > MostRecent.pers["teamTime"]) MostRecent = player;
				}
			}

			if(isDefined(MostRecent))
			{
				if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || (isDefined(MostRecent.spawned) && (level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd"))) MostRecent changeTeam_RoundBased("axis");
					else MostRecent changeTeam("axis");
			}
		}
		else if(AxisPlayers.size > (AlliedPlayers.size + 1))
		{
			// move axis player who has been on the team the shortest amount of time (highest teamTime value)
			for(j = 0; j < AxisPlayers.size; j++)
			{
				wait( [[level.ex_fpstime]](0.05) );
				player = AxisPlayers[j];
				if(isPlayer(player) && (isDefined(player.dont_auto_balance) || !isDefined(player.pers) || !isDefined(player.pers["teamTime"]))) continue;

				// skip clan1 player if clan1 is excluded from auto-balance
				if(clan_nobalance && isDefined(player.ex_name) && player.ex_clid == 1) continue;

				if(isPlayer(player))
				{
					if(!isDefined(MostRecent)) MostRecent = player;
						else if(isPlayer(player) && isDefined(player.pers["teamTime"]) && player.pers["teamTime"] > MostRecent.pers["teamTime"]) MostRecent = player;
				}
			}

			if(isDefined(MostRecent))
			{
				if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || (isDefined(MostRecent.spawned) && (level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd"))) MostRecent changeTeam_RoundBased("allies");
					else MostRecent changeTeam("allies");
			}
		}

		// populate the team arrays to check again
		AlliedPlayers = [];
		AlliedClanPlayers = 0;
		AxisPlayers = [];
		AxisClanPlayers = 0;
		MostRecent = undefined;

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			wait( [[level.ex_fpstime]](0.05) );
			player = players[i];
			if(isPlayer(player) && isDefined(player.pers["teamTime"]))
			{
				if(isDefined(player.pers["team"]))
				{
					if(player.pers["team"] == "allies")
					{
						AlliedPlayers[AlliedPlayers.size] = player;
						if(isDefined(player.ex_name) && player.ex_clid == 1) AlliedClanPlayers++;
					}
					else if(player.pers["team"] == "axis")
					{
						AxisPlayers[AxisPlayers.size] = player;
						if(isDefined(player.ex_name) && player.ex_clid == 1) AxisClanPlayers++;
					}
				}
			}
		}

		clan_nobalance = level.ex_clantag1_nobalance;
		if(clan_nobalance && (AlliedPlayers.size == AlliedClanPlayers || AxisPlayers.size == AxisClanPlayers)) clan_nobalance = false;
	}
}

changeTeam(team, special)
{
	if(!isDefined(special)) special = false;

	if(level.ex_mbot && isDefined(self.pers["isbot"]))
	{
		leavingteam = self.pers["team"];

		self thread extreme\_ex_bots::botJoin("spectator");
		wait( [[level.ex_fpstime]](0.75) );

		if(leavingteam == "allies")
		{
			level.bots_al--;
			self thread extreme\_ex_bots::addBot("axis");
		}
		else
		{
			level.bots_ax--;
			self thread extreme\_ex_bots::addBot("allies");
		}
	}
	else
	{
		if(self.sessionstate != "dead")
		{
			// Set a flag on the player to they aren't robbed points for dying - the callback will remove the flag
			if(!special)
			{
				self.switching_teams = true;
				self.joining_team = team;
				self.leaving_team = self.pers["team"];
			}
		
			// Suicide the player so they can't hit escape and fail the team balance
			self suicide();
		}

		self.pers["team"] = team;
		self.pers["savedmodel"] = undefined;
		self.sessionteam = self.pers["team"];

		if(isDefined(self.pers["isbot"]))
		{
			self thread extreme\_ex_bots::dbotLoadout();
			return;
		}

		// create the eXtreme+ weapon array
		self extreme\_ex_weapons::setWeaponArray();

		// clear game weapon array
		self extreme\_ex_clientcontrol::clearWeapons();
	
		// update spectator permissions immediately on change of team
		self maps\mp\gametypes\_spectating::setSpectatePermissions();

		// update allowed weapons
		self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

		// allow weapon change, do not allow team change!
		self setClientCvar("ui_allow_weaponchange", "1");
		self setClientCvar("ui_allow_teamchange", 0);

		if(level.ex_frag_fest)
		{
			self.pers["weapon"] = "none";
			self setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
			[[level.spawnplayer]]();
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				self setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
				self openMenu(game["menu_weapon_allies"]);
			}
			else
			{
				self setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
				self openMenu(game["menu_weapon_axis"]);
			}
		}

		self updateTeamTime();

		self notify("end_respawn");
	}
}

changeTeam_RoundBased(team)
{
	self.pers["team"] = team;
	self.pers["savedmodel"] = undefined;

	// create the eXtreme+ weapon array
	self extreme\_ex_weapons::setWeaponArray();

	// clear game weapon array
	self extreme\_ex_clientcontrol::clearWeapons();

	// update allowed weapons
	self thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

	// do not allow team change!
	self setClientCvar("ui_allow_teamchange", 0);

	self updateTeamTime();
}

countPlayers()
{
	//chad
	allies = 0;
	axis = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies")) allies++;
			else if((isDefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis")) axis++;
	}
	players["allies"] = allies;
	players["axis"] = axis;
	return players;
}

switchClanVersusNonclan(mode)
{
	level endon("ex_gameover");

	if(mode == level.ex_clanvsnonclan) return;

	if(mode == 0)
	{
		level.ex_clanvsnonclan = 0;
		iprintlnBold(&"MISC_CLANVSNONCLAN_SWITCHOFF_NOW");

		level.ex_autoassign = level.ex_autoassign_org;
		if(level.ex_autoassign == 2)
		{
			level.teambalance = 0;
			setCvar("scr_teambalance", level.teambalance);
		}
		else
		{
			level.teambalance = [[level.ex_drm]]("scr_teambalance", 1, 0, 1,"int");
			setCvar("scr_teambalance", level.teambalance);
			if(level.teambalance && !getTeamBalance()) level balanceTeams();
		}
	}

	if(mode == 1)
	{
		level.ex_clanvsnonclan = 1;
		iprintlnBold(&"MISC_CLANVSNONCLAN_SWITCHON_NOW");

		wait [[level.ex_fpstime]]((3) );
		players = level.players;
		for(i = 0; i < players.size; i++) players[i] freezecontrols(true);

		level.ex_autoassign = 2;
		level.ex_autoassign_bridge = 1;
		level.teambalance = 0;
		setCvar("scr_teambalance", level.teambalance);

		wait( [[level.ex_fpstime]](3) );
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			players[i] extreme\_ex_main::resetPlayerVariables();
			players[i] freezecontrols(false);
		}

		thread balanceClanVersusNonclan();
		wait( [[level.ex_fpstime]](5) );
		iprintlnBold(&"MISC_CLANVSNONCLAN_RESTART");
		wait( [[level.ex_fpstime]](3) );
		if(level.ex_statstotal) extreme\_ex_statstotal::writeStatsAll(true);
		map_restart(true);
	}

	if(mode == 2)
	{
		level.ex_clanvsnonclan = 2;
		iprintlnBold(&"MISC_CLANVSNONCLAN_SWITCHON_NEXTMAP");
	}

	if(mode == 3)
	{
		level.ex_clanvsnonclan = 3;
		iprintlnBold(&"MISC_CLANVSNONCLAN_SWITCHOFF_NEXTMAP");
	}
}

balanceClanVersusNonclan()
{
	level endon("ex_gameover");

	iprintlnbold(&"MP_AUTOBALANCE_NOW");

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(isPlayer(player))
		{
			if(isDefined(player.ex_name) && player.ex_clid == 1)
			{
				if(isDefined(player.pers["team"]) && player.pers["team"] != level.ex_autoassign_clanteam)
					if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || level.ex_currentgt == "ihtf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd") player changeTeam_RoundBased(level.ex_autoassign_clanteam);
						else player changeTeam(level.ex_autoassign_clanteam, true);
			}
			else
			{
				if(isDefined(player.pers["team"]) && player.pers["team"] != level.ex_autoassign_nonclanteam)
					if(level.ex_currentgt == "sd" || level.ex_currentgt == "lts" || level.ex_currentgt == "ihtf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd") player changeTeam_RoundBased(level.ex_autoassign_nonclanteam);
						else player changeTeam(level.ex_autoassign_nonclanteam, true);
			}
		}
	}
}

monitorClanVersusNonclan()
{
	level endon("ex_gameover");

	check_interval = 60; // seconds between each check
	noplayers_checks_max = 3; // terminate clan vs. non-clan if still no players after x checks
	nomembers_checks_max = 3; // terminate clan vs. non-clan if still no members after x checks
	members_min = 2; // minimum numbers of clan members needed to keep clan vs. non-clan alive

	noplayers_checks = 0;
	nomembers_checks = 0;

	monitoring = true;
	while(monitoring)
	{
		wait( [[level.ex_fpstime]](check_interval) );

		//logprint("CLANVSNONCLAN: checking for players\n");
		members = 0;

		players = level.players;
		if(players.size)
		{
			noplayers_checks = 0;
			//logprint("CLANVSNONCLAN: checking for members\n");
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isDefined(player.ex_name) && player.ex_clid == 1)
				{
					members++;
					//logprint("CLANVSNONCLAN: member " + player.name + " is online\n");
				}
			}
			if(members < members_min) nomembers_checks++;
				else nomembers_checks = 0;
			if(nomembers_checks == nomembers_checks_max) monitoring = false;
		}
		else
		{
			noplayers_checks++;
			if(noplayers_checks == noplayers_checks_max) monitoring = false;
		}
	}

	//logprint("CLANVSNONCLAN: switching to any to any mode\n");
	setCvar("ex_clanvsnonclan", 0);
	switchClanVersusNonclan(0);
}

roundDecimal(f, decimals)
{
	if(!isDefined(decimals)) decimals = 1;
	whole = int(f);
	switch(decimals)
	{
		case 5: fraction = (int(100000 * (f - whole) + 0.5)) / 100000; break; // 5 decimals
		case 4: fraction = (int(10000 * (f - whole) + 0.5)) / 10000; break; // 4 decimals
		case 3: fraction = (int(1000 * (f - whole) + 0.5)) / 1000; break; // 3 decimals
		case 2: fraction = (int(100 * (f - whole) + 0.5)) / 100; break; // 2 decimals
		default: fraction = (int(10 * (f - whole) + 0.5)) / 10; // 1 decimal
	}
	return(whole + fraction);
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return(var);
}
