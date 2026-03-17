#!/bin/bash
set -euo pipefail

go mod vendor
GOOS=linux GOARCH=amd64 go build -mod=vendor -o main main.go
