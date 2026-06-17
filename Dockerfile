# syntax=docker/dockerfile:1
FROM node:24-alpine
WORKDIR /app

# လိုအပ်သော Tools (Xray + Cloudflared) များ သွင်းခြင်း
RUN apk add --no-cache wget unzip bash ca-certificates && \
    wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/bin/ && \
    mv /usr/bin/xray /usr/bin/v2ray && \
    chmod +x /usr/bin/v2ray && \
    rm Xray-linux-64.zip && \
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# လက်ရှိ root ထဲက ဖိုင်များကို သိမ်းဆည်းရန်နေရာ
COPY . .

# Node.js အတွက် အခြေခံ package ရှိရင် run ရန် (မရှိရင်လည်း ကျော်သွားမည်)
RUN if [ -f package.json ]; then npm ci --only=production; fi

# Config နှင့် Entrypoint သတ်မှတ်ချက်များ
COPY config.json /etc/v2ray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p cache

EXPOSE 3000
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
