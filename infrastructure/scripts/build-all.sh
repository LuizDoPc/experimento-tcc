#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "Cleaning up macOS metadata files..."
find . -name "._*" -type f -delete 2>/dev/null || true
find . -name ".DS_Store" -type f -delete 2>/dev/null || true

echo "Building Java gRPC application..."
cd java-grpc
./mvnw clean package -DskipTests
cd ..

echo "Building Java HTTP application..."
cd java-http
./mvnw clean package -DskipTests
cd ..

echo "Building Go gRPC application..."
cd go-grpc/api
go mod download
go build -o api main.go
cd ../..

echo "Building Go HTTP application..."
cd go-http/api
go mod download
go build -o api main.go
cd ../..

echo "Building lab client..."
cd client
go mod download
go build -o lab-client .
cd ..

echo "All applications built successfully!"

