# Specify a base image
FROM python:slim

# Make a virtualenv to run pip as a non-root user
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Upgrade pip and install dependencies
RUN /opt/venv/bin/python -m pip install --upgrade pip \
  && pip install Flask

# Run the application
COPY rng.py /
CMD ["python", "rng.py"]