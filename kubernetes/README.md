# Kubernetes

- Helpful articles:
  - [Running a Python Application on Kubernetes](https://medium.com/avmconsulting-blog/running-a-python-application-on-kubernetes-aws-56609e7cd88c)
  - [Deploy a flask application with nginx on kubernetes](https://www.kisphp.com/kubernetes/deploy-a-flask-application-with-nginx-on-kubernetes)
  - [Deploy your first Flask+MongoDB app on Kubernetes](https://levelup.gitconnected.com/deploy-your-first-flask-mongodb-app-on-kubernetes-8f5a33fa43b4)
  - [DOCKER : KUBERNETES MINIKUBE INSTALL ON AWS EC2](https://www.bogotobogo.com/DevOps/Docker/Docker-Kubernetes-Minikube-install-on-AWS-EC2.php)

## Prerequisites

- Comprehensive understanding of kubernetes basics, from `kubernetes_basics/`

## Create docker images in your local minikube

- Point the local docker to minikube (`minikube docker-env`)
- Create images in the local minikube storage:

  - **flask** service image - `flaskapp:1.0`
  - **mongo** service image - `mongo` (pulled from dockerhub)
  - **nginx** service image - `nginx` (pulled from dockerhub)

## Free the required ports and create mock domain

- Make sure that port **:80** on the localhost is available. Turn off any running nginx or apache services from systmctl

- Add the minikube ip to your `/etc/hosts` (we can change to whatever we want as long as we edit the `ingress,yaml`), to avoid using the minikube ip and instead have environment representing a real production as close as possible.
  ```bash
  sudo bash -c "echo \"$(minikube ip) dev.k8s\" >> /etc/hosts"
  ```

## MongoDB service - **mongo**

- Create `PersistentVolume` for MongoDB

  ```bash
  kubectl apply -f kubernetes/mongo-pv.yaml
  ```

  This creates a storage volume of 256 MB that is to be made available to the mongo container. The contents of this volume persist, even if the MongoDB pod is deleted or moved to a different node.

- Create `PersistentVolumeClaim` for the mongo service

  ```bash
  kubectl apply -f kubernetes/mongo-pvc.yaml
  ```

  This is used to claim/obtain the storage created above and can be mounted on the mongo container.

- Create the deployment and service

  ```bash
  kubectl apply -f kubernetes/mongo.yaml
  ```

  - The deployment creates a single instance of MongoDB server. Here, we expose the port **27017** which can be accessed by other pods. The persistent volume claimed can be mounted onto a directory on the container.
  - The service is of type `ClusterIP`(default type of Service in Kubernetes). This service makes the **mongo** pod accessible from within the cluster, but not from outside. The only resource that should have access to the MongoDB database is our app.

## Flask and Nginx services - **flask** & **nginx** in the same pod

- Create `ConfigMap` for **flask** and **nginx**

  ```bash
  kubectl apply -f kubernetes/flask-cfg.yaml
  ```

  We create two configurations maps. One for the flask application and one for the nginx container.

- Create `Ingress`

  ```bash
  kubectl apply -f kubernetes/flask-ing.yaml
  ```

  The ingress configuration will be used to access our application in the browser under the `http://dev.k8s/` url

- Create deployment and services

  ```bash
  kubectl apply -f kubernetes/flask.yaml
  ```

  For a better understanding of what happens here, when you make a request to the url **http://dev.k8s/**, the browser will make a request to the minikube instance and will match the ingress with the url defined earlier which will connect to the flask service which will connect to the **nginx** container in the running pod of the **flask** application.

## Local development

- Building the whole project locally, using the `deploy.sh`

  ```bash
  sh deploy.sh
  ```

- Updating latest changes by rebuilding the image and restarting the running pods we can use the `-r` or `--rebuild` flag for the `deploy.sh`. If no name is provided the image name will default to **flaskapp:1.0**

  ```bash
  sh deploy.sh -r <image_name>
  ```

- Tear down the whole local project

  ```bash
  sh deploy.sh -d
  ```

- For more options use:
  ```bash
  sh deploy.sh -h
  ```
