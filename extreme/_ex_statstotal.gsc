#include extreme\_ex_hudcontroller;

init()
{
	if(level.ex_statstotal_monitor_player || level.ex_statstotal_monitor_team)
		[[level.ex_PrecacheShader]]("mod_blank_hudicon");

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
	if(level.ex_teamplay && level.ex_statstotal_monitor_team) level thread monitorStatsTeam(true);
}

onPlayerSpawned()
{
	//if(isDefined(self.pers["isbot"])) return;
	if(level.ex_readyup && !isDefined(game["readyup_done"])) return;
	startPlaying();
	if(level.ex_statstotal_monitor_player) self thread monitorStatsPlayer(false);
}

onPlayerKilled()
{
	//if(isDefined(self.pers["isbot"])) return;
	stopPlaying();
}

readStats()
{
	self.pers["total_points"] = 0;
	memory = self extreme\_ex_memory::getMemory("total", "points");
	if(!memory.error) self.pers["total_points"] = memory.value;
	if(self.pers["score"]) self.pers["total_points"] -= self.pers["score"];

	self.pers["total_kill"] = 0;
	memory = self extreme\_ex_memory::getMemory("total", "kills");
	if(!memory.error) self.pers["total_kill"] = memory.value;
	if(self.pers["kill"]) self.pers["total_kill"] -= self.pers["kill"];

	self.pers["total_death"] = 0;
	memory = self extreme\_ex_memory::getMemory("total", "deaths");
	if(!memory.error) self.pers["total_death"] = memory.value;
	if(self.pers["death"]) self.pers["total_death"] -= self.pers["death"];

	self.pers["total_bonus"] = 0;
	memory = self extreme\_ex_memory::getMemory("total", "bonus");
	if(!memory.error) self.pers["total_bonus"] = memory.value;
	if(self.pers["bonus"]) self.pers["total_bonus"] -= self.pers["bonus"];

	self.pers["total_special"] = 0;
	memory = self extreme\_ex_memory::getMemory("total", "special");
	if(!memory.error) self.pers["total_special"] = memory.value;
	if(self.pers["special"]) self.pers["total_special"] -= self.pers["special"];

	self.pers["total_time"] = 0;
	memory = self extreme\_ex_memory::getMemory("total", "time");
	if(!memory.error) self.pers["total_time"] = memory.value;

	if(!isDefined(self.pers["total_play"])) self.pers["total_play"] = 0;
	self.pers["total_start"] = 0;
	self.pers["total_session"] = 0;

	if(level.ex_statstotal_log)
	{
		message = "TOTALSTATS: " + self.name + " joined with stats: time " + self.pers["total_time"] + " seconds";
		message += ", points " + self.pers["total_points"];
		message += ", kills " + self.pers["total_kill"];
		message += ", deaths " + self.pers["total_death"];
		message += ", bonus " + self.pers["total_bonus"];
		message += ", special " + self.pers["total_special"];
		logprint(message + "\n");
	}
}

writeStats(commit)
{
	// players who are redirected to download don't have these vars yet
	if(!isDefined(self.pers) || !isDefined(self.pers["total_start"])) return;

	// if already committed to disk, no need to do it again. Players who made it
	// into intermission already have their stats updated. Moved away from using
	// self.pers variable so we are able to update stats for every round
	if(isDefined(self.totalstats_updated)) return;
	self.totalstats_updated = true;

	self stopPlaying();

	if(isDefined(self.pers["score"]))
	{
		points = self.pers["score"] + self.pers["specials_cash"];
		self.pers["total_points"] += points;
	}
	self extreme\_ex_memory::setMemory("total", "points", self.pers["total_points"], true);

	if(isDefined(self.pers["kill"])) self.pers["total_kill"] += self.pers["kill"];
	self extreme\_ex_memory::setMemory("total", "kills", self.pers["total_kill"], true);

	if(isDefined(self.pers["death"])) self.pers["total_death"] += self.pers["death"];
	self extreme\_ex_memory::setMemory("total", "deaths", self.pers["total_death"], true);

	if(isDefined(self.pers["bonus"])) self.pers["total_bonus"] += self.pers["bonus"];
	self extreme\_ex_memory::setMemory("total", "bonus", self.pers["total_bonus"], true);

	if(isDefined(self.pers["special"])) self.pers["total_special"] += self.pers["special"];
	self extreme\_ex_memory::setMemory("total", "special", self.pers["total_special"], true);

	self extreme\_ex_memory::setMemory("total", "time", self.pers["total_time"], commit);

	if(level.ex_statstotal_log)
	{
		logprint("TOTALSTATS: " + self.name + " updated stats, time " + self.pers["total_time"] + " seconds\n");
		info = getDurationInfo(self.pers["total_time"]);
		logprint("TOTALSTATS: " + self.name + " total playing time is " + info.message);
	}
}

