//Squirrel

Convars.SetValue("mp_gamemode", "coop");
Convars.SetValue("z_difficulty", "Easy");
Convars.SetValue("director_no_bosses", 0);
Convars.SetValue("director_no_mobs", 0);
Convars.SetValue("director_no_specials", 0);
Convars.SetValue("z_common_limit", 30);
Convars.SetValue("sb_stop", 0);

Convars.SetValue("st_autocb", 0);
Convars.SetValue("st_tankboost", 0);
Convars.SetValue("st_fastreload", 0);
Convars.SetValue("st_edgebug", 0);
Convars.SetValue("sv_infinite_ammo", 0);
Convars.SetValue("nb_blind", 0);
Convars.SetValue("god", 0);
//DirectorStop();
//EntFire("info_changelevel", "Disable");

function Event()
{
	if (g_ST.event == "0") return;
	DirectorStop();
	ST_MRStop();
	Convars.SetValue("host_timescale", 0.5);
	Convars.SetValue("sv_infinite_ammo", 1);
	Convars.SetValue("nb_blind", 1);
	if (g_ST.event == "1")
	{
	}
	else if (g_ST.event == "2")
	{
	}
}

function Inventory()
{
	Convars.SetValue("host_timescale", 0.5);
	
	local hPlayer = null;
	if ((hPlayer = Ent("!nick")) != null)
	{
		hPlayer.GiveItem("pistol");
		hPlayer.SetHealth(50);
	}
	if ((hPlayer = Ent("!rochelle")) != null)
	{
		hPlayer.GiveItem("pistol");
		hPlayer.SetHealth(50);
	}
	if ((hPlayer = Ent("!coach")) != null)
	{
		hPlayer.GiveItem("pistol");
		hPlayer.SetHealth(50);
	}
	if ((hPlayer = Ent("!ellis")) != null)
	{
		hPlayer.GiveItem("pistol");
		hPlayer.SetHealth(50);
	}
}

::OnEntityOutput <- function()
{
	if (g_ST.restart || activator == null || !activator.IsSurvivor()) return;
	local client = activator.GetEntityIndex();
	if (caller.GetName() == "trigger_area1")
	{
		
	}
	else if (caller.GetName() == "trigger_area2")
	{
		
	}
}

::OnPlayEnd <- function(hPlayer, sFileName)
{
	if (sFileName == "default")
	{
		
	}
	else if (sFileName == "default")
	{
		
	}
}

::OnPlayLine <- function(hPlayer, sFileName, tick, buttons)
{
	if (sFileName == "default" && tick == 4)
	{
		
	}
	else if (sFileName == "default" && tick == 4)
	{
		
	}
}

::OnAutoFired <- function(hPlayer, data)
{
	if (data == 0)
	{
		
	}
	else if (data == 1)
	{
		
	}
}

::OnAutoFired_Post <- function(hPlayer, hClient, data)
{
	if (data == 0)
	{
		
	}
	else if (data == 1)
	{
		
	}
}

::OnAutoCB <- function(hPlayer, sName)
{
	
}

::OnSafe <- function(hPlayer)
{
	
}

::OnRestart <- function()
{
	
}

//========================================================================================================================
//ScMp
//========================================================================================================================

Timer();
HUDLoad(0.0);
//SetTeam("Nick");