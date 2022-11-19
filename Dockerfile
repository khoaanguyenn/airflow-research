FROM ruby:2.7.6-alpine

ARG BUNDLE_GEMS__CONTRIBSYS__COM
# Install dependencies
RUN apk update -qq && apk add --no-cache build-base postgresql postgresql-dev libpq sqlite-dev

# Create a new folder
WORKDIR /app
COPY . /app

RUN BUNDLE_GEMS__CONTRIBSYS__COM=$BUNDLE_GEMS__CONTRIBSYS__COM bundle install -j 4 --quiet

ENV HANAMI_ENV=production

EXPOSE 2300
