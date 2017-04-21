FROM ruby:2.4.1-alpine

	
# Increase memcache size
#RUN sed -i 's/-m 64/-m 512/g' /etc/memcached.conf

RUN echo "touch81"
RUN apk update
RUN apk add git
RUN apk add --update alpine-sdk
RUN git clone https://github.com/blitline-dev/commonlogs.git
RUN cd commonlogs && bundle install

ENV CL_VERSION "0.01.17"
RUN cd commonlogs && git pull && bundle install

EXPOSE 4567/tcp
WORKDIR /commonlogs
#ENTRYPOINT exec puma -p 4567 -e development 
