FROM node:23-alpine
WORKDIR /app
RUN npm install express
RUN npm install morgan
RUN npm install redis@5
COPY . .
CMD ["node", "webui.js"]
EXPOSE 80
