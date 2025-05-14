# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Set proper permissions
RUN mkdir -p /usr/local/bundle && \
    chown -R 1000:1000 /usr/local/bundle

WORKDIR /src

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl default-mysql-client libjemalloc2 libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_APP_CONFIG="/usr/local/bundle"

# Build stage
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential default-libmysqlclient-dev git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle config set frozen false && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# Final stage
FROM base

COPY --from=build --chown=1000:1000 "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build --chown=1000:1000 /src /src

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

USER 1000:1000

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]