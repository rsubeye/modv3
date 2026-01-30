#include extreme\_ex_hudcontroller;

init()
{
	if(level.ex_motdrotate) [[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);

	if(level.ex_svrmsg)
	{
		level.ex_servermessages = [];
		level.ex_servermessages[0] = &"CUSTOM_SERVER_MESSAGE_1";
		level.ex_servermessages[1] = &"CUSTOM_SERVER_MESSAGE_2";
		level.ex_servermessages[2] = &"CUSTOM_SERVER_MESSAGE_3";
		level.ex_servermessages[3] = &"CUSTOM_SERVER_MESSAGE_4";
		level.ex_servermessages[4] = &"CUSTOM_SERVER_MESSAGE_5";
		level.ex_servermessages[5] = &"CUSTOM_SERVER_MESSAGE_6";
		level.ex_servermessages[6] = &"CUSTOM_SERVER_MESSAGE_7";
		level.ex_servermessages[7] = &"CUSTOM_SERVER_MESSAGE_8";
		level.ex_servermessages[8] = &"CUSTOM_SERVER_MESSAGE_9";
		level.ex_servermessages[9] = &"CUSTOM_SERVER_MESSAGE_10";
		level.ex_servermessages[10] = &"CUSTOM_SERVER_MESSAGE_11";
		level.ex_servermessages[11] = &"CUSTOM_SERVER_MESSAGE_12";
		level.ex_servermessages[12] = &"CUSTOM_SERVER_MESSAGE_13";
		level.ex_servermessages[13] = &"CUSTOM_SERVER_MESSAGE_14";
		level.ex_servermessages[14] = &"CUSTOM_SERVER_MESSAGE_15";
		level.ex_servermessages[15] = &"CUSTOM_SERVER_MESSAGE_16";
		level.ex_servermessages[16] = &"CUSTOM_SERVER_MESSAGE_17";
		level.ex_servermessages[17] = &"CUSTOM_SERVER_MESSAGE_18";
		level.ex_servermessages[18] = &"CUSTOM_SERVER_MESSAGE_19";
		level.ex_servermessages[19] = &"CUSTOM_SERVER_MESSAGE_20";

		if(level.ex_svrmsg_loop)
			[[level.ex_registerLevelEvent]]("onRandom", ::serverMessages, true, level.ex_svrmsg_delay_main, level.ex_svrmsg_delay_main, level.ex_svrmsg_delay_main / 2);
		else
			[[level.ex_registerLevelEvent]]("onRandom", ::serverMessages, true, level.ex_svrmsg_delay_main);
	}
}

onPlayerConnected()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("start_motd_rotation");
		self.ex_motd_rotate = 1;

		self thread motdStartRotation();

		self waittill("stop_motd_rotation");
		self.ex_motd_rotate = 0;
	}
}

motdStartRotation()
{
	level endon("ex_gameover");
	self endon("disconnect");
	self endon("stop_motd_rotation");

	while(self.ex_motd_rotate)
	{
		for(i = 0; i < level.rotmotd.size; i++)
		{
			msg = level.rotmotd[i];
			self setClientCvar("ui_motd", msg);
			wait( [[level.ex_fpstime]](level.ex_motdrotdelay) );
			if(level.ex_gameover) return;
		}
	}
}

