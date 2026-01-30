#include extreme\_ex_hudcontroller;

init()
{
	// Time limit
	if(!isDefined(game["timelimit"])) game["timelimit"] = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_timelimit", 30, 0, 1440, "float");
	setCvar("scr_" + level.ex_currentgt + "_timelimit", game["timelimit"]);

	// Score limit
	if(!isDefined(game["scorelimit"])) game["scorelimit"] = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_scorelimit", 100, 0, 99999, "int");
	setCvar("scr_" + level.ex_currentgt + "_scorelimit", game["scorelimit"]);

	// DOM, ESD, FT, LIB, LTS, ONS, RBCNQ, RBCTF, SD
	if(level.ex_roundbased)
	{
		// Round limit
		if(!isDefined(game["roundlimit"])) game["roundlimit"] = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_roundlimit", 5, 0, 99, "int");
		setCvar("scr_" + level.ex_currentgt + "_roundlimit", game["roundlimit"]);

		// Round length
		if(!isDefined(game["roundlength"])) game["roundlength"] = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_roundlength", 5, 1, 1440, "float");
		setCvar("scr_" + level.ex_currentgt + "_roundlength", game["roundlength"]);
	}

	// Conversion of stock server Cvars
	setCvar("g_allowvote", [[level.ex_drm]]("g_allowvote", 1, 0, 1, "int")); // level.allowvote in _serversettings.gsc
	setCvar("g_deadchat", [[level.ex_drm]]("g_deadchat", 1, 0, 1, "int")); // not script or menu related
	setCvar("g_debugdamage", [[level.ex_drm]]("g_debugdamage", 0, 0, 1, "int")); // cvar read by gametype scripts
	setCvar("g_oldvoting", [[level.ex_drm]]("g_oldvoting", 1, 0, 1, "int")); // not script or menu related
	setCvar("scr_friendlyfire", [[level.ex_drm]]("scr_friendlyfire", 0, 0, 3, "int")); // level.friendlyfire in _serversettings.gsc
	setCvar("scr_killcam", [[level.ex_drm]]("scr_killcam", 0, 0, 1, "int")); // level.killcam in _killcam.gsc
	setCvar("scr_spectateenemy", [[level.ex_drm]]("scr_spectateenemy", 0, 0, 1, "int")); // level.spectateenemy in _spectating.gsc
	setCvar("scr_spectatefree", [[level.ex_drm]]("scr_spectatefree", 1, 0, 1, "int")); // level.spectatefree in _spectating.gsc

	// Global switch for spectating when dead
	level.ex_spectatedead = [[level.ex_drm]]("ex_spectatedead", 0, 0, 1, "int");

	// Percentage of original damage to reflect (scr_friendlyfire 2)
	level.ex_friendlyfire_reflect = [[level.ex_drm]]("ex_friendlyfire_reflect", 50, 1, 100, "int") / 100;

	// Points for killing a player
	level.ex_points_kill = [[level.ex_drm]]("ex_points_kill", 1, 1, 100, "int");

	// Hide objectives when in killcam mode
	level.ex_killcam_hideobj = [[level.ex_drm]]("ex_killcam_hideobj", 0, 0, 1, "int");

	// Draws a team icon over teammates (_friendicons.gsc)
	level.drawfriend = [[level.ex_drm]]("scr_drawfriend", 1, 0, 1, "int");
	setCvar("scr_drawfriend", level.drawfriend);

	// Force respawning (game type scripts)
	level.forcerespawn = [[level.ex_drm]]("scr_forcerespawn", 0, 0, 1,"int");
	setCvar("scr_forcerespawn", level.forcerespawn);

	// If death music is on, this overrides forcespawn
	if(level.forcerespawn && level.ex_deathmusic)
	{
		setCvar("scr_forcerespawn", "0");
		level.forcerespawn = false;
	}

	// Respawn delay
	level.respawndelay = [[level.ex_drm]]("scr_respawndelay", 0, 0, 60, "int");
	setCvar("scr_respawndelay", level.respawndelay);

	// Additional respawn delay
	if(level.respawndelay)
	{
		level.ex_respawndelay_subzero = [[level.ex_drm]]("ex_respawndelay_subzero", 0, 0, 60, "int");
		level.ex_respawndelay_class = [[level.ex_drm]]("ex_respawndelay_class", 0, 0, 2, "int");
		if(level.ex_respawndelay_class)
		{
			level.ex_respawndelay_sniper = [[level.ex_drm]]("ex_respawndelay_sniper", 0, 0, 60, "int");
			level.ex_respawndelay_rifle = [[level.ex_drm]]("ex_respawndelay_rifle", 0, 0, 60, "int");
			level.ex_respawndelay_mg = [[level.ex_drm]]("ex_respawndelay_mg", 0, 0, 60, "int");
			level.ex_respawndelay_smg = [[level.ex_drm]]("ex_respawndelay_smg", 0, 0, 60, "int");
			level.ex_respawndelay_shot = [[level.ex_drm]]("ex_respawndelay_shot", 0, 0, 60, "int");
			level.ex_respawndelay_rl = [[level.ex_drm]]("ex_respawndelay_rl", 0, 0, 60, "int");
		}
	}

	// Auto Team Balancing (_teams.gsc)
	level.teambalance = [[level.ex_drm]]("scr_teambalance", 1, 0, 1, "int");
	setCvar("scr_teambalance", level.teambalance);

	level.ex_teambalance_delay = [[level.ex_drm]]("ex_teambalance_delay", 60, 0, 300, "int");
	level.ex_teambalance_interval = [[level.ex_drm]]("ex_teambalance_interval", 60, 10, 300, "int");

	// Voiceover on flag events
	level.ex_flag_voiceover = [[level.ex_drm]]("ex_flag_voiceover", 15, 0, 15, "int");

	// Drop flag at will
	level.ex_flag_drop = [[level.ex_drm]]("ex_flag_drop", 0, 0, 1, "int");

	// Retreat monitor
	level.ex_flag_retreat = [[level.ex_drm]]("ex_flag_retreat", 0, 0, 31, "int");
	if(level.ex_currentgt != "ctf" && level.ex_currentgt != "ctfb" && level.ex_currentgt != "rbctf") level.ex_flag_retreat = 0;

	// initialize scores
	if(level.ex_teamplay) teamScoreInit();

	// set up function aliases for score handling
	level.pscoreproc = ::playerScore;
	level.tscoreproc = ::teamScore;

	// set game type specific variables
	switch(level.ex_currentgt)
	{
		case "chq": chq_init(); break;
		case "cnq": cnq_init(); break;
		case "ctf": ctf_init(); break;
		case "ctfb": ctfb_init(); break;
		case "dm": dm_init(); break;
		case "dom": dom_init(); break;
		case "esd": esd_init(); break;
		case "ft": ft_init(); break;
		case "hm": hm_init(); break;
		case "hq": hq_init(); break;
		case "htf": htf_init(); break;
		case "ihtf": ihtf_init(); break;
		case "lib": lib_init(); break;
		case "lms": lms_init(); break;
		case "lts": lts_init(); break;
		case "ons": ons_init(); break;
		case "rbcnq": rbcnq_init(); break;
		case "rbctf": rbctf_init(); break;
		case "sd": sd_init(); break;
		case "tdm": tdm_init(); break;
		case "tkoth": tkoth_init(); break;
		case "vip": vip_init(); break;
	}
}

