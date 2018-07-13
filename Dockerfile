FROM ruby:2.5-slim

MAINTAINER katherly@upenn.edu

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential \
  git-annex \
  git-core \
  default-libmysqlclient-dev

SHELL ["/bin/bash", "-c"]

RUN mkdir /zip_workspace

RUN mkdir /bulwark_gitannex_remote

ADD . /usr/src/app/

WORKDIR /usr/src/app/

RUN mkdir /usr/src/app/todos

RUN bundle install

CMD ["bash", "-c", "while [ 1 ]; do sleep 10000; done"]