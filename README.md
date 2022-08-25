# IonosDnsUpdater 

[![ionos](https://img.shields.io/static/v1?label=based_on&message=IonosApi&color=blue)](link=https://developer.hosting.ionos.fr/docs/dns,float="left")
 [![alpine](https://img.shields.io/static/v1?label=using&message=alpine&color=orange)](https://alpinelinux.org)

Update Ionos domain records to update the current public ip

DSN Update for dns provider ionos, looks like a DynDSN 
This program aims is to update ip adresse for IONOS domains.
It works for 
 - A DNS records with ipv4
 - AAAA DNS records type with ipv6
 - SPF TXT DNS Record that are SPF with ip inside (SPF records are TXT records for mail server purpose)
 - CNAME DNS records (in this case use the -a param and set the name you want in place of ip  ex : updateDn.sh -a dns.ionos.fr)
 - SRV DNS records (in this case use the -a param and set the name you want in place of ip  ex : updateDn.sh -a '0 443 srv.ionos.fr')
 - MX DNS records (in this case use the -a param and set the name you want in place of ip  ex : updateDn.sh -a mx00.ionos.fr)
 - TXT DNS records (in this case use the -a param and set the name you want in place of ip  ex : updateDn.sh -a 'v=DMARC1; p=none')

running in a docker container or stand alone on linux system  
docker image available : 
[![docker](https://img.shields.io/static/v1?label=docker&message=dockerhub&color=green)](https://registry.hub.docker.com/r/goodlinux/ionosdnsupdater)

# WHAT THE PROGRAM DO
 
Calculating new IP by taking into acount the -a 1.2.3.4 parameter 
or if -a parameter is not set not set search actual external ip of the network 
with searching the external ip (ipv4 and ipv6) from Livebox from Orange.
If Livebox is not present, search external ip with service provider [ifconfig.me](http://ifconfig.me/) for ipv4 
or [ipv4v6.lafibre.info](https://ipv4v6.lafibre.info/) for ipv6

if the record name in param DOMAIN and DNS_TYPE exist,  
change the entire content of the record by the new ip, only if the content is different. 
if the record do not exist, create it. 

If the record type is SPF  
then the program search for a TXT spf record and update it with 
the new ip if the ip in the actual spf record has change.
If the record is not found do nothing
 
# GETTING STARTED
 
 Prerequisites
 Get an API Key at IONOS API Docs
 https://developer.hosting.ionos.fr/docs/getstarted
 
# PARAMETERS ARE
 
 Syntax updateDns.sh [-a|-e|-f|-v|-s].  
   options: 
   |param|extention|effect|
   |-------|-----------|----|
   |-a  |1.2.3.4 |change dns entry to given ip adress  |
   |-e  | |show error codes  |
   |-f  |filename |redirect verbose output to file  |
   |-v  | |give verbose output  |
      

 If you don't use the script in a docker container, 
 Add the variables **DOMAIN**, **DNS_TYPE** and **API_KEY** at the top of the script


# ENV VARIABLES FOR DOCKER CONTAINER  
 
 > - **API_KEY** =  put the Api code and secret you have retrieve from ionos  ex : ccc.secret   
 > - **DOMAIN** =   name of the domain/subdomain to update   ex : xxx.mydomain.ext  
 > - **DNS_TYPE** = DNS record type  ex : A, AAAA, or SPF to update a SPF TXT record   
 > - **CRON_DELAY** = Delay to start the DNS update via cron  ex : */5  for each 5 minutes 
 > - **PARAMS** = send the parameters to the script ex : -v -s (optional)   
 > - **VERBOSE** = indicate that you want to run with verbose mode : ex : y if you want to have more detail on the run 
 > - **BOX_IP** = local ip of the livebox to be able to catch ipv4 and ipv6 external ip (optional)   
 > - **TZ** =       Time zone of the container     ex : Europe/Paris   
  
 Working with IPv4 or IpV6  
 Make test before using it in real production, I could not be taken responsible for the usage of this piece of code.  
 Be sure of what you are doing, when updating your DNS records.  
 
 License
 Distributed under the MIT License. See LICENSE for more information.
