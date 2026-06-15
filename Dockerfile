FROM debian:stable-slim

# 1. Nginx ကို ဖြုတ်လိုက်ပါ (ပိုသွက်စေရန်)
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    ca-certificates \
    bash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Xray Core ကို သွင်းပါ
RUN wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/bin/ && \
    mv /usr/bin/xray /usr/bin/v2ray && \
    chmod +x /usr/bin/v2ray && \
    rm Xray-linux-64.zip

# 3. Cloudflared ကို သွင်းပါ
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 4. Config ဖိုင်များ
RUN mkdir -p /etc/v2ray
COPY config.json /etc/v2ray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Tunnel အတွက် Port လိုအပ်ချက်မရှိပါ (Tunnel က တိုက်ရိုက်ချိတ်မှာမို့လို့)
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
