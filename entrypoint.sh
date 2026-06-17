#!/bin/bash

# ၁။ Xray (VPN) ကို နောက်ခံမှာ Run ပါ
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Cloudflare Tunnel ကို မူရင်းအတိုင်း ပြန်လည် Run ခြင်း
if [ ! -z "$TUNNEL_TOKEN" ]; then
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &
fi

# ၃။ Container ကို အမြဲတမ်း အသက်ရှင်နေအောင် ထိန်းထားပါ
echo "VPN Core and Cloudflare Tunnel started on default port 8080."
tail -f /dev/null
