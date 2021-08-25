FROM flavorjones/truffleruby:buster-slim
RUN apt-get update
RUN apt-get install -y nano git memcached
RUN gem install bundler -v 1.17.3

RUN apt-get install -y build-essential openssl curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf
ENV VERSION "0.0.1"
RUN git clone https://github.com/blitline-dev/commonlogs.git
RUN cd commonlogs &&  bundle update && bundle install

ENV CL_VERSION "0.01.58"
RUN cd commonlogs && git pull --force && bundle update && bundle install
RUN memcached -d -u root
EXPOSE 4567/tcp
WORKDIR /commonlogs
ENTRYPOINT memcached -d -u root && bundle exec rackup -p 4567

