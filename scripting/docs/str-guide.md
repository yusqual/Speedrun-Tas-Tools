# STR (Speedrun TAS Tools) 使用文档

**版本**: 2.2  
**说明**: 为 L4D2 速通提供录制/回放/调试功能的 TAS 工具集，包含 SourceMod 插件 (`SpeedrunTastools.sp`) 和 VScript 封装 (`str_commands.nut`)。

---

## 目录

1. [概述](#1-概述)
2. [安装与文件结构](#2-安装与文件结构)
3. [控制台命令](#3-控制台命令)
4. [ConVar 配置项](#4-convars-配置项)
5. [菜单系统](#5-菜单系统)
6. [VScript API（str_commands.nut）](#6-VScript API（str_commands.nut）)
7. [STR 文件格式](#7-str-文件格式)
8. [Debug 显示](#8-debug-显示)
9. [VScript Forwards](#9-vscript-forwards)
10. [使用流程](#10-使用流程)
11. [注意事项](#11-注意事项)

---

## 1. 概述

STR 提供录制玩家逐帧输入和移动数据、回放录制内容、以及实时调试显示的功能。

- **SourceMod 插件** (`SpeedrunTastools.sp`) — 录制、回放、文件 IO、菜单、轨迹绘制等核心逻辑
- **VScript 封装** (`str_commands.nut`) — 通过 `Convars.SetValue()` 同步调用 SourceMod 插件的各项功能，无 `SendToConsole` 的一帧延迟

所有函数使用 `Convars.SetValue()` → `HookConVarChange` 机制，SourceMod 侧在当前帧同步执行回调。

---

## 2. 安装与文件结构

```
addons/sourcemod/
├── plugins/
│   └── SpeedrunTastools.smx          ← 编译后的 STR 插件
├── scripting/
│   ├── SpeedrunTastools.sp           ← 插件源码
│   ├── STR/                          ← 模块文件
│   │   ├── STAPlayer.inc             ← 玩家状态管理
│   │   ├── ReplayRecording.inc       ← 录制逻辑
│   │   ├── ReplayPlayback.inc        ← 回放逻辑 + Debug HUD
│   │   ├── ReplayFileIO.inc          ← 文件保存/加载/分割
│   │   ├── ReplayCommands.inc        ← 命令处理 + 菜单
│   │   ├── ReplayFrame.inc           ← 帧数据结构
│   │   ├── Menus.inc                 ← 菜单枚举
│   │   ├── Formats.inc, Vector.inc, Time.inc, ItemList.inc
│   │   └── ...
│   ├── str_commands.nut              ← VScript 封装（放入 scripts/vscripts/）
│   └── compile.exe                   ← 编译器
└── data/
    └── str/                          ← 录制文件存储目录
        └── <地图名>/
            └── <文件名>.STR
```

VScript 端需将 `str_commands.nut` 放入 `scripts/vscripts/` 目录，并在对应 map 脚本中 `IncludeScript("str_commands")` 引入。

---

## 3. 控制台命令

### 3.1 菜单

| 命令 | 说明 |
|------|------|
| `sm_str` | 打开 STR 主菜单 |

### 3.2 录制与回放

| 命令 | 参数 | 说明 |
|------|------|------|
| `sm_replayrecord` | `[client索引]` | 开始录制指定玩家（默认自身） |
| `sm_replay_continue` | `[client索引]` | 继续/开始回放 |
| `sm_replay_pause` | `[client索引]` | 暂停回放 |
| `sm_replay_unpause` | `[client索引]` | 取消暂停 |
| `sm_resetreplay` | `[client索引]` | 重置/停止 Replay |

### 3.3 文件操作

| 命令 | 参数 | 说明 |
|------|------|------|
| `sm_replaysave` | `[client索引]` | 保存录制的 Replay 到文件 |
| `sm_loadfile` | `[client索引] [文件名]` | 加载 .STR 文件 |
| `sm_replay_split` | `[client索引]` | 分割 Replay（从当前帧截断） |

### 3.4 帧与参数

| 命令 | 参数 | 说明 |
|------|------|------|
| `sm_startframe` | `[值]` | 设置回放起始帧 |
| `sm_endframe` | `[值]` | 设置回放结束帧 |
| `sm_stopframe` | `[值]` | 设置回放停止帧（到达后自动停止） |
| `sm_removeslot` | `[slot]` | 移除指定物品栏槽位 |

### 3.5 轨迹绘制

| 命令 | 参数 | 说明 |
|------|------|------|
| `sm_replaydrawtrace` | `[client索引]` | 绘制 Replay 轨迹线 |
| `sm_replaydrawtrace_posmap` | `[client索引] [x] [y] [z]` | 按坐标映射偏移绘制轨迹 |
| `sm_replaydrawtraceclose` | — | 关闭轨迹绘制 |

### 3.6 其他

| 命令 | 参数 | 说明 |
|------|------|------|
| `sm_smoothreplay` | `[client索引]` | 线性平滑回放（从起点平滑过渡到终点） |
| `sm_test` | — | 调试用测试命令 |

---

## 4. ConVar 配置项

### 4.1 行为开关

| ConVar | 默认值 | 说明 |
|--------|--------|------|
| `sm_replaytorecord` | `0` | 回放结束后自动转入录制模式 |
| `str_onlysetvel` | `0` | 仅应用速度，不改变位置和视角 |
| `sm_replay_incapacitated` | `0` | 倒地状态是否允许继续回放 |
| `sm_replay_idle_anytime` | `0` | 无人时是否允许闲置 Bot |
| `sm_showframe` | `0` | 屏幕中心显示帧信息 |
| `sm_replaydebug` | `0` | 全局透视轨迹 Debug 开关 |

### 4.2 坐标映射

| ConVar | 默认值 | 说明 |
|--------|--------|------|
| `str_posmap_x` | `0.0` | 轨迹坐标映射 X 分量 |
| `str_posmap_y` | `0.0` | 轨迹坐标映射 Y 分量 |
| `str_posmap_z` | `0.0` | 轨迹坐标映射 Z 分量 |

### 4.3 VScript 触发器（自动归零）

以下 ConVar 主要用于 VScript 调用，值会在回调处理后自动归零：

| ConVar | 格式 | 说明 |
|--------|------|------|
| `str_trigger_play` | `client索引` | 触发回放 |
| `str_trigger_record` | `client索引` | 触发录制 |
| `str_trigger_reset` | `client索引` | 触发重置 |
| `str_trigger_save` | `client索引` | 触发保存 |
| `str_trigger_pause` | `client索引` | 触发暂停 |
| `str_trigger_unpause` | `client索引` | 触发取消暂停 |
| `str_trigger_load` | `client;文件名` | 触发加载文件 |

---

## 5. 菜单系统

输入 `!str` 或 `/str` 打开主菜单。

### 5.1 菜单流程

```
主菜单
├── 录制                                  → 开始录制自身
├── 停止/重置                             → 停止录制/回放
├── 继续/播放                             → 开始回放（需先加载文件）
├── 暂停                                  → 暂停回放（播放中显示）
├── 加载文件                              → 输入文件名加载 .STR
├── 保存到文件                            → 保存当前录制为 .STR
├── 起始帧 / 结束帧 / 停止帧              → 设置回放范围
├── sm_replaytorecord: ON/OFF             → 切换回放转录制开关
├── sm_replay_incapacitated: ON/OFF       → 切换倒地继续回放
├── str_onlysetvel: ON/OFF                → 切换仅设置速度
├── 平滑回放                              → 执行线性平滑回放
├── 分离 Replay                           → 从当前帧截断
├── Debug 调试                            → 屏幕 HUD 调试显示
│   ├── [自身]          ON/OFF            → 显示自身调试信息
│   └── [Bot 名称]      ON/OFF            → 显示指定 Bot 调试信息
└── 退出菜单
```

### 5.2 Debug 子菜单

Debug 子菜单使用 VScript HUD 在屏幕上实时显示逐帧调试信息：
- **[名称]** — 左对齐，10 字符宽
- **帧** — 当前帧 / 总帧数（回放中）或 `-`（非回放）
- **F** — `m_fFlags`（如 130 表示空中，128 表示爬梯）
- **VEL** — 当前速度大小
- **[bitmask] +btn1 +btn2...** — 按键位掩码及对应按键名

---

## 6. VScript API（str_commands.nut）

### 6.1 引入方式

在 map 脚本中添加：

```squirrel
IncludeScript("str_commands");
```

### 6.2 核心操作

```squirrel
// 录制 / 播放 / 重置
ST_STR(hPlayer, 0);    // 开始录制
ST_STR(hPlayer, 1);    // 开始播放
ST_STR(hPlayer, 2);    // 重置/停止

// 停止（单个或全部）
ST_STRStop(hPlayer);   // 停止指定玩家；hPlayer 为 null 则停止所有

// 保存
ST_STR_Save(hPlayer);  // 保存录制到文件

// 暂停 / 取消暂停
ST_STR_Pause(hPlayer);
ST_STR_UnPause(hPlayer);

// 加载文件
ST_STR_LoadFile(hPlayer, "文件名");  // 例如: ST_STR_LoadFile(hPlayer, "B2.STR")
```

### 6.3 ConVar 设置

```squirrel
ST_STR_SetPlayToRecord(true);   // 回放结束后自动转入录制
ST_STR_SetOnlySetVel(true);     // 仅应用速度
ST_STR_SetShowFrame(true);      // 屏幕中心显示帧号
ST_STR_SetReplayDebug(true);    // 轨迹全局透视
ST_STR_SetPlayWhenIncapped(true); // 倒地允许回放
ST_STR_SetPosMap(x, y, z);     // 设置坐标映射偏移
```

### 6.4 参数约定

- `hPlayer` — 玩家句柄。为 `null` 时默认取 `PlayerInstanceFromIndex(1)` (主机)
- `sFileName` — 仅文件名，不含路径。如 `"B2.STR"`
- 所有操作在同一帧同步执行，无延迟

### 6.5 典型用法

```squirrel
// 1. 加载文件并开始回放
ST_STR_LoadFile(hPlayer, "mysave");
ST_STR(hPlayer, 1);  // mode 1 = 播放

// 2. 回放结束后自动转入录制
ST_STR_SetPlayToRecord(true);
ST_STR_SetShowFrame(true);

// 3. 批量停止所有玩家
ST_STRStop(null);

// 4. 设置仅速度模式（不改变位置和视角）
ST_STR_SetOnlySetVel(true);
```

---

## 7. STR 文件格式

### 7.1 存储位置

```
addons/sourcemod/data/str/<地图名>/<文件名>.STR
```

### 7.2 格式说明

`.STR` 文件为自定义二进制/文本混合格式，每帧包含以下数据：

| 字段 | 说明 |
|------|------|
| `FRAME_PosX/Y/Z` | 玩家坐标 |
| `FRAME_AngX/Y` | 视角（pitch, yaw） |
| `FRAME_VelX/Y/Z` | 速度向量 |
| `FRAME_Buttons` | 按键掩码（IN_ATTACK, IN_JUMP 等） |
| `FRAME_MOVETYPE` | 移动类型（用于爬梯检测） |
| `FRAME_WEAPON` | 当前武器索引 |

---

## 8. Debug 显示

### 8.1 开启方式

1. 菜单中进入 "Debug 调试" 子菜单
2. 勾选 "自身" 和/或目标 Bot

### 8.2 显示内容

在屏幕中央右侧实时显示（VScript HUD）：

```
[玩家名]    帧:123/456  F: 130  VEL:   250  [513] +fwd +mright
```

- 仅显示当前在线的 Fake Client（Bot），纯 AI Bot 不显示
- `!restart` 后 HUD 会自动重建
- 被禁用的玩家会清空 HUD 显示

### 8.3 VScript 技术细节

- 使用 HUD slot 9（`HUD_MID_BOX`）
- 每 tick 刷新，使用 `HUDPlace` + `HUDSetLayout`
- 数据经过转义（`"` → `'`，`\n` → `\\n`）嵌入 VScript 字符串

---

## 9. VScript Forwards

插件提供三个全局 Forward 供第三方插件和 VScript 使用：

```sp
// 回放每 tick 触发
forward void OnPlayTick(int client, int frame, const char[] filename);

// 录制每 tick 触发
forward void OnRecordTick(int client, int frame);

// 回放结束时触发
forward void OnPlayTickEnd(int client, const char[] filename);
```

STR 自身也会对 client 调用 VScript 函数（如果存在）：

```squirrel
// 回放每帧
if ("OnPlayTick" in getroottable()) OnPlayTick(self, curframe, "filename");

// 录制每帧
if ("OnRecordTick" in getroottable()) OnRecordTick(self, curframe);

// 回放结束（自然结束 / stopFrame 停止 / 手动重置）
if ("OnPlayTickEnd" in getroottable()) OnPlayTickEnd(self, "filename");
```

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `client` | `int` | 客户端索引 |
| `frame` | `int` | 当前帧号 |
| `filename` | `string` | 已加载的 .STR 文件名（不含路径），如 `"B2.STR"` |

### 触发时机

| Forward | VScript | 触发条件 |
|---------|---------|----------|
| `OnPlayTick` | `OnPlayTick(self, frame, filename)` | 回放中每 tick |
| `OnRecordTick` | `OnRecordTick(self, frame)` | 录制中每 tick |
| `OnPlayTickEnd` | `OnPlayTickEnd(self, filename)` | 回放自然结束、到达 stopFrame、或手动 `sm_resetreplay` |

### VScript 使用示例

```squirrel
// 在 map 脚本或 vs_st_speedrun.nut 中定义即可，STR 会自动调用

::OnPlayTick <- function(hPlayer, frame, filename)
{
    // 回放每帧触发 — 可用于同步 UI、日志、外部计时器等
    printl(format("[STR] Playing %s — frame %d", filename, frame));
}

::OnPlayTickEnd <- function(hPlayer, filename)
{
    // 回放结束时触发 — 可用于自动加载下一个文件、切换模式等
    printl(format("[STR] Playback of %s finished", filename));

    // 例如：链式加载下一个分段
    // ST_STR_LoadFile(hPlayer, "B3.STR");
    // ST_STR(hPlayer, 1);
}

::OnRecordTick <- function(hPlayer, frame)
{
    // 录制每帧触发 — 可用于监控录制进度、实时保存等
    printl(format("[STR] Recording — frame %d", frame));
}
```

---

## 10. 使用流程

### 10.1 录制

```
1. !str → 选择 "录制"
2. 进行游戏操作
3. !str → 选择 "停止/重置"
4. !str → 选择 "保存到文件" → 输入文件名
```

### 10.2 回放

```
1. !str → 选择 "加载文件" → 输入文件名
2. 设置起始帧/结束帧（可选）
3. !str → 选择 "继续/播放"
4. 回放过程中按 IN_ZOOM（默认右键）锁定视角，松开后平滑过渡回录制视角
```

### 10.3 VScript 调用

```squirrel
// 录制
ST_STR(hPlayer, 0);
// ... 录制 N 帧 ...
ST_STR_Save(hPlayer);

// 回放
ST_STR_LoadFile(hPlayer, "mysave");
ST_STR(hPlayer, 1);
```

---

## 11. 注意事项

1. **先加载再回放**：调用 `ST_STR(hPlayer, 1)` 之前必须先用 `ST_STR_LoadFile` 加载文件
2. **爬梯回放**：插件自动处理爬梯帧的 `MOVETYPE_LADDER` 和方向向量，FakeClient 播放正常
3. **按键释放**：回放结束/重置时自动调用 `ResetButton` 释放所有按键，防止 `+attack` 卡死
4. **暂停状态**：暂停时玩家位置被锁定在原点 (0, 0, 0)
5. **自由视角**：回放时按住右键（IN_ZOOM）锁定视角观察周围，松开后 10 tick 内平滑过渡回录制视角
6. **Debug HUD 限制**：HUD_MID_BOX 区域有裁剪限制，同时显示目标过多可能导致文字被裁剪
