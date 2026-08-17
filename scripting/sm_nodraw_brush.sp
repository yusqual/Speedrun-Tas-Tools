//SourcePawn

/**:
 * @brief 只绘制地图中的 NoDraw 静态 brush 表面 (SourceMod 版)
 *
 * 网格射线扫描: 以玩家(或准星固定点)为中心的盒状区域, 按网格发射射线,
 * 命中世界几何且表面带 SURF_NODRAW 标志时, 将连续命中点连成网格线标记
 * (墙面每个高度一条水平线, 地面横竖网格), 光束量少以避免超出临时实体投递上限。
 * 用于速通观察路线时看清完全透明的 NoDraw 墙 / 地面 / 平台。
 *
 * 命令:
 *   sm_nodraw          切换开关(跟随玩家)
 *   sm_nodraw on/off   开启 / 关闭
 *   sm_nodraw_pin      切换扫描中心固定到准星指向位置
 *
 * 说明: 只覆盖世界静态 brush (NoDraw)。func_brush 实体、透明位移面暂不绘制。
 * sm_nodraw_floor 0 可关闭地面网格, 为墙面释放光束预算。
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

// 墙面扫描高度 (相对扫描中心, 由 sm_nodraw_heights 动态解析)
float g_fWallHeights[64];
int g_iWallHeightCount;

// 网格线相对表面法线的外移量 (单位), 避免贴面被深度遮挡
#define ND_LINE_OFFSET   4.0
// 孤立命中点的 stub 长度 (单位)
#define ND_STUB_LEN      8.0
// 地面网格线相邻列高度差容差 (单位), 超过则视为不同表面
#define ND_Z_TOLERANCE   12.0
// 网格列数上限 (防止极端参数导致 trace 过多)
#define ND_MAX_GRID      64
// 每列竖直向下最多穿透的表面层数
#define ND_MAX_LAYERS    6

// 每客户端状态
bool g_bEnabled[MAXPLAYERS + 1];
bool g_bPinned[MAXPLAYERS + 1];
float g_fPinPos[MAXPLAYERS + 1][3];

ConVar g_hRadius;
ConVar g_hGrid;
ConVar g_hAbove;
ConVar g_hBelow;
ConVar g_hInterval;
ConVar g_hColor;
ConVar g_hColorFloor;
ConVar g_hHeights;
ConVar g_hDebug;
ConVar g_hMaxBeams;
ConVar g_hFloor;

Handle g_hScanTimer;
int g_iSprite = -1;

// 单次扫描发送的光束计数 (调试用)
int g_iScanBeams;

/**
 * @brief 插件启动: 注册命令 / ConVar / 定时器。
 */
