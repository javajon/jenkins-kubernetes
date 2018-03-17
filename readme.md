# Jenkins on Kubernetes

The demonstration covers these primary topics:

- Standing up a personal cluster
- Installing and configuring Jenkins from a Helm chart
- Jenkins plugin for leveraging Kubernetes power - builds on pods
- Roadmap: Leverage scaling
- Roadmap: Canary deployments
- Roadmap: Leverage monitoring


## What will these following instructions do?

- Start a personal Kubernetes cluster
- Create a Quay.io robot account and copy the credentials
- Install Jenkins on the cluster
- Configure Jenkins to leverage Kubernetes
- Create a pipeline that builds on and publishes to Kubernetes
- Roadmap: Add Prometheus-Operator monitoring stack from Helm charts
- Roadmap: Observe monitoring of a deployed container
- Roadmap: See how canary deployments work with this workflow


## How do I get set up?

- Clone this project from GitHub
- Install [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)
  (or any other Kubernetes solution) <br>Try not to start Minikube, just
  install the CLI tool and VirtualBox. Below the start script will start it.
- Install Kubectl and verify `kubectl version` runs correctly
- From project root run `./start.sh`. This will provision a personal Kubernetes cluster for you.


## Installing Helm

Download the command line tool by following this
[Quickstart guide](https://docs.helm.sh/using_helm/).
With the command line tool run:

```
helm init
helm repo update
```

to ensure the Tiller portion of Helm is install onto the cluster. This will
take a few moments before Tiller is available.


## Setup Monitoring (Optional)

Roadmap: At this moment this demonstration has not incorporated the monitoring
aspect of the canary deploys that happen below. But if you wish you can Setup
monitoring. Its best to follow the Prometheus-Operator setup as described in then
readme in [this repo](https://github.com/javajon/monitoring-kubernetes).  Part of
this is monitoring the latency of the helloworld service deployed below.  

```
kubectl create -n monitoring-demo -f alertmanager-latency-rule.yaml
```


## Installing Jenkins

A growing list of public stable charts are available and can be seen with this
listing command:

```
helm search stable
```

To install the stable Jenkins chart use helm to reference the chart.

```
helm install stable/jenkins --namespace jenkins --name jenkins -f ./jenkins-values.yaml
```

You can verify Jenkins is starting with this Kubernetes introspection command:

```
kubectl get deployments,pods -n jenkins
```

Run this command until the deployment changes the available status from
0 to 1. This will take a few minutes.

There will now be a Jenkins service running that you can access through a
Kubernetes NodePort. To see the list of available services type:

```
minikube service list
```

Look for the Jenkins service in the namespace "jenkins" and ask Minikube to
point your default browser to the Jenkins UI with this:

```
minikube service -n jenkins jenkins
```

For demonstration purposes the Jenkins user name and password is admin/admin
as defined in the jenkins-values.yaml file.

Also, in the jenkins-values.yaml file is a list of defined plugins. Through
the UI verify those plugins are present.


## Create a Quay.io Repo

Obtain a free account on Quay.io. Create a repository on Quay.io called
"hello-world-instrumented" and assign a robot account to the repo with write
access. Next, copy the token to a file called quay-robot-token.txt and place
it in your home directory. You will use this robot account and this generated
secret token in the next step.


## Configure Jenkins

From Jenkins main page:

1. Select "Manage Jenkins"
1. Select "Configure System"
1. Near the top of the page/form under "Global properties"
1. "Environment variables" and select Add.
1. Add environment variable: quay_username: jonathan_johnson+robot
1. Add environment variable: quay_password: 494WVD9UVCG5CSVXP8CFTA2KLZK3QZV0BP6HK38ZFNPYYE0BPAQT4VUIKQ4IFPCS
Your Quay.io robot account name and secret will be different.
1. Because the Kubernetes plugin is present (defined in jenkins-values.yaml) this
for includes a Cloud | Kubernetes section. Scroll down to the Pod's
"Container Template" and change "Docker image" from: jenkins/jnlp-slave:3.10-1
to: `radumatei/jenkins-slave-docker:kubectl`
1. Click Save.

The jenkins-slave-docker:kubectl Docker container image contains the KubeCtl CLI
command application that the Jenkinsfile in Hello-World-Instrumented will call.
The Jenkinsfile handles the compiling, Docker image building, deploying and
canary deployment logic.


## Create Jenkins Pipeline for Hello-World-Instrumented project

From Jenkins main page:

1. Select "New Item"
1. Enter name "Python-API-k8s-Pipeline"
1. Select "Pipeline", click OK
1. In Poll SCM field enter * * * * * - to poll every minute
1. In Pipeline section below select "Pipeline script from SCM"
1. From SCM dropdown select Git.
1. For the Repository URL enter: https://github.com/javajon/hello-world-instrumented


## Run the pipeline manually the first time

1. Click 'Build Now'
1. View build console output and notice its waiting for container agent
1. Agent appears in Jenkins main
1. Go to Minikube dashboard and observe Jenkins agent container spinning up


## Connection to Deployed Application

The Minikube service list will show a service that exposes two URLs as NodePorts.

```
minukube service list -n monitoring-demo
```
The helloworld application should be exposed in the monitoring-demo namespace.
Two NodePorts are exposed, one for the service response and one for the service
metric response. This is the same metrics URL that Prometheus will scrape.


## Acknowledgments
- A special thanks to the inspiration and skeleton for this tutorial from
[Chris Ricci](https://github.com/cricci82) at CoreOS (now RedHat).
- Inspiration also from [Lachlan Evenson](https://github.com/lachie83/croc-hunter)
with an helpful and [instructional video](https://youtu.be/eMOzF_xAm7w
