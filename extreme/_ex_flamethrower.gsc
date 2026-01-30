#include extreme\_ex_weapons;

main()
{
	self endon("kill_thread");

	self.tankonback = undefined;

	while(true)
	{
		wait( [[level.ex_fpstime]](0.1) );

		if(!level.ex_classes)
		{
			// Check if player is (still) carrying a flamethrower (any slot)
			weapon1 = self.pers["weapon"];
			if(level.ex_wepo_secondary) weapon2 = self.pers["weapon2"];
				else weapon2 = "none";

			if(isWeaponType(weapon1, "ft") || isWeaponType(weapon2, "ft"))
			{
				// Flamethrower found: attach the gas tank to the back if not attached already
				if(!isDefined(self.tankonback))
				{
					// Detach current weapon on back
					if(isDefined(self.weapononback))
					{
						if(checkAttached(self.weapononback)) self detach("xmodel/" + self.weapononback, "");
						self.weapononback = undefined;
					}
					self.tankonback = "ft_tank";
					if(!checkAttached(self.tankonback)) self attach("xmodel/" + self.tankonback, "j_spine4", true);
				}
			}
			else
			{
				// No flamethrower (anymore): detach the tank if attached
				if(isDefined(self.tankonback))
				{
					if(checkAttached(self.tankonback)) self detach("xmodel/" + self.tankonback, "j_spine4");
					self.tankonback = undefined;
				}
			}
		}

		// separated the actual flamethrower monitor so only players with a flamethrower will
		// run that thread, saving a ton of script variables
		sWeapon = self getCurrentWeapon();
		if(self attackbuttonpressed() && isWeaponType(sWeapon, "ft")) monitorFlamethrower();
	}
}

monitorFlamethrower()
{
	self endon("kill_thread");

	flame_alloc = 10;
	flame_index = 0;
	flame_refused = 0;

	flames = [];
	for(i = 1; i <= flame_alloc; i++)
	{
		flames[i] = spawnstruct();
		flames[i].inuse = false;
		flames[i].flame = undefined;
	}

	while(1)
	{
		wait( [[level.ex_fpstime]](0.1) );

		sWeapon = self getCurrentWeapon();
		if(!isWeaponType(sWeapon, "ft")) break;

		if(self attackbuttonpressed())
		{
			// Check if player is on turret
			if(isDefined(self.onturret)) continue;

			// Check if weapon has ammo left
			if(sWeapon == self getWeaponSlotWeapon("primary")) ft_slot = "primary";
				else ft_slot = "primaryb";
			ft_ammo = self getWeaponSlotClipAmmo(ft_slot);
			if(!ft_ammo) continue;

			// Check distance to object in front of player. Too close = no flame
			trace = self GetEyeTrace(1000);
			trace_dist = distance(trace["position"], self.origin);
			if(trace_dist < 100)
			{
				flame_refused++;
				if(flame_refused == 1 || flame_refused%5 == 0) self playsound("ft_refuse");
				continue;
			}
			else flame_refused = 0;

			// Next flame. Check if it has an allocated array element
			flame_index++;
			if(flame_index > flame_alloc)
			{
				// If first flame is still alive, expand array if within limits
				if(flames[1].inuse && flame_alloc <= 20)
				{
					flame_alloc++;
					flames[flame_alloc] = spawnstruct();
					flames[flame_alloc].inuse = false;
					flames[flame_alloc].flame = undefined;
				}
				else flame_index = 1;
			}

			// Did we cycle a full array?
			if(flames[flame_index].inuse) continue;

			// Play flamethrower sound on 1st and every 5th flame
			if(flame_index == 1 || flame_index%5 == 0) self playsound("ft_fire");

			// Now get a target
			trace_entity = self;
			flame_start = self getTargetedPos(65);
			flame_target = GetTargetedPos(level.ex_ft_range);

			trace = bulletTrace(flame_start, flame_target, true, undefined);
			if(trace["fraction"] != 1 && isDefined(trace["entity"]))
			{
				trace_entity = trace["entity"];
				flame_target = trace_entity.origin;
			}
			else
			{
				trace = bulletTrace(flame_start, flame_target, false, undefined);
				if(trace["fraction"] != 1 && trace["surfacetype"] != "default")
					flame_target = trace["position"];
			}

			if(!isDefined(flame_target)) flame_target = GetTargetedPos(level.ex_ft_range);

			// Limit how many times a flame may duplicate itself while traveling
			trace_dist = distance(flame_start, flame_target);
			if(trace_dist == 0) trace_dist = 1;
			flame_loop = (level.ex_ft_range / trace_dist) * 0.1;

			// Play effects
			flames[flame_index].inuse = true;
			flames[flame_index].flame = spawn("script_model", flame_start);
			flames[flame_index].flame setModel("xmodel/tag_origin"); // Substitution model (always precached)
			flames[flame_index].flame.angles = self.angles;
			flames[flame_index].flame hide();
			flames[flame_index].flame thread showFlame(flames[flame_index], flame_loop, flame_target);

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];

				// Skip if player left or player is self
				if(!isPlayer(player) || player == self) continue;

				// Skip dead players, spectators and spawn protected players
				if(!isAlive(player) || player.sessionteam == "spectator" || player.ex_invulnerable) continue;

				// Respect friendly fire settings 0 (off) and 2 (reflect; it doesn't damage the attacker though)
				if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
					if(player.pers["team"] == self.pers["team"]) continue;

				// If player is targeted and hit, set fixed damage and long burntime
				if(trace_entity == player)
				{
					iDamage = 20;
					iBurntime = 10;
				}
				else
				{
					// Skip if player is not near flame target
					trace_dist = distance(flame_target, player.origin);
					if( !isAlive(player) || player.sessionstate != "playing" || trace_dist >= 100 ) continue;

					// Check if free path between flame target and player
					trace = bullettrace(flame_target, player.origin, true, undefined);
					if(trace["fraction"] != 1 && isDefined(trace["entity"]) && trace["entity"] == player)
					{
						// Calculate damage and burntime (depending on distance)
						iDamage = int(20 * (1 - (trace_dist / 100)));
						if(trace_dist <= (100 / 2)) iBurntime = 6;
							else iBurntime = 3;
					}
					else continue;
				}

				// If player is already on fire, damage depends on flame index
				if(isDefined(player.ex_isonfire)) iDamage = int(iDamage * (flame_index / 10));

				// Burn and damage the player
				if(iDamage < player.health)
				{
					player.health = player.health - iDamage;
					player thread burnPlayer(self, sWeapon, iBurntime);
				}
				else player thread [[level.callbackPlayerDamage]](self, self, iDamage, 1, "MOD_PROJECTILE", sWeapon, undefined, (0,0,1), "none", 0);
			}
		}
	}
}

