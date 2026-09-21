# Fireworks Tech Graph - Scripts

辅助脚本集合，用于提高 SVG 图表生成的稳定性和效率。

## 脚本列表

### 1. validate-svg.sh

SVG 验证脚本，检查 SVG 语法并报告详细错误。

**用法：**
```bash
./validate-svg.sh <svg-file>
```

**检查项目：**
- XML 结构、属性语法和实体转义（使用 XML parser，避免把 `top_k=5` 之类的文本误判为属性）
- `marker-start` / `marker-mid` / `marker-end` 引用完整性
- 箭头与组件碰撞（支持绝对/相对 `M/L/H/V/Q/C/S/T` 路径，曲线路径采样检测）
- 渲染验证（cairosvg 优先，rsvg-convert 兜底）

**示例：**
```bash
./validate-svg.sh /path/to/diagram.svg
```

### 2. generate-diagram.sh

SVG 图表生成脚本，提供自动验证和 PNG 导出。

**用法：**
```bash
./generate-diagram.sh [OPTIONS]
```

**选项：**
- `-t, --type TYPE` - 图表类型（见脚本帮助）
- `-s, --style STYLE` - 风格编号（1-12，默认：1）
- `-o, --output PATH` - 输出路径（默认：当前目录）
- `-w, --width WIDTH` - PNG 宽度（像素，默认：1920）
- `--no-validate` - 跳过验证
- `-h, --help` - 显示帮助

**示例：**
```bash
# 生成架构图（Style 1）
./generate-diagram.sh -t architecture -s 1 -o ./output/arch.svg

# 生成流程图（Style 2，2400px 宽）
./generate-diagram.sh -t flowchart -s 2 -w 2400
```

**注意：** SVG 内容需要先准备好；这个脚本只负责验证与导出。

### 3. generate-from-template.py

基于风格配置和 JSON 数据生成 SVG。当前版本不再只是简单塞入 `nodes/arrows`，
而是会执行 style guide 中的部分可计算规则，例如：

- `style` - 风格编号（1-12）或规范风格名
- `semantic_profile` - 可选语义契约；Style 9-12 默认分别启用 C4、云部署、事件流和可观测性契约
- `containers` - 泳道 / 分组容器
- `containers[].header_prefix` / `containers[].header_text` - 工程编号式分区标题
- `containers[].side_label` - 左侧 layer label
- `nodes[].kind` - 语义组件类型，例如 `double_rect`、`cylinder`、`document`、`terminal`、`circle_cluster`
- `arrows[].flow` - 语义箭头类型，例如 `control`、`write`、`read`、`data`
- `source_port` / `target_port` - 指定端口锚点
- `route_points` / `corridor_x` / `corridor_y` - 控制复杂图的走线质量
- `style_overrides` - 对现有 style 做局部覆盖
- `window_controls` / `meta_*` - 顶部终端 chrome
- `blueprint_title_block` - 工程蓝图右下角 title block

**用法：**
```bash
python3 ./generate-from-template.py architecture ./output/arch.svg '{"style":1,"title":"My Diagram","containers":[],"nodes":[],"arrows":[]}'
```

**示例：**
```bash
python3 ./generate-from-template.py memory ./output/mem0.svg '{
  "style": 1,
  "title": "Mem0 Memory Architecture",
  "containers": [
    {"x":30,"y":90,"width":900,"height":90,"label":"Input Layer","header_prefix":"01"}
  ],
  "nodes": [
    {"id":"manager","kind":"double_rect","x":360,"y":220,"width":300,"height":72,"label":"Memory Manager"},
    {"id":"vector","kind":"cylinder","x":90,"y":360,"width":140,"height":110,"label":"Vector Store"}
  ],
  "arrows": [
    {"source":"manager","target":"vector","flow":"write","dashed":true}
  ]
}'
```

### 4. test-all-styles.sh

批量测试脚本覆盖 12 种风格。Style 1-7 与 9-12 从 JSON fixture 生成，AI 手绘的 Style 8 使用静态 SVG fixture；任何风格缺少回归 fixture 都会使批测失败。

**用法：**
```bash
./test-all-styles.sh
```

**功能：**
- 检查所有风格的参考文件
- 渲染 `fixtures/*.json` 回归样例
- 验证生成出的 SVG 文件
- 导出 PNG 文件到 `test-output/` 目录
- 生成测试报告

**输出：**
- 测试摘要（通过/失败统计）
- PNG 文件（带时间戳）
- 详细的验证错误信息

