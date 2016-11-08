FROM debian:jessie
MAINTAINER AJ Bowen <aj@soulshake.net>

RUN apt-get update && apt-get install -y \
    wkhtmltopdf \
    bsdmainutils \
    ca-certificates \
    curl \
    groff \
    jq \
    less \
    man \
    pssh \
    python \
    python-pip \
    python-docutils \
    ssh \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN pip install \
    awscli \
    pdfkit \
    PyYAML \
    termcolor

WORKDIR $$HOME
RUN echo "alias ll='ls -lahF'" >> /root/.bashrc
ENTRYPOINT ["/root/prepare-vms/scripts/trainer-cli"]

