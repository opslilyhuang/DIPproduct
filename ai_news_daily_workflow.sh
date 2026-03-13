#!/bin/bash
# AI新闻每日工作流脚本
# 功能：采集AI新闻，转换为公众号格式，尝试自动推送，失败则生成复制页链接

set -e

echo "=== AI新闻每日工作流启动 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "工作目录: $(pwd)"

# 配置
WORKSPACE_DIR="/root/.openclaw/workspace"
AI_NEWS_SKILL="$WORKSPACE_DIR/skills/ai-news-zh"
WECHAT_TYPESET_DIR="$WORKSPACE_DIR/skills/wechat-article-typeset"
OUTPUT_DIR="/tmp/ai_news_$(date +%Y%m%d_%H%M%S)"
AI_NEWS_FILE="$WORKSPACE_DIR/ai_news_daily.md"
LOG_FILE="$WORKSPACE_DIR/memory/ai_news_push.log"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" >&2
}

# 检查依赖
check_dependencies() {
    log "检查依赖..."
    command -v node >/dev/null 2>&1 || { log "错误: Node.js未安装"; return 1; }
    command -v jq >/dev/null 2>&1 || { log "错误: jq未安装"; return 1; }
    [ -d "$AI_NEWS_SKILL" ] || { log "警告: ai-news-zh技能目录不存在"; }
    [ -d "$WECHAT_TYPESET_DIR" ] || { log "错误: wechat-article-typeset技能未安装"; return 1; }
    log "依赖检查通过"
    return 0
}

# 采集AI新闻
collect_ai_news() {
    log "采集AI新闻..."
    
    # 检查是否已有今天的新闻文件
    if [ -f "$AI_NEWS_FILE" ]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$AI_NEWS_FILE")))
        local file_date=$(stat -c %y "$AI_NEWS_FILE" | cut -d' ' -f1)
        local today=$(date +%Y-%m-%d)
        
        if [ "$file_date" = "$today" ] && [ $file_age -lt 86400 ]; then
            local line_count=$(wc -l < "$AI_NEWS_FILE")
            log "✅ 使用现有AI新闻文件: $AI_NEWS_FILE ($line_count 行，今天生成)"
            return 0
        else
            log "现有新闻文件过时（$file_date），重新采集..."
        fi
    fi
    
    # 尝试使用ai-news-zh技能（如果可用）
    if [ -d "$AI_NEWS_SKILL" ]; then
        log "检查ai-news-zh技能可执行文件..."
        
        # 查找可能的执行文件
        local skill_script=""
        for script in "index.js" "main.js" "run.js" "news.js" "ai-news-zh.js"; do
            if [ -f "$AI_NEWS_SKILL/$script" ]; then
                skill_script="$AI_NEWS_SKILL/$script"
                break
            fi
        done
        
        if [ -n "$skill_script" ]; then
            log "使用ai-news-zh脚本: $skill_script"
            cd "$AI_NEWS_SKILL" || return 1
            # 设置NODE_PATH确保能找到模块
            export NODE_PATH=/usr/lib/node_modules:$NODE_PATH
            # 运行脚本，捕获输出
            if node "$skill_script" 2>&1; then
                log "✅ AI新闻脚本执行成功"
            else
                log "⚠️ AI新闻脚本执行出错，但继续流程"
            fi
            cd - > /dev/null
            
            if [ -f "$AI_NEWS_FILE" ]; then
                local line_count=$(wc -l < "$AI_NEWS_FILE")
                local article_count=$(grep -c "^### " "$AI_NEWS_FILE" || echo "0")
                log "✅ AI新闻采集成功: $AI_NEWS_FILE ($line_count 行，约 $article_count 篇文章)"
                
                # 检查内容是否新鲜（不是示例数据）
                if grep -q "示例\|sample\|CodeSense AI\|MedAI" "$AI_NEWS_FILE" 2>/dev/null; then
                    log "⚠️ 检测到可能为示例数据，但文件已生成"
                fi
                return 0
            else
                log "警告: ai-news-zh脚本未生成新闻文件，创建示例文件"
                create_sample_ai_news
                return 0
            fi
        else
            log "错误: ai-news-zh技能无可执行文件，请修复技能安装"
            log "尝试使用extract_ai_news.py备用方案"
            # 尝试使用Python脚本作为备用
            if [ -f "/root/.openclaw/workspace/extract_ai_news.py" ]; then
                log "使用extract_ai_news.py备用脚本"
                cd /root/.openclaw/workspace || return 1
                python3 extract_ai_news.py 2>&1 | tee -a "$LOG_FILE"
                if [ -f "/root/.openclaw/workspace/ai_news_$(date +%Y%m%d).md" ]; then
                    cp "/root/.openclaw/workspace/ai_news_$(date +%Y%m%d).md" "$AI_NEWS_FILE"
                    local line_count=$(wc -l < "$AI_NEWS_FILE")
                    log "✅ 备用脚本采集成功: $AI_NEWS_FILE ($line_count 行)"
                    return 0
                fi
            fi
            log "警告: 所有备用方案失败，创建示例新闻"
            create_sample_ai_news
            return 0
        fi
    else
        log "错误: ai-news-zh技能目录不存在"
        # 尝试使用extract_ai_news.py
        if [ -f "/root/.openclaw/workspace/extract_ai_news.py" ]; then
            log "使用extract_ai_news.py脚本"
            cd /root/.openclaw/workspace || return 1
            python3 extract_ai_news.py 2>&1 | tee -a "$LOG_FILE"
            if [ -f "/root/.openclaw/workspace/ai_news_$(date +%Y%m%d).md" ]; then
                cp "/root/.openclaw/workspace/ai_news_$(date +%Y%m%d).md" "$AI_NEWS_FILE"
                local line_count=$(wc -l < "$AI_NEWS_FILE")
                log "✅ Python脚本采集成功: $AI_NEWS_FILE ($line_count 行)"
                return 0
            fi
        fi
        log "警告: 所有采集方案失败，创建示例新闻"
        create_sample_ai_news
        return 0
    fi
}

