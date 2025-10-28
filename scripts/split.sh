#!/bin/bash

# Updated Script to build and split as root in Docker, then chown output to host user.
# This fixes apt install perms while ensuring files are user-owned on host.

INPUT_FILE="../fastthink-0.5b-tiny-q2_k.gguf"
SPLITS_DIR="./splits"
MAX_SIZE="99M"
MODEL_NAME="fastthink-0.5b-tiny"

# Create splits dir on host if needed
mkdir -p "$SPLITS_DIR"

IMAGE="ubuntu:22.04"

# Get host UID/GID for final chown
HOST_UID=$(id -u)
HOST_GID=$(id -g)

docker run --rm \
    -v "$(pwd):/workspace" \
    -w /workspace/scripts \
    "$IMAGE" \
    bash -c "
    apt-get update && apt-get install -y git build-essential cmake libcurl4-openssl-dev ccache

    if [ ! -d 'llama.cpp' ]; then
      git clone https://github.com/ggerganov/llama.cpp.git
    fi
    cd llama.cpp
    git pull

    rm -rf build
    mkdir -p build
    cd build
    cmake .. \
      -DLLAMA_CURL=OFF \
      -DLLAMA_BUILD_EXAMPLES=OFF \
      -DLLAMA_BUILD_SERVER=OFF
    cmake --build . --parallel 1 --config Release

    cd /workspace/scripts

    # Ensure output dir exists
    mkdir -p $SPLITS_DIR

    # Run the split with explicit prefix to ./splits/
    ./llama.cpp/build/bin/llama-gguf-split --split --split-max-size $MAX_SIZE $INPUT_FILE ./splits/$MODEL_NAME

    # Chown the splits dir to host user
    chown -R $HOST_UID:$HOST_GID $SPLITS_DIR

    # Verify
    ls -la $SPLITS_DIR/
  "

echo "Split complete! Files now in $SPLITS_DIR, owned by your user."