chq_init()
{
	level.radioradius = [[level.ex_drm]]("ex_chq_radio_radius", 10, 1, 12, "int") * 12;
	level.zradioradius = [[level.ex_drm]]("ex_chq_radio_zradius", 6, 1, 12, "int") * 12;
	level.ex_custom_radios = [[level.ex_drm]]("ex_chq_custom_radios", 1, 0, 1, "int");
	level.ex_hq_radio_spawntime = [[level.ex_drm]]("ex_chq_radio_spawntime", 45, 0, 240, "int");
	level.ex_hq_radio_holdtime = [[level.ex_drm]]("ex_chq_radio_holdtime", 120, 60, 1440, "int");
	level.ex_hq_radio_compass = [[level.ex_drm]]("ex_chq_radio_compass", 0, 0, 1, "int");
	level.ex_hqpoints_teamcap = [[level.ex_drm]]("ex_chqpoints_teamcap", 0, 0, 999, "int");
	level.ex_hqpoints_teamneut = [[level.ex_drm]]("ex_chqpoints_teamneut", 10, 0, 999, "int");
	level.ex_hqpoints_playercap = [[level.ex_drm]]("ex_chqpoints_playercap", 2, 0, 999, "int");
	level.ex_hqpoints_playerneut = [[level.ex_drm]]("ex_chqpoints_playerneut", 2, 0, 999, "int");
	level.ex_hqpoints_defpps = [[level.ex_drm]]("ex_chqpoints_defpps", 1, 0, 999, "int");
	level.ex_hqpoints_radius = [[level.ex_drm]]("ex_chqpoints_radius", 40, 0, 200, "int") * 12;
}

cnq_init()
{
	level.cnq_initialobj = [[level.ex_drm]]("scr_cnq_initialobjective", 1, 1, 3, "int");
	if(level.cnq_initialobj != 1 && level.cnq_initialobj != 3) level.cnq_initialobj = 1;
	level.spawnmethod = [[level.ex_drm]]("scr_cnq_spawnmethod", "default", "", "", "string");
	if(level.spawnmethod != "default" && level.spawnmethod != "random") level.spawnmethod = "default";
	level.team_obj_points = [[level.ex_drm]]("scr_cnq_team_objective_points", 10, 0, 999, "int");
	level.team_bonus_points = [[level.ex_drm]]("scr_cnq_team_bonus_points", 15, 0, 999, "int");
	level.player_obj_points = [[level.ex_drm]]("scr_cnq_player_objective_points", 10, 0, 999, "int");
	level.player_bonus_points = [[level.ex_drm]]("scr_cnq_player_bonus_points", 15, 0, 999, "int");
	level.cnq_campaign_mode = [[level.ex_drm]]("scr_cnq_campaign", 1, 0, 1, "int");
	level.showobj_hud = [[level.ex_drm]]("scr_cnq_showobj_hud", 1, 0, 1, "int");
	level.cnq_debug = [[level.ex_drm]]("scr_cnq_debug", 0, 0, 1, "int");
}

ctf_init()
{
	level.ex_ctfpoints_playercf = [[level.ex_drm]]("ex_ctfpoints_playercf", 10, 0, 999, "int");
	level.ex_ctfpoints_playerrf = [[level.ex_drm]]("ex_ctfpoints_playerrf", 2, 0, 999, "int");
	level.ex_ctfpoints_playersf = [[level.ex_drm]]("ex_ctfpoints_playersf", 2, 0, 999, "int");
	level.ex_ctfpoints_playertf = [[level.ex_drm]]("ex_ctfpoints_playertf", 1, 0, 999, "int");
	level.ex_ctfpoints_playerkf = [[level.ex_drm]]("ex_ctfpoints_playerkf", 1, 0, 999, "int");
	level.flagautoreturndelay = [[level.ex_drm]]("scr_ctf_flagautoreturndelay", 120, 0, 1440, "int");
}

