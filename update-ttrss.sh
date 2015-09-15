#!/bin/sh
set -e

TTRSS_PATH=/var/www/ttrss

# Note: Make sure to keep the actual updater service ("ttrss-update") alive,
#       otherwise this script will be killed and everyting goes nuts.
TTRSS_SUPERVISORD_SERVICES="ttrss-daemon nginx php5-fpm"

update_ttrss()
{
    echo "Updating: Tiny Tiny RSS"
    ( cd ${TTRSS_PATH} && git pull origin master )

    if [ -n "$DB_PORT" ]; then
        echo "Updating: Database"
        php /srv/ttrss-configure-db.php
        php /srv/ttrss-configure-plugin-mobilize.php
    fi
}

update_plugin_mobilize()
{
    echo "Updating: Mobilize plugin"
    ( cd ${TTRSS_PATH}/plugins/mobilize && git pull origin master )

    # Patch ttrss-mobilize plugin for getting it to work.
    sed -i -e "s/<?$/<?php/g" ${TTRSS_PATH}/plugins/mobilize/m.php
}

# For use with News+ on Android. Buy the Pro version -- I love it!
update_plugin_newsplus()
{
    echo "Updating: News+ plugin"
    ( cd ${TTRSS_PATH}/plugins/api_newsplus && git pull origin master )

    # Link plugin to TTRSS.
    ln -f -s ${TTRSS_PATH}/plugins/api_newsplus/api_newsplus/init.php ${TTRSS_PATH}/plugins/api_newsplus/init.php
}

update_theme_feedly()
{
    echo "Updating: Feedly theme"
    ( cd ${TTRSS_PATH}/themes/feedly-git && git pull origin master )

    # Link theme to TTRSS.
    ln -f -s ${TTRSS_PATH}/themes/feedly-git/feedly ${TTRSS_PATH}/themes/feedly
    ln -f -s ${TTRSS_PATH}/themes/feedly-git/feedly.css ${TTRSS_PATH}/themes/feedly.css
}

update_common()
{
    # Apply ownership of ttrss + addons to www-data.
    chown www-data:www-data -R ${TTRSS_PATH}
}

echo "Update: Updating rolling release ..."
echo "Update: Stopping all ..."

supervisorctl stop ${TTRSS_SUPERVISORD_SERVICES}
update_ttrss
update_plugin_mobilize
update_plugin_newsplus
update_theme_feedly
update_common

echo "Update: Done."

if [ "$1" != "--no-start" ]; then
    echo "Update: Starting all ..."
    supervisorctl start ${TTRSS_SUPERVISORD_SERVICES}
fi
if [ "$1" = "--wait-exit" ]; then
    UPDATE_WAIT_TIME=$2
    if [ -z "$UPDATE_WAIT_TIME" ]; then
        UPDATE_WAIT_TIME=24h # Default is to check every day (24 hours).
    fi
    echo "Update: Sleeping for $UPDATE_WAIT_TIME ..."
    sleep ${UPDATE_WAIT_TIME}
fi
