//SourcePawn

/**
 * @brief 扫描全图一次并绘制地图中的 NoDraw / SkyBox 静态 brush 表面。
 *
 * 通过网格射线扫描地图包围盒内的世界几何, 命中带 SURF_NODRAW 或 SURF_SKY 标志的表面时,
 * 用 VScript DebugDrawLine 绘制持久网格线 (墙面水平+垂直网格, 地面横竖网格)。
 * 仅需执行一次命令, 不依赖定时器持续刷新, 用于速通观察完全透明的 NoDraw 墙/地面/平台及天空盒。
 *
 * 命令:
 *   sm_nodraw_map [0/1/2]
 *                       扫描全图一次并绘制 brush 表面
 *                       0 = 全部绘制(默认), 1 = 只绘制墙面, 2 = 只绘制地板
 *   sm_nodraw_clear    清除 VScript DebugDrawLine 绘制
 *
 * 说明: 只覆盖世界静态 brush。func_brush 实体、透明位移面暂不绘制。
 * sm_nodraw_scan_nodraw 1 时扫描 NoDraw 表面, sm_nodraw_scan_skybox 1 时扫描天空盒表面。
 * sm_nodraw_floor 0 可关闭地面网格, 为墙面释放扫描预算。
 * sm_nodraw_wall_grid 1 时墙面绘制水平+垂直网格线, 0 仅水平线。
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "NoDrawBrush",
    author = "Yusqual",
    description = "Draw nodraw & skybox brush.",
    version = "1.0",
    url = "none"
};


// 网格线相对表面法线的外移量 (单位), 避免贴面被深度遮挡
#define ND_LINE_OFFSET   4.0
// 孤立命中点的 stub 长度 (单位)
#define ND_STUB_LEN      8.0
// 地面网格线相邻列高度差容差 (单位), 超过则视为不同表面
#define ND_Z_TOLERANCE   12.0
// 分块墙面扫描列数上限 (防止单块 trace 过多)
#define ND_MAX_GRID      64
// 全图扫描网格列数上限 (防止单次全图 trace 过多)
#define ND_MAX_MAP_GRID  200
// 每列竖直向下最多穿透的表面层数
#define ND_MAX_LAYERS    6

ConVar g_hColor;
ConVar g_hColorFloor;
ConVar g_hDebug;
ConVar g_hFloor;
ConVar g_hMapGrid;
ConVar g_hMapRadius;
ConVar g_hMapTile;
ConVar g_hWallGrid;
ConVar g_hScanNoDraw;
ConVar g_hScanSky;
ConVar g_hColorSky;

// 单次扫描发送的线段计数 (调试用)
int g_iScanBeams;

/**
 * @brief 插件启动: 注册 ConVar 和命令。
 */
public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    g_hColor      = CreateConVar("sm_nodraw_color",    "255 200 0", "墙面 NoDraw 网格线颜色 (R G B)");
    g_hColorFloor = CreateConVar("sm_nodraw_color_floor", "80 255 120", "地面 NoDraw 网格线颜色 (R G B)");
    g_hDebug      = CreateConVar("sm_nodraw_debug",    "0",         "为 1 时扫描后向服务器控制台打印线段数量");
    g_hFloor      = CreateConVar("sm_nodraw_floor",    "1",         "是否绘制地面网格线 (0 关闭, 1 开启)");
    g_hMapGrid    = CreateConVar("sm_nodraw_map_grid", "32.0",     "全图扫描网格间距 (单位), 越大越快越稀疏");
    g_hMapRadius  = CreateConVar("sm_nodraw_map_radius", "12000.0", "无法获取地图边界时, 以玩家位置为中心的扫描半宽 (单位)");
    g_hMapTile    = CreateConVar("sm_nodraw_map_tile", "1024.0",    "全图扫描墙面时的分块大小 (单位), 越小越接近局部命中效果, 也越慢");
    g_hWallGrid   = CreateConVar("sm_nodraw_wall_grid", "1",         "全图扫描墙面是否绘制垂直网格线 (0 仅水平线, 1 水平+垂直)");
    g_hScanNoDraw = CreateConVar("sm_nodraw_scan_nodraw", "1",       "是否扫描 NoDraw 表面 (0 关闭, 1 开启)");
    g_hScanSky    = CreateConVar("sm_nodraw_scan_skybox", "0",       "是否扫描 SkyBox 天空盒表面 (0 关闭, 1 开启)");
    g_hColorSky   = CreateConVar("sm_nodraw_color_skybox", "100 180 255", "SkyBox 天空盒网格线颜色 (R G B)");

    RegConsoleCmd("sm_nodraw_map", Cmd_NoDrawMap);
    RegConsoleCmd("sm_nodraw_clear", Cmd_NoDrawClear);

    AutoExecConfig(true, "sm_nodraw_brush");
}

