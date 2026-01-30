#include extreme\_ex_weapons;
#include extreme\_ex_hudcontroller;

init()
{
	level.trip_identifier = 0;

	level.ex_triparray = [];

	if(level.ex_teamplay)
	{
		level.ex_tweapons["axis"] = 0;
		level.ex_tweapons["allies"] = 0;
	}
	else level.ex_tweapons = 0;
}

main()
{
	self endon("kill_thread");

	while(isPlayer(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](0.5) );

		frag = false;
		smoke = false;
		combo = false;
		trip = "none";

		// if not prone, continue monitoring
		if(self [[level.ex_getstance]](false) != 2 || !self meleeButtonPressed() || self playerads()) continue;

		// disable tripwire & displays while using or with turret
		if(isDefined(self.onturret) || isWeaponType(self getCurrentWeapon(), "turret")) 
		{
			self thread cleanMessages();
			continue;
		}

		// check available nades
		frags = getCurrentAmmo(self.pers["fragtype"]);
		smokes = getCurrentAmmo(self.pers["smoketype"]);

		// teams share the same weapon file for special frags, so if one them is enabled, skip enemy frags
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) enemy_frags = 0;
			else enemy_frags = getCurrentAmmo(self.pers["enemy_fragtype"]);
		enemy_smokes = getCurrentAmmo(self.pers["enemy_smoketype"]);

		total_frags = frags + enemy_frags;
		total_smokes = smokes + enemy_smokes;

		// need at least 2. If not enough nades, continue monitoring
		if((total_frags + total_smokes < 2) || self.ex_plantwire || self.ex_defusewire) continue;

		// if not planting or defusing already, start nade selection process
		if(!self.ex_plantwire && !self.ex_defusewire)
		{
			// check if too close to special entities
			if(isPlayer(self) && self extreme\_ex_utils::tooClose(level.ex_mindist["tripwires"][0], level.ex_mindist["tripwires"][1], level.ex_mindist["tripwires"][2], level.ex_mindist["tripwires"][3]))
			{
				self cleanMessages();
				continue;
			}

			self showTripwireMessage(undefined, undefined, &"TRIPWIRE_CHOOSE_GRENADE");

			// check for frags
			frag1type = self.pers["fragtype"];
			frag2type = self.pers["fragtype"];

			// not enough of their own teams, so check for enemy frags too
			if(frags <= 1)
			{
				if(frags == 1 && enemy_frags >= 1) // mix own frag and enemy frags
				{
					frag2type = self.pers["enemy_fragtype"];
					frag = true;
				}
				else if(frags == 0 && enemy_frags >= 2) // enemy frags only
				{
					frag1type = self.pers["enemy_fragtype"];
					frag2type = self.pers["enemy_fragtype"];
					frag = true;
				}
			}
			else frag = true; // got enough of their own frags

			// check for frag/smoke combination
			comb1type = self.pers["fragtype"];
			comb2type = self.pers["fragtype"];

			if(frags >= 1)
			{
				if(smokes >= 1) // mix own frag and own smoke
				{
					comb2type = self.pers["smoketype"];
					combo = true;
				}
				else if(enemy_smokes >= 1) // mix own frag and enemy smoke
				{
					comb2type = self.pers["enemy_smoketype"];
					combo = true;
				}
			}

			if(!combo && enemy_frags >= 1)
			{
				if(smokes >= 1) // mix enemy frag and own smoke
				{
					comb1type = self.pers["enemy_fragtype"];
					comb2type = self.pers["smoketype"];
					combo = true;
				}
				else if(enemy_smokes >= 1) // mix own frag and enemy smoke
				{
					comb1type = self.pers["enemy_fragtype"];
					comb2type = self.pers["enemy_smoketype"];
					combo = true;
				}
			}

			// check for smokes
			smoke1type = self.pers["smoketype"];
			smoke2type = self.pers["smoketype"];

			// not enough of their own teams, so check for enemy frags too
			if(smokes <= 1)
			{
				if(smokes == 1 && enemy_smokes >= 1) // mix own smoke and enemy smoke
				{
					smoke2type = self.pers["enemy_smoketype"];
					smoke = true;
				}
				else if(smokes == 0 && enemy_smokes >= 2) // enemy smokes only
				{
					smoke1type = self.pers["enemy_smoketype"];
					smoke2type = self.pers["enemy_smoketype"];
					smoke = true;
				}
			}
			else smoke = true; // got enough of their own smokes

			// ok, lets see what they want to plant
			count = 0;
			while(self meleeButtonPressed() && self [[level.ex_getstance]](true) == 2)
			{
				wait( [[level.ex_fpstime]](0.05) );
				count += 0.05;
				if(count >= 1) break;
			}

			// didn't hold down long enough, loop
			if(count < 1)
			{
				self cleanMessages();
				continue;
			}

			// if they have enough frags, display the frag tripwire message
			if(frag)
			{
				self playLocalSound("tripclick");
				trip = "frag";
				if(combo) self showTripwireMessage(frag1type, frag2type, &"TRIPWIRE_HOLD_COMBO");
					else if(smoke) self showTripwireMessage(frag1type, frag2type, &"TRIPWIRE_HOLD_SMOKE");
						else self showTripwireMessage(frag1type, frag2type, &"TRIPWIRE_RELEASE_CANCEL");

				// if they let go here, they want to use frag grenades		
				count = 0;
				while(self meleeButtonPressed() && self [[level.ex_getstance]](true) == 2)
				{
					wait( [[level.ex_fpstime]](0.05) );
					count += 0.05;
					if(count >= 1) break;
				}
			}
			else count = 1; // no frags!

			// if they have a combination of frag and smoke, display the combo tripwire message
			if(combo)
			{
				if(count >= 1) // they kept holding so show the combo
				{
					self playLocalSound("tripclick");
					trip = "combo";
					if(smoke) self showTripwireMessage(comb1type, comb2type, &"TRIPWIRE_HOLD_SMOKE");
						else self showTripwireMessage(comb1type, comb2type, &"TRIPWIRE_RELEASE_CANCEL");
				}	

				// if they let go here, they want to use combo trip
				count = 0;
				while(self meleeButtonPressed() && self [[level.ex_getstance]](true) == 2)
				{
					wait( [[level.ex_fpstime]](0.05) );
					count += 0.05;
					if(count >= 1) break;
				}
			}
			else count = 1; // no combo!

			// if they have enough smokes, display the smoke tripwire message
			if(smoke)
			{
				if(count >= 1) // they kept holding so show the smokes
				{
					self playLocalSound("tripclick");
					trip = "smoke";
					if(frag) self showTripwireMessage(smoke1type, smoke2type, &"TRIPWIRE_HOLD_FRAG");
						else self showTripwireMessage(smoke1type, smoke2type, &"TRIPWIRE_RELEASE_CANCEL");
				}
			}

			// if they let go here, it will use the smokes. continue to hold and it will cancel planting a tripwire
			count = 0;
			while(self meleeButtonPressed() && self [[level.ex_getstance]](true) == 2)
			{
				wait( [[level.ex_fpstime]](0.05) );
				count += 0.05;
				if(count >= 1) break;
			}

			// they held on, so they don't want to plant a tripwire, or missed the one they wanted...doh!
			if(count >= 1)
			{
				trip = "none";
				self cleanMessages();
			}

			// check to see if they got up during this process?	
			if(self [[level.ex_getstance]](true) != 2) continue;

			// ok, good to go...
			if(trip == "frag") self thread plantTripwire(frag1type, frag2type);
				else if(trip == "combo") self thread plantTripwire(comb1type, comb2type);
					else if(trip == "smoke") self thread plantTripwire(smoke1type, smoke2type);
		}
	}
}

