# LAMP stack with Kubernetes and Docker

## Overview
  This template follows a common **LAMP** architecture in a **containerized environment**, orchestrated by **kubernetes**.
  The technical stack is interchangeable and the number of services can be scaled up / down in a similar way. The main goal is to have a step-by-step guideline for building projects in the most versatile way possible, following best practices.

- The current project is composed of:
  - **backend** - `Flask`
  - **frontend** - (**TODO...**)
  - **database** - `MongoDb`
  - **webserver** - `Nginx`
  - **separate worker** - (**TODO...**)

- Following these guidelines, we can:
  - Setup groundwork for new projects
  - Migrate monolith project to microservices
  - Orchestrate existing containerized project in a cloud agnostic architecture.

## Prerequisites

- Required packages:

  - python3-venv
  - Docker (version 20.10.20)
  - Docker Compose (version v2.3.3)
  - minikube (v1.27.1)
  - kubectl (Client Version: v1.20.4; Server Version: v1.25.2)
  - helm (v3.7.0)

- Minikube **started**
- Docker image created locally (otherwise when we create k8s deployment the pods will return `STATUS: ErrImagePull`)

## Quick local setup way. **The prerequisites must be met!**

  ```bash
  sh deploy.sh
  ```

  That's all and you should be good to go if you open **dev.k8s** in the browser.

  For more options use:
  ```bash
  sh deploy.sh -h
  ```

---
# Step by step guide
## Docker

- Obtain the minikube IP:
  ```bash
  $ minikube ip
  192.168.59.100
  ```
  In this case it's `192.168.59.100` and that's where the `DOCKER_HOST` will point to.
- Point the local docker to minikube
  ```bash
  minikube docker-env
  ```
- Copy the output and paste it in the shell. Example output:

  ```bash
  export DOCKER_TLS_VERIFY="1"
  export DOCKER_HOST="tcp://192.168.59.100:2376"
  export DOCKER_CERT_PATH="/home/abozhkov/.minikube/certs"
  export MINIKUBE_ACTIVE_DOCKERD="minikube"

  # To point your shell to minikube's docker-daemon, run:
  # eval $(minikube -p minikube docker-env)

  ```

- Create a new Dockerfile

  ```Dockerfile
  FROM python:3.10-alpine3.15
  WORKDIR /app
  COPY requirements.txt .
  RUN pip install -r requirements.txt
  COPY src src
  EXPOSE 5000
  HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=5 \
              CMD curl -f http://localhost:5000/health || exit 1
  ENTRYPOINT ["python", "./src/app.py"]
  ```

- Build new image with it it with a new tag `webapp:1.0`

  ```bash
  docker build -t webapp:1.0 .
  ```

- Create new container from the image, **that will run from minikube**

  ```bash
  docker run -d -p 80:5000 --name web webapp:1.0
  ```

## Docker Compose

- Create docker-compose.yaml file with the following content:

  ```yaml
  version: "3.9"
  services:
  web:
    build:
    context: .
    dockerfile: Dockerfile
    image: webapp:1.0
    ports:
      - "80:5000"
    restart: always
    networks:
      - webnet

  networks:
  webnet:
  ```

- Build and run the app from `docker compose` (`docker-compose` if you're using **v1**)
  ```bash
  docker compose build
  docker compose up -d
  ```

## Kubernetes (**k8s**)

- Basic local deployment `kubernetes_basics/` -> README.md
- Microservice based deployment `kubernetes/` -> README.md

## Helm (this example is only for kubernetes_basics)

- Create helm **chart** called `webapp` (with some edits to the auto-generated chart, for our specific setup)

  ```bash
  helm create webapp
  ```

- Create new template

  ```bash
  helm template webapp
  ```

- Install the generated helm template

  ```bash
  $ helm install web webapp/
  NAME: web
  LAST DEPLOYED: Fri Nov 18 16:25:39 2022
  NAMESPACE: default
  STATUS: deployed
  REVISION: 1
  TEST SUITE: None
  NOTES:
  1. Get the application URL by running these commands:
    export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services web-webapp)
    export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
    echo http://$NODE_IP:$NODE_PORT

  ```

- List the newly created pods and service

  ```bash
  $ kubectl get po,svc
  NAME                              READY   STATUS    RESTARTS   AGE
  pod/web-webapp-5bf8dc7b56-vwh2r   1/1     Running   0          46s
  pod/web-webapp-5bf8dc7b56-z5cbz   1/1     Running   0          46s

  NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
  service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        15d
  service/web-webapp   NodePort    10.111.17.41   <none>        80:31720/TCP   46s
  ```

- Uninstall the release
  ```bash
  $ helm uninstall web
  release "web" uninstalled
  ```
