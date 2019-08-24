FROM golang:1.9-stretch as confd
ARG CONFD_VERSION=0.16.0

ADD https://github.com/kelseyhightower/confd/archive/v${CONFD_VERSION}.tar.gz /tmp/

RUN apt-get update \
    && apt-get install -y \
    make \
    bzip2 \
  && mkdir -p /go/src/github.com/kelseyhightower/confd && \
  cd /go/src/github.com/kelseyhightower/confd && \
  tar --strip-components=1 -zxf /tmp/v${CONFD_VERSION}.tar.gz && \
  go install github.com/kelseyhightower/confd && \
  rm -rf /tmp/v${CONFD_VERSION}.tar.gz



FROM ruby:2.4-slim-stretch
ARG DIASPORA_VER=0.8.0.0

ENV RAILS_ENV=production \
    UID=942 \
    GID=942

RUN apt-get update \
    && apt-get install -y \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libxslt-dev \
    imagemagick \
    ghostscript \
    curl \
    libmagickwand-dev \
    git \
    libpq-dev \
    nodejs \
    wget \
    libjemalloc-dev \
    gosu \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup --GID ${GID} diaspora \
    && adduser --uid ${UID} --gid ${GID} \
    --home /diaspora --shell /bin/sh \
    --disabled-password --gecos "" diaspora

COPY --from=confd /go/bin/confd /usr/local/bin/confd
RUN mkdir -p /etc/confd/conf.d
RUN mkdir -p /etc/confd/templates
COPY --chown=diaspora:diaspora confd/ /etc/confd/

USER diaspora

WORKDIR /diaspora
RUN git clone -b master https://github.com/diaspora/diaspora.git
RUN mv /diaspora/diaspora/* /diaspora/
RUN mkdir /diaspora/log \
    && cp config/database.yml.example config/database.yml

RUN gem install bundler \
    && script/configure_bundler \
    && bin/bundle install --full-index -j$(getconf _NPROCESSORS_ONLN)

COPY --chown=root:staff entrypoints/ /usr/local/bin/

VOLUME /diaspora/public
LABEL maintainer="nikkoura"
LABEL source="https://github.com/nikkoura/docker-diaspora"
