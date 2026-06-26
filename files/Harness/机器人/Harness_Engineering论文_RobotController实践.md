# Harness Engineering 在嵌入式机器人控制系统 AI 辅助开发中的实践

## ——以 RobotController Android 项目为例

---

**作者**：子豪（Zihao）  
**单位**：Android 研发工程师  
**日期**：2026 年 6 月 25 日（v2.1 修订版，新增 HMM-L4 升级数据）  
**关键词**：Harness Engineering；AI Agent；AGENTS.md；嵌入式机器人控制；架构约束治理；上下文管理；棕地项目改造；安全关键系统；HARNESS 注解；CI 红线拦截

---

## 摘要

随着大语言模型（LLM）在软件工程领域的广泛应用，AI 辅助编程已从简单的代码补全演进为完整的 Agent 驱动开发范式。然而，模型能力本身并非决定 Agent 产出质量的唯一因素——2026 年以来，以 OpenAI、Anthropic、Stripe 为代表的一线团队提出 **"Agent = Model + Harness"** 核心公式，指出决定 Agent 表现上限的往往是模型之外的环境、约束与反馈系统，即 Harness。本文系统梳理 Harness Engineering 的理论与学术研究前沿，并以 RobotController——一款基于 Android 的嵌入式机器人控制应用——为核心案例，深入剖析 Harness 在真实安全关键系统中的完整实现路径。本文采用单案例研究方法，涵盖六层架构设计、13 个规则文件约束体系、AI 强制规则加载协议、冲突裁决机制、上下文长效提醒系统、三模板命令标准化体系，以及新提出的 Harness 成熟度五级模型。实践表明，在完善的 Harness 治理体系下，项目在约 30 天开发周期内完成 2 次重大架构决策（ADR）、EventChannel 全局重构（代码量减少 58%）、多优先级缺陷修复，并在 2026-06-25 达成 HMM-L4 量化管理级：HARNESS 注解落地 25 条（覆盖 10 个核心保护函数）、CI 性能红线检查集成 pre-commit hook、自动化治理健康报告体系建立，全程零性能红线违规。本文填补了安全关键嵌入式系统 Harness 实践的文献空白，并提出了可量化的 Harness 成熟度评估框架。

---

## 1. 引言

### 1.1 研究背景

2025—2026 年，AI 编程助手从单轮代码生成向多轮 Agent 执行范式快速迁移。GitHub Copilot、Claude Code、Codex CLI 等工具使 AI 能够直接操作文件系统、执行 Shell 命令、运行测试并自主进行架构重构。工业界的统计数据令人瞩目：OpenAI 的 3 名工程师用 5 个月时间，依托 AI Agent 产出了约百万行代码、合并了约 1500 个 PR，手写代码行数为零 [1]；Stripe 的 Minions 系统每周生成 1000 余个由 AI 主导的 PR [2]；Anthropic 利用双智能体架构 6 小时内以 $200 成本构建完整可用的 Web 应用 [3]。

然而，长链路任务中的上下文污染、架构约束偏离、代码熵积累等问题也随之暴露。LangChain 的对照实验揭示了一个关键事实：同一个模型，仅改变文件编辑接口的调用方式，编码基准得分从 6.7% 跃升至 68.3%；优化 Harness 环境而非更换模型，在 Terminal Bench 2.0 上将评分从 52.8% 提升至 66.5% [4]。这揭示了 Harness Engineering 的核心命题：**系统设计比模型选择更关键**。

### 1.2 问题陈述

嵌入式机器人控制系统是典型的安全关键软件，其核心约束不可谈判：TCP 通信延迟 < 500ms（遥控响应红线）、视频端到端延迟 < 600ms（实时操作红线）、触屏响应 < 5ms、Android Doze 模式下 WakeLock 保持。在引入 AI 辅助开发后，团队面临的核心挑战是：

1. **如何确保 AI 在修改任何代码时不违反性能红线？**  
2. **如何让 AI 在长对话周期中持续遵守架构约束，而非被上下文窗口逐出？**  
3. **当多个规则冲突时，AI 如何做出符合项目最大利益的裁决？**  
4. **如何标准化 AI 的命令输入，平衡"服从指令"与"自主判断"？**  
5. **如何在棕地项目（已有 75+ Java 文件的历史代码库）中渐进式引入 Harness？**

### 1.3 主要贡献

本文的主要贡献有：

1. 系统梳理 Harness Engineering 的核心理论与学术研究前沿，涵盖 2026 年最新学术文献；
2. 提出面向嵌入式安全关键系统的 Harness 设计方法，补充业界对安全关键场景研究的不足；
3. 提出 Harness 成熟度五级模型（HMM），为 Harness 治理提供可量化的评估框架；
4. 以 RobotController 项目为案例，展示一个完整的、可复现的棕地项目 Harness 改造路径；
5. 量化评估 Harness 在约 30 天开发周期内的治理效果，提供具体数据支撑。

---

## 2. 相关研究（Related Work）

本章从 Harness Engineering 学术研究、安全关键嵌入式系统 AI 研究、AI 编程评估基准和约束式 AI 生成四个维度，梳理相关研究脉络并明确本文的定位。

### 2.1 Harness Engineering 学术研究

#### 2.1.1 Agentic Harness Engineering（AHE）

Lin et al. [R1] 提出了 AHE 闭环框架，将 Harness 从手工工艺提升为可自动化演化的工程学科。其核心贡献包括三大观测支柱：Component Observability（组件可观测性）、Experience Observability（百万级轨迹蒸馏为分层证据语料）、Decision Observability（每次编辑附带可证伪预测）。实验数据表明，10 轮 AHE 迭代将 Terminal-Bench 2 pass@1 从 69.7% 提升至 77.0%，超越人类设计的 Codex-CLI（71.9%）。消融实验进一步定位增益来源为工具、中间件和长期记忆——而非系统提示词——说明**事实性 Harness 结构可跨模型迁移**。这一发现对本研究具有重要启示：Harness 的核心资产是可迁移的约束结构，而非散文式策略描述。

#### 2.1.2 Code as Agent Harness

Ning et al. [R2] 发布了 2026 年 5 月最全面的 Harness 系统性综述（102 页），定义了三层架构：Harness Interface（推理/行动/环境建模）、Harness Mechanisms（规划/记忆/工具/控制/自适应优化）、Scaling the Harness（多 Agent 共享代码基座）。该综述将五大应用域（编码助手、GUI 自动化、具身智能体、科学发现、个性化推荐）映射到三层架构，并指出六大开放挑战——其中"安全关键操作人工监督"和"跨 Agent 一致共享状态"与本研究高度相关。

#### 2.1.3 工业界 Harness 实践

OpenAI 的 Codex CLI 将 Agent Skills 目录和自定义 Linter 作为 Harness 的核心组件 [1]；Stripe 的 Minions 采用 Blueprint 状态机和 Pre-push hook 实现约束机械化 [2]；Hashimoto 在 Ghostty 开发中建立了"每个错误对应一条 AGENTS.md 规则"的免疫积累模式 [6]；Anthropic 则探索了 GAN 启发的三 Agent 架构（生成→评审→精化）[3]；Boeckeler [7] 首次在 Martin Fowler 博客上将 Harness Engineering 术语化，指出这是 AI 辅助工程中逐渐显露的独立学科。

#### 2.1.4 现有研究的盲区

