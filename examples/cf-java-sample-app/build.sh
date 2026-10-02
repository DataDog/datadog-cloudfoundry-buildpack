#!/usr/bin/env bash
set -euo pipefail

# Be sure to have Java 17 JDK installed
./mvnw package
# zip -u exits 12 ("nothing to do") when the jar already holds an up-to-date
# traffic script, e.g. on a rebuild; that is success, not a failure.
zip -u target/app-sample.jar traffic || [ $? -eq 12 ]
