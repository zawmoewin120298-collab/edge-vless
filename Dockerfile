FROM alpine:latest

# Install network tools and bash
RUN apk add --no-cache wget unzip ca-certificates bash

# Download and install V2Ray Core
RUN wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip && \
    unzip v2ray-linux-64.zip -d /usr/bin/ && \
    chmod +x /usr/bin/v2ray && \
    rm v2ray-linux-64.zip

# Download and install Cloudflared (Tunnel)
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# Setup configurations and entrypoint
RUN mkdir -p /etc/v2ray
COPY config.json /etc/v2ray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
