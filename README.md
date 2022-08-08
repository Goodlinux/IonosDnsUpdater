# IonosDnsUpdater
Update DNS by API in Shell
# DnsUpdater 
[![domainconnect](https://img.shields.io/static/v1?label=based_on&message=DomainConnectDDNS-Python&color=blue)](link=https://github.com/Domain-Connect/DomainConnectDDNS-Python,float="left")

DSN Update for dns provider like ionos, looks like a DynDSN 

Take your local IP and send it to ionos if it has changed 
Contenair Docker to periodcaly update the IP adress of my DNS hosted in Ionos 
Modifiez la variable d'environnement DOMAIN pour qu'elle colle à votre Nom de domaine à mettre à jour Modifiez la variable  
TZ pour qu'elle colle avotre Timezone 

Vous pouvez aussi mofifier le declenchement de la verification et mise a jour via la commande crontab du script (par default 5 minutes) 
Aprés avoir lancé le conteneur il faut aller un terminal pour valider le lien avec votre domaine. lancer le script "setupDomain" 
autre option lancer la commande suivante 
domain-connect-dyndns setup --domain xx.votredomaine.com 
et suivez les instructions 

Pour construire l'image Docker, télécharger le fichier DockerFile dans un dossier, placez vous dans le dossier et lancer la commande 
docker build -t NomDeVotreConteneur --no-cache --force-rm . 
Vous pouvez aussi télécharger l'image depuis le Docker Hub : 

[![docker](https://img.shields.io/static/v1?label=docker&message=Image_Docker_zipsme&color=green)](link=https://hub.docker.com/r/goodlinux/dnsupdater,float="left")

 
[![docker](https://img.shields.io/static/v1?label=docker&message=Image_Docker_zipsme&color=green)](link=https://hub.docker.com/r/goodlinux/dnsupdater,float="left")


 IONOS DNS Record Updater
 About the Project
 Since IONOS made an API available to manage your domains and I needed to change my records regularly I decided to create an automated dns record updater.

 Getting Started
 Prerequisites
 apt install curl jq
 Installation
 Get an API Key at IONOS API Docs
 Clone the repo
 git clone https://github.com/888iee/ionos_dns_record_updater.git
 cd into directory
 cd ionos_dns_record_updater
 Create a .env File
 touch .env
 Paste your key and values in
 api_key="prefix.encryptionkey"
 domain="my.domain.com"
 dns_type="A"
 Usage
 You can run the updater script with following commands.

 chmod +x updater.sh
 ./updater 
 # or set ip initally and don't retrieve ip automatically 
 ./updater -a 127.0.0.1
 # for more information
 ./updater -h
 Disclaimer
 Only IPv4 Adress was tested. 

 License
 Distributed under the MIT License. See LICENSE for more information.
