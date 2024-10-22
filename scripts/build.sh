# utility scripts are from my personal website codebase
bin/rails generate dockerfile --force --fullstaq --jemalloc --yjit --cache --parallel --compose
docker build --no-cache --progress=plain .
docker compose up