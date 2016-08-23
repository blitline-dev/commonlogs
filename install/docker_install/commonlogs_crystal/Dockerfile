FROM crystallang/crystal

RUN apt-get update
RUn apt-get install -y nano

RUN mkdir '/var/log/commonlogs'
RUN chown -R :syslog /var/log/commonlogs
RUN chmod 771 -R /var/log/commonlogs
RUN echo "touch19"

RUN git clone https://github.com/blitline-dev/crystal_syslog_server.git
WORKDIR crystal_syslog_server/src
EXPOSE 6768/tcp

# sudo docker run -d -p 6768:6768 -v /var/log/commonlogs:/var/log/commonlogs commonlogs/commonlogs_crystal:latest crystal main.cr

