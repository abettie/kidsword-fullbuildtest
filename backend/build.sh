#!/usr/bin/env bash
set -e

echo "Building Lambda functions..."
node esbuild.mjs

echo "Creating ZIP archives..."
mkdir -p dist

cd dist/users && zip -r ../users.zip . && cd ../..
cd dist/posts && zip -r ../posts.zip . && cd ../..

echo "Build complete: dist/users.zip, dist/posts.zip"
