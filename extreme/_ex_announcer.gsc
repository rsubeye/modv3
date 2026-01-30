#include extreme\_ex_hudcontroller;

init()
{
	[[level.ex_registerLevelEvent]]("onSecond", ::onSecond);
}

onSecond(eventID)
{
	if(level.mapended || level.ex_gameover || game["matchpaused"]) return;

	passedtime = (getTime() - level.starttime) / 1000;
	if(level.ex_overtime && game["matchovertime"]) secondsleft = int( (game["timelimit"] * 60) - passedtime + 0.5 );
		else if(level.ex_swapteams == 2 && !level.ex_roundbased) secondsleft = int( (game["halftimelimit"] * 60) - passedtime + 0.5 );
			else secondsleft = int( (game["timelimit"] * 60) - passedtime + 0.5 );

	if(secondsleft > 300 || secondsleft < 5) return;

	if(game["scorelimit"] != 0 && level.ex_teamplay)
	{
		alliesscore = getTeamScore("allies");
		axisscore = getTeamScore("axis");
		if(axisscore >= game["scorelimit"] || alliesscore >= game["scorelimit"]) return;
	}

	color = (0.705, 0.705, 0.392);
	anscore = false;
	antime = undefined;
	if(secondsleft == 300) { antime = "fivemins"; color = (0,1,1); anscore = true; }      // 5 mins
	if(secondsleft == 120) { antime = "twomins"; color = (.1,.6,.5); anscore = true; }    // 2 mins
	if(secondsleft ==  60) { antime = "onemin"; color = (.7,.2,.2); anscore = true; }     // 1 min
	if(secondsleft ==  30) { antime = "thirtysecs"; color = (.7,.7,.7); anscore = true; } // 30 secs
	if(secondsleft ==  20) { antime = "twentysecs"; color = (1,1,0); }                    // 20 secs
	if(secondsleft ==  10) { antime = "tensecs"; color = (1,0,0); }                       // 10 secs
	if(secondsleft ==   5) { antime = "fftto"; color = (1,0,0); }                         // 5 secs

	if(game["scorelimit"] <= 0 || !level.ex_teamplay) anscore = false;
		else if(level.ex_overtime && game["matchovertime"] && level.ex_currentgt == "tdm") anscore = false;

	if(isDefined(antime))
	{
		if(level.ex_announcer != 2) levelHudSetColor("mainclock", color);

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(!isPlayer(player) || !isDefined(player.pers) || !isDefined(player.pers["team"])) continue;

			// announce time
			if(level.ex_announcer_time) player playLocalSound(antime);

			// announce score
			if(level.ex_announcer_score && anscore) player thread announceScore();
		}
	}
}

announceScore()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");
	team = undefined;
	txt = undefined;
	aname = undefined;
	closetowin = false;

	if(axisscore == alliedscore)
	{
		self iprintln(&"SCORES_LEVEL");
		return;
	}

	if(axisscore < alliedscore)
	{
		ascore = game["scorelimit"] - alliedscore;
		team = "allies";
	}
	else
	{
		ascore = game["scorelimit"] - axisscore;
		team = "axis";
	}

	if(ascore > (game["scorelimit"] - 10))
	 	closetowin = true;
	
	if(self.pers["team"] == "allies") // if teams are not near winning, show scores
	{
		aname = &"SCORES_GERMAN";
		
		if(!closetowin)
		{
			if(alliedscore < axisscore)
				self iprintln(&"SCORES_YOUR_TEAM", (axisscore - alliedscore), &"SCORES_BEHIND", aname);
			else if(alliedscore > axisscore)
				self iprintln(&"SCORES_YOUR_TEAM", (alliedscore - axisscore), &"SCORES_AHEAD", aname);
			return;
		}
	}
	else
	{
		switch(game["allies"])
		{
			case "american":
				aname = &"SCORES_AMERICAN";
				break;
	
			case "british":
				aname = &"SCORES_BRITISH";
				break;
		
			case "russian":
				aname = &"SCORES_RUSSIAN";
				break;
		}
		
		if(!closetowin)
		{
			if(axisscore < alliedscore)
				self iprintln(&"SCORES_YOUR_TEAM", (alliedscore - axisscore), &"SCORES_BEHIND", aname);
			else if(axisscore > alliedscore)
				self iprintln(&"SCORES_YOUR_TEAM", (axisscore - alliedscore), &"SCORES_AHEAD", aname);
			return;
		}
	}

	// a team is close to winning
	if(self.pers["team"] != team) self iprintln(&"SCORES_TEAM_LOSING_MSGA", aname, &"SCORES_TEAM_LOSING_MSGB", ascore, &"SCORES_TEAM_WINNING");
		else self iprintln(&"SCORES_YOUR_TEAM", ascore, &"SCORES_TEAM_WINNING");
}
