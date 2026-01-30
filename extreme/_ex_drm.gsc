#include extreme\_ex_utils;

drm_init()
{
	level.drmlog = 0; // 0 = off, 1 = log some, 2 = log most, 3 = log all
	level.drmstat_readinit = 0;
	level.drmstat_readpost = 0;

	if(isDefined(game["drm_initdone"]))
	{
		// DRM already initialized, but called again: this must be a round based game
		// so make sure varcache will use the correct map sizing cvar
		game["ex_modstate"] = undefined;
		drm_mapsizing();
		return;
	}

	// process mod profiles
	game["profiles"] = [];

	profile_name = [[level.ex_cvardef]]("scr_profile_name_0", "", "", "", "string");
	if(profile_name == "") profile_name = "eXtreme+ Normal Configuration";
	game["profiles"][0] = spawnstruct();
	game["profiles"][0].name = profile_name;
	game["profiles"][0].dir = "";
	logprint("PROFILE: Profile 0, \"" + profile_name + "\" added to list (folder \"scriptdata\")\n");

	count = 1;
	for(;;)
	{
		profile_name = [[level.ex_cvardef]]("scr_profile_name_" + count, "", "", "", "string");
		if(profile_name == "") break;
		profile_dir = [[level.ex_cvardef]]("scr_profile_dir_" + count, "", "", "", "string");
		if(profile_dir == "") break;
		index = game["profiles"].size;
		game["profiles"][index] = spawnstruct();
		game["profiles"][index].name = profile_name;
		game["profiles"][index].dir = profile_dir;
		logprint("PROFILE: Profile " + index + ", \"" + profile_name + "\" added to list (folder \"scriptdata/" + profile_dir + "\")\n");
		if(game["profiles"].size == 6) break;
		count++;
	}

	game["profile_id"] = [[level.ex_cvardef]]("scr_profile_active", 0, 0, game["profiles"].size - 1, "int");
	game["profile_name"] = game["profiles"][game["profile_id"]].name;
	game["profile_dir"] = game["profiles"][game["profile_id"]].dir;
	logprint("PROFILE: Activated profile " + game["profile_id"] + ", \"" + game["profile_name"] + "\"\n");

	// process configuration files
	game["drm"] = [];

	for(i = 1; i <= 100; i ++)
	{
		dvar = "scr_drm_cfg_" + i;
		fName = getcvar(dvar);
		if(game["profile_dir"] != "") fName = game["profile_dir"] + "/" + fName;
		if(fName != "")
		{
			fHandle = openfile(fName, "read");
			if(fHandle != -1) drm_parsefile(fName, fHandle);
		}
	}

	fName = "developer.cfg";
	if(game["profile_dir"] != "") fName = game["profile_dir"] + "/" + fName;
	fHandle = openfile(fName, "read");
	if(fHandle != -1) drm_parsefile(fName, fHandle);

	game["drm_initdone"] = true;
	drm_mapsizing();
	logprint("DRM: " + game["drm"].size + " vars have been set\n");
}

fileExists(fName)
{
	fHandle = openfile(fName, "read");
	if(fHandle != -1) closefile(fHandle);
	return( (fHandle != -1) );
}

drm_mapsizing()
{
	// get the number of players for "small", "medium" and "large" extensions
	level.ex_drmplayers = 0;
	// if server just started, set number to startup preference
	if(getCvar("drm_players") == "")
	{
		if(drm_getcvar("ex_mapsizing_startup", false) != "") level.ex_drmplayers = drm_getCvarInt("ex_mapsizing_startup", false);
			else level.ex_drmplayers = 8;
		logprint("DRM: Server just started. Simulating " + level.ex_drmplayers + " players on request\n");
		setCvar("drm_players", level.ex_drmplayers);
	}
	else
	{
		// get the real number of players from the saved dvar
		level.ex_drmplayers = getCvarInt("drm_players");
		logprint("DRM: Server already running. Map sizing is based on " + level.ex_drmplayers + " players\n");
	}

	gametype = getcvar("g_gametype");
	mapname = getcvar("mapname");
	logprint("DRM: Variables will apply to game type \"" + gametype + "\" on map \"" + mapname + "\"\n");
}

// just a logprint + newline
drm_log(str, loglevel)
{
	if(!isDefined(loglevel)) loglevel = level.drmlog;
	if(level.drmlog >= loglevel) logprint(str + "\n");
}

