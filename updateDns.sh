#! /bin/sh
###################################
########## Variables ##############
###################################
# vars
base_url="https://api.hosting.ionos.com/"
curl_param="X-API-KEY:"
dns_zone="dns/v1/zones"
dns_records_start="dns/v1/"
dns_records_end="/records/"
zone="zones/"
output_type="accept: application/json"
record_found=0

###################################
########## Functions ##############
###################################

function Help() {
     # Show Help
    echo "Syntax update.sh [-a|-e|-f|-v]."
    echo "options:"
    echo "-a	change dns entry to given ip adress"
    echo "-e	show error codes"
    echo "-f	redirect verbose output to file"
    echo "-v	give verbose output"
    echo
}

function ErrorCodes() {
	echo "Error Codes: "
	echo "1	Invalid flags or reference"
	echo "2	ZoneId was not found"
}

function log() {
	if [ $redirect_mode ]; 	then
		echo $1 >> $redirect_file
	elif [ $verbose_mode ];
	  then
		echo $1
	fi
}

function GetExtIpAdress() {
	ip=$(curl -s ifconfig.me)
	log "Ip set to $ip." 
}

function GetZoneId() {
    log "Retrieving zone id."
    zone_id=$(curl -X GET "$base_url$dns_zone" -H "$curl_param $API_KEY" -s );
    # check if valid object was found
    name=$(echo $zone_id | jq '.[] | .name?' );
    if [[ "$name" == "" ]]; then 
	    # exit with error 
	    echo "Error: $zone_id | jq '.[]'"
	    exit 2
    fi
    zone_id=$(echo $zone_id | jq '.[] | .id?' | tr -d '"');
    log "Zoneid is $zone_id."
}

function GetRecordZone() {
    log "Retrieving dns records."
    customer_url="$base_url$dns_zone/$zone_id?recordType=$DNS_TYPE"	
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records')
    log "Find some domain record."
    #log "$records"
    echo $records | jq -c '.[]'  | while read i; do
    name=$(echo $i | jq '.name' | tr -d '"')
    if [[ $name = "$DOMAIN" || $name = "www.$DOMAIN" ]];  then
            log "Matching $name record found. \n"
	    log "$i \n"
	    record_found=1
            current_ip=$(echo $i | jq '.content' | tr -d '"')
            if [[ "$current_ip" == "$ip" ]];  then 
                    log "Ip in record : $current_ip is up to date no update"
		    exit 0
            else 
                    rec_id=$(echo $i | jq '.id' | tr -d '"')
		    log "Updating record $name with Id : $rec_id"
                    UpdateDNSRecord "$rec_id"
		    log "Ip updated old ip : $current_ip   New ip : $ip"
		    exit 0
            fi
    fi
    done
    if [ $record_found == 0 ]; then 
	log "Enregistrement non trouvé"
	CreateDNSRecord
    fi
}
	
function UpdateDNSRecord() {
	log "Updating DNS Record."
	updatedns_url="$base_url$dns_zone/$zone_id/records/$1"
	record_content="[{\"content\":\"$ip\"}]"
	log "url $updatedns_url Record -$record_content"
	curl -X PUT "$updatedns_url" -H "accept: application/json"  -H "$curl_param $API_KEY"  -H "Content-Type: application/json" -d "$record_content"
}

	
function CreateDNSRecord() {
	log "Creating DNS Record."
	createdns_url="$base_url$dns_zone/$zone_id/records"
	record_content="[{\"name\":\"$DOMAIN\",\"type\":\"$DNS_TYPE\",\"content\":\"$ip\",\"ttl\":60,\"prio\":0,\"disabled\":false}]"
	log "url : $createdns_url   Record : $record_content"
	curl -X POST "$createdns_url" -H "accept: application/json" -H "$curl_param $API_KEY" -H "Content-Type: application/json" -d "$record_content"

#        createdns_url="$base_url$dns_zone/$zone_id/records" 
#	record_content="[{\"name\":\"$domain\",\"type\":\"$dns_type\",\"content\":\"$ip\",\"ttl\":60,\"prio\":0,\"disabled\":false}]"
#	curl -X POST $createdns_url -H "accept: */*" -H "$curl_param $api_key" -H "Content-Type: application/json" -d "$record_content"


}

function CheckParamIP() {
	# check if ip paraeter is valid or set
	if [[ '$ip' == '' ]]; then
		log "No Ip in parameter chearch for actual external Ip of this network"
		GetExtIpAdress
	else
		if [[ $ip == $(echo $ip | grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' ) ]]; then                                                                                                          
			log "Ip $ip is valid, Setting ip to $ip" 
	   	else
			log "Ip isn't valid or set. This script will search for the actual ip adress of this machine."
			GetExtIpAdress
		fi
	fi
}

###################################
########## START ##################
###################################

# Get Flags
while getopts "ha:ef:v" opt; do
     case $opt in
		# display help
	h) Help;;
		# ip adress
        a) ip=$OPTARG;;
		# show error codes
	e) ErrorCodes exit;;
		# redirect verbose output to file
	f) redirect_mode=true && redirect_file=$OPTARG;;
		# verbose mode
        v) verbose_mode=true;;
		# invalid options
	\?) echo "Error: Invalid options"
	    exit 1;;
        esac
done

# checks if ip was set and retrieves it if not
log "Date : $(date) \n"
CheckParamIP
GetZoneId
GetRecordZone
