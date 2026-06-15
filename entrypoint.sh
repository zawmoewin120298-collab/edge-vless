#!/bin/bash

# ၁။ Xray (VPN) ကို run ပါ
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Cloudflare Tunnel ကို run ပါ
if [ ! -z "$TUNNEL_TOKEN" ]; then
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &
fi

# ၃။ Engine (Web App) ကို run ပါ
node dist/index.js