上述研究存在共同盲区：均以 Web 应用、桌面工具或通用软件开发为背景，未涉及嵌入式安全关键系统。而嵌入式系统的性能红线绝对化、线程优先级不可协商、验证环境受限等特性，对 Harness 提出了比通用场景更严格的约束要求——这正是本文试图填补的空白。

### 2.2 安全关键嵌入式系统的 AI 研究

Cazorla et al. [R3] 主持的 SAFEXPLAIN 项目（EU Horizon, 2023-2026）关注 AI 算法**嵌入**安全关键系统时的可解释性，目标是满足 ISO 26262、ISO/PAS 8800 等功能安全标准的端到端可追溯性要求。ACM Computing Surveys 的综述 [R4] 覆盖了工业和交通领域安全关键系统的 AI 应用全景。"Functional Safety Architectural Patterns for AI-Based Critical Systems" [R5] 则提出了对齐 ISO/IEC TR 5469 的模块化参考架构，其"将抽象安全约束转化为可执行设计模式"的思路与本文的 Harness 约束设计有思想共鸣。

然而，上述研究均关注 AI 算法**被集成入**安全系统的场景，而非 AI **辅助开发**安全系统的场景。后者涉及的工程挑战——如何让 AI Agent 在修改代码时持续遵守性能红线、如何将安全约束编码为 Agent 可理解和不可绕过的规则——在现有文献中几乎未被覆盖。

### 2.3 AI 编程评估基准

当前主流 AI 编程评估基准包括：HumanEval（OpenAI, 函数级代码补全）[R6]、SWE-bench / SWE-bench Verified（Princeton/UCB, 真实仓库 issue 修复）[R7]、LiveCodeBench（MIT/Cornell, 时间切片抗污染）[R8]、Aider Leaderboards（多语言代码编辑）、Terminal-Bench 2（Fudan, Agent 终端任务）[R1]。这些基准的共性局限是：**pass@k 仅评估功能正确性，不评估安全约束的遵守程度**。一个在 SWE-bench 上得分很高的方案，可能在真实嵌入式系统中因引入了主线程阻塞而直接导致机器人失控。这一评估维度缺失正是本研究提出 Harness 治理效果量化方法的动机之一。

### 2.4 约束式 AI 生成

Constitutional AI（Anthropic, 2024）[R9] 通过将行为准则编码为 AI 训练信号，实现模型输出的价值对齐——但其作用层面在**模型训练阶段**，而非运行时推理阶段。GitHub 的 spec-kit 提出 Spec-Driven Development（SDD）[R10]，将规约置于代码之前——与本文的"AI.md 三步协议强制规则加载"有思想共鸣，但作用层面不同（spec-kit 面向开发者工作流，本文面向 AI Agent 运行时约束）。

### 2.5 定位声明

综上所述，本文填补的空白是：**安全关键嵌入式系统的 AI 辅助开发 Harness 治理方法论**。与现有研究的关系为互补而非重复——AHE [R1] 关注自动化演化，本文关注手工设计；Code as Harness [R2] 提供了宏观学科定义，本文提供了嵌入式领域的实例化与扩展；SAFEXPLAIN [R3] 和功能安全架构模式 [R5] 关注 AI 嵌入系统的安全，本文关注 AI 开发系统的安全。

---

## 3. 研究方法论

### 3.1 案例研究方法

本文采用单案例嵌入式设计（Single-Case Embedded Design）方法。选择 RobotController 项目作为案例的原因如下：

1. **典型性**：系统具备安全关键系统的全部特征（实时约束、线程优先级、物理世界交互），在嵌入式控制领域具有代表性；
2. **棕地属性**：约 75 个 Java 文件的历史代码库，而非从零开始的绿地项目——这一属性使其案例结论对绝大多数工程团队更具参考价值；
3. **可追溯性**：完整的 ADR 记录、Git 提交历史、规则文件版本记录提供了充分的数据三角验证基础。

### 3.2 Harness 设计决策依据

本项目的 Harness 体系设计遵循以下决策原则：

**为什么选择六层架构而非四层？**
LangChain 的六层模型 [4] 将记忆与状态（L4）和评估与观测（L5）分离，而简化的四层模型通常将这二者合并。对于嵌入式安全关键系统，评估与观测的独立性至关重要——Python 模拟器的功能正确性验证与真机性能红线检测需要独立的验证层级，合并在记忆层中将导致职责混乱。

**为什么是六级优先级链而非三级？**
三级优先级（红线 > 建议 > 风格）对通用 Web 应用可能足够，但嵌入式系统存在"架构铁律（L1）"和"模块规范（L2）"两个独特的中间层——StateCenter 单向数据流（L1）的破坏会引发全局并发问题，而视频模块或通信模块的内部规范（L2）违反则更多是局部影响。简单的三级模型无法表达这种粒度差异。

**与形式化方法的对比**
形式化验证（如模型检查、定理证明）理论上可以提供更强的安全保证，但其在 Java 8 Android 工程的现有代码库上引入成本极高，且需要开发者具备形式化规约编写能力。本项目的 Harness 采用"轻量级约束 + 自检触发器"方案，以较低的引入成本获得可接受的安全保证。

### 3.3 数据收集方式

治理效果的量化数据来自以下来源：

| 数据项 | 收集方式 | 统计周期 |
|--------|---------|---------|
| 性能红线违规次数 | 代码静态审查 + AI 自检清单记录 + Python 模拟器验证 | 2026-05-25 至 2026-06-25（30 天） |
| 架构铁律违反次数 | 代码审查 + ADR 记录交叉验证 | 同上 |
| EventChannel 重构数据 | ADR-002 v1.3 记录 + Git diff 统计 | 2026-06-12（重构当日） |
| 缺陷修复次数 | Git 提交历史 + 修复报告文档 | 2026-06-25 集中合入 |
| 规则冲突次数 | AI 对话中"冲突裁决报告"触发频率的回顾性统计 | 2026-05-25 至 2026-06-25 |
| 规则文件行数 | 文件系统 `wc -l` 统计 | 2026-06-25 快照 |

---

## 4. Harness Engineering 理论基础

### 4.1 核心定义与公式

Harness Engineering 是一门围绕 AI Agent 构建约束系统、反馈回路和执行环境的工程学科 [5]。其核心公式为：

$$\text{Agent} = \text{Model} + \text{Harness}$$

其中，Model 提供推理与生成能力，Harness 负责状态管理、工具调用、约束执行、反馈验证和环境安全。类比而言，Model 是 CPU，Harness 是操作系统——CPU 再强，OS 如果天天崩，体验也不会好 [4]。

该术语由 Mitchell Hashimoto（HashiCorp 联合创始人）提出，并在 2026 年初 OpenAI 发布关于 Codex 的公开文章后获得主流关注 [6]。

### 4.2 Harness 与 Prompt Engineering 的层级关系

Harness Engineering 与 Prompt Engineering、Context Engineering 不适合放在同一层比较，它们是一层套一层的关系：

| 层级 | 解决的核心问题 | 关注点 |
|------|--------------|--------|
| **Prompt Engineering** | 怎么把指令说清楚 | 让模型理解意图，减少局部歧义 |
| **Context Engineering** | 该给 Agent 看什么 | 在合适时机提供正确且必要的信息 |
| **Harness Engineering** | 系统怎么持续执行、纠偏、观测和恢复 | 长链路任务中的持续正确、偏差修正、故障恢复 |

对简单任务，Prompt 够用。需要外部知识时，Context 更重要。到了长链路、可执行、低容错的安全关键场景，Harness 才是主要矛盾 [4]。

### 4.3 Harness 的六层架构模型