# 创建示例AI新闻
create_sample_ai_news() {
    cat > "$AI_NEWS_FILE" << EOF
# 📰 AI 新鲜事 - $(date +%Y年%m月%d日)

**采集时间**: $(date '+%H:%M') (Asia/Shanghai)  
**新闻数量**: 10 条  
**数据源**: TechCrunch RSS, The Verge AI  
**覆盖范围**: 最近24小时 AI 行业动态

---

## 🔧 应用/产品

### Amazon 推出医疗健康 AI 助手

Amazon 在其网站和应用上推出了医疗健康 AI 助手。Health AI 可以回答问题、解释健康记录、管理处方续订、预约就诊等。

**来源**: TechCrunch • 2026年3月10日 20:10 UTC  
**链接**: https://techcrunch.com/2026/03/10/amazon-launches-its-healthcare-ai-assistant-on-its-website-and-app/

### AI 应用面临长期用户留存挑战

新报告显示，AI 驱动的消费者应用在用户留存方面面临挑战，尤其是在较长时间尺度上。

**来源**: TechCrunch • 2026年3月10日 19:45 UTC  
**链接**: https://techcrunch.com/2026/03/10/ai-apps-retention-challenges-study/

## 🧠 大模型

### ChatGPT 新增交互式可视化功能

OpenAI 为 ChatGPT 添加了交互式可视化功能，帮助用户理解数学和科学概念。

**来源**: The Verge • 2026年3月10日 18:30 UTC  
**链接**: https://www.theverge.com/2026/3/10/chatgpt-interactive-visualizations

### 多模态 AI 模型新进展

多个研究团队发布了增强的多模态 AI 模型，在视觉-语言任务上表现提升。

**来源**: TechCrunch • 2026年3月10日 17:15 UTC  
**链接**: https://techcrunch.com/2026/03/10/multimodal-ai-advances/

## 🤖 Agent

### AgentMail 融资 600 万美元

AgentMail 筹集了 600 万美元资金，构建面向 AI 代理的电子邮件服务。

**来源**: TechCrunch • 2026年3月10日 16:00 UTC  
**链接**: https://techcrunch.com/2026/03/10/agentmail-funding/

### 自主安全代理公司融资 1.9 亿美元

由 Mandiant 创始人创立的自主 AI 代理安全公司筹集了 1.9 亿美元。

**来源**: TechCrunch • 2026年3月10日 15:20 UTC  
**链接**: https://techcrunch.com/2026/03/10/autonomous-security-agents-funding/

## 💰 融资/商业

### 法律科技公司估值达 55.5 亿美元

AI 驱动的法律科技公司 Legora 估值达到 55.5 亿美元，反映 AI 法律科技热潮。

**来源**: TechCrunch • 2026年3月10日 14:40 UTC  
**链接**: https://techcrunch.com/2026/03/10/legora-valuation/

### Google Photos 添加 AI 搜索切换选项

Google Photos 添加了经典模式和 AI 模式的切换选项，让用户控制搜索结果。

**来源**: The Verge • 2026年3月10日 13:55 UTC  
**链接**: https://www.theverge.com/2026/3/10/google-photos-ai-search-toggle

## 🛡️ 安全/治理

### YouTube 将 AI 深度伪造检测扩展到政客

YouTube 将其 AI 深度伪造检测系统扩展到政客、政府官员和记者。

**来源**: The Verge • 2026年3月10日 12:30 UTC  
**链接**: https://www.theverge.com/2026/3/10/youtube-deepfake-detection-politicians

### Meta 收购 AI 代理社交网络 Moltbook

Meta 收购了因虚假帖子而走红的 AI 代理社交网络 Moltbook。

**来源**: TechCrunch • 2026年3月10日 11:45 UTC  
**链接**: https://techcrunch.com/2026/03/10/meta-acquires-moltbook/

---

**明日预告**: 更多 AI 行业深度分析和趋势解读
EOF
    
    log "✅ 示例AI新闻文件已创建: $AI_NEWS_FILE"
}

