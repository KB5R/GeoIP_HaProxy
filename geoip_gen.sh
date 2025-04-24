#!/bin/bash

# https://nixhub.ru/posts/haproxy-geoip-setup/
# https://github.com/Loyalsoldier/geoip/tree/release

PROXY_SERVER=""
PROXY_PORT=""

GEOIP_ACL_PATH="/etc/haproxy/geoip"
GEOIP_TEMP_PATH="/tmp"


function DownloadDatabases () {
        # Clean old downloads artifacts:
        rm -rf  $GEOIP_TEMP_PATH/{*.csv,*.zip}

        # Get geoip database zip-file and unzip archive:
        if [ $PROXY_SERVER ]; then
                export https_proxy="http://$PROXY_SERVER:$PROXY_PORT/"
        fi

        curl -o $GEOIP_TEMP_PATH/geip_csv.zip https://raw.githubusercontent.com/Loyalsoldier/geoip/release/GeoLite2-Country-CSV.zip && \
        unzip -j $GEOIP_TEMP_PATH/geip_csv.zip -d $GEOIP_TEMP_PATH "*IPv4.csv" "*en.csv"

        # Rename csv-file:
        find /tmp/ -depth -type f -name '*IPv4.csv' -exec mv {} /tmp/ips.csv \;
        find /tmp/ -depth -type f -name '*en.csv' -exec mv {} /tmp/countres.csv \;
}

function CreateAclLists () {
        if [ ! -d $GEOIP_ACL_PATH ]; then
                mkdir -p $GEOIP_ACL_PATH
        fi

        while read line; do
                COUNTRY_CODE=$(echo $line | cut -d, -f5)
                COUNTRY_ID=$(echo $line | cut -d, -f1)

                # Create new country list
                cat $GEOIP_TEMP_PATH/ips.csv | grep $COUNTRY_ID | cut -d, -f1 > $GEOIP_ACL_PATH/$COUNTRY_CODE.list
        done <$GEOIP_TEMP_PATH/countres.csv
}

DownloadDatabases
CreateAclLists
