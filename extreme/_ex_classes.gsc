#include extreme\_ex_hudcontroller;

init()
{
	// precache attachment models
	[[level.ex_PrecacheModel]]("xmodel/class_assault");
	[[level.ex_PrecacheModel]]("xmodel/class_comm");
	[[level.ex_PrecacheModel]]("xmodel/class_engineer");
	[[level.ex_PrecacheModel]]("xmodel/class_recon");
	[[level.ex_PrecacheModel]]("xmodel/class_support");

	// precache and hooks if full mode enabled only
	if(level.ex_classes == 1)
	{
		if(level.ex_classes_hudicons)
		{
			game["hudicon_assault"] = "classhud_assault";
			game["hudicon_recon"] = "classhud_recon";
			game["hudicon_engineer"] = "classhud_engineer";
			game["hudicon_support"] = "classhud_support";
			game["hudicon_comm"] = "classhud_comm";

			[[level.ex_PrecacheShader]](game["hudicon_assault"]);
			[[level.ex_PrecacheShader]](game["hudicon_recon"]);
			[[level.ex_PrecacheShader]](game["hudicon_engineer"]);
			[[level.ex_PrecacheShader]](game["hudicon_support"]);
			[[level.ex_PrecacheShader]](game["hudicon_comm"]);
		}

		if(level.ex_classes_headicons)
		{
			game["headicon_assault"] = "classhead_assault";
			game["headicon_recon"] = "classhead_recon";
			game["headicon_engineer"] = "classhead_engineer";
			game["headicon_support"] = "classhead_support";
			game["headicon_comm"] = "classhead_comm";

			[[level.ex_PrecacheHeadIcon]](game["headicon_assault"]);
			[[level.ex_PrecacheHeadIcon]](game["headicon_recon"]);
			[[level.ex_PrecacheHeadIcon]](game["headicon_engineer"]);
			[[level.ex_PrecacheHeadIcon]](game["headicon_support"]);
			[[level.ex_PrecacheHeadIcon]](game["headicon_comm"]);
		}

		if(level.ex_classes_statusicons)
		{
			game["statusicon_assault"] = "classstatus_assault";
			game["statusicon_recon"] = "classstatus_recon";
			game["statusicon_engineer"] = "classstatus_engineer";
			game["statusicon_support"] = "classstatus_support";
			game["statusicon_comm"] = "classstatus_comm";

			[[level.ex_PrecacheStatusIcon]](game["statusicon_assault"]);
			[[level.ex_PrecacheStatusIcon]](game["statusicon_recon"]);
			[[level.ex_PrecacheStatusIcon]](game["statusicon_engineer"]);
			[[level.ex_PrecacheStatusIcon]](game["statusicon_support"]);
			[[level.ex_PrecacheStatusIcon]](game["statusicon_comm"]);
		}

		// hook menu response functions for team selection
		level.autoassign_saved = level.autoassign;
		level.autoassign = ::menuAutoAssign;
		level.allies_saved = level.allies;
		level.allies = ::menuAllies;
		level.axis_saved = level.axis;
		level.axis = ::menuAxis;
		level.spectator_saved = level.spectator;
		level.spectator = ::menuSpectator;

		// hook menu response functions for weapon selection
		level.weapon_saved = level.weapon;
		level.weapon = ::menuWeapon;
		level.secweapon_saved = level.secweapon;
		level.secweapon = ::menuSecWeapon;
	}

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
}

onPlayerSpawned()
{
	if(!isDefined(self.pers["class"])) self.pers["class"] = randomInt(5) + 1;

	switch(self.pers["class"])
	{
		case 1: // assault
			self attach("xmodel/class_assault", "j_spine4", true);
			break;
		case 2: // recon
			self attach("xmodel/class_recon", "j_spine4", true);
			break;
		case 3: // engineer
			self attach("xmodel/class_engineer", "j_spine4", true);
			break;
		case 4: // support
			self attach("xmodel/class_support", "j_spine4", true);
			break;
		case 5: // communication
			self attach("xmodel/class_comm", "j_spine4", true);
			break;
	}

	if(level.ex_classes == 1)
	{
		if(level.ex_classes_statusicons) playerHudSetStatusIcon(getStatusIcon());

		if(level.ex_classes_hudicons)
		{
			hud_index = playerHudCreate("classes_myclass", 120, 450, level.ex_iconalpha, (1,1,1), 1, 0, "fullscreen", "fullscreen", "center", "middle", false, true);
			if(hud_index != -1)
			{
				playerHudSetShader(hud_index, getHudIcon(), 32, 32);
				playerHudScale(hud_index, 0.5, 0, 24, 24);
			}
		}
	}
}

