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

content_type_box="Content-Type: application/x-sah-ws-4-call+json"
authorisation="Authorization: X-Sah "
login="Authorization: X-Sah-Login"

context="/var/tmp/livebox_context"
cookie="/var/tmp/livebox_cookies"
rm /var/tmp/livebox*

ipv4=""
ipv6=""

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

##########################################
### log information on log server      ###
### $1 = log level name                ###
### valid values are : emerg alert     ###
### crit err warning notice info debug ###
### $2 : message to log                ###
##########################################
logNas()
{
if [ -e /usr/bin/logger ]; then
	logger -n $LOG_SRV -p user.$1 -t "$HOSTNAME" -s "$2"
else
	echo "$2" >> /dev/stdout
fi
}

GetIpFromBox()
{
	log "Get IP from $BOX_IP."
	# get authorization	
	curl -s -o $context -k "http://"$BOX_IP"/ws" -c $cookie -X POST --compressed -H "$login" -H "$content_type_box" --data-raw '{"service":"sah.Device.Information","method":"createContext","parameters":{"applicationName":"webui","username":"'$BOX_USER'","password":"'$BOX_PASSWORD'"}}'
	# set authorization context ID
	CTX=$(cat $context | jq -c .data.contextID | tr -d '"')
	GRP=$(cat $context | jq -c .data.groups)
	IE=$CTX'","username":"'$BOX_USER'","groups":'$GRP'}}'
	ID2=$(tail -n1 $cookie | sed 's/#HttpOnly_'$BOX_IP'\tFALSE\t[/]\tFALSE\t0\t//1' | sed 's/sessid\t/sessid=/1')
#	log "IE : $IE"
#	log "ID2 : $ID2"
	res=$(curl -s -k "http://"$BOX_IP"/ws" -X POST -H "$content_type_box" -H "$authorisation"$IE  -H "Cookie: "$ID2 --data-raw '{"service":"NMC","method":"getWANStatus","parameters":{}}')
#	log "res : $res"
	ipv4=$(echo $res | jq -c .data.IPAddress | tr -d '"')
	ipv6=$(echo $res | jq -c .data.IPv6Address | tr -d '"')
}


GetIpFromExt()
{
	log "Get Ip from external provider" 
    ipv4=$(curl -s ifconfig.me)
    ipv6=$(curl -s https://ipv4v6.lafibre.info/ip.php)
}


GetExtIpAdress() 
{
    log "------------------"
	if [ "$BOX_IP" = "$(echo $BOX_IP | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ] && [ -n $BOX_IP ] ; then
		GetIpFromBox
	fi

    if [ "$ipv4" = "$(echo $ipv4 | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ] && [ -n $ipv4 ] ;  then
		log "Ipv4 from Box : $ipv4"

	else
		# try to get IP from externl source
		GetIpFromExt
	fi

    log "ipv4 : $ipv4"
	log "ipv6 : $ipv6"
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
           		logNas "info" "Ip in $record_name $dnsType : $record_ip is already up to date"
        	else
          		record_id=$(echo $record | jq '.id' | tr -d '"')
            		UpdateDNSRecord
			if [ $? = 0 ]; then 
		    		logNas "info" "Record $record_name $dnsType ip updated old ip : $record_ip   New ip : $ip"
			fi
    		fi
		    #Get out of the While with ERR 1 mean we found the record
			exit 1
			break
		fi
    done 
    if [ ! $? = 1 ]; then
	    logNas "info" "Enregistrement non trouvé"
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
		logNas "warning" "update error, $err : $msg"
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
		logNas "info" "Creating DNS Record $domainName $dnsType with ip : $ip successfull"
	else
		logNas "warning" "DNS Record $domainName $dnsType creation error, $err : $msg"
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
            for string in ${record_content}; do
            	case $string in
            		$(echo $string | grep '^v=spf1'))
            			new_content="v=spf1"
            		;;
            		$(echo $string | grep '^ip4:')) 
            			new_content="$new_content ip4:$ipv4"
            		;;
            		$(echo $string | grep '^ip6:'))
            			new_content="$new_content ip6:$ipv6"
            		;;
            		*)
            			new_content="$new_content $string"
            			;;
            	esac
            	#log "SPF record construction str : $string : new record : $new_content"
            done
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
                    logNas "warning" "SPF Record for $domainName Record Id :  $record_id update error, $err : $msg"
                    exit 2
                else
                	logNas "info" "$domainName SPF Record updated"
                fi
            else
                logNas "info" "$domainName SPF record is up to date no update necessary"
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

ProcessDnsUpdate()
{
		# Get Zone Id to update all records
		GetZoneId
    	
		#Proccessing Records update
		for record in ${DOMAIN}; do            
			# DOMAIN Variable should be formated domain="my.domain.net:A test.domain.net:AAAA domain.net:SPF"
			domainName=$(echo $record | cut -d ':' -f 1)
			dnsType=$(echo $record | cut -d ':' -f 2)
			echo "=============================================="
			echo "Update of Domain : $domainName Type : $dnsType"
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
					if [ "$ip" = "$(echo $ip | grep  -E '^([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}')" ] && [ -n $ipv6 ] ;  then
						GetRecordZone
						log "record zone AAAA with ip : $ip"
					else
						lognas "warning" "IPV6 not found, cannot update AAAA record"
						exit 1
					fi
					;;
				SPF)        
					# if spf is required, check existing spf TXT record and update it if it contains ip4
					# ip=$ipv4 able to update ipv4 and ipv6 in TXT spf record
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
					lognas "err" "$dnsType is an invalid record type"
					;;
			esac
		done	
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
        h) 	Help
			exit 0;;
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
			Help
			exit 1;;
        esac
done

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
    
if [ "$ipv4" = "$(echo $ipv4 | grep -E '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.|$)){4}$')" ] && [ -n $ipv4 ] ; then
  	# try to get IP from externl source
  	log "IPv4 Ok Processing"
   	ProcessDnsUpdate
elif [ "$ipv6" =  "$(echo $ipv6 | grep  -E '^([a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}')" ] && [ -n $ipv6 ] ; then
	log "Ipv6 Ok Processing"
	ProcessDnsUpdate
else
	logNas "warning" "no ip available, nothing to update"
fi
