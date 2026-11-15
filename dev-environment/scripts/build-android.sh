#!/usr/bin/env bash
set -euo pipefail
docker compose run --rm flutter bash -lc 'cd mobile && flutter pub get && flutter build apk --release'
echo 'APK: mobile/build/app/outputs/flutter-apk/app-release.apk'
