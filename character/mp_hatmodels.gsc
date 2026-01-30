//******************************************************************************
// German
//******************************************************************************
mp_german_normandy()
{
	a = [];
	a[a.size] = "xmodel/helmet_german_normandy";
	a[a.size] = "xmodel/helmet_german_normandy_coat_dark";
	a[a.size] = "xmodel/helmet_german_normandy_emilio";
	a[a.size] = "xmodel/helmet_german_normandy_officer_hat";
	if(level.ex_hatmodels == 2)
	{
		a[a.size] = "xmodel/sidecap_lightgrey";
		a[a.size] = "xmodel/sidecap_darkgrey";
	}
	return a;
}

mp_german_normandy_precache()
{
	precacheHatModels(mp_german_normandy());
}

mp_german_africa()
{
	a = [];
	a[a.size] = "xmodel/helmet_german_camo_emilio";
	a[a.size] = "xmodel/helmet_german_africa";
	a[a.size] = "xmodel/helmet_german_casual_africa";
	if(level.ex_hatmodels == 2)
	{
		a[a.size] = "xmodel/sidecap_khaki";
		a[a.size] = "xmodel/sidecap_lightgrey";
	}
	return a;
}

mp_german_africa_precache()
{
	precacheHatModels(mp_german_africa());
}

mp_german_winter()
{
	a = [];
	a[a.size] = "xmodel/helmet_german_winter_dark";
	a[a.size] = "xmodel/helmet_german_winter_jon";
	a[a.size] = "xmodel/helmet_german_normandy_coat_dark";
	a[a.size] = "xmodel/helmet_german_normandy";
	if(level.ex_hatmodels == 2)
	{
		a[a.size] = "xmodel/bonnet_british_winter";
	}
	return a;
}

mp_german_winter_precache()
{
	precacheHatModels(mp_german_winter());
}

//******************************************************************************
// American
//******************************************************************************
mp_american_normandy()
{
	a = [];
	a[a.size] = "xmodel/helmet_us_ranger_braeburn";
	a[a.size] = "xmodel/helmet_us_ranger_generic";
	//a[a.size] = "xmodel/helmet_us_ranger_medic_wells";
	a[a.size] = "xmodel/helmet_us_ranger_mo";
	a[a.size] = "xmodel/helmet_us_ranger_randall";
	if(level.ex_hatmodels == 2)
	{
		a[a.size] = "xmodel/cap_american_baseball";
		a[a.size] = "xmodel/cap_american_baseball_dark";
		a[a.size] = "xmodel/hat_american_boonie";
		a[a.size] = "xmodel/hat_american_cowboy";
		a[a.size] = "xmodel/sidecap_green";
	}
	return a;
}

mp_american_normandy_precache()
{
	precacheHatModels(mp_american_normandy());
}

//******************************************************************************
// British
//******************************************************************************
mp_british_normandy()
{
	a = [];
	a[a.size] = "xmodel/helmet_british_normandy";
	a[a.size] = "xmodel/helmet_british_normandy_a";
	a[a.size] = "xmodel/helmet_british_normandy_mac";
	if(level.ex_hatmodels == 2)
	{
		a[a.size] = "xmodel/beret_british_red";
		a[a.size] = "xmodel/beret_british_green";
		a[a.size] = "xmodel/bonnet_british_winter";
		a[a.size] = "xmodel/hat_american_cowboy";
		a[a.size] = "xmodel/sidecap_green";
	}
	return a;
}

mp_british_normandy_precache()
{
	precacheHatModels(mp_british_normandy());
}

mp_british_africa()
{
	a = [];
	a[a.size] = "xmodel/helmet_british_afrca";
	a[a.size] = "xmodel/helmet_british_africa_mac";
	a[a.size] = "xmodel/helmet_british_joel_driver";
	if(level.ex_hatmodels == 2)
	{
		a[a.size] = "xmodel/beret_british_green";
		a[a.size] = "xmodel/beret_british_blue";
		a[a.size] = "xmodel/sidecap_camo";
		a[a.size] = "xmodel/bonnet_british_winter";
	}
	return a;
}

mp_british_africa_precache()
{
	precacheHatModels(mp_british_africa());
}

//******************************************************************************
// Russian
//******************************************************************************
mp_russian()
{
	a = [];
	a[a.size] = "xmodel/helmet_russian_padded_a";
	a[a.size] = "xmodel/helmet_russian_padded_b";
	a[a.size] = "xmodel/helmet_russian_trench_a_hat";
	a[a.size] = "xmodel/helmet_russian_trench_b_hat";
	a[a.size] = "xmodel/helmet_russian_trench_c_hat";
	a[a.size] = "xmodel/helmet_russian_trench_d_hat";
	a[a.size] = "xmodel/helmet_russian_trench_popov_hat";
	if(level.ex_hatmodels == 2)
	{
		a[a.size] = "xmodel/bonnet_russian_winter";
	}
	return a;
}

mp_russian_precache()
{
	precacheHatModels(mp_russian());
}

//******************************************************************************
// Supporting code
//******************************************************************************
precacheHatModels(a)
{
	for(i = 0; i < a.size; i++) [[level.ex_PrecacheModel]](a[i]);
}

randomHatModel(a)
{
	if(randomInt(100) > 1) return a[randomint(a.size)];
		else return "";
}
