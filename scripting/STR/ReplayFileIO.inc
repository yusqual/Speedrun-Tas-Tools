#if defined REPLAYFILEIO_INCLUDED
#endinput
#endif
#define REPLAYFILEIO_INCLUDED

#include "STAPlayer.inc"
#include "ReplayFrame.inc"

/**
 * @brief 从文件中加载 Replay 帧数据到玩家。
 * 文件格式：[4字节帧计数][帧数据...]，每帧 FRAME_Length 个 4字节字段。
 *
 * @param client     要加载到的目标客户端。
 * @param filepath   .STR 文件的完整路径。
 * @return           true 表示加载成功。
 */
public bool LoadReplayFromFile(int client, const char[] filepath)
{
    File file = OpenFile(filepath, "rb");
    
    if (file == null)
    {
        return false;
    }
    
    int framecount;
    ReadFileCell(file, framecount, 4);
    
    Player_CreateFrameArray(client);
    any frameinfo[FRAME_Length];
    
    for (int i = 0; i < framecount; ++i)
    {
        ReadFile(file, frameinfo, sizeof(frameinfo), 4);
        Player_PushFrame(client, frameinfo);
    }
    
    delete file;
    
    // 自动设置 StopFrame（若无设置）
    if (Player_GetStopFrame(client) == 0)
    {
        Player_SetStopFrame(client, 99999);
    }
    
    Player_SetIsFileLoaded(client, true);

    // 从完整路径中提取文件名
    char filename[PLATFORM_MAX_PATH];
    int lastSlash = FindCharInString(filepath, '/', true);
    if (lastSlash != -1)
        strcopy(filename, sizeof(filename), filepath[lastSlash + 1]);
    else
        strcopy(filename, sizeof(filename), filepath);
    Player_SetLoadedFileName(client, filename);

    return true;
}

/**
 * @brief 将玩家的 Replay 帧数据保存到文件。
 * 文件格式：[4字节帧计数][帧数据...]。
 *
 * @param client     数据来源客户端。
 * @param filepath   要保存的文件路径。
 * @return           true 表示保存成功。
 */
public bool SaveReplayToFile(int client, const char[] filepath)
{
    File file = OpenFile(filepath, "wb");
    
    if (file == null)
    {
        return false;
    }
    
    int framecount = Player_GetRecordedFramesCount(client);
    WriteFileCell(file, framecount, 4);
    
    any frameinfo[FRAME_Length];
    
    for (int i = 0; i < framecount; ++i)
    {
        Player_GetFrame(client, i, frameinfo);
        
        for (int j = 0; j < FRAME_Length; ++j)
        {
            WriteFileCell(file, frameinfo[j], 4);
        }
    }
    
    delete file;
    return true;
}

/**
 * @brief 将玩家的 Replay 帧数据保存到文件，同时输出调试坐标文件。
 * 在 sm_replaydebug 开启时，额外输出 Pos_x.txt / Pos_y.txt / Pos_z.txt。
 *
 * @param client     数据来源客户端。
 * @param filepath   要保存的 .STR 文件路径。
 * @param dirpath    调试文件输出目录。
 * @param filename   文件名（不含扩展名，用于调试文件命名）。
 * @return           true 表示保存成功。
 */
