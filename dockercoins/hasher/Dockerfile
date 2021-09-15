# Specify a base image
FROM ruby:slim

#Install some dependencies
RUN apt-get update\
 && apt-get install -y --no-install-recommends\
 # for gems to be compiled
 build-essential\
 && apt-get clean\
 && rm -rf /var/cache/apt/archives/*\
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*\
 && truncate -s 0 /var/log/*log
RUN gem install sinatra thin

# Run the application
ADD hasher.rb /
CMD ["ruby", "hasher.rb"]