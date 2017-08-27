FROM crystallang/crystal:latest

RUN apt-get update
RUn apt-get install -y nano

RUN mkdir '/var/log/commonlogs'
RUN chown -R :syslog /var/log/commonlogs
RUN chmod 771 -R /var/log/commonlogs

RUN sudo apt-get update
RUN sudo apt-get install -y crystal
RUN sudo apt-get install -y wget socat nano tcpdump

ENV CL_VERSION="1.00.82"

RUN git clone https://github.com/blitline-dev/crystal_syslog_server.git
RUN cd crystal_syslog_server/src && crystal compile --release main.cr -o server

WORKDIR crystal_syslog_server/src


# sudo docker run -d -p 6768:6768 -v /var/log/commonlogs:/var/log/commonlogs commonlogs/commonlogs_crystal:latest crystal main.cr

