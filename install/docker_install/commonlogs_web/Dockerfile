FROM ubuntu:16.04
RUN apt-get update
RUN apt-get install locales

RUN echo "LANG=\"en_US.UTF-8\"" > /etc/default/locale
RUN locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8


RUN apt-get install -y nano git memcached
RUN apt-get install -y build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool 

RUN \
  apt-get update && \
  apt-get install -y ruby ruby-dev ruby-bundler && \
  rm -rf /var/lib/apt/lists/*


RUN git clone https://github.com/blitline-dev/commonlogs.git
RUN cd commonlogs && bundle install

ENV CL_VERSION "0.01.44"
RUN cd commonlogs && git pull && bundle install
RUN memcached -d -u root
RUN ps ax
EXPOSE 4567/tcp
WORKDIR /commonlogs
ENTRYPOINT memcached -d -u root && puma -p 4567 -e prod
