
init()
{
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 10);
}

onRandom(eventID)
{
	level endon("ex_gameover");

	// Remove color codes from player names, and init vars
	mononames = [];
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i])) mononames[i] = extreme\_ex_utils::monotone(players[i].name);

		// If player did not spawn yet, these vars are not available to evaluate, so define them
		if(!isDefined(players[i].ex_isunknown))
		{
			players[i].ex_isunknown = false;
			players[i].ex_ispunished = false;
			players[i].ex_isdupname = false;
		}
	}

	// If enabled, check for Unknown Soldiers and other unacceptable names
	if(level.ex_uscheck)
	{
		for(i = 0; i < players.size; i++)
		{
			// Proceed only if not already handled by Unknown Soldier or Duplicate Name handling code
			if(isPlayer(players[i]) && !players[i].ex_isunknown && !players[i].ex_ispunished && !players[i].ex_isdupname)
			{
				if(isUnknown(players[i]))
				{
					// Got one! If playing right now then start the handling code.
					if(players[i].sessionstate == "playing") players[i] thread handleUnknown(false);
						// Otherwise tag him, so we can handle it when he spawns.
						else players[i].ex_isunknown = true;
				}
			}
		}
	}

	// If there is nothing to compare, skip the duplicate name test
	if(players.size < 2) return;

	// Check for duplicate names
	for(i = 0; i < players.size-1; i++)
	{
		for(j = i+1; j < players.size; j++)
		{
			if(mononames[i] == mononames[j])
			{
				// Got one! Proceed only if player is not already handled by Name Checker code
				if(isPlayer(players[j]) && !players[j].ex_isdupname)
				{
					// Proceed only if player is not already handled by Unknown Soldier handling code
					if(!players[j].ex_isunknown)
					{
						// If playing right now then start the handling code.
						if(players[j].sessionstate == "playing") players[j] thread handleDupName();
							// Otherwise tag him, so we can handle it when he spawns.
							else players[j].ex_isdupname = true;
					}
					// Otherwise tag him, so the Unknown Soldier handling code can act on it
					else players[j].ex_isdupname = true;
				}
			}
		}
	}
}

handleDupName()
{
	self endon("kill_thread");
	self endon("ex_freefall");

	// Tag the player to prevent the Name Checker to kick in more than once
	self.ex_isdupname = true;

	self iprintlnbold(&"NAMECHECK_DNCHECK_DUPNAME1", [[level.ex_pname]](self));
	self setClientCvar("name", "Unknown Soldier");
	self iprintlnbold(&"NAMECHECK_DNCHECK_NEWUNKNOWN");

	if(level.ex_ncskipwarning)
	{
		if(level.ex_usclanguest) self iprintlnbold(&"NAMECHECK_DNCHECK_NEXTCLANGUEST");
			else self iprintlnbold(&"NAMECHECK_DNCHECK_NEXTGUEST");
	}
	else self iprintlnbold(&"NAMECHECK_DNCHECK_NEXTUNKNOWN");

	// Wait several seconds before starting the Unknown Soldier handling code
	wait( [[level.ex_fpstime]](10) );
	if(isPlayer(self))
	{
		self thread handleUnknown(level.ex_ncskipwarning);

		// Remove the tag; the player is officially an Unknown Soldier now
		self.ex_isdupname = false;
	}
}

