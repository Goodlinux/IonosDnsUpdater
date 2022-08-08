FROM alpine:latest
MAINTAINER Ludovic MAILLET <Ludo.goodlinux@gmail.com>

ENV DOMAIN=my.dns.com \ 
    CRONDELAY=*/5   \
    CONFFILE=/root/domain-settings   \
    TZ=Europe/Paris
    
EXPOSE 22

RUN apk -U add gcc musl-dev python3-dev libffi-dev openssl-dev cargo py3-pip curl apk-cron tzdata openssh \ 
  && pip install pip wheel --upgrade\
  && pip install cryptography \
  && pip install domain-connect-dyndns \
  && cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >  /etc/timezone \ 
  && echo 'apk -U upgrade'                                                                                                      > /usr/local/bin/updtPkg \ 
  && echo 'IPFILE=/var/local/currentip' 		                                                                                > /usr/local/bin/chkip    \
  && echo 'NEW_IP=$(curl -s ifconfig.me)' 		                                                                                      >> /usr/local/bin/chkip    \
  && echo 'CUR_IP=$(cat /var/local/currentip)' 	                                                                                      >> /usr/local/bin/chkip    \
  && echo 'if [ "$NEW_IP" != "$CUR_IP" ]; then' 	                                                                                  >> /usr/local/bin/chkip    \
  && echo '        echo $(date) " ==> $NEW_IP mise à jour demandée" > /dev/stdout'                                                    >> /usr/local/bin/chkip    \
  && echo '        domain-connect-dyndns update --all --config $CONFFILE > /dev/stdout'                                               >> /usr/local/bin/chkip    \
  && echo '        if [ "$?" == "0" ]; then'                                                                                          >> /usr/local/bin/chkip    \  
  && echo '             curl -s ifconfig.me > $IPFILE'                                                                                >> /usr/local/bin/chkip    \
  && echo '        fi' 								                                                                              >> /usr/local/bin/chkip    \  
  && echo 'else' 								                                                                                      >> /usr/local/bin/chkip    \
  && echo '        echo $(date) " ==> IP : $CUR_IP pas de mise à jour" > /dev/stdout'                                                 >> /usr/local/bin/chkip    \
  && echo 'fi' 									                                                                                      >> /usr/local/bin/chkip    \
  && echo 'domain-connect-dyndns setup --domain \$DOMAIN --config \$CONFFILE > /dev/stdout'                                     > /usr/local/bin/domainSetup.sh    \
  && echo $CRONDELAY'     *       *       *       *       /usr/local/bin/chkip'                                                 > /etc/crontabs/root \
  && echo '00     1       *       *       sun       /usr/local/bin/updtPkg'                                                           >> /etc/crontabs/root \  
  && echo "#! /bin/sh"                                                                                                          > /usr/local/bin/entrypoint.sh \
  && echo "echo 'nameserver      1.1.1.1' > /etc/resolv.conf"                                                                         >> /usr/local/bin/entrypoint.sh \
  && echo "echo 'nameserver      1.0.0.1' >> /etc/resolv.conf"                                                                        >> /usr/local/bin/entrypoint.sh \
  && echo "echo 'nameserver      8.8.8.8' >> /etc/resolv.conf"                                                                        >> /usr/local/bin/entrypoint.sh \  
  && echo "if [ ! -e  \$CONFFILE ]; then  "                                                                                           >> /usr/local/bin/entrypoint.sh  \ 
  && echo "        echo 'Config file $CONFFILE does not exist you can launch in a terminal the folowing command : domainSetup.sh ' > /dev/stdout"   >> /usr/local/bin/entrypoint.sh  \ 
  && echo "        echo 'and the restart the container. Or you can copy past following commands from container log' > /dev/stdout"                  >> /usr/local/bin/entrypoint.sh  \ 
  && echo "        domain-connect-dyndns setup --domain \$DOMAIN --config \$CONFFILE > /dev/stdout"                                                >> /usr/local/bin/entrypoint.sh  \
  && echo "fi "                                                                                                                       >> /usr/local/bin/entrypoint.sh  \
  && echo "crond -b "                                                                                                                 >> /usr/local/bin/entrypoint.sh  \
  && echo "sshd "                                                                                                                 >> /usr/local/bin/entrypoint.sh  \
  && echo "/bin/sh "                                                                                                                  >> /usr/local/bin/entrypoint.sh  \
  && chmod a+x /usr/local/bin/*
# Lancement du daemon cron
CMD /usr/local/bin/entrypoint.sh
#CMD /bin/sh
