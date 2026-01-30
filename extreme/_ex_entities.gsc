#include extreme\_ex_hudcontroller;

init()
{
	level endon("ex_gameover");

	game["entities_removed_gameobjects"] = 0; // subtotal from maps\mp\gametypes\_gameobjects.gsc
	game["entities_removed_class"] = 0;
	game["entities_removed_target"] = 0;
	game["entities_removed_total"] = 0;

	if(level.ex_entities)
	{
		//setCvar("g_listEntity", 1);
		dumpMapEntities("BEFORE");
	}

	// remove turrets
	if(!level.ex_turrets)
	{
		entities_removed = removeEntity("misc_turret", "classname");
		if(entities_removed)
		{
			game["entities_removed_class"] += entities_removed;
			game["entities_removed_total"] += entities_removed;
		}

		entities_removed = removeEntity("misc_mg42", "classname");
		if(entities_removed)
		{
			game["entities_removed_class"] += entities_removed;
			game["entities_removed_total"] += entities_removed;
		}
	}

	// disable minefields
	if(!level.ex_minefields)
	{
		entities_removed = removeEntity("minefield", "targetname");
		if(entities_removed)
		{
			game["entities_removed_target"] += entities_removed;
			game["entities_removed_total"] += entities_removed;
		}
	}

	// remove other entities, and optionally monitor entities
	if(level.ex_entities)
	{
		if((level.ex_entities & 1) == 1) removeMapEntities();
		if((level.ex_entities & 4) == 4) level thread monitorEntitiesOnHUD();
	}
}

