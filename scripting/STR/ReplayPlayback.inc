#if defined REPLAYPLAYBACK_INCLUDED
#endinput
#endif
#define REPLAYPLAYBACK_INCLUDED

#include "STAPlayer.inc"
#include "ReplayFrame.inc"
#include "ItemList.inc"

/**
 * @brief 用于平滑角度过渡的 tick 数量（全局常量）。
 */
static const int g_iAngleSmoothTickCount = 10;

/**
 * @brief 全局临时变量：角度平滑的参考帧角度。
 * 用于视角平滑插值的起点。
 */
static float g_fSmoothRefFrameAngles[2];

/**
 * @brief 全局临时变量：当前玩家实际视角的副本。
 * 用于视角平滑插值的计算。
 */
static float g_fSmoothCurrentAngles[3];

/**
 * @brief 全局临时变量：视角平滑插值结果的输出缓冲。
 */
static float g_fSmoothOutViewAngles[3];

/**
 * @brief 全局临时变量：上一帧的参考角度。
 * 用于自由视角过渡的角度缓存。
 */
static float g_fSmoothPrevFrameAngles[2];

/**
 * @brief 将玩家设置到指定帧的位置/角度/速度。
 * 从帧数据中读取位置/角度/速度并应用到目标客户端。
 *
 * @param source       帧数据来源的玩家。
 * @param target       要应用帧数据的目标客户端。
 * @param frame        帧索引。
 */
public void SetPlayerReplayFrame(int source, int target, int frame)
{
	any frameinfo[FRAME_Length];
	Player_GetFrame(source, frame, frameinfo);
	
	float pos[3];
	float frameangles[2];
	float velocity[3];
	GetArrayVector3(frameinfo, FRAME_PosX, pos);
	GetArrayVector2(frameinfo, FRAME_AngX, frameangles);
	GetArrayVector3(frameinfo, FRAME_VelX, velocity);
	
	float viewangles[3];
	CopyVector2ToVector3(frameangles, viewangles);
	
	TeleportEntity(target, pos, viewangles, velocity);
}

/**
 * @brief 处理倒带/快进逻辑。
 * 根据玩家的 Rewind/FastForward 按键状态调整当前播放帧。
 *
 * @param client  客户端索引。
 */
public void HandleReplayRewind(int client)
{
	int lastindex = Player_GetRecordedFramesCount(client) - 1;
	int factor = Player_GetRewindSpeed(client);
	int curframe = Player_GetRewindFrame(client);
	
	if (Player_GetHasRewindKeyDown(client))
	{
		Player_SetRewindFrame(client, curframe - factor);
	}
	
	if (Player_GetHasFastForwardKeyDown(client))
	{
		Player_SetRewindFrame(client, curframe + factor);
	}
	
	curframe = Player_GetRewindFrame(client);
	
	if (curframe < 0)
	{
		Player_SetRewindFrame(client, 0);
	}
	else if (curframe > lastindex)
	{
		Player_SetRewindFrame(client, lastindex);
	}
	
	// 显示当前帧信息
	curframe = Player_GetRewindFrame(client);
	if (lastindex > 0)
	{
		float tickinterval = GetTickInterval();
		int timeframe = curframe - Player_GetStartTimeReplayTick(client);
		if (timeframe < 0) timeframe = 0;
		
		float curtime = timeframe * tickinterval;
		char curtimebuf[64];
		FormatTimeSpan(curtimebuf, sizeof(curtimebuf), curtime);
		
		// 此处不直接输出文字，由调用方决定是否显示
	}
}

/**
 * @brief 处理自由视角线性平滑过渡（仅对真人玩家有效）。
 * 当玩家按住 IN_ZOOM 时锁定视角不动，松开后从当前视角平滑过渡到录制视角。
 *
 * @param client       客户端索引。
 * @param buttons      当前按键掩码。
 * @param frameinfo    当前播放帧数据。
 * @param viewangles   播放帧的目标视角。
 * @param pos          播放帧的目标位置。
 * @param velocity     播放帧的目标速度。
 * @param bOnlySetVel  是否仅设置速度。
 * @param fPlaybackTimeScale 播放时的 host_timescale 值。
 * @return             true 表示已处理（不继续走普通播放路径）。
 */
