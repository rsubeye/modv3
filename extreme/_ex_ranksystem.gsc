#include extreme\_ex_hudcontroller;

playerRankMonitor()
{
	self endon("kill_thread");

	if(!isDefined(self.pers["rank"])) self.pers["rank"] = self getRank();

	self waittill("spawned_player");

	if(level.ex_rank_statusicons) playerHudSetStatusIcon(getStatusIcon());

	while(isPlayer(self) && !level.ex_gameover)
	{
		self.pers["newrank"] = self getRank();

		// If old rank isn't the same as the new rank check
		if(self.pers["rank"] != self.pers["newrank"])
		{
			if(self.pers["rank"] < self.pers["newrank"])
			{
				// PROMOTED: update here, so the weapon update is based on the new rank
				self.pers["rank"] = self.pers["newrank"];
				self thread rankupdate(true);
			}
			else if(self.pers["rank"] > self.pers["newrank"])
			{
				// DEMOTED: update here, so the weapon update is based on the new rank
				self.pers["rank"] = self.pers["newrank"];
				self thread rankupdate(false);
			}
		}

		// check for WMD
		if(level.ex_rank_wmdtype) self thread checkWmd();

		// if player is in gunship, suspend rank updates until old weapons are restored
		while( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
		       (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) wait( [[level.ex_fpstime]](0.05) );

		wait( [[level.ex_fpstime]](1) );
	}
}

checkWmd()
{
	self endon("kill_thread");

	// return if already checking
	if(isDefined(self.ex_checkingwmd)) return;

	// if playing LIB and player is jailed, do not give WMD
	if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail)
	{
		self wmdStop();
		return;
	}

	// if entities monitor in defcon 2, suspend all WMD
	if(level.ex_entities_defcon == 2) return;

	// no checking if in gunship
	if( (level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == self) ||
	    (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == self) ) return;

	// no checking if frozen in FreezeTag
	if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") return;

	self.ex_checkingwmd = true;

	if(level.ex_rank_wmdtype == 1) self wmdFixed();
	else if(level.ex_rank_wmdtype == 2) self wmdRandom();
	else if(level.ex_rank_wmdtype == 3) self wmdAllowedRandom();

	wait( [[level.ex_fpstime]](5) );
	if(isPlayer(self)) self.ex_checkingwmd = undefined;
}

wmdFixed()
{
	self endon("kill_thread");

	wmd_assigned = false;
	if(self.ex_mortar_strike || self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship) wmd_assigned = true;
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;
	if(level.ex_gunship != 2 && self.ex_gunship) return;

	if(self.pers["rank"] < 3)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = false;
	if(self.pers["rank"] == 3) mortar_allowed = true;
	artillery_allowed = false;
	if(self.pers["rank"] == 4) artillery_allowed = true;
	airstrike_allowed = false;
	gunship_allowed = false;
	if(level.ex_gunship == 2)
	{
		if(self.pers["rank"] == 5 || self.pers["rank"] == 6) airstrike_allowed = true;
		else
		{
			if(!level.ex_rank_gunship_next && isDefined(self.pers["gunship"])) airstrike_allowed = true;
				else gunship_allowed = true;
		}
	}
	else if(self.pers["rank"] >= 5) airstrike_allowed = true;

	if(wmd_assigned)
	{
		if(mortar_allowed) return;
		if(artillery_allowed && (self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship)) return;
		if(airstrike_allowed && (self.ex_air_strike || self.ex_gunship)) return;
		if(gunship_allowed && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(mortar_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = 0;
			self thread extreme\_ex_mortar_player::start(delay);
		}
		else if(artillery_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = 0;
			self thread extreme\_ex_artillery_player::start(delay);
		}
		else if(airstrike_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = 0;
			self thread extreme\_ex_airstrike_player::start(delay);
		}
		else if(gunship_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = 0;
			self thread extreme\_ex_gunship::gunshipPerk(delay);
		}
	}
}

wmdRandom()
{
	self endon("kill_thread");

	wmd_assigned = false;
	if(self.ex_mortar_strike || self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship) wmd_assigned = true;
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;
	if(level.ex_gunship != 2 && self.ex_gunship) return;

	mortar_allowed = false;
	if(self.pers["rank"] >= level.ex_rank_mortar) mortar_allowed = true;
	artillery_allowed = false;
	if(self.pers["rank"] >= level.ex_rank_artillery) artillery_allowed = true;
	airstrike_allowed = false;
	if((self.pers["rank"] >= level.ex_rank_airstrike) || (level.ex_gunship != 2 && self.pers["rank"] >= level.ex_rank_special)) airstrike_allowed = true;
	gunship_allowed = false;
	if(level.ex_gunship == 2 && self.pers["rank"] >= level.ex_rank_special && (level.ex_rank_gunship_next || !isDefined(self.pers["gunship"]))) gunship_allowed = true;

	if(!mortar_allowed && !artillery_allowed && !airstrike_allowed && !gunship_allowed)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_air_strike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = 0;
			self thread extreme\_ex_mortar_player::start(delay);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = 0;
			self thread extreme\_ex_artillery_player::start(delay);
		}
		else if(wmdtodo == 3)
		{
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = 0;
			self thread extreme\_ex_airstrike_player::start(delay);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = 0;
			self thread extreme\_ex_gunship::gunshipPerk(delay);
		}
	}
}

