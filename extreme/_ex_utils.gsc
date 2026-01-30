log(line1, line2, line3, line4, line5, line5)
{
	if(level.ex_logextreme)
	{
		if(isDefined(line1)) logPrint("eXtreme-LOG: " + line1 + "\n");
		if(isDefined(line2)) logPrint("eXtreme-LOG: " + line2 + "\n");
		if(isDefined(line3)) logPrint("eXtreme-LOG: " + line3 + "\n");
		if(isDefined(line4)) logPrint("eXtreme-LOG: " + line4 + "\n");
		if(isDefined(line5)) logPrint("eXtreme-LOG: " + line5 + "\n");
	}
}

cvardef(varname, vardefault, min, max, type)
{
	// get the variable's definition
	switch(type)
	{
		case "int":
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getCvarInt(varname);
			break;
		case "float":
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getCvarFloat(varname);
			break;
		case "string":
		default:
			if(getcvar(varname) == "") definition = vardefault;
				else definition = getcvar(varname);
			break;
	}

	// if it's a number, check if it violates the minimum
	if((type == "int" || type == "float") && definition < min)
	{
		logprint("CVARDEF: Variable \"" + varname + "\" (" + definition + ") violates minimum (" + min + ")\n");
		definition = min;
	}

	// if it's a number, check if it violates the maximum
	if((type == "int" || type == "float") && definition > max)
	{
		logprint("CVARDEF: Variable \"" + varname + "\" (" + definition + ") violates maximum (" + max + ")\n");
		definition = max;
	}

	return definition;
}

punishment(weaponstatus, movestatus)
{
	if(!isDefined(weaponstatus)) weaponstatus = "keep";

	if(!isDefined(movestatus)) movestatus = "same";

	if(isDefined(self.ex_anchor))
	{
		self unlink();
		self.ex_anchor delete();
	}

	if(weaponstatus == "disable") self [[level.ex_dWeapon]]();
	else if(weaponstatus == "random" && randomInt(100) < 50)
	{
		if(randomInt(100) < 50) self [[level.ex_dWeapon]]();
			else self extreme\_ex_weapons::dropcurrentweapon();
	}
	else if(weaponstatus == "drop") self extreme\_ex_weapons::dropcurrentweapon();
	else if(weaponstatus == "enable") self [[level.ex_eWeapon]]();

	if(movestatus == "freeze")
	{
		// spawn a script origin, and lock the players in place and disable weapon
		self.ex_anchor = spawn("script_origin", self.origin);
		self.ex_anchor.angles = self.angles;
		self linkTo(self.ex_anchor);
	}
	else if(movestatus == "release" && isDefined(self.ex_anchor))
	{
		self unlink();
		self.ex_anchor delete();
	}		
}

playSoundLoc(sound, position, special)
{
	if(!isDefined(position))
		position = game["playArea_Centre"];
	
	soundloc = spawn( "script_model", position);
	wait( [[level.ex_fpstime]](0.05) );
	soundloc show();

	if(!isDefined(special)) soundloc playSound(sound);
	else
	{
		if(isPlayer(self) && special == "death")
		{
			if(level.ex_diana && isDefined(self.pers["diana"]))
			{
				soundloc playsound(sound + "_russianfem_" + (randomInt(level.ex_voices["diana"])+1) );
			}
			else
			{
				if(self.pers["team"] == "allies") soundloc playsound(sound + "_" + game["allies"] + "_" + (randomInt(level.ex_voices[game["allies"]])+1) );
				else soundloc playsound(sound + "_german_" + (randomInt(level.ex_voices["german"])+1) );
			}
		}
	}

	wait( [[level.ex_fpstime]](5) );
	soundloc delete();
}

playSoundOnPlayer(sound, special)
{
	self endon("kill_thread");

	self notify("ex_soplayer");
	self endon("ex_soplayer");

	if(!isDefined(special)) self playsound(sound);
	else
	{
		if(isPlayer(self) && special == "pain")
		{
			if(level.ex_diana && isDefined(self.pers["diana"]))
			{
				self playsound(sound + "_russianfem_" + (randomInt(level.ex_voices["diana"])+1) );
			}
			else
			{
				if(self.pers["team"] == "allies") self playsound(sound + "_" + game["allies"] + "_" + (randomInt(level.ex_voices[game["allies"]])+1) );
				else self playsound(sound + "_german_" + (randomInt(level.ex_voices["german"])+1) );
			}
		}
	}
}

playSoundOnPlayers(sound, team, spectators)
{
	if(!isDefined(spectators)) spectators = true;

	players = level.players;

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if(i % 10 == 0) wait( [[level.ex_fpstime]](.05) );

			if(isPlayer(players[i]) && isDefined(players[i].pers) && isDefined(players[i].pers["team"]) && players[i].pers["team"] == team)
			{
				if(spectators) players[i] playLocalSound(sound);
				else if(players[i].sessionstate != "spectator") players[i] playLocalSound(sound);
			}
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
		{
			if(i % 10 == 0) wait( [[level.ex_fpstime]](.05) );

			if(isPlayer(players[i]) && spectators) players[i] playLocalSound(sound);
			else if(isPlayer(players[i]) && isDefined(players[i].sessionstate) && players[i].sessionstate != "spectator") players[i] playLocalSound(sound);
		}
	}

	wait( [[level.ex_fpstime]](1) );
	level notify("psopdone");
}

playBattleChat(msg, team)
{
	if(!isDefined(msg)) return;

	// get nationality prefix for allies
	switch(game["allies"])
	{
		case "american":
			allies_prefix = "US_";
			break;
		case "british":
			allies_prefix = "UK_";
			break;
		default:
			allies_prefix = "RU_";
			break;
	}

	num = randomInt(4);

	allies_soundalias = allies_prefix + num + "_" + msg;
	axis_soundalias = "GE_" + num + "_" + msg;

	switch(team)
	{
		case "allies":
			level thread [[level.ex_psop]](allies_soundalias, "allies", false);
			break;
		case "axis":
			level thread [[level.ex_psop]](axis_soundalias, "axis", false);
			break;
		default:
			level thread [[level.ex_psop]](allies_soundalias, "allies", false);
			level thread [[level.ex_psop]](axis_soundalias, "axis", false);
			break;
	}
}

ex_PrecacheEffect(effect)
{
	if(!isDefined(game["precached_effects"]))
	{
		game["precached_effects"] = [];
		default_effect = "fx/misc/missing_fx.efx";
		effect_id = loadfx(default_effect);
		index = game["precached_effects"].size;
		game["precached_effects"][index] = spawnstruct();
		game["precached_effects"][index].effect = default_effect;
		game["precached_effects"][index].effect_id = effect_id;
	}

	// return the FX ID from the array for FX already precached
	effect_id = isInEffectsArray(game["precached_effects"], effect);
	if(effect_id != -1) return(effect_id);

	// load FX if within limit
	if(game["precached_effects"].size >= level.ex_tune_cachelimit_effects) // max 55 (max 63 but 8 reserved for level script effects)
	{
		logprint("ERROR: Too many precached effects! Effect \"" + effect + "\" replaced with \"missing_fx\"\n");
		return(game["precached_effects"][0].effect_id);
	}

	effect_id = loadfx(effect);
	index = game["precached_effects"].size;
	game["precached_effects"][index] = spawnstruct();
	game["precached_effects"][index].effect = effect;
	game["precached_effects"][index].effect_id = effect_id;
	return(effect_id);
}

ex_PrecacheShader(shader)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(game["precached_shaders"])) game["precached_shaders"] = [];

	if(isInArray(game["precached_shaders"], shader)) return;

	if(game["precached_shaders"].size >= level.ex_tune_cachelimit_shaders) // max 127
	{
		logprint("ERROR: Too many precached shaders! Precache request for \"" + shader + "\" ignored\n");
		return;
	}

	game["precached_shaders"][game["precached_shaders"].size] = shader;
	precacheShader(shader);
}

ex_PrecacheHeadIcon(icon)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(game["precached_headicons"])) game["precached_headicons"] = [];

	if(isInArray(game["precached_headicons"], icon)) return;

	if(game["precached_headicons"].size >= level.ex_tune_cachelimit_headicons) // max 15
	{
		logprint("ERROR: Too many precached head icons! Precache request for \"" + icon + "\" ignored\n");
		return;
	}

	game["precached_headicons"][game["precached_headicons"].size] = icon;
	precacheHeadIcon(icon);
}