plantTripwire(grenadetype1, grenadetype2)
{
	self endon("kill_thread");
	self endon("defusingtripwire");

	if(isPlayer(self))
	{
		// Make sure to only run one instance
		if(self.ex_plantwire) return;
		self.ex_plantwire = true;

		// show the plant message
		self showTripwireMessage(grenadetype1, grenadetype2, &"TRIPWIRE_PLANT");

		// while there not pressing the melee key, monitor to see if they leave the prone position
		while(isPlayer(self) && self.sessionstate == "playing" && !(self meleeButtonPressed()))
		{
			if(self [[level.ex_getstance]](true) != 2)
			{
				self cleanMessages();
				self.ex_plantwire = false;
				return;
			}
			
			wait( [[level.ex_fpstime]](0.05) );
		}

		// loop
		if(isPlayer(self))
		{
			for(;;)
			{
				// check the amount of ammo, might have thrown a grenade
				if(grenadetype1 == grenadetype2) iAmmo = self getCurrentAmmo(grenadetype1);
					else iAmmo = self getCurrentAmmo(grenadetype1) + self getCurrentAmmo(grenadetype2);
	
				// not enough ammo?
				if(iAmmo < 2) break;
		
				// check they're still prone
				if(self [[level.ex_getstance]](false) != 2) break;
		
				// get the position 15" in front of the player
				position = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles),15);
		
				// check that there is room.
				trace = bulletTrace(self.origin + (0,0,10), position + (0,0,10), false, undefined);
				if(trace["fraction"] !=1)
				{
					self iprintlnbold(&"TRIPWIRE_REASON_NO_ROOM");
					break;
				}
			
				// find ground
				trace = bulletTrace(position + (0,0,10), position + (0,0,-10), false, undefined);
				if(trace["fraction"] ==1)
				{
					self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
					break;
				}
		
				if(isDefined(trace["entity"]) && isDefined(trace["entity"].classname) && trace["entity"].classname == "script_vehicle") break;
		
				position=trace["position"];
				tracestart = position + (0,0,10);
		
				// find position 1
				traceend = tracestart + [[level.ex_vectorscale]](anglesToForward(self.angles + (0,90,0)),50);
				trace = bulletTrace(tracestart, traceend, false, undefined);
		
				if(trace["fraction"]!= 1)
				{
					distance = distance(tracestart,trace["position"]);
					if(distance>5) distance = distance - 2;
					position1 = tracestart + [[level.ex_vectorscale]](vectorNormalize(trace["position"]-tracestart),distance);
				}
				else position1 = trace["position"];
		
				// find ground
				trace = bulletTrace(position1, position1 + (0,0,-20), false, undefined);
		
				if(trace["fraction"]==1)
				{
					self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
					break;
				}
		
				vPos1 = trace["position"];
		
				// find position 2
				traceend = tracestart + [[level.ex_vectorscale]](anglesToForward(self.angles + (0,-90,0)),50);
				trace = bulletTrace(tracestart,traceend,false,undefined);
		
				if(trace["fraction"] != 1)
				{
					distance = distance(tracestart,trace["position"]);
					if(distance > 5) distance = distance - 2;
					position2 = tracestart + [[level.ex_vectorscale]](vectorNormalize(trace["position"]-tracestart),distance);
				}
				else position2 = trace["position"];
		
				// find ground
				trace = bulletTrace(position2,position2+(0,0,-20),false,undefined);
		
				if(trace["fraction"] == 1)
				{
					self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
					break;
				}
		
				vPos2 = trace["position"];
		
				maxlimit = level.ex_tweapon_limit;
				curval = 0;
				msg = "";
	
				// Ok to plant, kill checktripwireplacement and set up new hud message
				self notify("ex_checkdefusetripwire");
	
				// check to see if they are pressing their melee key
				if(isPlayer(self) && self.sessionstate == "playing" && self meleeButtonPressed())
				{
					// Check tripwire limit before planting
					if(level.ex_teamplay)
					{
						curval = level.ex_tweapons[self.sessionteam];
						msg = &"TRIPWIRE_LIMIT_TEAM_REACHED";
					}
					else
					{
						curval = level.ex_tweapons;
						maxlimit = maxlimit * 2;
						msg = &"TRIPWIRE_LIMIT_REACHED";
					}
					
					if(curval >= maxlimit)
					{
						self thread [[level.ex_bclear]]("self", 5);
						self iprintlnbold(msg);
						break;
					}
		
					// lock the player to the spot while planting the tripwire
					self extreme\_ex_utils::punishment("disable", "freeze");
	
					// get player origin and angles
					oldorigin = self.origin;
					angles = self.angles;
	
					// play plant sound
					self playSound("MP_bomb_plant");
	
					self cleanMessages();
					playerHudCreateBar(level.ex_tweapon_ptime, &"TRIPWIRE_PLANTING", false);

					// count how long they hold the melee button for
					count = 0;
					while(isPlayer(self) && self meleeButtonPressed() && self.origin == oldorigin && self [[level.ex_getstance]](false) == 2)
					{
						wait( level.ex_fps_frame );
						count += level.ex_fps_frame;
						if(count >= level.ex_tweapon_ptime) break;
					}
	
					// remove messages and progress bar
					playerHudDestroyBar();
	
					// did they hold the key down long enough?
					if(count < level.ex_tweapon_ptime) break;
	
					// check the tripwire limits again	
					maxlimit = level.ex_tweapon_limit;
					curval = 0;
		
					// Check tripwire limit before final deployment, in case someone beat them to it!
					if(level.ex_teamplay)
					{
						curval = level.ex_tweapons[self.sessionteam];
						msg = &"TRIPWIRE_LIMIT_TEAM_REACHED";
					}
					else
					{
						curval = level.ex_tweapons;
						maxlimit = maxlimit * 2;
						msg = &"TRIPWIRE_LIMIT_REACHED";
					}
					
					if(curval >= maxlimit)
					{
						self thread [[level.ex_bclear]]("self", 5);
						self iprintlnbold(msg);
						break;
					}
	
					// adjust the amount of tripwires available	
					if(level.ex_teamplay) level.ex_tweapons[self.sessionteam]++;
					else level.ex_tweapons++;
		
					// calculate the tripwire centre
					x = (vPos1[0] + vPos2[0])/2;
					y = (vPos1[1] + vPos2[1])/2;
					z = (vPos1[2] + vPos2[2])/2;
					vPos = (x,y,z+3);
		
					// decrease the players grenade ammo
					self takeAmmo(grenadetype1, 1);
					self takeAmmo(grenadetype2, 1);
			
					// spawn the tripwire
         	level.trip_identifier++;
					tripwep = spawn("script_origin", vPos);
					tripwep.identifier = level.trip_identifier;
					tripwep.angles = angles;
					tripwep.triparrayindex = getTriparrayIndex();
					//logprint("TRIPWIRE DEBUG: planted tripwire has array index " + tripwep.triparrayindex + "\n");
					level.ex_triparray[tripwep.triparrayindex] = tripwep;
					tripwep thread monitorTripwire(self, grenadetype1, grenadetype2, vPos1, vPos2);
					break;
				}
			}
		}
	}

	if(isPlayer(self))
	{
		// enable the players weapon and release them
		self thread extreme\_ex_utils::punishment("enable", "release");

		// remove the messages and progress bar
		playerHudDestroyBar();
		self cleanMessages();

		// not planting anymore!
		self.ex_plantwire = false;
	}
}

