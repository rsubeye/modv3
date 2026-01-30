#include extreme\_ex_punishments;

init()
{
	setcvar("team", "");
	setcvar("disableweapon", "");
	setcvar("enableweapon", "");
	setcvar("funmode", "");
	setcvar("mattress", "");
	setcvar("barrel", "");
	setcvar("bathtub", "");
	setcvar("toilet", "");
	setcvar("tree", "");
	setcvar("tombstone", "");
	setcvar("original", "");
	setcvar("warp", "");
	setcvar("lock", "");
	setcvar("silence", "");
	setcvar("unlock", "");
	setcvar("suicide", "");
	setcvar("smite", "");
	setcvar("torch", "");
	setcvar("fire", "");
	setcvar("spank", "");
	setcvar("arty", "");
	setcvar("endmap", "");
	setcvar("sayall", "");
	setcvar("sayallcenter", "");
	setcvar("switchplayerallies", "");
	setcvar("switchplayeraxis", "");
	setcvar("switchplayerspec", "");
	setcvar("switchsidesallplayers", "");
	setcvar("ssmonitor", "");

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 5);
}

onRandom(eventID)
{
	level endon("ex_gameover");

	if(level.ex_cmdmonitor_models)
	{
		v_FunmodePlayer = getcvar("funmode");
		if(v_FunmodePlayer != "") thread changePlayerModel(v_FunmodePlayer, "funmode");
		v_MattressPlayer = getcvar("mattress");
		if(v_MattressPlayer != "") thread changePlayerModel(v_MattressPlayer, "mattress");
		v_BarrelPlayer = getcvar("barrel");
		if(v_BarrelPlayer != "") thread changePlayerModel(v_BarrelPlayer, "barrel");
		v_BathtubPlayer = getcvar("bathtub");
		if(v_BathtubPlayer != "") thread changePlayerModel(v_BathtubPlayer, "bathtub");
		v_ToiletPlayer = getcvar("toilet");
		if(v_ToiletPlayer != "") thread changePlayerModel(v_ToiletPlayer, "toilet");
		v_TreePlayer = getcvar("tree");
		if(v_TreePlayer != "") thread changePlayerModel(v_TreePlayer, "tree");
		v_TombPlayer = getcvar("tombstone");
		if(v_TombPlayer != "") thread changePlayerModel(v_TombPlayer, "tombstone");
		v_OriginalPlayer = getcvar("original");
		if(v_OriginalPlayer != "") thread changePlayerModel(v_OriginalPlayer, "original");
	}

	v_DisableWeaponPlayer = getcvar("disableweapon");
	if(v_DisableWeaponPlayer != "") thread setStatusweaponPlayer(v_DisableWeaponPlayer, true);
	v_EnableWeaponPlayer = getcvar("enableweapon");
	if(v_EnableWeaponPlayer != "") thread setStatusweaponPlayer(v_EnableWeaponPlayer, false);
	v_WarpPlayer = getcvar("warp");
	if(v_WarpPlayer != "") thread messWithPlayer(v_WarpPlayer, "warp");
	v_LockPlayer = getcvar("lock");
	if(v_LockPlayer != "") thread messWithPlayer(v_LockPlayer, "lock");
	v_UnLockPlayer = getcvar("unlock");
	if(v_UnLockPlayer != "") thread messWithPlayer(v_UnLockPlayer, "unlock");
	v_SilencePlayer = getcvar("silence");
	if(v_SilencePlayer != "") thread messWithPlayer(v_SilencePlayer, "silence");
	v_SuicidePlayer = getcvar("suicide");
	if(v_SuicidePlayer != "") thread messWithPlayer(v_SuicidePlayer, "suicide");
	v_SmitePlayer = getcvar("smite");
	if(v_SmitePlayer != "") thread messWithPlayer(v_SmitePlayer, "smite");
	v_TorchPlayer = getcvar("torch");
	if(v_TorchPlayer != "") thread messWithPlayer(v_TorchPlayer, "torch");
	v_FirePlayer = getcvar("fire");
	if(v_FirePlayer != "") thread messWithPlayer(v_FirePlayer, "fire");
	v_SpankPlayer = getcvar("spank");
	if(v_SpankPlayer != "") thread messWithPlayer(v_SpankPlayer, "spank");
	v_ArtyPlayer = getcvar("arty");
	if(v_ArtyPlayer != "") thread messWithPlayer(v_ArtyPlayer, "arty");
	v_EndMap = getcvar("endmap");
	if(v_EndMap != "") thread endMap();
	v_SayAll = getcvar("sayall");
	if(v_SayAll != "") thread sayAll(v_SayAll, 0);
	v_SayAllCenter = getcvar("sayallcenter");
	if(v_SayAllCenter != "") thread sayAll(v_SayAllCenter, 1);
	v_SwitchPlayerAllies = getcvar("switchplayerallies");
	if(v_SwitchPlayerAllies != "") thread switchSide(v_SwitchPlayerAllies, "allies", 1, true);
	v_SwitchPlayerAxis = getcvar("switchplayeraxis");
	if(v_SwitchPlayerAxis != "") thread switchSide(v_SwitchPlayerAxis, "axis", 1, true);
	v_SwitchPlayerSpectator = getcvar("switchplayerspec");
	if(v_SwitchPlayerSpectator != "") thread switchSide(v_SwitchPlayerSpectator, "spectator", 1, true);
	v_SwitchSidesAllPlayers = getcvar("switchsidesallplayers");
	if(v_switchSidesAllPlayers != "") thread switchSides();
	v_StanceShootMonitor = getcvar("ssmonitor");
	if(v_StanceShootMonitor != "") thread setStanceShootMonitor(v_StanceShootMonitor);
}