ex_PrecacheStatusIcon(icon)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(game["precached_statusicons"])) game["precached_statusicons"] = [];

	if(isInArray(game["precached_statusicons"], icon)) return;

	if(game["precached_statusicons"].size >= level.ex_tune_cachelimit_statusicons) // max 8
	{
		logprint("ERROR: Too many precached status icons! Precache request for \"" + icon + "\" ignored\n");
		return;
	}

	game["precached_statusicons"][game["precached_statusicons"].size] = icon;
	precacheStatusIcon(icon);
}

ex_PrecacheModel(model)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(game["precached_models"])) game["precached_models"] = [];

	if(isInArray(game["precached_models"], model)) return;

	if(game["precached_models"].size >= level.ex_tune_cachelimit_models) // max 127 (max 254 but 127 reserved for weapon file models)
	{
		logprint("ERROR: Too many precached models! Precache request for \"" + model + "\" ignored\n");
		return;
	}

	game["precached_models"][game["precached_models"].size] = model;
	precacheModel(model);
}

ex_PrecacheItem(item)
{
	if(!isDefined(game["precached_items"])) game["precached_items"] = [];

	if(!isInArray(game["precached_items"], item))
	{
		if(isDefined(game["precachedone"])) return;

		if(game["precached_items"].size >= level.ex_tune_cachelimit_items) // max 127
		{
			logprint("ERROR: Too many precached items! Precache request for \"" + item + "\" ignored\n");
			return;
		}

		game["precached_items"][game["precached_items"].size] = item;
		precacheItem(item);
	}

	if(isDefined(level.weapons) && isDefined(level.weapons[item])) level.weapons[item].precached = true;
}

ex_PrecacheString(string)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(game["precached_strings"])) game["precached_strings"] = [];

	if(isInArray(game["precached_strings"], string)) return;

	if(game["precached_strings"].size >= level.ex_tune_cachelimit_strings) // max 254
	{
		logprint("ERROR: Too many precached strings! Precache request ignored\n");
		return;
	}

	game["precached_strings"][game["precached_strings"].size] = string;
	precacheString(string);
}

ex_PrecacheMenu(menu)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(game["precached_menus"])) game["precached_menus"] = [];

	if(isInArray(game["precached_menus"], menu)) return;

	if(game["precached_menus"].size >= level.ex_tune_cachelimit_menus) // max 32
	{
		logprint("ERROR: Too many precached menus! Precache request for \"" + menu + "\" ignored\n");
		return;
	}

	game["precached_menus"][game["precached_menus"].size] = menu;
	precacheMenu(menu);
}

ex_PrecacheShellShock(shock)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(game["precached_shellshocks"])) game["precached_shellshocks"] = [];

	if(isInArray(game["precached_shellshocks"], shock)) return;

	if(game["precached_shellshocks"].size >= level.ex_tune_cachelimit_shellshocks) // max 15
	{
		logprint("ERROR: Too many precached shellshocks! Precache request for \"" + shock + "\" ignored\n");
		return;
	}

	game["precached_shellshocks"][game["precached_shellshocks"].size] = shock;
	precacheShellShock(shock);
}

ex_PrecacheRumble(rumble)
{
	if(isDefined(game["precachedone"])) return;

	if(!isDefined(game["precached_rumbles"])) game["precached_rumbles"] = [];

	if(isInArray(game["precached_rumbles"], rumble)) return;

	if(game["precached_rumbles"].size >= level.ex_tune_cachelimit_rumbles) // max 15
	{
		logprint("ERROR: Too many precached rumbles! Precache request for \"" + rumble + "\" ignored\n");
		return;
	}

	game["precached_rumbles"][game["precached_rumbles"].size] = rumble;
	precacheRumble(rumble);
}

reportPrecached(verbose)
{
	if(isDefined(game["reportprecached"])) return;
	game["reportprecached"] = true;

	// strings
	if(isDefined(game["precached_strings"]))
	{
		logprint("STATS: number of precached strings     : " + numToStr(game["precached_strings"].size, 3) + " (max 254)\n");
	}
	else logprint("STATS: number of precached strings: 0\n");

	// shaders
	if(isDefined(game["precached_shaders"]))
	{
		logprint("STATS: number of precached shaders     : " + numToStr(game["precached_shaders"].size, 3) + " (max 127)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_shaders"].size; i++)
				logprint("STATS: precached shader " + (i+1) + ": " + game["precached_shaders"][i] + "\n");
		}
	}
	else logprint("STATS: number of precached shaders: 0\n");

	// models
	if(isDefined(game["precached_models"]))
	{
		logprint("STATS: number of precached models      : " + numToStr(game["precached_models"].size, 3) + " (max 127; game max 254 - 127 reserved)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_models"].size; i++)
				logprint("STATS: precached model " + (i+1) + ": " + game["precached_models"][i] + "\n");
		}
	}
	else logprint("STATS: number of precached models: 0\n");

	// effects
	if(isDefined(game["precached_effects"]))
	{
		logprint("STATS: number of precached effects     : " + numToStr(game["precached_effects"].size, 3) + " (max 55; game max 63 - 8 reserved)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_effects"].size; i++)
				logprint("STATS: precached effect " + (i+1) + ": " + game["precached_effects"][i].effect + " (ID: " + game["precached_effects"][i].effect_id +")\n");
		}
	}
	else logprint("STATS: number of precached effects: 0\n");

	// weapons
	if(isDefined(game["precached_items"]))
	{
		logprint("STATS: number of precached weapons     : " + numToStr(game["precached_items"].size, 3) + " (max 127)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_items"].size; i++)
				logprint("STATS: precached weapon " + (i+1) + ": " + game["precached_items"][i] + "\n");
		}
	}
	else logprint("STATS: number of precached weapons: 0\n");

	// menus
	if(isDefined(game["precached_menus"]))
	{
		logprint("STATS: number of precached menus       : " + numToStr(game["precached_menus"].size, 3) + " (max 32)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_menus"].size; i++)
				logprint("STATS: precached menu " + (i+1) + ": " + game["precached_menus"][i] + "\n");
		}
	}
	else logprint("STATS: number of precached menus: 0\n");

	// head icons
	if(isDefined(game["precached_headicons"]))
	{
		logprint("STATS: number of precached head icons  : " + numToStr(game["precached_headicons"].size, 3) + " (max 15)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_headicons"].size; i++)
				logprint("STATS: precached head icon " + (i+1) + ": " + game["precached_headicons"][i] + "\n");
		}
	}
	else logprint("STATS: number of precached head icons: 0\n");

	// status icons
	if(isDefined(game["precached_statusicons"]))
	{
		logprint("STATS: number of precached status icons: " + numToStr(game["precached_statusicons"].size, 3) + " (max 8)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_statusicons"].size; i++)
				logprint("STATS: precached status icon " + (i+1) + ": " + game["precached_statusicons"][i] + "\n");
		}
	}
	else logprint("STATS: number of precached status icons: 0\n");

	// shellshocks
	if(isDefined(game["precached_shellshocks"]))
	{
		logprint("STATS: number of precached shell shocks: " + numToStr(game["precached_shellshocks"].size, 3) + " (max 15)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_shellshocks"].size; i++)
				logprint("STATS: precached shellshock " + (i+1) + ": " + game["precached_shellshocks"][i] + "\n");
		}
	}
	else logprint("STATS: number of precached shell shocks: 0\n");

	// rumbles
	if(isDefined(game["precached_rumbles"]))
	{
		logprint("STATS: number of precached rumbles     : " + numToStr(game["precached_rumbles"].size, 3) + " (max 15)\n");
		if(verbose)
		{
			for(i = 0; i < game["precached_rumbles"].size; i++)
				logprint("STATS: precached rumble " + (i+1) + ": " + game["precached_rumbles"][i] + "\n");
		}
	}
	else logprint("STATS: number of precached rumbles: 0\n");

	logprint("STATS: number of DRM variable requests (during precache phase): " + level.drmstat_readinit + "\n");
	logprint("STATS: number of DRM variable requests  (after precache phase): " + level.drmstat_readpost + "\n");
}

isInEffectsArray(array, effect)
{
	if(!isDefined(array) || !array.size) return(-1);

	i = 0;
	while(i < array.size)
	{
		if(array[i].effect == effect) return(array[i].effect_id);
		i++;
	}
	return(-1);
}

isInArray(array, element)
{
	if(!isDefined(array) || !array.size) return(false);

	i = 0;
	while(i < array.size)
	{
		if(array[i] == element) return(true);
		i++;
	}
	return(false);
}

