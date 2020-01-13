FROM debian:jessie
MAINTAINER AJ Bowen <aj@soulshake.net>

RUN apt-get update && apt-get install -y \
    bsdmainutils \
    ca-certificates \
    curl \
    groff \
    jq \
    less \
    locales \
    man \
    pssh \
    python \
    python3 \
    python-docutils \
    python-pip \
    python3-pip \
    ssh \
    unzip \
    wkhtmltopdf \
    xvfb \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_GB.UTF-8

ENV LANG en_GB.UTF-8
ENV LC_ALL en_GB.UTF-8

ARG TERRAFORM_VERSION=0.11.13
RUN curl -s https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
 && mv terraform /usr/local/bin \
 && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip


RUN pip install -U \
    awscli \
    jinja2 \
    pdfkit \
    PyYAML \
    termcolor \
 && pip3 install -U \
    jinja2 \
    pdfkit \
    PyYAML

RUN mv $(which wkhtmltopdf) $(which wkhtmltopdf).real
COPY lib/wkhtmltopdf /usr/local/bin/wkhtmltopdf