setStanceShootMonitor(status)
{
	//first clear the buffer
	setcvar("ssmonitor", "");

	if(status == "0" && level.ex_stanceshoot)
	{
		level.ex_stanceshoot_backup = level.ex_stanceshoot;
		level.ex_stanceshoot = 0;
	}
	else if(status == "1" && isDefined(level.ex_stanceshoot_backup))
	{
		level.ex_stanceshoot = level.ex_stanceshoot_backup;
	}
}

setStatusweaponPlayer(PlayerEntID, lever)
{
	//first clear the buffer
	if(lever) setcvar("disableweapon", "");
		else setcvar("enableweapon", "");

	// Do we want to set teams
	v_team = getcvar("team");
	setcvar("team", "");

	playerEntID = int(PlayerEntID);
	players = level.players;
	for (i = 0; i < players.size; i++)
	{
		player = players[i];
		entID = player getEntityNumber();

		if(player.sessionstate == "playing" && ((entID == playerEntID) || (playerEntID == -1) || (v_team != "" && player.pers["team"] == v_team)) )
		{
			if(lever)
			{
				if(isAlive(player))
				{
					player thread setWeaponStatus(lever);
					player iprintlnbold(&"CMDMONITOR_DISABLEWEAPONS");
					iprintln(&"CMDMONITOR_DISABLEWEAPONSB", [[level.ex_pname]](player));
					wait( [[level.ex_fpstime]](1) );
				}
			}
			else
			{
				if(isAlive(player))
				{
					player thread setWeaponStatus(lever);
					player iprintlnbold(&"CMDMONITOR_ENABLEWEAPONS");
					iprintln(&"CMDMONITOR_ENABLEWEAPONSB", [[level.ex_pname]](player));
					wait( [[level.ex_fpstime]](1) );
				}
			}
		}
	}
}