monotone( str )
{
	if( !isDefined( str ) || ( str == "" ) )
		return ( "" );

	_s = "";

	_colorCheck = false;
	for ( i = 0; i < str.size; i++ )
	{
		ch = str[ i ];
		if( _colorCheck )
		{
			_colorCheck = false;

			switch( ch )
			{
				case "0":	// black
				case "1":	// red
				case "2":	// green
				case "3":	// yellow
				case "4":	// blue
				case "5":	// cyan
				case "6":	// pink
				case "7":	// white
				case "8":	// Olive
				case "9":	// Grey
					break;
				default:
					_s += ( "^" + ch );
					break;
			}
		}
		else if( ch == "^" )
			_colorCheck = true;
		else
			_s += ch;
	}
	return ( _s );
}

isOutside(origin)
{
	if(!isDefined(origin)) return false;

	trace = bulletTrace(origin, origin+ (0,0,6000), false, false);

	if(distance(origin, trace["position"]) >= 1000) return true;
	else return false;
}

time_convert(value)
{
	switch(value)
	{
		case 1: return &"TIME_1_SECOND";
		case 2: return &"TIME_2_SECONDS";
		case 3: return &"TIME_3_SECONDS";
		case 4: return &"TIME_4_SECONDS";
		case 5: return &"TIME_5_SECONDS";
		case 6: return &"TIME_6_SECONDS";
		case 7: return &"TIME_7_SECONDS";
		case 8: return &"TIME_8_SECONDS";
		case 9: return &"TIME_9_SECONDS";
		case 10: return &"TIME_10_SECONDS";

		case 11: return &"TIME_11_SECONDS";
		case 12: return &"TIME_12_SECONDS";
		case 13: return &"TIME_13_SECONDS";
		case 14: return &"TIME_14_SECONDS";
		case 15: return &"TIME_15_SECONDS";
		case 16: return &"TIME_16_SECONDS";
		case 17: return &"TIME_17_SECONDS";
		case 18: return &"TIME_18_SECONDS";
		case 19: return &"TIME_19_SECONDS";
		case 20: return &"TIME_20_SECONDS";
		
		case 21: return &"TIME_21_SECONDS";
		case 22: return &"TIME_22_SECONDS";
		case 23: return &"TIME_23_SECONDS";
		case 24: return &"TIME_24_SECONDS";
		case 25: return &"TIME_25_SECONDS";
		case 26: return &"TIME_26_SECONDS";
		case 27: return &"TIME_27_SECONDS";
		case 28: return &"TIME_28_SECONDS";
		case 29: return &"TIME_29_SECONDS";
		case 30: return &"TIME_30_SECONDS";

		case 31: return &"TIME_31_SECONDS";
		case 32: return &"TIME_32_SECONDS";
		case 33: return &"TIME_33_SECONDS";
		case 34: return &"TIME_34_SECONDS";
		case 35: return &"TIME_35_SECONDS";
		case 36: return &"TIME_36_SECONDS";
		case 37: return &"TIME_37_SECONDS";
		case 38: return &"TIME_38_SECONDS";
		case 39: return &"TIME_39_SECONDS";
		case 40: return &"TIME_40_SECONDS";

		case 41: return &"TIME_41_SECONDS";
		case 42: return &"TIME_42_SECONDS";
		case 43: return &"TIME_43_SECONDS";
		case 44: return &"TIME_44_SECONDS";
		case 45: return &"TIME_45_SECONDS";
		case 46: return &"TIME_46_SECONDS";
		case 47: return &"TIME_47_SECONDS";
		case 48: return &"TIME_48_SECONDS";
		case 49: return &"TIME_49_SECONDS";
		case 50: return &"TIME_50_SECONDS";

		case 51: return &"TIME_51_SECONDS";
		case 52: return &"TIME_52_SECONDS";
		case 53: return &"TIME_53_SECONDS";
		case 54: return &"TIME_54_SECONDS";
		case 55: return &"TIME_55_SECONDS";
		case 56: return &"TIME_56_SECONDS";
		case 57: return &"TIME_57_SECONDS";
		case 58: return &"TIME_58_SECONDS";
		case 59: return &"TIME_59_SECONDS";
		case 60: return &"TIME_60_SECONDS";
	}
}

GetMapDim(debug)
{
	if(!isDefined(debug)) debug = false;

	mark = getTime();

	xMin = 20000;
	xMax = -20000;
	yMin = 20000;
	yMax = -20000;
	zMin = 20000;
	zMax = -20000;
	zSky = -20000;

	entitytypes = [];
	entitytypes[entitytypes.size] = "mp_dm_spawn";
	entitytypes[entitytypes.size] = "mp_tdm_spawn";
	entitytypes[entitytypes.size] = "mp_ctf_spawn_allied";
	entitytypes[entitytypes.size] = "mp_ctf_spawn_axis";
	entitytypes[entitytypes.size] = "mp_sd_spawn_attacker";
	entitytypes[entitytypes.size] = "mp_sd_spawn_defender";

	// get min and max values for x, y and z for all common spawnpoints
	for(e = 0; e < entitytypes.size; e++)
	{
		entities = getentarray(entitytypes[e], "classname");

		for(i = 0; i < entities.size; i++)
		{
			if(isDefined(entities[i].origin))
			{
				origin = entities[i].origin;

				if(origin[0] < xMin) xMin = origin[0];
				if(origin[0] > xMax) xMax = origin[0];
				if(origin[1] < yMin) yMin = origin[1];
				if(origin[1] > yMax) yMax = origin[1];
				if(origin[2] < zMin) zMin = origin[2];
				if(origin[2] > zMax) zMax = origin[2];
				if(zMax > zSky) zSky = zMax;

				trace = bulletTrace(origin, origin + (0,0,20000), false, undefined);
				if(trace["fraction"] != 1 && trace["position"][2] > zSky)
				{
					if(trace["position"][2] < 6000) zSky = trace["position"][2];
						else if(zSky != 6000) zSky = 6000;
				}
			}

			if(i % 100 == 0) wait( [[level.ex_fpstime]](0.05) );
		}
	}

	// set the play area variables
	game["playArea_CentreX"] = int( (xMax + xMin) / 2 );
	game["playArea_CentreY"] = int( (yMax + yMin) / 2 );
	game["playArea_CentreZ"] = int( (zMax + zMin) / 2 );
	game["playArea_Centre"] = (game["playArea_CentreX"], game["playArea_CentreY"], game["playArea_CentreZ"]);

	game["playArea_Min"] = (xMin, yMin, zMin);
	game["playArea_Max"] = (xMax, yMax, zMax);

	game["playArea_Width"] = int(distance((xMin, yMin, 800),(xMax, yMin, 800)));
	game["playArea_Length"] = int(distance((xMin, yMin, 800),(xMin, yMax, 800)));

	// get centre map origin, just below skylimit
	origin = (game["playArea_CentreX"], game["playArea_CentreY"], zSky - 200);

	// get min and max values for x and y for map area
	trace = bulletTrace(origin, origin - (20000,0,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][0] < xMin) xMin = trace["position"][0];

	trace = bulletTrace(origin, origin + (20000,0,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][0] > xMax) xMax = trace["position"][0];

	trace = bulletTrace(origin, origin - (0,20000,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][1] < yMin) yMin = trace["position"][1];

	trace = bulletTrace(origin, origin + (0,20000,0), false, undefined);
	if(trace["fraction"] != 1 && trace["position"][1] > yMax) yMax = trace["position"][1];

	// set the map area variables
	game["mapArea_CentreX"] = int( (xMax + xMin) / 2 );
	game["mapArea_CentreY"] = int( (yMax + yMin) / 2 );
	game["mapArea_CentreZ"] = int( (zSky + zMin) / 2 );
	game["mapArea_Centre"] = (game["mapArea_CentreX"], game["mapArea_CentreY"], game["mapArea_CentreZ"]);

	game["mapArea_Max"] = (xMax, yMax, zSky);
	game["mapArea_Min"] = (xMin, yMin, zMin);

	game["mapArea_Width"] = int(distance((xMin, yMin, zSky),(xMax, yMin, zSky)));
	game["mapArea_Length"] = int(distance((xMin, yMin, zSky),(xMin, yMax, zSky)));

	if(debug)
	{
		took = (getTime() - mark) / 1000;
		logprint("DEBUG: getMapDim took " + took + " seconds\n");

		ne = (game["mapArea_Max"][0] - 200,game["mapArea_Min"][1] - 200,game["mapArea_Max"][2] - 200);
		se = (game["mapArea_Min"][0] - 200,game["mapArea_Min"][1] - 200,game["mapArea_Max"][2] - 200);
		sw = (game["mapArea_Min"][0] - 200,game["mapArea_Max"][1] - 200,game["mapArea_Max"][2] - 200);
		nw = (game["mapArea_Max"][0] - 200,game["mapArea_Max"][1] - 200,game["mapArea_Max"][2] - 200);
		logprint("DEBUG: ne=" + ne + ", se=" + se + ", sw=" + sw + ", nw=" + nw + ", mapheight=" + game["mapArea_Max"][2] + "\n");
		thread dropLine(ne, se, (1,0,0), 0);
		thread dropLine(se, sw, (1,0,0), 0);
		thread dropLine(sw, nw, (1,0,0), 0);
		thread dropLine(nw, ne, (1,0,0), 0);

		ne = (game["playArea_Max"][0],game["playArea_Min"][1],game["mapArea_Max"][2] - 200);
		se = (game["playArea_Min"][0],game["playArea_Min"][1],game["mapArea_Max"][2] - 200);
		sw = (game["playArea_Min"][0],game["playArea_Max"][1],game["mapArea_Max"][2] - 200);
		nw = (game["playArea_Max"][0],game["playArea_Max"][1],game["mapArea_Max"][2] - 200);
		logprint("DEBUG: ne=" + ne + ", se=" + se + ", sw=" + sw + ", nw=" + nw + ", playheight=" + game["playArea_Max"][2] + "\n");
		thread dropLine(ne, se, (1,0,0), 0);
		thread dropLine(se, sw, (1,0,0), 0);
		thread dropLine(sw, nw, (1,0,0), 0);
		thread dropLine(nw, ne, (1,0,0), 0);

		logprint("DEBUG: game[\"playArea_CentreX\"] = " + game["playArea_CentreX"] + "\n");
		logprint("DEBUG: game[\"playArea_CentreY\"] = " + game["playArea_CentreY"] + "\n");
		logprint("DEBUG: game[\"playArea_CentreZ\"] = " + game["playArea_CentreZ"] + "\n");
		logprint("DEBUG: game[\"playArea_Centre\"] = " + game["playArea_Centre"] + "\n");
		logprint("DEBUG: game[\"playArea_Max\"] = " + game["playArea_Max"] + "\n");
		logprint("DEBUG: game[\"playArea_Min\"] = " + game["playArea_Min"] + "\n");
		logprint("DEBUG: game[\"playArea_Width\"] = " + game["playArea_Width"] + "\n");
		logprint("DEBUG: game[\"playArea_Length\"] = " + game["playArea_Length"] + "\n");

		logprint("DEBUG: game[\"mapArea_CentreX\"] = " + game["mapArea_CentreX"] + "\n");
		logprint("DEBUG: game[\"mapArea_CentreY\"] = " + game["mapArea_CentreY"] + "\n");
		logprint("DEBUG: game[\"mapArea_CentreZ\"] = " + game["mapArea_CentreZ"] + "\n");
		logprint("DEBUG: game[\"mapArea_Centre\"] = " + game["mapArea_Centre"] + "\n");
		logprint("DEBUG: game[\"mapArea_Max\"] = " + game["mapArea_Max"] + "\n");
		logprint("DEBUG: game[\"mapArea_Min\"] = " + game["mapArea_Min"] + "\n");
		logprint("DEBUG: game[\"mapArea_Width\"] = " + game["mapArea_Width"] + "\n");
		logprint("DEBUG: game[\"mapArea_Length\"] = " + game["mapArea_Length"] + "\n");
	}

	entities = [];
	entities = undefined;
}

