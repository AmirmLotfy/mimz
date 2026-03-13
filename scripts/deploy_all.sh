#!/bin/bash
set -e

echo "=== Mimz Full Deployment ==="

echo "1/5: Bootstrapping GCP/Firebase..."
./scripts/bootstrap_firebase.sh

echo "2/5: Applying Firebase Rules..."
./scripts/apply_firebase_rules.sh

echo "3/5: Configuring FlutterFire..."
./scripts/configure_flutterfire.sh

echo "4/5: Deploying Backend to Cloud Run..."
./scripts/deploy_backend.sh

echo "5/5: Deployment Process Complete!"
