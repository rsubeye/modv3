#include extreme\_ex_hudcontroller;

init()
{
	level.ex_toolbox_users = [];
	count = 0;
	for(;;)
	{
		name_check = [[level.ex_drm]]("ex_toolbox_name_" + count, "", "", "", "string");
		if(name_check == "") break;
		index = level.ex_toolbox_users.size;
		level.ex_toolbox_users[index] = spawnstruct();
		level.ex_toolbox_users[index].name = name_check;
		level.ex_toolbox_users[index].tools = [[level.ex_drm]]("ex_toolbox_tools_" + count, 0, 0, 64, "int");
		count++;
	}

	if(!level.ex_toolbox_users.size) return;
	count = 0;
	for(i = 0; i < level.ex_toolbox_users.size; i++) count += level.ex_toolbox_users[i].tools;
	if(!count) return;

	level.ex_toolbox_modelent = [];
	level.ex_toolbox_models = [];
	level.ex_toolbox_model = -1;

	count = 0;
	for(;;)
	{
		model_check = [[level.ex_drm]]("ex_toolbox_model_" + count, "", "", "", "string");
		if(model_check == "") break;
		index = level.ex_toolbox_models.size;
		level.ex_toolbox_models[index] = spawnstruct();
		level.ex_toolbox_models[index].modelname = "xmodel/" + model_check;
		[[level.ex_PrecacheModel]](level.ex_toolbox_models[index].modelname);
		count++;
	}

	level.ex_toolbox_effects = [];
	level.ex_toolbox_effect = -1;

	count = 0;
	for(;;)
	{
		effect_check = [[level.ex_drm]]("ex_toolbox_effect_" + count, "", "", "", "string");
		if(effect_check == "") break;
		index = level.ex_toolbox_effects.size;
		level.ex_toolbox_effects[index] = spawnstruct();
		level.ex_toolbox_effects[index].effectname = "fx/" + effect_check;
		level.ex_toolbox_effects[index].effectid = [[level.ex_PrecacheEffect]](level.ex_toolbox_effects[index].effectname);
		count++;
	}

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
}

onPlayerSpawned()
{
	level endon("ex_gameover");
	self endon("disconnect");

	tool_user = false;
	for(i = 0; i < level.ex_toolbox_users.size; i++)
	{
		if(level.ex_toolbox_users[i].name == self.name)
		{
			tool_user = true;
			break;
		}
	}
	if(!tool_user) return;

	if((level.ex_toolbox_users[i].tools & 1) == 1) self thread toolShowPos();
	if((level.ex_toolbox_users[i].tools & 2) == 2) self thread toolThirdPerson();
	if((level.ex_toolbox_users[i].tools & 4) == 4 && level.ex_toolbox_models.size) self thread toolModelTest();
	if((level.ex_toolbox_users[i].tools & 8) == 8 && level.ex_toolbox_effects.size) self thread toolEffectTest();
}

