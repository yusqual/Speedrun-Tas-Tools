//Squirrel
// STR 扩展函数库。完整文档见 scripting/docs/str-guide.md §6.6

//====================================================================
// 武器备弹偏移表 (m_iAmmo 数组字节偏移)，用于拾取后 SetAmmo / NetProps.SetPropInt
// 值来源于 sm_speedrunner_tools.sp OFFSET_* 宏定义

g_STLib.WeaponAmmoOffset <-
{
    weapon_rifle = 12
    weapon_rifle_ak47 = 12
    weapon_rifle_desert = 12
    weapon_smg = 20
    weapon_smg_silenced = 20
    weapon_shotgun_chrome = 28
    weapon_pumpshotgun = 28
    weapon_autoshotgun = 32
    weapon_shotgun_spas = 32
    weapon_hunting_rifle = 36
    weapon_sniper_military = 40
    weapon_grenade_launcher = 68
}

//====================================================================
// SpawnWeaponEx — 在地面生成可设置上膛弹数、备弹数、升级的武器。
// m_iClip1 / m_upgradeBitVec 直接设在地面武器上（拾取后保留），
// 备弹通过 player_use 事件 hook（targetid 匹配武器 entindex）在拾取后设置。
// 文档见 str-guide.md §6.6
//
// @param sName         物品名 ("item13") 或实体类名 ("weapon_shotgun_chrome")
// @param vecPos        生成位置
// @param vecAng        生成角度 (可选)
// @param iClip         上膛弹数 m_iClip1 (可选)
// @param iReserve      备弹数，通过 sm_setammo 设置 (可选)
// @param iUpgradeBits  m_upgradeBitVec 标志位 (可选): LASER=4, INCENDIARY=1, EXPLOSIVE=2
// @param sTarget       targetname (可选)
// @return              生成的武器实体
//====================================================================

::SpawnWeaponEx <- function(sName, vecPos, vecAng = null, iClip = null, iReserve = null, iUpgradeBits = null, sTarget = null)
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
        if (iReserve != null)
        {
            if (!("_weaponExData" in getroottable()))
                ::_weaponExData <- {};
            ::_weaponExData[hWeapon.GetEntityIndex().tostring()] <-
                {reserve = iReserve, weaponClass = sWeaponClass, clip = iClip};

            if (!("_weaponExListener" in getroottable()))
            {
                ::_weaponExListener <- true;
                ::OnGameEvent_player_use <- function(event)
                {
                    local sTargetId = event.targetid.tostring();
                    if (!(sTargetId in ::_weaponExData)) return;
                    local data = ::_weaponExData[sTargetId];
                    delete ::_weaponExData[sTargetId];

                    local hPlayer = GetPlayerFromUserID(event.userid);
                    if (hPlayer == null) return;

                    local iSlot = (data.weaponClass.find("pistol") != null) ? 1 : 0;
                    local iClip = data.clip != null ? data.clip : 0;
                    SetAmmo(hPlayer, iSlot, iClip, data.reserve);
                };
                __CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
            }
        }
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