getTriparrayIndex()
{
	for(i = 0; i < level.ex_triparray.size; i++)
		if(!isDefined(level.ex_triparray[i])) return i;

	return level.ex_triparray.size;
}

defuseTripwire(tripwep, grenadetype1, grenadetype2)
{
	self endon("kill_thread");

	self notify("ex_checkdefusetripwire");
	self endon("ex_checkdefusetripwire");

	if(isPlayer(self))
	{
		// make sure to only run one instance
		if(self.ex_defusewire) return;

		self.ex_defusewire = true;
	
		// get the distance between the tripwire weapons and the player
		distance1 = distance(tripwep.tweapon1.origin, self.origin);
		distance2 = distance(tripwep.tweapon2.origin, self.origin);

		// check still in within range of the tripwire
		if(distance1 > 20 && distance2 > 20)
		{
			self cleanMessages();
			self.ex_defusewire = false;
			return;
		}
	
		// ok to defuse, end the plant routine
		self notify("defusingtripwire");

		// show new message
		self showTripwireMessage(grenadetype1, grenadetype2, &"TRIPWIRE_DEFUSE");
	
		// loop
		for(;;)
		{
			wait( [[level.ex_fpstime]](0.5) );

			if(isPlayer(self) && self meleeButtonPressed())
			{
				// lock the player to the spot while defusing the tripwire	
				self extreme\_ex_utils::punishment("disable", "freeze");

				// get player origin and angles
				oldorigin = self.origin;
				angles = self.angles;

				// play defuse sound
				self playSound("MP_bomb_defuse");

				self cleanMessages();
				playerHudCreateBar(level.ex_tweapon_dtime, &"TRIPWIRE_DEFUSING", true);

				count = 0;
				while(isPlayer(self) && self meleeButtonPressed() && isDefined(tripwep) && self.origin == oldorigin && self [[level.ex_getstance]](false) == 2)
				{
					wait( level.ex_fps_frame );
					count += level.ex_fps_frame;
					if(count >= level.ex_tweapon_dtime) break;
				}

				// remove the messages and progress bar
				playerHudDestroyBar();

				// did they hold the key down long enough?	
				if(count < level.ex_tweapon_dtime || !isDefined(tripwep)) break;
	
				// adjust the amount of tripwires available
				if(isDefined(tripwep.team) && tripwep.team != "no_owner")
				{
					if(level.ex_teamplay) level.ex_tweapons[tripwep.team]--;
					else level.ex_tweapons--;
				}
	
				// stop monitor the tripwire
				if(isDefined(tripwep)) tripwep notify("endmonitoringtripwire");

				// bonus points for defusing
				if(level.ex_reward_tripwire)
				{
					if( (!level.ex_teamplay && isDefined(tripwep.owner) && tripwep.owner != self) ||
					    (level.ex_teamplay && isDefined(tripwep.team) && tripwep.team != self.pers["team"]) )
					{
						self thread [[level.pscoreproc]](level.ex_reward_tripwire, "bonus");
					}
				}

				// remove the tripwire
				level notify("tripwire_danger" + tripwep.identifier);
				if(isDefined(tripwep.tweapon1)) tripwep.tweapon1 delete();
				if(isDefined(tripwep.tweapon2)) tripwep.tweapon2 delete();
				if(isDefined(tripwep))
				{
					if(isDefined(level.ex_triparray[tripwep.triparrayindex]))
					{
						//logprint("TRIPWIRE DEBUG: deleting tripwire index " + tripwep.triparrayindex + " from array\n");
						level.ex_triparray[tripwep.triparrayindex] delete();
					}
				}
	
				wait( [[level.ex_fpstime]](0.2) );

				// play a defuse sound to everyone and give them the new grenades
				if(isPlayer(self))
				{
					self playlocalsound("defused");
					self playSound("MP_bomb_defuse");
					self addToNadeLoadout(grenadetype1, 1);
					self addToNadeLoadout(grenadetype2, 1);
				}

				break;
			}

			wait( [[level.ex_fpstime]](0.05) );
	
			// check still prone
			if(self [[level.ex_getstance]](false) != 2) break;

			// check that the tripwire is still there, another player may be defusing too?
			if(!isDefined(tripwep.tweapon1) || !isDefined(tripwep.tweapon2)) break;

			// check the player is still within distance of the tripwire
			distance1 = distance(tripwep.tweapon1.origin, self.origin);
			distance2 = distance(tripwep.tweapon2.origin, self.origin);
			if(distance1 >= 20 && distance2 >= 20) break;
		}
	}

	// enable the players weapon and release them
	self thread extreme\_ex_utils::punishment("enable", "release");

	// remove the messages and progress bar
	playerHudDestroyBar();
	self cleanMessages();

	// not defusing anymore!
	self.ex_defusewire = false;
}

