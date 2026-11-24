FROM python:3.14-alpine
RUN apk add --no-cache entr git zip
COPY requirements.txt .
RUN pip install -r requirements.txt
# The Compose file will bind-mount the slides repository to /repo,
# and when running on Linux, the UID mismatch between the host and
# the container might cause git (invoked by markmaker) to barf.
# So we pre-emptively set this configuration value to reassure git.
RUN git config --global --add safe.directory /repo
