#include extreme\_ex_hudcontroller;

init()
{
	level.kc_array = [];

	// lock slot 0 because kcAllocate should issue slot numbers above 0 (self.ex_confirmkill 0 means no KC)
	level.kc_array[0] = spawnstruct();
	level.kc_array[0].inuse = 1;

	// set an entity max to prevent overload
	level.kc_maxent = 64;
}

kcCheck(attacker, sMeansOfDeath, sWeapon)
{
	// check if this kill has to be confirmed
	if(level.ex_kc && isPlayer(attacker) && attacker != self && (!level.ex_teamplay || attacker.pers["team"] != self.pers["team"]))
	{
		switch(level.ex_kc_weapon)
		{
			// all weapons
			case 0:
				return(kcAllocate());
			// all weapons, except gunship
			case 1:
				if((level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == attacker) ||
				   (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == attacker)) return(0);
				return(kcAllocate());
			// all weapons, except gunship and snipers
			case 2:
				if((extreme\_ex_weapons::isWeaponType(sWeapon, "sniper") && sMeansOfDeath != "MOD_MELEE") ||
				  (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == attacker) ||
				  (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == attacker)) return(0);
				return(kcAllocate());
			// all main weapons (from weapon menus)
			case 3:
				if(maps\mp\gametypes\_weapons::isMainWeapon(sWeapon)) return(kcAllocate());
				return(0);
			// all main weapons, except snipers
			case 4:
				if(!maps\mp\gametypes\_weapons::isMainWeapon(sWeapon)) return(0);
				if(extreme\_ex_weapons::isWeaponType(sWeapon, "sniper") && sMeansOfDeath != "MOD_MELEE") return(0);
				return(kcAllocate());
		}
	}

	// no KC
	return(false);
}

kcAllocate()
{
	if(level.kc_array.size == level.kc_maxent) return(0);

	for(i = 0; i < level.kc_array.size; i++)
	{
		if(level.kc_array[i].inuse == 0)
		{
			level.kc_array[i].inuse = 1;
			kcStatsInit(i);
			return(i);
		}
	}

	level.kc_array[i] = spawnstruct();
	level.kc_array[i].inuse = 1;
	kcStatsInit(i);
	return(i);
}

kcStatsInit(index)
{
	level.kc_array[index].attacker_stats = [];
	level.kc_array[index].victim_stats = [];
}

kcStatsAttacker(index, stat)
{
	kc_record = level.kc_array[index];
	kc_record.attacker_stats[kc_record.attacker_stats.size] = stat;
}

kcStatsVictim(index, stat)
{
	kc_record = level.kc_array[index];
	kc_record.victim_stats[kc_record.victim_stats.size] = stat;
}

kcMain(regular_points, reward_points, isteamscore, attacker)
{
	index = self.ex_confirmkill;

	if(!regular_points && !reward_points)
	{
		// only handle statistics
		if(isPlayer(attacker))
		{
			attacker.pers["kill"]++;
			for(i = 0; i < level.kc_array[index].attacker_stats.size; i++)
				attacker.pers[level.kc_array[index].attacker_stats[i]]++;
		}
		if(isPlayer(self))
		{
			self.pers["death"]++;
			self.deaths = self.pers["death"];
			for(i = 0; i < level.kc_array[index].victim_stats.size; i++)
				self.pers[level.kc_array[index].victim_stats[i]]++;
		}

		kcFree(index);
		return;
	}

	level.kc_array[index].points = regular_points;
	level.kc_array[index].reward = reward_points;
	level.kc_array[index].isteamscore = isteamscore;
	level.kc_array[index].victim = self;
	level.kc_array[index].victim_team = self.pers["team"];
	level.kc_array[index].attacker = attacker;

	if(self.pers["team"] == "axis") model = game["dogtag_axis"];
		else model = game["dogtag_allies"];

	level.kc_array[index].dogtags = spawn("script_model", self.origin + (0,0,20));
	level.kc_array[index].dogtags hide();
	level.kc_array[index].dogtags setmodel(model);
	level.kc_array[index].dogtags.angles = (0, self.angles[1], 0);
	level.kc_array[index].trigger = spawn("trigger_radius", level.kc_array[index].dogtags.origin, 0, 20, 50);

	if(!level.ex_teamplay)
	{
		level.kc_array[index].dogtags showToPlayer(level.kc_array[index].victim);
		level.kc_array[index].dogtags showToPlayer(level.kc_array[index].attacker);
	}
	else level.kc_array[index].dogtags show();

	// play hint to get tags once
	if(isPlayer(attacker) && !isDefined(attacker.kc_gettags))
	{
		attacker.kc_gettags = true;
		attacker playLocalSound("kc_gettags");
	}

	// Start bounce and rotation
	level.kc_array[index].dogtags thread dogtagRotate();

	// Remove the trigger and dogtags if the dog tag expire
	level.kc_array[index].dogtags thread dogtagTimeoutMonitor(index, level.ex_kc_timeout);

	// Wait for another player to pickup the dogtags
	level.kc_array[index].dogtags thread dogtagPickupMonitor(index);
}