static bool HandleAngleSmoothTransition(int client, int buttons,
	float pos[3], float velocity[3], float fPlaybackTimeScale)
{
	bool handled = false;
	
	if (buttons & IN_ZOOM)
	{
		// 锁定视角：设置位置和速度，但不设置角度
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		DispatchKeyValueVector(client, "origin", pos);
		Player_SetAngleSmooth(client, g_iAngleSmoothTickCount);
		SetConVarFloat(FindConVar("host_timescale"), 0.08, true, true);
		handled = true;
	}
	else
	{
		int iSmooth = Player_GetAngleSmooth(client);
		if (iSmooth > 0)
		{
			// 视角平滑过渡中
			int preframeang = Player_GetRewindFrame(client) + g_iAngleSmoothTickCount;
			int frameCount = Player_GetRecordedFramesCount(client);
			if (preframeang >= frameCount)
			{
				preframeang = frameCount - 1;
			}
			
			any preframeinfoang[FRAME_Length];
			Player_GetFrame(client, preframeang, preframeinfoang);
			GetArrayVector2(preframeinfoang, FRAME_AngX, g_fSmoothPrevFrameAngles);
			
			if (iSmooth == g_iAngleSmoothTickCount)
			{
				g_fSmoothRefFrameAngles = g_fSmoothPrevFrameAngles;
				GetClientEyeAngles(client, g_fSmoothCurrentAngles);
				SetConVarFloat(FindConVar("host_timescale"), fPlaybackTimeScale, true, true);
			}
			
			float outang[2];
			outang[0] = LinearInterPolation(g_fSmoothCurrentAngles[0], g_fSmoothRefFrameAngles[0],
				g_iAngleSmoothTickCount - iSmooth, g_iAngleSmoothTickCount);
			outang[1] = LinearInterPolation(g_fSmoothCurrentAngles[1], g_fSmoothRefFrameAngles[1],
				g_iAngleSmoothTickCount - iSmooth, g_iAngleSmoothTickCount);
			
			CopyVector2ToVector3(outang, g_fSmoothOutViewAngles);
			TeleportEntity(client, NULL_VECTOR, g_fSmoothOutViewAngles, velocity);
			DispatchKeyValueVector(client, "origin", pos);
			Player_SetAngleSmooth(client, iSmooth - 1);
			handled = true;
		}
	}
	
	return handled;
}

/**
 * @brief 处理线性位置/角度平滑过渡。
 * 从起始帧位置线性插值到结束帧位置。
 *
 * @param client     客户端索引。
 * @param velocity   当前帧的速度向量。
 * @return           true 表示已应用平滑插值。
 */
static bool HandleLinearSmoothTransition(int client, float velocity[3])
{
	int linetick = Player_GetSmoothLineTickCount(client);
	int iLineSmooth = Player_GetSmoothLineDecrement(client);
	
	if (iLineSmooth == linetick)
	{
		// 初始化平滑数据
		float pos_start[3];
		float viewangles_start[3];
		GetClientAbsOrigin(client, pos_start);
		GetClientEyeAngles(client, viewangles_start);
		
		Player_SetSmoothStartPos(client, pos_start);
		Player_SetSmoothStartAngles(client, viewangles_start);
		
		any frameinfo_linesmooth[FRAME_Length];
		Player_GetFrame(client, Player_GetEndFrame(client), frameinfo_linesmooth);
		
		float pos_end[3];
		float frameangles_end[2];
		GetArrayVector3(frameinfo_linesmooth, FRAME_PosX, pos_end);
		GetArrayVector2(frameinfo_linesmooth, FRAME_AngX, frameangles_end);
		
		Player_SetSmoothEndPos(client, pos_end);
		Player_SetSmoothEndFrameAngles(client, frameangles_end);
	}
	
	if (iLineSmooth > 0)
	{
		float startPos[3], endPos[3], startAng[3], endFrameAng[2];
		Player_GetSmoothStartPos(client, startPos);
		Player_GetSmoothEndPos(client, endPos);
		Player_GetSmoothStartAngles(client, startAng);
		Player_GetSmoothEndFrameAngles(client, endFrameAng);
		
		float outpos[3], outang[2], viewangles_line[3];
		
		outpos[0] = LinearInterPolation_Pos(startPos[0], endPos[0], linetick - iLineSmooth, linetick);
		outpos[1] = LinearInterPolation_Pos(startPos[1], endPos[1], linetick - iLineSmooth, linetick);
		outpos[2] = LinearInterPolation_Pos(startPos[2], endPos[2], linetick - iLineSmooth, linetick);
		
		outang[0] = LinearInterPolation(startAng[0], endFrameAng[0], linetick - iLineSmooth, linetick);
		outang[1] = LinearInterPolation(startAng[1], endFrameAng[1], linetick - iLineSmooth, linetick);
		CopyVector2ToVector3(outang, viewangles_line);
		
		TeleportEntity(client, NULL_VECTOR, viewangles_line, velocity);
		DispatchKeyValueVector(client, "origin", outpos);
		
		Player_SetSmoothLineDecrement(client, iLineSmooth - 1);
		
		return true;
	}
	else
	{
		// 平滑结束
		Player_SetIsLinearTransition(client, false);
		return false;
	}
}

