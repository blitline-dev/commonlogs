FROM crystallang/crystal

RUN apt-get update
RUn apt-get install -y nano

RUN mkdir '/var/log/commonlogs'
RUN chown -R :syslog /var/log/commonlogs
RUN chmod 771 -R /var/log/commonlogs
RUN echo "touchr12"

RUN git clone https://github.com/blitline-dev/crystal_syslog_server.git
WORKDIR crystal_syslog_server/src
EXPOSE 6768/tcp 6767/udp

# sudo docker run -d -p 6768:6768 -p 6767:6767 -v /var/log/commonlogs:/var/log/commonlogs commonlog_crystal:latest
