FROM python:alpine
RUN apk add --no-cache --virtual curl
RUN pip install Flask
COPY rng.py /
CMD ["python", "rng.py"]
EXPOSE 80
