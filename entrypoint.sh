#!/bin/bash

# ၁။ Xray (VPN) ကို နောက်ခံမှာ Run ပါ
/usr/bin/v2ray run -config /etc/v2ray/config.json &

# ၂။ Cloudflare Tunnel ကို UDP အကျပ်အတည်း ကျော်လွှားရန် TCP စနစ်သီးသန့်ဖြင့် Force Run ခြင်း
if [ ! -z "$TUNNEL_TOKEN" ]; then
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --protocol http2 --no-tls-verify --token "$TUNNEL_TOKEN" &
fi

# ၃။ Container ကို အမြဲတမ်း အသက်ရှင်နေအောင် ထိန်းထားပါ
echo "VPN Core and Cloudflare Tunnel forced on TCP HTTP/2."
tail -f /dev/null
