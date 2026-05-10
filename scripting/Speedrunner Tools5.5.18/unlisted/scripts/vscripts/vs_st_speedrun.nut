//Squirrel

Convars.SetValue("mp_gamemode", "coop");
Convars.SetValue("z_difficulty", "Easy");
Convars.SetValue("director_no_bosses", 0);
Convars.SetValue("director_no_mobs", 0);
Convars.SetValue("director_no_specials", 0);
Convars.SetValue("z_common_limit", 30);
Convars.SetValue("sb_stop", 0);

function Inventory()
{
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

//========================================================================================================================
//ScMp
//========================================================================================================================

Timer();