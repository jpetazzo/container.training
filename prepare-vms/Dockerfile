FROM debian:jessie
MAINTAINER AJ Bowen <aj@soulshake.net>

RUN apt-get update && apt-get install -y \
    bsdmainutils \
    ca-certificates \
    curl \
    groff \
    jq \
    less \
    man \
    pssh \
    python \
    python-docutils \
    python-pip \
    ssh \
    wkhtmltopdf \
    xvfb \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN pip install \
    awscli \
    jinja2 \
    pdfkit \
    PyYAML \
    termcolor

RUN mv $(which wkhtmltopdf) $(which wkhtmltopdf).real
COPY lib/wkhtmltopdf /usr/local/bin/wkhtmltopdf
