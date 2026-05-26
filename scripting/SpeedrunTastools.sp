//SourcePawn

/**:
 * @brief Speedrun TAS Tools (L4D2) — 重构版本
 *
 * 本文件为重构后的主入口文件，职责如下：
 * - 插件初始化（命令/CVar/事件/SDKCall注册）
 * - OnPlayerRunCmd 分发（调用模块文件处理）
 * - 事件钩子转发
 * - 通用工具函数（ST_Idle、IsPlayer等）
 *
 * 原有的录制/播放/文件IO/命令处理逻辑已拆分至：
 *   STR/STAPlayer.inc       — 所有玩家状态管理
 *   STR/ReplayRecording.inc — 录制逻辑
 *   STR/ReplayPlayback.inc  — 播放逻辑 + 平滑插值
 *   STR/ReplayFileIO.inc    — 文件保存/加载/分割
 *   STR/ReplayCommands.inc  — 控制台命令 + 菜单 + 轨迹绘制
 *
 * 重构目标：
 * 1. 拆分巨型 OnPlayerRunCmd 函数，提高可读性和可维护性
 * 2. 统一玩家状态至 STAPlayer.inc，消除重复变量定义
 * 3. 修复转录制时的卡顿问题（平滑状态残留）
 * 4. 保持 .STR 文件格式完全兼容
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <string>
#include <keyvalues>
#include <sdkhooks>
#include <multicolors>

//=============================================================================
// STR 基础头文件（不依赖主文件全局变量）
//=============================================================================
#include "STR/Time.inc"
#include "STR/Menus.inc"
#include "STR/Formats.inc"
#include "STR/Vector.inc"
#include "STR/ReplayFrame.inc"

//=============================================================================
// 常量定义
//=============================================================================

#define L4D2_TEAM_NONE      0
#define L4D2_TEAM_SPECTATOR 1
#define L4D2_TEAM_SURVIVOR  2
#define L4D2_TEAM_INFECTED  3

#define MAXCLIENTS 32
#define IN_IDLE     (1 << 26)
#define IN_TAKEOVER (1 << 27)

//=============================================================================
// 武器名称映射表
//=============================================================================
#include "STR/ItemList.inc"

//=============================================================================
// 全局变量（ConVar/SDKCall/Forward 句柄）
//=============================================================================

// ConVar 句柄
Handle b_PlayingToRecord;
Handle b_ReplayDebug;
Handle b_PlayWhenIncapacitated;
Handle g_ConVar_ReplayIdleAnytime;
Handle g_ConVar_PosMap_x;
Handle g_ConVar_PosMap_y;
Handle g_ConVar_PosMap_z;
Handle b_OnlySetVel;

// VScript 触发用 ConVar（自动归零，类似 MR 的 st_mr_play/st_mr_record）
Handle g_ConVar_STR_TriggerPlay;
Handle g_ConVar_STR_TriggerRecord;
Handle g_ConVar_STR_TriggerReset;
Handle g_ConVar_STR_TriggerSave;
Handle g_ConVar_STR_TriggerLoad;
Handle g_ConVar_STR_TriggerPause;
Handle g_ConVar_STR_TriggerUnPause;

// SDKCall 句柄
Handle g_hTakeOverBot;
Handle g_hGoAwayFromKeyboard;

// Forward 句柄
Handle g_hOnPlayTick;
Handle g_hOnRecordTick;

//=============================================================================
// 玩家状态管理（所有 getter/setter）
//=============================================================================
#include "STR/STAPlayer.inc"

//=============================================================================
// 功能模块
//=============================================================================
#include "STR/ReplayRecording.inc"
#include "STR/ReplayPlayback.inc"
#include "STR/ReplayFileIO.inc"
#include "STR/ReplayCommands.inc"

//=============================================================================
// 插件信息
//=============================================================================

public Plugin myinfo =
{
    name = "Speedrun TAS Tools(L4D2)",
    author = "DBGaming Team",
    description = "求生之路2速跑的TAS工具.",
    version = "2.2.06122-refactored",
    url = ""
};

//=============================================================================
// 插件启动
//=============================================================================

public void OnPluginStart()
{
    // 创建数据目录
    char dirbuf[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dirbuf, sizeof(dirbuf), "%s", STR_RootPath);
    if (!DirExists(dirbuf))
        CreateDirectory(dirbuf, 511);
    
    BuildPath(Path_SM, dirbuf, sizeof(dirbuf), "%s/%s", STR_RootPath, STR_ReplayFolder);
    if (!DirExists(dirbuf))
        CreateDirectory(dirbuf, 511);
    
    BuildPath(Path_SM, dirbuf, sizeof(dirbuf), "%s/%s", STR_RootPath, STR_ZoneFolder);
    if (!DirExists(dirbuf))
        CreateDirectory(dirbuf, 511);
    
    // 注册控制台命令
    RegConsoleCmd("sm_str",                   Cmd_STR_Main);
    RegConsoleCmd("sm_loadfile",              Cmd_LoadFile);
    RegConsoleCmd("sm_replay_continue",        Cmd_ReplayContinue);
    RegConsoleCmd("sm_replayrecord",           Cmd_ReplayRecord);
    RegConsoleCmd("sm_replaysave",             Cmd_ReplaySave);
    RegConsoleCmd("sm_resetreplay",            Cmd_ResetReplay);
    RegConsoleCmd("sm_smoothreplay",           Cmd_SmoothReplay);
    RegConsoleCmd("sm_replaydrawtrace",        Cmd_ReplayDrawTrace);
    RegConsoleCmd("sm_replaydrawtrace_posmap", Cmd_ReplayDrawTracePosMap);
    RegConsoleCmd("sm_replaydrawtraceclose",   Cmd_ReplayCloseDrawTrace);
    RegConsoleCmd("sm_startframe",             Cmd_SetFrameParam);
    RegConsoleCmd("sm_endframe",               Cmd_SetFrameParam);
    RegConsoleCmd("sm_stopframe",              Cmd_SetFrameParam);
    RegConsoleCmd("sm_removeslot",             Cmd_RemoveSlot);
    RegConsoleCmd("sm_replay_pause",           Cmd_ReplayPause);
    RegConsoleCmd("sm_replay_unpause",         Cmd_ReplayUnPause);
    RegConsoleCmd("sm_replay_split",           Cmd_ReplaySplit);
    RegConsoleCmd("sm_test",                   Cmd_Test);
    
    // 注册 ConVar
    CreateConVar("sm_showframe", "0", "是否在屏幕中间显示Replay细节.", FCVAR_NONE);
    b_PlayingToRecord    = CreateConVar("sm_replaytorecord", "0", "从Playing转换为Record的开关.", FCVAR_NOTIFY);
    b_ReplayDebug        = CreateConVar("sm_replaydebug", "0", "Replay的Debug开关(Trace是否全局透视).", FCVAR_NOTIFY);
    b_PlayWhenIncapacitated = CreateConVar("sm_replay_incapacitated", "0", "是否在倒地状态播放replay.", FCVAR_NOTIFY);
    g_ConVar_ReplayIdleAnytime = CreateConVar("sm_replay_idle_anytime", "0", "Allow idle even if no human players in game(via PCI).", FCVAR_NONE);
    g_ConVar_PosMap_x    = CreateConVar("str_posmap_x", "0.0", "坐标映射x分量.", FCVAR_NOTIFY);
    g_ConVar_PosMap_y    = CreateConVar("str_posmap_y", "0.0", "坐标映射y分量.", FCVAR_NOTIFY);
    g_ConVar_PosMap_z    = CreateConVar("str_posmap_z", "0.0", "坐标映射z分量.", FCVAR_NOTIFY);
    b_OnlySetVel         = CreateConVar("str_onlysetvel", "0", "仅设置速度,不设置坐标和视角.", FCVAR_NOTIFY);

    // VScript 触发用 ConVar（自动归零）
    g_ConVar_STR_TriggerPlay   = CreateConVar("str_trigger_play", "0",
        "VScript trigger: start playback for client. Auto-resets to 0.");
    g_ConVar_STR_TriggerRecord = CreateConVar("str_trigger_record", "0",
        "VScript trigger: start recording for client. Auto-resets to 0.");
    g_ConVar_STR_TriggerReset  = CreateConVar("str_trigger_reset", "0",
        "VScript trigger: reset/stop replay for client. Auto-resets to 0.");
    g_ConVar_STR_TriggerSave   = CreateConVar("str_trigger_save", "0",
        "VScript trigger: save replay for client. Auto-resets to 0.");
    g_ConVar_STR_TriggerLoad   = CreateConVar("str_trigger_load", "0",
        "VScript trigger: load replay file. Format 'client;filename'. Auto-resets to 0.");
    g_ConVar_STR_TriggerPause  = CreateConVar("str_trigger_pause", "0",
        "VScript trigger: pause replay for client. Auto-resets to 0.");
    g_ConVar_STR_TriggerUnPause = CreateConVar("str_trigger_unpause", "0",
        "VScript trigger: unpause replay for client. Auto-resets to 0.");

    HookConVarChange(g_ConVar_STR_TriggerPlay,   ConVarChanged_STR_Trigger);
    HookConVarChange(g_ConVar_STR_TriggerRecord, ConVarChanged_STR_Trigger);
    HookConVarChange(g_ConVar_STR_TriggerReset,  ConVarChanged_STR_Trigger);
    HookConVarChange(g_ConVar_STR_TriggerSave,   ConVarChanged_STR_Trigger);
    HookConVarChange(g_ConVar_STR_TriggerLoad,   ConVarChanged_STR_Trigger);
    HookConVarChange(g_ConVar_STR_TriggerPause,  ConVarChanged_STR_Trigger);
    HookConVarChange(g_ConVar_STR_TriggerUnPause,ConVarChanged_STR_Trigger);

    // 全局 Forward
    g_hOnPlayTick   = CreateGlobalForward("OnPlayTick", ET_Ignore, Param_Cell, Param_Cell);
    g_hOnRecordTick = CreateGlobalForward("OnRecordTick", ET_Ignore, Param_Cell, Param_Cell);
    
    // 事件钩子
    HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);
    HookEvent("map_transition", OnGameEvent);
    HookEvent("player_bot_replace", Event_PlayerBotReplace);
    HookEvent("bot_player_replace", Event_PlayerBotReplace);
    HookEvent("player_use", Event_PlayerUse);
    HookEvent("round_start", Event_RoundStart);

    // SDKCall 初始化：TakeOverBot / GoAwayFromKeyboard
    char sFilePath[64];
    BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/st_signs.txt");
    if (FileExists(sFilePath))
    {
        Handle hConfig = LoadGameConfigFile("st_signs");
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "TakeOverBot");
        g_hTakeOverBot = EndPrepSDKCall();
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "GoAwayFromKeyboard");
        g_hGoAwayFromKeyboard = EndPrepSDKCall();
        CloseHandle(hConfig);
    }
    
    // 加载 funcommands.games
    Handle gameconfig = LoadGameConfigFile("funcommands.games");
    if (!gameconfig)
    {
        SetFailState("funcommands.games.txt not found.");
        return;
    }
}

//=============================================================================
// VScript 触发 ConVar 统一处理（自动归零）
// VScript 调用 Convars.SetValue 会同步触发本函数（当前帧执行）。
//=============================================================================

public void ConVarChanged_STR_Trigger(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_ConVar_STR_TriggerLoad)
    {
        // 格式: "client;filename"
        char sParts[2][PLATFORM_MAX_PATH];
        if (ExplodeString(newValue, ";", sParts, 2, PLATFORM_MAX_PATH) == 2)
        {
            int client = StringToInt(sParts[0]);
            if (client > 0 && client <= MAXCLIENTS && IsClientInGame(client))
            {
                char mapbuf[64];
                GetCurrentMap(mapbuf, sizeof(mapbuf));
                char filepath[PLATFORM_MAX_PATH];
                BuildReplayFilePath(mapbuf, sParts[1], filepath, sizeof(filepath));
                if (LoadReplayFromFile(client, filepath))
                {
                    Player_SetHasRun(client, true);
                    STR_PrintMessageToAllClients("%N 已加载Replay(Trigger).", client);
                }
            }
        }
        SetConVarString(convar, "0");
        return;
    }

    int client = StringToInt(newValue);
    if (client < 1 || client > MAXCLIENTS || !IsClientInGame(client))
    {
        SetConVarString(convar, "0");
        return;
    }

    if (convar == g_ConVar_STR_TriggerRecord)
    {
        Player_SetIsSegmenting(client, true);
        Player_SetIsRewinding(client, false);
        Player_SetHasRun(client, false);
        Player_SetPlayingReplay(client, false);
        Player_CreateFrameArray(client);
        Player_SetRewindFrame(client, 0);
        STR_PrintMessageToAllClients("开始记录%N的Replay(Trigger)...", client);
    }
    else if (convar == g_ConVar_STR_TriggerPlay)
    {
        if (Player_GetIsFileLoaded(client))
        {
            Player_SetHasRun(client, true);
            Player_SetPlayingReplay(client, true);
            Player_SetRewindFrame(client, Player_GetStartFrame(client));
            Player_SetIsRewinding(client, true);

            int lineSmooth = Player_GetEndFrame(client) - Player_GetStartFrame(client);
            if (lineSmooth < 1) lineSmooth = 1;
            Player_SetSmoothLineDecrement(client, lineSmooth);
            g_bReplaySyncArmed[client] = true;
            if (g_iReplaySyncStartTick == -1)
                g_iReplaySyncStartTick = GetGameTickCount() + 3;

            STR_PrintMessageToAllClients("%N 开始播放Replay(Trigger).", client);
        }
    }
    else if (convar == g_ConVar_STR_TriggerReset)
    {
        ResetPlayerReplaySegment(client);
        STR_PrintMessageToAllClients("%N 的Replay已重置(Trigger).", client);
    }
    else if (convar == g_ConVar_STR_TriggerSave)
    {
        Player_SetIsRewinding(client, false);
        if (Player_GetIsSegmenting(client) || GetClientTeam(client) == 3)
        {
            char mapbuf[64];
            GetCurrentMap(mapbuf, sizeof(mapbuf));

            char newdirbuf[PLATFORM_MAX_PATH];
            BuildReplayDirPath(mapbuf, newdirbuf, sizeof(newdirbuf));
            if (!DirExists(newdirbuf)) CreateDirectory(newdirbuf, 511);

            char timebuf[128];
            FormatTime(timebuf, sizeof(timebuf), "%Y %m %d, %H %M %S");

            char namebuf[256];
            FormatEx(namebuf, sizeof(namebuf), "%s (%s)", mapbuf, timebuf);

            char filename[PLATFORM_MAX_PATH];
            FormatEx(filename, sizeof(filename), "%s/%s.STR", newdirbuf, namebuf);

            if (SaveReplayToFile(client, filename))
            {
                STR_PrintMessageToAllClients("已保存%N的Replay(Trigger).", client);
            }
        }
    }
    else if (convar == g_ConVar_STR_TriggerPause)
    {
        Player_SetIsPauseWhilePlaying(client, true);
        Player_SetIsRewinding(client, true);
        RequestFrame(SetPlayerMoveTypeNone, client);
        STR_PrintMessageToAllClients("%N 的Replay已暂停(Trigger).", client);
    }
    else if (convar == g_ConVar_STR_TriggerUnPause)
    {
        Player_SetIsPauseWhilePlaying(client, false);
        Player_SetIsRewinding(client, false);
        STR_PrintMessageToAllClients("%N 的Replay已取消暂停(Trigger).", client);
    }

    SetConVarString(convar, "0");
}

//=============================================================================
// 地图开始
//=============================================================================

public void OnMapStart()
{
    for (int i = 1; i <= MAXCLIENTS; i++)
    {
        Player_ResetAllReplayState(i);
        
        /**
         * @bug 修复：地图过渡期间播放 Replay 可能导致 +attack 按键卡死。
         * 原因分析：
         * - OnMapEnd → ForceStopAllReplays → ResetPlayerReplaySegment 通过
         *   RequestFrame(ResetButton) 排队释放按键，但跨地图的 RequestFrame
         *   回调可能丢失（SourceMod 不保证跨地图的帧回调存活）。
         * - 新地图的 OnMapStart 只重置了状态（Player_ResetAllReplayState）
         *   但没有发送 -attack 等 ClientCommand，导致 +attack 卡死。
         * 修复：在 OnMapStart 中为每个槽位重新排队 ResetButton。
         */
        RequestFrame(ResetButton, i);
    }
}

