# IonosDnsUpdater 

[![ionos](https://img.shields.io/static/v1?label=based_on&message=IonosApi&color=blue)](link=https://developer.hosting.ionos.fr/docs/dns,float="left")
 [![alpine](https://img.shields.io/static/v1?label=using&message=alpine&color=orange)](https://alpinelinux.org)

DSN Update for dns provider ionos, looks like a DynDSN 
This program aims is to update ip adresse for IONOS domains.

running in a docker container or stand alone on linux system
docker image available : 

[![docker](https://img.shields.io/static/v1?label=docker&message=dockerhub&color=green)](https://registry.hub.docker.com/r/goodlinux/ionosdnsupdater)

# WHAT THE PROGRAM DO
 
Calculating new IP by taking into acount the -a 1.2.3.4 parameter or if -a parameter is not set not set search actual external ip of the network running the programm.

if the record name in param DOMAIN and DNS_TYPE exist,  
change the entire content of the record by the new ip, only if the content is different. 
if the record do not exist, create it. 

If the parameter -s or SPF system variable for docker is set 
then the program search for a TXT spf record and update the new ip if the ip in the actual spf record has change.
If the record is not found do nothing
 
# GETTING STARTED
 
 Prerequisites
 Get an API Key at IONOS API Docs
 https://developer.hosting.ionos.fr/docs/getstarted
 
# PARAMETERS ARE
 
 Syntax updateDns.sh [-a|-e|-f|-v|-s]."  
   options:   
    -a	change dns entry to given ip adress"  
    -e	show error codes"  
    -f	redirect verbose output to file"  
    -v	give verbose output"  
    -s update SPF record with IP"  
 

# ENV VARIABLES FOR DOCKER CONTAINER  
 
 API_KEY =  put the Api code and secret you have retrieve from ionos  ex : ccc.secret   
 DOMAIN =   name of the domain/subdomain to update   ex : xxx.mydomain.ext  
 DNS_TYPE = DNS record type  ex : A  
 CRON_DELAY = Delay to start the DNS update via cron  ex : */5  for each 5 minutes
 SPF = Indicate that you want to update a SPF TXT record and set the Ip in it to the current one : ex : y if you want SPF
 PARAMS = send the parameters to the script ex : -v -s   
 VERBOSE = indicate that you want to run with verbose mode : ex : y if you want to have more detail on the run
 TZ =       Time zone of the container     ex : Europe/Paris  
  
 Only working with IP v4
 Make test before production, I could not be responsible for the usage of this piece of code.
 Be sure of what you are doing, by updating your DNS records. 
 
 License
 Distributed under the MIT License. See LICENSE for more information.