addToNadeLoadout(grenadetype, newnades)
{
	if(isWeaponType(grenadetype, "frag") || isWeaponType(grenadetype, "fragspecial"))
	{
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentfrags = self getammocount(self.pers["fragtype"]);
			else currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
		if(!isDefined(currentfrags)) currentfrags = 0;

		totalfrags = currentfrags + newnades;
		if(totalfrags > level.ex_frag_cap) totalfrags = level.ex_frag_cap;
		self setWeaponClipAmmo(self.pers["fragtype"], totalfrags);
	}
	else if(isWeaponType(grenadetype, "smoke") || isWeaponType(grenadetype, "smokespecial"))
	{
		currentsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
		if(!isDefined(currentsmokes)) currentsmokes = 0;

		totalsmokes = currentsmokes + newnades;
		if(totalsmokes > level.ex_smoke_cap) totalsmokes = level.ex_smoke_cap;
		self setWeaponClipAmmo(self.pers["smoketype"], totalsmokes);
	}
}

monitorTripwire(owner, grenadetype1, grenadetype2, vPos1, vPos2)
{
	level endon("ex_gameover");
	self endon("endmonitoringtripwire");

	// save owner and team
	if(isPlayer(owner))
	{
		self.owner = owner;
		self.team = owner.pers["team"];
	}
	else
	{
		self.owner = undefined;
		self.team = "no_owner";
	}

	// Spawn nade one
	grenadeID1 = getDeviceID(grenadetype1);
	angles = self.angles;
	if(grenadeID1 >= 70) angles = angles + (0,0,90); // flip satchels
	self.tweapon1 = spawn("script_model", vPos1 + (0,0,getModelZ(grenadeID1)));
	self.tweapon1 setModel(getWeaponModel(grenadeID1));
	self.tweapon1.angles = angles;
	self.tweapon1.damaged = false;

	// Spawn nade two
	grenadeID2 = getDeviceID(grenadetype2);
	angles = self.angles;
	if(grenadeID2 >= 70) angles = angles + (0,0,90); // flip satchels
	self.tweapon2 = spawn("script_model", vPos2 + (0,0,getModelZ(grenadeID2)));
	self.tweapon2 setModel(getWeaponModel(grenadeID2));
	self.tweapon2.angles = angles;
	self.tweapon2.damaged = false;

	// Get detection spots
	nadedist = distance(vPos1, vPos2);
	vPos3 = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), nadedist/3.33);
	vPos4 = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles + (0,180,0)), nadedist/3.33);

	// Set detection ranges
	tripwarnrange = distance(self.origin, vPos1) + 150;
	tripsphere = distance(vPos3, vPos1);

	//level thread tripDebug(vPos3, tripsphere, (1,0,0));
	//level thread tripDebug(vPos4, tripsphere, (1,1,0));

	if(isPlayer(owner) && owner.sessionstate == "playing")
	{
		// delay activation if trip is lethal to owner (so he can get out of range)
		if(level.ex_tweapon == 1)
		{
			hud_index = owner playerHudCreate("tripwire_act", 320, 408, 0.8, (1,1,1), 1.2, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
			if(hud_index != -1)
			{
				owner playerHudSetLabel(hud_index, &"TRIPWIRE_ACTIVATE");
				owner playerHudSetTimer(hud_index, 5);
				wait( [[level.ex_fpstime]](5) );
				if(isPlayer(owner))
				{
					owner playerHudDestroy(hud_index);
					owner playlocalsound("planted");
					owner playlocalsound("MP_bomb_plant");
				}
			}
			else wait( [[level.ex_fpstime]](5) );
		}
		else
		{
			owner playlocalsound("planted");
			owner playlocalsound("MP_bomb_plant");
		}
	}

	while(true)
	{
		wait( [[level.ex_fpstime]](0.05) );

		// Blow if one of the nades has taken enough damage
		if(self.tweapon1.damaged || self.tweapon2.damaged) break;

		// Loop through players to find out if one has triggered the wire
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			// Check if player still exist
			if(isPlayer(players[i]) && players[i].sessionstate == "playing") player = players[i];
				else continue;

			// Within range?
			if(distance(self.origin, player.origin) >= tripwarnrange)
			{
				// Set warning to false
				if(level.ex_tweapon_warning) player notify("tripwire_danger" + self.identifier);
				continue;
			}

			// player is jumping over the tripwire?
			// mbots do not always pass the isOnGround test, so skip this test for them
			if(isPlayer(player) && !isDefined(player.pers["isbot"]) && !player isOnGround()) continue;

			// check for defusal
			if(level.ex_tweapon_defuse)
			{
				defuse_ok = false;
				if(level.ex_teamplay)
				{
					switch(level.ex_tweapon_defuse)
					{
						case 1: if(player == self.owner && player.pers["team"] == self.team) defuse_ok = true; break;
						case 2:	if(player.pers["team"] == self.team) defuse_ok = true; break;
						case 3:	if( (player == self.owner && player.pers["team"] == self.team) || player.pers["team"] != self.team ) defuse_ok = true; break;
						case 4: defuse_ok = true; break;
					}
				}
				else
				{
					switch(level.ex_tweapon_defuse)
					{
						case 1:
						case 2: if(player == self.owner) defuse_ok = true; break;
						case 3:
						case 4: defuse_ok = true; break;
					}
				}
				if(defuse_ok && !player.ex_defusewire && player [[level.ex_getstance]](false) == 2)
				{
					// if in range of either grenade and prone and not already defusing
					if(distance(vPos1, player.origin) <= 20 || distance(vPos2, player.origin) <= 20)
					{
						// Prevent defusing while being frozen in freezetag
						if(level.ex_currentgt != "ft" || (isDefined(player.frozenstate) && player.frozenstate != "frozen"))
							player thread defuseTripwire(self, grenadetype1, grenadetype2);
					}
				}
			}

			// do we blow on owner?
			if(isDefined(self.owner) && self.owner == player)
			{
				if(self.team == player.pers["team"] && level.ex_tweapon != 1) continue; // don't blow on owner!
				if(level.ex_tweapon_warning) player thread tripwireWarning("tripwire_danger" + self.identifier, self.origin);
			}
			// do we blow on teammates?
			else if(level.ex_teamplay && isDefined(self.team) && self.team == player.pers["team"])
			{
				if(level.ex_tweapon == 3) continue; // don't blow on teammates!
				if(level.ex_tweapon_warning) player thread tripwireWarning("tripwire_danger" + self.identifier, self.origin);
			}

			// Within sphere one?
			if(distance(vPos3, player.origin) >= tripsphere) continue;

			// Within sphere two?
			if(distance(vPos4, player.origin) >= tripsphere) continue;

			// Player is within both spheres, so trigger explosion. closer to nade 1 or 2?
			if(distance(vPos1, player.origin) < distance(vPos2, player.origin)) self.tweapon1.damaged = true;
				else self.tweapon2.damaged = true;
		}
	}

	level notify("tripwire_danger" + self.identifier);

	if(isDefined(self.team) && self.team != "no_owner")
	{
		if(level.ex_teamplay) level.ex_tweapons[self.team]--;
		else level.ex_tweapons--;
	}

	self.tweapon1 notify("endtripwiredamagemonitor");
	self.tweapon2 notify("endtripwiredamagemonitor");

	if(isDefined(self.tweapon1.damaged))
	{
		self.tweapon1 playSound("weap_fraggrenade_pin");
		wait( [[level.ex_fpstime]](0.05) );
		self.tweapon2 playSound("weap_fraggrenade_pin");
		wait( [[level.ex_fpstime]](0.05) );
	}
	else
	{
		self.tweapon2 playSound("weap_fraggrenade_pin");
		wait( [[level.ex_fpstime]](0.05) );
		self.tweapon1 playSound("weap_fraggrenade_pin");
		wait( [[level.ex_fpstime]](0.05) );
	}

	wait( [[level.ex_fpstime]](randomFloat(0.25)) );

	// Check that damage owner still exists, if not tripwire just kills
	if(isPlayer(owner) && owner.sessionteam != "spectator") eAttacker = owner;
		else eAttacker = self;

	// blow 'em
	if(isDefined(self.tweapon1.damaged))
	{
		// blow 1
		playfx(level.ex_effect[getFX(grenadeID1)], self.tweapon1.origin);
		self.tweapon1 playSound(getSound(grenadeID1));
		self.tweapon1 tripwireDamage(self.tweapon1, eAttacker, grenadetype1, level.ex_tweapon);

		// A small, random, delay between the nades
		wait( [[level.ex_fpstime]](randomFloat(0.25)) );

		// blow 2
		playfx(level.ex_effect[getFX(grenadeID2)], self.tweapon2.origin);
		self.tweapon2 playSound(getSound(grenadeID2));
		self.tweapon2 tripwireDamage(self.tweapon2, eAttacker, grenadetype2, level.ex_tweapon);
	}
	else
	{
		// blow 2
		playfx(level.ex_effect[getFX(grenadeID2)], self.tweapon2.origin);
		self.tweapon2 playSound(getSound(grenadeID2));
		self.tweapon2 tripwireDamage(self.tweapon2, eAttacker, grenadetype2, level.ex_tweapon);

		// A small, random, delay between the effects
		wait( [[level.ex_fpstime]](randomFloat(0.25)) );

		// blow 1
		playfx(level.ex_effect[getFX(grenadeID1)], self.tweapon1.origin);
		self.tweapon1 playSound(getSound(grenadeID1));
		self.tweapon1 tripwireDamage(self.tweapon1, eAttacker, grenadetype1, level.ex_tweapon);
	}

	origin1 = self.tweapon1.origin;
	self.tweapon1 delete();
	origin2 = self.tweapon2.origin;
	self.tweapon2 delete();

	wait( [[level.ex_fpstime]](0.25) );
	if(isDefined(self))
	{
		if(isDefined(level.ex_triparray[self.triparrayindex]))
		{
			//logprint("TRIPWIRE DEBUG: deleting tripwire index " + self.triparrayindex + " from array\n");
			level.ex_triparray[self.triparrayindex] delete();

			thread checkProximityTrips(origin1, level.ex_tweapon_cpx);
			thread extreme\_ex_landmines::checkProximityLandmines(origin1, level.ex_tweapon_cpx);
			thread extreme\_ex_specials_sentrygun::checkProximitySentryGuns(origin1, eAttacker, level.ex_tweapon_cpx);

			wait( [[level.ex_fpstime]](0.5) );

			thread checkProximityTrips(origin2, level.ex_tweapon_cpx);
			thread extreme\_ex_landmines::checkProximityLandmines(origin2, level.ex_tweapon_cpx);
			thread extreme\_ex_specials_sentrygun::checkProximitySentryGuns(origin2, eAttacker, level.ex_tweapon_cpx);
		}
	}
}