getStance(checkjump)
{
	if(checkjump && !self isOnGround()) return 3; // jumping

	if(!isDefined(self.ex_newmodel))
	{
		if(isDefined(self.ex_spinemarker))
		{
			dist = self.ex_spinemarker.origin[2] - self.origin[2];
			if(dist < level.ex_tune_prone) return 2; // prone
				else if(dist < level.ex_tune_crouch) return 1; // crouch
		}
	}

	return 0; // standing
}

getMax( a, b, c, d )
{
	if( a > b ) ab = a;
	else ab = b;

	if( c > d ) cd = c;
	else cd = d;

	if( ab > cd ) m = ab;
	else m = cd;

	return m;
}

popObject()
{
	origin_org = self.origin;
	vVelocity = [[level.ex_vectorscale]](anglesToForward((-85,0,0)), 15);

	traced = false;
	for(;;)
	{
		vVelocity += (0,0,-2);
		origin_new = self.origin + vVelocity;
		if(origin_new[2] <= origin_org[2])
		{
			if(!traced)
			{
				traced = true;
				// no fancy tracking; just a one-shot trace straight down
				trace = bullettrace(self.origin + (0,0,5), self.origin - (0,0,10000), false, self);
				if(trace["fraction"] != 1)
				{
					if(isDefined(trace["entity"]))
					{
						// hitting a dead player's cloned body
						if(isDefined(trace["entity"].classname) && trace["entity"].classname == "noclass")
							trace = bullettrace(trace["position"], self.origin - (0,0,10000), false, trace["entity"]);
					}
					// only adjust if lower; it's not supposed to go up again
					if(trace["position"][2] < origin_org[2]) origin_org = trace["position"];
						else break;
				}
				else break;
			}
			else break;
		}
		self.origin = origin_new;
		wait( [[level.ex_fpstime]](0.05) );
	}

	self.origin = (origin_new[0], origin_new[1], origin_org[2]);
}

placeObject()
{
	trace = bullettrace(self.origin + (0,0,5), self.origin - (0,0,10000), false, self);
	if(trace["fraction"] != 1)
	{
		if(isDefined(trace["entity"]))
		{
			// hitting a dead player's cloned body
			if(isDefined(trace["entity"].classname) && trace["entity"].classname == "noclass")
				trace = bullettrace(trace["position"], self.origin - (0,0,10000), false, trace["entity"]);
		}
		// only adjust if lower; it's not supposed to go up again
		if(trace["position"][2] < self.origin[2]) self.origin = trace["position"];
	}
}

bounceObject(direction, speed, rotation, bounceability, impactsound, objectradius)
{
	vVelocity = [[level.ex_vectorscale]](direction, speed);

	pitch = rotation[0] * 0.05;
	yaw = rotation[1] * 0.05;
	roll = rotation[2] * 0.05;

	iLoop = 0;
	iLoopMax = 200; // max 10 seconds

	for(;;)
	{
		wait(0.05);

		iLoop++;
		if(iLoop == iLoopMax) break;

		vVelocity += (0,0,-2);
		neworigin = self.origin + vVelocity;
		newangles = self.angles + (pitch, yaw, roll);

		trace = bulletTrace(self.origin, neworigin, true, self);
		if(trace["fraction"] != 1)
		{
			ignore_entity = false;
			if(isDefined(trace["entity"]))
			{
				if(isPlayer(trace["entity"]) && iLoop < 3) ignore_entity = true;
					else if(isDefined(trace["entity"].classname) && trace["entity"].classname == "noclass") ignore_entity = true;
			}

			if(!ignore_entity)
			{
				vOldDirection = vectorNormalize(neworigin - self.origin);
				if(isDefined(objectradius)) self.origin = trace["position"] + [[level.ex_vectorscale]](vOldDirection, 0 - objectradius);
					else self.origin = trace["position"];
				vNewDirection = vOldDirection - [[level.ex_vectorscale]](trace["normal"], vectorDot(vOldDirection, trace["normal"]) * 2);

				vVelocity = [[level.ex_vectorscale]](vNewDirection, length(vVelocity) * bounceability);
				if(length(vVelocity) < 5) break;
				if(isDefined(impactsound) && length(vVelocity) > 10) self playSound(impactsound + trace["surfacetype"]);
				continue;
			}
		}

		self rotateto(newangles, .05, 0, 0);
		self moveto(neworigin, .05, 0, 0);
	}

	if(iLoop < iLoopMax)
	{
		self.angles = (0, self.angles[1], 0);
		trace = bullettrace(self.origin + (0,0,10), self.origin - (0,0,1000), false, self);
		if(isDefined(objectradius)) self.origin = trace["position"] + (0,0,(objectradius/2));
			else self.origin = trace["position"];
	}
}

