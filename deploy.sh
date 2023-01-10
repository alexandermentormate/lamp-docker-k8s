#!/bin/bash
RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m'
USAGE="$(basename "$0") [-h] [-d --destroy] [-r --rebuild <image_name>] -- deploy script for the project that builds and runs the project on hostname ${RED}dev.k8s${NC}.

where:
    -h, --help  show this help text
    -d, --destroy  destroy the entire project, including the persistent volumes
    -rb, --rebuild-backend, <image_name> [optional]  rebuild the backend service with optional <image_name> (default: flaskapp:1.0)
    -rf, --rebuild-frontend, <image_name> [optional]  rebuild the backend service with optional <image_name> (default: vueapp:1.0)"
    

if [ "$1" = "-h" ] || [ "$1" = "--help" ]
    then
        echo "$USAGE"
        exit 0
fi


if [ "$1" = "-d" ] || [ "$1" = "--destroy" ]
  then

    echo "${RED}Tearing down the local minikube project${NC}"

    kubectl delete -f kubernetes/8-deployment_webserver.yaml
    kubectl delete -f kubernetes/7-deployment_frontend.yaml
    kubectl delete -f kubernetes/6-deployment_backend.yaml
    kubectl delete -f kubernetes/5-deployment_database.yaml
    kubectl delete -f kubernetes/4-ingress.yaml
    kubectl delete -f kubernetes/3-configmaps.yaml
    kubectl delete -f kubernetes/2-persistentvolumeclaims.yaml
    kubectl delete -f kubernetes/1-persistentvolumes.yaml
    kubectl delete -f kubernetes/0-secrets.yaml

    echo "${RED}Done!${NS}"

    exit 0;
fi


echo "Include the ${RED}dev.k8s${NC} domain to /etc/hosts if not present"
grep -qxF "$(minikube ip) dev.k8s" /etc/hosts || sudo bash -c "echo \"$(minikube ip) dev.k8s\" >> /etc/hosts"


echo "Creating the ${GREEN}secrets${NC}: environment variables and credentials"
kubectl apply -f ./kubernetes/0-secrets.yaml


echo "Creating the ${GREEN}persistent volumes${NC} and ${GREEN}persistent volume claims${NC} for the database"
kubectl apply -f ./kubernetes/1-persistentvolumes.yaml
kubectl apply -f ./kubernetes/2-persistentvolumeclaims.yaml


echo "Applyinf rhw ${GREEN}configmaps${NC}"
kubectl apply -f ./kubernetes/3-configmaps.yaml


echo "Creating the ${GREEN}ingress${NC}"
minikube addons enable ingress
kubectl apply -f ./kubernetes/4-ingress.yaml


echo "Creating the ${GREEN}deployment${NC} for the database service"
kubectl create -f ./kubernetes/5-deployment_database.yaml

if [ "$1" = "-rb" ] || [ "$1" = "--rebuild-backend" ]
  then

    if [ $# -eq 2 ]
      then
        image_name=$2
      else
        image_name="flaskapp:1.0"
    fi

    echo "${GREEN}Building new backend image called $image_name${NC}"
    docker build -t $image_name ./services/backend/
fi


echo "Creating or restarting existing ${GREEN}deployment${NC} for the backend service"
kubectl delete -f ./kubernetes/6-deployment_backend.yaml
kubectl apply -f ./kubernetes/6-deployment_backend.yaml


if [ "$1" = "-rf" ] || [ "$1" = "--rebuild-frontend" ]
  then

    if [ $# -eq 2 ]
      then
        image_name=$2
      else
        image_name="vueapp:1.0"
    fi

    echo "${GREEN}Building new frontend image called $image_name${NC}"
    docker build -t $image_name ./services/frontend/
fi


echo "Creating or restarting existing ${GREEN}deployment${NC} for the frontend service"
kubectl delete -f ./kubernetes/7-deployment_frontend.yaml
kubectl apply -f ./kubernetes/7-deployment_frontend.yaml


echo "Creating or restarting existing ${GREEN}deployment${NC} for the webserver service"
kubectl wait --for=condition=ready pod -l app=backend-deployment
kubectl wait --for=condition=ready pod -l app=frontend-deployment
kubectl delete -f ./kubernetes/8-deployment_webserver.yaml
kubectl apply -f ./kubernetes/8-deployment_webserver.yaml
