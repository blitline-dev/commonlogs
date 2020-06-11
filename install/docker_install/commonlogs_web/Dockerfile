FROM quay.io/evl.ms/fullstaq-ruby:2.6.6-jemalloc-buster-slim

RUN apt-get update
RUN apt-get install -y nano git memcached


RUN apt-get install -y build-essential openssl curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf
RUN git clone https://github.com/blitline-dev/commonlogs.git
RUN cd commonlogs &&  bundle update && bundle install

ENV CL_VERSION "0.01.56"
RUN cd commonlogs && git pull && bundle update && bundle install
RUN memcached -d -u root
EXPOSE 4567/tcp
WORKDIR /commonlogs
ENTRYPOINT memcached -d -u root && puma -p 4567 -e prod