ctfb_init()
{
	level.ex_ctfbpoints_playercf = [[level.ex_drm]]("ex_ctfbpoints_playercf", 10, 0, 999, "int");
	level.ex_ctfbpoints_playerrf = [[level.ex_drm]]("ex_ctfbpoints_playerrf", 5, 0, 999, "int");
	level.ex_ctfbpoints_playersf = [[level.ex_drm]]("ex_ctfbpoints_playersf", 2, 0, 999, "int");
	level.ex_ctfbpoints_playerpf = [[level.ex_drm]]("ex_ctfbpoints_playerpf", 1, 0, 999, "int");
	level.ex_ctfbpoints_playertf = [[level.ex_drm]]("ex_ctfbpoints_playertf", 1, 0, 999, "int");
	level.ex_ctfbpoints_playerkfo = [[level.ex_drm]]("ex_ctfbpoints_playerkfo", 1, 0, 999, "int");
	level.ex_ctfbpoints_playerkfe = [[level.ex_drm]]("ex_ctfbpoints_playerkfe", 1, 0, 999, "int");
	level.ex_ctfbpoints_defend = [[level.ex_drm]]("ex_ctfbpoints_defend", 1, 0, 999, "int");
	level.ex_ctfbpoints_assist = [[level.ex_drm]]("ex_ctfbpoints_assist", 1, 0, 999, "int");
	level.flagprotectiondistance = [[level.ex_drm]]("scr_ctfb_flagprotectiondistance", 1000, 0, 5000, "int");
	level.show_enemy_own_flag_after_sec = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag_after_sec", 60, 10, 1440, "int");
	level.show_enemy_own_flag_time = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag_time", 60, 10, 1440, "int");
	level.flagautoreturndelay = [[level.ex_drm]]("scr_ctfb_flagautoreturndelay", 120, 0, 1440, "int");
	level.random_flag_position = [[level.ex_drm]]("scr_ctfb_random_flag_position", 0, 0, 1, "int");
	level.show_enemy_own_flag = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag", 1, 0, 1, "int");
}

dm_init()
{
	// No additional settings
}

dom_init()
{
	game["scorelimit"] = 0;
	level.flagsnumber = [[level.ex_drm]]("scr_dom_flagsnumber", 3, 1, 9, "int");
	level.spawndistance = [[level.ex_drm]]("scr_dom_spawndistance", 1000, 250, 5000, "int");
	level.flagcapturetime = [[level.ex_drm]]("scr_dom_flagcapturetime", 10, 1, 30, "int");
	level.pointscaptureflag = [[level.ex_drm]]("scr_dom_pointscaptureflag", 5, 1, 999, "int");
	level.cooldowntime = [[level.ex_drm]]("scr_dom_cooldowntime", 5, 1, 30, "int");
	level.flagtimeout = [[level.ex_drm]]("scr_dom_flagtimeout", 120, 0, 1440, "int");
	level.showflagwaypoints = [[level.ex_drm]]("scr_dom_showflagwaypoints", 0, 0, 1, "int");
	level.use_static_flags = [[level.ex_drm]]("scr_dom_static_flags", 0, 0, 1, "int");
	if(level.use_static_flags) maps\mp\gametypes\_mapsetup_dom_ons::init();
}

esd_init()
{
	level.esd_mode = [[level.ex_drm]]("scr_esd_mode", 2, 0, 4, "int");
	level.esd_campaign_mode = [[level.ex_drm]]("scr_esd_campaign", 1, 0, 1, "int");
	level.esd_swap_roundwinner = [[level.ex_drm]]("scr_esd_swap_roundwinner", 1, 0, 1, "int");
	level.spawnlimit = [[level.ex_drm]]("scr_esd_spawntickets", 10, 0, 999, "int");
	level.plantscore = [[level.ex_drm]]("scr_esd_plantscore", 5, 0, 999, "int");
	level.defusescore = [[level.ex_drm]]("scr_esd_defusescore", 10, 0, 999, "int");
	level.roundwin_points = [[level.ex_drm]]("scr_esd_roundwin_points", 5, 0, 999, "int");

	level.bombtimer = [[level.ex_drm]]("scr_esd_bombtimer", 60, 30, 120, "int");
	level.planttime = [[level.ex_drm]]("scr_esd_planttime", 5, 1, 60, "int");
	level.defusetime = [[level.ex_drm]]("scr_esd_defusetime", 10, 1, 60, "int");

	[[level.ex_registerCvar]]("ui_esd_mode", level.esd_mode, 1);
	[[level.ex_registerCvar]]("ui_esd_spawntickets", level.spawnlimit, 1);
}

hm_init()
{
	level.showcommander = [[level.ex_drm]]("scr_hm_showcommander", 1, 0, 1, "int");
	level.tposuptime = [[level.ex_drm]]("scr_hm_tposuptime", 5, 0, 10, "int");
	level.ex_hmpoints_cmd_hitman = [[level.ex_drm]]("scr_hmpoints_cmd_hitman", 5, 0, 999, "int");
	level.ex_hmpoints_guard_hitman = [[level.ex_drm]]("scr_hmpoints_guard_hitman", 3, 0, 999, "int");
	level.ex_hmpoints_hitman_cmd = [[level.ex_drm]]("scr_hmpoints_hitman_cmd", 10, 0, 999, "int");
	level.ex_hmpoints_hitman_guard = [[level.ex_drm]]("scr_hmpoints_hitman_guard", 1, 0, 999, "int");
	level.ex_hmpoints_hitman_hitman = [[level.ex_drm]]("scr_hmpoints_hitman_hitman", 2, 0, 999, "int");
	level.penalty_time = [[level.ex_drm]]("scr_hm_penaltytime", 5, 0, 10, "int");
}

hq_init()
{
	level.radioradius = [[level.ex_drm]]("ex_hq_radio_radius", 10, 1, 12, "int") * 12;
	level.zradioradius = [[level.ex_drm]]("ex_hq_radio_zradius", 6, 1, 12, "int") * 12;
	level.ex_custom_radios = [[level.ex_drm]]("ex_hq_custom_radios", 1, 0, 1, "int");
	level.ex_hq_radio_spawntime = [[level.ex_drm]]("ex_hq_radio_spawntime", 45, 0, 240, "int");
	level.ex_hq_radio_holdtime = [[level.ex_drm]]("ex_hq_radio_holdtime", 120, 60, 1440, "int");
	level.ex_hq_radio_compass = [[level.ex_drm]]("ex_hq_radio_compass", 0, 0, 1, "int");
	level.ex_hqpoints_teamcap = [[level.ex_drm]]("ex_hqpoints_teamcap", 0, 0, 999, "int");
	level.ex_hqpoints_teamneut = [[level.ex_drm]]("ex_hqpoints_teamneut", 10, 0, 999, "int");
	level.ex_hqpoints_playercap = [[level.ex_drm]]("ex_hqpoints_playercap", 2, 0, 999, "int");
	level.ex_hqpoints_playerneut = [[level.ex_drm]]("ex_hqpoints_playerneut", 2, 0, 999, "int");
	level.ex_hqpoints_defpps = [[level.ex_drm]]("ex_hqpoints_defpps", 1, 0, 999, "int");
	level.ex_hqpoints_radius = [[level.ex_drm]]("ex_hqpoints_radius", 40, 0, 200, "int") * 12;
}

