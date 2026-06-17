#!/bin/bash

# ၁။ Xray (VPN) ကို နောက်ခံ (Background) မှာ အရင်ဆုံး စတင်ပါ
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Cloudflare Tunnel ကို နောက်ခံ (Background) မှာ ချိတ်ဆက်ပါ
if [ ! -z "$TUNNEL_TOKEN" ]; then
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &
fi

# ၃။ Node.js (Web App) အပိုင်းကြောင့် လုံးဝ Crash မဖြစ်အောင် တိုက်ရိုက်ကာကွယ်ထားခြင်း
echo "VPN Core and Cloudflare Tunnel started."

# Container အမြဲတမ်း Active ဖြစ်ပြီး အသက်ရှင်နေအောင် ထိန်းထားပေးမယ့် အမိန့်
tail -f /dev/null
