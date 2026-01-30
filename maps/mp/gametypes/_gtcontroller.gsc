
init()
{
	switch(getcvar("g_gametype"))
	{
		case "chq":
			thread maps\mp\gametypes\_ex_chq::main();
			break;
		case "cnq":
			thread maps\mp\gametypes\_ex_cnq::main();
			break;
		case "ctf":
			thread maps\mp\gametypes\_ex_ctf::main();
			break;
		case "ctfb":
			thread maps\mp\gametypes\_ex_ctfb::main();
			break;
		case "dm":
			thread maps\mp\gametypes\_ex_dm::main();
			break;
		case "dom":
			thread maps\mp\gametypes\_ex_dom::main();
			break;
		case "esd":
			thread maps\mp\gametypes\_ex_esd::main();
			break;
		case "ft":
			thread maps\mp\gametypes\_ex_ft::main();
			break;
		case "hm":
			thread maps\mp\gametypes\_ex_hm::main();
			break;
		case "hq":
			thread maps\mp\gametypes\_ex_hq::main();
			break;
		case "htf":
			thread maps\mp\gametypes\_ex_htf::main();
			break;
		case "ihtf":
			thread maps\mp\gametypes\_ex_ihtf::main();
			break;
		case "lib":
			thread maps\mp\gametypes\_ex_lib::main();
			break;
		case "lms":
			thread maps\mp\gametypes\_ex_lms::main();
			break;
		case "lts":
			thread maps\mp\gametypes\_ex_lts::main();
			break;
		case "ons":
			thread maps\mp\gametypes\_ex_ons::main();
			break;
		case "rbcnq":
			thread maps\mp\gametypes\_ex_rbcnq::main();
			break;
		case "rbctf":
			thread maps\mp\gametypes\_ex_rbctf::main();
			break;
		case "sd":
			thread maps\mp\gametypes\_ex_sd::main();
			break;
		case "tdm":
			thread maps\mp\gametypes\_ex_tdm::main();
			break;
		case "tkoth":
			thread maps\mp\gametypes\_ex_tkoth::main();
			break;
		case "vip":
			thread maps\mp\gametypes\_ex_vip::main();
			break;
	}
}