htf_init()
{
	level.mode = [[level.ex_drm]]("scr_htf_mode", 0, 0, 3, "int");
	level.htf_teamscore = [[level.ex_drm]]("scr_htf_teamscore", 0, 0, 1, "int");
	level.flagspawndelay = [[level.ex_drm]]("scr_htf_flagspawndelay", 15, 0, 120, "int");
	level.removeflagspawns = [[level.ex_drm]]("scr_htf_removeflagspawns", 1, 0, 1, "int");
	level.flagholdtime = [[level.ex_drm]]("scr_htf_flagholdtime", 90, 10, 300, "int");
	level.flagrecovertime = [[level.ex_drm]]("scr_htf_flagrecovertime", 60, 0, 1440, "int");
	level.PointsForKillingFlagCarrier = [[level.ex_drm]]("scr_htf_pointsforkillingflagcarrier", 1, 0, 999, "int");
	level.PointsForStealingFlag = [[level.ex_drm]]("scr_htf_pointsforstealingflag", 1, 0, 999, "int");
	maps\mp\gametypes\_mapsetup_htf::init();
}

ihtf_init()
{
	level.flagspawndelay = [[level.ex_drm]]("scr_ihtf_flagspawndelay", 15, 0, 120, "int");
	level.flagholdtime = [[level.ex_drm]]("scr_ihtf_flagholdtime", 10, 10, 1440, "int");
	level.flagmaxholdtime = [[level.ex_drm]]("scr_ihtf_flagmaxholdtime", 120, 10, 1440, "int");
	level.flagtimeout = [[level.ex_drm]]("scr_ihtf_flagtimeout", 60, 10, 300, "int");
	level.PointsForHoldingFlag = [[level.ex_drm]]("scr_ihtf_pointsforholdingflag", 2, 0, 999, "int");
	level.PointsForStealingFlag = [[level.ex_drm]]("scr_ihtf_pointsforstealingflag", 1, 0, 999, "int");
	level.PointsForKillingPlayers = [[level.ex_drm]]("scr_ihtf_pointsforkillingplayers", 0, 0, 999, "int");
	level.PointsForKillingFlagCarrier = [[level.ex_drm]]("scr_ihtf_pointsforkillingflagcarrier", 1, 0, 999, "int");
	level.randomflagspawns = [[level.ex_drm]]("scr_ihtf_randomflagspawns", 1, 0, 1, "int");
	level.spawndistance = [[level.ex_drm]]("scr_ithf_spawndistance", 1000, 0, 5000, "int");
	level.playerspawnpointsmode = [[level.ex_drm]]("scr_ihtf_playerspawnpointsmode", "dm tdm", "", "", "string");
	level.flagspawnpointsmode = [[level.ex_drm]]("scr_ihtf_flagspawnpointsmode", "dm ctff sdb hq", "", "", "string");
	level.flagrecovertime = [[level.ex_drm]]("scr_ihtf_flagrecovertime", 60, 0, 1440, "int");
}

lib_init()
{
	// No additional settings
}

lms_init()
{
	level.minplayers = [[level.ex_drm]]("scr_lms_minplayers", 3, 3, 64, "int");
	level.joinperiodtime = [[level.ex_drm]]("scr_lms_joinperiod", 30, 1, 120, "int");
	level.killometer = [[level.ex_drm]]("scr_lms_killometer", 120, 30, 1200, "int");
	level.duelperiodtime = [[level.ex_drm]]("scr_lms_duelperiod", 60, 30, 300, "int");
	level.killwinner = [[level.ex_drm]]("scr_lms_killwinner", 0, 0, 1, "int");

	[[level.ex_registerCvar]]("ui_lms_killometer", level.killometer, 1);
	[[level.ex_registerCvar]]("ui_lms_duelperiod", level.duelperiodtime, 1);
}

lts_init()
{
	// No additional settings
}

ons_init()
{
	game["scorelimit"] = 0;
	level.flagsnumber = [[level.ex_drm]]("scr_ons_flagsnumber", 5, 0, 9, "int");
	level.spawndistance = [[level.ex_drm]]("scr_ons_spawndistance", 1000, 250, 5000, "int");
	level.flagcapturetime = [[level.ex_drm]]("scr_ons_flagcapturetime", 10, 1, 30, "int");
	level.pointscaptureflag = [[level.ex_drm]]("scr_ons_pointscaptureflag", 5, 1, 999, "int");
	level.cooldowntime = [[level.ex_drm]]("scr_ons_cooldowntime", 5, 1, 30, "int");
	level.flagtimeout = [[level.ex_drm]]("scr_ons_flagtimeout", 120, 0, 1440, "int");
	level.showflagwaypoints = [[level.ex_drm]]("scr_ons_showflagwaypoints", 0, 0, 1, "int");
	level.use_static_flags = [[level.ex_drm]]("scr_ons_static_flags", 1, 0, 1, "int");
	if(level.use_static_flags) maps\mp\gametypes\_mapsetup_dom_ons::init();
}