removeMapEntities()
{
	entities = [];
	entities_target = [];

	// multi-player entities - classname
	entities[entities.size] = "mp_dm_spawn";
	entities[entities.size] = "mp_tdm_spawn";
	entities[entities.size] = "mp_ctf_spawn_allied";
	entities[entities.size] = "mp_ctf_spawn_axis";
	entities[entities.size] = "mp_sd_spawn_attacker";
	entities[entities.size] = "mp_sd_spawn_defender";
	entities[entities.size] = "mp_lib_spawn_alliesnonjail";
	entities[entities.size] = "mp_lib_spawn_axisnonjail";
	entities[entities.size] = "mp_lib_spawn_alliesinjail";
	entities[entities.size] = "mp_lib_spawn_axisinjail";
	entities[entities.size] = "mp_tkoth_spawn_allied";
	entities[entities.size] = "mp_tkoth_spawn_axis";

	// single-player entities - classname
	entities[entities.size] = "actor_ally_brit_africa_mcgregor";
	entities[entities.size] = "actor_ally_brit_africa_mcgregor_radio";
	entities[entities.size] = "actor_ally_brit_africa_price";
	entities[entities.size] = "actor_ally_brit_africa_reg_bren";
	entities[entities.size] = "actor_ally_brit_africa_reg_pfaust";
	entities[entities.size] = "actor_ally_brit_africa_reg_rifle";
	entities[entities.size] = "actor_ally_brit_africa_reg_sniper";
	entities[entities.size] = "actor_ally_brit_africa_reg_sten";
	entities[entities.size] = "actor_ally_brit_africa_reg_thompson";
	entities[entities.size] = "actor_ally_brit_normandy_mcgregor";
	entities[entities.size] = "actor_ally_brit_normandy_price";
	entities[entities.size] = "actor_ally_brit_normandy_reg_bren";
	entities[entities.size] = "actor_ally_brit_normandy_reg_pfaust";
	entities[entities.size] = "actor_ally_brit_normandy_reg_pschreck";
	entities[entities.size] = "actor_ally_brit_normandy_reg_rifle";
	entities[entities.size] = "actor_ally_brit_normandy_reg_sniper";
	entities[entities.size] = "actor_ally_brit_normandy_reg_sten";
	entities[entities.size] = "actor_ally_brit_normandy_reg_thompson";
	entities[entities.size] = "actor_ally_ranger_nrmdy_30calportable";
	entities[entities.size] = "actor_ally_ranger_nrmdy_blake";
	entities[entities.size] = "actor_ally_ranger_nrmdy_braeburn";
	entities[entities.size] = "actor_ally_ranger_nrmdy_coffey";
	entities[entities.size] = "actor_ally_ranger_nrmdy_injured";
	entities[entities.size] = "actor_ally_ranger_nrmdy_mccloskey";
	entities[entities.size] = "actor_ally_ranger_nrmdy_mccloskey_30cal";
	entities[entities.size] = "actor_ally_ranger_nrmdy_medic";
	entities[entities.size] = "actor_ally_ranger_nrmdy_randall";
	entities[entities.size] = "actor_ally_ranger_nrmdy_reg_bar";
	entities[entities.size] = "actor_ally_ranger_nrmdy_reg_BAR"; // mp_anzio
	entities[entities.size] = "actor_ally_ranger_nrmdy_reg_carbine";
	entities[entities.size] = "actor_ally_ranger_nrmdy_reg_garand";
	entities[entities.size] = "actor_ally_ranger_nrmdy_reg_pschreck";
	entities[entities.size] = "actor_ally_ranger_nrmdy_reg_sniper";
	entities[entities.size] = "actor_ally_ranger_nrmdy_reg_thompson";
	entities[entities.size] = "actor_ally_ranger_nrmdy_rescuer";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_30calportable";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_braeburn";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_coffey";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_mccloskey";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_mccloskey_30cal";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_medic";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_randall";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_reg_bar";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_reg_BAR"; // mp_anzio
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_reg_carbine";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_reg_garand";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_reg_pschreck";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_reg_sniper";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_reg_thompson";
	entities[entities.size] = "actor_ally_ranger_wet_nrmdy_rescuer";
	entities[entities.size] = "actor_ally_rus_antanova";
	entities[entities.size] = "actor_ally_rus_commissar_letlev";
	entities[entities.size] = "actor_ally_rus_commissar_pistol";
	entities[entities.size] = "actor_ally_rus_commissar_ppsh";
	entities[entities.size] = "actor_ally_rus_gen_popov";
	entities[entities.size] = "actor_ally_rus_helmetguy";
	entities[entities.size] = "actor_ally_rus_reg_enforcer";
	entities[entities.size] = "actor_ally_rus_reg_male";
	entities[entities.size] = "actor_ally_rus_reg_mosin";
	entities[entities.size] = "actor_ally_rus_reg_pfaust";
	entities[entities.size] = "actor_ally_rus_reg_pps42";
	entities[entities.size] = "actor_ally_rus_reg_ppsh";
	entities[entities.size] = "actor_ally_rus_reg_pschreck";
	entities[entities.size] = "actor_ally_rus_reg_sniper";
	entities[entities.size] = "actor_ally_rus_reg_svt40";
	entities[entities.size] = "actor_ally_rus_volsky";
	entities[entities.size] = "actor_axis_afrikakorp_officer_luger";
	entities[entities.size] = "actor_axis_afrikakorp_officer_mp40";
	entities[entities.size] = "actor_axis_afrikakorp_reg_bergmann";
	entities[entities.size] = "actor_axis_afrikakorp_reg_g43";
	entities[entities.size] = "actor_axis_afrikakorp_reg_kar98";
	entities[entities.size] = "actor_axis_afrikakorp_reg_kar98scoped";
	entities[entities.size] = "actor_axis_afrikakorp_reg_mg42";
	entities[entities.size] = "actor_axis_afrikakorp_reg_mg42portable";
	entities[entities.size] = "actor_axis_afrikakorp_reg_mp40";
	entities[entities.size] = "actor_axis_afrikakorp_reg_pfaust";
	entities[entities.size] = "actor_axis_afrikakorp_reg_pschreck";
	entities[entities.size] = "actor_axis_afrikakorp_reg_thin";
	entities[entities.size] = "actor_axis_nrmdy_wehr_injured";
	entities[entities.size] = "actor_axis_nrmdy_wehr_officer_luger";
	entities[entities.size] = "actor_axis_nrmdy_wehr_officer_mp40";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_g43";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_kar98";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_kar98scoped";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_mg42";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_mg42portable";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_mp40";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_mp44";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_pfaust";
	entities[entities.size] = "actor_axis_nrmdy_wehr_reg_pschreck";
	entities[entities.size] = "actor_axis_snow_wehr_officer_luger";
	entities[entities.size] = "actor_axis_snow_wehr_officer_mp40";
	entities[entities.size] = "actor_axis_snow_wehr_reg_bergmann";
	entities[entities.size] = "actor_axis_snow_wehr_reg_g43";
	entities[entities.size] = "actor_axis_snow_wehr_reg_kar98k";
	entities[entities.size] = "actor_axis_snow_wehr_reg_kar98scoped";
	entities[entities.size] = "actor_axis_snow_wehr_reg_mg42";
	entities[entities.size] = "actor_axis_snow_wehr_reg_mg42portable";
	entities[entities.size] = "actor_axis_snow_wehr_reg_mp40";
	entities[entities.size] = "actor_axis_snow_wehr_reg_pfaust";
	entities[entities.size] = "actor_axis_snow_wehr_reg_prisoner";
	entities[entities.size] = "actor_axis_snow_wehr_reg_pshreck";
	entities[entities.size] = "info_grenade_hint";
	entities[entities.size] = "info_notnull";
	entities[entities.size] = "info_notnull_big";
	entities[entities.size] = "info_null";
	entities[entities.size] = "info_player_deathmatch";
	entities[entities.size] = "info_player_start";
	entities[entities.size] = "info_vehicle_node";
	entities[entities.size] = "info_vehicle_node_rotate";
	entities[entities.size] = "info_volume";
	entities[entities.size] = "node_balcony";
	entities[entities.size] = "node_concealment_crouch";
	entities[entities.size] = "node_concealment_prone";
	entities[entities.size] = "node_concealment_stand";
	entities[entities.size] = "node_cover_crouch";
	entities[entities.size] = "node_cover_crouch_window";
	entities[entities.size] = "node_cover_left";
	entities[entities.size] = "node_cover_prone";
	entities[entities.size] = "node_cover_right";
	entities[entities.size] = "node_cover_stand";
	entities[entities.size] = "node_cover_wide_left";
	entities[entities.size] = "node_cover_wide_right";
	entities[entities.size] = "node_negotiation_begin";
	entities[entities.size] = "node_negotiation_end";
	entities[entities.size] = "node_pathnode";
	entities[entities.size] = "node_reacquire";
	entities[entities.size] = "node_scripted";
	entities[entities.size] = "node_turret";

	// disposable entities - targetname
	entities_target[entities_target.size] = "lantern_glowFX_origin";
	entities_target[entities_target.size] = "flash_dark";
	entities_target[entities_target.size] = "flash_bright";
	entities_target[entities_target.size] = "nv_flash";

	entities_keep = [];

	switch(level.ex_currentgt)
	{
		case "chq":
		case "cnq":
		case "hq":
		case "htf":
		case "lts":
		case "rbcnq":
		case "tdm":
		case "vip":
			entities_keep[entities_keep.size] = "mp_tdm_spawn";
			break;
		case "ctf":
		case "rbctf":
			entities_keep[entities_keep.size] = "mp_ctf_spawn_allied";
			entities_keep[entities_keep.size] = "mp_ctf_spawn_axis";
			break;
		case "ctfb":
			entities_keep[entities_keep.size] = "mp_ctf_spawn_allied";
			entities_keep[entities_keep.size] = "mp_ctf_spawn_axis";
			if(level.random_flag_position) entities_keep[entities_keep.size] = "mp_dm_spawn"; // random flag position
			break;
		case "dm":
		case "hm":
		case "lms":
			entities_keep[entities_keep.size] = "mp_dm_spawn";
			break;
		case "dom":
		case "ons":
			if(isDefined(level.spawntype))
			{
				switch(level.spawntype)
				{
					case "tdm":
						entities_keep[entities_keep.size] = "mp_tdm_spawn";
						if(!level.use_static_flags) entities_keep[entities_keep.size] = "mp_dm_spawn"; // dynamic flags
						break;
					case "sd":
						entities_keep[entities_keep.size] = "mp_sd_spawn_attacker";
						entities_keep[entities_keep.size] = "mp_sd_spawn_defender";
						if(!level.use_static_flags) entities_keep[entities_keep.size] = "mp_dm_spawn"; // dynamic flags
						break;
					case "ctf":
						entities_keep[entities_keep.size] = "mp_ctf_spawn_allied";
						entities_keep[entities_keep.size] = "mp_ctf_spawn_axis";
						if(!level.use_static_flags) entities_keep[entities_keep.size] = "mp_dm_spawn"; // dynamic flags
						break;
					default:
						entities_keep[entities_keep.size] = "mp_dm_spawn";
						break;
				}
			}
			else entities_keep[entities_keep.size] = "mp_dm_spawn";
			break;
		case "esd":
		case "sd":
			entities_keep[entities_keep.size] = "mp_sd_spawn_attacker";
			entities_keep[entities_keep.size] = "mp_sd_spawn_defender";
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
				entities_keep[entities_keep.size] = "mp_dm_spawn";
			if(isDefined(spawntype_active["tdm"]) || isDefined(spawntype_active["hq"]))
				entities_keep[entities_keep.size] = "mp_tdm_spawn";
			if(isDefined(spawntype_active["ctfp"]))
			{
				entities_keep[entities_keep.size] = "mp_ctf_spawn_allied";
				entities_keep[entities_keep.size] = "mp_ctf_spawn_axis";
			}
			if(isDefined(spawntype_active["sdp"]))
			{
				entities_keep[entities_keep.size] = "mp_sd_spawn_attacker";
				entities_keep[entities_keep.size] = "mp_sd_spawn_defender";
			}
			if(isDefined(spawntype_active["hq"]))
				entities_keep[entities_keep.size] = "hqradio";
			break;
		case "lib":
			entities_keep[entities_keep.size] = "mp_lib_spawn_alliesnonjail";
			entities_keep[entities_keep.size] = "mp_lib_spawn_axisnonjail";
			entities_keep[entities_keep.size] = "mp_lib_spawn_alliesinjail";
			entities_keep[entities_keep.size] = "mp_lib_spawn_axisinjail";
			break;
		case "tkoth":
			if(isDefined(level.spawn))
			{
				switch(level.spawn)
				{
					case "tkoth":
						entities_keep[entities_keep.size] = "mp_tkoth_spawn_allied";
						entities_keep[entities_keep.size] = "mp_tkoth_spawn_axis";
						break;
					case "sd":
						entities_keep[entities_keep.size] = "mp_sd_spawn_attacker";
						entities_keep[entities_keep.size] = "mp_sd_spawn_defender";
						break;
					case "ctf":
						entities_keep[entities_keep.size] = "mp_ctf_spawn_allied";
						entities_keep[entities_keep.size] = "mp_ctf_spawn_axis";
						break;
				}
			}
			else return;
			break;
		default:
			return;
	}

	// If heli is enabled, keep DM spawnpoints
	if(level.ex_specials && level.ex_heli) entities_keep[entities_keep.size] = "mp_dm_spawn";

	// If ammo crates are enabled, keep TDM spawnpoints
	if(level.ex_amc_perteam)
	{
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "hm" || level.ex_currentgt == "lms") entities_keep[entities_keep.size] = "mp_dm_spawn";
			else entities_keep[entities_keep.size] = "mp_tdm_spawn";
	}

	// remove classname entities
	for(i = 0; i < entities.size; i++)
	{
		remove = true;

		for(j = 0; j < entities_keep.size; j++)
			if(entities[i] == entities_keep[j]) remove = false;

		if(remove)
		{
			entities_removed = removeEntity(entities[i], "classname");
			if(entities_removed)
			{
				game["entities_removed_class"] += entities_removed;
				game["entities_removed_total"] += entities_removed;
			}
		}
	}

	// remove targetname entities
	for(i = 0; i < entities_target.size; i++)
	{
		remove = true;

		for(j = 0; j < entities_keep.size; j++)
			if(entities_target[i] == entities_keep[j]) remove = false;

		if(remove)
		{
			entities_removed = removeEntity(entities_target[i], "targetname");
			if(entities_removed)
			{
				game["entities_removed_target"] += entities_removed;
				game["entities_removed_total"] += entities_removed;
			}
		}
	}
}

