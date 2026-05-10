//Squirrel

/*
Main functions of the Speedrunner Tools addon and helpers for Scripted Maps mode.
*/

::g_STLib <-
{
	Items =
	{
		item0 = {cls = "weapon_ammo_spawn", mdl = "models/props/terror/ammo_stack.mdl"}
		item1 = {cls = "weapon_upgradepack_incendiary_spawn", mdl = "models/w_models/weapons/w_eq_incendiary_ammopack.mdl"}
		item2 = {cls = "weapon_upgradepack_explosive_spawn", mdl = "models/w_models/weapons/w_eq_explosive_ammopack.mdl"}
		item3 = {cls = "upgrade_laser_sight", mdl = "models/w_models/Weapons/w_laser_sights.mdl"}
		item4 = {cls = "weapon_pistol_spawn", mdl = "models/w_models/weapons/w_pistol_B.mdl"}
		item5 = {cls = "weapon_pistol_magnum_spawn", mdl = "models/w_models/weapons/w_desert_eagle.mdl"}
		item6 = {cls = "weapon_adrenaline_spawn", mdl = "models/w_models/weapons/w_eq_adrenaline.mdl"}
		item7 = {cls = "weapon_pain_pills_spawn", mdl = "models/w_models/weapons/w_eq_painpills.mdl"}
		item8 = {cls = "weapon_vomitjar_spawn", mdl = "models/w_models/weapons/w_eq_bile_flask.mdl"}
		item9 = {cls = "weapon_pipe_bomb_spawn", mdl = "models/w_models/weapons/w_eq_pipebomb.mdl"}
		item10 = {cls = "weapon_molotov_spawn", mdl = "models/w_models/weapons/w_eq_molotov.mdl"}
		item11 = {cls = "weapon_defibrillator_spawn", mdl = "models/w_models/weapons/w_eq_defibrillator.mdl"}
		item12 = {cls = "weapon_first_aid_kit_spawn", mdl = "models/w_models/weapons/w_eq_Medkit.mdl"}
		item13 = {cls = "weapon_shotgun_chrome_spawn", mdl = "models/w_models/weapons/w_pumpshotgun_A.mdl"}
		item14 = {cls = "weapon_pumpshotgun_spawn", mdl = "models/w_models/weapons/w_shotgun.mdl"}
		item15 = {cls = "weapon_shotgun_spas_spawn", mdl = "models/w_models/weapons/w_shotgun_spas.mdl"}
		item16 = {cls = "weapon_autoshotgun_spawn", mdl = "models/w_models/weapons/w_autoshot_m4super.mdl"}
		item17 = {cls = "weapon_smg_spawn", mdl = "models/w_models/weapons/w_smg_uzi.mdl"}
		item18 = {cls = "weapon_smg_silenced_spawn", mdl = "models/w_models/weapons/w_smg_a.mdl"}
		item19 = {cls = "weapon_rifle_spawn", mdl = "models/w_models/weapons/w_rifle_m16a2.mdl"}
		item20 = {cls = "weapon_rifle_ak47_spawn", mdl = "models/w_models/weapons/w_rifle_ak47.mdl"}
		item21 = {cls = "weapon_rifle_desert_spawn", mdl = "models/w_models/weapons/w_desert_rifle.mdl"}
		item22 = {cls = "weapon_hunting_rifle_spawn", mdl = "models/w_models/weapons/w_sniper_mini14.mdl"}
		item23 = {cls = "weapon_sniper_military_spawn", mdl = "models/w_models/weapons/w_sniper_military.mdl"}
		item24 = {cls = "weapon_rifle_m60_spawn", mdl = "models/w_models/weapons/w_m60.mdl"}
		item25 = {cls = "weapon_grenade_launcher_spawn", mdl = "models/w_models/weapons/w_grenade_launcher.mdl"}
		item26 = {cls = "weapon_chainsaw_spawn", mdl = "models/weapons/melee/w_chainsaw.mdl"}
		item27 = {cls = "prop_physics", mdl = "models/props_junk/gascan001a.mdl"}
		item28 = {cls = "prop_physics", mdl = "models/props_junk/propanecanister001a.mdl"}
		item29 = {cls = "prop_physics", mdl = "models/props_equipment/oxygentank01.mdl"}
		item30 = {cls = "prop_physics", mdl = "models/props_junk/explosive_box001.mdl"}
		item31 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_bat.mdl", name = "baseball_bat"}
		item32 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_cricket_bat.mdl", name = "cricket_bat"}
		item33 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_crowbar.mdl", name = "crowbar"}
		item34 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_electric_guitar.mdl", name = "electric_guitar"}
		item35 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_fireaxe.mdl", name = "fireaxe"}
		item36 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_frying_pan.mdl", name = "frying_pan"}
		item37 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_golfclub.mdl", name = "golfclub"}
		item38 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_katana.mdl", name = "katana"}
		item39 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_machete.mdl", name = "machete"}
		item40 = {cls = "weapon_melee_spawn", mdl = "models/weapons/melee/w_tonfa.mdl", name = "tonfa"}
		item41 = {cls = "weapon_ammo_spawn", mdl = "models/props_unique/spawn_apartment/coffeeammo.mdl"}
	}
	Funcs = {}
	Vars = {}
}

//ST Global Hooks (defined here to reset any structure if used and later removed from vs_st_speedrun)
::OnEntityOutput <- function(...);
::OnRestart <- function(...);
::OnPlayEnd <- function(...);
::OnPlayLine <- function(...);
::OnAutoFired <- function(...);
::OnAutoFired_Post <- function(...);
::OnAutoCB <- function(...);
::OnSafe <- function(...);
::OnEntityCreated <- function(...);
::OnEntityDestroyed <- function(...);

//========================================================================================================================
//Speedrunner Tools API
//========================================================================================================================

::SpawnItem <- function(sName, vecPos, vecAng = null, iCount = null, sTarget = null, fRadius = 0)
{
	if (vecAng == null) vecAng = Vector();
	if (iCount == null) iCount = 1;
	if (sTarget == null) sTarget = "ent_speedrun_item";
	if (g_STLib.Items.rawin(sName))
	{
		if (fRadius > 0) RemoveItemEx(vecPos, fRadius);
		local iValue = sName.slice(4, sName.len()).tointeger();
		local hTable = 
		{
			targetname = sTarget
			origin = vecPos
			angles = vecAng
			count = iCount
		}
		if (iValue >= 27 && iValue <= 30)
		{
			hTable.rawdelete("count");
			hTable.model <- g_STLib.Items.rawget(sName).mdl;
		}
		else if (iValue > 30)
		{
			if (iValue == 41) hTable.model <- g_STLib.Items.rawget(sName).mdl;
			else hTable.melee_weapon <- g_STLib.Items.rawget(sName).name;
		}
		return SpawnEntityFromTable(g_STLib.Items.rawget(sName).cls, hTable);
	}
	return error(format("[SpawnItem] Invalid name '%s' specified.\n", sName));
}