//=============================================================================
// OnPlayerRunCmd — 主分发函数
//=============================================================================

/**
 * @brief 每 tick 调用一次，处理录制/播放/倒带等逻辑。
 * 根据玩家状态分发到不同模块处理。
 */
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float wishvel[3], float wishangles[3], int& weapon)
{
    Action result = Plugin_Continue;

    // 1) 录制状态
    if (Player_GetIsSegmenting(client))
    {
        if (Player_GetIsRewinding(client))
        {
            // 录制中倒带
            result = HandleReplayRecordingRewind(client, buttons, wishvel, wishangles, weapon);
        }
        else
        {
            // 正常录制
            result = HandleReplayRecording(client, buttons, impulse, wishvel, wishangles, weapon, g_hOnRecordTick);
        }
    }
    // 2) 播放状态
    else if (Player_GetIsPlayingReplay(client))
    {
        bool bPlayWhenInc = GetConVarBool(b_PlayWhenIncapacitated);
        bool bPlayToRec   = GetConVarBool(b_PlayingToRecord);
        bool bOnlySetVel  = GetConVarBool(b_OnlySetVel);
        float fTimeScale  = GetConVarFloat(FindConVar("host_timescale"));

        result = HandleReplayPlayback(client, buttons, wishvel, wishangles, weapon,
            g_hOnPlayTick, bPlayWhenInc, bPlayToRec, bOnlySetVel, fTimeScale);
    }

    // 3) Debug 显示（所有客户端）
    STR_UpdateDebugDisplay(client);

    return result;
}