debugAngles(impact, from, to)
{
	if(!isDefined(impact)) return;
	if(isDefined(from))
	{
		from = impact + [[level.ex_vectorscale]](from, -30);
		thread dropLine(impact, from, (0,1,0), 30);
	}
	if(isDefined(to))
	{
		to = impact + [[level.ex_vectorscale]](to, 30);
		thread dropLine(impact, to, (1,0,0), 30);
	}
}

myAnglesNormalize(angles)
{
	pitch = myAngleNormalize(angles[0]);
	yaw = myAngleNormalize(angles[1]);
	roll = myAngleNormalize(angles[2]);
	return( (pitch, yaw, roll) );
}

myAngleNormalize(angle)
{
	if(angle) while(angle >= 360) angle -= 360;
		else while(angle <= -360) angle += 360;
	return(angle);
}

hotSpot(radius, sMeansOfDeath, sWeapon)
{
	self endon("endhotspot");

	for(;;)
	{
		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if(isPlayer(players[i])) player = players[i];
			else continue;

			if(distance(self.origin, player.origin) > radius) continue;
			else player thread [[level.callbackPlayerDamage]](self, self, 5, 1, sMeansOfDeath, sWeapon, undefined, (0,0,0), "none", 0);
		}

		wait( [[level.ex_fpstime]](0.5) );
	}
}

scriptedfxradiusdamage(eAttacker, vOffset, sMeansOfDeath, sWeapon, iRange, iMaxDamage, iMinDamage, effect, surfacetype, quake, entignore, zignore, special)
{
	level endon("ex_gameover");

	if(!isDefined(vOffset)) vOffset = (0,0,0);
	if(!isDefined(special)) special = "false";
	
	iDFlags = 1;

	// set default surface fx to snow on winter maps and dirt on other maps
	if(level.ex_wintermap) surfacefx = "snow";
		else surfacefx = "dirt";

	if(isDefined(effect) && effect != "none")
	{
		if(isDefined(surfacetype))
		{
			switch(surfacetype)
			{
				case "beach":
				case "sand": surfacefx = "beach"; break;
				case "asphalt":
				case "metal":
				case "rock":
				case "gravel":
				case "plaster":
				case "default": surfacefx = "concrete"; break;
				case "mud":
				case "dirt":
				case "grass": surfacefx = "dirt"; break;
				case "snow":
				case "ice": surfacefx = "snow"; break;
				case "wood":
				case "bark": surfacefx = "wood"; break;
				case "water": surfacefx = "water"; break;
			}
		}

		if(effect == "generic") playfx(level.ex_effect["explosion_" + surfacefx], self.origin);
			else if(special == "false") playfx(level.ex_effect[effect], self.origin);

		if(special == "napalm" && sWeapon == "planebomb_mp")
		{
			playfx(level.ex_effect["napalm_bomb"], self.origin);
			wait( [[level.ex_fpstime]](0.25) );
			playfx(level.ex_effect["fire_ground"], self.origin);
		}

		if(level.ex_wintermap && sWeapon == "planebomb_mp") thread scriptedfxdelay("explosion_snow", 1.5, self.origin);
	}
	
	if(quake)
	{
		peqs = randomInt(100);
		strength = 0.5 + 0.5 * peqs /100;
		length = 1 + 3*peqs/100;;
		range = iRange + iRange * peqs/100;
		earthquake(strength, length, self.origin, range);		
	}
	
	if(iMaxDamage == 0 && iMinDamage == 0) return;
	
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || !isAlive(player) || player.sessionstate != "playing") continue;

		// bubble protection
		if(isDefined(player.ex_bubble_protected)) continue;

		// radius protection for player in gunship
		if((level.ex_gunship && isPlayer(level.gunship.owner) && level.gunship.owner == player) ||
			 (level.ex_gunship_special && isPlayer(level.gunship_special.owner) && level.gunship_special.owner == player)) continue;

		// not in range
		distance = distance((self.origin + vOffset), player.origin);
		if(distance >= iRange) continue;

		if(player != self)
		{
			percent = (iRange - distance) / iRange;
			iDamage = (iMinDamage + (iMaxDamage - iMinDamage)) * percent;

			offset = 0;
			stance = player [[level.ex_getStance]](false);
			switch(stance)
			{
				case 2:	offset = (0,0,5);	break;
				case 1:	offset = (0,0,35);	break;
				case 0:	offset = (0,0,55);	break;
			}

			traceorigin = player.origin + offset;
			vDir = vectorNormalize(traceorigin - (self.origin + vOffset));

			if(special != "nuke")
			{
				if(isPlayer(self)) trace = bullettrace(self.origin + vOffset, traceorigin, true, self);
					else trace = bullettrace(self.origin + vOffset, traceorigin, true, eAttacker);

				if(trace["fraction"] != 1 && isDefined(trace["entity"]))
				{
					if(isPlayer(trace["entity"]) && trace["entity"] != player && trace["entity"] != eAttacker)
						iDamage = iDamage * .5; // Damage blocked by other player, remove 50%
				}
				else
				{
					trace = bulletTrace(self.origin + vOffset, traceorigin, false, undefined);
					if(trace["fraction"] != 1 && trace["surfacetype"] != "default")
						iDamage = iDamage * .2; // Damage blocked by other entities, remove 80%
				}
			}
		}
		else
		{
			iDamage = iMaxDamage;
			vDir = (0,0,1);
		}

		if(special == "napalm") player thread napalmDamage(eAttacker);
		else
		{
			if(isPlayer(eAttacker) && eAttacker != player && special == "kamikaze" && iDamage >= player.health)
			{
				if(!isDefined(eAttacker.kamikaze_victims)) eAttacker.kamikaze_victims = 0;
				eAttacker.kamikaze_victims++;
			}
			player thread [[level.callbackPlayerDamage]](self, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, undefined, vDir, "none", 0);
		}
	}
}

scriptedfxdelay(effect, delay, pos)
{
	wait( [[level.ex_fpstime]](delay) );
	playfx(level.ex_effect[effect], pos);
}

strToIntArray(str, defint)
{
	info[0] = defint;
	info[1] = defint;
	info[2] = defint;
	info[3] = defint;

	if(!isDefined(str) || !str.size) return(info);

	str_array = strtok(str, ",");
	if(isDefined(str_array) && str_array.size)
	{
		if(isDefined(str_array[0])) info[0] = strToIntDef(str_array[0], defint);
		if(isDefined(str_array[1])) info[1] = strToIntDef(str_array[1], defint);
		if(isDefined(str_array[2])) info[2] = strToIntDef(str_array[2], defint);
		if(isDefined(str_array[3])) info[3] = strToIntDef(str_array[3], defint);
	}

	return(info);
}

strToInt(str)
{
	if(!isDefined(str) || !str.size) return(0);

	ctoi = [];
	ctoi["0"] = 0;
	ctoi["1"] = 1;
	ctoi["2"] = 2;
	ctoi["3"] = 3;
	ctoi["4"] = 4;
	ctoi["5"] = 5;
	ctoi["6"] = 6;
	ctoi["7"] = 7;
	ctoi["8"] = 8;
	ctoi["9"] = 9;

	val = 0;
	for(i = 0; i < str.size; i++)
	{
		switch(str[i])
		{
			case "0":
			case "1":
			case "2":
			case "3":
			case "4":
			case "5":
			case "6":
			case "7":
			case "8":
			case "9":
				val = val * 10 + ctoi[str[i]];
				break;
			default:
				return(0);
		}
	}

	return(val);
}

strToIntDef(str, defint)
{
	if(!isDefined(defint)) defint = 0;
	if(!isDefined(str) || str == "") return(defint);

	validchars = "-0123456789";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return(defint);

	return(int(str));
}

justNumbers(str)
{
	if(!isDefined(str) || str == "") return "";

	validchars = "0123456789";
	string = "";

	for(i = 0; i < str.size; i++)
	{
		chr = str[i];
		for(j = 0; j < validchars.size; j++)
			if(chr == validchars[j]) string += validchars[j];
	}

	return string;
}

justAlphabet(str)
{
	if(!isDefined(str) || str == "") return "";

	uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	lowercase = "abcdefghijklmnopqrstuvwxyz";

	string = "";
	
	for(i = 0; i < str.size; i++)
	{
		chr = str[i];

		for(j = 0; j < uppercase.size; j++)
		{
			if(chr == uppercase[j]) string += uppercase[j];
			else if(chr == lowercase[j]) string += lowercase[j];
		}
	}

	return string;
}

