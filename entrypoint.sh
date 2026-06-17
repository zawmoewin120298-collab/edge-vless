#!/bin/bash

# ၁။ Xray (VPN) ကို နောက်ခံမှာ Run ပါ
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Cloudflare Tunnel ကို TCP (http2) Protocol သုံးပြီး အတင်း Run ခိုင်းခြင်း
if [ ! -z "$TUNNEL_TOKEN" ]; then
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --protocol http2 --token "$TUNNEL_TOKEN" &
fi

# ၃။ Container ကို အမြဲတမ်း အသက်ရှင်နေအောင် ထိန်းထားပါ
echo "VPN Core and Cloudflare Tunnel started with HTTP/2 protocol."
tail -f /dev/null
