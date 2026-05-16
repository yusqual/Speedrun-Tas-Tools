#if defined STAPLAYER_INCLUDED
#endinput
#endif
#define STAPLAYER_INCLUDED


#include "Formats.inc"
#include "Vector.inc"
#include "ReplayFrame.inc"


//==============================================================


//获取和设置玩家Replay的暂停状态================================
bool PauseWhilePlaying[MAXPLAYERS + 1];

public bool Player_GetIsPauseWhilePlaying(int client)
{
    return PauseWhilePlaying[client];
}

public void Player_SetIsPauseWhilePlaying(int client, bool value)
{
    PauseWhilePlaying[client] = value;
}
//==============================================================





//获取和设置玩家线性平滑的起始帧================================
int Frame_Start[MAXPLAYERS + 1];

public void Player_SetStartFrame(int client, int value)
{
    Frame_Start[client] = value;
}

public int Player_GetStartFrame(int client)
{
    return Frame_Start[client];
}
//==============================================================




//获取和设置玩家线性平滑的结束帧================================
int Frame_End[MAXPLAYERS + 1];

public void Player_SetEndFrame(int client, int value)
{
    Frame_End[client] = value;
}

public int Player_GetEndFrame(int client)
{
    return Frame_End[client];
}
//==============================================================





//获取和设置玩家线性平滑的Replay停止帧================================
int Frame_Stop[MAXPLAYERS + 1];

public void Player_SetPauseFrame(int client, int value)
{
    Frame_Stop[client] = value;
}

public int Player_GetPauseFrame(int client)
{
    return Frame_Stop[client];
}
/*
    ==============================================================
*/

//获取和设置玩家线性平滑的Replay暂停帧================================
int Pause_Stop[MAXPLAYERS + 1];

public void Player_SetStopFrame(int client, int value)
{
    Pause_Stop[client] = value;
}

public int Player_GetStopFrame(int client)
{
    return Pause_Stop[client];
}
/*
    ==============================================================
*/



/*
    ==============================================================
*/

bool IsSegmenting[MAXPLAYERS + 1];

public bool Player_GetIsSegmenting(int client)
{
    return IsSegmenting[client];
}

public void Player_SetIsSegmenting(int client, bool value)
{
    IsSegmenting[client] = value;
}

public void Player_SetIsSegmentingAll(bool value)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
        {
            IsSegmenting[i] = value;
        }
    }
}



/*
    ==============================================================
*/





int LastPausedTick[MAXPLAYERS + 1];

public int Player_GetLastPausedTick(int client)
{
    return LastPausedTick[client];
}

public void Player_SetLastPausedTick(int client, int value)
{
    LastPausedTick[client] = value;
}


public void Player_SetLastPausedTickAll(bool value)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
        {
            LastPausedTick[i] = value;
        }
    }
}
/*
    ==============================================================
*/

bool IsRewinding[MAXPLAYERS + 1];

public bool Player_GetIsRewinding(int client)
{
    return IsRewinding[client];
}

public void Player_SetIsRewinding(int client, bool value)
{
    IsRewinding[client] = value;
}


public void Player_SetIsRewindingAll(bool value)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
        {
            IsRewinding[i] = value;
        }
    }
}

/*
    ==============================================================
*/

bool HasRun[MAXPLAYERS + 1];

public bool Player_GetHasRun(int client)
{
    return HasRun[client];
}

public void Player_SetHasRun(int client, bool value)
{
    HasRun[client] = value;
}


public void Player_SetHasRunAll(bool value)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
        {
            HasRun[i] = value;
        }
    }
}
/*
    ==============================================================
*/

bool IsPlayingReplay[MAXPLAYERS + 1];

public bool Player_GetIsPlayingReplay(int client)
{
    return IsPlayingReplay[client];
}

public void Player_SetPlayingReplay(int client, bool value)
{
    IsPlayingReplay[client] = value;
}


public void Player_SetPlayingReplayAll(bool value)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
        {
            IsPlayingReplay[i] = value;
        }
    }
}
/*
    ==============================================================
*/

int RewindSpeed[MAXPLAYERS + 1] = {1, ...};

public void Player_SetRewindSpeed(int client, int value)
{
    RewindSpeed[client] = value;
}

public int Player_GetRewindSpeed(int client)
{
    return RewindSpeed[client];
}
/*
    ==============================================================
*/

