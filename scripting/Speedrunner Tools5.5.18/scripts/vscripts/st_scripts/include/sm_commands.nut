//Squirrel

/*
This include-file converts SourceMod commands to the VScript environment. All listed plugins must be installed in order to work properly.
Speedrunner Tools: https://forums.alliedmods.net/showthread.php?t=304789
Movement Reader: https://forums.alliedmods.net/showthread.php?t=309141
Note that, some functions are related with a native function SendToServerConsole(), execution of them is delayed by one frame.
*/

//========================================================================================================================
//SourceMod Commands
//========================================================================================================================

::ClientCommand <- function(hPlayer, sCmd)
{
	SendToServerConsole(format("sm_ccmd %d \"%s\"", hPlayer.GetEntityIndex(), sCmd));
}

//============================================================
//============================================================

::SetClientName <- function(hPlayer, sName)
{
	SendToServerConsole(format("sm_name %d \"%s\"", hPlayer.GetEntityIndex(), sName));
}

//============================================================
//============================================================

::SetAmmo <- function(hPlayer, iSlot, iClip, iAmmo = null, iUpgrade = null)
{
	local sCmd = format("sm_setammo %d %d %d", hPlayer.GetEntityIndex(), iSlot, iClip);
	if (iAmmo != null)
	{
		sCmd = format("%s %d", sCmd, iAmmo);
		if (iUpgrade != null)
		{
			sCmd = format("%s %d", sCmd, iUpgrade);
		}
	}
	SendToServerConsole(sCmd);
}

//============================================================
//============================================================

::SetTeam <- function(survName)
{
	local bValue = false;
	local hPlayer = null;
	while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
	{
		if (hPlayer != Ent("!player") && hPlayer.IsSurvivor() && !IsPlayerABot(hPlayer)) return;
		if (IsPlayerABot(hPlayer)) bValue = true;
	}
	if (bValue)
	{
		SendToServerConsole("sb_add; sb_add; sb_add");
		ClientCommand(Ent("!player"), "sb_takecontrol " + survName);
		SendToServerConsole("kick Nick; kick Rochelle; kick Coach; kick Ellis");
		SendToServerConsole("kick Bill; kick Zoey; kick Louis; kick Francis");
		SendToServerConsole("sm_fake; sm_fake; sm_fake");
		return;
	}
	printl("[SetTeam] Add in the game at least 1 bot to execute.");
}

//============================================================
//============================================================

::CallVote <- function(hCaller, sCmd)
{
	if (g_ST.restart) return;
	if (IsPlayerABot(hCaller)) Say(null, "[CallVote] Vote being called by a bot!", false);
	ClientCommand(hCaller, "callvote ChangeDifficulty " + sCmd);
	local hPlayer = null;
	while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
	{
		if (hCaller != hPlayer && !IsPlayerABot(hPlayer))
		{
			ClientCommand(hPlayer, "Vote Yes");
		}
	}
}

//============================================================
//============================================================

::PlayerReplace <- function(hPlayer, hPlayer2)
{
	SendToServerConsole(format("sm_replace %d %d", hPlayer.GetEntityIndex(), hPlayer2.GetEntityIndex()));
}

//============================================================
//============================================================

::AutoKick <- function(hCaller, hPlayer, bRootKey = false)
{
	if (g_ST.restart) return;
	if (!("AKTable" in g_STLib))
	{
		g_STLib.AKTable <-
		{
			playersList = []
			OnGameEvent_round_end = function(event)
			{
				SendToServerConsole("sb_add; sb_add; sb_add; sb_add");
				foreach (idx, player in playersList)
				{
					if (IsPlayer(player) && !player.IsSurvivor())
					{
						ClientCommand(player, "sb_takecontrol " + ["Nick", "Rochelle", "Coach", "Ellis"][NetProps.GetPropInt(player, "m_survivorCharacter")]);
					}
				}
				SendToServerConsole("nb_delete_all survivor");
			}
		}
		__CollectEventCallbacks(g_STLib.AKTable, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	}
	if (IsPlayer(hCaller) && IsPlayer(hPlayer))
	{
		ST_Idle(hPlayer);
		if (IsPlayerABot(hPlayer = GetPlayerFromCharacter(NetProps.GetPropInt(hPlayer, "m_survivorCharacter"))))
		{
			if (IsPlayerABot(hCaller)) Say(null, "[AutoKick] Vote being called by a bot!", false);
			g_STLib.AKTable.playersList.append(GetOwner(hPlayer));
			ClientCommand(hCaller, "callvote Kick " + hPlayer.GetPlayerUserId());
			hPlayer = null;
			while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
			{
				if (hCaller != hPlayer && !IsPlayerABot(hPlayer))
				{
					ClientCommand(hPlayer, "Vote Yes");
				}
			}
		}
	}
}

//============================================================
//============================================================

::ST_Idle <- function(hPlayer, bMode = false)
{
	if (!IsPlayer(hPlayer)) return;
	Convars.SetValue(bMode ? "st_idletake" : "st_idle", hPlayer.GetEntityIndex());
}

//============================================================
//============================================================

::ST_PlayerReplace <- function(hPlayer, hPlayer2)
{
	if (!IsPlayer(hPlayer) || !IsPlayer(hPlayer2)) return;
	Convars.SetValue("st_idlereplace", format("%d %d", hPlayer.GetEntityIndex(), hPlayer2.GetEntityIndex()));
}

//============================================================
//============================================================

::ST_MR <- function(hPlayer = null, eMode = 0, sFileName = null, bNoTeleport = false)
{
	if (hPlayer == null) hPlayer = PlayerInstanceFromIndex(1);
	if (!IsPlayer(hPlayer)) return;
	if (eMode == 3) return Convars.SetValue("st_mr_split", hPlayer.GetEntityIndex());
	if (sFileName == null) sFileName = "default";
	Convars.SetValue("st_mr_force_file", eMode == 2 ? "default" : sFileName);
	Convars.SetValue("st_mr_no_teleport", bNoTeleport.tointeger());
	Convars.SetValue(eMode ? "st_mr_play" : "st_mr_record", hPlayer.GetEntityIndex());
}

//============================================================
//============================================================

::ST_MRStop <- function(hPlayer = null)
{
	if (IsPlayer(hPlayer)) return Convars.SetValue("st_mr_stop_player", hPlayer.GetEntityIndex());
	hPlayer = null;
	while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
	{
		Convars.SetValue("st_mr_stop_player", hPlayer.GetEntityIndex());
	}
}