/**
 * @brief 注入播放帧的按键指令到客户端。
 * 对于真人玩家使用 ClientCommand 注入按键。
 * 将帧数据的按键信息转换为 +duck/-duck 等指令。
 *
 * @param client       客户端索引。
 * @param buttons      当前按键掩码（可修改）。
 * @param frameinfo    当前播放帧数据。
 * @param frameinfo_action 下一帧数据（用于解决1tick延迟问题）。
 * @param bOnlySetVel  是否仅设置速度（跳过部分地面移动按键）。
 */
public void InjectPlaybackButtons(int client, int& buttons, any frameinfo[FRAME_Length],
	any frameinfo_action[FRAME_Length], bool bOnlySetVel)
{
	int ibuttons = frameinfo[FRAME_Buttons];
	int ibuttonsEx = frameinfo_action[FRAME_Buttons];
	
	if (!IsFakeClient(client) || (GetClientTeam(client) == 3))
	{
		if (ibuttons & IN_JUMP) buttons |= IN_JUMP;
		else buttons &= ~IN_JUMP;
		
		if (ibuttons & IN_DUCK) ClientCommand(client, "+duck");
		else ClientCommand(client, "-duck");
		
		if (ibuttons & IN_FORWARD && GetEntityFlags(client) & FL_ONGROUND && !bOnlySetVel)
			ClientCommand(client, "+forward");
		else ClientCommand(client, "-forward");
		
		if (ibuttons & IN_BACK && GetEntityFlags(client) & FL_ONGROUND && !bOnlySetVel)
			ClientCommand(client, "+back");
		else ClientCommand(client, "-back");
		
		if (ibuttons & IN_LEFT && !bOnlySetVel)
			ClientCommand(client, "+left");
		else ClientCommand(client, "-left");
		
		if (ibuttons & IN_RIGHT && !bOnlySetVel)
			ClientCommand(client, "+right");
		else ClientCommand(client, "-right");
		
		if (ibuttons & IN_ATTACK2) ClientCommand(client, "+attack2");
		else ClientCommand(client, "-attack2");
		
		if (ibuttons & IN_RELOAD) ClientCommand(client, "+reload");
		else ClientCommand(client, "-reload");
	}
	
	// 扩展按键（下一帧）：+use 和 +attack
	if (ibuttonsEx & IN_USE) ClientCommand(client, "+use");
	else ClientCommand(client, "-use");
	
	if (ibuttonsEx & IN_ATTACK)
	{
		ClientCommand(client, "+attack");
		Player_SetAttackCounter(client, 1);
	}
	else
	{
		int attackCounter = Player_GetAttackCounter(client);
		attackCounter--;
		if (attackCounter <= 0)
		{
			ClientCommand(client, "-attack");
			attackCounter = 0;
		}
		Player_SetAttackCounter(client, attackCounter);
	}
}

/**
 * @brief 处理播放模式的 OnPlayerRunCmd 回调。
 * 包含：帧迭代、位置/角度/速度应用、按键注入、线性/视角平滑、
 * 暂停处理、播放转录制、播放结束检测。
 *
 * @param client             客户端索引。
 * @param buttons            按键掩码（可修改）。
 * @param wishvel            期望速度向量（可修改，用于爬梯）。
 * @param wishangles         期望角度。
 * @param weapon             武器实体索引。
 * @param hOnPlayTick        OnPlayTick 全局转发句柄。
 * @param bPlayWhenIncapacitated 是否在倒地时继续播放。
 * @param bPlayingToRecord   是否启用播放转录制功能。
 * @param bOnlySetVel        是否仅设置速度。
 * @param fPlaybackTimeScale 播放时的 host_timescale 值。
 * @return                   Action 值。
 */
