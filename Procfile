web: bundle exec passenger start -a 127.0.0.1 -p 3000 --environment development --max-pool-size=2
vite: bin/vite dev
webpack-client: bin/shakapacker-dev-server
shakapacker-hack: bin/shakapacker-hack
webpack-server: SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch
jobs: bundle exec bin/jobs
mailhog: mailhog