rbcnq_init()
{
	level.rbcnq_initialobj = [[level.ex_drm]]("scr_rbcnq_initialobjective", 1, 1, 3, "int");
	if(level.rbcnq_initialobj != 1 && level.rbcnq_initialobj != 3) level.rbcnq_initialobj = 1;
	level.spawnmethod = [[level.ex_drm]]("scr_rbcnq_spawnmethod", "default", "", "", "string");
	if(level.spawnmethod != "default" && level.spawnmethod != "random") level.spawnmethod = "default";
	level.team_obj_points = [[level.ex_drm]]("scr_rbcnq_team_objective_points", 10, 0, 999, "int");
	level.team_bonus_points = [[level.ex_drm]]("scr_rbcnq_team_bonus_points", 15, 0, 999, "int");
	level.player_obj_points = [[level.ex_drm]]("scr_rbcnq_player_objective_points", 10, 0, 999, "int");
	level.player_bonus_points = [[level.ex_drm]]("scr_rbcnq_player_bonus_points", 15, 0, 999, "int");
	level.roundwin_points = [[level.ex_drm]]("scr_rbcnq_roundwin_points", 15, 0, 999, "int");
	level.rbcnq_campaign_mode = [[level.ex_drm]]("scr_rbcnq_campaign", 1, 0, 1, "int");
	level.rbcnq_swap_roundwinner = [[level.ex_drm]]("scr_rbcnq_swap_roundwinner", 1, 0, 1, "int");
	level.showobj_hud = [[level.ex_drm]]("scr_rbcnq_showobj_hud", 1, 0, 1, "int");
	level.captime = [[level.ex_drm]]("scr_rbcnq_captime", 5, 0, 10, "int");
	level.spawnlimit = [[level.ex_drm]]("scr_rbcnq_spawntickets", 10, 0, 999, "int");
	level.reset_scores = [[level.ex_drm]]("scr_rbcnq_round_reset_scores", 0, 0, 1, "int");
	level.cnq_debug = [[level.ex_drm]]("scr_rbcnq_debug", 0, 0, 1, "int");

	[[level.ex_registerCvar]]("ui_rbcnq_spawntickets", level.spawnlimit, 1);
}

rbctf_init()
{
	level.ex_rbctfpoints_roundwin = [[level.ex_drm]]("ex_rbctfpoints_roundwin", 5, 1, 999, "int");
	level.ex_rbctfpoints_playercf = [[level.ex_drm]]("ex_rbctfpoints_playercf", 10, 0, 999, "int");
	level.ex_rbctfpoints_playerrf = [[level.ex_drm]]("ex_rbctfpoints_playerrf", 5, 0, 999, "int");
	level.ex_rbctfpoints_playersf = [[level.ex_drm]]("ex_rbctfpoints_playersf", 2, 0, 999, "int");
	level.ex_rbctfpoints_playertf = [[level.ex_drm]]("ex_rbctfpoints_playertf", 1, 0, 999, "int");
	level.ex_rbctfpoints_playerkf = [[level.ex_drm]]("ex_rbctfpoints_playerkf", 1, 0, 999, "int");
	level.spawnlimit = [[level.ex_drm]]("scr_rbctf_spawntickets", 10, 0, 999, "int");
	level.showobj_hud = [[level.ex_drm]]("scr_rbctf_showobj_hud", 1, 0, 1, "int");
	level.flagautoreturndelay = [[level.ex_drm]]("scr_rbctf_returndelay", 60, 0, 1440, "int");

	[[level.ex_registerCvar]]("ui_rbctf_spawntickets", level.spawnlimit, 1);
}

sd_init()
{
	level.ex_sdpoints_plant = [[level.ex_drm]]("ex_sdpoints_plant", 5, 0, 999, "int");
	level.ex_sdpoints_defuse = [[level.ex_drm]]("ex_sdpoints_defuse", 10, 0, 999, "int");

	level.bombtimer = [[level.ex_drm]]("scr_sd_bombtimer", 60, 30, 120, "int");
	level.planttime = [[level.ex_drm]]("scr_sd_planttime", 5, 1, 60, "int");
	level.defusetime = [[level.ex_drm]]("scr_sd_defusetime", 10, 1, 60, "int");
}

tdm_init()
{
	// No additional settings
}

tkoth_init()
{
	maps\mp\gametypes\_mapsetup_tkoth::init();
	level.zonetimelimit = [[level.ex_drm]]("scr_tkoth_zonetimelimit", 5, 1, 15, "int");
	level.zonepoints_capture = [[level.ex_drm]]("ex_tkothpoints_capture", 1, 1, 100, "int");
	level.zonepoints_takeover = [[level.ex_drm]]("ex_tkothpoints_takeover", 2, 1, 100, "int");
	level.zonepoints_holdmax = [[level.ex_drm]]("ex_tkothpoints_holdmax", 10, 1, 100, "int");
	level.debug = [[level.ex_drm]]("scr_tkoth_debug", 0, 0, 1, "int");

	[[level.ex_registerCvar]]("ui_tkoth_zonetimelimit", level.zonetimelimit, 1);
}

vip_init()
{
	level.vipdelay = [[level.ex_drm]]("scr_vip_vipdelay", 5, 0, 300, "int");
	level.vipvisiblebyteammates = [[level.ex_drm]]("scr_vip_vipvisiblebyteammates", 1, 0, 1, "int");
	level.vipvisiblebyenemies = [[level.ex_drm]]("scr_vip_vipvisiblebyenemies", 1, 0, 1, "int");
	level.pointsforkillingvip = [[level.ex_drm]]("scr_vip_pointsforkillingvip", 5, 0, 999, "int");
	level.pointsforprotectingvip = [[level.ex_drm]]("scr_vip_pointsforprotectingvip", 3, 0, 999, "int");
	level.vippoints = [[level.ex_drm]]("scr_vip_vippoints", 2, 0, 999, "int");
	level.vippointscycle = [[level.ex_drm]]("scr_vip_vippoints_cycle", 3, 0, 999, "int");
	level.vipprotectiondistance = [[level.ex_drm]]("scr_vip_vipprotectiondistance", 1000, 0, 5000, "int");
	level.vipprotectiontime = [[level.ex_drm]]("scr_vip_vipprotectiontime", 15, 0, 120, "int");
	level.vippistol = [[level.ex_drm]]("scr_vip_vippistol", 1, 0, 1, "int");
	level.vipmaxfragnades = 9;
	level.vipfragnades = [[level.ex_drm]]("scr_vip_vipfragnades", 0, 0, level.vipmaxfragnades, "int");
	level.vipmaxsmokenades = 9;
	level.vipsmokenades = [[level.ex_drm]]("scr_vip_vipsmokenades", 3, 0, level.vipmaxsmokenades, "int");
	level.vipsmokeradius = [[level.ex_drm]]("scr_vip_vipsmokeradius", 380, 0, 5000, "int");
	level.vipsmokeduration = [[level.ex_drm]]("scr_vip_vipsmokeduration", 70, 0, 600, "int");
	level.viphealth = [[level.ex_drm]]("scr_vip_viphealth", 150, 0, 1000, "int");
	level.vipbinoculars = [[level.ex_drm]]("scr_vip_binoculars", 1, 0, 1, "int");
}

