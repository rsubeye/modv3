#include extreme\_ex_hudcontroller;

main()
{
	level endon("round_ended");
	self endon("kill_thread");

	campingtime = 0;
	snipercampingtime = 0;
	warnedforcamping = false;
	camppos = self.origin;

	while(isPlayer(self) && isAlive(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](0.5) );

		// skip camper check if meeting these conditions
		if(self.ex_isunknown || self.ex_iscamper || self.ex_sinbin || self.ex_inmenu) continue;

		// flag carrier is allowed to hide
		if(isDefined(self.flagAttached)) continue;

		// loop if player is in jail (LIB)
		if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail) continue;

		// prevent punishment while being frozen in freezetag
		if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") continue;

		// skip camper check if bomb planted on S&D
		//if(level.ex_currentgt == "sd" && level.bombplanted) continue;

		startpos = self.origin;
		wait( [[level.ex_fpstime]](0.5) );
		endpos = self.origin;

		if(extreme\_ex_weapons::isWeaponType(self getcurrentweapon(), "sniper"))
		{
			if(level.ex_campsniper_warntime)
			{
				if(warnedforcamping)
				{
					if(distance(startpos, camppos) < level.ex_campsniper_radius && !self.ex_sinbin) snipercampingtime++;
					else
					{
						snipercampingtime = 0;
						warnedforcamping = false;
					}
				}
				else
				{
					if(distance(startpos, endpos) < 20 && !self.ex_sinbin) snipercampingtime++;
						else snipercampingtime = 0;
				}

				// show them a warning message
				if(snipercampingtime == level.ex_campsniper_warntime && !self.ex_isunknown)
				{
					self iprintlnbold(&"CAMPING_WARNING_MESSAGE_SELF", [[level.ex_pname]](self));
					warnedforcamping = true;
					camppos = self.origin;
				}
			}
			else continue;
		}
		else
		{
			if(level.ex_campwarntime)
			{
				if(warnedforcamping)
				{
					if(distance(startpos, camppos) < level.ex_campradius && !self.ex_sinbin) campingtime++;
					else
					{
						campingtime = 0;
						warnedforcamping = false;
					}
				}
				else
				{
					if(distance(startpos, endpos) < 25 && !self.ex_sinbin) campingtime++;
						else campingtime = 0;
				}

				// show them a warning message
				if(campingtime == level.ex_campwarntime && !self.ex_isunknown)
				{
					self iprintlnbold(&"CAMPING_WARNING_MESSAGE_SELF", [[level.ex_pname]](self));
					warnedforcamping = true;
					camppos = self.origin;
				}
			}
			else continue;
		}

		// make sure not to handle campers who are taken care of by Unknown Soldier handler
		if(self.ex_isunknown) continue;

		// ok, they didn't listen, punish them!
		if( (level.ex_campwarntime && campingtime >= level.ex_campobjtime) || (level.ex_campsniper_warntime && snipercampingtime >= level.ex_campsniper_objtime) )
		{
			switch(level.ex_camppunish)
			{
				case 1:	self thread markTheCamper(); break;
				case 2:	self thread blowTheCamper(); break;
				case 3:	self thread shellshockPlayer(false); break;
				case 4:	self thread shellshockPlayer(true); break;
				default:
				{
					switch(randomInt(4) + 1)
					{
						case 2:	self thread blowTheCamper(); break;
						case 3:	self thread shellshockPlayer(false); break;
						case 4:	self thread shellshockPlayer(true); break;
						default: self thread markTheCamper(); break;
					}
				}
			}

			campingtime = 0;
			snipercampingtime = 0;
			warnedforcamping = false;
		}
	}
}

