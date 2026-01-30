#include extreme\_ex_specials;
#include extreme\_ex_hudcontroller;

perkInit()
{
	// perk related precaching

	// create perk array
	level.cams = [];

	// precache shaders
	[[level.ex_PrecacheShader]]("compass_dot");

	// precache models
	[[level.ex_PrecacheModel]]("xmodel/security_camera");
	[[level.ex_PrecacheModel]]("xmodel/security_camera_mount");

	level.ex_camX = 55;
	level.ex_camY = -59;
	level.ex_camUnit = 0.0226875;
	level.ex_camHudScale = level.ex_cam_range * level.ex_camUnit;
}

perkInitPost()
{
	// perk related precaching after map load
}

perkCheck()
{
	// checks before being able to buy this perk
	if(getTotalActive("cam") > 8) return(false);
	if(perkCheckFrom(self)) return(false);
	return(true);
}

perkAssignDelayed(index, delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );

	if(!playerPerkIsLocked(index, true)) self thread perkAssign(index, 0);
}

perkAssign(index, delay)
{
	self endon("kill_thread");

	if(isDefined(self.pers["isbot"])) return;
	wait( [[level.ex_fpstime]](delay) );

	if((level.ex_arcade_shaders & 8) == 8) self thread extreme\_ex_arcade::showArcadeShader(getPerkArcade(index), level.ex_arcade_shaders_perk);
		else self iprintlnbold(&"SPECIALS_CAM_READY");

	self thread hudNotifySpecial(index);

	camInfo = spawnstruct();
	camInfo.error = false;

	self thread binocMonitor(index, camInfo);
	self waittill("target_approved");
	self notify("kill_aimrig"); // let the default binoc monitor know
	self notify("kill_aimcam"); // let the perk binoc monitor know

	self thread playerStartUsingPerk(index, true);
	self thread hudNotifySpecialRemove(index);

	level thread perkCreate(self, camInfo.origin, camInfo.angles, camInfo.lmax, camInfo.rmax);
}

/*******************************************************************************
VALIDATION
*******************************************************************************/
binocMonitor(index, camInfo)
{
	self endon("kill_thread");
	self endon("kill_aimcam");

	for(;;)
	{
		self waittill("binocular_enter");
		self thread binocPlacement(index, camInfo);
	}
}

binocPlacement(index, camInfo)
{
	self endon("kill_thread");
	self endon("kill_aimrig");
	self endon("kill_aimrigfx");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed())
		{
			perkCheckDeployment(camInfo);
			if(!camInfo.error && getPerkPriority(index))
			{
				self notify("target_approved");
				break;
			}
			while(self usebuttonpressed()) wait( [[level.ex_fpstime]](.05) );
		}

		wait( [[level.ex_fpstime]](0.05) );
	}
}