tripwireWarning(name, origin)
{
	self endon("kill_thread");

	hud_index = playerHudIndex(name);
	if(hud_index != -1) return;

	// the name of the HUD element must be the same as the notification to destroy it
	self thread tripwireWarningDestroyer(name);

	hud_index = playerHudCreate(name, origin[0], origin[1], 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index == -1) return;
	playerHudSetShader(hud_index, "killiconsuicide", 7, 7);
	playerHudSetWaypoint(hud_index, origin[2] + 30, true);
}

tripwireWarningDestroyer(notification)
{
	self endon("kill_thread");

	ent = spawnstruct();
	self thread tripwireNotification(notification, true, ent);
	self thread tripwireNotification(notification, false, ent);
	ent waittill("returned");

	ent notify("die");
	playerHudDestroy(notification);
}

tripwireNotification(notification, islevel, ent)
{
	self endon("kill_thread");
	ent endon("die");

	if(isLevel) level waittill(notification);
		else self waittill(notification);

	ent notify("returned");
}

checkProximityTrips(origin, cpx)
{
	if(level.ex_tweapon && level.ex_tweapon_cpx)
	{
		for(i = 0; i < level.ex_triparray.size; i ++)
		{
			tripwire = level.ex_triparray[i];
			if(!isDefined(tripwire)) continue;

			origin1 = tripwire.tweapon1.origin;
			origin2 = tripwire.tweapon2.origin;
			if(!isDefined(origin1) || !isDefined(origin2)) continue;

			tripwire_damage = 0;
			if(distance(origin, origin1) <= cpx) tripwire_damage += 1;
			if(distance(origin, origin2) <= cpx) tripwire_damage += 2;

			if(tripwire_damage)
			{
				if(tripwire_damage == 3)
				{
					if(distance(origin, origin1) < distance(origin, origin2)) tripwire.tweapon1.damaged = true;
						else tripwire.tweapon2.damaged = true;
				}
				else if(tripwire_damage == 2) tripwire.tweapon2.damaged = true;
					else tripwire.tweapon1.damaged = true;
			}
		}
	}
}

