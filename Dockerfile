FROM alpine:latest

ARG TARGETARCH

RUN apk --no-cache add certbot curl

WORKDIR /scripts

COPY ./scripts /scripts

RUN chmod -R +x /scripts

CMD ["/bin/sh", "/scripts/start.sh"]
