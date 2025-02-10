#
#
### make variables
SHELL                         = /usr/bin/env bash
.SHELLFLAGS                   = -o pipefail -e -c

# project variables
MK_FILE_DIR                   = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BIN_DIR                       = $(MK_FILE_DIR)/bin
MANIFESTS_DIR                 = $(MK_FILE_DIR)/manifests

### Local cluster variables
K8S_VERSION                   =           	  # if empty kind uses the latest version available on for the installed kind version
KIND_CLUSTER_NAME             = local-k8s
INGRESS_DOMAIN                = localcluster

### Deployments variables
OLM_VERSION                   =
ifeq ($(OLM_VERSION),)
    $(eval OLM_VERSION = $(shell curl -s \
		https://api.github.com/repos/operator-framework/operator-lifecycle-manager/releases/latest | jq -cr .tag_name))
endif

REDHAT_CATALOG_IMAGE                = registry.redhat.io/redhat/redhat-operator-index:v4.17

ARTEMISCLOUD_NAMESPACE              = artemiscloud-operator
ARTEMISCLOUD_LOG_LEVEL              = info
ARTEMISCLOUD_WATCH_MODE             = all
ARTEMISCLOUD_WATCH_NAMESPACES       =
ifneq ($(ARTEMISCLOUD_WATCH_NAMESPACES),)
	ARTEMISCLOUD_WATCH_NAMESPACES_PARAM = --set "operator.watch.namespaces={$(ARTEMISCLOUD_WATCH_NAMESPACES)}"
endif
ARTEMISCLOUD_CHART_VERSION          =
ifneq ($(ARTEMISCLOUD_CHART_VERSION),)
	ARTEMISCLOUD_CHART_VERSION_PARAM = --version "$(ARTEMISCLOUD_CHART_VERSION)"
endif
INGRESS_CHAT_NAME                    = ingress-nginx/ingress-nginx
CHAOS_MESH_CONTAINER_RUNTIME         = containerd
CHAOS_MESH_CONTAINER_SOCKET_PATH     = /run/containerd/containerd.sock

# Prepare targets variables
PREPARE_K8S_TARGETS           = add-helm-charts-repos \
                                update-helm-charts-repos \
								deploy-ingress-controller \
								deploy-metrics-server \
								deploy-olm \
								deploy-cert-manager-operator \
								deploy-trust-manager-operator \
								deploy-prometheus \
								deploy-mariadb-operator-crds \
								deploy-mariadb-operator \
								deploy-toolbox \
								deploy-chaos-mesh

PREPARE_OCP_TARGETS           = add-helm-charts-repos \
								update-helm-charts-repos \
								deploy-cert-manager-operator \
								deploy-trust-manager-operator \
								deploy-prometheus \
								deploy-mariadb-operator-crds \
								deploy-mariadb-operator \
								deploy-toolbox \
								deploy-chaos-mesh

PREPARE_TARGETS               =
SKIP_TARGETS                  =

all: help

#############################
### local cluster targets ###
#############################
.PHONY: .setK8SPrepareTargets
.setK8SPrepareTargets:
	$(eval PREPARE_TARGETS = $(PREPARE_K8S_TARGETS))

.PHONY: .setOCPPrepareTargets
.setOCPPrepareTargets:
	$(eval PREPARE_TARGETS = $(PREPARE_OCP_TARGETS))

.PHONY: .runPrepare
.runPrepare:
	@for t in $(PREPARE_TARGETS); do \
    	skip=false; \
    	for s in $(SKIP_TARGETS); do \
        	if [[ "$${s}" == "$${t}" ]]; then \
            	skip="true"; \
        	fi; \
    	done; \
    	if [[ "$${skip}" == "false" ]]; then \
			echo "Executing target $${t}"; \
			$(MAKE) $${t} INGRESS_DOMAIN=$(INGRESS_DOMAIN) OLM_VERSION=$(OLM_VERSION); \
		else \
			echo "Skipping target $${t}"; \
    	fi; \
		echo ""; \
	done
	@echo ""

.PHONY: prepare-k8s
prepare-k8s: .setK8SPrepareTargets .runPrepare ## Deploy all the resources for kubernetes cluster. Check PREPARE_K8S_TARGETS in makefile for a list

 .PHONY: prepare-ocp
prepare-ocp: .setOCPPrepareTargets .runPrepare ## Deploy all the resources for openshift cluster. Check PREPARE_OCP_TARGETS in makefile for a list

.PHONY: create-kind
create-kind: ## Create Kind cluster
	@echo "Using KIND_CLUSTER_NAME as $(KIND_CLUSTER_NAME)"
	@if [ ! -f ${HOME}/.docker/config.json ]; then \
		mkdir -p ${HOME}/.docker; \
		chmod 0700 ${HOME}/.docker; \
		touch ${HOME}/.docker/config.json; \
		chmod 0600 ${HOME}/.docker/config.json; \
	fi
	@if [ ! "$(shell kind get clusters | grep $(KIND_CLUSTER_NAME))" ]; then \
		tempfile=$(shell mktemp); \
		cat $(MK_FILE_DIR)/local-cluster/kind-config.yaml | envsubst > $${tempfile}; \
		if [ "$(K8S_VERSION)" != "" ]; then \
			echo "Using K8S_VERSION as $(K8S_VERSION)"; \
			image_flag="--image kindest/node:$(K8S_VERSION)"; \
		fi; \
		kind create cluster --name=$(KIND_CLUSTER_NAME) --config $${tempfile} $${image_flag} --wait 180s; \
		kubectl wait pod --all -n kube-system --for condition=Ready --timeout 180s; \
		rm $${tempfile}; \
	else \
		echo "Kind cluster $(KIND_CLUSTER_NAME) already exists"; \
	fi
	@echo ""

.PHONY: delete-kind
delete-kind: ## delete Kind cluster
	@echo "Using KIND_CLUSTER_NAME as $(KIND_CLUSTER_NAME)"
	@if [ "$(shell kind get clusters | grep $(KIND_CLUSTER_NAME))" ]; then \
		kind delete cluster --name=$(KIND_CLUSTER_NAME) || true; \
	fi

.PHONY: copy-kind-kubeconfig-to-toolbox
copy-kind-kubeconfig-to-toolbox: ## copy kubeconfig from kind to toolbox container
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@tempfile=$(shell mktemp); \
	kind get kubeconfig --internal --name local-k8s > $${tempfile}; \
	$(BIN_DIR)/copy-kubeconfig-to-container.sh --namespace toolbox --file $${tempfile} --pod toolbox-0 \
		--container toolbox-container; \
	rm $${tempfile}
	@echo ""

######################################
### Cluster additional deployments ###
######################################
.PHONY: deploy-ingress-controller
deploy-ingress-controller: ## Deploy Ingress controller in the cluster
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=ingress-nginx; \
	chart=$(INGRESS_CHAT_NAME); \
	chart_tag=helm-chart-$(shell helm search repo $(INGRESS_CHAT_NAME) --output yaml | yq '.[0].version'); \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set controller.extraArgs.enable-ssl-passthrough= \
		--set controller.allowSnippetAnnotations=true \
		--set controller.ingressClassResource.default=true \
		--values https://raw.githubusercontent.com/kubernetes/ingress-nginx/$${chart_tag}/hack/manifest-templates/provider/kind/values.yaml \
		ingress-controller $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=90s pod --selector=app.kubernetes.io/component=controller" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

.PHONY: deploy-metrics-server
deploy-metrics-server: ## Deploy Kubernetes Metric Server
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=kube-system; \
	chart=metrics-server/metrics-server; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set args={--kubelet-insecure-tls} \
		metrics-server  $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

.PHONY: deploy-olm
deploy-olm: ## Deploy Operator Lifecycle Manager (OLM) in the cluster
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@echo "Deploying OLM version $(OLM_VERSION)"
	@tempfile=$(shell mktemp); \
	curl -sSL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/$(OLM_VERSION)/install.sh \
		-o $${tempfile}; \
	chmod +x $${tempfile}; \
	$${tempfile} $(OLM_VERSION); \
	rm $${tempfile}
	@echo "############################################################"
	@echo "# Removing pod security enforcement from olm namespace     #"
	@echo "# this is needed because redhat-operator-index requires it #"
	@echo "############################################################"
	@namespace_name=olm; \
	kubectl label --overwrite ns $${namespace_name} pod-security.kubernetes.io/enforce=privileged; \
	sleep 10; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

.PHONY: deploy-cert-manager-operator
deploy-cert-manager-operator: ## Deploy Cert Manager Operator
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=cert-manager; \
	chart=jetstack/cert-manager; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set crds.enabled=true \
		cert-manager-operator $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

.PHONY: deploy-trust-manager-operator
deploy-trust-manager-operator: ## Deploy Trust Manager Operator
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=cert-manager; \
	chart=jetstack/trust-manager; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set secretTargets.enabled=true \
		--set secretTargets.authorizedSecretsAll=true \
		trust-manager-operator $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

.PHONY: deploy-selfsigned-ca
deploy-selfsigned-ca: ## Deploy Self-Signed Certificate Authority
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=cert-manager; \
	kustomize build $(MANIFESTS_DIR)/cert-manager | kubectl -n $${namespace_name} apply -f - ; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t certificates \
		-p "--for=condition=Ready --timeout=300s --all certificates" \
		-t clusterissuers \
		-p "--for=condition=Ready --timeout=300s --all clusterissuers"; \
	kubectl get secret localcluster-selfsigned-ca-certificate --namespace $${namespace_name} -o yaml \
		| sed -E -e 's/name: .+/name: localcluster-selfsigned-ca-certificate-copy/' | kubectl apply -f -
	@echo ""

.PHONY: deploy-prometheus
deploy-prometheus: ## Deploy Prometheus Stack
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@echo "Using INGRESS_DOMAIN as $(INGRESS_DOMAIN)"; \
	namespace_name=monitoring; \
	chart=prometheus-community/kube-prometheus-stack; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set grafana.adminPassword=admin \
		--set grafana.ingress.enabled=true \
		--set grafana.ingress.hosts="{grafana.$(INGRESS_DOMAIN)}" \
		--set prometheus.ingress.enabled=true \
		--set prometheus.ingress.hosts="{prometheus.$(INGRESS_DOMAIN)}" \
		--set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.probeSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.scrapeConfigSelectorNilUsesHelmValues=false \
		prometheus $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

.PHONY: deploy-mariadb-operator-crds
deploy-mariadb-operator-crds: ## Deploy MariaDB Operator CRDs
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=mariadb-operator; \
	chart=mariadb-operator/mariadb-operator-crds; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		mariadb-operator-crds $${chart}
	@echo ""

.PHONY: deploy-mariadb-operator
deploy-mariadb-operator: ## Deploy MariaDB Operator
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=mariadb-operator; \
	chart=mariadb-operator/mariadb-operator; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		mariadb-operator $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

.PHONY: deploy-mariadb-instance
deploy-mariadb-instance: ## Deploy MariaDB Instance
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@kustomize build $(MANIFESTS_DIR)/mariadb-instance | kubectl apply -f -
	@namespace_name=$(shell sed -rn "s/namespace: (.*)/\1/p" $(MANIFESTS_DIR)/mariadb-instance/kustomization.yaml); \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments" \
		-t mariadbs \
		-p "--for=condition=Ready --timeout=300s --all pods"
	@echo ""

.PHONY: deploy-toolbox
deploy-toolbox: ## Deploy toolbox container
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=toolbox; \
	chart=tlbueno/toolbox; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set namespace.name=$${namespace_name} \
		toolbox $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods"
	@echo ""

.PHONY: deploy-redhat-operators-catalog
deploy-redhat-operators-catalog: ## Deploy RedHat Operators Catalog
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=olm; \
	chart=tlbueno/catalog-source-installer; \
	echo "Using catalog image: $(REDHAT_CATALOG_IMAGE)"; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set catalogSource.namespace=$${namespace_name} \
		--set catalogSource.image=$(REDHAT_CATALOG_IMAGE) \
		redhat-operators-catalog $${chart}; \
	sleep 20; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments" \
		-t pods \
		-p "--field-selector=status.phase!=Succeeded --for=condition=Ready --timeout=300s --all pods"
	@echo ""

.PHONY: deploy-artemiscloud-operator
deploy-artemiscloud-operator: ## Deploy ArtemisCloud Operator
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=$(ARTEMISCLOUD_NAMESPACE); \
	chart=tlbueno/artemiscloud-operator; \
	echo -n "Deploying chart $${chart} " && helm show chart $(ARTEMISCLOUD_CHART_VERSION_PARAM) $${chart} \
		| grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set operator.logLevel=$(ARTEMISCLOUD_LOG_LEVEL) \
		--set operator.watch.mode=$(ARTEMISCLOUD_WATCH_MODE) \
		$(ARTEMISCLOUD_WATCH_NAMESPACES_PARAM) \
		$(ARTEMISCLOUD_CHART_VERSION_PARAM) \
		artemiscloud-operator $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

.PHONY: deploy-chaos-mesh
deploy-chaos-mesh: ## Deploy Chaos Mesh
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@namespace_name=chaos-mesh; \
	chart=chaos-mesh/chaos-mesh; \
	echo -n "Deploying chart $${chart} " && helm show chart $${chart} |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --create-namespace --wait \
		--set chaosDaemon.runtime=$(CHAOS_MESH_CONTAINER_RUNTIME) \
		--set chaosDaemon.socketPath=$(CHAOS_MESH_CONTAINER_SOCKET_PATH) \
		chaos-mesh $${chart}; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods" \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments"
	@echo ""

#############################################
## Local configurations and tools targets ###
#############################################
.PHONY: configure-inotify
configure-inotify: ## Configure sysctl inotfy values for multiple kind nodes (requires sudo access)
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@echo "fs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/98-kind-inotify.conf > /dev/null
	@echo "fs.inotify.max_user_instances = 512" | sudo tee -a /etc/sysctl.d/98-kind-inotify.conf > /dev/null
	@sudo sysctl -p --system
	@echo ""

.PHONY: add-helm-charts-repos
add-helm-charts-repos: ## Add helm-charts repos do helm
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@echo "Adding ingress-nginx helm repo"
	@helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	@echo "Adding tlbueno helm repo"
	@helm repo add tlbueno https://tlbueno.github.io/helm-charts
	@echo "Adding jetstack helm repo"
	@helm repo add jetstack https://charts.jetstack.io
	@echo "Adding metrics-server helm repo"
	@helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
	@echo "Adding prometheus-community helm repo"
	@helm repo add prometheus-community	https://prometheus-community.github.io/helm-charts
	@echo "Adding mariadb-operator helm repo"
	@helm repo add mariadb-operator https://mariadb-operator.github.io/mariadb-operator
	@echo "Adding chaos-mesh helm repo"
	@helm repo add chaos-mesh https://charts.chaos-mesh.org
	@echo ""

.PHONY: update-helm-charts-repos
update-helm-charts-repos: ## Update helm-charts repos to helm
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@echo "updating helm repos"
	@helm repo update
	@echo ""

.PHONY: exec-toolbox
exec-toolbox: ## Execute a shell into the toolbox container
	@echo ""
	@echo "# Running $(@) #"
	@echo ""
	@kubectl -n toolbox exec toolbox-0 --stdin --tty -- bash -l
	@echo ""

####################
### Help targets ###
####################
.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\n"} \
		/^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-38s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[0m%s\033[0m\n", substr($$0, 5) } ' \
		$(MAKEFILE_LIST)