ArrayList RecordFramesList[MAXPLAYERS + 1];

public void Player_CreateFrameArray(int client)
{
    RecordFramesList[client] = CreateArray(FRAME_Length);
}


public Handle Player_GetRecordFramesList(int client)
{
    return RecordFramesList[client];
}



public void Player_PushFrame(int client, any[] frameinfo)
{
    PushArrayArray(RecordFramesList[client], frameinfo);
}

public void Player_GetFrame(int client, int index, any[] frameinfo)
{
    GetArrayArray(RecordFramesList[client], index, frameinfo);
}

public int Player_GetRecordedFramesCount(int client)
{
    if (RecordFramesList[client] == INVALID_HANDLE)
        return 0;
    return GetArraySize(RecordFramesList[client]);
}

public void Player_ResizeRecordFrameList(int client, int newsize)
{
    ResizeArray(RecordFramesList[client], newsize);
}

public void Player_DeleteRecordFrames(int client)
{	
    if (RecordFramesList[client] != null)
    {
        ClearArray(RecordFramesList[client]);
        delete RecordFramesList[client];
    }
}

/*
    ==============================================================
*/

int CurrentRewindFrame[MAXPLAYERS + 1];
int PreRewindFrame[MAXPLAYERS + 1];

public int Player_GetRewindFrame(int client)
{
    return CurrentRewindFrame[client];
}

public void Player_SetRewindFrame(int client, int value)
{
    CurrentRewindFrame[client] = value;
}

public void Player_IncrementRewindFrame(int client)
{
    ++CurrentRewindFrame[client];
}

public void Player_DecrementRewindFrame(int client)
{
    --CurrentRewindFrame[client];
}

public int Player_PreRewindFrame(int client, int pre)
{
    PreRewindFrame[client] = CurrentRewindFrame[client] + pre;
    return PreRewindFrame[client];
}

/*
    ==============================================================
*/

int PlayerLinkedBotIndex[MAXPLAYERS + 1];

public int Player_GetLinkedBotIndex(int client)
{
    return PlayerLinkedBotIndex[client];
}


/*
    ==============================================================
*/

int BotLinkedPlayerIndex[MAXPLAYERS + 1];

public int Bot_GetLinkedPlayerIndex(int client)
{
    return BotLinkedPlayerIndex[client];
}

public void Bot_SetLinkedPlayerIndex(int client, int value)
{
    BotLinkedPlayerIndex[client] = value;
}

/*
    ==============================================================
*/

/*
    Threshold value to which zone editing snaps to
*/
int ZoneGridSize[MAXPLAYERS + 1] = {8, ...};

public int Player_GetZoneGridSize(int client)
{
    return ZoneGridSize[client];
}

public void Player_SetZoneGridSize(int client, int value)
{
    ZoneGridSize[client] = value;
}

/*
    ==============================================================
*/

bool IsCreatingCheckpoint[MAXPLAYERS + 1];

public bool Player_GetIsCreatingCheckpoint(int client)
{
    return IsCreatingCheckpoint[client];
}

public void Player_SetIsCreatingCheckpoint(int client, bool value)
{
    IsCreatingCheckpoint[client] = value;
}

/*
    ==============================================================
*/

/*
    See CP_BuildState in Checkpoints.inc for possible values
    
    CreatingCheckpoint gets set to false after the height stage is complete
*/
int ZoneEditingStage[MAXPLAYERS + 1];

public int Player_GetZoneEditingStage(int client)
{
    return ZoneEditingStage[client];
}

public void Player_SetZoneEditingStage(int client, int value)
{
    ZoneEditingStage[client] = value;
}

/*
    ==============================================================
*/

float ZoneEditStartPos[MAXPLAYERS + 1][3];

public void Player_GetZoneEditStartPos(int client, float pos[3])
{
    pos = ZoneEditStartPos[client];
}

public void Player_SetZoneEditStartPos(int client, float value[3])
{
    ZoneEditStartPos[client] = value;
}

/*
    ==============================================================
*/

float ZoneEditEndPos[MAXPLAYERS + 1][3];

public void Player_GetZoneEditEndPos(int client, float pos[3])
{
    pos = ZoneEditEndPos[client];
}

public void Player_SetZoneEditEndPos(int client, float value[3])
{
    ZoneEditEndPos[client] = value;
}

