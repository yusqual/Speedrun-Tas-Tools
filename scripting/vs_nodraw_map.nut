//Squirrel
// NoDrawMap: 隐形碰撞(NoDraw/clip/透明位移面)网格射线扫描可视化 — 文档见 scripting/docs/

if (!("NoDrawMap" in getroottable()))
{
	//========================================================================
	// 配置
	//========================================================================
	g_NoDrawCfg <-
	{
		radius       = 640.0    // 扫描半宽 (以玩家/固定点为中心)
		grid         = 80.0     // 射线网格间距
		hBelow       = -96.0    // 竖直范围: 中心下方
		hAbove       = 384.0    // 竖直范围: 中心上方
		heights      = [0.0, 64.0, 160.0, 288.0]   // 墙面扫描高度 (相对中心)
		scan_step    = 0.1      // 刷新间隔 (秒)
		draw_time    = 0.30     // 标记存活时长 (秒), 须 > scan_step
		color_wall   = [255, 80, 80]     // 墙面命中色
		color_floor  = [80, 255, 120]    // 水平面命中色
		color_box    = [0, 255, 255]     // 扫描范围轮廓色
		mask_solid   = 33636363  // TRACE_MASK_PLAYER_SOLID (同 utils.nut)
		player_index = 1
		ignore_ents  = true      // 仅绘制世界几何 (静态 brush), 忽略玩家/NPC/实体
		max_layers   = 6         // 每列竖直方向最多记录的面数
	}

	g_NoDraw <-
	{
		enabled   = false
		pinned    = false
		center    = null       // 固定扫描中心 (pinned 时)
		scheduled = false      // 已挂起 think 链
	}

	//========================================================================
	// 入口: 开关 / 固定扫描中心到准星
	//========================================================================
	::NoDrawMap <- function(bOn = null, bPin = false)
	{
		if (bOn == null) bOn = !g_NoDraw.enabled;
		if (!bOn)
		{
			g_NoDraw.enabled = false;
			return;
		}
		local hPlayer = PlayerInstanceFromIndex(g_NoDrawCfg.player_index);
		if (hPlayer == null) return;
		g_NoDraw.enabled = true;
		g_NoDraw.pinned = bPin;
		g_NoDraw.center = bPin ? NoDrawMapPick(hPlayer) : null;
		if (!g_NoDraw.scheduled)
		{
			g_NoDraw.scheduled = true;
			EntFire("worldspawn", "RunScriptCode", "NoDrawMapThink()", 0.01);
		}
	}

	//========================================================================
	// 拾取准星指向的位置 (pinned 模式中心)
	//========================================================================
	::NoDrawMapPick <- function(hPlayer)
	{
		local hTrace =
		{
			start  = hPlayer.EyePosition()
			end    = hPlayer.EyePosition() + hPlayer.EyeAngles().Forward() * 4096.0
			ignore = hPlayer
			mask   = g_NoDrawCfg.mask_solid
		}
		TraceLine(hTrace);
		return hTrace.hit ? hTrace.pos : hTrace.end;
	}

	//========================================================================
	// 周期扫描 + 绘制
	//========================================================================
	::NoDrawMapThink <- function()
	{
		if (!g_NoDraw.enabled)
		{
			g_NoDraw.scheduled = false;
			return;
		}
		EntFire("worldspawn", "RunScriptCode", "NoDrawMapThink()", g_NoDrawCfg.scan_step);

		local hPlayer = PlayerInstanceFromIndex(g_NoDrawCfg.player_index);
		if (hPlayer == null) return;
		local gs = g_NoDrawCfg.grid;
		local r  = g_NoDrawCfg.radius;
		local vecOrigin = hPlayer.GetOrigin();
		local vecCenter = g_NoDraw.pinned
			? g_NoDraw.center
			: Vector(NoDrawMapSnap(vecOrigin.x, gs), NoDrawMapSnap(vecOrigin.y, gs), vecOrigin.z);
		local minX = vecCenter.x - r, maxX = vecCenter.x + r;
		local minY = vecCenter.y - r, maxY = vecCenter.y + r;
		local topZ = vecCenter.z + g_NoDrawCfg.hAbove;
		local botZ = vecCenter.z + g_NoDrawCfg.hBelow;
		local n  = floor(r * 2 / gs).tointeger() + 1;
		local s  = gs / 4;
		local dt = g_NoDrawCfg.draw_time;
		local cw = g_NoDrawCfg.color_wall;
		local cf = g_NoDrawCfg.color_floor;
		local cb = g_NoDrawCfg.color_box;
		local tr = null;

		//--- 墙面: 多高度上沿 X/Y 双向射线, 命中点画小方块
		foreach (dz in g_NoDrawCfg.heights)
		{
			local z = vecCenter.z + dz;
			for (local i = 0; i < n; i++)
			{
				local y = minY + i * gs;
				for (local d = 0; d < 2; d++)
				{
					tr = { start = d ? Vector(maxX, y, z) : Vector(minX, y, z)
						   end   = d ? Vector(minX, y, z) : Vector(maxX, y, z)
						   mask  = g_NoDrawCfg.mask_solid };
					TraceLine(tr);
					if (NoDrawMapHitWorld(tr))
						DebugDrawBox(tr.pos, Vector(-s, -s, -s), Vector(s, s, s), cw[0], cw[1], cw[2], 160, dt);
				}
			}
			for (local i = 0; i < n; i++)
			{
				local x = minX + i * gs;
				for (local d = 0; d < 2; d++)
				{
					tr = { start = d ? Vector(x, maxY, z) : Vector(x, minY, z)
						   end   = d ? Vector(x, minY, z) : Vector(x, maxY, z)
						   mask  = g_NoDrawCfg.mask_solid };
					TraceLine(tr);
					if (NoDrawMapHitWorld(tr))
						DebugDrawBox(tr.pos, Vector(-s, -s, -s), Vector(s, s, s), cw[0], cw[1], cw[2], 160, dt);
				}
			}
		}

		//--- 水平面: 每列自上而下逐层记录, 命中顶面画扁平标记
		for (local i = 0; i < n; i++)
		{
			for (local j = 0; j < n; j++)
			{
				local x = minX + i * gs, y = minY + j * gs;
				local z = topZ;
				for (local k = 0; k < g_NoDrawCfg.max_layers; k++)
				{
					tr = { start = Vector(x, y, z), end = Vector(x, y, botZ), mask = g_NoDrawCfg.mask_solid };
					TraceLine(tr);
					if (!NoDrawMapHitWorld(tr)) break;
					DebugDrawBox(tr.pos, Vector(-s, -s, -2), Vector(s, s, 2), cf[0], cf[1], cf[2], 160, dt);
					z = tr.pos.z - 1.0;
				}
			}
		}

		//--- 扫描范围轮廓 (始终可见)
		NoDrawMapBox(minX, minY, maxX, maxY, topZ, botZ, cb[0], cb[1], cb[2], dt);
	}

	//========================================================================
	// 命中判定: 仅接受世界几何 (brush)
	//========================================================================
	::NoDrawMapHitWorld <- function(hTrace)
	{
		if (!("hit" in hTrace) || !hTrace.hit) return false;
		if (hTrace.enthit == null) return true;
		return g_NoDrawCfg.ignore_ents ? hTrace.enthit.GetEntityIndex() == 0 : true;
	}

	//========================================================================
	// 网格对齐
	//========================================================================
	::NoDrawMapSnap <- function(x, gs)
	{
		return floor(x / gs + 0.5) * gs;
	}

	//========================================================================
	// 扫描盒轮廓线
	//========================================================================
	::NoDrawMapBox <- function(minX, minY, maxX, maxY, topZ, botZ, cr, cg, cbb, dt)
	{
		local tA = Vector(minX, minY, topZ), tB = Vector(maxX, minY, topZ);
		local tC = Vector(maxX, maxY, topZ), tD = Vector(minX, maxY, topZ);
		local bA = Vector(minX, minY, botZ), bB = Vector(maxX, minY, botZ);
		local bC = Vector(maxX, maxY, botZ), bD = Vector(minX, maxY, botZ);
		DebugDrawLine(tA, tB, cr, cg, cbb, true, dt);
		DebugDrawLine(tB, tC, cr, cg, cbb, true, dt);
		DebugDrawLine(tC, tD, cr, cg, cbb, true, dt);
		DebugDrawLine(tD, tA, cr, cg, cbb, true, dt);
		DebugDrawLine(bA, bB, cr, cg, cbb, true, dt);
		DebugDrawLine(bB, bC, cr, cg, cbb, true, dt);
		DebugDrawLine(bC, bD, cr, cg, cbb, true, dt);
		DebugDrawLine(bD, bA, cr, cg, cbb, true, dt);
		DebugDrawLine(tA, bA, cr, cg, cbb, true, dt);
		DebugDrawLine(tB, bB, cr, cg, cbb, true, dt);
		DebugDrawLine(tC, bC, cr, cg, cbb, true, dt);
		DebugDrawLine(tD, bD, cr, cg, cbb, true, dt);
	}
}
