FROM alpine:latest

RUN apk update
RUN apk add coreutils postgresql-client python3 py3-pip openssl --no-cache
RUN pip3 install awscli

COPY entrypoint.sh /entrypoint.sh

CMD ["sh", "/entrypoint.sh"]
