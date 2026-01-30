#include extreme\_ex_weapons;
#include extreme\_ex_hudcontroller;

main()
{
	self endon("kill_thread");

	count = 0;
	beepcount = 0;
	exit_ads = false;
	exit_nadeuse = false;
	exit_attackuse = false;
	exit_meleeuse = false;
	exit_range = false;
	spos = self.origin;
	sdist = int(level.ex_spwn_range / 12);

	self.ex_invulnerable = true;
	self.ex_spawnprotected = true;

	if(level.ex_spwn_headicon) playerHudSetHeadIcon(game["headicon_protect"], "none");

	if(level.ex_spwn_hud)
	{
		hud_index = playerHudCreate("spawnprot_icon", 120, 390, level.ex_iconalpha, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
		if(hud_index != -1)
		{
			playerHudSetShader(hud_index, game["mod_protect_hudicon"], 32, 32);
			playerHudScale(hud_index, 0.5, 0, 24, 24);
		}

		if(level.ex_spwn_hud == 2)
		{
			hud_index = playerHudCreate("spawnprot_time", 140, 375, 1, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
			if(hud_index != -1)
			{
				playerHudSetLabel(hud_index, &"SPAWNPROTECTION_TIME");
				playerHudSetValue(hud_index, level.ex_spwn_time);
			}

			hud_index = playerHudCreate("spawnprot_timeleft", 140, 385, 1, (0,1,0), 1, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
			if(hud_index != -1) playerHudSetValue(hud_index, level.ex_spwn_time);

			if(level.ex_spwn_range)
			{
				hud_index = playerHudCreate("spawnprot_range", 140, 400, 0.8, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
				if(hud_index != -1)
				{
					playerHudSetLabel(hud_index, &"SPAWNPROTECTION_RANGE");
					playerHudSetValue(hud_index, sdist);
				}

				hud_index = playerHudCreate("spawnprot_rangeleft", 140, 410, 1, (0,1,0), 1, 0, "fullscreen", "fullscreen", "left", "middle", false, true);
				if(hud_index != -1) playerHudSetValue(hud_index, sdist);
			}
		}
	}

	if(level.ex_spwn_msg)
	{
		if(level.ex_spwn_invisible) msg1 = &"SPAWNPROTECTION_ENABLED_INVISIBLE";
			else msg1 = &"SPAWNPROTECTION_ENABLED";
		msg2 = extreme\_ex_utils::time_convert(level.ex_spwn_time);

		switch(level.ex_spwn_msg)
		{
			case 1:
				self iprintln(msg1);
				self iprintln(msg2);
				break;
			default:
				self iprintlnbold(msg1);
				self iprintlnbold(msg2);
				break;
		}
	}

	if(level.ex_spwn_wepdisable) self [[level.ex_dWeapon]]();

	// invisible Spawn Protection ON
	// WARNING: also part of pre-spawn settings in ex_main::exPreSpawn()
	if(level.ex_spwn_invisible) self hide();

	while(isAlive(self) && self.sessionstate == "playing" && self.ex_invulnerable)
	{
		if(count >= level.ex_spwn_time) break;

		currweapon = self getCurrentWeapon();
		if( (!isDefined(self.ex_disabledWeapon) || !self.ex_disabledWeapon) && isValidWeapon(currweapon) && !isDummy(currweapon))
		{
			if(self playerAds())
			{
				exit_ads = true;
				break;
			}
			if(self.usedweapons)
			{
				exit_nadeuse = true;
				break;
			}
			if(self attackButtonPressed())
			{
				exit_attackuse = true;
				break;
			}
			if(self meleeButtonPressed())
			{
				exit_meleeuse = true;
				break;
			}
		}

		if(level.ex_spwn_range && !isDefined(self.ex_isparachuting))
		{
			distmoved = distance(spos, self.origin);
			if(level.ex_spwn_hud == 2)
			{
				sdist = level.ex_spwn_range - distmoved;
				sdistperc = 1 - (sdist / level.ex_spwn_range);
				playerHudSetValue("spawnprot_rangeleft", int(sdist / 12));
				playerHudSetColor("spawnprot_rangeleft", (sdistperc, 1 - sdistperc, 0));
			}
			if(distmoved > level.ex_spwn_range)
			{
				exit_range = true;
				break;
			}
		}

		wait( [[level.ex_fpstime]](0.05) );

		beepcount++;
		if(beepcount == 20)
		{
			if((level.ex_parachutes && !level.ex_parachutesprotection) || !isDefined(self.ex_isparachuting))
			{
				count++;
				if(level.ex_spwn_hud == 2)
				{
					playerHudSetValue("spawnprot_timeleft", level.ex_spwn_time - count);
					if(level.ex_spwn_time <= 3 || (count >= level.ex_spwn_time - 3) ) playerHudSetColor("spawnprot_timeleft", (1,0,0));
				}
			}
			beepcount = 0;
		}
	}

	if(level.ex_spwn_msg)
	{
		msg3 = undefined;
		if(exit_ads) msg3 = &"SPAWNPROTECTION_TOOK_AIM";
		if(exit_attackuse || exit_meleeuse) msg3 = &"SPAWNPROTECTION_FIRE_BUTTON_PRESSED";
		if(self.sessionstate == "playing" && exit_range) msg3 = &"SPAWNPROTECTION_MOVED_AWAY_AREA";
		msg4 = &"SPAWNPROTECTION_DISABLED";

		switch(level.ex_spwn_msg)
		{
			case 1:
				if(isDefined(msg3)) self iprintln(msg3);
				self iprintln(msg4);
				break;
			default:
				if(isDefined(msg3)) self iprintlnbold(msg3);
				self iprintlnbold(msg4);
				break;
		}
	}

	// restore the headicon if changed
	if(level.ex_spwn_headicon && self.sessionstate == "playing") playerHudRestoreHeadIcon();

	playerHudDestroy("spawnprot_icon");
	playerHudDestroy("spawnprot_time");
	playerHudDestroy("spawnprot_timeleft");
	playerHudDestroy("spawnprot_range");
	playerHudDestroy("spawnprot_rangeleft");

	// invisible Spawn Protection OFF
	if(level.ex_spwn_invisible) self show();

	if(level.ex_spwn_wepdisable) self [[level.ex_eWeapon]]();
	self.ex_spawnprotected = undefined;
	self.ex_invulnerable = false;
}

punish(reason)
{
	self endon("kill_thread");

	if(isDefined(self.ex_spwn_punish)) return;
	self.ex_spwn_punish = true;

	// spawn protection punishment threshold reset
	if(level.ex_spwn_punish_threshold) self.ex_spwn_punish_counter = 0;

	if(isPlayer(self))
	{
		if(reason == "abusing")
		{
			iprintln(&"SPAWNPROTECTION_PUNISH_ABUSER_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"SPAWNPROTECTION_PUNISH_ABUSER_PMSG");
		}

		if(reason == "attacking" || reason == "turretattack")
		{
			iprintln(&"SPAWNPROTECTION_PUNISH_ATTACKER_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"SPAWNPROTECTION_PUNISH_ATTACKER_PMSG");
		}
	}

	if(reason == "turretattack")
	{
		if(isPlayer(self)) self thread extreme\_ex_utils::execClientCommand("-attack; +activate; wait 10; -activate");
	}
	else
	{
		pun = randomInt(100);

		if(pun < 50)
		{
			if(isPlayer(self)) self [[level.ex_dWeapon]]();
			wait( [[level.ex_fpstime]](2) );
		}
		else for(i = 0; i < 2; i++)
		{
			if(isPlayer(self)) self extreme\_ex_weapons::dropcurrentweapon();
			wait( [[level.ex_fpstime]](1) );
		}

		if(isPlayer(self))
		{
			if(reason == "abusing") self iprintlnbold(&"SPAWNPROTECTION_FREE_ABUSER_PMSG");
			else if(reason == "attacking") self iprintlnbold(&"SPAWNPROTECTION_FREE_ATTACKER_PMSG");

			self [[level.ex_eWeapon]]();
			self.ex_spwn_punish = undefined;
		}
	}
}
