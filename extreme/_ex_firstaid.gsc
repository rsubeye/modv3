#include extreme\_ex_hudcontroller;

main()
{
	self endon("kill_thread");

	//  frag 20x20:
	//		icon(-42, -75), "right", "bottom", "left", "top"
	//		ammo(-20, -57), "right", "bottom", "left", "bottom"
	// smoke 20x20:
	//		icon(-42,-100), "right", "bottom", "left", "top"
	//		ammo(-20, -82), "right", "bottom", "left", "bottom"
	//  medi 20x20
	//		icon(-42,-125), "right", "bottom", "left", "top"
	//		ammo(-20,-107), "right", "bottom", "left", "bottom"
	//  mine 20x20
	//		icon(-42,-150), "right", "bottom", "left", "top"
	//		ammo(-20,-132), "right", "bottom", "left", "bottom"

	iconY = -125;
	ammoY = iconY + 18;

	if(self.ex_firstaidkits == 0) kits_color = (1, 0, 0);
		else kits_color = (1, 1, 1);

	// HUD firstaid icon
	hud_index = playerHudIndex("firstaid_icon");
	if(hud_index == -1) hud_index = playerHudCreate("firstaid_icon", -42, iconY, 1, (1,1,1), 1, 0, "right", "bottom", "left", "top", false, true);
	if(hud_index != -1) playerHudSetShader(hud_index, game["firstaidicon"], 20, 20);

	// HUD firstaid kits
	hud_index = playerHudIndex("firstaid_kits");
	if(hud_index == -1) hud_index = playerHudCreate("firstaid_kits", -20, ammoY, 1, kits_color, 1, 0, "right", "bottom", "left", "bottom", false, true);
	if(hud_index != -1) playerHudSetValue(hud_index, self.ex_firstaidkits);

	// check if player is allowed to heal, if healing is revoked don't allow them to heal
	self.ex_canheal = false;
	if(isDefined(self.ex_blockhealing))
	{
		playerHudSetAlpha("firstaid_icon", 0);
		playerHudSetAlpha("firstaid_kits", 0);
	}
	else if(self.ex_firstaidkits) self.ex_canheal = true;

	self.ex_targetplayer = undefined;

	while(isPlayer(self) && self.sessionstate != "spectator")
	{
		wait( [[level.ex_fpstime]](0.5) );

		if(isPlayer(self) && self.ex_canheal && self useButtonPressed() && self isOnGround())
		{
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				if(players[i] == self && !level.ex_medic_self) continue; // not allowed to heal yourself
				if(players[i].sessionstate == "dead" || players[i].sessionstate == "spectator") continue; // not playing
				if(level.ex_teamplay && players[i].pers["team"] != self.pers["team"]) continue; // not a teammate

				if(players[i].health <= 80 && // must be injured
					!isDefined(players[i].gettingfirstaid) && // and not currently being treated
					distance(players[i].origin, self.origin) < 48) // and within 4 feet of player
				{
					if(!level.ex_teamplay)
					{
						if(players[i] == self)
						{
							self.ex_targetplayer = players[i];
							break;
						}
					}
					else
					{
						self.ex_targetplayer = players[i];
						break;
					}					
				}
			}

			// not in range of any friendlies that need healing
			if(!isDefined(self.ex_targetplayer)) continue;

			// all systems go, commence healing
			// make sure they mean it, are holding USE for half a second
			holdtime = 0;

			while(isalive(self) && isalive(self.ex_targetplayer) // both still alive
				&& self useButtonPressed() && holdtime < 0.5
				&& self isOnGround() && self.ex_targetplayer isOnGround()
				&& distance(self.ex_targetplayer.origin, self.origin) < 48)
			{
				holdtime += 0.05;
				wait( [[level.ex_fpstime]](0.05) );
			}

			if(holdtime < 0.5) continue;

			if(isPlayer(self))
			{
				// can't heal while defusing a bomb	
				if(isDefined(self.defuseicon)) continue;
	
				// can't heal while moving
				if(isDefined(self.ex_moving) && self.ex_moving) continue;
	
				// can't heal if calling in mortars, artillery or an airstrike
				if(self.ex_binocuse) continue;
	
				// can't heal if target players health is 100%
				if(self.ex_targetplayer.health == 100) continue;
	
				// can't heal near ammo crates
				if(isDefined(self.ex_amc_check)) continue;
	
				// stop them flashing on compass as needing medic
				self.ex_targetplayer.needshealing = false;
		
				healamount = (level.ex_medic_minheal + randomInt(level.ex_medic_maxheal - level.ex_medic_minheal));
				healtime = int(healamount / 2) * .1;
				
				self playlocalsound("medi_bag");
				self.ex_targetplayer shellshock("medical", 4);
				self [[level.ex_dWeapon]]();
	
				// fade counter
				hud_index = playerHudIndex("firstaid_kits");
				if(hud_index != -1) playerHudFade(hud_index, 1, 0, 0);

				hud_index = playerHudIndex("firstaid_icon");
				if(hud_index != -1) playerHudScale(hud_index, 1, 0, 28, 28);

				healnow = 0;
				holdtime = 0;
				beepcount = 0;
				sprintcount = 0;
	
				while(isAlive(self) && isAlive(self.ex_targetplayer) // both still alive
					&& self useButtonPressed() // still holding the USE key
					&& !(self meleeButtonPressed()) // player hasn't melee'd
					&& !(self.ex_targetplayer meleeButtonPressed()) // target hasn't melee'd
					&& !(self attackButtonPressed()) // player hasn't fired
					&& !(self.ex_targetplayer attackButtonPressed()) // target hasn't fired
					&& self.ex_targetplayer.health < 100 // hasn't filled target's health
					&& healamount > 0) // hasn't run out of healamount
				{
					if(healnow == 1)
					{
						self.ex_targetplayer.health++; // 10 health per second, 1 point every other 1/20th of a second (server frame) had to do that 'cause of integer rounding issues
						healamount--;
						healnow = -1;
	
						self.ex_ishealing = true;
					}
	
					healnow++;
					beepcount++;
					sprintcount++;
					holdtime += 0.05;
					wait( [[level.ex_fpstime]](0.05) );
	
					// still recovering from sprint
					if(level.ex_sprint && sprintcount > 1)
					{
						if(self.ex_sprinttime < level.ex_sprinttime)
							self.ex_sprinttime++;
						
						sprintcount = 0;
					}

					if(beepcount > 20)
					{
						if(self.health > 70)
						{
							self playlocalsound("medi_use_high");
							beepcount = 0;
						}
						else
						{
							self playlocalsound("medi_use_low");
							beepcount = 0;
						}
					}
				}
	
				if(isDefined(self.ex_ishealing)) self.ex_ishealing = undefined;
	
				if(isPlayer(self.ex_targetplayer)) self.ex_targetplayer playsound("sprintover");
	
				if(isAlive(self) && isAlive(self.ex_targetplayer) && (healamount == 0 || self.ex_targetplayer.health == 100))
				{
					if(self.ex_targetplayer == self)
					{
						iprintln(&"FIRSTAID_APPLIED_SELF", [[level.ex_pname]](self));
						self playSound("health_pickup_medium");
					}
					else
					{
						iprintln(&"FIRSTAID_APPLIED_TEAM_MSG1", [[level.ex_pname]](self.ex_targetplayer));
						iprintln(&"FIRSTAID_APPLIED_TEAM_MSG2", [[level.ex_pname]](self));
						self playSound("health_pickup_medium");
						self thread [[level.pscoreproc]](1, "bonus");
					}
				}
	
				hud_index = playerHudIndex("firstaid_icon");
				if(hud_index != -1) playerHudScale(hud_index, 1, 0, 20, 20);
	
				self.ex_firstaidkits--;
				self [[level.ex_eWeapon]]();
	
				hud_index = playerHudIndex("firstaid_kits");
				if(hud_index != -1)
				{
					playerHudSetValue(hud_index, self.ex_firstaidkits);
					if(self.ex_firstaidkits == 0) kits_color = (1, 0, 0);
						else kits_color = (1, 1, 1);
					playerHudSetColor(hud_index, kits_color);
					playerHudFade(hud_index, 1, 0, 1);
				}
	
				wait( [[level.ex_fpstime]](0.5) );

				if(isPlayer(self))
				{				
					if(self.ex_firstaidkits == 0) self.ex_canheal = false;
		
					if(level.ex_firstaid_kits_msg)
					{
						if(self.ex_firstaidkits >= 2) self iprintlnbold(&"FIRSTAID_YOU_HAVE_NUMBER_LEFT", self.ex_firstaidkits);
							else if(self.ex_firstaidkits == 1) self iprintlnbold(&"FIRSTAID_ONE_KIT_LEFT");
								else if(self.ex_firstaidkits == 0) self iprintlnbold(&"FIRSTAID_NO_KIT_LEFT");
					}
	
					// Remove bulletholes if present
					if(level.ex_bulletholes && isAlive(self.ex_targetplayer) && self.ex_targetplayer.health == 100)
						self.ex_targetplayer thread extreme\_ex_bulletholes::removeAllHoles();
				}
			}
		}
	}
}

