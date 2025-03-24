#!/bin/sh
while :; do
    certbot renew --webroot -w /var/www/html
    docker compose restart nginx
    sleep 12h  # Check every 12 hours
done