//=============================================================================
// OnPlayerRunCmdPost — 每 tick 后处理
//=============================================================================

/**
 * @brief OnPlayerRunCmd 之后调用，用于显示 HUD 信息。
 */
public void OnPlayerRunCmdPost(int client)
{
    // 中心文字显示已移至 HandleReplayRewind 和 HandleReplayPlayback 内部
    // 此处不再处理，避免时序问题（OnPlayerRunCmd 中可能重置播放状态）
}

//=============================================================================
// 事件钩子
//=============================================================================

/**
 * @brief 玩家断开连接时清理 Replay 状态。
 */
public Action OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);
    if (client < 1) return Plugin_Continue;
    
    ResetPlayerReplaySegment(client);
    return Plugin_Continue;
}

/**
 * @brief 过关事件：自动保存所有正在录制的 Replay。
 */
public void OnGameEvent(Event event, const char[] name, bool dontBroadcast)
{
    if (StrEqual(name, "map_transition"))
    {
        char cmdbuf[128];
        for (int i = 1; i <= MAXCLIENTS; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i) && Player_GetIsSegmenting(i))
            {
                Format(cmdbuf, sizeof(cmdbuf), "sm_replaysave %d", i);
                ClientCommand(i, cmdbuf);
            }
        }
    }
}

