#!/bin/sh
# Run Solid Queue worker from app root so Bundler finds Gemfile
cd /home/app/webapp || exit 1
export BUNDLE_GEMFILE=/home/app/webapp/Gemfile
# Log to stdout/stderr for container log collection
exec chpst -u app:app bundle exec bin/jobs
