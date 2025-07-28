#!/bin/sh
exec chpst -u app:app bundle exec bin/jobs >>/home/app/webapp/log/worker.log 2>&1
