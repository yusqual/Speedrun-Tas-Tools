//Squirrel

/*
Debuggers for ScMp mode.
*/

//========================================================================================================================
//Debug
//========================================================================================================================

::CPTime <- function(sValue = null, hPlayer = null)
{
	if (sValue == null) sValue = "";
	Say(Ent(hPlayer), format(sValue + " %.03f", Time() - g_STLib.Vars.time), false);
}

//============================================================
//============================================================

::CPSetTime <- function(fValue = 0)
{
	g_STLib.Vars.time = Time() - fValue;
}

//============================================================
//============================================================

::CPGetTime <- function()
{
	return Time() - g_STLib.Vars.time;
}

//============================================================
//============================================================

::DebugItems <- function(itemName = null, withDelay = false)
{
	if (itemName == null) itemName = "";
	if (withDelay) return EntFire("worldspawn", "RunScriptCode", format("DebugItems(\"%s\")", itemName), 0.1);
	local iCount = 0;
	local hEntity = null;
	local sClass = "";
	local sModel = "";
	local vecPos = Vector();
	local specific = itemName.len() > 0 ? true : false;
	local sName = "";
	local sFileData = "";
	local vecAng = Vector();
	local cansList =
	[
		"models/props_junk/propanecanister001a.mdl"
		"models/props_junk/gascan001a.mdl"
		"models/props_equipment/oxygentank01.mdl"
	]
	while (hEntity = Entities.Next(hEntity))
	{
		sClass = hEntity.GetClassname();
		if ((sClass.find("weapon_") != null && sClass.find("_spawn") != null) || sClass == "upgrade_laser_sight" || sClass == "prop_physics")
		{
			sModel = NetProps.GetPropString(hEntity, "m_ModelName");
			if (sClass == "prop_physics" && cansList.find(sModel) == null) continue;
			vecPos = hEntity.GetOrigin();
			vecAng = hEntity.GetAngles();
			if (specific)
			{
				if (sModel.find(itemName) == null) continue;
				printl("[DebugItems] Specific found: " + hEntity + format(" --> setpos_exact %.03f, %.03f, %.03f", vecPos.x, vecPos.y, vecPos.z));
			}
			iCount++;
			SpawnEntityFromTable("prop_dynamic", {targetname = "mark_" + sClass, model = "models/extras/info_speech.mdl", glowstate = 3, disableshadows = 1, origin = hEntity.GetOrigin() + Vector(0, 0, 25), angles = Vector(0, RandomInt(0, 360), 0)});
			for (local i = 0; i < g_STLib.Items.len(); i++)
			{
				sName = format("item%d", i);
				if (sModel == g_STLib.Items.rawget(sName).mdl)
				{
					sFileData = format("%sSpawnItem(\"%s\", Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f), %d);\n", sFileData, sName, vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z, NetProps.GetPropInt(hEntity, "m_itemCount"));
					break;
				}
			}
		}
	}
	if (iCount > 0)
	{
		Say(null, "[DebugItems] Total items: " + iCount + format(specific ? " (%s)" : "", itemName), false);
		StringToFile("st_config/items_dump.nut", sFileData);
	}
	return iCount;
}

//============================================================
//============================================================

::CheckMoving <- function(fTime = 3.0, bChat = null, bLocalTime = false)
{
	if (Ent(LT + "g_STLib.CheckMoving.Think")) return;
	if (bChat == null) bChat = false; 
	g_STLib.CheckMoving <-
	{
		time = 0.0
		Think = function()
		{
			local text = "";
			local hPlayer = null;
			local buttons = 0;
			while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
			{
				if (IsPlayerABot(hPlayer) && hPlayer.IsSurvivor() && (buttons = hPlayer.GetButtonMask()) != 0 && buttons != IN_RELOAD)
				{
					text += GetCharacterDisplayName(hPlayer) + " btn=" + buttons + " | ";
				}
			}
			if (text.len() > 0)
			{
				fTime = bLocalTime ? Time() - time : CPGetTime();
				if (!bChat) SendToServerConsole(format("echo %.03f >> ", fTime) + text);
				else Say(null, format("%.03f >> ", fTime) + text, false);
			}
		}
	}
	if (bLocalTime) g_STLib.CheckMoving.time = Time();
	SendToServerConsole(format("echo %.03f >> Button listener begin...", CPGetTime()));
	OnGameFrame("g_STLib.CheckMoving.Think", null, fTime);
	EntFire("worldspawn", "RunScriptCode", "SendToServerConsole(\"echo #end\")", fTime + 0.01);
}

//============================================================
//============================================================

