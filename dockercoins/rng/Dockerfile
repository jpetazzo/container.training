FROM python:alpine
RUN apk add --no-cache --virtual curl
RUN pip install Flask
COPY rng.py /
HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
CMD ["python", "rng.py"]
EXPOSE 80
