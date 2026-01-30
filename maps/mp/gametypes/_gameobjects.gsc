main(allowed)
{
	entitytypes = getentarray();
	turretorigins = [];
	for(i = 0; i < entitytypes.size; i++)
	{
		// handle game objects with script_gameobjectname set
		if(isDefined(entitytypes[i].script_gameobjectname))
		{
			dodelete = true;
			for(j = 0; j < allowed.size; j++)
			{
				if(entitytypes[i].script_gameobjectname == allowed[j])
				{	
					dodelete = false;
					break;
				}
			}

			// Keep spawnpoints for flags, radios and bombzones when in "showall" designer mode
			if(dodelete && level.ex_designer && level.ex_designer_showall)
			{
				if(isDefined(entitytypes[i].targetname) &&
					(entitytypes[i].targetname == "allied_flag" ||
					 entitytypes[i].targetname == "axis_flag" ||
					 entitytypes[i].targetname == "bombzone" ||
					 entitytypes[i].targetname == "hqradio")) dodelete = false;
			}

			// Keep all turrets on the map, but avoid multiple turrets at same origin
			if(isDefined(entitytypes[i].classname) && (entitytypes[i].classname == "misc_turret" || entitytypes[i].classname == "misc_mg42"))
			{
				newturret = true;
				for(j = 0; j < turretorigins.size; j++)
				{
					dist = distance(entitytypes[i].origin, turretorigins[j]);
					if(dist < 100)
					{
						newturret = false;
						break;
					}
				}
				
				if(newturret)
				{
					turretorigins[turretorigins.size] = entitytypes[i].origin;
					dodelete = false;
				}
				else dodelete = true;
			}

			if(dodelete)
			{
				entitytypes[i] delete();
				game["entities_removed_gameobjects"]++;
			}
		}
		// handle turrets with no script_gameobjectname set
		else
		{
			// Keep all turrets on the map, but avoid multiple turrets at same origin
			if(isDefined(entitytypes[i].classname) && (entitytypes[i].classname == "misc_turret" || entitytypes[i].classname == "misc_mg42"))
			{
				newturret = true;
				for(j = 0; j < turretorigins.size; j++)
				{
					dist = distance(entitytypes[i].origin, turretorigins[j]);
					if(dist < 100)
					{
						newturret = false;
						break;
					}
				}

				if(!newturret)
				{
					entitytypes[i] delete();
					game["entities_removed_gameobjects"]++;
				}
				else turretorigins[turretorigins.size] = entitytypes[i].origin;
			}
		}
	}

	game["entities_removed_total"] += game["entities_removed_gameobjects"];
}
