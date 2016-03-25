FROM debian:jessie
MAINTAINER AJ Bowen <aj@soulshake.net>

RUN apt-get update
RUN apt-get install -y ca-certificates
RUN apt-get install -y groff
RUN apt-get install -y less
RUN apt-get install -y python python-pip
RUN apt-get install -y python-docutils
RUN apt-get install -y sudo
RUN apt-get install -y \
    bsdmainutils \
    curl \
    jq \
    less \
    man \
    pssh \
    ssh

RUN pip install awscli
RUN pip install \
    pdfkit \
    PyYAML \
    termcolor

RUN apt-get install -y wkhtmltopdf

ENV HOME /home/user

RUN useradd --create-home --home-dir $HOME user \
    && mkdir -p $HOME/.config/gandi \
    && chown -R user:user $HOME

RUN echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Replace 1000 with your user / group id
#RUN export uid=1000 gid=1000 && \
#    mkdir -p /home/user && \
#    mkdir -p /etc/sudoers.d && \
#    echo "user:x:${uid}:${gid}:user,,,:/home/user:/bin/bash" >> /etc/passwd && \
#    echo "user:x:${uid}:" >> /etc/group && \
#    echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user && \
#    chmod 0440 /etc/sudoers.d/user && \
#    chown ${uid}:${gid} -R /home/user

WORKDIR $HOME
RUN echo "alias ll='ls -lahF'" >> /home/user/.bashrc
RUN echo "export PATH=$PATH:/home/user/bin" >> /home/user/.bashrc
RUN mkdir -p /home/user/bin
RUN ln -s /home/user/prepare-vms/scripts/trainer-cli /home/user/bin/trainer-cli
USER user