perkCheckDeployment(camInfo)
{
	self endon("kill_thread");

	vStart = self getEye() + (0,0,20);
	vForward = [[level.ex_vectorscale]](anglesToForward(self getplayerangles()), 100000);
	cam_trace = bulletTrace(vStart, vStart + vForward, true, self);
	cam_angles = vectorToAngles(cam_trace["normal"]);

	// check if hitting surface
	if(cam_trace["fraction"] == 1 || isPlayer(cam_trace["entity"]))
	{
		self iprintlnbold(&"SPECIALS_CAM_BADSURFACE");
		camInfo.error = true;
		return;
	}

	// check if proper surface
	switch(cam_trace["surfacetype"])
	{
		case "metal":
		case "asphalt":
		case "concrete":
		case "plaster":
		case "rock":
		case "brick":
		case "bark":
		case "wood":
			surfaceok = true;
			break;
		default:
			surfaceok = false;
	}
	if(!surfaceok)
	{
		self iprintlnbold(&"SPECIALS_CAM_BADSURFACE");
		camInfo.error = true;
		return;
	}

	// check if vertical surface
	if(cam_angles[0] > 10)
	{
		self iprintlnbold(&"SPECIALS_CAM_NOTVERTICAL");
		camInfo.error = true;
		return;
	}

	// check if near other cam
	for(i = 0; i < level.cams.size; i++)
	{
		if(level.cams[i].inuse)
		{
			if(distance(level.cams[i].mnt.origin, cam_trace["position"]) <= 500 && abs(cam_angles[1] - level.cams[i].mnt.angles[1]) <= 45)
			{
				self iprintlnbold(&"SPECIALS_CAM_COVERED");
				camInfo.error = true;
				return;
			}
		}
	}

	// check if valid entity
	if(isDefined(cam_trace["entity"]))
	{
		bad_entity = false;
		target_index = extreme\_ex_airtrafficcontroller::planeCheckEntity(cam_trace["entity"]);
		if(target_index != -1) bad_entity = true;
		if(!bad_entity)
		{
			target_index = extreme\_ex_specials_flak::perkCheckEntity(cam_trace["entity"]);
			if(target_index != -1) bad_entity = true;
			if(!bad_entity)
			{
				target_index = extreme\_ex_specials_gml::perkCheckEntity(cam_trace["entity"]);
				if(target_index != -1) bad_entity = true;
				if(!bad_entity)
				{
					target_index = extreme\_ex_specials_sentrygun::perkCheckEntity(cam_trace["entity"]);
					if(target_index != -1) bad_entity = true;
					if(!bad_entity)
					{
						target_index = extreme\_ex_specials_uav::perkCheckEntity(cam_trace["entity"]);
						if(target_index != -1) bad_entity = true;
						if(!bad_entity)
						{
							target_index = extreme\_ex_specials_ugv::perkCheckEntity(cam_trace["entity"]);
							if(target_index != -1) bad_entity = true;
							if(!bad_entity && level.ex_heli && isDefined(level.helicopter) && cam_trace["entity"] == level.helicopter) bad_entity = true;
							if(!bad_entity && level.ex_gunship && cam_trace["entity"] == level.gunship) bad_entity = true;
							if(!bad_entity && level.ex_gunship_special && cam_trace["entity"] == level.gunship_special) bad_entity = true;
						}
					}
				}
			}
		}
		if(bad_entity)
		{
			self iprintlnbold(&"SPECIALS_CAM_BADENTITY");
			camInfo.error = true;
			return;
		}
	}

	// check if enough space to manoeuvre
	forwardpos = posForward(cam_trace["position"], cam_angles, 10);
	leftpos = posLeft(forwardpos, cam_angles, 0);
	rightpos = posRight(forwardpos, cam_angles, 0);
	uppos = posUp(forwardpos, cam_angles, 0);
	downpos = posDown(forwardpos, cam_angles, 0);
	if(distance(forwardpos, leftpos) < 5 ||
	   distance(forwardpos, rightpos) < 5 ||
	   distance(forwardpos, uppos) < 5 ||
	   distance(forwardpos, downpos) < 5)
	{
		self iprintlnbold(&"SPECIALS_CAM_MANOEUVRE");
		camInfo.error = true;
		return;
	}

	// check field of view
	increment = 5;
	camInfo.lmax = 85;
	for(i = 0; i < camInfo.lmax; i += increment)
	{
		forwardvector = anglestoforward( (0, cam_angles[1]-i, 0) );
		leftpos = forwardpos + [[level.ex_vectorscale]](forwardvector, 50);
		trace = bulletTrace(forwardpos, leftpos, false, undefined);
		if(trace["fraction"] < 1)
		{
			camInfo.lmax = i+increment; // left
			break;
		}
	}
	camInfo.rmax = 85;
	for(i = 10; i < camInfo.rmax; i += increment)
	{
		forwardvector = anglestoforward( (0, cam_angles[1]+i, 0) );
		rightpos = forwardpos + [[level.ex_vectorscale]](forwardvector, 50);
		trace = bulletTrace(forwardpos, rightpos, false, undefined);
		if(trace["fraction"] < 1)
		{
			camInfo.rmax = i-increment; // right
			break;
		}
	}
	if((camInfo.lmax + camInfo.rmax) <= 30)
	{
		self iprintlnbold(&"SPECIALS_CAM_FOV");
		camInfo.error = true;
		return;
	}

	// everything is ok
	camInfo.error = false;
	camInfo.origin = cam_trace["position"];
	camInfo.angles = cam_angles;
	return;
}

perkCheckEntity(entity)
{
	if(isDefined(level.cams))
	{
		for(i = 0; i < level.cams.size; i++)
			if(level.cams[i].inuse && isDefined(level.cams[i].owner) && (level.cams[i].mnt == entity || level.cams[i].cam == entity) ) return(i);
	}

	return(-1);
}

