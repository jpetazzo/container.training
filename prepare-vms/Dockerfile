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
    unzip \
    wkhtmltopdf \
    xvfb \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

ARG TERRAFORM_VERSION=0.11.13
RUN curl -s https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && mv terraform /usr/local/bin \
 && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip


RUN pip install \
    awscli \
    jinja2 \
    pdfkit \
    PyYAML \
    termcolor

RUN mv $(which wkhtmltopdf) $(which wkhtmltopdf).real
COPY lib/wkhtmltopdf /usr/local/bin/wkhtmltopdf
