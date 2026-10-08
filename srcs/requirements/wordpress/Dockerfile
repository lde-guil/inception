FROM alpine:3.22.0

RUN apk update && apk add --no-cache \
    php83 php83-fpm php83-mysqli php83-json php83-curl php83-dom \
    php83-mbstring php83-xml php83-zip php83-openssl php83-phar php83-pecl-redis \
    php83-tokenizer php83-xmlwriter php83-simplexml php83-ctype \
    bash curl wget mariadb-client

COPY tools/wordpress.sh /usr/bin/wordpress.sh

RUN chmod +x /usr/bin/wordpress.sh 

EXPOSE 9000/tcp

CMD ["wordpress.sh"]