/*
    ==============================================================
*/

public void Player_GetZoneEditBoxMinMax(int client, float min[3], float max[3])
{
    float startpos[3];
    float endpos[3];
    Player_GetZoneEditStartPos(client, startpos);
    Player_GetZoneEditEndPos(client, endpos);
    
    MinVector(startpos, endpos, min);
    MaxVector(startpos, endpos, max);
}

/*
    ==============================================================
*/

/*
    What type of zone is being created if IsCreatingCheckpoint is true
*/
int ZoneEditCreationType[MAXPLAYERS + 1];

public int Player_GetZoneEditCreationType(int client)
{
    return ZoneEditCreationType[client];
}

public void Player_SetZoneEditCreationType(int client, int value)
{
    ZoneEditCreationType[client] = value;
}

/*
    ==============================================================
*/

bool IsTimingRun[MAXPLAYERS + 1];

public bool Player_GetIsTimingRun(int client)
{
    return IsTimingRun[client];
}

public void Player_SetIsTimingRun(int client, bool value)
{
    IsTimingRun[client] = value;
}

/*
    ==============================================================
*/

int StartTimeReplayTick[MAXPLAYERS + 1];

public int Player_GetStartTimeReplayTick(int client)
{
    return StartTimeReplayTick[client];
}

public void Player_SetStartTimeReplayTick(int client, int value)
{
    StartTimeReplayTick[client] = value;
}

/*
    ==============================================================
*/

bool HasFastForwardKeyDown[MAXPLAYERS + 1];

public bool Player_GetHasFastForwardKeyDown(int client)
{
    return HasFastForwardKeyDown[client];
}

public void Player_SetHasFastForwardKeyDown(int client, bool value)
{
    HasFastForwardKeyDown[client] = value;
}

/*
    ==============================================================
*/

bool HasRewindKeyDown[MAXPLAYERS + 1];

public bool Player_GetHasRewindKeyDown(int client)
{
    return HasRewindKeyDown[client];
}

public void Player_SetHasRewindKeyDown(int client, bool value)
{
    HasRewindKeyDown[client] = value;
}

/*
    ==============================================================
*/

public int Player_ClampRecordFrame(int client, int frame)
{
    int count = Player_GetRecordedFramesCount(client);
    
    if (frame < 0)
    {
        frame = 0;
    }
    
    else if (frame >= count)
    {
        frame = count - 1;
    }
    
    return frame;
}

public void Player_PrintInfo(int client)
{
    PrintToChat(client, "============= Player_PrintInfo");
    PrintToChat(client, "IsSegmenting = %d", IsSegmenting[client]);
    PrintToChat(client, "IsRewinding = %d", IsRewinding[client]);
    PrintToChat(client, "HasRun = %d", HasRun[client]);
    PrintToChat(client, "PlayingReplay = %d", IsPlayingReplay[client]);
    PrintToChat(client, "CurrentRewindFrame = %d", CurrentRewindFrame[client]);
    PrintToChat(client, "PlayerLinkedBotIndex = %d", PlayerLinkedBotIndex[client]);
}

public void Player_PrintEditInfo(int client)
{
    PrintToChat(client, "============= Player_PrintEditInfo");
    PrintToChat(client, "CreatingCheckpoint = %d", IsCreatingCheckpoint[client]);
    PrintToChat(client, "ZoneGridSize = %d", ZoneGridSize[client]);
    PrintToChat(client, "ZoneEditingStage = %d", ZoneEditingStage[client]);
}

/*
    ==============================================================
*/

public const int SPECMODE_NONE = 0;
public const int SPECMODE_FIRSTPERSON = 4;
public const int SPECMODE_THIRDPERSON = 5;
public const int SPECMODE_FREELOOK = 6;


