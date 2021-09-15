# Specify a base image
FROM ruby:alpine

#Install some dependencies
RUN apk add --update build-base curl
RUN gem install sinatra thin

# Run the application
ADD hasher.rb /
CMD ["ruby", "hasher.rb"]