writeStatsAll(commit)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
		if(isPlayer(players[i])) players[i] writeStats(commit);
}

startPlaying()
{
	self.pers["total_start"] = (gettime() / 1000);
	if(level.ex_statstotal_log)
	{
		if(self.pers["total_session"]) logprint("TOTALSTATS: " + self.name + " resumed playing on mark " + self.pers["total_start"] + ", session " + self.pers["total_session"] + ", total time " + self.pers["total_time"] + " seconds\n");
			else logprint("TOTALSTATS: " + self.name + " started playing on mark " + self.pers["total_start"] + ", total " + self.pers["total_time"] + "\n");
	}
}

stopPlaying()
{
	if(self.pers["total_start"])
	{
		session_stop = (gettime() / 1000);
		self.pers["total_play"] += int(session_stop - self.pers["total_start"]);
		self.pers["total_session"] += self.pers["total_play"];
		self.pers["total_time"] += self.pers["total_play"];
		if(level.ex_statstotal_log)
			logprint("TOTALSTATS: " + self.name + " stopped playing on mark " + session_stop + ", played " + self.pers["total_play"] + ", session " + self.pers["total_session"] + ", total time " + self.pers["total_time"] + " seconds\n");

		self.pers["total_play"] = 0;
		self.pers["total_start"] = 0;
	}
}

getMySkillLevel(grace)
{
	switch(level.ex_statstotal_balance_mode)
	{
		case 0: return( roundDecimal(getKillsPerMinute(self, grace), 1) );
		case 1: return( roundDecimal(getScorePerMinute(self, grace), 1) );
		default: return( roundDecimal(getWeightedSkill(self, grace), 1) );
	}
}

getKillsPerMinute(player, grace)
{
	if(!isPlayer(player)) return(0);

	total_kill = player.pers["total_kill"];
	if(isDefined(player.pers["kill"])) total_kill += player.pers["kill"];

	total_play = player.pers["total_play"];
	if(player.pers["total_start"]) total_play += int((gettime() / 1000) - player.pers["total_start"]);
	total_time = int((player.pers["total_time"] + total_play + 30) / 60); // in minutes

	if(!total_time || (grace && total_time < level.ex_statstotal_balance_grace)) return(0);
	player_skill = total_kill / total_time;
	return(player_skill);
}

getScorePerMinute(player, grace)
{
	if(!isPlayer(player)) return(0);

	total_points = player.pers["total_points"] + player.pers["specials_cash"];
	if(isDefined(player.pers["score"])) total_points += player.pers["score"];

	total_play = player.pers["total_play"];
	if(player.pers["total_start"]) total_play += int((gettime() / 1000) - player.pers["total_start"]);
	total_time = int((player.pers["total_time"] + total_play + 30) / 60); // in minutes

	if(!total_time || (grace && total_time < level.ex_statstotal_balance_grace)) return(0);
	player_skill = total_points / total_time;
	return(player_skill);
}

getKillDeathRatio(player)
{
	if(!isPlayer(player)) return(0);

	total_kill = player.pers["kill"];
	total_death = player.pers["death"];

	if(!total_kill || (total_kill - total_death) <= 0) return(0);
	player_skill = int( (100 / total_kill) * (total_kill - total_death) );
	return(player_skill);
}