根据 LangChain、OpenAI 等团队的系统设计经验，成熟的 Harness 可分为六层 [4][7]：

| 层级 | 名称 | 核心问题 | 关键设计 |
|------|------|----------|----------|
| **L1** | 信息边界层 | Agent 该知道什么、不该知道什么 | 角色定义、渐进式披露、任务状态管理 |
| **L2** | 工具系统层 | Agent 如何与外部世界交互 | 工具抽象、结果提炼、调用时机控制 |
| **L3** | 执行编排层 | 多步骤任务如何串联 | 工作流引擎、确定性节点与 Agent 节点混排 |
| **L4** | 记忆与状态层 | 长任务中间结果如何管理 | 会话间记忆、进度追踪、结构化持久化 |
| **L5** | 评估与观测层 | Agent 如何判断自己做对了 | 独立验证、可观测性暴露、质量度量 |
| **L6** | 约束校验与恢复层 | 出错时怎么办 | 规则拦截、重试策略、回滚机制 |

建议从 L1 和 L6 开始：先让 Agent 知道该干什么，再给它设置出错后的拦截和恢复机制，这两层投入最低但通常最容易见效 [4]。

### 4.4 上下文衰减与管理策略

Dex Horthy 观察到一个关键现象：168K token 的上下文窗口，用到约 40% 时 Agent 输出质量开始明显下降。Anthropic 将此称为"上下文焦虑"——Sonnet 4.5 在上下文快满时变得犹豫，甚至倾向于提前收工 [3]。

| 区间 | 表现 |
|------|------|
| 0 - ~40%（Smart Zone）| 推理聚焦、工具调用准确、代码质量高 |
| 超过 ~40%（Dumb Zone）| 幻觉增多、兜圈子、格式混乱、代码变差 |

一线团队的应对策略包括：渐进式披露（按需加载，而非一次性塞入所有规则）、上下文重置（保存结构化进度后以干净状态重启 Agent）、规则分层（核心红线永远在首屏，详细规则按需拉取）。

### 4.5 十大核心实践

结合 OpenAI、Anthropic、Stripe、Hashimoto 等团队的一线经验 [1][2][3][6]，Harness Engineering 的十大核心实践为：

1. **AGENTS.md 免疫系统**：每个 Agent 错误对应一条规则，持续积累形成防错屏障
2. **架构约束机械化执行**：通过 Linter/CI 强制执行，而非仅靠文档说明
3. **应用可观测性对 Agent 可见**：Agent 可访问日志、指标、DOM 快照
4. **闭环自验证**：强制 Build-Verify-Fix 循环，消除"第一个可信方案"偏差
5. **会话间记忆**：结构化进度文件 + 上下文重置，对抗长会话质量衰减
6. **熵治理**：后台清理 Agent 定期扫描代码冗余、架构违规
7. **渐进式披露**：按需加载上下文，避免信息过载
8. **Blueprint 模式**：确定性节点与概率性节点交替编排
9. **Trace 驱动迭代**：基于失败案例的定向规则补充
10. **渐进式采纳路径**：从基础约束到自治循环的阶段性演进

---

## 5. RobotController 项目背景

### 5.1 系统概况

RobotController 是一款基于 Android 的嵌入式机器人控制系统，服务于工业清洁机器人的远程操控场景（如幕墙擦窗机器人）。系统通过 WiFi/TCP 与机器人通信，核心功能模块如下：

| 功能模块 | 技术实现 | 关键指标 |
|---------|---------|---------|
| **TCP/UDP 通信** | TCPCommunicationManager / WiFiCommunicationManager | 延迟 < 500ms |
| **MAVLink 协议** | 自实现编解码器，指数退避重连 | 解析耗时 < 1ms |
| **双路视频流** | libVLC 3.7.2，network-caching=0ms | 延迟 < 600ms |
| **视频录制** | VLC `:sout=duplicate` 分流，零额外线程 | 录制中延迟无增加 |
| **语音告警** | SoundPool V2.0，优先级队列容量 3 | 触发延迟 < 50ms |
| **触屏手柄** | TouchGamepadController + MotionSafetyFilter | 触摸响应 < 5ms |
| **蓝牙/USB 手柄** | BluetoothGamepadManager + DirectInput | 输入延迟 < 10ms |
| **AI 视觉** | TFLite 障碍物检测，5fps，独立 HandlerThread | 新增延迟 < 80ms |
| **日志系统** | LogManager，静态缓存，异步落盘 | 首次加载 < 500ms |

**技术栈**：Java 8，Android minSdk 21 / targetSdk 35，Gradle 三模块（`:core` + `:app` + `:tools`），EventChannel 泛型事件总线。

### 5.2 安全关键约束

本项目属于实时控制系统，任何性能退化都直接影响机器人安全。核心性能红线如下：

| 红线 | 阈值 | 违反后果 |
|------|------|----------|
| TCP 通信延迟 | **< 500ms** | 遥控响应迟缓 → 机器人失控风险 |
| 视频端到端延迟 | **< 600ms** | 画面卡顿 → 操作员无法实时判断 |
| 触屏触摸响应 | **< 5ms** | 操控手感恶化 → 精细操作失效 |
| 双路错开启停 | **≥ 500ms 间隔** | CPU 爆冲 → 双路同时丢帧 |

这些约束在引入 AI 辅助开发时面临严峻挑战：AI 可能在不了解系统背景的情况下，以"优化"名义引入阻塞操作、提升低优先级线程或修改核心常量，导致延迟飙升。因此，本项目的 Harness 必须将性能红线作为第一优先级约束。

---

## 6. RobotController 的 Harness 体系设计

### 6.1 总体架构

RobotController 的 Harness 体系遵循六层架构思想，根据嵌入式安全关键系统的特殊需求进行了定制强化，形成三大支柱与两条生命线的完整结构：

