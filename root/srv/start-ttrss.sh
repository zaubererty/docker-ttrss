#!/bin/sh

set -e

# Update configuration. This is necessary for entering the current IP + PORT of the database.
/srv/update-ttrss.sh --no-start

# Call the image's init script which in turn calls the s6 supervisor then.
/init
