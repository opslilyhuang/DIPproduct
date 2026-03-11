#!/bin/bash
# 公众号推送工作流脚本
# 将Obsidian文章推送到微信公众号草稿箱

set -e

echo "=== 公众号推送工作流开始 ==="

# 配置
OBSIDIAN_VAULT="/root/.openclaw/workspace/obsidian-vault"
ARTICLE_DIR="$OBSIDIAN_VAULT/公众号/草稿"
PUBLISHED_DIR="$OBSIDIAN_VAULT/公众号/已发布"
WECHAT_TYPESET_DIR="/root/.openclaw/workspace/skills/wechat-article-typeset"
MP_DRAFT_PUSH_DIR="/root/.openclaw/workspace/skills/mp-draft-push"

# 检查依赖
check_dependencies() {
    echo "检查依赖..."
    command -v node >/dev/null 2>&1 || { echo "错误: Node.js未安装"; exit 1; }
    command -v obsidian-cli >/dev/null 2>&1 || { echo "错误: obsidian-cli未安装"; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo "错误: jq未安装，请运行: apt install jq"; exit 1; }
    
    # 检查技能目录
    [ -d "$WECHAT_TYPESET_DIR" ] || { echo "错误: wechat-article-typeset技能未安装"; exit 1; }
    [ -d "$MP_DRAFT_PUSH_DIR" ] || { echo "错误: mp-draft-push技能未安装"; exit 1; }
    
    echo "依赖检查通过"
}

# 解析Obsidian文章frontmatter
parse_frontmatter() {
    local article_path="$1"
    echo "解析文章frontmatter: $article_path"
    
    # 简单的YAML frontmatter解析
    title=$(grep -E '^title:\s*' "$article_path" | sed 's/title:\s*//' | tr -d '\"'"'" | head -1)
    description=$(grep -E '^description:\s*' "$article_path" | sed 's/description:\s*//' | tr -d '\"'"'" | head -1)
    tags=$(grep -E '^tags:\s*' "$article_path" | sed 's/tags:\s*//' | tr -d '[]' | head -1)
    cover=$(grep -E '^cover:\s*' "$article_path" | sed 's/cover:\s*//' | tr -d '\"'"'" | head -1)
    
    # 设置默认值
    [ -z "$title" ] && title="文章标题"
    [ -z "$description" ] && description="文章摘要"
    
    echo "标题: $title"
    echo "摘要: $description"
    echo "标签: $tags"
    echo "封面图: ${cover:-未设置}"
}

# 转换Markdown为公众号HTML
convert_to_wechat_html() {
    local markdown_path="$1"
    local output_html_path="$2"
    
    echo "转换Markdown为公众号HTML..."
    
    cd "$WECHAT_TYPESET_DIR" || exit 1
    
    # 复制文章到当前目录（解决wechat-copy.js的路径问题）
    temp_markdown="/tmp/$(basename "$markdown_path")"
    cp "$markdown_path" "$temp_markdown"
    
    # 使用预设主题"墨色下划线"
    echo "正在生成复制页链接，可能需要网络连接..."
    node wechat-copy.js --preset "墨色下划线" "$(basename "$temp_markdown")" > /tmp/wechat_output.txt 2>&1
    
    # 从输出中提取复制页URL
    copy_url=$(grep -E '^https://edit\.shiker\.tech/copy\.html' /tmp/wechat_output.txt | head -1)
    
    if [ -n "$copy_url" ]; then
        echo "✅ 复制页URL: $copy_url"
        echo "请访问此链接复制到公众号后台"
        echo "$copy_url" > "$output_html_path.url"
    else
        echo "⚠️ 未获取到复制页URL（可能网络问题或API限制）"
        echo "使用本地HTML生成..."
    fi
    
    # 生成HTML文件（本地，无需网络）
    node wechat-html.js --preset "墨色下划线" "$(basename "$temp_markdown")" > "$output_html_path" 2>&1
    
    # 清理临时文件
    rm -f "$temp_markdown"
    
    echo "HTML文件已生成: $output_html_path"
    echo "（如需复制页链接，请确保网络连接正常）"
}

# 推送到微信公众号草稿箱
push_to_wechat_draft() {
    local title="$1"
    local description="$2"
    local html_content_path="$3"
    local cover_image_path="$4"
    
    echo "推送到微信公众号草稿箱..."
    
    # 检查API凭证
    if [ -z "$WECHAT_APPID" ] || [ -z "$WECHAT_SECRET" ]; then
        echo "警告: 微信公众号API凭证未设置"
        echo "请设置环境变量:"
        echo "  export WECHAT_APPID=你的AppID"
        echo "  export WECHAT_SECRET=你的AppSecret"
        echo "跳过推送步骤"
        return 1
    fi
    
    cd "$MP_DRAFT_PUSH_DIR" || exit 1
    
    # 读取HTML内容
    html_content=$(cat "$html_content_path" | tr -d '\n')
    
    # 调用推送脚本（这里需要根据技能实际接口调整）
    echo "标题: $title"
    echo "摘要: $description"
    echo "HTML内容长度: ${#html_content} 字符"
    echo "封面图: ${cover_image_path:-无}"
    
    echo "提示: 需要根据mp-draft-push技能的实际接口调用"
    echo "请参考: $MP_DRAFT_PUSH_DIR/SKILL.md"
    
    return 0
}

# 主函数
main() {
    check_dependencies
    
    # 如果没有指定文章，查找最新的草稿
    if [ $# -eq 0 ]; then
        article_path=$(find "$ARTICLE_DIR" -name "*.md" -type f | head -1)
        if [ -z "$article_path" ]; then
            echo "未找到文章，创建示例文章..."
            article_path="$ARTICLE_DIR/示例文章.md"
            cat > "$article_path" << EOF
---
title: 示例文章标题
description: 这是一个示例文章描述
tags: [示例, 测试]
cover: https://example.com/cover.jpg
publish_date: $(date +%Y-%m-%d)
status: draft
---

# 示例文章

欢迎阅读这篇示例文章。

## 第一部分

这里是文章内容...

- 要点1
- 要点2

## 第二部分

更多内容...

\`\`\`python
print("Hello, World!")
\`\`\`

**结束**
EOF
            echo "示例文章已创建: $article_path"
        fi
    else
        article_path="$1"
    fi
    
    echo "处理文章: $article_path"
    
    # 解析frontmatter
    parse_frontmatter "$article_path"
    
    # 创建临时文件
    temp_dir="/tmp/wechat_publish_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$temp_dir"
    
    html_path="$temp_dir/article.html"
    
    # 转换Markdown为HTML
    convert_to_wechat_html "$article_path" "$html_path"
    
    # 推送到公众号草稿箱
    push_to_wechat_draft "$title" "$description" "$html_path" "$cover"
    
    # 移动文章到已发布目录
    published_path="$PUBLISHED_DIR/$(basename "$article_path")"
    mv "$article_path" "$published_path"
    
    echo "=== 工作流完成 ==="
    echo "原始文章: $published_path"
    echo "HTML文件: $html_path"
    [ -f "$html_path.url" ] && echo "复制页URL: $(cat "$html_path.url")"
    echo ""
    echo "下一步:"
    echo "1. 访问复制页URL，复制到公众号后台"
    echo "2. 或配置微信公众号API凭证，实现自动推送"
    echo "3. 检查文章排版和内容"
}

# 执行主函数
main "$@"