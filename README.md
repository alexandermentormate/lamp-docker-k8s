# Minikube + Docker + Flask

    Video for reference - https://www.youtube.com/watch?v=SdTzwYmsgoU

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