ft_init()
{
	level.ft_roundend_delay = [[level.ex_drm]]("scr_ft_roundend_delay", 5, 5, 60, "int");
	level.ft_maxfreeze = [[level.ex_drm]]("scr_ft_maxfreeze", 999, 1, 999, "int");
	level.ft_unfreeze_mode = [[level.ex_drm]]("scr_ft_unfreeze_mode", 2, 0, 2, "int");
	level.ft_unfreeze_mode_window = [[level.ex_drm]]("scr_ft_unfreeze_mode_window", 60, 10, 300, "int");
	level.ft_unfreeze_prox = [[level.ex_drm]]("scr_ft_unfreeze_prox", 1, 0, 1, "int");
	level.ft_unfreeze_prox_time = [[level.ex_drm]]("scr_ft_unfreeze_prox_time", 3, 1, 10, "int");
	level.ft_unfreeze_prox_dist = [[level.ex_drm]]("scr_ft_unfreeze_prox_dist", 100, 100, 500, "int");
	level.ft_unfreeze_laser = [[level.ex_drm]]("scr_ft_unfreeze_laser", 1, 0, 1, "int");
	level.ft_unfreeze_laser_time = [[level.ex_drm]]("scr_ft_unfreeze_laser_time", 3, 1, 10, "int");
	level.ft_unfreeze_laser_dist = [[level.ex_drm]]("scr_ft_unfreeze_laser_dist", 5000, 100, 9999, "int");
	level.ft_unfreeze_respawn = [[level.ex_drm]]("scr_ft_unfreeze_respawn", 1, 0, 1, "int");
	level.ft_raygun = [[level.ex_drm]]("scr_ft_raygun", 3, 0, 3, "int");
	level.ft_teamchange = [[level.ex_drm]]("scr_ft_teamchange", 1, 0, 1, "int");
	level.ft_weaponchange = [[level.ex_drm]]("scr_ft_weaponchange", 0, 0, 1, "int");
	level.ft_weaponsteal = [[level.ex_drm]]("scr_ft_weaponsteal", 0, 0, 1, "int");
	level.ft_weaponsteal_frag = [[level.ex_drm]]("scr_ft_weaponsteal_frag", 1, 0, 9, "int");
	level.ft_weaponsteal_smoke = [[level.ex_drm]]("scr_ft_weaponsteal_smoke", 0, 0, 9, "int");
	level.ft_weaponsteal_keep = [[level.ex_drm]]("scr_ft_weaponsteal_keep", 1, 0, 1, "int");
	if(!level.ft_weaponsteal) level.ft_weaponsteal_keep = 0;
	level.ft_soundchance = [[level.ex_drm]]("scr_ft_soundchance", 50, 0, 100, "int");
	level.ft_history = [[level.ex_drm]]("scr_ft_history", 10, 0, 64, "int");
	level.ft_balance_frozen = [[level.ex_drm]]("scr_ft_balance_frozen", 0, 0, 1, "int");
	level.ft_points_freeze = [[level.ex_drm]]("scr_ft_points_freeze", 1, 1, 999, "int");
	level.ft_points_unfreeze = [[level.ex_drm]]("scr_ft_points_unfreeze", 5, 1, 999, "int");
}

//******************************************************************************
// Score handling
//******************************************************************************
playerScoreInit()
{
	if(!isDefined(self.pers["score"])) self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isDefined(self.pers["death"])) self.pers["death"] = 0;
	self.deaths = self.pers["death"];
}

playerScoreReset()
{
	self.pers["score"] = 0;
	self.score = self.pers["score"];

	self.pers["death"] = 0;
	self.deaths = self.pers["death"];
}

playerScore(points, stat, stat_points, checklimit)
{
	if(!isPlayer(self) || !isDefined(points)) return;
	if(!isDefined(checklimit)) checklimit = true;

	if(points)
	{
		self.pers["score"] += points;
		self.score = self.pers["score"];
		self notify("update_playerscore_hud");
	}

	if(isDefined(stat))
	{
		if(!isDefined(self.pers[stat])) self.pers[stat] = 0;
		if(isDefined(stat_points)) self.pers[stat] += stat_points;
			else self.pers[stat] += points;
	}

	if(level.ex_arcade_score) self thread extreme\_ex_arcade::checkScoreUpdate();
	if(checklimit && !level.ex_teamplay) self [[level.checkscorelimit]]();
}

teamScoreInit()
{
	if(!isDefined(game["alliedscore"])) game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);

	if(!isDefined(game["axisscore"])) game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

teamScoreReset()
{
	game["alliedscore"] = 0;
	setTeamScore("allies", game["alliedscore"]);

	game["axisscore"] = 0;
	setTeamScore("axis", game["axisscore"]);
}

teamScore(team, points, checklimit)
{
	if(!isDefined(team) || !isDefined(points)) return;
	if(!isDefined(checklimit)) checklimit = true;

	if(points)
	{
		switch(team)
		{
			case "allies":
				game["alliedscore"] = getTeamScore(team) + points;
				setTeamScore(team, game["alliedscore"]);
				level notify("update_teamscore_hud");
				if(checklimit) [[level.checkscorelimit]]();
				break;
			case "axis":
				game["axisscore"] = getTeamScore(team) + points;
				setTeamScore(team, game["axisscore"]);
				level notify("update_teamscore_hud");
				if(checklimit) [[level.checkscorelimit]]();
				break;
		}
	}
}

playerStatsInit()
{
	count = 1;
	for(;;)
	{
		stat = playerStats(count);
		if(stat == "") break;
		if(isPlayer(self) && !isDefined(self.pers[stat])) self.pers[stat] = 0;
		count++;
	}
}

playerStatsReset()
{
	count = 1;
	for(;;)
	{
		stat = playerStats(count);
		if(stat == "") break;
		if(isPlayer(self)) self.pers[stat] = 0;
		count++;
	}
}

