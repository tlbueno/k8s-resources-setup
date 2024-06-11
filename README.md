# k8s-resources-setup
A set resources to get deployed on kubernetes or openshift cluster

The goal of this project is to have a simple way to prepare a kubernetes or openshift cluster with some basic resources/tools for tests, experiments and proof of concepts. It was created to provide the resources to experiment the [ArtemisCloud operator](https://artemiscloud.io) but may be used as a general tool to provision a cluster

### Require tools

- base64
- curl
- [helm]
- jq
- [kind]
- kubectl
- [kustomize]
- make
- [yq]

### Local cluster vs remote cluster

In the [targets list below](#make-targets), you will see what can be deployed in the cluster. There is a target that creates a local cluster but this is not a requirement. If you have a remote cluster, since you are logged in it, it will work without issues. If you are running an Openshift cluster there are targets which may not apply, like the ones which deploys `olm` and `redhat operators catalog`.

The local cluster is created using [kind] as you will see below. In the kind configuration, [kind-config.yaml], there is an extra mount to mount the `${HOME}/.docker/config.json`. This file allows kind to use the registries credentials from docker. As an example, if you are logged in on a private registry like `registry.redhat.io` in docker, kind will be able to use images from there.

### Make targets

  - prepare-k8s, ie: `make prepare-k8s`
    - This target execute most of the targets below. You can see the list of targets in the [Makefile] under the `PREPARE_K8S_TARGETS` variable. If you want to skip targets, you add execute `make prepare-k8s SKIP_TARGETS="target_a target_b"`.

  - prepare-ocp, ie: `make prepare-ocp`
    - This target execute most of the targets below but skips those which should not be needed on an Openshift cluster. You can see the list of targets in the [Makefile] under the `PREPARE_OCP_TARGETS` variable. If you want to skip targets, you add execute `make prepare-ocp SKIP_TARGETS="target_a target_b"`.

  - create-kind, ie: `make create-kind`
    - Create [kind] cluster using the configuration file [kind-config.yaml].

    - K8S_VERSION environment variable can be used to define the kubernetes version kind will use. ie: `make create-kind K8S_VERSION=v1.30.0`. If the K8S_VERSION is not provide kind uses the latest version available on for the installed kind version.

    - KIND_CLUSTER_NAME environment variable can be used to define the cluster name. It is useful if there is more than one kind cluster on your computer. ie: `make create-kind KIND_CLUSTER_NAME=my-cluster`. It defaults to `local-k8s`.

  - delete-local-cluster, ie: `make delete-local-cluster`
    - delete the local cluster.

  - deploy-ingress-controller, ie: `make deploy-ingress-controller`
    - Deploy [Ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) in `ingress-nginx` namespace using [ingress-nginx/ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx) helm chart. Please refer to the target in the [Makefile](Makefile) to see the options used.

  - deploy-metrics-server, ie: `make deploy-metrics-server`
    - Deploy Kubernetes [Metric Server](https://kubernetes-sigs.github.io/metrics-server/) in `kube-system` namespace using [metrics-server/metrics-server](https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server) helm chart.

  - deploy-olm, ie: `make deploy-olm`
    - [Deploy Operator Lifecycle Manager (OLM)](https://olm.operatorframework.io/) in `olm` namespace. This target should not be executed on openshift clusters as Openshift already have OLM installed.
    - OLM_VERSION environment variable can be used to define the OLM version to install otherwise it will install the latest version from [olm github releases](https://github.com/operator-framework/operator-lifecycle-manager/releases)

  - deploy-cert-manager-operator, ie: `make deploy-cert-manager-operator`
    - [Deploy Cert Manager Operator](https://cert-manager.io/docs/) in in `cert-manager` namespace using [tlbueno/olm-operator-installer](https://github.com/tlbueno/helm-charts/tree/main/charts/olm-operator-installer) helm chart.

  - deploy-trust-manager-operator, ie: `make deploy-trust-manager-operator`
    - [Deploy Trust Manager Operator](https://cert-manager.io/docs/trust/trust-manager/) in `cert-manager` namespace using [jetstack/trust-manager](https://github.com/cert-manager/trust-manager/tree/main/deploy/charts/trust-manager) helm chart.

  - deploy-selfsigned-ca, ie: `make deploy-selfsigned-ca`
    - Deploy a self-signed CA Issuer, a self-signed CA and a CA issuer for the created self-signed CA in the namespace `cert-manager`. It also create copy of the self-signed CA to allow rotation of the CA without issues as suggested by cert-manager/trust-manager [documentation](https://cert-manager.io/docs/trust/trust-manager/#cert-manager-integration-intentionally-copying-ca-certificates).

  - deploy-prometheus, ie: `make deploy-prometheus`
    - Deploy [Prometheus](https://prometheus.io) Stack (Prometheus Operator, Prometheus, AlertManager, Node Exporter, Kube State Metrics, Grafana) in `prometheus` namespace using
    [prometheus-community/kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) helm chart
    - INGRESS_DOMAIN environment variable can be used to define the ingress domain. It defaults to `localcluster`.

  - deploy-mariadb-operator, ie: `make deploy-mariadb-operator`
    - Deploy [Mariadb Operator](https://mariadb.com/kb/en/kubernetes-operators-for-mariadb/) in `mariadb-operator` namespace using [mariadb-operator/mariadb-operator](https://github.com/mariadb-operator/mariadb-operator/tree/main/deploy/charts/mariadb-operator) helm chart.

  - deploy-mariadb-instance, ie: `make deploy-mariadb-instance`
    - Deploy Mariadb Instance in `mariadb` namespace using the manifest files from [here](manifests/mariadb-instance). It defined the root user password as `root_mariadb`.

  - deploy-toolbox, ie: `make deploy-toolbox`
    - Deploy [toolbox](https://github.com/tlbueno/toolbox) container using tlbueno/toolbox using [tlbueno/toolbox](https://github.com/tlbueno/helm-charts/tree/main/charts/toolbox). Toolbox is a simple container image which has a set of tools installed in it.

  - deploy-redhat-operators-catalog, ie: `make deploy-redhat-operators-catalog`
    - Deploy RedHat Operators Catalog in `olm` namespace using [tlbueno/catalog-source-installer](https://github.com/tlbueno/helm-charts/tree/main/charts/catalog-source-installer). This target should not be executed on openshift clusters as Openshift already have this package index installed.
    - `REDHAT_CATALOG_IMAGE` environment variable can be used to specify the catalog index image to be used.

  - configure-inotify, ie: `make configure-inotify`
    - Configure sysctl inotify values (requires sudo access). This may be need in some cases for some applications run fine inside the cluster.

  - add-helm-charts-repos, ie: `make add-helm-charts-repos`
    - Add helm-charts repos needed by the other targets to helm. May be needed if you are not using the `prepare-k8s` or `prepare-ocp` targets.

  - update-helm-charts-repos, ie: `make update-helm-charts-repos`
    - Update helm-charts repos. It is useful to get the latest version of charts from the repos. May be needed if you are not using the `prepare-k8s` or `prepare-ocp` targets.

  - exec-toolbox, ie: `make exec-toolbox`
    - Execute a shell in the toolbox container.

  - help, ie: `make help`
    - Display a simple list of the targets and its description.

### Other tools

- [namespace-data-collector.sh](bin/namespace-data-collector.sh) - A tool to dump kubernetes resources from a namespace. Execute `bin/namespace-data-collector.sh --help` for details.

- [kubectl-wait-wrapper.sh](bin/kubectl-wait-wrapper.sh) - A wrapper to kubectl wait command. It is used inside the [Makefile](Makefile). `bin/kubectl-wait-wrapper.sh --help` for details.

- [dump-certificate.sh](bin/dump-certificate.sh) - A tool do dump cert-manager certificate. Execute `bin/dump-certificate.sh --help` for details. In addition with a tool like certtool you can print certificate details like: `bin/dump-certificate.sh -n cert-manager -c localcluster-selfsigned-ca-certificate -k tls.crt | certtool -i`

## Ingress tips

To use the ingress usually you need to add the ingress address in /etc/host pointing to the cluster ingress entrypoint. ie, in the kind local cluster, you should point my-app.my-domain to the address 127.0.0.1. If you have multiple ingress addresses it is a boring task to do and manage. Another possible solution is to use an local DNS server to handle it. Below I show the steps to configure the dnsmasq DNS server to handle any subdomain of my main local domain, `localcluster`. The configuration was based on Fedora 40 and it may change on other versions or other distributions.

- Install dnsmasq
```sh
sudo dnf install dnsmasq
```

- Create an dnsmasq configuration, configure dnsmasq to start on system boot and start dnsmasq:
```sh
cat - <<EOF > sudo tee /etc/dnsmasq.d/00-local.conf
address=/localcluster/127.0.0.1
no-resolv
EOF
```
```sh
sudo systemctl enable dnsmasq.service
```
```sh
sudo systemctl start dnsmasq
```

- Create an systemd-resolved configuration to forward DNS queries to dnsmasq, restart systemd-resolved:
```sh
cat - <<EOF > sudo tee /etc/systemd/resolved.conf
[Resolve]
DNS=127.0.0.1
Domains=~localcluster
EOF
```
```sh
sudo systemctl restart systemd-resolved.service
```

- Check if it is working by trying to ping or resolve any domain under `localcluster`, ie:
```sh
ping this.is.a.test.localcluster -c 2
PING this.is.a.test.localcluster (127.0.0.1) 56(84) bytes of data.
64 bytes from localhost (127.0.0.1): icmp_seq=1 ttl=64 time=0.017 ms
64 bytes from localhost (127.0.0.1): icmp_seq=2 ttl=64 time=0.023 ms

--- this.is.a.test.localcluster ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1021ms
rtt min/avg/max/mdev = 0.017/0.020/0.023/0.003 ms
```
```sh
dig this.is.another.test.localcluster

; <<>> DiG 9.18.26 <<>> this.is.another.test.localcluster
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48062
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;this.is.another.test.localcluster.	IN	A

;; ANSWER SECTION:
this.is.another.test.localcluster. 0 IN	A	127.0.0.1

;; Query time: 1 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri May 24 08:12:49 -03 2024
;; MSG SIZE  rcvd: 74
```

[helm]: https://helm.sh
[kind]: https://kind.sigs.k8s.io
[kustomize]: https://kustomize.io
[yq]: https://github.com/mikefarah/yq
[kind-config.yaml]: local-cluster/kind-config.yaml
[Makefile]: Makefile