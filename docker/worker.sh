#!/bin/sh
# Run Solid Queue worker and log to stdout/stderr for container log collection
exec chpst -u app:app bundle exec bin/jobs
