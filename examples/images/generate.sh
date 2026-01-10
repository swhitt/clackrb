#!/bin/bash
set -e
cd "$(dirname "$0")/../.."

IMAGES_DIR="examples/images"

record_and_convert() {
    local name=$1
    local at_time=${2:-1000}
    local rows=${3:-6}

    echo "Recording $name..."
    asciinema rec "$IMAGES_DIR/${name}_v3.cast" \
        --command "expect $IMAGES_DIR/$name.exp" \
        --overwrite -q --cols 60 --rows "$rows"

    echo "Converting to v2..."
    asciinema convert "$IMAGES_DIR/${name}_v3.cast" "$IMAGES_DIR/${name}.cast" \
        -f asciicast-v2 --overwrite

    echo "Generating SVG..."
    svg-term --in "$IMAGES_DIR/${name}.cast" \
        --out "$IMAGES_DIR/${name}.svg" \
        --at "$at_time" \
        --no-cursor \
        --padding 5 \
        --height "$rows"

    rm -f "$IMAGES_DIR/${name}_v3.cast" "$IMAGES_DIR/${name}.cast"
    echo "Done: $IMAGES_DIR/${name}.svg"
    echo
}

record_and_convert "text" 2500 5
record_and_convert "password" 2000 5
record_and_convert "confirm" 1200 5
record_and_convert "select" 1200 7
record_and_convert "multiselect" 1800 8
record_and_convert "spinner" 1200 5

echo "All SVGs generated!"
