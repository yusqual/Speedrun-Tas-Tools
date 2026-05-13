# ST Squirrel 函数参考

**版本**: 5.5 (VScript) / 1.4.20 (SourceMod 主插件)  
**作者**: noa1mbot  
**说明**: Speedrunner Tools 提供的所有全局 Squirrel 函数完整参考。

---

## 目录

1. [核心全局变量](#1-核心全局变量)
2. [物品与实体生成](#2-物品与实体生成)
3. [物品管理](#3-物品管理)
4. [玩家控制](#4-玩家控制)
5. [地图与导演控制](#5-地图与导演控制)
6. [AutoFire 系统](#6-autofire-系统)
7. [计时器与 HUD](#7-计时器与-hud)
8. [工具函数](#8-工具函数)
9. [数学与辅助函数](#9-数学与辅助函数)
10. [SM 命令 VScript 封装](#10-sm-命令-vscript-封装)
11. [调试函数](#11-调试函数)

---

## 1. 核心全局变量

### 1.1 `g_ST`

全局配置和运行时状态表。定义在 `vs_st_ems.nut:60-87`。

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `timer_value` | float | 3.0 | 倒计时秒数 |
| `event` | string | "0" | 自定义事件数据 |
| `hud` | bool | true | HUD 可见性 |
| `falldmg` | bool | false | 坠落伤害报告 |
| `mode` | int | 1 | 游戏模式 (0=Nerd, 1=RTA, 2=SP) |
| `full_legit` | bool | false | Full Legit 模式 |
| `bhop` | bool | true | 全局 AutoBhop |
| `bhop_local` | bool | false | 本地 Bhop |
| `unpatch` | bool | false | Unpatch 模式 |
| `rd` | bool | false | RocketDude 模式 |
| `restart` | bool | false | 是否正在重启 |
| `var_fast_update` | bool | false | 快速 HUD 更新 |
| `var_bhoppers` | array | 33×true | 每个玩家的 Bhop 开关 |
| `tick` | int | -1 | 当前游戏 tick |
| `var_stats_fAvgSpeed` | float | 0.0 | 平均速度累计 |
| `var_stats_fMaxSpeed` | float | 0.0 | 最大速度 |
| `var_stats_fDist` | float | 0.0 | 总距离 |
| `var_stats_iJumps` | int | 0 | 跳跃数 |
| `var_stats_iKills` | int | 0 | 击杀数 |

持久化保存于 `ems/st_config/st_data.txt`。

### 1.2 `g_RTA`

RTA 模式计时数据表。定义在 `vs_st_ems.nut:88-97`。

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `time` | float | 0.0 | 当前累积时间 |
| `time_livesplit` | float | 0.0 | LiveSplit 兼容时间 |
| `time_igt` | float | 0.0 | IGT 游戏内时间 |
| `time_real` | int | 0 | Unix 时间戳 |
| `difficulty` | string | 0 | 难度 |
| `maps` | table | {} | 每关分段时间 |
| `stats` | table | {...} | 统计数据 |

### 1.3 `g_STLib`

ST API 核心库表。定义在 `speedrunner_tools.nut:7-56`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `g_STLib.Items` | table | 物品定义表 (item0~item41) |
| `g_STLib.Funcs` | table | 核心功能函数 |
| `g_STLib.Vars` | table | 运行时变量 (HUD, 时间等) |

---

## 2. 物品与实体生成

### 2.1 `SpawnItem(sName, vecPos, vecAng, iCount, sTarget, fRadius)`

在指定位置生成物品。

**定义**: `speedrunner_tools.nut:74-103`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sName` | string | — | 物品名称 (item0~item41) |
| `vecPos` | Vector | — | 生成位置 |
| `vecAng` | Vector | null → `Vector()` | 生成角度 |
| `iCount` | int | null → 1 | 数量 |
| `sTarget` | string | null → `"ent_speedrun_item"` | 物品 targetname |
| `fRadius` | float | 0 | 清除半径 (若 >0 则先移除范围内同名物品) |

**返回值**: 生成的 entity handle。

**示例**:
```lua
SpawnItem("item4", Vector(100, 200, 50));               // 生成手枪
SpawnItem("item9", Vector(100, 200, 50), Vector(0, 90, 0), 3); // 3 个土制
SpawnItem("item38", Vector(...), null, 1, "my_katana");  // 生成名为 my_katana 的武士刀
```

物品表见 speedrunner-tools-guide.md 的 7.3 节。

### 2.2 `SpawnZombie(sName, vecPos, idle)`

简易生成特感/普通感染者。

**定义**: `speedrunner_tools.nut:108-152`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sName` | string | — | 僵尸类型 |
| `vecPos` | Vector | null | 生成位置 |
| `idle` | bool | false | 是否闲置 (不攻击) |

**sName 可选值**: `"smoker"`, `"hunter"`, `"boomer"`, `"jockey"`, `"charger"`, `"spitter"`, `"tank"`, `"witch"`, `"witch_bride"`, `"infected"`, `"mob"`

**返回值**: 生成的 entity handle，失败返回 null。

**示例**:
```lua
SpawnZombie("tank", Vector(100, 200, 50));              // 生成 Tank
SpawnZombie("hunter", Vector(...), true);                // 生成闲置 Hunter
SpawnZombie("infected");                                 // 生成普通感染者
```

### 2.3 `SpawnZombieEx(sName, vecPos, vecAng, AttackOnSpawn, spawnTime)`

精确生成特感/普通感染者 (使用 commentary_zombie_spawner)。

**定义**: `speedrunner_tools.nut:157-181`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sName` | string | — | 僵尸类型或 common 模型名 |
| `vecPos` | Vector | — | 生成位置 |
| `vecAng` | Vector | null → 随机 Yaw | 生成角度 |
| `AttackOnSpawn` | bool | false | 是否立刻攻击 (Tank/Spitter 专用) |
| `spawnTime` | float | 0.0 | 生成延迟秒数 |

**特殊说明**:
- `sName = "infected"` 时，随机从 5 种 common 模型中选择
- `sName = "tank"` 或 `"spitter"` 时，会设置 `cm_AggressiveSpecials`

**示例**:
```lua
SpawnZombieEx("tank", Vector(...), Vector(0, 180, 0), true);   // 生成面向 180° 的 Tank
SpawnZombieEx("spitter", Vector(...), null, true, 1.0);         // 1 秒后生成 Spitter
SpawnZombieEx("infected", Vector(...));                          // 生成随机 common
```

### 2.4 `SpawnZombieForCB(vecPos, vecAng, startTime, hPlayer, bNotSolid, sName)`

生成用于 Commonboost 的僵尸。

**定义**: `speedrunner_tools.nut:186-249`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vecPos` | Vector | — | 生成位置 |
| `vecAng` | Vector | null → 随机 Yaw | 生成角度 |
| `startTime` | float | 0 | 开始计时时间 |
| `hPlayer` | entity | null | 目标玩家 |
| `bNotSolid` | bool | false | 是否非实体 |
| `sName` | string | `"ent_zombie_for_cb"` | 僵尸 targetname |

**返回值**: 生成的 infected entity handle。

该函数会注册 `OnGameEvent_weapon_fire` 事件监听。当 `startTime` 和 `hPlayer` 提供时，僵尸会在指定时间后朝玩家移动。

### 2.5 `SpawnCommon(sName, vecPos, vecAng, flags)`

生成普通感染者 (支持堕落幸存者)。

**定义**: `speedrunner_tools.nut:255-343`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sName` | string | null | common 模型名 (null=随机堕落, false=随机 CEDA) |
| `vecPos` | Vector | null | 生成位置 |
| `vecAng` | Vector | null → 随机 Yaw | 生成角度 |
| `flags` | int | 1 | FallenFlags 组合值 |

**flags 值**:
| 值 | 常量 | 说明 |
|----|------|------|
| 1 | FALLEN_VJAR_OR_MOLOTOV | 携带胆汁/燃烧瓶 |
| 2 | FALLEN_PIPE | 携带土制 |
| 4 | FALLEN_PILLS | 携带药丸 |
| 8 | FALLEN_MEDKIT | 携带医疗包 |
| 16 | FALLEN_SIT | 坐姿 |
| 32 | FALLEN_LYING | 躺姿 |

**示例**:
```lua
SpawnCommon("common_male_fallen_survivor", Vector(...));           // 堕落幸存者
SpawnCommon("common_male_ceda", Vector(...), Vector(0, 90, 0));   // 指定角度
SpawnCommon(null, Vector(...), null, FALLEN_SIT | FALLEN_PILLS);  // 坐姿携带药丸
```

### 2.6 `SpawnTrigger(sName, vecPos, vecMaxs, vecMins, sFunc, iType, output, sClass)`

生成 Trigger 实体。

**定义**: `speedrunner_tools.nut:348-368`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sName` | string | — | trigger targetname |
| `vecPos` | Vector | — | 中心位置 |
| `vecMaxs` | Vector | `Vector(64, 64, 128)` | 最大偏移 |
| `vecMins` | Vector | `Vector(-64, -64, 0)` | 最小偏移 |
| `sFunc` | string | `"OnEntityOutput"` | 触发时调用的回调函数名 |
| `iType` | int | TR_CLIENTS (1) | spawnflags |
| `output` | string | `"OnStartTouch"` | 触发的 output 名 (逗号分隔多个) |
| `sClass` | string | `"trigger_multiple"` | trigger 类名 |

**返回值**: trigger entity handle。

**示例**:
```lua
SpawnTrigger("area1", Vector(0, 0, 0), Vector(100, 100, 200), Vector(-100, -100, 0));
SpawnTrigger("finish", Vector(...), null, null, "OnFinish", TR_CLIENTS, "OnStartTouch,OnEndTouch");
```

---

## 3. 物品管理

### 3.1 `RemoveItem(sName)`

移除所有匹配的生成物品。

**定义**: `speedrunner_tools.nut:373-392`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sName` | string | null | 物品名称 (null=移除全部) |

**返回值**: 移除的物品数量。

```lua
RemoveItem("item9");    // 移除所有土制炸弹
RemoveItem();           // 移除地图上所有 ST 物品
```

### 3.2 `RemoveItemEx(vecPos, fRadius)`

移除指定半径内的所有物品和武器。

**定义**: `speedrunner_tools.nut:397-421`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vecPos` | Vector | — | 中心位置 |
| `fRadius` | float | 5.0 | 搜索半径 |

**返回值**: 移除的物品数量。

### 3.3 `RemoveSlot(hPlayer, slot)`

移除指定玩家的装备槽物品。

**定义**: `speedrunner_tools.nut:426-433`

| 参数 | 类型 | 说明 |
|------|------|------|
| `hPlayer` | entity | 玩家 handle |
| `slot` | int | 槽位 (0=主武器, 1=副武器, 2=药丸, 3=投掷物等) |

```lua
RemoveSlot(hPlayer, 0);   // 移除主武器
RemoveSlot(hPlayer, 2);   // 移除药丸/肾上腺素
```

### 3.4 `RemoveCI()`

移除所有普通感染者 (infected)。

**定义**: `speedrunner_tools.nut:438-445`

```lua
RemoveCI();   // 清空所有 common
```

---

## 4. 玩家控制

### 4.1 `ST_Idle(hPlayer, bMode)`

让玩家闲置或接管 Bot。

**定义**: `sm_commands.nut:143-147`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity | — | 玩家 handle |
| `bMode` | bool | false | false=闲置, true=接管 |

```lua
ST_Idle(hPlayer);          // 闲置当前玩家
ST_Idle(hPlayer, true);    // 接管 Bot
```

### 4.2 `ST_PlayerReplace(hPlayer, hPlayer2)`

交换两个玩家的角色控制权。

**定义**: `sm_commands.nut:152-156`

| 参数 | 类型 | 说明 |
|------|------|------|
| `hPlayer` | entity | 玩家 1 |
| `hPlayer2` | entity | 玩家 2 |

```lua
ST_PlayerReplace(hPlayer1, hPlayer2);
```

### 4.3 `PlayerKill(hPlayer)`

击杀指定玩家。

**定义**: `speedrunner_tools.nut:1025-1033`

| 参数 | 类型 | 说明 |
|------|------|------|
| `hPlayer` | entity | 目标玩家 |

```lua
PlayerKill(hPlayer);
```

### 4.4 `PlayerKillFromWeapon(hPlayer, hAttacker, iShots, bWaitForWeaponReady, fTime)`

使用霰弹枪武器击杀玩家 (用于团队击杀)。

**定义**: `speedrunner_tools.nut:1038-1164`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity | — | 被击杀者 |
| `hAttacker` | entity | — | 攻击者 |
| `iShots` | int | null → 4 | 射击次数 |
| `bWaitForWeaponReady` | bool | false | 等待武器就绪 |
| `fTime` | float | 1.0 | 等待时间 |

**支持武器**: `weapon_pumpshotgun`, `weapon_shotgun_chrome`, `weapon_autoshotgun`, `weapon_shotgun_spas`

**需要难度**: `Impossible` (专家)

```lua
PlayerKillFromWeapon(hPlayer, hAttacker, 2);   // 2 发 shotgun 击杀队友
```

### 4.5 `PlayerGod(hPlayer, bGod)`

设置玩家无敌状态。

**定义**: `speedrunner_tools.nut:1169-1174`

| 参数 | 类型 | 说明 |
|------|------|------|
| `hPlayer` | entity | 玩家 handle |
| `bGod` | bool | true=无敌, false=取消无敌 |

### 4.6 `ST_MR(hPlayer, eMode, sFileName, bNoTeleport)`

控制 Movement Reader 录制/回放。

**定义**: `sm_commands.nut:161-170`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity | null → 玩家 1 | 目标玩家 |
| `eMode` | int | 0 | 0=录制, 1=回放, 2=default 回放, 3=分割 |
| `sFileName` | string | null → `"default"` | 文件名 |
| `bNoTeleport` | bool | false | 不回传起始位置 |

```lua
ST_MR(hPlayer, 0, "m1_nick");     // 录制到 m1_nick.txt
ST_MR(hPlayer, 1, "m1_nick");     // 回放 m1_nick.txt
ST_MR(hPlayer, 2);                 // 回放 default.txt
ST_MR(hPlayer, 3);                 // 分割
```

### 4.7 `ST_MRStop(hPlayer)`

停止 Movement Reader。

**定义**: `sm_commands.nut:175-183`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity | null | 指定玩家 (null=停止所有) |

```lua
ST_MRStop();            // 停止所有玩家的 MR
ST_MRStop(hPlayer);     // 停止指定玩家的 MR
```

---

## 5. 地图与导演控制

### 5.1 `DirectorStop(bMode)`

控制导演系统。

**定义**: `speedrunner_tools.nut:450-477`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `bMode` | bool | false | false=禁用导演, true=恢复导演 |

**禁用时** (`false`):
- `director_no_bosses` = 1, `director_no_mobs` = 1, `director_no_specials` = 1
- `z_common_limit` = 0
- 移除所有现存感染者

**恢复时** (`true`):
- 恢复默认导演参数

```lua
DirectorStop();          // 禁用导演系统 (清除所有感染者)
DirectorStop(true);      // 恢复导演系统
```

### 5.2 `AutoOpen(bValue)`

自动开门 (安全门)。

**定义**: `speedrunner_tools.nut:482-514`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `bValue` | bool | false | true=开门一次, false=持续自动开门 |

```lua
AutoOpen(true);          // 自动打开最近的安全门
AutoOpen(false);         // 持续自动开门 (每 0.6 秒检测)
```

### 5.3 `ScriptedTP(hPlayer, hLeader, fTime, bStuckTeleport, eMode)`

脚本传送玩家。

**定义**: `speedrunner_tools.nut:897-945`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity | — | 被传送的玩家 |
| `hLeader` | entity | — | 目标玩家 (bStuckTeleport 时可为 null) |
| `fTime` | float | 6.1 | 延迟秒数 |
| `bStuckTeleport` | bool | false | 是否卡住传送 (自动找最近队友) |
| `eMode` | int | 0 | 0=传送, 1=Bot 跟随, 2=远距离跟随 |

```lua
ScriptedTP(hPlayer, hLeader, 5.0);              // 5 秒后将 hPlayer 传到 hLeader 位置
ScriptedTP(hPlayer, null, 3.0, true);            // 3 秒后自动卡住传送
ScriptedTP(hPlayer, hLeader, 0, false, 0);       // 立即传送
```

### 5.4 `ScriptedShots(hPlayer, fDistance)`

自动射击普通感染者。

**定义**: `speedrunner_tools.nut:950-1020`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity | — | 玩家 handle |
| `fDistance` | float | 1000 | 射击距离 (0=停止自动射击) |

```lua
ScriptedShots(hPlayer, 800);     // 开始自动射击半径 800 内的 common
ScriptedShots(hPlayer, 0);       // 停止自动射击
```

### 5.5 `NavMark(vecPos, flags)`

标记 NAV 区域。

**定义**: `utils.nut:937-948`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vecPos` | Vector | — | 标记位置 |
| `flags` | int | NAV_EMPTY (2) | NAV 属性标记 |

**flags 值**: `NAV_EMPTY`, `NAV_BATTLESTATION`, `NAV_FINALE`, `NAV_PLAYER_START`, `NAV_CHECKPOINT`, `NAV_NO_MOBS` 等。

```lua
NavMark(Vector(...));                       // 普通 NAV 标记
NavMark(Vector(...), NAV_CHECKPOINT);       // checkpoint 标记
```

---

## 6. AutoFire 系统

### 6.1 `AutoFire(hPlayer, vecAng, vecPos, bLoop, bUp, fRadius, hClient, delayTime, data, method3D, vecVel)`

榴弹发射器 Boost (AF1)。

**定义**: `speedrunner_tools.nut:519-616`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity/string | — | 发射玩家 |
| `vecAng` | Vector | null | 传送视角角度 |
| `vecPos` | Vector | null | 传送位置 |
| `bLoop` | bool | null | 是否循环攻击 |
| `bUp` | bool | null | 是否向上 (不蹲下) |
| `fRadius` | float | null → 25/61 | Boost 触发半径 |
| `hClient` | entity | null | 指定触发玩家 (null=任意人类) |
| `delayTime` | float | null → 0.0 | 延迟秒数 |
| `data` | int | null → 0 | 自定义数据 (传给 OnAutoFired) |
| `method3D` | bool | null | 使用 3D 距离 |
| `vecVel` | Vector | null | 榴弹速度向量 |

**回调解发**: `OnAutoFired(hPlayer, data)` 和 `OnAutoFired_Post(hPlayer, hClient, data)`

```lua
AutoFire(hPlayer, Vector(0, 90, 0), Vector(...), false, true, 30);
```

### 6.2 `AutoFire2(hPlayer, vecAng, vecPos, bLoop, bUp, fRadius, hClient, delayTime, data, method3D, bScripted)`

胆汁/投掷物 Boost (AF2)。

**定义**: `speedrunner_tools.nut:621-755`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `bScripted` | bool | null | 脚本模式 (记录向量) |

其余参数同 AutoFire。`fRadius` 默认 70。

```lua
AutoFire2(hPlayer, Vector(0, 180, 0), Vector(...));
```

### 6.3 `AutoFire3(hPlayer, aPlayers, fPitch, sWeapon, bScripted, data)`

Pipe/火瓶团队 Boost (AF3)。

**定义**: `speedrunner_tools.nut:760-882`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity/string | — | 投掷玩家 |
| `aPlayers` | array/entity | — | 要 Boost 的玩家数组 |
| `fPitch` | float | null → 2.0 | 视角俯仰 |
| `sWeapon` | string | null | 武器限制 (pipe_bomb/molotov) |
| `bScripted` | bool | null | 脚本模式 |
| `data` | int | 0 | 自定义数据 |

**注册方式**: 通过 `OnGameEvent_weapon_fire` 事件监听。

```lua
AutoFire3(hPlayer, [hPlayer2, hPlayer3], 2.0, "pipe_bomb");
```

### 6.4 `AFStop()`

停止所有 AutoFire。

**定义**: `speedrunner_tools.nut:887-892`

```lua
AFStop();   // 停止 AF1, AF2, AF3
```

---

## 7. 计时器与 HUD

### 7.1 `SpeedrunStart(isHUD)`

启动或停止计时器。

**定义**: `vs_st_ems.nut:947-957`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `isHUD` | bool | true | true=启动并显示 HUD, false=停止计时 |

```lua
SpeedrunStart();         // 启动计时
SpeedrunStart(false);    // 停止计时
```

### 7.2 `SpeedrunRestart(bAllowFastRestarts)`

重启速通关卡。

**定义**: `vs_st_ems.nut:897-945`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `bAllowFastRestarts` | bool | false | false=投票换图重启, true=快速 RestartGame |

```lua
SpeedrunRestart();           // 标准重启
SpeedrunRestart(true);       // 快速重启 (保留装备)
```

### 7.3 `Timer(value)`

三段式倒计时系统。

**定义**: `vs_st_ems.nut:1427-1475` (g_STLib.Funcs.Timer)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `value` | int | 3 | 3=开始倒计时, 2=倒数 1, 1=倒数 2, 0=结束冻结并调用 Inventory |

```lua
Timer();        // 使用 g_ST.timer_value (默认 3 秒)
```

倒计时流程: `3 → 2 → 1 → Inventory() / Inventory2() → SpeedrunStart()`

### 7.4 `HUDLoad(value)`

加载 HUD 计时器。

**定义**: `vs_st_ems.nut:1010-1141` (g_STLib.Funcs.HUDLoad)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `value` | float | 0.0 | 初始时间值 |

```lua
HUDLoad();          // 从 0 开始
HUDLoad(30.5);      // 从 30.5 秒开始
HUDLoad(g_RTA.time); // 接着上次 RTA 时间
```

### 7.5 `PrintTime()`

打印当前计时结果到控制台 (含完整统计信息)。

**定义**: `vs_st_ems.nut:959-1008` (g_STLib.Funcs.PrintTime)

```lua
g_STLib.Funcs.PrintTime();
```

### 7.6 `CPTime(sValue, hPlayer)`

打印带时间戳的消息到聊天框。

**定义**: `debug.nut:11-15`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sValue` | string | null | 消息文本 |
| `hPlayer` | entity | null | 目标玩家 (null=所有人) |

```
CPTime("Jump");       // 输出 "Jump 123.456"
CPTime("Checkpoint"); // 输出 "Checkpoint 234.567"
```

### 7.7 `CPSetTime(fValue)`

设置当前时间基准。

**定义**: `debug.nut:20-23`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `fValue` | float | 0 | 新的时间值 |

```lua
CPSetTime(0);        // 重置计时器为 0
CPSetTime(10.5);     // 设置为 10.5 秒
```

### 7.8 `CPGetTime()`

获取当前经过时间。

**定义**: `debug.nut:28-31`

**返回值**: float — 从 `g_STLib.Vars.time` 到现在的秒数。

```lua
local t = CPGetTime();
```

---

## 8. 工具函数

### 8.1 `TeleportEntity(hEntity, vecPos, vecAng, vecVel, bOriginKV)`

传送实体到指定位置。

**定义**: `utils.nut:860-873`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hEntity` | entity | — | 目标实体 |
| `vecPos` | Vector | null | 位置 (null=不变) |
| `vecAng` | Vector | null | 角度 (null=不变) |
| `vecVel` | Vector | null | 速度 (null=不变) |
| `bOriginKV` | bool | false | 是否用 KV 方式设置原点 |

```lua
TeleportEntity(hPlayer, Vector(100, 200, 50), Vector(30, 180, 0));
```

### 8.2 `GetPicker(hPlayer, tr_len, tr_mask)`

获取准星指向的实体。

**定义**: `utils.nut:451-469`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity | null → 玩家 1 | 玩家 |
| `tr_len` | float | MAX_TRACE_LENGTH | 追踪距离 |
| `tr_mask` | int | TRACE_MASK_VISIBLE_AND_NPCS | 追踪掩码 |

**返回值**: entity handle 或 null。

```lua
local hEnt = GetPicker(hPlayer);
```

### 8.3 `GetPickerPos(hPlayer, tr_len, tr_mask)`

获取准星指向的位置。

**定义**: `utils.nut:474-487`

**返回值**: Vector — 射线击中的坐标。

```lua
local vecPos = GetPickerPos(hPlayer);
```

### 8.4 `GetPlayer(model, checkObs)`

查找指定角色的生还者。

**定义**: `utils.nut:492-503`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `model` | int | null | 角色索引 (MDL_NI=0, MDL_RO=1 等) |
| `checkObs` | bool | false | 是否包括观察者 |

**返回值**: entity handle 或 null。

```lua
GetPlayer(MDL_NI);     // 找 Nick
GetPlayer(MDL_CO);     // 找 Coach
GetPlayer();           // 找任意生还者
```

### 8.5 `GetOwner(client)`

获取 Bot 的"所有者"(使其闲置的人类玩家)。

**定义**: `utils.nut:440-446`

| 参数 | 类型 | 说明 |
|------|------|------|
| `client` | entity/int/string | Bot 实体/索引/名称 |

### 8.6 `GetDistance(hEntity, hEntity2)`

计算两个实体间的距离。

**定义**: `utils.nut:1176-1178`

**返回值**: float — 3D 距离。

### 8.7 `GetSpeed(hPlayer)`

获取玩家速度。

**定义**: `utils.nut:1180-1182`

**返回值**: float — 速率 (标量长度)。

### 8.8 `GetDisplayTime(value, sValue)`

将秒数转换为分:秒格式。

**定义**: `utils.nut:537-543`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `value` | float | — | 秒数 |
| `sValue` | string | `":"` | 分隔符 |

**返回值**: string — 格式化的时间字符串。

```lua
GetDisplayTime(83.456);     // "1:23"
```

### 8.9 `GetEpoch()`

获取当前 Unix 时间戳。

**定义**: `utils.nut:548-557`

### 8.10 `GetDate(unix)`

获取日期时间信息。

**定义**: `utils.nut:599-632`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `unix` | int | null | Unix 时间戳 (null=当前时间) |

**返回值**: table — 包含 `time`, `time_full`, `date`, `timestamp`, `timestamp2`, `timestamp3`。

```lua
local d = GetDate();
printl(d.timestamp);    // "13/05/2026 @ 15:00:00"
```

### 8.11 `IsPlayer(hPlayer)`

检查是否为有效的玩家实体。

**定义**: `utils.nut:704-708`

**返回值**: bool。

### 8.12 `IsFakeClient(hPlayer)`

检查是否为假客户端 (sm_fake 创建的)。

**定义**: `utils.nut:666-669`

**返回值**: bool。

### 8.13 `Ent(entity)`

统一化实体查找函数。

**定义**: `utils.nut:773-779`

| 参数 | 类型 | 说明 |
|------|------|------|
| `entity` | instance/int/string | 实体/索引/名称 |

**返回值**: entity handle 或 null。

```lua
Ent(1);               // 索引 1
Ent("!nick");         // 名称查找
Ent(hPlayer);         // 有效性检查
```

### 8.14 `EmitSound(vecPos, sSound, iRadius)`

在指定位置播放音效。

**定义**: `utils.nut:784-798`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vecPos` | Vector | — | 音效位置 |
| `sSound` | string | — | 音效名 |
| `iRadius` | int | 3000 | 传播半径 |

```lua
EmitSound(Vector(...), "Shotgun.Fire");
```

### 8.15 `EmitSoundEx(hEntity, sndName, sndRadius, flags)`

在实体上播放音效 (支持跟随)。

**定义**: `utils.nut:815-855`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hEntity` | entity | — | 音效源实体 (null=对所有人类播放) |
| `sndName` | string | — | 音效名 |
| `sndRadius` | int | 5000 | 半径 |
| `flags` | int | 0 | SND_* 标记 |

```lua
EmitSoundEx(hPlayer, "Player.Jump");
```

### 8.16 `OnGameFrame(funcName, fTime, fDuration)`

创建定时器，定期执行函数。

**定义**: `utils.nut:909-932`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `funcName` | string | — | 函数名 (可带参数) |
| `fTime` | float | null → 0.01 | 执行间隔 |
| `fDuration` | float | null | 持续时间 (null=永久) |

**返回值**: `logic_timer` entity handle。

```lua
OnGameFrame("g_STLib.AF1.Think");                                // 每帧执行
OnGameFrame("SpeedrunRestart(false)", 1.0);                       // 1 秒后执行一次
OnGameFrame("MyFunction()", 0.1, 5.0);                            // 每 0.1 秒执行，持续 5 秒
OnGameFrame("g_STLib.AF1.ThinkProj", null, 0.5);                  // 每帧执行，0.5 秒后停止
```

### 8.17 `ClearEvent(sEvent, hTable)`

取消注册游戏事件监听。

**定义**: `utils.nut:879-904`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sEvent` | string | null | 事件名 (null=自动从调用帧检测) |
| `hTable` | table | null | 要移除的监听表 |

---

## 9. 数学与辅助函数

### 9.1 `AngNorm(ang, u_ang)`

角度归一化。

**定义**: `utils.nut:372-383`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `ang` | float | — | 角度 |
| `u_ang` | bool | false | true=返回 0~360, false=返回 -180~180 |

### 9.2 `Clamp(x, min, max)`

限定数值范围。

**定义**: `utils.nut:406-411`

### 9.3 `Lerp(a, b, t)`

线性插值。

**定义**: `utils.nut:416-419`

### 9.4 `EaseInOut(a, b, t)`

平滑插值 (缓入缓出)。

**定义**: `utils.nut:421-424`

### 9.5 `EaseIn(a, b, t)`

缓入插值 (二次方)。

**定义**: `utils.nut:426-429`

### 9.6 `EaseOut(a, b, t)`

缓出插值 (二次方)。

**定义**: `utils.nut:431-434`

### 9.7 `FEqual(a, b, deviation)`

浮点数近似相等比较。

**定义**: `utils.nut:396-401`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `a` | float | — | 值 a |
| `b` | float | — | 值 b |
| `deviation` | float | 0.001 | 允许误差范围 |

### 9.8 `absf(x)`

浮点数绝对值。

**定义**: `utils.nut:388-391`

### 9.9 `GetVecAng(vec)`

从向量计算欧拉角。

**定义**: `utils.nut:525-532`

| 参数 | 类型 | 说明 |
|------|------|------|
| `vec` | Vector | 方向向量 |

**返回值**: QAngle

### 9.10 `GetFinaleType()`

获取当前关卡的最终战类型。

**定义**: `utils.nut:637-661`

**返回值**: int — 0=Holdout, 1=Gauntlet, 2=Scavenge, 3=Custom, -1=N/A

---

## 10. SM 命令 VScript 封装

通过 `sm_ccmd` 与 SourceMod 插件通信。

### 10.1 `ClientCommand(hPlayer, sCmd)`

让指定玩家执行控制台命令。

**定义**: `sm_commands.nut:14-17`

| 参数 | 类型 | 说明 |
|------|------|------|
| `hPlayer` | entity | 玩家 |
| `sCmd` | string | 命令 |

```lua
ClientCommand(hPlayer, "say hello");
```

### 10.2 `SetClientName(hPlayer, sName)`

修改玩家名称。

**定义**: `sm_commands.nut:22-25`

### 10.3 `SetAmmo(hPlayer, iSlot, iClip, iAmmo, iUpgrade)`

设置玩家弹药量。

**定义**: `sm_commands.nut:30-42`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity | — | 玩家 |
| `iSlot` | int | — | 武器槽位 (0=主武器, 1=副武器) |
| `iClip` | int | — | 弹夹子弹数 |
| `iAmmo` | int | null | 备弹数 |
| `iUpgrade` | int | null | 升级弹药 (0= incendiary, 1= explosive, 2= laser) |

```lua
SetAmmo(hPlayer, 0, 30, 90);           // 主武器 30 发弹夹 + 90 备弹
SetAmmo(hPlayer, 0, 30, 90, 1);        // + 高爆弹药
```

### 10.4 `SetTeam(survName)`

设置队伍角色 (需要 Bot 在场)。

**定义**: `sm_commands.nut:47-66`

| 参数 | 类型 | 说明 |
|------|------|------|
| `survName` | string | 角色名 (Nick, Rochelle, Coach, Ellis) |

```lua
SetTeam("Coach");
```

### 10.5 `CallVote(hCaller, sCmd)`

发起投票 (更改难度)。

**定义**: `sm_commands.nut:71-84`

| 参数 | 类型 | 说明 |
|------|------|------|
| `hCaller` | entity | 发起者 |
| `sCmd` | string | 难度 (Easy, Normal, Hard, Impossible) |

```lua
CallVote(hPlayer, "Easy");
```

### 10.6 `PlayerReplace(hPlayer, hPlayer2)`

交换两个玩家的名称和角色控制权。

**定义**: `sm_commands.nut:89-92`

### 10.7 `AutoKick(hCaller, hPlayer, bRootKey)`

投票踢出 Bot 并补充新 Bot。

**定义**: `sm_commands.nut:97-138`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hCaller` | entity | — | 投票发起者 |
| `hPlayer` | entity | — | 要踢的 Bot |
| `bRootKey` | bool | false | 是否注册 round_end 事件 |

```lua
AutoKick(hPlayer, hBot);
```

---

## 11. 调试函数

### 11.1 `DebugItems(itemName, withDelay)`

标记地图上所有可生成物品并输出 SpawnItem 代码。

**定义**: `debug.nut:36-88`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `itemName` | string | null | 过滤物品名 (null=全部) |
| `withDelay` | bool | false | 延迟执行 |

**输出文件**: `ems/st_config/items_dump.nut`

```lua
DebugItems();              // 标记所有物品
DebugItems("molotov");     // 仅标记燃烧瓶
```

### 11.2 `CheckMoving(fTime, bChat, bLocalTime)`

监听 Bot 按键输入并输出到控制台。

**定义**: `debug.nut:93-124`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `fTime` | float | 3.0 | 监听时长 |
| `bChat` | bool | false | true=聊天输出, false=控制台输出 |
| `bLocalTime` | bool | false | 使用本地时间而非 CPGetTime |

```lua
CheckMoving(5.0);             // 监听 5 秒
CheckMoving(3.0, true);       // 聊天窗口输出
```

### 11.3 `ZDump(fTime)`

转储当前地图所有僵尸的位置和生成代码。

**定义**: `debug.nut:129-180`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `fTime` | float | null | 延迟秒数 (null=立即) |

**输出文件**: `ems/st_config/zdump.nut`

```lua
ZDump();          // 立即转储
ZDump(1.0);       // 1 秒后转储
```

### 11.4 `MobListener(flags, mobMax)`

监听普通感染者数量。

**定义**: `debug.nut:185-252`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `flags` | int | 1 | 1=HUD显示, 2=聊天输出, 4=控制台输出 |
| `mobMax` | int | 200 | 最大 Mob 数 |

```lua
MobListener(1);              // 仅 HUD 显示
MobListener(7);              // HUD + 聊天 + 控制台
MobListener(7, 150);         // 自定义上限
```

### 11.5 `ppos(vecPos, sName)`

在指定位置创建标记实体并打印 setpos 代码。

**定义**: `utils.nut:995-1009`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vecPos` | Vector | — | 标记位置 |
| `sName` | string | "" | 标记名称后缀 |

### 11.6 `ppos2(vecPos)`

小尺寸位置标记 (editor 模型)。

**定义**: `utils.nut:1011-1015`

### 11.7 `ptp(hPlayer)`

打印玩家当前位置/角度/速度的 TeleportEntity 代码。

**定义**: `utils.nut:1052-1078`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hPlayer` | entity/int | 1 | 玩家 handle 或索引 |

```lua
ptp();           // 打印玩家 1 的位置代码
ptp(hPlayer);    // 打印指定玩家
```

### 11.8 `pvel(hPlayer)`

打印玩家速度。

**定义**: `utils.nut:976-980`

### 11.9 `pdist(hPlayer, hPlayer2)`

打印两个玩家之间的距离。

**定义**: `utils.nut:985-990`

### 11.10 `DebugTrace(vStart, vEnd, autoPurge)`

在两点之间创建可视化绳索追踪线。

**定义**: `utils.nut:1083-1089`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vStart` | Vector | — | 起点 |
| `vEnd` | Vector | — | 终点 |
| `autoPurge` | float | null | 自动清除时间 |

```lua
DebugTrace(Vector(0, 0, 0), Vector(100, 0, 0), 5.0);  // 显示 5 秒
```

### 11.11 `find(name, findex)`

标记所有匹配名称或类名的实体。

**定义**: `utils.nut:1094-1120`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` | string | "" | 搜索文本 (空=清除标记) |
| `findex` | bool | false | true=精确匹配类名或名称 |

```lua
find("infected");   // 标记所有含 infected 的实体
find("", true);     // 清除所有标记
```
