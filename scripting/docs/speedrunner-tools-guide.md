# Speedrunner Tools 5.5.18 使用指南

**版本**: 5.5 (VScript) / 1.4.20 (SourceMod 主插件)  
**作者**: noa1mbot  
**说明**: Speedrunner Tools 让速通录制更加便捷。

---

## 目录

1. [概述](#1-概述)
2. [安装与文件结构](#2-安装与文件结构)
3. [SourceMod 插件](#3-sourcemod-插件)
4. [游戏模式](#4-游戏模式)
5. [聊天指令](#5-聊天指令)
6. [HUD 计时器](#6-hud-计时器)
7. [VScript API](#7-vscript-api)
8. [速通脚本编写](#8-速通脚本编写)
9. [倒计时与重开](#9-倒计时与重开)
10. [高级功能](#10-高级功能)
11. [钩子函数清单](#11-钩子函数清单)
12. [注意事项](#12-注意事项)

---

## 1. 概述

Speedrunner Tools 是一个 Left 4 Dead 2 速通工具集，包含 SourceMod 插件和 VScript 脚本两部分：

- **SourceMod 插件** — 提供自动 bhop、自动 commonboost、快速换弹、边缘bug、闲置/接管等游戏辅助功能
- **VScript 系统** — 提供 HUD 计时器、RTA/Nerd/SP 三种模式、物品生成、僵尸生成、自动攻击(AutoFire)、脚本传送等速通脚本 API

---

## 2. 安装与文件结构

```
addons/sourcemod/
├── plugins/disabled/movements/        ← 移动录制文件 (Movement Reader)
│
scripting/Speedrunner Tools5.5.18/
│
├── addoninfo.txt                      ← 附加组件信息
│
├── unlisted/                          ← SourceMod 插件源码
│   ├── sm_speedrunner_tools.sp        ← 主插件
│   ├── sm_amovement_reader.sp         ← Movement Reader (移动录制/回放)
│   ├── sm_bhop.sp                     ← Auto Bunnyhop
│   └── sm_autocb.sp                   ← Auto Commonboost
│
├── scripts/vscripts/
│   ├── scriptedmode.nut               ← Scripted Mode 框架
│   ├── vs_st_ems.nut                  ← 主入口脚本
│   ├── vs_st_restart_game.nut         ← 重开脚本
│   └── st_scripts/
│       ├── skipintro.nut              ← 跳过开场动画
│       └── include/
│           ├── speedrunner_tools.nut   ← ST API 核心库
│           ├── utils.nut              ← 工具函数与常量
│           ├── sm_commands.nut        ← SM 命令 VScript 封装
│           └── debug.nut              ← 调试工具
│
├── unlisted/scripts/vscripts/
│   ├── vs_st_speedrun.nut             ← 基础速通脚本模板
│   ├── vs_st_speedrun2.nut            ← 高级速通脚本模板
│   └── vs_st_speedrun_commentary.nut  ← 解说脚本模板
│
├── resource/ui/hud/
│   └── hudscriptedmode.res            ← HUD 布局配置
│
├── materials/vgui/hud/
│   └── scalablepanel_bgblack50_outlinegrey.vtf  ← HUD 背景材质
│
└── unlisted/resource/
    └── closecaption_english.txt       ← 角色名称字幕
```

数据文件保存在 (运行时创建):
```
ems/st_config/st_data.txt              ← g_ST 配置持久化
ems/st_config/dump/                    ← 调试转储目录
ems/st_config/zdump.nut                ← 僵尸位置转储
ems/st_config/items_dump.nut           ← 物品位置转储
```

---

## 3. SourceMod 插件

### 3.1 sm_speedrunner_tools.sp (v1.4.20)

主插件，提供辅助功能和 SM ↔ VScript 桥接。

#### ConVars

| ConVar | 默认值 | 说明 |
|--------|--------|------|
| `st_version` | 1.4.20 | 版本号 |
| `st_fastreload` | 0 | 快速换弹 |
| `st_fastbw` | 1 | 快速起身 (黑白屏时) |
| `st_tankboost` | 1 |  Tank 攻击时自动 idle+take |
| `st_edgebug` | 0 | 自动 edgebug (达到指定坠落速度时自动 idle) |
| `st_edgebug_height` | 680.0 | Edgebug 触发高度 |
| `st_disableledgehang` | 1 | 禁用边缘悬挂 |
| `st_idle_anytime` | 0 | 允许在没有其他人类玩家时 idle |
| `st_idle` | 0 | 立即 idle (设置玩家索引) |
| `st_idletake` | 0 | 立即 takeover (设置玩家索引) |
| `st_idlereplace` | 0 0 | 交换两个玩家的控制权 |
| `st_allow_sdkhooks` | 0 | 允许 SDKHooks 数据传入 VScript |

#### 3.1.2 控制台命令

| 命令 | 说明 |
|------|------|
| `sm_setammo <client> <slot> <clip> [ammo] [upgrade]` | 设置弹药量 |
| `sm_ccmd <client> <command>` | 让指定玩家执行命令 |
| `sm_restart` | 重启速通 (调用 SpeedrunRestart()) |
| `sm_fake [team\|kill\|idle\|take]` | 创建/管理假客户端 |
| `sm_name <client> <name>` | 设置玩家名称 |
| `sm_idle [client]` | 让玩家进入闲置 |
| `sm_take [client]` | 让玩家接管 Bot |
| `sm_replace <client1> <client2>` | 交换两个玩家的角色 |
| `noclip` | 切换飞行模式 |
| `debug_inventory` | 打印所有幸存者的装备信息到控制台 |

#### 3.1.3 功能说明

**快速换弹** (`st_fastreload 1`):
- 换弹时自动 idle+take，跳过换弹动画
- 不适用于 shotgun、pistol、chainsaw

**快速起身** (`st_fastbw 1`):
- 被扶起后自动 idle+take，跳过起身动画

**Tank Boost** (`st_tankboost 1`):
- 被 Tank 攻击时自动 idle，保持位置

**自动 Edgebug** (`st_edgebug 1`):
- 当坠落速度超过 `st_edgebug_height` 时自动 idle
- 配合 `sm_take` 立即恢复

**禁用边缘悬挂** (`st_disableledgehang 1`):
- 对所有生还者施加 DisableLedgeHang 输入

**PlayerReplace**:
- `sm_replace <client1> <client2>` — 交换两个玩家的名称、击杀数，并互相接管对方的 Bot

**DebugInventory**:
- 打印当前地图名、难度、所有生还者的装备、血量、临时血量、复活次数
- 包含下一个地图的位置预测

---

### 3.2 sm_bhop.sp (v1.3.2)

自动 Bunnyhop。

**命令**: `sm_autobhop` — 切换自动 bhop (针对当前玩家)

- 在空中自动屏蔽跳跃输入，落地后恢复
- 不影响爬梯时的跳跃
- 提示: 可通过 VScript 的 `!bhop` 聊天指令控制

---

### 3.3 sm_autocb.sp (v1.8.6b)

自动 Commonboost (BETA)。

**ConVar**: `st_autocb` (默认 1)

- 当玩家推开僵尸后在 3 tick 内跳跃，自动施加 commonboost 速度
- 玩家移动方向与僵尸被推方向的夹角必须小于 1/4π
- 推动僵尸后输出调试信息到控制台
- Forward: `OnAutoCB(player, zombieName)` — 可在 VScript 中 Hook

---

## 4. 游戏模式

Speedrunner Tools 提供三种模式，通过 `!mode` 或聊天指令切换:

| 模式 | 值 | 说明 |
|------|-----|------|
| **Nerd 模式** | 0 | 作弊模式 (sv_cheats 1)，适用于 TAS/脚本录制 |
| **RTA 模式** | 1 | 真实时间竞速，禁用作弊，全队 4 人 |
| **SP 模式** | 2 | 单人模式，仅 1 名生还者 |

切换方式:
```
!mode          # 循环切换 Nerd → RTA → SP
!mode nerd     # 切换到 Nerd 模式
!mode rta      # 切换到 RTA 模式 (!rta 也可)
!mode sp       # 切换到 SP 模式
```

### 4.1 Nerd 模式 (模式 0)
- `sv_cheats 1`，可使用所有作弊命令
- 导演系统被禁用 (`DirectorStop()`)
- 适用于: 脚本调试、Movement Reader 录制/回放、AutoFire 测试
- 自动刷新 SourceMod 插件

### 4.2 RTA 模式 (模式 1)
- `sv_cheats 0`，禁用作弊
- 自动添加 4 个 Bot 队友
- 禁用部分聊天指令以防止作弊
- 带有完整的计时、分段、统计功能
- 支持 AutoBhop 分类

### 4.3 SP 模式 (模式 2)
- 清除所有 Bot，仅保留 1 名生还者
- `sv_cheats 1`，可作弊
- 适用于单人速通练习

---

## 5. 聊天指令

### 5.1 核心指令

| 指令 | 说明 |
|------|------|
| `!mode [nerd\|rta\|sp]` | 切换游戏模式 |
| `!rta` | 切换到 RTA 模式 |
| `!restart` | 重启当前关卡 (mp_restartgame) |
| `!restart2` | 快速重启 (跳过开场，保留装备) |
| `!restart3` | 快速重启并补充 Bot |
| `!rst` | 重置脚本 (取消卡死) |
| `!bhop` | 切换全局 AutoBhop |
| `!bhop2` | 切换本地 Bhop (alias +as_jump) |
| `!hud` | 切换 HUD 显示 |
| `!timer [seconds]` | 查看或设置倒计时时间 |
| `!fdmg` | 切换坠落伤害报告 |
| `!rd` | 切换 RocketDude 模式 (无限榴弹发射器) |

### 5.2 调试指令 (!dbg)

| 指令 | 说明 |
|------|------|
| `!dbg st` | 打印 ST 配置和状态 |
| `!dbg lib` | 打印 g_STLib 完整结构 |
| `!dbg rta` | 打印 RTA 会话统计 |
| `!dbg start` | 手动启动计时器 |
| `!dbg stop` | 手动停止计时器 |
| `!dbg set <time>` | 设置当前计时值 |
| `!dbg hud <time>` | 重载 HUD 并设置初始时间 |
| `!dbg reset` | 重置所有 ST 数据 |
| `!dbg event <data>` | 设置或查看当前事件数据 |
| `!dbg event` | 查看当前事件值 |
| `!dbg legit` | 切换 Full Legit 模式 |
| `!dbg unpatch` | 切换 Unpatch 模式 (回滚旧版本地图) |
| `!dbg tp` | 打印当前位置/角度/速度的 TeleportEntity 代码 |
| `!dbg tp2` | 打印所有生还者的 TeleportEntity 代码 |
| `!dbg tp3` | 打印 TeleportEntity 代码并绑定到 X 键 |
| `!dbg trigger` | 显示 trigger 边界框 |
| `!dbg clip` | 显示 env_player_blocker 边界框 |
| `!dbg do` | 打印 DirectorOptions |
| `!dbg nav` | 绑定 X 键到 NAV 标记模式 |
| `!dbg af [pipe\|molo\|bile]` | 自动 AutoFire 测试 |
| `!dbg events` | 打印当前注册的游戏事件 |
| `!dbg af2` | 测试 AutoFire2 (胆汁) |
| `!dbg af3` | 测试 AutoFire3 (pipe/molotov 团队 boost) |

### 5.3 其他指令

| 指令 | 说明 |
|------|------|
| `!picker` | 查看准星指向实体的生成代码 |
| `!trigger` | 在当前位置创建 trigger 并打印 SpawnTrigger 代码 |
| `!xclip` | XClip 功能 — 穿透逃生门 |
| `!xclip set` | 设置 XClip 保存点 |
| `!xclip fast` | 快速 XClip |
| `!xclip exact` | 精确 XClip (考虑俯仰角) |
| `!xclip double` | 双人 XClip |
| `!find <name>` | 标记所有匹配名称/类名的实体 |
| `!findex <name>` | 精确匹配实体名称/类名 |
| `!zdump` | 转储当前地图所有僵尸的位置代码 |

---

## 6. HUD 计时器

Speedrunner Tools 提供精确到毫秒的 HUD 计时器，定时更新 (每 0.01 秒)。

### 6.1 HUD 布局

**HUD 开启时** (`!hud` 切换，默认开启):
- 左上: 计时器 (分:秒)
- 左中: 毫秒 (000)
- 中上: 分隔符 (')
- 右上: 调试信息 (debug 模式时)

**HUD 关闭时**:
- 中下: 计时器
- 右中: 毫秒
- 右下: 分隔符

### 6.2 计时器控制

```
SpeedrunStart()                    # 启动计时
SpeedrunStart(false)               # 停止计时
!dbg start / !dbg stop             # 等效聊天指令
CPSetTime(seconds)                 # 设置当前时间
CPGetTime()                        # 获取当前时间
CPTime("message")                  # 打印带时间戳的消息
```

### 6.3 RTA 计时系统

RTA 模式下自动记录:
- 每关分段时间
- LiveSplit 兼容时间 (含 8.5s 过渡偏移)
- IGT (游戏内时间)
- 平均速度、最大速度
- 距离、跳跃数、击杀数
- 重开次数、死亡次数

最终统计在结局时自动输出到控制台:
```
__________________ Speedrun Stats __________________
Version .................:2.1.5.4
Record date ............. :13 May, 2026 @ 03:00:00PM
Time ....................:1:23s(83.456)
Campaign ................: +1:23s(83.456)
LiveSplit ...............:1:23s(91.956)
IGT (outro stats) .......:1:23s(83.456)
Category ................: AutoBhop+RTA
Restarts ................:2
Deaths ..................:0
Avg. velocity ...........:456
Max. velocity ...........:789 (c1m2_streets)
Distance ................:12345
Jumps ...................:50
Infected killed .........:10
```

---

## 7. VScript API

### 7.1 核心全局变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `g_ST` | table | 全局配置和运行时状态 |
| `g_RTA` | table | RTA 模式的计时数据 |
| `g_STLib` | table | ST API 库 (Items, Funcs, Vars) |
| `g_STLib.Items` | table | 物品定义 (item0 ~ item41) |
| `g_STLib.Funcs` | table | 核心功能函数 |
| `g_STLib.Vars` | table | 运行时变量 (HUD, 时间等) |

### 7.2 g_ST 配置项

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `timer_value` | float | 3.0 | 倒计时秒数 |
| `event` | string | "0" | 自定义事件数据 |
| `hud` | bool | true | HUD 是否可见 |
| `falldmg` | bool | false | 报告坠落伤害 |
| `mode` | int | 1 | 游戏模式 (0=Nerd, 1=RTA, 2=SP) |
| `full_legit` | bool | false | Full Legit 模式 |
| `bhop` | bool | true | 全局 AutoBhop |
| `bhop_local` | bool | false | 本地 Bhop |
| `unpatch` | bool | false | Unpatch 模式 |
| `rd` | bool | false | RocketDude 模式 |
| `restart` | bool | false | 是否正在重启 |
| `var_fast_update` | bool | false | 快速 HUD 更新 |

配置持久化保存在 `ems/st_config/st_data.txt`。

### 7.3 物品生成 (SpawnItem)

```lua
SpawnItem("item0", Vector(x, y, z), Vector(pitch, yaw, roll), count, targetname, removeRadius)
```

物品名称表:

| 名称 | 物品 |
|------|------|
| item0 | 弹药堆 |
| item1 | 高爆弹药包 |
| item2 | 燃烧弹药包 |
| item3 | 激光瞄准器 |
| item4 | 手枪 |
| item5 | 玛格南手枪 |
| item6 | 肾上腺素 |
| item7 | 止痛药 |
| item8 | 胆汁罐 |
| item9 | 土制炸弹 |
| item10 | 燃烧瓶 |
| item11 | 电击器 |
| item12 | 医疗包 |
| item13 |  chrome  shotgun |
| item14 |  泵动 shotgun |
| item15 |  SPAS shotgun |
| item16 |  自动 shotgun |
| item17 |  SMG |
| item18 |  消音 SMG |
| item19 |  M16 |
| item20 |  AK47 |
| item21 |  沙漠步枪 |
| item22 |  猎枪 |
| item23 |  军用狙击枪 |
| item24 |  M60 |
| item25 |  榴弹发射器 |
| item26 |  电锯 |
| item27 |  汽油桶 (prop_physics) |
| item28 |   propane 罐 (prop_physics) |
| item29 |  氧气罐 (prop_physics) |
| item30 |  炸药箱 (prop_physics) |
| item31~40 |  各种近战武器 |
| item41 |  咖啡店弹药 (c1 特有) |

### 7.4 僵尸生成

```lua
// 简易生成 (仅限地图内可用)
SpawnZombie("smoker", Vector(x, y, z), idle)
SpawnZombie("hunter", Vector(x, y, z), idle)
// ... tank, witch, witch_bride, boomer, jockey, charger, spitter, infected

// 精确生成 (可指定角度)
SpawnZombieEx("tank", Vector(x, y, z), Vector(pitch, yaw, roll), AttackOnSpawn, spawnTime)
SpawnZombieEx("infected", Vector(x, y, z))       // 随机普通感染者
SpawnZombieEx("spitter", Vector(x, y, z))         // 可设置 cm_AggressiveSpecials

// Common 僵尸 (可指定模型)
SpawnCommon(modelName, pos, ang, flags)
SpawnCommon("common_male_fallen_survivor", pos)    // 堕落幸存者

// Commonboost 专用僵尸
SpawnZombieForCB(pos, ang, startTime, hPlayer, bNotSolid, name)
```

**SpawnCommon flags**:
- `FALLEN_VJAR_OR_MOLOTOV` (1) — 携带胆汁/燃烧瓶
- `FALLEN_PIPE` (2) — 携带土制
- `FALLEN_PILLS` (4) — 携带药丸
- `FALLEN_MEDKIT` (8) — 携带医疗包
- `FALLEN_SIT` (16) — 坐姿
- `FALLEN_LYING` (32) — 躺姿

### 7.5 Trigger 生成

```lua
SpawnTrigger("name", pos, maxs, mins, callbackFunc, type, output, classname)
```

默认创建一个 trigger_multiple，玩家进入时调用 `OnEntityOutput()`。

### 7.6 AutoFire 系统

自动攻击系统用于速通中的爆炸物 Boost:

```lua
// AF1: 榴弹发射器 Boost
AutoFire(hPlayer, vecAng, vecPos, bLoop, bUp, fRadius, hClient, delayTime, data, method3D, vecVel)

// AF2: 胆汁/投掷物 Boost
AutoFire2(hPlayer, vecAng, vecPos, bLoop, bUp, fRadius, hClient, delayTime, data, method3D, bScripted)

// AF3: Pipe/火瓶团队 Boost (多人)
AutoFire3(hPlayer, aPlayers, fPitch, sWeapon, bScripted, data)

// 停止所有 AutoFire
AFStop()
```

回调:
- `OnAutoFired(hPlayer, data)` — 投掷物落地时触发
- `OnAutoFired_Post(hPlayer, hClient, data)` — 玩家获得 boost 后触发

### 7.7 其他 API

```lua
// 玩家控制
ST_Idle(hPlayer, bMode)           // 闲置/接管 Bot
ST_PlayerReplace(h1, h2)          // 交换角色
PlayerKill(hPlayer)               // 击杀玩家
PlayerKillFromWeapon(hPlayer, hAttacker, iShots, bWait, fTime)  // 用武器击杀(霰弹枪)
PlayerGod(hPlayer, bGod)          // 无敌开关

// 物品管理
RemoveItem(itemName)              // 移除所有指定物品
RemoveItemEx(pos, radius)         // 移除半径内物品
RemoveSlot(hPlayer, slot)         // 移除指定装备槽
RemoveCI()                        // 移除所有普通感染者

// 地图控制
DirectorStop(bMode)               // 停止/恢复导演系统
AutoOpen(bValue)                  // 自动开门
ScriptedTP(hPlayer, hLeader, fTime, bStuckTeleport, eMode)  // 脚本传送
ScriptedShots(hPlayer, fDistance) // 自动射击普通感染者

// 工具函数
TeleportEntity(hEntity, pos, ang, vel)      // 传送实体
GetPicker(hPlayer)                           // 获取准星指向实体
GetPickerPos(hPlayer)                        // 获取准星指向位置
EmitSound(pos, soundName, radius)            // 播放音效
NavMark(pos, flags)                          // 标记 NAV 区域
OnGameFrame(funcName, interval, duration)    // 创建定时器
```

### 7.8 SM 命令 VScript 封装

```lua
ClientCommand(hPlayer, "command")     // 让玩家执行命令
SetClientName(hPlayer, "name")        // 改名
SetAmmo(hPlayer, slot, clip, ammo, upgrade)  // 设置弹药
SetTeam("Coach")                      // 设置队伍 (需 sb_add)
CallVote(hPlayer, "Easy")            // 投票
PlayerReplace(hPlayer1, hPlayer2)    // 交换角色
AutoKick(hCaller, hPlayer)           // 投票踢出 Bot + 自动补充
ST_Idle(hPlayer, bMode)             // Idle/Takeover
ST_PlayerReplace(hPlayer1, hPlayer2) // 交换角色
ST_MR(hPlayer, mode, filename, bNoTeleport)  // 控制 Movement Reader
ST_MRStop(hPlayer)                   // 停止 MR
```

---

## 8. 速通脚本编写

将脚本放置在:
```
scripts/vscripts/vs_st_speedrun.nut        # 自动加载
scripts/vscripts/vs_st_speedrun2.nut       # 高级模板
scripts/vscripts/vs_st_speedrun_commentary.nut
```

当 `g_ST.restart = true` 时，脚本在每回合开始自动加载。

### 8.1 基础脚本模板

```lua
// 设置游戏参数
Convars.SetValue("mp_gamemode", "coop");
Convars.SetValue("z_difficulty", "Easy");

// 禁用辅助功能 (MR 扩展模式可替代自动 CB)
Convars.SetValue("st_autocb", 0);
Convars.SetValue("st_tankboost", 0);
Convars.SetValue("st_fastreload", 0);
Convars.SetValue("st_edgebug", 0);

DirectorStop();                      // 停止导演系统
// EntFire("info_changelevel", "Disable");  // 锁定安全门

// 倒计时结束后调用
function Inventory2()
{
    // 给予装备
    local hPlayer = Ent("!nick");
    hPlayer.GiveItem("pistol");
    hPlayer.SetHealth(50);
    
    // 开始录制移动
    ST_MR(hPlayer, 0, "m1_nick");
}

// 触发器回调
::OnEntityOutput <- function()
{
    if (caller.GetName() == "trigger_area1") { }
}

// MR 回调
::OnPlayEnd <- function(hPlayer, sFileName) { }
::OnPlayLine <- function(hPlayer, sFileName, tick, buttons) { }

// AutoFire 回调
::OnAutoFired <- function(hPlayer, data) { }
::OnAutoFired_Post <- function(hPlayer, hClient, data) { }

// AutoCB 回调
::OnAutoCB <- function(hPlayer, sName) { }

// 安全室到达回调
::OnSafe <- function(hPlayer) { }

// 重开回调
::OnRestart <- function() { }

// 初始化
Timer();                              // 启动倒计时
HUDLoad(0.0);                         // 加载 HUD (可指定起始时间)
// SetTeam("Coach");                  // 可选: 设置角色
```

### 8.2 ST_MR 用法

```lua
// 录制/回放移动 (需要安装 Movement Reader 插件)
ST_MR(hPlayer, 0, "filename");      // 录制
ST_MR(hPlayer, 1, "filename");      // 回放
ST_MR(hPlayer, 2, "default");       // 从 default 文件回放
ST_MR(hPlayer, 3);                  // 分割
ST_MRStop();                         // 停止所有
ST_MRStop(hPlayer);                  // 停止指定玩家
```

### 8.3 HUD 更新回调

```lua
function OnGameEvent_scriptedmode_reloadhud(...)
{
    local time = g_STLib.Vars.HUD.Fields.timer_sec.dataval;
    local tick = g_STLib.Vars.tick;
    if (tick == 10) printl(tick + " tick >> time: " + time);
}
```

---

## 9. 倒计时与重开

### 9.1 Timer 系统

`Timer()` 函数在脚本中调用，提供三段式倒计时:

```lua
Timer();                        // 使用 g_ST.timer_value (默认 3 秒)
// 倒计时过程:
// 3 → 2 → 1 → Inventory() 或 Inventory2() → SpeedrunStart()
```

倒计时期间玩家被冻结，所有非主武器被移除。可通过 `!timer 5` 修改倒计时秒数。

### 9.2 重启方式

| 方式 | 命令 | 说明 |
|------|------|------|
| 标准重启 | `!restart` | `mp_restartgame 1` |
| 快速重启 | `!restart2` | 保持装备重新开始 (SpeedrunRestart(true)) |
| Bot 补充 | `!restart3` | 快速重启 + 补充 Bot |
| 重置脚本 | `!rst` | `host_timescale 1`，如果卡死则 `changelevel` |
| 完全重置 | `!dbg reset` | 重置所有 ST 数据 + HUD 重新加载 |

---

## 10. 高级功能

### 10.1 AutoBhop 系统

两种模式:

1. **全局 AutoBhop** (`!bhop`):
   - 通过 VScript 的 `OnGameFrame` 定时器实现
   - 在空中自动屏蔽跳跃输入
   - 可在 `!dbg st` 中查看 `var_bhoppers` 数组 (每个玩家独立开关)
   - 玩家可通过 `script bhop` 控制自己的开关

2. **本地 Bhop** (`!bhop2`):
   - 使用 alias 绑定 `+jump` 到 Space 键
   - 适用于没有全局 AutoBhop 的服务器

### 10.2 Unpatch 模式

`!dbg unpatch` — 尝试回滚旧版本地图修改:
- 移除 `env_player_blocker` (特定地图)
- 移除 `anv_mapfixes_*` (TLS 版本)
- 移除部分地图特有的阻挡物
- 还原 c8m3 仓库门、c10m3 安全门位置等

### 10.3 Full Legit 模式

`!dbg legit` — 禁用所有 ST 辅助功能:
- 不设置 `sv_cheats`
- 保持导演系统正常工作
- 不干预 checkpoint 关门逻辑

### 10.4 RocketDude 模式

`!rd` — 玩家出生时自动获得榴弹发射器 (仅 TLS 版本可用)。

### 10.5 SkipIntro

`st_scripts/skipintro.nut` — 在 m1 地图自动跳过开场动画:
- 移除 intro 摄像机 (`point_viewcontrol_survivor`)
- 移除 intro 声音和对话
- 移除 intro 过场实体 (直升机、飞机等)
- 调用 `ReleaseSurvivorPositions` 立即开始游戏

支持所有官方战役: c1~c13，以及通用 fallback 方案。

### 10.6 CheckMoving (调试)

监听 Bot 的按键输入:

```lua
CheckMoving(3.0);               // 监听 3 秒
CheckMoving(5.0, true);         // 通过聊天输出
```

### 10.7 MobListener

监听特感/普通感染者数量:

```lua
MobListener(flags, mobMax);
// flags: 1=HUD, 2=CHAT, 4=CONSOLE
```

### 10.8 ZDump

转储当前地图所有僵尸的位置和生成代码:

```
!zdump
// 生成文件: ems/st_config/zdump.nut
```

### 10.9 DebugItems

标记地图上的所有物品:

```
DebugItems()                    // 标记所有物品
DebugItems("molotov")           // 仅标记燃烧瓶
DebugItems("pipe")              // 仅标记土制
```

---

## 11. 钩子函数清单

Speedrunner Tools 提供了多层级的钩子系统，涵盖 VScript 全局回调、游戏事件、生命周期钩子和 SourceMod forward。

### 11.1 VScript 全局回调

定义在 `st_scripts/include/speedrunner_tools.nut` (第 59-68 行) 中的空函数桩，脚本中重写即生效:

| 钩子 | 参数 | 说明 |
|------|------|------|
| `OnEntityOutput` | `(caller, activator, output)` | trigger 实体被触发时调用 |
| `OnRestart` | `()` | 速通重开时调用 |
| `OnPlayEnd` | `(hPlayer, sFileName)` | Movement Reader 回放结束时调用 |
| `OnPlayLine` | `(hPlayer, sFileName, tick, buttons)` | MR 每帧回放时调用 |
| `OnAutoFired` | `(hPlayer, data)` | AutoFire 投掷物落地时调用 |
| `OnAutoFired_Post` | `(hPlayer, hClient, data)` | AutoFire 玩家获得 boost 后调用 |
| `OnAutoCB` | `(hPlayer, sName)` | 自动 Commonboost 完成时调用 |
| `OnSafe` | `(hPlayer)` | 玩家到达安全室时调用 |
| `OnEntityCreated` | `(hEntity, classname)` | 实体创建时调用 (需 `st_allow_sdkhooks 1`) |
| `OnEntityDestroyed` | `(hEntity)` | 实体销毁时调用 (需 `st_allow_sdkhooks 1`) |

**示例**:
```lua
::OnPlayEnd <- function(hPlayer, sFileName)
{
    if (sFileName == "default")
        ST_MR(hPlayer, 0, "m1_nick");  // 回放结束后自动开始录制下一段
}

::OnSafe <- function(hPlayer)
{
    printl("玩家 " + hPlayer.GetPlayerName() + " 已到达安全室！");
}
```

> **注意**: `OnEntityCreated` 和 `OnEntityDestroyed` 来自 SourceMod 的 SDKHooks，需要通过 `st_allow_sdkhooks 1` 启用。默认关闭以减少脚本负载。

### 11.2 生命周期钩子

在速通脚本 (`vs_st_speedrun.nut`) 中按约定定义的函数，由框架在特定时机自动调用:

| 钩子 | 参数 | 调用时机 | 说明 |
|------|------|----------|------|
| `Inventory` | `()` | 倒计时结束后 | 给予装备 (基础模板) |
| `Inventory2` | `()` | 倒计时结束后 / 开场动画结束后 | 给予装备 (高级模板, 优先于 Inventory) |
| `Event` | `()` | Inventory 之后 (仅 `g_ST.event != "0"`) | 处理自定义事件数据 |

**调用顺序**: `Timer()` 倒计时 → `Inventory()` 或 `Inventory2()` → `SpeedrunStart()`

**示例**:
```lua
function Inventory2()
{
    local hPlayer = Ent("!nick");
    hPlayer.GiveItem("pistol_magnum");
    hPlayer.SetHealth(50);
    ST_MR(hPlayer, 1, "m1_nick");  // 开始回放
}

function Event()
{
    if (g_ST.event == "1")
    {
        DirectorStop();
        Convars.SetValue("host_timescale", 0.5);
    }
}
```

### 11.3 游戏事件回调

通过 `OnGameEvent_` 前缀注册的 L4D2 游戏事件钩子，在脚本中定义即自动注册:

| 钩子 | 参数 (event table) | 说明 |
|------|---------------------|------|
| `OnGameEvent_weapon_fire` | `(event)` | 玩家开火时触发 |
| `OnGameEvent_player_jump_apex` | `(event)` | 玩家到达跳跃最高点时触发 |
| `OnGameEvent_scriptedmode_reloadhud` | `(...)` | HUD 每次更新时触发 (类似 OnGameFrame) |

**event 参数说明**:
- `OnGameEvent_weapon_fire`: `event.userid` — 玩家 UserID, `event.weapon` — 武器名称
- `OnGameEvent_player_jump_apex`: `event.userid` — 玩家 UserID

**示例**:
```lua
function OnGameEvent_weapon_fire(event)
{
    local hPlayer = GetPlayerFromUserID(event.userid);
    if (hPlayer && event.weapon == "pipe_bomb")
        printl("玩家投掷了土制炸弹！");
}

function OnGameEvent_scriptedmode_reloadhud(...)
{
    local time = g_STLib.Vars.HUD.Fields.timer_sec.dataval;
    local tick = g_STLib.Vars.tick;
    if (tick % 100 == 0)
        printl("Timer: " + time + " | Tick: " + tick);
}
```

> **完整游戏事件列表**: https://wiki.alliedmods.net/Left_4_dead_2_events

### 11.4 SourceMod Forwards

由 SourceMod 插件暴露给 VScript 的 forward:

| Forward | 来源 | VScript 对应钩子 | 说明 |
|---------|------|-----------------|------|
| `OnAutoCB(client, zombieName)` | `sm_autocb.sp` | `OnAutoCB(hPlayer, sName)` | 自动 Commonboost 完成 |
| `OnPlayEnd(client, filename)` | `sm_amovement_reader.sp` | `OnPlayEnd(hPlayer, sFileName)` | MR 回放结束 |
| `OnPlayLine(client, filename, tick, buttons)` | `sm_amovement_reader.sp` | `OnPlayLine(hPlayer, sFileName, tick, buttons)` | MR 回放每帧 |

SourceMod forward 的触发机制: SM 插件调用 `CreateGlobalForward()`，然后通过 `AcceptEntityInput(hPlayer, "RunScriptCode")` 调用 VScript 中对应的全局函数。因此 VScript 端的 `OnXxx` 钩子定义在 `getroottable()` 中 (以 `::` 前缀)。

实现方式 (以 OnAutoCB 为例):
```c++
// sm_autocb.sp
Call_StartForward(g_hOnAutoCB);
Call_PushCell(client);
Call_PushString(sEntName);
Call_Finish();
// 然后调用 VScript
Format(sCode, sizeof(sCode), "if (\"OnAutoCB\" in getroottable()) OnAutoCB(self, \"%s\")", sEntName);
SetVariantString(sCode);
AcceptEntityInput(client, "RunScriptCode");
```

### 11.5 钩子调用流程图

```
游戏事件 (OnGameEvent_round_start)
  │
  ├→ Hooks() 注册内部事件监听
  │     ├→ 安全门关闭检测 (CheckpointDoorClosed)
  │     ├→ PlayerSpeed 定时器 (每帧更新 cl_player_speed)
  │     ├→ Unpatch 模式处理
  │     └→ OnGameplayStart → ReleaseSurvivorPositions (Nerd 模式)
  │
  ├→ 脚本加载 (vs_st_speedrun.nut)
  │     ├→ Timer() 倒计时
  │     └→ HUDLoad() 初始化 HUD
  │
  └→ 倒计时结束
        ├→ Inventory() / Inventory2() ← 【生命周期钩子】
        ├→ Event()                    ← 【生命周期钩子】
        └→ SpeedrunStart() 启动计时
              └→ HUD 定时更新
                    └→ OnGameEvent_scriptedmode_reloadhud ← 【游戏事件回调】

外部触发:
  MR 回放结束 → OnPlayEnd(hPlayer, sFileName)              ← 【全局回调】
  MR 每帧     → OnPlayLine(hPlayer, sFileName, tick, btns)  ← 【全局回调】
  AutoFire    → OnAutoFired(hPlayer, data)                   ← 【全局回调】
              → OnAutoFired_Post(hPlayer, hClient, data)     ← 【全局回调】
  AutoCB      → OnAutoCB(hPlayer, sName)                     ← 【全局回调】
  进入安全室  → OnSafe(hPlayer)                              ← 【全局回调】
  实体创建    → OnEntityCreated(hEntity, classname)          ← 【全局回调】
  实体销毁    → OnEntityDestroyed(hEntity)                   ← 【全局回调】
  开火        → OnGameEvent_weapon_fire(event)               ← 【游戏事件回调】
  跳跃最高点  → OnGameEvent_player_jump_apex(event)          ← 【游戏事件回调】
  重开游戏    → OnRestart()                                  ← 【全局回调】
  trigger触发 → OnEntityOutput(caller, activator, output)    ← 【全局回调】
```

### 11.6 启用条件速查

| 钩子 | 是否需要额外设置 |
|------|-----------------|
| `OnEntityCreated` / `OnEntityDestroyed` | `st_allow_sdkhooks 1` |
| `OnPlayEnd` / `OnPlayLine` | 需要安装 Movement Reader 插件 |
| `OnAutoCB` | `st_autocb 1` (默认开启) |
| 其余所有钩子 | 无需额外设置，脚本中定义即用 |

---

## 12. 注意事项

1. **插件加载顺序**: `sm_speedrunner_tools` 需要在 `sm_bhop` 和其他插件之前加载
2. **RTA 模式限制**: RTA 模式下禁用部分聊天指令，需通过控制台操作
3. **AutoCB BETA**: 自动 Commonboost 仍为 BETA 功能，非标准情况可能工作异常
4. **Unpatch 局限性**: 无法完全还原 TLS 版本的修改，部分地图不支持
5. **Movement Reader 集成**: 脚本中可通过 `ST_MR()` 函数控制录制/回放，详细用法见 [movement-reader-guide.md](movement-reader-guide.md)
6. **VScript 钩子**: 所有全局钩子 (`OnPlayEnd`, `OnAutoCB` 等) 在 `st_scripts/include/speedrunner_tools.nut` 中预定义为空函数