/**
 * @brief Bot/玩家替换事件：记录闲置/接管标记。
 */
public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "player"));
    if (client > 0)
    {
        Player_AddIdleFlags(client, StrEqual(name, "player_bot_replace") ? IN_IDLE : IN_TAKEOVER);
    }
}

/**
 * @brief 玩家使用事件：Replay 播放中时处理旋转门。
 */
public void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (Player_GetIsPlayingReplay(client))
    {
        int entity = GetEventInt(event, "targetid");
        char sName[64];
        GetEntityClassname(entity, sName, sizeof(sName));
        if (StrContains(sName, "prop_door_rotating") != -1)
        {
            if (!GetEntProp(entity, Prop_Send, "m_eDoorState"))
                AcceptEntityInput(entity, "PlayerOpen", client);
            else
                AcceptEntityInput(entity, "PlayerClose", client);
        }
    }
}

/**
 * @brief 回合开始事件：重新初始化 Debug HUD。
 * !restart 后 VScript 重置、m_bChallengeModeActive 归零，
 * 需要在此重建 HUD 表和启用 ScriptedMode 显示。
 */
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bDebugEnabled[i])
        {
            STR_InitDebugHUD();
            break;
        }
    }
}

/**
 * @brief 地图结束时强制停止所有 Replay。
 */
