# IonosDnsUpdater 

[![ionos](https://img.shields.io/static/v1?label=based_on&message=IonosApi&color=blue)](link=https://developer.hosting.ionos.fr/docs/dns,float="left")
 [![alpine](https://img.shields.io/static/v1?label=using&message=alpine&color=orange)](https://alpinelinux.org)

DSN Update for dns provider ionos, looks like a DynDSN 
running in a docker container
docker image available : 

[![docker](https://img.shields.io/static/v1?label=docker&message=dockerhub&color=green)](https://registry.hub.docker.com/r/goodlinux/ionosdnsupdater)

 
# Getting Started
 Prerequisites
 Get an API Key at IONOS API Docs
 https://developer.hosting.ionos.fr/docs/getstarted
 
 
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
  
 License
 Distributed under the MIT License. See LICENSE for more information.
