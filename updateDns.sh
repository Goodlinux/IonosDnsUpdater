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
DOMAIN="maillet.me"
DNS_TYPE="A"
API_KEY="ed1d0dbe63b2449eb928d8fff7f4d476.r0CZ6k-dSOIFmguqpSwHnnhcxnoUYa6xgwWHZobPrnk8HqEliuqVCz8vM4YS5Ybt3Mw5jtq9uQdksZ7ACvF5qQ"



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
    customer_url="$base_url$dns_zone/$zone_id?suffix=$DOMAIN&recordName=$DOMAIN&recordType=$DNS_TYPE"
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
	    #CreateDNSRecord
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
    customer_url="$base_url$dns_zone/$zone_id?suffix=$DOMAIN&recordName=$DOMAIN&recordType=TXT"
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records' | tr -d "\\" | tr -s '"')
    echo $records > records.txt
    echo $records | jq -c '.[]'  | while read record; do
        echo $record > record.txt
        record_content=$(echo $record | jq -c '.content' | tr -d '"')
        echo $record_content > record_content
        test=$(echo $record_content | grep -q '^v=spf1')
        if [ $? = 0 ];  then
            log "Matching spf1 record found."
            echo $record_content > record_content
            new_content=$(echo $record_content | awk -v newip=$ip '
                    {for (i=1; i<=NF; i++) 
                        {
                        if (i > 1) { printf " "}
                        if ( index($i,"ip4:") == 1  )
                            { printf "ip4:"newip }
                        else 
                            { printf $i }
                        }
                    }  ')
            log "spf old record : $record_content"
            log "spf new record : $new_content"
            record_id=$(echo $record | jq -c '.id' | tr -d '"')
                        
           	log "- Updating SPF Record. Record Id :  $record_id"
            update_url="$base_url$dns_zone/$zone_id/records/$record_id"
            record_content="{\"content\":\"$new_content\"}"
            return=$(curl -s -X PUT  "$update_url"  -H "$output_type"  -H "$curl_param $API_KEY"  -H "$content_type" -d "$record_content")
            err=$(echo $return | jq '.[] | .code?' );
            msg=$(echo $return | jq '.[] | .message?' );
            if [ ! "$err" = ""  ]; then
                log "update error, $err : $msg"
                exit 2
            fi
        fi
		    #Get out of the While with ERR 1 mean we found the record
    done 
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
        s) spf_mode=true		;;
   # invalid options
        \?) echo "Error: Invalid options"
            exit 1;;
        esac
done

#verify if verbose mode was set by parameter ou system variable for Docker running
if [ ! $verbose_mode ]; then
    if [ "$VERBOSE" = "$(echo $VERBOSE | grep -E "^(y|Y|o|O)")" ]; then
        verbose_mode=true
        log "- verbose mode activated via sys param"
    fi
fi

#verify if verbose mode was set by parameter ou system variable for Docker running
if [ ! $spf_mode ]; then
    if [ "$SPF" = "$(echo $SPF | grep -E "^(y|Y|o|O)")" ]; then
        spf_mode=true
        log "- spf mode activated via sys param"
    fi
fi

# checks if ip was set and retrieves it if not
CheckParamIP
echo "Date : $(date +%Y-%m-%d_%H-%M)" >> /dev/stdout
echo "Updating : $DOMAIN with ip : $ip" >> /dev/stdout
# Retrieve DNS Zone Id
GetZoneId
# Retrieve Record Id and Create or Update DNS

if [ $spf_mode  ]; then
	GetRecordSpf
else
    GetRecordZone
fi
