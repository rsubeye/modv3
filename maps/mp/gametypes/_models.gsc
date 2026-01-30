
init()
{
	// Make sure the level script has the soldier types defined correctly
	switch(game["allies"])
	{
		case "british":
			if(isDefined(game["british_soldiertype"]))
			{
				if(game["british_soldiertype"] != "africa" && game["british_soldiertype"] != "normandy")
					game["british_soldiertype"] = "normandy";
			}
			else game["british_soldiertype"] = "normandy";
			break;
		case "russian":
			if(isDefined(game["russian_soldiertype"]))
			{
				if(game["russian_soldiertype"] != "coats" && game["russian_soldiertype"] != "padded")
					game["russian_soldiertype"] = "coats";
			}
			else game["russian_soldiertype"] = "coats";
			break;
		case "american":
			game["american_soldiertype"] = "normandy";
			break;
	}

	if(isDefined(game["german_soldiertype"]))
	{
		if(game["german_soldiertype"] != "africa" && game["german_soldiertype"] != "normandy" &&
		   game["german_soldiertype"] != "winterdark" && game["german_soldiertype"] != "winterlight")
			game["german_soldiertype"] = "normandy";
	}
	else game["german_soldiertype"] = "normandy";

	// Workaround for the 127 bones error with mobile turrets
	if(!isDefined(game["allow_mg30"]))
		game["allow_mg30"] = maps\mp\gametypes\_weapons::getWeaponStatus("mobile_30cal");

	if(!isDefined(game["allow_mg42"]))
		game["allow_mg42"] = maps\mp\gametypes\_weapons::getWeaponStatus("mobile_mg42");

	if(level.ex_turrets > 1 || game["allow_mg30"] || game["allow_mg42"])
	{
		if(isDefined(game["russian_soldiertype"]) && game["russian_soldiertype"] == "coats")
			game["russian_soldiertype"] = "padded";
		if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterdark")
			game["german_soldiertype"] = "winterlight";
	}

	// Stock processing
	switch(game["allies"])
	{
		case "british":
			if(isDefined(game["british_soldiertype"]) && game["british_soldiertype"] == "africa")
			{
				mptype\british_africa::precache();
				game["allies_model"] = mptype\british_africa::main;
			}
			else
			{
				mptype\british_normandy::precache();
				game["allies_model"] = mptype\british_normandy::main;
			}
			break;

		case "russian":
			if(isDefined(game["russian_soldiertype"]) && game["russian_soldiertype"] == "padded")
			{
				mptype\russian_padded::precache();
				game["allies_model"] = mptype\russian_padded::main;
			}
			else
			{
				mptype\russian_coat::precache();
				game["allies_model"] = mptype\russian_coat::main;
			}
			break;

		case "american":
		default:
			mptype\american_normandy::precache();
			game["allies_model"] = mptype\american_normandy::main;
	}

	if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterdark")
	{
		mptype\german_winterdark::precache();
		game["axis_model"] = mptype\german_winterdark::main;
	}
	else if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "winterlight")
	{
		mptype\german_winterlight::precache();
		game["axis_model"] = mptype\german_winterlight::main;
	}
	else if(isDefined(game["german_soldiertype"]) && game["german_soldiertype"] == "africa")
	{
		mptype\german_africa::precache();
		game["axis_model"] = mptype\german_africa::main;
	}
	else
	{
		mptype\german_normandy::precache();
		game["axis_model"] = mptype\german_normandy::main;
	}
}

getModel()
{
	self detachAll();

	if(self.pers["team"] == "allies") [[game["allies_model"] ]]();
		else if(self.pers["team"] == "axis") [[game["axis_model"] ]]();

	self.pers["savedmodel"] = saveModel();
}

saveModel()
{
	info["model"] = self.model;
	info["viewmodel"] = self getViewModel();

	if(isDefined(self.hatModel))
		info["ex_hatmodel"] = self.hatModel;

	attachSize = self getAttachSize();
	info["attach"] = [];

	for(i = 0; i < attachSize; i++)
	{
		info["attach"][i]["model"] = self getAttachModelName(i);
		info["attach"][i]["tag"] = self getAttachTagName(i);
		info["attach"][i]["ignoreCollision"] = self getAttachIgnoreCollision(i);
	}

	return info;
}

loadModel(info)
{
	self detachAll();
	self setModel(info["model"]);
	self setViewModel(info["viewmodel"]);

	if(isDefined(info["ex_hatmodel"]))
		self.hatModel = info["ex_hatmodel"];

	attachInfo = info["attach"];
	attachSize = attachInfo.size;

	for(i = 0; i < attachSize; i++)
		self attach(attachInfo[i]["model"], attachInfo[i]["tag"], attachInfo[i]["ignoreCollision"]);
}

dumpModelInfo()
{
	totalparts = 0;
	parts = getNumParts(self.model);
	totalparts += parts;
	for(j = 0; j < parts; j++)
	{
		partname = getPartName(self.model, j);
		logprint("PARTS MAIN: " + self.name + " " + partname + "\n");
	}

	attachments = self getAttachSize();
	for(i = 0; i < attachments; i++)
	{
		model = self getAttachModelName(i);
		parts = getNumParts(model);
		totalparts += parts;
		for(j = 0; j < parts; j++)
		{
			partname = getPartName(model, j);
			logprint("PARTS ATTACHMENT" + i + ": " + self.name + " " + partname + "\n");
		}
	}

	if(level.ex_wepo_secondary)
	{
		if(isDefined(level.weapons[self.pers["weapon1"]]))
		{
			model = getWeaponModel(self.pers["weapon1"]);
			parts = getNumParts(model);
			totalparts += parts;
			for(j = 0; j < parts; j++)
			{
				partname = getPartName(model, j);
				logprint("PARTS WEAPON1: " + self.name + " " + partname + "\n");
			}
		}
		if(isDefined(level.weapons[self.pers["weapon2"]]))
		{
			model = getWeaponModel(self.pers["weapon2"]);
			parts = getNumParts(model);
			totalparts += parts;
			for(j = 0; j < parts; j++)
			{
				partname = getPartName(model, j);
				logprint("PARTS WEAPON2: " + self.name + " " + partname + "\n");
			}
		}
	}
	else
	{
		if(isDefined(level.weapons[self.pers["weapon"]]))
		{
			model = getWeaponModel(self.pers["weapon"]);
			parts = getNumParts(model);
			totalparts += parts;
			for(j = 0; j < parts; j++)
			{
				partname = getPartName(model, j);
				logprint("PARTS WEAPON: " + self.name + " " + partname + "\n");
			}
		}
	}
	logprint("Player " + self.name + " has a total of " + totalparts + " bones\n");
}
