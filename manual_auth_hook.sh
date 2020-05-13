#!/bin/env bash

source ./namesilo_mate.sh

# $CERTBOT_DOMAIN "The domain being authenticated"
# $CERTBOT_VALIDATION "The validation string"
# $CERTBOT_TOKEN "Resource name part of the HTTP-01 challenge (HTTP-01 only)"
# $CERTBOT_REMAINING_CHALLENGES "Number of challenges remaining after the current challenge"
# $CERTBOT_ALL_DOMAINS "A comma-separated list of all domains challenged for the current certificate"

function updateOrAddRecord() {
    local domain=${1:?}
    local rrhost=${2:?}
    local rrvalue=${3:?}

    local response=$(echo $(operation dnsListRecords domain=$domain))
    local record_id=$(echo $response | print_dnsListRecords_response | grep "$rrhost" | awk '{printf "%s",$1}')
    local type=$(echo $response | print_dnsListRecords_response | grep "$rrhost" | awk '{printf "%s",$2}')
    local host=$(echo $response | print_dnsListRecords_response | grep "$rrhost" | awk '{printf "%s",$5}')
    local value=$(echo $response | print_dnsListRecords_response | grep "$rrhost" | awk '{printf "%s",$6}')
    local ttl=$(echo $response | print_dnsListRecords_response | grep "$rrhost" | awk '{printf "%s",$3}')
    local distance=$(echo $response | print_dnsListRecords_response | grep "$rrhost" | awk '{printf "%s",$4}')

    local rrid=${rrid:-$record_id}
    local rrdistance=${4:-${distance:-10}}
    local rrttl=${5:-${ttl:-7207}}

    if [[ -z "$rrid" ]]; then
        echo todo
    elif [[ "$rrvalue" != "$value" ]]; then
        request_dnsUpdateRecord $domain $rrid $rrhost $rrvalue $rrdistance $rrttl
    fi
}

updateOrAddRecord $CERTBOT_DOMAIN _acme-challenge $CERTBOT_VALIDATION

function digTXTRecord() {
    local record=$(dig -t txt _acme-challenge.$CERTBOT_DOMAIN @8.8.8.8 | grep -P -o "^_acme-challenge\.$CERTBOT_DOMAIN.+" | grep -P -o "(?<=\").+?(?=\")")
    if [[ 0 -eq $? && "$record" == $CERTBOT_VALIDATION ]]; then
        return 0
    fi
    return 1
}

times=0
for ((;;)) do
    digTXTRecord
    if ((0 == $?)); then
        break
    fi
    times=$((times+1))
    echo "wait in $times minute"
    sleep 60
done
