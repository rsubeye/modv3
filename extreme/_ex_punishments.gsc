#include extreme\_ex_hudcontroller;

setWeaponStatus(lever)
{
	self endon("kill_thread");

	if(lever) self [[level.ex_dWeapon]]();
		else self [[level.ex_eWeapon]]();
}

doWarp(readrules)
{
	self endon("kill_thread");

	if(!isDefined(readrules)) readrules = true;

	ix = self.origin[0];
	iy = self.origin[1];
	iz = 1000;
	if(iz > (game["mapArea_Max"][2] - 200)) iz = game["mapArea_Max"][2] - 200;
	startpoint = self.origin + (0, 0, 24);
	endpoint = (ix, iy, iz);
	distance = distance(startpoint, endpoint);

	self.ex_anchor = spawn("script_model", self.origin);
	self.ex_anchor.angles = self.angles;
	self linkto(self.ex_anchor);

	// drop flag
	self extreme\_ex_utils::dropTheFlag(true);

	lifttime = distance/100 + randomint(6);
	self.ex_anchor.origin = startpoint;
	self.ex_anchor moveto(endpoint, lifttime);

	// drop weapon
	self maps\mp\gametypes\_weapons::dropWeapon();

	wait( [[level.ex_fpstime]](3) ); // Allow player to read the command monitor message
	self [[level.ex_dWeapon]]();
	[[level.ex_bclear]]("self", 5);
	
	self thread warpShowRules(readrules);

	self waittill("warp_over");

	if(isPlayer(self))
	{
		self unlink();
		if(isDefined(self.ex_anchor)) self.ex_anchor delete();
		self.health = 1;
	}

	wait( [[level.ex_fpstime]](3) );

	// huh? Still here? Stupid map! Blow them up
	if(isPlayer(self) && self.sessionstate == "playing")
	{
		playfx(level.ex_effect["barrel"], self.origin);
		self playsound("mortar_explosion1");
		wait( [[level.ex_fpstime]](0.05) );
		if(isPlayer(self))
		{
			self.ex_forcedsuicide = true;
			self suicide();
		}
	}
}

warpShowRules(readrules)
{
	self endon("kill_thread");

	if(readrules)
	{
		svrrules = warpJustNumbers(level.ex_svrrules);
		self iprintlnbold(&"CUSTOM_SERVER_RULES_FAIL");
		wait( [[level.ex_fpstime]](3) );
		for(i = 1; i < svrrules.size; i++)
		{
			ruleno = int(svrrules[i]);
			showrule = warpGetRule(i);
			self iprintlnbold(showrule);
			wait( [[level.ex_fpstime]](3) );
		}
		self iprintlnbold(&"CUSTOM_SERVER_RULES_WARN");
		wait( [[level.ex_fpstime]](3) );
	}
	else wait( [[level.ex_fpstime]](10) );

	self notify("warp_over");
}

warpGetRule(ruleno)
{
	rulestr = "";

	switch(ruleno)
	{
		case 1: { rulestr = &"CUSTOM_SERVER_RULE_1"; break; }
		case 2: { rulestr = &"CUSTOM_SERVER_RULE_2"; break; }
		case 3: { rulestr = &"CUSTOM_SERVER_RULE_3"; break; }
		case 4: { rulestr = &"CUSTOM_SERVER_RULE_4"; break; }
		case 5: { rulestr = &"CUSTOM_SERVER_RULE_5"; break; }
		case 6: { rulestr = &"CUSTOM_SERVER_RULE_6"; break; }
		case 7: { rulestr = &"CUSTOM_SERVER_RULE_7"; break; }
		case 8: { rulestr = &"CUSTOM_SERVER_RULE_8"; break; }
		case 9: { rulestr = &"CUSTOM_SERVER_RULE_9"; break; }
		case 0: { rulestr = &"CUSTOM_SERVER_RULE_10"; break; }
	}
	return rulestr;
}

warpJustNumbers(strIn)
{
	if(!isDefined(strIn) || strIn == "") return "";

	numbers = "0123456789";
	strOut = "";

	for(i = 0; i < strIn.size; i++)
	{
		chr = strIn[i];
		for(j = 0; j < numbers.size; j++)
		{
			if(chr == numbers[j]) strOut += numbers[j];
		}
	}
	return strOut;
}

doAnchor(lever)
{
	self endon("kill_thread");

	if(lever)
	{
		self.anchor = spawn("script_origin", self.origin);
		self linkTo(self.anchor);
	}
	else
	{
		self unlink();
		if(isDefined(self.anchor)) self.anchor delete();
	}
}

