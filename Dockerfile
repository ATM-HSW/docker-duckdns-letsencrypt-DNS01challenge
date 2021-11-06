FROM alpine:latest

ARG TARGETARCH

LABEL org.label-schema.docker.dockerfile=/Dockerfile org.label-schema.vcs-type=Git org.label-schema.vcs-url=https://gitlab.com/aazario/docker-duckdns-letsencrypt

RUN apk --no-cache add certbot curl

WORKDIR /scripts

COPY ./scripts /scripts

RUN chmod -R +x /scripts

CMD ["/bin/sh", "/scripts/start.sh"]
