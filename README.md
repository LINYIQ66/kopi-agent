<p align="center">
  <img src="assets/banner.png" alt="KOPI O Agent" width="100%">
</p>

# KOPI O Agent ☤

<p align="center">
  <a href="https://kopi.happysocial.xyz/docs/"><img src="https://img.shields.io/badge/Docs-kopi.happysocial.xyz-FFD700?style=for-the-badge" alt="Documentation"></a>
  <a href="https://github.com/xingbaoku/kopi-agent/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
  <a href="https://happysocial.xyz"><img src="https://img.shields.io/badge/Built%20by-Xing%20Bao%20Ku%20PTE%20LTD-blueviolet?style=for-the-badge" alt="Built by Xing Bao Ku PTE LTD"></a>
</p>

**KOPI O Agent** — 由 [Xing Bao Ku PTE LTD](https://happysocial.xyz) 打造的自进化 AI 智能体。

基于开源 Hermes Agent 深度定制，专为中文用户和企业场景优化。一键安装，傻瓜式部署，开箱即用。

## ✨ 核心特性

- 🚀 **一键安装** — `curl -fsSL https://kopi.happysocial.xyz/install.sh | bash`，全程自动化
- 🔑 **API Key 自动开通** — 安装时自动获取，用户无需手动配置
- 📱 **消息平台就绪** — Telegram / WeChat Gateway 最后一步交互配置
- 🧠 **65 个预装技能** — 涵盖开发、运维、研究、创意等场景
- 💬 **中文优先** — 默认中文交互，支持中英双语
- 🔄 **自进化学习** — 从经验中学习，自动创建和改进技能
- ⏰ **定时任务** — 内置 Cron 调度，支持多平台投递
- 🤖 **多代理协作** — 子代理并行执行，任务委派

## 🚀 快速安装

### 一键安装（推荐）

```bash
curl -fsSL https://kopi.happysocial.xyz/install.sh | bash
```

安装过程全自动：
1. ✅ 系统环境检测 & 依赖安装
2. ✅ KOPI O Agent 安装
3. ✅ 自动开通 API 账号 & 获取密钥
4. ✅ 预装 65 个实用技能
5. ✅ 交互式配置 Telegram / WeChat Gateway

### 手动指定 API Key

```bash
curl -fsSL https://kopi.happysocial.xyz/install.sh | KOPI_API_KEY=kp-xxx bash
```

## 📖 使用指南

### CLI 命令

```bash
kopi              # 交互式聊天
kopi model        # 选择大模型
kopi tools        # 配置工具
kopi config set   # 设置配置项
kopi gateway      # 启动消息网关
kopi setup        # 完整设置向导
kopi update       # 更新到最新版
kopi doctor       # 诊断问题
```

### 消息平台

安装完成后，通过 Telegram 或 WeChat 与 KOPI O Agent 对话：

```
/new              # 新对话
/model            # 切换模型
/skills           # 浏览技能
/cron             # 管理定时任务
/help             # 查看所有命令
```

## 🛠 预装技能（65 个）

### 核心工具 (15)
计划、调试、TDD、GitHub 工作流、笔记、邮件等

### 开发工具 (15)
Claude Code、Codex、代码审查、MCP 集成等

### 数据研究 (10)
arXiv、Polymarket、Jupyter、Google Workspace 等

### 部署运维 (10)
子域名部署、API 平台、Docker、双语网站等

### 创意内容 (10)
漫画、信息图、Excalidraw、PPT、音乐等

### 其他实用 (5)
自我改进、知识图谱、OPC 方法论等

## 🔧 配置

### 模型配置

```yaml
# ~/.kopi/config.yaml
model:
  default: kopi-o
  provider: custom
  base_url: https://proxy.happysocial.xyz/v1
  api_key_file: /etc/kopi-agent/credentials
```

### Gateway 配置

```yaml
# Telegram
gateway:
  telegram:
    bot_token: "YOUR_BOT_TOKEN"

# WeChat
gateway:
  weixin:
    bot_token: "YOUR_BOT_TOKEN"
    ilink_bot_id: "YOUR_BOT_ID"
```

## 📚 文档

- [快速入门](https://kopi.happysocial.xyz/docs/getting-started/quickstart)
- [CLI 指南](https://kopi.happysocial.xyz/docs/user-guide/cli)
- [配置参考](https://kopi.happysocial.xyz/docs/user-guide/configuration)
- [消息网关](https://kopi.happysocial.xyz/docs/user-guide/messaging)
- [技能系统](https://kopi.happysocial.xyz/docs/user-guide/features/skills)
- [定时任务](https://kopi.happysocial.xyz/docs/user-guide/features/cron)

## 🤝 社区

- 🐛 [问题反馈](https://github.com/xingbaoku/kopi-agent/issues)
- 📚 [技能中心](https://agentskills.io)

## 📄 许可证

MIT — 详见 [LICENSE](LICENSE)

---

**Built with ❤️ by [Xing Bao Ku PTE LTD](https://happysocial.xyz)**

*Based on [Hermes Agent](https://github.com/NousResearch/hermes-agent) by [Nous Research](https://nousresearch.com)*
