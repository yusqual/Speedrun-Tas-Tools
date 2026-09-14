# Speedrun TAS Tools 更新日志

记录 L4D2 速跑 TAS 工具（SourceMod 插件 + VScript）的功能变更与修复。

## 未发布

### STR 回放

- **修复多人联机播放时动作键失效**：远程真人客户端播放 Replay 时不触发按 E（使用）/ 右键（推击）/ 左键（开火）等问题。原因：动作键此前仅通过 `ClientCommand` 下发到客户端本机执行，对远程联机客户端不可靠；现改为同时合并进服务端 `buttons` 掩码，由服务端判定并同步（门交互/推击/开火均为服务端逻辑）。MR 兼容模式与非 MR 模式均已修复。

### 文档

- `str-guide.md` 补充按键注入方式说明（掩码合并与 `ClientCommand` 的适用场景）。

## 2026-09

### 新增

- STR 回放新增 **MR 形式播放方式**（`str_replay_stuck_repro`，默认开启）：采用类似 MR 的物理还原方式（origin → velocity → angles、按键掩码合并、不强制恢复 MOVETYPE_WALK），复现斜坡蹲起卡住状态。
- `NoDrawBrush` 增加 PluginInfo。
- `SpawnWeaponEx` 支持生成掉落武器实体。

## 2026-08

### 新增

- 添加**天空盒绘制**功能。
- 使用 VScript 绘制线条，支持墙面与地板绘制；墙面横线绘制改为**网格线**。
- 新增 `nodraw_brush` 功能。

### 移除

- 移除早期临时射线方案代码与冗余文件。

## 2026-07

### 新增

- `str_extensions.nut` 新增 `SpawnWeaponEx` 武器生成函数（含上膛弹数/备弹/升级参数），并补充文档（str-guide §6.2.2）。
- 新增 `ST_STR_SwitchSlot`（切换玩家武器槽位 1-5）与 `ST_TriggerTeleport` 回调方式触发。

### 文档

- 文档统一更新：Hexo frontmatter、代码块类型统一为 CPP。

## 2026-06

### 新增

- STR 添加 **VScript 钩子函数**：`OnPlayTick`（含帧号与文件名参数）、`OnRecordTick`、`OnPlayTickEnd`，VScript 侧可按 tick 感知录制/播放进度。

## 2026-05

### 重构

- 主插件由单文件拆分为模块结构：`STAPlayer`（玩家状态）、`ReplayRecording`（录制）、`ReplayPlayback`（播放+平滑插值）、`ReplayFileIO`（文件读写）、`ReplayCommands`（命令+菜单+轨迹绘制），`.STR` 文件格式保持兼容。
- 修复重构引入的问题：
  1. 播放后"跳转到结尾"不设置玩家位置信息；
  2. 播放中使用自由视角后不自动恢复原始倍速；
  3. tick/时间 HUD 显示异常。

### 新增

- 添加 VScript ConVar 设置接口、调试菜单，封装 Squirrel 脚本函数（`str_commands.nut`：`ST_STR` / `ST_STRSave` 等）。
- 新增 MR 菜单。
- 新增 **Debug HUD**（VScript HUD 显示按键/帧号/速度等）。

### 修复

- **多人联机同步**：多名玩家统一起始 tick 开始播放。
- **爬梯问题**（系列修复）：FakeClient 无法吸附爬梯（`InjectPlaybackButtons` 对爬梯帧下发 ClientCommand、设置 wishvel 方向向量加速引擎识别爬梯意图）；视角朝上异常；爬梯导致的速度异常；爬梯动作异常。
- 修复转为录制时按键卡住问题；接管后下一 tick 加载/播放卡在 0 tick 暂停状态；闲置接管帧加载播放 STR 被 block 的问题。
- `OnMapStart` 中为每槽位重新排队 `ResetButton`：修复地图过渡后 `+attack` 等按键卡死（跨地图 RequestFrame 回调丢失）。
- 修复过关状态未重置 bug。
- 代码缩进统一：制表符 → 4 空格。

## 2026-02

### 新增

- 新增**仅设置速度**模式（`str_onlysetvel`）：回放时不设置坐标和视角。

### 修复

- 修复爬梯导致的速度异常与爬梯动作问题。