getWeightedSkill(player, grace)
{
	if(!isPlayer(player)) return(0);

	total_kill = player.pers["total_kill"];
	if(isDefined(player.pers["kill"])) total_kill += player.pers["kill"];

	total_points = player.pers["total_points"] + player.pers["specials_cash"];
	if(isDefined(player.pers["score"])) total_points += player.pers["score"];

	total_play = player.pers["total_play"];
	if(player.pers["total_start"]) total_play += int((gettime() / 1000) - player.pers["total_start"]);
	total_time = int((player.pers["total_time"] + total_play + 30) / 60); // in minutes

	if(!total_time || (grace && total_time < level.ex_statstotal_balance_grace)) return(0);
	player_kpm = total_kill / total_time;
	player_spm = total_points / total_time;
	player_kdr = getKillDeathRatio(player);
	player_skill = (player_spm * 7) + (player_kpm * 3) + player_kdr;
	return(player_skill);
}

getTeamSkillLevel(team, grace, average, delay)
{
	switch(level.ex_statstotal_balance_mode)
	{
		case 0: return( roundDecimal(getTeamKillsPerMinute(team, grace, average, delay), 1) );
		case 1: return( roundDecimal(getTeamScorePerMinute(team, grace, average, delay), 1) );
		default: return( roundDecimal(getTeamWeightedSkill(team, grace, average, delay), 1) );
	}
}

getTeamKillsPerMinute(team, grace, average, delay)
{
	team_players = 0;
	team_total = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		if(isDefined(player.pers["team"]) && player.pers["team"] == team)
		{
			player_skill = getKillsPerMinute(player, grace);
			if(player_skill != 0)
			{
				team_players++;
				team_total += player_skill;
			}
		}
		if(delay) if(i % 5 == 0) wait( [[level.ex_fpstime]](0.05) );
	}

	if(!team_total || !team_players) return(0);
	if(average)
	{
		team_skill = team_total / team_players;
		return( roundDecimal(team_skill, 1) );
	}
	else return( roundDecimal(team_total, 1) );
}

getTeamScorePerMinute(team, grace, average, delay)
{
	team_players = 0;
	team_total = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		if(isDefined(player.pers["team"]) && player.pers["team"] == team)
		{
			player_skill = getScorePerMinute(player, grace);
			if(player_skill != 0)
			{
				team_players++;
				team_total += player_skill;
			}
		}
		if(delay) if(i % 5 == 0) wait( [[level.ex_fpstime]](0.05) );
	}

	if(!team_total || !team_players) return(0);
	if(average)
	{
		team_skill = team_total / team_players;
		return( roundDecimal(team_skill, 1) );
	}
	else return( roundDecimal(team_total, 1) );
}

getTeamWeightedSkill(team, grace, average, delay)
{
	team_players = 0;
	team_total = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player)) continue;
		if(isDefined(player.pers["team"]) && player.pers["team"] == team)
		{
			player_skill = getWeightedSkill(player, grace);
			if(player_skill != 0)
			{
				team_players++;
				team_total += player_skill;
			}
		}
		if(delay) if(i % 5 == 0) wait( [[level.ex_fpstime]](0.05) );
	}

	if(!team_total || !team_players) return(0);
	if(average)
	{
		team_skill = team_total / team_players;
		return( roundDecimal(team_skill, 1) );
	}
	else return( roundDecimal(team_total, 1) );
}

getTeamBalanceDiff()
{
	if(!level.ex_statstotal_balance_diff)
	{
		// TODO: include logic
		switch(level.ex_statstotal_balance_mode)
		{
			case 0: // kpm
				balance_diff = 10;
				break;
			case 1: // spm
				balance_diff = level.ex_points_kill * 10;
				break;
			default: // weighted, spm*7 + kpm*3 + kdr*1
				balance_diff = ((level.ex_points_kill * 10) * 7) + (10 * 3) + 50;
				break;
		}
	}
	else balance_diff = level.ex_statstotal_balance_diff;
	return(balance_diff);
}

