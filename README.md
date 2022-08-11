# IonosDnsUpdater 

[![licences](https://img.shields.io/static/v1?label=based_on&message=IonosApi&color=blue)](link=https://developer.hosting.ionos.fr/docs/dns,float="left")

[![git](https://img.shields.io/static/v1?label=based_on&message=zipsme&color=blue)](https://github.com/zipsme/zipsme)

DSN Update for dns provider ionos, looks like a DynDSN 
running in a docker container
docker image available :
[![docker](https://img.shields.io/static/v1?label=docker&message=Image_Docker_IonosDnsUpdater&color=green)](link=https://https://registry.hub.docker.com/r/goodlinux/ionosdnsupdater/,float="left")


 IONOS DNS Record Updater
 About the Project
 
 The script take into account certain parameter
 
# Getting Started
 Prerequisites
 Get an API Key at IONOS API Docs
 https://developer.hosting.ionos.fr/docs/getstarted
 
 
# ENV VARIABLES  
 
 API_KEY = ccc.secret          ' put the Api code and secret you have retrieve from ionos  
 DOMAIN = www.mydomain.ext     ' name of the domain/subdomain to update  
 DNS_TYPE = A                  ' DNS record type   
 TZ=Europe/Paris               ' Time zone of the container
  
 
 License
 Distributed under the MIT License. See LICENSE for more information.