toolShowPos()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["tool_showpos"])) return;
	self.pers["tool_showpos"] = true;
	logprint("TOOLBOX: show position tool started for player: " + self.name + "\n");

	meleecount = 0;
	savecount = 0;

	// Position X
	hud_index = playerHudCreate("toolbox_posx", 250, 55, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// Position Y
	hud_index = playerHudCreate("toolbox_posy", 320, 55, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// Position Z
	hud_index = playerHudCreate("toolbox_posz", 390, 55, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// Angle X
	hud_index = playerHudCreate("toolbox_pitch", 250, 75, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// Angle Y
	hud_index = playerHudCreate("toolbox_yaw", 320, 75, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	// Angle Z
	hud_index = playerHudCreate("toolbox_roll", 390, 75, 1, (1,0,0), 1, 0, "fullscreen", "fullscreen", "center", "top", false, false);
	if(hud_index == -1) return;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		origin = self.origin;
		playerHudSetValue("toolbox_posx", origin[0]);
		playerHudSetValue("toolbox_posy", origin[1]);
		playerHudSetValue("toolbox_posz", origin[2]);

		angles = self getplayerangles();
		playerHudSetValue("toolbox_pitch", angles[0]);
		playerHudSetValue("toolbox_yaw", angles[1]);
		playerHudSetValue("toolbox_roll", angles[2]);

		// Monitor MELEE key. Reset counter if ADS, sprinting, planting or defusing
		if(self meleeButtonPressed() && !self playerADS() && !self.ex_plantwire && !self.ex_defusewire)
		{
			// Should have held key for 1 second at least
			if(meleecount > 5)
			{
				savecount++;
				logprint("TOOLBOX: [" + savecount + "] " + "origin " + origin + ", " + "angles " + angles + "\n");
				meleecount = 0;
				while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.5) );
			}
			else meleecount++;
		}
		else meleecount = 0;
	}
}

toolThirdPerson()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["tool_thirdperson"])) return;
	self.pers["tool_thirdperson"] = true;
	logprint("TOOLBOX: third person tool started for player: " + self.name + "\n");

	self.ex_thirdperson = false;
	thirdpersonangle = 0;
	thirdpersonrange = 100;

	meleecount = 0;
	usecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		// Monitor USE key. Reset counter if ADS, sprinting or rearming
		if(self useButtonPressed() && !self playerADS() && !self.ex_sprinting && !self.handling_mine && !isDefined(self.ex_amc_rearm) && !isDefined(self.ex_ishealing))
		{
			// Should have held key for 1 second at least
			if(usecount > 5)
			{
				if(self.ex_thirdperson)
				{
					thirdpersonrange += 20;
					if(thirdpersonrange > 200)
					{
						thirdpersonrange = 100;
						self setClientCvar("cg_thirdperson", 0);
						self.ex_thirdperson = false;
						usecount = 0;
					}
					else self setClientCvar("cg_thirdpersonrange", thirdpersonrange);
				}
				else
				{
					self setClientCvar("cg_thirdpersonangle", thirdpersonangle);
					self setClientCvar("cg_thirdpersonrange", thirdpersonrange);
					self setClientCvar("cg_thirdperson", 1);
					self.ex_thirdperson = true;
					usecount = 0;
				}
			}
			else usecount++;
		}
		else usecount = 0;

		if(self.ex_thirdperson)
		{
			// Monitor MELEE key. Reset counter if ADS, sprinting, planting or defusing
			if(self meleeButtonPressed() && !self playerADS() && !self.ex_plantwire && !self.ex_defusewire)
			{
				// Should have held key for 1 second at least
				if(meleecount > 5)
				{
					thirdpersonangle += 10;
					if(thirdpersonangle == 360) thirdpersonangle = 0;
					self setClientCvar("cg_thirdpersonangle", thirdpersonangle);
				}
				else meleecount++;
			}
			else meleecount = 0;
		}
	}
}

toolModelTest()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["tool_modeltest"])) return;
	self.pers["tool_modeltest"] = true;
	logprint("TOOLBOX: model testing tool started for player: " + self.name + "\n");

	meleecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		if(!self isOnGround()) continue;

		// Monitor MELEE key. Reset counter if ADS, sprinting, planting or defusing
		if(self meleeButtonPressed() && !self playerADS() && !self.ex_plantwire && !self.ex_defusewire)
		{
			// Should have held key for 1 second at least
			if(meleecount > 5)
			{
				if(!extreme\_ex_utils::tooClose(150, 150, 150, 150)) self thread toolModelCreate();
				while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.5) );
				meleecount = 0;
			}
			else meleecount++;
		}
		else meleecount = 0;
	}
}

toolModelCreate()
{
	level.ex_toolbox_model++;
	if(level.ex_toolbox_model >= level.ex_toolbox_models.size) level.ex_toolbox_model = 0;

	index = toolModelAllocate();
	level.ex_toolbox_modelent[index].model = spawn("script_model", self.origin);
	level.ex_toolbox_modelent[index].model setmodel(level.ex_toolbox_models[level.ex_toolbox_model].modelname);
	level.ex_toolbox_modelent[index].model.angles = (0, self.angles[1], 0);
	level.ex_toolbox_modelent[index].model.owner = self;
	level.ex_toolbox_modelent[index].model.team = self.pers["team"];

	level thread toolModelThink(index);
}

toolModelThink(index)
{
	//level thread toolModelRotate(index);
	//level thread toolModelFX(index);

	//level.ex_toolbox_modelent[index].model.owner linkTo(level.ex_toolbox_modelent[index].model, "tag_player1", (0,0,0), (0,0,0));

	ttl = 60;
	while(ttl > 0)
	{
		ttl--;
		wait( [[level.ex_fpstime]](1) );
	}

	//level.ex_toolbox_modelent[index].model.owner unlink();

	toolModelRemove(index);
}

