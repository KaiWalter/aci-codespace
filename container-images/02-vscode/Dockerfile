ARG BASEACR=dummy
FROM $BASEACR/01-base-ssh

ENV CODE_SERVER_VERSION 4.1.0

RUN apt-get install \
    ca-certificates sudo curl dumb-init \
    htop locales git procps ssh vim \
    lsb-release wget openssl -y \
    && wget https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_amd64.deb \
    && dpkg -i code-server_${CODE_SERVER_VERSION}_amd64.deb && rm -f code-server_${CODE_SERVER_VERSION}_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
