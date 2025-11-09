FROM python:alpine
WORKDIR /app
RUN pip install redis
RUN pip install requests
COPY worker.py .
CMD ["python", "worker.py"]