tripwireDamage(who, eAttacker, grenadetype, teamkill)
{
	deviceID = getDeviceID(grenadetype);
	switch(deviceID)
	{
		// only frags, fire, gas and satchel charges cause damage
		case 1:
		case 2:
		case 3:
		case 4:
		case 50:
		case 51:
		case 52:
		case 53:
		case 54:
		case 60:
		case 61:
		case 62:
		case 63:
		case 64:
		case 70:
		case 71:
		case 72:
		case 73:
		case 74:
		who extreme\_ex_utils::scriptedfxradiusdamage(eAttacker, undefined, "MOD_EXPLOSIVE", "tripwire_mp", level.ex_tweapon_radius, 600, 400, "none", undefined, true, true);
		break;
	}
}

showTripwireMessage(grenadetype1, grenadetype2, msg)
{
	self endon("kill_thread");

	if(isPlayer(self))
	{
		self cleanMessages();

		if(isDefined(msg))
		{
			hud_index = playerHudCreate("tripwire_msg", 320, 408, 1, (1,1,1), 0.8, 0, "fullscreen", "fullscreen", "center", "middle", false, false);
			if(hud_index == -1) return;
			playerHudSetText(hud_index, msg);
		}

		if(isDefined(grenadetype1))
		{
			hud_index = playerHudCreate("tripwire_nade1", 320, 415, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "left", "top", false, false);
			if(hud_index == -1) return;
			playerHudSetShader(hud_index, getWeaponHud(grenadetype1), 40, 40);
		}

		if(isDefined(grenadetype2))
		{
			hud_index = playerHudCreate("tripwire_nade2", 320, 415, 1, (1,1,1), 1, 0, "fullscreen", "fullscreen", "right", "top", false, false);
			if(hud_index == -1) return;
			playerHudSetShader(hud_index, getWeaponHud(grenadetype2), 40, 40);
		}
	}
}

