FROM python:alpine
RUN pip install redis
RUN pip install requests
COPY worker.py /
STOPSIGNAL SIGKILL
CMD ["python", "worker.py"]
