# 学习记录

## 格式
- **ID**: 唯一标识符
- **时间戳**: 学习发生的时间
- **优先级**: 高/中/低
- **摘要**: 简要描述学到了什么
- **复现步骤**: 如何重现学习场景
- **建议修复**: 如何应用这个学习

## 记录

### 2026-03-07：开始配置核心Skills
- **ID**: SIA-001
- **时间戳**: 2026-03-07 19:30
- **优先级**: 高
- **摘要**: 根据"OpenClaw避坑指南"文章，开始安装和配置10个核心Skills
- **复现步骤**: 
  1. 从微信文章获取10个Skills清单
  2. 使用skillhub安装Clawsec、Multi Search Engine等
  3. 创建.learnings/目录和日志文件
  4. 配置Proactive Agent和Self-Improving Agent
- **建议修复**: 定期检查.learnings/目录，确保学习记录被正确保存和使用

### 2026-03-07：技能安装经验
- **ID**: SIA-002
- **时间戳**: 2026-03-07 19:35
- **优先级**: 中
- **摘要**: 发现skillhub中某些Skills可能名称不同或不存在
- **复现步骤**:
  1. 尝试安装Ontology - 404错误
  2. 尝试安装Office-Automation - 404错误
  3. 使用skillhub安装成功：Clawsec、Multi Search Engine、Self-Improving Agent、Proactive Agent
- **建议修复**: 对于skillhub中找不到的Skills，尝试其他安装方法（如npx clawhub@latest install）或寻找替代Skills
### 2026-03-07：技能测试验证
- **ID**: SIA-003
- **时间戳**: 2026-03-07 19:40
- **优先级**: 中
- **摘要**: 测试已安装Skills的功能性
- **复现步骤**:
  1. 测试skillhub search "weather" - 成功返回技能列表
  2. 测试web_fetch使用Multi Search Engine - 成功获取页面，但动态内容受限
  3. 检查Clawsec技能 - 仅文档，无可执行脚本
  4. 验证.learnings/目录可写 - 成功添加此记录
  5. 检查HEARTBEAT.md配置 - 已就绪，等待心跳触发
- **建议修复**: 
  1. 对于需要API密钥的Skills（如Tavily Search），需要配置环境变量
  2. 对于缺少可执行文件的Skills（如Clawsec），需要从GitHub下载脚本
  3. 考虑安装Node.js以使用clawhub安装缺失Skills

### 2026-03-08：SSH暴力攻击防护
- **ID**: SIA-004
- **时间戳**: 2026-03-08 08:21
- **优先级**: 高
- **摘要**: 检测到SSH暴力攻击并成功使用fail2ban进行防护
- **复现步骤**:
  1. 夜间心跳检查发现SSH暴力攻击（IP 134.199.146.117等）
  2. 攻击持续数小时，尝试多种用户名（root、huawei、oracle等）
  3. 安装并配置fail2ban服务
  4. fail2ban成功屏蔽攻击IP，累计屏蔽50个IP
  5. 无成功登录记录，系统负载正常
- **建议修复**:
  1. 考虑启用SSH密钥认证，禁用密码认证
  2. 修改SSH默认端口
  3. 配置防火墙进一步限制访问
  4. 定期审查fail2ban日志和配置
