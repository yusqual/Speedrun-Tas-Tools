# AGENTS.md

## 核心文档规则
项目中的每一个函数（无论新建还是修改），**必须**在定义之前附带 Doxygen 格式的注释块。
本规则适用于项目内所有编程语言，请根据语言语法调整注释分隔符，例如：
- C / C++ / Java / JavaScript / TypeScript / SourcePawn：使用 `/** ... */` 或 `/// ...`
- Python：使用 `## @brief ...` 或在文档字符串内使用 `@param` 指令

注释块至少包含以下标签：
- `@brief`  函数功能的简短摘要（一句话）
- `@param`  每个参数的含义及方向（in / out / in,out），若有特殊限制也需说明
- `@return` 返回值的含义（若返回值为 void / None 可省略）
- `@throws` / `@exception` 函数可能抛出的异常或错误情况（若适用）

推荐在必要时添加：
- `@note`    重要备注
- `@warning` 需要注意的风险
- `@see`     参考链接或相关函数

## 注释语言要求
**所有 Doxygen 注释内容必须使用中文书写**，以便直接生成中文技术文档。
（代码、参数名、标签名等仍使用英文。）

## 格式示例

### SourcePawn 示例
```sourcepawn
/**
 * @brief 检查客户端是否为管理员。
 * 
 * 根据客户端索引查询其管理员权限标志位，若成功获取则返回 true。
 *
 * @param client        客户端索引（1 到 MaxClients）。
 * @param[out] flags    存储获取到的管理员标志位（按位组合）。
 * @return              true 表示该客户端是管理员且 flags 有效，false 表示不是管理员或查询失败。
 * @note                即使函数返回 false，flags 也可能被修改为 0，请勿依赖未初始化的值。
 */
native bool IsClientAdmin(int client, int &flags);
```

### Python 示例（Doxygen 指令）
``` python
## @brief 计算非负整数的阶乘。
#  @param n: 需要计算阶乘的整数（必须 >= 0）。
#  @return n 的阶乘值，当 n 为 0 时返回 1。
#  @throws ValueError 当 n 为负数时抛出。
def factorial(n: int) -> int:
    ...
```

### TypeScript 示例
``` typescript
/**
 * @brief 将用户输入字符串转换为安全显示格式。
 * 对字符串进行 HTML 转义，防止 XSS 攻击。
 *
 * @param input 用户输入的原始字符串。
 * @return 转义后的安全字符串。
 */
function sanitize(input: string): string {
    // ...
}
```

### 代码质量补充要求
- 不要留下没有具体说明和关联任务编号的 TODO 注释。

- 遵循项目已有的命名、格式和结构约定。