//============================================================
//============================================================

::SpawnZombie <- function(sName, vecPos = null, idle = false)
{
	local hTable =
	{
		infected = ZOMBIE_NORMAL
		mob = ZSPAWN_MOB
		tank = ZOMBIE_TANK
		witch = ZOMBIE_WITCH
		witch_bride = ZSPAWN_WITCHBRIDE
		hunter = ZOMBIE_HUNTER
		smoker = ZOMBIE_SMOKER
		boomer = ZOMBIE_BOOMER
		jockey = ZOMBIE_JOCKEY
		charger = ZOMBIE_CHARGER
		spitter = ZOMBIE_SPITTER
	}
	if (hTable.rawin(sName))
	{
		local sClass = sName;
		if (["infected", "witch", "witch_bride"].find(sName) == null) sClass = "player";
		else if (sName == "witch_bride")
		{
			sClass = "witch";
			Entities.First().PrecacheModel("models/infected/witch_bride.mdl");
		}
		local entList = [];
		local hEntity = null;
		while ((hEntity = Entities.FindByClassname(hEntity, sClass)) != null) entList.append(hEntity);
		ZSpawn({type = hTable.rawget(sName), pos = vecPos});
		while ((hEntity = Entities.FindByClassname(hEntity, sClass)) != null)
		{
			if (entList.find(hEntity) == null)
			{
				if (idle)
				{
					if (hEntity.IsPlayer()) hEntity.SetSenseFlags(BOT_CANT_FEEL | BOT_CANT_HEAR | BOT_CANT_SEE);
					else ReapplyInfectedFlags(INFECTED_FLAG_CANT_SEE_SURVIVORS | INFECTED_FLAG_CANT_HEAR_SURVIVORS | INFECTED_FLAG_CANT_FEEL_SURVIVORS, hEntity);
				}
				return hEntity;
			}
		}
		return null;
	}
	return error(format("[SpawnZombie] Invalid name '%s' specified.\n", sName));
}

//============================================================
//============================================================

::SpawnZombieEx <- function(sName, vecPos, vecAng = null, AttackOnSpawn = null, spawnTime = 0.0)
{
	if (vecAng == null) vecAng = Vector(0, RandomInt(0, 360), 0);
	if (AttackOnSpawn == null) AttackOnSpawn = false;
	if (type(sName) == "string")
	{
		if (sName == "infected")
		{
			sName =
			[
				"common_male_tshirt_cargos"
				"common_male_tankTop_jeans"
				"common_male_dressShirt_jeans"
				"common_female_tankTop_jeans"
				"common_female_tshirt_skirt"
			]
			sName = format("%s", sName[RandomInt(0, sName.len() - 1)]);
		}
		else if (["tank", "spitter"].find(sName) != null) g_ModeScript.DirectorOptions.cm_AggressiveSpecials <- AttackOnSpawn.tointeger();
		local hEntity = SpawnEntityFromTable("commentary_zombie_spawner", {origin = vecPos, angles = vecAng});
		EntFire("!activator", "SpawnZombie", sName, spawnTime, hEntity);
		EntFire("!activator", "Kill", null, spawnTime, hEntity);
	}
	else error("[SpawnZombieEx] Argument 1 is not valid.\n");
}

//============================================================
//============================================================

