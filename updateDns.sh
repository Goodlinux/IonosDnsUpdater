#! /bin/sh
########################
###### Variables #######
########################
# vars
base_url="https://api.hosting.ionos.com/"
curl_param="X-API-KEY:"
dns_zone="dns/v1/zones"
output_type="accept: application/json"
content_type="Content-Type: application/json"

#######################
##### Functions #######
#######################

Help() 
{
     # Show Help
    echo "Syntax update.sh [-a|-e|-f|-v]."
    echo "options:"
    echo "-a	change dns entry to given ip adress"
    echo "-e	show error codes"
    echo "-f	redirect verbose output to file"
    echo "-v	give verbose output"
    echo "-s 	update SPF record with IP"
    echo
}

ErrorCodes() 
{
	# Show Error codes
	echo "Error Codes: "
	echo "1	Invalid flags or reference"
	echo "2	ZoneId was not found"
}

log() 
{
	if [ $redirect_mode ]; 	then
		echo "$1" >> "$redirect_file"
	elif [ $verbose_mode ]; then
		echo "$1" >> /dev/stdout
	fi
}

GetExtIpAdress() 
{
	ip=$(curl -s ifconfig.me)
	log "Get ip from external : $ip."
}

GetZoneId() 
{
    log "- Searching zone id."
    zone_id=$(curl -X GET "$base_url$dns_zone" -H "$curl_param $API_KEY" -s );
    # check if valid object was found
    name=$(echo $zone_id | jq '.[] | .name?' );
    if [ "$name" = "" ]; then
	    # exit with error
	    echo "Error: $zone_id | jq '.[]'" >> /dev/stdout
	    exit 2
    fi
    zone_id=$(echo $zone_id | jq '.[] | .id?' | tr -d '"');
    log "Zoneid is $zone_id."
}

GetRecordZone() 
{
    log "- Searching dns records."
    customer_url="$base_url$dns_zone/$zone_id?suffix=$DOMAIN&recordType=$DNS_TYPE"
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records')
    echo $records | jq -c '.[]'  | while read record; do
        record_name=$(echo $record | jq '.name' | tr -d '"')
		#echo "name : $record_name"
        if [ "$record_name" = "$DOMAIN" ];  then
            log "Matching $record_name record found."
            record_ip=$(echo $record | jq '.content' | tr -d '"')
            if [ "$record_ip" = "$ip" ];  then
                    echo "Ip in $record_name : $record_ip is already up to date" >> /dev/stdout
            else
                    record_id=$(echo $record | jq '.id' | tr -d '"')
                    log "Updating record $record_name with Id : $record_id"
                    UpdateDNSRecord
		    if [ $? = 0 ]; then 
		        echo "Record $record_name ip updated old ip : $record_ip   New ip : $ip" >> /dev/stdout
		    fi
        fi
		    #Get out of the While with ERR 1 mean we found the record
		exit 1
		break
	fi
    done 
    if [ ! $? = 1 ]; then
	    log "Enregistrement non trouvé"
	    CreateDNSRecord
    fi
}

UpdateDNSRecord() 
{
	log "- Updating DNS Record. Record Id :  $record_id"
	update_url="$base_url$dns_zone/$zone_id/records/$record_id"
	record_content="{\"content\":\"$ip\"}"
	log "Record -$record_content"
	return=$(curl -s -X PUT  "$update_url"  -H "$output_type"  -H "$curl_param $API_KEY"  -H "$content_type" -d "$record_content")
	err=$(echo $return | jq '.[] | .code?' );
	msg=$(echo $return | jq '.[] | .message?' );
	if [ ! "$err" = ""  ]; then
	    log "update error, $err : $msg"
		exit 2
	fi
}