/**
 * @brief sm_nodraw_map 命令: 扫描全图一次并绘制指定类型的 brush 表面。
 *
 * 使用 VScript DebugDrawLine 绘制, 不受临时实体投递上限限制。
 * 扫描结束后无需定时器刷新, 线条持续 86400 秒。
 * 可选参数 0/1/2 控制绘制内容: 0 全部, 1 仅墙面, 2 仅地板。
 *
 * @param client   命令发起者。
 * @param args     参数个数。
 * @return         已处理。
 */
public Action Cmd_NoDrawMap(int client, int args)
{
    int target = ND_GetTarget(client);
    if (target == 0)
    {
        ReplyToCommand(client, "[NoDraw] 没有可用的游戏内客户端。");
        return Plugin_Handled;
    }

    int mode = 0;
    if (args >= 1)
    {
        char arg[8];
        GetCmdArg(1, arg, sizeof(arg));
        mode = StringToInt(arg);
        if (mode < 0 || mode > 2)
        {
            ReplyToCommand(client, "[NoDraw] 参数应为 0=全部绘制, 1=只绘制墙面, 2=只绘制地板");
            return Plugin_Handled;
        }
    }

    if (!g_hScanNoDraw.IntValue && !g_hScanSky.IntValue)
    {
        ReplyToCommand(client, "[NoDraw] 请先开启 sm_nodraw_scan_nodraw 或 sm_nodraw_scan_skybox");
        return Plugin_Handled;
    }

    ND_VScriptClear(target);
    ND_MapScanForClient(target, mode);

    if (mode == 0)
        ND_PrintReply(client, target, "已扫描全图并绘制 brush: 全部 (墙面+地板)");
    else if (mode == 1)
        ND_PrintReply(client, target, "已扫描全图并绘制 brush: 仅墙面");
    else
        ND_PrintReply(client, target, "已扫描全图并绘制 brush: 仅地板");
    return Plugin_Handled;
}

/**
 * @brief sm_nodraw_clear 命令: 清除 VScript DebugDrawLine 绘制的 NoDraw 标记。
 *
 * @param client   命令发起者。
 * @param args     参数个数。
 * @return         已处理。
 */
public Action Cmd_NoDrawClear(int client, int args)
{
    int target = ND_GetTarget(client);
    if (target == 0)
    {
        ReplyToCommand(client, "[NoDraw] 没有可用的游戏内客户端。");
        return Plugin_Handled;
    }

    ND_VScriptClear(target);
    ND_PrintReply(client, target, "已清除 NoDraw 全图绘制");
    return Plugin_Handled;
}

/**
 * @brief 获取地图世界几何边界 (worldspawn m_WorldMins/m_WorldMaxs)。
 *
 * 优先从 worldspawn 实体数据中读取地图包围盒; 若读取失败或包围盒无效,
 * 则以客户端当前位置为中心, 用 sm_nodraw_map_radius 构造方形包围盒作为回退。
 *
 * @param client       目标客户端索引, 用于回退时获取扫描中心。
 * @param[out] mins    地图包围盒最小坐标。
 * @param[out] maxs    地图包围盒最大坐标。
 * @return              true 表示成功读取到有效地图包围盒, false 表示使用了回退包围盒。
 */
