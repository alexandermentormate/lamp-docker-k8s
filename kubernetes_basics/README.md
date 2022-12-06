# Kubernetes basics

- Create `kubernetes_basics/deployment.yaml` file

  ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: python-webapp
    labels:
        app: web
    spec:
    replicas: 2
    selector:
        matchLabels:
        app: web
    template:
        metadata:
        labels:
            app: web
        spec:
        containers:
            - name: webapp
            image: webapp:1.0
            ports:
                - containerPort: 5000
  ```

- Create `kubernetes_basics/service.yaml` file

  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
  name: web-service
  spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 5000
  ```

- Apply both the k8s deployment and service:

  ```bash
  kubectl apply -f deployment.yaml
  kubectl apply -f service.yaml
  ```

- Check the running pods and service and obtain the allocated service port

  ```bash
  $ kubectl get po,svc
  NAME                                 READY   STATUS    RESTARTS   AGE
    pod/python-webapp-5cc9947b56-2cqhb   1/1     Running   0          72s
    pod/python-webapp-5cc9947b56-fv7xk   1/1     Running   0          72s

    NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
    service/kubernetes    ClusterIP   10.96.0.1        <none>        443/TCP        15d
    service/web-service   NodePort    10.107.123.136   <none>        80:31361/TCP   65s

  ```

  In this case the port is `31361` so if we combine it with the `minikube IP` / `DOCKER_HOST` (**http://192.168.59.100:31361/**) in the browser we should have the flask app up and running from a docker container, inside kubernetes.