doSuicide()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](0.25) );
	if(isPlayer(self))
	{
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

doSmite()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](1.5) );
	playfx(level.ex_effect["barrel"], self.origin);

	if(isPlayer(self))
	{
		self playsound("artillery_explosion");
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

doTorch(special, eAttacker)
{
	self endon("kill_thread");

	if(!isDefined(special)) special = false;
	if(!isDefined(eAttacker)) eAttacker = self;

	self thread doFire();

	for(i = 0; i < 10; i++)
	{
		if(isPlayer(self) && special) self thread [[level.callbackPlayerDamage]](eAttacker, eAttacker, randomInt(2) + 2, 1, "MOD_PROJECTILE", "planebomb_mp", undefined, (0,0,1), "none",0);
		wait( [[level.ex_fpstime]](1) );
	}

	if(special) return;

	if(isPlayer(self))
	{
		playfx(level.ex_effect["fire_ground"], self.origin);
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

doFire()
{
	self endon("kill_thread");

	self playsound("scream");

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.25) );
		if(isPlayer(self))
		{
			// quit burning effects when frozen in freezetag
			if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") return;

			playfxontag(level.ex_effect["fire_arm"], self, "j_elbow_le");
			playfxontag(level.ex_effect["fire_arm"], self, "j_elbow_ri");
			if(!isDefined(self.pers["diana"])) playfxontag(level.ex_effect["fire_torso"], self, "torso_stabilizer");
		}
	}
}

doSpank()
{
	self endon("kill_thread");

	self thread spankPlayer(10);
	self shellshock("default", 10);
}

spankPlayer(time)
{
	self endon("kill_thread");

	self notify("ex_spankme");
	self endon("ex_spankme");

	for(i = 0; i < (time); i++)
	{
		if(isPlayer(self))
		{
			self extreme\_ex_utils::forceto("prone");
			self thread extreme\_ex_weapons::dropcurrentweapon();
		}

		wait( [[level.ex_fpstime]](2) );
	}
}

doSilence()
{
	self endon("kill_thread");

	self thread extreme\_ex_utils::execClientCommand("bind T say");
	wait( [[level.ex_fpstime]](0.25) );
	self thread extreme\_ex_utils::execClientCommand("bind Y say");
	wait( [[level.ex_fpstime]](0.25) );
	self setClientCvar("cg_chatHeight", "0");
	self setClientCvar("cg_chatTime", "0");
}

doCrybaby()
{
	self endon("kill_thread");

	if(!level.ex_crybaby) return;
	if(isDefined(self.ex_crybaby)) return;

	// mark and make invulnerable
	self.ex_invulnerable = true;
	self.ex_crybaby = true;

	// save and replace head icon
	playerHudSetHeadIcon(game["headicon_crybaby"], "none");

	// lock player
	self freezecontrols(true);

	// play sound
	self.ex_headmarker playloopsound("crybaby_loop");

	// show crybaby image and txt
	alpha = 0;
	hud_index = playerHudCreate("crybaby_img", 320, 240, 0, (1,1,1), 1, 100, "fullscreen", "fullscreen", "center", "middle", false, false);
	if(hud_index != -1)
	{
		playerHudSetShader(hud_index, "exg_crybaby", 64, 64);
		playerHudScale(hud_index, 1.5, 0, 384, 384);
		playerHudFade(hud_index, 1.5, 1.5, 1 - (level.ex_crybaby_transp / 10));

		hud_index = playerHudCreate("crybaby_txt", 320, 420, alpha, (1,0,0), 1.3, 101, "fullscreen", "fullscreen", "center", "middle", false, false);
		if(hud_index != -1) playerHudSetText(hud_index, &"MISC_CRYBABY");
	}

	for(i = 0; i < level.ex_crybaby_time; i++)
	{
		wait( [[level.ex_fpstime]](0.5) );
		alpha = !alpha;
		playerHudSetAlpha("crybaby_txt", alpha);
		wait( [[level.ex_fpstime]](0.5) );
		alpha = !alpha;
		playerHudSetAlpha("crybaby_txt", alpha);
	}

	// stop sound
	self.ex_headmarker stopLoopSound();

	// remove crybaby image and txt
	playerHudDestroy("crybaby_img");
	playerHudDestroy("crybaby_txt");

	// release player
	self freezecontrols(false);

	// restore head icon
	playerHudRestoreHeadIcon();

	// unmark and make vulnerable
	self.ex_invulnerable = false;
	self.ex_crybaby = undefined;

	// smite
	if(isPlayer(self))
	{
		playfx(level.ex_effect["barrel"], self.origin);
		self playSound("artillery_explosion");
		self.ex_forcedsuicide = true;
		self suicide();
	}
}