removeEntity(entity_name, entity_key)
{
	entities_removed = 0;
	entities = getentarray(entity_name, entity_key);

	if(!entities.size) return(entities_removed);

	for(i = 0; i < entities.size; i++)
	{
		entities_removed++;
		entities[i] delete();
	}

	logprint("ENTITIES: removed " + numToStr(entities_removed, 3) + " entities of \""+ entity_name + "\"\n");
	return(entities_removed);
}

reportRemovedEntities()
{
	if(game["entities_removed_gameobjects"]) logprint("ENTITIES: subtotal " + numToStr(game["entities_removed_gameobjects"], 3) + " script_gameobjectname entities\n");
	if(game["entities_removed_class"]) logprint("ENTITIES: subtotal " + numToStr(game["entities_removed_class"], 3) + " classname entities\n");
	if(game["entities_removed_target"]) logprint("ENTITIES: subtotal " + numToStr(game["entities_removed_target"], 3) + " targetname entities\n");
	if(game["entities_removed_total"]) logprint("ENTITIES: removed a total of " + game["entities_removed_total"] + " entities\n");
}

monitorEntitiesOnHUD()
{
	level endon("ex_gameover");

	hud_index = -1;
	if(level.ex_entities_debug)
		hud_index = levelHudCreate("entitiesdebug", undefined, 630, 468, 1, (0, 1, 0), 0.7, 999, "fullscreen", "fullscreen", "right", "middle", false, false);

	if(level.ex_entities_act)
	{
		// level.ex_entities_defcon set in varcache to let other features start
		// defcon modes: 4 = normal, 3 = elevated, 2 = high, 1 = maximum
		level.ex_entities_defcon_old = level.ex_entities_defcon;
		level.ex_entities_defcon_cnt = 0;
		level.ex_entities_defcon_msg = true;
	}

	setcvar("entities_dump", "");

	while(true)
	{
		wait( [[level.ex_fpstime]](5) );
		enttotal = getTotalEntities();

		dumpcommand = getcvar("entities_dump");
		if(dumpcommand != "")
		{
			setcvar("entities_dump", "");
			thread dumpMapEntities("SNAPSHOT");
		}

		//   0 - 799 : green (normal, defcon 4)
		// 800 - 849 : yellow (elevated, defcon 3)
		// 850 - 899 : red (high, defcon 2)
		// 900+      : end map (maximum, defcon 1)
		if(enttotal >= 850)
		{
			if(level.ex_entities_act)
			{
				if(enttotal >= 900)
				{
					setDefCon(1);

					botcount = 0;
					players = level.players;
					for(i = 0; i < players.size; i++)
						if(isDefined(players[i].pers["isbot"])) botcount++;

					if(botcount)
					{
						if(level.ex_statstotal) extreme\_ex_statstotal::writeStatsAll(true);
						level notify("restarting");
						wait( [[level.ex_fpstime]](1) );
						map_restart(true);
					}
					else thread extreme\_ex_cmdmonitor::endmap();
					return;
				}
				else setDefCon(2);
			}
			if(level.ex_entities_debug && hud_index != -1) levelHudSetColor(hud_index, (1, 0, 0));
		}
		else if(enttotal >= 800)
		{
			if(level.ex_entities_act) setDefCon(3);
			if(level.ex_entities_debug && hud_index != -1) levelHudSetColor(hud_index, (1, 1, 0));
		}
		else
		{
			if(level.ex_entities_act) setDefCon(4);
			if(level.ex_entities_debug && hud_index != -1) levelHudSetColor(hud_index, (0, 1, 0));
		}

		if(level.ex_entities_debug && hud_index != -1) levelHudSetValue(hud_index, enttotal);
	}
}