/*
public bool Player_IsSpectating(int client)
{
    //return IsClientInGame(client) && GetClientTeam(client) == L4D2_TEAM_SPECTATOR;
}

public int Player_GetSpectateTarget(int client)
{
    if (!Player_IsSpectating(client))
    {
        return -1;
    }
    
    return GetEntDataEnt2(client, Offset_ObserverTarget);
}

public int Player_GetSpectateMode(int client)
{
    if (!Player_IsSpectating(client))
    {
        return -1;
    }
    
    return GetEntData(client, Offset_ObserverMode);
}



public int Player_GetSpectateList(int client, int[] outlist)
{
    int ret = 0;
    
    for (int i = 1; i < MaxClients + 1; ++i)
    {
        if (Player_IsSpectating(i))
        {
            int mode = Player_GetSpectateMode(i);
            
            
                //There is an intermediate state between thirdperson and freemode
                //but no need to support that I guess
            
            if (mode == SPECMODE_THIRDPERSON || mode == SPECMODE_FIRSTPERSON)
            {
                int target = Player_GetSpectateTarget(i);
                
                if (target == client)
                {
                    outlist[ret] = i;
                    ++ret;
                }
            }
        }
    }
    
    return ret;
}

*/


/*
    Adds the prefix and then adds the desired format
*/
public void STR_PrintMessageToAllClients(const char[] format, any ...)
{
    char message[255];
    message[0] = 0;
    
    char outmessage[255];
    
    if (IsSource2009())
    {
        StrCat(message, sizeof(message), STR_MessagePrefix);
    }
    
    else
    {
        StrCat(message, sizeof(message), STR_CSGOMessagePrefix);
    }

    StrCat(message, sizeof(message), format);	
    VFormat(outmessage, sizeof(outmessage), message, 2);
    
    CPrintToChatAll(outmessage);
}

/*
    Adds the prefix and then adds the desired format
*/
public void STR_PrintMessageToClient(int client, const char[] format, any ...)
{
    char message[255];
    message[0] = 0;
    
    char outmessage[255];
    
    if (IsSource2009())
    {
        StrCat(message, sizeof(message), STR_MessagePrefix);
    }

    else
    {
        StrCat(message, sizeof(message), STR_CSGOMessagePrefix);
    }

    StrCat(message, sizeof(message), format);	
    VFormat(outmessage, sizeof(outmessage), message, 3);
    
    CPrintToChat(client, outmessage);
}

/*
    Adds the prefix and then adds the desired format
*/

/*
public void STR_PrintMessageToClientSpectators(int client, const char[] format, any ...)
{
    char message[255];
    message[0] = 0;
    
    char outmessage[255];
    
    char clientname[MAX_NAME_LENGTH];
    GetClientName(client, clientname, sizeof(clientname));
    
    if (IsSource2009())
    {
        StrCat(message, sizeof(message), STR_MessagePrefix);
        StrCat(message, sizeof(message), " {lightblue}* ");
    }

    else
    {
        StrCat(message, sizeof(message), STR_CSGOMessagePrefix);
        StrCat(message, sizeof(message), " {bluegrey}* ");
    }
    
    StrCat(message, sizeof(message), clientname);

    if (IsSource2009())
    {
        StrCat(message, sizeof(message), " * {ghostwhite}- ");
    }

    else
    {
        StrCat(message, sizeof(message), " * {default}- ");
    }

    StrCat(message, sizeof(message), format);
    VFormat(outmessage, sizeof(outmessage), message, 3);
    
    int specs[MAXPLAYERS + 1];
    int count = Player_GetSpectateList(client, specs);
    
    for (int i = 0; i < count; ++i)
    {
        CPrintToChat(specs[i], message);
    }
}
*/


//=============================================================================
// 以下状态变量从主文件迁移至此处，统一管理
//=============================================================================

/**
 * @brief 自由视角平滑过渡递减计数器。
 * 播放Replay时用于视角平滑插值的tick递减。
 */
int g_iAngleSmooth[MAXPLAYERS + 1];

/**
 * @brief 获取玩家视角平滑计数器。
 */
public int Player_GetAngleSmooth(int client)
{
    return g_iAngleSmooth[client];
}

/**
 * @brief 设置玩家视角平滑计数器。
 */
public void Player_SetAngleSmooth(int client, int value)
{
    g_iAngleSmooth[client] = value;
}

//=============================================================================

//=============================================================================

/**
 * @brief 线性平滑状态标记。
 * true 时表示正在进行线性位置/角度过渡。
 */
bool g_bIsLinearTransition[MAXPLAYERS + 1];

/**
 * @brief 获取线性平滑状态。
 */
public bool Player_GetIsLinearTransition(int client)
{
    return g_bIsLinearTransition[client];
}

/**
 * @brief 设置线性平滑状态。
 */
public void Player_SetIsLinearTransition(int client, bool value)
{
    g_bIsLinearTransition[client] = value;
}