::SpawnZombieForCB <- function(vecPos, vecAng = null, startTime = 0, hPlayer = null, bNotSolid = null, sName = "ent_zombie_for_cb")
{
	if (vecAng == null) vecAng = Vector(0, RandomInt(0, 360), 0);
	if (bNotSolid == null) bNotSolid = false;
	local hEntity = SpawnEntityFromTable("infected", {origin = vecPos, angles = vecAng, targetname = sName});
	hEntity.ValidateScriptScope();
	ReapplyInfectedFlags(INFECTED_FLAG_CANT_SEE_SURVIVORS | INFECTED_FLAG_CANT_HEAR_SURVIVORS | INFECTED_FLAG_CANT_FEEL_SURVIVORS, hEntity);
	if (bNotSolid) DoEntFire("!self", "AddOutput", "solid 0", 0.0, null, hEntity);
	if (startTime == null) return hEntity;
	if (!("CBTable" in g_STLib))
	{
		g_STLib.CBTable <-
		{
			mobList = []
			Timer = function(hEntity, hPlayer, value)
			{
				if (!value)
				{
					/*		Approximate Minimal Values
					Min. anim. time is 0.5s at distance 235 units (can be farther, but... better leave this in case);
					Used step in 70 units for convenience; Mob think function equal to 0.1s;
					Rage distance found at 530 units for all maps, except c1, c4, c5, c13 @TODO: why?
					*/
					local fDistance = GetDistance(hEntity, hPlayer);
					if (fDistance > 1825) return Say(null, format("[CBZombie] Max. distance reached! (%.03f)", fDistance), false);
					if (["c1", "c4", "c5", "c13"].find(split(SessionState.MapName, "m")[0]) == null && fDistance > 530) Say(null, format("[CBZombie] Triggered, but for this map too far! (%.03f)", fDistance), false);
					local animTime = fDistance > 235 ? format("%f", (185+fDistance)/700).slice(0, 3).tofloat() : 0.5;
					NetProps.SetPropInt(hEntity, "m_nSequence", RandomInt(37, 39));
					DoEntFire("!activator", "RunScriptCode", "g_STLib.CBTable.Timer(activator, caller, 1)", animTime, hEntity, hPlayer);
					SendToServerConsole(format("echo %.03f >> [CBZombie] Name = %s, Dist = %.01f, AnimTime = " + animTime, CPGetTime(), hEntity.GetName(), fDistance));
					return;
				}
				CommandABot({bot = hEntity, target = hPlayer, cmd = BOT_CMD_ATTACK});
			}
			OnGameEvent_weapon_fire = function(event)
			{
				hPlayer = GetPlayerFromUserID(event.userid);
				if (!IsPlayerABot(hPlayer))
				{
					if (["vomitjar", "molotov", "pipe_bomb"].find(event.weapon) == null)
					{
						local hEntity = null;
						for (local i = 0; i < mobList.len(); i++)
						{
							if ((hEntity = mobList[i].bot).IsValid())
							{
								DoEntFire("!activator", "RunScriptCode", "g_STLib.CBTable.Timer(activator, caller, 0)", mobList[i].time, hEntity, hPlayer);
							}
							mobList.remove(i);
							i--;
						}
					}
				}
			}
		}
		__CollectEventCallbacks(g_STLib.CBTable, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
	}
	if (hPlayer != null)
	{
		DoEntFire("!activator", "RunScriptCode", "g_STLib.CBTable.Timer(activator, caller, 0)", startTime, hEntity, hPlayer);
		return hEntity;
	}
	g_STLib.CBTable.mobList.append({bot = hEntity, time = startTime.tofloat()});
	return hEntity;
}

//============================================================
//============================================================

::SpawnCommon <- function(sName = null, vecPos = null, vecAng = null, flags = 1)
{
	const FALLEN_VJAR_OR_MOLOTOV = 1;
	const FALLEN_PIPE = 2;
	const FALLEN_PILLS = 4;
	const FALLEN_MEDKIT = 8;
	const FALLEN_SIT = 16;
	const FALLEN_LYING = 32;
	Convars.SetValue("z_forcezombiemodel", 1);
	Convars.SetValue("z_fallen_max_count", 30);
	Convars.SetValue("z_background_limit", 99);
	if (type(sName) == "string") Convars.SetValue("z_forcezombiemodelname", sName);
	else Convars.SetValue("z_forcezombiemodelname", sName ? "common_male_fallen_survivor" : "common_male_ceda");
	if (vecAng == null) vecAng = Vector(0, RandomInt(0, 360), 0);
	local hEntity = SpawnZombie("infected");
	if (hEntity)
	{
		if (vecPos) hEntity.SetOrigin(vecPos);
		hEntity.SetAngles(QAngle(0, vecAng.y, 0));
		NetProps.SetPropInt(hEntity, "m_nFallenFlags", flags);
		if (flags & (FALLEN_SIT | FALLEN_LYING))
		{
			hEntity.ValidateScriptScope();
			local table = hEntity.GetScriptScope();
			table.sit_prepare <- true;
			table.time <- Time();
			table.seq <- 0;
			table.bbox <- null;
			table.pos <- Vector()
			table.ang <- Vector()
			table.Think <- function()
			{
				if (sit_prepare)
				{
					sit_prepare = NetProps.SetPropInt(self, "m_nSequence", flags & FALLEN_SIT ? 250 : 270);
					pos = self.GetOrigin();
					ang = self.GetAngles();
				}
				if (self.GetHealth() > 0 && NetProps.GetPropInt(self, "movetype") != MOVETYPE_NONE)
				{
					self.SetOrigin(pos);
					self.SetAngles(ang);
					if (!seq && (Time() - time) >= (flags & FALLEN_SIT ? 3.5 : 4.9))
					{
						seq = flags & FALLEN_SIT ? RandomInt(251, 259) : RandomInt(271, 278);
						NetProps.SetPropInt(self, "m_nSequence", seq);
						bbox = SpawnEntityFromTable("env_player_blocker", {origin = self.GetOrigin()});
						EntFire("!activator", "AddOutput", "maxs 13 13 " + (flags & FALLEN_SIT ? 32 : 16), 0.0, bbox);
						EntFire("!activator", "AddOutput", "mins -13 -13 0", 0.0, bbox);
						DoEntFire("!self", "SetParent", "!activator", 0.0, self, bbox);
						EntFire("!activator", "Enable", null, 0.0, bbox);
						EntFire("!self", "AddOutput", "solid 0");
					}
					if (seq)
					{
						NetProps.SetPropInt(self, "m_nSequence", seq);
						EntFire("!self", "RunScriptCode", format("NetProps.SetPropInt(self, \"m_nSequence\", %d)", seq), 0.01);
						EntFire("!self", "RunScriptCode", format("NetProps.SetPropInt(self, \"m_nSequence\", %d)", seq), 0.05);
					}
				}
				else EntFire("!activator", "Disable", null, 0.0, bbox);
			}
			AddThinkToEnt(hEntity, "Think");
			ReapplyInfectedFlags(INFECTED_FLAG_CANT_SEE_SURVIVORS | INFECTED_FLAG_CANT_HEAR_SURVIVORS | INFECTED_FLAG_CANT_FEEL_SURVIVORS, hEntity);
			hEntity.__KeyValueFromString("targetname", "ent_zombie_sit");
			
			::SpawnCommon_Think <- function()
			{
				if (!Ent("ent_zombie_sit")) return caller.Kill();
				local hPlayer;
				while (hPlayer = Entities.FindByClassname(hPlayer, "player"))
				{
					local hEntity = NetProps.GetPropEntity(hPlayer, "m_hGroundEntity");
					if (hEntity && hEntity.GetClassname() == "env_player_blocker" && (hEntity = hEntity.GetMoveParent()))
					{
						DoEntFire("!self", "RunScriptCode", "self.TakeDamage(50, DMG_CLUB, activator)", 0.01, hPlayer, hEntity);
					}
				}
			}
			OnGameFrame("SpawnCommon_Think");
		}
	}
	else error("Unable to spawn common infected due to limit.\n");
	Convars.SetValue("z_forcezombiemodel", 0);
	Convars.SetValue("z_fallen_max_count", 1);
	Convars.SetValue("z_forcezombiemodelname", "common_male01");
	Convars.SetValue("z_background_limit", 20);
	return hEntity;
}

//============================================================
//============================================================

::SpawnTrigger <- function(sName, vecPos, vecMaxs = null, vecMins = null, sFunc = null, iType = null, output = null, sClass = "trigger_multiple")
{
	if (vecMaxs == null) vecMaxs = Vector(64, 64, 128);
	if (vecMins == null) vecMins = Vector(-64, -64, 0);
	if (sFunc == null) sFunc = "OnEntityOutput";
	if (iType == null) iType = TR_CLIENTS;
	if (output == null) output = "OnStartTouch";
	local hEntity = SpawnEntityFromTable(sClass, {targetname = sName, origin = vecPos, spawnflags = iType});
	hEntity.__KeyValueFromVector("maxs", vecMaxs);
	hEntity.__KeyValueFromVector("mins", vecMins);
	hEntity.__KeyValueFromInt("solid", 2);
	hEntity.ValidateScriptScope();
	foreach (value in split(output, ","))
	{
		value = strip(value);
		hEntity.__KeyValueFromString(value, format("!caller,RunScriptCode,%s()", sFunc));
		hEntity.__KeyValueFromString(value, format("!caller,RunScriptCode,output <- \"%s\"", value));
	}
	if (iType & TR_OFF) DoEntFire("!self", "Disable", "", 0.0, null, hEntity);
	return hEntity;
}

//============================================================
//============================================================

::RemoveItem <- function(sName = null)
{
	local iCount = 0;
	if (sName == null)
	{
		foreach (key, val in g_STLib.Items) iCount += RemoveItem(key);
		return iCount;
	}
	if (g_STLib.Items.rawin(sName))
	{
		local hEntity = null;
		while ((hEntity = Entities.FindByModel(hEntity, g_STLib.Items.rawget(sName).mdl)) != null)
		{
			iCount++;
			hEntity.Kill();
		}
		return iCount;
	}
	return error(format("[RemoveItem] Invalid name '%s' specified.\n", sName));
}

//============================================================
//============================================================

::RemoveItemEx <- function(vecPos, fRadius = 5.0)
{
	local sClass = "";
	local sModel = "";
	local iCount = 0;
	local hEntity = null;
	while ((hEntity = Entities.FindInSphere(hEntity, vecPos, fRadius)) != null)
	{
		sClass = hEntity.GetClassname();
		if (sClass.find("weapon_") != null || sClass == "upgrade_laser_sight" || sClass == "prop_physics")
		{
			sModel = NetProps.GetPropString(hEntity, "m_ModelName");
			for (local i = 0; i < g_STLib.Items.len(); i++)
			{
				if (g_STLib.Items.rawget(format("item%d", i)).mdl == sModel)
				{
					iCount++;
					hEntity.Kill();
					break;
				}
			}
		}
	}
	return iCount;
}

//============================================================
//============================================================

::RemoveSlot <- function(hPlayer, slot)
{
	if (!IsPlayer(hPlayer)) return;
	local hTable = {};
	GetInvTable(hPlayer, hTable);
	slot = "slot" + slot;
	if (hTable.rawin(slot)) hTable.rawget(slot).Kill();
}

//============================================================
//============================================================

::RemoveCI <- function()
{
	local hEntity = null;
	while ((hEntity = Entities.FindByClassname(hEntity, "infected")) != null)
	{
		hEntity.Kill();
	}
}

//============================================================
//============================================================

::DirectorStop <- function(bMode = false)
{
	if (bMode)
	{
		Convars.SetValue("director_no_bosses", 0);
		Convars.SetValue("director_no_mobs", 0);
		Convars.SetValue("director_no_specials", 0);
		Convars.SetValue("z_common_limit", 30);
		return;
	}
	Convars.SetValue("director_no_bosses", 1);
	Convars.SetValue("director_no_mobs", 1);
	Convars.SetValue("director_no_specials", 1);
	Convars.SetValue("z_common_limit", 0);
	local sClass = "";
	local hEntity = null;
	while (hEntity = Entities.Next(hEntity))
	{
		if (NetProps.GetPropInt(hEntity, "m_iTeamNum") == 3)
		{
			sClass = hEntity.GetClassname();
			if (sClass == "player" || sClass == "infected" || sClass == "witch")
			{
				hEntity.Kill();
			}
		}
	}
}

//============================================================
//============================================================

::AutoOpen <- function(value = false)
{
	if (value)
	{
		local hEntity = null;
		local sModel = "";
		while ((hEntity = Entities.FindByClassname(hEntity, "prop_door_rotating_checkpoint")) != null)
		{
			sModel = NetProps.GetPropString(hEntity, "m_ModelName");
			if (sModel == "models/props_doors/checkpoint_door_01.mdl" || sModel == "models/props_doors/checkpoint_door_-01.mdl")
			{
				local dist = 0.0;
				local dist_max = 500.0;
				local hClient = null;
				local hPlayer = null;
				while (hPlayer = Entities.FindByClassname(hPlayer, "player"))
				{
					if (hPlayer.IsSurvivor() && (dist = (hEntity.GetOrigin() - hPlayer.GetOrigin()).Length()) < dist_max)
					{
						dist_max = dist;
						hClient = hPlayer;
					}
				}
				return DoEntFire("!self", "PlayerOpen", "", 0.0, hClient, hEntity);
			}
		}
	}
	else
	{
		AutoOpen(true);
		OnGameFrame("AutoOpen(true)", null, 0.6);
	}
}

//============================================================
//============================================================

::AutoFire <- function(hPlayer, vecAng = null, vecPos = null, bLoop = null, bUp = null, fRadius = null, hClient = null, delayTime = null, data = null, method3D = null, vecVel = null)
{
	if ((hPlayer = Ent(hPlayer)) == null || !hPlayer.IsPlayer()) return;
	if (fRadius == null) fRadius = method3D ? 61.0 : 25.0;
	if (delayTime == null) delayTime = 0.0;
	if (data == null) data = 0;
	g_STLib.AF1 <-
	{
		player = hPlayer
		client = hClient
		prohibit = false
		delay = false
		duck = bUp ? 0 : IN_DUCK
		created = false
		GetDist = function(hPlayer, hPlayer2)
		{
			if (method3D) return (hPlayer.GetOrigin() - hPlayer2.GetOrigin()).Length();
			return (hPlayer.GetOrigin() - hPlayer2.GetOrigin()).Length2D();
		}
		IsFire = function()
		{
			if (delay && !player.IsDead())
			{
				if (IsPlayer(client))
				{
					if (GetDist(client, player) < fRadius) return true;
					return false;
				}
				hClient = null;
				while ((hClient = Entities.FindByClassname(hClient, "player")) != null)
				{
					if (!IsPlayerABot(hClient) && !hClient.IsDead() && hClient != player && GetDist(hClient, player) < fRadius) return true;
				}
			}
			return false;
		}
		Think = function()
		{
			if (player.IsValid())
			{
				if (!prohibit && !g_ST.restart)
				{
					TeleportEntity(player, vecPos, vecAng, null);
					if (IsFire())
					{
						if (!bLoop)
						{
							prohibit = true;
							OnGameFrame("g_STLib.AF1.ThinkProj", null, 0.5);
						}
						NetProps.SetPropInt(player, "m_afButtonForced", duck | IN_ATTACK);
						return;
					}
					NetProps.SetPropInt(player, "m_afButtonForced", duck);
					return;
				}
				NetProps.SetPropInt(player, "m_afButtonForced", 0);
			}
			caller.Kill();
		}
		ThinkProj = function()
		{
			local hEntity = null;
			while ((hEntity = Entities.FindByClassname(hEntity, "grenade_launcher_projectile")) != null)
			{
				if (NetProps.GetPropEntity(hEntity, "m_hThrower") == player)
				{
					if (!created)
					{
						if (developer())
						{
							created = hEntity.GetVelocity();
							CPTime(format("[AF1] Vector(%.03f, %.03f, %.03f) Time:", created.x, created.y, created.z));
						}
						if (type(vecVel) == "instance") hEntity.SetVelocity(vecVel);
						created = true;
					}
					hPlayer = null;
					while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
					{
						if (hEntity == NetProps.GetPropEntity(hPlayer, "m_hGroundEntity"))
						{
							caller.Kill();
							OnAutoFired(player, data);
							EntFire("!activator", "RunScriptCode", format("OnAutoFired_Post(self, Ent(%d), %d)", hPlayer.GetEntityIndex(), data), 0.01, player);
							SendToServerConsole(format("echo %.03f >> Completed AutoFire successfully!", CPGetTime()));
							return;
						}
					}
				}
			}
		}
	}
	hPlayer = null;
	while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null) NetProps.SetPropInt(hPlayer, "m_afButtonForced", 0);
	OnGameFrame("g_STLib.AF1.Think");
	EntFire("worldspawn", "RunScriptCode", "g_STLib.AF1.delay = true", delayTime);
}