playerStats(stat)
{
	switch(stat)
	{
		// kills
		case 1:  return "kill";
		case 2:  return "grenadekill";
		case 3:  return "tripwirekill";
		case 4:  return "headshotkill";
		case 5:  return "bashkill";
		case 6:  return "sniperkill";
		case 7:  return "knifekill";
		case 8:  return "mortarkill";
		case 9:  return "artillerykill";
		case 10: return "airstrikekill";
		case 11: return "napalmkill";
		case 12: return "panzerkill";
		case 13: return "spawnkill";
		case 14: return "spamkill";
		case 15: return "teamkill";
		case 16: return "flamethrowerkill";
		case 17: return "landminekill";
		case 18: return "firenadekill";
		case 19: return "gasnadekill";
		case 20: return "satchelchargekill";
		case 21: return "gunshipkill";

		// deaths
		case 22: return "death";
		case 23: return "grenadedeath";
		case 24: return "tripwiredeath";
		case 25: return "headshotdeath";
		case 26: return "bashdeath";
		case 27: return "sniperdeath";
		case 28: return "knifedeath";
		case 29: return "mortardeath";
		case 30: return "artillerydeath";
		case 31: return "airstrikedeath";
		case 32: return "napalmdeath";
		case 33: return "panzerdeath";
		case 34: return "spawndeath";
		case 35: return "planedeath";
		case 36: return "flamethrowerdeath";
		case 37: return "fallingdeath";
		case 38: return "minefielddeath";
		case 39: return "suicide";
		case 40: return "landminedeath";
		case 41: return "firenadedeath";
		case 42: return "gasnadedeath";
		case 43: return "satchelchargedeath";
		case 44: return "gunshipdeath";

		// other
		case 45: return "turretkill";
		case 46: return "noobstreak";
		case 47: return "conseckill";
		case 48: return "weaponstreak";
		case 49: return "roundshown";
		case 50: return "longdist";
		case 51: return "longhead";
		case 52: return "longspree";
		case 53: return "flagcap";
		case 54: return "flagret";
		case 55: return "bonus";

		// empty signals end
		default: return "";
	}
}

//******************************************************************************
// Team Swapping (halftime or every round)
//******************************************************************************
swapTeams(flagproc)
{
	level endon("ex_gameover");

	// block checkTimeLimit(), checkScoreLimit() and updateGametypeCvars()
	game["matchpaused"] = 1;

	// remove perks and dog tags
	if(level.ex_specials) thread extreme\_ex_specials::removeAllPerks();
	if(level.ex_kc) thread extreme\_ex_killconfirmed::removeAllTags();

	// remove clock
	extreme\_ex_gtcommon::destroyClock();

	// freeze players and make them drop flag if necessary
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;
		player freezecontrols(true);
		player.health = player.maxhealth;
		player extreme\_ex_utils::dropTheFlag(true);
		wait( level.ex_fps_frame );
	}

	// flag based: return flags to base
	if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb" || level.ex_currentgt == "rbctf")
	{
		if(isDefined(flagproc)) level.flags["allies"] [[flagproc]]();
		if(isDefined(flagproc)) level.flags["axis"] [[flagproc]]();
	}

	// inform players
	hud_ybase = 0;
	hud_index = levelHudCreate("swapteam_bg", undefined, 0, hud_ybase, 0.5, (1,1,1), 1, 1, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetShader(hud_index, "black", 320, 75);

	hud_y = hud_ybase - 20;
	hud_index = levelHudCreate("swapteam_head", undefined, 0, hud_y, 1, (0,1,0), 2.5, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		if(level.ex_roundbased) levelHudSetText(hud_index, &"MISC_SWAPTEAM");
			else levelHudSetText(hud_index, &"MISC_HALFTIME");
	}

	hud_y = hud_ybase + 5;
	hud_index = levelHudCreate("swapteam_switch", undefined, 0, hud_y, 1, (1,1,0), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetLabel(hud_index, &"MISC_SWAPTEAM_SWITCH");

	hud_y += 15;
	hud_index = levelHudCreate("swapteam_min", undefined, 0, hud_y, 1, (1,1,1), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		levelHudSetLabel(hud_index, &"MISC_SWAPTEAM_CONTINUE");
		levelHudSetValue(hud_index, level.ex_swapteams_hudtime);
	}

	wait( [[level.ex_fpstime]](level.ex_swapteams_hudtime) );

	levelHudDestroy("swapteam_min");
	levelHudDestroy("swapteam_switch");
	levelHudDestroy("swapteam_head");
	levelHudDestroy("swapteam_bg");

	// switch scores
	tempscore = getTeamScore("allies");
	game["alliedscore"] = getTeamScore("axis");
	game["axisscore"] = tempscore;
	setTeamScore("allies", game["alliedscore"]);
	setTeamScore("axis", game["axisscore"]);

	// save models
	axismodels = [];
	alliedmodels = [];

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;

		if(isDefined(player.pers["team"]) && isDefined(player.pers["savedmodel"]))
		{
			if(player.pers["team"] == "axis") axismodels[axismodels.size] = player.pers["savedmodel"];
				else if(player.pers["team"] == "allies") alliedmodels[alliedmodels.size] = player.pers["savedmodel"];
		}
	}

	// switch teams and reset weapons if necessary
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;

		if(isDefined(player.pers["team"]))
		{
			//player unlink();
			//player.archivetime = 0;
			//player thread maps\mp\gametypes\_spectating::setSpectatePermissions();
			resetweapons = false;
			if(!level.ex_all_weapons && !level.ex_modern_weapons)
			{
				if(!level.ex_wepo_class || level.ex_wepo_team_only) resetweapons = true;
				if(level.ex_wepo_secondary && !level.ex_wepo_sec_enemy) resetweapons = true;
			}

			if(resetweapons)
			{
				player thread extreme\_ex_clientcontrol::clearWeapons();
				player thread extreme\_ex_weapons::setWeaponArray();
				player thread maps\mp\gametypes\_weapons::updateAllAllowedSingleClient();
			}

			if(player.pers["team"] == "axis")
			{
				player.pers["team"] = "allies";
				if(level.ex_diana && isDefined(player.pers["diana"])) player maps\mp\gametypes\_models::getModel();
					else if(alliedmodels.size) player.pers["savedmodel"] = alliedmodels[randomInt(alliedmodels.size)];
						else player.pers["savedmodel"] = undefined;
			}
			else if(player.pers["team"] == "allies")
			{
				player.pers["team"] = "axis";
				if(level.ex_diana && isDefined(player.pers["diana"])) player maps\mp\gametypes\_models::getModel();
					else if(axismodels.size) player.pers["savedmodel"] = axismodels[randomInt(axismodels.size)];
						else player.pers["savedmodel"] = undefined;
			}
			wait( level.ex_fps_frame );
		}
	}

	// let varcache know we passed halftime
	game["halftime"] = 1;

	level notify("restarting");
	wait( [[level.ex_fpstime]](1) );
	map_restart(true);
}

