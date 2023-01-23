# Kubernetes

- Helpful articles:
  - [Ordering changes via file naming conventions](https://www.quarryfox.com/docs/kubernetes/k8_naming_convention/)
  - [Running a Python Application on Kubernetes](https://medium.com/avmconsulting-blog/running-a-python-application-on-kubernetes-aws-56609e7cd88c)
  - [Deploy a flask application with nginx on kubernetes](https://www.kisphp.com/kubernetes/deploy-a-flask-application-with-nginx-on-kubernetes)
  - [Deploy your first Flask+MongoDB app on Kubernetes](https://levelup.gitconnected.com/deploy-your-first-flask-mongodb-app-on-kubernetes-8f5a33fa43b4)
  - [DOCKER : KUBERNETES MINIKUBE INSTALL ON AWS EC2](https://www.bogotobogo.com/DevOps/Docker/Docker-Kubernetes-Minikube-install-on-AWS-EC2.php)

- **Disclaimer** - all the steps below are atomatically handled in the `deploy.sh` script

## Pros and Cons of using Kubernetes
- Pros:

  - Scalability: k8s can easily scale applications up or down based on demand

  - Flexibility: k8s allows for easy deployment of applications across multiple environments, including on-premises, in the cloud, or in a hybrid environment

  - High availability: k8s provides built-in mechanisms for ensuring high availability of applications

  - Large ecosystem: k8s has a large and active community, which means there are many resources and tools available to help users manage their deployments

- Cons:

  - Complexity: k8s can be complex to set up and manage, especially for new users

  - Resource requirements: k8s requires a significant amount of resources, including memory and CPU, to run properly

  - Learning curve: k8s has a steep learning curve, which can make it difficult for new users to get started

  - Support: Kubernetes is open-source and doesn't have any official support

## Prerequisites

- Basic understanding of kubernetes (refer to `kubernetes_basics/` or the linked articles and videos)
- Docker images created in the minikube ecosystem (otherwise when we create the kubectl deployment the pods will return `STATUS: ErrImagePull`)
- We are **not** specifying custom `namespaces` for kubernetes, instead we are using the `default` one

## Naming Conventions
  The order in which Kubernetes objects are initialised matters, especially when bring environments first online. Luckily Kubectl like most CLI tooling respects the underlying ordering of yaml files via their file name. Hence, I like to follow the following naming convention:

  ```bash
  <order>-<kubernetes object type>_<description>.yaml
  ```

- Order is numeric and is used to ensure that objects are applied in the correct order.

- `kubernetes object type` is the shorthand for object described in the yaml file. For a full list of objects available on your   cluster and their respective shortnames, try:
  ```bash
  kubectl api-resources
  ```

- `description` contains a word or two as a reminder of what the object is for and how it will be used.

## Create docker images in your local minikube

- Point the local docker to minikube (`minikube docker-env`)
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
  **Copy the output and paste it in the shell.**

- Create images in the local minikube storage:

  - **backend** service image - `flaskapp:1.0`
    ```bash
    docker build -t flaskapp:1.0 ./kubernetes/backend/
    ```
  - **frontend** service image - `vueapp:1.0`
    ```bash
    docker build -t vueapp:1.0 ./kubernetes/frontend/
    ```
  - **database** service image - `mongo:latest` (pulled from dockerhub)
  - **webserver** service image - `nginx:latest` (pulled from dockerhub)

## Free the required ports and create mock domain

- Make sure that port **:80** on the localhost is available. Turn off any running nginx or apache services from systmctl

- Add the minikube ip to your `/etc/hosts` (we can change to whatever we want as long as we edit the `ingress,yaml`), to avoid using the minikube ip and instead have environment representing a real production as close as possible
  ```bash
  sudo bash -c "echo \"$(minikube ip) dev.k8s\" >> /etc/hosts"
  ```

---
# Kubernetes yaml configuration guide
  Explain the most important elements of each yaml file in the `./kubernetes/` directory, following the naming convention order.

## 0-secrets.yaml
  The kubernetes `Secret` is an object that contains a small amount of sensitive data such as a password, a token, or a key.
  ```yaml
  apiVersion: v1
    kind: Secret
    metadata:
      name: frontend-secrets
    type: Opaque
    data:
      ROOT_API: aHR0cDovL2Rldi5rOHMvYXBp  # evaluates to http://dev.k8s/api (base64 encoded)
  ```
- `kind` - Specify that the type of the configuration is of kind `Secret`
- `metadata` -> **name** - The name of this particular secret
- `type` - The Secret type is used to facilitate programmatic handling of the Secret data
- `data` - The data that this secret holds in a key-value pair format, **encoded explicitly by us**, because Kubernetes Secrets are, by default, stored unencrypted in the API server's underlying data store (etcd)
- Important thing to note about the `ROOT_API` - in our case we need to add not only the FQDN(or DNS) but to include the protocol `http://` (or `https://`) and `/api`

## 1-persistentvolumes.yaml
  A PersistentVolume (PV) is a piece of storage in the cluster that has been provisioned. It is a resource in the cluster just like a node is a cluster resource.
  ```yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: database-pv
  spec:
    capacity:
      storage: 256Mi
    accessModes:
      - ReadWriteOnce
    hostPath:
      path: /tmp/db
  ```
  - `accessModes` - Each PV gets its own set of access modes describing that specific PV's capabilities.
  - `hostPath` - A file or directory on the Node to emulate network-attached storage.

## 2-persistentvolumeclaims.yaml
  PersistentVolumeClaim is a user's request for and claim to a persistent volume.

## 3-configmaps.yaml
  A ConfigMap is an API object used to store non-confidential data in key-value pairs. pods can consume ConfigMaps as environment variables, command-line arguments, or as configuration files in a volume.
  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: backend-cfg
    namespace: default
  data:
    FLASK_PORT: "5000"
    FLASK_DEBUG: "0"
  ```
  Similar to the secrets, we have just need to specify the `name` and the `data`.

## 4-ingress.yaml
  An API object that manages external access to the services in a cluster, typically HTTP. Ingress may provide load balancing, SSL termination and name-based virtual hosting.
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: "nginx"
    name: frontend-ingress
    namespace: default
  spec:
    rules:
      - host: dev.k8s
        http:
          paths:
            - path: /
              pathType: ImplementationSpecific
              backend:
                service:
                  name: webserver-service
                  port:
                    number: 80
  ```
- `annotations` - Ingress frequently uses annotations to configure some options depending on the Ingress controller
- `host` - If a host is provided (for example, `dev.k8s`), the rules apply to that host
- `paths` - A list of paths (for example, /testpath), each of which has an associated `backend `defined with a `service.name` (in our case `webserver-service`) and a `service.port.name` or `service.port.number` (in our case `80`). Both the host and path must match the content of an incoming request before the load balancer directs traffic to the referenced Service.

## 5-deployment_database.yaml
- `Deployment` <br/>
  The deployment configuration goes hand in hand with a service configuration (is some cases we have a separate service.yaml file). It follows a similar pattern for each of the following deployments with slight variations. A Deployment provides declarative updates for pods and ReplicaSets. You describe a desired state in a Deployment, and the Deployment Controller changes the actual state to the desired state at a controlled rate
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: database-deployment
  spec:
    selector:
      matchLabels:
        app: database-deployment
    template:
      metadata:
        labels:
          app: database-deployment
      spec:
        containers:
          - name: database-container
            image: mongo
            ports:
              - containerPort: 27017
            volumeMounts:
              - name: storage
                mountPath: /data/db
            lifecycle:
              postStart:
                exec:
                  command:
                    [
                      "/bin/sh",
                      "-c",
                      "mongosh --eval \"if (db.getSiblingDB('admin').getUser('${MONGODB_USERNAME}') == null) { db.getSiblingDB('admin').createUser( { user: '${MONGODB_USERNAME}', pwd: '${MONGODB_PASSWORD}', roles: [ { role: 'dbAdmin', db: '${MONGODB_DATABASE}' },] } ); }\"",
                    ]
            envFrom:
              - secretRef:
                  name: database-secrets
            resources: {}
        volumes:
          - name: storage
            persistentVolumeClaim:
              claimName: database-pvc
  ```
  - `.metadata.name`- This field will become the basis for the ReplicaSets and pods which are created later (in our case `database-deployment`)
  - `.spec.selector` - Defines how the created ReplicaSet finds which pods to manage. In this case, we select a label that is defined in the Pod template (app: `database-deployment`)
  - `.template.spec` - indicates that the pods run one container named `database-container`, which runs the `mongo` Docker Hub image at latest version
  - `volumeMounts` - allocates space in the container, which we link to the `persistentVolumeClaim` we've created for this service.
  - `lifecycle.postStart.exec.command` - Executes a custom command after the container starts. In our case we create a new admin user, if one does not exist already
  - `envFrom` - allows us to use the secrets configuration, we've created (`database-secrets`)
  - `resources` - the resources we want to give to this container. If we keep it blank it defaults to minimal values

- `Service`<br/>
  An abstract way to expose an application running on a set of pods as a network service. Kubernetes gives pods their own IP addresses and a single DNS name for a set of pods, and can load-balance across them
  ```yaml
  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: database-service
  spec:
    type: ClusterIP
    selector:
      app: database-deployment
    ports:
      - port: 27017
        targetPort: 27017
  ```
  - `metadata.name` - name of the service
  - `spec.type: ClusterIP` - exposes the Service on a cluster-internal IP
  - `spec.selector.app` - all pods matching the given value (in our case `database-deployment`), will be targeted by this service object
  - `port` - exposes the Kubernetes service on the specified port within the cluster. Other pods within the cluster can communicate with this server on the specified port
  - `targetPort` - the port on which the service will send requests to, that our pod will be listening on

## 6-deployment_backend.yaml
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: backend-deployment
    labels:
      app: backend-deployment
  spec:
    replicas: 2
    ...
    template:
      metadata:
        ...
      spec:
        containers:
          - name: backend-container
            image: flaskapp:1.0
      ...
  ```

- `spec.replicas` - number of pods running at any given time
- `spec.containers.image` - the custom image we've created (`flaskapp:1.0`) in our minikube ecosystem and not pulled from Docker Hub

## 8-deployment_webserver.yaml
  ```yaml
  ...
  spec:
    containers:
      - name: webserver-container
        image: nginx
        ...
        env:
          - name: frontend_host
            value: $(FRONTEND_SERVICE_SERVICE_HOST)
          - name: frontend_port
            value: $(FRONTEND_SERVICE_SERVICE_PORT)
          - name: backend_host
            value: $(BACKEND_SERVICE_SERVICE_HOST)
          - name: backend_port
            value: $(BACKEND_SERVICE_SERVICE_PORT)
    volumes:
        - name: nginx-config
          configMap:
            name: webserver-cfg
  ...
  ---
  apiVersion: v1
  kind: Service
  ...
  spec:
    type: LoadBalancer
  ...
  ```
- `spec.containers.env` - explicitly added environemntal variabels. In our case we use the environemnt-injected ones in the format that kubernetes names them, for example the `SERVICE_HOST` -> `<service_name>_SERVICE_HOST`
- `volumes.configMap` - we're using predefined configurations from our config map. In our case we use nginx specific configurations (`nginx-default.conf.template`) so that we have proxy passes for both the `backend` and `frontend`
- (the Service) `spec.type: LoadBalancer` - `LoadBalancer` exposes the service externally using a cloud provider's load balancer. This will be usefull for a cloud deploy, in our case the `EXTERNAL-IP` will be with status `<pending>`