setDefCon(defcon)
{
	if(level.ex_entities_defcon != defcon)
	{
		level.ex_entities_defcon_old = level.ex_entities_defcon;
		level.ex_entities_defcon = defcon;

		// no return from defcon 1, so show message immediately
		if(level.ex_entities_defcon == 1) iprintlnbold(&"MISC_DEFCON1");

		// if previous mode did not hold for x cycles, do not show restore message
		if(level.ex_entities_defcon > level.ex_entities_defcon_old && level.ex_entities_defcon_cnt < 5) level.ex_entities_defcon_msg = false;
			else level.ex_entities_defcon_msg = true;
		level.ex_entities_defcon_cnt = 0;
	}
	else if(level.ex_entities_defcon != level.ex_entities_defcon_old)
	{
		level.ex_entities_defcon_cnt++;

		// inform players if defcon mode held for x cycles
		if(level.ex_entities_defcon_cnt == 5)
		{
			if(level.ex_entities_defcon_msg)
			{
				switch(level.ex_entities_defcon)
				{
					case 2: iprintlnbold(&"MISC_DEFCON2"); break;
					case 3: iprintlnbold(&"MISC_DEFCON3"); break;
					case 4: iprintlnbold(&"MISC_DEFCON4"); break;
				}
			}
		}
	}
}