//******************************************************************************
// Overtime handling
//******************************************************************************
startOvertime(flagproc)
{
	// block checkTimeLimit(), checkScoreLimit() and updateGametypeCvars()
	game["matchpaused"] = 1;

	// turn off features that would interfere
	if(level.ex_specials) thread extreme\_ex_specials::removeAllPerks();
	level.ex_bestof = 0;
	if(level.ex_kc)
	{
		level.ex_kc = 0;
		thread extreme\_ex_killconfirmed::removeAllTags();
	}

	// remove clock
	extreme\_ex_gtcommon::destroyClock();

	// freeze players and make them drop flag if necessary
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;
		player freezecontrols(true);
		player.health = player.maxhealth;
		player extreme\_ex_utils::dropTheFlag(true);
		wait( level.ex_fps_frame );
	}

	// flag based: return flags to base
	if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb" || level.ex_currentgt == "rbctf")
	{
		if(isDefined(flagproc)) level.flags["allies"] [[flagproc]]();
		if(isDefined(flagproc)) level.flags["axis"] [[flagproc]]();
	}

	// inform players
	hud_ybase = 0;
	hud_index = levelHudCreate("overtime_bg", undefined, 0, hud_ybase, 0.5, (1,1,1), 1, 1, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetShader(hud_index, "black", 320, 85);

	hud_y = hud_ybase - 20;
	hud_index = levelHudCreate("overtime_head", undefined, 0, hud_y, 1, (0,1,0), 2.5, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1) levelHudSetText(hud_index, &"MISC_OVERTIME");

	hud_y = hud_ybase + 5;
	hud_index = levelHudCreate("overtime_min", undefined, 0, hud_y, 1, (1,1,0), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
	if(hud_index != -1)
	{
		levelHudSetLabel(hud_index, &"MISC_OVERTIME_MINUTES");
		levelHudSetValue(hud_index, level.ex_overtime);
	}

	if(level.ex_flagbased)
	{
		hud_y += 15;
		hud_index = levelHudCreate("overtime_cap", undefined, 0, hud_y, 1, (1,1,1), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index != -1) levelHudSetText(hud_index, &"MISC_OVERTIME_FIRSTCAP");
	}

	if(level.ex_overtime_lastman)
	{
		hud_y += 10;
		hud_index = levelHudCreate("overtime_lts", undefined, 0, hud_y, 1, (1,1,1), 1.2, 2, "center_safearea", "center_safearea", "center", "middle", false, false);
		if(hud_index != -1) levelHudSetText(hud_index, &"MISC_OVERTIME_LASTTEAM");
	}

	wait( [[level.ex_fpstime]](level.ex_overtime_hudtime) );

	levelHudDestroy("overtime_lts");
	if(level.ex_flagbased) levelHudDestroy("overtime_cap");
	levelHudDestroy("overtime_min");
	levelHudDestroy("overtime_head");
	levelHudDestroy("overtime_bg");

	// unfreeze players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(!isPlayer(player) || player.sessionteam == "spectator") continue;
		player freezecontrols(false);
		player.health = player.maxhealth;

		if(level.ex_overtime_lastman) player.spawned = true;

		if(level.ex_overtime_resetteam)
		{
			if(player.sessionstate != "dead")
			{
				spawnpoint = undefined;

				switch(level.ex_currentgt)
				{
					case "tdm":
						spawnpointname = "mp_tdm_spawn";
						spawnpoints = getentarray(spawnpointname, "classname");
						spawnpoint = player maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
						break;
					case "ctf":
					case "ctfb":
						if(player.pers["team"] == "allies") spawnpointname = "mp_ctf_spawn_allied";
							else spawnpointname = "mp_ctf_spawn_axis";
						spawnpoints = getentarray(spawnpointname, "classname");
						spawnpoint = player maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearOwnFlag(spawnpoints);
						break;
				}

				if(isDefined(spawnpoint))
				{
					player setOrigin(spawnpoint.origin);
					player setPlayerAngles(spawnpoint.angles);
				}
				wait( level.ex_fps_frame );
			}
		}
	}

	// flag based: move flag trigger back to base origin
	if(level.ex_flagbased)
	{
		// set new score limit to current team score + 1
		game["scorelimit"] = getTeamScore("allies") + 1;
	}

	// start live stats for last team standing if not active already
	if(!level.ex_livestats && level.ex_overtime_lastman) thread extreme\_ex_livestats::init();

	// restart clock
	game["timelimit"] = level.ex_overtime;
	setCvar("scr_ctf_timelimit", game["timelimit"]);
	//setCvar("ui_timelimit", game["timelimit"]);
	level.starttime = getTime();
	extreme\_ex_gtcommon::createClock(game["timelimit"] * 60);
	levelHudSetLabel("mainclock", &"MISC_CLOCK_OT");

	// allow checkTimeLimit() and checkScoreLimit() to run again
	game["matchpaused"] = 0;
	game["matchovertime"] = 1;
}

//******************************************************************************
// Clock handling
//******************************************************************************
createClock(timer)
{
	if(!isDefined(timer) || !timer) return;
	hud_index = levelHudCreate("mainclock", undefined, 8, 2, 1, (0.705, 0.705, 0.392), 2, 0, "fullscreen", "fullscreen", "left", "top");
	if(hud_index != -1) levelHudSetTimer(hud_index, timer);
}

destroyClock()
{
	levelHudDestroy("mainclock");
}
