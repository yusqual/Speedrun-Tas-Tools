# Movement Reader (sm_amovement_reader) 使用指南

**版本**: 1.5.23  
**作者**: noa1mbot  
**说明**: 记录和回放玩家的移动操作。

---

## 目录

1. [文件存储位置](#1-文件存储位置)
2. [快速上手](#2-快速上手)
3. [菜单系统](#3-菜单系统)
4. [控制台命令](#4-控制台命令)
5. [ConVars 配置项](#5-convars-配置项)
6. [文件格式说明](#6-文件格式说明)
7. [高级功能](#7-高级功能)
8. [VScript 回调](#8-vscript-回调)

---

## 1. 文件存储位置

所有移动记录文件保存在:

```
addons/sourcemod/plugins/disabled/movements/
```

默认文件名:
- 玩家 1 (主机): `default.txt`
- 其他玩家: `default_{index}.txt` (如 `default_2.txt`)
- 快速保存: `quicksave.txt`

---

## 2. 快速上手

### 2.1 录制移动

1. 在游戏中打开控制台，输入 `stmr` 打开基本菜单
2. 选择 **Record** (选项 1)，开始录制
3. 执行你想要录制的移动操作
4. 输入 `st_mr_stop` 或在菜单中选择 **Stop** 停止录制

或者通过 ConVar 直接控制:

```
st_mr_record 1    # 开始录制玩家 1 的移动
st_mr_stop_player 1  # 停止玩家 1 的录制
```

### 2.2 回放移动

1. 确保 `default.txt` 文件存在于 movements 目录
2. 输入 `stmr` 打开菜单，选择 **Playback** (选项 2)

或者:

```
st_mr_play 1      # 开始回放玩家 1 的移动
```

---

## 3. 菜单系统

### 3.1 基本菜单 (`stmr`)

| 选项 | 功能 | 说明 |
|------|------|------|
| 1. Record | 录制 | 开始录制当前玩家的移动 |
| 2. Playback | 回放 | 开始回放已录制的移动 |
| 3. Split | 分割 | 从当前位置分割回放并开始新录制 |
| 4. Fwd >> | 快进 | 快进 150 帧 |
| 5. Rew << | 后退 | 后退 150 帧 |
| 6. Stop | 停止 | 停止所有录制/回放 |
| 7. Legacy Mode | 传统模式 | 切换 扩展模式/传统模式 (仅主机) |

### 3.2 高级菜单 (`stmr2`)

| 选项 | 功能 | 说明 |
|------|------|------|
| 1. Record/Split | 录制/分割 | 延迟后开始录制或分割 |
| 2. Play | 播放 | 开始回放 |
| 3. Goto/Freeze | 跳转/冻结 | 进入帧浏览模式或冻结当前帧 |
| 4. Stop | 停止 | 停止并重置 Goto 状态 |
| 5. Legacy Mode | 传统模式 | 切换是否使用扩展向量数据 |
| 6. Debug Mode | 调试模式 | OFF → Screen → Console 循环切换 |
| 7. Tracker | 轨迹追踪 | 在游戏中绘制移动路径 |
| 8. Save | 快速保存 | 保存当前 default.txt 的副本为 quicksave.txt |

**快捷键 (高级菜单下)**:
- `E + R` (使用+换弹): 清除所有轨迹线
- `SHIFT + R`: 加载最后一次快速保存的文件
- `A/D` 键 (在 Goto 模式下): 逐帧后退/前进

---

## 4. 控制台命令

### 4.1 `st_mr_stop [player]`

停止指定玩家的所有录制/回放。不带参数默认停止所有玩家。

```
st_mr_stop     # 停止所有
st_mr_stop 2   # 停止玩家 2
```

### 4.2 `st_mr_goto <line> [filename] [player]`

跳转到指定行开始回放。

```
st_mr_goto 150          # 跳转到当前回放的第 150 行
st_mr_goto 100 "run1"   # 加载 run1.txt 并跳转到第 100 行
st_mr_goto 50 "" 2      # 为玩家 2 跳转到第 50 行
```

> **注意**: 行号从 4 开始计数 (前 3 行为 Origin/Angles/Velocity 头信息)。  
> 在 Goto 模式下，按 A/D 键可以逐帧浏览。

### 4.3 `st_mr_get_frame [player]`

获取当前回放的帧号。

```
st_mr_get_frame     # 查看当前玩家帧号
st_mr_get_frame 2   # 查看玩家 2 的帧号
```

### 4.4 `st_mr_tracker [filename]`

在游戏中绘制移动路径的轨迹线，并将统计信息输出到控制台。

```
st_mr_tracker           # 追踪当前选中的文件
st_mr_tracker "run1"    # 追踪 run1.txt
```

控制台输出信息:
- ID: 轨迹编号
- Name: 移动文件名
- Duration: 时长
- Frames: 总帧数
- Lines: 总行数 (含头信息)
- File path: 文件路径
- Size: 文件大小
- Timestamp: 文件时间戳

### 4.5 `st_mr_tracker_clear`

清除所有已绘制的轨迹线。

### 4.6 `st_mr_save`

将当前 `default.txt` 复制为 `quicksave.txt`。

---

## 5. ConVars 配置项

| ConVar | 默认值 | 说明 |
|--------|--------|------|
| `st_mr_force_file` | `"default"` | 强制指定回放文件名 |
| `st_mr_record` | `0` | 指定要录制的玩家索引 |
| `st_mr_play` | `0` | 指定要回放的玩家索引 |
| `st_mr_split` | `0` | 指定要分割的玩家索引 |
| `st_mr_no_teleport` | `0` | 禁止回放前传送玩家到起始位置 |
| `st_mr_stop_player` | `0` | 停止指定玩家的录制/回放 |
| `st_mr_exrec` | `1` | 启用扩展录制 (记录 Origin 和 Velocity 向量) |
| `st_mr_explay` | `1` | 启用扩展回放 (使用记录的向量数据) |
| `st_mr_debug` | `0` | 在控制台输出指定玩家的移动数据行 |
| `st_mr_ffa` | `1` | 自由模式，每个玩家使用自己的 default 文件 |
| `st_mr_allow_record_idle` | `1` | 允许录制 IDLE 标志位 |
| `st_mr_allow_free_angle` | `0` | 允许自由视角录制/回放 (调试用) |
| `st_mr_allow_host_inputs` | `0` | 允许将客户端输入发送到主机控制台 |
| `st_mr_allow_playback_special_helpers` | `1` | 回放时自动重置计时器并清除特感 |
| `st_mr_tweak_delay` | `1.2` | 录制/分割前的延迟时间 (秒) |
| `st_mr_tweak_timescale` | `0.25` | 录制/分割后的游戏速度倍率 |
| `st_mr_tracker_text_level` | `1` | 轨迹文字显示级别 (0=关, 1=仅文字, 2=带时间标记) |

---

## 6. 文件格式说明

### 6.1 文件结构

一个标准的移动文件包含 3 行头信息 + N 行帧数据:

```
Origin:-1415.250:-877.969:160.031       ← 起始位置 (m_vecOrigin)
Angles:30.000:25.000:0.000               ← 起始视角
Velocity:250.000:0.000:0.000             ← 起始速度 (m_vecVelocity)

← 以下每行一帧 →
buttons:angleX:angleY:weapon:originX, originY, originZ:velX, velY, velZ:flags
buttons:angleX:angleY:weapon:originX, originY, originZ:velX, velY, velZ:flags
...
```

### 6.2 帧数据字段

| 字段 | 说明 |
|------|------|
| `buttons` | 按键掩码 (整数，见下方按键表) |
| `angleX` | 视角 X (Pitch) |
| `angleY` | 视角 Y (Yaw) |
| `weapon` | 武器 ID (见武器索引表) |
| `origin` | 位置向量 (X, Y, Z) — 仅扩展模式 |
| `velocity` | 速度向量 (X, Y, Z) — 仅扩展模式 |
| `flags` | 玩家标志位 (m_fFlags) — 仅扩展模式 |

### 6.3 按键掩码

| 值 | 名称 | 说明 |
|----|------|------|
| 1 | IN_ATTACK | 攻击 |
| 2 | IN_JUMP | 跳跃 |
| 4 | IN_DUCK | 蹲下 |
| 8 | IN_FORWARD | 前进 (W) |
| 16 | IN_BACK | 后退 (S) |
| 32 | IN_USE | 使用 (E) |
| 128 | IN_LEFT | 左移 |
| 256 | IN_RIGHT | 右移 |
| 512 | IN_MOVELEFT | 左平移 (A) |
| 1024 | IN_MOVERIGHT | 右平移 (D) |
| 2048 | IN_ATTACK2 | 右键攻击 |
| 4096 | IN_RUN | 奔跑 |
| 8192 | IN_RELOAD | 换弹 (R) |
| 131072 | IN_SPEED | 速度键 (SHIFT) |
| 262144 | IN_WALK | 行走 |
| 4194304 | IN_BULLRUSH | 冲锋 |
| 67108864 | IN_IDLE | 闲置 (插件自定义) |
| 134217728 | IN_TAKEOVER | 接管 Bot (插件自定义) |
| 268435456 | IN_FREE_ANGLE | 自由视角 (插件自定义) |

### 6.4 武器 ID

| ID | 武器 |
|----|------|
| 1 | weapon_upgradepack_incendiary |
| 2 | weapon_upgradepack_explosive |
| 3 | weapon_pistol |
| 4 | weapon_pistol_magnum |
| 5 | weapon_adrenaline |
| 6 | weapon_pain_pills |
| 7 | weapon_vomitjar |
| 8 | weapon_pipe_bomb |
| 9 | weapon_molotov |
| 10 | weapon_defibrillator |
| 11 | weapon_first_aid_kit |
| 12 | weapon_shotgun_chrome |
| 13 | weapon_pumpshotgun |
| 14 | weapon_shotgun_spas |
| 15 | weapon_autoshotgun |
| 16 | weapon_smg |
| 17 | weapon_smg_silenced |
| 18 | weapon_rifle |
| 19 | weapon_rifle_ak47 |
| 20 | weapon_rifle_desert |
| 21 | weapon_hunting_rifle |
| 22 | weapon_sniper_military |
| 23 | weapon_rifle_m60 |
| 24 | weapon_grenade_launcher |
| 25 | weapon_chainsaw |
| 26 | weapon_melee |

---

## 7. 高级功能

### 7.1 扩展模式 vs 传统模式

**扩展模式** (`st_mr_exrec 1` / `st_mr_explay 1`，默认开启):
- 录制 Origin、Velocity 和 Flags 数据
- 回放时精确还原位置和速度
- 文件体积较大

**传统模式** (`st_mr_exrec 0` / `st_mr_explay 0`):
- 仅记录按钮和视角
- 回放时由游戏物理模拟移动
- 兼容旧版本文件
- 在高级菜单中通过 **Legacy Mode** 切换

> 切换传统模式仅对主机 (player 1) 有效。

### 7.2 分割录制 (Split)

分割功能允许你在回放过程中从某个时间点开始重新录制:

1. 先录制一段移动 (如 default.txt)
2. 回放到你想修改的位置，点击 **Split**
3. 玩家的后续操作将替换原有动作

或者在控制台:
```
st_mr_split 1     # 分割玩家 1 的回放并开始新录制
```

分割前可以通过 `st_mr_tweak_delay` 设置延迟时间，`st_mr_tweak_timescale` 设置分割后的游戏速度。

### 7.3 Goto 模式 (帧精确浏览)

Goto 模式让你可以逐帧浏览回放:

1. 在高级菜单中选择 **Goto** 进入帧浏览模式
2. 按住 `A` 键后退，按住 `D` 键前进
3. 再次点击 **Goto** 退出浏览模式并继续回放
4. 点击 **Play** 从当前位置开始回放

> **注意**: Goto 模式下不保存 m_fFlags 状态，在跳跃前后分割可能导致回放异常。建议在可以等待下次跳跃的位置进行分割。

### 7.4 轨迹追踪 (Tracker)

在 3D 场景中绘制移动路径:

```
st_mr_tracker "filename"   # 绘制指定文件的路径
st_mr_tracker_clear        # 清除所有路径
```

每调用一次 `st_mr_tracker` 都会创建一个新的轨迹 ID。轨迹线为蓝色和黄色交替线段，并带有文字标注。首次追踪时，玩家视角会自动转向路径起点。

在高级菜单中按 **Tracker** (选项 7) 可快速追踪当前选中的文件。轨迹文字显示级别由 `st_mr_tracker_text_level` 控制。

### 7.5 调试模式

高级菜单选项 6 循环切换三种调试状态:

- **OFF**: 关闭调试
- **Screen**: 在游戏画面上显示 HUD 信息 (UPS、速度、帧号、标志位、按键状态)
- **Console**: 在控制台输出每帧的详细数据

> 多人模式下 Screen 调试不可用，会自动切换为 Console 模式。Screen 模式依赖 Speedrun Tools 的 HUD 系统。

### 7.6 IN_IDLE 和 IN_TAKEOVER

这两个自定义标志位用于处理 Bot 接管:

- **IN_IDLE** (67108864): 当玩家因 Bot 替换而被踢出时，标记为闲置状态
- **IN_TAKEOVER** (134217728): 当玩家重新接管 Bot 时触发

`st_mr_allow_record_idle` 控制是否录制这些标志位。

### 7.7 IN_FREE_ANGLE

**IN_FREE_ANGLE** (268435456) 标志位让回放保持玩家的原始视角不变。可以用于调试，但不建议在常规回放中使用。可通过 `st_mr_allow_free_angle` ConVar 全局启用。

### 7.8 主机输入转发

当 `st_mr_allow_host_inputs` 为 1 时，回放过程中会将攻击(+attack)和下蹲(+duck)指令发送到主机控制台。这主要用于非专用服务器上的回放。

### 7.9 特殊辅助功能

当 `st_mr_allow_playback_special_helpers` 为 1 (默认) 时，回放开始时自动执行:
- 调用 `SpeedrunStart()` 重置计时器
- 执行 `nb_delete_all infected` 移除所有感染者

---

## 8. VScript 回调

插件提供了两个 forward，可以在 VScript 中 Hook:

### 8.1 OnPlayEnd

回放结束时触发:

```c++
function OnPlayEnd(self, filename)
{
    // filename: 回放的文件名
}
```

### 8.2 OnPlayLine

每帧回放时触发:

```c++
function OnPlayLine(self, filename, tick, buttons)
{
    // filename: 回放的文件名
    // tick: 当前帧号 (+3)
    // buttons: 当前帧的按键掩码
}
```

---

## 9. 注意事项

1. **插件加载优先级**: 插件需要在 `sm_bhop` 等插件之前加载，避免冲突
2. **分割限制**: Goto 模式后立即分割可能因标志位不匹配导致回放异常
3. **门交互**: 回放中的门交互 (+use) 仅部分有效，单个按压可成功但持续按住效果不佳
4. **声音**: 回放时武器开火声音已在插件中模拟处理
5. **多次录制**: 1.4 版本后支持同时录制/分割多个玩家的移动
