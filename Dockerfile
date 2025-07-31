FROM ruby:3.2.2-alpine

ARG RAILS_ROOT=/usr/src/app
ENV RAILS_ROOT=${RAILS_ROOT}

USER root
WORKDIR $RAILS_ROOT

RUN apk update \
  && apk upgrade \
  && apk add --update --no-cache \
     build-base curl-dev git postgresql-dev \
     yaml-dev zlib-dev nodejs yarn dumb-init

ARG BUILD_NUMBER
ENV BUILD_NUMBER=${BUILD_NUMBER}

ARG RAILS_ENV
ENV RAILS_ENV=${RAILS_ENV:-production}

COPY Gemfile* $RAILS_ROOT/

RUN if [ "$RAILS_ENV" == "production" ]; \
    then bundle config set without 'development test doc'; \
    else bundle config set without 'test doc'; \
    fi
RUN gem install bundler:2.4.10; bundle install
RUN yarn install --check-files

COPY . $RAILS_ROOT

RUN if [ "$RAILS_ENV" == "production" ]; \
  then SECRET_KEY_BASE=`bin/rails secret` bundle exec rake assets:precompile --trace; \
  fi

EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["scripts/start.sh"]
