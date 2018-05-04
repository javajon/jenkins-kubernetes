#!/bin/sh

# This project was tested using:
#   Minikube v0.25.2  (Versions 0.26.0 and 0.26.1 are not stable for this demonstration as Jenkins agent spawning does not occur)
#   Kubernetes/KubeCtl v1.9.4
#   Helm v2.8.2 (Helm 2.9 is unstable for this demo)

# Start minikube and ensure security for our demonstration container registry is off
# You may want to adjust the cpu and memory resources to work with your target machine
# minikube start --kubernetes-version v1.9.4 --cpus 4 --memory 8000 --disk-size 80g --insecure-registry '192.168.99.0/24' -p minikube-jenkins
minikube start \
-p minikube-jenkins \
--kubernetes-version v1.9.4 \
--cpus 4 \
--memory 8192 \
--disk-size 80g \
--insecure-registry '192.168.99.0/24' 

minikube profile minikube-jenkins

helm init && helm repo update

minikube status
echo "$(minikube version) is now ready"
echo "Be sure to now run this command: '. ./env.sh'"

# Troubleshooting:
# If Minikube does not start correctly, try wiping it clean with `minikube delete`,
# then run this script again. If this does not help sometimes a deeper cleaning
# such as removing `~/.minikube`, `~/.kube` or `~/.virtualbox` may help.