public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    g_hRadius   = CreateConVar("sm_nodraw_radius",   "640.0",   "扫描半宽 (单位)");
    g_hGrid     = CreateConVar("sm_nodraw_grid",     "80.0",    "网格间距 (单位), 越小越密也越耗性能");
    g_hAbove    = CreateConVar("sm_nodraw_above",    "384.0",   "扫描竖直范围: 扫描中心以上 (单位)");
    g_hBelow    = CreateConVar("sm_nodraw_below",    "-96.0",   "扫描竖直范围: 扫描中心以下 (单位)");
    g_hInterval = CreateConVar("sm_nodraw_interval", "0.1",     "刷新间隔 (秒)");
    g_hColor      = CreateConVar("sm_nodraw_color",    "255 200 0", "墙面 NoDraw 网格线颜色 (R G B)");
    g_hColorFloor = CreateConVar("sm_nodraw_color_floor", "80 255 120", "地面 NoDraw 网格线颜色 (R G B)");
    g_hHeights    = CreateConVar("sm_nodraw_heights",  "0 64 160 288", "墙面扫描高度列表 (空格分隔, 相对扫描中心, 单位)");
    g_hDebug      = CreateConVar("sm_nodraw_debug",    "0",         "为 1 时每次扫描后向服务器控制台打印光束数量");
    g_hMaxBeams   = CreateConVar("sm_nodraw_maxbeams", "200",       "单次扫描光束预算, 超过则截断绘制 (0 表示不限制)");
    g_hFloor      = CreateConVar("sm_nodraw_floor",    "1",         "是否绘制地面网格线 (0 关闭, 1 开启)。关闭可为墙面释放光束预算");

    g_hInterval.AddChangeHook(ND_OnConVarChanged);
    g_hHeights.AddChangeHook(ND_OnHeightsChanged);
    ND_ParseHeights();

    RegConsoleCmd("sm_nodraw", Cmd_NoDraw);
    RegConsoleCmd("sm_nodraw_pin", Cmd_NoDrawPin);

    AutoExecConfig(true, "sm_nodraw_brush");

    g_hScanTimer = CreateTimer(g_hInterval.FloatValue, ND_ScanTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief 地图开始: 加载并预缓存光束模型。
 */
public void OnMapStart()
{
    char path[PLATFORM_MAX_PATH];
    Handle gc = LoadGameConfigFile("funcommands.games");
    if (gc != null)
    {
        if (GameConfGetKeyValue(gc, "SpriteBeam", path, sizeof(path)) && path[0])
            g_iSprite = PrecacheModel(path, true);
        delete gc;
    }
    if (g_iSprite <= 0)
        g_iSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

/**
 * @brief 客户端断开: 清理状态。
 *
 * @param client   客户端索引。
 */
public void OnClientDisconnect(int client)
{
    g_bEnabled[client] = false;
    g_bPinned[client] = false;
}

/**
 * @brief 间隔 ConVar 变化: 重建定时器以应用新刷新间隔。
 */
public void ND_OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    KillTimer(g_hScanTimer);
    g_hScanTimer = CreateTimer(convar.FloatValue, ND_ScanTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief 墙面高度 ConVar 变化: 重新解析高度列表。
 */
public void ND_OnHeightsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ND_ParseHeights();
}

/**
 * @brief 解析 sm_nodraw_heights 高度列表到缓存数组。
 */
public void ND_ParseHeights()
{
    char buf[256];
    g_hHeights.GetString(buf, sizeof(buf));

    char parts[64][16];
    int count = ExplodeString(buf, " ", parts, 64, sizeof(parts[]));
    g_iWallHeightCount = count;
    for (int i = 0; i < count; i++)
        g_fWallHeights[i] = StringToFloat(parts[i]);
}

/**
 * @brief 定时器回调: 为每个开启的客户端执行扫描。
 *
 * @return          继续循环。
 */
public Action ND_ScanTimer(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (g_bEnabled[client] && IsClientInGame(client))
            ND_ScanForClient(client);
    }
    return Plugin_Continue;
}

/**
 * @brief sm_nodraw 命令: 切换 / 开关 NoDraw 可视化。
 *
 * @param client   命令发起者。
 * @param args     参数个数(可选 on/off/0/1)。
 * @return         已处理。
 */
public Action Cmd_NoDraw(int client, int args)
{
    int target = ND_GetTarget(client);
    if (target == 0)
    {
        ReplyToCommand(client, "[NoDraw] 没有可用的游戏内客户端。");
        return Plugin_Handled;
    }

    bool enable;
    char arg[8];
    if (args >= 1 && GetCmdArg(1, arg, sizeof(arg)))
    {
        if (StrEqual(arg, "on", false) || StrEqual(arg, "1", false))
            enable = true;
        else if (StrEqual(arg, "off", false) || StrEqual(arg, "0", false))
            enable = false;
        else
            enable = !g_bEnabled[target];
    }
    else
    {
        enable = !g_bEnabled[target];
    }

    g_bEnabled[target] = enable;
    if (!enable)
        g_bPinned[target] = false;

    ND_PrintReply(client, target, enable ? "已开启 NoDraw brush 可视化" : "已关闭 NoDraw brush 可视化");
    return Plugin_Handled;
}

/**
 * @brief sm_nodraw_pin 命令: 切换扫描中心固定到准星指向位置。
 *
 * @param client   命令发起者。
 * @param args     参数个数。
 * @return         已处理。
 */
public Action Cmd_NoDrawPin(int client, int args)
{
    int target = ND_GetTarget(client);
    if (target == 0)
    {
        ReplyToCommand(client, "[NoDraw] 没有可用的游戏内客户端。");
        return Plugin_Handled;
    }

    g_bPinned[target] = !g_bPinned[target];
    if (g_bPinned[target])
    {
        float origin[3], angles[3], fwd[3], right[3], up[3], end[3];
        GetClientEyePosition(target, origin);
        GetClientEyeAngles(target, angles);
        GetAngleVectors(angles, fwd, right, up);
        end[0] = origin[0] + fwd[0] * 4096.0;
        end[1] = origin[1] + fwd[1] * 4096.0;
        end[2] = origin[2] + fwd[2] * 4096.0;

        TR_TraceRayFilter(origin, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, ND_FilterWorldOnly);
        if (TR_DidHit())
        {
            TR_GetEndPosition(g_fPinPos[target]);
            ND_PrintReply(client, target, "扫描中心已固定到准星位置");
        }
        else
        {
            g_bPinned[target] = false;
            ND_PrintReply(client, target, "准星未命中任何世界几何");
        }
    }
    else
    {
        ND_PrintReply(client, target, "扫描中心恢复跟随玩家");
    }
    return Plugin_Handled;
}

/**
 * @brief 解析命令目标客户端: 客户端命令返回其自身; 服务器控制台触发时回退到第一个游戏内人类玩家。
 *
 * @param client   命令发起者 (0 表示服务器控制台)。
 * @return         目标客户端索引, 无可用客户端时返回 0。
 */
public int ND_GetTarget(int client)
{
    if (client != 0 && IsClientInGame(client))
        return client;

    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            return i;
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i))
            return i;
    return 0;
}

