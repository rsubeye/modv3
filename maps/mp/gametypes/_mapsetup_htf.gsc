/*
Script to define custom flag spawns for HTF.
If you define more than one flag spawn position, only one will be selected at
random. The selected flag spawn position will be the same throughout the entire
match.

To set a custom flag position for a stock map, locate the map's procedure (like
breakout() for mp_breakout), uncomment the 4 lines by removing the double slashes,
and set the origin to the proper x, y and z coordinates. Set the angles if you
like the flag to face a certain direction (optional). Stick to setting yaw only;
the angles are formatted (pitch, yaw, roll), so set (0,90,0) for example.

To set a custom flag position for a custom map, add a case statement for that
specific map in init() below. For example:

		case "mp_custommapname": mp_custommapname(); break;

Create a procedure for that custom map by copying mp_mapname() and renaming it
to the procedure name you've set in the case statement:

	mp_custommapname()
	{
		//index = level.flags.size;
		//level.flags[index] = spawnstruct();
		//level.flags[index].origin = (0, 0, 0);
		//level.flags[index].angles = (0, 0, 0);
	}

Uncomment the 4 lines by removing the double slashes, and set the origin to the
proper x, y and z coordinates. Set the angles if you like the flag to face a
certain direction (optional). Stick to setting yaw only; the angles are formatted
(pitch, yaw, roll), so set (0,90,0) for example.

	mp_custommapname()
	{
		index = level.flags.size;
		level.flags[index] = spawnstruct();
		level.flags[index].origin = (x, y, z);
		level.flags[index].angles = (0, yaw, 0);
	}

If you want to define more than one flag spawn position, just copy the 4 lines
for every custom flag position, and set origin and (optionally) angles.

	mp_custommapname()
	{
		index = level.flags.size;
		level.flags[index] = spawnstruct();
		level.flags[index].origin = (x, y, z);
		level.flags[index].angles = (0, yaw, 0);

		index = level.flags.size;
		level.flags[index] = spawnstruct();
		level.flags[index].origin = (x, y, z);
		level.flags[index].angles = (0, yaw, 0);
	}

Do NOT remove the line where angles are set, even if you don't set custom angles.
Just leave it at (0,0,0). If you remove it, you will get script runtime errors.
*/

init()
{
	level.flags = [];

	switch(level.ex_currentmap)
	{
		// stock maps
		case "mp_breakout": breakout(); break;
		case "mp_brecourt": brecourt(); break;
		case "mp_burgundy": burgundy(); break;
		case "mp_carentan": carentan(); break;
		case "mp_dawnville": dawnville(); break;
		case "mp_decoy": decoy(); break;
		case "mp_downtown": downtown(); break;
		case "mp_farmhouse": farmhouse(); break;
		case "mp_harbor": harbor(); break;
		case "mp_leningrad": leningrad(); break;
		case "mp_matmata": matmata(); break;
		case "mp_railyard": railyard(); break;
		case "mp_rhine": rhine(); break;
		case "mp_toujane": toujane(); break;
		case "mp_trainstation": trainstation(); break;

		// custom maps
		case "mp_mapname": mp_mapname(); break;
	}
}

breakout()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

brecourt()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

burgundy()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

carentan()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

dawnville()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

decoy()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

downtown()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

farmhouse()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

harbor()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

leningrad()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

matmata()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

railyard()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

rhine()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

toujane()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

trainstation()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}

mp_mapname()
{
	//index = level.flags.size;
	//level.flags[index] = spawnstruct();
	//level.flags[index].origin = (0, 0, 0);
	//level.flags[index].angles = (0, 0, 0);
}
