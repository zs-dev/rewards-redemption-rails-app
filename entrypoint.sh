#!/bin/bash
set -e

rm -f /src/tmp/pids/server.pid

if [ ! -f "/src/Gemfile" ]; then
  echo ">>> No Gemfile found. Creating new Rails app..."
  rails new /src --database=mysql --skip-bundle --force
fi

echo ">>> Installing Gems..."
bundle install

echo ">>> Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0
