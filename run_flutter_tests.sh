#!/bin/bash
# run_flutter_tests.sh
# Runs all Flutter unit and widget tests.

set -e

echo "=================================="
echo "    Running Flutter Tests"
echo "=================================="

cd app
flutter test
