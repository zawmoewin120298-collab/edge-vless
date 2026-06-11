#!/bin/bash

# Railway ကပေးတဲ့ Port မရှိရင် Default 8080 သုံးခိုင်းခြင်း
if [ -z "$PORT" ]; then
  PORT=8080
fi

# config.json ထဲက Port နေရာကို Railway ရဲ့ Port အတိုင်း Auto လှည့်ပြင်ပေးခြင်း
if [ -f /etc/v2ray/config.json ]; then
  sed -i "s/\"port\": [0-9]*/\"port\": $PORT/g" /etc/v2ray/config.json
fi

echo "🚀 Starting V2Ray Core on Port: $PORT..."
# V2Ray Core ကို Background မှာ မောင်းနှင်ထားခြင်း
/usr/bin/v2ray run -c /etc/v2ray/config.json &

# Railway ရဲ့ Variables ထဲက TUNNEL_TOKEN ပါမပါ စစ်ဆေးခြင်း
if [ ! -z "$TUNNEL_TOKEN" ]; then
  echo "🛡️ Starting Cloudflare Tunnel using Railway Variable..."
  # Token ရှိရင် Tunnel ကို စနစ်တကျ တွဲမောင်းပေးခြင်း
  /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
else
  echo "💡 No TUNNEL_TOKEN provided, running V2Ray standalone."
  # Token မပါခဲ့ရင်လည်း Container ကြီး မပိတ်သွားအောင် ထိန်းထားခြင်း
  wait -n
fi

