#!/bin/bash
# 测试IP白名单是否已添加

echo "=== 微信公众号IP白名单测试 ==="
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "服务器IP: $(curl -s ifconfig.me 2>/dev/null || echo '未知')"
echo ""

# 微信公众号配置
export WECHAT_APPID="wxe580edd4705e1f38"
export WECHAT_SECRET="657ee02c48c29f7674b83cb939259874"

# 测试API连接
echo "测试微信公众号API连接..."
response=$(curl -s "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=${WECHAT_APPID}&secret=${WECHAT_SECRET}")

# 解析响应
access_token=$(echo "$response" | jq -r '.access_token' 2>/dev/null || echo '')
errcode=$(echo "$response" | jq -r '.errcode' 2>/dev/null || echo '')
errmsg=$(echo "$response" | jq -r '.errmsg' 2>/dev/null || echo '')

echo "API响应: $response"
echo ""

if [ -n "$access_token" ] && [ "$access_token" != "null" ]; then
    echo "✅ IP白名单测试通过！"
    echo "access_token: ${access_token:0:20}..."
    echo "有效期: $(echo "$response" | jq -r '.expires_in') 秒"
    echo ""
    echo "🎉 恭喜！自动推送功能现在可以正常工作。"
    echo "明天的AI新闻将自动推送到微信公众号草稿箱。"
    exit 0
elif [ "$errcode" = "40164" ]; then
    echo "❌ IP白名单限制仍然存在"
    echo "错误码: $errcode"
    echo "错误信息: $errmsg"
    echo ""
    echo "🔧 需要操作:"
    echo "1. 登录微信公众号后台 (https://mp.weixin.qq.com)"
    echo "2. 进入 设置 → 安全中心 → IP白名单"
    echo "3. 添加服务器IP: 43.160.220.5"
    echo "4. 保存后等待5-10分钟生效"
    echo "5. 重新运行此测试"
    exit 1
else
    echo "⚠️ 其他错误或未知状态"
    echo "错误码: $errcode"
    echo "错误信息: $errmsg"
    echo ""
    echo "📋 可能原因:"
    echo "- AppID或AppSecret错误"
    echo "- 网络连接问题"
    echo "- 微信公众号API故障"
    exit 2
fi