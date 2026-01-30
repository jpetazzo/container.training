FROM python:alpine
WORKDIR /app
RUN pip install Flask
COPY rng.py .
ENV FLASK_APP=rng FLASK_RUN_HOST=:: FLASK_RUN_PORT=80
CMD ["flask", "run", "--without-threads"]
EXPOSE 80