/*******************************************************************************
PERK CREATION AND REMOVAL
*******************************************************************************/
perkCreate(owner, origin, angles, lmax, rmax)
{
	index = perkAllocate();

	// set up core properties
	level.cams[index].timer = level.ex_cam_timer;
	level.cams[index].owner = owner;
	level.cams[index].ownernum = owner getEntityNumber();
	level.cams[index].team = owner.pers["team"];
	level.cams[index].lmax = lmax;
	level.cams[index].rmax = rmax;

	// create models
	level.cams[index].cam = spawn("script_model", origin);
	level.cams[index].cam hide();
	level.cams[index].cam setmodel("xmodel/security_camera");
	level.cams[index].cam.angles = angles;

	level.cams[index].mnt = spawn("script_model", origin);
	level.cams[index].mnt hide();
	level.cams[index].mnt setmodel("xmodel/security_camera_mount");
	level.cams[index].mnt.angles = angles;

	level.cams[index].sensor = spawn("script_origin", (0,0,0));

	// link sensor to cam
	level.cams[index].sensor linkTo(level.cams[index].cam, "tag_sensor", (0,0,0), (0,0,0));

	// position cam on mount by link and unlink
	level.cams[index].cam linkTo(level.cams[index].mnt, "tag_camera", (0,0,0), (0,0,0));
	wait( [[level.ex_fpstime]](.1) );
	level.cams[index].cam unlink();

	level.cams[index].mnt show();
	level.cams[index].cam show();

	level thread perkThink(index);
}

perkAllocate()
{
	for(i = 0; i < level.cams.size; i++)
	{
		if(level.cams[i].inuse == 0)
		{
			level.cams[i].inuse = 1;
			return(i);
		}
	}

	level.cams[i] = spawnstruct();
	level.cams[i].notification = "cam" + i;
	level.cams[i].inuse = 1;
	return(i);
}

perkCheckFrom(player)
{
	if(level.ex_cam && isDefined(level.cams))
	{
		for(i = 0; i < level.cams.size; i++)
			if(level.cams[i].inuse && isDefined(level.cams[i].owner) && level.cams[i].owner == player) return(true);
	}
	return(false);
}

perkRemoveAll()
{
	if(level.ex_cam && isDefined(level.cams))
	{
		for(i = 0; i < level.cams.size; i++)
			if(level.cams[i].inuse) thread perkRemove(i);
	}
}

perkRemoveFrom(player)
{
	for(i = 0; i < level.cams.size; i++)
		if(level.cams[i].inuse && isDefined(level.cams[i].owner) && level.cams[i].owner == player) thread perkRemove(i);
}

perkRemove(index)
{
	if(!level.cams[index].inuse) return;
	level notify(level.cams[index].notification);

	if(isPlayer(level.cams[index].owner)) level.cams[index].owner thread perkHudRemove(index);

	thread levelStopUsingPerk(level.cams[index].ownernum, "cam");
	perkFree(index);
}

perkFree(index)
{
	// models
	if(isDefined(level.cams[index].sensor)) level.cams[index].sensor delete();
	if(isDefined(level.cams[index].cam)) level.cams[index].cam delete();
	if(isDefined(level.cams[index].mnt)) level.cams[index].mnt delete();

	level.cams[index].inuse = 0;
	level.cams[index].owner = undefined;
	level.cams[index].dots = undefined;
}

/*******************************************************************************
PERK MAIN LOGIC
*******************************************************************************/
perkThink(index)
{
	level thread perkRotate(index);

	level thread perkLevelController(index);

	for(;;)
	{
		// remove perk if it reached end of life
		if(level.cams[index].timer <= 0) break;

		// remove perk if owner left
		if(!isPlayer(level.cams[index].owner)) break;

		// remove perk in team based GT if owner switches teams
		if(level.ex_teamplay && level.cams[index].owner.pers["team"] != level.cams[index].team) break;

		wait( [[level.ex_fpstime]](1) );
		level.cams[index].timer--;
	}

	level thread perkRemove(index);
}

perkRotate(index)
{
	level endon(level.cams[index].notification);

	lmax = level.cams[index].lmax;
	ltime = level.cams[index].lmax * 0.05;
	lrmax = level.cams[index].lmax + level.cams[index].rmax;
	lrtime = ltime + (level.cams[index].rmax * 0.05);

	if(ltime)
	{
		level.cams[index].cam rotateyaw(0 - lmax, ltime, 0, 0);
		wait( [[level.ex_fpstime]](ltime + 1) );
	}

	while(true)
	{
		level.cams[index].cam rotateyaw(lrmax, lrtime, 0, 0);
		wait( [[level.ex_fpstime]](lrtime + 1) );
		level.cams[index].cam rotateyaw(0 - lrmax, lrtime, 0, 0);
		wait( [[level.ex_fpstime]](lrtime + 1) );
	}
}

