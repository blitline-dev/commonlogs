FROM crystallang/crystal:latest

RUN apt-get update
RUN apt-get install -y nano

RUN mkdir '/var/log/commonlogs'
RUN chmod 771 -R /var/log/commonlogs

RUN apt-get update
RUN apt-get install -y crystal
RUN apt-get install -y wget socat nano tcpdump

ENV CL_VERSION="1.01.18"

RUN git clone https://github.com/blitline-dev/crystal_syslog_server.git
RUN cd crystal_syslog_server/src && crystal build --release main.cr -o server

WORKDIR crystal_syslog_server/src


# sudo docker run -d -p 6768:6768 -v /var/log/commonlogs:/var/log/commonlogs commonlogs/commonlogs_crystal:latest crystal main.cr

