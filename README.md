# LAMP stack with Kubernetes and Docker
  Building project **locally**, that will be in a pre-production state. And potentially ready for deployment in a cloud environment.<br />
  **Each section (`deployment/`, `helm/`, `kubernetes/`) has step-by-step documentation.**<br />
  There is basic kubernetes setup, using **Helm** (`helm/`).<br />
  The deployment process covers:
  - **EKS** (`deployment/eks`)

## Overview
  This template follows a **MVC** architecture in a **containerized environment**, orchestrated by **kubernetes**.
  The technical stack is interchangeable and the number of services can be scaled up / down in a similar way. The main goal is to have a step-by-step guideline for:
  - Understadning the basics of `Kubernetes`
  - Understanding `Docker` and `Docker compose` and how they interact with `Kubernetes`
  - Building projects (localy) in the most versatile way possible, following best practices.
  - Migrate monolith project to microservices
  - Orchestrate existing containerized project in a cloud agnostic architecture.

## Prerequisites

- Required packages:
  - Docker (version 20.10.20)
  - Docker Compose (version v2.3.3)
  - minikube (v1.27.1)
  - kubectl (Client Version: v1.20.4; Server Version: v1.25.2)
  - (optional) helm (v3.7.0)

## Quick local setup. **The prerequisites must be met!**

  ```bash
  sh deploy.sh
  ```

  That's all and you should be good to go if you open **dev.k8s** in the browser.

  For more options use:
  ```bash
  sh deploy.sh -h
  ```

## Project structure

- `Codebase` - This is the main portion and the lowest level of abstraction that we have. Our value comes from here and our goal is to use it in the most optimal, stable, scalable and versatile way possible. To achieve this we have to separate each main component into it's own `service`, in order to manage them and the communication between them in the best way possible. The current project is composed of the following services:
  - `backend` - **Flask**
  - `frontend` - **Vue**
  - `database` - **MongoDb**
  - `webserver` - **Nginx**
---
- `Containerization` -
  This is our second level of abstraction. Containers are a streamlined way to build, test, deploy, and redeploy applications on multiple environments from a developer’s local laptop to an on-premises data center and even the cloud. Benefits of containers include:
    - Less overhead - containers require less system resources than traditional or hardware virtual machine environments because they don’t include operating system images.
    - Increased portability - applications running in containers can be deployed easily to multiple different operating systems and hardware platforms.
    - More consistent operation - devOps teams know applications in containers will run the same, regardless of where they are deployed.
    - Greater efficiency - containers allow applications to be more rapidly deployed, patched, or scaled.
    - Better application development - containers support agile and DevOps efforts to accelerate development, test, and production cycles.
---
- `Orchestrating` the containers - 
  This is our third level of abstraction. Containerized applications can get complicated, however. When in production, many might require hundreds to thousands of separate containers in production. This is where container runtime environments such as `Docker` benefit from the use of other tools to orchestrate or manage all the containers in operation. `Kubernetes` **orchestrates the operation of multiple containers in harmony together**. It manages areas like the use of underlying infrastructure resources for containerized applications such as the amount of compute, network, and storage resources required. Orchestration tools like `Kubernetes` **make it easier to automate and scale container-based workloads for live production environments**.

## Docker
  As `Docker` is arguably the most popular container runtimes, it'll be our choice here, even though Kubernetes supports numerous container runtimes. A good metaphor that will help us understand how both work together is: Imagine `Kubernetes` as an “operating system” and `Docker containers` as “apps” that you install on the “operating system”.
 