perkInSight(index, player)
{
	dir = vectorNormalize(player.origin + (0, 0, 40) - level.cams[index].mnt.origin);

	dot = vectorDot(anglesToForward(level.cams[index].cam.angles), dir);
	if(dot > 1) dot = 1;
	viewangle = acos(dot);
	if(viewangle > level.ex_cam_viewangle) return(false);
	return(true);
}

perkCanSee(index, player)
{
	cansee = (bullettrace(level.cams[index].sensor.origin, player.origin + (0, 0, 10), false, undefined)["fraction"] == 1);
	if(!cansee) cansee = (bullettrace(level.cams[index].sensor.origin, player.origin + (0, 0, 40), false, undefined)["fraction"] == 1);
	if(!cansee && isDefined(player.ex_eyemarker)) cansee = (bullettrace(level.cams[index].sensor.origin, player.ex_eyemarker.origin, false, undefined)["fraction"] == 1);
	return(cansee);
}

perkLevelController(index)
{
	level endon("ex_gameover");
	level endon(level.cams[index].notification);

	level.cams[index].dots = [];

	while(true)
	{
		wait( [[level.ex_fpstime]](1) );

		if(!isPlayer(level.cams[index].owner)) break;
		if(level.cams[index].owner.sessionstate != "playing") continue;

		// if UAV is active for player or team, remove cam dots and use UAV instead
		if(level.ex_uav)
		{
			if( (level.ex_uav_private && extreme\_ex_specials_uav::perkCheckFrom(level.cams[index].owner)) || (!level.ex_uav_private && extreme\_ex_specials_uav::perkCheckTeam(level.cams[index].owner)) )
			{
				level.cams[index].owner perkHudRemove(index);
				continue;
			}
		}

		enemies = [];
		enemies = getEnemyPlayers(index);

		// update enemy players array
		for(e = 0; e < enemies.size; e++)
		{
			enemy = enemies[e];
			if(!isPlayer(enemy)) continue;

			enemyindex = -1;
			for(i = 0; i < level.cams[index].dots.size; i++)
			{
				enemyrec = level.cams[index].dots[i];
				if(isDefined(enemyrec.entity) && enemyrec.entity == enemy)
				{
					enemyindex = i;
					break;
				}
			}

			dist = int(distance( (level.cams[index].owner.origin[0], level.cams[index].owner.origin[1], 0), (enemy.origin[0], enemy.origin[1], 0) ));
			if(dist <= level.ex_cam_range && perkInSight(index, enemy) && perkCanSee(index, enemy))
			{
				if(enemyindex == -1)
				{
					enemyindex = level.cams[index].dots.size;
					level.cams[index].dots[enemyindex] = spawnstruct();
					level.cams[index].dots[enemyindex].entity = enemy;
					level.cams[index].dots[enemyindex].entityno = enemy getEntityNumber(); // for hud naming
					level.cams[index].dots[enemyindex].hud_index = -1;
				}

				level.cams[index].dots[enemyindex].dist = dist;
			}
			else if(enemyindex != -1) level.cams[index].dots[enemyindex].dist = 100000;
		}

		// sort the enemy players array on distance if necessary
		if(level.cams[index].dots.size > level.ex_cam_maxenemy)
		{
			level.cams[index].dots = quickSort(level.cams[index].dots, 0, level.cams[index].dots.size - 1);
		}

		// manage enemy dots
		for(i = 0; i < level.cams[index].dots.size; i++)
		{
			if(level.cams[index].owner.sessionstate != "playing") break;

			enemyrec = level.cams[index].dots[i];
			if(i < level.ex_cam_maxenemy && isPlayer(enemyrec.entity) && isAlive(enemyrec.entity) && enemyrec.dist <= level.ex_cam_range)
			{
				// create or update enemy dot
				if(enemyrec.hud_index == -1)
				{
					hud_index = level.cams[index].owner playerHudCreate("camdot" + enemyrec.entityno, 320, 240, 1, (1,0,0), 1, -1, "left", "bottom", "center", "middle", true, true);
					if(hud_index == -1) continue;
					enemyrec.hud_index = hud_index;
					level.cams[index].owner playerHudSetShader(hud_index, "compass_dot", 8, 8);
				}
				else hud_index = enemyrec.hud_index;

				forward = anglesToForward(level.cams[index].owner getPlayerAngles());
				forward = vectorNormalize( (forward[0], forward[1], 0) );
				dotx = vectorDot( (forward[1], -1 * forward[0], 0), enemyrec.entity.origin - level.cams[index].owner.origin) / level.ex_camHudScale;
				doty = vectorDot(forward, enemyrec.entity.origin - level.cams[index].owner.origin) / level.ex_camHudScale;
				level.cams[index].owner playerHudSetAlpha(hud_index, 1);
				level.cams[index].owner playerHudSetXYZ(hud_index, level.ex_camX + dotx, level.ex_camY - doty, undefined);
				if(level.ex_currentgt == "ft")
				{
					if(enemyrec.entity.frozenstate == "frozen") level.cams[index].owner playerHudSetColor(hud_index, (0,0,1));
						else level.cams[index].owner playerHudSetColor(hud_index, (1,0,0));
				}
				level.cams[index].owner playerHudFade(hud_index, 3, 0, 0);
			}
			else if(enemyrec.hud_index != -1)
			{
				// remove enemy dot
				level.cams[index].owner playerHudDestroy(enemyrec.hud_index);
				enemyrec.hud_index = -1;
			}
		}
	}
}

