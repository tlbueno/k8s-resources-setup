# single-instance
A artemis single instance deployment

Deploy command (executed from the project root directory):
```sh
kustomize build deployments/manifests/artemis/01-single-instance | kubectl apply -f -
```

---
NOTE:

If you are running in the local cluster using KinD deployed using the `create-kind` and `deploy-ingress-controller` you need to update the ingress to expose the acceptor ports of the instance to the host to be allowed to access it from the host. You may do it using the command below  from the project root directory, i.e: this command will expose the container 61610 port to the host 51510.:
```sh
deployments/bin/ingress-ngnix-expose-tcp-port.sh --src-port 51510 --namespace artemis-single-instance --dst-service artemis-all-0-svc --dst-port 61610
```

Another example is to expose java remote debug port 5005, ie:
```sh
deployments/bin/ingress-ngnix-expose-tcp-port.sh --src-port 51511 --namespace artemis-single-instance --dst-service debugger-svc --dst-port 5005
```
---

