[English](README.md) | [中文](README.zh.md)

# fireworks-tech-graph

> 不用手画图了。用中文描述你的系统，几秒钟得到可直接发布的 SVG + PNG 技术图。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code Skill](https://img.shields.io/badge/Claude%20Code-Skill-blue)](https://claude.ai/code)
[![7 种视觉风格](https://img.shields.io/badge/风格-7种-purple)]()
[![14 种图类型](https://img.shields.io/badge/图类型-14种-green)]()
[![UML 支持](https://img.shields.io/badge/UML-完整支持-orange)]()

## 概述

`fireworks-tech-graph` 将自然语言描述转化为精美的 SVG 技术图，并通过 `rsvg-convert` 导出高分辨率 PNG。内置 **7 种视觉风格**，深度覆盖 AI/Agent 领域常见图类型（RAG、Agentic Search、Mem0、Multi-Agent、Tool Call 流程等），并完整支持全部 14 种 UML 图类型。

```
用户: "画一张 Mem0 的架构图，暗黑风格"
  → Skill 识别：Memory Architecture Diagram，Style 2
  → 生成含泳道、圆柱体、语义箭头的 SVG
  → 导出 1920px PNG
  → 输出路径：mem0-architecture.svg / mem0-architecture.png
```

---

## 效果展示

> 所有示例图均以 1920px 宽度（2× 视网膜分辨率）通过 `rsvg-convert` 导出为 **PNG 格式**。技术图应选 PNG（无损），JPG 有损压缩会在文字和线条边缘产生噪点。

### 风格 1 — 扁平图标风（默认）
*Mem0 记忆架构图 — 白底，语义箭头，分层记忆系统*
![风格 1 — 扁平图标风](assets/samples/sample-style1-flat.png)

### 风格 2 — 暗黑极客风
*Tool Call 执行流程 — 深色背景，Neon 配色，等宽字体*
![风格 2 — 暗黑极客风](assets/samples/sample-style2-dark.png)

### 风格 3 — 工程蓝图风
*微服务架构图 — 深蓝底，网格线，青色描边*
![风格 3 — 工程蓝图风](assets/samples/sample-style3-blueprint.png)

### 风格 4 — Notion 极简风
*Agent 记忆类型图 — 白底极简，单一强调色*
![风格 4 — Notion 极简风](assets/samples/sample-style4-notion.png)

### 风格 5 — 玻璃态卡片风
*Multi-Agent 协作图 — 深色渐变底，磨砂玻璃卡片*
![风格 5 — 玻璃态卡片风](assets/samples/sample-style5-glass.png)

### 风格 6 — Claude 官方风格
*系统架构图 — 温暖奶油色背景 (#f8f6f3)，Anthropic 品牌色，简洁专业美学*
![风格 6 — Claude 官方风格](assets/samples/sample-style6-claude.png)

### 风格 7 — OpenAI 官方风格
*API 集成流程图 — 纯白背景，OpenAI 品牌配色，现代极简设计*
![风格 7 — OpenAI 官方风格](assets/samples/sample-style7-openai.png)

---

## 稳定输出提示词样例

下面这 7 组提示词都更贴近当前仓库里回归测试最稳定的输出方式：

### 风格 1 — 扁平图标风
```text
画一张 style 1（Flat Icon）的 Mem0 记忆架构图。
分成四个横向区域：Input Layer、Memory Manager、Storage Layer、Output / Retrieval。
包含 User、AI App / Agent、LLM、mem0 Client、Memory Manager、Vector Store、Graph DB、Key-Value Store、History Store、Context Builder、Ranked Results、Personalized Response。
使用 read、write、control、data 四类语义箭头，整体保持产品文档风格的清晰布局。
```

### 风格 2 — 暗黑极客风
```text
画一张 style 2（Dark Terminal）的 tool call flow 图。
包含 User query、Retrieve chunks、Generate answer、Knowledge base、Agent、Terminal、Source documents、Grounded answer。
使用终端窗口 chrome、Neon 强调色、等宽字体，以及 retrieval、answer synthesis、embedding update 三类语义箭头。
```

### 风格 3 — 工程蓝图风
```text
画一张 style 3（Blueprint）的微服务架构图。
使用带编号的工程分区标题，例如 01 // EDGE、02 // APPLICATION SERVICES、03 // DATA + EVENT INFRA、04 // OBSERVABILITY。
包含 Client Apps、API Gateway、Auth / Policy、三个业务服务、Event Router、Postgres、Redis Cache、Warehouse、Metrics / Traces。
使用蓝图网格、青色描边，并在右下角加入工程 title block。
```

### 风格 4 — Notion 极简风
```text
画一张 style 4（Notion Clean）的 agent memory types 图。
以中间的 Agent Core 为中心，对比 Sensory Memory、Working Memory、Episodic Memory、Semantic Memory、Procedural Memory。
使用极简白底、浅边框、单一强调色箭头，并给每种 memory 补充简短的存储标签。
```

### 风格 5 — 玻璃态卡片风
```text
画一张 style 5（Glassmorphism）的 multi-agent collaboration 图。
分成 Mission Control、Specialist Agents、Synthesis 三个区域。
包含 User brief、Coordinator Agent、Research Agent、Coding Agent、Review Agent、Shared Memory、Synthesis Engine、Final response。
使用 frosted glass 卡片、轻微 glow，以及 delegation、shared memory write、synthesis output 三类语义箭头。
```

### 风格 6 — Claude 官方风格
```text
画一张 style 6（Claude Official）的 system architecture 图。
使用左侧 layer label：Interface Layer、Core Layer、Foundation Layer。
包含 Client Surface、Gateway、Task Planner、Model Runtime、Policy Guardrails、Memory Store、Tool Runtime、Observability、Registry。
使用温暖奶油色背景、克制的品牌感配色、足够留白，并在右下角放 legend。
```

### 风格 7 — OpenAI 官方风格
```text
画一张 style 7（OpenAI Official）的 API integration flow 图。
分成 Entry、Model + Tools、Delivery 三个区域。
包含 Application、OpenAI SDK Layer、Prompt Builder、Model Runtime、Tool Calls、Response Formatter、Observability、Release Control。
整体保持纯白、精确、现代、极简，并使用干净的绿色语义箭头。
```

---

## 功能特性

- **7 种视觉风格** — 从白底极简到暗黑 Neon 再到磨砂玻璃，再到官方品牌风格
- **可执行风格系统** — 风格约束不仅写在文档里，也真正进入生成器逻辑
- **14 种图类型** — 完整支持全部 UML 图类型（类图、组件图、部署图、包图、复合结构图、对象图、用例图、活动图、状态机图、序列图、通信图、时序图、交互概览图、ER 图）以及 AI/Agent 领域图
- **AI/Agent 领域内建知识** — RAG、Agentic Search、Mem0、Multi-Agent、Tool Call 等常见 Pattern 开箱即用
- **语义形状词汇表** — LLM = 双边框圆角矩形，Agent = 六边形，Vector Store = 带内环圆柱
- **语义箭头系统** — 颜色 + 虚线样式编码含义（写入/读取/异步/循环）
- **产品图标库** — 40+ 产品品牌色：OpenAI、Anthropic、Pinecone、Weaviate、Kafka、PostgreSQL……
- **泳道分组** — 自动为复杂架构添加层级标签
- **SVG + PNG 双输出** — SVG 可编辑，1920px PNG 可直接嵌入文章
- **rsvg-convert 兼容** — 纯内联 SVG，不依赖外部字体，渲染稳定

---

## 安装

```bash
npx skills add yizhiyanhua-ai/fireworks-tech-graph
```

这个 Skill 的 `skills add` 安装源是 GitHub 仓库。npm 页面用于公开展示、版本分发和 README 浏览：

```text
https://www.npmjs.com/package/@yizhiyanhua-ai/fireworks-tech-graph
```

不要把 npm 包名直接写进 `skills add`，因为 CLI 会把安装源解析为 GitHub 路径或本地路径。

## 更新

```bash
npx skills add yizhiyanhua-ai/fireworks-tech-graph --force -g -y
```

用户后续要升级时，直接重新执行一次 `add --force` 即可拉取最新版本。

或直接克隆：

```bash
git clone https://github.com/yizhiyanhua-ai/fireworks-tech-graph.git ~/.claude/skills/fireworks-tech-graph
```

---

## 安装依赖

```bash
# macOS
brew install librsvg

# Ubuntu/Debian
sudo apt install librsvg2-bin

# 验证安装
rsvg-convert --version
```

---

## 使用方式

### 触发词

以下关键词会自动触发 Skill：

```
画图 / 帮我画 / 生成图 / 做个图 / 架构图 / 流程图 / 可视化一下 / 出图
generate diagram / draw diagram / create chart / visualize
```

### 基本用法

```
画一张 RAG 流程图
```

```
生成一张 Agentic Search 架构图
```

### 指定风格

```
画一张微服务架构图，风格2（暗黑极客风）
```

```
生成 Multi-Agent 协作图，玻璃态风格
```

### 指定输出路径

```
生成 Mem0 架构图，输出到 ~/Desktop/
```

```
画一张 Tool Call 流程图 --output /tmp/diagrams/
```

---

## 场景示例集

### AI/Agent 系统

```
画一张 Agentic RAG 和普通 RAG 的对比图，用 Notion 极简风
```
→ 功能矩阵对比：检索策略、Agent 循环、工具调用、延迟、成本

```
生成一张 Mem0 记忆架构图，包含向量库、图数据库、KV 存储和记忆管理器
```
→ 分泳道记忆架构：Input → Memory Manager → 存储层 → 检索输出

```
画一张 Multi-Agent 协作图：Orchestrator 调度 3 个 SubAgent（搜索/计算/代码执行），汇聚到 Aggregator
```
→ Agent 架构，六边形节点 + 工具层 + 结果聚合

```
可视化一下 Tool Call 的执行流程：LLM → Tool Selector → Execution → Parser → 回到 LLM
```
→ 含决策循环的流程图，展示工具调用的完整生命周期

```
画一张 Agent 的 5 种记忆类型图：感知记忆、工作记忆、情景记忆、语义记忆、程序记忆
```
→ 思维导图或分层架构，从感官输入到程序技能的记忆层级

### 基础设施与云架构

```
帮我画一张微服务架构图：Client → API Gateway → [用户服务 / 订单服务 / 支付服务] → PostgreSQL + Redis
```
→ 水平分层架构，每个服务集群一个泳道

```
生成一张数据管道图：Kafka 消费数据 → Spark 处理 → 写入 S3 → Athena 查询
```
→ 数据流图，每条箭头标注数据类型（stream / batch / query）

```
画一张 Kubernetes 部署架构：Ingress → Service → [Pod × 3] → ConfigMap + PersistentVolume
```
→ 架构图，Namespace 用虚线框，流量用实线箭头

### API 与时序流程

```
画一张 OAuth2 授权码流程的序列图：用户 → 客户端 → 授权服务器 → 资源服务器
```
→ 序列图，垂直生命线 + 激活框

```
帮我画一张 ChatGPT Plugin 的调用时序图
```
→ 时序：User → ChatGPT → Plugin Manifest → API → 响应链

### 决策与流程图

```
画一张 AI 应用上线前的质检流程图：代码审查 → 安全扫描 → 性能测试 → 人工审核 → 发布
```
→ 流程图，含菱形决策节点和并行分支

```
生成一张 RAG vs Fine-tuning vs Prompt Engineering 的功能对比图
```
→ 功能矩阵，对比成本、延迟、准确率、灵活性

### 概念图与知识图谱

```
帮我可视化一下 LLM 应用的技术栈：从底层模型到 SDK 到应用框架到部署层
```
→ 分层架构图或思维导图，从模型层到产品层

```
画一张 AI Agent 的核心能力地图：感知 / 记忆 / 推理 / 行动 / 学习
```
→ 以"AI Agent"为中心的放射状思维导图，5 个核心能力分支

---

## 7 种风格

| # | 名称 | 背景色 | 字体 | 适用场景 |
|---|------|--------|------|----------|
| 1 | **扁平图标风** *(默认)* | `#ffffff` | Helvetica | 博客、幻灯片、技术文档 |
| 2 | **暗黑极客风** | `#0f0f1a` | SF Mono / Fira Code | GitHub README、开发者文章 |
| 3 | **工程蓝图风** | `#0a1628` | Courier New | 架构设计文档、工程规范 |
| 4 | **Notion 极简风** | `#ffffff` | system-ui | Notion、Confluence、内部 Wiki |
| 5 | **玻璃态卡片风** | `#0d1117` 渐变 | Inter | 产品官网、演讲 Keynote |
| 6 | **Claude 官方风格** | `#f8f6f3` | system-ui | Anthropic 风格图表，温暖专业美学 |
| 7 | **OpenAI 官方风格** | `#ffffff` | system-ui | OpenAI 风格图表，简洁现代设计 |

每种风格在 `references/` 目录下都有专属参考文件，包含精确的颜色 Token、SVG 模板和使用规范。
生成器现在还会直接消费风格相关结构字段，例如 `containers`、语义化 `nodes[].kind`、`arrows[].flow` 以及显式端口锚点，以便更稳定地逼近样图级布局质量。

几个很有用的增强字段：
- `style_overrides`：在不复制整套 style 的前提下微调标题对齐或配色 token
- `containers[].header_prefix` / `containers[].header_text`：用于 style 3 这种 `01 // EDGE` 的工程编号分区标题
- `containers[].side_label`：用于 style 6 这类左侧 Layer Label
- `window_controls`、`meta_left`、`meta_center`、`meta_right`：用于终端 / 文档风格的顶部 chrome
- `blueprint_title_block`：用于 style 3 的蓝图标题信息框

### 风格选择指南

**UML 图类型：**
- **类图/组件图/包图**：风格 1（扁平图标风）或风格 4（Notion 极简风）— 结构清晰，易于阅读
- **序列图/时序图**：风格 2（暗黑极客风）— 等宽字体有助于对齐
- **状态机图/活动图**：风格 3（工程蓝图风）— 工程美学适合流程图
- **用例图/交互图**：风格 1（扁平图标风）— 彩色，易于理解

**AI/Agent 图类型：**
- **RAG/Agentic Search**：风格 2（暗黑极客风）或风格 5（玻璃态卡片风）— 科技感强
- **记忆架构**：风格 3（工程蓝图风）— 强调分层存储结构
- **Multi-Agent**：风格 5（玻璃态卡片风）— 磨砂卡片区分 Agent 边界

**文档类型：**
- **内部文档**：风格 4（Notion 极简风）— 极简，适合 Wiki
- **技术博客**：风格 1（扁平图标风）— 彩色，吸引眼球
- **GitHub README**：风格 2（暗黑极客风）— 匹配暗色主题
- **演示文稿**：风格 5（玻璃态卡片风）或风格 6（Claude 官方风格）— 精致专业

**品牌特定：**
- **Anthropic/Claude 项目**：风格 6（Claude 官方风格）— 温暖奶油色背景，品牌感强且克制
- **OpenAI 项目**：风格 7（OpenAI 官方风格）— 简洁白色，OpenAI 配色

---

## 支持的图类型

| 类型 | 描述 | 关键布局规则 |
|------|------|-------------|
| **架构图** | 服务、组件、云基础设施 | 水平分层，自上而下 |
| **数据流图** | 数据在系统中的流向 | 每条箭头标注数据类型 |
| **流程图** | 决策树、流程步骤 | 菱形 = 决策，自上而下 |
| **Agent 架构图** | LLM + 工具 + 记忆 | 五层模型：输入/Agent/记忆/工具/输出 |
| **记忆架构图** | Mem0、MemGPT 风格 | 读/写路径分离，记忆层级分明 |
| **序列图** | API 调用链、时序交互 | 垂直生命线，水平消息箭头 |
| **对比图** | 功能矩阵、方案比较 | 列 = 系统，行 = 属性 |
| **思维导图** | 概念地图、发散思维 | 中心节点，贝塞尔曲线分支 |

### UML 图类型支持（14 种）

| UML 类型 | 描述 | 推荐风格 |
|----------|------|----------|
| **类图** | 类、属性、方法、关系 | 风格 1, 4 |
| **组件图** | 软件组件和依赖关系 | 风格 1, 3 |
| **部署图** | 硬件节点和软件部署 | 风格 3 |
| **包图** | 包组织和依赖关系 | 风格 1, 4 |
| **复合结构图** | 类/组件的内部结构 | 风格 1, 3 |
| **对象图** | 对象实例和关系 | 风格 1, 4 |
| **用例图** | 参与者、用例、系统边界 | 风格 1 |
| **活动图** | 工作流、并行流程 | 风格 3 |
| **状态机图** | 状态转换和事件 | 风格 2, 3 |
| **序列图** | 时间顺序的消息交换 | 风格 2 |
| **通信图** | 对象交互和消息 | 风格 1, 2 |
| **时序图** | 状态随时间的变化 | 风格 2 |
| **交互概览图** | 高层交互流程 | 风格 1, 2 |
| **ER 图** | 实体关系数据模型 | 风格 1, 3 |

---

## AI/Agent 领域内建 Pattern

Skill 内置以下领域知识，可直接描述场景生成：

```
RAG Pipeline         → Query → Embed → VectorSearch → Retrieve → LLM → Response
Agentic RAG          → 在 RAG 基础上加入 Agent 循环 + 工具调用
Agentic Search       → Query → Planner → [Search/Calc/Code] → Synthesizer
Mem0 记忆层          → Input → Memory Manager → [VectorDB + GraphDB] → Context
Agent 记忆类型       → 感知记忆 → 工作记忆 → 情景记忆 → 语义记忆 → 程序记忆
Multi-Agent          → Orchestrator → [SubAgent×N] → Aggregator → Output
Tool Call 流程       → LLM → Tool Selector → Execution → Parser → LLM (循环)
```

---

## 形状词汇表

形状在所有风格中保持一致的语义：

| 概念 | 形状 |
|------|------|
| 用户 / 人类 | 圆形 + 身体路径 |
| LLM / 模型 | 圆角矩形，双边框，⚡ |
| Agent / 编排器 | 六边形 |
| 短期记忆 | 虚线边框圆角矩形 |
| 长期记忆 | 实线圆柱体 |
| Vector Store | 带内环圆柱 |
| Graph DB | 三圆簇 |
| 工具 / 函数 | 带 ⚙ 的矩形 |
| API / 网关 | 六边形（单边框） |
| 消息队列 / 流 | 横向管道 |
| 文档 / 文件 | 折角矩形 |
| 浏览器 / UI | 带三点标题栏的矩形 |
| 决策节点 | 菱形 |
| 外部服务 | 虚线边框矩形 |

---

## 箭头语义

| 流类型 | 线宽 | 虚线 | 含义 |
|--------|------|------|------|
| 主数据流 | 2px 实线 | — | 主要请求/响应路径 |
| 控制 / 触发 | 1.5px 实线 | — | 系统 A 触发 B |
| 记忆读取 | 1.5px 实线 | — | 从存储检索 |
| 记忆写入 | 1.5px | `5,3` | 写入/存储操作 |
| 异步 / 事件 | 1.5px | `4,2` | 非阻塞 |
| 反馈 / 循环 | 1.5px 曲线 | — | 迭代推理 |

---

## 文件结构

```
fireworks-tech-graph/
├── SKILL.md                      # 主 Skill 文件 — 图类型、布局规则、形状词汇
├── README.md                     # 英文文档
├── README.zh.md                  # 本文件（中文）
├── references/
│   ├── style-1-flat-icon.md      # 白底风格 — 彩色强调色
│   ├── style-2-dark-terminal.md  # 暗黑风格 — Neon 配色，等宽字体
│   ├── style-3-blueprint.md      # 蓝图风格 — 网格底纹，青色线条
│   ├── style-4-notion-clean.md   # 极简风格 — 白底，单色箭头
│   ├── style-5-glassmorphism.md  # 玻璃态风格 — 深色渐变，磨砂卡片
│   ├── style-6-claude-official.md # Claude 官方风格 — 温暖奶油色，Anthropic 品牌
│   ├── style-7-openai.md        # OpenAI 官方风格 — 简洁白色，OpenAI 品牌配色
│   └── icons.md                  # 40+ 产品图标 + 语义形状模板
├── agents/
│   └── openai.yaml              # 兼容运行时使用的 Agent 元数据
├── fixtures/
│   ├── mem0-style1.json         # Style 1 回归样例
│   ├── tool-call-style2.json    # Style 2 回归样例
│   └── ...                      # 各风格样图级 fixture
├── scripts/
│   ├── generate-diagram.sh       # SVG 校验与 PNG 导出
│   ├── generate-from-template.py # 基于模板生成 SVG 起始文件
│   ├── validate-svg.sh           # SVG 语法校验
│   └── test-all-styles.sh        # 批量测试所有风格
├── assets/
│   └── samples/                  # 示例图 PNG
├── templates/
│   ├── architecture.svg         # 架构图模板
│   ├── data-flow.svg            # 数据流模板
│   └── ...                      # 其他图类型模板
└── agentloop-core.svg           # 仓库自带示例 SVG
```

---

## 产品图标覆盖范围

**AI/ML 模型：** OpenAI、Anthropic/Claude、Google Gemini、Meta LLaMA、Mistral、Cohere、Groq、Hugging Face

**AI 框架：** Mem0、LangChain、LlamaIndex、LangGraph、CrewAI、AutoGen、DSPy、Haystack

**向量数据库：** Pinecone、Weaviate、Qdrant、Chroma、Milvus、pgvector、Faiss

**关系型/NoSQL 数据库：** PostgreSQL、MySQL、MongoDB、Redis、Elasticsearch、Neo4j、Cassandra

**消息队列：** Kafka、RabbitMQ、NATS、Pulsar

**云服务 & 基础设施：** AWS、GCP、Azure、Cloudflare、Vercel、Docker、Kubernetes

**可观测性：** Grafana、Prometheus、Datadog、LangSmith、Langfuse、Arize

---

## License

MIT © 2025 fireworks-tech-graph contributors