doArty()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](2) );
	self iprintlnbold(&"CMDMONITOR_ARTY_SELF_RUN");
	wait( [[level.ex_fpstime]](5) );

	self.ex_forcedsuicide = true;
	while(isPlayer(self) && isAlive(self))
	{
		arty = spawn("script_origin", self.origin);
		arty goArty(self);
	}
}

goArty(player)
{
	shellStartPos = (game["playArea_Min"][0], game["playArea_Min"][1], player.origin[2]);
	shellTargetPos = player.origin;

	self thread goArtyShell(player, shellStartPos, shellTargetPos);

	self waittill("arty_shell_impact");
	self delete();
}

goArtyShell(player, shellStartPos, shellTargetPos)
{
	shellStartPos = (shellTargetPos[0]-100, shellTargetPos[1]-100, game["mapArea_Max"][2]-200);

	shell = spawn("script_model", shellStartPos);
	shell setModel("xmodel/prop_stuka_bomb");
	shell.angles = vectorToAngles(vectorNormalize(shellTargetPos - shellStartPos));
	shell playSound("artillery_incoming");

	shellDist = distance(shellTargetPos, shellStartPos);
	shellDist = int(shellDist * 0.0254);
	shellSpeed = 50;
	shellInAir = goArtyShellTime(shellDist, shellSpeed);
	shell moveTo(shellTargetPos + (0,0,-100), shellInAir);
	wait( [[level.ex_fpstime]](shellInAir) );
	shell goArtyBoom(player);

	self notify("arty_shell_impact");
}

goArtyBoom(player)
{
	playfx(level.ex_effect["artillery"], self.origin);
	self playSound("artillery_explosion");
	self thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_EXPLOSIVE", "artillery_mp", 3, 0, 0, "none", undefined, true, true, true);
	artyDamage = 25;
	player thread [[level.callbackPlayerDamage]](self, self, artyDamage, 1, "MOD_EXPLOSIVE", "artillery_mp", undefined, (0,0,1), "none", 0);

	self hide();
	wait( [[level.ex_fpstime]](3) );
	self delete();
}

goArtyShellTime(distvalue, speedvalue)
{
	timeinsec = distvalue / speedvalue;
	if(timeinsec <= 0) timeinsec = 0.1;
	return timeinsec;
}

doSinbin()
{
	self endon("kill_thread");

	if(self.ex_sinbin) return;

	if(isPlayer(self) && self.sessionstate == "playing")
	{
		self.ex_sinbin = true;

		if(randomInt(100) < 50 && extreme\_ex_utils::isOutside(self.origin)) self sinSplat();
			else self sinFreeze();

		if(isPlayer(self)) self.ex_sinbin = false;
	}
}

sinFreeze()
{
	self endon("kill_thread");

	if(isPlayer(self))
	{
		self thread sinTimer(level.ex_sinfrztime);

		if(level.ex_sinbinmsg)
		{
			msg1 = &"SINBIN_FREEZE";
			msg2 = extreme\_ex_utils::time_convert(level.ex_sinfrztime);

			switch(level.ex_sinbinmsg)
			{
				case 0:
					self iprintln(msg1);
					self iprintln(msg2);
					break;
				case 1:
					self iprintlnbold(msg1);
					self iprintlnbold(msg2);
					break;
			}
		}

		if(isPlayer(self))
		{
			self extreme\_ex_utils::dropTheFlag(true);
			self thread extreme\_ex_utils::punishment("random", "freeze");
			self waittill("sinbin_timer_done");
			if(isPlayer(self)) self thread extreme\_ex_utils::punishment("enable", "release");
		}
	}
}

sinSplat()
{
	self endon("kill_thread");

	self notify("ex_freefall");

	if(isPlayer(self))
	{
		if(level.ex_sinbinmsg)
		{
			msg1 = &"SINBIN_FREEFALL";

			switch(level.ex_sinbinmsg)
			{
				case 0:
					self iprintln(msg1);
					break;
				case 1:
					self iprintlnbold(msg1);
					break;
			}
		}

		if(isPlayer(self))
		{
			self extreme\_ex_utils::dropTheFlag(true);
			self thread doWarp(false);
		}
	}
}

sinTimer(time)
{
	self endon("kill_thread");

	while(isPlayer(self) && time > 0)
	{
		wait( [[level.ex_fpstime]](1) );
		time--;
	}

	if(isPlayer(self)) self notify("sinbin_timer_done");
}
