VERSION=1
TYPE=xml
YOURAPIKEY=${YOURAPIKEY:?do you have a api key?}

function dump_element() {
    local root=${1:?}
    local tag=${2:?}
    echo $(echo $root | grep -P -o "(?<=<$tag>).+?(?=</$tag>)")
}

function print_table_head() {
    local labels=("${!1}")
    local widths=("${!2}")

    local format_str=
    local label_str=
    local dash_str=

    for ((i=0; i<${#labels[@]}; i++)); do
        local str=

        str=%-${widths[i]}s
        if [[ -z $format_str ]]; then
            format_str="$str"
        else
            format_str="$format_str $str"
        fi

        str=${labels[i]}
        if [[ -z "$label_str" ]]; then
            label_str="$str"
        else
            label_str="$label_str $str"
        fi
        
        str=$(printf -- "-%.0s" $(seq ${widths[i]}))
        if [[ -z "$dash_str" ]]; then
            dash_str="$str"
        else
            dash_str="$dash_str $str"
        fi
    done

    # echo $format_str
    # echo $label_str
    # echo $dash_str

    printf "$format_str\n" $label_str
    printf "$format_str\n" $dash_str
}

function print_table_body() {
    local values=("${!1}")
    local widths=("${!2}")

    local format_str=
    local value_str=

    for ((i=0; i<${#values[@]}; i++)); do
        local str=

        str=%-${widths[i]}s
        if [[ -z $format_str ]]; then
            format_str="$str"
        else
            format_str="$format_str $str"
        fi

        str=${values[i]}
        if [[ -z "$value_str" ]]; then
            value_str="$str"
        else
            value_str="$value_str $str"
        fi
    done

    # echo $format_str
    # echo $value_str

    printf "$format_str\n" $value_str
}

function print_standard_response() {
    local input=${1:+$(cat $1)}
    if [[ -z "$input" ]]; then read input; fi

    local request=$(dump_element "$input" request)
    local operation=$(dump_element "$request" operation)
    local ip=$(dump_element "$request" ip)

    local reply=$(dump_element "$input" reply)
    local code=$(dump_element "$reply" code)
    local detail=$(dump_element "$reply" detail)

    local labels=(operation ip code)
    local widths=(20 20 20)
    print_table_head labels[@] widths[@]

    local values=($operation $ip $code)
    print_table_body values[@] widths[@]
}

function print_listDomains_response() {
    local input=${1:+$(cat $1)}
    if [[ -z "$input" ]]; then read input; fi

    local labels=(domain)
    local widths=(40)
    print_table_head labels[@] widths[@]

    local reply=$(dump_element "$input" reply)
    local domains=$(dump_element "$reply" domains)
    for domain in $(echo $domains | grep -P -o "<domain>.+?</domain>"); do
        local domain=$(dump_element "$domain" domain)

        local values=($domain)
        print_table_body values[@] widths[@]
    done
}

function print_dnsListRecords_response() {
    local input=${1:+$(cat $1)}
    if [[ -z "$input" ]]; then read input; fi

    local labels=(record_id type ttl distance host value)
    local widths=(40 10 10 10 60 80)
    print_table_head labels[@] widths[@]

    local reply=$(dump_element "$input" reply)
    for resource_record in $(echo $reply | grep -P -o "<resource_record>.+?</resource_record>"); do
        local record_id=$(dump_element "$resource_record" record_id)
        local type=$(dump_element "$resource_record" type)
        local host=$(dump_element "$resource_record" host)
        local value=$(dump_element "$resource_record" value)
        local ttl=$(dump_element "$resource_record" ttl)
        local distance=$(dump_element "$resource_record" distance)

        local values=($record_id $type $ttl $distance $host $value)
        print_table_body values[@] widths[@]
    done
}

function operation() {
    local url=https://www.namesilo.com/api/$1\?version=$VERSION\&type=$TYPE\&key=$YOURAPIKEY\&$2
    curl -s $url
}

function request_listDomains() {
    # Limit results by an encoded portfolio name
    local portfolio=${1:-}

    local response=$(echo $(operation listDomains portfolio=$portfolio))
    echo $response | print_standard_response
    echo
    echo $response | print_listDomains_response
}
# request_listDomains

function request_dnsListRecords() {
    # The domain being requested
    local domain=${1:?}

    local response=$(echo $(operation dnsListRecords domain=$domain))
    echo $response | print_standard_response
    echo
    echo $response | print_dnsListRecords_response
}
# request_dnsListRecords wolfired.com

function request_dnsAddRecord() {
    # The domain being updated
    local domain=${1:?}
    # The type of resources record to add. Possible values are "A", "AAAA", "CNAME", "MX" and "TXT"
    local rrtype=${2:?}
    # The hostname for the new record (there is no need to include the ".DOMAIN")
    local rrhost=${3:?}
    # The value for the resource record
    # A     - The IPV4 Address
    # AAAA  - The IPV6 Address
    # CNAME - The Target Hostname
    # MX    - The Target Hostname
    # TXT   - The Text
    local rrvalue=${4:?}
    # Only used for MX (default is 10 if not provided)
    local rrdistance=${5:-10}
    # The TTL for the new record (default is 7207 if not provided)
    local rrttl=${6:-7207}

    local response=$(echo $(operation dnsAddRecord domain=$domain\&rrtype=$rrtype\&rrhost=$rrhost\&rrvalue=$rrvalue\&rrdistance=$rrdistance\&rrttl=$rrttl))
    echo $response
}
# request_dnsAddRecord wolfired.com TXT abcde edcba
# request_dnsListRecords wolfired.com

function request_dnsUpdateRecord() {
    # The domain associated with the DNS resource record to modify
    local domain=${1:?}
    # The unique ID of the resource record. You can get this value using dnsListRecords
    local rrid=${2:?}
    # The hostname to use (there is no need to include the ".DOMAIN")
    local rrhost=${3:?}
    # The value for the resource record
    # A     - The IPV4 Address
    # AAAA  - The IPV6 Address
    # CNAME - The Target Hostname
    # MX    - The Target Hostname
    # TXT   - The Text
    local rrvalue=${4:?}
    # Only used for MX (default is 10 if not provided)
    local rrdistance=${5:-10}
    # The TTL for this record (default is 7207 if not provided)
    local rrttl=${6:-7207}

    local response=$(echo $(operation dnsUpdateRecord domain=$domain\&rrid=$rrid\&rrhost=$rrhost\&rrvalue=$rrvalue\&rrdistance=$rrdistance\&rrttl=$rrttl))
    echo $response
}
# request_dnsUpdateRecord

function request_dnsDeleteRecord() {
    # The domain associated with the DNS resource record to delete
    local domain=${1:?}
    # The unique ID of the resource record. You can get this value using dnsListRecords
    local rrid=${2:?}

    local response=$(echo $(operation dnsDeleteRecord domain=$domain\&rrid=$rrid))
    echo $response
}
# request_dnsDeleteRecord wolfired.com 58db68e7d63d82119706d5e7a61ddf51
# request_dnsListRecords wolfired.com
