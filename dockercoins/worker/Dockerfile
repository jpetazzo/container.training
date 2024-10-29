FROM python:alpine
RUN pip install redis pyyaml requests
COPY worker.py /
CMD ["python", "worker.py"]
