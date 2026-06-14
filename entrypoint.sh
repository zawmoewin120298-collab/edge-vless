#!/bin/bash

# 1. V2Ray ကို Background မှာ အရင်စ Run ပါ
echo "Starting V2Ray Core..."
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# 2. V2Ray Server အလုပ်လုပ်ဖို့ ခဏ စောင့်ပါ
sleep 2

# 3. Cloudflare Tunnel ကို မောင်းပါ (ဒါက Foreground မှာ နေပါလိမ့်မယ်)
if [ -z "$TUNNEL_TOKEN" ]; then
    echo "⚠️ Warning: TUNNEL_TOKEN is empty! Cloudflared cannot connect."
    # Token မရှိရင်လည်း Container မသေအောင် V2Ray ကိုပဲ စောင့်ကြည့်ခိုင်းထားမည်
    wait
else
    echo "Starting Cloudflare Tunnel..."
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
fi
