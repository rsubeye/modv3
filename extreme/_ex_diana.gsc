
statusDiana()
{
	// ui_diana:
	// 0: diana off, memory off, menu off
	// 1: diana off, memory on, menu enabled
	// 2: diana on, memory off, menu enabled
	// 3: diana on, memory on, menu enabled
	diana_server = level.ex_diana;
	if(!diana_server)
	{
		if(level.ex_diana_memory) diana_server = 1;
	}
	else
	{
		if(level.ex_diana_memory) diana_server = 3;
			else diana_server = 2;
	}
	return(diana_server);
}

toggleDiana()
{
	diana_server = statusDiana();
	if(diana_server)
	{
		if(isDefined(self.pers["diana"])) self.pers["diana"] = undefined;
			else self.pers["diana"] = true;
		self setClientCvar("ui_diana_player", isDefined(self.pers["diana"]));

		if(diana_server == 2 || diana_server == 3)
		{
			self.pers["savedmodel"] = undefined;
			self iprintln(&"MPUI_DIANA_CHANGED");
		}

		if(diana_server == 1 || diana_server == 3)
			self thread extreme\_ex_memory::setMemory("diana", "status", isDefined(self.pers["diana"]), level.ex_tune_delaywrite);
	}
}
