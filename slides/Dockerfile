FROM alpine:3.9
RUN apk add --no-cache entr py-pip git
COPY requirements.txt .
RUN pip install -r requirements.txt