playersInRange(range)
{
	if(!isDefined(range) || !range) return false;

	info["inrange_friendly"] = false;
	info["inrange_enemies"] = false;
	info["closest_enemy"] = undefined;

	closest_enemy_dist = 100000;
	targetpos = self getMultipliedRange(range, 5);

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!isPlayer(self)) break;

		player = players[i];
		if(!isPlayer(player) || player == self || player.sessionstate != "playing") continue;

		if(player.pers["team"] == self.pers["team"])
		{
			if( (distance(self.origin, player.origin) <= range) || (isDefined(targetpos) && distance(targetPos, player.origin) <= range * 2) )
				info["inrange_friendly"] = true;
		}
		else if(isDefined(targetpos))
		{
			dist = distance(targetPos, player.origin);
			if(dist <= range * 2)
			{
				info["inrange_enemies"] = true;
				if(!isDefined(info["closest_enemy"])) info["closest_enemy"] = player;
					else if(dist < closest_enemy_dist) info["closest_enemy"] = player;
			}
		}
	}

	return info;
}

getMultipliedRange(range, multiplier)
{
	startOrigin = self.origin;
	forward = anglesToForward(self getplayerangles());
	forward = [[level.ex_vectorscale]](forward, range * multiplier);
	endOrigin = startOrigin + forward;
	return endOrigin;
}

printOnPlayersInRange(owner, msg1, msg2, targetpos)
{
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(isAlive(player) && player != owner && player.pers["team"] == owner.pers["team"])
		{
			// only play the warning if they are close to the strike area
			dist = distance( player.origin, targetpos );
			if(dist < 1000)
			{
				player iprintlnbold(msg1, [[level.ex_pname]](owner));
				player iprintlnbold(msg2);
			}
		}
	}
}

trim(s)
{
	if(s == "") return "";

	s2 = "";
	s3 = "";

	i = 0;
	while( (i < s.size) && (s[i] == " ") ) i++;

	if(i==s.size) return "";

	for(; i < s.size; i++) s2 += s[i];

	i = s2.size - 1;
	while( (s2[i] == " ") && (i > 0) ) i--;

	for(j = 0; j <= i; j++) s3 += s2[j];

	return s3;
}

numToStr(number, length)
{
	string = "" + number;
	if(string.size > length) length = string.size;
	diff = length - string.size;
	if(diff) for(i = 0; i < diff; i++) string = " " + string;
	return(string);
}

explode(str, delimiter)
{
	j = 0;
	temp_array[j] = "";	

	for(i = 0; i < str.size; i++)
	{
		if(str[i] == delimiter)
		{
			j++;
			temp_array[j] = "";
		}
		else temp_array[j] += str[i];
	}

	return temp_array;
}

convertMLJ(string)
{
	string = monotone(string);
	string = tolower(string);
	string = justalphabet(string);
	return string;
}

weaponPause(time)
{
	self endon("kill_thread");

	self [[level.ex_dWeapon]]();
	wait( [[level.ex_fpstime]](time) );
	if(isPlayer(self)) self [[level.ex_eWeapon]]();
}

weaponWeaken(time)
{
	self endon("kill_thread");

	self.ex_weakenweapon = true;
	wait( [[level.ex_fpstime]](time) );
	if(isPlayer(self)) self.ex_weakenweapon = undefined;
}

napalmDamage(eAttacker)
{
	self endon("kill_thread");

	// Respect friendly fire settings 0 (off) and 2 (reflect; it doesn't damage the attacker though)
	friendly = false;
	if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
		if(isPlayer(eAttacker) && eAttacker.pers["team"] == self.pers["team"]) friendly = true;

	// prevent damage and burning effects when frozen in freezetag
	if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") return;

	// burn them
	if(isPlayer(self) && !friendly) self extreme\_ex_punishments::doTorch(true, eAttacker);

	// play flame on dead body & make sure they die!
	if(isPlayer(self))
	{
		if(!friendly) playfx(level.ex_effect["fire_ground"], self.origin);
		self thread [[level.callbackPlayerDamage]](eAttacker, eAttacker, 1000, 1, "MOD_PROJECTILE", "planebomb_mp", undefined, (0,0,1), "none", 0);
	}
}

execClientCommand(cmd)
{
	self setClientCvar("clientcmd", cmd);
	self openMenuNoMouse(game["menu_clientcmd"]);
	self closeMenu(game["menu_clientcmd"]);
}

waittill_multi(str_multi)
{
	array = strtok(str_multi, " ");
	for (i = 0; i < array.size; i ++)
		self thread waittill_multi_thread(str_multi, array[i]);

	self waittill(str_multi);
}

waittill_multi_thread(str_multi, str)
{
	self endon(str_multi);
	self waittill(str);
	self notify(str_multi);
}

storeServerInfoDvar(dvar)
{
	if(!isDefined (game["serverinfodvar"]))
		game["serverinfodvar"] = [];

	game["serverinfodvar"][game["serverinfodvar"].size] = dvar;
}

forceto(stance)
{
	if(stance == "stand") self thread execClientCommand("+gostand;-gostand");
	else if(stance == "crouch" || stance == "duck") self thread execClientCommand("gocrouch");
	else if(stance == "prone") self thread execClientCommand("goprone");
}

_fpsTime(time)
{
	return(level.ex_fps_multiplier * time);
}

_disableWeapon()
{
	if(!isDefined(self.ex_disabledWeapon)) self.ex_disabledWeapon = 0;
	self.ex_disabledWeapon++;

	// bots don't like disableWeapon(), so we have to hack our way around it
	if(isDefined(self.pers["isbot"]))
	{
		// save the secondary, give them a dummy secondary and switch to it
		if(self.ex_disabledWeapon == 1)
		{
			if(!isDefined(self.weapon)) self.weapon = [];
			if(!isDefined(self.weapon["bot_primaryb"])) self.weapon["bot_primaryb"] = spawnstruct();
			self.weapon["bot_primaryb"].name = self getweaponslotweapon("primaryb");
			self.weapon["bot_primaryb"].clip = self getWeaponSlotClipAmmo("primaryb");
			self.weapon["bot_primaryb"].reserve = self getWeaponSlotAmmo("primaryb");
			self takeweapon(self.weapon["bot_primaryb"].name);
			self setweaponslotweapon("primaryb", "dummy3_mp");
			self setweaponslotclipammo("primaryb", 999);
			self setweaponslotammo("primaryb", 999);
			self setspawnweapon("dummy3_mp");
			self switchtoweapon("dummy3_mp");
		}
	}
	else self disableWeapon();

	extreme\_ex_weapons::debugLog(false, "_disableWeapon() finished"); // DEBUG
}

_enableWeapon()
{
	if(!isDefined(self.ex_disabledWeapon)) self.ex_disabledWeapon = 0;
	if(self.ex_disabledWeapon) self.ex_disabledWeapon--;

	if(!self.ex_disabledWeapon)
	{
		// restore secondary for bot and switch to primary
		if(isDefined(self.pers["isbot"]) && isDefined(self.weapon) && isDefined(self.weapon["bot_primaryb"]))
		{
			self takeweapon(self getweaponslotweapon("primaryb"));
			if(self.weapon["bot_primaryb"].name != "none")
			{
				self giveweapon(self.weapon["bot_primaryb"].name);
				self setweaponslotclipammo("primaryb", self.weapon["bot_primaryb"].clip);
				self setweaponslotammo("primaryb", self.weapon["bot_primaryb"].reserve);
				self setspawnweapon(self.weapon["primary"].name);
				self switchtoweapon(self.weapon["primary"].name);
			}
			else self setWeaponSlotWeapon("primaryb", "none");
		}
		else self enableWeapon();

		extreme\_ex_weapons::debugLog(true, "_enableWeapon() finished"); // DEBUG
	}
	else extreme\_ex_weapons::debugLog(false, "_enableWeapon() ignored"); // DEBUG
}

detectLogPlatform()
{
	version = getcvar("version");
	endstr = "";
	for (i = 0; i < 7; i ++) endstr += version[i + version.size - 7];
	level.IsLinuxServer = (endstr != "win-x86");

	if(level.IsLinuxServer) logprint("SERVER RUNNING ON LINUX (version string: " + version + ")\n");
		else logprint("SERVER RUNNING ON WINDOWS (version string: " + version + ")\n");

	if(level.ex_logplatform == 1) level.IsLinuxServer = false; // force Windows
	if(level.ex_logplatform == 2) level.IsLinuxServer = true;  // force Linux
}