markTheCamper()
{
	level endon("round_ended");
	self endon("kill_thread");
	self endon("stopcamper");

	if(self.ex_iscamper || (isDefined(level.roundended) && level.roundended) || self.sessionstate != "playing") return;
 
	self removeCamper();
	self.ex_objnum = levelHudGetObjective();

	if(self.ex_objnum)
	{
		self.ex_iscamper = true;

		// notify player and players
		self iprintlnbold(&"CAMPING_MARKED_MESSAGE_SELF", [[level.ex_pname]](self));
		self iprintlnbold(&"CAMPING_TIME_MESSAGE_SELF", level.ex_camptimer);
		iprintln(&"CAMPING_MARKED_MESSAGE_ALL", [[level.ex_pname]](self));
		iprintln(&"CAMPING_TIME_MESSAGE_ALL", level.ex_camptimer);

		compass_team = "none";
		if(self.pers["team"] == "allies") compass_icon = game["hudicon_allies"];
			else compass_icon = game["hudicon_axis"];

		objective_add(self.ex_objnum, "current", self.origin, compass_icon);
		objective_team(self.ex_objnum, compass_team);

		if(level.ex_camptimer >= 1) self thread countCamper();
	
		while(isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator")
		{
			for(i = 0; (i < 60 && isPlayer(self) && isAlive(self)); i++)
			{
				if((i <= 29) && self.ex_iscamper) objective_icon(self.ex_objnum, "objpoint_radio");
					else if((i >= 30) && self.ex_iscamper) objective_icon(self.ex_objnum, compass_icon);

				if(self.ex_iscamper) objective_position(self.ex_objnum, self.origin);

				wait( [[level.ex_fpstime]](0.05) );
			}
		}
	}
}

blowTheCamper()
{
	level endon("round_ended");
	self endon("kill_thread");

	if(self.ex_iscamper || (isDefined(level.roundended) && level.roundended) || self.sessionstate != "playing") return;

	self.ex_iscamper = true;
	
	self iprintlnbold(&"CAMPING_BLOWN_MESSAGE_SELF", [[level.ex_pname]](self));
	iprintln(&"CAMPING_BLOWN_MESSAGE_ALL", [[level.ex_pname]](self));
	wait( [[level.ex_fpstime]](1.5) );
	
	playfx(level.ex_effect["barrel"], self.origin);
	self playsound("mortar_explosion1");
	wait( [[level.ex_fpstime]](0.05) );

	self.ex_forcedsuicide = true;
	self suicide();
}

shellshockPlayer(diswep)
{
	level endon("round_ended");
	self endon("kill_thread");
	self endon("stopcamper");

	if(!isDefined(diswep)) diswep = false;

	if(self.ex_iscamper || (isDefined(level.roundended) && level.roundended) || self.sessionstate != "playing") return;
 
	self.ex_iscamper = true;
	time = undefined;

	// notify player and players
	self iprintlnbold(&"CAMPING_SHOCK_MESSAGE_SELF", [[level.ex_pname]](self));
	self iprintlnbold(&"CAMPING_TIME_MESSAGE_SELF", level.ex_camptimer);
	iprintln(&"CAMPING_SHOCK_MESSAGE_ALL", [[level.ex_pname]](self));
	iprintln(&"CAMPING_TIME_MESSAGE_ALL", level.ex_camptimer);
	self thread countCamper();

	while(isPlayer(self) && isAlive(self) && self.pers["team"] != "spectator" && self.ex_iscamper)
	{
		time = randomInt(5) + 5;
		if(isPlayer(self))
		{
			self shellshock("medical", time);
			if(diswep) self thread extreme\_ex_weapons::dropCurrentWeapon();
		}

		wait( [[level.ex_fpstime]](time + randomInt(5)) );
	}
}

countCamper()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](level.ex_camptimer - 1) );

	if(isPlayer(self))
	{
		self.ex_iscamper = false;
		if(isDefined(self.ex_objnum)) self removeCamper();
		self notify("stopcamper");
		self iprintlnbold(&"CAMPING_SURVIVED_MESSAGE_SELF", [[level.ex_pname]](self));
		iprintln(&"CAMPING_SURVIVED_MESSAGE_ALL", [[level.ex_pname]](self));
	}
}

removeCampers()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(players[i]) && isDefined(players[i].ex_objnum))
			players[i] removeCamper();
	}
}

removeCamper()
{
	self endon("disconnect");

	if(isDefined(self.ex_objnum))
	{
		levelHudFreeObjective(self.ex_objnum);
		self.ex_objnum = undefined;
	}
}