public Action HandleReplayPlayback(int client, int& buttons, float wishvel[3], float wishangles[3],
	int& weapon, Handle hOnPlayTick, bool bPlayWhenIncapacitated, bool bPlayingToRecord,
	bool bOnlySetVel, float fPlaybackTimeScale)
{
	// 倒地检查
	if (!bPlayWhenIncapacitated)
	{
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0)
		{
			return Plugin_Continue;
		}
	}
	
	// 暂停检查
	if (Player_GetIsPauseWhilePlaying(client))
	{
		// 暂停时保持位置不动
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
		return Plugin_Continue;
	}
	
	bool normalproc = true;
	int curframe = Player_GetRewindFrame(client);
	
	any frameinfo[FRAME_Length];
	Player_GetFrame(client, curframe, frameinfo);
	
	// 下一帧数据用于按键延迟处理
	any frameinfo_action[FRAME_Length];
	Player_GetFrame(client, curframe + 1, frameinfo_action);
	
	// 提取帧数据
	float pos[3];
	float frameangles[2];
	float velocity[3];
	GetArrayVector3(frameinfo, FRAME_PosX, pos);
	GetArrayVector2(frameinfo, FRAME_AngX, frameangles);
	GetArrayVector3(frameinfo, FRAME_VelX, velocity);
	
	float viewangles[3];
	CopyVector2ToVector3(frameangles, viewangles);
	
	// =========================================================
	// StopFrame 处理：播放转录制 / 播放停止
	// =========================================================
	int stopFrame = Player_GetStopFrame(client);
	if (stopFrame > 0 && !IsFakeClient(client))
	{
		if (curframe == stopFrame && bPlayingToRecord)
		{
			// 播放转录制
			normalproc = false;
			HandleReplayRewind(client);
			TeleportEntity(client, NULL_VECTOR, viewangles, velocity);
			DispatchKeyValueVector(client, "origin", pos);
			
			int endframe = Player_GetRewindFrame(client) + 1;
			int framecount = Player_GetRecordedFramesCount(client) - 1;
			if (endframe > framecount)
			{
				endframe = framecount;
			}
			
			Player_ResizeRecordFrameList(client, endframe);
			Player_SetIsRewinding(client, true);
			Player_SetIsSegmenting(client, true);
			Player_SetHasRun(client, false);
			Player_SetPlayingReplay(client, false);
			SetEntityMoveType(client, MOVETYPE_NONE);
			Player_SetRewindFrame(client, endframe - 1);
			
			ClientCommand(client, "slot1");
			ClientCommand(client, "-duck");
			
			STR_PrintMessageToAllClients("%N的Replay已经从%d帧继续.", client, endframe);
			return Plugin_Changed;
		}
		else if (curframe == stopFrame)
		{
			// 播放到指定帧停止
			Player_ResetAllReplayState(client);
			if (IsClientInGame(client) && GetClientTeam(client) != 1)
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
			STR_PrintMessageToAllClients("%N的Replay在%d帧停止.", client, curframe);
			return Plugin_Continue;
		}
	}
	
	// =========================================================
	// 暂停（倒带/快进）处理
	// =========================================================
	if (Player_GetIsRewinding(client))
	{
		normalproc = false;
		HandleReplayRewind(client);
		TeleportEntity(client, NULL_VECTOR, viewangles, velocity);
		DispatchKeyValueVector(client, "origin", pos);
	}
	
	// =========================================================
	// 武器切换
	// =========================================================
	if (frameinfo[FRAME_WEAPON] > 0)
	{
		FakeClientCommand(client, "use %s", g_Items[frameinfo[FRAME_WEAPON]]);
	}
	
	// =========================================================
	// 按键注入
	// =========================================================
	InjectPlaybackButtons(client, buttons, frameinfo, frameinfo_action, bOnlySetVel);
	
	// =========================================================
	// 位置/角度/速度应用
	// =========================================================
	if (curframe == 0)
	{
		// 第一帧始终强制设置全部
		TeleportEntity(client, NULL_VECTOR, viewangles, velocity);
		DispatchKeyValueVector(client, "origin", pos);
	}
	else
	{
		// 线性平滑处理
		if (Player_GetIsLinearTransition(client))
		{
			if (HandleLinearSmoothTransition(client, velocity))
			{
				// 平滑已完成此帧处理
			}
			else
			{
				// 平滑结束，使用正常帧数据
				TeleportEntity(client, NULL_VECTOR, viewangles, velocity);
				DispatchKeyValueVector(client, "origin", pos);
			}
		}
		else
		{
			// 自由视角平滑过渡（仅对真人玩家）
			if (!IsFakeClient(client))
			{
				int curButtons = GetClientButtons(client);
				bool bOnlySetVelConVar = view_as<bool>(GetConVarBool(FindConVar("str_onlysetvel")));
				
				if (bOnlySetVelConVar)
				{
					// 仅设置速度模式
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
					DispatchKeyValueVector(client, "origin", pos);
					Player_SetAngleSmooth(client, g_iAngleSmoothTickCount);
				}
				else if (!HandleAngleSmoothTransition(client, curButtons, pos, velocity, fPlaybackTimeScale))
				{
					// 正常播放路径
					ApplyPlaybackPosition(client, frameinfo, viewangles, velocity, pos, buttons, wishvel);
				}
			}
			else
			{
				// Bot 直接应用
				TeleportEntity(client, NULL_VECTOR, viewangles, velocity);
				if (frameinfo[FRAME_MOVETYPE] == MOVETYPE_LADDER)
				{
					wishvel[0] = velocity[0];
					wishvel[1] = velocity[1];
					wishvel[2] = velocity[2];
				}
				DispatchKeyValueVector(client, "origin", pos);
				buttons = frameinfo[FRAME_Buttons];
			}
		}
	}
	
	// =========================================================
	// 帧推进 & 结束检测
	// =========================================================
	if (normalproc)
	{
		Player_IncrementRewindFrame(client);
		curframe = Player_GetRewindFrame(client);
		int length = Player_GetRecordedFramesCount(client);
		
		// 触发 OnPlayTick 转发
		if (hOnPlayTick != INVALID_HANDLE)
		{
			Call_StartForward(hOnPlayTick);
			Call_PushCell(client);
			Call_PushCell(curframe);
			Call_Finish();
		}
		
		char sKeyValue[128];
		Format(sKeyValue, sizeof(sKeyValue), "if (\"OnPlayTick\" in getroottable()) OnPlayTick(self, %d)", curframe);
		SetVariantString(sKeyValue);
		AcceptEntityInput(client, "RunScriptCode");
		
		// 播放结束检测
		if (curframe >= length - 2)
		{
			Player_SetRewindFrame(client, length - 1);
			Player_SetIsRewinding(client, false);
			
			Player_ResetAllReplayState(client);
			if (IsClientInGame(client) && GetClientTeam(client) != 1)
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
		}
	}
	
	return Plugin_Changed;
}

