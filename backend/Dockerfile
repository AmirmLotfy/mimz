FROM node:20-slim AS builder

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --production=false
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

FROM node:20-slim

WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json* ./
RUN npm ci --production && npm cache clean --force
COPY --from=builder /app/dist ./dist

EXPOSE 8080
USER node
CMD ["node", "dist/server.js"]