getDurationInfo(seconds)
{
	seconds_minute = 60;
	seconds_hour = seconds_minute * 60;
	seconds_day = seconds_hour * 24;
	seconds_year = seconds_day * 365;

	years = 0;
	if(seconds >= seconds_year)
	{
		years = int(seconds / seconds_year);
		seconds = seconds % seconds_year;
	}
	days = 0;
	if(seconds >= seconds_day)
	{
		days = int(seconds / seconds_day);
		seconds = seconds % seconds_day;
	}
	hours = 0;
	if(seconds >= seconds_hour)
	{
		hours = int(seconds / seconds_hour);
		seconds = seconds % seconds_hour;
	}
	minutes = 0;
	if(seconds >= seconds_minute)
	{
		minutes = int(seconds / seconds_minute);
		seconds = seconds % seconds_minute;
	}

	info = spawnstruct();
	info.years = years;
	info.days = days;
	info.hours = hours;
	info.minutes = minutes;
	info.seconds = seconds;
	info.message = "";

	if(years)
	{
		if(years == 1) info.message += years + " year, ";
			else info.message += years + " years, ";
	}
	if(info.message != "" || days)
	{
		if(days == 1) info.message += days + " day, ";
			else info.message += days + " days, ";
	}
	if(info.message != "" || hours)
	{
		if(hours == 1) info.message += hours + " hour, ";
			else info.message += hours + " hours, ";
	}
	if(info.message != "" || minutes)
	{
		if(minutes == 1) info.message += minutes + " minute and ";
			else info.message += minutes + " minutes and ";
	}
	if(seconds == 1) info.message += seconds + " second\n";
		else info.message += seconds + " seconds\n";

	return(info);
}

monitorStatsPlayer(grace)
{
	self endon("kill_thread");

	basex = 120;
	if(level.ex_classes && level.ex_classes_hudicons) basex += 30;

	hud_index = playerHudCreate("statstotal_playerbg", basex, 450, level.ex_iconalpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "mod_blank_hudicon", 32, 32);
	playerHudScale(hud_index, 0.5, 0, 24, 24);

	hud_index = playerHudCreate("statstotal_playerskill", basex, 450, 1, (0.2,0.2,0), 0.7, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;

	stats = [];
	if((level.ex_statstotal_monitor_player & 1) == 1) stats[stats.size] = ::getKillsPerMinute;
	if((level.ex_statstotal_monitor_player & 2) == 2) stats[stats.size] = ::getScorePerMinute;
	if((level.ex_statstotal_monitor_player & 4) == 4) stats[stats.size] = ::getWeightedSkill;
	showing = 0;

	while(isAlive(self))
	{
		wait( [[level.ex_fpstime]](2) );
		stat = roundDecimal( [[stats[showing]]](self, grace), 1 );
		playerHudSetValue(hud_index, stat);

		showing++;
		if(showing > stats.size - 1) showing = 0;
	}
}

monitorStatsTeam(grace)
{
	if(isPlayer(self))
	{
		self endon("kill_thread");
		hudentity = self;
	}
	else
	{
		level endon("ex_gameover");
		hudentity = level;
	}

	hud_index = levelHudCreate("statstotal_alliesbg", undefined, 305, 450, level.ex_iconalpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "mod_blank_hudicon", 24, 24);

	hud_index = levelHudCreate("statstotal_alliesskill", undefined, 305, 450, 1, (0.2,0.2,0), 0.7, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;

	hud_index = levelHudCreate("statstotal_axisbg", undefined, 335, 450, level.ex_iconalpha, undefined, 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	levelHudSetShader(hud_index, "mod_blank_hudicon", 24, 24);

	hud_index = levelHudCreate("statstotal_axisskill", undefined, 335, 450, 1, (0.2,0.2,0), 0.7, 1, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;

	while(true)
	{
		wait( [[level.ex_fpstime]](2) );
		switch(level.ex_statstotal_balance_mode)
		{
			case 0: // kpm
				stat_allies = getTeamKillsPerMinute("allies", grace, true);
				stat_axis = getTeamKillsPerMinute("axis", grace, true);
				break;
			case 1: // spm
				stat_allies = getTeamScorePerMinute("allies", grace, true);
				stat_axis = getTeamScorePerMinute("axis", grace, true);
				break;
			default: // weighted
				stat_allies = getTeamWeightedSkill("allies", grace, true);
				stat_axis = getTeamWeightedSkill("axis", grace, true);
				break;
		}
		levelHudSetValue("statstotal_alliesskill", stat_allies);
		levelHudSetValue("statstotal_axisskill", stat_axis);
	}
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
