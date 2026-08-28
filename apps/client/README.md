# Bennu Client

Shared Flutter client target for Android and Windows.

The client is intentionally kept separate from the existing Web and Dashboard applications so the same application code can produce Android and Windows artifacts.

## Build targets

- Android: `flutter build apk --release`
- Windows: `flutter build windows --release`

Authentication and authorization remain enforced by the Bennu API. No Owner credentials are embedded in the client.

The repository CI workflow validates that Flutter can resolve dependencies and build both targets when the required platform toolchains are available.
