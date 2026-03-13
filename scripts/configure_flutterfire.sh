#!/bin/bash
set -e

echo "=== Configuring FlutterFire ==="

cd app
flutterfire configure \
  --project=mimzapp \
  --platforms=android,ios \
  --yes

echo "FlutterFire config generated successfully."
