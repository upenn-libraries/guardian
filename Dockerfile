FROM ruby:2.5-slim

MAINTAINER katherly@upenn.edu

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential \
  git-annex \
  git-core \
  default-libmysqlclient-dev

RUN mkdir /todos

ADD . /usr/src/app/

WORKDIR /usr/src/app/

RUN bundle install

CMD ["ruby", "/usr/src/app/guardian-make-todo /todos"]