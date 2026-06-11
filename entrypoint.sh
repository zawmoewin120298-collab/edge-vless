#!/bin/bash

# Railway Dynamic Port ကို ဖတ်ခြင်း
if [ -z "$PORT" ]; then
  PORT=8080
fi

# config.json ထဲက inbound port ကို Railway port အတိုင်း auto လှည့်ပြောင်းပေးခြင်း
if [ -f /etc/v2ray/config.json ]; then
  sed -i "s/\"port\": [0-9]*/\"port\": $PORT/g" /etc/v2ray/config.json
fi

echo "🚀 V2Ray Core with CDN Network Handling Active on Port: $PORT"
/usr/bin/v2ray run -c /etc/v2ray/config.json &

# Cloudflare Tunnel မောင်းနှင်ခြင်း
if [ ! -z "$TUNNEL_TOKEN" ]; then
  echo "🛡️ Cloudflare Tunnel Connection Establishing..."
  /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
else
  echo "⚠️ Warning: TUNNEL_TOKEN variable is missing!"
  wait -n
fi
