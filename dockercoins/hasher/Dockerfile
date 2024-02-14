FROM ruby:alpine
RUN apk add --update build-base curl
RUN gem install bundler
ADD Gemfile* /
RUN bundle install
ADD hasher.rb /
CMD ["bundle", "exec", "ruby", "hasher.rb"]
EXPOSE 80