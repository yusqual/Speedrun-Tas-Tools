//Squirrel

/*
The list of Squirrel based wrapper functions and constants available in Left 4 Dead 2 for a general purpose.
Defines from DirectorScript scope were collected in the constants table for convenience.
*/

::_ <- null;

const MAXCLIENTS = 32;
const MAXENTS = 2048;
const MAX_TRACE_LENGTH = 56755.8;
const TELEPORT_SHIFT = -10.0;
const LT = "ent_lt_";
const MDL_NI = 0;
const MDL_RO = 1;
const MDL_CO = 2;
const MDL_EL = 3;
const MDL_BI = 0;
const MDL_ZO = 1;
const MDL_LO = 2;
const MDL_FR = 3;

//SpawnCommon flags.
const FALLEN_VJAR_OR_MOLOTOV = 1;
const FALLEN_PIPE = 2;
const FALLEN_PILLS = 4;
const FALLEN_MEDKIT = 8;

//m_upgradeBitVec flags.
const UPGRFL_INCENDIARY = 1;
const UPGRFL_EXPLOSIVE = 2;
const UPGRFL_LASER = 4;

//CBaseTrigger spawnflags.
const TR_CLIENTS = 1;
const TR_NPCS = 2;
const TR_PUSHABLES = 4;
const TR_PHYSICS_OBJECTS = 8;
const TR_ONLY_PLAYER_ALLY_NPCS = 16;
const TR_ONLY_CLIENTS_IN_VEHICLES = 32;
const TR_EVERYTHING = 64;
const TR_ONLY_CLIENTS_NOT_IN_VEHICLES = 512;
const TR_PHYSICS_DEBRIS = 1024;
const TR_ONLY_NPCS_IN_VEHICLES = 2048;
const TR_DISALLOW_BOTS = 4096;
const TR_OFF = 8192;

//NAV editing.
const NAV_EMPTY = 2;
const NAV_BATTLESTATION = 32;
const NAV_FINALE = 64;
const NAV_PLAYER_START = 128;
const NAV_BATTLEFIELD = 256;
const NAV_NOT_CLEARABLE = 1024;
const NAV_CHECKPOINT = 2048;
const NAV_OBSCURED = 4096;
const NAV_NO_MOBS = 8192;
const NAV_RESCUE_VEHICLE = 32768;
const NAV_RESCUE_CLOSET = 65536;
const NAV_NOTHREAT = 524288;
const NAV_LYINGDOWN = 1048576;

//SDK2013: mp/src/game/shared/props_shared.h
const PHYSPROP_START_ASLEEP					= 1
const PHYSPROP_DONT_TAKE_PHYSICS_DAMAGE	= 2		// this prop can't be damaged by physics collisions
const PHYSPROP_DEBRIS							= 4
const PHYSPROP_MOTIONDISABLED					= 8		// motion disabled at startup (flag only valid in spawn - motion can be enabled via input)
const PHYSPROP_TOUCH							= 16	// can be 'crashed through' by running player (plate glass)
const PHYSPROP_PRESSURE						= 32	// can be broken by a player standing on it
const PHYSPROP_ENABLE_ON_PHYSCANNON			= 64	// enable motion only if the player grabs it with the physcannon
const PHYSPROP_NO_ROTORWASH_PUSH			= 128	// The rotorwash doesn't push these
const PHYSPROP_ENABLE_PICKUP_OUTPUT			= 256	// If set, allow the player to +USE this for the purposes of generating an output
const PHYSPROP_PREVENT_PICKUP					= 512	// If set, prevent +USE/Physcannon pickup of this prop
const PHYSPROP_PREVENT_PLAYER_TOUCH_ENABLE	= 1024	// If set, the player will not cause the object to enable its motion when bumped into
const PHYSPROP_HAS_ATTACHED_RAGDOLLS		= 2048	// Need to remove attached ragdolls on enable motion/etc
const PHYSPROP_FORCE_TOUCH_TRIGGERS			= 4096	// Override normal debris behavior and respond to triggers anyway
const PHYSPROP_FORCE_SERVER_SIDE				= 8192	// Force multiplayer physics object to be serverside
const PHYSPROP_RADIUS_PICKUP					= 16384	// For Xbox, makes small objects easier to pick up by allowing them to be found 
const PHYSPROP_ALWAYS_PICK_UP					= 1048576	// Physcannon can always pick this up, no matter what mass or constraints may apply.
const PHYSPROP_NO_COLLISIONS					= 2097152	// Don't enable collisions on spawn
const PHYSPROP_IS_GIB							= 4194304	// Limit # of active gibs

//============================================================
//These defines are taken from "entity_prop_stocks.inc" of SourceMod include-files.
//https://sm.alliedmods.net/new-api/entity_prop_stocks/__raw
//============================================================

const MOVETYPE_NONE = 0;
const MOVETYPE_ISOMETRIC = 1;
const MOVETYPE_WALK = 2;
const MOVETYPE_STEP = 3;
const MOVETYPE_FLY = 4;
const MOVETYPE_FLYGRAVITY = 5;
const MOVETYPE_VPHYSICS = 6;
const MOVETYPE_PUSH = 7;
const MOVETYPE_NOCLIP = 8;
const MOVETYPE_LADDER = 9;
const MOVETYPE_OBSERVER = 10;
const MOVETYPE_CUSTOM = 11;

