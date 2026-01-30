
init()
{
	// Draws a team icon over teammates
	// dvar scr_drawfriend and level.drawfriend set in _ex_gtcommon.gsc

	switch(game["allies"])
	{
		case "american":
			game["headicon_allies"] = "headicon_american";
			break;
		case "british":
			game["headicon_allies"] = "headicon_british";
			break;
		default:
			game["headicon_allies"] = "headicon_russian";
			break;
	}

	game["headicon_axis"] = "headicon_german";
	[[level.ex_PrecacheHeadIcon]](game["headicon_axis"]);
	[[level.ex_PrecacheHeadIcon]](game["headicon_allies"]);

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 5);
	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
}

onRandom(eventID)
{
	level endon("ex_gameover");

	drawfriend = getCvarInt("scr_drawfriend");
	if(level.drawfriend != drawfriend)
	{
		level.drawfriend = drawfriend;
		updateFriendIcons();
	}
}

onPlayerSpawned()
{
	self thread showFriendIcon();
}

onPlayerKilled()
{
	self.headicon = "";
}

showFriendIcon()
{
	if(level.ex_currentgt == "hm" && isDefined(self.hm_status))
	{
		self thread maps\mp\gametypes\_ex_hm::setHeadIcon();
	}
	else if(level.ex_currentgt == "vip" && isDefined(self.isvip) && self.isvip)
	{
		self thread maps\mp\gametypes\_ex_vip::setHeadIcon();
	}
	else if(level.drawfriend && self.pers["team"] != "spectator")
	{
		if(level.ex_classes && level.ex_classes_headicons)
		{
			self.headicon = self thread extreme\_ex_classes::getHeadIcon();
			self.headiconteam = self.pers["team"];
		}
		else if(level.ex_ranksystem && level.ex_rank_headicons)
		{
			self.headicon = self thread extreme\_ex_ranksystem::getHeadIcon();
			self.headiconteam = self.pers["team"];
		}
		else
		{
			if(self.pers["team"] == "allies")
			{
				self.headicon = game["headicon_allies"];
				self.headiconteam = "allies";
			}
			else
			{
				self.headicon = game["headicon_axis"];
				self.headiconteam = "axis";
			}
		}
	}
	else
	{
		self.headicon = "";
		self.headiconteam = "";
	}
}

updateFriendIcons()
{
	// for all living players, show the appropriate headicon
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || !isDefined(player.pers["team"]) || player.pers["team"] == "spectator") continue;
		player thread showFriendIcon();
	}
}