**示例：**
```bash
./test-all-styles.sh
```

## 依赖

所有脚本需要至少一个 PNG 渲染器（推荐 cairosvg）：

- **cairosvg**（推荐）- SVG 转 PNG，CSS 支持最好
  ```bash
  python3 -m pip install cairosvg
  ```

- **rsvg-convert**（备选）- 系统包；复杂 SVG 可能丢失 CSS / `<foreignObject>`
  ```bash
  brew install librsvg                # macOS
  sudo apt install librsvg2-bin       # Ubuntu/Debian
  ```

`generate-diagram.sh` 会优先调用 cairosvg，缺失时自动回退到 rsvg-convert。完整对比见 [PNG 导出参考](../references/png-export.md)。

聚焦后的语义动效由 `fireworks.py animate`、`motion.py` 和 `svg2gif.js` 协作完成，只接收带有 12 套已验收 role/stage/order 契约之一的生成器语义 SVG。精确源文件字节不锁定，但任意同风格拓扑不会自动套用动效。媒体输出只允许经过验证的 GIF，默认还会生成同名 `.motion.json` 报告。运行时需要 FFmpeg/FFprobe、Chrome/Chromium，以及 Skill 安装位置可解析到的 `puppeteer` 或 `puppeteer-core`；当前工作目录中的同名模块不会被隐式执行。依赖安装与最简命令：

```bash
for SKILL_ROOT in \
  "$HOME/.agents/skills/fireworks-tech-graph" \
  "$HOME/.claude/skills/fireworks-tech-graph"
do
  [ -d "$SKILL_ROOT" ] || continue
  npm install --prefix "$SKILL_ROOT" --ignore-scripts --no-save --package-lock=false puppeteer-core@25.3.0
done
SKILL_ROOT="${CLAUDE_SKILL_DIR:-$HOME/.agents/skills/fireworks-tech-graph}"
python3 "$SKILL_ROOT/scripts/fireworks.py" animate diagram.svg diagram.gif
```

默认自动识别风格，输出 5.75 秒、20fps、960px 宽、115 帧无限循环 GIF。第 1–36 帧保持既有 draw-on，第 36–38 帧淡入运行流，第 38–109 帧为完整稳定数据流，第 110–114 帧按 `[1,.7575,.515,.2725,.03]` reset。Style 1–12 的 signature、速度、路径、几何和构建合同均为 `user-approved`，包括 `persistent-data-flow-head`、`terminal-evidence-stream`、`blueprint-registration-bead`、14×10 `notion-memory-card`、`glass-task-capsule`、`policy-seal`、`token-train`、`gem-tracer`、`review-cursor`、region chevrons、event train 与 ops scanner；共享 `+2s-settled-flow` 时间修订也已于 2026-07-17 验收，默认新包的 `review_status` 为 `user-approved`。显式 3.75 秒/75 帧和 2.75 秒/55 帧继续支持。75 帧及以下要求全部 raster 唯一；更长时间线允许非相邻重复出现在 full-opacity 区间，frame 110 是 reset opacity 为 1.00 的唯一例外并分类为 `intentional_reset_boundary_repeat`，frame 111–114 必须全局不同；至少保留 75 个唯一 raster 且相邻重复数为零。75-vs-115 gate 分开统计 binary / decoded-RGBA / guarded-antialias 三类；guarded 等价要求 AE ≤ 128、normalized RMSE ≤ 0.001、component 宽或高不超过 2px 且只落在 edge/node border，DOM 和 signature geometry 仍 strict-exact。完整约束见 [动效参考](../references/motion-effects.md)。

- **grep, sed, awk** - 文本处理（macOS 自带）

## 目录结构

```
fireworks-tech-graph/
├── SKILL.md                    # Skill 主文档
├── references/                 # 风格参考文件
│   ├── style-1-flat-icon.md
│   ├── style-2-dark-terminal.md
│   └── ...
├── fixtures/                   # 回归测试样例（JSON）
│   ├── mem0-style1.json
│   ├── tool-call-style2.json
│   └── ...
├── scripts/                    # 辅助脚本（本目录）
│   ├── README.md              # 本文档
│   ├── validate-svg.sh        # SVG 验证
│   ├── generate-diagram.sh    # SVG 验证与 PNG 导出
│   ├── generate-from-template.py # 模板化生成 SVG
│   ├── motion.py              # SVG 转 GIF 校验、编码与原子报告
│   ├── svg2gif.js             # Chromium 手动时间轴逐帧渲染
│   └── test-all-styles.sh     # 批量测试
└── test-output/               # 测试输出目录（自动创建）
```