changePlayerModel(PlayerEntID, mode)
{
	//first clear the buffer
	setcvar(mode, "");

	// Do we want to set teams
	v_team = getcvar("team");
	setcvar("team", "");

	models = [];
	pmsg = undefined;
	amsg = undefined;

	// Setup model's
	switch(mode)
	{
		case "funmode":
		models[0] = "xmodel/furniture_bedmattress1";
		models[1] = "xmodel/furniture_bathtub";
		models[2] = "xmodel/furniture_toilet";
		models[3] = "xmodel/prop_barrel_benzin";
		models[4] = "xmodel/prop_tombstone1";
		models[5] = "xmodel/tree_grey_oak_sm_a";
		pmsg = &"CMDMONITOR_FUNMODE";
		amsg = &"CMDMONITOR_FUNMODEB";
		break;

		case "mattress":
		models[0] = "xmodel/furniture_bedmattress1";
		pmsg = &"CMDMONITOR_MATTRESS";
		amsg = &"CMDMONITOR_MATTRESSB";
		break;

		case "bathtub":
		models[0] = "xmodel/furniture_bathtub";
		pmsg = &"CMDMONITOR_BATHTUB";
		amsg = &"CMDMONITOR_BATHTUBB";
		break;

		case "toilet":
		models[0] = "xmodel/furniture_toilet";
		pmsg = &"CMDMONITOR_TOILET";
		amsg = &"CMDMONITOR_TOILETB";
		break;

		case "barrel":
		models[0] = "xmodel/prop_barrel_benzin";
		pmsg = &"CMDMONITOR_BARREL";
		amsg = &"CMDMONITOR_BARRELB";
		break;

		case "tombstone":
		models[0] = "xmodel/prop_tombstone1";
		pmsg = &"CMDMONITOR_TOMBSTONE";
		amsg = &"CMDMONITOR_TOMBSTONEB";
		break;

		case "tree":
		models[0] = "xmodel/tree_grey_oak_sm_a";
		pmsg = &"CMDMONITOR_TREE";
		amsg = &"CMDMONITOR_TREEB";
		break;

		case "original":
		models[0] = "original";
		pmsg = &"CMDMONITOR_ORIGINAL";
		amsg = &"CMDMONITOR_ORIGINALB";
		break;

		default: return;
	}

	modeltype = models[randomInt(models.size)];

	playerEntID = int(PlayerEntID);
	players = level.players;
	for (i = 0; i < players.size; i++)
	{
		player = players[i];
		entID = player getEntityNumber();

		if(player.sessionstate == "playing" && ((entID == playerEntID) || (playerEntID == -1) || (v_team != "" && player.pers["team"] == v_team)) )
		{
			if(isAlive(player))
			{
				if(modeltype == "original")
				{
					if(!isDefined(player.pers["savedmodel"])) player maps\mp\gametypes\_models::getModel();
						else maps\mp\gametypes\_models::loadModel(player.pers["savedmodel"]);
					if(isDefined(player.ex_newmodel)) player.ex_newmodel = undefined;
				}
				else
				{
					player detachall();
					player setModel(modeltype);
					player.ex_newmodel = true;
				}

				player iprintlnbold(pmsg);
				iprintln(amsg, [[level.ex_pname]](player));
				wait( [[level.ex_fpstime]](1) );
			}
		}
	}
}

messWithPlayer(PlayerEntID, mode)
{
	//first clear the buffer
	setcvar(mode, "");

	// Do we want to set teams
	v_team = getcvar("team");
	setcvar("team", "");

	pmsg = undefined;
	amsg = undefined;

	playerEntID = int(PlayerEntID);
	players = level.players;
	for (i = 0; i < players.size; i++)
	{
		player = players[i];
		entID = player getEntityNumber();

		if(playerEntID == -1 && mode == "silence") return;
		if(mode != "silence" && (player.sessionstate != "playing" || !isAlive(player)) ) continue;

		if( entID == playerEntID || playerEntID == -1 || (v_team != "" && player.pers["team"] == v_team) )
		{
			switch(mode)
			{
				case "warp":
				player.health = 0;
				player thread doWarp(true);
				pmsg = &"CMDMONITOR_WARP";
				amsg = &"CMDMONITOR_WARPB";
				break;

				case "lock":
				porigin = player.origin;
				player thread doAnchor(true);
				pmsg = &"CMDMONITOR_LOCK";
				amsg = &"CMDMONITOR_LOCKB";
				break;

				case "unlock":
				porigin = player.origin;
				player thread doAnchor(false);
				pmsg = &"CMDMONITOR_UNLOCK";
				amsg = &"CMDMONITOR_UNLOCKB";
				break;

				case "suicide":
				player thread doSuicide();
				pmsg = &"CMDMONITOR_SUICIDE";
				amsg = &"CMDMONITOR_SUICIDEB";
				break;

				case "smite":
				porigin = player.origin;
				player thread doSmite();
				pmsg = &"CMDMONITOR_SMITE";
				amsg = &"CMDMONITOR_SMITEB";
				break;

				case "torch":
				player thread doTorch(false);
				pmsg = &"CMDMONITOR_TORCH";
				amsg = &"CMDMONITOR_TORCHB";
				break;

				case "crybaby":
				player thread doCrybaby();
				//pmsg = &"CMDMONITOR_CRYBABY";
				amsg = &"CMDMONITOR_CRYBABYB";
				break;

				case "fire":
				player thread doFire();
				pmsg = &"CMDMONITOR_FIRE";
				amsg = &"CMDMONITOR_FIREB";
				break;

				case "spank":
				player thread doSpank();
				pmsg = &"CMDMONITOR_SPANK";
				amsg = &"CMDMONITOR_SPANKB";
				break;

				case "silence":
				player thread doSilence();
				pmsg = &"CMDMONITOR_SILENCEA";
				amsg = &"CMDMONITOR_SILENCEB";
				break;

				case "arty":
				player thread doArty();
				pmsg = &"CMDMONITOR_ARTY_SELF";
				amsg = &"CMDMONITOR_ARTY_ALL";
				break;

				default: return;
			}

			if(isDefined(pmsg)) player iprintlnbold(pmsg);
			if(isDefined(amsg)) iprintln(amsg, [[level.ex_pname]](player));
			wait( [[level.ex_fpstime]](1) );
		}
	}
}

