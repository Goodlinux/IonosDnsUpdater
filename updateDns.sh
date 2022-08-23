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
    echo "Syntax updateDns.sh [-a|-e|-f|-v|-s]."
    echo "options:"
    echo "-a	change dns entry to given ip adress"
    echo "-e	show error codes"
    echo "-f	redirect verbose output to file"
    echo "-v	give verbose output"
    echo "-s    update SPF record with IP"
    echo
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
	log "Get ip from external : $ip."
	case $DNS_TYPE in
            # A Record type need ipv4 adresse
        A)
            ip=$(curl -s ifconfig.me)
            if [ "$ip" = "$(echo $ip | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ];  then
                log "Get external Ipv4 : $ip"
            else
                log "ipv4 isn't valid."
                exit 1
            fi
            ;;
            # AAAA record type need ipv6 adresse
        AAAA) 
            ip=$(curl -s https://ipv4v6.lafibre.info/ip.php)
            # test if ipv6 is valid
            if [ "$ip" = "$(echo $ip | grep  -E '^([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}')" ];  then
                log "Get external Ipv6 : $ip"
            else
                # ipv6 is not available for your connexion
                if [ "$ip" = "$(echo $ip | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ];  then
                    log "External ip is an Ipv4 : $ip setting DNS record type to A"
                    DNS_TYPE="A"
                else
                    log "external ipv6 and ipv4 isn't valid."
                    exit 1
                fi
            fi
            ;;
    esac
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
# searching for dns record if existing update it if not create it
    log "- Searching dns records."
    customer_url="$base_url$dns_zone/$zone_id?suffix=$DOMAIN&recordName=$DOMAIN&recordType=$DNS_TYPE"
    echo $customer_url
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records')
    echo $records | jq -c '.[]'  | while read record; do
        record_name=$(echo $record | jq '.name' | tr -d '"')
		#echo "name : $record_name"
        if [ "$record_name" = "$DOMAIN" ];  then
            log "Matching $record_name record found."
            record_ip=$(echo $record | jq '.content' | tr -d '"')
            if [ "$record_ip" = "$ip" ];  then
                    echo "Ip in $record_name $DNS_TYPE : $record_ip is already up to date" >> /dev/stdout
            else
                    record_id=$(echo $record | jq '.id' | tr -d '"')
                    UpdateDNSRecord
		    if [ $? = 0 ]; then 
		        echo "Record $record_name $DNS_TYPE ip updated old ip : $record_ip   New ip : $ip" >> /dev/stdout
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
	log "Updating record $record_name with Id : $record_id"
	update_url="$base_url$dns_zone/$zone_id/records/$record_id"
	record_content="{\"content\":\"$ip\"}"
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
	log "- Creating DNS Record $DOMAIN $DNS_TYPE with ip : $ip"
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
# searchin for existing spf record if it exist update it if not do nothing spf record are TXT records type
    log "- Searching spf records."
    customer_url="$base_url$dns_zone/$zone_id?suffix=$DOMAIN&recordName=$DOMAIN&recordType=TXT"
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records' | tr -d '\\' | tr -s '"')
    echo $records | jq -c '.[]'  | while read record; do
        log "Treament of record $record"
        record_content=$(echo $record | jq -c '.content' | tr -d '"')
        test=$(echo $record_content | grep -q '^v=spf1')
        if [ $? = 0 ];  then
            log "Matching spf1 record found."
            # setting new content by cuting actual content with awk and changing the ip after ip4: 
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
            # if spf record is the same do anything, else update it 
            if [ ! "$record_content" = "$new_content" ]; then 
                log "Old and new records are different, updating spf record"
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
            else
                log "Old and new record are the same no update necessary"
            fi
        fi
    done 
}

CheckParamIP() 
{
	# check if ip paraeter is valid or set
	if [ "$ip" = "" ]; then
		log "ip is not set, search for actual external ip of this network"
		GetExtIpAdress
	else
        case $DNS_TYPE in
            # A Record type need ipv4 adresse
        A) 
            if [ "$ip" = "$(echo $ip | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ];  then
                log "Ipv4 : $ip is valid."
            else
                log "ipv4 isn't valid. search for actual external ip of this network"
                GetExtIpAdress
            fi
            ;;
            # AAAA record type need ipv6 adresse
        AAAA) 
            if [ "$ip" = "$(echo $ip | grep  -E '^([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}')" ];  then
                log "Ipv6 : $ip is valid."
            else
                log "ipv6 isn't valid. search for actual external ip of this network"
                GetExtIpAdress
            fi
            ;;
        esac

	fi
}

#################
##### START #####
#################
# Get Params
echo "Date : $(date +%Y-%m-%d_%H-%M)" >> /dev/stdout
while getopts "ha:f:vs" opt; do
     case $opt in
   # display help
        h) help_mode=true;;
   # ip adress
        a) ip=$OPTARG && log "- ip in param : $ip";;
   # redirect verbose output to file
        f) redirect_mode=true && redirect_file=$OPTARG;;
   # verbose mode
        v) verbose_mode=true && log "- verbose mode activated";;
   # Update IP in SPF for mail
        s) spf_mode=true && log "- spf mode activated";;
   # invalid options
        \?) echo "Error: Invalid options"
            exit 1;;
        esac
done

# if help is asked then prin help and finish
if [ $help_mode ]; then
    Help
else
    #verify if verbose mode was set by parameter ou system variable for Docker running
    if [ ! $verbose_mode ]; then
        test=$(echo $VERBOSE | grep -q '^[y|Y|o|O]')
        if [ "$?" = "0" ]; then
            verbose_mode=true
            log "- verbose mode activated via sys param"
        fi
    fi
    
    #verify if spf mode was set by parameter ou system variable for Docker running
    if [ ! $spf_mode ]; then
        test=$(echo $SPF | grep -q '^[y|Y|o|O]')
        if [ "$?" = "0" ]; then
            spf_mode=true
            log "- spf mode activated via sys param"
        fi
    fi

    # checks if ip was set and retrieves it if not
    
    CheckParamIP
    # Retrieve DNS Zone Id
    GetZoneId
    
    # if spf is required, check existing spf TXT record and update it if it contains ip4
   if [ $spf_mode  ]; then
       echo "Updating : $DOMAIN SPF record with ip : $ip" >> /dev/stdout
       GetRecordSpf
   else
        # If it was an other Record than spf then check if the content of the record has change before updating it
       echo "Updating : $DOMAIN $DNS_TYPE record with ip : $ip" >> /dev/stdout
       GetRecordZone
   fi
fi
