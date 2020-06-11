FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y nano git memcached


RUN apt-get install -y build-essential openssl curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf

RUN export TRUFFLERUBY_VERSION='20.1.0' \
 && curl -L https://github.com/oracle/truffleruby/releases/download/vm-$TRUFFLERUBY_VERSION/truffleruby-$TRUFFLERUBY_VERSION-linux-amd64.tar.gz | tar xz \
 &&  export PATH="$PWD/truffleruby-$TRUFFLERUBY_VERSION-linux-amd64/bin:$PATH" \
 && $PWD/truffleruby-$TRUFFLERUBY_VERSION-linux-amd64/lib/truffle/post_install_hook.sh \
 && ruby -v

RUN echo $PATH
ENV PATH="/truffleruby-20.1.0-linux-amd64/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get install -y nano git memcached

RUN apt-get install -y build-essential openssl curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf
ENV CL_VERSION "0.01.57"
RUN git clone https://github.com/blitline-dev/commonlogs.git
RUN cd commonlogs &&  bundle install

ENV CL_VERSION "0.01.56"
RUN cd commonlogs && git pull && bundle update && bundle install
RUN memcached -d -u root
EXPOSE 4567/tcp
WORKDIR /commonlogs
ENTRYPOINT memcached -d -u root && puma -p 4567 -e prod
