#!/bin/sh
#
# This script is in charge of calling "support-pack" and generating an
# appropriate HTML page to download the newly generated archive.
# Copyright (C) 2021-present Savoir-faire Linux Inc.

# Generate the debug package and retrieve its path. This operation may take some
# time.

export PATH=/bin:/sbin:/usr/bin:/usr/sbin
rm -rf /srv/www/tmp/support-pack-*.tar.gz

ERROR_FILE=$(mktemp)
TSTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE_NAME=$(support-pack -o /srv/www/tmp/support-pack-${TSTAMP}.tar.gz 2>"${ERROR_FILE}")
ARCHIVE_RET=$?

# Output a web page and its HTTP header to stdout.
printf "Content-type: text/html \n\n";

if [ ${ARCHIVE_RET} -eq 0 ]; then
    cat <<EOF
<html>
<head><title>Embedded Application Support-pack</title></head>
<body>
<h1>Download Log File</h1><p>
Debug archive ready to be downloaded: <a href="${ARCHIVE_NAME#/srv/www}">${ARCHIVE_NAME#/srv/www}</a>
</p></body></html>
EOF
else
    ERROR_MESSAGES=$(cat "${ERROR_FILE}")
    cat <<EOF
<html>
<head><title>Embedded Application Support-pack</title></head>
<body>
<h1>Error</h1>
<p>Debug archive could not be generated for the following reasons:</p>
<code>
${ERROR_MESSAGES}
</code>
</body></html>
EOF
fi

rm "${ERROR_FILE}"
