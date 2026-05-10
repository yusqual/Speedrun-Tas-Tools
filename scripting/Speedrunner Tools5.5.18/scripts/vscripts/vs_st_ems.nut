//Squirrel

const VSCRIPT_VER = "5.5.18";
const FILE_ST_DATA = "st_config/st_data.txt";
const RTA_LIVESPLIT_SHIFT = 8.5;

IncludeScript("st_scripts/include/utils.nut");
IncludeScript("st_scripts/include/sm_commands.nut");
IncludeScript("st_scripts/include/speedrunner_tools.nut");
IncludeScript("st_scripts/include/debug.nut");

g_STLib.Funcs.UpdateFile <- function(hTable)
{
	local sTable = "{";
	foreach (key, val in hTable)
	{
		if (key == "restart" || key == "tick" || key.find("var_") != null) continue;
		if (type(val) == "string") sTable = format("%s\n	%s = \"%s\"", sTable, key, val);
		else if (type(val) == "float") sTable = format("%s\n	%s = %f", sTable, key, val);
		else if (type(val) == "integer" || type(val) == "bool") sTable = sTable + "\n	" + key + " = " + val;
	}
	sTable = sTable + "\n}";
	StringToFile(FILE_ST_DATA, sTable);
}

g_STLib.Funcs.DumpGameVersion <- function(called = false)
{
	if ("LocalTime" in getroottable())
	{
		g_ST.var_fast_update = true;
		return SendToServerConsole("setinfo version2 TLS");
	}
	if (FileToString("st_config/dump/game_version_fragment.txt") == null && !called)
	{
		StringToFile("st_config/dump/dummy", "");	//made sure we created a directory
		Convars.SetValue("con_logfile", "ems/st_config/dump/game_version_fragment.txt");
		SendToServerConsole("version");
		EntFire("worldspawn", "RunScriptCode", "g_STLib.Funcs.DumpGameVersion(true)", 0.01);
		EntFire("worldspawn", "RunScriptCode", "Convars.SetValue(\"con_logfile\", \"\")", 0.01);
		return;
	}
	local sVersion = FileToString("st_config/dump/game_version_fragment.txt");
	if (sVersion == null) return SendToServerConsole("setinfo version2 N/A");
	local idx = sVersion.find("Version 2.");
	if (idx == null) return SendToServerConsole("setinfo version2 N/A");
	sVersion = sVersion.slice(idx + 7, idx + 15);
	local values = split(sVersion, ".");
	/*
		Fast update period available since 2.1.5.1 game version and up,
		to avoid console spam. For older versions it's disabled.
		But users may change 'var_fast_update' still in g_ST scope
		to 'true' if necessary, to use fast stopwatch for all versions.
	*/
	if (values[1].tointeger() > 1 || (values[1] == "1" && values[2] == "5" && values[3].tointeger() > 0)) g_ST.var_fast_update = true;
	SendToServerConsole("setinfo version2 " + sVersion);
}

if (!("g_ST" in getroottable()))
{
	::g_ST <-
	{
		//defaults
		timer_value = 3.0
		event = "0"
		hud = true
		falldmg = false
		mode = 1
		full_legit = false
		bhop = true
		bhop_local = false
		unpatch = false
		rd = false
		
		restart = false
		var_restarts_issue = false
		var_fast_update = false
		var_map1 = false
		var_map_time = null
		var_bhoppers = array(33, true)
		tick = -1
		var_stats_fAvgSpeed = 0.0
		var_stats_fMaxSpeed = 0.0
		var_stats_plrsDistance = array(4, null)
		var_stats_fDist = 0.0
		var_stats_iJumps = 0
		var_stats_iKills = 0
	}
	::g_RTA <-
	{
		time = 0.0
		time_livesplit = 0.0
		time_igt = 0.0
		time_real = 0
		difficulty = 0
		maps = {}
		stats = {avgs = {}, max = 0.0, max_mapname = "N/A", distance = 0.0, jumps = 0, kills = 0}
	}
	
	local value = FileToString(FILE_ST_DATA);
	if (value != null)
	{
		value = compilestring("return " + value)();
		foreach (key, val in g_ST)
		{
			if (key in value)
			{
				g_ST.rawset(key, value.rawget(key));
			}
		}
		printl("[ST] Reloaded data table.");
	}
	else printl("[ST] Data table has been created in 'left4dead2/ems/st_config' folder.");
	g_STLib.Funcs.UpdateFile(g_ST);
	g_STLib.Funcs.DumpGameVersion();
}

if (!g_ST.mode && !g_ST.full_legit)
{
	Convars.SetValue("sv_cheats", 1);
	Convars.SetValue("sv_client_min_interp_ratio", 0);
	Convars.SetValue("sv_vote_creation_timer", 0);
	Convars.SetValue("director_afk_timeout", 999999);
	Convars.SetValue("director_no_death_check", 1);
	Convars.SetValue("sb_all_bot_game", 1);
	Convars.SetValue("host_timescale", 1.0);
	Convars.SetValue("z_mega_mob_size", 50);
}

