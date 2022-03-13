FROM ubuntu:latest

ARG USER=code

RUN useradd -rm -s /bin/bash -g root -G sudo -u 1000 ${USER}

RUN apt-get update \
    && apt-get install \
    supervisor apt-utils openssl openssh-server sudo -y

RUN PWD=`openssl rand -base64 14` && echo ${USER}:${PWD} | chpasswd

RUN mkdir -p /var/run/sshd /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 22

CMD ["/usr/bin/supervisord"]