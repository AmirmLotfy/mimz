#!/bin/bash
set -e

# Configuration
PROJECT_ID="mimzapp"

echo "Deploying Firebase rules and storage configs..."

cd ..

firebase deploy --only firestore,storage --project $PROJECT_ID --non-interactive

echo "Firebase deployment complete."
