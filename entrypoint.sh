#!/bin/bash

# ၁။ V2Ray Core ကို Background မှာ အရင်စ Run ပါ
echo "Starting V2Ray Core..."
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Nginx Reverse Proxy (Keepalive) ကို Background မှာ Run ပါ
echo "Starting Nginx with Keepalive tuning..."
nginx &

# ၃။ ဆာဗာတွေ အလုပ်လုပ်ဖို့ ခဏ စောင့်ပါ
sleep 2

# ၄။ Cloudflare Tunnel ကို မောင်းပါ (ဒါက Foreground မှာ ဒိုင်ခံ နေပါလိမ့်မယ်)
if [ -z "$TUNNEL_TOKEN" ]; then
    echo "⚠️ Warning: TUNNEL_TOKEN is empty! Cloudflared cannot connect."
    # Token မရှိရင်လည်း Container မသေအောင် နောက်ကွယ်က process တွေကို စောင့်ကြည့်ခိုင်းထားမည်
    wait
else
    echo "Starting Cloudflare Tunnel..."
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
fi
