#!/bin/bash
# run_all_tests.sh
# Runs all tests across the Mimz project (Flutter & Backend).

set -e

echo "Starting Full Mimz Test Suite..."

echo ""
./run_backend_tests.sh

echo ""
./run_flutter_tests.sh

echo ""
echo "✅ All test suites passed successfully!"
