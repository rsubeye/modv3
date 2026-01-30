triggerOff()
{
	if(!isDefined (self.realOrigin))
		self.realOrigin = self.origin;

	if(self.origin == self.realorigin)
		self.origin += (0, 0, -10000);
}

triggerOn()
{
	if(isDefined (self.realOrigin) )
		self.origin = self.realOrigin;
}

error(msg)
{
	println("^c*ERROR* ", msg);
	wait( [[level.ex_fpstime]](0.05) );
}

vectorScale(vec, scale)
{
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

add_to_array(array, ent)
{
	if(!isDefined(ent))
		return array;
		
	if(!isDefined(array))
		array[0] = ent;
	else
		array[array.size] = ent;
	
	return array;	
}

exploder(num)
{
	num = int(num);
	ents = level._script_exploders;

	for(i = 0; i < ents.size; i++)
	{
		if(!isDefined(ents[i]))
			continue;

		if(ents[i].script_exploder != num)
			continue;

		if(isDefined(ents[i].script_fxid))
			level thread cannon_effect(ents[i]);

		if(isDefined (ents[i].script_sound))
			ents[i] thread exploder_sound();

		if(isDefined(ents[i].targetname))
		{
			if(ents[i].targetname == "exploder")
				ents[i] thread brush_show();
			else
			if((ents[i].targetname == "exploderchunk") || (ents[i].targetname == "exploderchunk visible"))
				ents[i] thread brush_throw();
			else
			if(!isDefined(ents[i].script_fxid))
				ents[i] thread brush_delete();
		}
		else
		if(!isDefined(ents[i].script_fxid))
			ents[i] thread brush_delete();
	}
}

exploder_sound()
{
	if(isDefined(self.script_delay))
		wait( [[level.ex_fpstime]](self.script_delay) );
		
	if(isDefined(level.scr_sound))
		self playSound(level.scr_sound[self.script_sound]);

}

cannon_effect(source)
{
	if(!isDefined(source.script_delay))
		source.script_delay = 0;

	if((isDefined(source.script_delay_min)) && (isDefined(source.script_delay_max)))
		source.script_delay = source.script_delay_min + randomfloat (source.script_delay_max - source.script_delay_min);

	org = undefined;
	if(isDefined(source.target))
		org = (getent(source.target, "targetname")).origin;

	level thread maps\mp\_fx::OneShotfx(source.script_fxid, source.origin, source.script_delay, org);
}

brush_delete()
{
	if(isDefined(self.script_delay))
		wait( [[level.ex_fpstime]](self.script_delay) );

	self delete();
}

brush_show()
{
	if(isDefined(self.script_delay))
		wait( [[level.ex_fpstime]](self.script_delay) );

	self show();
	self solid();
}

brush_throw()
{
	if(isDefined(self.script_delay))
		wait( [[level.ex_fpstime]](self.script_delay) );

	ent = undefined;
	if(isDefined(self.target))
		ent = getent(self.target, "targetname");

	if(!isDefined(ent))
	{
		self delete();
		return;
	}

	self show();

	org = ent.origin;

	temp_vec = (org - self.origin);

	//println("start ", self.origin , " end ", org, " vector ", temp_vec, " player origin ", level.player getorigin());

	x = temp_vec[0];
	y = temp_vec[1];
	z = temp_vec[2];

	self rotateVelocity((x,y,z), 12);
	self moveGravity((x, y, z), 12);

	wait( [[level.ex_fpstime]](6) );
	self delete();
}

getPlant()
{
	start = self.origin + (0, 0, 10);

	range = 11;
	forward = anglesToForward(self.angles);
	forward = maps\mp\_utility::vectorScale(forward, range);

	traceorigins[0] = start + forward;
	traceorigins[1] = start;

	trace = bulletTrace(traceorigins[0], (traceorigins[0] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		//println("^6Using traceorigins[0], tracefraction is", trace["fraction"]);
		
		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	trace = bulletTrace(traceorigins[1], (traceorigins[1] + (0, 0, -18)), false, undefined);
	if(trace["fraction"] < 1)
	{
		//println("^6Using traceorigins[1], tracefraction is", trace["fraction"]);

		temp = spawnstruct();
		temp.origin = trace["position"];
		temp.angles = orientToNormal(trace["normal"]);
		return temp;
	}

	traceorigins[2] = start + (16, 16, 0);
	traceorigins[3] = start + (16, -16, 0);
	traceorigins[4] = start + (-16, -16, 0);
	traceorigins[5] = start + (-16, 16, 0);

	besttracefraction = undefined;
	besttraceposition = undefined;
	for(i = 0; i < traceorigins.size; i++)
	{
		trace = bulletTrace(traceorigins[i], (traceorigins[i] + (0, 0, -1000)), false, undefined);

		//ent[i] = spawn("script_model",(traceorigins[i]+(0, 0, -2)));
		//ent[i].angles = (0, 180, 180);
		//ent[i] setmodel("xmodel/105");

		//println("^6trace ", i ," fraction is ", trace["fraction"]);

		if(!isDefined(besttracefraction) || (trace["fraction"] < besttracefraction))
		{
			besttracefraction = trace["fraction"];
			besttraceposition = trace["position"];

			//println("^6besttracefraction set to ", besttracefraction, " which is traceorigin[", i, "]");
		}
	}
	
	if(besttracefraction == 1)
		besttraceposition = self.origin;
	
	temp = spawnstruct();
	temp.origin = besttraceposition;
	temp.angles = orientToNormal(trace["normal"]);
	return temp;
}

orientToNormal(normal)
{
	hor_normal = (normal[0], normal[1], 0);
	hor_length = length(hor_normal);

	if(!hor_length)
		return (0, 0, 0);
	
	hor_dir = vectornormalize(hor_normal);
	neg_height = normal[2] * -1;
	tangent = (hor_dir[0] * neg_height, hor_dir[1] * neg_height, hor_length);
	plant_angle = vectortoangles(tangent);

	//println("^6hor_normal is ", hor_normal);
	//println("^6hor_length is ", hor_length);
	//println("^6hor_dir is ", hor_dir);
	//println("^6neg_height is ", neg_height);
	//println("^6tangent is ", tangent);
	//println("^6plant_angle is ", plant_angle);

	return plant_angle;
}

array_levelthread(ents, process, var, excluders)
{
	exclude = [];
	for(i=0;i<ents.size;i++)
		exclude[i] = false;

	if(isDefined(excluders))
	{
		for(i=0;i<ents.size;i++)
		for(p=0;p<excluders.size;p++)
		if(ents[i] == excluders[p])
			exclude[i] = true;
	}

	for(i=0;i<ents.size;i++)
	{
		if(!exclude[i])
		{
			if(isDefined(var))
				level thread [[process]](ents[i], var);
			else
				level thread [[process]](ents[i]);
		}
	}
}

set_ambient(track)
{
	level.ambient = track;
	if((isDefined(level.ambient_track)) && (isDefined(level.ambient_track[track])))
	{
		ambientPlay (level.ambient_track[track], 2);
		println ("playing ambient track ", track);
	}
}

abs(num)
{
	if(num < 0) num*= -1;
	return num;
}

deletePlacedEntity(entity)
{
	entities = getentarray(entity, "classname");
	for(i = 0; i < entities.size; i++)
	{
		//println("DELETED: ", entities[i].classname);
		entities[i] delete();
	}
}
