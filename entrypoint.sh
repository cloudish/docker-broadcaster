#!/bin/bash
set -e

source ~/.bash_profile

run() {
    sed -i -e "s,<url_transcode>,$URL_TRANSCODE,g" /usr/local/nginx-streaming/conf/nginx.conf

    sed -i -e "s,<fps>,$FPS,g" /usr/local/nginx-streaming/conf/nginx.conf
    sed -i -e "s,<x264_preset>,$X264_PRESET,g" /usr/local/nginx-streaming/conf/nginx.conf
    sed -i -e "s,<bitrate>,$BITRATE,g" /usr/local/nginx-streaming/conf/nginx.conf
    sed -i -e "s,<key_interval>,$KEY_INTERVAL,g" /usr/local/nginx-streaming/conf/nginx.conf
    sed -i -e "s,<chunk_size>,$CHUNK_SIZE,g" /usr/local/nginx-streaming/conf/nginx.conf
    sed -i -e "s,<url_live>,$URL_LIVE,g" /usr/local/nginx-streaming/conf/nginx.conf
    sed -i -e "s,<stream_specifier>,$STREAM_SPECIFIER,g" /usr/local/nginx-streaming/conf/nginx.conf
    sed -i -e "s,<private_key>,$PRIVATE_KEY,g" /usr/local/nginx-streaming/conf/nginx.conf

    #iterate through the json representing the servers and build out exec text, then inject
    pushes=""
    for row in $(echo "${SERVERS_JSON}" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }

        pushes+="exec_push $(_jq '.url') playpath=$(_jq '.key') name=degraded_quality;\n"
    done
    sed -i -e "s,<transcoded_stream_array>,${pushes},g" /usr/local/nginx-streaming/conf/nginx.conf

    #handle the expiration
    today=$(date +%s)
    expire=$(($today+$EXPIRATION_TOKEN))
    token=$(echo -n "$PRIVATE_KEY/stream$expire" | openssl dgst -md5 -binary |
             openssl enc -base64 | tr '+/' '-_' | tr -d '=')
    formatted_date=$(date --date="@$expire" +"%m-%d-%Y %r")

    echo "="
    echo "= Mobile files        = http://$YOUR_IP/"
    echo "= URL live            = rtmp://$YOUR_IP:1935/$URL_LIVE/"
    echo "= URL transcode       = rtmp://$YOUR_IP:1935/$URL_TRANSCODE/"
    echo "= Stream Key          = stream?e=$expire&st=$token"
    echo "= Expiration token    = $formatted_date (in $EXPIRATION_TOKEN sec.)                                          "
    echo "="
    echo "==============================================================================================="

    chown docker /src -Rf
    supervisord
}

case "$1" in
"run")
    echo "Run"
    run
    ;;
*)
    echo "Custom command : $@"
    exec "$@"
    ;;
esac