cleanMessages()
{
	self endon("kill_thread");

	playerHudDestroy("tripwire_msg");
	playerHudDestroy("tripwire_nade1");
	playerHudDestroy("tripwire_nade2");
}

giveAmmo(grenadetype,var)
{
	self endon("disconnect");

	if(isPlayer(self))
	{	
		iAmmo = var + self getCurrentAmmo(grenadetype);

		if(iAmmo < 1) return;

		self setWeaponClipAmmo(grenadetype, iAmmo);
		self playSound("grenade_pickup");
	}
}

takeAmmo(grenadetype,var)
{
	self endon("disconnect");

	if(isPlayer(self))
	{
		iAmmo = self getCurrentAmmo(grenadetype);

		if(iAmmo == 0) return;

		self setWeaponClipAmmo(grenadetype, iAmmo - var);
	}
}

getCurrentAmmo(grenadetype)
{
	return self getAmmoCount(grenadetype);
}

getDeviceID(grenadetype)
{
	switch(grenadetype)
	{
		// frag grenades
		case "frag_grenade_american_mp": return 1;
		case "frag_grenade_british_mp": return 2;
		case "frag_grenade_russian_mp": return 3;
		case "frag_grenade_german_mp": return 4;

		// american smoke grenades
		case "smoke_grenade_american_mp": return 10;
		case "smoke_grenade_american_blue_mp": return 11;
		case "smoke_grenade_american_green_mp": return 12;
		case "smoke_grenade_american_orange_mp": return 13;
		case "smoke_grenade_american_pink_mp": return 14;
		case "smoke_grenade_american_red_mp": return 15;
		case "smoke_grenade_american_yellow_mp": return 16;

		// british smoke grenades
		case "smoke_grenade_british_mp": return 20;
		case "smoke_grenade_british_blue_mp": return 21;
		case "smoke_grenade_british_green_mp": return 22;
		case "smoke_grenade_british_orange_mp": return 23;
		case "smoke_grenade_british_pink_mp": return 24;
		case "smoke_grenade_british_red_mp": return 25;
		case "smoke_grenade_british_yellow_mp": return 26;

		// russian smoke grenades
		case "smoke_grenade_russian_mp": return 30;
		case "smoke_grenade_russian_blue_mp": return 31;
		case "smoke_grenade_russian_green_mp": return 32;
		case "smoke_grenade_russian_orange_mp": return 33;
		case "smoke_grenade_russian_pink_mp": return 34;
		case "smoke_grenade_russian_red_mp": return 35;
		case "smoke_grenade_russian_yellow_mp": return 36;

		// german smoke grenades
		case "smoke_grenade_german_mp": return 40;
		case "smoke_grenade_german_blue_mp": return 41;
		case "smoke_grenade_german_green_mp": return 42;
		case "smoke_grenade_german_orange_mp": return 43;
		case "smoke_grenade_german_pink_mp": return 44;
		case "smoke_grenade_german_red_mp": return 45;
		case "smoke_grenade_german_yellow_mp": return 46;

		// gas grenades
		case "gas_mp": return 50;
		case "smoke_grenade_german_gas_mp": return 51;
		case "smoke_grenade_american_gas_mp": return 52;
		case "smoke_grenade_british_gas_mp": return 53;
		case "smoke_grenade_russian_gas_mp": return 54;

		// fire grenades
		case "fire_mp": return 60;
		case "smoke_grenade_british_fire_mp": return 61;
		case "smoke_grenade_russian_fire_mp": return 62;
		case "smoke_grenade_german_fire_mp": return 63;
		case "smoke_grenade_american_fire_mp": return 64;

		// satchel charges
		case "satchel_mp": return 70;
		case "smoke_grenade_german_satchel_mp": return 71;
		case "smoke_grenade_american_satchel_mp": return 72;
		case "smoke_grenade_british_satchel_mp": return 73;
		case "smoke_grenade_russian_satchel_mp": return 74;

	}
}