const IN_ATTACK = 1;
const IN_JUMP = 2;
const IN_DUCK = 4;
const IN_FORWARD = 8;
const IN_BACK = 16;
const IN_USE = 32;
const IN_CANCEL = 64;
const IN_LEFT = 128;
const IN_RIGHT = 256;
const IN_MOVELEFT = 512;
const IN_MOVERIGHT = 1024;
const IN_ATTACK2 = 2048;
const IN_RUN = 4096;
const IN_RELOAD = 8192;
const IN_ALT1 = 16384;
const IN_ALT2 = 32768;	
const IN_SCORE = 65536;
const IN_SPEED = 131072;	
const IN_WALK = 262144;
const IN_ZOOM = 524288;
const IN_WEAPON1 = 1048576;
const IN_WEAPON2 = 2097152;
const IN_BULLRUSH = 4194304;
const IN_GRENADE1 = 8388608;
const IN_GRENADE2 = 16777216;
const IN_ATTACK3 = 33554432;
//custom flags from MR plugin
const IN_IDLE = 67108864;
const IN_TAKEOVER = 134217728;
const IN_FREE_ANGLE = 268435456;

const FL_ONGROUND = 1;
const FL_DUCKING = 2;
const FL_WATERJUMP = 4;
const FL_ONTRAIN = 8;
const FL_INRAIN = 16;
const FL_FROZEN = 32;
const FL_ATCONTROLS = 64;
const FL_CLIENT = 128;
const FL_FAKECLIENT = 256;
const FL_INWATER = 512;
const FL_FLY = 1024;
const FL_SWIM = 2048;
const FL_CONVEYOR = 4096;
const FL_NPC = 8192;
const FL_GODMODE = 16384;
const FL_NOTARGET = 32768;
const FL_AIMTARGET = 65536;
const FL_PARTIALGROUND = 131072;
const FL_STATICPROP = 262144;
const FL_GRAPHED = 524288;
const FL_GRENADE = 1048576;
const FL_STEPMOVEMENT = 2097152;
const FL_DONTTOUCH = 4194304;
const FL_BASEVELOCITY = 8388608;
const FL_WORLDBRUSH = 16777216;
const FL_OBJECT = 33554432;
const FL_KILLME = 67108864;
const FL_ONFIRE = 134217728;
const FL_DISSOLVING = 268435456;
const FL_TRANSRAGDOLL = 536870912;
const FL_UNBLOCKABLE_BY_PLAYER = 1073741824;
const FL_FREEZING = 2147483648;
const FL_EP2V_UNKNOWN1 = 2147483648;

//============================================================
//From "sdkhooks.inc".
//https://sm.alliedmods.net/new-api/sdkhooks/__raw
//============================================================

const DMG_GENERIC = 0;
const DMG_CRUSH = 1;
const DMG_BULLET = 2;
const DMG_SLASH = 4;
const DMG_BURN = 8;
const DMG_VEHICLE = 16;
const DMG_FALL = 32;
const DMG_BLAST = 64;
const DMG_CLUB = 128;
const DMG_SHOCK = 256;
const DMG_SONIC = 512;
const DMG_ENERGYBEAM = 1024;
const DMG_PREVENT_PHYSICS_FORCE = 2048;
const DMG_NEVERGIB = 4096;
const DMG_ALWAYSGIB = 8192;
const DMG_DROWN = 16384;
const DMG_PARALYZE = 32768;
const DMG_NERVEGAS = 65536;
const DMG_POISON = 131072;
const DMG_RADIATION = 262144;
const DMG_DROWNRECOVER = 524288;
const DMG_ACID = 1048576;
const DMG_SLOWBURN = 2097152;
const DMG_MELEE = 2097152;
const DMG_REMOVENORAGDOLL = 4194304;
const DMG_PHYSGUN = 8388608;
const DMG_PLASMA = 16777216;
const DMG_AIRBOAT = 33554432;
const DMG_STUMBLE = 33554432;
const DMG_DISSOLVE = 67108864;
const DMG_BLAST_SURFACE = 134217728;
const DMG_DIRECT = 268435456;
const DMG_BUCKSHOT = 536870912;
const DMG_HEADSHOT = 1073741824;

//============================================================
//					Director Enumerations
//https://developer.valvesoftware.com/wiki/L4D2_Director_Scripts
//NOTE: movement and DMG_* flags were relocated.
//============================================================

