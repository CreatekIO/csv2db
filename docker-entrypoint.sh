#!/usr/bin/env sh
set -eu

echo "~~~ update RubyGems and Bundler"
gem install bundler -v "~> 2.4.22"
gem update --system 3.4.22 >/dev/null

echo "~~~ bundle install"
bundle install \
  --jobs "$(getconf _NPROCESSORS_ONLN)" \
  --retry 2