/**
 * @brief 命令反馈输出: 客户端触发走聊天, 服务器控制台触发打印到服务器控制台。
 *
 * @param client   命令发起者 (0 表示服务器控制台)。
 * @param target   实际生效的目标客户端。
 * @param msg      消息内容。
 */
public void ND_PrintReply(int client, int target, const char[] msg)
{
    if (client != 0)
        PrintToChat(client, "\x04[NoDraw]\x01 %s", msg);
    else if (target != 0)
        PrintToServer("[NoDraw] %s (客户端 #%d)", msg, target);
    else
        PrintToServer("[NoDraw] %s", msg);
}

/**
 * @brief 射线过滤器: 跳过所有实体, 只允许命中世界几何 (brush)。
 *
 * @param entity          射线命中的实体索引。
 * @param contentsMask    内容掩码。
 * @return                true 允许命中该实体, false 跳过。世界实体(index 0)始终返回 true。
 */
public bool ND_FilterWorldOnly(int entity, int contentsMask)
{
    return (entity == 0);
}

/**
 * @brief 为指定客户端执行一次完整扫描并绘制 NoDraw 网格线标记。
 *
 * 绘制顺序: 地面网格优先 (最易被遮挡, 保底), 再画墙面水平线, 最后画扫描盒轮廓。
 * 超出 sm_nodraw_maxbeams 预算时后绘制的部分会被截断。
 * sm_nodraw_floor 为 0 时跳过地面网格, 为墙面释放光束预算。
 * 墙面: 每个高度层沿 X/Y 双向扫描 (单向会漏掉射线路径上较远一侧的墙, 必须双向), 连续命中同一表面的点连成水平线。
 * 地面: 横竖两遍扫描, 高度一致的连续命中点连成网格线。
 *
 * @param client   目标客户端索引。
 */