CreateDNSRecord() 
{
	log "- Creating DNS Record $DOMAIN."
	create_url="$base_url$dns_zone/$zone_id/records"
	record_content="[{\"name\":\"$DOMAIN\",\"type\":\"$DNS_TYPE\",\"content\":\"$ip\",\"ttl\":60,\"prio\":0,\"disabled\":false}]"
    return=$(curl -s -X POST "$create_url" -H "$output_type" -H "$curl_param $API_KEY" -H "$content_type" -d "$record_content")
	err=$(echo $return | jq '.[] | .code?' );
	msg=$(echo $return | jq '.[] | .message?' );
	if [ "$err" = "" ] || [ "$err" = "null"  ]; then
	    log "creation successfull"
	else
	    log "creation error, $err : $msg"
		exit 2
	fi
}


GetRecordSpf() 
{
    log "- Searching spf records."
    customer_url="$base_url$dns_zone/$zone_id?suffix=$DOMAIN&recordType=TXT"
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records')
    echo $records | jq -c '.[]'  | while read record; do
        record_name=$(echo $record | jq '.name' | tr -d '"')
		#echo "name : $record_name"
        if [ "$record_name" = "$DOMAIN" ];  then
            log "Matching $record_name record found."
            record_content=$(echo $record | jq '.content' | tr -d '"')
            spf_ip=$(expr index "$record_content" ip4:)
	    echo "ip dans sfp1 : $spf_ip"
	    spf_ip=$(echo $record_content | grep -E '((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}')
	    echo "ip dans sfp2 : $spf_ip"
	    if [ "$spf_ip" = "$ip" ];  then
                    echo "Ip in SPF $record_name : $record_ip is already up to date" >> /dev/stdout
            else
                    record_id=$(echo $record | jq '.id' | tr -d '"')
                    log "Updating record $record_name with Id : $record_id"
                    #UpdateDNSRecord
		    if [ $? = 0 ]; then 
		        echo "Record $record_name ip updated old ip : $record_ip   New ip : $ip" >> /dev/stdout
		    fi
        fi
		    #Get out of the While with ERR 1 mean we found the record
		exit 1
		break
	fi
    done 
    if [ ! $? = 1 ]; then
	    log "Enregistrement non trouvé"
	    CreateDNSRecord
    fi
}


CheckParamIP() 
{
	# check if ip paraeter is valid or set
	if [ "$ip" = "" ]; then
		log "ip is not set, search for actual external ip of this network"
		GetExtIpAdress
	else
         if [ "$ip" = "$(echo $ip | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ];  then
        	log "Ip : $ip is valid."
	    else
            log "ip isn't valid. search for actual external ip of this network"
            GetExtIpAdress
        fi
	fi
}

#################
##### START #####
#################
# Get Params
while getopts "ha:ef:vs" opt; do
     case $opt in
   # display help
        h) Help;;
   # ip adress
        a) ip=$OPTARG && log "- ip in param : $ip";;
   # show error codes
        e) ErrorCodes exit;;
   # redirect verbose output to file
        f) redirect_mode=true && redirect_file=$OPTARG;;
   # verbose mode
        v) verbose_mode=true && log "- verbose mode activated";;
   # Update IP in SPF for mail
	s) spf_mode=true
		;;
   # invalid options
        \?) echo "Error: Invalid options"
            exit 1;;
        esac
done

#verify if verbose mode was set by parameter ou system variable for Docker running
if [ ! "$verbose_mode" = "true" ]; then
    if [ "$VERBOSE" = "$(echo $VERBOSE | grep -E "^(y|Y|o|O)")" ]; then
        verbose_mode=true
        log "- verbose mode activated via sys param"
    fi
fi

# checks if ip was set and retrieves it if not
CheckParamIP
echo "Date : $(date +%Y-%m-%d_%H-%M)" >> /dev/stdout
echo "Updating : $DOMAIN with ip : $ip" >> /dev/stdout
# Retrieve DNS Zone Id
GetZoneId
# Retrieve Record Id and Create or Update DNS
GetRecordZone

if [ '$spf_mode' = 'true' ]; then
	GetRecordSpf
fi