::ZDump <- function(fTime = null)
{
	if (fTime != null) return EntFire("worldspawn", "RunScriptCode", "ZDump()", fTime);
	local iCount = 0;
	local hEntity = null;
	local sClass = "";
	local vecPos = Vector();
	local vecAng = Vector();
	local sFileData = "";
	local aType = ["smoker", "boomer", "hunter", "spitter", "jockey", "charger", "witch", "tank"];
	local gender = 0;
	for (local i = 1; i <= MAXENTS; i++)
	{
		hEntity = EntIndexToHScript(i);
		if (hEntity != null)
		{
			if (NetProps.GetPropInt(hEntity, "m_iTeamNum") == 3)
			{
				sClass = hEntity.GetClassname();
				if (sClass == "player" || sClass == "infected" || sClass == "witch")
				{
					iCount++;
					vecPos = hEntity.GetOrigin();
					vecAng = hEntity.GetAngles();
					if (hEntity.IsPlayer() && !hEntity.IsDead())
					{
						sFileData = format("%sSpawnZombie(\"%s\", Vector(%.03f, %.03f, %.03f));\n", sFileData, aType[hEntity.GetZombieType() - 1], vecPos.x, vecPos.y, vecPos.z);
						continue;
					}
					gender = NetProps.GetPropInt(hEntity, "m_Gender");
					if (gender >= 11 && gender <= 17)
					{
						local model = NetProps.GetPropString(hEntity, "m_ModelName");
						local length = model.len();
						if (length > 16)
						{
							sFileData = format("%sSpawnCommon(\"%s\", Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));\n", sFileData, model.slice(16, length - 4), vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z);
							continue;
						}
					}
					sFileData = format("%sSpawnZombieEx(\"%s\", Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f));\n", sFileData, sClass, vecPos.x, vecPos.y, vecPos.z, vecAng.x, vecAng.y, vecAng.z);
				}
			}
		}
	}
	if (iCount > 0)
	{
		StringToFile("st_config/zdump.nut", sFileData);
		printl("[ST] Dump file \"left4dead2/ems/st_config/zdump.nut\" has been created.");
	}
	printl("[ST] Total zombies written: " + iCount);
}

//============================================================
//============================================================

::MobListener <- function(flags = 1, mobMax = 200)
{
	const MOB_HUD = 1;
	const MOB_CHAT = 2;
	const MOB_CONSOLE = 4;
	
	if (!Ent(LT + "MobListener"))
	{
		local hEntity = OnGameFrame("MobListener");
		this = hEntity.GetScriptScope();
		_mobMax <- mobMax;
		_flags <- flags;
		_mobsList <- [];
		_mobCurrent <- 0;
		_updateTime <- 0.0;
		
		local hEntity;
		while (hEntity = Entities.FindByClassname(hEntity, "infected"))
		{
			local scope = hEntity.GetScriptScope();
			if (scope && "non_finale" in scope) continue;
			hEntity.ValidateScriptScope();
			scope = hEntity.GetScriptScope();
			scope.non_finale <- null;
		}
		g_STLib.Vars.HUD.Fields.mob <- {slot = HUD_FAR_RIGHT, dataval = "MegaMob: 0 / " + mobMax, flags = HUD_FLAG_ALIGN_CENTER};
		HUDPlace(HUD_FAR_RIGHT, 0.435, 0.06, 0.14, 0.035);
	}
	if (!("self" in this))
	{
		g_STLib.Vars.HUD.Fields.mob.flags = HUD_FLAG_NOTVISIBLE;
		return Ent(LT + "MobListener").Kill(); 
	}

	local hEntity;
	while (hEntity = Entities.FindByClassname(hEntity, "infected"))
	{
		local scope = hEntity.GetScriptScope();
		if (!("non_finale" in scope))
		{
			if (_mobsList.find(hEntity) == null)
			{
				_mobsList.append(hEntity);
			}
		}
	}
	local update = false;
	for (local i = 0; i < _mobsList.len(); i++)
	{
		if (!_mobsList[i].IsValid())
		{
			update = true;
			_mobsList.remove(i);
			_mobCurrent++;
			i--;
		}
	}
	if (update || (Time() - _updateTime) > 1.0)
	{
		_updateTime = Time();
		mobMax = Convars.GetFloat("director_no_mobs") ? 0 : ("MobMaxPending" in g_ModeScript.LocalScript.DirectorOptions ? g_ModeScript.LocalScript.DirectorOptions.MobMaxPending*4 : _mobMax);
		local time = "ScriptedFinale" in g_STLib.Funcs ? Time() - g_STLib.Funcs.ScriptedFinale.time : CPGetTime();
		if (_flags & MOB_HUD) g_STLib.Vars.HUD.Fields.mob.dataval = format("MegaMob: %d / " + mobMax, _mobCurrent);
		if (_flags & MOB_CHAT && update) CPTime(format("MegaMob: %d | Finale: %.03f |", _mobCurrent, time));
		if (_flags & MOB_CONSOLE && update) printl(format("MegaMob: %d / %d | Finale: %.03f | Total time: %.03f (%s)", _mobCurrent, mobMax, time, CPGetTime(), GetDisplayTime(CPGetTime())));
	}
	return self;
}