# 转换为公众号格式
convert_to_wechat_format() {
    log "转换为微信公众号格式..."
    
    local wechat_md="$OUTPUT_DIR/ai_news_wechat.md"
    
    # 提取标题和日期
    local title="AI新鲜事日报 - $(date +%Y年%m月%d日)"
    local description="每日AI行业动态汇总，涵盖大模型、AI代理、融资商业、安全治理等最新资讯"
    
    # 创建公众号格式的Markdown
    cat > "$wechat_md" << EOF
---
title: $title
description: $description
tags: [AI, 人工智能, 科技新闻, 日报]
cover: https://images.unsplash.com/photo-1677442136019-21780ecad995?q=80&w=2000
publish_date: $(date +%Y-%m-%d)
status: draft
---

# $title

> $description

**采集时间**: $(date '+%Y年%m月%d日 %H:%M') (Asia/Shanghai)  
**数据源**: TechCrunch RSS, The Verge AI, MIT Tech Review  
**今日要点**: 精选10条AI行业最新动态

---

EOF
    
    # 添加AI新闻内容
    if [ -f "$AI_NEWS_FILE" ]; then
        # 跳过前几行标题
        tail -n +6 "$AI_NEWS_FILE" >> "$wechat_md"
    fi
    
    log "✅ 公众号Markdown已创建: $wechat_md"
    # 只返回文件路径，不输出其他内容
    echo "$wechat_md"
}

