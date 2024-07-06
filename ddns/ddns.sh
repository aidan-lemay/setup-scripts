#!/usr/bin/env bash

# Create logfile
parent_path="$(dirname "${BASH_SOURCE[0]}")"

FILE=${parent_path}/log.log

if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

LOG_FILE=${parent_path}'/log.log'

# Write last run of STDOUT & STDERR as log file and prints to screen
exec > >(tee $LOG_FILE) 2>&1
echo "==> $(date "+%Y-%m-%d %H:%M:%S")"

# Validate if config-file exists
if [[ -z "$1" ]]; then
  if ! source ${parent_path}/cfddns.conf; then
    echo 'Error! Missing configuration file cfddns.conf or invalid syntax!'
    exit 1
  fi

else
  if ! source ${parent_path}/"$1"; then
    echo 'Error! Missing configuration file '$1' or invalid syntax!'
    exit 1
  fi
fi

# Get external ip
ip=$(curl -4 -s -X GET https://checkip.amazonaws.com --max-time 10)

if [ -z "$ip" ]; then
    echo "Error! Can't get external ip from https://checkip.amazonaws.com"
    exit 1
fi

if ! [[ "$ip" =~ $REIP ]]; then
    echo "Error! IP Address returned was invalid!"
    exit 1
fi

echo "==> External IP is: $ip"

# Get the dns record id and current proxy status from Cloudflare API
dns_record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$dns_record" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json")

if [[ ${dns_record_info} == *"\"success\":false"* ]]; then
    echo ${dns_record_info}
    echo "Error! Can't get dns record info from Cloudflare API"
    exit 1
fi

is_proxed=$(echo ${dns_record_info} | grep -o '"proxied":[^,]*' | grep -o '[^:]*$')
dns_record_ip=$(echo ${dns_record_info} | grep -o '"content":"[^"]*' | cut -d'"' -f 4)

# Check if ip or proxy have changed
if [ ${dns_record_ip} == ${ip} ]; then
    echo "==> DNS record IP of ${dns_record} is ${dns_record_ip}", no changes needed.
    exit 0
fi

echo "==> DNS record of ${dns_record} is: ${dns_record_ip}. Trying to update..."

# Get the dns record information from Cloudflare API
cloudflare_record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$dns_record" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json")

if [[ ${cloudflare_record_info} == *"\"success\":false"* ]]; then
    echo ${cloudflare_record_info}
    echo "Error! Can't get ${dns_record} record information from Cloudflare API"
    exit 1
fi

# Get the dns record id from response
cloudflare_dns_record_id=$(echo ${cloudflare_record_info} | grep -o '"id":"[^"]*' | cut -d'"' -f4)

# Push new dns record information to Cloudflare API
update_dns_record=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$cloudflare_dns_record_id" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$dns_record\",\"content\":\"$ip\",\"ttl\":$ttl,\"proxied\":$proxied}")

if [[ ${update_dns_record} == *"\"success\":false"* ]]; then
    echo ${update_dns_record}
    echo "Error! Update failed"
    exit 1
fi

echo "==> Success!"
echo "==> $dns_record DNS Record updated to: $ip, ttl: $ttl, proxied: $proxied"
exit 0