// parse a config file
drm_parsefile(fName, fHandle)
{
	logprint("DRM: Reading config file " + fName + "\n");
	block_comment = false;

	for(;;)
	{
		elems = freadln(fHandle);
		
		if(elems == -1)
			break;
			
		if(elems == 0)
			continue;
	
		line = fgetarg(fHandle, 0);
		drm_log("Line read >" + line + "<", 1);
		
		if(block_comment && issubstr(line, "*/"))
		{
			drm_log("		block comment end -> ignored", 2);
			block_comment = false;
			continue;
		}

		if(block_comment)
		{
			drm_log("		still in block comment -> ignored", 2);
			continue;
		}

		if(!block_comment && getsubstr(line, 0, 2) == "/*")
		{
			drm_log("		block comment start -> ignored", 2);
			block_comment = true;
			continue;
		}

		if((getsubstr(line, 0, 2) == "//") || (getsubstr(line, 0, 1) == "#"))
		{
			drm_log("		line comment -> ignored", 2);
			continue;
		}

		cleanline = "";
		last = " ";
		
		for(i = 0; i < line.size; i ++)
		{
			drm_log("line[i] : >" + line[i] + "<", 3);
			switch(line[i])
			{
				case "	": // tab
				case " " : // space 0xa0
				case " " : // space 0x20
					if(last != " ")
					{
						drm_log("added space", 3);
						cleanline += " ";
						last = " ";
					}
					break;

				case "/" :
					if(last == "/")
					{
						drm_log("exiting", 3);
						cleanline = getsubstr(cleanline, 0, cleanline.size - 1);
						i = line.size; // exiting from loop
						break;
					}
					else
					{
						drm_log("adding slash", 3);
						cleanline += "/";
						last = "/";
					}
					break;

				case "#" :
					drm_log("exiting", 3);
					i = line.size; // exiting from loop
					break;

				default :
					drm_log("adding >" + line[i] + "<", 3);
					cleanline += line[i];
					last = line[i];
					break;
			}
		}

		if((cleanline.size >= 2) && (getsubstr(cleanline, cleanline.size - 2) == " /"))
		{
			// ends with " /"
			notsocleanline = cleanline;
			cleanline = getsubstr(notsocleanline, 0, notsocleanline.size - 2);
		}
		
		if((cleanline.size >= 1) && (cleanline[cleanline.size - 1] == " "))
		{
			// ends with " "
			notsocleanline = cleanline;
			cleanline = getsubstr(notsocleanline, 0, notsocleanline.size - 1);
		}
				
		if(cleanline == "")
		{
			drm_log("		nothing left -> ignored", 2);
			continue;
		}
	
		drm_log("		cleaned >" + cleanline + "<", 2);

		array = strtok(cleanline, " ");
		setcmd = array[0];
		
		if((setcmd != "set") && (setcmd != "seta") && (setcmd != "sets"))
		{
			if(!level.drmlog) logprint("DRM: Line >" + line + "<\n");
			logprint("DRM: does not begin with set, seta or sets -> ignored\n");
			continue;
		}
		
		if(array.size == 1)
		{
			logprint("DRM: Missing variable name -> ignored\n");
			continue;
		}
		
		var = toLower(array[1]);
		
		if(array.size == 2)
		{
			// value is undefined
			//logprint("DRM: Variable \"" + var + "\" has no value assigned\n");
			val = "";
		}
		else
		{
			// value is defined
			val = getsubstr(cleanline, setcmd.size + var.size + 2);
		}

		drm_log("		Variable \"" + var + "\" set to \"" + val + "\"", 1);

		game["drm"][var] = val;
	}

	closefile(fHandle);
}

