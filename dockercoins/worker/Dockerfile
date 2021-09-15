# Specify a base image
FROM python:alpine

# Make a virtualenv for pip
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Upgrade pip and install dependencies:
RUN /opt/venv/bin/python -m pip install --upgrade pip \
  && pip install redis requests

# Run the application
COPY worker.py /
CMD ["python", "worker.py"]