toolModelAllocate()
{
	for(i = 0; i < level.ex_toolbox_modelent.size; i++)
	{
		if(level.ex_toolbox_modelent[i].inuse == 0)
		{
			level.ex_toolbox_modelent[i].inuse = 1;
			return(i);
		}
	}

	level.ex_toolbox_modelent[i] = spawnstruct();
	level.ex_toolbox_modelent[i].notification = "testmodel" + i;
	level.ex_toolbox_modelent[i].inuse = 1;
	return(i);
}

toolModelRemove(index)
{
	if(!level.ex_toolbox_modelent[index].inuse) return;
	level notify(level.ex_toolbox_modelent[index].notification);
	level.ex_toolbox_modelent[index].model delete();
	level.ex_toolbox_modelent[index].inuse = 0;
}

toolModelRotate(index)
{
	level endon(level.ex_toolbox_modelent[index].notification);

	seconds = 10;
	while(true)
	{
		level.ex_toolbox_modelent[index].model movez(500, seconds, 1, 1);
		//level.ex_toolbox_modelent[index].model rotateyaw(360, seconds, 0, 0);
		wait(10);
		level.ex_toolbox_modelent[index].model movez(-500, seconds, 1, 1);
		//level.ex_toolbox_modelent[index].model rotateyaw(360 , seconds, 0, 0);
		wait(20);
	}
}

toolModelFX(index)
{
	level endon(level.ex_toolbox_modelent[index].notification);

	while(true)
	{
		//playfxontag(effect_id, level.ex_toolbox_modelent[index].model, "tag_id");
		wait(1);
	}
}

toolEffectTest()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(isDefined(self.pers["tool_fxtest"])) return;
	self.pers["tool_fxtest"] = true;
	logprint("TOOLBOX: effect testing tool started for player: " + self.name + "\n");

	meleecount = 0;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.2) );

		if(!self isOnGround()) continue;

		// Monitor MELEE key. Reset counter if ADS, sprinting, planting or defusing
		if(self meleeButtonPressed() && !self playerADS() && !self.ex_plantwire && !self.ex_defusewire)
		{
			// Should have held key for 1 second at least
			if(meleecount > 5)
			{
				if(!extreme\_ex_utils::tooClose(150, 150, 150, 150)) self thread toolEffectCreate();
				while(self meleeButtonPressed()) wait( [[level.ex_fpstime]](0.5) );
				meleecount = 0;
			}
			else meleecount++;
		}
		else meleecount = 0;
	}
}

toolEffectCreate()
{
	level.ex_toolbox_effect++;
	if(level.ex_toolbox_effect >= level.ex_toolbox_effects.size) level.ex_toolbox_effect = 0;

	playOrigin = self getEye() + [[level.ex_vectorscale]](anglesToForward(self getplayerangles()), 100) + (0,0,20);
	//playOrigin = (game["mapArea_CentreX"], game["mapArea_CentreY"], 1000);
	//playOrigin = self.origin;

	playfx(level.ex_toolbox_effects[level.ex_toolbox_effect].effectid, playOrigin);

	//fxAngle = vectorNormalize((playOrigin + (0,0,100)) - playOrigin);
	//fxlooper = playLoopedFx(level.ex_toolbox_effects[level.ex_toolbox_effect].effectid, 1.6, playOrigin, 0, fxAngle);
	//wait( [[level.ex_fpstime]](60) );
	//if(isDefined(fxlooper)) fxlooper delete();
}

/*******************************************************************************
LOCATORS
*******************************************************************************/
posForward(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posBack(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	origin = origin + [[level.ex_vectorscale]](forwardvector, 0 - length);
	return(origin);
}

posUp(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoup( (0, angles[1], 0) );
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posDown(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoup( (180, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, false, undefined);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posLeft(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoforward( (0, angles[1] + 90, 0) );
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posRight(origin, angles, length)
{
	angles = anglesNormalize(angles);
	forwardvector = anglestoforward( (0, angles[1] - 90, 0) );
	origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

/*******************************************************************************
MISC
*******************************************************************************/
angleNormalize(angle)
{
	if(angle) while(angle >= 360) angle -= 360;
		else while(angle <= -360) angle += 360;
	return(angle);
}

anglesNormalize(angles)
{
	pitch = angleNormalize(angles[0]);
	yaw = angleNormalize(angles[1]);
	roll = angleNormalize(angles[2]);
	return( (pitch, yaw, roll) );
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return(var);
}
