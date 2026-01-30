
queueInit(identifier, maxobjects)
{
	if(!isDefined(identifier)) return;
	if(!isDefined(maxobjects)) maxobjects = 8;
		else if(maxobjects < 2) maxobjects = 2;

	level.ex_objectQ[identifier] = spawnstruct();
	level.ex_objectQ[identifier].maxobjects = maxobjects;
	level.ex_objectQ[identifier].current = 0;
	level.ex_objectQ[identifier].objects = [];

	for(i = 0; i < level.ex_objectQ[identifier].maxobjects; i++)
	{
		level.ex_objectQ[identifier].objects[i] = spawnstruct();
		level.ex_objectQ[identifier].objects[i].entity = undefined;
		level.ex_objectQ[identifier].objects[i].trigger = undefined;
		level.ex_objectQ[identifier].objects[i].trigger_func = undefined;
		level.ex_objectQ[identifier].objects[i].notification = identifier + "_object" + i;
	}
}

queueFlush(identifier)
{
	if(!isDefined(level.ex_objectQ[identifier])) return;

	for(i = 0; i < level.ex_objectQ[identifier].maxobjects; i++)
	{
		object = level.ex_objectQ[identifier].objects[i];
		queueDelObject(object);
	}

	level.ex_objectQ[identifier].current = 0;
}

queuePutObject(entity, identifier, trigger, trigger_radius, trigger_height, trigger_func)
{
	if(!isDefined(entity)) return;
	if(!isDefined(level.ex_objectQ[identifier])) return;
	if(!isDefined(trigger) || !isDefined(trigger_func)) trigger = false;

	index = level.ex_objectQ[identifier].current;
	level.ex_objectQ[identifier].current++;
	if(level.ex_objectQ[identifier].current >= level.ex_objectQ[identifier].maxobjects) level.ex_objectQ[identifier].current = 0;

	object = level.ex_objectQ[identifier].objects[index];
	queueDelObject(object);
	object.entity = entity;
	if(trigger)
	{
		object.trigger = spawn("trigger_radius", entity.origin, 0, trigger_radius, trigger_height);
		object.trigger_func = trigger_func;
		level thread queueMonObject(object);
	}
}

queueDelObject(object)
{
	if(!isDefined(object)) return;

	if(isDefined(object.trigger))
	{
		level notify(object.notification);
		object.trigger delete();
	}
	if(isDefined(object.entity)) object.entity delete();
}

queueMonObject(object)
{
	level endon(object.notification);

	while(true)
	{
		object.trigger waittill("trigger", player);
		if([[object.trigger_func]](player, object.entity) == true)
		{
			object.trigger_func = undefined;
			object.trigger delete();
			object.entity delete();
			break;
		}
	}
}