public bool ND_GetMapBounds(int client, float mins[3], float maxs[3])
{
    int world = FindEntityByClassname(-1, "worldspawn");
    if (world == -1)
        world = 0;

    if (HasEntProp(world, Prop_Data, "m_WorldMins"))
    {
        GetEntPropVector(world, Prop_Data, "m_WorldMins", mins);
        GetEntPropVector(world, Prop_Data, "m_WorldMaxs", maxs);
        if (maxs[0] - mins[0] > 512.0 && maxs[1] - mins[1] > 512.0)
            return true;
    }
    if (HasEntProp(world, Prop_Send, "m_WorldMins"))
    {
        GetEntPropVector(world, Prop_Send, "m_WorldMins", mins);
        GetEntPropVector(world, Prop_Send, "m_WorldMaxs", maxs);
        if (maxs[0] - mins[0] > 512.0 && maxs[1] - mins[1] > 512.0)
            return true;
    }

    float center[3];
    GetClientAbsOrigin(client, center);
    float radius = g_hMapRadius.FloatValue;
    if (radius < 1024.0)
        radius = 1024.0;
    mins[0] = center[0] - radius; mins[1] = center[1] - radius; mins[2] = center[2] - radius;
    maxs[0] = center[0] + radius; maxs[1] = center[1] + radius; maxs[2] = center[2] + radius;
    return false;
}

/**
 * @brief 为指定客户端执行一次全图 brush 扫描, 并用 VScript DebugDrawLine 绘制。
 *
 * 根据 ConVar 开关分别扫描 NoDraw 与 SkyBox 表面, 扫描范围来自地图包围盒,
 * 线条持续 86400 秒, 不依赖定时器。墙面采用分块局部扫描, 避免长射线被
 * 首个可见表面挡住导致后方的目标墙面漏检。
 *
 * @param client   目标客户端索引。
 * @param mode     绘制内容: 0 = 全部, 1 = 仅墙面, 2 = 仅地板。
 */
public void ND_MapScanForClient(int client, int mode)
{
    float grid = g_hMapGrid.FloatValue;
    if (grid < 32.0)
        grid = 32.0;
    float life = 86400.0;

    g_iScanBeams = 0;

    int color[4], colorFloor[4], colorSky[4];
    ND_GetColor(g_hColor, color);
    ND_GetColor(g_hColorFloor, colorFloor);
    ND_GetColor(g_hColorSky, colorSky);

    float mins[3], maxs[3];
    ND_GetMapBounds(client, mins, maxs);

    float spanX = maxs[0] - mins[0];
    float spanY = maxs[1] - mins[1];
    float span = spanX > spanY ? spanX : spanY;
    float scanGrid = grid;
    int n = RoundToFloor(span / scanGrid) + 1;
    if (n > ND_MAX_MAP_GRID)
    {
        // 列数超限时自动放大网格间距, 保证覆盖全图而不是截断
        scanGrid = span / (ND_MAX_MAP_GRID - 1);
        n = ND_MAX_MAP_GRID;
    }

    float topZ = maxs[2] + 128.0;
    float botZ = mins[2] - 128.0;

    if (g_hScanNoDraw.IntValue)
    {
        ND_MapScanSurfaceForClient(client, mode, mins, maxs, scanGrid, n, topZ, botZ, life,
            SURF_NODRAW, color, colorFloor);
    }

    if (g_hScanSky.IntValue)
    {
        ND_MapScanSurfaceForClient(client, mode, mins, maxs, scanGrid, n, topZ, botZ, life,
            SURF_SKY, colorSky, colorSky);
    }

    // 地图包围盒轮廓 (仅全部绘制模式, 作为扫描范围参考)
    if (mode == 0)
        ND_DrawBoxOutline(client, mins[0], mins[1], maxs[0], maxs[1], topZ, botZ, life);

    if (g_hDebug.IntValue)
        PrintToServer("[NoDraw] map scan: %d lines", g_iScanBeams);
}

/**
 * @brief 按表面类型执行一次全图扫描: 绘制指定 SURF_* 类型的水平面和墙面。
 *
 * @param client        目标客户端索引。
 * @param mode          绘制内容: 0 = 全部, 1 = 仅墙面, 2 = 仅地板。
 * @param mins          地图包围盒最小坐标。
 * @param maxs          地图包围盒最大坐标。
 * @param scanGrid      水平网格间距 (可能已被自动放大)。
 * @param n             水平网格列数。
 * @param topZ          扫描顶部 Z。
 * @param botZ          扫描底部 Z。
 * @param life          线条持续时间 (秒)。
 * @param surfaceMask   SURF_* 位标志, 用于识别目标表面 (SURF_NODRAW 或 SURF_SKY)。
 * @param colorWall     墙面线条颜色 (RGBA)。
 * @param colorFloor    水平面线条颜色 (RGBA)。
 */