- Start minikube (we'll be using the default driver for it)
  ```bash
  minikube start
  ```

- Obtain the minikube IP:
  ```bash
  $ minikube ip
  192.168.59.100
  ```
  In this case it's `192.168.59.100` and that's where the `DOCKER_HOST` will point to.

- **Point the local docker to minikube** - this step is very important, because we have to make sure that all the created images are created in minkube's echosystem and that we can see all the running containers inside it.
  ```bash
  minikube docker-env
  ```

  Example output:
  ```bash
  export DOCKER_TLS_VERIFY="1"
  export DOCKER_HOST="tcp://192.168.59.100:2376"
  export DOCKER_CERT_PATH="/home/abozhkov/.minikube/certs"
  export MINIKUBE_ACTIVE_DOCKERD="minikube"

  # To point your shell to minikube's docker-daemon, run:
  # eval $(minikube -p minikube docker-env)

  ```

- Copy the output and paste it in the shell.

- Build new image with the tag `flaskapp:1.0`. This will be the main reference that we'll use for our local setup, if we decide to move the a new version, we need to make sure to accommodate this change for all the configuration files.

  ```bash
  docker build -t flaskapp:1.0 ./services/backend/
  ```
  This new image will be build inside the minikube ecosystem, from where we can access it later from the `.yaml` files

## Docker Compose
  `Docker compose` allows you to easily define and deploy your containers and operate multi-container applications at once by using a build definition in the for of `yml`/ `yaml` files. However this is not a production based solution and it's only convenient for local development.

- In our `docker-compose.yaml` we define each service that we use in our project. In our case:
  - `backend` - **Flask** service. Let's take a look at the more interesting parts.
    The `build` part points to the `context` (the `sourcecode`) where the `container` for this service will get it's content from and the `Dockerfile` that will be used to create the `image` from.
    ```yaml
    build:
        context: ./services/backend
        dockerfile: Dockerfile
    ```

    We sepcify the `ports` that we need for our application. In this case flask uses 5000.
    ```yaml
    ports:
      - "5000:5000"
    ```

    The `environement` key is used to set env variables for this service.
    ```yaml
    environment:
      APP_ENV: "prod"
      APP_DEBUG: "False"
      APP_PORT: 5000
      MONGODB_DATABASE: flaskdb
      MONGODB_USERNAME: flaskuser
      MONGODB_PASSWORD: mongopass
      MONGODB_HOSTNAME: mongodb
      MONGODB_PORT: 27017
    ```

    The `volumes` are the preferred mechanism for **persisting** data generated by and used by the container.
    ```yaml
    volumes:
      - ./services/backend:/app
    ```

    The `networks` parameter is responsible for defining in which networks the respective service will be a part of. In our case we have custom `backend-net` for the `backend` service and the `database`.
    ```yaml
    networks:
      - frontend-net
      - backend-net
    ```

  - `database` - **MongoDb** service.
    Here we specify an existing image that we've pulled from dockerhub and not one we've created ourselves, like in the `backend` service. That's why we do not have a `build` parameter.
    ```yaml
    image: mongo:4.0.8
    ```
    
    In our `volumes` we point the service to a bash script called `mongo-init.sh`, responsible for prepopulating the database.
    ```yaml
    volumes:
      - ./services/database/mongo-init.sh:/docker-entrypoint-initdb.d/mongo-init.sh:ro
      - mongodbdata:/data/db
    ```
  
  - `webserver`- **Nginx** service.

  - `frontend` - **Vue** frontend service. Both the `webserver` and `frontend` are a part of the same network, called `frontend`.
    ```yaml
    networks:
      - frontend-net
    ```

  - `networks` and `volumes` - as mentioned previously the `networks` are responsible for creating custom communication between services and the `volumes` alocate space for persistent data.
    ```yaml
    networks:
      frontend-net:
        driver: bridge
      backend-net:
        driver: bridge

    volumes:
      mongodbdata:
        driver: local
      nginxdata:
        driver: local
    ```
- Build and run the app from `docker compose` (`docker-compose` if you're using **v1**)
  ```bash
  docker compose up --build -d
  ```
## TODOS
### High priority
- Create ECS deployment
### Mid priority
- Include a CI/CD integration
### Low priority
- Include unit test coverage
