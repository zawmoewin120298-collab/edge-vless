FROM debian:stable-slim

# 1. Core utilities များနှင့် Nginx ကိုပါ တစ်ခါတည်း Install လုပ်ပါ
# (Debian apt-get တွင် --no-cache မရှိပါ၊ ၎င်းအစား clean နှင့် rm ကို သုံးရပါသည်)
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    ca-certificates \
    bash \
    nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. V2Ray Core ကို Download ဆွဲပြီး အတည်ပြုထည့်သွင်းပါ
RUN wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip && \
    unzip v2ray-linux-64.zip -d /usr/bin/ && \
    chmod +x /usr/bin/v2ray && \
    rm v2ray-linux-64.zip

# 3. Cloudflared (Cloudflare Tunnel) ကို ဒေါင်းလုဒ်လုပ်ပြီး သွင်းပါ
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 4. လိုအပ်သော လမ်းကြောင်းများနှင့် Configurations များ ထည့်သွင်းပါ
RUN mkdir -p /etc/v2ray /etc/nginx

COPY config.json /etc/v2ray/config.json
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Nginx ရဲ့ ပင်မ Public Port ဖြစ်တဲ့ Port 80 ကို အပြင်ထုတ်ပေးပါ
EXPOSE 80

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

