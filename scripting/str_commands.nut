//Squirrel

/*
STR 命令的 VScript 封装 —— 同步调用接口。

用法（Squirrel 脚本中）：
  ::ST_STR(hPlayer, eMode)       — eMode: 0=录制, 1=播放, 2=重置
  ::ST_STRStop(hPlayer)          — 停止/重置
  ::ST_STR_Save(hPlayer)         — 保存录制的 Replay
  ::ST_STR_Pause(hPlayer)        — 暂停播放
  ::ST_STR_UnPause(hPlayer)      — 取消暂停
  ::ST_STR_LoadFile(hPlayer, sFileName) — 加载 Replay 文件
  // 设置:
  ::ST_STR_SetPlayToRecord(bEnable)
  ::ST_STR_SetOnlySetVel(bEnable)
  ::ST_STR_SetShowFrame(bEnable)
  ::ST_STR_SetReplayDebug(bEnable)
  ::ST_STR_SetPlayWhenIncapped(bEnable)
  ::ST_STR_SetPosMap(x, y, z)

所有函数均使用 Convars.SetValue() 实现，SourceMod 侧的
ConVarChanged 回调在当前帧同步执行，没有 SendToConsole 的一帧延迟。

注意：
  使用 ST_STR_Play 之前必须先调用 ST_STR_LoadFile 加载文件，
  并设置好 StartFrame / EndFrame（否则会使用默认值 0）。
*/

//====================================================================
// 基础操作（同步 — Convars.SetValue → HookConVarChange）
//====================================================================

::ST_STR <- function(hPlayer = null, eMode = 0)
{
    if (hPlayer == null) hPlayer = PlayerInstanceFromIndex(1);
    if (!IsPlayer(hPlayer)) return;

    if (eMode == 0)           // 录制
        Convars.SetValue("str_trigger_record", hPlayer.GetEntityIndex());
    else if (eMode == 1)      // 播放
        Convars.SetValue("str_trigger_play", hPlayer.GetEntityIndex());
    else if (eMode == 2)      // 重置/停止
        Convars.SetValue("str_trigger_reset", hPlayer.GetEntityIndex());
    else
        printl("[ST_STR] Unknown mode: " + eMode + " (0=Record, 1=Play, 2=Reset)");
}

//============================================================
//============================================================

::ST_STRStop <- function(hPlayer = null)
{
    if (IsPlayer(hPlayer))
        return Convars.SetValue("str_trigger_reset", hPlayer.GetEntityIndex());
    hPlayer = null;
    while ((hPlayer = Entities.FindByClassname(hPlayer, "player")) != null)
    {
        Convars.SetValue("str_trigger_reset", hPlayer.GetEntityIndex());
    }
}

//============================================================
//============================================================

::ST_STR_Save <- function(hPlayer = null)
{
    if (hPlayer == null) hPlayer = PlayerInstanceFromIndex(1);
    if (!IsPlayer(hPlayer)) return;
    Convars.SetValue("str_trigger_save", hPlayer.GetEntityIndex());
}

//============================================================
//============================================================

::ST_STR_Pause <- function(hPlayer = null)
{
    if (hPlayer == null) hPlayer = PlayerInstanceFromIndex(1);
    if (!IsPlayer(hPlayer)) return;
    Convars.SetValue("str_trigger_pause", hPlayer.GetEntityIndex());
}

//============================================================
//============================================================

::ST_STR_UnPause <- function(hPlayer = null)
{
    if (hPlayer == null) hPlayer = PlayerInstanceFromIndex(1);
    if (!IsPlayer(hPlayer)) return;
    Convars.SetValue("str_trigger_unpause", hPlayer.GetEntityIndex());
}

//============================================================
//============================================================

::ST_STR_LoadFile <- function(hPlayer, sFileName)
{
    if (hPlayer == null) hPlayer = PlayerInstanceFromIndex(1);
    if (!IsPlayer(hPlayer)) return;
    if (sFileName == null || sFileName == "") return;
    Convars.SetValue("str_trigger_load", hPlayer.GetEntityIndex() + ";" + sFileName);
}

//====================================================================
// 设置 ConVars（同步）
//====================================================================

::ST_STR_SetPlayToRecord <- function(bEnable = true)
{
    Convars.SetValue("sm_replaytorecord", bEnable ? "1" : "0");
}

//============================================================

::ST_STR_SetOnlySetVel <- function(bEnable = true)
{
    Convars.SetValue("str_onlysetvel", bEnable ? "1" : "0");
}

//============================================================

::ST_STR_SetShowFrame <- function(bEnable = true)
{
    Convars.SetValue("sm_showframe", bEnable ? "1" : "0");
}

//============================================================

::ST_STR_SetReplayDebug <- function(bEnable = true)
{
    Convars.SetValue("sm_replaydebug", bEnable ? "1" : "0");
}

//============================================================

::ST_STR_SetPlayWhenIncapped <- function(bEnable = true)
{
    Convars.SetValue("sm_replay_incapacitated", bEnable ? "1" : "0");
}

//============================================================

::ST_STR_SetPosMap <- function(x, y, z)
{
    if (x == null) x = 0.0;
    if (y == null) y = 0.0;
    if (z == null) z = 0.0;
    Convars.SetValue("str_posmap_x", x.tostring());
    Convars.SetValue("str_posmap_y", y.tostring());
    Convars.SetValue("str_posmap_z", z.tostring());
}
