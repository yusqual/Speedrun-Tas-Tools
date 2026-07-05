//Squirrel
// STR 扩展函数库。完整文档见 scripting/docs/str-guide.md §6.6

//====================================================================
// ST_TriggerTeleport — 闲置玩家 → trigger 传送 → 接管回调。文档见 str-guide.md §6.6
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
