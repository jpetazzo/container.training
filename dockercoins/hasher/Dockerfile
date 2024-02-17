FROM ruby:alpine
RUN apk add --update build-base curl
RUN gem install sinatra --version '~> 3'
RUN gem install thin
ADD hasher.rb /
CMD ["ruby", "hasher.rb"]
EXPOSE 80
