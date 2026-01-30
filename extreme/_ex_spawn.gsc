
spawnSpectator(origin, angles)
{
	self notify("spawned");
	self notify("end_respawn");

	// small delay to let eventcontroller execute all onPlayerSpawn() and all
	// onPlayerKilled() events caused by _ex_spawn::spawnSpectator() when the game
	// is over
	if(level.ex_gameover) wait( [[level.ex_fpstime]](.1) );
	if(!isPlayer(self)) return;

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	if(level.ex_classes == 1) self setClientCvar("ui_allow_classchange", "0");

	if(isDefined(self.pers["team"]) && self.pers["team"] == "spectator")
		self.statusicon = "";

	if(level.ex_currentgt != "dm" && level.ex_currentgt != "sd" && level.ex_currentgt != "lms" || level.ex_currentgt != "hm")
		maps\mp\gametypes\_spectating::setSpectatePermissions();

	if(level.ex_currentgt == "sd" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "esd")
	{
		if(!isDefined(self.skip_setspectatepermissions))
			maps\mp\gametypes\_spectating::setSpectatePermissions();
	}

	if(isDefined(origin) && isDefined(angles))
		self spawn(origin, angles);
	else
	{
		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}

	if(!level.ex_roundbased) self setClientCvar("cg_objectiveText", "");

	if(level.ex_currentgt == "esd") level maps\mp\gametypes\_ex_esd::updateTeamStatus();
	if(level.ex_currentgt == "ft") level maps\mp\gametypes\_ex_ft::updateTeamStatus();
	if(level.ex_currentgt == "lts") level maps\mp\gametypes\_ex_lts::updateTeamStatus();
	if(level.ex_currentgt == "rbcnq") level maps\mp\gametypes\_ex_rbcnq::updateTeamStatus();
	if(level.ex_currentgt == "rbctf") level maps\mp\gametypes\_ex_rbctf::updateTeamStatus();
	if(level.ex_currentgt == "sd") level maps\mp\gametypes\_ex_sd::updateTeamStatus();

	if(!level.ex_gameover) thread monitorSpec();

	[[level.updatetimer]]();
}

spawnPreIntermission()
{
	self setClientCvar("g_scriptMainMenu", "");
	self closeMenu();
	self spawnSpectator();
	self allowSpectateTeam("allies", false);
	self allowSpectateTeam("axis", false);
	self allowSpectateTeam("freelook", false);
	self allowSpectateTeam("none", true);
}

spawnIntermission()
{
	self notify("spawned");
	self notify("end_respawn");

	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
	if(isDefined(spawnpoint))
		self spawn(spawnpoint.origin, spawnpoint.angles);
	else
		maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");

	[[level.updatetimer]]();
}

monitorSpec()
{
	self endon("disconnect");
	self endon("spawned");

	sticky_spec = false;
	sticky_valid = false;
	sticky_spec_player = -1;

	while(1)
	{
		wait( [[level.ex_fpstime]](.05) );

		if(sticky_spec)
		{
			sticky_valid = monitorSpecVerify(sticky_spec_player);

			if(self meleebuttonpressed() || !sticky_valid)
			{
				self.spectatorclient = -1;
				sticky_spec = false;
				while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
			else if(self attackbuttonpressed())
			{
				sticky_spec_player = monitorSpecNext(sticky_spec_player);
				self.spectatorclient = sticky_spec_player;
				if(sticky_spec_player == -1) sticky_spec = false;
				while(self attackbuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
			else if(self usebuttonpressed())
			{
				sticky_spec_player = monitorSpecPrevious(sticky_spec_player);
				self.spectatorclient = sticky_spec_player;
				if(sticky_spec_player == -1) sticky_spec = false;
				while(self usebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
			}
		}
		else if(self usebuttonpressed())
		{
			if(sticky_spec_player == -1 || !monitorSpecVerify(sticky_spec_player)) sticky_spec_player = monitorSpecNext(sticky_spec_player);
			self.spectatorclient = sticky_spec_player;
			if(sticky_spec_player != -1) sticky_spec = true;
			while(self usebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
		}
	}
}

monitorSpecNext(spec_player)
{
	self endon("disconnect");

	// do not use level.players as we need an array sorted on entity numbers
	players = getentarray("player", "classname");

	// no need to search if there's only one player (that would be me)
	if(players.size == 1) return(-1);

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player))
		{
			entity = player getEntityNumber();
			if(entity > spec_player && player.sessionteam != "spectator") return(entity);
		}
	}

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionteam != "spectator")
		{
			entity = player getEntityNumber();
			return(entity);
		}
	}

	return(-1);
}

monitorSpecPrevious(spec_player)
{
	self endon("disconnect");

	// do not use level.players as we need an array sorted on entity numbers
	players = getentarray("player", "classname");

	// no need to search if there's only one player (that would be me)
	if(players.size == 1) return(-1);

	for(i = players.size - 1; i >= 0; i--)
	{
		player = players[i];
		if(isPlayer(player))
		{
			entity = player getEntityNumber();
			if(entity < spec_player && player.sessionteam != "spectator") return(entity);
		}
	}

	for(i = players.size - 1; i >= 0; i--)
	{
		player = players[i];
		if(isPlayer(player) && player.sessionteam != "spectator")
		{
			entity = player getEntityNumber();
			return(entity);
		}
	}

	return(-1);
}

monitorSpecVerify(spec_player)
{
	self endon("disconnect");

	// level.players is OK as we're only validating the player we (want to) spectate
	players = level.players;

	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isPlayer(player) && player getEntityNumber() == spec_player)
		{
			if(player.sessionteam != "spectator") return(true);
			return(false);
		}
	}

	return(false);
}