// replacement for cvardef
drm_cvardef(varname, vardefault, min, max, type)
{
	// Initialization must be done on 1st call
	if(!isDefined(game["drm_initdone"])) drm_init();

	if(isDefined(game["precachedone"])) level.drmstat_readpost++;
		else level.drmstat_readinit++;

	basevar = varname;
	gametype = toLower(getcvar("g_gametype"));
	mapname = toLower(getcvar("mapname"));
	multigtmap = gametype + "_" + mapname;

	// first use the base variable to check for sizing overrides
	tempvar = basevar;

	// check for sizing extension override
	if(!isDefined(game["ex_modstate"]))
	{
		if(level.ex_drmplayers < level.ex_mapsizing_medium) tempvar = tempvar + "_small";
			else if(level.ex_drmplayers < level.ex_mapsizing_large) tempvar = tempvar + "_medium";
				else tempvar = tempvar + "_large";

		if(drm_getcvar(tempvar, false) != "") varname = tempvar;
	}

	// check for game type extension override
	tempvar = basevar + "_" + gametype;
	if(drm_getcvar(tempvar, false) != "") varname = tempvar;

	// check for game type + sizing extension override
	if(!isDefined(game["ex_modstate"]))
	{
		if(level.ex_drmplayers < level.ex_mapsizing_medium) tempvar = tempvar + "_small";
			else if(level.ex_drmplayers < level.ex_mapsizing_large) tempvar = tempvar + "_medium";
				else tempvar = tempvar + "_large";

		if(drm_getcvar(tempvar, false) != "") varname = tempvar;
	}

	// check for map extension override
	tempvar = basevar + "_" + mapname;
	if(drm_getcvar(tempvar, false) != "") varname = tempvar;

	// check for map + sizing extension override
	if(!isDefined(game["ex_modstate"]))
	{
		if(level.ex_drmplayers < level.ex_mapsizing_medium) tempvar = tempvar + "_small";
			else if(level.ex_drmplayers < level.ex_mapsizing_large) tempvar = tempvar + "_medium";
				else tempvar = tempvar + "_large";

		if(drm_getcvar(tempvar, false) != "") varname = tempvar;
	}

	// check for game type + map extension override
	tempvar = basevar + "_" + multigtmap;
	if(drm_getcvar(tempvar, false) != "") varname = tempvar;

	// check for game type + map + sizing extension override
	if(!isDefined(game["ex_modstate"]))
	{
		if(level.ex_drmplayers < level.ex_mapsizing_medium) tempvar = tempvar + "_small";
			else if(level.ex_drmplayers < level.ex_mapsizing_large) tempvar = tempvar + "_medium";
				else tempvar = tempvar + "_large";

		if(drm_getcvar(tempvar, false) != "") varname = tempvar;
	}

	// get the definition
	switch(type)
	{
		case "int":
			if(drm_getcvar(varname, false) == "") definition = vardefault;
				else definition = drm_getCvarInt(varname, false);
			break;
		case "float":
			if(drm_getcvar(varname, false) == "") definition = vardefault;
				else definition = drm_getCvarFloat(varname, false);
			break;
		case "string":
		default:
			if(drm_getcvar(varname, false) == "") definition = vardefault;
				else definition = drm_getcvar(varname, false);
			break;
	}

	// if int or float number, check if it violates the minimum
	if((type == "int" || type == "float") && definition < min)
	{
		logprint("DRM: Variable \"" + varname + "\" (" + definition + ") violates minimum (" + min + ")\n");
		definition = min;
	}

	// if int or float, check if it violates the maximum
	if((type == "int" || type == "float") && definition > max)
	{
		logprint("DRM: Variable \"" + varname + "\" (" + definition + ") violates maximum (" + max + ")\n");
		definition = max;
	}

	return(definition);
}

// replacement for getcvar
drm_getcvar(var, stats)
{
	if(!isDefined(stats)) stats = true;
	if(stats)
	{
		if(isDefined(game["precachedone"])) level.drmstat_readpost++;
			else level.drmstat_readinit++;
	}

	if(isDefined(game["drm"][var]))
		return(game["drm"][var]);
	
	return("");
}

// replacement for getCvarInt
drm_getCvarInt(var, stats)
{
	if(!isDefined(stats)) stats = true;
	if(stats)
	{
		if(isDefined(game["precachedone"])) level.drmstat_readpost++;
			else level.drmstat_readinit++;
	}

	if(isDefined(game["drm"][var]))
		return(atoi(game["drm"][var]));
	
	return(0);
}

// replacement for getCvarFloat
drm_getCvarFloat(var, stats)
{
	if(!isDefined(stats)) stats = true;
	if(stats)
	{
		if(isDefined(game["precachedone"])) level.drmstat_readpost++;
			else level.drmstat_readinit++;
	}

	if(isDefined(game["drm"][var]))
		return(atof(game["drm"][var]));
	
	return(0);
}
