bin/rails generate dockerfile --force --fullstaq --jemalloc --yjit --cache --parallel
docker build --no-cache --progress=plain .
docker compose up
