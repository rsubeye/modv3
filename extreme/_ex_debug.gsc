/*******************************************************************************
VECTOR DEBUG CODE
*******************************************************************************/
debugVec(origin, type, text)
{
	if(isDefined(origin))
	{
		if(!isDefined(level.ex_debug_models)) level.ex_debug_models = [];
		if(!isDefined(type)) type = 0;

		switch(type)
		{
			case 1: model = "xmodel/health_medium"; break;
			case 2: model = "xmodel/health_large"; break;
			default : model = "xmodel/health_small"; break;
		}

		index = level.ex_debug_models.size;
		level.ex_debug_models[index] = spawn("script_model", origin);
		if(isDefined(level.ex_debug_models[index]))
		{
			level.ex_debug_models[index] setmodel(model);
			if(isDefined(text) && isDefined(level.ex_debug_models[index].origin)) level.ex_debug_models[index] thread debugVecMark(text);
		}
	}
	else
	{
		if(isDefined(level.ex_debug_models))
		{
			for(i = 0; i < level.ex_debug_models.size; i++) level.ex_debug_models[i] delete();
			level.ex_debug_models = undefined;
		}
	}
}

debugVecMark(text)
{
	while(1)
	{
		//print3d(<origin>, <text>, [<color>, <alpha>, <scale>])
		print3d(self.origin + (0, 0, 15), text, (.3, .8, 1), 1, 0.3);
		wait( [[level.ex_fpstime]](0.05) );
	}
}
