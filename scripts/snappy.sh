#!/bin/bash

# Script to compress files matching a glob pattern in a specified directory using Snappy via Python venv
# Usage: ./script.sh [directory] [glob_pattern]
# Defaults: current directory (.) and *.gguf
# Assumes Python 3 and libsnappy (brew install snappy) available
# Keeps originals; outputs with .snappy appended to original suffix; cleans up venv
# Snappy: Fast, low-ratio compression (~1.5-2x on binaries); no config options
# Decompress: Use python-snappy or libsnappy tools (e.g., snzip if installed)

set -e # Exit on error

# Parse arguments
DIR="${1:-.}"
GLOB="${2:-*.gguf}"

VENV_DIR=".snappy_venv"
PY_SCRIPT="$VENV_DIR/compress.py"

# Create venv
python3 -m venv "$VENV_DIR"

# Activate and install
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install python-snappy # Correct package for Snappy compression bindings

# Write Python script for compression
cat >"$PY_SCRIPT" <<'EOF'
import os
import sys
import snappy
from pathlib import Path

# Get dir and glob from args or defaults
dir_path = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
glob_pattern = sys.argv[2] if len(sys.argv) > 2 else '*.gguf'

for file_path in dir_path.glob(glob_pattern):
    # Skip if already ends with .snappy
    if str(file_path.suffix).endswith('.snappy'):
        print(f"Skipping {file_path.name} (already compressed)")
        continue
    
    # Append .snappy to original suffix
    original_suffix = file_path.suffix
    compressed_suffix = original_suffix + '.snappy'
    compressed_path = file_path.with_suffix(compressed_suffix)
    print(f"Compressing {file_path.name} to {compressed_path.name}...")
    
    try:
        with open(file_path, 'rb') as infile:
            data = infile.read()  # Read whole file (ok for <2GB; chunk if larger)
        compressed = snappy.compress(data)
        with open(compressed_path, 'wb') as outfile:
            outfile.write(compressed)
        orig_size = file_path.stat().st_size
        comp_size = compressed_path.stat().st_size
        ratio = orig_size / comp_size if comp_size else 0
        print(f"  Success: {orig_size / 1024 / 1024:.1f} MB -> {comp_size / 1024 / 1024:.1f} MB ({ratio:.2f}x)")
    except Exception as e:
        print(f"  Error compressing {file_path.name}: {e}")
        if compressed_path.exists():
            compressed_path.unlink()

print("Compression complete.")
EOF

# Run the compression
python "$PY_SCRIPT" "$DIR" "$GLOB"

# Cleanup
deactivate
rm -rf "$VENV_DIR"
echo "Cleanup done. Originals preserved."
