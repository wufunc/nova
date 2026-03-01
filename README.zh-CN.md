# nova

**让你的 AI 编程助手拥有跨会话的持久记忆。**

[English](README.md) | [Design Document](DESIGN.md) | [设计文档](DESIGN.zh-CN.md)

---

## 问题

AI 编程助手的每次会话都从零开始。它不记得上次为什么选了方案 A 而不是方案 B，不记得那个调试了几小时才发现的未文档化 API 陷阱，也不记得应该约束未来开发的架构决策。

这导致了**重复犯错**和**决策漂移**——精心推导的技术选择被无意推翻，因为 Agent 根本不记得它们的存在。

## 解决方案

nova 为 Claude Code、Codex 和 Cursor 提供了一套结构化的持久记忆系统，包含三种互补的记忆类型：

| 记忆类型 | 用途 | 示例 |
|---------|------|------|
| **arch.md** | 项目架构概览 | "这是一个 Next.js monorepo，后端使用 Supabase" |
| **ADR** | 架构决策记录 | "我们选择 WebSocket 而非 SSE，因为……" |
| **DevLog** | 开发经验日志 | "Sentinel API 会返回空的 PoW 配置——必须先检查 `required` 字段" |

记忆在提交代码时自动写入，在会话开始时自动召回，无需手动维护。

### 工作原理

```
会话开始                                代码提交
  │                                      │
  ▼                                      ▼
/memory recall                      /git-commit
  │                                      │
  ├─ 加载 arch.md                        ├─ 生成 commit message
  ├─ 搜索相关 ADR/DevLog                  ├─ /memory update
  └─ 向 agent 呈现上下文                   │    ├─ 更新 arch.md？
                                         │    ├─ 创建 ADR？
                                         │    └─ 创建 DevLog？
                                         ├─ Stage + commit
                                         └─ Tag (mem/NNN)
```

### 四层 Skill 架构

```
Agent 指令入口      → 触发规则（始终在上下文中）
                     （CLAUDE.md / AGENTS.md / Cursor 规则）
  └─ git-commit     → 编排层（提交工作流）
       └─ memory    → 决策层（要不要记录？）
            ├─ adr-creator    → 写入层（格式化 + 写入 ADR）
            └─ devlog-creator → 写入层（格式化 + 写入 DevLog）
```

只加载需要的层级——大多数提交只用到前两层，上下文开销极小。

## 快速开始

### 安装

```bash
# 克隆并安装
git clone https://github.com/anthropic-lab/nova.git
cd nova && bash install.sh
```

默认情况下，`install.sh` 会自动探测本机已安装的 Agent，并全部安装。
你也可以通过 `--agents` 限定目标：

```bash
bash install.sh --agents codex,cursor
```

安装位置：
- Claude：skills 安装到 `~/.claude/skills/`，规则写入 `~/.claude/CLAUDE.md`
- Codex：skills 安装到 `~/.codex/skills/`，规则写入 `~/.codex/AGENTS.md`
- Cursor：skills 安装到 `~/.cursor/skills/`，规则写入 `~/.cursor/rules/nova.mdc`

### 如何使用

nova 的记忆系统是自维护的：
- 会话开始时，Agent 自动执行 `/memory recall`
- 如果 `.nova/memory/` 不存在，系统会自动初始化
- 系统会根据仓库结构按需生成或更新 `arch.md`
- 在提交流程中，系统会自动评估并创建所需记忆（ADR/DevLog）

你唯一需要手动触发的是：每次开发完成后执行一次 `git-commit` skill（Claude/Cursor 使用 `/git-commit`，Codex 使用 `$git-commit`）。

推荐执行粒度：一次 `git-commit` 对应一个可独立验证、可独立回滚的工作单元（例如一个 bug 修复、一个小功能、一次明确目的的重构）。

粒度太大（一次包含过多改动）的缺点：
- 提交意图和记忆记录会混杂，后续检索定位更困难
- 回滚和 cherry-pick 成本更高，风险更大
- 关键决策上下文容易被无关改动淹没

粒度太小（过于碎片化频繁提交）的缺点：
- 提交历史和记忆噪声增多，阅读成本变高
- 低价值记录变多，降低后续召回信噪比
- 团队评审和问题追踪会更碎片化

### 卸载

```bash
cd nova && bash uninstall.sh
```

项目级的记忆数据（`.nova/memory/`）会被保留——如不再需要请手动删除。

## 记忆类型

### arch.md — 地图

单文件的架构概览（约 200 行），每次会话都会加载。包含技术栈、目录结构、模块职责、数据流和已知限制。首次使用时自动生成，代码变更时自动更新。

### ADR — 路标

架构决策记录，记录**为什么**做出某个技术选择。只在做出重大决策时创建（比较了 2+ 种方案并权衡利弊）。参见 [ADR 示例](examples/adr-example.md)。

### DevLog — 路人的提醒

开发经验日志，记录**非显而易见的发现**。比如隐藏的 API 行为、调试洞察、环境配置陷阱、行不通的方案等。参见 [DevLog 示例](examples/devlog-example.md)。

## 检索机制：Grep 驱动，无需索引

每条 ADR 和 DevLog 都有为 Grep 搜索优化的 YAML frontmatter：

```yaml
---
tags: [chatgpt, sentinel, pow, auth]
modules: [contents/providers/chatgpt/auth]
summary: "sentinel returns empty proofofwork, must skip PoW not error"
tag: mem/003
---
```

Agent 通过 Grep 搜索 tags、modules 和 summary——无需向量数据库、无需 embedding、无需索引文件。上下文开销为 O(K)（K = 匹配条数），而非 O(N)（N = 总条数）。

## 项目结构

```
nova/
├── skills/                    # Skill 源文件
│   ├── memory/SKILL.md        # 核心记忆 skill（召回 + 更新）
│   ├── git-commit/SKILL.md    # 提交工作流编排器
│   ├── adr-creator/           # ADR 写入器 + 格式参考
│   └── devlog-creator/        # DevLog 写入器 + 格式参考
├── templates/                 # 安装用的 Agent 指令模板
├── examples/                  # 真实示例
├── install.sh                 # 安装脚本
├── uninstall.sh               # 卸载脚本
├── DESIGN.md                  # 设计文档（英文）
├── DESIGN.zh-CN.md            # 设计文档（中文）
└── .nova/                 # 本项目自身的记忆（dogfooding）
```

## 配置

### 宪法（可选）

在任何项目中创建 `.nova/constitution.md` 来定义该项目最高优先级的原则。Agent 会在每次会话前读取它，确保所有操作（代码和记忆）都遵守这些约束。

```markdown
# 项目宪法

- 所有 API 响应必须使用 Zod schema 进行类型定义
- 禁止直接操作 DOM——必须通过 React state
- 测试覆盖率不得低于 80%
```

### 记忆目录

`.nova/memory/` 目录会自动创建。你可以将它提交到仓库，这样记忆可以在不同机器和团队成员之间持久化。

## 设计理念

本系统做出了若干刻意的设计选择：

- **Grep 而非向量搜索** — 零依赖、零维护、O(K) 上下文开销
- **Git tag 而非 commit hash** — 避免内容寻址的循环问题
- **原则驱动而非规则驱动** — 足够灵活以捕获多样化的经验
- **四层 skill 而非单体** — 最小化常见路径的上下文开销
- **基于事实的 arch.md** — 适配任意项目结构，避免空模板章节

完整设计文档：[DESIGN.md](DESIGN.md) | [设计文档](DESIGN.zh-CN.md)

## 贡献

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解提交 Issue、Pull Request 和 Skill 修改的指南。

## 许可证

[MIT](LICENSE)
