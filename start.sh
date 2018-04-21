#!/bin/sh
#set -ex

# This project was tested using:
#   Minikube v0.25.2  (Currently, versions above this are not as stable. v0.26.1 does not work with this demo, e.g. agents do not start)
#   Kubernetes/KubeCtl v1.9.4
#   Helm v2.8.2

# Start minikube and ensure security for our demonstration container registry is off
# You may want to adjust the cpu and memory resources to work with your target machine
minikube start --kubernetes-version v1.9.4 --cpus 4 --memory 8000 --insecure-registry '192.168.99.0/24'

minikube status
echo "$(minikube version) is now ready"
echo "Be sure to now run this command: '. ./env.sh'"

# Troubleshooting:
# If Minikube does not start correctly, try wiping it clean with `minikube delete`,
# then run this script again. If this does not help sometimes a deeper cleaning
# such as removing `~/.minikube`, `~/.kube` or `~/.virtualbox` may help.
