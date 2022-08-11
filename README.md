# IonosDnsUpdater 

[![licences](https://img.shields.io/static/v1?label=based_on&message=IonosApi&color=blue)](link=https://developer.hosting.ionos.fr/docs/dns,float="left")

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
 
 API_KEY = ccc.secret           ' put the Api code and secret you have retrieve from ionos 
 DOMAIN = www.mydomain.ext      ' name of the domain/subdomain to update   
 DNS_TYPE = A                   ' DNS record type    
 TZ=Europe/Paris                ' Time zone of the container  
  
 
 License
 Distributed under the MIT License. See LICENSE for more information.
