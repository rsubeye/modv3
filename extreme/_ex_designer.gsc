/*
menus:
--------------------------------------------------------------------------------
quickdesign_spact.menu
1. Place new spawnpoint
2. Delete selected spawnpoint
3. Move selected spawnpoint
4. Undo

quickdesign_sptype1.menu
1. mp_dm_spawn - classname
   dm + hm + lms
	 ihtf if "dm" is in level.playerspawnpointsmode
2. mp_tdm_spawn - classname
	 tdm + chq + cnq + ft + hq + htf + lts + rbcnq + vip
	 dom + ons depending on level.spawntype
	 ihtf if "tdm" is in level.playerspawnpointsmode
3. mp_sd_spawn_attacker - classname
   sd + esd
	 dom + ons depending on level.spawntype
	 ihtf if "sdp" is in level.playerspawnpointsmode
	 tkoth if "sd" is in level.spawn
4. mp_sd_spawn_defender - classname
   sd + esd
	 dom + ons depending on level.spawntype
	 ihtf if "sdp" is in level.playerspawnpointsmode
	 tkoth if "sd" is in level.spawn
5. mp_ctf_spawn_allied - classname
   ctf + ctfb + rbctf
	 dom + ons depending on level.spawntype
	 ihtf if "ctfp" is in level.playerspawnpointsmode
	 tkoth if "sd" is in level.spawn
6. mp_ctf_spawn_axis - classname
   ctf + ctfb + rbctf
	 dom + ons depending on level.spawntype
	 ihtf if "ctfp" is in level.playerspawnpointsmode
	 tkoth if "sd" is in level.spawn

quickdesign_sptype2.menu
1. mp_lib_spawn_alliesnonjail - classname
   lib
2. mp_lib_spawn_axisnonjail - classname
   lib
3. mp_lib_spawn_alliesinjail - classname
   lib
4. mp_lib_spawn_axisinjail - classname
   lib
5. mp_tkoth_spawn_allied - classname
   tkoth
6. mp_tkoth_spawn_axis - classname
   tkoth

quickdesign_sptype3.menu
1. allied_flag - targetname
   if one exists, only allow move
2. axis_flag - targetname
   if one exists, only allow move
3. hqradio - targetname
4. bombzone - targetname


commands:
--------------------------------------------------------------------------------
P(lace), D(elete), M(ove)

P <type> <new_origin> <new_angles>
D <old_origin>
M <old_origin> <new_origin> <new_angles>

place new spawnpoint
- position yourself (origin + angles)
- press V 1 1 (place) (this will auto-select new spawnpoint and set type to previous selected type (dm by default))
- press V 2 x to set spawnpoint type

Delete spawnpoint
- select spawnpoint
- press V 1 2 (delete)

Move spawnpoint
- select spawnpoint
- position yourself on new location (origin + angles)
- press V 1 3 (move)


undo function
place will add the following to undo buffer

*/

init()
{
}

mainDesigner()
{
}