public void ND_ScanForClient(int client)
{
    float radius = g_hRadius.FloatValue;
    float grid = g_hGrid.FloatValue;
    if (radius < 64.0) radius = 64.0;
    if (grid < 16.0) grid = 16.0;
    float life = g_hInterval.FloatValue * 3.0;
    if (life < 0.3) life = 0.3;

    g_iScanBeams = 0;

    int color[4], colorFloor[4];
    ND_GetColor(g_hColor, color);
    ND_GetColor(g_hColorFloor, colorFloor);

    float center[3];
    if (g_bPinned[client])
    {
        center = g_fPinPos[client];
    }
    else
    {
        float origin[3];
        GetClientAbsOrigin(client, origin);
        center[0] = ND_Snap(origin[0], grid);
        center[1] = ND_Snap(origin[1], grid);
        center[2] = origin[2];
    }

    float minX = center[0] - radius, maxX = center[0] + radius;
    float minY = center[1] - radius, maxY = center[1] + radius;
    float topZ = center[2] + g_hAbove.FloatValue;
    float botZ = center[2] + g_hBelow.FloatValue;
    int n = RoundToFloor(radius * 2.0 / grid) + 1;
    if (n > ND_MAX_GRID) n = ND_MAX_GRID;

    // 地面网格线优先绘制 (最易被遮挡, 保底): 横 (沿 X) 竖 (沿 Y) 两遍扫描
    if (g_hFloor.IntValue)
    {
        ND_FloorLinePass(client, minX, minY, topZ, botZ, grid, n, life, colorFloor, 0);
        ND_FloorLinePass(client, minX, minY, topZ, botZ, grid, n, life, colorFloor, 1);
    }

    // 墙面网格线: 每个高度层沿 X/Y 双向扫描 (单向会漏掉射线路径上较远一侧的墙)
    for (int h = 0; h < g_iWallHeightCount; h++)
    {
        float z = center[2] + g_fWallHeights[h];
        ND_WallLinePass(client, minX, maxX, minY, maxY, z, grid, n, life, color, 0, true);
        ND_WallLinePass(client, minX, maxX, minY, maxY, z, grid, n, life, color, 0, false);
        ND_WallLinePass(client, minX, maxX, minY, maxY, z, grid, n, life, color, 1, true);
        ND_WallLinePass(client, minX, maxX, minY, maxY, z, grid, n, life, color, 1, false);
    }

    // 扫描范围轮廓 (最后绘制, 超出光束预算时会被截断)
    ND_DrawBoxOutline(client, minX, minY, maxX, maxY, topZ, botZ, life);

    if (g_hDebug.IntValue)
        PrintToServer("[NoDraw] scan: %d beams", g_iScanBeams);
}

/**
 * @brief 读取当前 TR 结果: 是否命中世界 NoDraw 表面, 并输出命中点与法线。
 *
 * @param[out] pos       命中点坐标。
 * @param[out] normal    命中表面法线。
 * @return               true 表示命中 NoDraw 世界表面。
 */
public bool ND_HitNodraw(float pos[3], float normal[3])
{
    if (!TR_DidHit() || !(TR_GetSurfaceFlags() & SURF_NODRAW))
        return false;
    TR_GetEndPosition(pos);
    TR_GetPlaneNormal(INVALID_HANDLE, normal);
    return true;
}

/**
 * @brief 墙面单方向扫描: 沿轴从一侧射向另一侧, 连续命中同一表面的点连成一条线。
 *
 * 必须对同一高度正反两向各扫一遍 (fwd true/false), 否则射线只会命中路径上
 * 离起点最近的那面墙, 玩家面对方向的墙会被漏掉。射线起点已处于实体内时
 * (负高度位于地面以下等) 该列命中结果无意义, 直接跳过。
 *
 * @param client   目标客户端索引。
 * @param minX     扫描盒最小 X。
 * @param maxX     扫描盒最大 X。
 * @param minY     扫描盒最小 Y。
 * @param maxY     扫描盒最大 Y。
 * @param z        当前高度层 Z。
 * @param grid     网格间距。
 * @param n        网格列数。
 * @param life     光束存活时长。
 * @param color    标记颜色。
 * @param axis     0 = 沿 X 发射 (固定 y), 1 = 沿 Y 发射 (固定 x)。
 * @param fwd      true = 从 min 侧射向 max 侧, false = 反向。
 */