pname(player)
{
	if(level.IsLinuxServer) return player.name;
		else return player;
}

iprintlnboldCLEAR(state, lines)
{
	for(i = 0; i < lines; i++)
	{
		if(state == "all") iprintlnbold(&"MISC_BLANK_LINE_TXT");
			else if(state == "self") self iprintlnbold(&"MISC_BLANK_LINE_TXT");
	}
}

sanitizeName(str)
{
	if(!isDefined(str) || str == "") return "";

	validchars = "!()+,-.0123456789;=@AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz_{}~";

	tmpname = extreme\_ex_utils::monotone(str);
	string = "";
	prevchr = "";
	for(i = 0; i < tmpname.size; i++)
	{
		chr = tmpname[i];
		if(chr == ".")
		{
			if(!string.size) continue; // avoid leading dots
			if(chr == prevchr) continue; // avoid double dots
		}
		else if(chr == "[") chr = "{";
		else if(chr == "]") chr = "}";

		for(j = 0; j < validchars.size; j++)
		{
			if(chr == validchars[j])
			{
				string += chr;
				prevchr = chr;
				break;
			}
		}
	}

	if(string == "") string = "noname";
	return string;
}

atof(str)
{
	if((!isDefined(str)) || (!str.size))
		return(0);

	switch(str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	str2 = getsubstr(str, offset);
	parts = strtok(str2, ".");

	intpart = atoi(parts[0]);
	decpart = atoi(parts[1]);

	if(decpart < 0)
		return(0);

	if(decpart)
		for(i = 0; i < parts[1].size; i ++)
			decpart = decpart / 10;

	return((intpart + decpart) * sign);
}

atoi(str)
{
	if((!isDefined(str)) || (!str.size))
		return(0);

	ctoi = [];
	ctoi["0"] = 0;
	ctoi["1"] = 1;
	ctoi["2"] = 2;
	ctoi["3"] = 3;
	ctoi["4"] = 4;
	ctoi["5"] = 5;
	ctoi["6"] = 6;
	ctoi["7"] = 7;
	ctoi["8"] = 8;
	ctoi["9"] = 9;

	switch(str[0])
	{
		case "+" :
			sign = 1;
			offset = 1;
			break;
		case "-" :
			sign = -1;
			offset = 1;
			break;
		default :
			sign = 1;
			offset = 0;
			break;
	}

	val = 0;

	for(i = offset; i < str.size; i ++)
	{
		switch(str[i])
		{
			case "0" :
			case "1" :
			case "2" :
			case "3" :
			case "4" :
			case "5" :
			case "6" :
			case "7" :
			case "8" :
			case "9" :
				val = val * 10 + ctoi[str[i]];
				break;
			default :
				return(0);
		}
	}

	return(val * sign);
}

dropLine(start, stop, linecolor, seconds)
{
	if(!isDefined(seconds)) seconds = 10;

	if(seconds) ticks = int(seconds * level.ex_fps);
		else ticks = level.MAX_SIGNED_INT;

	while(ticks > 0)
	{
		line(start, stop, linecolor);
		wait(level.ex_fps_frame);
		ticks--;
	}
}

dropText(origin, text, seconds, color, alpha, scale)
{
	if(!isDefined(seconds)) seconds = 10;
	if(!isDefined(color)) color = (0,1,0);
	if(!isDefined(alpha)) alpha = 1;
	if(!isDefined(scale)) scale = 0.3;

	if(seconds) ticks = int(seconds * level.ex_fps);
		else ticks = level.MAX_SIGNED_INT;

	while(ticks > 0)
	{
		print3d(origin, text, color, alpha, scale);
		wait(level.ex_fps_frame);
		ticks--;
	}
}

dropTheFlag(findnewspot)
{
	self endon("disconnect");

	if(level.ex_flagbased)
	{
		if(!isDefined(findnewspot)) findnewspot = false;

		if(isDefined(self.flag))
		{
			dropspot = undefined;
			if(findnewspot) dropspot = self getDropSpot(100);

			switch(level.ex_currentgt)
			{
				case "ctf":
				self thread maps\mp\gametypes\_ex_ctf::dropFlag(dropspot);
				break;

				case "ctfb":
				self thread maps\mp\gametypes\_ex_ctfb::dropFlag(dropspot);
				break;

				case "ihtf":
				self thread maps\mp\gametypes\_ex_ihtf::dropFlag(dropspot);
				break;

				case "htf":
				self thread maps\mp\gametypes\_ex_htf::dropFlag(dropspot);
				break;

				case "rbctf":
				self thread maps\mp\gametypes\_ex_rbctf::dropFlag(dropspot);
				break;
			}
		}

		if(isDefined(self.ownflag))
		{
			dropspot = undefined;
			if(findnewspot) dropspot = self getDropSpot(100);

			switch(level.ex_currentgt)
			{
				case "ctfb":
				self thread maps\mp\gametypes\_ex_ctfb::dropOwnFlag(dropspot);
				break;
			}
		}
	}
}

getDropSpot(radius)
{
	origin = self.origin + (0, 0, 20);
	dropspot = undefined;

	// scan 360 degrees in 20 degree increments for good spot to drop flag
	for(i = 0; i < 360; i += 20)
	{
		// locate candidate spot in circle
		spot0 = origin + [[level.ex_vectorscale]](anglestoforward((0, i, 0)), radius);
		trace = bulletTrace(origin, spot0, false, undefined);
		spot1 = trace["position"];
		dist1 = int(distance(origin, spot1) + 0.5);
		if(dist1 != radius) continue;

		// check if this spot is in minefield (unfortunately needs entity to check)
		badspot = false;
		model1 = spawn("script_model", spot1);
		model1 setmodel("xmodel/tag_origin");
		for(j = 0; j < level.ex_returners.size; j++)
		{
			if(model1 istouching(level.ex_returners[j]))
			{
				badspot = true;
				break;
			}
		}
		model1 delete();
		if(badspot) continue;

		// find ground level
		trace = bulletTrace(spot1, spot1 + (0, 0, -2000), false, undefined);
		spot2 = trace["position"];
		dist2 = int(distance(spot1, spot2) + 0.5);

		// make sure path is clear 50 units up
		trace = bulletTrace(spot2, spot2 + (0, 0, 50), false, undefined);
		spot3 = trace["position"];
		dist3 = int(distance(spot2, spot3) + 0.5);
		if(dist3 != 50) continue;

		dropspot = spot2;
		break;
	}

	return dropspot;
}

spawnpointArray()
{
	level.ex_current_spawnpoints = [];

	// get the names of the current spawnpoints
	spawnpointnames = [];

	switch(level.ex_currentgt)
	{
		case "chq":
		case "cnq":
		case "ft":
		case "hq":
		case "htf":
		case "lts":
		case "rbcnq":
		case "tdm":
		case "vip":
			spawnpointnames[spawnpointnames.size] = "mp_tdm_spawn";
			break;

		case "ctf":
		case "rbctf":
			spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_allied";
			spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_axis";
			break;

		case "ctfb":
			if(!level.random_flag_position)
			{
				spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_allied";
				spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_axis";
			}
			else spawnpointnames[spawnpointnames.size] = "mp_dm_spawn";
			break;

		case "dm":
		case "hm":
		case "lms":
			spawnpointnames[spawnpointnames.size] = "mp_dm_spawn";
			break;

		case "esd":
		case "sd":
			spawnpointnames[spawnpointnames.size] = "mp_sd_spawn_attacker";
			spawnpointnames[spawnpointnames.size] = "mp_sd_spawn_defender";
			break;

		case "ihtf":
			spawntype_array = strtok(level.playerspawnpointsmode, " ");
			spawntype_active = [];
			for(i = 0; i < spawntype_array.size; i ++)
			{
				switch(spawntype_array[i])
				{
					case "dm" :
					case "tdm" :
					case "ctfp" :
					case "ctff" :
					case "sdp" :
					case "sdb" :
					case "hq" :
						spawntype_active[spawntype_array[i]] = true;
					break;
				}
			}

			if(isDefined(spawntype_active["dm"]))
				spawnpointnames[spawnpointnames.size] = "mp_dm_spawn";
			if(isDefined(spawntype_active["tdm"]) || isDefined(spawntype_active["hq"]))
				spawnpointnames[spawnpointnames.size] = "mp_tdm_spawn";
			if(isDefined(spawntype_active["ctfp"]))
			{
				spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_allied";
				spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_axis";
			}
			if(isDefined(spawntype_active["sdp"]))
			{
				spawnpointnames[spawnpointnames.size] = "mp_sd_spawn_attacker";
				spawnpointnames[spawnpointnames.size] = "mp_sd_spawn_defender";
			}
			break;

		case "lib":
			spawnpointnames[spawnpointnames.size] = "mp_lib_spawn_alliesnonjail";
			spawnpointnames[spawnpointnames.size] = "mp_lib_spawn_axisnonjail";
			spawnpointnames[spawnpointnames.size] = "mp_lib_spawn_alliesinjail";
			spawnpointnames[spawnpointnames.size] = "mp_lib_spawn_axisinjail";
			break;

		case "dom":
		case "ons":
			switch(level.spawntype)
			{
				case "tdm":
					spawnpointnames[spawnpointnames.size] = "mp_tdm_spawn";
					break;
				case "sd":
					spawnpointnames[spawnpointnames.size] = "mp_sd_spawn_attacker";
					spawnpointnames[spawnpointnames.size] = "mp_sd_spawn_defender";
					break;
				case "ctf":
					spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_allied";
					spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_axis";
					break;
				default:
					spawnpointnames[spawnpointnames.size] = "mp_dm_spawn";
					break;
			}
			break;

		case "tkoth":
			switch(level.spawn)
			{
				case "tkoth":
					spawnpointnames[spawnpointnames.size] = "mp_tkoth_spawn_allied";
					spawnpointnames[spawnpointnames.size] = "mp_tkoth_spawn_axis";
					break;
				case "sd":
					spawnpointnames[spawnpointnames.size] = "mp_sd_spawn_attacker";
					spawnpointnames[spawnpointnames.size] = "mp_sd_spawn_defender";
					break;
				case "ctf":
					spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_allied";
					spawnpointnames[spawnpointnames.size] = "mp_ctf_spawn_axis";
					break;
			}
			break;
	}

	// find and store all stock spawnpoints
	for(i = 0; i < spawnpointnames.size; i++)
	{
		spawnpoints = getentarray(spawnpointnames[i], "classname");
		for(j = 0; j < spawnpoints.size; j++)
			level.ex_current_spawnpoints[level.ex_current_spawnpoints.size] = spawnpoints[j];
	}

	// if available, add all custom spawnpoints (only if origin is available)
	if(isDefined(level.ex_spawnpoints))
	{
		for(i = 0; i < level.ex_spawnpoints.size; i++)
		{
			if(isDefined(level.ex_spawnpoints[i].origin))
				level.ex_current_spawnpoints[level.ex_current_spawnpoints.size] = level.ex_spawnpoints[i];
		}
	}
}

tooClose(checkspawn, checkobj, checkturret, checkperk, report)
{
	self endon("kill_thread");

	if(!isDefined(checkspawn)) checkspawn = 150;
	if(!isDefined(checkobj)) checkobj = 150;
	if(!isDefined(checkturret)) checkturret = 150;
	if(!isDefined(checkperk)) checkperk = 150;
	if(!isDefined(report)) report = true;

	// Check spawnpoints
	if(checkspawn)
	{
		// if it doesn't exist, create spawnpoints array first
		if(!isDefined(level.ex_current_spawnpoints)) spawnpointArray();

		for(i = 0; i < level.ex_current_spawnpoints.size; i++)
		{
			if(distance(self.origin, level.ex_current_spawnpoints[i].origin) < checkspawn)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_SPAWN");
						else self iprintlnbold(&"MISC_TOO_CLOSE_SPAWN");
				}
				return true;
			}
		}
	}

	// Check turrets
	if(checkturret)
	{
		turrets = getentarray("misc_turret", "classname");
		for(i = 0; i < turrets.size; i++)
		{
			if(isDefined(turrets[i]) && distance(self.origin, turrets[i].origin) < checkturret)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_TURRET");
						else self iprintlnbold(&"MISC_TOO_CLOSE_TURRET");
				}
				return(true);
			}
		}

		turrets = getentarray("misc_mg42", "classname");
		for(i = 0; i < turrets.size; i++)
		{
			if(isDefined(turrets[i]) && distance(self.origin, turrets[i].origin) < checkturret)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_TURRET");
						else self iprintlnbold(&"MISC_TOO_CLOSE_TURRET");
				}
				return(true);
			}
		}
	}

	// Check perks
	if(checkperk)
	{
		// check bear traps
		if(isDefined(level.beartraps))
		{
			for(i = 0; i < level.beartraps.size; i++)
			{
				if(level.beartraps[i].inuse && distance(self.origin, level.beartraps[i].origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check defense bubbles
		if(isDefined(level.bubbles))
		{
			for(i = 0; i < level.bubbles.size; i++)
			{
				if(level.bubbles[i].inuse && distance(self.origin, level.bubbles[i].origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check insertions
		if(isDefined(level.insertions))
		{
			for(i = 0; i < level.insertions.size; i++)
			{
				if(level.insertions[i].inuse && distance(self.origin, level.insertions[i].origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check sentry guns
		if(isDefined(level.sentryguns))
		{
			for(i = 0; i < level.sentryguns.size; i++)
			{
				if(level.sentryguns[i].inuse && distance(self.origin, level.sentryguns[i].org_origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check missile launchers
		if(isDefined(level.gmls))
		{
			for(i = 0; i < level.gmls.size; i++)
			{
				if(level.gmls[i].inuse && distance(self.origin, level.gmls[i].org_origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}

		// check flak vierling
		if(isDefined(level.flaks))
		{
			for(i = 0; i < level.flaks.size; i++)
			{
				if(level.flaks[i].inuse && distance(self.origin, level.flaks[i].org_origin) < checkperk)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_PERK");
							else self iprintlnbold(&"MISC_TOO_CLOSE_PERK");
					}
					return(true);
				}
			}
		}
	}

	// Check objectives
	if(checkobj)
	{
		// check bomb zones
		if(level.ex_currentgt == "esd")
		{
			if(isDefined(level.bombmodel))
			{
				for(i = 0; i < level.bombmodel.size; i++)
				{
					if(isDefined(level.bombmodel[i]) && distance(self.origin, level.bombmodel[i].origin) < checkobj)
					{
						if(report)
						{
							if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
								else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
						}
						return true;
					}
				}
			}
			return false;
		}

		if(level.ex_currentgt == "sd")
		{
			if(isDefined(level.bombmodel))
			{
				if(distance(self.origin, level.bombmodel.origin) < checkobj)
				{
					if(report)
					{
						if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
							else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
					}
					return true;
				}
			}
			return false;
		}

		// check radio zone
		if(level.ex_currentgt == "chq" || level.ex_currentgt == "hq")
		{
			if(isDefined(level.radio))
			{
				for(i = 0; i < level.radio.size; i++)
				{
					if(!level.radio[i].hidden)
					{
						if(distance(self.origin, level.radio[i].origin) < checkobj)
						{
							if(report)
							{
								if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
									else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
							}
							return true;
						}
						return false;
					}
				}
			}
			return false;
		}

		// check flag zones
		if(level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
		{
			if(isDefined(level.flags))
			{
				for(i = 0; i < level.flags.size; i ++)
				{
					if(distance(self.origin, level.flags[i].origin) < checkobj)
					{
						if(report)
						{
							if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
								else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
						}
						return true;
					}
				}
			}
			return false;
		}

		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "ctfb")
		{
			_tooclose = false;
			flag = getent("allied_flag", "targetname");
			if(isDefined(flag) && isDefined(flag.home_origin) && distance(self.origin, flag.home_origin) < checkobj) _tooclose = true;

			if(!_tooclose)
			{
				flag = getent("axis_flag", "targetname");
				if(isDefined(flag) && isDefined(flag.home_origin) && distance(self.origin, flag.home_origin) < checkobj) _tooclose = true;
			}

			if(_tooclose)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
						else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
				}
				return true;
			}
			return false;
		}

		if(level.ex_currentgt == "htf" || level.ex_currentgt == "ihtf")
		{
			_tooclose = false;
			if(isDefined(level.flag) && isDefined(level.flag.home_origin) && distance(self.origin, level.flag.home_origin) < checkobj) _tooclose = true;

			if(_tooclose)
			{
				if(report)
				{
					if(report == 1) self iprintln(&"MISC_TOO_CLOSE_OBJ");
						else self iprintlnbold(&"MISC_TOO_CLOSE_OBJ");
				}
				return true;
			}
			return false;
		}
	}

	// If we get this far, there are no restrictions
	return false;
}