disablePlayerHealing()
{
	self endon("kill_thread");

	self.ex_blockhealing = true;
	self.ex_canheal = false;

	msg1 = &"FIRSTAID_DISABLED";
	msg2 = extreme\_ex_utils::time_convert(level.ex_medic_penalty);

	switch(level.ex_medic_penalty_msg)
	{
		case 0:
			self iprintln(msg1);
			self iprintln(msg2);
			break;
		default:
			self iprintlnbold(msg1);
			self iprintlnbold(msg2);
			break;
	}

	hud_index = playerHudIndex("firstaid_icon");
	if(hud_index != -1) playerHudSetAlpha(hud_index, 0);

	hud_index = playerHudIndex("firstaid_kits");
	if(hud_index != -1) playerHudSetAlpha(hud_index, 0);

	level thread watchPlayerHealing(self, level.ex_medic_penalty);
}

enablePlayerHealing()
{
	if(self.sessionstate == "playing")
	{
		hud_index = playerHudIndex("firstaid_icon");
		if(hud_index != -1) playerHudSetAlpha(hud_index, 1);

		hud_index = playerHudIndex("firstaid_kits");
		if(hud_index != -1)
		{
			playerHudSetValue(hud_index, self.ex_firstaidkits);
			if(self.ex_firstaidkits == 0) kits_color = (1, 0, 0);
				else kits_color = (1, 1, 1);
			playerHudSetColor(hud_index, kits_color);
			playerHudSetAlpha(hud_index, 1);
		}
	}

	self.ex_canheal = true;
	self.ex_blockhealing = undefined;
}

watchPlayerHealing(player, seconds)
{
	level endon("gameover");
	player endon("disconnect");

	wait( [[level.ex_fpstime]](seconds) );
	if(isPlayer(player)) player enablePlayerHealing();
}

callformedic()
{
	self endon("kill_thread");

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator") return;

	soundalias = undefined;

	if(level.ex_medicsystem)
	{
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
				case "american":
				soundalias = "american_medic";
				break;
				
				case "british":
				soundalias = "british_medic";
				break;
		
				default:
				soundalias = "russian_medic";
				break;
			}
		}
		else if(self.pers["team"] == "axis")
		{
			switch(game["axis"])
			{
				case "german":
				soundalias = "german_medic";
				break;
			}
		}
	}

	self thread maps\mp\gametypes\_quickmessages::doQuickMessage(soundalias, &"FIRSTAID_MEDIC_CALL", false);

	if(isPlayer(self) && level.ex_medic_showinjured)
	{
		self.needshealing = true;
		self thread ShowInjured();
	}
}

ShowInjured()
{
	self endon("kill_thread");

	while(isalive(self) && self.needshealing && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](level.ex_medic_showinjured_time) );
		self pingPlayer();
	}
}
