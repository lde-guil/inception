FROM alpine:3.22.0

RUN apk update && apk upgrade && apk add mariadb mariadb-client bash

RUN rm /etc/my.cnf.d/mariadb-server.cnf

COPY tools/mariadb.sh /usr/bin/mariadb.sh

RUN chmod +x /usr/bin/mariadb.sh

EXPOSE 3306/tcp

RUN mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql

CMD ["mariadb.sh"]