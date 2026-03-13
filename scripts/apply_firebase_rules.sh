#!/bin/bash
set -e

echo "=== Deploying Firebase Rules ==="

firebase deploy --only firestore:rules,storage --project mimzapp

echo "Rules deployed successfully."
