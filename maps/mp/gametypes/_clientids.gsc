init()
{
	level.clientid = 0;
	[[level.ex_registerCallback]]("onPlayerConnecting", ::onPlayerConnecting);
}

onPlayerConnecting()
{
	self.clientid = level.clientid;
	level.clientid++;
	if(level.clientid == level.MAX_SIGNED_INT) level.clientid = 0;
}