public void ND_WallLinePass(int client, float minX, float maxX, float minY, float maxY, float z, float grid, int n, float life, const int color[4], int axis, bool fwd)
{
    int runCount = 0;
    float runA[3], runB[3], runN[3];

    for (int i = 0; i < n; i++)
    {
        float s[3], e[3];
        if (axis == 0)
        {
            float y = minY + i * grid;
            s[0] = fwd ? minX : maxX; s[1] = y; s[2] = z;
            e[0] = fwd ? maxX : minX; e[1] = y; e[2] = z;
        }
        else
        {
            float x = minX + i * grid;
            s[0] = x; s[1] = fwd ? minY : maxY; s[2] = z;
            e[0] = x; e[1] = fwd ? maxY : minY; e[2] = z;
        }

        TR_TraceRayFilter(s, e, MASK_SOLID_BRUSHONLY, RayType_EndPoint, ND_FilterWorldOnly);
        if (TR_StartSolid())
        {
            // 起点已在实体内 (如负高度在地面以下): 命中为实体背面, 跳过该列
            if (runCount > 0)
            {
                ND_FlushWallRun(client, runA, runB, runN, runCount, life, color);
                runCount = 0;
            }
            continue;
        }
        float pos[3], normal[3];
        if (ND_HitNodraw(pos, normal))
        {
            if (runCount == 0)
            {
                runA = pos; runB = pos; runN = normal;
                runCount = 1;
            }
            else if (GetVectorDotProduct(runN, normal) > 0.9
                     && ND_RunContiguous(runB, pos, grid, axis))
            {
                runB = pos;
                runCount++;
            }
            else
            {
                ND_FlushWallRun(client, runA, runB, runN, runCount, life, color);
                runA = pos; runB = pos; runN = normal;
                runCount = 1;
            }
        }
        else if (runCount > 0)
        {
            ND_FlushWallRun(client, runA, runB, runN, runCount, life, color);
            runCount = 0;
        }
    }
    if (runCount > 0)
        ND_FlushWallRun(client, runA, runB, runN, runCount, life, color);
}

/**
 * @brief 收束墙面扫描的一段连续命中: 连成一条线或画孤立 stub。
 *
 * @param client   目标客户端索引。
 * @param a        段起点。
 * @param b        段终点。
 * @param normal   段表面法线。
 * @param count    段内命中点数。
 * @param life     光束存活时长。
 * @param color    标记颜色。
 */
public void ND_FlushWallRun(int client, const float a[3], const float b[3], const float normal[3], int count, float life, const int color[4])
{
    float p0[3], p1[3];
    if (count == 1)
    {
        // 孤立命中点: 画沿法线的短 stub
        for (int i = 0; i < 3; i++)
        {
            p0[i] = a[i];
            p1[i] = a[i] + normal[i] * ND_STUB_LEN;
        }
    }
    else
    {
        // 连续命中: 首尾连线, 两端沿法线外移避免贴面被深度遮挡
        for (int i = 0; i < 3; i++)
        {
            p0[i] = a[i] + normal[i] * ND_LINE_OFFSET;
            p1[i] = b[i] + normal[i] * ND_LINE_OFFSET;
        }
    }
    ND_DrawBeam(client, p0, p1, life, color);
}

/**
 * @brief 判断两个命中点是否属于相邻网格列上的同一连续表面。
 *
 * 沿扫描方向 (axis) 的坐标间距应约等于 grid, 垂直方向位移须有界;
 * 否则视为跨表面跳跃 (如墙的端面与相邻垂直墙), 不得连线。
 *
 * @param a       前一命中点。
 * @param b       当前命中点。
 * @param grid    网格间距。
 * @param axis    扫描轴 (0 = 沿 X, 1 = 沿 Y)。
 * @return        true 表示连续, 可加入同一条线。
 */