perkHudRemove(index)
{
	self endon("disconnect");

	for(i = 0; i < level.cams[index].dots.size; i++)
	{
		enemyrec = level.cams[index].dots[i];
		if(isDefined(enemyrec.hud_index) && enemyrec.hud_index != -1)
		{
			playerHudDestroy(enemyrec.hud_index);
			enemyrec.hud_index = -1;
		}
	}
}

getEnemyPlayers(index)
{
	teamplayers = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionstate == "spectator") continue;

		if(!level.ex_teamplay)
		{
			if(player != level.cams[index].owner) teamplayers[teamplayers.size] = player;
		}
		else if(player.pers["team"] != level.cams[index].team) teamplayers[teamplayers.size] = player;
	}

	return teamplayers;
}

quickSort(array, first, last)
{
	if(first >= last || array.size < 2) return(array);

	pivot_index = int((first + last) / 2);
	pivot = array[pivot_index];
	t = array[pivot_index];
	array[pivot_index] = array[last];
	array[last] = t;

	pivot_index = first;
	for(i = first; i < last; i++)
	{
		if(array[i].dist <= pivot.dist)
		{
			t = array[i];
			array[i] = array[pivot_index];
			array[pivot_index] = t;
			pivot_index++;
		}
	}

	t = array[pivot_index];
	array[pivot_index] = array[last];
	array[last] = t;

	array = quickSort(array, first, pivot_index - 1);
	array = quickSort(array, pivot_index + 1, last);
	return(array);
}

/*******************************************************************************
LOCATORS
*******************************************************************************/
posForward(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward(angles);
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posUp(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp( (0, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posDown(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToUp( (180, angles[1], 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, false, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posLeft(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward( (0, angles[1] + 90, 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

posRight(origin, angles, length, exclude_entity)
{
	angles = anglesNormalize(angles);
	forwardvector = anglesToForward( (0, angles[1] - 90, 0) );
	if(!length)
	{
		forwardpos = origin + ([[level.ex_vectorscale]](forwardvector, 20000));
		trace = bulletTrace(origin, forwardpos, true, exclude_entity);
		if(trace["fraction"] != 1) origin = trace["position"];
			else origin = forwardpos;
	}
	else origin = origin + [[level.ex_vectorscale]](forwardvector, length);
	return(origin);
}

/*******************************************************************************
MISC
*******************************************************************************/
abs(var)
{
	if(var < 0) var = var * (-1);
	return(var);
}

rev(var)
{
	if(var < 0) var = var * (-1);
		else var = 0 - var;
	return(var);
}

dif(var1, var2)
{
	if(var1 >= var2) diff = var1 - var2;
		else diff = var2 - var1;
	return(abs(diff));
}

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

getEyePos()
{
	if(isDefined(self.ex_eyemarker))
	{
		if(distancesquared(self.ex_eyemarker.origin, self.origin) > 0) return self.ex_eyemarker.origin;
			else return self geteye();
	}
	else return self geteye();
}
