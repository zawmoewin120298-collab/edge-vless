FROM alpine:latest

# လိုအပ်သော network tools နှင့် bash တင်ခြင်း
RUN apk add --no-cache wget unzip ca-certificates bash

# V2Ray Core သွင်းခြင်း
RUN wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip && \
    unzip v2ray-linux-64.zip -d /usr/bin/ && \
    chmod +x /usr/bin/v2ray && \
    rm v2ray-linux-64.zip

# Cloudflared (Tunnel) သွင်းခြင်း
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# Folder ဆောက်ပြီး ဖိုင်များ နေရာချခြင်း
RUN mkdir -p /etc/v2ray
COPY config.json /etc/v2ray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