public void ND_MapScanSurfaceForClient(int client, int mode, const float mins[3], const float maxs[3], float scanGrid, int n, float topZ, float botZ, float life, int surfaceMask, const int colorWall[4], const int colorFloor[4])
{
    // 水平面 (地板/天花板): 0 = 全部, 2 = 仅地板
    if (mode != 1 && g_hFloor.IntValue)
    {
        ND_FloorLinePass(client, mins[0], mins[1], topZ, botZ, scanGrid, n, life, colorFloor, surfaceMask, 0);
        ND_FloorLinePass(client, mins[0], mins[1], topZ, botZ, scanGrid, n, life, colorFloor, surfaceMask, 1);
    }

    // 墙面: 0 = 全部, 1 = 仅墙面; 分块局部扫描, 每块大小 sm_nodraw_map_tile
    if (mode != 2)
        ND_MapScanWalls(client, mins, maxs, scanGrid, life, colorWall, surfaceMask);
}

/**
 * @brief 全图墙面分块扫描: 把地图包围盒切成小块, 逐块局部双向扫描目标墙面。
 *
 * 直接在地图包围盒上发射贯穿全图的长射线, 会被路径上第一个可见 brush 挡住,
 * 使后方的目标墙面全部漏检。这里改成以 sm_nodraw_map_tile 为块大小,
 * 逐块调用 ND_WallLinePass, 用短射线恢复局部目标墙面的命中效果。
 *
 * @param client       目标客户端索引。
 * @param mins         地图包围盒最小坐标。
 * @param maxs         地图包围盒最大坐标。
 * @param grid         网格间距 (可能已被自动放大)。
 * @param life         线条持续时间 (秒)。
 * @param color        墙面颜色 (RGBA)。
 * @param surfaceMask  SURF_* 位标志, 用于识别目标表面。
 */
public void ND_MapScanWalls(int client, const float mins[3], const float maxs[3], float grid, float life, const int color[4], int surfaceMask)
{
    float tile = g_hMapTile.FloatValue;
    if (tile < grid * 2.0)
        tile = grid * 2.0;

    float stride = tile - grid;
    if (stride < grid)
        stride = tile;

    int tileN = RoundToFloor(tile / grid) + 1;
    if (tileN > ND_MAX_GRID)
        tileN = ND_MAX_GRID;
    if (tileN < 2)
        tileN = 2;

    int tilesX = RoundToCeil((maxs[0] - mins[0]) / stride);
    int tilesY = RoundToCeil((maxs[1] - mins[1]) / stride);
    if (tilesX < 1) tilesX = 1;
    if (tilesY < 1) tilesY = 1;

    float height = maxs[2] - mins[2];
    float vStep = grid;
    int levels = RoundToFloor(height / vStep) + 1;
    if (levels > 256)
    {
        // 高度层数超限时自动放大垂直步长, 保证覆盖全高
        vStep = height / 255;
        levels = 256;
    }

    for (int ty = 0; ty < tilesY; ty++)
    {
        float tMinY = mins[1] + ty * stride;
        float tMaxY = tMinY + tile;
        if (tMaxY > maxs[1])
            tMaxY = maxs[1];

        for (int tx = 0; tx < tilesX; tx++)
        {
            float tMinX = mins[0] + tx * stride;
            float tMaxX = tMinX + tile;
            if (tMaxX > maxs[0])
                tMaxX = maxs[0];

            for (int l = 0; l < levels; l++)
            {
                float z = mins[2] + l * vStep;
                ND_WallLinePass(client, tMinX, tMaxX, tMinY, tMaxY, z, grid, tileN, life, color, surfaceMask, 0, true);
                ND_WallLinePass(client, tMinX, tMaxX, tMinY, tMaxY, z, grid, tileN, life, color, surfaceMask, 0, false);
                ND_WallLinePass(client, tMinX, tMaxX, tMinY, tMaxY, z, grid, tileN, life, color, surfaceMask, 1, true);
                ND_WallLinePass(client, tMinX, tMaxX, tMinY, tMaxY, z, grid, tileN, life, color, surfaceMask, 1, false);

                // 垂直网格线: 连接当前高度层与上一层, 形成墙面网格
                if (g_hWallGrid.IntValue && l + 1 < levels)
                {
                    float zNext = mins[2] + (l + 1) * vStep;
                    ND_WallGridVerticalPass(client, tMinX, tMaxX, tMinY, tMaxY, z, zNext, grid, tileN, life, color, surfaceMask, 0, true);
                    ND_WallGridVerticalPass(client, tMinX, tMaxX, tMinY, tMaxY, z, zNext, grid, tileN, life, color, surfaceMask, 0, false);
                    ND_WallGridVerticalPass(client, tMinX, tMaxX, tMinY, tMaxY, z, zNext, grid, tileN, life, color, surfaceMask, 1, true);
                    ND_WallGridVerticalPass(client, tMinX, tMaxX, tMinY, tMaxY, z, zNext, grid, tileN, life, color, surfaceMask, 1, false);
                }
            }
        }
    }
}

