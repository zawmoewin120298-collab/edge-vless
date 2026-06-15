# syntax=docker/dockerfile:1

# -----------------------------------------------------------------------------
# Stage 1: Builder (Dashboard + Engine)
# -----------------------------------------------------------------------------
FROM node:24-alpine AS builder
WORKDIR /app

# Build Dashboard
COPY dashboard/package.json dashboard/package-lock.json* ./dashboard/
RUN cd dashboard && npm ci --legacy-peer-deps
COPY dashboard/ ./dashboard/
RUN cd dashboard && npm run build

# Build Engine
COPY engine/package.json engine/package-lock.json* ./engine/
RUN cd engine && npm ci
COPY engine/ ./engine/
RUN cd engine && npm run build

# -----------------------------------------------------------------------------
# Stage 2: Production Runner (Final Image)
# -----------------------------------------------------------------------------
FROM node:24-alpine
WORKDIR /app

# 1. လိုအပ်သော Tools (Xray + Cloudflared) များ သွင်းခြင်း
RUN apk add --no-cache wget unzip bash ca-certificates && \
    wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip Xray-linux-64.zip -d /usr/bin/ && \
    mv /usr/bin/xray /usr/bin/v2ray && \
    chmod +x /usr/bin/v2ray && \
    rm Xray-linux-64.zip && \
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 2. Files များ Copy ကူးခြင်း
COPY --from=builder /app/engine/dist ./dist
COPY --from=builder /app/dashboard/out ./dashboard/out
COPY --from=builder /app/engine/package.json ./package.json
RUN npm ci --only=production

# 3. Config များ ထည့်သွင်းခြင်း
COPY config.json /etc/v2ray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && mkdir -p cache

# 4. စတင် Run မည့် Command
EXPOSE 3000
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

