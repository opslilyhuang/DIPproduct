#!/bin/bash
# 微信公众号API配置
export WECHAT_APPID="wxe580edd4705e1f38"
export WECHAT_SECRET="657ee02c48c29f7674b83cb939259874"
export WECHAT_AUTHOR="仙女小麻瓜"
export DEFAULT_COVER_URL="https://images.unsplash.com/photo-1677442136019-21780ecad995?q=80&w=2000"

# 检查必要的工具
check_dependencies() {
    echo "检查依赖..."
    command -v curl >/dev/null 2>&1 || { echo "错误: curl未安装"; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo "错误: jq未安装，请运行: apt install jq"; exit 1; }
    echo "依赖检查通过"
}

# 获取access_token
get_wechat_token() {
    echo "获取微信公众号access_token..."
    local token_url="https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=${WECHAT_APPID}&secret=${WECHAT_SECRET}"
    local token_response=$(curl -s "$token_url")
    local access_token=$(echo "$token_response" | jq -r '.access_token')
    local expires_in=$(echo "$token_response" | jq -r '.expires_in')
    
    if [ "$access_token" = "null" ] || [ -z "$access_token" ]; then
        echo "错误: 获取access_token失败"
        echo "响应: $token_response"
        exit 1
    fi
    
    echo "✅ access_token获取成功 (有效期: ${expires_in}秒)"
    echo "$access_token"
}

# 测试API连接
test_api_connection() {
    echo "=== 微信公众号API连接测试 ==="
    
    check_dependencies
    
    echo "1. 检查环境变量..."
    if [ -z "$WECHAT_APPID" ] || [ -z "$WECHAT_SECRET" ]; then
        echo "错误: WECHAT_APPID或WECHAT_SECRET未设置"
        exit 1
    fi
    echo "✅ 环境变量检查通过"
    
    echo "2. 获取access_token..."
    local token=$(get_wechat_token)
    if [ -n "$token" ]; then
        echo "✅ API连接测试成功！"
        echo "token: ${token:0:20}..."
        return 0
    else
        echo "❌ API连接测试失败"
        return 1
    fi
}

# 上传图片到微信素材库
upload_wechat_image() {
    local token="$1"
    local image_path="$2"
    local upload_url="https://api.weixin.qq.com/cgi-bin/media/uploadimg?access_token=${token}"
    
    echo "上传图片: $image_path"
    local response=$(curl -s -F "media=@${image_path}" "$upload_url")
    local media_id=$(echo "$response" | jq -r '.media_id')
    
    if [ "$media_id" = "null" ] || [ -z "$media_id" ]; then
        echo "警告: 图片上传失败"
        echo "响应: $response"
        echo ""
    else
        echo "✅ 图片上传成功，media_id: $media_id"
        echo "$response"
    fi
}

# 创建草稿
create_draft() {
    local token="$1"
    local draft_json="$2"
    local draft_url="https://api.weixin.qq.com/cgi-bin/draft/add?access_token=${token}"
    
    echo "创建草稿..."
    local response=$(curl -s -X POST -H "Content-Type: application/json" -d "@$draft_json" "$draft_url")
    local media_id=$(echo "$response" | jq -r '.media_id')
    
    if [ "$media_id" = "null" ] || [ -z "$media_id" ]; then
        echo "错误: 创建草稿失败"
        echo "响应: $response"
        echo ""
    else
        echo "✅ 草稿创建成功，media_id: $media_id"
        echo "$response"
    fi
}

# 推送到公众号草稿箱
push_to_wechat_draft() {
    local title="$1"
    local digest="$2"
    local content_html="$3"
    local cover_image_path="$4"
    
    echo "=== 推送到微信公众号草稿箱 ==="
    
    check_dependencies
    
    # 获取access_token
    local token=$(get_wechat_token)
    if [ -z "$token" ]; then
        return 1
    fi
    
    # 处理封面图
    local thumb_media_id=""
    if [ -n "$cover_image_path" ] && [ -f "$cover_image_path" ]; then
        local upload_response=$(upload_wechat_image "$token" "$cover_image_path")
        thumb_media_id=$(echo "$upload_response" | jq -r '.media_id')
    elif [ -n "$DEFAULT_COVER_URL" ]; then
        echo "下载默认封面图..."
        local temp_cover="/tmp/wechat_cover_default_$(date +%s).jpg"
        curl -s -o "$temp_cover" "$DEFAULT_COVER_URL"
        if [ -f "$temp_cover" ]; then
            local upload_response=$(upload_wechat_image "$token" "$temp_cover")
            thumb_media_id=$(echo "$upload_response" | jq -r '.media_id')
            rm -f "$temp_cover"
        fi
    fi
    
    # 创建草稿JSON
    local draft_json="/tmp/draft_$(date +%Y%m%d%H%M%S).json"
    jq -n \
        --arg title "$title" \
        --arg author "${WECHAT_AUTHOR:-仙女小麻瓜}" \
        --arg digest "$digest" \
        --arg content "$content_html" \
        --arg thumb_media_id "$thumb_media_id" \
        '{
            articles: [{
                title: $title,
                author: $author,
                digest: $digest,
                content: $content,
                thumb_media_id: $thumb_media_id,
                need_open_comment: 1,
                only_fans_can_comment: 0
            }]
        }' > "$draft_json"
    
    echo "草稿JSON已创建: $draft_json"
    echo "标题: $title"
    echo "摘要: $digest"
    echo "内容长度: ${#content_html} 字符"
    echo "封面media_id: ${thumb_media_id:-无}"
    
    # 创建草稿
    local draft_response=$(create_draft "$token" "$draft_json")
    local draft_media_id=$(echo "$draft_response" | jq -r '.media_id')
    
    # 清理临时文件
    rm -f "$draft_json"
    
    if [ -n "$draft_media_id" ] && [ "$draft_media_id" != "null" ]; then
        echo ""
        echo "✅ 草稿发布成功！"
        echo ""
        echo "📝 文章信息"
        echo "- 标题: $title"
        echo "- 摘要: $digest"
        echo "- 草稿 ID: $draft_media_id"
        echo ""
        echo "📌 请前往微信公众号后台检查并发布："
        echo "   https://mp.weixin.qq.com"
        echo ""
        echo "⚠️ 检查要点："
        echo "1. 图片是否正常显示"
        echo "2. 排版是否正确"
        echo "3. 标题和摘要是否合适"
        echo "4. 确认无误后点击'发布'"
        return 0
    else
        echo "❌ 草稿创建失败"
        echo "响应: $draft_response"
        return 1
    fi
}

# 主函数
main() {
    if [ "$1" = "test" ]; then
        test_api_connection
    elif [ "$1" = "push" ]; then
        if [ $# -lt 4 ]; then
            echo "使用方法: $0 push '标题' '摘要' 'HTML内容' [封面图路径]"
            exit 1
        fi
        push_to_wechat_draft "$2" "$3" "$4" "$5"
    else
        echo "微信公众号API配置脚本"
        echo ""
        echo "使用方法:"
        echo "  $0 test                  # 测试API连接"
        echo "  $0 push 标题 摘要 HTML [封面图] # 推送到草稿箱"
        echo ""
        echo "环境变量:"
        echo "  WECHAT_APPID: $WECHAT_APPID"
        echo "  WECHAT_SECRET: ${WECHAT_SECRET:0:10}..."
        echo "  WECHAT_AUTHOR: $WECHAT_AUTHOR"
        echo "  DEFAULT_COVER_URL: $DEFAULT_COVER_URL"
    fi
}

# 执行主函数
main "$@"