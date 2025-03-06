# manifests
Kubernetes manifests used during the deployment or to deploy ArkMQ instances

- [cert-manager](cert-manager) - Manifest to used in [makefile] to deploy cert-manager, trust manager and create self-signed CA

- [mariadb-instance](mariadb-instance) - Manifests used in [makefile] to deploy Maria DB instance

- [artemis](artemis) - Manifests to deploy Artemis istances. Inside each directory there is a README.md file with the details of the specific deployment.

[makefile]: ../Makefile