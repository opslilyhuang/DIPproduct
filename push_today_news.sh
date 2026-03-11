#!/bin/bash
set -e

echo "=== 推送今天AI新闻到公众号草稿箱 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 配置
WORKSPACE="/root/.openclaw/workspace"
AI_NEWS_FILE="$WORKSPACE/ai_news_daily.md"
TYPESET_DIR="$WORKSPACE/skills/wechat-article-typeset"
MP_PUSH_DIR="$WORKSPACE/skills/mp-draft-push"
OUTPUT_DIR="/tmp/wechat_push_$(date +%s)"
TEMP_MD="$OUTPUT_DIR/news.md"
TEMP_HTML="$OUTPUT_DIR/news.html"
DRAFT_JSON="$OUTPUT_DIR/draft.json"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 环境变量
export WECHAT_APPID="wxe580edd4705e1f38"
export WECHAT_SECRET="657ee02c48c29f7674b83cb939259874"
export WECHAT_AUTHOR="仙女小麻瓜"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 检查文件
if [ ! -f "$AI_NEWS_FILE" ]; then
    log "错误: AI新闻文件不存在: $AI_NEWS_FILE"
    exit 1
fi

log "1. 准备公众号Markdown格式..."

# 提取标题和日期
TITLE="AI新鲜事日报 - 2026年3月11日"
DESCRIPTION="每日AI行业动态汇总，涵盖大模型、AI代理、融资商业、安全治理等最新资讯"

# 创建公众号格式的Markdown
cat > "$TEMP_MD" << MDEOF
---
title: $TITLE
description: $DESCRIPTION
tags: [AI, 人工智能, 科技新闻, 日报]
cover: https://images.unsplash.com/photo-1677442136019-21780ecad995?q=80&w=2000
publish_date: 2026-03-11
status: draft
---

# $TITLE

> $DESCRIPTION

**采集时间**: 2026年3月11日 08:00 (Asia/Shanghai)  
**数据源**: TechCrunch RSS, The Verge AI, MIT Tech Review  
**今日要点**: 精选10条AI行业最新动态

---

MDEOF

# 添加AI新闻内容（跳过前5行标题）
tail -n +6 "$AI_NEWS_FILE" >> "$TEMP_MD"

log "✅ Markdown文件已创建: $TEMP_MD"

log "2. 转换为公众号HTML格式..."
cd "$TYPESET_DIR" || exit 1

# 使用"青绿左边线"主题
node wechat-html.js --preset "青绿左边线" "$TEMP_MD" > "$TEMP_HTML" 2>&1

if [ ! -s "$TEMP_HTML" ]; then
    log "警告: HTML文件为空，尝试使用默认主题..."
    node wechat-html.js "$TEMP_MD" > "$TEMP_HTML" 2>&1
fi

if [ -s "$TEMP_HTML" ]; then
    LINE_COUNT=$(wc -l < "$TEMP_HTML")
    log "✅ HTML文件已生成: $TEMP_HTML ($LINE_COUNT 行)"
else
    log "错误: 无法生成HTML文件"
    exit 1
fi

log "3. 准备微信公众号API推送..."
cd "$MP_PUSH_DIR" || exit 1

# 加载脚本函数
source ./scripts.sh

# 获取access_token
log "获取access_token..."
TOKEN=$(get_wechat_token)
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    log "错误: 无法获取access_token"
    exit 1
fi
log "✅ access_token获取成功"

# 读取HTML内容
HTML_CONTENT=$(cat "$TEMP_HTML")
# 计算摘要（取前100字符）
DIGEST="每日AI行业动态汇总，涵盖大模型、AI代理、融资商业、安全治理等最新资讯。包含Amazon医疗健康AI助手、ChatGPT新功能、AI应用留存挑战等10条重要新闻。"

# 使用默认封面图
COVER_URL="https://images.unsplash.com/photo-1677442136019-21780ecad995?q=80&w=2000"
COVER_PATH="/tmp/default_cover.jpg"

# 下载封面图（如果需要）
if [ ! -f "$COVER_PATH" ]; then
    curl -s -o "$COVER_PATH" "$COVER_URL" || true
fi

# 上传封面图
if [ -f "$COVER_PATH" ]; then
    log "上传封面图..."
    UPLOAD_RESP=$(upload_wechat_image "$TOKEN" "$COVER_PATH")
    THUMB_ID=$(echo "$UPLOAD_RESP" | jq -r '.media_id')
    if [ -n "$THUMB_ID" ] && [ "$THUMB_ID" != "null" ]; then
        log "✅ 封面图上传成功，media_id: $THUMB_ID"
    else
        log "⚠️ 封面图上传失败，使用空值"
        THUMB_ID=""
    fi
else
    log "⚠️ 封面图文件不存在，使用空值"
    THUMB_ID=""
fi

log "4. 创建草稿..."
# 构建草稿JSON
jq -n \
  --arg title "$TITLE" \
  --arg author "$WECHAT_AUTHOR" \
  --arg digest "$DIGEST" \
  --arg content "$HTML_CONTENT" \
  --arg thumb_media_id "$THUMB_ID" \
  '{articles:[{title:$title,author:$author,digest:$digest,content:$content,thumb_media_id:$thumb_media_id,need_open_comment:1,only_fans_can_comment:0}]}' \
  > "$DRAFT_JSON"

log "草稿JSON已创建: $DRAFT_JSON"

# 创建草稿
DRAFT_RESP=$(create_draft "$TOKEN" "$DRAFT_JSON")
echo "$DRAFT_RESP"

# 检查响应
if echo "$DRAFT_RESP" | jq -e '.media_id' > /dev/null 2>&1; then
    MEDIA_ID=$(echo "$DRAFT_RESP" | jq -r '.media_id')
    log "✅ ✅ 草稿创建成功！"
    log "   草稿ID: $MEDIA_ID"
    log "   标题: $TITLE"
    log "   摘要: $DIGEST"
    log "   文章长度: ${#HTML_CONTENT} 字符"
    log "   封面图ID: $THUMB_ID"
    log ""
    log "🎉 推送完成！请登录公众号后台查看草稿箱"
else
    ERROR_CODE=$(echo "$DRAFT_RESP" | jq -r '.errcode')
    ERROR_MSG=$(echo "$DRAFT_RESP" | jq -r '.errmsg')
    log "❌ 草稿创建失败:"
    log "   错误代码: $ERROR_CODE"
    log "   错误信息: $ERROR_MSG"
    exit 1
fi

# 清理临时文件
# rm -rf "$OUTPUT_DIR"
log "临时文件保存在: $OUTPUT_DIR"