wmdAllowedRandom()
{
	self endon("kill_thread");

	if(!level.ex_rank_allow_mortar && !level.ex_rank_allow_artillery && !level.ex_rank_allow_airstrike && !level.ex_rank_allow_special) return;

	wmd_assigned = false;
	if(self.ex_mortar_strike || self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship) wmd_assigned = true;
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;
	if(level.ex_gunship != 2 && self.ex_gunship) return;

	if(self.pers["rank"] < level.ex_rank_allow_rank)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = level.ex_rank_allow_mortar;
	artillery_allowed = level.ex_rank_allow_artillery;
	airstrike_allowed = level.ex_rank_allow_airstrike || (level.ex_gunship != 2 && level.ex_rank_allow_special);
	gunship_allowed = (level.ex_gunship == 2 && level.ex_rank_allow_special && (level.ex_rank_gunship_next || !isDefined(self.pers["gunship"])));

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_air_strike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = 0;
			self thread extreme\_ex_mortar_player::start(delay);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = 0;
			self thread extreme\_ex_artillery_player::start(delay);
		}
		else if(wmdtodo == 3)
		{
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = 0;
			self thread extreme\_ex_airstrike_player::start(delay);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = 0;
			self thread extreme\_ex_gunship::gunshipPerk(delay);
		}
	}
}

wmdStop()
{
	// stop wmd binoc threads
	self notify("end_waitforuse");
	wait( [[level.ex_fpstime]](0.1) );

	// stop mortars
	self.ex_mortar_strike = false;
	self notify("mortar_over");
	self notify("end_mortar");
	wait( [[level.ex_fpstime]](0.1) );

	// stop artillery
	self.ex_artillery_strike = false;
	self notify("artillery_over");
	self notify("end_artillery");
	wait( [[level.ex_fpstime]](0.1) );

	// stop airstrike
	self.ex_air_strike = false;
	self notify("airstrike_over");
	self notify("end_airstike");
	wait( [[level.ex_fpstime]](0.1) );

	// stop gunship
	if(level.ex_gunship == 2)
	{
		self.ex_gunship = false;
		self notify("gunship_over");
		self notify("end_gunship");
		wait( [[level.ex_fpstime]](0.1) );
	}

	// clear hud icon
	playerHudDestroy("wmd_icon");
}