getTotalEntities()
{
	entities = getentarray();
	return(entities.size);
}

dumpMapEntities(log_prefix)
{
	level endon("ex_gameover");

	if(!isDefined(log_prefix)) log_prefix = "DUMP";

	entities = getentarray();

	if((level.ex_entities & 1) == 1) logprint("ENTITIES: " + log_prefix + ": raw entities array holds " + entities.size + " records\n");
	if((level.ex_entities & 2) != 2) return;

	entities_array = [];

	for(i = 0; i < entities.size; i++)
	{
		entity = entities[i];

		if(isDefined(entity))
		{
			entity_no = entity getentitynumber();

			array_index = entities_array.size;
			entities_array[array_index] = spawnstruct();
			entities_array[array_index].entity_no = entity_no;
			if(isPlayer(entity))
			{
				entities_array[array_index].name = entity.name;
				entities_array[array_index].classname = "player";
				entities_array[array_index].targetname = "";
				entities_array[array_index].script_gameobjectname = "";
				entities_array[array_index].model = "";
			}
			else
			{
				entities_array[array_index].name = "";
				if(isDefined(entity.classname)) entities_array[array_index].classname = entity.classname;
					else entities_array[array_index].classname = "";
				if(isDefined(entity.targetname)) entities_array[array_index].targetname = entity.targetname;
					else entities_array[array_index].targetname = "";
				if(isDefined(entity.script_gameobjectname)) entities_array[array_index].script_gameobjectname = entity.script_gameobjectname;
					else entities_array[array_index].script_gameobjectname = "";
				if(isDefined(entity.model)) entities_array[array_index].model = entity.model;
					else entities_array[array_index].model = "";
			}

			if(isDefined(entity.origin)) entities_array[array_index].origin = entity.origin;
				else entities_array[array_index].origin = undefined;
			if(isDefined(entity.angles)) entities_array[array_index].angles = entity.angles;
				else entities_array[array_index].angles = undefined;
		}
	}

	logprint("ENTITIES: " + log_prefix + ": processed entities array holds " + entities_array.size + " records (highest entity_no = " + entities_array[entities_array.size-1].entity_no + ")\n");

	array_index = 0;
	for(i = 0; i < 1024; i++)
	{
		if(i <= entities_array[entities_array.size-1].entity_no)
		{
			if(i == entities_array[array_index].entity_no)
			{
				string_out = "";
				spacer_out = false;

				if(entities_array[array_index].classname != "")
				{
					string_out += "classname: " + entities_array[array_index].classname;
					spacer_out = true;
				}

				if(entities_array[array_index].name != "")
				{
					if(spacer_out) string_out += ", ";
					string_out += "name: " + entities_array[array_index].name;
					spacer_out = true;
				}

				if(entities_array[array_index].targetname != "")
				{
					if(spacer_out) string_out += ", ";
					string_out += "targetname: " + entities_array[array_index].targetname;
					spacer_out = true;
				}

				if(entities_array[array_index].script_gameobjectname != "")
				{
					if(spacer_out) string_out += ", ";
					string_out += "script_gameobjectname: " + entities_array[array_index].script_gameobjectname;
					spacer_out = true;
				}

				if(entities_array[array_index].model != "")
				{
					if(spacer_out) string_out += ", ";
					string_out += "model: " + entities_array[array_index].model;
					spacer_out = true;
				}

				if(isDefined(entities_array[array_index].origin))
				{
					if(spacer_out) string_out += ", ";
					string_out += "origin: " + entities_array[array_index].origin;
					spacer_out = true;
				}

				if(isDefined(entities_array[array_index].angles))
				{
					if(spacer_out) string_out += ", ";
					string_out += "angles: " + entities_array[array_index].angles;
				}

				if(string_out != "") logprint("[" + numToStr(entities_array[array_index].entity_no, 4) + "] " + string_out + "\n");
					else logprint("[" + numToStr(entities_array[array_index].entity_no, 4) + "] (unknown)\n");

				array_index++;
			}
			else logprint("[" + numToStr(i, 4) + "] (null)\n");
		}
		else logprint("[" + numToStr(i, 4) + "] > (null)\n");
	}
}

