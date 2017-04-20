FROM ruby:2.4.1

ENV TERM xterm

RUN apt-get update \
	&& apt-get -y install wget memcached build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev \
	&& apt-get -y install libcurl4-openssl-dev curl git-core python-software-properties  \
	&& apt-get -y install openssl libreadline6 libreadline6-dev curl git-core zlib1g libsqlite3-dev sqlite3 libxml2-dev libxslt-dev \
        && apt-get -y install libc6-dev ncurses-dev automake libtool subversion awscli nano
# Increase memcache size
RUN sed -i 's/-m 64/-m 512/g' /etc/memcached.conf

RUN echo "touch80"
RUN git clone https://github.com/blitline-dev/commonlogs.git
RUN cd commonlogs && bundle install

ENV CL_VERSION "0.01.15"
RUN cd commonlogs && git pull && bundle install

EXPOSE 4567/tcp
WORKDIR /commonlogs
#ENTRYPOINT exec puma -p 4567 -e development 