public bool SaveReplayToFileWithDebug(int client, const char[] filepath, const char[] dirpath, const char[] filename)
{
    if (!SaveReplayToFile(client, filepath))
    {
        return false;
    }
    
    // 输出调试坐标文件
    int framecount = Player_GetRecordedFramesCount(client);
    any frameinfo[FRAME_Length];
    
    // Pos_x.txt
    {
        char debugPath[PLATFORM_MAX_PATH];
        FormatEx(debugPath, sizeof(debugPath), "%s/Pos_x.txt", dirpath);
        File debugFile = OpenFile(debugPath, "w");
        if (debugFile != null)
        {
            for (int i = 0; i < framecount; ++i)
            {
                Player_GetFrame(client, i, frameinfo);
                WriteFileLine(debugFile, "%.03f", frameinfo[FRAME_PosX]);
            }
            delete debugFile;
        }
    }
    
    // Pos_y.txt
    {
        char debugPath[PLATFORM_MAX_PATH];
        FormatEx(debugPath, sizeof(debugPath), "%s/Pos_y.txt", dirpath);
        File debugFile = OpenFile(debugPath, "w");
        if (debugFile != null)
        {
            for (int i = 0; i < framecount; ++i)
            {
                Player_GetFrame(client, i, frameinfo);
                WriteFileLine(debugFile, "%.03f", frameinfo[FRAME_PosY]);
            }
            delete debugFile;
        }
    }
    
    // Pos_z.txt
    {
        char debugPath[PLATFORM_MAX_PATH];
        FormatEx(debugPath, sizeof(debugPath), "%s/Pos_z.txt", dirpath);
        File debugFile = OpenFile(debugPath, "w");
        if (debugFile != null)
        {
            for (int i = 0; i < framecount; ++i)
            {
                Player_GetFrame(client, i, frameinfo);
                WriteFileLine(debugFile, "%.03f", frameinfo[FRAME_PosZ]);
            }
            delete debugFile;
        }
    }
    
    return true;
}

/**
 * @brief 从玩家的 Replay 帧数据中截取一段保存到文件。
 *
 * @param client       数据来源客户端。
 * @param filepath     要保存的文件路径。
 * @param frame_start  起始帧索引（含）。
 * @param frame_end    结束帧索引（含）。
 * @return             true 表示保存成功。
 */
public bool SplitReplayToFile(int client, const char[] filepath, int frame_start, int frame_end)
{
    int framecount = Player_GetRecordedFramesCount(client);
    
    if (frame_start < 0 || frame_end >= framecount || frame_start > frame_end)
    {
        return false;
    }
    
    File file = OpenFile(filepath, "wb");
    if (file == null)
    {
        return false;
    }
    
    int newcount = frame_end - frame_start + 1;
    WriteFileCell(file, newcount, 4);
    
    any frameinfo[FRAME_Length];
    
    for (int i = frame_start; i <= frame_end; ++i)
    {
        Player_GetFrame(client, i, frameinfo);
        
        for (int j = 0; j < FRAME_Length; ++j)
        {
            WriteFileCell(file, frameinfo[j], 4);
        }
    }
    
    delete file;
    return true;
}

/**
 * @brief 获取 Replay 文件的帧数。
 * 不加载数据，只读取文件头的帧计数。
 *
 * @param filepath  .STR 文件路径。
 * @return          帧数，-1 表示读取失败。
 */
public int GetReplayFileFrameCount(const char[] filepath)
{
    File file = OpenFile(filepath, "rb");
    if (file == null)
    {
        return -1;
    }
    
    int framecount;
    ReadFileCell(file, framecount, 4);
    delete file;
    
    return framecount;
}

/**
 * @brief 构建 Replay 文件的完整路径。
 * 路径格式：addons/sourcemod/data/Speedrun Tas Tools/Replays/<地图名>/<文件名>
 *
 * @param mapname     当前地图名称。
 * @param filename    文件名（不含路径）。
 * @param output      输出缓冲区。
 * @param maxlen      缓冲区大小。
 */
public void BuildReplayFilePath(const char[] mapname, const char[] filename, char[] output, int maxlen)
{
    BuildPath(Path_SM, output, maxlen, "%s/%s/%s/%s", STR_RootPath, STR_ReplayFolder, mapname, filename);
}

/**
 * @brief 构建 Replay 文件所在目录的路径。
 * 路径格式：addons/sourcemod/data/Speedrun Tas Tools/Replays/<地图名>/
 *
 * @param mapname   当前地图名称。
 * @param output    输出缓冲区。
 * @param maxlen    缓冲区大小。
 */
public void BuildReplayDirPath(const char[] mapname, char[] output, int maxlen)
{
    BuildPath(Path_SM, output, maxlen, "%s/%s/%s", STR_RootPath, STR_ReplayFolder, mapname);
}