rankupdate(promotion)
{
	self endon("disconnect");
	
	// update status icon
	if(level.ex_rank_statusicons) playerHudSetStatusIcon(getStatusIcon());

	// update head icon
	if(level.ex_rank_headicons) playerHudSetHeadIcon(getHeadIcon());

	// update HUD icon
	if(level.ex_rank_hudicons) self thread rankHud();

	rankstring = self getRankstring();

	while(self.sessionstate != "playing") wait( [[level.ex_fpstime]](0.5) );

	if(promotion)
	{
		if(level.ex_rank_announce == 1)
		{
			self iprintlnbold(&"RANK_PROMOTION_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"RANK_PROMOTION_START", &"RANK_MIDDLE_MSG", rankstring);
			self playLocalSound("promotion");
		}

		if(level.ex_rank_update_loadout) self extreme\_ex_weapons::updateLoadout(true);
	}
	else
	{
		if(level.ex_rank_announce == 1)
		{
			self iprintlnbold(&"RANK_DEMOTION_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"RANK_DEMOTION_START", &"RANK_MIDDLE_MSG", rankstring);
			self playLocalSound("demotion");
		}

		self wmdStop();
		if(level.ex_rank_update_loadout) self extreme\_ex_weapons::updateLoadout(false);
	}
}

rankHud()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(level.ex_rank_hudicons == 2)
	{
		hud_index = playerHudCreate("rank_text", 10, 474, 1, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "left", "middle", false, false);
		if(hud_index == -1) return;
		playerHudSetLabel(hud_index, &"RANK_RANK");
		rankstring = self getRankstring();
		playerHudSetText(hud_index, rankstring);
	}

	hud_index = playerHudCreate("rank_icon", 120, 420, level.ex_iconalpha, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
	if(hud_index == -1) return;
	chevron = self getHudIcon();
	playerHudSetShader(hud_index, chevron, 32, 32);
	playerHudScale(hud_index, .5, 0, 24, 24);
}

getRank()
{
	self endon("disconnect");

	// check if player has a preset rank
	if(!isDefined(self.pers["preset_rank"])) self.pers["preset_rank"] = self checkPresetRank();

	// determine rank using
	points = 0;
	if(level.ex_rank_score == 0)
	{
		points = self.pers["score"] + game["rank_" + self.pers["preset_rank"]];
		points = points + self.pers["specials_cash"];
	}
	else if(level.ex_rank_score == 1)
	{
		points = (self.pers["kill"] + self.pers["special"]) - (self.pers["teamkill"] + self.pers["death"]);
		points = points + game["rank_" + self.pers["preset_rank"]];
	}
	else
	{
		points = (self.pers["kill"] + self.pers["special"] + self.pers["bonus"]) - (self.pers["teamkill"] + self.pers["death"]);
		points = points + game["rank_" + self.pers["preset_rank"]];
	}

	if(points >= game["rank_7"]) return 7;
	else if(points >= game["rank_6"] && points < game["rank_7"]) return 6;
	else if(points >= game["rank_5"] && points < game["rank_6"]) return 5;
	else if(points >= game["rank_4"] && points < game["rank_5"]) return 4;
	else if(points >= game["rank_3"] && points < game["rank_4"]) return 3;
	else if(points >= game["rank_2"] && points < game["rank_3"]) return 2;
	else if(points >= game["rank_1"] && points < game["rank_2"]) return 1;
	else return 0;
}

getRankstring()
{
	self endon("disconnect");

	rank = &"RANK_AMERICAN_0";

	if(self.pers["team"] == "allies")
	{				
		switch(game["allies"])
		{
			case "american":
			{
				switch(self.pers["rank"])
				{
					case 7: rank = &"RANK_AMERICAN_7"; break; // General
					case 6: rank = &"RANK_AMERICAN_6"; break; // Colonel
					case 5: rank = &"RANK_AMERICAN_5"; break; // Major
					case 4: rank = &"RANK_AMERICAN_4"; break; // Captain
					case 3: rank = &"RANK_AMERICAN_3"; break; // Lieutenant
					case 2: rank = &"RANK_AMERICAN_2"; break; // Sergeant
					case 1: rank = &"RANK_AMERICAN_1"; break; // Corporal
					case 0: rank = &"RANK_AMERICAN_0"; break; // Private
				}
				break;
			}	
			
			case "british":
			{
				switch(self.pers["rank"])
				{
					case 7: rank = &"RANK_BRITISH_7"; break; // General
					case 6: rank = &"RANK_BRITISH_6"; break; // Colonel
					case 5: rank = &"RANK_BRITISH_5"; break; // Major
					case 4: rank = &"RANK_BRITISH_4"; break; // Captain
					case 3: rank = &"RANK_BRITISH_3"; break; // Lieutenant
					case 2: rank = &"RANK_BRITISH_2"; break; // Sergeant
					case 1: rank = &"RANK_BRITISH_1"; break; // Corporal
					case 0: rank = &"RANK_BRITISH_0"; break; // Private
				}
				break;
			}
			
			case "russian":
			{
				switch(self.pers["rank"])
				{
					case 7: rank = &"RANK_RUSSIAN_7"; break; // General-Poruchik
					case 6: rank = &"RANK_RUSSIAN_6"; break; // Polkovnik
					case 5: rank = &"RANK_RUSSIAN_5"; break; // Mayor
					case 4: rank = &"RANK_RUSSIAN_4"; break; // Kapitan
					case 3: rank = &"RANK_RUSSIAN_3"; break; // Leytenant
					case 2: rank = &"RANK_RUSSIAN_2"; break; // Podpraporshchik
					case 1: rank = &"RANK_RUSSIAN_1"; break; // Kapral
					case 0: rank = &"RANK_RUSSIAN_0"; break; // Soldat
				}
				break;
			}
		}
	}
	else if(self.pers["team"] == "axis")
	{
		switch(game["axis"])
		{
			case "german":
			{
				switch(self.pers["rank"])
				{
					case 7: rank = &"RANK_GERMAN_7"; break; // General
					case 6: rank = &"RANK_GERMAN_6"; break; // Oberst
					case 5: rank = &"RANK_GERMAN_5"; break; // Major
					case 4: rank = &"RANK_GERMAN_4"; break; // Hauptmann
					case 3: rank = &"RANK_GERMAN_3"; break; // Leutnant
					case 2: rank = &"RANK_GERMAN_2"; break; // Unterfeldwebel
					case 1: rank = &"RANK_GERMAN_1"; break; // Unteroffizier
					case 0: rank = &"RANK_GERMAN_0"; break; // Grenadier
				}
				break;
			}
		}
	}

	return rank;
}

getHudIcon()
{
	self endon("disconnect");

	if(!isDefined(self.pers) || !isDefined(self.pers["rank"]) || !isDefined(self.pers["team"]) || self.pers["team"] == "spectator") return "";
	return( game["hudicon_rank" + self.pers["rank"]] );
}

getStatusIcon()
{
	self endon("disconnect");

	if(!isDefined(self.pers) || !isDefined(self.pers["rank"]) || !isDefined(self.pers["team"]) || self.pers["team"] == "spectator") return "";
	return( game["statusicon_rank" + self.pers["rank"]] );
}

getHeadIcon()
{
	self endon("disconnect");

	if(!isDefined(self.pers) || !isDefined(self.pers["rank"]) || !isDefined(self.pers["team"]) || self.pers["team"] == "spectator") return "";
	return( game["headicon_rank" + self.pers["rank"]] );
}

checkPresetRank()
{
	self endon("disconnect");

	count = 0;
	clan_check = "";

	if(isDefined(self.ex_name))
	{
		// convert the players clan name
		playerclan = extreme\_ex_utils::convertMLJ(self.ex_name);

		for(;;)
		{
			// get the preset clan name
			clan_check = [[level.ex_drm]]("ex_psr_clan_" + count, "", "", "", "string");

			// check if there is a preset clan name, if not end here!
			if(clan_check == "") break;

			// convert clan name
			clan_check = extreme\_ex_utils::convertMLJ(clan_check);

			// if the names match, break here and set rank
			if(clan_check == playerclan) break;
				else count ++;
		}
	}

	if(clan_check != "")
		return [[level.ex_drm]]("ex_psr_rank_" + count, 0, 0, 8, "int");

	// convert the players name
	playername = extreme\_ex_utils::convertMLJ(self.name);

	count = 0;

	for(;;)
	{
		// get the preset player name
		name_check = [[level.ex_drm]]("ex_psr_name_" + count, "", "", "", "string");

		// check if there is a preset player name, if not end here!
		if(name_check == "") break;

		// convert name_check
		name_check = extreme\_ex_utils::convertMLJ(name_check);

		// if the names match, break here and set rank
		if(name_check == playername) break;
		else count ++;
	}

	if(name_check == "") return 0;
		else return [[level.ex_drm]]("ex_psr_rank_" + count, 0, 0, 8, "int");
}