sayAll(Message, CenterScreen)
{
	if(CenterScreen == 1)
	{
		iprintlnbold(Message);
		setcvar("sayallcenter", "");
	}
	else
	{
		iprintln(Message);
		setcvar("sayall", "");
	}
}

switchSides()
{
	// First clear the buffer
	setcvar("switchsidesallplayers", "");

	// Make the announcement to all players
	iprintln(&"CMDMONITOR_SWITCHSIDESA");

	wait( [[level.ex_fpstime]](2) );

	players = level.players;
	for (i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player.pers["team"] == "allies")
		{
			entID = player getEntityNumber();
			thread switchSide(entID, "axis", 1, true);
		}
		else if(player.pers["team"] == "axis")
		{
			entID = player getEntityNumber();
			thread switchSide(entID, "allies", 1, true);
		}
	}
}

switchSide(playerEntID, side, announce, keepscore)
{
	// First clear the buffer
	setcvar("switchplayerspec", "");
	setcvar("switchplayerallies", "");
	setcvar("switchplayeraxis", "");

	playerEntID = int(PlayerEntID);

	// Find the player
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		entID = player getEntityNumber();

		if((entID == playerEntID) || (playerEntID == -1))
		{
			if(level.ex_mbot && isDefined(player.pers["isbot"])) continue;

			// this is the player to move
			if(side != player.pers["team"])
			{
				// give player point back if keep score set
				if(isDefined(keepscore) && keepscore)
				{
					player.pers["score"]++;
					player.score = player.pers["score"];
				}

				switch(side)
				{
					case "spectator":
						player.switching_teams = true;
						player.joining_team = "spectator";
						player.leaving_team = player.pers["team"];
						if(player.sessionstate == "playing")
						{
							player.ex_forcedsuicide = true;
							player suicide();
						}

						player.pers["team"] = side;
						player.pers["savedmodel"] = undefined;
						player.sessionteam = player.pers["team"];

						player extreme\_ex_weapons::setWeaponArray();
						player extreme\_ex_clientcontrol::clearWeapons();
						player thread maps\mp\gametypes\_spectating::setSpectatePermissions();
						player thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();

						player setClientCvar("ui_allow_teamchange", "1");
						player setClientCvar("ui_allow_weaponchange", "0");
						if(level.ex_classes == 1) player setClientCvar("ui_allow_classchange", "0");

						player setClientCvar("g_scriptMainMenu", game["menu_ingame"]);
						player thread extreme\_ex_spawn::spawnSpectator();
						break;

					case "allies":
					case "axis":
						if(isDefined(self.spawned)) self.spawned = undefined;
						player setClientCvar("ui_allow_teamchange", "0");
						player setClientCvar("ui_allow_weaponchange", "1");
						if(level.ex_classes == 1) player setClientCvar("ui_allow_classchange", "0");

						if(side == "allies")
						{
							player setClientCvar("g_scriptMainMenu", game["menu_weapon_allies"]);
							player [[level.allies]]();
						}
						else
						{
							player setClientCvar("g_scriptMainMenu", game["menu_weapon_axis"]);
							player [[level.axis]]();
						}

						if(isDefined(player.pers["isbot"])) player thread extreme\_ex_bots::dbotJoin(side);

						break;
				}

				if(announce)
				{
					if(playerEntID != -1) iprintln(&"CMDMONITOR_SWITCHSIDESB", [[level.ex_pname]](player));
					player iprintlnbold(&"CMDMONITOR_SWITCHSIDESC");
				}
			}
		}
	}
}

endMap()
{
	// First clear the buffer
	setcvar("endmap", "");

	// Make sure we don't call exitLevel more than once
	if(level.mapended) return;
	level.mapended = true;

	// Make the announcement to all players
	iprintlnbold(&"CMDMONITOR_ENDMAP");
	wait( [[level.ex_fpstime]](7) );

	// End the map gracefully
	level.ex_overtime = 0;
	if(level.ex_cmdmonitor)
	{
		if(level.ex_cmdmonitor_endmap_skipstbd) level.ex_stbd = 0;
		if(level.ex_cmdmonitor_endmap_skipvote) level.ex_mapvote = 0;
	}

	[[level.endgameconfirmed]]();
}