showFlame(flame_pointer, flame_loop, flame_target)
{
	self thread playFlameFX(flame_loop);

	self moveto(flame_target, 1);
	wait( [[level.ex_fpstime]](1) );

	self delete();
	if(isDefined(flame_pointer)) flame_pointer.inuse = false;
}

playFlameFX(loopTime)
{
	wait( [[level.ex_fpstime]](0.05) );
	while(isDefined(self))
	{
		playfx(level.ex_effect["flamethrower"], self.origin);
		wait( [[level.ex_fpstime]](loopTime) );
	}
}

getEyeTrace(num)
{
	self endon("kill_thread");

	startOrigin = self getEye() + self getPlayerEyeOffset();
	forward = anglesToForward(self getplayerangles());
	forward = (forward[0] * num, forward[1] * num, forward[2] * num);
	endOrigin = startOrigin + forward;
	trace = bulletTrace(startOrigin, endOrigin, false, undefined);

	return trace;
}

getTargetedPos(num)
{
	self endon("kill_thread");

	startOrigin = self getEye() + self getPlayerEyeOffset();
	forward = anglesToForward(self getplayerangles());
	forward = (forward[0] * num, forward[1] * num, forward[2] * num);
	endOrigin = startOrigin + forward;

	return endOrigin;
}

getPlayerEyeOffset()
{
	self endon("kill_thread");

	offset = (0,0,16); // Stand
	if(self.ex_stance == 1) offset = (0,0,2); // Crouch
	if(self.ex_stance == 2) offset = (0,0,-27); // Prone

	return offset;
}

burnPlayer(eAttacker, sWeapon, burntime)
{
	self endon("kill_thread");

	if(isDefined(self.ex_isonfire)) return;
	self.ex_isonfire = 1;

	wait( [[level.ex_fpstime]](0.5) );
	if(randomint(100) > 10) self playsound("scream"); // 90% chance they scream

	burntime = burntime * 4; // loop is quarter of a second, so x4 to convert to seconds

	for(i = 0; i < burntime; i++)
	{
		if(isDefined(self))
		{
			// For every second on fire, player will lose some health
			if(i%4 == 0)
			{
				playfxontag(level.ex_effect["fire_torso"], self, "j_spine2"); // avoid j_spine1 for diana

				switch(randomint(13))
				{
					case 0: tag = "j_hip_le"; break;
					case 1: tag = "j_hip_ri"; break;
					case 2: tag = "j_knee_le"; break;
					case 3: tag = "j_knee_ri"; break;
					case 4: tag = "j_ankle_le"; break;
					case 5: tag = "j_ankle_ri"; break;
					case 6: tag = "j_wrist_ri"; break;
					case 7: tag = "j_wrist_le"; break;
					case 8: tag = "j_shoulder_le"; break;
					case 9: tag = "j_shoulder_ri"; break;
					case 10: tag = "j_elbow_le"; break;
					case 11: tag = "j_elbow_ri"; break;
					default: tag = "j_head"; break;
				}

				self thread playBurnFX(tag, level.ex_effect["fire_arm"], .1);

				iDamage = 5;
				if(iDamage < self.health) self.health = self.health - iDamage;
					else self thread [[level.callbackPlayerDamage]](eAttacker, eAttacker, iDamage, 1, "MOD_PROJECTILE", sWeapon, undefined, (0,0,1), "none", 0);
			}
		}

		wait( [[level.ex_fpstime]](0.25) );
	}

	if(isAlive(self)) self.ex_isonfire = undefined;
}

playBurnFX(tag, fxName, loopTime)
{
	self endon("kill_thread");

	while(isDefined(self) && isDefined(self.ex_isonfire))
	{
		playfxOnTag(fxName, self, tag);
		wait( [[level.ex_fpstime]](loopTime) );
	}
}

checkAttached(model)
{
	self endon("kill_thread");

	model_attached = false;
	model_full = "xmodel/" + model;

	attachedSize = self getAttachSize();
	for(i = 0; i < attachedSize; i++)
	{
		attachedModel = self getAttachModelName(i);
		if(attachedModel == model_full)
		{
			model_attached = true;
			break;
		}
	}

	return(model_attached);
}

tankExplosion(eVictim, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(isDefined(eVictim.tankonback))
	{
		eVictim detach("xmodel/ft_tank", "j_spine4");
		eVictim.tankonback = undefined;

		explosion = spawn("script_origin", eVictim.origin);
		playfx(level.ex_effect["artillery"], explosion.origin);
		explosion playSound("artillery_explosion");
		eVictim [[level.ex_callbackPlayerDamage]](eAttacker, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		explosion delete();
	}
}
