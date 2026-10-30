FROM python:3.14-alpine
RUN apk add --no-cache entr git zip
COPY requirements.txt .
RUN pip3 install -r requirements.txt