//=============================================================================

/**
 * @brief 线性平滑起始位置。
 */
float g_fSmoothStartPos[MAXPLAYERS + 1][3];

public void Player_GetSmoothStartPos(int client, float out[3])
{
    out = g_fSmoothStartPos[client];
}

public void Player_SetSmoothStartPos(int client, const float value[3])
{
    g_fSmoothStartPos[client] = value;
}

//=============================================================================

/**
 * @brief 线性平滑结束位置。
 */
float g_fSmoothEndPos[MAXPLAYERS + 1][3];

public void Player_GetSmoothEndPos(int client, float out[3])
{
    out = g_fSmoothEndPos[client];
}

public void Player_SetSmoothEndPos(int client, const float value[3])
{
    g_fSmoothEndPos[client] = value;
}

//=============================================================================

/**
 * @brief 线性平滑起始视角。
 */
float g_fSmoothStartAngles[MAXPLAYERS + 1][3];

public void Player_GetSmoothStartAngles(int client, float out[3])
{
    out = g_fSmoothStartAngles[client];
}

public void Player_SetSmoothStartAngles(int client, const float value[3])
{
    g_fSmoothStartAngles[client] = value;
}

//=============================================================================

/**
 * @brief 线性平滑插值输出视角。
 */
float g_fSmoothLineAngles[MAXPLAYERS + 1][3];

public void Player_GetSmoothLineAngles(int client, float out[3])
{
    out = g_fSmoothLineAngles[client];
}

public void Player_SetSmoothLineAngles(int client, const float value[3])
{
    g_fSmoothLineAngles[client] = value;
}

//=============================================================================

/**
 * @brief 线性平滑结束帧的角度（俯仰/偏航）。
 */
float g_fSmoothEndFrameAngles[MAXPLAYERS + 1][2];

public void Player_GetSmoothEndFrameAngles(int client, float out[2])
{
    out = g_fSmoothEndFrameAngles[client];
}

public void Player_SetSmoothEndFrameAngles(int client, const float value[2])
{
    g_fSmoothEndFrameAngles[client] = value;
}

//=============================================================================

/**
 * @brief 线性插值输出的位置。
 */
float g_fSmoothOutPos[MAXPLAYERS + 1][3];

public void Player_GetSmoothOutPos(int client, float out[3])
{
    out = g_fSmoothOutPos[client];
}

public void Player_SetSmoothOutPos(int client, const float value[3])
{
    g_fSmoothOutPos[client] = value;
}

//=============================================================================

/**
 * @brief 线性插值输出的角度（俯仰/偏航）。
 */
float g_fSmoothOutAng[MAXPLAYERS + 1][2];

public void Player_GetSmoothOutAng(int client, float out[2])
{
    out = g_fSmoothOutAng[client];
}

public void Player_SetSmoothOutAng(int client, const float value[2])
{
    g_fSmoothOutAng[client] = value;
}

//=============================================================================

/**
 * @brief 线性平滑覆盖的总tick数。
 */
int g_iSmoothLineTickCount[MAXPLAYERS + 1];

public int Player_GetSmoothLineTickCount(int client)
{
    return g_iSmoothLineTickCount[client];
}

public void Player_SetSmoothLineTickCount(int client, int value)
{
    g_iSmoothLineTickCount[client] = value;
}

//=============================================================================

/**
 * @brief 线性平滑递减变量。
 */
int g_iSmoothLineDecrement[MAXPLAYERS + 1];

public int Player_GetSmoothLineDecrement(int client)
{
    return g_iSmoothLineDecrement[client];
}

public void Player_SetSmoothLineDecrement(int client, int value)
{
    g_iSmoothLineDecrement[client] = value;
}

//=============================================================================

/**
 * @brief 播放时用于注入的按键掩码。
 */
int g_iPlaybackButtons[MAXPLAYERS + 1];

public int Player_GetPlaybackButtons(int client)
{
    return g_iPlaybackButtons[client];
}

public void Player_SetPlaybackButtons(int client, int value)
{
    g_iPlaybackButtons[client] = value;
}

//=============================================================================

/**
 * @brief 播放时用于注入的扩展按键（下一帧的按键，解决1tick延迟问题）。
 */
int g_iPlaybackButtonsEx[MAXPLAYERS + 1];

