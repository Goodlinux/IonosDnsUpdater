FROM alpine:latest
MAINTAINER Ludovic MAILLET <Ludoivc@maillet.me>

ENV API_KEY=xxx.yyyy  \
    DOMAIN="sub.domain.com:AAAA sub.domain2.com:SPF" \ 
    CRON_DELAY=*/5   \ 
    VERBOSE=n  \ 
    LOG_SRV=192.168.0.33 \ 
    BOX_IP=192.168.0.1   \ 
    BOX_USER=admin   \ 
    BOX_PASSWORD=xxxx   \ 
    TZ=Europe/Paris

RUN apk -U upgrade && apk add curl apk-cron tzdata jq nano \ 
  && cd /usr/local/bin/ && curl -O https://raw.githubusercontent.com/Goodlinux/IonosDnsUpdater/master/updateDns.sh \
  && cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \ 
  && echo "apk -U upgrade "                                                               > /usr/local/bin/updtPkg.sh \ 
  && echo "cd /usr/local/bin/"                                                            >> /usr/local/bin/updtPkg.sh \  
  && echo "curl -s -O https://raw.githubusercontent.com/Goodlinux/IonosDnsUpdater/master/updateDns.sh" >> /usr/local/bin/updtPkg.sh \
  && echo "chmod a+x /usr/local/bin/*"                                                    >> /usr/local/bin/updtPkg.sh \
  && echo "#! /bin/sh"                                                                     > /usr/local/bin/entrypoint.sh \
  && echo "echo 'Mise à jour ...'"                                                         >> /usr/local/bin/entrypoint.sh  \
  && echo "apk -U upgrade "                                                                >> /usr/local/bin/entrypoint.sh  \
  && echo "cd /usr/local/bin/"                                                             >> /usr/local/bin/entrypoint.sh \
  && echo "curl -s -O https://raw.githubusercontent.com/Goodlinux/IonosDnsUpdater/master/updateDns.sh"  >> /usr/local/bin/entrypoint.sh  \
  && echo "echo 'Update CronTab with Param '\$CRON_DELAY'...'"                                           >> /usr/local/bin/entrypoint.sh  \
  && echo "echo \$CRON_DELAY'     *       *       *       *       /usr/local/bin/updateDns.sh \$PARAMS' > /etc/crontabs/root"  >> /usr/local/bin/entrypoint.sh  \
  && echo "echo '00     1       *       *       sun       /usr/local/bin/updtPkg.sh'     >> /etc/crontabs/root"      >> /usr/local/bin/entrypoint.sh  \
  && echo "echo 'lancement de cron ...'"                                                   >> /usr/local/bin/entrypoint.sh  \
  && echo "crond -f"                                                                      >> /usr/local/bin/entrypoint.sh  \
  && chmod a+x /usr/local/bin/*
# Lancement du daemon cron
CMD /usr/local/bin/entrypoint.sh
