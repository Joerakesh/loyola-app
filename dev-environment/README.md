# Loyola Team Docker Developer Environment

A shared development toolchain for Windows 10/11 laptops with 8 GB RAM. It provides Flutter/Android APK builds, Node.js, Python, PostgreSQL and MongoDB. Android emulators are intentionally excluded; developers test on physical Android devices.

## Architecture

- Docker Desktop with the WSL 2 backend runs the SDK/tool containers.
- Flutter image includes Flutter, Java and Android command-line build tooling.
- Node.js and Python use separate lightweight containers.
- PostgreSQL and MongoDB are optional Compose profiles; start only what you need.
- ADB stays on Windows for reliable USB or wireless installation to physical phones.

## Laptop requirements

- Windows 10/11 with hardware virtualization enabled.
- Docker Desktop using WSL 2.
- Git for Windows.
- VS Code (recommended).
- Android Platform Tools (ADB) on Windows for installing APKs.
- 20–30 GB free disk space recommended for SDK images and caches.

### Suggested resource limits for 8 GB RAM

Start with Docker/WSL limited to 4 GB RAM, 2 GB swap and 2–4 CPUs. Adjust downward if Windows becomes sluggish. Optional `%UserProfile%\.wslconfig`:

```ini
[wsl2]
memory=4GB
processors=4
swap=2GB
```

After changing this file, run `wsl --shutdown` in PowerShell and restart Docker Desktop. Avoid running both database containers alongside an Android build on an 8 GB laptop.

## First-time setup

From the repository root, open PowerShell:

```powershell
cd dev-environment
docker version
docker compose version
docker compose build flutter node python
docker compose run --rm flutter bash -lc "yes | flutter doctor --android-licenses"
```

The first Flutter image build/download is large. The Flutter image requests Android platform 37 and build-tools 36.0.0 to match the app configuration previously discussed. If the app's `compileSdk`, Android Gradle Plugin or build-tools version changes, update the build args in `compose.yaml` and rebuild.

## Build a release APK

The Compose file mounts the repository root into the container, and this project expects the Flutter app under `mobile/`:

```powershell
.\scripts\build-android.ps1
```

Or directly:

```powershell
docker compose run --rm flutter bash -lc "cd mobile && flutter pub get && flutter build apk --release"
```

APK output:

`mobile/build/app/outputs/flutter-apk/app-release.apk`

Flutter Pub and Gradle caches persist in named Docker volumes between builds.

## Install on a physical Android device

Enable Developer Options and USB debugging on the phone, connect it to the laptop, and ensure Android Platform Tools are installed and on Windows PATH:

```powershell
adb devices
.\scripts\install-apk.ps1
```

ADB intentionally runs on Windows. USB device passthrough from Windows Docker Desktop into a Linux container is not a dependable default. Wireless ADB can also be paired from Windows; after connecting, use the same install script.

## Node.js and Python

Run interactive shells:

```powershell
docker compose run --rm node
docker compose run --rm python
```

For a Node project in `backend/`:

```powershell
docker compose run --rm node bash -lc "cd backend && npm ci && npm run dev"
```

Avoid sharing Windows `node_modules` with Linux containers because native modules may be incompatible. Use the project's lockfile.

## Databases (start only when needed)

Start PostgreSQL:

```powershell
docker compose --profile postgres up -d postgres
```

Start MongoDB:

```powershell
docker compose --profile mongo up -d mongo
```

Connection strings from another Compose container:
- PostgreSQL: `postgresql://loyola:loyola_dev_only@postgres:5432/loyola_dev`
- MongoDB: `mongodb://mongo:27017/loyola_dev`

Connection strings from a Windows-host application:
- PostgreSQL: `localhost:5432`
- MongoDB: `localhost:27017`

These credentials are for local development only. Never use them in production.

## Useful commands

```powershell
docker compose config
docker compose ps
docker compose down
docker system df
docker image prune
```

Do not use `docker compose down -v` unless you intend to delete database data and all named caches.

## Team practices

- Commit `pubspec.lock`, `package-lock.json` and Python dependency lock/requirements files.
- Keep SDK versions aligned; update this folder centrally when versions change.
- Never commit `.env` files, API tokens, production data, signing keys or keystores.
- Use CI secrets or secure key management for release signing; do not share a signing key through Git.
- Run `flutter analyze` and tests before merging.

## Scope and limitations

- Android emulator support is not included.
- This baseline builds APKs in Docker and installs them using host ADB.
- Live `flutter run` hot reload through Docker is not configured. For live debugging, install Flutter on the host or design and test a dedicated ADB-forwarding workflow.
- The Flutter base image currently uses the `stable` tag. For strict reproducibility, validate the build and then pin a specific image version or immutable digest.
- The environment has not yet been validated by building this repository's APK; run the first build on one team laptop before rolling it out.
