FROM alpine
RUN apk update
RUN apk add entr
RUN apk add py-pip
RUN apk add git
COPY requirements.txt .
RUN pip install -r requirements.txt
