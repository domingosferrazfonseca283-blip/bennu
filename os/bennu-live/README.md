# Bennu OS Linux

Bennu OS is distributed as a Linux-based operational environment with the Bennu dashboard and API services available as system services or containers.

## Build target

The distribution build is intentionally reproducible and based on Debian Live tooling. The scaffold in this directory defines the target filesystem, systemd services, boot configuration, and package manifest without claiming an ISO artifact has already been built.

## Security model

- Development authentication is disabled in production.
- Identity is delegated to the configured OIDC provider.
- Bennu Owner and guest approval remain enforced by the API.
- Privileged services should run with least privilege.

## ISO validation

An ISO is considered supported only after the CI/release environment successfully builds it and boots it in a virtual machine.