handleUnknown(skipwarning)
{
	self endon("kill_thread");
	self endon("ex_freefall");

	// Tag the player to prevent the Name Checker to kick in more than once
	self.ex_isunknown = true;

	usname = [];

	if(!skipwarning)
	{
		if(isPlayer(self))
		{
			// Warn them first
			if(level.ex_usclanguest)
			{
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_UNACCEPTABLE", [[level.ex_pname]](self));
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CHANGEIT");
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CLANGUEST", level.ex_uswarndelay1);
			}
			else
			{
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_UNACCEPTABLE", [[level.ex_pname]](self));
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CHANGEIT");
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_GUEST", level.ex_uswarndelay1);
			}
		}
		// Now give them some time to change their name
		waitWhileUnknown(level.ex_uswarndelay1);
	}

	if(isPlayer(self) && isUnknown(self))
	{
		// Get a free guest number (1 to maxclients)
		level.ex_usguestno = getFreeGuestSlot();

		if(level.ex_usclanguest)
		{
			usname = level.ex_usclanguestname + level.ex_usguestno; // Clan Guest
			self setClientCvar("name", usname);
			wait( [[level.ex_fpstime]](1) );
			if(isPlayer(self))
			{
				self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_BYSERVER");
				self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_CLANGUEST", [[level.ex_pname]](self));
			}

			// Clan guests are now off the hook; show welcome messages and return
			self.ex_isunknown = false;
			wait( [[level.ex_fpstime]](3) );
			if(isPlayer(self)) self thread extreme\_ex_messages::welcomemsg();
			return;
		}
		else
		{
			// Only assign guest name if not already using an assigned guest name
			if(!isAssignedName(self))
			{
				usname = level.ex_usguestname + level.ex_usguestno; // Non-clan Guest
				self setClientCvar("name", usname);
				wait( [[level.ex_fpstime]](1) );
				if(isPlayer(self))
				{
					self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_BYSERVER");
					self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_GUEST", [[level.ex_pname]](self));
					self iprintlnbold(&"UNKNOWNSOLDIER_NEWNAME_CHANGEIT", level.ex_uswarndelay2);
				}

				// After name assignment, non-clan guests get a second chance to change their name
				waitWhileUnknown(level.ex_uswarndelay2);
			}
		}
	}

	if(isPlayer(self) && isUnknown(self))
	{
		// My god, don't they understand? ok, time for punishment!
		count = 0;
		while(isPlayer(self) && isUnknown(self) && count < level.ex_uspunishcount)
		{
			if(!isDefined(self.ex_sinbin) || !self.ex_sinbin)
			{
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_TEMPORARY", [[level.ex_pname]](self));
				self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CHANGEIT");
				self iprintlnbold(&"UNKNOWNSOLDIER_STILL_PUNISH");
				self thread extreme\_ex_utils::punishment("drop", "freeze");
				waitWhileUnknown(10);
				if(isPlayer(self)) self thread extreme\_ex_utils::punishment("enable", "release");
				waitWhileUnknown(20 + randomInt(20));
				count++;
			}
			else break;
		}

		// Now, if still using assigned name, allow them to play without punishment until they die
		if(isPlayer(self) && isAssignedName(self))
		{
			// Set punished-tag so Name Checker doesn't kick in again
			self.ex_ispunished = true;
			self iprintlnbold(&"UNKNOWNSOLDIER_STILL_RELIEF1");
			self iprintlnbold(&"UNKNOWNSOLDIER_STILL_RELIEF2");
			self iprintlnbold(&"UNKNOWNSOLDIER_MSG_CHANGEIT");
		}
	}

	// Allow the Name Checker to iterate once to catch duplicate names.
	// Keep this wait statement outside the following if-block to catch players
	// that would otherwise fall through by quickly changing their name from US
	// to a valid name and back to US again (highly unlikely, but possible with key bindings)
	wait( [[level.ex_fpstime]](5) );

	if(isPlayer(self) && !self.ex_ispunished && !isUnknown(self))
	{
		// Has the Name Checker tagged him because of using a duplicate name?
		if(isPlayer(self) && !self.ex_isdupname)
		{
			// No, so thank them, and show the welcome messages
			self iprintlnbold(&"UNKNOWNSOLDIER_MSG_THANKS", [[level.ex_pname]](self));
			wait( [[level.ex_fpstime]](3) );
			if(isPlayer(self)) self thread extreme\_ex_messages::welcomemsg();
		}
		else self thread handleDupName();
	}

	// Remove the tag; the player is either renamed, punished or dupname-tagged
	self.ex_isunknown = false;
}

waitWhileUnknown(seconds)
{
	// Wait for x seconds as long as player has unacceptable name
	for(i = 0; i < seconds; i++)
	{
		if(isPlayer(self) && !isUnknown(self)) return;
			else wait( [[level.ex_fpstime]](1) );
	}
}

isUnknownSoldier(player)
{
	self endon("kill_thread");

	// Check if player is Unknown Soldier
	// Color codes are removed. Name is lowercased, so it will reject any case combination
	playernorm = "";
	if(isPlayer(player)) playernorm = extreme\_ex_utils::monotone(player.name);
	playernorm = tolower(playernorm);

	if(playernorm == "" || playernorm == "unknown soldier" || playernorm == "unknownsoldier") return true;
	return false;
}

isAssignedName(player)
{
	self endon("kill_thread");

	// Check if player has an assigned guest name
	// Do NOT check for assigned clan guest names!
	for(i = 1; i <= level.ex_maxclients; i++)
	{
		chkname = level.ex_usguestname + i;
		if(player.name == chkname) return true;
	}
	return false;
}

isUnknown(player)
{
	self endon("kill_thread");

	// Check if player has unacceptable name
	if(isUnknownSoldier(player)) return true;
	if(isAssignedName(player)) return true;
	return false;
}

getFreeGuestSlot()
{
	self endon("kill_thread");

	// Get a free guest number.
	players = level.players;

	if(level.ex_usclanguest) usname = level.ex_usclanguestname;
		else usname = level.ex_usguestname;

	i = 1;
	while(i <= level.ex_maxclients)
	{
		chkname = usname + i;
		found = false;
		for(j = 0; j < players.size; j++)
		{
			if(players[j].name == chkname)
			{
				found = true;
				break;
			}
		}
		if(found) i++;
			else break;
	}
	return i;
}
