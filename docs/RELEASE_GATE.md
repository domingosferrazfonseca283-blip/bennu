# Bennu Release Gate

The project must not be declared ready for installation/publication until every gate below is verified.

## Security
- Owner identity is authenticated by a real identity provider and verified email.
- `domingosferrazfonseca283@gmail.com` is the configured initial Owner email.
- There is exactly one initial Owner/Admin.
- New users are denied access by default and remain pending until Owner approval.
- Development authentication is disabled in production.
- Secrets are supplied through environment/secret management, never committed.
- Privileged and high-impact operations remain policy/approval gated.
- Audit events are persisted for access and privileged operations.

## Data and backend
- Production PostgreSQL migrations run successfully from an empty database.
- Redis starts successfully.
- API health endpoint responds after migrations.
- All required API modules load without import errors.

## Frontend
- Production build completes.
- Dashboard loads against production API.
- Authentication and authorization states are represented correctly.
- Demo/placeholder telemetry is clearly separated from real telemetry.

## Packaging
- Linux package/image is buildable and installable.
- Bennu OS ISO is produced and boots in a test VM before release.
- Windows and Android artifacts are only marked supported after their builds are reproducibly verified.
- Termux and Web deployments are validated separately.

## Release
- Clean-install test passes.
- Upgrade/migration test passes.
- Backup/restore procedure is documented and tested.
- Known blockers are zero.