```
┌─────────────────────────────────────────────────────────────────┐
│                    Harness 治理体系总架构                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐    │
│  │  规则约束系统   │  │  命令标准化系统 │  │  知识供给系统   │    │
│  │                │  │                │  │                │    │
│  │ 00 最高原则     │  │ 模板A 完整分析  │  │ AI.md (677行)  │    │
│  │ 01 全局约束     │  │ 模板B 快速执行  │  │ docs/ (60+文档)│    │
│  │ 02 视频规范     │  │ 模板C 性能专项  │  │ ADR (决策记录) │    │
│  │ 03 通信规范     │  │                │  │ SOP (流程标准) │    │
│  │ 04 状态/UI      │  └────────────────┘  └────────────────┘    │
│  │ 05 约束速查     │                                             │
│  │ 06 关键功能保护 │  ┌────────────────┐  ┌────────────────┐    │
│  │ 07 日志规范     │  │  冲突裁决机制   │  │  长效提醒机制   │    │
│  │ 08 发布规范     │  │                │  │                │    │
│  │ 09 冲突裁决     │  │ 6级优先级链     │  │ 4级提醒系统    │    │
│  │ 10 长效提醒     │  │ 冲突裁决模板   │  │ 规则指纹记忆   │    │
│  │ AI行为约束     │  │ 同级冲突提权   │  │ 自检触发器     │    │
│  │ 规则检查模板   │  └────────────────┘  └────────────────┘    │
│  └────────────────┘                                             │
│                          ↓                                      │
│              AI 强制规则加载协议（三步执行框架）                     │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 规则约束系统（13 文件，2113 行）

规则约束系统是整个 Harness 的核心，由 13 个 Markdown 文件组成，按优先级分六层组织：

```
层级 0（绝对红线）    TCP < 500ms, Video < 600ms, 触摸 < 5ms
层级 1（架构铁律）    StateCenter 单向数据流, B4 Activity 拆分原则
层级 2（模块规范）    视频(02), 通信(03), UI/状态(04)
层级 3（约束速查）    关键约束值(05), 关键功能保护(06), 日志(07)
层级 4（辅助规范）    发布上线(08), AI行为约束
层级 5（建议级）      代码风格, 命名约定
```

#### 6.2.1 关键规则文件设计

**00-最高原则.md**（118 行）是 Harness 的"宪法"，定义不可协商的性能红线。其独特设计是末尾内嵌的 **AI 自检触发器**——AI 读取该文件后，必须逐项输出 5 项强制校验结果，任何不合格项直接驳回方案：

```
【最高原则自检】
1. TCP 延迟影响：________（无影响 / 有影响→说明补偿措施）
2. 视频延迟影响：________（无影响 / 有影响→说明补偿措施）
3. 禁止操作命中：________（无 / 有→驳回方案）
4. 线程优先级变更：________（无 / 有→驳回方案）
5. 回滚预案：________（已就绪 / 缺失→补充）
```

**06-关键功能保护规范.md**（286 行）采用"禁止修改清单"模式，精确到行号级别标注保护区域。例如，`recvLoop()` 方法标注为 `★ 关键功能：TCP 接收循环`，附带允许与禁止操作的完整列表：

```java
// 禁止在 recvLoop() 中添加：
// ❌ 文件 I/O 操作
// ❌ 数据库读写
// ❌ 复杂字符串拼接（GC 压力）
// ❌ Thread.sleep() 或 wait()
// 允许的操作：
// ✅ inputStream.read(buf)    — 核心接收
// ✅ wakeLock.acquire(10000)  — Doze 防护
// ✅ mavLinkManager.feed()    — MAVLink 解析（纯计算）
```

**09-规则冲突裁决机制.md**（152 行）建立了完整的裁决决策树。当检测到多层规则冲突时，AI 必须按 6 级优先级链裁决，并输出标准化的"冲突裁决报告"。同级规则冲突（如正确性 vs 正确性）必须提请人类裁决——这一设计防止了 AI 在安全关键决策上的僭越。

**10-上下文长效提醒机制.md**（174 行）是专门对抗"规则被逐出上下文窗口"问题的方案。其四级提醒系统：

| 级别 | 机制 | 触发条件 |
|------|------|---------|
| Level 1 | 规则指纹（70 字符）| 始终在工作记忆中 |
| Level 2 | 自检触发器 | 每 5 轮对话自动触发 |
| Level 3 | 模块入口注入 | 读取特定文件时自动拉取关联规则 |
| Level 4 | 对话阶段健康检查 | 按对话长度分级检查 |

规则指纹（Level 1）设计为仅 70 字符，可永久驻留上下文首位：

```
🚨 TCP<500ms Video<600ms StateCenter-only B4-Activity-light
```

#### 6.2.2 线程优先级规范（不可协商的工程约束）

线程优先级规范是本项目 Harness 中最具代表性的"约束机械化"案例：

| 线程名称 | 优先级 | 所属模块 | 原因 |
|---------|--------|---------|------|
| `tcp-recv` | MAX_PRIORITY (10) | TCPCommunicationManager | TCP 接收必须实时 |
| `video-recv` | MAX_PRIORITY - 1 (9) | TcpVideoChannel | 视频接收次重要 |
| `tcp-send` | NORM_PRIORITY (5) | TCPCommunicationManager | 发送可微延迟 |
| `Heartbeat` | NORM_PRIORITY (5) | HeartbeatModule | 间隔 5s，不紧急 |
| `Record-IO-Thread` | THREAD_PRIORITY_BACKGROUND | VideoRecorderManager | 录制 IO 不得抢占音视频链路 |

任何试图修改线程优先级的 AI 方案，必须先通过规则文件的强制自检，否则直接驳回。

### 6.3 AI 强制规则加载协议（三步执行框架）

`AI.md`（677 行）是整个 Harness 的总入口，顶部定义三步强制协议，要求 AI 在处理任何代码修改请求前必须完成：

```
修改请求 → Step 1: 加载规则 → Step 2: 填写自检清单 → Step 3: 检查冲突 → 执行修改
              ↓ 失败                   ↓ 未完成              ↓ 有冲突
          拒绝执行                 补充后继续             裁决后继续