//============================================================
//============================================================

::AutoFire2 <- function(hPlayer, vecAng = null, vecPos = null, bLoop = null, bUp = null, fRadius = null, hClient = null, delayTime = null, data = null, method3D = null, bScripted = null)
{
	if ((hPlayer = Ent(hPlayer)) == null || !hPlayer.IsPlayer()) return;
	if (fRadius == null) fRadius = 70.0;
	if (delayTime == null) delayTime = 0.0;
	if (data == null) data = 0;
	if (!("g_AF2_Vectors" in getroottable())) ::g_AF2_Vectors <- {};
	g_STLib.AF2 <-
	{
		player = hPlayer
		client = hClient
		prohibit = false
		delay = false
		duck = bUp ? 0 : IN_DUCK
		found = false
		created = true
		GetDist = function(hPlayer, hPlayer2)
		{
			if (method3D) return (hPlayer.GetOrigin() - hPlayer2.GetOrigin()).Length();
			return (hPlayer.GetOrigin() - hPlayer2.GetOrigin()).Length2D();
		}
		IsFire = function()
		{
			if (delay && !player.IsDead())
			{
				if (IsPlayer(client))
				{
					if (GetDist(client, player) < fRadius) return true;
					return false;
				}
				hClient = null;
				while ((hClient = Entities.FindByClassname(hClient, "player")) != null)
				{
					if (!IsPlayerABot(hClient) && !hClient.IsDead() && hClient != player && GetDist(hClient, player) < fRadius) return true;
				}
			}
			return false;
		}
		Think = function()
		{
			if (player.IsValid())
			{
				if (!prohibit && !g_ST.restart)
				{
					TeleportEntity(player, vecPos, vecAng, null);
					if (IsFire())
					{
						if (!bLoop)
						{
							bLoop = true;
							EntFire("worldspawn", "RunScriptCode", "g_STLib.AF2.Stop()", 0.25);
							OnGameFrame("g_STLib.AF2.ThinkProj", null, 0.5);
							if (bScripted) EntFire("worldspawn", "RunScriptCode", "g_STLib.AF2.CheckEarlyTick()", 0.21);
						}
						NetProps.SetPropInt(player, "m_afButtonForced", duck);
						return;
					}
					NetProps.SetPropInt(player, "m_afButtonForced", duck | IN_ATTACK);
					return;
				}
				NetProps.SetPropInt(player, "m_afButtonForced", 0);
			}
			caller.Kill();
		}
		Stop = function()
		{
			prohibit = true;
			OnAutoFired(player, data);
			SendToServerConsole(format("echo %.03f >> Completed AutoFire2 successfully!", CPGetTime()));
			if (bScripted && !found)
			{
				local hEntity = null;
				while ((hEntity = Entities.FindByClassname(hEntity, "vomitjar_projectile")) != null)
				{
					if (NetProps.GetPropEntity(hEntity, "m_hThrower") == player)
					{
						g_AF2_Vectors.rawset("boost_" + data, {origin = hEntity.GetOrigin(), velocity = hEntity.GetVelocity()});
						return;
					}
				}
			}
		}
		CheckEarlyTick = function(value = 0)
		{
			local hEntity = null;
			while ((hEntity = Entities.FindByClassname(hEntity, "vomitjar_projectile")) != null)
			{
				if (NetProps.GetPropEntity(hEntity, "m_hThrower") == player)
				{
					if (value == 0)
					{
						found = true;
						hEntity.__KeyValueFromInt("solid", 0);
						if ("boost_" + data in g_AF2_Vectors) EntFire("worldspawn", "RunScriptCode", "g_STLib.AF2.CheckEarlyTick(1)", 0.01);
						else Say(null, "[AF2] Vector isn't yet saved. Round restart required.", false);
					}
					else if (value == 1)
					{
						hEntity.__KeyValueFromInt("solid", 2);
						hEntity.SetOrigin(g_AF2_Vectors.rawget("boost_" + data).origin);
						hEntity.SetVelocity(g_AF2_Vectors.rawget("boost_" + data).velocity);
						SendToServerConsole(format("echo %.03f >> Detected early projectile spawn, but fixed.", CPGetTime()));
						return;
					}
				}
			}
		}
		ThinkProj = function()
		{
			local hEntity = null;
			while ((hEntity = Entities.FindByClassname(hEntity, "vomitjar_projectile")) != null)
			{
				if (NetProps.GetPropEntity(hEntity, "m_hThrower") == player)
				{
					if (created && developer()) created = CPTime("[AF2] Created:");
					hPlayer = null;
					while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
					{
						if (hEntity == NetProps.GetPropEntity(hPlayer, "m_hGroundEntity"))
						{
							caller.Kill();
							if (developer()) CPTime("[AF2] Touch time:");
							EntFire("!activator", "RunScriptCode", format("OnAutoFired_Post(self, Ent(%d), %d)", hPlayer.GetEntityIndex(), data), 0.01, player);
							return;
						}
					}
				}
			}
		}
	}
	hPlayer = null;
	while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null) NetProps.SetPropInt(hPlayer, "m_afButtonForced", 0);
	OnGameFrame("g_STLib.AF2.Think");
	EntFire("worldspawn", "RunScriptCode", "g_STLib.AF2.delay = true", delayTime);
}