if (g_ST.rd && "LocalTime" in getroottable())
{
	::g_RD <- {};
	IncludeScript("rocketdude");
	function g_RD::OnGameEvent_player_spawn(event)
	{
		local hPlayer = GetPlayerFromUserID(event.userid);
		if (hPlayer.IsSurvivor()) hPlayer.GiveItem("grenade_launcher");
		if (!("note" in g_RD)) g_RD.note <- Say(null, "RocketDude is now active!", false);
	}
	__CollectEventCallbacks(g_RD, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
}

//========================================================================================================================
//Hooks
//========================================================================================================================

function OnGameEvent_round_start(event)
{
	SendToServerConsole("echo Speedrunner Tools v" + VSCRIPT_VER);
	g_STLib.Funcs.HUDLoad();
	g_STLib.Funcs.Hooks();
	if (g_ST.restart)
	{
		if (IncludeScript("vs_st_speedrun.nut", g_STLib.Funcs)) 
		{
			SendToServerConsole("echo [ST] Loaded custom speedrun script.");
			if (g_ST.event != "0") SendToServerConsole("echo [ST] Loaded under event: " + g_ST.event);
		}
		else SpeedrunStart();
		if (!("Inventory2" in g_STLib.Funcs)) IncludeScript("st_scripts/skipintro.nut");
		__CollectEventCallbacks(g_STLib.Funcs, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	}
	if (!g_ST.mode && IncludeScript("vs_st_debug.nut", g_STLib.Funcs))
	{
		SendToServerConsole("echo [ST] Loaded 'vs_st_debug.nut' test script.");
		__CollectEventCallbacks(g_STLib.Funcs, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	}
}

function OnGameEvent_player_say(event)
{
	local hPlayer = GetPlayerFromUserID(event.userid);
	if (hPlayer == null) return;
	if (g_ST.mode && event.text.find("!") == 0 && ["!hud", "!mode", "!mode nerd", "!mode rta", "!mode sp", "!rta", "!bhop", "!bhop2", "!restart", "!restart2", "!restart3", "!dbg rta", "!dbg st"].find(event.text) == null && !Convars.GetFloat("sv_cheats")) return Say(null, "Unable to use chat commands during RTA mode!", false);
	if (event.text.find("!mode") != null || event.text == "!rta")
	{
		g_STLib.Vars.started = false;
		g_RTA.difficulty = 0;	//we need to leave at least one opportunity to reset a difficulty
		g_ST.restart = false;
		g_ST.mode = (g_ST.mode+1)%3;
		if (event.text == "!rta" && g_ST.mode == 0) g_ST.mode = 1;
		local value = split(event.text, " "), modeName;
		if (value.len() >= 2) modeName = value[1].tolower();
		if (modeName == "nerd") g_ST.mode = 0;
		else if (modeName == "rta") g_ST.mode = 1;
		else if (modeName == "sp") g_ST.mode = 2;
		if (g_ST.mode == 0)
		{
			Convars.SetValue("sv_cheats", 1);
			Convars.SetValue("sv_client_min_interp_ratio", 0);
			Convars.SetValue("sv_vote_creation_timer", 0);
			Convars.SetValue("director_afk_timeout", 999999);
			Convars.SetValue("director_no_death_check", 1);
			Convars.SetValue("sb_all_bot_game", 1);
			DirectorStop();
			SendToServerConsole("sm plugins refresh");
			//SendToServerConsole("nb_delete_all survivor");
			Convars.SetValue("survivor_limit", 4);
			Say(null, "Nerd mode.", false);
		}
		else if (g_ST.mode == 1)
		{
			Convars.SetValue("survivor_limit", 4);
			SendToServerConsole("sb_add; sb_add; sb_add; sb_add");
			Say(null, "RTA mode.", false);
		}
		else if (g_ST.mode == 2)
		{
			local hPlayer = null;
			while (hPlayer = Entities.FindByClassname(hPlayer, "player")) if (IsPlayerABot(hPlayer)) hPlayer.Kill();
			Convars.SetValue("survivor_limit", 1);
			Say(null, "SP mode.", false);
		}
		EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
		g_STLib.Funcs.UpdateFile(g_ST);
	}
	
	else if (event.text == "!restart") SpeedrunRestart();
	else if (event.text == "!restart2") SpeedrunRestart(true);
	else if (event.text == "!restart3")
	{
		SpeedrunRestart(true);
		SendToServerConsole("sb_add; sb_add; sb_add");
	}
	
	else if (event.text == "!bhop")
	{
		if (g_ST.bhop)
		{
			Say(null, "AutoBhop OFF" + (Ent("ent_lt_g_stlib.funcs.autobhop") ? ". Round restart required." : ""), false);
			EmitSoundOn("Buttons.snd11", hPlayer);
		}
		else
		{
			Say(null, "AutoBhop ON" + (!Ent("ent_lt_g_stlib.funcs.autobhop") ? ". Round restart required." : ""), false);
			EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
		}
		g_ST.bhop = !g_ST.bhop;
		g_STLib.Funcs.UpdateFile(g_ST);
	}
	
	else if (event.text == "!bhop2")
	{
		if (g_ST.bhop_local)
		{
			SendToServerConsole("bind SPACE +jump");
			SendToServerConsole("-jump; -alt1");
			Say(null, "Local Bhop OFF", false);
			EmitSoundOn("Buttons.snd11", hPlayer);
		}
		else
		{
			SendToServerConsole("alias +as_jump \"+jump; +alt1\"");
			SendToServerConsole("alias -as_jump \"-jump; -alt1\"");
			SendToServerConsole("bind SPACE +as_jump");
			if (!Ent("ent_lt_g_stlib.funcs.autobhop"))
			{
				g_ST.bhop = true;
				Say(null, "AutoBhop + Local Bhop are ON. Round restart required.", false);
			}
			else Say(null, "Local Bhop ON", false);
			EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
		}
		g_ST.bhop_local = !g_ST.bhop_local;
		g_STLib.Funcs.UpdateFile(g_ST);
	}
	
	else if (event.text == "!hud")
	{
		if (g_ST.hud)
		{
			Say(null, "HUD is disabled." + (!g_STLib.Vars.HUD.Fields.timer_sec.slot ? " Round restart required." : ""), false);
			EmitSoundOn("Buttons.snd11", hPlayer);
		}
		else
		{
			Say(null, "HUD is enabled." + (g_STLib.Vars.HUD.Fields.timer_sec.slot ? " Round restart required." : ""), false);
			EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
		}
		g_ST.hud = !g_ST.hud;
		g_STLib.Funcs.UpdateFile(g_ST);
	}
	
	else if (event.text.find("!timer") != null)
	{
		local value = split(event.text, " ");
		if (value.len() == 2)
		{
			value[1] = value[1].tofloat();
			if (value[1] >= 0)
			{
				g_ST.timer_value = value[1];
				g_STLib.Funcs.UpdateFile(g_ST);
				EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
			}
			else EmitSoundOn("Buttons.snd11", hPlayer);
		}
		else Say(null, format("Current countdown: %.01fs", g_ST.timer_value), false);
	}
	
	else if (event.text == "!picker")
	{
		local hEntity = null;
		if ((hEntity = GetPicker(hPlayer, MAX_TRACE_LENGTH, TRACE_MASK_SHOT)) == null) return EmitSoundOn("Buttons.snd11", hPlayer);
		local vecPos = hEntity.GetOrigin();
		local vecAng = hEntity.GetAngles();
		local sClass = hEntity.GetClassname();
		local sFunc = "";
		if (sClass.find("weapon_") != null || sClass == "upgrade_laser_sight" || sClass == "prop_physics")
		{
			local sName = "";
			local sModel = NetProps.GetPropString(hEntity, "m_ModelName");
			for (local i = 0; i < g_STLib.Items.len(); i++)
			{
				sName = format("item%d", i);
				if (sModel == g_STLib.Items.rawget(sName).mdl)
				{
					sFunc = format("Function:\nSpawnItem(\"%s\", Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f), %d);", sName, vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z, NetProps.GetPropInt(hEntity, "m_itemCount"));
					Say(null, sFunc, false);
					return EmitSoundOn("Buttons.snd37", hPlayer);
				}
			}
			return EmitSoundOn("Buttons.snd11", hPlayer);
		}
		else if (sClass == "infected" || sClass == "witch")
		{
			local gender = NetProps.GetPropInt(hEntity, "m_Gender");
			if (gender >= 11 && gender <= 17)
			{
				local model = NetProps.GetPropString(hEntity, "m_ModelName");
				local length = model.len();
				if (length > 16)
				{
					sFunc = format("Function:\nSpawnCommon(\"%s\", Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));", model.slice(16, length - 4), vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z);
					Say(null, sFunc, false);
					return EmitSoundOn("Buttons.snd37", hPlayer);
				}
			}
			sFunc = format("Function:\nSpawnZombieEx(\"%s\", Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));", sClass, vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z);
			Say(null, sFunc, false);
			EmitSoundOn("Buttons.snd37", hPlayer);
		}
		else if (sClass == "player" && !hEntity.IsSurvivor())
		{
			local aType = ["smoker", "boomer", "hunter", "spitter", "jockey", "charger", "witch", "tank"];
			sFunc = format("Function:\nSpawnZombie(\"%s\", Vector(%.03f, %.03f, %.03f));", aType[hEntity.GetZombieType() - 1], vecPos.x, vecPos.y, vecPos.z);
			Say(null, sFunc, false);
			EmitSoundOn("Buttons.snd37", hPlayer);
		}
		else if (hEntity.IsPlayer())
		{
			vecAng = hEntity.EyeAngles();
			sFunc = format("Function:\nTeleportEntity(hPlayer, Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));", vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z);
			Say(null, sFunc, false);
			EmitSoundOn("Buttons.snd37", hPlayer);
		}
		else EmitSoundOn("Buttons.snd11", hPlayer);
	}
	
	else if (event.text == "!fdmg")
	{
		if (g_ST.falldmg)
		{
			Say(null, "FallDmg is disabled.", false);
			EmitSoundOn("Buttons.snd11", hPlayer);
		}
		else
		{
			Say(null, "FallDmg is enabled.", false);
			EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
		}
		g_ST.falldmg = !g_ST.falldmg;
		g_STLib.Funcs.UpdateFile(g_ST);
	}
	
	else if (event.text == "!trigger")
	{
		local vecPos = hPlayer.GetOrigin();
		local sFunc = format("Function:\nSpawnTrigger(\"trigger_area\", Vector(%.03f, %.03f, %.03f));", vecPos.x, vecPos.y, vecPos.z);
		Say(null, sFunc, false);
		EmitSoundOn("Buttons.snd37", hPlayer);
		ppos(vecPos);
	}
	
	else if (event.text == "!rst")
	{
		Convars.SetValue("host_timescale", 1.0);
		if (SessionState.MapName.find("m1_") == null && g_ST.var_restarts_issue) return SendToServerConsole("changelevel " + SessionState.MapName);
		Convars.SetValue("mp_restartgame", 1);
	}
	
	else if (event.text == "!zdump")
	{
		ZDump();
		EmitSoundOn("Buttons.snd4", hPlayer);
	}
	
	else if (event.text.find("!xclip") != null)
	{
		local value = split(event.text, " ");
		if (value.len() == 2)
		{
			if (value[1] == "fast")
			{
				local fAng = hPlayer.GetAngles().y*PI/180;
				hPlayer.SetOrigin(hPlayer.GetOrigin() + Vector(cos(fAng)*TELEPORT_SHIFT, sin(fAng)*TELEPORT_SHIFT, 0));
				ClientCommand(hPlayer, "sm_idle");
				ClientCommand(hPlayer, "sm_take");
				return;
			}
			else if (value[1] == "exact")
			{
				local fAng = hPlayer.GetAngles().y*PI/180;
				local fShift = cos(hPlayer.EyeAngles().x*PI/180)*TELEPORT_SHIFT;
				hPlayer.SetOrigin(hPlayer.GetOrigin() + Vector(cos(fAng)*fShift, sin(fAng)*fShift, 0));
				ClientCommand(hPlayer, "sm_idle");
				ClientCommand(hPlayer, "sm_take");
				return;
			}
			else if (value[1] == "set")
			{
				if (!("PlayerToXClip" in g_STLib))
				{
					g_STLib.PlayerToXClip <-
					{
						pos = array(MAXCLIENTS + 1, Vector())
						ang = array(MAXCLIENTS + 1, 0.0)
						survivor = array(MAXCLIENTS + 1, -1)
						active = array(MAXCLIENTS + 1, false)
					}
				}
				if (!hPlayer.IsDead() && hPlayer.IsSurvivor())
				{
					local client = hPlayer.GetEntityIndex();
					g_STLib.PlayerToXClip.pos[client] = hPlayer.GetOrigin();
					g_STLib.PlayerToXClip.ang[client] = hPlayer.GetAngles().y;
					g_STLib.PlayerToXClip.survivor[client] = NetProps.GetPropInt(hPlayer, "m_survivorCharacter");
					g_STLib.PlayerToXClip.active[client] = true;
					EmitSoundOn("Buttons.snd37", hPlayer);
					return;
				}
			}
			else if (value[1] == "double")
			{
				local fAng = hPlayer.GetAngles().y*PI/180;
				hPlayer.SetOrigin(hPlayer.GetOrigin() + Vector(cos(fAng)*-20, sin(fAng)*-20, 0));
				ClientCommand(hPlayer, "sm_idle");
				ClientCommand(hPlayer, "sm_take");
				return;
			}
		}
		else if ("PlayerToXClip" in g_STLib)
		{
			local client = hPlayer.GetEntityIndex();
			if (g_STLib.PlayerToXClip.active[client])
			{
				local hClient = GetPlayerFromCharacter(g_STLib.PlayerToXClip.survivor[client]);
				if (hClient != null && !hClient.IsDead() && hClient.IsSurvivor())
				{
					local fAng = g_STLib.PlayerToXClip.ang[client]*PI/180;
					hClient.SetOrigin(g_STLib.PlayerToXClip.pos[client] + Vector(cos(fAng)*TELEPORT_SHIFT, sin(fAng)*TELEPORT_SHIFT, 0));
					EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hClient);
					return;
				}
			}
		}
		EmitSoundOn("Buttons.snd11", hPlayer);
	}
	
	else if (event.text.find("!dbg") != null)
	{
		local value = split(event.text, " ");
		if (value.len() >= 2)
		{
			if (value[1] == "st")
			{
				printl("\n================================ CFG");
				foreach (key, value in g_ST) if (key.find("var_") == null && key != "restart" && key != "tick") printl(key + " = " + value);
				printl("================================ GLOBALS");
				printl("restart = " + g_ST.restart);
				printl("tick = " + g_ST.tick);
				foreach (key, value in g_ST) if (key.find("var_") != null && key.find("var_stats") == null) printl(key + " = " + value);
				foreach (key, value in g_ST)
				{
					if (key.find("var_") != null && key.find("var_stats") != null)
					{
						printl(key + " = " + value);
						if (["array", "table"].find(typeof value) != null) ptable(value);
					}
				}
				printl("================================ ROUND");
				DeepPrintTable(g_STLib.Vars);
				printl("");
			}
			else if (value[1] == "lib") DeepPrintTable(g_STLib);
			else if (value[1] == "rta")
			{
				local hTable = {}; RestoreTable("session_info", hTable); SaveTable("session_info", hTable);
				printl("\nRTA = " + (g_ST.mode ? true : false));
				printl("var_map1 = " + g_ST.var_map1);
				printl("var_map_time = " + g_ST.var_map_time);
				printl("session_info::restarts = " + ("restarts" in hTable ? hTable.restarts : null));
				printl("session_info::deaths = " + ("deaths" in hTable ? hTable.deaths : null));
				printl("session_info::start_map = " + ("start_map" in hTable ? hTable.start_map : null));
				DeepPrintTable(g_RTA);
			}
			else if (value[1] == "start") SpeedrunStart();
			else if (value[1] == "stop") SpeedrunStart(false);
			else if (value[1] == "set" && value.len() == 3) CPSetTime(value[2].tofloat());
			else if (value[1] == "hud" && value.len() == 3) g_STLib.Funcs.HUDLoad(value[2].tofloat());
			else if (value[1] == "event")
			{
				if (value.len() == 3)
				{
					g_ST.event = value[2];
					g_STLib.Funcs.UpdateFile(g_ST);
					EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
				}
				else Say(null, format("Current custom event: \"%s\".", g_ST.event), false);
			}
			else if (value[1] == "tp")
			{
				local vecAng = hPlayer.EyeAngles();
				local vecPos = hPlayer.GetOrigin();
				if (GetSpeed(hPlayer) > 0)
				{
					local vecVel = hPlayer.GetVelocity();
					Say(null, format("Function:\nTeleportEntity(Ent(%d), Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));", hPlayer.GetEntityIndex(), vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z, vecVel.x, vecVel.y, vecVel.z), false);
				}
				else Say(null, format("Function:\nTeleportEntity(Ent(%d), Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));", hPlayer.GetEntityIndex(), vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z), false);
				EmitSoundOn("Buttons.snd37", hPlayer);
			}
			else if (value[1] == "tp2")
			{
				local hPlayer = null;
				local sData = "";
				while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
				{
					if (hPlayer.IsSurvivor())
					{
						local vecPos = hPlayer.GetOrigin();
						local vecAng = hPlayer.EyeAngles();
						sData += format("TeleportEntity(Ent(\"!%s\"), Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));\n", (GetCharacterDisplayName(hPlayer)).tolower(), vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z);
					}
				}
				print(sData);
			}
			else if (value[1] == "tp3")
			{
				local vecAng = hPlayer.EyeAngles();
				local vecPos = hPlayer.GetOrigin();
				local sFunc;
				if (GetSpeed(hPlayer) > 0)
				{
					local vecVel = hPlayer.GetVelocity();
					sFunc = format("TeleportEntity(Ent(%d), Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));", hPlayer.GetEntityIndex(), vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z, vecVel.x, vecVel.y, vecVel.z);
				}
				else sFunc = format("TeleportEntity(Ent(%d), Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));", hPlayer.GetEntityIndex(), vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z);
				Say(null, "Function:\n" + sFunc, false);
				SendToConsole("bind \"x\" \"script " + sFunc);
				EmitSoundOn("Buttons.snd37", hPlayer);
			}
			else if (value[1] == "events") DeepPrintTable(GameEventCallbacks);
			else if (value[1] == "do")
			{
				printl("===============  DirectorOptions  ===============");
				foreach (key, val in g_ModeScript.LocalScript.DirectorOptions)
				{
					printl(key + " = " + val);
					Say(null, key + " = " + val, false);
				}
				printl("=================================================");
				foreach (key, val in g_ModeScript.DirectorOptions) printl(key + " = " + val);
			}
			else if (value[1] == "trigger")
			{
				Convars.SetValue("developer", -1);
				SendToConsole("ent_bbox trigger_once");
				SendToConsole("ent_bbox trigger_multiple");
				SendToConsole("ent_bbox trigger_hurt");
			}
			else if (value[1] == "clip")
			{
				Convars.SetValue("developer", -1);
				SendToConsole("ent_bbox env_player_blocker");
			}
			else if (value[1] == "legit")
			{
				if (!g_ST.full_legit)
				{
					Say(null, "Switched to the Full Legit mode: all sort of ST-defined helpers will be disabled.", false);
					EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
				}
				else
				{
					Say(null, "Normal ST mode.", false);
					EmitSoundOn("Buttons.snd11", hPlayer);
				}
				g_ST.full_legit = !g_ST.full_legit;
				g_STLib.Funcs.UpdateFile(g_ST);
			}
			else if (value[1] == "unpatch")
			{
				if (!g_ST.unpatch)
				{
					Say(null, "Unpatch mode activated. Round restart required.", false);
					EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
				}
				else
				{
					Say(null, "Normal ST mode.", false);
					EmitSoundOn("Buttons.snd11", hPlayer);
				}
				g_ST.unpatch = !g_ST.unpatch;
				g_STLib.Funcs.UpdateFile(g_ST);
			}
			else if (value[1] == "reset")
			{
				delete ::g_ST;
				ClearSavedTables();
				IncludeScript("vs_st_ems", g_ModeScript);
				SendToServerConsole("echo Speedrunner Tools v" + VSCRIPT_VER);
				SendToServerConsole("bind \"x\" \"say !dbg reset");					// binds for dbg!!!
				SendToServerConsole("bind \"v\" \"say !dbg start");
				SendToServerConsole("bind \"b\" \"script g_STLib.Funcs.PrintTime()");
				g_STLib.Funcs.HUDLoad();
				g_STLib.Funcs.Hooks();
				if (g_ST.mode)
				{
					Convars.SetValue("sv_cheats", 1);
					DirectorStop();
					SendToServerConsole("sm plugins refresh");
				}
			}
			else if (value[1] == "af" || value[1] == "af2" || value[1] == "af3")
			{
				AFStop();
				local hEntity, vecPos = hPlayer.GetOrigin(), dist, dist_store, hClient;
				while (hEntity = Entities.FindByClassname(hEntity, "player"))
				{
					if (hEntity != hPlayer && hEntity.IsSurvivor() && !hEntity.IsDead() && !hEntity.IsDying() && !hEntity.IsIncapacitated())
					{
						dist = (vecPos - hEntity.GetOrigin()).Length()
						if (!dist_store || dist_store > dist)
						{
							dist_store = dist;
							hClient = hEntity;
						}
					}
				}
				if (hClient)
				{
					local vecAng = hPlayer.EyeAngles();
					Convars.SetValue("sv_infinite_ammo", 1);
					Convars.SetValue("god", 1);
					hClient.SetOrigin(vecPos);
					if (value[1] == "af")
					{
						hClient.GiveItem("grenade_launcher");
						Say(null, "Function:\n" + format("AutoFire(%d, QAngle(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f), true);", hClient.GetEntityIndex(), vecAng.x, vecAng.y, vecAng.z, vecPos.x, vecPos.y, vecPos.z), false);
						AutoFire(hClient.GetEntityIndex(), vecAng, null, true);
					}
					else if (value[1] == "af2")
					{
						hClient.GiveItem("vomitjar");
						Say(null, "Function:\n" + format("AutoFire2(%d, QAngle(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f), true);", hClient.GetEntityIndex(), vecAng.x, vecAng.y, vecAng.z, vecPos.x, vecPos.y, vecPos.z), false);
						AutoFire2(hClient.GetEntityIndex(), vecAng, null, true);
						local hTable = {}; GetInvTable(hClient, hTable); foreach (key, val in hTable) if (key != "slot2") val.Kill();
					}
					else if (value[1] == "af3")
					{
						local item = "molotov";
						if (value.len() >= 3)
						{
							if (value[2] == "pipe") item = "pipe_bomb";
							else if (value[2] == "molo") item = "molotov";
							else if (value[2] == "bile") item = "vomitjar";
							else if (value[2] == "vjar") item = "vomitjar";
							else return Say(null, "Type in the chat !dbg af3 pipe, molo or bile to execute RTA boosts.", false);
						}
						hClient.GiveItem(item);
						Say(null, "Function:\n" + format("AutoFire2(%d, QAngle(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f), true, null, %d);", hClient.GetEntityIndex(), vecAng.x, vecAng.y, vecAng.z, vecPos.x, vecPos.y, vecPos.z, item == "vomitjar" ? 20 : 15), false);
						AutoFire2(hClient.GetEntityIndex(), vecAng, null, true, null, item == "vomitjar" ? 20 : 15);
						local hTable = {}; GetInvTable(hClient, hTable); foreach (key, val in hTable) if (key != "slot2") val.Kill();
					}
					EmitSoundOn("Buttons.snd37", hPlayer);
				}
				else Say(null, "Add to the game at least 1 bot to use.", false);
			}
			else if (value[1] == "nav")
			{
				if (Convars.GetFloat("nav_edit") && "NavMark_Picker" in getroottable())
				{
					EntFire("ent_nav_settings_mark", "Kill");
					Convars.SetValue("nav_edit", 0);
					Convars.SetValue("z_debug", 0);
					SendToServerConsole("unbind x");
					EmitSoundOn("Buttons.snd11", hPlayer);
					return;
				}
				::NavMark_Picker <- function()
				{
					local vecPos = GetPickerPos(self);
					SpawnEntityFromTable("prop_dynamic", {targetname = "ent_nav_settings_mark", model = "models/editor/axis_helper_thick.mdl", glowstate = 3, disableshadows = 1, origin = vecPos});
					NavMark(vecPos);
					printl(format("NavMark(Vector(%.03f, %.03f, %.03f));", vecPos.x, vecPos.y, vecPos.z));
					EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", self);
				}
				Convars.SetValue("nav_edit", 1);
				Convars.SetValue("z_debug", 1);
				SendToServerConsole("bind \"x\" \"ent_fire !self callscriptfunction NavMark_Picker");
				Say(null, "Button X has been bound to mark NAV areas. Open the console and copy/past generated function samples.", false);
				EmitSoundOn("Buttons.snd37", hPlayer);
			}
			else EmitSoundOn("Buttons.snd11", hPlayer);
		}
		else
		{
			Convars.SetValue("developer", 0);
			EmitSoundOn("Buttons.snd11", hPlayer);
		}
	}
	
	else if (event.text.find("!find") != null)
	{
		local value = split(event.text, " ");
		if (value.len() == 2)
		{
			local hEntity = null;
			local sName = "";
			local sClass = "";
			local iCount = 0;
			local bValue = false;
			if (value[0] == "!findex") bValue = true;
			for (local i = 1; i <= MAXENTS; i++)
			{
				hEntity = EntIndexToHScript(i);
				if (hEntity != null && NetProps.GetPropString(hEntity, "m_ModelName") != "models/extras/info_speech.mdl")
				{
					sClass = hEntity.GetClassname();
					sName = hEntity.GetName();
					if ((bValue && sClass != value[1] && sName != value[1]) || (sClass.find(value[1]) == null && sName.find(value[1]) == null)) continue;
					SpawnEntityFromTable("prop_dynamic", {targetname = sName, model = "models/extras/info_speech.mdl", glowstate = 3, disableshadows = 1, origin = hEntity.GetOrigin() + Vector(0, 0, 25), angles = Vector(0, RandomInt(0, 360), 0)});
					printl("" + hEntity);
					iCount++;
				}
			}
			return Say(null, "Count: " + iCount, false);
		}
		local hEntity = null;
		while ((hEntity = Entities.FindByModel(hEntity, "models/extras/info_speech.mdl")) != null) hEntity.Kill();
		EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
	}
	
	else if (event.text == "!rd")
	{
		if (!("LocalTime" in getroottable()))
		{
			Say(null, "RocketDude isn't available for " + Convars.GetStr("version2"), false);
			EmitSoundOn("Buttons.snd11", hPlayer);
			g_ST.rd = false;
			g_STLib.Funcs.UpdateFile(g_ST);
			return;
		}
		if (!g_ST.rd)
		{
			Say(null, "RocketDude mode activated. Round restart required.", false);
			EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", hPlayer);
		}
		else
		{
			Say(null, "Normal ST mode.", false);
			EmitSoundOn("Buttons.snd11", hPlayer);
		}
		g_ST.rd = !g_ST.rd;
		g_STLib.Funcs.UpdateFile(g_ST);
	}
}

::UserConsoleCommand <- function(hPlayer, args)
{
	//custom
	foreach (key, value in g_STLib.Funcs)
	{
		if (key.find("UserCmd") == null || (typeof value) != "function") continue;
		value(hPlayer, args);
	}
	
	//ST
	if (args == "bhop")
	{
		g_ST.var_bhoppers[hPlayer.GetEntityIndex()] = !g_ST.var_bhoppers[hPlayer.GetEntityIndex()];
	}
	else if (args.find("restart") != null)
	{
		if (args == "restart3") SendToServerConsole("sb_add; sb_add; sb_add");
		SpeedrunRestart(args == "restart" ? false : true);
		printl("Player " + hPlayer.GetPlayerName() + " is attempting to restart the game.");
	}
	else if (args.find("_takehost") != null)
	{
		if (g_STLib.Vars.host) return;
		g_STLib.Vars.host = hPlayer;
		if (hPlayer != Ent(1))
		{
			local sName = "";
			if (Ent(1)) sName = Ent(1).GetPlayerName();
			SendToServerConsole("echo [ST] Local server host is tied to another index " + hPlayer + ", occupier: " + sName);
		}
	}
}

function OnGameEvent_player_falldamage(event)
{
	if (g_ST.falldmg && (Convars.GetFloat("sv_cheats") || !g_ST.mode))
	{
		Say(null, format("Player %s fdmg %.01f", GetPlayerFromUserID(event.userid).GetPlayerName(), event.damage), false);
	}
}

function OnGameEvent_finale_vehicle_leaving(event)
{
	g_STLib.Funcs.PrintTime();
}

function OnGameEvent_map_transition(event)
{
	g_STLib.Funcs.PrintTime();
	SendToServerConsole("setinfo debug_restarts_issue 1");
}

function OnGameEvent_player_entered_checkpoint(event)
{
	if ("userid" in event && GetFlowPercentForPosition(EntIndexToHScript(event.door).GetOrigin(), false) > 50)
	{
		OnSafe(GetPlayerFromUserID(event.userid));
	}
}

function OnGameEvent_round_end(event)
{
	if (event.message == "#L4D_Scenario_Survivors_Dead")
	{
		g_ST.var_restarts_issue = true;
		g_STLib.Vars.is_mission_fail = true;
		if (!g_ST.mode) return;
		local hTable = {}; RestoreTable("session_info", hTable);
		if ("deaths" in hTable) hTable.deaths++;
		SaveTable("session_info", hTable);
		g_STLib.Funcs.OnGameEvent_round_start_pre_entity <- function(event)
		{
			g_RTA.time = g_STLib.Vars.HUD.Fields.timer_sec.dataval;
			SaveTable("rta", g_RTA);
		}
		__CollectEventCallbacks(g_STLib.Funcs, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	}
	else if (g_ST.mode && event.message == "#L4D_Scenario_Restart") g_ST.var_map1 = false;
}

function OnGameEvent_player_jump(event)
{
	if (GetPlayerFromUserID(event.userid).IsSurvivor())
	{
		g_ST.var_stats_iJumps++;
	}
}

function OnGameEvent_player_death(event)
{
	if ("userid" in event && GetPlayerFromUserID(event.userid).IsSurvivor()) g_STLib.Funcs.CheckpointDoorClosed();
	if ("victimisbot" in event && event.victimisbot && "attacker" in event)
	{
		local hPlayer = GetPlayerFromUserID(event.attacker);
		if (hPlayer && hPlayer.IsSurvivor())
		{
			g_ST.var_stats_iKills++;
		}
	}
}

function OnGameEvent_player_disconnect(event)
{
	g_STLib.Funcs.CheckpointDoorClosed();
}

function OnGameEvent_player_spawn(...)
{
	if (g_ST.unpatch && "LocalTime" in getroottable()) EntFire("anv_mapfixes_*", "Kill");
	SendToServerConsole("scripted_user_func _takehost");
	EntFire("info_director", "AddOutput", "OnGameplayStart !self,RunScriptCode,SendToServerConsole(\"scripted_user_func _takehost\")");	// if still gameplay didn't start
	ClearEvent();
}

//========================================================================================================================
//Funcs
//========================================================================================================================

::SpeedrunRestart <- function(bAllowFastRestarts = false)
{
	if (g_ST.mode)
	{
		if (g_STLib.Vars.is_custom_hosted && !g_STLib.Vars.is_custom_campaign)
		{
			CPTime("Please, return to the lobby and re-host the game.\x00");
			SendToConsole("callvote ReturnToLobby");
			return;
		}
		
		Convars.SetValue("sv_vote_command_delay", 0);
		Convars.SetValue("sv_vote_timer_duration", 0);
		Convars.SetValue("sv_vote_creation_timer", 0);
		if (g_RTA.difficulty) SendToServerConsole("z_difficulty " + g_RTA.difficulty);
		/*
			Ofc if we do RestartGame on the 1st map it will be faster than restart entire campaign, however, in this case,
			the statistics won't reset in the outro roller (some rules might request IGT result). Also, regarding the 1st maps,
			we suppose some Director (or map) changes after the team death restart (e.g. anger value, route openings...),
			therefore use such methods of restarting may entail not so legit map walkthrough.
		*/
		local map = split(Convars.GetStr("host_map").tolower(), "m")[0];
		if ((SessionState.MapName.find(map + "m") != null && bAllowFastRestarts) || g_STLib.Vars.is_custom_campaign) SendToConsole("callvote RestartGame");
		else SendToConsole("callvote ChangeMission L4D2" + map.toupper());
		if (!g_ST.restart)
		{
			EntFire("info_changelevel", "Disable");
			if (!g_STLib.Vars.is_mission_fail) OnGameFrame(format("SpeedrunRestart(%d)", bAllowFastRestarts.tointeger()), 1.0);
		}
		g_STLib.Funcs.OnGameEvent_vote_cast_yes <- function(event)
		{
			g_ST.var_map1 = false;
			g_RTA.time_real = GetEpoch();
			SaveTable("rta", g_RTA);
		}
		__CollectEventCallbacks(g_STLib.Funcs, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
		return;
	}
	if (!g_ST.restart)
	{
		if (SessionState.MapName.find("m1_") == null && g_ST.var_restarts_issue) return SendToServerConsole("changelevel " + SessionState.MapName);
		g_ST.restart = true;
		EntFire("info_changelevel", "Disable");
		Convars.SetValue("mp_restartgame", 1);
		Convars.SetValue("host_timescale", 1.0);
		Say(null, "Restarting...", false);
		if ("OnRestart" in getroottable()) EntFire("worldspawn", "RunScriptCode", "OnRestart()", 0.1);
	}
}

::SpeedrunStart <- function(isHUD = true)
{
	g_ST.restart = false;
	g_STLib.Vars.started = isHUD;
	if (isHUD) g_STLib.Vars.time = Time() - g_STLib.Vars.time_desired;
	if (g_ST.mode)
	{
		if (g_ST.var_map_time == null) g_ST.var_map_time = g_RTA.time;
		if (g_STLib.Vars.bhop) SendToServerConsole("echo Category->AutoBhop+RTA");
	}
}

g_STLib.Funcs.PrintTime <- function()
{
	if (g_STLib.Vars.started)
	{
		Convars.SetValue("host_timescale", 1.0);
		Say(null, format("Total time: %.03fs", g_STLib.Vars.HUD.Fields.timer_sec.dataval), false);
		g_STLib.Vars.started = false;
		g_ST.restart = true;
		
		//console stats
		SendToServerConsole("echo Version .................:" + Convars.GetStr("version2") + (g_STLib.Vars.unpatch ? " unpatched" : ""));
		SendToServerConsole("echo Time ....................:" + GetDisplayTime(g_STLib.Vars.HUD.Fields.timer_sec.dataval, "m") + "s" + format("(%.03f)", g_STLib.Vars.HUD.Fields.timer_sec.dataval));
		if (g_ST.mode)
		{
			HUDSetLayout(g_STLib.Vars.HUD);
			g_RTA.time = g_STLib.Vars.HUD.Fields.timer_sec.dataval;
			g_ST.var_map_time = g_ST.var_map_time != null ? g_RTA.time - g_ST.var_map_time : g_RTA.time;
			g_RTA.time_livesplit += g_STLib.Vars.is_finale ? g_ST.var_map_time : g_ST.var_map_time + RTA_LIVESPLIT_SHIFT;	// Constant time offset (8.5s) from 'map_transition' to loading screen, as if we'd use LiveSplit timer.
			g_RTA.time_igt += g_STLib.Vars.is_finale ? 0 : Time() - 1;
			g_RTA.maps.rawset(SessionState.MapName, g_ST.var_map_time);
			g_RTA.stats.avgs.rawset(SessionState.MapName, g_ST.var_stats_fAvgSpeed/g_ST.tick);
			if (g_RTA.stats.max < g_ST.var_stats_fMaxSpeed)
			{
				g_RTA.stats.max = g_ST.var_stats_fMaxSpeed;
				g_RTA.stats.max_mapname = SessionState.MapName;
			}
			g_RTA.stats.distance += g_ST.var_stats_fDist;
			g_RTA.stats.jumps += g_ST.var_stats_iJumps;
			g_RTA.stats.kills += g_ST.var_stats_iKills;
			SaveTable("rta", g_RTA);
			local igt = g_STLib.Vars.is_finale ? g_RTA.time_igt + Time() - 1 : g_RTA.time_igt;
			local length = 24 - SessionState.MapName.len(), mapname_fix = SessionState.MapName + " ";
			for (local d = 0; d < length; d++) mapname_fix += ".";
			SendToServerConsole("echo " + mapname_fix + " : +" + GetDisplayTime(g_ST.var_map_time, "m") + "s" + format("(%.03f)", g_ST.var_map_time));
			SendToServerConsole("echo LiveSplit ...............:" + GetDisplayTime(g_RTA.time_livesplit, "m") + "s" + format("(%.03f)", g_RTA.time_livesplit));
			SendToServerConsole("echo IGT (outro stats) .....:" + GetDisplayTime(igt, "m") + "s" + format("(%.03f)", igt));
			if (g_STLib.Vars.bhop) SendToServerConsole("echo Category ................: AutoBhop+RTA");
		}
		else
		{
			SendToServerConsole("echo Segment .................: +" + GetDisplayTime(g_STLib.Vars.HUD.Fields.timer_sec.dataval - g_STLib.Vars.time_desired, "m") + "s" + format("(%.03f)", g_STLib.Vars.HUD.Fields.timer_sec.dataval - g_STLib.Vars.time_desired));
			SendToServerConsole("echo Ticks ...................:" + g_ST.tick);
		}
		SendToServerConsole("echo Avg. velocity ...........:" + g_ST.var_stats_fAvgSpeed/g_ST.tick);
		SendToServerConsole("echo Max. velocity ...........:" + g_ST.var_stats_fMaxSpeed);
		SendToServerConsole("echo Distance ................:" + g_ST.var_stats_fDist);
		SendToServerConsole("echo Jumps ...................:" + g_ST.var_stats_iJumps);
		SendToServerConsole("echo Infected killed .........:" + g_ST.var_stats_iKills);
	}
}

g_STLib.Funcs.HUDLoad <- function(value = 0.0)
{
	SessionState.MapName = SessionState.MapName.tolower(); //bc it can be like "C12m1_hilltop" that will mess up plenty of expressions
	local hostmap = split(Convars.GetStr("host_map").tolower(), ".")[0];
	g_STLib.Vars.started <- false;
	g_STLib.Vars.time <- 0.0;
	g_STLib.Vars.time_desired <- value.tofloat();
	g_STLib.Vars.is_finale <- false;
	g_STLib.Vars.is_mission_fail <- false;
	g_STLib.Vars.HUD <- {Fields = {}};
	g_STLib.Vars.tick <- -1;
	g_STLib.Vars.bhop <- false;
	g_STLib.Vars.unpatch <- false;
	g_STLib.Vars.host <- null;
	g_STLib.Vars.campsList <- ["c1m1_hotel", "c1m2_streets", "c1m3_mall", "c1m4_atrium", "c6m1_riverbank", "c6m2_bedlam", "c6m3_port", "c2m1_highway", "c2m2_fairgrounds", "c2m3_coaster", "c2m4_barns", "c2m5_concert", "c3m1_plankcountry", "c3m2_swamp", "c3m3_shantytown", "c3m4_plantation", "c4m1_milltown_a", "c4m2_sugarmill_a", "c4m3_sugarmill_b", "c4m4_milltown_b", "c4m5_milltown_escape", "c5m1_waterfront", "c5m2_park", "c5m3_cemetery", "c5m4_quarter", "c5m5_bridge", "c13m1_alpinecreek", "c13m2_southpinestream", "c13m3_memorialbridge", "c13m4_cutthroatcreek", "c8m1_apartment", "c8m2_subway", "c8m3_sewers", "c8m4_interior", "c8m5_rooftop", "c9m1_alleys", "c9m2_lots", "c10m1_caves", "c10m2_drainage", "c10m3_ranchhouse", "c10m4_mainstreet", "c10m5_houseboat", "c11m1_greenhouse", "c11m2_offices", "c11m3_garage", "c11m4_terminal", "c11m5_runway", "c12m1_hilltop", "c12m2_traintunnel", "c12m3_bridge", "c12m4_barn", "c12m5_cornfield", "c7m1_docks", "c7m2_barge", "c7m3_port"];
	g_STLib.Vars.is_custom_campaign <- g_STLib.Vars.campsList.find(SessionState.MapName) == null;
	g_STLib.Vars.is_custom_hosted <- g_STLib.Vars.campsList.find(hostmap) == null;
	g_STLib.Vars.is_custom_map1 <- g_STLib.Vars.is_custom_campaign && SessionState.MapName == hostmap;
	if (g_ST.mode)
	{
		RestoreTable("rta", g_RTA);
		
		//reset camp-only stats on any m1
		if (!g_ST.var_map1 && (SessionState.MapName.find("m1_") != null || g_STLib.Vars.is_custom_map1))
		{
			//and total time on lobby map
			if (split(Convars.GetStr("host_map").tolower(), "m")[0] == split(SessionState.MapName, "m")[0] || g_STLib.Vars.is_custom_map1)
			{
				local hTable = {restarts = -1, deaths = 0, start_map = 0};
				RestoreTable("session_info", hTable);
				hTable.restarts++;
				hTable.deaths = 0;
				if (hTable.start_map != SessionState.MapName)
				{
					hTable.restarts = 0;
					hTable.start_map = SessionState.MapName;
				}
				SaveTable("session_info", hTable);
				
				g_RTA.time = 0.0;
				g_RTA.difficulty = Convars.GetStr("z_difficulty");
			}
			g_RTA.time_livesplit = 0.0;
			g_RTA.time_igt = 0.0;
			g_RTA.maps.clear();
			g_RTA.stats = {avgs = {}, max = 0.0, max_mapname = "N/A", distance = 0.0, jumps = 0, kills = 0};
			g_ST.var_map1 = true;
			g_ST.var_map_time = null;
			g_ST.tick = -1;
			g_ST.var_stats_fAvgSpeed = 0.0;
			g_ST.var_stats_fMaxSpeed = 0.0;
			g_ST.var_stats_plrsDistance = array(4, null);
			g_ST.var_stats_fDist = 0.0;
			g_ST.var_stats_iJumps = 0;
			g_ST.var_stats_iKills = 0;
		}
		SaveTable("rta", g_RTA);
		g_STLib.Vars.time_desired = value ? value : g_RTA.time;
	}
	else
	{
		g_ST.tick = -1;
		g_ST.var_stats_fAvgSpeed = 0.0;
		g_ST.var_stats_fMaxSpeed = 0.0;
		g_ST.var_stats_plrsDistance = array(4, null);
		g_ST.var_stats_fDist = 0.0;
		g_ST.var_stats_iJumps = 0;
		g_ST.var_stats_iKills = 0;
	}
	if (g_ST.hud)
	{
		g_STLib.Vars.HUD.Fields.timer_sec <- {slot = HUD_LEFT_TOP, dataval = g_STLib.Vars.time_desired, flags = HUD_FLAG_AS_TIME | HUD_FLAG_ALIGN_RIGHT};
		g_STLib.Vars.HUD.Fields.timer_ms <- {slot = HUD_LEFT_BOT, dataval = split(format("%.03f", g_STLib.Vars.time_desired), ".")[1], flags = HUD_FLAG_NOBG};
		g_STLib.Vars.HUD.Fields.timer_qmark <- {slot = HUD_MID_TOP, dataval = "'", flags = HUD_FLAG_NOBG};
	}
	else
	{
		g_STLib.Vars.HUD.Fields.timer_sec <- {slot = HUD_MID_BOT, dataval = g_STLib.Vars.time_desired, flags = HUD_FLAG_AS_TIME | HUD_FLAG_ALIGN_RIGHT};
		g_STLib.Vars.HUD.Fields.timer_ms <- {slot = HUD_RIGHT_TOP, dataval = split(format("%.03f", g_STLib.Vars.time_desired), ".")[1], flags = HUD_FLAG_NOBG | HUD_FLAG_ALIGN_LEFT};
		g_STLib.Vars.HUD.Fields.timer_qmark <- {slot = HUD_RIGHT_BOT, dataval = "'", flags = HUD_FLAG_NOBG | HUD_FLAG_ALIGN_CENTER};
	}
	function HUDUpdate()
	{
		if (g_STLib.Vars.started)
		{
			local fTime = Time() - g_STLib.Vars.time;
			g_STLib.Vars.HUD.Fields.timer_sec.dataval = fTime;
			g_STLib.Vars.HUD.Fields.timer_ms.dataval = split(format("%.03f", fTime), ".")[1];
			g_STLib.Vars.tick = floor((fTime - g_STLib.Vars.time_desired)/0.033333+0.5);
			g_ST.tick = floor(fTime/0.033333+0.5);
			if (g_ST.var_fast_update) HUDSetLayout(g_STLib.Vars.HUD);
			
			local hPlayer, speed, vecPos, delta, avgSpeed = 0, count = 0;
			while (hPlayer = Entities.FindByClassname(hPlayer, "player"))
			{
				if (hPlayer.IsSurvivor() && !hPlayer.IsDead() && !hPlayer.IsDying())
				{
					local surv = NetProps.GetPropInt(hPlayer, "m_survivorCharacter");
					if (surv < 4)
					{
						//this fix prevents counting the survivor bots during the jumping HUD bug
						local playerName = hPlayer.GetPlayerName(), bFound = false;
						foreach (idx, name in ["Hunter", "Smoker", "Boomer", "Jockey", "Charger", "Spitter"])
						{
							if (playerName.find(name) != null)
							{
								bFound = true;
								break;
							}
						}
						if (!IsPlayerABot(hPlayer) || !bFound)
						{
							speed = hPlayer.GetVelocity().Length();
							vecPos = hPlayer.GetOrigin();
							avgSpeed += speed;
							count++;
							if (g_ST.var_stats_plrsDistance[surv] == null) g_ST.var_stats_plrsDistance[surv] = vecPos;
							delta = (vecPos - g_ST.var_stats_plrsDistance[surv]).Length2D();
							g_ST.var_stats_fDist += delta > 203 || !speed ? 0.0 : delta;	//203 means max. possible delta at max. player speed (so, we skip TPs and store only real distance)
							g_ST.var_stats_plrsDistance[surv] = vecPos;
							if (g_ST.var_stats_fMaxSpeed < speed) g_ST.var_stats_fMaxSpeed = speed;
						}
					}
				}
			}
			if (count > 0) g_ST.var_stats_fAvgSpeed += avgSpeed/count;
			// printl(g_STLib.Vars.tick + " >> AVG: " + (g_ST.var_stats_fAvgSpeed/g_STLib.Vars.tick) + " | sum: " + g_ST.var_stats_fAvgSpeed + " | time: " + CPGetTime() + " | vel: " + speed);
			//alias +as_pr "+forward; say !dbg start";alias -as_pr "-forward; bind w +forward"; bind w +as_pr; mat_reloadmaterial digits*
		}
	}
	if (!Ent("ent_st_timer")) SpawnEntityFromTable("logic_timer", {targetname = "ent_st_timer", RefireTime = 0.01, OnTimer = "!caller,RunScriptCode,g_STLib.Funcs.HUDUpdate()"});
	HUDSetLayout(g_STLib.Vars.HUD);
}

g_STLib.Funcs.Hooks <- function()
{
	local unpatch_vote = false;
	
	function CheckpointDoorClosed()
	{
		if (g_ST.restart || g_ST.mode || g_ST.full_legit) return;
		EntFire("info_changelevel", "CheckpointDoorClosed");
	}
	EntFire("prop_door_rotating_checkpoint", "AddOutput", "OnFullyClosed !caller,RunScriptCode,g_STLib.Funcs.CheckpointDoorClosed()");
	EntFire("info_changelevel", "AddOutput", "OnStartTouch !caller,RunScriptCode,g_STLib.Funcs.CheckpointDoorClosed()");
	if (SessionState.MapName == "c5m5_bridge") Entities.FindByName(null, "trigger_heli").__KeyValueFromString("OnEntireTeamStartTouch", "!caller,RunScriptCode,g_STLib.Funcs.PrintTime()");
	else if (SessionState.MapName == "c13m4_cutthroatcreek") Entities.FindByName(null, "trigger_boat").__KeyValueFromString("OnEntireTeamStartTouch", "!caller,RunScriptCode,g_STLib.Funcs.PrintTime()");
	else if (SessionState.MapName == "c7m3_port") Entities.FindByName(null, "generator_final_button_relay").__KeyValueFromString("OnTrigger", "!caller,RunScriptCode,g_STLib.Funcs.PrintTime()");
	
	SendToServerConsole("setinfo cl_player_speed 0");
	function PlayerSpeed() if (GetPlayer()) SendToServerConsole("cl_player_speed " + GetPlayer().GetVelocity().Length2D());
	OnGameFrame("g_STLib.Funcs.PlayerSpeed");
	
	if (!g_ST.mode && SessionState.MapName.find("m1_") != null)
	{
		local hEntity;
		if (hEntity = Entities.FindByClassname(null, "info_director"))
		{
			hEntity.ValidateScriptScope();
			hEntity.GetScriptScope().InputReleaseSurvivorPositions <- function()
			{
				if ("Inventory2" in g_STLib.Funcs)
				{
					SpeedrunStart();
					g_STLib.Funcs.Inventory2();
					if ("Event" in g_STLib.Funcs) EntFire("worldspawn", "RunScriptCode", "g_STLib.Funcs.Event()", 0.01);
				}
				return true;
			}
		}
	}
	
	/* BETA: We can unpatch some elements to suit the old game versions.
	Mostly it were "env_player_blocker" as it turned out, therefore 90% of the game can be successfully rolled back.
	But still, restoring or simulating such things like "Infinite Stumble" trick or removing "prop_static" from the map – can be problematic.
	
	This feature cannot properly unpatch TLS versions due to the major gameplay changes after this update.
	Also, we're skipping some campaigns, because e.g. unpatching c7 hasn't any sense; c11 has only "prop_static" and BSP-clips fixes, but c13 just received significant changes.
	And some questions to c2m5 (prop_static) and c10m4 (BSP-clips, skip doesn't work).
	P.S.: Something else to unpatch?
	*/
	if (g_ST.unpatch)
	{
		if ("LocalTime" in getroottable())
		{
			g_STLib.Vars.unpatch = true;
			EntFire("anv_mapfixes_*", "Kill");
		}
		if (SessionState.MapName.find("c7m") == null && SessionState.MapName.find("c11m") == null && SessionState.MapName.find("c13m") == null)
		{
			g_STLib.Vars.unpatch = true;
			unpatch_vote = true;
			Convars.SetValue("sv_vote_creation_timer", 0);	//no vote cooldown at 2.0.X.X
			if (["c1m1_hotel"
				"c2m2_fairgrounds"
				"c2m3_coaster"
				"c5m1_waterfront"
				"c5m2_park"
				"c5m4_quarter"
				"c6m3_port"
				"c8m1_apartment"
				"c8m2_subway"
				].find(SessionState.MapName) != null) EntFire("env_player_blocker", "Kill");
				
			else if (SessionState.MapName == "c3m1_plankcountry")
			{
				EntFire("swamp_clip_brush", "Kill");
			}
			else if (SessionState.MapName == "c8m3_sewers")
			{
				Ent("warehouse_door").Kill();
				local hTable =
				{
					targetname = "warehouse_door"
					model = "models/props_interiors/door_sliding_breakable01.mdl"
					origin = Vector(11001.800, 7504.000, 16.000)
					angles = Vector(0.000, 0.000, 0.000)
					health = 200
					solid = 6
					spawnflags = 8
					disableshadows = 1
				}
				SpawnEntityFromTable("prop_physics", hTable);
				EntFire(hTable.targetname, "SetParent", "door_sliding");
				EntFire(hTable.targetname, "AddOutput", "OnBreak door_sliding,Kill");
				EntFire(hTable.targetname, "AddOutput", "OnBreak portal_warehouse,Open");
			}
			else if (SessionState.MapName == "c10m3_ranchhouse")
			{
				EntFire("info_changelevel", "AddOutput", "origin 0 -37 0");
				EntFire("checkpoint_entrance", "AddOutput", "OnOpen info_changelevel,AddOutput,origin 0 0 0", 1.0);	//move trigger back?
			}
			else if (SessionState.MapName == "c12m4_barn")
			{
				local hTable =
				{
					model = "models/props/cs_office/Light_security.mdl"
					origin = Vector(10623.700, -8391.810, 125.901)
					angles = Vector(0.000, 180.000, 0.000)
					solid = 6
					rendermode = 6
				}
				SpawnEntityFromTable("prop_dynamic", hTable);
			}
		}
		if (g_STLib.Vars.unpatch) SendToServerConsole("echo [ST] WARNING! Unpatch mode is used (type \"!dbg unpatch\" to disable).");
	}
	
	if ("g_RD" in getroottable())
	{
		SendToServerConsole("echo [ST] RocketDude mode is used.");
	}
	else if (g_ST.full_legit && !g_ST.mode)
	{
		SendToServerConsole("echo [ST] Full Legit mode init.");
	}
	
	if (g_ST.bhop)
	{
		g_STLib.Vars.bhop = true;
		if (g_ST.bhop_local)
		{
			SendToServerConsole("alias +as_jump \"+jump; +alt1\"");
			SendToServerConsole("alias -as_jump \"-jump; -alt1\"");
			SendToServerConsole("bind SPACE +as_jump");
		}
		function AutoBhop()
		{
			local hPlayer;
			while (hPlayer = Entities.FindByClassname(hPlayer, "player"))
			{
				if (hPlayer.IsSurvivor() && g_ST.var_bhoppers[hPlayer.GetEntityIndex()])
				{
					if (NetProps.GetPropEntity(hPlayer, "m_hGroundEntity") == null)
					{
						if (NetProps.GetPropInt(hPlayer, "m_MoveType") != MOVETYPE_LADDER)
						{
							NetProps.SetPropInt(hPlayer, "m_afButtonDisabled", NetProps.GetPropInt(hPlayer, "m_afButtonDisabled") | IN_JUMP);
							continue;
						}
					}
				}
				NetProps.SetPropInt(hPlayer, "m_afButtonDisabled", NetProps.GetPropInt(hPlayer, "m_afButtonDisabled") & ~IN_JUMP);
			}
			if (g_ST.bhop_local && (hPlayer = Entities.FindByName(null, "!player")) && hPlayer.IsSurvivor() && g_ST.var_bhoppers[hPlayer.GetEntityIndex()])
			{
				if (hPlayer.GetButtonMask() & IN_ALT1)
				{
					if (!(NetProps.GetPropInt(hPlayer, "m_fFlags") & FL_ONGROUND))
					{
						if (NetProps.GetPropInt(hPlayer, "m_MoveType") != MOVETYPE_LADDER)
						{
							return SendToServerConsole("-jump");
						}
					}
					SendToServerConsole("+jump");
					EntFire("worldspawn", "RunScriptCode", "SendToServerConsole(\"-jump\")", 0.01);
				}
			}
		}
		OnGameFrame("g_STLib.Funcs.AutoBhop");
	}
	
	if (g_ST.mode)
	{
		if (Convars.GetFloat("director_no_death_check")) Convars.SetValue("sv_cheats", 1);
		if (g_ST.mode == 2) Convars.SetValue("survivor_limit", 1);
		Convars.SetValue("sv_cheats", 0);
		Convars.SetValue("director_afk_timeout", 45);		//hidden cvars cannot be reset via sv_cheats toggles
		Convars.SetValue("sv_client_min_interp_ratio", 1);
		Convars.SetValue("sv_vote_command_delay", 2);
		Convars.SetValue("sv_vote_timer_duration", 15);
		if (!unpatch_vote && !g_ST.var_map1) Convars.SetValue("sv_vote_creation_timer", 180);	// for !restart2 and to avoid waiting 180s (conveniences... but remember: 1 vote per 1 player!)
		SendToServerConsole("sm plugins unload_all");	//just in case
		local hEntity;
		if ((SessionState.MapName.find("m1_") != null || g_STLib.Vars.is_custom_map1) && (hEntity = Entities.FindByClassname(null, "info_director")))
		{
			hEntity.ValidateScriptScope();
			hEntity.GetScriptScope().InputReleaseSurvivorPositions <- function()
			{
				SpeedrunStart();
				return true;
			}
			return;
		}
		if (hEntity = Entities.FindByClassname(null, "env_outtro_stats"))
		{
			g_STLib.Vars.is_finale = true;
			hEntity.ValidateScriptScope();
			hEntity.GetScriptScope().InputRollStatsCrawl <- function()
			{
				if (g_STLib.Vars.is_custom_campaign) g_STLib.Funcs.PrintTime();
				
				/*
					Offsets to sync our timer with outro statistics:
					0.033333 - if outro stats called via 'test_outtro_stats' cmd (debugging only).
					0.066667 - if outro stats called normally, via I/O chains.
					0.100000 - if previous maps were restarted at least once, or under any other uncertain circumstances (unused).
					1.000000 - server time corrector, since IGT goes from 'round_start' event (looks like exact time after HScript loaded).
					
					Note that, real in-game time in the statistics may differ from the summed Time() value on +/- 1 frame in case,
					if players executed round restarts (as a rule, after many tests we got it) and, prolly, it might happen
					at other situations as well, e.g. host lags (maybe..), so be ready for it.
				*/
				local fTimeCampaign = 0; foreach (key, value in g_RTA.maps) fTimeCampaign += value;
				local unix = GetEpoch();
				local iTimeReal = unix - g_RTA.time_real;
				local hTable = {}; RestoreTable("session_info", hTable); SaveTable("session_info", hTable);
				local fAvg = 0; foreach (key, value in g_RTA.stats.avgs) fAvg += g_RTA.maps[key]/fTimeCampaign*value;
				g_RTA.time_igt += Time() - 1 - 0.066667;
				SendToServerConsole("echo __________________ Speedrun Stats __________________");
				SendToServerConsole("echo ====================================================");
				SendToServerConsole("echo Version .................:" + Convars.GetStr("version2") + (g_STLib.Vars.unpatch ? " unpatched" : ""));
				SendToServerConsole("echo \"Record date ............. : " + GetDate(unix).timestamp3);
				SendToServerConsole("echo Time ....................:" + GetDisplayTime(g_RTA.time, "m") + "s" + format("(%.03f)", g_RTA.time));
				if (g_RTA.time > fTimeCampaign + 1) SendToServerConsole("echo Campaign ................: +" + GetDisplayTime(fTimeCampaign, "m") + "s" + format("(%.03f)", fTimeCampaign));
				SendToServerConsole("echo LiveSplit ...............:" + GetDisplayTime(g_RTA.time_livesplit, "m") + "s" + format("(%.03f)", g_RTA.time_livesplit));
				SendToServerConsole("echo IGT (outro stats) .....:" + GetDisplayTime(g_RTA.time_igt, "m") + "s" + format("(%.03f)", g_RTA.time_igt));
				if (g_RTA.time_real > 0) SendToServerConsole("echo RTA .....................:" + GetDisplayTime(iTimeReal, "m") + "s"); //non-precise time without floating point
				if (g_STLib.Vars.bhop) SendToServerConsole("echo Category ................: AutoBhop+RTA");
				SendToServerConsole("echo Restarts ................:" + ("restarts" in hTable ? hTable.restarts : 0));
				SendToServerConsole("echo Deaths ..................:" + ("deaths" in hTable ? hTable.deaths : 0));
				SendToServerConsole("echo Avg. velocity ...........:" + floor(fAvg+0.5));
				SendToServerConsole("echo Max. velocity ...........:" + floor(g_RTA.stats.max+0.5) + " (" + g_RTA.stats.max_mapname + ")");
				SendToServerConsole("echo Distance ................:" + floor(g_RTA.stats.distance+0.5));
				SendToServerConsole("echo Jumps ...................:" + g_RTA.stats.jumps);
				SendToServerConsole("echo Infected killed .........:" +  g_RTA.stats.kills);
				SendToServerConsole("echo");
				if (g_STLib.Vars.is_custom_campaign)
				{
					foreach (key, value in g_RTA.maps)
					{
						local length = 32 - key.len(); key += " ";
						for (local d = 0; d < length; d++) key += ".";
						SendToServerConsole("echo " + key + ":" + GetDisplayTime(value, "m") + "s" + format("(%.03f)", value));
					}
				}
				else
				{
					for (local i = 1; i <= 5; i++)
					{
						foreach (key, value in g_RTA.maps)
						{
							if (key.find("m" + i) != null)
							{
								local length = 32 - key.len(); key += " ";
								for (local d = 0; d < length; d++) key += ".";
								SendToServerConsole("echo " + key + ":" + GetDisplayTime(value, "m") + "s" + format("(%.03f)", value));
								break;
							}
						}
					}
				}
				if (g_RTA.maps.len() > 0) SendToServerConsole("echo");
				SendToServerConsole("echo Speedrunner Tools v" + VSCRIPT_VER);
				SendToServerConsole("echo");
				//ClearSavedTables();
				return true;
			}
		}
		if (g_ST.var_restarts_issue) return SpeedrunStart();
		function g_ModeScript::OnGameEvent_player_connect_full(event)
		{
			EntFire("info_director", "AddOutput", "OnGameplayStart !self,RunScriptCode,SpeedrunStart()");	//just to correct timer if game started not from 1st map (useful?)
			SpeedrunStart();
			ClearEvent();
		}
		__CollectEventCallbacks(g_ModeScript, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	}
	
	if (Convars.GetFloat("debug_restarts_issue"))
	{
		Convars.SetValue("debug_restarts_issue", 0);
		g_ST.var_restarts_issue = true;
	}
}

g_STLib.Funcs.Timer <- function(value = 3)
{
	if ("Inventory2" in this && SessionState.MapName.find("m1_") != null) return;
	if (value == 3)
	{
		function PlayerBlocker()
		{
			if (g_ST.restart)
			{
				local hPlayer = null;
				local hTable = {};
				while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
				{
					if (hPlayer.IsSurvivor())
					{
						NetProps.SetPropInt(hPlayer, "m_fFlags", NetProps.GetPropInt(hPlayer, "m_fFlags") | FL_FROZEN);
						GetInvTable(hPlayer, hTable);
						foreach (key, val in hTable)
						{
							if (key != "slot1" || SessionState.MapName.find("m1_") == null)
							{
								val.Kill();
							}
						}
					}
				}
			}
		}
		PlayerBlocker();
		SpawnEntityFromTable("logic_timer", {targetname = "ent_st_pb", RefireTime = 0.2, OnTimer = "!caller,RunScriptCode,g_STLib.Funcs.PlayerBlocker()"});
		EntFire("worldspawn", "RunScriptCode", "g_STLib.Funcs.Timer(2)", g_ST.timer_value/3);
		EntFire("worldspawn", "RunScriptCode", "g_STLib.Funcs.Timer(1)", g_ST.timer_value/3*2);
		EntFire("worldspawn", "RunScriptCode", "g_STLib.Funcs.Timer(0)", g_ST.timer_value);
	}	
	else if (value == 0)
	{
		EntFire("ent_st_pb", "Kill");
		SpeedrunStart();
		local hPlayer = null;
		while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
		{
			if (hPlayer.IsSurvivor())
			{
				NetProps.SetPropInt(hPlayer, "m_fFlags", NetProps.GetPropInt(hPlayer, "m_fFlags") & ~FL_FROZEN);
			}
		}
		if ("Inventory" in this) Inventory();
		else if ("Inventory2" in this) Inventory2();
		else Say(null, "Function callback \"g_STLib.Funcs.Inventory\" does not exist!", false);
		if ("Event" in this) EntFire("worldspawn", "RunScriptCode", "g_STLib.Funcs.Event()", 0.01);
		return;
	}
	Say(null, "" + value, false);
}