kcFree(index)
{
	if(!isDefined(level.kc_array[index])) return;
	if(isDefined(level.kc_array[index].trigger)) level.kc_array[index].trigger delete();
	if(isDefined(level.kc_array[index].dogtags)) level.kc_array[index].dogtags delete();
	level.kc_array[index].inuse = 0;
}

removeAllTags()
{
	for(i = 0; i < level.kc_array.size; i++)
	{
		if(level.kc_array[i].inuse)
		{
			if(isDefined(level.kc_array[i].dogtags))
			{
				level.kc_array[i].dogtags notify("kc_endtimeout");
				level.kc_array[i].dogtags notify("kc_endpickup");
			}
			kcFree(i);
		}
	}
}

dogtagRotate()
{
	self endon("kc_endtimeout");
	self endon("kc_endpickup");

	while(true)
	{
		self movez(20, 1.5, 0.3, 0.3);
		self rotateyaw(360, 1.5, 0, 0);
		wait( 1.5 );
		self movez(-20, 1.5, 0.3, 0.3);
		self rotateyaw(360 ,1.5, 0, 0);
		wait( 1.5 );
	}
}

dogtagTimeoutMonitor(index, timeout)
{
	self endon("kc_endtimeout");

	// Wait for this dog tag to timeout
	wait( [[level.ex_fpstime]](timeout) );

	// Notify trigger monitor to end
	self notify("kc_endpickup");

	// Delete trigger and model
	kcFree(index);
}