/**
 * @brief 应用播放帧的位置/角度/速度。
 * 处理爬梯模式（MOVETYPE_LADDER）的特殊逻辑。
 *
 * @param client      客户端索引。
 * @param frameinfo   当前帧数据。
 * @param viewangles  目标视角。
 * @param velocity    目标速度。
 * @param pos         目标位置。
 * @param buttons     当前帧按键掩码（可修改，用于爬梯）。
 * @param wishvel     期望速度向量（可修改，用于爬梯）。
 */
static void ApplyPlaybackPosition(int client, any frameinfo[FRAME_Length],
	float viewangles[3], float velocity[3], float pos[3],
	int& buttons, float wishvel[3])
{
	if (frameinfo[FRAME_MOVETYPE] == MOVETYPE_LADDER)
	{
		// 爬梯模式：通过 wishvel 传递速度
		buttons = frameinfo[FRAME_Buttons];
		TeleportEntity(client, NULL_VECTOR, viewangles, NULL_VECTOR);
		wishvel[0] = velocity[0];
		wishvel[1] = velocity[1];
		wishvel[2] = velocity[2];
	}
	else
	{
		TeleportEntity(client, NULL_VECTOR, viewangles, velocity);
	}
	DispatchKeyValueVector(client, "origin", pos);
}