const ALLOW_BASH_ALL	= 0;
const ALLOW_BASH_NONE = 2;
const ALLOW_BASH_PUSHONLY = 1;
const BOT_CANT_FEEL = 4;
const BOT_CANT_HEAR = 2;
const BOT_CANT_SEE = 1;
const BOT_CMD_ATTACK = 0;
const BOT_CMD_MOVE = 1;
const BOT_CMD_RESET = 3;
const BOT_CMD_RETREAT = 2;
const BOT_QUERY_NOTARGET = 1;
const FINALE_CUSTOM_CLEAROUT = 11;
const FINALE_CUSTOM_DELAY = 10;
const FINALE_CUSTOM_PANIC = 7;
const FINALE_CUSTOM_SCRIPTED = 9;
const FINALE_CUSTOM_TANK = 8;
const FINALE_FINAL_BOSS = 5;
const FINALE_GAUNTLET_1 = 0;
const FINALE_GAUNTLET_2 = 3;
const FINALE_GAUNTLET_BOSS = 16;
const FINALE_GAUNTLET_BOSS_INCOMING = 15;
const FINALE_GAUNTLET_ESCAPE = 17;
const FINALE_GAUNTLET_HORDE = 13;
const FINALE_GAUNTLET_HORDE_BONUSTIME = 14;
const FINALE_GAUNTLET_START	= 12;
const FINALE_HALFTIME_BOSS = 2;
const FINALE_HORDE_ATTACK_1	= 1;
const FINALE_HORDE_ATTACK_2	= 4;
const FINALE_HORDE_ESCAPE = 6;
const HUD_FAR_LEFT = 7;
const HUD_FAR_RIGHT = 8;
const HUD_LEFT_BOT = 1;
const HUD_LEFT_TOP = 0;
const HUD_MID_BOT	= 3;
const HUD_MID_BOX	= 9;
const HUD_MID_TOP	= 2;
const HUD_RIGHT_BOT = 5;
const HUD_RIGHT_TOP = 4;
const HUD_TICKER = 6;
const HUD_SCORE_1 = 11;
const HUD_SCORE_2 = 12;
const HUD_SCORE_3 = 13;
const HUD_SCORE_4 = 14;
const HUD_SCORE_TITLE = 10;
const HUD_FLAG_ALIGN_CENTER = 512;
const HUD_FLAG_ALIGN_LEFT = 256;
const HUD_FLAG_ALIGN_RIGHT = 768;
const HUD_FLAG_ALLOWNEGTIMER = 128;
const HUD_FLAG_AS_TIME = 16;
const HUD_FLAG_BEEP = 4;
const HUD_FLAG_BLINK = 8;
const HUD_FLAG_COUNTDOWN_WARN = 32;
const HUD_FLAG_NOBG = 64;
const HUD_FLAG_NOTVISIBLE = 16384;
const HUD_FLAG_POSTSTR = 2;
const HUD_FLAG_PRESTR = 1;
const HUD_FLAG_TEAM_INFECTED = 2048;
const HUD_FLAG_TEAM_MASK = 3072;
const HUD_FLAG_TEAM_SURVIVORS = 1024;
const HUD_SPECIAL_COOLDOWN = 4;
const HUD_SPECIAL_MAPNAME = 6;
const HUD_SPECIAL_MODENAME	= 7;
const HUD_SPECIAL_ROUNDTIME	= 5;
const HUD_SPECIAL_TIMER0	= 0;
const HUD_SPECIAL_TIMER1	= 1;
const HUD_SPECIAL_TIMER2	= 2;
const HUD_SPECIAL_TIMER3	= 3;
const INFECTED_FLAG_CANT_FEEL_SURVIVORS = 32768;
const INFECTED_FLAG_CANT_HEAR_SURVIVORS = 16384;
const INFECTED_FLAG_CANT_SEE_SURVIVORS = 8192;
const SCRIPTED_SPAWN_BATTLEFIELD = 2;
const SCRIPTED_SPAWN_FINALE	= 0;
const SCRIPTED_SPAWN_POSITIONAL = 3;
const SCRIPTED_SPAWN_SURVIVORS = 1;
const SCRIPT_SHUTDOWN_EXIT_GAME = 4;
const SCRIPT_SHUTDOWN_LEVEL_TRANSITION = 3;
const SCRIPT_SHUTDOWN_MANUAL = 0;
const SCRIPT_SHUTDOWN_ROUND_RESTART	= 1;
const SCRIPT_SHUTDOWN_TEAM_SWAP = 2;
const SPAWNDIR_E = 4;
const SPAWNDIR_N = 1;
const SPAWNDIR_NE = 2;
const SPAWNDIR_NW = 128;
const SPAWNDIR_S = 16;
const SPAWNDIR_SE = 8;
const SPAWNDIR_SW = 32;
const SPAWNDIR_W = 64;
const SPAWN_ABOVE_SURVIVORS = 6;
const SPAWN_ANYWHERE = 0;
const SPAWN_BATTLEFIELD = 2;
const SPAWN_BEHIND_SURVIVORS = 1;
const SPAWN_FAR_AWAY_FROM_SURVIVORS = 5;
const SPAWN_FINALE = 0;
const SPAWN_IN_FRONT_OF_SURVIVORS = 7;
const SPAWN_LARGE_VOLUME = 9;
const SPAWN_NEAR_IT_VICTIM = 2;
const SPAWN_NEAR_POSITION = 10;
const SPAWN_NO_PREFERENCE = -1;
const SPAWN_POSITIONAL = 3;
const SPAWN_SPECIALS_ANYWHERE	= 4;
const SPAWN_SPECIALS_IN_FRONT_OF_SURVIVORS = 3;
const SPAWN_SURVIVORS = 1;
const SPAWN_VERSUS_FINALE_DISTANCE = 8;
const STAGE_CLEAROUT = 4;
const STAGE_DELAY	= 2;
const STAGE_ESCAPE = 7;
const STAGE_NONE = 9;
const STAGE_PANIC = 0;
const STAGE_RESULTS = 8;
const STAGE_SETUP = 5;
const STAGE_TANK = 1;
const TIMER_COUNTDOWN = 2;
const TIMER_COUNTUP = 1;
const TIMER_DISABLE = 0;
const TIMER_SET = 4;
const TIMER_STOP = 3;
const TRACE_MASK_ALL	= -1;
const TRACE_MASK_NPC_SOLID = 33701899;
const TRACE_MASK_PLAYER_SOLID = 33636363;
const TRACE_MASK_SHOT = 1174421507;
const TRACE_MASK_VISIBLE_AND_NPCS = 33579137;
const TRACE_MASK_VISION = 33579073;
const UPGRADE_EXPLOSIVE_AMMO = 1;
const UPGRADE_INCENDIARY_AMMO = 0;
const UPGRADE_LASER_SIGHT = 2;
const ZOMBIE_NORMAL = 0;
const ZOMBIE_SMOKER = 1;
const ZOMBIE_BOOMER = 2;
const ZOMBIE_HUNTER = 3;
const ZOMBIE_SPITTER = 4;
const ZOMBIE_JOCKEY = 5;
const ZOMBIE_CHARGER = 6;
const ZOMBIE_WITCH = 7;
const ZOMBIE_TANK	= 8;
const ZOMBIE_TERROR = 9;	//not in doc
const ZSPAWN_MOB	= 10;
const ZSPAWN_WITCHBRIDE	= 11;
const ZSPAWN_MUDMEN	= 12;

//============================================================
//============================================================