public bool ND_RunContiguous(const float a[3], const float b[3], float grid, int axis)
{
    float dAlong, dAcross;
    if (axis == 0)
    {
        dAlong = FloatAbs(b[1] - a[1]);
        dAcross = FloatAbs(b[0] - a[0]);
    }
    else
    {
        dAlong = FloatAbs(b[0] - a[0]);
        dAcross = FloatAbs(b[1] - a[1]);
    }
    if (dAlong < grid * 0.5 || dAlong > grid * 1.5)
        return false;
    if (dAcross > grid * 0.75)
        return false;
    return true;
}

/**
 * @brief 地面单方向扫描: 沿轴逐列垂直向下射线, 高度一致的连续命中连成网格线。
 *
 * 每列从 topZ 向下逐层穿透非 NoDraw 表面, 取第一个 NoDraw 面的 z 参与连线,
 * 避免普通天花板/楼层遮挡脚下 NoDraw 地面。
 * 假设地面为水平面, 线条端点沿 Z 抬高 ND_LINE_OFFSET 避免贴面。
 *
 * @param client   目标客户端索引。
 * @param minX     扫描盒最小 X。
 * @param minY     扫描盒最小 Y。
 * @param topZ     扫描盒顶部 Z。
 * @param botZ     扫描盒底部 Z。
 * @param grid     网格间距。
 * @param n        网格列数。
 * @param life     光束存活时长。
 * @param color    标记颜色。
 * @param axis     0 = 沿 X 连线 (固定 y), 1 = 沿 Y 连线 (固定 x)。
 */
public void ND_FloorLinePass(int client, float minX, float minY, float topZ, float botZ, float grid, int n, float life, const int color[4], int axis)
{
    for (int outer = 0; outer < n; outer++)
    {
        int runCount = 0;
        float runA[3], runB[3];

        for (int inner = 0; inner < n; inner++)
        {
            float x, y;
            if (axis == 0)
            {
                y = minY + outer * grid;
                x = minX + inner * grid;
            }
            else
            {
                x = minX + outer * grid;
                y = minY + inner * grid;
            }

            // 该列从 topZ 向下穿透非 NoDraw 层, 取最上方 NoDraw 面
            float z = topZ;
            bool bHit = false;
            float pos[3];
            for (int k = 0; k < ND_MAX_LAYERS; k++)
            {
                float s[3], e[3];
                s[0] = x; s[1] = y; s[2] = z;
                e[0] = x; e[1] = y; e[2] = botZ;
                TR_TraceRayFilter(s, e, MASK_SOLID_BRUSHONLY, RayType_EndPoint, ND_FilterWorldOnly);
                if (!TR_DidHit())
                    break;
                TR_GetEndPosition(pos);
                if (TR_GetSurfaceFlags() & SURF_NODRAW)
                {
                    bHit = true;
                    break;
                }
                z = pos[2] - 1.0;
            }

            if (bHit)
            {
                if (runCount == 0)
                {
                    runA = pos; runB = pos;
                    runCount = 1;
                }
                else if (FloatAbs(pos[2] - runB[2]) <= ND_Z_TOLERANCE)
                {
                    runB = pos;
                    runCount++;
                }
                else
                {
                    ND_FlushFloorRun(client, runA, runB, runCount, life, color);
                    runA = pos; runB = pos;
                    runCount = 1;
                }
            }
            else if (runCount > 0)
            {
                ND_FlushFloorRun(client, runA, runB, runCount, life, color);
                runCount = 0;
            }
        }
        if (runCount > 0)
            ND_FlushFloorRun(client, runA, runB, runCount, life, color);
    }
}

/**
 * @brief 收束地面扫描的一段连续命中: 连成一条线或画孤立 stub。
 *
 * @param client   目标客户端索引。
 * @param a        段起点。
 * @param b        段终点。
 * @param count    段内命中点数。
 * @param life     光束存活时长。
 * @param color    标记颜色。
 */