/**
 * @brief 墙面垂直网格线: 连接相邻两个高度层中同一列的目标表面命中点。
 *
 * 对相邻高度 z0 / z1 分别发射同一条水平射线, 若两处都命中目标表面且
 * 法线方向一致、命中点水平距离在网格容差内, 则把两点连成垂直线段。
 * 与 ND_WallLinePass 的水平线段共同构成墙面网格。
 *
 * @param client   目标客户端索引。
 * @param minX     扫描范围最小 X。
 * @param maxX     扫描范围最大 X。
 * @param minY     扫描范围最小 Y。
 * @param maxY     扫描范围最大 Y。
 * @param z0       较低高度层 Z。
 * @param z1       较高高度层 Z。
 * @param grid     网格间距。
 * @param n        网格列数。
 * @param life         线条持续时间 (秒)。
 * @param color        线条颜色 (RGBA)。
 * @param surfaceMask  SURF_* 位标志, 用于识别目标表面。
 * @param axis         0 = 沿 X 发射 (固定 y), 1 = 沿 Y 发射 (固定 x)。
 * @param fwd          true = 从 min 侧射向 max 侧, false = 反向。
 */
public void ND_WallGridVerticalPass(int client, float minX, float maxX, float minY, float maxY, float z0, float z1, float grid, int n, float life, const int color[4], int surfaceMask, int axis, bool fwd)
{
    for (int i = 0; i < n; i++)
    {
        float s0[3], e0[3], s1[3], e1[3];
        if (axis == 0)
        {
            float y = minY + i * grid;
            s0[0] = fwd ? minX : maxX; s0[1] = y; s0[2] = z0;
            e0[0] = fwd ? maxX : minX; e0[1] = y; e0[2] = z0;
            s1[0] = fwd ? minX : maxX; s1[1] = y; s1[2] = z1;
            e1[0] = fwd ? maxX : minX; e1[1] = y; e1[2] = z1;
        }
        else
        {
            float x = minX + i * grid;
            s0[0] = x; s0[1] = fwd ? minY : maxY; s0[2] = z0;
            e0[0] = x; e0[1] = fwd ? maxY : minY; e0[2] = z0;
            s1[0] = x; s1[1] = fwd ? minY : maxY; s1[2] = z1;
            e1[0] = x; e1[1] = fwd ? maxY : minY; e1[2] = z1;
        }

        TR_TraceRayFilter(s0, e0, MASK_SOLID_BRUSHONLY, RayType_EndPoint, ND_FilterWorldOnly);
        if (TR_StartSolid())
            continue;
        float pos0[3], normal0[3];
        bool hit0 = ND_HitSurface(pos0, normal0, surfaceMask);

        TR_TraceRayFilter(s1, e1, MASK_SOLID_BRUSHONLY, RayType_EndPoint, ND_FilterWorldOnly);
        if (TR_StartSolid())
            continue;
        float pos1[3], normal1[3];
        bool hit1 = ND_HitSurface(pos1, normal1, surfaceMask);

        if (!hit0 || !hit1)
            continue;
        if (GetVectorDotProduct(normal0, normal1) <= 0.9)
            continue;

        // 同一列的两个命中点必须在同一面墙上: 水平方向位移须有界
        if (axis == 0)
        {
            if (FloatAbs(pos1[0] - pos0[0]) > grid * 0.75)
                continue;
        }
        else
        {
            if (FloatAbs(pos1[1] - pos0[1]) > grid * 0.75)
                continue;
        }

        float p0[3], p1[3];
        for (int k = 0; k < 3; k++)
        {
            p0[k] = pos0[k] + normal0[k] * ND_LINE_OFFSET;
            p1[k] = pos1[k] + normal1[k] * ND_LINE_OFFSET;
        }
        ND_DrawBeam(client, p0, p1, life, color);
    }
}

