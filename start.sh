#!/bin/sh

# This project was tested using:
#   Minikube v0.29.0  (Versions 0.26.0 and 0.26.1 are not stable for this demonstration as Jenkins agent spawning does not occur)
#   Kubernetes/KubeCtl v1.12.0
#   Helm v2.11.0 (Helm 2.9 is unstable for this demo)

minikube start --cpus 4 --memory 8192 --disk-size 80g

helm init && helm repo update

minikube status
echo "$(minikube version) is now ready"

# echo "Be sure to now run this command: '. ./env.sh'"

# Troubleshooting:
# If Minikube does not start correctly, try wiping it clean with `minikube delete`,
# then run this script again. If this does not help sometimes a deeper cleaning
# such as removing `~/.minikube`, `~/.kube` or `~/.virtualbox` may help.
