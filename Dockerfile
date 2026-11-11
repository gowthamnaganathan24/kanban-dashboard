
# Stage 1: Build the React/Vite application
FROM node:24-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

# Stage 2: Serve only production files
FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

# Temporarily use root to install security updates
USER root
RUN apk update && apk upgrade --no-cache

# Return to the non-root nginx user
USER 101

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s \
    --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1
