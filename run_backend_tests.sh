#!/bin/bash
# run_backend_tests.sh
# Runs all Fastify backend unit and integration tests via Vitest.

set -e

echo "=================================="
echo "    Running Backend Tests"
echo "=================================="

cd backend
npm run test
