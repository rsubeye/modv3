main(stage)
{
	// max for COD2 (signed integers)
	level.MAX_SIGNED_INT = 2147483647;
	// max positive feed for RandomInt (unsigned short integers)
	level.MAX_UNSIGNED_SHORT = 65535;
	level.MAX_SIGNED_SHORT = 32767;

	//****************************************************************************
	// turn off xbox related variables
	//****************************************************************************
	level.xenon = false;
	level.splitscreen = false;

	//****************************************************************************
	// initialize players array
	//****************************************************************************
	level.players = [];

	// 0 = no stages (proces all), 1 = stage 1 (init only), 2 = stage 2
	if(!isDefined(stage)) stage = 0;
	if(stage <= 1)
	{
		//**************************************************************************
		// setup commonly used function pointers
		//**************************************************************************
		level.ex_log = extreme\_ex_utils::log;
		level.ex_drm = extreme\_ex_drm::drm_cvardef;
		level.ex_cvardef = extreme\_ex_utils::cvardef;

		level.ex_PrecacheEffect = extreme\_ex_utils::ex_PrecacheEffect;
		level.ex_PrecacheShader = extreme\_ex_utils::ex_PrecacheShader;
		level.ex_PrecacheHeadIcon = extreme\_ex_utils::ex_PrecacheHeadIcon;
		level.ex_PrecacheStatusIcon = extreme\_ex_utils::ex_PrecacheStatusIcon;
		level.ex_PrecacheModel = extreme\_ex_utils::ex_PrecacheModel;
		level.ex_PrecacheItem = extreme\_ex_utils::ex_PrecacheItem;
		level.ex_PrecacheString = extreme\_ex_utils::ex_PrecacheString;
		level.ex_PrecacheMenu = extreme\_ex_utils::ex_PrecacheMenu;
		level.ex_PrecacheShellShock = extreme\_ex_utils::ex_PrecacheShellShock;
		level.ex_PrecacheRumble = extreme\_ex_utils::ex_PrecacheRumble;

		level.ex_registerCallback = extreme\_ex_eventcontroller::registerCallback;
		level.ex_registerLevelEvent = extreme\_ex_eventcontroller::registerLevelEvent;
		level.ex_enableLevelEvent = extreme\_ex_eventcontroller::enableLevelEvent;
		level.ex_disableLevelEvent = extreme\_ex_eventcontroller::disableLevelEvent;
		level.ex_registerPlayerEvent = extreme\_ex_eventcontroller::registerPlayerEvent;
		level.ex_enablePlayerEvent = extreme\_ex_eventcontroller::enablePlayerEvent;
		level.ex_disablePlayerEvent = extreme\_ex_eventcontroller::disablePlayerEvent;
		level.ex_registerCvar = extreme\_ex_cvarcontroller::registerCvar;

		level.ex_fpstime = extreme\_ex_utils::_fpsTime;
		level.ex_dWeapon = extreme\_ex_utils::_disableWeapon;
		level.ex_eWeapon = extreme\_ex_utils::_enableWeapon;
		level.ex_getStance = extreme\_ex_utils::GetStance;
		level.ex_vectorscale = maps\mp\_utility::vectorscale;
		level.ex_pname = extreme\_ex_utils::pname;
		level.ex_bclear = extreme\_ex_utils::iprintlnboldCLEAR;
		level.ex_psop = extreme\_ex_utils::playSoundOnPlayers;

		//**************************************************************************
		// callbackPlayerDamage redirection
		//**************************************************************************
		level.ex_callbackPlayerDamage = level.callbackPlayerDamage;
		level.callbackPlayerDamage = extreme\_ex_main::exPlayerDamage;

		//**************************************************************************
		// callbackPlayerDisconnect redirection
		//**************************************************************************
		level.ex_callbackPlayerDisconnect = level.callbackPlayerDisconnect;
		level.callbackPlayerDisconnect = extreme\_ex_eventcontroller::onCallbackDisconnected;

		//**************************************************************************
		// set basic variables
		//**************************************************************************
		level.ex_gameover = false;
		level.ex_maxclients = getCvarInt("sv_maxclients");
		level.ex_privateclients = getCvarInt("sv_privateclients");

		//**************************************************************************
		// initialize DRM
		//**************************************************************************
		extreme\_ex_drm::drm_init();

		//**************************************************************************
		// initialize FPS and spawn control
		//**************************************************************************
		level.ex_spawncontrol = extreme\_ex_drm::drm_getCvarInt("ex_spawncontrol");
		extreme\_ex_fps::init();

		//**************************************************************************
		// player based map sizing (needed in [[level.ex_drm]]() calls)
		//**************************************************************************
		level.ex_mapsizing_medium = extreme\_ex_drm::drm_getCvarInt("ex_mapsizing_medium");
		if(!level.ex_mapsizing_medium) level.ex_mapsizing_medium = 8;
		level.ex_mapsizing_large = extreme\_ex_drm::drm_getCvarInt("ex_mapsizing_large");
		if(!level.ex_mapsizing_large) level.ex_mapsizing_large = 14;

		//**************************************************************************
		// log control
		//**************************************************************************
		level.ex_logextreme = [[level.ex_drm]]("ex_logextreme", 0, 0, 1, "int");
		level.ex_logdamage = [[level.ex_drm]]("ex_logdamage", 0, 0, 1, "int");
		level.ex_logplatform = [[level.ex_drm]]("ex_logplatform", 0, 0, 2, "int");
		extreme\_ex_utils::detectLogPlatform();

		//**************************************************************************
		// game type check for IHTF, which fakes HQ during init. Reread later.
		//**************************************************************************
		level.ex_currentgt = getcvar("g_gametype");
		if(level.ex_currentgt == "chq" || level.ex_currentgt == "hq") level.ex_radiobased = true;
			else level.ex_radiobased = false;

		//**************************************************************************
		// tuning vars for precache limits (needed in level scripts; might be needed in controllers)
		//**************************************************************************
		level.ex_tune_cachelimit_effects = [[level.ex_drm]]("ex_tune_cachelimit_effects", 55, 50, 63, "int"); // 8 reserved for level script effects
		level.ex_tune_cachelimit_shaders = [[level.ex_drm]]("ex_tune_cachelimit_shaders", 127, 0, 127, "int");
		level.ex_tune_cachelimit_headicons = [[level.ex_drm]]("ex_tune_cachelimit_headicons", 15, 0, 15, "int");
		level.ex_tune_cachelimit_statusicons = [[level.ex_drm]]("ex_tune_cachelimit_statusicons", 8, 0, 8, "int");
		level.ex_tune_cachelimit_models = [[level.ex_drm]]("ex_tune_cachelimit_models", 127, 0, 254, "int"); // 127 reserved for weapon file models
		level.ex_tune_cachelimit_items = [[level.ex_drm]]("ex_tune_cachelimit_items", 127, 0, 127, "int");
		level.ex_tune_cachelimit_strings = [[level.ex_drm]]("ex_tune_cachelimit_strings", 254, 0, 254, "int");
		level.ex_tune_cachelimit_menus = [[level.ex_drm]]("ex_tune_cachelimit_menus", 32, 0, 32, "int");
		level.ex_tune_cachelimit_shellshocks = [[level.ex_drm]]("ex_tune_cachelimit_shellshock", 15, 0, 15, "int");
		level.ex_tune_cachelimit_rumbles = [[level.ex_drm]]("ex_tune_cachelimit_rumbles", 15, 0, 15, "int");

		//**************************************************************************
		// ambient fx control (needed in level script)
		//**************************************************************************
		level.ex_ambmapfog = [[level.ex_drm]]("ex_ambmapfog", 1, 0, 1, "int");
		level.ex_ambmapsound = [[level.ex_drm]]("ex_ambmapsound", 1, 0, 1, "int");
		level.ex_ambsoundfx = [[level.ex_drm]]("ex_ambsoundfx", 1, 0, 1, "int");
		level.ex_ambfirefx = [[level.ex_drm]]("ex_ambfirefx", 1, 0, 1, "int");
		level.ex_ambfogbankfx = [[level.ex_drm]]("ex_ambfogbankfx", 1, 0, 1, "int");
		level.ex_ambsmokefx = [[level.ex_drm]]("ex_ambsmokefx", 1, 0, 1, "int");
		level.ex_ambfliesfx = [[level.ex_drm]]("ex_ambfliesfx", 1, 0, 1, "int");
		level.ex_ambdustfx = [[level.ex_drm]]("ex_ambdustfx", 1, 0, 1, "int");
		level.ex_ambsnowfx = [[level.ex_drm]]("ex_ambsnowfx", 1, 0, 1, "int");

		//**************************************************************************
		// minefields (needed in level script)
		//**************************************************************************
		level.ex_minefields = [[level.ex_drm]]("ex_minefields", 1, 0, 3, "int");
		if(level.ex_minefields)
		{
			level.ex_minefields_instant = [[level.ex_drm]]("ex_minefields_instant", 0, 0, 1, "int");
			if(level.ex_minefields == 2)
			{
				level.ex_gasmine_min = [[level.ex_drm]]("ex_gasmine_min", 50, 1, 100, "int");
				level.ex_gasmine_max = [[level.ex_drm]]("ex_gasmine_max", 75, level.ex_gasmine_min, 100, "int");
			}
			else if(level.ex_minefields == 3)
			{
				level.ex_napalmmine_min = [[level.ex_drm]]("ex_napalmmine_min", 50, 1, 100, "int");
				level.ex_napalmmine_max = [[level.ex_drm]]("ex_napalmmine_max", 75, level.ex_napalmmine_min, 100, "int");
			}
		}

		//****************************************************************************
		// killtrigger management (needed in level script)
		//****************************************************************************
		level.ex_killtriggers = [[level.ex_drm]]("ex_killtriggers", 1, 0, 1, "int");

		//**************************************************************************
		// initialize event controller
		//**************************************************************************
		extreme\_ex_eventcontroller::init();

		//**************************************************************************
		// initialize dvar controller
		//**************************************************************************
		extreme\_ex_cvarcontroller::init();

		//**************************************************************************
		// initialize hud controller
		//**************************************************************************
		extreme\_ex_hudcontroller::hud_init();
	}

	//****************************************************************************
	// stop processing for game types which process varcache in two stages (CHQ and IHTF)
	//****************************************************************************
	if(stage == 1) return;

	//****************************************************************************
	// current game type and map level variables
	//****************************************************************************
	level.ex_currentgt = getcvar("g_gametype");
	level.ex_currentmap = getcvar("mapname");

	//****************************************************************************
	// game type checks
	//****************************************************************************
	// teamplay
	if(level.ex_currentgt != "dm" && level.ex_currentgt != "hm" &&
		level.ex_currentgt != "ihtf" && level.ex_currentgt != "lms") level.ex_teamplay = true;
		else level.ex_teamplay = false;

	// round based
	if(level.ex_currentgt == "dom" || level.ex_currentgt == "esd" || level.ex_currentgt == "ft" ||
		level.ex_currentgt == "lib" || level.ex_currentgt == "lts" || level.ex_currentgt == "ons" ||
		level.ex_currentgt == "rbcnq" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "sd") level.ex_roundbased = true;
		else level.ex_roundbased = false;

	// flag based
	if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb" || level.ex_currentgt == "htf" ||
		level.ex_currentgt == "ihtf" || level.ex_currentgt == "rbctf") level.ex_flagbased = true;
		else level.ex_flagbased = false;

	// radio based
	if(level.ex_currentgt == "chq" || level.ex_currentgt == "hq") level.ex_radiobased = true;
		else level.ex_radiobased = false;

	//****************************************************************************
	// tuning vars
	//****************************************************************************
	level.ex_tune_precachestats = [[level.ex_drm]]("ex_tune_precachestats", 0, 0, 2, "int");
	level.ex_tune_prone = [[level.ex_drm]]("ex_tune_prone", 18, 0, 100, "int"); // 18
	level.ex_tune_crouch = [[level.ex_drm]]("ex_tune_crouch", 43, 0, 100, "int"); // 43
	level.ex_tune_delaywrite = [[level.ex_drm]]("ex_tune_delaywrite", 0, 0, 1, "int");

	//****************************************************************************
	// debugging vars (either enable or disable. Do NOT remove or comment!)
	//****************************************************************************
	level.debugweapons = false;
	level.debugbotweapons = false;

	//****************************************************************************
	// player maxhealth
	//****************************************************************************
	level.ex_player_maxhealth = [[level.ex_drm]]("ex_player_maxhealth", 100, 10, 100, "int");

	//****************************************************************************
	// persona non grata
	//****************************************************************************
	level.ex_nongrata = [[level.ex_drm]]("ex_nongrata", 0, 0, 2, "int");
	level.ex_nongrata_title = [[level.ex_drm]]("ex_nongrata_title", "", "", "", "string");
	level.ex_nongrata_msg = [[level.ex_drm]]("ex_nongrata_msg", "", "", "", "string");

	//****************************************************************************
	// toolbox
	//****************************************************************************
	level.ex_toolbox = [[level.ex_drm]]("ex_toolbox", 0, 0, 1, "int");

	//****************************************************************************
	// air traffic controller
	//****************************************************************************
	level.ex_atc_maxplanes = [[level.ex_drm]]("ex_atc_maxplanes", 3, 1, 10, "int");
	level.ex_atc_maxcrashes = [[level.ex_drm]]("ex_atc_maxcrashes", 2, 0, 999, "int");
	level.ex_atc_crashchance = [[level.ex_drm]]("ex_atc_crashchance", 5, 1, 100, "int");

	//****************************************************************************
	// memory file naming convention
	//****************************************************************************
	level.ex_memory_filename = [[level.ex_drm]]("ex_memory_filename", 0, 0, 2, "int");

	//****************************************************************************
	// score memory
	//****************************************************************************
	level.ex_scorememory = [[level.ex_drm]]("ex_scorememory", 60, 0, 3600, "int");

	//****************************************************************************
	// total stats memory
	//****************************************************************************
	level.ex_statstotal = [[level.ex_drm]]("ex_statstotal", 0, 0, 1, "int");
	if(level.ex_statstotal)
	{
		level.ex_statstotal_log = [[level.ex_drm]]("ex_statstotal_log", 0, 0, 1, "int");
		level.ex_statstotal_balance = [[level.ex_drm]]("ex_statstotal_balance", 0, 0, 3, "int");
		level.ex_statstotal_balance_mode = [[level.ex_drm]]("ex_statstotal_balance_mode", 0, 0, 2, "int");
		level.ex_statstotal_balance_grace = [[level.ex_drm]]("ex_statstotal_balance_grace", 60, 0, 1440, "int");
		level.ex_statstotal_balance_diff = [[level.ex_drm]]("ex_statstotal_balance_diff", 0, 0, 99999, "int");
		level.ex_statstotal_balance_interval = [[level.ex_drm]]("ex_statstotal_balance_interval", 1, 0, 1, "int");
		level.ex_statstotal_monitor_player = [[level.ex_drm]]("ex_statstotal_monitor_player", 0, 0, 64, "int");
		level.ex_statstotal_monitor_team = [[level.ex_drm]]("ex_statstotal_monitor_team", 0, 0, 1, "int");
		if(level.ex_statstotal_balance == 1 || level.ex_statstotal_balance == 2) level.ex_statstotal_balance_log = 1;
			else level.ex_statstotal_balance_log = 0;
	}

	//****************************************************************************
	// log monitor
	//****************************************************************************
	level.ex_clog = [[level.ex_drm]]("ex_clog", 0, 0, 1, "int");
	if(level.ex_clog)
	{
		level.ex_clog_interval = [[level.ex_drm]]("ex_clog_interval", 30, 10, 60, "int");
		level.ex_clog_split = [[level.ex_drm]]("ex_clog_split", 1, 0, 1, "int");
		level.ex_clog_geo = [[level.ex_drm]]("ex_clog_geo", 0, 0, 1, "int");
		level.ex_clog_filter = [[level.ex_drm]]("ex_clog_filter", 0, 0, 1, "int");
	}

	level.ex_glog = [[level.ex_drm]]("ex_glog", 0, 0, 1, "int");
	if(level.ex_glog)
	{
		level.ex_glog_interval = [[level.ex_drm]]("ex_glog_interval", 5, 5, 60, "int");
		level.ex_glog_split = [[level.ex_drm]]("ex_glog_split", 1, 0, 1, "int");
		level.ex_glog_badword = [[level.ex_drm]]("ex_glog_badword", 0, 0, 1, "int");
		level.ex_glog_badword_max = [[level.ex_drm]]("ex_glog_badword_max", 100, 1, 1000, "int");
		level.ex_glog_badword_action = [[level.ex_drm]]("ex_glog_badword_action", 0, 0, 2, "int");
		level.ex_glog_filter = [[level.ex_drm]]("ex_glog_filter", 0, 0, 1, "int");
	}

	//****************************************************************************
	// intermission time
	//****************************************************************************
	level.ex_intermission = [[level.ex_drm]]("ex_intermission", 10, 5, 60, "int");

	//****************************************************************************
	// weather fx
	//****************************************************************************
	level.ex_weather = [[level.ex_drm]]("ex_weather", 0, 0, 1, "int");
	if(level.ex_weather)
	{
		level.ex_weather_rain_max = [[level.ex_drm]]("ex_weather_rain_max", 10, 1, 10, "int");
		level.ex_weather_snow_max = [[level.ex_drm]]("ex_weather_snow_max", 10, 1, 10, "int");
		level.ex_weather_transition = [[level.ex_drm]]("ex_weather_transition", 10, 1, 9999, "int");
		level.ex_weather_duration = [[level.ex_drm]]("ex_weather_duration", 30, 1, 9999, "int");
		level.ex_weather_prob_light = [[level.ex_drm]]("ex_weather_prob_light", 70, 0, 100, "int");
		level.ex_weather_prob_medium = [[level.ex_drm]]("ex_weather_prob_medium", 50, 0, 100, "int");
		level.ex_weather_prob_hard = [[level.ex_drm]]("ex_weather_prob_hard", 30, 0, 100, "int");
		level.ex_weather_prob_extreme = [[level.ex_drm]]("ex_weather_prob_extreme", 10, 0, 100, "int");
		level.ex_weather_none_fallback = [[level.ex_drm]]("ex_weather_none_fallback", 1, 0, 1, "int");
		level.ex_weather_lightning = [[level.ex_drm]]("ex_weather_lightning", 1, 0, 1, "int");
		level.ex_weather_thunder = [[level.ex_drm]]("ex_weather_thunder", 1, 0, 1, "int");
		level.ex_weather_visibility = [[level.ex_drm]]("ex_weather_visibility", 2, 0, 3, "int");
		level.ex_weather_visibility_modifier = [[level.ex_drm]]("ex_weather_visibility_modifier", 1, 0.1, 10, "float");
	}

	//****************************************************************************
	// cold breath fx (only available on wintermaps)
	//****************************************************************************
	level.ex_coldbreathfx = [[level.ex_drm]]("ex_coldbreathfx", 0, 0, 1, "int");

	//****************************************************************************
	// icon alpha
	//****************************************************************************
	level.ex_iconalpha = [[level.ex_drm]]("ex_iconalpha", 1, 0, 1, "float");

	//****************************************************************************
	// specials (keep above level.ex_gunship)
	//****************************************************************************
	level.ex_specials = [[level.ex_drm]]("ex_specials", 0, 0, 1, "int");
	level.ex_specials_na_text = [[level.ex_drm]]("ex_specials_na_text", "[Not available]", "", "", "string");
	if(level.ex_specials)
	{
		level.ex_specials_order = [[level.ex_drm]]("ex_specials_order", "", "", "", "string");
		level.ex_specials_minpoints = [[level.ex_drm]]("ex_specials_minpoints", 0, 0, 9999, "int");
		level.ex_specials_testdelay = [[level.ex_drm]]("ex_specials_testdelay", 10, 0, 9999, "int");
		level.ex_specials_priority = [[level.ex_drm]]("ex_specials_priority", 0, 0, 2, "int");
		level.ex_specials_keeptimer = [[level.ex_drm]]("ex_specials_keeptimer", 10, 0, 30, "int");
		if(level.ex_specials_keeptimer && level.ex_specials_keeptimer < 5) level.ex_specials_keeptimer = 5;
	}

	//****************************************************************************
	// specials: max health
	//****************************************************************************
	level.ex_specials_maxhealth = [[level.ex_drm]]("ex_specials_maxhealth", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_specials_maxhealth = 0;

	//****************************************************************************
	// specials: max ammo
	//****************************************************************************
	level.ex_specials_maxammo = [[level.ex_drm]]("ex_specials_maxammo", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_specials_maxammo = 0;

	//****************************************************************************
	// specials: knife
	//****************************************************************************
	level.ex_specials_knife = [[level.ex_drm]]("ex_specials_knife", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_specials_knife = 0;
	if(level.ex_specials_knife)
	{
		level.ex_specials_knife_model = [[level.ex_drm]]("ex_specials_knife_model", 0, 0, 2, "int");
	}

	//****************************************************************************
	// specials: supernade
	//****************************************************************************
	level.ex_supernade = [[level.ex_drm]]("ex_supernade", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_supernade = 0;
	if(level.ex_supernade)
	{
		level.ex_supernade_drop = [[level.ex_drm]]("ex_supernade_drop", 0, 0, 1, "int");
		level.ex_supernade_cpx = [[level.ex_drm]]("ex_supernade_cpx", 20, 0, 100, "int") * 12;
		level.ex_supernade_eoc = [[level.ex_drm]]("ex_supernade_eoc", 0, 0, 1, "int");
	}

	//****************************************************************************
	// specials: bullet proof vest
	//****************************************************************************
	level.ex_vest = [[level.ex_drm]]("ex_vest", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_vest = 0;
	if(level.ex_vest)
	{
		level.ex_vest_timer = [[level.ex_drm]]("ex_vest_timer", 60, 10, 1800, "int");
		level.ex_vest_protect_mg = [[level.ex_drm]]("ex_vest_protect_mg", 1, 0, 1, "int");
		level.ex_vest_protect_sniper = [[level.ex_drm]]("ex_vest_protect_sniper", 1, 0, 1, "int");
		level.ex_vest_protect_sniperlr = [[level.ex_drm]]("ex_vest_protect_sniperlr", 1, 0, 1, "int");
	}

	//****************************************************************************
	// specials: bear trap
	//****************************************************************************
	level.ex_beartrap = [[level.ex_drm]]("ex_beartrap", 2, 0, 3, "int");
	if(!level.ex_specials) level.ex_beartrap = 0;
	if(level.ex_beartrap)
	{
		level.ex_beartrap_timer = [[level.ex_drm]]("ex_beartrap_timer", 180, 10, 1800, "int");
		level.ex_beartrap_bleedtime = [[level.ex_drm]]("ex_beartrap_bleedtime", 5, 5, 60, "int");
		level.ex_beartrap_surfacecheck = [[level.ex_drm]]("ex_beartrap_surfacecheck", 0, 0, 1, "int");
		level.ex_beartrap_warning = [[level.ex_drm]]("ex_beartrap_warning", 100, 0, 100, "int");
		level.ex_beartrap_untrap = [[level.ex_drm]]("ex_beartrap_untrap", 1, 0, 1, "int");
		if(level.ex_beartrap_warning >= 1 && level.ex_beartrap_warning < 50) level.ex_beartrap_warning = 50;
	}

	//****************************************************************************
	// specials: monkey bomb
	//****************************************************************************
	level.ex_monkey = [[level.ex_drm]]("ex_monkey", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_monkey = 0;
	if(level.ex_monkey)
	{
		level.ex_monkey_timer = [[level.ex_drm]]("ex_monkey_timer", 180, 10, 1800, "int");
		level.ex_monkey_surfacecheck = [[level.ex_drm]]("ex_monkey_surfacecheck", 0, 0, 1, "int");
		level.ex_monkey_stance = [[level.ex_drm]]("ex_monkey_stance", 0, 0, 2, "int");
	}

	//****************************************************************************
	// specials: personal defense bubble
	//****************************************************************************
	level.ex_bubble_small = [[level.ex_drm]]("ex_bubble_small", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_bubble_small = 0;
	if(level.ex_bubble_small) level.ex_bubble_small_timer = [[level.ex_drm]]("ex_bubble_small_timer", 30, 10, 1800, "int");

	//****************************************************************************
	// specials: big bubble of love
	//****************************************************************************
	level.ex_bubble_big = [[level.ex_drm]]("ex_bubble_big", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_bubble_big = 0;
	if(level.ex_bubble_big) level.ex_bubble_big_timer = [[level.ex_drm]]("ex_bubble_big_timer", 45, 10, 1800, "int");

	//****************************************************************************
	// specials: stealth model
	//****************************************************************************
	level.ex_stealth = [[level.ex_drm]]("ex_stealth", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_stealth = 0;
	if(level.ex_stealth)
	{
		level.ex_stealth_timer = [[level.ex_drm]]("ex_stealth_timer", 60, 10, 1800, "int");
		level.ex_stealth_pause = [[level.ex_drm]]("ex_stealth_pause", 0, 0, 1, "int");
		level.ex_stealth_auto = [[level.ex_drm]]("ex_stealth_auto", 1, 0, 1, "int");
		level.ex_stealth_switch = [[level.ex_drm]]("ex_stealth_switch", 2, 1, 5, "int") * 10;
		level.ex_stealth_knife = [[level.ex_drm]]("ex_stealth_knife", 1, 0, 1, "int");
		level.ex_stealth_hint = [[level.ex_drm]]("ex_stealth_hint", 1, 0, 1, "int");
	}

	//****************************************************************************
	// specials: tactical insertion
	//****************************************************************************
	level.ex_insertion = [[level.ex_drm]]("ex_insertion", 1, 0, 1, "int");
	if(!level.ex_specials || level.ex_currentgt == "ft") level.ex_insertion = 0;
	if(level.ex_insertion)
	{
		level.ex_insertion_timer = [[level.ex_drm]]("ex_insertion_timer", 60, 10, 1800, "int");
		level.ex_insertion_fx = [[level.ex_drm]]("ex_insertion_fx", 1, 0, 1, "int");
	}

	//****************************************************************************
	// specials: wall penetrating bullets
	//****************************************************************************
	level.ex_wallfire = [[level.ex_drm]]("ex_wallfire", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_wallfire = 0;
	if(level.ex_wallfire)
	{
		level.ex_wallfire_timer = [[level.ex_drm]]("ex_wallfire_timer", 120, 10, 1800, "int");
		level.ex_wallfire_friction = [[level.ex_drm]]("ex_wallfire_friction", 1, 0, 1, "int");
		level.ex_wallfire_rpg = [[level.ex_drm]]("ex_wallfire_rpg", 0, 0, 1, "int");
	}

	//****************************************************************************
	// specials: flak vierling anti-aircraft gun
	//****************************************************************************
	level.ex_flak = [[level.ex_drm]]("ex_flak", 2, 0, 3, "int");
	if(!level.ex_specials) level.ex_flak = 0;
	if(level.ex_flak)
	{
		level.ex_flak_timer = [[level.ex_drm]]("ex_flak_timer", 120, 10, 1800, "int");
		level.ex_flak_mount = [[level.ex_drm]]("ex_flak_mount", 1, 0, 2, "int");
		level.ex_flak_mount_radius = [[level.ex_drm]]("ex_flak_mount_radius", 80, 50, 200, "int");
		level.ex_flak_target = [[level.ex_drm]]("ex_flak_target", 31, 1, 31, "int");
		level.ex_flak_firemode = [[level.ex_drm]]("ex_flak_firemode", 2, 0, 2, "int");
		level.ex_flak_interval = [[level.ex_drm]]("ex_flak_interval", 10, 0, 30, "float");
		level.ex_flak_maxhealth = [[level.ex_drm]]("ex_flak_maxhealth", 2000, 1000, 99999, "int");
		level.ex_flak_complex = [[level.ex_drm]]("ex_flak_complex", 0, 0, 1, "int");
		if(level.ex_flak == 2) level.ex_flak_complex = 0;
		if(!level.ex_teamplay && level.ex_flak_mount == 1) level.ex_flak_mount = 0;

		level.ex_flak_remove = [[level.ex_drm]]("ex_flak_remove", 0, 0, 255, "int");
		level.ex_flak_actionradius = [[level.ex_drm]]("ex_flak_actionradius", 100, 100, 150, "int");
		level.ex_flak_owneraction = [[level.ex_drm]]("ex_flak_owneraction", 15, 0, 255, "int");
		level.ex_flak_teamaction = [[level.ex_drm]]("ex_flak_teamaction", 7, 0, 255, "int");
		level.ex_flak_enemyaction = [[level.ex_drm]]("ex_flak_enemyaction", 7, 0, 255, "int");
		level.ex_flak_actiontime = [[level.ex_drm]]("ex_flak_actiontime", 2, 1, 10, "int");
		level.ex_flak_messages = [[level.ex_drm]]("ex_flak_messages", 2, 0, 2, "int");
		level.ex_flak_waypoints = [[level.ex_drm]]("ex_flak_waypoints", 2, 0, 3, "int");
		level.ex_flak_cpx = [[level.ex_drm]]("ex_flak_cpx", 8, 0, 64, "int");
		level.ex_flak_cpx_timer = [[level.ex_drm]]("ex_flak_cpx_timer", 30, 0, 1800, "int");
		if(level.ex_flak_cpx_timer > 0 && level.ex_flak_cpx_timer < 10) level.ex_flak_cpx_timer = 10;
		level.ex_flak_cpx_nades = [[level.ex_drm]]("ex_flak_cpx_nades", 2, 1, 10, "int");
	}

	//****************************************************************************
	// specials: guided missile launcher
	//****************************************************************************
	level.ex_gml = [[level.ex_drm]]("ex_gml", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_gml = 0;
	if(level.ex_gml)
	{
		level.ex_gml_timer = [[level.ex_drm]]("ex_gml_timer", 120, 10, 1800, "int");
		level.ex_gml_missiles = [[level.ex_drm]]("ex_gml_missiles", 21, 1, 21, "int");
		level.ex_gml_target = [[level.ex_drm]]("ex_gml_target", 127, 1, 127, "int");
		level.ex_gml_interval = [[level.ex_drm]]("ex_gml_interval", 1, 0, 5, "float");
		level.ex_gml_maxhealth = [[level.ex_drm]]("ex_gml_maxhealth", 2000, 1000, 99999, "int");
		level.ex_gml_burst = [[level.ex_drm]]("ex_gml_burst", 0, 0, 21, "int");
		if(level.ex_gml_burst == 1) level.ex_gml_burst = 0;
		level.ex_gml_burst_interval = [[level.ex_drm]]("ex_gml_burst_interval", 1, 0, 5, "float");

		level.ex_gml_remove = [[level.ex_drm]]("ex_gml_remove", 0, 0, 255, "int");
		level.ex_gml_actionradius = [[level.ex_drm]]("ex_gml_actionradius", 100, 100, 150, "int");
		level.ex_gml_owneraction = [[level.ex_drm]]("ex_gml_owneraction", 15, 0, 255, "int");
		level.ex_gml_teamaction = [[level.ex_drm]]("ex_gml_teamaction", 7, 0, 255, "int");
		level.ex_gml_enemyaction = [[level.ex_drm]]("ex_gml_enemyaction", 7, 0, 255, "int");
		level.ex_gml_actiontime = [[level.ex_drm]]("ex_gml_actiontime", 2, 1, 10, "int");
		level.ex_gml_messages = [[level.ex_drm]]("ex_gml_messages", 2, 0, 2, "int");
		level.ex_gml_waypoints = [[level.ex_drm]]("ex_gml_waypoints", 2, 0, 3, "int");
		level.ex_gml_cpx = [[level.ex_drm]]("ex_gml_cpx", 8, 0, 64, "int");
		level.ex_gml_cpx_timer = [[level.ex_drm]]("ex_gml_cpx_timer", 30, 0, 1800, "int");
		if(level.ex_gml_cpx_timer > 0 && level.ex_gml_cpx_timer < 10) level.ex_gml_cpx_timer = 10;
		level.ex_gml_cpx_nades = [[level.ex_drm]]("ex_gml_cpx_nades", 2, 1, 10, "int");
	}

	//****************************************************************************
	// specials: cam
	//****************************************************************************
	level.ex_cam = [[level.ex_drm]]("ex_cam", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_cam = 0;
	if(level.ex_cam)
	{
		level.ex_cam_timer = [[level.ex_drm]]("ex_cam_timer", 120, 10, 1800, "int");
		level.ex_cam_range = [[level.ex_drm]]("ex_cam_range", 3200, 1000, 100000, "int");
		level.ex_cam_viewangle = [[level.ex_drm]]("ex_cam_viewangle", 60, 20, 80, "int");
		level.ex_cam_maxenemy = [[level.ex_drm]]("ex_cam_maxenemy", 10, 1, 16, "int");
	}

	//****************************************************************************
	// specials: unmanned aerial vehicle (UAV)
	//****************************************************************************
	level.ex_uav = [[level.ex_drm]]("ex_uav", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_uav = 0;
	if(level.ex_uav)
	{
		level.ex_uav_timer = [[level.ex_drm]]("ex_uav_timer", 60, 10, 1800, "int");
		level.ex_uav_private = [[level.ex_drm]]("ex_uav_private", 1, 0, 1, "int");
		level.ex_uav_range = [[level.ex_drm]]("ex_uav_range", 3200, 1000, 100000, "int");
		level.ex_uav_maxenemy = [[level.ex_drm]]("ex_uav_maxenemy", 10, 1, 16, "int");
		level.ex_uav_model = [[level.ex_drm]]("ex_uav_model", 0, 0, 1, "int");
		if(!level.ex_teamplay) level.ex_uav_private = 1;
	}

	//****************************************************************************
	// specials: sentry gun
	//****************************************************************************
	level.ex_sentrygun = [[level.ex_drm]]("ex_sentrygun", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_sentrygun = 0;
	if(level.ex_sentrygun)
	{
		level.ex_sentrygun_timer = [[level.ex_drm]]("ex_sentrygun_timer", 120, 10, 1800, "int");
		level.ex_sentrygun_reach = [[level.ex_drm]]("ex_sentrygun_reach", 60, 20, 80, "int");
		level.ex_sentrygun_viewangle = [[level.ex_drm]]("ex_sentrygun_viewangle", 60, level.ex_sentrygun_reach, 80, "int");
		if(level.ex_sentrygun_viewangle > level.ex_sentrygun_reach) level.ex_sentrygun_viewangle = level.ex_sentrygun_reach;
		level.ex_sentrygun_maxhealth = [[level.ex_drm]]("ex_sentrygun_maxhealth", 2000, 1000, 99999, "int");
		level.ex_sentrygun_damage = [[level.ex_drm]]("ex_sentrygun_damage", 40, 1, 100, "int");
		level.ex_sentrygun_fireradius = [[level.ex_drm]]("ex_sentrygun_fireradius", 1500, 500, 3000, "int");

		level.ex_sentrygun_remove = [[level.ex_drm]]("ex_sentrygun_remove", 0, 0, 255, "int");
		level.ex_sentrygun_actionradius = [[level.ex_drm]]("ex_sentrygun_actionradius", 100, 100, 150, "int");
		level.ex_sentrygun_owneraction = [[level.ex_drm]]("ex_sentrygun_owneraction", 15, 0, 255, "int");
		level.ex_sentrygun_teamaction = [[level.ex_drm]]("ex_sentrygun_teamaction", 7, 0, 255, "int");
		level.ex_sentrygun_enemyaction = [[level.ex_drm]]("ex_sentrygun_enemyaction", 7, 0, 255, "int");
		level.ex_sentrygun_actiontime = [[level.ex_drm]]("ex_sentrygun_actiontime", 2, 1, 10, "int");
		level.ex_sentrygun_messages = [[level.ex_drm]]("ex_sentrygun_messages", 2, 0, 2, "int");
		level.ex_sentrygun_waypoints = [[level.ex_drm]]("ex_sentrygun_waypoints", 2, 0, 3, "int");
		level.ex_sentrygun_cpx = [[level.ex_drm]]("ex_sentrygun_cpx", 8, 0, 64, "int");
		level.ex_sentrygun_cpx_timer = [[level.ex_drm]]("ex_sentrygun_cpx_timer", 30, 0, 1800, "int");
		if(level.ex_sentrygun_cpx_timer > 0 && level.ex_sentrygun_cpx_timer < 10) level.ex_sentrygun_cpx_timer = 10;
		level.ex_sentrygun_cpx_nades = [[level.ex_drm]]("ex_sentrygun_cpx_nades", 2, 1, 10, "int");
	}

	//****************************************************************************
	// specials: unmanned ground vehicle (UGV aka sentry bot)
	//****************************************************************************
	level.ex_ugv = [[level.ex_drm]]("ex_ugv", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_ugv = 0;
	if(level.ex_ugv)
	{
		level.ex_ugv_timer = [[level.ex_drm]]("ex_ugv_timer", 120, 10, 1800, "int");
		level.ex_ugv_reach = [[level.ex_drm]]("ex_ugv_reach", 80, 20, 80, "int");
		level.ex_ugv_viewangle = [[level.ex_drm]]("ex_ugv_viewangle", 60, 20, level.ex_ugv_reach, "int");
		if(level.ex_ugv_viewangle > level.ex_ugv_reach) level.ex_ugv_viewangle = level.ex_ugv_reach;
		level.ex_ugv_maxhealth = [[level.ex_drm]]("ex_ugv_maxhealth", 2000, 1000, 99999, "int");
		level.ex_ugv_damage = [[level.ex_drm]]("ex_ugv_damage", 40, 1, 100, "int");
		level.ex_ugv_fireradius = [[level.ex_drm]]("ex_ugv_fireradius", 1000, 500, 3000, "int");
		level.ex_ugv_rockets = [[level.ex_drm]]("ex_ugv_rockets", 4, 0, 4, "int");

		level.ex_ugv_remove = [[level.ex_drm]]("ex_ugv_remove", 0, 0, 255, "int");
		level.ex_ugv_actionradius = [[level.ex_drm]]("ex_ugv_actionradius", 100, 100, 150, "int");
		level.ex_ugv_owneraction = [[level.ex_drm]]("ex_ugv_owneraction", 15, 0, 255, "int");
		level.ex_ugv_teamaction = [[level.ex_drm]]("ex_ugv_teamaction", 7, 0, 255, "int");
		level.ex_ugv_enemyaction = [[level.ex_drm]]("ex_ugv_enemyaction", 7, 0, 255, "int");
		level.ex_ugv_actiontime = [[level.ex_drm]]("ex_ugv_actiontime", 2, 1, 10, "int");
		level.ex_ugv_messages = [[level.ex_drm]]("ex_ugv_messages", 2, 0, 2, "int");
		level.ex_ugv_waypoints = [[level.ex_drm]]("ex_ugv_waypoints", 2, 0, 3, "int");
		level.ex_ugv_cpx = [[level.ex_drm]]("ex_ugv_cpx", 8, 0, 64, "int");
		level.ex_ugv_cpx_timer = [[level.ex_drm]]("ex_ugv_cpx_timer", 30, 0, 1800, "int");
		if(level.ex_ugv_cpx_timer > 0 && level.ex_ugv_cpx_timer < 10) level.ex_ugv_cpx_timer = 10;
		level.ex_ugv_cpx_nades = [[level.ex_drm]]("ex_ugv_cpx_nades", 2, 1, 10, "int");
	}

	//****************************************************************************
	// specials: quadrotor sentry guard
	//****************************************************************************
	level.ex_quad = [[level.ex_drm]]("ex_quad", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_quad = 0;
	if(level.ex_quad)
	{
		level.ex_quad_timer = [[level.ex_drm]]("ex_quad_timer", 120, 10, 1800, "int");
		level.ex_quad_stayondeath = [[level.ex_drm]]("ex_quad_stayondeath", 1, 0, 1, "int");
		level.ex_quad_viewangle = [[level.ex_drm]]("ex_quad_viewangle", 60, 20, 80, "int");
		level.ex_quad_damage = [[level.ex_drm]]("ex_quad_damage", 20, 1, 100, "int");
		level.ex_quad_fireradius = [[level.ex_drm]]("ex_quad_fireradius", 1000, 500, 3000, "int");
	}

	//****************************************************************************
	// specials: helicopter support
	//****************************************************************************
	level.ex_heli = [[level.ex_drm]]("ex_heli", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_heli = 0;
	if(level.ex_heli)
	{
		level.ex_heli_timer = [[level.ex_drm]]("ex_heli_timer", 60, 10, 1800, "int");
		level.ex_heli_gun = [[level.ex_drm]]("ex_heli_gun", 1, 0, 1, "int");
		level.ex_heli_gun_fov = [[level.ex_drm]]("ex_heli_gun_fov", 40, 20, 80, "int");
		level.ex_heli_gun_radius = [[level.ex_drm]]("ex_heli_gun_radius", 2000, 500, 9999, "int");
		level.ex_heli_missile = [[level.ex_drm]]("ex_heli_missile", 4, 0, 4, "int");
		level.ex_heli_missile_target = [[level.ex_drm]]("ex_heli_missile_target", 63, 1, 63, "int");
		level.ex_heli_missile_fov = [[level.ex_drm]]("ex_heli_missile_fov", 80, 20, 80, "int");
		level.ex_heli_missile_radius = [[level.ex_drm]]("ex_heli_missile_radius", 5000, 1000, 99999, "int");
		level.ex_heli_tube = [[level.ex_drm]]("ex_heli_tube", 2, 0, 2, "int");
		level.ex_heli_tube_fov = [[level.ex_drm]]("ex_heli_tube_fov", 40, 20, 80, "int");
		level.ex_heli_tube_radius = [[level.ex_drm]]("ex_heli_tube_radius", 5000, 1000, 99999, "int");
		level.ex_heli_maxhealth = [[level.ex_drm]]("ex_heli_maxhealth", 2000, 1000, 99999, "int");
		level.ex_heli_candamage = [[level.ex_drm]]("ex_heli_candamage", 1, 0, 1, "int");
		level.ex_heli_damagehud = [[level.ex_drm]]("ex_heli_damagehud", 1, 0, 1, "int");
		level.ex_heli_crash = [[level.ex_drm]]("ex_heli_crash", 0, 0, 100, "int");
		level.ex_heli_dust = [[level.ex_drm]]("ex_heli_dust", 0, 0, 1, "int");
	}

	//****************************************************************************
	// specials: gunship
	//****************************************************************************
	level.ex_gunship_special = [[level.ex_drm]]("ex_gunship_special", 1, 0, 1, "int");
	if(!level.ex_specials) level.ex_gunship_special = 0;

	//****************************************************************************
	// gunship
	//****************************************************************************
	level.ex_gunship = [[level.ex_drm]]("ex_gunship", 0, 0, 3, "int");
	if(level.ex_gunship || level.ex_gunship_special)
	{
		level.ex_gunship_killspree = [[level.ex_drm]]("ex_gunship_killspree", 10, 5, 30, "int");
		level.ex_gunship_killspree_once = [[level.ex_drm]]("ex_gunship_killspree_once", 0, 0, 1, "int");
		level.ex_gunship_obitladder = [[level.ex_drm]]("ex_gunship_obitladder", 5, 2, 9, "int");
		level.ex_gunship_obitladder_once = [[level.ex_drm]]("ex_gunship_obitladder_once", 0, 0, 1, "int");
		level.ex_gunship_maxhealth = [[level.ex_drm]]("ex_gunship_maxhealth", 2000, 1000, 99999, "int");
		level.ex_gunship_rotationspeed = [[level.ex_drm]]("ex_gunship_rotationspeed", 40, 10, 120, "int");
		level.ex_gunship_radius_tweak = [[level.ex_drm]]("ex_gunship_radius_tweak", 150, 100, 500, "int");
		level.ex_gunship_time = [[level.ex_drm]]("ex_gunship_time", 60, 10, 300, "int");
		level.ex_gunship_refill = [[level.ex_drm]]("ex_gunship_refill", 0, 0, 1, "int");
		level.ex_gunship_health = [[level.ex_drm]]("ex_gunship_health", 1, 0, 1, "int");
		level.ex_gunship_protect = [[level.ex_drm]]("ex_gunship_protect", 2, 0, 2, "int");
		level.ex_gunship_25mm = [[level.ex_drm]]("ex_gunship_25mm", 500, 0, 999, "int");
		level.ex_gunship_40mm = [[level.ex_drm]]("ex_gunship_40mm", 30, 0, 999, "int");
		level.ex_gunship_40mm_unlock = [[level.ex_drm]]("ex_gunship_40mm_unlock", 0, 0, 999, "int");
		level.ex_gunship_105mm = [[level.ex_drm]]("ex_gunship_105mm", 10, 0, 999, "int");
		level.ex_gunship_105mm_unlock = [[level.ex_drm]]("ex_gunship_105mm_unlock", 0, 0, 999, "int");
		level.ex_gunship_nuke = [[level.ex_drm]]("ex_gunship_nuke", 1, 0, 999, "int");
		level.ex_gunship_nuke_unlock = [[level.ex_drm]]("ex_gunship_nuke_unlock", 10, 0, 999, "int");
		level.ex_gunship_nuke_fx = [[level.ex_drm]]("ex_gunship_nuke_fx", 1, 0, 1, "int");
		level.ex_gunship_nuke_wipeout = [[level.ex_drm]]("ex_gunship_nuke_wipeout", 1, 0, 3, "int");
		level.ex_gunship_eject = [[level.ex_drm]]("ex_gunship_eject", 15, 0, 15, "int");
		level.ex_gunship_eject_dropzone = [[level.ex_drm]]("ex_gunship_eject_dropzone", 0, 0, 1, "int");
		level.ex_gunship_eject_protect = [[level.ex_drm]]("ex_gunship_eject_protect", 2, 0, 2, "int");
		level.ex_gunship_clock = [[level.ex_drm]]("ex_gunship_clock", 1, 0, 1, "int");
		level.ex_gunship_grain = [[level.ex_drm]]("ex_gunship_grain", 0, 0, 1, "int");
		level.ex_gunship_visible = [[level.ex_drm]]("ex_gunship_visible", 1, 0, 2, "int");
		level.ex_gunship_inform = [[level.ex_drm]]("ex_gunship_inform", 2, 0, 2, "int");
		level.ex_gunship_advertise = [[level.ex_drm]]("ex_gunship_advertise", 5, 0, 30, "int");
		level.ex_gunship_airraid = [[level.ex_drm]]("ex_gunship_airraid", 1, 0, 1, "int");
		level.ex_gunship_ambientsound = [[level.ex_drm]]("ex_gunship_ambientsound", 1, 0, 2, "int");
		level.ex_gunship_cm = [[level.ex_drm]]("ex_gunship_cm", 5, 0, 999, "int");
		level.ex_gunship_cm_ttl = [[level.ex_drm]]("ex_gunship_cm_ttl", 10, 5, 15, "int");

		level.ex_gunship_weapons = [];
		if(level.ex_gunship_25mm)
		{
			gunship_weapons_index = level.ex_gunship_weapons.size;
			level.ex_gunship_weapons[gunship_weapons_index] = spawnstruct();
			level.ex_gunship_weapons[gunship_weapons_index].weapon = "gunship_25mm_mp";
			level.ex_gunship_weapons[gunship_weapons_index].overlay = "gunship_overlay_25mm";
			level.ex_gunship_weapons[gunship_weapons_index].clip = 500;
			level.ex_gunship_weapons[gunship_weapons_index].ammo = level.ex_gunship_25mm;
			level.ex_gunship_weapons[gunship_weapons_index].enabled = true;
			level.ex_gunship_weapons[gunship_weapons_index].locked = false;
		}
		if(level.ex_gunship_40mm)
		{
			gunship_weapons_index = level.ex_gunship_weapons.size;
			level.ex_gunship_weapons[gunship_weapons_index] = spawnstruct();
			level.ex_gunship_weapons[gunship_weapons_index].weapon = "gunship_40mm_mp";
			level.ex_gunship_weapons[gunship_weapons_index].overlay = "gunship_overlay_40mm";
			level.ex_gunship_weapons[gunship_weapons_index].clip = 1;
			level.ex_gunship_weapons[gunship_weapons_index].ammo = level.ex_gunship_40mm;
			level.ex_gunship_weapons[gunship_weapons_index].enabled = true;
			level.ex_gunship_weapons[gunship_weapons_index].locked = (level.ex_gunship_40mm_unlock != 0);
		}
		if(level.ex_gunship_105mm)
		{
			gunship_weapons_index = level.ex_gunship_weapons.size;
			level.ex_gunship_weapons[gunship_weapons_index] = spawnstruct();
			level.ex_gunship_weapons[gunship_weapons_index].weapon = "gunship_105mm_mp";
			level.ex_gunship_weapons[gunship_weapons_index].overlay = "gunship_overlay_105mm";
			level.ex_gunship_weapons[gunship_weapons_index].clip = 1;
			level.ex_gunship_weapons[gunship_weapons_index].ammo = level.ex_gunship_105mm;
			level.ex_gunship_weapons[gunship_weapons_index].enabled = true;
			level.ex_gunship_weapons[gunship_weapons_index].locked = (level.ex_gunship_105mm_unlock != 0);
		}
		if(level.ex_gunship_nuke)
		{
			gunship_weapons_index = level.ex_gunship_weapons.size;
			level.ex_gunship_weapons[gunship_weapons_index] = spawnstruct();
			level.ex_gunship_weapons[gunship_weapons_index].weapon = "gunship_nuke_mp";
			level.ex_gunship_weapons[gunship_weapons_index].overlay = "gunship_overlay_nuke";
			level.ex_gunship_weapons[gunship_weapons_index].clip = 0; // force reload
			level.ex_gunship_weapons[gunship_weapons_index].ammo = level.ex_gunship_nuke;
			level.ex_gunship_weapons[gunship_weapons_index].enabled = true;
			level.ex_gunship_weapons[gunship_weapons_index].locked = (level.ex_gunship_nuke_unlock != 0);
		}

		if(level.ex_gunship_weapons.size)
		{
			locked_total = 0;
			for(i = 0; i < level.ex_gunship_weapons.size; i++)
				if(!level.ex_gunship_weapons[i].enabled || level.ex_gunship_weapons[i].locked) locked_total++;
			if(locked_total == level.ex_gunship_weapons.size)
			{
				level.ex_gunship = 0;
				level.ex_gunship_special = 0;
			}
		}
		else
		{
			level.ex_gunship = 0;
			level.ex_gunship_special = 0;
		}
	}

	//****************************************************************************
	// music options (keep before executing _ex_gtcommon)
	//****************************************************************************
	level.ex_cinematic = [[level.ex_drm]]("ex_cinematic", 1, 0, 3, "int");
	level.ex_intromusic = [[level.ex_drm]]("ex_intromusic", 0, 0, 3, "int");
	level.ex_specmusic = [[level.ex_drm]]("ex_specmusic", 0, 0, 1, "int");
	level.ex_deathmusic = [[level.ex_drm]]("ex_deathmusic", 0, 0, 1, "int");
	level.ex_endmusic = [[level.ex_drm]]("ex_endmusic", 0, 0, 1, "int");
	level.ex_statsmusic = [[level.ex_drm]]("ex_statsmusic", 0, 0, 1, "int");
	level.ex_mvmusic = [[level.ex_drm]]("ex_votemusic", 0, 0, 1, "int");

	//****************************************************************************
	// game type common variables
	//****************************************************************************
	extreme\_ex_gtcommon::init();

	//****************************************************************************
	// winner announcement
	//****************************************************************************
	level.ex_announcewinner = [[level.ex_drm]]("ex_announcewinner", 1, 0, 1, "int");
	level.ex_announcewinner_delay = [[level.ex_drm]]("ex_announcewinner_delay", 5, 1, 10, "int");
	if(!level.ex_teamplay) level.ex_announcewinner = 0;

	//****************************************************************************
	// dumb bots (stock test clients)
	//****************************************************************************
	level.ex_testclients = [[level.ex_drm]]("ex_testclients", 0, 0, level.ex_maxclients - 1, "int");
	level.ex_testclients_diag = [[level.ex_drm]]("ex_testclients_diag", 0, 0, 1, "int");
	if(level.ex_testclients) level.ex_testclients_freeze = [[level.ex_drm]]("ex_testclients_freeze", 0, 0, 1, "int");

	//****************************************************************************
	// AI bots (based on MBot)
	//****************************************************************************
	level.ex_mbot = [[level.ex_drm]]("ex_mbot", 0, 0, 1, "int");
	if(level.ex_mbot)
	{
		level.ex_mbot_allies = [[level.ex_drm]]("ex_mbot_allies", 5, 0, 32, "int");
		level.ex_mbot_axis = [[level.ex_drm]]("ex_mbot_axis", 5, 0, 32, "int");
		level.ex_mbot_spec = [[level.ex_drm]]("ex_mbot_spec", 0, 0, 32, "int");
		level.ex_mbot_skill = [[level.ex_drm]]("ex_mbot_skill", 5, 0, 10, "int");
		level.ex_mbot_speed = [[level.ex_drm]]("ex_mbot_speed", 180, 50, 220, "int");
		level.ex_mbot_maxdist = [[level.ex_drm]]("ex_mbot_maxdist", 1000, 100, 9999, "int");
		level.ex_mbot_viewangle = [[level.ex_drm]]("ex_mbot_viewangle", 120, 90, 180, "int");
		level.ex_mbot_timelimit = [[level.ex_drm]]("ex_mbot_timelimit", 0, 0, 9999, "int");
		if(level.ex_mbot_timelimit > 0 && level.ex_mbot_timelimit < 30) level.ex_mbot_timelimit = 30;
		level.ex_mbot_scorelimit = [[level.ex_drm]]("ex_mbot_scorelimit", 10000, 0, 99999, "int");
		if(level.ex_mbot_scorelimit > 0 && level.ex_mbot_scorelimit < 10) level.ex_mbot_scorelimit = 10;
		level.ex_mbot_dev = [[level.ex_drm]]("ex_mbot_dev", 0, 0, 1, "int");
		level.ex_mbot_devname = [[level.ex_drm]]("ex_mbot_devname", "", "", "", "string");
		level.ex_mbot_dev_pointer = [[level.ex_drm]]("ex_mbot_dev_pointer", 0, 0, 1, "int");
		level.ex_mbot_dev_filter = [[level.ex_drm]]("ex_mbot_dev_filter", 0, 0, 1, "int");
		level.ex_mbot_dev_confilter = [[level.ex_drm]]("ex_mbot_dev_confilter", 0, 0, 1, "int");
		level.ex_mbot_dev_killmode = [[level.ex_drm]]("ex_mbot_dev_killmode", 0, 0, 1, "int");
		level.ex_mbot_dev_killdev = [[level.ex_drm]]("ex_mbot_dev_killdev", 0, 0, 1, "int");
		level.ex_mbot_dev_autosave = [[level.ex_drm]]("ex_mbot_dev_autosave", 0, 0, 1, "int");

		if(level.ex_currentgt == "tdm")
		{
			level.ex_mbot_spawnpoints = getentarray("mp_tdm_spawn", "classname");
			if(level.ex_mbot_spawnpoints.size)
			{
				if(!extreme\_ex_bots::mapSupportsMBots(level.ex_currentmap, level.ex_currentgt))
				{
					if(!level.ex_mbot_dev)
					{
						level.ex_mbot = 0;
						level.ex_mbot_spawnpoints = undefined;
						logprint("MBOTS: SWITCHED OFF! UNSUPPORTED MAP: " + level.ex_currentmap + "\n");
					}
					else logprint("MBOTS: DEVELOPER ON UNSUPPORTED MAP: " + level.ex_currentmap + "\n");
				}
			}
			else
			{
				level.ex_mbot = 0;
				level.ex_mbot_dev = 0;
				level.ex_mbot_spawnpoints = undefined;
				logprint("MBOTS: SWITCHED OFF! NO TDM SPAWNPOINTS FOUND ON MAP: " + level.ex_currentmap + "\n");
			}
		}
		else
		{
			level.ex_mbot = 0;
			level.ex_mbot_dev = 0;
			logprint("MBOTS: SWITCHED OFF! UNSUPPORTED GAME TYPE: " + level.ex_currentgt + "\n");
		}
	}

	//****************************************************************************
	// ready-up
	//****************************************************************************
	level.ex_readyup = [[level.ex_drm]]("ex_readyup", 0, 0, 2, "int");
	if(level.ex_readyup)
	{
		level.ex_readyup_gtsd = [[level.ex_drm]]("ex_readyup_gtsd", 5, 5, 120, "int");
		level.ex_readyup_min = [[level.ex_drm]]("ex_readyup_min", 2, 1, 64, "int");
		level.ex_readyup_minteam = [[level.ex_drm]]("ex_readyup_minteam", 1, 1, 64, "int");
		level.ex_readyup_timer = [[level.ex_drm]]("ex_readyup_timer", 60, 0, 600, "int");
		level.ex_readyup_timermode = [[level.ex_drm]]("ex_readyup_timermode", 0, 0, 2, "int");
		level.ex_readyup_ticketing = [[level.ex_drm]]("ex_readyup_ticketing", 0, 0, 2, "int");
		level.ex_readyup_graceperiod = [[level.ex_drm]]("ex_readyup_graceperiod", 0, 0, 600, "int");
		if(level.ex_readyup_ticketing == 2 || !level.ex_roundbased) level.ex_readyup_graceperiod = 0;
	}

	//****************************************************************************
	// scoped-On HUD indicator
	//****************************************************************************
	level.ex_scopedon = [[level.ex_drm]]("ex_scopedon", 0, 0, 1, "int");

	//****************************************************************************
	// menu item for adding server to the favorites
	//****************************************************************************
	level.ex_addtofavorites = [[level.ex_drm]]("ex_addtofavorites", 1, 0, 1, "int");

	//****************************************************************************
	// menu items for the server connection hub
	//****************************************************************************
	level.ex_hub_server1_name = [[level.ex_drm]]("ex_hub_server1_name", "", "", "", "string");
	level.ex_hub_server1_ip = [[level.ex_drm]]("ex_hub_server1_ip", "", "", "", "string");
	level.ex_hub_server2_name = [[level.ex_drm]]("ex_hub_server2_name", "", "", "", "string");
	level.ex_hub_server2_ip = [[level.ex_drm]]("ex_hub_server2_ip", "", "", "", "string");
	level.ex_hub_server3_name = [[level.ex_drm]]("ex_hub_server3_name", "", "", "", "string");
	level.ex_hub_server3_ip = [[level.ex_drm]]("ex_hub_server3_ip", "", "", "", "string");
	level.ex_hub_server4_name = [[level.ex_drm]]("ex_hub_server4_name", "", "", "", "string");
	level.ex_hub_server4_ip = [[level.ex_drm]]("ex_hub_server4_ip", "", "", "", "string");

	level.ex_hub_password = false;
	hub_trigger = [[level.ex_drm]]("ex_hub_trigger", "password", "", "", "string");
	if(isSubStr(tolower(level.ex_hub_server4_name), tolower(hub_trigger)))
	{
		level.ex_hub_password = true;
		level.ex_hub_server4_ip = "";
	}

	//****************************************************************************
	// map in-game menu voting
	//****************************************************************************
	level.ex_ingame_vote_allow_old = [[level.ex_drm]]("ex_ingame_vote_allow_old", 1, 0, 1, "int");
	level.ex_ingame_vote_allow_gametype = [[level.ex_drm]]("ex_ingame_vote_allow_gametype", 0, 0, 1, "int");
	level.ex_ingame_vote_allow_map = [[level.ex_drm]]("ex_ingame_vote_allow_map", 0, 0, 1, "int");

	//****************************************************************************
	// map voting system
	//****************************************************************************
	level.ex_stock_maps = [[level.ex_drm]]("ex_stock_maps", 1, 0, 1, "int");
	level.ex_mapvote = [[level.ex_drm]]("ex_endgame_vote", 0, 0, 1, "int");
	if(level.ex_mapvote)
	{
		level.ex_mapvotemax = [[level.ex_drm]]("ex_endgame_vote_max", 160, 10, 160, "int");
		level.ex_mapvotemode = [[level.ex_drm]]("ex_endgame_vote_mode", 0, 0, 7, "int");
		level.ex_mapvoteweaponmode = [[level.ex_drm]]("ex_endgame_vote_weaponmode", 0, 0, 1, "int");
		level.ex_mapvoteweaponmode_allow = [[level.ex_drm]]("ex_endgame_vote_weaponmode_allow", "team class1 class2 class3 class4 class5 class6 class7 class8 class9 class10 all bash frag server random", "", "", "string");
		level.ex_mapvotetime = [[level.ex_drm]]("ex_endgame_vote_time", 30, 10, 180, "int");
		level.ex_mapvotetimegt = [[level.ex_drm]]("ex_endgame_vote_time_gt", 10, 10, 180, "int");
		level.ex_mapvotetimewm = [[level.ex_drm]]("ex_endgame_vote_time_wm", 20, 10, 180, "int");
		level.ex_mapvotereplay = [[level.ex_drm]]("ex_endgame_vote_replay", 0, 0, 2, "int");
		level.ex_mapvoteignclan = [[level.ex_drm]]("ex_endgame_ignore_clanvoting", 0, 0, 1, "int");
		level.ex_mapvote_memory = [[level.ex_drm]]("ex_endgame_vote_memory", 0, 0, 1, "int");
		level.ex_mapvote_memory_max = [[level.ex_drm]]("ex_endgame_vote_memory_max", 3, 2, 50, "int");
		level.ex_mapvote_filter = [[level.ex_drm]]("ex_endgame_vote_filter", 0, 0, 2, "int");
		level.ex_mapvote_filter_who = [[level.ex_drm]]("ex_endgame_vote_filter_who", 0, 0, 1, "int");
		level.ex_mapvote_thumbnails = [[level.ex_drm]]("ex_endgame_vote_thumbnails", 0, 0, 1, "int");
		level.ex_mapvote_movex = [[level.ex_drm]]("ex_endgame_vote_movex", 150, 0, 150, "int");
		level.ex_mapvote_skiplastgt = [[level.ex_drm]]("ex_endgame_vote_skiplastgt", 0, 0, 1, "int");

		if(level.ex_mapvote_memory) level.ex_mapvotereplay = 0; // no replay when memory is enabled
		if(level.ex_mapvotemode < 4) level.ex_mapvote_thumbnails = 0; // prevent thumbnail precaching
	}
	else level.ex_mapvotemode = 0; // for map rotation messages

	//****************************************************************************
	// in-game RCON
	//****************************************************************************
	level.ex_rcon = [[level.ex_drm]]("ex_rcon", 0, 0, 1, "int");
	if(level.ex_rcon)
	{
		level.ex_rcon_mode = [[level.ex_drm]]("ex_rcon_mode", 0, 0, 1, "int");
		level.ex_rcon_autopass = [[level.ex_drm]]("ex_rcon_autopass", 0, 0, 1, "int");
		level.ex_rcon_cachepin = [[level.ex_drm]]("ex_rcon_cachepin", 0, 0, 1, "int");
		level.ex_rcon_access_default = [[level.ex_drm]]("ex_rcon_access_default", 127, 1, 127, "int");
		level.ex_rcon_truncate = [[level.ex_drm]]("ex_rcon_truncate", 1, 0, 1, "int");
		level.ex_rcon_color = [[level.ex_drm]]("ex_rcon_color", 1, 0, 1, "int");
		level.ex_rcon_playeraction = [[level.ex_drm]]("ex_rcon_playeraction", 0, 0, 20, "int");
		level.ex_rcon_playermodel = [[level.ex_drm]]("ex_rcon_playermodel", 0, 0, 7, "int");
		level.ex_rcon_mapaction = [[level.ex_drm]]("ex_rcon_mapaction", 0, 0, 5, "int");
	}

	//****************************************************************************
	// crybaby punishment
	//****************************************************************************
	level.ex_crybaby = [[level.ex_drm]]("ex_crybaby", 1, 0, 1, "int");
	if(level.ex_crybaby)
	{
		level.ex_crybaby_transp = [[level.ex_drm]]("ex_crybaby_transp", 0, 0, 9, "int");
		level.ex_crybaby_time = [[level.ex_drm]]("ex_crybaby_time", 20, 5, 60, "int");
	}

	//****************************************************************************
	// weapons on back
	//****************************************************************************
	level.ex_weaponsonback = [[level.ex_drm]]("ex_weaponsonback", 0, 0, 2, "int");
	
	//****************************************************************************
	// close kill protection
	//****************************************************************************
	level.ex_closekill = [[level.ex_drm]]("ex_closekill", 0, 0, 1, "int");
	if(level.ex_closekill)
	{
		level.ex_closekill_units = [[level.ex_drm]]("ex_closekill_units", 0, 0, 1, "int");
		level.ex_closekill_distance = [[level.ex_drm]]("ex_closekill_distance", 30, 1, 999, "int");
		level.ex_closekill_msg = [[level.ex_drm]]("ex_closekill_msg", 0, 0, 2, "int");
	}

	//****************************************************************************
	// anti-hip
	//****************************************************************************
	level.ex_antihip = [[level.ex_drm]]("ex_antihip", 0, 0, 1, "int");

	//****************************************************************************
	// anti-run
	//****************************************************************************
	level.ex_antirun = [[level.ex_drm]]("ex_antirun", 0, 0, 2, "int");
	level.ex_antirun_spawncrouched = [[level.ex_drm]]("ex_antirun_spawncrouched", 0, 0, 1, "int");
	if(level.ex_antirun)
	{
		level.ex_antirun_ads = [[level.ex_drm]]("ex_antirun_ads", 1, 0, 1, "int");
		level.ex_antirun_distance = [[level.ex_drm]]("ex_antirun_distance", 500, 100, 9999, "int");
	}

	//****************************************************************************
	// inactivity monitor
	//****************************************************************************
	level.ex_inactive_plyr = [[level.ex_drm]]("ex_inactive_plyr", 0, 0, 1, "int");
	level.ex_inactive_plyr_time = [[level.ex_drm]]("ex_inactive_plyr_time", 5, 1, 999, "int");
	level.ex_inactive_dead = [[level.ex_drm]]("ex_inactive_dead", 0, 0, 1, "int");
	level.ex_inactive_dead_time = [[level.ex_drm]]("ex_inactive_dead_time", 5, 1, 999, "int");
	level.ex_inactive_spec = [[level.ex_drm]]("ex_inactive_spec", 0, 0, 1, "int");
	level.ex_inactive_spec_time = [[level.ex_drm]]("ex_inactive_spec_time", 15, 1, 999, "int");
	level.ex_inactive_msg = [[level.ex_drm]]("ex_inactive_msg", 1, 0, 1, "int");

	//****************************************************************************
	// server redirection
	//****************************************************************************
	level.ex_redirect = [[level.ex_drm]]("ex_redirect", 0, 0, 1, "int");
	if(level.ex_redirect)
	{
		level.ex_redirect_ip = [[level.ex_drm]]("ex_redirect_ip", "", "", "", "string");
		level.ex_redirect_pause = [[level.ex_drm]]("ex_redirect_pause", 10, 5, 60, "int");
		level.ex_redirect_reason = [[level.ex_drm]]("ex_redirect_reason", 0, 0, 3, "int");
		level.ex_redirect_logic = [[level.ex_drm]]("ex_redirect_logic", 2, 0, 2, "int");
		level.ex_redirect_priority = [[level.ex_drm]]("ex_redirect_priority", 0, 0, 4, "int");
		level.ex_redirect_hint = [[level.ex_drm]]("ex_redirect_hint", 1, 0, 1, "int");
	}

	//****************************************************************************
	// parachuting
	//****************************************************************************
	level.ex_parachutes = [[level.ex_drm]]("ex_parachutes", 0, 0, 5, "int");
	if(level.ex_parachutes)
	{
		level.ex_parachutesonlyattackers = [[level.ex_drm]]("ex_parachutes_only_attackers", 0, 0, 1, "int");
		level.ex_parachutesprotection = [[level.ex_drm]]("ex_parachutes_protection", 2, 0, 2, "int");
		level.ex_parachuteslimitaltitude = [[level.ex_drm]]("ex_parachutes_limit_altitude", 2000, 0, 6000, "int");
		level.ex_parachutes_chance = [[level.ex_drm]]("ex_parachutes_chance", 10, 1, 100, "int");
	}

	//****************************************************************************
	// long range rifles
	//****************************************************************************
	level.ex_longrange = [[level.ex_drm]]("ex_longrange", 0, 0, 2, "int");
	level.ex_longrange_memory = [[level.ex_drm]]("ex_longrange_memory", 1, 0, 1, "int");
	if(level.ex_longrange) level.ex_longrange_autoswitch = [[level.ex_drm]]("ex_longrange_autoswitch", 0, 0, 1, "int");

	//****************************************************************************
	// long range rifles hitloc
	//****************************************************************************
	level.ex_lrhitloc = [[level.ex_drm]]("ex_lrhitloc", 0, 0, 1, "int");
	if(level.ex_longrange == 2) level.ex_lrhitloc = 1;
	if(level.ex_lrhitloc)
	{
		level.ex_lrhitloc_unit = [[level.ex_drm]]("ex_lrhitloc_unit", 1, 0, 1, "int");
		level.ex_lrhitloc_msg = [[level.ex_drm]]("ex_lrhitloc_msg", 1, 0, 2, "int");
		level.ex_lrhitloc_head = [[level.ex_drm]]("ex_lrhitloc_head", 100, 1, 500, "int");
		level.ex_lrhitloc_neck = [[level.ex_drm]]("ex_lrhitloc_neck", 90, 1, 500, "int");
		level.ex_lrhitloc_torso_upper = [[level.ex_drm]]("ex_lrhitloc_torso_upper", 80, 1, 500, "int");
		level.ex_lrhitloc_torso_lower = [[level.ex_drm]]("ex_lrhitloc_torso_lower", 70, 1, 500, "int");
		level.ex_lrhitloc_right_leg_upper = [[level.ex_drm]]("ex_lrhitloc_right_leg_upper", 60, 1, 500, "int");
		level.ex_lrhitloc_right_leg_lower = [[level.ex_drm]]("ex_lrhitloc_right_leg_lower", 40, 1, 500, "int");
		level.ex_lrhitloc_left_leg_upper = [[level.ex_drm]]("ex_lrhitloc_left_leg_upper", 60, 1, 500, "int");
		level.ex_lrhitloc_left_leg_lower = [[level.ex_drm]]("ex_lrhitloc_left_leg_lower", 40, 1, 500, "int");
		level.ex_lrhitloc_right_arm_upper = [[level.ex_drm]]("ex_lrhitloc_right_arm_upper", 50, 1, 500, "int");
		level.ex_lrhitloc_right_arm_lower = [[level.ex_drm]]("ex_lrhitloc_right_arm_lower", 40, 1, 500, "int");
		level.ex_lrhitloc_left_arm_upper = [[level.ex_drm]]("ex_lrhitloc_left_arm_upper", 50, 1, 500, "int");
		level.ex_lrhitloc_left_arm_lower = [[level.ex_drm]]("ex_lrhitloc_left_arm_lower", 40, 1, 500, "int");
		level.ex_lrhitloc_right_hand = [[level.ex_drm]]("ex_lrhitloc_right_hand", 30, 1, 500, "int");
		level.ex_lrhitloc_left_hand = [[level.ex_drm]]("ex_lrhitloc_left_hand", 30, 1, 500, "int");
		level.ex_lrhitloc_right_foot = [[level.ex_drm]]("ex_lrhitloc_right_foot", 20, 1, 500, "int");
		level.ex_lrhitloc_left_foot = [[level.ex_drm]]("ex_lrhitloc_left_foot", 20, 1, 500, "int");
	}

	//****************************************************************************
	// sniper zoom level
	//****************************************************************************
	level.ex_zoom = [[level.ex_drm]]("ex_zoom", 0, 0, 2, "int");
	level.ex_zoom_memory = [[level.ex_drm]]("ex_zoom_memory", 1, 0, 1, "int");
	// keep here: memory defaults
	level.ex_zoom_min_sr = [[level.ex_drm]]("ex_zoom_min_sr", 1, 1, 10, "int");
	level.ex_zoom_max_sr = [[level.ex_drm]]("ex_zoom_max_sr", 7, level.ex_zoom_min_sr, 10, "int");
	level.ex_zoom_default_sr = [[level.ex_drm]]("ex_zoom_default_sr", 5, level.ex_zoom_min_sr, level.ex_zoom_max_sr, "int");
	level.ex_zoom_min_lr = [[level.ex_drm]]("ex_zoom_min_lr", 1, 1, 10, "int");
	level.ex_zoom_max_lr = [[level.ex_drm]]("ex_zoom_max_lr", 9, level.ex_zoom_min_lr, 10, "int");
	level.ex_zoom_default_lr = [[level.ex_drm]]("ex_zoom_default_lr", 7, level.ex_zoom_min_lr, level.ex_zoom_max_lr, "int");
	if(level.ex_zoom)
	{
		level.ex_zoom_class = [[level.ex_drm]]("ex_zoom_class", 3, 1, 3, "int");
		level.ex_zoom_switchreset = [[level.ex_drm]]("ex_zoom_switchreset", 0, 0, 1, "int");
		level.ex_zoom_adsreset = [[level.ex_drm]]("ex_zoom_adsreset", 0, 0, 1, "int");
		level.ex_zoom_gradual = [[level.ex_drm]]("ex_zoom_gradual", 1, 0, 1, "int");
		level.ex_zoom_hud = [[level.ex_drm]]("ex_zoom_hud", 1, 0, 1, "int");
	}

	//****************************************************************************
	// game type options
	//****************************************************************************
	level.ex_reward_melee = [[level.ex_drm]]("ex_reward_melee", 0, 0, 5, "int");
	level.ex_reward_headshot = [[level.ex_drm]]("ex_reward_headshot", 0, 0, 5, "int");
	level.ex_reward_kamikaze = [[level.ex_drm]]("ex_reward_kamikaze", 0, 0, 5, "int");
	level.ex_reward_landmine = [[level.ex_drm]]("ex_reward_defuse_landmine", 0, 0, 5, "int");
	level.ex_reward_tripwire = [[level.ex_drm]]("ex_reward_defuse_tripwire", 0, 0, 5, "int");
	level.ex_reward_teamkill = [[level.ex_drm]]("ex_reward_teamkill", 0, 0, 1, "int");
	level.ex_reward_killspree = [[level.ex_drm]]("ex_reward_killspree", 0, 0, 5, "int");
	level.ex_reward_killspree_power = [[level.ex_drm]]("ex_reward_killspree_power", 1, 1, 5, "int");

	// arcade style HUD score
	level.ex_arcade_score = [[level.ex_drm]]("ex_arcade_score", 0, 0, 1, "int");
	if(level.ex_arcade_score)
	{
		level.ex_arcade_score_red = [[level.ex_drm]]("ex_arcade_score_red", 1, 0, 1, "float");
		level.ex_arcade_score_green = [[level.ex_drm]]("ex_arcade_score_green", 1, 0, 1, "float");
		level.ex_arcade_score_blue = [[level.ex_drm]]("ex_arcade_score_blue", 0, 0, 1, "float");
	}

	// arcade style HUD images
	level.ex_arcade_shaders = [[level.ex_drm]]("ex_arcade_shaders", 31, 0, 32, "int");
	if(level.ex_arcade_shaders)
	{
		level.ex_arcade_shaders_perkall = [[level.ex_drm]]("ex_arcade_shaders_perkall", 0, 0, 1, "int");
		level.ex_arcade_shaders_spree = [[level.ex_drm]]("ex_arcade_shaders_spree", 2, 1, 5, "int");
		level.ex_arcade_shaders_ladder = [[level.ex_drm]]("ex_arcade_shaders_ladder", 2, 1, 5, "int");
		level.ex_arcade_shaders_perk = [[level.ex_drm]]("ex_arcade_shaders_perk", 2, 1, 5, "int");
		level.ex_arcade_shaders_extra = [[level.ex_drm]]("ex_arcade_shaders_extra", 2, 1, 5, "int");
	}
	
	// best-of mode
	level.ex_bestof = [[level.ex_drm]]("ex_bestof", 0, 0, 1, "int");
	if(level.ex_roundbased) level.bestoflimit = int(game["roundlimit"] / 2) + 1;
		else level.bestoflimit = int(game["scorelimit"] / 2) + 1;

	// team swap (halftime, halfway or every round)
	level.ex_swapteams = [[level.ex_drm]]("ex_swapteams", 0, 0, 2, "int");
	if(level.ex_swapteams)
	{
		level.ex_swapteams_hudtime = [[level.ex_drm]]("ex_swapteams_hudtime", 5, 3, 10, "int");
		if(level.ex_roundbased)
		{
			if(level.ex_currentgt == "dom" || level.ex_currentgt == "lib" || level.ex_currentgt == "ons" || level.ex_currentgt == "ft") level.ex_swapteams = 0;
			if(level.ex_currentgt == "esd" && level.esd_swap_roundwinner) level.ex_swapteams = 0;
			if(level.ex_currentgt == "rbcnq" && level.rbcnq_swap_roundwinner) level.ex_swapteams = 0;
			if(level.ex_currentgt == "rbctf" && level.ex_swapteams == 2) level.ex_swapteams = 1;
			if(level.ex_swapteams == 2)
			{
				if(game["roundlimit"])
				{
					if(level.ex_swapteams == 2 && game["roundlimit"] % 2 != 0) game["roundlimit"]++;
					game["halftimelimit"] = int((game["roundlimit"] / 2) + 0.5);
				}
				else level.ex_swapteams = 0;
			}
		}
		else
		{
			level.ex_swapteams = 2;
			if(level.ex_currentgt != "ctf" && level.ex_currentgt != "ctfb" && level.ex_currentgt != "tdm") level.ex_swapteams = 0;
			if(level.ex_swapteams)
			{
				if(game["timelimit"])
				{
					game["halftimelimit"] = game["timelimit"] / 2;
					if(!isDefined(game["halftime"])) game["halftime"] = 0;
				}
				else level.ex_swapteams = 0;
			}
		}
	}

	// overtime
	level.ex_overtime = [[level.ex_drm]]("ex_overtime", 0, 0, 30, "int");
	if(level.ex_currentgt != "ctf" && level.ex_currentgt != "ctfb" && level.ex_currentgt != "tdm") level.ex_overtime = 0;
	if(level.ex_overtime)
	{
		level.ex_overtime_lastman = [[level.ex_drm]]("ex_overtime_lastman", 1, 0, 1, "int");
		level.ex_overtime_resetteam = [[level.ex_drm]]("ex_overtime_resetteam", 0, 0, 1, "int");
		level.ex_overtime_hudtime = [[level.ex_drm]]("ex_overtime_hudtime", 5, 3, 10, "int");
	}

	// animation on flag base
	if(level.ex_flagbased || level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
	{
		level.ex_flagbase_anim_allies = [[level.ex_drm]]("ex_flagbase_anim_allies", 0, 0, 7, "int");
		level.ex_flagbase_anim_axis = [[level.ex_drm]]("ex_flagbase_anim_axis", 0, 0, 7, "int");
		level.ex_flagbase_anim_neutral = [[level.ex_drm]]("ex_flagbase_anim_neutral", 0, 0, 7, "int");
		level.ex_flagbase_anim_height = [[level.ex_drm]]("ex_flagbase_anim_height", 2, 0, 10, "int");
	}

	//****************************************************************************
	// security GUID check
	//****************************************************************************
	level.ex_security = [[level.ex_drm]]("ex_security", 0, 0, 1, "int");

	//****************************************************************************
	// set up voices arrays
	//****************************************************************************
	level.ex_voices["german"] = 3;
	level.ex_voices["american"] = 7;
	level.ex_voices["russian"] = 6;
	level.ex_voices["british"] = 6;
	level.ex_voices["diana"] = 2;

	//****************************************************************************
	// bleeding
	//****************************************************************************
	level.ex_bleeding = [[level.ex_drm]]("ex_bleeding", 0, 0, 100, "int");
	if(level.ex_bleeding)
	{
		level.ex_startbleed = [[level.ex_drm]]("ex_startbleed", 50, 1, 99, "int");
		level.ex_maxbleed = [[level.ex_drm]]("ex_maxbleed", 50, 0, 100, "int");
		level.ex_bleedsound = [[level.ex_drm]]("ex_bleedsound", 0, 0, 3, "int");
		level.ex_bleedshock = [[level.ex_drm]]("ex_bleedshock", 1, 0, 1, "int");
		level.ex_bleedmsg = [[level.ex_drm]]("ex_bleedmsg", 1, 0, 2, "int");
	}

	//****************************************************************************
	// dead body handling
	//****************************************************************************
	level.ex_deadbodyfx = [[level.ex_drm]]("ex_deadbodyfx", 0, 0, 2, "int");

	//****************************************************************************
	// bulletholes
	//****************************************************************************
	level.ex_bulletholes = [[level.ex_drm]]("ex_bulletholes", 0, 0, 1, "int");

	//****************************************************************************
	// range finder
	//****************************************************************************
	level.ex_rangefinder = [[level.ex_drm]]("ex_rangefinder", 1, 0, 1, "int");
	if(level.ex_rangefinder) level.ex_rangefinder_units = [[level.ex_drm]]("ex_rangefinder_units", 1, 0, 1, "int");

	//****************************************************************************
	// stance shoot delay monitor
	//****************************************************************************
	level.ex_stanceshoot = [[level.ex_drm]]("ex_stanceshoot", 0, 0, 3, "int");
	if(level.ex_stanceshoot)
	{
		level.ex_jump_sensitivity = [[level.ex_drm]]("ex_jump_sensitivity", 7, 0, 10, "int");
		level.ex_stanceshoot_action = [[level.ex_drm]]("ex_stanceshoot_action", 0, 0, 100, "int");
	}

	//****************************************************************************
	// binoculars animated crosshair
	//****************************************************************************
	level.ex_aimrig = [[level.ex_drm]]("ex_aimrig", 5, 0, 7, "int");

	//****************************************************************************
	// classes
	//****************************************************************************
	level.ex_classes = [[level.ex_drm]]("ex_classes", 0, 0, 2, "int");
	if(level.ex_classes)
	{
		if(!level.ex_teamplay) level.ex_classes = 2;
		if(level.ex_classes == 1)
		{
			level.ex_classes_hudicons = [[level.ex_drm]]("ex_classes_hudicons", 1, 0, 1, "int");
			level.ex_classes_headicons = [[level.ex_drm]]("ex_classes_headicons", 1, 0, 1, "int");
			level.ex_classes_statusicons = [[level.ex_drm]]("ex_classes_statusicons", 1, 0, 1, "int");
		}
		else
		{
			level.ex_classes_hudicons = 0;
			level.ex_classes_headicons = 0;
			level.ex_classes_statusicons = 0;
		}
	}
	else level.ex_classes_statusicons = 0;

	//****************************************************************************
	// rank system
	//****************************************************************************
	level.ex_ranksystem = [[level.ex_drm]]("ex_ranksystem", 0, 0, 1, "int");
	if(level.ex_ranksystem)
	{
		level.ex_rank_announce = [[level.ex_drm]]("ex_rank_announce", 1, 0, 1, "int");
		level.ex_rank_score = [[level.ex_drm]]("ex_rank_score", 0, 0, 2, "int");
		level.ex_rank_update_loadout = [[level.ex_drm]]("ex_rank_update_loadout", 1, 0, 1, "int");
		level.ex_rank_promote_nades = [[level.ex_drm]]("ex_rank_promote_nades", 1, 0, 1, "int");
		level.ex_rank_demote_nades = [[level.ex_drm]]("ex_rank_demote_nades", 1, 0, 1, "int");
		level.ex_rank_wmdtype = [[level.ex_drm]]("ex_rank_wmdtype", 1, 0, 3, "int");
		level.ex_rank_wmdspeedup = [[level.ex_drm]]("ex_rank_wmdspeedup", 0, 0, 1, "int");
		level.ex_rank_hudicons = [[level.ex_drm]]("ex_rank_hudicons", 1, 0, 2, "int");
		level.ex_rank_headicons = [[level.ex_drm]]("ex_rank_headicons", 1, 0, 1, "int");
		level.ex_rank_statusicons = [[level.ex_drm]]("ex_rank_statusicons", 2, 0, 3, "int");

		for(i = 0; i < 8; i++)
		{
			// set points required for each rank
			game["rank_" + i] = [[level.ex_drm]]("ex_rank_points_" + i, 5 * i, 0, 999, "int");

			// gun clips
			game["rank_ammo_gunclips_" + i] = [[level.ex_drm]]("ex_rank_gunclips_" + i, i, 0, 12, "int");
	
			// pistol clips
			game["rank_ammo_pistolclips_" + i]= [[level.ex_drm]]("ex_rank_pistolclips_" + i, i, 0, 12, "int");
	
			// grenades
			game["rank_ammo_grenades_" + i] = [[level.ex_drm]]("ex_rank_grenades_" + i, i, 0, 9, "int");
	
			// smoke grenades
			game["rank_ammo_smoke_grenades_" + i] = [[level.ex_drm]]("ex_rank_smoke_" + i, i, 0, 9, "int");
	
			// landmines
			game["rank_ammo_landmines_" + i] = [[level.ex_drm]]("ex_rank_landmines_" + i, i, 0, 9, "int");

			// first aid kits
			game["rank_firstaid_kits_" + i] = [[level.ex_drm]]("ex_rank_firstaid_" + i, i, 0, 9, "int");
		}
	
		// set up wmd: random
		level.ex_rank_mortar = [[level.ex_drm]]("ex_rank_mortar", 3, 0, 7, "int");
		level.ex_rank_artillery = [[level.ex_drm]]("ex_rank_artillery", 4, level.ex_rank_mortar + 1, 7, "int");
		level.ex_rank_airstrike = [[level.ex_drm]]("ex_rank_airstrike", 5, level.ex_rank_artillery + 1, 7, "int");
		level.ex_rank_special = [[level.ex_drm]]("ex_rank_special", 7, level.ex_rank_airstrike + 1, 7, "int");

		// set up wmd: allowed random
		level.ex_rank_allow_rank = [[level.ex_drm]]("ex_rank_allow_rank", 5, 0, 7, "int");
		level.ex_rank_allow_mortar = [[level.ex_drm]]("ex_rank_allow_mortar", 1, 0, 1, "int");
		level.ex_rank_allow_artillery = [[level.ex_drm]]("ex_rank_allow_artillery", 1, 0, 1, "int");
		level.ex_rank_allow_airstrike = [[level.ex_drm]]("ex_rank_allow_airstrike", 1, 0, 1, "int");
		level.ex_rank_allow_special = [[level.ex_drm]]("ex_rank_allow_special", 0, 0, 1, "int");

		// set up wmd: misc settings
		level.ex_rank_wmd_upgrade = [[level.ex_drm]]("ex_rank_wmd_upgrade", 0, 0, 1, "int");
		level.ex_rank_wmd_flare = [[level.ex_drm]]("ex_rank_wmd_flare", 0, 0, 1, "int");
		level.ex_rank_wmd_checkfriendly = [[level.ex_drm]]("ex_rank_wmd_checkfriendly", 0, 0, 1, "int");
		level.ex_rank_mortar_first = [[level.ex_drm]]("ex_rank_mortar_first", 5, 5, 1800, "int");
		level.ex_rank_mortar_next = [[level.ex_drm]]("ex_rank_mortar_next", 30, 30, 1800, "int");
		level.ex_rank_artillery_first = [[level.ex_drm]]("ex_rank_artillery_first", 5, 5, 1800, "int");
		level.ex_rank_artillery_next = [[level.ex_drm]]("ex_rank_artillery_next", 30, 30, 1800, "int");
		level.ex_rank_airstrike_first = [[level.ex_drm]]("ex_rank_airstrike_first", 5, 5, 1800, "int");
		level.ex_rank_airstrike_next = [[level.ex_drm]]("ex_rank_airstrike_next", 30, 30, 1800, "int");
		level.ex_rank_airstrike_planes = [[level.ex_drm]]("ex_rank_airstrike_planes", 0, 0, 5, "int");
		level.ex_rank_airstrike_alert = [[level.ex_drm]]("ex_rank_airstrike_alert", 1, 0, 1, "int");
		level.ex_rank_napalm_chance = [[level.ex_drm]]("ex_rank_napalm_chance", 50, 1, 100, "int");
		level.ex_rank_gunship_first = [[level.ex_drm]]("ex_rank_gunship_first", 5, 5, 1800, "int");
		level.ex_rank_gunship_next = [[level.ex_drm]]("ex_rank_gunship_next", 60, 0, 1800, "int");
		if(level.ex_rank_gunship_next > 0 && level.ex_rank_gunship_next < 30) level.ex_rank_gunship_next = 30;

		mortar_radius = [[level.ex_drm]]("ex_rank_mortar_radius", 2, 1, 3, "int");
		switch(mortar_radius)
		{
			case 1:	radius = 1000; break;
			case 2: radius = 750; break;
			default: radius = 500; break;
		}
		level.ex_rank_mortar_radius = radius;

		artillery_radius = [[level.ex_drm]]("ex_rank_artillery_radius", 2, 1, 3, "int");
		switch(artillery_radius)
		{
			case 1:	radius = 1000; break;
			case 2: radius = 750; break;
			default: radius = 500; break;
		}
		level.ex_rank_artillery_radius = radius;

		airstrike_radius = [[level.ex_drm]]("ex_rank_airstrike_radius", 2, 1, 3, "int");
		switch(airstrike_radius)
		{
			case 1:	radius = 1000; break;
			case 2: radius = 750; break;
			default: radius = 500; break;
		}
		level.ex_rank_airstrike_radius = radius;
	}

	//****************************************************************************
	// nade monitor
	//****************************************************************************
	level.ex_nademon_warn = [[level.ex_drm]]("ex_nademon_warn", 15, 0, 31, "int");

	level.ex_nademon_throwback = [[level.ex_drm]]("ex_nademon_throwback", 0, 0, 31, "int");
	level.ex_nademon_throwback_indicator = [[level.ex_drm]]("ex_nademon_throwback_indicator", 20, 0, 50, "int") * 12;
	if(level.ex_nademon_throwback_indicator && level.ex_nademon_throwback_indicator < 5) level.ex_nademon_throwback_indicator = 5;
	level.ex_nademon_throwback_pickup = [[level.ex_drm]]("ex_nademon_throwback_pickup", 5, 1, 10, "int") * 12;
	level.ex_nademon_throwback_team = [[level.ex_drm]]("ex_nademon_throwback_team", 1, 0, 1, "int");
	level.ex_nademon_throwback_time = [[level.ex_drm]]("ex_nademon_throwback_time", 3.0, 1.0, 5.0, "float");

	level.ex_nademon_frag = [[level.ex_drm]]("ex_nademon_frag", 0, 0, 99, "int");
	level.ex_nademon_frag_eoc = [[level.ex_drm]]("ex_nademon_frag_eoc", 0, 0, 1, "int");
	level.ex_nademon_frag_cpx = [[level.ex_drm]]("ex_nademon_frag_cpx", 10, 0, 100, "int") * 12;
	if(level.ex_nademon_frag)
	{
		level.ex_nademon_frag_maxwarn = [[level.ex_drm]]("ex_nademon_frag_maxwarn", 1, 0, 1, "int");
		level.ex_nademon_frag_duramod = [[level.ex_drm]]("ex_nademon_frag_duramod", 100, 1, 200, "int");
	}

	level.ex_nademon_satchel = [[level.ex_drm]]("ex_nademon_satchel", 0, 0, 99, "int");
	level.ex_nademon_satchel_eoc = [[level.ex_drm]]("ex_nademon_satchel_eoc", 0, 0, 1, "int");
	level.ex_nademon_satchel_cpx = [[level.ex_drm]]("ex_nademon_satchel_cpx", 10, 0, 100, "int") * 12;
	if(level.ex_nademon_satchel)
	{
		level.ex_nademon_satchel_maxwarn = [[level.ex_drm]]("ex_nademon_satchel_maxwarn", 1, 0, 1, "int");
		level.ex_nademon_satchel_duramod = [[level.ex_drm]]("ex_nademon_satchel_duramod", 100, 1, 200, "int");
	}

	level.ex_nademon_smoke = [[level.ex_drm]]("ex_nademon_smoke", 0, 0, 99, "int");
	if(level.ex_nademon_smoke)
	{
		level.ex_nademon_smoke_maxwarn = [[level.ex_drm]]("ex_nademon_smoke_maxwarn", 1, 0, 1, "int");
		level.ex_nademon_smoke_duramod = [[level.ex_drm]]("ex_nademon_smoke_duramod", 100, 1, 200, "int");
	}

	level.ex_nademon_fire = [[level.ex_drm]]("ex_nademon_fire", 0, 0, 99, "int");
	if(level.ex_nademon_fire)
	{
		level.ex_nademon_fire_maxwarn = [[level.ex_drm]]("ex_nademon_fire_maxwarn", 1, 0, 1, "int");
		level.ex_nademon_fire_duramod = [[level.ex_drm]]("ex_nademon_fire_duramod", 100, 1, 200, "int");
	}

	level.ex_nademon_gas = [[level.ex_drm]]("ex_nademon_gas", 0, 0, 99, "int");
	if(level.ex_nademon_gas)
	{
		level.ex_nademon_gas_maxwarn = [[level.ex_drm]]("ex_nademon_gas_maxwarn", 1, 0, 1, "int");
		level.ex_nademon_gas_duramod = [[level.ex_drm]]("ex_nademon_gas_duramod", 100, 1, 200, "int");
	}

	//****************************************************************************
	// tripwires
	//****************************************************************************
	level.ex_tweapon = [[level.ex_drm]]("ex_tripwire", 0, 0, 3, "int");
	if(level.ex_tweapon)
	{
		level.ex_tweapon_defuse = [[level.ex_drm]]("ex_tripwire_defuse", 3, 0, 4, "int");
		level.ex_tweapon_limit = [[level.ex_drm]]("ex_tripwire_limit", 5, 1, 10, "int");
		level.ex_tweapon_warning = [[level.ex_drm]]("ex_tripwire_warning", 0, 0, 1, "int");
		level.ex_tweapon_radius = 12 * [[level.ex_drm]]("ex_tripwire_radius", 12, 1, 999, "int");
		level.ex_tweapon_htime = [[level.ex_drm]]("ex_tripwire_holdtime", 30, 20, 100, "int");
		level.ex_tweapon_ptime = [[level.ex_drm]]("ex_tripwire_planttime", 5, 1, 30, "int");
		level.ex_tweapon_dtime = [[level.ex_drm]]("ex_tripwire_defusetime", 5, 1, 30, "int");
		level.ex_tweapon_cpx = [[level.ex_drm]]("ex_tripwire_cpx", 10, 0, 100, "int") * 12;
	}

	//****************************************************************************
	// distance check profiles
	//****************************************************************************
	mindist_landmines = [[level.ex_drm]]("ex_mindist_landmines", "150,150,150,150", "", "", "string");
	mindist_perks = [[level.ex_drm]]("ex_mindist_perks", "150,150,150,150", "", "", "string");
	mindist_tripwires = [[level.ex_drm]]("ex_mindist_tripwires", "150,150,150,150", "", "", "string");
	mindist_turrets = [[level.ex_drm]]("ex_mindist_turrets", "150,150,150,150", "", "", "string");

	level.ex_mindist["landmines"] = extreme\_ex_utils::strToIntArray(mindist_landmines, 150);
	level.ex_mindist["perks"] = extreme\_ex_utils::strToIntArray(mindist_perks, 150);
	level.ex_mindist["tripwires"] = extreme\_ex_utils::strToIntArray(mindist_tripwires, 150);
	level.ex_mindist["turrets"] = extreme\_ex_utils::strToIntArray(mindist_turrets, 150);

	//****************************************************************************
	// taunts
	//****************************************************************************
	level.ex_taunts = [[level.ex_drm]]("ex_taunts", 0, 0, 3, "int");
	
	//****************************************************************************
	// quick message spam delay
	//****************************************************************************
	level.ex_antispam = [[level.ex_drm]]("ex_antispam", 10, 0, 30, "int");

	//****************************************************************************
	// blood on screen
	//****************************************************************************
	level.ex_bloodonscreen = [[level.ex_drm]]("ex_bloodonscreen", 0, 0, 1, "int");

	//****************************************************************************
	// livestats
	//****************************************************************************
	level.ex_livestats = [[level.ex_drm]]("ex_livestats", 0, 0, 1, "int");

	//****************************************************************************
	// duplicate name check
	//****************************************************************************
	level.ex_namechecker = [[level.ex_drm]]("ex_namechecker", 1, 0, 1, "int");
	if(level.ex_namechecker) level.ex_ncskipwarning = [[level.ex_drm]]("ex_ncskipwarning", 1, 0, 1, "int");

	//****************************************************************************
	// damage modifiers
	//****************************************************************************
	level.ex_wdmodon = [[level.ex_drm]]("ex_wdmodon", 0, 0, 1, "int");

	//****************************************************************************
	// announcer: time and score
	//****************************************************************************
	level.ex_announcer = [[level.ex_drm]]("ex_announcer", 1, 0, 2, "int");
	if(level.ex_announcer)
	{
		level.ex_announcer_time = [[level.ex_drm]]("ex_announcer_time", 1, 0, 1, "int");
		level.ex_announcer_score = [[level.ex_drm]]("ex_announcer_score", 0, 0, 1, "int");
	}

	//****************************************************************************
	// announcer: firstblood, player connect, player disconnect
	//****************************************************************************
	level.ex_fbannounce = true;
	level.ex_firstblood = [[level.ex_drm]]("ex_firstblood", 1, 0, 1, "int");
	level.ex_plcdmsg = [[level.ex_drm]]("ex_plcdmsg", 1, 0, 1, "int");
	level.ex_plcdsound = [[level.ex_drm]]("ex_plcdsound", 0, 0, 1, "int");

	//****************************************************************************
	// goodluck sound
	//****************************************************************************
	level.ex_goodluck = [[level.ex_drm]]("ex_goodluck", 1, 0, 1, "int");

	//****************************************************************************
	// HUD indicators
	//****************************************************************************
	level.ex_deathicons = [[level.ex_drm]]("ex_deathicons", 0, 0, 1, "int");
	level.ex_grenadeind = [[level.ex_drm]]("ex_grenadeind", 0, 0, 1, "int");
	level.ex_objindicator = [[level.ex_drm]]("ex_objindicator", 1, 0, 1, "int");

	//****************************************************************************
	// kamikaze (suicide bombings)
	//****************************************************************************
	level.ex_kamikaze = [[level.ex_drm]]("ex_kamikaze", 0, 0, 1, "int");
	if(level.ex_kamikaze)
	{
		level.ex_kamikaze_frag_radius = [[level.ex_drm]]("ex_kamikaze_frag_radius", 300, 100, 10000, "int");
		level.ex_kamikaze_frag_damage = [[level.ex_drm]]("ex_kamikaze_frag_damage", 200, 1, 999, "int");
		level.ex_kamikaze_satchel_radius = [[level.ex_drm]]("ex_kamikaze_satchel_radius", 500, 100, 10000, "int");
		level.ex_kamikaze_satchel_damage = [[level.ex_drm]]("ex_kamikaze_satchel_damage", 200, 1, 999, "int");
	}

	//****************************************************************************
	// fix corrupt map rotations
	//****************************************************************************
	level.ex_fixmaprotation = [[level.ex_cvardef]]("ex_fix_maprotation", 0, 0, 1, "int");

	//****************************************************************************
	// random map rotation
	//****************************************************************************
	level.ex_randommaprotation = [[level.ex_cvardef]]("ex_random_maprotation", 0, 0, 1, "int");

	//****************************************************************************
	// player based map rotation
	//****************************************************************************
	level.ex_pbrotate = [[level.ex_cvardef]]("ex_pbrotate", 0, 0, 1, "int");

	//***************************************************************************
	// callvote delay
	//***************************************************************************
	level.ex_callvote_mode = [[level.ex_drm]]("ex_callvote_mode", 3, 0, 4, "int");
	if(level.ex_callvote_mode)
	{
		level.ex_callvote_delay_players = [[level.ex_drm]]("ex_callvote_delay_players", 0, 0, 64, "int");
		level.ex_callvote_delay = [[level.ex_drm]]("ex_callvote_delay", 60, 0, 9999, "int");
		level.ex_callvote_enable_time = [[level.ex_drm]]("ex_callvote_enable_time", 120, 30, 9999, "int");
		level.ex_callvote_disable_time = [[level.ex_drm]]("ex_callvote_disable_time", 300, 60, 9999, "int");
		level.ex_callvote_msg = [[level.ex_drm]]("ex_callvote_msg", 3, 0, 3, "int");
	}

	//****************************************************************************
	// message of the day
	//****************************************************************************
	level.ex_motdrotate = [[level.ex_drm]]("ex_motd_rotate", 1, 0, 1, "int");
	if(level.ex_motdrotate)
	{
		for(i = 1; i <= 10; i++)
		{
			msg = [[level.ex_drm]]("ex_motd" + i, "", "", "", "string");
			if(msg == "") break;
			if(!isDefined(level.rotmotd)) level.rotmotd = [];
			level.rotmotd[level.rotmotd.size] = msg;
		}
		if(!isDefined(level.rotmotd) || !level.rotmotd.size) level.ex_motdrotate = 0;
			else level.ex_motdrotdelay = [[level.ex_drm]]("ex_motd_delay", 3, 3, 60, "int");
	}

	//****************************************************************************
	// spawn protection
	//****************************************************************************
	level.ex_spwn_time = [[level.ex_drm]]("ex_protection_time", 5, 0, 60, "int");
	if(level.ex_spwn_time)
	{
		level.ex_spwn_range = [[level.ex_drm]]("ex_protection_range", 50, 0, 999, "int") * 12;
		level.ex_spwn_hud = [[level.ex_drm]]("ex_protection_hud", 2, 0, 2, "int");
		level.ex_spwn_headicon = [[level.ex_drm]]("ex_protection_headicon", 0, 0, 1, "int");
		level.ex_spwn_headicon_color = [[level.ex_drm]]("ex_protection_headicon_color", 2, 0, 4, "int");
		level.ex_spwn_headicon_size = [[level.ex_drm]]("ex_protection_headicon_size", 2, 0, 5, "int");
		level.ex_spwn_punish_self = [[level.ex_drm]]("ex_protection_punish_self", 0, 0, 1, "int");
		level.ex_spwn_punish_attacker = [[level.ex_drm]]("ex_protection_punish_attacker", 0, 0, 1, "int");
		level.ex_spwn_punish_threshold = [[level.ex_drm]]("ex_protection_threshold", 0, 0, 999, "int");
		level.ex_spwn_punish_threshold_reset = [[level.ex_drm]]("ex_protection_threshold_reset", 0, 0, 1, "int");
		level.ex_spwn_wepdisable = [[level.ex_drm]]("ex_protection_weapon_disable", 0, 0, 1, "int");
		level.ex_spwn_invisible = [[level.ex_drm]]("ex_protection_invisible", 0, 0, 1, "int");
		level.ex_spwn_msg = [[level.ex_drm]]("ex_protection_msg", 1, 0, 2, "int");

		switch(level.ex_spwn_headicon_color)
		{
			case 0: headicon_protect_color = "_w"; break; // white
			case 1: headicon_protect_color = "_y"; break; // yellow
			case 2: headicon_protect_color = "_g"; break; // green
			case 3: headicon_protect_color = "_b"; break; // brown
			default: headicon_protect_color = "_r"; break; // red
		}

		switch(level.ex_spwn_headicon_size)
		{
			case 0: headicon_protect_size = "_t"; break; // tiny
			case 1: headicon_protect_size = "_s"; break; // small
			case 2: headicon_protect_size = "_m"; break; // medium
			case 3: headicon_protect_size = "_l"; break; // large
			case 4: headicon_protect_size = "_x"; break; // xl cross
			default: headicon_protect_size = "_i"; break; // xl image (shield)
		}

		game["headicon_protect"] = "gfx/hud/hud@sp_cross" + headicon_protect_color + headicon_protect_size + ".tga";
	}

	//****************************************************************************
	// server message system
	//****************************************************************************
	level.ex_svrmsg = [[level.ex_drm]]("ex_svrmsg", 0, 0, 20, "int");
	if(level.ex_svrmsg)
	{
		level.ex_svrmsg_loop = [[level.ex_drm]]("ex_svrmsg_loop", 1, 0, 1, "int");
		level.ex_svrmsg_delay_msg = [[level.ex_drm]]("ex_svrmsg_delay_msg", 30, 1, 60, "int");
		level.ex_svrmsg_delay_main = [[level.ex_drm]]("ex_svrmsg_delay_main", 60, 60, 900, "int");
		level.ex_svrmsg_info = [[level.ex_drm]]("ex_svrmsg_info", 0, 0, 3, "int");
		level.ex_svrmsg_rotation = [[level.ex_drm]]("ex_svrmsg_rotation", 0, 0, 1, "int");
	}

	//****************************************************************************
	// active server rules
	//****************************************************************************
	level.ex_svrrules = [[level.ex_drm]]("ex_svrrules", "", "" , "", "string");

	//****************************************************************************
	// clan configuration
	//****************************************************************************
	level.ex_cltag = [];
	level.ex_clvote = [];
	level.ex_clspec = [];
	level.ex_clano = [];

	level.ex_cltag[1] = [[level.ex_drm]]("ex_clantag1", "clantag1", "" , "", "string");
	level.ex_clvote[1] = [[level.ex_drm]]("ex_clantag1_vote", 1, 0, 1, "int");
	level.ex_clspec[1] = [[level.ex_drm]]("ex_clantag1_spec", 1, 0, 1, "int");
	level.ex_clano[1] = [[level.ex_drm]]("ex_clantag1_announce", 1, 0, 1, "int");
	level.ex_clmsg[1] = [[level.ex_drm]]("ex_clantag1_msg", 0, 0, 3, "int");

	level.ex_cltag[2] = [[level.ex_drm]]("ex_clantag2", "clantag2", "" , "", "string");
	level.ex_clvote[2] = [[level.ex_drm]]("ex_clantag2_vote", 1, 0, 1, "int");
	level.ex_clspec[2] = [[level.ex_drm]]("ex_clantag2_spec", 1, 0, 1, "int");
	level.ex_clano[2] = [[level.ex_drm]]("ex_clantag2_announce", 1, 0, 1, "int");
	level.ex_clmsg[2] = [[level.ex_drm]]("ex_clantag2_msg", 0, 0, 3, "int");

	level.ex_cltag[3] = [[level.ex_drm]]("ex_clantag3", "clantag3", "" , "", "string");
	level.ex_clvote[3] = [[level.ex_drm]]("ex_clantag3_vote", 1, 0, 1, "int");
	level.ex_clspec[3] = [[level.ex_drm]]("ex_clantag3_spec", 1, 0, 1, "int");
	level.ex_clano[3] = [[level.ex_drm]]("ex_clantag3_announce", 1, 0, 1, "int");
	level.ex_clmsg[3] = [[level.ex_drm]]("ex_clantag3_msg", 0, 0, 3, "int");

	level.ex_cltag[4] = [[level.ex_drm]]("ex_clantag4", "clantag4", "" , "", "string");
	level.ex_clvote[4] = [[level.ex_drm]]("ex_clantag4_vote", 1, 0, 1, "int");
	level.ex_clspec[4] = [[level.ex_drm]]("ex_clantag4_spec", 1, 0, 1, "int");
	level.ex_clano[4] = [[level.ex_drm]]("ex_clantag4_announce", 1, 0, 1, "int");
	level.ex_clmsg[4] = [[level.ex_drm]]("ex_clantag4_msg", 0, 0, 3, "int");

	// clan voting
	level.ex_clanvoting = [[level.ex_drm]]("ex_clanvoting", 0, 0, 1, "int");

	// clan voting ensure voting is enabled
	if(level.ex_clanvoting) setCvar("g_allowvote", 1);

	// clan spectating
	level.ex_clanspectating = [[level.ex_drm]]("ex_clanspectating", 0, 0, 1, "int");

	// clan PIN identification
	level.ex_clanlogin = [[level.ex_drm]]("ex_clanlogin", 0, 0, 1, "int");
	if(level.ex_clanlogin) level.ex_clanlogin_pin = [[level.ex_drm]]("ex_clanlogin_pin", "1234", "", "", "string");

	// clan member welcome messages
	level.ex_clanwelcome = [[level.ex_drm]]("ex_clanwelcome", 0, 0, 1, "int");
	level.ex_clandelay = [[level.ex_drm]]("ex_clanmsgdelay", 1, 0.05, 10, "float");

	// clan1 team balancing exclusion
	level.ex_clantag1_nobalance = [[level.ex_drm]]("ex_clantag1_nobalance", 0, 0, 1, "int");

	// clan member checker system
	level.ex_checkmembers = [[level.ex_drm]]("ex_checkmembers", 0, 0, 4, "int");

	//****************************************************************************
	// non clan configuration - player welcome
	//****************************************************************************
	level.ex_pwelcome = [[level.ex_drm]]("ex_pwelcome", 0, 0, 1, "int");
	level.ex_pwelcome_all = [[level.ex_drm]]("ex_pwelcome_all", 2, 0, 10, "int");
	level.ex_pwelcome_msg = [[level.ex_drm]]("ex_pwelcome_msg", 0, 0, 3, "int");
	level.ex_pwelcome_delay = [[level.ex_drm]]("ex_pwelcome_delay", 2, 0, 10, "int");

	//****************************************************************************
	// force auto-assign and clan vs non-clan mode
	// WARNING: NEEDS TO BE BELOW THE CLAN VARS!
	//****************************************************************************
	if(getCvar("ex_clanvsnonclan") == "") level.ex_clanvsnonclan = extreme\_ex_drm::drm_getCvarInt("ex_clanvsnonclan");
		else level.ex_clanvsnonclan = getCvarInt("ex_clanvsnonclan");

	if(level.ex_clanvsnonclan == 2) level.ex_clanvsnonclan = 1; // RCON: on (next map)
		else if(level.ex_clanvsnonclan == 3) level.ex_clanvsnonclan = 0; // RCON: off (next map)
			else if(level.ex_clanvsnonclan < 0 || level.ex_clanvsnonclan > 3) level.ex_clanvsnonclan = 0;
	if(!level.ex_teamplay) level.ex_clanvsnonclan = 0;
	level.ex_clanvsnonclan_msg = [[level.ex_drm]]("ex_clanvsnonclan_msg", 4, 0, 5, "int");

	setCvar("ex_clanvsnonclan", level.ex_clanvsnonclan);

	level.ex_autoassign = [[level.ex_drm]]("ex_autoassign", 0, 0, 2, "int");
	level.ex_autoassign_org = level.ex_autoassign;
	level.ex_autoassign_bridge = [[level.ex_drm]]("ex_autoassign_bridge", 0, 0, 1, "int");

	if(level.ex_clanvsnonclan)
	{
		level thread maps\mp\gametypes\_teams::monitorClanVersusNonclan();
		level.ex_autoassign = 2;
		level.ex_autoassign_bridge = 1;
		level.ex_clanmodemsg = &"MISC_CLANVSNONCLAN";
		[[level.ex_PrecacheString]](level.ex_clanmodemsg);
	}

	level.ex_autoassign_clanteam = toLower( [[level.ex_drm]]("ex_autoassign_clanteam", "allies", "", "", "string") );
	if(level.ex_autoassign_clanteam != "allies" && level.ex_autoassign_clanteam != "axis")
		level.ex_autoassign_clanteam = "allies";
	if(level.ex_autoassign_clanteam == "allies") level.ex_autoassign_nonclanteam = "axis";
		else level.ex_autoassign_nonclanteam = "allies";

	if(level.ex_teamplay && (level.ex_clanvsnonclan || (level.ex_autoassign == 2 && level.ex_autoassign_bridge)))
	{
		level.teambalance = 0;
		setCvar("scr_teambalance", level.teambalance);
	}

	//****************************************************************************
	// jump height
	//****************************************************************************
	setCvar("jump_height", [[level.ex_drm]]("ex_jumpheight", 39, 0, 128, "int"));

	//****************************************************************************
	// fall damage
	//****************************************************************************
	if([[level.ex_drm]]("ex_falldamage_enable", 0, 0, 1, "int"))
	{
		minfalldamage = [[level.ex_drm]]("ex_falldamage_min", 15, 10, 9999, "int");
		maxfalldamage = [[level.ex_drm]]("ex_falldamage_max", 30, minfalldamage, 9999, "int");
		setcvar("bg_fallDamageMaxHeight", maxfalldamage * 12);
		setcvar("bg_fallDamageMinHeight", minfalldamage * 12);
	}

	//****************************************************************************
	// mod info, clan info and clan logo
	//****************************************************************************
	// mod info (bottom-right corner)
	level.ex_clantext = [[level.ex_drm]]("ex_clan_txt", 1, 0, 1, "int");
	level.ex_modtext = [[level.ex_drm]]("ex_mod_txt", 1, 0, 1, "int");

	// custom clan logo variables (mylogo)
	level.ex_mylogo = [[level.ex_drm]]("ex_mylogo", 1, 0, 1, "int");
	if(level.ex_mylogo)
	{
		level.ex_mylogo_posx = [[level.ex_drm]]("ex_mylogo_posx", 20, 0, 640, "int");
		level.ex_mylogo_posy = [[level.ex_drm]]("ex_mylogo_posy", 20, 0, 480, "int");
		level.ex_mylogo_sizex = [[level.ex_drm]]("ex_mylogo_sizex", 128, 0, 512, "int");
		level.ex_mylogo_sizey = [[level.ex_drm]]("ex_mylogo_sizey", 128, 0, 512, "int");
		level.ex_mylogo_transp = [[level.ex_drm]]("ex_mylogo_transp", 0, 0, 9, "int");
		level.ex_mylogo_looptime = [[level.ex_drm]]("ex_mylogo_looptime", 300, 0, 3600, "int");
		if(level.ex_mylogo_looptime > 0 && level.ex_mylogo_looptime < 10) level.ex_mylogo_looptime = 10;
		level.ex_mylogo_fadewait = [[level.ex_drm]]("ex_mylogo_fadewait", 10, 1, 3600, "int");
		if(level.ex_mylogo_fadewait > level.ex_mylogo_looptime) level.ex_mylogo_fadewait = level.ex_mylogo_looptime - 5;
	}

	//****************************************************************************
	// team killer detection (sinbin)
	//****************************************************************************
	level.ex_sinbin = [[level.ex_drm]]("ex_tksystem", 0, 0, 1, "int");
	if(level.ex_sinbin)
	{
		level.ex_sinbinmaxtk = [[level.ex_drm]]("ex_tkmax", 1, 1, 10, "int");
		level.ex_sinfrztime = [[level.ex_drm]]("ex_tktime", 5, 1, 60, "int");
		level.ex_sinbinmsg = [[level.ex_drm]]("ex_tkmsg", 1, 0, 2, "int");
	}

	//****************************************************************************
	// rotate is empty
	//****************************************************************************
	level.ex_rotateifempty = [[level.ex_cvardef]]("ex_rotate_if_empty", 15, 0, 1440, "int");
	if(game["timelimit"] > 1 && level.ex_rotateifempty >= game["timelimit"]) level.ex_rotateifempty = game["timelimit"] - 1;

	//****************************************************************************
	// laserdot
	//****************************************************************************
	level.ex_laserdot = [[level.ex_drm]]("ex_laserdot", 0, 0, 3, "int");
	if(level.ex_laserdot)
	{
		level.ex_laserdotsize = [[level.ex_drm]]("ex_laserdot_size", 2, 1, 10, "int");
		level.ex_laserdotred = [[level.ex_drm]]("ex_laserdot_red", 1, 0, 1, "float");
		level.ex_laserdotgreen = [[level.ex_drm]]("ex_laserdot_green", 0, 0, 1, "float");
		level.ex_laserdotblue = [[level.ex_drm]]("ex_laserdot_blue", 0, 0, 1, "float");
	}

	//****************************************************************************
	// black screen on death
	//****************************************************************************
	level.ex_bsod = [[level.ex_drm]]("ex_bsod", 0, 0, 4, "int");
	if(level.ex_bsod) level.ex_bsod_blockmenu = [[level.ex_drm]]("ex_bsod_blockmenu", 1, 0, 1, "int");

	//****************************************************************************
	// killing spree and obituary system
	//****************************************************************************
	level.ex_obituary = [[level.ex_drm]]("ex_obituary", 8, 0, 8, "int");
	if(level.ex_obituary)
	{
		level.ex_obitrange = [[level.ex_drm]]("ex_obitrange", 2, 0, 2, "int");
		level.ex_obitunit = [[level.ex_drm]]("ex_obitunit", 1, 0, 1, "int");
	}

	level.ex_obituary_streakinfo = [[level.ex_drm]]("ex_obituary_streakinfo", 0, 0, 2, "int");
	level.ex_obitladder = [[level.ex_drm]]("ex_obitladder", 1, 0, 1, "int");
	if(level.ex_obitladder)
	{
		laddermin = 1;
		laddermax = 5;
		level.ex_obitladder_2 = [[level.ex_drm]]("ex_obitladder_2", 3, laddermin, laddermax, "float");
		laddermin = level.ex_obitladder_2 + 0.5;
		laddermax = level.ex_obitladder_2 + 5;
		level.ex_obitladder_3 = [[level.ex_drm]]("ex_obitladder_3", 4.5, laddermin, laddermax, "float");
		laddermin = level.ex_obitladder_3 + 0.5;
		laddermax = level.ex_obitladder_3 + 5;
		level.ex_obitladder_4 = [[level.ex_drm]]("ex_obitladder_4", 6, laddermin, laddermax, "float");
		laddermin = level.ex_obitladder_4 + 0.5;
		laddermax = level.ex_obitladder_4 + 5;
		level.ex_obitladder_5 = [[level.ex_drm]]("ex_obitladder_5", 7.5, laddermin, laddermax, "float");
		laddermin = level.ex_obitladder_5 + 0.5;
		laddermax = level.ex_obitladder_5 + 5;
		level.ex_obitladder_6 = [[level.ex_drm]]("ex_obitladder_6", 9, laddermin, laddermax, "float");
		laddermin = level.ex_obitladder_6 + 0.5;
		laddermax = level.ex_obitladder_6 + 5;
		level.ex_obitladder_7 = [[level.ex_drm]]("ex_obitladder_7", 10.5, laddermin, laddermax, "float");
		laddermin = level.ex_obitladder_7 + 0.5;
		laddermax = level.ex_obitladder_7 + 5;
		level.ex_obitladder_8 = [[level.ex_drm]]("ex_obitladder_8", 12, laddermin, laddermax, "float");
		laddermin = level.ex_obitladder_8 + 0.5;
		laddermax = level.ex_obitladder_8 + 5;
		level.ex_obitladder_9 = [[level.ex_drm]]("ex_obitladder_9", 13.5, laddermin, laddermax, "float");
	}

	//****************************************************************************
	// hit, pain and death sounds
	//****************************************************************************
	level.ex_hitblip = [[level.ex_drm]]("ex_hitblip", 1, 0, 1, "int");
	level.ex_hitsound = [[level.ex_drm]]("ex_hitsound", 0, 0, 1, "int");
	level.ex_painsound = [[level.ex_drm]]("ex_painsound", 1, 0, 1, "int");
	level.ex_deathsound = [[level.ex_drm]]("ex_deathsound", 1, 0, 1, "int");

	//****************************************************************************
	// realism options
	//****************************************************************************
	level.ex_droponarmhit = [[level.ex_drm]]("ex_droponarmhit", 0, 0, 100, "int");
	level.ex_droponhandhit = [[level.ex_drm]]("ex_droponhandhit", 0, 0, 100, "int");
	level.ex_droponfall = [[level.ex_drm]]("ex_droponfall", 0, 0, 100, "int");

	//****************************************************************************
	// health bar, health regen and medic system
	//****************************************************************************
	level.ex_healthbar = [[level.ex_drm]]("ex_healthbar", 1, 0, 2, "int");
	level.ex_healthregen = [[level.ex_drm]]("ex_healthregen", 0, 0, 1, "int");
	level.ex_healthregen_delay = [[level.ex_drm]]("ex_healthregen_delay", 5000, 0, 99999, "int");
	level.ex_healthregen_rate = [[level.ex_drm]]("ex_healthregen_rate", 10, 1, 20, "int");
	level.ex_healthregen_heavybreathing = [[level.ex_drm]]("ex_healthregen_heavybreathing", 1, 0, 1, "int");
	level.ex_healthregen_heavybreathing_cutoff = [[level.ex_drm]]("ex_healthregen_heavybreathing_cutoff", 75, 1, 100, "int");

	level.ex_medicsystem = [[level.ex_drm]]("ex_medicsystem", 2, 0, 2, "int");
	if(level.ex_medicsystem)
	{
		level.ex_medic_self = [[level.ex_drm]]("ex_medic_self", 1, 0, 1, "int");
		level.ex_medic_callout = [[level.ex_drm]]("ex_medic_callout", 40, 0, 100, "float");
		level.ex_medic_minheal = [[level.ex_drm]]("ex_medic_minheal", 40, 1, 99, "int");
		level.ex_medic_maxheal = [[level.ex_drm]]("ex_medic_maxheal", 100, level.ex_medic_minheal + 1, 100, "int");
		level.ex_medic_showinjured = [[level.ex_drm]]("ex_medic_showinjured", 0, 0, 1, "int");
		level.ex_medic_showinjured_time = [[level.ex_drm]]("ex_medic_showinjured_time", 3, 3, 60, "float");
		level.ex_medic_penalty = [[level.ex_drm]]("ex_medic_penalty", 30, 0, 60, "int");
		if(level.ex_medic_penalty && level.ex_medic_penalty < 10) level.ex_medic_penalty = 10;
		level.ex_medic_penalty_msg = [[level.ex_drm]]("ex_medic_penalty_msg", 1, 0, 1, "int");

		level.ex_firstaid_kits = [[level.ex_drm]]("ex_firstaid_kits", 1, 1, 9, "int");
		level.ex_firstaid_kits_random = [[level.ex_drm]]("ex_firstaid_kits_random", 0, 0, 1, "int");
		level.ex_firstaid_kits_msg = [[level.ex_drm]]("ex_firstaid_kits_msg", 0, 0, 1, "int");
		level.ex_firstaid_collect = [[level.ex_drm]]("ex_firstaid_collect", 0, 0, 9, "int");
		level.ex_firstaid_drop = [[level.ex_drm]]("ex_firstaid_drop", 1, 0, 2, "int");
	}

	// if using the stock COD2 health system turn off the bleeding sounds
	if(level.ex_bleeding && level.ex_healthregen) level.ex_bleedsound = false;

	//****************************************************************************
	// anti-camper system
	//****************************************************************************
	level.ex_campwarntime = [[level.ex_drm]]("ex_campwarntime", 0, 0, 300, "int");
	if(level.ex_campwarntime)
	{
		if(level.ex_campwarntime && level.ex_campwarntime < 10) level.ex_campwarntime = 10;
		level.ex_campradius = [[level.ex_drm]]("ex_campradius", 10, 5, 100, "int") * 12;
		level.ex_campobjtime = [[level.ex_drm]]("ex_campobjtime", level.ex_campwarntime+10, level.ex_campwarntime+5, 600, "int");
	}

	level.ex_campsniper_warntime = [[level.ex_drm]]("ex_campsniper_warntime", 0, 0, 600, "int");
	if(level.ex_campsniper_warntime)
	{
		if(level.ex_campsniper_warntime && level.ex_campsniper_warntime < 10) level.ex_campsniper_warntime = 10;
		level.ex_campsniper_radius = [[level.ex_drm]]("ex_campradius", 10, 5, 100, "int") * 12;
		level.ex_campsniper_objtime = [[level.ex_drm]]("ex_campsniper_objtime", level.ex_campsniper_warntime+10, level.ex_campsniper_warntime+5, 1200, "int");
	}

	if(level.ex_campwarntime || level.ex_campsniper_warntime)
	{
		level.ex_camppunish = [[level.ex_drm]]("ex_camp_punish", 0, 0, 4, "int");
		level.ex_camptimer = [[level.ex_drm]]("ex_camptimer", 20, 0, 300, "int");
	}

	//****************************************************************************
	// weapon system
	//****************************************************************************
	// all weapons for all teams
	level.ex_all_weapons = [[level.ex_drm]]("ex_all_weapons", 0, 0, 1, "int");

	// modern Weapons
	level.ex_modern_weapons = [[level.ex_drm]]("ex_modern_weapons", 0, 0, 1, "int");

	// bash-only mode
	level.ex_bash_only = [[level.ex_drm]]("ex_bash_only", 0, 0, 1, "int");
	level.ex_bash_only_msg = [[level.ex_drm]]("ex_bash_only_msg", 4, 0, 5, "int");

	// frag fest mode
	level.ex_frag_fest = [[level.ex_drm]]("ex_frag_fest", 0, 0, 1, "int");
	level.ex_frag_fest_msg = [[level.ex_drm]]("ex_frag_fest_msg", 4, 0, 5, "int");

	// frag grenade loadout option
	level.ex_frag_loadout = [[level.ex_drm]]("ex_frag_loadout", 2, 0, 3, "int");
	level.ex_frag_cap = [[level.ex_drm]]("ex_frag_cap", 9, 3, 9, "int");

	// option 0 - stock weapon based ammo frag grenades
	level.ex_wepo_frag_stock_sniper = [[level.ex_drm]]("ex_wepo_frag_stock_sniper", 2, 0, 9, "int");
	level.ex_wepo_frag_stock_rifle = [[level.ex_drm]]("ex_wepo_frag_stock_rifle", 2, 0, 9, "int");
	level.ex_wepo_frag_stock_mg = [[level.ex_drm]]("ex_wepo_frag_stock_mg", 2, 0, 9, "int");
	level.ex_wepo_frag_stock_smg = [[level.ex_drm]]("ex_wepo_frag_stock_smg", 2, 0, 9, "int");
	level.ex_wepo_frag_stock_shot = [[level.ex_drm]]("ex_wepo_frag_stock_shot", 2, 0, 9, "int");
	level.ex_wepo_frag_stock_rl = [[level.ex_drm]]("ex_wepo_frag_stock_rl", 2, 0, 9, "int");
	level.ex_wepo_frag_stock_ft = [[level.ex_drm]]("ex_wepo_frag_stock_ft", 2, 0, 9, "int");

	// option 2 - fixed ammo frag grenades
	level.ex_wepo_frag = [[level.ex_drm]]("ex_wepo_frag", 1, 0, 9, "int");

	// option 3 - random ammo frag grenades
	level.ex_wepo_frag_random = [[level.ex_drm]]("ex_wepo_frag_random", 1, 0, 9, "int");

	// smoke grenade loadout option
	level.ex_smoke_loadout = [[level.ex_drm]]("ex_smoke_loadout", 2, 0, 3, "int");
	level.ex_smoke_cap = [[level.ex_drm]]("ex_smoke_cap", 9, 3, 9, "int");

	// option 0 - stock weapon based ammo smoke grenades
	level.ex_wepo_smoke_stock_sniper = [[level.ex_drm]]("ex_wepo_smoke_stock_sniper", 1, 0, 9, "int");
	level.ex_wepo_smoke_stock_rifle = [[level.ex_drm]]("ex_wepo_smoke_stock_rifle", 1, 0, 9, "int");
	level.ex_wepo_smoke_stock_mg = [[level.ex_drm]]("ex_wepo_smoke_stock_mg", 1, 0, 9, "int");
	level.ex_wepo_smoke_stock_smg = [[level.ex_drm]]("ex_wepo_smoke_stock_smg", 1, 0, 9, "int");
	level.ex_wepo_smoke_stock_shot = [[level.ex_drm]]("ex_wepo_smoke_stock_shot", 1, 0, 9, "int");
	level.ex_wepo_smoke_stock_rl = [[level.ex_drm]]("ex_wepo_smoke_stock_rl", 1, 0, 9, "int");
	level.ex_wepo_smoke_stock_ft = [[level.ex_drm]]("ex_wepo_smoke_stock_ft", 1, 0, 9, "int");

	// option 2 - fixed ammo smoke grenades
	level.ex_wepo_smoke = [[level.ex_drm]]("ex_wepo_smoke", 1, 0, 9, "int");

	// option 3 - random ammo smoke grenades
	level.ex_wepo_smoke_random = [[level.ex_drm]]("ex_wepo_smoke_random", 1, 0, 9, "int");

	// weapon classes
	// 0 = all team based weapons
	// 1 = pistols only
	// 2 = sniper only
	// 3 = machine gun only
	// 4 = submachine gun only
	// 5 = rifles only
	// 6 = bolt action only
	// 7 = shotgun only
	// 8 = panzerschreck only
	// 9 = bolt-sniper only
	//10 = knives only
	level.ex_wepo_class = [[level.ex_drm]]("ex_wepo_class", 0, 0, 10, "int");
	
	// only class all weapons or team based weapons available
	level.ex_wepo_team_only = [[level.ex_drm]]("ex_wepo_team_only", 0, 0, 1, "int");

	// weapons limiter
	level.ex_wepo_limiter = [[level.ex_drm]]("ex_weaponlimit", 0, 0, 1, "int");
	if(level.ex_wepo_limiter) level.ex_wepo_limiter_perteam = [[level.ex_drm]]("ex_weaponlimit_perteam", 1, 0, 1, "int");

	// grenades with weapon class
	level.ex_wepo_allow_grenades = [[level.ex_drm]]("ex_wepo_allow_grenades", 0, 0, 3, "int");

	// set the grenades up for weapon class only
	if(level.ex_wepo_allow_grenades == 1)
	{
		level.ex_wepo_allow_frag = true;
		level.ex_wepo_allow_smoke = false;
	}
	else if(level.ex_wepo_allow_grenades == 2)
	{
		level.ex_wepo_allow_frag = false;
		level.ex_wepo_allow_smoke = true;
	}
	else if(level.ex_wepo_allow_grenades == 3)
	{
		level.ex_wepo_allow_frag = true;
		level.ex_wepo_allow_smoke = true;
	}
	else
	{
		level.ex_wepo_allow_frag = false;
		level.ex_wepo_allow_smoke = false;
	}

	// sidearm options
	level.ex_wepo_sidearm = [[level.ex_drm]]("ex_wepo_sidearm", 1, 0, 2, "int");
	level.ex_wepo_sidearm_type = [[level.ex_drm]]("ex_wepo_sidearm_type", 0, 0, 1, "int");

	// knife options
	level.ex_wepo_knife_gravity = [[level.ex_drm]]("ex_wepo_knife_gravity", 1, 0, 1, "int");
	level.ex_wepo_knife_bouncefactor = [[level.ex_drm]]("ex_wepo_knife_bouncefactor", 0.5, 0.1, 0.9, "float");

	// weapon enemy options
	level.ex_wepo_enemy = [[level.ex_drm]]("ex_wepo_enemy", 1, 0, 2, "int");
	level.ex_wepo_enemy_pct = [[level.ex_drm]]("ex_wepo_enemy_pct", 30, 0, 100, "int");

	// weapon loadout option
	level.ex_wepo_loadout = [[level.ex_drm]]("ex_wepo_loadout", 0, 0, 1, "int");

	// weapon precache option
	level.ex_wepo_precache_mode = [[level.ex_drm]]("ex_wepo_precache_mode", 0, 0, 1, "int");

	//****************************************************************************
	// weapon drop system (after death)
	//****************************************************************************
	// drop weapons
	level.ex_wepo_drop_weps = [[level.ex_drm]]("ex_wepo_drop_weps", 1, 0, 4, "int");
	level.ex_wepo_drop_sp = [[level.ex_drm]]("ex_wepo_drop_sp", 1, 0, 1, "int");
	level.allow_pistol_drop = [[level.ex_drm]]("ex_allow_pistol_drop", 1, 0, 1, "int");
	level.allow_sniper_drop = [[level.ex_drm]]("ex_allow_sniper_drop", 1, 0, 1, "int");
	level.allow_sniperlr_drop = [[level.ex_drm]]("ex_allow_sniperlr_drop", 1, 0, 1, "int");
	level.allow_mg_drop = [[level.ex_drm]]("ex_allow_mg_drop", 1, 0, 1, "int");
	level.allow_smg_drop = [[level.ex_drm]]("ex_allow_smg_drop", 1, 0, 1, "int");
	level.allow_rifle_drop = [[level.ex_drm]]("ex_allow_rifle_drop", 1, 0, 1, "int");
	level.allow_boltrifle_drop = [[level.ex_drm]]("ex_allow_boltrifle_drop", 1, 0, 1, "int");
	level.allow_boltsniper_drop = [[level.ex_drm]]("ex_allow_boltsniper_drop", 1, 0, 1, "int");
	level.allow_shotgun_drop = [[level.ex_drm]]("ex_allow_shotgun_drop", 1, 0, 1, "int");
	level.allow_rl_drop = [[level.ex_drm]]("ex_allow_rl_drop", 1, 0, 1, "int");
	level.allow_ft_drop = [[level.ex_drm]]("ex_allow_ft_drop", 1, 0, 1, "int");
	level.allow_knife_drop = [[level.ex_drm]]("ex_allow_knife_drop", 1, 0, 1, "int");

	// drop grenades
	level.ex_wepo_drop_grenades = [[level.ex_drm]]("ex_wepo_drop_grenades", 1, 0, 3, "int");

	// set up drop grenades
	if(level.ex_wepo_drop_grenades == 1)
	{
		level.ex_wepo_drop_frag = true;
		level.ex_wepo_drop_smoke = false;
	}
	else if(level.ex_wepo_drop_grenades == 2)
	{
		level.ex_wepo_drop_frag = false;
		level.ex_wepo_drop_smoke = true;
	}
	else if(level.ex_wepo_drop_grenades == 3)
	{
		level.ex_wepo_drop_frag = true;
		level.ex_wepo_drop_smoke = true;
	}
	else
	{
		level.ex_wepo_drop_frag = false;
		level.ex_wepo_drop_smoke = false;
	}

	//****************************************************************************
	// secondary weapons system
	//****************************************************************************
	level.ex_wepo_secondary = [[level.ex_drm]]("ex_wepo_secondary", 0, 0, 2, "int");

	//****************************************************************************
	// landmines
	//****************************************************************************
	level.ex_landmines = [[level.ex_drm]]("ex_landmines", 3, 0, 3, "int");
	if(level.ex_landmines)
	{
		level.ex_landmines_defuse = [[level.ex_drm]]("ex_landmines_defuse", 3, 0, 4, "int");
		level.ex_landmines_loadout = [[level.ex_drm]]("ex_landmines_loadout", 1, 0, 1, "int");
		level.ex_landmines_cap = [[level.ex_drm]]("ex_landmines_cap", 9, 3, 9, "int");
		level.ex_landmines_max = [[level.ex_drm]]("ex_landmines_max", 5, 1, 32, "int");
		level.ex_landmines_fifo = [[level.ex_drm]]("ex_landmines_fifo", 1, 0, 1, "int");
		level.ex_landmine_plant_time = [[level.ex_drm]]("ex_landmine_plant_time", 5, 3, 20, "int");
		level.ex_landmine_defuse_time = [[level.ex_drm]]("ex_landmine_defuse_time", 5, 3, 20, "int");
		level.ex_landmine_warning = [[level.ex_drm]]("ex_landmine_warning", 1, 0, 2, "int");
		level.ex_landmine_depth = [[level.ex_drm]]("ex_landmine_depth", 2, 1, 2, "int");
		level.ex_landmine_surfacecheck = [[level.ex_drm]]("ex_landmine_surfacecheck", 0, 0, 1, "int");
		level.ex_landmine_cpx = [[level.ex_drm]]("ex_landmine_cpx", 10, 0, 100, "int") * 12;
		level.ex_landmine_bb = [[level.ex_drm]]("ex_landmine_bb", 1, 0, 1, "int");
		level.ex_allow_mine_sniper = [[level.ex_drm]]("ex_allow_mine_sniper", 2, 0, 9, "int");
		level.ex_allow_mine_boltrifle = [[level.ex_drm]]("ex_allow_mine_boltrifle", 2, 0, 9, "int");
		level.ex_allow_mine_rifle = [[level.ex_drm]]("ex_allow_mine_rifle", 2, 0, 9, "int");
		level.ex_allow_mine_semiauto = [[level.ex_drm]]("ex_allow_mine_semiauto", 2, 0, 9, "int");
		level.ex_allow_mine_smg = [[level.ex_drm]]("ex_allow_mine_smg", 2, 0, 9, "int");
		level.ex_allow_mine_mg = [[level.ex_drm]]("ex_allow_mine_mg", 2, 0, 9, "int");
		level.ex_allow_mine_shotgun = [[level.ex_drm]]("ex_allow_mine_shotgun", 2, 0, 9, "int");
	}

	//****************************************************************************
	// burst mode
	//****************************************************************************
	level.ex_burst_mode = [[level.ex_drm]]("ex_burst_mode", 0, 0, 3, "int");
	if(level.ex_burst_mode)
	{
		level.ex_burst_mg = [[level.ex_drm]]("ex_burst_mg", 2.0, 1.5, 10.0, "float");
		level.ex_burst_smg = [[level.ex_drm]]("ex_burst_smg", 2.0, 1.5, 10.0, "float");
		level.ex_burst_ads = [[level.ex_drm]]("ex_burst_ads", 1, 0, 1, "int");
	}

	//****************************************************************************
	// flamethrower
	//****************************************************************************
	level.ex_ft_range = [[level.ex_drm]]("ex_ft_range", 500, 100, 750, "int");
	level.ex_ft_tank_explode = [[level.ex_drm]]("ex_ft_tank_explode", 10, 0, 100, "int");

	//****************************************************************************
	// turrets
	//****************************************************************************
	level.ex_turrets = [[level.ex_drm]]("ex_turrets", 1, 0, 3, "int");
	if(level.ex_turrets)
	{
		level.ex_turretabuse = [[level.ex_drm]]("ex_turretabuse", 0, 0, 1, "int");
		level.ex_turretabuse_warn = [[level.ex_drm]]("ex_turretabuse_warn", 5, 0, 99, "int");
		level.ex_turretabuse_kill = [[level.ex_drm]]("ex_turretabuse_kill", level.ex_turretabuse_warn+2, level.ex_turretabuse_warn+1, 100, "int");
		level.ex_turretoverheat = [[level.ex_drm]]("ex_turretoverheat", 1, 0, 1, "int");
		level.ex_turretoverheat_heatrate = [[level.ex_drm]]("ex_turretoverheat_heatrate", 2, 1, 4, "int");
		level.ex_turretoverheat_coolrate = [[level.ex_drm]]("ex_turretoverheat_coolrate", 2, 1, 4, "int");
		level.ex_turretsmax = [[level.ex_drm]]("ex_turretsmax", 6, 1, 99, "int");
	}

	//****************************************************************************
	// forced client cvars
	//****************************************************************************
	level.ex_forceclientcvars = [[level.ex_drm]]("ex_forceclientcvars", 0, 0, 3, "int");
	if(level.ex_forceclientcvars == 2)
	{
		if(getCvar("sv_disableClientConsole") != "" && getCvarInt("sv_disableClientConsole") == 1) level.ex_forceclientcvars = 3;
			else level.ex_forceclientcvars = 1;
	}
	if(level.ex_forceclientcvars)
	{
		level.ex_forceclientcvars_loop = [[level.ex_drm]]("ex_forceclientcvars_loop", 60, 10, 300, "int");
		level.ex_forcerate = [[level.ex_drm]]("ex_forcerate", 25000, 0, 25000, "int");
		if(level.ex_forcerate && level.ex_forcerate < 1000) level.ex_forcerate = 5000;
		level.ex_mantlehint = [[level.ex_drm]]("ex_mantlehint", 0, 0, 1, "int");
		level.ex_crosshair = [[level.ex_drm]]("ex_crosshair", 1, 0, 1, "int");
		level.ex_crosshairnames = [[level.ex_drm]]("ex_crosshairnames", 1, 0, 1, "int");
		level.ex_enemycross = [[level.ex_drm]]("ex_enemycross", 0, 0, 1, "int");
		level.ex_hudstance = [[level.ex_drm]]("ex_hudstance", 0, 0, 1, "int");
		level.ex_brightmodels = [[level.ex_drm]]("ex_brightmodels", 0, 0, 1, "int");
		level.ex_maxpackets = [[level.ex_drm]]("ex_maxpackets", 0, 0, 100, "int");
		if(level.ex_maxpackets && level.ex_maxpackets < 10) level.ex_maxpackets = 30;
		level.ex_maxfps = [[level.ex_drm]]("ex_maxfps", 0, 0, 300, "int");
		if(level.ex_maxfps && level.ex_maxfps < 50) level.ex_maxfps = 85;
	}

	//****************************************************************************
	// unknown soldier handling
	//****************************************************************************
	level.ex_uscheck = [[level.ex_drm]]("ex_uscheck", 1, 0, 1, "int");
	if(level.ex_uscheck)
	{
		level.ex_usclanguest = [[level.ex_drm]]("ex_usclanguest", 1, 0, 1, "int");
		level.ex_usclanguestname = [[level.ex_drm]]("ex_usclanguestname", "Guest#", "" , "", "string");
		level.ex_usguestname = [[level.ex_drm]]("ex_usguestname", "UnacceptableName#", "" , "", "string");
		level.ex_uswarndelay1 = [[level.ex_drm]]("ex_uswarndelay1", 30, 20, 60, "int");
		level.ex_uswarndelay2 = [[level.ex_drm]]("ex_uswarndelay2", 30, 20, 120, "int");
		level.ex_uspunishcount = [[level.ex_drm]]("ex_uspunishcount", 5, 1, 999, "int");
	}

	//****************************************************************************
	// sprint
	//****************************************************************************
	level.ex_sprint = [[level.ex_drm]]("ex_sprint", 1, 0, 3, "int");
	if(level.ex_sprint)
	{
		level.ex_sprint_level = [[level.ex_drm]]("ex_sprint_level", 0, 0, 4, "int");
		level.ex_sprinttime = [[level.ex_drm]]("ex_sprint_time", 3, 1, 999, "int") * 20;
		level.ex_sprintrecovertime = [[level.ex_drm]]("ex_sprint_recover_time", 2, 1, 999, "int") * 20;
		level.ex_sprinthud = [[level.ex_drm]]("ex_sprint_hud", 0, 0, 1, "int");
		level.ex_sprinthudhint = [[level.ex_drm]]("ex_sprint_hud_hint", 0, 0, 1, "int");
		level.ex_sprintheavyflag = [[level.ex_drm]]("ex_sprint_heavy_flag", 0, 0, 1, "int");
		level.ex_sprintheavyflag_rank = [[level.ex_drm]]("ex_sprint_heavy_flag_rank", 5, 0, 7, "int");
		level.ex_sprintheavymg = [[level.ex_drm]]("ex_sprint_heavy_mg", 0, 0, 1, "int");
		level.ex_sprintheavymg_rank = [[level.ex_drm]]("ex_sprint_heavy_mg_rank", 5, 0, 7, "int");
		level.ex_sprintheavypanzer = [[level.ex_drm]]("ex_sprint_heavy_panzer", 0, 0, 1, "int");
		level.ex_sprintheavypanzer_rank = [[level.ex_drm]]("ex_sprint_heavy_panzer_rank", 5, 0, 7, "int");
	}

	//****************************************************************************
	// gravity and game speed
	//****************************************************************************
	tmp_gravity = [[level.ex_drm]]("ex_gravity", 100, 0, 9999, "int");
	if(tmp_gravity != 100) setcvar("g_gravity", 8 * tmp_gravity);
	tmp_speed = [[level.ex_drm]]("ex_speed", 100, 0, 9999, "int");
	if(tmp_speed != 100) setcvar("g_speed", int(1.9 * tmp_speed));

	//****************************************************************************
	// player stats
	//****************************************************************************
	level.ex_statshud = [[level.ex_drm]]("ex_statshud", 0, 0, 1, "int");

	//****************************************************************************
	// statsboard
	//****************************************************************************
	level.ex_stbd = [[level.ex_drm]]("ex_stbd", 0, 0, 1, "int");
	if(level.ex_stbd)
	{
		level.ex_stbd_kd = [[level.ex_drm]]("ex_stbd_kd", 1, 0, 1, "int");
		level.ex_stbd_se = [[level.ex_drm]]("ex_stbd_se", 1, 0, 1, "int");
		if(!level.ex_stbd_kd && !level.ex_stbd_se) level.ex_stbd = 0;
		if(level.ex_stbd)
		{
			level.ex_stbd_time = [[level.ex_drm]]("ex_stbd_time", 30, 10, 120, "int");
			level.ex_stbd_tps = [[level.ex_drm]]("ex_stbd_tps", 0, 0, 10, "int");
			level.ex_stbd_icons = [[level.ex_drm]]("ex_stbd_icons", 0, 0, 1, "int");
			level.ex_stbd_movex = [[level.ex_drm]]("ex_stbd_movex", 150, 0, 150, "int");
			level.ex_stbd_fade = [[level.ex_drm]]("ex_stbd_fade", 0, 0, 1, "int");
			level.ex_stbd_log = [[level.ex_drm]]("ex_stbd_log", 0, 0, 1, "int");
		}
	}

	//****************************************************************************
	// ambient planes
	//****************************************************************************
	level.ex_planes = [[level.ex_drm]]("ex_planes", 0, 0, 3, "int");
	level.ex_planes_altitude = [[level.ex_drm]]("ex_planes_altitude", 6000, 0, 6000, "int");
	level.ex_planes_flak = [[level.ex_drm]]("ex_planes_flak", 1, 0, 1, "int");
	level.ex_planes_maxhealth = [[level.ex_drm]]("ex_planes_maxhealth", 2000, 1000, 99999, "int");
	if(level.ex_planes)
	{
		level.ex_planes_min = [[level.ex_drm]]("ex_planes_min", 2, 1, 10, "int");
		level.ex_planes_max = [[level.ex_drm]]("ex_planes_max", level.ex_planes_min * 2, level.ex_planes_min + 1, 20, "int");
		level.ex_planes_delay_min = [[level.ex_drm]]("ex_planes_delay_min", 300, 30, 720, "int");
		level.ex_planes_delay_max = [[level.ex_drm]]("ex_planes_delay_max", level.ex_planes_delay_min * 2, level.ex_planes_delay_min + 1, 1440, "int");
		level.ex_planes_alert = [[level.ex_drm]]("ex_planes_alert", 1, 0, 1, "int");
	}

	//****************************************************************************
	// ambient flares
	//****************************************************************************
	level.ex_flares = [[level.ex_drm]]("ex_flares", 0, 0, 1, "int");
	if(level.ex_flares)
	{
		level.ex_flares_type = [[level.ex_drm]]("ex_flares_type", 0, 0, 2, "int");
		level.ex_flares_min = [[level.ex_drm]]("ex_flares_min", 5, 1, 10, "int");
		level.ex_flares_max = [[level.ex_drm]]("ex_flares_max", level.ex_flares_min * 2, level.ex_flares_min + 1, 20, "int");
		level.ex_flares_delay_min = [[level.ex_drm]]("ex_flares_delay_min", 300, 30, 720, "int");
		level.ex_flares_delay_max = [[level.ex_drm]]("ex_flares_delay_max", level.ex_flares_delay_min * 2, level.ex_flares_delay_min + 1, 1440, "int");
		level.ex_flares_alert = [[level.ex_drm]]("ex_flares_alert", 1, 0, 1, "int");
	}
	
	//****************************************************************************
	// ambient mortars
	//****************************************************************************
	level.ex_mortars = [[level.ex_drm]]("ex_mortars", 0, 0, 2, "int");
	if(level.ex_mortars)
	{
		level.ex_mortars_min = [[level.ex_drm]]("ex_mortars_min", 5, 1, 10, "int");
		level.ex_mortars_max = [[level.ex_drm]]("ex_mortars_max", level.ex_mortars_min * 2, level.ex_mortars_min + 1, 20, "int");
		level.ex_mortars_delay_min = [[level.ex_drm]]("ex_mortars_delay_min", 300, 30, 720, "int");
		level.ex_mortars_delay_max = [[level.ex_drm]]("ex_mortars_delay_max", level.ex_mortars_delay_min * 2, level.ex_mortars_delay_min + 1, 1440, "int");
		level.ex_mortars_alert = [[level.ex_drm]]("ex_mortars_alert", 1, 0, 1, "int");
	}

	//****************************************************************************
	// ambient artillery
	//****************************************************************************
	level.ex_artillery = [[level.ex_drm]]("ex_artillery", 0, 0, 2, "int");
	if(level.ex_artillery)
	{
		level.ex_artillery_shells_min = [[level.ex_drm]]("ex_artillery_shells_min", 5, 1, 10, "int");
		level.ex_artillery_shells_max = [[level.ex_drm]]("ex_artillery_shells_max", level.ex_artillery_shells_min * 2, level.ex_artillery_shells_min + 1, 20, "int");
		level.ex_artillery_delay_min = [[level.ex_drm]]("ex_artillery_delay_min", 300, 30, 720, "int");
		level.ex_artillery_delay_max = [[level.ex_drm]]("ex_artillery_delay_max", level.ex_artillery_delay_min * 2, level.ex_artillery_delay_min + 1, 1440, "int");
		level.ex_artillery_alert = [[level.ex_drm]]("ex_artillery_alert", 1, 0, 1, "int");
	}

	//****************************************************************************
	// mobile MG monitoring
	//****************************************************************************
	level.ex_mg_shoot_disable = [[level.ex_drm]]("ex_mg_shoot_disable", 0, 0, 1, "int");
	level.ex_mg_shoot_damage = [[level.ex_drm]]("ex_mg_shoot_damage", 0, 0, 1, "int");

	//****************************************************************************
	// sky fx
	//****************************************************************************
	level.ex_tracers = [[level.ex_drm]]("ex_tracers", 0, 0, 10, "int");
	if(level.ex_tracers)
	{
		level.ex_tracersdelaymin = [[level.ex_drm]]("ex_tracers_delay_min", 60, 10, 720, "int");
		level.ex_tracersdelaymax = [[level.ex_drm]]("ex_tracers_delay_max", level.ex_tracersdelaymin * 2, level.ex_tracersdelaymin + 1, 1440, "int");
		level.ex_tracers_sound = [[level.ex_drm]]("ex_tracers_sound", 1, 0, 1, "int");
	}

	level.ex_flakfx = [[level.ex_drm]]("ex_flakfx", 0, 0, 10, "int");
	if(level.ex_flakfx)
	{
		level.ex_flakfxdelaymin = [[level.ex_drm]]("ex_flakfx_delay_min", 120, 10, 720, "int");
		level.ex_flakfxdelaymax = [[level.ex_drm]]("ex_flakfx_delay_max", level.ex_flakfxdelaymin * 2, level.ex_flakfxdelaymin + 1, 1440, "int");
	}

	//****************************************************************************
	// pop helmet system
	//****************************************************************************
	level.ex_pophelmet = [[level.ex_drm]]("ex_pophelmet", 0, 0, 100, "int");

	//****************************************************************************
	// special grenades
	//****************************************************************************
	level.ex_firenades = [[level.ex_drm]]("ex_fire_grenades", 0, 0, 1, "int");
	level.ex_gasnades = [[level.ex_drm]]("ex_gas_grenades", 0, 0, 1, "int");
	level.ex_satchelcharges = [[level.ex_drm]]("ex_satchel_charges", 0, 0, 1, "int");

	//****************************************************************************
	// coloured smoke grenades
	//****************************************************************************
	level.ex_smoke["american"] = [[level.ex_drm]]("ex_american_smoke", 0, 0, 9, "int");
	level.ex_smoke["british"] = [[level.ex_drm]]("ex_british_smoke", 0, 0, 9, "int");
	level.ex_smoke["russian"] = [[level.ex_drm]]("ex_russian_smoke", 0, 0, 9, "int");
	level.ex_smoke["german"] = [[level.ex_drm]]("ex_german_smoke", 0, 0, 9, "int");

	//****************************************************************************
	// command monitor
	//****************************************************************************
	level.ex_cmdmonitor = [[level.ex_drm]]("ex_cmdmonitor", 0, 0, 1, "int");
	// force command monitor ON if rcon client mode enabled
	if(level.ex_rcon && !level.ex_rcon_mode) level.ex_cmdmonitor = 1;
	if(level.ex_cmdmonitor)
	{
		level.ex_cmdmonitor_models = [[level.ex_drm]]("ex_cmdmonitor_models", 0, 0, 1, "int");
		level.ex_cmdmonitor_endmap_skipstbd = [[level.ex_drm]]("ex_cmdmonitor_endmap_skipstbd", 1, 0, 1, "int");
		level.ex_cmdmonitor_endmap_skipvote = [[level.ex_drm]]("ex_cmdmonitor_endmap_skipvote", 0, 0, 1, "int");
	}

	//****************************************************************************
	// player model limiter
	//****************************************************************************
	level.ex_american_normandy = [[level.ex_drm]]("ex_american_normandy", 1, 1, 10, "int");
	level.ex_british_africa = [[level.ex_drm]]("ex_british_africa", 1, 1, 5, "int");
	level.ex_british_normandy = [[level.ex_drm]]("ex_british_normandy", 1, 1, 6, "int");
	level.ex_german_africa = [[level.ex_drm]]("ex_german_africa", 1, 1, 3, "int");
	level.ex_german_normandy = [[level.ex_drm]]("ex_german_normandy", 1, 1, 4, "int");
	level.ex_german_winterdark = [[level.ex_drm]]("ex_german_winterdark", 1, 1, 4, "int");
	level.ex_russian_coat = [[level.ex_drm]]("ex_russian_coat", 1, 1, 4, "int");
	level.ex_russian_padded = [[level.ex_drm]]("ex_russian_padded", 1, 1, 2, "int");
	level.ex_hatmodels = [[level.ex_drm]]("ex_hatmodels", 0, 0, 2, "int");
	level.ex_camouflage = [[level.ex_drm]]("ex_camouflage", 0, 0, 1, "int");
	level.ex_diana = [[level.ex_drm]]("ex_diana", 0, 0, 1, "int");
	level.ex_diana_memory = [[level.ex_drm]]("ex_diana_memory", 1, 0, 1, "int");

	//****************************************************************************
	// WMD radius control
	//****************************************************************************
	level.ex_mortar_radius = 12 * [[level.ex_drm]]("ex_mortar_radius", 24, 5, 500, "int");
	level.ex_artillery_radius = 12 * [[level.ex_drm]]("ex_artillery_radius", 36, 5, 500, "int");
	level.ex_airstrike_radius = 12 * [[level.ex_drm]]("ex_airstrike_radius", 48, 5, 500, "int");
	level.ex_wmdplanes_maxhealth = [[level.ex_drm]]("ex_wmdplanes_maxhealth", 2000, 1000, 99999, "int");

	//****************************************************************************
	// ammo crates
	//****************************************************************************
	level.ex_amc_perteam = [[level.ex_drm]]("ex_amc_perteam", 0, 0, 8, "int");
	if(level.ex_amc_perteam)
	{
		level.ex_amc_msg = [[level.ex_drm]]("ex_amc_msg", 0, 0, 2, "int");
		level.ex_amc_compass = [[level.ex_drm]]("ex_amc_compass", 0, 0, 2, "int");
		level.ex_amc_chutein = [[level.ex_drm]]("ex_amc_chutein", 0, 0, 3600, "int");
		level.ex_amc_chutein_slice = [[level.ex_drm]]("ex_amc_chutein_slice", 0, 0, 4, "int");
		level.ex_amc_chutein_neutral = [[level.ex_drm]]("ex_amc_chutein_neutral", 0, 0, 1, "int");
		level.ex_amc_chutein_lifespan = [[level.ex_drm]]("ex_amc_chutein_lifespan", 0, 0, 3600, "int");
		level.ex_amc_chutein_pause_slice = [[level.ex_drm]]("ex_amc_chutein_pause_slice", 10, 1, 3600, "int");
		level.ex_amc_chutein_pause_all = [[level.ex_drm]]("ex_amc_chutein_pause_all", 240, 1, 3600, "int");
		level.ex_amc_chutein_score = [[level.ex_drm]]("ex_amc_chutein_score", 0, 0, 1, "int");
	}

	//****************************************************************************
	// entities (free up entities by removing unused spawnpoints)
	//****************************************************************************
	level.ex_entities = [[level.ex_drm]]("ex_entities", 1, 0, 64, "int");
	level.ex_entities_act = [[level.ex_drm]]("ex_entities_act", 1, 0, 1, "int");
	level.ex_entities_debug = [[level.ex_drm]]("ex_entities_debug", 0, 0, 1, "int");
	level.ex_entities_defcon = 4; // 4 = normal, 3 = elevated, 2 = high, 1 = maximum

	//****************************************************************************
	// jukebox
	//****************************************************************************
	level.ex_jukebox = [[level.ex_drm]]("ex_jukebox", 0, 0, 1, "int");
	level.ex_jukebox_power = [[level.ex_drm]]("ex_jukebox_power", 1, 0, 1, "int"); // keep here: memory default
	if(level.ex_jukebox)
	{
		level.ex_jukebox_memory = [[level.ex_drm]]("ex_jukebox_memory", 1, 0, 1, "int");
		level.ex_jukebox_maxtracks = [[level.ex_drm]]("ex_jukebox_tracks", 1, 1, 99, "int");
	}

	//****************************************************************************
	// indoor map
	//****************************************************************************
	level.ex_indoor = [[level.ex_drm]]("ex_indoor", 0, 0, 1, "int");

	//****************************************************************************
	// designer
	//****************************************************************************
	level.ex_designer = [[level.ex_drm]]("ex_designer", 0, 0, 1, "int");
	level.ex_designer_name = [[level.ex_drm]]("ex_designer_name", "", "", "", "string");
	level.ex_designer_showall = [[level.ex_drm]]("ex_designer_showall", 0, 0, 1, "int");

	//****************************************************************************
	// problematic maps
	//****************************************************************************
	level.ex_problemmap = [[level.ex_drm]]("ex_problemmap", 0, 0, 64, "int");

	//****************************************************************************
	// kill confirmed mode
	//****************************************************************************
	level.ex_kc = [[level.ex_drm]]("ex_kc", 0, 0, 3, "int");
	if(level.ex_kc)
	{
		level.ex_kc_weapon = [[level.ex_drm]]("ex_kc_weapon", 2, 0, 4, "int");
		level.ex_kc_pdistr = [[level.ex_drm]]("ex_kc_pdistr", 0, 0, 3, "int");
		level.ex_kc_confirmed_bonus = [[level.ex_drm]]("ex_kc_confirmed_bonus", 1, 1, 999, "int");
		level.ex_kc_denied = [[level.ex_drm]]("ex_kc_denied", 4, 0, 5, "int");
		level.ex_kc_denied_bonus = [[level.ex_drm]]("ex_kc_denied_bonus", 1, 1, 999, "int");
		level.ex_kc_timeout = [[level.ex_drm]]("ex_kc_timeout", 30, 10, 120, "int");
		level.ex_kc_confirm_msg = [[level.ex_drm]]("ex_kc_confirm_msg", 23, 0, 31, "int");
		level.ex_kc_denied_msg = [[level.ex_drm]]("ex_kc_denied_msg", 23, 0, 31, "int");
		level.ex_kc_color_dm = [[level.ex_drm]]("ex_kc_color_dm", 0, 0, 5, "int");
		level.ex_kc_color_axis = [[level.ex_drm]]("ex_kc_color_axis", 2, 0, 5, "int");
		level.ex_kc_color_allies = [[level.ex_drm]]("ex_kc_color_allies", 4, 0, 5, "int");
	}

	//****************************************************************************
	// screenshot mode
	//****************************************************************************
	level.ex_screenshot_mode = [[level.ex_drm]]("ex_screenshot_mode", 0, 0, 1, "int");

	//****************************************************************************
	// OVERRIDES
	//****************************************************************************
	// axis and allies overrides
	level.game_allies = [[level.ex_drm]]("scr_allies", "", "", "", "string");
	if(level.game_allies != "" && (level.game_allies != "american" && level.game_allies != "british" && level.game_allies != "russian")) level.game_allies = "";
	level.game_axis = [[level.ex_drm]]("scr_axis", "", "", "", "string");
	if(level.game_axis != "" && level.game_axis != "german") level.game_axis = "";

	// end music overrides vote and stats music
	if(level.ex_endmusic)
	{
		level.ex_mvmusic = 0;
		level.ex_statsmusic = 0;
	}

	// turn off cinematic intro for a listen server
	if(getCvarInt("dedicated") == 0) level.ex_cinematic = 0;

	// check if we have to override weapon mode
	weaponmode = undefined;
	if(!isDefined(game["weaponmode"]))
	{
		weaponmode_str = getCvar("ex_weaponmode");
		if(weaponmode_str != "")
		{
			weaponmode = getCvarInt("ex_weaponmode");
			setCvar("ex_weaponmode", "");
			// "random": random weapon mode
			if(weaponmode == 99) weaponmode = randomInt(22);
			game["weaponmode"] = weaponmode;
		}
	}
	else weaponmode = int(game["weaponmode"]);

	if(isDefined(weaponmode))
	{
		// case numbers correspond to level.weaponmodes[mode].id
		switch(weaponmode)
		{
			// "team"    : team weapons (stock)
			case  0: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 0; break;
			// "class1"  : pistols
			case  1: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 1; break;
			// "class2"  : sniper rifles
			case  2: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 2; break;
			// "class3"  : machine guns
			case  3: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 3; break;
			// "class4"  : submachine guns
			case  4: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 4; break;
			// "class5"  : rifles
			case  5: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 5; break;
			// "class6"  : bolt action rifles
			case  6: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 6; break;
			// "class7"  : shotguns
			case  7: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 7; break;
			// "class8"  : rocket launchers
			case  8: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 8; break;
			// "class9"  : bolt action and sniper rifles
			case  9: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 9; break;
			// "class10" : knives
			case 10: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 10; break;
			// "all"     : all weapons
			case 11: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 1; level.ex_modern_weapons = 0; level.ex_wepo_class = 0; break;
			// "modern"  : modern weapons
			case 12: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 1; level.ex_wepo_class = 0; break;
			// "mclass1" : modern pistols
			case 13: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 1; level.ex_wepo_class = 1; break;
			// "mclass2" : modern sniper rifles
			case 14: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 1; level.ex_wepo_class = 2; break;
			// "mclass3" : modern machine guns
			case 15: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 1; level.ex_wepo_class = 3; break;
			// "mclass4" : modern submachine guns
			case 16: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 1; level.ex_wepo_class = 4; break;
			// "mclass7" : modern shotguns
			case 17: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 1; level.ex_wepo_class = 7; break;
			// "mclass8" : modern rocket launchers
			case 18: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 1; level.ex_wepo_class = 8; break;
			// "mclass10": modern knives
			case 19: level.ex_bash_only = 0; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 1; level.ex_wepo_class = 10; break;
			// "bash"    : bash mode
			case 20: level.ex_bash_only = 1; level.ex_frag_fest = 0; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 0; break;
			// "frag"    : frag fest
			case 21: level.ex_bash_only = 0; level.ex_frag_fest = 1; level.ex_all_weapons = 0; level.ex_modern_weapons = 0; level.ex_wepo_class = 0; break;
			// "server"  : take server configuration
			default: break;
		}
	}

	// overrides for class system
	if(level.ex_classes)
	{
		level.ex_weaponsonback = 0;
		if(level.ex_classes == 1) level.ex_amc_perteam = 0;
	}

	// overrides for problematic maps
	if(level.ex_problemmap)
	{
		// trying to solve entity overflow errors
		if( (level.ex_problemmap & 1) == 1)
		{
			level.ex_designer = 0;
			level.ex_entities = 5; // clean up entities (1) and start entity monitor (4)
			level.ex_tracers = 0; // tracers prevent DM spawnpoints from being cleaned
			level.ex_amc_perteam = 0; // ammo crates prevent TDM spawnpoints from being cleaned
			level.ex_indoor = 1;
			level.ex_deadbodyfx = 0; // would keep dead player entity on the map for 20 seconds
			level.ex_pophelmet = 0;
			level.ex_firstaid_drop = 0;
		}

		// trying to solve material overflow errors
		if( (level.ex_problemmap & 2) == 2)
		{
			level.ex_bloodonscreen = 0;
			level.ex_bulletholes = 0;
			level.ex_camouflage = 0;
			level.ex_crybaby = 0;
			level.ex_diana = 0;
			level.ex_mapvote_thumbnails = 0;
			level.ex_arcade_shaders = 0;
			level.ex_pophelmet = 0;
			level.ex_ranksystem = 0;
			level.ex_statshud = 0;
			level.ex_turrets = 0;
			level.ex_tweapon = 0;
			level.ex_weather = 0;
		}

		// trying to solve model overflow errors
		if( (level.ex_problemmap & 4) == 4)
		{
			level.ex_american_normandy = 1;
			level.ex_british_africa = 1;
			level.ex_british_normandy = 1;
			level.ex_german_africa = 1;
			level.ex_german_normandy = 1;
			level.ex_german_winterdark = 1;
			level.ex_russian_coat = 1;
			level.ex_russian_padded = 1;
			level.ex_hatmodels = 0;
			level.ex_indoor = 1;
			level.ex_cmdmonitor_models = 0;
			level.ex_all_weapons = 0;
			level.ex_modern_weapons = 0;
			level.ex_weaponsonback = 0;
			level.ex_mbot = 0;
		}

		// trying to solve string overflow errors
		if( (level.ex_problemmap & 8) == 8)
		{
			level.ex_pwelcome = 0;
			level.ex_tweapon = 0;
			level.ex_landmines = 0;
			level.ex_stbd = 0;
			level.ex_mapvote = 0;
			if(level.ex_ranksystem && level.ex_rank_hudicons == 2) level.ex_rank_hudicons = 1;
			if(level.ex_turrets > 1) level.ex_turrets = 1;
		}

		// trying to solve effect overflow errors
		if( (level.ex_problemmap & 16) == 16)
		{
			level.ex_turretoverheat = 0;
			level.ex_flares = 0;
			level.ex_flakfx = 0;
			level.ex_planes_flak = 0;
			level.ex_tracers = 0;
			level.ex_aimrig = 0;
			level.ex_flagbase_anim_allies = 0;
			level.ex_flagbase_anim_axis = 0;
			level.ex_flagbase_anim_neutral = 0;
			level.ex_wallfire = 0;
		}
	}

	// mbot overrides
	if(level.ex_mbot)
	{
		level.ex_classes = 0;
		level.ex_testclients = 0;
		level.ex_designer = 0;
		if(level.ex_wepo_class == 1 || level.ex_wepo_class == 10) level.ex_wepo_class = 0;
		if((level.ex_all_weapons || (!level.ex_wepo_class && (level.ex_gunship || level.ex_gunship_special))) && level.ex_turrets > 1) level.ex_turrets = 1;
		level.ex_bash_only = 0;
		level.ex_weaponsonback = 0;
		level.ex_longrange = 0;
		level.ex_readyup = 0;
		level.ex_spwn_time = 0;
		level.ex_firenades = 0;
		level.ex_gasnades = 0;
		level.ex_satchelcharges = 0;

		level.ex_stbd = 0;
		level.ex_mapvote = 0;
		level.ex_mapvote_thumbnails = 0;
		level.ex_svrmsg_info = 0;
		level.ex_svrmsg_rotation = 0;
		level.ex_wepo_limiter = 0;

		setCvar("g_allowvote", 0);
		setCvar("g_oldvoting", 0);
		game["timelimit"] = 0;
		setCvar("scr_" + level.ex_currentgt + "_timelimit", game["timelimit"]);
		game["scorelimit"] = 0;
		setCvar("scr_" + level.ex_currentgt + "_scorelimit", game["scorelimit"]);
		level.teambalance = 0;
		setCvar("scr_teambalance", level.teambalance);

		if(level.ex_mbot_dev)
		{
			level.ex_designer = 1;
			level.ex_designer_showall = 0;
			level.ex_mbot_dev_allies = level.ex_mbot_allies;
			if(!level.ex_mbot_dev_allies) level.ex_mbot_dev_allies = 5;
			level.ex_mbot_allies = 0;
			level.ex_mbot_dev_axis = level.ex_mbot_axis;
			if(!level.ex_mbot_dev_axis) level.ex_mbot_dev_axis = 5;
			level.ex_mbot_axis = 0;
			level.ex_mbot_spec = 0;
		}
	}

	// spawnpoint designer overrides
	if(level.ex_designer)
	{
		level.ex_indoor = 1;
		level.ex_amc_perteam = 0;
		level.ex_turrets = 0;
		level.ex_healthbar = 0;
		level.ex_healthregen = 1;
		level.ex_medicsystem = 0;
		level.ex_landmines = 0;
		level.ex_tweapon = 0;
		level.ex_specials = 0;
	}

	// bot weapon drop override
	level.ex_weapondrop_override = 0;
	if(level.ex_mbot || level.ex_testclients) level.ex_weapondrop_override = 1;

	// camouflage models are only available for the first model, so set model limiter to 1
	if(level.ex_camouflage)
	{
		level.ex_american_normandy = 1;
		level.ex_british_africa = 1;
		level.ex_british_normandy = 1;
		level.ex_german_africa = 1;
		level.ex_german_normandy = 1;
		level.ex_german_winterdark = 1;
		level.ex_russian_coat = 1;
		level.ex_russian_padded = 1;
	}

	// freezetag overrides
	if(level.ex_currentgt == "ft")
	{
		// force sidearm for FreezeTag (regular sidearm will be replaced by raygun)
		level.ex_wepo_sidearm = 1;

		// disable or change weapon drop features if weapon exchange mode is enabled
		if(level.ft_weaponsteal)
		{
			level.ex_droponarmhit = 0;
			level.ex_droponhandhit = 0;
			level.ex_droponfall = 0;
			if(level.ex_wepo_drop_weps == 2) level.ex_wepo_drop_weps = 0; // off
				else if(level.ex_wepo_drop_weps == 4) level.ex_wepo_drop_weps = 3; // secondary only
		}

		// change parachute (protection) feature
		if(level.ex_parachutes)
		{
			if(level.ex_parachutesprotection == 0) level.ex_parachutes = 0;
				else if(level.ex_parachutesprotection == 2) level.ex_parachutesprotection = 1;
		}

		level.ex_obituary = 0;
		level.ex_gunship = 0;
		level.ex_gunship_special = 0;
		level.ex_medic_showinjured = 0;
		level.ex_turrets = 0;
	}

	// kill confirmed checks
	if(level.ex_kc)
	{
		if(level.ex_currentgt == "ft" || level.ex_currentgt == "hm" || level.ex_currentgt == "lms" || level.ex_currentgt == "lts") level.ex_kc = 0;
		else if(!level.ex_teamplay)
		{
			if(level.ex_kc > 1) level.ex_kc = 1;
			if(level.ex_kc_denied == 3) level.ex_kc_denied = 1;
				else if(level.ex_kc_denied == 4 || level.ex_kc_denied == 5) level.ex_kc_denied = 2;
		}

		// if you get bonus points for denied kills, turn off tactical insertion
		if(level.ex_kc_denied == 2 || level.ex_kc_denied == 4 || level.ex_kc_denied == 5) level.ex_insertion = 0;
	}

	// for bash-only mode activate shotgun-only class, and disable all-weapons,
	// modern weapons, nades, pistols, knives and medic system (secondary weapons
	// will be disabled automatically)
	if(level.ex_bash_only)
	{
		level.ex_statshud = 0;
		level.ex_frag_fest = 0;
		level.ex_all_weapons = 0;
		level.ex_modern_weapons = 0;
		level.ex_wepo_class = 7;
		level.ex_frag_loadout = 2;
		level.ex_wepo_allow_frag = 0;
		level.ex_wepo_frag = 0;
		level.ex_smoke_loadout = 2;
		level.ex_wepo_allow_smoke = 0;
		level.ex_wepo_smoke = 0;
		level.ex_wepo_sidearm = 0;
		level.ex_wepo_drop_weps = 0;
		level.ex_amc_perteam = 0;
		level.ex_turrets = 0;
		level.ex_medicsystem = 0;
		level.ex_landmines = 0;
		level.ex_indoor = 1;
		level.ex_ranksystem = 0;
		level.ex_specials = 0;
		level.ex_specialmodemsg = &"^1BASH MODE";
		[[level.ex_PrecacheString]](level.ex_specialmodemsg);
	}

	// for nade fest activate pictol-only class, and disable all-weapons, modern
	// weapons, sidearm and medic system (secondary weapons wil be diabled
	// automatically
	if(level.ex_frag_fest)
	{
		level.ex_statshud = 0;
		level.ex_all_weapons = 0;
		level.ex_modern_weapons = 0;
		level.ex_wepo_class = 1;
		level.ex_frag_loadout = 2;
		level.ex_wepo_allow_frag = 1;
		level.ex_wepo_frag = 9;
		level.ex_wepo_allow_smoke = 0;
		level.ex_smoke_loadout = 2;
		level.ex_wepo_smoke = 0;
		level.ex_wepo_sidearm = 0;
		level.ex_wepo_drop_weps = 0;
		//level.ex_amc_perteam = 0;
		level.ex_turrets = 0;
		level.ex_medicsystem = 0;
		level.ex_landmines = 0;
		level.ex_indoor = 1;
		level.ex_ranksystem = 0;
		level.ex_specials = 0;
		level.ex_specialmodemsg = &"^1FRAG FEST";
		[[level.ex_PrecacheString]](level.ex_specialmodemsg);
	}

	// disable modern weapons and classes if all weapons enabled
	if(level.ex_all_weapons)
	{
		level.ex_modern_weapons = 0;
		level.ex_wepo_class = 0;
		level.ex_wepo_team_only = 0;
		level.ex_wepo_enemy = 1;
	}

	// disable weapons on back and some classes if modern weapons enabled
	if(level.ex_modern_weapons)
	{
		if(level.ex_wepo_class == 5 || level.ex_wepo_class == 6 || level.ex_wepo_class == 9) level.ex_wepo_class = 0;
		level.ex_wepo_team_only = 0;
		level.ex_wepo_enemy = 1;
		level.ex_weaponsonback = 0;
	}

	// allow use of enemy weapons if using secondary enemy menu
	if(level.ex_wepo_secondary == 2) level.ex_wepo_sec_enemy = 1;
		else level.ex_wepo_sec_enemy = 0;
	if(level.ex_wepo_sec_enemy) level.ex_wepo_enemy = 1;

	// weapon class based overrides
	if(level.ex_wepo_class)
	{
		// disable the secondary weapons system
		level.ex_wepo_secondary = 0;

		// disable the weapon limiter
		level.ex_wepo_limiter = 0;

		// override team only menu for unsupported weapon classes
		if(level.ex_wepo_class >= 6) level.ex_wepo_team_only = 0;

		// force sidearm to knife for pistols only class
		if(level.ex_wepo_class == 1 && level.ex_wepo_sidearm) level.ex_wepo_sidearm_type = 1;

		// switch off nades and sidearm for knives only class
		if(level.ex_wepo_class == 10)
		{
			level.ex_wepo_allow_grenades = 0;
			level.ex_wepo_allow_frag = 0;
			level.ex_wepo_allow_smoke = 0;
			level.ex_wepo_sidearm = 0;
		}

		// allow use of enemy weapons if weapons not limited to team
		if(!level.ex_wepo_team_only) level.ex_wepo_enemy = 1;
	}

	// if the rank system is disabled, use default weapon, frag and smoke ammo settings
	if(!level.ex_ranksystem)
	{
		// set weapon ammo loadout to stock
		if(level.ex_wepo_loadout == 1) level.ex_wepo_loadout = 0;

		// set frag ammo loadout to stock
		if(!level.ex_bash_only && level.ex_frag_loadout == 1) level.ex_frag_loadout = 0;

		// set smoke ammo loadout to stock
		if(!level.ex_bash_only && level.ex_smoke_loadout == 1) level.ex_smoke_loadout = 0;

		// set landmines ammo loadout to stock
		if(level.ex_landmines && level.ex_landmines_loadout == 1) level.ex_landmines_loadout = 0;
	}

	// gunship checks
	if(level.ex_gunship || level.ex_gunship_special)
	{
		// gunship mode 2, but ranksystem turned off, switch to mode 1
		if(level.ex_gunship == 2 && !level.ex_ranksystem) level.ex_gunship = 1;

		// gunship mode 2, ranksystem on but wmd turned off, switch to mode 1
		if(level.ex_gunship == 2 && level.ex_ranksystem && !level.ex_rank_wmdtype) level.ex_gunship = 1;

		// gunship mode 2, ranksystem wmd mode 3, but special not allowed, switch to mode 1
		if(level.ex_gunship == 2 && level.ex_ranksystem && level.ex_rank_wmdtype == 3 && !level.ex_rank_allow_special) level.ex_gunship = 1;

		// gunship mode 3, but obitladder turned off, switch to mode 1
		if(level.ex_gunship == 3 && !level.ex_obitladder) level.ex_gunship = 1;

		// disable gunship stopwatch on sd and esd (overlapping)
		if(level.ex_currentgt == "sd" || level.ex_currentgt == "esd") level.ex_gunship_clock = 0;
	}

	// deactivate features if screenshot mode is enabled
	if(level.ex_screenshot_mode)
	{
		game["timelimit"] = 0;
		setCvar("scr_" + level.ex_currentgt + "_timelimit", game["timelimit"]);
		level.ex_testclients = 0;
		level.ex_mbot = 0;
		level.ex_clantext = 0;
		level.ex_modtext = 0;
		level.ex_mylogo = 0;
		level.ex_svrmsg = 0;
		level.ex_specmusic = 0;
		level.ex_indoor = 1;
	}

	// indoor map overrides
	if(level.ex_indoor)
	{
		if(level.ex_ranksystem) level.ex_rank_wmdtype = 0;
		level.ex_amc_chutein = 0;
		level.ex_artillery = 0;
		level.ex_flakfx = 0;
		level.ex_flares = 0;
		level.ex_mortars = 0;
		level.ex_parachutes = 0;
		level.ex_planes = 0;
		level.ex_tracers = 0;
		level.ex_gunship = 0;
		level.ex_gunship_special = 0;
		level.ex_heli = 0;
	}

	// weapon class turret override
	if(level.ex_turrets && level.ex_wepo_class)
	{
		level.ex_turrets_onclassmap = [[level.ex_drm]]("ex_turrets_onclassmap", 0, 0, 1, "int");
		if(!level.ex_turrets_onclassmap) level.ex_turrets = 0;
			else if(level.ex_turrets > 1) level.ex_turrets = 1;
	}

	// prevent status icons overflow (max 8) and image overflow (max unknown)
	if(level.ex_ranksystem)
	{
		if(level.ex_readyup && !isDefined(game["readyup_done"])) level.ex_rank_statusicons = 0;
		if(level.ex_classes == 1 && level.ex_classes_statusicons) level.ex_rank_statusicons = 0;
		if(level.ex_classes == 1 && level.ex_classes_headicons) level.ex_rank_headicons = 0;

		if(level.ex_rank_statusicons == 2 && (level.ex_flagbased || level.ex_currentgt == "ft" || level.ex_currentgt == "hm" || level.ex_currentgt == "lib" || level.ex_currentgt == "vip"))
			level.ex_rank_statusicons = 0;
		if(level.ex_rank_statusicons == 3 && (level.ex_flagbased || level.ex_gunship || level.ex_gunship_special || level.ex_currentgt == "ft" || level.ex_currentgt == "hm" || level.ex_currentgt == "lib" || level.ex_currentgt == "vip"))
			level.ex_rank_statusicons = 0;

		// check for potential shader precache overflow
		if((level.ex_arcade_shaders & 8) == 8 && level.ex_arcade_shaders_perkall && level.ex_specials) level.ex_arcade_shaders_perkall = 0;
	}
	else level.ex_rank_statusicons = 0;

	// disable black screen of death if killcam is enabled; adjust mode 4 if no respawn delay
	if(getCvar("scr_killcam") != "" && getCvarInt("scr_killcam")) level.ex_bsod = 0;
	if(level.ex_bsod == 4 && !level.respawndelay) level.ex_bsod = 2;

	// no need to randomize rotation if map voting system or player based rotation is enabled
	if(level.ex_pbrotate || level.ex_mapvote) level.ex_randommaprotation = 0;

	// redirection check
	if(level.ex_redirect && (!isDefined(level.ex_redirect_ip) || level.ex_redirect_ip == "")) level.ex_redirect = 0;

	// disable live stats if not team based, or the game type has a similar system
	if(!level.ex_teamplay || level.ex_currentgt == "lib" || level.ex_currentgt == "rbcnq" || level.ex_currentgt == "rbctf") level.ex_livestats = 0;

	// disable knife perk if knife is available as main weapon or sidearm
	if(level.ex_wepo_class == 10 || (level.ex_wepo_sidearm && level.ex_wepo_sidearm_type)) level.ex_specials_knife = 0;

	//****************************************************************************
	// special feature activation
	//****************************************************************************

	// object queue initialization
	if(level.ex_pophelmet) extreme\_ex_objectqueue::queueInit("helmet", 8);
	if(level.ex_medicsystem && level.ex_firstaid_drop) extreme\_ex_objectqueue::queueInit("health", 8);

	// map voting (also needed by next map display feature)
	extreme\_ex_mapvote::init();

	// override to prevent image overflow (keep in between mapvote init and statshud init)
	if(level.ex_mapvote && level.ex_mapvote_thumbnails && level.ex_maps.size > 1)
	{
		level.ex_statshud = 0;
		level.ex_arcade_shaders = 0;
	}

	// stats hud init
	if(level.ex_statshud)
	{
		extreme\_ex_statshud::init();

 		// override (keep after statshud init)
 		// if player stats still enabled (init can switch the feature off), disable
		// certain features to free up HUD elements
		if(level.ex_statshud)
		{
			if(level.ex_ranksystem && level.ex_rank_hudicons == 2) level.ex_rank_hudicons = 1;
			if(level.ex_sprint) level.ex_sprinthud = 0;
			level.ex_cam = 0;
			level.ex_uav = 0;
			// if safe mode enabled, disable more
			if(level.ex_statshud_safemode)
			{
				level.ex_rank_hudicons = 0;
				if(level.ex_beartrap) level.ex_beartrap_warning = 0;
				if(level.ex_landmines) level.ex_landmine_warning = 0;
				if(level.ex_tweapon) level.ex_tweapon_warning = 0;
			}
		}
	}

	// specials registration (if ex_specials is 0 this will set all perks vars to 0)
	extreme\_ex_specials::registerPerks();

	// weather override (keep after perks init)
	if(level.ex_weather)
	{
		if(level.ex_specials)
		{
			level.ex_weather_rain_max = 1;
			level.ex_weather_snow_max = 1;
		}
		if(level.ex_weather_visibility) level.ex_ambmapfog = 0;
		level.ex_ambsnowfx = 0;
	}

	// animated aim rig
	if((!level.ex_ranksystem || !level.ex_rank_wmdtype) && (!level.ex_specials || !level.ex_cam)) level.ex_aimrig = 0;

	// init entity management
	extreme\_ex_entities::init();

	// init persistent memory
	extreme\_ex_memory::init();

	// spawnpoint manipulation
	extreme\_ex_spawnpoints::init();

	// load effects
	loadeffects();

	// precache strings
	precachestrings();

	// precache headicons
	precacheheadicons();

	// precache ranksystem shaders, headicons and statusicons
	if(level.ex_ranksystem) precacheranksystem();

	// precache shaders
	precacheshaders();

	// precache models
	precachemodels();

	// load the clan text before precaching it in modinfo.gsc
	if(level.ex_clantext) thread scriptdata\_ex_clantext::init();

	// unconditional events initialization (handled by event controller)
	extreme\_ex_airtrafficcontroller::init();
	extreme\_ex_clientcontrol::init();
	extreme\_ex_callvote::init();
	extreme\_ex_messages::init();
	extreme\_ex_projectiles::init();
	extreme\_ex_specials::init();

	// conditional events initialization (handled by event controller)
	if(level.ex_artillery) extreme\_ex_artillery_ambient::init();
	if(level.ex_classes) extreme\_ex_classes::init();
	if(level.ex_cmdmonitor) extreme\_ex_cmdmonitor::init();
	if(level.ex_flares) extreme\_ex_flares_ambient::init();
	if(level.ex_inactive_plyr || level.ex_inactive_spec) extreme\_ex_inactivity::init();
	if(level.ex_longrange) extreme\_ex_longrange::init();
	if(level.ex_rotateifempty) extreme\_ex_maprotation::init();
	if(level.ex_modtext || level.ex_clantext) extreme\_ex_modinfo::init();
	if(level.ex_mortars) extreme\_ex_mortar_ambient::init();
	if(level.ex_mylogo) extreme\_ex_mylogo::init();
	if(level.ex_namechecker) extreme\_ex_namecheck::init();
	if(level.ex_redirect) extreme\_ex_redirect::init();
	if(level.ex_statstotal) extreme\_ex_statstotal::init();
	if(level.ex_tracers || level.ex_flakfx) extreme\_ex_skyeffects::init();
	if(level.ex_announcer && !level.ex_roundbased) extreme\_ex_announcer::init();
	if(level.ex_weaponsonback == 2 || (level.ex_weaponsonback == 1 && level.ex_wepo_secondary)) extreme\_ex_weaponback::init();
	if(level.ex_toolbox) extreme\_ex_toolbox::init();

	// enhanced feature initialization
	if(level.ex_jukebox) extreme\_ex_jukebox::init();
	if(level.ex_kc) extreme\_ex_killconfirmed::init();
	if(level.ex_landmines) extreme\_ex_landmines::init();
	if(level.ex_clog || level.ex_glog) extreme\_ex_logmonitor::init();
	if(level.ex_readyup) extreme\_ex_readyup::init();
	if(level.ex_nongrata) extreme\_ex_security::init();
	if(level.ex_tweapon) extreme\_ex_tripwires::init();
}

postmapload()
{
	level.ex_nademonitor = 0;
	// force nade monitor to run if fire or gas nades are activated. They need monitoring for the damage threads
	if(level.ex_firenades || level.ex_smoke[game["allies"]] == 7 || level.ex_smoke[game["axis"]] == 7) level.ex_nademonitor = 1;
	if(level.ex_gasnades || level.ex_smoke[game["allies"]] == 8 || level.ex_smoke[game["axis"]] == 8) level.ex_nademonitor = 1;
	//if(level.ex_satchelcharges || level.ex_smoke[game["allies"]] == 9 || level.ex_smoke[game["axis"]] == 9) level.ex_nademonitor = 1;

	// enable nade monitor if any of the nade features are enabled
	if(level.ex_nademon_frag || level.ex_nademon_frag_eoc || level.ex_nademon_frag_cpx) level.ex_nademonitor = 1;
	if(level.ex_nademon_satchel || level.ex_nademon_satchel_eoc || level.ex_nademon_satchel_cpx) level.ex_nademonitor = 1;
	if(level.ex_nademon_smoke || level.ex_nademon_fire || level.ex_nademon_gas) level.ex_nademonitor = 1;
	if(level.ex_nademon_throwback) level.ex_nademonitor = 1;

	// only switch nade monitor off again if a weapon class is enabled without nades
	if(level.ex_wepo_class && !level.ex_wepo_allow_frag && !level.ex_wepo_allow_smoke) level.ex_nademonitor = 0;

	// force on if the supernade features is enabled
	if(level.ex_supernade && (level.ex_supernade_cpx || level.ex_supernade_eoc)) level.ex_nademonitor = 1;

	if(level.ex_nademonitor) extreme\_ex_nades::init();

	// winter map detection and options
	if(isDefined(game["german_soldiertype"]) && (game["german_soldiertype"] == "winterlight" || game["german_soldiertype"] == "winterdark")) level.ex_wintermap = true;
		else level.ex_wintermap = false;

	// postmapload precache fx
	postmapload_loadfx();

	// postmapload precache strings
	postmapload_precachestrings();

	// postmapload precache shaders
	postmapload_precacheshaders();

	// postmapload precache perks
	if(level.ex_specials) extreme\_ex_specials::initPost();

	// update server info dvars and initiate forced cvar loop if necessary
	extreme\_ex_cvarcontroller::initPost();

	// start live stats
	if(level.ex_livestats) thread extreme\_ex_livestats::init();
}

loadeffects()
{
	// explode player punishment
	if(level.ex_rcon || level.ex_cmdmonitor || (level.ex_turrets && level.ex_turretabuse) || ((level.ex_campwarntime || level.ex_campsniper_warntime) && (!level.ex_camppunish || level.ex_camppunish == 3)))
		level.ex_effect["barrel"] = [[level.ex_PrecacheEffect]]("fx/props/barrelexp.efx");

	// turret overheating
	if(level.ex_turrets && level.ex_turretoverheat)
		level.ex_effect["armored_car_overheat"] = [[level.ex_PrecacheEffect]]("fx/distortion/armored_car_overheat.efx");

	// ambient flares
	if(level.ex_flares)
	{
		switch(level.ex_flares_type)
		{
			case 0: level.ex_effect["flare_ambient"] = [[level.ex_PrecacheEffect]]("fx/misc/flare_hill400.efx"); break;
			case 1: level.ex_effect["flare_ambient"] = [[level.ex_PrecacheEffect]]("fx/flares/flare_1.efx"); break;
			default: level.ex_effect["flare_ambient"] = [[level.ex_PrecacheEffect]]("fx/flares/flare_firework.efx"); break;
		}
	}

	// ambient flak effects
	if(level.ex_flakfx || (level.ex_planes && level.ex_planes_flak) || (level.ex_ranksystem && level.ex_rank_wmdtype))
		level.ex_effect["flak_shellexplode"] = [[level.ex_PrecacheEffect]]("fx/explosions/flak_shellexplode.efx");

	// ambient tracers
	if(level.ex_tracers) level.ex_effect["tracer"] = [[level.ex_PrecacheEffect]]("fx/misc/antiair_tracers.efx");

	// plane and heli crash effects
	if(level.ex_planes || level.ex_gunship || level.ex_gunship_special || level.ex_heli || level.ex_ranksystem || (level.ex_amc_perteam && level.ex_amc_chutein))
	{
		level.ex_effect["plane_explosion"] = [[level.ex_PrecacheEffect]]("fx/explosions/spitfire_bomb_dirt.efx");
		level.ex_effect["planecrash_smoke"] = [[level.ex_PrecacheEffect]]("fx/smoke/thin_black_smoke_M.efx");
		level.ex_effect["planecrash_explosion"] = [[level.ex_PrecacheEffect]]("fx/explosions/panzer_explosion.efx");
		level.ex_effect["planecrash_ball"] = [[level.ex_PrecacheEffect]]("fx/smoke/battlefield_smokebank_S.efx");
	}

	// napalm
	if(level.ex_ranksystem && level.ex_rank_wmdtype)
	{
		level.ex_effect["napalm_bomb"] = [[level.ex_PrecacheEffect]]("fx/extreme_napalm/napalm.efx");
		if(level.ex_rank_wmd_flare) level.ex_effect["flare_indicator"] = [[level.ex_PrecacheEffect]]("fx/misc/flare_artillery_runner.efx");
	}

	// landmines
	if(level.ex_landmines) level.ex_effect["landmine_explosion"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_dirt.efx");

	// gunship
	if(level.ex_gunship)
	{
		level.ex_effect["gunship_flares"] = [[level.ex_PrecacheEffect]]("fx/flares/ac130_flare_emitter.efx");
		if(level.ex_gunship_nuke && level.ex_gunship_nuke_fx) level.ex_effect["gunship_nuke"] = [[level.ex_PrecacheEffect]]("fx/impacts/gunship_nuke_expand.efx");
	}

	// multi purpose effects
	level.ex_effect["plane_bomb"] = [[level.ex_PrecacheEffect]]("fx/explosions/spitfire_bomb_dirt.efx");
	level.ex_effect["artillery"] = [[level.ex_PrecacheEffect]]("fx/props/barrelexp.efx");

	// bleeding
	if(level.ex_bleeding) level.ex_effect["bleeding"] = [[level.ex_PrecacheEffect]]("fx/impacts/bleeding_hit.efx");

	// fire effects for napalm, command monitor fire, flamethrower, fire nades
	level.ex_effect["fire_ground"] = [[level.ex_PrecacheEffect]]("fx/fire/ground_fire_med.efx");
	level.ex_effect["fire_arm"] = [[level.ex_PrecacheEffect]]("fx/fire/character_arm_fire.efx");
	level.ex_effect["fire_torso"] = [[level.ex_PrecacheEffect]]("fx/fire/character_torso_fire.efx");

	// binoculars animated crosshair
	if(level.ex_aimrig)
	{
		switch(level.ex_aimrig)
		{
			case 1: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_black.efx"); break;
			case 2: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_blue.efx"); break;
			case 3: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_gold.efx"); break;
			case 4: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_green.efx"); break;
			case 5: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_red.efx"); break;
			case 6: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_silver.efx"); break;
			case 7: game["aimrig_selector"] = [[level.ex_PrecacheEffect]]("fx/selector/ui_selector_yellow.efx"); break;
		}
	}

	if(level.ex_flagbased || level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
	{
		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
		{
			if(level.ex_flagbase_anim_allies)
			{
				switch(level.ex_flagbase_anim_allies)
				{
					case 1: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_black.efx"); break;
					case 2: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_blue.efx"); break;
					case 3: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_gold.efx"); break;
					case 4: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_green.efx"); break;
					case 5: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_red.efx"); break;
					case 6: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_silver.efx"); break;
					case 7: game["flagbase_anim_allies"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_yellow.efx"); break;
				}
			}

			if(level.ex_flagbase_anim_axis)
			{
				switch(level.ex_flagbase_anim_axis)
				{
					case 1: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_black.efx"); break;
					case 2: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_blue.efx"); break;
					case 3: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_gold.efx"); break;
					case 4: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_green.efx"); break;
					case 5: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_red.efx"); break;
					case 6: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_silver.efx"); break;
					case 7: game["flagbase_anim_axis"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_yellow.efx"); break;
				}
			}
		}

		if(level.ex_currentgt == "htf" || level.ex_currentgt == "ihtf" || level.ex_currentgt == "dom" || level.ex_currentgt == "ons")
		{
			if(level.ex_flagbase_anim_neutral)
			{
				switch(level.ex_flagbase_anim_neutral)
				{
					case 1: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_black.efx"); break;
					case 2: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_blue.efx"); break;
					case 3: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_gold.efx"); break;
					case 4: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_green.efx"); break;
					case 5: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_red.efx"); break;
					case 6: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_silver.efx"); break;
					case 7: game["flagbase_anim_neutral"] = [[level.ex_PrecacheEffect]]("fx/flagbase/ui_flagbase_yellow.efx"); break;
				}
			}
		}
	}
}

precacheranksystem()
{
	// ranksystem hudicon definitions
	if(level.ex_rank_hudicons)
	{
		game["hudicon_rank0"] = "private_hudicon";
		game["hudicon_rank1"] = "corporal_hudicon";
		game["hudicon_rank2"] = "sergeant_hudicon";
		game["hudicon_rank3"] = "lieutenant_hudicon";
		game["hudicon_rank4"] = "captain_hudicon";
		game["hudicon_rank5"] = "major_hudicon";
		game["hudicon_rank6"] = "colonel_hudicon";
		game["hudicon_rank7"] = "general_hudicon";

		[[level.ex_PrecacheShader]](game["hudicon_rank0"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank1"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank2"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank3"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank4"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank5"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank6"]);
		[[level.ex_PrecacheShader]](game["hudicon_rank7"]);
	}

	if(level.ex_rank_headicons)
	{
		// ranksystem headicon definitions
		game["headicon_rank0"] = "headicon_privateA";
		game["headicon_rank1"] = "headicon_corpor_a";
		game["headicon_rank2"] = "headicon_sergnt_a";
		game["headicon_rank3"] = "headicon_lieute_a";
		game["headicon_rank4"] = "headicon_captan_a";
		game["headicon_rank5"] = "headicon_major0_a";
		game["headicon_rank6"] = "headicon_colonl_a";
		game["headicon_rank7"] = "headicon_generl_a";

		[[level.ex_PrecacheHeadIcon]](game["headicon_rank0"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank1"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank2"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank3"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank4"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank5"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank6"]);
		[[level.ex_PrecacheHeadIcon]](game["headicon_rank7"]);
	}

	// ranksystem statusicon definitions
	if(level.ex_rank_statusicons)
	{
		game["statusicon_rank0"] = "rank_private";
		game["statusicon_rank1"] = "rank_corporal";
		game["statusicon_rank2"] = "rank_sergeant";
		game["statusicon_rank3"] = "rank_lieutenant";
		game["statusicon_rank4"] = "rank_captain";
		game["statusicon_rank5"] = "rank_major";
		game["statusicon_rank6"] = "rank_colonel";
		game["statusicon_rank7"] = "rank_general";

		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank0"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank1"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank2"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank3"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank4"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank5"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank6"]);
		[[level.ex_PrecacheStatusIcon]](game["statusicon_rank7"]);
	}
}

precachestrings()
{
	// crybaby punishment from rcon
	if(level.ex_rcon && level.ex_crybaby) [[level.ex_PrecacheString]](&"MISC_CRYBABY");

	// welcome messages
	if(level.ex_pwelcome)
	{
		if(level.ex_pwelcome_all >= 1) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_1");
		if(level.ex_pwelcome_all >= 2) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_2");
		if(level.ex_pwelcome_all >= 3) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_3");
		if(level.ex_pwelcome_all >= 4) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_4");
		if(level.ex_pwelcome_all >= 5) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_5");
		if(level.ex_pwelcome_all >= 6) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_6");
		if(level.ex_pwelcome_all >= 7) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_7");
		if(level.ex_pwelcome_all >= 8) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_8");
		if(level.ex_pwelcome_all >= 9) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_9");
		if(level.ex_pwelcome_all >= 10) [[level.ex_PrecacheString]](&"CUSTOM_ALL_MESSAGE_10");

		if(level.ex_pwelcome_msg >= 1) [[level.ex_PrecacheString]](&"CUSTOM_NONCLAN_MESSAGE_1");
		if(level.ex_pwelcome_msg >= 2) [[level.ex_PrecacheString]](&"CUSTOM_NONCLAN_MESSAGE_2");
		if(level.ex_pwelcome_msg >= 3) [[level.ex_PrecacheString]](&"CUSTOM_NONCLAN_MESSAGE_3");

		if(level.ex_clanwelcome)
		{
			if(level.ex_cltag[1] != "")
			{
				if(level.ex_clmsg[1] >= 1) [[level.ex_PrecacheString]](&"CUSTOM_CLAN1_MESSAGE_1");
				if(level.ex_clmsg[1] >= 2) [[level.ex_PrecacheString]](&"CUSTOM_CLAN1_MESSAGE_2");
				if(level.ex_clmsg[1] >= 3) [[level.ex_PrecacheString]](&"CUSTOM_CLAN1_MESSAGE_3");
			}

			if(level.ex_cltag[2] != "")
			{
				if(level.ex_clmsg[2] >= 1) [[level.ex_PrecacheString]](&"CUSTOM_CLAN2_MESSAGE_1");
				if(level.ex_clmsg[2] >= 2) [[level.ex_PrecacheString]](&"CUSTOM_CLAN2_MESSAGE_2");
				if(level.ex_clmsg[2] >= 3) [[level.ex_PrecacheString]](&"CUSTOM_CLAN2_MESSAGE_3");
			}

			if(level.ex_cltag[3] != "")
			{
				if(level.ex_clmsg[3] >= 1) [[level.ex_PrecacheString]](&"CUSTOM_CLAN3_MESSAGE_1");
				if(level.ex_clmsg[3] >= 2) [[level.ex_PrecacheString]](&"CUSTOM_CLAN3_MESSAGE_2");
				if(level.ex_clmsg[3] >= 3) [[level.ex_PrecacheString]](&"CUSTOM_CLAN3_MESSAGE_3");
			}

			if(level.ex_cltag[4] != "")
			{
				if(level.ex_clmsg[4] >= 1) [[level.ex_PrecacheString]](&"CUSTOM_CLAN4_MESSAGE_1");
				if(level.ex_clmsg[4] >= 2) [[level.ex_PrecacheString]](&"CUSTOM_CLAN4_MESSAGE_2");
				if(level.ex_clmsg[4] >= 3) [[level.ex_PrecacheString]](&"CUSTOM_CLAN4_MESSAGE_3");
			}
		}

		[[level.ex_PrecacheString]](&"CUSTOM_VOTE_ALLOWED");
		[[level.ex_PrecacheString]](&"CUSTOM_VOTE_NOT_ALLOWED");
	}

	// arcade style HUD announcement of points scored for kills
	if(level.ex_arcade_score)
	{
		[[level.ex_PrecacheString]](&"MP_PLUS");
		[[level.ex_PrecacheString]](&"MP_MINUS");
	}

	// server redirection
	if(level.ex_redirect)
	{
		[[level.ex_PrecacheString]](&"REDIRECT_TITLE");
		[[level.ex_PrecacheString]](&"REDIRECT_TIMELEFT");

		if(level.ex_redirect_reason == 0 || level.ex_redirect_reason == 1)
			[[level.ex_PrecacheString]](&"REDIRECT_REASON_ISFULL");

		if(level.ex_redirect_reason == 0 || level.ex_redirect_reason == 1 || level.ex_redirect_reason == 3)
		{
			[[level.ex_PrecacheString]](&"REDIRECT_TO_OTHERSERVER");
			if(level.ex_redirect_hint) [[level.ex_PrecacheString]](&"REDIRECT_HINT_VISITWEBSITE");
		}

		if(level.ex_redirect_reason == 1)
		{
			[[level.ex_PrecacheString]](&"REDIRECT_REASON_ISPRIVATE");
			[[level.ex_PrecacheString]](&"REDIRECT_TO_PUBLICSERVER");
		}

		if(level.ex_redirect_reason == 2)
		{
			[[level.ex_PrecacheString]](&"REDIRECT_REASON_ISOLD");
			[[level.ex_PrecacheString]](&"REDIRECT_TO_NEWSERVER");
			if(level.ex_redirect_hint) [[level.ex_PrecacheString]](&"REDIRECT_HINT_ADDTOFAV");
		}

		if(level.ex_redirect_reason == 3) [[level.ex_PrecacheString]](&"REDIRECT_REASON_ISSERVICED");

		if(level.ex_redirect_priority)
		{
			[[level.ex_PrecacheString]](&"REDIRECT_REASON_CLANPRIORITY");
			[[level.ex_PrecacheString]](&"REDIRECT_CLAN_FREEUPSLOT");
			[[level.ex_PrecacheString]](&"REDIRECT_CLAN_ABORTED");
			[[level.ex_PrecacheString]](&"REDIRECT_CLAN_PLEASEWAIT");
			[[level.ex_PrecacheString]](&"REDIRECT_CLAN_CONTINUE");

			if(level.ex_redirect_hint)
			{
				[[level.ex_PrecacheString]](&"REDIRECT_HINT_SORRY");
				[[level.ex_PrecacheString]](&"REDIRECT_HINT_PRIORITY");
				[[level.ex_PrecacheString]](&"REDIRECT_HINT_EXTREME");
			}
		}
	}

	// round based game type round number text
	if(level.ex_roundbased || level.ex_currentgt == "lib")
	{
		[[level.ex_PrecacheString]](&"MISC_ROUNDNUMBER");
		[[level.ex_PrecacheString]](&"MISC_LASTROUND");
	}

	// halftime
	if(level.ex_swapteams)
	{
		if(level.ex_roundbased) [[level.ex_PrecacheString]](&"MISC_SWAPTEAM");
		else
		{
			[[level.ex_PrecacheString]](&"MISC_CLOCK_1H");
			[[level.ex_PrecacheString]](&"MISC_CLOCK_2H");
			[[level.ex_PrecacheString]](&"MISC_HALFTIME");
		}
		[[level.ex_PrecacheString]](&"MISC_SWAPTEAM_SWITCH");
		[[level.ex_PrecacheString]](&"MISC_SWAPTEAM_CONTINUE");
	}

	// overtime
	if(level.ex_overtime)
	{
		[[level.ex_PrecacheString]](&"MISC_CLOCK_OT");
		[[level.ex_PrecacheString]](&"MISC_OVERTIME");
		[[level.ex_PrecacheString]](&"MISC_OVERTIME_MINUTES");
		if(level.ex_currentgt == "ctf" || level.ex_currentgt == "ctfb") [[level.ex_PrecacheString]](&"MISC_OVERTIME_FIRSTCAP");
		if(level.ex_overtime_lastman)
		{
			[[level.ex_PrecacheString]](&"MISC_OVERTIME_LASTTEAM");
			[[level.ex_PrecacheString]](&"MISC_OVERTIME_WAIT");
		}
	}

	if(level.ex_stbd)
	{
		// initializing
		[[level.ex_PrecacheString]](&"MISC_INITIALIZING");

		// statsboard title
		[[level.ex_PrecacheString]](&"STATSBOARD_TITLE");
		[[level.ex_PrecacheString]](&"STATSBOARD_HOWTO");
		[[level.ex_PrecacheString]](&"STATSBOARD_TIMELEFT");
		[[level.ex_PrecacheString]](&"STATSBOARD_PLAYERLEFT");

		// statsboard kills and deaths categories
		if(level.ex_stbd_kd)
		{
			[[level.ex_PrecacheString]](&"STATSBOARD_HEADER_KD");
			[[level.ex_PrecacheString]](&"STATSBOARD_KILLS_DEATHS");
			[[level.ex_PrecacheString]](&"STATSBOARD_GRENADES");
			if(level.ex_tweapon) [[level.ex_PrecacheString]](&"STATSBOARD_TRIPWIRES");
			[[level.ex_PrecacheString]](&"STATSBOARD_HEADSHOTS");
			[[level.ex_PrecacheString]](&"STATSBOARD_BASHES");
			[[level.ex_PrecacheString]](&"STATSBOARD_SNIPERS");
			[[level.ex_PrecacheString]](&"STATSBOARD_KNIVES");
			if(level.ex_ranksystem || level.ex_mortars == 2) [[level.ex_PrecacheString]](&"STATSBOARD_MORTARS");
			if(level.ex_ranksystem || level.ex_artillery == 2) [[level.ex_PrecacheString]](&"STATSBOARD_ARTILLERY");
			if(level.ex_ranksystem || level.ex_planes == 3) [[level.ex_PrecacheString]](&"STATSBOARD_AIRSTRIKES");
			if(level.ex_ranksystem) [[level.ex_PrecacheString]](&"STATSBOARD_NAPALM");
			[[level.ex_PrecacheString]](&"STATSBOARD_PANZERS");
			if(level.ex_landmines) [[level.ex_PrecacheString]](&"STATSBOARD_LANDMINES");
			[[level.ex_PrecacheString]](&"STATSBOARD_FIRENADES");
			[[level.ex_PrecacheString]](&"STATSBOARD_GASNADES");
			[[level.ex_PrecacheString]](&"STATSBOARD_FLAMETHROWERS");
			[[level.ex_PrecacheString]](&"STATSBOARD_SATCHELCHARGES");
			if(level.ex_gunship || level.ex_gunship_special) [[level.ex_PrecacheString]](&"STATSBOARD_GUNSHIP");
			[[level.ex_PrecacheString]](&"STATSBOARD_SPAM_KILLS");
			[[level.ex_PrecacheString]](&"STATSBOARD_TEAM_KILLS");
			[[level.ex_PrecacheString]](&"STATSBOARD_FALLING_DEATHS");
			[[level.ex_PrecacheString]](&"STATSBOARD_MINEFIELD_DEATHS");
			[[level.ex_PrecacheString]](&"STATSBOARD_SUICIDE_DEATHS");
			//[[level.ex_PrecacheString]](&"STATSBOARD_SPAWN");
		}

		// statsboard score, efficiency and bonus points
		if(level.ex_stbd_se)
		{
			if(level.ex_flagbased)
			{
				[[level.ex_PrecacheString]](&"STATSBOARD_HEADER_FL");
				[[level.ex_PrecacheString]](&"STATSBOARD_FLAGS");
			}
			[[level.ex_PrecacheString]](&"STATSBOARD_HEADER_SE");
			[[level.ex_PrecacheString]](&"STATSBOARD_SCORE_EFFICIENCY");
			[[level.ex_PrecacheString]](&"STATSBOARD_HEADER_BP");
			[[level.ex_PrecacheString]](&"STATSBOARD_BONUS");
		}
	}

	// sprint
	if(level.ex_sprint && level.ex_sprinthudhint)
	{
		[[level.ex_PrecacheString]](&"SPRINT_HINT");
	}

	if(level.ex_ranksystem && level.ex_rank_wmdtype)
	{
		[[level.ex_PrecacheString]](&"WMD_MORTAR_HINT");
		[[level.ex_PrecacheString]](&"WMD_ARTILLERY_HINT");
		[[level.ex_PrecacheString]](&"WMD_AIRSTRIKE_HINT");
		[[level.ex_PrecacheString]](&"WMD_NAPALM_HINT");
	}

	if((level.ex_ranksystem && level.ex_rank_wmdtype) || level.ex_gunship)
	{
		[[level.ex_PrecacheString]](&"WMD_GUNSHIP_HINT");
		[[level.ex_PrecacheString]](&"WMD_ACTIVATE_HINT");
	}

	if(level.ex_medicsystem)
	{
		[[level.ex_PrecacheString]](&"FIRSTAID_MEDI");
		[[level.ex_PrecacheString]](&"FIRSTAID_DISABLED");
	}

	// tripwire messages
	if(level.ex_tweapon)
	{
		[[level.ex_PrecacheString]](&"TRIPWIRE_CHOOSE_GRENADE");
		[[level.ex_PrecacheString]](&"TRIPWIRE_HOLD_COMBO");
		[[level.ex_PrecacheString]](&"TRIPWIRE_HOLD_SMOKE");
		[[level.ex_PrecacheString]](&"TRIPWIRE_HOLD_FRAG");
		[[level.ex_PrecacheString]](&"TRIPWIRE_RELEASE_CANCEL");
		[[level.ex_PrecacheString]](&"TRIPWIRE_DEFUSE");
		[[level.ex_PrecacheString]](&"TRIPWIRE_PLANT");
		[[level.ex_PrecacheString]](&"TRIPWIRE_DEFUSING");
		[[level.ex_PrecacheString]](&"TRIPWIRE_PLANTING");
		[[level.ex_PrecacheString]](&"TRIPWIRE_ACTIVATE");
	}

	if(level.ex_svrmsg && level.ex_svrmsg_info && !level.ex_mapvote)
	{
		// pre-cache strings for map announcement system
		if(level.ex_svrmsg_info == 1 || level.ex_svrmsg_info == 3) [[level.ex_PrecacheString]](&"MAPROTATION_NEXT_MAP");
		if(level.ex_svrmsg_info >= 2)
		{
			[[level.ex_PrecacheString]](&"MAPROTATION_CUSTOM_NEXT");
			[[level.ex_PrecacheString]](&"MAPROTATION_NEXT_GT");
		}
		if(level.ex_svrmsg_rotation) [[level.ex_PrecacheString]](&"MAPROTATION_TITLE");
	}

	if(level.ex_mapvote)
	{
		// initializing
		[[level.ex_PrecacheString]](&"MISC_INITIALIZING");

		// pre-cache strings for extended map voting system
		[[level.ex_PrecacheString]](&"MAPVOTE_TITLE");
		[[level.ex_PrecacheString]](&"MAPVOTE_HEADERS");
		[[level.ex_PrecacheString]](&"MAPVOTE_HOWTO");
		[[level.ex_PrecacheString]](&"MAPVOTE_TIMELEFT");
		[[level.ex_PrecacheString]](&"MAPVOTE_INPROGRESS");
		[[level.ex_PrecacheString]](&"MAPVOTE_NOTALLOWED");
		[[level.ex_PrecacheString]](&"MAPVOTE_PLEASEWAIT");
		[[level.ex_PrecacheString]](&"MAPVOTE_PAGE");
		[[level.ex_PrecacheString]](&"MAPVOTE_WINNER");
		if(level.ex_mapvotereplay) [[level.ex_PrecacheString]](&"MAPVOTE_REPLAY");
	}

	if((level.ex_mapvote && level.ex_mapvotemode < 4) || (level.ex_svrmsg && level.ex_svrmsg_info && level.ex_svrmsg_rotation))
	{
		// pre-cache game type abbreviations for extended map voting system
		[[level.ex_PrecacheString]](&"MPUI_CHQ");
		[[level.ex_PrecacheString]](&"MPUI_CNQ");
		[[level.ex_PrecacheString]](&"MPUI_CTF");
		[[level.ex_PrecacheString]](&"MPUI_CTFB");
		[[level.ex_PrecacheString]](&"MPUI_DM");
		[[level.ex_PrecacheString]](&"MPUI_DOM");
		[[level.ex_PrecacheString]](&"MPUI_ESD");
		[[level.ex_PrecacheString]](&"MPUI_FT");
		[[level.ex_PrecacheString]](&"MPUI_HM");
		[[level.ex_PrecacheString]](&"MPUI_HQ");
		[[level.ex_PrecacheString]](&"MPUI_HTF");
		[[level.ex_PrecacheString]](&"MPUI_IHTF");
		[[level.ex_PrecacheString]](&"MPUI_LIB");
		[[level.ex_PrecacheString]](&"MPUI_LMS");
		[[level.ex_PrecacheString]](&"MPUI_LTS");
		[[level.ex_PrecacheString]](&"MPUI_ONS");
		[[level.ex_PrecacheString]](&"MPUI_RBCNQ");
		[[level.ex_PrecacheString]](&"MPUI_RBCTF");
		[[level.ex_PrecacheString]](&"MPUI_SD");
		[[level.ex_PrecacheString]](&"MPUI_TDM");
		[[level.ex_PrecacheString]](&"MPUI_VIP");
		[[level.ex_PrecacheString]](&"MPUI_TKOTH");
		[[level.ex_PrecacheString]](&"MPUI_UNKNOWN_GT_SHORT");
	}

	if((level.ex_mapvote && level.ex_mapvotemode >= 4) || (level.ex_svrmsg && level.ex_svrmsg_info >= 2))
	{
		// pre-cache game types for extended map voting system
		[[level.ex_PrecacheString]](&"MPUI_CLASSIC_HEADQUARTERS");
		[[level.ex_PrecacheString]](&"MPUI_CONQUEST");
		[[level.ex_PrecacheString]](&"MPUI_CAPTURE_THE_FLAG");
		[[level.ex_PrecacheString]](&"MPUI_CAPTURE_THE_FLAG_BACK");
		[[level.ex_PrecacheString]](&"MPUI_DEATHMATCH");
		[[level.ex_PrecacheString]](&"MPUI_DOMINATION");
		[[level.ex_PrecacheString]](&"MPUI_ENHANCED_SD");
		[[level.ex_PrecacheString]](&"MPUI_FREEZETAG");
		[[level.ex_PrecacheString]](&"MPUI_HITMAN");
		[[level.ex_PrecacheString]](&"MPUI_HEADQUARTERS");
		[[level.ex_PrecacheString]](&"MPUI_HOLD_THE_FLAG");
		[[level.ex_PrecacheString]](&"MPUI_I_HOLD_THE_FLAG");
		[[level.ex_PrecacheString]](&"MPUI_LIBERATION");
		[[level.ex_PrecacheString]](&"MPUI_LAST_MAN_STANDING");
		[[level.ex_PrecacheString]](&"MPUI_LAST_TEAM_STANDING");
		[[level.ex_PrecacheString]](&"MPUI_ONSLAUGHT");
		[[level.ex_PrecacheString]](&"MPUI_ROUNDBASED_CNQ");
		[[level.ex_PrecacheString]](&"MPUI_ROUNDBASED_CTF");
		[[level.ex_PrecacheString]](&"MPUI_SEARCH_AND_DESTROY");
		[[level.ex_PrecacheString]](&"MPUI_TEAM_DEATHMATCH");
		[[level.ex_PrecacheString]](&"MPUI_VERY_IMPORTANT_PERSON");
		[[level.ex_PrecacheString]](&"MPUI_TEAM_KING_OF_THE_HILL");
		[[level.ex_PrecacheString]](&"MPUI_UNKNOWN_GT_LONG");
	}

	if(level.ex_spwn_time)
	{
		[[level.ex_PrecacheString]](&"SPAWNPROTECTION_TIME");
		[[level.ex_PrecacheString]](&"SPAWNPROTECTION_RANGE");
	}

	// sinbin: teamkill punishment
	if(level.ex_sinbin)
	{
		[[level.ex_PrecacheString]](&"SINBIN_FREEZE");
		[[level.ex_PrecacheString]](&"SINBIN_FREEFALL");
	}

	// spectator music control messages
	if(level.ex_specmusic)
	{
		[[level.ex_PrecacheString]](&"MISC_MELEE_CHANGE_MUSIC");
		[[level.ex_PrecacheString]](&"MISC_MUSIC_CHNG");
	}

	// range finder
	if(level.ex_rangefinder)
	{
		if(level.ex_rangefinder_units == 1) [[level.ex_PrecacheString]](&"MISC_RANGE");
			else [[level.ex_PrecacheString]](&"MISC_RANGE2");
	}

	// unfixed turrets
	if(level.ex_turrets > 1)
	{
		[[level.ex_PrecacheString]](&"TURRET_MELEE_TO_PICKUP");
		[[level.ex_PrecacheString]](&"TURRET_MELEE_TO_PLANT");
		[[level.ex_PrecacheString]](&"TURRET_DEPLANT");
		[[level.ex_PrecacheString]](&"TURRET_PLANTING");
		[[level.ex_PrecacheString]](&"TURRET_USE_SHOW_ICON");
		[[level.ex_PrecacheString]](&"TURRET_TOO_CLOSE");
		[[level.ex_PrecacheString]](&"TURRET_TOO_FAR");
	}

	// landmines
	if(level.ex_landmines)
	{
		[[level.ex_PrecacheString]](&"LANDMINES_PLANTING");
		[[level.ex_PrecacheString]](&"LANDMINES_DEFUSING");
		[[level.ex_PrecacheString]](&"LANDMINES_DEFUSE");
	}

	// retreat monitor
	if((level.ex_flag_retreat & 4) == 4)
	{
		[[level.ex_PrecacheString]](&"MISC_FLAG_RETREAT");
		if((level.ex_flag_retreat & 16) == 16) [[level.ex_PrecacheString]](&"MISC_FLAG_BRINGIN");
	}

	// kill confirmed mode
	if(level.ex_kc)
	{
		if((level.ex_kc_confirm_msg & 2) == 2)
		{
			[[level.ex_PrecacheString]](&"MISC_KCA_HUD");
			if(level.ex_kc > 1)
			{
				[[level.ex_PrecacheString]](&"MISC_KCC_HUD");
				[[level.ex_PrecacheString]](&"MISC_KCA_PROXY_HUD");
			}
		}
		if((level.ex_kc_confirm_msg & 8) == 8) [[level.ex_PrecacheString]](&"MISC_KCV_HUD");

		if((level.ex_kc_denied_msg & 2) == 2)
		{
			[[level.ex_PrecacheString]](&"MISC_KDV_HUD");
			if(level.ex_kc_denied > 2)
			{
				[[level.ex_PrecacheString]](&"MISC_KDC_HUD");
				[[level.ex_PrecacheString]](&"MISC_KDV_PROXY_HUD");
			}
		}
		if((level.ex_kc_denied_msg & 8) == 8) [[level.ex_PrecacheString]](&"MISC_KDA_HUD");
	}

	// pre-cache weapon modes for extended map voting system
	if(level.ex_mapvote && level.ex_mapvoteweaponmode)
	{
		wm_array = strtok(tolower(level.ex_mapvoteweaponmode_allow), " ");
		if(isDefined(wm_array) && wm_array.size)
		{
			level.weaponmodes = [];
			level.weaponmodenames = [];

			// precache regular weapon mode string
			weaponmodes = [];
			for(i = 0; i < wm_array.size; i++)
			{
				if(!isDefined(level.weaponmodes[wm_array[i]]))
				{
					index = precacheWeaponmode(wm_array[i]);
					if(index != -1) weaponmodes[weaponmodes.size] = index;
				}
				else weaponmodes[weaponmodes.size] = level.weaponmodes[wm_array[i]].index;
			}

			if(weaponmodes.size)
			{
				level.wmodes = "";
				for(j = 0; j < weaponmodes.size; j++)
				{
					level.wmodes = level.wmodes + weaponmodes[j];
					if(j < (weaponmodes.size - 1)) level.wmodes = level.wmodes + " ";
				}
				//logprint("MAPVOTE: Weapon modes string converted into ID string: " + level.wmodes + ".\n");

				// precache weapon mode strings defined in map voting list
				if(level.ex_mapvotemode >= 4 && isDefined(level.ex_maps))
				{
					for(i = 0; i < level.ex_maps.size; i++)
					{
						if(isDefined(level.ex_maps[i].weaponmode))
						{
							wm_array = strtok(tolower(level.ex_maps[i].weaponmode), " ");
							if(isDefined(wm_array) && wm_array.size)
							{
								weaponmodes = [];
								for(j = 0; j < wm_array.size; j++)
								{
									if(!isDefined(level.weaponmodes[wm_array[j]]))
									{
										index = precacheWeaponmode(wm_array[j]);
										if(index != -1) weaponmodes[weaponmodes.size] = index;
									}
									else weaponmodes[weaponmodes.size] = level.weaponmodes[wm_array[j]].index;
								}

								if(weaponmodes.size)
								{
									level.ex_maps[i].wmodes = "";
									for(j = 0; j < weaponmodes.size; j++)
									{
										level.ex_maps[i].wmodes = level.ex_maps[i].wmodes + weaponmodes[j];
										if(j < (weaponmodes.size - 1)) level.ex_maps[i].wmodes = level.ex_maps[i].wmodes + " ";
									}
									//logprint("MAPVOTE: Weapon modes string for map " + level.ex_maps[i].mapname + " converted into ID string: " + level.ex_maps[i].wmodes + ".\n");
								}
								else logprint("MAPVOTE: Map " + level.ex_maps[i].mapname + " has no valid weapon modes; using default instead.\n");
							}
							else logprint("MAPVOTE: Map " + level.ex_maps[i].mapname + " has an empty weapon modes string; using default instead.\n");
						}
					}
				}
			}
			else
			{
				level.ex_mapvoteweaponmode = 0;
				logprint("MAPVOTE: No valid weapon modes found; weapon mode voting disabled.\n");
			}
		}
		else
		{
			level.ex_mapvoteweaponmode = 0;
			logprint("MAPVOTE: Weapon modes string empty; weapon mode voting disabled.\n");
		}
	}

	// pre-cache map long names for extended map voting system and map rotation info
	if(level.ex_mapvote || (level.ex_svrmsg && (level.ex_svrmsg_info == 1 || level.ex_svrmsg_info == 3)) )
	{
		for(i = 0; i < level.ex_maps.size; i++) [[level.ex_PrecacheString]](level.ex_maps[i].loclname);
	}
}

precacheWeaponmode(weaponmode)
{
	switch(weaponmode)
	{
		case "team":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 0;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_TEAM";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class1":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 1;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS1";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class2":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 2;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS2";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class3":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 3;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS3";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class4":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 4;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS4";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class5":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 5;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS5";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class6":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 6;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS6";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class7":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 7;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS7";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class8":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 8;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS8";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class9":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 9;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS9";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "class10":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 10;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_CLASS10";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "all":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 11;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_ALL";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "modern":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 12;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass1":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 13;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS1";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass2":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 14;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS2";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass3":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 15;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS3";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass4":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 16;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS4";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass7":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 17;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS7";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass8":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 18;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS8";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "mclass10":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 19;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_MODERN_CLASS10";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "bash":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 20;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_BASH";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "frag":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 21;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_FRAG";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "random":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 99;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_RANDOM";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		case "server":
			index = level.weaponmodenames.size;
			level.weaponmodenames[index] = weaponmode;
			level.weaponmodes[weaponmode] = spawnstruct();
			level.weaponmodes[weaponmode].id = 100;
			level.weaponmodes[weaponmode].loc = &"WEAPONMODE_SERVER";
			level.weaponmodes[weaponmode].index = index;
			[[level.ex_PrecacheString]](level.weaponmodes[weaponmode].loc);
			return(index);
		default:
			logprint("MAPVOTE: Invalid weapon mode <" + weaponmode + "> defined. Please check your weapon mode settings!\n");
			return(-1);
	}
}

precacheshaders()
{
	// generic, used by almost everything
	[[level.ex_PrecacheShader]]("black");
	[[level.ex_PrecacheShader]]("white");

	// crybaby punishment from rcon
	if(level.ex_rcon) [[level.ex_PrecacheShader]]("exg_crybaby");

	// turrets
	if(level.ex_turrets > 1) [[level.ex_PrecacheShader]]("objpoint_star");
	if( (level.ex_turrets && level.ex_turretoverheat) || (level.ex_heli && level.ex_heli_damagehud) ) [[level.ex_PrecacheShader]]("hud_temperature_gauge");

	// landmines
	if(level.ex_landmines)
	{
		[[level.ex_PrecacheShader]]("mtl_weapon_bbetty_hud");
		if(level.ex_landmine_warning) [[level.ex_PrecacheShader]]("killiconsuicide");
	}

	// bullet holes
	if(level.ex_bulletholes)
	{
		[[level.ex_PrecacheShader]]("gfx/custom/bullethit_glass.tga");
		[[level.ex_PrecacheShader]]("gfx/custom/bullethit_glass2.tga");
	}

	// ammo crates
	if(level.ex_amc_perteam && level.ex_amc_compass)
	{
		[[level.ex_PrecacheShader]]("compassping_ammocrate");
	}

	// tripwires
	if(level.ex_tweapon)
	{
		[[level.ex_PrecacheShader]]("hud_us_smokegrenade_C");
		if(level.ex_tweapon_warning) [[level.ex_PrecacheShader]]("killiconsuicide");
	}

	// blood on screen or pop helmet
	if(level.ex_bloodonscreen || level.ex_pophelmet)
	{
		[[level.ex_PrecacheShader]]("gfx/impact/flesh_hit2");
		[[level.ex_PrecacheShader]]("gfx/impact/flesh_hitgib");
	}

	// camper monitor
	if(level.ex_campwarntime || level.ex_campsniper_warntime) [[level.ex_PrecacheShader]]("objpoint_radio");

	// health bar or sprint hud
	if(level.ex_healthbar == 2 || (level.ex_sprint && level.ex_sprinthud))
	{
		[[level.ex_PrecacheShader]]("gfx/hud/hud@health_back.tga");
		[[level.ex_PrecacheShader]]("gfx/hud/hud@health_bar.tga");
	}

	// first aid icon
	if(level.ex_healthbar == 2 || level.ex_medicsystem)
	{
		game["firstaidicon"] = "gfx/hud/hud@health_cross.tga";
		[[level.ex_PrecacheShader]](game["firstaidicon"]);
	}

	// hit blip
	if(level.ex_hitblip) [[level.ex_PrecacheShader]]("gfx/reticle/mg42_cross.tga");

	// wmd hud icons
	if(level.ex_ranksystem)
	{
		game["wmd_mortar_hudicon"] = "wmd_mortars_hudicon";
		game["wmd_artillery_hudicon"] = "wmd_artillery_hudicon";
		game["wmd_airstrike_hudicon"] = "wmd_airstrike_hudicon";
		game["wmd_napalm_hudicon"] = "wmd_napalm_hudicon";

		[[level.ex_PrecacheShader]](game["wmd_mortar_hudicon"]);
		[[level.ex_PrecacheShader]](game["wmd_artillery_hudicon"]);
		[[level.ex_PrecacheShader]](game["wmd_airstrike_hudicon"]);
		[[level.ex_PrecacheShader]](game["wmd_napalm_hudicon"]);
	}

	// gunship
	if(level.ex_gunship)
	{
		if(!level.ex_rank_statusicons && !level.ex_classes_statusicons) [[level.ex_PrecacheStatusIcon]]("gunship_statusicon");

		game["wmd_gunship_hudicon"] = "wmd_gunship_hudicon";
		[[level.ex_PrecacheShader]](game["wmd_gunship_hudicon"]);

		if(level.ex_gunship_25mm) [[level.ex_PrecacheShader]]("gunship_overlay_25mm");
		if(level.ex_gunship_40mm) [[level.ex_PrecacheShader]]("gunship_overlay_40mm");
		if(level.ex_gunship_105mm) [[level.ex_PrecacheShader]]("gunship_overlay_105mm");
		if(level.ex_gunship_nuke) [[level.ex_PrecacheShader]]("gunship_overlay_nuke");
		if(level.ex_gunship_grain) [[level.ex_PrecacheShader]]("gunship_overlay_grain");
		if(level.ex_gunship_clock)
		{
			[[level.ex_PrecacheShader]]("hudStopwatch");
			[[level.ex_PrecacheShader]]("hudstopwatchneedle");
		}
	}

	// spawn protection
	if(level.ex_spwn_time)
	{
		game["mod_protect_hudicon"] = "mod_protect_hudicon";
		[[level.ex_PrecacheShader]](game["mod_protect_hudicon"]);
	}

	// arcade shaders
	if(level.ex_arcade_shaders)
	{
		if((level.ex_arcade_shaders & 1) == 1)
		{
			[[level.ex_PrecacheShader]]("x2_dominating");
			[[level.ex_PrecacheShader]]("x2_godlike");
			[[level.ex_PrecacheShader]]("x2_holyshit");
			[[level.ex_PrecacheShader]]("x2_humiliation");
			[[level.ex_PrecacheShader]]("x2_killingspree");
			[[level.ex_PrecacheShader]]("x2_rampage");
			[[level.ex_PrecacheShader]]("x2_slaughter");
			[[level.ex_PrecacheShader]]("x2_unstoppable");
			[[level.ex_PrecacheShader]]("x2_wickedsick");
		}

		if(level.ex_obitladder && (level.ex_arcade_shaders & 2) == 2)
		{
			[[level.ex_PrecacheShader]]("x2_doublekill");
			[[level.ex_PrecacheShader]]("x2_triplekill");
			[[level.ex_PrecacheShader]]("x2_multikill");
			[[level.ex_PrecacheShader]]("x2_megakill");
			[[level.ex_PrecacheShader]]("x2_ultrakill");
			[[level.ex_PrecacheShader]]("x2_monsterkill");
			[[level.ex_PrecacheShader]]("x2_ludicrouskill");
			[[level.ex_PrecacheShader]]("x2_topgun");
		}

		if(level.ex_ranksystem && level.ex_rank_wmdtype && (level.ex_arcade_shaders & 4) == 4)
		{
			[[level.ex_PrecacheShader]]("x2_mortarsunlock");
			[[level.ex_PrecacheShader]]("x2_artilleryunlock");
			[[level.ex_PrecacheShader]]("x2_airstrikeunlock");
			[[level.ex_PrecacheShader]]("x2_napalmunlock");
		}

		gunship_arcade = 0;
		if( (level.ex_gunship == 1 && (level.ex_arcade_shaders & 1) == 1) || (level.ex_gunship == 2 && (level.ex_arcade_shaders & 4) == 4) || (level.ex_gunship == 3 && (level.ex_arcade_shaders & 2) == 2) ) gunship_arcade = 1;
		if(level.ex_specials && level.ex_gunship_special) gunship_arcade = 1;
		if(gunship_arcade)
		{
			[[level.ex_PrecacheShader]]("x2_gunshipunlock");
			if(level.ex_gunship_40mm) [[level.ex_PrecacheShader]]("x2_40mmunlock");
			if(level.ex_gunship_105mm) [[level.ex_PrecacheShader]]("x2_105mmunlock");
			if(level.ex_gunship_nuke) [[level.ex_PrecacheShader]]("x2_nukeunlock");
		}

		if((level.ex_arcade_shaders & 16) == 16)
		{
			[[level.ex_PrecacheShader]]("x2_headshot");
			if(level.ex_firstblood) [[level.ex_PrecacheShader]]("x2_firstblood");
		}
	}

	if(level.ex_livestats || (level.ex_overtime && level.ex_overtime_lastman))
	{
		// game["hudicon_x"] icons are precached by maps\mp\gametypes\_hud_teamscore.gsc
		[[level.ex_precacheShader]]("hud_status_alive");
		[[level.ex_precacheShader]]("hud_status_dead");
	}
}

precachemodels()
{
	// mbots
	if(level.ex_mbot && level.ex_mbot_dev)
	{
		[[level.ex_PrecacheModel]]("xmodel/marker_glow0");
		[[level.ex_PrecacheModel]]("xmodel/marker_glow1");
		[[level.ex_PrecacheModel]]("xmodel/marker_glow2");

		[[level.ex_PrecacheModel]]("xmodel/marker_camp0");
		[[level.ex_PrecacheModel]]("xmodel/marker_climb0");
		[[level.ex_PrecacheModel]]("xmodel/marker_fall0");
		[[level.ex_PrecacheModel]]("xmodel/marker_jump0");
		[[level.ex_PrecacheModel]]("xmodel/marker_junction0");
		[[level.ex_PrecacheModel]]("xmodel/marker_mantle_up0");
		[[level.ex_PrecacheModel]]("xmodel/marker_mantle_over0");
		[[level.ex_PrecacheModel]]("xmodel/marker_nade0");
		[[level.ex_PrecacheModel]]("xmodel/marker_waypoint0");
		[[level.ex_PrecacheModel]]("xmodel/marker_wpstart0");
	}

	if(level.ex_medicsystem && level.ex_firstaid_drop)
	{
		[[level.ex_PrecacheModel]]("xmodel/health_small");
		[[level.ex_PrecacheModel]]("xmodel/health_medium");
		[[level.ex_PrecacheModel]]("xmodel/health_large");
	}

	if(level.ex_artillery || level.ex_cmdmonitor || level.ex_mortars || level.ex_planes ||
	  (level.ex_ranksystem && level.ex_rank_wmdtype != 0) ||
	  (level.ex_amc_perteam && level.ex_amc_chutein))
	{
		[[level.ex_PrecacheModel]]("xmodel/vehicle_stuka_flying");
		[[level.ex_PrecacheModel]]("xmodel/vehicle_spitfire_flying");
		[[level.ex_PrecacheModel]]("xmodel/vehicle_p51_mustang");
		[[level.ex_PrecacheModel]]("xmodel/vehicle_condor");
		[[level.ex_PrecacheModel]]("xmodel/vehicle_mebelle");
		[[level.ex_PrecacheModel]]("xmodel/prop_stuka_bomb");
	}

	// parachutes
	if(level.ex_parachutes || ((level.ex_gunship || level.ex_gunship_special) && level.ex_gunship_eject))
	{
		if(level.ex_modern_weapons)
		{
			game["chute_player_axis"] = "xmodel/vehicle_parachute_glide_grey";
			game["chute_player_allies"] = "xmodel/vehicle_parachute_glide_brown";
		}
		else
		{
			game["chute_player_axis"] = "xmodel/vehicle_parachute_cone_grey";
			game["chute_player_allies"] = "xmodel/vehicle_parachute_cone_brown";
		}

		[[level.ex_PrecacheModel]](game["chute_player_axis"]);
		[[level.ex_PrecacheModel]](game["chute_player_allies"]);
	}

	if(level.ex_amc_perteam && level.ex_amc_chutein)
	{
		if(!level.ex_amc_chutein_neutral)
		{
			game["chute_cargo_axis"] = "xmodel/vehicle_parachute_drop_grey";
			game["chute_cargo_allies"] = "xmodel/vehicle_parachute_drop_brown";
			[[level.ex_PrecacheModel]](game["chute_cargo_axis"]);
			[[level.ex_PrecacheModel]](game["chute_cargo_allies"]);
		}
		else
		{
			game["chute_cargo_neutral"] = "xmodel/vehicle_parachute_drop_camo";
			[[level.ex_PrecacheModel]](game["chute_cargo_neutral"]);
		}
	}

	// model changer
	if(level.ex_cmdmonitor && level.ex_cmdmonitor_models)
	{
		[[level.ex_PrecacheModel]]("xmodel/furniture_bedmattress1");
		[[level.ex_PrecacheModel]]("xmodel/furniture_bathtub");
		[[level.ex_PrecacheModel]]("xmodel/furniture_toilet");
		[[level.ex_PrecacheModel]]("xmodel/prop_barrel_benzin");
		[[level.ex_PrecacheModel]]("xmodel/prop_tombstone1");
		[[level.ex_PrecacheModel]]("xmodel/tree_grey_oak_sm_a");
	}

	// knife
	if(level.ex_wepo_class == 10 || (level.ex_wepo_sidearm && level.ex_wepo_sidearm_type))
	{
		if(level.ex_modern_weapons) [[level.ex_PrecacheModel]]("xmodel/viewmodel_modern_knife");
			else [[level.ex_PrecacheModel]]("xmodel/viewmodel_knife");
	}

	// ammocrates
	if(level.ex_amc_perteam) [[level.ex_PrecacheModel]]("xmodel/ammocrate_rearming");

	// unfixed turrets
	if(level.ex_turrets > 1)
	{
		[[level.ex_PrecacheModel]]("xmodel/weapon_30cal");
		[[level.ex_PrecacheModel]]("xmodel/weapon_mg42");
	}

	// landmines
	if(level.ex_landmines) [[level.ex_PrecacheModel]]("xmodel/weapon_bbetty");

	// binoc aimer, gunship, flag drop, sinbin and flamethrower
	[[level.ex_PrecacheModel]]("xmodel/tag_origin");

	// gunship
	if(level.ex_gunship) [[level.ex_PrecacheModel]]("xmodel/vehicle_condor");

	// kill confirmed
	if(level.ex_kc)
	{
		if(level.ex_teamplay)
		{
			switch(level.ex_kc_color_axis)
			{
				case 0: game["dogtag_axis"] = "xmodel/dogtag_blue"; break;
				case 1: game["dogtag_axis"] = "xmodel/dogtag_brass"; break;
				case 2: game["dogtag_axis"] = "xmodel/dogtag_gold"; break;
				case 3: game["dogtag_axis"] = "xmodel/dogtag_green"; break;
				case 4: game["dogtag_axis"] = "xmodel/dogtag_red"; break;
				default: game["dogtag_axis"] = "xmodel/dogtag_silver";
			}
			[[level.ex_PrecacheModel]](game["dogtag_axis"]);
			switch(level.ex_kc_color_allies)
			{
				case 0: game["dogtag_allies"] = "xmodel/dogtag_blue"; break;
				case 1: game["dogtag_allies"] = "xmodel/dogtag_brass"; break;
				case 2: game["dogtag_allies"] = "xmodel/dogtag_gold"; break;
				case 3: game["dogtag_allies"] = "xmodel/dogtag_green"; break;
				case 4: game["dogtag_allies"] = "xmodel/dogtag_red"; break;
				default: game["dogtag_allies"] = "xmodel/dogtag_silver";
			}
			[[level.ex_PrecacheModel]](game["dogtag_allies"]);
		}
		else
		{
			switch(level.ex_kc_color_dm)
			{
				case 0: game["dogtag_axis"] = "xmodel/dogtag_blue"; break;
				case 1: game["dogtag_axis"] = "xmodel/dogtag_brass"; break;
				case 2: game["dogtag_axis"] = "xmodel/dogtag_gold"; break;
				case 3: game["dogtag_axis"] = "xmodel/dogtag_green"; break;
				case 4: game["dogtag_axis"] = "xmodel/dogtag_red"; break;
				default: game["dogtag_axis"] = "xmodel/dogtag_silver";
			}
			[[level.ex_PrecacheModel]](game["dogtag_axis"]);
			game["dogtag_allies"] = game["dogtag_axis"];
		}
	}
}

precacheheadicons()
{
	if(level.ex_spwn_time) [[level.ex_PrecacheHeadIcon]](game["headicon_protect"]);

	if(level.ex_rcon && level.ex_crybaby)
	{
		game["headicon_crybaby"] = "headicon_crybaby";
		[[level.ex_PrecacheHeadIcon]](game["headicon_crybaby"]);
	}
}

postmapload_precachestrings()
{
	if(level.ex_ranksystem && level.ex_rank_hudicons == 2)
	{
		switch(game["allies"])
		{
			case "american":
			{
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_7"); // General
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_6"); // Colonel
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_5"); // Major
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_4"); // Captain
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_3"); // Lieutenant
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_2"); // Sergeant
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_1"); // Corporal
				[[level.ex_PrecacheString]](&"RANK_AMERICAN_0"); // Private
				break;
			}	
				
			case "british":
			{
				[[level.ex_PrecacheString]](&"RANK_BRITISH_7"); // General
				[[level.ex_PrecacheString]](&"RANK_BRITISH_6"); // Colonel
				[[level.ex_PrecacheString]](&"RANK_BRITISH_5"); // Major
				[[level.ex_PrecacheString]](&"RANK_BRITISH_4"); // Captain
				[[level.ex_PrecacheString]](&"RANK_BRITISH_3"); // Lieutenant
				[[level.ex_PrecacheString]](&"RANK_BRITISH_2"); // Sergeant
				[[level.ex_PrecacheString]](&"RANK_BRITISH_1"); // Corporal
				[[level.ex_PrecacheString]](&"RANK_BRITISH_0"); // Private
				break;
			}
	
			default:
			{
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_7"); // General-Poruchik
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_6"); // Polkovnik
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_5"); // Mayor
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_4"); // Kapitan
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_3"); // Leytenant
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_2"); // Podpraporshchik
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_1"); // Kapral
				[[level.ex_PrecacheString]](&"RANK_RUSSIAN_0"); // Soldat
				break;
			}
		}

		[[level.ex_PrecacheString]](&"RANK_GERMAN_7"); // General
		[[level.ex_PrecacheString]](&"RANK_GERMAN_6"); // Oberst
		[[level.ex_PrecacheString]](&"RANK_GERMAN_5"); // Major
		[[level.ex_PrecacheString]](&"RANK_GERMAN_4"); // Hauptmann
		[[level.ex_PrecacheString]](&"RANK_GERMAN_3"); // Leutnant
		[[level.ex_PrecacheString]](&"RANK_GERMAN_2"); // Unterfeldwebel
		[[level.ex_PrecacheString]](&"RANK_GERMAN_1"); // Unteroffizier
		[[level.ex_PrecacheString]](&"RANK_GERMAN_0"); // Grenadier

		[[level.ex_PrecacheString]](&"RANK_RANK");
	}

	if(level.ex_amc_perteam)
	{
		[[level.ex_PrecacheString]](&"AMMOCRATE_REARMING_WEAPONS");
		[[level.ex_PrecacheString]](&"AMMOCRATE_REARMING_GRENADES");
		if(level.ex_medicsystem) [[level.ex_PrecacheString]](&"AMMOCRATE_REARMING_FIRSTAID");

 		if(level.ex_amc_msg >= 2)
		{
			switch(game["allies"])
			{
				case "american": [[level.ex_PrecacheString]](&"AMMOCRATE_DENY_AMERICAN"); break;
				case "british": [[level.ex_PrecacheString]](&"AMMOCRATE_DENY_BRITISH"); break;
				default: [[level.ex_PrecacheString]](&"AMMOCRATE_DENY_RUSSIAN"); break;
			}

			[[level.ex_PrecacheString]](&"AMMOCRATE_DENY_GERMAN");
			[[level.ex_PrecacheString]](&"AMMOCRATE_ACTIVATE");
		}
	}
}

postmapload_precacheshaders()
{
	// tripwires
	if(level.ex_tweapon)
	{
		switch(game["allies"])
		{
			case "american": grenadeicon = "gfx/icons/hud@us_grenade_C.tga"; break;
			case "british": grenadeicon = "gfx/icons/hud@british_grenade_C.tga"; break;
			default: grenadeicon = "gfx/icons/hud@russian_grenade_C.tga"; break;
		}

		[[level.ex_precacheShader]](grenadeicon);
		[[level.ex_PrecacheShader]]("gfx/icons/hud@steilhandgrenate_C.tga");

		if(level.ex_firenades || level.ex_smoke[game["axis"]] == 7 || level.ex_smoke[game["allies"]] == 7)
			[[level.ex_PrecacheShader]]("gfx/icons/hud@incenhandgrenade_c.tga");

		if(level.ex_gasnades || level.ex_smoke[game["axis"]] == 8 || level.ex_smoke[game["allies"]] == 8)
			[[level.ex_PrecacheShader]]("gas_grenade");

		if(level.ex_satchelcharges || level.ex_smoke[game["axis"]] == 9 || level.ex_smoke[game["allies"]] == 9)
			[[level.ex_PrecacheShader]]("gfx/icons/hud@satchel_charge1.tga");
	}

	// winner announcement
	if(level.ex_announcewinner)
	{
		switch(game["allies"])
		{
			case "american":
				game["winner_draw"] = "x2flag_german_american";
				break;
			case "british":
				game["winner_draw"] = "x2flag_german_british";
				break;
			default:
				game["winner_draw"] = "x2flag_german_russian";
				break;
		}

		game["winner_allies"] = "x2flag_" + game["allies"];
		game["winner_axis"] = "x2flag_german";

		[[level.ex_PrecacheShader]](game["winner_draw"]);
		[[level.ex_PrecacheShader]](game["winner_allies"]);
		[[level.ex_PrecacheShader]](game["winner_axis"]);
	}
}

postmapload_loadfx()
{
	// generic explosion effects for scriptedfx (postmapload because of nade monitor)
	if(level.ex_nademonitor || level.ex_artillery || level.ex_cmdmonitor || level.ex_mortars || level.ex_planes || level.ex_landmines || level.ex_heli || level.ex_ranksystem)
	{
		level.ex_effect["explosion_beach"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_beach.efx");
		level.ex_effect["explosion_concrete"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_concrete.efx");
		level.ex_effect["explosion_dirt"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_dirt.efx");
		level.ex_effect["explosion_snow"] = [[level.ex_PrecacheEffect]]("fx/explosions/grenadeExp_snow.efx");
		level.ex_effect["explosion_water"] = [[level.ex_PrecacheEffect]]("fx/explosions/mortarExp_water.efx");
		level.ex_effect["explosion_wood"] = [[level.ex_PrecacheEffect]]("fx/explosions/grenadeExp_wood.efx");
	}

	// flamethrower
	loadftfx = false;
	if(isDefined(level.weapons["flamethrower_allies"]) && level.weapons["flamethrower_allies"].precached) loadftfx = true;
	if(isDefined(level.weapons["flamethrower_axis"]) && level.weapons["flamethrower_axis"].precached) loadftfx = true;
	if(loadftfx) level.ex_effect["flamethrower"] = [[level.ex_PrecacheEffect]]("fx/fire/flamethrower.efx");

	// special nades for trips
	if(level.ex_tweapon)
	{
		// smoke
		loadSmokeFX(extreme\_ex_weapons::getSmokeColour(level.ex_smoke[game["allies"]]));
		loadSmokeFX(extreme\_ex_weapons::getSmokeColour(level.ex_smoke["german"]));

		// fire nades
		if(level.ex_firenades || level.ex_smoke[game["axis"]] == 7 || level.ex_smoke[game["allies"]] == 7)
			level.ex_effect["fire"] = [[level.ex_PrecacheEffect]]("fx/impacts/molotov_blast.efx");

		// gas nades
		if(level.ex_gasnades || level.ex_smoke[game["axis"]] == 8 || level.ex_smoke[game["allies"]] == 8)
			level.ex_effect["gas"] = [[level.ex_PrecacheEffect]]("fx/impacts/mustard_blast.efx");

		// satchel charges
		if(level.ex_satchelcharges || level.ex_smoke[game["axis"]] == 9 || level.ex_smoke[game["allies"]] == 9)
			level.ex_effect["satchel"] = [[level.ex_PrecacheEffect]]("fx/explosions/barn_explosion.efx");
	}

	// coldbreath FX
	if(level.ex_currentgt == "ft" || (level.ex_wintermap && level.ex_coldbreathfx))
		level.ex_effect["coldbreathfx"] = [[level.ex_PrecacheEffect]]("fx/misc/cold_breath.efx");

	// weather
	if(level.ex_weather) thread extreme\_ex_weather::init();
}

loadSmokeFX(colour)
{
	switch(colour)
	{
		case "_blue_": level.ex_effect["bluesmoke"] = [[level.ex_PrecacheEffect]]("fx/extreme_smoke/blue_main.efx"); break;
		case "_green_": level.ex_effect["greensmoke"] = [[level.ex_PrecacheEffect]]("fx/extreme_smoke/green_main.efx"); break;
		case "_orange_": level.ex_effect["orangesmoke"] = [[level.ex_PrecacheEffect]]("fx/extreme_smoke/orange_main.efx"); break;
		case "_pink_": level.ex_effect["pinksmoke"] = [[level.ex_PrecacheEffect]]("fx/extreme_smoke/pink_main.efx"); break;
		case "_red_": level.ex_effect["redsmoke"] = [[level.ex_PrecacheEffect]]("fx/extreme_smoke/red_main.efx"); break;
		case "_yellow_": level.ex_effect["yellowsmoke"] = [[level.ex_PrecacheEffect]]("fx/extreme_smoke/yellow_main.efx"); break;
		default: level.ex_effect["greysmoke"] = [[level.ex_PrecacheEffect]]("fx/props/american_smoke_grenade.efx"); break;
	}
}
