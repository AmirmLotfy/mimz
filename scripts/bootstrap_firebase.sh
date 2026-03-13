#!/bin/bash
set -e

echo "=== Bootstrapping Firebase config for Mimz ==="

# Set correct GCP project
gcloud config set project mimzapp

# Enable minimum required APIs
echo "Enabling GCP APIs..."
gcloud services enable \
    firebase.googleapis.com \
    firestore.googleapis.com \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    identitytoolkit.googleapis.com \
    generativelanguage.googleapis.com \
    --project=mimzapp

echo "=== Firebase Bootstrap Complete ==="
echo "Note: Provider setup (Google, Apple, Email) must be configured in the Firebase Console."
