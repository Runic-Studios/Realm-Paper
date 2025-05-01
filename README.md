# Realm-Paper

Realm-Paper is a git-ops managed repository that describes all the necessary steps and artifacts required to create a new Runic Realms paper server docker image.

- `artifact-manifest.yaml` describes which artifacts to pull from the internal docker registry and where to mount them
- The `Dockerfile` installs necessary tools for the entrypoint and unzips certain artifacts
- The `server/entrypoint.sh` utilizes Palimpsest to stack configuration files on top of each other
  - These config files come from volume mounts configured by the corresponding helm chart

This repository has the `artifact-manifest.yaml` updated automatically by various git-ops processes (stemming from the dependent artifacts).
