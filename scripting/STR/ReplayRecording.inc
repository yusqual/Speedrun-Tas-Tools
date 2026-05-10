#if defined REPLAYRECORDING_INCLUDED
#endinput
#endif
#define REPLAYRECORDING_INCLUDED

#include "STAPlayer.inc"
#include "ReplayFrame.inc"
#include "ItemList.inc"

/**
 * @brief 将武器实体类名映射为 g_Items 中的序号。
 *
 * @param weapon  武器实体索引，若 <= 0 则返回 0。
 * @return        映射后的序号（0 表示空/未知）。
 */
static int WeaponToItemIndex(int weapon)
{
	if (weapon <= 0)
	{
		return 0;
	}
	
	char sClass[64];
	GetEntityClassname(weapon, sClass, sizeof(sClass));
	
	for (int i = 1; i < ITEMS_COUNT; i++)
	{
		if (StrEqual(sClass, g_Items[i]))
		{
			return i;
		}
	}
	
	return 0;
}

/**
 * @brief 处理录制模式的 OnPlayerRunCmd 回调。
 * 在玩家处于录制状态（段录制中）且未暂停/倒带时调用。
 * 采集玩家每一帧的位置、角度、速度、按键、武器等信息并存入帧数组。
 *
 * @param client      客户端索引。
 * @param buttons     当前帧的按键掩码（可修改）。
 * @param impulse     脉冲值。
 * @param wishvel     期望速度向量。
 * @param wishangles  期望角度。
 * @param weapon      当前武器实体索引。
 * @param hOnRecordTick  OnRecordTick 全局转发句柄。
 * @return            Action 值，通常为 Plugin_Changed。
 */
public Action HandleReplayRecording(int client, int& buttons, int& impulse, float wishvel[3], float wishangles[3], int& weapon, Handle hOnRecordTick)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	float viewangles[3];
	GetClientEyeAngles(client, viewangles);
	
	float frameangles[2];
	CopyVector3ToVector2(viewangles, frameangles);
	
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	
	any frameinfo[FRAME_Length];
	frameinfo[FRAME_Buttons] = buttons | Player_GetIdleFlags(client);
	frameinfo[FRAME_FFLAG] = GetEntityFlags(client);
	frameinfo[FRAME_MOVETYPE] = GetEntityMoveType(client);
	frameinfo[FRAME_ACTIVESLOT] = GetActiveSlot(client);
	
	CopyVector3ToArray(pos, frameinfo, FRAME_PosX);
	CopyVector2ToArray(frameangles, frameinfo, FRAME_AngX);
	CopyVector3ToArray(velocity, frameinfo, FRAME_VelX);
	
	// 重置闲置标记
	if (Player_GetIdleFlags(client) > 0)
	{
		Player_ClearIdleFlags(client);
	}
	
	// 武器映射
	frameinfo[FRAME_WEAPON] = WeaponToItemIndex(weapon);
	
	Player_PushFrame(client, frameinfo);
	
	int curframe = Player_GetRewindFrame(client);
	
	// 触发 OnRecordTick 转发
	if (hOnRecordTick != INVALID_HANDLE)
	{
		Call_StartForward(hOnRecordTick);
		Call_PushCell(client);
		Call_PushCell(curframe);
		Call_Finish();
	}
	
	// VScript 回调
	char sKeyValue[128];
	Format(sKeyValue, sizeof(sKeyValue), "if (\"OnRecordTick\" in getroottable()) OnRecordTick(self, %d)", curframe);
	SetVariantString(sKeyValue);
	AcceptEntityInput(client, "RunScriptCode");
	
	// 更新当前帧指针到最新
	Player_SetRewindFrame(client, Player_GetRecordedFramesCount(client) - 1);
	
	return Plugin_Changed;
}

/**
 * @brief 处理录制倒带模式的 OnPlayerRunCmd 回调。
 * 在录制过程中暂停/倒带时调用，允许玩家回放已录制的帧。
 *
 * @param client     客户端索引。
 * @param buttons    按键掩码。
 * @param wishvel    期望速度向量。
 * @param wishangles 期望角度。
 * @param weapon     武器实体索引。
 * @return           Action 值，通常为 Plugin_Handled。
 */
public Action HandleReplayRecordingRewind(int client, int& buttons, float wishvel[3], float wishangles[3], int& weapon)
{
	HandleReplayRewind(client);
	SetPlayerReplayFrame(client, client, Player_GetRewindFrame(client));
	return Plugin_Handled;
}

/**
 * @brief 获取玩家当前激活的武器槽位编号。
 *
 * @param client  客户端索引。
 * @return        槽位编号：1~5 对应 slot0~slot4，-1 表示未知。
 */
int GetActiveSlot(int client)
{
	int Slot0 = GetPlayerWeaponSlot(client, 0);
	int Slot1 = GetPlayerWeaponSlot(client, 1);
	int Slot2 = GetPlayerWeaponSlot(client, 2);
	int Slot3 = GetPlayerWeaponSlot(client, 3);
	int Slot4 = GetPlayerWeaponSlot(client, 4);
	int aWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (aWeapon == Slot0)
		return 1;
	else if (aWeapon == Slot1)
		return 2;
	else if (aWeapon == Slot2)
		return 3;
	else if (aWeapon == Slot3)
		return 4;
	else if (aWeapon == Slot4)
		return 5;
	else
		return -1;
}