getWeaponHud(grenadetype)
{
	deviceID = getDeviceID(grenadetype);
	switch(deviceID)
	{
		// frag grenades
		case 1: return "gfx/icons/hud@us_grenade_C.tga";
		case 2: return "gfx/icons/hud@british_grenade_C.tga";
		case 3: return "gfx/icons/hud@russian_grenade_C.tga";
		case 4: return "gfx/icons/hud@steilhandgrenate_C.tga";

		// gas grenades
		case 50:
		case 51:
		case 52:
		case 53:
		case 54: return "gas_grenade";

		// fire grenades
		case 60:
		case 61:
		case 62:
		case 63:
		case 64: return "gfx/icons/hud@incenhandgrenade_c.tga";

		// satchel charges
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return "gfx/icons/hud@satchel_charge1.tga";

		// smoke grenades
		default: return "hud_us_smokegrenade_C";
	}
}

getModelZ(grenadeID)
{
	switch(grenadeID)
	{
		// frag grenades
		case 1: return 2;
		case 2: return 2;
		case 3: return 3;
		case 4: return 3;

		// gas grenades
		case 50:
		case 51:
		case 52:
		case 53:
		case 54: return 1;

		// fire grenades
		case 60:
		case 61:
		case 62:
		case 63:
		case 64: return 1;

		// satchel charges
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return 0;

		// smoke grenades
		default: return 3;
	}
}

getWeaponModel(grenadeID)
{
	switch(grenadeID)
	{
		// frag grenades
		case 1: return "xmodel/weapon_mk2fraggrenade";
		case 2: return "xmodel/weapon_mk1grenade";
		case 3: return "xmodel/weapon_russian_handgrenade";
		case 4: return "xmodel/weapon_nebelhandgrenate";

		// gas grenades
		case 50:
		case 51:
		case 52:
		case 53:
		case 54: return "xmodel/weapon_mustardgas_grenade";

		// fire grenades
		case 60:
		case 61:
		case 62:
		case 63:
		case 64: return "xmodel/weapon_incendiary_grenade";

		// satchel charges
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return "xmodel/projectile_satchel";

		// smoke grenades
		default: return "xmodel/weapon_us_smoke_grenade";
	}
}

getFX(grenadeID)
{
	switch(grenadeID)
	{
		// frag grenade
		case 1:
		case 2:
		case 3:
		case 4: return "plane_bomb"; // temp explosion

		// smoke grey
		case 10:
		case 20:
		case 30:
		case 40: return "greysmoke";

		// smoke blue
		case 11:
		case 21:
		case 31:
		case 41: return "bluesmoke";

		// smoke green
		case 12:
		case 22:
		case 32:
		case 42: return "greensmoke";

		// smoke orange
		case 13:
		case 23:
		case 33:
		case 43: return "orangesmoke";

		// smoke pink
		case 14:
		case 24:
		case 34:
		case 44: return "pinksmoke";

		// smoke red
		case 15:
		case 25:
		case 35:
		case 45: return "redsmoke";

		// smoke yellow
		case 16:
		case 26:
		case 36:
		case 46: return "yellowsmoke";
		
		// gas grenades
		case 50:
		case 51:
		case 52:
		case 53:
		case 54: return "gas";

		// fire grenades
		case 60:
		case 61:
		case 62:
		case 63:
		case 64: return "fire";

		// satchel charges
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return "satchel";
	}
}

getSound(grenadeID)
{
	switch(grenadeID)
	{
		// frag, satchel charges and fire grenades
		case 1:
		case 2:
		case 3:
		case 4:
		case 60:
		case 61:
		case 62:
		case 63:
		case 64:
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return "grenade_explode_default";

		// gas and smoke grenades
		default: return "smokegrenade_explode_default";
	}
}

// Tripwire debugging

tripDebug(pos, range, color)
{
	timeout = 60 * level.ex_fps;

	while(timeout > 0)
	{
		start = pos + [[level.ex_vectorscale]](anglestoforward((0,0,0)), range);
		for(i = 10; i < 360; i += 10)
		{
			point = pos + [[level.ex_vectorscale]](anglestoforward((0,i,0)), range);
			line(start, point, color);
			start = point;
		}
		wait(.05);
		timeout--;
	}
}
