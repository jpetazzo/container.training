# Specify a base image
FROM node:slim

# Change to another directory to run npm
WORKDIR /usr/app

# Update npm 
RUN npm -g install npm

#Install some dependencies
RUN npm install express redis

# Run the application
COPY files/ /files/
COPY webui.js /
CMD ["node", "webui.js"]