## 使用场景

### 场景 1：验证现有 SVG

```bash
SKILL_ROOT=~/.agents/skills/fireworks-tech-graph # Codex
# SKILL_ROOT=~/.claude/skills/fireworks-tech-graph # Claude Code
"$SKILL_ROOT/scripts/validate-svg.sh" /path/to/your-diagram.svg
```

### 场景 2：生成并验证图表

1. 使用 Codex 或 Claude Code 生成 SVG 内容
2. 运行验证和导出：
   ```bash
   SKILL_ROOT=~/.agents/skills/fireworks-tech-graph # Codex
   # SKILL_ROOT=~/.claude/skills/fireworks-tech-graph # Claude Code
   "$SKILL_ROOT/scripts/generate-diagram.sh" -t architecture -s 1 -o ./output/arch.svg
   ```

### 场景 3：批量测试所有风格

```bash
SKILL_ROOT=~/.agents/skills/fireworks-tech-graph # Codex
# SKILL_ROOT=~/.claude/skills/fireworks-tech-graph # Claude Code
"$SKILL_ROOT/scripts/test-all-styles.sh"
```

测试脚本会自动：
1. 读取 `../fixtures/*.json`
2. 按 `template_type + style` 调用 `generate-from-template.py`
3. 运行 `validate-svg.sh`
4. 导出 PNG 到 `../test-output/`

### 场景 4：validator 单元测试

```bash
python3 -m unittest discover -s tests -p 'test_validate_svg.py' -v
```

覆盖 marker 双端引用、文本等号、`H/V` 路径、曲线路径、虚线组件和容器排除等正反例。

对启发式难以区分的形状，可显式添加 `data-graph-role="node|container|legend|decoration|label|background"`。`node` 会强制纳入障碍物检测，其余角色会从组件障碍物中排除；`legend` 组内的示例箭头也不会被当作业务流。

查看测试输出：
```bash
ls -lh ../test-output/
```

## 故障排除

### 问题：找不到 PNG 渲染器

**解决方案（任选其一，推荐 cairosvg）：**
```bash
python3 -m pip install cairosvg        # 推荐
brew install librsvg                   # macOS 系统包
sudo apt install librsvg2-bin          # Ubuntu/Debian
```

### 问题：rsvg-convert 渲染缺框/缺文字

**原因：** rsvg-convert 对 `<foreignObject>`、CSS `filter`、复杂 `<style>` 块支持有限。

**解决方案：** 切换到 cairosvg：
```bash
python3 -m pip install cairosvg
```
脚本会自动优先使用 cairosvg。如果仍需要像素级还原（例如浏览器生成的 SVG），按 [PNG 导出参考](../references/png-export.md) 使用 `svg2png.js`。

### 问题：权限被拒绝

**解决方案：**
```bash
chmod +x *.sh
```

### 问题：SVG 验证失败

**解决方案：**
1. 查看详细错误信息
2. 使用 Edit 工具修复语法错误
3. 重新运行验证

## 开发说明

### 添加新的验证规则

编辑 `validate-svg.sh`，在现有检查项后添加新的检查逻辑：

```bash
# Check N: Your new check
echo -n "Checking something... "
# Your validation logic here
if [ condition ]; then
    echo -e "${GREEN}✓ Pass${NC}"
else
    echo -e "${RED}✗ Fail${NC}"
fi
```

### 扩展支持的图表类型

编辑 `generate-diagram.sh`，在 `--type` 参数处理中添加新类型。

## 版本历史

- **v1.2.0** (2026-07-17) - 语义动效与动态展示
  - 12 种已验收的 SVG→GIF 场景动效与 5.75 秒 settled-flow 默认时间线
  - README 全动态图集、GIF manifest、媒体回读与安装副本全风格门禁
  - 动效源 SVG 保持语义契约约束，不绑定标题和内容字节
- **v1.1.0** (2026-07-15) - 几何与分发升级
  - Schema v1 与类型化 Diagram IR
  - 正交路由、端口分流、图例/标签避让、跨线桥与确定性布局报告
  - `fireworks.py` 统一 CLI 与离线交互 HTML 导出
  - 完整 npx Skill 镜像、CI、Release archive parity 与安装 canary
- **v1.0.0** (2026-04-11) - 初始版本
  - SVG 验证脚本
  - 图表生成脚本
  - 批量测试脚本

## 许可证

MIT License - 与 fireworks-tech-graph skill 相同