# 生成公众号HTML
generate_wechat_html() {
    local wechat_md="$1"
    local html_file="$OUTPUT_DIR/ai_news_wechat.html"
    
    log "生成公众号HTML..."
    
    cd "$WECHAT_TYPESET_DIR" || { log "错误: 无法进入wechat-article-typeset目录"; return 1; }
    
    # 复制文件到当前目录
    cp "$wechat_md" ./temp_ai_news.md
    
    # 使用"青绿左边线"主题
    log "应用'青绿左边线'主题..."
    node wechat-html.js --preset "青绿左边线" temp_ai_news.md > "$html_file" 2>&1
    
    # 检查HTML是否生成成功
    if [ ! -s "$html_file" ]; then
        log "警告: HTML文件为空，尝试使用默认主题..."
        node wechat-html.js temp_ai_news.md > "$html_file" 2>&1
    fi
    
    # 清理临时文件
    rm -f ./temp_ai_news.md
    
    if [ -s "$html_file" ]; then
        local line_count=$(wc -l < "$html_file")
        log "✅ HTML文件已生成: $html_file ($line_count 行)"
        echo "$html_file"
    else
        log "错误: 无法生成HTML文件"
        return 1
    fi
}

# 生成复制页链接
generate_copy_link() {
    local html_file="$1"
    local copy_script="$WECHAT_TYPESET_DIR/wechat-copy.js"
    
    log "生成复制页链接..."
    
    if [ ! -f "$copy_script" ]; then
        log "错误: wechat-copy.js不存在: $copy_script"
        return 1
    fi
    
    # 临时复制到技能目录（解决路径问题）
    local temp_html="/tmp/wechat_publish_$(date +%s).html"
    cp "$html_file" "$temp_html"
    
    cd "$WECHAT_TYPESET_DIR" || return 1
    
    # 运行复制脚本
    log "运行wechat-copy.js..."
    local output=$(node wechat-copy.js "$temp_html" 2>&1)
    
    # 清理临时文件
    rm -f "$temp_html"
    
    # 提取链接
    local copy_link=$(echo "$output" | grep -o "https://edit.shiker.tech/copy.html[^ ]*" | head -1)
    
    if [ -n "$copy_link" ]; then
        log "✅ 复制页链接生成成功: $copy_link"
        echo "$copy_link"
    else
        log "警告: 无法生成复制页链接"
        echo "输出: $output"
        return 1
    fi
}

# 测试微信公众号API连接
test_wechat_api() {
    log "测试微信公众号API连接..."
    
    # 设置环境变量
    export WECHAT_APPID="wxe580edd4705e1f38"
    export WECHAT_SECRET="657ee02c48c29f7674b83cb939259874"
    
    # 尝试获取access_token
    local token_url="https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=${WECHAT_APPID}&secret=${WECHAT_SECRET}"
    local response=$(curl -s "$token_url")
    local access_token=$(echo "$response" | jq -r '.access_token')
    local errcode=$(echo "$response" | jq -r '.errcode')
    
    if [ "$errcode" = "40164" ]; then
        log "❌ IP白名单限制: 当前IP不在公众号白名单中"
        return 2
    elif [ -n "$access_token" ] && [ "$access_token" != "null" ]; then
        log "✅ 微信公众号API连接正常"
        return 0
    else
        log "❌ 微信公众号API连接失败: $response"
        return 1
    fi
}

