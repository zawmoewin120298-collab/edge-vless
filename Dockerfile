# syntax=docker/dockerfile:1
FROM node:20-alpine
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

# လက်ရှိ root ထဲက ဖိုင်အားလုံးကို ကူးထည့်ခြင်း
COPY . .

# လိုအပ်သော config ဖိုင်များကို သက်ဆိုင်ရာ နေရာများသို့ သေချာရွှေ့ပေးခြင်း
RUN mkdir -p /etc/v2ray && \
    cp config.json /etc/v2ray/config.json && \
    cp entrypoint.sh /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 8080 3000
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