```

**Step 1 强制加载规则（30 秒内完成）**：

```
□ 打开并阅读 .codebuddy/rules/00-最高原则.md          ← 性能红线
□ 打开并阅读 .codebuddy/rules/06-关键功能保护规范.md   ← 禁止操作清单
□ 确认本次修改涉及的模块规则（视频→02，通信→03）
□ 检查 AI.md §0 关键功能保护摘要
```

**Step 2 填写自检清单（5 项必须全部回答）**：

```
□ 我的修改会新增网络请求或 I/O 吗？        → 如果是，可能增加延迟
□ 我的修改会新增线程或修改线程优先级吗？    → 如果是，可能抢占 TCP/视频 CPU
□ 我的修改会在主线程做耗时操作吗？          → 如果是，可能阻塞视频渲染
□ 我的修改会产生大量 GC 吗？               → 如果是，可能干扰解码线程
□ 我修改了任何常量值吗？                   → 如果是，必须检查对 TCP/视频的影响
```

**Step 3 规则冲突裁决**：当多个规则冲突时，按六级优先级链执行，不可自行裁决同级冲突。

### 6.4 命令标准化系统（三模板决策树）

**AI 命令模板指南**提供了一个四路决策树，将 AI 命令场景分为三种标准模板：

| 模板 | 适用场景 | 核心机制 |
|------|---------|---------|
| **模板 A - 完整分析** | 大功能/重构/不确定方案 | 5 角色审核（调研→架构→工程→产品→QA）+ 12 维度评估 |
| **模板 B - 快速执行** | Bug 修复/小改动 | 先执行强制规则加载协议 + 输出 5 项自检清单 |
| **模板 C - 性能专项** | 延迟/内存优化 | 三级风险分类（无风险/低风险/高风险）+ 基线对比 |

三类模板共用统一的"执行原则"：

| 原则 | 说明 |
|------|------|
| **红线优先** | 指令可能违规 → 先指出风险，等确认再执行 |
| **主动优化** | 指令不够优但不违规 → 给出更优方案供选择 |
| **规则可挑战** | 规则有更优理解 → 说明理由后执行 |

该设计在"服从指令"与"自主判断"之间建立了明确边界——AI 不是简单的命令执行器，也不是无边界的自由决策者。

### 6.5 知识供给系统（文档化架构决策）

#### 6.5.1 AI.md 渐进式披露设计

`AI.md` 的设计理念与 OpenAI 的 100 行 AGENTS.md 目录结构高度一致：顶部放置强制规则加载协议（约 50 行，所有 AI 每次处理请求都要加载），后续章节按模块组织详细约束、SOP 和速查信息，按需渐进加载，而非一次性塞入上下文。

#### 6.5.2 架构决策记录（ADR）

通过 ADR-001（Gradle 模块化拆分，Phases 1-3）和 ADR-002（EventChannel 事件通道重构，v1.3），项目将重大架构决策固化为持久文档，AI 在涉及相关模块时可自动引用，避免在不了解背景的情况下做出与历史决策冲突的建议。

#### 6.5.3 文档-代码双向链接（HARNESS 注解体系）

在 HMM-L3→L4 升级中，文档-代码双向链接已从"改进方向"实现为正式治理基础设施：

```java
// HARNESS: rule=.codebuddy/rules/06-关键功能保护规范.md §2.1
// HARNESS: performance-redline: TCP<500ms
// HARNESS: thread-priority: tcp-recv=MAX_PRIORITY
private void recvLoop() { ... }
```

**落地数据（2026-06-25）**：

| 指标 | 数值 |
|------|------|
| HARNESS 注解总数 | 25 条（覆盖 6 个 Java 文件） |
| 含规则引用（rule=） | 10 条 |
| 含性能红线（redline） | 10 条 |
| 含线程优先级约束 | 3 条 |
| 覆盖核心保护函数 | 10 个（recvLoop / WakeLock / tcp-recv 线程 / network-caching / createAndStartVlc / handleReconnect / STAGGER_START_MS / HeartbeatModule / TCP_RECV_LOOP_SO_TIMEOUT_MS / TCP_RECONNECT_MAX_BACKOFF_MS） |
| 审计验证结果 | 0 ERROR, CI 模式通过 |

配套的 `scripts/harness_audit.py` 自动扫描代码中的 `HARNESS:` 注解，与规则文件交叉验证规则引用有效性、性能红线一致性和关键文件缺失注解检测，确保文档-代码的持续一致性。

### 6.6 Harness 六层架构映射

将 RobotController 的 Harness 组件映射到标准六层架构：

| 六层 | RobotController 对应实现 |
|------|------------------------|
| **L1 信息边界** | AI.md §AI 强制规则加载协议（定义 AI 的权限与默认加载范围）；渐进式规则分层 |
| **L2 工具系统** | AI 编程助手的文件读写、Shell 执行、Grep 搜索能力；Python 模拟器测试脚本 |
| **L3 执行编排** | 三步协议（加载→自检→裁决）；SOP 标准流程（SOP-1~4）；三模板命令决策树 |
| **L4 记忆与状态** | `.codebuddy/rules/` 13 个规则文件；AI.md 版本记录；ADR 决策历史；四级长效提醒 |
| **L5 评估与观测** | 5 项强制自检清单；冲突裁决报告模板；Python 模拟器性能验证 |
| **L6 约束与恢复** | 禁止修改清单（行号级保护）；自检触发器（读文件即触发）；6 级优先级裁决树；回滚协议 |

---

## 7. Harness 的实际治理效果

### 7.1 量化产出数据（约 30 天周期）

以下数据覆盖 2026 年 5 月 25 日至 6 月 25 日，Harness 完整运行期间。数据来源包括代码静态审查、AI 自检清单记录、Python 模拟器验证、Git 提交历史和 ADR 记录交叉验证：

| 类别 | 指标 | 数据 |
|------|------|------|
| **架构治理** | ADR 架构决策记录 | 2 项（ADR-001 Gradle 模块化 + ADR-002 EventChannel 重构） |
| **代码重构** | EventChannel 迁移文件数 | 14 个文件，5 个模块 |
| **代码质量** | StateCenter 代码量变化 | 508 行 → 215 行（减少 58%） |
| **API 清洁度** | 旧 API 残留 | 0 处（全量清零，零 @Deprecated） |
| **文档体系** | 设计文档总数 | 60+ 篇 |
| **缺陷修复** | P0 崩溃修复 | 1 次（VLC Surface 重复绑定崩溃） |
| **缺陷修复** | P1 延迟/稳定性优化 | 4 项（SO_TIMEOUT 100ms、重连退避、MAVLink 缓冲区、卡顿监控） |
| **缺陷修复** | P2 体验优化 | 2 项（心跳日志限频、断连资源回收） |
| **规则治理** | 规则文件 | 13 个，2113 行 |
| **安全指标** | 性能红线违规次数 | **0 次** |
| **安全指标** | 架构铁律违反次数 | **0 次** |
| **安全指标** | 模块间不当直接调用 | **0 次** |

### 7.2 规则冲突频率量化分析

在 30 天周期内，AI 对话中共触发 10 次冲突裁决。按冲突类型统计如下：

| 冲突类型 | 发生次数 | 占比 | 趋势（第1周→第4周）| 说明 |
|---------|---------|------|-------------------|------|
| 性能红线 vs 代码简洁性 | 3 | 30% | 3→0 | 早期 AI 倾向引入"优化"但阻塞操作，规则积累后消失 |
| 架构铁律 vs 向后兼容 | 5 | 50% | 4→1 | 最频繁类型，AI 常因"不破坏现有功能"而绕过 StateCenter；后期通过强制自检显著减少 |
| 模块规范 vs 全局约束 | 2 | 20% | 2→0 | 模块级 LogManager 规范与全局通信规范在日志落盘时机上出现冲突 |
| 同级规则冲突（正确性 vs 正确性）| 0 | 0% | — | 30 天内未触发同级冲突（均通过优先级链解决），验证了分层设计的合理性 |

**趋势分析**：冲突频率从第 1 周的每周 6 次下降到第 4 周的每周 1 次（-83%），说明 Harness 的"错误驱动规则积累"机制正在生效——每次裁决后补充对应规则，与 Hashimoto 的 AGENTS.md 免疫积累模式一致。

### 7.3 关键治理事件详析

#### 事件 1：ADR-002 EventChannel 全局重构（2026-06-12）

这是本项目 Harness 治理效果最具说服力的案例。`StateCenter` 是全局唯一通信枢纽，随项目迭代积累了 13 个 `CopyOnWriteArrayList`、volatile 字段和大量 `@Deprecated` 方法，持续违反开闭原则。

Harness 约束在重构中的关键作用：

**架构铁律约束层（L1）**：AI 被规则文件约束为"新增事件类型仅在 StateCenter 加 1 行 `public final EventChannel<X>` 字段"，从根本上消除了膨胀的可能。

**执行编排层（L3）**：AI 按照 5 个 Phase 的 SOP 逐步迁移，每个 Phase 独立验证（`javac` 编译 0 错误），确保整个迁移过程可回滚。

**约束与恢复层（L6）**：Phase 2-4 迁移中发现 `VideoController.java` 构造函数末尾 `}` 被意外删除，自检机制立即触发，在编译验证阶段捕获并修复，未造成任何功能回归。

最终结果：508 行 → 215 行（-58%），全项目 0 处旧 API 引用，21 个测试用例全部通过。

**关键洞察**：如果没有 Harness 的约束，AI 极可能将迁移分散到多个文件的"局部最优"，而非形成一致的、可独立测试的 EventChannel 体系。

#### 事件 2：ADR-001 Gradle 三模块化拆分（2026-06-12）

ADR-001 将约 75 个 Java 文件的单模块项目拆分为 `:core`/`:app`/`:tools` 三模块。Harness 在此的作用体现在：

**决策记录约束**：ADR 明确规定"不到 Phase 2 触发条件（`:core` > 3 个子包，单次编译 > 30 秒，引入独立机器人协议库）就不拆分"，防止 AI 因"未来可能需要"而过度拆分。

**依赖方向保护**：规则文件明确标注 "`:core` 禁止依赖任何其他模块"，配合编译器级强制（Gradle 无法反向依赖），将人工规范提升为机械化约束。

#### 事件 3：P0 VLC 崩溃修复（2026-06-25）

Surface 重复绑定导致的 P0 崩溃。Harness 确保：

1. AI 在分析修复方案前，强制阅读 06-关键功能保护规范，确认修复不影响 video-recv 线程
2. 自检清单第 1 项"会新增 I/O 吗"和第 4 项"会产生大量 GC 吗"均输出"无影响"
3. 修复方案通过 Python 模拟器脚本验证（当前唯一可用的验证手段）

#### 事件 4：P1 TCP 卡顿修复

SO_TIMEOUT 从 3000ms 降至 100ms 解决偶发性卡顿。这是一个典型的"常量修改"场景，自检清单第 5 项"修改了常量值"触发强制评估——AI 必须输出对 TCP 延迟的影响分析，确认 100ms 超时不会导致误断连后，方可执行修改。

### 7.4 棕地项目改造路径

与 OpenAI、Anthropic 的绿地项目不同，RobotController 是一个已运行约 75 个 Java 文件的历史代码库。Harness 的引入经历了以下渐进演进：

```
Phase 1: AI.md 单文件约束
    ↓ 规则复杂度提升
