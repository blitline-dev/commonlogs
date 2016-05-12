FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y -q install software-properties-common python-software-properties
RUN add-apt-repository ppa:adiscon/v8-stable
RUN apt-get update && apt-get -y -q install rsyslog wget nano vim

RUN echo "touch6"
# Recreate rsyslog.conf

RUN echo "" > /etc/rsyslog.conf
RUN echo '$RepeatedMsgReduction on' >> /etc/rsyslog.conf
RUN echo '$FileOwner syslog' >> /etc/rsyslog.conf
RUN echo '$FileGroup syslog' >> /etc/rsyslog.conf
RUN echo '$FileCreateMode 0770'  >> /etc/rsyslog.conf
RUN echo '$DirCreateMode 0770'  >> /etc/rsyslog.conf
RUN echo '$Umask 0000'  >> /etc/rsyslog.conf
RUN echo '$PrivDropToUser syslog'  >> /etc/rsyslog.conf
RUN echo '$PrivDropToGroup syslog' >> /etc/rsyslog.conf
RUN echo '$WorkDirectory /var/spool/rsyslog' >> /etc/rsyslog.conf
RUN echo '$IncludeConfig /etc/rsyslog.d/*.conf' >> /etc/rsyslog.conf


RUN mkdir '/var/log/commonlogs'
RUN chown -R :syslog /var/log/commonlogs
RUN chmod 771 -R /var/log/commonlogs

# Create commonlog.conf
RUN cd /etc/rsyslog.d && wget 'https://s3.amazonaws.com/commonlogs.install/docker/60-commonlogs.conf' -O 60-commonlogs.conf
RUN ls /etc/rsyslog.d

RUN wget 'https://s3.amazonaws.com/commonlogs.install/docker/start.sh'
RUN chmod 770 /start.sh

EXPOSE 6768/tcp 6767/udp

ENTRYPOINT ["/start.sh"]

# sudo docker run -d -p 6768:6768 -p 6767:6767 -v /var/log/commonlogs:/var/log/commonlogs commonlog_rsyslog:latest