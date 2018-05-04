# Canary Releases on Kubernetes

This demonstration covers these topics:

- A personal Kubernetes cluster with Minikube
- Install and configure Jenkins from Helm chart
- Installing Prometheus from Helm chart
- Demonstrating Kubernetes plugin for Jenkins
- Build, deploy and run container from Jenkinsfile
- Update container with canary deployment
- Monitoring canary deployments
- Rollback canary

> Canary release is a technique to reduce the risk of introducing a new software version in production by slowly rolling out the change to a small subset of users before rolling it out to the entire infrastructure and making it available to everybody.
- [MartinFowler.com](https://martinfowler.com/bliki/CanaryRelease.html)

## Instructions Overview

- Start a personal Kubernetes cluster
- Create a Quay.io robot account and copy the credentials
- Install Jenkins on the cluster
- Configure Jenkins to leverage Kubernetes
- Create a pipeline that builds on and publishes to Kubernetes
- Roadmap: Add Prometheus-Operator monitoring stack from Helm charts
- Roadmap: Observe monitoring of a deployed container
- Roadmap: See how canary deployments work with this workflow

------------

## Setup

### Install

1. Clone these two projects from GitHub
    - [jenkins-kubernetes](https://github.com/javajon/jenkins-kubernetes)
    - [hello-world-instrumented](https://github.com/javajon/hello-world-instrumented)
1. Install [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) (or any other Kubernetes cluster)
1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) command line tool for Kubernetes
1. Install [Helm](https://docs.helm.sh/using_helm/), a package manager for Kubernetes based applications

### Start

1. Start Minikube with Helm: From project root run `./start.sh`. This will provision a personal Kubernetes cluster.
1. Verify `minikube status` and `kubectl version` and `helm version` run correctly

------------

## Monitoring

### Setup Monitoring (Optional)

For a canary deployment monitoring the performance and behavior of newly deployed containers is important to inspect before deciding to either promote the new version, or rolling it back. Containers can be monitored with Prometheus. There is a stable Helm chart that installs a Prometheus operator and some opinionated configurations on top of that. To install and configure the Prometheus stack run these 3 commands:

``` sh
curl https://raw.githubusercontent.com/javajon/monitoring-kubernetes/master/configurations/deploy-prometheus-stack.sh | bash -s
```

Roadmap: Need to add ServiceMonitor for scraping the hello-world metrics. For now metrics can be largely seen at the node CPU and memory metrics. Consider these two declarations

``` sh
kubectl create -n monitoring -f monitoring.yaml
kubectl create -n monitoring -f alertmanager-latency-rule.yaml
```

The above script includes a wait command, so it will take a few minutes for it to complete.

Below are instructions that configure Prometheus to watch for performance of the upcoming hello-world deployments. But first, let's get a Jenkins pipeline to build, deploy and install the hello-world application.

------------

## Jenkins

### Install Jenkins on Kubernetes

A growing list of public stable charts are available and can be seen with this listing command `helm search stable`. To start Jenkins use Helm to install the stable/Jenkins chart.

``` sh
helm install stable/jenkins --namespace jenkins --name jenkins -f ./jenkins-values.yaml
```

The jenkins-values.yaml file includes details for the Jenkins configuration to ensure it starts with all the appropriate plugins, along with its Kubernetes plugin. The Jenkins chart also installs a definition for a custom container for running Jenkins jobs. The jenkins-slave-docker:kubectl Docker container image contains the KubeCtl CLI application that the Jenkinsfile in hello-world-instrumented will call. The Jenkinsfile handles the compiling, Docker image building, deploying and canary deployment logic.

Next, give the plugin and access to Quay credentials. Later, when a pipeline runs, it will access Quay through the credentials. The credentials are supplied as a secret and the Jenkinsfile code access the secret credentials using Kubectl commands. The Jenkins agent running the Jenkinsfile job has access to Docker and Kubectl. To register the Quay credentials add this secret:

``` sh
kubectl -n jenkins create -f quay-secret.yaml
```

Verify Jenkins is starting with this Kubernetes introspection command:

``` sh
kubectl get deployments,pods -n jenkins
```

Run this command until the deployment changes the *Available* status from 0 to 1. This will take a few minutes.

There will now be a Jenkins service running that you can access through a Kubernetes NodePort. List the available services with this:

``` sh
minikube service list
```

Look for the Jenkins service in the namespace `jenkins` and ask Minikube to point your default browser to the Jenkins UI with this:

``` sh
minikube service -n jenkins jenkins
```

In the jenkins-values.yaml file is a list of defined plugins. Through the Jenkins dashboard observe those plugins are present.

### Verify Jenkins with Kubernetes

Here is an example test pipeline script that inspects environment variables and uses KubeCtl commands to manipulate Kubernetes. Create a pipeline in Jenkins, paste this script and build the pipeline. View the logs to see the previously submitted secret Quay credentials.

``` bash
node {
  stage ('Inspections') {

    sh('env > env.txt')
    sh('cat env.txt')

    sh('kubectl get secret quay -o yaml -n jenkins')

    def quayUserName = sh(script:"kubectl get secret quay -n jenkins -o=jsonpath='{.data.username}' | base64 -d", returnStdout: true)
    def quayPassword = sh(script:"kubectl get secret quay -n jenkins -o=jsonpath='{.data.password}' | base64 -d", returnStdout: true)

    echo "Quay access: ${quayUserName} / ${quayPassword}"
  }
}
```

This pipeline will take a few minutes to startup and run. Through the Kubernetes dashboard observe how a new pod is created in the jenkins namespace by the Jenkins Kubernetes plugin. To verify this pipeline success, inspect the build's console output and verify at the end the "Quay access:" line reports the Quay secret credentials.

------------

## Canary Deployment

Now, this starts to get really interesting. So far you have Kubernetes running with Prometheus monitoring and Jenkins.

> To demonstrate, a simple web application is used. Its GitHub repo two branches: production and canary. Using a Jenkins Pipeline, when changes are committed to the canary branch a build will be triggered and the new version will be rolled out to all replicas in the canary deployment. Once the change is validated, usually via some automated testing and health checks, changes are pushed to the production branch that will trigger the Jenkins Pipeline to update all deployments in the production deployment. - Chris Ricci

Next, add a new pipeline based on a Jenkinsfile that can orchestrate the building and deployment.

### Create a Jenkins Pipeline

Navigate to the main Jenkins page:

``` sh
minikube service -n jenkins jenkins
```

From Jenkins main page:

1. Select "New Item"
1. Enter name "Canary Example"
1. Select "Pipeline", click OK
1. In Pipeline section below select "Pipeline script from SCM"
1. From SCM dropdown select Git
1. For the Git repository URL enter:

``` sh
https://github.com/javajon/hello-world-instrumented
```

### Initial Pipeline Run

1. The build will start within a minute, or click 'Build Now'
1. View build console output and notice the job is waiting for container agent
1. Agent appears in Jenkins main
1. Go to the Minikube dashboard and observe the Jenkins agent container spinning up

### Verify Hello-world

Once the Jenkins pipeline completes successfully, a very simple Python application is deployed. The service is instrumented to serve metrics using the [Prometheus instrumentation library for Python](https://github.com/prometheus/client_python).

The application is served on port 5000, via an exposed NodePort:

``` sh
SERVICE=http://$(minikube ip):$(kubectl get svc hello-world -n monitoring-demo -o jsonpath="{.spec.ports[?(@.name=='web')].nodePort}")
curl $SERVICE
or
while true; sleep .3; do curl -s $SERVICE; done
```

and the metrics are served on 8000, via an exposed NodePort 1:

``` sh
METRICS=http://$(minikube ip):$(kubectl get svc hello-world -n monitoring-demo -o jsonpath="{.spec.ports[?(@.name=='metrics')].nodePort}")
curl $METRICS
```

Exercise the service at port 5000 a few times with curl or from a browser to generate some metrics.

``` sh
while true; sleep .3; do curl $SERVICE; done;
```

This command will point your default browser to the observable metrics:

``` sh
start http://$(minikube ip):$(kubectl get svc hello-world -n monitoring-demo -o jsonpath='{.spec.ports[1].node Port}{"\n"}')
```

### Exercise Deployed Application

The Minikube service list will show a service that exposes two URLs as NodePorts.

``` sh
minikube service list -n monitoring-demo
```

The hello-world application is in the monitoring-demo namespace. Each services has two NodePorts exposed, one for the service response and one for the metrics response. This is the metrics URL that Prometheus is currently scraping.

``` sh
kubectl get pods -n monitoring-demo
```

Notice that behind the service are 3 instances of the service running, 2 production and 1 canary.

------------

### Technology stack

This demonstration was performed with these tools. Newer versions may exist.

- VirtualBox 5.8
- Minikube 0.25.2 (with Kubernetes 1.9.4)
- Kubectl 1.10.0
- Helm 2.8.2
- Prometheus Operator
- Kube-Prometheus (Alertmanager + Grafana)
- Python
- See jenkins-value.yaml file for Jenkins version and its plugins

### Presentation short instructions

| Step                       | Command
|----------------------------|---------
| Fresh Minikube             | `minikube delete`
| Initialize                 | `./start.sh`
| CLI env                    | `. ./env.sh`
| Monitoring stack           | curl https://raw.githubusercontent.com/javajon/monitoring-kubernetes/master/configurations/deploy-prometheus-stack.sh | bash -s
| Deploy Jenkins             | `helm install stable/jenkins --namespace jenkins --name jenkins -f ./jenkins-values.yaml`
| Add Quay secret            | `kubectl -n jenkins create -f quay-secret.yaml`

### References

[Canary deployments](
https://whatis.techtarget.com/definition/canary-canary-testing)
[Jenkins stable Helm chart](https://github.com/kubernetes/charts/tree/master/stable/jenkins)
[Kubernetes plugin for Jenkins](https://github.com/jenkinsci/kubernetes-plugin)
[Jenkins agent with Docker and Kubectl](https://github.com/radu-matei/jenkins-slave-docker)

### Acknowledgments

- A special thanks to the inspiration for this tutorial from [Chris Ricci](https://github.com/cricci82) at CoreOS (now RedHat).
- This demonstration is based on Chris Ricci and Duffie Cooley, []*Continuous Deployment and Monitoring with Tectonic, Prometheus, and Jenkins*](https://www.brighttalk.com/webcast/14601/267207/continuous-deployment-and-monitoring-with-tectonic-prometheus-and-jenkins) presentation found here on BrightTALK. Starts at the 24:15 mark.

### Etcetera

- Instructional video: [Lachlan Evenson's](https://github.com/lachie83/croc-hunter) demonstration [Zero to Kubernetes CI/CD in 5 minutes with Jenkins and Helm](https://youtu.be/eMOzF_xAm7w)
- Instructional video: [Continuously delivering apps to Kubernetes using Helm - Adnan Abdulhussein (Bitnami)](https://youtu.be/CmPK93hg5w8)
- [Jenkins Slave with Docker client and kubectl CLI](https://github.com/radu-matei/jenkins-slave-docker)