if (!("g_Utils" in getroottable()))
{
	::g_Utils <-
	{
		botOwner = array(MAXCLIENTS + 1, null)
		OnGameEvent_player_bot_replace = function(event)
		{
			botOwner[GetPlayerFromUserID(event.bot).GetEntityIndex()] = GetPlayerFromUserID(event.player);
		}
	}
}
__CollectEventCallbacks(g_Utils, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);

//========================================================================================================================
//StdLib
//========================================================================================================================

::AngNorm <- function(ang, u_ang = false)
{
	ang%=360;
	if (u_ang)
	{
		if (ang < 0) ang += 360;
		return ang;
	}
	if (ang > 180) ang -= 360;
	else if (ang <= -180) ang += 360;
	return ang;
}

//============================================================
//============================================================

::absf <- function(x)
{
	return x < 0 ? x*-1 : x;
}

//============================================================
//============================================================

::FEqual <- function(a, b, deviation = 0.001)
{
	a -= b;
	if (a < 0) a *= -1;
	return a < deviation;
}

//============================================================
//============================================================

::Clamp <- function(x, min, max)
{
	if (x < min) x = min;
	else if (x > max) x = max;
	return x;
}

//============================================================
//============================================================

::Lerp <- function(a, b, t)
{
	return a + (b - a)*t;
}

::EaseInOut <- function(a, b, t)
{
	return a + (b - a)*(t * t * (3 - 2 * t));
}

::EaseIn <- function(a, b, t)
{
	return a + (b - a)*(t * t);
}

::EaseOut <- function(a, b, t)
{
	return a + (b - a)*(1.0 - (1.0 - t) * (1.0 - t));
}

//========================================================================================================================
//L4D2
//========================================================================================================================

::GetOwner <- function(client)
{
	if (type(client) == "instance") return g_Utils.botOwner[client.GetEntityIndex()];
	if (type(client) == "integer") return g_Utils.botOwner[client];
	if (type(client) == "string") return g_Utils.botOwner[Entities.FindByName(null, client).GetEntityIndex()];
	return null;
}

//============================================================
//============================================================

::GetPicker <- function(hPlayer = null, tr_len = MAX_TRACE_LENGTH, tr_mask = TRACE_MASK_VISIBLE_AND_NPCS)
{
	if (hPlayer == null) hPlayer = PlayerInstanceFromIndex(1);
	local hEntity = null;
	local vecPos = hPlayer.EyePosition();
	local vecAng = hPlayer.EyeAngles();
	local fAng_Pitch = vecAng.x*PI/180;
	local fAng_Yaw = vecAng.y*PI/180;
	local hTrace =
	{
		start = vecPos
		end = vecPos + Vector(cos(fAng_Pitch)*cos(fAng_Yaw)*tr_len, cos(fAng_Pitch)*sin(fAng_Yaw)*tr_len, sin(fAng_Pitch*-1)*tr_len)
		ignore = hPlayer
		mask = tr_mask
	}
	TraceLine(hTrace);
	if (!hTrace.hit || (hEntity = hTrace.enthit).GetEntityIndex() == 0) return null;
	return hEntity;
}

//============================================================
//============================================================

::GetPickerPos <- function(hPlayer = null, tr_len = MAX_TRACE_LENGTH, tr_mask = TRACE_MASK_VISIBLE_AND_NPCS)
{
	if (hPlayer == null) hPlayer = PlayerInstanceFromIndex(1);
	local vecPos = hPlayer.EyePosition();
	local hTrace =
	{
		start = vecPos
		end = vecPos + hPlayer.EyeAngles().Forward()*tr_len
		ignore = hPlayer
		mask = tr_mask
	}
	TraceLine(hTrace);
	return hTrace.pos;
}

//============================================================
//============================================================

::GetPlayer <- function(model = null, checkObs = false)
{
	local hPlayer = null;
	while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
	{
		if ((hPlayer.IsSurvivor() || checkObs) && (NetProps.GetPropInt(hPlayer, "m_survivorCharacter") == model || model == null))
		{
			return hPlayer;
		}
	}
	return null;
}

//============================================================
//============================================================

::GetAnySurv <- function()
{
	local hPlayer, playerList = [], count = 0;
	while (hPlayer = Entities.FindByClassname(hPlayer, "player"))
	{
		if (hPlayer.IsSurvivor() && !hPlayer.IsDead() && !hPlayer.IsDying() && NetProps.GetPropInt(hPlayer, "m_survivorCharacter") < 4)
		{
			count++;
			playerList.append(hPlayer);
		}
	}
	return count ? playerList[RandomInt(0, count - 1)] : hPlayer;
}

//============================================================
//============================================================

::GetVecAng <- function(vec)
{
	local fPitch = asin(vec.z/vec.Length())*180/PI*-1;
	local length = sqrt(pow(vec.x, 2.0) + pow(vec.y, 2.0));
	local fYaw = acos(vec.x/length)*180/PI;
	if (asin(vec.y/length) < 0) fYaw*=-1;
	return QAngle(fPitch, fYaw, 0);
}

//============================================================
//============================================================

::GetDisplayTime <- function(value, sValue = ":")
{
	local min = (value/60).tointeger();
	local sec_10 = ((value%60)/10).tointeger();
	local sec_1 = (value%10).tointeger();
	return min + sValue + sec_10 + sec_1;
}

//============================================================
//============================================================

