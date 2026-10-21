FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev
COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["node", "gcp_relay_server.mjs"]
