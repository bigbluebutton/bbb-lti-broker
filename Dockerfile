FROM alpine:3.13 AS alpine

FROM alpine AS base
RUN apk add --no-cache \
    libpq \
    libxml2 \
    libxslt \
    libstdc++ \
    ruby \
    ruby-irb \
    ruby-bigdecimal \
    ruby-bundler \
    ruby-json \
    nodejs \
    npm \
    yarn \
    tini \
    tzdata \
    shared-mime-info
WORKDIR /usr/src/app

FROM base as builder
RUN apk add --update --no-cache \
    build-base \
    libxml2-dev \
    libxslt-dev \
    pkgconf \
    postgresql-dev \
    ruby-dev \
    yaml-dev \
    zlib-dev \
    curl-dev git \
    && ( echo 'install: --no-document' ; echo 'update: --no-document' ) >>/etc/gemrc
USER root
COPY Gemfile* ./
RUN bundle config build.nokogiri --use-system-libraries \
    && bundle install --deployment --without development:test -j4 \
    && rm -rf vendor/bundle/ruby/*/cache \
    && find vendor/bundle/ruby/*/gems/ \( -name '*.c' -o -name '*.o' \) -delete
RUN yarn install
RUN bin/webpack
COPY . ./

FROM base AS application
USER root
ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=true
COPY --from=builder /usr/src/app ./

ARG BUILD_NUMBER
ENV BUILD_NUMBER=${BUILD_NUMBER}

FROM application

EXPOSE 3000

# Precompile assets
#   The assets are precompiled in runtime because RELATIVE_URL_ROOT can be set up through .env

# Run startup command
CMD ["scripts/start.sh"]
