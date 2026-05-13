#if defined REPLAYCOMMANDS_INCLUDED
#endinput
#endif
#define REPLAYCOMMANDS_INCLUDED

#include "STAPlayer.inc"
#include "ReplayFrame.inc"
#include "ReplayFileIO.inc"
#include "ReplayPlayback.inc"
#include "ReplayRecording.inc"

//=============================================================================
// 工具函数
//=============================================================================

/**
 * @brief 重置玩家按键状态。
 * 通过 ClientCommand 发送 -attack/-duck 等指令释放所有按键。
 * 使用 RequestFrame 在下一帧执行。
 *
 * @param client  客户端索引。
 */
public void ResetButton(any client)
{
	if (client > 0 && IsClientInGame(client))
	{
		ClientCommand(client, "-attack");
		ClientCommand(client, "-attack2");
		ClientCommand(client, "-duck");
		ClientCommand(client, "-forward");
		ClientCommand(client, "-back");
		ClientCommand(client, "-use");
		ClientCommand(client, "-left");
		ClientCommand(client, "-right");
		ClientCommand(client, "-moveleft");
		ClientCommand(client, "-moveright");
	}
}

/**
 * @brief 将玩家移动类型设置为 MOVETYPE_NONE（下一帧执行）。
 */
public void SetPlayerMoveTypeNone(any client)
{
	if (client > 0 && IsClientInGame(client))
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
	}
}

/**
 * @brief 重置单个玩家的 Replay 段状态。
 * 清空帧数据、重置状态标记、恢复移动类型。
 *
 * @param client  客户端索引。
 */
public void ResetPlayerReplaySegment(int client)
{
	if (client < 1) return;
	if (!IsClientInGame(client)) return;
	
	Player_ResetAllReplayState(client);
	
	if (IsPlayingOnTeam(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	
	RequestFrame(ResetButton, client);
}

/**
 * @brief 判断玩家是否在生还者或感染者阵营且存活。
 *
 * @param client  客户端索引。
 * @return        true 表示在阵营中且存活。
 */
public bool IsPlayingOnTeam(int client)
{
	int team = GetClientTeam(client);
	return team != L4D2_TEAM_SPECTATOR && team != L4D2_TEAM_NONE && IsPlayerAlive(client);
}

/**
 * @brief 强制停止所有玩家的 Replay 操作。
 * 清理录制/播放状态并恢复移动类型。
 */
public void ForceStopAllReplays()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			ResetPlayerReplaySegment(i);
		}
	}
}

/**
 * @brief 强制停止指定玩家的 Replay 操作。
 *
 * @param client  指定客户端索引。
 */
public void ForceStopPlayerReplay(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ResetPlayerReplaySegment(client);
	}
}

//=============================================================================
// 主菜单
//=============================================================================

/**
 * @brief 打开主 Replay 管理菜单（sm_str）。
 */
