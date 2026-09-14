//Squirrel
// STR 扩展函数库。完整文档见 scripting/docs/str-guide.md §6.6

//====================================================================
// SpawnWeaponEx — 在地面生成可设置上弹数、备弹数、升级的武器。
// m_iClip1 / m_upgradeBitVec 直接设在地面武器上（拾取后保留）；
// 备弹写入地面武器的 m_iExtraPrimaryAmmo——游戏为落地武器维护的备弹字段
// （L4D1 沿袭机制，武器被持有时权威值在玩家 m_iAmmo 池，丢/捡时游戏在两者间转移）：
//   1. 同类武器按 E 的总量比较（上弹+备弹）读取它，6/72 可替换手持 8/10；
//   2. 拾取时游戏原生将其转移进拾取者的 m_iAmmo 池（下标 m_iPrimaryAmmoType）；
//   3. 玩家丢枪时游戏把池中对应类型的备弹写回该字段，拾取者因此"继承"备弹。
// 升级弹药：m_upgradeBitVec 为升级类型标志，m_nUpgradedPrimaryAmmoLoaded 为
// 当前弹匣内的升级弹数；升级是整把枪的属性（丢枪前一直有效），该计数只影响
// 当前已装填的部分。指定燃烧/高爆标志时缺省把整个弹匣填满升级弹（与原版
// 拾取升级包的效果一致），需要部分装填时用 iUpgradeAmmo 显式指定。
// 注意：m_iPrimaryAmmoCount / m_iClip2 与备弹无关（实测写入被游戏忽略）。
// 文档见 str-guide.md §6.6
//
// @param sName         物品名 ("item13") 或实体类名 ("weapon_shotgun_chrome")
// @param vecPos        生成位置
// @param vecAng        生成角度 (可选)
// @param iClip         上膛弹数 m_iClip1 (可选)
// @param iReserve      备弹数，写入武器 m_iExtraPrimaryAmmo (可选；手枪等无备弹武器无效果)
// @param iUpgradeBits  m_upgradeBitVec 标志位 (可选): LASER=4, INCENDIARY=1, EXPLOSIVE=2
// @param sTarget       targetname (可选)，缺省 "ent_speedrun_item"
// @param iUpgradeAmmo  升级弹数量（弹匣内升级弹数，自动钳制到上弹数；缺省时若含
//                      燃烧/高爆标志则填满整个弹匣）(可选)
// @return              生成的武器实体
//====================================================================

::SpawnWeaponEx <- function(sName, vecPos, vecAng = null, iClip = null, iReserve = null, iUpgradeBits = null, sTarget = null, iUpgradeAmmo = null)
{
    if (vecAng == null) vecAng = Vector(0, RandomInt(0, 360), 0);
    if (sTarget == null) sTarget = "ent_speedrun_item";

    local sWeaponClass;
    if (g_STLib.Items.rawin(sName))
    {
        local sSpawnClass = g_STLib.Items.rawget(sName).cls;
        local iPos = sSpawnClass.find("_spawn");
        sWeaponClass = (iPos != null) ? sSpawnClass.slice(0, iPos) : sSpawnClass;
    }
    else
    {
        sWeaponClass = sName;
        local iPos = sWeaponClass.find("_spawn");
        if (iPos != null) sWeaponClass = sWeaponClass.slice(0, iPos);
    }

    local hWeapon = SpawnEntityFromTable(sWeaponClass,
    {
        targetname = sTarget
        origin = vecPos
        angles = vecAng
    });

    if (hWeapon != null)
    {
        if (iClip != null)
            NetProps.SetPropInt(hWeapon, "m_iClip1", iClip);
        if (iUpgradeBits != null)
            NetProps.SetPropInt(hWeapon, "m_upgradeBitVec", iUpgradeBits);
        if (iUpgradeAmmo != null || (iUpgradeBits != null && (iUpgradeBits & 3) != 0))
        {
            // 升级弹数缺省为整个弹匣（与原版拾取升级包一致），且不超过实际上弹数
            local iWant = (iUpgradeAmmo != null) ? iUpgradeAmmo : NetProps.GetPropInt(hWeapon, "m_iClip1");
            local iClipNow = NetProps.GetPropInt(hWeapon, "m_iClip1");
            if (iWant > iClipNow)
                iWant = iClipNow;
            if (iWant > 0)
                NetProps.SetPropInt(hWeapon, "m_nUpgradedPrimaryAmmoLoaded", iWant);
        }
        if (iReserve != null)
            NetProps.SetPropInt(hWeapon, "m_iExtraPrimaryAmmo", iReserve);
    }

    return hWeapon;
}

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

//====================================================================
// 【临时调试】WexDumpEnt — 打印单个武器实体的弹药相关字段。
// 用于验证 m_iExtraPrimaryAmmo 机制（丢枪/拾取前后对比）。确认后删除。
//
// @param hEnt      武器实体句柄。
// @param sTag      输出标签，用于区分调用来源。
//====================================================================

