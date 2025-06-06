#!/bin/bash

# Build and run the Eight Sleep CLI

echo "Building Eight Sleep CLI..."
cd "$(dirname "$0")"

# Build the package
swift build -c release

# Run the CLI
./.build/release/eight-sleep-cli