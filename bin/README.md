# bin
scripts that are used my during the deployment and help to debug and configuration the cluster resources.

- [copy-kubeconfig-to-container.sh](copy-kubeconfig-to-container.sh) - A tool do copy a kubeconfig file to an container. Execute `bin/copy-kubeconfig-to-container.sh --help` for details. It is used by the `copy-kind-kubeconfig-to-toolbox` target.

- [dump-certificate.sh](dump-certificate.sh) - A tool do dump cert-manager certificate. Execute `bin/dump-certificate.sh --help` for details. In addition with a tool like certtool you can print certificate details like: `bin/dump-certificate.sh -n cert-manager -c localcluster-selfsigned-ca-certificate -k tls.crt | certtool -i`

- [generate-artemis-sidecar-patch.sh](generate-artemis-sidecar-patch.sh) - A tool to generate a artemis custom resource resourceTemplate patch to include a sidecar container using [toolbox](https://github.com/tlbueno/toolbox) image. This is useful during the scenario creation to ensure the patch that will be included in the CR will mount all pod directoiers.

- [ingress-ngnix-expose-tcp-port.sh](ingress-ngnix-expose-tcp-port.sh) - A tool to update the helm chart deployed by the target `deploy-ingress-controller` to expose an TCP service, ie: To expose artemis acceptor service named artemis-all-0-svc and port 61616 from namespace artemis-single-instance to the host port 51511 use the command: `bin/ingress-ngnix-expose-tcp-port.sh --src-port 51511 --namespace artemis-single-instance --dst-service artemis-all-0-svc --dst-port 61616`. This will allow applications reach the artemis acceptor port without the need of pass thru 443 port with SSL. This is useful for connecting to artemis without SSL need.

- [kubectl-wait-wrapper.sh](kubectl-wait-wrapper.sh) - A wrapper to kubectl wait command. It is used inside the [Makefile]. `bin/kubectl-wait-wrapper.sh --help` for details. It is used by multiple targets to check the deployment.

- [namespace-data-collector.sh](namespace-data-collector.sh) - A tool to dump kubernetes resources from a namespace. Execute `bin/namespace-data-collector.sh --help` for details.