::_WexDumpEnt <- function(hEnt, sTag)
{
    if (hEnt == null || !hEnt.IsValid())
    {
        printl("[WexDump] " + sTag + ": 实体无效");
        return;
    }
    local function GetPropSafe(hEnt, sProp)
    {
        try { return NetProps.GetPropInt(hEnt, sProp); }
        catch (e) { return -999; }
    }
    local function IsHeld(hEnt)
    {
        try { return NetProps.GetPropEntity(hEnt, "m_hOwner") != null ? 1 : 0; }
        catch (e) { return -999; }
    }
    printl(format("[WexDump] %s %s name=%s held=%d clip=%d upgAmmo=%d extraAmmo=%d dropGender=%d",
        sTag, hEnt.GetClassname(), hEnt.GetName(), IsHeld(hEnt),
        GetPropSafe(hEnt, "m_iClip1"),
        GetPropSafe(hEnt, "m_nUpgradedPrimaryAmmoLoaded"),
        GetPropSafe(hEnt, "m_iExtraPrimaryAmmo"),
        GetPropSafe(hEnt, "m_DroppedByInfectedGender")));
}

//====================================================================
// 【临时调试】WexDump — 打印地图上指定类名所有武器实体的弹药字段。确认后删除。
//
// @param sClass    武器类名（如 "weapon_pumpshotgun"），缺省木喷。
//====================================================================

::_WexDump <- function(sClass = "weapon_pumpshotgun")
{
    local hEnt = null;
    while ((hEnt = Entities.FindByClassname(hEnt, sClass)) != null)
        _WexDumpEnt(hEnt, sClass);
}

//====================================================================
// 【临时调试】WexDumpAll — 对全部主武器类名依次执行 _WexDump。
// 由 weapon_drop 观察回调在丢枪后自动调用，也可手动执行：script _WexDumpAll()
//====================================================================

::_WexDumpAll <- function()
{
    printl("[WexDumpAll] ---- ----");
    local classes = ["weapon_pumpshotgun", "weapon_shotgun_chrome", "weapon_autoshotgun",
        "weapon_shotgun_spas", "weapon_smg", "weapon_smg_silenced", "weapon_rifle",
        "weapon_rifle_ak47", "weapon_rifle_desert", "weapon_rifle_sg552", "weapon_smg_mp5",
        "weapon_hunting_rifle", "weapon_sniper_military", "weapon_sniper_awp",
        "weapon_sniper_scout", "weapon_grenade_launcher", "weapon_rifle_m60"];
    foreach (s in classes)
        _WexDump(s);
}

//====================================================================
// 【临时调试】WexPoolEnt — 打印指定玩家 m_iAmmo 备弹池的全部元素。确认后删除。
//
// @param hPlayer   玩家实体句柄。
// @param sTag      输出标签，用于区分调用来源。
//====================================================================

::_WexPoolEnt <- function(hPlayer, sTag)
{
    if (hPlayer == null)
    {
        printl("[WexPool] " + sTag + ": 玩家无效");
        return;
    }
    local iSize = NetProps.GetPropArraySize(hPlayer, "m_iAmmo");
    local s = "";
    for (local i = 0; i < iSize; i++)
        s += format("%d ", NetProps.GetPropIntArray(hPlayer, "m_iAmmo", i));
    printl("[WexPool] " + sTag + " m_iAmmo[" + iSize + "]: " + s);
}

//====================================================================
// 【临时调试】WexPool — 打印指定索引玩家的备弹池（缺省 1 号玩家）。确认后删除。
//
// @param iIdx      玩家实体索引，缺省 1。
//====================================================================

::_WexPool <- function(iIdx = 1)
{
    _WexPoolEnt(PlayerInstanceFromIndex(iIdx), "idx" + iIdx);
}

//====================================================================
// 【临时调试】weapon_drop 观察回调：丢枪时打印事件字段并转储被丢武器与全地图武器，
// 用于确认游戏丢枪时把玩家池备弹写入 m_iExtraPrimaryAmmo。确认后随本表一并删除。
//====================================================================

::_WexCallbacks <-
{
    OnGameEvent_weapon_drop = function(event)
    {
        local s = "";
        foreach (k, v in event)
            s += k + "=" + v + " ";
        printl("[WexDump] weapon_drop: " + s);
        try { _WexDumpEnt(EntIndexToHScript(event.propid), "dropped-at-event"); }
        catch (e) { printl("[WexDump] dropped entity dump failed: " + e); }
        EntFire("worldspawn", "RunScriptCode", "_WexDumpAll()", 0.5);
        EntFire("worldspawn", "RunScriptCode", "_WexDumpAll()", 2.0);
    }
}

// 生成任何武器时确保丢枪观察已注册（收集/注册幂等；只收集上面的专用调试表）
if (!("_WexRegistered" in getroottable()))
{
    ::_WexRegistered <- true;
    __CollectEventCallbacks(::_WexCallbacks, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
}
