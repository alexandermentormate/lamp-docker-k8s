#!/bin/bash
RED='\033[0;31m'
GREEN='\032[0;312m'
NC='\033[0m'
USAGE="$(basename "$0") [-h] [-d --destroy] [-r --rebuild <image_name>] -- program to calculate the answer to life, the universe and everything

where:
    -h  show this help text
    -d, --destroy  destroy the entire project, including the persistent volumes
    -r, --rebuild, <image_name> [optional]  rebuild the project with optional <image_name> (default: flaskapp:1.0)"
    

if [ "$1" = "-h" ]
    then
        echo "$USAGE"
        exit 0
fi


if [ "$1" = "--destroy" ]
  then

    echo "${RED}Tearing down the local minikube project${NC}"

    kubectl delete -f kubernetes/flask.yaml
    kubectl delete -f kubernetes/mongo.yaml
    kubectl delete -f kubernetes/secrets.yaml
    kubectl delete -f kubernetes/flask-cfg.yaml
    kubectl delete -f kubernetes/flask-ing.yaml
    kubectl delete -f kubernetes/mongo-pvc.yaml
    kubectl delete -f kubernetes/mongo-pv.yaml

    echo "${RED}Done!${NS}"

    exit 0;
fi


echo "Include the ${RED}dev.k8s${NC} domain to /etc/hosts if not present"

grep -qxF "$(minikube ip) dev.k8s" /etc/hosts || sudo bash -c "echo \"$(minikube ip) dev.k8s\" >> /etc/hosts"


echo "Creating the database credentials"

kubectl apply -f ./kubernetes/secrets.yaml


echo "Creating the mongo volume"

kubectl apply -f ./kubernetes/mongo-pv.yaml
kubectl apply -f ./kubernetes/mongo-pvc.yaml


echo "Creating the mongodb deployment and service"

kubectl create -f ./kubernetes/mongo.yaml


echo "Apply the flaskapp config"
kubectl apply -f ./kubernetes/flask-cfg.yaml


echo "Create the flaskapp ingress"

minikube addons enable ingress
kubectl apply -f ./kubernetes/flask-ing.yaml


if [ "$1" = "-r" ] || [ "$1" = "--rebuild" ]
  then

    if [ $# -eq 2 ]
      then
        image_name=$2
      else
        image_name="flaskapp:1.0"
    fi

    echo "${GREEN}Building new flask image called $image_name${NC}"
    docker build -t $image_name .
fi

echo "Create or Restart existing flaskapp deployment / services"
kubectl delete -f ./kubernetes/flask.yaml
kubectl apply -f ./kubernetes/flask.yaml
