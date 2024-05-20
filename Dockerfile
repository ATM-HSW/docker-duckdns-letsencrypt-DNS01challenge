FROM alpine:latest

ARG TARGETARCH

LABEL org.label-schema.docker.dockerfile=/Dockerfile org.label-schema.vcs-type=Git org.label-schema.vcs-url=https://github.com/ATM-HSW/docker-duckdns-letsencrypt-DNS01challenge

RUN apk --no-cache add certbot curl bash py3-pip && \
    pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.19/ certbot-dns-duckdns --break-system-packages

WORKDIR /scripts

COPY ./scripts /scripts

RUN chmod -R +x /scripts

CMD ["/bin/sh", "/scripts/start.sh"]