welcomeMsg()
{
	self endon("kill_thread");

	if(isDefined(self.pers["welcdone"])) return;
	self.pers["welcdone"] = true;

	if(!level.ex_pwelcome) return;
		
	// welcome messages - default 1 to 10
	if(level.ex_pwelcome_all >= 1)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_1");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 2)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_2");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 3)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_3");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 4)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_4");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 5)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_5");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 6)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_6");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 7)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_7");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 8)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_8");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 9)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_9");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_pwelcome_all >= 10)
	{
		self thread playerHudAnnounce(&"CUSTOM_ALL_MESSAGE_10");
		wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
	}

	if(level.ex_clanwelcome && isDefined(self.ex_name))
	{
		switch(self.ex_clid)
		{
			// clan 1 messages
			case 1:
				if(level.ex_clmsg[1] >= 1)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN1_MESSAGE_1");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}

				if(level.ex_clmsg[1] >= 2)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN1_MESSAGE_2");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}

				if(level.ex_clmsg[1] >= 3)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN1_MESSAGE_3");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}
				break;

			// clan 2 messages
			case 2:
				if(level.ex_clmsg[2] >= 1)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN2_MESSAGE_1");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}

				if(level.ex_clmsg[2] >= 2)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN2_MESSAGE_2");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}

				if(level.ex_clmsg[2] >= 3)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN2_MESSAGE_3");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}
				break;

			// clan 3 messages
			case 3:
				if(level.ex_clmsg[3] >= 1)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN3_MESSAGE_1");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}

				if(level.ex_clmsg[3] >= 2)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN3_MESSAGE_2");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}

				if(level.ex_clmsg[3] >= 3)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN3_MESSAGE_3");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}
				break;

			// clan 4 messages
			case 4:
				if(level.ex_clmsg[4] >= 1)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN4_MESSAGE_1");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}

				if(level.ex_clmsg[4] >= 2)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN4_MESSAGE_2");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}

				if(level.ex_clmsg[4] >= 3)
				{
					self thread playerHudAnnounce(&"CUSTOM_CLAN4_MESSAGE_3");
					wait( [[level.ex_fpstime]](level.ex_clandelay) );
				}
				break;
		}
	}
	else
	{
		// welcome messages - custom 1 to 3
		if(level.ex_pwelcome_msg >= 1)
		{
			self thread playerHudAnnounce(&"CUSTOM_NONCLAN_MESSAGE_1");
			wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
		}

		if(level.ex_pwelcome_msg >= 2)
		{
			self thread playerHudAnnounce(&"CUSTOM_NONCLAN_MESSAGE_2");
			wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
		}

		if(level.ex_pwelcome_msg >= 3)
		{
			self thread playerHudAnnounce(&"CUSTOM_NONCLAN_MESSAGE_3");
			wait( [[level.ex_fpstime]](level.ex_pwelcome_delay) );
		}
	}

	// voting status
	if(getCvarInt("g_allowvote") == 1)
	{
		if(level.ex_clanvoting)
		{
			if(isDefined(self.ex_name) && level.ex_clvote[self.ex_clid]) self thread playerHudAnnounce(&"CUSTOM_VOTE_ALLOWED");
				else self thread playerHudAnnounce(&"CUSTOM_VOTE_NOT_ALLOWED");
		}
		else self thread playerHudAnnounce(&"CUSTOM_VOTE_ALLOWED");
	}
	else self thread playerHudAnnounce(&"CUSTOM_VOTE_NOT_ALLOWED");
}

goodluckMsg()
{
	self endon("kill_thread");

	if(!isDefined(self.pers["team"])) return;

	// if using the readyup system, no need to hear any intro sounds again
	if(level.ex_readyup && isDefined(game["readyup_done"])) return;

	// on round based games, no need to hear any intro sounds every round
	if(level.ex_roundbased && game["roundnumber"] > 1) return;

	stp = undefined;
	wait( [[level.ex_fpstime]](5) );

	if(isPlayer(self))
	{
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
				case "american":
				stp = "us_welcome";
				break;

				case "british":
				stp = "uk_welcome";
				break;

				case "russian":
				stp = "ru_welcome";
				break;
			}
		}
		else if(self.pers["team"] == "axis")
		{
			switch(game["axis"])
			{
				case "german":
				stp = "ge_welcome";
				break;
			}
		}

		if(isDefined(stp))
		{
			self playLocalSound(stp);
			self.ex_glplay = true;
		}
	}
}

serverMessages(eventID)
{
	level endon("ex_gameover");

	for(i = 0; i < level.ex_svrmsg; i++)
	{
		iprintln(level.ex_servermessages[i]);
		wait( [[level.ex_fpstime]](level.ex_svrmsg_delay_msg) );
	}
	
	if(level.ex_svrmsg_info >= 1) extreme\_ex_maps::DisplayMapRotation();

	if(level.ex_svrmsg_loop) [[level.ex_enableLevelEvent]]("onRandom", eventID);
}

spectatorMessages()
{
	level endon("ex_gameover");
	self endon("disconnect");
	self endon("spawned");

	specmsg = [];
	specmsg[0] = &"CUSTOM_SPECTATOR_MESSAGE_1";
	specmsg[1] = &"CUSTOM_SPECTATOR_MESSAGE_2";
	specmsg[2] = &"CUSTOM_SPECTATOR_MESSAGE_3";
	specmsg[3] = &"CUSTOM_SPECTATOR_MESSAGE_4";
	specmsg[4] = &"CUSTOM_SPECTATOR_MESSAGE_5";
	specmsg[5] = &"CUSTOM_SPECTATOR_MESSAGE_6";
	specmsg[6] = &"CUSTOM_SPECTATOR_MESSAGE_7";
	specmsg[7] = &"CUSTOM_SPECTATOR_MESSAGE_8";
	specmsg[8] = &"CUSTOM_SPECTATOR_MESSAGE_9";
	specmsg[9] = &"CUSTOM_SPECTATOR_MESSAGE_10";

	while(isPlayer(self) && self.pers["team"] == "spectator")
	{
		for(i = 0; i < level.ex_specmsg; i++)
		{
			self iprintln(specmsg[i]);
			wait( [[level.ex_fpstime]](level.ex_specmsg_delay_msg) );
		}

		wait( [[level.ex_fpstime]](level.ex_specmsg_delay_main / 2) );
	}
}
