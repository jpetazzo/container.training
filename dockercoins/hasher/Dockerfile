FROM ruby:alpine
WORKDIR /app
RUN apk add --update build-base curl
RUN gem install sinatra --version '~> 3'
RUN gem install thin
COPY hasher.rb .
CMD ["ruby", "hasher.rb", "-o", "::"]
EXPOSE 80
