# EKS deployment
  This is the continuation for the minikube local deployment example, where we have all the source code and we create the docker images, which we deploy in ECR

## Disclaimer
  If we do not have a registered domain (FQDN), we need to separate the webserver service and apply it first in order to obtain the service dns(external ip), that EKS provides and replace it in the ingress and secrets.
  For the purpose of this demo we'll go without a FQDN.

## Deployment steps:

- Check that we are authenticated with aws cli and that `kubectl` is using the correct `context`
  - Check kubectl config
    ```bash
    kubectl config view
    ```
    Example output:
    ```bash
    ...
    contexts:
    - context:
        cluster: my-cluster.eu-central-1.eksctl.io
        user: abozhkov-pc@my-cluster.eu-central-1.eksctl.io
      name: abozhkov-pc@my-cluster.eu-central-1.eksctl.io
    - context:
        cluster: gke_rational-symbol-202020_us-east1-d_staging-cd
        user: gke_rational-symbol-202020_us-east1-d_staging-cd
      name: gke_rational-symbol-202020_us-east1-d_staging-cd
    current-context: abozhkov-pc@my-cluster.eu-central-1.eksctl.io
    ...
    ```
    The `current-context` should be the value of the EKS cluster name (in our case `name: abozhkov-pc@my-cluster.eu-central-1.eksctl.io`)

  - If the `current-context` is different from the cluster name (for example `minikube`), run:
    ```bash
    kubectl config use-context <eks-cluster-name>
    ```
- Create new cluster called `my-cluster`
  ```bash
  eksctl create cluster \
  --name my-cluster \
  --region eu-central-1 \
  --nodegroup-name linux-nodes \
  --node-type t3.medium \
  --nodes 1 \
  --nodes-max=5 \
  --asg-access
  ```
  Where:
  - `nodegroup-name` - name of the node groups
  - `node-type` - type of `EC2` instances we want to run for each node; t3.medium is good for this example, less than that and we run into resource issues
  - `node` - number of nodes we initially start with; we'll start with 1 with the option to auto-scale, which EKS handles autmatically if on
  - `nodes-max` - max number of nodes we want; we can't go higher than the preset value, even if autscaling is on
  - `asg-access` - autoscaling on

- Add admin role for your current user in order to have read access for the cluster, from the aws console (not included by default)
  - Get the `IAM` user name
  ```bash
  aws iam get-user
  ```
  Example output:
  ```bash
  {
      "User": {
          "Path": "/",
          "UserName": "abozhkov-pc",
          "UserId": "AIDAQ3RCFZCC5HB45KWYD",
          "Arn": "arn:aws:iam::059127482501:user/abozhkov-pc",
          "CreateDate": "2021-11-01T15:52:53+00:00"
      }
  }
  ```
  - Create a new admin role that includes all EKS permissions and get the role `arn`
  - Create the identity mapping
  ```bash
  eksctl create iamidentitymapping \
  --cluster my-cluster \
  --region=eu-central-1 \
  --arn arn:aws:iam::059127482501:role/MentorMateAdmin \
  --username abozhkov-pc \
  --group system:masters
  ```
  Where:
  - `cluster` - cluster name
  - `arn` - the admin role `arn`
  - `group` - the group role for kubernetes (in our case we set them as `system:masters`)

  ### **Important note: Even as an admin, we still don't have access to the master nodes. They are handled by AWS!**

- Create ECR repository and push your `backend` and `frontend` images to it
  - Create new ECR repository from aws console and get the repo uri (in our case `059127482501.dkr.ecr.eu-central-1.amazonaws.com`)
  - Retrieve an authentication token and authenticate your Docker client to your registry.
    ```bash
    aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 059127482501.dkr.ecr.eu-central-1.amazonaws.com
    ```
  - Build `backend` image, tag and push it to the ECR repo
    ```bash
    docker build -t flaskapp:1.0 <path_to_backend_dockerfile>
    docker tag flaskapp:1.0 059127482501.dkr.ecr.eu-central-1.amazonaws.com/test-image-repository:flaskapp
    docker push 059127482501.dkr.ecr.eu-central-1.amazonaws.com/test-image-repository:flaskapp
    ```
  - Build `frontend` image, tag and push it to the ECR repo
    ```bash
    docker build -t vueapp:1.0 <path_to_backend_dockerfile>
    docker tag vueapp:1.0 059127482501.dkr.ecr.eu-central-1.amazonaws.com/test-image-repository:vueapp
    docker push 059127482501.dkr.ecr.eu-central-1.amazonaws.com/test-image-repository:vueapp
    ```
  - Update the configuration files with the new image uri's
    - `6-deployment_backend.yaml` -> `spec->containers->image: 059127482501.dkr.ecr.eu-central-1.amazonaws.com/test-image-repository:flaskapp`
    - `7-deployment_frontend.yaml` -> `spec->containers->image: 059127482501.dkr.ecr.eu-central-1.amazonaws.com/test-image-repository:vueapp`

- Apply the `.yaml` files
  - First apply the `service_webserver.yaml` in order to obtain `EXTERNAL-IP` (EKS DNS)
    ```bash
    kubectl apply -f service_webserver.yaml
    ```
  - Get the service
    ```bash
    kubectl get svc
    ```
    Example output:
    ```bash
    NAME                TYPE           CLUSTER-IP       EXTERNAL-IP                                                                 PORT(S)        AGE
    kubernetes          ClusterIP      10.100.0.1       <none>                                                                      443/TCP        101m
    webserver-service   LoadBalancer   10.100.210.229   a6350d35187654a8eb70e3535ca3b7b5-452790203.eu-central-1.elb.amazonaws.com   80:31103/TCP   48s
    ```
    Our `EXTERNAL-IP` is `a6350d35187654a8eb70e3535ca3b7b5-452790203.eu-central-1.elb.amazonaws.com`
  - Use the EXTERNAL-IP (EKS DNS) from the **webserver service** to manually update:
    - `0-secrets.yaml` -> `data->ROOT_API: <BASE64_EXTERNAL-IP>`<br />
      The `<EXTERNAL-IP>` has to be base64 encoded in a `http://<EXTERNAL-IP>/api` format. Example:
      ```bash
      echo  'http://<EXTERNAL-IP>/api' | base64
      ```
    - `4-ingress.yaml` -> `spec->rules->host: <EXTERNAL-IP>`
  - Apply the rest of the files in the original order
    ```bash
    kubectl apply -f 0-secrets.yaml &\
    kubectl apply -f 1-persistentvolumes.yaml &\
    kubectl apply -f 2-persistentvolumeclaims.yaml &\
    kubectl apply -f 3-configmaps.yaml &\
    kubectl apply -f 4-ingress.yaml &\
    kubectl apply -f 5-deployment_database.yaml &\
    kubectl apply -f 6-deployment_backend.yaml &\
    kubectl apply -f 7-deployment_frontend.yaml &\
    kubectl apply -f 8-deployment_webserver.yaml
    ```

- Check all the running resources
  ```bash
  kubectl get all -o wide
  ```
