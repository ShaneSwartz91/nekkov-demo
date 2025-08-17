FROM node:18-bullseye AS frontend
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci || npm i
COPY frontend/ .
RUN npm run build
FROM caddy:2.7.6-alpine
WORKDIR /srv/app
RUN apk add --no-cache python3 py3-pip
COPY backend/requirements.txt ./backend/requirements.txt
RUN pip3 install --no-cache-dir -r backend/requirements.txt
COPY backend/ ./backend/
COPY --from=frontend /app/frontend/dist ./frontend/dist
COPY Caddyfile /etc/caddy/Caddyfile
ENV PORT=8080
EXPOSE 8080
CMD sh -c "python3 -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 & exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile"
