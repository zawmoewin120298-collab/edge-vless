#!/bin/bash

# ၁။ V2Ray Core ကို Background မှာ Run ပါ
echo "Starting V2Ray Core..."
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Cloudflare Tunnel ကို Foreground မှာ ဒိုင်ခံ မောင်းပါ
if [ -z "$TUNNEL_TOKEN" ]; then
    echo "⚠️ Warning: TUNNEL_TOKEN is empty! Cloudflared cannot connect."
    wait
else
    echo "Starting Cloudflare Tunnel..."
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
fi
