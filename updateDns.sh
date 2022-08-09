#! /bin/sh
###################################
########## Variables ##############
###################################
export TOP_PID=$$
# source .env file
#SCRIPTPATH=$(dirname $(readlink -f "$0"))
#. "$SCRIPTPATH/.env"

# vars
base_url="https://api.hosting.ionos.com/"
curl_param="X-API-KEY:"
dns_zone="dns/v1/zones"
dns_records_start="dns/v1/"
dns_records_end="/records/"
zone="zones/"
output_type="accept: application/json"
kill_script=false

###################################
########## Functions ##############
###################################

function Help() {
     # Show Help
    echo "If you need further help than the below, read the readme file \n  or create an issue on github."
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
	echo "2 	ZoneId was found"
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
	ip=$(curl -s https://ipinfo.io/ip)
	log "Ip set to $ip." 
}

function GetZoneId() {
    log "Retrieving zone id."
    # get zone ID
    zone_id=$(curl -X GET "$base_url$dns_zone" -H "$curl_param $API_KEY" -s );
    # check if valid object was found
    name=$(echo $zone_id | jq '.[] | .name?' );
    if [[ "$name" == "" ]]; then 
	    # exit with error 
	    echo "Error: $zone_id | jq '.[]'"
	    exit 2
    fi
    zone_id=$(echo $zone_id | jq '.[] | .id?' | tr -d '"');
    log "Zoneid was set to $zone_id."
}

#function DeleteRecord() {	
#   log "Deleting record $1."
#    delete_url="$base_url$dns_zone/$zone_id/records/$1"
#    curl -X DELETE $delete_url -H "accept: */*" -H "$curl_param $API_KEY"
#}

function GetCustomerZone() {
    log "Retrieving dns records."
    customer_url="$base_url$dns_zone/$zone_id?recordType=$DNS_TYPE"	
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records')
    log "Find maching domain record."
	log "$records"
    echo $records | jq -c '.[]'  | while read i; do
    name=$(echo $i | jq '.name' | tr -d '"')
    if [[ $name = "$DOMAIN" || $name = "www.$DOMAIN" ]];  then
            log "Matching record found."
            current_ip=$(echo $i | jq '.content' | tr -d '"')
            if [[ "$current_ip" == "$ip" ]];  then 
                    log "Ip dans l'enregistrement : $current_ip pas de mise à jour"
            else 
                    rec_id=$(echo $i | jq '.id' | tr -d '"')
                    UpdateDNSRecord "$rec_id"
		    log "Ip mise à jour ancienne : $current_ip   New : $ip"
		    exit 0
            fi
            #rec_id=$(echo $i | jq '.id' | tr -d '"')
            #DeleteRecord "$rec_id"
    fi
    done
	log "Enregistrement non trouvé"
}
	
function UpdateDNSRecord() {
	log "Updating DNS Record."
	createdns_url="$base_url$dns_zone/$zone_id/records/$1"
	record_content="[{\"name\":\"$DOMAIN\",\"type\":\"$DNS_TYPE\",\"content\":\"$ip\"}]"
	curl -X PUT $createdns_url -H "accept: */*" -H "$curl_param $API_KEY" -H "Content-Type: application/json" -d "$record_content"
	log $createdns_url -H "accept: */*" -H "$curl_param $API_KEY" -H "Content-Type: application/json" -d "$record_content"
}

	
function CreateDNSRecord() {
	log "Creating DNS Record."
	createdns_url="$base_url$dns_zone/$zone_id/records"
	record_content="[{\"name\":\"$DOMAIN\",\"type\":\"$DNS_TYPE\",\"content\":\"$ip\",\"ttl\":60,\"prio\":0,\"disabled\":false}]"
	curl -X POST $createdns_url -H "accept: */*" -H "$curl_param $API_KEY" -H "Content-Type: application/json" -d "$record_content"
	log $createdns_url -H "accept: */*" -H "$curl_param $API_KEY" -H "Content-Type: application/json" -d "$record_content"
}

function CheckParamIP() {
	# check ip regex
	if [[ $ip =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$ ]]; then
		log "Ip set to $ip" 
	   else
		log "Adress isn't valid or set. This script will search for the actual ip adress of this machine."
		GetExtIpAdress
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
CheckParamIP
GetZoneId
GetCustomerZone
#CreateDNSRecord

log "This script is done and will exit"