menuAutoAssign()
{
	if(isDefined(self.spawned)) return;

	if(level.ex_gameover)
	{
		[[level.spectator]]();
		return;
	}

	self.pers["class"] = undefined;
	self.pers["classteam"] = "auto";
	self setClientCvar("g_scriptMainMenu", game["menu_classes"]);
	self closeMenu();
	self openMenu(game["menu_classes"]);
}

menuAllies()
{
	if(isDefined(self.spawned)) return;

	if(level.ex_gameover)
	{
		[[level.spectator]]();
		return;
	}

	if(self.pers["team"] != "allies")
	{
		self.pers["class"] = undefined;
		self.pers["classteam"] = "allies";
		self setClientCvar("g_scriptMainMenu", game["menu_classes"]);
		self closeMenu();
		self openMenu(game["menu_classes"]);
	}
}

menuAxis()
{
	if(isDefined(self.spawned)) return;

	if(level.ex_gameover)
	{
		[[level.spectator]]();
		return;
	}

	if(self.pers["team"] != "axis")
	{
		self.pers["class"] = undefined;
		self.pers["classteam"] = "axis";
		self setClientCvar("g_scriptMainMenu", game["menu_classes"]);
		self closeMenu();
		self openMenu(game["menu_classes"]);
	}
}

menuSpectator()
{
	if(isDefined(self.spawned)) return;

	if(level.ex_gameover)
	{
		[[level.spectator]]();
		return;
	}

	self.pers["class"] = undefined;
	self.pers["classteam"] = undefined;
	self [[level.spectator_saved]]();
}

menuWeapon(response)
{
	self [[level.weapon_saved]](response);
}

menuSecWeapon(response)
{
	self [[level.secweapon_saved]](response);
}

menuResponse(response)
{
	if(!isDefined(self.pers["classteam"])) return;

	oldclass = undefined;
	if(isDefined(self.pers["class"])) oldclass = self.pers["class"];

	switch(response)
	{
		case "class1": // assault
			self.pers["class"] = 1;
			break;
		case "class2": // recon
			self.pers["class"] = 2;
			break;
		case "class3": // engineer
			self.pers["class"] = 3;
			break;
		case "class4": // support
			self.pers["class"] = 4;
			break;
		case "class5": // communication
			self.pers["class"] = 5;
			break;
		default: // catch-all: assault
			self.pers["class"] = 1;
			break;
	}

	self closeMenu();
	self closeInGameMenu();

	if(isDefined(oldclass))
	{
		if(oldclass == self.pers["class"]) return;
		if(self.sessionstate == "playing")
		{
			self.ex_forcedsuicide = true;
			self suicide();
		}
	}

	if(self.pers["classteam"] == "auto") self [[level.autoassign_saved]]();
		else if(self.pers["classteam"] == "allies") self [[level.allies_saved]]();
			else if(self.pers["classteam"] == "axis") self [[level.axis_saved]]();
}

getStatusIcon()
{
	if(!isDefined(self.pers["class"])) return("");

	switch(self.pers["class"])
	{
		case 1: // assault
			return(game["statusicon_assault"]);
		case 2: // recon
			return(game["statusicon_recon"]);
		case 3: // engineer
			return(game["statusicon_engineer"]);
		case 4: // support
			return(game["statusicon_support"]);
		case 5: // communication
			return(game["statusicon_comm"]);
	}
}

getHudIcon()
{
	if(!isDefined(self.pers["class"])) return("");

	switch(self.pers["class"])
	{
		case 1: // assault
			return(game["hudicon_assault"]);
		case 2: // recon
			return(game["hudicon_recon"]);
		case 3: // engineer
			return(game["hudicon_engineer"]);
		case 4: // support
			return(game["hudicon_support"]);
		case 5: // communication
			return(game["hudicon_comm"]);
	}
}

getHeadIcon()
{
	if(!isDefined(self.pers["class"])) return("");

	switch(self.pers["class"])
	{
		case 1: // assault
			return(game["headicon_assault"]);
		case 2: // recon
			return(game["headicon_recon"]);
		case 3: // engineer
			return(game["headicon_engineer"]);
		case 4: // support
			return(game["headicon_support"]);
		case 5: // communication
			return(game["headicon_comm"]);
	}
}
