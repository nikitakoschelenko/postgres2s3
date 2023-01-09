FROM alpine:latest

RUN apk update \
	&& apk add coreutils \
	&& apk add postgresql-client \
	&& apk add python3 py3-pip && pip3 install --upgrade pip && pip3 install awscli \
	&& apk add openssl \
	&& rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh

CMD ["sh", "/entrypoint.sh"]