dumpSingleEntity(entity)
{
	if(!isDefined(entity)) return;

	entity_no = entity getentitynumber();
	entity_struct = spawnstruct();
	entity_struct.entity_no = entity_no;
	if(isPlayer(entity))
	{
		entity_struct.name = entity.name;
		entity_struct.classname = "player";
		entity_struct.targetname = "";
		entity_struct.script_gameobjectname = "";
		entity_struct.model = "";
	}
	else
	{
		entity_struct.name = "";
		if(isDefined(entity.classname)) entity_struct.classname = entity.classname;
			else entity_struct.classname = "";
		if(isDefined(entity.targetname)) entity_struct.targetname = entity.targetname;
			else entity_struct.targetname = "";
		if(isDefined(entity.script_gameobjectname)) entity_struct.script_gameobjectname = entity.script_gameobjectname;
			else entity_struct.script_gameobjectname = "";
		if(isDefined(entity.model)) entity_struct.model = entity.model;
			else entity_struct.model = "";
	}

	if(isDefined(entity.origin)) entity_struct.origin = entity.origin;
		else entity_struct.origin = undefined;
	if(isDefined(entity.angles)) entity_struct.angles = entity.angles;
		else entity_struct.angles = undefined;

	string_out = "";
	spacer_out = false;

	if(entity_struct.classname != "")
	{
		string_out += "classname: " + entity_struct.classname;
		spacer_out = true;
	}

	if(entity_struct.name != "")
	{
		if(spacer_out) string_out += ", ";
		string_out += "name: " + entity_struct.name;
		spacer_out = true;
	}

	if(entity_struct.targetname != "")
	{
		if(spacer_out) string_out += ", ";
		string_out += "targetname: " + entity_struct.targetname;
		spacer_out = true;
	}

	if(entity_struct.script_gameobjectname != "")
	{
		if(spacer_out) string_out += ", ";
		string_out += "script_gameobjectname: " + entity_struct.script_gameobjectname;
		spacer_out = true;
	}

	if(entity_struct.model != "")
	{
		if(spacer_out) string_out += ", ";
		string_out += "model: " + entity_struct.model;
		spacer_out = true;
	}

	if(isDefined(entity_struct.origin))
	{
		if(spacer_out) string_out += ", ";
		string_out += "origin: " + entity_struct.origin;
		spacer_out = true;
	}

	if(isDefined(entity_struct.angles))
	{
		if(spacer_out) string_out += ", ";
		string_out += "angles: " + entity_struct.angles;
	}

	if(string_out != "") logprint("[" + numToStr(entity_struct.entity_no, 4) + "] " + string_out + "\n");
		else logprint("[" + numToStr(entity_struct.entity_no, 4) + "] (unknown)\n");
}

numToStr(number, length)
{
	string = "" + number;
	if(string.size > length) length = string.size;
	diff = length - string.size;
	if(diff) string = dupChar("0", diff) + string;
	return(string);
}

dupChar(char, length)
{
	string = "";
	for(i = 0; i < length; i++) string = string + char;
	return(string);
}
