FROM node:20-alpine

WORKDIR /app

COPY api/package*.json ./
RUN npm ci --omit=dev

COPY api/*.js ./
COPY index.html styles.css app.js ./public/

ENV DB_PATH=/data/todos.sqlite

EXPOSE 3000
VOLUME /data

CMD ["node", "server.js"]
