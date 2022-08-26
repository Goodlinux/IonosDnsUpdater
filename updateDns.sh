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
    echo "Syntax updateDns.sh [-a|-e|-f|-v]."
    echo "using sys variable DOMAIN that should be formated as 'domainname1:dsntype1 domainname2:dnstype2' separated by spaces"
    echo "ex : DOMAIN=\"my.domain.net:A test.domain.net:AAAA domain.net:SPF\""
    echo "options:"
    echo "-a	change dns entry to given ip adress or text for MX, CNAME SRV or TXT records"
    echo "-f	redirect verbose output to file"
    echo "-v	give verbose output"
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
    log "------------------"
	log "Get ip from external : $ip."
	# Try to get IP from local LiveBox from Orange
	if [ "$BOX_IP" = "$(echo $BOX_IP | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ]; then
        log "Try to get Ip from Box"
		ipv4=$(curl -s -X POST -H "$content_type" -d '{"parameters":{}}'  http://$BOX_IP/sysbus/NMC:getWANStatus | jq -c .result.data.IPAddress | tr -d '"')
		ipv6=$(curl -s -X POST -H "$content_type" -d '{"parameters":{}}'  http://$BOX_IP/sysbus/NMC:getWANStatus | jq -c .result.data.IPv6Address | tr -d '"')
		log "Box ipv4 : $ipv4"
		log "Box ipv6 : $ipv6"
    else    # try to get IP from externl source
        ipv4=$(curl -s ifconfig.me)
        ipv6=$(curl -s https://ipv4v6.lafibre.info/ip.php)
        if [ "$ipv6" = "$(echo $ipv6 | grep  -E '^([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}')" ];  then  # test if retrieve ip is ipv6
            log "Get external Ipv6 : $ipv6"
        else
           	log "ipv6 isn't valid."
           	ipv6=""
        fi
    fi
}

GetZoneId() 
{
#Get zone Id for the Domain
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
    customer_url="$base_url$dns_zone/$zone_id?suffix=$domainName&recordName=$domainName&recordType=$dnsType"
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records')
    echo $records | jq -c '.[]'  | while read record; do
        record_name=$(echo $record | jq '.name' | tr -d '"')
		#echo "name : $record_name"
        if [ "$record_name" = "$domainName" ];  then
            log "Matching $record_name record found."
            record_ip=$(echo $record | jq '.content' | tr -d '"')
            if [ "$record_ip" = "$ip" ];  then
                    echo "Ip in $record_name $dnsType : $record_ip is already up to date" >> /dev/stdout
            else
                    record_id=$(echo $record | jq '.id' | tr -d '"')
                    UpdateDNSRecord
		    if [ $? = 0 ]; then 
		        echo "Record $record_name $dnsType ip updated old ip : $record_ip   New ip : $ip" >> /dev/stdout
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
	log "- Creating DNS Record $domainName $dnsType with ip : $ip"
	create_url="$base_url$dns_zone/$zone_id/records"
	record_content="[{\"name\":\"$domainName\",\"type\":\"$dnsType\",\"content\":\"$ip\",\"ttl\":60,\"prio\":0,\"disabled\":false}]"
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
# searchin for existing spf record if it exist update it if not do nothing 
# note that spf record are TXT records type
    log "- Searching spf records."
    customer_url="$base_url$dns_zone/$zone_id?suffix=$domainName&recordName=$domainName&recordType=$dnsType"
    records=$(curl -X GET $customer_url -H $output_type -H "$curl_param $API_KEY" -s | jq '.records' | tr -d '\\' | tr -s '"')
    echo $records | jq -c '.[]'  | while read record; do
        record_content=$(echo $record | jq -c '.content' | tr -d '"')
        # chearch for string v=spf1 in record content
        test=$(echo $record_content | grep -q '^v=spf1')
        if [ $? = 0 ];  then
            log "Matching spf1 record found."
            # setting new content by cuting actual content with awk and changing the ip after ip4: by the new one
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
                else
                	echo "SPF Record updated"
                fi
            else
                echo "SPF record is up to date no update necessary"
            fi
        fi
    done 
}

CheckParamIP() 
{
	# check if ip paraeter is valid or set
	log "------------------------------"
	log "verifying ip settings"
	if [ "$ip" = "" ]; then
		log "ip is not set by parameter, search for actual external ip of this network"
		GetExtIpAdress
	else
        if [ "$ip" = "$(echo $ip | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ];  then
                log "Ipv4 : $ip is valid."
                ipv4=$ip
            else
                if [ "$ip" = "$(echo $ip | grep  -E '^([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}')" ];  then
                    log "Ipv6 : $ip is valid."
                    ipv6=$ip
                else
                    log "ipv in param isn't valid. search for actual external ip of this network"
                    GetExtIpAdress
                fi
                
        fi
    fi
}

#################
##### START #####
#################
# Get Params
echo "*=*=**=*==*=*="
echo "Date : $(date +%Y-%m-%d_%H-%M)"
while getopts "ha:f:v" opt; do
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
#        s) spf_mode=true && log "- spf mode activated";;
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
    
    # checks if ip was set and retrieves it if not
    CheckParamIP
    # Retrieve DNS Zone Id
    GetZoneId
    
    for record in ${DOMAIN}; do            # DOMAIN Variable should be formated domain="my.domain.net:A test.domain.net:AAAA domain.net:SPF"
        domainName=$(echo $record | cut -d ':' -f 1)
        dnsType=$(echo $record | cut -d ':' -f 2)
        log "=============================================="
        log "Update of Domain : $domainName Type : $dnsType"
        case "$dnsType" in
            A)          
                # A and SPF Record type need ipv4 adresse
                ip=$ipv4
                log "ip : $ip"
                GetRecordZone
                ;;
            AAAA)       
                # AAAA record type need ipv6 adresse
                ip=$ipv6
                echo "ip : $ip"
                if [ "$ip" = "$(echo $ip | grep  -E '^([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}')" ];  then
                    GetRecordZone
                    log "record zone AAAA with ip : $ip"
                else
                    echo "IPV6 not find, cannot update record"
                    exit 1
                fi
                ;;
            SPF)        
                # if spf is required, check existing spf TXT record and update it if it contains ip4
                ip=$ipv4
                dnsType=TXT
                GetRecordSpf
                ;;
            TXT | CNAME | MX | SRV)  
                # for other record type get text from -a parameter
                if [ "$ip" = "" ]; then 
                    log "for record $dnsTyype need to have the -a param set"
                else
                    log "$dns_Type records updating with $ip text value"
                    GetRecordZone
                fi
                ;;
            *) 
                echo "Error: Invalid record type"
                ;;
        esac
    done
fi