public void OnMapEnd()
{
    ForceStopAllReplays();
}

/**
 * @brief 客户端断开时清理。
 */
public void OnClientDisconnect(int client)
{
    ResetPlayerReplaySegment(client);
}

//=============================================================================
// 通用工具函数
//=============================================================================

/**
 * @brief 闲置/接管 Bot 操作。
 * 源自 ST 工具集的 ST_Idle 函数。
 *
 * @param client  客户端索引。
 * @param bType   true = TakeOver（接管Bot）, false = Idle（闲置）。
 * @return        true 表示操作成功。
 */
stock bool ST_Idle(int client, bool bType = false)
{
    if (IsClientInGame(client) && !IsPlayerABot(client))
    {
        if (bType)
        {
            if (GetClientTeam(client) == 1)
            {
                SDKCall(g_hTakeOverBot, client);
                return true;
            }
        }
        else
        {
            if (GetClientTeam(client) == 2 && IsPlayerAlive(client))
            {
                if (GetConVarBool(g_ConVar_ReplayIdleAnytime))
                {
                    SDKCall(g_hGoAwayFromKeyboard, client);
                    PrintToChatAll("[ST_Idle] %N is now idle.", client);
                    return true;
                }
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsPlayerABot(i) && IsPlayerAlive(i) && client != i && GetClientTeam(i) == 2)
                    {
                        SDKCall(g_hGoAwayFromKeyboard, client);
                        PrintToChatAll("%N is now idle.", client);
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

/**
 * @brief 检查客户端是否为有效玩家。
 */
stock bool IsPlayer(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

/**
 * @brief 检查客户端是否为 Bot。
 */
stock bool IsPlayerABot(int client)
{
    return (GetEntityFlags(client) & FL_FAKECLIENT) ? true : false;
}

/**
 * @brief 获取血量缓冲值（虚血）。
 */
stock float GetHealthBuffer(int client)
{
    float fHealthTemp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer")
        - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime"))
        * GetConVarFloat(FindConVar("pain_pills_decay_rate")));
    return fHealthTemp > 0.0 ? fHealthTemp : 0.0;
}