public void STR_OpenSegmentReplayMenu(int client)
{
	bool onteam = IsPlayingOnTeam(client);
	Menu menu = CreateMenu(MenuHandler_SegmentReplay);
	SetMenuTitle(menu, "Speedrun TAS Tools (By 悠夏line)");
	
	if (!Player_GetIsSegmenting(client))
	{
		if (!Player_GetHasRun(client))
		{
			if (onteam)
			{
				Menu_AddEnumEntry(menu, SEG_Start, "开始Replay");
			}
			else
			{
				STR_PrintMessageToClient(client, "闲置期间无法录制Replay");
			}
			Menu_AddEnumEntry(menu, SEG_LoadFromFile, "加载Replay");
		}
		else
		{
			if (Player_GetIsPlayingReplay(client))
			{
				if (Player_GetIsRewinding(client))
				{
					Menu_AddEnumEntry(menu, MOV_Resume, "继续");
					Menu_AddEnumEntry(menu, JumpToStart, "跳转至开头");
					Menu_AddEnumEntry(menu, JumpToEnd, "跳转至结尾");
					Menu_AddEnumEntry(menu, MOV_ContinueFrom, "从此处继续Replay");
					Menu_AddEnumEntry(menu, MOV_NewFrom, "从此处开始新Replay");
				}
				else
				{
					Menu_AddEnumEntry(menu, MOV_Pause, "暂停");
					Menu_AddEnumEntry(menu, MOV_Replay2Record, "转为录制");
				}
				Menu_AddEnumEntry(menu, MOV_SaveToFile, "保存Replay");
			}
			else
			{
				Menu_AddEnumEntry(menu, SEG_Play, "播放Replay");
				Menu_AddEnumEntry(menu, SEG_Play_Trace, "绘制Replay轨迹");
				Menu_AddEnumEntry(menu, SEG_Play_Trace_PosMap, "绘制坐标映射轨迹(Def Trick.)");
				Menu_AddEnumEntry(menu, SEG_Play_Trace_Close, "关闭绘制轨迹");
			}
		}
	}
	else
	{
		if (Player_GetIsRewinding(client))
		{
			char speedstr[64];
			FormatEx(speedstr, sizeof(speedstr), "跳转帧数(x值): %d", Player_GetRewindSpeed(client));
			Menu_AddEnumEntry(menu, SEG_Resume, "继续(两秒后)");
			Menu_AddEnumEntry(menu, Step_Forward, "前进x帧");
			Menu_AddEnumEntry(menu, Step_Back, "后退x帧");
			Menu_AddEnumEntry(menu, RewindSpeed_All, speedstr);
			Menu_AddEnumEntry(menu, MOV_SaveToFile, "保存Replay");
			Menu_AddEnumEntry(menu, SEG_Resume_Now, "立即继续");
		}
		else
		{
			Menu_AddEnumEntry(menu, SEG_Pause, "暂停");
		}
	}
	
	Menu_AddEnumEntry(menu, SEG_EXIT, "退出菜单");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

//=============================================================================
// 菜单处理器
//=============================================================================

/**
 * @brief Replay 文件选择菜单处理器。
 */
public int MenuHandler_ReplaySelect(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	
	if (action == MenuAction_Select)
	{
		char info[512];
		bool found = GetMenuItem(menu, param2, info, sizeof(info));
		if (!found) return 0;
		
		char mapbuf[MAX_NAME_LENGTH];
		GetCurrentMap(mapbuf, sizeof(mapbuf));
		
		char filepath[PLATFORM_MAX_PATH];
		BuildReplayFilePath(mapbuf, info, filepath, sizeof(filepath));
		
		if (!LoadReplayFromFile(client, filepath))
		{
			STR_PrintMessageToClient(client, "\"%s\" 无法打开", info);
			return 0;
		}
		
		if (Player_GetStopFrame(client) == 99999)
		{
			STR_PrintMessageToClient(client, "%N的StopFrame参数已自动设置为99999", client);
		}
		
		STR_PrintMessageToClient(client, "已加载Replay \"%s\"", info);
		Player_SetHasRun(client, true);
		STR_OpenSegmentReplayMenu(client);
	}
	else if (action == MenuAction_Cancel)
	{
		// do nothing
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	
	return 0;
}

/**
 * @brief 主功能菜单处理器。
 * 处理录制/播放/暂停/保存等所有菜单操作。
 */
public int MenuHandler_SegmentReplay(Menu menu, MenuAction action, int param1, int param2)
{
	int client = param1;
	
	if (action == MenuAction_Select)
	{
		char info[3];
		bool found = GetMenuItem(menu, param2, info, sizeof(info));
		if (!found) return 0;
		
		int itemid = StringToInt(info);
		
		switch (itemid)
		{
			case SEG_Start:
			{
				STR_PrintMessageToClient(client, "开始记录Replay...");
				Player_SetIsSegmenting(client, true);
				Player_SetIsRewinding(client, false);
				Player_SetHasRun(client, false);
				Player_SetPlayingReplay(client, false);
				Player_CreateFrameArray(client);
				Player_SetRewindFrame(client, 0);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_LoadFromFile:
			{
				char mapbuf[MAX_NAME_LENGTH];
				GetCurrentMap(mapbuf, sizeof(mapbuf));
				
				char mapreplaybuf[PLATFORM_MAX_PATH];
				BuildReplayDirPath(mapbuf, mapreplaybuf, sizeof(mapreplaybuf));
				
				if (!DirExists(mapreplaybuf))
				{
					STR_PrintMessageToClient(client, "无可用文件(\"%s\")", mapbuf);
					return 0;
				}
				
				DirectoryListing dirlist = OpenDirectory(mapreplaybuf);
				if (dirlist == null)
				{
					STR_PrintMessageToClient(client, "无法打开文件夹");
					return 0;
				}
				
				FileType curtype;
				char curname[512];
				int index = 0;
				
				Menu selectmenu = CreateMenu(MenuHandler_ReplaySelect);
				SetMenuTitle(selectmenu, "选择Replay文件");
				
				while (dirlist.GetNext(curname, sizeof(curname), curtype))
				{
					if (curtype != FileType_File)
						continue;
					AddMenuItem(selectmenu, curname, curname);
					index++;
				}
				delete dirlist;
				
				if (index == 0)
				{
					STR_PrintMessageToClient(client, "No replays available");
					return 0;
				}
				
				DisplayMenu(selectmenu, client, MENU_TIME_FOREVER);
			}
			
			case MOV_SaveToFile:
			{
				char mapbuf[MAX_NAME_LENGTH];
				GetCurrentMap(mapbuf, sizeof(mapbuf));
				
				char playernamebuf[MAX_NAME_LENGTH];
				GetClientName(client, playernamebuf, sizeof(playernamebuf));
				
				char newdirbuf[PLATFORM_MAX_PATH];
				BuildReplayDirPath(mapbuf, newdirbuf, sizeof(newdirbuf));
				if (!DirExists(newdirbuf))
					CreateDirectory(newdirbuf, 511);
				
				char timebuf[128];
				FormatTime(timebuf, sizeof(timebuf), "%Y %m %d, %H %M %S");
				
				char namebuf[256];
				FormatEx(namebuf, sizeof(namebuf), "[%s] (%s)", mapbuf, timebuf);
				
				char filename[PLATFORM_MAX_PATH];
				FormatEx(filename, sizeof(filename), "%s/%s.STR", newdirbuf, namebuf);
				
				if (!SaveReplayToFile(client, filename))
				{
					STR_PrintMessageToClient(client, "无法保存Replay");
					return 0;
				}
				
				STR_PrintMessageToClient(client, "保存Replay文件： \"%s\"", namebuf);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_Resume:
			{
				float t_scale = GetConVarFloat(FindConVar("host_timescale"));
				CreateTimer(2.0 * t_scale, Timer_ResumeRecord, client, TIMER_REPEAT);
			}
			
			case SEG_Resume_Now:
			{
				Player_SetIsRewinding(client, false);
				SetEntityMoveType(client, MOVETYPE_WALK);
				Player_SetLastPausedTick(client, Player_GetRewindFrame(client));
				Player_ResizeRecordFrameList(client, Player_GetRewindFrame(client));
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_EXIT:
			{
				ResetPlayerReplaySegment(client);
				RequestFrame(ResetButton, client);
			}
			
			case SEG_Pause:
			{
				Player_SetIsRewinding(client, true);
				Player_SetIsSegmenting(client, true);
				Player_SetHasRun(client, false);
				Player_SetPlayingReplay(client, false);
				SetEntityMoveType(client, MOVETYPE_NONE);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_GoBack:
			{
				int newframe = Player_GetLastPausedTick(client);
				newframe = Player_ClampRecordFrame(client, newframe);
				Player_SetRewindFrame(client, newframe);
				Player_SetIsRewinding(client, true);
				SetEntityMoveType(client, MOVETYPE_NONE);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_Play:
			{
				Player_SetPlayingReplay(client, true);
				Player_SetRewindFrame(client, 0);
				Player_SetIsRewinding(client, true);
				STR_PrintMessageToClient(client, "开始播放Replay.");
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_Play_Trace:
			{
				char tracebuf[128];
				Format(tracebuf, sizeof(tracebuf), "sm_replaydrawtrace %d", client);
				ClientCommand(client, tracebuf);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_Play_Trace_PosMap:
			{
				char tracebuf[128];
				Format(tracebuf, sizeof(tracebuf), "sm_replaydrawtrace_posmap %d", client);
				ClientCommand(client, tracebuf);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_Play_Trace_Close:
			{
				char traceclosebuf[128];
				Format(traceclosebuf, sizeof(traceclosebuf), "sm_replaydrawtraceclose %d", client);
				ClientCommand(client, traceclosebuf);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case SEG_Stop:
			{
				Player_SetHasRun(client, true);
				Player_SetIsSegmenting(client, false);
				Player_SetIsRewinding(client, false);
				Player_SetPlayingReplay(client, false);
				SetEntityMoveType(client, MOVETYPE_WALK);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case Step_Back:
			{
				STR_StepBack(client, Player_GetRewindSpeed(client));
				STR_OpenSegmentReplayMenu(client);
			}
			
			case Step_Forward:
			{
				STR_StepForward(client, Player_GetRewindSpeed(client));
				STR_OpenSegmentReplayMenu(client);
			}
			
			case Rewind:
			{
				STR_RewindDown(client, 1);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case Fastforward:
			{
				STR_FastForwardDown(client, 1);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case MOV_Resume:
			{
				Player_SetIsRewinding(client, false);
				SetEntityMoveType(client, MOVETYPE_WALK);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case MOV_Resume_Close:
			{
				CreateTimer(1.5, Timer_ResumePlayClose, client, TIMER_REPEAT);
			}
			
			case MOV_NewFrom:
			{
				any frameinfo[FRAME_Length];
				int frame = Player_GetRewindFrame(client);
				Player_GetFrame(client, frame, frameinfo);
				
				ResetPlayerReplaySegment(client);
				Player_SetIsSegmenting(client, true);
				Player_SetIsRewinding(client, true);
				Player_SetHasRun(client, true);
				Player_SetPlayingReplay(client, true);
				Player_CreateFrameArray(client);
				Player_SetRewindFrame(client, 0);
				Player_PushFrame(client, frameinfo);
				
				SetEntityMoveType(client, MOVETYPE_NONE);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case MOV_Stop:
			{
				Player_SetHasRun(client, true);
				Player_SetIsSegmenting(client, false);
				Player_SetIsRewinding(client, false);
				Player_SetPlayingReplay(client, false);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case MOV_Pause:
			{
				Player_SetIsRewinding(client, true);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case MOV_Replay2Record:
			{
				int endframe = Player_GetRewindFrame(client) + 1;
				int framecount = Player_GetRecordedFramesCount(client) - 1;
				if (endframe > framecount)
				{
					endframe = framecount;
				}
				
				Player_ResizeRecordFrameList(client, endframe);
				Player_SetIsSegmenting(client, true);
				Player_SetIsRewinding(client, false);
				Player_SetHasRun(client, false);
				Player_SetPlayingReplay(client, false);
				SetEntityMoveType(client, MOVETYPE_WALK);
				Player_SetRewindFrame(client, endframe - 1);
				
				// Bug修复: 转录制时重置平滑相关状态
				Player_SetIsLinearTransition(client, false);
				Player_SetAngleSmooth(client, 0);
				Player_SetSmoothLineDecrement(client, 0);
				
				RequestFrame(ResetButton, client);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case MOV_ContinueFrom:
			{
				int endframe = Player_GetRewindFrame(client) + 1;
				int framecount = Player_GetRecordedFramesCount(client) - 1;
				if (endframe > framecount)
				{
					endframe = framecount;
				}
				
				Player_ResizeRecordFrameList(client, endframe);
				Player_SetIsSegmenting(client, true);
				Player_SetIsRewinding(client, true);
				Player_SetHasRun(client, false);
				Player_SetPlayingReplay(client, false);
				SetEntityMoveType(client, MOVETYPE_NONE);
				Player_SetRewindFrame(client, endframe - 1);
				RequestFrame(ResetButton, client);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case RewindSpeed_All:
			{
				int curspeed = Player_GetRewindSpeed(client);
				curspeed *= 4;
				if (curspeed > 64)
				{
					curspeed = 1;
				}
				Player_SetRewindSpeed(client, curspeed);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case JumpToStart:
			{
				Player_SetRewindFrame(client, 0);
				SetPlayerReplayFrame(client, client, 0);
				STR_OpenSegmentReplayMenu(client);
			}
			
			case JumpToEnd:
			{
				int endFrame = Player_GetRecordedFramesCount(client) - 1;
				Player_SetRewindFrame(client, endFrame);
				SetPlayerReplayFrame(client, client, endFrame);
				STR_OpenSegmentReplayMenu(client);
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ResetPlayerReplaySegment(client);
		ClientCommand(client, "-duck");
		ClientCommand(client, "-forward");
		ClientCommand(client, "-back");
		ClientCommand(client, "-attack");
		ClientCommand(client, "-use");
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	
	return 0;
}

//=============================================================================
// Console Commands
//=============================================================================

/**
 * @brief sm_str 命令处理器。
 */
public Action Cmd_STR_Main(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[STR] - This command can only be used in-game.");
		return Plugin_Handled;
	}
	STR_OpenSegmentReplayMenu(client);
	return Plugin_Handled;
}

/**
 * @brief sm_loadfile 命令处理器。
 * 用法：sm_loadfile <客户端索引> <文件名>
 */
public Action Cmd_LoadFile(int client, int args)
{
	if (args == 2)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (client > 0 && IsClientInGame(client))
		{
			GetCmdArg(2, sArg, sizeof(sArg));
			char info[512];
			info = sArg;
			
			char mapbuf[MAX_NAME_LENGTH];
			GetCurrentMap(mapbuf, sizeof(mapbuf));
			
			char filepath[PLATFORM_MAX_PATH];
			BuildReplayFilePath(mapbuf, info, filepath, sizeof(filepath));
			
			if (!LoadReplayFromFile(client, filepath))
			{
				STR_PrintMessageToClient(client, "\"%s\" 无法打开", info);
				return Plugin_Continue;
			}
			
			STR_PrintMessageToAllClients("%N 已加载Replay(Cmd) \"%s\"", client, info);
		}
	}
	return Plugin_Handled;
}

/**
 * @brief sm_replay_continue 命令处理器。
 * 用法：sm_replay_continue <客户端索引>
 * 从 StartFrame 开始平滑播放。
 */
public Action Cmd_ReplayContinue(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (Player_GetIsFileLoaded(client))
		{
			Player_SetHasRun(client, true);
			Player_SetPlayingReplay(client, true);
			Player_SetRewindFrame(client, Player_GetStartFrame(client));
			Player_SetIsRewinding(client, true);
			
			int lineSmooth = Player_GetEndFrame(client) - Player_GetStartFrame(client);
			if (lineSmooth < 1)
			{
				lineSmooth = 1;
			}
			Player_SetSmoothLineDecrement(client, lineSmooth);
			g_bReplaySyncArmed[client] = true;
			if (g_iReplaySyncStartTick == -1)
			{
				g_iReplaySyncStartTick = GetGameTickCount() + 3;
			}
		}
		else
		{
			STR_PrintMessageToAllClients("%N的Replay文件没有加载.", client);
		}
	}
	return Plugin_Handled;
}

/**
 * @brief sm_replayrecord 命令处理器。
 * 用法：sm_replayrecord <客户端索引>
 */
public Action Cmd_ReplayRecord(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		Player_SetIsSegmenting(client, true);
		Player_SetIsRewinding(client, false);
		Player_SetHasRun(client, false);
		Player_SetPlayingReplay(client, false);
		Player_CreateFrameArray(client);
		Player_SetRewindFrame(client, 0);
		
		STR_PrintMessageToAllClients("开始记录%N的Replay(Cmd)...", client);
		STR_OpenSegmentReplayMenu(client);
	}
	return Plugin_Handled;
}

/**
 * @brief sm_replaysave 命令处理器。
 * 用法：sm_replaysave <客户端索引>
 */
public Action Cmd_ReplaySave(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		Player_SetIsRewinding(client, false);
		
		if (Player_GetIsSegmenting(client) || GetClientTeam(client) == 3)
		{
			char mapbuf[MAX_NAME_LENGTH];
			GetCurrentMap(mapbuf, sizeof(mapbuf));
			
			char newdirbuf[PLATFORM_MAX_PATH];
			BuildReplayDirPath(mapbuf, newdirbuf, sizeof(newdirbuf));
			if (!DirExists(newdirbuf))
				CreateDirectory(newdirbuf, 511);
			
			char timebuf[128];
			FormatTime(timebuf, sizeof(timebuf), "%Y %m %d, %H %M %S");
			
			char namebuf[256];
			FormatEx(namebuf, sizeof(namebuf), "%s (%s)", mapbuf, timebuf);
			
			char filename[PLATFORM_MAX_PATH];
			FormatEx(filename, sizeof(filename), "%s/%s.STR", newdirbuf, namebuf);
			
			if (!SaveReplayToFile(client, filename))
			{
				STR_PrintMessageToAllClients("无法保存%N的Replay", client);
				return Plugin_Handled;
			}
			
			STR_PrintMessageToAllClients("已保存%N的Replay文件(Cmd)： \"%s\"", client, namebuf);
		}
		else
		{
			STR_PrintMessageToAllClients("%N没有在记录Replay.", client);
		}
	}
	else
	{
		STR_PrintMessageToAllClients("%N的Save参数有误.", client);
	}
	return Plugin_Handled;
}

/**
 * @brief sm_resetreplay 命令处理器。
 * 用法：sm_resetreplay <客户端索引>
 */
public Action Cmd_ResetReplay(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		ResetPlayerReplaySegment(client);
		STR_PrintMessageToClient(client, "Replay Reseted");
	}
	return Plugin_Handled;
}

/**
 * @brief sm_smoothreplay 命令处理器。
 * 用法：sm_smoothreplay <客户端索引>
 */
public Action Cmd_SmoothReplay(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (Player_GetIsFileLoaded(client))
		{
			any frameinfo[FRAME_Length];
			
			Player_GetFrame(client, Player_GetStartFrame(client), frameinfo);
			float startPos[3];
			GetArrayVector3(frameinfo, FRAME_PosX, startPos);
			Player_SetSmoothStartPos(client, startPos);
			
			Player_GetFrame(client, Player_GetEndFrame(client), frameinfo);
			float endPos[3];
			GetArrayVector3(frameinfo, FRAME_PosX, endPos);
			Player_SetSmoothEndPos(client, endPos);
			
			Player_SetIsLinearTransition(client, true);
			CreateTimer(0.01, Timer_SmoothReplay, client, TIMER_REPEAT);
			
			STR_PrintMessageToAllClients("%N的Smooth设置成功", client);
		}
		else
		{
			STR_PrintMessageToAllClients("%N的Replay文件没有加载.", client);
		}
	}
	return Plugin_Handled;
}

/**
 * @brief 平滑定时器回调：当玩家移动到目标位置附近时自动继续播放。
 */
public Action Timer_SmoothReplay(Handle timer, any client)
{
	float fOrigin[3];
	GetClientAbsOrigin(client, fOrigin);
	
	float startPos[3], endPos[3];
	Player_GetSmoothStartPos(client, startPos);
	Player_GetSmoothEndPos(client, endPos);
	
	if (GetVectorDistance(endPos, fOrigin, false) < GetVectorDistance(startPos, endPos, false)
		&& GetEntityFlags(client) & FL_ONGROUND)
	{
		ClientCommand(client, "sm_replay_continue %d", client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/**
 * @brief 恢复录制定时器。
 */
public Action Timer_ResumeRecord(Handle timer, any client)
{
	Player_SetIsRewinding(client, false);
	SetEntityMoveType(client, MOVETYPE_WALK);
	Player_SetLastPausedTick(client, Player_GetRewindFrame(client));
	Player_ResizeRecordFrameList(client, Player_GetRewindFrame(client));
	STR_OpenSegmentReplayMenu(client);
	return Plugin_Stop;
}

/**
 * @brief 恢复播放并关闭菜单定时器。
 */
public Action Timer_ResumePlayClose(Handle timer, any client)
{
	Player_SetIsRewinding(client, false);
	SetEntityMoveType(client, MOVETYPE_WALK);
	return Plugin_Stop;
}

/**
 * @brief sm_replay_pause 命令处理器。
 * 用法：sm_replay_pause <客户端索引>
 */
public Action Cmd_ReplayPause(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (client > 0 && IsClientInGame(client))
		{
			Player_SetIsPauseWhilePlaying(client, true);
			Player_SetIsRewinding(client, true);
			RequestFrame(SetPlayerMoveTypeNone, client);
			STR_PrintMessageToAllClients("%N 的Replay已暂停.", client);
		}
	}
	else
	{
		STR_PrintMessageToClient(client, "输入参数错误");
	}
	return Plugin_Handled;
}

/**
 * @brief sm_replay_unpause 命令处理器。
 * 用法：sm_replay_unpause <客户端索引>
 */
public Action Cmd_ReplayUnPause(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (client > 0 && IsClientInGame(client))
		{
			Player_SetIsPauseWhilePlaying(client, false);
			Player_SetIsRewinding(client, false);
			STR_PrintMessageToAllClients("%N 的Replay已取消暂停.", client);
		}
	}
	else
	{
		STR_PrintMessageToClient(client, "输入参数错误");
	}
	return Plugin_Handled;
}

/**
 * @brief sm_startframe / sm_endframe / sm_stopframe 命令组。
 * 设置播放帧范围参数。
 */
public Action Cmd_SetFrameParam(int client, int args)
{
	if (args == 2)
	{
		char sArgCmd[32], sArgVal[128];
		GetCmdArg(0, sArgCmd, sizeof(sArgCmd));
		GetCmdArg(1, sArgVal, sizeof(sArgVal));
		client = StringToInt(sArgVal);
		
		if (client > 0 && IsClientInGame(client))
		{
			GetCmdArg(2, sArgVal, sizeof(sArgVal));
			int value = StringToInt(sArgVal);
			
			if (StrEqual(sArgCmd, "sm_startframe"))
			{
				Player_SetStartFrame(client, value);
				STR_PrintMessageToAllClients("%N 的StartFrame参数已设置为%d", client, value);
			}
			else if (StrEqual(sArgCmd, "sm_endframe"))
			{
				Player_SetEndFrame(client, value);
				STR_PrintMessageToAllClients("%N 的EndFrame参数已设置为%d", client, value);
			}
			else if (StrEqual(sArgCmd, "sm_stopframe"))
			{
				Player_SetStopFrame(client, value);
				STR_PrintMessageToAllClients("%N 的StopFrame参数已设置为%d", client, value);
			}
		}
	}
	else
	{
		STR_PrintMessageToClient(client, "输入参数错误");
	}
	return Plugin_Handled;
}

/**
 * @brief sm_replay_split 命令处理器。
 * 从已有Replay中截取一段保存为新文件。
 * 用法：sm_replay_split <客户端> <起始帧> <结束帧>
 */
public Action Cmd_ReplaySplit(int client, int args)
{
	if (args == 3)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (client > 0 && IsClientInGame(client) && Player_GetIsFileLoaded(client))
		{
			int framecount = Player_GetRecordedFramesCount(client);
			
			GetCmdArg(2, sArg, sizeof(sArg));
			int frame_start = StringToInt(sArg);
			GetCmdArg(3, sArg, sizeof(sArg));
			int frame_end = StringToInt(sArg);
			
			if (frame_start < frame_end && frame_end <= framecount && frame_start >= 0)
			{
				char mapbuf[MAX_NAME_LENGTH];
				GetCurrentMap(mapbuf, sizeof(mapbuf));
				
				char newdirbuf[PLATFORM_MAX_PATH];
				BuildReplayDirPath(mapbuf, newdirbuf, sizeof(newdirbuf));
				if (!DirExists(newdirbuf))
					CreateDirectory(newdirbuf, 511);
				
				char timebuf[128];
				FormatTime(timebuf, sizeof(timebuf), "%Y %m %d, %H %M %S");
				
				char namebuf[256];
				FormatEx(namebuf, sizeof(namebuf), "[%s] (%s)", mapbuf, timebuf);
				
				char filename[PLATFORM_MAX_PATH];
				FormatEx(filename, sizeof(filename), "%s/%s_Splited.STR", newdirbuf, namebuf);
				
				if (SplitReplayToFile(client, filename, frame_start, frame_end))
				{
					STR_PrintMessageToClient(client, "保存Replay文件： \"%s_Splited\"", namebuf);
				}
				else
				{
					STR_PrintMessageToAllClients("%N 分离Replay参数设置错误，请检查.", client);
				}
			}
			else
			{
				STR_PrintMessageToAllClients("%N 分离Replay参数设置错误，请检查.", client);
			}
		}
		else
		{
			STR_PrintMessageToAllClients("请先为玩家%N加载Replay.", client);
		}
	}
	else
	{
		STR_PrintMessageToClient(client, "输入参数错误");
	}
	return Plugin_Handled;
}

/**
 * @brief sm_removeslot 命令处理器。
 * 删除玩家指定武器槽位的物品。
 * 用法：sm_removeslot <客户端> <槽位编号1-5>
 */
public Action Cmd_RemoveSlot(int client, int args)
{
	if (args == 2)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (client > 0 && IsClientInGame(client))
		{
			GetCmdArg(2, sArg, sizeof(sArg));
			int slotIndex = StringToInt(sArg);
			int weapon = GetPlayerWeaponSlot(client, slotIndex - 1);
			AcceptEntityInput(weapon, "Kill");
			
			switch (slotIndex)
			{
				case 1: STR_PrintMessageToAllClients("%N 的主武器已移除", client);
				case 2: STR_PrintMessageToAllClients("%N 的副武器已移除", client);
				case 3: STR_PrintMessageToAllClients("%N 的投掷品已移除", client);
				case 4: STR_PrintMessageToAllClients("%N 的栏位4物品已移除", client);
				case 5: STR_PrintMessageToAllClients("%N 的栏位5物品已移除", client);
			}
		}
	}
	else
	{
		STR_PrintMessageToClient(client, "输入参数错误");
	}
	return Plugin_Handled;
}

/**
 * @brief sm_test 调试命令。
 */
public Action Cmd_Test(int client, int args)
{
	if (args == 2)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		GetCmdArg(2, sArg, sizeof(sArg));
		int client_2 = StringToInt(sArg);
		
		char sTrace[512];
		float pos[2][3];
		GetClientAbsOrigin(client, pos[0]);
		GetClientAbsOrigin(client_2, pos[1]);
		
		Format(sTrace, sizeof(sTrace),
			"DebugDrawLine(Vector(%f, %f, %f), Vector(%f, %f, %f), 0, 0, 255, true, 86400);",
			pos[0][0], pos[0][1], pos[0][2], pos[1][0], pos[1][1], pos[1][2]);
		SetVariantString(sTrace);
		AcceptEntityInput(client, "RunScriptCode");
	}
	else
	{
		STR_PrintMessageToAllClients("参数错误(需要两个参数).");
	}
	return Plugin_Handled;
}

//=============================================================================
// 步进/倒带/快进控制
//=============================================================================

/**
 * @brief 前进指定帧数。
 */
public Action STR_StepForward(int client, int args)
{
	if (!Player_GetIsRewinding(client))
	{
		return Plugin_Handled;
	}
	
	int oldfactor = Player_GetRewindSpeed(client);
	Player_SetRewindSpeed(client, args);
	Player_SetHasFastForwardKeyDown(client, true);
	HandleReplayRewind(client);
	Player_SetRewindSpeed(client, oldfactor);
	Player_SetHasFastForwardKeyDown(client, false);
	
	return Plugin_Handled;
}

/**
 * @brief 后退指定帧数。
 */
public Action STR_StepBack(int client, int args)
{
	if (!Player_GetIsRewinding(client))
	{
		return Plugin_Handled;
	}
	
	int oldfactor = Player_GetRewindSpeed(client);
	Player_SetRewindSpeed(client, args);
	Player_SetHasRewindKeyDown(client, true);
	HandleReplayRewind(client);
	Player_SetRewindSpeed(client, oldfactor);
	Player_SetHasRewindKeyDown(client, false);
	
	return Plugin_Handled;
}

/**
 * @brief 开始倒带。
 */
public Action STR_RewindDown(int client, int args)
{
	if (!Player_GetIsRewinding(client))
	{
		return Plugin_Handled;
	}
	Player_SetHasRewindKeyDown(client, true);
	return Plugin_Handled;
}

/**
 * @brief 停止倒带。
 */
public Action STR_RewindUp(int client, int args)
{
	if (!Player_GetIsRewinding(client))
	{
		return Plugin_Handled;
	}
	Player_SetHasRewindKeyDown(client, false);
	return Plugin_Handled;
}

/**
 * @brief 开始快进。
 */
public Action STR_FastForwardDown(int client, int args)
{
	if (!Player_GetIsRewinding(client))
	{
		return Plugin_Handled;
	}
	Player_SetHasFastForwardKeyDown(client, true);
	return Plugin_Handled;
}

//=============================================================================
// 轨迹绘制
//=============================================================================

/**
 * @brief 用光束线绘制两点间的轨迹（发送给所有客户端）。
 * 优化版本：使用循环替代重复代码。
 *
 * @param sprite    光束精灵索引。
 * @param points    轨迹点数组（必须恰好20个点）。
 * @param lifetime  显示生命周期。
 * @param color     颜色RGBA。
 */
public void STR_DisplayTraceToAll(int sprite, float points[20][3], float lifetime, int color[4])
{
	for (int i = 0; i < 19; i++)
	{
		TE_SetupBeamPoints(points[i], points[i + 1], sprite, 0, 0, 0, lifetime, 1.0, 1.0, 5, 0.0, color, 0);
		TE_SendToAll();
	}
}

/**
 * @brief sm_replaydrawtrace 命令处理器。
 * 使用 VScript DebugDrawLine 绘制 Replay 路径。
 */
public Action Cmd_ReplayDrawTrace(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (Player_GetIsFileLoaded(client))
		{
			int length = Player_GetRecordedFramesCount(client);
			float pos[2][3];
			char sTrace[512];
			
			char sPerspective[8];
			if (GetConVarBool(b_ReplayDebug))
			{
				sPerspective = "true";
			}
			else
			{
				sPerspective = "false";
			}
			
			for (int i = 1; i < length - 1; i++)
			{
				any frameinfo[2][FRAME_Length];
				Player_GetFrame(client, i, frameinfo[0]);
				GetArrayVector3(frameinfo[0], FRAME_PosX, pos[0]);
				Player_GetFrame(client, i + 1, frameinfo[1]);
				GetArrayVector3(frameinfo[1], FRAME_PosX, pos[1]);
				
				Format(sTrace, sizeof(sTrace),
					"DebugDrawLine(Vector(%f, %f, %f), Vector(%f, %f, %f), 0, 255, 0, %s, 86400);",
					pos[0][0], pos[0][1], pos[0][2], pos[1][0], pos[1][1], pos[1][2], sPerspective);
				SetVariantString(sTrace);
				AcceptEntityInput(client, "RunScriptCode");
			}
			STR_PrintMessageToAllClients("绘制%N的Replay轨迹.", client);
		}
		else
		{
			SetVariantString("DebugDrawClear()");
			AcceptEntityInput(client, "RunScriptCode");
			STR_PrintMessageToAllClients("请先为玩家%N加载Replay.", client);
		}
	}
	else
	{
		STR_PrintMessageToClient(client, "参数错误(输入一个参数).");
	}
	return Plugin_Handled;
}

/**
 * @brief sm_replaydrawtrace_posmap 命令处理器。
 * 带坐标偏移的轨迹绘制（用于电击器Trick调试）。
 */
public Action Cmd_ReplayDrawTracePosMap(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (Player_GetIsFileLoaded(client))
		{
			float fPosMap[3];
			fPosMap[0] = GetConVarFloat(g_ConVar_PosMap_x);
			fPosMap[1] = GetConVarFloat(g_ConVar_PosMap_y);
			fPosMap[2] = GetConVarFloat(g_ConVar_PosMap_z);
			
			int length = Player_GetRecordedFramesCount(client);
			float pos[2][3];
			char sTrace[512];
			
			char sPerspective[8];
			if (GetConVarBool(b_ReplayDebug))
			{
				sPerspective = "true";
			}
			else
			{
				sPerspective = "false";
			}
			
			for (int i = 1; i < length - 1; i++)
			{
				any frameinfo[2][FRAME_Length];
				Player_GetFrame(client, i, frameinfo[0]);
				GetArrayVector3(frameinfo[0], FRAME_PosX, pos[0]);
				Player_GetFrame(client, i + 1, frameinfo[1]);
				GetArrayVector3(frameinfo[1], FRAME_PosX, pos[1]);
				
				Format(sTrace, sizeof(sTrace),
					"DebugDrawLine(Vector(%f, %f, %f), Vector(%f, %f, %f), 255, 0, 0, %s, 86400);",
					pos[0][0] + fPosMap[0], pos[0][1] + fPosMap[1], pos[0][2] + fPosMap[2],
					pos[1][0] + fPosMap[0], pos[1][1] + fPosMap[1], pos[1][2] + fPosMap[2],
					sPerspective);
				SetVariantString(sTrace);
				AcceptEntityInput(client, "RunScriptCode");
			}
			STR_PrintMessageToAllClients("绘制%N的Replay轨迹(PosMap).", client);
		}
		else
		{
			SetVariantString("DebugDrawClear()");
			AcceptEntityInput(client, "RunScriptCode");
			STR_PrintMessageToAllClients("请先为玩家%N加载Replay.", client);
		}
	}
	else
	{
		STR_PrintMessageToClient(client, "参数错误(输入一个参数).");
	}
	return Plugin_Handled;
}

/**
 * @brief sm_replaydrawtraceclose 命令处理器。
 * 清除所有轨迹绘制。
 */
public Action Cmd_ReplayCloseDrawTrace(int client, int args)
{
	if (args == 1)
	{
		char sArg[128];
		GetCmdArg(1, sArg, sizeof(sArg));
		client = StringToInt(sArg);
		
		if (client < 1) return Plugin_Handled;
		
		SetVariantString("DebugDrawClear()");
		AcceptEntityInput(client, "RunScriptCode");
		STR_PrintMessageToAllClients("轨迹绘制已关闭.");
	}
	return Plugin_Handled;
}

/**
 * @brief 在指定位置显示光环（已弃用，保留兼容）。
 */
public void STR_DisplayRingToClient(int client, int sprite, float points[3], float radius, float lifetime)
{
	TE_SetupBeamRingPoint(points, radius, radius + 5.0, sprite, 0, 0, 0, lifetime, 2.0, 0.0, {255, 0, 255, 255}, 0, 0);
}
