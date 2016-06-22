FROM node:4-slim
RUN npm install express
RUN npm install redis
COPY files/ /files/
COPY webui.js /
CMD ["node", "webui.js"]
EXPOSE 80
