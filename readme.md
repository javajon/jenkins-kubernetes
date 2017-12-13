# Jenkins on Kubernetes #

- Cattle, not pets
- Jenkins plugin for leveraging Kubernetes power - builds on pods.
- Leverage scaling
- Leverage monitoring
- Inspiration from Chris Ricci

## What will these following instructions do? ##

- Start a personal Kubernetes cluster
- Add a private Docker registry with a UI to Kubernetes 
- Add Prometheus, Alertmanager and Grafana to Kubernetes
- Using a stable Jenkins chart, install onto Kubernetes
- Canary deployment


## How do I get set up? ##

- Clone this project from GitHub
- Install [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) (or any other Kubernetes solution)
  <br>Try not to start Minikube, just install the CLI tool and VirtualBox. Below the start script will start it.
- Install Kubectl and verify `kubectl version` runs correctly
- From project root run `./start.sh`. This will provision a personal Kubernetes cluster for you.
- Install Helm

## Create Some Kubernetes Namespaces ##

`
kubectl create ns production && kubectl create ns monitoring-demo
`

## Installing Helm ##

Download the command line tool from here then run

```
helm init
helm repo update
```

to ensure the Tiller portion of Helm is install onto the cluster. This will take a minute before 
Tiller is available.

## Setup Monitoring ##

Change to the monitoring directory

`
cd k8s/monitoring/
`

Start Prometheus

`
kubectl create -n monitoring-demo -f .
`

Get the load balancer endpoint for Prometheus:
`
minikube service -n monitoring-demo prometheus-hello-world
`

## Setup Alert Manager ##

Change to alerting

`cd ../alerting/`

Create alert manager instance (Not Needed for 1.6.7)

`
kubectl create -n monitoring-demo -f hello-world-alert-manager.yaml
`

Create the Alert Manager Service (Not Needed for 1.6.7)

`
kubectl create -n monitoring-demo -f hello-world-alert-manager-service.yaml
`

Create alert manager secret

`
kubectl create -n monitoring-demo secret generic alertmanager-helloworld --from-file=alertmanager.yaml
`

Create Alert Manager latency rule

`
kubectl create -n monitoring-demo -f alertmanager-latency-rule.yaml
`

## Installing Jenkins ##

A growing list of public stable charts are available and can be seen with this listing command:

`helm search stable`

To install the stable Jenkins chart use helm to reference the chart.

`
helm --namespace jenkins --name jenkins -f ./jenkins-values.yaml install stable/jenkins
`

You can verify Jenkins is starting with this Kubernetes introspection command:

`
kubectl get deployments,pods -n jenkins
`

Run this command until the deployment changges the available status from 0 to 1. This will 
take a few minutes.

There will now be a Jenkins service running that you can access through a kubernetes NodePort. 
To see the list of available services type:

`minikube service list`

Look for the Jenkins service in the namespace "jenkins" and ask Minikube to point your default
browser to the Jenkins UI with this:

`minikube service -n jenkins jenkins-jenkins`

For demonstration purposes the Jenkins user name and password is admin/admin as 
defined in the jenkins-values.yaml file.

Also in the jenkins-values.yaml file is a list of defined plugins. Through the UI verify those plugins
are present.

## Create a Quay Repo ##

Create a repo in Quay called "hello-world-instrumented" and assign a robot
account to the repo with write access. Next, copy the token to a file called 
quay-robot-token.txt and place it in your home directory.

## Configure Jenkins ##

Change docker image to: radumatei/jenkins-slave-docker:kubectl
Add a Container Environment variable: quay_username: jonathan_johnson+robot
Add a Container Environment variable: quay_password: (credentials from robot account)

## Connection to Deployed Application ##

minikube service list will show a service that exposes two URLs as NodePorts.

`
kubectl get svc hello-world -n monitoring-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
`

With curl hit the first port a few times to get the Hello World response. Then curl the next port
to get the metrics report. This is the same metrics url that Prometheus will scrape.


## Acknowledgments ##
A special thank you the inspiration and skeleton for this tutorial from [Chris Ricci](https://github.com/cricci82) at CoreOS.
Inspiration also from [Lachlan Evenson](https://github.com/lachie83/croc-hunter) with an helpful and [instructional video](https://youtu.be/eMOzF_xAm7w