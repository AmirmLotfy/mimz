# Scripts Index

The `scripts/` directory is the repo's operational toolbox.

## Categories

- Deploy:
  `deploy_all.sh`, `deploy_backend.sh`, `deploy_firebase.sh`, `deploy_rules_and_indexes.sh`
- Release:
  `build_release_apk.sh`, `release_smoketest.sh`, `check_release_config.sh`
- Validation:
  `validate_deployment.sh`, `print_android_fingerprints.sh`
- Bootstrap:
  `bootstrap_cloud.sh`, `bootstrap_firebase.sh`, `configure_flutterfire.sh`
- Utilities:
  `seed_demo_data.js`, `apply_firebase_rules.sh`

Prefer these scripts over one-off terminal sequences so deploy/build behavior stays consistent.
