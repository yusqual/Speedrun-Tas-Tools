//Squirrel

/*
STR 扩展函数库 —— 基于 Speedrunner Tools 模组封装的工具函数。

引入方式（在 vs_st_speedrun.nut 或 map 脚本中）：
  IncludeScript("str_extensions");

依赖：
  - str_commands.nut        （STR VScript API）
  - Speedrunner Tools 模组  （ST_Idle, SpawnTrigger 等）

所有函数使用 :: 全局作用域。
*/

//====================================================================
// ST_TriggerTeleport
//
// 闲置目标玩家 → 在目标位置生成 trigger → 玩家碰到 trigger 后
// 接管玩家，输出耗时，执行回调。
//
// 参数：
//   hPlayer   — 玩家句柄
//   vecPos    — trigger 生成位置 (Vector)
//   fCallback — 回调函数 function(hPlayer, fElapsedSeconds)
//
// 示例：
//   ST_TriggerTeleport(hPlayer, Vector(1000, 2000, 100),
//       function(hPlayer, fTime) {
//           printl("Reached in " + fTime + " s");
//           ST_STR_LoadFile(hPlayer, "next.STR");
//           ST_STR(hPlayer, 1);
//       }
//   );
//====================================================================

::ST_TriggerTeleport <- function(hPlayer, vecPos, fCallback = null)
{
    if (!IsPlayer(hPlayer) || vecPos == null) return;

    ST_Idle(hPlayer, true);
    local fStartTime = Time();
    local iClient = hPlayer.GetEntityIndex();
    local sId = iClient + "_" + (Time() * 1000.0).tointeger();
    local sTrigName = "st_tp_trig_" + sId;
    local sFuncName = "ST_TrigHandler_" + sId;

    if (!("g_STrigData" in getroottable()))
        ::g_STrigData <- {};
    ::g_STrigData[sTrigName] <- {client = iClient, startTime = fStartTime, callback = fCallback};

    getroottable()[sFuncName] <- function()
    {
        local sName = self.GetName();
        if (!(sName in ::g_STrigData)) return;
        local data = ::g_STrigData[sName];

        local hPlayer = EntIndexToHScript(data.client);
        if (!IsPlayer(hPlayer)) { delete ::g_STrigData[sName]; self.Kill(); return; }

        local fElapsed = Time() - data.startTime;

        ST_Idle(hPlayer, false);
        printl(format("[STR] %.03f s", fElapsed));

        if (data.callback != null)
            data.callback(hPlayer, fElapsed);

        delete ::g_STrigData[sName];
        self.Kill();
    };

    SpawnTrigger(sTrigName, vecPos, null, null, sFuncName);
}
