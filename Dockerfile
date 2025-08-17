# ---------- Build frontend ----------
FROM node:18-bullseye AS frontend
WORKDIR /app/frontend

# Copy only the manifest files first (better caching)
COPY frontend/package*.json ./

# If there is no package-lock.json, npm ci fails — so fall back to npm i
RUN npm ci || npm i

# Copy the rest of the frontend and build
COPY frontend/ .
# If your build needs dev deps (Vite), they are already installed above
RUN npm run build

# ---------- Final runtime (Caddy + Python) ----------
FROM caddy:2.7.6-alpine
WORKDIR /srv/app

# Install Python + pip
RUN apk add --no-cache python3 py3-pip

# Backend deps
COPY backend/requirements.txt ./backend/requirements.txt
RUN pip3 install --no-cache-dir -r backend/requirements.txt

# App code
COPY backend/ ./backend/

# Frontend build output from the previous stage
COPY --from=frontend /app/frontend/dist ./frontend/dist

# Caddy config
COPY Caddyfile /etc/caddy/Caddyfile

ENV PORT=8080
EXPOSE 8080

# Start Uvicorn (API) in background, Caddy in foreground (web)
CMD sh -c "python3 -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 & exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile"