::GetEpoch <- function()
{
	this = {};
	GetDateFromConsole(this);
	local function IsLeap(value) return (value % 4 == 0 && (value % 100 != 0 || value % 400 == 0));
	local daysList = [31, IsLeap(year) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
	for (local i = 0; i < month - 1; i++) day += daysList[i];
	for (local i = 1970; i < year; i++) day += IsLeap(i) ? 366 : 365;
	return (((day - 1)*24 + hour)*60+min)*60+sec;
}

::GetDateFromConsole <- function(table)
{
	/*
		Since in the VScript base there weren't defined any Squirrel's original date() or time(), thus get unix from the local time.
		Unfortunately, we cannot properly get local time until TLS update, only with certain difficulties. Also, legacy method
		won't work after 2.1.5.5 for some reason (because 'con_logfile' no longer functional?).
	*/
	if ("LocalTime" in getroottable())	//TLS clue
	{
		//wrapper to needed format
		LocalTime(table);
		table.min <- minute;
		table.sec <- second;
	}
	else
	{
		local sFileData = FileToString("st_config/dump/logs_total.txt");
		if (sFileData == null)
		{
			StringToFile("st_config/dump/logs_total.txt", "1");
			sFileData = "1";
		}
		local logs_total = sFileData;
		Convars.SetValue("con_timestamp", 1);
		Convars.SetValue("con_logfile", "ems/st_config/dump/timestamp_" + sFileData + ".txt"); printl("");
		Convars.SetValue("con_logfile", "");
		Convars.SetValue("con_timestamp", 0);
		sFileData = FileToString("st_config/dump/timestamp_" + sFileData + ".txt");
		local length = sFileData.len();
		if (length >= 15720) StringToFile("st_config/dump/logs_total.txt", "" + (logs_total.tointeger() + 1)); //655 total entries until error
		sFileData = split(sFileData.slice(length - 24, length - 3), " - ");
		local date = split(sFileData[0], "/"); local clock = split(sFileData[1], ":");
		table.day <- date[1].tointeger(); table.month <- date[0].tointeger(); table.year <- date[2].tointeger();
		table.hour <- clock[0].tointeger(); table.min <- clock[1].tointeger(); table.sec <- clock[2].tointeger();
	}
}

//============================================================
//============================================================

::GetDate <- function(unix = null)
{
	this = {};
	if (unix != null)
	{
		sec <- unix%60;
		min <- unix/60;
		hour <- min/60;
		day <- hour/24+1;
		month <- 1;
		year <- 1970;
		hour%=24; min%=60;
		local function IsLeap(value) return (value % 4 == 0 && (value % 100 != 0 || value % 400 == 0));
		local daysBuffer = 0;
		for (local buffer = 0; (buffer += IsLeap(year) ? 366 : 365) < day; year++) daysBuffer = buffer;
		local daysList = [null, 31, IsLeap(year) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
		day -= daysBuffer;
		for (local buffer = daysBuffer = 0; (buffer += daysList[month]) < day; month++) daysBuffer = buffer;
		day -= daysBuffer;
	}
	else GetDateFromConsole(this);
	local monthName = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][month - 1];
	local clock = hour%12;
	if (!hour) clock = 12;
	else if (hour == 12) clock = hour;
	clock = clock + "" + (hour < 12 ? "AM" : "PM");
	time <- format("%s:%s", (hour < 10 ? "0"+hour:hour).tostring(), (min < 10 ? "0"+min:min).tostring());
	time_full <- time + ":" + (sec < 10 ? "0"+sec:sec);
	date <- format("%s/%s/%d", (day < 10 ? "0"+day:day).tostring(), (month < 10 ? "0"+month:month).tostring(), year);
	timestamp <- format("%s @ %s", date, time_full);
	timestamp2 <- format("%d %s, %d @%s", day, monthName, year, split(timestamp, "@")[1]);
	timestamp3 <- format("%d %s, %d @ %s - %s", day, monthName, year, clock, strip(split(timestamp, "@")[1]));
	return this;
}

//============================================================
//============================================================

::GetFinaleType <- function()
{
	/*
		0	- Holdout (standart)
		1	- Gauntlet
		2	- Scavenge
		3	- Custom
		-1	- N/A
	*/
	if (SessionState.MapName == "c1m4_atrium") return 2;
	if (SessionState.MapName == "c2m5_concert") return 0;
	if (SessionState.MapName == "c3m4_plantation") return 0;
	if (SessionState.MapName == "c4m5_milltown_escape") return 0;
	if (SessionState.MapName == "c5m5_bridge") return 1;
	if (SessionState.MapName == "c6m3_port") return 1;
	if (SessionState.MapName == "c7m3_port") return 3;
	if (SessionState.MapName == "c8m5_rooftop") return 0;
	if (SessionState.MapName == "c9m2_lots") return 0;
	if (SessionState.MapName == "c10m5_houseboat") return 0;
	if (SessionState.MapName == "c11m5_runway") return 0;
	if (SessionState.MapName == "c12m5_cornfield") return 0;
	if (SessionState.MapName == "c13m4_cutthroatcreek") return 1;
	if (SessionState.MapName == "c14m2_lighthouse") return 2;
	return -1;
}

//============================================================
//============================================================

::IsFakeClient <- function(hPlayer)
{
	if (hPlayer.GetNetworkIDString() == "BOT" && !IsPlayerABot(hPlayer)) return true;
	return false;
}

//============================================================
//============================================================

::IsHuman <- function(hPlayer)
{
	if (hPlayer.GetNetworkIDString() != "BOT") return true;
	return false;
}

//============================================================
//============================================================

::IsFuncExist <- function(funcName)
{
	local bFound = false;
	local hTable = getroottable();
	foreach (idx, name in split(funcName, "."))
	{
		if (bFound) return false;
		if (name in hTable)
		{
			name = hTable.rawget(name);
			if (type(name) == "table") hTable = name;
			else if (type(name).find("function") != null) bFound = true;
		}
	}
	return bFound;
}

//============================================================
//============================================================

::IsPlayer <- function(hPlayer)
{
	if (type(hPlayer) == "instance" && hPlayer.IsValid() && hPlayer.IsPlayer()) return true;
	return false;
}

//============================================================
//============================================================

::IsPlayerVictim <- function(hPlayer)
{
	if (NetProps.GetPropEntity(hPlayer, "m_tongueOwner")) return true;
	if (NetProps.GetPropEntity(hPlayer, "m_pounceAttacker")) return true;
	if (NetProps.GetPropEntity(hPlayer, "m_jockeyAttacker")) return true;
	if (NetProps.GetPropEntity(hPlayer, "m_pummelAttacker")) return true;
	return false;
}

//============================================================
//============================================================

::IsPlayerView <- function(hPlayer, vecPos)
{
	vecPos -= hPlayer.GetOrigin();
	local length = vecPos.Length();
	vecPos = Vector(vecPos.x/length, vecPos.y/length, vecPos.z/length);	//normalize vector
	if (vecPos.Dot(hPlayer.EyeAngles().Forward()) > 0) return true;
	return false;
}

//============================================================
//============================================================

::IsPlayerDirect <- function(hPlayer, vecPos)
{
	if (GetVecAng(vecPos - hPlayer.GetOrigin()).Forward().Dot(GetVecAng(hPlayer.GetVelocity()).Forward()) > 0) return true;
	return false;
}

//============================================================
//============================================================

::IsMapL4D1 <- function()
{
	if (["c1", "c2", "c3", "c4", "c5", "c6", "c13"].find(split(SessionState.MapName, "m")[0]) == null) return true;
	return false;
}

//============================================================
//============================================================

::IsSpawnAllowed <- function()
{
	local hPlayer, clients = 0, bots = 0, reserved = 0;
	while (hPlayer = Entities.FindByClassname(hPlayer, "player"))
	{
		if (IsPlayerABot(hPlayer)) bots++;
		else
		{
			clients++;
			if (!hPlayer.IsSurvivor()) reserved++;
		}
	}
	return MAXCLIENTS > bots - reserved + clients*2 - 1;
}

//============================================================
//============================================================

::Ent <- function(entity)
{
	if (type(entity) == "instance" && entity.IsValid()) return entity;
	if (type(entity) == "integer") return EntIndexToHScript(entity);
	if (type(entity) == "string") return Entities.FindByName(null, entity);
	return null;
}

//============================================================
//============================================================

::EmitSound <- function(vecPos, sSound, iRadius = 3000)
{
	local hTable =
	{
		origin = vecPos
		targetname = "ent_temp_sound_ent"
		message = sSound
		health = 10
		spawnflags = 48
		radius = iRadius
	}
	SpawnEntityFromTable("ambient_generic", hTable);
	EntFire(hTable.targetname, "PlaySound");
	EntFire(hTable.targetname, "Kill");
}

//============================================================
//============================================================

::EmitSoundAll <- function(sName)
{
	local hPlayer = null;
	while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
	{
		EmitSoundOnClient(sName, hPlayer);
	}
}

//============================================================
//============================================================

::EmitSoundEx <- function(hEntity, sndName, sndRadius = null, flags = 0)
{
	const SND_PLAY_EVERYWHERE = 1;
	const SND_START_SILENT = 16;
	const SND_IS_NOT_LOOPED = 32;
	const SND_ONCE = 64;
	if (!hEntity || !hEntity.IsValid())
	{
		local hPlayer;
		while (hPlayer = Entities.FindByClassname(hPlayer, "player"))
		{
			if (IsHuman(hPlayer))
			{
				EmitSoundEx(hPlayer, sndName, 140, SND_ONCE);
			}
		}
		return;
	}
	if (sndRadius == null) sndRadius = 5000;
	if (flags & SND_ONCE) flags = flags | SND_IS_NOT_LOOPED;
	local startName = hEntity.GetName();
	hEntity.__KeyValueFromString("targetname", UniqueString());
	local hTable =
	{
		origin = hEntity.GetOrigin()
		message = sndName
		health = 10
		spawnflags = flags
		radius = sndRadius
		SourceEntityName = hEntity.GetName()
	}
	local hSound = SpawnEntityFromTable("ambient_generic", hTable);
	DoEntFire("!self", "SetParent", "!activator", 0.0, hEntity, hSound);
	hEntity.__KeyValueFromString("targetname", startName);
	if (flags & SND_ONCE)
	{
		EntFire("!activator", "PlaySound", null, 0.0, hSound);
		return EntFire("!activator", "Kill", null, 0.0, hSound);
	}
	return hSound;
}

//============================================================
//============================================================

::TeleportEntity <- function(hEntity, vecPos = Vector(), vecAng = Vector(), vecVel = Vector(), bOriginKV = false)
{
	if (type(hEntity) == "instance" && hEntity.IsValid())
	{
		if (vecPos != null)
		{
			if (bOriginKV) hEntity.__KeyValueFromVector("origin", vecPos);
			else hEntity.SetOrigin(vecPos);
		}
		if (vecAng != null) hEntity.SetForwardVector(QAngle(vecAng.x, vecAng.y, vecAng.z).Forward());
		if (vecVel != null) hEntity.SetVelocity(vecVel);
		return;
	}
	error("[TeleportEntity] Invalid CBaseEntity!\n");
}

//============================================================
//============================================================

::ClearEvent <- function(sEvent = null, hTable = null)
{
	if (sEvent == null) 
	{
		hTable = getstackinfos(2);
		if (hTable.func.find("OnGameEvent_") == null) return error("[ClearEvent] Unable to delete from this scope.\n");
		sEvent = hTable.func.slice(12, hTable.func.len());
		hTable = hTable.locals.rawget("this");
	}
	if (sEvent in GameEventCallbacks)
	{
		local aEvents = GameEventCallbacks.rawget(sEvent);
		if (aEvents.len() > 0)
		{
			if (hTable == null) aEvents.clear();
			else
			{
				local idx = null;
				if ((idx = aEvents.find(hTable)) != null) aEvents.remove(idx);
				else error(format("[ClearEvent] Event '%s' isn't registered within specified scope.\n", sEvent));
			}
		}
		else error("[ClearEvent] No callbacks defined for this event.\n");
	}
	else error("[ClearEvent] Invalid event specified.\n");
}

//============================================================
//============================================================

::OnGameFrame <- function(funcName, fTime = null, fDuration = null)
{
	local sName = split(funcName, "(")[0];
	if (Entities.FindByName(null, LT + sName) == null)
	{
		if (IsFuncExist(sName))
		{
			if (funcName.find("(") == null) funcName += "()";
			if (fTime == null) fTime = 0.01;
			if (fDuration != null) EntFire(LT + sName, "Kill", null, fDuration);
			local hTable =
			{
				targetname = LT + sName
				RefireTime = fTime
				OnTimer = "!caller,RunScriptCode," + funcName
			}
			local hEntity = SpawnEntityFromTable("logic_timer", hTable);
			hEntity.ValidateScriptScope();
			return hEntity;
		}
		error(format("[OnGameFrame] Function callback '%s' does not exist!\n", sName));
	}
	return null;
}

//============================================================
//============================================================

::NavMark <- function(vecPos, flags = NAV_EMPTY)
{
	if (!Ent("ent_nav_settings")) 
	{
		SpawnEntityFromTable("func_nav_attribute_region", {targetname = "ent_nav_settings", origin = vecPos, spawnflags = flags});
		EntFire("ent_nav_settings", "AddOutput", "maxs 16 16 32");
		EntFire("ent_nav_settings", "AddOutput", "mins -16 -16 -16");
		EntFire("ent_nav_settings", "Kill", null, 0.1);
	}
	EntFire("ent_nav_settings", "AddOutput", "origin " + vecPos.ToKVString());
	EntFire("ent_nav_settings", "AddOutput", "spawnflags " + flags);
	EntFire("ent_nav_settings", "ApplyNavAttributes");
}

//============================================================
//============================================================

::RegCvar <- function(cvar, value)
{
	if (Convars.GetFloat(cvar) == null)
	{
		SendToServerConsole("setinfo " + cvar + " " + value);
		return true;
	}
	return false;
}

//========================================================================================================================
//Debug Funcs
//========================================================================================================================

::ptable <- function(hTable)
{
	g_MapScript.DeepPrintTable(hTable);
}

//============================================================
//============================================================

::pvel <- function(hPlayer = 1)
{
	if ((hPlayer = Ent(hPlayer)) == null) return;
	Say(null, format("Velocity %s's: %.03f", hPlayer.IsPlayer() ? hPlayer.GetPlayerName() : hPlayer.GetName(), GetSpeed(hPlayer)), false);
}

//============================================================
//============================================================

::pdist <- function(hPlayer, hPlayer2 = 1)
{
	if ((hPlayer = Ent(hPlayer)) == null) return;
	if ((hPlayer2 = Ent(hPlayer2)) == null) return;
	Say(null, format("%s << %.03f >> %s", GetCharacterDisplayName(hPlayer), GetDistance(hPlayer, hPlayer2), GetCharacterDisplayName(hPlayer2)), false);
}

//============================================================
//============================================================

::ppos <- function(vecPos, sName = "")
{
	if (sName.len()) sName = "_" + sName;
	local hTable =
	{
		targetname = "mark" + sName
		model = "models/extras/info_speech.mdl"
		glowstate = 3
		disableshadows = 1
		origin = vecPos + Vector(0, 0, 25)
		angles = Vector(0, RandomInt(0, 360), 0)
	}
	SpawnEntityFromTable("prop_dynamic", hTable);
	printl(format("[ppos] >> setpos_exact %.03f, %.03f, %.03f", vecPos.x, vecPos.y, vecPos.z));
}

::ppos2 <- function(vecPos)
{
	local hEntity = SpawnEntityFromTable("prop_dynamic", {targetname = "mark_small", model = "models/editor/axis_helper_thick.mdl", rendermode = 6, glowstate = 3, origin = vecPos});
	NetProps.SetPropFloat(hEntity, "m_flModelScale", 0.5);
}

//============================================================
//============================================================

//Only if no ST libraries included.
if (!("CPTime" in getroottable()))
{
	::Timer <- function(isHUD = true)
	{
		if (!isHUD) return EntFire(LT+"g_HUD.Think", "Kill");
		NetProps.SetPropInt(Entities.FindByClassname(null, "terror_gamerules"), "m_bChallengeModeActive", 1);
		if (!("g_HUD" in getroottable())) g_HUD <- {Fields = {}};
		g_HUD.timestamp <- Time();
		g_HUD.Fields._hud <- {slot = HUD_SCORE_TITLE, dataval = "N/A", flags = HUD_FLAG_ALIGN_LEFT};
		g_HUD.Think <- function()
		{
			local time = Time() - timestamp;
			Fields._hud.dataval = (time < 600 ? "0" : "") + GetDisplayTime(time) + "," + split(format("%.03f", time), ".")[1];
			HUDSetLayout(this);
		}
		OnGameFrame("g_HUD.Think");
		HUDPlace(HUD_SCORE_TITLE, 0.47, 0.01, 0.07, 0.02);
	}; ::timer <- Timer;

	//Used in conjunction with Timer() to print timestamps.
	::CPTime <- function(say = "test")
	{
		if (say == null) say = "null";
		if (type(say) != "string") say = say.tostring();
		Say(null, say + (Ent(LT+"g_HUD.Think") ? format(" %.03f", Time() - g_HUD.timestamp) : ""), false);
	}
}

//============================================================
//============================================================

::ptp <- function(hPlayer = 1)
{
	if ((hPlayer = Ent(hPlayer)) == null) return;
	local name = GetCharacterDisplayName(hPlayer);
	if (!name.len()) name = "none";
	local hTable =
	{
		Nick = "GetPlayer(MDL_NI)"
		Rochelle = "GetPlayer(MDL_RO)"
		Coach = "GetPlayer(MDL_CO)"
		Ellis = "GetPlayer(MDL_EL)"
		Bill = "GetPlayer(MDL_BI)"
		Zoey = "GetPlayer(MDL_ZO)"
		Louis = "GetPlayer(MDL_LO)"
		Francis = "GetPlayer(MDL_FR)"
		none = "Ent(1)"
	}
	if (name in hTable)
	{
		local vPos = hPlayer.GetOrigin();
		local vAng = hPlayer.EyeAngles();
		local vVel = hPlayer.GetVelocity();
		name = format("Function:\nTeleportEntity(%s, Vector(%.03f, %.03f, %.03f), Vector(%.03f, %.03f, %.03f)", hTable.rawget(name), vPos.x, vPos.y, vPos.z, vAng.x, vAng.y, vAng.z);
		if (vVel.Length() > 0) name += format(", Vector(%.03f, %.03f, %.03f)", vVel.x, vVel.y, vVel.z);
		Say(null, name + ");", false);
	}
}

//============================================================
//============================================================

::DebugTrace <- function(vStart, vEnd, autoPurge = null)
{
	local sName;
	SpawnEntityFromTable("keyframe_rope", {origin = vStart, RopeMaterial = "cable/cable.vmt", targetname = (sName = UniqueString())});
	SpawnEntityFromTable("keyframe_rope", {origin = vEnd, RopeMaterial = "cable/cable.vmt", targetname = sName, NextKey = sName, Width = 1, Type = 2});
	if (autoPurge != null) EntFire(sName, "Kill", null, autoPurge);
}

//============================================================
//============================================================

::find <- function(name = "", findex = false)
{
	if (name.len())
	{
		local hEntity = null;
		local sName = "";
		local sClass = "";
		local iCount = 0;
		for (local i = 1; i <= MAXENTS; i++)
		{
			hEntity = EntIndexToHScript(i);
			if (hEntity != null && NetProps.GetPropString(hEntity, "m_ModelName") != "models/extras/info_speech.mdl")
			{
				sClass = hEntity.GetClassname();
				sName = hEntity.GetName();
				if ((findex && sClass != name && sName != name) || (sClass.find(name) == null && sName.find(name) == null)) continue;
				SpawnEntityFromTable("prop_dynamic", {targetname = sName, model = "models/extras/info_speech.mdl", glowstate = 3, disableshadows = 1, origin = hEntity.GetOrigin() + Vector(0, 0, 25), angles = Vector(0, RandomInt(0, 360), 0)});
				printl("" + hEntity);
				iCount++;
			}
		}
		return Say(null, "Count: " + iCount, false);
	}
	local hEntity = null;
	while ((hEntity = Entities.FindByModel(hEntity, "models/extras/info_speech.mdl")) != null) hEntity.Kill();
	EmitSoundOn("EDIT_TOGGLE_PLACE_MODE", Ent(1));
}

//============================================================
//============================================================

::AsAny <- function(any = "surv")
{
	local hPlayer = Ent(1);
	local charList =
	{
		surv = (NetProps.GetPropInt(hPlayer, "m_survivorCharacter") + 1)%4
		nick = 0
		rochelle = 1
		coach = 2
		ellis = 3
		bill = 0
		zoey = 1
		louis = 2
		francis = 3
	}
	if (!(hPlayer.IsSurvivor() && any in charList))
	{
		local godmode = Convars.GetFloat("god").tointeger();
		Convars.SetValue("god", 0);
		NetProps.SetPropInt(hPlayer, "m_currentReviveCount", 2);
		hPlayer.TakeDamage(1e4, DMG_GENERIC, hPlayer);
		Convars.SetValue("god", godmode);
		EntFire("survivor_death_model", "Kill", null, 0.01);
	}
	if (any in charList)
	{
		if (!hPlayer.IsSurvivor())
		{
			NetProps.SetPropInt(hPlayer, "m_iTeamNum", 2);
			NetProps.SetPropInt(hPlayer, "m_zombieClass", ZOMBIE_TERROR);
			EntFire("worldspawn", "RunScriptCode", "SendToConsole(\"respawn\")", 0.01);
			EntFire("!activator", "AddOutput", "origin " + split(hPlayer.GetOrigin().ToKVString(), "))")[0], 0.05, hPlayer);
		}
		NetProps.SetPropInt(hPlayer, "m_survivorCharacter", charList[any]);
	}
	else
	{
		if (any == "tank") Convars.SetValue("z_frustration", 0);
		NetProps.SetPropInt(hPlayer, "m_iTeamNum", 3);
		EntFire("!activator", "RunScriptCode", format("SpawnZombie(\"%s\", self.GetOrigin())", any), NetProps.GetPropInt(hPlayer, "m_zombieClass") == ZOMBIE_TANK ? 0.01 : 0.0, hPlayer);
	}
}

//========================================================================================================================
//OBSOLETE (these aliases aren't often used and usually being avoided in further code)
//========================================================================================================================

::PlayerVel <- pvel;
::PlayerDist <- pdist;

::GetDistance <- function(hEntity, hEntity2)
{
	return (hEntity.GetOrigin() - hEntity2.GetOrigin()).Length();
}

::GetSpeed <- function(hPlayer)
{
	return hPlayer.GetVelocity().Length();
}