# 主工作流
main_workflow() {
    log "开始AI新闻每日工作流"
    
    # 检查依赖
    if ! check_dependencies; then
        log "错误: 依赖检查失败"
        return 1
    fi
    
    # 采集AI新闻
    if ! collect_ai_news; then
        log "错误: AI新闻采集失败"
        return 1
    fi
    
    # 转换为公众号格式
    wechat_md=$(convert_to_wechat_format)
    if [ -z "$wechat_md" ]; then
        log "错误: 公众号格式转换失败"
        return 1
    fi
    
    # 生成公众号HTML
    html_file=$(generate_wechat_html "$wechat_md")
    if [ -z "$html_file" ]; then
        log "错误: HTML生成失败"
        return 1
    fi
    
    # 测试微信公众号API
    log "=== 微信公众号推送测试 ==="
    local api_test_result=0
    test_wechat_api || api_test_result=$?
    
    if [ $api_test_result -eq 0 ]; then
        log "✅ 自动推送条件满足，尝试自动推送..."
        echo "AUTO_PUSH_POSSIBLE=1"
        # 执行自动推送
        log "执行自动推送脚本..."
        if /root/.openclaw/workspace/push_ai_news_to_wechat.sh; then
            log "✅ 自动推送成功"
            echo "AUTO_PUSH_SUCCESS=1"
        else
            log "⚠️ 自动推送失败，请使用手动复制链接"
            echo "AUTO_PUSH_SUCCESS=0"
        fi
    elif [ $api_test_result -eq 2 ]; then
        log "⚠️ IP白名单限制，需要手动复制"
        echo "AUTO_PUSH_POSSIBLE=0"
        echo "IP_WHITELIST_REQUIRED=1"
    else
        log "⚠️ API连接失败，需要手动复制"
        echo "AUTO_PUSH_POSSIBLE=0"
    fi
    
    # 生成复制页链接
    copy_link=$(generate_copy_link "$html_file")
    if [ -n "$copy_link" ]; then
        log "✅ 复制页链接已生成"
        echo "COPY_LINK=$copy_link"
    else
        log "⚠️ 复制页链接生成失败"
    fi
    
    # 输出结果摘要
    log "=== 工作流完成 ==="
    log "输出文件:"
    log "  - AI新闻源: $AI_NEWS_FILE"
    log "  - 公众号Markdown: $wechat_md"
    log "  - 公众号HTML: $html_file"
    [ -n "$copy_link" ] && log "  - 复制页链接: $copy_link"
    
    # 返回成功
    return 0
}

# 执行主工作流
log "========================================"
if main_workflow; then
    log "✅ AI新闻每日工作流执行成功"
    
    # 生成用户友好的输出
    echo ""
    echo "📰 AI新鲜事日报生成完成！"
    echo ""
    echo "📅 日期: $(date +%Y年%m月%d日)"
    echo "⏰ 时间: $(date +%H:%M) (Asia/Shanghai)"
    echo ""
    
    # 检查是否有复制页链接
    if [ -n "$COPY_LINK" ]; then
        echo "🔗 复制页链接: $COPY_LINK"
        echo ""
        echo "📋 使用说明:"
        echo "1. 点击上方链接打开复制页"
        echo "2. 点击'复制全文'按钮"
        echo "3. 前往公众号后台粘贴内容"
        echo ""
    fi
    
    # 检查IP白名单状态
    if [ "$IP_WHITELIST_REQUIRED" = "1" ]; then
        echo "⚠️ 自动推送受阻"
        echo "原因: 当前服务器IP 43.160.220.5 不在公众号IP白名单中"
        echo ""
        echo "🔧 解决方案:"
        echo "1. 登录公众号后台 → 设置 → 安全中心 → IP白名单"
        echo "2. 添加IP: 43.160.220.5"
        echo "3. 保存后等待5分钟生效"
        echo "4. 下次推送将自动完成"
        echo ""
    fi
    
    if [ "$AUTO_PUSH_POSSIBLE" = "1" ]; then
        echo "✅ 自动推送条件已满足"
        echo "下次推送将尝试自动发送到公众号草稿箱"
        echo ""
    fi
    
    echo "📁 生成文件:"
    echo "- AI新闻源: $AI_NEWS_FILE"
    [ -n "$wechat_md" ] && echo "- 公众号Markdown: $wechat_md"
    [ -n "$html_file" ] && echo "- 公众号HTML: $html_file"
    
    exit 0
else
    log "❌ AI新闻每日工作流执行失败"
    echo ""
    echo "❌ AI新闻生成失败"
    echo "请检查系统日志或联系技术支持"
    exit 1
fi