//============================================================
//============================================================

::AutoFire3 <- function(hPlayer, aPlayers, fPitch = null, sWeapon = null, bScripted = null, data = 0)
{
	if ((hPlayer = Ent(hPlayer)) == null || !hPlayer.IsPlayer()) return;
	if (type(aPlayers) == "instance") aPlayers = [aPlayers];
	if (type(aPlayers) != "array") return Say(null, "[AF3] Argument 2 must be 'instance' or 'array'.", false);
	if (fPitch == null) fPitch = 2.0;
	if (!("g_AF3_Vectors" in getroottable())) ::g_AF3_Vectors <- {};
	g_STLib.AF3 <-
	{
		player = hPlayer
		yaw = 0.0
		found = false
		created = true
		OnGameEvent_weapon_fire = function(event)
		{
			if (GetPlayerFromUserID(event.userid) == player && !g_ST.restart && ["pipe_bomb", "molotov"].find(event.weapon) != null && (sWeapon == null || event.weapon == sWeapon))
			{
				foreach (idx, name in aPlayers)
				{
					NetProps.SetPropInt(name, "m_afButtonForced", IN_JUMP);
					EntFire("!activator", "RunScriptCode", "NetProps.SetPropInt(self, \"m_afButtonForced\", 0)", 0.01, name);
					if (bScripted && IsPlayer(name))
					{	
						local fDist = GetDistance(player, name);
						if (fDist > 60 && fDist < 250)
						{
							//Could we use linear regression?
							EntFire("!activator", "RunScriptCode", "g_STLib.AF3.ApplyFix(self)", (115.25+fDist)/750, name);
						}
					}
				}
				sWeapon = event.weapon;
				yaw = player.GetAngles().y;
				ClearEvent("weapon_fire", this);
				OnGameFrame("g_STLib.AF3.Think", null, 0.3);
				if (bScripted)
				{
					EntFire("worldspawn", "RunScriptCode", "g_STLib.AF3.Think(true)", 0.085);
					EntFire("worldspawn", "RunScriptCode", "g_STLib.AF3.Think(true)", 0.115);
				}
				if (developer()) OnGameFrame("g_STLib.AF3.Debug", null, 0.5);
				//SpeedrunStart();
			}
		}
		Think = function(value = false)
		{
			if (IsPlayer(player)) TeleportEntity(player, null, Vector(fPitch, yaw, 0), null);
			if (bScripted)
			{
				local hEntity = null;
				while ((hEntity = Entities.FindByClassname(hEntity, sWeapon + "_projectile")) != null)
				{
					if (NetProps.GetPropEntity(hEntity, "m_hThrower") == player)
					{
						//@TODO: In case with molotov will be ricochet once.
						hEntity.__KeyValueFromInt("solid", 0);
						OnAutoFired(player, data);
						bScripted = false;
						if (value)
						{
							found = true;
							SendToServerConsole(format("echo %.03f >> Detected early projectile spawn.", CPGetTime()));
						}
					}
				}
			}
		}
		ApplyFix = function(hPlayer, value = 0)
		{
			local hEntity = null;
			while ((hEntity = Entities.FindByClassname(hEntity, sWeapon + "_projectile")) != null)
			{
				if (NetProps.GetPropEntity(hEntity, "m_hThrower") == player)
				{
					if (value == 0)
					{
						hPlayer.SetVelocity(Vector());
						NetProps.SetPropInt(hPlayer, "m_afButtonForced", IN_DUCK);
						EntFire("!activator", "RunScriptCode", "NetProps.SetPropInt(self, \"m_afButtonForced\", 0)", 0.01, hPlayer);
						EntFire("!activator", "RunScriptCode", "g_STLib.AF3.ApplyFix(self, 1)", 0.01, hPlayer);
						if (developer()) CPTime(format("[AF3] %s's boost time:", GetCharacterDisplayName(hPlayer)));
					}
					else if (value == 1)
					{
						local survivor = NetProps.GetPropInt(hPlayer, "m_survivorCharacter");
						local vecVel = hEntity.GetVelocity();
						if (!("boost_" + data in g_AF3_Vectors)) g_AF3_Vectors.rawset("boost_" + data, array(4, null));
						local aVecs = g_AF3_Vectors.rawget("boost_" + data);
						if (found)
						{
							if (aVecs[survivor] != null) vecVel = aVecs[survivor];
							else Say(null, "[AF3] Vector isn't yet saved. Round restart required.", false);
						}
						else aVecs[survivor] = vecVel;
						hPlayer.SetVelocity(QAngle(fPitch, yaw+180, 0).Forward().Scale(76.18)); //Taken from original boost.
						NetProps.SetPropVector(hPlayer, "m_vecBaseVelocity", vecVel);
						SendToServerConsole(format("echo %.03f >> Completed AutoFire3 scripted Long Boost for: %s", CPGetTime(), GetCharacterDisplayName(hPlayer)));
						EntFire("!activator", "RunScriptCode", format("OnAutoFired_Post(self, Ent(%d), %d)", hPlayer.GetEntityIndex(), data), 0.01, player);
					}
				}
			}
		}
		Debug = function()
		{
			local hEntity = null;
			while ((hEntity = Entities.FindByClassname(hEntity, sWeapon + "_projectile")) != null)
			{
				if (NetProps.GetPropEntity(hEntity, "m_hThrower") == player)
				{
					if (created) created = CPTime(format("[AF3] %s created:", sWeapon));
					foreach (idx, name in aPlayers)
					{
						if (NetProps.GetPropEntity(name, "m_hGroundEntity") == hEntity)
						{
							CPTime(format("[AF3] %s's touch time:", GetCharacterDisplayName(name)));
						}
					}
				}
			}
		}
	}
	__CollectEventCallbacks(g_STLib.AF3, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
}

//============================================================
//============================================================

::AFStop <- function()
{
	if ("AF1" in g_STLib) g_STLib.AF1.prohibit = true;
	if ("AF2" in g_STLib) g_STLib.AF2.prohibit = true;
	if ("AF3" in g_STLib) ClearEvent("weapon_fire", g_STLib.AF3);
}

//============================================================
//============================================================

::ScriptedTP <- function(hPlayer, hLeader, fTime = 6.1, bStuckTeleport = null, eMode = 0)
{
	if ((hPlayer = Ent(hPlayer)) == null || !hPlayer.IsPlayer() || hPlayer.IsDead() || hPlayer.IsDying() || hPlayer.IsIncapacitated()) return Say(null, "[ScriptedTP] Invalid player.", false);
	if (!bStuckTeleport)
	{
		if ((hLeader = Ent(hLeader)) == null || !hLeader.IsPlayer() || hLeader.IsDead() || hLeader.IsDying()) return Say(null, "[ScriptedTP] Invalid leader.", false);
		bStuckTeleport = false;
	}
	if (fTime > 0)
	{
		local name = GetCharacterDisplayName(hPlayer);
		if (eMode)
		{
			local func = "g_STLib.Funcs.ScTP_" + name;
			compilestring(format("%s <- function() CommandABot({cmd = BOT_CMD_RESET, bot = Ent(\"!%s\")});", func, name))();
			OnGameFrame(func, eMode < 2 ? 0.2 : 4.0, fTime);
		}
		EntFire("worldspawn", "RunScriptCode", format("ScriptedTP(\"!%s\", \"!%s\", 0, %d)", name, GetCharacterDisplayName(hLeader), bStuckTeleport.tointeger()), fTime);
		return;
	}
	if (bStuckTeleport)
	{
		if (IsPlayerABot(hPlayer)) Say(null, "[ScriptedTP] Done, but player a bot.", false);
		hLeader = null;
		local dist = 0.0;
		local dist_max = MAX_TRACE_LENGTH;
		local hEntity = null;
		while (hEntity = Entities.FindByClassname(hEntity, "player"))
		{
			if (hEntity.IsSurvivor() && !hEntity.IsDead() && !hEntity.IsDying() && hEntity != hPlayer && (dist = (hEntity.GetOrigin() - hPlayer.GetOrigin()).Length()) < dist_max)
			{
				dist_max = dist;
				hLeader = hEntity;
			}
		}
		if (!hLeader) return Say(null, "[ScriptedTP] No player to teleport.", false);
		hPlayer.__KeyValueFromVector("origin", hLeader.GetOrigin());
		SendToServerConsole(format("echo %.03f >> [ScriptedTP] Completed scripted stuck warp.", CPGetTime()));
		return;
	}
	if (IsPlayerABot(hLeader)) Say(null, "[ScriptedTP] Done, but leader a bot.", false);
	if (!IsPlayerABot(hPlayer)) Say(null, "[ScriptedTP] Done, but player isn't idle.", false);
	if (GetDistance(hLeader, hPlayer) < 1500) Say(null, format("[ScriptedTP] Done, but distance (%.01f) between players is too close.", GetDistance(hLeader, hPlayer)), false);
	//@TODO: If player see idle player, it won't notify. Add trace hull?
	local fAng = hLeader.GetAngles().y*PI/180;
	local fShift = cos(hLeader.EyeAngles().x*PI/180)*TELEPORT_SHIFT;
	hPlayer.SetOrigin(hLeader.GetOrigin() + Vector(cos(fAng)*fShift, sin(fAng)*fShift, 0));
	SendToServerConsole(format("echo %.03f >> [ScriptedTP] Completed scripted warp.", CPGetTime()));
}

//============================================================
//============================================================

::ScriptedShots <- function(hPlayer, fDistance = 1000)
{
	if ((hPlayer = Ent(hPlayer)) == null || !hPlayer.IsPlayer()) return Say(null, "[ScriptedShots] Invalid player specified.", false);
	if (!("ScriptedShots" in g_STLib))
	{
		g_STLib.ScriptedShots <-
		{
			playersList = []
			time = array(MAXCLIENTS + 1, 0.0)
			dist = array(MAXCLIENTS + 1, 0.0)
			Think = function()
			{
				local bFound = false;
				for (local i = 0; i < playersList.len(); i++)
				{
					hPlayer = playersList[i];
					if (!IsPlayer(hPlayer))
					{
						printl(CPGetTime() + " >> [ScriptedShots] Auto-removed.");
						playersList.remove(i);
						i--;
						continue;
					}
					bFound = true;
					if (!hPlayer.IsSurvivor() || hPlayer.IsDying() || hPlayer.IsDead()) continue;
					local client = hPlayer.GetEntityIndex();
					if ((Time() - time[client]) > RandomFloat(0.0, 0.5))
					{
						local hEntity = null;
						while (hEntity = Entities.FindByClassname(hEntity, "infected"))
						{
							if (hEntity.GetHealth() > 0 && NetProps.GetPropInt(hEntity, "movetype") != MOVETYPE_NONE)
							{
								if (GetDistance(hPlayer, hEntity) < dist[client])
								{
									local hTrace =
									{
										start = hPlayer.EyePosition()
										end = hEntity.GetOrigin() + Vector(0, 0, 34)
										ignore = hPlayer
										mask = TRACE_MASK_SHOT
									}
									TraceLine(hTrace);
									if (hTrace.hit && hTrace.enthit == hEntity)
									{
										hEntity.TakeDamage(50, DMG_BULLET | DMG_HEADSHOT, hPlayer);
										time[client] = Time();
										break;
									}
								}
							}
						}
					}
				}
				if (!bFound) caller.Kill();
			}
		}
	}
	this = g_STLib.ScriptedShots;
	local idx = playersList.find(hPlayer);
	if (!fDistance)
	{
		if (idx == null) return Say(null, "[ScriptedShots] Not found for removal: " + hPlayer, false);
		playersList.remove(idx);
		return printl(CPGetTime() + " >> [ScriptedShots] Removed successfully: " + hPlayer);
	}
	dist[hPlayer.GetEntityIndex()] = fDistance;
	if (idx != null) return;
	playersList.append(hPlayer);
	OnGameFrame("g_STLib.ScriptedShots.Think", 0.1);
}

//============================================================
//============================================================

::PlayerKill <- function(hPlayer)
{
	if (!IsPlayer(hPlayer)) return;
	if (hPlayer.IsDying() || hPlayer.IsDead()) return;
	hPlayer.SetReviveCount(2);
	hPlayer.SetHealthBuffer(0);
	NetProps.SetPropInt(hPlayer, "m_fFlags", NetProps.GetPropInt(hPlayer, "m_fFlags") & ~FL_GODMODE);
	DoEntFire("!self", "SetHealth", "-1", 0.0, null, hPlayer);
}

//============================================================
//============================================================

::PlayerKillFromWeapon <- function(hPlayer, hAttacker, iShots = null, bWaitForWeaponReady = false, fTime = 1.0)
{
	if (iShots == null) iShots = 4;
	if (!("PKFW" in g_STLib))
	{
		g_STLib.PKFW <-
		{
			IsPKFW = array(MAXCLIENTS + 1, false)
			Weapons =
			{
				weapon_pumpshotgun =
				{
					time = 0.733
					bullet = 10
					dmg = 12.0
					dmg_type = g_MapScript.DMG_BUCKSHOT
					sound = "Shotgun.Fire"
				}
				weapon_shotgun_chrome =
				{
					time = 0.733
					bullet = 8
					dmg = 15.0
					dmg_type = g_MapScript.DMG_BUCKSHOT
					sound = "Shotgun_Chrome.Fire"
				}
				weapon_autoshotgun =
				{
					time = 0.266
					bullet = 11
					dmg = 11.0
					dmg_type = g_MapScript.DMG_BUCKSHOT
					sound = "AutoShotgun.Fire"
				}
				weapon_shotgun_spas =
				{
					time = 0.266
					bullet = 9
					dmg = 13.0
					dmg_type = g_MapScript.DMG_BUCKSHOT
					sound = "AutoShotgun_Spas.Fire"
				}
				//@TODO: More weapons?
			}
			IsValid = function(hPlayer, hAttacker)
			{
				if (hPlayer == null || hAttacker == null)
				{
					Say(null, "[PKFW] Invalid player.", false);
					return null;
				}
				if (hAttacker.IsIncapacitated() || hAttacker.IsDead() || hPlayer.IsDead() || GetDistance(hPlayer, hAttacker) > 110.0)
				{
					Say(null, "[PKFW] Aborted! Wrong situation for use.", false);
					return null;
				}
				local hEntity = hAttacker.GetActiveWeapon();
				local sWeapon = "";
				if (hEntity == null || !g_STLib.PKFW.Weapons.rawin(sWeapon = hEntity.GetClassname()))
				{
					Say(null, format("[PKFW] Weapon \"%s\" is not in PKFW.Weapons table.", sWeapon), false);
					return null;
				}
				if (NetProps.GetPropInt(hEntity, "m_iClip1") < 1)
				{
					Say(null, "[PKFW] Not enough ammo in clip.", false);
					return null;
				}
				if (Convars.GetStr("z_difficulty").find("mpossible") == null)
				{
					Say(null, "[PKFW] Current difficulty is not \"Impossible\".", false);
					return null;
				}
				if (NetProps.GetPropInt(hEntity, "m_bInReload"))
				{
					Say(null, "[PKFW] Done, but weapon being reloaded.", false);
				}
				//@TODO: Else checks?
				return g_STLib.PKFW.Weapons.rawget(sWeapon);
			}
			TimerCallback = function(client, attacker, iShots)
			{
				local hPlayer = GetPlayerFromCharacter(client);
				local hAttacker = GetPlayerFromCharacter(attacker);
				local hTable = {};
				if ((hTable = g_STLib.PKFW.IsValid(hPlayer, hAttacker)) == null)
				{
					g_STLib.PKFW.IsPKFW[hAttacker.GetEntityIndex()] = false;
					return;
				}
				local hEntity = hAttacker.GetActiveWeapon();
				NetProps.SetPropInt(hEntity, "m_iClip1", NetProps.GetPropInt(hEntity, "m_iClip1") - 1);
				EmitSound(hAttacker.EyePosition(), hTable.sound);
				hPlayer.TakeDamage(0.0, 0, hAttacker); //Take zero damage before incap to show friendlyfire hud messages.
				for (local i = 1; i <= hTable.bullet; i++) hPlayer.TakeDamage(hTable.dmg, hTable.dmg_type, hAttacker);
				if ((iShots -= 1) > 0)
				{
					EntFire("worldspawn", "RunScriptCode", format("g_STLib.PKFW.TimerCallback(%d, %d, %d)", client, attacker, iShots), hTable.time);
					return;
				}
				g_STLib.PKFW.IsPKFW[hAttacker.GetEntityIndex()] = false;
				EntFire("!activator", "RunScriptCode", "if (\"PKFW_Post\" in g_STLib.Funcs) g_STLib.Funcs.PKFW_Post(self)", 0.01, hAttacker);
			}
		}
	}
	if (hPlayer == null || hAttacker == null)
	{
		Say(null, "[PKFW] Invalid player.", false);
		return;
	}
	local client = NetProps.GetPropInt(hPlayer, "m_survivorCharacter");
	local attacker = NetProps.GetPropInt(hAttacker, "m_survivorCharacter");
	local idx = hAttacker.GetEntityIndex();
	if (g_STLib.PKFW.IsPKFW[idx])
	{
		Say(null, "[PKFW] Already called.", false);
		return;
	}
	g_STLib.PKFW.IsPKFW[idx] = true;
	iShots = iShots > 0 ? iShots : 1;
	if (bWaitForWeaponReady)
	{
		EntFire("worldspawn", "RunScriptCode", format("g_STLib.PKFW.TimerCallback(%d, %d, %d)", client, attacker, iShots), fTime.tofloat());
		return;
	}
	g_STLib.PKFW.TimerCallback(client, attacker, iShots);
}

//============================================================
//============================================================

::PlayerGod <- function(hPlayer, bGod)
{
	if (!IsPlayer(hPlayer)) return;
	if (bGod) NetProps.SetPropInt(hPlayer, "m_fFlags", NetProps.GetPropInt(hPlayer, "m_fFlags") | FL_GODMODE);
	else NetProps.SetPropInt(hPlayer, "m_fFlags", NetProps.GetPropInt(hPlayer, "m_fFlags") & ~FL_GODMODE);
}