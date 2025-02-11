FROM python:alpine
RUN pip install Flask
COPY rng.py /
STOPSIGNAL SIGINT
CMD ["python", "rng.py"]
EXPOSE 80