dogtagPickupMonitor(index)
{
	self endon("kc_endpickup");

	kc_record = level.kc_array[index];

	while(true)
	{
		kc_record.trigger waittill("trigger", player);

		// make sure that victim and attacker variables are valid entities
		if(!isPlayer(kc_record.victim)) kc_record.victim = self;
		if(!isPlayer(kc_record.attacker)) kc_record.attacker = self;

		// KILL DENIED (pickup by victim or teammates)
		if( (!level.ex_teamplay && player == kc_record.victim) || (level.ex_teamplay && player.pers["team"] == kc_record.victim_team) )
		{
			// if pickup by victim is disabled, deny pickup
			if(!level.ex_kc_denied) continue;

			// if only victim can collect, and you're not, deny pickup
			if((level.ex_kc_denied == 1 || level.ex_kc_denied == 2) && player != kc_record.victim) continue;

			// handle bonus points
			points_denied = kc_record.points + kc_record.reward;
			if(level.ex_kc_denied == 2 || level.ex_kc_denied == 5 || (level.ex_kc_denied == 4 && player == kc_record.victim))
			{
				player thread [[level.pscoreproc]](level.ex_kc_denied_bonus, "bonus");
				if(kc_record.isteamscore) thread [[level.tscoreproc]](player.pers["team"], level.ex_kc_denied_bonus);
			}

			// sounds and messages
			if(level.ex_kc_denied_msg)
			{
				// for victim and collector
				if((level.ex_kc_denied_msg & 1) == 1) player playLocalSound("kc_denied");
				if(player != kc_record.victim)
				{
					if((level.ex_kc_denied_msg & 2) == 2) player thread dogtagConfirmHUD(&"MISC_KDC_HUD");

					if(isPlayer(kc_record.victim))
					{
						if((level.ex_kc_denied_msg & 4) == 4) player iprintln(&"MISC_KDC_FOR", [[level.ex_pname]](kc_record.victim));
						if((level.ex_kc_denied_msg & 1) == 1) kc_record.victim playLocalSound("kc_denied");
						if((level.ex_kc_denied_msg & 2) == 2) kc_record.victim thread dogtagConfirmHUD(&"MISC_KDV_PROXY_HUD");
						if((level.ex_kc_denied_msg & 4) == 4) kc_record.victim iprintln(&"MISC_KDV_BY", [[level.ex_pname]](player));
						//if((level.ex_kc_denied_msg & 4) == 4) kc_record.victim iprintln(&"MISC_KDV_PROXY");
					}
				}
				else
				{
					if((level.ex_kc_denied_msg & 2) == 2) player thread dogtagConfirmHUD(&"MISC_KDV_HUD");
					if(isPlayer(kc_record.attacker) && (level.ex_kc_denied_msg & 4) == 4) player iprintln(&"MISC_KDV_SELF", [[level.ex_pname]](kc_record.attacker));
				}

				// for attacker
				if(isPlayer(kc_record.attacker))
				{
					if((level.ex_kc_denied_msg & 8) == 8) kc_record.attacker thread dogtagConfirmHUD(&"MISC_KDA_HUD");
					if((level.ex_kc_denied_msg & 16) == 16) kc_record.attacker iprintln(&"MISC_KDA_BY", [[level.ex_pname]](player));
					//if((level.ex_kc_denied_msg & 16) == 16) kc_record.attacker iprintln(&"MISC_KDA_SELF");
				}
			}

			lpplayerguid = player getGuid();
			lpplayernum = player getEntityNumber();
			lpplayerteam = player.pers["team"];
			lpplayername = player.name;
			logPrint("KD;" + lpplayerguid + ";" + lpplayernum + ";" + lpplayerteam + ";" + lpplayername + ";" + points_denied + "\n");
			
			// break out of loop
			break;
		}
		// KILL CONFIRMED (pickup by attacker or his teammates)
		else
		{
			// if only attacker can collect, and you're not, deny pickup
			if(level.ex_kc == 1 && (!isPlayer(kc_record.attacker) || player != kc_record.attacker)) continue;

			// handle regular points
			points = kc_record.points + kc_record.reward;
			if(level.ex_kc == 2 && isPlayer(kc_record.attacker)) pointsto = kc_record.attacker;
				else pointsto = player;

			pointsto thread [[level.pscoreproc]](points, "bonus", kc_record.reward);
			if(kc_record.isteamscore) thread [[level.tscoreproc]](pointsto.pers["team"], points);

			// handle statistics
			if(isPlayer(pointsto))
			{
				pointsto.pers["kill"]++;
				for(i = 0; i < kc_record.attacker_stats.size; i++)
					pointsto.pers[kc_record.attacker_stats[i]]++;
			}
			if(isPlayer(kc_record.victim))
			{
				kc_record.victim.pers["death"]++;
				kc_record.victim.deaths = kc_record.victim.pers["death"];
				for(i = 0; i < kc_record.victim_stats.size; i++)
					kc_record.victim.pers[kc_record.victim_stats[i]]++;
			}

			// sounds and messages
			if(level.ex_kc_confirm_msg)
			{
				// for attacker and collector
				if((level.ex_kc_confirm_msg & 1) == 1) player playLocalSound("kc_confirmed");
				if(player != kc_record.attacker)
				{
					if((level.ex_kc_confirm_msg & 2) == 2) player thread dogtagConfirmHUD(&"MISC_KCC_HUD");

					if(isPlayer(kc_record.attacker))
					{
						if((level.ex_kc_confirm_msg & 4) == 4) player iprintln(&"MISC_KCC_FOR", [[level.ex_pname]](kc_record.attacker));
						if((level.ex_kc_confirm_msg & 1) == 1) kc_record.attacker playLocalSound("kc_confirmed");
						if((level.ex_kc_confirm_msg & 2) == 2) kc_record.attacker thread dogtagConfirmHUD(&"MISC_KCA_PROXY_HUD");
						if((level.ex_kc_confirm_msg & 4) == 4) kc_record.attacker iprintln(&"MISC_KCA_BY", [[level.ex_pname]](player));
						//if((level.ex_kc_confirm_msg & 4) == 4) kc_record.attacker iprintln(&"MISC_KCA_PROXY");
					}
				}
				else
				{
					if((level.ex_kc_confirm_msg & 2) == 2) player thread dogtagConfirmHUD(&"MISC_KCA_HUD");
					if(isPlayer(kc_record.victim) && (level.ex_kc_confirm_msg & 4) == 4) player iprintln(&"MISC_KCA_SELF", [[level.ex_pname]](kc_record.victim));
				}

				// for victim
				if(isPlayer(kc_record.victim))
				{
					if((level.ex_kc_confirm_msg & 8) == 8) kc_record.victim thread dogtagConfirmHUD(&"MISC_KCV_HUD");
					if((level.ex_kc_confirm_msg & 16) == 16) kc_record.victim iprintln(&"MISC_KCV_BY", [[level.ex_pname]](player));
					//if((level.ex_kc_confirm_msg & 16) == 16) kc_record.victim iprintln(&"MISC_KCV_SELF");
				}
			}

			lpplayerguid = player getGuid();
			lpplayernum = player getEntityNumber();
			lpplayerteam = player.pers["team"];
			lpplayername = player.name;
			logPrint("KC;" + lpplayerguid + ";" + lpplayernum + ";" + lpplayerteam + ";" + lpplayername + ";" + points + "\n");

			// break out of loop
			break;
		}
	}

	// Notify timeout monitor to end
	self notify("kc_endtimeout");

	// Play pickup sound
	self playSound("kc_pickup");

	// Delete model
	kcFree(index);
}

dogtagConfirmHUD(notification)
{
	self notify("kc_update");
	waittillframeend;
	self endon("kc_update");

	hud_index = playerHudIndex("kc_notification");
	if(hud_index == -1)
	{
		hud_index = playerHudCreate("kc_notification", 320, 350, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index == -1) return;
	}
	else playerHudSetAlpha(hud_index, 1);

	playerHudSetText(hud_index, notification);
	wait( [[level.ex_fpstime]](.5) );
	playerHudFade(hud_index, .5, 0, 0);
	//playerHudDestroy(hud_index);
}
