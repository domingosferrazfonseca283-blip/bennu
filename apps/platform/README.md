# Bennu cross-platform clients

The Bennu platform uses the API as the shared control plane and the dashboard as the shared UI.

## Targets

- Web: supported through the existing dashboard build.
- Windows: package the web UI as a desktop client using the repository's Electron target when implemented.
- Android: package the shared UI as a mobile client when the Android build target is implemented.
- Termux: use the API/CLI client over localhost or a configured server.
- Cloud/server: deploy the production Compose stack.

A target is not considered officially supported until its build artifact is produced and smoke-tested on that target.