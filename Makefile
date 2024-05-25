#
### make variables
SHELL                         = /usr/bin/env bash
.SHELLFLAGS                   = -o pipefail -e -c

# root project variables 
ROOT_DIR                      = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BIN_DIR                       = $(ROOT_DIR)/bin

### Local cluster variables
K8S_VERSION                   =           	# if empty kind uses the latest version available on for the installed kind version
KIND_CLUSTER_NAME             = local-k8s

INGRESS_DOMAIN                = localdev

ifdef REDHAT_CATALOG_IMAGE
    $(eval REDHAT_CATALOG_IMAGE_PARAM = "${REDHAT_CATALOG_IMAGE}")
endif

all: help

#############################
### local cluster targets ###
#############################
.PHONY: prepare-k8s
prepare-k8s: add-helm-charts-repos update-helm-charts-repos deploy-ingress-controller deploy-olm deploy-metrics-server deploy-cert-manager-operator deploy-trust-manager-operator deploy-prometheus deploy-toolbox ## Deploy the resource for kubernetes cluster

.PHONY: prepare-ocp
prepare-ocp: add-helm-charts-repos update-helm-charts-repos deploy-cert-manager-operator deploy-trust-manager-operator deploy-prometheus deploy-toolbox ## Deploy resources for openshift cluster

.PHONY: create-kind
create-kind: ## Create Kind cluster
	@if [ ! "$(shell kind get clusters | grep $(KIND_CLUSTER_NAME))" ]; then \
		tempfile=$(shell mktemp); \
		cat local-cluster/kind-config.yaml | envsubst > $${tempfile}; \
		if [ "$(K8S_VERSION)" != "" ]; then \
			image_flag="--image kindest/node:$(K8S_VERSION)"; \
		fi; \
		kind create cluster --name=$(KIND_CLUSTER_NAME) --config $${tempfile} $${image_flag} --wait 180s; \
		kubectl wait pod --all -n kube-system --for condition=Ready --timeout 180s; \
		rm $${tempfile}; \
	else \
		echo "Kind cluster $(KIND_CLUSTER_NAME) already exists"; \
	fi
	@echo ""

.PHONY: delete-local-cluster
delete-local-cluster: ## delete local cluster
	@if [ "$(shell kind get clusters | grep $(KIND_CLUSTER_NAME))" ]; then \
		kind delete cluster --name=$(KIND_CLUSTER_NAME) || true; \
	fi

######################################
### Cluster additional deployments ###
######################################
.PHONY: deploy-ingress-controller
deploy-ingress-controller: ## Deploy Ingress controller in the cluster
	@echo "#####################################"
	@echo "# Running deploy-ingress-controller #"
	@echo "#####################################"
	@namespace_name=ingress-nginx; \
	kubectl create namespace $${namespace_name} || true; \
	echo -n "Deploying chart " && helm show chart ingress-nginx/ingress-nginx |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace default --wait \
		--set namespaceOverride=$${namespace_name} \
		--set controller.extraArgs.enable-ssl-passthrough= \
		--set controller.allowSnippetAnnotations=true \
		--set controller.ingressClassResource.default=true \
		--values https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/hack/manifest-templates/provider/kind/values.yaml \
		ingress-nginx ingress-nginx/ingress-nginx; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=90s pod --selector=app.kubernetes.io/component=controller"
	@echo ""

.PHONY: deploy-metrics-server
deploy-metrics-server: ## Deploy Kubernetes Metric Server
	@echo "################################"
	@echo "# Running deploy-metrics-server #"
	@echo "################################"
	@namespace_name=kube-system; \
	echo -n "Deploying chart " && helm show chart metrics-server/metrics-server |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace $${namespace_name} --wait \
		--set args={--kubelet-insecure-tls} \
		metrics-server  metrics-server/metrics-server; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments" \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods"
	@echo ""

.PHONY: deploy-olm
deploy-olm: ## Deploy Operator Lifecycle Manager (OLM) in the cluster
	@echo "#######################"
	@echo "# Running deploy-olm #"
	@echo "#######################"
