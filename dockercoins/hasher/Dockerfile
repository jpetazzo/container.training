FROM ruby:alpine
RUN apk add --update build-base curl
RUN gem install sinatra --version '~> 3'
RUN gem install thin
RUN gem install yaml
RUN gem install prometheus-client
ADD hasher.rb /
CMD ["ruby", "hasher.rb"]
