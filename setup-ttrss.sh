#!/bin/sh

set -e

setup_nginx()
{
    if [ -z "$TTRSS_HOST" ]; then
        TTRSS_HOST=ttrss
    fi

    if [ "$TTRSS_SSL_ENABLED" = "1" ]; then
        if [ ! -f "/etc/ssl/private/ttrss.key" ]; then
            # Generate the TLS certificate for our Tiny Tiny RSS server instance.
            openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
                -subj "/C=US/ST=World/L=World/O=$TTRSS_HOST/CN=$TTRSS_HOST" \
                -keyout "/etc/ssl/private/ttrss.key" \
                -out "/etc/ssl/certs/ttrss.crt"
        fi
        chmod 600 "/etc/ssl/private/ttrss.key"
        chmod 600 "/etc/ssl/certs/ttrss.crt"
    else
        # Turn off SSL.
        sed -i -e "s/listen\s*443\s*;/listen 80;/g" /etc/nginx/sites-enabled/ttrss
        sed -i -e "s/ssl\s*on\s*;/ssl off;/g" /etc/nginx/sites-enabled/ttrss
        sed -i -e "/\s*ssl_*/d" /etc/nginx/sites-enabled/ttrss
    fi

    # Configure Nginx so that is doesn't show its version number in the HTTP headers.
    sed -i -e "s/.*server_tokens\s.*/server_tokens off;/g" /etc/nginx/nginx.conf
}

setup_ttrss()
{
    TTRSS_PATH=/var/www/ttrss

    mkdir -p ${TTRSS_PATH}
    git clone https://tt-rss.org/gitlab/fox/tt-rss.git ${TTRSS_PATH}
    git clone https://github.com/sepich/tt-rss-mobilize.git ${TTRSS_PATH}/plugins/mobilize
    git clone https://github.com/hrk/tt-rss-newsplus-plugin.git ${TTRSS_PATH}/plugins/api_newsplus
    git clone https://github.com/levito/tt-rss-feedly-theme.git ${TTRSS_PATH}/themes/feedly-git

    # Add initial config.
    cp ${TTRSS_PATH}/config.php-dist ${TTRSS_PATH}/config.php

    # Patch URL path.
    sed -i -e 's@htt.*/@'"${SELF_URL_PATH-http://localhost/}"'@g' ${TTRSS_PATH}/config.php

    # Enable additional system plugins: api_newsplus.
    sed -i -e "s/.*define('PLUGINS'.*/define('PLUGINS', 'api_newsplus, auth_internal, note, updater');/g" ${TTRSS_PATH}/config.php
}

echo "Setup: Installing Tiny Tiny RSS ..."
setup_ttrss
setup_nginx

echo "Setup: Applying updates ..."
/srv/update-ttrss.sh --no-start

echo "Setup: Done"
