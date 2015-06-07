FROM python
RUN pip install redis
COPY worker.py /
CMD ["python", "worker.py"]
