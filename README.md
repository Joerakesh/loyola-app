# Loyola College App

Loyola College student ERP application repository. This repository contains the Flutter mobile app, the Node.js/Express API backend, and the Vercel API entry point.

## Repository layout

```text
.
├── api/                    # Vercel catch-all API function
├── backend/                # Express + TypeScript API server
├── dev-environment/        # Shared Docker toolchains and team setup
├── mobile/                 # Flutter Android application
├── index.html              # Static web entry page
└── package.json            # Root Vercel/runtime dependencies
```

## Prerequisites for team members

For the recommended Windows 10/11 + 8 GB RAM setup:

- Git for Windows
- Docker Desktop with WSL 2 backend and hardware virtualization enabled
- VS Code (recommended)
- Android Platform Tools (ADB) on Windows for installing builds to physical Android devices
- 20–30 GB free disk space for the Flutter/Android image and build caches

The shared environment keeps Flutter, Java, Android build tools, Node.js and Python SDKs in containers. Android emulators are not part of this setup; test on physical devices.

## 1. Clone and configure

```powershell
git clone https://github.com/Joerakesh/loyola-app.git
cd loyola-app
git switch feature/docker-dev-environment
```

If the branch has already been merged, use the repository's default branch instead.

Create the backend environment file:

```powershell
Copy-Item backend/.env.example backend/.env
```

Edit `backend/.env` and configure the required local credentials and integrations. In particular:

- Set a strong random `SESSION_SECRET`.
- Set a valid 64-character hexadecimal `ERP_CREDENTIALS_ENCRYPTION_KEY`.
- Keep `MONGODB_URI=mongodb://localhost:27017` for running the backend directly on Windows. When running through the Compose backend service, Compose overrides it to use the MongoDB service hostname.
- Configure Firebase credentials and other integration values only when needed.
- If using a Firebase service-account file, place it at `backend/service-account-key.json` to match the example path.

Never commit `backend/.env`, service-account JSON files, tokens, private keys or production data.

## 2. Install and configure Docker

Install Docker Desktop for Windows and choose the WSL 2 backend. Start Docker Desktop and verify from PowerShell:

```powershell
docker version
docker compose version
wsl --status
```

For an 8 GB laptop, begin with a WSL/Docker memory limit of 4 GB, 2 GB swap and 2–4 CPUs. Optional `%UserProfile%\.wslconfig`:

```ini
[wsl2]
memory=4GB
processors=4
swap=2GB
```

Apply changes with:

```powershell
wsl --shutdown
```

Restart Docker Desktop after that. Avoid running the Flutter release build and multiple databases simultaneously on 8 GB machines.

Build the shared images once:

```powershell
cd dev-environment
docker compose build flutter node python
```

Accept Android SDK licences inside the Flutter container:

```powershell
docker compose run --rm flutter bash -lc "yes | flutter doctor --android-licenses"
```

See [dev-environment/README.md](dev-environment/README.md) for full Docker settings, image details, resource limits and troubleshooting.

## 3. Run the backend API and MongoDB together

The Express + TypeScript backend is in `backend/`. Its npm scripts are:

- `npm run dev` — development server with `tsx watch`
- `npm run build` — TypeScript compilation
- `npm start` — run compiled server
- `npm test` — Vitest test suite
- `npm run typecheck` — TypeScript type checking

### Recommended: run backend and MongoDB in Docker

From the repository root:

```powershell
cd dev-environment
docker compose --profile backend up --build
```

This starts:
- MongoDB 7 on host port `27017`
- Express API on host port `3000`

The backend container installs the locked npm dependencies and starts the dev server. It uses `mongodb://mongo:27017` inside the Compose network. The backend loads the environment from `backend/.env`; Compose sets the container's MongoDB URI to the service hostname.

Stop the services:

```powershell
docker compose --profile backend down
```

### Alternative: run backend directly on Windows

If Node.js 24 is installed on the host:

```powershell
cd backend
npm ci
npm run dev
```

Make sure MongoDB is running locally and `MONGODB_URI` in `backend/.env` points to it.

### Backend endpoints

With the development server running:

| Purpose | URL |
|---|---|
| Health check | http://localhost:3000/api/health |
| Swagger API docs | http://localhost:3000/api/docs |
| OpenAPI JSON | http://localhost:3000/api/openapi.json |
| Admin redirect | http://localhost:3000/admin |

The backend defaults to port `3000` and can be changed with `PORT`.

## 4. Run the Flutter mobile app

The Flutter project is in `mobile/`. The Docker image is intended for dependency resolution and Android APK builds. Physical-device installation uses host ADB.

### Build a release APK in Docker

From the repository root:

```powershell
cd dev-environment
.\scripts\build-android.ps1
```

Or run the build command directly:

```powershell
docker compose run --rm flutter bash -lc "cd mobile && flutter pub get && flutter build apk --release"
```

APK output:

`mobile/build/app/outputs/flutter-apk/app-release.apk`

### Install on a physical Android device

Enable Developer Options and USB debugging, connect the phone, and install Android Platform Tools on Windows. Then:

```powershell
adb devices
.\scripts\install-apk.ps1
```

Wireless ADB can also be paired from Windows, then use the same install script. USB passthrough into Docker is not configured.

### Live Flutter development

This Docker setup is for builds, not live `flutter run` hot reload. For live debugging on a physical phone, use a host Flutter SDK with host ADB, or implement and test a dedicated ADB-forwarding workflow.

## 5. Run other development tools

From `dev-environment/`:

### Node.js 24 shell

```powershell
docker compose run --rm node
```

The repository backend requires Node.js 24.x, so the shared Node image uses Node 24.

### Python 3.12 shell

```powershell
docker compose run --rm python
```

### PostgreSQL (optional)

PostgreSQL is available for local work that needs it; the current Express backend is configured for MongoDB.

```powershell
docker compose --profile postgres up -d postgres
```

Host connection: `localhost:5432`  
Container connection: `postgresql://loyola:loyola_dev_only@postgres:5432/loyola_dev`

Stop it:

```powershell
docker compose --profile postgres down
```

## 6. Run the static web entry page

The repository root contains `index.html`. The root `package.json` does not define a local frontend dev script. To preview the static page, you can use the Node container with a temporary static server:

```powershell
cd dev-environment
docker compose run --rm --service-ports node bash -lc "npx --yes http-server -p 4173 /workspace"
```

Open http://localhost:4173. This is a static preview, not a separate application backend. The `api/` catch-all file is the Vercel serverless entry point that forwards API requests to the Express app; local development should use the Express server described above.

## 7. Common commands

Run from `dev-environment/`:

```powershell
docker compose config                  # validate Compose configuration
docker compose ps                      # list running containers
docker compose --profile backend up    # start API + MongoDB
docker compose --profile postgres up -d postgres
docker compose down                    # stop containers
docker system df                       # inspect Docker disk use
```

Do not use `docker compose down -v` unless you intend to delete named database data and SDK caches.

## 8. Team workflow

1. Pull the latest branch and create a feature branch.
2. Use the shared Docker environment for consistent tool versions.
3. Keep `mobile/pubspec.lock` and `backend/package-lock.json` committed.
4. Never commit secrets, local environment files, service-account keys or signing keystores.
5. Run backend type checks/tests and Flutter analysis before opening a PR.
6. Build and test APKs on a physical Android device before merging.

## Documentation

- [Docker developer environment and setup guide](dev-environment/README.md)
- [Flutter documentation](https://docs.flutter.dev/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