/**
 * @brief 清除指定客户端的 VScript DebugDraw 覆盖层。
 *
 * @param client   目标客户端索引。
 */
public void ND_VScriptClear(int client)
{
    SetVariantString("DebugDrawClear()");
    AcceptEntityInput(client, "RunScriptCode");
}

/**
 * @brief 通过 VScript DebugDrawLine 向指定客户端发送一条长时线条。
 *
 * 替代 TE_SetupBeamPoints, 不受临时实体投递上限限制; 线条由客户端脚本
 * 调试覆盖层绘制, 持续时间为 life 秒。
 *
 * @param client   目标客户端索引。
 * @param start    线条起点。
 * @param end      线条终点。
 * @param life     持续时间 (秒)。
 * @param color    颜色 (RGBA)。
 */
public void ND_VScriptDrawLine(int client, const float start[3], const float end[3], float life, const int color[4])
{
    char code[256];
    Format(code, sizeof(code),
        "DebugDrawLine(Vector(%f, %f, %f), Vector(%f, %f, %f), %d, %d, %d, true, %f);",
        start[0], start[1], start[2],
        end[0], end[1], end[2],
        color[0], color[1], color[2],
        life);
    SetVariantString(code);
    AcceptEntityInput(client, "RunScriptCode");
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
 * @brief 读取当前 TR 结果: 是否命中指定 SURF_* 类型的世界表面, 并输出命中点与法线。
 *
 * @param[out] pos           命中点坐标。
 * @param[out] normal        命中表面法线。
 * @param surfaceMask        SURF_* 位标志, 用于识别目标表面 (SURF_NODRAW 或 SURF_SKY)。
 * @return                   true 表示命中指定类型的世界表面。
 */
public bool ND_HitSurface(float pos[3], float normal[3], int surfaceMask)
{
    if (!TR_DidHit() || !(TR_GetSurfaceFlags() & surfaceMask))
        return false;
    TR_GetEndPosition(pos);
    TR_GetPlaneNormal(INVALID_HANDLE, normal);
    return true;
}

/**
 * @brief 墙面单方向扫描: 沿轴从一侧射向另一侧, 连续命中同一表面的点连成一条线。
 *
 * 必须对同一高度正反两向各扫一遍 (fwd true/false), 否则射线只会命中路径上
 * 离起点最近的那面墙, 另一侧的墙会被漏掉。射线起点已处于实体内时
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
 * @param life         线条持续时间 (秒)。
 * @param color        标记颜色。
 * @param surfaceMask  SURF_* 位标志, 用于识别目标表面。
 * @param axis         0 = 沿 X 发射 (固定 y), 1 = 沿 Y 发射 (固定 x)。
 * @param fwd          true = 从 min 侧射向 max 侧, false = 反向。
 */
public void ND_WallLinePass(int client, float minX, float maxX, float minY, float maxY, float z, float grid, int n, float life, const int color[4], int surfaceMask, int axis, bool fwd)
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
        if (ND_HitSurface(pos, normal, surfaceMask))
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
 * @param life     线条持续时间 (秒)。
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
 * @param life         线条持续时间 (秒)。
 * @param color        标记颜色。
 * @param surfaceMask  SURF_* 位标志, 用于识别目标表面。
 * @param axis         0 = 沿 X 连线 (固定 y), 1 = 沿 Y 连线 (固定 x)。
 */
public void ND_FloorLinePass(int client, float minX, float minY, float topZ, float botZ, float grid, int n, float life, const int color[4], int surfaceMask, int axis)
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

            // 该列从 topZ 向下穿透非目标层, 取最上方目标表面
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
                if (TR_GetSurfaceFlags() & surfaceMask)
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
 * @param life     线条持续时间 (秒)。
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
 * @brief 向指定客户端发送一条 VScript DebugDrawLine 线段。
 *
 * @param client   目标客户端索引。
 * @param start    线段起点。
 * @param end      线段终点。
 * @param life     持续时间 (秒)。
 * @param color    颜色 (RGBA)。
 */
public void ND_DrawBeam(int client, const float start[3], const float end[3], float life, const int color[4])
{
    g_iScanBeams++;
    ND_VScriptDrawLine(client, start, end, life, color);
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
 * @param life     线条持续时间 (秒)。
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
