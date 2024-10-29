FROM node:10-slim
RUN npm install express
RUN npm install redis@3
RUN npm install yamljs
RUN npm install prom-client
COPY files/ /files/
COPY webui.js /
CMD ["node", "webui.js"]
EXPOSE 80
