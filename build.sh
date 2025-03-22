#!/bin/bash

# Function to fetch latest Playwright versions
get_playwright_versions() {
    npm view playwright versions --json | jq -r '.[]' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 3
}

# Build images for each version
build_images() {
    for version in $(get_playwright_versions); do
        echo "Building Playwright v${version}"
        docker build \
            --build-arg PLAYWRIGHT_VERSION=${version} \
            -t your-registry/playwright-plus:${version} \
            -f Dockerfile .
        
        # Optionally push to registry
        docker push your-registry/playwright-plus:${version}
    done
}

build_images 