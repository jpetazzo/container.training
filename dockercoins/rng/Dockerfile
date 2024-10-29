FROM python:alpine
RUN pip install Flask pyyaml prometheus-flask-exporter
COPY rng.py /
CMD ["python", "rng.py"]
