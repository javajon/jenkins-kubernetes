#!/bin/sh

# This project was tested using:
#   Minikube v0.29.0
#   Kubernetes/KubeCtl v1.12.0
#   Helm v2.11.0

minikube start --cpus 4 --memory 8192 --disk-size 80g

helm init && helm repo update

minikube status
echo "$(minikube version) is now ready"

# echo "Be sure to now run this command: '. ./env.sh'"

# Troubleshooting:
# If Minikube does not start correctly, try wiping it clean with `minikube delete`,
# then run this script again. If this `does not help sometimes a deeper cleaning
# such as removing `~/.minikube`, `~/.kube` or `~/.virtualbox` may help.
