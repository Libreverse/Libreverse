#!/bin/bash

# Configuration
INPUT_FILE="/Users/george/libreverse/app/client-ai-models/intel-toxic-prompt-roberta.onnx" # Path to your ONNX file
OUTPUT_DIR="/Users/george/libreverse/app/client-ai-models/"                              # Directory to save .onnx.part files
MAX_CHUNK_SIZE=$((95*1024*1024))                                                        # 95MB in bytes

# Derive base filename (without path or extension)
BASE_NAME=$(basename "$INPUT_FILE" .onnx)
METADATA_FILE="$OUTPUT_DIR/${BASE_NAME}_metadata.json"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

# Get file size
FILE_SIZE=$(stat -f %z "$INPUT_FILE" 2>/dev/null || stat -c %s "$INPUT_FILE" 2>/dev/null)
if [ -z "$FILE_SIZE" ]; then
    echo "Error: Could not determine file size."
    exit 1
fi

# Split the file into chunks
split -b "$MAX_CHUNK_SIZE" "$INPUT_FILE" "$OUTPUT_DIR/${BASE_NAME}_" || {
    echo "Error: Failed to split file."
    exit 1
}

# Rename chunks to .onnx.part
chunk_index=0
chunks=()
for chunk in "$OUTPUT_DIR/${BASE_NAME}_"*; do
    if [ -f "$chunk" ]; then
        new_name="$OUTPUT_DIR/${BASE_NAME}_${chunk_index}.onnx.part"
        mv "$chunk" "$new_name"
        chunks+=("$(basename "$new_name")")
        chunk_size=$(stat -f %z "$new_name" 2>/dev/null || stat -c %s "$new_name" 2>/dev/null)
        echo "Created chunk ${BASE_NAME}_${chunk_index} ($chunk_size bytes)"
        ((chunk_index++))
    fi
done

# Generate metadata JSON
metadata=$(cat <<EOF
{
    "original_filename": "$(basename "$INPUT_FILE")",
    "mime_type": "application/octet-stream",
    "chunk_count": ${#chunks[@]},
    "chunks": [
$(for i in "${!chunks[@]}"; do
    chunk_size=$(stat -f %z "$OUTPUT_DIR/${chunks[$i]}" 2>/dev/null || stat -c %s "$OUTPUT_DIR/${chunks[$i]}" 2>/dev/null)
    echo "        {\"index\": $i, \"filename\": \"${chunks[$i]}\", \"size\": $chunk_size}$( [ $i -lt $((${#chunks[@]}-1)) ] && echo "," )"
done)
    ]
}
EOF
)

# Save metadata
echo "$metadata" > "$METADATA_FILE"
if [ $? -eq 0 ]; then
    echo "Metadata saved to $METADATA_FILE"
else
    echo "Error: Failed to save metadata."
    exit 1
fi

echo "Processing complete. ${#chunks[@]} chunks created."