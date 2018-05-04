#!/bin/sh
set -ex
    
# Roadmap: Perhaps an unbrella chart for this instead of a script
kubectl create namespace monitoring

helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/

helm install coreos/prometheus-operator --wait --name prometheus-operator --namespace monitoring --set rbacEnable=false
helm install coreos/kube-prometheus     --wait --name kube-prometheus     --namespace monitoring --set global.rbacEnable=false

kubectl patch service kube-prometheus-prometheus   --namespace=monitoring --type='json' -p='[{"op": "replace",  "path": "/spec/type", "value":"NodePort"}]'
kubectl patch service kube-prometheus-alertmanager --namespace=monitoring --type='json' -p='[{"op": "replace",  "path": "/spec/type", "value":"NodePort"}]'
kubectl patch service kube-prometheus-grafana      --namespace=monitoring --type='json' -p='[{"op": "replace",  "path": "/spec/type", "value":"NodePort"}]'

minikube service list -n monitoring