ifndef OLM_VERSION
	$(eval OLM_VERSION = $(shell curl -s https://api.github.com/repos/operator-framework/operator-lifecycle-manager/releases/latest | jq -cr .tag_name))
endif
	@echo "Deploying OLM version ${OLM_VERSION}"
	@tempfile=$(shell mktemp); \
	curl -sSL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/$(OLM_VERSION)/install.sh -o $${tempfile}; \
	chmod +x $${tempfile}; \
	$${tempfile} $(OLM_VERSION); \
	rm $${tempfile}
	@echo "############################################################"
	@echo "# Removing pod security enforcement from olm namespace     #"
	@echo "# this is needed because redhat-operator-index requires it #"
	@echo "############################################################"
	@namespace_name=olm; \
	kubectl label --overwrite ns $${namespace_name} pod-security.kubernetes.io/enforce=privileged; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments" \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods"
	@echo ""

.PHONY: deploy-cert-manager-operator
deploy-cert-manager-operator: ## Deploy Cert Manager Operator
	@echo "########################################"
	@echo "# Running deploy-cert-manager-operator #"
	@echo "########################################"
	@namespace_name=cert-manager; \
	echo -n "Deploying chart " && helm show chart tlbueno/olm-operator-installer |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace default --wait \
		--set namespace.name=$${namespace_name} \
		cert-manager tlbueno/olm-operator-installer; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments" \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods"
	@echo ""

.PHONY: deploy-trust-manager-operator
deploy-trust-manager-operator: ## Deploy Trust Manager Operator
	@echo "#########################################"
	@echo "# Running deploy-trust-manager-operator #"
	@echo "#########################################"
	@namespace_name=cert-manager; \
	echo -n "Deploying chart " && helm show chart jetstack/trust-manager |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace default --wait \
		--set namespace=$${namespace_name} \
		trust-manager jetstack/trust-manager; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments" \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods"
	@echo "" 

.PHONY: deploy-prometheus
deploy-prometheus: ## Deploy Prometheus Stack
	@echo "#############################"
	@echo "# Running deploy-prometheus #"
	@echo "#############################"
	@namespace_name=monitoring; \
	kubectl create namespace $${namespace_name} || true; \
	echo -n "Deploying chart " && helm show chart tlbueno/toolbox |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace default --wait \
		--set namespaceOverride=$${namespace_name} \
		--set grafana.namespaceOverride=$${namespace_name} \
		--set grafana.adminPassword=admin \
		--set grafana.ingress.enabled=true \
		--set grafana.ingress.hosts="{grafana.$(INGRESS_DOMAIN)}" \
		--set prometheus.ingress.enabled=true \
		--set prometheus.ingress.hosts="{prometheus.$(INGRESS_DOMAIN)}" \
		--set kube-state-metrics.namespaceOverride=$${namespace_name} \
		--set prometheus-node-exporter.namespaceOverride=$${namespace_name} \
		prometheus prometheus-community/kube-prometheus-stack; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments" \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods"
	@echo ""

.PHONY: deploy-toolbox
deploy-toolbox: ## Deploy toolbox container
	@echo "##########################"
	@echo "# Running deploy-toolbox #"
	@echo "##########################"
	@namespace_name=tools; \
	echo -n "Deploying chart " && helm show chart tlbueno/toolbox |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace default --wait \
		--set namespace.name=$${namespace_name} \
		toolbox tlbueno/toolbox; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t pods \
		-p "--for=condition=Ready --timeout=300s --all pods"
	@echo "" 

.PHONY: deploy-redhat-operators-catalog
deploy-redhat-operators-catalog: ## Deploy RedHat Operators Catalog
	@echo "###########################################"
	@echo "# Running deploy-redhat-operators-catalog #"
	@echo "###########################################"
	@namespace_name=olm; \
	echo -n "Deploying chart " && helm show chart tlbueno/catalog-source-installer |grep -E "(^version|^appVersion)" | sort -r | paste -sd ' '; \
	helm install --namespace default --wait \
		--set catalogSource.namespace=$${namespace_name} \
		$(REDHAT_CATALOG_IMAGE_PARAM) \
		redhat-catalog-source tlbueno/catalog-source-installer; \
	$(BIN_DIR)/kubectl-wait-wrapper.sh -n $${namespace_name} \
		-t deployments \
		-p "--for=condition=Available --timeout=300s --all deployments" \
		-t pods \
		-p "--field-selector=status.phase!=Succeeded --for=condition=Ready --timeout=300s --all pods" -d
	@echo ""

#############################################
## Local configurations and tools targets ###
#############################################
.PHONY: configure-inotify
configure-inotify: ## Configure sysctl inotfy values (requires sudo access)
	@echo "#############################"
	@echo "# Running configure-inotify #"
	@echo "#############################"
	@echo "fs.inotify.max_user_watches = 524288" | sudo tee /etc/sysctl.d/98-kind-inotify.conf > /dev/null
	@echo "fs.inotify.max_user_instances = 512" | sudo tee -a /etc/sysctl.d/98-kind-inotify.conf > /dev/null
	@sudo sysctl -p --system
	@echo "" 

.PHONY: add-helm-charts-repos
add-helm-charts-repos: ## Add helm-charts repos do helm
	@echo "#################################"
	@echo "# Running add-helm-charts-repos #"
	@echo "#################################"
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
	@echo ""

.PHONY: update-helm-charts-repos
update-helm-charts-repos: ## Update helm-charts repos to helm
	@echo "####################################"
	@echo "# Running update-helm-charts-repos #"
	@echo "####################################"
	@echo "updating helm repos"
	@helm repo update
	@echo ""

.PHONY: exec-toolbox
exec-toolbox: ## Execute a shell into the toolbox container
	@echo "##########################"
	@echo "# Running exec-toolbox #"
	@echo "##########################"
	@kubectl -n tools --stdin --tty exec toolbox -- bash -l
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