Phase 2: .codebuddy/rules/ 模块化拆分（6 → 13 个规则文件）
    ↓ 命令随意性暴露
Phase 3: 命令模板标准化（三模板决策树 + 执行原则）
    ↓ 规则冲突事件触发
Phase 4: 冲突裁决机制（6 级优先级链 + 裁决报告模板）
    ↓ 长会话质量衰减观察
Phase 5: 长效提醒机制（4 级提醒系统 + 规则指纹 + 自检触发器）
    ↓ HMM-L3→L4 升级
Phase 6: 量化管理落地（HARNESS 注解 25 条 + harne_audit.py CI 审计
         + ci_redline_check.sh pre-commit 集成 + harness_stats.py 周报）
```

这一路径验证了 Harness 渐进式采纳的可行性：**先做 L1 信息边界和 L6 约束恢复，再逐步补齐中间层**，且全程不中断现有功能。

### 7.5 与业界标准实践的对照

| 实践维度 | OpenAI [1] | Hashimoto [6] | Stripe [2] | 本项目 |
|---------|-----------|--------------|-----------|--------|
| 上下文文件 | AGENTS.md 约 100 行目录 | 每行对应一个历史失败 | 仓库即事实来源 | AI.md 677 行 + 13 规则文件分层 |
| 架构约束执行 | 自定义 Linter + 结构测试 | AGENTS.md 免疫积累 | Pre-push hook | 自检触发器 + 冲突裁决模板 |
| 上下文对抗 | 渐进式披露 | 单 Agent + 下班启动 | Devbox 隔离 | 4 级长效提醒 + 70 字规则指纹 |
| 熵治理 | 后台清理 Agent | 错误驱动规则积累 | 300 万测试维护 | 文档同步自动触发 + ADR 固化 |
| 命令标准化 | Agent Skills 目录 | 6 步渐进路径 | Blueprint 状态机 | 三模板决策树 + 执行原则 |
| 项目类型 | 绿地项目 | 绿地项目（Ghostty） | 大型绿地 | **棕地改造** |
| 安全级别 | 通用 Web | 桌面工具 | 支付系统 | **嵌入式实时控制** |

---

## 8. Harness 成熟度模型

### 8.1 模型定义

参考 CMMI（能力成熟度模型集成）的分级方法论，本研究提出 Harness 成熟度模型（Harness Maturity Model, HMM），将 Harness 治理水平分为五个等级：

| 级别 | 名称 | 特征 | L1-L6 覆盖 | 关键标志 |
|------|------|------|-----------|---------|
| **HMM-L1** | 初始级（Initial） | 无规则文件或仅有零散约束，AI 输出完全不可预测 | 无 | 开发者靠口头经验约束 AI |
| **HMM-L2** | 管理级（Managed） | 有基础规则文件，定义了核心约束（如最高原则），但约束为纯文本描述，无强制执行 | L1 部分, L6 雏形 | 有 AI.md 或 AGENTS.md 文件，但无自检机制 |
| **HMM-L3** | 定义级（Defined） | 规则分层 + 冲突裁决机制 + 自检触发器；约束从纯文本升级为可执行的检查流程 | L1, L3, L6 部分 | 本项目当前状态（参见下方评估） |
| **HMM-L4** | 量化级（Quantitatively Managed） | 规则有效性通过量化指标测量；引入自动化审计（规则-代码一致性扫描、冲突频率统计）；CI 级红线拦截 | L1-L6 全覆盖 | 自动化规则审计脚本、性能红线 CI Task |
| **HMM-L5** | 优化级（Optimizing） | 规则自动演化——AI 基于故障案例自动提出规则优化建议并自评；跨模型 Harness 可迁移性验证 | L1-L6 全覆盖 + 自适应 | 无人干预的规则自我迭代、AHE 闭环 |

### 8.2 本项目的成熟度评估

RobotController 项目已于 **2026-06-25** 完成 HMM-L3→L4 升级，当前处于 **HMM-L4（量化级）**。具体判定依据如下：

| 维度 | 当前状态 | 达到 HMM-L4 的标志 |
|------|---------|---------------------|
| 规则文件覆盖 | 13 个文件，2113 行，覆盖 L1-L6 | —（L3 已满足） |
| 约束强制执行 | 自检触发器 + 禁止修改清单 + 6 级优先级链 | ✅ **CI 级红线拦截**：`ci_redline_check.sh` 已集成 pre-commit hook（6 大类检查，提交时自动拦截） |
| 量化度量 | 冲突频率回顾性统计 | ✅ **自动化治理健康报告**：`harness_stats.py` 每周生成 HMM 评估 + 豁免统计 + 假阳性追踪 |
| 规则-代码一致性 | 周期性人工审计 | ✅ **HARNESS 注解落地**：25 条注解覆盖 10 个核心保护函数 + `harness_audit.py` CI 级自动一致性审计 |
| 治理脚本文档 | 无 | ✅ **使用手册完成**：`架构_手册_v1.0_治理脚本使用指南.md`（含频率建议、输出解读、治理闭环图） |

### 8.3 对标分析

将现有工业界案例纳入 HMM 框架：

| 组织/项目 | HMM 级别 | 判定依据 |
|----------|---------|---------|
| OpenAI Codex CLI [1] | L4 | 自定义 Linter + 结构测试 + Agent Skills 目录；但无规则自我演化能力 |
| Stripe Minions [2] | L3→L4 | Pre-push hook + Blueprint 状态机；但上下文管理主要靠 Devbox 隔离，缺乏分层提醒 |
| Hashimoto Ghostty [6] | L3 | AGENTS.md 免疫积累 + 持续规则补充；但无系统化分层和冲突裁决 |
| Anthropic Labs [3] | L3→L4 | 三 Agent 架构提供了一定程度的自我评审；但更侧重架构创新而非约束积累 |
| **本项目 RobotController** | **L3→L4** | **规则分层最完善、约束最严格（嵌入式安全关键场景），但缺乏 CI 级自动化和模型迁移验证** |

---

## 9. 讨论

### 9.1 嵌入式系统 Harness 的三大特殊性

相比于 Web 应用，嵌入式安全关键系统的 Harness 有三个特殊要求：

**① 性能约束的优先级必须绝对化**

Web 系统的"性能优化"通常是建议级；嵌入式控制系统的 TCP < 500ms / Video < 600ms 是生存红线。Harness 必须将这些约束置于所有其他规则之上，且不允许任何豁免。本项目通过"最高原则 > 全局约束 > 模块规范"的六级优先级链，以及不可绕过的自检触发器，实现了绝对化约束。

**② 线程优先级表不可动态协商**

嵌入式实时系统中，线程优先级是系统调度的核心。tcp-recv = MAX_PRIORITY (10)、video-recv = MAX-1 (9)，这些数值不是建议，是系统稳定性的基础。Harness 通过行号级精确保护 + 自检触发器，将线程优先级表从"文档规范"升级为"不可绕过的机械约束"。

**③ 验证环境受限的适应性设计**

嵌入式系统通常无法随时运行真机测试。本项目的 Harness 在验证层做出适应性设计：明确标注"当前可用验证手段：Python 模拟器脚本"，并规定"AI 不可仅因测试脚本失败即回滚代码，必须先分析失败原因归属（代码回归 vs 测试框架限制）"。这一务实的设计避免了因验证条件限制而导致的无效回滚。

### 9.2 棕地项目 Harness 改造的关键发现

业界公开案例（OpenAI、Anthropic、Hashimoto）几乎都是绿地项目，而棕地项目改造是绝大多数工程团队面临的真实场景。本项目提供了以下关键经验：

**渐进性优于完整性**：不要等到 Harness 六层全部设计好再引入。先做 L1（AI.md + 基础规则）和 L6（禁止修改清单），即使只有这两层，也能显著减少 AI 的有害修改。

**错误驱动规则积累**：与 Hashimoto 的 AGENTS.md 模式一致，每次 AI 出错（如意外删除 `}`、修改 TCP 常量未评估影响），就在 Harness 中增加对应规则，使 Harness 随时间持续强化。第 7.2 节的冲突频率趋势（-83%）验证了这一策略的有效性。

**人类判断的不可替代性**：同级规则冲突（如"代码简洁性 vs 向后兼容性"）必须由人类裁决，Harness 只负责识别冲突和提供裁决框架，不应赋予 AI 最终决策权。30 天周期内未触发同级冲突，说明良好的分层设计可以有效避免人类裁决的高频触发。

### 9.3 局限性与改进方向

#### 9.3.1 验证闭环不完整

真机 ADB 性能测试当前不可执行，Python 模拟器只能覆盖部分场景，存在理论上的验证盲区。未来可引入 Android Profiler Trace 解析，自动检测 `recvLoop()` 执行时间是否超过 500ms 阈值。

#### 9.3.2 规则维护成本

13 个规则文件共 2113 行，需要人工保持与代码的一致性。当前维护成本约为每周 30 分钟（版本迭代时更新受影响的规则文件行号）。行号偏移超过 ±5 行的概率约 15%（每次代码重构可能移动方法位置）。引入自动化审计 Agent 可以降低此成本。

#### 9.3.3 Harness 对 AI 模型版本的敏感度

本研究的 Harness 实现以 WorkBuddy（CodeBuddy App）为宿主环境，规则的有效性和强制加载协议的可靠性依赖于特定 AI 编程助手的能力。Lin et al. 的 AHE 研究 [R1] 表明，冻结的 Harness 结构可跨模型迁移（收益 +5.1~+10.1pp），但该结论的适用性需要根据具体宿主环境验证。建议后续研究设计交叉验证实验：用同一套规则文件分别接入不同 AI 编程助手，对比约束遵守率。

#### 9.3.4 Harness 是否抑制了合理创新（假阳性拦截）

当前设计未追踪"被自检触发器拦截但实际上是合理方案"的次数。理论上，严格的约束系统可能抑制 AI 的创新性重构建议（如将某个线程优先级从 NORM 调整为 MAX 可能是新的性能优化策略）。建议在 AI.md 中增加"规则挑战通道"，允许 AI 在充分论证后申请规则豁免，并记录每次豁免的合理性和后续结果。

#### 9.3.5 功能正确性验证薄弱

目前更多依赖编译验证（`javac` 0 错误）而非端到端功能测试，与 Boeckeler [7] 指出的业界共性问题一致。可参考 AHE [R1] 的 Decision Observability 思路，在每次代码修改后附加可证伪的功能预测（如"修改后 MAVLink 心跳间隔应为 5s ± 0.1s"），并在 CI 中自动化验证该预测。

---

## 10. 结论

本文系统阐述了 Harness Engineering 的理论框架，并结合 2026 年最新学术研究，以 RobotController 嵌入式机器人控制系统为案例，展示了 Harness 在安全关键场景与棕地项目中的完整实践。

**核心结论如下**：

1. **Harness Engineering 重新定义了 AI 辅助开发的质量上限**。在"Agent = Model + Harness"范式下，Harness 的设计质量对 Agent 表现的影响不亚于模型选择。Lin et al. 的 AHE 实验 [R1] 和 LangChain 的对照数据（6.7% → 68.3%）共同证明，正确的系统设计可以实现数量级的能力提升。

2. **安全关键嵌入式系统需要更严格的 Harness 约束体系**。相比 Web 应用，嵌入式系统的性能红线不可谈判、线程优先级不可动态协商、验证环境受限——这些特殊性要求 Harness 在 L6 约束恢复层进行专项强化，包括行号级禁止修改清单、不可绕过的自检触发器和务实的验证策略。

3. **棕地项目 Harness 改造是可行的，且可量化验证**。通过渐进式路径（Phase 1-6），RobotController 在不中断现有功能的前提下，完成了从"无 Harness"到"HMM-L3 完整约束体系"再到"HMM-L4 量化管理级"的两阶段演进：HARNESS 注解落地 25 条覆盖 10 个核心保护函数，CI 性能红线检查集成 pre-commit hook，自动化治理健康报告每周运行。提供了业界罕见的棕地改造完整案例。

4. **量化治理效果显著**。约 30 天开发周期内：零性能红线违规、零架构铁律违反、零模块间不当直接调用，EventChannel 重构代码量减少 58%、旧 API 全量清零，规则冲突频率下降 83%。

5. **Harness 成熟度模型提供了可量化的治理评估框架**。HMM 五级模型将 Harness 从"有/无"的二元判断升级为可渐进改进的成熟度评估体系。RobotController 当前处于 HMM-L3（定义级），向 HMM-L4（量化级）过渡的路径清晰可行。

**展望**：随着模型能力的持续提升，Harness 的某些保护层可能会变得冗余（如 Anthropic 移除 Sprint 机制）。Harness 不是一次性的工程投入，而是需要随模型能力演进而持续调整的动态系统。HMM 模型和 AHE 的自动化演化思路共同指向一个方向：Harness Engineering 作为独立工程学科，其核心价值不在于一套固定不变的规则，而在于提供可持续演进的治理框架。

---

## 参考文献

[1] OpenAI Engineering Blog, "Codex: Three Engineers, Five Months, One Million Lines of Zero-Handwritten Code," 2026.

[2] Stripe Engineering, "Minions: Unattended PR Generation at Scale — 1,000+ PRs Per Week," 2026.

[3] Anthropic Labs, "A GAN-Inspired Three-Agent Architecture for Long-Running Coding Tasks," 2026.

[4] JavaGuide, "一文搞懂 Harness Engineering：六层架构、上下文管理与一线团队实战," https://javaguide.cn/ai/agent/harness-engineering.html, 2026.

[5] Harness Engineering Community, *Harness Engineering Knowledge Graph*, https://harness-engineering.ai/, 2026.

[6] Mitchell Hashimoto, "Ghostty Terminal: Six-Step AI Agent Engineering Methodology," Personal Blog, 2026.

[7] Birgitta Böckeler, "Bliki: Harness Engineering," Martin Fowler Blog, 2026.

[8] Vivek Trivedy (LangChain), "The Anatomy of an Agent Harness," LangChain Blog, 2026.

[9] Y Build Team, "Harness 工程：围绕 AI Agent 构建系统," https://ybuild.ai/zh/blog/harness-engineering-complete-guide-ai-coding-agents-2026, 2026.

[10] Nicholas Carlini, "Building a C Compiler with 16 Parallel AI Agents," Personal Blog, 2026.

[11] RobotController Project, *AI.md v2.x — AI 强制规则加载协议*, Internal Documentation, 2026.

[12] RobotController Project, *ADR-001: Gradle 模块化拆分 (Phases 1-3)*, Internal Architecture Decision Record, 2026.

[13] RobotController Project, *ADR-002: StateCenter → EventChannel 事件通道重构 (v1.3)*, Internal Architecture Decision Record, 2026.

[14] RobotController Project, *AI 命令模板指南 v1.0*, Internal Documentation, 2026.

**新增学术引用**：

[R1] Jiahang Lin, Shichun Liu, Chengjun Pan, et al., "Agentic Harness Engineering: Observability-Driven Automatic Evolution of Coding-Agent Harnesses," arXiv:2604.25850v4, 2026. 10轮 AHE 迭代将 Terminal-Bench 2 pass@1 从 69.7% 提升至 77.0%；冻结 Harness 跨模型迁移增益 +5.1~+10.1pp.

[R2] Xuying Ning, Katherine Tieu, Dongqi Fu, et al., "Code as Agent Harness: Toward Executable, Verifiable, and Stateful Agent Systems," arXiv:2605.18747, 2026. 102 页系统性综述，定义三层架构（Interface → Mechanisms → Scaling），覆盖五大应用域，指出六大开放挑战。

[R3] Francisco J. Cazorla et al., "SAFEXPLAIN: Safe and Explainable Critical Embedded Systems Based on AI," EU Horizon Europe, Grant No. 101069595, 2023-2026. 面向 AI 集成安全关键系统的可解释性方案，目标满足 ISO 26262 / ISO PAS 8800.

[R4] "Artificial Intelligence for Safety-Critical Systems in Industrial and Transportation Domains," ACM Computing Surveys, 2024.

[R5] "Functional Safety Architectural Patterns for AI-Based Critical Systems," ACM, 2025. DOI: 10.1145/3769121. 对齐 ISO/IEC TR 5469 的模块化参考架构。

[R6] Mark Chen et al., "Evaluating Large Language Models Trained on Code," (HumanEval), OpenAI, arXiv:2107.03374, 2021.

[R7] Carlos E. Jimenez et al., "SWE-bench: Can Language Models Resolve Real-World GitHub Issues?" ICLR 2024.

[R8] Naman Jain et al., "LiveCodeBench: Holistic and Contamination Free Evaluation of Large Language Models for Code," 2024.

[R9] Yuntao Bai et al., "Constitutional AI: Harmlessness from AI Feedback," Anthropic, arXiv:2212.08073, 2024.

[R10] GitHub, "spec-kit: Spec-Driven Development," https://github.com/github/spec-kit, 2026.

---

## 附录 A：Harness 规则文件清单

| 文件 | 行数 | 核心内容 |
|------|------|---------|
| `00-最高原则.md` | 118 | 性能红线（TCP < 500ms / Video < 600ms）+ AI 自检触发器 |
| `01-项目总览与全局约束.md` | 268 | StateCenter 单向数据流、Activity 拆分原则、模块职责边界 |
| `02-视频模块规范.md` | 190 | libVLC 保护、network-caching=0ms、录制分流约束 |
| `03-通信与心跳规范.md` | 157 | WakeLock 管理、recvLoop 保护、MAVLink 编解码约束 |
| `04-StateCenter与UI规范.md` | 140 | EventChannel 订阅生命周期、ViewBinding、Fragment 复用规则 |
| `05-关键约束值速查.md` | 105 | 所有关键数值（延迟/超时/缓存）的速查表 |
| `06-关键功能保护规范.md` | 286 | 行号级禁止修改清单 + 线程优先级表 + 全局单例保护 |
| `07-日志模块规范.md` | 129 | 静态缓存模板、刷新/清空兜底、异步落盘规范 |
| `08-上线发布规范.md` | 114 | 上线打包检查清单、版本号规则、release note 模板 |
| `09-规则冲突裁决机制.md` | 152 | 6 级优先级链 + 冲突裁决报告模板 + 同级冲突提权 |
| `10-上下文长效提醒机制.md` | 174 | 4 级提醒系统 + 70 字规则指纹 + 阶段健康检查 |
| `AI行为约束.md` | 194 | AI 代码生成通用约束 + 规则加载流程 + 质量要求 |
| `规则检查强制模板.md` | 86 | 自检清单标准输出格式 + 规则检查结果模板 |
| **合计（13 文件）** | **2113** | **覆盖 Harness 六层架构全部约束维度** |

---

## 附录 B：EventChannel 重构关键数据（ADR-002 v1.3）

| Phase | 迁移内容 | 文件数 | 验证结果 |
|-------|---------|--------|---------|
| Phase 1 | StateCenter 内部：13 CopyOnWriteArrayList → 13 EventChannel | 1 | javac 20 文件 0 错误 |
| Phase 2-1 | udpPacketChannel 迁移 | 3 | 0 错误 |
| Phase 2-2 | alarmStateChannel 迁移 | 2 | 0 错误 |
| Phase 2-3 | wifiStateChannel + heartbeatChannel 迁移 | 4 | 0 错误 |
| Phase 2-4 | videoStateChannel + videoDebugChannel 迁移 | 5 | 0 错误 |
| Phase 2-5 | robotStatusChannel 迁移 | 2 | 0 错误 |
| Phase 3-1 | 剩余 6 通道迁移 | 9 | 0 错误 |
| Phase 3-2 | StateCenter 兼容层清理 | 1 | 508→215 行（-58%） |
| Phase 3-3 | 测试迁移 | 1 | 21 测试用例全通过 |
| **合计** | **全量迁移** | **14** | **旧 API 引用归零** |

---

## 附录 C：规则冲突频率量化表（2026-05-25 至 2026-06-25）

| 冲突类型 | 发生次数 | 占比 | 趋势（第1周→第4周）| 裁决方式 | 后续规则补充 |
|---------|---------|------|-------------------|---------|------------|
| 性能红线 vs 代码简洁性 | 3 | 30% | 3→0 | 优先级链自动裁决（红线胜出） | 在 06-关键功能保护规范 中补充"禁止在 recvLoop 中引入 lambda 表达式（GC 压力）" |
| 架构铁律 vs 向后兼容 | 5 | 50% | 4→1 | 2 次优先级链裁决 + 3 次讨论后确认 | 在 AI行为约束 中补充"新增 API 优先经过 StateCenter，直接跨模块调用需附加论证" |
| 模块规范 vs 全局约束 | 2 | 20% | 2→0 | 全局约束胜出（LogManager 落盘时机让步于通信线程优先级） | 在 03-通信与心跳规范 中明确"日志落盘不得在 tcp-recv 线程中执行" |
| 同级冲突（正确性 vs 正确性）| 0 | 0% | — | — | 验证了分层设计的合理性，无需补充 |
| **合计** | **10** | **100%** | **-83%（6→1/周）** | — | **共补充 3 条新规则** |

---

*本文档版本：v2.1（修订版，新增 HMM-L4 升级数据：HARNESS 注解落地 + CI 集成 + 治理手册）*  
*生成日期：2026-06-25*  
*字数：约 10200 字*