public int Player_GetPlaybackButtonsEx(int client)
{
    return g_iPlaybackButtonsEx[client];
}

public void Player_SetPlaybackButtonsEx(int client, int value)
{
    g_iPlaybackButtonsEx[client] = value;
}

//=============================================================================

/**
 * @brief 轨迹绘制当前行索引。
 */
int g_iTraceLine[MAXPLAYERS + 1];

public int Player_GetTraceLine(int client)
{
    return g_iTraceLine[client];
}

public void Player_SetTraceLine(int client, int value)
{
    g_iTraceLine[client] = value;
}

//=============================================================================

/**
 * @brief 是否已加载Replay文件标记。
 */
bool g_bIsFileLoaded[MAXPLAYERS + 1];

public bool Player_GetIsFileLoaded(int client)
{
    return g_bIsFileLoaded[client];
}

public void Player_SetIsFileLoaded(int client, bool value)
{
    g_bIsFileLoaded[client] = value;
}

//=============================================================================

/**
 * @brief 闲置/接管标记位。
 */
int g_iIdleFlags[MAXPLAYERS + 1];

public int Player_GetIdleFlags(int client)
{
    return g_iIdleFlags[client];
}

public void Player_SetIdleFlags(int client, int value)
{
    g_iIdleFlags[client] = value;
}

public void Player_AddIdleFlags(int client, int value)
{
    g_iIdleFlags[client] |= value;
}

public void Player_ClearIdleFlags(int client)
{
    g_iIdleFlags[client] = 0;
}

//=============================================================================

/**
 * @brief 播放开始时的 host_timescale 快照。
 * 用于在自由视角结束后恢复倍速。
 */
float g_fPlaybackTimeScale[MAXPLAYERS + 1];

public float Player_GetPlaybackTimeScale(int client)
{
    return g_fPlaybackTimeScale[client];
}

public void Player_SetPlaybackTimeScale(int client, float value)
{
    g_fPlaybackTimeScale[client] = value;
}

//=============================================================================

/**
 * @brief 多人同步播放的全局起始 tick。
 * -1 表示没有正在进行的同步。
 * 由 Cmd_ReplayContinue 设置，所有玩家共享此 tick 来对齐开始时间。
 */
int g_iReplaySyncStartTick = -1;

/**
 * @brief 玩家是否已武装（等待同步开始）。
 * 在同步 tick 到达前，玩家处于暂停状态，不推进帧。
 */
bool g_bReplaySyncArmed[MAXPLAYERS + 1];

public bool Player_GetIsReplaySyncArmed(int client)
{
    return g_bReplaySyncArmed[client];
}

public void Player_SetReplaySyncArmed(int client, bool value)
{
    g_bReplaySyncArmed[client] = value;
}

//=============================================================================

/**
 * @brief 玩家是否启用 Debug 显示。
 * 由 Debug 子菜单控制开关。
 */
bool g_bDebugEnabled[MAXPLAYERS + 1];

/**
 * @brief 玩家 Debug 显示的目标掩码（位标志）。
 * 第 i 位 = 1 表示显示玩家 i 的调试信息。
 */
int g_iDebugTargetMask[MAXPLAYERS + 1];

//=============================================================================

/**
 * @brief 重置所有与播放/录制相关的玩家状态。
 * 在停止播放、连接断开、地图切换等场景调用。
 */
public void Player_ResetAllReplayState(int client)
{
    if (client < 1 || client > MAXPLAYERS)
    {
        return;
    }
    
    Player_SetIsSegmenting(client, false);
    Player_SetIsRewinding(client, false);
    Player_SetHasRun(client, false);
    Player_SetPlayingReplay(client, false);
    Player_SetRewindFrame(client, 0);
    Player_DeleteRecordFrames(client);
    Player_SetIsPauseWhilePlaying(client, false);
    Player_SetIsLinearTransition(client, false);
    Player_SetAngleSmooth(client, 0);
    Player_SetSmoothLineDecrement(client, 0);
    Player_SetIsFileLoaded(client, false);
    Player_SetTraceLine(client, 0);
    Player_ClearIdleFlags(client);
    Player_SetPlaybackButtons(client, 0);
    Player_SetPlaybackButtonsEx(client, 0);
    g_bReplaySyncArmed[client] = false;
    g_iReplaySyncStartTick = -1;
}