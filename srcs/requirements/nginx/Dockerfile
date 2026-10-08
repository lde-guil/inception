FROM alpine:3.22.0

RUN apk upgrade
RUN apk add --no-cache nginx openssl bash
RUN mkdir -p /etc/nginx/ssl
RUN openssl ecparam -name prime256v1 -genkey -noout -out my-key.pem 
RUN openssl req -x509 -days 365 -key my-key.pem -noenc \
    -out /etc/nginx/ssl/nginx-crt.pem \
    -keyout /etc/nginx/ssl/nginx-key.pem \
    -subj "/C=FR/ST=Paris/L=Paris/O=42 Paris/OU=lde-guil.42.fr/CN=lde-guil.42.fr"

COPY ./conf/default.conf /etc/nginx/http.d/default.conf

EXPOSE 80/tcp 443/tcp

CMD ["nginx", "-g", "daemon off;"]