public void ND_FlushFloorRun(int client, const float a[3], const float b[3], int count, float life, const int color[4])
{
    float p0[3], p1[3];
    if (count == 1)
    {
        // 孤立命中点: 画竖直 stub
        for (int i = 0; i < 3; i++)
        {
            p0[i] = a[i];
            p1[i] = a[i];
        }
        p1[2] += ND_STUB_LEN;
    }
    else
    {
        // 连续命中: 首尾连线, 两端抬高避免贴面
        for (int i = 0; i < 3; i++)
        {
            p0[i] = a[i];
            p1[i] = b[i];
        }
        p0[2] += ND_LINE_OFFSET;
        p1[2] += ND_LINE_OFFSET;
    }
    ND_DrawBeam(client, p0, p1, life, color);
}

/**
 * @brief 向指定客户端发送一条光束。
 *
 * 超过 sm_nodraw_maxbeams 预算时不再发送, 用于防止临时实体投递超限导致全部光束被丢弃。
 *
 * @param client   目标客户端索引。
 * @param start    光束起点。
 * @param end      光束终点。
 * @param life     存活时长。
 * @param color    颜色 (RGBA)。
 */
public void ND_DrawBeam(int client, const float start[3], const float end[3], float life, const int color[4])
{
    if (g_iSprite <= 0)
        return;
    if (g_hMaxBeams.IntValue > 0 && g_iScanBeams >= g_hMaxBeams.IntValue)
        return;
    g_iScanBeams++;
    TE_SetupBeamPoints(start, end, g_iSprite, 0, 0, 0, life, 2.0, 2.0, 5, 0.0, color, 0);
    TE_SendToClient(client);
}

/**
 * @brief 绘制扫描盒轮廓 (青色), 便于观察扫描范围。
 *
 * @param client   目标客户端索引。
 * @param minX     盒最小 X。
 * @param minY     盒最小 Y。
 * @param maxX     盒最大 X。
 * @param maxY     盒最大 Y。
 * @param topZ     盒顶部 Z。
 * @param botZ     盒底部 Z。
 * @param life     光束存活时长。
 */
public void ND_DrawBoxOutline(int client, float minX, float minY, float maxX, float maxY, float topZ, float botZ, float life)
{
    int cyan[4] = { 0, 255, 255, 255 };
    float pts[8][3];
    pts[0][0] = minX; pts[0][1] = minY; pts[0][2] = topZ;
    pts[1][0] = maxX; pts[1][1] = minY; pts[1][2] = topZ;
    pts[2][0] = maxX; pts[2][1] = maxY; pts[2][2] = topZ;
    pts[3][0] = minX; pts[3][1] = maxY; pts[3][2] = topZ;
    pts[4][0] = minX; pts[4][1] = minY; pts[4][2] = botZ;
    pts[5][0] = maxX; pts[5][1] = minY; pts[5][2] = botZ;
    pts[6][0] = maxX; pts[6][1] = maxY; pts[6][2] = botZ;
    pts[7][0] = minX; pts[7][1] = maxY; pts[7][2] = botZ;
    int edges[12][2] = {
        {0,1},{1,2},{2,3},{3,0},
        {4,5},{5,6},{6,7},{7,4},
        {0,4},{1,5},{2,6},{3,7}
    };
    for (int i = 0; i < 12; i++)
        ND_DrawBeam(client, pts[edges[i][0]], pts[edges[i][1]], life, cyan);
}

/**
 * @brief 将数值对齐到网格。
 *
 * @param value   待对齐数值。
 * @param grid    网格间距。
 * @return        对齐后的数值。
 */
public float ND_Snap(float value, float grid)
{
    return RoundToFloor(value / grid + 0.5) * grid;
}

/**
 * @brief 解析颜色 ConVar ("R G B") 到 RGBA 数组。
 *
 * @param cv       颜色 ConVar。
 * @param[out] color   输出颜色数组 (RGBA)。
 */
public void ND_GetColor(ConVar cv, int[] color)
{
    char buf[64];
    cv.GetString(buf, sizeof(buf));

    color[0] = 255; color[1] = 200; color[2] = 0;
    char parts[3][8];
    int count = ExplodeString(buf, " ", parts, 3, sizeof(parts[]));
    for (int i = 0; i < count; i++)
        color[i] = StringToInt(parts[i]);
    color[3] = 255;
}
